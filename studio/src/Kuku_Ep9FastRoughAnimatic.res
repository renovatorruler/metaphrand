/*
 * Fast, generic rough-animatic builder.
 *
 * This intentionally does one small job: turn a validated EDL into a continuous
 * silent review movie. Accepted motion is used as motion. Missing motion becomes
 * a gently moving accepted anchor still, or an explicit placeholder card when
 * no accepted anchor exists. No provider, credentials, production manifest, or
 * spend ledger is touched.
 *
 * Run from studio/:
 *   node src/Kuku_Ep9FastRoughAnimatic.res.mjs <edl-v2.json> <output.mp4>
 */

open Cinema_Backends

@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external exitProcess: int => unit = "exit"
@module("node:path") external dirname: string => string = "dirname"
@module("node:path") external resolve2: (string, string) => string = "resolve"
@module("node:path") external basename: string => string = "basename"

exception FastRoughAnimaticError(string)

let fail = message => raise(FastRoughAnimaticError(message))

let objectOf = (json, where) =>
  switch Js.Json.decodeObject(json) {
  | Some(value) => value
  | None => fail(where ++ " must be an object")
  }

let field = (object_, key, where) =>
  switch Js.Dict.get(object_, key) {
  | Some(value) => value
  | None => fail(where ++ "." ++ key ++ " is required")
  }

let stringField = (object_, key, where) =>
  switch field(object_, key, where)->Js.Json.decodeString {
  | Some(value) => value
  | None => fail(where ++ "." ++ key ++ " must be a string")
  }

let intField = (object_, key, where) =>
  switch field(object_, key, where)->Js.Json.decodeNumber {
  | Some(value) => Belt.Float.toInt(value)
  | None => fail(where ++ "." ++ key ++ " must be a number")
  }

let numberField = (object_, key, where) =>
  switch field(object_, key, where)->Js.Json.decodeNumber {
  | Some(value) => value
  | None => fail(where ++ "." ++ key ++ " must be a number")
  }

let arrayField = (object_, key, where) =>
  switch field(object_, key, where)->Js.Json.decodeArray {
  | Some(value) => value
  | None => fail(where ++ "." ++ key ++ " must be an array")
  }

let stringArrayField = (object_, key, where) =>
  arrayField(object_, key, where)->Belt.Array.mapWithIndex((index, json) =>
    switch Js.Json.decodeString(json) {
    | Some(value) => value
    | None => fail(where ++ "." ++ key ++ "[" ++ Belt.Int.toString(index) ++ "] must be text")
    }
  )

let readObject = (path, where) => {
  if !exists(Path(path)) {
    fail(where ++ " does not exist: " ++ path)
  }
  try readText(Path(path))->Js.Json.parseExn->objectOf(where) catch {
  | Js.Exn.Error(error) =>
    fail(
      where ++ " is not valid JSON: " ++
      Js.Exn.message(error)->Belt.Option.getWithDefault("unknown parse error"),
    )
  }
}

let escapeMarkup = text =>
  text
  ->Js.String2.replaceByRe(%re("/&/g"), "&amp;")
  ->Js.String2.replaceByRe(%re("/</g"), "&lt;")
  ->Js.String2.replaceByRe(%re("/>/g"), "&gt;")

type beat = {
  id: string,
  scene: int,
  start: string,
  end_: string,
  durationSeconds: int,
  sourceClass: string,
  storyEvent: string,
  acceptedAsset: option<string>,
  anchorRefs: array<string>,
}

type anchor = {path: string, status: string}

type source =
  | AcceptedMotion(string)
  | AcceptedStill(string)
  | ReviewStill(string)
  | Placeholder

type result = {
  output: string,
  contact: string,
  sha256: string,
  durationSeconds: float,
  acceptedMotionBeats: int,
  acceptedStillBeats: int,
  reviewStillBeats: int,
  placeholderBeats: int,
}

