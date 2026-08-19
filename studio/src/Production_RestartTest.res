/* Restart integration contract for the generic production control plane.

   Every crash boundary below is simulated with synthetic fixture state and
   direct journal/store writes. No real provider is called, no network is
   available, and no production artifact is read or changed. */

module B = Cinema_Backends
module W = Production_WorkOrder
module S = Production_State
module P = Production_Preflight
module G = Production_Gateway
module C = Production_Controller
module J = Production_ExecutionJournal
module A = Production_ArtifactStore
module F = Production_TestFixtures

let targetId = "T-SYNTHETIC"

let fail = message => {
  Js.log("FAIL - " ++ message)
  assert(false)
}

let expect = (condition, message) =>
  if !condition {
    fail(message)
  }

let expectGatewayError = (label, work) => {
  let refused = try {
    work()
    false
  } catch {
  | G.GatewayError(_) => true
  }
  expect(refused, label ++ ": expected GatewayError")
}

let requireOrder = evaluation =>
  switch evaluation.W.workOrder {
  | Some(order) => order
  | None => fail("expected a compiled synthetic work order:\n" ++ W.explain(evaluation))
  }

let requireCleared = evaluation =>
  switch evaluation.P.cleared {
  | Some(cleared) => cleared
  | None => fail("expected a cleared synthetic work order:\n" ++ P.explain(evaluation))
  }

let currentTarget = stateDir =>
  switch S.load(~stateDir).targets->Belt.Array.getBy(row => row.targetId == targetId) {
  | Some(row) => row
  | None => fail("synthetic target is absent from lifecycle state")
  }

let onlyAuthorization = stateDir => {
  let authorizations = J.load(~stateDir).authorizations
  if Belt.Array.length(authorizations) != 1 {
    fail("expected exactly one synthetic execution authorization")
  }
  authorizations[0]
}

let onlyAttempt = stateDir => {
  let attempts = J.load(~stateDir).attempts
  if Belt.Array.length(attempts) != 1 {
    fail("expected exactly one synthetic execution attempt")
  }
  attempts[0]
}

let expectStatus = (reconciliation, expected, message) =>
  switch reconciliation.C.status {
  | C.LifecycleCurrent(actual) => expect(actual == expected, message)
  | C.ReadyForExecution => fail(message ++ ": unexpectedly ready")
  | C.ReconciliationBlocked => fail(message ++ ": unexpectedly reconciliation-blocked")
  }

let prepareAuthorized = assertionId => {
  let fixture = F.create()
  let ready = C.reconcile(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId,
  )
  switch ready.status {
  | C.ReadyForExecution => ()
  | _ => fail("synthetic fixture did not reconcile to Ready")
  }
  let order = requireOrder(W.compile(~packetPath=fixture.packetPath, ~targetId))
  let cleared = requireCleared(
    P.evaluate(~packetPath=fixture.packetPath, ~stateDir=fixture.stateDir, ~targetId),
  )
  let calls = ref(0)
  let provider = F.registerFakeProvider(
    ~fixture,
    ~adapterId="restart-fake-provider-" ++ assertionId,
    ~submit=_ => {
      calls := calls.contents + 1
      Error("restart tests must never invoke the fake provider")
    },
  )
  let authorization = G.authorize(
    ~cleared,
    ~provider,
    ~commandText=F.executionCommand(~cleared, ~provider, ~assertionId),
  )
  expect(currentTarget(fixture.stateDir).state == S.Authorized, "authorization was not durable")
  (fixture, order, provider, authorization, calls)
}

let claim = (fixture: F.fixture) => {
  let authorization = onlyAuthorization(fixture.stateDir)
  J.claimNextAttempt(
    ~stateDir=fixture.stateDir,
    ~authorizationId=authorization.authorizationId,
    ~reason="synthetic crash boundary after attempt claim",
  )
}

