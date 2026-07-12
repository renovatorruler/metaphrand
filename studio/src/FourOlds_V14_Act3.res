/* THE FOUR OLDS v14 — ACT 3 (scenes 35–44), engine-only, resumable.
   Run AFTER Act 2B: CLAUDE_STUDIO_BUDGET=40 node src/FourOlds_V14_Act3.res.mjs */

@module("fs") external existsSync: string => bool = "existsSync"

let dir = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/v14/"

type job = {seed: Seed.sceneSeed, out: string}

let mk = (id, file, slug, logline, cast, peshat, sod, beats, rules): job => {
  seed: {
    id,
    slug,
    logline,
    cast,
    layer: {peshat, sod},
    beats,
    rules: Belt.Array.concat(rules, V14Rules.common),
  },
  out: dir ++ file,
}

let streamer: Seed.voiceCard = {
  name: "STREAMER",
  who: "30s, gaming chair, ring light, veins out. Has spent fifteen years explaining that nobody ever went to the Moon. Today is the best day of his life, then the worst, then — within one broadcast cycle — the best again.",
  register: "caps-lock speech; certainty as a business model; never concedes, only re-theorizes.",
  earnsEloquence: false,
  lexicon: "conspiracy-streamer English.",
}

let lawyer1: Seed.voiceCard = {
  name: "LAWYER #1",
  who: "White House counsel's office, senior. Wants one clean legal instrument and there isn't one.",
  register: "fast, precise, appalled in a controlled way.",
  earnsEloquence: false,
  lexicon: "legal plain — must stay CIVILIAN-READABLE.",
}

let lawyer2: Seed.voiceCard = {
  name: "LAWYER #2",
  who: "White House counsel's office, the one who actually read the file.",
  register: "delivers catastrophe in complete sentences.",
  earnsEloquence: false,
  lexicon: "legal plain — civilian-readable.",
}

