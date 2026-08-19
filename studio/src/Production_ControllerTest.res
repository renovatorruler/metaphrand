/* Synthetic, zero-network contract tests for the generic production
   controller. Fake providers return plain text octets; fake inspectors return
   structured reports. No story, media, or live provider is referenced. */

module B = Cinema_Backends
module F = Production_TestFixtures
module C = Production_Controller
module W = Production_WorkOrder
module S = Production_State
module G = Production_Gateway
module P = Production_Preflight
module I = Production_Inspection
module A = Production_ArtifactStore

let fail = message => {
  Js.Console.error("FAIL - " ++ message)
  assert(false)
}

let check = (condition, message) =>
  if !condition {
    fail(message)
  }

let expectControllerFailure = (label, operation) => {
  let failed = try {
    operation()
    false
  } catch {
  | C.ControllerError(_) => true
  | _ => false
  }
  check(failed, label ++ " should fail closed")
}

let ready = reconciliation =>
  switch reconciliation.C.status {
  | C.ReadyForExecution => true
  | _ => false
  }

let stateFor = (fixture: F.fixture, targetId) =>
  S.load(~stateDir=fixture.stateDir).targets
  ->Belt.Array.getBy(row => row.targetId == targetId)
  ->Belt.Option.getExn

let queueRaw = (fixture: F.fixture, name) =>
  B.readText(B.Path(fixture.stateDir ++ "/queues/" ++ name ++ ".json"))

let queueEntries = (fixture: F.fixture, name) =>
  queueRaw(fixture, name)
  ->Js.Json.parseExn
  ->Js.Json.decodeObject
  ->Belt.Option.getExn
  ->Js.Dict.get("entries")
  ->Belt.Option.flatMap(Js.Json.decodeArray)
  ->Belt.Option.getExn

let queueObject = (fixture: F.fixture, name) =>
  queueRaw(fixture, name)
  ->Js.Json.parseExn
  ->Js.Json.decodeObject
  ->Belt.Option.getExn

let queueLifecycleCount = (fixture: F.fixture, name) =>
  queueObject(fixture, name)
  ->Js.Dict.get("lifecycleEventCount")
  ->Belt.Option.flatMap(Js.Json.decodeNumber)
  ->Belt.Option.map(Js.Math.floor_int)
  ->Belt.Option.getExn

let queueLifecycleHead = (fixture: F.fixture, name) =>
  queueObject(fixture, name)
  ->Js.Dict.get("lifecycleHeadEventId")
  ->Belt.Option.flatMap(Js.Json.decodeString)
  ->Belt.Option.getExn

let checkQueueAuthority = (fixture: F.fixture, name) => {
  let snapshot = S.load(~stateDir=fixture.stateDir)
  let head = Belt.Array.getExn(snapshot.events, Belt.Array.length(snapshot.events) - 1)
  check(
    queueLifecycleCount(fixture, name) == Belt.Array.length(snapshot.events) &&
    queueLifecycleHead(fixture, name) == head.id,
    name ++ " queue must bind the newest anchored lifecycle snapshot",
  )
}

let queueHasTarget = (fixture: F.fixture, name, targetId) =>
  queueEntries(fixture, name)->Belt.Array.some(value => {
    let row = value->Js.Json.decodeObject->Belt.Option.getExn
    Js.Dict.get(row, "targetId")->Belt.Option.flatMap(Js.Json.decodeString) == Some(targetId)
  })

let fakeProvider = (fixture: F.fixture, calls: ref<int>, label): G.provider =>
  F.registerFakeProvider(
    ~fixture,
    ~adapterId="fake-provider-" ++ label,
    ~submit=request => {
    calls := calls.contents + 1
    Ok({
      content: "synthetic candidate for " ++ request.workOrderHash,
      contentType: "text/plain",
      providerReceipt: "fake-receipt-" ++ label,
    })
  })

let fakeInspector = (~fixture: F.fixture, ~id, ~verdict): C.inspector =>
  C.registerInspector(
    ~packetPath=fixture.packetPath,
    ~adapterId=id,
    ~credentialText=F.inspectorCredential(
      ~adapterId=id,
      ~assertionId="ASSERT-INSPECTOR-" ++ id,
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
  })

