module B = Cinema_Backends
module D = Production_Domain
module W = Production_WorkOrder

let fail = message => {
  Js.log("FAIL - " ++ message)
  assert(false)
}

let requireOrder = evaluation =>
  switch evaluation.W.workOrder {
  | Some(order) => order
  | None => fail("expected work order, got:\n" ++ W.explain(evaluation))
  }

let hasCode = (evaluation, code) =>
  evaluation.W.findings->Belt.Array.some(finding => finding.code == code)

let expectCode = (label, evaluation, code) =>
  if !hasCode(evaluation, code) {
    fail(label ++ ": expected " ++ code ++ ", got:\n" ++ W.explain(evaluation))
  }

let acceptanceById = (order: W.workOrder, id) =>
  switch order.acceptance->Belt.Array.getBy(item => item.id == id) {
  | Some(item) => item
  | None => fail("missing typed acceptance " ++ id)
  }

let sameStrings = (left, right) =>
  left->Js.Array2.joinWith("\u{1f}") == right->Js.Array2.joinWith("\u{1f}")

let expectMetadata = (order, id, validator, decisionIds) => {
  let item = acceptanceById(order, id)
  if item.validator != validator || !sameStrings(item.decisionIds, decisionIds) {
    fail("typed acceptance lost validator or decision traceability for " ++ id)
  }
}

let jsonObject = json => json->Js.Json.decodeObject->Belt.Option.getExn
let jsonArray = json => json->Js.Json.decodeArray->Belt.Option.getExn
let jsonField = (row, key) => Js.Dict.get(row, key)->Belt.Option.getExn
let jsonString = (row, key) => jsonField(row, key)->Js.Json.decodeString->Belt.Option.getExn

let canonicalAcceptanceRows = order =>
  order.W.canonical
  ->Js.Json.parseExn
  ->jsonObject
  ->jsonField("acceptance")
  ->jsonArray

let canonicalAcceptanceById = (order, id) =>
  switch canonicalAcceptanceRows(order)->Belt.Array.getBy(json => {
    let row = json->jsonObject
    jsonString(row, "id") == id
  }) {
  | Some(json) => json->jsonObject
  | None => fail("canonical work order omitted acceptance " ++ id)
  }

let expectCanonicalConstraint = (order, id, expectedJson) => {
  let row = canonicalAcceptanceById(order, id)
  let actual = jsonField(row, "constraint")->D.canonicalJson
  let expected = expectedJson->Js.Json.parseExn->D.canonicalJson
  if actual != expected {
    fail(id ++ " canonical typed payload mismatch: " ++ actual)
  }
  let inMemory = acceptanceById(order, id)
  if jsonString(row, "validator") != D.validatorKindName(inMemory.validator) {
    fail(id ++ " canonical validator does not match its typed acceptance")
  }
  let canonicalDecisionIds = jsonField(row, "decisionIds")
    ->jsonArray
    ->Belt.Array.map(json => json->Js.Json.decodeString->Belt.Option.getExn)
  if !sameStrings(canonicalDecisionIds, inMemory.decisionIds) {
    fail(id ++ " canonical decision traceability does not match its typed acceptance")
  }
}

let fixture = Production_TestFixtures.create()
let initial = W.compile(~packetPath=fixture.packetPath, ~targetId="T-SYNTHETIC")
let order = requireOrder(initial)

if order.packetHash == "" || order.hash == "" || order.operation != "synthetic_octets" {
  fail("compiled work order did not bind packet, target, and operation")
}
if order.principalAction != "Subject reveals itself from behind the anchor" ||
  order.declaredActionCount != 1 || order.declaredContinuousSeconds != 3.5 {
  fail("work order lost its principal-action complexity contract")
}
if Belt.Array.length(order.acceptance) != 9 || Belt.Array.length(W.semanticChecks(order)) != 4 ||
  Belt.Array.length(W.humanQuestions(order)) != 1 {
  fail("work order did not route every typed requirement to its validator")
}
order.acceptance->Belt.Array.forEach(check => {
  if Belt.Array.length(check.decisionIds) == 0 {
    fail("acceptance check lacks decision traceability: " ++ check.id)
  }
})

/* All nine domain variants survive compilation as data, rather than only as
   display strings. These assertions intentionally inspect every payload field. */
