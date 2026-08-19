/* Offline validator for the Episode 9 finale's exact 2:15–14:15 animatic EDL. */

module B = Cinema_Backends

@module("node:path") external dirname: string => string = "dirname"
@module("node:path") external resolve2: (string, string) => string = "resolve"
@module("node:path") external isAbsolute: string => bool = "isAbsolute"

exception AnimaticEdlError(string)

let die = message => raise(AnimaticEdlError(message))

let objectOf = (json, where) =>
  switch Js.Json.decodeObject(json) {
  | Some(value) => value
  | None => die(where ++ " must be an object")
  }

let field = (object_, key, where) =>
  switch Js.Dict.get(object_, key) {
  | Some(value) => value
  | None => die(where ++ "." ++ key ++ " is required")
  }

let objectField = (object_, key, where) =>
  field(object_, key, where)->objectOf(where ++ "." ++ key)

let stringField = (object_, key, where) =>
  switch field(object_, key, where)->Js.Json.decodeString {
  | Some(value) => value
  | None => die(where ++ "." ++ key ++ " must be a string")
  }

let optionalStringField = (object_, key, where) =>
  switch Js.Dict.get(object_, key) {
  | None => None
  | Some(json) =>
    switch Js.Json.decodeString(json) {
    | Some(value) => Some(value)
    | None => die(where ++ "." ++ key ++ " must be a string when present")
    }
  }

let numberField = (object_, key, where) =>
  switch field(object_, key, where)->Js.Json.decodeNumber {
  | Some(value) => value
  | None => die(where ++ "." ++ key ++ " must be a number")
  }

let intField = (object_, key, where) => {
  let number = numberField(object_, key, where)
  let value = Belt.Float.toInt(number)
  if Belt.Int.toFloat(value) != number {
    die(where ++ "." ++ key ++ " must be an integer")
  }
  value
}

let boolField = (object_, key, where) =>
  switch field(object_, key, where)->Js.Json.decodeBoolean {
  | Some(value) => value
  | None => die(where ++ "." ++ key ++ " must be a boolean")
  }

let arrayField = (object_, key, where) =>
  switch field(object_, key, where)->Js.Json.decodeArray {
  | Some(value) => value
  | None => die(where ++ "." ++ key ++ " must be an array")
  }

let stringArrayField = (object_, key, where) =>
  arrayField(object_, key, where)->Belt.Array.mapWithIndex((index, json) =>
    switch Js.Json.decodeString(json) {
    | Some(value) => value
    | None => die(where ++ "." ++ key ++ "[" ++ Belt.Int.toString(index) ++ "] must be a string")
    }
  )

let readObject = (path, where) => {
  if !B.exists(B.Path(path)) {
    die(where ++ " cannot be read: file does not exist")
  }
  try B.readText(B.Path(path))->Js.Json.parseExn->objectOf(where) catch {
  | B.BackendError(message) => die(where ++ " cannot be read: " ++ message)
  | Js.Exn.Error(error) =>
    die(
      where ++ " is not valid JSON: " ++
      Js.Exn.message(error)->Belt.Option.getWithDefault("unknown parse error"),
    )
  }
}

let parseTimecode = (value, where) =>
  switch Js.String2.split(value, ":") {
  | [minutesText, secondsText] =>
    switch (Belt.Int.fromString(minutesText), Belt.Int.fromString(secondsText)) {
    | (Some(minutes), Some(seconds)) if minutes >= 0 && seconds >= 0 && seconds < 60 =>
      minutes * 60 + seconds
    | _ => die(where ++ " must be an M:SS timecode")
    }
  | _ => die(where ++ " must be an M:SS timecode")
  }

let approvedRootRelatives = [
  "../clips",
  "../references",
  "../local",
  "../local_motion",
  "../two_point_five_d",
  "../../coldopen",
  "../../../ep8prod",
]

