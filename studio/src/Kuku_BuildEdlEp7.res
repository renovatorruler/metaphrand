/* कुकु और अक्षर — EP7 «आ की रात», the 2-MINUTE SLICE: scenes 1–2 (lines 1–21).

   Same laws as Kuku_BuildEdlEp6 (its header holds the full history):
   - every dialogue line shows its SPEAKER; the only exceptions are the
     scene-opening establisher, तानसेन's own segments, and the hand-anchored clip
   - a mimicry beat is ITS OWN SEGMENT over a shot of the parrot
   - an effect either OPENS a shot at 0.0 (beds, arrivals) or lands AFTER the
     line's speech (at omitted); nothing may sit under a voice
   - every generated asset appears in the cut (no paid orphans)

   Score cues are REUSED from Ep6 provisionally (cueT5_teach warm for the dusk
   farewell, cueT7_night for the courtyard) — an EP7 score is a later, approved
   spend, and reuse costs nothing.

   Run from studio/:  node src/Kuku_BuildEdlEp7.res.mjs */

open Cinema_Backends

let dir = "../stories/kuku/ep7prod"

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
  | EventAfter(n) => Js.Dict.set(o, "sfx", Js.Json.string(n)) /* no `at` = after speech */
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
    Js.Dict.set(
      o,
      "fx",
      Js.Json.array(
        s.fx->Belt.Array.map(x => {
          let f = Js.Dict.empty()
          Js.Dict.set(f, "png", Js.Json.string(x.png))
          Js.Dict.set(f, "at", Js.Json.number(x.at))
          Js.Dict.set(f, "scale", Js.Json.number(x.scale))
          Js.Dict.set(f, "pos", Js.Json.string(x.pos))
          Js.Json.object_(f)
        }),
      ),
    )
  }
  Js.Json.object_(o)
}

let noFx: array<fxJ> = []

