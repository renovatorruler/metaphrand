/* KukuEp10_SceneClips.res — scene 1 «भागती गाड़ी» rebuilt as MOTION.
   Four Seedance 2.5 clips carry the runaway from the moment the cart breaks
   away to the moment the failed lift sets it back down. Every prompt is
   rendered by Kuku_PromptSpec.videoPrompt from a typed spec; each clip is
   anchored to an approved still so the lane cannot be reinvented; and every
   move is BOUNDED in metres against the lane's own data, because an unbounded
   move is what made the wall breathe in the first survey.

   Run from studio/:
     node src/KukuEp10_SceneClips.res.mjs           # print prompts, price the batch
     node src/KukuEp10_SceneClips.res.mjs --go      # spend and download all
     node src/KukuEp10_SceneClips.res.mjs --go c2   # just one */

module P = Kuku_PromptSpec
module S = Kuku_Ep10Sets

@module("fs") external existsSync: string => bool = "existsSync"
type execOpts = {"encoding": string, "timeout": int}
@module("child_process")
external execFileSync: (string, array<string>, execOpts) => string = "execFileSync"
@scope("process") @val external argv: array<string> = "argv"

let opts = {"encoding": "utf8", "timeout": 1800000}
let ep10 = P.kukuRoot ++ "ep10prod/"
let stills = ep10 ++ "stills/"
let clips = ep10 ++ "clips/"

let laneSet = S.setProse(S.Lane)
let dragons = "The five dragon children are in their GREAT forms — ENORMOUS: a hay cart would fit between one's front claws and a grown man would reach only to her knee. KUKU is green, FYURIA orange-red, LEDA lilac-purple, CASTOR golden-yellow, VESPER pale blue; each wears a golden कड़ा cuff on one forearm. "

let commonBlocking = [
  "the start image IS this lane — the same flagstones, low kerbs, rubble wall along the right, stone post behind, and the same horizon and sun",
  "the cart runs along the CENTRELINE and never climbs either kerb",
  "गौरी the brown-and-white paper cow stays aboard the cart in EVERY frame, braced in the hay",
  "the three red paper markers sit on the centreline at 12, 24 and 36 metres; the closed stone end wall stays far away all clip and never comes near",
]
let commonPhysics = [
  "the lane is RIGID: kerbs, markers, post and wall keep their positions; the lane never lengthens and no marker reappears once passed",
  "wheels turn at a speed that matches the ground moving past them",
]
let commonRules = [
  "गौरी is in the cart in EVERY frame — a cart running empty is wrong",
  "no extra dragons beyond those named; never two of the same dragon",
]

type clip = {tag: string, start: string, secs: int, spec: P.videoSpec}

