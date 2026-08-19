/* कुकु और अक्षर — cast recording.

   Reads a manifest, converts each Hindi performance parenthetical to the voice
   engine's bracketed tag via the author's TAG_MAP contract, renders one take per
   spoken line, loudness-normalises it, and writes the durations the assembler
   needs.

   Two things this handles that a straight per-speaker loop cannot:

   1. CHORUS lines are rendered once per member and mixed, so «सब» is actually
      several children rather than one child pretending.
   2. MIMICRY. Ep6 introduced तानसेन, a parrot who repeats a line **in the voice of
      whoever said it**. Those lines live in the sound-cue list, not the dialogue
      list, but they are not sound effects — each is a TTS take using the MIMICKED
      character's locked voice id. A generator keyed on the speaker label would
      either skip them or give the parrot a voice of his own, and both are wrong.

   Money: every take is skipped if it already exists and is non-trivial in size, so
   a re-run costs nothing. DRY=1 prices the run without spending.

   Run from studio/:
     node src/Kuku_Voices.res.mjs <episode-dir> <manifest.json> <durs.json> */

open Cinema_Backends

@val @scope("process") external argv: array<string> = "argv"
@val @scope(("process", "env")) external envDry: option<string> = "DRY"

exception Failed(string)

/* Locked identities live in one registry so production and table reads cannot
   silently recast the same character. */
let voiceOf = Kuku_Cast.voiceOf
let mimicVoiceKey = Kuku_Cast.mimicVoiceKey

let pad2 = (i: int) => i < 10 ? "0" ++ Belt.Int.toString(i) : Belt.Int.toString(i)

/* THE PARROT'S VOICE. तानसेन's takes are generated with the MIMICKED character's
   voice, which is literally what a parrot does — but played back unaltered it just
   sounds like that character speaking again, and the echo does not read as a bird.
   Lifting the pitch makes it audibly an impression.

   1.15 is deliberate and the ceiling is the plot: मिटासुर has to RECOGNISE फ्यूरिया's
   voice at his door, and फ्यूरिया has to recognise her own words. Push much past
   this and the identity blurs, which breaks the story rather than flavouring it.

   asetrate raises pitch and speed together; atempo pulls the speed back so the take
   keeps its length — durations feed segment lengths in the EDL, so they must hold. */
let parrotPitch = 1.15

/* Mimicry the automatic parser cannot see, because the cue does not say «हूबहू».
   Both of these are story payoffs, so they are declared rather than inferred:

   * the cruel sentence finally getting overwritten — तानसेन says «शाबाश» in the
     voice of the girl who said the unkind thing
   * the closing, where he returns each child's own gift in that child's own voice:
     धन्यवाद was वैस्पर's word, शाबाश was फ्यूरिया's, साथी was कुकु's

   `after` is the dialogue index the cue follows; it must match the manifest.

   PER-EPISODE, because these are story payoffs, i.e. DATA. The first version was
   one flat list, which meant an Ep7 run would have re-bought Ep6's four takes at
   Ep7 indices they do not belong to (132 > Ep7's own 115 lines). Keyed on the
   episode directory so the wrong show cannot be declared into an episode.

   File names are mimic_<after>_<voice>.mp3 — within one cue, a voice may appear
   at most ONCE, or the second take overwrites the first and is paid for twice. */
