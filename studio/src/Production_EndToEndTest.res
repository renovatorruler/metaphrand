/* Public-API end-to-end acceptance matrix for the generic production control
   plane. Every input is synthetic and every adapter is an in-process fake.
   This test performs no network requests, process spawning, media work, story
   access, or mutation outside its fresh temporary fixture directories. */

module B = Cinema_Backends
module F = Production_TestFixtures
module D = Production_Domain
module W = Production_WorkOrder
module C = Production_Controller
module G = Production_Gateway
module S = Production_State
module I = Production_Inspection
module A = Production_ArtifactStore

let targetId = "T-SYNTHETIC"

let fail = message => {
  Js.Console.error("FAIL - " ++ message)
  assert(false)
}

let expect = (condition, message) =>
  if !condition {
    fail(message)
  }

let expectControllerFailure = (label, operation) => {
  let refused = try {
    operation()
    false
  } catch {
  | C.ControllerError(_) => true
  | _ => false
  }
  expect(refused, label ++ " must fail closed")
}

let isReady = reconciliation =>
  switch reconciliation.C.status {
  | C.ReadyForExecution => true
  | _ => false
  }

let stateFor = (fixture: F.fixture, selectedTargetId) =>
  S.load(~stateDir=fixture.stateDir).targets
  ->Belt.Array.getBy(row => row.targetId == selectedTargetId)
  ->Belt.Option.getExn

let storeFor = (fixture: F.fixture) =>
  A.openStore(~root=fixture.storeDir, ~reviewBatchSize=3)

let queueText = (fixture: F.fixture, name) =>
  B.readText(B.Path(fixture.stateDir ++ "/queues/" ++ name ++ ".json"))

let packetObject = (fixture: F.fixture) =>
  B.readText(B.Path(fixture.packetPath))
  ->Js.Json.parseExn
  ->Js.Json.decodeObject
  ->Belt.Option.getExn

let requiredArray = (object_, key) =>
  Js.Dict.get(object_, key)
  ->Belt.Option.flatMap(Js.Json.decodeArray)
  ->Belt.Option.getExn

let writeReboundPacket = (fixture: F.fixture, root) =>
  B.writeText(
    B.Path(fixture.packetPath),
    F.bindApprovals(Js.Json.stringifyWithSpace(Js.Json.object_(root), 2)) ++ "\n",
  )

let firstTarget = root =>
  requiredArray(root, "targets")
  ->Belt.Array.getExn(0)
  ->Js.Json.decodeObject
  ->Belt.Option.getExn

let fakeProvider = (fixture: F.fixture, calls: ref<int>, label): G.provider =>
  F.registerFakeProvider(
    ~fixture,
    ~adapterId="e2e-provider-" ++ label,
    ~submit=request => {
      calls := calls.contents + 1
      Ok({
        content: "synthetic candidate for " ++ request.workOrderHash ++ "\n",
        contentType: "application/x-synthetic-text",
        providerReceipt: "E2E-FAKE-RECEIPT-" ++ label,
      })
    },
  )

let fakeInspector = (~fixture: F.fixture, ~label, ~verdict): C.inspector => {
  let adapterId = "e2e-inspector-" ++ label
  C.registerInspector(
    ~packetPath=fixture.packetPath,
    ~adapterId,
    ~credentialText=F.inspectorCredential(
      ~adapterId,
      ~assertionId="E2E-ASSERT-INSPECTOR-" ++ label,
    ),
    ~inspect=request => {
      let report: I.report = {
        schema: "production.inspection-report/v1",
        workOrderHash: request.job.workOrderHash,
        artifactHash: request.job.artifactHash,
        policyHash: request.job.policyHash,
        inspectorId: "PR-INSPECTOR",
        results: request.job.checks->Belt.Array.map(check => ({
          checkId: check.id,
          verdict,
          confidence: verdict == I.Unknown ? 0.0 : 1.0,
          evidence: "synthetic evidence for " ++ check.id,
        }: I.result)),
      }
      Ok(I.encodeReport(report))
    },
  )
}

let authorizationCommand = (~fixture: F.fixture, ~provider, ~assertionId) =>
  F.executionCommandForBinding(
    ~bindingHash=C.executionAuthorizationBinding(
      ~packetPath=fixture.packetPath,
      ~stateDir=fixture.stateDir,
      ~targetId,
      ~provider,
    ),
    ~assertionId,
  )

