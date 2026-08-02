/* कुकु और अक्षर — Ep6 «त से तोता»: score cues and sound effects.

   The screenplay carries 40 real (ध्वनि: …) cues, but they are not 40 distinct
   sounds — the parrot's wingbeat alone appears ten times, and clapping four. They
   dedupe to the table below, which the EDL then places wherever the cue asks for it.

   TWO SOUNDS ARE DELIBERATELY NOT GENERATED. तानसेन replaying वैस्पर's shriek, and
   the two-snores button at the close, must reuse वैस्पर's ACTUAL recorded audio —
   the joke is that it is literally the same sound coming out of a bird. A generated
   imitation would be a different scream and the gag dies. Those are wired to takes/
   in the EDL, not made here.

   Run from studio/:  node src/Kuku_ScoreEp6.res.mjs   (DRY=1 to price it) */

open Cinema_Backends

@val @scope(("process", "env")) external envDry: option<string> = "DRY"

let dir = "/Users/dusty/Dev/metaphrand/stories/kuku/ep6prod"

/* one cue per movement of the story, not one per scene — the assembler ducks these
   under dialogue, so they must stay unhurried and never demand attention */
let cues = [
  (
    "cueT1_morning",
    72000,
    "Bright pond morning for a children's papercraft cartoon: skipping ukulele, glockenspiel, soft water sparkle, ducks and small birds; a curious lift halfway as something unseen copies a child's voice — playful mystery, never spooky. Instrumental, cohesive.",
  ),
  (
    "cueT2_play",
    70000,
    "Comic naming-game cue for a children's cartoon: bouncy pizzicato call-and-response, a cheeky repeated motif that answers itself like an echo, warm family laughter, one big surprised stinger in the middle then straight back to play. Instrumental, cohesive, never scary.",
  ),
  (
    "cueT3_race",
    72000,
    "A running race for small children: light galloping percussion, breathless and fun, a cheerful finish — then the music thins to one quiet, slightly sour held note as somebody who always wins does not. Instrumental, cohesive, no menace.",
  ),
  (
    "cueT4_hurt",
    80000,
    "Quiet afternoon hurt for a children's cartoon: a single soft music box, long gentle strings, an unkind sentence arriving where it was never meant to go; sad but warm and safe, no dread; ends with a small honest resolve to put it right. Instrumental, cohesive.",
  ),
  (
    "cueT5_teach",
    88000,
    "Teaching and making cue: patient music box and soft strings that stay UNDER a grandmother's lesson, leaving room for a voice; playful call-and-response lifts as children repeat words; a warm golden bloom as a glowing letter is forged and settles into the ground. Instrumental, cohesive.",
  ),
  (
    "cueT6_words",
    85000,
    "Gentle building cue for a children's cartoon: three good words given as gifts, each one landing with a small warm chime and applause; tender in the middle where an apology is made by a stream, then a wide contented golden close. Instrumental, cohesive.",
  ),
  (
    "cueT7_night",
    70000,
    "Goodnight cue for a children's papercraft cartoon: soft lullaby music box, crickets, water, everything settling; two sleepers breathing; unhurried, tender, fading to almost nothing. Instrumental, cohesive.",
  ),
]

