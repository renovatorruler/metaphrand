/* कुकु और अक्षर — PREFLIGHT. Run this before spending money on an episode, and
   again before publishing it.

   Every check here exists because the failure it catches actually shipped, or
   nearly shipped, on a previous episode. The written version is
   stories/kuku/PRODUCTION_LESSONS.md; this file is the part that cannot be
   forgotten. A lesson that lives only in a document gets re-learned — Ep6 repeated
   two Ep5 mistakes before this existed.

   Exits nonzero if any BLOCKING check fails, so it can gate a build.

   Run from studio/:
     node src/Kuku_Preflight.res.mjs <episode-dir> <prefix>
   e.g. node src/Kuku_Preflight.res.mjs ../stories/kuku/ep6prod ep6 */

open Cinema_Backends

@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external exit: int => unit = "exit"

let fld = (j, k) => j->Js.Json.decodeObject->Belt.Option.flatMap(o => Js.Dict.get(o, k))
let asStr = o => o->Belt.Option.flatMap(Js.Json.decodeString)->Belt.Option.getWithDefault("")
let asNum = o => o->Belt.Option.flatMap(Js.Json.decodeNumber)->Belt.Option.getWithDefault(0.0)
let asArr = o => o->Belt.Option.flatMap(Js.Json.decodeArray)->Belt.Option.getWithDefault([])

type severity = Blocking | Warning
type finding = {check: string, severity: severity, detail: string}

let findings: array<finding> = []
let add = (check, severity, detail) => {
  let _ = Js.Array2.push(findings, {check, severity, detail})
}
let passed: array<string> = []
let pass = (c: string) => {
  let _ = Js.Array2.push(passed, c)
}

/* A dialogue shot is named e<ep>_d<scene>_<char>. Matching the bare substring "_d"
   also catches e6_sab_upar_deKHte and e6_Dadi_dana_lene_jaati, which are story
   shots — that false positive is exactly the kind of thing that makes a guard get
   ignored, so the shape is checked properly. */
let isDialogueShot = (n: string): bool =>
  switch Js.String2.match_(n, %re("/^e\d+_d\d+_[a-z]+$/")) {
  | Some(_) => true
  | None => false
  }

let dialogueShotChar = (n: string): option<string> =>
  isDialogueShot(n)
    ? Js.String2.split(n, "_")->Belt.Array.get(2)
    : None

let slugOf = (who: string): string =>
  switch who {
  | "KUKU" => "kuku"
  | "FYURIA" => "fyuria"
  | "VESPER" => "vesper"
  | "DADI" => "dadi"
  | "PAPA" => "papa"
  | "MITASUR" => "mitasur"
  | "CASTOR" => "castor"
  | "LEDA" => "leda"
  | _ => "group"
  }

/* charsheet basename for a speaker — the Ep5 bug was a missing reference sheet,
   which produced two कैस्टरs and no लेडा */
let sheetOf = (who: string): option<string> =>
  switch who {
  | "KUKU" => Some("kuku")
  | "FYURIA" => Some("furia")
  | "VESPER" => Some("vesper")
  | "DADI" => Some("dadi")
  | "PAPA" => Some("papa")
  | "MITASUR" => Some("mitasur")
  | "CASTOR" => Some("castor")
  | "LEDA" => Some("leda")
  | _ => None
  }