let jobs: array<job> = [
  /* ---- v35 LANDING ------------------------------------------------------ */
  mk(
    "v14-35-landing",
    "sc35_landing.scene.txt",
    "INT. FRONTIER MISSION CONTROL - DAY",
    "Harmony One lands on the Sea of Tranquility in front of every screen in America — and the touchdown slam that the world never sees racks the crates, bends a hinge, and hurts Stitch for real. He answers the sound-off late, through his teeth, and calls it nothing. In the lander's blind spot, four old men steal the backup rover.",
    [V14Cast.brandt, V14Cast.lindqvist, V14Cast.shen, V14Cast.cricket, V14Cast.dutch, V14Cast.stitch, V14Cast.gunny],
    "a Moon landing, an injury nobody reports, and a theft nobody sees",
    "the cost begins: the slam that will strand Cricket later (a bent hinge) and seat Stitch at the standoff (cracked ribs) both happen in one cut the world experiences as a perfect landing — the film pays consequences forward without ever underlining them",
    [
      {
        who: "BRANDT",
        want: "the landing, clean, on every screen",
        wall: "dust and the whole planet watching",
        turn: "'Contact light — engine stop.' — the dust settles on every screen in America; HARMONY ONE stands on the Sea of Tranquility, white, flagless",
        subtext: "the regime's perfect image, seconds from expiring",
      },
      {
        who: "CRICKET",
        want: "a full sound-off after the slam",
        wall: "nothing from Crate B",
        turn: "'Sound off.' — 'Here.' — 'Here.' — a beat — nothing — 'Stitch.' — nothing — 'Elmore.' — a wet, ugly cough: '…M'fine. Caught the rack with my side is all.' — GUNNY: 'Don't you go quiet on this net again, Colonel.' / 'Copy.' — and nobody says the word ribs, then or ever",
        subtext: "the injury is real, logged only in how he moves from now on",
      },
      {
        who: "GUNNY",
        want: "the freight moved before the rest cycle ends",
        wall: "a camera boom panning the site for Earth",
        turn: "behind the lander, in its blind spot, four crates open; four suited figures cross-load tarped bundles and latched cases onto the BACKUP ROVER, museum tags turning on their wrist cuffs; the last man aboard raps the fender two-two; the rover arcs out of shadow into sun, tracks unspooling across ground no one has touched in fifty years — and the dust it throws comes down all at once, in one place, unnaturally neat",
        subtext: "the backup crew takes the backup rover; the joke is never spoken",
      },
    ],
    [
      "FULL PLAYING — this scene carries many required beats: give it two and a half to three screenplay pages. Every required beat gets its own staging and its air; per-line style stays terse; do NOT pad with invented business — length comes from playing each listed beat fully, never from filler.",
      "REQUIRED: the touchdown INSIDE the bay played hard — the rack slams, straps take the load wrong, something in Crate B slides half a foot and stops hard (the injury), and a hinge on the cargo door takes a blow nobody clocks (ONE action line, no emphasis — it pays at the departure); the sound-off as beat 2; the rover theft as beat 3; BRANDT straightening from the solar array, turning out of pure habit, and staring north at a thin haze where nothing should move — three seconds, four — LINDQVIST (O.S.): 'Commander, panel four's ready for your sign-off.' — and Brandt turns back to the array: 'Base station nominal. Harmony One, beginning retrieval operations at first light tomorrow, per the program.'",
      "Stitch's injury register: old-man stoic, one cough, one line, cadence unchanged. FORBIDDEN: any character naming the injury's seriousness.",
    ],
  ),
  /* ---- v36 EMPTY SITES ------------------------------------------------------ */
  mk(
    "v14-36-empty-sites",
    "sc36_empty_sites.scene.txt",
    "EXT. SURVEYOR CRATER, APOLLO 12 SITE - LUNAR DAY",
    "The retrieval tour finds a socket hole where the first flag should be — then another at Fra Mauro. Fresh bootprints, wheel tracks running dead straight toward Tranquility. On Earth, the hoax industry has the best day of its existence: THERE WERE NEVER ANY FLAGS.",
    [V14Cast.brandt, V14Cast.lindqvist, V14Cast.shen, streamer, V14Cast.buck, V14Cast.earlene],
    "two empty flag sites, a global broadcast with nothing to retrieve, and the deniers declaring victory",
    "the third group gets its hour: the people who doubt American excellence read absence as proof, joy as vindication — while the men on the Moon read the tracks and say nothing on the open loop; the audience knows, the world doesn't, and the deniers dance in the gap",
    [
      {
        who: "LINDQVIST",
        want: "read the arrival statement off his cue card",
        wall: "there is nothing to arrive at",
        turn: "'We arrive as guests of history, to relieve it of its oldest burden—' — he stops reading. The flag is missing. A socket hole in the gray. Recent bootprints that aren't theirs. Wheel tracks in and out. / BRANDT: 'Harmony, Site One. The artifact is… not present.'",
        subtext: "the ceremony has no object; the script has no page for this",
      },
      {
        who: "STREAMER",
        want: "vindication",
        wall: "none — absence is his oxygen",
        turn: "'There were NEVER any flags! Fifty years of soundstage! They're on the Moon looking for PROPS, people! WAKE UP!' — chat avalanching, donations chiming",
        subtext: "the doubter of American excellence, feeding",
      },
      {
        who: "SHEN",
        want: "the possibility raised",
        wall: "Brandt",
        turn: "on the private loop: 'Commander. The possibility must be raised. If the artifacts were never — if the landings themselves were—' / BRANDT: 'Don't.' — silence — and Shen looks at fifty years of undisturbed prints ringing the socket, the new ones laid over them, crisp-edged and fresh",
        subtext: "even the Bloc's man can read footprints; doubt is a choice",
      },
    ],
    [
      "REQUIRED: the Apollo 12 descent stage bright gold, the ranked experiment packages, the socket hole; Fra Mauro the same — Lindqvist holding his cue card, not reading it; the diner beat — BUCK: 'Somebody took 'em.' / EARLENE: 'Took 'em where, Buck? It's the Moon.' — and a smile starting on Buck's face, slow; the pavilion beat — Marwani mid-remarks, the giant screen cutting to PLEASE STAND BY: UNITY DAY, an aide whispering while he keeps smiling at children; Brandt following the wheel tracks northwest with his visor: 'Whoever they are, they're not hiding their driving.'",
      "The hoaxer beat is an INSET (streamer feed) — once here, hard, gleeful. His mutation comes later; here he is pure joy.",
    ],
  ),
  /* ---- v37 THE REVEAL ---------------------------------------------------------- */
  mk(
    "v14-37-reveal",
    "sc37_reveal.scene.txt",
    "EXT. APPROACH TO TRANQUILITY BASE - LUNAR DAY",
    "The helmet-cams clear the rise before the men do, and every screen on Earth fills with COLOR: six flags in a ring, lawn chairs, a grill, a small flag with one star too many — and four crates standing on end, stenciled OLD IDEAS, OLD CULTURE, OLD CUSTOMS, OLD HABITS. At Roy's, somebody asks where Earl and them are — they're missing the damnedest thing that ever happened. Buck, looking at the screen: 'There they are.'",
    [V14Cast.brandt, V14Cast.lindqvist, V14Cast.shen, V14Cast.buck, V14Cast.earlene, V14Cast.gunny, streamer],
    "the world finds the flags — and the men guarding them",
    "the title lands: the four categories the regime taught a training room now stand on the Moon with four old men in front of them, alive; the town's cold shoulder turns to recognition in one line; and the deniers begin their mutation on live television",
    [
      {
        who: "BRANDT",
        want: "visual on the last site",
        wall: "a rise of gray ground",
        turn: "the chest camera clears the rise before any man's helmet — ON THE MAIN SCREEN: COLOR. — a controller stands so fast his headset cord snaps taut — six flags vibrant against the black, five in a wide ring, the first flag raised again at the center on its 1969 pole; lawn chairs; a squat grill; a card table; a cooler; four old men in fifty-year-old suits, three seated, one at the grill with a long spatula; behind them four emptied crates on end, stenciled faces out; beside the grill, on a workshop pole, a hand-sewn flag with fifty-one stars; a tripod camera with a red light, already live",
        subtext: "the withheld image, paid in one frame to the whole planet",
      },
      {
        who: "EARLENE",
        want: "everyone to see this",
        wall: "the ones who'd love it most aren't on their stools",
        turn: "'Where's Earl and them? They're missing the damnedest thing that ever happened.' — and BUCK, not looking away from four old suits on the screen: 'There they are.' — the diner goes quiet one beat, then comes off its stools all at once",
        subtext: "the apology for every ticket written, in three words",
      },
      {
        who: "STREAMER",
        want: "to have been right",
        wall: "the flags exist, in color, on camera",
        turn: "mid-rant he stops; his jaw works; dead air; chat avalanching — then, quieter, already rebuilding: 'Those flags are NEW, people. Look at the COLORS. They SWAPPED them—'",
        subtext: "deniers don't repent; they re-theorize — the mutation begins",
      },
    ],
    [
      "TENT-POLE SEQUENCE — one of the film's major set-pieces: play it at FULL LENGTH, three to four screenplay pages. Give every required beat its complete staging, every cutaway its own beats, every held moment its air. The style stays terse per LINE (one shot per paragraph), but the SEQUENCE is long — do not compress, do not summarize, do not merge cutaways.",
      "REQUIRED cutaways in order: mission control (the standing controller); Roy's (the Earlene/Buck beat exactly as written); the Unity Day pavilion — Marwani feels the crowd's eyes go past him, turns, and the screen behind him holds the ring of flags forty feet tall; the schoolchildren in the front row see flags and lawn chairs and a cookout — and they CHEER; the Frontier training-room watch party where the Module 7 FACILITATOR stands frozen with a paper plate, reading her own four words off the crate lids; a Warsaw tram stop where strangers packed around one phone start to clap.",
      "The panelist identification beat: '— I'm being told those suits are the museum pieces. From the gift program. They're wearing the gifts.' — one line, then on.",
      "End the scene on Gunny at the grill seeing the three Harmony suits on the rise and raising the spatula, unhurried, all the way up. Hold on that.",
    ],
  ),
  /* ---- v38 THE STANDOFF ------------------------------------------------------------ */
  mk(
    "v14-38-standoff",
    "sc38_standoff.scene.txt",
    "EXT. TRANQUILITY BASE - LUNAR DAY",
    "Brandt asks for a private channel and gets the whole world instead: 'We'll talk right here.' Who are you? — 'We're the backup crew. NASA never processed us out. We're still on the roster, son. This is our mission.' And from a lawn chair, because he cannot stand up: 'This here's our camp. Pack the fuck off.' In the counsel's office, four lawyers discover the fifty-year file — and that the only Americans on the Moon are the ones they want removed.",
    [V14Cast.brandt, V14Cast.cricket, V14Cast.stitch, V14Cast.gunny, V14Cast.shen, lawyer1, lawyer2],
    "the confrontation at the ring of flags, and the legal panic underneath it",
    "the standoff's real architecture: the world is the witness protection; the file is the shield; and the government that wants them gone discovers it outsourced its own hands — there is no interagency version of this, only an international incident or a surrender",
    [
      {
        who: "BRANDT",
        want: "protocol: identify, order, retrieve",
        wall: "an open loop and a man who won't leave it",
        turn: "'Switching to channel two. Let's talk privately, gentlemen.' / CRICKET, keying the OPEN loop: 'We'll talk right here. Whole world's listening anyway.' — then, formal, for the record: who are you and by what authority — CRICKET, standing out of his chair unhurried: 'We're the backup crew. NASA never processed us out. We're still on the roster, son. This is our mission.'",
        subtext: "authority meets a man with nothing to lose and a camera with everything to gain",
      },
      {
        who: "STITCH",
        want: "to stand up with the others",
        wall: "his ribs",
        turn: "he doesn't get up — from the chair, flat: 'This here's our camp. Pack the fuck off.' — and the not-getting-up reads to the world as contempt and to the crew as what it is",
        subtext: "the injury pays: the hardest line in the film is delivered seated because it has to be",
      },
      {
        who: "LAWYER #2",
        want: "one legal instrument that removes four men from the Moon",
        wall: "the file",
        turn: "'It's been signed off every quarter since 1972, by career staff, under four statutes. He's not a trespasser. As far as the United States government is concerned, that man is federal personnel standing on his duty station.' / LAWYER #1: 'Then send somebody up there and remove them.' / LAWYER #2: 'Who? The only Americans on the Moon are the ones you want removed.' — silence around the speakerphone",
        subtext: "the regime de-Americanized the mission on purpose, and the purpose just changed sides",
      },
      {
        who: "SHEN",
        want: "to test the line",
        wall: "four old men who come out of their chairs at once — three of them; Stitch stays seated and somehow that is worse",
        turn: "he steps toward the nearest flag; the men close between him and the colors, nobody signaling; GUNNY, tallest, looks down at him through the visor glass a long moment, then points the spatula, once, back at the Harmony rover — and the loop stays silent, and nobody moves, and the old men sit back down one at a time, and Gunny goes back to the grill and flips what's on it",
        subtext: "the first probe, answered without one word",
      },
    ],
    [
      "TENT-POLE SEQUENCE — one of the film's major set-pieces: play it at FULL LENGTH, three to four screenplay pages. Give every required beat its complete staging, every cutaway its own beats, every held moment its air. The style stays terse per LINE (one shot per paragraph), but the SEQUENCE is long — do not compress, do not summarize, do not merge cutaways.",
      "REQUIRED: Lindqvist's blurt ('Where did you even COME from?') answered with 'We came in the mail.'; the counsel's-office INSERT of the personnel screen — DAWES, E. — ASTRONAUT (ACTIVE), the fifty-year column of $0.00 entries; Brandt's close: 'Harmony copies. Control, Harmony requests instructions.'",
      "The lawyers' scene must NOT mention any annuity reactivation or check — the shield is the fifty-year file alone, plus the recorded fact that the President personally offered this man flown status last week (one line: 'And sir — the President offered him the wings on a recorded line Tuesday. We can't call him a fraud without calling the President one.').",
      "Keep the whole scene under four pages; the standoff beats spare, the lawyer beats fast.",
    ],
  ),
  /* ---- v39 THE WALL + STAND-DOWN ------------------------------------------------------- */
  mk(
    "v14-39-wall",
    "sc39_wall.scene.txt",
    "EXT. TRANQUILITY BASE - LUNAR DAY",
    "Geneva orders the retrieval. Brandt reaches for a flag and finds a color guard: 'You want 'em? Come through us.' The country erupts. And then the President of the United States comes up on the open loop himself and plays the last card — ordered to stand down, Commander — and Cricket answers it: 'You're not my commander, sir. NASA's civilian. Always was. That was the whole point of it.'",
    [V14Cast.brandt, V14Cast.cricket, V14Cast.gunny, V14Cast.marwani, V14Cast.shen, V14Cast.buck],
    "the wall at the flags, the country in the streets, and a presidential order refused on live television",
    "the film's thesis said out loud exactly once, by the right man, in the right grammar: America sent civilians — we came in peace — and a civilian cannot be commanded off his duty station by a king; the release valve opens nationwide",
    [
      {
        who: "BRANDT",
        want: "to follow the order without becoming the man who did",
        wall: "four old men, shoulder to shoulder, visors level",
        turn: "he plants his boots, reaches for the staff — the line forms in one motion, Cricket at center — his glove stops a foot short; GUNNY keys the open loop, slow and even, to every living room on Earth: 'You want 'em? Come through us.' — Brandt lowers his arm and steps back one step: 'Geneva, Harmony One. The site is… occupied by personnel asserting jurisdiction. Requesting political guidance.'",
        subtext: "a soldier discovering the order he won't obey",
      },
      {
        who: "MARWANI",
        want: "to end it with his own voice",
        wall: "the loop is open and the world is on it",
        turn: "patched in, warm as ever: the country needs this day whole; as your Commander in Chief I am ordering you to stand down — a beat of static — CRICKET: 'You're not my commander, sir. NASA's civilian. Always was. That was the whole point of it.' — and the loop hangs silent all the way to Geneva",
        subtext: "the king commands and nothing happens; the emperor's authority was a category error",
      },
      {
        who: "BUCK",
        want: "to answer",
        wall: "he's in a diner in Nebraska",
        turn: "his fist comes down on the counter once — 'U-S-A!' — and the diner takes it up, coffee cups rattling; the fairgrounds; a highway overpass with a bedsheet flag and a hundred horns; the Brooklyn loft where half the UNITY DAY shirts catch themselves chanting and some don't stop",
        subtext: "rage, released in the register it was stored in",
      },
    ],
    [
      "FULL PLAYING — this scene carries many required beats: give it two and a half to three screenplay pages. Every required beat gets its own staging and its air; per-line style stays terse; do NOT pad with invented business — length comes from playing each listed beat fully, never from filler.",
      "QUOTE THE DOORWAY: the color-guard wall must visually and rhythmically quote the barn-seizure stand from Act 1 — the same square posture, feet set, hands at sides, a man between the government and the thing he keeps — except this time nobody can move him. BRANDT is the decent man sent to do Wade's job, and unlike Wade, he refuses: where Wade stepped forward and took an arm, Brandt lowers his and steps BACK. Do not name any of this; the body remembers.",
      "REQUIRED: the Geneva voice ('Harmony One, this is Accord Coordination, Geneva. You are directed to proceed with retrieval of all six artifacts. Immediately, please.'); the Flight Director taking his headset all the way off rather than relay Washington's ACKNOWLEDGE; Gunny dealing four hands of cards onto the card table during the long static after Brandt's request for guidance.",
      "Marwani's stand-down must include the words 'Commander in Chief' so Cricket's answer lands as law, not attitude. Cricket's line is FIXED as written in the logline — no additions, nothing after 'the whole point of it.'",
      "The USA-USA montage: diner, fairgrounds (the county fair mid-swing, the restored carousel turning, every grown-up on their feet chanting at a phone), overpass, loft. Fast, four beats, done.",
    ],
  ),
  /* ---- v40 HALE ------------------------------------------------------------------------ */
  mk(
    "v14-40-hale",
    "sc40_hale.scene.txt",
    "INT. FRONTIER AEROSPACE, HALE'S OFFICE - DAY",
    "Alone with the wall screen, Magnus Hale watches the helmet-cam clear the rise — and comes up out of his chair laughing, ten years falling off him in one cut. Then the press room: he folds the prepared statement in half, and in half again. 'I can't read this one.' What follows is the sound of a man getting his voice back.",
    [V14Cast.hale, V14Cast.vess],
    "the founder's resurrection, in two rooms",
    "the flip the audience has waited two acts for: joy first, rage second — the compliance corpse comes alive at the sight of somebody using his rocket for the finest thing an American has done in fifty years, and the rage that follows is joy wearing work clothes",
    [
      {
        who: "HALE",
        want: "nothing — he has stopped wanting on camera",
        wall: "two years of reading hostage tape",
        turn: "the wall screen fills with the ring of flags — he stands slowly — then he LAUGHS, one bark, then really laughs, hands on his head, walking a circle in the dark office like a man whose team just won — THEN the press room: the page folded in half, and in half again, set down squared to the podium's edge — 'I can't read this one.' — straight into the cameras: 'Somebody used my rocket to do the finest thing an American has done in fifty years. You want somebody to punish for that? You want to nationalize me? Go. Fuck. Yourself.' — and walking off, past a reporter, not turning: 'Tell the commie he can eat shit.'",
        subtext: "the fire was never out; it was impounded",
      },
      {
        who: "VESS",
        want: "to watch it happen",
        wall: "none left",
        turn: "he passes her in the wings; they look at each other, one beat, two; he keeps walking; the corner of her mouth moves",
        subtext: "her shield did its job to the last day it was needed",
      },
    ],
    [
      "REQUIRED order: the office joy beat FIRST (no dialogue in it — the laugh is the dialogue), then the presser. The joy must be physical and undignified; the rage must be level and unhurried. Bedlam after — flashes, aides shouting the feed down and failing, because the feed is his.",
      "Then ONE beat: Roy's — frozen, then BUCK's short bark of a laugh and a slap on the counter; the COOK looks at the carbon meter on his gas line, and turns the flat-top burners up, all the way, all of them.",
    ],
  ),
  /* ---- v41 VESS & PELL --------------------------------------------------------------------- */
  mk(
    "v14-41-vess-pell",
    "sc41_vess_pell.scene.txt",
    "INT. FRONTIER AEROSPACE, VESS'S OFFICE - NIGHT",
    "Pell arrives with marshals for the mission override and leaves alone with the arithmetic of his own signatures. There is no override — the ship answers its crew. And every federal touchpoint the stowaways passed through has one name on it, and it is not hers.",
    [V14Cast.vess, V14Cast.pell],
    "the enforcer comes for a kill switch that does not exist and finds his own name instead",
    "no mastermind: she didn't build the caper and doesn't have to have — she only has to show him that the thread he wants to pull hangs him alone; the machine will need one name, and the machine's own paperwork has already chosen it",
    [
      {
        who: "PELL",
        want: "the override room and Mira Vess, in that order",
        wall: "'There is no override. The ship answers its crew. You built the compliance regime, Administrator. Nothing at this company moves without a signature. You know that better than anyone.'",
        turn: "the folder opens; the pages go down facing him one at a time — the re-weigh acceptance with the drift correction, countersigned; the site-inspection log, 'exceeds requirement,' signed; the inspection tag carbon, INSPECTED — J. PELL, personally executed, photographed — his own name, four times, in his own hand — 'You scheduled—' and he stops, because nobody scheduled anything, and that is worse",
        subtext: "the scapegoat discovers the paperwork has already voted",
      },
      {
        who: "VESS",
        want: "him to understand the arithmetic without her stating one threat",
        wall: "none",
        turn: "'Take it public, Administrator. All of it. Walk them through the program you ran, the cargo you certified, the shop you praised. Somebody's name ends up in the story. Count the signatures and tell me whose.' — she comes around the desk, past him, to the door: 'You wanted the company to cooperate. The company cooperated. The country didn't.' — and she walks out through her own marshals, unhurried, gone",
        subtext: "the refusal, not the author; she declines to hang for a regime she despises",
      },
    ],
    [
      "FORBIDDEN: any suggestion Vess orchestrated the caper — no scheduled inspections, no planted scale tech, no fuel-margin line. Her power in this scene is arithmetic and nerve, nothing else.",
      "END: Pell alone in her office, the pages lined up facing the empty chair; after a moment he sits down in front of them, in the visitor's chair, and doesn't touch anything.",
    ],
  ),
  /* ---- v42 LOOK UP ---------------------------------------------------------------------------- */
  mk(
    "v14-42-look-up",
    "sc42_look_up.scene.txt",
    "INT. FRONTIER AEROSPACE, HALE'S OFFICE - NIGHT",
    "Hale types two words and posts them: Look up. The porch lights answer — two, pause, two — fence line to fence line, ballpark to skyline, until the night side of the Earth is rippling coast to coast and seven visors on the Moon tilt back to watch the country wave.",
    [V14Cast.hale, V14Cast.danny, V14Cast.joss, V14Cast.stitch, V14Cast.gunny, V14Cast.buck],
    "one post, and the country answers the Moon with its lights",
    "the answer to the lights-out despair: the men decided the country was gone, and the country — asked to do exactly one thing — floods the dark with the crew's own two-two knock code, learned from nobody, everywhere at once",
    [
      {
        who: "HALE",
        want: "to hand the country the microphone",
        wall: "two words are all that fit",
        turn: "INSERT — THE PHONE: Look up. — posted; the phone face down on the desk",
        subtext: "the loudest man alive gets it exactly right by saying almost nothing",
      },
      {
        who: "DANNY",
        want: "to answer his father",
        wall: "a quarter million miles",
        turn: "the farmhouse porch light: off — on, on — off — on, on — Danny's hand on the switch, working it two-pause-two; Joss's truck headlights answer across the section land; farmhouse after farmhouse comes alight down the valley, some steady, some flashing, spreading fence line to fence line",
        subtext: "the knock code leaves the family and becomes the country's",
      },
      {
        who: "STITCH",
        want: "to deal the next hand",
        wall: "the Earth",
        turn: "'Y'all.' — seven visors tilt back; the night side is flickering, waves of light crawling across it, coastlines pulsing, whole seaboards going bright and dark and bright; nobody says anything for a long time; the cards hang in his glove, forgotten; at the grill, without looking away from the Earth, Gunny reaches over and turns down the burner",
        subtext: "the men who thought nobody was coming watch everybody arrive at once",
      },
    ],
    [
      "FULL PLAYING — this scene carries many required beats: give it two and a half to three screenplay pages. Every required beat gets its own staging and its air; per-line style stays terse; do NOT pad with invented business — length comes from playing each listed beat fully, never from filler.",
      "REQUIRED beats: Roy's register phone buzzing (Earlene reads it, shows the Cook); the ballpark groundskeeper throwing whole banks of tower lights on-off; the aerial — suburb grids pulsing, highways bright with flashers, the dark country filling porch by porch; the grid-control room — load curves spiking off the chart, the operator into his headset, disbelieving: 'That's more draw than the whole state used to pull on the Fourth. Where's this even coming from?'; Buck watching his own porch light blink through the diner window: 'Good.'",
      "The lights use the two-two rhythm — never explained, never sourced, never commented on.",
    ],
  ),
  /* ---- v43 THE BURGER + THE FOURTH ------------------------------------------------------------------ */
  mk(
    "v14-43-fourth",
    "sc43_fourth.scene.txt",
    "EXT. TRANQUILITY BASE - LUNAR DAY",
    "'…is that a burger?' The retrieval dies of laughter on live television, Brandt stands his crew down on the open loop, and a plated burger waits at an empty fourth chair for the Bloc's observer. Then Gunny reads John Adams — pomp and parade, bells, bonfires and illuminations — and three mortar shells break red, white, and blue-white over the Sea of Tranquility. 'It's Independence Day. God bless America.'",
    [V14Cast.gunny, V14Cast.cricket, V14Cast.brandt, V14Cast.lindqvist, V14Cast.shen, V14Cast.stitch, V14Cast.tito, V14Cast.buck],
    "a cookout ends a geopolitical crisis; a letter from 1776 gets its bells back; fireworks in vacuum",
    "release, paid in full and itemized: the burger answers the meat-shaming, the shells answer the ban, Adams' bells answer the silenced steeple, the ring of six answers the permits — every insult of Act 2 dies here in order, and nobody on the page knows they're keeping score",
    [
      {
        who: "BRANDT",
        want: "an exit that isn't a defeat",
        wall: "the smell has no smell in vacuum, but the sight of a burger coming off a sealed grill press does something anyway",
        turn: "on the open loop, unguarded: '…is that a burger?' — a controller snorts; the whole back row goes; forty languages caption it inside the hour — then, formal, every word chosen: 'Geneva, Harmony One. Site survey complete. There is nothing at Tranquility to retrieve. There is a color guard, on station, under national colors. Harmony One stands down.' — static from Geneva. Nothing else.",
        subtext: "the professional finds the true report and files it",
      },
      {
        who: "GUNNY",
        want: "to feed everybody, which is how he says everything",
        wall: "one man standing apart, arms folded",
        turn: "the long spatula extends a burger across three meters, steady, to Brandt — Lindqvist takes one laughing silently behind glass — and for Shen, who refuses, Gunny plates one anyway and sets it on the card table at the empty fourth chair, facing him. It sits there. Shen looks at it, and away.",
        subtext: "real kindness doesn't need the other man to take it",
      },
      {
        who: "CRICKET",
        want: "to say the two sentences",
        wall: "the whole planet listening",
        turn: "Gunny reads the Adams letter off a folded photocopy, slower and older — 'with shows, games, sports, guns, bells, bonfires and illuminations — from one end of this continent to the other. From this time forward. Forevermore.' … 'Two hundred and fifty years, and here we all are. One end of the continent to the other — and a little past it.' — the barn: 'Tito Alvarez. You built the tubes. Count us down.' — 'Tres… dos… uno.' — the first shell rides a hard straight spark and breaks RED, a perfect sphere, expanding and not stopping, no air to slow it, no sound at all; WHITE, rings within rings; and Cricket steps forward beside the first flag and keys the loop to the whole lit face of the Earth: 'It's Independence Day.' — a beat, the planet quiet — 'God bless America.' — the third shell breaks BLUE-WHITE dead center over the ring and swells until it takes the entire frame — WHITE OUT. Hold in the white. Silence.",
        subtext: "defiance, spoken as a blessing",
      },
    ],
    [
      "TENT-POLE SEQUENCE — one of the film's major set-pieces: play it at FULL LENGTH, three to four screenplay pages. Give every required beat its complete staging, every cutaway its own beats, every held moment its air. The style stays terse per LINE (one shot per paragraph), but the SEQUENCE is long — do not compress, do not summarize, do not merge cutaways.",
      "THE PLANT (one exchange, dry): LINDQVIST, mid-burger, worrying out loud in European — what Geneva will do to them, the inquiry, their careers — and STITCH waving it off with tall-tale certainty: they'll come around, always have. Zero evidence, total conviction. This plants the optimism the departure scene will cash.",
      "REQUIRED cutaways: the diner (the Cook plating burgers nobody ordered, waving off every wallet; Buck raising his cup to the TV); Warsaw howling; the Geneva coordinator's presser dying under open laughter; the White House press secretary gripping the podium through '— the situation has — evolved —'.",
      "Adams' bells line must be present and unabridged — it pays the silenced steeple, and NOBODY connects the two out loud.",
      "The shells: three, in flag order, each described in one paragraph, no sound in any of them.",
    ],
  ),
  /* ---- v44 DEPARTURE + CODA --------------------------------------------------------------------------- */
  mk(
    "v14-44-coda",
    "sc44_coda.scene.txt",
    "EXT. TRANQUILITY BASE - LUNAR DAY (DAYS LATER)",
    "Load-up. The cargo door the landing bent won't seat — the ascent can't fly with it open, the rendezvous window is minutes wide, and the fix is a man outside forcing it shut while the engine lights. Cricket's hands decide before his mouth does. He waves them off the Moon. Months later, a Tuesday net crosses a three-second lag, a grandson still doesn't believe the colors, and the first Ranger of Tranquility Base walks his ring of flags while the whole night side of the Earth waves back.",
    [
      V14Cast.cricket,
      V14Cast.dutch,
      V14Cast.stitch,
      V14Cast.gunny,
      V14Cast.brandt,
      V14Cast.shen,
      V14Cast.lindqvist,
      V14Cast.danny,
      V14Cast.buck,
      V14Cast.earlene,
    ],
    "a split-second sacrifice, a ride home with cold burgers, and a park with one ranger",
    "he doesn't choose to stay — he chooses to close the door, and staying is what closing it costs; an old man gives his life to his country in one motion and his country, for once, gives it back with interest: a job, a title, a Tuesday net, and a planet that answers his wave",
    [
      {
        who: "DUTCH",
        want: "the load-out to schedule, margins initialed",
        wall: "the cargo door hinge the landing bent — it won't seat, the latch light stays amber, and the ascent cannot fly with it open",
        turn: "the window math said out loud once, plain: the ship overhead comes around in minutes, not hours — this window or none with the air they have; the fix is outside, a pry bar and a man's weight holding the door seated while the latches run — and whoever holds it isn't aboard when it fires",
        subtext: "the engineer states the price; he doesn't assign it",
      },
      {
        who: "CRICKET",
        want: "his crew off the ground",
        wall: "one bent hinge and one man's worth of weight",
        turn: "no discussion — he's moving before Dutch finishes, bar set, boots planted, his whole weight on the door as the latches walk shut one by one — 'GO.' — the ascent engine lights, silent; the lander rises on its spark, up and over, dust settling in slow sheets — and Cricket, alone by the ring of flags, holds a salute until it's one bright point among the stars — then turns, and walks back to the flags, bootprints joining the hundreds already there",
        subtext: "a split-second decision fifty years in the making; nobody ever hears him weigh it",
      },
      {
        who: "STITCH",
        want: "a goodbye that isn't one",
        wall: "the hatch between them now",
        turn: "through the window, key clicks only: two — pause — two. And from the ground, on the fender of the parked rover: two — pause — two. — in the cabin, foil-wrapped burgers pass hand to hand, cold; Lindqvist holds one out to Shen, wedged beside him; Shen looks at it, takes it, unwraps it, and eats; nobody says anything about it; Dutch, chewing, starts a margin calculation on the foil",
        subtext: "the family grammar survives the vacuum; the Bloc's man eats the kindness at last",
      },
      {
        who: "DANNY",
        want: "the Tuesday net kept",
        wall: "months, and a quarter million miles, and a three-second lag",
        turn: "MONTHS ON — Roy's TV, C-SPAN, the vote board filling green — CHYRON: RESTORATION OF FLIGHT STATUS ACT PASSES 98-2. BACKUP CREWS OF THE APOLLO PROGRAM ENTERED INTO THE ROLLS. — BUCK: 'Who were the two?' / EARLENE: 'Does it matter?' / 'I'd like to know their addresses is all.' — a second chyron, later, under a photo of a man with a lanyard: ACCORD ENFORCEMENT INQUIRY NAMES SPECIAL ADMINISTRATOR; ADMINISTRATION 'COOPERATING FULLY' — the carbon meter gone off the diner's gas line, four screw holes where it sat; the barn — DANNY at the rig, headset on, a fresh spiral notebook with his own handwriting on the spine: 'Net's open. Tuesday, nineteen-oh-two local.' / 'Copy.' / 'Here.' / 'On time for once, son.' — a pause, static, long-traveled, three seconds of light-lag round trip — CRICKET, far, thin, clear: 'Tranquility. Reading you loud and clear.' — and STITCH, on the net: 'Boy believes we went now, mind. He just don't believe the flags kept their color. Says y'all swapped 'em.' — three seconds — CRICKET: 'Hm.' — Danny grins at the rig and writes the time in the log",
        subtext: "the vow has an heir; the argument never ends and the old men find that funny now",
      },
      {
        who: "CRICKET",
        want: "walk the perimeter",
        wall: "none, anymore",
        turn: "TRANQUILITY BASE NATIONAL HISTORIC PARK — EST. JULY 4 — RANGER STATION NO. 1. — a small hab off the original site, resupply pods beside it; the six flags in their ring, colors lit by Earthlight; over the hab, on its workshop pole, the fifty-one-star flag; CRICKET — suit patched at the knee, an arrowhead park patch on his chest — walks the ring, one firm pull at each staff; finishes at the 1969 flag and looks up; the Earth hangs full, night side facing; he raises one glove, all the way, and waves — a beat — a city flickers; then another; then whole coastlines, pulsing two-pause-two, the wave rolling westward across the dark, city by city, sea to sea — Cricket holds his glove up, and the Earth keeps answering, and the flags hold their colors in the black. FADE OUT.",
        subtext: "the wave, returned at planetary scale, forever",
      },
    ],
    [
      "TENT-POLE SEQUENCE — one of the film's major set-pieces: play it at FULL LENGTH, three to four screenplay pages. Give every required beat its complete staging, every cutaway its own beats, every held moment its air. The style stays terse per LINE (one shot per paragraph), but the SEQUENCE is long — do not compress, do not summarize, do not merge cutaways.",
      "BEFORE THE JAM — the optimism beat, staged in this order: (1) load-up underway, and the EUROPEANS do the European thing — contingency math out loud, the rendezvous window, the margins, worry as procedure ('if the door does not seat, we do not go home'); (2) the AMERICANS do the American thing — one old, plainly: don't worry, we'll get home — flat certainty, zero supporting evidence, the stowaways reassuring the licensed crew; (3) THEN the door jams — the European worry proven right — (4) and Cricket makes the American promise true anyway, with his body, from outside. The joke becomes the covenant; nobody names it.",
      "THE HATCH: seed it as the bent hinge from the landing (one callback action line), play the jam and the fix in under a page, and BAN all of the following: any speech from Cricket about staying, any argument, any farewell circle, the phrase 'Three's enough,' and any line where anyone names what he just did. Brandt gets ONE protest syllable ('Dawes—') answered by 'GO.' The goodbyes are the two-two clicks through the glass, nothing else.",
      "REQUIRED coda furniture: the pay-stub INSERT — DAWES, E. — RANGER (FIRST), TRANQUILITY BASE NATIONAL HISTORIC PARK, and a number, a real one, with digits — Danny putting it under a magnet on the fridge, square; the Pell scapegoat chyron exactly one beat, no scene; the Stitch grandson-denier exchange on the net verbatim as written in beat 4 — the flag-color question stays unadjudicated forever.",
      "END: FADE OUT, then centered: THE END.",
    ],
  ),
]

