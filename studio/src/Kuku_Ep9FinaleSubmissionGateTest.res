module B = Cinema_Backends

let check = (condition, message) =>
  if !condition {
    raise(Failure(message))
  }

let blockedMessage = fn =>
  try {
    fn()
    "NOT_BLOCKED"
  } catch {
  | Kuku_Ep9FinaleSubmissionGate.SubmissionGateError(message) => message
  }

let root = "../stories/kuku/ep9prod/finale/"
let activeRouteRaw = B.readText(B.Path(root ++ "manifests/ep9_finale_route.v2.json"))
let inactiveRouteRaw = Js.String2.replace(activeRouteRaw, `"active": true`, `"active": false`)
let sourceRaw = B.readText(B.Path("fixtures/kuku_ep9_finale_paid_shots_calibration.v1.json"))
let budgetRaw = B.readText(B.Path(root ++ "budget/ep9_finale_budget.v2.json"))
let frozenSpendRaw = B.readText(B.Path("fixtures/kuku_ep9_finale_spend_calibration.v1.json"))
let promptHash = Js.String2.repeat("a", 64)
let frameHash = Js.String2.repeat("b", 64)

let inspectors: Kuku_Ep9FinaleSubmissionGate.inspectors = {
  exists: _ => true,
  sha256: path => Js.String2.endsWith(path, ".txt") ? promptHash : frameHash,
}

let request = (
  ~targetId="B03",
  ~model="kling2_6",
  ~variant=None,
  ~durationSeconds=10.0,
  ~quoteCredits=10.0,
  ~promptSha256=promptHash,
  ~startFrameSha256=frameHash,
  (),
): Kuku_Ep9FinaleSubmissionGate.request => {
  targetId,
  model,
  variant,
  durationSeconds,
  quoteCredits,
  promptSha256,
  startFrameSha256,
}

let authorize = (
  ~routeRaw=inactiveRouteRaw,
  ~spendRaw=frozenSpendRaw,
  ~request=request(),
  ~inspectors=inspectors,
  (),
) =>
  Kuku_Ep9FinaleSubmissionGate.authorizeRaw(
    ~routeRaw,
    ~sourceRaw,
    ~budgetRaw,
    ~spendRaw,
    ~manifestDirectory="/fixture/manifests",
    ~request,
    ~inspectors,
  )

let appendEvent = (~raw, ~targetId, ~classId, ~attempt, ~model, ~credits, ~status) => {
  let root = raw->Js.Json.parseExn->Js.Json.decodeObject->Belt.Option.getExn
  let events = Js.Dict.get(root, "events")
  ->Belt.Option.flatMap(Js.Json.decodeArray)
  ->Belt.Option.getExn
  let event = Js.Dict.empty()
  Js.Dict.set(event, "classId", Js.Json.string(classId))
  Js.Dict.set(event, "targetId", Js.Json.string(targetId))
  Js.Dict.set(event, "attempt", Js.Json.number(Belt.Int.toFloat(attempt)))
  Js.Dict.set(event, "model", Js.Json.string(model))
  Js.Dict.set(event, "actualCredits", Js.Json.number(credits))
  Js.Dict.set(event, "status", Js.Json.string(status))
  events->Js.Array2.push(Js.Json.object_(event))->ignore
  Js.Json.object_(root)->Js.Json.stringify
}

let heldPaidIds = [
  "B03", "B04", "B06", "B07", "B10", "B11", "B12", "B13", "B16", "B17", "B18",
  "C01", "C02", "C04", "C05", "C07", "C08", "C13", "C14", "C15", "C16", "C18",
  "D02", "D03", "D06", "D07", "H01", "H02",
]
check(Belt.Array.length(heldPaidIds) == 28, "hold test covers every paid route")
heldPaidIds->Belt.Array.forEach(targetId => {
  let message = blockedMessage(() =>
    authorize(
      ~routeRaw=activeRouteRaw,
      ~request=request(~targetId, ~model="held_request_never_reaches_model_validation", ()),
      (),
    )->ignore
  )
  check(Js.String2.includes(message, "production_hold_active"), "active hold blocks " ++ targetId)
  check(
    Js.String2.includes(message, "sound_off_continuity_rebuild_2026-08-16"),
    "active hold identifies itself for " ++ targetId,
  )
  check(Js.String2.includes(message, "Reason:"), "active hold states its reason for " ++ targetId)
  check(
    Js.String2.includes(message, "Release condition:"),
    "active hold states its release condition for " ++ targetId,
  )
})

let success = authorize()
check(success.targetId == "B03", "authorized target")
check(success.attempt == 1, "first attempt")
check(success.actualSpend == 80.0, "frozen calibration spend")
check(success.projectedSpend == 90.0, "projected spend")
check(success.remainingMandatoryFirstPassCredits == 396.0, "remaining mandatory first passes")
check(success.protectedProjectedCredits == 486.0, "protected expected completion")
check(!success.nativeAudioOnVideo, "native video audio remains disabled")
check(Js.String2.length(success.authorizationFingerprint) == 64, "authorization fingerprint")

let staleSpendRoot = frozenSpendRaw->Js.Json.parseExn->Js.Json.decodeObject->Belt.Option.getExn
Js.Dict.set(
  staleSpendRoot,
  "activeRouteManifest",
  Js.Json.string("../manifests/ep9_finale_paid_shots.v1.json"),
)
let staleSpendRaw = Js.Json.object_(staleSpendRoot)->Js.Json.stringify
check(
  Js.String2.includes(
    blockedMessage(() => authorize(~spendRaw=staleSpendRaw, ())->ignore),
    "must bind route v2 and budget v2",
  ),
  "stale spend-ledger authority rejected",
)