let main = () => {
  switch (Belt.Array.get(argv, 2), Belt.Array.get(argv, 3)) {
  | (Some(dir), Some(prefix)) => {
      let manifest = Js.Json.parseExn(readText(Path(dir ++ "/" ++ prefix ++ "_manifest.json")))
      let events = fld(manifest, "events")->asArr
      let cues = fld(manifest, "sfx")->asArr
      let durs = Kuku_Edl.loadDurs(Path(dir ++ "/" ++ prefix ++ "_durs.json"))

      let edlPath = Path(dir ++ "/" ++ prefix ++ "_edl.json")
      let edl = exists(edlPath) ? Some(Kuku_Edl.load(edlPath)) : None

      let shotsPath = Path(dir ++ "/" ++ prefix ++ "_shots.json")
      let shots = exists(shotsPath) ? Some(Js.Json.parseExn(readText(shotsPath))) : None

      /* ---- 1. every speaker has a voice ------------------------------------
         Ep5 crashed the recorder at take 105 because पापा had no map entry. */
      let speakers = Js.Dict.empty()
      events->Belt.Array.forEach(e => {
        let w = fld(e, "who")->asStr
        if !Js.String2.endsWith(w, "_SFX") {
          Js.Dict.set(speakers, w, true)
        }
      })
      let voiceless =
        Js.Dict.keys(speakers)->Belt.Array.keep(w =>
          w != "CHORUS_ALL" && sheetOf(w) == None
        )
      if Belt.Array.length(voiceless) > 0 {
        add("speaker-has-voice", Blocking, "no voice/sheet mapping for: " ++ Js.Array2.joinWith(voiceless, ", "))
      } else {
        pass("speaker-has-voice")
      }

      /* ---- 2. every take exists and has a duration ------------------------- */
      let missingTakes =
        events
        ->Belt.Array.keep(e => !Js.String2.endsWith(fld(e, "who")->asStr, "_SFX"))
        ->Belt.Array.keep(e => {
          let i = fld(e, "idx")->asNum->Belt.Float.toInt
          Js.Dict.get(durs.takes, Belt.Int.toString(i)) == None
        })
        ->Belt.Array.map(e => Belt.Int.toString(fld(e, "idx")->asNum->Belt.Float.toInt))
      if Belt.Array.length(missingTakes) > 0 {
        add("all-takes-recorded", Blocking, Belt.Int.toString(Belt.Array.length(missingTakes)) ++ " missing: " ++ Js.Array2.joinWith(Belt.Array.slice(missingTakes, ~offset=0, ~len=12), ","))
      } else {
        pass("all-takes-recorded")
      }

      /* ---- 3. dialogue is levelled ----------------------------------------
         Ep5 shipped once with the stream louder than the voices. */
      let unlevelled =
        readDir(Path(dir ++ "/takes"))
        ->Belt.Array.keep(f => Js.String2.endsWith(f, ".mp3"))
        ->Belt.Array.keep(f => !exists(Path(dir ++ "/takes/." ++ f ++ ".leveled")))
      if Belt.Array.length(unlevelled) > 0 {
        add("dialogue-levelled", Blocking, Belt.Int.toString(Belt.Array.length(unlevelled)) ++ " takes never loudness-normalised")
      } else {
        pass("dialogue-levelled")
      }

      switch edl {
      | None => add("edl-exists", Warning, "no EDL yet — rerun preflight after building it")
      | Some(e) => {
          pass("edl-exists")

          /* ---- 4. every EDL source exists on disk ------------------------- */
          let missingSrc = []
          e.scenes->Belt.Array.forEach(sc =>
            sc.segments->Belt.Array.forEachWithIndex((gi, seg) =>
              switch Kuku_Edl.sourcePath(seg.src) {
              | Some(p) =>
                if !exists(Path(dir ++ "/" ++ p)) {
                  let _ = Js.Array2.push(missingSrc, sc.name ++ "#" ++ Belt.Int.toString(gi) ++ " " ++ p)
                }
              | None => ()
              }
            )
          )
          if Belt.Array.length(missingSrc) > 0 {
            add("edl-sources-exist", Blocking, Belt.Int.toString(Belt.Array.length(missingSrc)) ++ " missing, e.g. " ++ Js.Array2.joinWith(Belt.Array.slice(missingSrc, ~offset=0, ~len=4), " | "))
          } else {
            pass("edl-sources-exist")
          }

          /* ---- 4b. every EDL event resolves to a DURATION -------------------
             Ep6 assembled to 110s of card and nothing else because the durs file
             has two writers and the second rebuilt it from scratch, wiping all 34
             effect durations. Every file was on disk; the assembler skipped all
             eight scenes anyway, because it needs the LENGTH, not the file. Checking
             existence alone is not enough. */
          let noDuration = []
          e.scenes->Belt.Array.forEach(sc =>
            sc.segments->Belt.Array.forEach(seg =>
              seg.takes->Belt.Array.forEach(t =>
                switch Kuku_Edl.eventDur(durs, t) {
                | _ => ()
                | exception _ => {
                    let n = Kuku_Edl.eventPath(t)
                    if !Belt.Array.some(noDuration, x => x == n) {
                      let _ = Js.Array2.push(noDuration, n)
                    }
                  }
                }
              )
            )
          )
          if Belt.Array.length(noDuration) > 0 {
            add(
              "edl-events-have-durations",
              Blocking,
              Belt.Int.toString(Belt.Array.length(noDuration)) ++
              " events have no duration entry (the assembler will SKIP their whole scene): " ++
              Js.Array2.joinWith(Belt.Array.slice(noDuration, ~offset=0, ~len=6), ", "),
            )
          } else {
            pass("edl-events-have-durations")
          }

          /* ---- 4c. every EDL event resolves to a FILE ON DISK ---------------
             Distinct from 4b: a duration can exist while the path is wrong. The
             mimicry takes are recorded voice living in takes/, but were being
             addressed as sfx/, so ffmpeg was handed inputs that did not exist and
             the scene's whole audio bus died. Existence and length are two checks,
             not one. */
          let noFile = []
          e.scenes->Belt.Array.forEach(sc =>
            sc.segments->Belt.Array.forEach(seg =>
              seg.takes->Belt.Array.forEach(t => {
                let p = Kuku_Edl.eventPath(t)
                if !exists(Path(dir ++ "/" ++ p)) && !Belt.Array.some(noFile, x => x == p) {
                  let _ = Js.Array2.push(noFile, p)
                }
              })
            )
          )
          if Belt.Array.length(noFile) > 0 {
            add(
              "edl-events-have-files",
              Blocking,
              Belt.Int.toString(Belt.Array.length(noFile)) ++
              " event audio files missing: " ++
              Js.Array2.joinWith(Belt.Array.slice(noFile, ~offset=0, ~len=6), ", "),
            )
          } else {
            pass("edl-events-have-files")
          }

          /* ---- 5. NO DIALOGUE STILL REUSED ACROSS SCENES -------------------
             Ep5 held one दादी close-up from scene 1 to scene 8 and had to be
             re-cut with 43 fresh images. */
          let stillScenes = Js.Dict.empty()
          e.scenes->Belt.Array.forEach(sc =>
            sc.segments->Belt.Array.forEach(seg =>
              switch seg.src {
              | Still(n) =>
                if isDialogueShot(n) {
                  let prev = Js.Dict.get(stillScenes, n)->Belt.Option.getWithDefault([])
                  if !Belt.Array.some(prev, s => s == sc.name) {
                    Js.Dict.set(stillScenes, n, Belt.Array.concat(prev, [sc.name]))
                  }
                }
              | _ => ()
              }
            )
          )
          let crossScene =
            Js.Dict.entries(stillScenes)->Belt.Array.keep(((_, ss)) => Belt.Array.length(ss) > 1)
          if Belt.Array.length(crossScene) > 0 {
            add(
              "no-dialogue-still-across-scenes",
              Blocking,
              crossScene
              ->Belt.Array.map(((n, ss)) => n ++ " in " ++ Js.Array2.joinWith(ss, "+"))
              ->Js.Array2.joinWith(", "),
            )
          } else {
            pass("no-dialogue-still-across-scenes")
          }

          /* ---- 6. NO SOUND MAY PLAY UNDER SPEECH ---------------------------
             Ep5 put every cue at 0.0s (the bridge broke audibly before it broke).
             Ep6 repeated the PRINCIPLE with a new number: cues at 0.15/0.35 —
             under the line instead of before it — and the parrot's echoes played
             simultaneously with the dialogue. The first version of this check
             tested Ep5's literal symptom (at == 0.0) and waved Ep6's cut through.
             The rule is the principle: in a segment with speech, an effect either
             OPENS the shot (at 0.0 — ambience beds, arrival sounds) or starts
             AFTER the speech ends. Anything in between is buried under a voice. */
          let buried = []
          e.scenes->Belt.Array.forEach(sc =>
            sc.segments->Belt.Array.forEachWithIndex((gi, seg) => {
              let firstSpeech =
                seg.takes->Belt.Array.getBy(t =>
                  switch t {
                  | Kuku_Edl.Speech(_) => true
                  | Kuku_Edl.Effect(_) => false
                  }
                )
              switch firstSpeech {
              | Some(Kuku_Edl.Speech({idx, at})) => {
                  let start = at->Belt.Option.getWithDefault(0.3)
                  let stop =
                    start +.
                    Js.Dict.get(durs.takes, Belt.Int.toString(idx))->Belt.Option.getWithDefault(0.0)
                  seg.takes->Belt.Array.forEach(t =>
                    switch t {
                    | Kuku_Edl.Effect({name, at}) => {
                        let a = at->Belt.Option.getWithDefault(0.0)
                        if a > 0.05 && a < stop -. 0.05 {
                          let _ = Js.Array2.push(
                            buried,
                            sc.name ++
                            "#" ++
                            Belt.Int.toString(gi) ++
                            " " ++
                            name ++
                            " at " ++
                            Js.Float.toFixedWithPrecision(a, ~digits=2) ++
                            "s under speech ending " ++
                            Js.Float.toFixedWithPrecision(stop, ~digits=2) ++ "s",
                          )
                        }
                      }
                    | Kuku_Edl.Speech(_) => ()
                    }
                  )
                }
              | Some(Kuku_Edl.Effect(_)) | None => ()
              }
            })
          )
          if Belt.Array.length(buried) > 0 {
            add(
              "sfx-not-buried-under-speech",
              Blocking,
              Belt.Int.toString(Belt.Array.length(buried)) ++
              " buried, e.g. " ++
              Js.Array2.joinWith(Belt.Array.slice(buried, ~offset=0, ~len=4), " | "),
            )
          } else {
            pass("sfx-not-buried-under-speech")
          }

          /* ---- 7. every sound cue in the script is placed -----------------
             Ep5 built an effects table and never consumed it; the crack the
             plot turned on was silent. */
          let placed = Js.Dict.empty()
          e.scenes->Belt.Array.forEach(sc =>
            sc.segments->Belt.Array.forEach(seg =>
              seg.takes->Belt.Array.forEach(t =>
                switch t {
                | Effect({name}) => Js.Dict.set(placed, name, true)
                | Speech(_) => ()
                }
              )
            )
          )
          let nPlaced = Belt.Array.length(Js.Dict.keys(placed))
          if nPlaced == 0 && Belt.Array.length(cues) > 0 {
            add("sound-cues-placed", Blocking, Belt.Int.toString(Belt.Array.length(cues)) ++ " cues in the script, none in the EDL")
          } else {
            pass("sound-cues-placed")
          }

          /* ---- 8. paid-for assets that the cut never uses ------------------ */
          let used = Js.Dict.empty()
          e.scenes->Belt.Array.forEach(sc =>
            sc.segments->Belt.Array.forEach(seg =>
              switch Kuku_Edl.sourcePath(seg.src) {
              | Some(p) => Js.Dict.set(used, p, true)
              | None => ()
              }
            )
          )
          let orphanStills =
            readDir(Path(dir ++ "/stills"))
            ->Belt.Array.keep(f => Js.String2.endsWith(f, ".png") && !Js.String2.startsWith(f, "wp_"))
            ->Belt.Array.keep(f => Js.Dict.get(used, "stills/" ++ f) == None)
          let orphanClips =
            readDir(Path(dir ++ "/clips"))
            ->Belt.Array.keep(f => Js.String2.endsWith(f, ".mp4"))
            ->Belt.Array.keep(f => Js.Dict.get(used, "clips/" ++ f) == None)
          let nOrphan = Belt.Array.length(orphanStills) + Belt.Array.length(orphanClips)
          if nOrphan > 0 {
            add(
              "no-paid-orphans",
              Warning,
              Belt.Int.toString(nOrphan) ++ " generated assets the cut never uses (" ++
              Belt.Int.toString(Belt.Array.length(orphanClips)) ++ " of them clips, the expensive kind)",
            )
          } else {
            pass("no-paid-orphans")
          }

          /* ---- 8b. THE LETTER MUST BE ON SCREEN ----------------------------
             Ep6 shipped a review cut in which the letter the episode is named
             after was composited nowhere: glyphs/fx_t.png was rendered and every
             segment carried `fx: []`. Nothing failed, because the orphan scan
             above only looks at stills and clips — an unattached GLYPH was
             invisible to it. This is a letter-teaching show; a cut with no
             letter on screen is not shippable, so this blocks. */
          let nFx = Belt.Array.reduce(e.scenes, 0, (n, sc) =>
            n + Belt.Array.reduce(sc.segments, 0, (m, seg) => m + Belt.Array.length(seg.fx))
          )
          let glyphFx = ref(0)
          e.scenes->Belt.Array.forEach(sc =>
            sc.segments->Belt.Array.forEach(seg =>
              seg.fx->Belt.Array.forEach(x =>
                if Js.String2.startsWith(x.png, "glyphs/fx_") {
                  glyphFx := glyphFx.contents + 1
                }
              )
            )
          )
          if glyphFx.contents == 0 {
            add(
              "letter-is-on-screen",
              Blocking,
              "the letterform is composited onto NO shot (" ++
              Belt.Int.toString(nFx) ++
              " overlays total) — a letter episode must show its letter",
            )
          } else {
            pass("letter-is-on-screen")
          }

          /* every rendered glyph should be attached to something, for the same
             reason: it was paid for to be seen */
          let usedFx = Js.Dict.empty()
          e.scenes->Belt.Array.forEach(sc =>
            sc.segments->Belt.Array.forEach(seg =>
              seg.fx->Belt.Array.forEach(x => Js.Dict.set(usedFx, x.png, true))
            )
          )
          let glyphDir = dir ++ "/glyphs"
          let orphanGlyphs = !exists(Path(glyphDir))
            ? []
            : readDir(Path(glyphDir))
              ->Belt.Array.keep(f => Js.String2.endsWith(f, ".png"))
              ->Belt.Array.keep(f => Js.Dict.get(usedFx, "glyphs/" ++ f) == None)
          if Belt.Array.length(orphanGlyphs) > 0 {
            add(
              "glyphs-are-used",
              Warning,
              Belt.Int.toString(Belt.Array.length(orphanGlyphs)) ++
              " rendered glyph(s) attached to nothing: " ++
              Js.Array2.joinWith(orphanGlyphs, ", "),
            )
          } else {
            pass("glyphs-are-used")
          }

          /* ---- 9. the picture must move ------------------------------------
             A cut made only of speaker close-ups is what the first Ep6 EDL
             produced: every establisher and clip rendered and unused. */
          let nSeg = Belt.Array.reduce(e.scenes, 0, (n, sc) => n + Belt.Array.length(sc.segments))
          let nDialogueStill = ref(0)
          e.scenes->Belt.Array.forEach(sc =>
            sc.segments->Belt.Array.forEach(seg =>
              switch seg.src {
              | Still(n) =>
                if isDialogueShot(n) {
                  nDialogueStill := nDialogueStill.contents + 1
                }
              | _ => ()
              }
            )
          )
          if nSeg > 0 && nDialogueStill.contents * 10 > nSeg * 9 {
            add("picture-has-variety", Warning, Belt.Int.toString(nDialogueStill.contents) ++ " of " ++ Belt.Int.toString(nSeg) ++ " segments are talking heads")
          } else {
            pass("picture-has-variety")
          }
        }
      }

      /* ---- 10. every dialogue shot attaches the speaker's own charsheet ----
         Ep5 produced two कैस्टरs and no लेडा because a sheet was not attached. */
      switch shots {
      | None => add("shot-refs-include-speaker", Warning, "no shot list to check")
      | Some(sj) => {
          let bad = []
          fld(sj, "stills")
          ->asArr
          ->Belt.Array.forEach(s => {
            let n = fld(s, "name")->asStr
            let refs = fld(s, "refs")->asArr->Belt.Array.map(r => Js.Json.decodeString(r)->Belt.Option.getWithDefault(""))
            /* e6_d3_kuku -> kuku */
            switch dialogueShotChar(n) {
            | Some(who) if who != "group" && who != "toddlers" => {
                let sheet = who == "fyuria" ? "furia" : who
                if !Belt.Array.some(refs, r => r == sheet) {
                  let _ = Js.Array2.push(bad, n ++ " (refs: " ++ Js.Array2.joinWith(refs, ",") ++ ")")
                }
              }
            | _ => ()
            }
          })
          if Belt.Array.length(bad) > 0 {
            add("shot-refs-include-speaker", Blocking, Js.Array2.joinWith(Belt.Array.slice(bad, ~offset=0, ~len=6), " | "))
          } else {
            pass("shot-refs-include-speaker")
          }
        }
      }

      /* ---- 11. word cards must depict their words ------------------------
         Ep5 shipped five of six wrong. This can only check that a distinct
         picture EXISTS for each carded word; a human still has to look. */
      let wordpics = readDir(Path(dir ++ "/wordpics"))->Belt.Array.keep(f => Js.String2.endsWith(f, ".png"))
      if Belt.Array.length(wordpics) < 6 {
        add("word-cards-have-pictures", Blocking, "only " ++ Belt.Int.toString(Belt.Array.length(wordpics)) ++ " word pictures; the recap needs one per carded word")
      } else {
        pass("word-cards-have-pictures")
      }

      /* ---- report -------------------------------------------------------- */
      Js.log("PREFLIGHT — " ++ dir)
      Js.log("passed: " ++ Belt.Int.toString(Belt.Array.length(passed)))
      passed->Belt.Array.forEach(p => Js.log("  ok   " ++ p))
      let blockers = findings->Belt.Array.keep(f => f.severity == Blocking)
      let warns = findings->Belt.Array.keep(f => f.severity == Warning)
      if Belt.Array.length(warns) > 0 {
        Js.log("\nwarnings:")
        warns->Belt.Array.forEach(f => Js.log("  warn " ++ f.check ++ ": " ++ f.detail))
      }
      if Belt.Array.length(blockers) > 0 {
        Js.log("\nBLOCKING:")
        blockers->Belt.Array.forEach(f => Js.log("  FAIL " ++ f.check ++ ": " ++ f.detail))
        Js.log("\nPREFLIGHT FAILED — " ++ Belt.Int.toString(Belt.Array.length(blockers)) ++ " blocking")
        exit(1)
      } else {
        Js.log("\nPREFLIGHT PASSED")
      }
    }
  | _ => Js.log("usage: node src/Kuku_Preflight.res.mjs <episode-dir> <prefix>")
  }
}

main()
