exception WriteError(string)

type spoken =
  | Action(string)
  | Dialogue({who: string, radio: bool, whisper: bool, text: string})

type stage = Written | Lifted

type scene = {
  id: string,
  slug: string,
  lns: array<spoken>,
  seedHash: string,
  sceneHash: string,
  attempts: int,
  stage: stage, // Written = raw from the seed; Lifted = passed the dialogue doctrine
}

/* ---- content hash (Node crypto; an external, not an escape hatch) --------- */
type hash
@module("crypto") external createHash: string => hash = "createHash"
@send external hUpdate: (hash, string) => hash = "update"
@send external hDigest: (hash, string) => string = "digest"
let sha256 = s => createHash("sha256")->hUpdate(s)->hDigest("hex")

let unpath = t =>
  switch t {
  | Cinema_Backends.Path(s) => s
  }

let doctrinePath = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/studio/DIALOGUE_DOCTRINE.md"
let doctrine = () => Cinema_Backends.readText(Cinema_Backends.Path(doctrinePath))

/* ---- canonical forms ----------------------------------------------------- */
let canonOf = sp =>
  switch sp {
  | Action(t) => "ACTION: " ++ t
  | Dialogue({who, radio, whisper, text}) =>
    who ++ (radio ? " (RADIO)" : "") ++ (whisper ? " (WHISPER)" : "") ++ ": " ++ text
  }
let canonical = lns => Belt.Array.joinWith(lns, "\n", canonOf)

let seedCanon = (s: Seed.sceneSeed) =>
  s.id ++
  "|" ++
  s.slug ++
  "|" ++
  s.logline ++
  "|" ++
  Belt.Array.joinWith(s.cast, ";", c => c.name ++ ":" ++ c.who ++ ":" ++ c.register) ++
  "|" ++
  s.layer.peshat ++
  "|" ++
  s.layer.sod ++
  "|" ++
  Belt.Array.joinWith(s.beats, ";", b => b.who ++ ">" ++ b.want ++ ">" ++ b.wall ++ ">" ++ b.turn) ++
  "|" ++
  Belt.Array.joinWith(s.rules, ";", r => r)

/* ---- prompt assembly from the seed --------------------------------------- */
let card = (c: Seed.voiceCard) =>
  "- " ++
  c.name ++
  " — " ++
  c.who ++
  "; sounds: " ++
  c.register ++
  (switch c.lexicon {
  | Some(l) => "; SPEAKS THROUGH his own world (say the unsayable in this vocabulary, never as feeling): " ++ l
  | None => ""
  }) ++
  (c.earnsEloquence ? "; may speak in polished lines" : "; speaks plainly, never polished")

let beatLine = (i, b: Seed.beat) =>
  Belt.Int.toString(i + 1) ++
  ". " ++
  b.who ++
  " wants " ++
  b.want ++
  "; wall: " ++
  b.wall ++
  "; turns: " ++
  b.turn ++
  (switch b.subtext {
  | Some(s) =>
    "\n   UNDERNEATH — what " ++
    b.who ++ " wants here but CANNOT say; keep it OFF the page, let it drive the lines from underneath: " ++ s
  | None => ""
  })

