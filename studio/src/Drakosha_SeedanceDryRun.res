/* Dry run: assemble all ten jobs exactly as they would be submitted — emit
   prompts + reference bindings, verify every file exists, write the artifacts
   for human review, and print the audit table. Spends nothing.

   The emitted/ directory is REVIEW MATERIAL, not the submission artifact: the
   gate accepts shot records and re-runs this same emitter inside the wall, so
   editing an emitted prompt by hand changes nothing downstream. */

@module("fs") external readFileSync: (string, string) => string = "readFileSync"
@module("fs") external writeFileSync: (string, string) => unit = "writeFileSync"
@module("fs") external existsSync: string => bool = "existsSync"
type mkdirOpts = {recursive: bool}
@module("fs") external mkdirSync: (string, mkdirOpts) => unit = "mkdirSync"
type hash
@module("crypto") external createHash: string => hash = "createHash"
@send external update: (hash, string) => hash = "update"
@send external digest: (hash, string) => string = "digest"

open Drakosha_SeedanceBatch

let refsDir = "../stories/drakosha/ep1prod/scene1/references"
let kfDir = "../stories/drakosha/rnd/keyframes"
let outDir = "../stories/drakosha/production/seedance_batch/emitted"

let sha256 = (s: string): string => createHash("sha256")->update(s)->digest("hex")

/* The author's own shot plates, drawn by her and approved by definition. Scene 4b
   was shot entirely from f18_angles and NOT from either room plate; scene 5 has
   its own master. Do not stage either against @ROOM_FRONT or @ROOM_BACK —
   production record §14 records that the hall's zoning does not reconcile, and
   they read as different rooms. Path is relative to the frames directory, e.g.
   "FRAME:scene5/2026-08-17_SCENE5_MASTER_dinner-table_author.png". */
let framesDir = "../stories/drakosha/production/kuku_flow/frames"

let resolveRef = (p: string): string =>
  if Js.String2.startsWith(p, "KF:") {
    kfDir ++ "/" ++ Js.String2.sliceToEnd(p, ~from=3)
  } else if Js.String2.startsWith(p, "FRAME:") {
    framesDir ++ "/" ++ Js.String2.sliceToEnd(p, ~from=6)
  } else {
    refsDir ++ "/" ++ p
  }

/* THE PROMPT MUST CARRY THE SCRIPT'S OWN LINES.

   The scene-5 job that came back in English was written from a conversation
   about staging — shots referred to by label ("Мама's objection") — and the
   words were never fetched from the script. Every dialogue assertion passed
   because there was no dialogue to check.

   The job record already declares which shots it covers ("SH042-043"), and the
   shooting script already holds the dialogue for every SH number. So the gate
   can look the lines up and require them, and require that nothing is spoken
   that the script does not contain. A prompt built from notes fails here. */

let shootingScript = "../stories/drakosha/2026-08-04_EP1_den-rozhdeniya_SHOOTING_numbered_bilingual.md"

let pad3 = (n: int): string => {
  let x = Belt.Int.toString(n)
  switch Js.String2.length(x) {
  | 1 => "00" ++ x
  | 2 => "0" ++ x
  | _ => x
  }
}

let shRange = (shots: string): array<string> => {
  let nums =
    shots
    ->Js.String2.replaceByRe(%re("/[^0-9\-]/g"), " ")
    ->Js.String2.trim
    ->Js.String2.split("-")
    ->Belt.Array.keepMap(x => Belt.Int.fromString(Js.String2.trim(x)))
  switch nums {
  | [a] => ["SH" ++ pad3(a)]
  | [a, b] =>
    Belt.Array.range(a, b)->Belt.Array.map(n =>
      "SH" ++ pad3(n)
    )
  | _ => []
  }
}

/* dialogue text for one SH block, if the script gives it any */
let linesForShot = (script: string, sh: string): array<string> => {
  let parts = Js.String2.split(script, "### " ++ sh)
  switch Belt.Array.get(parts, 1) {
  | None => []
  | Some(rest) =>
    let body = Belt.Array.getExn(Js.String2.split(rest, "### "), 0)
    body
    ->Js.String2.split("\n")
    ->Belt.Array.keepMap(l => {
      let t = Js.String2.trim(l)
      let speakers = ["ФРОСЯ", "ВАСЯ", "МАМА", "ПАПА", "БАБУШКА-ЯГА"]
      let isSpeech =
        Js.String2.startsWith(t, "**") &&
        Js.String2.includes(t, ":**") &&
        speakers->Belt.Array.some(sp => Js.String2.includes(t, "**" ++ sp))
      if isSpeech {
        switch Js.String2.split(t, ":**") {
        | [_, tail] =>
          let cleaned =
            tail->Js.String2.replaceByRe(%re("/\*\([^)]*\)\*/g"), "")->Js.String2.trim
          Js.String2.length(cleaned) > 3 ? Some(cleaned) : None
        | _ => None
        }
      } else {
        None
      }
    })
  }
}

/* compare on Cyrillic letters only — stress marks, punctuation and the
   pronunciation respellings must not make a present line look absent */
let bare = (s: string): string =>
  s->Js.String2.replaceByRe(%re("/[^А-яЁё]/g"), "")->Js.String2.toLowerCase

let assertScriptLinesPresent = (record, script: string, problem): unit => {
  let expected =
    shRange(record.shots)->Belt.Array.map(sh => linesForShot(script, sh))->Belt.Array.concatMany
  let creativeBare = bare(record.creative)
  expected->Belt.Array.forEach(line => {
    let b = bare(line)
    /* first 24 Cyrillic letters is enough to identify a line without demanding
       that a lightly reworded version match character for character */
    let probe = Js.String2.length(b) > 24 ? Js.String2.slice(b, ~from=0, ~to_=24) : b
    if Js.String2.length(probe) > 8 && !Js.String2.includes(creativeBare, probe) {
      problem(
        record.jobId,
        "the script gives this shot the line \"" ++
        Js.String2.slice(line, ~from=0, ~to_=60) ++
        "…\" and the choreography does not contain it. Prompts are assembled from the script, never from notes.",
      )
    }
  })
}

/* s5job1 shipped with a choreography that opened "the sequence begins on the
   supplied start image … that image is the truth for the set" while the emitted
   args carried "startImage": "". The prompt asserted an anchor the job never
   received, so the model invented the room. */
let assertStartFrameBacked = (record, problem): unit => {
  let c = Js.String2.toLowerCase(record.creative)
  let claims =
    Js.String2.includes(c, "start image") ||
    Js.String2.includes(c, "start frame") ||
    Js.String2.includes(c, "supplied start")
  switch (claims, record.startImage) {
  | (true, None) =>
    problem(
      record.jobId,
      "the choreography tells the model it begins on a supplied start image, and no startImage is bound. Either bind one or stop promising it.",
    )
  | _ => ()
  }
}

/* the same job described the whole set — boulder-block walls, stove, armchairs,
   bench, rug, bulbs — in the LOCATION MAP prose and bound seven references, all
   of them character sheets. Prose is not a plate. */
let assertSetImageBacked = (record, refPaths: array<string>, problem): unit => {
  let describesSet = Js.String2.includes(record.creative, "LOCATION MAP")
  let hasSetPlate =
    refPaths->Belt.Array.some(p => Js.String2.includes(p, "SET-")) || record.startImage != None
  if describesSet && !hasSetPlate {
    problem(
      record.jobId,
      "the choreography describes the set in LOCATION MAP prose but binds no set plate and no start image. The room must be carried by a picture, not by words.",
    )
  }
}

/* A START FRAME CAN ONLY CHAIN WITHIN ONE LOCATION.
   I claimed s5job3's closing wide would be the start frame for the chest scene.
   It cannot: the script's own headings say СЦЕНА 6 is ДОМ ЗА ПЛИТОЙ — СЛЕДОМ
   with the children standing on the floor, and СЦЕНА 7 is У СКРЫТОЙ НИШИ at the
   rear wall. Neither happens at the table. The claim was never checked against
   the script — it was just asserted, which is the same failure as every other
   one tonight, one step further downstream.

   So the script's scene headings become DATA. A job's shots resolve to a scene
   heading; a start frame lifted from another job carries that job's id in its
   filename ("…_from-s5job2-mama.png"); and if the two jobs sit under different
   headings the chain is refused. Whether two shots are in the same place stops
   being something anybody remembers. */
