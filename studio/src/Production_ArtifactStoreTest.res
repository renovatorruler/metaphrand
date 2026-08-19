/* Zero-network, zero-provider regression tests for the generic immutable
 artifact/review store. Every fixture lives beneath a fresh OS temp dir. */

module B = Cinema_Backends
module Store = Production_ArtifactStore
module L = Production_Lease

@module("node:fs") external symlinkSync: (string, string) => unit = "symlinkSync"
@val @scope("process") external argv: array<string> = "argv"

let fail = message => {
  Js.Console.error("FAIL - " ++ message)
  assert(false)
}

let check = (condition, message) =>
  if !condition {
    fail(message)
  }

let expectFailure = (label, operation) => {
  let failed = try {
    operation()
    false
  } catch {
  | Store.StoreError(_) => true
  | Production_OutputSafety.OutputSafetyError(_) => true
  | _ => true
  }
  check(failed, label ++ " should fail closed")
}

let freshRoot = label => {
  let B.Path(path) = B.tempDir("production-artifact-" ++ label ++ "-")
  path
}

let packetHash = B.sha256Text("synthetic packet v1")
let workOrderHash = B.sha256Text("synthetic work order v1")
let producerId = "synthetic-fake-producer"
let targetId = "T-SYNTHETIC-STORE"
let authorizationId = "AUTH-" ++ B.sha256Text("synthetic authorization 1")
let providerReceiptHash = B.sha256Text("synthetic provider receipt 1")

let passed = (store, text, report) => {
  let candidate = Store.putTextCandidate(
    ~store,
    ~producerId,
    ~targetId,
    ~authorizationId,
    ~attempt=1,
    ~providerReceiptHash,
    ~packetHash,
    ~workOrderHash,
    ~text,
  )
  let inspection = Store.recordInspection(
    ~store,
    ~candidate,
    ~reportText=report,
    ~inspectorId="fake-independent-inspector",
    ~verdict=Store.Pass,
  )
  (candidate, inspection)
}

let immutableObjectsAndRestart = () => {
  let root = freshRoot("objects")
  let store = Store.openStore(~root, ~reviewBatchSize=3)
  let text = "synthetic candidate bytes: alpha"
  let candidate = Store.putTextCandidate(
    ~store,
    ~producerId,
    ~targetId,
    ~authorizationId,
    ~attempt=1,
    ~providerReceiptHash,
    ~packetHash,
    ~workOrderHash,
    ~text,
  )
  check(candidate.artifactHash == B.sha256Text(text), "text artifact must use exact UTF-8 hash")
  check(
    B.sha256File(B.Path(candidate.objectPath)) == candidate.artifactHash,
    "stored text hash must verify",
  )

  let duplicate = Store.putTextCandidate(
    ~store,
    ~producerId,
    ~targetId,
    ~authorizationId,
    ~attempt=1,
    ~providerReceiptHash,
    ~packetHash,
    ~workOrderHash,
    ~text,
  )
  check(duplicate.candidateHash == candidate.candidateHash, "exact repeat must be idempotent")
  check(
    Store.listCandidates(store)->Belt.Array.length == 1,
    "idempotent repeat must not duplicate metadata",
  )
  let independentProducer = Store.putTextCandidate(
    ~store,
    ~producerId="second-synthetic-producer",
    ~targetId,
    ~authorizationId,
    ~attempt=1,
    ~providerReceiptHash,
    ~packetHash,
    ~workOrderHash,
    ~text,
  )
  check(
    independentProducer.candidateHash != candidate.candidateHash,
    "candidate identity must bind the producer independently of identical bytes",
  )
  check(
    Store.listCandidates(store)->Belt.Array.length == 2,
    "the same bytes from a second producer must remain a distinct candidate",
  )

  let source = root ++ "/synthetic-input.bytes"
  B.writeText(B.Path(source), "\u0000opaque synthetic bytes\u0001")
  let fileCandidate = Store.putFileCandidate(
    ~store,
    ~producerId,
    ~targetId,
    ~authorizationId,
    ~attempt=1,
    ~providerReceiptHash,
    ~packetHash,
    ~workOrderHash,
    ~sourcePath=source,
  )
  check(
    fileCandidate.artifactHash == B.sha256File(B.Path(source)),
    "file import must hash exact source bytes",
  )
  let importedHash = fileCandidate.artifactHash
  B.writeText(B.Path(source), "source changed after import")
  check(
    B.sha256File(B.Path(fileCandidate.objectPath)) == importedHash,
    "imported object must not follow source mutation",
  )

  let reopened = Store.openStore(~root, ~reviewBatchSize=3)
  let hashes = Store.listCandidates(reopened)->Belt.Array.map(row => row.candidateHash)
  check(
    hashes->Belt.Array.some(hash => hash == candidate.candidateHash),
    "restart must recover text candidate",
  )
  check(
    hashes->Belt.Array.some(hash => hash == fileCandidate.candidateHash),
    "restart must recover file candidate",
  )
  Js.log("ok - immutable text/file objects and restart recovery")
}

