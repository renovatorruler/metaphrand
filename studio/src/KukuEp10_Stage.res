// KukuEp10_Stage.res — the one courtyard and everything that happens on it
// that is not a puppet: its light, its lamp and flame, its wind and smoke,
// the door and the wall as masks, the letter द and its light, and the rules
// that turn a script line into puppet motion. No main: scene modules open this.
//
// The law of the stage: one plate, graded in code; one lamp, whose flame is
// drawn by code in every state; the letter is the true font glyph, never
// generated; every line plays on its own recorded take with the mouth on its
// visemes. A scene is a list of layers and a list of cues, and renders the
// same bytes every time.

@module("fs") external readFileSync: (string, string) => string = "readFileSync"
@module("fs") external existsSync: string => bool = "existsSync"

open Puppet
open KukuEp10_Rigs

/* ------------------------------------------------- the plate's geometry */
/* Everything at stage scale, 1280x720. Measured on the plate: the door leaf
   and its frame fill the left edge to x 300; the wall runs from y 205 (its
   top) to y 445 (where the flagstones begin); the niche is x 545..750,
   y 250..410 with its shelf at 400; the flame stands on the shelf at 603. */
let doorPoly = [(0.0, 0.0), (300.0, 0.0), (300.0, 700.0), (0.0, 720.0)]
let wallPoly = [(300.0, 200.0), (1280.0, 200.0), (1280.0, 448.0), (300.0, 448.0)]
let valleyPoly = [(300.0, 0.0), (1280.0, 0.0), (1280.0, 207.0), (300.0, 207.0)]
let lampBase = (603.0, 390.0)
let nicheCentre = (648.0, 330.0)

/* A MASK LAYER: the plate itself, clipped to a polygon, drawn above the
   puppets — so a puppet drawn below it passes behind the door or beyond the
   wall. The plate is loaded once; clipping is per frame and cheap. */
let maskLayer = async (~z, ~poly) => {
  let img = await loadImage(ImagePath(root ++ "sets/courtyard_plate.png"))
  {
    z,
    draw: (c, _t) => {
      save(c)
      beginPath(c)
      Js.Array2.forEachi(poly, ((x, y), i) => i == 0 ? moveTo(c, x, y) : lineTo(c, x, y))
      closePath(c)
      clip(c)
      drawImageSized(c, img, 0.0, 0.0, 1280.0, 720.0)
      restore(c)
    },
  }
}
let doorMask = z => maskLayer(~z, ~poly=doorPoly)
let wallMask = z => maskLayer(~z, ~poly=wallPoly)

/* ------------------------------------------------------------- the lamp */
/* The bowl is the lower part of the lit patch (the flame cut off), so the
   same clay bowl stands in the niche in every state; the flame itself is
   drawn by code, and so it can lie down, thin to blue, and die. */
/* the bowl's top-left on the shelf; `at` lets a scene carry it (दादी brings
   it in; कुकु carries it the next evening) — the flame base follows it */
let shelfBowl = (548.0, 353.0)
let bowlLayer = async (~at: sec => (float, float)=_ => shelfBowl, ~shown: sec => bool=_ => true, z) => {
  let img = await loadImage(ImagePath(root ++ "cutout/sprites/lamp_lit.png"))
  /* the patch is 234x169 drawn at 110x79; the flame ends at patch row 78, so
     the bowl is rows 78..169 */
  {
    z,
    draw: (c, t) => {
      if shown(t) {
        let (bx, by) = at(t)
        save(c)
        beginPath(c)
        moveTo(c, bx, by +. 78.0 *. 0.47)
        lineTo(c, bx +. 110.0, by +. 78.0 *. 0.47)
        lineTo(c, bx +. 110.0, by +. 79.0)
        lineTo(c, bx, by +. 79.0)
        closePath(c)
        clip(c)
        drawImageSized(c, img, bx, by, 110.0, 79.0)
        restore(c)
      }
    },
  }
}
/* where the flame stands for a bowl drawn at a top-left */
let flameBaseOf = ((bx, by)) => (bx +. 55.0, by +. 37.0)

/* the flame at an instant: how tall (1 = the lit patch's), how far it leans
   (-1..1, positive toward the camera-right), how blue (0 = gold, 1 = a thin
   blue tongue), how bright its glow */
