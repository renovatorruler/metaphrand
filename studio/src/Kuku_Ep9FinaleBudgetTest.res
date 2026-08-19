let check = (condition, message) =>
  if !condition {
    raise(Failure(message))
  }

let root = "../stories/kuku/ep9prod/finale/budget/"
let result = Kuku_Ep9FinaleBudget.validate(
  ~budgetPath=root ++ "ep9_finale_budget.v2.json",
  ~spendPath="fixtures/kuku_ep9_finale_spend_calibration.v1.json",
)

check(result.operatingCeiling == 899.0, "operating ceiling")
check(result.reserve == 201.0, "locked reserve")
check(result.absoluteCap == 1100.0, "absolute cap")
check(result.classMaximum == 769.0, "class maximum")
check(result.expectedCompletion == 486.0, "expected completion")
check(result.revisedRouteMaximum == 769.0, "revised route maximum")
check(result.firstTakeMotionSeconds == 266.0, "paid acquisition")
check(result.paidFinalUsageSeconds == 242.0, "paid final usage")
check(result.localOrReuseConversionSeconds == 128.0, "local conversion")
check(result.totalMotionCoverageSeconds == 370.0, "motion coverage")
check(result.actualSpend == 80.0, "current spend")
check(result.eventCount == 28, "current event count")

/* The production ledger is mutable. Validate it every run, but never freeze a
   live spend amount or event count into a unit-test assertion. */
let live = Kuku_Ep9FinaleBudget.validate(
  ~budgetPath=root ++ "ep9_finale_budget.v2.json",
  ~spendPath=root ++ "ep9_finale_spend.v1.json",
)
check(live.actualSpend >= 80.0, "live ledger must not regress below calibration")
check(live.eventCount >= 28, "live ledger must retain calibration events")

Js.log("Kuku_Ep9FinaleBudgetTest: ok")
