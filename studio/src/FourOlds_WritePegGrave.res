/* THE FOUR OLDS — Peg's grave. Establishes she's gone before the story started
   (widower Cricket, not a scene that dramatizes her death) and plants the one
   thing she said that the ending pays off without ever naming her again: real
   kindness doesn't need an audience, performed kindness is always selling
   something. Engine-written. */

let outPath = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/draft/engine_peg_grave.scene.txt"

let seed: Seed.sceneSeed = {
  id: "four-olds-peg-grave",
  slug: "EXT. COUNTY CEMETERY - DAY",
  logline: "Cricket and Dutch at Peg's grave, plain flowers, almost no conversation — until Cricket says the one true thing he came to say: she never trusted Marwani, not for one day, despite being the kindest woman anyone knew. Dutch's only job is to ask the one small factual question that lets him finish the thought without either man having to admit they're having a feeling.",
  cast: [
    {
      name: "CRICKET",
      who: "widower, checklist-grammar, deflects feelings into operational facts. Has never once given a speech about his wife and isn't about to start now — what he says here is stated, not performed, the same register he'd use to read an instrument.",
      register: "spare, plain, a handful of words at most per line. States a fact and stops. Does not editorialize on his own feelings.",
      earnsEloquence: false,
      lexicon: "plain, factual, no metaphor.",
    },
    {
      name: "DUTCH",
      who: "specification grammar, distrusts adjectives, has never once in his life offered comfort through emotional language. His way of being present for a grieving friend is to ask a plain factual question, because that is the only language he has for anything, including this.",
      register: "short, direct, conditions-and-facts. Never a hedge, never a soft word.",
      earnsEloquence: false,
      lexicon: "plain, procedural, applied here to a subject it was never built for.",
    },
  ],
  layer: {
    peshat: "two old friends stand at a grave, one of them says a few plain sentences about his late wife",
    sod: "Cricket is stating, without meaning to, exactly what kind of resistance runs in his family — Peg saw through Marwani's performed kindness years before any of this started, and everything the crew does for the rest of the film is the difference between what she recognized as fake and what real looks like, though nobody in this scene says any of that aloud",
  },
  beats: [
    {
      who: "CRICKET",
      want: "say the one true thing he came here to say about Peg, then stop",
      wall: "fifty years of never once discussing a feeling out loud, including with himself",
      turn: "he says it plainly, in a handful of sentences: she never trusted Marwani, not one day, despite being — by every account, including strangers' — an unusually kind woman; she looked at him on television once and had an immediate, plain read on him, stated the way a farm wife sizes up a traveling salesman, not the way a pundit talks",
      subtext: "he is not eulogizing her, he is reporting a fact, the same way he would read a gauge",
    },
    {
      who: "DUTCH",
      want: "be present and useful without forcing Cricket to perform grief",
      wall: "neither man has a language for this",
      turn: "he asks one small, factual, almost procedural question that gives Cricket room to finish the thought without either of them acknowledging they are having an emotional conversation",
      subtext: "this is the only kind of comfort Dutch knows how to offer — treat the grief like a spec question, because that's the one language he trusts",
    },
  ],
  rules: [
    "RUTHLESSLY SHORT — four to eight lines of dialogue total. This is not a eulogy and must never read like one. If a line starts to sound written for the occasion, cut it.",
    "NEVER state a theme aloud. Cricket does not explain what Peg's insight means for the mission, does not connect it to Marwani's politics explicitly beyond the one plain fact of her distrust, does not connect it to anything ahead in the story. He says what she said and what happened, full stop. The audience makes every connection, not the characters.",
    "The core content, exactly: Peg never trusted Marwani, not for one day, despite being an unusually kind woman by every account. She had an immediate, plain read on him from a single television appearance — something in the register of a farm wife sizing up a traveling salesman (he's selling something), never in the register of a pundit or a political argument. This is not phrased as a political opinion; it is phrased as the same kind of plain judgment she'd make about a stranger at the door.",
    "Cricket's line should sound like something he has said maybe twice before in his life, not a performance built for this moment. Dutch's question is small, factual, almost clinical — that is the whole of his comfort, and it is enough.",
    "Kill every AI-writing tell: em-dash overuse, rule-of-three, negative parallelism, corrective-definition ('that's not X, that's Y'), cute conceits or metaphors performing cleverness, inflated vocabulary, ironic narrator asides.",
    "Concrete and plain: the flowers are not roses, something inexpensive and true to an actual farm wife's own garden (zinnias, black-eyed susans, something like that) — not a florist arrangement. The cemetery is small, unpretentious, a real county cemetery, not scenic.",
    "Fountain screenplay format: a slugline, plain action lines describing only what a camera would see, colon-terminated CHARACTER NAME: dialogue cues (this project's standing convention).",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=5)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: PEG'S GRAVE ===\n")
    Js.log(Cinema_Backends.readText(out))
  } catch {
  | Write.WriteError(m) => Js.log("WRITE FAILED (gate):\n" ++ m)
  | Session.SessionError(m) => Js.log("SESSION: " ++ m)
  }
  Session.close()
}
main()->ignore
