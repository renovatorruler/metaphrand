/* ============================================================================
   Judge — model-judged assessment: the slop a regex can't catch.

   Non-deterministic; goes through `Session.ask`, so it spends a call. It returns
   the model-judged `Gate.violation`s it finds (comma-drip, forced triads,
   arranged-for-effect); an empty array means clean to its eye. Pair it with the
   mechanical floor (`Gate.craftlint`) — the floor is free and catches the
   obvious; the judge is paid and catches the subtle.
   ============================================================================ */

let language: string => promise<array<Gate.violation>>

/* A concept gate's judgment of a scene. None = passes; Some(reason) = it flags,
   with the model's reason. Lenient by design: it speaks only when sure. */
let concept: (Process.conceptGate, string) => promise<option<Process.reasonText>>
