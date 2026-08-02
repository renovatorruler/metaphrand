/* KUKU Ep1 — author's register note (2026-07-21): PAPA addresses Kuku with तुम,
   never तू. Re-lift s0 + s5 converting ALL of Papa's address forms toward Kuku to
   तुम-forms (तेरा→तुम्हारा, तू→तुम, तूने→तुमने, imperatives to तुम-forms), nothing
   else changed. Receipts stay valid.

   Native worker run: follow studio/NATIVE_WORKERS.md with this driver.
*/

@val @scope("process") external cwd: unit => string = "cwd"

let dir = cwd() ++ "/../stories/kuku/ep1"

let ids = ["ep1-s0-teaser", "ep1-s5-kalu-ghar"]

let notes = `ONE register correction from the author, applied ONLY to lines spoken by PAPA, and NOTHING else may change: Papa addresses Kuku with तुम, never तू. Convert every तू-form in PAPA's dialogue lines to the correct तुम-form with matching verb agreement. Examples of the required changes: "कालू तेरा है, कुकु." must become "कालू तुम्हारा है, कुकु." ; "हाँ, वो तेरा ही है. अब अपने कुत्ते का ध्यान रखना, ये तेरा काम है." must become "हाँ, वो तुम्हारा ही है. अब अपने कुत्ते का ध्यान रखना, ये तुम्हारा काम है." ; "और तू अभी छोटा है" must become "और तुम अभी छोटे हो" ; "मैंने देखा, कुकु. तूने कैसे उठाया उसको ऊपर." must become "मैंने देखा, कुकु. तुमने कैसे उठाया उसको ऊपर." ; "बस, बेटा, रुक जा. इतना हाँफ मत" must become "बस, बेटा, रुको. इतना हाँफो मत". Do NOT change any line spoken by KUKU, FURIA, VESPER, DADI MAYA, CHEEKU, MUKHIYA, or RADIO. Do not change Kuku's तू toward the dog. Keep everything else word-for-word identical.`

let liftOne = async id => {
  let path = Cinema_Backends.Path(dir ++ "/" ++ id ++ ".scene.txt")
  try {
    let sc = await Write.liftDialogue(~path, ~notes, ~maxTries=3)
    let _ = Write.emit(sc, ~txt=path)
    switch Write.verify(path) {
    | Ok() => Js.log("== OK " ++ id)
    | Error(m) => Js.log("== VERIFY FAILED " ++ id ++ ": " ++ m)
    }
  } catch {
  | Write.WriteError(m) => Js.log("== FAILED " ++ id ++ ": " ++ m)
  | Session.SessionError(m) => Js.log("== SESSION " ++ id ++ ": " ++ m)
  }
}

let main = async () => {
  await liftOne(ids[0])
  await liftOne(ids[1])
  Js.log("=== done, " ++ Belt.Int.toString(Session.callsMade()) ++ " calls ===")
  Session.close()
}
main()->ignore
