/* THE FOUR OLDS — scene 1 (cold open) authored in the DME CUE FORMAT for the
   Mix3 stem mixer. Two desk anchors flip across a triumphant day of coverage;
   each feed is a continuous ATMOS bed, cuts are CUT static transitions, and the
   whole thing collapses to a tinny diner radio. No named characters, no
   narrating of visuals — exposition is the anchors talking to each other.
   Run: CLAUDE_STUDIO_TURN_TIMEOUT_MS=360000 CLAUDE_STUDIO_BUDGET=12 node src/FourOlds_Audio_Sc01.res.mjs */

let outPath = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/audio/a01_cold_open.scene.txt"

let anchor: Seed.voiceCard = {
  name: "ANCHOR",
  who: "the woman at the desk, lead anchor; JUBILANT tonight, riding the high, feeding questions to her co-anchor and to the feeds",
  register: "warm broadcast lead, delighted; asks the questions that tee up the story",
  earnsEloquence: false,
  lexicon: "cable-news plain.",
}
let coanchor: Seed.voiceCard = {
  name: "COANCHOR",
  who: "the man at the desk, co-anchor; JUBILANT, the one who describes the incoming pictures and knows the details",
  register: "broadcast baritone gone giddy; answers her, narrates the feeds AS conversation, never as a chyron",
  earnsEloquence: false,
  lexicon: "cable-news plain.",
}
let announcer: Seed.voiceCard = {
  name: "ANNOUNCER",
  who: "the arena PA voice presenting the President",
  register: "big-room PA, formal, echoing",
  earnsEloquence: false,
  lexicon: "ceremony announcements.",
}
let senator: Seed.voiceCard = {
  name: "SENATOR",
  who: "a senator at the hearing making the reasonable-sounding case for taking Frontier public",
  register: "dry, calm, reasonable in its own frame",
  earnsEloquence: false,
  lexicon: "hearing-room plain; the socialist argument stated plainly.",
}
let radio: Seed.voiceCard = {
  name: "RADIO",
  who: "a small radio on a diner counter reading a regulatory notice at almost no volume",
  register: "flat government-notice read",
  earnsEloquence: false,
  lexicon: "regulatory boilerplate.",
}