/* ---- runner ---------------------------------------------------------- */
let runOne = async (j: job) => {
  let path = Cinema_Backends.Path(j.out)
  let done_ = existsSync(j.out) && Write.verify(path) == Ok()
  if done_ {
    Js.log("SKIP " ++ j.seed.id ++ " (verified)")
  } else {
    let sc = await Write.writeScene(~seed=j.seed, ~maxTries=4)
    let _ = Write.emit(sc, ~txt=path)
    let sc2 = await Write.liftDialogue(~path, ~maxTries=3)
    let _ = Write.emit(sc2, ~txt=path)
    switch Write.verify(path) {
    | Ok() => Js.log("OK   " ++ j.seed.id)
    | Error(m) => Js.log("BAD  " ++ j.seed.id ++ " — " ++ m)
    }
  }
}

let main = async () => {
  let failed = []
  let n = Belt.Array.length(jobs)
  let rec go = async i =>
    if i < n {
      let j = jobs[i]
      switch await (async () => await runOne(j))() {
      | _ => ()
      | exception Write.WriteError(m) => {
          Js.Array2.push(failed, j.seed.id)->ignore
          Js.log("FAIL " ++ j.seed.id ++ " (gate): " ++ m)
        }
      | exception Session.SessionError(m) => {
          Js.Array2.push(failed, j.seed.id)->ignore
          Js.log("FAIL " ++ j.seed.id ++ " (session): " ++ m)
        }
      }
      await go(i + 1)
    }
  await go(0)
  Js.log(
    "ACT 3 DONE — " ++
    Belt.Int.toString(n - Belt.Array.length(failed)) ++
    "/" ++
    Belt.Int.toString(n) ++
    " ok" ++ (Belt.Array.length(failed) > 0 ? " | failed: " ++ Js.Array2.joinWith(failed, ", ") : ""),
  )
  Session.close()
}
main()->ignore
