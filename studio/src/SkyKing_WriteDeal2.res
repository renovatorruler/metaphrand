/* ACT 2 #13 — R2: FIREWORKS (2026-07-03; the collision scene — the bridge
   grammar's tension member). REYES comes off the failed offer needing the deal
   REAL: paper, a name good for it, terms she can say on the air. MERCER, the
   honest middleman, has already asked upstairs - and upstairs isn't interested
   in paper for this man; between the lines, some of the bridge line would be
   fine with FIREWORKS over the water. It solves itself. No villain - an
   institution pricing options in flat voices. THE TURN: the clip breaks over
   the command post mid-argument - the machine's own room becomes one more dark
   room stopped by the voice (the crossover image: an agent's phone playing the
   bad-thing apology; the room going quiet like the garage did) - and the
   politics invert in real time: nobody shoots anything down on a night the
   whole country is listening, and suddenly they NEED him down alive. Reyes
   WINS her deal - authorized for the wrong reason - and the win tastes like
   ash. She takes it anyway (fail forward: the right thing at a price) and
   heads for the radar room. Both of them right; neither of them clean.
   Engine-written. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-deal2.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-deal2",
  slug: "INT. AIRPORT OPERATIONS CENTER - COMMAND POST - NIGHT",
  logline: "Reyes comes off the frequency with the man's gentle disbelief still in her ears and asks her boss for the one thing that might actually bring him down: a real deal - paper, a name that's good for it, terms she can say on the air without lying. And Mercer, who already asked, gives her the machine's true answer: upstairs isn't interested in paper for a man they've filed under threat - and between the lines, some of the voices on the bridge line would be fine with fireworks over the water. Then a junior agent's phone says, in a soft tinny voice the whole room recognizes, that it kind of did a bad thing - and the command post stops like a garage at midnight, and the politics flip while they stand there: you can't shoot a man the whole country is listening to. She gets her deal. For the wrong reason. She takes it anyway.",
  cast: [
    {
      name: "REYES",
      who: "fresh off hearing herself lie to the gentlest man alive and being thanked for it; she wants the deal REAL and she wants it in writing - not for procedure, because a real promise is the only card left that might land him. She fights her own boss with the file's facts (empty plane, no demands, no victims, the fuel clock) and loses on the merits - and then wins on the optics, which is worse, and takes it anyway because he's still up there.",
      register: "professional, pressed, human; argues with facts not feelings; her disgust at the winning reason stays UNDER (one look, one beat - never a speech); ends moving.",
      earnsEloquence: false,
      lexicon: "paper, a name that's good for it, terms I can say on the air, the file, said flat and driving.",
    },
    {
      name: "MERCER",
      who: "the honest middleman - he already made her case upstairs before she asked, because he's not a villain; he relays the machine's true position in flat arithmetic (no paper for a threat; fireworks solve themselves) and he neither endorses it nor softens it. When the clip breaks over the room he reads the new politics instantly and reprices without sentiment: now they need him down alive, so she gets her deal. He never pretends the reason is mercy.",
      register: "flat, fast, arithmetic; relays ugly positions without owning or disowning them; the repricing delivered as procedure; one honest beat of tiredness allowed.",
      earnsEloquence: false,
      lexicon: "upstairs, the bridge line, options, what they'll own, said flat.",
    },
    {
      name: "KEMP",
      who: "the DHS liaison, still on his phone and his log; the one who relays that the watch floor is asking about the clip - the machine discovering the country mid-call.",
      register: "dry, careful, brief; one or two relays.",
      earnsEloquence: false,
      lexicon: "the watch floor, the clip, the numbers, said dry.",
    },
    {
      name: "BIRDY",
      who: "present ONLY as the clip - his recorded voice out of an agent's phone, the same tinny snippet the country is playing, arriving inside the room that filed him as a threat. He does not know.",
      register: "a verbatim reprise of the bad-thing apology, tinny, small; nothing new.",
      earnsEloquence: false,
      lexicon: "only what he already said.",
    },
  ],
  layer: {
    peshat: "the negotiator fights her boss for a real deal and loses - until the viral clip reaches the command post and the politics reverse; she gets the deal for optics and takes it",
    sod: "the collision of two right people inside a machine that is honest about being a machine: she is right that only a true promise can reach a man who has priced himself at life in prison, and he is right that the institution will never paper a threat - and the thing that breaks the deadlock is neither of them: it is the country, arriving through a phone speaker, turning mercy into the cheaper option; the room that could not find a box for him is invaded by his voice like every other room in America, and stops the same way; she wins everything she asked for and the reason dirties it - the machine never becomes kind, it becomes watched, and the difference is the whole film's honesty; she takes the ash-flavored win because the man is still in the air and the light is going",
  },
  beats: [
    {
      who: "REYES",
      want: "the deal made REAL: paper, a name good for it, terms she can say on the air without lying",
      wall: "Mercer already asked - upstairs isn't interested in paper for a man filed under threat; the file's facts (empty plane, no demands, nobody hurt) don't move a category",
      turn: "she pushes it to the wall - what exactly are they planning to do with him then - and Mercer gives her the machine's true position, flat, between the lines: some of the bridge line would be fine with fireworks over the water; it solves itself",
      subtext: "both of them right; the institution honest about itself through its honest middleman; the word shoot-down never said - 'fireworks' does the work; her horror stays procedural",
    },
    {
      who: "MERCER",
      want: "to keep the night inside what upstairs will own - and get through it without the Bureau owning a dead man it chose to kill",
      wall: "Reyes won't let the position sit unexamined; she makes him say what 'options' costs and who carries it",
      turn: "a junior agent's phone, somewhere behind them, says in a small tinny voice: I, uh. I kind of did a bad thing here - and heads turn; another phone has it; a wall monitor cuts to the beach road's line of headlights; Kemp relays that the watch floor is asking about a clip; the command post goes quiet the way the garage went quiet",
      subtext: "the crossover image - the machine becomes one more dark room stopped by the voice; the country arriving inside the building; nobody in the room chooses anything, the ground just moves",
    },
    {
      who: "MERCER",
      want: "(repricing in real time) to read the new politics and act inside them",
      wall: "the new politics are made of numbers still climbing on his own agents' phones",
      turn: "he says the new position as flatly as he said the old one - nobody is shooting anything down on a night the whole country is listening; and they need him down alive now - and turns to Reyes: she gets her paper; make the offer real",
      subtext: "mercy by optics; the machine never becomes kind, it becomes watched; the fireworks die not from conscience but from cameras - and the film says so without saying it",
    },
    {
      who: "REYES",
      want: "(the ash-flavored win) to take it and go - because he's still up there",
      wall: "the reason: she asked for mercy and got arithmetic wearing mercy's clothes",
      turn: "one beat - she looks at the phones still playing his voice around the room, and at Mercer, and doesn't say the thing; she takes the authorization and moves for the radar room; end on Mercer alone at the table, the counts climbing on the wall monitor behind him",
      subtext: "the right thing at a dirty price, taken anyway; her disgust one look wide, never a speech; the deal now REAL for R3 - where the man it's for still won't believe it",
    },
  ],
  rules: [
    "THE COLLISION IS HOT AND BOTH ARE RIGHT: Reyes argues the file's facts (empty plane, no demands, nobody hurt, the fuel clock); Mercer relays the institution's true position without owning or disowning it. Neither is a villain; neither backs down until the ground moves. Real interruption rhythm is allowed - two professionals talking over each other ONCE at the peak - but no shouting match, no speeches.",
    "THE WORD 'SHOOT-DOWN' IS NEVER SAID: 'fireworks over the water' and 'it solves itself' carry it, flat, between the lines - exactly once each. Nobody gasps; Reyes's horror is procedural (she makes him say what it costs and who carries it), never performed.",
    "THE CLIP BREAKS AS THE TURN: a junior agent's phone plays the VERBATIM bad-thing snippet (tinny, small) - the same audio from the clip scene; heads turn; a second phone; a wall monitor with the beach-road headlights; KEMP's dry relay (the watch floor asking about a clip; the numbers). THE ROOM STOPS THE WAY THE GARAGE STOPPED - stage the echo of that image plainly (people going still, work suspended). Nobody says 'viral', 'trending', 'folk hero', or reads the internet aloud.",
    "THE REPRICING IS FLAT: Mercer states the new position with the same arithmetic voice as the old one - nobody is shooting anything down on a night the whole country is listening; they need him down alive now; she gets her paper. He NEVER pretends the reason is mercy, and NOBODY names the irony (no 'funny how...' lines, no summarizing).",
    "REYES'S DISGUST IS ONE LOOK WIDE: she takes the win without thanking anyone and without a speech; the closest she comes is a beat of not saying the thing. She exits MOVING (toward the radar room - R3 is loaded).",
    "SOURCED FACTS ONLY: the clip and the beach-road crowds arrive through phones/monitors/Kemp's relay (all planted); the fuel clock may be cited from the board; nobody knows anything the room wasn't given.",
    "ACTION LINES ARE FULL SENTENCES, PRESENT TENSE; ORIENT every voice (re-anchor Reyes arriving off the radar-room corridor, Mercer at the big table, Kemp at his phone); the SECOND CHANNEL stays physical (the wall monitors, the bridge-line phone, agents' phones lighting one by one, the fuel estimate, Kemp's log).",
    "END on Mercer alone at the table, the counts climbing on the monitor behind him - no button, nobody comments.",
    "Kill every catalog tell: doubled openers, engineered refrains, appended-fact fragments, list drumbeats, cross-character mirroring, summarizing Lines, thematic telegraphing, stated turns, manufactured stammers, parallel restatement, trailing-'so.' American vernacular. Recorded, not written.",
    "Voice-differentiate: REYES (pressed, driving, facts), MERCER (flat arithmetic, honest middleman), KEMP (dry relays), BIRDY (the tinny verbatim snippet only).",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=5)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: R2 FIREWORKS (the collision; the clip breaks; the ash win) ===\n")
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
