/* THE GAUNTLET — adversarial regression suite for every text gate (docs/09).
   Each gate faces two fixtures: the disease it hunts (must FLAG) and a clean
   control (must PASS). Fixtures are fossilized user catches — the dead barn
   scene, the fog register, the safe-outline family — so taste regressions
   become build failures. Hermetic: pure text only, no fs state (env-dependent
   gates live in Ports_Smoke; spine telemetry in FourOlds_DramaRun).
   MECHANICAL section is free and always runs.
   JUDGES section costs model calls: JUDGES=1 CLAUDE_STUDIO_BUDGET=12 node src/Gauntlet.res.mjs */

@val external env: Js.Dict.t<string> = "process.env"
@val @scope("process") external exit: int => unit = "exit"

let passed = ref(0)
let failed = ref(0)

type expect = Flag | Pass

let assert_ = (name: string, flagged: bool, want: expect) => {
  let ok = switch want {
  | Flag => flagged
  | Pass => !flagged
  }
  if ok {
    passed := passed.contents + 1
    Js.log("  ok    " ++ name)
  } else {
    failed := failed.contents + 1
    Js.log(
      "  MISS  " ++
      name ++
      (want == Flag ? " — the disease walked through" : " — clean text got flagged (false positive)"),
    )
  }
}

/* ============ FIXTURES ============ */

/* the dead sim scene — the real corpse (a03 v14.2, trimmed): procedure,
   no want, no cost, no clock. Fixture #1 by right. */
let barnDead = `CRICKET: Net's open. Tuesday, nineteen-oh-two local.
DUTCH: Bus B first. What's it read.
CRICKET: Twenty-eight point one.
GUNNY: It's nineteen-oh-three, gentlemen. Commander, run your checklist.
CRICKET: Guidance internal. Tanks at sixty-two percent, simulated. Descent program loaded.
CRICKET: Three hundred feet. Drifting left. Correcting.
CRICKET: Contact light. Engine stop.
STITCH: Hair late on the throttle there at the end.
CRICKET: Net closed. Same time Tuesday.`

/* a fight: want, wall, turn, two changes */
let keysFight = `ACTION: Sam pockets the truck keys.
RAY: Give me the keys.
SAM: You're three beers in.
RAY: Dad's on the floor of the pharmacy, Sam.
ACTION: Ray puts his hand out. Sam looks at the beer on the table, then at his brother.
SAM: I'm driving.
ACTION: Sam takes his coat. Ray follows him out.`

/* my own fog register, parodied — every trick the clarity law bans */
let fog = "The signal came back wrong again. He looked at the others and they knew. After Meridian there was no point pretending, so she did what she always did, and the box on the table stayed shut. Outside, the second one was already starting."

let clear = "Cricket, seventy-nine, stands at the Apollo flags in a museum spacesuit, flipping burgers on a small grill. Around him, six astronauts in modern suits hold the cables they were sent to take the flags down with. On the radio, his two surviving crewmates argue about grill temperature. Earth is watching all of it live, and somewhere in a control room a man orders Cricket's oxygen cut."

/* functions in costumes vs. Russell's real ATC exchange (compost) */
let inert = "JENSEN: The quarterly numbers are in. MARKS: Revenue is up four percent. JENSEN: Good. Schedule the board review. MARKS: Tuesday work? JENSEN: Tuesday works. Send the deck tonight. MARKS: Will do."

let alive = "CONTROLLER: There is a runway just off to your right side in about a mile. RICH: Oh man, those guys would rough me up if I tried landing there. I think I might mess something up there too. I wouldn't want to do that. Oh, they've probably got anti-aircraft. CONTROLLER: No, they don't have any of that stuff. We're just trying to find a place for you to land safely. RICH: Yeah, not quite ready to bring it down just yet."

/* ============ MECHANICAL (free, always) ============ */

let flaggedAction = (t: string): bool =>
  switch Craft.gateAction(t) {
  | Ok() => false
  | Error(_) => true
  }
let flaggedDialogue = (t: string): bool =>
  switch Craft.gateDialogue(t) {
  | Ok() => false
  | Error(_) => true
  }

let tellHits = (name: string, s: string): bool =>
  switch Tells.tells->Belt.Array.getBy(t => t.name == name) {
  | Some(t) => Js.Re.test_(t.re, s)
  | None => {
      Js.log("  MISS  no such tell in the registry: " ++ name)
      failed := failed.contents + 1
      false
    }
  }