expectMetadata(order, "R-CONTINUITY", D.Deterministic, ["D-BLOCKING", "D-FOUNDATION"])
switch acceptanceById(order, "R-CONTINUITY").requirementKind {
| D.Continuity(spec)
    if spec.entityId == "E-SUBJECT" && spec.beforeStateId == "entry" &&
      spec.afterStateId == "exit" => ()
| _ => fail("continuity payload did not survive compilation")
}
expectCanonicalConstraint(
  order,
  "R-CONTINUITY",
  `{"kind":"continuity","spec":{"entityId":"E-SUBJECT","beforeStateId":"entry","afterStateId":"exit"}}`,
)

expectMetadata(order, "R-PRESENCE", D.SemanticInspector, ["D-BLOCKING"])
switch acceptanceById(order, "R-PRESENCE").requirementKind {
| D.Presence(spec)
    if spec.entityId == "E-SUBJECT" && spec.stateId == Some("exit") && spec.minimum == 1 &&
      spec.maximum == Some(1) => ()
| _ => fail("presence payload did not survive compilation")
}
expectCanonicalConstraint(
  order,
  "R-PRESENCE",
  `{"kind":"presence","spec":{"entityId":"E-SUBJECT","stateId":"exit","minimum":1,"maximum":1}}`,
)

expectMetadata(order, "R-FORBIDDEN", D.SemanticInspector, ["D-BLOCKING"])
switch acceptanceById(order, "R-FORBIDDEN").requirementKind {
| D.Forbidden(spec) if spec.entityId == "E-FORBIDDEN" && spec.stateId == Some("visible") => ()
| _ => fail("forbidden payload did not survive compilation")
}
expectCanonicalConstraint(
  order,
  "R-FORBIDDEN",
  `{"kind":"forbidden","spec":{"entityId":"E-FORBIDDEN","stateId":"visible"}}`,
)

expectMetadata(order, "R-SCALE", D.Deterministic, ["D-BLOCKING"])
switch acceptanceById(order, "R-SCALE").requirementKind {
| D.RelativeScale(spec)
    if spec.subjectEntityId == "E-SUBJECT" && spec.subjectStateId == "exit" &&
      spec.referenceEntityId == "E-ANCHOR" && spec.referenceStateId == "installed" &&
      spec.minRatio == 0.09 && spec.maxRatio == 0.11 => ()
| _ => fail("relative-scale payload did not survive compilation")
}
expectCanonicalConstraint(
  order,
  "R-SCALE",
  `{"kind":"relative_scale","spec":{"subjectEntityId":"E-SUBJECT","subjectStateId":"exit","referenceEntityId":"E-ANCHOR","referenceStateId":"installed","minRatio":0.09,"maxRatio":0.11}}`,
)

expectMetadata(order, "R-GEOGRAPHY", D.SemanticInspector, ["D-BLOCKING"])
switch acceptanceById(order, "R-GEOGRAPHY").requirementKind {
| D.Geography(spec)
    if spec.subjectEntityId == "E-SUBJECT" && spec.referenceEntityId == "E-ANCHOR" &&
      spec.relation == D.Behind => ()
| _ => fail("geography payload did not survive compilation")
}
expectCanonicalConstraint(
  order,
  "R-GEOGRAPHY",
  `{"kind":"geography","spec":{"subjectEntityId":"E-SUBJECT","referenceEntityId":"E-ANCHOR","relation":"behind"}}`,
)

expectMetadata(order, "R-CAMERA", D.HumanOnly, ["D-BLOCKING"])
switch acceptanceById(order, "R-CAMERA").requirementKind {
| D.CameraSide(spec)
    if spec.side == D.CameraRight && spec.anchorEntityId == "E-ANCHOR" &&
      spec.occluderEntityId == Some("E-ANCHOR") => ()
| _ => fail("camera-side payload did not survive compilation")
}
expectCanonicalConstraint(
  order,
  "R-CAMERA",
  `{"kind":"camera_side","spec":{"side":"right","anchorEntityId":"E-ANCHOR","occluderEntityId":"E-ANCHOR"}}`,
)

expectMetadata(order, "R-FRAMING", D.SemanticInspector, ["D-BLOCKING"])
switch acceptanceById(order, "R-FRAMING").requirementKind {
| D.Framing(spec)
    if spec.shotSize == D.Wide && sameStrings(spec.requiredEntityIds, ["E-ANCHOR", "E-SUBJECT"]) &&
      !spec.fullyVisible => ()
| _ => fail("framing payload did not survive compilation")
}
expectCanonicalConstraint(
  order,
  "R-FRAMING",
  `{"kind":"framing","spec":{"shotSize":"wide","requiredEntityIds":["E-ANCHOR","E-SUBJECT"],"fullyVisible":false}}`,
)

