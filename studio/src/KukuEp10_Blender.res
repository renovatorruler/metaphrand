/* KukuEp10_Blender.res — emit the set bible as a Blender-buildable scene.

   The geometry a shot needs already exists as data in Kuku_Ep10Sets (landmarks
   in metres). This module writes that data as JSON; `sets/blender/build_set.py`
   reads it and constructs the real 3D set, so camera angles stop being a video
   model's guess and become arithmetic. Blender's API is Python-only — the same
   author exception the Defold runtime has — and ReScript still owns the data.

   Run from studio/: node src/KukuEp10_Blender.res.mjs [set] */

module S = Kuku_Ep10Sets
module P = Kuku_PromptSpec

@module("fs") external writeFileSync: (string, string) => unit = "writeFileSync"
@module("fs") external mkdirSync: (string, {"recursive": bool}) => unit = "mkdirSync"
@scope("process") @val external argv: array<string> = "argv"

let outDir = P.kukuRoot ++ "ep10prod/sets/blender/"
mkdirSync(outDir, {"recursive": true})

let str = Js.Json.string
let num = Js.Json.number
let obj = kvs => Js.Json.object_(Js.Dict.fromArray(kvs))

/* AN ACTOR IS PLACED, NOT DESCRIBED. A blockout that holds only landmarks tells
   the image model where the ring is and leaves every body to chance — which is
   how five dragons ended up in a different order each render. Here each cast
   member is a position, a facing and a height in metres, and the proxy is
   painted in that character's canonical colour, so the blockout carries WHO as
   well as WHERE. The model repaints the forms; it does not choose the staging. */
type actor = {
  who: string,
  cx: float, /* metres across */
  cy: float, /* metres along */
  facing: float, /* degrees; 0 looks down +y, 180 looks toward the courtyard */
  height: float, /* metres, standing */
  kind: string, /* dragon | elder | cow | cart | bird */
  lift: float, /* metres off the ground — airborne moments */
  pose: string, /* stand | crouch | fly | land */
  r: float,
  g: float,
  b: float,
}

let greatH = 7.0
let smallH = 1.5

/* colours straight from the character bible, so the proxy carries identity */

/* दृश्य ० — THE FLIGHT DRILL, AS MOMENTS. A scene is not a tableau seen from
   several angles: फ्यूरिया stands, crouches, flies the ring, brushes the bell
   and lands past her mark, and each of those is a different arrangement of
   bodies. Every shot below names its own staging, so the blockout can hold the
   moment the screenplay is actually on. */
let watchers = lift => [
  {who: "KUKU", cx: -15.0, cy: 1.0, facing: 180.0, height: greatH, kind: "dragon", lift, pose: "stand", r: 0.35, g: 0.62, b: 0.32},
  {who: "LEDA", cx: -8.0, cy: -0.5, facing: 180.0, height: greatH, kind: "dragon", lift, pose: "stand", r: 0.72, g: 0.60, b: 0.86},
  {who: "CASTOR", cx: 8.0, cy: -0.5, facing: 180.0, height: greatH, kind: "dragon", lift, pose: "stand", r: 0.92, g: 0.74, b: 0.24},
  {who: "VESPER", cx: 15.0, cy: 1.0, facing: 180.0, height: greatH, kind: "dragon", lift, pose: "stand", r: 0.68, g: 0.82, b: 0.92},
]
let rishi = {who: "RISHI", cx: -7.5, cy: -15.0, facing: 150.0, height: 2.6, kind: "elder", lift: 0.0, pose: "stand", r: 0.90, g: 0.86, b: 0.74}
let cart = {who: "CART", cx: 0.0, cy: 2.0, facing: 0.0, height: 1.6, kind: "cart", lift: 0.0, pose: "stand", r: 0.55, g: 0.40, b: 0.28}
let gauri = {who: "GAURI", cx: 0.0, cy: 2.0, facing: 0.0, height: 1.5, kind: "cow", lift: 0.0, pose: "stand", r: 0.90, g: 0.86, b: 0.74}
let cheel = {who: "CHEEL", cx: 16.0, cy: -26.0, facing: 200.0, height: 1.0, kind: "bird", lift: 0.0, pose: "stand", r: 0.28, g: 0.24, b: 0.22}
let fy = (cy, lift, pose) => {
  who: "FYURIA", cx: 0.0, cy, facing: 180.0, height: greatH, kind: "dragon", lift, pose,
  r: 0.85, g: 0.24, b: 0.35,
}