let authorizationCommand = (~fixture: F.fixture, ~provider, ~assertionId) =>
  F.executionCommandForBinding(
    ~bindingHash=C.executionAuthorizationBinding(
      ~packetPath=fixture.packetPath,
      ~stateDir=fixture.stateDir,
      ~targetId="T-SYNTHETIC",
      ~provider,
    ),
    ~assertionId,
  )

type produced = {fixture: F.fixture, execution: G.execution}

let produce = label => {
  let fixture = F.create()
  let calls = ref(0)
  let provider = fakeProvider(fixture, calls, label)
  let execution = C.execute(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId="T-SYNTHETIC",
    ~provider,
    ~authorizationCommandText=authorizationCommand(
      ~fixture,
      ~provider,
      ~assertionId="CMD-PRODUCE-" ++ label,
    ),
  )
  check(calls.contents == 1, "fake provider must be called exactly once")
  check(
    stateFor(fixture, "T-SYNTHETIC").state == S.CandidateQuarantine,
    "provider output must enter candidate quarantine",
  )
  {fixture, execution}
}

let reconcileIdempotentlyAndInvalidateDiskDrift = () => {
  let fixture = F.create()
  let first = C.reconcile(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId="T-SYNTHETIC",
  )
  check(ready(first), "clean synthetic packet must reconcile ready")
  check(first.eventIds->Belt.Array.length == 3, "first reconcile must lock, compile, and ready")
  let firstExplanation = C.explain(first)
  check(Js.String2.startsWith(firstExplanation, "READY T-SYNTHETIC"), "ready status must be plain")
  let count = S.load(~stateDir=fixture.stateDir).events->Belt.Array.length
  check(queueHasTarget(fixture, "ready", "T-SYNTHETIC"), "ready queue must be materialized")
  check(queueEntries(fixture, "blocked")->Belt.Array.length == 0, "clean target must not be blocked")
  checkQueueAuthority(fixture, "ready")
  checkQueueAuthority(fixture, "blocked")
  let initialReadyQueue = queueRaw(fixture, "ready")
  let initialBlockedQueue = queueRaw(fixture, "blocked")
  let repeat = C.reconcile(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId="T-SYNTHETIC",
  )
  check(ready(repeat), "exact repeat must remain ready")
  check(repeat.eventIds->Belt.Array.length == 0, "exact repeat must not append duplicate events")
  check(
    S.load(~stateDir=fixture.stateDir).events->Belt.Array.length == count,
    "idempotent reconcile must preserve ledger length",
  )
  check(queueRaw(fixture, "ready") == initialReadyQueue, "restart-safe ready queue must be deterministic")
  check(queueRaw(fixture, "blocked") == initialBlockedQueue, "restart-safe blocked queue must be deterministic")

  B.writeText(B.Path(fixture.firstReferencePath), "synthetic reference drift\n")
  let blocked = C.reconcile(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId="T-SYNTHETIC",
  )
  check(blocked.status == C.ReconciliationBlocked, "changed reference bytes must block")
  check(
    blocked.blockers->Belt.Array.some(row => row.code == "ASSET_HASH_MISMATCH"),
    "blocker must identify changed reference bytes",
  )
  let explanation = C.explain(blocked)
  check(Js.String2.includes(explanation, "BLK-"), "plain blocker report must expose stable IDs")
  check(queueEntries(fixture, "ready")->Belt.Array.length == 0, "blocked change must remove ready entry")
  check(queueHasTarget(fixture, "blocked", "T-SYNTHETIC"), "blocker queue must contain target")
  checkQueueAuthority(fixture, "ready")
  checkQueueAuthority(fixture, "blocked")
  let firstBlockerId = Belt.Array.getExn(blocked.blockers, 0).id
  check(
    Js.String2.includes(queueRaw(fixture, "blocked"), firstBlockerId),
    "blocked queue must contain the same stable blocker ID",
  )
  let blockedQueue = queueRaw(fixture, "blocked")
  let blockedAgain = C.reconcile(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId="T-SYNTHETIC",
  )
  check(
    C.explain(blockedAgain) == explanation,
    "unchanged blocking evidence must produce the same IDs and explanation",
  )
  check(blockedAgain.eventIds->Belt.Array.length == 0, "unchanged block must be idempotent")
  check(queueRaw(fixture, "blocked") == blockedQueue, "unchanged blocker queue bytes must be stable")

  B.writeText(B.Path(fixture.firstReferencePath), "synthetic subject reference\n")
  let restored = C.reconcile(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId="T-SYNTHETIC",
  )
  check(ready(restored), "restored exact reference must clear blocker")
  check(queueHasTarget(fixture, "ready", "T-SYNTHETIC"), "cleared target must return to ready queue")
  check(queueEntries(fixture, "blocked")->Belt.Array.length == 0, "cleared target must leave blocked queue")
  checkQueueAuthority(fixture, "ready")
  checkQueueAuthority(fixture, "blocked")
  Js.log("ok - deterministic reconcile, stable blocker IDs, and disk-drift invalidation")
}

