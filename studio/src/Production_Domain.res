/* Generic production authority. This module is intentionally pure with the
   exception of SHA-256: it reads no environment variables, paths, clocks, or
   conversation state. The same packet bytes always reconstruct the same
   effective context. */

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

type governedSubject = {
  subjectId: string,
  authorityHash: string,
  decisionIds: array<string>,
}

type hash
@module("node:crypto") external createHash: string => hash = "createHash"
@send external hashUpdate: (hash, string) => hash = "update"
@send external hashDigest: (hash, string) => string = "digest"

let die = message => raise(DomainError(message))

let compareStrings = (left: string, right: string): int => compare(left, right)

let principalRoleName = role =>
  switch role {
  | Authorizer => "authorizer"
  | Reviewer => "reviewer"
  | Producer => "producer"
  | Inspector => "inspector"
  }

let canonicalJson = (json: Js.Json.t): string => {
  let rec encode = value =>
    switch Js.Json.classify(value) {
    | JSONFalse => "false"
    | JSONTrue => "true"
    | JSONNull => "null"
    | JSONString(text) => Js.Json.stringify(Js.Json.string(text))
    | JSONNumber(number) => Js.Json.stringify(Js.Json.number(number))
    | JSONArray(values) => "[" ++ values->Belt.Array.map(encode)->Js.Array2.joinWith(",") ++ "]"
    | JSONObject(object_) => {
        let keys = Js.Dict.keys(object_)
        keys->Js.Array2.sortInPlaceWith(compareStrings)->ignore
        "{" ++
        keys
        ->Belt.Array.map(key =>
          Js.Json.stringify(Js.Json.string(key)) ++
          ":" ++
          encode(Js.Dict.get(object_, key)->Belt.Option.getExn)
        )
        ->Js.Array2.joinWith(",") ++ "}"
      }
    }
  encode(json)
}

let parseJson = raw =>
  try Js.Json.parseExn(raw) catch {
  | _ => die("packet is not valid JSON")
  }

let canonicalHashJson = raw =>
  createHash("sha256")->hashUpdate(canonicalJson(parseJson(raw)))->hashDigest("hex")

let authorityHashJson = json =>
  createHash("sha256")->hashUpdate(canonicalJson(json))->hashDigest("hex")

let sha256Text = text => createHash("sha256")->hashUpdate(text)->hashDigest("hex")

let objectOf = (json, where) =>
  switch Js.Json.decodeObject(json) {
  | Some(value) => value
  | None => die(where ++ " must be an object")
  }

let arrayOf = (json, where) =>
  switch Js.Json.decodeArray(json) {
  | Some(value) => value
  | None => die(where ++ " must be an array")
  }

let assertOnlyKeys = (object_, allowed, where) =>
  Js.Dict.keys(object_)->Belt.Array.forEach(key =>
    if !(allowed->Belt.Array.some(allowedKey => allowedKey == key)) {
      die(where ++ ": unknown field '" ++ key ++ "'")
    }
  )

let requiredJson = (object_, key, where) =>
  switch Js.Dict.get(object_, key) {
  | Some(value) => value
  | None => die(where ++ "." ++ key ++ " is required")
  }

let requiredString = (object_, key, where) =>
  switch requiredJson(object_, key, where)->Js.Json.decodeString {
  | Some(value) if Js.String2.trim(value) != "" => value
  | _ => die(where ++ "." ++ key ++ " must be a nonempty string")
  }

let optionalString = (object_, key, where) =>
  switch Js.Dict.get(object_, key) {
  | None => None
  | Some(value) =>
    switch Js.Json.decodeString(value) {
    | Some(text) if Js.String2.trim(text) != "" => Some(text)
    | _ => die(where ++ "." ++ key ++ " must be a nonempty string when present")
    }
  }

let requiredNullableString = (object_, key, where) =>
  switch Js.Json.classify(requiredJson(object_, key, where)) {
  | JSONNull => None
  | JSONString(text) if Js.String2.trim(text) != "" => Some(text)
  | _ => die(where ++ "." ++ key ++ " must be null or a nonempty string")
  }

let requiredBoolean = (object_, key, where) =>
  switch requiredJson(object_, key, where)->Js.Json.decodeBoolean {
  | Some(value) => value
  | None => die(where ++ "." ++ key ++ " must be a boolean")
  }

let requiredFloat = (object_, key, where) =>
  switch requiredJson(object_, key, where)->Js.Json.decodeNumber {
  | Some(value) if Js.Float.isFinite(value) => value
  | _ => die(where ++ "." ++ key ++ " must be a finite number")
  }

let requiredInt = (object_, key, where, ~minimum) => {
  let value = requiredFloat(object_, key, where)
  let integer = Js.Math.floor_int(value)
  if Belt.Int.toFloat(integer) != value || integer < minimum {
    die(where ++ "." ++ key ++ " must be an integer >= " ++ Belt.Int.toString(minimum))
  }
  integer
}

let optionalInt = (object_, key, where, ~minimum) =>
  switch Js.Dict.get(object_, key) {
  | None => None
  | Some(json) =>
    switch Js.Json.decodeNumber(json) {
    | Some(value) if Js.Float.isFinite(value) => {
        let integer = Js.Math.floor_int(value)
        if Belt.Int.toFloat(integer) != value || integer < minimum {
          die(where ++ "." ++ key ++ " must be an integer >= " ++ Belt.Int.toString(minimum))
        }
        Some(integer)
      }
    | _ => die(where ++ "." ++ key ++ " must be a finite integer when present")
    }
  }

let requiredArray = (object_, key, where) =>
  arrayOf(requiredJson(object_, key, where), where ++ "." ++ key)

let stringsOf = (jsons, where) =>
  jsons->Belt.Array.mapWithIndex((index, json) =>
    switch Js.Json.decodeString(json) {
    | Some(value) if Js.String2.trim(value) != "" => value
    | _ => die(where ++ "[" ++ Belt.Int.toString(index) ++ "] must be a nonempty string")
    }
  )

let requiredStrings = (object_, key, where) =>
  stringsOf(requiredArray(object_, key, where), where ++ "." ++ key)

let requiredNonemptyStrings = (object_, key, where) => {
  let values = requiredStrings(object_, key, where)
  if Belt.Array.length(values) == 0 {
    die(where ++ "." ++ key ++ " must not be empty")
  }
  values
}

let assertUnique = (values: array<string>, where: string) => {
  let seen = Js.Dict.empty()
  values->Belt.Array.forEach(value => {
    if Js.Dict.get(seen, value) != None {
      die(where ++ ": duplicate value '" ++ value ++ "'")
    }
    Js.Dict.set(seen, value, true)
  })
}

