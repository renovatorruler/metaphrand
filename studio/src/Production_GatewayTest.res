/* Contract tests for the sole production execution boundary. These fixtures
   contain only synthetic text and in-process fake providers: no network,
   media, real provider, process spawn, or story data is involved. */

module B = Cinema_Backends
module W = Production_WorkOrder
module S = Production_State
module P = Production_Preflight
module G = Production_Gateway
module A = Production_ArtifactStore
module J = Production_ExecutionJournal
module F = Production_TestFixtures

let targetId = "T-SYNTHETIC"
let providerId = "fake-provider"

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
  if !refused {
    fail(label ++ ": expected GatewayError")
  }
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

let prepareReady = () => {
  let fixture = Production_TestFixtures.create()
  let order = requireOrder(W.compile(~packetPath=fixture.packetPath, ~targetId))
  S.append(
    ~stateDir=fixture.stateDir,
    ~targetId,
    ~state=S.Locked,
    ~actor=S.System,
    ~reason="synthetic authority locked for gateway contract test",
  )->ignore
  S.append(
    ~stateDir=fixture.stateDir,
    ~targetId,
    ~state=S.Compiled,
    ~actor=S.System,
    ~packetHash=order.packetHash,
    ~workOrderHash=order.hash,
    ~reason="synthetic work order compiled for gateway contract test",
  )->ignore
  S.append(
    ~stateDir=fixture.stateDir,
    ~targetId,
    ~state=S.Ready,
    ~actor=S.System,
    ~packetHash=order.packetHash,
    ~workOrderHash=order.hash,
    ~reason="synthetic work order ready for gateway contract test",
  )->ignore
  let cleared = requireCleared(P.evaluate(~packetPath=fixture.packetPath, ~stateDir=fixture.stateDir, ~targetId))
  (fixture, order, cleared)
}

let currentTarget = stateDir =>
  switch S.load(~stateDir).targets->Belt.Array.getBy(row => row.targetId == targetId) {
  | Some(row) => row
  | None => fail("synthetic target is absent from lifecycle state")
  }

let storeFor = (fixture: Production_TestFixtures.fixture, order: W.workOrder) =>
  A.openStore(~root=fixture.storeDir, ~reviewBatchSize=order.reviewBatchSize)

let validProvider = (~fixture, ~calls, ~expectedOrder: W.workOrder, ~onSubmit=(_request => ())) =>
  F.registerFakeProvider(~fixture, ~adapterId=providerId, ~submit=request => {
      calls := calls.contents + 1
      onSubmit(request)
      let referencesMatch = Belt.Array.length(request.references) == Belt.Array.length(expectedOrder.references) &&
        request.references->Belt.Array.every(reference =>
          expectedOrder.references->Belt.Array.some(expected =>
            reference.assetId == expected.assetId && reference.path != expected.path &&
            Js.String2.startsWith(reference.path, fixture.stateDir ++ "/inputs/sha256/") &&
            reference.sha256 == expected.sha256 && B.exists(B.Path(reference.path)) &&
            B.sha256File(B.Path(reference.path)) == reference.sha256
          )
        )
      if request.authorizationId == "" || request.packetHash != expectedOrder.packetHash ||
        request.workOrderHash != expectedOrder.hash || request.targetId != expectedOrder.targetId ||
        request.operation != expectedOrder.operation ||
        request.canonicalWorkOrder != expectedOrder.canonical || !referencesMatch {
        fail("gateway supplied an incomplete or unbound provider request")
      }
      Ok({
        content: "synthetic provider output\n",
        contentType: "application/x-synthetic-text",
        providerReceipt: "FAKE-RECEIPT-OK",
      })
    })

let authorize = (~cleared, ~provider, ~id) =>
  G.authorize(
    ~cleared,
    ~provider,
    ~commandText=F.executionCommand(~cleared, ~provider, ~assertionId=id),
  )

let packetDrift = (fixture: Production_TestFixtures.fixture) => {
  let original = B.readText(B.Path(fixture.packetPath))
  let changed = Js.String2.replace(
    original,
    "Exercise the generic production lifecycle",
    "Exercise a changed synthetic production lifecycle",
  )
  expect(changed != original, "packet drift fixture did not alter authority")
  B.writeText(B.Path(fixture.packetPath), changed)
}