let explicitAuthorizationAndApprovalFlow = () => {
  let fixture = F.create()
  let calls = ref(0)
  let provider = fakeProvider(fixture, calls, "authorization")
  expectControllerFailure("missing signed authorization command", () => {
    let _ = C.execute(
      ~packetPath=fixture.packetPath,
      ~stateDir=fixture.stateDir,
      ~targetId="T-SYNTHETIC",
      ~provider,
      ~authorizationCommandText="{}",
    )
  })
  check(calls.contents == 0, "failed authorization must make zero provider calls")
  check(
    stateFor(fixture, "T-SYNTHETIC").state == S.Ready,
    "failed authorization must leave target ready",
  )
  let execution = C.execute(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId="T-SYNTHETIC",
    ~provider,
    ~authorizationCommandText=authorizationCommand(
      ~fixture,
      ~provider,
      ~assertionId="CMD-CONTROLLER-AUTHORIZATION",
    ),
  )
  check(calls.contents == 1, "authorized execution must call fake provider once")
  check(
    queueEntries(fixture, "ready")->Belt.Array.length == 0,
    "candidate quarantine must be removed from the ready queue",
  )

  expectControllerFailure("producer credential cannot register as inspector", () =>
    C.registerInspector(
      ~packetPath=fixture.packetPath,
      ~adapterId="producer-as-inspector",
      ~credentialText=F.signedAssertion(
        ~assertionId="ASSERT-PRODUCER-AS-INSPECTOR",
        ~principalId="PR-PRODUCER",
        ~role="producer",
        ~action="register_inspector_adapter",
        ~bindingHash=Production_Credentials.bindingHash([
          "inspector_adapter",
          "producer-as-inspector",
        ]),
      ),
      ~inspect=_ => Error("must not register"),
    )->ignore
  )
  let storeBeforeIndependentInspection = A.openStore(~root=fixture.storeDir, ~reviewBatchSize=3)
  check(
    A.listInspections(storeBeforeIndependentInspection)->Belt.Array.length == 0,
    "producer identity must not create independent inspection evidence",
  )

  let inspector = fakeInspector(~fixture, ~id="fake-pass-inspector", ~verdict=I.Pass)
  let inspected = C.inspectCandidate(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId="T-SYNTHETIC",
    ~candidateHash=execution.candidate.candidateHash,
    ~inspector,
  )
  check(inspected.adjudication.outcome == I.ReviewReady, "PASS evidence must adjudicate review-ready")
  check(
    stateFor(fixture, "T-SYNTHETIC").state == S.ReviewReady,
    "PASS evidence must enter review_ready lifecycle",
  )
  let batch = C.createReviewBatch(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId="T-SYNTHETIC",
  )->Belt.Option.getExn
  check(batch.entries->Belt.Array.length == 1, "one eligible candidate must form one review entry")

  expectControllerFailure("missing substantive human acceptance answers", () => {
    let _ = C.recordHumanReview(
      ~packetPath=fixture.packetPath,
      ~stateDir=fixture.stateDir,
      ~targetId="T-SYNTHETIC",
      ~batchHash=batch.batchHash,
      ~candidateHash=execution.candidate.candidateHash,
      ~commandText="{}",
      ~decision=A.Approve,
      ~answers=[],
      ~note="Synthetic review cannot skip human-only questions",
    )
  })
  let approvalAnswers: array<C.humanAnswer> = [{
    requirementId: "R-CAMERA",
    verdict: C.HumanPass,
    evidence: "Synthetic protected camera side is legible",
  }]
  let approvalNote = "Synthetic candidate satisfies the human-only framing judgment"
  let approvalBinding = C.reviewCommandBinding(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId="T-SYNTHETIC",
    ~batchHash=batch.batchHash,
    ~candidateHash=execution.candidate.candidateHash,
    ~decision=A.Approve,
    ~answers=approvalAnswers,
    ~note=approvalNote,
  )
  let reviewed = C.recordHumanReview(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId="T-SYNTHETIC",
    ~batchHash=batch.batchHash,
    ~candidateHash=execution.candidate.candidateHash,
    ~commandText=F.reviewCommandForBinding(
      ~bindingHash=approvalBinding,
      ~assertionId="CMD-APPROVE-SYNTHETIC",
    ),
    ~decision=A.Approve,
    ~answers=approvalAnswers,
    ~note=approvalNote,
  )
  check(reviewed.lifecycleEvent.state == S.Approved, "substantive approval must be durable")
  check(
    reviewed.record.reportHashes->Belt.Array.length == 1,
    "approval must bind exact independent inspection evidence",
  )
  Js.log("ok - explicit gateway authorization, independent PASS, batch, and human approval")
}

