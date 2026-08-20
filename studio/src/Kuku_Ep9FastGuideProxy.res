/*
 * Fast scene-level guide-audio pass for the Episode 9 rough animatic.
 *
 * It reuses the already derived v5 source ranges, the six explicitly named
 * manual-review candidates, and the isolated mimic. Lines remain in screenplay
 * order and are distributed through their scene windows. This is a review mix,
 * not final stem approval or lip sync. One ffmpeg mix and one proxy encode; no
 * provider, extraction, per-line render, or production-manifest mutation.
 *
 * Run from studio/:
 *   node src/Kuku_Ep9FastGuideProxy.res.mjs <silent-animatic.mp4> <guide.m4a> <proxy.mp4>
 */

open Cinema_Backends

@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external exitProcess: int => unit = "exit"
@module("node:path") external dirname: string => string = "dirname"
@module("node:path") external resolve2: (string, string) => string = "resolve"
@module("node:path") external isAbsolute: string => bool = "isAbsolute"

exception FastGuideProxyError(string)

let fail = message => raise(FastGuideProxyError(message))

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
  | None => fail(where ++ "." ++ key ++ " must be text")
  }

let floatField = (object_, key, where) =>
  switch field(object_, key, where)->Js.Json.decodeNumber {
  | Some(value) => value
  | None => fail(where ++ "." ++ key ++ " must be a number")
  }

let intField = (object_, key, where) => Belt.Float.toInt(floatField(object_, key, where))

let arrayField = (object_, key, where) =>
  switch field(object_, key, where)->Js.Json.decodeArray {
  | Some(value) => value
  | None => fail(where ++ "." ++ key ++ " must be an array")
  }

let readObject = (path, where) => {
  if !exists(Path(path)) {
    fail(where ++ " does not exist: " ++ path)
  }
  try readText(Path(path))->Js.Json.parseExn->objectOf(where) catch {
  | Js.Exn.Error(error) =>
    fail(
      where ++ " is invalid JSON: " ++
      Js.Exn.message(error)->Belt.Option.getWithDefault("unknown parse error"),
    )
  }
}

let parseTimecode = value =>
  switch Js.String2.split(value, ":") {
  | [minutes, seconds] =>
    switch (Belt.Int.fromString(minutes), Belt.Int.fromString(seconds)) {
    | (Some(minutes), Some(seconds)) => minutes * 60 + seconds
    | _ => fail("invalid timecode " ++ value)
    }
  | _ => fail("invalid timecode " ++ value)
  }

type line = {
  order: int,
  scene: int,
  path: string,
  sourceStart: float,
  duration: float,
}

type sceneWindow = {start: float, duration: float}

type scheduledLine = {line: line, delayMs: int}

type result = {
  guide: string,
  proxy: string,
  guideSha256: string,
  proxySha256: string,
  lineCount: int,
  speechSeconds: float,
  proxyBytes: float,
}

let projectPath = (~repoRoot, declared) => {
  if isAbsolute(declared) {
    declared
  } else if Js.String2.startsWith(declared, "../stories/") {
    resolve2(repoRoot, Js.String2.sliceToEnd(declared, ~from=3))
  } else {
    resolve2(repoRoot, declared)
  }
}

let loadSceneByOrder = planPath => {
  let root = readObject(planPath, "table-read plan")
  let scenes: Js.Dict.t<int> = Js.Dict.empty()
  arrayField(root, "segments", "table-read plan")->Belt.Array.forEachWithIndex((index, json) => {
    let where = "table-read plan.segments[" ++ Belt.Int.toString(index) ++ "]"
    let row = objectOf(json, where)
    Js.Dict.set(scenes, Belt.Int.toString(intField(row, "order", where)), intField(row, "scene", where))
  })
  scenes
}

