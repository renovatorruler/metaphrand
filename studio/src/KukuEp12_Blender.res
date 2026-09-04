// KukuEp12_Blender.res — the «द से दीया» courtyard, emitted as scene JSON for Blender.
//
// EP12 is ONE place for all thirty shots, so the set is built once here and every
// camera station is derived from the same numbers. Two shots cannot disagree about
// where the wall, the niche or the lamp is, because neither shot carries geometry —
// they carry a camera, and the geometry is this file.
//
// CONVENTIONS carried over from the EP10 rig, each of which cost a bad render to learn:
//   · The courtyard floor is z = 0. EVERY camera z below is METRES ABOVE THE FLOOR,
//     for the position AND the aim. An absolute z buries the camera in the stone.
//   · Aim at a subject's UPPER body, never its feet, or the render crops heads.
//   · Nothing here travels. There is no path, no waypoint list, no distance.
//
//   node src/KukuEp12_Blender.res.mjs        # writes ep12prod scene json

@module("fs") external writeFileSync: (string, string) => unit = "writeFileSync"
@module("fs") external mkdirSync: (string, {"recursive": bool}) => unit = "mkdirSync"
@module("process") external cwd: unit => string = "cwd"

let outDir = cwd() ++ "/../stories/kuku/ep12/sets/blender/"

let str = Js.Json.string
let num = Js.Json.number
let obj = kvs => Js.Json.object_(Js.Dict.fromArray(kvs))

// ---- the courtyard, in metres -------------------------------------------------
// A square of paper flagstone. The valley is beyond the low wall at +y, and that
// is where the wind comes from; दादी's door is behind the camera side at -y.
let floorSize = 5.5
let wallY = 2.4 // the low valley wall
let wallH = 1.38
let nicheH = 0.68 // the niche floor — where the दीया stands
let doorY = -2.6
let diyaX = 0.0
let diyaY = wallY -. 0.12
let diyaZ = nicheH

// The children are in SMALL form — low enough to sit at a lamp, which is also what
// makes them small against the wind. That is the story, so it is in the geometry.
let smallH = 0.62
let dadiH = 1.62

type actor = {
  who: string,
  cx: float,
  cy: float,
  facing: float,
  height: float,
  kind: string,
  pose: string,
  r: float,
  g: float,
  b: float,
}

// Colours from CHARACTER_BIBLE — फ्यूरिया bright pink-red, वैस्पर pale blue.
let kuku = {who: "KUKU", cx: -0.05, cy: 1.25, facing: 0.0, height: smallH, kind: "child", pose: "sit", r: 0.42, g: 0.62, b: 0.36}
let furia = {who: "FYURIA", cx: -0.62, cy: 1.42, facing: 14.0, height: smallH, kind: "child", pose: "sit", r: 0.90, g: 0.28, b: 0.32}
let leda = {who: "LEDA", cx: 0.55, cy: 1.42, facing: -14.0, height: smallH, kind: "child", pose: "sit", r: 0.72, g: 0.62, b: 0.86}
let castor = {who: "CASTOR", cx: -1.05, cy: 1.72, facing: 26.0, height: smallH *. 0.85, kind: "child", pose: "sit", r: 0.94, g: 0.80, b: 0.32}
let vesper = {who: "VESPER", cx: 0.98, cy: 1.72, facing: -26.0, height: smallH, kind: "child", pose: "sit", r: 0.74, g: 0.86, b: 0.94}
let kalu = {who: "KALU", cx: 1.45, cy: 0.85, facing: 200.0, height: 0.30, kind: "dog", pose: "curled", r: 0.24, g: 0.22, b: 0.21}
let dadiAtDoor = {who: "DADI", cx: 0.0, cy: doorY +. 0.45, facing: 0.0, height: dadiH, kind: "elder", pose: "stand", r: 0.88, g: 0.84, b: 0.78}
let dadiAtNiche = {who: "DADI", cx: 0.42, cy: 1.95, facing: 10.0, height: dadiH, kind: "elder", pose: "kneel", r: 0.88, g: 0.84, b: 0.78}