type produced = {
  fixture: F.fixture,
  execution: G.execution,
  calls: ref<int>,
}

let produce = label => {
  let fixture = F.create()
  let calls = ref(0)
  let provider = fakeProvider(fixture, calls, label)
  let command = authorizationCommand(
    ~fixture,
    ~provider,
    ~assertionId="E2E-CMD-PRODUCE-" ++ label,
  )
  let execution = C.execute(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId,
    ~provider,
    ~authorizationCommandText=command,
  )
  expect(calls.contents == 1, label ++ " must make exactly one fake provider call")
  expect(
    stateFor(fixture, targetId).state == S.CandidateQuarantine,
    label ++ " must enter candidate quarantine before inspection",
  )
  {fixture, execution, calls}
}

let makeIncompletePacket = (fixture: F.fixture) => {
  let root = packetObject(fixture)
  Js.Dict.set(
    firstTarget(root),
    "requirementIds",
    Js.Json.array([
      Js.Json.string("R-CONTINUITY"),
      Js.Json.string("R-SCALE"),
      Js.Json.string("R-CAMERA"),
      Js.Json.string("R-COMPLEXITY"),
      Js.Json.string("R-REFERENCES"),
    ]),
  )
  writeReboundPacket(fixture, root)
}

let decisionEvent = (~sequence, ~kind, ~statement=?) => {
  let row = Js.Dict.empty()
  Js.Dict.set(row, "sequence", Js.Json.number(Belt.Int.toFloat(sequence)))
  Js.Dict.set(row, "kind", Js.Json.string(kind))
  switch statement {
  | Some(value) => Js.Dict.set(row, "statement", Js.Json.string(value))
  | None => ()
  }
  Js.Json.object_(row)
}

let makeContradictoryPacket = (fixture: F.fixture) => {
  let root = packetObject(fixture)
  let conflict = Js.Dict.empty()
  Js.Dict.set(conflict, "decisionId", Js.Json.string("D-CONFLICT"))
  Js.Dict.set(conflict, "scope", Js.Json.string("blocking.synthetic-target"))
  Js.Dict.set(conflict, "dependencies", Js.Json.array([Js.Json.string("D-FOUNDATION")]))
  Js.Dict.set(
    conflict,
    "events",
    Js.Json.array([
      decisionEvent(
        ~sequence=5,
        ~kind="propose",
        ~statement="Contradictory synthetic target contract",
      ),
      decisionEvent(~sequence=6, ~kind="approve"),
    ]),
  )
  let ledgers = requiredArray(root, "decisionLedgers")
  Js.Dict.set(
    root,
    "decisionLedgers",
    Js.Json.array(Belt.Array.concat(ledgers, [Js.Json.object_(conflict)])),
  )
  writeReboundPacket(fixture, root)
}

let changePurposeUnderNewAuthority = (fixture: F.fixture) => {
  let root = packetObject(fixture)
  Js.Dict.set(
    firstTarget(root),
    "purpose",
    Js.Json.string("Exercise a newly approved synthetic production lifecycle"),
  )
  writeReboundPacket(fixture, root)
}

