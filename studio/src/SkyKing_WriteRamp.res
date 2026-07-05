/* Scene 2 — Birdy's ordinary world (the ramp). Written by the ENGINE from a seed
   I author (structure only: wants, walls, turns, voice cards, the buried layer).
   The masculine Sod stays submerged; no hand-typed dialogue or action. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-ramp.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-ramp",
  slug: "EXT. AIRPORT RAMP - DUSK",
  logline: "At the end of a long shift loading a regional turboprop, an ordinary baggage handler lets slip that he wants more than the ramp, and quietly swallows his friend's answer that men like them don't get it.",
  cast: [
    {
      name: "BIRDY",
      who: "a gentle baggage handler around 30 who loads other people's planes and has never flown one (the same man who will later take the plane up)",
      register: "gentle, warm, apologetic, self-deprecating; halting and plain; turns hurt into a joke; never sharp or bitter",
      earnsEloquence: false,
    },
    {
      name: "DEZ",
      who: "Birdy's ramp partner, a few years older, worn and settled into the job, kind underneath a dry resigned manner, has stopped wanting more",
      register: "dry, flat, unhurried, a little weary; kind but matter-of-fact; the voice of a man who made his peace with less",
      earnsEloquence: false,
    },
  ],
  layer: {
    peshat: "two ground-crew workers finishing a shift, loading bags into the belly of a parked twin-turboprop airliner as the light goes, talking the way coworkers do",
    sod: "the weight a man carries alone, that he is measured by the work, that he was supposed to rise and provide and hasn't, and that he can't say any of it, so he turns it into a joke",
  },
  beats: [
    {
      who: "BIRDY",
      want: "to get through the last of the shift well, careful with the bags, doing a thankless job right",
      wall: "it is heavy, invisible work and the day has been long",
      turn: "the ordinariness settles in; this is his life, and he is good at a thing nobody sees",
    },
    {
      who: "BIRDY",
      want: "to float, lightly, that he might put in for the open spot off the ramp",
      wall: "Dez, kindly, tells him it's as good as spoken for and that men on the ramp don't get moved up",
      turn: "Birdy hears it land and, instead of pushing or letting it show, makes a joke of it and keeps loading",
    },
    {
      who: "BIRDY",
      want: "to watch the plane he just loaded leave",
      wall: "he is on the ground and it isn't his to fly; it taxis out without him",
      turn: "he watches it go a beat too long, then turns back to the next cart of bags",
    },
  ],
  rules: [
    "The aircraft is a twin-engine Bombardier Q400 - the same kind of plane he will later take up.",
    "Action lines = ONLY what the camera sees or the mic hears. No interiority, no naming feelings.",
    "Keep it short - a single scene, a handful of exchanges.",
    "Never name the buried theme; no one says pressure, expectation, provide, worth, burden, or 'men like us' in those words - it lives only in what they do and joke about.",
    "Birdy turns hurt into a joke; Dez is dry and resigned, kind underneath.",
    "End on Birdy watching the loaded plane taxi out, then turning back to the bags.",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=3)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE THE RAMP SCENE ===\n")
    Js.log(Cinema_Backends.readText(out))
    Js.log("\n=== VERIFY ===")
    switch Write.verify(out) {
    | Ok() => Js.log("VERIFY OK")
    | Error(m) => Js.log("VERIFY FAILED - " ++ m)
    }
  } catch {
  | Write.WriteError(m) => Js.log("WRITE FAILED (gate never satisfied):\n" ++ m)
  | Session.SessionError(m) => Js.log("SESSION: " ++ m)
  }
  Session.close()
}

main()->ignore