let extraMimicsFor = (dir: string): array<(int, string, string)> =>
  if Js.String2.includes(dir, "ep6prod") {
    [
      (114, "FYURIA", "…शाबाश। शाबाश!"),
      (132, "VESPER", "धन्यवाद…"),
      (132, "FYURIA", "शाबाश…"),
      (132, "KUKU", "साथी…"),
    ]
  } else if Js.String2.includes(dir, "ep7prod") {
    [
      /* after 65: «बारी-बारी बच्चों की आवाज़ में: का! ना! मा! ता! रा!» — the parrot
         returns the five new matra syllables, one child's voice each. */
      (65, "KUKU", "का!"),
      (65, "FYURIA", "ना!"),
      (65, "VESPER", "मा!"),
      (65, "MITASUR", "ता!"),
      (65, "CASTOR", "रा!"),
      /* after 95: «बारी-बारी सबकी आवाज़ में: बधाई! बधाई!» — two turns of the round. */
      (95, "PAPA", "बधाई!"),
      (95, "LEDA", "बधाई!"),
    ]
  } else if Js.String2.includes(dir, "ep8prod") {
    [
      /* दृश्य 1: the strange borrowed cry nobody recognises */
      (12, "CHEEL", "क्रीऽऽऽ!"),
      /* दृश्य 5: the delivery — he replays what he heard, voice by voice */
      (56, "KUKU", "मदद! दादीऽ!"),
      (56, "CHEEL", "क्रीऽऽऽ!"),
      (56, "LEDA", "मुझे डर लग रहा है…"),
      /* दृश्य 6: mocking the beaten queen in her own voice */
      (65, "CHEEL", "मेरी चाल! मेरी चाल!"),
      /* दृश्य 9: the button, softly */
      (92, "CHEEL", "मेरी चाल…"),
    ]
  } else {
    []
  }

/* ---- TAG_MAP: Hindi parenthetical -> engine tag -------------------------- */

type tagmap = {tags: Js.Dict.t<string>, visual: array<string>}

let loadTagmap = (p: string): tagmap => {
  let j = Js.Json.parseExn(readText(Path(p)))
  let o = j->Js.Json.decodeObject->Belt.Option.getWithDefault(Js.Dict.empty())
  let tags = Js.Dict.empty()
  switch Js.Dict.get(o, "tags")->Belt.Option.flatMap(Js.Json.decodeObject) {
  | Some(t) =>
    Js.Dict.entries(t)->Belt.Array.forEach(((k, v)) =>
      switch Js.Json.decodeString(v) {
      | Some(s) => Js.Dict.set(tags, k, s)
      | None => ()
      }
    )
  | None => ()
  }
  let visual =
    Js.Dict.get(o, "visual")
    ->Belt.Option.flatMap(Js.Json.decodeArray)
    ->Belt.Option.getWithDefault([])
    ->Belt.Array.keepMap(Js.Json.decodeString)
  {tags, visual}
}

/* A parenthetical may be several notes joined by commas, mixing performance with
   staging ("शर्म से, फिर सीधे"). Per the author's contract the VOCAL half wins and
   the purely visual half is dropped — a stage direction must never be spoken. */
let tagFor = (tm: tagmap, raw: string): string => {
  let p = Js.String2.trim(raw)
  if p == "" {
    ""
  } else {
    switch Js.Dict.get(tm.tags, p) {
    | Some(t) => t ++ " "
    | None =>
      if Belt.Array.some(tm.visual, v => v == p) {
        ""
      } else {
        let parts = Js.String2.split(p, ",")->Belt.Array.map(Js.String2.trim)
        let found = parts->Belt.Array.keepMap(x => Js.Dict.get(tm.tags, x))
        Belt.Array.length(found) > 0 ? Js.Array2.joinWith(found, " ") ++ " " : ""
      }
    }
  }
}

/* ---- manifest ------------------------------------------------------------ */

type line = {idx: int, who: string, namep: string, text: string}
type mimic = {after: int, voice: string, text: string, label: string}

let fld = (j, k) => j->Js.Json.decodeObject->Belt.Option.flatMap(o => Js.Dict.get(o, k))
let asStr = o => o->Belt.Option.flatMap(Js.Json.decodeString)->Belt.Option.getWithDefault("")
let asNum = o => o->Belt.Option.flatMap(Js.Json.decodeNumber)->Belt.Option.getWithDefault(0.0)

/* Pull «हूबहू <name> की …: «spoken»» out of a cue. Returns None for cues that only
   describe the bird moving — those need no audio at all. */