let loadDerivedLines = (~repoRoot, ~derivedDirectory, ~sceneByOrder) => {
  let byOrder: Js.Dict.t<line> = Js.Dict.empty()
  readDir(Path(derivedDirectory))
  ->Belt.Array.keep(name => Js.String2.endsWith(name, ".json"))
  ->Belt.Array.forEach(name => {
    let path = derivedDirectory ++ "/" ++ name
    let row = readObject(path, "derived timing " ++ name)
    if stringField(row, "pipeline_version", "derived timing") ==
      "kuku-ep9-finale-dialogue-v5-candidate-content-bound" {
      let order = intField(row, "order", "derived timing")
      let key = Belt.Int.toString(order)
      if Js.Dict.get(byOrder, key) == None {
        let scene = switch Js.Dict.get(sceneByOrder, key) {
        | Some(value) => value
        | None => fail("derived order has no screenplay scene: " ++ key)
        }
        let sourceStart = floatField(row, "source_start", "derived timing")
        let sourceEnd = floatField(row, "source_end", "derived timing")
        Js.Dict.set(byOrder, key, {
          order,
          scene,
          path: projectPath(~repoRoot, stringField(row, "source_audio", "derived timing")),
          sourceStart,
          duration: sourceEnd -. sourceStart,
        })
      }
    }
  })
  byOrder
}

let addManualCandidates = (~repoRoot, ~manualPath, ~byOrder) => {
  let root = readObject(manualPath, "manual-review manifest")
  arrayField(root, "exceptions", "manual-review manifest")
  ->Belt.Array.forEachWithIndex((index, json) => {
    let where = "manual-review manifest.exceptions[" ++ Belt.Int.toString(index) ++ "]"
    let row = objectOf(json, where)
    let order = intField(row, "order", where)
    let key = Belt.Int.toString(order)
    /* Manual candidates SUPERSEDE derived lines (story-logic delta v1, 2026-08-19: orders
       105/106/202 were re-recorded with corrected text, so the derived timing for those
       orders is stale by design). The retimer already resolves the same collision the same
       way — manual wins — and the two must agree or picture and sound drift apart. */
    if Js.Dict.get(byOrder, key) != None {
      Js.Console.log("  manual candidate supersedes derived order " ++ key)
    }
    Js.Dict.set(byOrder, key, {
      order,
      scene: intField(row, "scene", where),
      path: projectPath(~repoRoot, stringField(row, "candidate", where)),
      sourceStart: 0.0,
      duration: floatField(row, "candidate_duration_seconds", where),
    })
  })
}

let addMimic = (~mimicPath, ~byOrder) => {
  let Seconds(duration) = probeDuration(Path(mimicPath))
  Js.Dict.set(byOrder, "316", {
    order: 316,
    scene: 10,
    path: mimicPath,
    sourceStart: 0.0,
    duration,
  })
}

let loadSceneWindows = edlPath => {
  let root = readObject(edlPath, "animatic EDL")
  let timeline = field(root, "timeline", "animatic EDL")->objectOf("animatic EDL.timeline")
  let timelineStart = parseTimecode(stringField(timeline, "start", "animatic EDL.timeline"))
  let windows: Js.Dict.t<sceneWindow> = Js.Dict.empty()
  arrayField(root, "beats", "animatic EDL")->Belt.Array.forEachWithIndex((index, json) => {
    let where = "animatic EDL.beats[" ++ Belt.Int.toString(index) ++ "]"
    let row = objectOf(json, where)
    let scene = intField(row, "scene", where)
    let key = Belt.Int.toString(scene)
    let beatStart = parseTimecode(stringField(row, "start", where)) - timelineStart
    let beatDuration = floatField(row, "durationSeconds", where)
    switch Js.Dict.get(windows, key) {
    | Some(window) => Js.Dict.set(windows, key, {start: window.start, duration: window.duration +. beatDuration})
    | None => Js.Dict.set(windows, key, {start: Belt.Int.toFloat(beatStart), duration: beatDuration})
    }
  })
  windows
}


/* Beat-anchored dialogue windows (2026-08-18). The review mix spread each scene's lines
   evenly through the scene, so a voice could land a beat away from its picture — the user
   rejected that: we have exact per-line durations and we control the beat windows, so lines
   must play inside the beats that own them. plan.chunks[].segment_orders maps line→chunk;
   each EDL beat's dialogueRefs maps chunk→beats; a chunk's window is the span of its beats. */
