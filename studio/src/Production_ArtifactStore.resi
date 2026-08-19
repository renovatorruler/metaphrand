/* Generic, provider-free persistence for production candidates and review.
   Every durable value is immutable and bound to the authority hashes that
   produced it. The store never deletes historical records. */

exception StoreError(string)

type store

type contentKind = Text | File
type inspectionVerdict = Pass | Fail | Unknown
type dispositionKind = Rejected | Stale | Quarantined | Superseded | Reusable
type reviewDecision = Approve | Reject

type candidate = {
  candidateHash: string,
  producerId: string,
  targetId: string,
  authorizationId: string,
  attempt: int,
  providerReceiptHash: string,
  packetHash: string,
  workOrderHash: string,
  artifactHash: string,
  contentKind: contentKind,
  objectPath: string,
}

type inspection = {
  inspectionHash: string,
  candidateHash: string,
  packetHash: string,
  workOrderHash: string,
  artifactHash: string,
  reportHash: string,
  inspectorId: string,
  verdict: inspectionVerdict,
}

type disposition = {
  dispositionHash: string,
  candidateHash: string,
  packetHash: string,
  workOrderHash: string,
  artifactHash: string,
  kind: dispositionKind,
  reason: string,
  supersededBy: option<string>,
  reportHashes: array<string>,
}

type reviewEntry = {
  candidateHash: string,
  targetId: string,
  packetHash: string,
  workOrderHash: string,
  artifactHash: string,
  reportHashes: array<string>,
}

type reviewBatch = {
  batchHash: string,
  targetId: string,
  entries: array<reviewEntry>,
}

type reviewRecord = {
  reviewHash: string,
  batchHash: string,
  candidateHash: string,
  targetId: string,
  packetHash: string,
  workOrderHash: string,
  artifactHash: string,
  reportHashes: array<string>,
  reviewerId: string,
  decision: reviewDecision,
  note: string,
}

let openStore: (~root: string, ~reviewBatchSize: int) => store

/* Text is stored directly. Arbitrary bytes are imported byte-for-byte from a
 source file, without decoding or changing them. Exact repeats are idempotent. */
let putTextCandidate: (
  ~store: store,
  ~producerId: string,
  ~targetId: string,
  ~authorizationId: string,
  ~attempt: int,
  ~providerReceiptHash: string,
  ~packetHash: string,
  ~workOrderHash: string,
  ~text: string,
) => candidate
let putFileCandidate: (
  ~store: store,
  ~producerId: string,
  ~targetId: string,
  ~authorizationId: string,
  ~attempt: int,
  ~providerReceiptHash: string,
  ~packetHash: string,
  ~workOrderHash: string,
  ~sourcePath: string,
) => candidate

/* The report itself is content-addressed. The inspection record binds that
 report to the exact authority and candidate bytes. */
let recordInspection: (
  ~store: store,
  ~candidate: candidate,
  ~reportText: string,
  ~inspectorId: string,
  ~verdict: inspectionVerdict,
) => inspection

/* Dispositions are append-only exclusions. Rejected, stale, explicitly
   quarantined, superseded and reusable-only candidates remain discoverable but
   cannot be placed into a review batch. */
let recordDisposition: (
  ~store: store,
  ~candidate: candidate,
  ~kind: dispositionKind,
  ~reason: string,
  ~supersededBy: option<string>,
) => disposition

/* Atomically claims the next stable batch from every eligible unbatched
   candidate up to the store's configured cap. Concurrent callers sharing a
   root are serialized by a cross-process lease, so one candidate can occur in
   at most one immutable batch. A candidate is eligible only when it has at
   least one PASS, no FAIL/UNKNOWN, and no disposition. */
let createReviewBatch: (
  ~store: store,
  ~targetId: string,
  ~packetHash: string,
  ~workOrderHash: string,
) => option<reviewBatch>

/* The caller selects only a candidate and decision. All authority/report
   bindings are recovered from the immutable batch and revalidated against the
   current store before the review is accepted. */
let recordReview: (
  ~store: store,
  ~batchHash: string,
  ~candidateHash: string,
  ~reviewerId: string,
  ~decision: reviewDecision,
  ~note: string,
) => reviewRecord

let listCandidates: store => array<candidate>
let listInspections: store => array<inspection>
let listDispositions: store => array<disposition>
let listReviewBatches: store => array<reviewBatch>
let listReviews: store => array<reviewRecord>
