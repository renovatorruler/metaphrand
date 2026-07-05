/* ACT 2 #3b — KEEP HIM TALKING (2026-07-02, user-specified second radar-room
   scene). Opens seconds after THE DOT ends (Kemp's phone still warm): the watch
   floor's two instructions come back through Kemp - keep him talking, and
   airplanes are coming to look at him. Bishop's job becomes the human thread:
   keep the line alive WITHOUT pushing (no why, no intentions). The NAME gets
   asked - and the man deflects his real name, offering only what everybody
   calls him: Birdy (the mystery holds; a nickname identifies nobody; Kemp logs
   it). Plants the lines the intercept already references ("not sure I'm doing
   this right"; "I don't want to hurt anybody"; "he asked me to call him Birdy").
   ENDS on the cut the user asked for: two fast tags rising toward the slow blip
   -> the klaxon (the intercept). Engine-written. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-keep.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-keep",
  slug: "INT. SEATTLE APPROACH - RADAR ROOM - NIGHT (MOMENTS LATER)",
  logline: "Seconds after the call goes in, the watch floor sends back its first two decisions through Kemp: keep the man talking, and airplanes are coming up to look at him. So Bishop's whole job becomes a conversation - keep the line alive, ask nothing that could close him up - and the soft voice over the water volunteers more than any interrogation would get: he's not sure he's doing this right, he doesn't want to hurt anybody, and when Bishop asks what to call him, he won't give a name - just what everybody calls him. Birdy. The room writes it down, still not knowing who he is, as two fast military tags rise onto the bottom of the scope, climbing hard toward the one slow blip.",
  cast: [
    {
      name: "BISHOP",
      who: "the approach controller, now assigned the strangest job of his career: keep a gentle stranger talking. He works the line the way he works everything - unhurried, plain, small - and he instinctively does NOT ask the big questions (why, what are you doing, what do you want), because he can hear that pushing would lose the man. This is the birth of the thread: the first voice Birdy trusts.",
      register: "flat, warm underneath, small mundane questions; a real controller's redundancy; protective without ever naming it; his calm tightens, never cracks.",
      earnsEloquence: false,
      lexicon: "the frequency, the airplane, the night, the scope, said plain and small.",
    },
    {
      name: "KEMP",
      who: "the DHS liaison, the phone still at his ear from the call; the watch floor talks into it and he relays the instructions to a room he has no authority over except the phone in his hand; then he stays on his log, writing down what the night gives him, including a name that isn't a name.",
      register: "civilian-plain, bureaucratic-dry; relays instructions carefully, word for word; logs things half-aloud; deadpan about the absurd parts.",
      earnsEloquence: false,
      lexicon: "the watch floor, the log, the writeup, quote-unquote, said dry.",
    },
    {
      name: "SUPERVISOR",
      who: "the shift supervisor; turns the watch floor's instruction into the room's marching order with a sentence, then stands there listening like everyone else.",
      register: "flat, economical; one order, plain; then quiet.",
      earnsEloquence: false,
      lexicon: "the room, the line, the job, said plain.",
    },
    {
      name: "PRICE",
      who: "the controller at the next position, half his attention still on his own traffic; he's the one who sees the two fast military tags come up off the base and calls them across the room, flat.",
      register: "dry, minimal; the callout plain and quick.",
      earnsEloquence: false,
      lexicon: "his sector, the tags, fast movers, said flat.",
    },
    {
      name: "BIRDY",
      who: "the soft voice over the water, kept on the line by a kind stranger; small talk reaches him where questions wouldn't, and he volunteers the truth in pieces - he's not sure he's doing this right, he doesn't want to hurt anybody; asked for a name, he can't quite claim his own - he gives what everybody calls him instead, and asks the man to use it.",
      register: "soft, apologetic, halting, sad-but-cheerful; flat little flying observations; deflects the real name without drama - it just doesn't come; never bitter, never clever, nothing wanted.",
      earnsEloquence: false,
      lexicon: "plain small words; the airplane said like a borrowed thing; sorry; what people call him.",
    },
  ],
  layer: {
    peshat: "told to keep the pilot talking while fighters scramble, the controller makes small talk with him, learns he's harmless and unsure, and gets a nickname instead of a name",
    sod: "the machine's first mercy and first leash are the same instruction - keep him talking - and the man assigned to it becomes the first person in years to simply listen to Birdy; the overlooked man cannot even claim his own name when asked for it - a lifetime of being nobody hands over the nickname the world gave him instead of the name it never learned - so the state's file on the gentlest man alive reads 'goes by Birdy, identity unknown'; and while the room learns how harmless he is, the sky is already sending armed airplanes to look at him - the care and the threat rising together, and nobody in the room says which is which",
  },
  beats: [
    {
      who: "KEMP",
      want: "to relay the watch floor's instructions exactly and get them acted on - his name is on this call too",
      wall: "he's the visitor; he has no authority over this room except the phone in his hand",
      turn: "he covers the mouthpiece and gives the room the two decisions - they want him kept talking, and they're sending airplanes up to look at him - and the Supervisor turns it into the room's order with one plain sentence to Bishop",
      subtext: "the machine's first decision arrives through the paperwork guy; keep-him-talking is care and leash in the same breath; nobody says the word for what the airplanes are",
    },
    {
      who: "BISHOP",
      want: "to keep the line alive without closing him up",
      wall: "every real question - why, what's the plan, what do you want - is the kind that loses a man like this; Bishop can hear it",
      turn: "he goes small instead - the airplane, the night, how she's handling - and the soft voice opens: he volunteers that he's not sure he's doing this right, and that he doesn't want to hurt anybody, that's the main thing; the room stands still and listens to how harmless he is",
      subtext: "the birth of the thread - the first person in years who just listens to him; the interrogation that never happens getting more truth than one ever would; the room's picture of him turning human",
    },
    {
      who: "BISHOP",
      want: "something to call him - hours of this ahead, and 'aircraft off Sea-Tac' won't carry it",
      wall: "the man won't claim his own name; asked plainly, it just doesn't come",
      turn: "Birdy deflects the name without drama and hands over the other thing - what everybody calls him - and asks Bishop to use it; Bishop takes it plain; Kemp logs it half-aloud: goes by Birdy, no name given - the file on him still has a hole where a man should be",
      subtext: "the overlooked man cannot claim his own name; the nickname the world gave him instead of the name it never learned; the mystery holds - nobody knows who he is, and now he has a handle anyway",
    },
    {
      who: "PRICE",
      want: "to call the new traffic he's seeing - it's his scope and his job",
      wall: "nothing walls him; it's simply arriving, fast",
      turn: "two fast military tags rise onto the bottom of the scope off the base, climbing hard toward the slow blip; Bishop keys up and tells Birdy, plain and easy, that some airplanes are coming up to take a look at him and they're not going to do anything; Birdy's answer is small and okay; end on the two fast tags closing the distance to the one slow blip",
      subtext: "the machine's second hand arriving while the first one soothes; escort or execution, nobody says; the cut to the jets loaded in the last image",
    },
  ],
  rules: [
    "CONTINUOUS with THE DOT (moments later): characters are already introduced - re-anchor them LIGHTLY on first mention ('Kemp, the phone still at his ear'; 'Price, half back on his own traffic') - no full re-introductions, but a listener must still place every voice.",
    "SOURCED FACTS ONLY: the keep-him-talking instruction and the incoming airplanes enter ONLY through Kemp's phone relay from the watch floor; the fast tags enter ONLY through Price's scope callout. Nobody knows anything they weren't given on the page. Nobody names what the fighters are for.",
    "KEEP-HIM-TALKING is the scene's engine: Bishop asks NOTHING big - no why, no intentions, no plan, no family, nothing about coming down (THE RICHARD RUSSELL LAW holds absolutely). His questions are SMALL and mundane: the airplane, the night, how she's handling. The truth arrives VOLUNTEERED, never extracted.",
    "PLANT these two Birdy lines, ONCE each, plain and undramatic (the intercept scene later quotes them): (a) that he's not sure he's doing this right - flat, honest, no fear-performance; (b) that he doesn't want to hurt anybody, that's the main thing. Do not let either become a speech or a Line.",
    "THE NAME BEAT, exactly this shape: Bishop asks plainly what he should call him / whether he's got a name. Birdy DEFLECTS the real name - it just doesn't come, no drama, no explanation ('aw, it's-' register) - and offers what everybody calls him: Birdy - and asks Bishop to use it (the intercept later says 'that's what he asked me to call him'). Bishop takes it plain ('Okay, Birdy.' - answering adoption is a legal echo). KEMP logs it half-aloud, dry: goes by Birdy, quote-unquote, no name given. The REAL name is NEVER said - the file keeps its hole. No thematic line about being nobody; the deflection stays small and unexplained.",
    "ACTION LINES ARE FULL SENTENCES, PRESENT TENSE; ORIENT every voice with the physical move first; the scene must play EARS-ONLY.",
    "THE SECOND CHANNEL stays physical: Kemp's phone and log, the coffee, the scope - the slow untagged blip, then the two fast tags rising and closing; Price's own traffic still in one ear; the Supervisor's reading glasses going on to look. Keep cutting to it.",
    "LEGIBILITY: no jargon beyond plain 'fast movers'/'military' language that explains itself; everything a lay ear can follow.",
    "CONTROLLERS ARE REAL FLAT PROS; tense under control; no ticking-clock lines; nobody summarizes the moment; the closest anyone comes is Kemp's dry log entry.",
    "END FAST on the image: the two fast tags closing on the one slow blip - the cut to the jets. No button, nobody comments after Birdy's small okay.",
    "Kill every catalog tell: doubled openers, engineered refrains, appended-fact fragments, list drumbeats, cross-character mirroring, summarizing Lines, thematic telegraphing, stated/implied turns, manufactured stammers, parallel restatement. American vernacular. Recorded, not written.",
    "Voice-differentiate: BISHOP (flat, warm underneath, small), KEMP (dry, careful, deadpan), SUPERVISOR (one order, plain), PRICE (minimal, quick), BIRDY (soft, halting, sad-cheerful).",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=5)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: KEEP HIM TALKING (the name; the thread; the tags rise) ===\n")
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