let assertStableId = (value: string, where: string) =>
  if !Js.Re.test_(%re("/^[A-Za-z0-9][A-Za-z0-9._:-]*$/"), value) {
    die(where ++ ": '" ++ value ++ "' is not a stable identifier")
  }

let assertStableIds = (values: array<string>, where: string) =>
  values->Belt.Array.forEach(value => assertStableId(value, where))

let decodeDimensions = (json, where) => {
  let row = objectOf(json, where)
  assertOnlyKeys(row, ["width", "height", "depth", "unit"], where)
  let dimensions = {
    width: requiredFloat(row, "width", where),
    height: requiredFloat(row, "height", where),
    depth: requiredFloat(row, "depth", where),
    unit: requiredString(row, "unit", where),
  }
  if dimensions.width <= 0.0 || dimensions.height <= 0.0 || dimensions.depth <= 0.0 {
    die(where ++ ": dimensions must all be greater than zero")
  }
  dimensions
}

let principalRoleOf = (value, where) =>
  switch value {
  | "authorizer" => Authorizer
  | "reviewer" => Reviewer
  | "producer" => Producer
  | "inspector" => Inspector
  | other => die(where ++ ": unknown principal role '" ++ other ++ "'")
  }

let decodePrincipal = (json, index) => {
  let where = "principals[" ++ Belt.Int.toString(index) ++ "]"
  let row = objectOf(json, where)
  assertOnlyKeys(row, ["id", "roles", "publicKeyPem", "decisionIds"], where)
  let roleNames = requiredNonemptyStrings(row, "roles", where)
  assertUnique(roleNames, where ++ ".roles")
  let decisionIds = requiredNonemptyStrings(row, "decisionIds", where)
  assertUnique(decisionIds, where ++ ".decisionIds")
  let publicKeyPem = requiredString(row, "publicKeyPem", where)
  if (
    !Js.String2.includes(publicKeyPem, "-----BEGIN PUBLIC KEY-----") ||
    !Js.String2.includes(publicKeyPem, "-----END PUBLIC KEY-----")
  ) {
    die(where ++ ".publicKeyPem must be a PEM public key")
  }
  {
    id: requiredString(row, "id", where),
    roles: roleNames->Belt.Array.mapWithIndex((index, role) =>
      principalRoleOf(role, where ++ ".roles[" ++ Belt.Int.toString(index) ++ "]")
    ),
    publicKeyPem,
    decisionIds,
    authorityHash: authorityHashJson(json),
  }
}

let decodeEntityState = (json, where) => {
  let row = objectOf(json, where)
  assertOnlyKeys(row, ["id", "label", "tags", "dimensions", "locationEntityId"], where)
  let tags = requiredStrings(row, "tags", where)
  assertUnique(tags, where ++ ".tags")
  {
    id: requiredString(row, "id", where),
    label: requiredString(row, "label", where),
    tags,
    dimensions: switch Js.Dict.get(row, "dimensions") {
    | Some(value) => Some(decodeDimensions(value, where ++ ".dimensions"))
    | None => None
    },
    locationEntityId: optionalString(row, "locationEntityId", where),
  }
}

let decodeEntity = (json, index) => {
  let where = "entities[" ++ Belt.Int.toString(index) ++ "]"
  let row = objectOf(json, where)
  assertOnlyKeys(row, ["id", "label", "kind", "states", "decisionIds"], where)
  let states =
    requiredArray(row, "states", where)->Belt.Array.mapWithIndex((stateIndex, state) =>
      decodeEntityState(state, where ++ ".states[" ++ Belt.Int.toString(stateIndex) ++ "]")
    )
  assertUnique(states->Belt.Array.map(state => state.id), where ++ ".states.id")
  if Belt.Array.length(states) == 0 {
    die(where ++ ".states must not be empty")
  }
  let decisionIds = requiredNonemptyStrings(row, "decisionIds", where)
  assertUnique(decisionIds, where ++ ".decisionIds")
  {
    id: requiredString(row, "id", where),
    label: requiredString(row, "label", where),
    kind: requiredString(row, "kind", where),
    states,
    decisionIds,
    authorityHash: authorityHashJson(json),
  }
}

let assetStatusOf = (value, where) =>
  switch value {
  | "proposed" => AssetProposed
  | "candidate" => AssetCandidate
  | "approved" => AssetApproved
  | "rejected" => AssetRejected
  | "quarantined" => AssetQuarantined
  | "reusable" => AssetReusable
  | "superseded" => AssetSuperseded
  | other => die(where ++ ": unknown asset status '" ++ other ++ "'")
  }

let decodeAsset = (json, index) => {
  let where = "assets[" ++ Belt.Int.toString(index) ++ "]"
  let row = objectOf(json, where)
  assertOnlyKeys(
    row,
    [
      "id",
      "label",
      "kind",
      "status",
      "path",
      "contentSha256",
      "entityIds",
      "referenceAssetIds",
      "decisionIds",
    ],
    where,
  )
  let entityIds = requiredStrings(row, "entityIds", where)
  let referenceAssetIds = requiredStrings(row, "referenceAssetIds", where)
  let decisionIds = requiredNonemptyStrings(row, "decisionIds", where)
  assertUnique(entityIds, where ++ ".entityIds")
  assertUnique(referenceAssetIds, where ++ ".referenceAssetIds")
  assertUnique(decisionIds, where ++ ".decisionIds")
  let contentSha256 = optionalString(row, "contentSha256", where)
  switch contentSha256 {
  | Some(value) if !Js.Re.test_(%re("/^[A-Fa-f0-9]{64}$/"), value) =>
    die(where ++ ".contentSha256 must contain 64 hexadecimal characters")
  | _ => ()
  }
  {
    id: requiredString(row, "id", where),
    label: requiredString(row, "label", where),
    kind: requiredString(row, "kind", where),
    status: assetStatusOf(requiredString(row, "status", where), where ++ ".status"),
    path: optionalString(row, "path", where),
    contentSha256,
    entityIds,
    referenceAssetIds,
    decisionIds,
    authorityHash: authorityHashJson(json),
  }
}

