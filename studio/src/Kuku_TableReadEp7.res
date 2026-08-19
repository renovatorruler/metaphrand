/* कुकु और अक्षर — EP7 TABLE READ (audio only).

   Stitches the recorded takes into one listenable pass of the episode, in script
   order — and, like a real table read, a narrator (सूत्रधार) reads what is not
   dialogue: each scene heading and every (ध्वनि: …) cue, at the spot where the
   cue sits in the script. Dialogue expression is already IN the takes (the Hindi
   parentheticals became v3 audio tags at record time via TAG_MAP).

   The narrator is a TABLE-READ voice, not series canon: Kuber (hi, storyteller).
   Locking a canonical सूत्रधार voice is the author's call, not this file's.
   Narration is levelled to -20 LUFS — the event tier, a step under dialogue's
   -17 — so the cast stays foreground (PRODUCTION_LESSONS #4's ladder).

   Narration takes live in ep7prod/tableread/, NOT takes/ — takes/ is production
   ground truth and the preflight gate reads it; a table-read asset must never
   make an episode look more (or less) recorded than it is.

   Re-runs are free: narration is keyed on its text via .said sidecars (lesson
   18), and the voice engine is only called for missing or changed lines.

   Run from studio/:
     node src/Kuku_TableReadEp7.res.mjs */

open Cinema_Backends

exception TableRead(string)

let dir = "../stories/kuku/ep7prod"
let screenplay = "../stories/kuku/2026-07-31_EP7_aa_matra_screenplay.md"

/* table-read narrator: Kuber — Hindi storybook narrator */
let narratorVoice = "sZk20flPPGUa0sDxsZ8t"
let narratorTag = "[softly] "

/* तानसेन's takes, in PERFORMANCE order per cue. The filesystem cannot carry this
   ordering (mimic_65_* sorts alphabetically, which would shuffle का-ना-मा-ता-रा),
   so it is declared here, matching extraMimicsFor in Kuku_Voices. */
let mimicsAfter = (idx: int): array<string> =>
  switch idx {
  | 6 => ["mimic_06_PAPA.mp3"]
  | 65 => [
      "mimic_65_KUKU.mp3",
      "mimic_65_FYURIA.mp3",
      "mimic_65_VESPER.mp3",
      "mimic_65_MITASUR.mp3",
      "mimic_65_CASTOR.mp3",
    ]
  | 95 => ["mimic_95_PAPA.mp3", "mimic_95_LEDA.mp3"]
  | _ => []
  }

/* A mimicry cue's quoted tail is PERFORMED by the parrot takes right after it —
   the narrator reads only the set-up («तानसेन — हूबहू पापा की आवाज़») or the echo
   would play twice, once described and once heard. */
let stripPerformedQuote = (idx: int, cue: string): string =>
  if Belt.Array.length(mimicsAfter(idx)) > 0 && Js.String2.includes(cue, ":") {
    Js.String2.trim(
      Js.String2.slice(cue, ~from=0, ~to_=Js.String2.indexOf(cue, ":")),
    )
  } else {
    cue
  }

let fld = (j, k) => j->Js.Json.decodeObject->Belt.Option.flatMap(o => Js.Dict.get(o, k))
let asStr = o => o->Belt.Option.flatMap(Js.Json.decodeString)->Belt.Option.getWithDefault("")
let asNum = o => o->Belt.Option.flatMap(Js.Json.decodeNumber)->Belt.Option.getWithDefault(0.0)

let pad2 = (i: int) => i < 10 ? "0" ++ Belt.Int.toString(i) : Belt.Int.toString(i)

/* «दृश्य N — …» heading lines, by scene number, read from the screenplay itself
   (the manifest keeps only the number; the narrator wants the words). */
let sceneHeadings = (): Js.Dict.t<string> => {
  let out = Js.Dict.empty()
  readText(Path(screenplay))
  ->Js.String2.split("\n")
  ->Belt.Array.forEach(line => {
    let t = Js.String2.trim(line)
    if Js.String2.startsWith(t, "दृश्य") {
      let digits = Js.Array2.joinWith(
        Js.String2.split(t, "")->Belt.Array.keep(c => c >= "0" && c <= "9"),
        "",
      )
      if digits != "" {
        Js.Dict.set(out, digits, t)
      }
    }
  })
  out
}

/* one narration take: skip when present with the same text (content key) */
let narrate = async (~file: string, ~text: string, ~made: ref<int>, ~skipped: ref<int>): path => {
  let p = Path(dir ++ "/tableread/" ++ file)
  let said = Path(dir ++ "/tableread/." ++ file ++ ".said")
  let full = narratorTag ++ text
  if exists(p) && exists(said) && readText(said) == full {
    skipped := skipped.contents + 1
    p
  } else {
    let blob = await tts(~text=Text(full), ~voice=VoiceId(narratorVoice))
    let _ = writeBytes(p, blob)
    /* level to -20 LUFS (event tier), in place, BEFORE the sidecar lands — a
       crash between the two must re-buy the take, never ship it unlevelled */
    let tmp = dir ++ "/tableread/." ++ file ++ ".tmp.mp3"
    ffmpeg([
      "-nostdin", "-loglevel", "error", "-y",
      "-i", dir ++ "/tableread/" ++ file,
      "-af", "loudnorm=I=-20:TP=-1.5:LRA=11",
      "-c:a", "libmp3lame", "-q:a", "3", tmp,
    ])
    copyFile(Path(tmp), p)
    removeFile(Path(tmp))
    writeText(said, full)
    made := made.contents + 1
    p
  }
}

