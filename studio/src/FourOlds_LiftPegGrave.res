/* THE FOUR OLDS — dialogue-lift pass for Peg's grave scene.
   Run: CLAUDE_STUDIO_BUDGET=6 node src/FourOlds_LiftPegGrave.res.mjs */
let path = Cinema_Backends.Path(
  "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/draft/engine_peg_grave.scene.txt",
)

let main = async () => {
  try {
    let sc = await Write.liftDialogue(~path, ~maxTries=4)
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
