/* ACT 2 — MAYA GETS THE NEWS. Late, Maya just in from a night shift, and the knock
   comes: a federal agent (SHAW) and a local officer with the look Maya knows from the
   care home - the one you wear walking into a room where somebody's dying. Birdy took
   an airplane. He's up there now, fighters on his wing, men deciding what to do about
   him, and she might be the only one he'll pick up the phone for. The woman who stopped
   waiting up has to decide, in a minute, whether she's still his wife. REAL people
   (Shaw has her own brutal errand + clock; Maya's feelings TANGLED and unnamed - she'd
   already given up on him). End on the THRESHOLD before the call. Every tell killed. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-news.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-news",
  slug: "INT. BIRDY AND MAYA'S HOME - NIGHT",
  logline: "Late, and Maya's just in from a shift when the knock comes - a federal agent and a cop on her step with the look she knows from the care home, the one you wear walking into a room where somebody's dying. They tell her Birdy took an airplane. That he's up there right now, fighters on his wing, men deciding what to do about him, and that she might be the only person he'll pick up the phone for. And the woman who stopped waiting up for him has to decide, in about a minute, whether she's still his wife.",
  cast: [
    {
      name: "MAYA",
      who: "Birdy's wife, the care-home nurse; kind, tired, and long since done reaching for this marriage - she stopped waiting up. The news detonates her: disbelief, then something she can't name - she'd given up on him, and now he might die, and she doesn't know what she feels. NOT a passive victim; her numbness, anger, exhaustion and buried love are all HERS, all tangled.",
      register: "tired, plain, then unmoored; disbelief first ('he loads bags'); the tangled feelings under it, never named; she can barely get the words out, and half of what she says is trying to make it not be true.",
      earnsEloquence: false,
      lexicon: "the house, the shift, the sim in the spare room, said plain; what she feels she cannot say.",
    },
    {
      name: "SHAW",
      who: "a federal field agent sent to the wife's door; she needs Maya to help talk him down, fast, and she has maybe one shot at getting this reeling woman to snap into it; human but pressured, doing a brutal errand - not a bot, not cruel, but she can't give Maya time to fall apart.",
      register: "professional, direct, a little too calm (the crisis-register), pushing gently but hard; her own pressure under it; she doesn't perform comfort.",
      earnsEloquence: false,
      lexicon: "the situation, the aircraft, the phone, the time said flat and controlled.",
    },
  ],
  layer: {
    peshat: "an agent comes to the wife's door with the news that her husband stole an airplane and asks her to help talk him down",
    sod: "the woman who had already grieved this marriage, who stopped waiting up, who was done, learns that the gentle nobody she gave up on has done the most enormous, brave, doomed thing - and is dragged back into loving him at the exact moment she might lose him for real; she doesn't know what she feels and has no time to find out, because a room full of strangers has decided she's his last chance; the numbness she built to survive the marriage cracks; the question the scene puts to her, in a minute, with agents in her living room - is she still his wife",
  },
  beats: [
    {
      who: "SHAW",
      want: "to confirm she's the wife and get her moving - fast",
      wall: "Maya can't take it in; she keeps trying to make it a mistake, a mix-up, the wrong guy",
      turn: "Shaw breaks it plainly - he took an airplane, he's up there now, there are fighters - and Maya's disbelief ('Birdy? he loads bags') cracks into something else",
      subtext: "the agent's brutal errand and her clock; Maya's world not computing; the news landing on the numbness she'd built to get through the marriage",
    },
    {
      who: "MAYA",
      want: "for it to not be true - and a second to feel what she feels",
      wall: "there is no second; Shaw needs her now, and the thing she feels is tangled - she'd given up on him",
      turn: "Maya reels - the sim in the spare room, the planes he loads, the man she stopped waiting up for - and the tangled feelings surface without a name (she was done, and now he might die); she can't say any of it",
      subtext: "the grieved marriage detonating; guilt, numbness, buried love all at once; the woman who stopped reaching, forced to reach",
    },
    {
      who: "SHAW",
      want: "Maya to talk to him - she may be his only chance",
      wall: "putting Maya on with him means she might hear him die; and Maya isn't sure she's still his to save",
      turn: "Shaw tells her the plain truth - he might not pick up for anybody else - and Maya, the woman who stopped waiting up, goes with her / is brought to the phone; end on the threshold, the weight of it, before she ever hears his voice",
      subtext: "the question answered without a word - she's still his wife; the numbness cracked; his last chance is the person he lost",
    },
  ],
  rules: [
    "Action = ONLY what the camera sees or the mic hears (the doorway, the late hour, the agents on the step, the car at the curb, the phone). No interiority, no naming feelings.",
    "REAL PEOPLE, self-interest: SHAW has her own brutal job and clock - get Maya moving - she is NOT a comforting exposition-bot and NOT a cartoon; a pro doing a hard thing, pushing gently but hard, unable to give Maya time. MAYA is NOT a passive victim reciting reactions - her numbness, disbelief, anger, exhaustion and buried love are all tangled and all HERS.",
    "MAYA's feelings are TANGLED and UNNAMED: she'd already given up on this marriage (she stopped waiting up), so the news isn't clean grief - it's disbelief + guilt + numbness + buried love at once, and she can't say any of it. Show it through behavior and what she can't get out, NEVER stated.",
    "The DISBELIEF is specific and real ('Birdy? he loads bags') - the gentle nobody, an airplane, doesn't compute. Do NOT over-explain.",
    "Do NOT resolve into a big emotional speech or a Line. End on the THRESHOLD - Maya brought to the phone / about to hear him, the weight of it, before the call. The call is the NEXT scene.",
    "KILL every catalog tell: doubled-openers, refrains, appended-fact fragments, list drumbeats, cross-character mirroring, summarizing Lines, thematic telegraphing, movie-procedural / ticking-clock register. American vernacular; recorded, not written.",
    "Voice-differentiate HARD: MAYA (tired, plain, unmoored, half-disbelieving), SHAW (professional, direct, the crisis-calm, pressured).",
    "Tie QUIETLY to the established Maya - she works nights (just in from a shift), the marriage was numb, she stopped waiting up, the flight sim in the spare room - do NOT explain the callbacks; let them be.",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=5)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: MAYA GETS THE NEWS (Act 2) ===\n")
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
