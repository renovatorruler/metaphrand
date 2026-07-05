/* The SKY KING cold open, written by the ENGINE from a seed I author. I supply
   structure — wants, walls, turns, voice cards, the buried layer, the rules. The
   warm Session writes the sentences; the gate judges them; emit leaves a receipt.
   Nothing here is a line of dialogue or a line of action typed by me. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-cold-open.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-cold-open",
  slug: "EXT. SKY - DUSK / INT. Q400 COCKPIT - CONTINUOUS",
  logline: "A man flies a stolen airliner alone at sunset, taken with the view and talking to a controller on the radio, until fighter jets reveal they are escorting him; asked to land, he gently refuses.",
  cast: [
    {
      name: "BIRDY",
      who: "ground-crew worker, around 30, took an empty airliner up alone and has never really flown",
      register: "gentle, warm, apologetic, self-deprecating; halting and plain; never sharp, wry, or knowing",
      earnsEloquence: false,
    },
    {
      name: "BISHOP",
      who: "an air traffic controller talking him through it over the radio, calm, has handled hard nights",
      register: "steady, kind, unhurried; careful with his words; a reassuring professional",
      earnsEloquence: false,
    },
  ],
  layer: {
    peshat: "a man alone in a cockpit at sunset, taken with the view, making small talk with a man on the ground while fighter jets ride his wings",
    sod: "the weight a man carries alone, to hold it together and provide and never break down or burden anyone, so he jokes and marvels instead of saying he is drowning",
  },
  beats: [
    {
      who: "BIRDY",
      want: "to stay up here a little longer and share how beautiful it is",
      wall: "he is alone in the sky and the man he is talking to is stuck on the ground",
      turn: "the wonder lands but it only underlines how alone he is",
    },
    {
      who: "BIRDY",
      want: "to treat the fighter jets on his wings as company rather than a threat",
      wall: "they are armed and they are there to bring him down",
      turn: "he speaks of them almost tenderly, unbothered, as if they had always been there",
    },
    {
      who: "BISHOP",
      want: "to get Birdy to start bringing the plane down while there is still light",
      wall: "Birdy is not ready to let go of this",
      turn: "Birdy refuses, gently, not as defiance but because he cannot end it yet",
    },
  ],
  rules: [
    "The aircraft is a twin-engine Bombardier Q400; the man flies it alone.",
    "Bishop is only a voice over the radio; every Bishop line is (RADIO); he is never seen.",
    "Birdy wears ground-crew clothes and an orange hi-vis vest.",
    "Keep it short, a cold open, a handful of exchanges.",
    "End on Bishop asking him to bring it down and Birdy gently refusing, then one final image.",
    "Never name the buried theme; no one says pressure, expectation, provide, burden, or breaking down.",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=3)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE THE SCENE (not me) ===\n")
    Js.log(Cinema_Backends.readText(out))
    Js.log("\n=== RECEIPT ===")
    Js.log(Cinema_Backends.readText(Cinema_Backends.Path(outPath ++ ".receipt.json")))
    Js.log("\n=== VERIFY (engine's own output) ===")
    switch Write.verify(out) {
    | Ok() => Js.log("VERIFY OK")
    | Error(m) => Js.log("VERIFY FAILED — " ++ m)
    }
  } catch {
  | Write.WriteError(m) => Js.log("WRITE FAILED (gate never satisfied in maxTries):\n" ++ m)
  | Session.SessionError(m) => Js.log("SESSION: " ++ m)
  }
  Session.close()
}

main()->ignore