let parseBeat = (~manifestDirectory, ~index, json): beat => {
  let where = "EDL.beats[" ++ Belt.Int.toString(index) ++ "]"
  let row = objectOf(json, where)
  let acceptedPath = stringField(row, "acceptedAssetPath", where)
  {
    id: stringField(row, "id", where),
    scene: intField(row, "scene", where),
    start: stringField(row, "start", where),
    end_: stringField(row, "end", where),
    durationSeconds: intField(row, "durationSeconds", where),
    sourceClass: stringField(row, "sourceClass", where),
    storyEvent: stringField(row, "storyEvent", where),
    acceptedAsset: acceptedPath == "" ? None : Some(resolve2(manifestDirectory, acceptedPath)),
    anchorRefs: stringArrayField(row, "anchorRefs", where),
  }
}

let acceptedAnchorStatus = status =>
  status == "accepted" || Js.String2.startsWith(status, "accepted_")

let loadAnchors = (~manifestDirectory, ~relativePath) => {
  let anchorManifestPath = resolve2(manifestDirectory, relativePath)
  let root = readObject(anchorManifestPath, "anchor manifest")
  let anchorDirectory = dirname(anchorManifestPath)
  let anchors: Js.Dict.t<anchor> = Js.Dict.empty()
  arrayField(root, "anchors", "anchor manifest")->Belt.Array.forEachWithIndex((index, json) => {
    let where = "anchor manifest.anchors[" ++ Belt.Int.toString(index) ++ "]"
    let row = objectOf(json, where)
    let id = stringField(row, "id", where)
    Js.Dict.set(anchors, id, {
      path: resolve2(anchorDirectory, stringField(row, "output", where)),
      status: stringField(row, "status", where),
    })
  })
  anchors
}

/* Optional per-beat camera move for stills, requested by the parent shot by shot.
   PushIn: start on the full frame and drift into a target point ("pan and zoom from the
   full frame to the sage"). PanAcross: zoom in at one point, travel to another, then pull
   back out ("pan from the leftmost character to the rightmost, then zoom out"). All
   coordinates are fractions of the frame. At zoom 1 the crop is the whole frame whatever
   the target, so both moves begin and/or end wide without special-casing. */
type cameraMove =
  | PushIn({zoomTo: float, cx: float, cy: float})
  | PanAcross({zoom: float, fromCx: float, toCx: float, cy: float})

type reviewOverrides = {
  sources: Js.Dict.t<source>,
  excludedAssets: Js.Dict.t<bool>,
  cameras: Js.Dict.t<cameraMove>,
}

let emptyReviewOverrides = () => {
  let sources: Js.Dict.t<source> = Js.Dict.empty()
  let excludedAssets: Js.Dict.t<bool> = Js.Dict.empty()
  let cameras: Js.Dict.t<cameraMove> = Js.Dict.empty()
  {sources, excludedAssets, cameras}
}