let decodeTarget = (json, index) => {
  let where = "targets[" ++ Belt.Int.toString(index) ++ "]"
  let row = objectOf(json, where)
  assertOnlyKeys(
    row,
    [
      "id",
      "purpose",
      "principalAction",
      "operation",
      "declaredActionCount",
      "declaredContinuousSeconds",
      "entityIds",
      "assetIds",
      "requirementIds",
      "dependsOnTargetIds",
      "decisionIds",
    ],
    where,
  )
  let entityIds = requiredStrings(row, "entityIds", where)
  let assetIds = requiredStrings(row, "assetIds", where)
  let requirementIds = requiredStrings(row, "requirementIds", where)
  let dependsOnTargetIds = requiredStrings(row, "dependsOnTargetIds", where)
  let decisionIds = requiredNonemptyStrings(row, "decisionIds", where)
  assertUnique(entityIds, where ++ ".entityIds")
  assertUnique(assetIds, where ++ ".assetIds")
  assertUnique(requirementIds, where ++ ".requirementIds")
  assertUnique(dependsOnTargetIds, where ++ ".dependsOnTargetIds")
  assertUnique(decisionIds, where ++ ".decisionIds")
  let declaredContinuousSeconds = requiredFloat(row, "declaredContinuousSeconds", where)
  if declaredContinuousSeconds <= 0.0 {
    die(where ++ ".declaredContinuousSeconds must be greater than zero")
  }
  {
    id: requiredString(row, "id", where),
    purpose: requiredString(row, "purpose", where),
    principalAction: requiredString(row, "principalAction", where),
    operation: requiredString(row, "operation", where),
    declaredActionCount: requiredInt(row, "declaredActionCount", where, ~minimum=1),
    declaredContinuousSeconds,
    entityIds,
    assetIds,
    requirementIds,
    dependsOnTargetIds,
    decisionIds,
    authorityHash: authorityHashJson(json),
  }
}

let validatorKindOf = (value, where) =>
  switch value {
  | "deterministic" => Deterministic
  | "semantic_inspector" => SemanticInspector
  | "human_only" => HumanOnly
  | other => die(where ++ ": unknown validator kind '" ++ other ++ "'")
  }

let spatialRelationOf = (value, where) =>
  switch value {
  | "inside" => Inside
  | "behind" => Behind
  | "in_front_of" => InFrontOf
  | "left_of" => LeftOf
  | "right_of" => RightOf
  | "under" => Under
  | "above" => Above
  | "adjacent_to" => AdjacentTo
  | other => die(where ++ ": unknown spatial relation '" ++ other ++ "'")
  }

let cameraSideOf = (value, where) =>
  switch value {
  | "left" => CameraLeft
  | "right" => CameraRight
  | "front" => CameraFront
  | "back" => CameraBack
  | "interior" => CameraInterior
  | other => die(where ++ ": unknown camera side '" ++ other ++ "'")
  }

let shotSizeOf = (value, where) =>
  switch value {
  | "extreme_wide" => ExtremeWide
  | "wide" => Wide
  | "full" => Full
  | "medium" => Medium
  | "close_up" => CloseUp
  | "extreme_close_up" => ExtremeCloseUp
  | "insert" => Insert
  | other => die(where ++ ": unknown shot size '" ++ other ++ "'")
  }

let decodeRequirementKind = (kind, json, where) => {
  let row = objectOf(json, where)
  switch kind {
  | "continuity" => {
      assertOnlyKeys(row, ["entityId", "beforeStateId", "afterStateId"], where)
      Continuity({
        entityId: requiredString(row, "entityId", where),
        beforeStateId: requiredString(row, "beforeStateId", where),
        afterStateId: requiredString(row, "afterStateId", where),
      })
    }
  | "presence" => {
      assertOnlyKeys(row, ["entityId", "stateId", "minimum", "maximum"], where)
      let minimum = requiredInt(row, "minimum", where, ~minimum=0)
      let maximum = optionalInt(row, "maximum", where, ~minimum=0)
      switch maximum {
      | Some(value) if value < minimum => die(where ++ ".maximum must be >= minimum")
      | _ => ()
      }
      Presence({
        entityId: requiredString(row, "entityId", where),
        stateId: optionalString(row, "stateId", where),
        minimum,
        maximum,
      })
    }
  | "forbidden" => {
      assertOnlyKeys(row, ["entityId", "stateId"], where)
      Forbidden({
        entityId: requiredString(row, "entityId", where),
        stateId: optionalString(row, "stateId", where),
      })
    }
  | "relative_scale" => {
      assertOnlyKeys(
        row,
        [
          "subjectEntityId",
          "subjectStateId",
          "referenceEntityId",
          "referenceStateId",
          "minRatio",
          "maxRatio",
        ],
        where,
      )
      let minRatio = requiredFloat(row, "minRatio", where)
      let maxRatio = requiredFloat(row, "maxRatio", where)
      if minRatio <= 0.0 || maxRatio < minRatio {
        die(where ++ ": scale ratios must satisfy 0 < minRatio <= maxRatio")
      }
      RelativeScale({
        subjectEntityId: requiredString(row, "subjectEntityId", where),
        subjectStateId: requiredString(row, "subjectStateId", where),
        referenceEntityId: requiredString(row, "referenceEntityId", where),
        referenceStateId: requiredString(row, "referenceStateId", where),
        minRatio,
        maxRatio,
      })
    }
  | "geography" => {
      assertOnlyKeys(row, ["subjectEntityId", "referenceEntityId", "relation"], where)
      Geography({
        subjectEntityId: requiredString(row, "subjectEntityId", where),
        referenceEntityId: requiredString(row, "referenceEntityId", where),
        relation: spatialRelationOf(requiredString(row, "relation", where), where ++ ".relation"),
      })
    }
  | "camera_side" => {
      assertOnlyKeys(row, ["side", "anchorEntityId", "occluderEntityId"], where)
      CameraSide({
        side: cameraSideOf(requiredString(row, "side", where), where ++ ".side"),
        anchorEntityId: requiredString(row, "anchorEntityId", where),
        occluderEntityId: optionalString(row, "occluderEntityId", where),
      })
    }
  | "framing" => {
      assertOnlyKeys(row, ["shotSize", "requiredEntityIds", "fullyVisible"], where)
      let requiredEntityIds = requiredStrings(row, "requiredEntityIds", where)
      assertUnique(requiredEntityIds, where ++ ".requiredEntityIds")
      Framing({
        shotSize: shotSizeOf(requiredString(row, "shotSize", where), where ++ ".shotSize"),
        requiredEntityIds,
        fullyVisible: requiredBoolean(row, "fullyVisible", where),
      })
    }
  | "complexity" => {
      assertOnlyKeys(
        row,
        ["maxPrincipalActions", "maxVisibleEntities", "maxContinuousSeconds"],
        where,
      )
      let maxContinuousSeconds = requiredFloat(row, "maxContinuousSeconds", where)
      if maxContinuousSeconds <= 0.0 {
        die(where ++ ".maxContinuousSeconds must be greater than zero")
      }
      Complexity({
        maxPrincipalActions: requiredInt(row, "maxPrincipalActions", where, ~minimum=1),
        maxVisibleEntities: requiredInt(row, "maxVisibleEntities", where, ~minimum=1),
        maxContinuousSeconds,
      })
    }
  | "references" => {
      assertOnlyKeys(row, ["assetIds", "exact"], where)
      let assetIds = requiredStrings(row, "assetIds", where)
      assertUnique(assetIds, where ++ ".assetIds")
      References({assetIds, exact: requiredBoolean(row, "exact", where)})
    }
  | other => die(where ++ ": unknown requirement kind '" ++ other ++ "'")
  }
}

