module W = Production_WorkOrder
module S = Production_State

type dependencyProof = {
  targetId: string,
  eventId: string,
  packetHash: string,
  workOrderHash: string,
}
type clearedData = {
  order: W.workOrder,
  stateDir: string,
  readyEventId: string,
  dependencies: array<dependencyProof>,
}
type cleared = Cleared(clearedData)
type evaluation = {cleared: option<cleared>, findings: array<W.finding>}

@module("node:path") external resolvePath: string => string = "resolve"

let add = (findings, code, subject, message) =>
  findings->Js.Array2.push({W.code, subject, message})->ignore

let currentFor = (snapshot: S.snapshot, targetId) =>
  snapshot.targets->Belt.Array.getBy(target => target.targetId == targetId)

let evaluate = (~packetPath, ~stateDir, ~targetId) => {
  let compiled = W.compile(~packetPath, ~targetId)
  let findings = Js.Array2.copy(compiled.findings)
  switch compiled.workOrder {
  | None => {cleared: None, findings}
  | Some(order) => {
      let dependencies: array<dependencyProof> = []
      let snapshot = try {
        Some(S.load(~stateDir=resolvePath(stateDir)))
      } catch {
      | S.StateError(message) => {
          add(findings, "STATE_LEDGER_INVALID", targetId, message)
          None
        }
      }
      switch snapshot {
      | None => ()
      | Some(snapshot) => {
          switch currentFor(snapshot, targetId) {
          | None =>
            add(
              findings,
              "TARGET_NOT_RECONCILED",
              targetId,
              "target has no lifecycle state; reconcile the packet before execution",
            )
          | Some(current) => {
              if current.state != S.Ready {
                add(
                  findings,
                  "TARGET_NOT_READY",
                  targetId,
                  "current lifecycle state is " ++ S.lifecycleName(current.state),
                )
              }
              if current.lastEvent.packetHash != Some(order.packetHash) {
                add(
                  findings,
                  "READY_PACKET_DRIFT",
                  targetId,
                  "ready event does not bind the current packet hash",
                )
              }
              if current.lastEvent.workOrderHash != Some(order.hash) {
                add(
                  findings,
                  "READY_WORK_ORDER_DRIFT",
                  targetId,
                  "ready event does not bind the current work-order hash",
                )
              }
            }
          }
          order.dependencyTargetIds->Belt.Array.forEach(dependencyId =>
            switch currentFor(snapshot, dependencyId) {
            | Some(dependency) if dependency.state == S.Approved || dependency.state == S.Released => {
                if dependency.lastEvent.packetHash != Some(order.packetHash) {
                  add(
                    findings,
                    "DEPENDENCY_PACKET_DRIFT",
                    dependencyId,
                    "dependency approval does not bind the current packet hash",
                  )
                }
                let compiledDependency = W.compile(~packetPath, ~targetId=dependencyId)
                switch compiledDependency.workOrder {
                | Some(dependencyOrder)
                  if dependency.lastEvent.workOrderHash == Some(dependencyOrder.hash) &&
                    dependency.lastEvent.packetHash == Some(order.packetHash) =>
                  dependencies->Js.Array2.push({
                    targetId: dependencyId,
                    eventId: dependency.lastEvent.id,
                    packetHash: order.packetHash,
                    workOrderHash: dependencyOrder.hash,
                  })->ignore
                | Some(_) =>
                  add(
                    findings,
                    "DEPENDENCY_WORK_ORDER_DRIFT",
                    dependencyId,
                    "dependency approval does not bind its current work order",
                  )
                | None =>
                  add(
                    findings,
                    "DEPENDENCY_INVALID",
                    dependencyId,
                    "dependency no longer compiles under current authority",
                  )
                }
              }
            | Some(dependency) =>
              add(
                findings,
                "DEPENDENCY_NOT_APPROVED",
                dependencyId,
                "dependency state is " ++ S.lifecycleName(dependency.state),
              )
            | None =>
              add(
                findings,
                "DEPENDENCY_NOT_RECONCILED",
                dependencyId,
                "dependency has no lifecycle state",
              )
            }
          )
        }
      }
      if Belt.Array.length(findings) == 0 {
        dependencies->Js.Array2.sortInPlaceWith((left, right) => compare(left.targetId, right.targetId))->ignore
        let finalSnapshot = S.load(~stateDir=resolvePath(stateDir))
        let finalCurrent = currentFor(finalSnapshot, targetId)
        switch finalCurrent {
        | Some(current) if current.state == S.Ready &&
            current.lastEvent.packetHash == Some(order.packetHash) &&
            current.lastEvent.workOrderHash == Some(order.hash) => ()
        | _ =>
          add(
            findings,
            "TARGET_CHANGED_DURING_PREFLIGHT",
            targetId,
            "target readiness changed while preflight was being evaluated",
          )
        }
        dependencies->Belt.Array.forEach(proof =>
          switch currentFor(finalSnapshot, proof.targetId) {
          | Some(row) if (row.state == S.Approved || row.state == S.Released) &&
              row.lastEvent.id == proof.eventId &&
              row.lastEvent.packetHash == Some(proof.packetHash) &&
              row.lastEvent.workOrderHash == Some(proof.workOrderHash) => ()
          | _ =>
            add(
              findings,
              "DEPENDENCY_CHANGED_DURING_PREFLIGHT",
              proof.targetId,
              "dependency approval changed while preflight was being evaluated",
            )
          }
        )
        if Belt.Array.length(findings) == 0 {
          let current = finalCurrent->Belt.Option.getExn
          {
            cleared: Some(
              Cleared({
                order,
                stateDir: resolvePath(stateDir),
                readyEventId: current.lastEvent.id,
                dependencies,
              }),
            ),
            findings,
          }
        } else {
          findings->Js.Array2.sortInPlaceWith((left, right) =>
            compare(left.code ++ left.subject ++ left.message, right.code ++ right.subject ++ right.message)
          )->ignore
          {cleared: None, findings}
        }
      } else {
        findings->Js.Array2.sortInPlaceWith((left, right) =>
          compare(left.code ++ left.subject ++ left.message, right.code ++ right.subject ++ right.message)
        )->ignore
        {cleared: None, findings}
      }
    }
  }
}

let workOrder = (Cleared(value)) => value.order
let stateDirectory = (Cleared(value)) => value.stateDir
let readyEventId = (Cleared(value)) => value.readyEventId
let dependencyProofs = (Cleared(value)) => Js.Array2.copy(value.dependencies)

let explain = evaluation =>
  switch evaluation.cleared {
  | Some(proof) => {
      let order = workOrder(proof)
      "READY " ++ order.targetId ++ "\nCleared work order: " ++ order.hash ++ "\n"
    }
  | None =>
    "BLOCKED\n" ++
    evaluation.findings
    ->Belt.Array.map(finding => "- [" ++ finding.code ++ "] " ++ finding.subject ++ ": " ++ finding.message)
    ->Js.Array2.joinWith("\n") ++
    "\n"
  }