let zeroCallsForBlockedIncompleteContradictoryStaleAndUnauthorized = () => {
  let blocked = F.create()
  let blockedCalls = ref(0)
  let blockedProvider = fakeProvider(blocked, blockedCalls, "blocked")
  B.writeText(B.Path(blocked.firstReferencePath), "synthetic changed reference bytes\n")
  let blockedResult = C.reconcile(
    ~packetPath=blocked.packetPath,
    ~stateDir=blocked.stateDir,
    ~targetId,
  )
  expect(
    blockedResult.status == C.ReconciliationBlocked &&
      blockedResult.blockers->Belt.Array.some(row => row.code == "ASSET_HASH_MISMATCH"),
    "changed reference bytes must block before execution",
  )
  expectControllerFailure("blocked work", () =>
    C.execute(
      ~packetPath=blocked.packetPath,
      ~stateDir=blocked.stateDir,
      ~targetId,
      ~provider=blockedProvider,
      ~authorizationCommandText="{}",
    )->ignore
  )
  expect(blockedCalls.contents == 0, "blocked work reached the fake provider")

  let incomplete = F.create()
  let incompleteCalls = ref(0)
  let incompleteProvider = fakeProvider(incomplete, incompleteCalls, "incomplete")
  makeIncompletePacket(incomplete)
  let incompleteResult = C.reconcile(
    ~packetPath=incomplete.packetPath,
    ~stateDir=incomplete.stateDir,
    ~targetId,
  )
  expect(
    incompleteResult.status == C.ReconciliationBlocked &&
      incompleteResult.blockers->Belt.Array.some(row => row.code == "SEMANTIC_CONTRACT_MISSING"),
    "incomplete acceptance contract must be identified before execution",
  )
  expectControllerFailure("incomplete work", () =>
    C.execute(
      ~packetPath=incomplete.packetPath,
      ~stateDir=incomplete.stateDir,
      ~targetId,
      ~provider=incompleteProvider,
      ~authorizationCommandText="{}",
    )->ignore
  )
  expect(incompleteCalls.contents == 0, "incomplete work reached the fake provider")

  let contradictory = F.create()
  let contradictoryCalls = ref(0)
  let contradictoryProvider = fakeProvider(contradictory, contradictoryCalls, "contradictory")
  makeContradictoryPacket(contradictory)
  let contradictoryResult = C.reconcile(
    ~packetPath=contradictory.packetPath,
    ~stateDir=contradictory.stateDir,
    ~targetId,
  )
  expect(
    contradictoryResult.status == C.ReconciliationBlocked &&
      contradictoryResult.blockers->Belt.Array.some(row => row.code == "DECISION_CONFLICT"),
    "contradictory approved decisions must be identified before execution",
  )
  expectControllerFailure("contradictory work", () =>
    C.execute(
      ~packetPath=contradictory.packetPath,
      ~stateDir=contradictory.stateDir,
      ~targetId,
      ~provider=contradictoryProvider,
      ~authorizationCommandText="{}",
    )->ignore
  )
  expect(contradictoryCalls.contents == 0, "contradictory work reached the fake provider")

  let stale = F.create()
  let staleCalls = ref(0)
  let staleProvider = fakeProvider(stale, staleCalls, "stale-command")
  let staleCommand = authorizationCommand(
    ~fixture=stale,
    ~provider=staleProvider,
    ~assertionId="E2E-CMD-STALE-AUTHORITY",
  )
  changePurposeUnderNewAuthority(stale)
  expectControllerFailure("stale signed authority", () =>
    C.execute(
      ~packetPath=stale.packetPath,
      ~stateDir=stale.stateDir,
      ~targetId,
      ~provider=staleProvider,
      ~authorizationCommandText=staleCommand,
    )->ignore
  )
  expect(staleCalls.contents == 0, "stale signed authority reached the fake provider")

  let unauthorized = F.create()
  let unauthorizedCalls = ref(0)
  let unauthorizedProvider = fakeProvider(unauthorized, unauthorizedCalls, "unauthorized")
  expectControllerFailure("unsigned execution", () =>
    C.execute(
      ~packetPath=unauthorized.packetPath,
      ~stateDir=unauthorized.stateDir,
      ~targetId,
      ~provider=unauthorizedProvider,
      ~authorizationCommandText="{}",
    )->ignore
  )
  expect(unauthorizedCalls.contents == 0, "unauthorized work reached the fake provider")

  Js.log("ok - blocked, incomplete, contradictory, stale, and unauthorized work made zero calls")
}

