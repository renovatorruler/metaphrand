/* Generic orchestration above the production authority compiler, lifecycle
   ledger, execution gateway, independent inspection, and immutable review
   store. No provider or inspector implementation is embedded here. */

exception ControllerError(string)

type blocker = {id: string, code: string, subject: string, message: string}
type reconcileStatus =
  | ReadyForExecution
  | ReconciliationBlocked
  | LifecycleCurrent(Production_State.lifecycle)
type reconciliation = {
  targetId: string,
  status: reconcileStatus,
  workOrder: option<Production_WorkOrder.workOrder>,
  blockers: array<blocker>,
  eventIds: array<string>,
}

type inspectionRequest = {
  job: Production_Inspection.job,
  candidate: Production_ArtifactStore.candidate,
}
type inspector
type inspectionResult = {
  candidate: Production_ArtifactStore.candidate,
  report: Production_Inspection.report,
  adjudication: Production_Inspection.adjudication,
  record: Production_ArtifactStore.inspection,
  lifecycleEvent: option<Production_State.event>,
}

type humanVerdict = HumanPass | HumanFail | HumanUnknown
type humanAnswer = {
  requirementId: string,
  verdict: humanVerdict,
  evidence: string,
}
type reviewResult = {
  record: Production_ArtifactStore.reviewRecord,
  lifecycleEvent: Production_State.event,
}

let registerInspector: (
  ~packetPath: string,
  ~adapterId: string,
  ~credentialText: string,
  ~inspect: inspectionRequest => result<string, string>,
) => inspector
let inspectorId: inspector => string
let inspectorPrincipalId: inspector => string

/* Reconstructs authority from packet bytes, reconciles the target's durable
   lifecycle, and atomically rebuilds canonical queues/ready.json and
   queues/blocked.json. Exact repeats are idempotent. */
let reconcile: (~packetPath: string, ~stateDir: string, ~targetId: string) => reconciliation
let explain: reconciliation => string

/* Returns the exact, deterministic execution binding a human authorizer must
   sign. It performs the same reconciliation and preflight used by execute. */
let executionAuthorizationBinding: (
  ~packetPath: string,
  ~stateDir: string,
  ~targetId: string,
  ~provider: Production_Gateway.provider,
) => string

/* Execution cannot bypass opaque preflight clearance, a content-bound signed
   human command, or the sole gateway. */
let execute: (
  ~packetPath: string,
  ~stateDir: string,
  ~targetId: string,
  ~provider: Production_Gateway.provider,
  ~authorizationCommandText: string,
) => Production_Gateway.execution

/* Inspector output is an encoded production.inspection-report/v1 document.
   Malformed, incomplete, identity-mismatched, FAIL, and UNKNOWN evidence all
   fail closed and can never create review eligibility. */
let inspectCandidate: (
  ~packetPath: string,
  ~stateDir: string,
  ~targetId: string,
  ~candidateHash: string,
  ~inspector: inspector,
) => inspectionResult

/* Builds a deterministic capped batch only from candidates whose immutable
   PASS-only evidence agrees with a current review_ready lifecycle event. */
let createReviewBatch: (
  ~packetPath: string,
  ~stateDir: string,
  ~targetId: string,
) => option<Production_ArtifactStore.reviewBatch>

/* Human review answers every human-only acceptance item with evidence before
   the immutable approve/reject decision is recorded. The first function
   returns the exact binding a packet-authorized reviewer must sign. */
let reviewCommandBinding: (
  ~packetPath: string,
  ~stateDir: string,
  ~targetId: string,
  ~batchHash: string,
  ~candidateHash: string,
  ~decision: Production_ArtifactStore.reviewDecision,
  ~answers: array<humanAnswer>,
  ~note: string,
) => string

let recordHumanReview: (
  ~packetPath: string,
  ~stateDir: string,
  ~targetId: string,
  ~batchHash: string,
  ~candidateHash: string,
  ~commandText: string,
  ~decision: Production_ArtifactStore.reviewDecision,
  ~answers: array<humanAnswer>,
  ~note: string,
) => reviewResult