let failAndUnknownRemainOutOfReview = () => {
  let failed = produce("semantic-fail")
  let failResult = C.inspectCandidate(
    ~packetPath=failed.fixture.packetPath,
    ~stateDir=failed.fixture.stateDir,
    ~targetId="T-SYNTHETIC",
    ~candidateHash=failed.execution.candidate.candidateHash,
    ~inspector=fakeInspector(~fixture=failed.fixture, ~id="fake-fail-inspector", ~verdict=I.Fail),
  )
  check(failResult.adjudication.outcome == I.Quarantine, "FAIL must adjudicate quarantine")
  check(failResult.lifecycleEvent == None, "FAIL must not mint a promotion lifecycle event")
  let failStore = A.openStore(~root=failed.fixture.storeDir, ~reviewBatchSize=3)
  check(A.listDispositions(failStore)->Belt.Array.length == 1, "FAIL must record quarantine disposition")
  check(
    C.createReviewBatch(
      ~packetPath=failed.fixture.packetPath,
      ~stateDir=failed.fixture.stateDir,
      ~targetId="T-SYNTHETIC",
    ) == None,
    "failed candidate must not enter review batch",
  )

  let unknown = produce("semantic-unknown")
  let unknownResult = C.inspectCandidate(
    ~packetPath=unknown.fixture.packetPath,
    ~stateDir=unknown.fixture.stateDir,
    ~targetId="T-SYNTHETIC",
    ~candidateHash=unknown.execution.candidate.candidateHash,
    ~inspector=fakeInspector(
      ~fixture=unknown.fixture,
      ~id="fake-unknown-inspector",
      ~verdict=I.Unknown,
    ),
  )
  check(unknownResult.adjudication.outcome == I.HumanRequired, "UNKNOWN must require human evidence")
  check(
    stateFor(unknown.fixture, "T-SYNTHETIC").state == S.Unknown,
    "UNKNOWN must be explicit in lifecycle state",
  )
  check(
    C.createReviewBatch(
      ~packetPath=unknown.fixture.packetPath,
      ~stateDir=unknown.fixture.stateDir,
      ~targetId="T-SYNTHETIC",
    ) == None,
    "unknown candidate must not enter review batch",
  )

  let malformed = produce("malformed-inspection")
  let badInspector = C.registerInspector(
    ~packetPath=malformed.fixture.packetPath,
    ~adapterId="fake-malformed-inspector",
    ~credentialText=F.inspectorCredential(
      ~adapterId="fake-malformed-inspector",
      ~assertionId="ASSERT-MALFORMED-INSPECTOR",
    ),
    ~inspect=request => Ok(`{
      "schema":"production.inspection-report/v1",
      "workOrderHash":"${request.job.workOrderHash}",
      "artifactHash":"${request.job.artifactHash}",
      "policyHash":"${request.job.policyHash}",
      "inspectorId":"PR-INSPECTOR",
      "results":[]
    }`),
  )
  expectControllerFailure("incomplete inspection report", () => {
    let _ = C.inspectCandidate(
      ~packetPath=malformed.fixture.packetPath,
      ~stateDir=malformed.fixture.stateDir,
      ~targetId="T-SYNTHETIC",
      ~candidateHash=malformed.execution.candidate.candidateHash,
      ~inspector=badInspector,
    )
  })
  check(
    stateFor(malformed.fixture, "T-SYNTHETIC").state == S.CandidateQuarantine,
    "malformed report must leave candidate quarantined",
  )
  Js.log("ok - FAIL, UNKNOWN, and malformed inspection evidence all fail closed")
}

