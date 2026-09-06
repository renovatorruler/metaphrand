// KukuEp10_Cutout.res — the hybrid pipeline: generated cutouts, composed in code.
//
// The generative model is asked for ONE thing per picture — a single character on
// a flat keyable sheet — because that is what it copies faithfully. Everything a
// model cannot hold across pictures (who is in frame, where the lamp is, whether
// it is lit, which mouth shape is showing) becomes a layer placed by code.
//
//   node src/KukuEp10_Cutout.res.mjs sprite dadi     # one cutout, receipted

@module("fs") external mkdirSync: (string, {"recursive": bool}) => unit = "mkdirSync"
@module("process") external cwd: unit => string = "cwd"
@module("process") external argv: array<string> = "argv"

module P = Kuku_PromptSpec

let root = cwd() ++ "/../stories/kuku/ep10/"
let () = PromptGate.setStrict(true)
let spritesDir = root ++ "cutout/sprites/"

/* THE SPRITE STYLE KEY IS A FLAT SHEET, NOT THE SET. image[0] out-argues any
   text; both set keys are pictures of walls, and the first कुकु sprite came
   back standing in front of that wall with the sheet nowhere. So a sprite's
   key is a synthesized flat paper texture in the key colour: the reference
   now argues FOR the sheet. */
/* The key is now a crop of कुकु's own receipted sprite: a papercraft figure
   standing on the blue sheet, wing and arm and sheet-shadow, no set. The flat
   texture said nothing about the FIGURE's material, and फ्यूरिया came back
   as flat cut paper with a generic face. */
let sheetKey = root ++ "style/sheet_blue_material_key.png"
let () = P.useStyleKey(sheetKey)
let proxyFor = who => spritesDir ++ who ++ "_pose_proxy.png"

/* THE KEY SHEET. A cutout is generated on one flat green paper sheet and keyed
   out. The green is named as a material the character stands on, never as a
   thing to remove — the gate would refuse that, and the model draws what it is
   told to remove. */
let keySheet = "one smooth flat sheet of bright green paper fills the entire background edge to edge, the same even green everywhere"
/* कुकु is green, so his sheet is blue: a key colour must be absent from the character */
let keySheetBlue = "one smooth flat sheet of bright blue paper fills the entire background edge to edge, the same even blue everywhere"

let dadiKneeling: P.imageSpec = {
  scene: "दादी kneels on the flat green paper with both hands held forward and low, as if setting something small down in front of दादी, face turned three quarters toward the camera, mouth gently closed.",
  shot: P.Wide,
  subjects: [P.Dadi({doing: "दादी kneels with both hands held forward and low, face three quarters to the camera, mouth gently closed"})],
  setting: keySheet,
  lighting: "Evening, warm level light from the left, the same gold as the courtyard plate, soft shadow falling to the right.",
  plate: None,
  blockout: None,
  objects: [],
  extraRules: [
    "THE WHOLE BACKGROUND IS THAT ONE FLAT GREEN PAPER SHEET; दादी is the only thing on it.",
    "EVERY SURFACE OF दादी IS CUT PAPER: separate pieces with real thickness, soft rounded cut edges and a fine visible paper grain.",
    "दादी FILLS THE FRAME: whole body visible from horns to tail with clear green margin on every side.",
  ],
}

/* THE PUPPET SPRITE. A spread pose: every limb standing clear of the body with
   green showing between, so each part can be cut along a polygon and hinged.
   Generated once; from here on कुकु moves only by numbers. */
let kukuSpread: P.imageSpec = {
  scene: "कुकु stands on the flat blue paper facing three quarters to the left, both wings raised high and spread wide open, both arms held straight out from the body with blue paper visible between each arm and the body, legs apart, tail stretched straight out behind with blue paper visible between the tail and the legs, head level, mouth closed.",
  shot: P.Sheet,
  subjects: [P.Dragon({name: P.Kuku, form: P.Small, doing: "कुकु stands facing three quarters to the left with both wings raised high and spread wide open, both arms held straight out from the body, legs apart, tail stretched straight out behind, head level, mouth closed"})],
  setting: keySheetBlue,
  lighting: "Evening, warm level light from the left, the same gold as the courtyard plate, soft shadow falling to the right.",
  plate: None,
  blockout: Some(proxyFor("kuku")),
  objects: [],
  extraRules: [
    "THE WHOLE BACKGROUND IS THAT ONE FLAT BLUE PAPER SHEET; कुकु is the only thing on it.",
    "EVERY SURFACE OF कुकु IS CUT PAPER: separate pieces with real thickness, soft rounded cut edges and a fine visible paper grain.",
    "कुकु FILLS THE FRAME: whole body visible from horns to tail tip with clear blue margin on every side.",
    "EVERY LIMB STANDS CLEAR: blue paper shows between each wing and the head, between each arm and the body, between the two legs, and between the tail and the legs.",
  ],
}

