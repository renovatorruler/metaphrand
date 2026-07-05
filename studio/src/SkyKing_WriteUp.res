/* ACT 2, beat 1 — UP / DISBELIEF (opens Act 2). The Q400 climbs into the dark with
   no flight plan and a ground crew's transponder code. An approach controller catches
   it, can't make sense of it, and finally raises the man flying it - who answers
   gentle, apologetic, oddly at peace, sorry for the trouble (the real Sky King
   register). As the tower grasps there's an untrained man alone in an airliner, the
   machinery wakes: somewhere, cold and procedural, jets are ordered up. This is the
   DISBELIEF BEFORE THE AWE - no recognition yet. Birdy dreamy/gentle; the war-room
   COLD and secondary; the story stays with him in the dark. Engine-written. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-up.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-up",
  slug: "INT. APPROACH CONTROL / Q400 FLIGHT DECK - NIGHT",
  logline: "The Q400 climbs into the dark with no flight plan and a ground crew's transponder code. In approach control, a controller catches it, can't make sense of it, and finally raises the man flying it - who answers gentle, apologetic, and oddly calm, like he's sorry for the trouble. As the tower grasps there's an untrained man alone in an airliner, the machinery wakes: somewhere, cold and procedural, fighters are ordered into the air.",
  cast: [
    {
      name: "BIRDY",
      who: "up in the airliner he took, dreamy and strangely at peace; gentle, apologetic, plain, a little lost; NOT a hijacker, NOT raging - a soft man who did one enormous thing and is polite about it. For the first time in his life he is calm and awake and himself.",
      register: "soft, plain, apologetic, unhurried; he talks to the controller like a man who feels bad for the trouble he's causing; his aviation lines are literal readbacks, but between them he's just a gentle guy, a little lost. NEVER a Line, never aviation poetry, never a quip.",
      earnsEloquence: false,
      lexicon: "his readbacks / the flying flat and literal; everything else plain and soft.",
    },
    {
      name: "TOWER",
      who: "an approach controller, trained-calm, then quietly thrown as the impossible unfolds on an ordinary shift; he does his job; controllers do not panic, but he is human under it.",
      register: "clipped professional ATC phraseology, going plainer and more human as it stops making sense; steady, careful; not panicked, not cold - a working professional meeting something that doesn't fit.",
      earnsEloquence: false,
      lexicon: "real radio phraseology, headings, altitudes, squawks - literal; then plain human between calls.",
    },
    {
      name: "SUPERVISOR",
      who: "the watch supervisor - the cold machinery waking; treats the unknown as a threat and gets fighters airborne; brief, procedural, secondary; NOT a villain, just the system doing what it does.",
      register: "flat, procedural, official; short; no drama, no speech - a phone call and an order.",
      earnsEloquence: false,
      lexicon: "procedure, the phone, the order - flat and official.",
    },
  ],
  layer: {
    peshat: "a controller catches an unauthorized airliner, raises the man flying it, and the watch supervisor orders fighters up",
    sod: "the gentlest man alive did the most enormous, irreversible, dangerous thing, and he is polite about it; up there, for the first time, he is calm and awake and himself; the world below can only read it as a threat and starts the machinery that will decide whether he lives - but the story stays with HIM, dreamy and apologizing in the dark, finally somewhere; the recognition that he is 'one of us' has not started - this is the disbelief before the awe",
  },
  beats: [
    {
      who: "TOWER",
      want: "to identify and raise the unknown airplane that just took off with no plan",
      wall: "it makes no sense - a ground transponder code, no flight plan, climbing, not answering",
      turn: "he works the phraseology, tries the frequencies, and finally gets an answer - a soft, unsure voice that is nothing like a pilot",
      subtext: "trained calm holding over rising unease; the impossible arriving on an ordinary shift; the moment he realizes this is not a normal airplane",
    },
    {
      who: "BIRDY",
      want: "to not be a problem - to explain himself gently - and, under it, just to fly",
      wall: "there is no version of this that isn't a catastrophe for everyone on the ground",
      turn: "Birdy answers plain and apologetic - sorry for the trouble, he isn't going to hurt anybody, he just wanted to fly it - dreamy and calm, and it lands on the controller as something stranger and sadder than a threat",
      subtext: "a soft man at peace for the first time, apologizing for the enormous thing; not raging, not a hijacker - which is exactly what makes it unbearable to the people below",
    },
    {
      who: "SUPERVISOR",
      want: "to treat it as a threat and get fighters airborne",
      wall: "nothing about the voice fits a threat - but procedure is procedure",
      turn: "the order goes out, cold and procedural - scramble the alert - and jets are coming, while Birdy flies on, gentle, not knowing or not minding",
      subtext: "the machinery waking, kept COLD and secondary; the consequence that will bear down; the story stays with the gentle man in the dark, not the war room",
    },
  ],
  rules: [
    "Action lines = ONLY what the camera sees or the mic hears. No interiority, no naming feelings.",
    "BIRDY is DREAMY, gentle, apologetic, plain, oddly at peace - NOT a hijacker, NOT raging, NOT quipping. He talks to the controller like a soft man sorry for the trouble (the real Sky King register). His aviation lines are literal readbacks; between them he's just a gentle guy, a little lost. NEVER a Line, never aviation poetry.",
    "The controller (TOWER) does NOT panic - trained calm going plainer and more human as it stops making sense. Real ATC phraseology, then a real person under it.",
    "The scramble / military machinery is COLD, PROCEDURAL, SECONDARY - a brief phone call and an order, NOT a war-room set piece; NO villain, NO heroics; the story stays with Birdy in the dark.",
    "THEME never stated: no one says brave, coward, free, alive, peace, or 'a threat that isn't one.' The gentleness landing as stranger-than-a-threat shows only through the plain exchange.",
    "AMERICAN vernacular throughout (US ATC, US idiom) - no British forms.",
    "Recorded, not written: plain, procedural, real radio; no music-cue prose, no appended-fact tags, no flat echoes, no clichés, no speeches.",
    "Do NOT resolve it - this is the disbelief BEFORE the awe (recognition comes later). End on the fighters ordered up and Birdy flying on, gentle, in the dark.",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=5)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: UP / DISBELIEF (Act 2 opens) ===\n")
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