let rejectFlow = () => {
  let produced = produce("human-reject")
  let _ = C.inspectCandidate(
    ~packetPath=produced.fixture.packetPath,
    ~stateDir=produced.fixture.stateDir,
    ~targetId="T-SYNTHETIC",
    ~candidateHash=produced.execution.candidate.candidateHash,
    ~inspector=fakeInspector(
      ~fixture=produced.fixture,
      ~id="fake-pass-before-reject",
      ~verdict=I.Pass,
    ),
  )
  let batch = C.createReviewBatch(
    ~packetPath=produced.fixture.packetPath,
    ~stateDir=produced.fixture.stateDir,
    ~targetId="T-SYNTHETIC",
  )->Belt.Option.getExn
  let rejectionAnswers: array<C.humanAnswer> = [{
    requirementId: "R-CAMERA",
    verdict: C.HumanFail,
    evidence: "Synthetic protected side is not visually clear",
  }]
  let rejectionNote = "Reject synthetic candidate for the recorded human-only failure"
  let rejectionBinding = C.reviewCommandBinding(
    ~packetPath=produced.fixture.packetPath,
    ~stateDir=produced.fixture.stateDir,
    ~targetId="T-SYNTHETIC",
    ~batchHash=batch.batchHash,
    ~candidateHash=produced.execution.candidate.candidateHash,
    ~decision=A.Reject,
    ~answers=rejectionAnswers,
    ~note=rejectionNote,
  )
  let rejected = C.recordHumanReview(
    ~packetPath=produced.fixture.packetPath,
    ~stateDir=produced.fixture.stateDir,
    ~targetId="T-SYNTHETIC",
    ~batchHash=batch.batchHash,
    ~candidateHash=produced.execution.candidate.candidateHash,
    ~commandText=F.reviewCommandForBinding(
      ~bindingHash=rejectionBinding,
      ~assertionId="CMD-REJECT-SYNTHETIC",
    ),
    ~decision=A.Reject,
    ~answers=rejectionAnswers,
    ~note=rejectionNote,
  )
  check(rejected.lifecycleEvent.state == S.Rejected, "human rejection must be durable")
  let store = A.openStore(~root=produced.fixture.storeDir, ~reviewBatchSize=3)
  check(
    A.listDispositions(store)->Belt.Array.some(row => row.kind == A.Rejected),
    "human rejection must preserve an exclusion disposition",
  )
  let eventCount = S.load(~stateDir=produced.fixture.stateDir).events->Belt.Array.length
  let unchanged = C.reconcile(
    ~packetPath=produced.fixture.packetPath,
    ~stateDir=produced.fixture.stateDir,
    ~targetId="T-SYNTHETIC",
  )
  check(
    unchanged.status == C.LifecycleCurrent(S.Rejected),
    "unchanged authority must not reopen a rejected target",
  )
  check(
    S.load(~stateDir=produced.fixture.stateDir).events->Belt.Array.length == eventCount,
    "reconciling an unchanged rejection must not append lifecycle events",
  )
  let rejectedCalls = ref(0)
  let rejectedProvider = fakeProvider(produced.fixture, rejectedCalls, "rejected-retry")
  expectControllerFailure("rejected target cannot execute again", () =>
    C.execute(
      ~packetPath=produced.fixture.packetPath,
      ~stateDir=produced.fixture.stateDir,
      ~targetId="T-SYNTHETIC",
      ~provider=rejectedProvider,
      ~authorizationCommandText="{}",
    )->ignore
  )
  check(rejectedCalls.contents == 0, "rejected target retry reached the fake provider")
  Js.log("ok - substantive human rejection is recorded and excluded")
}

