/* KUKU aur AKSHAR — Episode 2 batch DIALOGUE LIFT. Baked notes protect the show's
   register (adventure tier, simple learnable Hindi), the तुम register, the character-
   richness law (tics sparingly), and the fused mechanic / recurring lines.

   Native worker run after Kuku_WriteEp2: follow studio/NATIVE_WORKERS.md.
*/

@val @scope("process") external cwd: unit => string = "cwd"

let dir = cwd() ++ "/../stories/kuku/ep2"

let ids = [
  "ep2-s0-mela", "ep2-s1-chori", "ep2-s2-akshar", "ep2-s3-peecha",
  "ep2-s4-shakti", "ep2-s5-pehla-akshar", "ep2-s6-topi",
]

let notes = `This is a Hindi-teaching kids' ADVENTURE show (ages 4-7, Miniforce/Super-Kitties tier, letter म). PROTECT the register; do not sophisticate the Hindi. Rules for this lift:
(1) Keep every dialogue line a COMPLETE, grammatically correct, simple, learnable Hindi sentence; no adult subtext, no chopped fragments.
(2) PRONOUNS: kids and dog get तुम/तुम्हारा, never तू/तेरा; आप only to elders; elders say तुम to kids. Fix any तू that slipped in.
(3) CHARACTER RICHNESS: tics are seasoning. Furia's मैं पहले! appears at MOST once in the whole episode; Vesper's English-drift + हिंदी में वैस्पर appears at MOST once (in the letter-reveal scene). If either recurs, rewrite the extra occurrences into real character lines (Furia leading by heart; Vesper noticing/inventing). Furia = big-hearted helper-leader; Vesper = tender seer-inventor — write the person, not the catchphrase.
(4) KEEP these exact lines/beats where present: अक्षर वीर, तैयार!; साँस, टोपी, अक्षर; हम मदद करेंगे; मदद (Morni's cry); हिंदी का हर अक्षर टोपी पहनता है; जो बनाया जाता है, उसे कोई मिटा नहीं सकता; माया में म है; शुभ रात्रि.
(5) मिटासुर stays comic and sympathetic, never scary; his wound (I can only erase, never make; these letters are all I have) must read clearly and sadly-funny, and his first-made-म moment stays wondrous.
(6) Repetition of म and its words (माँ, मेला, मिठाई, मोर, मछली, मदद, माया) is REQUIRED; never trim it. English action lines stay action; all dialogue Devanagari except Vesper's one marked drift.
(7) You MAY make lines more alive and character-true; do not change the story, staging, or events.`

let liftOne = async id => {
  let path = Cinema_Backends.Path(dir ++ "/" ++ id ++ ".scene.txt")
  if !Cinema_Backends.exists(path) {
    Js.log("== SKIP " ++ id ++ " (no scene)")
    false
  } else {
    try {
      let sc = await Write.liftDialogue(~path, ~notes, ~maxTries=4)
      let _ = Write.emit(sc, ~txt=path)
      switch Write.verify(path) {
      | Ok() => { Js.log("== LIFTED+VERIFIED " ++ id); true }
      | Error(m) => { Js.log("== VERIFY FAILED " ++ id ++ ": " ++ m); false }
      }
    } catch {
    | Write.WriteError(m) => { Js.log("== LIFT FAILED " ++ id ++ ": " ++ m); false }
    | Session.SessionError(m) => { Js.log("== SESSION " ++ id ++ ": " ++ m); false }
    }
  }
}

let rec run = async (i, ok) =>
  switch Belt.Array.get(ids, i) {
  | None => ok
  | Some(id) => { let r = await liftOne(id); await run(i + 1, r ? ok + 1 : ok) }
  }

let main = async () => {
  let ok = await run(0, 0)
  Js.log("\n=== EP2 LIFT: " ++ Belt.Int.toString(ok) ++ "/7 production-ready, " ++ Belt.Int.toString(Session.callsMade()) ++ " calls ===")
  Session.close()
}
main()->ignore
