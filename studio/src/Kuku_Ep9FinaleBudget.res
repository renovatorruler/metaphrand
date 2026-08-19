/* Zero-spend validator for the Episode 9 finale credit envelope.

   This module never calls a provider and never writes a file. It rejects a
   budget whose class maxima do not exactly equal the operating ceiling, a
   reserve that does not close exactly to the absolute cap, or a spend ledger
   that exceeds any automatic stop. */

module B = Cinema_Backends

exception BudgetError(string)

let die = message => raise(BudgetError(message))

let objectOf = (json, where) =>
  switch Js.Json.decodeObject(json) {
  | Some(value) => value
  | None => die(where ++ " must be an object")
  }

let arrayOf = (object_, key, where) =>
  switch Js.Dict.get(object_, key)->Belt.Option.flatMap(Js.Json.decodeArray) {
  | Some(value) => value
  | None => die(where ++ "." ++ key ++ " must be an array")
  }

let objectField = (object_, key, where) =>
  switch Js.Dict.get(object_, key)->Belt.Option.map(value => objectOf(value, where ++ "." ++ key)) {
  | Some(value) => value
  | None => die(where ++ "." ++ key ++ " is required")
  }

let numberField = (object_, key, where) =>
  switch Js.Dict.get(object_, key)->Belt.Option.flatMap(Js.Json.decodeNumber) {
  | Some(value) => value
  | None => die(where ++ "." ++ key ++ " must be a number")
  }

let stringField = (object_, key, where) =>
  switch Js.Dict.get(object_, key)->Belt.Option.flatMap(Js.Json.decodeString) {
  | Some(value) => value
  | None => die(where ++ "." ++ key ++ " must be a string")
  }

let close = (left, right) => Js.Math.abs_float(left -. right) < 0.0001

let readObject = (path, where) =>
  try B.readText(B.Path(path))->Js.Json.parseExn->objectOf(where) catch {
  | B.BackendError(message) => die(where ++ " cannot be read: " ++ message)
  | Js.Exn.Error(error) =>
    die(
      where ++ " is not valid JSON: " ++
      Js.Exn.message(error)->Belt.Option.getWithDefault("unknown parse error"),
    )
  }

type result = {
  operatingCeiling: float,
  reserve: float,
  absoluteCap: float,
  classMaximum: float,
  expectedCompletion: float,
  revisedRouteMaximum: float,
  firstTakeMotionSeconds: float,
  paidFinalUsageSeconds: float,
  localOrReuseConversionSeconds: float,
  totalMotionCoverageSeconds: float,
  actualSpend: float,
  eventCount: int,
}

