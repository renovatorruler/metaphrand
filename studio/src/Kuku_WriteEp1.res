/* KUKU aur AKSHAR — Episode 1 (letter क), STORY scene, written by the ENGINE from
   a seed I author. I supply structure only — wants, walls, turns, voice cards, the
   buried layer, the rules. The warm Session writes the sentences (English action,
   Devanagari dialogue); the gate judges them; emit leaves a receipt. Nothing here
   is a line of dialogue or action typed by me.

   Run from inside studio/ (path is computed from process.cwd(), not hardcoded):
     npm run build && CLAUDE_STUDIO_BUDGET=12 node src/Kuku_WriteEp1.res.mjs
   Zero-spend structural smoke:
     CLAUDE_STUDIO_BIN="$(pwd)/scripts/fake-claude.mjs" CLAUDE_STUDIO_BUDGET=5 \
       node src/Kuku_WriteEp1.res.mjs
*/

@val @scope("process") external cwd: unit => string = "cwd"

let outPath = cwd() ++ "/../stories/kuku/ep1-k.scene.txt"

let seed: Seed.sceneSeed = {
  id: "kuku-ep1-k",
  slug: "EXT. AKSHAR GHAATI (LETTER VALLEY) - MORNING",
  logline: "The littlest dragon cannot light Grandmother's lamp with fire like the big dragons do; encouraged to breathe what he loves instead, he breathes a glowing letter क into the sky, and the valley discovers his failure is a gift.",
  cast: [
    {
      name: "KUKU",
      who: "the littlest dragon, about four, eager and warm; he breathes glowing letters instead of fire and does not yet know it is wonderful",
      register: "the simplest preschool Hindi: two to five words, present tense, first-words vocabulary only; all feeling on the surface, delight and a quick sadness and delight again; sometimes says his own name",
      earnsEloquence: false,
      lexicon: "the world of a small child: माँ, दोस्त, आग, देखो, फिर से, मेरा",
    },
    {
      name: "DADI MAYA",
      who: "the grandmother dragon, warm and patient and playful, the one who guides Kuku without pitying or fixing him",
      register: "short, clear, warm Hindi; gentle imperatives; never stern, never disappointed; repeats a child's answer back to reward it",
      earnsEloquence: false,
      lexicon: "warmth and encouragement: शाबाश, फिर से कोशिश कर, बहुत अच्छा",
    },
    {
      name: "CHEEKU",
      who: "Kuku's tiny fast best friend, giggly, all fun and no forethought; the one who begs for things to happen again",
      register: "the tiniest fastest Hindi; fragments and repeats; giggles; loves फिर से and मज़ा; never cruel",
      earnsEloquence: false,
    },
  ],
  layer: {
    peshat: "a baby dragon tries to light his grandmother's morning lamp, cannot make fire, and instead breathes a glowing letter क that delights everyone and lights the room",
    sod: "your difference is not a lack, it is your gift; and learning comes out of you the moment you are brave enough to try again",
  },
  beats: [
    {
      who: "KUKU",
      want: "to light Dadi's morning lamp with fire, like the big dragons do",
      wall: "no flame comes when he breathes, only a puff of smoke, and Cheeku giggles",
      turn: "he deflates and says he cannot make fire",
    },
    {
      who: "DADI MAYA",
      want: "to lift Kuku without pitying him or calling him broken",
      wall: "he believes he is a failed dragon",
      turn: "she tells him not to chase fire but to breathe what he loves, and try one more time",
    },
    {
      who: "KUKU",
      want: "to try one last time even though he is afraid to fail again",
      wall: "his fear that the same nothing will come out",
      turn: "he takes a huge breath, thinks of his friends, and a glowing letter क floats up into the sky - not fire, something new",
    },
    {
      who: "KUKU",
      want: "everyone to see the wonderful thing he made",
      wall: "no one has ever seen a dragon breathe a letter",
      turn: "Dadi names it - an अक्षर, क - and क is in Kuku's own name; the glowing क lights the room like a little lamp, and Cheeku begs to see it again",
    },
  ],
  rules: [
    "AUDIENCE: children aged three to five learning Hindi from scratch. This is a warm preschool show in the spirit of Sesame Street.",
    "English sluglines and English action lines; ALL dialogue in Devanagari (Hindi), standard characters only.",
    "PRESCHOOL register: dialogue must be extremely simple - short present-tense sentences, only the most common spoken-Hindi words a small child knows.",
    "Heavy, INTENTIONAL repetition and call-and-response is REQUIRED, not a flaw - it is how preschoolers learn. Repeat the letter क and the word कुकु.",
    "The little dragons address each other with तू or तुम; Dadi is warm and grandmotherly, never stern.",
    "No irony, no subtext on the surface, no sophistication, nothing scary, no villain; Kuku's failure is gentle and brief and turns into wonder.",
    "One line per paragraph. No em-dashes and no emoji in the dialogue.",
    "End the scene on the beat 'कुकु का क' - the valley celebrating the letter that is Kuku's own.",
    "Keep it short, a single preschool scene of a few exchanges.",
    "Never state the buried theme; no one says difference, gift, failure, or brave; it lives only in what happens.",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=3)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE THE SCENE (not me) ===\n")
    Js.log(Cinema_Backends.readText(out))
    Js.log("\n=== RECEIPT ===")
    Js.log(Cinema_Backends.readText(Cinema_Backends.Path(outPath ++ ".receipt.json")))
    Js.log("\n=== VERIFY (engine's own output) ===")
    switch Write.verify(out) {
    | Ok() => Js.log("VERIFY OK")
    | Error(m) => Js.log("VERIFY FAILED - " ++ m)
    }
  } catch {
  | Write.WriteError(m) => Js.log("WRITE FAILED (gate never satisfied in maxTries):\n" ++ m)
  | Session.SessionError(m) => Js.log("SESSION: " ++ m)
  }
  Session.close()
}

main()->ignore
