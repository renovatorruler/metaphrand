/* Tests that must pass. `npm test` compiles first, then runs this. */

/* The floor must FLAG text with an em-dash. */
switch Gate.craftlint(Gate.raw("he paused — then signed")) {
| Ok(_) => assert(false)
| Error(findings) => Js.log2("flagged em-dash text, findings:", Array.length(findings))
}

/* Plain text must PASS the floor, and only then can it ship. */
switch Pipeline.process("he paused, then signed") {
| Ok(out) => Js.log2("shipped proven-clean text:", out)
| Error(_) => assert(false)
}

Js.log("OK - gate contract tests passed")
