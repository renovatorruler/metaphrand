/* BATTERY — the one doorway (docs/05 as an executable; stage rubrics held).
   A scene walks every gate in order and comes out with ONE report.

   SUBSTANCE (default): is this the right scene? Mechanical floor first
   (craft devices per line, echo pairs, show-don't-tell and ornament on
   ACTION lines only — dialogue is exempt by law), then the judges:
   Clarity (orientation), Drama (the fight), SceneCraft (the two changes,
   core criteria), HumanReaction (does it move anyone — strict). BLOCKS:
   exit 1 on any fail. A pass means "worth the author's read" — the human
   is the stop, never this program.

   FINISHING (--finishing): line law only, structure locked. The One Law
   judge (comma-drip / forced-triad / arranged-for-effect) as TRIAGE — it
   over-flags by design; the author's ear is the calibration. Reports,
   never blocks (exit 0).

   Run: CLAUDE_STUDIO_BUDGET=8 node src/Battery.res.mjs <scene.txt> [--finishing]
   Without a budget env the judges are skipped and the floor still runs. */

@module("fs") external readFileSync: (string, string) => string = "readFileSync"
@module("fs") external writeFileSync: (string, 'a) => unit = "writeFileSync"
@module("fs") external existsSync: string => bool = "existsSync"
@val @scope("Buffer") external bufferFrom: 'a => 'b = "from"
@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external exit: int => unit = "exit"
@val external env: Js.Dict.t<string> = "process.env"

/* ---- report buffer: console + sidecar ---- */
let buf: array<string> = []
let say = (s: string) => {
  Js.log(s)
  Js.Array2.push(buf, s)->ignore
}

let failed = ref(false)
let verdict = (name: string, ok: bool, detail: string) => {
  if !ok {
    failed := true
  }
  say("  " ++ (ok ? "ok    " : "FAIL  ") ++ name ++ (detail == "" ? "" : " — " ++ detail))
}
let info = (name: string, detail: string) => say("  info  " ++ name ++ " — " ++ detail)

/* ---- a light line classifier (Write's parser stays sealed; this one only
   reads, it cannot mint scenes) ---- */
type line = Action(string) | Dialogue(string, string) /* who, text */
let dlgRe = %re("/^([A-Z][A-Z .'`#-]*?)\s*(?:\((?:RADIO|WHISPER|PA|TV|ON TV)\))?\s*:\s*(.+)$/")

let classify = (raw: string): array<line> =>
  Js.String2.split(raw, "\n")
  ->Belt.Array.map(Js.String2.trim)
  ->Belt.Array.keep(l => l != "" && !Js.String2.startsWith(l, "#") && !Js.String2.startsWith(l, "["))
  ->Belt.Array.map(l =>
    if Js.String2.startsWith(l, "ACTION:") {
      Action(Js.String2.trim(Js.String2.sliceToEnd(l, ~from=7)))
    } else {
      switch Js.Re.exec_(dlgRe, l) {
      | Some(m) => {
          let g = Js.Re.captures(m)
          let who = g->Belt.Array.get(1)->Belt.Option.flatMap(Js.Nullable.toOption)->Belt.Option.getWithDefault("")
          let text = g->Belt.Array.get(2)->Belt.Option.flatMap(Js.Nullable.toOption)->Belt.Option.getWithDefault("")
          Js.String2.length(who) <= 24 ? Dialogue(Js.String2.trim(who), Js.String2.trim(text)) : Action(l)
        }
      | None => Action(l)
      }
    }
  )

/* ---- the mechanical floor (free) ---- */
let floor = (lns: array<line>) => {
  say("- mechanical floor")
  let deviceViols = []
  lns->Belt.Array.forEach(l =>
    switch l {
    | Action(t) =>
      switch Craft.gateAction(t) {
      | Ok() => ()
      | Error(vs) => vs->Belt.Array.forEach(v => Js.Array2.push(deviceViols, Craft.show(v) ++ "  @ " ++ Js.String2.slice(t, ~from=0, ~to_=60))->ignore)
      }
    | Dialogue(_, t) =>
      switch Craft.gateDialogue(t) {
      | Ok() => ()
      | Error(vs) => vs->Belt.Array.forEach(v => Js.Array2.push(deviceViols, Craft.show(v) ++ "  @ " ++ Js.String2.slice(t, ~from=0, ~to_=60))->ignore)
      }
    }
  )
  verdict(
    "craft devices",
    Belt.Array.length(deviceViols) == 0,
    Belt.Array.length(deviceViols) == 0
      ? ""
      : Belt.Int.toString(Belt.Array.length(deviceViols)) ++ " violation(s):\n        " ++ deviceViols->Belt.Array.joinWith("\n        ", x => x),
  )

  /* echo pairs across consecutive dialogue of different speakers */
  let dlg = lns->Belt.Array.keepMap(l =>
    switch l {
    | Dialogue(w, t) => Some((w, t))
    | Action(_) => None
    }
  )
  let echoes = ref(0)
  for i in 1 to Belt.Array.length(dlg) - 1 {
    let (wa, ta) = Belt.Array.getExn(dlg, i - 1)
    let (wb, tb) = Belt.Array.getExn(dlg, i)
    if wa != wb {
      switch Craft.echoViolation(~prev=ta, ~cur=tb) {
      | Some(_) => echoes := echoes.contents + 1
      | None => ()
      }
    }
  }
  verdict("echo dialogue", echoes.contents == 0, echoes.contents == 0 ? "" : Belt.Int.toString(echoes.contents) ++ " flat echo(es)")

  /* show-don't-tell + ornament on ACTION lines only (dialogue exempt by law) */
  let told = ref(0)
  let flowery = ref(0)
  lns->Belt.Array.forEach(l =>
    switch l {
    | Action(t) => {
        told := told.contents + Belt.Array.length(Showing.tells(t))
        flowery := flowery.contents + Belt.Array.length(Concreteness.findings(t))
      }
    | Dialogue(_, _) => ()
    }
  )
  info("show-don't-tell (action lines)", Belt.Int.toString(told.contents) ++ " told-claim(s) — judge each in context (docs/05 SS8 legal list)")
  info("ornament (action lines)", Belt.Int.toString(flowery.contents) ++ " finding(s)")
}

/* ---- the substance judges (budgeted) ---- */
let judges = async (raw: string) => {
  say("- clarity (orientation — a first-time reader)")
  let (clr, clrReport) = await Clarity.gate(raw)
  verdict("clarity", clr, clrReport)

  say("- drama (the fight)")
  switch await Judge.concept(Process.Drama, raw) {
  | None => verdict("drama", true, "")
  | Some(Process.ReasonText(r)) => verdict("drama", false, r)
  }

  say("- scene craft (the two changes; core criteria)")
  let checks = await SceneCraft.audit(raw)
  let coreFails = checks->Belt.Array.keepMap(c => c.core && !c.passed ? Some(c.id ++ (c.note == "" ? "" : " (" ++ c.note ++ ")")) : None)
  let flags = checks->Belt.Array.keepMap(c => !c.core && !c.passed ? Some(c.id) : None)
  verdict("scene craft", Belt.Array.length(coreFails) == 0, Belt.Array.length(coreFails) == 0 ? "" : coreFails->Belt.Array.joinWith("; ", x => x))
  if Belt.Array.length(flags) > 0 {
    info("scene craft triage flags", flags->Belt.Array.joinWith(", ", x => x))
  }

  say("- human reaction (does it move anyone — strict)")
  switch await Judge.concept(Process.HumanReaction, raw) {
  | None => verdict("human reaction", true, "")
  | Some(Process.ReasonText(r)) => verdict("human reaction", false, r)
  }
}

/* ---- the finishing triage (budgeted; reports, never blocks) ---- */
let finishing = async (raw: string) => {
  say("- the One Law (naturalness triage — over-flags by design)")
  let vs = await Judge.language(raw)
  if Belt.Array.length(vs) == 0 {
    say("  ok    no line-level tells")
  } else {
    vs->Belt.Array.forEach(v => say("  flag  " ++ Gate.describe(v)))
    say("  note  triage, not a fix-list — the author's ear is the calibration; plain one-fact sentences satisfy it, comma-tails do not")
  }
}

let main = async () => {
  switch argv->Belt.Array.get(2) {
  | None => {
      Js.log("usage: CLAUDE_STUDIO_BUDGET=8 node src/Battery.res.mjs <scene.txt> [--finishing]")
      exit(2)
    }
  | Some(path) => {
      if !existsSync(path) {
        Js.log("no such file: " ++ path)
        exit(2)
      }
      let mode = argv->Belt.Array.some(a => a == "--finishing") ? "finishing" : "substance"
      let raw = readFileSync(path, "utf8")
      let lns = classify(raw)
      say("BATTERY (" ++ mode ++ ") on " ++ path)
      say(
        "  " ++
        Belt.Int.toString(Belt.Array.length(lns)) ++
        " lines (" ++
        Belt.Int.toString(lns->Belt.Array.keep(l =>
          switch l {
          | Dialogue(_, _) => true
          | Action(_) => false
          }
        )->Belt.Array.length) ++ " dialogue)",
      )
      say("  note  layer card is NOT checked here — read the work's LAYERS.md before any edit (docs/05 SS0)")

      let hasBudget = Js.Dict.get(env, "CLAUDE_STUDIO_BUDGET") != None
      if mode == "substance" {
        floor(lns)
        if hasBudget {
          await judges(raw)
        } else {
          say("  note  judges SKIPPED (no CLAUDE_STUDIO_BUDGET) — this was the floor only, not the battery")
          failed := true
        }
        say("")
        say(
          failed.contents
            ? "SUBSTANCE: FAIL — not ready for the author"
            : "SUBSTANCE: PASS — worth the author's read (the human is the stop)",
        )
      } else {
        if hasBudget {
          await finishing(raw)
        } else {
          say("  note  no budget — finishing triage needs the judge")
        }
        say("")
        say("FINISHING: triage complete — reports, never blocks")
      }
      writeFileSync(path ++ ".battery.txt", bufferFrom(buf->Belt.Array.joinWith("\n", x => x) ++ "\n"))
      exit(mode == "substance" && failed.contents ? 1 : 0)
    }
  }
}
main()->ignore