let sceneHeadingFor = (script: string, sh: string): option<string> => {
  switch Js.String2.split(script, "### " ++ sh)->Belt.Array.get(0) {
  | None => None
  | Some(before) =>
    let heads = Js.String2.split(before, "\n## СЦЕНА ")
    switch Belt.Array.get(heads, Belt.Array.length(heads) - 1) {
    | None => None
    | Some(tail) =>
      Belt.Array.get(Js.String2.split(tail, "\n"), 0)->Belt.Option.map(Js.String2.trim)
    }
  }
}

let assertStartFrameSameLocation = (record, script: string, allJobs, problem): unit =>
  switch record.startImage {
  | None => ()
  | Some(k) =>
    /* only frames lifted from another job carry "from-<jobid>" */
    switch Js.String2.split(k, "from-")->Belt.Array.get(1) {
    | None => ()
    | Some(tail) =>
      let srcId = Belt.Array.getExn(Js.String2.split(tail, "-"), 0)
      switch allJobs->Belt.Array.getBy(r => r.jobId == srcId) {
      | None => ()
      | Some(src) =>
        let mine =
          shRange(record.shots)->Belt.Array.get(0)->Belt.Option.flatMap(sceneHeadingFor(script, _))
        let theirs =
          shRange(src.shots)->Belt.Array.get(0)->Belt.Option.flatMap(sceneHeadingFor(script, _))
        switch (mine, theirs) {
        | (Some(a), Some(b)) if a != b =>
          problem(
            record.jobId,
            "its start frame is lifted from " ++
            srcId ++
            ", but the script puts them in different places — this job is \"СЦЕНА " ++
            a ++
            "\" and that one is \"СЦЕНА " ++
            b ++
            "\". A start frame only chains within one location.",
          )
        | _ => ()
        }
      }
    }
  }

/* A REFERENCE SHEET FIXES IDENTITY, NOT EXPRESSION.
   Every character plate carries one face — Фрося's wide gap-toothed grin,
   Бабушка-Яга's warm sly look — and the model treats it as a mask unless the
   choreography says otherwise. In s5job2 Фрося holds the same grin straight
   through Вася's line, which is not how anyone listens to anything.

   The earlier fix for the dead room ("everybody is doing one specific thing")
   covered hands and props and never mentioned faces, so the room got busy while
   the performances stayed frozen. Whenever two or more characters share a frame,
   the one who is NOT speaking has to play the moment: what they think of what
   they are hearing must be on them.

   Mechanically checkable: a multi-character job must contain a REACTIONS block.
   That does not prove the reactions are good, but it makes their absence
   impossible to ship by accident, which is how this one shipped. */
/* A REACTION IS A SHAPE THAT MOVES, NOT A SECOND MASK.
   It is not enough to write "Фрося looks surprised" — held for four seconds that
   is just a different frozen face. A real reaction travels: it starts one way
   and ends another, and the words have to say so. These are the markers that say
   a face changed rather than merely was. */
let changeMarkers = [
  "widen",
  "opens",
  "drops",
  "falls",
  "tightens",
  "goes from",
  "changes",
  "shifts",
  "by the end",
  "at first",
  "starts",
  "then ",
  "no longer",
  "fades",
  "gives way",
  "turns to",
  "stops",
]

let reactionHeaders = ["REACTIONS", "REACTION"]

let assertReactionsWritten = (record, problem): unit =>
  if Belt.Array.length(record.cast) > 1 {
    let c = record.creative
    switch reactionHeaders->Belt.Array.getBy(h => Js.String2.includes(c, h)) {
    | None =>
      problem(
        record.jobId,
        "more than one character is in this job and the choreography never says what the NON-SPEAKING ones do with their faces. A reference sheet fixes identity, not expression — without it the model holds the sheet's expression like a mask for the whole shot. Add a REACTIONS block.",
      )
    | Some(h) =>
      /* the block runs from its header to the next ALL-CAPS heading */
      let after = Belt.Array.getExn(Js.String2.split(c, h), 1)
      let block =
        Belt.Array.getExn(Js.String2.splitByRe(after, %re("/\n[A-ZА-Я][A-ZА-Я ,\-]{4,}\n/")), 0)
        ->Belt.Option.getWithDefault(after)
      /* everybody in the cast who has a name must be written about somewhere in
         it — otherwise the one person nobody thought about is the one holding
         the mask, which is exactly what happened to Фрося. */
      let missing =
        record.cast
        ->Belt.Array.keep(t =>
          switch castRuName(t) {
          | None => false
          | Some(n) =>
            !Js.String2.includes(block, n) &&
            !Js.String2.includes(block, castEntry(t).tag)
          }
        )
        ->Belt.Array.keepMap(castRuName)
      if Belt.Array.length(missing) > 0 {
        problem(
          record.jobId,
          "the REACTIONS block never mentions " ++
          Js.Array2.joinWith(missing, ", ") ++
          ". Every character who is in frame while somebody else speaks needs their face written, or they hold their reference sheet's expression throughout.",
        )
      }
      /* A MOOD IS NOT A DIRECTION. Мама's block said "starts flat and unimpressed,
         and by the end that goes to something firmer" — every word of it about
         how she FEELS — and she smiled warmly through the entire take, because
         her reference sheet smiles and an adjective does not outrank a picture.
         The same failure as the broom, in a different cell: what beats a sheet is
         an instruction about the same thing the sheet is showing. So a reactions
         block has to say what the FACE PARTS do, and there must be at least one
         piece of anatomy per character in the job. */
      let facialParts = [
        "mouth", "brow", "eyes", "eyelid", "jaw", "chin", "lips", "teeth",
        "forehead", "nostril", "cheek", "blink",
      ]
      let parts = facialParts->Belt.Array.keep(w => Js.String2.includes(Js.String2.toLowerCase(block), w))
      if Belt.Array.length(parts) < Belt.Array.length(record.cast) {
        problem(
          record.jobId,
          "the REACTIONS block names moods rather than describing faces. \"Flat and unimpressed\" lost to a reference sheet that smiles; \"her mouth stays a level line and never turns up at the corners\" wins. Say what the mouth, brows, eyes and jaw actually do — at least one piece of anatomy per character.",
        )
      }
      let changes = changeMarkers->Belt.Array.keep(m => Js.String2.includes(block, m))
      if Belt.Array.length(changes) < 2 {
        problem(
          record.jobId,
          "the REACTIONS block describes states, not changes. A held expression is just a second mask — Фрося wore one grin through Вася's whole line in s5job2. Say what each face STARTS as and what it BECOMES (widens, drops, gives way to, by the end…).",
        )
      }
    }
  }

/* THE EMOTION GATE — every face must be named, and the choreography must agree
   with the name. Author's rule, 2026-08-26: "every character description
   requires one to two words for actual emotion, and choreography of the face
   after that has to match that emotion."

   WHY IT EXISTS. v07table came back with three adults wearing the same worried
   face, and Мама — who was supposed to be quietly unsettled at seeing her own
   face — reading as an outright scowl. Nothing in her paragraph was wrong
   sentence by sentence. What went wrong is that it stacked "her brows draw in a
   fraction and stay drawn", "the eyes narrow a little" and "her jaw sets", each
   defensible alone and all three together an angry face. There was no line in
   the creative saying what she was actually FEELING, so there was nothing for
   the anatomy to be checked against — not by the model, and not by me.

   Naming the emotion turns an unfalsifiable paragraph into a checkable one. It
   also front-loads the intention for the model, which the doctrine allows so
   long as the anatomy still does the binding: a mood alone loses to a reference
   sheet, but a mood plus the anatomy that produces it is strictly more than the
   anatomy alone.

   THE SYNTAX, because a gate can only check what it can find:

     REACTIONS
     Папа — SHOCK: starts mid-laugh, brows high … mouth falls open and stays open.
     Бабушка-Яга — SATISFACTION: her eyes stay down on her cup … one eyebrow climbs.

   Name, space, em dash, space, one or two words in capitals, colon, then the
   anatomy as before.

   WHAT IS CHECKED. Three things, and deliberately not more. That the emotion is
   declared at all; that it is one of the known words, because an unknown word
   has no anatomy to check against; and that the paragraph contains at least one
   piece of anatomy that BELONGS to that emotion and none that CONTRADICTS it.
   The contradiction lists are the valuable half — they are what would have
   failed Мама, whose UNEASE paragraph carried three pieces of anger.

   WHAT IS NOT CHECKED, and must stay a human job: whether the emotion is the
   RIGHT one for the story. Code cannot know that Яга should not be astonished.

   THE LISTS ARE MEANT TO GROW. Add an emotion when a shot needs one; add a
   forbid the first time a face comes back wrong in a way a phrase predicted. */
type emotionSpec = {name: string, belongs: array<string>, contradicts: array<string>}

