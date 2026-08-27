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
/* No blanket cast blurb any more: naming dragons who are not in the shot invited
   the model to draw them. Each clip declares only its own cast, and the colour,
   scale and bracelet laws come from Kuku_PromptSpec.subjectText — the same law
   the stills use. */
let d = (name, doing) => P.Dragon({name, form: P.Great, doing})
let cow = doing => P.Gauri({doing: doing})

let commonBlocking = [
  "the start image IS this lane — the same flagstones, low kerbs, rubble wall along the right, stone post behind, and the same horizon and sun",
  "the cart runs along the CENTRELINE, wheels on the flagstones the whole way, the kerbs sliding past on either side",
  "गौरी the brown-and-white paper cow stays aboard the cart in EVERY frame, braced in the hay",
  "the three red paper markers sit on the centreline at 12, 24 and 36 metres; the closed stone end wall stays a distant line at the bottom of the slope for the whole clip",
]
let commonPhysics = [
  S.greatFormStaging,
  S.greatFormFraming,
  "the lane is RIGID: kerbs, markers, post and wall keep their positions, the lane keeps its exact length, and each marker slides past exactly once",
  "wheels turn at a speed that matches the ground moving past them",
]
let commonRules = [
  "गौरी is in the cart in EVERY frame — a cart running empty is wrong",
]

type clip = {tag: string, start: string, endFrame: string, secs: int, spec: P.videoSpec, talking: bool, cheap: bool}

let talkPhysics = [
  S.greatFormStaging,
  S.greatFormFraming,
  "the character stays planted on the same spot for the whole clip — a held shot, the body anchored, the head, mouth and wings carrying the performance",
  "the mouth moves in natural speech throughout, jaw and lips working, with small head movements and blinks between phrases",
]