check(
  Js.String2.includes(
    blockedMessage(() => authorize(~request=request(~targetId="B01", ()), ())->ignore),
    "routed as local",
  ),
  "local route rejected",
)
check(
  Js.String2.includes(
    blockedMessage(() => authorize(~request=request(~targetId="B09", ()), ())->ignore),
    "routed as reuse",
  ),
  "reuse route rejected",
)
check(
  Js.String2.includes(
    blockedMessage(() => authorize(~request=request(~targetId="C03", ()), ())->ignore),
    "C03 is permanently locked",
  ),
  "C03 rejected",
)
check(
  Js.String2.includes(
    blockedMessage(() => authorize(~request=request(~model="seedance1_5", ()), ())->ignore),
    "Seedance is forbidden",
  ),
  "Seedance rejected",
)
check(
  Js.String2.includes(
    blockedMessage(() => authorize(~request=request(
      ~targetId="B07",
      ~model="veo3_1_lite",
      ~durationSeconds=8.0,
      ~quoteCredits=8.0,
      (),
    ), ())->ignore),
    "accepted locked asset",
  ),
  "accepted pilot rejected",
)
check(
  Js.String2.includes(
    blockedMessage(() => authorize(~request=request(~model="veo3_1_lite", ()), ())->ignore),
    "model does not match",
  ),
  "model mismatch rejected",
)
check(
  Js.String2.includes(
    blockedMessage(() => authorize(~request=request(~variant=Some("unexpected"), ()), ())->ignore),
    "variant does not match",
  ),
  "variant mismatch rejected",
)
check(
  Js.String2.includes(
    blockedMessage(() => authorize(~request=request(~durationSeconds=8.0, ()), ())->ignore),
    "duration does not match",
  ),
  "duration mismatch rejected",
)
check(
  Js.String2.includes(
    blockedMessage(() => authorize(~request=request(~quoteCredits=9.0, ()), ())->ignore),
    "exact quote does not match",
  ),
  "quote mismatch rejected",
)
check(
  Js.String2.includes(
    blockedMessage(() => authorize(
      ~request=request(~promptSha256=Js.String2.repeat("c", 64), ()),
      (),
    )->ignore),
    "prompt hash does not match",
  ),
  "prompt hash mismatch rejected",
)
check(
  Js.String2.includes(
    blockedMessage(() => authorize(
      ~inspectors={...inspectors, sha256: _ => promptHash},
      (),
    )->ignore),
    "start-frame hash does not match",
  ),
  "start-frame hash mismatch rejected",
)

let b03Attempt1 = appendEvent(
  ~raw=frozenSpendRaw,
  ~targetId="B03",
  ~classId="B_WIDE_ENVIRONMENT",
  ~attempt=1,
  ~model="kling2_6",
  ~credits=10.0,
  ~status="rejected",
)
let b03Attempt2 = appendEvent(
  ~raw=b03Attempt1,
  ~targetId="B03",
  ~classId="B_WIDE_ENVIRONMENT",
  ~attempt=2,
  ~model="kling2_6",
  ~credits=10.0,
  ~status="rejected",
)
check(
  Js.String2.includes(
    blockedMessage(() => authorize(~spendRaw=b03Attempt2, ())->ignore),
    "third attempt is forbidden",
  ),
  "third attempt rejected",
)

let acceptedB03 = appendEvent(
  ~raw=frozenSpendRaw,
  ~targetId="B03",
  ~classId="B_WIDE_ENVIRONMENT",
  ~attempt=1,
  ~model="kling2_6",
  ~credits=10.0,
  ~status="accepted",
)
check(
  Js.String2.includes(
    blockedMessage(() => authorize(~spendRaw=acceptedB03, ())->ignore),
    "accepted spend event",
  ),
  "accepted ledger asset rejected",
)

let d02Attempt1 = appendEvent(
  ~raw=frozenSpendRaw,
  ~targetId="D02",
  ~classId="D_COMPLEX_GROUP",
  ~attempt=1,
  ~model="gemini_omni",
  ~credits=24.0,
  ~status="rejected",
)
check(
  Js.String2.includes(
    blockedMessage(() => authorize(
      ~spendRaw=d02Attempt1,
      ~request=request(
        ~targetId="D02",
        ~model="gemini_omni",
        ~durationSeconds=8.0,
        ~quoteCredits=24.0,
        (),
      ),
      (),
    )->ignore),
    "no direct paid retry",
  ),
  "Gemini direct retry rejected",
)

let syntheticSpend = credits => appendEvent(
  ~raw=frozenSpendRaw,
  ~targetId="SYNTHETIC_" ++ Js.Float.toString(credits),
  ~classId="A_STILLS",
  ~attempt=1,
  ~model="fixture",
  ~credits,
  ~status="fixture",
)

[
  (410.0, "first_pass_assembly"),
  (560.0, "critical_only"),
  (660.0, "accepted_yield_audit"),
  (679.0, "revised_route_stop"),
  (809.0, "operating_stop"),
  (910.0, "premium_disable"),
  (1010.0, "absolute_stop"),
]->Belt.Array.forEach(((extraCredits, expectedStop)) =>
  check(
    Js.String2.includes(
      blockedMessage(() => authorize(~spendRaw=syntheticSpend(extraCredits), ())->ignore),
      expectedStop,
    ),
    expectedStop ++ " threshold rejected",
  )
)

check(
  Js.String2.includes(
    blockedMessage(() => authorize(~spendRaw=syntheticSpend(320.0), ())->ignore),
    "protected spend would be",
  ),
  "mandatory-obligation ceiling rejected",
)

Js.log("Kuku_Ep9FinaleSubmissionGateTest: ok")