let postCallAuthorityDriftIsPreservedAsStaleQuarantine = () => {
  let fixture = F.create()
  let calls = ref(0)
  let provider = F.registerFakeProvider(
    ~fixture,
    ~adapterId="e2e-provider-post-call-drift",
    ~submit=request => {
      calls := calls.contents + 1
      B.writeText(
        B.Path(fixture.firstReferencePath),
        "synthetic authority changed while the fake provider was running\n",
      )
      Ok({
        content: "synthetic output from stale authority " ++ request.workOrderHash ++ "\n",
        contentType: "application/x-synthetic-text",
        providerReceipt: "E2E-FAKE-RECEIPT-POST-CALL-DRIFT",
      })
    },
  )
  let command = authorizationCommand(
    ~fixture,
    ~provider,
    ~assertionId="E2E-CMD-POST-CALL-DRIFT",
  )
  let execution = C.execute(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId,
    ~provider,
    ~authorizationCommandText=command,
  )
  expect(calls.contents == 1, "post-call drift scenario must make one fake provider call")
  expect(execution.quarantinedStale, "post-call authority drift must mark execution stale")
  expect(
    stateFor(fixture, targetId).state == S.Superseded,
    "post-call authority drift must terminate obsolete lifecycle authority",
  )
  let store = storeFor(fixture)
  let candidates = A.listCandidates(store)
  expect(candidates->Belt.Array.length == 1, "stale output bytes must remain in the artifact ledger")
  expect(
    candidates[0].candidateHash == execution.candidate.candidateHash &&
      B.exists(B.Path(candidates[0].objectPath)),
    "preserved stale output must retain its exact content-addressed identity",
  )
  expect(
    A.listDispositions(store)->Belt.Array.some(row =>
      row.candidateHash == execution.candidate.candidateHash && row.kind == A.Stale
    ),
    "post-call drift must add an immutable stale disposition",
  )
  expect(
    A.createReviewBatch(
      ~store,
      ~targetId,
      ~packetHash=execution.candidate.packetHash,
      ~workOrderHash=execution.candidate.workOrderHash,
    ) == None,
    "stale-quarantined output must never enter review",
  )
  Js.log("ok - post-call authority drift preserves and stale-quarantines output")
}

let inspect = (~produced: produced, ~label, ~verdict) =>
  C.inspectCandidate(
    ~packetPath=produced.fixture.packetPath,
    ~stateDir=produced.fixture.stateDir,
    ~targetId,
    ~candidateHash=produced.execution.candidate.candidateHash,
    ~inspector=fakeInspector(~fixture=produced.fixture, ~label, ~verdict),
  )

let semanticPassFailUnknownFailClosed = () => {
  let passed = produce("semantic-pass")
  let passResult = inspect(~produced=passed, ~label="pass", ~verdict=I.Pass)
  expect(passResult.adjudication.outcome == I.ReviewReady, "PASS must adjudicate review-ready")
  expect(
    stateFor(passed.fixture, targetId).state == S.ReviewReady,
    "PASS must create review-ready lifecycle evidence, not approval",
  )
  let passBatch = C.createReviewBatch(
    ~packetPath=passed.fixture.packetPath,
    ~stateDir=passed.fixture.stateDir,
    ~targetId,
  )->Belt.Option.getExn
  expect(passBatch.entries->Belt.Array.length == 1, "eligible PASS candidate must enter one batch")
  expect(
    A.listReviews(storeFor(passed.fixture))->Belt.Array.length == 0,
    "inspector PASS evidence must not approve the candidate",
  )

  let failed = produce("semantic-fail")
  let failResult = inspect(~produced=failed, ~label="fail", ~verdict=I.Fail)
  expect(failResult.adjudication.outcome == I.Quarantine, "FAIL must adjudicate quarantine")
  expect(failResult.lifecycleEvent == None, "FAIL must not promote lifecycle state")
  expect(
    A.listDispositions(storeFor(failed.fixture))->Belt.Array.some(row =>
      row.candidateHash == failed.execution.candidate.candidateHash && row.kind == A.Quarantined
    ),
    "FAIL must preserve a quarantine disposition",
  )
  expect(
    C.createReviewBatch(
      ~packetPath=failed.fixture.packetPath,
      ~stateDir=failed.fixture.stateDir,
      ~targetId,
    ) == None,
    "FAIL candidate must not enter review",
  )

  let unknown = produce("semantic-unknown")
  let unknownResult = inspect(~produced=unknown, ~label="unknown", ~verdict=I.Unknown)
  expect(
    unknownResult.adjudication.outcome == I.HumanRequired,
    "UNKNOWN must remain explicit and require additional evidence",
  )
  expect(
    stateFor(unknown.fixture, targetId).state == S.Unknown,
    "UNKNOWN must be durable rather than silently treated as PASS",
  )
  expect(
    C.createReviewBatch(
      ~packetPath=unknown.fixture.packetPath,
      ~stateDir=unknown.fixture.stateDir,
      ~targetId,
    ) == None,
    "UNKNOWN candidate must not enter review",
  )
  expect(
    passed.calls.contents + failed.calls.contents + unknown.calls.contents == 3,
    "semantic inspection must not create additional provider calls",
  )
  Js.log("ok - semantic PASS, FAIL, and UNKNOWN outcomes fail closed and batch only PASS")
}

