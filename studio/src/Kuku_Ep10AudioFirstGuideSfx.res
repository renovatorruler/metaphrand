/* Episode 10 audio-first table-read guide effects.

   Builds 22 deterministic, zero-provider guide cues from already approved Kuku
   series effects. These are editorial placeholders, not final foley. Missing
   cow vocals/hooves and the isolated bronze bell are declared in the manifest
   instead of being imitated by a cast voice or bought from a provider.

   Run from studio/: node src/Kuku_Ep10AudioFirstGuideSfx.res.mjs */

open Cinema_Backends

exception GuideSfxError(string)
let fail = message => raise(GuideSfxError(message))
@val @scope(("process", "exit")) external exit: int => unit = "process.exit"

let root = "../stories/kuku"
let outDir = root ++ "/ep10prod/audio_first_table_read_v4/guide_sfx"
let manifestPath = outDir ++ "/EP10_AUDIO_FIRST_GUIDE_SFX_V1.manifest.json"

type layer = {
  source: string,
  delayMs: int,
  gain: float,
  start: float,
}

type cue = {
  idx: int,
  file: string,
  seconds: float,
  layers: array<layer>,
  limitation: string,
}

let layer = (~source, ~delayMs=0, ~gain=0.55, ~start=0.0) => {
  source: root ++ "/" ++ source,
  delayMs,
  gain,
  start,
}

