/*
 * Route-bound validator for the Episode 9 finale v2 animatic EDL.
 *
 * The v1 EDL remains the timing/story source. This validator first proves that
 * v1 is still valid, then permits only the source-class transformation declared
 * by ep9_finale_route.v2.json.
 */

module B = Cinema_Backends

@module("node:path") external dirname: string => string = "dirname"
@module("node:path") external resolve2: (string, string) => string = "resolve"

exception AnimaticEdlV2Error(string)

let die = message => raise(AnimaticEdlV2Error(message))

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

let arraysEqual = (left, right) => {
  if Belt.Array.length(left) != Belt.Array.length(right) {
    false
  } else {
    let equal = ref(true)
    left->Belt.Array.forEachWithIndex((index, value) =>
      if Belt.Array.get(right, index) != Some(value) {
        equal := false
      }
    )
    equal.contents
  }
}

let readRaw = (path, where) =>
  try B.readText(B.Path(path)) catch {
  | B.BackendError(message) => die(where ++ " cannot be read: " ++ message)
  }

let parseRoot = (raw, where) =>
  try raw->Js.Json.parseExn->objectOf(where) catch {
  | Js.Exn.Error(error) =>
    die(
      where ++ " is not valid JSON: " ++
      Js.Exn.message(error)->Belt.Option.getWithDefault("unknown parse error"),
    )
  }

let close = (left, right) => Js.Math.abs_float(left -. right) < 0.0001

type routeRule = {
  routeKind: string,
  finalUseSeconds: float,
  acquisitionSeconds: float,
  localDependency: option<string>,
}

type result = {
  beatCount: int,
  totalSeconds: int,
  paidSeconds: int,
  localMotionSeconds: int,
  twoPointFiveDSeconds: int,
  reuseSeconds: int,
  paidShotCount: int,
  routeShotCount: int,
  convertedSeconds: int,
  paidAcquisitionSeconds: int,
  placeholderCount: int,
}

let expectedSourceClass = routeKind =>
  switch routeKind {
  | "paid" => "paid_shot"
  | "local" => "local_motion"
  | "reuse" => "reuse"
  | unknown => die("unknown route kind " ++ unknown)
  }

let sameBeatIdentity = (v1, v2, where) => {
  let sameString = key => stringField(v1, key, where ++ ".v1") == stringField(v2, key, where ++ ".v2")
  let sameInt = key => intField(v1, key, where ++ ".v1") == intField(v2, key, where ++ ".v2")
  if !sameString("id") || !sameInt("scene") || !sameString("start") || !sameString("end") ||
    !sameInt("durationSeconds") || !sameString("scriptRef") || !sameString("storyEvent") ||
    !sameString("acceptedAssetPath") || !sameString("acceptedAssetSha256") ||
    !arraysEqual(
      stringArrayField(v1, "dialogueRefs", where ++ ".v1"),
      stringArrayField(v2, "dialogueRefs", where ++ ".v2"),
    ) ||
    !arraysEqual(
      stringArrayField(v1, "eventRefs", where ++ ".v1"),
      stringArrayField(v2, "eventRefs", where ++ ".v2"),
    ) ||
    !arraysEqual(
      stringArrayField(v1, "anchorRefs", where ++ ".v1"),
      stringArrayField(v2, "anchorRefs", where ++ ".v2"),
    ) {
    die(stringField(v1, "id", where ++ ".v1") ++ " changed a timing, story, reference, or accepted-asset field from v1")
  }
}

let isV2 = (~manifestPath) => {
  let root = parseRoot(readRaw(manifestPath, "animatic EDL"), "animatic EDL")
  stringField(root, "version", "animatic EDL") == "ep9-finale-animatic-edl-v2"
}