/* the standing tableau, kept for the fly-through */
let drillStaging = Js.Array2.concatMany(watchers(0.0), [[fy(-12.0, 0.0, "stand"), rishi, cart, gauri, cheel]])

let actorJson = a =>
  obj([
    ("lift", num(a.lift)),
    ("pose", str(a.pose)),
    ("who", str(a.who)),
    ("pos", Js.Json.array([num(a.cx), num(a.cy), num(0.0)])),
    ("facing_deg", num(a.facing)),
    ("height_m", num(a.height)),
    ("kind", str(a.kind)),
    ("rgb", Js.Json.array([num(a.r), num(a.g), num(a.b)])),
  ])

/* a camera is a position and an aim, both in set metres — deterministic */
type cam = {tag: string, x: float, y: float, z: float, ax: float, ay: float, az: float, lens: float}

let laneCams = [
  {tag: "top_looking_down", x: 0.0, y: -3.0, z: S.laneDrop +. 1.7, ax: 0.0, ay: 30.0, az: 1.0, lens: 35.0},
  {tag: "upper_mid", x: 0.0, y: 9.0, z: S.laneDrop *. 0.8 +. 1.7, ax: 0.0, ay: 40.0, az: 0.6, lens: 35.0},
  {tag: "lower_mid", x: 0.0, y: 27.0, z: S.laneDrop *. 0.35 +. 1.7, ax: 0.0, ay: 52.0, az: 0.3, lens: 35.0},
  {tag: "flat_approach", x: 0.0, y: 44.0, z: 1.7, ax: 0.0, ay: 58.0, az: 0.0, lens: 35.0},
  {tag: "bottom_looking_up", x: 0.0, y: 58.0, z: 1.7, ax: 0.0, ay: 6.0, az: S.laneDrop, lens: 35.0},
  {tag: "overhead", x: 0.0, y: 22.0, z: S.laneDrop +. 26.0, ax: 0.0, ay: 30.0, az: 2.0, lens: 28.0},
  {tag: "side_on", x: -16.0, y: 26.0, z: S.laneDrop *. 0.5 +. 4.0, ax: 0.0, ay: 26.0, az: 2.0, lens: 35.0},
]

/* courtyard vantages, one per shot that needs staging authority. The floor is
   at laneDrop; the ring's centre stands seven metres above it. */
let cy0 = S.laneDrop
let courtyardCams = [
  /* A GREAT-FORM DRAGON IS SEVEN METRES TALL. The first pass put these lenses
     ten metres out and the frame filled with a single flank; every distance
     here is set from the tallest thing it must contain. */
  {tag: "drill_stage", x: 0.0, y: 34.0, z: cy0 +. 17.0, ax: 0.0, ay: -15.0, az: cy0 +. 4.0, lens: 30.0},
  {tag: "ring_wide", x: 0.0, y: 14.0, z: cy0 +. 6.0, ax: 0.0, ay: -18.0, az: cy0 +. 7.0, lens: 35.0},
  {tag: "at_the_mark", x: 17.0, y: 6.0, z: cy0 +. 6.0, ax: 0.0, ay: -12.0, az: cy0 +. 3.5, lens: 40.0},
  {tag: "through_the_ring", x: 0.0, y: 6.0, z: cy0 +. 7.0, ax: 0.0, ay: -18.0, az: cy0 +. 8.0, lens: 35.0},
  {tag: "rishi_side", x: 2.0, y: -6.0, z: cy0 +. 3.0, ax: -7.5, ay: -15.0, az: cy0 +. 1.8, lens: 50.0},
  {tag: "row_of_five", x: -22.0, y: 16.0, z: cy0 +. 6.0, ax: 0.0, ay: -6.0, az: cy0 +. 3.5, lens: 40.0},
  {tag: "courtyard_overhead", x: 0.0, y: -6.0, z: cy0 +. 40.0, ax: 0.0, ay: -14.0, az: cy0, lens: 30.0},
]

/* a shot is a camera and the arrangement of bodies at that instant */
type shot = {id: string, cam: cam, cast: array<actor>}

let ringY = -18.0
let markY = -12.0