let all: array<clip> = [
  {
    talking: false,
    cheap: false,
    tag: "c1_breaks_away",
    start: stills ++ "h15_cart_runs.png",
    endFrame: "",
    secs: 10,
    spec: {
      scene: "The tethered hay cart breaks away and begins to run down the gurukul's flight-lane at golden dusk, गौरी braced inside it, the cut red rope whipping along behind. The cart and गौरी are the complete cast of this clip. " ++ laneSet,
      cameraTravels: true,
      cast: [cow("braced in the running cart")],
      blocking: Js.Array2.concat(commonBlocking, ["the cart and गौरी are the complete cast from first frame to last — the lane belongs to them alone"]),
      beats: [
        "0.0-3.0s: the cart is already moving and gathering speed, hay lifting, the loose red rope snaking behind it",
        "3.0-7.0s: it runs on down the slope and the FIRST red marker slides past its wheels and away behind",
        "7.0-10.0s: still accelerating, reaching roughly twelve metres down the lane by the last frame",
      ],
      camera: "one single continuous tracking shot alongside the cart at cart height, travelling at its speed, holding one framing and facing DOWN the lane from first frame to last",
      physics: Js.Array2.concat(commonPhysics, ["the cart's whole travel this clip is about twelve metres — from the top of the slope to the first marker"]),
      lighting: "constant warm golden dusk exactly as the start image, low sun, long soft shadows, the light holding steady for the whole clip",
      audio: "",
      extraRules: commonRules,
    },
  },
  {
    talking: false,
    cheap: false,
    tag: "c2_five_flank",
    start: stills ++ "h16_five_flank.png",
    endFrame: "",
    secs: 5,
    spec: {
      scene: "All five sweep in and take up formation around the running cart. " ++ laneSet,
      cameraTravels: true,
      cast: [d(P.Fyuria, "lowest and furthest forward"), d(P.Kuku, "on the cart's left"), d(P.Leda, "on the cart's right, head turned down to the lane"), d(P.Castor, "tight beside the cart"), d(P.Vesper, "highest of all"), cow("braced in the running cart")],
      blocking: Js.Array2.concat(commonBlocking, [
        "FYURIA flies lowest and furthest forward, KUKU on the cart's left, LEDA on its right with her head turned down to the lane, CASTOR tight beside it, VESPER highest of all",
        "each dragon towers over the cart — the cart is small beneath them",
      ]),
      beats: [
        "0.0-2.0s: the five drop into place around the running cart, wings spread wide",
        "2.0-5.0s: they hold formation and travel with it as it passes the SECOND marker",
      ],
      camera: "a continuous tracking shot alongside the cart and its escort at cart height, matching their speed. The camera looks DOWN the lane in the direction of travel for the entire clip, holding that facing to the last frame, and the flagstones stream TOWARD the camera and out of the bottom of frame the whole time. One continuous take.",
      physics: Js.Array2.concat(commonPhysics, ["the cart's whole travel this clip is about eight metres"]),
      lighting: "constant warm golden dusk exactly as the start image, the light holding steady for the whole clip",
      audio: "",
      extraRules: commonRules,
    },
  },
  {
    talking: false,
    cheap: false,
    tag: "c3_failed_lift",
    start: stills ++ "h17_group_lift.png",
    endFrame: "",
    secs: 5,
    spec: {
      scene: "The five grip the cart's wheels and strain upward to lift it clear of the lane — and it stays down. " ++ laneSet,
      cameraTravels: true,
      cast: [d(P.Kuku, "front-left wheel"), d(P.Fyuria, "front-right wheel"), d(P.Castor, "rear-left wheel"), d(P.Leda, "rear-right wheel"), d(P.Vesper, "the centre rail from above"), cow("sliding in the hay as the cart twists")],
      blocking: Js.Array2.concat(commonBlocking, [
        "KUKU has the front-left wheel, FYURIA the front-right, CASTOR the rear-left, LEDA the rear-right, VESPER the centre rail from above",
        "the cart's FRONT wheels come off the ground while the BACK wheels stay down, so the cart twists rather than rising",
      ]),
      beats: [
        "0.0-2.0s: all five take hold and heave, wings beating hard, the front of the cart lifting a little",
        "2.0-4.0s: the back stays planted; the cart twists on its axis and गौरी slides in the hay",
        "4.0-5.0s: the strain is plainly failing — the cart is still moving forward beneath them",
      ],
      camera: "one single continuous low tracking shot alongside, at wheel height, matching the cart's speed",
      physics: Js.Array2.concat(commonPhysics, [
        "the back wheels stay planted on the flagstones; only the front wheels rise, by less than a wheel's height",
        "the cart covers about four metres in this clip",
      ]),
      lighting: "constant warm golden dusk exactly as the start image, the light holding steady for the whole clip",
      audio: "",
      extraRules: commonRules,
    },
  },
  {
    talking: false,
    cheap: false,
    tag: "c4_wheels_return",
    start: stills ++ "h19_wheels_return.png",
    endFrame: "",
    secs: 5,
    spec: {
      scene: "The lift is abandoned: the cart's wheels come back down onto the flagstones, dust puffs out, and it runs on with गौरी still aboard. Every dragon has let go of it. " ++ laneSet,
      cameraTravels: true,
      cast: [cow("braced in the cart as it settles and runs on")],
      blocking: Js.Array2.concat(commonBlocking, ["the dragons have let go and are out of frame or high above; the cart is alone on the lane again"]),
      beats: [
        "0.0-2.0s: all four wheels settle back onto the flagstones together and dust puffs out around them",
        "2.0-5.0s: the cart rights itself and runs on down the slope, गौरी braced, hay still lifting",
      ],
      camera: "one single continuous low tracking shot at wheel height alongside the cart",
      physics: Js.Array2.concat(commonPhysics, ["the cart covers about four metres in this clip"]),
      lighting: "constant warm golden dusk exactly as the start image, the light holding steady for the whole clip",
      audio: "",
      extraRules: commonRules,
    },
  },
  /* ---- scene 0-अ — the knot lets go: the episode's inciting incident ---- */
  {
    talking: false,
    cheap: false,
    tag: "s0b_rope_slips",
    start: stills ++ "h12_rope_slip.png",
    endFrame: "",
    secs: 5,
    spec: {
      scene: "The tethered cart's rope gives way: the knot at the stone post works loose, the last loop pulls free, and the rope end whips away after the cart.",
      cameraTravels: false,
      cast: [
        P.Prop({what: "THE ROPE", doing: "thick red paper twine, pulled taut around the weathered stone post"}),
      ],
      blocking: [
        "the start image IS this post and this knot — the same stone, the same rope, the same light",
        "the stone post holds perfectly still, exactly as the start image has it",
      ],
      beats: [
        "0.0-1.5s: the rope is stretched tight and trembling under load, its paper fibres straining, one loop creeping a little around the post",
        "1.5-3.0s: the loops slide, turn by turn, the knot opening as the load pulls it apart",
        "3.0-5.0s: the last loop lets go and the freed rope end whips away out of frame, leaving the post bare",
      ],
      camera: "one locked-off CLOSE camera on the post and knot, held perfectly still for the whole clip",
      physics: [
        "the rope moves like stiff paper twine — it bends at creases and holds its shape, stiff from end to end",
        "once the knot begins to give it keeps giving; the loops only ever loosen",
        "the post stays exactly where it is and keeps its shape throughout",
      ],
      lighting: "constant warm golden dusk exactly as the start image",
      audio: "",
      extraRules: [],
    },
  },
  /* ---- scene 0-अ — चील takes the bell ---- */
  {
    talking: false,
    cheap: false,
    tag: "s0c_bell_taken",
    start: stills ++ "h13_bell_taken.png",
    endFrame: "",
    secs: 5,
    spec: {
      scene: "चील takes the bell: perched on the stone arch beside it, she works the bronze binding open, the bell drops free into her talons, and she lifts away with it.",
      cameraTravels: false,
      cast: [
        P.Cheel({doing: "perched on the arch beside the hanging bell, working its binding loose, then lifting away with the bell in her talons"}),
        P.Prop({what: "THE BELL", doing: "bronze, hanging from the crown of the arch on its cord, warm and gleaming"}),
      ],
      blocking: [
        "the start image IS this arch and this bell — the same stone, the same cord, the same sky and light",
        "the stone arch holds perfectly still throughout, exactly as the start image has it",
        "she is the only creature in frame",
      ],
      beats: [
        "0.0-1.5s: she leans in and works the bronze binding at the crown of the arch with her beak and talons, the bell swinging a little as it loosens",
        "1.5-2.5s: the binding gives and the bell drops free, caught in her talons, swinging under her once",
        "2.5-5.0s: her great wings open and beat down, and she lifts away from the arch with the bell held beneath her, rising out of the top of frame",
      ],
      camera: "one locked-off MEDIUM camera on the arch, held perfectly still for the whole clip, with sky above so she has room to rise into it",
      physics: [
        "the bell hangs and swings from a single point like a real bell on a cord, and once caught it hangs from her talons the same way",
        "her wings move like stiff cut paper, and the downbeat is what lifts her — she rises only when they beat",
        "the arch, its stones and the cord keep their shapes; only the bell and the eagle move",
      ],
      lighting: "constant warm golden dusk exactly as the start image",
      audio: "",
      extraRules: [],
    },
  },
  /* ---- scene 0 «उड़ान-आँगन» — the ring drill ---- */
  {
    talking: false,
    cheap: false,
    tag: "s0a_furia_ring",
    start: stills ++ "h53_ring_drill_wide.png",
    endFrame: stills ++ "h53_ring_drill_wide.png", /* loops, so copies stitch */
    secs: 5,
    spec: {
      scene: "फ्यूरिया flies one complete circuit of the drill: up from her mark, through the opening of the great stone ring, round behind it and back down to land on the same mark, exactly as she began. The clip ends where it started.",
      cameraTravels: false,
      cast: [d(P.Fyuria, "flying one circuit: mark, through the ring, round and back to the mark")],
      blocking: [
        "the start image IS this courtyard — the same flagstones, the same ring, the same sky and light",
        "the RING holds perfectly still, exactly as the start image has it; it is fourteen metres across, and she passes through its opening with her wings spread",
      ],
      beats: [
        "0.0-1.2s: she crouches on the marked flagstone and launches toward the ring, paper dust curling from the stones beneath her",
        "1.2-2.4s: she flies INTO the ring's opening and through it, crossing from the near side of the ring to the far side",
        "2.4-3.6s: beyond the ring she banks round in a wide arc and comes back toward the courtyard",
        "3.6-5.0s: she settles onto the same marked flagstone in exactly the pose she began in, ready to go again",
      ],
      camera: "one locked-off WIDE camera on the courtyard floor, held perfectly still for the whole clip, the ring centred and whole in frame with sky above it",
      physics: [
        "PROOF OF PASSAGE: as she goes through, the ring's near rim briefly passes in front of her body, hiding part of her for a moment, and on the far side the ring's stone is nearer to camera than she is",
        "SEAMLESS LOOP: the final frame matches the first exactly — same place on the mark, same pose, same wing position — so the clip can play again straight after itself",
        "she passes cleanly through the empty middle of the opening, well clear of the stone",
      ],
      lighting: "constant warm golden dusk exactly as the start image — low sun, long soft shadows",
      audio: "",
      extraRules: [],
    },
  },
  /* The circuit above loops three times; this is the fourth and last, the one
     that finishes ऋषि's instruction — «घेरे से निकलो, घंटी छुओ और अपनी जगह पर लौटो».
     It begins on the same frame the loop ends on, so it stitches straight after. */
  {
    talking: false,
    cheap: false,
    tag: "s0d_bell_touch",
    start: stills ++ "h53_ring_drill_wide.png",
    endFrame: "",
    secs: 5,
    spec: {
      scene: "फ्यूरिया flies her last circuit and finishes the drill: up from her mark, through the opening of the great stone ring, and as she passes she brushes the bronze bell hanging inside it with one claw so that it rings. Then she comes round and lands back on her mark, pleased with herself.",
      cameraTravels: false,
      cast: [d(P.Fyuria, "flying through the ring and brushing the bell with one claw as she passes")],
      blocking: [
        "the start image IS this courtyard — the same flagstones, the same ring, the same bell, the same sky and light",
        "the RING holds perfectly still, exactly as the start image has it; it is fourteen metres across, and she passes through its opening with her wings spread",
        "THE BELL HANGS INSIDE THE RING and stays hanging on its hook from first frame to last — her claw meets it for one instant and travels on, and the bell swings in place behind her",
      ],
      beats: [
        "0.0-1.2s: she crouches on the marked flagstone and launches toward the ring, paper dust curling from the stones beneath her",
        "1.2-2.6s: she flies INTO the ring's opening, and as she passes the hanging bell she reaches out ONE FORELIMB and brushes it lightly with a claw",
        "2.6-3.0s: the bell swings on its hook from the touch and rings",
        "3.0-5.0s: beyond the ring she banks round in a wide arc, comes back and settles onto the same marked flagstone, chin lifted",
      ],
      camera: "one locked-off WIDE camera on the courtyard floor, held perfectly still for the whole clip, the ring centred and whole in frame with sky above it",
      physics: [
        "PROOF OF PASSAGE: as she goes through, the ring's near rim briefly passes in front of her body, hiding part of her for a moment, and on the far side the ring's stone is nearer to camera than she is",
        "A PASSING BRUSH: the claw makes contact for one moment and travels on; the bell is left swinging on its hook, still hanging in the ring",
        "the bell swings from its single hook like a real bell, pivoting at that one point",
        "she passes cleanly through the empty middle of the opening, well clear of the stone",
      ],
      lighting: "constant warm golden dusk exactly as the start image — low sun, long soft shadows",
      audio: "",
      extraRules: [],
    },
  },
  /* ---- scene 2 «निशान» — the braking ---- */
  {
    talking: false,
    cheap: false,
    tag: "s2a_furia_brakes",
    start: stills ++ "h20_furia_brake.png",
    endFrame: "",
    secs: 5,
    spec: {
      scene: "FYURIA flies BACKWARDS ahead of the running cart, wings beating against it, trying to slow it. " ++ laneSet,
      cameraTravels: true,
      cast: [d(P.Fyuria, "flying backwards ahead of the cart, wings beating against it"), cow("braced in the running cart")],
      blocking: Js.Array2.concat(commonBlocking, [
        "फ्यूरिया is ahead of the cart, facing back toward it, flying in reverse down the lane while the cart bears down on her",
        "she towers over the cart — the cart is small beneath her",
      ]),
      beats: [
        "0.0-2.0s: her wings sweep forward hard against the oncoming cart, paper dust rolling up between them",
        "2.0-5.0s: the cart slows a little but keeps coming; she is driven backwards down the lane by it",
      ],
      camera: "one single continuous tracking shot alongside both of them at cart height, looking down the lane in the direction of travel, the flagstones streaming toward the camera and out of the bottom of frame",
      physics: Js.Array2.concat(commonPhysics, ["cart and dragon both continue to travel DOWN the lane throughout — the cart still winning against her push", "the cart covers about five metres in this clip"]),
      lighting: "constant deepening golden dusk exactly as the start image, the light holding steady for the whole clip",
      audio: "",
      extraRules: commonRules,
    },
  },
  {
    talking: false,
    cheap: false,
    tag: "s2b_marker_passes",
    start: stills ++ "h23_marker_pass.png",
    endFrame: "",
    secs: 5,
    spec: {
      scene: "Close on the lane surface: the second flat red distance mark passes beneath the cart's rushing wheels. " ++ laneSet,
      cameraTravels: false,
      cast: [cow("braced in the cart as it rushes through frame")],
      blocking: [
        "the start image IS this lane — same flagstones, same kerbs, same light",
        "the red mark is FLUSH with the paving, an inlaid stone the wheels roll straight over, the cart staying level as it passes",
        "the cart and गौरी are the complete cast of this clip",
      ],
      beats: [
        "0.0-2.5s: wooden wheels rush across frame, dust lifting from the flagstones",
        "2.5-5.0s: the flat red mark slides beneath them and away behind, out of the bottom of frame",
      ],
      camera: "a low LOCKED camera fixed in place close to the lane surface, holding one framing as the cart passes through frame",
      physics: Js.Array2.concat(commonPhysics, ["the wheels and the ground move in ONE direction across frame from first frame to last"]),
      lighting: "constant deepening golden dusk exactly as the start image",
      audio: "",
      extraRules: ["the cart and गौरी are the complete cast of this clip"],
    },
  },
  {
    talking: true,
    cheap: false,
    tag: "s2c_castor_talks",
    start: stills ++ "h22_castor_calm.png",
    endFrame: "",
    secs: 5,
    spec: {
      scene: "A DIALOGUE beat: कैस्टर keeps गौरी calm as the cart runs, talking to her the whole time. " ++ laneSet,
      cameraTravels: true,
      cast: [d(P.Castor, "speaking gently down to her"), cow("looking up at him from the hay")],
      blocking: Js.Array2.concat(commonBlocking, [
        "कैस्टर flies ALONG the lane directly above and behind the cart — nose forward over it, his long body and tail stretching back up the slope behind him, wings swept back. He lowers only his HEAD and neck down toward गौरी in the cart beneath him. He stays nose-forward in line with the lane the whole clip",
        "गौरी looks up at him from the hay",
      ]),
      beats: [
        "0.0-5.0s: he speaks to her continuously and gently, mouth working, head dipping a little with the words; she watches him and her ears move",
      ],
      camera: "a WIDE tracking shot, the camera well back and leading them down the lane so the full width of the lane, both kerbs and a band of sky are in frame. कैस्टर occupies the LEFT of frame and the cart the RIGHT, clearly separated, with open space above and behind him. One continuous take, facing down the lane throughout",
      physics: Js.Array2.concat(talkPhysics, [
        "SOLID BODIES: kerb, wall, cart and ground are solid stone and wood — every tail, wing and limb travels through open air, clear of them at all times",
        "the wall runs alongside the lane and stays a solid wall the whole clip",
      ]),
      lighting: "constant deepening golden dusk exactly as the start image, the light holding steady for the whole clip",
      audio: "SILENT — the picture alone carries this shot; the voice is dubbed in later",
      extraRules: commonRules,
    },
  },
]

