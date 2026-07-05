/* SKY KING — the DIALOGUE LIFT pass. Raises an emitted scene to the doctrine
   (DIALOGUE_DOCTRINE.md): subtext / tactic / lexicon / earned truth, re-gates on
   the Craft floor, and stamps it LIFTED so it can be produced. A scene that has
   NOT been lifted is refused at the render door (verify fails).
   Run: CLAUDE_STUDIO_BUDGET=4 node src/SkyKing_Lift.res.mjs <scene-id> */
let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"

@val @scope("process") external argv: array<string> = "argv"

let main = async () => {
  let id = Belt.Array.get(argv, 2)->Belt.Option.getWithDefault("")
  if id == "" {
    Js.log("usage: node src/SkyKing_Lift.res.mjs <scene-id> [notes-file]")
  } else {
    let path = Cinema_Backends.Path(dir ++ "/" ++ id ++ ".scene.txt")
    let notes = switch Belt.Array.get(argv, 3) {
    | Some(nf) if nf != "" => Some(Cinema_Backends.readText(Cinema_Backends.Path(nf)))
    | _ => None
    }
    try {
      let sc = await Write.liftDialogue(~path, ~notes?, ~maxTries=4)
      let _ = Write.emit(sc, ~txt=path)
      Js.log("=== LIFTED: " ++ id ++ " ===\n")
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
  }
  Session.close()
}
main()->ignore
