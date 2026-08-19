/*
 * Read-only, zero-spend validator for the authoritative Episode 9 route.
 *
 * The v1 paid-shot manifest remains the acquisition and lifecycle ledger. The
 * v2 route is deliberately separate: it decides paid versus local/reuse work
 * without copying or replacing accepted-job state.
 */

module B = Cinema_Backends

@module("node:path") external dirname: string => string = "dirname"
@module("node:path") external resolve2: (string, string) => string = "resolve"

exception RouteError(string)

let die = message => raise(RouteError(message))

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
  | Some(value) if value != "" => value
  | Some(_) => die(where ++ "." ++ key ++ " must not be empty")
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

let parseRoot = (raw, where) =>
  try raw->Js.Json.parseExn->objectOf(where) catch {
  | Js.Exn.Error(error) =>
    die(
      where ++ " is not valid JSON: " ++
      Js.Exn.message(error)->Belt.Option.getWithDefault("unknown parse error"),
    )
  }

type modelRule = {duration: float, quoteGate: float}

let modelRules: Js.Dict.t<modelRule> = {
  let rules = Js.Dict.empty()
  Js.Dict.set(rules, "minimax_hailuo", {duration: 10.0, quoteGate: 7.0})
  Js.Dict.set(rules, "veo3_1_lite", {duration: 8.0, quoteGate: 8.0})
  Js.Dict.set(rules, "kling2_6", {duration: 10.0, quoteGate: 10.0})
  Js.Dict.set(rules, "gemini_omni", {duration: 8.0, quoteGate: 24.0})
  Js.Dict.set(rules, "cinematic_studio_video_4_0", {duration: 8.0, quoteGate: 52.0})
  rules
}

let lifecycleFields = [
  "status",
  "acceptedJobId",
  "acceptedAttempt",
  "failedAttempts",
  "output",
  "outputSha256",
  "promptSha256",
  "startFrameSha256",
]

let routeModelAllowed = (id, model) =>
  if Js.String2.startsWith(id, "B") {
    model == "minimax_hailuo" || model == "veo3_1_lite" || model == "kling2_6"
  } else if Js.String2.startsWith(id, "C") {
    model == "kling2_6"
  } else if Js.String2.startsWith(id, "D") {
    model == "kling2_6" || model == "gemini_omni"
  } else if Js.String2.startsWith(id, "H") {
    model == "cinematic_studio_video_4_0"
  } else {
    false
  }

let expectedRetryPolicy = (id, model) =>
  if id == "B07" || id == "B10" || id == "C04" {
    "no_further_submission_locked_asset"
  } else if model == "gemini_omni" {
    "no_direct_retry_local_fallback"
  } else if model == "cinematic_studio_video_4_0" {
    "one_shared_cinema_retry_total"
  } else {
    "one_retry_max"
  }

type result = {
  routeCount: int,
  paidCount: int,
  localOrReuseCount: int,
  paidAcquisitionSeconds: float,
  paidFinalUsageSeconds: float,
  localOrReuseSeconds: float,
  totalMotionSeconds: float,
  paidFirstTakeCredits: float,
  expectedTotalCredits: float,
  revisedMaximumCredits: float,
}

let expectDeclaredNumber = (totals, key, expected) => {
  let actual = numberField(totals, key, "route.totals")
  if !close(actual, expected) {
    die("route.totals." ++ key ++ " must be " ++ Js.Float.toString(expected))
  }
}

let validateBudgetClasses = root => {
  let expected = [
    ("A_STILLS", 65.0, 102.0),
    ("B_WIDE_ENVIRONMENT", 104.0, 178.0),
    ("C_SIMPLE_CHARACTER", 110.0, 210.0),
    ("D_COMPLEX_GROUP", 68.0, 88.0),
    ("E_CINEMA_HERO", 104.0, 156.0),
    ("F_AUDIO", 35.0, 35.0),
  ]
  let seen = Js.Dict.empty()
  let expectedSum = ref(0.0)
  let maximumSum = ref(0.0)
  arrayField(root, "budgetClasses", "route")->Belt.Array.forEachWithIndex((index, itemJson) => {
    let where = "route.budgetClasses[" ++ Belt.Int.toString(index) ++ "]"
    let item = objectOf(itemJson, where)
    let id = stringField(item, "id", where)
    if Js.Dict.get(seen, id) != None {
      die("duplicate budget class: " ++ id)
    }
    Js.Dict.set(seen, id, true)
    expectedSum := expectedSum.contents +. numberField(item, "expectedTotalCredits", where)
    maximumSum := maximumSum.contents +. numberField(item, "revisedMaximumCredits", where)
  })
  if Js.Dict.keys(seen)->Belt.Array.length != 6 {
    die("route must contain exactly six budget classes")
  }
  expected->Belt.Array.forEach(((id, expectedCredits, maximumCredits)) => {
    let match_ = arrayField(root, "budgetClasses", "route")->Belt.Array.keepMap(itemJson => {
      let item = objectOf(itemJson, "route.budgetClasses")
      if stringField(item, "id", "route.budgetClasses") == id {
        Some(item)
      } else {
        None
      }
    })
    if Belt.Array.length(match_) != 1 {
      die("missing budget class " ++ id)
    }
    let item = match_[0]
    if !close(numberField(item, "expectedTotalCredits", "budget class " ++ id), expectedCredits) ||
      !close(numberField(item, "revisedMaximumCredits", "budget class " ++ id), maximumCredits) {
      die("budget class " ++ id ++ " has drifted")
    }
  })
  if !close(expectedSum.contents, 486.0) || !close(maximumSum.contents, 769.0) {
    die("budget-class totals must remain 486 expected and 769 maximum")
  }
}