let loadReviewOverrides = path => {
  let root = readObject(path, "review overrides")
  if stringField(root, "version", "review overrides") != "rough-animatic-overrides-v1" {
    fail("review overrides version is not supported")
  }
  let directory = dirname(path)
  let loaded = emptyReviewOverrides()
  stringArrayField(root, "excludedAssets", "review overrides")->Belt.Array.forEach(relativePath =>
    Js.Dict.set(loaded.excludedAssets, resolve2(directory, relativePath), true)
  )
  arrayField(root, "beatSources", "review overrides")->Belt.Array.forEachWithIndex((index, json) => {
    let where = "review overrides.beatSources[" ++ Belt.Int.toString(index) ++ "]"
    let row = objectOf(json, where)
    let beatId = stringField(row, "beatId", where)
    let kind = stringField(row, "kind", where)
    let path = resolve2(directory, stringField(row, "path", where))
    if !exists(Path(path)) {
      fail(where ++ " source does not exist: " ++ path)
    }
    let source = switch kind {
    | "review_still" => ReviewStill(path)
    | "accepted_still" => AcceptedStill(path)
    | "accepted_motion" => AcceptedMotion(path)
    | unknown => fail(where ++ " has unsupported kind " ++ unknown)
    }
    if Js.Dict.get(loaded.sources, beatId) != None {
      fail("duplicate review override for " ++ beatId)
    }
    Js.Dict.set(loaded.sources, beatId, source)
    switch Js.Dict.get(row, "camera") {
    | Some(cameraJson) => {
        let camera = objectOf(cameraJson, where ++ ".camera")
        let move = switch stringField(camera, "kind", where ++ ".camera") {
        | "pushIn" => {
            let zoomTo = numberField(camera, "zoomTo", where ++ ".camera")
            if zoomTo <= 1.0 || zoomTo > 2.0 {
              fail(where ++ ".camera.zoomTo must be in (1.0, 2.0]")
            }
            PushIn({
              zoomTo,
              cx: numberField(camera, "cx", where ++ ".camera"),
              cy: numberField(camera, "cy", where ++ ".camera"),
            })
          }
        | "panAcross" => {
            let zoom = numberField(camera, "zoom", where ++ ".camera")
            if zoom <= 1.0 || zoom > 2.0 {
              fail(where ++ ".camera.zoom must be in (1.0, 2.0]")
            }
            PanAcross({
              zoom,
              fromCx: numberField(camera, "fromCx", where ++ ".camera"),
              toCx: numberField(camera, "toCx", where ++ ".camera"),
              cy: numberField(camera, "cy", where ++ ".camera"),
            })
          }
        | unknown => fail(where ++ ".camera.kind is unsupported: " ++ unknown)
        }
        Js.Dict.set(loaded.cameras, beatId, move)
      }
    | None => ()
    }
  })
  loaded
}

let parentIdOf = id =>
  switch Js.String2.splitByRe(id, %re("/-L\d+$/")) {
  | [Some(prefix), _] => prefix
  | _ => id
  }

let sourceFor = (~anchors, ~overrides, beat): source =>
  switch Js.Dict.get(overrides.sources, beat.id) {
  | Some(source) => source
  /* sub-shots inherit their parent beat's override unless they carry their own */
  | None if Js.Dict.get(overrides.sources, parentIdOf(beat.id)) != None =>
    switch Js.Dict.get(overrides.sources, parentIdOf(beat.id)) {
    | Some(source) => source
    | None => Placeholder
    }
  | None => switch beat.acceptedAsset {
  | Some(path) if Js.Dict.get(overrides.excludedAssets, path) == None => AcceptedMotion(path)
  | Some(_) | None =>
    let acceptedAnchor = beat.anchorRefs->Belt.Array.getBy(reference =>
      switch Js.Dict.get(anchors, reference) {
      | Some(anchor) => acceptedAnchorStatus(anchor.status) && exists(Path(anchor.path))
      | None => false
      }
    )
    switch acceptedAnchor {
    | Some(reference) =>
      switch Js.Dict.get(anchors, reference) {
      | Some(anchor) => AcceptedStill(anchor.path)
      | None => Placeholder
      }
    | None => Placeholder
    }
  }
  }

let sourceLabel = source =>
  switch source {
  | AcceptedMotion(_) => ("ACCEPTED MOTION", "#72e39b")
  | AcceptedStill(_) => ("ROUGH MOVE FROM ACCEPTED STILL", "#ffd166")
  | ReviewStill(_) => ("APPROVED CONTINUITY PANEL — NOT FINAL ART", "#7bdff2")
  | Placeholder => ("PLACEHOLDER — PICTURE NEEDED", "#ff8da1")
  }

let threeDigits = value =>
  value < 10
    ? "00" ++ Belt.Int.toString(value)
    : value < 100
      ? "0" ++ Belt.Int.toString(value)
      : Belt.Int.toString(value)

let segmentName = (~index, ~beat) =>
  threeDigits(index) ++ "_" ++ beat.id ++ ".mp4"

