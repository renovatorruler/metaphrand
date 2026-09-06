// KukuEp10_Puppets.res — the puppets of EP10 and the shots that move them.
//
// कुकु was generated ONCE as a spread-pose sprite on a blue sheet (receipted,
// 2 credits). Everything below is numbers: where each part is cut, where it
// hinges, how it moves. A render costs nothing and is the same every time.
//
//   node src/KukuEp10_Puppets.res.mjs cut       # cut the parts from the sprite
//   node src/KukuEp10_Puppets.res.mjs check     # rest pose + exploded pose, on grey
//   node src/KukuEp10_Puppets.res.mjs fly       # the proof: कुकु flies in and lands at the niche

@module("fs") external mkdirSync: (string, {"recursive": bool}) => unit = "mkdirSync"
@module("process") external cwd: unit => string = "cwd"
@module("process") external argv: array<string> = "argv"

open Puppet

let root = cwd() ++ "/../stories/kuku/ep10/"
let outDir = root ++ "cutout/out/"

/* ------------------------------------------------------------ कुकु's rig */
/* Sprite space is the raw generation, 2752x1536, कुकु facing LEFT. Polygons
   are loose wherever they border transparent sheet and careful only where
   parts meet: a part must never copy a neighbour's pixels, or the copy moves
   with it as a ghost. Pivots sit on the joints. Drawing order, back to front:
   far wing, far arm, far leg, tail, near wing, torso, near leg, near arm, head. */
let p = (x, y) => (Px(x), Px(y))
let torso = PartName("torso")
let head = PartName("head")
let wingNear = PartName("wingNear") /* screen-left, in front of the body */
let wingFar = PartName("wingFar") /* screen-right, behind the body */
let armNear = PartName("armNear")
let armFar = PartName("armFar")
let legNear = PartName("legNear")
let legFar = PartName("legFar")
let tail = PartName("tail")

