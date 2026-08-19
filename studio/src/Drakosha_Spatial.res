/* Frosya and Vasya -- deterministic physical-production gate.

   The screenplay is prose.  This module is deliberately not: it accepts only
   named geometry, named evidence, and structured interactions.  A story wish
   can guide asset selection, but it cannot certify that an action is possible.

   The decoder is strict.  Missing geometry never becomes zero. */

exception SpatialError(string)

type severity = Blocking | Warning

type finding = {
  code: string,
  severity: severity,
  scope: string,
  detail: string,
  remedy: string,
}

type evidenceKind =
  | AuthorLocked
  | PhysicalMeasurement
  | AssetMeasurement
  | Derived
  | CatalogReference
  | Estimate
  | StoryRequired
  | Unmeasured

type evidence = {
  id: string,
  kind: evidenceKind,
  note: string,
  inputs: array<string>,
}

type point = {x: float, y: float, z: float}
type aabb = {min: point, max: point}
type namedPoint = {id: string, value: point, evidence: string}
type orientation = Xyz | Yxz
type openingPlane = XY | XZ | YZ
type openingEdge = UMin | UMax | VMin | VMax
type visibilityRisk = VisibilityUnclassified | NoVisibilityRisk | ExposedToGiants
type opening = {
  id: string,
  plane: openingPlane,
  center: point,
  spanU: float,
  spanV: float,
  evidence: string,
}
type volume = {id: string, bounds: aabb, evidence: string}
type destination = {
  id: string,
  evidence: string,
  barrierAnchorId: string,
  floorAnchorId: string,
  supportAnchorId: string,
  openingId: string,
  barrierEdge: openingEdge,
  volumeId: string,
}

type state = {
  id: string,
  evidence: string,
  bounds: aabb,
  anchors: array<namedPoint>,
  grips: array<namedPoint>,
  openings: array<opening>,
  volumes: array<volume>,
  destinations: array<destination>,
  visibilityRisk: visibilityRisk,
  orientations: array<orientation>,
  affordances: array<string>,
}

type capability = {
  id: string,
  evidence: string,
  stateIds: array<string>,
  maxHandHeightLoaded: float,
  armReachLoaded: float,
  maxLiftMassG: float,
  maxCarryMassG: float,
  maxDragMassG: float,
}

type mass = {value: float, evidence: string}

type handlingMethod =
  | OnePersonLift
  | TwoPersonLift
  | OnePersonDrag
  | TwoPersonDrag
  | TwoPersonFoldOnFloor
  | PapaSpin
  | Ride
  | PushByHand
  | CarryThreadInJaws
  | CrawlWithFoldedWings
  | PayOut
  | ThreadPull
  | HandOverHandPull

type handlingPermission = {method: handlingMethod, stateIds: array<string>}

type entity = {
  id: string,
  label: string,
  kind: string,
  states: array<state>,
  capabilities: array<capability>,
  mass: option<mass>,
  handlingPermissions: array<handlingPermission>,
}

type units = {length: string, mass: string, time: string, axes: string}

type registry = {
  schema: string,
  units: units,
  evidence: array<evidence>,
  entities: array<entity>,
}

type decisionStatus = AuthorApproved | Proposed | Superseded | Rejected
type decision = {id: string, status: decisionStatus, note: string}

type coverageClass = Physical | NoneDeclared | Pending
type noneReason =
  | SpokenDialogueOnly
  | StaticTextCard
  | SoundOnly
  | StaticEstablishingImage

type coverage = {
  shotId: string,
  blockSha256: string,
  classification: coverageClass,
  interactionIds: array<string>,
  reason: option<noneReason>,
  exemptionDecisionRef: option<string>,
}

type actorAssignment = {
  entityId: string,
  stateId: string,
  capabilityId: string,
  gripId: string,
  stance: option<point>,
  stanceEvidence: string,
  shoulderAnchor: string,
}
type resolvedActor = (entity, state, capability, actorAssignment)

type objectRef = {entityId: string, stateId: string}

type placeInto = {
  actors: array<actorAssignment>,
  subject: objectRef,
  target: objectRef,
  destinationId: string,
  orientation: orientation,
  method: handlingMethod,
  clearance: float,
}

type moveObject = {
  actors: array<actorAssignment>,
  subject: objectRef,
  path: objectRef,
  orientation: orientation,
  method: handlingMethod,
}

type interactionAction = PlaceInto(placeInto) | MoveObject(moveObject)
type proofSpec = {sideFile: string, planFile: string}
type criticality = BlockingCriticality

type interaction = {
  id: string,
  shotIds: array<string>,
  decisionRefs: array<string>,
  criticality: criticality,
  action: interactionAction,
  proof: option<proofSpec>,
}

type sourceRef = {path: string, sha256: string, expectedShotCount: int}
type backlogRef = {path: string, sha256: string, openItemIds: array<string>}
type outputConfig = {reportPath: string, proofDir: string, indexPath: string}

type manifest = {
  schema: string,
  profile: string,
  source: sourceRef,
  backlog: backlogRef,
  output: outputConfig,
  decisions: array<decision>,
  coverage: array<coverage>,
  interactions: array<interaction>,
}

type shotBlock = {id: string, raw: string, sha256: string}
type artifact = {relativePath: string, body: string}

type evaluation = {
  findings: array<finding>,
  passed: array<string>,
  shotBlocks: array<shotBlock>,
  sourceSha256: string,
  artifacts: array<artifact>,
}

/* ---- strict JSON decoding ---------------------------------------------- */

let objOf = (j: Js.Json.t, where: string): Js.Dict.t<Js.Json.t> =>
  switch Js.Json.decodeObject(j) {
  | Some(o) => o
  | None => raise(SpatialError(where ++ ": expected an object"))
  }

let arrOf = (j: Js.Json.t, where: string): array<Js.Json.t> =>
  switch Js.Json.decodeArray(j) {
  | Some(a) => a
  | None => raise(SpatialError(where ++ ": expected an array"))
  }

let get = (o: Js.Dict.t<Js.Json.t>, k: string): option<Js.Json.t> => Js.Dict.get(o, k)

let reqStr = (o, k, where): string =>
  switch get(o, k)->Belt.Option.flatMap(Js.Json.decodeString) {
  | Some(s) if Js.String2.length(s) > 0 => s
  | _ => raise(SpatialError(where ++ ": missing nonempty string field '" ++ k ++ "'"))
  }

let optStr = (o, k): option<string> => get(o, k)->Belt.Option.flatMap(Js.Json.decodeString)

let reqNum = (o, k, where): float =>
  switch get(o, k)->Belt.Option.flatMap(Js.Json.decodeNumber) {
  | Some(n) if Js.Float.isFinite(n) => n
  | _ => raise(SpatialError(where ++ ": missing finite number field '" ++ k ++ "'"))
  }

let reqPositive = (o, k, where): float => {
  let n = reqNum(o, k, where)
  if n <= 0.0 {
    raise(SpatialError(where ++ ": field '" ++ k ++ "' must be greater than zero"))
  }
  n
}

let reqNonnegative = (o, k, where): float => {
  let n = reqNum(o, k, where)
  if n < 0.0 {
    raise(SpatialError(where ++ ": field '" ++ k ++ "' must be zero or greater"))
  }
  n
}

let reqInt = (o, k, where): int => {
  let n = reqNum(o, k, where)
  let i = Belt.Float.toInt(n)
  if Belt.Int.toFloat(i) != n {
    raise(SpatialError(where ++ ": field '" ++ k ++ "' must be an integer"))
  }
  i
}

let reqArray = (o, k, where): array<Js.Json.t> =>
  switch get(o, k) {
  | Some(j) => arrOf(j, where ++ "." ++ k)
  | None => raise(SpatialError(where ++ ": missing array field '" ++ k ++ "'"))
  }

let optArray = (o, k, where): array<Js.Json.t> =>
  switch get(o, k) {
  | Some(j) => arrOf(j, where ++ "." ++ k)
  | None => []
  }

let reqObject = (o, k, where): Js.Dict.t<Js.Json.t> =>
  switch get(o, k) {
  | Some(j) => objOf(j, where ++ "." ++ k)
  | None => raise(SpatialError(where ++ ": missing object field '" ++ k ++ "'"))
  }

let stringsOf = (rows: array<Js.Json.t>, where: string): array<string> =>
  rows->Belt.Array.mapWithIndex((i, j) =>
    switch Js.Json.decodeString(j) {
    | Some(s) if Js.String2.length(s) > 0 => s
    | _ => raise(SpatialError(where ++ "[" ++ Belt.Int.toString(i) ++ "]: expected a nonempty string"))
    }
  )

let hasDuplicateStrings = rows => {
  let seen = Js.Dict.empty()
  rows->Belt.Array.some(row =>
    if Js.Dict.get(seen, row) == Some(true) {
      true
    } else {
      Js.Dict.set(seen, row, true)
      false
    }
  )
}

let pointOf = (j: Js.Json.t, where: string): point => {
  let a = arrOf(j, where)
  if Belt.Array.length(a) != 3 {
    raise(SpatialError(where ++ ": expected exactly three coordinates [x,y,z]"))
  }
  let coord = i =>
    switch Belt.Array.get(a, i)->Belt.Option.flatMap(Js.Json.decodeNumber) {
    | Some(n) if Js.Float.isFinite(n) => n
    | _ => raise(SpatialError(where ++ "[" ++ Belt.Int.toString(i) ++ "]: expected a finite number"))
    }
  {x: coord(0), y: coord(1), z: coord(2)}
}

let aabbOf = (o: Js.Dict.t<Js.Json.t>, where: string): aabb => {
  let min = switch get(o, "min") {
  | Some(j) => pointOf(j, where ++ ".min")
  | None => raise(SpatialError(where ++ ": missing 'min'"))
  }
  let max = switch get(o, "max") {
  | Some(j) => pointOf(j, where ++ ".max")
  | None => raise(SpatialError(where ++ ": missing 'max'"))
  }
  if max.x <= min.x || max.y <= min.y || max.z <= min.z {
    raise(SpatialError(where ++ ": every max coordinate must be greater than min"))
  }
  {min, max}
}

let evidenceKindOf = (s, where) =>
  switch s {
  | "author_locked" => AuthorLocked
  | "physical_measurement" => PhysicalMeasurement
  | "asset_measurement" => AssetMeasurement
  | "derived" => Derived
  | "catalog_reference" => CatalogReference
  | "estimate" => Estimate
  | "story_required" => StoryRequired
  | "unmeasured" => Unmeasured
  | _ => raise(SpatialError(where ++ ": unknown evidence kind '" ++ s ++ "'"))
  }

let evidenceKindName = kind =>
  switch kind {
  | AuthorLocked => "author_locked"
  | PhysicalMeasurement => "physical_measurement"
  | AssetMeasurement => "asset_measurement"
  | Derived => "derived"
  | CatalogReference => "catalog_reference"
  | Estimate => "estimate"
  | StoryRequired => "story_required"
  | Unmeasured => "unmeasured"
  }

let decodeEvidence = (j, where): evidence => {
  let o = objOf(j, where)
  {
    id: reqStr(o, "id", where),
    kind: evidenceKindOf(reqStr(o, "kind", where), where ++ ".kind"),
    note: optStr(o, "note")->Belt.Option.getWithDefault(""),
    inputs: optArray(o, "inputs", where)->stringsOf(where ++ ".inputs"),
  }
}

let decodeNamedPoints = (o: Js.Dict.t<Js.Json.t>, where: string, defaultEvidence: string): array<namedPoint> =>
  Js.Dict.entries(o)->Belt.Array.map(((id, j)) => {
    let p = objOf(j, where ++ "." ++ id)
    let value = switch get(p, "value") {
    | Some(v) => pointOf(v, where ++ "." ++ id ++ ".value")
    | None => raise(SpatialError(where ++ "." ++ id ++ ": missing point field 'value'"))
    }
    {id, value, evidence: optStr(p, "evidence")->Belt.Option.getWithDefault(defaultEvidence)}
  })

let orientationOf = (value, where): orientation =>
  switch value {
  | "xyz" => Xyz
  | "yxz" => Yxz
  | _ => raise(SpatialError(where ++ ": unsupported orientation '" ++ value ++ "'"))
  }

let orientationName = orientation =>
  switch orientation {
  | Xyz => "xyz"
  | Yxz => "yxz"
  }

let openingPlaneOf = (value, where): openingPlane =>
  switch value {
  | "xy" => XY
  | "xz" => XZ
  | "yz" => YZ
  | _ => raise(SpatialError(where ++ ": unsupported opening plane '" ++ value ++ "'"))
  }

let openingPlaneName = plane =>
  switch plane {
  | XY => "xy"
  | XZ => "xz"
  | YZ => "yz"
  }

let openingEdgeOf = (value, where): openingEdge =>
  switch value {
  | "u_min" => UMin
  | "u_max" => UMax
  | "v_min" => VMin
  | "v_max" => VMax
  | _ => raise(SpatialError(where ++ ": unsupported opening edge '" ++ value ++ "'"))
  }

let openingEdgeName = edge =>
  switch edge {
  | UMin => "u_min"
  | UMax => "u_max"
  | VMin => "v_min"
  | VMax => "v_max"
  }

let visibilityRiskOf = (value, where): visibilityRisk =>
  switch value {
  | "unclassified" => VisibilityUnclassified
  | "none" => NoVisibilityRisk
  | "exposed_to_giants" => ExposedToGiants
  | _ => raise(SpatialError(where ++ ": unsupported visibility risk '" ++ value ++ "'"))
  }

let safeOutputRelativePath = value =>
  Js.String2.split(value, "/")->Belt.Array.every(segment =>
    segment != "" && segment != "." && segment != ".." &&
    Js.Re.test_(%re("/^[A-Za-z0-9][A-Za-z0-9._-]*$/"), segment)
  )

let safeProofFile = value =>
  Js.Re.test_(%re("/^[A-Za-z0-9][A-Za-z0-9._-]*[.]svg$/"), value)