type flame = {height: float, lean: float, blue: float, glowStrength: float}
let flameLit = {height: 1.0, lean: 0.0, blue: 0.0, glowStrength: 0.5}
let flameOut = {height: 0.0, lean: 0.0, blue: 0.0, glowStrength: 0.0}
/* a living flame: the lit state with a small flicker on two incommensurate rhythms */
let flicker = (base, t) => {
  let tv = secf(t)
  {
    ...base,
    height: base.height *. (1.0 +. 0.06 *. Js.Math.sin(9.0 *. tv) +. 0.04 *. Js.Math.sin(23.0 *. tv)),
    lean: base.lean +. 0.05 *. Js.Math.sin(7.0 *. tv),
  }
}
let flameLayer = (~z, ~flame: sec => flame, ~base: sec => (float, float)=_ => lampBase) => {
  z,
  draw: (c, t) => {
    let f = flame(t)
    if f.height > 0.02 {
      let (bx, by) = base(t)
      let h = 44.0 *. f.height
      let w = 16.0 *. (1.0 -. 0.4 *. f.blue) *. (0.6 +. 0.4 *. f.height)
      save(c)
      translate(c, bx, by)
      rotate(c, f.lean *. 0.9)
      /* the glow first, added */
      setCompositeOp(c, "lighter")
      setGlobalAlpha(c, f.glowStrength *. (0.5 +. 0.5 *. f.height))
      let g = createRadialGradient(c, 0.0, -.h *. 0.45, 0.0, 0.0, -.h *. 0.45, 110.0 *. f.height +. 30.0)
      addColorStop(g, 0.0, f.blue > 0.5 ? "rgba(140,190,255,1)" : "rgba(255,190,100,1)")
      addColorStop(g, 1.0, "rgba(0,0,0,0)")
      setFillGradient(c, g)
      fillRect(c, -100.0, -.h -. 100.0, 200.0, h +. 200.0)
      /* the tongue: a teardrop, gold core to orange edge, or blue when starved */
      setCompositeOp(c, "source-over")
      setGlobalAlpha(c, 1.0)
      let outer = f.blue > 0.5 ? "rgba(110,170,255,0.95)" : "rgba(255,140,40,0.95)"
      let inner = f.blue > 0.5 ? "rgba(220,240,255,1)" : "rgba(255,245,180,1)"
      let tongue = (wf, hf, colour) => {
        setFillStyle(c, colour)
        beginPath(c)
        moveTo(c, 0.0, 0.0)
        bezierCurveTo(c, w *. wf, -.h *. 0.35 *. hf, w *. wf *. 0.6, -.h *. 0.8 *. hf, 0.0, -.h *. hf)
        bezierCurveTo(c, -.w *. wf *. 0.6, -.h *. 0.8 *. hf, -.w *. wf, -.h *. 0.35 *. hf, 0.0, 0.0)
        closePath(c)
        fill(c)
      }
      tongue(1.0, 1.0, outer)
      tongue(0.55, 0.7, inner)
      restore(c)
    }
  },
}

/* SMOKE: after the flame dies, a few soft grey puffs rise from the shelf and
   thin out. Deterministic: puff i is born at t0 + i*0.35 s. */
let smokeLayer = (~z, ~from: float, ~puffs=7) => {
  z,
  draw: (c, t) => {
    let tv = secf(t)
    let (bx, by) = lampBase
    for i in 0 to puffs - 1 {
      let born = from +. Belt.Int.toFloat(i) *. 0.35
      let age = tv -. born
      if age > 0.0 && age < 4.0 {
        let u = age /. 4.0
        let drift = Js.Math.sin(Belt.Int.toFloat(i) *. 1.7 +. age *. 1.3) *. 14.0 *. u
        let x = bx +. drift +. Belt.Int.toFloat(mod(i, 3)) *. 3.0
        let y = by -. 8.0 -. age *. 34.0
        let r = 6.0 +. u *. 26.0
        save(c)
        setGlobalAlpha(c, 0.28 *. (1.0 -. u) *. (age < 0.3 ? age /. 0.3 : 1.0))
        let g = createRadialGradient(c, x, y, 0.0, x, y, r)
        addColorStop(g, 0.0, "rgba(120,120,130,1)")
        addColorStop(g, 1.0, "rgba(120,120,130,0)")
        setFillGradient(c, g)
        fillRect(c, x -. r, y -. r, 2.0 *. r, 2.0 *. r)
        restore(c)
      }
    }
  },
}