expectMetadata(order, "R-COMPLEXITY", D.Deterministic, ["D-BLOCKING"])
switch acceptanceById(order, "R-COMPLEXITY").requirementKind {
| D.Complexity(spec)
    if spec.maxPrincipalActions == 1 && spec.maxVisibleEntities == 3 &&
      spec.maxContinuousSeconds == 4.0 => ()
| _ => fail("complexity payload did not survive compilation")
}
expectCanonicalConstraint(
  order,
  "R-COMPLEXITY",
  `{"kind":"complexity","spec":{"maxPrincipalActions":1,"maxVisibleEntities":3,"maxContinuousSeconds":4}}`,
)

expectMetadata(order, "R-REFERENCES", D.Deterministic, ["D-BLOCKING"])
switch acceptanceById(order, "R-REFERENCES").requirementKind {
| D.References(spec)
    if sameStrings(spec.assetIds, ["A-SET", "A-SUBJECT"]) && spec.exact => ()
| _ => fail("references payload did not survive compilation")
}
expectCanonicalConstraint(
  order,
  "R-REFERENCES",
  `{"kind":"references","spec":{"assetIds":["A-SET","A-SUBJECT"],"exact":true}}`,
)

if order.schema != "production.work-order/v2" ||
  jsonString(order.canonical->Js.Json.parseExn->jsonObject, "schema") != order.schema {
  fail("typed work-order schema is not versioned consistently")
}

let second = requireOrder(W.compile(~packetPath=fixture.packetPath, ~targetId="T-SYNTHETIC"))
if W.encode(second) != W.encode(order) || second.hash != order.hash {
  fail("fresh compilation did not reconstruct an identical work order")
}

let original = B.readText(B.Path(fixture.packetPath))
let pretty = Js.Json.stringifyWithSpace(Js.Json.parseExn(original), 2) ++ "\n"
B.writeText(B.Path(fixture.packetPath), pretty)
let reformatted = requireOrder(W.compile(~packetPath=fixture.packetPath, ~targetId="T-SYNTHETIC"))
if reformatted.hash != order.hash {
  fail("work-order hash changed because packet whitespace changed")
}
B.writeText(B.Path(fixture.packetPath), original)

/* Every negative fixture must fail before an executable work order exists. */
B.writeText(
  B.Path(fixture.packetPath),
  Js.String2.replace(original, `"status":"approved"`, `"status":"candidate"`),
)
expectCode(
  "unapproved reference",
  W.compile(~packetPath=fixture.packetPath, ~targetId="T-SYNTHETIC"),
  "ASSET_NOT_APPROVED",
)
B.writeText(B.Path(fixture.packetPath), original)

B.writeText(B.Path(fixture.firstReferencePath), "tampered reference\n")
expectCode(
  "reference byte drift",
  W.compile(~packetPath=fixture.packetPath, ~targetId="T-SYNTHETIC"),
  "ASSET_HASH_MISMATCH",
)
B.writeText(B.Path(fixture.firstReferencePath), "synthetic subject reference\n")

B.writeText(
  B.Path(fixture.packetPath),
  Js.String2.replace(original, `"declaredActionCount":1`, `"declaredActionCount":2`),
)
expectCode(
  "principal action budget",
  W.compile(~packetPath=fixture.packetPath, ~targetId="T-SYNTHETIC"),
  "COMPLEXITY_ACTION_BUDGET",
)
B.writeText(B.Path(fixture.packetPath), original)

/* Re-authorizing a semantically valid change to each representative typed
   payload must produce a distinct immutable work-order hash. This complements
   the canonical-payload assertions above: the new hash cannot silently retain
   the prior constraint. */
let typedMutations = [
  ("continuity", `"beforeStateId":"entry"`, `"beforeStateId":"exit"`),
  ("presence", `"minimum":1,"maximum":1`, `"minimum":1,"maximum":2`),
  ("forbidden", `"entityId":"E-FORBIDDEN","stateId":"visible"`, `"entityId":"E-FORBIDDEN"`),
  ("relative scale", `"minRatio":0.09`, `"minRatio":0.08`),
  ("geography", `"relation":"behind"`, `"relation":"left_of"`),
  ("camera side", `"side":"right"`, `"side":"left"`),
  ("framing", `"shotSize":"wide"`, `"shotSize":"full"`),
  ("complexity", `"maxContinuousSeconds":4}`, `"maxContinuousSeconds":4.5}`),
  (
    "references",
    `"assetIds":["A-SUBJECT","A-SET"],"exact":true`,
    `"assetIds":["A-SUBJECT","A-SET"],"exact":false`,
  ),
]
typedMutations->Belt.Array.forEach(((label, before, after)) => {
  let changed = Js.String2.replace(original, before, after)
  if changed == original {
    fail(label ++ " mutation fixture did not match packet bytes")
  }
  B.writeText(
    B.Path(fixture.packetPath),
    Production_TestFixtures.bindApprovals(changed) ++ "\n",
  )
  let changedOrder = requireOrder(W.compile(~packetPath=fixture.packetPath, ~targetId="T-SYNTHETIC"))
  if changedOrder.hash == order.hash || changedOrder.canonical == order.canonical {
    fail(label ++ " typed payload was not bound into the immutable work-order hash")
  }
})
B.writeText(B.Path(fixture.packetPath), original)

