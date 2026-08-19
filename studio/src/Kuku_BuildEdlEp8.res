/* कुकु और अक्षर — EP8 «च से चील», FULL EPISODE EDL, v2 screenplay (approved
   2026-08-10). Line numbers match the v2 manifest exactly — the ★ review copy
   parses to 92 events across दृश्य 0–9 with 3-क folded into scene 3's block.

   Laws as ever: every dialogue line shows its speaker; effects open a shot at
   0.0 or land after speech; every paid asset appears; one kathā sentence = one
   image in the cold open; the recap speaks each word ON its own card.

   Run from studio/:  node src/Kuku_BuildEdlEp8.res.mjs */

open Cinema_Backends

let dir = "../stories/kuku/ep8prod"

type takeJ = Speech(int) | Bed(string) | EventAfter(string) | EffectAt(string, float)

let takeJson = (t: takeJ): Js.Json.t => {
  let o = Js.Dict.empty()
  switch t {
  | Speech(i) => Js.Dict.set(o, "i", Js.Json.number(Belt.Int.toFloat(i)))
  | Bed(n) => {
      Js.Dict.set(o, "sfx", Js.Json.string(n))
      Js.Dict.set(o, "at", Js.Json.number(0.0))
      Js.Dict.set(o, "duck", Js.Json.boolean(false))
    }
  | EventAfter(n) => Js.Dict.set(o, "sfx", Js.Json.string(n))
  | EffectAt(n, at) => {
      Js.Dict.set(o, "sfx", Js.Json.string(n))
      Js.Dict.set(o, "at", Js.Json.number(at))
    }
  }
  Js.Json.object_(o)
}

type fxJ = {png: string, at: float, scale: float, pos: string}
type segJ = {src: string, dur: option<float>, takes: array<takeJ>, fx: array<fxJ>}

let segJson = (s: segJ): Js.Json.t => {
  let o = Js.Dict.empty()
  Js.Dict.set(o, "src", Js.Json.string(s.src))
  switch s.dur {
  | Some(d) => Js.Dict.set(o, "dur", Js.Json.number(d))
  | None => ()
  }
  Js.Dict.set(o, "takes", Js.Json.array(s.takes->Belt.Array.map(takeJson)))
  if Belt.Array.length(s.fx) > 0 {
    Js.Dict.set(o, "fx", Js.Json.array(s.fx->Belt.Array.map(x => {
      let g = Js.Dict.empty()
      Js.Dict.set(g, "png", Js.Json.string(x.png))
      Js.Dict.set(g, "at", Js.Json.number(x.at))
      Js.Dict.set(g, "scale", Js.Json.number(x.scale))
      Js.Dict.set(g, "pos", Js.Json.string(x.pos))
      Js.Json.object_(g)
    })))
  }
  Js.Json.object_(o)
}

let noFx: array<fxJ> = []