let markSubmitting = (fixture: F.fixture) => {
  let authorization = onlyAuthorization(fixture.stateDir)
  let claimed = claim(fixture)
  J.recordStatus(
    ~stateDir=fixture.stateDir,
    ~authorizationId=authorization.authorizationId,
    ~attempt=claimed.attempt,
    ~status=J.Submitting,
    ~reason="synthetic crash boundary immediately before provider invocation",
  )->ignore
  claimed
}

let storeFor = (fixture: F.fixture, order: W.workOrder) =>
  A.openStore(~root=fixture.storeDir, ~reviewBatchSize=order.reviewBatchSize)

let putCrashCandidate = (~fixture: F.fixture, ~order: W.workOrder, ~attempt) => {
  let authorization = onlyAuthorization(fixture.stateDir)
  let store = storeFor(fixture, order)
  let candidate = A.putTextCandidate(
    ~store,
    ~producerId="PR-PRODUCER",
    ~targetId,
    ~authorizationId=authorization.authorizationId,
    ~attempt,
    ~providerReceiptHash=B.sha256Text("synthetic-restart-provider-receipt"),
    ~packetHash=order.packetHash,
    ~workOrderHash=order.hash,
    ~text="synthetic candidate persisted at a crash boundary\n",
  )
  (store, candidate)
}

let unclaimedAuthorizationBlocksThenExplicitlyReopens = () => {
  let (fixture, _, _, _, calls) = prepareAuthorized("CMD-RESTART-UNCLAIMED")
  let first = C.reconcile(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId,
  )
  switch first.status {
  | C.ReconciliationBlocked => {
      expect(
        first.blockers->Belt.Array.some(row => row.code == "EXECUTION_RECOVERED_BEFORE_SUBMIT"),
        "unclaimed authorization did not produce the stable restart blocker",
      )
    }
  | _ => fail("unclaimed authorization did not fail closed on first reconciliation")
  }
  expect(currentTarget(fixture.stateDir).state == S.Blocked, "unclaimed authorization was not blocked")
  expect(calls.contents == 0, "unclaimed authorization recovery called the fake provider")

  let later = C.reconcile(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId,
  )
  switch later.status {
  | C.ReadyForExecution => ()
  | _ => fail("later explicit reconciliation did not reopen recovered pre-submit work")
  }
  expect(calls.contents == 0, "reopening recovered work called the fake provider")
}

let claimedBeforeSubmitRecoversWithoutProviderCall = () => {
  let (fixture, _, _, _, calls) = prepareAuthorized("CMD-RESTART-CLAIMED")
  claim(fixture)->ignore
  let recovered = C.reconcile(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId,
  )
  switch recovered.status {
  | C.ReconciliationBlocked => ()
  | _ => fail("claimed-before-submit crash did not reconcile as blocked")
  }
  let attempt = onlyAttempt(fixture.stateDir)
  expect(
    attempt.current.status == J.BlockedPreSubmit,
    "claimed-before-submit crash did not become BlockedPreSubmit",
  )
  expect(currentTarget(fixture.stateDir).state == S.Blocked, "claimed crash did not block lifecycle")
  expect(calls.contents == 0, "claimed-before-submit recovery called the fake provider")
}

let submittingRecoveryIsUnknownTerminalAndCannotRetry = () => {
  let (fixture, _, provider, authorization, calls) = prepareAuthorized("CMD-RESTART-SUBMITTING")
  markSubmitting(fixture)->ignore
  let recovered = C.reconcile(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId,
  )
  expectStatus(
    recovered,
    S.Superseded,
    "submitting crash was not superseded under unknown external outcome",
  )
  expect(
    onlyAttempt(fixture.stateDir).current.status == J.InterruptedUnknown,
    "submitting crash did not become InterruptedUnknown",
  )
  expectGatewayError("retry after interrupted submission", () =>
    G.execute(~authorization, ~provider)->ignore
  )
  expect(calls.contents == 0, "interrupted submission recovery or retry called the fake provider")
}