/* Shot identification burned into the picture.
 *
 * This used to be a 1100px pango card with a 90px margin overlaid across the bottom of the
 * frame — a slab covering a third of the picture. The user rejected it twice ("that caption
 * panel is still covering a third of the screen", "why do you add this horrendous giant
 * chyron"), and it kept coming back because the builder only had two modes: no label at all,
 * or the slab. This is the third mode it should always have had.
 *
 * A small chip in the top-left corner: the plain shot number the parent actually speaks
 * ("s53 shows Castor to be small"), tinted by source kind so a glance still distinguishes
 * motion from still. n is the beat's 1-based position, exactly how
 * ep9_simple_shot_numbers.v2.json was built. Nothing else is burned in — scene, timecode and
 * story text live in the manifests, and putting them on the picture is what made the slab.
 *
 * This ffmpeg build has no drawtext filter (no libfreetype), which is why all text in this
 * pipeline goes through pango-view and is overlaid as an image.
 */
let renderChip = (~buildDirectory, ~index, ~source) => {
  let (_, color) = sourceLabel(source)
  let markup =
    "<span font=\"Avenir Next Bold 20\" foreground=\"" ++ color ++ "\">" ++
    escapeMarkup("S" ++ Belt.Int.toString(index + 1)) ++ "</span>"
  let chip = buildDirectory ++ "/chip_" ++ threeDigits(index) ++ ".png"
  /* width 60 fits the longest label (S143) on one line; anything narrower wraps */
  let _ = pango(~markup, ~width=60, ~background="#151327", ~margin=6, ~out=Path(chip))
  chip
}

/* The still-image motion filter: an authored camera move when the beat has one, else the
   gentle default drift every still has always had. Authored moves get a 2560x1440 canvas so
   a 1.5x crop still lands above the 1280 output width; `in` (the looped input frame count)
   is the clock, since with d=1 zoompan's `on` never advances. */
let stillMotion = (~camera: option<cameraMove>, ~seconds: int) => {
  let f = n => Js.Float.toString(n)
  let frames = Belt.Int.toFloat(seconds * 24)
  switch camera {
  | None =>
    "scale=1344:756:force_original_aspect_ratio=increase,crop=1344:756," ++
    "zoompan=z='min(zoom+0.00008,1.05)':x='iw/2-(iw/zoom/2)':" ++
    "y='ih/2-(ih/zoom/2)':d=1:s=1280x720:fps=24,setsar=1"
  | Some(PushIn({zoomTo, cx, cy})) =>
    "scale=2560:1440:force_original_aspect_ratio=increase,crop=2560:1440," ++
    "zoompan=z='min(1+" ++ f(zoomTo -. 1.0) ++ "*in/" ++ f(frames) ++ "," ++ f(zoomTo) ++ ")':" ++
    "x='max(min(" ++ f(cx) ++ "*iw-iw/zoom/2,iw-iw/zoom),0)':" ++
    "y='max(min(" ++ f(cy) ++ "*ih-ih/zoom/2,ih-ih/zoom),0)':" ++
    "d=1:s=1280x720:fps=24,setsar=1"
  | Some(PanAcross({zoom, fromCx, toCx, cy})) => {
      /* 20% settle in, 55% travel, 25% pull back out */
      let f1 = f(frames *. 0.2)
      let f2 = f(frames *. 0.75)
      let cxExpr =
        "if(lt(in," ++ f1 ++ ")," ++ f(fromCx) ++ ",if(lt(in," ++ f2 ++ ")," ++
        f(fromCx) ++ "+" ++ f(toCx -. fromCx) ++ "*(in-" ++ f1 ++ ")/(" ++ f2 ++ "-" ++ f1 ++ ")," ++
        f(toCx) ++ "))"
      "scale=2560:1440:force_original_aspect_ratio=increase,crop=2560:1440," ++
      "zoompan=z='if(lt(in," ++ f1 ++ "),1+" ++ f(zoom -. 1.0) ++ "*in/" ++ f1 ++
      ",if(lt(in," ++ f2 ++ ")," ++ f(zoom) ++ ",max(1," ++ f(zoom) ++ "-" ++
      f(zoom -. 1.0) ++ "*(in-" ++ f2 ++ ")/(" ++ f(frames) ++ "-" ++ f2 ++ "))))':" ++
      "x='max(min((" ++ cxExpr ++ ")*iw-iw/zoom/2,iw-iw/zoom),0)':" ++
      "y='max(min(" ++ f(cy) ++ "*ih-ih/zoom/2,ih-ih/zoom),0)':" ++
      "d=1:s=1280x720:fps=24,setsar=1"
    }
  }
}

