/* THE FOUR OLDS — scene 1 (cold open), FAITHFUL adaptation of the locked v14
   screenplay in the DME cue format. Back to the screenplay's structure per the
   director: ONE anchor voice carries the broadcast (no desk banter), chyrons
   become anchor reads, feeds cut with static, and the diner plays as written —
   the pot down the counter, the cup's quarter turn, one anonymous "Huh." No
   name is ever HEARD. Standing revisions kept: Marwani thanks the nation
   first; the Senator gives the socialist rationale; no narrated phones or
   selfies.
   Run: CLAUDE_STUDIO_TURN_TIMEOUT_MS=360000 CLAUDE_STUDIO_BUDGET=12 node src/FourOlds_Audio_Sc01.res.mjs */

let outPath = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/audio/a01_cold_open.scene.txt"

let anchor: Seed.voiceCard = {
  name: "ANCHOR",
  who: "the network's election-night anchor — the single broadcast voice that carries the montage; jubilant tonight, but always ON AIR: tight, driving, professional even when delighted",
  register: "broadcast cadence, not conversation: calls the board, reads what crosses the wire, hands to feeds; short declarative reads",
  earnsEloquence: false,
  lexicon: "network news English; reads incoming items as news ('Just in —'), never as personal phone alerts.",
}
let commentator: Seed.voiceCard = {
  name: "COMMENTATOR",
  who: "a silver-haired studio commentator moved to tears on air",
  register: "voice thick, a swallow before the line; earnest, reverent",
  earnsEloquence: false,
  lexicon: "reconciliation-speak.",
}
let announcer: Seed.voiceCard = {
  name: "ANNOUNCER",
  who: "the arena PA voice",
  register: "big-room PA, formal",
  earnsEloquence: false,
  lexicon: "ceremony announcements.",
}
let senator: Seed.voiceCard = {
  name: "SENATOR",
  who: "a senator making the calm, reasonable-sounding case for taking Frontier public",
  register: "dry, deliberate, three sentences",
  earnsEloquence: false,
  lexicon: "hearing-room plain.",
}
let radio: Seed.voiceCard = {
  name: "RADIO",
  who: "a small radio on the diner counter reading a regulatory notice",
  register: "flat government-notice read",
  earnsEloquence: false,
  lexicon: "regulatory boilerplate.",
}
let buck: Seed.voiceCard = {
  name: "BUCK",
  who: "an old regular at the diner counter — TO THE LISTENER just an old man's voice; his name is never spoken",
  register: "one syllable",
  earnsEloquence: false,
  lexicon: "Huh.",
}