let referenceDrift = (fixture: Production_TestFixtures.fixture) =>
  B.writeText(B.Path(fixture.firstReferencePath), "changed synthetic subject reference\n")

let assertDurableFailure = (
  fixture: Production_TestFixtures.fixture,
  order: W.workOrder,
  expectedMessage,
) => {
  let journal = J.load(~stateDir=fixture.stateDir)
  expect(Belt.Array.length(journal.attempts) == 1, "failed gateway attempt lacks a journal receipt")
  let receipt = journal.attempts[0].current
  expect(
    receipt.status == J.Failed && Js.String2.includes(receipt.reason, expectedMessage) &&
    receipt.transitionId == "JEV-" ++ receipt.recordHash,
    "canonical failure receipt does not preserve status, reason, and content hash",
  )
  expect(currentTarget(fixture.stateDir).state == S.Blocked, "provider failure did not block the lifecycle")
  let store = storeFor(fixture, order)
  expect(Belt.Array.length(A.listCandidates(store)) == 0, "failed provider attempt created a candidate")
}

let assertDurableUnknown = (
  fixture: Production_TestFixtures.fixture,
  order: W.workOrder,
  expectedMessage,
) => {
  let journal = J.load(~stateDir=fixture.stateDir)
  expect(Belt.Array.length(journal.attempts) == 1, "unknown provider outcome lacks a journal receipt")
  let receipt = journal.attempts[0].current
  expect(
    receipt.status == J.InterruptedUnknown && Js.String2.includes(receipt.reason, expectedMessage) &&
    receipt.transitionId == "JEV-" ++ receipt.recordHash,
    "unknown-outcome receipt does not preserve status, reason, and content hash",
  )
  expect(
    currentTarget(fixture.stateDir).state == S.Superseded,
    "unknown provider outcome did not terminate retry authority",
  )
  let store = storeFor(fixture, order)
  expect(Belt.Array.length(A.listCandidates(store)) == 0, "unknown provider outcome created a candidate")
}

let reopen = (fixture: Production_TestFixtures.fixture, order: W.workOrder) => {
  S.append(
    ~stateDir=fixture.stateDir,
    ~targetId,
    ~state=S.Compiled,
    ~actor=S.System,
    ~packetHash=order.packetHash,
    ~workOrderHash=order.hash,
    ~reason="synthetic retry recompiled the unchanged authority",
  )->ignore
  S.append(
    ~stateDir=fixture.stateDir,
    ~targetId,
    ~state=S.Ready,
    ~actor=S.System,
    ~packetHash=order.packetHash,
    ~workOrderHash=order.hash,
    ~reason="synthetic retry returned the unchanged authority to ready",
  )->ignore
  requireCleared(P.evaluate(~packetPath=fixture.packetPath, ~stateDir=fixture.stateDir, ~targetId))
}

let validExecutionIsQuarantinedAndIdempotent = () => {
  let (fixture, order, cleared) = prepareReady()
  let calls = ref(0)
  let provider = validProvider(~fixture, ~calls, ~expectedOrder=order)
  let authorization = authorize(~cleared, ~provider, ~id="CMD-VALID-EXECUTION")
  let first = G.execute(~authorization, ~provider)
  expect(calls.contents == 1, "valid execution did not call the fake provider exactly once")
  expect(!first.reused && !first.quarantinedStale && first.attempt == 1, "first execution returned the wrong execution status")
  expect(currentTarget(fixture.stateDir).state == S.CandidateQuarantine, "valid output bypassed candidate quarantine")
  let store = storeFor(fixture, order)
  let candidates = A.listCandidates(store)
  expect(Belt.Array.length(candidates) == 1, "valid output was not preserved exactly once")
  expect(candidates[0].candidateHash == first.candidate.candidateHash, "execution and store disagree on candidate identity")
  expect(Belt.Array.length(A.listInspections(store)) == 0, "gateway performed or invented an independent inspection")

  let second = G.execute(~authorization, ~provider)
  expect(calls.contents == 1, "idempotent replay called the fake provider again")
  expect(second.reused, "idempotent replay was not reported as reused")
  expect(second.candidate.candidateHash == first.candidate.candidateHash, "idempotent replay returned different bytes")
}

