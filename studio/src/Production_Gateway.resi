/* Sole execution boundary for the generic production control plane. */

exception GatewayError(string)

type authorization
type request = {
  authorizationId: string,
  packetHash: string,
  workOrderHash: string,
  targetId: string,
  operation: string,
  canonicalWorkOrder: string,
  references: array<Production_WorkOrder.reference>,
}
type providerOutput = {content: string, contentType: string, providerReceipt: string}
type provider
type execution = {
  candidate: Production_ArtifactStore.candidate,
  attempt: int,
  receiptHash: string,
  reused: bool,
  quarantinedStale: bool,
}
type recovery = {changed: bool, message: string}

let registerProvider: (
  ~packetPath: string,
  ~adapterId: string,
  ~credentialText: string,
  ~submit: request => result<providerOutput, string>,
) => provider
let authorizationBinding: (
  ~cleared: Production_Preflight.cleared,
  ~provider: provider,
) => string
let authorize: (
  ~cleared: Production_Preflight.cleared,
  ~provider: provider,
  ~commandText: string,
) => authorization
let recover: (~packetPath: string, ~stateDir: string, ~targetId: string) => recovery
/* Read-only, exact revalidation used before inspection and human review. It
   checks the candidate, terminal execution receipt, packet, dependency-event
   proofs, and immutable reference snapshots as one authority unit. */
let candidateAuthorityCurrent: (
  ~packetPath: string,
  ~stateDir: string,
  ~candidate: Production_ArtifactStore.candidate,
) => bool
let execute: (~authorization: authorization, ~provider: provider) => execution