let loadChunkByOrder = planPath => {
  let root = readObject(planPath, "table-read plan")
  let byOrder: Js.Dict.t<string> = Js.Dict.empty()
  arrayField(root, "chunks", "table-read plan")->Belt.Array.forEachWithIndex((index, json) => {
    let where = "table-read plan.chunks[" ++ Belt.Int.toString(index) ++ "]"
    let row = objectOf(json, where)
    let chunkId = stringField(row, "id", where)
    arrayField(row, "segment_orders", where)->Belt.Array.forEach(orderJson =>
      switch Js.Json.decodeNumber(orderJson) {
      | Some(order) => Js.Dict.set(byOrder, Js.Float.toString(order), chunkId)
      | None => fail(where ++ " has a non-numeric segment order")
      }
    )
  })
  byOrder
}

let loadChunkWindows = edlPath => {
  let root = readObject(edlPath, "animatic EDL")
  let timeline = field(root, "timeline", "animatic EDL")->objectOf("animatic EDL.timeline")
  let timelineStart = parseTimecode(stringField(timeline, "start", "animatic EDL.timeline"))
  let windows: Js.Dict.t<sceneWindow> = Js.Dict.empty()
  arrayField(root, "beats", "animatic EDL")->Belt.Array.forEachWithIndex((index, json) => {
    let where = "animatic EDL.beats[" ++ Belt.Int.toString(index) ++ "]"
    let row = objectOf(json, where)
    let beatStart = Belt.Int.toFloat(parseTimecode(stringField(row, "start", where)) - timelineStart)
    let beatDuration = floatField(row, "durationSeconds", where)
    switch Js.Dict.get(row, "dialogueRefs") {
    | Some(refsJson) =>
      switch Js.Json.decodeArray(refsJson) {
      | Some(refs) => refs->Belt.Array.forEach(refJson =>
          switch Js.Json.decodeString(refJson) {
          | Some(chunkId) =>
            switch Js.Dict.get(windows, chunkId) {
            | Some(w) => {
                let endOld = w.start +. w.duration
                let endNew = beatStart +. beatDuration
                let start = w.start < beatStart ? w.start : beatStart
                let end_ = endOld > endNew ? endOld : endNew
                Js.Dict.set(windows, chunkId, {start, duration: end_ -. start})
              }
            | None => Js.Dict.set(windows, chunkId, {start: beatStart, duration: beatDuration})
            }
          | None => ()
          }
        )
      | None => ()
      }
    | None => ()
    }
  })
  windows
}


/* Line-level beat anchors (ep9_dialogue_beat_anchors.v2.json): order -> beat id, authored by
   content match. Highest-precedence scheduling authority; chunk windows remain the fallback
   for any unanchored line. */
