/* कुकु और अक्षर — EP9 story-logic delta v1 (approved by the parent 2026-08-19).

   Three recorded lines are superseded and two new lines added so the story's causal rules
   hold: the gate is stuck half-open and DRAFTS like an open door (mechanism), only Kuku's
   letter can fill it because what he forges cannot be unmade (canon), and the goat kid is
   bonded to the children and naps on the low cloud before that cloud is taken (stakes).
   Source of truth already updated: SPEC_SCREENPLAY + BEATSHEET carry the same words.

   The five lines ride the manual-review candidate path (the finale's existing exception
   mechanism), voiced by the locked cast at the same -17 LUFS as every other cast line.
   Orders 95 and 96 are free in the finale audio set — in the table-read plan they are
   narrator rows, and the finale dropped the narrator.

   Run from studio/:
     node src/Kuku_Ep9StoryDelta.res.mjs             audio + manifests
     node src/Kuku_Ep9StoryDelta.res.mjs shotnumbers regenerate simple shot numbers from v4
   (run the first mode, then the retimer, then shotnumbers) */

open Cinema_Backends

@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external exitProcess: int => unit = "exit"

exception DeltaError(string)
let fail = m => raise(DeltaError(m))

let finale = "../stories/kuku/ep9prod/finale"
let reviewDir = finale ++ "/audio/manual_review"
let manualPath =
  finale ++ "/audio/EP9_DIALOGUE_MANUAL_REVIEW_kuku-ep9-finale-dialogue-v5-candidate-content-bound.json"
let anchorsPath = finale ++ "/manifests/ep9_dialogue_beat_anchors.v2.json"

type line = {order: int, scene: int, speaker: string, text: string, anchor: string}

/* the approved delta, verbatim from EP9_STORY_LOGIC_DELTA_v1.md */
let lines: array<line> = [
  {
    order: 95,
    scene: 2,
    speaker: "CASTOR",
    text: "देखो! बकरी का बच्चा भी अभ्यास कर रहा है!",
    anchor: "S02-B04-L2",
  },
  {
    order: 96,
    scene: 2,
    speaker: "VESPER",
    text: "बकरी का बच्चा फिर अपने बादल पर सो गया।",
    anchor: "S02-B04-L3",
  },
  {
    order: 105,
    scene: 3,
    speaker: "RISHI",
    text: "कल चील ने तुम्हारा अक्षर-पुल तोड़ा। उसकी गूँज मेरे गुरुकुल तक पहुँची — और द्वार का घिसा हुआ हिस्सा गिर पड़ा। अब द्वार अधखुला अटका है, और अधखुला द्वार हवा खींचता है — जैसे खुला दरवाज़ा।",
    anchor: "",
  },
  {
    order: 106,
    scene: 3,
    speaker: "RISHI",
    text: "यही गुरुकुल का रास्ता है। मेरी छड़ी इसे थोड़ी देर थाम लेगी — पर पत्थर एक बार टूटा है, फिर टूटेगा। छड़ियाँ झुक जाती हैं। कुकु की साँस से बना अक्षर कभी नहीं टूटता। द्वार की खाली जगह उसे ही चाहिए — हमेशा के लिए।",
    anchor: "",
  },
  {
    order: 202,
    scene: 6,
    speaker: "LEDA",
    text: "बादल पानी की तरह घूमता हुआ ऊपर जा रहा है — हर चक्कर द्वार के और पास। तीन चक्कर में पहुँच जाएगा। पहला शुरू हो चुका है।",
    anchor: "",
  },
  /* review round 2 (2026-08-19): the staff-rhythm instruction was incomprehensible without
     its mechanism ("chari ki taal dekho... there's no way kids would understand"), and the
     stroke-anatomy narration was noise ("just say this is ba and display it") */
  {
    order: 115,
    scene: 3,
    speaker: "RISHI",
    text: "खिंचती हवा झोंकों में आती है — हर झोंके पर मेरी छड़ी काँपती है। झूले की तरह ताल पकड़ो: पहले खाली पंखों से एक चक्कर, फिर इसी ताल में अक्षर उठाकर द्वार में लगाओ।",
    anchor: "",
  },
  {
    order: 148,
    scene: 4,
    speaker: "DADI",
    text: "यह ब है।",
    anchor: "",
  },
]