/* deduped from the script's 40 cues */
let effects = [
  /* act break — plays over the त card between acts, so it must read as a page
     turn rather than as something happening in the world: one clean note, no
     room tone, nothing the child could mistake for the pond or the birds */
  ("chime_act", 2.0, "One single soft warm marimba note struck gently and left to ring out and fade, clean and bell-like, no background noise, no room ambience, storybook page-turn feeling"),
  /* ambience beds */
  ("morning_birds_pond", 6.0, "Early morning songbirds around a small calm pond, gentle water lapping, peaceful outdoors"),
  ("pond_water_calm", 6.0, "A small calm pond, very gentle water movement, quiet and constant"),
  ("day_crickets", 5.0, "Midday crickets and insects in a warm open meadow, constant"),
  ("evening_crickets", 5.0, "Evening crickets by a pond, calm and warm, distant"),
  ("leaves_rustle", 4.0, "Leaves rustling softly in a light breeze through a large tree"),
  ("wind_only_silence", 3.5, "A sudden hush outdoors, only a thin wind moving, nothing else"),
  ("reeds_wind", 4.0, "Tall dry reeds at a pond edge swaying and clicking in wind, water behind"),
  ("stream_bridge_ropes", 6.0, "A stream running under a small rope-and-plank bridge, ropes creaking gently"),
  /* the parrot */
  ("parrot_wingbeat", 2.0, "A single medium bird taking off, three strong wing flaps close to the microphone"),
  ("parrot_flutter_away", 2.5, "A medium bird flapping away, wingbeats getting further away and higher"),
  ("parrot_land_perch", 1.5, "A medium bird landing on a wooden perch, small claws tapping wood once"),
  ("parrot_settle_feathers", 2.5, "A bird shuffling and fluffing its feathers as it settles to sleep on a perch"),
  ("ducks_flap_off", 2.5, "A few ducks startling off the surface of a pond, splashing and flapping away"),
  /* footsteps */
  ("dadi_stick_steps", 4.0, "Slow elderly footsteps on stony ground with a walking stick tapping, thak thak"),
  ("papa_heavy_steps", 3.0, "Heavy adult footsteps approaching on dry ground, unhurried and solid"),
  ("group_steps_field", 3.5, "Several children walking together through grass, light chattering footsteps"),
  ("running_steps_arrive", 2.5, "Light quick running footsteps arriving and stopping, then breathing hard"),
  ("mitasur_slow_heavy", 3.5, "Slow heavy soft-footed steps walking away on dry earth, tired"),
  ("leda_small_steps", 2.5, "Very small toddler footsteps walking slowly and carefully on soft ground"),
  ("race_footsteps", 4.5, "Two pairs of feet racing on grass, one light and fast in front, one heavy and slapping behind, both breathing hard"),
  ("splash_arrive", 2.0, "Feet splashing into shallow pond water at a run, happy arrival"),
  /* objects and actions */
  ("line_drawn_dirt", 2.0, "A stick dragged through dry dirt to draw a line on the ground"),
  ("door_creak_small", 2.0, "A small wooden door creaking open slowly"),
  ("door_close_soft", 1.5, "A small wooden door closing gently and latching"),
  ("seed_peck", 3.0, "A bird pecking seed from a hard bowl, light rapid tapping"),
  ("seed_into_bowl", 1.5, "A small handful of dry seed poured into a hollow wooden bowl"),
  ("forge_whoosh_land", 4.5, "A soft magical whoosh of breath, a warm golden shimmer, then a heavy solid object settling firmly into soft earth with one deep thock"),
  /* people */
  ("kids_playing_steps", 4.0, "Young children playing and running outdoors, happy scattered footsteps"),
  ("group_laugh", 3.0, "A small family group of children and adults laughing warmly together outdoors"),
  ("three_laugh", 2.5, "Three people laughing together warmly, one small one deep"),
  ("clap_group", 2.5, "A small group of children clapping happily together, six or seven claps"),
  ("clap_big", 3.5, "A small group of children and adults clapping loudly and joyfully, building"),
  ("yawn_boy", 2.0, "A small sleepy boy yawning long and softly"),
  ("valley_echo_scatter", 3.5, "A loud shout echoing away across an open valley, birds scattering in alarm, leaves shaking"),
  /* The closing button is two sleepers breathing — a boy and the parrot copying him.
     The joke only works if it is literally the SAME sound twice, so one effect is
     generated and placed at both points rather than two similar ones. (The original
     plan was to reuse वैस्पर's own recording; he has no snore TAKE, because the snore
     is a sound cue and not a spoken line.) */
  ("snore_soft_boy", 4.0, "A small boy snoring softly and peacefully, gentle slow rhythm, warm and comic not laboured"),
]

