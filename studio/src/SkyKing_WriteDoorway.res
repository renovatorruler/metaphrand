/* DOORWAY 1 — HE TAKES THE PLANE (closes Act 1). Dusk, the ramp emptying out. With
   nothing left in his life, Birdy does not clock out - he boards the cold Q400 he
   loads every day, takes the captain's seat, runs the flows he has only ever run in
   the dark of a spare room, and this time the props turn. Dez sees it moving, too
   late. He rolls out and takes off. THE FIRST BRAVE ACT - dreamy, calm, NO rage, NO
   villain; the calm IS the bravery. Point of no return. Mostly wordless - the camera
   carries the turn; the only words are the flat sim-flows, now real. Engine-written. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-doorway.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-doorway",
  slug: "EXT. AIRPORT RAMP - DUSK",
  logline: "Dusk, the ramp emptying out. Birdy, alone with the cold Q400 he loads every day and a life with nothing left in it, does not clock out. He climbs aboard the empty airplane, takes the captain's seat, and runs the flows he has only ever run in the dark of a spare room - and this time the props turn. Dez sees it moving where nothing should move and it is already too late. Birdy rolls out under the last light and takes off, and for the first time in his life he has dared.",
  cast: [
    {
      name: "BIRDY",
      who: "the gifted coward at the end of the numb glass; for the first time not afraid, because there is nothing left to lose. Calm, dreamy, sure-handed - the home-sim competence finally real. He does NOT rage; he is almost peaceful. The first brave act of his life.",
      register: "near-silent; the only words are the flat flight flows muttered to himself, the SAME callouts from the home sim, steady and low - literal, never poetry, never a declaration; he does not narrate himself or the moment.",
      earnsEloquence: false,
      lexicon: "the flows, the panel, the callouts, the runway said flat and literal - flaps, bugs, power, rotate; NEVER a metaphor for a feeling.",
    },
    {
      name: "DEZ",
      who: "Birdy's friend from the ramp, the one who kept telling him to walk in and ask; crossing the emptying ramp at dusk, he sees the Dash moving where nothing should move and understands, too late.",
      register: "wordless or almost - a name, or one keyed radio call; no speech, no chase; the human cost and the world beginning to wake.",
      earnsEloquence: false,
      lexicon: "flat, literal - the tail number, the ramp; if he speaks at all it is plain and small.",
    },
  ],
  layer: {
    peshat: "at dusk, alone on the emptying ramp, Birdy boards the parked Q400, starts it, and takes off",
    sod: "this is the first brave thing he has ever done: freed by having nothing left to lose, the gifted coward finally dares - not in rage but in a dreamy calm, running the real airplane on the flows he only ever dared in the dark where no one could see; the point of no return, the lie of his smallness beginning to die; and the one man who kept telling him to reach watches him reach at last, catastrophically, too late to stop",
  },
  beats: [
    {
      who: "BIRDY",
      want: "(the buried will finally surfacing) to stop being nothing - to do the thing",
      wall: "every habit of his life says clock out, drive home, be small; a normal man stops here",
      turn: "at the end of shift, his last task in his hands, he looks at the cold Q400 - and instead of clocking out he sets the task down and walks to the airplane",
      subtext: "the glass is full; the passing-over was the last drop; there is nothing left to lose and so, for the first time, nothing left to be afraid of - the calm is the bravery, not rage",
    },
    {
      who: "BIRDY",
      want: "to start it - to fly the real one",
      wall: "the point where it is still stoppable; the flight deck of a real airliner he has no clearance and no business in",
      turn: "he climbs aboard the empty airplane, takes the captain's seat, runs his hands over the panel, and starts the flows - the same flat callouts from the home sim, muttered low and steady - and the engines spin up and the props begin to turn",
      subtext: "the gift, finally real and out of the dark; the dreamy competence; the sim was always this, rehearsed a thousand nights where it couldn't cost him anything - now it can, and he does it anyway",
    },
    {
      who: "BIRDY",
      want: "to go",
      wall: "the world about to wake to it - someone will see",
      turn: "Dez, crossing the empty ramp, sees the Dash moving where nothing should and stops dead; Birdy releases the brakes and the Q400 rolls out under the last light, no clearance, no plan; it swings onto the runway and lifts off into the dusk; the point of no return is behind him",
      subtext: "the first brave act, complete; the man who kept telling him to reach watches him finally reach, too late; the lie of his smallness dies as the wheels leave the ground",
    },
  ],
  rules: [
    "Action lines = ONLY what the camera sees or the mic hears. NO interiority: NEVER name what Birdy feels (brave, calm, afraid, free, done, alive). The transformation is shown ONLY through behavior - the hesitation, the hands, the steadiness, the airplane moving.",
    "MOSTLY WORDLESS: the ONLY dialogue is Birdy's flat flight flows muttered to himself - the SAME callouts we heard in the home sim (flaps, bugs, power, rotate), literal and low, a quiet rhyme; NO speeches, NO declaration, NO one naming the moment. Do NOT explain the callback.",
    "DREAMY, calm, Drive-register - NOT a frantic heist. Birdy is unhurried, peaceful, sure-handed; the awe is in the calm. NO rage, NO revenge (he is NOT angry at Ward or anyone), NO villain, NO music-cue prose.",
    "COMFORT IS THE HORROR → the first brave act: taking the plane is the first genuinely courageous thing he has ever done, precisely because he has nothing left to lose. Show the calm of a man past fear. NEVER state it.",
    "Sustain 'he could still stop' until the point of no return (brakes off / the roll), then it is irrevocable. The TURN is the airplane moving under its own power with him at the controls.",
    "DEZ sees the plane move where nothing should and freezes - wordless, or a name, or one keyed radio call; NOT a chase, NOT an action-movie beat. Small and secondary - the human cost, the world starting to wake.",
    "Recorded, not written: plain, mundane, filmable; the wet apron, the beacon, the dusk light; NO aviation poetry, NO metaphor, NO Line, no appended-fact tags stapled on, no flat echoes.",
    "Do NOT show the whole flight - end AS he commits and lifts off (Act 2 is the flight). Close on the wheels leaving the ground / the Dash climbing into the dusk - plain, dreamy, done. The end of Act 1.",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=4)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: DOORWAY 1 (he takes the plane) ===\n")
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