/* same loudness treatment as every table-read cast line (Kuku_TableReadEp9.normalize) */
let normalize = (~src: path, ~out: path, ~lufs: int): path => {
  let Path(s) = src
  let Path(o) = out
  ffmpeg([
    "-nostdin", "-loglevel", "error", "-y", "-i", s,
    "-af", "loudnorm=I=" ++ Belt.Int.toString(lufs) ++ ":TP=-1.5:LRA=11",
    "-c:a", "libmp3lame", "-q:a", "3", o,
  ])
  out
}

let voiceFor = (speaker: string): string =>
  switch Kuku_Cast.voiceOf(speaker) {
  | Some(v) => v
  | None => fail("no locked voice for " ++ speaker)
  }

let json = path =>
  switch Js.Json.parseExn(readText(Path(path))) {
  | j => j
  | exception _ => fail("unparseable json: " ++ path)
  }
let obj = (j, w) =>
  switch Js.Json.decodeObject(j) {
  | Some(o) => o
  | None => fail(w ++ " is not an object")
  }

let renderLines = async () => {
  ensureDirPath(Path(reviewDir))
  let rendered: array<(line, string, float)> = []
  for i in 0 to Belt.Array.length(lines) - 1 {
    switch Belt.Array.get(lines, i) {
    | None => ()
    | Some(l) => {
        let voice = voiceFor(l.speaker)
        let sig_ = voice ++ "|" ++ l.text ++ "::eleven_v3::tts::ep9-story-delta-v1"
        let name = "delta_" ++ Belt.Int.toString(l.order) ++ "_" ++ sha256Text(sig_) ++ ".mp3"
        let out = Path(reviewDir ++ "/" ++ name)
        if exists(out) && fileSizeMb(out) *. 1.0e6 > 2000.0 {
          Js.log("  cached " ++ Belt.Int.toString(l.order) ++ " " ++ l.speaker)
        } else {
          let raw = Path(reviewDir ++ "/." ++ name ++ ".raw.mp3")
          let blob = await tts(~text=Text(l.text), ~voice=VoiceId(voice))
          let _ = writeBytes(raw, blob)
          /* -17 LUFS: the level every cast line in the guide already sits at */
          let _ = normalize(~src=raw, ~out, ~lufs=-17)
          removeFile(raw)
          Js.log("  tts OK " ++ Belt.Int.toString(l.order) ++ " " ++ l.speaker)
        }
        let Seconds(d) = probeDuration(out)
        Js.Array2.push(rendered, (l, name, d))->ignore
      }
    }
  }
  rendered
}

let updateManual = (rendered: array<(line, string, float)>) => {
  let root = obj(json(manualPath), "manual review")
  let ours = lines->Belt.Array.map(l => l.order)
  let kept = switch Js.Dict.get(root, "exceptions") {
  | Some(v) =>
    switch Js.Json.decodeArray(v) {
    | Some(rows) =>
      rows->Belt.Array.keep(r =>
        switch Js.Json.decodeObject(r) {
        | Some(o) =>
          switch Js.Dict.get(o, "order")->Belt.Option.flatMap(Js.Json.decodeNumber) {
          | Some(n) => !(ours->Js.Array2.includes(Belt.Float.toInt(n)))
          | None => true
          }
        | None => true
        }
      )
    | None => fail("manual.exceptions is not an array")
    }
  | None => fail("manual has no exceptions")
  }
  let added = rendered->Belt.Array.map(((l, name, d)) => {
    let e = Js.Dict.empty()
    Js.Dict.set(e, "order", Js.Json.number(Belt.Int.toFloat(l.order)))
    Js.Dict.set(e, "scene", Js.Json.number(Belt.Int.toFloat(l.scene)))
    Js.Dict.set(e, "speaker", Js.Json.string(l.speaker))
    Js.Dict.set(e, "text", Js.Json.string(l.text))
    Js.Dict.set(e, "reason", Js.Json.string(
      "story-logic delta v1 (parent-approved 2026-08-19): supersedes the derived line; " ++
      "text now carries the draft mechanism / Kuku-permanence rule / goat bond",
    ))
    Js.Dict.set(e, "candidate", Js.Json.string(
      "../stories/kuku/ep9prod/finale/audio/manual_review/" ++ name,
    ))
    Js.Dict.set(e, "candidate_duration_seconds", Js.Json.number(d))
    Js.Json.object_(e)
  })
  let all = Belt.Array.concat(kept, added)
  Js.Dict.set(root, "exceptions", Js.Json.array(all))
  Js.Dict.set(root, "exception_count", Js.Json.number(Belt.Int.toFloat(Belt.Array.length(all))))
  writeText(Path(manualPath), Js.Json.stringifyWithSpace(Js.Json.object_(root), 1))
  Js.log("manual review carries " ++ Belt.Int.toString(Belt.Array.length(all)) ++ " exceptions")
}

