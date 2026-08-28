/* KukuEp10_SetBible.res — build EP10's set bible from Kuku_Ep10Sets data.

   Stages, each gated by the author:
     blueprint   write the plan-view SVGs (free) — geography approved first
     plate <set> generate the empty-set master plate (nano, 2cr)
     survey <set> a Seedance Mini camera pass over the approved plate (12.5cr)
     angles <set> extract vantage plates from the survey clip (free)

   Run from studio/: node src/KukuEp10_SetBible.res.mjs blueprint */

module S = Kuku_Ep10Sets
module P = Kuku_PromptSpec

@module("fs") external writeFileSync: (string, string) => unit = "writeFileSync"
@module("fs") external existsSync: string => bool = "existsSync"
@module("fs") external mkdirSync: (string, {"recursive": bool}) => unit = "mkdirSync"
type execOpts = {"encoding": string, "timeout": int}
@module("child_process")
external execFileSync: (string, array<string>, execOpts) => string = "execFileSync"
@scope("process") @val external argv: array<string> = "argv"

let opts = {"encoding": "utf8", "timeout": 900000}
let dir = P.kukuRoot ++ "ep10prod/sets/"
mkdirSync(dir, {"recursive": true})

let sets = [S.Lane, S.Courtyard, S.FlatStone, S.Tower, S.Doorway, S.GrassVerge]

let setOfName = n =>
  Js.Array2.find(sets, s => S.setName(s) == n)

/* ---- the master plate: the set itself, empty of characters ---------------- */
let platePrompt = s =>
  PromptGate.pass(~which="platePrompt", Js.Array2.joinWith(
    [
      "SHOT: WIDE ESTABLISHING PLATE, LANDSCAPE 16:9, full-bleed, the camera is INSIDE the world.",
      "STYLE: " ++ P.styleLaw ++ ". The FIRST attached image is the art style; match it EXACTLY.",
      "PALETTE: " ++ P.paletteLaw ++ ".",
      "BLUEPRINT: the SECOND attached image is a PLAN-VIEW MAP of this set — read the landmark positions from it, then draw the PLACE ITSELF seen from inside the world. Every landmark stands blank and plain: the markers are flat red paving stones, the post is a bare stone post, every face of stone smooth and empty.",
      "TIME: this is the set BEFORE the story happens — every flagstone bare, the flat stone bare, the lane open and empty from top to wall.",
      "SET: " ++ S.setProse(s),
      "VIEWPOINT: " ++ S.vantageProse(s, S.TopLookingDown),
      "LIGHTING: warm golden dusk — the last golden evening; the low sun gilds the paper flagstones. THE SUN STANDS OFF TO ONE SIDE, well clear of the viewing axis, so every landmark is LIT full-face and every colour in the place stays full — green hills, blue water, snow on the far peaks.",
      "PURPOSE: this is a SET PLATE — the empty location itself, to be reused as the reference for every shot staged here. Every landmark must be clearly visible and correctly placed.",
      "HARD RULES:\n" ++
      P.bullets(
        Js.Array2.concat(
          [
            "the set stands EMPTY and still: bare flagstones, open sky, architecture and landscape alone — the whole cast of this picture is the place itself",
            "the picture is the finished place seen from inside the world, rendered edge to edge, with open air between the viewer and every landmark",
          ],
          P.worldFacts,
        ),
      ),
    ],
    "\n",
  ))

let plateFile = s => dir ++ S.setName(s) ++ "_plate.png"
let blueprintSvg = s => dir ++ S.setName(s) ++ "_blueprint.svg"
let blueprintPng = s => dir ++ S.setName(s) ++ "_blueprint.png"
let surveyFile = s => dir ++ S.setName(s) ++ "_survey.mp4"

let firstUrl = (raw, ext) =>
  switch Js.String2.match_(raw, Js.Re.fromString("https://[^\"\\s]*\\." ++ ext)) {
  | Some(m) => m[0]
  | None => None
  }

let fetchTo = (url, dst) => {
  let _ = execFileSync("curl", ["-sL", "--retry", "3", "--create-dirs", "-o", dst, url], opts)
  Js.log("saved " ++ dst)
}

