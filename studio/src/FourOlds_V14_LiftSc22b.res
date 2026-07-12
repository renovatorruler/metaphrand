/* One corrective lift: restore the approved canon line in sc22b.
   Run: CLAUDE_STUDIO_BUDGET=6 node src/FourOlds_V14_LiftSc22b.res.mjs */
let path = Cinema_Backends.Path(
  "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/v14/sc22b_tradecraft.scene.txt",
)

let notes = "ONE required fix, nothing else: Gunny's answer to Joss's 'That's insane. That's — that's Revolutionary War stuff.' must be the approved canon line, verbatim: 'They've got every algorithm ever written. We've got Valley Forge.' Replace the current 'They've got their computers. Never stopped a letter yet.' with it. Change no other line."

let main = async () => {
  try {
    let sc = await Write.liftDialogue(~path, ~notes, ~maxTries=3)
    let _ = Write.emit(sc, ~txt=path)
    switch Write.verify(path) {
    | Ok() => Js.log("OK sc22b relifted")
    | Error(m) => Js.log("BAD: " ++ m)
    }
  } catch {
  | Write.WriteError(m) => Js.log("LIFT FAILED: " ++ m)
  | Session.SessionError(m) => Js.log("SESSION: " ++ m)
  }
  Session.close()
}
main()->ignore