let rejectedOutputRemainsPreservedAndExcluded = () => {
  let produced = produce("human-rejection")
  inspect(~produced, ~label="pass-before-rejection", ~verdict=I.Pass)->ignore
  let batch = C.createReviewBatch(
    ~packetPath=produced.fixture.packetPath,
    ~stateDir=produced.fixture.stateDir,
    ~targetId,
  )->Belt.Option.getExn
  let answers: array<C.humanAnswer> = [{
    requirementId: "R-CAMERA",
    verdict: C.HumanFail,
    evidence: "Synthetic protected side is not sufficiently clear",
  }]
  let note = "Reject the synthetic candidate for the recorded human-only failure"
  let binding = C.reviewCommandBinding(
    ~packetPath=produced.fixture.packetPath,
    ~stateDir=produced.fixture.stateDir,
    ~targetId,
    ~batchHash=batch.batchHash,
    ~candidateHash=produced.execution.candidate.candidateHash,
    ~decision=A.Reject,
    ~answers,
    ~note,
  )
  let rejected = C.recordHumanReview(
    ~packetPath=produced.fixture.packetPath,
    ~stateDir=produced.fixture.stateDir,
    ~targetId,
    ~batchHash=batch.batchHash,
    ~candidateHash=produced.execution.candidate.candidateHash,
    ~commandText=F.reviewCommandForBinding(
      ~bindingHash=binding,
      ~assertionId="E2E-CMD-HUMAN-REJECT",
    ),
    ~decision=A.Reject,
    ~answers,
    ~note,
  )
  expect(rejected.lifecycleEvent.state == S.Rejected, "human rejection must be durable")
  let beforeReconcile = S.load(~stateDir=produced.fixture.stateDir)
  let store = storeFor(produced.fixture)
  let candidates = A.listCandidates(store)
  expect(candidates->Belt.Array.length == 1, "rejection must not delete historical candidate bytes")
  expect(
    candidates[0].candidateHash == produced.execution.candidate.candidateHash &&
      B.exists(B.Path(candidates[0].objectPath)),
    "rejected candidate must retain its content-addressed object",
  )
  expect(
    A.listDispositions(store)->Belt.Array.some(row =>
      row.candidateHash == produced.execution.candidate.candidateHash && row.kind == A.Rejected
    ),
    "rejected candidate must retain its exclusion disposition",
  )
  expect(
    A.listReviews(store)->Belt.Array.some(row =>
      row.candidateHash == produced.execution.candidate.candidateHash && row.decision == A.Reject
    ),
    "rejected candidate must retain its substantive review record",
  )
  let unchanged = C.reconcile(
    ~packetPath=produced.fixture.packetPath,
    ~stateDir=produced.fixture.stateDir,
    ~targetId,
  )
  expect(
    unchanged.status == C.LifecycleCurrent(S.Rejected),
    "unchanged reconciliation must preserve rejection",
  )
  expect(
    S.load(~stateDir=produced.fixture.stateDir).events->Belt.Array.length ==
      beforeReconcile.events->Belt.Array.length,
    "unchanged rejection reconciliation must append no lifecycle event",
  )
  expect(
    C.createReviewBatch(
      ~packetPath=produced.fixture.packetPath,
      ~stateDir=produced.fixture.stateDir,
      ~targetId,
    ) == None,
    "rejected candidate must remain excluded from later review batches",
  )
  let retryCalls = ref(0)
  let retryProvider = fakeProvider(produced.fixture, retryCalls, "rejected-retry")
  expectControllerFailure("execution after unchanged rejection", () =>
    C.execute(
      ~packetPath=produced.fixture.packetPath,
      ~stateDir=produced.fixture.stateDir,
      ~targetId,
      ~provider=retryProvider,
      ~authorizationCommandText="{}",
    )->ignore
  )
  expect(retryCalls.contents == 0, "rejected target retry reached the fake provider")
  Js.log("ok - rejected output remains preserved and excluded after unchanged reconciliation")
}