/* ---- stages ---------------------------------------------------------------- */
let doBlueprints = () =>
  Js.Array2.forEach(sets, s => {
    writeFileSync(blueprintSvg(s), S.blueprint(s))
    Js.log("blueprint " ++ S.setName(s))
  })

let doPlate = s => {
  let bp = blueprintPng(s)
  let refs = existsSync(bp) ? [P.styleKey, bp] : [P.styleKey]
  if !existsSync(bp) {
    Js.log("NOTE: no blueprint PNG for " ++ S.setName(s) ++ " — generating from prose alone")
  }
  ignore(Kuku_Engine.plate(~id=S.setName(s) ++ "_plate", ~prompt=platePrompt(s), ~refs, ~dst=plateFile(s), ()))
}

/* the camera pass: the empty set surveyed in one continuous move */
let surveySpec = (s): P.videoSpec => {
  scene: "A slow survey of an EMPTY papercraft set, the place itself the whole subject. " ++ S.setProse(s),
  cameraTravels: true,
  cast: [], /* a survey is deliberately empty of characters */
  blocking: [
    "the start image IS this set; every landmark stays exactly where the start image puts it",
    "the set holds perfectly still — a still world, the camera the only thing that travels",
  ],
  beats: [
    "0.0-1.0s: the camera is still, at the stone post at the top of the lane",
    "1.0-4.0s: it travels slowly forward down the centreline, its whole travel about EIGHTEEN METRES — coming to rest roughly level with the second red marker",
    "4.0-5.0s: it comes to rest. The closed stone wall is still far away in the distance at the end of the clip, exactly as far as eighteen metres of travel would leave it",
  ],
  camera: "one single short forward dolly of about eighteen metres down the lane centreline at head height, then a full stop, the end wall still far away at the finish",
  physics: [
    "the place itself is the complete cast — bare ground and standing architecture from first frame to last",
    "the set is RIGID: the end wall, the stone post, the kerbs and every red marker keep their exact positions in the world for the whole clip",
    "the end wall grows slowly and steadily nearer as the camera advances, and the lane keeps its exact length from first frame to last",
    "each red marker passes out of frame behind the camera exactly once, and exactly three markers exist in the whole lane",
  ],
  lighting: "constant warm golden dusk, identical to the start image throughout, the light holding steady for the whole clip",
  audio: "",
  extraRules: ["the set stays EMPTY for the whole clip: bare flagstones, open sky, the place itself the only subject"],
}

let doSurvey = s => {
  let plate = plateFile(s)
  if !existsSync(plate) {
    Js.log("no approved plate for " ++ S.setName(s) ++ " — run `plate` first")
  } else {
    ignore(Kuku_Engine.clip(~id=S.setName(s) ++ "_survey", ~spec=surveySpec(s),
      ~model="seedance_2_0_mini", ~secs=5, ~start=plate, ~dst=surveyFile(s), ()))
  }
}

let doRetouch = (s, change) => {
  let plate = plateFile(s)
  if !existsSync(plate) {
    Js.log("no plate for " ++ S.setName(s))
  } else {
    let bak = dir ++ S.setName(s) ++ "_plate_PRE_RETOUCH.png"
    if !existsSync(bak) {
      let _ = execFileSync("cp", [plate, bak], opts)
    }
    let spec: P.editSpec = {
      change,
      keep: [
        "the exact geography: the post at the top LEFT, the three red markers evenly spaced on the centreline, the flat stretch, the closed stone wall across the far end",
        "the same camera, the same perspective, the same golden dusk light",
      ],
      extraRules: ["the set stays EMPTY and still: bare ground, open sky, architecture and landscape alone"],
    }
    ignore(Kuku_Engine.edit(~id=S.setName(s) ++ "_retouch", ~spec, ~src=plate, ~dst=plate, ()))
  }
}

