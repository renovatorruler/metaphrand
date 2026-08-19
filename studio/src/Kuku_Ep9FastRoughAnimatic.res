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

type reviewOverrides = {
  sources: Js.Dict.t<source>,
  excludedAssets: Js.Dict.t<bool>,
}

let emptyReviewOverrides = () => {
  let sources: Js.Dict.t<source> = Js.Dict.empty()
  let excludedAssets: Js.Dict.t<bool> = Js.Dict.empty()
  {sources, excludedAssets}
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
  })
  loaded
}

let sourceFor = (~anchors, ~overrides, beat): source =>
  switch Js.Dict.get(overrides.sources, beat.id) {
  | Some(source) => source
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

let renderCard = (~buildDirectory, ~index, ~beat, ~source) => {
  let (label, color) = sourceLabel(source)
  let markup =
    "<span font=\"Avenir Next Bold 22\" foreground=\"" ++ color ++ "\">" ++
    escapeMarkup(label) ++ "</span>   " ++
    "<span font=\"Avenir Next Demi Bold 22\" foreground=\"#f5f1ff\">" ++
    escapeMarkup(beat.id ++ "  •  SCENE " ++ Belt.Int.toString(beat.scene) ++ "  •  " ++ beat.start ++ "–" ++ beat.end_) ++
    "</span>\n<span font=\"Noto Sans Devanagari 25\" foreground=\"#ffffff\">" ++
    escapeMarkup(beat.storyEvent) ++ "</span>"
  let card = buildDirectory ++ "/card_" ++ threeDigits(index) ++ ".png"
  let _ = pango(~markup, ~width=1100, ~background="#151327", ~out=Path(card))
  card
}

let commonOutputArgs = (~frames, ~output) => [
  "-map", "[out]", "-frames:v", Belt.Int.toString(frames), "-an", "-r", "24",
  "-c:v", "libx264", "-preset", "ultrafast", "-crf", "25", "-pix_fmt", "yuv420p",
  "-g", "24", "-keyint_min", "24", "-sc_threshold", "0", "-video_track_timescale", "24000",
  output,
]

let renderSegment = (~buildDirectory, ~index, ~beat, ~source, ~cleanPicture) => {
  let output = buildDirectory ++ "/" ++ segmentName(~index, ~beat)
  let frames = beat.durationSeconds * 24
  let tail = commonOutputArgs(~frames, ~output)
  if cleanPicture {
    switch source {
    | AcceptedMotion(path) =>
      ffmpeg(Belt.Array.concatMany([
        ["-nostdin", "-v", "error", "-y", "-stream_loop", "-1", "-i", path],
        [
          "-filter_complex",
          "[0:v]fps=24,scale=1280:720:force_original_aspect_ratio=increase," ++
          "crop=1280:720,setsar=1,format=yuv420p[out]",
        ],
        tail,
      ]))
    | AcceptedStill(path) =>
      ffmpeg(Belt.Array.concatMany([
        ["-nostdin", "-v", "error", "-y", "-loop", "1", "-framerate", "24", "-i", path],
        [
          "-filter_complex",
          "[0:v]scale=1344:756:force_original_aspect_ratio=increase,crop=1344:756," ++
          "zoompan=z='min(zoom+0.00008,1.05)':x='iw/2-(iw/zoom/2)':" ++
          "y='ih/2-(ih/zoom/2)':d=1:s=1280x720:fps=24,setsar=1," ++
          "format=yuv420p[out]",
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
    let card = renderCard(~buildDirectory, ~index, ~beat, ~source)
    switch source {
  | AcceptedMotion(path) =>
    ffmpeg(Belt.Array.concatMany([
      ["-nostdin", "-v", "error", "-y", "-stream_loop", "-1", "-i", path, "-loop", "1", "-i", card],
      [
        "-filter_complex",
        "[0:v]fps=24,scale=1280:720:force_original_aspect_ratio=increase," ++
        "crop=1280:720,setsar=1[base];[1:v]format=rgba[card];" ++
        "[base][card]overlay=0:H-h:shortest=0,format=yuv420p[out]",
      ],
      tail,
    ]))
  | AcceptedStill(path)
  | ReviewStill(path) =>
    ffmpeg(Belt.Array.concatMany([
      ["-nostdin", "-v", "error", "-y", "-loop", "1", "-framerate", "24", "-i", path, "-loop", "1", "-i", card],
      [
        "-filter_complex",
        "[0:v]scale=1344:756:force_original_aspect_ratio=increase,crop=1344:756," ++
        "zoompan=z='min(zoom+0.00008,1.05)':x='iw/2-(iw/zoom/2)':" ++
        "y='ih/2-(ih/zoom/2)':d=1:s=1280x720:fps=24,setsar=1[base];" ++
        "[1:v]format=rgba[card];[base][card]overlay=0:H-h:shortest=0,format=yuv420p[out]",
      ],
      tail,
    ]))
  | Placeholder =>
    ffmpeg(Belt.Array.concatMany([
      [
        "-nostdin", "-v", "error", "-y", "-f", "lavfi", "-i",
        "color=c=0x201a38:s=1280x720:r=24", "-loop", "1", "-i", card,
      ],
      [
        "-filter_complex",
        "[0:v]drawbox=x=56:y=48:w=1168:h=624:color=0x6f5aa8@0.20:t=6[base];" ++
        "[1:v]format=rgba[card];[base][card]overlay=0:(H-h)/2:shortest=0,format=yuv420p[out]",
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
    Kuku_Ep9FinaleAnimaticEdlV2.isV3(~manifestPath)
      ? Kuku_Ep9FinaleAnimaticEdlV2.validateV3(~manifestPath)
      : Kuku_Ep9FinaleAnimaticEdlV2.validate(~manifestPath)
  ) catch {
  | Kuku_Ep9FinaleAnimaticEdlV2.AnimaticEdlV2Error(message) =>
    fail("EDL validation failed: " ++ message)
  }
  if validation.totalSeconds != 720 {
    fail("the validated EDL is not the required 720 seconds")
  }

  let manifestDirectory = dirname(manifestPath)
  let root = readObject(manifestPath, "EDL")
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
    renderSegment(~buildDirectory, ~index, ~beat, ~source, ~cleanPicture)
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
  if Js.Math.abs_float(durationSeconds -. 720.0) > 0.05 {
    fail(
      "assembled duration is " ++ Js.Float.toString(durationSeconds) ++
      " seconds instead of 720",
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
