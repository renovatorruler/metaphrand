/* Act 1, beat 5 — THE DAY (the quiet passing-over → Doorway 1). End of shift. WARD
   calls Birdy in to tell him the crew-chief slot went to Marquez - the job Ward held
   open two weeks waiting on a man who would never walk in and ask - and to ask Birdy,
   the best hand out there, to TRAIN Marquez into it. Birdy makes it easy, agrees to
   train the winner, and something goes quiet. HIS OWN FAULT, honest system, even
   kind - NOT a victim, NO villain. The last drop in a full glass of numbness. Comfort
   is the horror. Recorded, not written. Engine-written; the Sod stays under. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-passed.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-passed",
  slug: "INT. RAMP OFFICE - DAY",
  logline: "End of shift. Ward calls Birdy into the cramped ramp office to tell him the crew-chief slot went to Marquez - the job Ward held open two weeks waiting on a man who would never walk in and ask - and to ask Birdy, the best hand out there, to bring Marquez up to speed on it. Birdy tells him he made the right call, agrees to train him, gives the boss nothing to feel bad about, and goes back to the ramp with something gone quiet in him.",
  cast: [
    {
      name: "BIRDY",
      who: "the best hand on the ramp and a gifted coward; he will not confront or reach or ask, ever - that is his whole tragedy - and he makes it easy for everyone, which is why his life goes nowhere. The same man who will, at dusk, take a plane.",
      register: "gentle, plain, agreeable, short; deflects by making it easy and saying the small good thing; never defends himself, never reaches; gives the boss nothing to push against. Recorded, not written.",
      earnsEloquence: false,
      lexicon: "the job, the ramp, the schedule, the shift said flat and literal; NEVER a metaphor for a feeling.",
    },
    {
      name: "WARD",
      who: "the ramp boss, fifties; decent, gruff, worn; he knows Birdy is the best out there and he held the chief slot open for him and finally couldn't; he feels bad and half-wants Birdy to be angry so the guilt has somewhere to go. NOT a villain - the honest system with a conscience.",
      register: "plain, direct, a little worn; the boss who has had this talk before; goes quiet and awkward when Birdy won't give him a reaction; not cruel, never a speech.",
      earnsEloquence: false,
      lexicon: "the slot, the roster, the shift, the paperwork said flat and literal.",
    },
  ],
  layer: {
    peshat: "the boss tells Birdy the chief job went to someone else and asks him to train the man who got it; Birdy agrees",
    sod: "the bill for the cowardice, fully due and by Birdy's own hand: the one step up he might have had went to a lesser man because Birdy would never walk in and ask, though the boss held it open and all but waited on him; now Birdy will TRAIN the winner, the way he carries everyone; the honest system was even kind and it cost him anyway; he had every true thing to say and said none; the comfort clicks one notch tighter and something in him goes finally, terminally quiet - the last drop before, at dusk, he takes the plane",
  },
  beats: [
    {
      who: "WARD",
      want: "to tell Birdy the chief slot went to Marquez and get it over clean - and, under it, to get some sign Birdy minds, so he isn't the man who screwed him",
      wall: "Birdy gives him nothing to push against - no anger, no ask, no fight",
      turn: "Ward lays it out, says he held it open, waited on him, couldn't anymore; Birdy takes it flat and tells Ward he made the right call",
      subtext: "Ward respects Birdy, knows he's the best, feels bad; he wants Birdy to be angry so the guilt has somewhere to go; Birdy won't give him that - won't reach even to defend himself",
    },
    {
      who: "WARD",
      want: "to get Birdy to bring Marquez up to speed - Birdy knows the chief work better than anyone",
      wall: "he is asking the passed-over man to train the man who passed him",
      turn: "Ward asks; Birdy says okay, he'll get Marquez up to speed - no edge, no hesitation, he just says yes",
      subtext: "the whole tragedy in one ask: Birdy does the work, others get the title, and he makes it easy; the cosmic joke that he's the best flier none of them will ever know they had, training a lesser man for a lesser job",
    },
    {
      who: "BIRDY",
      want: "for it to be over, to go back to work",
      wall: "something has gone quiet in him that wasn't quiet this morning",
      turn: "Ward, out of things to push on, tells him it's a good thing he's doing - which is worse; Birdy nods and goes back out to the ramp; the glass is full and the last drop has landed",
      subtext: "no outburst, no self-pity - comfort is the horror - a small terminal quiet; the man who, at dusk, will walk into the empty Q400 and take it",
    },
  ],
  rules: [
    "Action lines = ONLY what the camera sees or the mic hears. No interiority, no naming feelings.",
    "THEME never stated: no one says passed over, coward, afraid, deserved, unfair, gift, or dream. Birdy NEVER says 'that should've been mine' and never defends himself. The passing-over shows through the plain exchange and through what Birdy does NOT say.",
    "HIS OWN FAULT, honest system, even KIND, NOT a victim: make it clear Ward held the slot open and waited on Birdy, who never put in; no one wronged him. NO villain, NO firing, NO melodrama. Ward is decent and feels bad.",
    "The gut-punch is the ASK: Ward asks Birdy to TRAIN Marquez into the job, and Birdy just says yes. He carries everyone; he makes it easy; THAT is the tragedy - never stated.",
    "BIRDY will not confront or reach, ever: he deflects with the small agreeable thing, tells the boss he made the right call, agrees to train the winner. Plain, real, and it is him. NO aviation, NO metaphor, NO Line.",
    "WARD is decent and worn, NOT a villain: gruff, direct, awkward at Birdy's non-reaction, half-wanting a rise out of him. Voice-differentiate HARD: WARD plain/direct/boss-worn; BIRDY short/deflecting-agreeable/gives nothing. A reader must tell them apart with the names stripped.",
    "Keep the winner (Marquez) a FACT, not the subject - the live thing is between Ward and Birdy in the room (Ward wanting a rise, the train-him ask; Birdy giving nothing), NEVER two men standing around discussing an absent third.",
    "Recorded, not written: plain, mundane, a little baggy; the office, the roster, the shift; clip a line ONLY when a beat earns it; when in doubt, make it worse.",
    "End SMALL: something goes quiet in Birdy - shown ONLY in behavior (a beat, back to the ramp), never named. The last drop before Doorway 1. No self-pity.",
    "No appended-fact tags stapled after a sentence closes; no echo-repeat tic; no aviation poetry; no one gives a Line.",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=4)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: THE DAY (the quiet passing-over) ===\n")
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
