/* FINALE #16 — THE NIGHT CALLED, v2 (2026-07-04; the naming + the death). NEW
   MOVEMENT per the user's Act-3 redesign:
   1. Banjo's bar plea (land it / first round / I want the stories) → the ache:
      "...I don't have any stories."
   2. DEACON's formal last question: "Is there anything anybody can say that'd
      change your mind?" → BIRDY, his reason stated ONCE as a fact about the
      deal: "Well. You heard them. I'll never be able to fly again." (oblique,
      never the suicide named.)
   3. THE NAMING (the real callsign rite, abbreviated to its bones on the
      frequency; it ANSWERS both refusals): you don't pick your own → the
      squadron TELLS HIS STORIES BACK to him (the night: the readback, the
      stall save, the roll, and that he spent it worried about their gas) - the
      rebuttal to "I don't have any stories" → "Took a vote up here. Two to
      nothing." → the bestowal, said aloud EXACTLY ONCE in the whole film:
      SKY KING → BISHOP types it onto the glass (the machine's record now
      registers the tribe's vote).
   The crown arrives ALIVE and is HEARD - and still cannot keep him.
   4. The quiet → "I'll just bring this nose down and call it a night." → the
      dive / "Birdy. Pull. PULL." / THE KNEELING (Negative; both jets descend)
      / Banjo's carrier cutting / Bishop's "Birdy?" / the island cuts mid-hiss /
      THE IMPACT NEVER SHOWN/HEARD/NAMED / the long silence (Maya, Kemp's
      unwritten log, the tag SKY KING riding empty glass, "Nobody moves.").
   Engine-written. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-finale.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-finale",
  slug: "INT. Q400 FLIGHT DECK / NIGHT SKY / RADAR ROOM / COMMAND POST - NIGHT (INTERCUT)",
  logline: "The fuel has stopped being a subject anyone raises, and the wingman tries the last true thing anybody has - land it, the first round's on me, I want to hear the stories - and the soft voice answers with the ache it has carried all night: it doesn't have any stories. So the lead pilot asks the only question left, whether anything anybody says could change his mind, and the answer is a fact off the government's own paper: he'll never be allowed to fly again. And two fighter pilots, out of arguments, do the one thing their world does for a man who has become one of them - they tell him his stories back, they take a vote, and they give him a name - and the man who was nobody all his life is christened, alive, on an open frequency, one minute before he brings the nose down and calls it a night.",
  cast: [
    {
      name: "BIRDY",
      who: "out of fuel-margin, out of night, settled - the day complete; his last kindnesses are refusals to make anyone feel it coming; he answers the bar invitation honestly (no stories), states his reason once as a fact off the paper (never fly again), receives the name they give him plainly and is moved by it, and announces the end in the language of finishing a shift. Nothing after the last line.",
      register: "soft, warm, spent; the stories admission flat and true, no self-pity; the reason-line plain and oblique (a fact about the deal, never the suicide); receiving the name, a small plain moved acknowledgment; the final line EXACTLY in the end-of-shift register; NOTHING spoken after it.",
      earnsEloquence: false,
      lexicon: "the nose, the night, the tank; no stories; never fly again; call it a night.",
    },
    {
      name: "BANJO",
      who: "the wingman who fell for him first; the talker; his plea is a bar invitation because that is the only language that carries it; and in the rite he is the one who TELLS THE STORIES BACK - the night's exploits recounted flat and deadpan, the pilot's way of saying you are one of us; and when the nose goes down his voice stops being a pilot's.",
      register: "the invitation warm and dry; the stories told back plain, deadpan, fast (not a speech - a list of true things done tonight); then in the dive short and breaking; then silent.",
      earnsEloquence: false,
      lexicon: "the bar, the round, the stories; the readback, the stall, the roll, the gas; then nothing.",
    },
    {
      name: "DEACON",
      who: "lead escort; he asks the formal last question, and when the answer is the ban he confers the thing the ban cannot touch - the name; the naming is his to give as lead; then his control fails by one millimeter in the dive (the name breaking through phraseology), and he refuses the order to leave the dying man.",
      register: "measured; the question flat; the bestowal quiet and certain - the single utterance of the title in the film; then clipped procedure compressing to the name; 'Negative.' flat.",
      earnsEloquence: false,
      lexicon: "change your mind; you don't pick your own; two to nothing; the name; the floor; negative.",
    },
    {
      name: "BISHOP",
      who: "at his scope for the last minutes of the voice he kept alive all night; when the name is given on his frequency he types it into the naked track - the record registering the vote; his last transmission is the name alone as a question; and after the island cuts the sound he keys once into the hiss and has nothing.",
      register: "level to the end; the typing wordless; 'Birdy?' into the hiss; then nothing; his stillness is the room's.",
      earnsEloquence: false,
      lexicon: "the tag, the track, typed not spoken; the name; the frequency; nothing.",
    },
    {
      name: "CONTROLLER",
      who: "the command net voice; orders the escort off the descending aircraft - altitude floors, procedure - takes Deacon's one-word refusal, and does not repeat the order.",
      register: "flat, procedural, twice; then silent.",
      earnsEloquence: false,
      lexicon: "the floor, come off him, said flat.",
    },
    {
      name: "MAYA",
      who: "at the command post through all of it - WORDLESS: a held face, two hands; the film is with her in the silence.",
      register: "silent; action only.",
      earnsEloquence: false,
      lexicon: "none.",
    },
  ],
  layer: {
    peshat: "the pilots plead, get his no-stories answer and his never-fly-again reason, and in return give him his stories back and a name; he is named alive; then he says he'll bring the nose down and call it a night, and dives; the escort refuses orders and descends with him; an island cuts the transmission; the rooms hold still; the tag rides empty glass",
    sod: "the man who never had one story is given all of them back by the two who watched him make them, and is made a citizen of the sky by the only tribe with standing to do it, one minute before he leaves it - the too-late love arriving exactly in time to be HEARD and not one second in time to keep him; the state offered him the ground for life and the squadron gave him the air forever and he chooses to die a pilot over living grounded; his final mercy is grammatical, the end of a life in the language of the end of a shift, so no one on the frequency has to hear it coming; the machine's two hands go down into the dark with him against the machine's own voice; the impact belongs to nobody, only the silence is shown, because the folk who will sing him never showed it either; and the name the tribe gave and the machine typed rides the empty glass like a crown over a missing head",
  },
  beats: [
    {
      who: "BANJO",
      want: "to land him with the only rope left: the bar, the first round, the stories",
      wall: "the man has no stories - and says so, flat and true, the ache of the whole film in four words",
      turn: "the invitation warm and dry (you land her, first round's on me - I want to hear the stories) - and '...I don't have any stories.' - and nobody has anything to put against it yet",
      subtext: "the last true rope thrown; the coward's ledger read out in one admission; the plea that cannot say please",
    },
    {
      who: "DEACON",
      want: "to ask the only question left before he lets go: is there anything that changes this",
      wall: "the answer is on the government's paper and it is total",
      turn: "'Is there anything anybody can say that'd change your mind?' - and Birdy, plain, a fact not a plea: 'Well. You heard them. I'll never be able to fly again.' - the reason stated once, oblique, the suicide never named",
      subtext: "the deal's poison surfacing as the reason; the two men who fly for a living hearing that a man will never fly again and knowing exactly what it costs; the door the paper closed",
    },
    {
      who: "DEACON",
      want: "to give him the one thing the ban cannot revoke - the tribe's citizenship - by its own rite",
      wall: "there is a minute, maybe, and the rite is usually a bar and a whole squadron",
      turn: "the naming, abbreviated to its bones and answering BOTH refusals: Banjo tells his stories back - the readback cleaner than line pilots, the stall he caught and greased, the roll, the whole night he spent worried about their gas - 'that's stories, man, you've been telling 'em all night'; and the rule - you don't pick your own, that's not how it works - and 'Took a vote up here. Two to nothing.'; and Deacon confers it, quiet and certain, the ONE time the title is spoken in the film: Sky King; and Bishop, hearing it, types it into the naked track - SKY KING appears on the glass; Birdy receives it plainly, moved, small",
      subtext: "the squadron telling your exploits IS the rite; the rebuttal to 'no stories'; the citizenship the state can't revoke answering the ban; the crown given ALIVE and heard; the machine's record registering the tribe's vote; and still it cannot keep him",
    },
    {
      who: "BIRDY",
      want: "(the day complete) to end it gently for everyone on the frequency",
      wall: "there is no gentle version - so he borrows the gentlest grammar he owns",
      turn: "a small quiet after the name, the panel light on his face, and then, warm and tired: 'I'll just bring this nose down and call it a night.' - and the nose goes down; NOTHING spoken by him again",
      subtext: "the crown received, then the shift ended; the sentence the country will grieve to; the day called; the light long gone",
    },
    {
      who: "DEACON",
      want: "to hold him in the air with a voice - procedure, then the name",
      wall: "the airplane is going down and no call arrests it; command orders the flight off - below your floor, come off him",
      turn: "the callouts compress until the name breaks through - 'Birdy. Pull. PULL.' - and to command, one word: 'Negative.' - and both fighters roll in and go down into the dark beside the airliner, their lights falling with it; Banjo's voice breaks for one clipped word and then stops; BISHOP's last is the name alone as a question - 'Birdy?' - and the island's black shoulder crosses the line and cuts the frequency to hiss mid-breath; Bishop keys once into the hiss and has nothing",
      subtext: "the kneeling: the machine's two hands descending against the machine's own voice; love as disobedience at altitude; the man who never lied left holding an open key with the truth and no time",
    },
    {
      who: "MAYA",
      want: "(the silence, held long)",
      wall: "-",
      turn: "the rooms hold perfectly still - the command post standing; Maya's face and her two hands, wordless; Kemp's pen down on the open log, the line unwritten; the fighters' calls gone; and on every scope the tag SKY KING rides its spot of glass with nothing under it; hold, and hold, and end",
      subtext: "the impact never shown, heard, or named; the crown riding the empty glass over a missing head; the film ends its verse inside the silence the country fell into",
    },
  ],
  rules: [
    "THE STORIES EXCHANGE, exact shape: Banjo's plea dressed as a bar invitation, warm and dry ('you land her, first round's on me - I want to hear the stories' register) - then flat and true with the beat before it: '...I don't have any stories.' The old survival-reply ('you'll always have stories') is DEAD and must not appear.",
    "THE REASON-QUESTION AND ANSWER, exact: DEACON: 'Is there anything anybody can say that'd change your mind?' - BIRDY: 'Well. You heard them. I'll never be able to fly again.' - stated ONCE, plain, a fact off the paper; OBLIQUE (the suicide is NEVER named); nothing else like it in the scene.",
    "THE NAMING answers BOTH refusals and is the film's emotional peak - keep it TIGHT and DEADPAN, never a speech: (a) BANJO tells the stories BACK - a short flat run of the night's true exploits (the clean readback, the stall he caught and recovered, the barrel roll, and that he spent the night worried about the fighters' fuel) capped plainly ('that's stories, man - you've been telling 'em all night' register) - the rebuttal to 'no stories'; (b) the RULE, plain: you don't pick your own, that's not how it works; (c) 'Took a vote up here. Two to nothing.'; (d) DEACON confers it, quiet and certain - the title SKY KING spoken ALOUD EXACTLY ONCE in the entire film, here, by the lead, as liturgy; (e) BIRDY receives it plainly and moved, small (register: 'well. huh. okay.' - not a speech, not tears on the page). NO winking, NO 'you're one of us now' stated as thesis - the rite carries it.",
    "THE GLASS-CROWN LANDS HERE (relocated from R3): when the name is given on the frequency, BISHOP types it into the naked track and SKY KING appears in the data block under the blip - wordless, the machine's record registering the tribe's vote; the name is NEVER spoken by Bishop or anyone but Deacon's single bestowal.",
    "THE CROWN DOES NOT SAVE HIM: after the naming and a small quiet, the FINAL LINE, verbatim register and placement - 'I'll just bring this nose down and call it a night.' - warm, tired, small, end-of-shift; the nose goes down on the action line after it; BIRDY SPEAKS NOTHING AFTER THIS LINE. Do NOT let the naming read as a rescue; it is a benediction, and he goes.",
    "THE DIVE / THE KNEELING, exact shape: DEACON's calls compress to the name - 'Birdy. Pull. PULL.' (the name breaking through phraseology exactly once); CONTROLLER, flat, twice at most: below your floor, come off him; DEACON: 'Negative.' (one word); BOTH jets descend with the airliner into the dark; Banjo's last is short and breaking ('Birdy, you're— level her. Level—' register) then his carrier cuts; command does NOT repeat the order.",
    "BISHOP'S LAST: the name alone as a question - 'Birdy?' - then the island cuts the frequency to hiss MID-BREATH; Bishop keys once into the hiss, holds it, says nothing, lets it go. He never pleads, never lies, never says goodbye.",
    "THE IMPACT IS NEVER SHOWN, HEARD, OR NAMED - ABSOLUTE: no fireball, no sound, no cutaway to the island, no 'he's gone' / 'we lost him'; the transmission cuts mid-hiss and the silence does everything.",
    "THE SILENCE HELD LONG: a run of pure action lines - the command post standing; MAYA wordless (a held face, two hands, nothing more written on her); KEMP's pen down on the open log, the line unwritten; the tag SKY KING riding its spot of glass with nothing under it; END inside it - no button, no coda material, no time-jump.",
    "ACTION LINES ARE FULL SENTENCES, PRESENT TENSE; ORIENT every voice; FULL DARK (panel, scopes, the fighters' lights the only light); plainest sentences of the picture, no similes, no lyric. THE RUSSELL LAW TO THE LAST BREATH - the reason-line and the final line are the only surfacings and both are oblique/grammar, never announcement.",
    "Kill every catalog tell. American vernacular. Recorded, not written. When in doubt: smaller.",
    "Voice-differentiate: BIRDY (warm, spent, small), BANJO (dry invitation; the stories deadpan; the breaking word), DEACON (the question; the bestowal certain; the name once; Negative), BISHOP (level; the typing; 'Birdy?'; the hiss), CONTROLLER (flat, twice), MAYA (wordless).",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=6)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: THE NIGHT CALLED v2 (the naming; the crown alive; the death) ===\n")
    Js.log(Cinema_Backends.readText(out))
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