/* --------------------------------------------------------------- wind */
/* A GUST is a pulse: 0 outside [at, at+len], rising fast and easing out. A
   scene's wind is the sum of its gusts; the flame's lean and the paper bits
   both read from it, so they always agree. */
type gust = {at: float, len: float, strength: float}
let windAt = (gusts: array<gust>, t: sec) => {
  let tv = secf(t)
  Js.Array2.reduce(gusts, (acc, g) => {
    if tv < g.at || tv > g.at +. g.len {
      acc
    } else {
      let u = (tv -. g.at) /. g.len
      let env = u < 0.15 ? u /. 0.15 : 1.0 -. (u -. 0.15) /. 0.85
      acc +. g.strength *. env
    }
  }, 0.0)
}
/* the flame under wind: lies away from the valley (toward the camera-left),
   loses height, and goes blue when starved */
let flameInWind = (gusts, ~base=flameLit, t) => {
  let w = windAt(gusts, t)
  let f = flicker(base, t)
  {
    ...f,
    height: f.height *. (1.0 -. 0.5 *. Js.Math.min_float(1.0, w)),
    lean: f.lean -. 1.15 *. Js.Math.min_float(1.0, w),
    blue: Js.Math.max_float(f.blue, Js.Math.min_float(1.0, w -. 0.7) *. 3.0),
    glowStrength: f.glowStrength *. (1.0 -. 0.5 *. Js.Math.min_float(1.0, w)),
  }
}
/* PAPER BITS: small pale scraps that cross the courtyard right to left while
   a gust blows, each on its own line and rhythm. Deterministic per index. */
let windBitsLayer = (~z, ~gusts: array<gust>, ~count=18) => {
  z,
  draw: (c, t) => {
    let tv = secf(t)
    Js.Array2.forEach(gusts, g => {
      let age = tv -. g.at
      if age > 0.0 && age < g.len +. 0.6 {
        for i in 0 to count - 1 {
          let fi = Belt.Int.toFloat(i)
          let start = g.at +. mod_float(fi *. 0.37, g.len *. 0.6)
          let a = tv -. start
          if a > 0.0 && a < 1.4 {
            let u = a /. 1.4
            let x = 1300.0 -. u *. (1500.0 +. mod_float(fi *. 131.0, 300.0))
            let y = 470.0 +. mod_float(fi *. 53.0, 200.0) -. 40.0 *. Js.Math.sin(u *. 3.14159 *. (1.0 +. mod_float(fi, 3.0)))
            let rot = a *. (2.0 +. mod_float(fi, 5.0))
            save(c)
            setGlobalAlpha(c, 0.85 *. g.strength *. (u < 0.1 ? u /. 0.1 : u > 0.85 ? (1.0 -. u) /. 0.15 : 1.0))
            translate(c, x, y)
            rotate(c, rot)
            setFillStyle(c, mod(i, 2) == 0 ? "#efe6d6" : "#d9cdb8")
            fillRect(c, -5.0 -. mod_float(fi, 4.0), -2.5, 10.0 +. 2.0 *. mod_float(fi, 4.0), 5.0)
            restore(c)
          }
        }
      }
    })
  },
}

/* ---------------------------------------------------------- the letter */
/* द is the true font glyph with its own glow, never generated. It appears in
   two strokes as the script describes: the deep curve first, then the roof
   drawn across it. `reveal` is 0..1 for the curve, `roof` 0..1 for the bar.
   Mirrored is the wrong-way attempt. The glyph is 1400 square; the bar is
   its top ~22 percent. */
