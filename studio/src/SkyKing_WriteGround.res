/* ACT 2 — GROUND / THE WORLD REACTS (v2, real people not NPCs). The plane's an hour up
   and the airport is a command post: FBI, DHS, TSA, port police, the airline, a bridge
   line to whoever weighs a shoot-down. FBI agent REYES works the two men who know the
   pilot: WARD (the boss, who passed him over two weeks ago - which hangs it on him, so
   he WON'T say it) and DEZ (who watched his friend board, and won't hand him to a room
   that might kill him). The truth is PRIED OUT against their self-interest, and it's
   worse than a threat - a gentle nobody, no plan, no demand. They need someone he'll
   pick up the phone for. NO helpful NPCs; every line is a person protecting their own.
   Reyes established + human, NOT a bot. Supervisor CUT. Every catalog tell killed. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-ground.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-ground",
  slug: "INT. AIRPORT OPERATIONS CENTER - COMMAND POST - NIGHT",
  logline: "The plane is an hour up and the airport has become a command post - FBI, Homeland, TSA, port police, the airline, a bridge line open to the people weighing whether to shoot it down. In the middle of it FBI agent Reyes works the two men who know the pilot: Ward, the ramp boss, who will not say the thing that hangs it on him, and Dez, who watched his friend walk onto that airplane and would rather chew glass than hand him to the room that might kill him. The truth about Birdy has to be pried out, and it's worse than a threat - no plan, no demand, no reason a machine can use, just a gentle nobody nobody ever looked at - and they need someone he'll pick up the phone for.",
  cast: [
    {
      name: "REYES",
      who: "FBI, running the human-intel piece of a huge multi-agency response; sharp, fast, pressured, but a real person doing a brutal job in a chaos - NOT cruel, NOT a machine; she needs to know who this man is, for the room deciding his fate and for any shot at talking him down; she feels the clock and the shoot-down under everything. One agent in a swarm, not a lone investigator.",
      register: "professional, fast, human under pressure; identifies herself as FBI; gets tired and plain and even redundant, not machine-gun; decent, never a bitch, never a bot.",
      earnsEloquence: false,
      lexicon: "the incident, the badge, the bridge line, intent, the intercept said flat and procedural; her own weariness plain.",
    },
    {
      name: "WARD",
      who: "the ramp boss; the pilot is one of his, and he passed him over two weeks ago, which hangs the whole thing on him - so he is defensive, cagey, self-protective, gives the minimum; the guilt is UNDER it and he will NOT confess it. He protects himself and his ramp.",
      register: "defensive, worn, cagey; deflects, minimizes, answers a question with less than it asked; the guilt buried, never spoken.",
      earnsEloquence: false,
      lexicon: "the ramp, the roster, the aircraft, the badge said flat; what he won't say, he won't say.",
    },
    {
      name: "DEZ",
      who: "Birdy's friend; he's here because he SAW him board - the witness; and he's the one who told Birdy to reach, to ask for more. Torn between what he saw and protecting his friend, scared for him, guilty; he stonewalls and resists, will not give Birdy up easily to a room that might shoot him.",
      register: "younger, protective, hesitant (beta), wrecked; resists, deflects, gives up ground against his will; pauses, trails; plain and scared.",
      earnsEloquence: false,
      lexicon: "the ramp, what he saw, his friend said plain; his own part in it he can barely touch.",
    },
    {
      name: "COLE",
      who: "a different FBI agent who takes over the room when Reyes steps away; burnt-out, blunt, casually contemptuous of the public; he answers a question that wasn't even aimed at him, flat and crude, then goes back to his phone.",
      register: "flat, crude, no-nonsense, casually derogatory about civilians; brief; not performing cruelty, just how he sees people.",
      earnsEloquence: false,
      lexicon: "the technique, the public, said flat and contemptuous.",
    },
  ],
  layer: {
    peshat: "in a chaotic multi-agency command post, an FBI agent pries out of the ramp boss and a witness who the pilot is and who can reach him",
    sod: "the whole apparatus of the state has descended on the gentlest, most overlooked man alive, treating him as a threat, and the two men who actually know him protect themselves and him against it - Ward won't own that he passed him over, Dez won't hand his friend to the room that might kill him; the truth pried out of them is worse than a threat - no plan, no demand, no reason a machine can use, just a nobody nobody looked at, which is why they can't predict him or save him; the man who did nothing his whole life is now the center of a national emergency, and the people who overlooked him have to reckon with it while trying not to be the reason he dies; the machinery turns toward the wife who'd given up on him, as maybe his only chance",
  },
  beats: [
    {
      who: "REYES",
      want: "who this man is, fast - for the room and the bridge line asking about intent",
      wall: "Ward is cagey and self-protective, gives her the minimum, clearly holding something back",
      turn: "she gets the name - Birdy, William Petrek, a bag handler - but Ward's evasion tells her there's more, and the swarm keeps ratcheting around them (Homeland, the airline, the bridge call, the intercept)",
      subtext: "Reyes reading Ward's evasion; the scale and the clock pressing; Ward protecting himself and his ramp; the machine needing a threat it can act on",
    },
    {
      who: "REYES",
      want: "the WHY - grievance, plan, threat, anything that predicts him",
      wall: "the why is that Ward passed him over and Dez told him to reach - things that hang it on THEM and give up their friend, so they won't say them",
      turn: "she pries it out against their will - the pass-over slips loose and Ward goes defensive; Dez, scared and guilty, gives up more than he means to about what he saw; the truth lands - no motive, no plan, a gentle nobody - which is worse, because a machine can't use it",
      subtext: "the two men protecting themselves and Birdy; the guilt under it; the truth extracted against resistance, unusable to the machine; the dawning horror that they may be why he's up there",
    },
    {
      who: "REYES",
      want: "anyone he'll pick up the phone for - a shot at talking him down before someone decides for him",
      wall: "giving up the wife hands Birdy's last person to a room that might kill him; and it isn't good with the wife anyway",
      turn: "they give up Maya - reluctantly, Dez maybe because it might be his only chance - and Reyes moves on it while the command post roars and the bridge line waits on intent",
      subtext: "the agonizing choice - help the machine that might kill him, hoping it saves him; the turn toward Maya as his last chance; the man nobody saw at the center of everything",
    },
    {
      who: "DEZ",
      want: "just to say it to Ward - why did she handle them like that",
      wall: "he's muttering to Ward, not to the agents",
      turn: "Reyes has gone and another agent, Cole, has dropped into her chair; Dez mutters to Ward - 'why's she talk to us like we ride the short bus' - and Cole, who it wasn't even aimed at, answers him flat and crude and goes back to his phone; Dez looks at the green track",
      subtext: "the plant - Birdy was treated as less-than his whole life (bullied, mislabeled, the short bus), never stated; the machine's casual presumption, answering a question not asked; Dez feeling it and saying nothing",
    },
  ],
  rules: [
    "Action lines = ONLY what the camera sees or the mic hears. CONVEY THE SCALE: a real national-security response has descended - FBI, DHS/Homeland, TSA, port police, the airline, agents and radios and screens everywhere, a bridge line open to the people weighing a shoot-down. It is CROWDED, CHAOTIC, multi-agency - NOT one lone investigator, NO small-town single-cop. Reyes is one agent in a swarm.",
    "REYES is FBI (she establishes it plainly on the page) and a REAL PERSON doing a brutal job under a clock - NOT a bitch, NOT an interrogation-bot; she gets tired, plain, even redundant lines; she is decent under the pressure. She needs the intel for the room deciding his fate AND for any shot at talking him down.",
    "WARD is DEFENSIVE and self-protective: the pilot is one of his and he passed him over two weeks ago, which hangs it on him, so he will NOT volunteer that - it must be PRIED OUT or slip sideways, reluctantly; his guilt stays UNDER his defensiveness, NEVER confessed outright.",
    "DEZ is here because he SAW Birdy board (the witness) and is TORN: protective, scared for him, guilty (he told him to reach); he STONEWALLS and resists, will NOT give Birdy up easily to a room that might shoot him; the truth comes out against his will.",
    "REAL PEOPLE, NOT NPCs: nobody helpfully serves the plot or hands over information they'd protect. Every character pursues their OWN want and self-interest; the exposition is EXTRACTED against resistance, NEVER volunteered. If a line exists only to inform the audience or the agent, cut it or make it a weapon or an evasion.",
    "The truth about Birdy (a gentle nobody, no plan, no demand) emerges AGAINST their resistance and lands as WORSE than a threat - carried by their reluctant, self-protective account, NEVER a summarizing Line.",
    "The move to the WIFE (Maya) is the AGONIZING choice at the END - handing his last person to the machine, maybe his only chance. Do NOT resolve it; set it up.",
    "CUT any pure-NPC / plot-delivery character - no supervisor who just relays a line.",
    "Recorded, not written; American vernacular; KILL every catalog tell: doubled-openers, engineered refrains, appended-fact fragments, list drumbeats, cross-character mirroring, summarizing Lines, thematic telegraphing, the movie-procedural / ticking-clock register.",
    "Voice-differentiate HARD: REYES (fast, professional, human), WARD (defensive, worn, cagey), DEZ (younger, protective, hesitant, wrecked).",
    "END WITH A VERY QUICK BUTTON (~3 lines, do NOT overdo it): after Reyes steps away and another agent (COLE) drops into her chair, DEZ mutters to WARD - NOT to the agents - 'why's she talk to us like we ride the short bus'; COLE, whom it was NOT directed at, answers unprompted, flat and crude ('because you people...' + a cynical reason), then back to his phone. Do NOT explain any connection to Birdy; Dez just looks at the green track. Keep it TIGHT - a handful of words, then out.",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=5)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: GROUND v2 (real people, real scale) ===\n")
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
