/* THE FOUR OLDS v14 — ACT 2B/2C (scenes 25–34), engine-only, resumable.
   Run AFTER Act 2A: CLAUDE_STUDIO_BUDGET=35 node src/FourOlds_V14_Act2B.res.mjs */

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

let lita: Seed.voiceCard = {
  name: "LITA",
  who: "Lita Alvarez, 80s. Tito's grandmother; sewed a flag with fifty-one stars; her kitchen has saints on the wall and a Singer by the window.",
  register: "almost wordless; hands do the talking.",
  earnsEloquence: false,
  lexicon: "spare; a little Spanish.",
}

let dockworker: Seed.voiceCard = {
  name: "DOCKWORKER",
  who: "50s, Frontier badge, twenty years of lanyard tape on the clip. Works checklists for a living and knows exactly what a signature means.",
  register: "no lines unless unavoidable; the scene lives in his hands and eyes.",
  earnsEloquence: false,
  lexicon: "none needed.",
}

let scaleTech: Seed.voiceCard = {
  name: "SCALE TECH",
  who: "40s, integration floor scale operator, coffee thermos on the console. Nobody arranged anything with him. Nobody ever will.",
  register: "reads numbers aloud flat; writes what he writes.",
  earnsEloquence: false,
  lexicon: "procedural minimal.",
}