let letterLayer = async (~z, ~x, ~y, ~size, ~mirrored=false, ~reveal: sec => float, ~roof: sec => float, ~glow: sec => float) => {
  let img = await loadImage(ImagePath(root ++ "elements/letter_da_TRUE.png"))
  {
    z,
    draw: (c, t) => {
      let rv = reveal(t)
      let rf = roof(t)
      let gl = glow(t)
      if rv > 0.0 || rf > 0.0 {
        save(c)
        translate(c, x, y)
        if mirrored {
          scaleCtx(c, -1.0, 1.0)
        }
        let s = size /. 1400.0
        /* the glow behind it, added */
        if gl > 0.0 {
          save(c)
          setCompositeOp(c, "lighter")
          setGlobalAlpha(c, gl)
          let g = createRadialGradient(c, 0.0, size *. 0.1, 0.0, 0.0, size *. 0.1, size *. 1.1)
          addColorStop(g, 0.0, "rgba(255,200,90,1)")
          addColorStop(g, 1.0, "rgba(0,0,0,0)")
          setFillGradient(c, g)
          fillRect(c, -.size *. 1.2, -.size *. 1.1, size *. 2.4, size *. 2.4)
          restore(c)
        }
        /* the curve: the lower 78 percent of the glyph, revealed top-down as it is breathed */
        if rv > 0.0 {
          save(c)
          beginPath(c)
          let top = -.size *. 0.5 +. size *. 0.22
          let hgt = size *. 0.78 *. rv
          moveTo(c, -.size *. 0.6, top)
          lineTo(c, size *. 0.6, top)
          lineTo(c, size *. 0.6, top +. hgt)
          lineTo(c, -.size *. 0.6, top +. hgt)
          closePath(c)
          clip(c)
          drawImageSized(c, img, -.size *. 0.5, -.size *. 0.5, size, size)
          restore(c)
        }
        /* the roof: the top bar, drawn left to right */
        if rf > 0.0 {
          save(c)
          beginPath(c)
          let top = -.size *. 0.5
          let wid = size *. rf
          moveTo(c, -.size *. 0.5, top)
          lineTo(c, -.size *. 0.5 +. wid, top)
          lineTo(c, -.size *. 0.5 +. wid, top +. size *. 0.22)
          lineTo(c, -.size *. 0.5, top +. size *. 0.22)
          closePath(c)
          clip(c)
          drawImageSized(c, img, -.size *. 0.5, -.size *. 0.5, size, size)
          restore(c)
        }
        restore(c)
        ignore(s)
      }
    },
  }
}

/* GOLDEN MIST: what कुकु's breath is before it becomes a letter — a cloud of
   warm motes from his snout that drifts and thins. `puffAt` is when the
   breath leaves him; the motes live 1.8 s. `settle` is where they gather. */
let mistLayer = (~z, ~fromX, ~fromY, ~toX, ~toY, ~puffAt: float, ~gather: bool, ~motes=40) => {
  z,
  draw: (c, t) => {
    let age = secf(t) -. puffAt
    if age > 0.0 && age < 1.8 {
      let u = age /. 1.8
      save(c)
      setCompositeOp(c, "lighter")
      for i in 0 to motes - 1 {
        let fi = Belt.Int.toFloat(i)
        let spread = gather ? (1.0 -. u) : u
        let ang = fi *. 2.399
        let rad = 30.0 +. mod_float(fi *. 17.0, 90.0) *. spread
        let x = fromX +. (toX -. fromX) *. Js.Math.min_float(1.0, u *. 1.6) +. Js.Math.cos(ang) *. rad
        let y = fromY +. (toY -. fromY) *. Js.Math.min_float(1.0, u *. 1.6) +. Js.Math.sin(ang) *. rad *. 0.6
        let r = 3.0 +. mod_float(fi, 4.0) +. 6.0 *. (gather ? 1.0 -. u : u)
        setGlobalAlpha(c, (gather ? 0.7 : 0.6 *. (1.0 -. u)) *. (u < 0.1 ? u /. 0.1 : 1.0))
        let g = createRadialGradient(c, x, y, 0.0, x, y, r)
        addColorStop(g, 0.0, "rgba(255,215,120,1)")
        addColorStop(g, 1.0, "rgba(255,170,60,0)")
        setFillGradient(c, g)
        fillRect(c, x -. r, y -. r, 2.0 *. r, 2.0 *. r)
      }
      restore(c)
    }
  },
}

