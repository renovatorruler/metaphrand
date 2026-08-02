/* KUKU Ep1 — surgical register + spelling re-lift (author, 2026-07-22): among the kids
   and to the dog, तू/तेरा → तुम/तुम्हारा; and फूरिया → फ्यूरिया. Nothing else changes.
   Through the engine so every receipt stays valid.

   Native worker run: follow studio/NATIVE_WORKERS.md with this driver.
*/

@val @scope("process") external cwd: unit => string = "cwd"

let dir = cwd() ++ "/../stories/kuku/ep1"

let ids = [
  "ep1-s0-teaser", "ep1-s1-akshar", "ep1-s2-pilla", "ep1-s3-chhupam",
  "ep1-s4-bachaav", "ep1-s5-kalu-ghar", "ep1-s6-topi",
]

let notes = `Two surgical corrections from the author, applied to EVERY dialogue line where they occur, and NOTHING else may change (same events, same order, same meaning, same character voices):

1. PRONOUN REGISTER: the kids (Kuku, Furia, Vesper) and anyone speaking to the puppy Kalu use the informal तू/तेरा too roughly. Change the तू-family to the तुम-family everywhere it appears in dialogue, with correct verb agreement: तू → तुम, तुझे → तुम्हें, तुझको → तुमको, तेरा/तेरे/तेरी → तुम्हारा/तुम्हारे/तुम्हारी, तूने → तुमने, तुझसे → तुमसे. Fix the verb ending to agree with तुम (e.g. "तू बस थोड़ा रुक" → "तुम बस थोड़ा रुको"; "अब तू मेरे ही पास रहेगा" → "अब तुम मेरे ही पास रहोगे"; "तूने खाया ही नहीं" → "तुमने खाया ही नहीं"). Keep आप wherever a child already addresses an elder. Papa and Dadi's lines toward children also use तुम, never तू.

2. NAME SPELLING: the name फूरिया is misspelled; the correct spelling is फ्यूरिया. Change every फूरिया (and फ़ूरिया if present) to फ्यूरिया.

Do not reword, shorten, enrich, or re-voice any line. Do not touch the letter क, the क words, the English action lines, or Vesper's marked English drifts. Only the pronoun forms and the name spelling change.`

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

let rec run = async i =>
  switch Belt.Array.get(ids, i) {
  | None => ()
  | Some(id) => {
      await liftOne(id)
      await run(i + 1)
    }
  }

let main = async () => {
  await run(0)
  Js.log("=== done, " ++ Belt.Int.toString(Session.callsMade()) ++ " calls ===")
  Session.close()
}
main()->ignore