let kukuRig: rigSpec<small> = {
  sprite: ImagePath(root ++ "cutout/sprites/kuku_spread.png"),
  partsDir: root ++ "cutout/parts/kuku/",
  parts: [
    {
      name: torso,
      parent: None,
      pivot: p(1320.0, 980.0),
      z: 6,
      outline: [p(1180.0, 640.0), p(1300.0, 615.0), p(1375.0, 600.0), p(1450.0, 720.0), p(1462.0, 1040.0), p(1400.0, 1095.0), p(1395.0, 1300.0), p(1210.0, 1300.0), p(1150.0, 1200.0), p(1120.0, 1000.0), p(1140.0, 830.0), p(1168.0, 760.0)],
    },
    {
      name: head,
      parent: Some(torso),
      pivot: p(1290.0, 740.0),
      z: 9,
      outline: [p(990.0, 560.0), p(1005.0, 440.0), p(1085.0, 255.0), p(1150.0, 165.0), p(1250.0, 140.0), p(1480.0, 165.0), p(1610.0, 300.0), p(1625.0, 500.0), p(1560.0, 610.0), p(1420.0, 655.0), p(1380.0, 770.0), p(1180.0, 785.0), p(1075.0, 685.0)],
    },
    {
      name: wingNear,
      parent: Some(torso),
      pivot: p(1190.0, 740.0),
      z: 5,
      outline: [p(1120.0, 190.0), p(1030.0, 300.0), p(1010.0, 470.0), p(1000.0, 590.0), p(1085.0, 665.0), p(1190.0, 690.0), p(1198.0, 800.0), p(950.0, 800.0), p(850.0, 785.0), p(640.0, 520.0), p(470.0, 240.0), p(500.0, 150.0), p(900.0, 130.0)],
    },
    {
      name: wingFar,
      parent: Some(torso),
      pivot: p(1420.0, 700.0),
      z: 1,
      outline: [p(1372.0, 700.0), p(1425.0, 765.0), p(1800.0, 768.0), p(2000.0, 700.0), p(2280.0, 560.0), p(2260.0, 150.0), p(1500.0, 150.0), p(1520.0, 560.0), p(1400.0, 640.0)],
    },
    {
      name: armNear,
      parent: Some(torso),
      pivot: p(1170.0, 835.0),
      z: 8,
      outline: [p(1168.0, 762.0), p(830.0, 770.0), p(800.0, 830.0), p(825.0, 900.0), p(1165.0, 908.0)],
    },
    {
      name: armFar,
      parent: Some(torso),
      pivot: p(1405.0, 835.0),
      z: 2,
      outline: [p(1385.0, 758.0), p(1790.0, 768.0), p(1830.0, 840.0), p(1800.0, 928.0), p(1425.0, 912.0)],
    },
    {
      name: legNear,
      parent: Some(torso),
      pivot: p(1140.0, 1120.0),
      z: 7,
      outline: [p(1075.0, 1040.0), p(1130.0, 1030.0), p(1205.0, 1110.0), p(1205.0, 1350.0), p(1275.0, 1330.0), p(1285.0, 1430.0), p(990.0, 1430.0), p(1000.0, 1340.0), p(1060.0, 1330.0), p(1035.0, 1150.0)],
    },
    {
      name: legFar,
      parent: Some(torso),
      pivot: p(1500.0, 1120.0),
      z: 3,
      outline: [p(1395.0, 1090.0), p(1470.0, 1040.0), p(1640.0, 1060.0), p(1662.0, 1200.0), p(1650.0, 1330.0), p(1750.0, 1350.0), p(1765.0, 1445.0), p(1345.0, 1450.0), p(1350.0, 1350.0), p(1392.0, 1300.0)],
    },
    {
      name: tail,
      parent: Some(torso),
      pivot: p(1600.0, 1150.0),
      z: 4,
      outline: [p(1560.0, 935.0), p(2430.0, 950.0), p(2440.0, 1130.0), p(2000.0, 1268.0), p(1665.0, 1262.0), p(1662.0, 1160.0), p(1642.0, 1062.0), p(1470.0, 1040.0), p(1540.0, 1000.0)],
    },
  ],
}

/* the point between his feet, in sprite space: what stands on the ground */
let feet = (1140.0, 1420.0)

/* a state with every part at rest, placed by where the feet are on the stage */
let standing = (~feetX, ~feetY, ~size) => {
  let (fx, fy) = feet
  {
    x: Px(feetX -. fx *. size),
    y: Px(feetY -. fy *. size),
    size: Scale(size),
    facingLeft: true,
    bank: Deg(0.0),
    parts: Js.Dict.empty(),
    opacity: Alpha(1.0),
  }
}

let posed = (st: puppetState, poses: array<(partName, partPose)>): puppetState => {
  let d = Js.Dict.empty()
  Js.Array2.forEach(poses, ((PartName(n), pose)) => Js.Dict.set(d, n, pose))
  {...st, parts: d}
}

/* ---------------------------------------------------------------- checks */
let stageW = 1280
let stageH = 720
let fpsOut = Fps(24)

let check = async () => {
  mkdirSync(outDir, {"recursive": true})
  let rig = await loadRig(kukuRig)
  let grey = colourLayer(~z=0, ~colour="#7a7a7a", ~w=Px(1280.0), ~h=Px(720.0))
  let restState = _t => standing(~feetX=640.0, ~feetY=660.0, ~size=0.42)
  /* every part swung by a test angle: any pixel that belongs to a neighbour
     shows up as a ghost that moves with the wrong piece */
  let exploded = _t =>
    posed(
      standing(~feetX=640.0, ~feetY=660.0, ~size=0.42),
      [
        (head, turn(-14.0)),
        (wingNear, turn(22.0)),
        (wingFar, turn(-22.0)),
        (armNear, turn(-35.0)),
        (armFar, turn(30.0)),
        (legNear, turn(-25.0)),
        (legFar, turn(25.0)),
        (tail, turn(-12.0)),
      ],
    )
  let sh = state => {
    name: "check",
    width: stageW,
    height: stageH,
    fps: fpsOut,
    duration: Sec(1.0),
    layers: [grey, puppetLayer(~z=1, ~rig, ~state)],
    camera: _t => wholeStage(1280.0, 720.0),
    audio: None,
    out: "",
  }
  frame(sh(restState), Sec(0.0), outDir ++ "check_rest.png")
  frame(sh(exploded), Sec(0.0), outDir ++ "check_exploded.png")
  Js.log("wrote check_rest.png and check_exploded.png in " ++ outDir)
}