/* फ्यूरिया's sheet: the same spread pose, her own colour in the silhouette.
   Her design has no blue, so the blue sheet keys her too. */
let furiaSpread: P.imageSpec = {
  scene: "फ्यूरिया stands on the flat blue paper facing three quarters to the left, both wings raised high and spread wide open, both arms held straight out from the body with blue paper visible between each arm and the body, legs apart, tail stretched straight out behind with blue paper visible between the tail and the legs, head level, mouth closed.",
  shot: P.Sheet,
  subjects: [P.Dragon({name: P.Fyuria, form: P.Small, doing: "फ्यूरिया stands facing three quarters to the left with both wings raised high and spread wide open, both arms held straight out from the body, legs apart, tail stretched straight out behind, head level, mouth closed"})],
  setting: keySheetBlue,
  lighting: "Evening, warm level light from the left, the same gold as the courtyard plate, soft shadow falling to the right.",
  plate: None,
  blockout: Some(proxyFor("furia")),
  objects: [],
  extraRules: [
    "THE WHOLE BACKGROUND IS THAT ONE FLAT BLUE PAPER SHEET; फ्यूरिया is the only thing on it.",
    "EVERY SURFACE OF फ्यूरिया IS CUT PAPER: separate pieces with real thickness, soft rounded cut edges and a fine visible paper grain.",
    "फ्यूरिया FILLS THE FRAME: whole body visible from horns to tail tip with clear blue margin on every side.",
    "फ्यूरिया'S FACE AND BODY ARE THE SHEET'S: large round eyes with dark paper lashes, the smiling snout with one small fang, a cream belly of stacked paper plates, the golden कड़ा on one forearm, the same bright pink-red paper everywhere else.",
    "EVERY LIMB STANDS CLEAR: blue paper shows between each wing and the head, between each arm and the body, between the two legs, and between the tail and the legs.",
  ],
}

/* MOUTH SHAPES are edits of the SAME sprite, so the body stays identical and only
   the mouth changes; the mouth region is then cut out and swapped by the viseme
   track. A (rest) and X (silence) use the sprite's own closed mouth. */
/* one character's mouth set: the sprite it edits, what stays, and the four
   shapes. A character whose sprite smiles open needs the closed shape too,
   for rest and silence. */