let cloneDependencyIntoPacket = (fixture: F.fixture) => {
  let root = packetObject(fixture)
  let targets = requiredArray(root, "targets")
  let requirements = requiredArray(root, "requirements")
  let mainTarget = targets
  ->Belt.Array.getExn(0)
  ->Js.Json.decodeObject
  ->Belt.Option.getExn
  let dependencyTarget = Js.Json.stringify(Js.Json.object_(mainTarget))
  ->Js.String2.replaceByRe(%re("/T-SYNTHETIC/g"), "T-DEPENDENCY")
  ->Js.String2.replaceByRe(%re("/R-/g"), "RD-")
  ->Js.Json.parseExn
  Js.Dict.set(
    mainTarget,
    "dependsOnTargetIds",
    Js.Json.array([Js.Json.string("T-DEPENDENCY")]),
  )
  let dependencyRequirements = requirements->Belt.Array.map(requirement =>
    Js.Json.stringify(requirement)
    ->Js.String2.replaceByRe(%re("/T-SYNTHETIC/g"), "T-DEPENDENCY")
    ->Js.String2.replaceByRe(%re("/R-/g"), "RD-")
    ->Js.Json.parseExn
  )
  Js.Dict.set(root, "targets", Js.Json.array(Belt.Array.concat(targets, [dependencyTarget])))
  Js.Dict.set(
    root,
    "requirements",
    Js.Json.array(Belt.Array.concat(requirements, dependencyRequirements)),
  )
  writeReboundPacket(fixture, root)
}

let approveDependency = (fixture: F.fixture) => {
  let reconciliation = C.reconcile(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId="T-DEPENDENCY",
  )
  expect(isReady(reconciliation), "synthetic dependency must reconcile ready")
  let order = reconciliation.workOrder->Belt.Option.getExn
  let artifactHash = B.sha256Text("synthetic dependency artifact")
  let inspectionHash = B.sha256Text("synthetic dependency inspection")
  let reviewHash = B.sha256Text("synthetic dependency human review")
  S.append(
    ~stateDir=fixture.stateDir,
    ~targetId="T-DEPENDENCY",
    ~state=S.Authorized,
    ~actor=S.Human,
    ~packetHash=order.packetHash,
    ~workOrderHash=order.hash,
    ~reason="synthetic dependency authorized",
  )->ignore
  S.append(
    ~stateDir=fixture.stateDir,
    ~targetId="T-DEPENDENCY",
    ~state=S.CandidateQuarantine,
    ~actor=S.Provider,
    ~packetHash=order.packetHash,
    ~workOrderHash=order.hash,
    ~artifactHash,
    ~reason="synthetic dependency candidate quarantined",
  )->ignore
  S.append(
    ~stateDir=fixture.stateDir,
    ~targetId="T-DEPENDENCY",
    ~state=S.ReviewReady,
    ~actor=S.System,
    ~packetHash=order.packetHash,
    ~workOrderHash=order.hash,
    ~artifactHash,
    ~reportHash=inspectionHash,
    ~reason="synthetic dependency passed independent inspection",
  )->ignore
  S.append(
    ~stateDir=fixture.stateDir,
    ~targetId="T-DEPENDENCY",
    ~state=S.Approved,
    ~actor=S.Human,
    ~packetHash=order.packetHash,
    ~workOrderHash=order.hash,
    ~artifactHash,
    ~reportHash=reviewHash,
    ~reason="synthetic dependency approved",
  )->ignore
}

let dependencyInvalidationBlocksWithoutProviderCall = () => {
  let fixture = F.create()
  cloneDependencyIntoPacket(fixture)
  approveDependency(fixture)
  let dependent = C.reconcile(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId,
  )
  expect(isReady(dependent), "approved exact dependency must permit dependent work")
  let calls = ref(0)
  let provider = fakeProvider(fixture, calls, "dependency-invalidated")
  let command = authorizationCommand(
    ~fixture,
    ~provider,
    ~assertionId="E2E-CMD-DEPENDENCY-INVALIDATED",
  )
  S.append(
    ~stateDir=fixture.stateDir,
    ~targetId="T-DEPENDENCY",
    ~state=S.Superseded,
    ~actor=S.System,
    ~reason="synthetic dependency invalidated after downstream authorization binding",
  )->ignore
  expectControllerFailure("invalidated dependency", () =>
    C.execute(
      ~packetPath=fixture.packetPath,
      ~stateDir=fixture.stateDir,
      ~targetId,
      ~provider,
      ~authorizationCommandText=command,
    )->ignore
  )
  let blocked = C.reconcile(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId,
  )
  expect(
    blocked.status == C.ReconciliationBlocked &&
      blocked.blockers->Belt.Array.some(row => row.code == "DEPENDENCY_NOT_APPROVED"),
    "dependency invalidation must durably block the dependent target",
  )
  expect(calls.contents == 0, "invalidated dependency reached the fake provider")
  expect(
    Js.String2.includes(queueText(fixture, "blocked"), "DEPENDENCY_NOT_APPROVED"),
    "dependency invalidation must update the deterministic blocked queue",
  )
  Js.log("ok - dependency invalidation blocks downstream work with zero calls")
}

