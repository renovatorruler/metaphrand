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
  Js.Array2.joinWith(
    [
      "SHOT: WIDE ESTABLISHING PLATE, LANDSCAPE 16:9, full-bleed, the camera is INSIDE the world.",
      "STYLE: " ++ P.styleLaw ++ ". The FIRST attached image is the art style; match it EXACTLY.",
      "PALETTE: " ++ P.paletteLaw ++ ".",
      "BLUEPRINT: the SECOND attached image is a PLAN-VIEW MAP of this set, not a picture and not a style — read the landmark positions from it and place every landmark accordingly. Do not draw the map, draw the place. The map's WORDS AND NUMBERS ARE NOT PROPS: never carve, paint, letter or number any landmark in the picture; the markers are blank red paper wedges, the post is a blank stone post.",
      "TIME: this is the set BEFORE the story happens — nothing the episode later creates is here yet (no golden ga-shape on the flat stone, no cart, no rope).",
      "SET: " ++ S.setProse(s),
      "CAMERA: " ++ S.vantageProse(s, S.TopLookingDown),
      "LIGHTING: warm golden dusk — the last golden evening; the low sun gilds the paper flagstones.",
      "PURPOSE: this is a SET PLATE — the empty location itself, to be reused as the reference for every shot staged here. Every landmark must be clearly visible and correctly placed.",
      "HARD RULES:\n" ++
      P.bullets(
        Js.Array2.concat(
          [
            "the set is EMPTY: no dragons, no birds, no animals, no cow, no cart, no figures of any kind anywhere in frame",
            "no map, no plan view, no diagram, no floor plan, no blueprint lines, no arrows, no measurement marks in the picture",
          ],
          P.negatives,
        ),
      ),
    ],
    "\n",
  )

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
  let args = Js.Array2.concat(
    Js.Array2.concat(
      ["generate", "create", "nano_banana_pro", "--prompt", platePrompt(s)],
      Js.Array2.reduce(refs, (acc, r) => Js.Array2.concat(acc, ["--image", r]), []),
    ),
    ["--aspect_ratio", "16:9", "--resolution", "2k", "--wait", "--json"],
  )
  let raw = execFileSync("higgsfield", args, opts)
  switch firstUrl(raw, "(png|webp|jpg)") {
  | Some(url) => fetchTo(url, plateFile(s))
  | None => Js.log("FAIL plate " ++ S.setName(s) ++ " — " ++ Js.String2.slice(raw, ~from=0, ~to_=160))
  }
}

/* the camera pass: the empty set surveyed in one continuous move */
let surveySpec = (s): P.videoSpec => {
  scene: "A slow survey of an EMPTY papercraft set — no characters of any kind. " ++ S.setProse(s),
  cameraTravels: true,
  cast: [], /* a survey is deliberately empty of characters */
  blocking: [
    "the start image IS this set; every landmark stays exactly where the start image puts it",
    "nothing in the set moves — this is a still world; only the camera travels",
  ],
  beats: [
    "0.0-1.0s: the camera is still, at the stone post at the top of the lane",
    "1.0-4.0s: it travels slowly forward down the centreline, covering about EIGHTEEN METRES in total — roughly as far as the second red marker — and no further",
    "4.0-5.0s: it comes to rest. The closed stone wall is still far away in the distance at the end of the clip, exactly as far as eighteen metres of travel would leave it",
  ],
  camera: "one short bounded forward dolly of about eighteen metres down the lane centreline at head height, then a stop — no orbit, no whip, no cut, no zoom, and the camera never reaches or nears the end wall",
  physics: [
    "nothing animate exists here; no creature, no cart, no cow enters frame at any point",
    "the set is RIGID: the end wall, the stone post, the kerbs and every red marker keep their exact positions in the world for the whole clip",
    "the end wall only ever grows slowly nearer as the camera advances — it must never recede, never shrink, never move back, and the lane must never get longer",
    "red markers only ever pass out of frame behind the camera; no marker ever reappears and no new marker is ever added",
  ],
  lighting: "constant warm golden dusk, identical to the start image throughout, no time change",
  audio: "no dialogue, no music",
  extraRules: ["the set is EMPTY: no dragons, no birds, no animals, no cow, no cart, no figures at any point in the clip"],
}