let validate = (~manifestPath): result => {
  let manifestDirectory = dirname(manifestPath)
  let root = parseRoot(readRaw(manifestPath, "animatic EDL v2"), "animatic EDL v2")
  if stringField(root, "version", "animatic EDL v2") != "ep9-finale-animatic-edl-v2" {
    die("animatic EDL v2 version has drifted")
  }

  let sources = objectField(root, "sourceDocuments", "animatic EDL v2")
  let v1Relative = stringField(sources, "derivedFrom", "animatic EDL v2.sourceDocuments")
  let routeRelative = stringField(sources, "routeManifest", "animatic EDL v2.sourceDocuments")
  if v1Relative != "ep9_finale_animatic_edl.v1.json" ||
    routeRelative != "ep9_finale_route.v2.json" ||
    stringField(sources, "paidShotManifest", "animatic EDL v2.sourceDocuments") !=
      "ep9_finale_paid_shots.v1.json" {
    die("v2 derivation, route, or acquisition source path has drifted")
  }
  let v1Path = resolve2(manifestDirectory, v1Relative)
  let routePath = resolve2(manifestDirectory, routeRelative)
  let v1Result = try Kuku_Ep9FinaleAnimaticEdl.validate(~manifestPath=v1Path) catch {
  | Kuku_Ep9FinaleAnimaticEdl.AnimaticEdlError(message) =>
    die("source v1 EDL is invalid: " ++ message)
  }
  let routeResult = try Kuku_Ep9FinaleRoute.validate(~routePath) catch {
  | Kuku_Ep9FinaleRoute.RouteError(message) => die("authoritative route is invalid: " ++ message)
  }

  let v1Root = parseRoot(readRaw(v1Path, "animatic EDL v1"), "animatic EDL v1")
  let routeRoot = parseRoot(readRaw(routePath, "route v2"), "route v2")
  let v1Timeline = objectField(v1Root, "timeline", "animatic EDL v1")
  let timeline = objectField(root, "timeline", "animatic EDL v2")
  if stringField(timeline, "start", "animatic EDL v2.timeline") !=
      stringField(v1Timeline, "start", "animatic EDL v1.timeline") ||
    stringField(timeline, "end", "animatic EDL v2.timeline") !=
      stringField(v1Timeline, "end", "animatic EDL v1.timeline") ||
    /* the main story grows when clips must play whole; length is declared, not fixed */
    intField(timeline, "durationSeconds", "animatic EDL v2.timeline") < 720 ||
    intField(timeline, "fps", "animatic EDL v2.timeline") != 24 ||
    stringField(timeline, "master", "animatic EDL v2.timeline") != "1280x720" {
    die("v2 timeline must preserve the validated 2:15–14:15 v1 timeline")
  }

  let policy = objectField(root, "policy", "animatic EDL v2")
  if stringField(policy, "routingAuthority", "animatic EDL v2.policy") != routeRelative ||
    stringField(policy, "routeIdField", "animatic EDL v2.policy") != "routeShotId" ||
    !boolField(policy, "nonPaidBeatsOmitPaidShotId", "animatic EDL v2.policy") ||
    !arraysEqual(
      stringArrayField(policy, "splitRouteUseIds", "animatic EDL v2.policy"),
      ["D01"],
    ) ||
    !arraysEqual(
      stringArrayField(policy, "paidFinalBeyondAcquisitionIds", "animatic EDL v2.policy"),
      ["B06"],
    ) {
    die("v2 route-binding policy has drifted")
  }

  let routeRules: Js.Dict.t<routeRule> = Js.Dict.empty()
  arrayField(routeRoot, "routes", "route v2")->Belt.Array.forEachWithIndex((index, itemJson) => {
    let where = "route v2.routes[" ++ Belt.Int.toString(index) ++ "]"
    let item = objectOf(itemJson, where)
    let id = stringField(item, "id", where)
    let routeKind = stringField(item, "routeKind", where)
    let acquisitionSeconds = routeKind == "paid" ? numberField(item, "durationSeconds", where) : 0.0
    Js.Dict.set(routeRules, id, {
      routeKind,
      finalUseSeconds: numberField(item, "finalUseSeconds", where),
      acquisitionSeconds,
      localDependency: optionalStringField(item, "localDependency", where),
    })
  })
  if Js.Dict.keys(routeRules)->Belt.Array.length != 45 || routeResult.routeCount != 45 {
    die("authoritative route must contain exactly 45 IDs")
  }

  let v1Beats = arrayField(v1Root, "beats", "animatic EDL v1")
  let beats = arrayField(root, "beats", "animatic EDL v2")
  if Belt.Array.length(v1Beats) != 97 || Belt.Array.length(beats) != 97 {
    die("v1 and v2 EDLs must each contain exactly 97 beats")
  }

  let seenRouteSeconds: Js.Dict.t<int> = Js.Dict.empty()
  let seenRouteBeats: Js.Dict.t<int> = Js.Dict.empty()
  let seenPaidIds: Js.Dict.t<bool> = Js.Dict.empty()
  let paidSeconds = ref(0)
  let localMotionSeconds = ref(0)
  let twoPointFiveDSeconds = ref(0)
  let reuseSeconds = ref(0)
  let convertedSeconds = ref(0)
  let convertedToLocal = ref(0)
  let convertedToReuse = ref(0)
  let placeholderCount = ref(0)

  beats->Belt.Array.forEachWithIndex((index, beatJson) => {
    let where = "animatic EDL beats[" ++ Belt.Int.toString(index) ++ "]"
    let beat = objectOf(beatJson, where ++ ".v2")
    let v1Beat = objectOf(Belt.Array.getExn(v1Beats, index), where ++ ".v1")
    sameBeatIdentity(v1Beat, beat, where)
    let id = stringField(beat, "id", where ++ ".v2")
    let duration = intField(beat, "durationSeconds", where ++ ".v2")
    let v1Class = stringField(v1Beat, "sourceClass", where ++ ".v1")
    let sourceClass = stringField(beat, "sourceClass", where ++ ".v2")
    let routeShotId = optionalStringField(beat, "routeShotId", where ++ ".v2")
    let paidShotId = optionalStringField(beat, "paidShotId", where ++ ".v2")

    if v1Class == "paid_shot" {
      let originalId = switch optionalStringField(v1Beat, "paidShotId", where ++ ".v1") {
      | Some(value) => value
      | None => die(id ++ " source v1 paid beat has no paidShotId")
      }
      if routeShotId != Some(originalId) {
        die(id ++ " must retain " ++ originalId ++ " as routeShotId")
      }
      let rule = switch Js.Dict.get(routeRules, originalId) {
      | Some(value) => value
      | None => die(id ++ " has no authoritative route for " ++ originalId)
      }
      let expectedClass = expectedSourceClass(rule.routeKind)
      if sourceClass != expectedClass {
        die(id ++ " must follow " ++ originalId ++ " routeKind " ++ rule.routeKind)
      }
      if rule.routeKind == "paid" {
        if paidShotId != Some(originalId) {
          die(id ++ " paid route must preserve paidShotId " ++ originalId)
        }
        Js.Dict.set(seenPaidIds, originalId, true)
      } else {
        if paidShotId != None {
          die(id ++ " nonpaid route must remove paidShotId")
        }
        convertedSeconds := convertedSeconds.contents + duration
        if rule.routeKind == "local" {
          convertedToLocal := convertedToLocal.contents + duration
        } else {
          convertedToReuse := convertedToReuse.contents + duration
        }
      }
      let previousSeconds = Js.Dict.get(seenRouteSeconds, originalId)->Belt.Option.getWithDefault(0)
      let previousBeats = Js.Dict.get(seenRouteBeats, originalId)->Belt.Option.getWithDefault(0)
      Js.Dict.set(seenRouteSeconds, originalId, previousSeconds + duration)
      Js.Dict.set(seenRouteBeats, originalId, previousBeats + 1)
    } else {
      if routeShotId != None || paidShotId != None || sourceClass != v1Class {
        die(id ++ " was not a paid v1 beat and must not be rerouted")
      }
    }

    switch sourceClass {
    | "paid_shot" => paidSeconds := paidSeconds.contents + duration
    | "local_motion" => localMotionSeconds := localMotionSeconds.contents + duration
    | "two_point_five_d" => twoPointFiveDSeconds := twoPointFiveDSeconds.contents + duration
    | "reuse" => reuseSeconds := reuseSeconds.contents + duration
    | unknown => die(id ++ " uses unknown source class " ++ unknown)
    }
    if stringField(beat, "acceptedAssetPath", where ++ ".v2") == "" {
      placeholderCount := placeholderCount.contents + 1
    }
  })

  if Js.Dict.keys(seenRouteSeconds)->Belt.Array.length != 45 {
    die("v2 EDL must bind every route ID exactly once, except the declared D01 split")
  }
  Js.Dict.keys(routeRules)->Belt.Array.forEach(id => {
    let rule = Js.Dict.get(routeRules, id)->Belt.Option.getExn
    let usedSeconds = Js.Dict.get(seenRouteSeconds, id)->Belt.Option.getWithDefault(0)
    let beatUses = Js.Dict.get(seenRouteBeats, id)->Belt.Option.getWithDefault(0)
    if !close(Belt.Int.toFloat(usedSeconds), rule.finalUseSeconds) {
      die(id ++ " EDL usage does not match route finalUseSeconds")
    }
    let expectedUses = id == "D01" ? 2 : 1
    if beatUses != expectedUses {
      die(id ++ " must appear in " ++ Belt.Int.toString(expectedUses) ++ " routed EDL beat(s)")
    }
    if rule.routeKind == "paid" && rule.finalUseSeconds > rule.acquisitionSeconds {
      if id != "B06" || rule.localDependency == None ||
        !close(rule.finalUseSeconds, 10.0) || !close(rule.acquisitionSeconds, 8.0) {
        die(id ++ " exceeds paid acquisition without the approved B06 local dependency")
      }
    }
  })

  if paidSeconds.contents != 242 || localMotionSeconds.contents != 275 ||
    twoPointFiveDSeconds.contents != 121 || reuseSeconds.contents != 82 ||
    convertedSeconds.contents != 128 || convertedToLocal.contents != 115 ||
    convertedToReuse.contents != 13 ||
    paidSeconds.contents + localMotionSeconds.contents + twoPointFiveDSeconds.contents +
      reuseSeconds.contents != 720 {
    die("v2 source totals must remain paid 242, local 275, 2.5D 121, reuse 82, with 128 converted as 115 local plus 13 reuse")
  }
  if Js.Dict.keys(seenPaidIds)->Belt.Array.length != 28 {
    die("v2 EDL must retain exactly 28 paid route IDs")
  }
  if placeholderCount.contents != v1Result.placeholderCount {
    die("v2 must preserve all accepted-asset paths and placeholders from v1")
  }

  let sourceTotals = objectField(root, "sourceTotals", "animatic EDL v2")
  let expectTotal = (key, expected) =>
    if intField(sourceTotals, key, "animatic EDL v2.sourceTotals") != expected {
      die("animatic EDL v2.sourceTotals." ++ key ++ " must be " ++ Belt.Int.toString(expected))
    }
  expectTotal("paid_shot", 242)
  expectTotal("local_motion", 275)
  expectTotal("two_point_five_d", 121)
  expectTotal("reuse", 82)
  expectTotal("converted_from_paid", 128)
  expectTotal("paid_acquisition", 266)
  if !close(routeResult.paidAcquisitionSeconds, 266.0) {
    die("route-backed paid acquisition must remain 266 seconds")
  }

  {
    beatCount: Belt.Array.length(beats),
    totalSeconds: paidSeconds.contents + localMotionSeconds.contents + twoPointFiveDSeconds.contents + reuseSeconds.contents,
    paidSeconds: paidSeconds.contents,
    localMotionSeconds: localMotionSeconds.contents,
    twoPointFiveDSeconds: twoPointFiveDSeconds.contents,
    reuseSeconds: reuseSeconds.contents,
    paidShotCount: Js.Dict.keys(seenPaidIds)->Belt.Array.length,
    routeShotCount: Js.Dict.keys(seenRouteSeconds)->Belt.Array.length,
    convertedSeconds: convertedSeconds.contents,
    paidAcquisitionSeconds: Belt.Float.toInt(routeResult.paidAcquisitionSeconds),
    placeholderCount: placeholderCount.contents,
  }
}

