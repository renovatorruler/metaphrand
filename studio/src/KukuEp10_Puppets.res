// KukuEp10_Puppets.res — the proofs and checks that move the EP10 puppets.
//
//   node src/KukuEp10_Puppets.res.mjs cut | check | run | talk | talk3 | lights | lineup | fly
//
// The rigs and the stage live in KukuEp10_Rigs; the episode's scenes live in
// their own modules. This file only runs things.

@module("process") external argv: array<string> = "argv"

open Puppet
open KukuEp10_Rigs
open KukuEp10_Stage

/* THE STAGE TEST: every mechanism of the stage in one sixteen-second scene,
   so the machinery is proven before a single scene of the script is authored. */
let stageTest = async () => {
  let dadi = await actor("dadi")
  let kuku = await actor("kuku")
  let furia = await actor("furia")
  let papa = await actor("papa")
  let sleeper = await actor("kalu_asleep")
  let plate = await plateLayer(~path=ImagePath(root ++ "sets/courtyard_plate.png"), ~w=Px(1280.0), ~h=Px(720.0))
  let bowl = await bowlLayer(1)
  let wall = await wallMask(4)
  let door = await doorMask(7)
  let gusts = [{at: 3.0, len: 1.5, strength: 0.6}, {at: 6.0, len: 1.2, strength: 0.9}, {at: 8.5, len: 1.6, strength: 1.4}]
  let dies = 9.4
  let flame = t => secf(t) < dies ? flameInWind(gusts, t) : flameOut
  let cues = [{line: 1, at: 4.2}, {line: 9, at: 12.0}]
  let letter = await letterLayer(~z=21, ~x=760.0, ~y=470.0, ~size=240.0,
    ~reveal=t => track([{at: Sec(11.0), v: 0.0}, {at: Sec(12.4), v: 1.0}], t),
    ~roof=t => track([{at: Sec(12.5), v: 0.0}, {at: Sec(13.2), v: 1.0}], t),
    ~glow=t => track([{at: Sec(11.5), v: 0.0}, {at: Sec(13.5), v: 0.8}], t))
  let dadiState = t => walkingActor(dadi, ~from={x: 120.0, y: 632.0, facingLeft: false}, ~to_={x: 880.0, y: 628.0, facingLeft: false}, ~t0=0.5, ~t1=4.0, cues, t)
  let furiaState = t => walkingActor(furia, ~from={x: 1350.0, y: 660.0, facingLeft: true}, ~to_={x: 960.0, y: 650.0, facingLeft: true}, ~t0=5.0, ~t1=8.0, cues, t)
  let kukuState = t => sittingActor(kuku, {x: 700.0, y: 640.0, facingLeft: true}, cues, t)
  let papaState = t => standingActor(papa, {x: track([{at: Sec(12.0), v: 1150.0}, {at: Sec(16.0), v: 950.0}], ~ease=linear, t), y: 200.0, facingLeft: true}, cues, ~scale=0.3, t)
  let sleeperState = t => {
    let st = stand(sleeper.spec, ~feetX=420.0, ~feetY=655.0, ~size=0.13, ~facingLeft=false, ())
    posed(st, [(dCurl, {angle: Deg(0.0), dx: Px(0.0), dy: Px(0.0), s: Scale(1.0 +. 0.012 *. Js.Math.sin(2.0 *. Js.Math._PI *. 0.3 *. secf(t)))})])
  }
  let sc = {
    name: "stage_test",
    duration: 16.0,
    layers: Js.Array2.concatMany(
      [plate, bowl, wall, door, letter],
      [
        actorLayers(~z=3, papa, papaState),
        actorLayers(~z=6, dadi, dadiState),
        actorLayers(~z=9, kuku, kukuState),
        actorLayers(~z=10, furia, furiaState),
        actorLayers(~z=8, sleeper, sleeperState),
        [
          windBitsLayer(~z=12, ~gusts),
          mistLayer(~z=21, ~fromX=690.0, ~fromY=560.0, ~toX=760.0, ~toY=470.0, ~puffAt=10.6, ~gather=true),
          fadingTint(~z=20, ~colour=nightTint, ~strength=t => track([{at: Sec(2.0), v: 0.0}, {at: Sec(4.0), v: 1.0}], t)),
          fadingTint(~z=20, ~colour=darkTint, ~strength=t => track([{at: Sec(dies), v: 0.0}, {at: Sec(dies +. 1.2), v: 1.0}], t)),
          flameLayer(~z=21, ~flame),
          smokeLayer(~z=21, ~from=dies),
          valleyLightLayer(~z=22, ~strength=t => track([{at: Sec(13.0), v: 0.0}, {at: Sec(15.0), v: 0.9}], t)),
        ],
      ],
    ),
    camera: still(),
    cues,
  }
  let out = renderScene(sc)
  Js.log("rendered " ++ out)
}