let drillShots = [
  {
    id: "h01_ring_wide",
    cam: {tag: "h01", x: 0.0, y: 34.0, z: cy0 +. 17.0, ax: 0.0, ay: -15.0, az: cy0 +. 4.0, lens: 30.0},
    cast: Js.Array2.concatMany(watchers(0.0), [[fy(markY, 0.0, "stand"), rishi, cart, gauri]]),
  },
  {
    id: "h02_rishi_teach",
    cam: {tag: "h02", x: 6.0, y: 2.0, z: cy0 +. 3.4, ax: -7.5, ay: -15.0, az: cy0 +. 1.9, lens: 55.0},
    cast: [rishi, fy(markY, 0.0, "stand")],
  },
  {
    id: "h03_furia_mark",
    cam: {tag: "h03", x: 18.0, y: 8.0, z: cy0 +. 5.0, ax: 0.0, ay: markY, az: cy0 +. 3.0, lens: 50.0},
    cast: [fy(markY, 0.0, "crouch"), rishi],
  },
  {
    id: "h04_launch",
    cam: {tag: "h04", x: 0.0, y: 12.0, z: cy0 +. 7.0, ax: 0.0, ay: ringY, az: cy0 +. 8.0, lens: 35.0},
    cast: [fy(ringY +. 1.0, 6.0, "fly")],
  },
  {
    id: "h06_landing_paw",
    cam: {tag: "h06", x: 12.0, y: 2.0, z: cy0 +. 3.0, ax: 0.0, ay: markY, az: cy0 +. 1.5, lens: 60.0},
    cast: [fy(markY +. 1.6, 0.0, "land")],
  },
  {
    id: "h45_leda_watch_ring",
    cam: {tag: "h45", x: -24.0, y: 18.0, z: cy0 +. 6.0, ax: -8.0, ay: -0.5, az: cy0 +. 4.5, lens: 55.0},
    cast: [{...watchers(0.0)[1], facing: 170.0}],
  },
  {
    id: "h53_ring_drill_wide",
    cam: {tag: "h53", x: -20.0, y: 26.0, z: cy0 +. 13.0, ax: 0.0, ay: -14.0, az: cy0 +. 4.0, lens: 28.0},
    cast: Js.Array2.concatMany(watchers(0.0), [[fy(markY, 0.0, "stand"), rishi]]),
  },
  {
    id: "h10_cheel_tower",
    cam: {tag: "h10", x: 4.0, y: -8.0, z: cy0 +. 6.0, ax: 16.0, ay: -26.0, az: cy0 +. 18.0, lens: 60.0},
    cast: [cheel],
  },
  {
    id: "h52_gauri_hay_cart",
    cam: {tag: "h52", x: -7.0, y: 12.0, z: cy0 +. 2.4, ax: 0.0, ay: 2.0, az: cy0 -. 0.2, lens: 45.0},
    cast: [cart, gauri],
  },
]

/* THE FLY: a single continuous move the author can watch before a credit is
   spent — from behind the watching row, in over the launch circle, and up to
   the ring's mouth. Blender renders it; Higgsfield never sees it. */
let flyFrom = {tag: "fly_a", x: 0.0, y: 34.0, z: cy0 +. 17.0, ax: 0.0, ay: -15.0, az: cy0 +. 4.0, lens: 30.0}
let flyTo = {tag: "fly_b", x: 0.0, y: -6.0, z: cy0 +. 6.0, ax: 0.0, ay: -18.0, az: cy0 +. 8.0, lens: 30.0}

let camJson = c =>
  obj([
    ("tag", str(c.tag)),
    ("pos", Js.Json.array([num(c.x), num(c.y), num(c.z)])),
    ("aim", Js.Json.array([num(c.ax), num(c.ay), num(c.az)])),
    ("lens_mm", num(c.lens)),
  ])

/* THE DRILL FLIGHT, as ऋषि sets it: out from the launch circle, UP AND THROUGH
   the ring's opening, a claw brushing the bell at its crown, round behind it,
   and back down to the mark. Waypoints are metres in the set's own frame, so
   the path through the fourteen-metre ring is arithmetic — the one move that
   has been guessed at in every generated version of this shot. */
let ringZ = cy0 +. 7.0 /* the ring's centre: its lowest point meets the floor */
let bellZ = cy0 +. 14.0 -. 1.9 /* just under the crown, where the bell hangs */