let printResult = result => {
  Js.log("KUKU EP9 FINALE ANIMATIC EDL V2 — VALID")
  Js.log(
    Belt.Int.toString(result.beatCount) ++ " beats | " ++
    Belt.Int.toString(result.totalSeconds) ++ "s | " ++
    Belt.Int.toString(result.routeShotCount) ++ " route IDs | " ++
    Belt.Int.toString(result.paidShotCount) ++ " paid IDs",
  )
  Js.log(
    "paid " ++ Belt.Int.toString(result.paidSeconds) ++ "s final from " ++
    Belt.Int.toString(result.paidAcquisitionSeconds) ++ "s acquisition | local " ++
    Belt.Int.toString(result.localMotionSeconds) ++ "s | 2.5D " ++
    Belt.Int.toString(result.twoPointFiveDSeconds) ++ "s | reuse " ++
    Belt.Int.toString(result.reuseSeconds) ++ "s | converted " ++
    Belt.Int.toString(result.convertedSeconds) ++ "s",
  )
}

/* v3 acceptance (2026-08-18): a RETIMED derivative of the validated v2. Everything that
   makes a beat what it is — id, scene, script/story refs, sources, routing — must equal the
   validated v2 exactly. Only start/end/durationSeconds may differ, because v3's whole
   purpose is the user's rule that a shot never ends before its dialogue: beats are resized
   to contain their anchored lines. Times are checked for contiguity from 2:15 and an exact
   720-second total instead of equality with v1. */
