/* KUKU Ep1 — the PROPER-HINDI re-lift (author's laws 2a/2b, 2026-07-21) plus the
   rights-critical radio replacements from EP1_AI_AUDIT_v1.md (H1). All seven
   scenes, one warm session, receipts kept valid.

   Run from inside studio/:
     CLAUDE_STUDIO_BUDGET=20 node src/Kuku_ReliftProper.res.mjs
*/

@val @scope("process") external cwd: unit => string = "cwd"

let dir = cwd() ++ "/../stories/kuku/ep1"

let ids = [
  "ep1-s0-teaser",
  "ep1-s1-akshar",
  "ep1-s2-pilla",
  "ep1-s3-chhupam",
  "ep1-s4-bachaav",
  "ep1-s5-kalu-ghar",
  "ep1-s6-topi",
]

let notes = `THE AUTHOR'S DIRECTOR NOTES — every note MUST be addressed. This show teaches his children Hindi; they absorb the SYNTAX of every line, so the language itself is the product.

1. COMPLETE SENTENCES (highest priority). Rewrite every dialogue line that is a chopped staccato fragment into a complete, grammatically correct, natural Hindi sentence. Short and simple is right; broken is not. The author's own model correction, follow its shape exactly: the line "पापा, पापा, देखो. मेरा कुत्ता, काला वाला. तुम एक कुत्ता ले आओ ना, घर में. मेरे लिए." must become "पापा, पापा, देखो वो काला कुत्ता. आप एक कुत्ता मेरे लिए घर ले आओ ना." Likewise "काला कुत्ता. मैंने बनाया." must become a full sentence such as "देखो, मैंने काला कुत्ता बनाया है." Apply this shape to EVERY fragmented dialogue line in the scene. Warm colloquial Hindi, not stiff formal Hindi. Exceptions allowed: the toddler CHEEKU's one-word babble, and the single letter क in call-and-response.

2. PRONOUN REGISTER. Children address elders with आप, never तुम and never तू: Kuku to PAPA and to DADI MAYA, Furia and Vesper to PAPA and to DADI MAYA. (आप with a warm imperative like ले आओ ना is correct house register.) Elders keep तू/तुम toward children. The children keep तू among themselves and toward the puppy Kalu. Fix every violation.

3. RADIO LINES (rights). Replace these radio lines with ORIGINAL lines in the same mood, copying no existing song: (a) the line beginning "आजा रे परदेसी" is verbatim from a real film song and MUST be replaced with an original old-film-style line; (b) the evening line beginning "शाम ढल रही है, कागा" must be replaced with an original evening line; (c) the lullaby line beginning "सो जा तारे, सो जा चंदा" must be replaced with lines from the show's own lullaby: "अक्षर घाटी सो गई है, तारे जले हैं ऊपर..." Radio lines not listed here stay.

4. PROTECTED — keep these exactly as they are (spelling and all): मैं पहले!, हिंदी में, वैस्पर!, कुत्ता केला नहीं खाता, साँस, टोपी, अक्षर, आज का अक्षर है क, हिंदी का हर अक्षर टोपी पहनता है, शुभ रात्रि, वैस्पर, तू कर, कुकु. आज तू पहले., Vesper's English drift lines (his device), all क-word call-and-response, and Furia's whisper मैंने तो पहले ही देख ली थी, सच में. When a protected line is itself a fragment, it stays a fragment.

5. Do not add sophistication, subtext, or new content; do not change the story, the staging, or the English action lines except where a note requires it. Every changed line stays short, warm, learnable.`

let liftOne = async id => {
  let path = Cinema_Backends.Path(dir ++ "/" ++ id ++ ".scene.txt")
  try {
    let sc = await Write.liftDialogue(~path, ~notes, ~maxTries=4)
    let _ = Write.emit(sc, ~txt=path)
    switch Write.verify(path) {
    | Ok() => {
        Js.log("== OK " ++ id)
        true
      }
    | Error(m) => {
        Js.log("== VERIFY FAILED " ++ id ++ ": " ++ m)
        false
      }
    }
  } catch {
  | Write.WriteError(m) => {
      Js.log("== FAILED " ++ id ++ ": " ++ m)
      false
    }
  | Session.SessionError(m) => {
      Js.log("== FAILED " ++ id ++ " (session): " ++ m)
      false
    }
  }
}

let rec run = async (i, ok) =>
  switch Belt.Array.get(ids, i) {
  | None => ok
  | Some(id) => {
      let r = await liftOne(id)
      await run(i + 1, r ? ok + 1 : ok)
    }
  }

let main = async () => {
  let ok = await run(0, 0)
  Js.log("=== " ++ Belt.Int.toString(ok) ++ "/7 proper-Hindi lifted, " ++ Belt.Int.toString(Session.callsMade()) ++ " calls ===")
  Session.close()
}
main()->ignore
