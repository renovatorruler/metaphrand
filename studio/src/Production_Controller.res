module B = Cinema_Backends
module W = Production_WorkOrder
module S = Production_State
module P = Production_Preflight
module G = Production_Gateway
module I = Production_Inspection
module A = Production_ArtifactStore
module D = Production_Domain
module Credentials = Production_Credentials
module Safety = Production_OutputSafety

exception ControllerError(string)

type blocker = {id: string, code: string, subject: string, message: string}
type reconcileStatus =
  | ReadyForExecution
  | ReconciliationBlocked
  | LifecycleCurrent(S.lifecycle)
type reconciliation = {
  targetId: string,
  status: reconcileStatus,
  workOrder: option<W.workOrder>,
  blockers: array<blocker>,
  eventIds: array<string>,
}

type inspectionRequest = {job: I.job, candidate: A.candidate}
type inspectorData = {
  id: string,
  principalId: string,
  inspect: inspectionRequest => result<string, string>,
}
type inspector = Inspector(inspectorData)
type inspectionResult = {
  candidate: A.candidate,
  report: I.report,
  adjudication: I.adjudication,
  record: A.inspection,
  lifecycleEvent: option<S.event>,
}

type humanVerdict = HumanPass | HumanFail | HumanUnknown
type humanAnswer = {requirementId: string, verdict: humanVerdict, evidence: string}
type reviewResult = {record: A.reviewRecord, lifecycleEvent: S.event}

@module("node:path") external resolvePath: string => string = "resolve"

let die = message => raise(ControllerError(message))

let stableAdapterId = (id, label) => {
  if !Js.Re.test_(%re("/^[A-Za-z0-9][A-Za-z0-9._:-]*$/"), id) {
    die(label ++ " must be a stable identifier")
  }
  id
}

let registerInspector = (~packetPath, ~adapterId, ~credentialText, ~inspect) => {
  stableAdapterId(adapterId, "inspector adapter id")->ignore
  let credential = try {
    Credentials.verifyPrincipal(
      ~packetPath,
      ~raw=credentialText,
      ~role=D.Inspector,
      ~action="register_inspector_adapter",
      ~bindingHash=Credentials.bindingHash(["inspector_adapter", adapterId]),
    )
  } catch {
  | Credentials.CredentialError(message) => die("inspector adapter credential refused: " ++ message)
  }
  Inspector({id: adapterId, principalId: Credentials.principalId(credential), inspect})
}

let inspectorId = (Inspector(inspector)) => inspector.id
let inspectorPrincipalId = (Inspector(inspector)) => inspector.principalId

let currentFor = (snapshot: S.snapshot, targetId: string): option<S.targetState> =>
  snapshot.targets->Belt.Array.getBy(row => row.targetId == targetId)

let blockerId = (code, subject, message) =>
  "BLK-" ++ B.sha256Text(code ++ "\n" ++ subject ++ "\n" ++ message)

let makeBlocker = (~code, ~subject, ~message): blocker =>
  {id: blockerId(code, subject, message), code, subject, message}

let blockersFromFindings = (findings: array<W.finding>): array<blocker> =>
  findings->Belt.Array.map(finding =>
    makeBlocker(~code=finding.code, ~subject=finding.subject, ~message=finding.message)
  )

let sortBlockers = (blockers: array<blocker>): array<blocker> => {
  let copy = Js.Array2.copy(blockers)
  copy->Js.Array2.sortInPlaceWith((left, right) => compare(left.id, right.id))->ignore
  copy
}

let blockerReason = (blockers: array<blocker>) =>
  "blocked by " ++ blockers->Belt.Array.map(row => row.id)->Js.Array2.joinWith(",")

let loadState = stateDir =>
  try S.load(~stateDir=resolvePath(stateDir)) catch {
  | S.StateError(message) => die("state ledger is invalid: " ++ message)
  }

let appendEvent = (
  ~stateDir,
  ~targetId,
  ~state,
  ~actor,
  ~packetHash=?,
  ~workOrderHash=?,
  ~artifactHash=?,
  ~reportHash=?,
  ~reason,
) =>
  try {
    S.append(
      ~stateDir,
      ~targetId,
      ~state,
      ~actor,
      ~packetHash?,
      ~workOrderHash?,
      ~artifactHash?,
      ~reportHash?,
      ~reason,
    )
  } catch {
  | S.StateError(message) => die("could not reconcile lifecycle: " ++ message)
  }

let pushEvent = (events: array<string>, event: S.event) =>
  events->Js.Array2.push(event.id)->ignore

let exactBindings = (row: S.targetState, order: W.workOrder) =>
  row.lastEvent.packetHash == Some(order.packetHash) &&
  row.lastEvent.workOrderHash == Some(order.hash)