let seed: Seed.sceneSeed = {
  id: "audio-01-cold-open-v10",
  slug: "SCENE 1. THE COLD OPEN - BROADCAST MONTAGE",
  logline: "The v14 cold open for the ear, beat for beat: the board flips, the balloons drop, the tearful commentator, the President's apology to the world, the Nobel read, the cash bay, Brussels, the Stewardship Act, the hearing — and the last cut lands in a diner where a radio reads the fireworks ban and one old voice says 'Huh.'",
  cast: [anchor, commentator, announcer, V14Cast.marwani, V14Cast.hale, senator, radio, buck],
  layer: {
    peshat: "a broadcast montage of the regime's victory day, ending in an ordinary diner",
    sod: "the whole grand circus, answered by one syllable and a click",
  },
  beats: [
    {
      who: "ANCHOR",
      want: "to call the night and carry the coverage",
      wall: "history is crossing the wire faster than she can read it",
      turn: "ON AIR the whole way — calls the board ('the entire board, red to blue, in one second'), rides the balloon drop with one delighted line, tees the commentator, hands to the arena, then back at the desk READS each item as news: the Nobel ('citing the announced agenda'), the cargo bay over the drone ('pallets of banded hundreds — the manifest reads Iran Compensation Framework, disbursement one of twelve'), Brussels ('two hundred billion dollars to European defense renewal'), and 'Just in — the White House unveils the Stewardship Act: private assets above one billion dollars, administered in the public interest.' Broadcast reads, never chat, never her phone.",
      subtext: "the machine narrating its own triumph",
    },
    {
      who: "COMMENTATOR",
      want: "to say what tonight means through actual tears",
      wall: "he can barely get it out",
      turn: "a swallow, then the canon line: 'It's a reconciliation. With a whole world the last administration spent years insulting — and tonight that world is watching us come back to the table.'",
      subtext: "media worship, dead straight",
    },
    {
      who: "MARWANI",
      want: "to consecrate the era",
      wall: "nothing — unopposed",
      turn: "the arena: announcer presents him, the crowd's HISTORY IS HEALING chant, then — thanks first ('Thank you. Thank you, all of you.') and the complete triple: 'I do not stand here to celebrate a victory. I stand here to begin a repair.' / 'On behalf of the United States, to every nation we have wronged — we are sorry.' / 'This is not retreat. This is not surrender. This is repair.'",
      subtext: "the smile as the weapon",
    },
    {
      who: "SENATOR",
      want: "the moral case for taking Frontier",
      wall: "Hale reads a compliance script",
      turn: "HALE, flat: 'Frontier is proud to serve the goals of this administration, at home and beyond it.' SENATOR, calm, three sentences: no one man ought to own the only road off this planet; public money built most of it; so it goes into public hands — 'call it nationalization if you like; that's what it is.' The witness mic holds on nothing.",
      subtext: "the reasonable face of the taking",
    },
    {
      who: "BUCK",
      want: "his coffee",
      wall: "the radio is reading the world away",
      turn: "the broadcast shrinks to the tinny counter radio; the diner's own life goes on (griddle, the pot working down the counter, a cup topped off unasked); the radio reads the fireworks ban; a cup turns a quarter on its saucer; the old voice: 'Huh.' — he drinks; a hand clicks the radio off mid-word; the griddle alone; quiet; the theme.",
      subtext: "ordinary America's entire verdict, one syllable",
    },
  ],
  rules: Belt.Array.concat(
    [
      "THE SOURCE — the locked v14 screenplay cold open, adapt it BEAT FOR BEAT (this is a faithful adaptation, not a re-conception):\n\nACTION: A wall of monitors flips the electoral board from red to blue in a single second.\nACTION: Balloons drop onto a news desk and bounce off the anchors' shoulders.\nACTION: In the crowd, two people hold up a bedsheet -- HISTORY IS HEALING. [becomes the arena CHANT]\nCOMMENTATOR: It's a reconciliation. With a whole world the last administration spent years insulting, and tonight that world is watching us come back to the table.\nMARWANI: [thanks first, then] I do not stand here to celebrate a victory. I stand here to begin a repair. / On behalf of the United States, to every nation we have wronged, we are sorry. / This is not retreat. This is not surrender. This is repair.\n[CHYRON: NOBEL PEACE PRIZE, CITING 'THE ANNOUNCED AGENDA' -> anchor read]\n[cargo bay: pallets of banded hundreds; MANIFEST: IRAN COMPENSATION FRAMEWORK, DISBURSEMENT 1 OF 12 -> anchor read over the drone]\n[Brussels signing, champagne; TICKER: $200 BILLION TO EUROPEAN DEFENSE RENEWAL -> anchor read]\n[STEWARDSHIP ACT: PRIVATE ASSETS ABOVE $1B ADMINISTERED IN THE PUBLIC INTEREST -> anchor reads it as incoming news, 'Just in —', NEVER off a phone]\nHALE: Frontier is proud to serve the goals of this administration, at home and beyond it.\nSENATOR: [the calm socialist rationale, three sentences, ending] call it nationalization if you like; that's what it is.\n[Roy's Diner: griddle; the pot works down the counter, a cup topped off unasked; the counter radio reads the fireworks ban; a cup turns a quarter on its saucer]\nBUCK: Huh.\n[he drinks; the radio clicks off mid-word; griddle alone; THE FOUR OLDS theme]",
      "AUTHOR IN THE DME CUE FORMAT (the mixer reads it):\n\
ACTION: ATMOS <space> | <bed description>   (continuous; plays until the next ATMOS/CUT)\n\
ACTION: CUT <space> | <static/transition description>\n\
ACTION: FX | <spot description>\n\
ACTION: MUSIC | <description>   (only the end theme)\n\
Spaces: studio, arena, cargobay, brussels, hearing, diner. Dialogue perspective as a leading wryly: broadcast voices at the desk (close); arena voices (pa); the diner radio (radio); the diner's human voice (close).",
      "ONE ANCHOR. No co-anchor, no desk banter, no interviews. The anchor is ON AIR: short broadcast reads and handoffs. The only other studio voice is the tearful COMMENTATOR with his one canon line.",
      "NO NAME IS EVER SPOKEN. Cue names (BUCK) are production labels; to the listener he is an old man's voice at a counter. No 'Earlene', no 'hon', no address by name anywhere in the scene.",
      "NEVER NARRATE A PERSONAL DEVICE OR A VISUAL-ONLY GAG: no phone alerts read off a phone, no selfie. Incoming items are read as news ('Just in —'). The balloons become soft rubber taps on the desk mics and one delighted anchor line.",
      "THE MONTAGE CUTS: studio -> CUT arena (announcer, chant, Marwani) -> CUT studio (Nobel read) -> CUT cargobay (drone; the Iran read) -> CUT brussels (cork, glassware; the $200B read; then the Stewardship Act read) -> CUT hearing (Hale, Senator) -> CUT diner (the fidelity drop: the broadcast thins into the tinny counter radio). Every CUT carries a broadcast static/feed-switch sound.",
      "THE DINER FINALE, per the screenplay, with air: ATMOS diner (griddle low, morning crockery); FX the coffee pot working down the counter, a cup topped off; the RADIO (radio) reads: 'under the carbon framework the sale, use, and private storage of consumer fireworks is prohibited nationwide, effective the first of the month' and continues; FX a cup turns a quarter on its saucer; BUCK (close): 'Huh.'; FX he drinks, the cup back down; the RADIO keeps reading and a hand clicks it off MID-WORD; FX the griddle, and nothing else; a held quiet; MUSIC | the show's theme rises.",
      "SHORT — two and a half to three minutes. The feeds are quick; the diner gets the most air.",
    ],
    AudioRules.common,
  ),
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=4)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    let sc2 = await Write.liftDialogue(~path=out, ~maxTries=3)
    let _ = Write.emit(sc2, ~txt=out)
    switch Write.verify(out) {
    | Ok() => Js.log("OK audio-01-v10")
    | Error(m) => Js.log("BAD audio-01-v10 — " ++ m)
    }
  } catch {
  | Write.WriteError(m) => Js.log("WRITE FAILED:\n" ++ m)
  | Session.SessionError(m) => Js.log("SESSION: " ++ m)
  }
  Session.close()
}
main()->ignore
