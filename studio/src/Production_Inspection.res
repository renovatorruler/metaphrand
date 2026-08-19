module B = Cinema_Backends

exception InspectionError(string)

type verdict = Pass | Fail | Unknown
type check = {id: string, description: string}
type result = {checkId: string, verdict: verdict, confidence: float, evidence: string}
type job = {
  schema: string,
  workOrderHash: string,
  artifactHash: string,
  policyHash: string,
  checks: array<check>,
}
type report = {
  schema: string,
  workOrderHash: string,
  artifactHash: string,
  policyHash: string,
  inspectorId: string,
  results: array<result>,
}
type outcome = Quarantine | HumanRequired | ReviewReady
type adjudication = {
  outcome: outcome,
  reportHash: string,
  failures: array<result>,
  unknowns: array<result>,
}

let die = message => raise(InspectionError(message))

let verdictName = verdict =>
  switch verdict {
  | Pass => "PASS"
  | Fail => "FAIL"
  | Unknown => "UNKNOWN"
  }

let verdictOf = value =>
  switch value {
  | "PASS" => Pass
  | "FAIL" => Fail
  | "UNKNOWN" => Unknown
  | other => die("unknown inspection verdict '" ++ other ++ "'")
  }

let outcomeName = outcome =>
  switch outcome {
  | Quarantine => "quarantine"
  | HumanRequired => "human_required"
  | ReviewReady => "review_ready"
  }

let obj = (json, where) =>
  switch Js.Json.decodeObject(json) {
  | Some(value) => value
  | None => die(where ++ " must be an object")
  }

let get = (object, key) => Js.Dict.get(object, key)

let reqString = (object, key, where) =>
  switch get(object, key)->Belt.Option.flatMap(Js.Json.decodeString) {
  | Some(value) if Js.String2.trim(value) != "" => value
  | _ => die(where ++ "." ++ key ++ " must be a nonempty string")
  }

let reqNumber = (object, key, where) =>
  switch get(object, key)->Belt.Option.flatMap(Js.Json.decodeNumber) {
  | Some(value) if value >= 0.0 && value <= 1.0 => value
  | _ => die(where ++ "." ++ key ++ " must be a number from 0 through 1")
  }

let reqArray = (object, key, where) =>
  switch get(object, key)->Belt.Option.flatMap(Js.Json.decodeArray) {
  | Some(value) => value
  | None => die(where ++ "." ++ key ++ " must be an array")
  }

let checkToJson = check => {
  let row = Js.Dict.empty()
  Js.Dict.set(row, "id", Js.Json.string(check.id))
  Js.Dict.set(row, "description", Js.Json.string(check.description))
  Js.Json.object_(row)
}

let resultToJson = result => {
  let row = Js.Dict.empty()
  Js.Dict.set(row, "checkId", Js.Json.string(result.checkId))
  Js.Dict.set(row, "verdict", Js.Json.string(verdictName(result.verdict)))
  Js.Dict.set(row, "confidence", Js.Json.number(result.confidence))
  Js.Dict.set(row, "evidence", Js.Json.string(result.evidence))
  Js.Json.object_(row)
}

let encodeJob = (job: job) => {
  let root = Js.Dict.empty()
  Js.Dict.set(root, "schema", Js.Json.string(job.schema))
  Js.Dict.set(root, "workOrderHash", Js.Json.string(job.workOrderHash))
  Js.Dict.set(root, "artifactHash", Js.Json.string(job.artifactHash))
  Js.Dict.set(root, "policyHash", Js.Json.string(job.policyHash))
  Js.Dict.set(root, "checks", Js.Json.array(job.checks->Belt.Array.map(checkToJson)))
  Js.Json.stringifyWithSpace(Js.Json.object_(root), 2) ++ "\n"
}

let encodeReport = (report: report) => {
  let root = Js.Dict.empty()
  Js.Dict.set(root, "schema", Js.Json.string(report.schema))
  Js.Dict.set(root, "workOrderHash", Js.Json.string(report.workOrderHash))
  Js.Dict.set(root, "artifactHash", Js.Json.string(report.artifactHash))
  Js.Dict.set(root, "policyHash", Js.Json.string(report.policyHash))
  Js.Dict.set(root, "inspectorId", Js.Json.string(report.inspectorId))
  Js.Dict.set(root, "results", Js.Json.array(report.results->Belt.Array.map(resultToJson)))
  Js.Json.stringifyWithSpace(Js.Json.object_(root), 2) ++ "\n"
}