let dependencyBlockers = (
  ~order: W.workOrder,
  ~snapshot: S.snapshot,
): array<blocker> => {
  let blockers: array<blocker> = []
  order.dependencyTargetIds->Belt.Array.forEach(dependencyId =>
    switch currentFor(snapshot, dependencyId) {
    | None =>
      blockers->Js.Array2.push(
        makeBlocker(
          ~code="DEPENDENCY_NOT_RECONCILED",
          ~subject=dependencyId,
          ~message="dependency has no lifecycle state",
        ),
      )->ignore
    | Some(dependency) if dependency.state != S.Approved && dependency.state != S.Released =>
      blockers->Js.Array2.push(
        makeBlocker(
          ~code="DEPENDENCY_NOT_APPROVED",
          ~subject=dependencyId,
          ~message="dependency state is " ++ S.lifecycleName(dependency.state),
        ),
      )->ignore
    | Some(dependency) if dependency.lastEvent.packetHash != Some(order.packetHash) =>
      blockers->Js.Array2.push(
        makeBlocker(
          ~code="DEPENDENCY_PACKET_DRIFT",
          ~subject=dependencyId,
          ~message="dependency approval does not bind the current packet hash",
        ),
      )->ignore
    | Some(dependency) => {
        let compiled = W.compile(~packetPath=order.packetPath, ~targetId=dependencyId)
        switch compiled.workOrder {
        | Some(dependencyOrder)
          if dependency.lastEvent.workOrderHash == Some(dependencyOrder.hash) => ()
        | Some(_) =>
          blockers->Js.Array2.push(
            makeBlocker(
              ~code="DEPENDENCY_WORK_ORDER_DRIFT",
              ~subject=dependencyId,
              ~message="dependency approval does not bind its current work order",
            ),
          )->ignore
        | None =>
          blockers->Js.Array2.push(
            makeBlocker(
              ~code="DEPENDENCY_INVALID",
              ~subject=dependencyId,
              ~message="dependency no longer compiles under current authority",
            ),
          )->ignore
        }
      }
    }
  )
  blockers->sortBlockers
}

let supersede = (~stateDir, ~targetId, ~events, ~reason) => {
  let prior = loadState(stateDir)->currentFor(targetId)
  let event = appendEvent(
    ~stateDir,
    ~targetId,
    ~state=S.Superseded,
    ~actor=S.System,
    ~packetHash=?prior->Belt.Option.flatMap(row => row.lastEvent.packetHash),
    ~workOrderHash=?prior->Belt.Option.flatMap(row => row.lastEvent.workOrderHash),
    ~artifactHash=?prior->Belt.Option.flatMap(row => row.lastEvent.artifactHash),
    ~reportHash=?prior->Belt.Option.flatMap(row => row.lastEvent.reportHash),
    ~reason,
  )
  pushEvent(events, event)
}

let appendCompiled = (~stateDir, ~order: W.workOrder, ~events, ~reason) => {
  let event = appendEvent(
    ~stateDir,
    ~targetId=order.targetId,
    ~state=S.Compiled,
    ~actor=S.System,
    ~packetHash=order.packetHash,
    ~workOrderHash=order.hash,
    ~reason,
  )
  pushEvent(events, event)
}

let appendBlocked = (~stateDir, ~targetId, ~events, ~blockers) => {
  let event = appendEvent(
    ~stateDir,
    ~targetId,
    ~state=S.Blocked,
    ~actor=S.System,
    ~reason=blockerReason(blockers),
  )
  pushEvent(events, event)
}

let reconcileBlocked = (
  ~stateDir,
  ~targetId,
  ~order: option<W.workOrder>,
  ~current: option<S.targetState>,
  ~blockers,
  ~events,
) => {
  let reason = blockerReason(blockers)
  switch (order, current) {
  | (_, Some(row)) if row.state == S.Blocked => ()
  | (_, None) => appendBlocked(~stateDir, ~targetId, ~events, ~blockers)
  | (_, Some(row)) if row.state == S.Locked || row.state == S.Compiled ||
      row.state == S.Ready || row.state == S.Authorized =>
    appendBlocked(~stateDir, ~targetId, ~events, ~blockers)
  | (Some(order), Some(row))
    if (row.state == S.Rejected || row.state == S.Superseded) && exactBindings(row, order) => ()
  | (Some(order), Some(row)) if row.state == S.Rejected || row.state == S.Superseded => {
      appendCompiled(
        ~stateDir,
        ~order,
        ~events,
        ~reason="compiled current authority before dependency block",
      )
      appendBlocked(~stateDir, ~targetId, ~events, ~blockers)
    }
  | (Some(order), Some(_)) => {
      supersede(
        ~stateDir,
        ~targetId,
        ~events,
        ~reason="invalidated advanced lifecycle: " ++ reason,
      )
      appendCompiled(
        ~stateDir,
        ~order,
        ~events,
        ~reason="compiled current authority before dependency block",
      )
      appendBlocked(~stateDir, ~targetId, ~events, ~blockers)
    }
  | (None, Some(row)) if row.state == S.Superseded => ()
  | (None, Some(_)) =>
    supersede(
      ~stateDir,
      ~targetId,
      ~events,
      ~reason="current lifecycle invalidated: " ++ reason,
    )
  }
}

