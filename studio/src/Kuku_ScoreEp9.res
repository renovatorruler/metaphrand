/* कुकु और अक्षर — EP9 «ब से बड़ा» original score for the 13:00 main story.

   One cue per scene, written to the scene's dramatic job and generated through the
   ElevenLabs music endpoint (music_v2, instrumental so nothing sings over the Hindi).

   Mixing rules carried forward from Ep6/Ep7/Ep8 unchanged: skip-if-exists so a rerun is
   free, DRY pricing before spending, and beds levelled to -26 LUFS (events stay -20). The
   master then sidechain-ducks the bed under dialogue, so score never competes with a line.

   Cue lengths are the scene spans measured off EDL v4 plus a 4s tail for the crossfade
   into the next scene.

   Run from studio/:  node src/Kuku_ScoreEp9.res.mjs
                      DRY=1 node src/Kuku_ScoreEp9.res.mjs */

open Cinema_Backends

@val @scope(("process", "env")) external envDry: option<string> = "DRY"

let finale = "../stories/kuku/ep9prod/finale"
let scoreDir = finale ++ "/audio/score"

/* (name, startSeconds, ms, gain, prompt) — start is seconds into the main story.

   `gain` is a linear multiplier on the -26 LUFS bed. The parent's note after hearing the
   first mix: the bed "is perfectly fine during the action sequences and in the dream
   sequence, but not at the other places." So action cues (transformation, flight, crisis,
   the rescue-and-repair climax) play at full bed level and everything dialogue-led steps
   back 6-8 dB — present enough to colour the scene, quiet enough to stop competing with a
   line the child is trying to follow. The cold open keeps its own separate mix untouched. */
let cues: array<(string, float, int, float, string)> = [
  (
    "cue01_echo_wakes",
    0.0,
    28000,
    0.63,
    "Opening cue for a children's mythological cartoon: a lone low tanpura drone under a single curious bansuri phrase, then a soft golden shimmer rising and travelling away, answered by one distant temple bell and a low stone-heavy swell of unease. Wonder with a shadow behind it, patient and spacious, never frightening. Fully instrumental, no voices, no lyrics.",
  ),
  (
    "cue02_morning_practice",
    24.0,
    69000,
    0.45,
    "Warm playful morning cue for a children's show: light skipping tabla and plucked strings under a cheerful bansuri melody, the feeling of small creatures running and jumping in wet grass at sunrise, little comic stumbles in the rhythm, affectionate and unhurried. Ends with the breeze turning and one soft questioning note. Fully instrumental, no voices, no lyrics.",
  ),
  (
    "cue03_the_sage",
    89.0,
    112000,
    0.4,
    "Cue for the arrival of an ancient dragon sage in a children's mythological cartoon: slow dignified low strings and a sustained sarangi line carrying real weight and responsibility, a quiet three-beat pulse underneath like something being held against a pull. Grave, kind, never menacing; one warm lift where a grandmother stands her ground. Fully instrumental, no voices, no lyrics.",
  ),
  (
    "cue04_forging",
    197.0,
    87000,
    0.5,
    "Discovery and making cue for a children's show: hushed curious pizzicato and santoor drops as a pattern is recognised, then a steadily building shimmer of strings and soft chimes as something is drawn into being stroke by stroke, resolving on one warm resonant bell as it becomes solid. Magical, focused, joyful. Fully instrumental, no voices, no lyrics.",
  ),
  (
    "cue05_transformation",
    280.0,
    64000,
    1.0,
    "Transformation cue for a children's mythological cartoon: five separate small sparks of light answering one after another, then one enormous warm rising swell of strings, tabla and dhol as small bodies grow into their true size — triumphant, earned, awestruck rather than loud. Settles into steady confidence. Fully instrumental, no voices, no lyrics.",
  ),
  (
    "cue06_first_flight",
    340.0,
    95000,
    1.0,
    "Soaring first-flight cue for a children's show: open joyful strings and bansuri riding a wide steady pulse, the exhilaration of wings working for the first time, then the rhythm gradually fraying and pulling out of step as coordination is lost, ending on a sharp uneasy break. Fully instrumental, no voices, no lyrics.",
  ),
  (
    "cue07_crisis",
    431.0,
    72000,
    1.0,
    "Urgent rescue cue for a children's cartoon: driving tabla and dholak under short determined string figures, climbing in steps, with one brief drop to near-silence where an attempt fails and a small frightened bell is heard. Exciting and tense, never harsh or frightening, no dissonance, no stingers. Fully instrumental, no voices, no lyrics.",
  ),
  (
    "cue08_rescue_and_repair",
    499.0,
    133000,
    1.0,
    "Long climax cue for a children's mythological cartoon: five separate rhythms locking into one shared pulse, growing from careful and coordinated into a huge warm triumphant swell of strings, dhol and sarangi as something broken is made whole and a small friend is carried to safety. Relief and pride rather than victory. Ends settling into calm. Fully instrumental, no voices, no lyrics.",
  ),
  (
    "cue09_aftermath",
    628.0,
    70000,
    0.4,
    "Tender aftermath cue for a children's show: gentle solo bansuri over soft santoor, the quiet after danger — an apology honestly made, a grandmother's steadiness, a small animal returned to its mother. Warm, forgiving, unhurried. Fully instrumental, no voices, no lyrics.",
  ),
  (
    "cue10_departure",
    694.0,
    90000,
    0.5,
    "Hopeful departure cue for a children's mythological cartoon: a rising open-hearted melody on bansuri and strings over a confident walking pulse, five young flyers leaving home toward a great school in the clouds, full of promise and a little nervousness, ending on one bright unresolved lift that says the story continues. Fully instrumental, no voices, no lyrics.",
  ),
]