let executionProvenanceIdentityAndTamper = () => {
  let root = freshRoot("execution-provenance")
  let store = Store.openStore(~root, ~reviewBatchSize=3)
  let text = "byte-identical provider output"
  let authorizationA = "AUTH-" ++ B.sha256Text("authorization A")
  let authorizationB = "AUTH-" ++ B.sha256Text("authorization B")
  let receiptA = B.sha256Text("provider receipt A")
  let receiptB = B.sha256Text("provider receipt B")
  let create = (~authorizationId, ~attempt, ~providerReceiptHash) =>
    Store.putTextCandidate(
      ~store,
      ~producerId,
      ~targetId,
      ~authorizationId,
      ~attempt,
      ~providerReceiptHash,
      ~packetHash,
      ~workOrderHash,
      ~text,
    )
  let first = create(~authorizationId=authorizationA, ~attempt=1, ~providerReceiptHash=receiptA)
  let otherAuthorization = create(
    ~authorizationId=authorizationB,
    ~attempt=1,
    ~providerReceiptHash=receiptA,
  )
  let otherAttempt = create(
    ~authorizationId=authorizationA,
    ~attempt=2,
    ~providerReceiptHash=receiptA,
  )
  let otherReceipt = create(
    ~authorizationId=authorizationA,
    ~attempt=1,
    ~providerReceiptHash=receiptB,
  )
  let rows = [first, otherAuthorization, otherAttempt, otherReceipt]
  check(
    rows->Belt.Array.every(row => row.artifactHash == first.artifactHash),
    "byte-identical executions must share their content-addressed artifact",
  )
  check(
    otherAuthorization.candidateHash != first.candidateHash,
    "authorizationId must participate in candidate identity",
  )
  check(
    otherAttempt.candidateHash != first.candidateHash,
    "global attempt must participate in candidate identity",
  )
  check(
    otherReceipt.candidateHash != first.candidateHash,
    "provider receipt must participate in candidate identity",
  )
  check(
    Store.listCandidates(store)->Belt.Array.length == 4,
    "four execution provenances must persist as four immutable candidate records",
  )

  let forgedAuthorization = {...first, authorizationId: authorizationB}
  expectFailure("in-memory authorization provenance tamper", () => {
    Store.recordInspection(
      ~store,
      ~candidate=forgedAuthorization,
      ~reportText="must not persist",
      ~inspectorId="synthetic-inspector",
      ~verdict=Store.Pass,
    )->ignore
  })
  let forgedAttempt = {...first, attempt: 9}
  expectFailure("in-memory attempt provenance tamper", () => {
    Store.recordDisposition(
      ~store,
      ~candidate=forgedAttempt,
      ~kind=Store.Stale,
      ~reason="must not persist",
      ~supersededBy=None,
    )->ignore
  })
  let forgedReceipt = {...first, providerReceiptHash: receiptB}
  expectFailure("in-memory provider receipt provenance tamper", () => {
    Store.recordInspection(
      ~store,
      ~candidate=forgedReceipt,
      ~reportText="must not persist",
      ~inspectorId="synthetic-inspector",
      ~verdict=Store.Pass,
    )->ignore
  })

  let malformedRoot = freshRoot("malformed-provenance")
  let malformedStore = Store.openStore(~root=malformedRoot, ~reviewBatchSize=3)
  let malformed = (~authorizationId, ~attempt, ~providerReceiptHash) =>
    Store.putTextCandidate(
      ~store=malformedStore,
      ~producerId,
      ~targetId,
      ~authorizationId,
      ~attempt,
      ~providerReceiptHash,
      ~packetHash,
      ~workOrderHash,
      ~text,
    )->ignore
  expectFailure("malformed authorizationId", () =>
    malformed(~authorizationId=B.sha256Text("missing AUTH prefix"), ~attempt=1, ~providerReceiptHash=receiptA)
  )
  expectFailure("zero global attempt", () =>
    malformed(~authorizationId=authorizationA, ~attempt=0, ~providerReceiptHash=receiptA)
  )
  expectFailure("negative global attempt", () =>
    malformed(~authorizationId=authorizationA, ~attempt=-1, ~providerReceiptHash=receiptA)
  )
  expectFailure("malformed provider receipt hash", () =>
    malformed(~authorizationId=authorizationA, ~attempt=1, ~providerReceiptHash="not-a-hash")
  )
  check(
    Store.listCandidates(malformedStore)->Belt.Array.length == 0,
    "malformed execution provenance must not create candidate records",
  )

  let recordPath = root ++ "/records/candidates/" ++ first.candidateHash ++ ".json"
  let original = B.readText(B.Path(recordPath))
  B.writeText(B.Path(recordPath), Js.String2.replace(original, `"attempt":1`, `"attempt":7`))
  expectFailure("durable candidate provenance tamper", () =>
    Store.listCandidates(Store.openStore(~root, ~reviewBatchSize=3))->ignore
  )
  Js.log("ok - execution provenance identity, validation, and tamper rejection")
}