let emotions: array<emotionSpec> = [
  {
    name: "SHOCK",
    belongs: ["mouth falls open", "mouth stays open", "jaw hangs", "jaw falls", "eyes go round", "eyes snap wide", "eyes open wide", "eyes go wide", "brows shoot up", "brows drive up", "brows go up"],
    contradicts: ["eyes narrow", "brows draw in", "brows draw together", "brows draw down", "jaw sets", "lips press", "corner of the mouth pulls up"],
  },
  {
    name: "DISBELIEF",
    belongs: ["mouth falls open", "mouth stays open", "jaw hangs", "eyes go wide", "eyes snap wide", "eyes open wide", "brows shoot up", "brows go up", "blinks"],
    contradicts: ["eyes narrow", "brows draw in", "brows draw together", "brows draw down", "jaw sets", "lips press"],
  },
  {
    name: "WONDER",
    belongs: ["mouth falls open", "mouth stays open", "eyes go wide", "eyes open wide", "eyes shine", "eyes bright", "brows go up", "brows climb"],
    contradicts: ["eyes narrow", "brows draw together", "brows draw down", "jaw sets", "lips press"],
  },
  {
    name: "DELIGHT",
    belongs: ["eyes squeeze", "eyes crinkle", "cheeks bunch", "cheeks push up", "mouth stretches", "mouth stretched", "grin"],
    contradicts: ["brows draw together", "brows draw down", "jaw sets", "lips press", "mouth closes into"],
  },
  {
    name: "GLEE",
    belongs: ["eyes squeeze", "eyes crinkle", "cheeks bunch", "mouth stretches", "mouth stretched", "grin", "squeal"],
    contradicts: ["brows draw together", "brows draw down", "jaw sets", "lips press"],
  },
  {
    name: "AMUSEMENT",
    belongs: ["corner of the mouth", "closed-lipped smile", "eyes narrow", "one eyebrow climbs", "one eyebrow rises", "dry"],
    contradicts: ["jaw drops", "jaw hangs", "mouth falls open", "eyes go round", "eyes snap wide", "brows shoot up"],
  },
  {
    name: "SATISFACTION",
    belongs: ["corner of the mouth", "closed-lipped smile", "eyes narrow", "one eyebrow climbs", "one eyebrow rises", "settles"],
    contradicts: ["jaw drops", "jaw hangs", "mouth falls open", "eyes go round", "eyes snap wide", "brows shoot up"],
  },
  {
    name: "UNEASE",
    belongs: ["mouth stays closed", "lips close", "mouth closes", "brows stay level", "eyes stay open", "eyes stay steady"],
    contradicts: ["eyes narrow", "brows draw together", "brows draw in", "brows draw down", "jaw sets", "lips press", "mouth falls open", "jaw hangs", "grin"],
  },
  {
    name: "CONFUSION",
    belongs: ["brows draw together", "brows lift", "uncertain", "loose O", "blank O", "mouth falls open into"],
    contradicts: ["eyes squeeze", "cheeks bunch", "grin", "jaw sets"],
  },
  {
    name: "WORRY",
    belongs: ["brows lift in the middle", "brows draw up", "mouth closes", "mouth tightens", "eyes drop"],
    contradicts: ["grin", "cheeks bunch", "closed-lipped smile", "jaw hangs"],
  },
  {
    name: "ANGER",
    belongs: ["brows draw down", "brows draw together", "jaw sets", "lips press", "eyes narrow"],
    contradicts: ["mouth falls open", "jaw hangs", "eyes go round", "brows shoot up", "grin"],
  },
  {
    name: "EAGERNESS",
    belongs: ["eyes widen", "brows lift", "mouth opens", "leans in", "grin", "bounces"],
    contradicts: ["eyes narrow", "lips press", "jaw sets", "eyelids droop"],
  },
  {
    name: "DETERMINATION",
    belongs: ["jaw sets", "lips press", "brows draw down", "eyes steady", "eyes narrow"],
    contradicts: ["mouth falls open", "jaw hangs", "eyes go round", "brows shoot up"],
  },
  {
    name: "SULK",
    belongs: ["shoulders slump", "shoulders drop", "chin tucks", "chin drops", "lips press", "pout", "lower lip pushes", "brows draw down", "looks down", "eyes drop"],
    contradicts: ["grin", "mouth falls open", "eyes go wide", "eyes snap wide", "brows shoot up", "cheeks bunch"],
  },
  {
    name: "DISGUST",
    belongs: ["nose wrinkles", "upper lip lifts", "tongue", "eyes screw", "head pulls back"],
    contradicts: ["grin", "cheeks bunch", "eyes shine"],
  },
]

let emotionNames = emotions->Belt.Array.map(e => e.name)

/* DELIVERED SHOTS ARE NOT RE-JUDGED BY A RULE THAT POSTDATES THEM. 2026-08-26.

   Eighteen creatives carried a REACTIONS block when this gate was written and
   seventeen of them were already shot and paid for. Failing them would repeat
   the mistake assertNamedFeaturesAreBacked made — calling every delivered shot
   bad — and it would be worse here, because a delivered creative is bound BY
   HASH to the approval the author gave it. Editing one to satisfy a later rule
   would falsify the record of what she actually approved and what was actually
   sent.

   So these are listed, once, by name. Anything not on this list is gated. When
   a listed shot is REWRITTEN for a reshoot, take it off the list — the new text
   is new work and gets the new rule. v07table will come off it the moment its
   reshoot is written. */
let emotionGateGrandfathered = [
  "s8shot1", "s8shot2", "s8tochka", "s8tochka2", "s8vasya", "s8offer", "s8glass",
  "s8salat", "s8bowl", "s8fu", "s8rusya", "s8mak", "s8poppy",
  "v01ask", "v02answer", "v03gather", "v04read", "v05single", "v05vzhukh",
  "v06frosya", "v07table",
]

