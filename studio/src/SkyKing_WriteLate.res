/* Act 1, scene 1 — the coward's morning. The THEME is cowardice: the system is
   honest (it rewards nerve, not talent) and Birdy is gifted AND gutless. An app
   hands the aircraft turn he loves to someone else and puts him on the toilet
   truck — and he doesn't ask why. When the green lead botches the load, he quietly
   covers it and eats the blame. Dez sees the coward in him and says so; Birdy
   deflects and eats his same rote lunch. No villain, no victim. Recorded-not-
   written dialogue (DIALOGUE_DOCTRINE.md). Engine-written; the Sod stays under. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-late.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-late",
  slug: "EXT. AIRPORT RAMP - DAWN",
  logline: "A gifted baggage handler checks in at dawn; an app hands the live-aircraft turn he loves to someone else and puts him on the toilet truck, and he doesn't ask why; when the green lead botches a load, Birdy quietly covers it and eats the blame; his friend Dez sees the coward in him and says it plain, and Birdy just deflects and eats his same rote lunch. The system was never unfair - it only ever paid out on nerve, and he has none.",
  cast: [
    {
      name: "BIRDY",
      who: "a baggage handler in his early thirties, plainly the most gifted hand on the ramp and everyone knows it - and a coward: he will not ask, will not fight, will not reach for the thing he loves, and covers for everyone so there is never a moment of conflict. NOT a victim - the ache is that a gift is worthless without the nerve to spend it, and he knows it. The same man who will one day steal a plane.",
      register: "gentle, warm, agreeable, self-deprecating; deflects everything with a small ordinary line or a shrug; never confronts anyone, ever; says the plain mundane thing ('I did. I said good morning.' is the model). Recorded, not written - flat, a little dull, no cleverness.",
      earnsEloquence: false,
      lexicon: "the real ramp said FLAT and literal - stands, turns, inbounds, chocks, the aircraft, plain shop-talk. NEVER a metaphor for a feeling; a plane is a plane, not a symbol.",
    },
    {
      name: "TANNER",
      who: "a younger ramp lead, newish to running the crew, a little over his head; he makes an honest mistake on the load this morning and is about to wear it - until Birdy quietly takes it off him. Not a villain, not cruel, just green.",
      register: "brisk, a little unsure under the brisk; relieved when Birdy covers for him, though he would never say so.",
      earnsEloquence: false,
      lexicon: "the board and the clock - stands, times, the manifest, the count; plain crew shop-talk, literal.",
    },
    {
      name: "DEZ",
      who: "Birdy's ramp partner and only real friend; the one who sees plainly what Birdy is - gifted and gutless - and is sick of watching him prop up the men who pass him. Worn; dared once, or gave up long ago.",
      register: "dry, blunt, plain; says the hard true thing without dressing it; not cruel, tired.",
      earnsEloquence: false,
      lexicon: "the years and the ramp said flat - seniority, the miles, the count; plain, literal.",
    },
  ],
  layer: {
    peshat: "a dawn shift-start on the ramp - an app assignment, a botched load quietly covered, a friend's hard word, a rote lunch",
    sod: "that the system is HONEST - it never paid out on talent, it pays out on nerve, and Birdy has none; that a gift is worthless without the courage to spend it, so his stuckness is his OWN cowardice and not anyone's unfairness; that he would rather cover for the men who pass him and eat every indignity than risk one moment of conflict or dare to reach for the plane he loves",
  },
  beats: [
    {
      who: "BIRDY",
      want: "the live-aircraft turn - the plane he is the best hand for, the one part of this job he loves",
      wall: "the app assigned it to someone else and put him on the lav truck; and he never actually asked, never put in for it",
      turn: "he takes the toilet-truck job off the app without a word, tells himself the app decides - and quietly, in passing, catches a real ramp thing the others missed",
      subtext: "the plane was never for cowards and he knows it; he could ask, could fight for the turn, and won't, because asking is a risk and he has no nerve - the app is just the story he tells himself so it isn't his fault",
    },
    {
      who: "BIRDY",
      want: "for nothing to become a conflict",
      wall: "Tanner has botched the load and it is about to land on him; the honest thing is to let it",
      turn: "Birdy quietly fixes it and takes the blame himself - covers for the younger man who outranks him - so there is no scene, propping up the very hierarchy that keeps him down",
      subtext: "the purest form of the cowardice: he will eat another man's mistake rather than risk a moment of friction; he holds up the people who pass him because standing still is safer than standing up",
    },
    {
      who: "DEZ",
      want: "to make Birdy see the coward in himself for once - to say the true thing out loud",
      wall: "Birdy will not hear it; he deflects with a plain agreeable line and won't be drawn",
      turn: "Dez says it flat - that Birdy will never fly because he won't even ask, that he covers for the men who pass him - and Birdy just deflects and eats his same rote lunch, the marriage on autopilot behind it",
      subtext: "Dez loves him and can't watch it; Birdy can't let the truth in, because letting it in would mean he'd have to change, and changing is the one thing he hasn't the nerve for",
    },
  ],
  rules: [
    "Action lines = ONLY what the camera sees or the mic hears. No interiority, no naming feelings.",
    "THE THEME IS COWARDICE, never stated: the system is HONEST (it pays out on nerve, not talent), Birdy is gifted AND a coward, and his stuckness is his OWN, not the system's unfairness. Show it LIVE - he won't ask, he covers for Tanner, he deflects Dez. NO ONE says coward, nerve, brave, afraid, deserve, or unfair.",
    "NO human villain. The shit job comes from an APP / the impersonal system - there is no one to blame, which is the point. Tanner is NOT an antagonist; he's a green lead whose honest mistake Birdy quietly covers.",
    "Birdy NEVER confronts anyone; he deflects with a plain, agreeable, ordinary line and covers for everyone. Not bitter, not a victim.",
    "Dez is the one who names the cowardice - plainly, once, not a speech.",
    "The home token is a ROTE lunch, the same thing every day, the marriage on autopilot - cowardice at home too. Play it flat; do not sentimentalize it.",
    "Regional turboprop operation (Q400s) - real, literal ramp gear and procedure, said FLAT, never as a metaphor for anything.",
    "End on Birdy heading to the lav truck as the plane he'd have worked taxis out under someone else - plain, no self-pity, no image.",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=4)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: SCENE 1 (coward's morning) ===\n")
    Js.log(Cinema_Backends.readText(out))
    Js.log("\n=== VERIFY ===")
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
