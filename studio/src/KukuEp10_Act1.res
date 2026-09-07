// KukuEp10_Act1.res — «द से दीया» Act 1, the ordinary world: script shots ०१–१४
// as four continuous scenes on the puppet stage. This is the template every
// later scene follows: marks carried as values, every line on its own take,
// the camera as cuts between a master and singles, the light graded in code.

open Puppet
open KukuEp10_Rigs
open KukuEp10_Stage

/* ------------------------------------------------------------- marks */
/* Where everyone stands or sits for the whole act. Scene 2 brings them here;
   scenes 3 and 4 inherit these values, so continuity is a fact, not a hope. */
let dadiAtNiche = {x: 760.0, y: 626.0, facingLeft: true}
let vesperMark = {x: 410.0, y: 650.0, facingLeft: false}
let castorMark = {x: 515.0, y: 668.0, facingLeft: false}
let ledaMark = {x: 600.0, y: 700.0, facingLeft: false}
let kukuMark = {x: 700.0, y: 705.0, facingLeft: false}
let furiaMark = {x: 900.0, y: 700.0, facingLeft: true}
let kaluMark = {x: 1010.0, y: 662.0, facingLeft: true}
let offRight = {x: 1360.0, y: 660.0, facingLeft: true}
let behindDoor = {x: 150.0, y: 632.0, facingLeft: false}
let atDoor = {x: 330.0, y: 640.0, facingLeft: true}

/* z: plate 0, bowl 1, beyond-wall 2-3, wall mask 4, behind-door 5-6, door mask 7,
   courtyard actors 8-12 front-most highest, paper bits 13, tints 20, light 21+ */
let zOf = (m: mark) => 8 + Belt.Float.toInt((m.y -. 620.0) /. 25.0)

/* SEATED: the legs fold and the body comes down over `settle` seconds from
   `at`; before that the actor stands. A blend, so nobody pops into a sit. */
let seated = (a: actor, m: mark, cues, ~at, ~settle=0.5, ~headTurn: sec => float=_ => 0.0, t) => {
  let u = Js.Math.min_float(1.0, Js.Math.max_float(0.0, (secf(t) -. at) /. settle))
  let drop = 26.0 *. a.size /. 0.21 *. u
  standingActor(a, {...m, y: m.y +. drop}, cues, ~extra=_ => [(legNear, turn(52.0 *. u)), (legFar, turn(-48.0 *. u))], ~headTurn, t)
}

/* THE CAMERA AS CUTS: a master until the first line; at each line a single on
   its speaker, every third line back to the master; the master again after
   the last line. A single is a push toward the speaker's head, clamped to
   the plate. */
let clampLook = (zoom, x, y) => {
  let hw = 640.0 /. zoom
  let hh = 360.0 /. zoom
  (Js.Math.max_float(hw, Js.Math.min_float(1280.0 -. hw, x)), Js.Math.max_float(hh, Js.Math.min_float(720.0 -. hh, y)))
}
let single = (m: mark, ~size, ~zoom=1.35) => {
  let headY = m.y -. 1100.0 *. size *. depthScale(m.y)
  let (lx, ly) = clampLook(zoom, m.x, headY +. 60.0)
  {zoom: Scale(zoom), lookX: Px(lx), lookY: Px(ly)}
}
let cameraCuts = (~master: camera, ~cues: array<cue>, ~singleOf: cue => camera, ~masterEvery=3) => (t: sec) => {
  let tv = secf(t)
  let live = Js.Array2.reducei(cues, (acc, c, i) => tv >= c.at ? Some((c, i)) : acc, None)
  switch live {
  | None => master
  | Some((c, i)) =>
    tv > c.at +. takeOf(c.line).secs +. 0.25
      ? master
      : mod(i, masterEvery) == masterEvery - 1
      ? master
      : singleOf(c)
  }
}
let masterCam = {zoom: Scale(1.06), lookX: Px(660.0), lookY: Px(372.0)}