let validate = (~budgetPath, ~spendPath): result => {
  let budget = readObject(budgetPath, "budget")
  let approval = objectField(budget, "approval", "budget")
  let totals = objectField(budget, "totals", "budget")
  let operatingCeiling = numberField(approval, "operatingCeiling", "budget.approval")
  let reserve = numberField(approval, "lockedEmergencyReserve", "budget.approval")
  let absoluteCap = numberField(approval, "absoluteCap", "budget.approval")
  let firstTakeMotionSeconds =
    numberField(totals, "plannedFirstTakeMotionSeconds", "budget.totals")
  let paidFinalUsageSeconds = numberField(totals, "paidFinalUsageSeconds", "budget.totals")
  let localOrReuseConversionSeconds =
    numberField(totals, "localOrReuseConversionSeconds", "budget.totals")
  let totalMotionCoverageSeconds =
    numberField(totals, "totalMotionCoverageSeconds", "budget.totals")
  let expectedCompletion = numberField(totals, "expectedCompletionCredits", "budget.totals")
  let revisedRouteMaximum =
    numberField(totals, "revisedRouteMaximumCredits", "budget.totals")

  if !close(operatingCeiling +. reserve, absoluteCap) {
    die("operating ceiling plus reserve must equal the absolute cap")
  }
  if !close(operatingCeiling, 899.0) || !close(reserve, 201.0) || !close(absoluteCap, 1100.0) {
    die("the approved 899 + 201 = 1100 envelope has drifted")
  }

  let classIds = Js.Dict.empty()
  let classMaximum = ref(0.0)
  let classExpected = ref(0.0)
  arrayOf(budget, "classes", "budget")->Belt.Array.forEachWithIndex((index, classJson) => {
    let where = "budget.classes[" ++ Belt.Int.toString(index) ++ "]"
    let class_ = objectOf(classJson, where)
    let id = stringField(class_, "id", where)
    if Js.Dict.get(classIds, id) != None {
      die("duplicate budget class: " ++ id)
    }
    Js.Dict.set(classIds, id, true)
    let firstTake = numberField(class_, "firstTakeCredits", where)
    let retry = numberField(class_, "retryCredits", where)
    let maximum = numberField(class_, "maximumCredits", where)
    if !close(firstTake +. retry, maximum) {
      die(id ++ " maximumCredits must equal firstTakeCredits plus retryCredits")
    }
    classMaximum := classMaximum.contents +. maximum
    classExpected := classExpected.contents +. firstTake
  })

  if !close(classMaximum.contents, revisedRouteMaximum) {
    die("class maxima must sum exactly to the revised route maximum")
  }
  if !close(classExpected.contents, expectedCompletion) {
    die("class first-take totals must sum exactly to expected completion credits")
  }
  if !close(firstTakeMotionSeconds, 266.0) || !close(paidFinalUsageSeconds, 242.0) ||
    !close(localOrReuseConversionSeconds, 128.0) || !close(totalMotionCoverageSeconds, 370.0) {
    die("the post-calibration 266/242/128/370 motion strategy has drifted")
  }
  if !close(expectedCompletion, 486.0) || !close(revisedRouteMaximum, 769.0) {
    die("the post-calibration 486 expected / 769 maximum route has drifted")
  }
  if revisedRouteMaximum >= operatingCeiling {
    die("the revised route must retain headroom beneath the operating ceiling")
  }

  let spend = readObject(spendPath, "spend ledger")
  let actualSpend = ref(0.0)
  let events = arrayOf(spend, "events", "spend ledger")
  events->Belt.Array.forEachWithIndex((index, eventJson) => {
    let where = "spend ledger.events[" ++ Belt.Int.toString(index) ++ "]"
    let event = objectOf(eventJson, where)
    let credits = numberField(event, "actualCredits", where)
    if credits < 0.0 {
      die(where ++ ".actualCredits cannot be negative")
    }
    actualSpend := actualSpend.contents +. credits
  })

  if actualSpend.contents > absoluteCap +. 0.0001 {
    die("actual spend exceeds the absolute cap")
  }
  if actualSpend.contents > revisedRouteMaximum +. 0.0001 {
    die("actual spend exceeds the revised route maximum; update authority before continuing")
  }

  {
    operatingCeiling,
    reserve,
    absoluteCap,
    classMaximum: classMaximum.contents,
    expectedCompletion,
    revisedRouteMaximum,
    firstTakeMotionSeconds,
    paidFinalUsageSeconds,
    localOrReuseConversionSeconds,
    totalMotionCoverageSeconds,
    actualSpend: actualSpend.contents,
    eventCount: Belt.Array.length(events),
  }
}

let printResult = result => {
  Js.log("KUKU EP9 FINALE BUDGET — VALID")
  Js.log(
    "operating ceiling: " ++ Js.Float.toString(result.operatingCeiling) ++
    " | locked reserve: " ++ Js.Float.toString(result.reserve) ++
    " | absolute cap: " ++ Js.Float.toString(result.absoluteCap),
  )
  Js.log(
    "paid acquisition: " ++ Js.Float.toString(result.firstTakeMotionSeconds) ++
    "s | paid final use: " ++ Js.Float.toString(result.paidFinalUsageSeconds) ++
    "s | total motion coverage: " ++ Js.Float.toString(result.totalMotionCoverageSeconds) ++
    "s",
  )
  Js.log(
    "expected completion: " ++ Js.Float.toString(result.expectedCompletion) ++
    " | revised maximum: " ++ Js.Float.toString(result.revisedRouteMaximum) ++
    " | locally converted: " ++ Js.Float.toString(result.localOrReuseConversionSeconds) ++
    "s",
  )
  Js.log(
    "spend events: " ++ Belt.Int.toString(result.eventCount) ++
    " | actual spend: " ++ Js.Float.toString(result.actualSpend),
  )
  if result.actualSpend >= result.revisedRouteMaximum {
    Js.log("PAUSE: revised route maximum reached; update authority before any submission")
  } else if result.actualSpend >= 750.0 {
    Js.log("YIELD AUDIT REQUIRED before further noncritical motion")
  } else if result.actualSpend >= 650.0 {
    Js.log("CRITICAL-ONLY: no retry may be used for visual polish")
  } else if result.actualSpend >= 500.0 {
    Js.log("ROUGH-CUT REVIEW REQUIRED before any retry")
  } else {
    Js.log(
      "remaining before revised-route stop: " ++
      Js.Float.toString(result.revisedRouteMaximum -. result.actualSpend),
    )
  }
}