let decodeOpenings = (o: Js.Dict.t<Js.Json.t>, where: string, defaultEvidence: string): array<opening> =>
  Js.Dict.entries(o)->Belt.Array.map(((id, j)) => {
    let p = objOf(j, where ++ "." ++ id)
    ({
      id,
      plane: openingPlaneOf(reqStr(p, "plane", where ++ "." ++ id), where ++ "." ++ id ++ ".plane"),
      center: switch get(p, "center") {
      | Some(value) => pointOf(value, where ++ "." ++ id ++ ".center")
      | None => raise(SpatialError(where ++ "." ++ id ++ ": missing positioned opening center"))
      },
      spanU: reqPositive(p, "clearSpanU", where ++ "." ++ id),
      spanV: reqPositive(p, "clearSpanV", where ++ "." ++ id),
      evidence: optStr(p, "evidence")->Belt.Option.getWithDefault(defaultEvidence),
    }: opening)
  })

let decodeVolumes = (o: Js.Dict.t<Js.Json.t>, where: string, defaultEvidence: string): array<volume> =>
  Js.Dict.entries(o)->Belt.Array.map(((id, j)) => {
    let p = objOf(j, where ++ "." ++ id)
    ({
      id,
      bounds: aabbOf(reqObject(p, "aabb", where ++ "." ++ id), where ++ "." ++ id ++ ".aabb"),
      evidence: optStr(p, "evidence")->Belt.Option.getWithDefault(defaultEvidence),
    }: volume)
  })

let decodeDestinations = (o: Js.Dict.t<Js.Json.t>, where: string, defaultEvidence: string): array<destination> =>
  Js.Dict.entries(o)->Belt.Array.map(((id, j)) => {
    let p = objOf(j, where ++ "." ++ id)
    ({
      id,
      evidence: optStr(p, "evidence")->Belt.Option.getWithDefault(defaultEvidence),
      barrierAnchorId: reqStr(p, "barrierAnchor", where ++ "." ++ id),
      floorAnchorId: reqStr(p, "floorAnchor", where ++ "." ++ id),
      supportAnchorId: reqStr(p, "supportAnchor", where ++ "." ++ id),
      openingId: reqStr(p, "opening", where ++ "." ++ id),
      barrierEdge: openingEdgeOf(
        reqStr(p, "barrierEdge", where ++ "." ++ id),
        where ++ "." ++ id ++ ".barrierEdge",
      ),
      volumeId: reqStr(p, "volume", where ++ "." ++ id),
    }: destination)
  })

let emptyObject = (): Js.Dict.t<Js.Json.t> => Js.Dict.empty()

let optObject = (o, k, where) =>
  switch get(o, k) {
  | Some(j) => objOf(j, where ++ "." ++ k)
  | None => emptyObject()
  }

let decodeState = (j, where): state => {
  let o = objOf(j, where)
  let evidence = reqStr(o, "evidence", where)
  {
    id: reqStr(o, "id", where),
    evidence,
    bounds: aabbOf(reqObject(o, "aabb", where), where ++ ".aabb"),
    anchors: decodeNamedPoints(optObject(o, "anchors", where), where ++ ".anchors", evidence),
    grips: decodeNamedPoints(optObject(o, "grips", where), where ++ ".grips", evidence),
    openings: decodeOpenings(optObject(o, "openings", where), where ++ ".openings", evidence),
    volumes: decodeVolumes(optObject(o, "volumes", where), where ++ ".volumes", evidence),
    destinations: decodeDestinations(
      optObject(o, "destinations", where),
      where ++ ".destinations",
      evidence,
    ),
    visibilityRisk: visibilityRiskOf(
      optStr(o, "visibilityRisk")->Belt.Option.getWithDefault("unclassified"),
      where ++ ".visibilityRisk",
    ),
    orientations: optArray(o, "allowedOrientations", where)
      ->stringsOf(where ++ ".allowedOrientations")
      ->Belt.Array.mapWithIndex((index, value) =>
        orientationOf(value, where ++ ".allowedOrientations[" ++ Belt.Int.toString(index) ++ "]")
      ),
    affordances: optArray(o, "affordances", where)->stringsOf(where ++ ".affordances"),
  }
}

let decodeCapability = (id, j, where): capability => {
  let o = objOf(j, where)
  let stateIds = reqArray(o, "states", where)->stringsOf(where ++ ".states")
  if Belt.Array.length(stateIds) == 0 || hasDuplicateStrings(stateIds) {
    raise(SpatialError(where ++ ".states: expected one or more distinct bound state IDs"))
  }
  {
    id,
    evidence: reqStr(o, "evidence", where),
    stateIds,
    maxHandHeightLoaded: reqPositive(o, "maxHandHeightLoaded", where),
    armReachLoaded: reqPositive(o, "armReachLoaded", where),
    maxLiftMassG: reqNonnegative(o, "maxLiftMassG", where),
    maxCarryMassG: reqNonnegative(o, "maxCarryMassG", where),
    maxDragMassG: reqNonnegative(o, "maxDragMassG", where),
  }
}

let handlingMethodOf = (s, where): handlingMethod =>
  switch s {
  | "one_person_lift" => OnePersonLift
  | "two_person_lift" => TwoPersonLift
  | "one_person_drag" => OnePersonDrag
  | "two_person_drag" => TwoPersonDrag
  | "two_person_fold_on_floor" => TwoPersonFoldOnFloor
  | "papa_spin" => PapaSpin
  | "ride" => Ride
  | "push_by_hand" => PushByHand
  | "carry_thread_in_jaws" => CarryThreadInJaws
  | "crawl_with_folded_wings" => CrawlWithFoldedWings
  | "pay_out" => PayOut
  | "thread_pull" => ThreadPull
  | "hand_over_hand_pull" => HandOverHandPull
  | _ => raise(SpatialError(where ++ ": unsupported handling method '" ++ s ++ "'"))
  }

let handlingMethodName = method =>
  switch method {
  | OnePersonLift => "one_person_lift"
  | TwoPersonLift => "two_person_lift"
  | OnePersonDrag => "one_person_drag"
  | TwoPersonDrag => "two_person_drag"
  | TwoPersonFoldOnFloor => "two_person_fold_on_floor"
  | PapaSpin => "papa_spin"
  | Ride => "ride"
  | PushByHand => "push_by_hand"
  | CarryThreadInJaws => "carry_thread_in_jaws"
  | CrawlWithFoldedWings => "crawl_with_folded_wings"
  | PayOut => "pay_out"
  | ThreadPull => "thread_pull"
  | HandOverHandPull => "hand_over_hand_pull"
  }

let methodActorCount = method =>
  switch method {
  | OnePersonLift | OnePersonDrag => 1
  | TwoPersonLift | TwoPersonDrag | TwoPersonFoldOnFloor => 2
  | PapaSpin | Ride | PushByHand | CarryThreadInJaws | CrawlWithFoldedWings | PayOut | ThreadPull | HandOverHandPull => 1
  }

let decodeEntity = (j, where): entity => {
  let o = objOf(j, where)
  let mass = switch get(o, "massG") {
  | None => None
  | Some(j) => {
      let m = objOf(j, where ++ ".massG")
      Some({value: reqPositive(m, "value", where ++ ".massG"), evidence: reqStr(m, "evidence", where ++ ".massG")})
    }
  }
  let capabilities =
    Js.Dict.entries(optObject(o, "capabilities", where))
    ->Belt.Array.map(((id, row)) => decodeCapability(id, row, where ++ ".capabilities." ++ id))
  let handlingPermissions = optArray(o, "handlingMethods", where)
    ->Belt.Array.mapWithIndex((index, row) => {
      let methodWhere = where ++ ".handlingMethods[" ++ Belt.Int.toString(index) ++ "]"
      let permission = objOf(row, methodWhere)
      let stateIds = reqArray(permission, "states", methodWhere)->stringsOf(methodWhere ++ ".states")
      if Belt.Array.length(stateIds) == 0 || hasDuplicateStrings(stateIds) {
        raise(SpatialError(methodWhere ++ ".states: expected one or more distinct bound state IDs"))
      }
      {
        method: handlingMethodOf(reqStr(permission, "kind", methodWhere), methodWhere ++ ".kind"),
        stateIds,
      }
    })
  {
    id: reqStr(o, "id", where),
    label: reqStr(o, "label", where),
    kind: reqStr(o, "kind", where),
    states: reqArray(o, "states", where)->Belt.Array.mapWithIndex((i, row) =>
      decodeState(row, where ++ ".states[" ++ Belt.Int.toString(i) ++ "]")
    ),
    capabilities,
    mass,
    handlingPermissions,
  }
}

let decodeRegistry = raw => {
  let root = Js.Json.parseExn(raw)->objOf("registry")
  let unitsObject = reqObject(root, "units", "registry")
  let units = {
    length: reqStr(unitsObject, "length", "registry.units"),
    mass: reqStr(unitsObject, "mass", "registry.units"),
    time: reqStr(unitsObject, "time", "registry.units"),
    axes: reqStr(unitsObject, "axes", "registry.units"),
  }
  if units.length != "in" || units.mass != "g" || units.time != "s" || units.axes != "x=left-right,y=front-back,z=up" {
    raise(SpatialError("registry.units: expected inches, grams, seconds, and axes x=left-right,y=front-back,z=up"))
  }
  let registry = {
    schema: reqStr(root, "schema", "registry"),
    units,
    evidence: reqArray(root, "evidence", "registry")->Belt.Array.mapWithIndex((i, row) =>
      decodeEvidence(row, "registry.evidence[" ++ Belt.Int.toString(i) ++ "]")
    ),
    entities: reqArray(root, "entities", "registry")->Belt.Array.mapWithIndex((i, row) =>
      decodeEntity(row, "registry.entities[" ++ Belt.Int.toString(i) ++ "]")
    ),
  }
  if registry.schema != "drakosha.physical-registry/v1" {
    raise(SpatialError("registry.schema: unsupported schema '" ++ registry.schema ++ "'"))
  }
  registry
}

let decisionStatusOf = (s, where) =>
  switch s {
  | "author_approved" => AuthorApproved
  | "proposed" => Proposed
  | "superseded" => Superseded
  | "rejected" => Rejected
  | _ => raise(SpatialError(where ++ ": unknown decision status '" ++ s ++ "'"))
  }

let decisionStatusName = status =>
  switch status {
  | AuthorApproved => "author_approved"
  | Proposed => "proposed"
  | Superseded => "superseded"
  | Rejected => "rejected"
  }

let coverageClassOf = (s, where) =>
  switch s {
  | "physical" => Physical
  | "none" => NoneDeclared
  | "pending" => Pending
  | _ => raise(SpatialError(where ++ ": unknown coverage classification '" ++ s ++ "'"))
  }

let noneReasonOf = (s, where): noneReason =>
  switch s {
  | "spoken_dialogue_only" => SpokenDialogueOnly
  | "static_text_card" => StaticTextCard
  | "sound_only" => SoundOnly
  | "static_establishing_image" => StaticEstablishingImage
  | _ => raise(SpatialError(where ++ ": unsupported nonphysical reason '" ++ s ++ "'"))
  }

let decodeActor = (j, where): actorAssignment => {
  let o = objOf(j, where)
  let stance = switch get(o, "stance") {
  | None => None
  | Some(value) => Some(pointOf(value, where ++ ".stance"))
  }
  {
    entityId: reqStr(o, "entity", where),
    stateId: reqStr(o, "state", where),
    capabilityId: reqStr(o, "capability", where),
    gripId: reqStr(o, "grip", where),
    stance,
    stanceEvidence: optStr(o, "stanceEvidence")->Belt.Option.getWithDefault(""),
    shoulderAnchor: optStr(o, "shoulderAnchor")->Belt.Option.getWithDefault(""),
  }
}

let decodeObjectRef = (o, key, where): objectRef => {
  let r = reqObject(o, key, where)
  {entityId: reqStr(r, "entity", where ++ "." ++ key), stateId: reqStr(r, "state", where ++ "." ++ key)}
}