let assertEmotionsDeclared = (record, problem): unit => {
  let grandfathered = emotionGateGrandfathered->Belt.Array.some(j => j == record.jobId)
  if !grandfathered {
    let c = record.creative
    switch reactionHeaders->Belt.Array.getBy(h => Js.String2.includes(c, "\n" ++ h ++ "\n")) {
    | None => ()
    | Some(h) =>
      let after = Belt.Array.getExn(Js.String2.split(c, "\n" ++ h ++ "\n"), 1)
      let block =
        Belt.Array.getExn(Js.String2.splitByRe(after, %re("/\n[A-ZА-Я][A-ZА-Я ,\-]{4,}\n/")), 0)
        ->Belt.Option.getWithDefault(after)
      let paragraphs = Js.String2.split(block, "\n\n")
      record.cast
      ->Belt.Array.keepMap(t =>
        switch castRuName(t) {
        | None => None
        | Some(n) => Some((n, castEntry(t).tag))
        }
      )
      ->Belt.Array.forEach(((n, tag)) => {
        /* The creative may write a longer form of the name than the cast token
           carries — "Бабушка-Яга" for Яга — so the paragraph is found by the
           name appearing in its opening, not by starting with it exactly. */
        let opensWith = (p: string, n: string) => {
          let head = Js.String2.slice(Js.String2.trim(p), ~from=0, ~to_=40)
          Js.String2.includes(head, n)
        }
        /* Match by the full "NAME — " marker, not by prefix: "@VASYA" is a
           prefix of "@VASYA_MAMA" and "Вася" of "Вася-мама", so a bare
           containment check hands one character the other's paragraph. */
        let mName = n ++ " — "
        let mTag = tag ++ " — "
        let para =
          paragraphs->Belt.Array.getBy(p =>
            Js.String2.includes(p, mTag) || Js.String2.includes(p, mName)
          )
        switch para {
        | None =>
          problem(
            record.jobId,
            n ++
            " has no paragraph of their own in the REACTIONS block. Every character needs one that starts with their name, so the emotion they are playing can be named and checked against the anatomy that follows.",
          )
        | Some(p) =>
          let marker = Js.String2.includes(p, mTag) ? mTag : mName
          switch Js.String2.indexOf(p, marker) {
          | -1 =>
            problem(
              record.jobId,
              n ++
              " is described without naming the emotion. Write it as \"" ++
              n ++
              " — EMOTION: …\" — one or two words in capitals after an em dash, then the anatomy. Without a named feeling there is nothing for the choreography to be checked against, which is how Мама's UNEASE came back as a scowl in v07table. Known words: " ++
              Js.Array2.joinWith(emotionNames, ", ") ++
              ".",
            )
          | i =>
            let rest = Js.String2.sliceToEnd(p, ~from=i + Js.String2.length(marker))
            switch Js.String2.indexOf(rest, ":") {
            | -1 =>
              problem(
                record.jobId,
                n ++
                "'s emotion is not closed with a colon. The syntax is \"" ++
                n ++
                " — EMOTION: …\" so the gate can tell the label from the choreography.",
              )
            | j =>
              let label = Js.String2.trim(Js.String2.slice(rest, ~from=0, ~to_=j))
              let words = Js.String2.split(label, " ")->Belt.Array.keep(w => w != "")
              if Belt.Array.length(words) < 1 || Belt.Array.length(words) > 2 {
                problem(
                  record.jobId,
                  n ++
                  " declares \"" ++
                  label ++
                  "\", which is " ++
                  Belt.Int.toString(Belt.Array.length(words)) ++
                  " words. An emotion is one or two words. A sentence here is a description, and a description is what this gate exists to stop standing in for a feeling.",
                )
              } else {
                switch emotions->Belt.Array.getBy(e => e.name == label) {
                | None =>
                  problem(
                    record.jobId,
                    n ++
                    " declares \"" ++
                    label ++
                    "\", which the gate does not know, so it cannot check the choreography against it. Use one of: " ++
                    Js.Array2.joinWith(emotionNames, ", ") ++
                    " — or add the new one to `emotions` in this file with the anatomy that belongs to it and the anatomy that contradicts it.",
                  )
                | Some(spec) =>
                  let lower = Js.String2.toLowerCase(p)
                  /* A reactions paragraph is a JOURNEY — it says what the face
                     starts as and what it becomes — but the label names where it
                     ENDS, because that is the feeling the shot delivers. So the
                     anatomy that BELONGS is looked for anywhere in the paragraph,
                     while the anatomy that CONTRADICTS is looked for only in the
                     destination. Without that split the gate failed Руся for
                     being confused before he was delighted, which is the whole
                     point of his performance. The destination is the last third
                     of the paragraph: these are written with the arrival at the
                     end, every time. */
                  let dest = {
                    let n = Js.String2.length(lower)
                    let from = n > 180 ? n - n / 3 : 0
                    Js.String2.sliceToEnd(lower, ~from)
                  }
                  /* A NEGATIVE LOCK IS NOT A CONTRADICTION. "her jaw never drops"
                     and "without her eyes narrowing" are the prompt DEFENDING the
                     emotion, not betraying it, and a gate that fires on them
                     punishes exactly the writing it wants. */
                  let negators = ["never", "not ", "no ", "without", "nor "]
                  let negatedAt = (hay: string, at: int) => {
                    let from = at > 30 ? at - 30 : 0
                    let window = Js.String2.slice(hay, ~from, ~to_=at)
                    negators->Belt.Array.some(g => Js.String2.includes(window, g))
                  }
                  let has = spec.belongs->Belt.Array.some(w => Js.String2.includes(lower, w))
                  if !has {
                    problem(
                      record.jobId,
                      n ++
                      " is marked " ++
                      label ++
                      " but the choreography never does any of the things " ++
                      label ++
                      " does with a face. Put at least one of these in: " ++
                      Js.Array2.joinWith(spec.belongs, "; ") ++
                      ".",
                    )
                  }
                  spec.contradicts->Belt.Array.forEach(w => {
                    let at = Js.String2.indexOf(dest, w)
                    if at >= 0 && !negatedAt(dest, at) {
                      problem(
                        record.jobId,
                        n ++
                        " is marked " ++
                        label ++
                        " but the choreography ENDS on \"" ++
                        w ++
                        "\", which is a different feeling on the same face. This is exactly the v07table failure: Мама was meant to be unsettled and her paragraph finished on brows drawing in, eyes narrowing and a jaw setting, so she came back angry. Either change the anatomy or change the label — but they have to agree.",
                      )
                    }
                  })
                }
              }
            }
          }
        }
      })
    }
  }
}

/* THE SHOT IS AS LONG AS THE AUDIO, NOT AS LONG AS THE SCRIPT GUESSES.
   s5job2 was generated TWICE at 20 seconds because its durations came from the
   shooting script's estimates (4+2+2+3+4+5). The approved ElevenLabs reads for
   those same four lines total 20.3 seconds of speech BEFORE any gap between
   them, so the audio could never fit the picture, and both renders had to have
   Фрося and Вася compressed 20–25% at the dub. Two generations at 130 credits
   each — roughly ten dollars — to discover something measurable for free.
   The reads already existed. Nobody looked at them.

   LINE_INDEX.json maps every recorded line to its transcript and its duration.
   This assertion matches the job's script lines against it and refuses any job
   whose duration cannot hold the audio it will have to carry. */
let lineIndexPath = "../stories/drakosha/production/kuku_flow/audio/LINE_INDEX.json"

type indexEntry = {dur: option<float>, text: option<string>}

/* A FILENAME IS A DECISION. The audio directory keeps every take ever rendered,
   and the ones marked _FINAL / _APPROVED / _CONTROL are the chosen reads; the
   rest are superseded history. Left in the index they are not merely noise —
   they are wrong answers. `line34_YAGA.mp3` holds the OLD wording of the same
   speech, so the duration gate found two files for one line, added them, and
   demanded a 20s shot for 8.8s of dialogue.

   So: once any take of a line is decided, every other take of that line stops
   existing as far as the gates are concerned. Lines are grouped by their
   `lineNN_` prefix, which is how they are named. */
let lineKey = (file: string): string =>
  switch Js.String2.match_(file, %re("/^line[0-9]+_/")) {
  | Some(m) => Belt.Array.get(m, 0)->Belt.Option.flatMap(x => x)->Belt.Option.getWithDefault(file)
  | None => file
  }

let isDecided = (file: string): bool =>
  ["_FINAL", "_APPROVED", "_CONTROL"]->Belt.Array.some(mark => Js.String2.includes(file, mark))

let decidedOnly = (index: array<(string, float, string)>): array<(string, float, string)> => {
  let settled = Js.Dict.empty()
  index->Belt.Array.forEach(((file, _, _)) =>
    if isDecided(file) {
      Js.Dict.set(settled, lineKey(file), true)
    }
  )
  index->Belt.Array.keep(((file, _, _)) =>
    switch Js.Dict.get(settled, lineKey(file)) {
    | Some(_) => isDecided(file)
    | None => true
    }
  )
}

let loadLineIndex = (): array<(string, float, string)> =>
  if !existsSync(lineIndexPath) {
    []
  } else {
    let raw = readFileSync(lineIndexPath, "utf8")
    switch Js.Json.parseExn(raw)->Js.Json.decodeObject {
    | None => []
    | Some(obj) =>
      obj
      ->Js.Dict.entries
      ->Belt.Array.keepMap(((file, v)) =>
        switch Js.Json.decodeObject(v) {
        | None => None
        | Some(e) =>
          switch (
            Js.Dict.get(e, "dur")->Belt.Option.flatMap(Js.Json.decodeNumber),
            Js.Dict.get(e, "text")->Belt.Option.flatMap(Js.Json.decodeString),
          ) {
          | (Some(d), Some(t)) => Some((file, d, t))
          | _ => None
          }
        }
      )
      ->decidedOnly
    }
  }

/* A recorded line and a script line are "the same line" when the first 20
   Cyrillic letters agree. Transcripts mangle endings — «светились» came back as
   «светилили» — so never demand a full match. */
let findRecording = (index, scriptLine: string): option<(string, float)> => {
  let want = bare(scriptLine)
  if Js.String2.length(want) < 3 {
    None
  } else if Js.String2.length(want) < 8 {
    /* Short lines like «Ма́ма…» are only four letters and would substring-match
       half the library — «мама» is inside «маманетонииактак…». Demand equality
       for these, so the one-word warning still gets counted. */
    index
    ->Belt.Array.getBy(((_, _, text)) => bare(text) == want)
    ->Belt.Option.map(((f, d, _)) => (f, d))
  } else {
    let probe = Js.String2.length(want) > 20 ? Js.String2.slice(want, ~from=0, ~to_=20) : want
    index
    ->Belt.Array.getBy(((_, _, text)) => Js.String2.includes(bare(text), probe))
    ->Belt.Option.map(((f, d, _)) => (f, d))
  }
}

/* 0.25s between one line ending and the next beginning. Below that they tread
   on each other; the author's note is that nobody waits, so this is a breath
   and not a pause. */
let gapSec = 0.25

/* Screen time that carries no dialogue and therefore is not in the audio total:
   the establishing beat before anyone speaks, and the tail after the last line.
   s5job2's wide ran 2.4s before Бабушка-Яга's first word. Without this the gate
   compares speech against the whole shot and calls 20s enough when it isn't. */