let reconcileReady = (
  ~stateDir,
  ~order: W.workOrder,
  ~current: option<S.targetState>,
  ~events,
) => {
  let targetId = order.targetId
  switch current {
  | Some(row) if row.state == S.Ready && exactBindings(row, order) => ()
  | Some(row)
    if exactBindings(row, order) &&
      (row.state == S.Authorized || row.state == S.CandidateQuarantine ||
      row.state == S.Unknown || row.state == S.ReviewReady || row.state == S.Approved ||
      row.state == S.Rejected || row.state == S.Superseded || row.state == S.Released) => ()
  | Some(row) if row.state == S.Locked => {
      appendCompiled(~stateDir, ~order, ~events, ~reason="compiled reconciled authority")
      let event = appendEvent(
        ~stateDir,
        ~targetId,
        ~state=S.Ready,
        ~actor=S.System,
        ~packetHash=order.packetHash,
        ~workOrderHash=order.hash,
        ~reason="all deterministic blockers cleared",
      )
      pushEvent(events, event)
    }
  | Some(row) if row.state == S.Compiled && exactBindings(row, order) => {
      let event = appendEvent(
        ~stateDir,
        ~targetId,
        ~state=S.Ready,
        ~actor=S.System,
        ~packetHash=order.packetHash,
        ~workOrderHash=order.hash,
        ~reason="all deterministic blockers cleared",
      )
      pushEvent(events, event)
    }
  | Some(row) if row.state == S.Blocked => {
      let locked = appendEvent(
        ~stateDir,
        ~targetId,
        ~state=S.Locked,
        ~actor=S.System,
        ~reason="reconciling changed authority",
      )
      pushEvent(events, locked)
      appendCompiled(~stateDir, ~order, ~events, ~reason="compiled reconciled authority")
      let ready = appendEvent(
        ~stateDir,
        ~targetId,
        ~state=S.Ready,
        ~actor=S.System,
        ~packetHash=order.packetHash,
        ~workOrderHash=order.hash,
        ~reason="all deterministic blockers cleared",
      )
      pushEvent(events, ready)
    }
  | None => {
      let locked = appendEvent(
        ~stateDir,
        ~targetId,
        ~state=S.Locked,
        ~actor=S.System,
        ~reason="locked for deterministic reconciliation",
      )
      pushEvent(events, locked)
      appendCompiled(~stateDir, ~order, ~events, ~reason="compiled reconciled authority")
      let ready = appendEvent(
        ~stateDir,
        ~targetId,
        ~state=S.Ready,
        ~actor=S.System,
        ~packetHash=order.packetHash,
        ~workOrderHash=order.hash,
        ~reason="all deterministic blockers cleared",
      )
      pushEvent(events, ready)
    }
  | Some(row) if row.state == S.Rejected || row.state == S.Superseded => {
      appendCompiled(~stateDir, ~order, ~events, ~reason="compiled reconciled authority")
      let ready = appendEvent(
        ~stateDir,
        ~targetId,
        ~state=S.Ready,
        ~actor=S.System,
        ~packetHash=order.packetHash,
        ~workOrderHash=order.hash,
        ~reason="all deterministic blockers cleared",
      )
      pushEvent(events, ready)
    }
  | Some(_) => {
      supersede(
        ~stateDir,
        ~targetId,
        ~events,
        ~reason="authority bindings changed during reconciliation",
      )
      appendCompiled(~stateDir, ~order, ~events, ~reason="compiled changed authority")
      let ready = appendEvent(
        ~stateDir,
        ~targetId,
        ~state=S.Ready,
        ~actor=S.System,
        ~packetHash=order.packetHash,
        ~workOrderHash=order.hash,
        ~reason="all deterministic blockers cleared",
      )
      pushEvent(events, ready)
    }
  }
}

let qString = value => Js.Json.string(value)

let blockerJson = (blocker: blocker) => {
  let row = Js.Dict.empty()
  Js.Dict.set(row, "id", qString(blocker.id))
  Js.Dict.set(row, "code", qString(blocker.code))
  Js.Dict.set(row, "subject", qString(blocker.subject))
  Js.Dict.set(row, "message", qString(blocker.message))
  Js.Json.object_(row)
}

let readyJson = (~row: S.targetState, ~order: W.workOrder) => {
  let entry = Js.Dict.empty()
  Js.Dict.set(entry, "targetId", qString(order.targetId))
  Js.Dict.set(entry, "packetHash", qString(order.packetHash))
  Js.Dict.set(entry, "workOrderHash", qString(order.hash))
  Js.Dict.set(entry, "readyEventId", qString(row.lastEvent.id))
  Js.Json.object_(entry)
}

let blockedJson = (~targetId, ~state, ~blockers) => {
  let entry = Js.Dict.empty()
  Js.Dict.set(entry, "targetId", qString(targetId))
  Js.Dict.set(entry, "lifecycle", qString(state))
  Js.Dict.set(entry, "blockers", Js.Json.array(blockers->Belt.Array.map(blockerJson)))
  Js.Json.object_(entry)
}

let queueBody = (~schema, ~entries, ~snapshot: S.snapshot) => {
  let root = Js.Dict.empty()
  Js.Dict.set(root, "schema", qString(schema))
  Js.Dict.set(
    root,
    "lifecycleEventCount",
    Js.Json.number(Belt.Int.toFloat(Belt.Array.length(snapshot.events))),
  )
  switch Belt.Array.get(snapshot.events, Belt.Array.length(snapshot.events) - 1) {
  | Some(head) => Js.Dict.set(root, "lifecycleHeadEventId", qString(head.id))
  | None => ()
  }
  Js.Dict.set(root, "entries", Js.Json.array(entries))
  D.canonicalJson(Js.Json.object_(root)) ++ "\n"
}

let safeQueuePath = (~stateDir, ~relative, ~label) =>
  try Safety.manifestOutputPath(~baseDir=stateDir, ~relativePath=relative, ~label) catch {
  | Safety.OutputSafetyError(message) => die("unsafe queue path: " ++ message)
  }

let atomicQueueWrite = (~stateDir, ~name, ~body) => {
  B.ensureDirPath(B.Path(stateDir ++ "/queues"))
  let destination = safeQueuePath(
    ~stateDir,
    ~relative="queues/" ++ name ++ ".json",
    ~label=name ++ " queue",
  )
  if B.exists(B.Path(destination)) && B.readText(B.Path(destination)) == body {
    ()
  } else {
    let temporary = safeQueuePath(
      ~stateDir,
      ~relative="queues/." ++ name ++ "." ++ B.sha256Text(body) ++ ".tmp",
      ~label="temporary " ++ name ++ " queue",
    )
    if !B.writeTextExclusive(B.Path(temporary), body) &&
      (!B.exists(B.Path(temporary)) || B.readText(B.Path(temporary)) != body) {
      die("temporary " ++ name ++ " queue collided with different content")
    }
    try Safety.atomicRename(~temporaryPath=temporary, ~destinationPath=destination) catch {
    | _ =>
      if !B.exists(B.Path(destination)) || B.readText(B.Path(destination)) != body {
        die("could not atomically materialize " ++ name ++ " queue")
      }
    }
  }
}

