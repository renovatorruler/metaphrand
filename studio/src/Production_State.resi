/* Durable lifecycle state for the generic production control plane.

   The append-only event ledger and its independently persisted high-water head
   anchor are authoritative. current.json is only a materialized view and can
   always be reconstructed from the anchored ledger. */

exception StateError(string)

type lifecycle =
  | Draft
  | Locked
  | Compiled
  | Blocked
  | Ready
  | Authorized
  | CandidateQuarantine
  | Unknown
  | ReviewReady
  | Approved
  | Rejected
  | Superseded
  | Released

type actor = System | Human | Provider | Inspector

type event = {
  id: string,
  sequence: int,
  previousEventId: option<string>,
  targetId: string,
  state: lifecycle,
  actor: actor,
  packetHash: option<string>,
  workOrderHash: option<string>,
  artifactHash: option<string>,
  reportHash: option<string>,
  reason: string,
}

type targetState = {targetId: string, state: lifecycle, lastEvent: event}
type snapshot = {events: array<event>, targets: array<targetState>, nextSequence: int}

let lifecycleName: lifecycle => string
let actorName: actor => string
let decodeEvents: string => array<event>
let encodeEvents: array<event> => string
let reduce: array<event> => snapshot
let transition: (~events: array<event>, ~event: event) => array<event>
let load: (~stateDir: string) => snapshot
/* Holds the same cross-process lease used by append while the callback derives
   secondary state. The supplied snapshot is anchored and cannot become older
   than a concurrent lifecycle append before the callback finishes. */
let withConsistentSnapshot: (~stateDir: string, snapshot => 'a) => 'a
let append: (
  ~stateDir: string,
  ~targetId: string,
  ~state: lifecycle,
  ~actor: actor,
  ~packetHash: string=?,
  ~workOrderHash: string=?,
  ~artifactHash: string=?,
  ~reportHash: string=?,
  ~reason: string,
) => event
/* Refuses stale or internally inconsistent snapshots instead of allowing an
   older materialized view to overwrite newer lifecycle authority. */
let writeMaterialized: (~stateDir: string, ~snapshot: snapshot) => unit
