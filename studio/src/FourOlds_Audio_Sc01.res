/* THE FOUR OLDS audio play — scene 1 (the cold open) re-conceived FOR THE EAR
   as a broadcast montage the listener flips across, ending in one ordinary
   room that switches it off. Two hard laws from the director:
   (1) NO NAMED CHARACTERS — the listener has met no one; every voice is a
       broadcast role or anonymous. No Buck, no Earlene, no named aide.
   (2) BROADCAST-ARTIFACT CUT GRAMMAR — distinct acoustic space per feed, the
       anchor threads the handoffs, a static/channel-flip marks the hard jumps,
       the finale drops fidelity to a tinny diner radio. No music.
   Run: CLAUDE_STUDIO_TURN_TIMEOUT_MS=360000 CLAUDE_STUDIO_BUDGET=10 node src/FourOlds_Audio_Sc01.res.mjs */

let outPath = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/audio/a01_cold_open.scene.txt"

let anchor: Seed.voiceCard = {
  name: "ANCHOR",
  who: "network news anchor, the through-line voice of the montage; JUBILANT tonight — riding the high of the night, delighted, can barely keep the professional lid on the celebration; hands off to each feed the way live TV does",
  register: "broadcast-smooth continuity gone giddy: 'we go now to', 'just crossing', 'and that's' — announces every cut so the ear never gets lost, but the joy keeps breaking through",
  earnsEloquence: false,
  lexicon: "cable-news plain; reads chyrons/tickers/alerts aloud because that is what anchors do.",
}
let commentator: Seed.voiceCard = {
  name: "COMMENTATOR",
  who: "a studio panelist moved to tears by the new administration; sincere, thick-voiced",
  register: "swallows once before he speaks; earnest, reverent",
  earnsEloquence: false,
  lexicon: "reconciliation-speak.",
}
let announcer: Seed.voiceCard = {
  name: "ANNOUNCER",
  who: "the arena PA voice at the rally, presenting the flags",
  register: "big-room PA cadence, formal, echoing",
  earnsEloquence: false,
  lexicon: "ceremony announcements.",
}
let senator: Seed.voiceCard = {
  name: "SENATOR",
  who: "a senator at the hearing; holds one word in his mouth",
  register: "dry, deliberate, one loaded word",
  earnsEloquence: false,
  lexicon: "hearing-room plain.",
}
let radio: Seed.voiceCard = {
  name: "RADIO",
  who: "the small radio on the diner counter reading the regulatory notice at almost no volume",
  register: "flat government-notice read, tinny and distant",
  earnsEloquence: false,
  lexicon: "regulatory boilerplate.",
}

