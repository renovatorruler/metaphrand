/* «कर्क की तांती» — the film's colour grade, emitted as .cube 3D LUTs.

   Two levels, exactly as a colourist would work:
     1. ERA CONFORM — one LUT per era, so every photograph of that decade shares
        the same stock character (T-Max mono, faded 90s print, Portra 400/800),
        and the present-day/clinical material sits cooler and flatter than the past.
     2. GLOBAL LOOK — one master film-print LUT laid over the whole timeline
        (filmic shoulder, split-toned shadows/highlights, shaped saturation).

   ffmpeg applies these with `lut3d`; nothing here is a runtime guess — every
   number is in the type-checked table below, so a grade is reproducible and
   diffable rather than a slider someone once dragged. */

type rgb = {r: float, g: float, b: float}

/* One era's colour contract. */
type grade = {
  name: string,
  mono: bool, /* collapse to luminance (the 1976 T-Max era) */
  lift: rgb, /* added to shadows */
  gain: rgb, /* multiplied through */
  gamma: rgb, /* per-channel midtone shaping */
  sat: float, /* 1.0 = unchanged */
  shoulder: float, /* highlight rolloff knee; 1.0 = none */
}

let neutral = {r: 1.0, g: 1.0, b: 1.0}
let zero = {r: 0.0, g: 0.0, b: 0.0}

let eras: array<grade> = [
  {
    /* 1976 — Kodak T-Max 100: true monochrome, deep blacks, luminous highs,
       the faintest silver-sepia warmth of an aged darkroom print. */
    name: "tmax1976",
    mono: true,
    lift: {r: 0.012, g: 0.008, b: 0.004},
    gain: {r: 1.01, g: 0.99, b: 0.95},
    gamma: {r: 0.98, g: 0.98, b: 0.98},
    sat: 0.0,
    shoulder: 0.70,
  },
  {
    /* ~1990 — consumer colour negative, album-aged: warm cast, lifted blacks,
       the magenta drift prints pick up over decades. */
    name: "print1990",
    mono: false,
    lift: {r: 0.030, g: 0.020, b: 0.026},
    gain: {r: 1.00, g: 0.96, b: 0.91},
    gamma: {r: 1.02, g: 1.00, b: 1.03},
    sat: 0.86,
    shoulder: 0.52,
  },
  {
    /* 2005 — Portra 400: warm forgiving skin, creamy highlights,
       shadows leaning very slightly teal. */
    name: "portra400",
    mono: false,
    lift: {r: 0.010, g: 0.014, b: 0.022},
    gain: {r: 1.00, g: 0.97, b: 0.94},
    gamma: {r: 1.00, g: 1.00, b: 1.01},
    sat: 0.94,
    shoulder: 0.60,
  },
  {
    /* 2018+ — Portra 800: golden, a touch more contrast and saturation. */
    name: "portra800",
    mono: false,
    lift: {r: 0.008, g: 0.010, b: 0.018},
    gain: {r: 1.02, g: 0.98, b: 0.94},
    gamma: {r: 0.99, g: 1.00, b: 1.01},
    sat: 0.98,
    shoulder: 0.62,
  },
  {
    /* The present, and every clinical frame: colder, flatter, a hint of the
       green fluorescent ward. The past is warm; now is not. */
    name: "present",
    mono: false,
    lift: {r: 0.006, g: 0.012, b: 0.016},
    gain: {r: 0.95, g: 0.97, b: 1.00},
    gamma: {r: 1.01, g: 1.00, b: 0.99},
    sat: 0.88,
    shoulder: 0.66,
  },
]

/* The master print look, laid over everything after the era conform:
   filmic shoulder, split tone (cool shadows / warm highlights), gentle
   saturation shaping so deep shadows desaturate the way emulsion does. */
let look: grade = {
  name: "look_print",
  mono: false,
  lift: {r: 0.004, g: 0.006, b: 0.012},
  gain: {r: 1.00, g: 1.00, b: 0.99},
  gamma: {r: 1.00, g: 1.00, b: 1.00},
  sat: 1.02,
  shoulder: 0.80,
}