let decodeInteraction = (j, where): interaction => {
  let o = objOf(j, where)
  let actionType = reqStr(o, "type", where)
  let actors = reqArray(o, "actors", where)->Belt.Array.mapWithIndex((i, row) =>
    decodeActor(row, where ++ ".actors[" ++ Belt.Int.toString(i) ++ "]")
  )
  let action = switch actionType {
  | "place_into" => {
      let target = reqObject(o, "target", where)
      let method = reqObject(o, "method", where)
      if get(method, "requiresProtectedApproach") != None {
        raise(SpatialError(where ++ ".method: visibility risk belongs to the registered target state, not the interaction"))
      }
      let methodKind = handlingMethodOf(reqStr(method, "kind", where ++ ".method"), where ++ ".method.kind")
      switch methodKind {
      | OnePersonLift | TwoPersonLift => ()
      | _ => raise(SpatialError(where ++ ": place_into requires an explicit lift method"))
      }
      PlaceInto({
        actors,
        subject: decodeObjectRef(o, "object", where),
        target: {entityId: reqStr(target, "entity", where ++ ".target"), stateId: reqStr(target, "state", where ++ ".target")},
        destinationId: reqStr(target, "destination", where ++ ".target"),
        orientation: orientationOf(reqStr(o, "orientation", where), where ++ ".orientation"),
        method: methodKind,
        clearance: reqNonnegative(method, "clearance", where ++ ".method"),
      })
    }
  | "move_object" => {
      let method = reqObject(o, "method", where)
      if get(method, "requiresProtectedApproach") != None {
        raise(SpatialError(where ++ ".method: visibility risk belongs to the registered path state, not the interaction"))
      }
      let methodKind = handlingMethodOf(reqStr(method, "kind", where ++ ".method"), where ++ ".method.kind")
      switch methodKind {
      | OnePersonDrag | TwoPersonDrag => ()
      | _ => raise(SpatialError(where ++ ": move_object currently supports only explicit drag methods"))
      }
      MoveObject({
        actors,
        subject: decodeObjectRef(o, "object", where),
        path: decodeObjectRef(o, "path", where),
        orientation: orientationOf(reqStr(o, "orientation", where), where ++ ".orientation"),
        method: methodKind,
      })
    }
  | _ => raise(SpatialError(where ++ ": unsupported interaction type '" ++ actionType ++ "'"))
  }
  let expectedActors = switch action {
  | PlaceInto(a) => methodActorCount(a.method)
  | MoveObject(a) => methodActorCount(a.method)
  }
  if Belt.Array.length(actors) != expectedActors {
    raise(SpatialError(where ++ ": " ++ handlingMethodName(switch action { | PlaceInto(a) => a.method | MoveObject(a) => a.method }) ++ " requires exactly " ++ Belt.Int.toString(expectedActors) ++ " actor assignment(s)"))
  }
  actors->Belt.Array.forEachWithIndex((index, actor) => {
    if actor.stance == None || Js.String2.length(actor.stanceEvidence) == 0 || Js.String2.length(actor.shoulderAnchor) == 0 {
      raise(SpatialError(where ++ ".actors[" ++ Belt.Int.toString(index) ++ "]: every handled-object assignment requires stance, stanceEvidence, and shoulderAnchor for reach proof"))
    }
    switch actor.stance {
    | Some(stance) if stance.z != 0.0 =>
      raise(SpatialError(where ++ ".actors[" ++ Belt.Int.toString(index) ++ "].stance: schema v1 requires z=0; elevated support needs registered support geometry in a later schema"))
    | _ => ()
    }
  })
  let actorIds = actors->Belt.Array.map(a => a.entityId)
  let gripIds = actors->Belt.Array.map(a => a.gripId)
  if hasDuplicateStrings(actorIds) {
    raise(SpatialError(where ++ ": actor assignments must name distinct entities"))
  }
  if hasDuplicateStrings(gripIds) {
    raise(SpatialError(where ++ ": actor assignments must use distinct object grips"))
  }
  let proof = switch get(o, "proof") {
  | None => None
  | Some(j) => {
      let proofObject = objOf(j, where ++ ".proof")
      let sideFile = reqStr(proofObject, "sideFile", where ++ ".proof")
      let planFile = reqStr(proofObject, "planFile", where ++ ".proof")
      if !safeProofFile(sideFile) || !safeProofFile(planFile) {
        raise(SpatialError(where ++ ".proof: filenames must be single safe ASCII .svg leaf names"))
      }
      if sideFile == planFile {
        raise(SpatialError(where ++ ".proof: sideFile and planFile must be distinct"))
      }
      Some({sideFile, planFile})
    }
  }
  switch (action, proof) {
  | (PlaceInto(_), None) =>
    raise(SpatialError(where ++ ": place_into requires distinct side-elevation and approach-topology proof outputs"))
  | (MoveObject(_), Some(_)) =>
    raise(SpatialError(where ++ ": move_object proof output is not supported until a swept-formation renderer is implemented"))
  | _ => ()
  }
  let shotIds = reqArray(o, "shotIds", where)->stringsOf(where ++ ".shotIds")
  if Belt.Array.length(shotIds) == 0 {
    raise(SpatialError(where ++ ".shotIds: at least one exact shot link is required"))
  }
  let decisionRefs = reqArray(o, "decisionRefs", where)->stringsOf(where ++ ".decisionRefs")
  if Belt.Array.length(decisionRefs) == 0 {
    raise(SpatialError(where ++ ".decisionRefs: every physical interaction must consume at least one explicit author decision"))
  }
  let criticality = switch reqStr(o, "criticality", where) {
  | "blocking" => BlockingCriticality
  | value => raise(SpatialError(where ++ ".criticality: unsupported value '" ++ value ++ "'; every release interaction is blocking"))
  }
  {
    id: reqStr(o, "id", where),
    shotIds,
    decisionRefs,
    criticality,
    action,
    proof,
  }
}

let decodeManifest = raw => {
  let root = Js.Json.parseExn(raw)->objOf("manifest")
  let source = reqObject(root, "source", "manifest")
  let backlog = reqObject(root, "physicalBacklog", "manifest")
  let output = reqObject(root, "output", "manifest")
  let reportPath = reqStr(output, "reportPath", "manifest.output")
  let proofDir = reqStr(output, "proofDir", "manifest.output")
  let indexPath = reqStr(output, "indexPath", "manifest.output")
  if !safeOutputRelativePath(reportPath) || !Js.String2.endsWith(reportPath, ".md") {
    raise(SpatialError("manifest.output.reportPath: expected a safe relative .md path"))
  }
  if !safeOutputRelativePath(proofDir) {
    raise(SpatialError("manifest.output.proofDir: expected a safe relative directory path"))
  }
  if !safeOutputRelativePath(indexPath) || !Js.String2.endsWith(indexPath, ".json") {
    raise(SpatialError("manifest.output.indexPath: expected a safe relative .json path"))
  }
  let manifest = {
    schema: reqStr(root, "schema", "manifest"),
    profile: reqStr(root, "profile", "manifest"),
    source: {
      path: reqStr(source, "path", "manifest.source"),
      sha256: reqStr(source, "sha256", "manifest.source"),
      expectedShotCount: reqInt(source, "expectedShotCount", "manifest.source"),
    },
    backlog: {
      path: reqStr(backlog, "path", "manifest.physicalBacklog"),
      sha256: reqStr(backlog, "sha256", "manifest.physicalBacklog"),
      openItemIds: reqArray(backlog, "openItemIds", "manifest.physicalBacklog")->stringsOf("manifest.physicalBacklog.openItemIds"),
    },
    output: {
      reportPath,
      proofDir,
      indexPath,
    },
    decisions: reqArray(root, "decisions", "manifest")->Belt.Array.mapWithIndex((i, row) => {
      let where = "manifest.decisions[" ++ Belt.Int.toString(i) ++ "]"
      let o = objOf(row, where)
      {
        id: reqStr(o, "id", where),
        status: decisionStatusOf(reqStr(o, "status", where), where ++ ".status"),
        note: optStr(o, "note")->Belt.Option.getWithDefault(""),
      }
    }),
    coverage: reqArray(root, "coverage", "manifest")->Belt.Array.mapWithIndex((i, row) => {
      let where = "manifest.coverage[" ++ Belt.Int.toString(i) ++ "]"
      let o = objOf(row, where)
      let classification = coverageClassOf(reqStr(o, "classification", where), where ++ ".classification")
      let reasonCode = optStr(o, "reasonCode")
      let exemptionRef = optStr(o, "exemptionDecisionRef")
      let (reason, exemptionDecisionRef) = switch (classification, reasonCode, exemptionRef) {
      | (NoneDeclared, Some(code), Some(decisionRef)) => (Some(noneReasonOf(code, where ++ ".reasonCode")), Some(decisionRef))
      | (NoneDeclared, _, _) => raise(SpatialError(where ++ ": nonphysical coverage requires both a closed reasonCode and exemptionDecisionRef"))
      | (_, Some(_), _) | (_, _, Some(_)) => raise(SpatialError(where ++ ": nonphysical exemption fields are allowed only when classification is 'none'"))
      | (_, None, None) => (None, None)
      }
      {
        shotId: reqStr(o, "shotId", where),
        blockSha256: reqStr(o, "blockSha256", where),
        classification,
        interactionIds: optArray(o, "interactionIds", where)->stringsOf(where ++ ".interactionIds"),
        reason,
        exemptionDecisionRef,
      }
    }),
    interactions: reqArray(root, "interactions", "manifest")->Belt.Array.mapWithIndex((i, row) =>
      decodeInteraction(row, "manifest.interactions[" ++ Belt.Int.toString(i) ++ "]")
    ),
  }
  if manifest.schema != "drakosha.physical-manifest/v1" {
    raise(SpatialError("manifest.schema: unsupported schema '" ++ manifest.schema ++ "'"))
  }
  manifest
}

/* ---- source parsing and hashing ---------------------------------------- */

type hash
@module("crypto") external createHash: string => hash = "createHash"
@send external hUpdate: (hash, string) => hash = "update"
@send external hDigest: (hash, string) => string = "digest"

let sha256 = s => createHash("sha256")->hUpdate(s)->hDigest("hex")

let validateBacklogRaw = (~manifest: manifest, ~raw: string): unit => {
  let actualHash = sha256(raw)
  if actualHash != manifest.backlog.sha256 {
    raise(SpatialError("physical backlog hash mismatch: expected " ++ manifest.backlog.sha256 ++ " but found " ++ actualHash))
  }
  let root = Js.Json.parseExn(raw)->objOf("physical backlog")
  if reqStr(root, "schema", "physical backlog") != "drakosha.physical-backlog/v1" {
    raise(SpatialError("physical backlog: unsupported schema"))
  }
  let openIds = reqArray(root, "items", "physical backlog")
    ->Belt.Array.mapWithIndex((index, row) => {
      let where = "physical backlog.items[" ++ Belt.Int.toString(index) ++ "]"
      let item = objOf(row, where)
      let id = reqStr(item, "id", where)
      let status = reqStr(item, "status", where)
      switch status {
      | "resolved" => None
      | "blocking" | "rejected" | "needs_proxy" | "needs_layout" | "blocking_until_proxy" | "needs_plan" => Some(id)
      | _ => raise(SpatialError(where ++ ": unsupported status '" ++ status ++ "'"))
      }
    })
    ->Belt.Array.keepMap(x => x)
  if hasDuplicateStrings(openIds) || hasDuplicateStrings(manifest.backlog.openItemIds) {
    raise(SpatialError("physical backlog/openItemIds contains duplicate IDs"))
  }
  let sameItems = Belt.Array.length(openIds) == Belt.Array.length(manifest.backlog.openItemIds) &&
    Belt.Array.every(openIds, id => Belt.Array.some(manifest.backlog.openItemIds, expected => expected == id))
  if !sameItems {
    raise(SpatialError("manifest.physicalBacklog.openItemIds does not exactly match unresolved backlog items"))
  }
}

let shotIdFromHeading = line => {
  if Js.String2.startsWith(line, "### SH") && Js.String2.length(line) >= 9 {
    let id = Js.String2.slice(line, ~from=4, ~to_=9)
    switch Js.String2.match_(id, %re("/^SH\d{3}$/")) {
    | Some(_) => Some(id)
    | None => None
    }
  } else {
    None
  }
}

let parseShotBlocks = screenplay => {
  let lines = Js.String2.split(screenplay, "\n")
  let blocks: array<shotBlock> = []
  let currentId = ref(None)
  let currentLines: ref<array<string>> = ref([])
  let finish = () =>
    switch currentId.contents {
    | None => ()
    | Some(id) => {
        let raw = Js.Array2.joinWith(currentLines.contents, "\n")
        let _ = Js.Array2.push(blocks, {id, raw, sha256: sha256(raw)})
      }
    }
  lines->Belt.Array.forEach(line =>
    switch shotIdFromHeading(line) {
    | Some(id) => {
        finish()
        currentId := Some(id)
        currentLines := [line]
      }
    | None =>
      switch currentId.contents {
      | Some(_) => {
          let _ = Js.Array2.push(currentLines.contents, line)
        }
      | None => ()
      }
    }
  )
  finish()
  blocks
}

/* ---- lookup and evidence ------------------------------------------------ */

let findEvidence = (registry, id) => registry.evidence->Belt.Array.getBy(e => e.id == id)
let findEntity = (registry, id) => registry.entities->Belt.Array.getBy(e => e.id == id)
let findState = (entity, id) => entity.states->Belt.Array.getBy(s => s.id == id)
let findCapability = (entity, id) => entity.capabilities->Belt.Array.getBy(c => c.id == id)
let findAnchor = (state, id) => state.anchors->Belt.Array.getBy(a => a.id == id)
let findGrip = (state, id) => state.grips->Belt.Array.getBy(a => a.id == id)
let findOpening = (state, id) => state.openings->Belt.Array.getBy(a => a.id == id)
let findVolume = (state, id) => state.volumes->Belt.Array.getBy(a => a.id == id)
let findDestination = (state, id) => state.destinations->Belt.Array.getBy(a => a.id == id)
let findDecision = (manifest, id) => manifest.decisions->Belt.Array.getBy(d => d.id == id)
let findCoverage = (manifest, id) => manifest.coverage->Belt.Array.getBy(c => c.shotId == id)
let findInteraction = (manifest, id) => manifest.interactions->Belt.Array.getBy(i => i.id == id)
let handlingAllowed = (entity: entity, stateId: string, method: handlingMethod): bool =>
  entity.handlingPermissions->Belt.Array.some(permission =>
    permission.method == method && permission.stateIds->Belt.Array.some(id => id == stateId)
  )
let handlingMethodsForState = (entity: entity, stateId: string): array<string> =>
  entity.handlingPermissions
  ->Belt.Array.keep(permission => permission.stateIds->Belt.Array.some(id => id == stateId))
  ->Belt.Array.map(permission => handlingMethodName(permission.method))

let certifyingEvidence = (registry, id): bool => {
  let visiting: array<string> = []
  let rec trusted = id => {
    if Belt.Array.some(visiting, x => x == id) {
      false
    } else {
      switch findEvidence(registry, id) {
      | None => false
      | Some(e) =>
        switch e.kind {
        | AuthorLocked | PhysicalMeasurement => true
        | Derived => {
            let _ = Js.Array2.push(visiting, id)
            let ok = Belt.Array.length(e.inputs) > 0 && Belt.Array.every(e.inputs, trusted)
            let _ = Js.Array2.pop(visiting)
            ok
          }
        /* Asset evidence is fail-closed until the referenced asset and its
           measurement receipt are hash-verified by the asset pipeline. */
        | AssetMeasurement | CatalogReference | Estimate | StoryRequired | Unmeasured => false
        }
      }
    }
  }
  trusted(id)
}

let evidenceFailureCode = kind =>
  switch kind {
  | StoryRequired => "EVD_STORY_REQUIREMENT_USED"
  | Unmeasured => "EVD_UNMEASURED_USED"
  | Estimate => "EVD_ESTIMATE_USED_IN_RELEASE"
  | CatalogReference => "EVD_CATALOG_USED_IN_RELEASE"
  | AssetMeasurement => "EVD_ASSET_NOT_HASH_VERIFIED"
  | Derived => "EVD_DERIVATION_UNTRUSTED"
  | AuthorLocked | PhysicalMeasurement => "EVD_MISSING"
  }

let f2 = n => Js.Float.toFixedWithPrecision(n, ~digits=2)

let replaceAllLiteral = (value, needle, replacement) =>
  value->Js.String2.split(needle)->Js.Array2.joinWith(replacement)

let xmlEscape = value =>
  value
  ->replaceAllLiteral("&", "&amp;")
  ->replaceAllLiteral("<", "&lt;")
  ->replaceAllLiteral(">", "&gt;")
  ->replaceAllLiteral("\"", "&quot;")
  ->replaceAllLiteral("'", "&apos;")