let reviewEligibilityAndBatches = () => {
  let root = freshRoot("review")
  let store = Store.openStore(~root, ~reviewBatchSize=2)
  let (passA, inspectA) = passed(store, "candidate A", "A passes all assertions")
  let (passB, _) = passed(store, "candidate B", "B passes all assertions")
  let (passC, _) = passed(store, "candidate C", "C passes all assertions")
  let otherTarget = Store.putTextCandidate(
    ~store,
    ~producerId,
    ~targetId="T-OTHER-STORE",
    ~authorizationId,
    ~attempt=1,
    ~providerReceiptHash,
    ~packetHash,
    ~workOrderHash,
    ~text="other target candidate",
  )
  Store.recordInspection(
    ~store,
    ~candidate=otherTarget,
    ~reportText="other target passes",
    ~inspectorId="fake-independent-inspector",
    ~verdict=Store.Pass,
  )->ignore

  let failed = Store.putTextCandidate(
    ~store,
    ~producerId,
    ~targetId,
    ~authorizationId,
    ~attempt=1,
    ~providerReceiptHash,
    ~packetHash,
    ~workOrderHash,
    ~text="failed candidate",
  )
  let _ = Store.recordInspection(
    ~store,
    ~candidate=failed,
    ~reportText="one assertion failed",
    ~inspectorId="fake-independent-inspector",
    ~verdict=Store.Fail,
  )
  let unknown = Store.putTextCandidate(
    ~store,
    ~producerId,
    ~targetId,
    ~authorizationId,
    ~attempt=1,
    ~providerReceiptHash,
    ~packetHash,
    ~workOrderHash,
    ~text="unknown candidate",
  )
  let _ = Store.recordInspection(
    ~store,
    ~candidate=unknown,
    ~reportText="evidence is inconclusive",
    ~inspectorId="fake-independent-inspector",
    ~verdict=Store.Unknown,
  )
  let _uninspected = Store.putTextCandidate(
    ~store,
    ~producerId,
    ~targetId,
    ~authorizationId,
    ~attempt=1,
    ~providerReceiptHash,
    ~packetHash,
    ~workOrderHash,
    ~text="uninspected candidate",
  )
  let (disposed, _) = passed(store, "disposed candidate", "passed before becoming stale")
  let _ = Store.recordDisposition(
    ~store,
    ~candidate=disposed,
    ~kind=Store.Stale,
    ~reason="authority changed",
    ~supersededBy=None,
  )

  let first = Store.createReviewBatch(~store, ~targetId, ~packetHash, ~workOrderHash)
    ->Belt.Option.getExn
  let second = Store.createReviewBatch(~store, ~targetId, ~packetHash, ~workOrderHash)
    ->Belt.Option.getExn
  check(first.entries->Belt.Array.length == 2, "first batch must honor size cap")
  check(
    second.entries->Belt.Array.length == 1,
    "second batch must contain remaining eligible candidate",
  )
  check(
    Store.createReviewBatch(~store, ~targetId, ~packetHash, ~workOrderHash) == None,
    "eligible candidates must be batched only once",
  )

  let batched =
    Belt.Array.concat(first.entries, second.entries)->Belt.Array.map(entry => entry.candidateHash)
  let expected = [passA.candidateHash, passB.candidateHash, passC.candidateHash]
  expected->Belt.Array.forEach(hash =>
    check(
      batched->Belt.Array.some(actual => actual == hash),
      "every pass-only candidate must be batched",
    )
  )
  check(batched->Belt.Array.length == 3, "batch must contain only reviewable candidates")
  check(
    !(batched->Belt.Array.some(hash => hash == otherTarget.candidateHash)),
    "review batches must not include a candidate from another target",
  )
  check(
    !(batched->Belt.Array.some(hash => hash == failed.candidateHash)),
    "FAIL must remain quarantined",
  )
  check(
    !(batched->Belt.Array.some(hash => hash == unknown.candidateHash)),
    "UNKNOWN must remain quarantined",
  )
  check(
    !(batched->Belt.Array.some(hash => hash == disposed.candidateHash)),
    "disposition must exclude candidate",
  )

  let batchForA =
    first.entries->Belt.Array.some(entry => entry.candidateHash == passA.candidateHash)
      ? first
      : second
  let review = Store.recordReview(
    ~store,
    ~batchHash=batchForA.batchHash,
    ~candidateHash=passA.candidateHash,
    ~reviewerId="synthetic-reviewer",
    ~decision=Store.Approve,
    ~note="approved synthetic fixture",
  )
  check(review.packetHash == packetHash, "approval must bind exact packet hash")
  check(review.workOrderHash == workOrderHash, "approval must bind exact work-order hash")
  check(review.artifactHash == passA.artifactHash, "approval must bind exact artifact hash")
  check(
    review.reportHashes->Belt.Array.length == 1 &&
      Belt.Array.getExn(review.reportHashes, 0) == inspectA.reportHash,
    "approval must bind exact inspection report hashes",
  )
  expectFailure("conflicting second decision", () => {
    let _ = Store.recordReview(
      ~store,
      ~batchHash=batchForA.batchHash,
      ~candidateHash=passA.candidateHash,
      ~reviewerId="other-reviewer",
      ~decision=Store.Reject,
      ~note="conflict",
    )
  })
  let otherBatch = Store.createReviewBatch(
    ~store,
    ~targetId="T-OTHER-STORE",
    ~packetHash,
    ~workOrderHash,
  )->Belt.Option.getExn
  check(
    otherBatch.targetId == "T-OTHER-STORE" && otherBatch.entries->Belt.Array.length == 1 &&
      otherBatch.entries[0].candidateHash == otherTarget.candidateHash,
    "other target candidate must remain eligible only for its own batch",
  )
  let reopened = Store.openStore(~root, ~reviewBatchSize=2)
  check(Store.listReviewBatches(reopened)->Belt.Array.length == 3, "restart must recover batches")
  check(Store.listReviews(reopened)->Belt.Array.length == 1, "restart must recover exact review")
  Js.log("ok - fail-closed eligibility, capped batches, once-only review, exact approvals")
}