let commonOutputArgs = (~frames, ~output) => [
  "-map", "[out]", "-frames:v", Belt.Int.toString(frames), "-an", "-r", "24",
  "-c:v", "libx264", "-preset", "ultrafast", "-crf", "25", "-pix_fmt", "yuv420p",
  "-g", "24", "-keyint_min", "24", "-sc_threshold", "0", "-video_track_timescale", "24000",
  output,
]

let renderSegment = (~buildDirectory, ~index, ~beat, ~source, ~camera, ~seek, ~cleanPicture) => {
  let output = buildDirectory ++ "/" ++ segmentName(~index, ~beat)
  let frames = beat.durationSeconds * 24
  let tail = commonOutputArgs(~frames, ~output)
  if cleanPicture {
    switch source {
    | AcceptedMotion(path) =>
      /* play ONCE and hold the last frame: -stream_loop looped short clips through long
         beats (S19's 10s arrival played three times over its 30s dialogue window) and the
         restart judder read as a framerate problem. tpad clones the final frame instead. */
      ffmpeg(Belt.Array.concatMany([
        Belt.Array.concatMany([
          ["-nostdin", "-v", "error", "-y"],
          seek > 0.0 ? ["-ss", Js.Float.toString(seek)] : [],
          ["-i", path],
        ]),
        [
          "-filter_complex",
          "[0:v]fps=24,scale=1280:720:force_original_aspect_ratio=increase," ++
          "crop=1280:720,setsar=1,tpad=stop=-1:stop_mode=clone,format=yuv420p[out]",
        ],
        tail,
      ]))
    | AcceptedStill(path) =>
      ffmpeg(Belt.Array.concatMany([
        ["-nostdin", "-v", "error", "-y", "-loop", "1", "-framerate", "24", "-i", path],
        [
          "-filter_complex",
          "[0:v]" ++ stillMotion(~camera, ~seconds=beat.durationSeconds) ++ ",format=yuv420p[out]",
        ],
        tail,
      ]))
    | ReviewStill(_)
    | Placeholder =>
      ffmpeg(Belt.Array.concatMany([
        [
          "-nostdin", "-v", "error", "-y", "-f", "lavfi", "-i",
          "color=c=0x252837:s=1280x720:r=24",
        ],
        [
          "-filter_complex",
          "[0:v]drawbox=x=1216:y=24:w=40:h=40:color=0xcdbb74@0.72:t=fill," ++
          "format=yuv420p[out]",
        ],
        tail,
      ]))
    }
  } else {
    let chip = renderChip(~buildDirectory, ~index, ~source)
    /* top-left, inset, and translucent — identification without occlusion */
    let place = "[1:v]format=rgba,colorchannelmixer=aa=0.62[chip];" ++
      "[base][chip]overlay=18:14:shortest=0,format=yuv420p[out]"
    switch source {
  | AcceptedMotion(path) =>
    ffmpeg(Belt.Array.concatMany([
      Belt.Array.concatMany([
        ["-nostdin", "-v", "error", "-y"],
        seek > 0.0 ? ["-ss", Js.Float.toString(seek)] : [],
        ["-i", path, "-loop", "1", "-i", chip],
      ]),
      [
        "-filter_complex",
        "[0:v]fps=24,scale=1280:720:force_original_aspect_ratio=increase," ++
        "crop=1280:720,setsar=1,tpad=stop=-1:stop_mode=clone[base];" ++ place,
      ],
      tail,
    ]))
  | AcceptedStill(path)
  | ReviewStill(path) =>
    ffmpeg(Belt.Array.concatMany([
      ["-nostdin", "-v", "error", "-y", "-loop", "1", "-framerate", "24", "-i", path, "-loop", "1", "-i", chip],
      [
        "-filter_complex",
        "[0:v]" ++ stillMotion(~camera, ~seconds=beat.durationSeconds) ++ "[base];" ++ place,
      ],
      tail,
    ]))
  | Placeholder =>
    ffmpeg(Belt.Array.concatMany([
      [
        "-nostdin", "-v", "error", "-y", "-f", "lavfi", "-i",
        "color=c=0x201a38:s=1280x720:r=24", "-loop", "1", "-i", chip,
      ],
      [
        "-filter_complex",
        "[0:v]drawbox=x=56:y=48:w=1168:h=624:color=0x6f5aa8@0.20:t=6[base];" ++ place,
      ],
      tail,
    ]))
    }
  }
  output
}