/* ------------------------------------------------------- shared helpers */
let easeOut = u => 1.0 -. Js.Math.pow_float(~base=1.0 -. u, ~exp=3.0)
let clamp01 = u => u < 0.0 ? 0.0 : u > 1.0 ? 1.0 : u
let groundY = 640.0
let courtyard = async () => {
  let plate = await plateLayer(~path=ImagePath(root ++ "sets/courtyard_plate.png"), ~w=Px(1280.0), ~h=Px(720.0))
  let lamp = await imageLayer(~z=1, ~path=ImagePath(root ++ "cutout/sprites/lamp_lit.png"), ~x=Px(548.0), ~y=Px(353.0), ~w=Px(110.0), ~h=Px(79.0))
  (plate, lamp)
}

/* ------------------------------------------------- the ground proof: run */
/* Small कुकु cannot fly — only the great forms fly, after the कड़ा — so the
   small form's action is on the ground: he runs in from the right along the
   flagstones, skids to a stop beside the niche, and looks up at the lamp. */
let runIn = async () => {
  mkdirSync(outDir, {"recursive": true})
  let rig = await loadRig(kukuRig)
  let (plate, lamp) = await courtyard()
  let size = 0.21
  let stopT = 3.3
  let stopX = 735.0
  let speed = 190.0
  let f = 2.6 /* strides per second */
  /* the feet: a steady run, then the last stretch eases into a skid */
  let feetX = t => {
    let tv = secf(t)
    let brakeT = stopT -. 0.55
    let xAtBrake = 1330.0 -. speed *. brakeT
    tv < brakeT ? 1330.0 -. speed *. tv : xAtBrake +. (stopX -. xAtBrake) *. easeOut(clamp01((tv -. brakeT) /. 0.55))
  }
  /* how much of the run is still happening: 1 at speed, 0 once stopped */
  let running = t => 1.0 -. easeOut(clamp01((secf(t) -. (stopT -. 0.55)) /. 0.55))
  let stride = t => Js.Math.sin(2.0 *. Js.Math._PI *. f *. secf(t))
  let legs = t => 16.0 *. running(t) *. stride(t)
  /* the brace at the stop: legs planted apart, then relaxed */
  let brace = t => track([{at: Sec(stopT -. 0.3), v: 0.0}, {at: Sec(stopT), v: 12.0}, {at: Sec(stopT +. 0.6), v: 0.0}], t)
  let bob = t => 3.0 *. running(t) *. Js.Math.abs_float(Js.Math.sin(2.0 *. Js.Math._PI *. f *. secf(t)))
  let squash = t => track([{at: Sec(stopT), v: 0.0}, {at: Sec(stopT +. 0.1), v: 5.0}, {at: Sec(stopT +. 0.4), v: 0.0}], t)
  let lean = t => -7.0 *. running(t) +. track([{at: Sec(stopT -. 0.3), v: 0.0}, {at: Sec(stopT), v: 6.0}, {at: Sec(stopT +. 0.7), v: 0.0}], t)
  /* wings swept up while running, like a child running with arms raised, with a
     flutter on the stride; they settle to the spread rest once he stands */
  let sweep = t => track([{at: Sec(0.0), v: 35.0}, {at: Sec(stopT +. 0.2), v: 35.0}, {at: Sec(stopT +. 1.0), v: 0.0}], t) +. 6.0 *. running(t) *. stride(t)
  /* arms hang and swing opposite the legs; the look up at the lamp */
  let armSwing = t => 12.0 *. running(t) *. stride(t)
  let look = t => track([{at: Sec(stopT +. 0.7), v: 0.0}, {at: Sec(stopT +. 1.2), v: -11.0}], t)
  let state = t => {
    let base = standing(~feetX=feetX(t), ~feetY=groundY +. squash(t), ~size)
    posed(
      {...base, y: Px(pxf(base.y) -. bob(t)), bank: Deg(lean(t))},
      [
        (legNear, turn(legs(t) +. brace(t))),
        (legFar, turn(-.legs(t) -. brace(t))),
        (armNear, turn(-32.0 -. armSwing(t))),
        (armFar, turn(32.0 -. armSwing(t))),
        (wingNear, turn(sweep(t))),
        (wingFar, turn(-.sweep(t))),
        (tail, turn(6.0 *. running(t) *. Js.Math.sin(2.0 *. Js.Math._PI *. f *. secf(t) -. 1.2))),
        (head, turn(-0.5 *. lean(t) +. 2.0 *. running(t) *. stride(t) +. look(t))),
      ],
    )
  }
  let shadow = t => {cx: Px(feetX(t)), cy: Px(groundY +. 6.0), rx: Px(150.0 *. size *. 3.4), ry: Px(70.0 *. size), a: Alpha(0.3)}
  let camera = t => {
    zoom: Scale(track([{at: Sec(0.0), v: 1.06}, {at: Sec(stopT +. 0.8), v: 1.11}], t)),
    lookX: Px(track([{at: Sec(0.0), v: 700.0}, {at: Sec(stopT +. 0.8), v: 685.0}], t)),
    lookY: Px(372.0),
  }
  let sh = {
    name: "kuku_runs_in",
    width: stageW,
    height: stageH,
    fps: fpsOut,
    duration: Sec(5.4),
    layers: [plate, lamp, shadowLayer(~z=2, ~shadow), puppetLayer(~z=3, ~rig, ~state)],
    camera,
    audio: None,
    out: outDir ++ "proof_kuku_runs_in.mp4",
  }
  render(sh)
  contactSheet(~video=sh.out, ~out=outDir ++ "proof_kuku_runs_in_sheet.png", ~cols=6, ~rows=2, ~everySec=0.45)
}

