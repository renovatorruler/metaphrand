module B = Cinema_Backends
module D = Production_Domain

type finding = {code: string, subject: string, message: string}
type acceptance = {
  id: string,
  kind: string,
  requirementKind: D.requirementKind,
  validator: D.validatorKind,
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

@module("node:path") external dirname: string => string = "dirname"
@module("node:path") external resolve2: (string, string) => string = "resolve"
@module("node:path") external isAbsolute: string => bool = "isAbsolute"

let sortedStrings = values => {
  let copy = Js.Array2.copy(values)
  copy->Js.Array2.sortInPlace->ignore
  copy
}

let findTarget = (packet: D.packet, id) => packet.targets->Belt.Array.getBy(target => target.id == id)
let findEntity = (packet: D.packet, id) => packet.entities->Belt.Array.getBy(entity => entity.id == id)
let findAsset = (packet: D.packet, id) => packet.assets->Belt.Array.getBy(asset => asset.id == id)
let findRequirement = (packet: D.packet, id) =>
  packet.requirements->Belt.Array.getBy(requirement => requirement.id == id)

let findState = (packet: D.packet, entityId, stateId) =>
  findEntity(packet, entityId)->Belt.Option.flatMap(entity =>
    entity.states->Belt.Array.getBy(state => state.id == stateId)
  )

let relationName = relation =>
  switch relation {
  | D.Inside => "inside"
  | D.Behind => "behind"
  | D.InFrontOf => "in_front_of"
  | D.LeftOf => "left_of"
  | D.RightOf => "right_of"
  | D.Under => "under"
  | D.Above => "above"
  | D.AdjacentTo => "adjacent_to"
  }

let cameraName = side =>
  switch side {
  | D.CameraLeft => "left"
  | D.CameraRight => "right"
  | D.CameraFront => "front"
  | D.CameraBack => "back"
  | D.CameraInterior => "interior"
  }

let shotName = size =>
  switch size {
  | D.ExtremeWide => "extreme_wide"
  | D.Wide => "wide"
  | D.Full => "full"
  | D.Medium => "medium"
  | D.CloseUp => "close_up"
  | D.ExtremeCloseUp => "extreme_close_up"
  | D.Insert => "insert"
  }

/* The work order keeps the domain variant itself. The copies make array-backed
   payloads independent from the packet parser's mutable JavaScript arrays and
   normalize fields whose order is not semantically meaningful. */
let copyConstraint = kind =>
  switch kind {
  | D.Continuity(spec) => D.Continuity({
      entityId: spec.entityId,
      beforeStateId: spec.beforeStateId,
      afterStateId: spec.afterStateId,
    })
  | D.Presence(spec) => D.Presence({
      entityId: spec.entityId,
      stateId: spec.stateId,
      minimum: spec.minimum,
      maximum: spec.maximum,
    })
  | D.Forbidden(spec) => D.Forbidden({entityId: spec.entityId, stateId: spec.stateId})
  | D.RelativeScale(spec) => D.RelativeScale({
      subjectEntityId: spec.subjectEntityId,
      subjectStateId: spec.subjectStateId,
      referenceEntityId: spec.referenceEntityId,
      referenceStateId: spec.referenceStateId,
      minRatio: spec.minRatio,
      maxRatio: spec.maxRatio,
    })
  | D.Geography(spec) => D.Geography({
      subjectEntityId: spec.subjectEntityId,
      referenceEntityId: spec.referenceEntityId,
      relation: spec.relation,
    })
  | D.CameraSide(spec) => D.CameraSide({
      side: spec.side,
      anchorEntityId: spec.anchorEntityId,
      occluderEntityId: spec.occluderEntityId,
    })
  | D.Framing(spec) => D.Framing({
      shotSize: spec.shotSize,
      requiredEntityIds: spec.requiredEntityIds->sortedStrings,
      fullyVisible: spec.fullyVisible,
    })
  | D.Complexity(spec) => D.Complexity({
      maxPrincipalActions: spec.maxPrincipalActions,
      maxVisibleEntities: spec.maxVisibleEntities,
      maxContinuousSeconds: spec.maxContinuousSeconds,
    })
  | D.References(spec) => D.References({
      assetIds: spec.assetIds->sortedStrings,
      exact: spec.exact,
    })
  }

let kindAndDescription = kind =>
  switch kind {
  | D.Continuity(spec) => (
      "continuity",
      spec.entityId ++ " enters as " ++ spec.beforeStateId ++ " and exits as " ++ spec.afterStateId,
    )
  | D.Presence(spec) => (
      "presence",
      spec.entityId ++
      spec.stateId->Belt.Option.mapWithDefault("", state => " in state " ++ state) ++
      " appears at least " ++ Belt.Int.toString(spec.minimum) ++
      spec.maximum->Belt.Option.mapWithDefault(" times", maximum =>
        " and at most " ++ Belt.Int.toString(maximum) ++ " times"
      ),
    )
  | D.Forbidden(spec) => (
      "forbidden",
      spec.entityId ++
      spec.stateId->Belt.Option.mapWithDefault(" is forbidden", state =>
        " in state " ++ state ++ " is forbidden"
      ),
    )
  | D.RelativeScale(spec) => (
      "relative_scale",
      spec.subjectEntityId ++ "." ++ spec.subjectStateId ++ " height is between " ++
      Js.Float.toString(spec.minRatio) ++ " and " ++ Js.Float.toString(spec.maxRatio) ++
      " times " ++ spec.referenceEntityId ++ "." ++ spec.referenceStateId,
    )
  | D.Geography(spec) => (
      "geography",
      spec.subjectEntityId ++ " is " ++ relationName(spec.relation) ++ " " ++ spec.referenceEntityId,
    )
  | D.CameraSide(spec) => (
      "camera_side",
      "camera is on the " ++ cameraName(spec.side) ++ " side of " ++ spec.anchorEntityId ++
      spec.occluderEntityId->Belt.Option.mapWithDefault("", id => " with " ++ id ++ " as occluder"),
    )
  | D.Framing(spec) => (
      "framing",
      shotName(spec.shotSize) ++ " includes " ++
      spec.requiredEntityIds->sortedStrings->Js.Array2.joinWith(", ") ++
      (spec.fullyVisible ? " fully visible" : " with partial visibility allowed"),
    )
  | D.Complexity(spec) => (
      "complexity",
      "at most " ++ Belt.Int.toString(spec.maxPrincipalActions) ++ " principal actions, " ++
      Belt.Int.toString(spec.maxVisibleEntities) ++ " visible entities, and " ++
      Js.Float.toString(spec.maxContinuousSeconds) ++ " continuous seconds",
    )
  | D.References(spec) => (
      "references",
      (spec.exact ? "exact references: " : "references include: ") ++
      spec.assetIds->sortedStrings->Js.Array2.joinWith(", "),
    )
  }

let add = (findings, code, subject, message) =>
  findings->Js.Array2.push({code, subject, message})->ignore

let requireAuthority = (
  context: D.context,
  decisionIds,
  subjectId,
  authorityHash,
  findings,
) =>
  decisionIds->Belt.Array.forEach(id =>
    if !(context.effectiveDecisionIds->Belt.Array.some(active => active == id)) {
      add(
        findings,
        "DECISION_NOT_EFFECTIVE",
        subjectId,
        "required decision " ++ id ++ " is not currently approved and effective",
      )
    } else if !D.approvalBinds(context, ~decisionId=id, ~subjectId, ~authorityHash) {
      add(
        findings,
        "DECISION_BINDING_MISMATCH",
        subjectId,
        "approved decision " ++ id ++ " does not bind this exact canonical revision",
      )
    }
  )

let requireEntityAuthority = (context: D.context, id, findings) =>
  switch findEntity(context.packet, id) {
  | Some(entity) => requireAuthority(
      context,
      entity.decisionIds,
      "entity:" ++ entity.id,
      entity.authorityHash,
      findings,
    )
  | None => ()
  }

let validateRequirement = (packet: D.packet, requirement: D.requirement, findings) => {
  let requireEntity = id =>
    if findEntity(packet, id) == None {
      add(findings, "ENTITY_UNKNOWN", requirement.id, "unknown entity " ++ id)
    }
  let requireState = (entityId, stateId) => {
    requireEntity(entityId)
    if findState(packet, entityId, stateId) == None {
      add(
        findings,
        "STATE_UNKNOWN",
        requirement.id,
        "unknown state " ++ entityId ++ "." ++ stateId,
      )
    }
  }
  switch requirement.kind {
  | D.Continuity(spec) => {
      requireState(spec.entityId, spec.beforeStateId)
      requireState(spec.entityId, spec.afterStateId)
    }
  | D.Presence(spec) => {
      requireEntity(spec.entityId)
      switch spec.stateId {
      | Some(stateId) => requireState(spec.entityId, stateId)
      | None => ()
      }
    }
  | D.Forbidden(spec) => {
      requireEntity(spec.entityId)
      switch spec.stateId {
      | Some(stateId) => requireState(spec.entityId, stateId)
      | None => ()
      }
    }
  | D.RelativeScale(spec) => {
      requireState(spec.subjectEntityId, spec.subjectStateId)
      requireState(spec.referenceEntityId, spec.referenceStateId)
      switch (
        findState(packet, spec.subjectEntityId, spec.subjectStateId),
        findState(packet, spec.referenceEntityId, spec.referenceStateId),
      ) {
      | (Some(subject), Some(reference)) =>
        switch (subject.dimensions, reference.dimensions) {
        | (Some(subjectDimensions), Some(referenceDimensions)) =>
          if subjectDimensions.unit != referenceDimensions.unit {
            add(
              findings,
              "SCALE_UNIT_MISMATCH",
              requirement.id,
              "relative scale states use different units",
            )
          } else {
            let ratio = subjectDimensions.height /. referenceDimensions.height
            if ratio < spec.minRatio || ratio > spec.maxRatio {
              add(
                findings,
                "SCALE_RANGE_FAIL",
                requirement.id,
                "registered height ratio " ++ Js.Float.toString(ratio) ++
                " is outside the required range",
              )
            }
          }
        | _ =>
          add(
            findings,
            "SCALE_DIMENSIONS_MISSING",
            requirement.id,
            "relative scale requires measured dimensions for both exact states",
          )
        }
      | _ => ()
      }
    }
  | D.Geography(spec) => {
      requireEntity(spec.subjectEntityId)
      requireEntity(spec.referenceEntityId)
    }
  | D.CameraSide(spec) => {
      requireEntity(spec.anchorEntityId)
      switch spec.occluderEntityId {
      | Some(id) => requireEntity(id)
      | None => ()
      }
    }
  | D.Framing(spec) => spec.requiredEntityIds->Belt.Array.forEach(requireEntity)
  | D.Complexity(_) => ()
  | D.References(spec) =>
    spec.assetIds->Belt.Array.forEach(id =>
      if findAsset(packet, id) == None {
        add(findings, "REFERENCE_UNKNOWN", requirement.id, "unknown reference asset " ++ id)
      }
    )
  }
}

let hasCycle = (packet: D.packet, startId) => {
  let rec visit = (id, trail) =>
    if trail->Belt.Array.some(item => item == id) {
      true
    } else {
      switch findTarget(packet, id) {
      | None => false
      | Some(target) =>
        target.dependsOnTargetIds->Belt.Array.some(dependency =>
          visit(dependency, Belt.Array.concat(trail, [id]))
        )
      }
    }
  visit(startId, [])
}

let boolJson = value => Js.Json.boolean(value)
let stringArrayJson = values => Js.Json.array(values->sortedStrings->Belt.Array.map(Js.Json.string))

let optionStringJson = value =>
  switch value {
  | Some(value) => Js.Json.string(value)
  | None => Js.Json.null
  }

let optionIntJson = value =>
  switch value {
  | Some(value) => Js.Json.number(Belt.Int.toFloat(value))
  | None => Js.Json.null
  }

let constraintJson = kind => {
  let row = Js.Dict.empty()
  let specRow = Js.Dict.empty()
  switch kind {
  | D.Continuity(spec) => {
      Js.Dict.set(row, "kind", Js.Json.string("continuity"))
      Js.Dict.set(specRow, "entityId", Js.Json.string(spec.entityId))
      Js.Dict.set(specRow, "beforeStateId", Js.Json.string(spec.beforeStateId))
      Js.Dict.set(specRow, "afterStateId", Js.Json.string(spec.afterStateId))
    }
  | D.Presence(spec) => {
      Js.Dict.set(row, "kind", Js.Json.string("presence"))
      Js.Dict.set(specRow, "entityId", Js.Json.string(spec.entityId))
      Js.Dict.set(specRow, "stateId", optionStringJson(spec.stateId))
      Js.Dict.set(specRow, "minimum", Js.Json.number(Belt.Int.toFloat(spec.minimum)))
      Js.Dict.set(specRow, "maximum", optionIntJson(spec.maximum))
    }
  | D.Forbidden(spec) => {
      Js.Dict.set(row, "kind", Js.Json.string("forbidden"))
      Js.Dict.set(specRow, "entityId", Js.Json.string(spec.entityId))
      Js.Dict.set(specRow, "stateId", optionStringJson(spec.stateId))
    }
  | D.RelativeScale(spec) => {
      Js.Dict.set(row, "kind", Js.Json.string("relative_scale"))
      Js.Dict.set(specRow, "subjectEntityId", Js.Json.string(spec.subjectEntityId))
      Js.Dict.set(specRow, "subjectStateId", Js.Json.string(spec.subjectStateId))
      Js.Dict.set(specRow, "referenceEntityId", Js.Json.string(spec.referenceEntityId))
      Js.Dict.set(specRow, "referenceStateId", Js.Json.string(spec.referenceStateId))
      Js.Dict.set(specRow, "minRatio", Js.Json.number(spec.minRatio))
      Js.Dict.set(specRow, "maxRatio", Js.Json.number(spec.maxRatio))
    }
  | D.Geography(spec) => {
      Js.Dict.set(row, "kind", Js.Json.string("geography"))
      Js.Dict.set(specRow, "subjectEntityId", Js.Json.string(spec.subjectEntityId))
      Js.Dict.set(specRow, "referenceEntityId", Js.Json.string(spec.referenceEntityId))
      Js.Dict.set(specRow, "relation", Js.Json.string(relationName(spec.relation)))
    }
  | D.CameraSide(spec) => {
      Js.Dict.set(row, "kind", Js.Json.string("camera_side"))
      Js.Dict.set(specRow, "side", Js.Json.string(cameraName(spec.side)))
      Js.Dict.set(specRow, "anchorEntityId", Js.Json.string(spec.anchorEntityId))
      Js.Dict.set(specRow, "occluderEntityId", optionStringJson(spec.occluderEntityId))
    }
  | D.Framing(spec) => {
      Js.Dict.set(row, "kind", Js.Json.string("framing"))
      Js.Dict.set(specRow, "shotSize", Js.Json.string(shotName(spec.shotSize)))
      Js.Dict.set(specRow, "requiredEntityIds", stringArrayJson(spec.requiredEntityIds))
      Js.Dict.set(specRow, "fullyVisible", boolJson(spec.fullyVisible))
    }
  | D.Complexity(spec) => {
      Js.Dict.set(row, "kind", Js.Json.string("complexity"))
      Js.Dict.set(
        specRow,
        "maxPrincipalActions",
        Js.Json.number(Belt.Int.toFloat(spec.maxPrincipalActions)),
      )
      Js.Dict.set(
        specRow,
        "maxVisibleEntities",
        Js.Json.number(Belt.Int.toFloat(spec.maxVisibleEntities)),
      )
      Js.Dict.set(specRow, "maxContinuousSeconds", Js.Json.number(spec.maxContinuousSeconds))
    }
  | D.References(spec) => {
      Js.Dict.set(row, "kind", Js.Json.string("references"))
      Js.Dict.set(specRow, "assetIds", stringArrayJson(spec.assetIds))
      Js.Dict.set(specRow, "exact", boolJson(spec.exact))
    }
  }
  Js.Dict.set(row, "spec", Js.Json.object_(specRow))
  Js.Json.object_(row)
}

let acceptanceJson = (item: acceptance) => {
  let row = Js.Dict.empty()
  Js.Dict.set(row, "id", Js.Json.string(item.id))
  Js.Dict.set(row, "kind", Js.Json.string(item.kind))
  Js.Dict.set(row, "constraint", constraintJson(item.requirementKind))
  Js.Dict.set(row, "validator", Js.Json.string(D.validatorKindName(item.validator)))
  Js.Dict.set(row, "description", Js.Json.string(item.description))
  Js.Dict.set(row, "decisionIds", stringArrayJson(item.decisionIds))
  Js.Json.object_(row)
}

let referenceJson = (item: reference) => {
  let row = Js.Dict.empty()
  Js.Dict.set(row, "assetId", Js.Json.string(item.assetId))
  Js.Dict.set(row, "path", Js.Json.string(item.path))
  Js.Dict.set(row, "sha256", Js.Json.string(item.sha256))
  Js.Json.object_(row)
}

let canonicalBody = (
  ~packetId,
  ~packetRevision,
  ~packetHash,
  ~targetId,
  ~purpose,
  ~principalAction,
  ~operation,
  ~declaredActionCount,
  ~declaredContinuousSeconds,
  ~dependencyTargetIds,
  ~references,
  ~acceptance,
  ~maxAttempts,
  ~reviewBatchSize,
  ~requiresHumanApproval,
  ~requiresExplicitAuthorization,
) => {
  let root = Js.Dict.empty()
  Js.Dict.set(root, "schema", Js.Json.string("production.work-order/v2"))
  Js.Dict.set(root, "packetId", Js.Json.string(packetId))
  Js.Dict.set(root, "packetRevision", Js.Json.number(Belt.Int.toFloat(packetRevision)))
  Js.Dict.set(root, "packetHash", Js.Json.string(packetHash))
  Js.Dict.set(root, "targetId", Js.Json.string(targetId))
  Js.Dict.set(root, "purpose", Js.Json.string(purpose))
  Js.Dict.set(root, "principalAction", Js.Json.string(principalAction))
  Js.Dict.set(root, "operation", Js.Json.string(operation))
  Js.Dict.set(root, "declaredActionCount", Js.Json.number(Belt.Int.toFloat(declaredActionCount)))
  Js.Dict.set(root, "declaredContinuousSeconds", Js.Json.number(declaredContinuousSeconds))
  Js.Dict.set(root, "dependencyTargetIds", stringArrayJson(dependencyTargetIds))
  let sortedReferences = Js.Array2.copy(references)
  sortedReferences->Js.Array2.sortInPlaceWith((left, right) => compare(left.assetId, right.assetId))->ignore
  Js.Dict.set(root, "references", Js.Json.array(sortedReferences->Belt.Array.map(referenceJson)))
  let sortedAcceptance = Js.Array2.copy(acceptance)
  sortedAcceptance->Js.Array2.sortInPlaceWith((left, right) => compare(left.id, right.id))->ignore
  Js.Dict.set(root, "acceptance", Js.Json.array(sortedAcceptance->Belt.Array.map(acceptanceJson)))
  Js.Dict.set(root, "maxAttempts", Js.Json.number(Belt.Int.toFloat(maxAttempts)))
  Js.Dict.set(root, "reviewBatchSize", Js.Json.number(Belt.Int.toFloat(reviewBatchSize)))
  Js.Dict.set(root, "requiresHumanApproval", boolJson(requiresHumanApproval))
  Js.Dict.set(root, "requiresExplicitAuthorization", boolJson(requiresExplicitAuthorization))
  D.canonicalJson(Js.Json.object_(root))
}

let encode = (order: workOrder) => order.canonical ++ "\n"

let compile = (~packetPath, ~targetId) => {
  let findings: array<finding> = []
  if !B.exists(B.Path(packetPath)) {
    add(findings, "PACKET_MISSING", packetPath, "production packet does not exist")
    {workOrder: None, findings}
  } else {
    let raw = B.readText(B.Path(packetPath))
    let context = try {
      Some(D.reconstruct(raw))
    } catch {
    | D.DomainError(message) => {
        add(findings, "PACKET_INVALID", packetPath, message)
        None
      }
    }
    switch context {
    | None => {workOrder: None, findings}
    | Some(context) => {
        context.blockers->Belt.Array.forEach(message =>
          add(findings, "AUTHORITY_BLOCKED", context.packet.packetId, message)
        )
        context.conflicts->Belt.Array.forEach(conflict =>
          add(
            findings,
            "DECISION_CONFLICT",
            conflict.scope,
            "multiple effective decisions: " ++ conflict.decisionIds->Js.Array2.joinWith(", "),
          )
        )
        let built = switch findTarget(context.packet, targetId) {
        | None => {
            add(findings, "TARGET_UNKNOWN", targetId, "target is not declared in the packet")
            None
          }
        | Some(target) => {
            requireAuthority(
              context,
              target.decisionIds,
              "target:" ++ target.id,
              target.authorityHash,
              findings,
            )
            target.entityIds->Belt.Array.forEach(id =>
              if findEntity(context.packet, id) == None {
                add(findings, "ENTITY_UNKNOWN", target.id, "target references unknown entity " ++ id)
              } else {
                requireEntityAuthority(context, id, findings)
              }
            )
            target.dependsOnTargetIds->Belt.Array.forEach(id =>
              if findTarget(context.packet, id) == None {
                add(findings, "DEPENDENCY_UNKNOWN", target.id, "unknown target dependency " ++ id)
              }
            )
            if hasCycle(context.packet, target.id) {
              add(findings, "DEPENDENCY_CYCLE", target.id, "target dependency graph contains a cycle")
            }

            let targetRequirements: array<D.requirement> = []
            let seenRequirements = Js.Dict.empty()
            target.requirementIds->Belt.Array.forEach(id => {
              if Js.Dict.get(seenRequirements, id) != None {
                add(findings, "REQUIREMENT_DUPLICATE", target.id, "duplicate requirement " ++ id)
              }
              Js.Dict.set(seenRequirements, id, true)
              switch findRequirement(context.packet, id) {
              | None => add(findings, "REQUIREMENT_UNKNOWN", target.id, "unknown requirement " ++ id)
              | Some(requirement) => {
                  if requirement.targetId != target.id {
                    add(
                      findings,
                      "REQUIREMENT_TARGET_MISMATCH",
                      id,
                      "requirement belongs to " ++ requirement.targetId,
                    )
                  }
                  requireAuthority(
                    context,
                    requirement.decisionIds,
                    "requirement:" ++ requirement.id,
                    requirement.authorityHash,
                    findings,
                  )
                  validateRequirement(context.packet, requirement, findings)
                  switch requirement.kind {
                  | D.Continuity(spec) => requireEntityAuthority(context, spec.entityId, findings)
                  | D.Presence(spec) => requireEntityAuthority(context, spec.entityId, findings)
                  | D.Forbidden(spec) => requireEntityAuthority(context, spec.entityId, findings)
                  | D.RelativeScale(spec) => {
                      requireEntityAuthority(context, spec.subjectEntityId, findings)
                      requireEntityAuthority(context, spec.referenceEntityId, findings)
                    }
                  | D.Geography(spec) => {
                      requireEntityAuthority(context, spec.subjectEntityId, findings)
                      requireEntityAuthority(context, spec.referenceEntityId, findings)
                    }
                  | D.CameraSide(spec) => {
                      requireEntityAuthority(context, spec.anchorEntityId, findings)
                      switch spec.occluderEntityId {
                      | Some(id) => requireEntityAuthority(context, id, findings)
                      | None => ()
                      }
                    }
                  | D.Framing(spec) => spec.requiredEntityIds->Belt.Array.forEach(id =>
                      requireEntityAuthority(context, id, findings)
                    )
                  | D.Complexity(_) | D.References(_) => ()
                  }
                  targetRequirements->Js.Array2.push(requirement)->ignore
                }
              }
            })
            context.packet.requirements->Belt.Array.forEach(requirement =>
              if requirement.targetId == target.id &&
                !(target.requirementIds->Belt.Array.some(id => id == requirement.id)) {
                add(
                  findings,
                  "REQUIREMENT_OMITTED",
                  target.id,
                  "target omits declared requirement " ++ requirement.id,
                )
              }
            )
            if !(targetRequirements->Belt.Array.some(req => req.validator == D.SemanticInspector)) {
              add(
                findings,
                "SEMANTIC_CONTRACT_MISSING",
                target.id,
                "every generated candidate requires at least one independent semantic check",
              )
            }

            let references: array<reference> = []
            let packetDir = dirname(resolve2(".", packetPath))
            target.assetIds->Belt.Array.forEach(id =>
              switch findAsset(context.packet, id) {
              | None => add(findings, "ASSET_UNKNOWN", target.id, "unknown asset " ++ id)
              | Some(asset) => {
                  requireAuthority(
                    context,
                    asset.decisionIds,
                    "asset:" ++ asset.id,
                    asset.authorityHash,
                    findings,
                  )
                  if asset.status != D.AssetApproved {
                    add(findings, "ASSET_NOT_APPROVED", id, "reference asset is not approved")
                  }
                  switch (asset.path, asset.contentSha256) {
                  | (Some(relative), Some(declaredHash)) => {
                      if isAbsolute(relative) {
                        add(findings, "ASSET_PATH_UNSAFE", id, "reference paths must be relative")
                      } else {
                        let resolved = try {
                          Some(
                            Production_OutputSafety.manifestOutputPath(
                              ~baseDir=packetDir,
                              ~relativePath=relative,
                              ~label="reference asset " ++ id,
                            ),
                          )
                        } catch {
                        | Production_OutputSafety.OutputSafetyError(message) => {
                            add(findings, "ASSET_PATH_UNSAFE", id, message)
                            None
                          }
                        }
                        switch resolved {
                        | Some(path) if !B.exists(B.Path(path)) =>
                          add(findings, "ASSET_FILE_MISSING", id, "reference file is missing")
                        | Some(path) if B.sha256File(B.Path(path)) != declaredHash =>
                          add(findings, "ASSET_HASH_MISMATCH", id, "reference bytes changed")
                        | Some(_) =>
                          references->Js.Array2.push({assetId: id, path: relative, sha256: declaredHash})->ignore
                        | None => ()
                        }
                      }
                    }
                  | _ =>
                    add(
                      findings,
                      "ASSET_BINDING_MISSING",
                      id,
                      "approved reference requires path and SHA-256",
                    )
                  }
                }
              }
            )

            let maxAttempts = ref(0)
            let attemptsPolicyCount = ref(0)
            let reviewBatchSize = ref(0)
            let reviewPolicyCount = ref(0)
            let requiresHumanApproval = ref(false)
            let requiresExplicitAuthorization = ref(false)
            let executionPolicyCount = ref(0)
            let globalComplexity: array<D.complexityPolicy> = []
            context.packet.policies->Belt.Array.forEach(policy => {
              requireAuthority(
                context,
                policy.decisionIds,
                "policy:" ++ policy.id,
                policy.authorityHash,
                findings,
              )
              switch policy.kind {
              | D.AttemptsPolicy(value) => {
                  attemptsPolicyCount := attemptsPolicyCount.contents + 1
                  maxAttempts := value.maxPerTarget
                }
              | D.ReviewPolicy(value) => {
                  reviewPolicyCount := reviewPolicyCount.contents + 1
                  reviewBatchSize := value.batchSize
                  requiresHumanApproval := value.requireHumanApproval
                }
              | D.ComplexityPolicy(value) => globalComplexity->Js.Array2.push(value)->ignore
              | D.ExecutionPolicy(value) => {
                  executionPolicyCount := executionPolicyCount.contents + 1
                  requiresExplicitAuthorization := value.requiresExplicitAuthorization
                }
              }
            })
            if attemptsPolicyCount.contents != 1 || maxAttempts.contents <= 0 {
              add(findings, "ATTEMPTS_POLICY_INVALID", target.id, "exactly one attempts policy is required")
            }
            if reviewPolicyCount.contents != 1 || reviewBatchSize.contents <= 0 ||
              !requiresHumanApproval.contents {
              add(
                findings,
                "REVIEW_POLICY_UNSAFE",
                target.id,
                "review policy must require human approval and a positive batch size",
              )
            }
            if executionPolicyCount.contents != 1 || !requiresExplicitAuthorization.contents {
              add(
                findings,
                "EXECUTION_POLICY_UNSAFE",
                target.id,
                "execution policy must require explicit authorization",
              )
            }
            if Belt.Array.length(globalComplexity) != 1 {
              add(
                findings,
                "COMPLEXITY_POLICY_INVALID",
                target.id,
                "exactly one global complexity policy is required",
              )
            }
            globalComplexity->Belt.Array.forEach(policy => {
              if target.declaredActionCount > policy.maxPrincipalActions {
                add(
                  findings,
                  "COMPLEXITY_ACTION_BUDGET",
                  target.id,
                  "declared action count exceeds the packet policy",
                )
              }
              if Belt.Array.length(target.entityIds) > policy.maxVisibleEntities {
                add(
                  findings,
                  "COMPLEXITY_ENTITY_BUDGET",
                  target.id,
                  "declared visible entities exceed the packet policy",
                )
              }
              if target.declaredContinuousSeconds > policy.maxContinuousSeconds {
                add(
                  findings,
                  "COMPLEXITY_DURATION_BUDGET",
                  target.id,
                  "declared continuous duration exceeds the packet policy",
                )
              }
            })
            targetRequirements->Belt.Array.forEach(requirement =>
              switch requirement.kind {
              | D.References(spec) if spec.exact => {
                  let declared = spec.assetIds->sortedStrings->Js.Array2.joinWith("\u{1f}")
                  let targetAssets = target.assetIds->sortedStrings->Js.Array2.joinWith("\u{1f}")
                  if declared != targetAssets {
                    add(
                      findings,
                      "REFERENCE_SET_MISMATCH",
                      requirement.id,
                      "exact reference requirement does not equal the target asset set",
                    )
                  }
                }
              | D.Complexity(spec) => {
                  if target.declaredActionCount > spec.maxPrincipalActions {
                    add(
                      findings,
                      "COMPLEXITY_REQUIREMENT_FAIL",
                      requirement.id,
                      "declared action count exceeds its target requirement",
                    )
                  }
                  if Belt.Array.length(target.entityIds) > spec.maxVisibleEntities {
                    add(
                      findings,
                      "COMPLEXITY_REQUIREMENT_FAIL",
                      requirement.id,
                      "declared visible entity count exceeds its target requirement",
                    )
                  }
                  if target.declaredContinuousSeconds > spec.maxContinuousSeconds {
                    add(
                      findings,
                      "COMPLEXITY_REQUIREMENT_FAIL",
                      requirement.id,
                      "declared continuous duration exceeds its target requirement",
                    )
                  }
                }
              | _ => ()
              }
            )

            if Belt.Array.length(findings) == 0 {
              let acceptance = targetRequirements->Belt.Array.map(requirement => {
                let (kind, description) = kindAndDescription(requirement.kind)
                {
                  id: requirement.id,
                  kind,
                  requirementKind: copyConstraint(requirement.kind),
                  validator: requirement.validator,
                  description,
                  decisionIds: requirement.decisionIds->sortedStrings,
                }
              })
              acceptance->Js.Array2.sortInPlaceWith((left, right) => compare(left.id, right.id))->ignore
              references->Js.Array2.sortInPlaceWith((left, right) => compare(left.assetId, right.assetId))->ignore
              let canonical = canonicalBody(
                ~packetId=context.packet.packetId,
                ~packetRevision=context.packet.revision,
                ~packetHash=context.canonicalHash,
                ~targetId=target.id,
                ~purpose=target.purpose,
                ~principalAction=target.principalAction,
                ~operation=target.operation,
                ~declaredActionCount=target.declaredActionCount,
                ~declaredContinuousSeconds=target.declaredContinuousSeconds,
                ~dependencyTargetIds=target.dependsOnTargetIds,
                ~references,
                ~acceptance,
                ~maxAttempts=maxAttempts.contents,
                ~reviewBatchSize=reviewBatchSize.contents,
                ~requiresHumanApproval=requiresHumanApproval.contents,
                ~requiresExplicitAuthorization=requiresExplicitAuthorization.contents,
              )
              let order = {
                schema: "production.work-order/v2",
                packetId: context.packet.packetId,
                packetRevision: context.packet.revision,
                packetHash: context.canonicalHash,
                packetPath: resolve2(".", packetPath),
                targetId: target.id,
                purpose: target.purpose,
                principalAction: target.principalAction,
                operation: target.operation,
                declaredActionCount: target.declaredActionCount,
                declaredContinuousSeconds: target.declaredContinuousSeconds,
                dependencyTargetIds: target.dependsOnTargetIds->sortedStrings,
                references,
                acceptance,
                maxAttempts: maxAttempts.contents,
                reviewBatchSize: reviewBatchSize.contents,
                requiresHumanApproval: requiresHumanApproval.contents,
                requiresExplicitAuthorization: requiresExplicitAuthorization.contents,
                canonical,
                hash: B.sha256Text(canonical),
              }
              Some(order)
            } else {
              None
            }
          }
        }
        if Belt.Array.length(findings) > 0 {
          findings->Js.Array2.sortInPlaceWith((left, right) =>
            compare(left.code ++ left.subject ++ left.message, right.code ++ right.subject ++ right.message)
          )->ignore
          {workOrder: None, findings}
        } else {
          {workOrder: built, findings}
        }
      }
    }
  }
}

let semanticChecks = (order: workOrder) =>
  order.acceptance
  ->Belt.Array.keep(item => item.validator == D.SemanticInspector)
  ->Belt.Array.map(item => ({id: item.id, description: item.description}: Production_Inspection.check))

let humanQuestions = (order: workOrder) =>
  order.acceptance->Belt.Array.keep(item => item.validator == D.HumanOnly)

let explain = evaluation => {
  switch evaluation.workOrder {
  | Some(order) =>
    "READY " ++ order.targetId ++ "\n" ++
    "Work order: " ++ order.hash ++ "\n" ++
    "Purpose: " ++ order.purpose ++ "\n" ++
    "Principal action: " ++ order.principalAction ++ "\n"
  | None =>
    "BLOCKED\n" ++
    evaluation.findings
    ->Belt.Array.map(finding => "- [" ++ finding.code ++ "] " ++ finding.subject ++ ": " ++ finding.message)
    ->Js.Array2.joinWith("\n") ++
    "\n"
  }
}