type mouthSet = {who: string, src: string, keep: string, whoRule: string, shapes: array<(string, string)>}
let mouthSets = [
  {
    who: "dadi",
    src: "dadi_kneeling_raw.png",
    keep: "everything else exactly as it is: the same pose, the same shawl, the same staff, the same wings and tail, the same flat green background, the same framing",
    whoRule: "only the mouth of दादी changes; the mouth is a clean paper cutout in the same papercraft finish",
    shapes: [
      ("open", "दादी's mouth open wide in a tall oval, as if saying a long AA sound"),
      ("round", "दादी's mouth pursed small and round, as if saying OO"),
      ("half", "दादी's mouth slightly open with the paper teeth just showing, as if saying EE"),
    ],
  },
  {
    who: "kuku",
    src: "kuku_spread_raw.png",
    keep: "everything else exactly as it is: the same spread pose, the same wings, arms, legs and tail, the same eyes, the same flat blue background, the same framing",
    whoRule: "only the mouth of कुकु changes; the mouth is a clean paper cutout in the same papercraft finish",
    shapes: [
      ("closed", "कुकु's mouth closed, lips together, calm and content, teeth hidden"),
      ("open", "कुकु's mouth open wide in a tall oval, as if saying a long AA sound"),
      ("round", "कुकु's mouth pursed small and round, as if saying OO"),
      ("half", "कुकु's mouth slightly open with the paper teeth just showing, as if saying EE"),
    ],
  },
  {
    who: "furia",
    src: "furia_spread_raw.png",
    keep: "everything else exactly as it is: the same spread pose, the same wings, arms, legs and tail, the same eyes and lashes, the same golden कड़ा, the same flat blue background, the same framing",
    whoRule: "only the mouth of फ्यूरिया changes; the mouth is a clean paper cutout in the same papercraft finish",
    shapes: [
      ("open", "फ्यूरिया's mouth open wide in a tall oval, as if saying a long AA sound"),
      ("round", "फ्यूरिया's mouth pursed small and round, as if saying OO"),
      ("half", "फ्यूरिया's mouth slightly open with the paper teeth just showing, as if saying EE"),
    ],
  },
]
let mouthEdit = (set, change): P.editSpec => {change, keep: [set.keep], extraRules: [set.whoRule]}
let mouth = (who, shape) =>
  switch Js.Array2.find(mouthSets, m => m.who == who) {
  | Some(set) =>
    switch Js.Array2.find(set.shapes, ((n, _)) => n == shape) {
    | Some((n, change)) =>
      ignore(Kuku_Engine.edit(~episode="EP10", ~id="sprite_" ++ who ++ "_mouth_" ++ n, ~spec=mouthEdit(set, change),
        ~src=spritesDir ++ set.src, ~dst=spritesDir ++ who ++ "_mouth_" ++ n ++ "_raw.png", ()))
    | None => Js.log("no mouth shape " ++ shape ++ " for " ++ who)
    }
  | None => Js.log("no mouth set for " ++ who)
  }

let specOf = name =>
  switch name {
  | "dadi" => Some(("sprite_dadi_kneeling", dadiKneeling, "dadi_kneeling_raw.png"))
  | "kuku" => Some(("sprite_kuku_spread", kukuSpread, "kuku_spread_raw.png"))
  | "furia" => Some(("sprite_furia_spread", furiaSpread, "furia_spread_raw.png"))
  | _ => None
  }

let sprite = name =>
  switch specOf(name) {
  | Some((id, spec, file)) =>
    ignore(Kuku_Engine.still(~episode="EP10", ~id, ~spec, ~dst=spritesDir ++ file, ()))
  | None => Js.log("no sprite named " ++ name)
  }

/* THE POSE PROXY. Pictures beat text: the first कुकु sprite copied the pose off
   the character sheet and ignored the written spread pose. So the spread pose
   is also a picture — a flat green silhouette on the blue sheet, drawn by code,
   attached as the staging reference. Zero credits, deterministic. Sprite
   space is 2752x1536, the character facing left. */
let drawProxy = (~who, ~colour) => {
  module C = Puppet
  let cv = C.createCanvas(2752, 1536)
  let c = C.getContext(cv, "2d")
  C.setFillStyle(c, "#2f6fe0")
  C.fillRect(c, 0.0, 0.0, 2752.0, 1536.0)
  C.setFillStyle(c, colour)
  C.setStrokeStyle(c, colour)
  C.setLineCap(c, "round")
  let disc = (x, y, rx, ry) => {
    C.beginPath(c)
    C.ellipse(c, x, y, rx, ry, 0.0, 0.0, 2.0 *. Js.Math._PI)
    C.fill(c)
  }
  let bar = (x0, y0, x1, y1, w) => {
    C.setLineWidth(c, w)
    C.beginPath(c)
    C.moveTo(c, x0, y0)
    C.lineTo(c, x1, y1)
    C.stroke(c)
  }
  let poly = pts => {
    C.beginPath(c)
    Js.Array2.forEachi(pts, ((x, y), i) => i == 0 ? C.moveTo(c, x, y) : C.lineTo(c, x, y))
    C.closePath(c)
    C.fill(c)
  }
  /* wings first, behind everything */
  poly([(1300.0, 760.0), (700.0, 200.0), (450.0, 520.0), (1150.0, 900.0)])
  poly([(1540.0, 760.0), (2200.0, 200.0), (2400.0, 560.0), (1650.0, 900.0)])
  /* tail out behind (to the right, since the character faces left) */
  poly([(1580.0, 1020.0), (2500.0, 980.0), (2500.0, 1060.0), (1580.0, 1140.0)])
  /* body, neck, head */
  disc(1420.0, 950.0, 210.0, 300.0)
  bar(1330.0, 780.0, 1200.0, 640.0, 130.0)
  disc(1150.0, 520.0, 175.0, 165.0)
  /* arms straight out, legs apart */
  bar(1250.0, 880.0, 820.0, 880.0, 90.0)
  bar(1600.0, 880.0, 2050.0, 880.0, 90.0)
  bar(1330.0, 1230.0, 1230.0, 1470.0, 110.0)
  bar(1520.0, 1230.0, 1600.0, 1470.0, 110.0)
  C.writeFileBuffer(proxyFor(who), C.toBuffer(cv, "image/png"))
  Js.log("wrote " ++ proxyFor(who))
}