let approvedAssetPath = (~manifestPath, ~relativePath) => {
  if relativePath == "" || isAbsolute(relativePath) {
    false
  } else {
    let manifestDirectory = dirname(manifestPath)
    let candidate = resolve2(manifestDirectory, relativePath)
    approvedRootRelatives->Belt.Array.some(rootRelative => {
      let root = resolve2(manifestDirectory, rootRelative)
      candidate == root || Js.String2.startsWith(candidate, root ++ "/")
    })
  }
}

let arraysEqual = (left, right) => {
  if Belt.Array.length(left) != Belt.Array.length(right) {
    false
  } else {
    let matches = ref(true)
    left->Belt.Array.forEachWithIndex((index, value) => {
      if Belt.Array.get(right, index) != Some(value) {
        matches := false
      }
    })
    matches.contents
  }
}

let allowedDialogueRefs = {
  let values: Js.Dict.t<bool> = Js.Dict.empty()
  [
    "chunk_006",
    "chunk_007",
    "chunk_008",
    "chunk_009",
    "chunk_010",
    "chunk_011",
    "chunk_012",
    "chunk_013",
    "chunk_014",
    "chunk_015",
    "chunk_016",
    "chunk_017",
    "chunk_019",
    "chunk_020",
    "chunk_021",
    "chunk_022",
    "chunk_023",
    "chunk_024",
    "chunk_025",
    "chunk_026",
  ]->Belt.Array.forEach(value => Js.Dict.set(values, value, true))
  values
}

let allowedEventRefs = {
  let values: Js.Dict.t<bool> = Js.Dict.empty()
  [
    "S01", "S02", "S03", "S04", "S05", "S06", "S07", "S08", "S09", "S10", "S11",
    "S12", "S13", "S14", "S15", "S16", "S17", "S18", "S19", "S20", "S21", "S22",
    "S23", "S24", "S25",
  ]->Belt.Array.forEach(value => Js.Dict.set(values, value, true))
  values
}

type paidRule = {scene: int, acquisitionSeconds: int}

type result = {
  beatCount: int,
  totalSeconds: int,
  paidSeconds: int,
  localMotionSeconds: int,
  twoPointFiveDSeconds: int,
  reuseSeconds: int,
  paidShotCount: int,
  placeholderCount: int,
}