let drillFlight = obj([
  ("who", str("FYURIA")),
  ("rgb", Js.Json.array([num(0.85), num(0.24), num(0.35)])),
  ("height_m", num(greatH)),
  ("frames", num(288.0)),  /* the cue runs about twelve seconds */
  ("cam", camJson({tag: "watch", x: 16.0, y: 36.0, z: cy0 +. 12.0, ax: 0.0, ay: -15.0, az: cy0 +. 7.0, lens: 28.0})),
  /* ONE SLOW DRIFT, HELD WIDE. The first move swung in to twelve metres and
     cropped the ring, the mark and half the flight. The ring alone is fourteen
     metres tall, so at a 28 mm lens nothing closer than about thirty-five
     metres can hold it — every station below sits further out than that, and
     the camera only slides sideways while the drill plays out complete. */
  (
    "cam_path",
    Js.Json.array([
      obj([("pos", Js.Json.array([num(16.0), num(36.0), num(cy0 +. 12.0)])), ("aim", Js.Json.array([num(0.0), num(-15.0), num(cy0 +. 7.0)]))]),
      obj([("pos", Js.Json.array([num(8.0), num(34.0), num(cy0 +. 13.0)])), ("aim", Js.Json.array([num(0.0), num(-16.0), num(cy0 +. 8.0)]))]),
      obj([("pos", Js.Json.array([num(-4.0), num(33.0), num(cy0 +. 13.0)])), ("aim", Js.Json.array([num(0.0), num(-16.0), num(cy0 +. 8.0)]))]),
      obj([("pos", Js.Json.array([num(-14.0), num(34.0), num(cy0 +. 11.0)])), ("aim", Js.Json.array([num(0.0), num(-14.0), num(cy0 +. 6.0)]))]),
      obj([("pos", Js.Json.array([num(-10.0), num(32.0), num(cy0 +. 10.0)])), ("aim", Js.Json.array([num(0.0), num(-12.0), num(cy0 +. 4.0)]))]),
    ]),
  ),
  (
    "waypoints",
    Js.Json.array(
      Js.Array2.concatMany(
        /* off the mark and up to the ring's mouth */
        [
          Js.Json.array([num(0.0), num(-12.0), num(cy0)]),
          Js.Json.array([num(0.0), num(-13.0), num(cy0 +. 4.5)]),
          Js.Json.array([num(0.0), num(-15.5), num(ringZ +. 1.0)]),
        ],
        [
          /* THREE CIRCUITS, «वह उलटे घेरे के भीतर घूमती है». Each one threads the
             opening and loops around the ring's top rim — through the hole,
             up over the stone, down in front, and through again. Sampled every
             sixty degrees so the arc stays round. */
          Belt.Array.makeBy(18, i => {
            let th = Js.Math._PI *. 2.0 *. Belt.Int.toFloat(i) /. 6.0
            let rimZ = cy0 +. 14.0 /* the crown */
            let r = 5.0
            Js.Json.array([
              num(Belt.Int.toFloat(i) *. 0.12),
              num(-18.0 +. r *. Js.Math.sin(th)),
              num(rimZ -. r *. Js.Math.cos(th)),
            ])
          }),
          /* the bell, struck in passing on the way out of the last circuit */
          [
            Js.Json.array([num(0.0), num(-18.0), num(bellZ -. 0.8)]),
            Js.Json.array([num(2.0), num(-21.0), num(ringZ +. 2.0)]),
            /* the wide arc home */
            Js.Json.array([num(11.0), num(-22.0), num(ringZ)]),
            Js.Json.array([num(14.0), num(-15.0), num(cy0 +. 7.0)]),
            Js.Json.array([num(7.0), num(-11.0), num(cy0 +. 4.0)]),
            /* braking onto the mark, and the claw that scuffs past it */
            Js.Json.array([num(1.5), num(-12.2), num(cy0 +. 1.2)]),
            Js.Json.array([num(0.0), num(-11.4), num(cy0)]),
          ],
        ],
      ),
    ),
  ),
])

/* ---- ACTIONS: the lane's moving shots, as geometry ------------------------
   A clip on the lane is a set of bodies travelling measured distances at
   measured heights. Every failure the conformance fleets found in these shots
   was spatial — two dragons gripping one wheel, वैस्पर perched on a wall
   instead of flying highest, the cart teleporting up the slope — so the fix is
   to state the arrangement in metres and let Blender carry it, exactly as the
   drill flight now does for the courtyard. dz is height ABOVE the lane surface,
   so the slope is applied for us. */
/* CAMERA DISTANCE IS ARITHMETIC, NOT TASTE. A great-form dragon is seven
   metres and a formation spans twenty; the first pass put these lenses twelve
   metres out and every frame filled with one wheel. Each station below is set
   from the tallest body it must hold. */
/* EVERY CAMERA Z BELOW IS METRES ABOVE THE ROAD, station and aim alike — the
   lane falls nine metres, so absolute heights buried the low cameras in earth
   and pointed the aims at empty sky. */
