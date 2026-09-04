/* Drakosha_Blender.res — emit the room bible as a Blender-buildable scene.

   The geometry already exists as data in Drakosha_Room. This module only writes
   it as JSON; sets/blender/build_room.py reads that and constructs the room, so
   camera angles and blocking stop being the video model's guess.

   A BODY is placed here, not described: position, facing, height and the
   character's own colour, so the blockout carries WHO as well as WHERE.

   Run from studio/:  node src/Drakosha_Blender.res.mjs [shot] */

module R = Drakosha_Room

@module("fs") external writeFileSync: (string, string) => unit = "writeFileSync"
@module("fs") external mkdirSync: (string, {"recursive": bool}) => unit = "mkdirSync"

let outDir = "../stories/drakosha/ep1prod/sets/blender/"
mkdirSync(outDir, {"recursive": true})

let str = Js.Json.string
let num = Js.Json.number
let obj = kvs => Js.Json.object_(Js.Dict.fromArray(kvs))

/* WHICH LEVEL SOMEBODY IS ON IS A FACT, NOT AN INFERENCE. Working it out from
   coordinates put Мама and Папа on the underfloor road while they stood at the
   table. The shot says where they are: "hall", "ramp" or "road". */
type body = {who: string, head: float, hip: float, arm: float, baby: bool, pose: string, hands: string, seat: float, bx: float, by: float, facing: float, tall: float, level: string, r: float, g: float, b: float}

/* HEIGHTS ARE LOOKED UP, NOT DERIVED. stories/frosya-vasya/BIBLE.md line 256
   carries the registry: В 3.15 / Ф 3.5 / Яга 3.6 hunched / М 3.9 / П 4.5 in.

   I first computed them from the prose relations in castScale — "a head shorter
   than Мама", "a head above Мама" — with the head measured at 51% of body. That
   gave Вася 5.8 cm, two thirds of Фрося, and Папа half again taller than Мама.
   Both absurd. Those relations are written for a video model in the language of
   ordinary human proportion, where a head is an eighth of a body; on a design
   that is half head they are not arithmetic. The registry is. */
/* one copy only — the registry lives in the set bible beside the furniture that
   is derived from it, so a body and the chair it sits on can never drift apart */
let vasyaH = R.vasyaH
let frosyaH = R.frosyaH
let mamaH = R.mamaH
let papaH = R.papaH

/* HEAD HEIGHT, MEASURED CHIN TO CROWN off FAMILY_SCALE_AUTHORITY_v2 with a
   ruler laid over it. Author, 2026-08-31: "it's not the same head and different
   proportion of body. It's also the heads get bigger as the bodies get bigger."
   Both true, and one head size for all five was wrong.

   Sheet reads ~162 px per inch. Crown is the top of hair or kerchief; Яга is
   measured in her head columns only, never the broom. Папа's chin is behind the
   beard, so his is the one estimate here — read from the moustache line, and the
   least trustworthy number in the list.

       Вася 1.50   Фрося 1.54   Яга 1.56   Мама 1.67   Папа ~2.10 in

   NOTE FOR PROMPTING, NOT FOR GEOMETRY: BIBLE.md tells the image model "two and
   a half head-heights", and that calibration is right — asking for two gave a
   head far too big. But what the sheet actually RENDERED is 2.1 to 2.35. The
   prompt number and the delivered number are different things; this file wants
   the delivered one. */
let headVasya = 1.50 *. R.inch
let headFrosya = 1.54 *. R.inch
let headYaga = 1.56 *. R.inch
/* ARM LENGTH, shoulder to fingertip, measured off the same ruled sheet as the
   heads. IT IS SHORTER THAN THE LEG for every one of them — .18 to .31 of body
   against .30 for the leg. Author, 2026-08-31: "currently their arms are longer
   than their legs. You really have to build them standing so that they make
   sense and then sit them down." The arm used to be however far the hand had to
   travel to reach the table, which is not a body, it is a rubber band. */
let headMama = 1.67 *. R.inch
let headPapa = 2.10 *. R.inch
let headYaga = 1.56 *. R.inch
/* ARM LENGTH, shoulder to fingertip, measured off the same ruled sheet as the
   heads. IT IS SHORTER THAN THE LEG for every one of them — .18 to .31 of body
   against .30 for the leg. Author, 2026-08-31: "currently their arms are longer
   than their legs. You really have to build them standing so that they make
   sense and then sit them down." The arm used to be however far the hand had to
   travel to reach the table, which is not a body, it is a rubber band. */
let headBaby = 0.93 *. R.inch
/* MEASURED off C-BABY-RATIO-01 with a ruler: Руся is 355px tall at 211.5 px/in
   = 1.68in, and his head runs 200px chin to crown = 0.95in. Муся's is 0.90.
   That is 55% of their height in head — I had them at 0.85 and the heads were
   too small. Author, 2026-08-31. */
/* MEASURED off C-BABY-RATIO-01: a baby's head is about half its whole height and
   the legs only a fifth, the rest torso. At 0.90 the head was wider than the
   body was long, so on all fours Муся rendered as a ball on the boards with no
   body at all. Author, 2026-08-31. */