let loadLineAnchorWindows = (~anchorPath, ~edlPath) => {
  let root = readObject(edlPath, "animatic EDL")
  let timeline = field(root, "timeline", "animatic EDL")->objectOf("animatic EDL.timeline")
  let timelineStart = parseTimecode(stringField(timeline, "start", "animatic EDL.timeline"))
  let beatWindows: Js.Dict.t<sceneWindow> = Js.Dict.empty()
  arrayField(root, "beats", "animatic EDL")->Belt.Array.forEachWithIndex((index, json) => {
    let where = "animatic EDL.beats[" ++ Belt.Int.toString(index) ++ "]"
    let row = objectOf(json, where)
    let beatStart = Belt.Int.toFloat(parseTimecode(stringField(row, "start", where)) - timelineStart)
    Js.Dict.set(beatWindows, stringField(row, "id", where),
      {start: beatStart, duration: floatField(row, "durationSeconds", where)})
  })
  let anchorsRoot = readObject(anchorPath, "dialogue beat anchors")
  let anchors = field(anchorsRoot, "anchors", "dialogue beat anchors")
    ->objectOf("dialogue beat anchors.anchors")
  let byOrder: Js.Dict.t<sceneWindow> = Js.Dict.empty()
  Js.Dict.entries(anchors)->Belt.Array.forEach(((order, beatJson)) => {
    let (beatId, leadIn) = switch Js.Json.decodeString(beatJson) {
    | Some(id) => (id, 0.0)
    | None =>
      switch Js.Json.decodeObject(beatJson) {
      | Some(o) => {
          let id = switch Js.Dict.get(o, "beat") {
          | Some(v) =>
            switch Js.Json.decodeString(v) {
            | Some(id) => id
            | None => fail("anchor " ++ order ++ " beat is not a string")
            }
          | None => fail("anchor " ++ order ++ " has no beat")
          }
          let lead = switch Js.Dict.get(o, "leadIn") {
          | Some(v) =>
            switch Js.Json.decodeNumber(v) {
            | Some(n) => n
            | None => 0.0
            }
          | None => 0.0
          }
          (id, lead)
        }
      | None => fail("dialogue anchor for order " ++ order ++ " is not a string or object")
      }
    }
    switch Js.Dict.get(beatWindows, beatId) {
    | Some(w) =>
      Js.Dict.set(byOrder, order, {start: w.start +. leadIn, duration: w.duration -. leadIn})
    | None => fail("dialogue anchor references unknown beat " ++ beatId)
    }
  })
  byOrder
}

let scheduleLines = (~lines, ~windows, ~chunkByOrder, ~chunkWindows, ~lineWindows) => {
  let scheduled: array<scheduledLine> = []
  for scene in 1 to 10 {
    let sceneLines = lines->Belt.Array.keep(line => line.scene == scene)
    let window = switch Js.Dict.get(windows, Belt.Int.toString(scene)) {
    | Some(value) => value
    | None => fail("missing EDL window for scene " ++ Belt.Int.toString(scene))
    }
    /* Each line's DESIRED start is its anchored beat's start (line anchors first, chunk
       window else, scene window last). A naive forward packer cascaded here: one over-full
       beat pushed every later line, and by mid-scene the audio ran far behind the picture
       (the user: "the images are running ahead"). Instead: constrained scheduling —
       earliest[i] from packing forward, latest[i] from packing backward, then one monotone
       pass clamping each desired start into its feasible range. Overflow spreads into
       neighbouring slack on BOTH sides and can never cascade past it. */
    let n = Belt.Array.length(sceneLines)
    if n > 0 {
      let desired = sceneLines->Belt.Array.map(line => {
        let w = switch Js.Dict.get(lineWindows, Belt.Int.toString(line.order)) {
        | Some(lw) => lw
        | None =>
          switch Js.Dict.get(chunkByOrder, Belt.Int.toString(line.order)) {
          | Some(chunkId) =>
            switch Js.Dict.get(chunkWindows, chunkId) {
            | Some(cw) => cw
            | None => window
            }
          | None => window
          }
        }
        w.start
      })
      let earliest = Belt.Array.make(n, 0.0)
      let latest = Belt.Array.make(n, 0.0)
      for i in 0 to n - 1 {
        let prev = i == 0
          ? window.start
          : Belt.Array.getExn(earliest, i - 1) +. Belt.Array.getExn(sceneLines, i - 1).duration
        Belt.Array.setExn(earliest, i, prev)
      }
      for i in 0 to n - 1 {
        let j = n - 1 - i
        let next = j == n - 1
          ? window.start +. window.duration -. Belt.Array.getExn(sceneLines, j).duration
          : Belt.Array.getExn(latest, j + 1) -. Belt.Array.getExn(sceneLines, j).duration
        Belt.Array.setExn(latest, j, next)
      }
      let cursor = ref(window.start)
      for i in 0 to n - 1 {
        let line = Belt.Array.getExn(sceneLines, i)
        let lo = Belt.Array.getExn(earliest, i) > cursor.contents
          ? Belt.Array.getExn(earliest, i)
          : cursor.contents
        let want = Belt.Array.getExn(desired, i) +. 0.15
        let bounded = want < lo ? lo : want
        let hi = Belt.Array.getExn(latest, i)
        let start = bounded > hi ? hi : bounded
        Js.Array2.push(scheduled, {
          line,
          delayMs: Belt.Float.toInt(Js.Math.round(start *. 1000.0)),
        })->ignore
        cursor := start +. line.duration
      }
    }
    let speech = sceneLines->Belt.Array.reduce(0.0, (sum, line) => sum +. line.duration)
    Js.Console.log(
      "scene " ++ Belt.Int.toString(scene) ++ ": " ++
      Belt.Int.toString(Belt.Array.length(sceneLines)) ++ " lines, " ++
      Js.Float.toFixedWithPrecision(speech, ~digits=1) ++ "s speech, beat-anchored",
    )
  }
  scheduled
}

