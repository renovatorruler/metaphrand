/* Crash-safe, provider-free execution journal. Each canonical, content-hashed
   terminal transition is the authoritative execution receipt; no detached
   unauthenticated receipt file exists beside it.

   The gateway records an immutable authorization before it claims an attempt,
   and records `Submitting` immediately before crossing the provider boundary.
   On restart, `recoverInterrupted` can therefore distinguish work which
   certainly never reached a provider from work whose provider outcome is
   unknowable. */

exception JournalError(string)

type status =
  | Claimed
  | Submitting
  | CandidateQuarantine
  | StaleQuarantine
  | Failed
  | BlockedPreSubmit
  | InterruptedUnknown

type authorizationIntent

type authorizationRecord = {
  authorizationId: string,
  recordHash: string,
  targetId: string,
  packetHash: string,
  workOrderHash: string,
  providerId: string,
  providerPrincipalId: string,
  authorizerPrincipalId: string,
  commandId: string,
  authorizedEventId: string,
  dependencyProofHash: string,
  referenceSetHash: string,
  maxAttempts: int,
}

type transition = {
  transitionId: string,
  recordHash: string,
  authorizationId: string,
  targetId: string,
  packetHash: string,
  workOrderHash: string,
  attempt: int,
  sequence: int,
  previousTransitionId: option<string>,
  status: status,
  candidateHash: option<string>,
  artifactHash: option<string>,
  providerReceiptHash: option<string>,
  reason: string,
}

type attemptRecord = {
  authorizationId: string,
  targetId: string,
  attempt: int,
  transitions: array<transition>,
  current: transition,
}

type snapshot = {
  authorizations: array<authorizationRecord>,
  attempts: array<attemptRecord>,
}

type recoveryKind =
  | UnclaimedAuthorization
  | InterruptedBeforeSubmit
  | InterruptedDuringSubmit
  | Terminal(status)

type recoveryClassification = {
  authorizationId: string,
  targetId: string,
  attempt: option<int>,
  kind: recoveryKind,
}

let statusName: status => string
let recoveryKindName: recoveryKind => string

let createAuthorizationIntent: (
  ~targetId: string,
  ~packetHash: string,
  ~workOrderHash: string,
  ~providerId: string,
  ~providerPrincipalId: string,
  ~authorizerPrincipalId: string,
  ~commandId: string,
  ~authorizedEventId: string,
  ~dependencyProofHash: string,
  ~referenceSetHash: string,
  ~maxAttempts: int,
) => authorizationIntent

let intentId: authorizationIntent => string

/* Idempotent for identical content; a collision with different bytes fails. */
let persistAuthorization: (~stateDir: string, ~intent: authorizationIntent) => authorizationRecord

/* Atomically consumes a previously unclaimed single-use authorization and
 allocates the next contiguous attempt number for its target/work-order. */
let claimNextAttempt: (
  ~stateDir: string,
  ~authorizationId: string,
  ~reason: string,
) => transition

/* Appends the next legal transition for one attempt. A new Claimed transition
   must use the next authority-scoped attempt number and consumes that
   authorization. Repeating the exact current transition is idempotent. */
let recordStatus: (
  ~stateDir: string,
  ~authorizationId: string,
  ~attempt: int,
  ~status: status,
  ~candidateHash: string=?,
  ~artifactHash: string=?,
  ~providerReceiptHash: string=?,
  ~reason: string,
) => transition

/* Reconstructs the entire journal solely from immutable disk records. It
   ignores dot-prefixed *.pending files left by a crash, but fails on every
   malformed, misnamed, branched, missing, or contradictory committed record. */
let load: (~stateDir: string) => snapshot

/* Pure, sorted restart classification. */
let classify: snapshot => array<recoveryClassification>

/* Provider-free, state-idempotent repair. A dangling Claimed attempt becomes
   BlockedPreSubmit; a dangling Submitting attempt becomes
   InterruptedUnknown. Unclaimed authorizations remain explicitly classified
   for the lifecycle reconciler. */
let recoverInterrupted: (~stateDir: string) => snapshot