let materializeQueues = (~packetPath, ~stateDir, ~focusTargetId) =>
  try {
    S.withConsistentSnapshot(~stateDir, snapshot => {
      let targetIds = Js.Dict.empty()
      snapshot.targets->Belt.Array.forEach(row => Js.Dict.set(targetIds, row.targetId, true))
      Js.Dict.set(targetIds, focusTargetId, true)
      try {
        let context = D.reconstruct(B.readText(B.Path(packetPath)))
        context.packet.targets->Belt.Array.forEach(target => Js.Dict.set(targetIds, target.id, true))
      } catch {
      | D.DomainError(_) => ()
      | B.BackendError(_) => ()
      }
      let ids = Js.Dict.keys(targetIds)
      ids->Js.Array2.sortInPlace->ignore
      let readyEntries: array<Js.Json.t> = []
      let blockedEntries: array<Js.Json.t> = []
      ids->Belt.Array.forEach(targetId => {
        /* Recompile every target only after acquiring the lifecycle lease. A
           reconciliation result computed earlier is diagnostic data, never a
           snapshot that may overwrite a newer queue generation. */
        let evaluated = W.compile(~packetPath, ~targetId)
        let current = currentFor(snapshot, targetId)
        let (order, blockers) = switch evaluated.workOrder {
        | None => (None, blockersFromFindings(evaluated.findings)->sortBlockers)
        | Some(order) => (Some(order), dependencyBlockers(~order, ~snapshot))
        }
        switch (order, blockers, current) {
        | (Some(order), blockers, Some(row)) if Belt.Array.length(blockers) == 0 &&
            row.state == S.Ready && exactBindings(row, order) =>
          readyEntries->Js.Array2.push(readyJson(~row, ~order))->ignore
        | (Some(order), blockers, Some(row)) if Belt.Array.length(blockers) == 0 &&
            row.state == S.Ready => {
            let drift = [makeBlocker(
              ~code="READY_AUTHORITY_DRIFT",
              ~subject=targetId,
              ~message="ready lifecycle bindings do not match current authority",
            )]
            blockedEntries->Js.Array2.push(
              blockedJson(~targetId, ~state=S.lifecycleName(row.state), ~blockers=drift),
            )->ignore
            ignore(order)
          }
        | (_, blockers, current) if Belt.Array.length(blockers) > 0 =>
          blockedEntries->Js.Array2.push(
            blockedJson(
              ~targetId,
              ~state=current
                ->Belt.Option.map(row => S.lifecycleName(row.state))
                ->Belt.Option.getWithDefault("draft"),
              ~blockers,
            ),
          )->ignore
        | (Some(_), _, None) => {
            let unreconciled = [makeBlocker(
              ~code="TARGET_NOT_RECONCILED",
              ~subject=targetId,
              ~message="target has not been reconciled into durable lifecycle state",
            )]
            blockedEntries->Js.Array2.push(
              blockedJson(~targetId, ~state="draft", ~blockers=unreconciled),
            )->ignore
          }
        | (_, _, Some(row)) if row.state == S.Blocked => {
            let lifecycleBlocker = [makeBlocker(
              ~code="LIFECYCLE_BLOCKED",
              ~subject=targetId,
              ~message=row.lastEvent.reason,
            )]
            blockedEntries->Js.Array2.push(
              blockedJson(
                ~targetId,
                ~state=S.lifecycleName(row.state),
                ~blockers=lifecycleBlocker,
              ),
            )->ignore
          }
        | _ => ()
        }
      })
      atomicQueueWrite(
        ~stateDir,
        ~name="ready",
        ~body=queueBody(
          ~schema="production.ready-queue/v2",
          ~entries=readyEntries,
          ~snapshot,
        ),
      )
      atomicQueueWrite(
        ~stateDir,
        ~name="blocked",
        ~body=queueBody(
          ~schema="production.blocked-queue/v2",
          ~entries=blockedEntries,
          ~snapshot,
        ),
      )
    })
  } catch {
  | S.StateError(message) => die("could not materialize lifecycle queues: " ++ message)
  }

let refreshQueues = (~packetPath, ~stateDir, ~targetId) =>
  materializeQueues(~packetPath, ~stateDir, ~focusTargetId=targetId)

let reconcile = (~packetPath, ~stateDir, ~targetId) => {
  let absoluteStateDir = resolvePath(stateDir)
  let recovery = try G.recover(~packetPath, ~stateDir=absoluteStateDir, ~targetId) catch {
  | G.GatewayError(message) => die("execution recovery failed closed: " ++ message)
  }
  let evaluation = W.compile(~packetPath, ~targetId)
  let events: array<string> = []
  let snapshot = loadState(absoluteStateDir)
  let before = currentFor(snapshot, targetId)
  let result = switch (recovery.changed, before, evaluation.workOrder) {
  | (true, Some(row), workOrder) if row.state == S.Blocked => {
      let blockers = [makeBlocker(
        ~code="EXECUTION_RECOVERED_BEFORE_SUBMIT",
        ~subject=targetId,
        ~message=recovery.message ++ "; a new explicit authorization is required",
      )]
      {
        targetId,
        status: ReconciliationBlocked,
        workOrder,
        blockers,
        eventIds: events,
      }
    }
  | (_, _, None) => {
      let blockers = blockersFromFindings(evaluation.findings)->sortBlockers
      reconcileBlocked(
        ~stateDir=absoluteStateDir,
        ~targetId,
        ~order=None,
        ~current=before,
        ~blockers,
        ~events,
      )
      {
        targetId,
        status: ReconciliationBlocked,
        workOrder: None,
        blockers,
        eventIds: events,
      }
    }
  | (_, _, Some(order)) => {
      let blockers = dependencyBlockers(~order, ~snapshot)
      if Belt.Array.length(blockers) > 0 {
        reconcileBlocked(
          ~stateDir=absoluteStateDir,
          ~targetId,
          ~order=Some(order),
          ~current=before,
          ~blockers,
          ~events,
        )
        {
          targetId,
          status: ReconciliationBlocked,
          workOrder: Some(order),
          blockers,
          eventIds: events,
        }
      } else {
        reconcileReady(~stateDir=absoluteStateDir, ~order, ~current=before, ~events)
        let after = loadState(absoluteStateDir)->currentFor(targetId)
        let status = switch after {
        | Some(row) if row.state == S.Ready => ReadyForExecution
        | Some(row) => LifecycleCurrent(row.state)
        | None => die("reconciliation did not materialize target state")
        }
        {targetId, status, workOrder: Some(order), blockers: [], eventIds: events}
      }
    }
  }
  materializeQueues(~packetPath, ~stateDir=absoluteStateDir, ~focusTargetId=result.targetId)
  result
}