let deterministicOrdering = () => {
  let rootA = freshRoot("determinism-a")
  let rootB = freshRoot("determinism-b")
  let storeA = Store.openStore(~root=rootA, ~reviewBatchSize=10)
  let storeB = Store.openStore(~root=rootB, ~reviewBatchSize=10)
  let _ = passed(storeA, "zeta", "zeta report")
  let _ = passed(storeA, "alpha", "alpha report")
  let _ = passed(storeA, "middle", "middle report")
  let _ = passed(storeB, "middle", "middle report")
  let _ = passed(storeB, "alpha", "alpha report")
  let _ = passed(storeB, "zeta", "zeta report")
  let batchA = Store.createReviewBatch(~store=storeA, ~targetId, ~packetHash, ~workOrderHash)
    ->Belt.Option.getExn
  let batchB = Store.createReviewBatch(~store=storeB, ~targetId, ~packetHash, ~workOrderHash)
    ->Belt.Option.getExn
  check(
    batchA.batchHash == batchB.batchHash,
    "batch hash must not depend on insertion order or root",
  )
  let orderA = batchA.entries->Belt.Array.map(entry => entry.candidateHash)->Js.Array2.joinWith(",")
  let orderB = batchB.entries->Belt.Array.map(entry => entry.candidateHash)->Js.Array2.joinWith(",")
  check(orderA == orderB, "batch ordering must be stable across independent stores")
  Js.log("ok - deterministic batch ordering and hash")
}

