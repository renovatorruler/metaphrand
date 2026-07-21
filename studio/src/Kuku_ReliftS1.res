/* KUKU Ep1 — targeted re-lift of scene s1-akshar to address two director's
   line-notes from the author (2026-07-21). Goes through liftDialogue so the
   receipt chain stays intact; hand-editing the scene file would fail verify.

   Run from inside studio/:
     CLAUDE_STUDIO_BUDGET=5 node src/Kuku_ReliftS1.res.mjs
*/

@val @scope("process") external cwd: unit => string = "cwd"

let path = Cinema_Backends.Path(cwd() ++ "/../stories/kuku/ep1/ep1-s1-akshar.scene.txt")

let notes = `Address exactly these two director's line-notes and change NOTHING else in the scene:
1. Furia's line "वैस्पर! दीदी तुझे बुला रही है." is wrong: it is the GRANDMOTHER (दादी) calling him, not an older sister (दीदी). Change दीदी to दादी so the line reads: वैस्पर! दादी तुझे बुला रही है.
2. Furia's line "अरे रुको! ये तो मेरा अक्षर है, अंग्रेज़ी वाला, मेरे नाम का. मैं तो इसको पहले से जानती हूँ!" must not call her letter अंग्रेज़ी वाला (her own letter is NOT English). Remove that word so the sense is simply "my letter, the one my name starts with", e.g.: अरे रुको! ये तो मेरा अक्षर है, मेरे नाम वाला. मैं तो इसको पहले से जानती हूँ!
Every other line stays exactly as it is. Keep the register: simple, learnable kids' Hindi.`

let main = async () => {
  try {
    let sc = await Write.liftDialogue(~path, ~notes, ~maxTries=3)
    let _ = Write.emit(sc, ~txt=path)
    switch Write.verify(path) {
    | Ok() => Js.log("RELIFT OK, VERIFY OK")
    | Error(m) => Js.log("VERIFY FAILED: " ++ m)
    }
  } catch {
  | Write.WriteError(m) => Js.log("RELIFT FAILED: " ++ m)
  | Session.SessionError(m) => Js.log("SESSION: " ++ m)
  }
  Session.close()
}
main()->ignore
