/* ACT 2 #8 — THE RAINIER ASK (2026-07-02; SUPERSEDES sky-king-gift per user:
   "show Birdy asking to see Mount Rainier - some conversation between him and
   Bishop"). THE ENGINE: the first time in his life Birdy ASKS for anything.
   Act 1 built the disease (won't ask, never put in) - so the ask comes hard,
   sideways, half-retreated, apologized for. And BISHOP grants it with the
   machine's own dignity: a NORMAL CLEARANCE, like any pilot requesting a route
   deviation - and Birdy's readback comes back FLAWLESS (a life of listening on
   the ramp + the sim), which lights the FIRST STEP of the recognition staircase
   (the pilots clock the readback). The command net tugs the leash once and
   Bishop covers with the mandate's own words (keep him talking). The mountain
   carries the last of the light on its top (plants the Act 3 payoff line -
   the word 'pink' is RESERVED for Act 3; do not use it here). Richard Russell
   Law absolute. Engine-written. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-rainier.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-rainier",
  slug: "INT. Q400 FLIGHT DECK / SEATTLE APPROACH - RADAR ROOM - NIGHT (INTERCUT)",
  logline: "The airplane drones south with a fighter off each wing, and the big mountain stands off in the distance with the last of the evening light still on its top - and Birdy, a man who has never asked anybody for anything in his whole life, spends two minutes trying to get one small question out of his mouth. When it finally comes, Bishop answers it the way you'd answer any pilot: with a clearance. And the readback that comes down off that stolen airplane is so clean that the two fighter pilots look at each other across the dark.",
  cast: [
    {
      name: "BIRDY",
      who: "up in the dark with the mountain standing off his nose, wanting one thing and unable to ask for it - because he has never asked for anything; the want comes out sideways (you can see it real good from up here), gets half-retracted (I don't gotta, it's fine), and finally lands as the smallest, most apologetic question a hijacker ever asked. When the clearance comes back he answers it the way twenty years of listening taught him - flawless, automatic - and doesn't know what he just showed them.",
      register: "soft, plain, sad-but-cheerful, apologetic; the ask circles and stalls and half-dies before it lands; flat literal callouts; plain wonder, never poetry; NEVER a stated want beyond the mountain itself.",
      earnsEloquence: false,
      lexicon: "the mountain, the light on the top, the panel, fuel, said plain; the readback crisp and correct and unexplained.",
    },
    {
      name: "BISHOP",
      who: "the controller keeping the line alive; he hears the want under Birdy's circling long before the question lands, and he does the kindest thing the machine's language allows: he treats the ask like any pilot's request and grants it as a normal clearance - heading, altitude, direct the mountain - giving the overlooked man the dignity of an ordinary transaction. When the command net tugs the leash, he covers with their own order.",
      register: "flat, warm underneath, unhurried; the clearance delivered exactly like a routine one; the cover line flat and immovable.",
      earnsEloquence: false,
      lexicon: "the frequency, the clearance, headings and altitudes said plain and self-evident; keep him talking.",
    },
    {
      name: "DEACON",
      who: "the lead fighter pilot, holding formation off the Q400's wing; he hears the exchange on frequency, and it's the readback that gets him - clean, cadenced, professional - from a man who is not supposed to be able to do that.",
      register: "measured, serious, minimal; the surprise stays under the professionalism.",
      earnsEloquence: false,
      lexicon: "the wing, the readback, said flat.",
    },
    {
      name: "BANJO",
      who: "the wingman; younger, drier, the one who says out loud what both pilots are thinking - short, to Deacon, on their own frequency.",
      register: "dry, quick, quiet; one or two lines; the awe arriving as an aside.",
      earnsEloquence: false,
      lexicon: "the readback, where'd he get that, said flat between pilots.",
    },
    {
      name: "CONTROLLER",
      who: "the flat voice of the command net; tugs the leash once - what is he doing, where is he going - and takes Bishop's answer because there is nothing else on the table tonight.",
      register: "flat, procedural, brief; one exchange.",
      earnsEloquence: false,
      lexicon: "the track, the deviation, said flat.",
    },
  ],
  layer: {
    peshat: "the pilot asks the controller if he can go look at the mountain, gets cleared to it like any pilot would be, and his flawless readback surprises the fighter escort",
    sod: "a man who never asked for anything in his life - not a raise, not the chief slot, not one thing at the counter of the world - finally asks, at the end of everything, in a stolen airplane, for permission to look at a mountain; and the machine hunting him answers with the only mercy its language holds: a routine clearance, the dignity of being treated as exactly what he always should have been; his readback - perfect, automatic, learned through twenty years of listening from the ramp to a frequency that never once spoke to him - is the first crack of the recognition: the world beginning to see what was standing on the ground the whole time; and the mountain holds the last of the light like it waited for him; nobody names any of it",
  },
  beats: [
    {
      who: "BIRDY",
      want: "to ask - to go look at the mountain standing off his nose with the light still on it",
      wall: "a lifetime of never asking; the question circles, comes out sideways (you can see it real good from up here), and half-dies (I don't gotta, it's fine, forget it)",
      turn: "Bishop hears the want under the circling and leaves the door open - quiet, no push - and the smallest, most apologetic question a hijacker ever asked finally lands: could he maybe go over and look at it, if that's not - if that doesn't mess anything up",
      subtext: "the disease meeting the one desire bigger than it; asking permission of the machine that is hunting him; the mountain waiting with the last light on its top",
    },
    {
      who: "BISHOP",
      want: "to grant it the only way the machine's language can - as a normal clearance",
      wall: "he can't authorize anything real; the fighters are on the wing; the room is listening",
      turn: "he clears him to the mountain the way he'd clear any pilot - a heading, an altitude, direct - routine words, ordinary voice; and Birdy's readback comes down clean and cadenced and exactly right, automatic, like a man who's done it ten thousand times; the frequency goes quiet a second",
      subtext: "the dignity of the ordinary transaction - the kindest thing on the table; the readback showing what nobody ever looked at; Birdy not knowing what he just did",
    },
    {
      who: "BANJO",
      want: "to say the thing out loud - pilot to pilot, on their own frequency",
      wall: "it makes no sense: the man flying that airplane is supposed to be nobody",
      turn: "Banjo, dry, to Deacon: that readback - where does a guy like that get a readback like that; and Deacon, holding formation, gives it the only answer there is - nothing - while the Q400 banks gently toward the mountain and the two fighters bank with it",
      subtext: "the first step of the recognition staircase; the awe arriving as a puzzled aside between professionals; the escort turning WITH him - the machine following the man for once",
    },
    {
      who: "BIRDY",
      want: "just to look at it",
      wall: "the command net tugs the leash - what's he doing, where's he going - the machine wanting its category back",
      turn: "Bishop covers flat with their own order (they said keep him talking - he's talking) and the net takes it; and the mountain fills the windscreen with the last of the evening light still on the top, and Birdy says the plain thing, small, half to himself; end on the Q400 tiny against the mountain, a fighter off each wing, nobody saying anything",
      subtext: "mercy smuggled inside procedure; the gift in the open at last - the gift spent on the one thing he ever asked for; the light on the top planted for the very end; unresolved, no button",
    },
  ],
  rules: [
    "THE ASK COMES HARD - this is the engine: Birdy has NEVER asked for anything (Act 1 canon), so the question circles, lands sideways, half-retracts, and only finally arrives small and apologetic. Do NOT let him ask cleanly on the first pass. NOBODY names the pattern (no 'you never ask for anything' - the disease is never stated).",
    "THE CLEARANCE IS ORDINARY ON PURPOSE: Bishop grants the ask exactly like a routine pilot request - plain heading/altitude/direct-the-mountain language, self-evident to a lay ear (LEGIBILITY: no jargon soup; 'turn left, direct the mountain, keep what you've got' register). The dignity IS the mercy. He does not editorialize, does not make it a moment.",
    "THE READBACK BEAT (the first step of the recognition staircase): Birdy reads the clearance back FLAWLESSLY - clean, cadenced, automatic - and the page does not explain where it came from. The fighter pilots clock it on their own frequency: Banjo's dry aside (where does a guy like that get a readback like that / register), Deacon's silence. Keep it SHORT - an aside, not a discussion. The awe arrives puzzled, never stated as awe.",
    "THE COMMAND NET TUGS ONCE: the CONTROLLER asks flat what he's doing / where he's going; BISHOP covers with the mandate's own words - they said keep him talking, he's talking (register) - flat, immovable; the net takes it. One exchange only; mercy smuggled inside procedure; nobody names it.",
    "THE MOUNTAIN CARRIES THE LAST LIGHT ON ITS TOP - action lines only, plain and filmable (the evening light still on the top, the rest of it dark). THE WORD 'PINK' IS RESERVED for Act 3 - do NOT use it anywhere in this scene. Birdy's wonder line stays plain and small ('would you look at that' / 'the top's still lit' register), never poetry, never a Line.",
    "THE RICHARD RUSSELL LAW, absolute: nothing about coming down, an after, jail, a deal, or wanting to live/die - not stated, not implied, not joked - from him or at him. The mountain is the only want on the page.",
    "ACTION LINES ARE FULL SENTENCES, PRESENT TENSE. ORIENT every voice - the physical move or the frequency shift BEFORE the speaker (the pilots' aside is clearly on their own frequency, marked and oriented). The scene must play EARS-ONLY.",
    "INTERCUT flight deck and radar room; re-anchor returning characters lightly (Bishop at his scope; Deacon and Banjo holding off the wings). The SECOND CHANNEL stays physical: the mountain growing in the windscreen, the panel glow, the fuel number, the two fighters banking with him, Bishop's scope with the track bending toward the mountain.",
    "Sourced facts only; controllers and pilots stay flat real pros (redundant, plain, no ticking clocks, no quips); Birdy's callouts stay flat and literal under everything.",
    "END FAST and unresolved: the Q400 small against the mountain with the last light on the top, a fighter off each wing, nobody saying anything. No button.",
    "Kill every catalog tell: doubled openers, engineered refrains, appended-fact fragments, list drumbeats, cross-character mirroring, summarizing Lines, thematic telegraphing, stated/implied turns, manufactured stammers, parallel restatement. American vernacular. Recorded, not written.",
    "Voice-differentiate: BIRDY (soft, circling, apologetic; the readback suddenly crisp), BISHOP (flat, warm under, routine on purpose), DEACON (measured, minimal), BANJO (dry, quick), CONTROLLER (flat, brief).",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=5)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: THE RAINIER ASK (the first ask; the readback) ===\n")
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