/* THE VALLEY LIGHT: the letter's gold going over the wall and down into the
   valley, a wide band brightening from the courtyard's middle outward. */
let valleyLightLayer = (~z, ~strength: sec => float) => {
  z,
  draw: (c, t) => {
    let s = strength(t)
    if s > 0.0 {
      save(c)
      setCompositeOp(c, "lighter")
      setGlobalAlpha(c, s)
      beginPath(c)
      Js.Array2.forEachi(valleyPoly, ((x, y), i) => i == 0 ? moveTo(c, x, y) : lineTo(c, x, y))
      closePath(c)
      clip(c)
      let g = createRadialGradient(c, 760.0, 250.0, 10.0, 760.0, 250.0, 560.0)
      addColorStop(g, 0.0, "rgba(255,200,90,0.95)")
      addColorStop(g, 0.45, "rgba(255,180,70,0.5)")
      addColorStop(g, 1.0, "rgba(0,0,0,0)")
      setFillGradient(c, g)
      fillRect(c, 300.0, 0.0, 980.0, 207.0)
      restore(c)
    }
  },
}

/* ------------------------------------------------------------ the light */
/* The plate is graded over EVERYTHING — puppets included — so the tint sits
   at z 20 and the flame, its glow and any letter light sit above it. The
   states of the script, and blends between them for the moments the light
   changes (the lamp catching, the lamp dying, the letter lighting). */
let dusk = (_: sec) => 0.0
let tintFor = (l: light) =>
  switch l {
  | Dusk => []
  | LampNight => [tintLayer(~z=20, ~colour="#5a6fb8", ~w=Px(1280.0), ~h=Px(720.0))]
  | Dark => [
      tintLayer(~z=20, ~colour="#3a4a8a", ~w=Px(1280.0), ~h=Px(720.0)),
      tintLayer(~z=20, ~colour="#6a7098", ~w=Px(1280.0), ~h=Px(720.0)),
    ]
  | Golden => [tintLayer(~z=20, ~colour="#6a6a90", ~w=Px(1280.0), ~h=Px(720.0))]
  }
/* THE STATES AS LAYERS. Lamp-night is one multiply (A); dark is lamp-night
   plus a second (B) — so the lamp's death is B fading in over A, never A
   stacked twice; golden is its own (C), and the letter lighting the courtyard
   is A and B fading out while C fades in. Every light SOURCE — the flame, its
   glow, the letter, the mist, the valley band — sits ABOVE the tints at z 21+,
   or the dark state buries the very thing that is supposed to light it. */
let nightTint = "#5a6fb8"
let darkTint = "#6a7098"
let goldenTint = "#6a6a90"
/* a tint whose strength follows a track: for the moment the light changes,
   the multiply is drawn with alpha, so the courtyard fades between states */
let fadingTint = (~z, ~colour, ~strength: sec => float) => {
  z,
  draw: (c, t) => {
    let s = strength(t)
    if s > 0.0 {
      save(c)
      setCompositeOp(c, "multiply")
      setGlobalAlpha(c, s)
      setFillStyle(c, colour)
      fillRect(c, -1280.0, -720.0, 3840.0, 2160.0)
      restore(c)
    }
  },
}

/* --------------------------------------------------------- the puppets */
/* Everything a scene needs to know about a character in one record: its rig,
   its rest pose, its mouth map, which patches mean silence, and its size on
   the stage as a child, a grown-up or a puppy. */
type actor = {
  who: string,
  spec: rigSpec<small>,
  rig: rig<small>,
  rest: array<(partName, partPose)>,
  mouthMap: string => option<string>,
  size: float,
  headPart: partName,
}
let mouthOf = who =>
  switch who {
  | "kuku" => kukuMouth
  | _ => rhubarbMouth
  }
let restOf = who =>
  switch who {
  | "kuku" => canonical
  | "furia" => furiaCanonical
  | "leda" => ledaCanonical
  | "castor" => castorCanonical
  | "vesper" => vesperCanonical
  | "papa" => papaCanonical
  | _ => []
  }
