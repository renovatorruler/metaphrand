/* PromptGate.res — the positive-description law, enforced.

   Author's hard rule (2026-08-27): a generation prompt names what IS on screen,
   never what is absent. The models in use have exactly one text channel —
   verified with `higgsfield model get` across seedance_2_0, seedance_2_0_mini,
   seedance_2_5 and nano_banana_pro: a `prompt` field and delivery knobs, with
   zero negative-prompt parameter — so a prohibition is just its noun smuggled
   into the scene behind a weak word ("no arch" still says "arch"). The session
   that produced this rule watched CAMERA draw a tripod, MARKED FLAGSTONE carve
   runes, and BELL ARCH build an arch the screenplay never had; each was fixed
   by describing what is there, and each fix held.

   Same shape as Gate.craftlint for scene prose: renderer output must pass here
   before it can reach a model. `scan` reports offending lines; `pass` is wired
   into every renderer, so text that forbids is unrenderable — a violation is a
   loud failure before any credit is spent, at latest when `lint:prompts` runs
   in the test chain. Fix a defect by changing state or description, never by
   adding a prohibition — if the gate blocks you, the answer is a better noun. */

let banned = Js.Re.fromStringWithFlags(
  "\\b(?:no|not|never|none|nothing|nobody|nowhere|neither|nor|cannot|can't|don't|doesn't|isn't|aren't|wasn't|won't|wouldn't|couldn't|shouldn't|mustn't|avoid|avoids|avoiding|without|except|forbid|forbids|forbidden|prohibited)\\b",
  ~flags="i",
)

let scan = (text: string): array<string> =>
  Js.Array2.reduce(Js.String2.split(text, "\n"), (acc, line) =>
    switch Js.String2.match_(line, banned) {
    | Some(m) =>
      switch m[0] {
      | Some(tok) => Js.Array2.concat(acc, ["[" ++ tok ++ "] " ++ Js.String2.trim(line)])
      | None => acc
      }
    | None => acc
    }
  , [])

let pass = (~which: string, text: string): string => {
  let bad = scan(text)
  if Js.Array2.length(bad) > 0 {
    Js.Exn.raiseError(
      "PromptGate: " ++
      which ++
      " forbids instead of describing — name what IS on screen:\n" ++
      Js.Array2.joinWith(bad, "\n"),
    )
  }
  text
}


/* ---- THE STRICT LAW (2026-09-04 audit) ---------------------------------------
   Eleven agents traced every inconsistent EP10 frame to prompt text a regex can
   catch: a collective noun where a name should be ("the five"), a pronoun with no
   named actor, one character's line describing another, a SCENE that leaves a
   cast member unnamed, a shape noun the model then draws (a glyph, a beam), an
   absent object named so it can be forbidden ("cold and dark"), and small-form
   and great-form asserted in the same prompt. Each check below refuses the exact
   receipt prompts that produced the bad frames — that is the fixture test.
   Opt-in per episode: an older show's prompts are not rewritten under this law. */

let strict = ref(false)
let setStrict = b => strict := b

let castTable = [
  ("KUKU", "कुकु"), ("FYURIA", "फ्यूरिया"), ("LEDA", "लेडा"), ("CASTOR", "कैस्टर"),
  ("VESPER", "वैस्पर"), ("KALU", "कालू"), ("DADI", "दादी"), ("PAPA", "पापा"),
]
let collective = %re("/\b(?:the five|all five|the four|all four|the others|the children|each child|each of them|both of them|the group|five (?:great|small) dragons|everyone|they|them|their|he|she|his|her|him)\b/i")
let shapeWords = %re("/\b(?:letter|letters|glyph|curve|curves|line|lines|stroke|column|pillar|post|pole|beam|shaft|ray|searchlight|symbol|shape)\b/i")
let namedAbsent = %re("/\b(?:cold and dark|unlit|wick dark|empty and cold|dead lamp)\b/i")
let flameWords = %re("/\b(?:flame|burning wick|small flame)\b/i")
let darkLighting = %re("/darkness|night sky|one source of light/i")
let smallForm = %re("/small everyday form/i")
/* A NOUN REPEATED IS A NOUN MATERIALISED. Naming the कड़ा once per subject and
   again in the cast clause put a bracelet on both forearms; the same class put a
   tripod in frame for "CAMERA:" and painted a whole road for one red marker.
   A distinctive worn or carried thing is named AT MOST ONCE in a prompt — and
   when a character sheet is attached, not at all: the sheet is the authority. */
let wearables = ["कड़ा", "bracelet", "halter", "spectacles", "shawl", "staff", "turra", "safa"]
let greatForm = %re("/GREAT FORM/")
let subjectLine = %re("/^- (KUKU|FYURIA|LEDA|CASTOR|VESPER|DADI|PAPA|KALU) — (.*)$/")
/* hybrid form: subject[N].name / subject[N].pose */
let fieldName = %re("/^subject\[(\d+)\]\.name: (.+)$/")
let fieldPose = %re("/^subject\[(\d+)\]\.pose: (.+)$/")
let boilerplate = %re("/^(?:SHOT:|STYLE:|SET PLATE|PAPER MATERIAL|STAGING:|CHARACTER REFERENCES|VIEWPOINT:|AUDIO:|CAMERA:|style\.|set\.|object\.|cast\.|world\.|camera\.|light\.|setting\.|render\.|subject\[\d+\]\.(?:name|species|colour|scale|wears|look|state):|prop\[)/")