let decodeRequirement = (json, index) => {
  let where = "requirements[" ++ Belt.Int.toString(index) ++ "]"
  let row = objectOf(json, where)
  assertOnlyKeys(
    row,
    ["id", "targetId", "scope", "validator", "decisionIds", "kind", "spec"],
    where,
  )
  let decisionIds = requiredNonemptyStrings(row, "decisionIds", where)
  assertUnique(decisionIds, where ++ ".decisionIds")
  let kind = requiredString(row, "kind", where)
  {
    id: requiredString(row, "id", where),
    targetId: requiredString(row, "targetId", where),
    scope: requiredString(row, "scope", where),
    validator: validatorKindOf(requiredString(row, "validator", where), where ++ ".validator"),
    decisionIds,
    kind: decodeRequirementKind(kind, requiredJson(row, "spec", where), where ++ ".spec"),
    authorityHash: authorityHashJson(json),
  }
}

let decodePolicyKind = (kind, json, where) => {
  let row = objectOf(json, where)
  switch kind {
  | "attempts" => {
      assertOnlyKeys(row, ["maxPerTarget"], where)
      AttemptsPolicy({maxPerTarget: requiredInt(row, "maxPerTarget", where, ~minimum=1)})
    }
  | "review" => {
      assertOnlyKeys(row, ["batchSize", "requireHumanApproval"], where)
      ReviewPolicy({
        batchSize: requiredInt(row, "batchSize", where, ~minimum=1),
        requireHumanApproval: requiredBoolean(row, "requireHumanApproval", where),
      })
    }
  | "complexity" => {
      assertOnlyKeys(
        row,
        ["maxPrincipalActions", "maxVisibleEntities", "maxContinuousSeconds"],
        where,
      )
      let maxContinuousSeconds = requiredFloat(row, "maxContinuousSeconds", where)
      if maxContinuousSeconds <= 0.0 {
        die(where ++ ".maxContinuousSeconds must be greater than zero")
      }
      ComplexityPolicy({
        maxPrincipalActions: requiredInt(row, "maxPrincipalActions", where, ~minimum=1),
        maxVisibleEntities: requiredInt(row, "maxVisibleEntities", where, ~minimum=1),
        maxContinuousSeconds,
      })
    }
  | "execution" => {
      assertOnlyKeys(row, ["requiresExplicitAuthorization"], where)
      ExecutionPolicy({
        requiresExplicitAuthorization: requiredBoolean(row, "requiresExplicitAuthorization", where),
      })
    }
  | other => die(where ++ ": unknown policy kind '" ++ other ++ "'")
  }
}

let decodePolicy = (json, index) => {
  let where = "policies[" ++ Belt.Int.toString(index) ++ "]"
  let row = objectOf(json, where)
  assertOnlyKeys(row, ["id", "decisionIds", "kind", "spec"], where)
  let decisionIds = requiredNonemptyStrings(row, "decisionIds", where)
  assertUnique(decisionIds, where ++ ".decisionIds")
  let kind = requiredString(row, "kind", where)
  {
    id: requiredString(row, "id", where),
    decisionIds,
    kind: decodePolicyKind(kind, requiredJson(row, "spec", where), where ++ ".spec"),
    authorityHash: authorityHashJson(json),
  }
}

let decodeApprovalBinding = (json, where) => {
  let row = objectOf(json, where)
  assertOnlyKeys(row, ["subjectId", "contentSha256"], where)
  let contentSha256 = requiredString(row, "contentSha256", where)
  if !Js.Re.test_(%re("/^[A-Fa-f0-9]{64}$/"), contentSha256) {
    die(where ++ ".contentSha256 must contain 64 hexadecimal characters")
  }
  {subjectId: requiredString(row, "subjectId", where), contentSha256}
}

/* Decision event identifiers are not labels supplied by the packet author.
   They are a hash of the complete canonical event (except its own identifier),
   its owning decision metadata, and its predecessor. This public helper exists
   for packet-authoring tools; decodePacket independently recomputes the same
   value and rejects stale or invented identifiers. */
let deriveDecisionEventIdJson = (~decisionId, ~scope, ~dependencies, eventJson) => {
  let event = objectOf(eventJson, "decision event")
  let content = Js.Dict.empty()
  Js.Dict.keys(event)->Belt.Array.forEach(key =>
    if key != "eventId" {
      Js.Dict.set(content, key, Js.Dict.get(event, key)->Belt.Option.getExn)
    }
  )
  let envelope = Js.Dict.empty()
  Js.Dict.set(envelope, "schema", Js.Json.string("production.decision-event/v1"))
  Js.Dict.set(envelope, "decisionId", Js.Json.string(decisionId))
  Js.Dict.set(envelope, "scope", Js.Json.string(scope))
  Js.Dict.set(envelope, "dependencies", Js.Json.array(dependencies->Belt.Array.map(Js.Json.string)))
  Js.Dict.set(envelope, "event", Js.Json.object_(content))
  "DEV-" ++ sha256Text(canonicalJson(Js.Json.object_(envelope)))
}

let decodeDecisionEvent = (json, where) => {
  let row = objectOf(json, where)
  let kind = requiredString(row, "kind", where)
  let common = ["eventId", "sequence", "previousEventId", "kind"]
  let eventId = requiredString(row, "eventId", where)
  let sequence = requiredInt(row, "sequence", where, ~minimum=1)
  let previousEventId = requiredNullableString(row, "previousEventId", where)
  let decodedKind = switch kind {
  | "propose" => {
      assertOnlyKeys(row, Belt.Array.concat(common, ["statement"]), where)
      ProposeEvent(requiredString(row, "statement", where))
    }
  | "approve" => {
      assertOnlyKeys(row, Belt.Array.concat(common, ["note", "bindings"]), where)
      let bindings =
        requiredArray(row, "bindings", where)->Belt.Array.mapWithIndex((index, json) =>
          decodeApprovalBinding(json, where ++ ".bindings[" ++ Belt.Int.toString(index) ++ "]")
        )
      assertUnique(
        bindings->Belt.Array.map(binding => binding.subjectId),
        where ++ ".bindings.subjectId",
      )
      ApproveEvent({note: optionalString(row, "note", where), bindings})
    }
  | "reject" => {
      assertOnlyKeys(row, Belt.Array.concat(common, ["reason"]), where)
      RejectEvent(requiredString(row, "reason", where))
    }
  | "reopen" => {
      assertOnlyKeys(row, Belt.Array.concat(common, ["reason"]), where)
      ReopenEvent(requiredString(row, "reason", where))
    }
  | "supersede" => {
      assertOnlyKeys(row, Belt.Array.concat(common, ["supersededBy", "reason"]), where)
      SupersedeEvent({
        supersededBy: requiredString(row, "supersededBy", where),
        reason: requiredString(row, "reason", where),
      })
    }
  | other => die(where ++ ": unknown decision event kind '" ++ other ++ "'")
  }
  {eventId, sequence, previousEventId, kind: decodedKind}
}