/* the sheet key: flat bright blue paper with a fine grain, the same size as a
   sprite; synthesized, so it depicts nothing but the sheet */
let drawSheetKey = () => {
  Cinema_Backends.ffmpeg([
    "-y", "-v", "error", "-f", "lavfi", "-i", "color=c=0x2f6fe0:s=2752x1536",
    "-vf", "noise=alls=14:allf=u,gblur=sigma=0.8", "-frames:v", "1", sheetKey,
  ])
  Js.log("wrote " ++ sheetKey)
}

/* PLAN: the exact prompt a sprite would be generated from, and every finding
   of the law against it. Costs nothing; run it before spending. */
let plan = name =>
  switch specOf(name) {
  | Some((id, spec, _)) => {
      let txt = P.imagePrompt(spec)
      Js.log("== " ++ id ++ " ==\n" ++ txt)
      let found = Js.Array2.concat(PromptGate.scan(txt), PromptGate.scanStrict(txt))
      Js.log(Js.Array2.length(found) == 0 ? "GATE CLEAN" : Js.Array2.joinWith(found, "\n"))
    }
  | None => Js.log("no sprite named " ++ name)
  }

let () = {
  mkdirSync(spritesDir, {"recursive": true})
  switch (Belt.Array.get(argv, 2), Belt.Array.get(argv, 3), Belt.Array.get(argv, 4)) {
  | (Some("sprite"), Some(n), _) => sprite(n)
  | (Some("plan"), Some(n), _) => plan(n)
  | (Some("proxy"), Some(who), Some(colour)) => {
      drawProxy(~who, ~colour)
      drawSheetKey()
    }
  | (Some("mouth"), Some(who), Some(shape)) => mouth(who, shape)
  | _ => Js.log("usage: sprite <name> | plan <name> | proxy <who> <#colour> | mouth <who> <shape>")
  }
}

/* ============================================================================
   THE COMPOSITOR. A shot is layers placed by code: the plate, a character
   cutout, a mouth patch chosen per viseme, the lamp, a slow camera. Nothing here
   is re-imagined by a model, so nothing here can drift. ffmpeg is the renderer;
   this module owns the plan and emits the filter graph.
   ============================================================================ */
@module("fs") external readFileSync: (string, string) => string = "readFileSync"
@module("fs") external writeFileSync: (string, string) => unit = "writeFileSync"

type viseme = {start: float, end_: float, shape: string}

let visemesOf = path => {
  let j = Js.Json.parseExn(readFileSync(path, "utf8"))
  let cues =
    j->Js.Json.decodeObject->Belt.Option.flatMap(o => Js.Dict.get(o, "mouthCues"))
    ->Belt.Option.flatMap(Js.Json.decodeArray)->Belt.Option.getWithDefault([])
  Js.Array2.map(cues, c => {
    let o = c->Js.Json.decodeObject->Belt.Option.getWithDefault(Js.Dict.empty())
    let num = k => Js.Dict.get(o, k)->Belt.Option.flatMap(Js.Json.decodeNumber)->Belt.Option.getWithDefault(0.0)
    let str = k => Js.Dict.get(o, k)->Belt.Option.flatMap(Js.Json.decodeString)->Belt.Option.getWithDefault("X")
    {start: num("start"), end_: num("end"), shape: str("value")}
  })
}

/* Rhubarb's shapes → our patches. A and X are the sprite's own closed mouth. */
let patchFor = shape =>
  switch shape {
  | "E" | "F" => Some("round")
  | "D" => Some("open")
  | "B" | "C" | "G" | "H" => Some("half")
  | _ => None
  }