/* Seedance 2.5 needs mode=omni_reference before it will accept a start image;
   Mini has no mode parameter at all. Talking shots go to Mini — it cannot carry
   motion but holds a shot perfectly well, which is all dialogue asks — and its
   audio is discarded so the ElevenLabs take can be dubbed over. */
let argsFor = c => {
  let model = c.cheap ? "seedance_2_0_mini" : "seedance_2_0"
  let head = ["generate", "create", model, "--prompt", P.videoPrompt(c.spec)]
  /* 2.0 takes a start image directly; only 2.5 needs the extra mode flag */
  let mode = []
  let audio = c.cheap ? ["--generate_audio", "false"] : ["--generate_audio", "false"]
  Js.Array2.concatMany(head, [
    mode,
    ["--start-image", c.start],
    c.endFrame == "" ? [] : ["--end-image", c.endFrame],
    audio,
    ["--duration", Belt.Int.toString(c.secs)],
    ["--resolution", "720p"],
    ["--bitrate_mode", "high"],
    ["--aspect_ratio", "16:9", "--wait", "--json"],
  ])
}

let run = c => {
  let dst = clips ++ "SCENE1_" ++ c.tag ++ ".mp4"
  if existsSync(dst) {
    Js.log("skip (exists) " ++ c.tag)
  } else {
    let model = c.cheap ? "seedance_2_0_mini" : "seedance_2_0"
    Kuku_Spend.record(
      ~episode="EP10", ~shot=c.tag, ~kind="clip", ~model,
      ~credits=Kuku_Spend.priceOf(model) *. Belt.Int.toFloat(c.secs) /. 5.0,
      ~note=Belt.Int.toString(c.secs) ++ "s", (),
    )
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

/* any argv word that prefixes a real tag selects that clip — not just c-tags */
let only = Js.Array2.filter(argv, a =>
  !Js.String2.startsWith(a, "-") && Js.Array2.some(all, c => Js.String2.startsWith(c.tag, a))
)
let chosen = Js.Array2.length(only) > 0
  ? Js.Array2.filter(all, c => Js.Array2.some(only, o => Js.String2.startsWith(c.tag, o)))
  : all

if Js.Array2.some(argv, a => a == "--gate") {
  let bad = ref(0)
  Js.Array2.forEach(all, c =>
    try {ignore(P.videoPrompt(c.spec))} catch {
    | Js.Exn.Error(err) => {
        bad := bad.contents + 1
        Js.log("== " ++ c.tag ++ " ==")
        Js.log(switch Js.Exn.message(err) { | Some(m) => m | None => "?" })
      }
    }
  )
  if bad.contents > 0 {
    Js.Exn.raiseError(Belt.Int.toString(bad.contents) ++ " clip prompts forbid")
  }
  Js.log("PROMPT GATE CLEAN: " ++ Belt.Int.toString(Js.Array2.length(all)) ++ " clip prompts describe, and every line names what is on screen")
} else if Js.Array2.some(argv, a => a == "--go") {
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