let seed: Seed.sceneSeed = {
  id: "audio-01-cold-open-v7",
  slug: "SCENE 1. THE COLD OPEN - BROADCAST MONTAGE",
  logline: "For the ear: a listener flips across a triumphant day of live coverage for the new regime — a studio calling the election, a rally where the president apologizes to the world, pallets of cash, a founder cornered at a hearing — and it all shrinks, at the end, to a tinny radio on a diner counter that somebody switches off. No one we are asked to know; the world, made concrete, then turned off.",
  cast: [anchor, commentator, announcer, V14Cast.marwani, V14Cast.hale, senator, radio],
  layer: {
    peshat: "a broadcast montage of the regime's victory day, heard as if flipping across live feeds, ending in an ordinary diner",
    sod: "the whole grand circus, met by one room that turns off the television; ordinary America is unimpressed and unheard",
  },
  beats: [
    {
      who: "ANCHOR",
      want: "to carry the audience through the night's coverage feed by feed",
      wall: "there is a great deal happening at once, in many places",
      turn: "the anchor threads every cut with live-TV continuity so the ear always knows we have moved to a new place — the studio, the rally, the cargo bay, the signing, the hearing — reading the chyrons and alerts aloud as anchors do",
      subtext: "the machine narrating its own triumph",
    },
    {
      who: "MARWANI",
      want: "to consecrate the new era from the rally podium",
      wall: "nothing — he is unopposed, which is the horror",
      turn: "he OPENS BY THANKING THE NATION — 'Thank you. Thank you, all of you' — gracious, warm, the crowd roaring back — and only then the mission: 'I do not stand here to celebrate a victory. I stand here to begin a repair.' / 'to every nation we have wronged, we are sorry.' / 'This is not retreat. This is not surrender. This is repair.' — the arena vast around him; a broadcast artifact (static / the feed pulling back to the studio) carries us OUT of the speech and back to the anchor",
      subtext: "the smile as the weapon",
    },
    {
      who: "SENATOR",
      want: "to make the moral case for taking Frontier into public hands",
      wall: "Hale sits there reading a compliance script",
      turn: "Hale reads his hostage line — 'Frontier is proud to serve the goals of this administration, at home and beyond it.' — and the SENATOR answers not with one word but with the SOCIALIST RATIONALE, calm and reasonable in its own frame: no single man should privately own the only road off this planet; the Moon, the fleet, the future are public goods, built on public money, and the age of the billionaire owning them is over — THAT is why the committee moves to bring Frontier under public stewardship. Hale folds his page and the mic holds on nothing.",
      subtext: "the reasonable face of the taking; the fire banked in Hale, for now",
    },
    {
      who: "RADIO",
      want: "to finish reading a regulatory notice nobody is listening to",
      wall: "it is playing to a diner that has stopped caring",
      turn: "the grand broadcast shrinks — tinny, small — a radio on a counter reading the nationwide fireworks ban; a mug sets down; a stool creaks; nobody answers; a hand clicks the television dark. Then the title.",
      subtext: "the one casualty this room notices is the Fourth of July",
    },
  ],
  rules: Belt.Array.concat(
    [
      "THE SOURCE — the locked v14 screenplay cold open. This is a ONE-WAY ADAPTATION for the ear; the facts and canon lines are fixed, but every VISUAL must become something HEARD. The screenplay:\n\nACTION: A wall of monitors flips the electoral board from red to blue in a single second.\nACTION: Balloons drop onto a news desk and bounce off the anchors' shoulders.\nACTION: In the crowd, two people hold up a bedsheet -- HISTORY IS HEALING.\nCOMMENTATOR: It's a reconciliation. With a whole world the last administration spent years insulting, and tonight that world is watching us come back to the table.\nMARWANI: I do not stand here to celebrate a victory. I stand here to begin a repair.\nMARWANI: On behalf of the United States, to every nation we have wronged, we are sorry.\nMARWANI: This is not retreat. This is not surrender. This is repair.\n[CHYRON: NOBEL COMMITTEE AWARDS PEACE PRIZE, CITING THE ANNOUNCED AGENDA]\n[cargo plane bay full of banded hundred-dollar bills; MANIFEST: IRAN COMPENSATION FRAMEWORK, DISBURSEMENT 1 OF 12; a young aide takes a selfie]\n[Brussels signing room; champagne; TICKER: AMERICA COMMITS $200 BILLION TO EUROPEAN DEFENSE RENEWAL]\n[phone push alert: WHITE HOUSE UNVEILS STEWARDSHIP ACT: PRIVATE ASSETS ABOVE $1B TO BE ADMINISTERED IN THE PUBLIC INTEREST]\nHALE: Frontier is proud to serve the goals of this administration, at home and beyond it.\nSENATOR: Nationalization.\n[Roy's Diner, morning; muted TV cycling the footage; a radio murmurs]\nRADIO: under the carbon framework the sale, use, and private storage of consumer fireworks is prohibited nationwide effective the first of the month —\n[a regular watches, turns his cup] BUCK: Huh. [screen to black] THE FOUR OLDS.",
      "LAW 1 — NO NAMED CHARACTERS. The listener has met NO ONE. Every voice is a broadcast ROLE (the anchor, the commentator, the president, an arena announcer, a founder at a hearing, a senator, a radio) or ANONYMOUS. DELETE 'Buck' and 'Earlene' entirely — the diner is anonymous: a griddle, a poured cup, a mug set down, a stool, a hand that turns off the TV. NO character names, NO name-tags between people who know each other. Marwani and Hale may be named only as the broadcast identifies them (the anchor says who they are), never as people we know.",
      "LAW 2 — BROADCAST-ARTIFACT CUT GRAMMAR (the director's choice). The montage is the listener FLIPPING ACROSS LIVE COVERAGE. Three signals, together: (a) EACH FEED IS A DISTINCT ACOUSTIC SPACE — studio (close, dead, a tight applause pocket), rally arena (huge, PA slap, crowd wash), cargo bay (engine drone through a hull), signing room (bright, champagne, small), hearing room (dry, one witness mic); write the ACTION lines so each space is unmistakable. (b) THE ANCHOR THREADS EVERY HANDOFF — 'we go live to', 'just crossing now', 'and that is' — so the ear is never lost about where we cut to. (c) A BROADCAST ARTIFACT MARKS THE HARD JUMPS — an ACTION line of static / a channel-flip / a feed-switch on the ~3 biggest cuts (NOT every micro-cut). NO MUSIC anywhere until the very end.",
      "LAW 3 — THE FINALE FIDELITY DROP is the period at the end of the montage. Everything so far is clean full-fidelity broadcast. The LAST cut is different: the grand speech / the coverage SHRINKS — suddenly tinny, thin, small — revealed as a radio on a diner counter. Write it so the ear hears the fidelity collapse. Then concrete anonymous room: griddle, a cup poured, the fireworks-ban notice low and unheeded, a mug set on a saucer, a stool creak, and a hand that clicks the TV to black. Silence. THEN the show's theme sting. The contrast IS the meaning: the whole circus, and one room turns it off.",
      "VISUAL -> AURAL. Chyrons, tickers, manifests, phone alerts are READ ALOUD by the anchor (anchors read the news); the 'HISTORY IS HEALING' bedsheet becomes a CROWD CHANT; the selfie becomes a phone-camera shutter; the cash bay becomes the anchor describing banded pallets over an engine drone. Keep every canon fact: Nobel 'announced agenda', Iran Compensation Framework disbursement 1 of 12, $200 billion to European defense, the Stewardship Act wording, Hale 'proud to serve', the senator's 'Nationalization', the fireworks ban.",
      "DIRECTOR'S REVISIONS (must land): (1) the ANCHOR is JUBILANT throughout — giddy with the night, the joy breaking through the professional patter. (2) MARWANI OPENS BY THANKING THE NATION ('Thank you. Thank you, all of you') before any of the repair lines. (3) there MUST be a broadcast audio transition OUT of Marwani's speech back to the anchor — a static wash / the feed pulling back — do not hard-cut from his last word straight to the anchor. (4) the SENATOR does NOT just say 'Nationalization' — he gives a short, reasonable-sounding SOCIALIST RATIONALE (no one man should own the only road off the planet; public money built it; the fleet and the Moon are public goods; the age of the billionaire owning them is over) and only in that frame names the move to public stewardship; Hale stays banked and silent after.",
      "EYES-CLOSED TEST — a blind listener with no context must follow this as: flipping across a triumphant day of live coverage for a new American regime, landing at last in one ordinary diner that switches the whole thing off. If a beat only works because you can SEE it, rewrite it so the EAR gets it, or cut it.",
      "SHORT — two and a half to three audio minutes. LEAN. The anchor is the spine; the feeds are quick; the diner finale gets the most air.",
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
    | Ok() => Js.log("OK audio-01-v7")
    | Error(m) => Js.log("BAD audio-01-v7 — " ++ m)
    }
  } catch {
  | Write.WriteError(m) => Js.log("WRITE FAILED:\n" ++ m)
  | Session.SessionError(m) => Js.log("SESSION: " ++ m)
  }
  Session.close()
}
main()->ignore
