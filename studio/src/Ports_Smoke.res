/* PORTS SMOKE - proves the recovered-enforcer ports without spending model
   budget: the five pure gates run on real/demo data; the two Session-based
   judges (SceneCraft, BlindAttribution) get their PARSERS exercised on fixed
   transcripts - the model paths compile and run later inside the battery
   with CLAUDE_STUDIO_BUDGET set. Run: node src/Ports_Smoke.res.mjs */

let stories = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories"

let main = () => {
  /* 1 - PREFLIGHT on the real FOUR OLDS story dir (honest result) */
  Js.log("== Preflight (four-olds, principals) ==")
  let cast = ["cricket", "dutch", "stitch", "gunny", "marwani", "hale", "vess", "brandt"]
  let fails = Preflight.audit(~storiesDir=stories, ~slug="four-olds", ~cast)
  Js.log(Preflight.report(~slug="four-olds", fails))

  /* 2 - HEART ledger: a clean ledger and each violation class */
  Js.log("\n== Heart ==")
  let good = [
    {Heart.beat: "b1", bond: Heart.Bond("cricket+danny"), move: Heart.Deposit("the thermos")},
    {Heart.beat: "b3", bond: Heart.Bond("cricket+danny"), move: Heart.Wound("the unsigned papers")},
    {Heart.beat: "b7", bond: Heart.Bond("cricket+danny"), move: Heart.Thaw("the thermos")},
    {Heart.beat: "b8", bond: Heart.Bond("cricket+danny"), move: Heart.Unlocks("the launch blessing")},
  ]
  let (okG, sumG) = Heart.gate(good)
  Js.log((okG ? "PASS " : "FAIL ") ++ sumG)
  let bad = [
    {Heart.beat: "b2", bond: Heart.Bond("a+b"), move: Heart.Wound("the slap")},
    {Heart.beat: "b4", bond: Heart.Bond("a+b"), move: Heart.Thaw("the apology argument")},
  ]
  let (okB, sumB) = Heart.gate(bad)
  Js.log((okB ? "PASS (gate too weak!) " : "FAIL as expected: ") ++ sumB)

  /* 3 - DENSITY: a shrink-wrapped seed vs a fleshed one */
  Js.log("\n== Density ==")
  let wrapped = Density.audit(
    ~scenes=[("s1", Density.Bone), ("s2", Density.Bone), ("s3", Density.Bone), ("s4", Density.Flesh)],
    ~wants=[("earlene", false)],
  )
  Js.log((Density.passed(wrapped) ? "PASS (gate too weak!) " : "FAIL as expected: ") ++ Density.summary(wrapped))
  let fleshed = Density.audit(
    ~scenes=[
      ("s1", Density.Bone),
      ("s2", Density.Flesh),
      ("s3", Density.Bone),
      ("s4", Density.Flesh),
      ("s5", Density.Flesh),
      ("s6", Density.Bone),
    ],
    ~wants=[("earlene", true), ("joss", true)],
  )
  Js.log((Density.passed(fleshed) ? "PASS: " : "FAIL ") ++ Density.summary(fleshed))

  /* 4 - SHOWING: a told line vs a shown line */
  Js.log("\n== Showing ==")
  let told = "He felt afraid and realized there was no out-arguing him; Ray was brave."
  let shown = "Ray set the wrench down and put himself between the door and his brother."
  Js.log(
    "told  -> score " ++
    Js.Float.toString(Showing.showScore(told)) ++
    " [" ++
    Showing.tells(told)->Belt.Array.joinWith("; ", Showing.show) ++ "]",
  )
  Js.log("shown -> score " ++ Js.Float.toString(Showing.showScore(shown)) ++ " (tells: " ++ Belt.Int.toString(Belt.Array.length(Showing.tells(shown))) ++ ")")

  /* 5 - CONCRETENESS: ornament vs bare fact */
  Js.log("\n== Concreteness ==")
  let flowery = "The glass bleeds rainbows like veins of *destiny*."
  let bare = "Her skin is cold."
  Js.log(
    "flowery -> score " ++
    Js.Float.toString(Concreteness.score(flowery)) ++
    " [" ++
    Concreteness.findings(flowery)->Belt.Array.joinWith("; ", Concreteness.show) ++ "]",
  )
  Js.log("bare    -> score " ++ Js.Float.toString(Concreteness.score(bare)))

  /* 6 - SCENECRAFT parser on a fixed model transcript (no Session call) */
  Js.log("\n== SceneCraft (parser only - the judge runs in the battery) ==")
  let fixed = "Here you go: {\"checks\":[{\"id\":\"single_action\",\"pass\":true,\"note\":\"\"},{\"id\":\"character_change\",\"pass\":false,\"note\":\"nobody ends changed\"}]}"
  let got = SceneCraft.parse(fixed)
  switch Js.Dict.get(got, "character_change") {
  | Some((false, note)) => Js.log("parsed core fail correctly: character_change -> " ++ note)
  | _ => Js.log("PARSER BROKEN")
  }

  /* 7 - BLIND ATTRIBUTION parsers (no Session call) */
  Js.log("\n== BlindAttribution (parsers only - the judge runs in the battery) ==")
  let cards = "### Cricket - `cricket`\nchecklist grammar\n### Stitch - `stitch`\nrounds every number"
  Js.log("keys: " ++ BlindAttribution.keysFromCards(cards)->Belt.Array.joinWith(", ", x => x))
  let script = "CRICKET: Net's open. Tuesday.\nSTITCH: Five hundred feet, easy.\nINT. BARN - NIGHT\nnote: not a cue"
  let pairs = BlindAttribution.parseDialogue(script)
  Js.log(
    "dialogue parsed: " ++
    pairs->Belt.Array.joinWith(" | ", ((k, t)) => k ++ ": " ++ Js.String2.slice(t, ~from=0, ~to_=18)),
  )
  let calls = BlindAttribution.parseCalls("{\"calls\":[{\"line\":0,\"speaker\":\"CRICKET\"},{\"line\":1,\"speaker\":\"stitch\"}]}")
  Js.log("calls parsed: 0->" ++ Js.Dict.get(calls, "0")->Belt.Option.getWithDefault("?") ++ " 1->" ++ Js.Dict.get(calls, "1")->Belt.Option.getWithDefault("?"))

  Js.log("\nPORTS SMOKE DONE")
}
main()