type key = {kt: float, kx: float, ky: float, kdz: float, kf: float}
type mover = {mwho: string, mkind: string, mh: float, mr: float, mg: float, mb: float, keys: array<key>}
/* HOW THE MOTION IS PACED. Smoothstep between every key made each keyframe a
   dead stop — a runaway cart eased to rest at the first marker, which is the
   opposite of the beat. "accel" gathers speed, "linear" holds it, "settle"
   comes to a real stop where the story asks for one. */
type action = {aid: string, frames: int, lens: float, ease: string, campath: array<(float, float, float, float, float, float)>, movers: array<mover>}

let k = (kt, kx, ky, kdz, kf) => {kt, kx, ky, kdz, kf}
let dragonMover = (who, r, g, b, keys) => {mwho: who, mkind: "dragon", mh: greatH, mr: r, mg: g, mb: b, keys}
let cartMover = keys => {mwho: "CART", mkind: "cart", mh: 1.6, mr: 0.55, mg: 0.40, mb: 0.28, keys}
let cowMover = keys => {mwho: "GAURI", mkind: "cow", mh: 1.5, mr: 0.90, mg: 0.86, mb: 0.74, keys}

let cKuku = (0.35, 0.62, 0.32)
let cFy = (0.85, 0.24, 0.35)
let cLeda = (0.72, 0.60, 0.86)
let cCas = (0.92, 0.74, 0.24)
let cVes = (0.68, 0.82, 0.92)

/* the cart rides in the bed, so cow and cart share a path */
let ride = (y0, y1) => [k(0.0, 0.0, y0, 0.9, 0.0), k(1.0, 0.0, y1, 0.9, 0.0)]