let markdownText = value =>
  value
  ->xmlEscape
  ->replaceAllLiteral("|", "&#124;")
  ->replaceAllLiteral("`", "&#96;")
  ->replaceAllLiteral("[", "&#91;")
  ->replaceAllLiteral("]", "&#93;")
  ->replaceAllLiteral("\r", " ")
  ->replaceAllLiteral("\n", " ")

let orientPoint = (value: point, orientation: orientation): point =>
  switch orientation {
  | Xyz => value
  /* yxz is a right-handed +90-degree yaw about +z:
     x'=-y, y'=x, z'=z.  It is never a mirror/sort operation. */
  | Yxz => {x: -.value.y, y: value.x, z: value.z}
  }

let orientBounds = (bounds: aabb, orientation: orientation): aabb =>
  switch orientation {
  | Xyz => bounds
  | Yxz => {
      min: {x: -.bounds.max.y, y: bounds.min.x, z: bounds.min.z},
      max: {x: -.bounds.min.y, y: bounds.max.x, z: bounds.max.z},
    }
  }

let translateBounds = (bounds: aabb, offset: point): aabb => {
  min: {
    x: bounds.min.x +. offset.x,
    y: bounds.min.y +. offset.y,
    z: bounds.min.z +. offset.z,
  },
  max: {
    x: bounds.max.x +. offset.x,
    y: bounds.max.y +. offset.y,
    z: bounds.max.z +. offset.z,
  },
}

let boundsOverlap = (left: aabb, right: aabb): bool =>
  left.max.x > right.min.x && left.min.x < right.max.x &&
  left.max.y > right.min.y && left.min.y < right.max.y &&
  left.max.z > right.min.z && left.min.z < right.max.z

let unionBounds = (left: aabb, right: aabb): aabb => {
  min: {
    x: min(left.min.x, right.min.x),
    y: min(left.min.y, right.min.y),
    z: min(left.min.z, right.min.z),
  },
  max: {
    x: max(left.max.x, right.max.x),
    y: max(left.max.y, right.max.y),
    z: max(left.max.z, right.max.z),
  },
}

let boundsWidth = (bounds: aabb) => bounds.max.x -. bounds.min.x
let boundsDepth = (bounds: aabb) => bounds.max.y -. bounds.min.y
let boundsHeight = (bounds: aabb) => bounds.max.z -. bounds.min.z

let pointInsideBounds = (value: point, bounds: aabb): bool =>
  value.x >= bounds.min.x && value.x <= bounds.max.x &&
  value.y >= bounds.min.y && value.y <= bounds.max.y &&
  value.z >= bounds.min.z && value.z <= bounds.max.z

let boundsInsideBounds = (inner: aabb, outer: aabb): bool =>
  inner.min.x >= outer.min.x && inner.max.x <= outer.max.x &&
  inner.min.y >= outer.min.y && inner.max.y <= outer.max.y &&
  inner.min.z >= outer.min.z && inner.max.z <= outer.max.z

let almostEqual = (left: float, right: float): bool => Js.Math.abs_float(left -. right) <= 0.000001

let openingInsideBounds = (opening: opening, bounds: aabb): bool => {
  let halfU = opening.spanU /. 2.0
  let halfV = opening.spanV /. 2.0
  switch opening.plane {
  | XY =>
    opening.center.x -. halfU >= bounds.min.x && opening.center.x +. halfU <= bounds.max.x &&
    opening.center.y -. halfV >= bounds.min.y && opening.center.y +. halfV <= bounds.max.y &&
    opening.center.z >= bounds.min.z && opening.center.z <= bounds.max.z
  | XZ =>
    opening.center.x -. halfU >= bounds.min.x && opening.center.x +. halfU <= bounds.max.x &&
    opening.center.z -. halfV >= bounds.min.z && opening.center.z +. halfV <= bounds.max.z &&
    opening.center.y >= bounds.min.y && opening.center.y <= bounds.max.y
  | YZ =>
    opening.center.y -. halfU >= bounds.min.y && opening.center.y +. halfU <= bounds.max.y &&
    opening.center.z -. halfV >= bounds.min.z && opening.center.z +. halfV <= bounds.max.z &&
    opening.center.x >= bounds.min.x && opening.center.x <= bounds.max.x
  }
}

/* Schema v1 certifies one deliberately narrow insertion path: an axis-aligned
   top aperture on the exact top face of its positioned interior.  Other
   planes must be modeled by a future path/sweep schema instead of guessed. */
let openingOnVolumeTop = (opening: opening, volume: volume): bool =>
  switch opening.plane {
  | XY =>
    almostEqual(opening.center.z, volume.bounds.max.z) &&
    opening.center.x -. opening.spanU /. 2.0 >= volume.bounds.min.x &&
    opening.center.x +. opening.spanU /. 2.0 <= volume.bounds.max.x &&
    opening.center.y -. opening.spanV /. 2.0 >= volume.bounds.min.y &&
    opening.center.y +. opening.spanV /. 2.0 <= volume.bounds.max.y
  | XZ | YZ => false
  }

let anchorOnOpeningEdge = (anchor: namedPoint, opening: opening, edge: openingEdge): bool => {
  let halfU = opening.spanU /. 2.0
  let halfV = opening.spanV /. 2.0
  switch opening.plane {
  | XY => {
      let u = anchor.value.x
      let v = anchor.value.y
      almostEqual(anchor.value.z, opening.center.z) &&
      switch edge {
      | UMin => almostEqual(u, opening.center.x -. halfU) && v >= opening.center.y -. halfV && v <= opening.center.y +. halfV
      | UMax => almostEqual(u, opening.center.x +. halfU) && v >= opening.center.y -. halfV && v <= opening.center.y +. halfV
      | VMin => almostEqual(v, opening.center.y -. halfV) && u >= opening.center.x -. halfU && u <= opening.center.x +. halfU
      | VMax => almostEqual(v, opening.center.y +. halfV) && u >= opening.center.x -. halfU && u <= opening.center.x +. halfU
      }
    }
  | XZ | YZ => false
  }
}

let openingSpans = (bounds: aabb, plane: openingPlane): (float, float) =>
  switch plane {
  | XY => (boundsWidth(bounds), boundsDepth(bounds))
  | XZ => (boundsWidth(bounds), boundsHeight(bounds))
  | YZ => (boundsDepth(bounds), boundsHeight(bounds))
  }

let straightDownFinalOffset = (
  ~entryOffset: point,
  ~subjectBounds: aabb,
  ~volumeBounds: aabb,
  ~clearance: float,
): point => {
  x: entryOffset.x,
  y: entryOffset.y,
  z: volumeBounds.min.z +. clearance -. subjectBounds.min.z,
}

/* ---- validation --------------------------------------------------------- */