let validateStopRules = root => {
  let expected = [
    ("attempt_limit", 0.0),
    ("first_pass_assembly", 500.0),
    ("critical_only", 650.0),
    ("accepted_yield_audit", 750.0),
    ("revised_route_stop", 769.0),
    ("operating_stop", 899.0),
    ("premium_disable", 1000.0),
    ("absolute_stop", 1100.0),
  ]
  let rules = arrayField(root, "stopRules", "route")
  if Belt.Array.length(rules) != Belt.Array.length(expected) {
    die("route must contain the eight approved stop rules")
  }
  expected->Belt.Array.forEachWithIndex((index, (expectedId, expectedThreshold)) => {
    let where = "route.stopRules[" ++ Belt.Int.toString(index) ++ "]"
    let rule = objectOf(rules[index], where)
    if stringField(rule, "id", where) != expectedId ||
      !close(numberField(rule, "atActualCredits", where), expectedThreshold) {
      die("stop-rule order or threshold has drifted at " ++ expectedId)
    }
    stringField(rule, "action", where)->ignore
  })
}

let validateSubmissionHold = root => {
  let hold = field(root, "submissionHold", "route")->objectOf("route.submissionHold")
  stringField(hold, "id", "route.submissionHold")->ignore
  boolField(hold, "active", "route.submissionHold")->ignore
  if stringField(hold, "scope", "route.submissionHold") != "all_paid_submissions" {
    die("route.submissionHold.scope must remain all_paid_submissions")
  }
  stringField(hold, "reason", "route.submissionHold")->ignore
  stringField(hold, "releaseCondition", "route.submissionHold")->ignore
  stringField(hold, "releaseAuthority", "route.submissionHold")->ignore
}