let buildPrompt = (s: Seed.sceneSeed) => {
  let cast = Belt.Array.joinWith(s.cast, "\n", card)
  let beats = s.beats->Belt.Array.mapWithIndex((i, b) => beatLine(i, b))->Belt.Array.joinWith("\n", x => x)
  let rules = s.rules->Belt.Array.joinWith("\n", r => "- " ++ r)
  "You are writing ONE scene for a filmed table read. Output ONLY the scene.\n\n" ++
  "SCENE: " ++ s.slug ++ "\n" ++
  "WHAT IT IS: " ++ s.logline ++ "\n\n" ++
  "CAST (write each ONLY in their own voice):\n" ++ cast ++ "\n\n" ++
  "BURIED LAYER — carry it, NEVER state it on the page:\n" ++
  "  surface: " ++ s.layer.peshat ++ "\n" ++
  "  buried (no line or action may name this): " ++ s.layer.sod ++ "\n\n" ++
  "PLAY THESE BEATS IN ORDER:\n" ++ beats ++ "\n\n" ++
  "HARD RULES:\n" ++ rules ++ "\n" ++
  "- Action lines = ONLY what the camera sees or the mic hears. No interiority, no naming feelings.\n" ++
  "- A radio voice is heard, not seen — mark it (RADIO).\n" ++
  "- A line dropped low as a private aside (so others in the room won't hear) — mark it (WHISPER).\n" ++
  "- NO AI tells: no colon lists, no three-beat adjective runs, no em-dashes in action, no one-word fragments, no \"not just X, it's Y\", no \"that's not X, that's Y\".\n\n" ++
  "THE DIALOGUE BAR — every spoken line must clear this. Read it, then write TO it (subtext over text, each line a tactic, the lexicon, plain-but-true, the gap):\n" ++
  doctrine() ++ "\n\n" ++
  "OUTPUT FORMAT — one element per line, nothing else:\n" ++
  "ACTION: a filmable action line\n" ++
  "NAME: dialogue\n" ++
  "NAME (RADIO): dialogue heard over the radio\n" ++
  "NAME (WHISPER): dialogue spoken low / under the breath — a private aside to someone in the room\n" ++
  "No scene headings, no blank lines, no parentheticals except (RADIO) and (WHISPER), no commentary."
}

/* ---- parse the model's output into typed lines --------------------------- */
let dlgRe = %re("/^([A-Z][A-Z .'`-]*?)\s*((?:\((?:RADIO|WHISPER)\)\s*)*):\s*(.+)$/")
let cap = (r, i) => Js.Re.captures(r)->Belt.Array.get(i)->Belt.Option.flatMap(Js.Nullable.toOption)

let parseLine = raw => {
  let line = Js.String2.trim(raw)
  if line == "" {
    None
  } else if Js.String2.startsWith(line, "ACTION:") {
    Some(Action(Js.String2.trim(Js.String2.sliceToEnd(line, ~from=7))))
  } else {
    switch Js.Re.exec_(dlgRe, line) {
    | Some(r) => {
        let tags = cap(r, 2)->Belt.Option.getWithDefault("")
        Some(
          Dialogue({
            who: cap(r, 1)->Belt.Option.getWithDefault("")->Js.String2.trim,
            radio: Js.String2.includes(tags, "RADIO"),
            whisper: Js.String2.includes(tags, "WHISPER"),
            text: cap(r, 3)->Belt.Option.getWithDefault("")->Js.String2.trim,
          }),
        )
      }
    | None => Some(Action(line)) // stray prose is gated as action; nothing slips ungated
    }
  }
}

let parse = raw =>
  Js.String2.splitByRe(raw, %re("/\r?\n/"))->Belt.Array.keepMap(x => x)->Belt.Array.keepMap(parseLine)