/* OBJECT_SCALE_REGISTRY_v1: C-RUS and C-MUS are both 1.70in / 4.32cm, "same
   height, visibly rounder". Яга is 3.6in hunched per FAMILY_SCALE_AUTHORITY_v2,
   which supersedes the registry's 3.85 for C-YAG-MINI. */
let yagaH = R.yagaH
let babyH = 1.70 *. R.inch

/* THE EXCHANGE, blocked. The staging alternates FROSYA_AT_RAMP and
   FROSYA_ON_ROAD are gone — they put Фрося in frame three times at once. Add a
   second placement back only when a shot actually needs it. */
let exchange = [
  {who: "FROSYA", head: headFrosya, hip: 0.30, arm: 0.217, baby: false, pose: "stand", hands: "bars", seat: 0.0, bx: 6.0, by: 36.0, facing: 300.0, tall: frosyaH, level: "hall", r: 0.30, g: 0.85, b: 0.45},
  {who: "VASYA", head: headVasya, hip: 0.30, arm: 0.184, baby: false, pose: "stand", hands: "side", seat: 0.0, bx: -1.0, by: 44.0, facing: 221.0, tall: vasyaH, level: "hall", r: 0.30, g: 0.55, b: 0.95},
  {who: "MAMA", head: headMama, hip: 0.30, arm: 0.254, baby: false, pose: "sit", hands: "table", seat: 1.4, bx: -9.6, by: 98.0, facing: 270.0, tall: mamaH, level: "hall", r: 0.95, g: 0.55, b: 0.30},
  {who: "PAPA", head: headPapa, hip: 0.30, arm: 0.307, baby: false, pose: "sit", hands: "table", seat: 1.4, bx: 9.6, by: 98.0, facing: 90.0, tall: papaH, level: "hall", r: 0.85, g: 0.30, b: 0.75},
  /* the family at the plank table by the iron plate — provisional placement,
     it moves with the room size the author is still ruling on */
  {who: "YAGA", head: headYaga, hip: 0.30, arm: 0.225, baby: false, pose: "sit", hands: "table", seat: 1.4, bx: 0.0, by: 102.0, facing: 180.0, tall: yagaH, level: "hall", r: 0.55, g: 0.45, b: 0.30},
  {who: "RUSYA", head: headBaby, hip: 0.22, arm: 0.300, baby: true, pose: "sit", hands: "lap", seat: 0.15, bx: -11.5, by: 93.0, facing: 205.0, tall: babyH, level: "hall", r: 0.95, g: 0.75, b: 0.35},
  {who: "MUSYA", head: headBaby, hip: 0.22, arm: 0.300, baby: true, pose: "crawl", hands: "lap", seat: 0.15, bx: -4.5, by: 92.0, facing: 155.0, tall: babyH, level: "hall", r: 0.95, g: 0.60, b: 0.70},
]

let mark = (l: R.landmark) =>
  obj([
    ("name", str(l.name)),
    ("pos", Js.Json.array([num(l.x), num(l.y), num(l.z)])),
    ("size", Js.Json.array([num(l.w), num(l.d), num(l.h)])),
    ("note", str(l.note)),
  ])

let bodyJson = (b: body) =>
  obj([
    ("who", str(b.who)),
    ("pos", Js.Json.array([num(b.bx), num(b.by)])),
    ("facing", num(b.facing)),
    ("level", str(b.level)),
    ("tall", num(b.tall)),
    ("head", num(b.head)),
    ("hip", num(b.hip)),
    ("arm", num(b.arm)),
    /* EXPLICIT, NOT INFERRED. This was decided by head-to-height with the line
       at 40%, and every adult in the family is above it — Мама 42.8, Папа 46.6,
       Вася 47.6 — so the whole cast was being built with baby construction and
       lost its pelvis and every joint. On a design where the adults are already
       nearly half head, that ratio cannot separate them. Author, 2026-08-31:
       "why do they all look different now?" 2026-08-31. */
    ("baby", Js.Json.boolean(b.baby)),
    ("pose", str(b.pose)),
    ("hands", str(b.hands)),
    ("seat", num(b.seat)),
    ("rgb", Js.Json.array([num(b.r), num(b.g), num(b.b)])),
  ])

let scene = obj([
  ("hall_w_cm", num(R.hallWidth)),
  ("hall_l_cm", num(R.hallLength)),
  ("wall_h_cm", num(R.wallHeight)),
  ("landmarks", Js.Json.array(Js.Array2.map(R.landmarks, mark))),
  ("furnishings", Js.Json.array(Js.Array2.map(R.furnishings, mark))),
  ("road", Js.Json.array(Js.Array2.map(R.roadDatum, mark))),
  ("lower", Js.Json.array(Js.Array2.map(R.lowerStorey, mark))),
  ("floor_t", num(R.floorThickness)),
  ("road_drop", num(R.roadDrop)),
  ("rail_h", num(R.railHeight)),
  ("frosya_h", num(R.frosyaH)),
  ("ramp_foot_w", num(R.rampFootWidth)),
  ("bodies", Js.Json.array(Js.Array2.map(exchange, bodyJson))),
])

let file = outDir ++ "room_exchange.json"
writeFileSync(file, Js.Json.stringifyWithSpace(scene, 1))
Js.log("wrote " ++ file)