/* a speaker's mark and size, for the singles */
let markOf = who =>
  switch who {
  | "dadi" => (dadiAtNiche, 0.335)
  | "vesper" => (vesperMark, 0.21)
  | "castor" => (castorMark, 0.21)
  | "leda" => (ledaMark, 0.21)
  | "kuku" => (kukuMark, 0.21)
  | _ => (furiaMark, 0.21)
  }
let singleOfCue = (c: cue) => {
  let (m, size) = markOf(actorKeyOf(takeOf(c.line).who))
  single(m, ~size)
}

/* the common stage: plate, wall mask, door mask */
let stageBase = async () => {
  let plate = await plateLayer(~path=ImagePath(root ++ "sets/courtyard_plate.png"), ~w=Px(1280.0), ~h=Px(720.0))
  let wall = await wallMask(4)
  let door = await doorMask(7)
  [plate, wall, door]
}
let nightAt = (from, to_) => fadingTint(~z=20, ~colour=nightTint, ~strength=t => track([{at: Sec(from), v: 0.0}, {at: Sec(to_), v: 1.0}], t))
let nightFull = fadingTint(~z=20, ~colour=nightTint, ~strength=_ => 1.0)

/* ==================================================== scene 1: शॉट ०१–०२ */
/* दादी comes in past the door with the lamp in her hands, walks to the niche,
   sets it down; the flame catches and the courtyard warms into lamp-night. */
let scene1 = async () => {
  let dadi = await actor("dadi")
  let base = await stageBase()
  let cues = [{line: 1, at: 1.6}, {line: 2, at: 10.8}]
  let arrive = 5.6
  let setDown = (5.9, 6.7)
  let lit = 8.2
  /* she walks in facing right, sets the lamp down, then turns to it for «जल गया» */
  let dadiState = t =>
    secf(t) < 7.0
      ? walkingActor(dadi, ~from=behindDoor, ~to_={...dadiAtNiche, facingLeft: false}, ~t0=0.8, ~t1=arrive, cues, t)
      : standingActor(dadi, dadiAtNiche, cues, ~headTurn=t => track([{at: Sec(8.0), v: 0.0}, {at: Sec(8.6), v: 6.0}, {at: Sec(10.5), v: 6.0}, {at: Sec(11.2), v: 0.0}], t), t)
  /* the bowl rides at her chest until she sets it on the shelf */
  let bowlAt = t => {
    let st = dadiState(t)
    let hand = (pxf(st.x) -. 10.0, pxf(st.y) -. 300.0 *. scalef(st.size) /. 0.335)
    let (a, b) = setDown
    let tv = secf(t)
    if tv < a {
      hand
    } else if tv > b {
      shelfBowl
    } else {
      let u = easeInOut((tv -. a) /. (b -. a))
      let (hx, hy) = hand
      let (sx, sy) = shelfBowl
      (hx +. (sx -. hx) *. u, hy +. (sy -. hy) *. u)
    }
  }
  let bowl = await bowlLayer(~at=bowlAt, 9)
  let flame = t => {
    let catch_ = track([{at: Sec(lit), v: 0.0}, {at: Sec(lit +. 0.9), v: 1.0}], t)
    let f = flicker(flameLit, t)
    {...f, height: f.height *. catch_, lean: f.lean +. 0.35 *. track([{at: Sec(lit), v: 1.0}, {at: Sec(lit +. 1.6), v: 0.0}], t), glowStrength: f.glowStrength *. catch_}
  }
  let sc = {
    name: "s01_lamp",
    duration: 15.0,
    layers: Js.Array2.concatMany(base, [
      [bowl],
      actorLayers(~z=6, dadi, dadiState),
      [nightAt(lit +. 0.3, lit +. 3.0), flameLayer(~z=21, ~flame, ~base=t => flameBaseOf(bowlAt(t)))],
    ]),
    camera: t => {
      let z = track([{at: Sec(6.0), v: 1.06}, {at: Sec(12.0), v: 1.22}], t)
      let (lx, ly) = clampLook(z, track([{at: Sec(6.0), v: 660.0}, {at: Sec(12.0), v: 700.0}], t), track([{at: Sec(6.0), v: 372.0}, {at: Sec(12.0), v: 390.0}], t))
      {zoom: Scale(z), lookX: Px(lx), lookY: Px(ly)}
    },
    cues,
  }
  sc
}

