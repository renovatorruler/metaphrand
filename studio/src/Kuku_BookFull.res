/* KUKU picture book — FULL text pass. All 7 receipted Ep1 scenes in, the complete
   14-spread book text out (Hindi, storybook register, laws 2a/2b). Session-driven,
   budget-capped; source = verified scenes. Receipted-book machinery = future work.

   Run from studio/: CLAUDE_STUDIO_BUDGET=6 node src/Kuku_BookFull.res.mjs
*/

@val @scope("process") external cwd: unit => string = "cwd"

let dir = cwd() ++ "/../stories/kuku/ep1"

let ids = [
  "ep1-s0-teaser", "ep1-s1-akshar", "ep1-s2-pilla", "ep1-s3-chhupam",
  "ep1-s4-bachaav", "ep1-s5-kalu-ghar", "ep1-s6-topi",
]

let spreads = `1. Kuku plays dog in the garden with paper ears (his wish: a real dog)
2. Kuku shows Papa his drawing; Papa says no, a dog is much work
3. At Dadi Maya's rock: the golden letter क is revealed, wearing its टोपी
4. The hat lesson: every Hindi letter wears a टोपी; the children trace it in the air
5. The letter hunt; dreamy Vesper alone hears a tiny crying sound
6. The muddy black puppy stuck by the old well; Furia goes gentle
7. Kuku frees the puppy, names him कालू; the banana is refused (कुत्ता केला नहीं खाता!)
8. Hiding कालू from Papa: jumping, mud, crashing bowls, chaos
9. Papa almost discovers them; quiet doubt: maybe a dog IS much work
10. The walk; कालू chases a pigeon and slips into the old well's edge
11. Furia tries first and cannot reach; Vesper sees it: something like a hook, from above
12. The chant साँस, टोपी, अक्षर — the glowing क lifts कालू to safety
13. Papa saw everything: कालू तेरा है; the bowl, the blanket, the banana chorus
14. Under the stars: the day's क words; Furia writes क first; Vesper asleep around कालू; शुभ रात्रि`

let main = async () => {
  let src =
    ids
    ->Belt.Array.map(id =>
      "=== " ++ id ++ " ===\n" ++
      Cinema_Backends.readText(Cinema_Backends.Path(dir ++ "/" ++ id ++ ".scene.txt"))
    )
    ->Belt.Array.joinWith("\n\n", x => x)
  let prompt =
    "You are adapting a children's TV episode into a 32-page Hindi PICTURE BOOK for kids aged four to seven learning Hindi (letter of the day: क). Below are the SEVEN engine-canon scenes (English action, Devanagari dialogue).\n\n" ++
    src ++
    "\n\nWrite the text for EXACTLY 14 spreads following this plan:\n" ++ spreads ++
    "\n\nFORMAT: for each spread output a block:\n[N]\n<line>\n<line>\n(2 or 3 lines per spread)\n\nHARD RULES: every line is a COMPLETE, grammatically correct, simple Hindi sentence of at most 12 words, in warm storybook narrator voice (past tense narration); you may include ONE short quoted dialogue line per spread taken from the scenes (keep quotes verbatim where possible, e.g. \"कुत्ता केला नहीं खाता!\", \"साँस... टोपी... अक्षर!\", \"कालू तेरा है, कुकु.\", \"शुभ रात्रि, वैस्पर.\"); children address elders as आप; no fragments; no English; standard Devanagari with दंड (।) at sentence ends; repeat the letter क and its words (कुत्ता, कालू, काला, कान, कुआँ, कीचड़, कटोरा, कंबल, केला) naturally and often. Output ONLY the 14 blocks, nothing else."
  try {
    let out = await Session.ask(prompt)
    let outPath = Cinema_Backends.Path(cwd() ++ "/../stories/kuku/book/book_text_v1.txt")
    Cinema_Backends.writeText(outPath, out)
    Js.log("=== BOOK TEXT written to stories/kuku/book/book_text_v1.txt ===")
    Js.log(out)
  } catch {
  | Session.SessionError(m) => Js.log("SESSION: " ++ m)
  }
  Session.close()
}
main()->ignore
