module B = Cinema_Backends

let check = (condition, message) =>
  if !condition {
    raise(Failure(message))
  }

let expectRouteError = (run, expectedFragment) => {
  let message = try {
    run()
    raise(Failure("expected route validation to fail"))
  } catch {
  | Kuku_Ep9FinaleRoute.RouteError(message) => message
  }
  check(Js.String2.includes(message, expectedFragment), "unexpected route error: " ++ message)
}

let routePath =
  "../stories/kuku/ep9prod/finale/manifests/ep9_finale_route.v2.json"
let sourcePath =
  "../stories/kuku/ep9prod/finale/manifests/ep9_finale_paid_shots.v1.json"

let result = Kuku_Ep9FinaleRoute.validate(~routePath)
check(result.routeCount == 45, "route must cover every acquisition ID")
check(result.paidCount == 28, "paid route count")
check(result.localOrReuseCount == 17, "local/reuse route count")
check(result.paidAcquisitionSeconds == 266.0, "paid acquisition seconds")
check(result.paidFinalUsageSeconds == 242.0, "paid final-use seconds")
check(result.localOrReuseSeconds == 128.0, "local/reuse conversion seconds")
check(result.totalMotionSeconds == 370.0, "total motion coverage")
check(result.paidFirstTakeCredits == 371.0, "route first-take credits")
check(result.expectedTotalCredits == 486.0, "expected production total")
check(result.revisedMaximumCredits == 769.0, "revised maximum")

let routeRaw = B.readText(B.Path(routePath))
let sourceRaw = B.readText(B.Path(sourcePath))

expectRouteError(
  () =>
    Kuku_Ep9FinaleRoute.validateRaw(
      ~routeRaw=Js.String2.replace(
        routeRaw,
        `"scope": "all_paid_submissions"`,
        `"scope": "single_target"`,
      ),
      ~sourceRaw,
    )->ignore,
  "scope must remain all_paid_submissions",
)

expectRouteError(
  () =>
    Kuku_Ep9FinaleRoute.validateRaw(
      ~routeRaw=Js.String2.replace(routeRaw, `"active": true`, `"active": "yes"`),
      ~sourceRaw,
    )->ignore,
  "active must be a boolean",
)

expectRouteError(
  () =>
    Kuku_Ep9FinaleRoute.validateRaw(
      ~routeRaw=Js.String2.replace(routeRaw, `"model":"kling2_6"`, `"model":"seedance1_5"`),
      ~sourceRaw,
    )->ignore,
  "no-Seedance",
)

expectRouteError(
  () =>
    Kuku_Ep9FinaleRoute.validateRaw(
      ~routeRaw=Js.String2.replace(routeRaw, `"id":"B01"`, `"id":"B02"`),
      ~sourceRaw,
    )->ignore,
  "duplicate route id",
)

expectRouteError(
  () =>
    Kuku_Ep9FinaleRoute.validateRaw(
      ~routeRaw=Js.String2.replace(
        routeRaw,
        `"paidAcquisitionSeconds": 266`,
        `"paidAcquisitionSeconds": 265`,
      ),
      ~sourceRaw,
    )->ignore,
  "paidAcquisitionSeconds must be 266",
)

Js.log("Kuku_Ep9FinaleRouteTest: ok")
