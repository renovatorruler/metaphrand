/* SCENE CRAFT - the Mercurio rubric, enforced (port of
   metaphrand/scene_craft.py; docs/07-SCENE-CRAFT.md). Is each scene a complete
   story that changes BOTH the plot AND a person? The model judges a written
   scene against a FIXED rubric, per criterion, so a clean scene is shown, not
   claimed. Over-flags by design (triage; the author's ear is the calibration).
   CORE criteria fail the gate; the rest are flags. Runs through Session (the
   one warm chokepoint, budget-guarded) - never call in bulk without
   CLAUDE_STUDIO_BUDGET set. */

type check = {
  id: string,
  desc: string,
  core: bool,
  passed: bool,
  note: string,
}

/* (id, description, core?) - CORE criteria fail the gate. */
let rubric = [
  ("single_action", "One focused action, one time & place (unity)", true),
  ("plot_change", "The situation ends shifted from how it opened", true),
  ("character_change", "A character's inner state shifts, caused by the scene's action", true),
  ("reversal", "A set-up surprise, inevitable in hindsight & rooted in character", true),
  ("beats", "Distinct, escalating beats - not one note repeated (Clurman)", false),
  ("escalation", "Stakes/accountability rise; hard for the protagonist", false),
]

let system =
  "You are a ruthless scene editor, not a writer, enforcing Jim Mercurio's scene craft. A SCENE is a " ++
  "story in itself: one action, in one time and place, that changes BOTH the plot AND a person.\n\n" ++
  "Judge the scene against EACH criterion; return pass/fail with a short reason:\n" ++
  "  single_action     - one focused action, one time & place. FAIL if two scenes are fused, or it meanders with no single dramatic event.\n" ++
  "  plot_change       - the external situation ends DIFFERENT from how it opened. FAIL if nothing in the story moves (a static info-dump or mood beat).\n" ++
  "  character_change  - a character's INNER state shifts, caused by what they do here. FAIL if everyone ends inside exactly as they began. This is the one most scenes miss.\n" ++
  "  reversal          - a surprise or directional shift, SET UP so it feels inevitable in hindsight and rooted in character (a frustrated expectation). FAIL if it is a frictionless straight line.\n" ++
  "  beats             - built of distinct, escalating beats, not one note repeated. FAIL if the beats are redundant or hold a single note.\n" ++
  "  escalation        - stakes and accountability RISE; it is hard for the protagonist. FAIL if it is easy or the pressure never mounts.\n\n" ++
  "Do NOT judge prose, subtext, or whether lines sound good - other gates handle those. Judge ONLY the dramatic architecture above. Be strict on character_change and reversal.\n\n" ++
  "Return ONLY JSON: {\"checks\":[{\"id\":\"<criterion>\",\"pass\":<true|false>,\"note\":\"<reason, max 12 words>\"}]}, one entry per criterion."

/* pull the {...} block and decode id -> (pass, note) */
let parse = (raw: string): Js.Dict.t<(bool, string)> => {
  let out = Js.Dict.empty()
  let jsonText = switch Js.Re.exec_(%re("/\{[\s\S]*\}/"), raw) {
  | Some(m) =>
    Js.Re.captures(m)->Belt.Array.get(0)->Belt.Option.flatMap(Js.Nullable.toOption)->Belt.Option.getWithDefault(raw)
  | None => raw
  }
  switch Js.Json.parseExn(jsonText) {
  | json =>
    switch Js.Json.decodeObject(json) {
    | Some(obj) =>
      switch Js.Dict.get(obj, "checks")->Belt.Option.flatMap(Js.Json.decodeArray) {
      | Some(rows) =>
        rows->Belt.Array.forEach(row =>
          switch Js.Json.decodeObject(row) {
          | Some(c) => {
              let id = Js.Dict.get(c, "id")->Belt.Option.flatMap(Js.Json.decodeString)
              let pass =
                Js.Dict.get(c, "pass")->Belt.Option.flatMap(Js.Json.decodeBoolean)->Belt.Option.getWithDefault(true)
              let note =
                Js.Dict.get(c, "note")
                ->Belt.Option.flatMap(Js.Json.decodeString)
                ->Belt.Option.getWithDefault("")
                ->Js.String2.slice(~from=0, ~to_=80)
              switch id {
              | Some(i) => Js.Dict.set(out, i, (pass, note))
              | None => ()
              }
            }
          | None => ()
          }
        )
      | None => ()
      }
    | None => ()
    }
  | exception _ => ()
  }
  out
}

/* judge one scene; missing criteria default to pass (never false-fail) */
let audit = async (scene: string): array<check> => {
  let raw = await Session.ask(system ++ "\n\nJudge this scene against every criterion.\n\nSCENE:\n" ++ Js.String2.trim(scene))
  let got = parse(raw)
  rubric->Belt.Array.map(((id, desc, core)) => {
    let (passed, note) = Js.Dict.get(got, id)->Belt.Option.getWithDefault((true, ""))
    {id, desc, core, passed, note}
  })
}

let report = (checks: array<check>, ~heading: string=""): string => {
  let head = heading == "" ? "scene craft" : "scene craft - " ++ heading
  let fails = checks->Belt.Array.keep(c => !c.passed)
  if Belt.Array.length(fails) == 0 {
    head ++ ": PASS - all " ++ Belt.Int.toString(Belt.Array.length(checks)) ++ " criteria met."
  } else {
    let coreN = fails->Belt.Array.keep(c => c.core)->Belt.Array.length
    let lines = [
      head ++
      ": " ++
      Belt.Int.toString(coreN) ++
      " core FAIL, " ++
      Belt.Int.toString(Belt.Array.length(fails) - coreN) ++ " flag(s)",
    ]
    checks->Belt.Array.forEach(c => {
      let mark = c.passed ? "ok  " : c.core ? "FAIL" : "flag"
      let line = "  " ++ mark ++ " " ++ c.id ++ " - " ++ c.desc
      Js.Array2.push(lines, !c.passed && c.note != "" ? line ++ "  -> " ++ c.note : line)->ignore
    })
    lines->Belt.Array.joinWith("\n", x => x)
  }
}

let gate = async (scene: string): (bool, string) => {
  let checks = await audit(scene)
  let coreFails = checks->Belt.Array.keepMap(c => c.core && !c.passed ? Some(c.id) : None)
  Belt.Array.length(coreFails) == 0
    ? (true, "scene-craft clean")
    : (false, "core fails: " ++ coreFails->Belt.Array.joinWith(", ", x => x))
}