let laneActions = [
  {
    /* «गाड़ी तीन लाल निशानों की ओर दौड़ रही है» — twelve metres, accelerating */
    aid: "c1_breaks_away",
    frames: 240,
    lens: 35.0,
    ease: "accel",
    /* A TRACKING CAMERA RIDES BESIDE ITS SUBJECT AND AIMS AT IT. Leading the
       cart by seven metres and aiming two further ahead put it tiny on the
       crest with the frame full of empty road. Station and aim now travel the
       cart's own y, offset only across the lane. */
    campath: [(-11.0, 1.0, 2.0, 0.0, 1.0, 0.9), (-11.0, 13.0, 2.0, 0.0, 13.0, 0.9)],
    movers: [
      cartMover([k(0.0, 0.0, 1.0, 0.0, 0.0), k(0.35, 0.0, 4.0, 0.0, 0.0), k(1.0, 0.0, 13.0, 0.0, 0.0)]),
      cowMover([k(0.0, 0.0, 1.0, 1.1, 0.0), k(0.35, 0.0, 4.0, 1.1, 0.0), k(1.0, 0.0, 13.0, 1.1, 0.0)]),
    ],
  },
  {
    /* the five take formation: फ्यूरिया lowest and furthest forward, वैस्पर highest */
    aid: "c2_five_flank",
    frames: 120,
    lens: 32.0,
    ease: "linear",
    campath: [(-21.0, 8.0, 12.0, 0.0, 17.0, 4.0), (-17.0, 16.0, 11.0, 0.0, 25.0, 3.5)],
    movers: [
      cartMover(ride(13.0, 21.0)),
      cowMover([k(0.0, 0.0, 13.0, 1.1, 0.0), k(1.0, 0.0, 21.0, 1.1, 0.0)]),
      dragonMover("FYURIA", 0.85, 0.24, 0.35, [k(0.0, 0.0, 17.0, 1.6, 0.0), k(1.0, 0.0, 25.5, 1.4, 0.0)]),
      dragonMover("KUKU", 0.35, 0.62, 0.32, [k(0.0, -6.0, 13.0, 2.2, 0.0), k(1.0, -6.0, 21.0, 2.2, 0.0)]),
      dragonMover("LEDA", 0.72, 0.60, 0.86, [k(0.0, 6.0, 13.0, 2.6, 0.0), k(1.0, 6.0, 21.0, 2.6, 0.0)]),
      dragonMover("CASTOR", 0.92, 0.74, 0.24, [k(0.0, 3.0, 11.5, 1.8, 0.0), k(1.0, 3.0, 19.5, 1.8, 0.0)]),
      dragonMover("VESPER", 0.68, 0.82, 0.92, [k(0.0, 0.0, 14.0, 9.0, 0.0), k(1.0, 0.0, 22.0, 9.0, 0.0)]),
    ],
  },
  {
    /* ONE DRAGON PER WHEEL and वैस्पर on the centre rail above: the arrangement
       the fleets kept finding wrong. All four wheels rise a hand's height
       together, the weight wins, and they settle back down. */
    aid: "c3_failed_lift",
    frames: 120,
    lens: 34.0,
    ease: "linear",
    campath: [(-13.0, 36.0, 3.0, 0.0, 24.5, 3.5), (-10.0, 38.0, 3.4, 0.0, 27.5, 3.2)],
    movers: [
      cartMover([k(0.0, 0.0, 22.0, 0.0, 0.0), k(0.45, 0.0, 24.0, 0.55, 0.0), k(0.75, 0.0, 25.0, 0.5, 0.0), k(1.0, 0.0, 26.0, 0.0, 0.0)]),
      cowMover([k(0.0, 0.0, 22.0, 1.1, 0.0), k(0.45, 0.0, 24.0, 1.65, 0.0), k(1.0, 0.0, 26.0, 1.1, 0.0)]),
      dragonMover("KUKU", 0.35, 0.62, 0.32, [k(0.0, -2.0, 21.0, 1.4, 0.0), k(1.0, -2.0, 25.0, 1.2, 0.0)]),
      dragonMover("FYURIA", 0.85, 0.24, 0.35, [k(0.0, 2.0, 21.0, 1.4, 0.0), k(1.0, 2.0, 25.0, 1.2, 0.0)]),
      dragonMover("CASTOR", 0.92, 0.74, 0.24, [k(0.0, -2.0, 23.6, 1.4, 0.0), k(1.0, -2.0, 27.6, 1.2, 0.0)]),
      dragonMover("LEDA", 0.72, 0.60, 0.86, [k(0.0, 2.0, 23.6, 1.4, 0.0), k(1.0, 2.0, 27.6, 1.2, 0.0)]),
      dragonMover("VESPER", 0.68, 0.82, 0.92, [k(0.0, 0.0, 22.4, 8.0, 0.0), k(1.0, 0.0, 26.4, 8.0, 0.0)]),
    ],
  },
  {
    /* «फ्यूरिया पीछे की ओर उड़ते हुए» — flying backwards ahead of the cart,
       forepaws on its front wall, both still travelling DOWN the lane */
    aid: "s2a_furia_brakes",
    frames: 120,
    lens: 35.0,
    ease: "linear",
    campath: [(-3.0, 48.0, 3.2, 0.0, 32.0, 2.2), (-3.0, 53.0, 3.0, 0.0, 37.0, 2.0)],
    movers: [
      cartMover(ride(27.0, 33.0)),
      cowMover([k(0.0, 0.0, 27.0, 1.1, 0.0), k(1.0, 0.0, 33.0, 1.1, 0.0)]),
      dragonMover("FYURIA", 0.85, 0.24, 0.35, [k(0.0, 0.0, 30.0, 2.6, 180.0), k(1.0, 0.0, 35.6, 2.4, 180.0)]),
    ],
  },
  {
    /* the flat: the cart's last metres, slowing to a full stop */
    aid: "b4_curve_stop",
    frames: 120,
    lens: 38.0,
    ease: "settle",
    campath: [(-14.0, 49.0, 2.6, 0.0, 54.0, 1.2), (-12.0, 52.0, 2.2, 0.0, 56.0, 1.0)],
    movers: [
      cartMover([k(0.0, 0.0, 51.0, 0.0, 0.0), k(0.6, 0.0, 54.2, 0.0, 0.0), k(0.85, 0.0, 55.2, 0.0, 0.0), k(1.0, 0.0, 55.4, 0.0, 0.0)]),
      cowMover([k(0.0, 0.0, 51.0, 1.1, 0.0), k(0.6, 0.0, 54.2, 1.1, 0.0), k(1.0, 0.0, 55.4, 1.1, 0.0)]),
      dragonMover("FYURIA", 0.85, 0.24, 0.35, [k(0.0, 0.0, 53.0, 2.4, 180.0), k(0.6, 0.0, 56.2, 2.2, 180.0), k(1.0, 0.0, 57.2, 1.8, 180.0)]),
    ],
  },
]

/* c4: «चारों पहिए पटरी पर लौटते हैं। गाड़ी डगमगाती है और फिर सीधी होती है।»
   The wheels come down and the cart RUNS ON — the shot whose ground measured
   zero pixels of travel, i.e. the cart was parked while everyone acted. Here
   it covers seven metres and the camera sits low behind it, so the road has to
   stream away underneath. */