let main = () => {
  let durs = Kuku_Edl.loadDurs(Path(dir ++ "/ep7_durs.json"))
  let sfxD = (n: string): float => Kuku_Edl.sfxDur(durs, n)

  /* ---- s0: the title card — «आ की रात», the letterform composited on it.
     The letter itself first appears in scene 4, outside this slice; the show's
     opening is the one honest place the letterform lives in a scenes-1–2 cut. */
  let s0: array<segJ> = [
    {
      src: "card:a1",
      dur: Some(3.4),
      takes: [],
      fx: [{png: "glyphs/fx_aa.png", at: 0.5, scale: 0.34, pos: "tc"}],
    },
  ]

  /* ---- scene 1: the meadow at dusk, पापा leaves (lines 1–12) -------------- */
  let s1: array<segJ> = [
    /* establisher carries line 1 + the opening ambience + the rope-and-wheel */
    {src: "still:e7_s1_master", dur: None, takes: [Speech(1), Bed("dusk_birds"), EventAfter("cart_rope_creak")], fx: noFx},
    {src: "still:e7_d1_furia", dur: None, takes: [Speech(2)], fx: noFx},
    {src: "still:e7_d1_papa", dur: None, takes: [Speech(3)], fx: noFx},
    {src: "still:e7_d1_furia", dur: None, takes: [Speech(4)], fx: noFx},
    {src: "still:e7_d1_papa", dur: None, takes: [Speech(5)], fx: noFx},
    {src: "still:e7_d1_furia", dur: None, takes: [Speech(6)], fx: noFx},
    /* तानसेन echoes पापा — his own segment, nothing else speaking */
    {
      src: "still:e7_s1_tansen",
      dur: Some(0.3 +. sfxD("mimic_06_PAPA") +. 0.4),
      takes: [EffectAt("mimic_06_PAPA", 0.3)],
      fx: noFx,
    },
    {src: "still:e7_d1_furia", dur: None, takes: [Speech(7)], fx: noFx},
    {src: "still:e7_d1_kuku", dur: None, takes: [Speech(8)], fx: noFx},
    {src: "still:e7_d1_vesper", dur: None, takes: [Speech(9)], fx: noFx},
    {src: "still:e7_d1_dadi", dur: None, takes: [Speech(10)], fx: noFx},
    {src: "still:e7_d1_mitasur", dur: None, takes: [Speech(11)], fx: noFx},
    /* the departure — the one clip, pure picture and rolling wheels */
    {
      src: "clip:c7_rath_depart",
      dur: Some(sfxD("cart_rolls_bridge") +. 0.4),
      takes: [Bed("cart_rolls_bridge")],
      fx: noFx,
    },
    /* कालू's farewell bark on his own shot */
    {src: "still:e7_s1_kalu", dur: Some(0.1 +. sfxD("kalu_bark") +. 0.5), takes: [EffectAt("kalu_bark", 0.1)], fx: noFx},
    /* the family calls after the cart */
    {src: "still:e7_s1_wave", dur: None, takes: [Speech(12)], fx: noFx},
  ]

  /* ---- scene 2: the courtyard, deep evening (lines 13–21) ----------------- */
  let s2: array<segJ> = [
    {src: "still:e7_s2_master", dur: None, takes: [Speech(13), Bed("evening_crickets"), EventAfter("dishes_clink")], fx: noFx},
    {src: "still:e7_d2_vesper", dur: None, takes: [Speech(14)], fx: noFx},
    {src: "still:e7_d2_dadi", dur: None, takes: [Speech(15)], fx: noFx},
    {src: "still:e7_d2_castor", dur: None, takes: [Speech(16)], fx: noFx},
    {src: "still:e7_d2_dadi", dur: None, takes: [Speech(17)], fx: noFx},
    {src: "still:e7_d2_kuku", dur: None, takes: [Speech(18)], fx: noFx},
    {src: "still:e7_d2_furia", dur: None, takes: [Speech(19)], fx: noFx},
    {src: "still:e7_d2_dadi", dur: None, takes: [Speech(20)], fx: noFx},
    /* her door closes; the light under it goes out */
    {src: "still:e7_s2_door", dur: Some(0.2 +. sfxD("door_close_soft") +. 0.8), takes: [EffectAt("door_close_soft", 0.2)], fx: noFx},
    /* कुकु turns to the others: the night's work begins */
    {src: "still:e7_s2_huddle", dur: None, takes: [Speech(21)], fx: noFx},
  ]

  /* ---- scene 3: under the stars — the flying beat, then प twice (22–35) ---- */
  let glyph = (png, at, scale, pos) => {png: "glyphs/" ++ png, at, scale, pos}
  let s3: array<segJ> = [
    /* the sky first, then the boy drinking it in — his line on his own face */
    {src: "still:e7_s3_master", dur: Some(2.8), takes: [Bed("evening_crickets")], fx: noFx},
    {src: "still:e7_d3_vesper", dur: None, takes: [Speech(22)], fx: noFx},
    {src: "still:e7_d3_kuku", dur: None, takes: [Speech(23)], fx: noFx},
    {src: "still:e7_d3_dadi", dur: None, takes: [Speech(24)], fx: noFx},
    {src: "still:e7_d3_kuku", dur: None, takes: [Speech(25)], fx: noFx},
    {src: "still:e7_d3_dadi", dur: None, takes: [Speech(26)], fx: noFx},
    {src: "still:e7_d3_kuku", dur: None, takes: [Speech(27)], fx: noFx},
    {src: "still:e7_d3_dadi", dur: None, takes: [Speech(28)], fx: noFx},
    {src: "still:e7_d3_kuku", dur: None, takes: [Speech(29)], fx: [glyph("fx_pa.png", 0.8, 0.16, "tl")]},
    {src: "still:e7_s3_master", dur: None, takes: [Speech(30)], fx: noFx},
    {src: "still:e7_s3_forge", dur: None, takes: [Speech(31), EventAfter("forge_whoosh_land")], fx: [glyph("fx_pa.png", 1.2, 0.26, "tc")]},
    {src: "still:e7_s3_forge", dur: None, takes: [Speech(32), EventAfter("forge_whoosh_land")], fx: [glyph("fx_pp.png", 1.2, 0.30, "tc")]},
    {src: "still:e7_d3_leda", dur: None, takes: [Speech(33)], fx: [glyph("fx_pp.png", 0.1, 0.22, "tl")]},
    {src: "still:e7_d3_castor", dur: None, takes: [Speech(34)], fx: [glyph("fx_pp.png", 0.1, 0.22, "tl")]},
    {src: "still:e7_d3_kuku", dur: None, takes: [Speech(35)], fx: [glyph("fx_pp.png", 0.1, 0.26, "tc")]},
  ]

  /* ---- scene 4: the मात्रा (36–55) — the letterwork rides composited glyphs -- */
  let s4: array<segJ> = [
    {src: "still:e7_s4_master", dur: None, takes: [Speech(36), Bed("evening_crickets")], fx: noFx},
    {src: "still:e7_d4_castor", dur: None, takes: [Speech(37)], fx: noFx},
    {src: "still:e7_d4_dadi", dur: None, takes: [Speech(38)], fx: [glyph("fx_paa.png", 0.5, 0.20, "tc")]},
    {src: "still:e7_d4_leda", dur: None, takes: [Speech(39)], fx: [glyph("fx_paa.png", 0.1, 0.18, "tl")]},
    {src: "still:e7_d4_dadi", dur: None, takes: [Speech(40)], fx: noFx},
    {src: "still:e7_s4_master", dur: None, takes: [Speech(41), EventAfter("forge_whoosh_land")], fx: noFx},
    {src: "still:e7_d4_castor", dur: None, takes: [Speech(42)], fx: [glyph("fx_matra.png", 0.3, 0.20, "tc")]},
    {src: "still:e7_d4_leda", dur: None, takes: [Speech(43)], fx: [glyph("fx_matra.png", 0.1, 0.16, "tl")]},
    {src: "still:e7_d4_kuku", dur: None, takes: [Speech(44)], fx: [glyph("fx_matra.png", 0.1, 0.16, "tl")]},
    {src: "still:e7_d4_dadi", dur: None, takes: [Speech(45), EventAfter("soft_tak")], fx: noFx},
    {src: "still:e7_s4_join", dur: None, takes: [Speech(46)], fx: [glyph("fx_paa.png", 0.2, 0.30, "tc")]},
    {src: "still:e7_d4_kuku", dur: None, takes: [Speech(47)], fx: [glyph("fx_paa.png", 0.1, 0.18, "tl")]},
    {src: "still:e7_d4_dadi", dur: None, takes: [Speech(48)], fx: noFx},
    {src: "still:e7_s4_join", dur: None, takes: [Speech(49), EventAfter("forge_whoosh_land"), EventAfter("soft_tak")], fx: noFx},
    {src: "still:e7_s4_papa_glow", dur: None, takes: [Speech(50), EventAfter("soft_tak")], fx: [glyph("fx_papa.png", 0.4, 0.30, "tc")]},
    {src: "still:e7_s4_papa_glow", dur: None, takes: [Speech(51)], fx: [glyph("fx_papa.png", 0.1, 0.26, "tc")]},
    {src: "still:e7_d4_dadi", dur: None, takes: [Speech(52)], fx: [glyph("fx_papa.png", 0.1, 0.16, "tl")]},
    {src: "still:e7_d4_dadi", dur: None, takes: [Speech(53)], fx: [glyph("fx_aa.png", 0.4, 0.24, "tc")]},
    {src: "still:e7_d4_leda", dur: None, takes: [Speech(54)], fx: [glyph("fx_aa.png", 0.1, 0.20, "tl")]},
    {src: "still:e7_s4_master", dur: None, takes: [Speech(55)], fx: [glyph("fx_aa.png", 0.2, 0.30, "tc")]},
  ]

  /* ---- scene 5: the doubling game (56–78) --------------------------------- */
  /* तानसेन returns the five syllables in the children's voices, one after the
     other in PERFORMANCE order, each starting when the last one ends */
  let mimicRound = ["mimic_65_KUKU", "mimic_65_FYURIA", "mimic_65_VESPER", "mimic_65_MITASUR", "mimic_65_CASTOR"]
  let mimicTakes = []
  let clock = ref(0.3)
  mimicRound->Belt.Array.forEach(m => {
    let _ = Js.Array2.push(mimicTakes, EffectAt(m, clock.contents))
    clock := clock.contents +. sfxD(m) +. 0.15
  })
  let s5: array<segJ> = [
    {src: "still:e7_s5_master", dur: None, takes: [Speech(56), Bed("evening_crickets")], fx: noFx},
    {src: "still:e7_d5_castor", dur: None, takes: [Speech(57)], fx: [glyph("fx_ka.png", 0.2, 0.20, "tc")]},
    {src: "still:e7_d5_dadi", dur: None, takes: [Speech(58)], fx: noFx},
    {src: "still:e7_d5_vesper", dur: None, takes: [Speech(59)], fx: [glyph("fx_na.png", 0.2, 0.20, "tc")]},
    {src: "still:e7_d5_dadi", dur: None, takes: [Speech(60)], fx: noFx},
    {src: "still:e7_d5_leda", dur: None, takes: [Speech(61)], fx: [glyph("fx_ma.png", 0.2, 0.20, "tc")]},
    {src: "still:e7_d5_dadi", dur: None, takes: [Speech(62)], fx: noFx},
    {src: "still:e7_d5_kuku", dur: None, takes: [Speech(63)], fx: [glyph("fx_ta.png", 0.2, 0.20, "tc")]},
    {src: "still:e7_d5_dadi", dur: None, takes: [Speech(64)], fx: noFx},
    {src: "still:e7_s5_master", dur: None, takes: [Speech(65)], fx: [glyph("fx_ra.png", 0.2, 0.22, "tc")]},
    {src: "still:e7_s5_tansen", dur: Some(clock.contents +. 0.4), takes: mimicTakes, fx: noFx},
    {src: "still:e7_d5_kuku", dur: None, takes: [Speech(66)], fx: noFx},
    {src: "still:e7_d5_dadi", dur: None, takes: [Speech(67)], fx: noFx},
    {src: "still:e7_d5_vesper", dur: None, takes: [Speech(68)], fx: [glyph("fx_raat.png", 0.3, 0.26, "tc")]},
    {src: "still:e7_d5_dadi", dur: None, takes: [Speech(69)], fx: noFx},
    {src: "still:e7_d5_kuku", dur: None, takes: [Speech(70)], fx: [glyph("fx_naam.png", 0.3, 0.26, "tc")]},
    {src: "still:e7_d5_mitasur", dur: None, takes: [Speech(71), EventAfter("group_laugh")], fx: [glyph("fx_kaam.png", 0.3, 0.26, "tc")]},
    {src: "still:e7_d5_kuku", dur: None, takes: [Speech(72), EventAfter("wind_only_silence")], fx: noFx},
    {src: "still:e7_s5_leda_tara", dur: None, takes: [Speech(73)], fx: noFx},
    {src: "still:e7_d5_kuku", dur: None, takes: [Speech(74)], fx: noFx},
    {src: "still:e7_s5_leda_tara", dur: None, takes: [Speech(75)], fx: [glyph("fx_taara.png", 0.5, 0.24, "tc")]},
    {src: "still:e7_d5_vesper", dur: None, takes: [Speech(76)], fx: noFx},
    {src: "still:e7_s5_kuku_realise", dur: None, takes: [Speech(77)], fx: [glyph("fx_taara.png", 0.3, 0.30, "tc")]},
    {src: "still:e7_d5_dadi", dur: None, takes: [Speech(78)], fx: noFx},
  ]

  /* ---- scene 6: the doorstep, deepest night (79–84) ----------------------- */
  let s6: array<segJ> = [
    {src: "still:e7_s6_master", dur: None, takes: [Speech(79), Bed("evening_crickets"), EventAfter("tiptoe_steps")], fx: noFx},
    {src: "still:e7_s6_forge", dur: None, takes: [Speech(80), EventAfter("forge_whoosh_land")], fx: noFx},
    {src: "still:e7_s6_forge", dur: None, takes: [Speech(81), EventAfter("soft_tak")], fx: [glyph("fx_taara.png", 3.0, 0.26, "tc")]},
    {src: "still:e7_s6_star_door", dur: None, takes: [Speech(82)], fx: [glyph("fx_taara.png", 0.2, 0.24, "tc")]},
    {src: "still:e7_d6_vesper", dur: None, takes: [Speech(83)], fx: noFx},
    {src: "still:e7_d6_dadi", dur: None, takes: [Speech(84)], fx: noFx},
  ]

  /* ---- scene 7: dawn, the रथ returns (85–93) ------------------------------ */
  let s7: array<segJ> = [
    {src: "still:e7_s7_master", dur: Some(3.2), takes: [Bed("first_bird")], fx: noFx},
    {src: "still:e7_d7_vesper", dur: None, takes: [Speech(85)], fx: noFx},
    {src: "still:e7_d7_mitasur", dur: None, takes: [Speech(86)], fx: noFx},
    {
      src: "clip:c7_rath_return",
      dur: Some(sfxD("cart_arrives") +. 0.6),
      takes: [Bed("cart_arrives"), EffectAt("kalu_bark", 4.5)],
      fx: noFx,
    },
    {src: "still:e7_d7_papa", dur: None, takes: [Speech(87)], fx: noFx},
    {src: "still:e7_d7_kuku", dur: None, takes: [Speech(88)], fx: noFx},
    {src: "still:e7_s7_star_dawn", dur: None, takes: [Speech(89)], fx: [glyph("fx_taara.png", 0.4, 0.22, "tc")]},
    {src: "still:e7_d7_kuku", dur: None, takes: [Speech(90)], fx: noFx},
    {src: "still:e7_d7_papa", dur: None, takes: [Speech(91)], fx: noFx},
    {src: "still:e7_d7_kuku", dur: None, takes: [Speech(92)], fx: [glyph("fx_aa.png", 0.5, 0.20, "tc")]},
    {src: "still:e7_d7_papa", dur: None, takes: [Speech(93)], fx: noFx},
  ]

  /* ---- scene 8: birthday morning + recap + button (94–115) ---------------- */
  let mimic95: array<takeJ> = []
  let clock95 = ref(0.3)
  ["mimic_95_PAPA", "mimic_95_LEDA"]->Belt.Array.forEach(m => {
    let _ = Js.Array2.push(mimic95, EffectAt(m, clock95.contents))
    clock95 := clock95.contents +. sfxD(m) +. 0.15
  })
  let _ = Js.Array2.push(mimic95, EffectAt("kalu_bark", clock95.contents))
  clock95 := clock95.contents +. sfxD("kalu_bark")
  let recapCard = (n: string, d: float): segJ => {src: "card:" ++ n, dur: Some(d), takes: [], fx: noFx}
  let s8: array<segJ> = [
    {src: "still:e7_d8_furia", dur: None, takes: [Speech(94), EffectAt("door_creak_small", 0.0), Bed("morning_birds_pond")], fx: noFx},
    {src: "still:e7_s8_master", dur: None, takes: [Speech(95), EventAfter("clap_group")], fx: noFx},
    {src: "still:e7_s8_tansen", dur: Some(clock95.contents +. 0.4), takes: mimic95, fx: noFx},
    {src: "still:e7_d8_furia", dur: None, takes: [Speech(96)], fx: noFx},
    {src: "still:e7_d8_kuku", dur: None, takes: [Speech(97)], fx: noFx},
    {src: "still:e7_d8_leda", dur: None, takes: [Speech(98)], fx: noFx},
    {src: "still:e7_d8_furia", dur: None, takes: [Speech(99)], fx: noFx},
    {src: "still:e7_d8_papa", dur: None, takes: [Speech(100)], fx: noFx},
    {src: "still:e7_d8_furia", dur: None, takes: [Speech(101)], fx: noFx},
    {src: "still:e7_d8_furia", dur: None, takes: [Speech(102)], fx: noFx},
    {src: "still:e7_s8_gift", dur: None, takes: [Speech(103)], fx: noFx},
    {src: "still:e7_d8_vesper", dur: None, takes: [Speech(104)], fx: noFx},
    {src: "still:e7_d8_furia", dur: None, takes: [Speech(105)], fx: noFx},
    {src: "still:e7_d8_vesper", dur: None, takes: [Speech(106)], fx: noFx},
    {src: "still:e7_d8_papa", dur: None, takes: [Speech(107)], fx: noFx},
    {src: "still:e7_s8_mata", dur: None, takes: [Speech(108), EventAfter("forge_whoosh_land"), EventAfter("soft_tak")], fx: [glyph("fx_maata.png", 1.5, 0.24, "tc")]},
    {src: "still:e7_d8_dadi", dur: None, takes: [Speech(109)], fx: [glyph("fx_maata.png", 0.1, 0.16, "tl")]},
    {src: "still:e7_d8_papa", dur: None, takes: [Speech(110)], fx: noFx},
    {src: "still:e7_d8_dadi", dur: None, takes: [Speech(111)], fx: noFx},
    {src: "still:e7_s8_niti", dur: None, takes: [Speech(112)], fx: noFx},
    {src: "still:e7_s8_niti", dur: None, takes: [Speech(113)], fx: noFx},
    /* the recap — the doubled frame, then one card per word lived on screen */
    recapCard("r1", 3.0),
    recapCard("r2", 2.4),
    recapCard("r3", 2.4),
    recapCard("r4", 2.4),
    recapCard("r5", 2.4),
    recapCard("r6", 2.4),
    recapCard("r7", 2.4),
    recapCard("r8", 2.4),
    /* the button: वैस्पर asleep on the mangoes */
    {src: "still:e7_s8_vesper_asleep", dur: Some(0.3 +. sfxD("snore_soft_boy") +. 0.5), takes: [EffectAt("snore_soft_boy", 0.3)], fx: noFx},
    {src: "still:e7_d8_furia", dur: None, takes: [Speech(114)], fx: noFx},
    {src: "still:e7_d8_papa", dur: None, takes: [Speech(115)], fx: noFx},
    {src: "still:e7_s8_vesper_asleep", dur: Some(4.0), takes: [Bed("morning_birds_pond")], fx: noFx},
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
      sceneJson("s0_card", "score/cueT7_night.mp3", 0.5, s0),
      sceneJson("s1", "score/cueT5_teach.mp3", 0.35, s1),
      sceneJson("s2", "score/cueT7_night.mp3", 0.4, s2),
      sceneJson("s3", "score/cueT7_night.mp3", 0.4, s3),
      sceneJson("s4", "score/cueT5_teach.mp3", 0.35, s4),
      sceneJson("s5", "score/cueT2_play.mp3", 0.35, s5),
      sceneJson("s6", "score/cueT7_night.mp3", 0.45, s6),
      sceneJson("s7", "score/cueT1_morning.mp3", 0.35, s7),
      sceneJson("s8", "score/cueT2_play.mp3", 0.3, s8),
    ]),
  )
  writeText(Path(dir ++ "/ep7_edl.json"), Js.Json.stringifyWithSpace(Js.Json.object_(root), 1))
  Js.log(
    "ep7_edl.json written: 9 scenes, " ++
    Belt.Int.toString(
      Belt.Array.length(s0) +
      Belt.Array.length(s1) +
      Belt.Array.length(s2) +
      Belt.Array.length(s3) +
      Belt.Array.length(s4) +
      Belt.Array.length(s5) +
      Belt.Array.length(s6) +
      Belt.Array.length(s7) +
      Belt.Array.length(s8),
    ) ++ " segments",
  )
}

main()