let rec evaluate = (~registry, ~manifest, ~screenplay): evaluation => {
  let findings: array<finding> = []
  let passed: array<string> = []
  let artifacts: array<artifact> = []
  let add = (code, severity, scope, detail, remedy) => {
    let _ = Js.Array2.push(findings, {code, severity, scope, detail, remedy})
  }
  let addArtifact = (scope, artifact) =>
    if Belt.Array.some(artifacts, existing => existing.relativePath == artifact.relativePath) {
      add(
        "PRF_PATH_COLLISION",
        Blocking,
        scope,
        "more than one proof resolves to " ++ artifact.relativePath,
        "Give every proof plane and interaction an explicit unique output filename.",
      )
    } else {
      let _ = Js.Array2.push(artifacts, artifact)
    }
  let pass = detail => {
    let _ = Js.Array2.push(passed, detail)
  }
  let requireEvidence = (evidenceId, scope, feature) =>
    switch findEvidence(registry, evidenceId) {
    | None => add("EVD_MISSING", Blocking, scope, feature ++ " references missing evidence " ++ evidenceId, "Add a named evidence record; never substitute an estimate silently.")
    | Some(e) =>
      if !certifyingEvidence(registry, evidenceId) {
        add(
          evidenceFailureCode(e.kind),
          Blocking,
          scope,
          feature ++ " uses non-certifying " ++ evidenceKindName(e.kind) ++ " evidence " ++ evidenceId,
          "Measure and register the final asset/proxy, or explicitly lock a canonical dimension. Story-required geometry cannot certify itself.",
        )
      }
    }

  let checkUnique = (label, ids) => {
    let seen = Js.Dict.empty()
    let duplicates: array<string> = []
    ids->Belt.Array.forEach(id =>
      if Js.Dict.get(seen, id) == Some(true) {
        if !Belt.Array.some(duplicates, d => d == id) {
          let _ = Js.Array2.push(duplicates, id)
        }
      } else {
        Js.Dict.set(seen, id, true)
      }
    )
    if Belt.Array.length(duplicates) > 0 {
      add("REG_ID_DUPLICATE", Blocking, label, "duplicate IDs: " ++ Js.Array2.joinWith(duplicates, ", "), "Give every record one stable unique ID.")
    }
  }

  checkUnique("registry.evidence", registry.evidence->Belt.Array.map(e => e.id))
  checkUnique("registry.entities", registry.entities->Belt.Array.map(e => e.id))
  registry.entities->Belt.Array.forEach(entity => {
    checkUnique("registry.entities." ++ entity.id ++ ".states", entity.states->Belt.Array.map(state => state.id))
    checkUnique("registry.entities." ++ entity.id ++ ".capabilities", entity.capabilities->Belt.Array.map(capability => capability.id))
    checkUnique("registry.entities." ++ entity.id ++ ".handlingMethods", entity.handlingPermissions->Belt.Array.map(permission => handlingMethodName(permission.method)))
    entity.capabilities->Belt.Array.forEach(capability =>
      capability.stateIds->Belt.Array.forEach(stateId =>
        if !Belt.Array.some(entity.states, state => state.id == stateId) {
          add(
            "REG_CAPABILITY_STATE_MISSING",
            Blocking,
            "registry.entities." ++ entity.id ++ ".capabilities." ++ capability.id,
            "capability binds unknown state " ++ stateId,
            "Bind every capability to an existing exact actor pose.",
          )
        }
      )
    )
    entity.handlingPermissions->Belt.Array.forEach(permission =>
      permission.stateIds->Belt.Array.forEach(stateId =>
        if !Belt.Array.some(entity.states, state => state.id == stateId) {
          add(
            "REG_HANDLING_STATE_MISSING",
            Blocking,
            "registry.entities." ++ entity.id ++ ".handlingMethods",
            handlingMethodName(permission.method) ++ " binds unknown state " ++ stateId,
            "Bind every handling permission to an existing exact object state.",
          )
        }
      )
    )
    entity.states->Belt.Array.forEach(state => {
      let prefix = "registry.entities." ++ entity.id ++ ".states." ++ state.id
      checkUnique(prefix ++ ".anchors", state.anchors->Belt.Array.map(anchor => anchor.id))
      checkUnique(prefix ++ ".grips", state.grips->Belt.Array.map(grip => grip.id))
      checkUnique(prefix ++ ".openings", state.openings->Belt.Array.map(opening => opening.id))
      checkUnique(prefix ++ ".volumes", state.volumes->Belt.Array.map(volume => volume.id))
      checkUnique(prefix ++ ".destinations", state.destinations->Belt.Array.map(destination => destination.id))
      checkUnique(prefix ++ ".allowedOrientations", state.orientations->Belt.Array.map(orientationName))
      state.anchors->Belt.Array.forEach(anchor =>
        if !pointInsideBounds(anchor.value, state.bounds) {
          add(
            "REG_POINT_OUT_OF_BOUNDS",
            Blocking,
            prefix,
            "anchor " ++ anchor.id ++ " at [" ++ f2(anchor.value.x) ++ ", " ++ f2(anchor.value.y) ++ ", " ++ f2(anchor.value.z) ++ "] lies outside its owning state AABB",
            "Correct the measured state or anchor. A reach target cannot exist outside its owning prop/body envelope.",
          )
        }
      )
      state.grips->Belt.Array.forEach(grip =>
        if !pointInsideBounds(grip.value, state.bounds) {
          add(
            "REG_POINT_OUT_OF_BOUNDS",
            Blocking,
            prefix,
            "grip " ++ grip.id ++ " at [" ++ f2(grip.value.x) ++ ", " ++ f2(grip.value.y) ++ ", " ++ f2(grip.value.z) ++ "] lies outside its owning state AABB",
            "Correct the measured state or grip. Story-convenient contact points outside the prop cannot certify handling.",
          )
        }
      )
      state.openings->Belt.Array.forEach(opening => {
        if !openingInsideBounds(opening, state.bounds) {
          add(
            "REG_OPENING_EXCEEDS_STATE",
            Blocking,
            prefix,
            "positioned opening " ++ opening.id ++ " is not fully contained by its owning state AABB",
            "Measure both the aperture center and clear spans inside the exact target state.",
          )
        }
      })
      state.volumes->Belt.Array.forEach(volume =>
        if !boundsInsideBounds(volume.bounds, state.bounds) {
          add(
            "REG_VOLUME_EXCEEDS_STATE",
            Blocking,
            prefix,
            "positioned volume " ++ volume.id ++ " is not fully contained by its owning state AABB",
            "Measure the interior as an AABB inside the exact target state.",
          )
        }
      )
      state.destinations->Belt.Array.forEach(destination =>
        switch (
          findAnchor(state, destination.barrierAnchorId),
          findAnchor(state, destination.floorAnchorId),
          findAnchor(state, destination.supportAnchorId),
          findOpening(state, destination.openingId),
          findVolume(state, destination.volumeId),
        ) {
        | (None, _, _, _, _) =>
          add(
            "REG_DESTINATION_COMPONENT_MISSING",
            Blocking,
            prefix,
            "destination " ++ destination.id ++ " binds missing barrier anchor " ++ destination.barrierAnchorId,
            "Bind one measured anchor, opening, and interior from this exact target state.",
          )
        | (_, None, _, _, _) =>
          add(
            "REG_DESTINATION_COMPONENT_MISSING",
            Blocking,
            prefix,
            "destination " ++ destination.id ++ " binds missing floor anchor " ++ destination.floorAnchorId,
            "Bind the drawer/bin floor and its support structure to the same measured destination.",
          )
        | (_, _, None, _, _) =>
          add(
            "REG_DESTINATION_COMPONENT_MISSING",
            Blocking,
            prefix,
            "destination " ++ destination.id ++ " binds missing support anchor " ++ destination.supportAnchorId,
            "Bind the drawer/bin floor and its support structure to the same measured destination.",
          )
        | (_, _, _, None, _) =>
          add(
            "REG_DESTINATION_COMPONENT_MISSING",
            Blocking,
            prefix,
            "destination " ++ destination.id ++ " binds missing opening " ++ destination.openingId,
            "Bind one measured anchor, opening, and interior from this exact target state.",
          )
        | (_, _, _, _, None) =>
          add(
            "REG_DESTINATION_COMPONENT_MISSING",
            Blocking,
            prefix,
            "destination " ++ destination.id ++ " binds missing volume " ++ destination.volumeId,
            "Bind one measured anchor, opening, and interior from this exact target state.",
          )
        | (Some(anchor), Some(floor), Some(support), Some(opening), Some(volume)) => {
            if !openingOnVolumeTop(opening, volume) {
              add(
                "REG_DESTINATION_OPENING_DISCONNECTED",
                Blocking,
                prefix,
                "destination " ++ destination.id ++ " opening is not a supported positioned top face of its bound interior",
                "For schema v1, place the XY aperture on the interior max-z face; use a later swept-path schema for side insertion.",
              )
            }
            if !anchorOnOpeningEdge(anchor, opening, destination.barrierEdge) {
              add(
                "REG_DESTINATION_BARRIER_DISCONNECTED",
                Blocking,
                prefix,
                "destination " ++ destination.id ++ " barrier anchor is not on its declared " ++ openingEdgeName(destination.barrierEdge) ++ " aperture edge",
                "Measure and bind the actual rim edge. An unrelated low anchor cannot certify this destination.",
              )
            }
            if !almostEqual(floor.value.x, anchor.value.x) ||
              !almostEqual(floor.value.y, anchor.value.y) ||
              !almostEqual(floor.value.z, volume.bounds.min.z) {
              add(
                "REG_DESTINATION_FLOOR_DISCONNECTED",
                Blocking,
                prefix,
                "destination " ++ destination.id ++ " floor anchor is not vertically aligned with its rim at the bound interior floor",
                "Measure one structural drawer/bin section: support, floor, rim, opening, and interior must share a coordinate frame.",
              )
            }
            if support.value.z > volume.bounds.min.z {
              add(
                "REG_DESTINATION_SUPPORT_CONFLICT",
                Blocking,
                prefix,
                "destination " ++ destination.id ++ " support/underbody anchor rises above its interior floor",
                "Correct the measured furniture section; a drawer cannot occupy the same vertical space as its support/underbody clearance.",
              )
            }
          }
        }
      )
    })
  })
  checkUnique("manifest.decisions", manifest.decisions->Belt.Array.map(d => d.id))
  checkUnique("manifest.interactions", manifest.interactions->Belt.Array.map(i => i.id))
  checkUnique("manifest.coverage", manifest.coverage->Belt.Array.map(c => c.shotId))

  let blocks = parseShotBlocks(screenplay)
  let duplicateShotIds = {
    let seen = Js.Dict.empty()
    let duplicates: array<string> = []
    blocks->Belt.Array.forEach(block =>
      if Js.Dict.get(seen, block.id) == Some(true) {
        if !Belt.Array.some(duplicates, id => id == block.id) {
          let _ = Js.Array2.push(duplicates, block.id)
        }
      } else {
        Js.Dict.set(seen, block.id, true)
      }
    )
    duplicates
  }
  if Belt.Array.length(duplicateShotIds) > 0 {
    add(
      "SRC_SHOT_ID_DUPLICATE",
      Blocking,
      "screenplay",
      "duplicate shot headings: " ++ Js.Array2.joinWith(duplicateShotIds, ", "),
      "Every screenplay block needs one unique stable SH identifier before coverage can be trusted.",
    )
  }
  let sourceSha = sha256(screenplay)
  if sourceSha != manifest.source.sha256 {
    add(
      "SRC_HASH_MISMATCH",
      Blocking,
      "screenplay",
      "manifest expects " ++ manifest.source.sha256 ++ " but the current screenplay is " ++ sourceSha,
      "Re-audit the changed screenplay and update its manifest hash only after coverage and interactions are updated.",
    )
  } else {
    pass("screenplay hash matches the reviewed source")
  }
  if Belt.Array.length(manifest.backlog.openItemIds) > 0 {
    add(
      "PHY_BACKLOG_OPEN",
      Blocking,
      "physical backlog",
      Belt.Int.toString(Belt.Array.length(manifest.backlog.openItemIds)) ++ " unresolved production interactions remain; first: " ++ manifest.backlog.openItemIds->Belt.Array.slice(~offset=0, ~len=10)->Js.Array2.joinWith(", "),
      "Resolve the consolidated interaction items and move their measured, approved definitions into the manifest before release.",
    )
  } else {
    pass("physical interaction backlog is closed")
  }
  if Belt.Array.length(blocks) == 0 {
    add("SRC_NO_SHOT_BLOCKS", Blocking, "screenplay", "no ### SH### blocks were found", "Use stable SH identifiers in the shooting script.")
  } else if Belt.Array.length(blocks) != manifest.source.expectedShotCount {
    add(
      "SRC_SHOT_COUNT_MISMATCH",
      Blocking,
      "screenplay",
      "expected " ++ Belt.Int.toString(manifest.source.expectedShotCount) ++ " shots but parsed " ++ Belt.Int.toString(Belt.Array.length(blocks)),
      "Update the manifest only after every added or removed shot has a coverage classification.",
    )
  } else {
    pass(Belt.Int.toString(Belt.Array.length(blocks)) ++ " stable shot blocks parsed")
  }

  let missingCoverage = blocks->Belt.Array.keep(b => findCoverage(manifest, b.id) == None)
  if Belt.Array.length(missingCoverage) > 0 {
    add(
      "COV_SHOT_MISSING",
      Blocking,
      "coverage",
      Belt.Int.toString(Belt.Array.length(missingCoverage)) ++ " screenplay blocks have no classification; first: " ++
      missingCoverage->Belt.Array.slice(~offset=0, ~len=12)->Belt.Array.map(b => b.id)->Js.Array2.joinWith(", "),
      "Classify every SH block as physical, none, or pending. Release requires zero pending or missing rows.",
    )
  } else {
    pass("every screenplay block has one coverage row")
  }
  let unknownCoverage = manifest.coverage->Belt.Array.keep(c => blocks->Belt.Array.getBy(b => b.id == c.shotId) == None)
  if Belt.Array.length(unknownCoverage) > 0 {
    add("COV_SHOT_UNKNOWN", Blocking, "coverage", "unknown shot IDs: " ++ unknownCoverage->Belt.Array.map(c => c.shotId)->Js.Array2.joinWith(", "), "Remove stale coverage rows or restore the referenced shot blocks.")
  }
  let staleCoverage = manifest.coverage->Belt.Array.keep(c =>
    switch blocks->Belt.Array.getBy(b => b.id == c.shotId) {
    | Some(b) => b.sha256 != c.blockSha256
    | None => false
    }
  )
  if Belt.Array.length(staleCoverage) > 0 {
    add(
      "COV_BLOCK_HASH_MISMATCH",
      Blocking,
      "coverage",
      Belt.Int.toString(Belt.Array.length(staleCoverage)) ++ " classified blocks changed; first: " ++ staleCoverage->Belt.Array.slice(~offset=0, ~len=12)->Belt.Array.map(c => c.shotId)->Js.Array2.joinWith(", "),
      "Reclassify those exact shot blocks and update their interactions before accepting new hashes.",
    )
  }
  let pending = manifest.coverage->Belt.Array.keep(c => c.classification == Pending)
  if Belt.Array.length(pending) > 0 {
    let count = Belt.Array.length(pending)
    add("COV_PENDING", Blocking, "coverage", Belt.Int.toString(count) ++ (count == 1 ? " shot is" : " shots are") ++ " still pending physical classification", "Complete the physical/nonphysical classification before release.")
  }
  manifest.coverage->Belt.Array.forEach(c =>
    if c.classification == NoneDeclared {
      if Belt.Array.length(c.interactionIds) > 0 {
        add("COV_NONE_WITH_INTERACTION", Blocking, c.shotId, "a nonphysical exemption also links physical interactions", "Use physical classification for any shot with an interaction.")
      }
      switch c.exemptionDecisionRef {
      | None => add("COV_NONE_NOT_APPROVED", Blocking, c.shotId, "nonphysical exemption has no approval decision", "Attach an explicit author-approved exemption decision.")
      | Some(id) =>
        switch findDecision(manifest, id) {
        | Some({status: AuthorApproved}) => ()
        | Some(_) => add("COV_NONE_NOT_APPROVED", Blocking, c.shotId, "nonphysical exemption decision " ++ id ++ " is not author_approved", "Review this exact exemption before release.")
        | None => add("COV_NONE_NOT_APPROVED", Blocking, c.shotId, "nonphysical exemption references missing decision " ++ id, "Add and explicitly approve the exemption decision.")
        }
      }
    }
  )
  let physicalWithout = manifest.coverage->Belt.Array.keep(c => c.classification == Physical && Belt.Array.length(c.interactionIds) == 0)
  if Belt.Array.length(physicalWithout) > 0 {
    add(
      "COV_PHYSICAL_WITHOUT_INTERACTION",
      Blocking,
      "coverage",
      Belt.Int.toString(Belt.Array.length(physicalWithout)) ++ " physical shots lack structured interactions; first: " ++ physicalWithout->Belt.Array.slice(~offset=0, ~len=12)->Belt.Array.map(c => c.shotId)->Js.Array2.joinWith(", "),
      "Add named interactions with geometry and capability checks.",
    )
  }
  manifest.coverage->Belt.Array.forEach(c =>
    c.interactionIds->Belt.Array.forEach(id =>
      switch findInteraction(manifest, id) {
      | None => add("COV_INTERACTION_UNLINKED", Blocking, c.shotId, "coverage references missing interaction " ++ id, "Add the interaction or remove the stale link.")
      | Some(i) =>
        if !Belt.Array.some(i.shotIds, shot => shot == c.shotId) {
          add("COV_INTERACTION_SHOT_MISMATCH", Blocking, c.shotId, id ++ " does not list this shot in its shotIds", "Keep both sides of the coverage link identical.")
        }
      }
    )
  )
  manifest.interactions->Belt.Array.forEach(interaction =>
    interaction.shotIds->Belt.Array.forEach(shotId =>
      switch blocks->Belt.Array.getBy(b => b.id == shotId) {
      | None => add("COV_INTERACTION_SHOT_MISMATCH", Blocking, interaction.id, "interaction names unknown shot " ++ shotId, "Remove the stale reference or restore the shot block.")
      | Some(_) =>
        switch findCoverage(manifest, shotId) {
        | None => add("COV_INTERACTION_UNLINKED", Blocking, interaction.id, shotId ++ " has no coverage row linking this interaction", "Add the shot's hashed coverage row and link this interaction.")
        | Some(c) =>
          if !Belt.Array.some(c.interactionIds, id => id == interaction.id) {
            add("COV_INTERACTION_UNLINKED", Blocking, interaction.id, shotId ++ " does not link back to this interaction", "Keep both sides of every coverage link identical.")
          }
        }
      }
    )
  )

  let resolveEntity = (id, scope) =>
    switch findEntity(registry, id) {
    | Some(e) => Some(e)
    | None => {
        add("REG_ENTITY_MISSING", Blocking, scope, "missing entity " ++ id, "Add it to the physical registry with measured geometry.")
        None
      }
    }
  let resolveState = (entity, id, scope) =>
    switch findState(entity, id) {
    | Some(s) => Some(s)
    | None => {
        add("REG_STATE_MISSING", Blocking, scope, entity.id ++ " has no state " ++ id, "Register the exact action state; do not reuse an incompatible pose or object state.")
        None
      }
    }

  manifest.interactions->Belt.Array.forEach(interaction => {
    let scope = interaction.id ++ " [" ++ Js.Array2.joinWith(interaction.shotIds, ", ") ++ "]"
    interaction.decisionRefs->Belt.Array.forEach(id =>
      switch findDecision(manifest, id) {
      | None => add("DEC_MISSING", Blocking, scope, "missing decision " ++ id, "Record the decision and its author status.")
      | Some(d) =>
        switch d.status {
        | AuthorApproved => ()
        | Proposed => add("DEC_NOT_APPROVED", Blocking, scope, id ++ " is only proposed", "Do not publish an interaction until the author approves the underlying story choice.")
        | Superseded => add("DEC_SUPERSEDED", Blocking, scope, id ++ " was superseded", "Replace this interaction with the current approved decision.")
        | Rejected => add("DEC_REJECTED", Blocking, scope, id ++ " was rejected", "Remove the rejected staging and design a new interaction before rewriting prose.")
        }
      }
    )

    let checkActors = (actors: array<actorAssignment>): array<resolvedActor> =>
      actors->Belt.Array.map(a =>
        switch resolveEntity(a.entityId, scope) {
        | None => None
        | Some(entity) =>
          switch (resolveState(entity, a.stateId, scope), findCapability(entity, a.capabilityId)) {
          | (Some(state), Some(capability)) => {
              requireEvidence(state.evidence, scope, entity.id ++ "." ++ state.id ++ " geometry")
              requireEvidence(capability.evidence, scope, entity.id ++ "." ++ capability.id ++ " capability")
              if state.bounds.min.z != 0.0 {
                add(
                  "PHY_ACTOR_SUPPORT_MISMATCH",
                  Blocking,
                  scope,
                  entity.id ++ "." ++ state.id ++ " body envelope begins at z=" ++ f2(state.bounds.min.z) ++ " in while schema v1 actor stances require the registered support plane at z=0",
                  "Use a ground-supported pose with bounds.min.z=0, or add explicit support geometry in a later schema.",
                )
              }
              if !Belt.Array.some(capability.stateIds, stateId => stateId == state.id) {
                add(
                  "REG_CAPABILITY_STATE_MISMATCH",
                  Blocking,
                  scope,
                  entity.id ++ "." ++ capability.id ++ " is not bound to pose " ++ state.id,
                  "Use the capability measured for the exact actor pose; a prone envelope cannot borrow standing reach or strength.",
                )
              }
              Some((entity, state, capability, a))
            }
          | (_, None) => {
              add("REG_CAPABILITY_MISSING", Blocking, scope, entity.id ++ " has no capability " ++ a.capabilityId, "Register reach and force limits for the exact pose.")
              None
            }
          | _ => None
          }
        }
      )->Belt.Array.keepMap(x => x)

    let checkActorPairCollisions = (actors: array<resolvedActor>) =>
      actors->Belt.Array.forEachWithIndex((leftIndex, ((leftEntity, leftState, _, leftAssignment))) =>
        actors->Belt.Array.forEachWithIndex((rightIndex, ((rightEntity, rightState, _, rightAssignment))) =>
          if rightIndex > leftIndex {
            let leftBounds = translateBounds(leftState.bounds, leftAssignment.stance->Belt.Option.getExn)
            let rightBounds = translateBounds(rightState.bounds, rightAssignment.stance->Belt.Option.getExn)
            if boundsOverlap(leftBounds, rightBounds) {
              add(
                "PHY_ACTOR_ACTOR_COLLISION",
                Blocking,
                scope,
                leftEntity.id ++ " and " ++ rightEntity.id ++ " occupy overlapping body envelopes in their registered handled formation",
                "Register a collision-free team formation; separate grip assignments do not prove that both bodies fit.",
              )
            }
          }
        )
      )

    let checkActorSubjectCollisions = (~actors: array<resolvedActor>, ~subjectBounds: aabb, ~subjectLabel: string) =>
      actors->Belt.Array.forEach(((actorEntity, actorState, _, assignment)) => {
        let actorBounds = translateBounds(actorState.bounds, assignment.stance->Belt.Option.getExn)
        if boundsOverlap(actorBounds, subjectBounds) {
          add(
            "PHY_ACTOR_SUBJECT_COLLISION",
            Blocking,
            scope,
            actorEntity.id ++ " body envelope overlaps the handled " ++ subjectLabel ++ " envelope",
            "Register a body-clear handled stance. Hand contact at a grip does not permit the actor's body to pass through the prop.",
          )
        }
      })

    switch interaction.action {
    | PlaceInto(action) => {
        let actors = checkActors(action.actors)
        checkActorPairCollisions(actors)
        switch (resolveEntity(action.subject.entityId, scope), resolveEntity(action.target.entityId, scope)) {
        | (Some(subject), Some(target)) =>
          switch (resolveState(subject, action.subject.stateId, scope), resolveState(target, action.target.stateId, scope)) {
          | (Some(subjectState), Some(targetState)) => {
              requireEvidence(subjectState.evidence, scope, subject.id ++ "." ++ subjectState.id ++ " geometry")
              requireEvidence(targetState.evidence, scope, target.id ++ "." ++ targetState.id ++ " geometry")
              if !Belt.Array.some(subjectState.orientations, allowed => allowed == action.orientation) {
                add(
                  "PHY_ORIENTATION_NOT_ALLOWED",
                  Blocking,
                  scope,
                  subject.id ++ "." ++ subjectState.id ++ " does not allow placement orientation " ++ orientationName(action.orientation),
                  "Register and measure the exact handled orientation; the evaluator never chooses a best-case rotation.",
                )
              }
              let subjectBounds = orientBounds(subjectState.bounds, action.orientation)
              let destination = findDestination(targetState, action.destinationId)
              let barrier = switch destination {
              | Some(row) => findAnchor(targetState, row.barrierAnchorId)
              | None => None
              }
              let floor = switch destination {
              | Some(row) => findAnchor(targetState, row.floorAnchorId)
              | None => None
              }
              let support = switch destination {
              | Some(row) => findAnchor(targetState, row.supportAnchorId)
              | None => None
              }
              let opening = switch destination {
              | Some(row) => findOpening(targetState, row.openingId)
              | None => None
              }
              let volume = switch destination {
              | Some(row) => findVolume(targetState, row.volumeId)
              | None => None
              }
              switch (destination, barrier, floor, support, opening, volume) {
              | (None, _, _, _, _, _) =>
                add(
                  "REG_DESTINATION_MISSING",
                  Blocking,
                  scope,
                  target.id ++ "." ++ targetState.id ++ " has no bound destination " ++ action.destinationId,
                  "Select one target-state destination that owns its rim, positioned aperture, and positioned interior.",
                )
              | (Some(_), None, _, _, _, _)
              | (Some(_), _, None, _, _, _)
              | (Some(_), _, _, None, _, _)
              | (Some(_), _, _, _, None, _)
              | (Some(_), _, _, _, _, None) =>
                add(
                  "REG_DESTINATION_COMPONENT_MISSING",
                  Blocking,
                  scope,
                  target.id ++ "." ++ targetState.id ++ "." ++ action.destinationId ++ " has an incomplete bound geometry tuple",
                  "Measure and bind the actual rim, opening, and interior in this exact target state.",
                )
              | (Some(destination), Some(anchor), Some(floor), Some(support), Some(opening), Some(volume)) => {
                  requireEvidence(destination.evidence, scope, target.id ++ ".destination." ++ destination.id)
                  requireEvidence(anchor.evidence, scope, target.id ++ "." ++ destination.barrierAnchorId)
                  requireEvidence(floor.evidence, scope, target.id ++ "." ++ destination.floorAnchorId)
                  requireEvidence(support.evidence, scope, target.id ++ "." ++ destination.supportAnchorId)
                  requireEvidence(opening.evidence, scope, target.id ++ ".opening." ++ opening.id)
                  requireEvidence(volume.evidence, scope, target.id ++ ".volume." ++ volume.id)

                  /* Entry pose is centered on the bound aperture.  The rim is
                     evidence about the same destination, never a convenient
                     low point used to move the aperture. */
                  let entryOffset = {
                    x: opening.center.x -. (subjectBounds.min.x +. subjectBounds.max.x) /. 2.0,
                    y: opening.center.y -. (subjectBounds.min.y +. subjectBounds.max.y) /. 2.0,
                    z: opening.center.z +. action.clearance -. subjectBounds.min.z,
                  }
                  let entrySubjectBounds = translateBounds(subjectBounds, entryOffset)
                  checkActorSubjectCollisions(
                    ~actors,
                    ~subjectBounds=entrySubjectBounds,
                    ~subjectLabel=subject.label,
                  )

                  let (spanU, spanV) = openingSpans(subjectBounds, opening.plane)
                  if spanU +. 2.0 *. action.clearance > opening.spanU || spanV +. 2.0 *. action.clearance > opening.spanV {
                    add(
                      "PHY_OPENING_FIT_FAIL",
                      Blocking,
                      scope,
                      subject.id ++ " oriented envelope spans " ++ f2(spanU) ++ " x " ++ f2(spanV) ++ " in on the " ++ openingPlaneName(opening.plane) ++ " plane, but bound opening " ++ opening.id ++ " is " ++ f2(opening.spanU) ++ " x " ++ f2(opening.spanV) ++ " in before clearance",
                      "Use a measured orientation/state that fits this destination's positioned aperture.",
                    )
                  }

                  /* Straight-down v1 insertion preserves the aperture's x/y
                     center. Re-centering below the rim would be teleporting. */
                  let finalOffset = straightDownFinalOffset(
                    ~entryOffset,
                    ~subjectBounds,
                    ~volumeBounds=volume.bounds,
                    ~clearance=action.clearance,
                  )
                  let finalBounds = translateBounds(subjectBounds, finalOffset)
                  if finalBounds.min.x < volume.bounds.min.x +. action.clearance ||
                    finalBounds.max.x > volume.bounds.max.x -. action.clearance ||
                    finalBounds.min.y < volume.bounds.min.y +. action.clearance ||
                    finalBounds.max.y > volume.bounds.max.y -. action.clearance ||
                    finalBounds.min.z < volume.bounds.min.z +. action.clearance ||
                    finalBounds.max.z > volume.bounds.max.z -. action.clearance {
                    add(
                      "PHY_FINAL_CONTAINMENT_FAIL",
                      Blocking,
                      scope,
                      subject.id ++ " has no clearance-preserving final pose inside bound volume " ++ volume.id,
                      "Use a larger measured destination, smaller explicit object state, or smaller approved clearance.",
                    )
                  }

                  actors->Belt.Array.forEach(((actorEntity, actorState, capability, assignment)) =>
                    switch findGrip(subjectState, assignment.gripId) {
                    | None => add("PHY_GRIP_ASSIGNMENT_FAIL", Blocking, scope, subject.id ++ "." ++ subjectState.id ++ " has no grip " ++ assignment.gripId, "Measure stable grip points for the handled state.")
                    | Some(grip) => {
                        requireEvidence(grip.evidence, scope, subject.id ++ ".grip." ++ grip.id)
                        let orientedGrip = orientPoint(grip.value, action.orientation)
                        let gripX = entryOffset.x +. orientedGrip.x
                        let gripY = entryOffset.y +. orientedGrip.y
                        let required = entryOffset.z +. orientedGrip.z
                        let stance = assignment.stance->Belt.Option.getExn
                        requireEvidence(assignment.stanceEvidence, scope, assignment.entityId ++ ".interaction_stance")
                        let actorBounds = translateBounds(actorState.bounds, stance)
                        if boundsOverlap(actorBounds, targetState.bounds) {
                          add(
                            "PHY_ACTOR_TARGET_COLLISION",
                            Blocking,
                            scope,
                            assignment.entityId ++ " stance places its body envelope inside " ++ target.id ++ "." ++ targetState.id,
                            "Move the actor to a collision-free measured stance or register explicit support geometry; do not solve reach by standing inside the prop.",
                          )
                        }
                        let availableHandHeight = stance.z +. capability.maxHandHeightLoaded
                        if availableHandHeight < required {
                          add(
                            "PHY_VERTICAL_REACH_FAIL",
                            Blocking,
                            scope,
                            assignment.entityId ++ " must hold " ++ subject.id ++ " at " ++ f2(required) ++ " in at the bound aperture, but loaded maximum from this stance is " ++ f2(availableHandHeight) ++ " in (shortfall " ++ f2(required -. availableHandHeight) ++ " in)",
                            "Lower/remove the barrier, add a proven access device, or choose a different destination. Camera framing cannot repair geometry.",
                          )
                        }
                        switch findAnchor(actorState, assignment.shoulderAnchor) {
                        | None => add("PHY_SHOULDER_ANCHOR_MISSING", Blocking, scope, actorEntity.id ++ "." ++ actorState.id ++ " has no shoulder anchor " ++ assignment.shoulderAnchor, "Measure the shoulder anchor used by the reach proof.")
                        | Some(shoulder) => {
                            requireEvidence(shoulder.evidence, scope, actorEntity.id ++ "." ++ actorState.id ++ "." ++ shoulder.id)
                            let shoulderX = stance.x +. shoulder.value.x
                            let shoulderY = stance.y +. shoulder.value.y
                            let shoulderZ = stance.z +. shoulder.value.z
                            let dx = gripX -. shoulderX
                            let dy = gripY -. shoulderY
                            let dz = required -. shoulderZ
                            let distance = Js.Math.sqrt(dx *. dx +. dy *. dy +. dz *. dz)
                            if distance > capability.armReachLoaded {
                              add(
                                "PHY_ARM_REACH_FAIL",
                                Blocking,
                                scope,
                                assignment.entityId ++ " shoulder-to-grip distance at the bound aperture is " ++ f2(distance) ++ " in, but loaded arm reach is " ++ f2(capability.armReachLoaded) ++ " in",
                                "Move the measured stance/support, lower the target, or provide a proven access device; do not move the destination or actor through the set collider.",
                              )
                            }
                          }
                        }
                      }
                    }
                  )
                }
              }
              if !handlingAllowed(subject, subjectState.id, action.method) {
                add(
                  "PHY_HANDLING_METHOD_FAIL",
                  Blocking,
                  scope,
                  subject.id ++ "." ++ subjectState.id ++ " does not allow method " ++ handlingMethodName(action.method) ++ "; registered for this state: " ++ handlingMethodsForState(subject, subjectState.id)->Js.Array2.joinWith(", "),
                  "Use a measured feasible handling method instead of changing ability between shots.",
                )
              }
              switch subject.mass {
              | None => add("PHY_MASS_MISSING", Blocking, scope, subject.id ++ " has no measured mass", "Weigh the prop/proxy or record an author-locked fictional mass.")
              | Some(mass) => {
                  requireEvidence(mass.evidence, scope, subject.id ++ ".massG")
                  let team = actors->Belt.Array.reduce(0.0, (sum, ((_, _, cap, _))) => sum +. cap.maxLiftMassG) *. 0.8
                  if mass.value > team {
                    add("PHY_LIFT_CAPACITY_FAIL", Blocking, scope, subject.id ++ " is " ++ f2(mass.value) ++ " g; team capacity after 0.80 efficiency is " ++ f2(team) ++ " g", "Keep the established drag behavior, lighten the measured prop, or provide a proven machine/route.")
                  }
                }
              }
              let protectedApproach = Belt.Array.some(targetState.affordances, x => x == "protected_approach")
              if targetState.visibilityRisk == VisibilityUnclassified {
                add(
                  "REG_VISIBILITY_RISK_UNCLASSIFIED",
                  Blocking,
                  scope,
                  target.id ++ "." ++ targetState.id ++ " is used as a place_into target but has no explicit visibilityRisk classification",
                  "Classify the target state as none or exposed_to_giants in the physical registry. Omission cannot certify a safe approach.",
                )
              }
              let requiresProtectedApproach = targetState.visibilityRisk != NoVisibilityRisk
              if requiresProtectedApproach {
                if !protectedApproach {
                  add("PHY_PROTECTED_APPROACH_MISSING", Blocking, scope, target.id ++ "." ++ targetState.id ++ " has no protected approach; registered: " ++ Js.Array2.joinWith(targetState.affordances, ", "), "Keep the action behind cover or register a measured access/cover model in a later schema.")
                } else {
                  add(
                    "PHY_PROTECTED_APPROACH_UNMODELED",
                    Blocking,
                    scope,
                    target.id ++ "." ++ targetState.id ++ " carries a protected_approach tag, but schema v1 has no measured route-to-cover relationship that can certify it",
                    "Add structured approach-path and cover-volume geometry in a later schema. A string affordance alone cannot certify concealment.",
                  )
                }
              }
              switch interaction.proof {
              | None => ()
              | Some(proof) =>
                switch (barrier, opening) {
                | (None, _) | (_, None) => add("PRF_INPUT_INCOMPLETE", Blocking, scope, "cannot render the requested proof without the complete bound destination " ++ action.destinationId, "Measure and register the exact destination tuple before requesting a geometry proof.")
                | (Some(anchor), Some(opening)) => {
                    let entryOffset = {
                      x: opening.center.x -. (subjectBounds.min.x +. subjectBounds.max.x) /. 2.0,
                      y: opening.center.y -. (subjectBounds.min.y +. subjectBounds.max.y) /. 2.0,
                      z: opening.center.z +. action.clearance -. subjectBounds.min.z,
                    }
                    let requiredGripHeights = actors->Belt.Array.keepMap(((_, _, _, assignment)) =>
                      switch findGrip(subjectState, assignment.gripId) {
                      | None => None
                      | Some(grip) => {
                          let orientedGrip = orientPoint(grip.value, action.orientation)
                          Some(entryOffset.z +. orientedGrip.z)
                        }
                      }
                    )
                    let maxRequired = requiredGripHeights->Belt.Array.reduce(0.0, (m, x) => x > m ? x : m)
                    let actorRows = actors
                    let sidePath = manifest.output.proofDir ++ "/" ++ proof.sideFile
                    let planPath = manifest.output.proofDir ++ "/" ++ proof.planFile
                    let sideCollision = Belt.Array.some(artifacts, existing => existing.relativePath == sidePath)
                    let planCollision = Belt.Array.some(artifacts, existing => existing.relativePath == planPath)
                    if sideCollision || planCollision {
                      add(
                        "PRF_PATH_COLLISION",
                        Blocking,
                        scope,
                        "proof output path already belongs to another interaction: " ++ (sideCollision ? sidePath : planPath),
                        "Give every proof plane and interaction an explicit unique output filename.",
                      )
                    }
                    /* A proof belongs to the complete diagnostic verdict, not
                       just the interaction-local slice.  Registry invariants
                       are checked before interactions, so a referenced bad
                       grip/anchor must never render a green PASS diagram. */
                    let failed = findings->Belt.Array.some(f => f.severity == Blocking)
                    let svg = renderPlaceIntoProof(
                      ~interaction,
                      ~subject,
                      ~subjectBounds,
                      ~target,
                      ~targetState,
                      ~barrier=anchor,
                      ~actorRows,
                      ~maxRequired,
                      ~placementBottom=opening.center.z +. action.clearance,
                      ~failed,
                    )
                    if !sideCollision {
                      addArtifact(scope, {relativePath: sidePath, body: svg})
                    }
                    let plan = renderPlaceIntoPlan(
                      ~interaction,
                      ~subject,
                      ~target,
                      ~targetState,
                      ~requiresProtectedApproach,
                      ~protectedApproach,
                      ~failed,
                    )
                    if !planCollision {
                      addArtifact(scope, {relativePath: planPath, body: plan})
                    }
                  }
                }
              }
            }
          | _ => ()
          }
        | _ => ()
        }
      }
    | MoveObject(action) => {
        let actors = checkActors(action.actors)
        checkActorPairCollisions(actors)
        switch (resolveEntity(action.subject.entityId, scope), resolveEntity(action.path.entityId, scope)) {
        | (Some(subject), Some(path)) =>
          switch (resolveState(subject, action.subject.stateId, scope), resolveState(path, action.path.stateId, scope)) {
          | (Some(subjectState), Some(pathState)) => {
              requireEvidence(subjectState.evidence, scope, subject.id ++ "." ++ subjectState.id ++ " geometry")
              requireEvidence(pathState.evidence, scope, path.id ++ "." ++ pathState.id ++ " geometry")
              if !Belt.Array.some(subjectState.orientations, allowed => allowed == action.orientation) {
                add(
                  "PHY_ORIENTATION_NOT_ALLOWED",
                  Blocking,
                  scope,
                  subject.id ++ "." ++ subjectState.id ++ " does not allow travel orientation " ++ orientationName(action.orientation),
                  "Register the exact handled orientation; the evaluator never rotates an object merely to find a smaller width.",
                )
              }
              let subjectBounds = orientBounds(subjectState.bounds, action.orientation)
              if subjectBounds.min.z != 0.0 {
                add(
                  "PHY_SUBJECT_SUPPORT_MISMATCH",
                  Blocking,
                  scope,
                  subject.id ++ "." ++ subjectState.id ++ " handled envelope begins at z=" ++ f2(subjectBounds.min.z) ++ " in while schema v1 drag paths use the support plane z=0",
                  "Register a ground-supported drag state with bounds.min.z=0, or model an explicit carrier/support in a later interaction schema.",
                )
              }
              if pathState.bounds.min.z != 0.0 {
                add(
                  "PHY_PATH_SUPPORT_MISMATCH",
                  Blocking,
                  scope,
                  path.id ++ "." ++ pathState.id ++ " clearance envelope begins at z=" ++ f2(pathState.bounds.min.z) ++ " in while schema v1 drag formations are grounded at z=0",
                  "Register the route clearance from its support plane with bounds.min.z=0, or model a ramp/platform explicitly.",
                )
              }
              checkActorSubjectCollisions(~actors, ~subjectBounds, ~subjectLabel=subject.label)
              if !handlingAllowed(subject, subjectState.id, action.method) {
                add("PHY_HANDLING_METHOD_FAIL", Blocking, scope, subject.id ++ "." ++ subjectState.id ++ " does not allow method " ++ handlingMethodName(action.method), "Use a method measured for this exact object state.")
              }
              actors->Belt.Array.forEach(((actorEntity, actorState, capability, assignment)) =>
                switch findGrip(subjectState, assignment.gripId) {
                | None => add("PHY_GRIP_ASSIGNMENT_FAIL", Blocking, scope, subject.id ++ "." ++ subjectState.id ++ " has no grip " ++ assignment.gripId, "Use distinct measured grips on the exact handled state.")
                | Some(grip) => {
                    requireEvidence(grip.evidence, scope, subject.id ++ ".grip." ++ grip.id)
                    let orientedGrip = orientPoint(grip.value, action.orientation)
                    let stance = assignment.stance->Belt.Option.getExn
                    requireEvidence(assignment.stanceEvidence, scope, assignment.entityId ++ ".interaction_stance")
                    let availableHandHeight = stance.z +. capability.maxHandHeightLoaded
                    if orientedGrip.z > availableHandHeight {
                      add(
                        "PHY_VERTICAL_REACH_FAIL",
                        Blocking,
                        scope,
                        assignment.entityId ++ " must hold the moving grip at z=" ++ f2(orientedGrip.z) ++ " in, but its loaded hand maximum is " ++ f2(availableHandHeight) ++ " in",
                        "Register a lower reachable grip/pose; a route wide enough for the prop does not prove the child can hold it.",
                      )
                    }
                    switch findAnchor(actorState, assignment.shoulderAnchor) {
                    | None => add("PHY_SHOULDER_ANCHOR_MISSING", Blocking, scope, actorEntity.id ++ "." ++ actorState.id ++ " has no shoulder anchor " ++ assignment.shoulderAnchor, "Measure the shoulder anchor used by the moving grip proof.")
                    | Some(shoulder) => {
                        requireEvidence(shoulder.evidence, scope, actorEntity.id ++ "." ++ actorState.id ++ "." ++ shoulder.id)
                        /* Move-object stances are expressed in the subject's
                           handled-pose frame, so the moving grip remains the
                           origin-relative reach target throughout the route. */
                        let dx = orientedGrip.x -. (stance.x +. shoulder.value.x)
                        let dy = orientedGrip.y -. (stance.y +. shoulder.value.y)
                        let dz = orientedGrip.z -. (stance.z +. shoulder.value.z)
                        let distance = Js.Math.sqrt(dx *. dx +. dy *. dy +. dz *. dz)
                        if distance > capability.armReachLoaded {
                          add(
                            "PHY_ARM_REACH_FAIL",
                            Blocking,
                            scope,
                            assignment.entityId ++ " shoulder-to-moving-grip distance is " ++ f2(distance) ++ " in, but loaded arm reach is " ++ f2(capability.armReachLoaded) ++ " in",
                            "Register a reachable handled pose and grip; route clearance cannot compensate for an impossible hold.",
                          )
                        }
                      }
                    }
                  }
                }
              )
              switch subject.mass {
              | None => add("PHY_MASS_MISSING", Blocking, scope, subject.id ++ " has no measured mass", "Measure the prop before certifying a carry, lift, or drag.")
              | Some(m) => {
                  requireEvidence(m.evidence, scope, subject.id ++ ".massG")
                  let capacity = actors->Belt.Array.reduce(0.0, (sum, ((_, _, cap, _))) => sum +. cap.maxDragMassG) *. 0.8
                  if m.value > capacity {
                    add("PHY_DRAG_CAPACITY_FAIL", Blocking, scope, subject.id ++ " is " ++ f2(m.value) ++ " g; team capacity is " ++ f2(capacity) ++ " g", "Change the route/method or establish a machine; do not let the prop become lighter between shots.")
                  }
                }
              }
              let subjectW = boundsWidth(subjectBounds)
              let subjectH = boundsHeight(subjectBounds)
              let pathW = boundsWidth(pathState.bounds)
              let pathH = boundsHeight(pathState.bounds)
              if subjectW > pathW {
                add("PHY_PATH_WIDTH_FAIL", Blocking, scope, subject.id ++ " is " ++ f2(subjectW) ++ " in wide in explicit orientation " ++ orientationName(action.orientation) ++ ", but path " ++ path.id ++ " is only " ++ f2(pathW) ++ " in wide", "Measure a flexible turning envelope or widen/change the path; labels like 'soft' do not prove a turn.")
              }
              if subjectH > pathH {
                add("PHY_PATH_HEADROOM_FAIL", Blocking, scope, subject.id ++ " is " ++ f2(subjectH) ++ " in high in state " ++ subjectState.id ++ ", but path " ++ path.id ++ " has only " ++ f2(pathH) ++ " in headroom", "Use a measured handled state and route envelope that clear in all axes.")
              }
              actors->Belt.Array.forEach(((entity, state, _, _)) => {
                let actorW = boundsWidth(state.bounds)
                let actorH = boundsHeight(state.bounds)
                if actorW > pathW {
                  add("PHY_ACTOR_PATH_WIDTH_FAIL", Blocking, scope, entity.id ++ " is " ++ f2(actorW) ++ " in wide in state " ++ state.id ++ ", but the route is " ++ f2(pathW) ++ " in wide", "Register the travel-oriented actor pose or widen/change the route.")
                }
                if actorH > pathH {
                  add("PHY_ACTOR_PATH_HEADROOM_FAIL", Blocking, scope, entity.id ++ " is " ++ f2(actorH) ++ " in high in state " ++ state.id ++ ", but route headroom is " ++ f2(pathH) ++ " in", "Use a measured crawl pose and route height.")
                }
              })
              let formationBounds = actors->Belt.Array.reduce(subjectBounds, (combined, ((_, actorState, _, assignment))) =>
                unionBounds(combined, translateBounds(actorState.bounds, assignment.stance->Belt.Option.getExn))
              )
              let formationW = boundsWidth(formationBounds)
              let formationH = boundsHeight(formationBounds)
              if formationW > pathW {
                add(
                  "PHY_FORMATION_PATH_WIDTH_FAIL",
                  Blocking,
                  scope,
                  "the complete handled formation (object plus translated actors) is " ++ f2(formationW) ++ " in wide, but the route is " ++ f2(pathW) ++ " in wide",
                  "Measure a narrower collision-free team formation or change the route; checking each child separately is insufficient.",
                )
              }
              if formationH > pathH {
                add(
                  "PHY_FORMATION_PATH_HEADROOM_FAIL",
                  Blocking,
                  scope,
                  "the complete handled formation is " ++ f2(formationH) ++ " in high, but route headroom is " ++ f2(pathH) ++ " in",
                  "Use a measured handled formation whose combined envelope clears the route.",
                )
              }
              if Belt.Array.some(pathState.affordances, x => x == "ninety_degree_turn") {
                if !Belt.Array.some(pathState.affordances, x => x == "turn_envelope_measured") {
                  add("PHY_TURN_ENVELOPE_UNPROVEN", Blocking, scope, path.id ++ "." ++ pathState.id ++ " requires a ninety-degree turn but has no swept-envelope record", "Measure the handled object and actor team through the turn; width alone cannot certify a corner.")
                } else {
                  add(
                    "PHY_TURN_ENVELOPE_UNMODELED",
                    Blocking,
                    scope,
                    path.id ++ "." ++ pathState.id ++ " carries a turn_envelope_measured tag, but schema v1 has no structured swept-formation envelope or bound measurement receipt to validate",
                    "Add the sampled/swept actor-plus-object envelope and its evidence in a later schema. A tag cannot certify a corner.",
                  )
                }
              }
              if pathState.visibilityRisk == VisibilityUnclassified {
                add(
                  "REG_VISIBILITY_RISK_UNCLASSIFIED",
                  Blocking,
                  scope,
                  path.id ++ "." ++ pathState.id ++ " is used as a move_object path but has no explicit visibilityRisk classification",
                  "Classify the path state as none or exposed_to_giants in the physical registry. Omission cannot certify a concealed route.",
                )
              }
              if pathState.visibilityRisk != NoVisibilityRisk {
                if !Belt.Array.some(pathState.affordances, x => x == "protected_approach") {
                  add("PHY_PROTECTED_APPROACH_MISSING", Blocking, scope, path.id ++ "." ++ pathState.id ++ " has no protected_approach affordance", "Register a measured access/cover model in a later schema.")
                } else {
                  add(
                    "PHY_PROTECTED_APPROACH_UNMODELED",
                    Blocking,
                    scope,
                    path.id ++ "." ++ pathState.id ++ " carries a protected_approach tag, but schema v1 has no measured route-to-cover relationship that can certify it",
                    "Add structured route and cover-volume geometry. A tag cannot prove that the entire handled formation stays concealed.",
                  )
                }
              }
            }
          | _ => ()
          }
        | _ => ()
        }
      }
    }
  })

  {findings, passed, shotBlocks: blocks, sourceSha256: sourceSha, artifacts}
}

