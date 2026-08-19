/** Generic, filesystem-independent authority model for production work. */
exception DomainError(string)

type validatorKind = Deterministic | SemanticInspector | HumanOnly
type principalRole = Authorizer | Reviewer | Producer | Inspector
type principal = {
  id: string,
  roles: array<principalRole>,
  publicKeyPem: string,
  decisionIds: array<string>,
  authorityHash: string,
}

type dimensions = {width: float, height: float, depth: float, unit: string}
type entityState = {
  id: string,
  label: string,
  tags: array<string>,
  dimensions: option<dimensions>,
  locationEntityId: option<string>,
}
type entity = {
  id: string,
  label: string,
  kind: string,
  states: array<entityState>,
  decisionIds: array<string>,
  authorityHash: string,
}

type assetStatus =
  | AssetProposed
  | AssetCandidate
  | AssetApproved
  | AssetRejected
  | AssetQuarantined
  | AssetReusable
  | AssetSuperseded

type asset = {
  id: string,
  label: string,
  kind: string,
  status: assetStatus,
  path: option<string>,
  contentSha256: option<string>,
  entityIds: array<string>,
  referenceAssetIds: array<string>,
  decisionIds: array<string>,
  authorityHash: string,
}

type target = {
  id: string,
  purpose: string,
  principalAction: string,
  operation: string,
  declaredActionCount: int,
  declaredContinuousSeconds: float,
  entityIds: array<string>,
  assetIds: array<string>,
  requirementIds: array<string>,
  dependsOnTargetIds: array<string>,
  decisionIds: array<string>,
  authorityHash: string,
}

type continuitySpec = {entityId: string, beforeStateId: string, afterStateId: string}
type presenceSpec = {
  entityId: string,
  stateId: option<string>,
  minimum: int,
  maximum: option<int>,
}
type forbiddenSpec = {entityId: string, stateId: option<string>}
type relativeScaleSpec = {
  subjectEntityId: string,
  subjectStateId: string,
  referenceEntityId: string,
  referenceStateId: string,
  minRatio: float,
  maxRatio: float,
}
type spatialRelation = Inside | Behind | InFrontOf | LeftOf | RightOf | Under | Above | AdjacentTo
type geographySpec = {
  subjectEntityId: string,
  referenceEntityId: string,
  relation: spatialRelation,
}
type cameraSide = CameraLeft | CameraRight | CameraFront | CameraBack | CameraInterior
type cameraSideSpec = {
  side: cameraSide,
  anchorEntityId: string,
  occluderEntityId: option<string>,
}
type shotSize = ExtremeWide | Wide | Full | Medium | CloseUp | ExtremeCloseUp | Insert
type framingSpec = {shotSize: shotSize, requiredEntityIds: array<string>, fullyVisible: bool}
type complexitySpec = {
  maxPrincipalActions: int,
  maxVisibleEntities: int,
  maxContinuousSeconds: float,
}
type referencesSpec = {assetIds: array<string>, exact: bool}

type requirementKind =
  | Continuity(continuitySpec)
  | Presence(presenceSpec)
  | Forbidden(forbiddenSpec)
  | RelativeScale(relativeScaleSpec)
  | Geography(geographySpec)
  | CameraSide(cameraSideSpec)
  | Framing(framingSpec)
  | Complexity(complexitySpec)
  | References(referencesSpec)

type requirement = {
  id: string,
  targetId: string,
  scope: string,
  validator: validatorKind,
  decisionIds: array<string>,
  kind: requirementKind,
  authorityHash: string,
}

type attemptsPolicy = {maxPerTarget: int}
type reviewPolicy = {batchSize: int, requireHumanApproval: bool}
type complexityPolicy = {
  maxPrincipalActions: int,
  maxVisibleEntities: int,
  maxContinuousSeconds: float,
}
type executionPolicy = {requiresExplicitAuthorization: bool}
type policyKind =
  | AttemptsPolicy(attemptsPolicy)
  | ReviewPolicy(reviewPolicy)
  | ComplexityPolicy(complexityPolicy)
  | ExecutionPolicy(executionPolicy)
type policy = {id: string, decisionIds: array<string>, kind: policyKind, authorityHash: string}

type supersede = {supersededBy: string, reason: string}
type approvalBinding = {subjectId: string, contentSha256: string}
type approval = {note: option<string>, bindings: array<approvalBinding>}
type decisionEventKind =
  | ProposeEvent(string)
  | ApproveEvent(approval)
  | RejectEvent(string)
  | ReopenEvent(string)
  | SupersedeEvent(supersede)
type decisionEvent = {
  eventId: string,
  sequence: int,
  previousEventId: option<string>,
  kind: decisionEventKind,
}
type decisionLedger = {
  decisionId: string,
  scope: string,
  dependencies: array<string>,
  events: array<decisionEvent>,
}

/** Packet-level commitment to the complete global decision-event history.
    Per-event hashes protect event contents and predecessor links; this anchor
    additionally makes removal of an otherwise valid newest suffix fail closed. */
type decisionHistoryAnchor = {eventCount: int, headEventId: option<string>}

type decisionStatus =
  | DecisionProposed
  | DecisionApproved
  | DecisionRejected
  | DecisionSuperseded(string)
type reducedDecision = {
  id: string,
  scope: string,
  statement: string,
  dependencies: array<string>,
  status: decisionStatus,
  bindings: array<approvalBinding>,
}
type decisionConflict = {scope: string, decisionIds: array<string>}

type packet = {
  schema: string,
  packetId: string,
  revision: int,
  decisionHistory: decisionHistoryAnchor,
  decisionLedgers: array<decisionLedger>,
  principals: array<principal>,
  entities: array<entity>,
  assets: array<asset>,
  targets: array<target>,
  requirements: array<requirement>,
  policies: array<policy>,
}

type context = {
  packet: packet,
  canonicalHash: string,
  decisions: array<reducedDecision>,
  effectiveDecisionIds: array<string>,
  conflicts: array<decisionConflict>,
  blockers: array<string>,
}

/** Strictly decodes and structurally validates production-packet/v2 JSON. */
let decodePacket: string => packet

/** RFC-style canonical JSON for stable object-key/whitespace-independent hashing. */
let canonicalJson: Js.Json.t => string
let canonicalHashJson: string => string

/** Derives the tamper-evident identifier for a decision event JSON object.
    The event must include sequence, previousEventId, kind, and kind payload;
    any eventId field is deliberately excluded from its own hash. */
let deriveDecisionEventIdJson: (
  ~decisionId: string,
  ~scope: string,
  ~dependencies: array<string>,
  Js.Json.t,
) => string

/** Reconstructs all effective authority from packet bytes alone. */
let reconstruct: string => context

let decisionStatusName: decisionStatus => string
let validatorKindName: validatorKind => string
let principalRoleName: principalRole => string

/** True only when the effective approval for a decision binds the exact
    canonical revision of the governed subject. */
let approvalBinds: (
  context,
  ~decisionId: string,
  ~subjectId: string,
  ~authorityHash: string,
) => bool