let specOf = who =>
  switch who {
  | "kuku" => Some(kukuRig)
  | "furia" => Some(furiaRig)
  | "leda" => Some(ledaRig)
  | "castor" => Some(castorRig)
  | "vesper" => Some(vesperRig)
  | "papa" => Some(papaRig)
  | "dadi" => Some(dadiRig)
  | "kalu" => Some(kaluRig)
  | "kalu_asleep" => Some(kaluAsleepRig)
  | _ => None
  }
let sizeOf = who =>
  switch who {
  | "dadi" => 0.335
  | "papa" => 0.42
  | "kalu" | "kalu_asleep" => 0.13
  | _ => 0.21
  }
let headOf = who =>
  switch who {
  | "dadi" => dHead
  | "kalu" => dHeadDog
  | "kalu_asleep" => dCurl
  | _ => head
  }
let actor = async who =>
  switch specOf(who) {
  | Some(spec) => {
      let rig = await loadRig(spec)
      {who, spec, rig, rest: restOf(who), mouthMap: mouthOf(who), size: sizeOf(who), headPart: headOf(who)}
    }
  | None => Js.Exn.raiseError("no actor named " ++ who)
  }

/* WHERE SOMEONE STANDS: feet on the stage, which way they face. The ground
   in this courtyard: y 640 at the front, rising toward the wall; a puppet
   standing further back is placed higher and a little smaller. */
type mark = {x: float, y: float, facingLeft: bool}
let depthScale = y => 1.0 -. (640.0 -. y) /. 640.0 *. 0.45

/* the takes: line number → recorded wav, its visemes, its length, its speaker */
type take = {line: int, who: string, text: string, wav: string, visemes: string, secs: float}
let takes: array<take> = {
  let j = Js.Json.parseExn(readFileSync(root ++ "cutout/audio/takes.json", "utf8"))
  j
  ->Js.Json.decodeArray
  ->Belt.Option.getWithDefault([])
  ->Js.Array2.map(e => {
    let o = e->Js.Json.decodeObject->Belt.Option.getWithDefault(Js.Dict.empty())
    let str = k => Js.Dict.get(o, k)->Belt.Option.flatMap(Js.Json.decodeString)->Belt.Option.getWithDefault("")
    let num = k => Js.Dict.get(o, k)->Belt.Option.flatMap(Js.Json.decodeNumber)->Belt.Option.getWithDefault(0.0)
    {line: Belt.Float.toInt(num("line")), who: str("who"), text: str("text"), wav: root ++ str("wav"), visemes: root ++ str("visemes"), secs: num("secs")}
  })
}
let takeOf = line =>
  switch Js.Array2.find(takes, t => t.line == line) {
  | Some(t) => t
  | None => Js.Exn.raiseError("no take for line " ++ Belt.Int.toString(line))
  }
/* the script's speaker names → actor keys */
let actorKeyOf = who =>
  switch who {
  | "दादी" => "dadi"
  | "कुकु" => "kuku"
  | "फ्यूरिया" => "furia"
  | "लेडा" => "leda"
  | "कैस्टर" => "castor"
  | "वैस्पर" => "vesper"
  | "पापा" => "papa"
  | _ => "kuku"
  }

/* A CUE: a line spoken at a moment. A scene's dialogue is a list of cues;
   `sequence` lays lines end to end with a gap, so a scene author writes the
   line numbers and the gaps and gets the timing back. */
type cue = {line: int, at: float}
let sequence = (~from=0.0, ~gap=0.35, lines: array<int>) => {
  let t = ref(from)
  Js.Array2.map(lines, l => {
    let c = {line: l, at: t.contents}
    t := t.contents +. takeOf(l).secs +. gap
    c
  })
}
let endOf = (cues: array<cue>) =>
  Js.Array2.reduce(cues, (m, c) => Js.Math.max_float(m, c.at +. takeOf(c.line).secs), 0.0)
let cueVisemes = (c: cue) => visemes(takeOf(c.line).visemes)

/* SPEECH ON A PUPPET: for an actor and the cues that are theirs, the mouth
   patch at t and how much they are talking, from their own takes. */