let c4Action = {
  aid: "c4_wheels_return",
  frames: 120,
  lens: 30.0,
  ease: "accel",
  campath: [(-1.5, 21.0, 1.8, 0.0, 30.0, 1.2), (-1.5, 26.0, 1.7, 0.0, 35.0, 1.1)],
  movers: [
    cartMover([k(0.0, 0.0, 26.0, 0.35, 0.0), k(0.18, 0.0, 27.4, 0.0, 0.0), k(0.35, 0.0, 28.6, 0.12, 0.0), k(1.0, 0.0, 33.0, 0.0, 0.0)]),
    cowMover([k(0.0, 0.0, 26.0, 1.45, 0.0), k(0.18, 0.0, 27.4, 1.1, 0.0), k(1.0, 0.0, 33.0, 1.1, 0.0)]),
  ],
}

/* DIALOGUE HOLDS. A speaking shot is a character held in frame while the world
   keeps moving behind them — the cart is still running through every one of
   these, because the clock never stops until the ग catches it. The camera
   makes a slow deliberate move so Mini has motion to follow without inventing
   any, and the generated audio is thrown away for the dubbed take. */
let hold = (id, who, r, g, b, keys, campath, lens) => {
  aid: id,
  frames: 120,
  lens,
  ease: "linear",
  campath,
  movers: [dragonMover(who, r, g, b, keys)],
}

/* AIM AT MID-BODY, NOT AT THE FEET. A great-form dragon spans seven metres
   upward from wherever she flies; aiming at her base height centres the frame
   on her belly and crops the head. Each aim below sits at the mover's own
   height plus half her body, and each station is set back far enough that the
   whole animal fits: roughly 21 metres on a 50 mm. */
let dialogueActions = [
  /* लेडा flying low alongside the lane, head turned down, calling instructions.
     Slow push in from a three-quarter front. */
  hold("d_leda_calls", "LEDA", 0.72, 0.60, 0.86,
    [k(0.0, 6.0, 16.0, 3.0, 20.0), k(1.0, 6.0, 23.0, 2.8, 20.0)],
    [(-12.0, 31.0, 7.2, 6.0, 18.5, 6.5), (-10.0, 29.0, 6.8, 6.0, 24.5, 6.3)], 50.0),
  /* वैस्पर highest, calling down — camera LOW looking up, so his height reads */
  hold("d_vesper_above", "VESPER", 0.68, 0.82, 0.92,
    [k(0.0, 0.0, 22.0, 13.0, 0.0), k(1.0, 0.0, 29.0, 12.4, 0.0)],
    [(-8.0, 38.0, 2.0, 0.0, 24.0, 16.5), (-7.0, 43.0, 2.0, 0.0, 30.5, 16.0)], 45.0),
  /* कैस्टर alongside the cart, talking to गौरी — a gentle drift, wide enough
     that his whole length stays inside the kerbs */
  hold("d_castor_calm", "CASTOR", 0.92, 0.74, 0.24,
    [k(0.0, -4.0, 30.0, 2.4, 0.0), k(1.0, -4.0, 36.0, 2.2, 0.0)],
    [(14.0, 44.0, 6.4, -4.0, 32.0, 5.9), (13.0, 48.0, 6.2, -4.0, 38.0, 5.7)], 50.0),
  /* फ्यूरिया refusing to chase the bell: she looks up and away, then back down
     to the cart. A slow arc round her holds the choice on her face. */
  hold("d_furia_refuses", "FYURIA", 0.85, 0.24, 0.35,
    [k(0.0, 0.0, 38.0, 2.6, 175.0), k(1.0, 0.0, 43.0, 2.4, 185.0)],
    [(-13.0, 56.0, 6.8, 0.0, 39.5, 6.1), (8.0, 58.0, 6.6, 0.0, 44.0, 5.9)], 50.0),
  /* कुकु's breath failing — held close, the camera easing back as it scatters */
  hold("d_kuku_breath", "KUKU", 0.35, 0.62, 0.32,
    [k(0.0, -3.0, 47.0, 2.0, 10.0), k(1.0, -3.0, 49.0, 1.9, 10.0)],
    [(12.0, 58.0, 6.0, -3.0, 48.0, 5.5), (15.0, 61.0, 6.4, -3.0, 49.0, 5.3)], 45.0),
]

