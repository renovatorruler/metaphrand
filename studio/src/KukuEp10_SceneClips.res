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
  S.greatFormStaging,
  "the lane is RIGID: kerbs, markers, post and wall keep their positions; the lane never lengthens and no marker reappears once passed",
  "wheels turn at a speed that matches the ground moving past them",
]
let commonRules = [
  "गौरी is in the cart in EVERY frame — a cart running empty is wrong",
  "no extra dragons beyond those named; never two of the same dragon",
]

type clip = {tag: string, start: string, secs: int, spec: P.videoSpec, talking: bool, cheap: bool}

let talkPhysics = [
  "the character stays where they are — this is a held shot, not a travelling one; no lunging toward or away from camera",
  "the mouth moves in natural speech throughout, jaw and lips working, with small head movements and blinks between phrases",
]

let all: array<clip> = [
  {
    talking: false,
    cheap: false,
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
    talking: false,
    cheap: false,
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
      camera: "a continuous tracking shot alongside the cart and its escort at cart height, matching their speed. The camera looks DOWN the lane in the direction of travel for the entire clip — it never faces back up the slope, never drifts rearward, and the flagstones must stream TOWARD the camera and out of the bottom of frame, never away from it. No cut, no zoom.",
      physics: Js.Array2.concat(commonPhysics, ["the cart covers about eight metres in this clip and no more"]),
      lighting: "constant warm golden dusk exactly as the start image, no time change",
      audio: "no dialogue, no music",
      extraRules: commonRules,
    },
  },
  {
    talking: false,
    cheap: false,
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
    talking: false,
    cheap: false,
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
  /* ---- scene 2 «निशान» — the braking ---- */
  {
    talking: false,
    cheap: false,
    tag: "s2a_furia_brakes",
    start: stills ++ "h20_furia_brake.png",
    secs: 5,
    spec: {
      scene: dragons ++ "FYURIA flies BACKWARDS ahead of the running cart, wings beating against it, trying to slow it. " ++ laneSet,
      blocking: Js.Array2.concat(commonBlocking, [
        "फ्यूरिया is ahead of the cart, facing back toward it, flying in reverse down the lane while the cart bears down on her",
        "she towers over the cart — the cart is small beneath her",
      ]),
      beats: [
        "0.0-2.0s: her wings sweep forward hard against the oncoming cart, paper dust rolling up between them",
        "2.0-5.0s: the cart slows a little but keeps coming; she is driven backwards down the lane by it",
      ],
      camera: "one continuous tracking shot alongside both of them at cart height, looking down the lane in the direction of travel; the flagstones stream toward the camera and out of the bottom of frame — no cut, no zoom",
      physics: Js.Array2.concat(commonPhysics, ["cart and dragon both continue to travel DOWN the lane throughout — she is losing ground, not pushing it back up", "the cart covers about five metres in this clip"]),
      lighting: "constant deepening golden dusk exactly as the start image, no time change",
      audio: "no dialogue, no music",
      extraRules: commonRules,
    },
  },
  {
    talking: false,
    cheap: false,
    tag: "s2b_marker_passes",
    start: stills ++ "h23_marker_pass.png",
    secs: 5,
    spec: {
      scene: "Close on the lane surface: the second flat red distance mark passes beneath the cart's rushing wheels. " ++ laneSet,
      blocking: [
        "the start image IS this lane — same flagstones, same kerbs, same light",
        "the red mark is FLUSH with the paving, an inlaid stone the wheels roll straight over without a bump",
        "no dragon in this shot",
      ],
      beats: [
        "0.0-2.5s: wooden wheels rush across frame, dust lifting from the flagstones",
        "2.5-5.0s: the flat red mark slides beneath them and away behind, out of the bottom of frame",
      ],
      camera: "a low locked-off camera close to the lane surface as the cart passes through frame — the camera itself does not travel",
      physics: Js.Array2.concat(commonPhysics, ["the wheels and the ground move in ONE direction across frame and never reverse"]),
      lighting: "constant deepening golden dusk exactly as the start image",
      audio: "no dialogue, no music",
      extraRules: ["no characters other than the cart and गौरी — no dragons enter frame"],
    },
  },
  {
    talking: true,
    cheap: false,
    tag: "s2c_castor_talks",
    start: stills ++ "h22_castor_calm.png",
    secs: 5,
    spec: {
      scene: dragons ++ "CASTOR flies close alongside the running cart with his head lowered toward गौरी, speaking to her gently to keep her calm. This is a DIALOGUE shot: he is talking. " ++ laneSet,
      blocking: Js.Array2.concat(commonBlocking, [
        "कैस्टर flies ALONG the lane directly above and behind the cart — nose forward over it, his long body and tail stretching back up the slope behind him, wings swept back. He lowers only his HEAD and neck down toward गौरी in the cart beneath him. He is never turned side-on across the lane",
        "गौरी looks up at him from the hay",
      ]),
      beats: [
        "0.0-5.0s: he speaks to her continuously and gently, mouth working, head dipping a little with the words; she watches him and her ears move",
      ],
      camera: "a held three-quarter shot travelling with them, looking slightly down the lane so the cart is in the lower half of frame and कैस्टर's head and neck come down into it from above and behind — his body reads as running away up the lane, not across it. No cut, no zoom, no camera reversal",
      physics: Js.Array2.concat(talkPhysics, [
        "SOLID BODIES: no part of any character ever passes through the kerb, the wall, the cart or the ground — tail, wings and limbs stay outside solid objects at all times",
        "the wall runs alongside the lane and stays a wall; nothing clips into it",
      ]),
      lighting: "constant deepening golden dusk exactly as the start image, no time change",
      audio: "SILENT: generate no speech and no music; this shot will be dubbed",
      extraRules: commonRules,
    },
  },
]

/* Seedance 2.5 needs mode=omni_reference before it will accept a start image;
   Mini has no mode parameter at all. Talking shots go to Mini — it cannot carry
   motion but holds a shot perfectly well, which is all dialogue asks — and its
   audio is discarded so the ElevenLabs take can be dubbed over. */
let argsFor = c => {
  let model = c.cheap ? "seedance_2_0_mini" : "seedance_2_5"
  let head = ["generate", "create", model, "--prompt", P.videoPrompt(c.spec)]
  let mode = c.cheap ? [] : ["--mode", "omni_reference"]
  let audio = c.cheap ? ["--generate_audio", "false"] : ["--generate_audio", "false"]
  Js.Array2.concatMany(head, [
    mode,
    ["--start-image", c.start],
    audio,
    ["--duration", Belt.Int.toString(c.secs)],
    ["--resolution", c.cheap ? "720p" : "1080p"],
    ["--aspect_ratio", "16:9", "--wait", "--json"],
  ])
}

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