let explain = reconciliation =>
  switch reconciliation.status {
  | ReadyForExecution =>
    let order = reconciliation.workOrder->Belt.Option.getExn
    "READY " ++ reconciliation.targetId ++ "\n" ++
    "Work order: " ++ order.hash ++ "\n" ++
    "Packet: " ++ order.packetHash ++ "\n"
  | LifecycleCurrent(state) =>
    "CURRENT " ++ reconciliation.targetId ++ " " ++ S.lifecycleName(state) ++ "\n" ++
    reconciliation.workOrder->Belt.Option.mapWithDefault("", order =>
      "Work order: " ++ order.hash ++ "\nPacket: " ++ order.packetHash ++ "\n"
    )
  | ReconciliationBlocked =>
    "BLOCKED " ++ reconciliation.targetId ++ "\n" ++
    reconciliation.blockers
    ->Belt.Array.map(blocker =>
      "- [" ++ blocker.id ++ "] " ++ blocker.code ++ " " ++ blocker.subject ++ ": " ++
      blocker.message
    )
    ->Js.Array2.joinWith("\n") ++ "\n"
  }

let clearedForExecution = (~packetPath, ~stateDir, ~targetId) => {
  let reconciled = reconcile(~packetPath, ~stateDir, ~targetId)
  switch reconciled.status {
  | ReconciliationBlocked => die(explain(reconciled))
  | LifecycleCurrent(state) =>
    die(
      targetId ++ " is already in lifecycle state " ++ S.lifecycleName(state) ++
      "; execution requires a newly reconciled ready state",
    )
  | ReadyForExecution => ()
  }
  let evaluated = P.evaluate(~packetPath, ~stateDir=resolvePath(stateDir), ~targetId)
  let cleared = switch evaluated.cleared {
  | Some(value) => value
  | None => die("preflight did not clear execution:\n" ++ P.explain(evaluated))
  }
  cleared
}

let executionAuthorizationBinding = (~packetPath, ~stateDir, ~targetId, ~provider) => {
  let cleared = clearedForExecution(~packetPath, ~stateDir, ~targetId)
  G.authorizationBinding(~cleared, ~provider)
}

let execute = (
  ~packetPath,
  ~stateDir,
  ~targetId,
  ~provider: G.provider,
  ~authorizationCommandText,
) => {
  let cleared = clearedForExecution(~packetPath, ~stateDir, ~targetId)
  let authorization = try {
    G.authorize(~cleared, ~provider, ~commandText=authorizationCommandText)
  } catch {
  | G.GatewayError(message) => die(message)
  }
  try {
    let result = G.execute(~authorization, ~provider)
    refreshQueues(~packetPath, ~stateDir=resolvePath(stateDir), ~targetId)
    result
  } catch {
  | G.GatewayError(message) => {
      refreshQueues(~packetPath, ~stateDir=resolvePath(stateDir), ~targetId)
      die(message)
    }
  }
}

let requireCurrentCandidate = (
  ~stateDir,
  ~order: W.workOrder,
  ~candidate: A.candidate,
  ~requiredState,
) =>
  switch loadState(stateDir)->currentFor(order.targetId) {
  | Some(row)
    if row.state == requiredState && exactBindings(row, order) &&
      row.lastEvent.artifactHash == Some(candidate.artifactHash) => ()
  | _ =>
    die(
      "candidate does not match the current " ++ S.lifecycleName(requiredState) ++
      " lifecycle authority",
    )
  }

let currentOrder = (~packetPath, ~targetId) => {
  let evaluated = W.compile(~packetPath, ~targetId)
  switch evaluated.workOrder {
  | Some(order) => order
  | None => die(W.explain(evaluated))
  }
}

let storeFor = (~stateDir, ~order: W.workOrder) =>
  A.openStore(~root=resolvePath(stateDir) ++ "/store", ~reviewBatchSize=order.reviewBatchSize)

let candidateFor = (~store, ~candidateHash) =>
  switch A.listCandidates(store)->Belt.Array.getBy(row => row.candidateHash == candidateHash) {
  | Some(candidate) => candidate
  | None => die("unknown candidate " ++ candidateHash)
  }

let executionAuthorityCurrent = (~packetPath, ~stateDir, ~candidate) =>
  try G.candidateAuthorityCurrent(~packetPath, ~stateDir, ~candidate) catch {
  | G.GatewayError(message) => die("candidate execution authority is invalid: " ++ message)
  }

