/* ACT 2 #6 — THE MANDATE (2026-07-02). The receiving end of Kemp's phone call:
   the airport ops center is being BORN as a command post (folding tables,
   agencies arriving, the track thrown up on the big screen) and REYES enters
   the film - introduced properly, WITH a mandate, before she ever works a
   witness. MERCER (the SAC, her boss here and in R1/R2) gives her the night's
   two jobs: find out who he is, and get him on the ground - and when she asks
   what she's authorized to put on the table, the answer that isn't an answer
   licenses everything: "whatever gets him down." THE LIE IS NEVER NAMED - the
   license lives in what Mercer won't say (no paper, no numbers, no answer).
   NO VILLAIN: Mercer is a man building a response with no good options and a
   clock, not a heavy. Sourced facts only (Kemp's call + the fighters from the
   keep scene, now on the board). Ends on Reyes watching the green track loop -
   the woman told to say anything, looking at the blip she'll have to say it to.
   Engine-written. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-mandate.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-mandate",
  slug: "INT. AIRPORT OPERATIONS CENTER - COMMAND POST - NIGHT",
  logline: "The airport's operations center is turning into a command post around the people setting it up - folding tables going out, screens coming alive, badges from four agencies walking in with coffee and go-bags - and in the middle of it Reyes gets the night handed to her: an airliner is up with one unidentified man flying it, two fighters are already on his wing, and her boss needs him on the ground. When she asks the professional question - what am I authorized to offer him - the answer she gets back isn't an answer, and both of them know exactly what that makes it.",
  cast: [
    {
      name: "REYES",
      who: "FBI, forties, a crisis negotiator by training - arrives dressed and quick with a bag over her shoulder, pulled out of the tail end of a normal night; the agent who gets handed the impossible-people jobs. Sharp, decent, tired in the eyes. She wants the facts and her authority defined, because that's how this is done properly - and she watches the second one get refused in a way that tells her exactly what the job really is. Her introduction in the film.",
      register: "professional, quick, human; asks precise questions; the trained calm under it; when the answer doesn't come, she doesn't perform outrage - she just registers it and carries it.",
      earnsEloquence: false,
      lexicon: "the table, authority, paper, who am I talking to, said flat and precise.",
    },
    {
      name: "MERCER",
      who: "the special agent in charge, fifties, running the room as it's born - jacket off, sleeves rolled, a phone in one hand most of the scene; a man assembling a multi-agency response around a total absence of facts, with a clock made of fuel. NOT a villain: he gives Reyes the license the only way institutions give it - by refusing to define it - because an undefined promise is the only card the machine has tonight, and defining it would make it his.",
      register: "flat, fast, economical; walks while he talks; answers what serves the response and goes silent past the edge of it; the refusal delivered as procedure, never as menace.",
      earnsEloquence: false,
      lexicon: "the ground, the room, the bridge line, what gets him down, said flat.",
    },
  ],
  layer: {
    peshat: "as the command post spins up, an FBI negotiator is given the job of talking the pilot down and told, in so many unwords, that she can promise anything",
    sod: "the machine's love language is authorization, and tonight it authorizes a blank - the license to lie is never spoken because speaking it would make someone own it; Mercer hands Reyes an undefined promise precisely so that whatever she says up there belongs to her and not to the institution - the oldest trick the machine plays on its own decent people; and Reyes takes the job knowing, because the alternative is leaving the gentle unknown man to the fighters on his wing; the woman who will spend the film trying to make one true promise enters it being handed a false one; nobody in the room knows the man on the track is the gentlest voice of the night - here he is a category, and the room is built to land a category",
  },
  beats: [
    {
      who: "MERCER",
      want: "the response assembled NOW - screens up, agencies seated, the human side covered",
      wall: "the room is half-born (folding tables, cables being taped down, badges arriving confused) and the facts are almost nothing: one aircraft, one voice, no name, no motive - and a fuel clock nobody can read",
      turn: "the big screen comes alive with the track looping over the water and the two fighter tags sitting on it - the night gets a face - and Mercer's hole is obvious: he has nobody to work the MAN; Reyes comes through the door with a bag on her shoulder",
      subtext: "the machine assembling itself around an absence; the category (unknown intent) standing in for a man; the audience knowing the gentle voice the room has never heard",
    },
    {
      who: "REYES",
      want: "the brief - the facts, and her authority defined: what can she put on the table",
      wall: "the facts run out in one breath (an airliner, one unidentified man flying it, says it isn't his, two fighters on the wing) - and on authority, Mercer gives her nothing: no paper, no numbers, no definition",
      turn: "she asks it straight - what am I authorized to offer him - and the answer is 'whatever gets him down'; she asks if there's paper behind anything she says, and the answer is her name and the first job again; the license lands exactly by not landing",
      subtext: "the professional question refused in the institutional way; the blank check that makes the lie hers alone; both of them understanding it completely and neither saying it; no villain - a machine with one card",
    },
    {
      who: "REYES",
      want: "(taking it anyway) a place to start",
      wall: "there is no name, no file, no family, nothing - the man is a hole in the middle of the night",
      turn: "Mercer gives her the two jobs in order - find out who he is, then get him down - and points her at the airline's people being brought in (the ramp boss, a witness); Reyes stands a beat looking up at the green track making its slow loop, the two fast tags riding it, and the room roars quietly around her; end there, on her watching it",
      subtext: "the two jobs that launch her next two scenes; the woman told to say anything, looking at the blip she'll have to say it to; unresolved, no button",
    },
  ],
  rules: [
    "INTRODUCE both characters on first appearance per the law: REYES (FBI, forties, dressed and quick, a bag over her shoulder, pulled from the tail end of a normal night - the crisis negotiator they hand the impossible-people jobs) and MERCER (the special agent in charge, fifties, jacket off, sleeves rolled, phone in hand, running the room as it's born). A listener must place both voices immediately.",
    "THE LIE IS NEVER NAMED: nobody says lie, bluff, false, or 'even if it isn't true.' The license lives in the SHAPE of the exchange - her precise question ('what am I authorized to offer him' / 'is there paper behind it'), his non-answer ('whatever gets him down' / her name and the job again), and the silence after it. Both understand; neither says; the audience gets it whole. If a line names the lie, cut it.",
    "NO VILLAIN: Mercer is pragmatic, pressured, and institutionally honest - the refusal is procedure, not menace; he never sneers, never monologues, never enjoys it. The system stays honest about itself.",
    "SOURCED FACTS ONLY: the room knows exactly what entered it - Kemp's call (an airline turboprop off Sea-Tac, empty, one man flying it, unidentified, says it isn't his) and the fighters (two tags on the board, from the military response already up). NO name, NO 'ground worker/employee' guess, NO motive. Mercer's brief must include what they don't know. The two jobs: find out who he is FIRST, then get him down - which launches the ground scene.",
    "ACTION LINES ARE FULL SENTENCES, PRESENT TENSE. ORIENT every voice - the physical move before the speaker. The scene must play EARS-ONLY.",
    "THE SECOND CHANNEL is the room being BORN: folding tables carried past, cables taped down, screens waking one by one, the big track looping up on the wall with two fast tags on it, badges and go-bags arriving, phones starting to ring and not stopping, Mercer's own phone at his ear between lines. Keep cutting to it; the room's assembly runs under the whole conversation.",
    "LEGIBILITY: plain words; the only quasi-jargon allowed is 'unknown intent' (once, self-evident) and 'the bridge line' if grounded in its own sentence. Everything else civilian-plain.",
    "REAL PROS ARE REDUNDANT AND PLAIN: no ticking-clock lines, no crisp end-weighted quips, no machine-gun exchanges; Mercer walks and talks in flat pieces; Reyes's questions are precise but human, and she gets at least one baggy, ordinary line.",
    "DRAMATIC IRONY STAYS COLD: the room talks about a category (the aircraft, the individual, unknown intent) while the audience knows the gentle voice; NOBODY in the room editorializes about him; no one wonders aloud what kind of person he is. The gap does the work.",
    "END FAST and unresolved: Reyes looking up at the green track looping with the two fast tags riding it, the room roaring quietly around her. No button, nobody comments, no summary line.",
    "Kill every catalog tell: doubled openers, engineered refrains, appended-fact fragments, list drumbeats, cross-character mirroring, summarizing Lines, thematic telegraphing, stated/implied turns, manufactured stammers, parallel restatement. American vernacular. Recorded, not written.",
    "Voice-differentiate: REYES (precise, human, trained-calm), MERCER (flat, fast, walking, procedural).",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=5)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: THE MANDATE (Reyes enters; the licensed blank) ===\n")
    Js.log(Cinema_Backends.readText(out))
    Js.log("\n=== VERIFY (expect PENDING until lift) ===")
    switch Write.verify(out) {
    | Ok() => Js.log("VERIFY OK")
    | Error(m) => Js.log("VERIFY: " ++ m)
    }
  } catch {
  | Write.WriteError(m) => Js.log("WRITE FAILED (gate):\n" ++ m)
  | Session.SessionError(m) => Js.log("SESSION: " ++ m)
  }
  Session.close()
}

main()->ignore
