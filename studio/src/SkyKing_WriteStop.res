/* ACT 2 #5 — THE STOP (the breather; 2026-07-02). The world Birdy vanished from.
   A normal mid-shift on the Sea-Tac night ramp FREEZES - the ground stop - and
   the wrongness assembles in pieces: port-police lights crossing the field, the
   tower weird on the handhelds, Ward out of the office with a phone at his ear,
   somebody counting tails - one of theirs is missing. Mostly WORDLESS; the
   breather is physical. The quiet engine: DEZ KNOWS (he watched it lift off,
   doorway scene) and HOLDS THE NAME when Gus asks - protecting his friend from
   a machine he can already see coming. Ends on a port-police SUV rolling slow
   up the ramp toward the one kid who saw it. Low dialogue. Engine-written. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-stop.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-stop",
  slug: "EXT. SEA-TAC - NORTH RAMP - NIGHT",
  logline: "A normal night mid-shift on the ramp - bags on the belt, a fuel truck pumping, jets pushing back - and then the airport just stops. The ground stop comes over the PA and the handhelds, and nobody working the ramp knows why; the wrongness assembles in pieces - port-police lights crossing the field, the tower gone strange on the radio, Ward out of the office with a phone at his ear - until somebody counts tails and comes up one short. And Dez, who was out there when it lifted off, stands apart holding his radio and the only name that explains everything, and doesn't say it.",
  cast: [
    {
      name: "DEZ",
      who: "the young ramp agent who watched the airplane taxi and lift off and keyed his radio too late; Birdy's friend. He knows exactly what's missing and exactly who was near it, and he holds the name - not from a plan, from loyalty and dread; saying it hands his friend to whatever all these lights are. He stands a little apart from the crew the whole scene.",
      register: "quiet, short, hollowed out; deflects the one direct question; younger, hesitant; a kid holding something too big.",
      earnsEloquence: false,
      lexicon: "the ramp, the radio in his hand, what he saw said AROUND, never straight.",
    },
    {
      name: "GUS",
      who: "the fuel guy - older, Texan drawl, twenty years of pumping gas into airplanes; his truck stops mid-pump when the stop comes down and he reads the field the way old ramp hands do: by what the lights and the radios are doing. He's the one who counts tails.",
      register: "dry, unhurried, plain; reads the field out loud in small pieces; asks Dez the one straight question without pushing it.",
      earnsEloquence: false,
      lexicon: "the truck, the gas, the tails, the field, said flat and slow.",
    },
    {
      name: "WARD",
      who: "the ramp boss - fifties, worn, a windbreaker over the uniform shirt; comes out of the office mid-call with a phone pressed to his ear and stands looking at the south sky while somebody on the other end talks; whatever he's hearing, he doesn't share it. His face does the math the audience can't see yet.",
      register: "almost silent in this scene - half-heard phone fragments and one flat order; the weight stays under.",
      earnsEloquence: false,
      lexicon: "the phone, the roster, the yes-and-no of a man listening, said low.",
    },
  ],
  layer: {
    peshat: "the airport ground-stops, the ramp crew pieces together that one of their airplanes is missing, and Dez, who saw it go, doesn't say so",
    sod: "the world the invisible man vanished from, discovering the hole he left - the airport itself is the first thing that ever noticed him, and it noticed him by STOPPING; the men who worked beside him every night count tails to find what's missing because the missing thing was never the airplane, it was him, and nobody ever counted; and the one person who knows stands holding the name like a held breath - the first of everyone who will have to choose between the machine and the gentle man it's hunting; the lights crossing the field are the world's attention arriving at last, and it arrives as police",
  },
  beats: [
    {
      who: "GUS",
      want: "to finish the pump and get to his next airplane - a normal night",
      wall: "the ground stop comes down over the PA and the handhelds: everything holds, nobody moves metal - and no reason given",
      turn: "the ramp freezes mid-motion - the belt still running bags to nowhere, the pushback stopped half-turned, Gus's truck clicked off mid-gallon - and the crew stands looking at each other under the sodium lights",
      subtext: "the airport as a body stopping; the breather itself - quiet after three tight rooms; nobody knows why and everybody knows it's not weather",
    },
    {
      who: "GUS",
      want: "to read the field and figure out what kind of wrong this is",
      wall: "the pieces don't assemble from where the ramp stands: port-police lights crossing the far field, the tower frequency gone clipped and strange on the handhelds, Ward out of the office with a phone at his ear looking at the south sky and giving the ramp nothing",
      turn: "Gus starts counting tails down the row, slow, out loud - and comes up one short; the crew looks at the gap in the line where an airplane should be",
      subtext: "the old hand reading the field like weather; the missing thing found by counting - the airplane nobody watched, the man nobody counted; Ward's face doing math he doesn't share",
    },
    {
      who: "DEZ",
      want: "to be invisible - to not be asked",
      wall: "Gus asks him straight, without pushing: you were out that end - you see anything?",
      turn: "Dez doesn't give it - a deflection that says nothing and means everything - and Gus lets it sit; then headlights swing onto the ramp: a port-police SUV rolling slow up the line toward them, and Dez watches it come with the radio still in his hand; end on Dez looking south at the empty dark where it went",
      subtext: "the held name; loyalty ahead of the machine; the first of everyone who will choose between the system and the gentle man; the witness about to be found",
    },
  ],
  rules: [
    "THIS IS A BREATHER: LOW dialogue, mostly physical action - long stretches with no spoken line. After three tight interior scenes the film gets air. Do not fill the quiet with talk.",
    "ACTION LINES ARE FULL SENTENCES, PRESENT TENSE (Breaking Bad register). BANNED: verbless fragment piles.",
    "RE-ANCHOR the returning characters lightly on first mention (they were introduced in Act 1): DEZ (young, the radio still in his hand), GUS (older, Texan, the fuel truck), WARD (the ramp boss, windbreaker, the phone). A listener must place every voice.",
    "SOURCED FACTS ONLY: the ramp knows ONLY what reaches it on the page - the ground stop via the PA/handhelds (no reason given), the strangeness via the tower chatter and the port-police lights, the missing airplane via GUS COUNTING TAILS. Nobody says who took it; nobody knows; NOBODY names Birdy - not once in the scene.",
    "DEZ HOLDS THE NAME: when Gus asks him the one straight question (you were out that end - see anything?), Dez deflects - short, hollow, saying nothing that commits ('I don't know what I saw' register, or flatter). Gus does NOT push. The held name is the scene's engine and it stays held.",
    "WARD is nearly silent: phone fragments half-heard (yeah - no - say that again) and at most one flat order to the crew; his face and his stillness carry the math; the guilt stays buried (his reckoning belongs to a later scene).",
    "THE SECOND CHANNEL IS THE SCENE: the frozen belt with bags riding to nowhere, the half-turned pushback, the fuel truck clicked off mid-pump, the sodium light, the port-police lights crossing the far field, the tower voices clipped on the handhelds, the counting of tails, the SUV headlights at the end. The eye carries this scene.",
    "LEGIBILITY: plain words only - ground stop said plainly ('everything holds'), tails counted plainly; no ramp jargon that doesn't explain itself.",
    "NO summarizing, NO naming the event (nobody says stolen, hijack, or Birdy); the closest anyone gets is the gap in the tail count and Ward's face.",
    "END FAST: the SUV rolling slow up the line toward Dez, Dez looking south at the empty dark. No button, nobody comments.",
    "Kill every catalog tell: doubled openers, engineered refrains, appended-fact fragments, list drumbeats, cross-character mirroring, summarizing Lines, thematic telegraphing, manufactured stammers, parallel restatement. American vernacular. Recorded, not written.",
    "Voice-differentiate: DEZ (quiet, short, hollow), GUS (dry, slow, plain), WARD (low phone fragments, one order).",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=5)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: THE STOP (the breather; the ramp realizes) ===\n")
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
