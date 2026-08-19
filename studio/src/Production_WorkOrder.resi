/* Compiles durable authority into one immutable, provider-agnostic work order.
   Provider prompts/requests are derived from this value; they are not an
   independent source of production truth. */

type finding = {code: string, subject: string, message: string}
type acceptance = {
  id: string,
  kind: string,
  requirementKind: Production_Domain.requirementKind,
  validator: Production_Domain.validatorKind,
  description: string,
  decisionIds: array<string>,
}
type reference = {assetId: string, path: string, sha256: string}
type workOrder = {
  schema: string,
  packetId: string,
  packetRevision: int,
  packetHash: string,
  packetPath: string,
  targetId: string,
  purpose: string,
  principalAction: string,
  operation: string,
  declaredActionCount: int,
  declaredContinuousSeconds: float,
  dependencyTargetIds: array<string>,
  references: array<reference>,
  acceptance: array<acceptance>,
  maxAttempts: int,
  reviewBatchSize: int,
  requiresHumanApproval: bool,
  requiresExplicitAuthorization: bool,
  canonical: string,
  hash: string,
}
type evaluation = {workOrder: option<workOrder>, findings: array<finding>}

let compile: (~packetPath: string, ~targetId: string) => evaluation
let encode: workOrder => string
let semanticChecks: workOrder => array<Production_Inspection.check>
let humanQuestions: workOrder => array<acceptance>
let explain: evaluation => string