let requireSuccess = (~label, result) =>
  if result.code != 0 {
    fail(
      label ++ " failed (exit " ++ Belt.Int.toString(result.code) ++ "): " ++
      Js.String2.slice(result.stderr, ~from=0, ~to_=1800),
    )
  }

let build = (~manifestPath, ~output, ~reviewOverridePath, ~cleanPicture): result => {
  let validation = try (
    Kuku_Ep9FinaleAnimaticEdlV2.isV4(~manifestPath)
      ? Kuku_Ep9FinaleAnimaticEdlV2.validateV4(~manifestPath)
      : Kuku_Ep9FinaleAnimaticEdlV2.isV3(~manifestPath)
      ? Kuku_Ep9FinaleAnimaticEdlV2.validateV3(~manifestPath)
      : Kuku_Ep9FinaleAnimaticEdlV2.validate(~manifestPath)
  ) catch {
  | Kuku_Ep9FinaleAnimaticEdlV2.AnimaticEdlV2Error(message) =>
    fail("EDL validation failed: " ++ message)
  }
  /* The main story may exceed 12:00 so paid clips play whole. The validator's total comes
     from the v2 identity manifest (still 12:00 by design), so the length is read from THIS
     manifest's own timeline, which the retimer publishes. */
  let _ = validation

  let manifestDirectory = dirname(manifestPath)
  let root = readObject(manifestPath, "EDL")
  let mainSeconds =
    intField(field(root, "timeline", "EDL")->objectOf("EDL.timeline"), "durationSeconds",
      "EDL.timeline")
  let sourceDocuments = field(root, "sourceDocuments", "EDL")->objectOf("EDL.sourceDocuments")
  let anchors = loadAnchors(
    ~manifestDirectory,
    ~relativePath=stringField(sourceDocuments, "anchorManifest", "EDL.sourceDocuments"),
  )
  let overrides = switch reviewOverridePath {
  | Some(path) => loadReviewOverrides(path)
  | None => emptyReviewOverrides()
  }
  let beats = arrayField(root, "beats", "EDL")->Belt.Array.mapWithIndex((index, json) =>
    parseBeat(~manifestDirectory, ~index, json)
  )

  let outputDirectory = dirname(output)
  let buildDirectory = outputDirectory ++ "/." ++ basename(output) ++ ".build"
  ensureDirPath(Path(outputDirectory))
  ensureDirPath(Path(buildDirectory))

  let lastMotionPath: ref<option<string>> = ref(None)
  let lastMotionSeek = ref(0.0)
  let acceptedMotionBeats = ref(0)
  let acceptedStillBeats = ref(0)
  let reviewStillBeats = ref(0)
  let placeholderBeats = ref(0)
  let segments = beats->Belt.Array.mapWithIndex((index, beat) => {
    let source = sourceFor(~anchors, ~overrides, beat)
    switch source {
    | AcceptedMotion(path) => {
        if !exists(Path(path)) {
          fail("accepted asset is missing: " ++ path)
        }
        acceptedMotionBeats := acceptedMotionBeats.contents + 1
      }
    | AcceptedStill(_) => acceptedStillBeats := acceptedStillBeats.contents + 1
    | ReviewStill(_) => reviewStillBeats := reviewStillBeats.contents + 1
    | Placeholder => placeholderBeats := placeholderBeats.contents + 1
    }
    Js.Console.log(
      "[" ++ Belt.Int.toString(index + 1) ++ "/" ++ Belt.Int.toString(Belt.Array.length(beats)) ++
      "] " ++ beat.id,
    )
    /* a camera move follows the same beat-id-then-parent fallback the picture source uses */
    let camera = switch Js.Dict.get(overrides.cameras, beat.id) {
    | Some(move) => Some(move)
    | None => Js.Dict.get(overrides.cameras, parentIdOf(beat.id))
    }
    /* Consecutive sub-shots wired to the SAME clip continue it rather than restarting: the
       chest discovery replayed its first seconds three times before this. */
    let seek = switch source {
    | AcceptedMotion(path) =>
      switch (lastMotionPath.contents, index > 0) {
      | (Some(prev), true) if prev == path => lastMotionSeek.contents
      | _ => 0.0
      }
    | _ => 0.0
    }
    switch source {
    | AcceptedMotion(path) => {
        lastMotionPath := Some(path)
        lastMotionSeek := seek +. Belt.Int.toFloat(beat.durationSeconds)
      }
    | _ => lastMotionPath := None
    }
    renderSegment(~buildDirectory, ~index, ~beat, ~source, ~camera, ~seek, ~cleanPicture)
  })

  let concatPath = buildDirectory ++ "/segments.concat.txt"
  let concatBody = segments->Belt.Array.map(path => "file '" ++ resolve2(buildDirectory, path) ++ "'")
    ->Js.Array2.joinWith("\n")
  writeText(Path(concatPath), concatBody ++ "\n")
  ffmpeg([
    "-nostdin", "-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", concatPath,
    "-c", "copy", "-movflags", "+faststart", output,
  ])

  let contact = Js.String2.endsWith(output, ".mp4")
    ? Js.String2.slice(output, ~from=0, ~to_=Js.String2.length(output) - 4) ++ "_CONTACT.png"
    : output ++ "_CONTACT.png"
  ffmpeg([
    "-nostdin", "-v", "error", "-y", "-i", output,
    "-vf", "fps=1/36,scale=320:180,tile=5x4",
    "-frames:v", "1", contact,
  ])

  let Seconds(durationSeconds) = probeDuration(Path(output))
  if Js.Math.abs_float(durationSeconds -. Belt.Int.toFloat(mainSeconds)) > 0.05 {
    fail(
      "assembled duration is " ++ Js.Float.toString(durationSeconds) ++
      " seconds instead of " ++ Belt.Int.toString(mainSeconds),
    )
  }
  let probe = run(
    ~cmd="ffprobe",
    ~args=[
      "-v", "error", "-select_streams", "v:0", "-show_entries",
      "stream=width,height,r_frame_rate,codec_name", "-of", "default=nw=1", output,
    ],
  )
  requireSuccess(~label="final ffprobe", probe)
  if !Js.String2.includes(probe.stdout, "width=1280") ||
    !Js.String2.includes(probe.stdout, "height=720") ||
    !Js.String2.includes(probe.stdout, "r_frame_rate=24/1") {
    fail("assembled picture format is not 1280x720 at 24 fps: " ++ probe.stdout)
  }

  {
    output,
    contact,
    sha256: sha256File(Path(output)),
    durationSeconds,
    acceptedMotionBeats: acceptedMotionBeats.contents,
    acceptedStillBeats: acceptedStillBeats.contents,
    reviewStillBeats: reviewStillBeats.contents,
    placeholderBeats: placeholderBeats.contents,
  }
}