/* ---- gate every line ----------------------------------------------------- */
let gateAll = lns => {
  let perLine =
    lns->Belt.Array.reduce([], (acc, sp) => {
      let (res, head) = switch sp {
      | Action(t) => (Craft.gateAction(t), "ACTION: " ++ t)
      | Dialogue({who, radio, whisper, text}) => (
          Craft.gateDialogue(text),
          who ++ (radio ? " (RADIO)" : "") ++ (whisper ? " (WHISPER)" : "") ++ ": " ++ text,
        )
      }
      switch res {
      | Ok() => acc
      | Error(vs) => Belt.Array.concat(acc, vs->Belt.Array.map(v => head ++ "  <- " ++ Craft.show(v)))
      }
    })
  /* cross-line: flat echoes between consecutive DIALOGUE lines of different speakers
     (ACTION lines between them are skipped — an echo across a beat still echoes). */
  let dlg =
    lns->Belt.Array.keepMap(sp =>
      switch sp {
      | Dialogue({who, radio, text}) => Some((who, radio, text))
      | Action(_) => None
      }
    )
  let echoes: ref<array<string>> = ref([])
  for i in 1 to Belt.Array.length(dlg) - 1 {
    let (whoA, _, textA) = Belt.Array.getExn(dlg, i - 1)
    let (whoB, radioB, textB) = Belt.Array.getExn(dlg, i)
    if whoA != whoB {
      switch Craft.echoViolation(~prev=textA, ~cur=textB) {
      | Some(v) =>
        echoes :=
          Belt.Array.concat(
            echoes.contents,
            [whoB ++ (radioB ? " (RADIO)" : "") ++ ": " ++ textB ++ "  <- " ++ Craft.show(v)],
          )
      | None => ()
      }
    }
  }
  Belt.Array.concat(perLine, echoes.contents)
}

/* ---- the writing stage: generate -> gate -> regenerate ------------------- */
let writeScene = async (~seed: Seed.sceneSeed, ~maxTries: int): scene => {
  let rec attempt = async (n, msg) => {
    let raw = await Session.ask(msg)
    let parsed = parse(raw)
    let viols = gateAll(parsed)
    if Belt.Array.length(viols) == 0 && Belt.Array.length(parsed) > 0 {
      (parsed, n)
    } else if n >= maxTries {
      raise(
        WriteError(
          "gate not satisfied after " ++
          Belt.Int.toString(n) ++
          " tries:\n" ++
          Belt.Array.joinWith(viols, "\n", x => x),
        ),
      )
    } else {
      let fix =
        "Those lines tripped the craft gate:\n" ++
        Belt.Array.joinWith(viols, "\n", x => x) ++
        "\n\nRewrite the WHOLE scene in the exact same output format, fixing those lines into plain filmable prose. Output only the scene."
      await attempt(n + 1, fix)
    }
  }
  let (lns, attempts) = await attempt(1, buildPrompt(seed))
  {
    id: seed.id,
    slug: seed.slug,
    lns,
    seedHash: sha256(seedCanon(seed)),
    sceneHash: sha256(canonical(lns)),
    attempts,
    stage: Written,
  }
}

let sentinel = "@@SCENE@@"
let bodyOf = txt =>
  switch Js.String2.indexOf(txt, sentinel) {
  | -1 => None
  | i => Some(Js.String2.trim(Js.String2.sliceToEnd(txt, ~from=i + Js.String2.length(sentinel))))
  }

/* ---- the dialogue LIFT pass: raise an emitted scene to DIALOGUE_DOCTRINE.md
   (subtext / tactic / lexicon / earned truth), leaving working lines alone, then
   re-gate on the Craft floor. Preserves id/slug/seedHash; stamps the scene Lifted,
   which is what verify/read require before anything can be produced. ------------ */
let updateText = (sp, t) =>
  switch sp {
  | Action(_) => Action(t)
  | Dialogue({who, radio, whisper}) => Dialogue({who, radio, whisper, text: t})
  }

let receiptField = (path, k) =>
  Js.Json.parseExn(Cinema_Backends.readText(Cinema_Backends.Path(unpath(path) ++ ".receipt.json")))
  ->Js.Json.decodeObject
  ->Belt.Option.flatMap(o => Js.Dict.get(o, k))
  ->Belt.Option.flatMap(Js.Json.decodeString)
  ->Belt.Option.getWithDefault("")

let numberedScene = lns =>
  lns
  ->Belt.Array.mapWithIndex((i, sp) => Belt.Int.toString(i) ++ ": " ++ canonOf(sp))
  ->Belt.Array.joinWith("\n", x => x)