let has = (re, s) => Js.Re.test_(re, s)
let hasName = ((latin, dev), s) => Js.String2.includes(s, latin) || Js.String2.includes(s, dev)

let scanStrict = (text: string): array<string> => {
  let lines = Js.String2.split(text, "\n")
  let out = ref([])
  let add = m => out := Js.Array2.concat(out.contents, [m])
  /* who is in this prompt, from its own subject lines */
  /* pair each subject[N].name with its subject[N].pose */
  let idxName = Js.Array2.reduce(lines, (acc, l) =>
    switch Js.String2.match_(l, fieldName) {
    | Some(m) =>
      switch (m[1], m[2]) {
      | (Some(i), Some(n)) => Js.Array2.concat(acc, [(i, Js.String2.trim(n))])
      | _ => acc
      }
    | None => acc
    }
  , [])
  let fieldSubjects = Js.Array2.reduce(lines, (acc, l) =>
    switch Js.String2.match_(l, fieldPose) {
    | Some(m) =>
      switch (m[1], m[2]) {
      | (Some(i), Some(pose)) =>
        switch Js.Array2.find(idxName, ((j, _)) => j == i) {
        | Some((_, n)) => Js.Array2.concat(acc, [(n, pose)])
        | None => acc
        }
      | _ => acc
      }
    | None => acc
    }
  , [])
  let subjects = Js.Array2.concat(fieldSubjects, Js.Array2.reduce(lines, (acc, l) =>
    switch Js.String2.match_(l, subjectLine) {
    | Some(m) =>
      switch (m[1], m[2]) {
      | (Some(name), Some(tail)) => Js.Array2.concat(acc, [(name, tail)])
      | _ => acc
      }
    | None => acc
    }
  , []))
  let lighting = Js.Array2.find(lines, l => Js.String2.startsWith(l, "LIGHTING:") || Js.String2.startsWith(l, "light.state:"))->Belt.Option.getWithDefault("")
  Js.Array2.forEach(lines, l => {
    let t = Js.String2.trim(l)
    if t != "" && !has(boilerplate, t) {
      if has(collective, t) {
        add("[PER_SUBJECT: collective or pronoun — name the actor] " ++ t)
      }
      if has(shapeWords, t) {
        add("[SHAPE_WORDS: a shape noun the model will draw — describe light only; the letter is a VFX layer] " ++ t)
      }
      if has(namedAbsent, t) {
        add("[STATE_PAIR: an absent object is named so it can be forbidden — leave it out] " ++ t)
      }
      if has(flameWords, t) && has(darkLighting, lighting) {
        add("[STATE_PAIR: a flame in a shot whose lighting says dark] " ++ t)
      }
    }
  })
  Js.Array2.forEach(wearables, w => {
    let n = Js.Array2.length(Js.String2.split(text, w)) - 1
    if n > 1 {
      add("[REPEATED_NOUN: " ++ w ++ " named " ++ Belt.Int.toString(n) ++ " times — a repeated noun gets drawn twice; the character sheet is the authority on what is worn]")
    }
  })
  if has(smallForm, text) && has(greatForm, text) {
    add("[CONTRADICTION_FORM: small everyday form and GREAT FORM in one prompt]")
  }
  /* each subject line is ABOUT its own subject: the pose names that character
     (Latin or Devanagari), and no other cast member is the actor of the line.
     Another member may appear as the object of the action — "लेडा leans toward
     कुकु" is lawful; "कैस्टर and फ्यूरिया filling the courtyard" under KUKU is not. */
  Js.Array2.forEach(subjects, ((name, tail)) => {
    let own = Js.Array2.find(castTable, ((latin, _)) => latin == name)
    switch own {
    | Some(a) => if !hasName(a, tail) { add("[PER_SUBJECT: " ++ name ++ "'s line never names " ++ name ++ " — the pose must say who acts] " ++ tail) }
    | None => ()
    }
    Js.Array2.forEach(castTable, ((latin, dev)) =>
      if latin != name && (Js.String2.startsWith(Js.String2.trim(tail), dev) || Js.String2.startsWith(Js.String2.trim(tail), latin)) {
        add("[PER_SUBJECT: " ++ name ++ "'s line has " ++ latin ++ " as its actor] " ++ tail)
      }
    )
  })
  let tails = Js.Array2.map(subjects, ((_, t)) => t)
  Js.Array2.forEachi(tails, (t, i) =>
    if Js.Array2.indexOf(tails, t) != i {
      add("[DUPLICATE_DOING: two subjects share one description] " ++ t)
    }
  )
  /* a SCENE with two or more cast names every one of them */
  if Js.Array2.length(subjects) >= 2 {
    switch Js.Array2.find(lines, l => Js.String2.startsWith(l, "SCENE:")) {
    | Some(scene) =>
      Js.Array2.forEach(subjects, ((name, _)) => {
        let alias = Js.Array2.find(castTable, ((latin, _)) => latin == name)
        switch alias {
        | Some(a) => if !hasName(a, scene) { add("[PER_SUBJECT: SCENE leaves " ++ name ++ " unnamed] " ++ scene) }
        | None => ()
        }
      })
    | None => ()
    }
  }
  out.contents
}

let passStrict = (~which: string, text: string): string => {
  let bad = Js.Array2.concat(scan(text), strict.contents ? scanStrict(text) : [])
  if Js.Array2.length(bad) > 0 {
    Js.Exn.raiseError("PromptGate: " ++ which ++ " refused:\n" ++ Js.Array2.joinWith(bad, "\n"))
  }
  text
}