let seed: Seed.sceneSeed = {
  id: "audio-01-cold-open-v9",
  slug: "SCENE 1. THE COLD OPEN - BROADCAST MONTAGE",
  logline: "Two desk anchors carry a triumphant night of coverage for the new regime, flipping to feed after feed, until it all shrinks to a tinny radio on a diner counter that somebody switches off.",
  cast: [anchor, coanchor, announcer, V14Cast.marwani, V14Cast.hale, senator, radio],
  layer: {
    peshat: "a two-anchor broadcast montage of the regime's victory day, ending in an ordinary diner",
    sod: "the whole grand circus, met by one room that turns off the television",
  },
  beats: [
    {
      who: "ANCHOR",
      want: "to call the biggest night of her career with her co-anchor",
      wall: "history is moving faster than the desk can keep up",
      turn: "SPECIFIC, JUBILANT desk talk — never filler: the board flipped all at once ('I have never seen a map do that — not a state at a time, ALL of it, one second'); the co-anchor puts a number and history on it ('biggest sweep in forty years, and it wasn't close'); then the tearful commentator beside them; every handoff is concrete ('he's walking out RIGHT now — let's go')",
      subtext: "the machine narrating its own triumph, delighted",
    },
    {
      who: "COMMENTATOR",
      want: "to say what tonight means, through actual tears",
      wall: "he can barely get it out",
      turn: "the canon line, voice thick, swallowing: 'It's a reconciliation. With a whole world the last administration spent years insulting — and tonight that world is watching us come back to the table.' The anchors receive it reverently. It is ridiculous and nobody on the desk knows it.",
      subtext: "media worship played dead straight",
    },
    {
      who: "MARWANI",
      want: "to consecrate the era from the podium",
      wall: "nothing — unopposed",
      turn: "OPENS BY THANKING THE NATION ('Thank you. Thank you, all of you. Thank you.'), the roar settling under him, then ALL THREE canon lines, complete: 'I do not stand here to celebrate a victory. I stand here to begin a repair.' / 'On behalf of the United States, to every nation we have wronged — we are sorry.' / 'This is not retreat. This is not surrender. This is repair.'",
      subtext: "the smile as the weapon; his rule-of-three rhetoric is the satire",
    },
    {
      who: "COANCHOR",
      want: "to walk the audience through what keeps crossing the wire",
      wall: "each item is bigger than the last",
      turn: "back at the desk, rapid-fire and gleeful: the NOBEL gag (SHE: 'The Peace Prize? He's been in office eleven weeks.' HE: 'They're citing the announced agenda.' SHE, delighted: 'The ANNOUNCED agenda.'); the CASH BAY exchange (SHE: 'what are we looking at?' HE: 'cargo bay of the first flight out — pallets of banded hundreds, floor to ceiling' SHE: 'how much?' HE: 'first delivery under the Iran Compensation Framework. First of twelve.'); the STEWARDSHIP ACT (HE: 'and this just in from the White House — the Stewardship Act: private assets above one billion dollars to be administered in the public interest' SHE, one beat, the only flicker in the whole giddy night: 'Administered.' HE, cheerfully: 'In the public interest.')",
      subtext: "obscene things, cheerfully; the one-word 'Administered.' is the crack of unease that closes right up",
    },
    {
      who: "SENATOR",
      want: "the moral case for taking Frontier public",
      wall: "Hale reads a compliance script",
      turn: "HALE, flat, reading: 'Frontier is proud to serve the goals of this administration, at home and beyond it.' The SENATOR, calm, three sentences, no more: no one man ought to own the only road off this planet; public money built most of it; so it goes into public hands — 'call it nationalization if you like; that's what it is.' The witness mic holds on nothing.",
      subtext: "the reasonable face of the taking; Hale's fire banked",
    },
    {
      who: "RADIO",
      want: "to finish a notice nobody hears",
      wall: "it plays to a diner that has stopped caring",
      turn: "the broadcast SHRINKS to a tinny counter radio mid-coverage; the diner has its own life (griddle, percolator, forks); the radio reaches the fireworks ban — 'the sale, use, and private storage of consumer fireworks is prohibited nationwide, effective the first of the month' — the room's small sounds go on; a mug turns slow on a saucer; and a hand clicks THE RADIO off mid-word ('effective immediat—' CLICK). The griddle alone. Quiet. Then the theme.",
      subtext: "of the whole circus, the only thing this room registers is the Fourth of July — and it answers by switching it off",
    },
  ],
  rules: Belt.Array.concat(
    [
      "AUTHOR IN THE DME CUE FORMAT (this is mandatory — the mixer reads it). Sounds are written as ACTION lines with a prefix:\n\
- A continuous background bed:  ACTION: ATMOS <space> | <description>\n\
- A hard cut to a new feed:     ACTION: CUT <space> | <static or whoosh description>\n\
- A one-off spot effect:        ACTION: FX | <description>\n\
- Music (only the end sting):   ACTION: MUSIC | <description>\n\
<space> is one of: studio, arena, cargobay, hearing, diner. A bed plays until the next ATMOS/CUT. Dialogue carries its PERSPECTIVE as a leading wryly: the desk anchors speak (close); the arena announcer and the President speak (pa); the diner radio speaks (radio). Example of the grammar:\n\
ACTION: ATMOS studio | election-night control-room, low bustle and monitors\n\
ANCHOR: (close) We can call it. The whole map has turned.\n\
COANCHOR: (close) I have never seen a board move like that.\n\
ACTION: CUT arena | a wash of broadcast static\n\
ACTION: ATMOS arena | a vast hall, a huge settled crowd\n\
ANNOUNCER: (pa) Please rise for the President of the United States.",
      "OPEN ON BREAKING NEWS. The very first cue is the network's breaking-news identity: ACTION: FX | a breaking-news sting and bed, then ATMOS studio. Establish the anchor DESK immediately.",
      "TWO ANCHORS, EXPOSITION AS CONVERSATION. A woman (ANCHOR) and a man (COANCHOR) co-anchor. They tell the story by talking TO EACH OTHER — she asks, he answers. NEVER narrate a visual: no 'there's an alert on my phone', no reading chyrons or tickers aloud, no describing a selfie. The cash bay is the model exchange (she: what are we looking at / he: pallets of hundreds, first Iran disbursement / she: how much / he: first of twelve).",
      "NO NAMED CHARACTERS. The listener has met no one. Voices are broadcast ROLES (anchor, co-anchor, arena announcer, the President, a senator, a radio) or anonymous (the diner). No Buck, no Earlene, no named aide. Marwani and Hale are named only as the anchors identify them on air.",
      "THE MONTAGE, feed by feed, each its own ATMOS bed with a CUT static between: studio desk (call + commentator) -> CUT -> arena (Marwani thanks the nation, then the full triple) -> CUT back to studio (Nobel gag, cash-bay exchange, Stewardship Act) -> CUT -> hearing (Hale + the Senator, three sentences) -> the FINALE. The desk segments carry the satire; keep them SPECIFIC — margins, weeks in office, disbursement counts — never generic chat.",
      "THE FIDELITY-DROP FINALE — the scene's whole point, give it air. After the hearing: ACTION: CUT diner | the broadcast thins and shrinks into a tinny counter radio mid-sentence, then ATMOS diner | griddle low, a percolator, morning crockery. The RADIO (radio) reads the fireworks-ban notice; the room's own sounds keep going THROUGH it (FX a fork on a plate, FX a mug turned slow on its saucer); then FX | a hand clicks the RADIO off cutting the word ('effective immediat—' CLICK) — it is the RADIO that dies, keep the device consistent; FX | the griddle alone; a held beat of quiet; ACTION: MUSIC | the show's theme rises out of the silence. Anonymous throughout — no names, no 'hon', nobody we meet.",
      "KEEP CANON, COMPLETE: Marwani's THREE lines including 'This is not retreat. This is not surrender. This is repair.'; the tearful commentator's 'reconciliation' line; Nobel 'citing the announced agenda' (+ the eleven-weeks jab); Iran Compensation Framework 'first of twelve'; THE STEWARDSHIP ACT ('private assets above one billion dollars to be administered in the public interest') as a desk exchange with the anchor's one-word 'Administered.' flicker; the Senator's three-sentence nationalization case; the nationwide fireworks ban. The anchors are JUBILANT — [excited] energy, quick, riding each other's lines.",
      "SHORT — two and a half to three minutes. The desk is the spine; feeds are quick; the diner finale gets the most air of any single segment.",
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
    | Ok() => Js.log("OK audio-01-v9")
    | Error(m) => Js.log("BAD audio-01-v9 — " ++ m)
    }
  } catch {
  | Write.WriteError(m) => Js.log("WRITE FAILED:\n" ++ m)
  | Session.SessionError(m) => Js.log("SESSION: " ++ m)
  }
  Session.close()
}
main()->ignore
