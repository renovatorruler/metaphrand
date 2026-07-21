/* KUKU aur AKSHAR — the DIALOGUE LIFT pass. writeScene emits a scene stamped
   PENDING; verify/render REFUSE a PENDING scene, so this pass is mandatory.

   IMPORTANT: the default dialogue doctrine pushes lines toward adult subtext and
   sophistication. This is a PRESCHOOL teaching show — we want the opposite. So we
   hand the lift baked director's notes that PROTECT the simple, repetitive register.

   Run from inside studio/:
     CLAUDE_STUDIO_BUDGET=6 node src/Kuku_Lift.res.mjs           # defaults to kuku-ep1-k
     CLAUDE_STUDIO_BUDGET=6 node src/Kuku_Lift.res.mjs <scene-id>
*/

@val @scope("process") external cwd: unit => string = "cwd"
@val @scope("process") external argv: array<string> = "argv"

let dir = cwd() ++ "/../stories/kuku"

let preschoolNotes = `This is a PRESCHOOL Hindi teaching show for children aged three to five learning Hindi from scratch, in the spirit of Sesame Street. Do NOT add subtext, irony, cleverness, or adult sophistication to any line. Keep every dialogue line extremely simple: short, present tense, only the most common spoken-Hindi words a small child knows. Heavy repetition and call-and-response is REQUIRED, not a flaw. Keep the letter क and the word कुकु recurring, and keep the closing beat 'कुकु का क'. Keep the English action lines as action; all dialogue stays in standard Devanagari. Nothing scary, no villain, no shaming Kuku.`

let main = async () => {
  let id = Belt.Array.get(argv, 2)->Belt.Option.getWithDefault("ep1-k")
  let path = Cinema_Backends.Path(dir ++ "/" ++ id ++ ".scene.txt")
  if !Cinema_Backends.exists(path) {
    Js.log("no scene file at " ++ dir ++ "/" ++ id ++ ".scene.txt — run Kuku_WriteEp1 first")
  } else {
  try {
    let sc = await Write.liftDialogue(~path, ~notes=preschoolNotes, ~maxTries=4)
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