/* ==================================================== scene 2: शॉट ०३–०९ */
/* The five run in one after another and settle in a half circle at the lamp,
   कालू trots in and curls up, and the lamp talk plays as master and singles. */
let scene2 = async () => {
  let dadi = await actor("dadi")
  let vesper = await actor("vesper")
  let castor = await actor("castor")
  let leda = await actor("leda")
  let kuku = await actor("kuku")
  let furia = await actor("furia")
  let kalu = await actor("kalu")
  let sleeper = await actor("kalu_asleep")
  let base = await stageBase()
  let bowl = await bowlLayer(1)
  let cues = sequence(~from=6.4, ~gap=0.4, [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14])
  /* arrivals: who, mark, start, arrive */
  let runIn = (a, m: mark, t0, t1, t) =>
    secf(t) < t1 +. 0.2
      ? walkingActor(a, ~from=offRight, ~to_={...m, facingLeft: m.facingLeft}, ~t0, ~t1, cues, t)
      : seated(a, m, cues, ~at=t1 +. 0.2, t)
  let vesperState = t => runIn(vesper, vesperMark, 0.3, 3.1, t)
  let castorState = t => runIn(castor, castorMark, 0.8, 3.4, t)
  let ledaState = t => runIn(leda, ledaMark, 1.3, 3.7, t)
  let kukuState = t => runIn(kuku, kukuMark, 1.8, 4.0, t)
  let furiaState = t => runIn(furia, furiaMark, 2.3, 4.2, t)
  /* कालू trots in behind them and is asleep by the time the talk begins */
  let kaluState = t => {
    let st = walkingActor(kalu, ~from={...offRight, y: 662.0}, ~to_=kaluMark, ~t0=2.8, ~t1=4.6, cues, t)
    {...st, opacity: Alpha(secf(t) < 4.9 ? 1.0 : 0.0)}
  }
  let sleeperState = t => {
    let st = stand(sleeper.spec, ~feetX=kaluMark.x, ~feetY=kaluMark.y +. 30.0, ~size=0.13, ~facingLeft=false, ())
    {
      ...posed(st, [(dCurl, {angle: Deg(0.0), dx: Px(0.0), dy: Px(0.0), s: Scale(1.0 +. 0.012 *. Js.Math.sin(2.0 *. Js.Math._PI *. 0.3 *. secf(t)))})]),
      opacity: Alpha(secf(t) < 4.9 ? 0.0 : 1.0),
    }
  }
  /* दादी listens, and turns toward whoever speaks */
  let dadiState = t => standingActor(dadi, dadiAtNiche, cues, ~headTurn=t => 1.5 *. talkingFor(dadi, cues, t), t)
  let sc = {
    name: "s02_lamp_talk",
    duration: endOf(cues) +. 1.2,
    layers: Js.Array2.concatMany(base, [
      [bowl],
      actorLayers(~z=zOf(dadiAtNiche), dadi, dadiState),
      actorLayers(~z=zOf(vesperMark), vesper, vesperState),
      actorLayers(~z=zOf(castorMark), castor, castorState),
      actorLayers(~z=zOf(ledaMark), leda, ledaState),
      actorLayers(~z=zOf(kukuMark), kuku, kukuState),
      actorLayers(~z=zOf(furiaMark), furia, furiaState),
      actorLayers(~z=zOf(kaluMark), kalu, kaluState),
      actorLayers(~z=zOf(kaluMark), sleeper, sleeperState),
      [nightFull, flameLayer(~z=21, ~flame=t => flicker(flameLit, t))],
    ]),
    camera: cameraCuts(~master=masterCam, ~cues, ~singleOf=singleOfCue),
    cues,
  }
  sc
}

