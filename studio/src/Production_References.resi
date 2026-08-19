/* Immutable, content-addressed provider inputs. Source references are checked
   against the work order, copied once beneath control state, and reverified
   immediately before submission. */

exception ReferenceError(string)

let snapshot: (
  ~stateDir: string,
  ~workOrder: Production_WorkOrder.workOrder,
) => array<Production_WorkOrder.reference>

/* Reconstructs the canonical provider-reference set without writing. Both the
   approved source and the already committed content-addressed snapshot must
   still exist with their exact hashes. This is the restart/review path. */
let rehydrate: (
  ~stateDir: string,
  ~workOrder: Production_WorkOrder.workOrder,
) => array<Production_WorkOrder.reference>

let verify: (
  ~stateDir: string,
  ~references: array<Production_WorkOrder.reference>,
) => unit