let requireExecutionAuthority = (~packetPath, ~stateDir, ~candidate) =>
  if !executionAuthorityCurrent(~packetPath, ~stateDir, ~candidate) {
    die("candidate execution authority is stale under current dependencies or references")
  }

let inspectCandidate = (~packetPath, ~stateDir, ~targetId, ~candidateHash, ~inspector) => {
  let Inspector(selectedInspector) = inspector
  let absoluteStateDir = resolvePath(stateDir)
  let order = currentOrder(~packetPath, ~targetId)
  let store = storeFor(~stateDir=absoluteStateDir, ~order)
  let candidate = candidateFor(~store, ~candidateHash)
  if candidate.targetId != targetId {
    die("candidate belongs to a different target")
  }
  if candidate.producerId == selectedInspector.principalId {
    die("independent inspector must not be the candidate producer")
  }
  if candidate.packetHash != order.packetHash || candidate.workOrderHash != order.hash {
    die("candidate authority does not match the current work order")
  }
  requireExecutionAuthority(~packetPath, ~stateDir=absoluteStateDir, ~candidate)
  requireCurrentCandidate(
    ~stateDir=absoluteStateDir,
    ~order,
    ~candidate,
    ~requiredState=S.CandidateQuarantine,
  )
  if A.listDispositions(store)->Belt.Array.some(row => row.candidateHash == candidateHash) {
    die("candidate already has a terminal or quarantine disposition")
  }
  let checks = W.semanticChecks(order)
  if Belt.Array.length(checks) == 0 {
    die("work order has no independent semantic checks")
  }
  let job: I.job = {
    schema: "production.inspection-job/v1",
    workOrderHash: order.hash,
    artifactHash: candidate.artifactHash,
    policyHash: I.policyHash(checks),
    checks,
  }
  let rawReport = switch selectedInspector.inspect({job, candidate}) {
  | Ok(raw) => raw
  | Error(message) => die("independent inspector failed: " ++ message)
  }
  /* Inspection evidence cannot be committed if dependency/reference authority
     changed while the independent adapter was running. */
  requireExecutionAuthority(~packetPath, ~stateDir=absoluteStateDir, ~candidate)
  requireCurrentCandidate(
    ~stateDir=absoluteStateDir,
    ~order,
    ~candidate,
    ~requiredState=S.CandidateQuarantine,
  )
  let report = try I.decodeReport(rawReport) catch {
  | I.InspectionError(message) => die("invalid independent inspection report: " ++ message)
  }
  if report.inspectorId != selectedInspector.principalId {
    die("inspection report identity does not match the selected inspector")
  }
  let adjudication = try I.adjudicate(~job, ~report) catch {
  | I.InspectionError(message) => die("inspection failed closed: " ++ message)
  }
  let reportText = I.encodeReport(report)
  let verdict = switch adjudication.outcome {
  | I.Quarantine => A.Fail
  | I.HumanRequired => A.Unknown
  | I.ReviewReady => A.Pass
  }
  requireExecutionAuthority(~packetPath, ~stateDir=absoluteStateDir, ~candidate)
  requireCurrentCandidate(
    ~stateDir=absoluteStateDir,
    ~order,
    ~candidate,
    ~requiredState=S.CandidateQuarantine,
  )
  let record = try {
    A.recordInspection(
      ~store,
      ~candidate,
      ~reportText,
      ~inspectorId=selectedInspector.principalId,
      ~verdict,
    )
  } catch {
  | A.StoreError(message) => die("could not preserve inspection evidence: " ++ message)
  }
  let lifecycleEvent = switch adjudication.outcome {
  | I.Quarantine => {
      try {
        A.recordDisposition(
          ~store,
          ~candidate,
          ~kind=A.Quarantined,
          ~reason="independent semantic inspection failed",
          ~supersededBy=None,
        )->ignore
      } catch {
      | A.StoreError(message) => die("could not quarantine failed inspection: " ++ message)
      }
      None
    }
  | I.HumanRequired =>
    Some(
      appendEvent(
        ~stateDir=absoluteStateDir,
        ~targetId,
        ~state=S.Unknown,
        ~actor=S.System,
        ~packetHash=order.packetHash,
        ~workOrderHash=order.hash,
        ~artifactHash=candidate.artifactHash,
        ~reportHash=record.reportHash,
        ~reason="independent inspection returned UNKNOWN; candidate remains quarantined",
      ),
    )
  | I.ReviewReady =>
    Some(
      appendEvent(
        ~stateDir=absoluteStateDir,
        ~targetId,
        ~state=S.ReviewReady,
        ~actor=S.System,
        ~packetHash=order.packetHash,
        ~workOrderHash=order.hash,
        ~artifactHash=candidate.artifactHash,
        ~reportHash=record.reportHash,
        ~reason="all independent semantic checks passed",
      ),
    )
  }
  refreshQueues(~packetPath, ~stateDir=absoluteStateDir, ~targetId)
  {candidate, report, adjudication, record, lifecycleEvent}
}

let candidateMatchesReviewReady = (
  ~packetPath,
  ~stateDir,
  ~packetHash,
  ~snapshot: S.snapshot,
  ~inspections: array<A.inspection>,
  ~candidate: A.candidate,
) =>
  executionAuthorityCurrent(~packetPath, ~stateDir, ~candidate) &&
  candidate.packetHash == packetHash &&
  snapshot.targets->Belt.Array.some(row => {
    let lifecycleMatches = row.targetId == candidate.targetId && row.state == S.ReviewReady &&
      row.lastEvent.packetHash == Some(candidate.packetHash) &&
      row.lastEvent.workOrderHash == Some(candidate.workOrderHash) &&
      row.lastEvent.artifactHash == Some(candidate.artifactHash)
    if !lifecycleMatches {
      false
    } else {
      let reportMatches = inspections->Belt.Array.some(inspection =>
        inspection.candidateHash == candidate.candidateHash && inspection.verdict == A.Pass &&
        row.lastEvent.reportHash == Some(inspection.reportHash)
      )
      let authorityMatches = switch W.compile(~packetPath, ~targetId=row.targetId).workOrder {
      | Some(order) => order.packetHash == candidate.packetHash && order.hash == candidate.workOrderHash
      | None => false
      }
      reportMatches && authorityMatches
    }
  })