/* ==================================================== scene 3: शॉट १०–११ */
/* The first gust from the valley: the flame lies flat and struggles up, paper
   bits cross the flagstones; वैस्पर looks to the valley, फ्यूरिया shrugs it off. */
let scene3 = async () => {
  let dadi = await actor("dadi")
  let vesper = await actor("vesper")
  let castor = await actor("castor")
  let leda = await actor("leda")
  let kuku = await actor("kuku")
  let furia = await actor("furia")
  let sleeper = await actor("kalu_asleep")
  let base = await stageBase()
  let bowl = await bowlLayer(1)
  let gusts = [{at: 0.8, len: 2.8, strength: 0.85}]
  let cues = [{line: 15, at: 4.6}, {line: 16, at: 9.2}]
  let sit = (a, m, ~headTurn=_ => 0.0) => t => seated(a, m, cues, ~at=-1.0, ~headTurn, t)
  let sc = {
    name: "s03_first_gust",
    duration: endOf(cues) +. 1.0,
    layers: Js.Array2.concatMany(base, [
      [bowl],
      actorLayers(~z=zOf(dadiAtNiche), dadi, t => standingActor(dadi, dadiAtNiche, cues, ~headTurn=t => -6.0 *. windAt(gusts, t), t)),
      actorLayers(~z=zOf(vesperMark), vesper, sit(vesper, vesperMark, ~headTurn=t => track([{at: Sec(3.8), v: 0.0}, {at: Sec(4.4), v: -14.0}, {at: Sec(8.6), v: -14.0}, {at: Sec(9.2), v: 0.0}], t))),
      actorLayers(~z=zOf(castorMark), castor, sit(castor, castorMark)),
      actorLayers(~z=zOf(ledaMark), leda, sit(leda, ledaMark)),
      actorLayers(~z=zOf(kukuMark), kuku, sit(kuku, kukuMark, ~headTurn=t => -5.0 *. windAt(gusts, t))),
      actorLayers(~z=zOf(furiaMark), furia, sit(furia, furiaMark)),
      actorLayers(~z=zOf(kaluMark), sleeper, t => {
        let st = stand(sleeper.spec, ~feetX=kaluMark.x, ~feetY=kaluMark.y +. 30.0, ~size=0.13, ~facingLeft=false, ())
        posed(st, [(dCurl, {angle: Deg(0.0), dx: Px(0.0), dy: Px(0.0), s: Scale(1.0 +. 0.012 *. Js.Math.sin(2.0 *. Js.Math._PI *. 0.3 *. secf(t)))})])
      }),
      [windBitsLayer(~z=13, ~gusts), nightFull, flameLayer(~z=21, ~flame=t => flameInWind(gusts, t))],
    ]),
    camera: t => secf(t) < 4.4 ? {zoom: Scale(1.3), lookX: Px(640.0), lookY: Px(385.0)} : cameraCuts(~master=masterCam, ~cues, ~singleOf=singleOfCue)(t),
    cues,
  }
  sc
}

/* ==================================================== scene 4: शॉट १२–१४ */
/* दादी gives the children the lamp, crosses to the door, turns for her last
   warning, कुकु answers, and she goes in. Five children and one small flame. */