let explicitSignedCommandIsMandatory = () => {
  let (fixture, order, cleared) = prepareReady()
  let calls = ref(0)
  let provider = validProvider(~fixture, ~calls, ~expectedOrder=order)
  expectGatewayError("missing signed command", () =>
    G.authorize(~cleared, ~provider, ~commandText="{}") ->ignore
  )
  expect(calls.contents == 0, "missing signed command reached a fake provider")
}

let providerBindingIsExact = () => {
  let (fixture, order, cleared) = prepareReady()
  let calls = ref(0)
  let authorizedProvider = validProvider(~fixture, ~calls, ~expectedOrder=order)
  let wrong = F.registerFakeProvider(
    ~fixture,
    ~adapterId="different-fake-provider",
    ~submit=_ => {
      calls := calls.contents + 1
      Error("must not be called")
    },
  )
  let authorization = authorize(
    ~cleared,
    ~provider=authorizedProvider,
    ~id="CMD-PROVIDER-BINDING",
  )
  expectGatewayError("wrong provider", () => G.execute(~authorization, ~provider=wrong)->ignore)
  expect(calls.contents == 0, "wrong provider was called")
}

let staleAuthorityBeforeAuthorizeMakesZeroCalls = () => {
  let (packetFixture, packetOrder, packetCleared) = prepareReady()
  let packetCalls = ref(0)
  let packetProvider = validProvider(~fixture=packetFixture, ~calls=packetCalls, ~expectedOrder=packetOrder)
  packetDrift(packetFixture)
  expectGatewayError("packet drift before authorize", () =>
    authorize(
      ~cleared=packetCleared,
      ~provider=packetProvider,
      ~id="CMD-PACKET-DRIFT-BEFORE-AUTH",
    )->ignore
  )
  expect(packetCalls.contents == 0, "packet drift before authorize reached a fake provider")

  let (referenceFixture, referenceOrder, referenceCleared) = prepareReady()
  let referenceCalls = ref(0)
  let referenceProvider = validProvider(
    ~fixture=referenceFixture,
    ~calls=referenceCalls,
    ~expectedOrder=referenceOrder,
  )
  referenceDrift(referenceFixture)
  expectGatewayError("reference drift before authorize", () =>
    authorize(
      ~cleared=referenceCleared,
      ~provider=referenceProvider,
      ~id="CMD-REFERENCE-DRIFT-BEFORE-AUTH",
    )->ignore
  )
  expect(referenceCalls.contents == 0, "reference drift before authorize reached a fake provider")
}

let staleAuthorityBeforeSubmitMakesZeroCalls = () => {
  let (packetFixture, packetOrder, packetCleared) = prepareReady()
  let packetCalls = ref(0)
  let packetProvider = validProvider(~fixture=packetFixture, ~calls=packetCalls, ~expectedOrder=packetOrder)
  let packetAuthorization = authorize(
    ~cleared=packetCleared,
    ~provider=packetProvider,
    ~id="CMD-PACKET-DRIFT-BEFORE-SUBMIT",
  )
  packetDrift(packetFixture)
  expectGatewayError("packet drift before submit", () =>
    G.execute(~authorization=packetAuthorization, ~provider=packetProvider)->ignore
  )
  expect(packetCalls.contents == 0, "packet drift before submit reached a fake provider")

  let (referenceFixture, referenceOrder, referenceCleared) = prepareReady()
  let referenceCalls = ref(0)
  let referenceProvider = validProvider(
    ~fixture=referenceFixture,
    ~calls=referenceCalls,
    ~expectedOrder=referenceOrder,
  )
  let referenceAuthorization = authorize(
    ~cleared=referenceCleared,
    ~provider=referenceProvider,
    ~id="CMD-REFERENCE-DRIFT-BEFORE-SUBMIT",
  )
  referenceDrift(referenceFixture)
  expectGatewayError("reference drift before submit", () =>
    G.execute(~authorization=referenceAuthorization, ~provider=referenceProvider)->ignore
  )
  expect(referenceCalls.contents == 0, "reference drift before submit reached a fake provider")
}

