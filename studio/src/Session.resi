/* ============================================================================
   Session — the ONE and only model-work boundary.

   `ask` is the single call, but it does not choose a provider. The default
   integration is a native-worker handoff selected by the trusted host:

     STUDIO_NATIVE_WORKER_PROVIDER=codex|claude
     STUDIO_NATIVE_JOB_DIR=<unique run directory>
     STUDIO_WORKER_BUDGET=<positive call cap>

   When a response is absent, `ask` writes a JSON job containing the exact
   prompt, provider, prompt hash, and response path, then raises
   `NATIVE_WORKER_REQUIRED`. The host orchestrator delegates that bounded job
   through its own native subagent mechanism. After the worker writes the
   declared response file, retrying the driver consumes it and continues.

   The module never converts a Codex host into a Claude worker or vice versa.
   If no native handoff is configured, it refuses to select a provider.

   Sequential BY CONSTRUCTION. Every `ask` is threaded through one promise
   queue: it waits for the previous turn to fully settle before it writes, then
   installs its own completion as the gate for the next. Two `ask`s fired in the
   same tick still run strictly one-after-another. There is no code path that
   issues two model calls at once -- not "you shouldn't", but "there is no door".

   Native and fake turns are capped by STUDIO_WORKER_BUDGET -- a positive number
   YOU set, not a line in the source I can quietly raise. Missing responses do
   not consume the cap; accepted worker responses do. Only one unresolved
   native job may exist, so a later prompt cannot bypass the current handoff.

   Zero-cost tests explicitly set STUDIO_FAKE_WORKER=1 and
   STUDIO_FAKE_WORKER_BIN. The historical Claude CLI path exists only when
   STUDIO_ALLOW_CLAUDE_CLI=1 is explicitly supplied, and then retains its
   CLAUDE_STUDIO_BUDGET cap. Merely installing `claude` or setting a budget is
   not permission to run it.

   In fake or explicitly opted-in process mode, a timeout kills and invalidates
   the process. The next call starts a new generation, and callbacks from the
   old generation are ignored, so a late result cannot reach a newer request.

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
/* codex | claude | fake | claude-cli | none; written into new receipts. */
let workerProvider: unit => string
let close: unit => unit