let liftPrompt = (doctrine, lns, viols, notes) => {
  let must =
    Belt.Array.length(viols) == 0
      ? ""
      : "\n\nThese lines also trip the mechanical floor and MUST be fixed:\n" ++
        Belt.Array.joinWith(viols, "\n", x => x)
  let noteBlock = switch notes {
  | Some(n) if Js.String2.trim(n) != "" =>
    "\n\n=== DIRECTOR'S NOTES — every note MUST be addressed; these override 'leave it alone' ===\n" ++
    n ++ "\n=== END NOTES ===\n"
  | _ => ""
  }
  "You are lifting the DIALOGUE of a filmed table-read scene to the bar in the doctrine below.\n\n" ++
  "Raise lines toward SUBTEXT (say less than is meant), TACTIC (each line does something to the other person), the character's own LEXICON, and — only at a real turn, only if earned — a buried truth surfacing plainly. Keep the story, the events, the staging, and each character's voice. Leave a line ALONE if it already carries subtext or does something; do NOT gild working lines. NEVER add wit, a quotable button, or any decoration — plainer-but-truer beats clever, most lines stay plain, and not one line may sound like writing.\n\n" ++
  "=== DOCTRINE ===\n" ++ doctrine ++ "\n=== END DOCTRINE ===\n" ++
  noteBlock ++
  "\nReturn ONLY the lines you changed, one per line, as:\n" ++
  "<index>| <new line text, with NO name prefix>\n" ++
  "If nothing should change, return exactly: NONE\n\n" ++
  "SCENE (numbered):\n" ++ numberedScene(lns) ++ must
}

let editRe = %re("/^\s*(\d+)\s*\|\s*(.+)$/")

/* the lift returns BARE text, but models sometimes re-include the line's own
   prefix ("ACTION:" or "WHO (RADIO):") in the edit — which would double it in
   the canonical scene ("ACTION: ACTION: …"). Strip the line's OWN prefix from
   the edit text mechanically; never trust the model to omit it. */
let reEscape = s => Js.String2.replaceByRe(s, %re("/[.*+?^${}()|[\]\\]/g"), "\\$&")
let stripOwnPrefix = (orig, t) => {
  let t = Js.String2.trim(t)
  switch orig {
  | Action(_) => Js.String2.replaceByRe(t, %re("/^\s*ACTION:\s*/"), "")
  | Dialogue({who}) => {
      let re = Js.Re.fromStringWithFlags(
        "^\\s*" ++ reEscape(who) ++ "\\s*(?:\\((?:RADIO|WHISPER)\\)\\s*)*:\\s*",
        ~flags="i",
      )
      Js.String2.replaceByRe(t, re, "")
    }
  }
}

let applyEdits = (lns, raw) => {
  let arr = Belt.Array.copy(lns)
  Js.String2.splitByRe(raw, %re("/\r?\n/"))->Belt.Array.forEach(lnO =>
    switch lnO {
    | Some(ln) =>
      switch Js.Re.exec_(editRe, ln) {
      | Some(m) =>
        switch (cap(m, 1)->Belt.Option.flatMap(Belt.Int.fromString), cap(m, 2)) {
        | (Some(i), Some(t)) =>
          if i >= 0 && i < Belt.Array.length(arr) {
            let orig = Belt.Array.getExn(arr, i)
            Belt.Array.setExn(arr, i, updateText(orig, stripOwnPrefix(orig, t)))
          }
        | _ => ()
        }
      | None => ()
      }
    | None => ()
    }
  )
  arr
}