/* ---- style pass: Blender owns the geometry, nano owns the paper ----------- */
let stylePassPrompt = s =>
  PromptGate.pass(~which="stylePassPrompt", Js.Array2.joinWith(
    [
      "TASK: the SECOND attached image is an untextured grey 3D BLOCKOUT of this set — the geometry and camera are already correct. Render that exact view as the finished illustration.",
      "STYLE: " ++ P.styleLaw ++ ". The FIRST attached image is the art style; match it EXACTLY.",
      "PALETTE: " ++ P.paletteLaw ++ ".",
      "KEEP FROM THE BLOCKOUT, EXACTLY: the viewpoint, the perspective, the horizon line, the shape and fall of the ground, and the position and size of every object in frame, all held exactly where the blockout puts them.",
      "THE BLOCKOUT IS THE AUTHORITY ON WHAT IS IN FRAME: render exactly the forms it shows, the full list of them and only that list. The set description below covers the whole location; the blockout chooses which part of it this picture holds.",
      "SET: " ++ S.setProse(s),
      "MATERIALS: flagstones become layered cut-paper slabs; kerbs become folded paper edges; the markers become blank red paper wedges; the wall becomes stacked paper stones; the ground becomes soft paper grass and hills.",
      "LIGHTING: warm golden dusk — the last golden evening, low grazing light and long soft shadows.",
      "HARD RULES:\n" ++
      P.bullets(
        Js.Array2.concat(
          [
            "the set stands EMPTY and still: bare ground, open sky, architecture and landscape alone",
            "every surface is finished paper, textured corner to corner",
          ],
          P.worldFacts,
        ),
      ),
    ],
    "\n",
  ))

let doStylePass = (s, blockout, dst) => {
  ignore(Kuku_Engine.plate(~id=S.setName(s) ++ "_stylepass", ~prompt=stylePassPrompt(s),
    ~refs=[P.styleKey, blockout], ~dst, ()))
}

let mode = Js.Array2.length(argv) > 2 ? argv[2] : "blueprint"
let target = Js.Array2.length(argv) > 3 ? setOfName(argv[3]) : None

switch (mode, target) {
| ("blueprint", _) => doBlueprints()
| ("gate", _) => {
    let bad = ref(0)
    let try_ = (label, f) =>
      try {ignore(f())} catch {
      | Js.Exn.Error(err) => {
          bad := bad.contents + 1
          Js.log("== " ++ label ++ " ==")
          Js.log(switch Js.Exn.message(err) { | Some(m) => m | None => "?" })
        }
      }
    Js.Array2.forEach(sets, s => {
      try_(S.setName(s) ++ " plate", () => platePrompt(s))
      try_(S.setName(s) ++ " style", () => stylePassPrompt(s))
      try_(S.setName(s) ++ " survey", () => P.videoPrompt(surveySpec(s)))
    })
    if bad.contents > 0 {
      Js.Exn.raiseError(Belt.Int.toString(bad.contents) ++ " set prompts forbid")
    }
    Js.log("PROMPT GATE CLEAN: plates, style passes and surveys for " ++ Belt.Int.toString(Js.Array2.length(sets)) ++ " sets")
  }
| ("plate", Some(s)) => doPlate(s)
| ("survey", Some(s)) => doSurvey(s)
| ("prompt", Some(s)) => Js.log(platePrompt(s))
| ("stylepass", Some(s)) => {
    let tag = Js.Array2.length(argv) > 4 ? argv[4] : "bottom_looking_up"
    doStylePass(
      s,
      dir ++ "blender/" ++ S.setName(s) ++ "_" ++ tag ++ "_blockout.png",
      dir ++ S.setName(s) ++ "_" ++ tag ++ "_plate.png",
    )
  }
| ("retouch", Some(s)) =>
  doRetouch(
    s,
    Js.Array2.length(argv) > 4
      ? argv[4]
      : "Make every surface blank plain paper: the markers become blank plain red paving stones, the post a blank plain stone post, every stone face smooth and empty. Also lift the pale upright stone slab off the flat stretch near the wall entirely, continuing the clean flagstones where it stood.",
  )
| (m, _) =>
  Js.log(
    "usage: node src/KukuEp10_SetBible.res.mjs <blueprint|plate|survey|prompt> <lane|courtyard|flat_stone|tower|doorway|grass_verge>  (got: " ++
    m ++ ")",
  )
}