let validateRaw = (~routeRaw, ~sourceRaw): result => {
  let root = parseRoot(routeRaw, "route")
  let sourceRoot = parseRoot(sourceRaw, "source acquisition manifest")
  if stringField(root, "version", "route") != "2.0" ||
    stringField(root, "status", "route") != "authoritative_production_route" {
    die("route version and authority status must remain locked")
  }
  validateSubmissionHold(root)

  let authority = field(root, "authority", "route")->objectOf("route.authority")
  if stringField(authority, "sourceAcquisitionManifest", "route.authority") !=
      "ep9_finale_paid_shots.v1.json" ||
    !boolField(authority, "routingComesFromThisFile", "route.authority") ||
    !boolField(authority, "acquisitionLifecycleComesFromSourceManifest", "route.authority") ||
    boolField(authority, "copyLifecycleFieldsIntoThisFile", "route.authority") ||
    !boolField(authority, "preserveSourceManifest", "route.authority") {
    die("route authority must preserve the v1 acquisition and lifecycle manifest")
  }

  let policy = field(root, "policy", "route")->objectOf("route.policy")
  if !boolField(policy, "noSeedance", "route.policy") {
    die("no-Seedance policy must remain enabled")
  }
  if boolField(policy, "nativeAudioOnVideo", "route.policy") {
    die("native audio on video must remain disabled")
  }
  if numberField(policy, "maximumAttemptsPerTarget", "route.policy") != 2.0 ||
    boolField(policy, "thirdAttemptAllowed", "route.policy") {
    die("the two-attempt limit and no-third-attempt rule must remain locked")
  }
  if !boolField(policy, "quoteExactPayloadBeforeSubmission", "route.policy") {
    die("every paid submission must be repriced")
  }

  let sourceIds = Js.Dict.empty()
  let sourceStatuses: Js.Dict.t<string> = Js.Dict.empty()
  arrayField(sourceRoot, "shots", "source acquisition manifest")
  ->Belt.Array.forEachWithIndex((index, shotJson) => {
    let where = "source acquisition manifest.shots[" ++ Belt.Int.toString(index) ++ "]"
    let shot = objectOf(shotJson, where)
    let id = stringField(shot, "id", where)
    if !Js.Re.test_(%re("/^[BCDH][0-9]{2}$/"), id) {
      die("source acquisition manifest contains an out-of-scope id: " ++ id)
    }
    if Js.Dict.get(sourceIds, id) != None {
      die("source acquisition manifest contains duplicate id " ++ id)
    }
    Js.Dict.set(sourceIds, id, true)
    Js.Dict.set(sourceStatuses, id, stringField(shot, "status", where))
  })
  if Js.Dict.keys(sourceIds)->Belt.Array.length != 45 {
    die("source acquisition manifest must contain exactly 45 B/C/D/H ids")
  }

  let routeIds = Js.Dict.empty()
  let paidCount = ref(0)
  let localOrReuseCount = ref(0)
  let acquisitionSeconds = ref(0.0)
  let paidFinalSeconds = ref(0.0)
  let localFinalSeconds = ref(0.0)
  let firstTakeCredits = ref(0.0)

  arrayField(root, "routes", "route")->Belt.Array.forEachWithIndex((index, routeJson) => {
    let where = "route.routes[" ++ Belt.Int.toString(index) ++ "]"
    let item = objectOf(routeJson, where)
    let id = stringField(item, "id", where)
    if Js.Dict.get(routeIds, id) != None {
      die("duplicate route id: " ++ id)
    }
    if Js.Dict.get(sourceIds, id) == None {
      die("route id does not exist in the source acquisition manifest: " ++ id)
    }
    Js.Dict.set(routeIds, id, true)
    lifecycleFields->Belt.Array.forEach(key =>
      if Js.Dict.get(item, key) != None {
        die(id ++ " must not copy lifecycle field " ++ key ++ " from the source manifest")
      }
    )

    let routeKind = stringField(item, "routeKind", where)
    let finalUse = numberField(item, "finalUseSeconds", where)
    if finalUse <= 0.0 {
      die(id ++ " final-use duration must be positive")
    }
    if routeKind == "paid" {
      let model = stringField(item, "model", where)
      if Js.String2.includes(Js.String2.toLowerCase(model), "seedance") {
        die(id ++ " violates the no-Seedance route")
      }
      let rule = switch Js.Dict.get(modelRules, model) {
      | Some(rule) => rule
      | None => die(id ++ " uses an unapproved paid model: " ++ model)
      }
      if !routeModelAllowed(id, model) {
        die(id ++ " uses " ++ model ++ " outside its approved routing role")
      }
      let duration = numberField(item, "durationSeconds", where)
      let quoteGate = numberField(item, "quoteGate", where)
      if !close(duration, rule.duration) || !close(quoteGate, rule.quoteGate) {
        die(id ++ " duration or quote gate has drifted from its model rule")
      }
      let retryPolicy = stringField(item, "retryPolicy", where)
      if retryPolicy != expectedRetryPolicy(id, model) {
        die(id ++ " retry policy has drifted")
      }
      paidCount := paidCount.contents + 1
      acquisitionSeconds := acquisitionSeconds.contents +. duration
      paidFinalSeconds := paidFinalSeconds.contents +. finalUse
      firstTakeCredits := firstTakeCredits.contents +. quoteGate
    } else if routeKind == "local" || routeKind == "reuse" {
      stringField(item, "localMethod", where)->ignore
      if Js.Dict.get(item, "model") != None || Js.Dict.get(item, "durationSeconds") != None ||
        Js.Dict.get(item, "quoteGate") != None {
        die(id ++ " local/reuse route must not carry paid-model fields")
      }
      localOrReuseCount := localOrReuseCount.contents + 1
      localFinalSeconds := localFinalSeconds.contents +. finalUse
    } else {
      die(id ++ " routeKind must be paid, local, or reuse")
    }
  })

  if Js.Dict.keys(routeIds)->Belt.Array.length != 45 {
    die("route must cover exactly 45 source ids")
  }
  Js.Dict.keys(sourceIds)->Belt.Array.forEach(id =>
    if Js.Dict.get(routeIds, id) == None {
      die("source acquisition id is missing from route: " ++ id)
    }
  )

  let expectSourceStatus = (id, expected) =>
    if Js.Dict.get(sourceStatuses, id) != Some(expected) {
      die(id ++ " lifecycle must remain " ++ expected ++ " in the source acquisition manifest")
    }
  expectSourceStatus("B07", "pilot_accepted")
  expectSourceStatus("B10", "pilot_accepted")
  expectSourceStatus("C04", "pilot_accepted")
  expectSourceStatus("C03", "pilot_local_fallback")

  let totalMotion = paidFinalSeconds.contents +. localFinalSeconds.contents
  if paidCount.contents != 28 || localOrReuseCount.contents != 17 ||
    !close(acquisitionSeconds.contents, 266.0) || !close(paidFinalSeconds.contents, 242.0) ||
    !close(localFinalSeconds.contents, 128.0) || !close(totalMotion, 370.0) ||
    !close(firstTakeCredits.contents, 371.0) {
    die("computed route totals must remain 28 paid, 17 local/reuse, 266s acquired, 242s paid final, 128s converted, 370s motion, and 371 first-take credits")
  }

  let totals = field(root, "totals", "route")->objectOf("route.totals")
  expectDeclaredNumber(totals, "existingShotCount", 45.0)
  expectDeclaredNumber(totals, "paidRouteCount", 28.0)
  expectDeclaredNumber(totals, "localOrReuseRouteCount", 17.0)
  expectDeclaredNumber(totals, "paidAcquisitionSeconds", 266.0)
  expectDeclaredNumber(totals, "paidFinalUsageSeconds", 242.0)
  expectDeclaredNumber(totals, "localOrReuseConversionSeconds", 128.0)
  expectDeclaredNumber(totals, "totalMotionCoverageSeconds", 370.0)
  expectDeclaredNumber(totals, "paidRouteFirstTakeCredits", 371.0)
  expectDeclaredNumber(totals, "currentActualCreditsAtCalibration", 80.0)
  expectDeclaredNumber(totals, "remainingPaidVideoFirstTakeCredits", 346.0)
  expectDeclaredNumber(totals, "expectedAdditionalStillCredits", 25.0)
  expectDeclaredNumber(totals, "expectedAudioCredits", 35.0)
  expectDeclaredNumber(totals, "expectedTotalCredits", 486.0)
  expectDeclaredNumber(totals, "revisedMaximumCredits", 769.0)
  expectDeclaredNumber(totals, "operatingCeiling", 899.0)
  expectDeclaredNumber(totals, "lockedEmergencyReserve", 201.0)
  expectDeclaredNumber(totals, "absoluteCap", 1100.0)
  if !close(
      numberField(totals, "currentActualCreditsAtCalibration", "route.totals") +.
      numberField(totals, "remainingPaidVideoFirstTakeCredits", "route.totals") +.
      numberField(totals, "expectedAdditionalStillCredits", "route.totals") +.
      numberField(totals, "expectedAudioCredits", "route.totals"),
      486.0,
    ) {
    die("expected-total components no longer add to 486 credits")
  }
  validateBudgetClasses(root)
  validateStopRules(root)

  {
    routeCount: Js.Dict.keys(routeIds)->Belt.Array.length,
    paidCount: paidCount.contents,
    localOrReuseCount: localOrReuseCount.contents,
    paidAcquisitionSeconds: acquisitionSeconds.contents,
    paidFinalUsageSeconds: paidFinalSeconds.contents,
    localOrReuseSeconds: localFinalSeconds.contents,
    totalMotionSeconds: totalMotion,
    paidFirstTakeCredits: firstTakeCredits.contents,
    expectedTotalCredits: numberField(totals, "expectedTotalCredits", "route.totals"),
    revisedMaximumCredits: numberField(totals, "revisedMaximumCredits", "route.totals"),
  }
}