let parse = (raw, where) =>
  try Js.Json.parseExn(raw) catch {
  | _ => die(where ++ " must be valid JSON")
  }

let decodeChecks = (rows, where) =>
  rows->Belt.Array.mapWithIndex((index, json) => {
    let item = where ++ "[" ++ Belt.Int.toString(index) ++ "]"
    let row = obj(json, item)
    {id: reqString(row, "id", item), description: reqString(row, "description", item)}
  })

let decodeResults = (rows, where) =>
  rows->Belt.Array.mapWithIndex((index, json) => {
    let item = where ++ "[" ++ Belt.Int.toString(index) ++ "]"
    let row = obj(json, item)
    {
      checkId: reqString(row, "checkId", item),
      verdict: verdictOf(reqString(row, "verdict", item)),
      confidence: reqNumber(row, "confidence", item),
      evidence: reqString(row, "evidence", item),
    }
  })

let decodeJob = raw => {
  let root = obj(parse(raw, "inspection job"), "inspection job")
  let schema = reqString(root, "schema", "inspection job")
  if schema != "production.inspection-job/v1" {
    die("unsupported inspection job schema '" ++ schema ++ "'")
  }
  {
    schema,
    workOrderHash: reqString(root, "workOrderHash", "inspection job"),
    artifactHash: reqString(root, "artifactHash", "inspection job"),
    policyHash: reqString(root, "policyHash", "inspection job"),
    checks: decodeChecks(reqArray(root, "checks", "inspection job"), "inspection job.checks"),
  }
}

let decodeReport = raw => {
  let root = obj(parse(raw, "inspection report"), "inspection report")
  let schema = reqString(root, "schema", "inspection report")
  if schema != "production.inspection-report/v1" {
    die("unsupported inspection report schema '" ++ schema ++ "'")
  }
  {
    schema,
    workOrderHash: reqString(root, "workOrderHash", "inspection report"),
    artifactHash: reqString(root, "artifactHash", "inspection report"),
    policyHash: reqString(root, "policyHash", "inspection report"),
    inspectorId: reqString(root, "inspectorId", "inspection report"),
    results: decodeResults(
      reqArray(root, "results", "inspection report"),
      "inspection report.results",
    ),
  }
}

let policyHash = (checks: array<check>) => {
  let sorted = Js.Array2.copy(checks)
  sorted->Js.Array2.sortInPlaceWith((left, right) => compare(left.id, right.id))->ignore
  B.sha256Text(
    sorted
    ->Belt.Array.map(check => check.id ++ "\u{1f}" ++ check.description)
    ->Js.Array2.joinWith("\n"),
  )
}

let adjudicate = (~job: job, ~report: report) => {
  if report.workOrderHash != job.workOrderHash {
    die("inspection report workOrderHash does not match its job")
  }
  if report.artifactHash != job.artifactHash {
    die("inspection report artifactHash does not match its job")
  }
  if report.policyHash != job.policyHash || job.policyHash != policyHash(job.checks) {
    die("inspection report policyHash does not match the required checks")
  }
  let expected = Js.Dict.empty()
  job.checks->Belt.Array.forEach(check => {
    if Js.Dict.get(expected, check.id) != None {
      die("inspection job has duplicate check '" ++ check.id ++ "'")
    }
    Js.Dict.set(expected, check.id, false)
  })
  report.results->Belt.Array.forEach(result => {
    switch Js.Dict.get(expected, result.checkId) {
    | None => die("inspection report contains unknown check '" ++ result.checkId ++ "'")
    | Some(true) => die("inspection report duplicates check '" ++ result.checkId ++ "'")
    | Some(false) => Js.Dict.set(expected, result.checkId, true)
    }
  })
  Js.Dict.entries(expected)->Belt.Array.forEach(((id, covered)) =>
    if !covered {
      die("inspection report is missing required check '" ++ id ++ "'")
    }
  )
  let failures = report.results->Belt.Array.keep(result => result.verdict == Fail)
  let unknowns = report.results->Belt.Array.keep(result => result.verdict == Unknown)
  let outcome = Belt.Array.length(failures) > 0
    ? Quarantine
    : Belt.Array.length(unknowns) > 0
    ? HumanRequired
    : ReviewReady
  {outcome, reportHash: B.sha256Text(encodeReport(report)), failures, unknowns}
}