B.writeText(
  B.Path(fixture.packetPath),
  Js.String2.replace(original, `"declaredContinuousSeconds":3.5`, `"declaredContinuousSeconds":8`),
)
expectCode(
  "continuous handle budget",
  W.compile(~packetPath=fixture.packetPath, ~targetId="T-SYNTHETIC"),
  "COMPLEXITY_DURATION_BUDGET",
)
B.writeText(B.Path(fixture.packetPath), original)

B.writeText(
  B.Path(fixture.packetPath),
  original
  ->Js.String2.replace(`"height":4`, `"height":20`)
  ->Js.String2.replace(`"height":4`, `"height":20`),
)
expectCode(
  "registered scale",
  W.compile(~packetPath=fixture.packetPath, ~targetId="T-SYNTHETIC"),
  "SCALE_RANGE_FAIL",
)
B.writeText(B.Path(fixture.packetPath), original)

B.writeText(
  B.Path(fixture.packetPath),
  original
  ->Js.String2.replace(`"validator":"semantic_inspector"`, `"validator":"deterministic"`)
  ->Js.String2.replace(`"validator":"semantic_inspector"`, `"validator":"deterministic"`)
  ->Js.String2.replace(`"validator":"semantic_inspector"`, `"validator":"deterministic"`)
  ->Js.String2.replace(`"validator":"semantic_inspector"`, `"validator":"deterministic"`),
)
expectCode(
  "independent semantic contract",
  W.compile(~packetPath=fixture.packetPath, ~targetId="T-SYNTHETIC"),
  "SEMANTIC_CONTRACT_MISSING",
)
B.writeText(B.Path(fixture.packetPath), original)

B.writeText(
  B.Path(fixture.packetPath),
  Js.String2.replace(original, `,"R-REFERENCES"`, ``),
)
expectCode(
  "omitted constraint",
  W.compile(~packetPath=fixture.packetPath, ~targetId="T-SYNTHETIC"),
  "REQUIREMENT_OMITTED",
)
B.writeText(B.Path(fixture.packetPath), original)

let rejectedJson = Js.Json.parseExn(original)
let rejectedRoot = rejectedJson->Js.Json.decodeObject->Belt.Option.getExn
let rejectedLedgers = Js.Dict.get(rejectedRoot, "decisionLedgers")
  ->Belt.Option.getExn
  ->Js.Json.decodeArray
  ->Belt.Option.getExn
let rejectedLedger = Belt.Array.getExn(rejectedLedgers, 1)->Js.Json.decodeObject->Belt.Option.getExn
let rejectedEvents = Js.Dict.get(rejectedLedger, "events")
  ->Belt.Option.getExn
  ->Js.Json.decodeArray
  ->Belt.Option.getExn
let rejectedEvent = Js.Dict.empty()
Js.Dict.set(rejectedEvent, "eventId", Js.Json.string("EV-BLOCKING-REJECT"))
Js.Dict.set(rejectedEvent, "sequence", Js.Json.number(4.0))
Js.Dict.set(rejectedEvent, "kind", Js.Json.string("reject"))
Js.Dict.set(rejectedEvent, "reason", Js.Json.string("synthetic rejection"))
Belt.Array.set(rejectedEvents, 1, Js.Json.object_(rejectedEvent))->ignore
B.writeText(
  B.Path(fixture.packetPath),
  Production_TestFixtures.sealDecisionEvents(Js.Json.stringify(rejectedJson)),
)
expectCode(
  "closed rejected authority",
  W.compile(~packetPath=fixture.packetPath, ~targetId="T-SYNTHETIC"),
  "DECISION_NOT_EFFECTIVE",
)
B.writeText(B.Path(fixture.packetPath), original)

Js.log("PASS - immutable typed work-order compiler and deterministic preflight findings")
