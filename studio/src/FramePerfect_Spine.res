/* FRAME PERFECT - a Brehon story, v2: human-denominated (the user's law).
   The stakes are PEOPLE - belonging, standing, being heard, the ability to
   stop - never the mechanism; the process supplies walls and turns only.
   The Sod - an ending is the gift; repeat play is how strangers love each
   other - is never stated; the last image carries it. */

let spine: DramaCards.spine = {
  story: "FRAME PERFECT - a Brehon story (human-centered v2)",
  truth: {
    premise: {
      x: "A fight that has no way to end",
      leadsTo: "eats a man's people and his sleep; a true ending, even a lost one, leads to",
      y: "getting his people and his evenings back",
    },
    argument: {
      claim: "People do not need to win their fights; they need their fights to end.",
      antithesis: "An ending you did not win is surrender wearing a robe - some fights ARE the self-respect, and a man who lets a stranger close his fight has traded his spine for sleep.",
    },
    designingPrinciple: "Two hostages of the same argument, freed by strangers who end fights for a living.",
    lighthouse: "The caucus. A retired paralegal reads her client's own forum posts back to him, flat, one after another, until the rage sounds like what it is - a lonely man missing his people. She asks what he actually wants back. He opens his mouth to say the record, and says: Tuesday nights. Across town her opposite number of forty cases just listens, and the silent moderator talks for forty minutes straight, because someone is finally paid to hear him.",
    authorialStake: "The unfashionable claim, said sincerely: closure is a public good - peace is worth more than vindication, and a working institution is a kind of love between strangers.",
    contestedObject: {
      object_: "Marco's name on the board of the forum he has lived in for seventeen years - which is his standing in front of the only people who watched him chase it.",
      whyBothCannotHave: "The slot is public and binary: restored says he is one of them and the removal wronged him; removed says he cheated the people he loves. One line, one name, in the town square - whichever way it reads, one of the two men is publicly wrong.",
    },
    opponentPlan: [
      "Purge the verification backlog of every suspect run, oldest first, no explanations",
      "Tighten the tool-assist rule so borderline tricks are removable on suspicion alone",
      "Keep the board credible so the community he built survives its own nostalgia",
      "Hand a clean board to a successor and leave the unpaid job without being remembered as the tyrant",
    ],
  },
  opening: {
    id: "f01_removed",
    summary: "The record lands after seventeen years and the thread erupts - his people, cheering. The removal arrives mid-celebration, one line, and the cheering curdles in place.",
    povWant: "Marco wants to be believed by the people who watched him chase it for seventeen years",
    obstacle: "the one man whose word is the town square's verdict will not say why",
    fortune: -2,
    stakes: 3,
    question: "What happens to a man when his own people go quiet on him?",
  },
  beats: [
    {
      id: "f02_attrition",
      edge: But, /* in spite of everything he throws, the silence holds */
      cause: Antagonist,
      summary: "He cannot stop. Every rant costs him a friend; the regulars stop replying; his roommate goes quiet on the fourth retelling. The mute lands and he is outside the window of the only room he belongs in, read-only.",
      povWant: "He wants to stop - he can hear himself - and the loop will not let him",
      obstacle: "silence gives him nothing to push against, so the argument runs on him instead",
      fortune: -3,
      stakes: 5,
      antagonistAction: Some("the removal stands unexplained; the mute does the moderator's talking"),
      question: "How does a man put down a fight that has become his whole day?",
    },
    {
      id: "f03_demand",
      edge: Therefore, /* because the noise failed, he tries one clean sentence */
      cause: Protagonist,
      summary: "The demand form takes one sentence, so he has to fold forty-seven posts into one. Writing it is the first night he sleeps. The refusal comes back with one tap - and even that is the first acknowledgment in months that he exists.",
      povWant: "One answer from a human being - any answer, on any record",
      obstacle: "the man in possession can still refuse for free; his time still costs nothing",
      fortune: -2,
      stakes: 5,
      antagonistAction: Some("Dee refuses with one tap between backlog purges, unbothered"),
      question: "What would it take to make the silent man actually show up?",
    },
    {
      id: "f04_bonds",
      edge: Therefore, /* the refusal opens the one gate where weight enters */
      cause: Protagonist,
      summary: "Both men put something behind their word. His roommate asks if he has lost his mind; that night he sleeps eight hours - weight on the table quiets the head. Now losing means being the forum's cheat, in front of everyone, forever.",
      povWant: "To make the fight real enough that it has to end one way or the other",
      obstacle: "his own stake: from here, an ending can cost him the story he tells about himself",
      fortune: -1,
      stakes: 7,
      antagonistAction: Some("Dee matches the bond out of contempt and mutes the thread again"),
      question: "Now that it can end - can he bear whichever ending comes?",
    },
    {
      id: "f05_advocates",
      edge: Therefore, /* the bonds retain the professionals */
      cause: Protagonist,
      summary: "The advocates take over, forty cases of history between them. Her caucus: his own posts read back flat until he hears the loneliness under the rage; what does he want back - Tuesday nights. His counterpart just listens, and Dee talks forty minutes straight, the first hearing HE has had in years.",
      povWant: "Each man, without knowing it, wants what the advocate gives first: to be heard",
      obstacle: "rage and contempt do not fold into one clean claim without a fight of their own",
      fortune: 0,
      stakes: 7,
      antagonistAction: Some("the opposing advocate shapes Dee's years of thankless purges into a cold, fair case"),
      question: "If being heard was most of what they wanted - what is left to fight about?",
    },
    {
      id: "f06_nearsettle",
      edge: But, /* in spite of a fair deal, he refuses it */
      cause: Protagonist,
      summary: "The advocates reach a fair settlement in nine moves. Marco kills it - she doesn't even care about the run, none of them do - because after two years the fight is the last thing that is his. His advocate has seen forty men decline; she tells him, flat, what refusing has ever bought any of them.",
      povWant: "He wants the fury FELT, not resolved - the grievance has become who he is",
      obstacle: "the deal is genuinely fair and everyone in the room, including him, knows it",
      fortune: -4,
      stakes: 9,
      antagonistAction: Some("Dee's side pockets the refusal as proof the man was never reasonable"),
      question: "Who is he, if the argument ends?",
    },
    {
      id: "f07_deadlock",
      edge: Therefore, /* the refusal burns the clocks to zero */
      cause: ThirdParty,
      summary: "Deadlock. Final offers, word-for-word - so each advocate writes the other man's humanity into her page: hers concedes Dee acted in good faith; his concedes Marco ran clean under the rule as written. The most reasonable pages of both their careers.",
      povWant: "Each advocate wants to write the offer a fair stranger cannot refuse",
      obstacle: "one self-serving clause hands the case, and her client's name, to the other side",
      fortune: -5,
      stakes: 10,
      antagonistAction: Some("the opposing offer concedes just enough to be the more reasonable page"),
      question: "When both pages are fair - what is actually being judged?",
    },
    {
      id: "f08_adjudicator",
      edge: But, /* in spite of the deadlock, one shared elder exists */
      cause: Protagonist,
      summary: "The parties seat the one person both men learned the game under: the board's retired founder. Asking him is itself the first thing they have done together in two years - an admission the fight outgrew them both. The audience is asked to rule before he does.",
      povWant: "Both men want, for one minute, the same thing: a judge they can believe",
      obstacle: "believing the judge means agreeing, in advance, to be the one who was wrong",
      fortune: -4,
      stakes: 10,
      antagonistAction: Some("the opposing advocate rests on her page and starts the ruling clock"),
      question: "Bent, or broken - what would you rule, knowing both men now?",
    },
    {
      id: "f09_ruling",
      edge: But, /* in spite of his hope, the verdict goes against him */
      cause: ThirdParty,
      summary: "One citable sentence. The removal stands - and the sentence gives both men back their names: ran clean under a rule that was broken; removed in good faith by a man doing an unpaid job. No cheat, and no tyrant, on the record, in front of everyone. Marco loses, and breathes.",
      povWant: "He walked in wanting vindication; what the ending hands him is his life back",
      obstacle: "the strongest fair case against him, standing word-for-word as the ruling",
      fortune: 1,
      stakes: 10,
      antagonistAction: Some("the opposing final offer becomes the ruling, word for word"),
      question: "What does the first evening after a two-year argument feel like?",
    },
    {
      id: "f10_fortysecond",
      edge: Therefore, /* endings hold; the porch takes people back */
      cause: Protagonist,
      summary: "Three weeks later, a thread about frame timing. Marco is posting about the game again. Four replies down, Dee answers him - technical, no weather - and nobody remarks. In the background the two advocates accept their forty-second case, opposite sides.",
      povWant: "Everyone on the board wants what these two quietly have: a fight that stayed ended",
      obstacle: "only the next dispute, already arriving somewhere, as disputes always do",
      fortune: 2,
      stakes: 10,
      antagonistAction: None,
      question: "How many endings does a place need before its people trust it with their fights?",
    },
  ],
  climaxId: "f09_ruling",
}