let present = (p: path, minBytes: float): bool =>
  exists(p) && fileSizeMb(p) *. 1.0e6 > minBytes

let main = async () => {
  let dry = switch envDry {
  | Some("1") => true
  | _ => false
  }
  ensureDirPath(Path(scoreDir))
  let totalMs = cues->Belt.Array.reduce(0, (a, (_, _, ms, _, _)) => a + ms)
  Js.log(
    "EP9 SCORE — " ++ Belt.Int.toString(Belt.Array.length(cues)) ++ " cues, " ++
    Js.Float.toFixedWithPrecision(Belt.Int.toFloat(totalMs) /. 1000.0, ~digits=0) ++ "s of music",
  )

  let made = ref(0)
  let skipped = ref(0)
  let failed = ref(0)
  for i in 0 to Belt.Array.length(cues) - 1 {
    switch Belt.Array.get(cues, i) {
    | None => ()
    | Some((name, _, ms, _, prompt)) => {
        let p = Path(scoreDir ++ "/" ++ name ++ ".mp3")
        if present(p, 20000.0) {
          skipped := skipped.contents + 1
        } else if dry {
          Js.log("  would score " ++ name ++ " (" ++ Belt.Int.toString(ms / 1000) ++ "s)")
        } else {
          switch await music(~prompt=Prompt(prompt), ~ms=Millis(ms), ~instrumental=true) {
          | blob => {
              let _ = writeBytes(p, blob)
              made := made.contents + 1
              Js.log("  score OK " ++ name)
            }
          | exception BackendError(m) => {
              failed := failed.contents + 1
              Js.log("  score FAIL " ++ name ++ ": " ++ m)
            }
          }
        }
      }
    }
  }

  if !dry {
    /* beds sit at -26 LUFS; the marker keeps this idempotent */
    let levelled = ref(0)
    cues->Belt.Array.forEach(((name, _, _, _, _)) => {
      let src = scoreDir ++ "/" ++ name ++ ".mp3"
      let marker = Path(scoreDir ++ "/." ++ name ++ ".leveled")
      if exists(Path(src)) && !exists(marker) {
        let tmp = scoreDir ++ "/." ++ name ++ ".tmp.mp3"
        ffmpeg([
          "-y", "-v", "error", "-i", src,
          "-af", "loudnorm=I=-26:TP=-1.5:LRA=11",
          "-c:a", "libmp3lame", "-q:a", "3", tmp,
        ])
        copyFile(Path(tmp), Path(src))
        removeFile(Path(tmp))
        writeText(marker, "-26 LUFS bed")
        levelled := levelled.contents + 1
      }
    })
    Js.log("levelled " ++ Belt.Int.toString(levelled.contents) ++ " cues to -26 LUFS")

    let entries = cues->Belt.Array.keepMap(((name, start, _, gain, _)) => {
      let f = scoreDir ++ "/" ++ name ++ ".mp3"
      if !exists(Path(f)) {
        None
      } else {
        let Seconds(d) = probeDuration(Path(f))
        let o = Js.Dict.empty()
        Js.Dict.set(o, "id", Js.Json.string(name))
        Js.Dict.set(o, "path", Js.Json.string("../audio/score/" ++ name ++ ".mp3"))
        Js.Dict.set(o, "startSeconds", Js.Json.number(start))
        Js.Dict.set(o, "durationSeconds", Js.Json.number(d))
        Js.Dict.set(o, "gain", Js.Json.number(gain))
        Some(Js.Json.object_(o))
      }
    })
    let root = Js.Dict.empty()
    Js.Dict.set(root, "version", Js.Json.number(1.0))
    Js.Dict.set(root, "purpose", Js.Json.string(
      "EP9 score cues, one per scene, levelled to -26 LUFS. startSeconds is relative to the " ++
      "main story (which begins at 2:15 of the episode). The master sidechain-ducks these " ++
      "under the dialogue+SFX stem.",
    ))
    Js.Dict.set(root, "cues", Js.Json.array(entries))
    writeText(
      Path(finale ++ "/manifests/ep9_score_cues.v1.json"),
      Js.Json.stringifyWithSpace(Js.Json.object_(root), 2),
    )
    Js.log("score manifest carries " ++ Belt.Int.toString(Belt.Array.length(entries)) ++ " cues")
  }

  Js.log(
    "\nmade=" ++ Belt.Int.toString(made.contents) ++
    " skipped=" ++ Belt.Int.toString(skipped.contents) ++
    " failed=" ++ Belt.Int.toString(failed.contents) ++
    (dry ? "\nDRY run — nothing generated, nothing spent." : ""),
  )
}

main()
->Js.Promise2.catch(e => {
  Js.log2("EP9 SCORE FAILED:", e)
  Js.Promise.resolve()
})
->ignore
