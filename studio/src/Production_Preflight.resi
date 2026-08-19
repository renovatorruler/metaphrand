/* The only module that can mint a cleared work order. The constructor is
   intentionally hidden; downstream execution receives proof, not booleans. */

type cleared
type dependencyProof = {
  targetId: string,
  eventId: string,
  packetHash: string,
  workOrderHash: string,
}
type evaluation = {cleared: option<cleared>, findings: array<Production_WorkOrder.finding>}

let evaluate: (~packetPath: string, ~stateDir: string, ~targetId: string) => evaluation
let workOrder: cleared => Production_WorkOrder.workOrder
let stateDirectory: cleared => string
let readyEventId: cleared => string
let dependencyProofs: cleared => array<dependencyProof>
let explain: evaluation => string
