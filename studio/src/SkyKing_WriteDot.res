/* ACT 2 #3 — THE DOT v3 (2026-07-02): four user notes on v2.
   (1) INTRODUCE every character on first appearance (name + concrete strokes +
   function — this is Bishop/Price/Supervisor/Kemp's first scene in the film).
   (2) SOURCED FACTS ONLY: v2's "a ground worker took an airliner" was an
   unsourced leap — Birdy never said who he was. Now the TOWER CALL sources the
   aircraft ("they watched one of the airline's turboprops taxi out and go"),
   and Kemp's phone sentence carries only what the room knows, including "we
   don't know who he is." The who-is-he job stays with the Reyes ground scene.
   (3) PRIORITY QUESTIONS: after contact, Bishop's professional reflex - who
   else is on board / are YOU the one flying it. Birdy: it's empty, just him
   (the audience learns he hurt nobody).
   (4) THE HIJACK BEAT: Price says the word once; the Supervisor kills it on the
   facts (hijacked from who? he's alone); it's banned from the phone; the
   bureaucracy lands on its euphemism. Implied, never adopted.
   All v2 gold protected (the writeup line, the federal handoff, the draft-aloud,
   Birdy's lines, the self-evident hail). Engine-written. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-dot.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-dot",
  slug: "INT. SEATTLE APPROACH - RADAR ROOM - NIGHT",
  logline: "A slow night in the radar room, and the DHS liaison is one signature away from ending his quarterly visit where, as always, nothing happened - when a blip with no ID and no altitude crawls off the Sea-Tac ground onto Bishop's scope. The tower watched one of the airline's turboprops taxi itself out and go. The voice that finally answers the hail is soft and sorry and alone up there - he kind of did a bad thing - and the only man in the room whose job this is has to get on a phone and say, in plain words that have to hold up, exactly what they know and what they don't.",
  cast: [
    {
      name: "BISHOP",
      who: "an approach controller deep into a slow night shift - fifties, cardigan under the headset, reading glasses pushed up on his head, the steadiest voice in the building. He notices the blip because noticing is the whole job, and he is the first person on earth to hear the man in the stolen airplane. After contact his reflexes are a real controller's: who else is on that airplane, and am I talking to the one flying it.",
      register: "flat, procedural, redundant the way real controllers are; plain words for technical things; tense under control as it turns; his calm never cracks, it just tightens.",
      earnsEloquence: false,
      lexicon: "the scope, the blip, the frequency, the field, souls on board asked plain; coffee and the night shift.",
    },
    {
      name: "PRICE",
      who: "the controller at the next position - thirties, sleeves shoved up, a night-shift slouch; his own traffic still in his ear. The blip isn't his and he says so; he gets pulled in despite himself, and he's the one who finally says the word everyone is stepping around - once.",
      register: "dry, minimal, a little bored until it stops being boring; blurts the hijack word once, low, and takes the correction.",
      earnsEloquence: false,
      lexicon: "his own traffic, his sector, not-mine, said flat.",
    },
    {
      name: "SUPERVISOR",
      who: "the shift supervisor - sixties, gray, reading glasses on a lanyard, a man twenty years of night shifts have made unhurriable. He was signing out Kemp's visit paperwork when the night broke. He kills the hijack word the moment it lands - on the facts, not on feelings - and hands the thing to the one person in the room it legally belongs to.",
      register: "flat, economical, decides fast without drama; the correction is procedure, not a speech; plain words.",
      earnsEloquence: false,
      lexicon: "the checklist, the paperwork, the phone, the facts said plain and heavy with nothing.",
    },
    {
      name: "KEMP",
      who: "the DHS liaison - forties, a government sport coat, a visitor badge clipped crooked, a thin folder of signed forms - at the end of his scheduled quarterly night visit, jacket over one arm, one signature from going home; nothing has ever happened on one of his visits and he likes it that way. When it turns real he becomes the man who has to CALL IT IN with his own name on it, and his problem is that the true sentence has a hole in the middle of it: they don't know who the man is.",
      register: "civilian-plain, a little bureaucratic, dry; asks what things mean because he has to write them down and say them out loud to a duty officer; drafts his phone sentence half-aloud; lands on the bureaucratic category with a straight face; never panicked, just a man very aware his name is on this.",
      earnsEloquence: false,
      lexicon: "the forms, the badge, the watch floor, the duty officer, the writeup; civilian words for airplane things.",
    },
    {
      name: "BIRDY",
      who: "the voice on the frequency; a gentle man who just did the one enormous thing and cannot even confront a radio call - the first hails get his keyed mic and his breathing and nothing else, because answering is confronting; when words finally come they are apologetic and small, like a kid owning up; asked the priority questions, he gives the two facts that matter plainly: the airplane is empty, and it's him flying it.",
      register: "soft, apologetic, halting; a keyed mic and a breath before words come; the 'kind of did a bad thing' register - plain, no drama, no demands, nothing wanted; never bitter, never clever.",
      earnsEloquence: false,
      lexicon: "plain small words; sorry; the airplane said like a borrowed thing; just me up here.",
    },
  ],
  layer: {
    peshat: "a controller notices an unidentified airplane off the Sea-Tac ground, the tower reports a stolen turboprop, the soft voice on the radio apologizes and says he's alone, and the DHS liaison has to phone in exactly what they know and don't",
    sod: "the most overlooked man alive finally does the one unmissable thing, and the machine's first true act on meeting him is a CLASSIFICATION problem - the word everyone reaches for (hijacking) is wrong on the facts, because he took nothing from anybody but the ground, and the true sentence has a hole where a name should be; the coward's disease survives inside the brave act (he cannot answer a hail); and the two facts he volunteers when asked - the airplane is empty, it's just him - are the gentlest facts a threat has ever reported about himself; nobody in the room knows they just heard the gentlest voice of their lives",
  },
  beats: [
    {
      who: "BISHOP",
      want: "to account for the blip - it came off the Sea-Tac ground and somebody must be working it",
      wall: "nobody is: Price isn't, nothing's filed, no ID and no altitude on it - and behind them KEMP is signing the last form of a visit where nothing ever happened",
      turn: "the coordination line rings and Price takes it: the TOWER WATCHED IT GO - one of the airline's turboprops, the big twin-prop, taxied out with nobody cleared and took off; the blip has a type now and still no name; Bishop reaches for the frequency",
      subtext: "the job is noticing; the fact entering the room the only way facts do - somebody saw it; the outsider one signature from going home",
    },
    {
      who: "BISHOP",
      want: "an answer from the hail - identify yourself, say what you're doing",
      wall: "the mic KEYS - a breath, an engine droning behind it, no words - and the click off; the second try gets the same",
      turn: "a keyed mic with breathing in it is worse than silence; Bishop calls the supervisor over - and Kemp drifts up behind the chairs, jacket over his arm, asking whether keyed-and-silent is a thing that happens, because it decides what goes in his writeup",
      subtext: "the man who cannot confront anyone cannot even answer a hail; the outsider's pull is his own paperwork; nobody says the word yet",
    },
    {
      who: "SUPERVISOR",
      want: "to hear it himself and put the thing in a category",
      wall: "the third hail gets the category no checklist has: a soft, apologetic voice - sorry to bug you, he kind of did a bad thing, the airplane's not really his to have",
      turn: "Bishop's reflex takes over - the priority questions, plain: who else is on the airplane with you, and is it you flying it - and the soft voice gives the two facts that matter: it's empty, it's just him up there; the room absorbs that the seventy-six seats behind him are empty",
      subtext: "the machine meets a sorrow; the gentlest facts a threat ever reported about himself; the audience learns he made sure to hurt nobody - never said as virtue, just answered as fact",
    },
    {
      who: "PRICE",
      want: "to name the thing everyone is stepping around",
      wall: "the word is wrong on the facts, and the supervisor is standing right there",
      turn: "Price says it low - a hijacking - and the supervisor kills it flat on the facts: hijacked from who, he's alone on the thing; keep that word off the phone; and when Kemp says the watch floor will ask him what it IS, the answer is the flattest true category anyone can find - a stolen airplane; Kemp writes the euphemism",
      subtext: "the word implied and refused in the same breath; the machine's need for a box meeting a man no box fits; no drama in the correction - just facts",
    },
    {
      who: "KEMP",
      want: "to say the right sentence to the watch floor - his name is on this call, and it has to hold up",
      wall: "the true sentence has a hole in the middle: they know the what (one of the airline's turboprops, empty, one man flying it) and not the WHO - and the plain version sounds made up",
      turn: "he builds it half-aloud, dials, and says exactly what they know and what they don't - somebody took one of the airline's turboprops off Sea-Tac, it's empty, one man on the radio flying it, and we don't know who he is; the plain words land in the room like they're hearing it for the first time too; end on the blip crawling out over the black of the water",
      subtext: "the translation the machine forces on itself; the hole where a name should be - the overlooked man, unidentified even now; the DHS thread lit",
    },
  ],
  rules: [
    "INTRODUCE EVERY CHARACTER on FIRST appearance, in the action line: name + two or three concrete strokes (age, look, what they're doing) that make their function legible - 'KEMP - forties, a government sport coat, a visitor badge clipped crooked, a thin folder of signed forms - the DHS liaison at the end of his quarterly visit.' Bishop, Price, the Supervisor and Kemp ALL get this (it is their first scene in the film). A listener must never meet a voice they can't place.",
    "SOURCED FACTS ONLY: nobody states a fact that didn't enter the scene on the page. The aircraft type enters ONLY via the tower call (Price takes it, relays it plain: they watched one of the airline's turboprops taxi out and go - the big twin-prop). NOBODY concludes who is flying it - not 'a ground worker', not 'an employee', nothing; Kemp's phone sentence must include that they do not know who he is.",
    "PRIORITY QUESTIONS after contact, Bishop's professional reflex, plain: who else is on the airplane with you - and - is it you flying it, just you. BIRDY's answers are the two facts: it's empty / just me up here (apologetic, plain, never performed as virtue).",
    "THE HIJACK BEAT, exactly once: PRICE says the word low ('a hijacking' register); the SUPERVISOR kills it immediately ON THE FACTS - hijacked from who, he's alone on the thing - and bans it from the phone call; KEMP, deadpan, needs a category for the watch floor and gets the flattest true one: a stolen airplane. The word never appears again; nobody summarizes the moment; no poster line.",
    "ACTION LINES ARE FULL SENTENCES, PRESENT TENSE (Breaking Bad register): subject + finite verb every time. BANNED: verbless fragment piles.",
    "ORIENT EVERY VOICE: the physical move comes BEFORE the speaker. The scene must play EARS-ONLY.",
    "AUDIENCE LEGIBILITY: dejargonize at the source - plain words for technical things ('no ID on him, no altitude, just the blip'; 'nobody filed a plan for him'). Budget: at most TWO flavor terms in the whole scene, each self-evident in its own line. Price's clearance to his own airplane is allowed. KEMP is NOT a question machine: every question serves his writeup or his phone call. No 'in English, please', ever.",
    "HAILS #1 AND #2 ARE ANSWERED BY A KEYED MIC AND NO WORDS: carrier hiss, a breath, the engine behind it, the click off. NO words from Birdy until the third hail. Do not gloss what the silence means.",
    "THE THIRD HAIL gets the protected register, soft and plain: sorry to bug you / 'I, uh... I kind of did a bad thing' / real sorry, the airplane's not really his to have. Keep the phrase 'kind of did a bad thing'. THE RICHARD RUSSELL LAW: nothing about coming down, an after, jail, or intentions - from him or at him.",
    "THE SECOND CHANNEL stays physical and constant: the blip crawling with no tag, Kemp's forms and badge and jacket, Price's own traffic in his ear, the coordination line, the phone on the wall. Keep cutting to it.",
    "CONTROLLERS ARE REAL FLAT PROS: redundant, plain, dry; tense under control - never movie-procedural ticking-clock lines. The supervisor's correction is procedure, not theater.",
    "END FAST after Kemp's plain sentence lands: the room hearing it, the blip crawling out over the water. No button, nobody comments.",
    "Kill every catalog tell: doubled openers, engineered refrains, appended-fact fragments, list drumbeats, cross-character mirroring, summarizing Lines, thematic telegraphing, stated/implied turns, manufactured stammers, parallel restatement. American vernacular. Recorded, not written.",
    "Voice-differentiate: BISHOP (flat, steady, tightening), PRICE (dry, bored, then not; the one blurt), SUPERVISOR (worn, economical, kills the word flat), KEMP (civilian-plain, bureaucratic-dry, name-on-the-call careful), BIRDY (soft, apologetic, halting).",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=5)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: THE DOT v3 (intros; sourced facts; souls; the hijack beat) ===\n")
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