let cues: array<cue> = [
  {idx: 1, file: "cue_001_4af2449fbfd3319016f4c6248660a2a9692c00c2ab9db183714625e338edb96c.mp3", seconds: 1.8, layers: [layer(~source="ep8prod/sfx/wingbeat_huge.mp3", ~gain=0.42), layer(~source="ep9prod/finale/audio/sfx/SFX20_bell_inside_cloud.mp3", ~delayMs=650, ~gain=0.48)], limitation: "bell is a consistent series bell proxy, not an isolated school-bell recording"},
  {idx: 2, file: "cue_002_b7c99c506e5a5aedf098807bad76e3162e9ee3dfaa40d1d2b822410d18194430.mp3", seconds: 1.6, layers: [layer(~source="ep8prod/sfx/wingbeat_huge.mp3", ~gain=0.32, ~start=1.2), layer(~source="ep5prod/sfx/two_foot_thud.mp3", ~delayMs=850, ~gain=0.55)], limitation: "clean guide wing slowdown and landing"},
  {idx: 3, file: "cue_003_265e4bfe5a309b9092f140dbe255b64daaf7a91b747f41f7cca9288b7f62c85e.mp3", seconds: 3.2, layers: [layer(~source="ep7prod/sfx/cart_rope_creak.mp3", ~gain=0.48), layer(~source="ep5prod/sfx/stone_knock.mp3", ~delayMs=550, ~gain=0.42), layer(~source="ep3prod/sfx/wheels_roll.mp3", ~delayMs=700, ~gain=0.50), layer(~source="ep3prod/sfx/wheels_fast.mp3", ~delayMs=1750, ~gain=0.55)], limitation: "no clean cow moo exists locally; rope, stone and accelerating wheels carry the guide cue"},
  {idx: 4, file: "cue_004_c880bb9ce94a9c0fae94732cc4474821064927e08fd59d96ae2677d8900c1094.mp3", seconds: 2.2, layers: [layer(~source="ep9prod/finale/audio/sfx/SFX20_bell_inside_cloud.mp3", ~gain=0.48), layer(~source="ep8prod/sfx/wingbeat_huge.mp3", ~delayMs=550, ~gain=0.40)], limitation: "series bell proxy also represents the bronze clasp"},
  {idx: 5, file: "cue_005_01ebdfca3b09aad5789e97fd17d16ed5b4e5c72e7b947bb13187eb000726d6d5.mp3", seconds: 2.2, layers: [layer(~source="ep8prod/sfx/wingbeat_huge.mp3", ~gain=0.38), layer(~source="ep3prod/sfx/wheels_fast.mp3", ~gain=0.52), layer(~source="ep3prod/sfx/wheels_roll.mp3", ~delayMs=1150, ~gain=0.42)], limitation: "guide braking transition"},
  {idx: 6, file: "cue_006_16398f69b30a56657b660c594e5d5bae6c127f9cb5b8f09a195cd69451e0a680.mp3", seconds: 1.6, layers: [layer(~source="ep8prod/sfx/plank_khat.mp3", ~gain=0.62), layer(~source="ep6prod/sfx/door_close_soft.mp3", ~delayMs=650, ~gain=0.68)], limitation: "wooden gate guide composite"},
  {idx: 7, file: "cue_007_a3272326c6210671b67c6983edd6ab71ac4170683077c07a75ad85e37cd69d92.mp3", seconds: 1.4, layers: [layer(~source="ep5prod/sfx/stone_knock.mp3", ~gain=0.58), layer(~source="ep5prod/sfx/stone_knock.mp3", ~delayMs=650, ~gain=0.48)], limitation: "two marker-placement guide knocks"},
  {idx: 8, file: "cue_008_7c429b807ef5f3a65c618b291f90d634b969559e4e00296bd4573c72b599e30a.mp3", seconds: 0.65, layers: [layer(~source="ep8prod/sfx/glint_chime.mp3", ~gain=0.48)], limitation: "placed immediately after the spoken line in this table-read guide, not word-aligned"},
  {idx: 9, file: "cue_009_22becc539d2ee2e073293c0984714527b65f32c5d54dcc79bffb8a9885f54d06.mp3", seconds: 0.65, layers: [layer(~source="ep8prod/sfx/glint_chime.mp3", ~gain=0.48)], limitation: "placed immediately after the spoken line in this table-read guide, not word-aligned"},
  {idx: 10, file: "cue_010_91095ed10e45f6ecd188b4c6ea45018f87f9482f9bf9570d2fab5aedbaf1f65e.mp3", seconds: 0.95, layers: [layer(~source="ep8prod/sfx/glint_chime.mp3", ~gain=0.43), layer(~source="ep8prod/sfx/glint_chime.mp3", ~delayMs=460, ~gain=0.43)], limitation: "two pings follow the line in this table-read guide; final mix must word-align them"},
  {idx: 11, file: "cue_011_67a84a8be941fc28988121c8ee10b573079270b07b56d4785913fecd8b78ef07.mp3", seconds: 2.6, layers: [layer(~source="ep9prod/finale/audio/sfx/SFX08_three_pulse.mp3", ~gain=0.45), layer(~source="ep9prod/finale/audio/sfx/SFX12_b_forms.mp3", ~delayMs=450, ~gain=0.42), layer(~source="ep5prod/sfx/letter_lock_stone.mp3", ~delayMs=1350, ~gain=0.60)], limitation: "generic golden-shape formation and stone lock; source filenames refer to Episode 9 but contain no spoken letter"},
  {idx: 12, file: "cue_012_aeb8012e07d0351cde14925f1cafdb818115b664257dbeff1865c15688479e88.mp3", seconds: 1.4, layers: [layer(~source="ep9prod/finale/audio/sfx/SFX13_b_light_to_bracelets.mp3", ~gain=0.52)], limitation: "generic five-place bracelet-light cue with no spoken letter"},
  {idx: 13, file: "cue_013_89c34ec456b3b2bf2f870a336e4d4f90a45b6667e4beceb05157eecf77b66536.mp3", seconds: 1.8, layers: [layer(~source="ep7prod/sfx/cart_rolls_bridge.mp3", ~gain=0.62), layer(~source="ep8prod/sfx/glint_chime.mp3", ~delayMs=700, ~gain=0.16)], limitation: "glint is a temporary guide for the stone-to-gold timbre change"},
  {idx: 14, file: "cue_014_ee9da4957b58f2b0d38d4d7d721cc1a0e89a84b0e204d8b8da3de51310e6093e.mp3", seconds: 1.0, layers: [layer(~source="ep7prod/sfx/cart_rolls_bridge.mp3", ~gain=0.62, ~start=1.2)], limitation: "rear-wheel guide segment"},
  {idx: 15, file: "cue_015_87f2c75fa1a32312fcd37f2deb8a94e956e28f1aade947d46ee23b821cdc74a2.mp3", seconds: 2.2, layers: [layer(~source="ep8prod/sfx/shadow_pass.mp3", ~gain=0.50), layer(~source="ep9prod/finale/audio/sfx/SFX20_bell_inside_cloud.mp3", ~delayMs=650, ~gain=0.30)], limitation: "series bell proxy fades with the overhead pass"},
  {idx: 16, file: "cue_016_36724c9e10920c6c36e32379bc63fc10597c7c4ad91633a14597191a5b3b51c2.mp3", seconds: 2.2, layers: [layer(~source="ep7prod/sfx/cart_arrives.mp3", ~gain=0.62)], limitation: "no clean cow sigh exists locally; stopping cart carries the guide cue"},
  {idx: 17, file: "cue_017_59befccc8b0dd2281b7f9e8b70c732410a992901d41cf590343b72646d52fc66.mp3", seconds: 2.2, layers: [layer(~source="ep9prod/finale/audio/sfx/SFX13_b_light_to_bracelets.mp3", ~gain=0.52), layer(~source="ep4prod/sfx/magic_chime.mp3", ~delayMs=800, ~gain=0.24)], limitation: "temporary shrinking guide uses neutral bracelet/light cues, not the Episode 9 growth cue"},
  {idx: 18, file: "cue_018_ddcb9da4964cc65b9f34ae6d260d503634a0f5fd9bde1b5a6b861506ad0bd605.mp3", seconds: 1.6, layers: [layer(~source="ep3prod/sfx/soft_tumble.mp3", ~delayMs=450, ~gain=0.62)], limitation: "no clean cow moo exists locally; Castor's soft tumble is present"},
  {idx: 19, file: "cue_019_d2327af5ced11fdcf58cfd7c8f4c99cafbb1b350e5f05f887ae0bf39bfc2507e.mp3", seconds: 1.8, layers: [layer(~source="ep8prod/sfx/glint_chime.mp3", ~gain=0.42), layer(~source="ep6prod/sfx/chime_act.mp3", ~delayMs=520, ~gain=0.36)], limitation: "two-tone home-link guide; Dadi distance is applied to her voice locally"},
  {idx: 20, file: "cue_020_a9a6da52f2c92c2a6eb65ab99ab6c74d0f294fddf59a2ce3e8a99297c0117759.mp3", seconds: 1.8, layers: [layer(~source="ep7prod/sfx/soft_tak.mp3", ~gain=0.55), layer(~source="ep5prod/sfx/stone_knock.mp3", ~delayMs=400, ~gain=0.24), layer(~source="ep5prod/sfx/stone_knock.mp3", ~delayMs=750, ~gain=0.22), layer(~source="ep5prod/sfx/stone_knock.mp3", ~delayMs=1100, ~gain=0.20), layer(~source="ep5prod/sfx/stone_knock.mp3", ~delayMs=1450, ~gain=0.18)], limitation: "four softened stone knocks are an explicit temporary hoof proxy"},
  {idx: 21, file: "cue_021_b8a41050a9805ee92e985ec97c85a1a14300c310d5cdd9a29324939a3d0e9486.mp3", seconds: 2.3, layers: [layer(~source="ep8prod/sfx/cheel_land.mp3", ~gain=0.48), layer(~source="ep9prod/finale/audio/sfx/SFX01_claw_on_stone.mp3", ~delayMs=650, ~gain=0.45), layer(~source="ep9prod/finale/audio/sfx/SFX20_bell_inside_cloud.mp3", ~delayMs=1350, ~gain=0.28)], limitation: "series bell proxy"},
  {idx: 22, file: "cue_022_f64ce957196a3adf84b9c8c7888589950ca4159bf6691706deccd4e122b3016f.mp3", seconds: 2.2, layers: [layer(~source="ep5prod/sfx/rope_creak.mp3", ~gain=0.58), layer(~source="ep8prod/sfx/glint_chime.mp3", ~delayMs=1650, ~gain=0.12)], limitation: "quiet glint is a temporary sub-strike bronze resonance; cue hard-cuts before a full bell hit"},
]