let decodeDecisionLedger = (json, index) => {
  let where = "decisionLedgers[" ++ Belt.Int.toString(index) ++ "]"
  let row = objectOf(json, where)
  assertOnlyKeys(row, ["decisionId", "scope", "dependencies", "events"], where)
  let decisionId = requiredString(row, "decisionId", where)
  let scope = requiredString(row, "scope", where)
  let dependencies = requiredStrings(row, "dependencies", where)
  assertUnique(dependencies, where ++ ".dependencies")
  let eventJsons = requiredArray(row, "events", where)
  let events = eventJsons->Belt.Array.mapWithIndex((eventIndex, eventJson) => {
    let eventWhere = where ++ ".events[" ++ Belt.Int.toString(eventIndex) ++ "]"
    let event = decodeDecisionEvent(eventJson, eventWhere)
    let expectedId = deriveDecisionEventIdJson(~decisionId, ~scope, ~dependencies, eventJson)
    if event.eventId != expectedId {
      die(eventWhere ++ ".eventId fails its canonical content hash; expected " ++ expectedId)
    }
    event
  })
  if Belt.Array.length(events) == 0 {
    die(where ++ ".events must not be empty")
  }
  let priorSequence = ref(0)
  events->Belt.Array.forEach(event => {
    if event.sequence <= priorSequence.contents {
      die(
        "decision " ++ decisionId ++ " events must be stored in strictly increasing sequence order",
      )
    }
    priorSequence := event.sequence
  })
  {
    decisionId,
    scope,
    dependencies,
    events,
  }
}

let decodeDecisionHistoryAnchor = json => {
  let where = "packet.decisionHistory"
  let row = objectOf(json, where)
  assertOnlyKeys(row, ["eventCount", "headEventId"], where)
  {
    eventCount: requiredInt(row, "eventCount", where, ~minimum=0),
    headEventId: requiredNullableString(row, "headEventId", where),
  }
}

let decisionStatusName = status =>
  switch status {
  | DecisionProposed => "proposed"
  | DecisionApproved => "approved"
  | DecisionRejected => "rejected"
  | DecisionSuperseded(_) => "superseded"
  }

let validatorKindName = validator =>
  switch validator {
  | Deterministic => "deterministic"
  | SemanticInspector => "semantic_inspector"
  | HumanOnly => "human_only"
  }

let reduceLedger = ledger => {
  let current = ref(None)
  let statement = ref(None)
  let bindings: ref<array<approvalBinding>> = ref([])
  let priorSequence = ref(0)
  ledger.events->Belt.Array.forEach(event => {
    if event.sequence <= priorSequence.contents {
      die(
        "decision " ++
        ledger.decisionId ++ " events must be stored in strictly increasing sequence order",
      )
    }
    priorSequence := event.sequence
    switch (current.contents, event.kind) {
    | (None, ProposeEvent(value)) => {
        statement := Some(value)
        current := Some(DecisionProposed)
      }
    | (Some(DecisionProposed), ApproveEvent(approval)) => {
        bindings := approval.bindings
        current := Some(DecisionApproved)
      }
    | (Some(DecisionProposed), RejectEvent(_)) => current := Some(DecisionRejected)
    | (Some(DecisionProposed), SupersedeEvent(spec)) =>
      current := Some(DecisionSuperseded(spec.supersededBy))
    | (Some(DecisionApproved), ReopenEvent(_))
    | (Some(DecisionRejected), ReopenEvent(_))
    | (Some(DecisionSuperseded(_)), ReopenEvent(_)) => {
        bindings := []
        current := Some(DecisionProposed)
      }
    | (Some(DecisionApproved), SupersedeEvent(spec))
    | (Some(DecisionRejected), SupersedeEvent(spec)) =>
      current := Some(DecisionSuperseded(spec.supersededBy))
    | (None, _) => die("decision " ++ ledger.decisionId ++ " must begin with propose")
    | (Some(status), _) =>
      die(
        "illegal decision transition for " ++
        ledger.decisionId ++
        " from " ++
        decisionStatusName(status),
      )
    }
  })
  {
    id: ledger.decisionId,
    scope: ledger.scope,
    statement: statement.contents->Belt.Option.getExn,
    dependencies: ledger.dependencies,
    status: current.contents->Belt.Option.getExn,
    bindings: bindings.contents,
  }
}

let findById = (type a, rows: array<a>, id: string, getId: a => string): option<a> =>
  rows->Belt.Array.getBy(row => getId(row) == id)

let assertReferences = (values, known, where) =>
  values->Belt.Array.forEach(value =>
    if !(known->Belt.Array.some(id => id == value)) {
      die(where ++ ": unknown id '" ++ value ++ "'")
    }
  )

let assertAcyclic = (~ids, ~dependencies, ~where) => {
  let visiting = Js.Dict.empty()
  let visited = Js.Dict.empty()
  let rec visit = id =>
    if Js.Dict.get(visiting, id)->Belt.Option.getWithDefault(false) {
      die(where ++ ": dependency cycle includes '" ++ id ++ "'")
    } else if !(Js.Dict.get(visited, id)->Belt.Option.getWithDefault(false)) {
      Js.Dict.set(visiting, id, true)
      dependencies(id)->Belt.Array.forEach(visit)
      Js.Dict.set(visiting, id, false)
      Js.Dict.set(visited, id, true)
    }
  ids->Belt.Array.forEach(visit)
}