/* लेडा's cutaway, «अभी नहीं... अभी नहीं... अब धीरे!». The drill is her call to
   make — ऋषि says «लेडा बताएगी कब धीमा होना है» — so the cut goes to her while
   फ्यूरिया is still in the air, and comes back for the braking swing. She holds
   her ground and her head tracks the flight; only the camera closes in. */
let courtyardActions = [
  {
    aid: "d_leda_counts",
    frames: 96,
    lens: 50.0,
    ease: "linear",
    campath: [
      (-21.0, -15.0, 4.4, -8.0, -0.5, 3.6),
      (-18.0, -12.0, 4.0, -8.0, -0.5, 3.5),
    ],
    movers: [
      dragonMover("LEDA", 0.72, 0.60, 0.86, [
        k(0.0, -8.0, -0.5, 0.0, 200.0),
        k(0.55, -8.0, -0.5, 0.0, 186.0),
        k(1.0, -8.0, -0.5, 0.0, 176.0),
      ]),
    ],
  },
]

let keyJson = key =>
  Js.Json.array([num(key.kt), num(key.kx), num(key.ky), num(key.kdz), num(key.kf)])

let moverJson = m =>
  obj([
    ("who", str(m.mwho)),
    ("kind", str(m.mkind)),
    ("height_m", num(m.mh)),
    ("rgb", Js.Json.array([num(m.mr), num(m.mg), num(m.mb)])),
    ("keys", Js.Json.array(Js.Array2.map(m.keys, keyJson))),
  ])

let actionJson = a =>
  obj([
    ("id", str(a.aid)),
    ("frames", num(Belt.Int.toFloat(a.frames))),
    ("ease", str(a.ease)),
    ("lens_mm", num(a.lens)),
    (
      "cam_path",
      Js.Json.array(
        Js.Array2.map(a.campath, ((px, py, pz, ax, ay, az)) =>
          obj([
            ("pos", Js.Json.array([num(px), num(py), num(pz)])),
            ("aim", Js.Json.array([num(ax), num(ay), num(az)])),
          ])
        ),
      ),
    ),
    ("movers", Js.Json.array(Js.Array2.map(a.movers, moverJson))),
  ])

let landmarkJson = (l: S.landmark) =>
  obj([
    ("name", str(l.name)),
    ("pos", Js.Json.array([num(l.x), num(l.y), num(l.z)])),
    ("note", str(l.note)),
  ])

let sceneJson = s =>
  obj([
    ("set", str(S.setName(s))),
    ("lane_length_m", num(S.laneLength)),
    ("lane_width_m", num(S.laneWidth)),
    ("lane_drop_m", num(S.laneDrop)),
    ("landmarks", Js.Json.array(Js.Array2.map(S.landmarksOf(s), landmarkJson))),
    ("actors", Js.Json.array(s == S.Courtyard ? Js.Array2.map(drillStaging, actorJson) : [])),
    ("shots", s == S.Courtyard
      ? Js.Json.array(Js.Array2.map(drillShots, sh =>
          obj([
            ("id", str(sh.id)),
            ("cam", camJson(sh.cam)),
            ("actors", Js.Json.array(Js.Array2.map(sh.cast, actorJson))),
          ])
        ))
      : Js.Json.array([])),
    ("actions", s == S.Lane
      ? Js.Json.array(Js.Array2.map(Js.Array2.concatMany(laneActions, [[c4Action], dialogueActions]), actionJson))
      : s == S.Courtyard ? Js.Json.array(Js.Array2.map(courtyardActions, actionJson)) : Js.Json.array([])),
    ("flight", s == S.Courtyard ? drillFlight : Js.Json.null),
    ("fly", s == S.Courtyard ? Js.Json.array([camJson(flyFrom), camJson(flyTo)]) : Js.Json.array([])),
    ("cameras", Js.Json.array(Js.Array2.map(s == S.Courtyard ? courtyardCams : laneCams, camJson))),
    ("prose", str(S.setProse(s))),
  ])

let target = Js.Array2.length(argv) > 2 ? argv[2] : "lane"
let set = switch target {
| "courtyard" => S.Courtyard
| "flat_stone" => S.FlatStone
| "tower" => S.Tower
| "doorway" => S.Doorway
| "grass_verge" => S.GrassVerge
| _ => S.Lane
}

let file = outDir ++ S.setName(set) ++ "_scene.json"
writeFileSync(file, Js.Json.stringifyWithSpace(sceneJson(set), 2))
Js.log("wrote " ++ file ++ " (" ++ Belt.Int.toString(Js.Array2.length(laneCams)) ++ " cameras)")