let liftDialogue = async (~path, ~notes: option<string>=?, ~maxTries: int): scene => {
  let body = switch bodyOf(Cinema_Backends.readText(path)) {
  | Some(b) => b
  | None => raise(WriteError("no scene body at " ++ unpath(path)))
  }
  let doctrine = Cinema_Backends.readText(Cinema_Backends.Path(doctrinePath))
  let rec round = async (n, lns) => {
    let raw = await Session.ask(liftPrompt(doctrine, lns, gateAll(lns), notes))
    let lns2 = Js.String2.trim(raw) == "NONE" ? lns : applyEdits(lns, raw)
    let v2 = gateAll(lns2)
    if Belt.Array.length(v2) == 0 {
      lns2
    } else if n >= maxTries {
      raise(
        WriteError(
          "lift gate not satisfied after " ++
          Belt.Int.toString(n) ++
          ":\n" ++
          Belt.Array.joinWith(v2, "\n", x => x),
        ),
      )
    } else {
      await round(n + 1, lns2)
    }
  }
  let lns = await round(1, parse(body))
  {
    id: receiptField(path, "id"),
    slug: receiptField(path, "slug"),
    lns,
    seedHash: receiptField(path, "seedHash"),
    sceneHash: sha256(canonical(lns)),
    attempts: 1,
    stage: Lifted,
  }
}

/* ---- EXTEND: insert a new beat into a finished scene WITHOUT re-rolling it.
   The lift can only edit existing lines; this generates new lines in context
   (full scene + doctrine + the beat brief), gates the SPLICED whole (per-line
   + cross-line echoes across both seams), and emits with dialogue=PENDING so
   the doctrine lift must run again before anything renders. Approved lines are
   preserved verbatim by construction. --------------------------------------- */
let extendScene = async (~path, ~afterLine: int, ~brief: string, ~maxTries: int): scene => {
  let body = switch bodyOf(Cinema_Backends.readText(path)) {
  | Some(b) => b
  | None => raise(WriteError("no scene body at " ++ unpath(path)))
  }
  let lns = parse(body)
  let n = Belt.Array.length(lns)
  if afterLine < 0 || afterLine >= n {
    raise(WriteError("afterLine out of range: " ++ Belt.Int.toString(afterLine)))
  }
  let basePrompt =
    "You are ADDING one short beat to a finished, approved table-read scene. Every existing line is LOCKED — you write ONLY the new lines.\n\n" ++
    "EXISTING SCENE (numbered, locked):\n" ++
    numberedScene(lns) ++
    "\n\nINSERT the new beat immediately AFTER line " ++
    Belt.Int.toString(afterLine) ++
    ".\n\nTHE NEW BEAT:\n" ++
    brief ++
    "\n\nOUTPUT: ONLY the new lines, in the exact scene format — one element per line:\n" ++
    "ACTION: a filmable action line\n" ++
    "NAME: dialogue\n" ++
    "NAME (RADIO): dialogue heard over the radio\n" ++
    "NAME (WHISPER): dialogue spoken low, a private aside\n" ++
    "No numbering, no blank lines, no commentary. The beat must read seamlessly against the lines around it and obey the doctrine below.\n\n" ++
    "=== DOCTRINE ===\n" ++
    doctrine() ++ "\n=== END DOCTRINE ==="
  let rec attempt = async (k, msg) => {
    let raw = await Session.ask(msg)
    let newLns = parse(raw)
    if Belt.Array.length(newLns) == 0 {
      raise(WriteError("extend returned no lines"))
    }
    let spliced = Belt.Array.concatMany([
      Belt.Array.slice(lns, ~offset=0, ~len=afterLine + 1),
      newLns,
      Belt.Array.sliceToEnd(lns, afterLine + 1),
    ])
    let viols = gateAll(spliced)
    if Belt.Array.length(viols) == 0 {
      spliced
    } else if k >= maxTries {
      raise(
        WriteError(
          "extend gate not satisfied after " ++
          Belt.Int.toString(k) ++
          ":\n" ++
          Belt.Array.joinWith(viols, "\n", x => x),
        ),
      )
    } else {
      await attempt(
        k + 1,
        "Those lines tripped the craft gate:\n" ++
        Belt.Array.joinWith(viols, "\n", x => x) ++
        "\n\nRewrite ONLY your new inserted lines (same format, same insertion point), fixing the violations. Output only the new lines.",
      )
    }
  }
  let spliced = await attempt(1, basePrompt)
  {
    id: receiptField(path, "id"),
    slug: receiptField(path, "slug"),
    lns: spliced,
    seedHash: receiptField(path, "seedHash"),
    sceneHash: sha256(canonical(spliced)),
    attempts: 1,
    stage: Written,
  }
}