let mechanical = () => {
  Js.log("== CRAFT DEVICES (action lines) ==")
  assert_("em-dash chain", flaggedAction("The barn — gray, patient — waited."), Flag)
  assert_("rule-of-three cadence", flaggedAction("He wanted glory, vindication, peace."), Flag)
  assert_("plain action passes", flaggedAction("Cricket kicks the inverter case and the needle climbs home."), Pass)

  Js.log("== CRAFT DEVICES (dialogue) ==")
  assert_("corrective definition", flaggedDialogue("That's not mercy. That's arithmetic."), Flag)
  assert_("negative parallelism", flaggedDialogue("It's not just a flag, it's the whole country."), Flag)
  assert_("plain dialogue passes", flaggedDialogue("Give me the keys, Sam. Dad's on the floor of the pharmacy."), Pass)

  Js.log("== ECHO DETECTOR ==")
  assert_(
    "flat echo across speakers",
    Craft.echoViolation(~prev="You walk away.", ~cur="Walk away.")->Belt.Option.isSome,
    Flag,
  )
  assert_(
    "question echo is legal",
    Craft.echoViolation(~prev="You walk away.", ~cur="Walk away? From what?")->Belt.Option.isSome,
    Pass,
  )

  Js.log("== NAMED TELLS (expository) ==")
  assert_("meeting leak", tellHits("Meeting Leak", "As discussed, the flow now opens on the invite."), Flag)
  assert_("closer summary", tellHits("Closer Summary", "In conclusion, the system works."), Flag)
  assert_("delve", tellHits("Delve/Dive", "Let's delve into the architecture."), Flag)
  assert_("hedge stack", tellHits("Hedge Stack", "While it is important to note that gates exist, coverage varies."), Flag)
  assert_("plain expository passes", tellHits("Closer Summary", "The system has nine gates. Three are typed."), Pass)

  Js.log("== SHOW-DON'T-TELL ==")
  assert_("interiority + state told", Belt.Array.length(Showing.tells("He felt afraid and realized Ray was brave.")) > 0, Flag)
  assert_("behavior shown passes", Belt.Array.length(Showing.tells("Ray set the wrench down and stood in the doorway.")) > 0, Pass)

  Js.log("== CONCRETENESS ==")
  assert_("ornament", Belt.Array.length(Concreteness.findings("The glass bleeds rainbows like veins of destiny.")) > 0, Flag)
  assert_("bare fact passes", Belt.Array.length(Concreteness.findings("Her skin is cold.")) > 0, Pass)

  Js.log("== HEART LEDGER ==")
  let unbanked = [
    {Heart.beat: "b1", bond: Heart.Bond("a+b"), move: Heart.Thaw("the apology argument")},
  ]
  let banked = [
    {Heart.beat: "b1", bond: Heart.Bond("a+b"), move: Heart.Deposit("the thermos")},
    {Heart.beat: "b2", bond: Heart.Bond("a+b"), move: Heart.Thaw("the thermos")},
  ]
  assert_("unbanked thaw", !Heart.passed(Heart.audit(unbanked)), Flag)
  assert_("banked thaw passes", !Heart.passed(Heart.audit(banked)), Pass)

  Js.log("== DENSITY ==")
  let wrapped = Density.audit(~scenes=[("s1", Density.Bone), ("s2", Density.Bone), ("s3", Density.Bone)], ~wants=[])
  let fleshed = Density.audit(
    ~scenes=[("s1", Density.Bone), ("s2", Density.Flesh), ("s3", Density.Flesh), ("s4", Density.Bone)],
    ~wants=[],
  )
  assert_("shrink-wrap", !Density.passed(wrapped), Flag)
  assert_("fleshed world passes", !Density.passed(fleshed), Pass)
}

/* ============ JUDGES (model, budgeted, run when prompts change) ============ */

let judges = async () => {
  Js.log("== LANGUAGE JUDGE ==")
  let drip = await Judge.language("Forty-one people, a church group, the wrong neighborhood, gone.")
  assert_("comma-drip", Belt.Array.length(drip) > 0, Flag)
  let plain = await Judge.language("The truck would not start, so Ray walked the four miles into town.")
  assert_("plain sentence passes", Belt.Array.length(plain) > 0, Pass)

  Js.log("== DRAMA JUDGE (the barn corpse) ==")
  let dead = await Judge.concept(Process.Drama, barnDead)
  assert_("the dead sim scene", dead->Belt.Option.isSome, Flag)
  let fight = await Judge.concept(Process.Drama, keysFight)
  assert_("the keys fight passes", fight->Belt.Option.isSome, Pass)

  Js.log("== HUMAN REACTION ==")
  let numb = await Judge.concept(Process.HumanReaction, inert)
  assert_("functions in costumes", numb->Belt.Option.isSome, Flag)
  let felt = await Judge.concept(Process.HumanReaction, alive)
  assert_("Russell's real exchange passes", felt->Belt.Option.isSome, Pass)

  Js.log("== CLARITY ==")
  let (fogOk, _) = await Clarity.gate(fog)
  assert_("the fog register", !fogOk, Flag)
  let (clrOk, _) = await Clarity.gate(clear)
  assert_("the clear pane passes", !clrOk, Pass)

  Js.log("== SCENE CRAFT (Mercurio) ==")
  let deadChecks = await SceneCraft.audit(barnDead)
  let deadCore = deadChecks->Belt.Array.keep(c => c.core && !c.passed)->Belt.Array.length
  assert_("barn fails a core criterion", deadCore > 0, Flag)
  let fightChecks = await SceneCraft.audit(keysFight)
  let fightCore = fightChecks->Belt.Array.keep(c => c.core && !c.passed)->Belt.Array.length
  assert_("keys fight clears the core rubric", fightCore > 0, Pass)
}

let main = async () => {
  Js.log("THE GAUNTLET\n")
  mechanical()
  switch Js.Dict.get(env, "JUDGES") {
  | Some("1") => {
      Js.log("")
      await judges()
    }
  | _ => Js.log("\n(judge fixtures skipped — JUDGES=1 CLAUDE_STUDIO_BUDGET=12 to run)")
  }
  Js.log(
    "\nGAUNTLET: " ++
    Belt.Int.toString(passed.contents) ++
    " ok, " ++
    Belt.Int.toString(failed.contents) ++ " miss" ++ (failed.contents == 1 ? "" : "es"),
  )
  exit(failed.contents == 0 ? 0 : 1)
}
main()->ignore