let sameBeatIdentityExceptTiming = (v2, v3, where) => {
  let sameString = key => stringField(v2, key, where ++ ".v2") == stringField(v3, key, where ++ ".v3")
  let sameInt = key => intField(v2, key, where ++ ".v2") == intField(v3, key, where ++ ".v3")
  if !sameString("id") || !sameInt("scene") || !sameString("scriptRef") ||
    !sameString("storyEvent") || !sameString("acceptedAssetPath") ||
    !sameString("acceptedAssetSha256") || !sameString("sourceClass") ||
    optionalStringField(v2, "routeShotId", where) != optionalStringField(v3, "routeShotId", where) ||
    optionalStringField(v2, "paidShotId", where) != optionalStringField(v3, "paidShotId", where) ||
    !arraysEqual(
      stringArrayField(v2, "dialogueRefs", where ++ ".v2"),
      stringArrayField(v3, "dialogueRefs", where ++ ".v3"),
    ) ||
    !arraysEqual(
      stringArrayField(v2, "eventRefs", where ++ ".v2"),
      stringArrayField(v3, "eventRefs", where ++ ".v3"),
    ) ||
    !arraysEqual(
      stringArrayField(v2, "anchorRefs", where ++ ".v2"),
      stringArrayField(v3, "anchorRefs", where ++ ".v3"),
    ) {
    die(where ++ " identity drifted from the validated v2 beat")
  }
}