let build = (~silentVideo, ~guide, ~proxy): result => {
  if !exists(Path(silentVideo)) {
    fail("silent animatic does not exist: " ++ silentVideo)
  }
  /* the main story is as long as the picture — it grows when paid clips must play whole */
  let Seconds(silentSeconds) = probeDuration(Path(silentVideo))
  let mainSeconds = Js.Float.toString(Js.Math.round(silentSeconds))
  let finaleRoot = dirname(dirname(silentVideo))
  let repoRoot = resolve2(finaleRoot, "../../../..")
  let ep9Root = dirname(finaleRoot)
  let planPath = ep9Root ++ "/ep9_table_read_plan_v2_dream.json"
  let edlPath = finaleRoot ++ "/manifests/ep9_finale_animatic_edl.v4.json"
  let derivedDirectory = finaleRoot ++ "/audio/alignment/stem_validation/derived"
  let manualPath = finaleRoot ++
    "/audio/EP9_DIALOGUE_MANUAL_REVIEW_kuku-ep9-finale-dialogue-v5-candidate-content-bound.json"
  let mimicPath = ep9Root ++ "/table_read/cache/mimic_8ef8ac789738bd302ff7577a00c11ab1d8dd7dc887d0ec110daacd30ad627631.mp3"

  let sceneByOrder = loadSceneByOrder(planPath)
  let byOrder = loadDerivedLines(~repoRoot, ~derivedDirectory, ~sceneByOrder)
  addManualCandidates(~repoRoot, ~manualPath, ~byOrder)
  addMimic(~mimicPath, ~byOrder)
  let lines = Js.Dict.values(byOrder)
  Js.Array2.sortInPlaceWith(lines, (left, right) => left.order - right.order)->ignore
  /* 140 = 131 derived (3 of them superseded in place by re-recorded manual candidates)
     + 6 original manual candidates + 2 new delta lines (orders 95, 96) + 1 mimic. */
  if Belt.Array.length(lines) != 140 {
    fail(
      "expected 140 lines after story-logic delta v1; found " ++
      Belt.Int.toString(Belt.Array.length(lines)),
    )
  }
  let speechSeconds = lines->Belt.Array.reduce(0.0, (sum, line) => sum +. line.duration)
  if speechSeconds < 465.0 || speechSeconds > 495.0 {
    fail(
      "guide source duration drifted outside the post-delta window: " ++
      Js.Float.toFixedWithPrecision(speechSeconds, ~digits=1),
    )
  }
  lines->Belt.Array.forEach(line =>
    if !exists(Path(line.path)) {
      fail("guide source does not exist for order " ++ Belt.Int.toString(line.order) ++ ": " ++ line.path)
    }
  )
  let scheduled = scheduleLines(~lines, ~windows=loadSceneWindows(edlPath), ~chunkByOrder=loadChunkByOrder(planPath), ~chunkWindows=loadChunkWindows(edlPath), ~lineWindows=loadLineAnchorWindows(~anchorPath=finaleRoot ++ "/manifests/ep9_dialogue_beat_anchors.v2.json", ~edlPath))

  ensureDirPath(Path(dirname(guide)))
  ensureDirPath(Path(dirname(proxy)))
  let inputArgs: array<string> = ["-nostdin", "-v", "error", "-y"]
  let filters: array<string> = []
  scheduled->Belt.Array.forEachWithIndex((index, scheduledLine) => {
    let line = scheduledLine.line
    Js.Array2.push(inputArgs, "-ss")->ignore
    Js.Array2.push(inputArgs, Js.Float.toString(line.sourceStart))->ignore
    Js.Array2.push(inputArgs, "-t")->ignore
    Js.Array2.push(inputArgs, Js.Float.toString(line.duration))->ignore
    Js.Array2.push(inputArgs, "-i")->ignore
    Js.Array2.push(inputArgs, line.path)->ignore
    Js.Array2.push(
      filters,
      "[" ++ Belt.Int.toString(index) ++ ":a]aresample=48000," ++
      "aformat=sample_fmts=fltp:channel_layouts=stereo,asetpts=PTS-STARTPTS," ++
      "adelay=delays=" ++ Belt.Int.toString(scheduledLine.delayMs) ++ ":all=1[a" ++
      Belt.Int.toString(index) ++ "]",
    )->ignore
  })
  /* Sound effects ride the same mix, under the dialogue. Their timeline stores absolute
     episode seconds; the guide track starts at 2:15, so subtract that offset. A missing
     timeline simply means the SFX pass has not run yet — the guide still builds. */
  let sfxPath = finaleRoot ++ "/manifests/ep9_sfx_timeline.v1.json"
  let sfxCount = ref(0)
  if exists(Path(sfxPath)) {
    let sfxRoot = readObject(sfxPath, "sfx timeline")
    arrayField(sfxRoot, "cues", "sfx timeline")->Belt.Array.forEach(cueJson => {
      let cue = objectOf(cueJson, "sfx cue")
      let path = resolve2(finaleRoot ++ "/manifests", stringField(cue, "path", "sfx cue"))
      if exists(Path(path)) {
        let startMs = Belt.Float.toInt(
          (floatField(cue, "startSeconds", "sfx cue") -. 135.0) *. 1000.0,
        )
        if startMs >= 0 {
          let index = Belt.Array.length(scheduled) + sfxCount.contents
          Js.Array2.push(inputArgs, "-i")->ignore
          Js.Array2.push(inputArgs, path)->ignore
          Js.Array2.push(
            filters,
            "[" ++ Belt.Int.toString(index) ++ ":a]aresample=48000," ++
            "aformat=sample_fmts=fltp:channel_layouts=stereo,asetpts=PTS-STARTPTS," ++
            "volume=" ++ Js.Float.toString(floatField(cue, "gain", "sfx cue")) ++ "," ++
            "adelay=delays=" ++ Belt.Int.toString(startMs) ++ ":all=1[a" ++
            Belt.Int.toString(index) ++ "]",
          )->ignore
          sfxCount := sfxCount.contents + 1
        }
      }
    })
  }
  Js.Console.log(Belt.Int.toString(sfxCount.contents) ++ " sound effects mixed under the dialogue")

  let totalInputs = Belt.Array.length(scheduled) + sfxCount.contents
  let mixInputs = Belt.Array.range(0, totalInputs - 1)
    ->Belt.Array.map(index => "[a" ++ Belt.Int.toString(index) ++ "]")
    ->Js.Array2.joinWith("")
  let filterComplex = filters->Js.Array2.joinWith(";") ++ ";" ++ mixInputs ++
    "amix=inputs=" ++ Belt.Int.toString(totalInputs) ++
    ":duration=longest:dropout_transition=0:normalize=0," ++
    "alimiter=limit=0.95,apad=whole_dur=" ++ mainSeconds ++ ",atrim=0:" ++ mainSeconds ++ "[aout]"
  ffmpeg(Belt.Array.concatMany([
    inputArgs,
    [
      "-filter_complex", filterComplex, "-map", "[aout]", "-t", mainSeconds, "-c:a", "aac",
      "-b:a", "160k", "-ar", "48000", "-ac", "2", "-movflags", "+faststart", guide,
    ],
  ]))

  /* Letter-of-the-day bug: the episode's ब rides the top-right corner for the whole
     runtime (parent's request; top-left belongs to the shot chip). Burned into the review
     proxy here; the final-episode assembler must add the same overlay to its master. */
  let bug = finaleRoot ++ "/local/fx/ba_bug.png"
  ffmpeg([
    "-nostdin", "-v", "error", "-y", "-i", silentVideo, "-i", guide, "-i", bug,
    "-filter_complex",
    "[0:v]scale=960:540:flags=lanczos[v];" ++
    "[2:v]format=rgba,colorchannelmixer=aa=0.55[bug];" ++
    "[v][bug]overlay=W-w-14:12[vout]",
    "-map", "[vout]", "-map", "1:a:0",
    "-c:v", "libx264", "-preset", "veryfast", "-crf", "27", "-pix_fmt", "yuv420p",
    "-r", "24", "-c:a", "aac", "-b:a", "128k", "-ar", "48000", "-ac", "2",
    "-t", mainSeconds, "-movflags", "+faststart", proxy,
  ])

  let Seconds(guideDuration) = probeDuration(Path(guide))
  let Seconds(proxyDuration) = probeDuration(Path(proxy))
  let want = Belt.Float.fromString(mainSeconds)->Belt.Option.getWithDefault(720.0)
  if Js.Math.abs_float(guideDuration -. want) > 0.05 ||
    Js.Math.abs_float(proxyDuration -. want) > 0.05 {
    fail("guide or proxy duration does not match the main-story length")
  }
  let probe = run(
    ~cmd="ffprobe",
    ~args=[
      "-v", "error", "-show_entries", "stream=codec_type,width,height,r_frame_rate",
      "-of", "default=nw=1", proxy,
    ],
  )
  if probe.code != 0 || !Js.String2.includes(probe.stdout, "width=960") ||
    !Js.String2.includes(probe.stdout, "height=540") ||
    !Js.String2.includes(probe.stdout, "codec_type=audio") {
    fail("phone proxy format check failed: " ++ probe.stdout ++ probe.stderr)
  }
  {
    guide,
    proxy,
    guideSha256: sha256File(Path(guide)),
    proxySha256: sha256File(Path(proxy)),
    lineCount: Belt.Array.length(lines),
    speechSeconds,
    proxyBytes: fileSizeMb(Path(proxy)) *. 1000000.0,
  }
}

