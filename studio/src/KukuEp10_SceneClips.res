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
      scene: "चील takes the bell: perched on the crown of the great stone flight ring, she works the bronze binding open, the bell drops free into her talons, and she lifts away with it.",
      cameraTravels: false,
      cast: [
        P.Cheel({doing: "perched on the ring's crown above the hanging bell, working its binding loose, then lifting away with the bell in her talons"}),
        P.Prop({what: "THE BELL", doing: "bronze, hanging from its short bronze hook inside the crown of the flight ring, warm and gleaming"}),
      ],
      blocking: [
        "the start image IS this ring and this bell — the same stone, the same hook, the same sky and light",
        "the great stone ring holds perfectly still throughout, exactly as the start image has it",
        "she is the only creature in frame",
      ],
      beats: [
        "0.0-1.5s: she leans down and works the bronze binding at the ring's crown with her beak and talons, the bell swinging a little as it loosens",
        "1.5-2.5s: the binding gives and the bell drops free, caught in her talons, swinging under her once",
        "2.5-5.0s: her great wings open and beat down, and she lifts away from the ring with the bell held beneath her, rising out of the top of frame",
      ],
      camera: "one locked-off MEDIUM camera on the ring's crown, held perfectly still for the whole clip, with sky above so she has room to rise into it",
      physics: [
        "the bell hangs and swings from a single point like a real bell on a cord, and once caught it hangs from her talons the same way",
        "her wings move like stiff cut paper, and the downbeat is what lifts her — she rises only when they beat",
        "the ring, its stones and the hook keep their shapes; only the bell and the eagle move",
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
        "SHE IS AIRBORNE FROM LAUNCH TO LANDING: her wings carry her the whole way, and the only contacts in the whole clip are her claw on the bell (one instant, in passing) and her feet on the marked circle at the first and last moments",
        "ONE TOUCH ONLY: the claw meets the bell exactly once, mid-flight, on her way through",
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
  /* ---- story-beat motion clips: the six that carry the episode's turns.
     Lane/flat geography comes from each start frame; the forging and the stop
     are locked at BOTH ends so the destination image — not the model — owns
     the final composition. The ग in b2's end frame is the locally composited
     glyph, so the letter is animated toward, never invented. ---- */
  {
    talking: false,
    cheap: false,
    tag: "b1_breath_fail",
    start: stills ++ "h24_kuku_breath_fail.png",
    endFrame: "",
    secs: 5,
    spec: {
      scene: "कुकु tries to forge and his breath fails: a thin stream of golden paper light leaves his mouth, wavers, scatters into shapeless drifting wisps and fades to a few falling paper flecks. The stone below stays bare.",
      cameraTravels: false,
      cast: [d(P.Kuku, "hovering in place, exhaling a thin golden breath that scatters and dies")],
      blocking: [
        "the start image IS this place — the same stone, kerbs and light",
        "कुकु holds his position in the air through the whole clip, wings beating steadily",
      ],
      beats: [
        "0.0-1.5s: he draws a breath and exhales a thin stream of golden paper light",
        "1.5-3.5s: the stream wavers, breaks into curling wisps and scatters in the air",
        "3.5-5.0s: the last flecks drift down and fade; his eyes go wide — startled, deflated",
      ],
      camera: "one locked static camera, holding one framing from first frame to last",
      physics: [
        "the golden light behaves like cut paper — flat curls and flecks, drifting with weight",
        "the stone below stays bare from first frame to last",
      ],
      lighting: "constant light exactly as the start image, holding steady for the whole clip",
      audio: "",
      extraRules: [],
    },
  },
  {
    talking: false,
    cheap: false,
    tag: "b2_forging",
    start: stills ++ "h28_forging.png",
    endFrame: stills ++ "h29_ga_stands.png",
    secs: 5,
    spec: {
      scene: "The forging: कुकु exhales a broad steady stream of golden paper light onto the flat stone, and the golden shape builds itself whole out of the light — finishing exactly as the end image shows, seated on the stone with a heavy settling weight.",
      cameraTravels: false,
      cast: [d(P.Kuku, "exhaling a broad golden stream onto the flat stone, steady and sure")],
      blocking: [
        "the start image IS this place and the END image is this same place a breath later — the shape grows from the first into the second",
        "the golden shape that forms is EXACTLY the shape in the end image — the same form, proportion and position, built up from flowing golden light",
        "कुकु keeps his position; only his breath and the growing shape move",
      ],
      beats: [
        "0.0-1.5s: the golden stream pours onto the stone and pools into flowing light",
        "1.5-4.0s: the light rises and takes form, edges firming from liquid gold to solid golden paper",
        "4.0-5.0s: the finished shape settles onto the stone with visible weight — one heavy seat — and the light stills",
      ],
      camera: "one locked static camera, holding the exact framing shared by the start and end images",
      physics: [
        "the shape seats DOWN into place at the end — a heavy, final settling, dust puffing at its base",
        "the stream flows in one direction, mouth to stone, for the whole clip",
      ],
      lighting: "constant deepening dusk exactly as the start image, the golden light of the forging the only new light",
      audio: "",
      extraRules: [],
    },
  },
  {
    talking: false,
    cheap: false,
    tag: "b3_three_beats",
    start: stills ++ "h36_three_beats.png",
    endFrame: "",
    secs: 5,
    spec: {
      scene: "फ्यूरिया holds ahead of the slowing cart and beats her wings against its motion — three deep deliberate beats, each one slowing the cart further, paper dust rolling beneath each stroke.",
      cameraTravels: true,
      cast: [d(P.Fyuria, "flying backwards ahead of the cart, forepaws braced on its front wall, wings in deep deliberate beats"), cow("braced in the cart, steadying as it slows")],
      blocking: [
        "the start image IS this lane — the same flagstones, kerbs and light",
        "फ्यूरिया stays ahead of the cart with her forepaws on its front wall the whole clip",
        "the cart continues DOWN the lane, slowing the whole time",
      ],
      beats: [
        "0.0-1.6s: FIRST deep wingbeat — dust rolls out from under her wings, the cart slows a little",
        "1.6-3.2s: SECOND deep beat, stronger — hay shifts forward in the cart bed",
        "3.2-5.0s: THIRD beat — the cart is visibly slower by the last frame, wheels turning gently",
      ],
      camera: "one single continuous tracking shot alongside, matching the cart's slowing speed, facing along the lane the whole clip",
      physics: Js.Array2.concat(commonPhysics, [
        "each wingbeat visibly costs her effort and visibly slows the cart — action and result linked",
      ]),
      lighting: "constant deepening golden dusk exactly as the start image, the light holding steady for the whole clip",
      audio: "",
      extraRules: commonRules,
    },
  },
  {
    talking: false,
    cheap: false,
    tag: "b4_curve_stop",
    start: stills ++ "h37_cart_into_curve.png",
    endFrame: stills ++ "h38_stopped.png",
    secs: 5,
    spec: {
      scene: "The cart rolls its last stretch and comes to rest — exactly as the end image shows — wheels turning slower and slower until they stand still, गौरी steady in the bed, फ्यूरिया easing her hold as it stops.",
      cameraTravels: false,
      cast: [d(P.Fyuria, "ahead of the cart, forepaws on its front wall, easing it to rest"), cow("standing braced in the cart bed as it slows to a stop")],
      blocking: [
        "the start image IS this place and the END image is this same place moments later — the clip travels from one to the other",
        "the cart moves only forward, slower every second, and is perfectly still by the last frame",
      ],
      beats: [
        "0.0-2.0s: the cart rolls in, wheels turning slowly, फ्यूरिया braced against its front",
        "2.0-4.0s: slower still — hay settles, गौरी's footing steadies",
        "4.0-5.0s: the wheels stand still; dust settles; everything at rest exactly as the end image",
      ],
      camera: "one locked static camera, holding the exact framing shared by the start and end images",
      physics: [
        "wheels turn at a speed matching the ground passing beneath them, down to a full stop",
        "the stop is gentle and final — the cart stays at rest once stopped",
      ],
      lighting: "constant dusk exactly as the start image, the light holding steady for the whole clip",
      audio: "",
      extraRules: ["गौरी stays in the cart bed the whole clip, upright and calm by the end"],
    },
  },
  {
    talking: false,
    cheap: false,
    tag: "b5_shrink",
    start: stills ++ "h39_shrink_glow.png",
    endFrame: stills ++ "h54_small_five_stand.png",
    secs: 5,
    spec: {
      scene: "Five columns of soft golden paper light stand where the five dragons were; the light settles and sinks, and inside each column a small everyday dragon child appears — finishing exactly as the end image shows, five small dragons standing together on the flagstones.",
      cameraTravels: false,
      cast: [],
      blocking: [
        "the start image IS this place and the END image is this same place after the light settles — the clip travels from one to the other",
        "each column of light shrinks DOWN in place, and the small dragon in the end image appears exactly where that column stood",
      ],
      beats: [
        "0.0-2.0s: the five golden columns glow and slowly sink, paper-light motes drifting",
        "2.0-4.0s: within each column a small silhouette resolves as the light thins",
        "4.0-5.0s: the last light dissolves into drifting golden flecks — five small dragons stand exactly as the end image",
      ],
      camera: "one locked static camera, holding the exact framing shared by the start and end images",
      physics: [
        "the light behaves like cut paper — flat golden motes and curls, sinking with weight",
      ],
      lighting: "constant dusk exactly as the start image, the golden columns the only extra light, fading as they settle",
      audio: "",
      extraRules: [],
    },
  },
  {
    talking: false,
    cheap: false,
    tag: "b6_tower_door",
    start: stills ++ "h44_tower_door.png",
    endFrame: "",
    secs: 5,
    spec: {
      scene: "चील stands before the tall closed stone door with the stolen bronze bell. She lifts the bell in one talon, studies the door — and raises her other claw to ring it. The clip ends on that raised claw, the ring itself left for the next episode.",
      cameraTravels: false,
      cast: [P.Cheel({doing: "before the closed door, lifting the bell, raising a claw to strike it"})],
      blocking: [
        "the start image IS this place — the same door, stone and light",
        "the door stays CLOSED from first frame to last",
        "the bell stays in her talon the whole clip",
      ],
      beats: [
        "0.0-2.0s: she lifts the bronze bell level with her eyes and tilts her head at the door",
        "2.0-4.0s: she looks from the bell to the door, slow and deliberate",
        "4.0-5.0s: she raises her free claw beside the bell, poised to strike — and holds there on the last frame",
      ],
      camera: "one locked static camera, holding one framing from first frame to last",
      physics: [
        "the bell swings slightly from her movements, hanging from its one point in her talon",
      ],
      lighting: "constant cool fading dusk exactly as the start image, blue-grey on the stone, holding steady",
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
    let price = Kuku_Spend.priceOf(model) *. Belt.Int.toFloat(c.secs) /. 5.0
    Kuku_Spend.guard(~episode="EP10", ~shot=c.tag, ~credits=price)
    let raw = execFileSync("higgsfield", argsFor(c), opts)
    switch Js.String2.match_(raw, Js.Re.fromString("https://[^\"\\s]*\\.(mp4|webm|mov)")) {
    | Some(m) =>
      switch m[0] {
      | Some(url) => {
          let _ = execFileSync("curl", ["-sL", "--retry", "3", "--create-dirs", "-o", dst, url], opts)
          Kuku_Spend.record(
            ~episode="EP10", ~shot=c.tag, ~kind="clip", ~model,
            ~credits=price, ~note=Belt.Int.toString(c.secs) ++ "s", (),
          )
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