let main = async () => {
  let dry = envDry == Some("1")
  ensureDirPath(Path(dir ++ "/score"))
  ensureDirPath(Path(dir ++ "/sfx"))
  Js.log(
    "score cues: " ++
    Belt.Int.toString(Belt.Array.length(cues)) ++
    "   sound effects: " ++
    Belt.Int.toString(Belt.Array.length(effects)),
  )

  let made = ref(0)
  let skipped = ref(0)
  let failed = ref(0)

  /* big enough to be real audio, not an error page */
  let present = (p: path, minBytes: float): bool => exists(p) && fileSizeMb(p) *. 1.0e6 > minBytes

  for i in 0 to Belt.Array.length(cues) - 1 {
    switch Belt.Array.get(cues, i) {
    | None => ()
    | Some((name, ms, prompt)) => {
        let p = Path(dir ++ "/score/" ++ name ++ ".mp3")
        if present(p, 50000.0) {
          skipped := skipped.contents + 1
        } else if dry {
          Js.log("  would score " ++ name ++ " (" ++ Belt.Int.toString(ms / 1000) ++ "s)")
        } else {
          switch await music(~prompt=Prompt(prompt), ~ms=Millis(ms), ~instrumental=true) {
          | b => {
              let _ = writeBytes(p, b)
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

  for i in 0 to Belt.Array.length(effects) - 1 {
    switch Belt.Array.get(effects, i) {
    | None => ()
    | Some((name, secs, prompt)) => {
        let p = Path(dir ++ "/sfx/" ++ name ++ ".mp3")
        if present(p, 2000.0) {
          skipped := skipped.contents + 1
        } else if dry {
          Js.log("  would make " ++ name)
        } else {
          switch await soundEffect(~prompt=Prompt(prompt), ~seconds=secs, ~influence=0.55) {
          | b => {
              let _ = writeBytes(p, b)
              made := made.contents + 1
              Js.log("  sfx OK " ++ name)
            }
          | exception BackendError(m) => {
              failed := failed.contents + 1
              Js.log("  sfx FAIL " ++ name ++ ": " ++ m)
            }
          }
        }
      }
    }
  }

  /* Ambience must sit under dialogue, events may punch through. Ep5 shipped once
     with the stream louder than the voices; levelling here keeps that from
     recurring. Score is left alone — the assembler ducks it per-scene. */
  if !dry {
    let beds = [
      "morning_birds_pond", "pond_water_calm", "day_crickets", "evening_crickets",
      "leaves_rustle", "wind_only_silence", "reeds_wind", "stream_bridge_ropes",
    ]
    let levelled = ref(0)
    effects->Belt.Array.forEach(((name, _, _)) => {
      let src = dir ++ "/sfx/" ++ name ++ ".mp3"
      let marker = Path(dir ++ "/sfx/." ++ name ++ ".leveled")
      if exists(Path(src)) && !exists(marker) {
        let target = Belt.Array.some(beds, b => b == name) ? "-26" : "-20"
        let tmp = dir ++ "/sfx/." ++ name ++ ".tmp.mp3"
        ffmpeg([
          "-y", "-v", "error", "-i", src,
          "-af", "loudnorm=I=" ++ target ++ ":TP=-1.5:LRA=11",
          "-c:a", "libmp3lame", "-q:a", "3", tmp,
        ])
        copyFile(Path(tmp), Path(src))
        removeFile(Path(tmp))
        writeText(marker, target ++ " LUFS")
        levelled := levelled.contents + 1
      }
    })
    Js.log("levelled " ++ Belt.Int.toString(levelled.contents) ++ " effects (beds -26, events -20 LUFS)")

    /* fold durations into the durs file the assembler reads */
    let dursPath = Path(dir ++ "/ep6_durs.json")
    let root =
      Js.Json.parseExn(readText(dursPath))
      ->Js.Json.decodeObject
      ->Belt.Option.getWithDefault(Js.Dict.empty())
    let sfxDict =
      Js.Dict.get(root, "sfx")
      ->Belt.Option.flatMap(Js.Json.decodeObject)
      ->Belt.Option.getWithDefault(Js.Dict.empty())
    effects->Belt.Array.forEach(((name, _, _)) => {
      let p = Path(dir ++ "/sfx/" ++ name ++ ".mp3")
      if exists(p) {
        let Seconds(d) = probeDuration(p)
        Js.Dict.set(sfxDict, name, Js.Json.number(d))
      }
    })
    Js.Dict.set(root, "sfx", Js.Json.object_(sfxDict))
    writeText(dursPath, Js.Json.stringifyWithSpace(Js.Json.object_(root), 1))
    Js.log("durs now carries " ++ Belt.Int.toString(Belt.Array.length(Js.Dict.keys(sfxDict))) ++ " sfx entries")
  }

  Js.log(
    "\nmade=" ++
    Belt.Int.toString(made.contents) ++
    " skipped=" ++
    Belt.Int.toString(skipped.contents) ++
    " failed=" ++
    Belt.Int.toString(failed.contents),
  )
}

main()
->Js.Promise2.catch(e => {
  Js.log2("SCORE/SFX FAILED:", e)
  Js.Promise.resolve()
})
->ignore