let governedSubjects = (packet: packet): array<governedSubject> =>
  Belt.Array.concatMany([
    packet.principals->Belt.Array.map(principal => {
      subjectId: "principal:" ++ principal.id,
      authorityHash: principal.authorityHash,
      decisionIds: principal.decisionIds,
    }),
    packet.entities->Belt.Array.map(entity => {
      subjectId: "entity:" ++ entity.id,
      authorityHash: entity.authorityHash,
      decisionIds: entity.decisionIds,
    }),
    packet.assets->Belt.Array.map(asset => {
      subjectId: "asset:" ++ asset.id,
      authorityHash: asset.authorityHash,
      decisionIds: asset.decisionIds,
    }),
    packet.targets->Belt.Array.map(target => {
      subjectId: "target:" ++ target.id,
      authorityHash: target.authorityHash,
      decisionIds: target.decisionIds,
    }),
    packet.requirements->Belt.Array.map(requirement => {
      subjectId: "requirement:" ++ requirement.id,
      authorityHash: requirement.authorityHash,
      decisionIds: requirement.decisionIds,
    }),
    packet.policies->Belt.Array.map(policy => {
      subjectId: "policy:" ++ policy.id,
      authorityHash: policy.authorityHash,
      decisionIds: policy.decisionIds,
    }),
  ])