let pad3 = n => {
  let s = Belt.Int.toString(n)
  Js.String2.length(s) == 1 ? "00" ++ s : Js.String2.length(s) == 2 ? "0" ++ s : s
}

let renderCue = cue => {
  let target = outDir ++ "/" ++ cue.file
  cue.layers->Belt.Array.forEach(item =>
    if !exists(Path(item.source)) {
      fail("missing guide source for cue " ++ pad3(cue.idx) ++ ": " ++ item.source)
    }
  )
  if !exists(Path(target)) {
    let inputs = cue.layers->Belt.Array.reduce([], (args, item) =>
      Belt.Array.concat(args, ["-i", item.source])
    )
    let labels = cue.layers->Belt.Array.mapWithIndex((index, item) => {
      let label = "a" ++ Belt.Int.toString(index)
      let delay = Belt.Int.toString(item.delayMs)
      let remain = cue.seconds -. Belt.Int.toFloat(item.delayMs) /. 1000.0
      let length = remain > 0.05 ? remain : 0.05
      "[" ++ Belt.Int.toString(index) ++ ":a]atrim=start=" ++ Js.Float.toString(item.start) ++
      ":duration=" ++ Js.Float.toString(length) ++ ",asetpts=PTS-STARTPTS,volume=" ++
      Js.Float.toString(item.gain) ++ ",adelay=delays=" ++ delay ++ ":all=1,apad=pad_dur=" ++
      Js.Float.toString(cue.seconds) ++ "[" ++ label ++ "]"
    })
    let mixInputs = cue.layers->Belt.Array.mapWithIndex((index, _) =>
      "[a" ++ Belt.Int.toString(index) ++ "]"
    )->Js.Array2.joinWith("")
    let filter = labels->Js.Array2.joinWith(";") ++ ";" ++ mixInputs ++
      "amix=inputs=" ++ Belt.Int.toString(Belt.Array.length(cue.layers)) ++
      ":normalize=0:duration=longest,atrim=duration=" ++ Js.Float.toString(cue.seconds) ++
      ",afade=t=out:st=" ++ Js.Float.toString(cue.seconds -. 0.08) ++
      ":d=0.08,alimiter=limit=0.82[out]"
    ffmpeg(Belt.Array.concat(
      ["-y", "-v", "error"],
      Belt.Array.concat(inputs, [
        "-filter_complex", filter, "-map", "[out]", "-ar", "48000", "-ac", "2",
        "-c:a", "libmp3lame", "-b:a", "192k", target,
      ]),
    ))
  }
  let Seconds(actual) = probeDuration(Path(target))
  if actual < cue.seconds -. 0.08 || actual > cue.seconds +. 0.12 {
    fail("cue " ++ pad3(cue.idx) ++ " duration mismatch: " ++ Js.Float.toString(actual))
  }
  (target, actual)
}