let overlappingBatchClaimsFailClosed = () => {
  let root = freshRoot("overlapping-batches")
  let store = Store.openStore(~root, ~reviewBatchSize=1)
  let (candidateA, inspectionA) = passed(store, "eligible candidate A", "candidate A passes")
  let (candidateB, inspectionB) = passed(store, "eligible candidate B", "candidate B passes")
  let batch = Store.createReviewBatch(~store, ~targetId, ~packetHash, ~workOrderHash)
    ->Belt.Option.getExn
  let claimedEntry = batch.entries[0]
  let (otherCandidate, otherInspection) =
    claimedEntry.candidateHash == candidateA.candidateHash
      ? (candidateB, inspectionB)
      : (candidateA, inspectionA)
  let otherEntry: Store.reviewEntry = {
    candidateHash: otherCandidate.candidateHash,
    targetId: otherCandidate.targetId,
    packetHash: otherCandidate.packetHash,
    workOrderHash: otherCandidate.workOrderHash,
    artifactHash: otherCandidate.artifactHash,
    reportHashes: [otherInspection.reportHash],
  }
  let quote = value => Js.Json.stringify(Js.Json.string(value))
  let entryJson = (entry: Store.reviewEntry) => {
    let reports = entry.reportHashes->Belt.Array.map(quote)->Js.Array2.joinWith(",")
    "{" ++
    "\"candidateHash\":" ++ quote(entry.candidateHash) ++ "," ++
    "\"targetId\":" ++ quote(entry.targetId) ++ "," ++
    "\"packetHash\":" ++ quote(entry.packetHash) ++ "," ++
    "\"workOrderHash\":" ++ quote(entry.workOrderHash) ++ "," ++
    "\"artifactHash\":" ++ quote(entry.artifactHash) ++ "," ++
    "\"reportHashes\":[" ++ reports ++ "]}"
  }
  /* This is a correctly content-addressed second immutable batch, but it
     overlaps the first as an old racing writer could have done. A restart must
     reject that state rather than silently presenting both. */
  let overlappingBody =
    "{\"schema\":\"production-review-batch/v1\",\"targetId\":" ++
    quote(targetId) ++ ",\"entries\":[" ++ entryJson(claimedEntry) ++ "," ++
    entryJson(otherEntry) ++ "]}"
  let overlappingHash = B.sha256Text(overlappingBody)
  B.writeText(
    B.Path(root ++ "/records/review-batches/" ++ overlappingHash ++ ".json"),
    overlappingBody,
  )
  expectFailure("overlapping immutable review-batch claims", () =>
    Store.listReviewBatches(Store.openStore(~root, ~reviewBatchSize=1))->ignore
  )
  Js.log("ok - overlapping immutable review-batch claims fail closed")
}

let reviewBatchLeasePath = "leases/review-batches.sqlite"
let concurrentTargetId = "T-SYNTHETIC-ARTIFACT-CONCURRENCY"
let concurrentPacketHash = B.sha256Text("synthetic concurrent artifact packet")
let concurrentWorkOrderHash = B.sha256Text("synthetic concurrent artifact work order")
let concurrentAuthorizationId = "AUTH-" ++ B.sha256Text("synthetic concurrent authorization")
let concurrentReceiptHash = B.sha256Text("synthetic concurrent provider receipt")

let arg = index =>
  switch Belt.Array.get(argv, index) {
  | Some(value) => value
  | None => fail("missing cross-process argument " ++ Belt.Int.toString(index))
  }

let mark = (path, body) =>
  if !B.writeTextExclusive(B.Path(path), body) {
    fail("cross-process marker collided at " ++ path)
  }

let waitForGate = path => {
  let deadline = Js.Date.now() +. 10000.0
  while !B.exists(B.Path(path)) && Js.Date.now() < deadline {
    ()
  }
  if !B.exists(B.Path(path)) {
    fail("timed out waiting for cross-process gate " ++ path)
  }
}