let all: array<clip> = [
  {
    tag: "c1_breaks_away",
    start: stills ++ "h15_cart_runs.png",
    secs: 10,
    spec: {
      scene: "The tethered hay cart breaks away and begins to run down the gurukul's flight-lane at golden dusk, गौरी braced inside it, the cut red rope whipping along behind. No dragon is in this shot. " ++ laneSet,
      blocking: Js.Array2.concat(commonBlocking, ["no dragon appears at any point in this clip — the lane belongs to the cart alone"]),
      beats: [
        "0.0-3.0s: the cart is already moving and gathering speed, hay lifting, the loose red rope snaking behind it",
        "3.0-7.0s: it runs on down the slope and the FIRST red marker slides past its wheels and away behind",
        "7.0-10.0s: still accelerating, now roughly twelve metres down the lane and no further",
      ],
      camera: "one continuous tracking shot alongside the cart at cart height, travelling at its speed — no cut, no zoom, no orbit, and the camera never turns back up the lane",
      physics: Js.Array2.concat(commonPhysics, ["the cart covers about twelve metres in total — from the top of the slope to the first marker — and no more"]),
      lighting: "constant warm golden dusk exactly as the start image, low sun, long soft shadows, no time change",
      audio: "no dialogue, no music",
      extraRules: commonRules,
    },
  },
  {
    tag: "c2_five_flank",
    start: stills ++ "h16_five_flank.png",
    secs: 5,
    spec: {
      scene: dragons ++ "All five sweep in and take up formation around the running cart. " ++ laneSet,
      blocking: Js.Array2.concat(commonBlocking, [
        "FYURIA flies lowest and furthest forward, KUKU on the cart's left, LEDA on its right with her head turned down to the lane, CASTOR tight beside it, VESPER highest of all",
        "each dragon towers over the cart — the cart is small beneath them",
      ]),
      beats: [
        "0.0-2.0s: the five drop into place around the running cart, wings spread wide",
        "2.0-5.0s: they hold formation and travel with it as it passes the SECOND marker",
      ],
      camera: "a continuous tracking shot alongside the cart and its escort at cart height, matching their speed — no cut, no zoom",
      physics: Js.Array2.concat(commonPhysics, ["the cart covers about eight metres in this clip and no more"]),
      lighting: "constant warm golden dusk exactly as the start image, no time change",
      audio: "no dialogue, no music",
      extraRules: commonRules,
    },
  },
  {
    tag: "c3_failed_lift",
    start: stills ++ "h17_group_lift.png",
    secs: 5,
    spec: {
      scene: dragons ++ "The five grip the cart's wheels and strain upward to lift it clear of the lane — and it does not come. " ++ laneSet,
      blocking: Js.Array2.concat(commonBlocking, [
        "KUKU has the front-left wheel, FYURIA the front-right, CASTOR the rear-left, LEDA the rear-right, VESPER the centre rail from above",
        "the cart's FRONT wheels come off the ground while the BACK wheels stay down, so the cart twists rather than rising",
      ]),
      beats: [
        "0.0-2.0s: all five take hold and heave, wings beating hard, the front of the cart lifting a little",
        "2.0-4.0s: the back stays planted; the cart twists on its axis and गौरी slides in the hay",
        "4.0-5.0s: the strain is plainly failing — the cart is still moving forward beneath them",
      ],
      camera: "one continuous low tracking shot alongside, at wheel height, matching the cart's speed — no cut, no zoom",
      physics: Js.Array2.concat(commonPhysics, [
        "the cart never leaves the ground completely; only the front wheels rise, by less than a wheel's height",
        "the cart covers about four metres in this clip",
      ]),
      lighting: "constant warm golden dusk exactly as the start image, no time change",
      audio: "no dialogue, no music",
      extraRules: commonRules,
    },
  },
  {
    tag: "c4_wheels_return",
    start: stills ++ "h19_wheels_return.png",
    secs: 5,
    spec: {
      scene: "The lift is abandoned: the cart's wheels come back down onto the flagstones, dust puffs out, and it runs on with गौरी still aboard. No dragon grips it any more. " ++ laneSet,
      blocking: Js.Array2.concat(commonBlocking, ["the dragons have let go and are out of frame or high above; the cart is alone on the lane again"]),
      beats: [
        "0.0-2.0s: all four wheels settle back onto the flagstones together and dust puffs out around them",
        "2.0-5.0s: the cart rights itself and runs on down the slope, गौरी braced, hay still lifting",
      ],
      camera: "a continuous low tracking shot at wheel height alongside the cart — no cut, no zoom",
      physics: Js.Array2.concat(commonPhysics, ["the cart covers about four metres in this clip"]),
      lighting: "constant warm golden dusk exactly as the start image, no time change",
      audio: "no dialogue, no music",
      extraRules: commonRules,
    },
  },
]

let argsFor = c => [
  "generate", "create", "seedance_2_5",
  "--prompt", P.videoPrompt(c.spec),
  "--mode", "omni_reference",
  "--start-image", c.start,
  "--duration", Belt.Int.toString(c.secs),
  "--resolution", "1080p",
  "--aspect_ratio", "16:9",
  "--wait", "--json",
]

let run = c => {
  let dst = clips ++ "SCENE1_" ++ c.tag ++ ".mp4"
  if existsSync(dst) {
    Js.log("skip (exists) " ++ c.tag)
  } else {
    let raw = execFileSync("higgsfield", argsFor(c), opts)
    switch Js.String2.match_(raw, Js.Re.fromString("https://[^\"\\s]*\\.(mp4|webm|mov)")) {
    | Some(m) =>
      switch m[0] {
      | Some(url) => {
          let _ = execFileSync("curl", ["-sL", "--retry", "3", "--create-dirs", "-o", dst, url], opts)
          Js.log("OK " ++ c.tag)
        }
      | None => Js.log("FAIL " ++ c.tag ++ " — no url")
      }
    | None => Js.log("FAIL " ++ c.tag ++ " — " ++ Js.String2.slice(raw, ~from=0, ~to_=200))
    }
  }
}

let only = Js.Array2.filter(argv, a => Js.String2.startsWith(a, "c"))
let chosen = Js.Array2.length(only) > 0
  ? Js.Array2.filter(all, c => Js.Array2.some(only, o => Js.String2.startsWith(c.tag, o)))
  : all

if Js.Array2.some(argv, a => a == "--go") {
  Js.Array2.forEach(chosen, run)
} else {
  Js.Array2.forEach(chosen, c => {
    let costArgs = Js.Array2.copy(argsFor(c))
    costArgs[1] = "cost"
    let _ = Js.Array2.removeCountInPlace(costArgs, ~pos=Js.Array2.length(costArgs) - 2, ~count=2)
    Js.log(
      c.tag ++
      "  " ++
      Belt.Int.toString(c.secs) ++
      "s  start=" ++
      (existsSync(c.start) ? "ok" : "MISSING") ++
      "  " ++ Js.String2.trim(execFileSync("higgsfield", costArgs, opts)),
    )
  })
}