let five = [kuku, furia, leda, castor, vesper]
let withDadiDoor = Js.Array2.concat(five, [kalu, dadiAtDoor])
let withDadiNiche = Js.Array2.concat(five, [kalu, dadiAtNiche])
let childrenOnly = Js.Array2.concat(five, [kalu])

let actorJson = a =>
  obj([
    ("who", str(a.who)),
    ("kind", str(a.kind)),
    ("pose", str(a.pose)),
    ("pos", Js.Json.array([num(a.cx), num(a.cy), num(0.0)])),
    ("facing", num(a.facing)),
    ("height", num(a.height)),
    ("rgb", Js.Json.array([num(a.r), num(a.g), num(a.b)])),
  ])

// ---- camera stations ----------------------------------------------------------
// Ten stations serve thirty shots. Reusing stations is deliberate: a viewer reads
// one place more strongly when the angles recur, and every reuse is one less
// chance for the set to be re-imagined.
type cam = {tag: string, px: float, py: float, pz: float, ax: float, ay: float, az: float, lens: float}

let cams = [
  // the whole courtyard from the door side — wall, niche and lamp beyond the five
  {tag: "wide", px: 0.0, py: -1.6, pz: 1.25, ax: 0.0, ay: 2.1, az: 0.62, lens: 30.0},
  // the lamp in its niche
  {tag: "niche", px: 0.0, py: 0.95, pz: 0.80, ax: 0.0, ay: wallY -. 0.05, az: nicheH +. 0.04, lens: 45.0},
  // the flame alone — an INSERT; it holds no character
  {tag: "flame", px: 0.18, py: 1.75, pz: 0.76, ax: 0.0, ay: wallY -. 0.1, az: nicheH +. 0.03, lens: 60.0},
  // lamp AND one child together, for any beat where someone acts on the flame
  {tag: "lampmed", px: 0.85, py: 0.95, pz: 0.78, ax: -0.10, ay: wallY -. 0.15, az: nicheH, lens: 35.0},
  // the reverse: from BESIDE the niche, inside the courtyard, back at the faces
  {tag: "faces", px: 1.55, py: wallY -. 0.30, pz: 1.20, ax: -0.15, ay: 1.15, az: 0.45, lens: 28.0},
  // कैस्टर's own eyeline — the lamp large above him
  {tag: "childeye", px: -0.20, py: 1.35, pz: 0.32, ax: 0.0, ay: wallY, az: nicheH, lens: 35.0},
  // over फ्यूरिया's shoulder toward the lamp
  {tag: "overfuria", px: -0.85, py: 1.05, pz: 0.72, ax: 0.05, ay: wallY -. 0.08, az: nicheH, lens: 40.0},
  // दादी's doorway, from the lamp side
  {tag: "door", px: 0.0, py: 0.60, pz: 1.10, ax: 0.0, ay: doorY, az: 1.05, lens: 35.0},
  // out over the wall to the valley — where the wind is born
  {tag: "valley", px: 0.0, py: 1.90, pz: 1.45, ax: 0.0, ay: 7.0, az: 0.90, lens: 28.0},
  // low three-quarter across the group, lamp at frame right
  {tag: "group34", px: -2.15, py: -0.35, pz: 1.00, ax: 0.15, ay: 1.95, az: 0.52, lens: 30.0},
  // high and back: one small lit place in a large dark night
  {tag: "high", px: -1.00, py: -1.90, pz: 2.30, ax: 0.0, ay: 1.90, az: 0.50, lens: 26.0},
]

let camJson = c =>
  obj([
    ("tag", str(c.tag)),
    ("pos", Js.Json.array([num(c.px), num(c.py), num(c.pz)])),
    ("aim", Js.Json.array([num(c.ax), num(c.ay), num(c.az)])),
    ("lens", num(c.lens)),
  ])

// ---- the thirty shots ----------------------------------------------------------
// shot id, camera station, which actors stand in it, and the light state.
// Two light states only: "dusk" (शॉट ०१–०६) and "night" (the rest). The lamp is
// the key light in both; at night it is the ONLY light.
type shot = {id: string, cam: string, cast: array<actor>, light: string, secs: float}