let updateAnchors = () => {
  let root = obj(json(anchorsPath), "anchors")
  let anchors = switch Js.Dict.get(root, "anchors")->Belt.Option.flatMap(Js.Json.decodeObject) {
  | Some(a) => a
  | None => fail("anchors.anchors missing")
  }
  lines->Belt.Array.forEach(l =>
    if l.anchor != "" {
      Js.Dict.set(anchors, Belt.Int.toString(l.order), Js.Json.string(l.anchor))
    }
  )
  writeText(Path(anchorsPath), Js.Json.stringifyWithSpace(Js.Json.object_(root), 1))
  Js.log("anchors updated for new orders 95, 96")
}

/* S<n> is simply the 1-based beat position in the v4 EDL — the same rule the review
   render's corner chips use, so the manifest and the picture can never disagree. */
let writeShotNumbers = () => {
  let edl = obj(json(finale ++ "/manifests/ep9_finale_animatic_edl.v4.json"), "edl v4")
  let beats = switch Js.Dict.get(edl, "beats")->Belt.Option.flatMap(Js.Json.decodeArray) {
  | Some(b) => b
  | None => fail("v4 has no beats")
  }
  let out = Js.Dict.empty()
  beats->Belt.Array.forEachWithIndex((i, bj) => {
    let b = obj(bj, "beat")
    let row = Js.Dict.empty()
    let getS = k =>
      switch Js.Dict.get(b, k)->Belt.Option.flatMap(Js.Json.decodeString) {
      | Some(v) => v
      | None => fail("beat missing " ++ k)
      }
    Js.Dict.set(row, "beat", Js.Json.string(getS("id")))
    Js.Dict.set(row, "start", Js.Json.string(getS("start")))
    Js.Dict.set(row, "end", Js.Json.string(getS("end")))
    Js.Dict.set(out, "S" ++ Belt.Int.toString(i + 1), Js.Json.object_(row))
  })
  writeText(
    Path(finale ++ "/manifests/ep9_simple_shot_numbers.v3.json"),
    Js.Json.stringifyWithSpace(Js.Json.object_(out), 1),
  )
  Js.log("shot numbers v3: " ++ Belt.Int.toString(Belt.Array.length(beats)) ++ " shots")
}

let main = async () => {
  if argv->Js.Array2.includes("shotnumbers") {
    writeShotNumbers()
  } else {
    let rendered = await renderLines()
    updateManual(rendered)
    updateAnchors()
    rendered->Belt.Array.forEach(((l, _, d)) =>
      Js.log(
        "  " ++ Belt.Int.toString(l.order) ++ " " ++ l.speaker ++ " " ++
        Js.Float.toFixedWithPrecision(d, ~digits=2) ++ "s",
      )
    )
  }
}

main()
->Js.Promise2.catch(e => {
  Js.log2("STORY DELTA FAILED:", e)
  exitProcess(1)
  Js.Promise.resolve()
})
->ignore
