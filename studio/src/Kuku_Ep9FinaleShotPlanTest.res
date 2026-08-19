let manifest = "../stories/kuku/ep9prod/finale/manifests/ep9_finale_paid_shots.v1.json"
let result = Kuku_Ep9FinaleShotPlan.validate(~manifestPath=manifest)

if result.count != 45 || result.seconds != 396.0 || result.credits != 562.0 {
  raise(Failure("paid-shot totals changed"))
}
if Belt.Array.length(result.missingInputs) > 82 {
  raise(Failure("legacy acquisition inputs regressed below the locked calibration state"))
}
[
  "B03:prompt",
  "B03:start_frame",
  "B04:prompt",
  "B04:start_frame",
  "B06:prompt",
  "B06:start_frame",
]->Belt.Array.forEach(expectedPresent => {
  if result.missingInputs->Belt.Array.some(value => value == expectedPresent) {
    raise(Failure("prepared first-batch input is missing: " ++ expectedPresent))
  }
})
if Belt.Array.length(result.missingInputs) == 0 {
  raise(Failure("legacy v1 manifest unexpectedly claims every superseded paid input is ready"))
}

Js.log("Kuku_Ep9FinaleShotPlanTest: ok")