let validatePacket = packet => {
  let decisionIds = packet.decisionLedgers->Belt.Array.map(ledger => ledger.decisionId)
  let principalIds = packet.principals->Belt.Array.map(principal => principal.id)
  let entityIds = packet.entities->Belt.Array.map(entity => entity.id)
  let assetIds = packet.assets->Belt.Array.map(asset => asset.id)
  let targetIds = packet.targets->Belt.Array.map(target => target.id)
  let requirementIds = packet.requirements->Belt.Array.map(requirement => requirement.id)
  let policyIds = packet.policies->Belt.Array.map(policy => policy.id)
  assertStableId(packet.packetId, "packet.packetId")
  assertStableIds(decisionIds, "decisionLedgers.decisionId")
  assertStableIds(principalIds, "principals.id")
  assertStableIds(entityIds, "entities.id")
  packet.entities->Belt.Array.forEach(entity =>
    assertStableIds(
      entity.states->Belt.Array.map(state => state.id),
      "entity " ++ entity.id ++ " state ids",
    )
  )
  assertStableIds(assetIds, "assets.id")
  assertStableIds(targetIds, "targets.id")
  packet.targets->Belt.Array.forEach(target =>
    assertStableId(target.operation, "target " ++ target.id ++ " operation")
  )
  assertStableIds(requirementIds, "requirements.id")
  packet.requirements->Belt.Array.forEach(requirement =>
    assertStableId(requirement.scope, "requirement " ++ requirement.id ++ " scope")
  )
  assertStableIds(policyIds, "policies.id")
  assertUnique(decisionIds, "decisionLedgers.decisionId")
  assertUnique(principalIds, "principals.id")
  assertUnique(entityIds, "entities.id")
  assertUnique(assetIds, "assets.id")
  assertUnique(targetIds, "targets.id")
  assertUnique(requirementIds, "requirements.id")
  assertUnique(policyIds, "policies.id")

  let allEvents = packet.decisionLedgers->Belt.Array.flatMap(ledger => ledger.events)
  packet.decisionLedgers->Belt.Array.forEach(ledger =>
    assertStableId(ledger.scope, "decision " ++ ledger.decisionId ++ " scope")
  )
  assertStableIds(allEvents->Belt.Array.map(event => event.eventId), "decision event ids")
  allEvents->Belt.Array.forEach(event =>
    switch event.previousEventId {
    | Some(value) => assertStableId(value, "decision event previousEventId")
    | None => ()
    }
  )
  assertUnique(allEvents->Belt.Array.map(event => event.eventId), "decision event ids")
  let sequenceStrings = allEvents->Belt.Array.map(event => Belt.Int.toString(event.sequence))
  assertUnique(sequenceStrings, "decision event sequences")
  let orderedEvents = Js.Array2.copy(allEvents)
  orderedEvents->Js.Array2.sortInPlaceWith((left, right) => left.sequence - right.sequence)->ignore
  let previousEventId = ref(None)
  orderedEvents->Belt.Array.forEachWithIndex((index, event) => {
    let expected = index + 1
    if event.sequence != expected {
      die(
        "decision event sequences must be contiguous from 1; expected " ++
        Belt.Int.toString(expected) ++
        " but found " ++
        Belt.Int.toString(event.sequence),
      )
    }
    if event.previousEventId != previousEventId.contents {
      die(
        "decision event " ++
        event.eventId ++
        " does not chain to the preceding event at sequence " ++
        Belt.Int.toString(event.sequence),
      )
    }
    previousEventId := Some(event.eventId)
  })

  let actualEventCount = Belt.Array.length(orderedEvents)
  if packet.decisionHistory.eventCount != actualEventCount {
    die(
      "packet.decisionHistory.eventCount does not match the canonical decision history; expected " ++
      Belt.Int.toString(actualEventCount) ++
      " but found " ++
      Belt.Int.toString(packet.decisionHistory.eventCount),
    )
  }
  if packet.decisionHistory.headEventId != previousEventId.contents {
    let expectedHead = switch previousEventId.contents {
    | Some(value) => value
    | None => "null"
    }
    let foundHead = switch packet.decisionHistory.headEventId {
    | Some(value) => value
    | None => "null"
    }
    die(
      "packet.decisionHistory.headEventId does not match the canonical decision history; expected " ++
      expectedHead ++ " but found " ++ foundHead,
    )
  }

  let reduced = packet.decisionLedgers->Belt.Array.map(reduceLedger)
  packet.decisionLedgers->Belt.Array.forEach(ledger => {
    assertReferences(
      ledger.dependencies,
      decisionIds,
      "decision " ++ ledger.decisionId ++ " dependencies",
    )
    if ledger.dependencies->Belt.Array.some(id => id == ledger.decisionId) {
      die("decision " ++ ledger.decisionId ++ " cannot depend on itself")
    }
  })
  assertAcyclic(
    ~ids=decisionIds,
    ~dependencies=id => {
      let ledger: decisionLedger =
        packet.decisionLedgers
        ->Belt.Array.getBy(ledger => ledger.decisionId == id)
        ->Belt.Option.getExn
      ledger.dependencies
    },
    ~where="decision dependencies",
  )

  packet.principals->Belt.Array.forEach(principal =>
    assertReferences(
      principal.decisionIds,
      decisionIds,
      "principal " ++ principal.id ++ " decisionIds",
    )
  )
  packet.decisionLedgers->Belt.Array.forEach(ledger =>
    ledger.events->Belt.Array.forEach(event =>
      switch event.kind {
      | SupersedeEvent(spec) => {
          let replacementId = spec.supersededBy
          if replacementId == ledger.decisionId {
            die("decision " ++ ledger.decisionId ++ " cannot supersede itself")
          }
          let replacement = findById(reduced, replacementId, row => row.id)
          switch replacement {
          | None =>
            die(
              "decision " ++
              ledger.decisionId ++
              " names unknown superseding decision '" ++
              replacementId ++ "'",
            )
          | Some(value) if value.scope != ledger.scope =>
            die(
              "decision " ++
              ledger.decisionId ++
              " may only be superseded within scope '" ++
              ledger.scope ++ "'",
            )
          | Some(_) => ()
          }
          let replacementProposalSequence =
            packet.decisionLedgers
            ->Belt.Array.getBy(candidate => candidate.decisionId == replacementId)
            ->Belt.Option.getExn
            ->(candidate => Belt.Array.getExn(candidate.events, 0).sequence)
          if replacementProposalSequence >= event.sequence {
            die(
              "superseding decision " ++
              replacementId ++ " must be proposed before it is referenced",
            )
          }
        }
      | _ => ()
      }
    )
  )

  packet.entities->Belt.Array.forEach(entity => {
    assertReferences(entity.decisionIds, decisionIds, "entity " ++ entity.id ++ " decisionIds")
    entity.states->Belt.Array.forEach(state =>
      switch state.locationEntityId {
      | Some(id) if id == entity.id =>
        die("entity " ++ entity.id ++ " cannot locate itself inside itself")
      | Some(id) =>
        assertReferences([id], entityIds, "entity " ++ entity.id ++ " state " ++ state.id)
      | None => ()
      }
    )
  })
  packet.assets->Belt.Array.forEach(asset => {
    assertReferences(asset.decisionIds, decisionIds, "asset " ++ asset.id ++ " decisionIds")
    assertReferences(asset.entityIds, entityIds, "asset " ++ asset.id ++ " entityIds")
    assertReferences(
      asset.referenceAssetIds,
      assetIds,
      "asset " ++ asset.id ++ " referenceAssetIds",
    )
    if asset.referenceAssetIds->Belt.Array.some(id => id == asset.id) {
      die("asset " ++ asset.id ++ " cannot reference itself")
    }
  })
  assertAcyclic(
    ~ids=assetIds,
    ~dependencies=id => {
      let asset: asset =
        packet.assets->Belt.Array.getBy(asset => asset.id == id)->Belt.Option.getExn
      asset.referenceAssetIds
    },
    ~where="asset references",
  )
  packet.targets->Belt.Array.forEach(target => {
    assertReferences(target.decisionIds, decisionIds, "target " ++ target.id ++ " decisionIds")
    assertReferences(target.entityIds, entityIds, "target " ++ target.id ++ " entityIds")
    assertReferences(target.assetIds, assetIds, "target " ++ target.id ++ " assetIds")
    assertReferences(
      target.requirementIds,
      requirementIds,
      "target " ++ target.id ++ " requirementIds",
    )
    assertReferences(
      target.dependsOnTargetIds,
      targetIds,
      "target " ++ target.id ++ " dependencies",
    )
    if target.dependsOnTargetIds->Belt.Array.some(id => id == target.id) {
      die("target " ++ target.id ++ " cannot depend on itself")
    }
  })
  assertAcyclic(
    ~ids=targetIds,
    ~dependencies=id => {
      let target: target =
        packet.targets
        ->Belt.Array.getBy(target => target.id == id)
        ->Belt.Option.getExn
      target.dependsOnTargetIds
    },
    ~where="target dependencies",
  )

  let assertEntityState = (entityId, stateId, where) => {
    let entity = findById(packet.entities, entityId, entity => entity.id)->Belt.Option.getExn
    if !(entity.states->Belt.Array.some(state => state.id == stateId)) {
      die(where ++ ": entity '" ++ entityId ++ "' has no state '" ++ stateId ++ "'")
    }
  }
  packet.requirements->Belt.Array.forEach(requirement => {
    assertReferences(
      [requirement.targetId],
      targetIds,
      "requirement " ++ requirement.id ++ " targetId",
    )
    assertReferences(
      requirement.decisionIds,
      decisionIds,
      "requirement " ++ requirement.id ++ " decisionIds",
    )
    switch requirement.kind {
    | Continuity(spec) => {
        assertReferences([spec.entityId], entityIds, "requirement " ++ requirement.id)
        assertEntityState(spec.entityId, spec.beforeStateId, "requirement " ++ requirement.id)
        assertEntityState(spec.entityId, spec.afterStateId, "requirement " ++ requirement.id)
      }
    | Presence(spec) => {
        assertReferences([spec.entityId], entityIds, "requirement " ++ requirement.id)
        switch spec.stateId {
        | Some(stateId) =>
          assertEntityState(spec.entityId, stateId, "requirement " ++ requirement.id)
        | None => ()
        }
      }
    | Forbidden(spec) => {
        assertReferences([spec.entityId], entityIds, "requirement " ++ requirement.id)
        switch spec.stateId {
        | Some(stateId) =>
          assertEntityState(spec.entityId, stateId, "requirement " ++ requirement.id)
        | None => ()
        }
      }
    | RelativeScale(spec) => {
        assertReferences(
          [spec.subjectEntityId, spec.referenceEntityId],
          entityIds,
          "requirement " ++ requirement.id,
        )
        assertEntityState(
          spec.subjectEntityId,
          spec.subjectStateId,
          "requirement " ++ requirement.id,
        )
        assertEntityState(
          spec.referenceEntityId,
          spec.referenceStateId,
          "requirement " ++ requirement.id,
        )
      }
    | Geography(spec) =>
      assertReferences(
        [spec.subjectEntityId, spec.referenceEntityId],
        entityIds,
        "requirement " ++ requirement.id,
      )
    | CameraSide(spec) => {
        assertReferences([spec.anchorEntityId], entityIds, "requirement " ++ requirement.id)
        switch spec.occluderEntityId {
        | Some(id) => assertReferences([id], entityIds, "requirement " ++ requirement.id)
        | None => ()
        }
      }
    | Framing(spec) =>
      assertReferences(spec.requiredEntityIds, entityIds, "requirement " ++ requirement.id)
    | Complexity(_) => ()
    | References(spec) =>
      assertReferences(spec.assetIds, assetIds, "requirement " ++ requirement.id)
    }
  })
  packet.targets->Belt.Array.forEach(target =>
    target.requirementIds->Belt.Array.forEach(requirementId => {
      let requirement =
        findById(
          packet.requirements,
          requirementId,
          requirement => requirement.id,
        )->Belt.Option.getExn
      if requirement.targetId != target.id {
        die(
          "target " ++
          target.id ++
          " includes requirement " ++
          requirementId ++
          " owned by " ++
          requirement.targetId,
        )
      }
    })
  )
  packet.policies->Belt.Array.forEach(policy =>
    assertReferences(policy.decisionIds, decisionIds, "policy " ++ policy.id ++ " decisionIds")
  )

  let subjects = governedSubjects(packet)
  assertUnique(subjects->Belt.Array.map(subject => subject.subjectId), "governed subject ids")
  packet.decisionLedgers->Belt.Array.forEach(ledger =>
    ledger.events->Belt.Array.forEach(event =>
      switch event.kind {
      | ApproveEvent(approval) =>
        approval.bindings->Belt.Array.forEach(
          binding =>
            switch subjects->Belt.Array.getBy(subject => subject.subjectId == binding.subjectId) {
            | None =>
              die(
                "decision " ++
                ledger.decisionId ++
                " approval binds unknown subject '" ++
                binding.subjectId ++ "'",
              )
            | Some(subject)
              if !(subject.decisionIds->Belt.Array.some(id => id == ledger.decisionId)) =>
              die(
                "decision " ++
                ledger.decisionId ++
                " may not approve ungoverned subject '" ++
                binding.subjectId ++ "'",
              )
            | Some(_) => ()
            },
        )
      | _ => ()
      }
    )
  )
}