let createReviewBatch = (~packetPath, ~stateDir, ~targetId) => {
  let absoluteStateDir = resolvePath(stateDir)
  let order = currentOrder(~packetPath, ~targetId)
  let store = storeFor(~stateDir=absoluteStateDir, ~order)
  let snapshot = loadState(absoluteStateDir)
  let inspections = A.listInspections(store)
  let dispositions = A.listDispositions(store)
  A.listCandidates(store)->Belt.Array.forEach(candidate => {
    if candidate.targetId == targetId {
    let evidence = inspections->Belt.Array.keep(row => row.candidateHash == candidate.candidateHash)
    let passOnly = evidence->Belt.Array.some(row => row.verdict == A.Pass) &&
      !(evidence->Belt.Array.some(row => row.verdict != A.Pass))
    let disposed = dispositions->Belt.Array.some(row => row.candidateHash == candidate.candidateHash)
    if passOnly && !disposed && !candidateMatchesReviewReady(
      ~packetPath,
      ~stateDir=absoluteStateDir,
      ~packetHash=order.packetHash,
      ~snapshot,
      ~inspections,
      ~candidate,
    ) {
      A.recordDisposition(
        ~store,
        ~candidate,
        ~kind=A.Stale,
        ~reason="PASS evidence has no matching current review_ready lifecycle authority",
        ~supersededBy=None,
      )->ignore
    }
    }
  })
  let batch = try A.createReviewBatch(
    ~store,
    ~targetId,
    ~packetHash=order.packetHash,
    ~workOrderHash=order.hash,
  ) catch {
  | A.StoreError(message) => die("could not create review batch: " ++ message)
  }
  switch batch {
  | None => None
  | Some(batch) => {
      let fresh = loadState(absoluteStateDir)
      let freshInspections = A.listInspections(store)
      batch.entries->Belt.Array.forEach(entry => {
        let candidate = candidateFor(~store, ~candidateHash=entry.candidateHash)
        if !candidateMatchesReviewReady(
          ~packetPath,
          ~stateDir=absoluteStateDir,
          ~packetHash=order.packetHash,
          ~snapshot=fresh,
          ~inspections=freshInspections,
          ~candidate,
        ) {
          die("review batch contains candidate without current review_ready authority")
        }
      })
      Some(batch)
    }
  }
}

let humanVerdictName = verdict =>
  switch verdict {
  | HumanPass => "PASS"
  | HumanFail => "FAIL"
  | HumanUnknown => "UNKNOWN"
  }

let validateAnswers = (~order: W.workOrder, ~decision, ~answers, ~note) => {
  if Js.String2.trim(note) == "" {
    die("human review note must be substantive and nonempty")
  }
  let questions = W.humanQuestions(order)
  let seen = Js.Dict.empty()
  answers->Belt.Array.forEach(answer => {
    if Js.String2.trim(answer.evidence) == "" {
      die("human answer " ++ answer.requirementId ++ " requires evidence")
    }
    if Js.Dict.get(seen, answer.requirementId) != None {
      die("duplicate human answer " ++ answer.requirementId)
    }
    Js.Dict.set(seen, answer.requirementId, true)
    if !(questions->Belt.Array.some(question => question.id == answer.requirementId)) {
      die("human answer refers to unknown requirement " ++ answer.requirementId)
    }
  })
  questions->Belt.Array.forEach(question =>
    if Js.Dict.get(seen, question.id) == None {
      die("human review is missing answer for " ++ question.id)
    }
  )
  switch decision {
  | A.Approve if answers->Belt.Array.some(answer => answer.verdict != HumanPass) =>
    die("approval requires PASS evidence for every human-only acceptance item")
  | _ => ()
  }
}

let answersNote = (~answers: array<humanAnswer>, ~note) => {
  let sorted = Js.Array2.copy(answers)
  sorted->Js.Array2.sortInPlaceWith((left, right) =>
    compare(left.requirementId, right.requirementId)
  )->ignore
  note ++ "\n\nHuman acceptance evidence:\n" ++
  sorted
  ->Belt.Array.map(answer =>
    "[" ++ answer.requirementId ++ "] " ++ humanVerdictName(answer.verdict) ++ ": " ++
    answer.evidence
  )
  ->Js.Array2.joinWith("\n")
}

let reviewDecisionName = decision =>
  switch decision {
  | A.Approve => "approve"
  | A.Reject => "reject"
  }

let reviewEntryFor = (~store, ~batchHash, ~candidateHash) => {
  let batch = A.listReviewBatches(store)->Belt.Array.getBy(row => row.batchHash == batchHash)
  switch batch {
  | None => die("unknown review batch " ++ batchHash)
  | Some(batch) =>
    switch batch.entries->Belt.Array.getBy(row => row.candidateHash == candidateHash) {
    | Some(entry) => entry
    | None => die("candidate " ++ candidateHash ++ " is not in review batch " ++ batchHash)
    }
  }
}

