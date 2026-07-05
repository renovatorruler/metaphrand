/* ============================================================================
   Craft — the mechanical AI-marker gate. The unbypassable FLOOR.

   This is ONE stage of the writing pipeline, not the whole fix. It catches only
   what code can cleanly check: the pattern-detectable clear-pane families and
   the banned patterns (colon-reveal, rule-of-three, em-dash in narration,
   clipped one-word fragments, negative parallelism, corrective definition,
   copula-avoidance). It cannot judge voice or taste — the human-judgment passes
   ride ON TOP as skills. Its job is only that prose carrying a detectable AI
   tell cannot pass into a render.

   Honesty: this is a runtime check, not a type. It blocks text it can SEE the
   marker in; it does not make me incapable of writing markers, and it cannot
   catch a marker it has no pattern for. It is the floor, not the ceiling.
   ============================================================================ */

type violation = {device: string, evidence: string}

/* Action / narration prose — gated strictly (the narrator must not perform). */
let gateAction: string => result<unit, array<violation>>

/* Dialogue is a character's own voice, so only the markers that are wrong in
   ANYONE's mouth apply (negative parallelism, corrective definition). */
let gateDialogue: string => result<unit, array<violation>>

/* Human-readable one-liner for a violation, for logs and receipts. */
let show: violation => string

/* Cross-line flat-echo: speaker B (cur) merely repeats speaker A (prev) and ends in
   a period — the banned dead repetition. Returns None when the echo CHANGES something
   (B is a question or "!", or A was a question B answers) or is a bare back-channel. */
let echoViolation: (~prev: string, ~cur: string) => option<violation>