let validate = (~routePath): result => {
  let routeRaw = try B.readText(B.Path(routePath)) catch {
  | B.BackendError(message) => die("route cannot be read: " ++ message)
  }
  let routeRoot = parseRoot(routeRaw, "route")
  let authority = field(routeRoot, "authority", "route")->objectOf("route.authority")
  let sourceName = stringField(authority, "sourceAcquisitionManifest", "route.authority")
  let sourcePath = resolve2(dirname(routePath), sourceName)
  let sourceRaw = try B.readText(B.Path(sourcePath)) catch {
  | B.BackendError(message) => die("source acquisition manifest cannot be read: " ++ message)
  }
  validateRaw(~routeRaw, ~sourceRaw)
}

let printResult = result => {
  Js.log("KUKU EP9 FINALE ROUTE V2 — VALID")
  Js.log(
    Belt.Int.toString(result.routeCount) ++ " source IDs | " ++
    Belt.Int.toString(result.paidCount) ++ " paid | " ++
    Belt.Int.toString(result.localOrReuseCount) ++ " local/reuse",
  )
  Js.log(
    Js.Float.toString(result.paidAcquisitionSeconds) ++ "s paid acquisition | " ++
    Js.Float.toString(result.paidFinalUsageSeconds) ++ "s paid final | " ++
    Js.Float.toString(result.localOrReuseSeconds) ++ "s converted | " ++
    Js.Float.toString(result.totalMotionSeconds) ++ "s total motion",
  )
  Js.log(
    Js.Float.toString(result.expectedTotalCredits) ++ " expected credits | " ++
    Js.Float.toString(result.revisedMaximumCredits) ++ " revised maximum credits",
  )
}