/* ---- proof and report rendering ---------------------------------------- */

and renderPlaceIntoProof = (~interaction, ~subject, ~subjectBounds, ~target, ~targetState, ~barrier, ~actorRows, ~maxRequired, ~placementBottom, ~failed) => {
  let groundY = 510.0
  let displayMaxIn = 12.0
  let scale = 38.0
  let yOf = z => groundY -. z *. scale
  let subjectH = boundsHeight(subjectBounds)
  let actorShapes = actorRows->Belt.Array.mapWithIndex((i, ((entity, state, capability, assignment))) => {
    let h = state.bounds.max.z -. state.bounds.min.z
    let supportZ = (assignment.stance->Belt.Option.getExn).z
    let actorBottomZ = supportZ +. state.bounds.min.z
    let actorTopZ = supportZ +. state.bounds.max.z
    let x = 90.0 +. Belt.Int.toFloat(i) *. 170.0
    let availableZ = supportZ +. capability.maxHandHeightLoaded
    "<rect x='" ++ f2(x) ++ "' y='" ++ f2(yOf(actorTopZ)) ++ "' width='78' height='" ++ f2(h *. scale) ++ "' rx='20' fill='#75a7d8' opacity='0.82'/>" ++
    "<line x1='" ++ f2(x -. 12.0) ++ "' y1='" ++ f2(yOf(availableZ)) ++ "' x2='" ++ f2(x +. 102.0) ++ "' y2='" ++ f2(yOf(availableZ)) ++ "' stroke='#24679e' stroke-width='3' stroke-dasharray='7 5'/>" ++
    "<text x='" ++ f2(x) ++ "' y='540' class='label'>" ++ xmlEscape(entity.label) ++ " z=" ++ f2(actorBottomZ) ++ ".." ++ f2(actorTopZ) ++ " in</text>" ++
    "<text x='" ++ f2(x) ++ "' y='" ++ f2(yOf(availableZ) -. 8.0) ++ "' class='small'>loaded hand max " ++ f2(availableZ) ++ " in; support z=" ++ f2(supportZ) ++ "</text>"
  })->Js.Array2.joinWith("\n")
  let targetVisibleTopZ = min(targetState.bounds.max.z, displayMaxIn)
  let targetVisibleBottomZ = max(targetState.bounds.min.z, -1.5)
  let targetTopY = yOf(targetVisibleTopZ)
  let targetVisibleHeight = targetVisibleTopZ -. targetVisibleBottomZ
  let requiredY = yOf(maxRequired)
  let rimY = yOf(barrier.value.z)
  let subjectX = 535.0
  let subjectY = yOf(placementBottom +. subjectH)
  let status = failed ? "FAIL" : "PASS"
  let statusColor = failed ? "#a61b1b" : "#1f6f43"
  let statusFill = failed ? "#fee8e6" : "#e3f4e9"
  let banner = failed
    ? "BLOCKED: one or more registered interaction checks failed."
    : "CERTIFIED: all registered checks for this interaction passed."
  "<svg xmlns='http://www.w3.org/2000/svg' width='1040' height='600' viewBox='0 0 1040 600'>\n" ++
  "<style>.title{font:700 22px system-ui,sans-serif}.label{font:600 15px system-ui,sans-serif}.small{font:13px system-ui,sans-serif}.status{fill:" ++ statusColor ++ ";font:700 15px system-ui,sans-serif}</style>\n" ++
  "<rect width='1040' height='600' fill='#fbfaf6'/>\n" ++
  "<text x='40' y='38' class='title'>" ++ xmlEscape(interaction.id) ++ " — SIDE ELEVATION — " ++ status ++ "</text>\n" ++
  "<text x='40' y='64' class='small'>Vertical z coordinates are registry-derived and to scale; horizontal spacing and widths are schematic.</text>\n" ++
  "<line x1='40' y1='510' x2='1000' y2='510' stroke='#342f2a' stroke-width='4'/><text x='42' y='495' class='small'>registered support plane z=0</text>\n" ++
  actorShapes ++ "\n" ++
  "<rect x='700' y='" ++ f2(targetTopY) ++ "' width='260' height='" ++ f2(targetVisibleHeight *. scale) ++ "' fill='#8a6042' opacity='0.88'/><path d='M700 " ++ f2(targetTopY +. 12.0) ++ " l18 -12 l18 12 l18 -12 l18 12' fill='none' stroke='#fbfaf6' stroke-width='5'/><text x='716' y='94' class='small'>" ++ xmlEscape(target.label) ++ " registered z=" ++ f2(targetState.bounds.min.z) ++ ".." ++ f2(targetState.bounds.max.z) ++ " in" ++ (targetState.bounds.max.z > displayMaxIn ? " (top clipped)" : "") ++ "</text>\n" ++
  "<line x1='455' y1='" ++ f2(rimY) ++ "' x2='975' y2='" ++ f2(rimY) ++ "' stroke='" ++ statusColor ++ "' stroke-width='4'/><text x='715' y='" ++ f2(rimY -. 10.0) ++ "' class='status'>barrier " ++ xmlEscape(barrier.id) ++ " at " ++ f2(barrier.value.z) ++ " in</text>\n" ++
  "<rect x='" ++ f2(subjectX) ++ "' y='" ++ f2(subjectY) ++ "' width='110' height='" ++ f2(subjectH *. scale) ++ "' rx='18' fill='#d1a759' stroke='#7f5a17' stroke-width='3'/><text x='" ++ f2(subjectX) ++ "' y='" ++ f2(subjectY -. 9.0) ++ "' class='small'>" ++ xmlEscape(subject.label) ++ " required pose</text>\n" ++
  "<line x1='430' y1='" ++ f2(requiredY) ++ "' x2='680' y2='" ++ f2(requiredY) ++ "' stroke='" ++ statusColor ++ "' stroke-width='3' stroke-dasharray='9 5'/><text x='432' y='" ++ f2(requiredY -. 9.0) ++ "' class='status'>required grip " ++ f2(maxRequired) ++ " in</text>\n" ++
  "<rect x='40' y='555' width='960' height='30' rx='6' fill='" ++ statusFill ++ "'/><text x='54' y='576' class='status'>" ++ banner ++ "</text>\n" ++
  "</svg>\n"
}