let clamp = (x: float): float => x < 0.0 ? 0.0 : x > 1.0 ? 1.0 : x

/* A true film shoulder: slope is exactly 1 at the knee and falls away above it,
   so bright tones COMPRESS instead of racing to clipped white. Pure white lands
   at knee + 0.632*(1-knee) — a soft printed white, never paper-blank.
   (The earlier version normalised f(1)=1, which gave slope > 1 just past the
   knee and blew the highlights out — worst on the faded-print era.) */
let rolloff = (x: float, knee: float): float =>
  if x <= knee {
    x
  } else {
    let t = (x -. knee) /. (1.0 -. knee)
    knee +. (1.0 -. knee) *. (1.0 -. Js.Math.exp(-.t))
  }

let luma = (r, g, b) => 0.2126 *. r +. 0.7152 *. g +. 0.0722 *. b

let apply = (grade: grade, r: float, g: float, b: float): (float, float, float) => {
  let (r, g, b) = if grade.mono {
    let y = luma(r, g, b)
    (y, y, y)
  } else {
    (r, g, b)
  }
  /* lift -> gain -> gamma */
  let ch = (v, lift, gain, gamma) => {
    let v = clamp(v *. gain +. lift *. (1.0 -. v))
    clamp(Js.Math.pow_float(~base=v, ~exp=gamma))
  }
  let r = ch(r, grade.lift.r, grade.gain.r, grade.gamma.r)
  let g = ch(g, grade.lift.g, grade.gain.g, grade.gamma.g)
  let b = ch(b, grade.lift.b, grade.gain.b, grade.gamma.b)
  /* saturation about luminance, with extra desaturation in the deep shadows */
  let y = luma(r, g, b)
  let shadowDesat = 0.55 +. 0.45 *. Js.Math.min_float(1.0, y /. 0.18)
  let s = grade.sat *. shadowDesat
  let r = clamp(y +. (r -. y) *. s)
  let g = clamp(y +. (g -. y) *. s)
  let b = clamp(y +. (b -. y) *. s)
  (rolloff(r, grade.shoulder), rolloff(g, grade.shoulder), rolloff(b, grade.shoulder))
}

let size = 33

let cube = (grade: grade): string => {
  let out = ref(`TITLE "kark_${grade.name}"\nLUT_3D_SIZE ${Belt.Int.toString(size)}\nDOMAIN_MIN 0 0 0\nDOMAIN_MAX 1 1 1\n`)
  let n = size - 1
  /* .cube order: red fastest, then green, then blue */
  for bi in 0 to n {
    for gi in 0 to n {
      for ri in 0 to n {
        let fr = Belt.Int.toFloat(ri) /. Belt.Int.toFloat(n)
        let fg = Belt.Int.toFloat(gi) /. Belt.Int.toFloat(n)
        let fb = Belt.Int.toFloat(bi) /. Belt.Int.toFloat(n)
        let (r, g, b) = apply(grade, fr, fg, fb)
        let f = (v: float) => Js.Float.toFixedWithPrecision(v, ~digits=6)
        out := out.contents ++ `${f(r)} ${f(g)} ${f(b)}\n`
      }
    }
  }
  out.contents
}

@module("fs") external writeFileSync: (string, string) => unit = "writeFileSync"
@module("fs") external mkdirSync: (string, {"recursive": bool}) => unit = "mkdirSync"

let dir = "/Users/dusty/Dev/metaphrand/stories/songbook/kark-mv/luts/"

let emit = () => {
  mkdirSync(dir, {"recursive": true})
  eras->Belt.Array.forEach(e => {
    writeFileSync(dir ++ e.name ++ ".cube", cube(e))
    Js.log("emitted " ++ e.name ++ ".cube")
  })
  writeFileSync(dir ++ look.name ++ ".cube", cube(look))
  Js.log("emitted " ++ look.name ++ ".cube")
}

emit()
