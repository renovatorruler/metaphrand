/* Deterministic, zero-spend validator for the paid Episode 9 shot ledger. */

module B = Cinema_Backends

@module("node:path") external dirname: string => string = "dirname"
@module("node:path") external resolve2: (string, string) => string = "resolve"

exception ShotPlanError(string)

let die = message => raise(ShotPlanError(message))

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

let stringField = (object_, key, where) =>
  switch field(object_, key, where)->Js.Json.decodeString {
  | Some(value) => value
  | None => die(where ++ "." ++ key ++ " must be a string")
  }

let numberField = (object_, key, where) =>
  switch field(object_, key, where)->Js.Json.decodeNumber {
  | Some(value) => value
  | None => die(where ++ "." ++ key ++ " must be a number")
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

let close = (left, right) => Js.Math.abs_float(left -. right) < 0.0001

type modelRule = {classId: string, duration: float, quoteGate: float}

let modelRules: Js.Dict.t<modelRule> = {
  let rules = Js.Dict.empty()
  Js.Dict.set(rules, "minimax_hailuo", {classId: "B_WIDE_ENVIRONMENT", duration: 10.0, quoteGate: 7.0})
  Js.Dict.set(rules, "veo3_1_lite", {classId: "B_WIDE_ENVIRONMENT", duration: 8.0, quoteGate: 8.0})
  Js.Dict.set(rules, "seedance1_5", {classId: "C_SIMPLE_CHARACTER", duration: 8.0, quoteGate: 9.6})
  Js.Dict.set(rules, "kling2_6", {classId: "C_SIMPLE_CHARACTER", duration: 10.0, quoteGate: 10.0})
  Js.Dict.set(rules, "seedance_2_0_mini", {classId: "D_COMPLEX_GROUP", duration: 8.0, quoteGate: 20.0})
  Js.Dict.set(rules, "gemini_omni", {classId: "D_COMPLEX_GROUP", duration: 8.0, quoteGate: 24.0})
  Js.Dict.set(rules, "cinematic_studio_video_4_0", {classId: "E_CINEMA_HERO", duration: 8.0, quoteGate: 52.0})
  rules
}

type classTotal = {count: int, seconds: float, credits: float}
type result = {count: int, seconds: float, credits: float, missingInputs: array<string>}

let validate = (~manifestPath): result => {
  let manifestDirectory = dirname(manifestPath)
  let root = try B.readText(B.Path(manifestPath))->Js.Json.parseExn->objectOf("shot manifest") catch {
  | B.BackendError(message) => die("shot manifest cannot be read: " ++ message)
  | Js.Exn.Error(error) =>
    die(
      "shot manifest is not valid JSON: " ++
      Js.Exn.message(error)->Belt.Option.getWithDefault("unknown parse error"),
    )
  }
  let policy = field(root, "policy", "shot manifest")->objectOf("shot manifest.policy")
  if boolField(policy, "nativeAudioOnVideo", "shot manifest.policy") {
    die("native video audio must be disabled")
  }
  if numberField(policy, "maximumAttemptsPerShot", "shot manifest.policy") != 2.0 {
    die("maximumAttemptsPerShot must be two")
  }
  if boolField(policy, "thirdAttemptAllowed", "shot manifest.policy") {
    die("third attempts are forbidden")
  }

  let ids = Js.Dict.empty()
  let outputs = Js.Dict.empty()
  let classes: Js.Dict.t<classTotal> = Js.Dict.empty()
  let missingInputs: array<string> = []
  let count = ref(0)
  let seconds = ref(0.0)
  let credits = ref(0.0)

  arrayField(root, "shots", "shot manifest")->Belt.Array.forEachWithIndex((index, shotJson) => {
    let where = "shot manifest.shots[" ++ Belt.Int.toString(index) ++ "]"
    let shot = objectOf(shotJson, where)
    let id = stringField(shot, "id", where)
    let classId = stringField(shot, "classId", where)
    let model = stringField(shot, "model", where)
    let duration = numberField(shot, "durationSeconds", where)
    let quoteGate = numberField(shot, "quoteGate", where)
    let prompt = stringField(shot, "promptFile", where)
    let startFrame = stringField(shot, "startFrame", where)
    let output = stringField(shot, "output", where)

    if Js.Dict.get(ids, id) != None {
      die("duplicate shot id: " ++ id)
    }
    Js.Dict.set(ids, id, true)
    if Js.Dict.get(outputs, output) != None {
      die("duplicate output path: " ++ output)
    }
    Js.Dict.set(outputs, output, true)

    let rule = switch Js.Dict.get(modelRules, model) {
    | Some(rule) => rule
    | None => die(id ++ " uses an unapproved model: " ++ model)
    }
    if rule.classId != classId {
      die(id ++ " routes " ++ model ++ " through the wrong class")
    }
    if !close(rule.duration, duration) || !close(rule.quoteGate, quoteGate) {
      die(id ++ " duration or quote gate has drifted from the approved model rule")
    }

    if !B.exists(B.Path(resolve2(manifestDirectory, prompt))) {
      missingInputs->Js.Array2.push(id ++ ":prompt")->ignore
    }
    if !B.exists(B.Path(resolve2(manifestDirectory, startFrame))) {
      missingInputs->Js.Array2.push(id ++ ":start_frame")->ignore
    }

    let previous = Js.Dict.get(classes, classId)->Belt.Option.getWithDefault({count: 0, seconds: 0.0, credits: 0.0})
    Js.Dict.set(classes, classId, {
      count: previous.count + 1,
      seconds: previous.seconds +. duration,
      credits: previous.credits +. quoteGate,
    })
    count := count.contents + 1
    seconds := seconds.contents +. duration
    credits := credits.contents +. quoteGate
  })

  let expect = (classId, expectedCount, expectedSeconds, expectedCredits) =>
    switch Js.Dict.get(classes, classId) {
    | Some(total)
      if total.count == expectedCount && close(total.seconds, expectedSeconds) &&
        close(total.credits, expectedCredits) => ()
    | Some(total) =>
      die(
        classId ++ " totals drifted: " ++ Belt.Int.toString(total.count) ++ " shots, " ++
        Js.Float.toString(total.seconds) ++ " seconds, " ++ Js.Float.toString(total.credits) ++
        " credits",
      )
    | None => die("missing shot class " ++ classId)
    }

  expect("B_WIDE_ENVIRONMENT", 18, 164.0, 134.0)
  expect("C_SIMPLE_CHARACTER", 18, 160.0, 176.0)
  expect("D_COMPLEX_GROUP", 7, 56.0, 148.0)
  expect("E_CINEMA_HERO", 2, 16.0, 104.0)
  if count.contents != 45 || !close(seconds.contents, 396.0) || !close(credits.contents, 562.0) {
    die("global paid-shot totals must remain 45 shots, 396 seconds, and 562 first-take credits")
  }
  {count: count.contents, seconds: seconds.contents, credits: credits.contents, missingInputs}
}

let printResult = result => {
  Js.log("KUKU EP9 FINALE SHOT PLAN — VALID")
  Js.log(
    Belt.Int.toString(result.count) ++ " paid shots | " ++ Js.Float.toString(result.seconds) ++
    "s first-take motion | " ++ Js.Float.toString(result.credits) ++ " first-take credits",
  )
  if Belt.Array.length(result.missingInputs) == 0 {
    Js.log("READY: every prompt and start frame exists")
  } else {
    Js.log(
      "BLOCKED: " ++ Belt.Int.toString(Belt.Array.length(result.missingInputs)) ++
      " prompt/start-frame inputs are still missing",
    )
  }
}
