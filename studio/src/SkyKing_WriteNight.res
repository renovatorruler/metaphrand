/* Act 1, scene 4 — home at night. A thin dinner, another rejection from the
   flight program he can't stop applying to, a worn-but-loving wife who gently
   wants him to let it go, his retreat into the simulator, and Maya covering him
   asleep at the console. The wife is RESIGNED, never a nag; his shame is the
   driver. Engine-written; the Sod stays submerged. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-night.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-night",
  slug: "INT. BIRDY AND MAYA'S HOME - NIGHT",
  logline: "Home to a thin dinner and another rejection from the flight program he can't stop applying to, Birdy can't give Maya the one thing she's quietly asking for - to let the dream go - so he retreats to his simulator, and she covers him where he falls asleep, still flying.",
  cast: [
    {
      name: "BIRDY",
      who: "a gentle baggage handler around 30 who flies a home simulator like a prayer and keeps applying to a flight program that keeps saying no; the same man who will later take the plane up",
      register: "gentle, warm, self-deprecating; deflects the rejection with a joke; lights up only at the simulator; never bitter",
      earnsEloquence: false,
    },
    {
      name: "MAYA",
      who: "Birdy's wife, around 30, worn thin by the money and by years of watching him chase a thing that keeps breaking him; she loves him and is tired of hoping, and tonight she hasn't the fight in her",
      register: "quiet, plain, weary; not a nag and never cruel; a woman whose belief has dimmed to patience, and whose patience is love worn down to its last thread",
      earnsEloquence: false,
    },
  ],
  layer: {
    peshat: "a couple's small, cold, money-tight home at night - a thin dinner, a rejection letter, a man at a simulator, a wife who covers him asleep",
    sod: "the weight a man carries - that the one thing he is good at is the one thing he'll never be allowed to do, that chasing it is failing his wife and their money, and that he'd rather sleep inside the dream than wake to a life where he is nothing; and her love, worn down to a comforter laid over a sleeping man",
  },
  beats: [
    {
      who: "BIRDY",
      want: "to come home to a thin, easy, ordinary evening and not let the day land",
      wall: "a denial letter from the flight program is on the table - applied again, turned down again - and the house is cold and tight with money",
      turn: "he sees the letter, makes light of it, and the dinner is small and quiet",
    },
    {
      who: "MAYA",
      want: "for him to let the flying go - to stop the applications, the money sunk in the sim, the hope that keeps breaking them both",
      wall: "the cockpit in his head is the only place Birdy isn't a failure; he can't put it down",
      turn: "she hasn't the fight tonight; the part of her that used to believe just quietly lets go, and she tells him she's going to bed and leaves him with it",
    },
    {
      who: "BIRDY",
      want: "the one place he is good - the cockpit he'll never have",
      wall: "it's a secondhand chair and a screen in the spare room, not a plane",
      turn: "he sets up the simulator, pulls the headset on, friends' voices crackling on the line, and flies - absorbed, happy, somewhere else - late into the night",
    },
    {
      who: "MAYA",
      want: "to be done resenting it and just love him",
      wall: "she finds him asleep at the console, headset still on, the sim still running",
      turn: "she stands a moment, then brings a comforter from the bed and lays it over him, switches off the lamp, and leaves the screen glowing",
    },
  ],
  rules: [
    "Action lines = ONLY what the camera sees or the mic hears. No interiority, no naming feelings.",
    "DRIVE IT WITH EVENTS and physical detail - the cold house, the denial letter, the thin dinner, the secondhand simulator rig, the headset, the friends' voices on the line, him asleep, the comforter. SHOW the poverty. Keep dialogue spare.",
    "Vary the length - a fuller, quieter home scene after the loud ramp, but not a stage play; let images carry it.",
    "MAYA is WORN and LOVING and RESIGNED - NOT a nag, NEVER cruel. She gently wants him to let the dream go because it's costing them, and tonight she is too tired to fight it; the light that used to believe in him has dimmed. She still loves him - she covers him asleep.",
    "BIRDY can't let the dream go - it's the only place he isn't a failure; he deflects the rejection with a joke, retreats to the sim, and falls asleep inside it.",
    "Show real POVERTY without a speech about it - worn rooms, unpaid bills, a small dinner, a secondhand rig.",
    "The flight-program rejection is the latest of several; the sim friends are off-screen online voices on the headset.",
    "Never name the buried theme; no one says dream, failure, provide, give up, or distance - it lives in the letter, the cold house, the headset, and the comforter.",
    "End on Maya laying the comforter over Birdy asleep at the glowing simulator.",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=3)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: NIGHT (scene 4) ===\n")
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