and renderPlaceIntoPlan = (~interaction, ~subject, ~target, ~targetState, ~requiresProtectedApproach, ~protectedApproach, ~failed) => {
  let widthIn = boundsWidth(targetState.bounds)
  let depthIn = boundsDepth(targetState.bounds)
  let scale = min(520.0 /. widthIn, 300.0 /. depthIn)
  let targetW = widthIn *. scale
  let targetD = depthIn *. scale
  let targetX = 40.0 +. (600.0 -. targetW) /. 2.0
  let targetY = 120.0 +. (340.0 -. targetD) /. 2.0
  let status = failed ? "FAIL" : "PASS"
  let statusColor = failed ? "#a61b1b" : "#1f6f43"
  let statusFill = failed ? "#fee8e6" : "#e3f4e9"
  let accessColor = protectedApproach ? "#1f6f43" : "#a61b1b"
  let requirementText = requiresProtectedApproach ? "required" : "not required"
  let accessText = protectedApproach ? "tag present (noncertifying in v1)" : "tag absent"
  let affordances = targetState.affordances->Js.Array2.joinWith(", ")->xmlEscape
  "<svg xmlns='http://www.w3.org/2000/svg' width='1040' height='650' viewBox='0 0 1040 650'>\n" ++
  "<style>.title{font:700 22px system-ui,sans-serif}.label{font:600 15px system-ui,sans-serif}.small{font:13px system-ui,sans-serif}.status{fill:" ++ statusColor ++ ";font:700 15px system-ui,sans-serif}</style>\n" ++
  "<rect width='1040' height='650' fill='#fbfaf6'/>\n" ++
  "<text x='40' y='38' class='title'>" ++ xmlEscape(interaction.id) ++ " — APPROACH FACTS — " ++ status ++ "</text>\n" ++
  "<text x='40' y='64' class='small'>Only registered target geometry and affordances are drawn. Their evidence may still be noncertifying; no route or cover location is invented.</text>\n" ++
  "<rect x='" ++ f2(targetX) ++ "' y='" ++ f2(targetY) ++ "' width='" ++ f2(targetW) ++ "' height='" ++ f2(targetD) ++ "' fill='#8a6042' opacity='0.88' stroke='#342f2a' stroke-width='3'/>\n" ++
  "<text x='40' y='500' class='label'>" ++ xmlEscape(target.label) ++ " footprint: " ++ f2(widthIn) ++ " x " ++ f2(depthIn) ++ " in</text>\n" ++
  "<text x='40' y='526' class='small'>Handled subject: " ++ xmlEscape(subject.label) ++ "</text>\n" ++
  "<rect x='690' y='120' width='310' height='250' rx='12' fill='#f0eee8' stroke='#b6ada2' stroke-width='2'/>\n" ++
  "<text x='714' y='158' class='label'>Access requirement</text><text x='714' y='188' class='small'>protected approach: " ++ requirementText ++ "</text>\n" ++
  "<text x='714' y='226' class='label' fill='" ++ accessColor ++ "'>protected_approach: " ++ accessText ++ "</text>\n" ++
  "<text x='714' y='266' class='small'>Registered affordances:</text><text x='714' y='292' class='small'>" ++ affordances ++ "</text>\n" ++
  "<text x='714' y='336' class='small'>Route geometry: not depicted</text>\n" ++
  "<rect x='40' y='580' width='960' height='50' rx='6' fill='" ++ statusFill ++ "'/><text x='54' y='604' class='status'>" ++ (failed ? "BLOCKED: one or more interaction checks failed." : "CERTIFIED: all registered checks passed.") ++ "</text><text x='54' y='622' class='small'>This artifact cannot certify an unregistered path by appearance.</text>\n" ++
  "</svg>\n"
}

