/* कुकु और अक्षर — EP8 «च से चील»: ORIGINAL score + sound effects for the
   2-minute slice (cold open + scene 1).

   Ep7 borrowed Ep6's cues. Ep8 does not: the author asked for a thrilling,
   "scary" feel a child would name as scary, and the show has never had a cue
   with menace in it. These are written from scratch through the ElevenLabs music
   endpoint, instrumental, so nothing sings over the Hindi.

   The line between thrilling and frightening, held deliberately: tension comes
   from LOW strings, held breath and space, never from stingers, dissonance or
   horror timbres. A four-year-old should lean in, not leave the room.

   Same disciplines as Kuku_ScoreEp6: skip-if-exists, DRY pricing, beds levelled
   to -26 LUFS and events to -20, durations folded into ep8_durs.json.

   Run from studio/:  node src/Kuku_ScoreEp8.res.mjs */

open Cinema_Backends

@val @scope(("process", "env")) external envDry: option<string> = "DRY"

let dir = "../stories/kuku/ep8prod"

/* (name, ms, prompt) — instrumental only */
let cues: array<(string, int, string)> = [
  (
    "cueC1_tapasya",
    75000,
    "Ancient Indian mythological storybook score for a children's show. Solo bansuri flute over a slow tanpura drone and soft tabla, patient and vast like a mountain peak through many seasons. Around the midpoint a low sustained string swells with quiet awe as a boon is granted, then settles. Warm, wondrous, unhurried, never frightening. Fully instrumental, no voices, no lyrics.",
  ),
  (
    "cueC3_cheel",
    50000,
    "Elegant slow predator theme for a children's mythological cartoon: a patient, unhurried waltz-like pulse on low pizzicato strings and a single silky sarangi line that glides and circles, vain and amused, never rushing. Tension from patience and low register, no stingers, no dissonance, no horror. A queen surveying what is already hers. Fully instrumental, no voices.",
  ),
  (
    "cueC4_fight",
    70000,
    "Driving adventure cue for a children's cartoon rescue: quick pulsing tabla and dholak under urgent short sarangi figures, building in steps as a plan is attempted, with two brief drops to almost-silence where a plan fails. Determined and exciting, never frightening or harsh, no dissonance. Ends unresolved on a held low note. Fully instrumental, no voices.",
  ),
  (
    "cueC5_rescue",
    55000,
    "Heroic arrival cue for a children's mythological cartoon: from held breathless silence, low strings rise into one enormous warm triumphant swell with deep drums and a soaring sarangi, the grandmother's theme — powerful, protective, dignified, more relief than victory, then settling gently into calm. Fully instrumental, no voices.",
  ),
  (
    "cueC6_katha",
    80000,
    "Gentle nostalgic storybook cue for a children's show: solo bansuri flute over a soft tanpura drone and very light sarangi, wistful and warm, the sound of an old story being told at dusk about something beautiful that was lost without anybody noticing. Tender, unhurried, a little sad, never tragic. Fully instrumental, no voices.",
  ),
  (
    "cueC2_shadow",
    40000,
    "Playful sunny morning theme for a preschool cartoon on light pizzicato strings and a gentle flute — and underneath, a low cello note that keeps returning, slow and patient, like a shadow circling. Tension held by space and low strings, never sharp, no stingers, no dissonance, no horror. Ends unresolved, curious rather than scared. Fully instrumental, no voices.",
  ),
]