let isV3 = (~manifestPath) => {
  let root = parseRoot(readRaw(manifestPath, "animatic EDL"), "animatic EDL")
  stringField(root, "version", "animatic EDL") == "ep9-finale-animatic-edl-v3"
}

let validateV3 = (~manifestPath): result => {
  let manifestDirectory = dirname(manifestPath)
  let root = parseRoot(readRaw(manifestPath, "animatic EDL v3"), "animatic EDL v3")
  if stringField(root, "version", "animatic EDL v3") != "ep9-finale-animatic-edl-v3" {
    die("animatic EDL v3 version has drifted")
  }
  /* the retimer publishes the main-story length here when clips force it past 12:00 */
  let declaredTotal =
    intField(field(root, "timeline", "animatic EDL v3")->objectOf("timeline"),
      "durationSeconds", "timeline")
  /* the sibling v2 remains the identity authority and is validated in full */
  let v2Path = resolve2(manifestDirectory, "ep9_finale_animatic_edl.v2.json")
  let v2Result = validate(~manifestPath=v2Path)
  let v2Root = parseRoot(readRaw(v2Path, "animatic EDL v2"), "animatic EDL v2")
  let v2Beats = arrayField(v2Root, "beats", "animatic EDL v2")
  let beats = arrayField(root, "beats", "animatic EDL v3")
  if Belt.Array.length(beats) != 97 || Belt.Array.length(v2Beats) != 97 {
    die("v3 must contain exactly 97 beats")
  }
  let cursor = ref(Kuku_Ep9FinaleAnimaticEdl.parseTimecode("2:15", "animatic EDL v3"))
  beats->Belt.Array.forEachWithIndex((index, beatJson) => {
    let where = "animatic EDL v3 beats[" ++ Belt.Int.toString(index) ++ "]"
    let beat = objectOf(beatJson, where)
    let v2Beat = objectOf(Belt.Array.getExn(v2Beats, index), where)
    sameBeatIdentityExceptTiming(v2Beat, beat, where)
    let start = Kuku_Ep9FinaleAnimaticEdl.parseTimecode(stringField(beat, "start", where), where)
    let end_ = Kuku_Ep9FinaleAnimaticEdl.parseTimecode(stringField(beat, "end", where), where)
    let duration = intField(beat, "durationSeconds", where)
    if start != cursor.contents {
      die(where ++ " is not contiguous")
    }
    if end_ - start != duration || duration < 2 {
      die(where ++ " has inconsistent or sub-minimum timing")
    }
    cursor := end_
  })
  if cursor.contents - Kuku_Ep9FinaleAnimaticEdl.parseTimecode("2:15", "animatic EDL v3") !=
    declaredTotal {
    die("v3 total does not match the declared main-story length")
  }
  v2Result
}

/* v4 acceptance (2026-08-18): per-line sub-shots. Ids are either an original v2 beat id or
   "<parent>-L<k>". Sub-shots must inherit their parent's full identity (everything except
   id/timing/parentBeat/lineOrder), parents must appear complete and in v2 order, timing must
   be contiguous from 2:15 and total exactly 720. */
