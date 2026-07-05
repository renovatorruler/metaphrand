/* ACT 2, beat 3 — THE INTERCEPT. The klaxon that was always a false alarm (the Act 1
   base scene) is real this time. Deacon & Banjo scramble hot, briefed hijacked
   airliner, and come up on a Q400 doing slow gentle turns, flown by an unarmed,
   untrained, lost man who is somehow flying it beautifully. The terrorist collapses
   into a person; the pilots who waited their whole careers for something real get it,
   and it's nothing they trained for. Bishop (the controller, just cast) is the human
   thread. PAYS OFF the Cessna. Recognition BEGINS (not the full awe / barrel roll yet).
   NO villain, NO action-thriller. Engine-written. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-intercept.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-intercept",
  slug: "INT. F-15 COCKPIT / NIGHT SKY - NIGHT",
  logline: "The klaxon that was always a false alarm is real this time. Deacon and Banjo scramble hot, briefed for a hijacked airliner - and come up on a Q400 doing slow, gentle turns in the dark, flown by a man who isn't attacking anyone, who can barely hold an altitude, who is somehow flying it beautifully. The terrorist they were sent to stop turns out to be a lost soul, and the pilots who waited their whole careers for something real get it, and it is nothing they trained for.",
  cast: [
    {
      name: "DEACON",
      who: "the flight lead; serious, by-the-book, controlled; runs the intercept by procedure, ready to do the terrible thing if ordered - but what he finds fits no procedure. The coward among the brave, watching a man dare everything.",
      register: "clipped fighter-pilot radio, correct and terse, going plainer and more human as it stops fitting; never a speech, never poetry.",
      earnsEloquence: false,
      lexicon: "real intercept phraseology - heading, angels, tally, visual, no joy, knock it off - literal; the Q400 and the sky said flat.",
    },
    {
      name: "BANJO",
      who: "the wingman; dry, restless, has ached his whole career for something real - and now it's here and it isn't a fight, it's a doomed gentle guy; the clown goes quiet.",
      register: "dry radio banter that dies into something real; the ache under it; clipped, then plain.",
      earnsEloquence: false,
      lexicon: "intercept phraseology literal; his gripes and quips flat, then silenced.",
    },
    {
      name: "BISHOP",
      who: "the air traffic controller who has taken over working the man in the Q400; calm, kind, the human thread; he keeps reminding everyone there is a person up there; steady, careful, humane, never panicked.",
      register: "calm, warm, steady ATC; the human center; plain and kind; never a speech.",
      earnsEloquence: false,
      lexicon: "the radio, the altitudes, the man's callsign said calm and literal.",
    },
  ],
  layer: {
    peshat: "two fighter pilots scramble to intercept a rogue airliner and find an unarmed, untrained, gentle man flying it",
    sod: "the false-alarm klaxon is finally real - and the something-real these starved men waited a whole career for is not a battle but a doomed, gentle soul who can somehow fly; the terrorist assumption collapses into a person; the pilots begin, against everything, to SEE him; the Cessna stand-down is over, and what replaces it is stranger and sadder and - as he flies - awe beginning; Deacon, the coward among the brave, is watching a man do the bravest, most doomed thing, and it lands on him; 'he's one of us' has not been said yet - this is where it starts",
  },
  beats: [
    {
      who: "DEACON",
      want: "to run the intercept by the book - identify the threat, get eyes on, be ready for the order",
      wall: "the klaxon they've mocked for years is real; they're briefed a hijacked airliner, and everything that implies",
      turn: "they scramble hot and climb toward the target - Banjo half-expecting another county-strip nothing - and it is NOT nothing: a real Q400, airborne, moving in the dark",
      subtext: "the false alarm is over; the thing they starved for is here; professional adrenaline while the Cessna-rhyme collapses into something real",
    },
    {
      who: "BANJO",
      want: "the fight, the threat they were scrambled for",
      wall: "when they get eyes on there is no threat - a Q400 in slow wandering turns, a lone guy, no weapons, not squawking hijack, flying gentle and a little lost",
      turn: "Banjo's ready quip dies; they pull alongside and SEE him - just a man - while Bishop's calm voice keeps saying there is a person up there; the terrorist assumption falls apart",
      subtext: "the ache for something real, answered by something they cannot shoot; the mission deflating into a human being; the clown going quiet",
    },
    {
      who: "DEACON",
      want: "to know what in God's name they're supposed to do with this",
      wall: "there is no procedure for a gentle, untrained man flying an airliner beautifully toward nothing",
      turn: "the Q400 rolls into a clean, impossible turn - the guy can FLY - and Deacon, who stopped reaching for anything real, watches it and something moves in him; not the awe yet, the start of it; Bishop, steady, says just stay with him",
      subtext: "Deacon is Birdy in a flight suit, watching a man dare everything; the first flicker of recognition; the held awe beginning - threat to person to, soon, one of us",
    },
  ],
  rules: [
    "Action lines = ONLY what the camera sees or the mic hears (the cockpit, the HUD, the Q400 in the dark, the night sky). No interiority, no naming feelings.",
    "PAY OFF THE CESSNA: the scramble/target language rhymes the Act 1 base false-alarm ('unknown, low and slow' / 'another one out of the county strip') and INVERTS it - this time it is NOT a Cessna, NOT nothing: a real Q400, moving. Let ONE line (Banjo) carry the callback; do NOT explain it.",
    "NO terrorist-thriller clichés, NO heroics, NO villain, NO action set piece: this is disbelief turning into recognition. The pilots are professionals meeting something that fits nothing; the awe/horror is that the 'threat' is a gentle, doomed man who can fly.",
    "Fighter-pilot radio is REAL and clipped - callsigns, headings, angels, 'tally,' 'visual,' 'no joy,' 'knock it off,' used CORRECTLY - going plainer and human as it stops fitting. NO aviation poetry, NO movie-pilot swagger.",
    "BISHOP is calm, kind, steady - the human thread; he keeps reminding everyone there is a person up there; warm, careful, never panicked, NEVER a speech.",
    "BANJO's dry humor DIES into something real (the ache answered). DEACON runs procedure, then something moves in him (the coward-among-the-brave watching a man dare everything) - shown ONLY through behavior and radio, NEVER stated.",
    "Do NOT reach the full awe, 'he's one of us,' or the barrel roll - that is the later midpoint. This is the START of recognition. End on the pilots pulled alongside, watching him fly, not knowing what to do.",
    "Recorded, not written: plain, procedural, real; no music-cue prose, no flat echoes, no appended-fact tags, no clichés; American vernacular throughout.",
    "BIRDY appears ONLY as a gentle presence - relayed by Bishop or one faint overheard line; he is NOT in the cockpit scene proper.",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=5)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: THE INTERCEPT (Act 2) ===\n")
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