let parseMimic = (cue: string, after: int): option<mimic> =>
  if !Js.String2.includes(cue, "हूबहू") {
    None
  } else {
    switch (Js.String2.indexOf(cue, "«"), Js.String2.lastIndexOf(cue, "»")) {
    | (-1, _) | (_, -1) => None
    | (a, b) if b > a => {
        let spoken = Js.String2.trim(Js.String2.slice(cue, ~from=a + 1, ~to_=b))
        let head = Js.String2.slice(cue, ~from=0, ~to_=a)
        let after' = Js.String2.sliceToEnd(head, ~from=Js.String2.indexOf(head, "हूबहू") + 5)
        let word =
          Js.String2.split(Js.String2.trim(after'), " ")
          ->Belt.Array.get(0)
          ->Belt.Option.getWithDefault("")
        switch mimicVoiceKey(word) {
        | Some(v) if spoken != "" => Some({after, voice: v, text: spoken, label: word})
        | _ => None
        }
      }
    | _ => None
    }
  }

let main = async () => {
  switch (Belt.Array.get(argv, 2), Belt.Array.get(argv, 3), Belt.Array.get(argv, 4)) {
  | (Some(dir), Some(manifestPath), Some(dursPath)) => {
      let dry = envDry == Some("1")
      let chorusMembers = Kuku_Cast.chorusMembersFor(dir)
      let tm = loadTagmap(dir ++ "/../ep5prod/tagmap.json")
      let mj = Js.Json.parseExn(readText(Path(dir ++ "/" ++ manifestPath)))

      let lines =
        fld(mj, "events")
        ->Belt.Option.flatMap(Js.Json.decodeArray)
        ->Belt.Option.getWithDefault([])
        ->Belt.Array.map(e => {
          idx: fld(e, "idx")->asNum->Belt.Float.toInt,
          who: fld(e, "who")->asStr,
          namep: fld(e, "namep")->asStr,
          text: fld(e, "text")->asStr,
        })
        ->Belt.Array.keep(l => !Js.String2.endsWith(l.who, "_SFX"))

      let mimics =
        fld(mj, "sfx")
        ->Belt.Option.flatMap(Js.Json.decodeArray)
        ->Belt.Option.getWithDefault([])
        ->Belt.Array.keepMap(c =>
          parseMimic(fld(c, "cue")->asStr, fld(c, "after")->asNum->Belt.Float.toInt)
        )

      ensureDirPath(Path(dir ++ "/takes"))
      Js.log(
        "to record: " ++
        Belt.Int.toString(Belt.Array.length(lines)) ++
        " dialogue takes + " ++
        Belt.Int.toString(Belt.Array.length(mimics)) ++
        " mimicry takes",
      )

      let made = ref(0)
      let skipped = ref(0)
      let failed = ref(0)

      /* One take. A take is keyed on the TEXT IT SAYS, not merely on its index.

         Keying on the filename alone means that correcting a line in the manifest
         leaves the old audio in place forever — the file exists, so it is skipped,
         and the cut keeps saying the wrong thing while every downstream check
         passes. The sidecar records what was actually spoken, so an edited line
         re-records by itself.

         A re-recorded take invalidates everything DERIVED from it. The pristine
         snapshot matters most: leave a stale one behind and the parrot pitch step
         re-derives the take from the old audio and silently undoes the edit. */
      let renderCount = ref(0)
      let adopted = ref(0)
      let recycled = ref(0)
      let redone = []

      /* CONTENT INDEX: every take already on disk, keyed by the exact words it says.
         Take FILES are named by position (07.mp3), because the EDL and assembler
         address them that way — but position is exactly what an edit moves. Insert
         one line into scene 4 and every later index shifts, and a purely positional
         check would re-buy ~85 unchanged performances (lesson 8, in its most
         expensive form).

         So before buying anything, look for the same voice saying the same words
         under ANY name and copy it into place. Voice is part of the key because the
         same sentence in two mouths is two different performances. */
      let contentKey = (~voice: string, ~text: string) => voice ++ "|" ++ text
      let speakerOfIdx: Js.Dict.t<string> = Js.Dict.empty()
      lines->Belt.Array.forEach(l => Js.Dict.set(speakerOfIdx, pad2(l.idx), l.who))
      /* VOICE IS PART OF THE KEY. The word बधाई! is spoken twice this episode —
         once as पापा, once as लेडा — so keying on words alone would copy one
         dragon's performance into the other's mouth. The voice is recovered from
         the file's own name, the convention the whole line already uses:
           NN.mp3            the speaker of line NN in the manifest
           NN_WHO.mp3        chorus member WHO
           mimic_NN_WHO.mp3  the parrot in WHO's voice
         A name fitting none of these is never indexed, so it is never reused. */
      let voiceOfFileName = (mp3: string): option<string> => {
        /* NEVER infer the voice from the CURRENT manifest: the files on disk were
           recorded against the PREVIOUS one, and an inserted line shifts every later
           index. Index 36 may have been दादी yesterday and कुकु today — inferring
           would splice one dragon's recording into another's mouth. The voice a take
           was actually bought in is recorded in a .voice sidecar at purchase time;
           a take without one is simply not reusable. */
        let sidecar = Path(dir ++ "/takes/." ++ mp3 ++ ".voice")
        exists(sidecar) ? Some(readText(sidecar)) : None
      }
      let _ = speakerOfIdx
      /* THE BANK: every performance ever bought for this episode. It is the reuse
         source, so an index shift costs nothing and a stale file at a reused index
         can never be mistaken for the line that now lives there.

         CONTENT-ADDRESSED, NOT NAME-ADDRESSED. The first bank stored deposits under
         their positional filename (bank/36.mp3) — and a later script edit put a NEW
         line at index 36, whose deposit OVERWROTE the banked original before the
         shifted old line was reused from it. Result, measured on 2026-08-06:
         17 takes on disk carrying one line's audio under another line's text, and
         17 original performances destroyed and re-bought. A deposit named by the
         hash of (voice, words) cannot collide with a different performance by
         construction — same name means same content, so overwriting is harmless. */
      let bank = dir ++ "/takes/.bank"
      ensureDirPath(Path(bank))
      let bankName = (~voice: string, ~text: string): string =>
        sha256Text(contentKey(~voice, ~text)) ++ ".mp3"
      let byContent: Js.Dict.t<string> = Js.Dict.empty()
      /* ONLY the bank is indexed. It is content-addressed and immutable, so a
         key can never point at bytes that change mid-run. The first version also
         indexed top-level takes/ — mutable files — and an index-shifted rerun
         copied one freshly-recorded line into SIX other slots before it was
         caught by ear (Ep8, 2026-08-09). Same staleness family as lesson 9. */
      [bank]->Belt.Array.forEach(root =>
        readDir(Path(root))
        ->Belt.Array.keep(f => Js.String2.startsWith(f, ".") && Js.String2.endsWith(f, ".said"))
        ->Belt.Array.forEach(sidecar => {
          let mp3 = Js.String2.slice(sidecar, ~from=1, ~to_=Js.String2.length(sidecar) - 5)
          let voiceStamp = Path(root ++ "/." ++ mp3 ++ ".voice")
          if exists(Path(root ++ "/" ++ mp3)) && exists(voiceStamp) {
            Js.Dict.set(
              byContent,
              contentKey(~voice=readText(voiceStamp), ~text=readText(Path(root ++ "/" ++ sidecar))),
              root ++ "/" ++ mp3,
            )
          }
        })
      )
      let _ = voiceOfFileName

      let render = async (~file: string, ~voice: string, ~text: string, ~what: string): unit => {
        let p = Path(dir ++ "/takes/" ++ file)
        let said = Path(dir ++ "/takes/." ++ file ++ ".said")
        let present = exists(p) && fileSizeMb(p) *. 1.0e6 > 2000.0
        /* takes recorded before this stamp existed are adopted, not re-bought */
        if present && !exists(said) {
          writeText(said, text)
          adopted := adopted.contents + 1
        }
        let voiceStamp = Path(dir ++ "/takes/." ++ file ++ ".voice")
        let key = contentKey(~voice, ~text)
        /* a take is current only if it says the right WORDS in the right VOICE —
           a recast (सूत्रधार, Ep8) with unchanged text must re-record, not skip.
           Takes from before .voice stamps existed are trusted on text alone. */
        let voiceMatches = !exists(voiceStamp) || readText(voiceStamp) == voice
        if present && readText(said) == text && voiceMatches {
          writeText(voiceStamp, voice)
          skipped := skipped.contents + 1
        } else if (
          /* the same words already bought in this same voice, under another name */
          switch Js.Dict.get(byContent, key) {
          | Some(src) => src != dir ++ "/takes/" ++ file && exists(Path(src))
          | None => false
          }
        ) {
          switch Js.Dict.get(byContent, key) {
          | Some(src) => {
              if !dry {
                copyFile(Path(src), p)
                writeText(said, text)
                writeText(voiceStamp, voice)
                /* derived artefacts belong to the OLD file, never to this copy */
                removeFile(Path(dir ++ "/takes/." ++ file ++ ".leveled"))
                removeFile(Path(dir ++ "/takes/." ++ file ++ ".parrot"))
                removeFile(Path(dir ++ "/takes/.pristine/" ++ file))
              }
              recycled := recycled.contents + 1
              Js.log("  reuse " ++ file ++ " <- " ++ src ++ "  " ++ what)
            }
          | None => ()
          }
        } else if dry {
          Js.log("  would record " ++ file ++ "  " ++ what ++ (present ? "  (TEXT CHANGED)" : ""))
        } else {
          if present {
            let _ = Js.Array2.push(redone, file)
          }
          switch await tts(~text=Text(text), ~voice=VoiceId(voice)) {
          | blob => {
              let _ = writeBytes(p, blob)
              writeText(said, text)
              writeText(voiceStamp, voice)
              /* deposit in the bank so no later edit can ever re-buy this line */
              let bf = bankName(~voice, ~text)
              copyFile(p, Path(bank ++ "/" ++ bf))
              writeText(Path(bank ++ "/." ++ bf ++ ".said"), text)
              writeText(Path(bank ++ "/." ++ bf ++ ".voice"), voice)
              /* every artefact derived from the old audio is now a lie */
              removeFile(Path(dir ++ "/takes/." ++ file ++ ".leveled"))
              removeFile(Path(dir ++ "/takes/." ++ file ++ ".parrot"))
              removeFile(Path(dir ++ "/takes/.pristine/" ++ file))
              made := made.contents + 1
              renderCount := renderCount.contents + 1
              /* a newly bought performance is itself reusable by later lines */
              Js.Dict.set(byContent, key, bank ++ "/" ++ bankName(~voice, ~text))
              Js.log("  OK " ++ file ++ "  " ++ what)
            }
          | exception BackendError(m) => {
              failed := failed.contents + 1
              Js.log("  FAIL " ++ file ++ ": " ++ m)
            }
          }
        }
      }

      /* dialogue */
      for i in 0 to Belt.Array.length(lines) - 1 {
        switch Belt.Array.get(lines, i) {
        | None => ()
        | Some(l) => {
            let body = tagFor(tm, l.namep) ++ l.text
            if l.who == "CHORUS_ALL" {
              for k in 0 to Belt.Array.length(chorusMembers) - 1 {
                switch Belt.Array.get(chorusMembers, k) {
                | Some(w) =>
                  switch voiceOf(w) {
                  | Some(v) =>
                    await render(
                      ~file=pad2(l.idx) ++ "_" ++ w ++ ".mp3",
                      ~voice=v,
                      ~text=body,
                      ~what="chorus/" ++ w,
                    )
                  | None => ()
                  }
                | None => ()
                }
              }
            } else {
              switch voiceOf(l.who) {
              | Some(v) =>
                await render(~file=pad2(l.idx) ++ ".mp3", ~voice=v, ~text=body, ~what=l.who)
              | None =>
                raise(
                  BackendError(
                    "no voice for speaker '" ++
                    l.who ++
                    "' (line " ++
                    Belt.Int.toString(l.idx) ++
                    ") — add it to voiceOf before recording, do not guess",
                  ),
                )
              }
            }
          }
        }
      }

      /* mimicry — the parrot, in someone else's voice */
      for i in 0 to Belt.Array.length(mimics) - 1 {
        switch Belt.Array.get(mimics, i) {
        | None => ()
        | Some(m) =>
          switch voiceOf(m.voice) {
          | Some(v) =>
            await render(
              ~file="mimic_" ++ pad2(m.after) ++ "_" ++ m.voice ++ ".mp3",
              ~voice=v,
              ~text=m.text,
              ~what="तानसेन as " ++ m.label,
            )
          | None => ()
          }
        }
      }

      /* the declared ones the parser cannot see */
      let extraMimics = extraMimicsFor(dir)
      for i in 0 to Belt.Array.length(extraMimics) - 1 {
        switch Belt.Array.get(extraMimics, i) {
        | None => ()
        | Some((after, who, text)) =>
          switch voiceOf(who) {
          | Some(v) =>
            await render(
              ~file="mimic_" ++ pad2(after) ++ "_" ++ who ++ ".mp3",
              ~voice=v,
              ~text,
              ~what="तानसेन as " ++ who ++ " (declared)",
            )
          | None => ()
          }
        }
      }

      /* chorus parts -> one mixed take */
      if !dry {
        lines
        ->Belt.Array.keep(l => l.who == "CHORUS_ALL")
        ->Belt.Array.forEach(l => {
          let out = dir ++ "/takes/" ++ pad2(l.idx) ++ ".mp3"
          if !exists(Path(out)) {
            let parts =
              chorusMembers
              ->Belt.Array.map(w => dir ++ "/takes/" ++ pad2(l.idx) ++ "_" ++ w ++ ".mp3")
              ->Belt.Array.keep(p => exists(Path(p)))
            if Belt.Array.length(parts) >= 2 {
              let inputs = Belt.Array.concatMany(parts->Belt.Array.map(p => ["-i", p]))
              ffmpeg(
                Belt.Array.concatMany([
                  ["-y", "-v", "error"],
                  inputs,
                  [
                    "-filter_complex",
                    "amix=inputs=" ++
                    Belt.Int.toString(Belt.Array.length(parts)) ++
                    ":duration=longest:normalize=1,volume=2",
                    "-c:a", "libmp3lame", "-q:a", "3", out,
                  ],
                ]),
              )
              Js.log("  mixed chorus " ++ pad2(l.idx))
            }
          }
        })
      }

      /* Loudness. Ep5 shipped with dialogue buried under ambience until every take
         was pinned to -17 LUFS; do it at record time so the mix starts level. */
      if !dry {
        let normed = ref(0)
        readDir(Path(dir ++ "/takes"))
        ->Belt.Array.keep(f => Js.String2.endsWith(f, ".mp3") && !Js.String2.includes(f, ".norm."))
        ->Belt.Array.forEach(f => {
          let src = dir ++ "/takes/" ++ f
          let marker = Path(dir ++ "/takes/." ++ f ++ ".leveled")
          if !exists(marker) {
            let tmp = dir ++ "/takes/." ++ f ++ ".tmp.mp3"
            ffmpeg([
              "-y", "-v", "error", "-i", src,
              "-af", "loudnorm=I=-17:TP=-1.5:LRA=11",
              "-c:a", "libmp3lame", "-q:a", "3", tmp,
            ])
            copyFile(Path(tmp), Path(src))
            removeFile(Path(tmp))
            writeText(marker, "-17 LUFS")
            normed := normed.contents + 1
          }
        })
        Js.log("levelled " ++ Belt.Int.toString(normed.contents) ++ " takes to -17 LUFS")

        /* Pitch the parrot up — after levelling, so the shift rides a known level.

           EVERY SHIFT DERIVES FROM A PRISTINE PRE-PITCH SNAPSHOT, never from the
           take in place. An in-place shift has to be guarded against stacking, and
           it makes changing parrotPitch later impossible without delta arithmetic
           against whatever was applied last time. Re-deriving from the snapshot
           makes a new pitch value a one-line edit and costs exactly one generation
           of mp3 loss no matter how many times it is retuned.

           The marker records the pitch this take currently carries, so a changed
           parrotPitch re-derives and an unchanged one is skipped. */
        let pristineDir = dir ++ "/takes/.pristine"
        ensureDirPath(Path(pristineDir))
        let pitched = ref(0)
        let pitchBad = []
        readDir(Path(dir ++ "/takes"))
        ->Belt.Array.keep(f => Js.String2.startsWith(f, "mimic_") && Js.String2.endsWith(f, ".mp3"))
        ->Belt.Array.forEach(f => {
          let src = dir ++ "/takes/" ++ f
          let pristine = pristineDir ++ "/" ++ f
          let marker = Path(dir ++ "/takes/." ++ f ++ ".parrot")
          /* first sight of this take: the levelled file IS the pristine source */
          if !exists(Path(pristine)) {
            copyFile(Path(src), Path(pristine))
          }
          let carries =
            exists(marker)
              ? Belt.Float.fromString(Js.String2.trim(readText(marker)))->Belt.Option.getWithDefault(
                  0.0,
                )
              : 0.0
          if Js.Math.abs_float(carries -. parrotPitch) > 0.001 {
            let tmp = dir ++ "/takes/." ++ f ++ ".pitch.mp3"
            /* asetrate is an ABSOLUTE sample rate, so it MUST come from the file's
               own rate. Hardcoding 44100 against these 48kHz takes lifted the pitch
               only 5.7% while atempo still slowed 15% — the parrot came out barely
               shifted AND 8.6% longer, and nothing caught it because the marker
               recorded the intended 1.15 rather than what actually happened. */
            let probe = run(
              ~cmd="ffprobe",
              ~args=[
                "-v", "error", "-select_streams", "a:0",
                "-show_entries", "stream=sample_rate", "-of", "csv=p=0", pristine,
              ],
            )
            let srcRate =
              Belt.Float.fromString(Js.String2.trim(probe.stdout))->Belt.Option.getWithDefault(44100.0)
            let rate = Belt.Float.toInt(srcRate *. parrotPitch)
            ffmpeg([
              "-y", "-v", "error", "-i", pristine,
              "-af",
              "asetrate=" ++
              Belt.Int.toString(rate) ++
              ",aresample=" ++
              Belt.Float.toString(srcRate) ++
              ",atempo=" ++
              Js.Float.toFixedWithPrecision(1.0 /. parrotPitch, ~digits=4),
              "-c:a", "libmp3lame", "-q:a", "3", tmp,
            ])
            /* PROVE THE TRANSFORM DID WHAT IT CLAIMS. asetrate shortens by the same
               ratio it raises pitch by, and atempo is there to give that length
               back — so a correct shift lands on the pristine duration. When the
               rate was wrong these drifted 8.6% and shipped silently. */
            let Seconds(was) = probeDuration(Path(pristine))
            let Seconds(now) = probeDuration(Path(tmp))
            /* Tolerance is relative OR one mp3 frame's worth of encoder padding,
               whichever is looser — a 0.6s echo re-encodes 21ms short (3.3%, and
               inaudible) purely from padding. The bug this catches ran 385ms long
               on a 4.5s take, so the two are nowhere near each other. */
            let slack = Js.Math.max_float(0.05, was *. 0.02)
            if Js.Math.abs_float(now -. was) > slack {
              let _ = Js.Array2.push(
                pitchBad,
                "  " ++
                f ++
                ": pristine " ++
                Js.Float.toFixedWithPrecision(was, ~digits=3) ++
                "s -> pitched " ++
                Js.Float.toFixedWithPrecision(now, ~digits=3) ++ "s",
              )
            }
            copyFile(Path(tmp), Path(src))
            removeFile(Path(tmp))
            writeText(marker, Js.Float.toString(parrotPitch))
            pitched := pitched.contents + 1
          }
        })
        if Belt.Array.length(pitchBad) > 0 {
          Js.log("\nPITCH SHIFT CHANGED TAKE LENGTH — asetrate/atempo disagree:")
          pitchBad->Belt.Array.forEach(b => Js.log(b))
          raise(Failed("parrot pitch altered take durations"))
        }
        Js.log(
          "pitched " ++
          Belt.Int.toString(pitched.contents) ++
          " parrot takes up " ++
          Js.Float.toFixedWithPrecision((parrotPitch -. 1.0) *. 100.0, ~digits=0) ++
          "% (length preserved)",
        )
      }

      /* durations for the assembler */
      if !dry {
        let takes = Js.Dict.empty()
        lines->Belt.Array.forEach(l => {
          let p = Path(dir ++ "/takes/" ++ pad2(l.idx) ++ ".mp3")
          if exists(p) {
            let Seconds(d) = probeDuration(p)
            Js.Dict.set(takes, Belt.Int.toString(l.idx), Js.Json.number(d))
          }
        })
        let sfx = Js.Dict.empty()
        let recordDur = (name: string) => {
          let p = Path(dir ++ "/takes/" ++ name ++ ".mp3")
          if exists(p) {
            let Seconds(d) = probeDuration(p)
            Js.Dict.set(sfx, name, Js.Json.number(d))
          }
        }
        mimics->Belt.Array.forEach(m => recordDur("mimic_" ++ pad2(m.after) ++ "_" ++ m.voice))
        extraMimics->Belt.Array.forEach(((after, who, _)) =>
          recordDur("mimic_" ++ pad2(after) ++ "_" ++ who)
        )
        /* MERGE, never replace. The durs file has two writers — this one for takes
           and mimicry, the score/effects generator for the 34 sound effects. Building
           it fresh here silently wiped every effect duration, and the assembler then
           skipped ALL EIGHT SCENES for "missing" files that were sitting on disk. */
        let dursFull = Path(dir ++ "/" ++ dursPath)
        let root = exists(dursFull)
          ? Js.Json.parseExn(readText(dursFull))
            ->Js.Json.decodeObject
            ->Belt.Option.getWithDefault(Js.Dict.empty())
          : Js.Dict.empty()
        let existingSfx =
          Js.Dict.get(root, "sfx")
          ->Belt.Option.flatMap(Js.Json.decodeObject)
          ->Belt.Option.getWithDefault(Js.Dict.empty())
        Js.Dict.entries(sfx)->Belt.Array.forEach(((k, v)) => Js.Dict.set(existingSfx, k, v))
        Js.Dict.set(root, "takes", Js.Json.object_(takes))
        Js.Dict.set(root, "sfx", Js.Json.object_(existingSfx))
        writeText(dursFull, Js.Json.stringifyWithSpace(Js.Json.object_(root), 1))
        Js.log(
          "durations written: " ++
          Belt.Int.toString(Belt.Array.length(Js.Dict.keys(takes))) ++
          " takes, " ++
          Belt.Int.toString(Belt.Array.length(Js.Dict.keys(existingSfx))) ++ " sfx+mimicry",
        )
      }

      if adopted.contents > 0 {
        Js.log(
          "adopted " ++
          Belt.Int.toString(adopted.contents) ++
          " existing takes into text-stamping (not re-bought)",
        )
      }
      if Belt.Array.length(redone) > 0 {
        Js.log("re-recorded because the line changed: " ++ Js.Array2.joinWith(redone, ", "))
      }
      Js.log(
        "\nrecorded=" ++
        Belt.Int.toString(made.contents) ++
        " skipped=" ++
        Belt.Int.toString(skipped.contents) ++
        " reused=" ++
        Belt.Int.toString(recycled.contents) ++
        " failed=" ++
        Belt.Int.toString(failed.contents),
      )
      if dry {
        Js.log("DRY run — nothing recorded, nothing spent.")
      }
    }
  | _ => Js.log("usage: node src/Kuku_Voices.res.mjs <episode-dir> <manifest.json> <durs.json>")
  }
}

main()
->Js.Promise2.catch(e => {
  Js.log2("VOICES FAILED:", e)
  Js.Promise.resolve()
})
->ignore