let reportMarkdown = (
  ~registry: registry,
  ~manifest: manifest,
  ~evaluation: evaluation,
  ~registrySha256: string,
  ~manifestSha256: string,
  ~backlogSha256: string,
) => {
  let blockers = evaluation.findings->Belt.Array.keep(f => f.severity == Blocking)
  let warnings = evaluation.findings->Belt.Array.keep(f => f.severity == Warning)
  let status = Belt.Array.length(blockers) > 0 ? "FAIL — NOT CLEARED FOR SHOOTING" : "PASS"
  let findingRows = evaluation.findings->Belt.Array.map(f =>
    "| `" ++ markdownText(f.code) ++ "` | " ++ (f.severity == Blocking ? "BLOCK" : "WARN") ++ " | " ++ markdownText(f.scope) ++ " | " ++ markdownText(f.detail) ++ " | " ++ markdownText(f.remedy) ++ " |"
  )->Js.Array2.joinWith("\n")
  let proofRows = evaluation.artifacts->Belt.Array.map(a =>
    "- [" ++ markdownText(a.relativePath) ++ "](<" ++ a.relativePath ++ ">)"
  )->Js.Array2.joinWith("\n")
  let highlightCodes = [
    "PHY_BACKLOG_OPEN",
    "COV_SHOT_MISSING",
    "COV_PENDING",
    "DEC_NOT_APPROVED",
    "PHY_PATH_WIDTH_FAIL",
    "PHY_TURN_ENVELOPE_UNPROVEN",
    "PHY_TURN_ENVELOPE_UNMODELED",
    "DEC_REJECTED",
    "PHY_VERTICAL_REACH_FAIL",
    "PHY_ARM_REACH_FAIL",
    "PHY_HANDLING_METHOD_FAIL",
    "PHY_LIFT_CAPACITY_FAIL",
    "PHY_PROTECTED_APPROACH_MISSING",
    "PHY_PROTECTED_APPROACH_UNMODELED",
  ]
  let highlights = evaluation.findings
    ->Belt.Array.keep(f => Belt.Array.some(highlightCodes, code => code == f.code))
    ->Belt.Array.map(f => "- `" ++ markdownText(f.code) ++ "` — " ++ markdownText(f.detail))
    ->Js.Array2.joinWith("\n")
  "# Episode 1 physical preflight\n\n" ++
  "**Status: " ++ status ++ "**\n\n" ++
  "> This report is generated from the machine-readable registry and interaction manifest. A camera angle or a sentence in the screenplay cannot override a failed measurement.\n\n" ++
  "- Registry schema: `" ++ markdownText(registry.schema) ++ "`\n" ++
  "- Manifest profile: `" ++ markdownText(manifest.profile) ++ "`\n" ++
  "- Screenplay SHA-256: `" ++ evaluation.sourceSha256 ++ "`\n" ++
  "- Registry SHA-256: `" ++ registrySha256 ++ "`\n" ++
  "- Manifest SHA-256: `" ++ manifestSha256 ++ "`\n" ++
  "- Physical-backlog SHA-256: `" ++ backlogSha256 ++ "`\n" ++
  "- Parsed shots: " ++ Belt.Int.toString(Belt.Array.length(evaluation.shotBlocks)) ++ "\n" ++
  "- Blocking findings: " ++ Belt.Int.toString(Belt.Array.length(blockers)) ++ "\n" ++
  "- Warnings: " ++ Belt.Int.toString(Belt.Array.length(warnings)) ++ "\n\n" ++
  "## Release-level result\n\n" ++
  (Belt.Array.length(blockers) == 0
    ? "- The hashed screenplay, registry, manifest, and physical backlog passed the release profile.\n"
    : "- No production-cleared screenplay or receipt may be written from this draft.\n" ++
      (Js.String2.length(highlights) == 0 ? "" : highlights ++ "\n")) ++
  "\n## Detailed findings\n\n" ++
  (Belt.Array.length(evaluation.findings) == 0
    ? "No findings.\n"
    : "| Code | Level | Scope | Finding | Required remedy |\n|---|---|---|---|---|\n" ++ findingRows ++ "\n") ++
  "\n## Passed checks\n\n" ++
  (Belt.Array.length(evaluation.passed) == 0 ? "- None.\n" : evaluation.passed->Belt.Array.map(x => "- " ++ markdownText(x))->Js.Array2.joinWith("\n") ++ "\n") ++
  "\n## Generated geometry proofs\n\n" ++
  (Belt.Array.length(evaluation.artifacts) == 0 ? "- None.\n" : proofRows ++ "\n") ++
  "\n## Release rule\n\nThe shooting-script generator must refuse to publish Markdown or HTML while this report contains a blocking finding.\n"
}

let hasBlockers = evaluation => evaluation.findings->Belt.Array.some(f => f.severity == Blocking)