let deterministicRestartAndContextRehydration = () => {
  let fixture = F.create()
  let calls = ref(0)
  let provider = fakeProvider(fixture, calls, "restart-rehydration")
  let first = C.reconcile(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId,
  )
  expect(isReady(first), "restart fixture must initially reconcile ready")
  let firstOrder = first.workOrder->Belt.Option.getExn
  let packetRaw = B.readText(B.Path(fixture.packetPath))
  let firstContext = D.reconstruct(packetRaw)
  let firstSnapshot = S.load(~stateDir=fixture.stateDir)
  let firstEvents = S.encodeEvents(firstSnapshot.events)
  let firstCurrent = B.readText(B.Path(fixture.stateDir ++ "/current.json"))
  let firstReadyQueue = queueText(fixture, "ready")
  let firstBlockedQueue = queueText(fixture, "blocked")
  let firstBinding = C.executionAuthorizationBinding(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId,
    ~provider,
  )

  B.writeText(B.Path(fixture.stateDir ++ "/current.json"), "corrupt disposable materialized view\n")
  B.writeText(B.Path(fixture.stateDir ++ "/queues/ready.json"), "corrupt disposable queue\n")
  B.writeText(B.Path(fixture.stateDir ++ "/queues/blocked.json"), "corrupt disposable queue\n")

  let rehydratedSnapshot = S.load(~stateDir=fixture.stateDir)
  expect(
    S.encodeEvents(rehydratedSnapshot.events) == firstEvents,
    "append-only event files must reconstruct identical lifecycle state",
  )
  S.writeMaterialized(~stateDir=fixture.stateDir, ~snapshot=rehydratedSnapshot)
  expect(
    B.readText(B.Path(fixture.stateDir ++ "/current.json")) == firstCurrent,
    "materialized current state must be reproducible exactly from immutable events",
  )
  let second = C.reconcile(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId,
  )
  expect(isReady(second), "rehydrated lifecycle must remain ready")
  expect(second.eventIds->Belt.Array.length == 0, "restart reconciliation must append no duplicate event")
  let secondOrder = second.workOrder->Belt.Option.getExn
  let secondContext = D.reconstruct(B.readText(B.Path(fixture.packetPath)))
  let secondBinding = C.executionAuthorizationBinding(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId,
    ~provider,
  )
  expect(
    secondContext.canonicalHash == firstContext.canonicalHash &&
      secondContext.effectiveDecisionIds->Js.Array2.joinWith("\n") ==
        firstContext.effectiveDecisionIds->Js.Array2.joinWith("\n"),
    "packet authority must reconstruct identically without conversation history",
  )
  expect(
    secondOrder.hash == firstOrder.hash && secondOrder.canonical == firstOrder.canonical,
    "typed work order must recompile byte-identically after restart",
  )
  expect(firstBinding == secondBinding, "execution authorization binding must be deterministic after restart")
  expect(queueText(fixture, "ready") == firstReadyQueue, "ready queue must rehydrate byte-identically")
  expect(
    queueText(fixture, "blocked") == firstBlockedQueue,
    "blocked queue must rehydrate byte-identically",
  )
  expect(calls.contents == 0, "context rehydration must never invoke the fake provider")
  Js.log("ok - restart reconstructs context, lifecycle, work order, queues, and binding deterministically")
}

zeroCallsForBlockedIncompleteContradictoryStaleAndUnauthorized()
postCallAuthorityDriftIsPreservedAsStaleQuarantine()
semanticPassFailUnknownFailClosed()
rejectedOutputRemainsPreservedAndExcluded()
dependencyInvalidationBlocksWithoutProviderCall()
deterministicRestartAndContextRehydration()

Js.log("PASS - production control public-API end-to-end acceptance matrix")
