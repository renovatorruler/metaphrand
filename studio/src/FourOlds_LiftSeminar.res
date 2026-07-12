/* THE FOUR OLDS v14 — dialogue-lift pass on the seminar scene.
   Run: CLAUDE_STUDIO_BUDGET=8 node src/FourOlds_LiftSeminar.res.mjs */
let path = Cinema_Backends.Path(
  "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/draft/engine_seminar_v14.scene.txt",
)

let notes = "PROTECT the vagueness — the Facilitator's examples must stay generic and a little sloppy ('they kind of blur together, it's fine' is the best line in her answer, keep it), and the pivot 'Nobody has to hand you a list. You already know what yours are.' is the scene's tooth — keep its substance intact. 'That's the work happening.' stays. Do NOT sharpen any example toward any specific character or trade. Keep JOSS's Hanoi line and MACK's coffee line verbatim. BAY TWO MAN stays halting and plain."

let main = async () => {
  try {
    let sc = await Write.liftDialogue(~path, ~notes, ~maxTries=4)
    let _ = Write.emit(sc, ~txt=path)
    Js.log("=== LIFTED ===\n")
    Js.log(Cinema_Backends.readText(path))
    Js.log("\n=== VERIFY ===")
    switch Write.verify(path) {
    | Ok() => Js.log("VERIFY OK (production-ready)")
    | Error(m) => Js.log("VERIFY FAILED - " ++ m)
    }
  } catch {
  | Write.WriteError(m) => Js.log("LIFT FAILED: " ++ m)
  | Session.SessionError(m) => Js.log("SESSION: " ++ m)
  }
  Session.close()
}
main()->ignore
