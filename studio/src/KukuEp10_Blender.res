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

let camJson = c =>
  obj([
    ("tag", str(c.tag)),
    ("pos", Js.Json.array([num(c.x), num(c.y), num(c.z)])),
    ("aim", Js.Json.array([num(c.ax), num(c.ay), num(c.az)])),
    ("lens_mm", num(c.lens)),
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
    ("cameras", Js.Json.array(Js.Array2.map(laneCams, camJson))),
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