let nonDialogueHeadSec = 2.0

let assertDurationHoldsAudio = (record, script: string, problem): unit => {
  let index = loadLineIndex()
  if Belt.Array.length(index) > 0 {
    /* A job that names the recordings it carries is sized against those. Without
       it, a shot covering half a script line is measured against the whole line
       and padded with seconds that hold nothing. */
    let declared =
      record.carriesLines->Belt.Array.keepMap(f =>
        index
        ->Belt.Array.getBy(((name, _, _)) => name == f)
        ->Belt.Option.map(((n, d, _)) => (n, d))
      )
    if Belt.Array.length(record.carriesLines) > 0 && Belt.Array.length(declared) < Belt.Array.length(record.carriesLines) {
      problem(
        record.jobId,
        "names a recording in carriesLines that is not in LINE_INDEX.json. A job may only be sized against takes the index knows the length of.",
      )
    }
    let lines =
      shRange(record.shots)->Belt.Array.map(sh => linesForShot(script, sh))->Belt.Array.concatMany
    /* One recording can answer TWO script lines: the script splits Фрося's wish
       across SH060 and SH061 for the cut, but it was recorded as one continuous
       read. Counting it twice claimed the job needed 29s when it needs 21. */
    let seen = Js.Dict.empty()
    let found =
      lines
      ->Belt.Array.keepMap(l => findRecording(index, l))
      ->Belt.Array.keep(((file, _)) =>
        switch Js.Dict.get(seen, file) {
        | Some(_) => false
        | None =>
          Js.Dict.set(seen, file, true)
          true
        }
      )
    let found = Belt.Array.length(record.carriesLines) > 0 ? declared : found
    let total = found->Belt.Array.reduce(0.0, (acc, (_, d)) => acc +. d)
    let needed =
      total +.
      gapSec *. Belt.Int.toFloat(Belt.Array.length(found) - 1) +.
      nonDialogueHeadSec
    let have = Belt.Int.toFloat(record.durationSec)
    if Belt.Array.length(found) > 0 && needed > have {
      let names = found->Belt.Array.map(((f, d)) => f ++ " " ++ Js.Float.toFixedWithPrecision(d, ~digits=2) ++ "s")
      problem(
        record.jobId,
        "duration is " ++
        Belt.Int.toString(record.durationSec) ++
        "s but the APPROVED AUDIO for these shots needs " ++
        Js.Float.toFixedWithPrecision(needed, ~digits=1) ++
        "s — " ++
        Js.Array2.joinWith(names, ", ") ++
        ". Set the duration from the recorded reads, never from the script's estimates; otherwise the dub has to be sped up.",
      )
    }
  }
}

/* A model is not a preference. Each one has a hard ceiling on how long a single
   generation may run and how many image references it will accept, and going
   past either does not error — it truncates or silently drops references, which
   is a spent credit and a clip that has to be shot again. Priced and checked
   here, before submission, for the same reason durations are: the cheapest fix
   for a bad generation is not generating it. */
let assertModelFits = (spec: Drakosha_SeedanceJobs.jobSpec, refCount: int, problem): unit => {
  let m = spec.model
  let name = Drakosha_SeedanceJobs.modelName(m)
  let maxSec = Drakosha_SeedanceJobs.modelMaxSec(m)
  let maxRefs = Drakosha_SeedanceJobs.modelMaxRefs(m)
  if spec.record.durationSec > maxSec {
    problem(
      spec.record.jobId,
      "asks for " ++
      Belt.Int.toString(spec.record.durationSec) ++
      "s on " ++
      name ++
      ", which generates at most " ++
      Belt.Int.toString(maxSec) ++
      "s. Either move the job to seedance_2_5 or split the shots — never let it truncate.",
    )
  }
  /* Kling accepts no reference images at all, so identity has nowhere to come
     from except the start frame. A Kling job without one is a job that will
     invent a different child. The references a Kling job declares are not sent
     — they stay in the record as provenance, which is why the count is not an
     error here the way it is on Seedance. */
  switch spec.model {
  | Kling26 | Kling30 | Veo31Lite =>
    switch spec.record.startImage {
    | None =>
      problem(
        spec.record.jobId,
        "runs on " ++
        name ++
        ", which takes no image references. With no start frame either, nothing in the call says who she is. Give it a start frame.",
      )
    | Some(_) => ()
    }
    switch (spec.model, spec.endImage) {
    | (Kling26, Some(_)) =>
      problem(
        spec.record.jobId,
        "declares an end frame, but only kling3_0 accepts one. On kling2_6 it is silently ignored and the clip will not loop.",
      )
    | _ => ()
    }
  | Mini | V20 | V25 =>
    if refCount > maxRefs {
      problem(
        spec.record.jobId,
        "binds " ++
        Belt.Int.toString(refCount) ++
        " image references but " ++
        name ++
        " accepts " ++
        Belt.Int.toString(maxRefs) ++
        ". The extras are dropped without an error and the shot comes back off-model.",
      )
    }
  }
}

let creditTotal = ref(0.0)

/* A CAST TAGLINE IS IDENTITY, NEVER INVENTORY.
   @YAGA's line said "birch broom in hand" and @FROSYA's said "no pencil". Both
   are states, not identity, and both were fed to the model in EVERY job — which
   is why she held a broom through a dinner she was eating with both hands, and
   why the job in which Фрося RECEIVES the pencil also told the model she has
   none. The choreography owns what is in a character's hands, shot by shot; the
   reference line owns only who they are. */
let assertTagLinesAreIdentityOnly = (record: shotRecord, problem): unit =>
  record.cast->Belt.Array.forEach(t => {
    let entry = castEntry(t)
    let held = [" in hand", "in her hand", "in his hand", "holding a", "holding her", "no pencil", "empty-handed"]
    held->Belt.Array.forEach(phrase =>
      if Js.String2.includes(Js.String2.toLowerCase(entry.tagLine), phrase) {
        problem(
          record.jobId,
          "the reference line for " ++
          entry.tag ++
          " says \"" ++
          Js.String2.trim(phrase) ++
          "\" — that is what is in their hands, which changes shot to shot and belongs in the choreography. A reference line fixes identity only, or every job in the episode inherits one pose.",
        )
      }
    )
  })

/* HANDS ARE A POSITIVE STATEMENT, NEVER A PROHIBITION.
   s6jobB's choreography said "Бабушка-Яга has NO broom in any frame" and she came
   back holding the broom in two of four shots — and because that hand was full,
   the beckon she was supposed to make with it never happened. Her reference sheet
   is a picture of a woman holding a broom, and a picture beats the word "no".

   The only thing that displaces what a sheet shows is a competing instruction of
   the same kind: say what IS in the hands and what those hands are doing. "Her
   hands are empty, hanging open at her sides" occupies the cell; "no broom"
   leaves it empty and the sheet fills it back in.

   So every character in a job needs a HANDS line, and it must contain a positive
   verb — a prohibition alone does not count. */
/* The header must START A LINE. Matching it anywhere let s6jobA pass on the words
   "CLOSE ON HANDS, the SAME framing" inside a shot description — a gate that can
   be satisfied by an accident of phrasing is not a gate. */
let handsHeaders = ["\nHANDS — ", "\nHANDS - ", "\nHANDS: "]

let handsVerbs = [
  "holding", "holds", "grips", "gripping", "resting", "rests", "closed around",
  "open at", "open and", "tucked", "folded", "pressed", "planted", "hooked",
  "clutch", "cupped", "hangs", "hanging", "raises", "raised", "crooks", "reaching",
  "carries", "wrapped", "spread", "flat against", "hang ", "come up", "comes up",
]

