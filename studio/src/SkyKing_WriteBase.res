/* Act 1, beat 4 — THE BASE (light seed). Two ANG fighter pilots sit a dead alert
   shift. The wingman (BANJO) can't stand the quiet and keeps trying to get the lead
   (DEACON) to be real with him; DEACON gives him nothing but the job. A scramble
   tone lights them alive, then stands down to nothing. THE SOD: these "brave" men
   are stuck too - DEACON is his own quiet coward, Birdy in a flight suit - and both
   ache for something real to matter and can't say it; tomorrow a baggage handler
   will hand it to them. Seeds the two who intercept and are awed in Act 2. NO villain,
   NO theme on the page. Recorded, not written. Engine-written; the Sod stays under. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-base.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-base",
  slug: "INT. ALERT FACILITY, AIR NATIONAL GUARD FIGHTER BASE - DAY",
  logline: "Two fighter pilots kill the back half of a dead alert shift. The wingman can't sit in the quiet and keeps needling the lead to be real with him; the lead gives him nothing but the job. A scramble tone lights them alive for ten seconds and stands down to nothing, and they sit back down to wait - two men going nowhere, the day before a baggage handler in a stolen plane hands them the realest thing of their lives.",
  cast: [
    {
      name: "DEACON",
      who: "the flight lead, about 40; serious, controlled, by-the-book; deflects everything into the job or a task; stuck and won't say it - his own quiet coward, the rhyme with Birdy, a brave man who long ago stopped reaching for anything real.",
      register: "terse, closed, procedural; short answers; turns any real thing into a task, a rule, or the schedule; never emotes; the deflection is a task, not a joke.",
      earnsEloquence: false,
      lexicon: "the alert, the jets, the tasking, the gear said flat and literal; the room and the hours said flat; NEVER a metaphor for a feeling.",
    },
    {
      name: "BANJO",
      who: "the wingman, about 30; dry, restless, can't stand silence; needles and gripes and keeps talking to fill the quiet - but tired and real, not a joke machine; he aches loudest and hides it in the clowning.",
      register: "loose, associative, complaining about small true things (the vending machine, the busted recliner, the milk-run tasking); his funny is FLAT and dry, never a written punchline; he trails on, repeats, keeps the noise going so the quiet can't land.",
      earnsEloquence: false,
      lexicon: "mundane gripes about the room and the food and the schedule; flying said flat and literal.",
    },
  ],
  layer: {
    peshat: "two fighter pilots kill a long dead shift on alert; a scramble tone sounds and stands down; they go back to waiting",
    sod: "these are the 'brave' men, and the lead is his own kind of coward - stuck, won't reach, won't say the life has gone hollow, a rhyme with Birdy; both ache for something real to matter and can't say it; tomorrow a baggage handler in a stolen plane will give them the realest thing of their lives, and this dead afternoon is the hunger that will make them see him",
  },
  beats: [
    {
      who: "BANJO",
      want: "to get Deacon to bite - to be real with him, break the dead quiet",
      wall: "Deacon gives him nothing, just the job",
      turn: "Banjo riffs and gripes and pushes; Deacon answers short and turns it into a task or a rule; the quiet closes back over them",
      subtext: "Banjo's clowning is a plea for something to matter; Deacon's flatness is his cowardice - he won't reach, won't admit he's as stuck and starved as Banjo is",
    },
    {
      who: "DEACON",
      want: "the tone to be real - to move, to matter, for ten seconds",
      wall: "nothing ever happens on this alert; it's all milk runs and false alarms",
      turn: "the scramble tone sounds - both light up and move fast and sure for the jets, fully alive - and it stands down: a strayed light plane already turned around; they come off the step and sit back down",
      subtext: "the honest ache under all the boredom - they live for that tone; how badly the controlled by-the-book lead wants it to be real shows in how fast he moves; the deflation seeds the day it IS real",
    },
    {
      who: "BANJO",
      want: "to name it - to get Deacon to admit they'll do this till they retire and nothing will ever happen",
      wall: "Deacon won't say it",
      turn: "Banjo says the closest thing to true he'll let himself say; Deacon gives the small it's-the-job deflection, finds a task, and they settle back into the wait",
      subtext: "the trap they're both in, named as close as men like this name anything; Deacon is Birdy in a flight suit; the hunger is set for tomorrow",
    },
  ],
  rules: [
    "Action lines = ONLY what the camera sees or the mic hears. No interiority, no naming feelings.",
    "THEME never stated: no one says trapped, stuck, coward, bored, going nowhere, aching, matter, real, hollow, or dream. The boredom and the hunger show ONLY through behavior and mundane talk.",
    "The 'FUNNY' wingman (BANJO) is DRY, TIRED, REAL - griping about small true things (the vending machine, the busted recliner, the tasking). His humor is FLAT and never a written punchline or a clever button. NO banter, NO quippy back-and-forth, NO snappy exchange where every beat lands. Recorded, not written.",
    "Voice-differentiate HARD: DEACON = terse, closed, procedural, deflects into a task or a rule, short answers. BANJO = loose, associative, complaining, keeps talking to fill the quiet. A reader must tell who's speaking with the names stripped. NEITHER is witty for the audience.",
    "The scramble is real procedure - a tone, the steps to the jets, a stand-down call - handled flat and fast, NOT movie-dramatic; no heroic scramble writing, no music-cue prose.",
    "Military shop-talk is LITERAL and flat (the tasking, the jets, the alert, the schedule), never a symbol for a feeling.",
    "DEACON's stuckness - the coward among the brave, the Birdy-rhyme - stays UNDER: shown only as his refusal to reach or to say anything real, NEVER stated.",
    "Keep the SURFACE light (two guys killing time) while the hunger for something real sets underneath, so Act 2's scramble pays off. No self-pity, no melodrama.",
    "Plain, mundane, a little baggy: most lines run a touch too long or trail off; clip a line ONLY when a specific beat earns the curtness, never as the default rhythm. When in doubt, make it worse.",
    "No aviation poetry. No one gives a Line. No appended-fact tags stapled after a sentence closes.",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=4)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: THE BASE (two pilots, dead alert shift) ===\n")
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
