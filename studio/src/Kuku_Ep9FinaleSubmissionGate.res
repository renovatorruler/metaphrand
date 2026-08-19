/*
 * Read-only, fail-closed authorization for one Episode 9 paid-video request.
 *
 * This is deliberately not a provider client and never writes the spend
 * ledger. The caller must rerun it after any submission or source mutation.
 * Route v2 owns routing and price/duration bounds. Paid-shots v1 contributes
 * only paths, provenance, and lifecycle state.
 */

module B = Cinema_Backends

@module("node:path") external dirname: string => string = "dirname"
@module("node:path") external resolve2: (string, string) => string = "resolve"
@module("node:path") external resolvePath: string => string = "resolve"

exception SubmissionGateError(string)

let die = message => raise(SubmissionGateError(message))

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
  | Some(value) if value != "" => value
  | Some(_) => die(where ++ "." ++ key ++ " must not be empty")
  | None => die(where ++ "." ++ key ++ " must be a string")
  }

let optionalStringField = (object_, key, where) =>
  switch Js.Dict.get(object_, key) {
  | None => None
  | Some(json) =>
    switch Js.Json.decodeString(json) {
    | Some(value) if value != "" => Some(value)
    | Some(_) => die(where ++ "." ++ key ++ " must not be empty when present")
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

let close = (left, right) => Js.Math.abs_float(left -. right) < 0.0001

let parseRoot = (raw, where) =>
  try raw->Js.Json.parseExn->objectOf(where) catch {
  | Js.Exn.Error(error) =>
    die(
      where ++ " is not valid JSON: " ++
      Js.Exn.message(error)->Belt.Option.getWithDefault("unknown parse error"),
    )
  }

let readRaw = (path, where) =>
  try B.readText(B.Path(path)) catch {
  | B.BackendError(message) => die(where ++ " cannot be read: " ++ message)
  }

let sha256Pattern = %re("/^[a-f0-9]{64}$/")

let requireSha256 = (value, label) =>
  if !Js.Re.test_(sha256Pattern, value) {
    die(label ++ " must be a lowercase 64-character SHA-256")
  }

let terminalLifecycle = status => {
  let lower = Js.String2.toLowerCase(status)
  Js.String2.includes(lower, "accepted") ||
  Js.String2.includes(lower, "local_fallback") ||
  lower == "locked" || Js.String2.startsWith(lower, "locked_") ||
  Js.String2.includes(lower, "_locked_") || Js.String2.endsWith(lower, "_locked") ||
  lower == "complete" || Js.String2.startsWith(lower, "completed_")
}

type request = {
  targetId: string,
  model: string,
  variant: option<string>,
  durationSeconds: float,
  quoteCredits: float,
  promptSha256: string,
  startFrameSha256: string,
}

type inspectors = {
  exists: string => bool,
  sha256: string => string,
}

type budgetClass = {
  currentActual: float,
  remainingExpected: float,
  maximum: float,
}

type result = {
  authorizationFingerprint: string,
  targetId: string,
  attempt: int,
  model: string,
  variant: option<string>,
  durationSeconds: float,
  nativeAudioOnVideo: bool,
  quoteCredits: float,
  promptPath: string,
  startFramePath: string,
  promptSha256: string,
  startFrameSha256: string,
  routeSha256: string,
  provenanceSha256: string,
  budgetSha256: string,
  spendLedgerSha256: string,
  actualSpend: float,
  projectedSpend: float,
  remainingMandatoryFirstPassCredits: float,
  protectedProjectedCredits: float,
  revisedRouteMaximum: float,
  operatingCeiling: float,
  absoluteCap: float,
}

let findById = (~items, ~id, ~where) => {
  let matches = items->Belt.Array.keepMap(itemJson => {
    let item = objectOf(itemJson, where)
    stringField(item, "id", where) == id ? Some(item) : None
  })
  if Belt.Array.length(matches) != 1 {
    die(where ++ " must contain exactly one " ++ id)
  }
  matches[0]
}

let addFloat = (dict, key, amount) => {
  let previous = Js.Dict.get(dict, key)->Belt.Option.getWithDefault(0.0)
  Js.Dict.set(dict, key, previous +. amount)
}

let addInt = (dict, key, amount) => {
  let previous = Js.Dict.get(dict, key)->Belt.Option.getWithDefault(0)
  Js.Dict.set(dict, key, previous + amount)
}

let routeClassForId = id =>
  if Js.String2.startsWith(id, "B") {
    "B_WIDE_ENVIRONMENT"
  } else if Js.String2.startsWith(id, "C") {
    "C_SIMPLE_CHARACTER"
  } else if Js.String2.startsWith(id, "D") {
    "D_COMPLEX_GROUP"
  } else if Js.String2.startsWith(id, "H") {
    "E_CINEMA_HERO"
  } else {
    die("unknown route-id class for " ++ id)
  }

let rejectThreshold = projectedSpend => {
  if projectedSpend >= 1100.0 {
    die("absolute_stop: projected spend reaches the 1100-credit absolute stop")
  } else if projectedSpend >= 1000.0 {
    die("premium_disable: projected spend reaches 1000 credits; this route has no authority to continue")
  } else if projectedSpend >= 899.0 {
    die("operating_stop: projected spend reaches the 899-credit operating stop")
  } else if projectedSpend >= 769.0 {
    die("revised_route_stop: projected spend reaches the 769-credit route maximum; updated authority is required")
  } else if projectedSpend >= 750.0 {
    die("accepted_yield_audit: projected spend reaches 750 credits; audit and reroute before continuing")
  } else if projectedSpend >= 650.0 {
    die("critical_only: projected spend reaches 650 credits; this gate has no recorded critical-retry clearance")
  } else if projectedSpend >= 500.0 {
    die("first_pass_assembly: projected spend reaches 500 credits; assemble and review the rough cut before continuing")
  }
}

let validateBudgetStops = budget => {
  let expected = [500.0, 650.0, 750.0, 769.0, 899.0, 1000.0, 1100.0]
  let stops = arrayField(budget, "automaticStops", "budget")
  if Belt.Array.length(stops) != Belt.Array.length(expected) {
    die("budget must contain all seven automatic stops")
  }
  expected->Belt.Array.forEachWithIndex((index, threshold) => {
    let where = "budget.automaticStops[" ++ Belt.Int.toString(index) ++ "]"
    let stop = objectOf(stops[index], where)
    if !close(numberField(stop, "atActualSpend", where), threshold) {
      die(where ++ " threshold has drifted")
    }
    stringField(stop, "action", where)->ignore
  })
}

let authorizeRaw = (
  ~routeRaw,
  ~sourceRaw,
  ~budgetRaw,
  ~spendRaw,
  ~manifestDirectory,
  ~request: request,
  ~inspectors,
): result => {
  let routeValidation = try Kuku_Ep9FinaleRoute.validateRaw(~routeRaw, ~sourceRaw) catch {
  | Kuku_Ep9FinaleRoute.RouteError(message) => die("route/provenance validation failed: " ++ message)
  }
  let route = parseRoot(routeRaw, "route")
  let submissionHold = objectField(route, "submissionHold", "route")
  if boolField(submissionHold, "active", "route.submissionHold") {
    let holdId = stringField(submissionHold, "id", "route.submissionHold")
    let reason = stringField(submissionHold, "reason", "route.submissionHold")
    let releaseCondition = stringField(
      submissionHold,
      "releaseCondition",
      "route.submissionHold",
    )
    die(
      "production_hold_active [" ++ holdId ++
      "]: every Episode 9 paid submission is blocked. Reason: " ++ reason ++
      " Release condition: " ++ releaseCondition,
    )
  }
  let source = parseRoot(sourceRaw, "paid-shot provenance")
  let budget = parseRoot(budgetRaw, "budget")
  let spend = parseRoot(spendRaw, "spend ledger")

  let project = stringField(route, "project", "route")
  if project != "Kuku Episode 9 Season 1 Finale" ||
    stringField(source, "project", "paid-shot provenance") != project ||
    stringField(budget, "project", "budget") != project ||
    stringField(spend, "project", "spend ledger") != project {
    die("route, provenance, budget, and spend ledger must name the Episode 9 finale project")
  }
  if stringField(spend, "version", "spend ledger") != "1.0" ||
    stringField(spend, "activeRouteManifest", "spend ledger") !=
      "../manifests/ep9_finale_route.v2.json" ||
    stringField(spend, "budgetManifest", "spend ledger") != "ep9_finale_budget.v2.json" {
    die("the live spend ledger must bind route v2 and budget v2 as its active authorities")
  }

  if stringField(budget, "version", "budget") != "2.0" ||
    stringField(budget, "authority", "budget") != "Post-calibration hybrid route" {
    die("the explicit budget must be authoritative budget v2")
  }
  let approval = objectField(budget, "approval", "budget")
  if !boolField(approval, "approvedByUser", "budget.approval") {
    die("budget v2 is not user-approved")
  }
  let operatingCeiling = numberField(approval, "operatingCeiling", "budget.approval")
  let reserve = numberField(approval, "lockedEmergencyReserve", "budget.approval")
  let absoluteCap = numberField(approval, "absoluteCap", "budget.approval")
  let totals = objectField(budget, "totals", "budget")
  let revisedRouteMaximum = numberField(totals, "revisedRouteMaximumCredits", "budget.totals")
  if !close(operatingCeiling, 899.0) || !close(reserve, 201.0) ||
    !close(absoluteCap, 1100.0) || !close(revisedRouteMaximum, 769.0) ||
    !close(operatingCeiling +. reserve, absoluteCap) {
    die("budget v2 must preserve the 769 / 899 + 201 = 1100 authority")
  }
  if !close(routeValidation.revisedMaximumCredits, revisedRouteMaximum) ||
    !close(routeValidation.expectedTotalCredits, numberField(totals, "expectedCompletionCredits", "budget.totals")) {
    die("route v2 and budget v2 credit totals disagree")
  }
  validateBudgetStops(budget)

  let budgetClasses: Js.Dict.t<budgetClass> = Js.Dict.empty()
  arrayField(budget, "classes", "budget")->Belt.Array.forEachWithIndex((index, classJson) => {
    let where = "budget.classes[" ++ Belt.Int.toString(index) ++ "]"
    let class_ = objectOf(classJson, where)
    let id = stringField(class_, "id", where)
    if Js.Dict.get(budgetClasses, id) != None {
      die("duplicate budget class " ++ id)
    }
    Js.Dict.set(budgetClasses, id, {
      currentActual: numberField(class_, "currentActualCredits", where),
      remainingExpected: numberField(class_, "remainingExpectedCredits", where),
      maximum: numberField(class_, "maximumCredits", where),
    })
  })
  if Js.Dict.keys(budgetClasses)->Belt.Array.length != 6 {
    die("budget v2 must contain exactly six classes")
  }

  let routeItems = arrayField(route, "routes", "route")
  let sourceItems = arrayField(source, "shots", "paid-shot provenance")
  let routesById: Js.Dict.t<Js.Dict.t<Js.Json.t>> = Js.Dict.empty()
  routeItems->Belt.Array.forEach(routeJson => {
    let item = objectOf(routeJson, "route.routes")
    Js.Dict.set(routesById, stringField(item, "id", "route.routes"), item)
  })
  let routeItem = findById(~items=routeItems, ~id=request.targetId, ~where="route.routes")
  let sourceShot = findById(~items=sourceItems, ~id=request.targetId, ~where="paid-shot provenance.shots")
  if request.targetId == "C03" {
    die("C03 is permanently locked to local fallback after two refunded failures")
  }
  let routeKind = stringField(routeItem, "routeKind", "selected route")
  if routeKind != "paid" {
    die(request.targetId ++ " is routed as " ++ routeKind ++ "; no paid submission is permitted")
  }
  let retryPolicy = stringField(routeItem, "retryPolicy", "selected route")
  if retryPolicy == "no_further_submission_locked_asset" {
    die(request.targetId ++ " is an accepted locked asset; no further submission is permitted")
  }
  let sourceStatus = stringField(sourceShot, "status", "selected provenance shot")
  if stringField(sourceShot, "classId", "selected provenance shot") != routeClassForId(request.targetId) {
    die(request.targetId ++ " provenance class does not match its stable route ID")
  }
  if terminalLifecycle(sourceStatus) || Js.Dict.get(sourceShot, "acceptedJobId") != None ||
    Js.Dict.get(sourceShot, "acceptedAttempt") != None || Js.Dict.get(sourceShot, "outputSha256") != None {
    die(request.targetId ++ " is already accepted, complete, or lifecycle-locked")
  }

  if Js.String2.includes(Js.String2.toLowerCase(request.model), "seedance") {
    die("Seedance is forbidden for every remaining Episode 9 submission")
  }
  let routeModel = stringField(routeItem, "model", "selected route")
  let routeDuration = numberField(routeItem, "durationSeconds", "selected route")
  let routeQuote = numberField(routeItem, "quoteGate", "selected route")
  let routeVariant = optionalStringField(routeItem, "variant", "selected route")
  if request.model != routeModel {
    die(request.targetId ++ " requested model does not match route v2")
  }
  if request.variant != routeVariant {
    die(request.targetId ++ " requested variant does not match route v2")
  }
  if !close(request.durationSeconds, routeDuration) {
    die(request.targetId ++ " requested duration does not match route v2")
  }
  if request.quoteCredits <= 0.0 || !close(request.quoteCredits, routeQuote) {
    die(request.targetId ++ " exact quote does not match the route-v2 quote gate")
  }

  requireSha256(request.promptSha256, "requested prompt hash")
  requireSha256(request.startFrameSha256, "requested start-frame hash")
  let promptPath = resolve2(manifestDirectory, stringField(sourceShot, "promptFile", "selected provenance shot"))
  let startFramePath = resolve2(manifestDirectory, stringField(sourceShot, "startFrame", "selected provenance shot"))
  if !inspectors.exists(promptPath) {
    die(request.targetId ++ " prompt file does not exist")
  }
  if !inspectors.exists(startFramePath) {
    die(request.targetId ++ " start frame does not exist")
  }
  if inspectors.sha256(promptPath) != request.promptSha256 {
    die(request.targetId ++ " prompt hash does not match the exact file")
  }
  if inspectors.sha256(startFramePath) != request.startFrameSha256 {
    die(request.targetId ++ " start-frame hash does not match the exact file")
  }
  switch optionalStringField(sourceShot, "promptSha256", "selected provenance shot") {
  | Some(declared) if declared != request.promptSha256 =>
    die(request.targetId ++ " prompt hash disagrees with lifecycle provenance")
  | _ => ()
  }
  switch optionalStringField(sourceShot, "startFrameSha256", "selected provenance shot") {
  | Some(declared) if declared != request.startFrameSha256 =>
    die(request.targetId ++ " start-frame hash disagrees with lifecycle provenance")
  | _ => ()
  }

  let eventCounts: Js.Dict.t<int> = Js.Dict.empty()
  let maximumAttempts: Js.Dict.t<int> = Js.Dict.empty()
  let historyCounts: Js.Dict.t<int> = Js.Dict.empty()
  let historyMaximumAttempts: Js.Dict.t<int> = Js.Dict.empty()
  let seenAttempts: Js.Dict.t<bool> = Js.Dict.empty()
  let acceptedTargets: Js.Dict.t<bool> = Js.Dict.empty()
  let classActuals: Js.Dict.t<float> = Js.Dict.empty()
  let actualSpend = ref(0.0)
  arrayField(spend, "events", "spend ledger")->Belt.Array.forEachWithIndex((index, eventJson) => {
    let where = "spend ledger.events[" ++ Belt.Int.toString(index) ++ "]"
    let event = objectOf(eventJson, where)
    let classId = stringField(event, "classId", where)
    if Js.Dict.get(budgetClasses, classId) == None {
      die(where ++ " uses unknown budget class " ++ classId)
    }
    let credits = numberField(event, "actualCredits", where)
    if credits < 0.0 {
      die(where ++ ".actualCredits cannot be negative")
    }
    actualSpend := actualSpend.contents +. credits
    addFloat(classActuals, classId, credits)
    let targetId = stringField(event, "targetId", where)
    let attempt = intField(event, "attempt", where)
    if attempt < 1 {
      die(where ++ ".attempt must be positive")
    }
    let historyKey = classId ++ "#" ++ targetId
    let attemptKey = historyKey ++ "#" ++ Belt.Int.toString(attempt)
    if Js.Dict.get(seenAttempts, attemptKey) != None {
      die("spend ledger contains duplicate attempt " ++ attemptKey)
    }
    Js.Dict.set(seenAttempts, attemptKey, true)
    addInt(historyCounts, historyKey, 1)
    let previousHistoryMax = Js.Dict.get(historyMaximumAttempts, historyKey)->Belt.Option.getWithDefault(0)
    if attempt > previousHistoryMax {
      Js.Dict.set(historyMaximumAttempts, historyKey, attempt)
    }
    switch Js.Dict.get(routesById, targetId) {
    | Some(item) if classId == routeClassForId(targetId) => {
        if targetId != "C03" {
          if stringField(item, "routeKind", "route.routes") != "paid" {
            die("spend ledger contains a paid event for nonpaid route " ++ targetId)
          }
          let eventModel = stringField(event, "model", where)
          if Js.String2.includes(Js.String2.toLowerCase(eventModel), "seedance") ||
            eventModel != stringField(item, "model", "route.routes") {
            die("spend ledger contains a post-route model violation for " ++ targetId)
          }
        }
        addInt(eventCounts, targetId, 1)
        let previousMax = Js.Dict.get(maximumAttempts, targetId)->Belt.Option.getWithDefault(0)
        if attempt > previousMax {
          Js.Dict.set(maximumAttempts, targetId, attempt)
        }
        if terminalLifecycle(stringField(event, "status", where)) {
          Js.Dict.set(acceptedTargets, targetId, true)
        }
      }
    | _ => ()
    }
  })
  historyCounts->Js.Dict.entries->Belt.Array.forEach(((historyKey, count)) => {
    let maximum = Js.Dict.get(historyMaximumAttempts, historyKey)->Belt.Option.getWithDefault(0)
    if count != maximum || count > 2 {
      die(historyKey ++ " attempt history is noncontiguous or exceeds two attempts")
    }
  })
  let calibrationSpend = numberField(
    objectField(budget, "strategy", "budget"),
    "calibrationLockedAtActualCredits",
    "budget.strategy",
  )
  if actualSpend.contents < calibrationSpend {
    die("live spend ledger has regressed below the 80-credit calibration snapshot")
  }
  budgetClasses->Js.Dict.entries->Belt.Array.forEach(((classId, class_)) => {
    let live = Js.Dict.get(classActuals, classId)->Belt.Option.getWithDefault(0.0)
    if live +. 0.0001 < class_.currentActual {
      die("live spend for " ++ classId ++ " is below its calibration baseline")
    }
  })

  let targetEventCount = Js.Dict.get(eventCounts, request.targetId)->Belt.Option.getWithDefault(0)
  let targetMaximumAttempt = Js.Dict.get(maximumAttempts, request.targetId)->Belt.Option.getWithDefault(0)
  if targetEventCount != targetMaximumAttempt {
    die(request.targetId ++ " attempt history is not contiguous from attempt one")
  }
  if Js.Dict.get(acceptedTargets, request.targetId) != None {
    die(request.targetId ++ " already has an accepted spend event")
  }
  if targetEventCount >= 2 {
    die(request.targetId ++ " already has two attempts; a third attempt is forbidden")
  }
  let nextAttempt = targetEventCount + 1
  if retryPolicy == "no_direct_retry_local_fallback" && nextAttempt > 1 {
    die(request.targetId ++ " permits no direct paid retry; use its local fallback")
  }
  if retryPolicy == "one_shared_cinema_retry_total" && nextAttempt > 1 {
    let cinemaRetries = ["H01", "H02"]->Belt.Array.reduce(0, (total, id) => {
      let attempts = Js.Dict.get(eventCounts, id)->Belt.Option.getWithDefault(0)
      total + (attempts > 1 ? attempts - 1 : 0)
    })
    if cinemaRetries >= 1 {
      die("the one shared Cinema retry has already been consumed")
    }
  }

  let remainingVideoFirstPasses = ref(0.0)
  routeItems->Belt.Array.forEach(routeJson => {
    let item = objectOf(routeJson, "route.routes")
    if stringField(item, "routeKind", "route.routes") == "paid" {
      let id = stringField(item, "id", "route.routes")
      let alreadyAttempted = Js.Dict.get(eventCounts, id)->Belt.Option.getWithDefault(0) > 0
      let fulfilledByThisAuthorization = id == request.targetId && nextAttempt == 1
      if !alreadyAttempted && !fulfilledByThisAuthorization {
        remainingVideoFirstPasses := remainingVideoFirstPasses.contents +.
          numberField(item, "quoteGate", "route.routes")
      }
    }
  })
  if nextAttempt > 1 && remainingVideoFirstPasses.contents > 0.0001 {
    die("optional retries remain locked until every paid first pass is resolved and the rough cut is assembled")
  }

  let remainingSupportFirstPasses = ref(0.0)
  ["A_STILLS", "F_AUDIO"]->Belt.Array.forEach(classId => {
    let class_ = Js.Dict.get(budgetClasses, classId)->Belt.Option.getExn
    let live = Js.Dict.get(classActuals, classId)->Belt.Option.getWithDefault(0.0)
    let spentAfterCalibration = live -. class_.currentActual
    let remaining = class_.remainingExpected -. spentAfterCalibration
    if remaining > 0.0 {
      remainingSupportFirstPasses := remainingSupportFirstPasses.contents +. remaining
    }
  })

  let projectedSpend = actualSpend.contents +. request.quoteCredits
  rejectThreshold(projectedSpend)
  let remainingMandatoryFirstPassCredits =
    remainingVideoFirstPasses.contents +. remainingSupportFirstPasses.contents
  let protectedProjectedCredits = projectedSpend +. remainingMandatoryFirstPassCredits
  if protectedProjectedCredits > revisedRouteMaximum +. 0.0001 {
    die(
      "protected spend would be " ++ Js.Float.toString(protectedProjectedCredits) ++
      " credits after reserving mandatory first passes, above the 769-credit route authority",
    )
  }
  if projectedSpend > operatingCeiling +. 0.0001 || projectedSpend > absoluteCap +. 0.0001 {
    die("projected spend exceeds the approved operating or absolute ceiling")
  }

  let routeSha256 = B.sha256Text(routeRaw)
  let provenanceSha256 = B.sha256Text(sourceRaw)
  let budgetSha256 = B.sha256Text(budgetRaw)
  let spendLedgerSha256 = B.sha256Text(spendRaw)
  let variantLabel = switch request.variant {
  | Some(value) => value
  | None => "-"
  }
  let authorizationFingerprint = B.sha256Text(
    routeSha256 ++ "|" ++ provenanceSha256 ++ "|" ++ budgetSha256 ++ "|" ++
    spendLedgerSha256 ++ "|" ++ request.targetId ++ "|" ++ Belt.Int.toString(nextAttempt) ++
    "|" ++ request.model ++ "|" ++ variantLabel ++ "|" ++
    Js.Float.toString(request.durationSeconds) ++ "|" ++ Js.Float.toString(request.quoteCredits) ++
    "|" ++ request.promptSha256 ++ "|" ++ request.startFrameSha256,
  )

  {
    authorizationFingerprint,
    targetId: request.targetId,
    attempt: nextAttempt,
    model: request.model,
    variant: request.variant,
    durationSeconds: request.durationSeconds,
    nativeAudioOnVideo: false,
    quoteCredits: request.quoteCredits,
    promptPath,
    startFramePath,
    promptSha256: request.promptSha256,
    startFrameSha256: request.startFrameSha256,
    routeSha256,
    provenanceSha256,
    budgetSha256,
    spendLedgerSha256,
    actualSpend: actualSpend.contents,
    projectedSpend,
    remainingMandatoryFirstPassCredits,
    protectedProjectedCredits,
    revisedRouteMaximum,
    operatingCeiling,
    absoluteCap,
  }
}

let productionInspectors: inspectors = {
  exists: path => B.exists(B.Path(path)),
  sha256: path => B.sha256File(B.Path(path)),
}

let authorize = (
  ~routePath,
  ~sourcePath,
  ~budgetPath,
  ~spendPath,
  ~request: request,
): result => {
  let routePath = resolvePath(routePath)
  let sourcePath = resolvePath(sourcePath)
  let budgetPath = resolvePath(budgetPath)
  let spendPath = resolvePath(spendPath)
  let routeRaw = readRaw(routePath, "route")
  let sourceRaw = readRaw(sourcePath, "paid-shot provenance")
  let budgetRaw = readRaw(budgetPath, "budget")
  let spendRaw = readRaw(spendPath, "spend ledger")
  let route = parseRoot(routeRaw, "route")
  let authority = objectField(route, "authority", "route")
  let declaredSource = resolve2(
    dirname(routePath),
    stringField(authority, "sourceAcquisitionManifest", "route.authority"),
  )
  if declaredSource != sourcePath {
    die("the supplied provenance manifest is not the source bound by route v2")
  }
  let result = authorizeRaw(
    ~routeRaw,
    ~sourceRaw,
    ~budgetRaw,
    ~spendRaw,
    ~manifestDirectory=dirname(sourcePath),
    ~request,
    ~inspectors=productionInspectors,
  )
  if readRaw(routePath, "route") != routeRaw ||
    readRaw(sourcePath, "paid-shot provenance") != sourceRaw ||
    readRaw(budgetPath, "budget") != budgetRaw ||
    readRaw(spendPath, "spend ledger") != spendRaw ||
    productionInspectors.sha256(result.promptPath) != result.promptSha256 ||
    productionInspectors.sha256(result.startFramePath) != result.startFrameSha256 {
    die("an authority, lifecycle, spend, prompt, or start-frame input changed during authorization")
  }
  result
}

let resultJson = result => {
  let root = Js.Dict.empty()
  Js.Dict.set(root, "status", Js.Json.string("AUTHORIZED_ONCE"))
  Js.Dict.set(root, "authorizationFingerprint", Js.Json.string(result.authorizationFingerprint))
  Js.Dict.set(root, "targetId", Js.Json.string(result.targetId))
  Js.Dict.set(root, "attempt", Js.Json.number(Belt.Int.toFloat(result.attempt)))
  Js.Dict.set(root, "model", Js.Json.string(result.model))
  Js.Dict.set(root, "variant", Js.Json.string(switch result.variant { | Some(value) => value | None => "-" }))
  Js.Dict.set(root, "durationSeconds", Js.Json.number(result.durationSeconds))
  Js.Dict.set(root, "nativeAudioOnVideo", Js.Json.boolean(result.nativeAudioOnVideo))
  Js.Dict.set(root, "exactQuoteCredits", Js.Json.number(result.quoteCredits))
  Js.Dict.set(root, "promptPath", Js.Json.string(result.promptPath))
  Js.Dict.set(root, "startFramePath", Js.Json.string(result.startFramePath))
  Js.Dict.set(root, "promptSha256", Js.Json.string(result.promptSha256))
  Js.Dict.set(root, "startFrameSha256", Js.Json.string(result.startFrameSha256))
  Js.Dict.set(root, "routeSha256", Js.Json.string(result.routeSha256))
  Js.Dict.set(root, "provenanceSha256", Js.Json.string(result.provenanceSha256))
  Js.Dict.set(root, "budgetSha256", Js.Json.string(result.budgetSha256))
  Js.Dict.set(root, "spendLedgerSha256", Js.Json.string(result.spendLedgerSha256))
  Js.Dict.set(root, "actualSpend", Js.Json.number(result.actualSpend))
  Js.Dict.set(root, "projectedSpend", Js.Json.number(result.projectedSpend))
  Js.Dict.set(
    root,
    "remainingMandatoryFirstPassCredits",
    Js.Json.number(result.remainingMandatoryFirstPassCredits),
  )
  Js.Dict.set(root, "protectedProjectedCredits", Js.Json.number(result.protectedProjectedCredits))
  Js.Dict.set(root, "revisedRouteMaximum", Js.Json.number(result.revisedRouteMaximum))
  Js.Dict.set(root, "operatingCeiling", Js.Json.number(result.operatingCeiling))
  Js.Dict.set(root, "absoluteCap", Js.Json.number(result.absoluteCap))
  Js.Dict.set(root, "validForSingleSubmission", Js.Json.boolean(true))
  Js.Dict.set(root, "mustReauthorizeAfterAnySubmissionOrMutation", Js.Json.boolean(true))
  Js.Json.object_(root)
}

let printResult = result =>
  Js.log(resultJson(result)->Js.Json.stringifyWithSpace(2))