let unprovedProviderFailuresAreUnknownAndNeverRetry = () => {
  let (fixture, order, cleared) = prepareReady()
  let calls = ref(0)
  let provider = F.registerFakeProvider(~fixture, ~adapterId=providerId, ~submit=_ => {
      calls := calls.contents + 1
      Error("synthetic provider refusal")
    })
  let authorization = authorize(~cleared, ~provider, ~id="CMD-PROVIDER-FAILURE")
  expectGatewayError("provider error", () => G.execute(~authorization, ~provider)->ignore)
  expect(calls.contents == 1, "provider error path did not call the fake provider exactly once")
  assertDurableUnknown(fixture, order, "synthetic provider refusal")
  expectGatewayError("consumed failed authorization", () => G.execute(~authorization, ~provider)->ignore)
  expect(calls.contents == 1, "consumed failed authorization called the fake provider again")
  let retryCleared = reopen(fixture, order)
  expectGatewayError("unknown provider outcome forbids a new authorization", () =>
    authorize(~cleared=retryCleared, ~provider, ~id="CMD-PROVIDER-FAILURE-RETRY")->ignore
  )
  expect(calls.contents == 1, "unknown provider outcome permitted a second fake provider call")
}

let invalidProviderOutputFailsClosed = () => {
  let (fixture, order, cleared) = prepareReady()
  let calls = ref(0)
  let provider = F.registerFakeProvider(~fixture, ~adapterId=providerId, ~submit=_ => {
      calls := calls.contents + 1
      Ok({content: "", contentType: "", providerReceipt: ""})
    })
  let authorization = authorize(~cleared, ~provider, ~id="CMD-INVALID-OUTPUT")
  expectGatewayError("invalid provider output", () => G.execute(~authorization, ~provider)->ignore)
  expect(calls.contents == 1, "invalid-output path called the fake provider more than once")
  assertDurableFailure(fixture, order, "response lacks content, contentType, or providerReceipt")
}

let driftDuringProviderCallPreservesStaleQuarantine = () => {
  let (fixture, order, cleared) = prepareReady()
  let calls = ref(0)
  let provider = validProvider(
    ~fixture,
    ~calls,
    ~expectedOrder=order,
    ~onSubmit=_ => packetDrift(fixture),
  )
  let authorization = authorize(~cleared, ~provider, ~id="CMD-DRIFT-DURING-CALL")
  let execution = G.execute(~authorization, ~provider)
  expect(calls.contents == 1, "authority-drift execution did not call the fake provider exactly once")
  expect(execution.quarantinedStale, "authority drift during provider work was not marked stale")
  expect(!execution.reused, "fresh stale output was incorrectly reported as reused")
  expect(
    currentTarget(fixture.stateDir).state == S.Superseded,
    "stale output did not terminate its obsolete lifecycle authority",
  )
  let store = storeFor(fixture, order)
  expect(Belt.Array.length(A.listCandidates(store)) == 1, "stale output bytes were discarded")
  let dispositions = A.listDispositions(store)
  expect(Belt.Array.length(dispositions) == 1, "stale output lacks an exclusion disposition")
  expect(dispositions[0].kind == A.Stale, "authority-drift output has the wrong disposition")
  expect(
    dispositions[0].candidateHash == execution.candidate.candidateHash,
    "stale disposition is not bound to the preserved candidate",
  )
  let journal = J.load(~stateDir=fixture.stateDir)
  expect(
    journal.attempts[0].current.status == J.StaleQuarantine,
    "stale output lacks a canonical stale-quarantine journal receipt",
  )
}

let immutableReferenceDriftDuringSubmissionIsStale = () => {
  let (fixture, order, cleared) = prepareReady()
  let calls = ref(0)
  let provider = F.registerFakeProvider(~fixture, ~adapterId=providerId, ~submit=request => {
      calls := calls.contents + 1
      let snapshot = request.references[0]
      B.writeText(B.Path(snapshot.path), "corrupted immutable snapshot during submission\n")
      Ok({
        content: "synthetic output from changed reference authority\n",
        contentType: "application/x-synthetic-text",
        providerReceipt: "FAKE-RECEIPT-REFERENCE-DRIFT",
      })
    })
  let authorization = authorize(~cleared, ~provider, ~id="CMD-REFERENCE-DRIFT-DURING-CALL")
  let execution = G.execute(~authorization, ~provider)
  expect(calls.contents == 1, "reference-drift fixture did not make exactly one fake call")
  expect(execution.quarantinedStale, "reference drift during submission was accepted as current")
  let store = storeFor(fixture, order)
  expect(
    A.listDispositions(store)->Belt.Array.some(row =>
      row.candidateHash == execution.candidate.candidateHash && row.kind == A.Stale
    ),
    "reference-drift output was not preserved with a stale disposition",
  )
}