/* (name, seconds, prompt) */
let effects: array<(string, float, string)> = [
  (
    "mountain_wind_high",
    12.0,
    "Thin high-altitude wind over bare rock on a mountain peak, lonely and clean, faint distant echo, no music, no voices, loopable ambience",
  ),
  (
    "eagle_cry_far",
    3.0,
    "A single distant eagle or kite cry echoing across a wide mountain valley, piercing but far away, open air, no music",
  ),
  (
    "snow_settle",
    6.0,
    "Very soft snow falling and settling on stone in absolute stillness, delicate granular whisper, no wind gusts, no music",
  ),
  (
    "boon_shimmer",
    5.0,
    "A warm golden magical shimmer descending and settling, like glowing words coming to rest on feathers, soft bell-like sparkle with a low warm bloom underneath, wondrous not scary, no music bed",
  ),
  (
    "wingbeat_huge",
    4.0,
    "One huge bird of prey unfolding enormous wings and taking off with two powerful heavy wingbeats, deep air displacement, close and impressive, no music, no voices",
  ),
  (
    "shadow_pass",
    5.0,
    "The sound of a large shadow passing overhead outdoors: birdsong and small daytime sounds cutting abruptly to a held hush, one low air movement, then the birds hesitantly returning, no music",
  ),
  (
    "morning_dishes",
    6.0,
    "Soft homely clink of ceramic dishes being tidied in a courtyard on a bright morning, unhurried, faint, no voices, no music",
  ),
  (
    "glint_chime",
    2.0,
    "A single tiny bright glint chime, like sunlight catching a small shiny object, one delicate sparkle tone with a fast decay, quiet, no music bed",
  ),
  (
    "plank_khat",
    2.5,
    "A soft wooden knock and slide, like a small plank shifting off stone and dropping away, one muted distant clatter far below after a pause, outdoors, no voices",
  ),
  (
    "sparks_forge",
    4.0,
    "A soft magical breath of light: a gentle exhale becoming a shimmer of small golden sparks that rise and knit together with delicate bell-like tones, warm and wondrous, no music bed, no voices",
  ),
  (
    "sparks_scatter",
    4.0,
    "A gust of wind blowing apart a cloud of delicate magical sparkles: a low whoosh of displaced air and many small chime tones scattering and fading away downward, disappointed rather than violent, no music",
  ),
  (
    "tail_whoosh_strike",
    4.0,
    "One enormous heavy whoosh of a huge tail swung through air, ending in a deep solid impact with an explosive burst of feathers and dust, powerful and clean, no cries, no music, no gore",
  ),
  (
    "feathers_rain",
    6.0,
    "Many large feathers drifting and settling on rock after a struggle, soft irregular rustling touches, quiet aftermath, faint wind, no music",
  ),
  (
    "tail_whoosh_miss",
    2.5,
    "One huge fast whoosh of a heavy tail swung through empty air, no impact, air displacement only, ending clean, no voices, no music",
  ),
  (
    "cheel_land",
    5.0,
    "A very large bird landing close: two heavy powerful wingbeats shoving air, then talons gripping and scraping rock once, then a weighty settling rustle of big feathers folding, close and impressive, no cries, no music",
  ),
]

let beds = ["mountain_wind_high"]

let present = (p: path, minBytes: float): bool => exists(p) && fileSizeMb(p) *. 1.0e6 > minBytes

let main = async () => {
  let dry = envDry == Some("1")
  ensureDirPath(Path(dir ++ "/score"))
  ensureDirPath(Path(dir ++ "/sfx"))

  let made = ref(0)
  let skipped = ref(0)
  let failed = ref(0)

  for i in 0 to Belt.Array.length(cues) - 1 {
    switch Belt.Array.get(cues, i) {
    | None => ()
    | Some((name, ms, prompt)) => {
        let p = Path(dir ++ "/score/" ++ name ++ ".mp3")
        if present(p, 20000.0) {
          skipped := skipped.contents + 1
        } else if dry {
          Js.log("  would compose " ++ name ++ " (" ++ Belt.Int.toString(ms / 1000) ++ "s)")
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

  if !dry {
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

    let dursPath = Path(dir ++ "/ep8_durs.json")
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
    Belt.Int.toString(failed.contents) ++
    (dry ? "\nDRY run — nothing generated, nothing spent." : ""),
  )
}

main()
->Js.Promise2.catch(e => {
  Js.log2("SCORE/SFX FAILED:", e)
  Js.Promise.resolve()
})
->ignore