let validate = (~manifestPath): result => {
  let manifestDirectory = dirname(manifestPath)
  let root = readObject(manifestPath, "animatic EDL")

  if stringField(root, "version", "animatic EDL") != "ep9-finale-animatic-edl-v1" {
    die("animatic EDL version has drifted")
  }

  let sources = objectField(root, "sourceDocuments", "animatic EDL")
  let shootingScriptRelative = stringField(sources, "shootingScript", "animatic EDL.sourceDocuments")
  let paidManifestRelative = stringField(sources, "paidShotManifest", "animatic EDL.sourceDocuments")
  let anchorManifestRelative = stringField(sources, "anchorManifest", "animatic EDL.sourceDocuments")
  let audioPlanRelative = stringField(sources, "audioPlan", "animatic EDL.sourceDocuments")
  if shootingScriptRelative != "../EP9_FINALE_SHOOTING_SCRIPT.md" ||
    paidManifestRelative != "ep9_finale_paid_shots.v1.json" ||
    anchorManifestRelative != "ep9_finale_anchor_stills.v1.json" ||
    audioPlanRelative != "../audio/EP9_MAIN_STORY_AUDIO_PLAN.md" {
    die("animatic EDL source-document paths are not approved")
  }
  [shootingScriptRelative, paidManifestRelative, anchorManifestRelative, audioPlanRelative]
  ->Belt.Array.forEach(relativePath => {
    if !B.exists(B.Path(resolve2(manifestDirectory, relativePath))) {
      die("animatic EDL source document does not exist: " ++ relativePath)
    }
  })

  let timeline = objectField(root, "timeline", "animatic EDL")
  let timelineStart = stringField(timeline, "start", "animatic EDL.timeline")
  let timelineEnd = stringField(timeline, "end", "animatic EDL.timeline")
  if timelineStart != "2:15" || timelineEnd != "14:15" ||
    intField(timeline, "durationSeconds", "animatic EDL.timeline") != 720 ||
    intField(timeline, "fps", "animatic EDL.timeline") != 24 ||
    stringField(timeline, "master", "animatic EDL.timeline") != "1280x720" {
    die("animatic EDL timeline must remain 2:15–14:15, 720 seconds, 24 fps, 1280x720")
  }

  let locked = arrayField(timeline, "lockedBeforeMain", "animatic EDL.timeline")
  if Belt.Array.length(locked) != 2 {
    die("animatic EDL must name the locked cold open and title before the main story")
  }
  let expectLocked = (index, start, end_, kind) => {
    let where = "animatic EDL.timeline.lockedBeforeMain[" ++ Belt.Int.toString(index) ++ "]"
    let row = Belt.Array.getExn(locked, index)->objectOf(where)
    if stringField(row, "start", where) != start || stringField(row, "end", where) != end_ ||
      stringField(row, "kind", where) != kind {
      die(where ++ " has drifted")
    }
  }
  expectLocked(0, "0:00", "2:00", "cold_open_reuse")
  expectLocked(1, "2:00", "2:15", "title_reuse")

  let policy = objectField(root, "policy", "animatic EDL")
  if !arraysEqual(
    stringArrayField(policy, "sourceClasses", "animatic EDL.policy"),
    ["paid_shot", "local_motion", "two_point_five_d", "reuse"],
  ) {
    die("animatic EDL source classes have drifted")
  }
  if !arraysEqual(
    stringArrayField(policy, "approvedAssetRoots", "animatic EDL.policy"),
    approvedRootRelatives,
  ) {
    die("animatic EDL approved asset roots have drifted")
  }
  if stringField(policy, "dialogueTiming", "animatic EDL.policy") !=
    "scene_chunk_only_unaligned" {
    die("animatic EDL must not claim unvalidated per-line dialogue timing")
  }
  if boolField(policy, "generatedAudioOnPaidShots", "animatic EDL.policy") {
    die("generated audio on paid shots must remain disabled")
  }
  let placeholder = objectField(policy, "acceptedAssetPlaceholder", "animatic EDL.policy")
  if stringField(placeholder, "path", "animatic EDL.policy.acceptedAssetPlaceholder") != "" ||
    stringField(placeholder, "sha256", "animatic EDL.policy.acceptedAssetPlaceholder") != "" {
    die("accepted asset placeholder must remain empty until an asset is approved")
  }

  let paidManifestPath = resolve2(manifestDirectory, paidManifestRelative)
  let paidRoot = readObject(paidManifestPath, "paid-shot manifest")
  let paidRules: Js.Dict.t<paidRule> = Js.Dict.empty()
  arrayField(paidRoot, "shots", "paid-shot manifest")->Belt.Array.forEachWithIndex(
    (index, shotJson) => {
      let where = "paid-shot manifest.shots[" ++ Belt.Int.toString(index) ++ "]"
      let shot = objectOf(shotJson, where)
      let id = stringField(shot, "id", where)
      if Js.Dict.get(paidRules, id) != None {
        die("duplicate paid-shot manifest id: " ++ id)
      }
      Js.Dict.set(paidRules, id, {
        scene: intField(shot, "scene", where),
        acquisitionSeconds: intField(shot, "durationSeconds", where),
      })
    },
  )
  if Js.Dict.keys(paidRules)->Belt.Array.length != 45 {
    die("paid-shot manifest must contain exactly 45 shot IDs")
  }

  let anchorManifestPath = resolve2(manifestDirectory, anchorManifestRelative)
  let anchorRoot = readObject(anchorManifestPath, "anchor manifest")
  let anchorIds: Js.Dict.t<bool> = Js.Dict.empty()
  arrayField(anchorRoot, "anchors", "anchor manifest")->Belt.Array.forEachWithIndex(
    (index, anchorJson) => {
      let where = "anchor manifest.anchors[" ++ Belt.Int.toString(index) ++ "]"
      let id = stringField(objectOf(anchorJson, where), "id", where)
      if Js.Dict.get(anchorIds, id) != None {
        die("duplicate anchor id: " ++ id)
      }
      Js.Dict.set(anchorIds, id, true)
    },
  )

  let beats = arrayField(root, "beats", "animatic EDL")
  let beatIds: Js.Dict.t<bool> = Js.Dict.empty()
  let seenPaid: Js.Dict.t<int> = Js.Dict.empty()
  let expectedStart = ref(parseTimecode(timelineStart, "animatic EDL.timeline.start"))
  let totalSeconds = ref(0)
  let paidSeconds = ref(0)
  let localMotionSeconds = ref(0)
  let twoPointFiveDSeconds = ref(0)
  let reuseSeconds = ref(0)
  let placeholderCount = ref(0)

  beats->Belt.Array.forEachWithIndex((index, beatJson) => {
    let where = "animatic EDL.beats[" ++ Belt.Int.toString(index) ++ "]"
    let beat = objectOf(beatJson, where)
    let id = stringField(beat, "id", where)
    if id == "" || Js.Dict.get(beatIds, id) != None {
      die(id == "" ? where ++ ".id must not be empty" : "duplicate EDL beat id: " ++ id)
    }
    Js.Dict.set(beatIds, id, true)

    let scene = intField(beat, "scene", where)
    if scene < 1 || scene > 10 {
      die(id ++ " uses an invalid scene number")
    }
    let startText = stringField(beat, "start", where)
    let endText = stringField(beat, "end", where)
    let start = parseTimecode(startText, where ++ ".start")
    let end_ = parseTimecode(endText, where ++ ".end")
    let duration = intField(beat, "durationSeconds", where)
    if start < expectedStart.contents {
      die(id ++ " overlaps the preceding beat")
    }
    if start > expectedStart.contents {
      die(id ++ " leaves a timeline gap")
    }
    if end_ <= start || end_ - start != duration {
      die(id ++ " has a wrong duration or reversed timecode")
    }
    if stringField(beat, "scriptRef", where) != startText ++ "–" ++ endText {
      die(id ++ " scriptRef must match its exact shooting-script time range")
    }
    if Js.String2.trim(stringField(beat, "storyEvent", where)) == "" {
      die(id ++ " must retain its shooting-script story event")
    }
    expectedStart := end_
    totalSeconds := totalSeconds.contents + duration

    let sourceClass = stringField(beat, "sourceClass", where)
    let paidShotId = optionalStringField(beat, "paidShotId", where)
    switch sourceClass {
    | "paid_shot" =>
      switch paidShotId {
      | Some(shotId) =>
        switch Js.Dict.get(paidRules, shotId) {
        | Some(rule) => {
            if rule.scene != scene {
              die(id ++ " uses paid shot " ++ shotId ++ " in the wrong scene")
            }
            let previous = Js.Dict.get(seenPaid, shotId)->Belt.Option.getWithDefault(0)
            let used = previous + duration
            if used > rule.acquisitionSeconds {
              die(id ++ " overuses acquisition duration for paid shot " ++ shotId)
            }
            Js.Dict.set(seenPaid, shotId, used)
          }
        | None => die(id ++ " uses unknown paid shot ID " ++ shotId)
        }
      | None => die(id ++ " is paid_shot but has no paidShotId")
      }
      paidSeconds := paidSeconds.contents + duration
    | "local_motion" => {
        if paidShotId != None {
          die(id ++ " is local_motion but carries a paidShotId")
        }
        localMotionSeconds := localMotionSeconds.contents + duration
      }
    | "two_point_five_d" => {
        if paidShotId != None {
          die(id ++ " is two_point_five_d but carries a paidShotId")
        }
        twoPointFiveDSeconds := twoPointFiveDSeconds.contents + duration
      }
    | "reuse" => {
        if paidShotId != None {
          die(id ++ " is reuse but carries a paidShotId")
        }
        reuseSeconds := reuseSeconds.contents + duration
      }
    | unknown => die(id ++ " uses unknown source class " ++ unknown)
    }

    stringArrayField(beat, "dialogueRefs", where)->Belt.Array.forEach(reference => {
      if Js.Dict.get(allowedDialogueRefs, reference) == None {
        die(id ++ " uses unknown dialogue reference " ++ reference)
      }
    })
    stringArrayField(beat, "eventRefs", where)->Belt.Array.forEach(reference => {
      if Js.Dict.get(allowedEventRefs, reference) == None {
        die(id ++ " uses unknown event reference " ++ reference)
      }
    })
    stringArrayField(beat, "anchorRefs", where)->Belt.Array.forEach(reference => {
      if Js.Dict.get(anchorIds, reference) == None {
        die(id ++ " uses unknown anchor reference " ++ reference)
      }
    })

    let acceptedPath = stringField(beat, "acceptedAssetPath", where)
    let acceptedSha = stringField(beat, "acceptedAssetSha256", where)
    if acceptedPath == "" {
      if acceptedSha != "" {
        die(id ++ " has an asset hash without an accepted path")
      }
      placeholderCount := placeholderCount.contents + 1
    } else {
      if acceptedSha == "" {
        die(id ++ " has an accepted asset path without a hash")
      }
      if !approvedAssetPath(~manifestPath, ~relativePath=acceptedPath) {
        die(id ++ " uses an unapproved source path: " ++ acceptedPath)
      }
      let resolved = resolve2(manifestDirectory, acceptedPath)
      if !B.exists(B.Path(resolved)) {
        die(id ++ " accepted source path does not exist: " ++ acceptedPath)
      }
      if !Js.Re.test_(%re("/^[A-Fa-f0-9]{64}$/"), acceptedSha) ||
        B.sha256File(B.Path(resolved)) != Js.String2.toLowerCase(acceptedSha) {
        die(id ++ " accepted source hash does not match the file")
      }
    }
  })

  if Belt.Array.length(beats) != 97 {
    die("animatic EDL must contain exactly 97 shooting-script beats")
  }
  if expectedStart.contents != parseTimecode(timelineEnd, "animatic EDL.timeline.end") ||
    totalSeconds.contents != 720 {
    die("animatic EDL must end exactly at 14:15 after 720 seconds")
  }
  if paidSeconds.contents != 370 || localMotionSeconds.contents != 160 ||
    twoPointFiveDSeconds.contents != 121 || reuseSeconds.contents != 69 {
    die("source-class totals must remain paid 370, local 160, 2.5D 121, reuse 69 seconds")
  }
  if Js.Dict.keys(seenPaid)->Belt.Array.length != 45 {
    let missing = Js.Dict.keys(paidRules)->Belt.Array.keep(id => Js.Dict.get(seenPaid, id) == None)
    die("animatic EDL is missing paid shot IDs: " ++ missing->Belt.Array.joinWith(", ", id => id))
  }

  {
    beatCount: Belt.Array.length(beats),
    totalSeconds: totalSeconds.contents,
    paidSeconds: paidSeconds.contents,
    localMotionSeconds: localMotionSeconds.contents,
    twoPointFiveDSeconds: twoPointFiveDSeconds.contents,
    reuseSeconds: reuseSeconds.contents,
    paidShotCount: Js.Dict.keys(seenPaid)->Belt.Array.length,
    placeholderCount: placeholderCount.contents,
  }
}

let printResult = result => {
  Js.log("KUKU EP9 FINALE ANIMATIC EDL — VALID")
  Js.log(
    Belt.Int.toString(result.beatCount) ++ " beats | " ++ Belt.Int.toString(result.totalSeconds) ++
    "s from 2:15 to 14:15 | " ++ Belt.Int.toString(result.paidShotCount) ++ " paid shot IDs",
  )
  Js.log(
    "paid " ++ Belt.Int.toString(result.paidSeconds) ++ "s | local " ++
    Belt.Int.toString(result.localMotionSeconds) ++ "s | 2.5D " ++
    Belt.Int.toString(result.twoPointFiveDSeconds) ++ "s | reuse " ++
    Belt.Int.toString(result.reuseSeconds) ++ "s | " ++
    Belt.Int.toString(result.placeholderCount) ++ " accepted-asset placeholders",
  )
}
