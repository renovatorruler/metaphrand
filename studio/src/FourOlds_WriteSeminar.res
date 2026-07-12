/* THE FOUR OLDS v14 — THE SEMINAR, rebuilt per the user's design:
   a worker sincerely asks what Mao's four categories MEAN, and the
   facilitator's four warm, concrete, American examples are — unknown to
   everyone in the room — portraits of the four men the movie is named for.
   First deliverable of v14. Engine-written, 1883 action-line register. */

let outPath = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/draft/engine_seminar_v14.scene.txt"

let seed: Seed.sceneSeed = {
  id: "four-olds-v14-seminar",
  slug: "INT. FRONTIER AEROSPACE, TRAINING ROOM B - DAY",
  logline: "Mandatory Cultural Alignment, Module 7: a corporate facilitator presents Mao's Four Olds as an admirable early framework; an older worker sincerely asks what the four categories actually mean, and her answer is cheerfully, terrifyingly vague — anything can be an old, and the beauty of the framework, she says, is that you decide what counts for you. The room goes quiet. The homework hands every man the knife and asks him to pick what to cut.",
  cast: [
    {
      name: "FACILITATOR",
      who: "30s, corporate trainer, all teeth, clicker in hand. Genuinely nice — that is the horror. She does not sneer at the old things; she examines them, warmly, the way a nurse discusses a growth. She improvises well and reads silence as engagement.",
      register: "chirpy corporate-positive, exclamation-adjacent, 'great question' energy; short bursts; never sarcastic, never cruel on the surface.",
      earnsEloquence: false,
      lexicon: "HR-training English: frameworks, examine, journey, retire (as a verb for traditions). No academic jargon, no political vocabulary.",
    },
    {
      name: "BAY TWO MAN",
      who: "60s, machinist laid off from Bay Two, attending because the notice said mandatory for rehire eligibility. He is not baiting her — he genuinely wants to understand what he is being asked to give up. His sincerity is what makes the scene land.",
      register: "plain, slow, few words, no rhetoric. Asks like a man asking about a part number.",
      earnsEloquence: false,
      lexicon: "shop plain.",
    },
    {
      name: "JOSS",
      who: "26, dock worker, near the back with sunflower seeds. Dry, minimal, constitutionally unable to let a thing pass — but he knows the sign-in clipboard feeds his compliance score.",
      register: "deadpan, short, no hand raised.",
      earnsEloquence: false,
      lexicon: "plain gen-z minimal, no slang overload.",
    },
    {
      name: "PELL",
      who: "50s, federal compliance administrator, drops in mid-module to be seen blessing the good work. Knows nothing about the content and consumes it like vitamins.",
      register: "beaming officialese, benedictory.",
      earnsEloquence: false,
      lexicon: "compliance-brochure English.",
    },
  ],
  layer: {
    peshat: "a mandatory corporate heritage-training session; a worker asks a sincere question; an administrator drops in; homework is assigned",
    sod: "the framework needs no aim because it makes every man aim at himself — the categories are elastic enough to hold any American life, and the homework outsources the targeting to the targeted. Nobody in the scene names this. The four category names will find their four men later, on the crates, without this room ever knowing them.",
  },
  beats: [
    {
      who: "FACILITATOR",
      want: "deliver Module 7 on schedule with good engagement",
      wall: "a sincere question she was not scripted for: what do the four categories actually mean",
      turn: "her improvised answer is genuinely vague — a couple of harmless, ordinary examples, then the cheerful pivot that the beauty of the framework is you decide what counts as old for you — and the room goes quiet in a way she reads as engagement",
      subtext: "the machine does not need to aim; it hands every man the knife and lets him choose the cut",
    },
    {
      who: "BAY TWO MAN",
      want: "genuinely understand what counts as an old idea, an old custom, an old habit",
      wall: "the categories are abstractions on a slide",
      turn: "the answer he gets could mean anything at all — which means it can mean anything of his; he lowers his hand and says nothing more for the rest of the scene",
      subtext: "the vagueness IS the answer, and he is old enough to know it",
    },
    {
      who: "JOSS",
      want: "poke the thing once",
      wall: "the sign-in clipboard feeds his compliance score",
      turn: "he asks anyway — what happened to the people who liked the old stuff — and the answer is a smiling euphemism; he files it",
      subtext: "the kid's first clear look at the machine's teeth",
    },
    {
      who: "PELL",
      want: "be seen blessing the good work",
      wall: "he knows nothing about the material",
      turn: "he praises the Mao slide as 'centuries of ancient Chinese wisdom,' is corrected ('it's from 1966—'), and beams 'Wonderful.' — and stays",
      subtext: "the enforcer takes propaganda like vitamins; accuracy is not the point, alignment is",
    },
  ],
  rules: [
    "THE PAYLOAD — the BAY TWO MAN sincerely asks what the four categories actually mean, and the FACILITATOR's answer must be PLAUSIBLY GENERIC: the kind of examples a real corporate trainer improvises on the spot. Allowed register: a handshake deal instead of a proper contract; recipes nobody wrote down; taking your hat off for a parade; keeping things in the garage you never use. Two or three loose examples MAXIMUM, a little circular, cheerfully unbothered by their own vagueness — and then the pivot that is the scene's real tooth, delivered as a selling point: the beauty of the framework is that nobody has to tell you what your olds are — you know them already; each person decides what counts for them. That is what the homework then formalizes. The menace is the ELASTICITY — everything is potentially in scope and the room is being asked to aim at itself — and NOBODY names this, ever. The vagueness just sits.",
    "HARD BANS on her examples (these would read as portraits of the film's principal characters and the audience must never feel the writer's hand): no mention of fifty years, no Tuesdays or any weekly ritual kept for decades, no test pilots or pilot tall tales, no flag-folding, no anthem singing, no signatures on old engineering standards, nothing that matches any principal character's biography or trade. Her examples must be the ordinary furniture of anyone's life, not anyone's life in particular.",
    "NOBODY in the room connects anything to any person. No knowing looks, no reaction shots that wink. The room's response to her answer is SILENCE, which the Facilitator misreads as engagement.",
    "REQUIRED canon beats, keep these exactly: the slide sequence — a stylized Mao portrait over the words 1966 — A BOLD QUESTION: WHAT DO WE OWE THE PAST?, then a slide in clean sans-serif on harmony blue reading OLD IDEAS. OLD CULTURE. OLD CUSTOMS. OLD HABITS.; MACK in the third row copying the four category names into a pocket notebook in block letters (no explanation why); JOSS's line, not raising his hand: 'What happened to the people who liked the old stuff?' answered after a silence with: 'There were — implementation errors. In that era. Which is why today's frameworks center dialogue.'; PELL's drop-in: 'Don't mind me. This is the good work, folks. Centuries of ancient Chinese wisdom in that slide.' / FACILITATOR: 'It's from 1966—' / PELL: 'Wonderful.'; the homework slide: YOUR REFLECTION HOMEWORK — IDENTIFY ONE OLD HABIT YOU'RE READY TO RETIRE!; the chained sign-in clipboard that feeds compliance scores; the corridor button — JOSS, low: 'My grandpa's old habit was getting shot at over Hanoi.' MACK: 'Write coffee. Everybody writes coffee.'",
    "ACTION LINES per studio/SCREENPLAY_STYLE.md, strictly: one paragraph = one shot, 1-3 sentences, never more than 4 lines; verbs lead, fragments legal as shot-cuts; end a flowing beat with ' ...' and an interrupted one with ' --'; CAPS for first appearances, sounds, and the one object the frame must find, one detonation per beat max; sound on its own line; mini-slugs (AT THE DOOR --, ON THE SCREEN --) instead of prose transitions; NO similes, NO metaphors, NO aphorisms in action lines — plain facts the lens can see; at most one plain-fact editorial line in the whole scene; white space is pace.",
    "CIVILIAN LANGUAGE throughout — no insider jargon of any trade. The facilitator's corporate dialect is allowed because it translates itself.",
    "No rule-of-three rhythm in any dialogue except the slide text itself. The facilitator lists four things because there are four things, plainly, not musically.",
    "Kill every AI tell: no negative parallelism, no corrective definition, no em-dash chains in dialogue, no withheld-then-appended fragments about a single image.",
    "Length: about two screenplay pages. The scene ends in the corridor on Mack's coffee line — no extra coda.",
    "Fountain screenplay format: slugline, action lines, colon-terminated CHARACTER NAME: cues (this project's convention).",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=5)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: THE SEMINAR (v14) ===\n")
    Js.log(Cinema_Backends.readText(out))
  } catch {
  | Write.WriteError(m) => Js.log("WRITE FAILED (gate):\n" ++ m)
  | Session.SessionError(m) => Js.log("SESSION: " ++ m)
  }
  Session.close()
}
main()->ignore