let assertHandsWritten = (record, problem): unit => {
  let c = record.creative
  switch handsHeaders->Belt.Array.getBy(h => Js.String2.includes(c, h)) {
  | None =>
    problem(
      record.jobId,
      "the choreography has no HANDS block. Every character's hands must be stated positively in every job, or the reference sheet puts back whatever it shows them holding — which is how Бабушка-Яга carried her broom through a scene in which she was giving away two gifts.",
    )
  | Some(h) =>
    let after = Belt.Array.getExn(Js.String2.split(c, h), 1)
    let block =
      Belt.Array.getExn(Js.String2.splitByRe(after, %re("/\n[A-ZА-Я][A-ZА-Я ,\-]{4,}\n/")), 0)
      ->Belt.Option.getWithDefault(after)
    let missing =
      record.cast
      ->Belt.Array.keep(t =>
        switch castRuName(t) {
        | None => false
        | Some(n) =>
          !Js.String2.includes(block, n) &&
          !Js.String2.includes(block, castEntry(t).tag)
        }
      )
      ->Belt.Array.keepMap(castRuName)
    if Belt.Array.length(missing) > 0 {
      problem(
        record.jobId,
        "the HANDS block never says what " ++
        Js.Array2.joinWith(missing, ", ") ++
        " is doing with their hands. An unwritten pair of hands is filled from the reference sheet.",
      )
    }
    let lower = Js.String2.toLowerCase(block)
    let verbs = handsVerbs->Belt.Array.keep(v => Js.String2.includes(lower, v))
    if Belt.Array.length(verbs) < Belt.Array.length(record.cast) {
      problem(
        record.jobId,
        "the HANDS block leans on prohibitions rather than saying what the hands ARE doing. \"No broom\" lost to a reference sheet that shows one; \"her hands hang open and empty at her sides\" wins, because it occupies the same cell. Give every character a positive hand action.",
      )
    }
  }
}

/* EVERY CHARACTER OWNS A WALL.
   Scene 6 was shot with every background written as "the hall running away, soft
   and out of focus". Each shot was correct on its own and the scene had no
   geography at all — nobody could say where anyone stood, because nothing said.
   The cost is not tidiness: Мама's turn at the end is the cut into scene 7, and
   against an unnamed blur it is a woman turning her head rather than a woman
   looking at the niche she is about to open.

   "Soft and out of focus" is not a background. It is a refusal to choose one,
   which hands the model the same blank cell the broom came out of.

   So: the BACKGROUNDS block must name every character and put each of them
   against one of the four walls of the hall — or state outright that the framing
   shows no wall, which is a decision rather than an omission.

   BUT ONLY WHEN THERE IS NO START FRAME. 2026-08-24, the author: "why is it even
   important when I'm giving you reference with the background?" She is right.
   This gate was written for shots the model builds from text, where an unnamed
   background is a blank cell it fills however it likes. When she supplies a
   start plate, the wall is ALREADY ANSWERED — by a picture, which outranks any
   sentence I could write about it. Demanding a canon wall name anyway made me
   guess at a room I was looking at, put "the kitchen end" behind Фрося when it
   is the hatch wall, and cost her a correction on a question her own frame had
   already settled. A gate that manufactures a wrong answer is worse than no
   gate: the wrong name then fights the plate.

   So with a start image, deferring to the plate IS the decision, and saying so
   passes. Naming a wall still passes too, and is worth doing when it is known —
   it carries the geography forward into the shots that have no plate. What must
   never happen is a background block that contradicts the frame it is anchored
   to; that is the CONCORDANCE RULE's job, not this one's.

   Note also that which wall sits behind a character is a fact about where the
   CAMERA stands, not about the character. It is answered per shot and never
   carried over from the last one. */
let namedWalls = [
  "hatch wall", "hatch-wall", "ramp", "railing", "back wall", "kitchen end",
  "niche", "table end", "boulder-block wall", "no wall", "shows no wall",
]

/* DO NOT NAME A THING THE PICTURE DOES NOT SHOW. 2026-08-24.

   Having just been told the wall behind Фрося is the hatch wall, I wrote HATCH
   WALL into her BACKGROUNDS block — over a start frame showing a bare run of
   stone blocks, with no hatch reference bound. The author: "giving the model
   that there is a hatch wall and not providing the reference for it and giving
   a start frame that doesn't have a hatch wall is just asking for trouble."

   Exactly right, and it is the CONCORDANCE RULE pointing the other way. A
   named architectural feature is an instruction to draw one. Say "hatch" and
   something hatch-shaped appears in a frame that had none, and now the plate
   and the prompt are fighting over the same wall.

   The distinction the two of us kept collapsing: a wall's NAME is production
   knowledge — it belongs in the job record, the shot list, the geography note,
   so the next shot knows where it stands. What goes in the PROMPT is what the
   frame shows. They are not the same document and they do not want the same
   sentence.

   The first version of this gate failed eight already-delivered scene 8 shots,
   which is how I learned what it can and cannot know. It reads FILENAMES. A
   start plate that genuinely shows the stove does not have "stove" in its name,
   so demanding a name-match calls every good shot a bad one. A gate that cannot
   see the picture must not pretend to.

   So it checks only what is checkable:
     - no start frame and no reference carrying the feature → FAIL. Nothing can
       show it, so naming it is inventing it.
     - a start frame, and the block names a feature while calling that same wall
       bare or plain → FAIL. Both cannot be true of one frame, and that
       contradiction is exactly the sentence that put a hatch on a blank run of
       stone.
     - a start frame and no contradiction → passes. The plate may well show it;
       only a person can say, and this gate does not get a vote. */
let wallFeatures = ["hatch", "niche", "ramp", "railing", "stove", "iron door"]
let bareWords = ["bare run", "plain run", "bare wall", "plain wall", "blank wall", "nothing is set into", "nothing stands against"]

let assertNamedFeaturesAreBacked = (record, refPaths: array<string>, problem): unit => {
  let c = record.creative
  switch Js.String2.includes(c, "\nBACKGROUNDS") {
  | false => ()
  | true =>
    let after = Belt.Array.getExn(Js.String2.split(c, "\nBACKGROUNDS"), 1)
    let block =
      Belt.Array.getExn(Js.String2.splitByRe(after, %re("/\n[A-ZА-Я][A-ZА-Я ,\-]{4,}\n/")), 0)
      ->Belt.Option.getWithDefault(after)
    let lower = Js.String2.toLowerCase(block)
    let backing = refPaths->Belt.Array.map(Js.String2.toLowerCase)
    let hasStartImage = switch record.startImage {
    | Some(_) => true
    | None => false
    }
    let callsItBare = bareWords->Belt.Array.some(w => Js.String2.includes(lower, w))
    wallFeatures->Belt.Array.forEach(f => {
      let named = Js.String2.includes(lower, f)
      let inRefs = backing->Belt.Array.some(b => Js.String2.includes(b, f))
      if named && !inRefs {
        if !hasStartImage {
          problem(
            record.jobId,
            "the BACKGROUNDS block names \"" ++
            f ++
            "\" and there is no start frame and no bound reference that shows one. With nothing to look at, a named feature is simply an instruction to invent one.",
          )
        } else if callsItBare {
          problem(
            record.jobId,
            "the BACKGROUNDS block names \"" ++
            f ++
            "\" and in the same breath calls that wall bare or plain. Both cannot be true of the frame in front of you: either the plate shows the feature, in which case describe it, or it does not, in which case do not name it. This is the sentence that put a hatch on a blank run of stone.",
          )
        }
      }
    })
  }
}

/* THE GLYPH GATE — no letter the model draws is ever trusted. 2026-08-20.

   I wrote a gate here yesterday claiming the model can hold a row of tiles if
   the tiles are big enough, citing s7jobD. s7jobD was thrown out. Its glyphs
   were wrong AND the finger pointed at the wrong tiles, which is a fault that
   does not exist in a still frame — and still frames were all I looked at.

   The actual record for scene 7, from the author:

     - the top-down row: one tile plainly wrong, and the pointing wrong on top
       of that. Discarded and replaced with our own composite.
     - Мама laying the tiles out: wrong count and wrong letters.
     - the third: tiles too small, letters wrong, covered with a plate.

   Nothing survived. There is no size at which the model becomes reliable with
   Cyrillic, and there is no prompt that fixes it. So the rule is not a
   threshold, it is absolute.

   THE RULE: any shot containing a letter that the audience must read is shot
   on the assumption that every glyph in it will be wrong, and is designed so
   that we can replace the glyphs afterwards on the moving footage. That means
   a locked or near-locked camera, the tile or the paper at rest at the moment
   it must be read, and enough pixels on the glyph to repaint cleanly.

   And the labelling follows the performance, never the other way round:
   whatever tile the finger actually touches becomes the letter he says. We do
   not ask the model to point correctly at letters it cannot draw. */