/* rest and exploded poses of any rig, on grey */
let checkRig = async (spec, tag) => {
  mkdirSync(outDir, {"recursive": true})
  let rig = await loadRig(spec)
  let grey = colourLayer(~z=0, ~colour="#7a7a7a", ~w=Px(1280.0), ~h=Px(720.0))
  let restState = _t => stand(spec, ~feetX=640.0, ~feetY=690.0, ~size=0.42, ())
  let exploded = _t =>
    posed(
      stand(spec, ~feetX=640.0, ~feetY=690.0, ~size=0.42, ()),
      [(head, turn(-14.0)), (wingNear, turn(22.0)), (wingFar, turn(-22.0)), (armNear, turn(-35.0)), (armFar, turn(30.0)), (legNear, turn(-25.0)), (legFar, turn(25.0)), (tail, turn(-12.0))],
    )
  let sh = state => {
    name: "check_" ++ tag,
    width: stageW,
    height: stageH,
    fps: fpsOut,
    duration: Sec(1.0),
    layers: [grey, puppetLayer(~z=1, ~rig, ~state)],
    camera: _t => wholeStage(1280.0, 720.0),
    audio: None,
    out: "",
  }
  frame(sh(restState), Sec(0.0), outDir ++ "check_" ++ tag ++ "_rest.png")
  frame(sh(exploded), Sec(0.0), outDir ++ "check_" ++ tag ++ "_exploded.png")
  Js.log("wrote check_" ++ tag ++ "_rest.png and check_" ++ tag ++ "_exploded.png")
}