let sh = (id, cam, cast, light, secs) => {id, cam, cast, light, secs}

let shots = [
  sh("s00_plate", "wide", [], "dusk", 0.0),
  sh("s01_dadi_enters", "wide", [dadiAtDoor], "dusk", 9.0),
  sh("s02_lamp_lit", "niche", [dadiAtNiche], "dusk", 8.0),
  sh("s03_five_settle", "group34", withDadiNiche, "dusk", 9.0),
  sh("s04_dadi_explains", "faces", withDadiNiche, "dusk", 10.0),
  sh("s05_first_gust", "flame", childrenOnly, "dusk", 6.0),
  sh("s06_dadi_valley", "valley", [dadiAtNiche], "dusk", 10.0),
  sh("s07_dadi_leaves", "door", withDadiDoor, "night", 9.0),
  sh("s08_furia_offers", "overfuria", childrenOnly, "night", 8.0),
  sh("s09_wing_nearly_kills", "lampmed", childrenOnly, "night", 9.0),
  sh("s10_furia_backs_off", "group34", childrenOnly, "night", 8.0),
  sh("s11_castor_cups", "childeye", childrenOnly, "night", 10.0),
  sh("s12_paws_too_small", "lampmed", childrenOnly, "night", 8.0),
  sh("s13_vesper_wall", "niche", childrenOnly, "night", 9.0),
  sh("s14_wall_flies", "niche", childrenOnly, "night", 7.0),
  sh("s15_leda_counts", "valley", childrenOnly, "night", 11.0),
  sh("s16_all_shield", "group34", childrenOnly, "night", 12.0),
  sh("s17_offbeat_gust", "lampmed", childrenOnly, "night", 9.0),
  sh("s18_blue_thread", "flame", childrenOnly, "night", 7.0),
  sh("s19_kuku_breathes_nothing", "overfuria", childrenOnly, "night", 9.0),
  sh("s20_mist_scatters", "niche", childrenOnly, "night", 8.0),
  sh("s21_furia_gives_first", "faces", childrenOnly, "night", 10.0),
  sh("s22_kuku_hears_the_sound", "childeye", childrenOnly, "night", 11.0),
  sh("s23_leda_draws_shape", "faces", childrenOnly, "night", 12.0),
  sh("s24_all_encourage", "group34", childrenOnly, "night", 8.0),
  sh("s25_curve_forms", "niche", childrenOnly, "night", 12.0),
  sh("s26_line_rises", "niche", childrenOnly, "night", 10.0),
  sh("s27_wind_turns", "valley", childrenOnly, "night", 11.0),
  sh("s28_flame_stands", "flame", childrenOnly, "night", 9.0),
  sh("s29_dadi_returns", "door", withDadiDoor, "night", 11.0),
  sh("s30_night_holds", "high", childrenOnly, "night", 9.0),
]

let shotJson = s =>
  obj([
    ("id", str(s.id)),
    ("cam", str(s.cam)),
    ("light", str(s.light)),
    ("secs", num(s.secs)),
    ("cast", Js.Json.array(Js.Array2.map(s.cast, actorJson))),
  ])

let scene = obj([
  ("episode", str("EP12")),
  ("set", str("dadi_courtyard")),
  ("floor_size_m", num(floorSize)),
  ("wall_y_m", num(wallY)),
  ("wall_h_m", num(wallH)),
  ("niche_h_m", num(nicheH)),
  ("door_y_m", num(doorY)),
  ("diya", Js.Json.array([num(diyaX), num(diyaY), num(diyaZ)])),
  ("cams", Js.Json.array(Js.Array2.map(cams, camJson))),
  ("shots", Js.Json.array(Js.Array2.map(shots, shotJson))),
])

let () = {
  mkdirSync(outDir, {"recursive": true})
  writeFileSync(outDir ++ "courtyard_scene.json", Js.Json.stringifyWithSpace(scene, 2))
  Js.log(
    "courtyard_scene.json — " ++
    Js.Int.toString(Js.Array2.length(shots)) ++ " shots, " ++
    Js.Int.toString(Js.Array2.length(cams)) ++ " camera stations, one set",
  )
}