let jobs: array<job> = [
  /* ---- v25 THE SUITS -------------------------------------------------- */
  mk(
    "v14-25-suits",
    "sc25_suits.scene.txt",
    "INT. FEDERAL SURPLUS HOLDING, OUTSIDE LINCOLN - DAY",
    "The gift program concentrated every Apollo suit in the country into one federal warehouse — and the warehouse leaks exactly where the sim test proved it would. Four crates of 'degraded textile artifacts, non-flight-rated' roll out on a disposal-contractor lot sale and arrive at Stitch's hangar at the county airstrip, museum tags still wired to the wrists.",
    [V14Cast.mack, V14Cast.stitch, V14Cast.gunny],
    "the warehouse trick, run at scale; a restoration bench in a Texas hangar",
    "the regime gathered the sacred objects into one room to give them away — and thereby put them all behind one leaky door; the men do not steal the suits so much as file them out; and the restoration is a resurrection nobody calls one",
    [
      {
        who: "MACK",
        want: "four suits out of federal holding without one line of paper pointing home",
        wall: "the lot sheet has to say the opposite of what's true",
        turn: "the disposal listing does the work — DEGRADED TEXTILE ARTIFACTS, NON-FLIGHT-RATED, SOLD AS SCRAP — and a forklift loads history onto a rented flatbed between pallets of actual junk",
        subtext: "the sim was the rehearsal; this is the performance, and his hands don't shake on paper",
      },
      {
        who: "STITCH",
        want: "make fifty-year-old suits hold air",
        wall: "hoses gone stiff, seals gone flat, and no manual on earth",
        turn: "the bench montage — new hose runs, seals cut by hand, a soapy-water leak check crawling with bubbles that slowly stop; a patch going onto one knee; and the museum brass tags on the wrists LEFT ON, deliberate, wired where they hang",
        subtext: "the restorer's whole life was practice for four suits",
      },
    ],
    [
      "REQUIRED: the warehouse interior once — ranked shelving, orange-stickered seizures (a beat of recognition: trainers, tooling, town memorabilia, all of it), the suits on rolling racks with museum tags; the lot-sale paperwork INSERT; the flatbed out the gate past a guard who checks the sheet, not the load.",
      "REQUIRED at the hangar: the leak check with soapy water shown ONCE plainly (bubbles = leaks; bubbles stopping = sealed) — this is the audience's suit lesson, no other technical talk; the knee patch; Gunny handling the gloves like communion ware; the four suits standing on racks at the end, tags turning on their wires.",
      "NOBODY says the word 'steal' and nobody celebrates. Two pages maximum.",
    ],
  ),
  /* ---- v26 PELL'S INSPECTION ------------------------------------------- */
  mk(
    "v14-26-inspection",
    "sc26_inspection.scene.txt",
    "INT. TRI-COUNTY AUCTION BARN - DAY",
    "The Special Administrator inspects his program's containment contractor — announced, scheduled, with a photographer. Everything Pell looks at is legal. One tarped pallet in the room is not. Nobody's face is allowed to know which one.",
    [V14Cast.pell, V14Cast.mack, V14Cast.dutch, V14Cast.tito, V14Cast.joss],
    "a scheduled federal site inspection of a legal shop",
    "suspense in plain sight: the audience knows exactly what's under the one tarp and must watch a man with certification authority walk past it twice; Dutch's real preservation science becomes his own cover story, sentence for sentence",
    [
      {
        who: "PELL",
        want: "a clean inspection and a good photograph for the program",
        wall: "nothing — that's the horror; the shop gives him nothing to catch",
        turn: "he stops at the purge fittings ('Why does a box need plumbing?') and DUTCH answers with the truth he wrote years ago — fifty years vacuum-baked, the fabric rides flat, nitrogen so the dye doesn't oxidize on the way down — and Pell writes 'exceeds requirement' in the visit log and beams: the Accord loves this optic, retired hands preserving what they're retiring",
        subtext: "the cover story is bulletproof because it isn't a story",
      },
      {
        who: "JOSS",
        want: "to be anywhere else",
        wall: "he's the one standing nearest the tarped pallet",
        turn: "Pell's pen taps the tarp once in passing — 'And this?' — JOSS: 'Floor absorbent.' — Pell nods and moves on, and Joss does not exhale until the door",
        subtext: "two words, held together by nothing",
      },
    ],
    [
      "The visit is ANNOUNCED — open with the shop sanitized: federal drawings ONLY on the table, the binder nowhere, couches out of sight, one pallet that could not be moved in time under a tarp. Cricket is OFF-SITE by schedule (one Mack line: 'Dawes runs the co-op errands Thursdays.') — Pell must not meet the man from the farm here.",
      "Pell's register: his national role now — a photographer trails him; he poses once with the crate line; his praise recycles the insult ('heritage labor — exactly the optic the program wants').",
      "END: the visit log signed, the SUV out the gate — and the shop standing still three full seconds before anyone moves. Two pages maximum.",
    ],
  ),
  /* ---- v27 VESS TESTIFIES ------------------------------------------------ */
  mk(
    "v14-27-vess",
    "sc27_vess.scene.txt",
    "INT. SENATE HEARING ROOM - DAY",
    "The receiver threat, answered: Vess testifies that day-to-day authority is hers, that Hale is loud and his calendar is clean, and that the broadcast is in nine weeks — the Accord flies on schedule if the company stays in the hands that run it. Hale watches from a dark office with a draft post under his thumb, and backspaces it to nothing.",
    [V14Cast.vess, V14Cast.hale],
    "a Senate hearing about nationalizing Frontier through Unity Day",
    "she buys the mission's freedom by testifying to her founder's harmlessness — the deepest insult she'll ever pay him and the best protection he'll ever get; he deletes his own defense to keep her shield intact",
    [
      {
        who: "VESS",
        want: "keep a federal receiver out of the building through Unity Day",
        wall: "a Senator hunting a headline about her founder",
        turn: "she gives them Hale — 'Frequently. In colorful terms. I can provide dates.' … 'He is not built for quiet. He posts what he thinks. Usually before breakfast. You have his feed. Subpoena his drafts folder if you want the rest.' — laughter, open now — and the close: 'A receiver wouldn't know this company in six months. Your broadcast is in nine weeks. The Accord flies on schedule if the company stays in the hands that run it. Mine.' … 'Watch him as closely as you like. He's loud. His calendar's clean.'",
        subtext: "the testimony is a shield shaped like a betrayal",
      },
      {
        who: "HALE",
        want: "answer",
        wall: "answering proves the Senator right and burns her shield",
        turn: "the draft post under his thumb — 'My COO and the mother of my children just' — held, then backspaced to nothing; the phone face down; he watches the rest in the dark",
        subtext: "the loudest man in America chooses silence once, for her",
      },
    ],
    [
      "Keep the hearing under a page and a half; the panelist button after ('— when even Mira Vess won't defend him, what's left to defend?') lands over Hale's dark office.",
      "The 'mother of my children' fragment is the only reveal of their history — no other reference, no reaction shot, no follow-up anywhere.",
    ],
  ),
  /* ---- v28 SEND-OFFS -------------------------------------------------------- */
  mk(
    "v14-28-sendoffs",
    "sc28_sendoffs.scene.txt",
    "INT. DAWES BARN - NIGHT",
    "Danny finds his father packing a canvas kit bag off a handwritten list and says the bravest thing in the movie: none of the things. He's paid the county, he'll drive Thursday, he is a farmer. Alone afterward, Cricket's thumb catches a seam Peg sewed into the bag years ago — one dried zinnia, orange, thin as paper. In East LA, Lita folds fifty-one stars into a triangle and pins a saint inside.",
    [V14Cast.cricket, V14Cast.danny, V14Cast.tito, lita],
    "three goodbyes: a son's, a wife's from beyond, a grandmother's",
    "the film's whole emotional freight moves in objects — a paid tax bill, a hidden flower, a medal pinned where it will touch nothing but flag — because these are people who say it with logistics or not at all",
    [
      {
        who: "DANNY",
        want: "send his father off without making him carry a goodbye",
        wall: "everything he could say would be one of 'the things'",
        turn: "'I know what's in the barn, Dad. I've known a year. I figured you'd tell me when it mattered.' … 'I'm not going to say any of the things. About your age, or the law, or Mom. You'd just stand there and let me finish.' / 'I would.' — then, on his way out: 'County's squared, by the way. Paid it Tuesday.' / a beat / 'I'll pay you back.' / 'I know.' — and: 'You need a driver?' / 'Thursday. Four a.m. Dress like a farmer.' / 'I am a farmer.'",
        subtext: "the son protects the farm behind the man; the man lets him",
      },
      {
        who: "CRICKET",
        want: "pack the bag right",
        wall: "fifty years of habit says a sentence out loud — 'You'll want the—' — and stops mid-word, because there's nobody left in the room to finish it",
        turn: "his thumb catches a raised seam, old thread, three sides of small even stitches, not his own work — the pocketknife — one dried flattened zinnia, orange, gone thin as paper — he doesn't try to work out when she did it; he folds the canvas back over it and packs the rest of the bag around it",
        subtext: "she is coming along; nobody gets to know",
      },
      {
        who: "TITO",
        want: "carry the flag his grandmother made the way it deserves",
        wall: "neither of them says one word the whole folding",
        turn: "lengthwise, lengthwise, then the triangle folds tight and sharp from her end while he keeps the tension; the last fold tucks; she pins a small St. Christopher deep inside where it will touch nothing but flag, puts the triangle in his hands; he kisses her forehead and goes; through the window he sets it on the truck seat with both hands; she sits back down at the Singer and turns off the lamp",
        subtext: "Betsy Ross in East Los Angeles; the saint rides in the stars",
      },
    ],
    [
      "The kit-bag list is shown: logbook, slide rule, a zippo, a folded photograph he doesn't look at. The zinnia beat plays wordless and under thirty seconds of screen time — no flashback, no music cue on the page.",
      "Keep the three parts in this order: barn (Danny), bedroom (the seam), Alvarez kitchen (the flag). Under three pages total.",
    ],
  ),
  /* ---- v29 WEIGH-IN ------------------------------------------------------------ */
  mk(
    "v14-29-weigh-in",
    "sc29_weigh_in.scene.txt",
    "INT. FRONTIER AEROSPACE, CARGO INTEGRATION HALL - DAY",
    "Pell's program, Pell's cameras, Pell's random re-weigh — and four crates come up thirty kilos heavy. A scale tech nobody arranged taps cell three, watches the numbers stutter, and writes 'calibration drift' in the log. Pell files the sheet, walks the row once, and personally signs the inspection tag on LOT D for the photographer.",
    [V14Cast.pell, V14Cast.mack, V14Cast.joss, scaleTech],
    "a compliance re-weigh at cargo integration, resolved by one technician's pen",
    "the country's quiet defection reaches the regime's own floor: no conspiracy, no signal, one man reading a room and choosing a side with a log entry — and the enforcer's signature lands on the crate with a live man inside it, on camera, forever",
    [
      {
        who: "PELL",
        want: "a flawless certification event for the program's cameras",
        wall: "LOT A declares three-eighty and weighs four-eleven-two — then B, C, D, all heavy",
        turn: "'Thirty kilos over, times four crates. That's a hundred and twenty kilos of something, Mr. Boone.' — the cell check stutters, the tech writes drift, the corrected numbers pass — Pell reads the sheet twice, files it squared to the corner: 'Hm.' — and signs LOT D himself for the photo: INSPECTED — J. PELL",
        subtext: "the moment his career ends, staged as the moment it peaks",
      },
      {
        who: "SCALE TECH",
        want: "read numbers and drink his coffee",
        wall: "the numbers are true and the crate stencil says OLD IDEAS",
        turn: "he taps cell three with two knuckles — 411.9… 408.2… 413.5 — looks at the crate, the gauge, his clipboard, a long moment — then writes, reading aloud as he writes: 'Calibration drift, cell three. All four reads invalidated. Corrected tare applied. Within tolerance after correction.' — initials it, tears the copy, hands it up, and walks back to his console without looking at Mack",
        subtext: "Lexington, fought with a pen",
      },
      {
        who: "JOSS",
        want: "to keep breathing normally in the crane cab",
        wall: "his heart is in his ears",
        turn: "he sits absolutely still through the cell check; when the tech walks away Joss's hands go back to the levers one finger at a time",
        subtext: "the kid learns what the country is made of, one stranger at a time",
      },
    ],
    [
      "FULL PLAYING — this scene carries many required beats: give it two and a half to three screenplay pages. Every required beat gets its own staging and its air; per-line style stays terse; do NOT pad with invented business — length comes from playing each listed beat fully, never from filler.",
      "PELL AND THE KILOGRAMS: he reads the weights with continental reverence — the metric system is his sacrament (per his card) — and the comedy is a man savoring the very numbers that should end him.",
      "REQUIRED: the six crates on cradles, stencils huge on the flanks — LOT A — OLD IDEAS. LOT B — OLD CULTURE. LOT C — OLD CUSTOMS. LOT D — OLD HABITS. LOT E — SUPPLEMENTARY CONTAINMENT. LOT F — SUPPLEMENTARY CONTAINMENT.; Pell's photographer; 'Random re-weigh. Compliance is a rhythm, folks. Random means random.'; the declared-vs-actual reads spoken flat; Mack's one offered explanation ('Could be the couch upgrade. Archival spec revision come through in March—') cut off by 'Re-run it. Cell check first.'; the hall gone quiet enough to hear the air handlers.",
      "NOBODY arranged the tech. No look passes between him and Mack — the absence of the look is the point. Play his decision entirely in the pause before the pen moves.",
      "END on the tag in the holder — INSPECTED — J. PELL — and the shutter clicking.",
    ],
  ),
  /* ---- v30 LOADOUT ---------------------------------------------------------------- */
  mk(
    "v14-30-loadout",
    "sc30_loadout.scene.txt",
    "EXT. FRONTIER AEROSPACE, MAIN GATE - PRE-DAWN",
    "Four contractors in gray coveralls ride Danny's farm truck through the gate at 4 AM on a laminated work order with four names that aren't theirs. By sunrise, four old men are torqued into four crates, a dockworker has looked one of them in the eye and signed ALL CLEAR, and the stack rolls out the high door into the dawn.",
    [V14Cast.cricket, V14Cast.gunny, V14Cast.joss, V14Cast.tito, V14Cast.mack, V14Cast.danny, dockworker],
    "the infiltration: gate, servicing, climb-in, seal, checks, stack",
    "the Trojan horse closes around its riders one bolt at a time — and the machine's last honest checkpoint, a man with a wrench and a checklist, becomes the revolution's first sworn witness by writing two words",
    [
      {
        who: "GUNNY",
        want: "through the gate without a second look",
        wall: "a guard young enough to card him",
        turn: "'Y'all know where you're going?' / 'Son, we were servicing this bay before your daddy made the varsity.' — waved through; Danny's knuckles white on the wheel, eyes forward",
        subtext: "age as camouflage",
      },
      {
        who: "CRICKET",
        want: "last instructions given and the lid down",
        wall: "everything after the lid is other people's hands",
        turn: "kit bag between his knees; 'Tuesday net's at nineteen hundred, your frequency card's taped under the console. Don't improvise.' / JOSS: 'Copy. No improvising.' / 'And Joss. Thank your dad for the radio.' / a second — 'Fly good, old man.' — the lid comes down, torque gun, eight bolts, the purge hiss",
        subtext: "command handed to the next generation in two sentences",
      },
      {
        who: "DOCKWORKER",
        want: "clear his checklist",
        wall: "one amber latch flag on LOT D — procedure says open it",
        turn: "panel up: an old man packed in a molded couch, kit bag between his knees, eyes open, looking straight up at him — one second, two, three — the clipboard, the tag (INSPECTED — J. PELL), the man who does not blink — he resets the latch, seats the panel, and writes in block letters: LOT D — ALL CLEAR — and moves to LOT E without looking back",
        subtext: "the first shot of the war is a checkbox",
      },
    ],
    [
      "FULL PLAYING — this scene carries many required beats: give it two and a half to three screenplay pages. Every required beat gets its own staging and its air; per-line style stays terse; do NOT pad with invented business — length comes from playing each listed beat fully, never from filler.",
      "REQUIRED: the laminated order (VALLEY SALVAGE & SURPLUS — ARCHIVAL UNIT FINAL SERVICING, BAY 1); the climb-ins one by one off a purge cart, unhurried, Joss's dock crew moving around them seeing nothing; the knock checks down the line (two-two answered from B, C, D, A); Tito at LOT E setting the canvas triangle into a padded corner mount and checking it twice with two knuckles; the transporter taking the six out the high door, stencils catching the light; Mack signing the contractor crew OUT, four names, one pen; JOSS: 'Net's quiet. Two clicks if it stays that way.' / MACK: 'Go home. Sleep.'",
      "The dockworker beat is the scene's center: play it exactly as specified, no interiority, no music, the three seconds counted in action lines.",
    ],
  ),
  /* ---- v31 LAUNCH ------------------------------------------------------------------- */
  mk(
    "v14-31-launch",
    "sc31_launch.scene.txt",
    "EXT. FRONTIER LAUNCH COMPLEX, PAD 1 - NIGHT",
    "The gala toasts a rocket with no flag on its side — and on the way up, the heat peels the primer off in sheets and the flag underneath climbs into the sky in front of the entire planet. The booster flies home and lands wearing scorched colors. Four crates ride the shudder into orbit and answer each other two-two in the dark.",
    [V14Cast.marwani, V14Cast.cricket, V14Cast.buck, V14Cast.vess, V14Cast.pell],
    "launch night: a gala, an ignition, a paint job that doesn't survive American fire",
    "the regime's aesthetic — erasure to white — burns off at max heating in front of its own cameras; nobody explains it, nobody can repaint a rocket in flight, and the first crack of color in the film's release arrives before the ship even stages",
    [
      {
        who: "MARWANI",
        want: "the toast of his presidency",
        wall: "physics",
        turn: "'Tonight a rocket rises with no flag on its side. Think of that. Not conquest. Not pride. Repair.' — and behind him, on the barn-door screen, the climbing booster sheds its primer in burning sheets, stars and stripes coming through the scorch — a thousand flutes hang in the air, and he keeps smiling at a room that has stopped looking at him",
        subtext: "the whiteout does not survive fire; his signature image self-corrects on live TV",
      },
      {
        who: "CRICKET",
        want: "ride it",
        wall: "four g's on a seventy-nine-year-old chest",
        turn: "the hum becomes a shudder, dust ticks off the lid seam in the amber light; weight takes him deep into the molding, hand flat on the lid; the light dims under load — holds — comes back; then cutoff, and the kit bag floats up to the end of its lanyard",
        subtext: "fifty years of Tuesdays, cashed in ninety seconds",
      },
      {
        who: "BUCK",
        want: "watch her go",
        wall: "everything she's carrying is a secret from him",
        turn: "'There she goes in a minute. Ours. Whatever's riding her.' — and when the colors burn through the primer the whole diner comes off its stools at once, and nobody says a word, and nobody sits back down until staging",
        subtext: "the country recognizes itself before it knows why",
      },
    ],
    [
      "TENT-POLE SEQUENCE — one of the film's major set-pieces: play it at FULL LENGTH, three to four screenplay pages. Give every required beat its complete staging, every cutaway its own beats, every held moment its air. The style stays terse per LINE (one shot per paragraph), but the SEQUENCE is long — do not compress, do not summarize, do not merge cutaways.",
      "REQUIRED order: pad at night, vapor rolling down the hull; the gala (the Harmony Banner model under glass, Marwani working the room); mission control polls; crate D interior (hum → shudder); ignition — the night goes orange for a mile; THE PRIMER BURN on the climb, seen from ground cameras and the gala screen and the diner TV; staging; ONE later shot — the booster landed back on its pad, steam rising off scorched red white and blue, ground crew standing there looking up at it, NO tarp, NO dialogue, NO explanation, hold three seconds and cut; then orbit — engine cutoff, silence all at once, the bay dark, two knocks — pause — two knocks, answered from crate to crate, four amber lights burning in four sealed boxes, the Earth turning gold in the one small window.",
      "The primer burn is NEVER explained — not by an anchor, not by a character, not by an insert. It happens, the world sees it, the film moves on.",
      "Vess and Pell get one glass-row beat each at mission control, no dialogue between them.",
    ],
  ),
  /* ---- v32 CRATE LIFE / SHEN'S PALM ---------------------------------------------------- */
  mk(
    "v14-32-crate-life",
    "sc32_crate_life.scene.txt",
    "INT. HARMONY ONE, CARGO BAY - SHIP'S NIGHT",
    "Coast: morse jokes knocked through crate walls, Gunny's sock-footed service rotation swapping air canisters in the dark, a flashlight sweep that misses, a thermos passed through a vent hatch — and then Shen's audit stops at OLD HABITS, and a bare palm lies flat on the crate skin for eight seconds while a man inside holds his breath.",
    [V14Cast.gunny, V14Cast.cricket, V14Cast.dutch, V14Cast.stitch, V14Cast.brandt, V14Cast.lindqvist, V14Cast.shen],
    "life support as routine; two near-discoveries, one of them deliberate",
    "Shen's palm is the film's held card — he feels what he feels and writes NO ANOMALY, and the movie never says why; the audience gets a watcher who chooses not to see, or chooses to wait, and no relief either way",
    [
      {
        who: "GUNNY",
        want: "run the rotation to the schedule on the shelf edge",
        wall: "a live crew one bulkhead away",
        turn: "panel open from inside, out in thermal underwear and socks, canister swaps through the service ports, a penlight hooded in his fist — the thermos passed into D ('Obliged.' whispered from inside) — then the bay door seal hisses and he goes flat behind crate F, socks floating, while LINDQVIST's flashlight walks the stencils and a half-open vent hatch gets pushed flush with one finger",
        subtext: "a submariner's silence, weightless",
      },
      {
        who: "STITCH",
        want: "room service",
        wall: "there is no room service",
        turn: "knock-morse through the walls — Dutch pencils it letter by letter — INSERT the notebook: STITCH ASKS IF ANYONE ELSE'S HOTEL HAS ROOM SERVICE — Dutch knocks back slow and even — INSERT: TOLD HIM. TAKE IT UP WITH THE SPEC AUTHOR.",
        subtext: "morale, administered in taps",
      },
      {
        who: "SHEN",
        want: "a complete cargo audit, serial by serial",
        wall: "something at OLD HABITS that no instrument shows",
        turn: "he stops, head tilted a few degrees; drifts closer; reads the tag (INSPECTED — J. PELL); the gauge nominal; then one glove comes off, wedged under his arm, and his bare palm lies flat on the crate skin — five seconds — eight — inside, Cricket holds a breath all the way held — BRANDT at the door: 'Shen. Burn prep. Straps in twenty.' — the palm lifts, the glove goes back on, the stylus moves: LOT D — SEALS INTACT. PURGE NOMINAL. NO ANOMALY. — the lights bank down; from crate C, soft, two knocks; Cricket answers",
        subtext: "the held card: what the palm knew stays his",
      },
    ],
    [
      "CRATE ASSIGNMENTS, BINDING (the title mapping — every letter mentioned must comply): DUTCH rides crate A (OLD IDEAS); STITCH rides crate B (OLD CULTURE); GUNNY rides crate C (OLD CUSTOMS); CRICKET rides crate D (OLD HABITS). Gunny is the service-rotation man: he exits from and returns to crate C.",
      "Gunny's window beat is REQUIRED before he seals back in: both hands on the frame, the Moon filling a third of the glass, a long look, then back into crate C, panel shut, four amber lights in the dark.",
      "Shen's interiority is FORBIDDEN — no expression described beyond stillness; the eight seconds are counted in action lines; his tablet entry is the scene's only verdict.",
    ],
  ),
  /* ---- v33 THE OFFER --------------------------------------------------------------------- */
  mk(
    "v14-33-offer",
    "sc33_offer.scene.txt",
    "EXT. DAWES FARM, PORCH - DAY",
    "A washed SUV, an aide holding a phone flat on his palm, and the President of the United States asking a farmhouse if the Commander is home. The offer: the record amended, Apollo Eighteen with his name on the crew, flown status, the wings — if Unity Day passes undisturbed and he watches it from his porch, visibly. Danny: 'He's out.' Two hundred miles up, a morse key answers.",
    [V14Cast.marwani, V14Cast.danny, V14Cast.joss, V14Cast.cricket],
    "a presidential offer relayed to a porch, and its answer relayed from orbit",
    "the regime finally offers the one thing money can't touch — the record — to a man who is at that moment in low Earth orbit inside a box labeled OLD HABITS; the audience holds the dramatic irony the administration lacks, and the refusal comes home in cipher",
    [
      {
        who: "MARWANI",
        want: "a great American at peace with a new world, visible on a porch on the Fourth",
        wall: "the porch is empty and he doesn't know it",
        turn: "the offer, warm, complete — the record amended, Apollo Eighteen entered into the rolls with his name on the crew; flown status conferred by executive order; the title, the wings, the history — on one condition: Unity Day passes undisturbed, and your father watches it at home, on his porch, visibly — and the answer he gets is a screen door clapping",
        subtext: "he is negotiating with a house",
      },
      {
        who: "DANNY",
        want: "give away nothing",
        wall: "the President of the United States, warm as a salesman, on an aide's palm",
        turn: "'He's out.' … 'I'll pass it along if he calls.' / 'Mr. Dawes—' / 'You have a good day now.' — the screen door claps; the aide is left holding his own phone out to an empty porch",
        subtext: "Peg's read of the salesman, inherited whole",
      },
      {
        who: "CRICKET",
        want: "hear it all before answering",
        wall: "the word VISIBLE",
        turn: "Ridge Road, six-minute pass, Joss's key by red flashlight; in crate D the pad fills: RECORD AMENDED. FLOWN STATUS. EXEC ORDER. CONDITION: HOME ON PORCH UNITY DAY. VISIBLE. — he looks at the last word a moment, knocks two-two around the bay, and sends short and even; on the tailgate Joss reads it out: 'Tell him: you can't give back what you never had.' … 'There's more.' … 'Dawes out.' — and overhead one moving point of light crosses the dark, west to east, steady, and they watch it all the way to the horizon",
        subtext: "the temptation scene, passed through a key",
      },
    ],
    [
      "NO pension, NO money anywhere in the offer — the record and the wings only.",
      "Keep Marwani's lines inside his broadcast-warm register (triads permitted); Danny's total word count under twenty; the morse relay played procedural and unhurried.",
    ],
  ),
  /* ---- v34 TLI + SKY KING PAYOFF ------------------------------------------------------------ */
  mk(
    "v14-34-tli",
    "sc34_tli.scene.txt",
    "INT. FRONTIER MISSION CONTROL - NIGHT",
    "Go for the burn that can't be refunded. The push takes the bay, the straps creak, and Dutch boxes the figure twice: NO ABORT FROM HERE. Then, in the coasting dark, a knuckle taps a crate wall, and Cricket asks the only question left: 'Did he ever get to fly it again?' — 'He flew it. The rest of his life.' END OF ACT TWO.",
    [V14Cast.cricket, V14Cast.stitch, V14Cast.dutch, V14Cast.pell, V14Cast.vess],
    "trans-lunar injection, and one story finishing its work",
    "the myth upgrades its own ending exactly when the men need it to — the storyteller revises Sky King's fate from 'never again' to 'the rest of his life' and neither man remarks on the change; the door of no return closes with a smile in it",
    [
      {
        who: "DUTCH",
        want: "the burn nominal and the arithmetic honest",
        wall: "the arithmetic says there is no way home but forward",
        turn: "pencil in the margin — velocity, a time, an arc — the result boxed twice — INSERT: BURN NOMINAL. COAST 62 HRS. NO ABORT FROM HERE. — he looks at the boxed line a moment, then knocks two-two; answered from D, then B, then C",
        subtext: "the engineer files the doorway behind them",
      },
      {
        who: "CRICKET",
        want: "ask about the ending",
        wall: "he already knows the real one",
        turn: "'We've had the mic the whole trip, you know. You don't have to keep tapping at me.' / 'Yeah. Old habit. Fifty years of it, it's hard to shake.' — a strap picked at — 'Can I ask you something about Sky King.' / 'Go ahead.' / 'Did he ever get to fly it again?' — a second, then easy, a smile in it: 'He flew it. The rest of his life.' — Cricket's mouth pulls up at one corner; he works a thumb slow along one knuckle",
        subtext: "the first telling said never again; tonight the myth says otherwise, and both men let it",
      },
    ],
    [
      "CRATE ASSIGNMENTS, BINDING (every letter mentioned must comply): DUTCH is in crate A (OLD IDEAS); STITCH in crate B (OLD CULTURE); GUNNY in crate C (OLD CUSTOMS); CRICKET in crate D (OLD HABITS).",
      "REQUIRED control-room texture: the go/no-go poll brief; 'Harmony One, you are go for trans-lunar injection.' with the plain anchor 'Sixty-two hours to lunar orbit, gentlemen. Get some sleep.'; the track on the main screen bending out of Earth's neighborhood for good; Vess letting go of the rail one finger at a time; Pell capping his highlighter: 'Well. Nothing stopping it now.' — Vess doesn't answer him.",
      "End the scene, and the act, on Cricket's knuckle beat. Centered: END OF ACT TWO.",
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
    "ACT 2B DONE — " ++
    Belt.Int.toString(n - Belt.Array.length(failed)) ++
    "/" ++
    Belt.Int.toString(n) ++
    " ok" ++ (Belt.Array.length(failed) > 0 ? " | failed: " ++ Js.Array2.joinWith(failed, ", ") : ""),
  )
  Session.close()
}
main()->ignore