let cloneDependencyIntoPacket = (fixture: F.fixture) => {
  let root = B.readText(B.Path(fixture.packetPath))
    ->Js.Json.parseExn
    ->Js.Json.decodeObject
    ->Belt.Option.getExn
  let targets = Js.Dict.get(root, "targets")
    ->Belt.Option.flatMap(Js.Json.decodeArray)
    ->Belt.Option.getExn
  let requirements = Js.Dict.get(root, "requirements")
    ->Belt.Option.flatMap(Js.Json.decodeArray)
    ->Belt.Option.getExn
  let mainTarget = Belt.Array.getExn(targets, 0)
    ->Js.Json.decodeObject
    ->Belt.Option.getExn
  let dependencyTarget = Js.Json.stringify(mainTarget->Js.Json.object_)
    ->Js.String2.replaceByRe(%re("/T-SYNTHETIC/g"), "T-DEPENDENCY")
    ->Js.String2.replaceByRe(%re("/R-/g"), "RD-")
    ->Js.Json.parseExn
  Js.Dict.set(
    mainTarget,
    "dependsOnTargetIds",
    Js.Json.array([Js.Json.string("T-DEPENDENCY")]),
  )
  let allTargets = Belt.Array.concat(targets, [dependencyTarget])
  let dependencyRequirements = requirements->Belt.Array.map(requirement =>
    Js.Json.stringify(requirement)
    ->Js.String2.replaceByRe(%re("/T-SYNTHETIC/g"), "T-DEPENDENCY")
    ->Js.String2.replaceByRe(%re("/R-/g"), "RD-")
    ->Js.Json.parseExn
  )
  Js.Dict.set(root, "targets", Js.Json.array(allTargets))
  Js.Dict.set(root, "requirements", Js.Json.array(Belt.Array.concat(requirements, dependencyRequirements)))
  B.writeText(
    B.Path(fixture.packetPath),
    F.bindApprovals(Js.Json.stringifyWithSpace(Js.Json.object_(root), 2)) ++ "\n",
  )
}