let mouthFor = (a: actor, cues: array<cue>, t: sec) => {
  let tv = secf(t)
  let live = Js.Array2.find(cues, c => actorKeyOf(takeOf(c.line).who) == a.who && tv >= c.at && tv < c.at +. takeOf(c.line).secs)
  switch live {
  | Some(c) => mouthAt(cueVisemes(c), ~map=a.mouthMap, Sec(tv -. c.at))
  | None => a.who == "kuku" ? Some("closed") : None
  }
}
let talkingFor = (a: actor, cues: array<cue>, t: sec) => {
  let tv = secf(t)
  switch Js.Array2.find(cues, c => actorKeyOf(takeOf(c.line).who) == a.who && tv >= c.at && tv < c.at +. takeOf(c.line).secs) {
  | Some(c) => talking(cueVisemes(c), Sec(tv -. c.at))
  | None => 0.0
  }
}

/* STANDING AND SPEAKING: an actor at a mark, at rest, with idle life, and
   the mouth and head following any cue of theirs. Extra poses are laid over. */
let sway = (hz, amp, phase, t) => amp *. Js.Math.sin(2.0 *. Js.Math._PI *. hz *. secf(t) +. phase)
let standingActor = (a: actor, m: mark, cues, ~extra: sec => array<(partName, partPose)>=_ => [], ~headTurn: sec => float=_ => 0.0, ~scale=1.0, t) => {
  let base = stand(a.spec, ~feetX=m.x, ~feetY=m.y, ~size=a.size *. depthScale(m.y) *. scale, ~facingLeft=m.facingLeft, ())
  let talk = talkingFor(a, cues, t)
  let phase = Belt.Int.toFloat(Js.String2.length(a.who)) *. 0.9
  let emphasis = 2.2 *. talk *. Js.Math.sin(2.0 *. Js.Math._PI *. 0.95 *. secf(t) +. phase)
  let breathe = sway(0.27, 0.7, phase, t)
  let headA = (a.headPart, turn(emphasis +. breathe +. headTurn(t)))
  let tailA = a.who == "dadi" || a.who == "kalu" ? [] : [(tail, turn(sway(0.22, 2.5, phase *. 2.0, t)))]
  {
    ...posed(base, Js.Array2.concatMany(a.rest, [tailA, [headA], extra(t)])),
    mouth: mouthFor(a, cues, t),
  }
}

/* SITTING: the legs fold and the body comes down; a crouch on the flagstones
   the way the children settle around the lamp. */
let sittingActor = (a: actor, m: mark, cues, ~headTurn: sec => float=_ => 0.0, t) => {
  let st = standingActor(a, {...m, y: m.y +. 26.0 *. a.size /. 0.21}, cues, ~extra=_ => [(legNear, turn(m.facingLeft ? 52.0 : 52.0)), (legFar, turn(-48.0))], ~headTurn, t)
  st
}

/* WALKING: a gait toward a mark. `from` at t0, `to` at t1, the stride on the
   ground speed, the arms swinging opposite, a bob on each step. */
let walkingActor = (a: actor, ~from: mark, ~to_: mark, ~t0, ~t1, cues, t) => {
  let tv = secf(t)
  let u = tv <= t0 ? 0.0 : tv >= t1 ? 1.0 : (tv -. t0) /. (t1 -. t0)
  let moving = tv > t0 && tv < t1 ? 1.0 : 0.0
  let x = from.x +. (to_.x -. from.x) *. u
  let y = from.y +. (to_.y -. from.y) *. u
  let f = 2.2
  let stride = Js.Math.sin(2.0 *. Js.Math._PI *. f *. tv)
  let legs = 14.0 *. moving *. stride
  let arms = 10.0 *. moving *. stride
  let bob = 3.0 *. moving *. Js.Math.abs_float(stride)
  let m = {x, y: y -. bob, facingLeft: to_.x < from.x}
  standingActor(a, m, cues, ~extra=_ => [(legNear, turn(legs)), (legFar, turn(-.legs)), (armNear, turn(-.restArmNear -. arms)), (armFar, turn(restArmFar -. arms))], t)
}

/* a puppet layer from a state function, with its contact shadow under it */
let actorLayers = (~z, a: actor, state: sec => puppetState) => [
  shadowLayer(~z=z - 1, ~shadow=t => {
    let st = state(t)
    {cx: st.x, cy: Px(pxf(st.y) +. 6.0), rx: Px(70.0 *. scalef(st.size) /. 0.21), ry: Px(14.0), a: Alpha(0.28)}
  }),
  puppetLayer(~z, ~rig=a.rig, ~state),
]