let lines = sc => sc.lns

/* ---- emit + receipt ------------------------------------------------------ */
let emit = (sc, ~txt) => {
  let p = unpath(txt)
  let body = canonical(sc.lns)
  let header =
    sc.id ++
    " — " ++
    sc.slug ++
    "\n[engine-emitted; verify against " ++
    p ++
    ".receipt.json]\n\n" ++
    sentinel ++ "\n"
  Cinema_Backends.writeText(txt, header ++ body)

  let d = Js.Dict.empty()
  Js.Dict.set(d, "id", Js.Json.string(sc.id))
  Js.Dict.set(d, "slug", Js.Json.string(sc.slug))
  Js.Dict.set(d, "seedHash", Js.Json.string(sc.seedHash))
  Js.Dict.set(d, "sceneHash", Js.Json.string(sc.sceneHash))
  Js.Dict.set(d, "gate", Js.Json.string("PASS"))
  Js.Dict.set(
    d,
    "dialogue",
    Js.Json.string(
      switch sc.stage {
      | Written => "PENDING"
      | Lifted => "LIFTED"
      },
    ),
  )
  Js.Dict.set(d, "attempts", Js.Json.string(Belt.Int.toString(sc.attempts)))
  Js.Dict.set(d, "emittedBy", Js.Json.string("studio/Write.writeScene"))
  Cinema_Backends.writeText(
    Cinema_Backends.Path(p ++ ".receipt.json"),
    Js.Json.stringifyWithSpace(Js.Json.object_(d), 2),
  )
  txt
}

/* ---- verify: the wall you can check -------------------------------------- */
let verify = txt => {
  let p = unpath(txt)
  let receipt = Cinema_Backends.Path(p ++ ".receipt.json")
  if !Cinema_Backends.exists(txt) {
    Error("no scene file at " ++ p)
  } else if !Cinema_Backends.exists(receipt) {
    Error("NO RECEIPT — this scene did not come from the engine")
  } else {
    switch bodyOf(Cinema_Backends.readText(txt)) {
    | None => Error("no " ++ sentinel ++ " body in the file")
    | Some(body) =>
      let recv = Js.Json.parseExn(Cinema_Backends.readText(receipt))
      let field = k =>
        recv
        ->Js.Json.decodeObject
        ->Belt.Option.flatMap(o => Js.Dict.get(o, k))
        ->Belt.Option.flatMap(Js.Json.decodeString)
        ->Belt.Option.getWithDefault("")
      if field("sceneHash") != sha256(body) {
        Error("TAMPERED — scene text does not match its receipt hash (hand-edited)")
      } else if field("gate") != "PASS" {
        Error("receipt does not record a PASS")
      } else {
        let viols = gateAll(parse(body))
        if Belt.Array.length(viols) != 0 {
          Error("GATE WOULD FAIL on emitted text:\n" ++ Belt.Array.joinWith(viols, "\n", x => x))
        } else if field("dialogue") != "LIFTED" {
          Error(
            "DIALOGUE DOCTRINE NOT RUN — scene is not production-ready. Run the lift pass (SkyKing_Lift) before rendering.",
          )
        } else {
          Ok()
        }
      }
    }
  }
}

let read = txt =>
  switch verify(txt) {
  | Error(m) => Error(m)
  | Ok() =>
    switch bodyOf(Cinema_Backends.readText(txt)) {
    | None => Error("no scene body")
    | Some(b) => Ok(parse(b))
    }
  }