let setupConcurrentBatch = (~storeRoot, ~descriptorPath) => {
  let store = Store.openStore(~root=storeRoot, ~reviewBatchSize=1)
  let candidate = Store.putTextCandidate(
    ~store,
    ~producerId="synthetic-concurrency-provider",
    ~targetId=concurrentTargetId,
    ~authorizationId=concurrentAuthorizationId,
    ~attempt=1,
    ~providerReceiptHash=concurrentReceiptHash,
    ~packetHash=concurrentPacketHash,
    ~workOrderHash=concurrentWorkOrderHash,
    ~text="one synthetic candidate may be claimed only once",
  )
  Store.recordInspection(
    ~store,
    ~candidate,
    ~reportText="all synthetic assertions pass",
    ~inspectorId="synthetic-independent-inspector",
    ~verdict=Store.Pass,
  )->ignore
  B.writeText(
    B.Path(descriptorPath),
    concurrentTargetId ++ "\n" ++ concurrentPacketHash ++ "\n" ++ concurrentWorkOrderHash ++
    "\n" ++ candidate.candidateHash ++ "\n",
  )
}

let holdConcurrentBatchLease = (~storeRoot, ~readyPath, ~releaseGatePath) =>
  L.withLease(
    ~stateDir=storeRoot,
    ~relativePath=reviewBatchLeasePath,
    ~resource="artifact review-batch claim",
    () => {
      mark(readyPath, "held\n")
      waitForGate(releaseGatePath)
    },
  )

let claimConcurrentBatch = (
  ~storeRoot,
  ~targetId,
  ~packetHash,
  ~workOrderHash,
  ~readyPath,
  ~startGatePath,
  ~attemptPath,
  ~resultPath,
) => {
  mark(readyPath, "ready\n")
  waitForGate(startGatePath)
  mark(attemptPath, "attempting\n")
  let result = try {
    let store = Store.openStore(~root=storeRoot, ~reviewBatchSize=1)
    switch Store.createReviewBatch(~store, ~targetId, ~packetHash, ~workOrderHash) {
    | Some(batch) =>
      "batched " ++ batch.batchHash ++ " " ++ batch.entries[0].candidateHash ++ "\n"
    | None => "none\n"
    }
  } catch {
  | Store.StoreError(message) => "refused " ++ message ++ "\n"
  }
  mark(resultPath, result)
}

let verifyConcurrentBatch = (~storeRoot, ~candidateHash) => {
  let batches = Store.listReviewBatches(Store.openStore(~root=storeRoot, ~reviewBatchSize=1))
  let claims =
    batches
    ->Belt.Array.flatMap(batch => batch.entries)
    ->Belt.Array.keep(entry => entry.candidateHash == candidateHash)
  check(
    Belt.Array.length(batches) == 1 && Belt.Array.length(claims) == 1,
    "candidate must occur in exactly one immutable review batch",
  )
  Js.log("production-control artifact batching: one candidate, exactly one immutable batch claim")
}

let changedEvidenceFailsClosed = () => {
  let root = freshRoot("evidence-drift")
  let store = Store.openStore(~root, ~reviewBatchSize=2)
  let (candidate, _) = passed(store, "candidate", "initial pass")
  let batch = Store.createReviewBatch(~store, ~targetId, ~packetHash, ~workOrderHash)
    ->Belt.Option.getExn
  let _ = Store.recordInspection(
    ~store,
    ~candidate,
    ~reportText="new evidence cannot determine one assertion",
    ~inspectorId="second-independent-inspector",
    ~verdict=Store.Unknown,
  )
  expectFailure("inspection evidence drift after batch", () => {
    let _ = Store.recordReview(
      ~store,
      ~batchHash=batch.batchHash,
      ~candidateHash=candidate.candidateHash,
      ~reviewerId="synthetic-reviewer",
      ~decision=Store.Approve,
      ~note="must not be accepted",
    )
  })
  Js.log("ok - post-batch evidence drift fails closed")
}

let preservation = () => {
  let root = freshRoot("preservation")
  let store = Store.openStore(~root, ~reviewBatchSize=10)
  let make = text =>
    Store.putTextCandidate(
      ~store,
      ~producerId,
      ~targetId,
      ~authorizationId,
      ~attempt=1,
      ~providerReceiptHash,
      ~packetHash,
      ~workOrderHash,
      ~text,
    )
  let replacement = make("replacement")
  let rows = [
    (make("rejected"), Store.Rejected, "human rejected", None),
    (make("stale"), Store.Stale, "authority drift", None),
    (make("quarantined"), Store.Quarantined, "policy quarantine", None),
    (
      make("superseded"),
      Store.Superseded,
      "better candidate exists",
      Some(replacement.candidateHash),
    ),
    (make("reusable"), Store.Reusable, "useful fragment, not target candidate", None),
  ]
  rows->Belt.Array.forEach(((candidate, kind, reason, supersededBy)) => {
    let _ = Store.recordDisposition(~store, ~candidate, ~kind, ~reason, ~supersededBy)
  })
  let reopened = Store.openStore(~root, ~reviewBatchSize=10)
  check(
    Store.listDispositions(reopened)->Belt.Array.length == 5,
    "all historical dispositions must persist",
  )
  check(
    Store.listCandidates(reopened)->Belt.Array.length == 6,
    "disposed candidates and replacement must persist",
  )
  check(
    Store.createReviewBatch(~store=reopened, ~targetId, ~packetHash, ~workOrderHash) == None,
    "uninspected/disposed history must not enter review",
  )
  Js.log("ok - rejected/stale/quarantined/superseded/reusable history is preserved")
}