let scene4 = async () => {
  let dadi = await actor("dadi")
  let vesper = await actor("vesper")
  let castor = await actor("castor")
  let leda = await actor("leda")
  let kuku = await actor("kuku")
  let furia = await actor("furia")
  let sleeper = await actor("kalu_asleep")
  let base = await stageBase()
  let bowl = await bowlLayer(1)
  let cues = [{line: 17, at: 0.6}, {line: 18, at: 6.2}, {line: 19, at: 10.2}, {line: 20, at: 16.6}]
  let walkOut = (5.6, 9.6)
  let exit = (18.6, 21.0)
  let dadiState = t => {
    let tv = secf(t)
    let (w0, w1) = walkOut
    let (e0, e1) = exit
    if tv < w0 {
      standingActor(dadi, dadiAtNiche, cues, t)
    } else if tv < w1 +. 0.2 {
      walkingActor(dadi, ~from=dadiAtNiche, ~to_=atDoor, ~t0=w0, ~t1=w1, cues, t)
    } else if tv < e0 {
      standingActor(dadi, {...atDoor, facingLeft: false}, cues, t)
    } else {
      walkingActor(dadi, ~from=atDoor, ~to_=behindDoor, ~t0=e0, ~t1=e1, cues, t)
    }
  }
  let sit = (a, m, ~headTurn=_ => 0.0) => t => seated(a, m, cues, ~at=-1.0, ~headTurn, t)
  /* the children follow her with their heads as she crosses */
  let follow = (m: mark) => t => {
    let st = dadiState(t)
    let dx = pxf(st.x) -. m.x
    (m.facingLeft ? -1.0 : 1.0) *. Js.Math.max_float(-10.0, Js.Math.min_float(10.0, -.dx /. 60.0))
  }
  let sc = {
    name: "s04_dadi_goes_in",
    duration: 24.5,
    layers: Js.Array2.concatMany(base, [
      [bowl],
      actorLayers(~z=6, dadi, dadiState),
      actorLayers(~z=zOf(vesperMark), vesper, sit(vesper, vesperMark, ~headTurn=follow(vesperMark))),
      actorLayers(~z=zOf(castorMark), castor, sit(castor, castorMark, ~headTurn=follow(castorMark))),
      actorLayers(~z=zOf(ledaMark), leda, sit(leda, ledaMark, ~headTurn=follow(ledaMark))),
      actorLayers(~z=zOf(kukuMark), kuku, sit(kuku, kukuMark, ~headTurn=follow(kukuMark))),
      actorLayers(~z=zOf(furiaMark), furia, sit(furia, furiaMark, ~headTurn=follow(furiaMark))),
      actorLayers(~z=zOf(kaluMark), sleeper, t => {
        let st = stand(sleeper.spec, ~feetX=kaluMark.x, ~feetY=kaluMark.y +. 30.0, ~size=0.13, ~facingLeft=false, ())
        posed(st, [(dCurl, {angle: Deg(0.0), dx: Px(0.0), dy: Px(0.0), s: Scale(1.0 +. 0.012 *. Js.Math.sin(2.0 *. Js.Math._PI *. 0.3 *. secf(t)))})])
      }),
      [nightFull, flameLayer(~z=21, ~flame=t => flicker(flameLit, t))],
    ]),
    camera: t => {
      let tv = secf(t)
      /* her line at the door is a single on her there; the end is a slow push on the five and the flame */
      if tv >= 10.0 && tv < 16.4 {
        single({...atDoor, facingLeft: false}, ~size=0.335, ~zoom=1.3)
      } else if tv >= 21.0 {
        pushIn(~from=1.06, ~to_=1.18, ~lookX=680.0, ~lookY=400.0, ~over=3.5)(Sec(tv -. 21.0))
      } else {
        cameraCuts(~master=masterCam, ~cues=[{line: 17, at: 0.6}, {line: 18, at: 6.2}, {line: 20, at: 16.6}], ~singleOf=singleOfCue, ~masterEvery=2)(t)
      }
    },
    cues,
  }
  sc
}

let scenes = [("s01_lamp", scene1), ("s02_lamp_talk", scene2), ("s03_first_gust", scene3), ("s04_dadi_goes_in", scene4)]