let enableExpr = (vs, patch) =>
  Js.Array2.joinWith(
    Js.Array2.map(Js.Array2.filter(vs, v => patchFor(v.shape) == Some(patch)), v =>
      "between(t," ++ Js.Float.toString(v.start) ++ "," ++ Js.Float.toString(v.end_) ++ ")"
    ),
    "+",
  )

let f = Js.Float.toString

let renderProof = () => {
  let out = root ++ "cutout/out/"
  mkdirSync(out, {"recursive": true})
  let plate = root ++ "sets/courtyard_plate.png"
  let sprite = spritesDir ++ "dadi_stand.png"
  let audio = root ++ "cutout/audio/line008.wav"
  let vs = visemesOf(root ++ "cutout/audio/line008.visemes.json")
  let dur = Js.Array2.reduce(vs, (m, v) => v.end_ > m ? v.end_ : m, 0.0) +. 0.6
  /* canvas 1280x720. The sprite is 1706x1536 (the raw 2752x1536 cropped from x=523).
     दादी scaled to 0.72 of frame height and stood to the right of the niche. */
  let s = 0.72 *. 720.0 /. 1536.0
  let sx = 660.0
  let sy = 720.0 *. 0.92 -. 1536.0 *. s
  /* The mouth box is (1000,435) 230x130 in raw coordinates, i.e. (477,435) in the sprite.
     Each patch was cut from its edit at the offset that registers the edit's spectacles
     onto the base sprite's (measured: round +13,-6; half 0,-3; open +4,-35), so every
     patch lands on the same box. */
  let mx = sx +. 477.0 *. s
  let my = sy +. 435.0 *. s
  let bob = "+2*sin(2*PI*t/3.2)"
  let patchLayer = (i, name, src, dst) =>
    "[" ++ Belt.Int.toString(i) ++ ":v]scale=iw*" ++ f(s) ++ ":-1[" ++ name ++ "];[" ++ src ++ "][" ++ name ++ "]overlay=x=" ++ f(mx) ++ ":y=" ++ f(my) ++ bob ++ ":enable='" ++ enableExpr(vs, name) ++ "'[" ++ dst ++ "]"
  let graph = Js.Array2.joinWith([
    "[0:v]scale=1280:720[bg]",
    "[5:v]scale=iw*0.47:-1[lamp]",
    "[bg][lamp]overlay=x=548:y=353[l1]",
    "[1:v]scale=iw*" ++ f(s) ++ ":-1[sp]",
    "[l1][sp]overlay=x=" ++ f(sx) ++ ":y=" ++ f(sy) ++ bob ++ "[c1]",
    patchLayer(2, "round", "c1", "c2"),
    patchLayer(3, "half", "c2", "c3"),
    patchLayer(4, "open", "c3", "c4"),
    "[c4]zoompan=z='1+0.05*on/" ++ f(dur *. 24.0) ++ "':x='iw*0.6-(iw/zoom)*0.6':y='ih*0.55-(ih/zoom)*0.55':d=1:s=1280x720:fps=24[v]",
  ], ";")
  writeFileSync(out ++ "proof_plan.txt", graph)
  let args = [
    "-v", "error", "-y",
    "-loop", "1", "-i", plate,
    "-loop", "1", "-i", sprite,
    "-loop", "1", "-i", spritesDir ++ "mouth_round.png",
    "-loop", "1", "-i", spritesDir ++ "mouth_half.png",
    "-loop", "1", "-i", spritesDir ++ "mouth_open.png",
    "-loop", "1", "-i", spritesDir ++ "lamp_lit.png",
    "-i", audio,
    "-filter_complex", graph,
    "-map", "[v]", "-map", "6:a",
    "-t", f(dur), "-r", "24",
    "-c:v", "libx264", "-crf", "18", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "160k",
    out ++ "proof_dadi_line008.mp4",
  ]
  Cinema_Backends.ffmpeg(args)
  Js.log("rendered " ++ out ++ "proof_dadi_line008.mp4  (" ++ f(dur) ++ "s, " ++ Belt.Int.toString(Js.Array2.length(vs)) ++ " visemes)")
}

let () =
  switch Belt.Array.get(argv, 2) {
  | Some("render") => renderProof()
  | _ => ()
  }