switch argv->Belt.Array.sliceToEnd(2) {
| [silentVideo, guide, proxy] =>
  try {
    let result = build(
      ~silentVideo=resolve2(".", silentVideo),
      ~guide=resolve2(".", guide),
      ~proxy=resolve2(".", proxy),
    )
    Js.Console.log("FAST GUIDE PROXY COMPLETE")
    Js.Console.log("guide: " ++ result.guide)
    Js.Console.log("guide sha256: " ++ result.guideSha256)
    Js.Console.log("proxy: " ++ result.proxy)
    Js.Console.log("proxy sha256: " ++ result.proxySha256)
    Js.Console.log(
      Belt.Int.toString(result.lineCount) ++ " lines | " ++
      Js.Float.toFixedWithPrecision(result.speechSeconds, ~digits=1) ++ "s speech | " ++
      Js.Float.toFixedWithPrecision(result.proxyBytes /. 1000000.0, ~digits=1) ++ " MB proxy",
    )
  } catch {
  | FastGuideProxyError(message)
  | BackendError(message) => {
      Js.Console.error("FAST GUIDE PROXY FAILED: " ++ message)
      exitProcess(1)
    }
  }
| _ => {
    Js.Console.error(
      "usage: node src/Kuku_Ep9FastGuideProxy.res.mjs <silent-animatic.mp4> <guide.m4a> <proxy.mp4>",
    )
    exitProcess(2)
  }
}