let candidateAtInterruptedBoundaryIsPreservedAndExcluded = () => {
  let (fixture, order, _, _, calls) = prepareAuthorized("CMD-RESTART-CANDIDATE")
  let submitting = markSubmitting(fixture)
  let (store, candidate) = putCrashCandidate(~fixture, ~order, ~attempt=submitting.attempt)
  A.recordInspection(
    ~store,
    ~candidate,
    ~reportText="synthetic PASS evidence that must not override interrupted provenance\n",
    ~inspectorId="PR-INSPECTOR",
    ~verdict=A.Pass,
  )->ignore

  let recovered = C.reconcile(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId,
  )
  expectStatus(recovered, S.Superseded, "interrupted candidate lifecycle was not superseded")
  let candidates = A.listCandidates(store)
  expect(Belt.Array.length(candidates) == 1, "interrupted candidate bytes were discarded or duplicated")
  expect(candidates[0].candidateHash == candidate.candidateHash, "preserved candidate identity changed")
  let dispositions = A.listDispositions(store)
  expect(Belt.Array.length(dispositions) == 1, "interrupted candidate lacks one exclusion disposition")
  expect(
    dispositions[0].kind == A.Quarantined &&
    dispositions[0].candidateHash == candidate.candidateHash,
    "interrupted candidate received the wrong quarantine disposition",
  )
  expect(
    A.createReviewBatch(
      ~store,
      ~targetId,
      ~packetHash=order.packetHash,
      ~workOrderHash=order.hash,
    ) == None,
    "interrupted candidate entered review despite its quarantine disposition",
  )
  expect(calls.contents == 0, "interrupted candidate recovery called the fake provider")
}

let terminalCandidateJournalRestoresLifecycle = () => {
  let (fixture, order, _, _, calls) = prepareAuthorized("CMD-RESTART-TERMINAL-CANDIDATE")
  let submitting = markSubmitting(fixture)
  let (_, candidate) = putCrashCandidate(~fixture, ~order, ~attempt=submitting.attempt)
  let authorization = onlyAuthorization(fixture.stateDir)
  J.recordStatus(
    ~stateDir=fixture.stateDir,
    ~authorizationId=authorization.authorizationId,
    ~attempt=submitting.attempt,
    ~status=J.CandidateQuarantine,
    ~candidateHash=candidate.candidateHash,
    ~artifactHash=candidate.artifactHash,
    ~providerReceiptHash=candidate.providerReceiptHash,
    ~reason="synthetic crash after terminal journal and before lifecycle append",
  )->ignore
  expect(currentTarget(fixture.stateDir).state == S.Authorized, "fixture crossed lifecycle boundary early")

  let recovered = C.reconcile(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId,
  )
  expectStatus(
    recovered,
    S.CandidateQuarantine,
    "terminal candidate journal did not restore CandidateQuarantine lifecycle",
  )
  expect(
    currentTarget(fixture.stateDir).lastEvent.artifactHash == Some(candidate.artifactHash),
    "restored lifecycle is not bound to the terminal candidate artifact",
  )
  expect(calls.contents == 0, "terminal candidate recovery called the fake provider")
}

