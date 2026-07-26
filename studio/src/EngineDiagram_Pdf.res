/* The engine-architecture diagram as a US-letter, vector, 4-page PDF -
   hand-assembled PDF 1.4 (base-14 Helvetica, no rasterizer, no deps).
   v2: the COMPLETE pass census, derived from docs/01-08 (not from memory -
   the transcript-artifact law applies to diagrams too). Every stage cites
   its doc home; passes carry their NAMES, never dead filenames.
   Run: node src/EngineDiagram_Pdf.res.mjs */

@module("fs") external writeFileSync: (string, 'a) => unit = "writeFileSync"
@val @scope("Buffer") external bufferFrom: 'a => 'b = "from"

let out = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/docs/ENGINE-ARCHITECTURE_2026-07-15_1030_v3_letter.pdf"

/* colors as "r g b" */
let ink = "0.10 0.10 0.10"
let body = "0.24 0.22 0.20"
let green = "0.04 0.49 0.20"
let amber = "0.66 0.45 0.04"
let red = "0.70 0.15 0.12"
let blue = "0.23 0.29 0.78"
let white = "1 1 1"
let dark = "0.12 0.12 0.12"
let mid = "0.33 0.31 0.29"
let cream = "0.94 0.93 0.88"
let pink = "0.99 0.95 0.94"
let gray = "0.54 0.52 0.47"

let m = 40
let w = 532

let esc = (s: string): string =>
  s
  ->Js.String2.replaceByRe(%re("/\(/g"), "\\(")
  ->Js.String2.replaceByRe(%re("/\)/g"), "\\)")

let i2s = Belt.Int.toString

type page = {ops: array<string>, mutable y: int}
let mkPage = () => {ops: [], y: 0}
let push = (p, s) => Js.Array2.push(p.ops, s)->ignore
let rectF = (p, x, y, wd, h, col) =>
  push(p, col ++ " rg " ++ i2s(x) ++ " " ++ i2s(792 - y - h) ++ " " ++ i2s(wd) ++ " " ++ i2s(h) ++ " re f")
let rectS = (p, x, y, wd, h, col) =>
  push(p, col ++ " RG 0.9 w " ++ i2s(x) ++ " " ++ i2s(792 - y - h) ++ " " ++ i2s(wd) ++ " " ++ i2s(h) ++ " re S")
let txt = (p, x, yBase, pt: float, bold, col, s) =>
  push(
    p,
    "BT /" ++
    (bold ? "F2" : "F1") ++
    " " ++
    Js.Float.toString(pt) ++
    " Tf " ++
    col ++
    " rg 1 0 0 1 " ++
    i2s(x) ++
    " " ++
    i2s(792 - yBase) ++
    " Tm (" ++
    esc(s) ++
    ") Tj ET",
  )

let header = (p, pageNo, sub) => {
  txt(p, m, 58, 15.0, true, ink, "METAPHRAND ENGINE -- the artifact chain, complete census")
  txt(p, m, 74, 8.0, false, mid, "One spine: each stage emits an artifact - a gate guards each transition - notes flow ONE stage back, never against a prior draft of itself.")
  txt(p, m, 88, 8.0, true, gray, "v3 - 2026-07-15 - page " ++ pageNo ++ " of 4 - " ++ sub)
  p.y = 104
}

let stage = (p, title, lines, chips: array<(string, string)>) => {
  let h = 24 + Belt.Array.length(lines) * 12 + Belt.Array.length(chips) * 13 + 6
  rectS(p, m, p.y, w, h, ink)
  txt(p, m + 12, p.y + 17, 10.5, true, ink, title)
  lines->Belt.Array.forEachWithIndex((k, l) => txt(p, m + 12, p.y + 31 + k * 12, 8.0, false, body, l))
  let base = p.y + 31 + Belt.Array.length(lines) * 12 + 1
  chips->Belt.Array.forEachWithIndex((k, (col, s)) => txt(p, m + 12, base + k * 13, 8.0, true, col, s))
  p.y = p.y + h + 6
}

let gate = (p, label, detail, fill) => {
  rectF(p, m, p.y, w, 20, fill)
  txt(p, m + 12, p.y + 14, 9.0, true, white, label)
  txt(p, m + 205, p.y + 14, 7.5, false, "0.85 0.83 0.78", detail)
  p.y = p.y + 20 + 6
}

/* ============ PAGE 1: idea -> world ============ */
let p1 = mkPage()
header(p1, "1", "conception: idea -> ground truth -> spine -> world")
stage(p1, "0 - IDEA", ["The premise in the author's words -- a sentence, an image, a what-if. Plot is not yet a story (docs/01 step 0)."], [])
stage(
  p1,
  "1 - GROUND TRUTH -- the constitution (docs/08 layer A + docs/05 per-work)",
  [
    "Every later note diffs against THIS. Egri premise (X leads to Y) - central dramatic argument + the antithesis's",
    "BEST case - designing principle - the lighthouse scene (the DNA, written first, in prose) - authorial stake -",
    "contested object + WHY both cannot have it - the opponent's plan (succeeds absent the hero) - THE PROMISE (the",
    "opening's contract) - THE CLOCK (a named doom, visible early) - ARENA RULES (how the world works, in the bible).",
  ],
  [
    (green, "TYPED, LIVE: DramaCards.groundTruth + DramaGate.checkTruth"),
    (mid, "LAW: promise / clock / arena live in the story bible (docs/05 per-work 1, 2, 8)"),
  ],
)
gate(p1, "GATE A - checkTruth", "premise grammar - antithesis real - mutual exclusion WRITTEN - plan >= 3 steps", dark)
stage(
  p1,
  "2 - SPINE -- structure as causality + telemetry (docs/01 + 02 + 08 layers B/C)",
  [
    "The transformation (mirror at the hinge) - two worlds - logline as loop + exception - TWO DOORWAYS of no return -",
    "beats on BUT|THEREFORE edges (and-then has no constructor) - per-beat corkboard: POV want + obstacle - fortune",
    "-5..+5, stakes 1..10 never retreating - climax roll-call - THE WEAVE LAW (every principal >= 2 plot-causal edges;",
    "every cost arrives along a built edge) - A/B braid - kishotenketsu available - point of attack (cold-open frame).",
  ],
  [
    (green, "TYPED, LIVE: DramaCards.spine + DramaGate.checkSpine (proven: the safe FOUR OLDS spine fails 10 ways, v2 passes)"),
    (mid, "LAW: weave / braid / arrangement legality (docs/01 step 7, 02 SS1+4, 05 per-work 4-6)"),
  ],
)
gate(p1, "GATE B - checkSpine", "curve alive (<= -3, lands late) - stakes never retreat - no luck rescue - antagonist at climax", dark)
stage(
  p1,
  "3 - WORLD & CAST -- a populated world, not a corridor (docs/02 SS3 + 04 + 05)",
  [
    "THE FULLNESS GATE (where are the women? who has a life off the spine?) - orchestration on opposed poles - the",
    "character web (each a different answer to the argument) - NATAL CHART -> VOICE CARD per name (the chart GENERATES",
    "the voice, docs/04) - ICEBERG BACKSTORIES (inform behavior, never stated) - off-model casting + the likeness vet -",
    "voice donors - LIKABILITY design - each principal crazy in a different key.",
  ],
  [
    (green, "TYPED, LIVE: Preflight.res - the hard-stop (dated variants resolve; per-character coverage; on day one it caught 3 real FOUR OLDS gaps)"),
    (green, "TYPED, LIVE: BlindAttribution.res - cover-the-names judge via the warm Session (>= 70%, no pair blurred > 3x)"),
  ],
)
gate(p1, "GATE C - preflight + blind attribution", "Preflight.require_ blocks drafting - the fullness read stays LAW", dark)
txt(p1, m, 760, 7.5, false, gray, "Notes and repairs route UPSTREAM -- Wilder: a third-act problem is a first-act problem.")

/* ============ PAGE 2: cards -> render -> substance ============ */
let p2 = mkPage()
header(p2, "2", "scene cards -> clean-room render -> substance")
stage(
  p2,
  "4 - SCENE MAP + CARDS -- every scene asks permission to exist (docs/08 layer D + 05 SS0)",
  [
    "The four-masters card: want / wall / cost / clock - truthIn != truthOut - a named value's charge flips - audience",
    "ledger (each danger tagged suspense or twist) - the forward question - LAYER CARDS FIRST (pure PaRDeS contracts:",
    "Peshat shows AND withholds, Remez felt-not-stated, Derash aimed, Sod off-page; read the card before ANY edit) -",
    "THE INTRIGUE BUILDER (hint early, reveal later; one looks-unrelated chain live; reveals chain to the end reveal).",
  ],
  [
    (green, "TYPED, LIVE: DramaCards.sceneCard + checkCard; IntrigueCards.res"),
    (mid, "LAW: LAYERS.md per work (docs/05 SS0) - held-card reveal schedule (series design before episodes)"),
  ],
)
gate(p2, "GATE D - checkCard", "thin litmus blocks - no flip = nonevent - empty audience ledger blocks", dark)
stage(
  p2,
  "5 - CLEAN-ROOM RENDER -- the amnesiac writer (transcript-artifact law)",
  [
    "Fresh context = ground truth + cards + voice cards + the constitution. Never the conversation, never a prior draft",
    "(an undo arrives as absence + positive restatement). ENTROPY AT THE SEED: perturb one recipe variable off-mode,",
    "execute normal; the model names its own cliche, then swerves off-center (the off-model register). CIVILIAN",
    "LANGUAGE at write time (jargon only via plain-swap / context-carry / establish-first / react-translation).",
  ],
  [
    (green, "TYPED, LIVE: Seed -> Write.writeScene -> emit + receipt -> verify (proof-of-generation)"),
    (green, "TYPED, LIVE: Entropy.res (names each slot's cliche + off-modal alternatives; budget-capped)"),
  ],
)
gate(p2, "GATE E - words-are-law receipt", "the deliverable comes only from the pipeline", dark)
stage(
  p2,
  "6 - SUBSTANCE BATTERY -> THE AUTHOR -- is this the right scene? (docs/05 sweeps 1-9 + 07)",
  [
    "DRAMA (Mamet: want / wall / cost / clock; exposition as ammunition; two-discussing-an-absent-third = crock) - the",
    "TWO CHANGES (Mercurio: plot change + character change, set-up reversal, escalating beats, docs/07) - HEART LEDGER",
    "(deposits banked early, in passing; thaws SPEND deposits, never arguments; kindness must be PRICED, the bill on",
    "page) - ANTI-SHRINKWRAP / density (the world lives its own business beside the spine; no synopsis wearing dialogue;",
    "the Grace rule: no flat bigots) - PaRDeS sermon discipline (Sod stays OFF the page) - VOICE (blind attribution;",
    "dialogue realism: messy, halting, inarticulate about pain) - MOMENTUM + modulation (never close a loop without",
    "opening a bigger one; valleys after peaks) - BACKSTORY-LEAK (lenses leak, facts don't) - likability - civilian pass.",
  ],
  [
    (green, "TYPED, LIVE: Heart.res (the ledger: unbanked wounds/thaws are violations) - Density.res (anti-shrinkwrap)"),
    (green, "TYPED, LIVE: SceneCraft.res (the Mercurio rubric via Session) - the Drama judge in Judge.res"),
    (amber, "SKILL: drama-enhancer + the one stateful editor (memory for critics)"),
    (blue, "HUMAN CHECKPOINT -- the author approves substance; structure locks here"),
  ],
)
txt(p2, m, 760, 7.5, false, gray, "Substance before finishing: never polish a draft that may still be rewritten (docs/05, the two batteries).")

/* ============ PAGE 3: finishing -> production ============ */
let p3 = mkPage()
header(p3, "3", "finishing (fenced) -> performance & production")
stage(
  p3,
  "7 - FINISHING BATTERY -- fenced: line law only, structure is locked (docs/05 SS10-11 + 06)",
  [
    "HUMANIZER + THE MASTER BANS: the completion-sentence (no unit whose sole job is completing the previous one),",
    "withhold-then-append + its comma variant, corrective definition, rule-of-three as rhythm, costume metaphor,",
    "em-dash chains, poignancy-reach (scenes end FLAT) - CLEAR-PANE (intrigue lives in events / meaning / intent,",
    "never in sentence construction; six families, thirty-one devices; a sentence that dies when flattened = EVENT-GAP,",
    "fix the scene) - THE ONE LAW (craftlint floor + the naturalness ceiling: 'arranged for effect', judged line by",
    "line) - idiom / calque (native idiom, never English calqued in) - ECHO-dialogue + APPENDED-FACT dialogue tells -",
    "show-don't-tell assembly sweep (interiority tags judged in context) - NAMED TELLS on prose deliverables (16 tells",
    "+ the Meeting Leak) - trim (enter late, leave early) - fountain hygiene (one line per paragraph).",
  ],
  [
    (green, "TYPED, LIVE: Gate.res (craftlint - violation kinds in the type system; Pipeline.ship accepts only proven-clean)"),
    (green, "TYPED, LIVE: Judge.res (naturalness) - Showing.res + Concreteness.res (show-don't-tell + ornament) - TellsGate.res"),
    (amber, "SKILL: humanizer - clear-pane (invoke the SKILL, never a from-memory approximation)"),
  ],
)
stage(
  p3,
  "8 - PERFORMANCE & PRODUCTION -- no raw text reaches an API (studio doctrine docs)",
  [
    "THE PERFORMANCE LAW: Perf.load is the ONLY door (re-runs words-are-law + total coverage incl. embedded PA/TV",
    "cues); the tagged performance JSON is the maintained artifact; no dialogue renders without expression tags -",
    "cached TTS per voice + line - DME STEM MIX (dialogue leveled + futzed per space, atmos beds crossfaded, spot fx",
    "synced, music ducked under dialogue) -> -16 LUFS master - FRAMELOOK (Portra realism; establishing + second-angle",
    "shot grammar) - the cold-open -> title transition spec - RENDER EFFICIENCY (finish lives in post; cache everything",
    "paid; never re-render an episode per note) - receipts throughout - audio ships as MP3, named + dated + versioned.",
  ],
  [
    (green, "TYPED, LIVE: Perf.res (sealed opaque type) - Mix3.res - the cast maps"),
    (mid, "LAW: AUDIO_MIX.md - FRAMELOOK.md - TRANSITIONS.md - SEEDANCE template - the render-efficiency mandate"),
  ],
)
txt(p3, m, 760, 7.5, false, gray, "Conception, middle, and production all carry typed bailiffs now; the remaining debt is WIRING - a gate exists only where it is invoked.")

/* ============ PAGE 4: laws + audit + legend ============ */
let p4 = mkPage()
header(p4, "4", "cross-cutting laws + the honest audit")

let laws = [
  ("Transcript != artifact.", "Generation contexts never contain the conversation. (This diagram's v1 broke this law - drawn from the chat, it missed passes.)"),
  ("Notes hit the anterior artifact only.", "Scenes vs. cards, cards vs. spine, spine vs. ground truth -- never a draft vs. its own previous draft."),
  ("Stage rubrics.", "Each gate judges its own altitude -- no line critics on outlines, no structure notes at the polish stage."),
  ("Memory for critics, amnesia for writers.", "The editor keeps history (fresh critics rotate notes); the writer sees only the spec."),
  ("Entropy at the seed.", "Perturb one recipe variable off-mode, then execute normal -- signature is seed-time; no pass adds it later."),
  ("Guardrails outside the agent.", "Remove the capability, don't instruct around it (the budget proxy, the sealed Perf type, the clean room)."),
  ("The human is the stop.", "Checkpoints gate forward motion; nothing auto-ships. Script first; render only after approval."),
]
let lawsH = 30 + Belt.Array.length(laws) * 27 + 6
rectF(p4, m, p4.y, w, lawsH, cream)
rectS(p4, m, p4.y, w, lawsH, ink)
txt(p4, m + 12, p4.y + 19, 11.0, true, ink, "CROSS-CUTTING LAWS (every stage)")
laws->Belt.Array.forEachWithIndex((k, (name, det)) => {
  txt(p4, m + 12, p4.y + 38 + k * 27, 9.0, true, ink, name)
  txt(p4, m + 12, p4.y + 49 + k * 27, 7.5, false, body, det)
})
p4.y = p4.y + lawsH + 10

let findings = [
  ("The chain IS one spine, not a patchwork.", "The scene invariant appears three times ON PURPOSE -- permission (Gate D), judgment (stage 6), advisory (the skill): one law, three doors. Every pass above traces to a doc (cited per stage); nothing here is invented."),
  ("DEBT 1 -- REPAID 2026-07-15 (with one residue: wiring).", "The seven owed enforcers were recovered from git history, ported to typed ReScript, smoke-proven, and the recovered Python deleted: Preflight.res, Heart.res, Density.res, SceneCraft.res, BlindAttribution.res, Showing.res, Concreteness.res (craftlint/naturalness already lived as Gate.res/Judge.res). Docs 05/06/07 + WRITING_ISSUES now cite the .res runners; no dead filenames remain. Preflight's first run caught 3 real FOUR OLDS gaps (no BACKSTORY.md, no CHARTS.md, no voice card for brandt). RESIDUE: (a) wiring - a gate exists only where it is INVOKED; entry points must call Preflight.require_ and the battery judges; (b) doorways/weave/canon runners still doc-law only, covered at conception by DramaGate."),
  ("DEBT 2 -- edge honesty is unverified.", "BUT|THEREFORE forces the causal claim to exist; nothing checks it is true (an and-then can hide behind a Therefore). Needs the blind read-back: summarize each beat, re-derive the labels cold."),
  ("DEBT 3 -- no regression memory.", "Draft-over-draft diffs (stakes-shrink, curve-flattening) need stored curves per draft; today only the current spine is judged."),
  ("DEBT 4 -- the table read is missing.", "The strongest civilian gate the industry has; we own the TTS plumbing (stage 8) and don't yet point it at drafts (stage 6)."),
]
let wrap = (s: string): array<string> => {
  let words = Js.String2.split(s, " ")
  let lines = []
  let cur = ref("")
  words->Belt.Array.forEach(word => {
    let cand = cur.contents == "" ? word : cur.contents ++ " " ++ word
    if Js.String2.length(cand) > 118 {
      Js.Array2.push(lines, cur.contents)->ignore
      cur := word
    } else {
      cur := cand
    }
  })
  if cur.contents != "" {
    Js.Array2.push(lines, cur.contents)->ignore
  }
  lines
}
let findingLines = findings->Belt.Array.map(((h, b)) => (h, wrap(b)))
let findH =
  30 +
  findingLines->Belt.Array.reduce(0, (acc, (_, ls)) => acc + 13 + Belt.Array.length(ls) * 10 + 6) + 4
rectF(p4, m, p4.y, w, findH, pink)
rectS(p4, m, p4.y, w, findH, red)
txt(p4, m + 12, p4.y + 19, 11.0, true, red, "THE HONEST AUDIT")
let fy = ref(p4.y + 38)
findingLines->Belt.Array.forEach(((h, ls)) => {
  txt(p4, m + 12, fy.contents, 9.0, true, red, h)
  ls->Belt.Array.forEachWithIndex((k, l) => txt(p4, m + 12, fy.contents + 11 + k * 10, 7.5, false, body, l))
  fy := fy.contents + 13 + Belt.Array.length(ls) * 10 + 6
})
p4.y = p4.y + findH + 10

rectS(p4, m, p4.y, w, 44, ink)
txt(p4, m + 12, p4.y + 17, 9.0, true, ink, "LEGEND")
txt(p4, m + 70, p4.y + 17, 8.0, true, green, "TYPED = ReScript gate, blocks (live)")
txt(p4, m + 250, p4.y + 17, 8.0, true, amber, "SKILL = LLM pass, advisory")
txt(p4, m + 400, p4.y + 17, 8.0, true, blue, "HUMAN = checkpoint")
txt(p4, m + 70, p4.y + 33, 8.0, true, mid, "LAW = doctrine, judged in the read")
txt(p4, m + 250, p4.y + 33, 8.0, true, red, "NO RUNNER = enforcement owed since the Python purge")
p4.y = p4.y + 44 + 12
txt(p4, m, p4.y + 8, 7.5, false, gray, "Derived from: docs/01-STORY_FRAMEWORK - 02-STORY_SPEC - 03-VOICE_GUIDE - 04-VOICE_FROM_CHART - 05-PASSES (the manifest) -")
txt(p4, m, p4.y + 19, 7.5, false, gray, "06-THE-ONE-LAW - 07-SCENE-CRAFT - 08-DRAMA_GATES - studio/src gates - studio doctrine docs (AUDIO_MIX, PERFORMANCE, INTRIGUE, ...).")

/* ============ assemble ============ */
let pageStream = (p: page): string => p.ops->Belt.Array.joinWith("\n", x => x)

let main = () => {
  let streams = [pageStream(p1), pageStream(p2), pageStream(p3), pageStream(p4)]
  let n = Belt.Array.length(streams)
  let kids = Belt.Array.makeBy(n, k => i2s(3 + k) ++ " 0 R")->Belt.Array.joinWith(" ", x => x)
  let fontA = 3 + 2 * n /* first object id after pages+streams */
  let objs = [
    "1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n",
    "2 0 obj\n<< /Type /Pages /Kids [" ++ kids ++ "] /Count " ++ i2s(n) ++ " >>\nendobj\n",
  ]
  for k in 0 to n - 1 {
    Js.Array2.push(
      objs,
      i2s(3 + k) ++
      " 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 " ++
      i2s(fontA) ++ " 0 R /F2 " ++ i2s(fontA + 1) ++ " 0 R >> >> /Contents " ++
      i2s(3 + n + k) ++ " 0 R >>\nendobj\n",
    )->ignore
  }
  streams->Belt.Array.forEachWithIndex((k, s) =>
    Js.Array2.push(
      objs,
      i2s(3 + n + k) ++ " 0 obj\n<< /Length " ++ i2s(Js.String2.length(s)) ++ " >>\nstream\n" ++ s ++ "\nendstream\nendobj\n",
    )->ignore
  )
  Js.Array2.push(objs, i2s(fontA) ++ " 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>\nendobj\n")->ignore
  Js.Array2.push(objs, i2s(fontA + 1) ++ " 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>\nendobj\n")->ignore

  let head = "%PDF-1.4\n"
  let offsets = []
  let pos = ref(Js.String2.length(head))
  objs->Belt.Array.forEach(o => {
    Js.Array2.push(offsets, pos.contents)->ignore
    pos := pos.contents + Js.String2.length(o)
  })
  let pad10 = nn => {
    let s = i2s(nn)
    Js.String2.repeat("0", 10 - Js.String2.length(s)) ++ s
  }
  let xref =
    "xref\n0 " ++
    i2s(Belt.Array.length(objs) + 1) ++
    "\n0000000000 65535 f \n" ++
    offsets->Belt.Array.joinWith("", o => pad10(o) ++ " 00000 n \n")
  let trailer =
    "trailer\n<< /Size " ++
    i2s(Belt.Array.length(objs) + 1) ++
    " /Root 1 0 R >>\nstartxref\n" ++
    i2s(pos.contents) ++
    "\n%%EOF"
  let pdf = head ++ objs->Belt.Array.joinWith("", x => x) ++ xref ++ trailer
  writeFileSync(out, bufferFrom(pdf))
  Js.log("PDF -> " ++ out)
}
main()