let assertGlyphsPlanned = (record, problem): unit => {
  let c = record.creative
  let lower = Js.String2.toLowerCase(c)
  let hasLetters =
    Js.String2.includes(lower, "фишк") ||
    Js.String2.includes(lower, "tile") ||
    Js.String2.includes(lower, "букв") ||
    Js.String2.includes(lower, "слово") ||
    Js.String2.includes(lower, "letter")
  if hasLetters {
    switch Js.String2.includes(c, "\nGLYPHS") {
    | false =>
      problem(
        record.jobId,
        "this shot has letters in it and no GLYPHS block. Every glyph the model draws is assumed wrong — scene 7 lost every single letter shot. State how this shot survives that: either NOT READABLE (the letters are texture and nobody reads them), or REPAINT with the camera hold and the moment the letters are at rest, or PLATE if the letters are our art over a generated plate.",
      )
    | true =>
      let after = Belt.Array.getExn(Js.String2.split(c, "\nGLYPHS"), 1)
      let block = Belt.Array.getExn(Js.String2.split(after, "\n\n"), 0)
      let up = Js.String2.toUpperCase(block)
      let planned =
        Js.String2.includes(up, "NOT READABLE") ||
        Js.String2.includes(up, "REPAINT") ||
        Js.String2.includes(up, "PLATE")
      if !planned {
        problem(
          record.jobId,
          "the GLYPHS block names no strategy. It must say NOT READABLE, REPAINT or PLATE.",
        )
      }
      if Js.String2.includes(up, "REPAINT") && !Js.String2.includes(up, "AT REST") {
        problem(
          record.jobId,
          "a REPAINT shot must say when the letters are AT REST — glyphs can only be replaced cleanly on tiles or paper that are not moving. If they never come to rest, the shot cannot be repainted and needs a different plan.",
        )
      }
    }
  }
}

let assertBackgroundsAssigned = (record, problem): unit => {
  let c = record.creative
  switch Js.String2.includes(c, "\nBACKGROUNDS") {
  | false =>
    problem(
      record.jobId,
      "the choreography has no BACKGROUNDS block. Every character in frame must be placed against a named wall of the hall — the hatch wall, the ramp side, the back wall, or the table end — or the shot must say it shows no wall at all.",
    )
  | true =>
    let after = Belt.Array.getExn(Js.String2.split(c, "\nBACKGROUNDS"), 1)
    let block =
      Belt.Array.getExn(Js.String2.splitByRe(after, %re("/\n[A-ZА-Я][A-ZА-Я ,\-]{4,}\n/")), 0)
      ->Belt.Option.getWithDefault(after)
    /* Names are matched case-insensitively: a BACKGROUNDS block naturally writes
       "Behind МАМА" in caps while the cast register holds "Мама". A gate that
       fails on capitalisation trains people to fight the gate. */
    let blockLower = Js.String2.toLowerCase(block)
    let missing =
      record.cast
      ->Belt.Array.keep(t =>
        switch castRuName(t) {
        | None => false
        | Some(n) =>
          !Js.String2.includes(blockLower, Js.String2.toLowerCase(n)) &&
          !Js.String2.includes(block, castEntry(t).tag)
        }
      )
      ->Belt.Array.keepMap(castRuName)
    if Belt.Array.length(missing) > 0 {
      problem(
        record.jobId,
        "the BACKGROUNDS block never says what is behind " ++
        Js.Array2.joinWith(missing, ", ") ++
        ". A character with no wall behind them is a character the audience cannot place, and the model puts a different room back there in every shot.",
      )
    }
    let lower = Js.String2.toLowerCase(block)
    let walls = namedWalls->Belt.Array.keep(w => Js.String2.includes(lower, w))
    /* With an author plate the wall is already answered by a picture; pointing
       at the plate is a decision, not an omission. See the note above. */
    let deferredToPlate =
      Js.String2.includes(lower, "start image") ||
      Js.String2.includes(lower, "start frame") ||
      Js.String2.includes(lower, "the plate")
    let hasStartImage = switch record.startImage {
    | Some(_) => true
    | None => false
    }
    if Belt.Array.length(walls) == 0 && !(hasStartImage && deferredToPlate) {
      problem(
        record.jobId,
        "the BACKGROUNDS block names no wall of the hall. \"Soft and out of focus\" describes the lens, not the room. Name the hatch wall, the ramp and its railing, the back wall with the niche, or the table end — or say the framing shows no wall. This job has a start frame, so \"as the start image has it\" is also a valid answer: the plate already settles the wall and outranks anything written here.",
      )
    }
  }
}

/* ============================================================================
   THE 2026-08-20 GATES — every one of these exists because I broke it that day.
   They are written here rather than in a document because on that day I read
   the documents, wrote new ones, and then broke the rules in them within the
   hour. The gates that were CODE I obeyed without argument; the gates that were
   PROSE I skipped every time. So these are code.
   ========================================================================= */

/* GATE 1 — AN UNKNOWN SHOT CODE IS A FAILURE, NOT A FREE PASS.

   `shRange` pulls the digits out of a shot code. Given none, it returns an
   empty array — and every script-derived check downstream then has nothing to
   check and passes silently: no script line, so no missing-line error; no
   lines, so no missing-recording error and no duration error.

   On 2026-08-20 a gate fired on "LOOP-WRITE-03-FACE-KLING" saying the script
   gave that shot a line the choreography did not contain. Rather than supply
   the line, I renamed the job until the gate stopped firing. Then I named the
   Точка job "TOCHKA-MARK" — no digits at all — and it sailed through every
   check and was submitted with no recording in existence. Ten credits, and the
   wrong shot entirely.

   A job now either names real SH numbers, or declares itself a non-script
   element and says why. Silence is no longer an option. */
let assertShotCodeResolves = (record, problem): unit => {
  let codes = shRange(record.shots)
  if Belt.Array.length(codes) == 0 {
    let c = record.creative
    let declared =
      Js.String2.includes(c, "NON-SCRIPT ELEMENT") &&
      Js.String2.includes(c, "WHY:")
    if !declared {
      problem(
        record.jobId,
        "the shot code \"" ++
        record.shots ++
        "\" contains no SH number, so every script-derived check silently skipped: the line check, the recording check and the duration check all passed because they had nothing to look at. Either give this job its real SH numbers, or put a NON-SCRIPT ELEMENT block in the creative with a WHY: line saying what it is and why the script does not cover it.",
      )
    }
  }
}

/* GATE 2 — A LINE THAT HAS NOT BEEN RECORDED CANNOT BE SHOT.

   The Точка clip was generated before «Точка» had ever been recorded. I had
   said three times in the same session that the recording did not exist, and
   then submitted the shot anyway. The gate below reads every «…» line in the
   creative and refuses if the line index has no recording for it. */
let assertQuotedLinesRecorded = (record, problem): unit => {
  let c = record.creative
  /* Only the text BETWEEN a « and the NEXT », never past it. Splitting on the
     characters instead grabbed the whole rest of the file as one "line". */
  let quoted = {
    let out = []
    let re = %re("/«([^»]{2,140})»/g")
    let rec loop = () =>
      switch Js.Re.exec_(re, c) {
      | Some(m) =>
        switch Belt.Array.get(Js.Re.captures(m), 1)->Belt.Option.flatMap(x => Js.Nullable.toOption(x)) {
        | Some(t) =>
          let tt = Js.String2.trim(t)
          if Js.String2.length(tt) > 2 && Js.Re.test_(%re("/[\u0400-\u04FF]/"), tt) {
            out->Js.Array2.push(tt)->ignore
          }
        | None => ()
        }
        loop()
      | None => ()
      }
    loop()
    out
  }
  if Belt.Array.length(quoted) > 0 {
    let index = loadLineIndex()
    if Belt.Array.length(index) > 0 {
      let missing =
        quoted->Belt.Array.keep(l => Belt.Option.isNone(findRecording(index, l)))
      if Belt.Array.length(missing) > 0 {
        problem(
          record.jobId,
          "the choreography quotes " ++
          Js.Array2.joinWith(missing->Belt.Array.map(m => "«" ++ Js.String2.trim(m) ++ "»"), ", ") ++
          " and there is no recording of it in the line index. Record it first. A shot built around a line nobody has said yet is a shot built on a guess about its length and its reading.",
        )
      }
    }
  }
}

/* GATE 3 — A SHOT THAT LIVES ON A FACE NEEDS A MODEL THAT TAKES REFERENCES.

   Kling accepts no reference images. Given a creative with three paragraphs of
   facial direction it returned a mannequin, twice, and the second time I had
   already been told the first one was blank. Every expressive shot this show
   has ever cut ran with the character sheets bound; Kling structurally cannot
   do that. It can hold a loop or it can act, not both. */
let assertFaceWorkHasReferences = (spec: Drakosha_SeedanceJobs.jobSpec, refCount: int, problem): unit => {
  let c = spec.record.creative
  let wantsFace =
    Js.String2.includes(c, "\nFACES") ||
    Js.String2.includes(c, "\nREACTIONS")
  let maxRefs = Drakosha_SeedanceJobs.modelMaxRefs(spec.model)
  if wantsFace && maxRefs == 0 && refCount == 0 {
    problem(
      spec.record.jobId,
      "asks for a performance (it has a FACES block) on " ++
      Drakosha_SeedanceJobs.modelName(spec.model) ++
      ", which takes no reference images at all. On 2026-08-20 this produced a blank-faced child twice. Expression on this show comes from the bound character sheets; move the job to a Seedance model, which takes a start frame, an end frame AND references together.",
    )
  }
}

