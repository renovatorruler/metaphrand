/* कुकु और अक्षर — EP7 scenes 1–2 sound effects (the 2-minute slice).

   Reuses Ep6's already-paid library where the cue is the same sound (crickets,
   the soft door) and generates only what this episode's script actually adds:
   dusk birds, the rope-and-wheel of the loaded रथ, the departure over the plank
   bridge, कालू's farewell bark, the distant dishes of scene 2.

   Same disciplines as Kuku_ScoreEp6: skip-if-exists, DRY pricing, beds levelled
   to −26 LUFS and events to −20, durations folded into ep7_durs.json.

   Run from studio/:  node src/Kuku_SfxEp7.res.mjs */

open Cinema_Backends

@val @scope(("process", "env")) external envDry: option<string> = "DRY"

let dir = "../stories/kuku/ep7prod"
let ep6 = "../stories/kuku/ep6prod"

/* (name, seconds, prompt) — names are what the EDL's cue mapping speaks */
let effects: array<(string, float, string)> = [
  (
    "dusk_birds",
    12.0,
    "Gentle evening birdsong at dusk in a quiet valley meadow, sparse unhurried chirps settling down for the night, soft and warm, no wind noise, loopable ambience",
  ),
  (
    "cart_rope_creak",
    4.0,
    "A rope being pulled taut and knotted over wooden cart slats, two soft hemp creaks, then one slow wooden wheel creak as a loaded cart shifts its weight, close and quiet, no voices",
  ),
  (
    "cart_rolls_bridge",
    8.0,
    "A wooden two-wheeled cart rolls away over grass then onto a wooden plank bridge, wheels rumbling low over boards with a gentle rhythmic knock, fading into the distance, quiet evening air, no voices",
  ),
  (
    "kalu_bark",
    2.5,
    "A single small friendly dog giving two bright farewell barks, medium distance, open field acoustics, no growl, cheerful",
  ),
  (
    "dishes_clink",
    4.0,
    "Soft distant clink of ceramic dishes being tidied indoors heard from an outdoor courtyard at night, gentle and homely, faint, no voices",
  ),
  /* scenes 3–5: the मात्रा's tiny landing */
  (
    "soft_tak",
    1.5,
    "One single tiny wooden tick, like a small light peg gently clicking into its slot, soft and precise with a faint warm ring, quiet room, no voices",
  ),
  /* scenes 6–8 */
  (
    "tiptoe_steps",
    4.0,
    "Several small creatures tiptoeing in an exaggerated hush across stone flags at night, tiny careful padded footfalls with little pauses, faint cloth rustle, playful and quiet, no voices",
  ),
  (
    "first_bird",
    5.0,
    "The very first solitary bird of dawn singing a few clear unhurried phrases into cold still morning air, distant and sweet, wide open acoustics, no other birds, no wind",
  ),
  (
    "cart_arrives",
    7.0,
    "A wooden two-wheeled cart approaching on a dirt track, wheels rumbling softly closer over wooden bridge planks then grass, slowing with a final creak of the axle as it comes to a gentle stop, quiet dawn air, no voices",
  ),
]

/* the same sound already exists from Ep6 — copy, never re-buy */
let reused: array<string> = [
  "evening_crickets",
  "door_close_soft",
  "forge_whoosh_land",
  "group_laugh",
  "wind_only_silence",
  "snore_soft_boy",
  "door_creak_small",
  "clap_group",
  "morning_birds_pond",
]

let beds = ["dusk_birds", "evening_crickets", "wind_only_silence", "morning_birds_pond", "first_bird"]

let present = (p: path, minBytes: float): bool =>
  exists(p) && fileSizeMb(p) *. 1.0e6 > minBytes

let main = async () => {
  let dry = envDry == Some("1")
  ensureDirPath(Path(dir ++ "/sfx"))

  let made = ref(0)
  let skipped = ref(0)
  let failed = ref(0)

  reused->Belt.Array.forEach(name => {
    let dst = Path(dir ++ "/sfx/" ++ name ++ ".mp3")
    if present(dst, 2000.0) {
      skipped := skipped.contents + 1
    } else if dry {
      Js.log("  would copy " ++ name ++ " from ep6 (free)")
    } else {
      copyFile(Path(ep6 ++ "/sfx/" ++ name ++ ".mp3"), dst)
      /* already levelled in ep6; carry the marker so it is not re-levelled */
      writeText(Path(dir ++ "/sfx/." ++ name ++ ".leveled"), "carried from ep6")
      Js.log("  copied " ++ name ++ " (free)")
    }
  })

  for i in 0 to Belt.Array.length(effects) - 1 {
    switch Belt.Array.get(effects, i) {
    | None => ()
    | Some((name, secs, prompt)) => {
        let p = Path(dir ++ "/sfx/" ++ name ++ ".mp3")
        if present(p, 2000.0) {
          skipped := skipped.contents + 1
        } else if dry {
          Js.log("  would make " ++ name ++ " (" ++ Js.Float.toString(secs) ++ "s)")
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

    /* fold durations into the durs file the assembler reads */
    let dursPath = Path(dir ++ "/ep7_durs.json")
    let root =
      Js.Json.parseExn(readText(dursPath))
      ->Js.Json.decodeObject
      ->Belt.Option.getWithDefault(Js.Dict.empty())
    let sfxDict =
      Js.Dict.get(root, "sfx")
      ->Belt.Option.flatMap(Js.Json.decodeObject)
      ->Belt.Option.getWithDefault(Js.Dict.empty())
    let all = Belt.Array.concat(effects->Belt.Array.map(((n, _, _)) => n), reused)
    all->Belt.Array.forEach(name => {
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
  Js.log2("SFX FAILED:", e)
  Js.Promise.resolve()
})
->ignore
