/* कुकु और अक्षर — Episode 9 future-dream cold open.

   The picture plan is deliberately isolated from the obsolete Episode 9 table
   read.  Seventeen motion clips form one exact 120-second scene at 24 fps.  A
   replaceable 120-second full mix is placed at time zero; changing that audio
   later never invalidates the picture cut.

   Run from studio/: node src/Kuku_BuildEdlEp9ColdOpen.res.mjs */

open Cinema_Backends

let dir = "../stories/kuku/ep9prod/coldopen"

let silentMix: Kuku_Edl.take = Effect({name: "coldopen_full_mix", at: Some(0.0), duck: false})

let kaFx: Kuku_Edl.fx = {
  png: "glyphs/fx_ka.png",
  at: 2.0,
  scale: 0.20,
  pos: "shield",
}

let clip = (~name: string, ~seconds: float, ~mix: bool=false, ~fx: array<Kuku_Edl.fx>=[]): Kuku_Edl.segment => {
  src: Clip(name),
  dur: Some(seconds),
  inPoint: Some(0.0),
  fadeout: None,
  bridge: false,
  cards: [],
  fx,
  takes: mix ? [silentMix] : [],
  stillWas: None,
}

let clips: array<Kuku_Edl.segment> = [
  clip(~name="co01_attackers_descend", ~seconds=7.0, ~mix=true),
  clip(~name="co02_last_bridge_saboteur", ~seconds=6.0),
  clip(~name="co03_fyuria_reveal", ~seconds=7.0),
  clip(~name="co04_fyuria_catches_tower", ~seconds=7.0),
  clip(~name="co05_fyuria_fire_split", ~seconds=7.0),
  clip(~name="co06_commander_bait", ~seconds=8.0),
  clip(~name="co07_pin_pulled", ~seconds=8.0),
  clip(~name="co08_fyuria_holds_bridge", ~seconds=6.0),
  clip(~name="co09_vesper_fire_lure", ~seconds=8.0),
  clip(~name="co10_vesper_third_current", ~seconds=7.0),
  clip(~name="co11_leda_castor_arrive", ~seconds=7.0),
  clip(~name="co12_castor_inside_crack", ~seconds=9.0),
  clip(~name="co13_bridge_repaired", ~seconds=6.0),
  clip(~name="co14_kuku_glyph_shield", ~seconds=7.0, ~fx=[kaFx]),
  clip(~name="co15_last_family_crosses", ~seconds=6.0),
  clip(~name="co16_five_dragon_formation", ~seconds=7.0),
  clip(~name="co17_child_fyuria_wakes", ~seconds=7.0),
]

let main = () => {
  let scene: Kuku_Edl.scene = {
    name: "s0_future",
    cue: "score/coldopen_silence.mp3",
    scoreVol: 1.0,
    cueIn: 0.0,
    segments: clips,
  }
  Kuku_Edl.save(Path(dir ++ "/ep9_coldopen_edl.json"), {scenes: [scene]})

  let durations = Js.Dict.empty()
  let takes = Js.Dict.empty()
  let sfx = Js.Dict.empty()
  Js.Dict.set(sfx, "coldopen_full_mix", Js.Json.number(120.0))
  Js.Dict.set(durations, "takes", Js.Json.object_(takes))
  Js.Dict.set(durations, "sfx", Js.Json.object_(sfx))
  writeText(
    Path(dir ++ "/ep9_coldopen_durs.json"),
    Js.Json.stringifyWithSpace(Js.Json.object_(durations), 1),
  )

  let total = clips->Belt.Array.reduce(0.0, (sum, segment) =>
    sum +. segment.dur->Belt.Option.getWithDefault(0.0)
  )
  Js.log(
    "ep9_coldopen_edl.json written: " ++
    Belt.Int.toString(Belt.Array.length(clips)) ++
    " clips / " ++
    Js.Float.toFixedWithPrecision(total, ~digits=1) ++
    " seconds / 2880 frames",
  )
}

main()
