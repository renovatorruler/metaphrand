/* Act 1, scene 2 — the fuel-guy incident. Birdy's habit of checking the bond
   every time catches a real static hazard the hurried fueler missed; he kills
   the flow and fixes it, the fueler reports HIM for stopping the turn, and the
   supervisor writes him up. He's right and punished, and laughs it off.
   EVENT-driven with a build-up; engine-written; the Sod stays submerged. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-fuel.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-fuel",
  slug: "EXT. AIRPORT RAMP / FUELING THE Q400 - DAY",
  logline: "Birdy's habit of checking the fuel bond catches a static hazard the fueler missed; he kills the flow and fixes it, the fueler reports him for stopping the turn, and Birdy takes the write-up with a shrug.",
  cast: [
    {
      name: "BIRDY",
      who: "a gentle baggage handler around 30 who checks everything every time and quietly knows the gear better than his job lets on; takes a hit without bitterness",
      register: "gentle, warm, self-deprecating; careful and exact when it matters; absorbs the unfair write-up with a joke, never sour",
      earnsEloquence: false,
    },
    {
      name: "GUS",
      who: "a contract fueler, hurried and proud, sick of being checked by a ramper, cuts the corner on the bond to make his turn time",
      register: "gruff, impatient, defensive; not evil, just careless and stung when he's caught",
      earnsEloquence: false,
    },
    {
      name: "TANNER",
      who: "the ramp supervisor (from before), younger, metric-minded, sees only the turn clock and the delay, not who was right",
      register: "clipped, brisk, cold; cares about the number on the tablet",
      earnsEloquence: false,
    },
  ],
  layer: {
    peshat: "a regional turboprop being fueled on the ramp - a careful handler, a hurried fueler, a supervisor watching the turn time",
    sod: "the weight a man carries - that he is good and careful at a thing nobody credits, that doing the right thing gets him punished, and he swallows the injustice with a joke rather than let it land",
  },
  beats: [
    {
      who: "BIRDY",
      want: "to run his bond check on the fuel truck before the pump starts, the way he does every time",
      wall: "GUS is behind on his turns, sick of the checking, waves him off and starts the pump",
      turn: "Birdy checks anyway and sees the bonding clamp has shaken loose off bare metal - a static hazard with fuel already flowing",
    },
    {
      who: "BIRDY",
      want: "to stop the fueling and reset the bond before it becomes a fire",
      wall: "GUS won't stop - his turn time, his pride, 'it's always fine'",
      turn: "it comes to a head; Birdy hits the deadman and kills the flow, reclamps the bond to clean metal himself - hazard gone, but Gus's turn stopped cold in front of everyone",
    },
    {
      who: "GUS",
      want: "to not be the man who got shut down and corrected by a baggage handler",
      wall: "Birdy was right and the whole ramp saw it",
      turn: "Gus reports it up as Birdy interfering and blowing the turn; TANNER, who only sees the clock, writes BIRDY up for stopping a fueling - and Birdy, right and punished, makes a joke of it and goes back to the bags",
    },
  ],
  rules: [
    "Action lines = ONLY what the camera sees or the mic hears. No interiority, no naming feelings.",
    "DRIVE IT WITH THE EVENT and physical business - the bond check, the loose clamp, the pump, the deadman, the fuel, the shutdown, the tablet, the write-up. Show his competence by what he DOES; keep dialogue spare and functional, never a debate.",
    "Let the event BUILD - the ignored check pays off as a real hazard, then the injustice lands. Vary the rhythm; this one is meatier than the clock-in beat.",
    "GUS is hurried, proud, careless, defensive when caught - not a villain. TANNER sees only the turn clock and the delay.",
    "BIRDY checks every time (a careful habit others find annoying), he is RIGHT here, and he takes the unearned write-up with a shrug and a joke, never bitter.",
    "Real ramp/fueling procedure on a Q400 - bonding cable to bare metal, deadman switch, fuel hose, static.",
    "Never name the buried theme; no one says competent, unfair, or overlooked - it lives in the catch, the shutdown, and the write-up he didn't earn.",
    "End on Birdy taking the write-up and going back to work, easy about it.",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=3)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: FUEL (scene 2) ===\n")
    Js.log(Cinema_Backends.readText(out))
    Js.log("\n=== VERIFY ===")
    switch Write.verify(out) {
    | Ok() => Js.log("VERIFY OK")
    | Error(m) => Js.log("VERIFY FAILED - " ++ m)
    }
  } catch {
  | Write.WriteError(m) => Js.log("WRITE FAILED (gate):\n" ++ m)
  | Session.SessionError(m) => Js.log("SESSION: " ++ m)
  }
  Session.close()
}

main()->ignore
