/* ============================================================================
   Runner — the orchestration layer above the engine.

   Drive a scene (or a whole episode) through the entire gated pipeline:
   write -> concept gate + repair -> approve -> language gate + repair -> ship.
   The four model-touching jobs are injected as a `crew`, so a free stub crew can
   drive the structure and a real crew (`Session.ask` + the judges) drives a real
   run. Every repair loop is gas-capped; at a stall the scene comes back Blocked.
   ============================================================================ */

type crew = {
  write: string => promise<string>,
  judgeConcept: (Process.conceptGate, string) => promise<option<Process.reasonText>>,
  judgeLanguage: string => promise<array<Gate.violation>>,
  repair: (Process.draft, array<Process.finding>) => promise<Process.draft>,
}

type produced =
  | Shipped(Process.draft)            // cleared both gates, reached the page
  | Blocked(array<Process.finding>)   // a gate stalled (gas out) — back to the director

let produceScene: (Process.brief, Process.bible, crew, Gas.gas) => promise<produced>
let produceEpisode: (array<Process.brief>, Process.bible, crew, Gas.gas) => promise<array<produced>>