let doSurvey = s => {
  let plate = plateFile(s)
  if !existsSync(plate) {
    Js.log("no approved plate for " ++ S.setName(s) ++ " — run `plate` first")
  } else {
    let args = [
      "generate",
      "create",
      "seedance_2_0_mini",
      "--prompt",
      P.videoPrompt(surveySpec(s)),
      "--start-image",
      plate,
      "--duration",
      "5",
      "--wait",
      "--json",
    ]
    let raw = execFileSync("higgsfield", args, opts)
    switch firstUrl(raw, "(mp4|webm|mov)") {
    | Some(url) => fetchTo(url, surveyFile(s))
    | None => Js.log("FAIL survey " ++ S.setName(s) ++ " — " ++ Js.String2.slice(raw, ~from=0, ~to_=160))
    }
  }
}

/* retouch: fix an approved-but-flawed plate in place, laws still code-rendered */
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
      extraRules: ["the set stays EMPTY: no dragons, birds, animals, cow, cart or figures"],
    }
    let raw = execFileSync(
      "higgsfield",
      ["generate", "create", "nano_banana_pro", "--prompt", P.editPrompt(spec), "--image", plate,
       "--aspect_ratio", "16:9", "--resolution", "2k", "--wait", "--json"],
      opts,
    )
    switch firstUrl(raw, "(png|webp|jpg)") {
    | Some(url) => fetchTo(url, plate)
    | None => Js.log("FAIL retouch — " ++ Js.String2.slice(raw, ~from=0, ~to_=160))
    }
  }
}


/* ---- style pass: Blender owns the geometry, nano owns the paper ----------- */
let stylePassPrompt = s =>
  Js.Array2.joinWith(
    [
      "TASK: the SECOND attached image is an untextured grey 3D BLOCKOUT of this set — the geometry and camera are already correct. Render that exact view as the finished illustration.",
      "STYLE: " ++ P.styleLaw ++ ". The FIRST attached image is the art style; match it EXACTLY.",
      "PALETTE: " ++ P.paletteLaw ++ ".",
      "KEEP FROM THE BLOCKOUT, EXACTLY: the camera angle, the perspective, the horizon line, the shape and fall of the ground, the position and size of every object in frame. Do not move anything, do not add architecture, do not change the viewpoint.",
      "THE BLOCKOUT IS THE AUTHORITY ON WHAT IS IN FRAME: render only the forms it actually shows. The set description below names landmarks that exist elsewhere in this location — any of them NOT present in the blockout is out of shot and must NOT be added.",
      "SET: " ++ S.setProse(s),
      "MATERIALS: flagstones become layered cut-paper slabs; kerbs become folded paper edges; the markers become blank red paper wedges; the wall becomes stacked paper stones; the ground becomes soft paper grass and hills.",
      "LIGHTING: warm golden dusk — the last golden evening, low grazing light and long soft shadows.",
      "HARD RULES:\n" ++
      P.bullets(
        Js.Array2.concat(
          [
            "the set is EMPTY: no dragons, no birds, no animals, no cow, no cart, no figures of any kind",
            "no grey untextured surfaces left anywhere — every surface is finished paper",
          ],
          P.negatives,
        ),
      ),
    ],
    "\n",
  )

let doStylePass = (s, blockout, dst) => {
  let args = [
    "generate", "create", "nano_banana_pro", "--prompt", stylePassPrompt(s),
    "--image", P.styleKey, "--image", blockout,
    "--aspect_ratio", "16:9", "--resolution", "2k", "--wait", "--json",
  ]
  let raw = execFileSync("higgsfield", args, opts)
  switch firstUrl(raw, "(png|webp|jpg)") {
  | Some(url) => fetchTo(url, dst)
  | None => Js.log("FAIL stylepass — " ++ Js.String2.slice(raw, ~from=0, ~to_=160))
  }
}

let mode = Js.Array2.length(argv) > 2 ? argv[2] : "blueprint"
let target = Js.Array2.length(argv) > 3 ? setOfName(argv[3]) : None

switch (mode, target) {
| ("blueprint", _) => doBlueprints()
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
      : "Remove every letter, word and number from the picture: no carved or painted text on the stone post, none on any stone, and no numerals on the red markers — the markers become blank plain red paper wedges and the post a blank plain stone post. Also remove the pale upright stone slab standing on the flat stretch near the wall entirely, leaving clean empty flagstones there.",
  )
| (m, _) =>
  Js.log(
    "usage: node src/KukuEp10_SetBible.res.mjs <blueprint|plate|survey|prompt> <lane|courtyard|flat_stone|tower|doorway|grass_verge>  (got: " ++
    m ++ ")",
  )
}
