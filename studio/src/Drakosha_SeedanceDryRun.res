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
        ->Belt.Array.keepMap(castRuName)
        ->Belt.Array.keep(n => !Js.String2.includes(block, n))
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
      ->Belt.Array.keepMap(castRuName)
      ->Belt.Array.keep(n => !Js.String2.includes(block, n))
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
   shows no wall, which is a decision rather than an omission. */
let namedWalls = [
  "hatch wall", "hatch-wall", "ramp", "railing", "back wall", "kitchen end",
  "niche", "table end", "boulder-block wall", "no wall", "shows no wall",
]

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
      ->Belt.Array.keepMap(castRuName)
      ->Belt.Array.keep(n => !Js.String2.includes(blockLower, Js.String2.toLowerCase(n)))
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
    if Belt.Array.length(walls) == 0 {
      problem(
        record.jobId,
        "the BACKGROUNDS block names no wall of the hall. \"Soft and out of focus\" describes the lens, not the room. Name the hatch wall, the ramp and its railing, the back wall with the niche, or the table end — or say the framing shows no wall.",
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
    if record.durationSec < 4 || record.durationSec > 30 {
      problem(jobId, "invalid duration — Seedance 2.5 takes 4 to 30 seconds")
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
      assertHandsWritten(record, problem)
      assertBackgroundsAssigned(record, problem)
      let refPaths = emitRefPaths(record)->Belt.Array.map(resolveRef)
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
        Js.Dict.set(d, "imageReferences", Js.Json.array(refPaths->Belt.Array.map(Js.Json.string)))
        Js.Dict.set(d, "promptSha256", Js.Json.string(sha256(prompt)))
        Js.Json.object_(d)
      }
      writeFileSync(outDir ++ "/" ++ jobId ++ ".args.json", Js.Json.stringifyWithSpace(args, 2))
      let castCount = Belt.Array.length(record.cast)
      let refCount = Belt.Array.length(refPaths)
      assertModelFits(spec, refCount, problem)
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