switch argv->Belt.Array.sliceToEnd(2) {
| [manifestArgument, outputArgument] =>
  try {
    let result = build(
      ~manifestPath=resolve2(".", manifestArgument),
      ~output=resolve2(".", outputArgument),
      ~reviewOverridePath=None,
      ~cleanPicture=false,
    )
    Js.Console.log("FAST ROUGH ANIMATIC COMPLETE")
    Js.Console.log(result.output)
    Js.Console.log("contact: " ++ result.contact)
    Js.Console.log("sha256: " ++ result.sha256)
    Js.Console.log(
      "720s | accepted motion " ++ Belt.Int.toString(result.acceptedMotionBeats) ++
      " | accepted still " ++ Belt.Int.toString(result.acceptedStillBeats) ++
      " | review still " ++ Belt.Int.toString(result.reviewStillBeats) ++
      " | placeholder " ++ Belt.Int.toString(result.placeholderBeats),
    )
  } catch {
  | FastRoughAnimaticError(message)
  | BackendError(message) => {
      Js.Console.error("FAST ROUGH ANIMATIC FAILED: " ++ message)
      exitProcess(1)
    }
  }
| [manifestArgument, outputArgument, overrideArgument] =>
  try {
    let result = build(
      ~manifestPath=resolve2(".", manifestArgument),
      ~output=resolve2(".", outputArgument),
      ~reviewOverridePath=Some(resolve2(".", overrideArgument)),
      ~cleanPicture=false,
    )
    Js.Console.log("FAST ROUGH ANIMATIC COMPLETE")
    Js.Console.log(result.output)
    Js.Console.log("contact: " ++ result.contact)
    Js.Console.log("sha256: " ++ result.sha256)
    Js.Console.log(
      "720s | accepted motion " ++ Belt.Int.toString(result.acceptedMotionBeats) ++
      " | accepted still " ++ Belt.Int.toString(result.acceptedStillBeats) ++
      " | review still " ++ Belt.Int.toString(result.reviewStillBeats) ++
      " | placeholder " ++ Belt.Int.toString(result.placeholderBeats),
    )
  } catch {
  | FastRoughAnimaticError(message)
  | BackendError(message) => {
      Js.Console.error("FAST ROUGH ANIMATIC FAILED: " ++ message)
      exitProcess(1)
    }
  }
| [manifestArgument, outputArgument, overrideArgument, "--clean-picture"] =>
  try {
    let result = build(
      ~manifestPath=resolve2(".", manifestArgument),
      ~output=resolve2(".", outputArgument),
      ~reviewOverridePath=Some(resolve2(".", overrideArgument)),
      ~cleanPicture=true,
    )
    Js.Console.log("FAST CLEAN-PICTURE ANIMATIC COMPLETE")
    Js.Console.log(result.output)
    Js.Console.log("contact: " ++ result.contact)
    Js.Console.log("sha256: " ++ result.sha256)
    Js.Console.log(
      "720s | accepted motion " ++ Belt.Int.toString(result.acceptedMotionBeats) ++
      " | accepted still " ++ Belt.Int.toString(result.acceptedStillBeats) ++
      " | review still rendered neutral " ++ Belt.Int.toString(result.reviewStillBeats) ++
      " | placeholder " ++ Belt.Int.toString(result.placeholderBeats),
    )
  } catch {
  | FastRoughAnimaticError(message)
  | BackendError(message) => {
      Js.Console.error("FAST CLEAN-PICTURE ANIMATIC FAILED: " ++ message)
      exitProcess(1)
    }
  }
| _ => {
    Js.Console.error(
      "usage: node src/Kuku_Ep9FastRoughAnimatic.res.mjs <animatic-edl-v2.json> <output.mp4> [review-overrides.json] [--clean-picture]",
    )
    exitProcess(2)
  }
}