let approveDependency = (fixture: F.fixture) => {
  let dependency = C.reconcile(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId="T-DEPENDENCY",
  )
  check(ready(dependency), "synthetic dependency must compile ready")
  let order = dependency.workOrder->Belt.Option.getExn
  let artifactHash = B.sha256Text("synthetic dependency artifact")
  let reportHash = B.sha256Text("synthetic dependency report")
  let reviewHash = B.sha256Text("synthetic dependency review")
  S.append(
    ~stateDir=fixture.stateDir,
    ~targetId="T-DEPENDENCY",
    ~state=S.Authorized,
    ~actor=S.Human,
    ~packetHash=order.packetHash,
    ~workOrderHash=order.hash,
    ~reason="synthetic dependency authorization",
  )->ignore
  S.append(
    ~stateDir=fixture.stateDir,
    ~targetId="T-DEPENDENCY",
    ~state=S.CandidateQuarantine,
    ~actor=S.Provider,
    ~packetHash=order.packetHash,
    ~workOrderHash=order.hash,
    ~artifactHash,
    ~reason="synthetic dependency candidate",
  )->ignore
  S.append(
    ~stateDir=fixture.stateDir,
    ~targetId="T-DEPENDENCY",
    ~state=S.ReviewReady,
    ~actor=S.System,
    ~packetHash=order.packetHash,
    ~workOrderHash=order.hash,
    ~artifactHash,
    ~reportHash,
    ~reason="synthetic dependency inspection pass",
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
  C.reconcile(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId="T-DEPENDENCY",
  )->ignore
  order
}

let dependencyInvalidation = () => {
  let fixture = F.create()
  cloneDependencyIntoPacket(fixture)
  approveDependency(fixture)->ignore
  check(
    queueHasTarget(fixture, "blocked", "T-SYNTHETIC") &&
      Js.String2.includes(queueRaw(fixture, "blocked"), "TARGET_NOT_RECONCILED"),
    "declared but unreconciled targets must be explicit in the blocked queue",
  )

  let main = C.reconcile(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId="T-SYNTHETIC",
  )
  check(ready(main), "approved exact dependency must permit dependent target")
  check(
    !queueHasTarget(fixture, "blocked", "T-SYNTHETIC") &&
      queueHasTarget(fixture, "ready", "T-SYNTHETIC"),
    "reconciliation must move a target from blocked to ready",
  )
  S.append(
    ~stateDir=fixture.stateDir,
    ~targetId="T-DEPENDENCY",
    ~state=S.Superseded,
    ~actor=S.System,
    ~reason="synthetic dependency invalidated",
  )->ignore
  let blocked = C.reconcile(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId="T-SYNTHETIC",
  )
  check(blocked.status == C.ReconciliationBlocked, "lost dependency approval must invalidate ready target")
  check(
    blocked.blockers->Belt.Array.some(row => row.code == "DEPENDENCY_NOT_APPROVED"),
    "dependency invalidation must carry an exact blocker code",
  )
  check(
    stateFor(fixture, "T-SYNTHETIC").state == S.Blocked,
    "dependency invalidation must durably block dependent lifecycle",
  )
  Js.log("ok - approved dependency permits work and later invalidation blocks it")
}

let dependencyRaceBindings = () => {
  let beforeSubmit = F.create()
  cloneDependencyIntoPacket(beforeSubmit)
  approveDependency(beforeSubmit)->ignore
  let target = C.reconcile(
    ~packetPath=beforeSubmit.packetPath,
    ~stateDir=beforeSubmit.stateDir,
    ~targetId="T-SYNTHETIC",
  )
  check(ready(target), "dependent target must be ready before race test")
  let evaluated = P.evaluate(
    ~packetPath=beforeSubmit.packetPath,
    ~stateDir=beforeSubmit.stateDir,
    ~targetId="T-SYNTHETIC",
  )
  let cleared = evaluated.cleared->Belt.Option.getExn
  check(
    P.dependencyProofs(cleared)->Belt.Array.length == 1,
    "preflight authorization must bind the exact dependency event",
  )
  let calls = ref(0)
  let beforeProvider = F.registerFakeProvider(
    ~fixture=beforeSubmit,
    ~adapterId="fake-dependency-race-provider",
    ~submit=_ => {
      calls := calls.contents + 1
      Error("unexpected dependency-race provider call")
    },
  )
  let authorization = G.authorize(
    ~cleared,
    ~provider=beforeProvider,
    ~commandText=F.executionCommand(
      ~cleared,
      ~provider=beforeProvider,
      ~assertionId="CMD-DEPENDENCY-RACE-BEFORE-SUBMIT",
    ),
  )
  S.append(
    ~stateDir=beforeSubmit.stateDir,
    ~targetId="T-DEPENDENCY",
    ~state=S.Superseded,
    ~actor=S.System,
    ~reason="dependency changed after authorization",
  )->ignore
  let refused = try {
    let _ = G.execute(
      ~authorization,
      ~provider=beforeProvider,
    )
    false
  } catch {
  | G.GatewayError(_) => true
  }
  check(refused, "dependency change before submit must refuse execution")
  check(calls.contents == 0, "dependency change before submit must make zero provider calls")

  let duringSubmit = F.create()
  cloneDependencyIntoPacket(duringSubmit)
  approveDependency(duringSubmit)->ignore
  let duringCalls = ref(0)
  let duringProvider = F.registerFakeProvider(
    ~fixture=duringSubmit,
    ~adapterId="fake-dependency-drift-provider",
    ~submit=_ => {
      duringCalls := duringCalls.contents + 1
      S.append(
        ~stateDir=duringSubmit.stateDir,
        ~targetId="T-DEPENDENCY",
        ~state=S.Superseded,
        ~actor=S.System,
        ~reason="dependency changed while fake work was running",
      )->ignore
      Ok({
        content: "synthetic stale candidate",
        contentType: "text/plain",
        providerReceipt: "fake-drift-receipt",
      })
    },
  )
  let execution = C.execute(
    ~packetPath=duringSubmit.packetPath,
    ~stateDir=duringSubmit.stateDir,
    ~targetId="T-SYNTHETIC",
    ~provider=duringProvider,
    ~authorizationCommandText=authorizationCommand(
      ~fixture=duringSubmit,
      ~provider=duringProvider,
      ~assertionId="CMD-DEPENDENCY-DRIFT-DURING-SUBMIT",
    ),
  )
  check(duringCalls.contents == 1, "mid-call drift test must call only the fake provider once")
  check(execution.quarantinedStale, "dependency drift during work must stale-quarantine output")
  let store = A.openStore(~root=duringSubmit.storeDir, ~reviewBatchSize=3)
  check(
    A.listDispositions(store)->Belt.Array.some(row =>
      row.candidateHash == execution.candidate.candidateHash && row.kind == A.Stale
    ),
    "mid-call dependency drift must preserve a bound stale disposition",
  )
  check(
    C.createReviewBatch(
      ~packetPath=duringSubmit.packetPath,
      ~stateDir=duringSubmit.stateDir,
      ~targetId="T-SYNTHETIC",
    ) == None,
    "dependency-stale candidate must never enter review",
  )

  let downstream = F.create()
  cloneDependencyIntoPacket(downstream)
  approveDependency(downstream)->ignore
  let downstreamCalls = ref(0)
  let downstreamProvider = fakeProvider(downstream, downstreamCalls, "downstream-authority")
  let downstreamExecution = C.execute(
    ~packetPath=downstream.packetPath,
    ~stateDir=downstream.stateDir,
    ~targetId="T-SYNTHETIC",
    ~provider=downstreamProvider,
    ~authorizationCommandText=authorizationCommand(
      ~fixture=downstream,
      ~provider=downstreamProvider,
      ~assertionId="CMD-DOWNSTREAM-DEPENDENCY-AUTHORITY",
    ),
  )
  C.inspectCandidate(
    ~packetPath=downstream.packetPath,
    ~stateDir=downstream.stateDir,
    ~targetId="T-SYNTHETIC",
    ~candidateHash=downstreamExecution.candidate.candidateHash,
    ~inspector=fakeInspector(
      ~fixture=downstream,
      ~id="fake-downstream-pass-inspector",
      ~verdict=I.Pass,
    ),
  )->ignore
  let originalBatch = C.createReviewBatch(
    ~packetPath=downstream.packetPath,
    ~stateDir=downstream.stateDir,
    ~targetId="T-SYNTHETIC",
  )->Belt.Option.getExn
  S.append(
    ~stateDir=downstream.stateDir,
    ~targetId="T-DEPENDENCY",
    ~state=S.Superseded,
    ~actor=S.System,
    ~reason="rotate dependency approval event without changing work-order bytes",
  )->ignore
  approveDependency(downstream)->ignore
  check(
    !G.candidateAuthorityCurrent(
      ~packetPath=downstream.packetPath,
      ~stateDir=downstream.stateDir,
      ~candidate=downstreamExecution.candidate,
    ),
    "a new dependency approval event must stale the old candidate authorization",
  )
  expectControllerFailure("rotated dependency blocks a previously batched candidate", () =>
    C.reviewCommandBinding(
      ~packetPath=downstream.packetPath,
      ~stateDir=downstream.stateDir,
      ~targetId="T-SYNTHETIC",
      ~batchHash=originalBatch.batchHash,
      ~candidateHash=downstreamExecution.candidate.candidateHash,
      ~decision=A.Approve,
      ~answers=[{
        requirementId: "R-CAMERA",
        verdict: C.HumanPass,
        evidence: "synthetic evidence must not override dependency drift",
      }],
      ~note="This command must not be mintable under rotated dependency authority",
    )->ignore
  )
  C.reconcile(
    ~packetPath=downstream.packetPath,
    ~stateDir=downstream.stateDir,
    ~targetId="T-SYNTHETIC",
  )->ignore
  let downstreamStore = A.openStore(~root=downstream.storeDir, ~reviewBatchSize=3)
  check(
    A.listDispositions(downstreamStore)->Belt.Array.some(row =>
      row.candidateHash == downstreamExecution.candidate.candidateHash && row.kind == A.Stale
    ),
    "restart reconciliation must stale-dispose a candidate after dependency-event rotation",
  )
  check(
    C.createReviewBatch(
      ~packetPath=downstream.packetPath,
      ~stateDir=downstream.stateDir,
      ~targetId="T-SYNTHETIC",
    ) == None,
    "dependency-rotated candidate must remain excluded from every later review batch",
  )
  check(downstreamCalls.contents == 1, "downstream authority checks made another provider call")
  Js.log("ok - dependency event proofs block pre-submit races and quarantine mid-call drift")
}

let main = () => {
  reconcileIdempotentlyAndInvalidateDiskDrift()
  explicitAuthorizationAndApprovalFlow()
  failAndUnknownRemainOutOfReview()
  rejectFlow()
  dependencyInvalidation()
  dependencyRaceBindings()
  Js.log("PRODUCTION CONTROLLER TESTS PASSED")
}

main()