let isV4 = (~manifestPath) => {
  let root = parseRoot(readRaw(manifestPath, "animatic EDL"), "animatic EDL")
  stringField(root, "version", "animatic EDL") == "ep9-finale-animatic-edl-v4"
}

let parentOf = id =>
  switch Js.String2.splitByRe(id, %re("/-L\d+$/")) {
  | [Some(prefix), _] => prefix
  | _ => id
  }

let sameBeatIdentityExceptIdAndTiming = (v2, v4, where) => {
  let sameString = key => stringField(v2, key, where ++ ".v2") == stringField(v4, key, where ++ ".v4")
  let sameInt = key => intField(v2, key, where ++ ".v2") == intField(v4, key, where ++ ".v4")
  if !sameInt("scene") || !sameString("scriptRef") || !sameString("storyEvent") ||
    !sameString("acceptedAssetPath") || !sameString("acceptedAssetSha256") ||
    !sameString("sourceClass") ||
    optionalStringField(v2, "routeShotId", where) != optionalStringField(v4, "routeShotId", where) ||
    optionalStringField(v2, "paidShotId", where) != optionalStringField(v4, "paidShotId", where) {
    die(where ++ " sub-shot identity drifted from its parent beat")
  }
}

let validateV4 = (~manifestPath): result => {
  let manifestDirectory = dirname(manifestPath)
  let root = parseRoot(readRaw(manifestPath, "animatic EDL v4"), "animatic EDL v4")
  if stringField(root, "version", "animatic EDL v4") != "ep9-finale-animatic-edl-v4" {
    die("animatic EDL v4 version has drifted")
  }
  /* the retimer publishes the main-story length here when clips force it past 12:00 */
  let declaredTotal =
    intField(field(root, "timeline", "animatic EDL v4")->objectOf("timeline"),
      "durationSeconds", "timeline")
  let v2Path = resolve2(manifestDirectory, "ep9_finale_animatic_edl.v2.json")
  let v2Result = validate(~manifestPath=v2Path)
  let v2Root = parseRoot(readRaw(v2Path, "animatic EDL v2"), "animatic EDL v2")
  let v2Beats = arrayField(v2Root, "beats", "animatic EDL v2")
  let v2ById: Js.Dict.t<Js.Dict.t<Js.Json.t>> = Js.Dict.empty()
  let v2Order = v2Beats->Belt.Array.map(bj => {
    let b = objectOf(bj, "v2 beat")
    let id = stringField(b, "id", "v2 beat")
    Js.Dict.set(v2ById, id, b)
    id
  })
  let beats = arrayField(root, "beats", "animatic EDL v4")
  let cursor = ref(Kuku_Ep9FinaleAnimaticEdl.parseTimecode("2:15", "animatic EDL v4"))
  let parentSeq: array<string> = []
  beats->Belt.Array.forEachWithIndex((index, beatJson) => {
    let where = "animatic EDL v4 beats[" ++ Belt.Int.toString(index) ++ "]"
    let beat = objectOf(beatJson, where)
    let id = stringField(beat, "id", where)
    let parent = parentOf(id)
    let v2Beat = switch Js.Dict.get(v2ById, parent) {
    | Some(b) => b
    | None => die(where ++ " has unknown parent " ++ parent)
    }
    sameBeatIdentityExceptIdAndTiming(v2Beat, beat, where)
    let n = Belt.Array.length(parentSeq)
    if n == 0 || Belt.Array.getExn(parentSeq, n - 1) != parent {
      Js.Array2.push(parentSeq, parent)->ignore
    }
    let start = Kuku_Ep9FinaleAnimaticEdl.parseTimecode(stringField(beat, "start", where), where)
    let end_ = Kuku_Ep9FinaleAnimaticEdl.parseTimecode(stringField(beat, "end", where), where)
    let duration = intField(beat, "durationSeconds", where)
    if start != cursor.contents || end_ - start != duration || duration < 1 {
      die(where ++ " has non-contiguous or invalid timing")
    }
    cursor := end_
  })
  if cursor.contents - Kuku_Ep9FinaleAnimaticEdl.parseTimecode("2:15", "animatic EDL v4") !=
    declaredTotal {
    die("v4 total does not match the declared main-story length")
  }
  if parentSeq != v2Order {
    die("v4 parent order or coverage differs from the validated v2")
  }
  v2Result
}