let terminalCandidateWithDriftRecoversAsStale = () => {
  let (fixture, order, _, _, calls) = prepareAuthorized("CMD-RESTART-TERMINAL-STALE")
  let submitting = markSubmitting(fixture)
  let (store, candidate) = putCrashCandidate(~fixture, ~order, ~attempt=submitting.attempt)
  A.recordInspection(
    ~store,
    ~candidate,
    ~reportText="synthetic PASS evidence predating reference drift\n",
    ~inspectorId="PR-INSPECTOR",
    ~verdict=A.Pass,
  )->ignore
  let authorization = onlyAuthorization(fixture.stateDir)
  J.recordStatus(
    ~stateDir=fixture.stateDir,
    ~authorizationId=authorization.authorizationId,
    ~attempt=submitting.attempt,
    ~status=J.CandidateQuarantine,
    ~candidateHash=candidate.candidateHash,
    ~artifactHash=candidate.artifactHash,
    ~providerReceiptHash=candidate.providerReceiptHash,
    ~reason="synthetic crash after terminal journal before drift-aware lifecycle append",
  )->ignore
  B.writeText(B.Path(fixture.firstReferencePath), "changed source reference after terminal receipt\n")

  let first = G.recover(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId,
  )
  expect(first.changed, "drifted terminal candidate was not recovered as stale")
  expect(currentTarget(fixture.stateDir).state == S.Superseded, "stale recovery did not supersede lifecycle")
  expect(
    A.listDispositions(store)->Belt.Array.some(row =>
      row.candidateHash == candidate.candidateHash && row.kind == A.Stale
    ),
    "drifted terminal candidate lacks an immutable stale disposition",
  )
  expect(
    A.createReviewBatch(
      ~store,
      ~targetId,
      ~packetHash=order.packetHash,
      ~workOrderHash=order.hash,
    ) == None,
    "drifted terminal candidate entered review after restart",
  )
  let second = G.recover(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId,
  )
  expect(!second.changed, "stale terminal recovery was not idempotent")
  expect(calls.contents == 0, "drifted terminal recovery called the fake provider")
}

let authorizedLifecycleWithoutJournalBlocks = () => {
  let fixture = F.create()
  let ready = C.reconcile(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId,
  )
  switch ready.status {
  | C.ReadyForExecution => ()
  | _ => fail("missing-journal fixture did not reconcile to Ready")
  }
  let order = requireOrder(W.compile(~packetPath=fixture.packetPath, ~targetId))
  S.append(
    ~stateDir=fixture.stateDir,
    ~targetId,
    ~state=S.Authorized,
    ~actor=S.Human,
    ~packetHash=order.packetHash,
    ~workOrderHash=order.hash,
    ~reason="synthetic crash after lifecycle authorization but before journal commit",
  )->ignore

  let recovered = C.reconcile(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId,
  )
  switch recovered.status {
  | C.ReconciliationBlocked => ()
  | _ => fail("Authorized lifecycle without journal did not fail closed")
  }
  expect(currentTarget(fixture.stateDir).state == S.Blocked, "missing journal did not block lifecycle")
  expect(
    Js.String2.includes(currentTarget(fixture.stateDir).lastEvent.reason, "no immutable execution-journal"),
    "missing-journal blocker did not preserve its plain-language reason",
  )
}

let repeatRecoveryIsIdempotent = () => {
  let (fixture, _, _, _, calls) = prepareAuthorized("CMD-RESTART-IDEMPOTENT")
  claim(fixture)->ignore
  let first = G.recover(~packetPath=fixture.packetPath, ~stateDir=fixture.stateDir, ~targetId)
  expect(first.changed, "first recovery did not report its durable repair")
  let afterFirst = S.load(~stateDir=fixture.stateDir)
  let firstTransition = onlyAttempt(fixture.stateDir).current.transitionId
  let second = G.recover(~packetPath=fixture.packetPath, ~stateDir=fixture.stateDir, ~targetId)
  expect(!second.changed, "repeat recovery was not reported as idempotent")
  let afterSecond = S.load(~stateDir=fixture.stateDir)
  expect(
    Belt.Array.length(afterSecond.events) == Belt.Array.length(afterFirst.events),
    "repeat recovery appended a duplicate lifecycle event",
  )
  expect(
    onlyAttempt(fixture.stateDir).current.transitionId == firstTransition,
    "repeat recovery appended a duplicate journal transition",
  )
  expect(calls.contents == 0, "idempotent recovery called the fake provider")
}

unclaimedAuthorizationBlocksThenExplicitlyReopens()
claimedBeforeSubmitRecoversWithoutProviderCall()
submittingRecoveryIsUnknownTerminalAndCannotRetry()
candidateAtInterruptedBoundaryIsPreservedAndExcluded()
terminalCandidateJournalRestoresLifecycle()
terminalCandidateWithDriftRecoversAsStale()
authorizedLifecycleWithoutJournalBlocks()
repeatRecoveryIsIdempotent()

Js.log("PASS - production restart recovery and crash-boundary contract")
