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
let () = P.useStyleKey(root ++ "style/ep10_style_key.png")
let spritesDir = root ++ "cutout/sprites/"

/* THE KEY SHEET. A cutout is generated on one flat green paper sheet and keyed
   out. The green is named as a material the character stands on, never as a
   thing to remove — the gate would refuse that, and the model draws what it is
   told to remove. */
let keySheet = "one smooth flat sheet of bright green paper fills the entire background edge to edge, the same even green everywhere"

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

/* MOUTH SHAPES are edits of the SAME sprite, so the body stays identical and only
   the mouth changes; the mouth region is then cut out and swapped by the viseme
   track. A (rest) and X (silence) use the sprite's own closed mouth. */
let mouthEdit = (shape, change): P.editSpec => {
  change,
  keep: ["everything else exactly as it is: the same pose, the same shawl, the same staff, the same wings and tail, the same flat green background, the same framing"],
  extraRules: ["only the mouth of दादी changes; the mouth is a clean paper cutout in the same papercraft finish"],
}
let mouths = [
  ("open", "दादी's mouth open wide in a tall oval, as if saying a long AA sound"),
  ("round", "दादी's mouth pursed small and round, as if saying OO"),
  ("half", "दादी's mouth slightly open with the paper teeth just showing, as if saying EE"),
]
let mouth = shape =>
  switch Js.Array2.find(mouths, ((n, _)) => n == shape) {
  | Some((n, change)) =>
    ignore(Kuku_Engine.edit(~episode="EP10", ~id="sprite_dadi_mouth_" ++ n, ~spec=mouthEdit(n, change),
      ~src=spritesDir ++ "dadi_kneeling_raw.png", ~dst=spritesDir ++ "dadi_mouth_" ++ n ++ "_raw.png", ()))
  | None => Js.log("no mouth shape " ++ shape)
  }

let sprite = name =>
  switch name {
  | "dadi" =>
    ignore(Kuku_Engine.still(~episode="EP10", ~id="sprite_dadi_kneeling", ~spec=dadiKneeling,
      ~dst=spritesDir ++ "dadi_kneeling_raw.png", ()))
  | _ => Js.log("no sprite named " ++ name)
  }

let () = {
  mkdirSync(spritesDir, {"recursive": true})
  switch (Belt.Array.get(argv, 2), Belt.Array.get(argv, 3)) {
  | (Some("sprite"), Some(n)) => sprite(n)
  | (Some("mouth"), Some(n)) => mouth(n)
  | _ => Js.log("usage: sprite <name>")
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