/* ------------------------------------------------------------ the flight */
/* Authored once, waiting for a rig it can accept: the parameter is rig<great>,
   so कुकु's small rig cannot be handed in — that is the series law as a type.
   His great form has no sprite yet (one Sheet generation, 2 credits). */
let flight = (rig: rig<great>, ~plate, ~lamp): shot => {
  let landT = 4.2
  let landX = 720.0
  let feetX = t => track([{at: Sec(0.0), v: 1330.0}, {at: Sec(landT), v: landX}], ~ease=linear, t)
  let height = t => track([{at: Sec(0.0), v: 430.0}, {at: Sec(1.8), v: 250.0}, {at: Sec(3.0), v: 210.0}, {at: Sec(landT), v: 0.0}], t)
  let feetY = t => groundY -. height(t) +. track([{at: Sec(landT), v: 0.0}, {at: Sec(landT +. 0.12), v: 7.0}, {at: Sec(landT +. 0.45), v: 0.0}], t)
  let size = t => track([{at: Sec(0.0), v: 0.13}, {at: Sec(landT), v: 0.21}], ~ease=linear, t)
  let hz = 2.4
  let flapAmp = t => track([{at: Sec(0.0), v: 26.0}, {at: Sec(2.6), v: 18.0}, {at: Sec(3.4), v: 30.0}, {at: Sec(landT), v: 0.0}], t)
  let flap = t => cycle(~hz, ~amp=flapAmp(t), t)
  let wingHold = t => track([{at: Sec(3.4), v: 0.0}, {at: Sec(landT +. 0.2), v: 0.0}, {at: Sec(landT +. 1.1), v: 38.0}], t)
  let pitch = t => track([{at: Sec(0.0), v: -10.0}, {at: Sec(1.8), v: -6.0}, {at: Sec(3.3), v: 14.0}, {at: Sec(landT), v: 0.0}], t)
  let tuck = t => track([{at: Sec(0.0), v: -38.0}, {at: Sec(3.2), v: -38.0}, {at: Sec(landT -. 0.1), v: 0.0}], t)
  let arms = t => track([{at: Sec(0.0), v: -28.0}, {at: Sec(3.3), v: -10.0}, {at: Sec(landT), v: 8.0}, {at: Sec(landT +. 0.9), v: -30.0}], t)
  let look = t => track([{at: Sec(landT +. 0.9), v: 0.0}, {at: Sec(landT +. 1.4), v: 9.0}], t)
  let state = t => {
    let s = size(t)
    let base = standing(~feetX=feetX(t), ~feetY=feetY(t), ~size=s)
    let fl = flap(t)
    let bob = secf(t) < landT ? 4.0 *. Js.Math.sin(2.0 *. Js.Math._PI *. hz *. secf(t) -. 1.2) : 0.0
    posed(
      {...base, y: Px(pxf(base.y) +. bob), bank: Deg(pitch(t))},
      [
        (wingNear, turn(fl -. wingHold(t))),
        (wingFar, turn(-.fl +. wingHold(t))),
        (head, turn(-0.4 *. pitch(t) +. look(t))),
        (legNear, turn(tuck(t))),
        (legFar, turn(tuck(t))),
        (armNear, turn(arms(t))),
        (armFar, turn(-.arms(t))),
        (tail, turn(cycle(~hz, ~amp=secf(t) < landT ? 7.0 : 0.0, ~phase=-1.4, t))),
      ],
    )
  }
  let shadow = t => {
    let hgt = height(t)
    let s = size(t)
    {
      cx: Px(feetX(t)),
      cy: Px(groundY +. 6.0),
      rx: Px(520.0 *. s *. (1.0 -. 0.5 *. Js.Math.min_float(1.0, hgt /. 300.0))),
      ry: Px(70.0 *. s),
      a: Alpha(0.32 *. (1.0 -. 0.8 *. Js.Math.min_float(1.0, hgt /. 300.0))),
    }
  }
  let camera = t => {
    zoom: Scale(track([{at: Sec(0.0), v: 1.06}, {at: Sec(landT +. 0.6), v: 1.14}], t)),
    lookX: Px(track([{at: Sec(0.0), v: 660.0}, {at: Sec(landT +. 0.6), v: 690.0}], t)),
    lookY: Px(track([{at: Sec(0.0), v: 345.0}, {at: Sec(landT +. 0.6), v: 400.0}], t)),
  }
  {
    name: "kuku_flies_in",
    width: stageW,
    height: stageH,
    fps: fpsOut,
    duration: Sec(6.2),
    layers: [plate, lamp, shadowLayer(~z=2, ~shadow), puppetLayer(~z=3, ~rig, ~state)],
    camera,
    audio: None,
    out: outDir ++ "proof_kuku_flies_in.mp4",
  }
}

let () =
  switch Belt.Array.get(argv, 2) {
  | Some("cut") => ignore(cut(kukuRig))
  | Some("check") => ignore(check())
  | Some("run") => ignore(runIn())
  | Some("fly") =>
    Js.log("the flight takes a great-form rig only (rig<great>); कुकु's great form has no sprite yet — one Sheet generation, 2 credits, on the author's budget line")
  | _ => Js.log("usage: cut | check | run | fly")
  }
