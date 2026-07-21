/* KUKU picture-book PROTOTYPE — narration lines for two sample spreads, generated
   by the engine from the RECEIPTED Ep1 scenes (s0 + s1). Honest note: the book
   pipeline has no receipt machinery yet (writeScene is screenplay-shaped); this
   driver uses the warm Session directly, budget-capped, sources = verified scenes.
   Building real book receipts is future work if the book becomes a product.

   Run from studio/: CLAUDE_STUDIO_BUDGET=3 node src/Kuku_BookProto.res.mjs
*/

@val @scope("process") external cwd: unit => string = "cwd"

let dir = cwd() ++ "/../stories/kuku/ep1"

let main = async () => {
  let s0 = Cinema_Backends.readText(Cinema_Backends.Path(dir ++ "/ep1-s0-teaser.scene.txt"))
  let s1 = Cinema_Backends.readText(Cinema_Backends.Path(dir ++ "/ep1-s1-akshar.scene.txt"))
  let prompt =
    "You are adapting a children's TV episode into a Hindi PICTURE BOOK for kids aged four to seven learning Hindi. Below are two ENGINE-CANON scenes (English action, Devanagari dialogue).\n\n" ++
    "=== SCENE A (the garden: Kuku plays dog, wants a real dog) ===\n" ++ s0 ++
    "\n=== SCENE B (Dadi reveals today's letter क on her rock) ===\n" ++ s1 ++
    "\n\nWrite EXACTLY 4 numbered picture-book narration lines in Hindi (Devanagari), storybook narrator voice:\n" ++
    "1. and 2. = two lines for the page showing Kuku playing dog in the garden (his paper ears, his wish for a real dog).\n" ++
    "3. and 4. = two lines for the page showing Dadi Maya revealing the glowing letter on her rock.\n" ++
    "HARD RULES: every line is a COMPLETE, grammatically correct, simple Hindi sentence of at most 12 words; warm storybook register; no fragments; no English; standard Devanagari; you may quote one short dialogue line from the scenes inside a line. Output ONLY the 4 numbered lines, nothing else."
  try {
    let out = await Session.ask(prompt)
    Js.log("=== BOOK PROTO LINES (engine) ===")
    Js.log(out)
  } catch {
  | Session.SessionError(m) => Js.log("SESSION: " ++ m)
  }
  Session.close()
}
main()->ignore