/* GATE 4 — A START FRAME MUST NOT BE AN UPSCALED CROP.

   The Точка start frame was a 640x360 region of a 1280x720 plate blown back up
   to 1280x720. The model got a soft picture, reinvented what it could not read,
   and gave the pencil a metal ferrule it has never had and the child a face
   that is not hers. A frame that claims a resolution it does not have is a lie
   the model believes.

   Provenance lives beside the frame as `<name>.provenance.json` with a
   `native` flag. No sidecar and no gate; a sidecar saying otherwise fails. */
let assertStartFrameNative = (record, problem): unit =>
  switch record.startImage {
  | None => ()
  | Some(k) =>
    let prov = "../stories/drakosha/rnd/keyframes/" ++ k ++ ".provenance.json"
    if existsSync(prov) {
      let txt = readFileSync(prov, "utf8")
      if Js.String2.includes(txt, "\"native\": false") || Js.String2.includes(txt, "\"upscaled\": true") {
        problem(
          record.jobId,
          "start frame " ++
          k ++
          " is recorded as an upscaled crop. Feeding the model a frame with fewer real pixels than it claims is how the pencil grew a metal band and the child stopped looking like herself. Re-cut the frame at native resolution, or shoot the wider framing and crop the OUTPUT instead.",
        )
      }
    }
  }

let fail = ref(false)
let problem = (jobId: string, msg: string): unit => {
  fail := true
  Js.log("  FAIL  " ++ jobId ++ ": " ++ msg)
}

let () = {
  mkdirSync(outDir, {recursive: true})
  let manifestLines = []
  Drakosha_SeedanceJobs.all->Belt.Array.forEach(spec => {
    let jobId = spec.record.jobId
    /* load choreography */
    let creative = if existsSync(spec.creativeFile) {
      readFileSync(spec.creativeFile, "utf8")
    } else {
      problem(jobId, "missing creative file " ++ spec.creativeFile)
      ""
    }
    let record = {...spec.record, creative}
    /* Higgsfield offered 5/8/12 and nothing else. Krea's Seedance 2.5 takes any
       integer 4..30, which is what lets a whole exchange run in one generation
       instead of being cut into clips that then have to be matched to each
       other. Keep the floor and ceiling; drop the three fixed rungs. */
    /* This floor is a Seedance floor and was written when Seedance was the only
       provider. Kling generates from 3s, and a loop element — one letter at a
       child's writing pace — is three seconds. Padding it to four to satisfy a
       rule about dialogue shots would make the writing look slow. */
    let floorSec = switch spec.model {
    | Kling26 | Kling30 => 3
    | Mini | V20 | V25 | Veo31Lite => 4
    }
    if record.durationSec < floorSec || record.durationSec > 30 {
      problem(
        jobId,
        "invalid duration — " ++
        Drakosha_SeedanceJobs.modelName(spec.model) ++
        " takes " ++
        Belt.Int.toString(floorSec) ++
        " to 30 seconds",
      )
    }
    /* emit (raises on smuggled tags) */
    switch try Some(emitPrompt(record)) catch {
    | BatchError(m) =>
      problem(jobId, m)
      None
    } {
    | None => ()
    | Some(prompt) =>
      if existsSync(shootingScript) {
        let sc = readFileSync(shootingScript, "utf8")
        assertScriptLinesPresent(record, sc, problem)
        assertDurationHoldsAudio(record, sc, problem)
        assertStartFrameSameLocation(
          record,
          sc,
          Belt.Array.concat(
            Drakosha_SeedanceJobs.all->Belt.Array.map(s => s.record),
            Belt.Array.concat(Drakosha_SeedanceJobs.retired, Drakosha_SeedanceJobs.retiredBatch),
          ),
          problem,
        )
      }
      assertStartFrameBacked(record, problem)
      assertReactionsWritten(record, problem)
      assertEmotionsDeclared(record, problem)
      assertHandsWritten(record, problem)
      assertBackgroundsAssigned(record, problem)
      assertGlyphsPlanned(record, problem)
      assertShotCodeResolves(record, problem)
      assertQuotedLinesRecorded(record, problem)
      assertStartFrameNative(record, problem)
      let refPaths = emitRefPaths(record)->Belt.Array.map(resolveRef)
      assertNamedFeaturesAreBacked(record, refPaths, problem)
      refPaths->Belt.Array.forEach(p =>
        if !existsSync(p) {
          problem(jobId, "missing reference " ++ p)
        }
      )
      assertSetImageBacked(record, refPaths, problem)
      let start = switch record.startImage {
      | Some(k) =>
        let p = resolveRef(Js.String2.includes(k, ":") ? k : "KF:" ++ k)
        if !existsSync(p) {
          problem(jobId, "missing start image " ++ p)
        }
        p
      | None => ""
      }
      writeFileSync(outDir ++ "/" ++ jobId ++ ".prompt.txt", prompt)
      let args = {
        let d = Js.Dict.empty()
        Js.Dict.set(d, "model", Js.Json.string(Drakosha_SeedanceJobs.modelName(spec.model)))
        Js.Dict.set(d, "duration", Js.Json.number(Belt.Int.toFloat(record.durationSec)))
        Js.Dict.set(d, "startImage", Js.Json.string(start))
        /* The end frame was missing from this artifact until 2026-08-24, so a job
           pinned at both ends looked, in review, exactly like one pinned at the
           start. The emitted args are what gets read before a submission is
           approved; anything the gate will actually send has to appear here or
           the review is of a different job. */
        switch spec.endImage {
        | Some(e) => Js.Dict.set(d, "endImage", Js.Json.string(kfDir ++ "/" ++ e))
        | None => ()
        }
        Js.Dict.set(d, "imageReferences", Js.Json.array(refPaths->Belt.Array.map(Js.Json.string)))
        Js.Dict.set(d, "promptSha256", Js.Json.string(sha256(prompt)))
        Js.Json.object_(d)
      }
      writeFileSync(outDir ++ "/" ++ jobId ++ ".args.json", Js.Json.stringifyWithSpace(args, 2))
      let castCount = Belt.Array.length(record.cast)
      let refCount = Belt.Array.length(refPaths)
      assertModelFits(spec, refCount, problem)
      assertFaceWorkHasReferences(spec, refCount, problem)
      assertTagLinesAreIdentityOnly(record, problem)
      let credits =
        Drakosha_SeedanceJobs.modelCreditsPerSec(spec.model) *.
        Belt.Int.toFloat(record.durationSec)
      creditTotal := creditTotal.contents +. credits
      manifestLines
      ->Js.Array2.push(
        jobId ++
        "  " ++
        record.shots ++
        "  cast=" ++
        Belt.Int.toString(castCount) ++
        "  refs=" ++
        Belt.Int.toString(refCount) ++
        "  start=" ++ (start == "" ? "none" : "yes") ++
        "  model=" ++ Drakosha_SeedanceJobs.modelName(spec.model) ++
        "  cr=" ++ Js.Float.toFixedWithPrecision(credits, ~digits=1) ++
        "  sha=" ++
        Js.String2.slice(sha256(prompt), ~from=0, ~to_=12),
      )
      ->ignore
      Js.log(
        "  OK    " ++
        jobId ++
        "  " ++
        record.shots ++
        "  cast " ++
        Belt.Int.toString(castCount) ++
        ", refs " ++
        Belt.Int.toString(refCount) ++ (start == "" ? ", text+refs only" : ", start-image"),
      )
    }
  })
  let ledger =
    "TOTAL " ++
    Js.Float.toFixedWithPrecision(creditTotal.contents, ~digits=1) ++
    " credits (~$" ++
    Js.Float.toFixedWithPrecision(creditTotal.contents *. 0.043, ~digits=2) ++
    " at the Ultra rate) for this batch."
  writeFileSync(
    outDir ++ "/BATCH_MANIFEST.txt",
    manifestLines->Js.Array2.joinWith("\n") ++ "\n" ++ ledger ++ "\n",
  )
  Js.log("  " ++ ledger)
  if fail.contents {
    Js.log("DRY RUN: FAIL — fix the rows above; nothing may be submitted.")
    %raw(`process.exit(1)`)->ignore
  } else {
    Js.log("DRY RUN: PASS — emitted artifacts in " ++ outDir ++ " for review.")
  }
}
