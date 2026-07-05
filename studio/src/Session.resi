/* ============================================================================
   Session — the ONE and only path to the model, and now a WARM one.

   `ask` is the single call. Under it sits exactly ONE long-lived `claude`
   process, spawned in stream-json mode the first time you ask and reused for
   every turn after. The boot cost (system prompt, memory, tools) is paid ONCE
   for the whole run, not once per call. Each turn is a single message written
   to that process's stdin; its reply is read off stdout.

   Sequential BY CONSTRUCTION. Every `ask` is threaded through one promise
   queue: it waits for the previous turn to fully settle before it writes, then
   installs its own completion as the gate for the next. Two `ask`s fired in the
   same tick still run strictly one-after-another. There is no code path that
   issues two model calls at once -- not "you shouldn't", but "there is no door".

   Capped by the CLAUDE_STUDIO_BUDGET environment variable -- a number YOU set,
   not a line in the source I can quietly raise. CLAUDE_STUDIO_BIN can point the
   one path at a fake model for zero-spend testing. Each turn logs the model's
   own usage + cost report, so spend is finally observable.

   Honest about the limits: ReScript has no linear types, so "two overlapping
   calls" cannot be made a *compile* error -- the enforcement is the single
   serializing door, at runtime. And nothing here stops me from setting the env
   var myself or writing a fresh raw spawn that bypasses this module entirely.
   The compiler enforces the single path; only you holding the budget and the
   trigger enforce the amount.

   Call `close` when a run is done to end the process (a safety net unrefs it
   too, so a forgotten close won't hang the run).
   ============================================================================ */

/* raised when the budget cap is hit, or a turn fails/times out. Callers can
   catch this specifically to tell a refusal apart from a model failure. */
exception SessionError(string)

let ask: string => promise<string>
let callsMade: unit => int
let close: unit => unit