let filesystemSafety = () => {
  let root = freshRoot("safety")
  let store = Store.openStore(~root, ~reviewBatchSize=2)
  expectFailure("path traversal disguised as authority hash", () => {
    let _ = Store.putTextCandidate(
      ~store,
      ~producerId,
      ~targetId,
      ~authorizationId,
      ~attempt=1,
      ~providerReceiptHash,
      ~packetHash="../../outside",
      ~workOrderHash,
      ~text="never written",
    )
  })

  let collisionText = "intended immutable body"
  let collisionHash = B.sha256Text(collisionText)
  let collisionPath =
    root ++
    "/objects/sha256/" ++
    Js.String2.slice(collisionHash, ~from=0, ~to_=2) ++
    "/" ++
    collisionHash ++ ".txt"
  B.ensureDirPath(
    B.Path(root ++ "/objects/sha256/" ++ Js.String2.slice(collisionHash, ~from=0, ~to_=2)),
  )
  B.writeText(B.Path(collisionPath), "different occupant")
  expectFailure("immutable object collision", () => {
    let _ = Store.putTextCandidate(
      ~store,
      ~producerId,
      ~targetId,
      ~authorizationId,
      ~attempt=1,
      ~providerReceiptHash,
      ~packetHash,
      ~workOrderHash,
      ~text=collisionText,
    )
  })

  let symlinkRoot = freshRoot("symlink")
  let outside = freshRoot("outside")
  let linkedStore = Store.openStore(~root=symlinkRoot, ~reviewBatchSize=2)
  symlinkSync(outside, symlinkRoot ++ "/objects")
  expectFailure("symlink escape", () => {
    let _ = Store.putTextCandidate(
      ~store=linkedStore,
      ~producerId,
      ~targetId,
      ~authorizationId,
      ~attempt=1,
      ~providerReceiptHash,
      ~packetHash,
      ~workOrderHash,
      ~text="must not escape root",
    )
  })
  check(
    B.readDir(B.Path(outside))->Belt.Array.length == 0,
    "symlink escape must not write outside store",
  )
  Js.log("ok - traversal, collision, and symlink escape are rejected")
}

let runUnitTests = () => {
  immutableObjectsAndRestart()
  executionProvenanceIdentityAndTamper()
  reviewEligibilityAndBatches()
  deterministicOrdering()
  overlappingBatchClaimsFailClosed()
  changedEvidenceFailsClosed()
  preservation()
  filesystemSafety()
  Js.log("PRODUCTION ARTIFACT STORE TESTS PASSED")
}

let main = () =>
  switch Belt.Array.get(argv, 2) {
  | None => runUnitTests()
  | Some("concurrency-setup") =>
    setupConcurrentBatch(~storeRoot=arg(3), ~descriptorPath=arg(4))
  | Some("concurrency-lease-hold") =>
    holdConcurrentBatchLease(~storeRoot=arg(3), ~readyPath=arg(4), ~releaseGatePath=arg(5))
  | Some("concurrency-worker") =>
    claimConcurrentBatch(
      ~storeRoot=arg(3),
      ~targetId=arg(4),
      ~packetHash=arg(5),
      ~workOrderHash=arg(6),
      ~readyPath=arg(7),
      ~startGatePath=arg(8),
      ~attemptPath=arg(9),
      ~resultPath=arg(10),
    )
  | Some("concurrency-verify") =>
    verifyConcurrentBatch(~storeRoot=arg(3), ~candidateHash=arg(4))
  | Some(mode) => fail("unknown artifact-store test mode " ++ mode)
  }

main()