let decodePacket = raw => {
  let root = objectOf(parseJson(raw), "packet")
  assertOnlyKeys(
    root,
    [
      "schema",
      "packetId",
      "revision",
      "decisionHistory",
      "decisionLedgers",
      "principals",
      "entities",
      "assets",
      "targets",
      "requirements",
      "policies",
    ],
    "packet",
  )
  let schema = requiredString(root, "schema", "packet")
  if schema != "production-packet/v2" {
    die("packet.schema: unsupported schema '" ++ schema ++ "'")
  }
  let packet = {
    schema,
    packetId: requiredString(root, "packetId", "packet"),
    revision: requiredInt(root, "revision", "packet", ~minimum=1),
    decisionHistory: decodeDecisionHistoryAnchor(
      requiredJson(root, "decisionHistory", "packet"),
    ),
    decisionLedgers: requiredArray(
      root,
      "decisionLedgers",
      "packet",
    )->Belt.Array.mapWithIndex((index, json) => decodeDecisionLedger(json, index)),
    principals: requiredArray(root, "principals", "packet")->Belt.Array.mapWithIndex((
      index,
      json,
    ) => decodePrincipal(json, index)),
    entities: requiredArray(root, "entities", "packet")->Belt.Array.mapWithIndex((index, json) =>
      decodeEntity(json, index)
    ),
    assets: requiredArray(root, "assets", "packet")->Belt.Array.mapWithIndex((index, json) =>
      decodeAsset(json, index)
    ),
    targets: requiredArray(root, "targets", "packet")->Belt.Array.mapWithIndex((index, json) =>
      decodeTarget(json, index)
    ),
    requirements: requiredArray(root, "requirements", "packet")->Belt.Array.mapWithIndex((
      index,
      json,
    ) => decodeRequirement(json, index)),
    policies: requiredArray(root, "policies", "packet")->Belt.Array.mapWithIndex((index, json) =>
      decodePolicy(json, index)
    ),
  }
  validatePacket(packet)
  packet
}

let reconstruct = raw => {
  let packet = decodePacket(raw)
  let decisions = packet.decisionLedgers->Belt.Array.map(reduceLedger)
  decisions->Js.Array2.sortInPlaceWith((left, right) => compareStrings(left.id, right.id))->ignore

  let approvedByScope = Js.Dict.empty()
  decisions->Belt.Array.forEach(decision =>
    if decision.status == DecisionApproved {
      let existing = Js.Dict.get(approvedByScope, decision.scope)->Belt.Option.getWithDefault([])
      Js.Dict.set(approvedByScope, decision.scope, Belt.Array.concat(existing, [decision.id]))
    }
  )
  let conflicts = Js.Dict.keys(approvedByScope)->Belt.Array.keepMap(scope => {
    let ids = Js.Dict.get(approvedByScope, scope)->Belt.Option.getExn
    if Belt.Array.length(ids) > 1 {
      ids->Js.Array2.sortInPlaceWith(compareStrings)->ignore
      Some({scope, decisionIds: ids})
    } else {
      None
    }
  })
  conflicts
  ->Js.Array2.sortInPlaceWith((left, right) => compareStrings(left.scope, right.scope))
  ->ignore

  let effectiveMemo = Js.Dict.empty()
  let rec isEffective = id =>
    switch Js.Dict.get(effectiveMemo, id) {
    | Some(value) => value
    | None => {
        let decision = findById(decisions, id, row => row.id)->Belt.Option.getExn
        let value =
          decision.status == DecisionApproved &&
          decision.dependencies->Belt.Array.every(isEffective) &&
          !(
            conflicts->Belt.Array.some(conflict =>
              conflict.decisionIds->Belt.Array.some(other => other == id)
            )
          )
        Js.Dict.set(effectiveMemo, id, value)
        value
      }
    }
  let effectiveDecisionIds =
    decisions->Belt.Array.keepMap(decision => isEffective(decision.id) ? Some(decision.id) : None)
  let blockers = []
  conflicts->Belt.Array.forEach(conflict =>
    blockers
    ->Js.Array2.push(
      "scope " ++
      conflict.scope ++
      " has multiple approved decisions: " ++
      Js.Array2.joinWith(conflict.decisionIds, ", "),
    )
    ->ignore
  )
  decisions->Belt.Array.forEach(decision =>
    if decision.status == DecisionApproved {
      decision.dependencies->Belt.Array.forEach(dependencyId =>
        if !isEffective(dependencyId) {
          blockers
          ->Js.Array2.push(
            "approved decision " ++
            decision.id ++
            " depends on ineffective decision " ++
            dependencyId,
          )
          ->ignore
        }
      )
    }
  )
  blockers->Js.Array2.sortInPlaceWith(compareStrings)->ignore
  {
    packet,
    canonicalHash: canonicalHashJson(raw),
    decisions,
    effectiveDecisionIds,
    conflicts,
    blockers,
  }
}

let approvalBinds = (context: context, ~decisionId, ~subjectId, ~authorityHash) =>
  context.decisions->Belt.Array.some(decision =>
    decision.id == decisionId &&
    context.effectiveDecisionIds->Belt.Array.some(id => id == decisionId) &&
    decision.bindings->Belt.Array.some(binding =>
      binding.subjectId == subjectId && binding.contentSha256 == authorityHash
    )
  )