let main = () => {
  let durs = Kuku_Edl.loadDurs(Path(dir ++ "/ep8_durs.json"))
  let sfxD = (n: string): float => Kuku_Edl.sfxDur(durs, n)
  let glyph = (png, at, scale, pos) => {png: "glyphs/" ++ png, at, scale, pos}

  /* ---- दृश्य 0 (1–8): कथा-आरंभ — one kathā sentence per image -------------- */
  let s0: array<segJ> = [
    {src: "still:e8_s0_peak", dur: Some(3.2), takes: [Bed("mountain_wind_high"), EffectAt("eagle_cry_far", 0.3)], fx: noFx},
    {src: "still:e8_s0_peak", dur: None, takes: [Speech(1)], fx: [glyph("fx_cheel.png", 1.0, 0.22, "tl")]},
    {src: "still:e8_s0_snow", dur: None, takes: [Speech(2), Bed("snow_settle")], fx: noFx},
    {src: "still:e8_s0_seasons", dur: None, takes: [Speech(3)], fx: noFx},
    {src: "still:e8_s0_rishi", dur: None, takes: [Speech(4)], fx: noFx},
    {src: "still:e8_s0_rishi", dur: None, takes: [Speech(5)], fx: noFx},
    {src: "still:e8_s0_boon", dur: None, takes: [Speech(6)], fx: noFx},
    {src: "still:e8_s0_boon", dur: None, takes: [Speech(7)], fx: noFx},
    {src: "clip:c8_boon_settle", dur: Some(4.8), takes: [EffectAt("boon_shimmer", 0.4)], fx: noFx},
    {src: "clip:c8_cheel_circle", dur: Some(4.8), takes: [Bed("wingbeat_huge")], fx: noFx},
    {src: "still:e8_s0_peak", dur: None, takes: [Speech(8)], fx: noFx},
    /* the «च से चील» card moved into the J-cut title build (Kuku_AssembleEp8Slice)
       — the title music starts under the card, so the card belongs to the title */
  ]

  /* ---- दृश्य 1 (9–14): the courtyard morning ------------------------------ */
  let s1: array<segJ> = [
    {src: "still:e8_s1_master", dur: Some(3.0), takes: [Bed("morning_birds_pond"), EffectAt("morning_dishes", 0.5)], fx: noFx},
    {src: "still:e8_d1_dadi", dur: None, takes: [Speech(9)], fx: [glyph("fx_cha.png", 0.8, 0.22, "tl")]},
    {src: "still:e8_d1_castor", dur: None, takes: [Speech(10)], fx: noFx},
    {src: "clip:c8_shadow_pass", dur: Some(4.8), takes: [EffectAt("shadow_pass", 0.6)], fx: noFx},
    {src: "still:e8_d1_leda", dur: None, takes: [Speech(11)], fx: noFx},
    {src: "still:e8_d1_fyuria", dur: None, takes: [Speech(12)], fx: noFx},
    /* तानसेन's strange borrowed cry — the नक़ल is real audio now, his own beat */
    {src: "still:e8_s1_tansen", dur: Some(0.3 +. sfxD("mimic_12_CHEEL") +. 0.6), takes: [EffectAt("mimic_12_CHEEL", 0.3)], fx: noFx},
    {src: "still:e8_d1_kuku", dur: None, takes: [Speech(13)], fx: noFx},
    {src: "still:e8_d1_dadi", dur: None, takes: [Speech(14)], fx: noFx},
  ]

  /* ---- दृश्य 2 (15–21): the shiny trail ----------------------------------- */
  let s2: array<segJ> = [
    {src: "still:e8_s2_spoon", dur: None, takes: [Speech(15), Bed("morning_birds_pond"), EventAfter("glint_chime"), EventAfter("running_steps_arrive")], fx: noFx},
    {src: "still:e8_d2_leda", dur: None, takes: [Speech(16), EventAfter("glint_chime")], fx: noFx},
    {src: "still:e8_d2_vesper", dur: None, takes: [Speech(17)], fx: noFx},
    {src: "clip:c8_trail_follow", dur: Some(4.8), takes: [EffectAt("glint_chime", 1.0), EffectAt("glint_chime", 3.2)], fx: noFx},
    {src: "still:e8_d2_kuku", dur: None, takes: [Speech(18)], fx: noFx},
    {src: "clip:c8_climb", dur: Some(4.8), takes: [Bed("group_steps_field")], fx: noFx},
    {src: "still:e8_d2_castor", dur: None, takes: [Speech(19)], fx: noFx},
    {src: "still:e8_d2_fyuria", dur: None, takes: [Speech(20)], fx: noFx},
    {src: "clip:c8_nest_reveal", dur: Some(4.8), takes: [Bed("wind_only_silence")], fx: noFx},
    {src: "clip:c8_plank_falls", dur: Some(4.8), takes: [EffectAt("plank_khat", 0.8)], fx: noFx},
    {src: "still:e8_d2_vesper", dur: None, takes: [Speech(21)], fx: noFx},
  ]

  /* ---- दृश्य 3 (22–28): she lands ----------------------------------------- */
  let s3: array<segJ> = [
    {src: "clip:c8_cheel_land", dur: Some(4.8), takes: [Bed("cheel_land")], fx: noFx},
    {src: "still:e8_d3_cheel", dur: None, takes: [Speech(22)], fx: [glyph("fx_chaal.png", 1.0, 0.22, "tl")]},
    {src: "still:e8_d3_kuku", dur: None, takes: [Speech(23)], fx: noFx},
    {src: "still:e8_d3_cheel", dur: None, takes: [Speech(24)], fx: noFx},
    {src: "still:e8_d3_fyuria", dur: None, takes: [Speech(25)], fx: noFx},
    {src: "still:e8_d3_cheel", dur: None, takes: [Speech(26)], fx: noFx},
    {src: "still:e8_s3_cornered", dur: None, takes: [Speech(27)], fx: noFx},
    {src: "still:e8_d3_kuku", dur: None, takes: [Speech(28)], fx: noFx},
    {src: "clip:c8_lift_off", dur: Some(4.8), takes: [EffectAt("wingbeat_huge", 0.4)], fx: noFx},
  ]

  /* ---- दृश्य 3-क + 4 (29–49): desperation then the team fights — one crag,
     one contiguous stretch of action, one scene block so every d4 still is
     scene-correct ---- */
  let s4a: array<segJ> = [
    {src: "still:e8_d4_castor", dur: None, takes: [Speech(29), EventAfter("running_steps_arrive")], fx: noFx},
    /* they peer down at the broken plank, far below */
    {src: "still:e8_s3a_gap", dur: None, takes: [Speech(30)], fx: noFx},
    {src: "still:e8_s3a_gap", dur: None, takes: [Speech(31)], fx: noFx},
    {src: "still:e8_d4_leda", dur: None, takes: [Speech(32)], fx: noFx},
    {src: "still:e8_d4_vesper", dur: None, takes: [Speech(33)], fx: noFx},
    /* all five scream into the valley; the echo answers, then nothing */
    {src: "still:e8_s3a_scream", dur: None, takes: [Speech(34), EventAfter("valley_echo_scatter")], fx: noFx},
    {src: "still:e8_d4_cheel", dur: None, takes: [Speech(35)], fx: noFx},
    {src: "still:e8_d4_kuku", dur: None, takes: [Speech(36)], fx: noFx},
    {src: "still:e8_d4_leda", dur: None, takes: [Speech(37), Bed("wind_only_silence")], fx: [glyph("fx_chakkar.png", 1.2, 0.22, "tl")]},
    {src: "still:e8_d4_kuku", dur: None, takes: [Speech(38)], fx: noFx},
    {src: "still:e8_d4_castor", dur: None, takes: [Speech(39)], fx: noFx},
    {src: "still:e8_s4_crack", dur: None, takes: [Speech(40)], fx: noFx},
    {src: "still:e8_s4_bridge", dur: None, takes: [Speech(41), EventAfter("sparks_forge")], fx: noFx},
    {src: "still:e8_s4_bridge", dur: None, takes: [Speech(42)], fx: noFx},
    {src: "clip:c8_letters_scatter", dur: Some(4.8), takes: [EffectAt("sparks_scatter", 0.3)], fx: noFx},
    /* the bridge's failure explained out loud — her wing-wind did it */
    {src: "still:e8_d4_castor", dur: None, takes: [Speech(43)], fx: noFx},
    {src: "still:e8_d4_kuku", dur: None, takes: [Speech(44)], fx: noFx},
    {src: "still:e8_d4_cheel", dur: None, takes: [Speech(45)], fx: noFx},
    {src: "still:e8_d4_kuku", dur: None, takes: [Speech(46), EventAfter("sparks_forge")], fx: [glyph("fx_chup.png", 1.2, 0.30, "tc")]},
    {src: "still:e8_d4_cheel", dur: None, takes: [Speech(47)], fx: [glyph("fx_chup.png", 0.1, 0.16, "tl")]},
    {src: "still:e8_d4_vesper", dur: None, takes: [Speech(48)], fx: noFx},
    {src: "still:e8_d4_kuku", dur: None, takes: [Speech(49)], fx: noFx},
  ]

  /* ---- दृश्य 5 (50–57): तानसेन की चाल — gambit, distraction, delivery ------ */
  let s5: array<segJ> = [
    {src: "still:e8_d5_kuku", dur: None, takes: [Speech(50)], fx: noFx},
    {src: "still:e8_d5_vesper", dur: None, takes: [Speech(51)], fx: noFx},
    /* फ्यूरिया's plan spoken before she runs — she is the distraction */
    {src: "still:e8_d4_fyuria", dur: None, takes: [Speech(52)], fx: noFx},
    {src: "still:e8_d5_leda", dur: None, takes: [Speech(53)], fx: noFx},
    {src: "still:e8_s4_counter", dur: None, takes: [Speech(54)], fx: noFx},
    {src: "still:e8_d5_fyuria", dur: None, takes: [Speech(55)], fx: noFx},
    {src: "clip:c8_tansen_launch", dur: Some(4.8), takes: [EffectAt("parrot_wingbeat", 0.2)], fx: noFx},
    {src: "clip:c8_tansen_dash", dur: Some(4.8), takes: [Bed("wind_only_silence")], fx: noFx},
    /* the delivery: he replays what he heard, voice by voice */
    {src: "still:e8_s5_delivery", dur: None, takes: [Speech(56)], fx: noFx},
    {
      src: "still:e8_s5_delivery",
      dur: Some(0.3 +. sfxD("mimic_56_KUKU") +. 0.25 +. sfxD("mimic_56_CHEEL") +. 0.25 +. sfxD("mimic_56_LEDA") +. 0.6),
      takes: [
        EffectAt("mimic_56_KUKU", 0.3),
        EffectAt("mimic_56_CHEEL", 0.3 +. sfxD("mimic_56_KUKU") +. 0.25),
        EffectAt("mimic_56_LEDA", 0.3 +. sfxD("mimic_56_KUKU") +. 0.25 +. sfxD("mimic_56_CHEEL") +. 0.25),
      ],
      fx: noFx,
    },
    {src: "still:e8_s5_delivery", dur: None, takes: [Speech(57)], fx: noFx},
    {src: "clip:c8_kalu_dadi_climb", dur: Some(4.8), takes: [EffectAt("dadi_stick_steps", 0.2)], fx: noFx},
  ]

  /* ---- दृश्य 6 (58–67): the dive, the miss, the tail ---------------------- */
  let s6: array<segJ> = [
    {src: "still:e8_d6_cheel", dur: None, takes: [Speech(58)], fx: noFx},
    {src: "clip:c8_stoop", dur: Some(4.8), takes: [], fx: noFx},
    {src: "still:e8_s6_dadi_steps", dur: None, takes: [Speech(59)], fx: noFx},
    {src: "still:e8_d6_cheel", dur: None, takes: [Speech(60), EventAfter("wingbeat_huge")], fx: noFx},
    {src: "still:e8_d6_dadi", dur: None, takes: [Speech(61)], fx: noFx},
    /* first strike — the miss; she is old, and it costs her */
    {src: "still:e8_s6_miss", dur: Some(0.3 +. sfxD("tail_whoosh_miss") +. 0.7), takes: [EffectAt("tail_whoosh_miss", 0.3)], fx: noFx},
    {src: "still:e8_d6_cheel", dur: None, takes: [Speech(62)], fx: noFx},
    {src: "still:e8_d6_kuku", dur: None, takes: [Speech(63)], fx: noFx},
    /* the second strike lands */
    {src: "clip:c8_dadi_tail", dur: Some(4.8), takes: [EffectAt("tail_whoosh_strike", 1.2)], fx: noFx},
    {src: "still:e8_d6_cheel", dur: None, takes: [Speech(64)], fx: noFx},
    {src: "clip:c8_tumble_away", dur: Some(4.8), takes: [EffectAt("feathers_rain", 0.4)], fx: noFx},
    {src: "still:e8_d6_dadi", dur: None, takes: [Speech(65)], fx: noFx},
    /* तानसेन mocks the beaten queen in her own voice */
    {src: "still:e8_s1_tansen", dur: Some(0.3 +. sfxD("mimic_65_CHEEL") +. 0.5), takes: [EffectAt("mimic_65_CHEEL", 0.3)], fx: noFx},
    {src: "still:e8_d6_fyuria", dur: None, takes: [Speech(66)], fx: noFx},
    {src: "still:e8_d6_dadi", dur: None, takes: [Speech(67)], fx: noFx},
  ]

  /* ---- दृश्य 7 (68–79): the कथा ------------------------------------------- */
  let s7: array<segJ> = [
    {src: "still:e8_s7_circle", dur: Some(3.0), takes: [Bed("evening_crickets")], fx: noFx},
    {src: "still:e8_d7_kuku", dur: None, takes: [Speech(68)], fx: noFx},
    {src: "still:e8_d7_dadi_katha", dur: None, takes: [Speech(69)], fx: noFx},
    {src: "still:e8_d7_dadi_katha", dur: None, takes: [Speech(70)], fx: noFx},
    {src: "still:e8_s7_flash_flying", dur: None, takes: [Speech(71)], fx: noFx},
    {src: "still:e8_s7_flash_road", dur: None, takes: [Speech(72)], fx: noFx},
    {src: "still:e8_s7_flash_rath", dur: None, takes: [Speech(73)], fx: noFx},
    {src: "still:e8_d7_dadi_katha", dur: None, takes: [Speech(74)], fx: noFx},
    {src: "still:e8_d7_vesper", dur: None, takes: [Speech(75)], fx: noFx},
    {src: "still:e8_d7_leda", dur: None, takes: [Speech(76)], fx: noFx},
    {src: "still:e8_d7_dadi_katha", dur: None, takes: [Speech(77)], fx: noFx},
    {src: "still:e8_d7_kuku", dur: None, takes: [Speech(78)], fx: noFx},
    {src: "still:e8_s7_dadi_sky", dur: None, takes: [Speech(79)], fx: noFx},
  ]

  /* ---- दृश्य 8 (80–92): the walk down + recap, each word ON its card ------ */
  let recap = (nm: string, i: int): segJ => {src: "card:" ++ nm, dur: None, takes: [Speech(i)], fx: noFx}
  let s8: array<segJ> = [
    {src: "clip:c8_walk_down", dur: Some(4.8), takes: [Bed("evening_crickets"), EffectAt("dadi_stick_steps", 0.4)], fx: noFx},
    {src: "still:e8_d8_dadi", dur: None, takes: [Speech(80)], fx: noFx},
    {src: "still:e8_d8_fyuria", dur: None, takes: [Speech(81)], fx: noFx},
    {src: "still:e8_d8_dadi", dur: None, takes: [Speech(82)], fx: noFx},
    {src: "still:e8_d8_kuku", dur: None, takes: [Speech(83)], fx: noFx},
    {src: "still:e8_d8_dadi", dur: None, takes: [Speech(84)], fx: noFx},
    {src: "still:e8_d8_leda", dur: None, takes: [Speech(85), EventAfter("group_laugh")], fx: noFx},
    {src: "still:e8_s8_rath_look", dur: Some(3.2), takes: [], fx: noFx},
    {src: "still:e8_d8_dadi", dur: None, takes: [Speech(86)], fx: noFx},
    recap("r2", 87),
    recap("r3", 88),
    recap("r4", 89),
    recap("r5", 90),
    recap("r6", 91),
    recap("r7", 92),
    {src: "card:r8", dur: Some(3.0), takes: [], fx: noFx},
  ]

  /* ---- दृश्य 9: अंतिम झलक ------------------------------------------------- */
  let s9: array<segJ> = [
    {src: "clip:c8_ridge_button", dur: Some(4.8), takes: [Bed("wind_only_silence"), EffectAt("eagle_cry_far", 1.4)], fx: noFx},
    {src: "clip:c8_kalu_growl", dur: Some(4.8), takes: [Bed("evening_crickets"), EffectAt("mimic_92_CHEEL", 0.6)], fx: noFx},
  ]

  let sceneJson = (name: string, cue: string, vol: float, segs: array<segJ>): Js.Json.t => {
    let o = Js.Dict.empty()
    Js.Dict.set(o, "name", Js.Json.string(name))
    Js.Dict.set(o, "cue", Js.Json.string(cue))
    Js.Dict.set(o, "score_vol", Js.Json.number(vol))
    Js.Dict.set(o, "segments", Js.Json.array(segs->Belt.Array.map(segJson)))
    Js.Json.object_(o)
  }

  let root = Js.Dict.empty()
  Js.Dict.set(
    root,
    "scenes",
    Js.Json.array([
      sceneJson("s0_cold", "score/cueC1_tapasya.mp3", 0.55, s0),
      sceneJson("s1", "score/cueC2_shadow.mp3", 0.45, s1),
      sceneJson("s2", "score/cueC2_shadow.mp3", 0.4, s2),
      sceneJson("s3", "score/cueC3_cheel.mp3", 0.5, s3),
      sceneJson("s4", "score/cueC4_fight.mp3", 0.45, s4a),
      sceneJson("s5", "score/cueC4_fight.mp3", 0.4, s5),
      sceneJson("s6", "score/cueC5_rescue.mp3", 0.5, s6),
      sceneJson("s7", "score/cueC6_katha.mp3", 0.4, s7),
      sceneJson("s8", "score/cueC6_katha.mp3", 0.35, s8),
      sceneJson("s9", "score/cueC3_cheel.mp3", 0.45, s9),
    ]),
  )
  writeText(Path(dir ++ "/ep8_edl.json"), Js.Json.stringifyWithSpace(Js.Json.object_(root), 1))
  let total =
    Belt.Array.length(s0) + Belt.Array.length(s1) + Belt.Array.length(s2) +
    Belt.Array.length(s3) + Belt.Array.length(s4a) +
    Belt.Array.length(s5) + Belt.Array.length(s6) + Belt.Array.length(s7) +
    Belt.Array.length(s8) + Belt.Array.length(s9)
  Js.log("ep8_edl.json written: 11 scenes, " ++ Belt.Int.toString(total) ++ " segments")
}

main()
