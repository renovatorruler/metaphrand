/* Act 1, scene 3 — the cockpit pretend. Alone in a parked Q400 at the end of
   his shift, Birdy slips into the captain's seat and flies an imaginary
   departure he knows cold (from his sim) - until a captain catches him and he's
   a ramper in the wrong seat again. Mostly wordless; the LONGING shown, then
   punctured. Engine-written; the Sod stays submerged. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-cockpit.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-cockpit",
  slug: "INT. PARKED Q400 FLIGHT DECK - NIGHT",
  logline: "Alone in a parked plane at the end of his shift, Birdy slips into the captain's seat and flies an imaginary departure he knows by heart, until a pilot catches him and he's a ramper in the wrong seat again.",
  cast: [
    {
      name: "BIRDY",
      who: "a gentle baggage handler around 30 who has flown a thousand departures on a home simulator and knows the flows cold, but has never sat at real controls; caught somewhere he doesn't belong, he apologizes and deflects",
      register: "gentle, warm; alone, he is quiet and absorbed and sure-handed; caught, he goes shy and self-deprecating, makes a small joke, never argues",
      earnsEloquence: false,
    },
    {
      name: "WARD",
      who: "a Q400 captain back to grab something he forgot; finds a baggage handler in his seat and sees only a man out of place",
      register: "flat, territorial, unimpressed; not cruel, just done with his day and protective of his flight deck; never sees that the ramper actually knew the flow",
      earnsEloquence: false,
    },
  ],
  layer: {
    peshat: "an empty parked turboprop at night; a ramp worker alone in the cockpit a few minutes before a pilot comes back",
    sod: "the weight a man carries - that the one thing he is truly good at is the one thing his life will never let him do, so he does it alone in an empty cockpit, in his head, where no one can take it from him - until someone does",
  },
  beats: [
    {
      who: "BIRDY",
      want: "a minute alone in the captain's seat of the parked plane after the shift",
      wall: "he's a ramper; the flight deck is not his and he knows it",
      turn: "he climbs the airstair, ducks into the dark cockpit, and lowers himself into the left seat; for a moment it's his",
    },
    {
      who: "BIRDY",
      want: "to fly it - to run the departure he knows by heart from the sim",
      wall: "the plane is dead and dark and none of it is real",
      turn: "hands on the power levers, the yoke, the flap handle, he runs the flow and murmurs the calls under his breath; he is exact, he is sure, and for a moment he is not on the ground at all",
    },
    {
      who: "WARD",
      want: "to grab the headset he forgot and go home",
      wall: "there is a baggage handler sitting in his seat working the controls",
      turn: "WARD orders him down; Birdy startles, apologizes, makes a small joke, and climbs out past him - a ramper in the wrong seat again, the dream clicked off like a switch",
    },
  ],
  rules: [
    "Action lines = ONLY what the camera sees or the mic hears. No interiority, no naming feelings.",
    "DRIVE IT WITH ACTION - the climb up the airstair, the hands moving over the power levers and yoke and switches, the murmured departure calls, the catch. The LONGING is shown by what he does, NOT said. Keep dialogue very spare; most of this scene is Birdy alone.",
    "Show that Birdy KNOWS the departure flow cold - real Q400 procedure, real callouts under his breath (power set, rotate, positive rate, gear up) - so the ache is that he could do it and never will.",
    "Let the alone-time BREATHE before the catch; this scene is quiet and mostly wordless, a change of pace from the loud ramp.",
    "WARD is a tired captain, territorial about his flight deck, dismissive - not cruel; he never registers that the ramper actually flew the flow right.",
    "BIRDY is caught, goes shy, apologizes, deflects with a small joke, and climbs down; never bitter.",
    "Never name the buried theme; no one says dream, longing, or 'not your place' - it lives in the empty seat, the murmured flow, and being told to get down.",
    "End on Birdy back down on the ramp, the dark plane behind him.",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=3)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: COCKPIT (scene 3) ===\n")
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