let reviewCommandBinding = (
  ~packetPath,
  ~stateDir,
  ~targetId,
  ~batchHash,
  ~candidateHash,
  ~decision,
  ~answers,
  ~note,
) => {
  let absoluteStateDir = resolvePath(stateDir)
  let order = currentOrder(~packetPath, ~targetId)
  let store = storeFor(~stateDir=absoluteStateDir, ~order)
  let candidate = candidateFor(~store, ~candidateHash)
  if candidate.packetHash != order.packetHash || candidate.workOrderHash != order.hash {
    die("review candidate authority does not match the current work order")
  }
  requireExecutionAuthority(~packetPath, ~stateDir=absoluteStateDir, ~candidate)
  requireCurrentCandidate(
    ~stateDir=absoluteStateDir,
    ~order,
    ~candidate,
    ~requiredState=S.ReviewReady,
  )
  let snapshot = loadState(absoluteStateDir)
  if !candidateMatchesReviewReady(
    ~packetPath,
    ~stateDir=absoluteStateDir,
    ~packetHash=order.packetHash,
    ~snapshot,
    ~inspections=A.listInspections(store),
    ~candidate,
  ) {
    die("review candidate lacks exact current PASS inspection authority")
  }
  validateAnswers(~order, ~decision, ~answers, ~note)
  let entry = reviewEntryFor(~store, ~batchHash, ~candidateHash)
  let currentEventId = switch currentFor(snapshot, targetId) {
  | Some(row) => row.lastEvent.id
  | None => die("review target is missing current lifecycle authority")
  }
  Credentials.bindingHash([
    "record_human_review",
    order.packetHash,
    order.hash,
    targetId,
    batchHash,
    candidateHash,
    candidate.artifactHash,
    entry.reportHashes->Js.Array2.joinWith("\n"),
    currentEventId,
    reviewDecisionName(decision),
    answersNote(~answers, ~note),
  ])
}

let recordHumanReview = (
  ~packetPath,
  ~stateDir,
  ~targetId,
  ~batchHash,
  ~candidateHash,
  ~commandText,
  ~decision,
  ~answers,
  ~note,
) => {
  let absoluteStateDir = resolvePath(stateDir)
  let order = currentOrder(~packetPath, ~targetId)
  let store = storeFor(~stateDir=absoluteStateDir, ~order)
  let candidate = candidateFor(~store, ~candidateHash)
  if candidate.packetHash != order.packetHash || candidate.workOrderHash != order.hash {
    die("review candidate authority does not match the current work order")
  }
  requireExecutionAuthority(~packetPath, ~stateDir=absoluteStateDir, ~candidate)
  requireCurrentCandidate(
    ~stateDir=absoluteStateDir,
    ~order,
    ~candidate,
    ~requiredState=S.ReviewReady,
  )
  if !candidateMatchesReviewReady(
    ~packetPath,
    ~stateDir=absoluteStateDir,
    ~packetHash=order.packetHash,
    ~snapshot=loadState(absoluteStateDir),
    ~inspections=A.listInspections(store),
    ~candidate,
  ) {
    die("review candidate lacks exact current PASS inspection authority")
  }
  validateAnswers(~order, ~decision, ~answers, ~note)
  let bindingHash = reviewCommandBinding(
    ~packetPath,
    ~stateDir=absoluteStateDir,
    ~targetId,
    ~batchHash,
    ~candidateHash,
    ~decision,
    ~answers,
    ~note,
  )
  let command = try {
    Credentials.verifyHumanCommand(
      ~packetPath,
      ~raw=commandText,
      ~role=D.Reviewer,
      ~action="record_human_review",
      ~bindingHash,
    )
  } catch {
  | Credentials.CredentialError(message) => die("human review command refused: " ++ message)
  }
  try Credentials.consumeHumanCommand(~stateDir=absoluteStateDir, ~command) catch {
  | Credentials.CredentialError(message) => die("human review command refused: " ++ message)
  }
  /* The signed command is necessary but not sufficient: its candidate must
     still have the exact execution and lifecycle authority at commit time. */
  requireExecutionAuthority(~packetPath, ~stateDir=absoluteStateDir, ~candidate)
  requireCurrentCandidate(
    ~stateDir=absoluteStateDir,
    ~order,
    ~candidate,
    ~requiredState=S.ReviewReady,
  )
  let reviewerId = Credentials.commandPrincipalId(command)
  let normalizedNote = answersNote(~answers, ~note)
  let record = try {
    A.recordReview(
      ~store,
      ~batchHash,
      ~candidateHash,
      ~reviewerId,
      ~decision,
      ~note=normalizedNote,
    )
  } catch {
  | A.StoreError(message) => die("human review was not recorded: " ++ message)
  }
  switch decision {
  | A.Reject =>
    try {
      A.recordDisposition(
        ~store,
        ~candidate,
        ~kind=A.Rejected,
        ~reason="human review " ++ record.reviewHash ++ " rejected the candidate",
        ~supersededBy=None,
      )->ignore
    } catch {
    | A.StoreError(message) => die("human rejection disposition failed: " ++ message)
    }
  | A.Approve => ()
  }
  let state = decision == A.Approve ? S.Approved : S.Rejected
  let lifecycleEvent = appendEvent(
    ~stateDir=absoluteStateDir,
    ~targetId,
    ~state,
    ~actor=S.Human,
    ~packetHash=order.packetHash,
    ~workOrderHash=order.hash,
    ~artifactHash=candidate.artifactHash,
    ~reportHash=record.reviewHash,
    ~reason=(decision == A.Approve ? "human approved review " : "human rejected review ") ++
      record.reviewHash ++ " by " ++ reviewerId,
  )
  refreshQueues(~packetPath, ~stateDir=absoluteStateDir, ~targetId)
  {record, lifecycleEvent}
}
