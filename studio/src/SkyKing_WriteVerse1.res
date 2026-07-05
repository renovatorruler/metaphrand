/* VERSE 1 — THE RAMP (2026-07-04; the ballad restructure's first witness verse
   AND DOORWAY #1 — the first time the film breaks into the past; once it opens,
   the threat is a man and cannot be unknown; the form commits). GATEWAY: in the
   command post's holding area, Reyes (or an agent) asks DEZ what he was like -
   and Dez, wrecked, starts talking, and the film goes to THE DAYS BEFORE:
   the rote ramp morning, the scheduling app handing his aircraft to someone
   else and him not asking, him covering the green kid TANNER's mistake and
   eating the blame with a laugh, the turkey sandwich, and Dez telling him to
   REACH - put in for the thing - and Birdy deflecting. The prison shown, not
   told: the diffuse daily cowardice, no single wound. RETURN: Dez in the
   present, unable to finish, the weight of "I told him to reach and he did."
   The sim/fake-life theme belongs to Maya's verse; this one is the WORKPLACE
   smallness. Engine-written. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-verse1.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-verse1",
  slug: "INT. COMMAND POST - HOLDING AREA - NIGHT / EXT. SEA-TAC RAMP - DAY (FLASHBACK)",
  logline: "In a side room off the command post, a young ramp agent who has not stopped shaking since they walked him in is asked, gently, what his friend was like - and because he cannot say the true thing, he says the small ones, and the film goes back to an ordinary shift a few days ago: a scheduling app taking the airplane a man had earned and him not saying a word, a green kid's mistake that a supervisor pins on the wrong guy and the wrong guy taking it with a laugh, a turkey sandwich eaten standing up, and a friend saying reach, put in for it, you're better than this - to a man who just smiles and lets it go. And then the room again, and the young man who told his friend to reach, and cannot finish the sentence.",
  cast: [
    {
      name: "DEZ",
      who: "the young ramp agent, hours after watching his friend take an airplane he will not come back from; wrecked, guilty, talking because the agent is kind and because talking is the only thing left; he keeps trying to explain who Birdy WAS and keeps landing on small things because the big thing won't come; the reach he pushed on his friend is a stone in him now.",
      register: "young, unsteady, halting; deflects the big feeling into small memories; the guilt never named, always under; trails off, can't finish.",
      earnsEloquence: false,
      lexicon: "the ramp, the app, the schedule, his friend; reach, put in, said and regretted.",
    },
    {
      name: "REYES",
      who: "the agent drawing him out - not the machine's needs now (the name and job are known), but the human map; she asks small and lets the silences run; she is learning the man she is about to try to talk down, and learning she is too late.",
      register: "quiet, patient, few words; she does not push; the questions small and human.",
      earnsEloquence: false,
      lexicon: "what was he like, walk me through it, said soft.",
    },
    {
      name: "BIRDY",
      who: "in the flashback - the man himself, a few days ago, on an ordinary shift: gentle, competent, and small by a hundred daily choices; he does not ask, does not fight, covers the kid who cost him, eats the blame with a joke, and lets the good chance pass because reaching for it is the one thing he can't do. No single wound; the cowardice is the water he swims in, and he is kind the whole time.",
      register: "soft, plain, sad-cheerful, deflecting; 'easier' register; the competence shown in his hands, the smallness in what he won't say; never self-pitying, always the small nice thing.",
      earnsEloquence: false,
      lexicon: "the airplane, the turn, the schedule said flat; easier; it's fine; the joke instead of the fight.",
    },
    {
      name: "TANNER",
      who: "in the flashback - the green kid on the ramp who makes the mistake Birdy quietly covers; eager, careless, unaware what it cost.",
      register: "young, oblivious, quick.",
      earnsEloquence: false,
      lexicon: "the ramp, the mistake, thanks-man.",
    },
    {
      name: "WARD",
      who: "in the flashback - the ramp boss who pins the mistake on Birdy without malice, because Birdy is the one who won't argue; the injustice is routine, not cruel.",
      register: "worn, flat, moving fast; the blame handed out without looking up.",
      earnsEloquence: false,
      lexicon: "the roster, the write-up, whose-was-it, flat.",
    },
  ],
  layer: {
    peshat: "asked what his friend was like, a young ramp agent remembers ordinary days - the airplane given away, the blame taken, the chance let go - and cannot finish",
    sod: "the film opens the past for the first time and the threat becomes a man - and the man turns out to be made of a hundred small surrenders, no single wound to blame, which is worse, because it is everyone's; the prison was never bars, it was the daily choice of easier, the joke instead of the fight, the airplane handed to a man who wouldn't ask twice; and the one person who saw the gift and said reach carries the reaching now like a killing - because the friend finally reached, once, for the only airplane nobody could give away, and it took him; the machine learns who it is hunting exactly when it is too late to matter, which is the only time the world ever learns who anyone was",
  },
  beats: [
    {
      who: "REYES",
      want: "the human map of the man - not facts, who he WAS",
      wall: "Dez is wrecked and the true thing won't come; he reaches for it and lands on small stuff",
      turn: "she asks small - what was he like - and lets the silence run; Dez starts with a nothing memory (the app, the schedule) and the film goes back with him to an ordinary shift",
      subtext: "the machine's needs already met; this is the too-late learning; the kindness of small questions; the doorway opening",
    },
    {
      who: "BIRDY",
      want: "(flashback) to get through the shift without trouble for anybody",
      wall: "the schedule app hands the airplane he'd earned to someone else; the fair move is to say something",
      turn: "he looks at the tablet, and he doesn't say anything - 'easier' - he takes the worse assignment and moves; Dez, beside him, is the one who's angry for him",
      subtext: "the daily surrender shown, not named; the competence in his hands and the smallness in his silence; Dez already pushing him to reach",
    },
    {
      who: "BIRDY",
      want: "(flashback) to cover the kid and keep the peace",
      wall: "Tanner's mistake lands on the ramp and Ward looks for who to pin it on",
      turn: "Birdy takes it - lets Ward write it against him rather than give up the green kid - and laughs it off, the small joke instead of the fight; Tanner, oblivious, thanks-man and moves on; the turkey sandwich eaten standing up",
      subtext: "the purest cowardice is the kindness - protecting the man who cost him; the injustice routine, not cruel; Dez watching it cost his friend one more inch",
    },
    {
      who: "DEZ",
      want: "(flashback) to make his friend reach - put in for it, you're better than this",
      wall: "reaching is the one thing Birdy can't do; he deflects it with a smile",
      turn: "Dez tells him to put in for the thing (the slot, the program, the more) and Birdy lets it go by, gentle, 'maybe, we'll see' register; and the film comes back to the present - Dez, in the room, the reach a stone in him now, trying to say I told him to reach and not able to finish it",
      subtext: "the friend who saw the gift; the reach that became the airplane; the guilt that has no clean shape; the man learned too late; end on the unfinished sentence",
    },
  ],
  rules: [
    "THE GATEWAY + FLASHBACK STRUCTURE: open in the PRESENT (the holding area, Dez and Reyes) with a small human question; DISSOLVE to the FLASHBACK (the ramp, a few days ago, DAY) triggered by Dez's first small memory; play the memory; RETURN to the present at the end (Dez unable to finish). Mark the flashback clearly in action lines (the shift; daylight; the ordinary ramp) so a listener knows we've gone back and come back.",
    "THE COWARDICE IS SHOWN, NEVER NAMED (canon): no character says coward, afraid, small, pressure, be a man; it lives ONLY in behavior - the airplane given away and no word said, the blame taken with a joke, the chance let go with a smile. NO single explaining wound; the smallness is diffuse and daily. Birdy is KIND the whole time (the cowardice IS the kindness - he protects the kid who cost him).",
    "'EASIER' is the tell-word (established): Birdy's non-fight register - 'it's fine', 'easier', 'maybe, we'll see' - the small nice thing instead of the fight; his competence shown in his hands (he works well), his smallness in what he won't say.",
    "REYES asks SMALL and human and lets silences run - she is learning the man, too late; she is NOT interrogating for facts (those are known). DEZ deflects the big feeling into small memories and CANNOT finish the true sentence (the reach he pushed); the guilt stays under, never stated.",
    "THE DOORWAY: this is the FIRST flashback in the film - the moment the threat becomes a man. Do not signal it as 'a doorway'; just let the past open plainly and let the man arrive.",
    "SOURCED / REAL PEOPLE: Ward pins the blame WITHOUT malice (routine, not cruel); Tanner is oblivious, not a predator; the injustice is the honest system's, not a villain's. Every character pursues their own small want.",
    "ACTION LINES ARE FULL SENTENCES, PRESENT TENSE (the flashback plays in present tense like any scene); ORIENT every voice; INTRODUCE Tanner and re-anchor Ward/Dez lightly in the flashback; the SECOND CHANNEL is the ramp's physical work (the tablet/app, the bags, the tug, the sandwich).",
    "LIGHT: the flashback is DAY (an ordinary daylight shift - contrast with the golden-hour-into-dark of the flight); the present holding-area is night/interior.",
    "END on the unfinished sentence in the present - Dez trying to say he told his friend to reach and not able to finish it; no button, no summary, nobody names the meaning.",
    "Kill every catalog tell: doubled openers, engineered refrains, appended-fact fragments, list drumbeats, cross-character mirroring, summarizing Lines, thematic telegraphing, stated turns, manufactured stammers, parallel restatement, trailing-'so.' on anyone but Maya. American vernacular. Recorded, not written.",
    "Voice-differentiate: DEZ (young, unsteady, guilty, trailing), REYES (quiet, patient), BIRDY (soft, deflecting, 'easier'), TANNER (oblivious, quick), WARD (worn, flat).",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=5)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: VERSE 1 — THE RAMP (Dez; Doorway #1) ===\n")
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