let check = async () => {
  mkdirSync(outDir, {"recursive": true})
  let rig = await loadRig(kukuRig)
  let grey = colourLayer(~z=0, ~colour="#7a7a7a", ~w=Px(1280.0), ~h=Px(720.0))
  let restState = _t => posedCanonical(standing(~feetX=640.0, ~feetY=660.0, ~size=0.42), [])
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
  /* wings as the character sheet holds them, with a flutter on the stride */
  let flutter = t => 5.0 *. running(t) *. stride(t)
  /* arms hang and swing opposite the legs; the look up at the lamp */
  let armSwing = t => 12.0 *. running(t) *. stride(t)
  let look = t => track([{at: Sec(stopT +. 0.7), v: 0.0}, {at: Sec(stopT +. 1.2), v: -11.0}], t)
  let state = t => {
    let base = standing(~feetX=feetX(t), ~feetY=groundY +. squash(t), ~size)
    posedCanonical(
      {...base, y: Px(pxf(base.y) -. bob(t)), bank: Deg(lean(t))},
      [
        (legNear, turn(legs(t) +. brace(t))),
        (legFar, turn(-.legs(t) -. brace(t))),
        (armNear, turn(-.restArmNear -. armSwing(t))),
        (armFar, turn(restArmFar -. armSwing(t))),
        (wingNear, wingAt(restWingNear +. flutter(t), 0.6)),
        (wingFar, wingAt(restWingFar -. flutter(t), 0.6)),
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
let flight = (rig: rig<great>, ~plate, ~lamp, ~sizeFrom, ~sizeTo, ~landX, ~out): shot => {
  let landT = 4.2
  let feetX = t => track([{at: Sec(0.0), v: 1330.0}, {at: Sec(landT), v: landX}], ~ease=linear, t)
  let height = t => track([{at: Sec(0.0), v: 430.0}, {at: Sec(1.8), v: 250.0}, {at: Sec(3.0), v: 210.0}, {at: Sec(landT), v: 0.0}], t)
  let feetY = t => groundY -. height(t) +. track([{at: Sec(landT), v: 0.0}, {at: Sec(landT +. 0.12), v: 7.0}, {at: Sec(landT +. 0.45), v: 0.0}], t)
  let size = t => track([{at: Sec(0.0), v: sizeFrom}, {at: Sec(landT), v: sizeTo}], ~ease=linear, t)
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
    out,
  }
}

/* the great form flies in: the first flight the type allows */
let flyGreat = async () => {
  mkdirSync(outDir, {"recursive": true})
  let rig = await loadRig(kukuGreatRig)
  let (plate, lamp) = await courtyard()
  let sh = flight(rig, ~plate, ~lamp, ~sizeFrom=0.22, ~sizeTo=0.46, ~landX=760.0, ~out=outDir ++ "proof_kuku_great_flies_in.mp4")
  render(sh)
  contactSheet(~video=sh.out, ~out=outDir ++ "proof_kuku_great_flies_in_sheet.png", ~cols=6, ~rows=2, ~everySec=0.52)
}

let talk = async () => {
  mkdirSync(outDir, {"recursive": true})
  let dadi = await loadRig(dadiRig)
  let kuku = await loadRig(kukuRig)
  let (plate, lamp) = await courtyard()
  let vs = visemes(root ++ "cutout/audio/line008.visemes.json")
  let dur = 8.08 +. 0.6
  let dadiState = t => {
    let base = stand(dadiRig, ~feetX=985.0, ~feetY=628.0, ~size=0.335, ())
    let sway = 1.2 *. Js.Math.sin(2.0 *. Js.Math._PI *. 0.22 *. secf(t))
    let emphasis = 2.0 *. talking(vs, t) *. Js.Math.sin(2.0 *. Js.Math._PI *. 0.9 *. secf(t))
    {...posed(base, [(dHead, turn(-1.5 +. sway +. emphasis))]), mouth: mouthAt(vs, t)}
  }
  let kukuState = t => {
    let base = stand(kukuRig, ~feetX=730.0, ~feetY=640.0, ~size=0.21, ~facingLeft=false, ())
    let nod = track([{at: Sec(3.0), v: 0.0}, {at: Sec(3.25), v: 6.0}, {at: Sec(3.6), v: 0.0}, {at: Sec(6.4), v: 0.0}, {at: Sec(6.65), v: 6.0}, {at: Sec(7.0), v: 0.0}], t)
    let breathe = 0.6 *. Js.Math.sin(2.0 *. Js.Math._PI *. 0.3 *. secf(t))
    posedCanonical(base, [(head, turn(-9.0 +. nod +. breathe)), (tail, turn(3.0 *. Js.Math.sin(2.0 *. Js.Math._PI *. 0.25 *. secf(t))))])
  }
  let shadowOf = (fx, w) => (_t: sec) => {cx: Px(fx), cy: Px(646.0), rx: Px(w), ry: Px(14.0), a: Alpha(0.28)}
  let camera = t => {
    zoom: Scale(track([{at: Sec(0.0), v: 1.1}, {at: Sec(dur), v: 1.18}], ~ease=linear, t)),
    lookX: Px(track([{at: Sec(0.0), v: 690.0}, {at: Sec(dur), v: 718.0}], ~ease=linear, t)),
    lookY: Px(track([{at: Sec(0.0), v: 390.0}, {at: Sec(dur), v: 400.0}], ~ease=linear, t)),
  }
  let sh = {
    name: "dadi_line008",
    width: stageW,
    height: stageH,
    fps: fpsOut,
    duration: Sec(dur),
    layers: [
      plate,
      {...lamp, z: 21},
      glowLayer(~z=22, ~colour="rgba(255,186,96,1)", ~glow=lampGlow(~strength=0.30)),
      shadowLayer(~z=3, ~shadow=shadowOf(985.0, 95.0)),
      shadowLayer(~z=3, ~shadow=shadowOf(730.0, 70.0)),
      puppetLayer(~z=4, ~rig=dadi, ~state=dadiState),
      puppetLayer(~z=5, ~rig=kuku, ~state=kukuState),
    ],
    camera,
    audio: Some(root ++ "cutout/audio/line008.wav"),
    out: outDir ++ "proof_dadi_line008_puppet.mp4",
  }
  render(sh)
  contactSheet(~video=sh.out, ~out=outDir ++ "proof_dadi_line008_puppet_sheet.png", ~cols=6, ~rows=2, ~everySec=0.72)
}

let talkKuku = async () => {
  mkdirSync(outDir, {"recursive": true})
  let dadi = await loadRig(dadiRig)
  let kuku = await loadRig(kukuRig)
  let (plate, lamp) = await courtyard()
  let vs = visemes(root ++ "cutout/audio/line009.visemes.json")
  let dur = Js.Array2.reduce(vs, (m, v) => v.to_ > m ? v.to_ : m, 0.0) +. 0.6
  let kukuState = t => {
    let base = stand(kukuRig, ~feetX=730.0, ~feetY=640.0, ~size=0.21, ~facingLeft=false, ())
    let emphasis = 2.5 *. talking(vs, t) *. Js.Math.sin(2.0 *. Js.Math._PI *. 1.1 *. secf(t))
    let breathe = 0.6 *. Js.Math.sin(2.0 *. Js.Math._PI *. 0.3 *. secf(t))
    {
      ...posedCanonical(base, [(head, turn(-9.0 +. emphasis +. breathe)), (tail, turn(3.0 *. Js.Math.sin(2.0 *. Js.Math._PI *. 0.25 *. secf(t))))]),
      mouth: mouthAt(vs, ~map=kukuMouth, t),
    }
  }
  let dadiState = t => {
    let base = stand(dadiRig, ~feetX=985.0, ~feetY=628.0, ~size=0.335, ())
    let listen = track([{at: Sec(1.2), v: 0.0}, {at: Sec(1.5), v: 3.0}, {at: Sec(2.0), v: 0.0}], t)
    let sway = 1.0 *. Js.Math.sin(2.0 *. Js.Math._PI *. 0.2 *. secf(t))
    posed(base, [(dHead, turn(-1.5 +. sway +. listen))])
  }
  let shadowOf = (fx, w) => (_t: sec) => {cx: Px(fx), cy: Px(646.0), rx: Px(w), ry: Px(14.0), a: Alpha(0.28)}
  let camera = t => {
    zoom: Scale(track([{at: Sec(0.0), v: 1.18}, {at: Sec(dur), v: 1.24}], ~ease=linear, t)),
    lookX: Px(track([{at: Sec(0.0), v: 718.0}, {at: Sec(dur), v: 730.0}], ~ease=linear, t)),
    lookY: Px(400.0),
  }
  let sh = {
    name: "kuku_line009",
    width: stageW,
    height: stageH,
    fps: fpsOut,
    duration: Sec(dur),
    layers: [
      plate,
      {...lamp, z: 21},
      glowLayer(~z=22, ~colour="rgba(255,186,96,1)", ~glow=lampGlow(~strength=0.30)),
      shadowLayer(~z=3, ~shadow=shadowOf(985.0, 95.0)),
      shadowLayer(~z=3, ~shadow=shadowOf(730.0, 70.0)),
      puppetLayer(~z=4, ~rig=dadi, ~state=dadiState),
      puppetLayer(~z=5, ~rig=kuku, ~state=kukuState),
    ],
    camera,
    audio: Some(root ++ "cutout/audio/line009.wav"),
    out: outDir ++ "proof_kuku_line009_puppet.mp4",
  }
  render(sh)
}

/* ------------------------------------ the exchange: lines 8, 9 and 10 */
/* The script's own beat: दादी explains the lamp (8), कुकु understands (9),
   दादी confirms (10). Three puppets, two of them speaking, one take each,
   the mouths on the visemes of the takes, the heads on the rhythm of speech. */
let talk3 = async () => {
  mkdirSync(outDir, {"recursive": true})
  let dadi = await loadRig(dadiRig)
  let kuku = await loadRig(kukuRig)
  let furia = await loadRig(furiaRig)
  let (plate, lamp) = await courtyard()
  let vs8 = visemes(root ++ "cutout/audio/line008.visemes.json")
  let vs9 = visemes(root ++ "cutout/audio/line009.visemes.json")
  let vs10 = visemes(root ++ "cutout/audio/line010.visemes.json")
  let t9 = 8.08 +. 0.35
  let t10 = t9 +. 2.32 +. 0.35
  let dur = t10 +. 3.6 +. 0.5
  let at = (t0, t) => Sec(secf(t) -. t0)
  let sway = (hz, amp, t) => amp *. Js.Math.sin(2.0 *. Js.Math._PI *. hz *. secf(t))
  let dadiState = t => {
    let base = stand(dadiRig, ~feetX=985.0, ~feetY=628.0, ~size=0.335, ())
    let talk8 = talking(vs8, t)
    let talk10 = talking(vs10, at(t10, t))
    let emphasis = 2.0 *. (talk8 +. talk10) *. Js.Math.sin(2.0 *. Js.Math._PI *. 0.9 *. secf(t))
    /* she tips toward कुकु as he answers */
    let lean = track([{at: Sec(t9 -. 0.2), v: 0.0}, {at: Sec(t9 +. 0.4), v: 3.0}, {at: Sec(t10), v: 0.0}], t)
    let mouth = secf(t) < t9 ? mouthAt(vs8, t) : secf(t) >= t10 ? mouthAt(vs10, at(t10, t)) : None
    {...posed(base, [(dHead, turn(-1.5 +. sway(0.22, 1.2, t) +. emphasis +. lean))]), mouth}
  }
  let kukuState = t => {
    let base = stand(kukuRig, ~feetX=750.0, ~feetY=640.0, ~size=0.21, ~facingLeft=false, ())
    let talk9 = talking(vs9, at(t9, t))
    let emphasis = 2.5 *. talk9 *. Js.Math.sin(2.0 *. Js.Math._PI *. 1.1 *. secf(t))
    let nod = track([{at: Sec(3.0), v: 0.0}, {at: Sec(3.25), v: 6.0}, {at: Sec(3.6), v: 0.0}, {at: Sec(6.4), v: 0.0}, {at: Sec(6.65), v: 6.0}, {at: Sec(7.0), v: 0.0}], t)
    let mouth = secf(t) >= t9 && secf(t) < t10 ? mouthAt(vs9, ~map=kukuMouth, at(t9, t)) : Some("closed")
    {
      ...posedCanonical(base, [(head, turn(-9.0 +. nod +. emphasis +. sway(0.3, 0.6, t))), (tail, turn(sway(0.25, 3.0, t)))]),
      mouth,
    }
  }
  let furiaState = t => {
    let base = stand(furiaRig, ~feetX=470.0, ~feetY=650.0, ~size=0.2, ~facingLeft=false, ())
    /* she listens: a look at कुकु when he speaks, a slow breath otherwise */
    let look = track([{at: Sec(t9 -. 0.1), v: 0.0}, {at: Sec(t9 +. 0.3), v: 4.0}, {at: Sec(t10 +. 0.5), v: 0.0}], t)
    posed(base, Js.Array2.concat(furiaCanonical, [(head, turn(-4.0 +. look +. sway(0.27, 0.8, t))), (tail, turn(sway(0.2, 2.5, t)))]))
  }
  let shadowOf = (fx, w, cy) => (_t: sec) => {cx: Px(fx), cy: Px(cy), rx: Px(w), ry: Px(14.0), a: Alpha(0.28)}
  let camera = t => {
    zoom: Scale(track([{at: Sec(0.0), v: 1.08}, {at: Sec(dur), v: 1.16}], ~ease=linear, t)),
    lookX: Px(track([{at: Sec(0.0), v: 690.0}, {at: Sec(dur), v: 700.0}], ~ease=linear, t)),
    lookY: Px(track([{at: Sec(0.0), v: 380.0}, {at: Sec(dur), v: 395.0}], ~ease=linear, t)),
  }
  let sh = {
    name: "lines_008_010",
    width: stageW,
    height: stageH,
    fps: fpsOut,
    duration: Sec(dur),
    layers: [
      plate,
      {...lamp, z: 21},
      glowLayer(~z=22, ~colour="rgba(255,186,96,1)", ~glow=lampGlow(~strength=0.30)),
      shadowLayer(~z=3, ~shadow=shadowOf(985.0, 95.0, 646.0)),
      shadowLayer(~z=3, ~shadow=shadowOf(750.0, 70.0, 646.0)),
      shadowLayer(~z=3, ~shadow=shadowOf(470.0, 70.0, 656.0)),
      puppetLayer(~z=4, ~rig=dadi, ~state=dadiState),
      puppetLayer(~z=5, ~rig=furia, ~state=furiaState),
      puppetLayer(~z=6, ~rig=kuku, ~state=kukuState),
    ],
    camera,
    audio: Some(root ++ "cutout/audio/lines008_010.wav"),
    out: outDir ++ "proof_lines_008_010.mp4",
  }
  render(sh)
  contactSheet(~video=sh.out, ~out=outDir ++ "proof_lines_008_010_sheet.png", ~cols=6, ~rows=2, ~everySec=1.25)
}

/* ------------------------------------------------------- the lineup */
/* the whole company at rest in the courtyard, one frame: the look test */
let lineup = async () => {
  mkdirSync(outDir, {"recursive": true})
  let (plate, lamp) = await courtyard()
  let kalu = await loadRig(kaluRig)
  let castor = await loadRig(castorRig)
  let leda = await loadRig(ledaRig)
  let kuku = await loadRig(kukuRig)
  let furia = await loadRig(furiaRig)
  let vesper = await loadRig(vesperRig)
  let dadi = await loadRig(dadiRig)
  let papa = await loadRig(papaRig)
  let child = (rig, spec, can, fx, left) => puppetLayer(~z=5, ~rig, ~state=_t => posed(stand(spec, ~feetX=fx, ~feetY=655.0, ~size=0.21, ~facingLeft=left, ()), can))
  let sh = {
    name: "lineup",
    width: stageW,
    height: stageH,
    fps: fpsOut,
    duration: Sec(1.0),
    layers: [
      plate,
      {...lamp, z: 21},
      puppetLayer(~z=4, ~rig=papa, ~state=_t => posed(stand(papaRig, ~feetX=1195.0, ~feetY=662.0, ~size=0.4, ()), papaCanonical)),
      puppetLayer(~z=4, ~rig=dadi, ~state=_t => stand(dadiRig, ~feetX=1040.0, ~feetY=640.0, ~size=0.32, ())),
      child(castor, castorRig, castorCanonical, 330.0, false),
      child(leda, ledaRig, ledaCanonical, 470.0, false),
      child(kuku, kukuRig, canonical, 610.0, false),
      child(furia, furiaRig, furiaCanonical, 760.0, true),
      child(vesper, vesperRig, vesperCanonical, 900.0, true),
      puppetLayer(~z=6, ~rig=kalu, ~state=_t => stand(kaluRig, ~feetX=200.0, ~feetY=660.0, ~size=0.13, ~facingLeft=false, ())),
    ],
    camera: _t => wholeStage(1280.0, 720.0),
    audio: None,
    out: "",
  }
  frame(sh, Sec(0.0), outDir ++ "cast_lineup.png")
  Js.log("wrote cast_lineup.png")
}

let lights = async () => {
  mkdirSync(outDir, {"recursive": true})
  let dadi = await loadRig(dadiRig)
  let kuku = await loadRig(kukuRig)
  let (plate, lamp) = await courtyard()
  let dadiState = _t => stand(dadiRig, ~feetX=985.0, ~feetY=628.0, ~size=0.335, ())
  let kukuState = _t => posedCanonical(stand(kukuRig, ~feetX=730.0, ~feetY=640.0, ~size=0.21, ~facingLeft=false, ()), [(head, turn(-9.0))])
  Js.Array2.forEach([Dusk, LampNight, Dark, Golden], l => {
    let sh = {
      name: "light_" ++ lightName(l),
      width: stageW,
      height: stageH,
      fps: fpsOut,
      duration: Sec(1.0),
      layers: Js.Array2.concat(
        Js.Array2.concat([plate], lightLayers(l, ~lamp)),
        [puppetLayer(~z=4, ~rig=dadi, ~state=dadiState), puppetLayer(~z=5, ~rig=kuku, ~state=kukuState)],
      ),
      camera: _t => wholeStage(1280.0, 720.0),
      audio: None,
      out: "",
    }
    frame(sh, Sec(0.0), outDir ++ "light_" ++ lightName(l) ++ ".png")
  })
  Js.log("wrote the four light states in " ++ outDir)
}

let () =
  switch Belt.Array.get(argv, 2) {
  | Some("cut") => {
      ignore(cut(kukuRig))
      ignore(cut(dadiRig))
      ignore(cut(furiaRig))
      ignore(cut(ledaRig))
      ignore(cut(castorRig))
      ignore(cut(vesperRig))
      ignore(cut(papaRig))
      ignore(cut(kaluRig))
      ignore(cut(kukuGreatRig))
      ignore(cut(kaluAsleepRig))
    }
  | Some("checkfuria") => ignore(checkRig(furiaRig, "furia"))
  | Some("checkleda") => ignore(checkRig(ledaRig, "leda"))
  | Some("checkcastor") => ignore(checkRig(castorRig, "castor"))
  | Some("checkvesper") => ignore(checkRig(vesperRig, "vesper"))
  | Some("checkpapa") => ignore(checkRig(papaRig, "papa"))
  | Some("lineup") => ignore(lineup())
  | Some("stagetest") => ignore(stageTest())
  | Some("checkkalu") => ignore(checkRig(kaluRig, "kalu"))
  | Some("talk") => ignore(talk())
  | Some("talkkuku") => ignore(talkKuku())
  | Some("talk3") => ignore(talk3())
  | Some("lights") => ignore(lights())
  | Some("check") => ignore(check())
  | Some("run") => ignore(runIn())
  | Some("fly") => ignore(flyGreat())
  | Some("checkkukugreat") => ignore(checkRig(kukuGreatRig, "kuku_great"))
  | _ => Js.log("usage: cut | check | run | talk | lights | fly")
  }