let main = async () => {
  let mj = Js.Json.parseExn(readText(Path(dir ++ "/ep7_manifest.json")))
  let events =
    fld(mj, "events")
    ->Belt.Option.flatMap(Js.Json.decodeArray)
    ->Belt.Option.getWithDefault([])
    ->Belt.Array.map(e => (
      fld(e, "idx")->asNum->Belt.Float.toInt,
      fld(e, "scene")->asNum->Belt.Float.toInt,
      fld(e, "who")->asStr,
    ))
    ->Belt.Array.keep(((_, _, who)) => !Js.String2.endsWith(who, "_SFX"))
  let cues =
    fld(mj, "sfx")
    ->Belt.Option.flatMap(Js.Json.decodeArray)
    ->Belt.Option.getWithDefault([])
    ->Belt.Array.map(c => (
      fld(c, "scene")->asNum->Belt.Float.toInt,
      fld(c, "after")->asNum->Belt.Float.toInt,
      fld(c, "cue")->asStr,
    ))
  let headings = sceneHeadings()

  ensureDirPath(Path(dir ++ "/tableread"))
  let made = ref(0)
  let skipped = ref(0)

  /* record narration first — headings, then cues, in script order */
  let headingTake = Js.Dict.empty()
  for s in 1 to 8 {
    let key = Belt.Int.toString(s)
    switch Js.Dict.get(headings, key) {
    | Some(h) => {
        let p = await narrate(~file="scene_" ++ pad2(s) ++ ".mp3", ~text=h, ~made, ~skipped)
        Js.Dict.set(headingTake, key, p)
      }
    | None => raise(TableRead("no दृश्य heading found for scene " ++ key))
    }
  }
  let cueTake: Js.Dict.t<path> = Js.Dict.empty()
  for i in 0 to Belt.Array.length(cues) - 1 {
    switch Belt.Array.get(cues, i) {
    | Some((_, after, cue)) => {
        let p = await narrate(
          ~file="cue_" ++ pad2(i) ++ ".mp3",
          ~text=stripPerformedQuote(after, cue),
          ~made,
          ~skipped,
        )
        Js.Dict.set(cueTake, Belt.Int.toString(i), p)
      }
    | None => ()
    }
  }
  Js.log(
    "narration: " ++
    Belt.Int.toString(made.contents) ++
    " recorded, " ++
    Belt.Int.toString(skipped.contents) ++ " reused",
  )

  let cache = dir ++ "/build"
  let lineGap = silence(Millis(350), Path(cache))
  let sceneGap = silence(Millis(1200), Path(cache))
  let echoGap = silence(Millis(250), Path(cache))

  /* every dialogue file must exist before any ffmpeg work starts */
  let missing: array<string> = []
  let need = (f: string): path => {
    let p = Path(dir ++ "/takes/" ++ f)
    if !exists(p) {
      let _ = Js.Array2.push(missing, f)
    }
    p
  }

  let parts: array<path> = []
  let push = (p: path) => {
    let _ = Js.Array2.push(parts, p)
  }
  let cueAt = (afterIdx: int, scene: int) =>
    cues->Belt.Array.forEachWithIndex((i, (cScene, cAfter, _)) =>
      if cScene == scene && cAfter == afterIdx {
        switch Js.Dict.get(cueTake, Belt.Int.toString(i)) {
        | Some(p) => {
            push(lineGap)
            push(p)
          }
        | None => ()
        }
      }
    )

  let lastScene = ref(0)
  events->Belt.Array.forEach(((idx, scene, _)) => {
    if scene != lastScene.contents {
      if lastScene.contents != 0 {
        push(sceneGap)
      }
      switch Js.Dict.get(headingTake, Belt.Int.toString(scene)) {
      | Some(h) => {
          push(h)
          push(lineGap)
        }
      | None => ()
      }
      cueAt(0, scene) /* scene-top cues, e.g. ambience descriptions */
      lastScene := scene
    } else {
      push(lineGap)
    }
    push(need(pad2(idx) ++ ".mp3"))
    /* cue narration first — «तानसेन — हूबहू पापा की आवाज़» sets up the echo,
       THEN the parrot performs it */
    cueAt(idx, scene)
    mimicsAfter(idx)->Belt.Array.forEach(m => {
      push(echoGap)
      push(need(m))
    })
  })

  if Belt.Array.length(missing) > 0 {
    raise(
      TableRead(
        Belt.Int.toString(Belt.Array.length(missing)) ++
        " takes missing — record them first (Kuku_Voices): " ++
        Js.Array2.joinWith(Belt.Array.slice(missing, ~offset=0, ~len=10), ", "),
      ),
    )
  }

  let out = concatAudio(parts, Path(dir ++ "/EP7_TABLE_READ.mp3"))
  let Seconds(len) = durationSec(out)
  let Path(o) = out
  Js.log(
    "table read: " ++
    Belt.Int.toString(Belt.Array.length(events)) ++
    " lines + " ++
    Belt.Int.toString(Belt.Array.length(cues)) ++
    " narrated cues + 8 headings -> " ++
    o ++
    "  (" ++
    Js.Float.toFixedWithPrecision(len /. 60.0, ~digits=1) ++
    " min)",
  )
}

main()->ignore