let main = () => {
  ensureDirPath(Path(outDir))
  let rows = cues->Belt.Array.map(cue => {
    let (target, actual) = renderCue(cue)
    let row = Js.Dict.empty()
    Js.Dict.set(row, "cue_index", Js.Json.number(Belt.Int.toFloat(cue.idx)))
    Js.Dict.set(row, "path", Js.Json.string(target))
    Js.Dict.set(row, "sha256", Js.Json.string(sha256File(Path(target))))
    Js.Dict.set(row, "duration_seconds", Js.Json.number(actual))
    Js.Dict.set(row, "limitation", Js.Json.string(cue.limitation))
    Js.Dict.set(row, "provider_calls", Js.Json.number(0.0))
    let sources = cue.layers->Belt.Array.map(item => {
      let source = Js.Dict.empty()
      Js.Dict.set(source, "path", Js.Json.string(item.source))
      Js.Dict.set(source, "sha256", Js.Json.string(sha256File(Path(item.source))))
      Js.Dict.set(source, "delay_ms", Js.Json.number(Belt.Int.toFloat(item.delayMs)))
      Js.Dict.set(source, "gain", Js.Json.number(item.gain))
      Js.Dict.set(source, "start_seconds", Js.Json.number(item.start))
      Js.Json.object_(source)
    })
    Js.Dict.set(row, "sources", Js.Json.array(sources))
    Js.Json.object_(row)
  })
  let manifest = Js.Dict.empty()
  Js.Dict.set(manifest, "schema", Js.Json.string("kuku.ep10.audio_first.guide_sfx.v1"))
  Js.Dict.set(manifest, "purpose", Js.Json.string("zero-credit editorial guide effects; declared approximations are not final foley"))
  Js.Dict.set(manifest, "cue_count", Js.Json.number(Belt.Int.toFloat(Belt.Array.length(cues))))
  Js.Dict.set(manifest, "provider_calls", Js.Json.number(0.0))
  Js.Dict.set(manifest, "cues", Js.Json.array(rows))
  let body = Js.Json.object_(manifest)->Js.Json.stringifyWithSpace(1)
  if exists(Path(manifestPath)) {
    if readText(Path(manifestPath)) != body {
      fail("existing guide manifest differs; refusing overwrite")
    }
  } else {
    writeText(Path(manifestPath), body)
  }
  Js.log("EP10 V4 GUIDE SFX -> 22 decoded local cues, zero provider calls")
  Js.log("MANIFEST -> " ++ manifestPath)
}

try main() catch {
| GuideSfxError(message) => {
    Js.log("EP10 V4 GUIDE SFX FAILED: " ++ message)
    exit(1)
  }
}