/* ------------------------------------------------------------ the scene */
/* A scene renders to one file with its dialogue mixed from the takes at their
   cue times over a bed of silence; the assembler joins scenes end to end. */
type scene = {
  name: string,
  duration: float,
  layers: array<layer>,
  camera: sec => camera,
  cues: array<cue>,
}
let sceneDir = root ++ "scenes/"

let audioFor = (sc: scene, out) => {
  /* every take delayed to its cue, mixed over silence of the scene's length */
  let inputs = Js.Array2.reduce(sc.cues, (acc, c) => Js.Array2.concat(acc, ["-i", takeOf(c.line).wav]), [])
  let n = Js.Array2.length(sc.cues)
  let delays = Js.Array2.mapi(sc.cues, (c, i) => {
    let ms = Belt.Int.toString(Belt.Float.toInt(c.at *. 1000.0))
    "[" ++ Belt.Int.toString(i + 1) ++ ":a]adelay=" ++ ms ++ "|" ++ ms ++ "[d" ++ Belt.Int.toString(i) ++ "]"
  })
  let labels = Js.Array2.joinWith(Js.Array2.mapi(sc.cues, (_, i) => "[d" ++ Belt.Int.toString(i) ++ "]"), "")
  let graph = Js.Array2.joinWith(Js.Array2.concat(delays, ["[0:a]" ++ labels ++ "amix=inputs=" ++ Belt.Int.toString(n + 1) ++ ":normalize=0:duration=first[out]"]), ";")
  Cinema_Backends.ffmpeg(
    Js.Array2.concatMany(
      ["-y", "-v", "error", "-f", "lavfi", "-t", Js.Float.toString(sc.duration), "-i", "anullsrc=r=48000:cl=stereo"],
      [inputs, ["-filter_complex", graph, "-map", "[out]", "-ac", "2", "-ar", "48000", "-c:a", "aac", "-b:a", "192k", out]],
    ),
  )
}

let renderScene = (sc: scene) => {
  mkdirSync(sceneDir, {"recursive": true})
  let audio = sceneDir ++ sc.name ++ ".m4a"
  if Js.Array2.length(sc.cues) > 0 {
    audioFor(sc, audio)
  }
  let out = sceneDir ++ sc.name ++ ".mp4"
  render({
    name: sc.name,
    width: 1280,
    height: 720,
    fps: Fps(24),
    duration: Sec(sc.duration),
    layers: sc.layers,
    camera: sc.camera,
    audio: Js.Array2.length(sc.cues) > 0 ? Some(audio) : None,
    out,
  })
  contactSheet(~video=out, ~out=sceneDir ++ sc.name ++ "_sheet.png", ~cols=6, ~rows=2, ~everySec=Js.Math.max_float(0.5, sc.duration /. 12.0))
  out
}

/* JOIN scenes end to end into one file, re-encoding nothing: every scene is
   rendered with the same codec, size and rate. */
let concat = (files: array<string>, out) => {
  let list = sceneDir ++ "concat.txt"
  writeFileSync(list, Js.Array2.joinWith(Js.Array2.map(files, f => "file '" ++ f ++ "'"), "\n") ++ "\n")
  Cinema_Backends.ffmpeg(["-y", "-v", "error", "-f", "concat", "-safe", "0", "-i", list, "-c", "copy", out])
}

/* a still camera and a slow push, the two a dialogue scene mostly needs */
let still = (~zoom=1.06, ~lookX=660.0, ~lookY=372.0) => (_t: sec) => {zoom: Scale(zoom), lookX: Px(lookX), lookY: Px(lookY)}
let pushIn = (~from=1.06, ~to_=1.14, ~lookX=660.0, ~lookY=372.0, ~over) => (t: sec) => {
  zoom: Scale(track([{at: Sec(0.0), v: from}, {at: Sec(over), v: to_}], ~ease=linear, t)),
  lookX: Px(lookX),
  lookY: Px(lookY),
}