let attemptCeilingSpansSingleUseAuthorizations = () => {
  let (fixture, order, cleared) = prepareReady()
  let calls = ref(0)
  let provider = F.registerFakeProvider(~fixture, ~adapterId=providerId, ~submit=_ => {
      calls := calls.contents + 1
      Ok({content: "", contentType: "", providerReceipt: ""})
    })
  let first = authorize(~cleared, ~provider, ~id="CMD-ATTEMPT-CEILING-1")
  expectGatewayError("first invalid attempt", () => G.execute(~authorization=first, ~provider)->ignore)
  let secondCleared = reopen(fixture, order)
  let second = authorize(~cleared=secondCleared, ~provider, ~id="CMD-ATTEMPT-CEILING-2")
  expectGatewayError("second invalid attempt", () => G.execute(~authorization=second, ~provider)->ignore)
  let thirdCleared = reopen(fixture, order)
  expectGatewayError("third authorization exceeds ceiling", () =>
    authorize(~cleared=thirdCleared, ~provider, ~id="CMD-ATTEMPT-CEILING-3")->ignore
  )
  expect(calls.contents == 2, "attempt ceiling permitted more than two fake provider calls")
  let journal = J.load(~stateDir=fixture.stateDir)
  expect(Belt.Array.length(journal.attempts) == 2, "attempt ceiling journal count is not exact")
}

let idempotentReplayRevalidatesCurrentAuthority = () => {
  let (fixture, order, cleared) = prepareReady()
  let calls = ref(0)
  let provider = validProvider(~fixture, ~calls, ~expectedOrder=order)
  let authorization = authorize(~cleared, ~provider, ~id="CMD-IDEMPOTENT-REPLAY")
  let first = G.execute(~authorization, ~provider)
  expect(calls.contents == 1, "replay-drift fixture did not complete its initial fake call")

  referenceDrift(fixture)
  expectGatewayError("idempotent replay after authority drift", () =>
    G.execute(~authorization, ~provider)->ignore
  )
  expect(calls.contents == 1, "stale idempotent replay called the fake provider again")

  let store = storeFor(fixture, order)
  let candidates = A.listCandidates(store)
  expect(Belt.Array.length(candidates) == 1, "stale replay duplicated or discarded historical output")
  expect(candidates[0].candidateHash == first.candidate.candidateHash, "stale replay changed candidate identity")
  let dispositions = A.listDispositions(store)
  expect(Belt.Array.length(dispositions) == 1, "stale replay lacks an exclusion disposition")
  expect(dispositions[0].kind == A.Stale, "stale replay received the wrong disposition")
  expect(
    dispositions[0].candidateHash == first.candidate.candidateHash,
    "stale replay disposition is not bound to the historical candidate",
  )
  expect(
    currentTarget(fixture.stateDir).state == S.Superseded,
    "stale idempotent replay did not terminate obsolete lifecycle authority",
  )
}

validExecutionIsQuarantinedAndIdempotent()
explicitSignedCommandIsMandatory()
providerBindingIsExact()
staleAuthorityBeforeAuthorizeMakesZeroCalls()
staleAuthorityBeforeSubmitMakesZeroCalls()
unprovedProviderFailuresAreUnknownAndNeverRetry()
invalidProviderOutputFailsClosed()
driftDuringProviderCallPreservesStaleQuarantine()
immutableReferenceDriftDuringSubmissionIsStale()
idempotentReplayRevalidatesCurrentAuthority()
attemptCeilingSpansSingleUseAuthorizations()

Js.log("PASS - production gateway authorization, fail-closed execution, and quarantine contract")
