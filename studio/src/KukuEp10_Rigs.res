// KukuEp10_Rigs.res — every puppet of EP10 and the stage constants they stand on.
//
// No main here: scene modules open this. Each character was generated ONCE as a
// spread-pose sprite on a sheet in a colour it does not wear, keyed by a rule
// and passed on a number, and cut into hinged parts along the polygons below.
// From here on a character moves only by numbers.

@module("process") external cwd: unit => string = "cwd"

open Puppet

let root = cwd() ++ "/../stories/kuku/ep10/"
let outDir = root ++ "cutout/out/"

/* ------------------------------------------------------------ कुकु's rig */
/* Sprite space is the raw generation, 2752x1536, कुकु facing LEFT. Polygons
   are loose wherever they border transparent sheet and careful only where
   parts meet: a part must never copy a neighbour's pixels, or the copy moves
   with it as a ghost. Pivots sit on the joints. Drawing order, back to front:
   far wing, tail, far leg, near wing, torso, far arm, near leg, near arm, head.
   The far arm is drawn in front of the torso although it is on the far side:
   hanging behind the body it would vanish, and the character sheet shows both
   hands. Its shoulder has a paper joint like the near arm's. */
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

/* AN ARM ENDS IN A HALF-DISC at the shoulder, cut inside the arm's own pixels,
   and hinges on that disc's centre: it turns in place like a ball in a socket,
   so no straight cut ever shows and nothing is drawn over the picture. cut is
   where the arm meets the torso; the disc bulges toward the torso. */
let armEnd = (~cut, ~yTop, ~yBot, ~tip, ~towardTorso) => {
  let r = (yBot -. yTop) /. 2.0
  let cy = (yTop +. yBot) /. 2.0
  let px = cut -. towardTorso *. r
  let arc = Belt.Array.makeBy(9, i => {
    let a = -.Js.Math._PI /. 2.0 +. Belt.Int.toFloat(i) *. Js.Math._PI /. 8.0
    p(px +. towardTorso *. r *. Js.Math.cos(a), cy +. r *. Js.Math.sin(a))
  })
  let tipSide = tip < cut ? -1.0 : 1.0
  (p(px, cy), Js.Array2.concat(arc, [p(tip, yBot), p(tip +. tipSide *. 25.0, cy), p(tip, yTop)]))
}

let (kArmNPivot, kArmNOutline) = armEnd(~cut=1168.0, ~yTop=762.0, ~yBot=908.0, ~tip=760.0, ~towardTorso=1.0)
let (kArmFPivot, kArmFOutline) = armEnd(~cut=1395.0, ~yTop=768.0, ~yBot=912.0, ~tip=1850.0, ~towardTorso=-1.0)
let kukuRig: rigSpec<small> = {
  sprite: ImagePath(root ++ "cutout/sprites/kuku_spread.png"),
  partsDir: root ++ "cutout/parts/kuku/",
  patches: [
    {patch: "closed", image: ImagePath(root ++ "cutout/sprites/kuku_mouth_closed.png"), parent: head, at: p(960.0, 540.0)},
    {patch: "open", image: ImagePath(root ++ "cutout/sprites/kuku_mouth_open.png"), parent: head, at: p(960.0, 540.0)},
    {patch: "round", image: ImagePath(root ++ "cutout/sprites/kuku_mouth_round.png"), parent: head, at: p(960.0, 540.0)},
    {patch: "half", image: ImagePath(root ++ "cutout/sprites/kuku_mouth_half.png"), parent: head, at: p(960.0, 540.0)},
  ],
  feet: p(1140.0, 1420.0),
  parts: [
    {
      name: torso,
      parent: None,
      pivot: p(1320.0, 980.0),
      z: 5,
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
      z: 4,
      outline: [p(1120.0, 190.0), p(1030.0, 300.0), p(1010.0, 470.0), p(1000.0, 590.0), p(1085.0, 665.0), p(1190.0, 690.0), p(1198.0, 800.0), p(950.0, 800.0), p(850.0, 785.0), p(640.0, 520.0), p(470.0, 240.0), p(500.0, 150.0), p(900.0, 130.0)],
    },
    {
      name: wingFar,
      parent: Some(torso),
      pivot: p(1420.0, 700.0),
      z: 1,
      outline: [p(1372.0, 700.0), p(1425.0, 765.0), p(1800.0, 768.0), p(2000.0, 700.0), p(2280.0, 560.0), p(2260.0, 150.0), p(1500.0, 150.0), p(1520.0, 560.0), p(1400.0, 640.0)],
    },
    {name: armNear, parent: Some(torso), pivot: kArmNPivot, z: 8, outline: kArmNOutline},
    {name: armFar, parent: Some(torso), pivot: kArmFPivot, z: 6, outline: kArmFOutline},
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
      z: 2,
      outline: [p(1560.0, 935.0), p(2430.0, 950.0), p(2440.0, 1130.0), p(2000.0, 1268.0), p(1665.0, 1262.0), p(1662.0, 1160.0), p(1642.0, 1062.0), p(1470.0, 1040.0), p(1540.0, 1000.0)],
    },
  ],
}

/* ------------------------------------------------------------ दादी's rig */
/* Her sprite is the standing pose on green (1706x1536 after the crop that
   removed the leaked wall), facing LEFT. Two parts — head with neck, and
   everything else — are enough for dialogue: the head nods on its neck, and
   her mouth shapes are the registered patches already cut for the first proof. */
let dHead = PartName("head")
let dBody = PartName("body")
let dadiRig: rigSpec<small> = {
  sprite: ImagePath(root ++ "cutout/sprites/dadi_stand.png"),
  partsDir: root ++ "cutout/parts/dadi/",
  feet: p(860.0, 1380.0),
  parts: [
    {
      name: dBody,
      parent: None,
      pivot: p(900.0, 1000.0),
      z: 1,
      outline: [p(600.0, 660.0), p(960.0, 660.0), p(965.0, 560.0), p(990.0, 300.0), p(1460.0, 270.0), p(1706.0, 600.0), p(1706.0, 1450.0), p(540.0, 1450.0), p(560.0, 760.0)],
    },
    {
      name: dHead,
      parent: Some(dBody),
      pivot: p(800.0, 640.0),
      z: 2,
      outline: [p(460.0, 380.0), p(480.0, 290.0), p(560.0, 170.0), p(700.0, 140.0), p(830.0, 120.0), p(930.0, 160.0), p(965.0, 260.0), p(950.0, 420.0), p(962.0, 660.0), p(660.0, 665.0), p(590.0, 560.0), p(455.0, 500.0)],
    },
  ],
  patches: [
    {patch: "half", image: ImagePath(root ++ "cutout/sprites/mouth_half.png"), parent: dHead, at: p(477.0, 435.0)},
    {patch: "open", image: ImagePath(root ++ "cutout/sprites/mouth_open.png"), parent: dHead, at: p(477.0, 435.0)},
    {patch: "round", image: ImagePath(root ++ "cutout/sprites/mouth_round.png"), parent: dHead, at: p(477.0, 435.0)},
  ],
}

/* ---------------------------------------------------------- फ्यूरिया's rig */
/* Her sheet sprite: 2752x1536, facing LEFT, wings spread, arms out, the कड़ा
   on the far forearm. Same part names as कुकु's rig so the same shots and the
   same canonical-pose logic apply; her own rest angles below. */
let (fuArmNPivot, fuArmNOutline) = armEnd(~cut=1190.0, ~yTop=618.0, ~yBot=715.0, ~tip=790.0, ~towardTorso=1.0)
let (fuArmFPivot, fuArmFOutline) = armEnd(~cut=1400.0, ~yTop=660.0, ~yBot=800.0, ~tip=1850.0, ~towardTorso=-1.0)
let furiaRig: rigSpec<small> = {
  sprite: ImagePath(root ++ "cutout/sprites/furia_spread.png"),
  partsDir: root ++ "cutout/parts/furia/",
  feet: p(1300.0, 1420.0),
  patches: [
    {patch: "open", image: ImagePath(root ++ "cutout/sprites/furia_mouth_open.png"), parent: head, at: p(1040.0, 430.0)},
    {patch: "round", image: ImagePath(root ++ "cutout/sprites/furia_mouth_round.png"), parent: head, at: p(1040.0, 430.0)},
    {patch: "half", image: ImagePath(root ++ "cutout/sprites/furia_mouth_half.png"), parent: head, at: p(1040.0, 430.0)},
  ],
  parts: [
    {
      name: torso,
      parent: None,
      pivot: p(1330.0, 900.0),
      z: 5,
      outline: [p(1190.0, 560.0), p(1300.0, 530.0), p(1400.0, 560.0), p(1470.0, 700.0), p(1520.0, 940.0), p(1460.0, 1010.0), p(1440.0, 1130.0), p(1240.0, 1130.0), p(1150.0, 1000.0), p(1120.0, 800.0), p(1150.0, 700.0), p(1188.0, 640.0)],
    },
    {
      name: head,
      parent: Some(torso),
      pivot: p(1290.0, 620.0),
      z: 9,
      outline: [p(1060.0, 470.0), p(1090.0, 380.0), p(1160.0, 230.0), p(1260.0, 170.0), p(1400.0, 160.0), p(1520.0, 190.0), p(1560.0, 330.0), p(1520.0, 480.0), p(1420.0, 560.0), p(1400.0, 650.0), p(1200.0, 660.0), p(1150.0, 560.0), p(1080.0, 520.0)],
    },
    {
      name: wingNear,
      parent: Some(torso),
      pivot: p(1200.0, 600.0),
      z: 4,
      outline: [p(1160.0, 230.0), p(1090.0, 380.0), p(1060.0, 470.0), p(1150.0, 560.0), p(1200.0, 640.0), p(1190.0, 700.0), p(840.0, 640.0), p(700.0, 640.0), p(480.0, 300.0), p(470.0, 100.0), p(1000.0, 90.0)],
    },
    {
      name: wingFar,
      parent: Some(torso),
      pivot: p(1440.0, 600.0),
      z: 1,
      outline: [p(1400.0, 560.0), p(1470.0, 700.0), p(1460.0, 760.0), p(1900.0, 780.0), p(2450.0, 860.0), p(2460.0, 160.0), p(1560.0, 150.0), p(1540.0, 400.0)],
    },
    {name: armNear, parent: Some(torso), pivot: fuArmNPivot, z: 8, outline: fuArmNOutline},
    {name: armFar, parent: Some(torso), pivot: fuArmFPivot, z: 6, outline: fuArmFOutline},
    {
      name: legNear,
      parent: Some(torso),
      pivot: p(1190.0, 1050.0),
      z: 7,
      outline: [p(1120.0, 990.0), p(1250.0, 1000.0), p(1290.0, 1130.0), p(1280.0, 1300.0), p(1310.0, 1420.0), p(1000.0, 1420.0), p(1020.0, 1330.0), p(1090.0, 1300.0), p(1060.0, 1120.0)],
    },
    {
      name: legFar,
      parent: Some(torso),
      pivot: p(1480.0, 1040.0),
      z: 3,
      outline: [p(1440.0, 1000.0), p(1560.0, 960.0), p(1600.0, 1100.0), p(1590.0, 1380.0), p(1620.0, 1470.0), p(1340.0, 1470.0), p(1350.0, 1380.0), p(1400.0, 1300.0), p(1400.0, 1130.0)],
    },
    {
      name: tail,
      parent: Some(torso),
      pivot: p(1540.0, 1000.0),
      z: 2,
      outline: [p(1520.0, 940.0), p(1600.0, 900.0), p(1960.0, 820.0), p(1980.0, 900.0), p(1700.0, 1060.0), p(1600.0, 1100.0), p(1560.0, 1040.0)],
    },
  ],
}

/* ------------------------------------------------------------ लेडा's rig */
let (leArmNPivot, leArmNOutline) = armEnd(~cut=1192.0, ~yTop=768.0, ~yBot=875.0, ~tip=790.0, ~towardTorso=1.0)
let (leArmFPivot, leArmFOutline) = armEnd(~cut=1395.0, ~yTop=795.0, ~yBot=905.0, ~tip=1850.0, ~towardTorso=-1.0)
let ledaRig: rigSpec<small> = {
  sprite: ImagePath(root ++ "cutout/sprites/leda_spread.png"),
  partsDir: root ++ "cutout/parts/leda/",
  feet: p(1360.0, 1440.0),
  patches: [
    {patch: "open", image: ImagePath(root ++ "cutout/sprites/leda_mouth_open.png"), parent: head, at: p(1050.0, 480.0)},
    {patch: "round", image: ImagePath(root ++ "cutout/sprites/leda_mouth_round.png"), parent: head, at: p(1050.0, 480.0)},
    {patch: "half", image: ImagePath(root ++ "cutout/sprites/leda_mouth_half.png"), parent: head, at: p(1050.0, 480.0)},
  ],
  parts: [
    {name: torso, parent: None, pivot: p(1340.0, 930.0), z: 5,
      outline: [p(1190.0, 640.0), p(1290.0, 620.0), p(1400.0, 660.0), p(1470.0, 760.0), p(1530.0, 900.0), p(1540.0, 1060.0), p(1450.0, 1130.0), p(1410.0, 1200.0), p(1210.0, 1200.0), p(1160.0, 1080.0), p(1150.0, 900.0), p(1175.0, 760.0)]},
    {name: head, parent: Some(torso), pivot: p(1300.0, 680.0), z: 9,
      outline: [p(1070.0, 560.0), p(1080.0, 440.0), p(1120.0, 330.0), p(1200.0, 220.0), p(1300.0, 170.0), p(1440.0, 180.0), p(1560.0, 190.0), p(1600.0, 320.0), p(1580.0, 480.0), p(1480.0, 560.0), p(1420.0, 660.0), p(1400.0, 700.0), p(1200.0, 700.0), p(1180.0, 600.0), p(1100.0, 600.0)]},
    {name: wingNear, parent: Some(torso), pivot: p(1220.0, 640.0), z: 4,
      outline: [p(1200.0, 220.0), p(1120.0, 330.0), p(1080.0, 440.0), p(1100.0, 600.0), p(1190.0, 650.0), p(1195.0, 775.0), p(900.0, 775.0), p(700.0, 760.0), p(520.0, 540.0), p(500.0, 150.0), p(1000.0, 120.0)]},
    {name: wingFar, parent: Some(torso), pivot: p(1450.0, 650.0), z: 1,
      outline: [p(1400.0, 640.0), p(1470.0, 760.0), p(1500.0, 795.0), p(1800.0, 795.0), p(2000.0, 760.0), p(2450.0, 860.0), p(2460.0, 120.0), p(1620.0, 100.0), p(1615.0, 520.0), p(1480.0, 570.0)]},
    {name: armNear, parent: Some(torso), pivot: leArmNPivot, z: 8, outline: leArmNOutline},
    {name: armFar, parent: Some(torso), pivot: leArmFPivot, z: 6, outline: leArmFOutline},
    {name: legNear, parent: Some(torso), pivot: p(1210.0, 1150.0), z: 7,
      outline: [p(1140.0, 1110.0), p(1260.0, 1100.0), p(1320.0, 1200.0), p(1320.0, 1380.0), p(1340.0, 1450.0), p(1110.0, 1455.0), p(1120.0, 1380.0), p(1150.0, 1300.0), p(1130.0, 1200.0)]},
    {name: legFar, parent: Some(torso), pivot: p(1500.0, 1100.0), z: 3,
      outline: [p(1405.0, 1040.0), p(1520.0, 1030.0), p(1600.0, 1100.0), p(1600.0, 1380.0), p(1610.0, 1445.0), p(1395.0, 1445.0), p(1400.0, 1380.0), p(1410.0, 1200.0)]},
    {name: tail, parent: Some(torso), pivot: p(1600.0, 1080.0), z: 2,
      outline: [p(1545.0, 960.0), p(1700.0, 930.0), p(2420.0, 1000.0), p(2430.0, 1080.0), p(2100.0, 1200.0), p(1650.0, 1200.0), p(1610.0, 1130.0), p(1560.0, 1060.0)]},
  ],
}

/* ---------------------------------------------------------- कैस्टर's rig */
let (caArmNPivot, caArmNOutline) = armEnd(~cut=1192.0, ~yTop=700.0, ~yBot=815.0, ~tip=850.0, ~towardTorso=1.0)
let (caArmFPivot, caArmFOutline) = armEnd(~cut=1395.0, ~yTop=728.0, ~yBot=855.0, ~tip=1850.0, ~towardTorso=-1.0)
let castorRig: rigSpec<small> = {
  sprite: ImagePath(root ++ "cutout/sprites/castor_spread.png"),
  partsDir: root ++ "cutout/parts/castor/",
  feet: p(1300.0, 1370.0),
  patches: [
    {patch: "open", image: ImagePath(root ++ "cutout/sprites/castor_mouth_open.png"), parent: head, at: p(1040.0, 470.0)},
    {patch: "round", image: ImagePath(root ++ "cutout/sprites/castor_mouth_round.png"), parent: head, at: p(1040.0, 470.0)},
    {patch: "half", image: ImagePath(root ++ "cutout/sprites/castor_mouth_half.png"), parent: head, at: p(1040.0, 470.0)},
  ],
  parts: [
    {name: torso, parent: None, pivot: p(1330.0, 940.0), z: 5,
      outline: [p(1180.0, 660.0), p(1290.0, 640.0), p(1400.0, 670.0), p(1470.0, 760.0), p(1530.0, 900.0), p(1540.0, 1040.0), p(1450.0, 1100.0), p(1420.0, 1200.0), p(1140.0, 1200.0), p(1120.0, 1050.0), p(1110.0, 880.0), p(1150.0, 760.0)]},
    {name: head, parent: Some(torso), pivot: p(1290.0, 680.0), z: 9,
      outline: [p(1030.0, 520.0), p(1040.0, 400.0), p(1090.0, 280.0), p(1180.0, 190.0), p(1300.0, 160.0), p(1460.0, 170.0), p(1560.0, 260.0), p(1580.0, 420.0), p(1520.0, 560.0), p(1420.0, 660.0), p(1400.0, 700.0), p(1200.0, 700.0), p(1170.0, 600.0), p(1060.0, 600.0)]},
    {name: wingNear, parent: Some(torso), pivot: p(1190.0, 650.0), z: 4,
      outline: [p(1180.0, 190.0), p(1090.0, 280.0), p(1040.0, 400.0), p(1030.0, 520.0), p(1060.0, 600.0), p(1170.0, 610.0), p(1190.0, 690.0), p(880.0, 690.0), p(700.0, 600.0), p(620.0, 300.0), p(640.0, 120.0), p(1000.0, 110.0)]},
    {name: wingFar, parent: Some(torso), pivot: p(1450.0, 660.0), z: 1,
      outline: [p(1400.0, 640.0), p(1470.0, 760.0), p(1500.0, 780.0), p(1800.0, 760.0), p(2000.0, 720.0), p(2280.0, 700.0), p(2260.0, 120.0), p(1600.0, 110.0), p(1580.0, 300.0), p(1520.0, 560.0)]},
    {name: armNear, parent: Some(torso), pivot: caArmNPivot, z: 8, outline: caArmNOutline},
    {name: armFar, parent: Some(torso), pivot: caArmFPivot, z: 6, outline: caArmFOutline},
    {name: legNear, parent: Some(torso), pivot: p(1130.0, 1120.0), z: 7,
      outline: [p(1060.0, 1070.0), p(1200.0, 1060.0), p(1230.0, 1160.0), p(1225.0, 1300.0), p(1245.0, 1365.0), p(1035.0, 1370.0), p(1040.0, 1290.0), p(1070.0, 1200.0)]},
    {name: legFar, parent: Some(torso), pivot: p(1440.0, 1060.0), z: 3,
      outline: [p(1360.0, 990.0), p(1500.0, 980.0), p(1540.0, 1100.0), p(1530.0, 1320.0), p(1530.0, 1385.0), p(1330.0, 1385.0), p(1340.0, 1320.0), p(1355.0, 1200.0)]},
    {name: tail, parent: Some(torso), pivot: p(1560.0, 960.0), z: 2,
      outline: [p(1500.0, 890.0), p(1700.0, 880.0), p(2270.0, 920.0), p(2280.0, 1010.0), p(2000.0, 1050.0), p(1600.0, 1040.0), p(1545.0, 1000.0)]},
  ],
}

/* ---------------------------------------------------------- वैस्पर's rig */
let (veArmNPivot, veArmNOutline) = armEnd(~cut=1192.0, ~yTop=788.0, ~yBot=880.0, ~tip=780.0, ~towardTorso=1.0)
let (veArmFPivot, veArmFOutline) = armEnd(~cut=1395.0, ~yTop=800.0, ~yBot=905.0, ~tip=1850.0, ~towardTorso=-1.0)
let vesperRig: rigSpec<small> = {
  sprite: ImagePath(root ++ "cutout/sprites/vesper_spread.png"),
  partsDir: root ++ "cutout/parts/vesper/",
  feet: p(1330.0, 1440.0),
  patches: [
    {patch: "open", image: ImagePath(root ++ "cutout/sprites/vesper_mouth_open.png"), parent: head, at: p(1060.0, 550.0)},
    {patch: "round", image: ImagePath(root ++ "cutout/sprites/vesper_mouth_round.png"), parent: head, at: p(1060.0, 550.0)},
    {patch: "half", image: ImagePath(root ++ "cutout/sprites/vesper_mouth_half.png"), parent: head, at: p(1060.0, 550.0)},
  ],
  parts: [
    {name: torso, parent: None, pivot: p(1330.0, 990.0), z: 5,
      outline: [p(1180.0, 720.0), p(1290.0, 700.0), p(1400.0, 730.0), p(1470.0, 820.0), p(1530.0, 960.0), p(1540.0, 1100.0), p(1450.0, 1160.0), p(1420.0, 1240.0), p(1150.0, 1240.0), p(1120.0, 1100.0), p(1120.0, 940.0), p(1160.0, 830.0)]},
    {name: head, parent: Some(torso), pivot: p(1290.0, 740.0), z: 9,
      outline: [p(1070.0, 600.0), p(1080.0, 480.0), p(1120.0, 360.0), p(1220.0, 270.0), p(1340.0, 250.0), p(1500.0, 270.0), p(1560.0, 380.0), p(1560.0, 520.0), p(1500.0, 620.0), p(1420.0, 720.0), p(1400.0, 760.0), p(1200.0, 760.0), p(1180.0, 660.0), p(1090.0, 650.0)]},
    {name: wingNear, parent: Some(torso), pivot: p(1200.0, 720.0), z: 4,
      outline: [p(1220.0, 270.0), p(1120.0, 360.0), p(1080.0, 480.0), p(1070.0, 600.0), p(1090.0, 650.0), p(1180.0, 700.0), p(1195.0, 785.0), p(900.0, 785.0), p(700.0, 760.0), p(420.0, 560.0), p(400.0, 150.0), p(1000.0, 100.0)]},
    {name: wingFar, parent: Some(torso), pivot: p(1460.0, 730.0), z: 1,
      outline: [p(1400.0, 720.0), p(1470.0, 820.0), p(1500.0, 800.0), p(1800.0, 800.0), p(2000.0, 760.0), p(2420.0, 820.0), p(2420.0, 80.0), p(1580.0, 60.0), p(1560.0, 380.0), p(1500.0, 620.0)]},
    {name: armNear, parent: Some(torso), pivot: veArmNPivot, z: 8, outline: veArmNOutline},
    {name: armFar, parent: Some(torso), pivot: veArmFPivot, z: 6, outline: veArmFOutline},
    {name: legNear, parent: Some(torso), pivot: p(1170.0, 1160.0), z: 7,
      outline: [p(1090.0, 1110.0), p(1240.0, 1100.0), p(1260.0, 1200.0), p(1260.0, 1360.0), p(1270.0, 1445.0), p(1050.0, 1445.0), p(1060.0, 1360.0), p(1080.0, 1200.0)]},
    {name: legFar, parent: Some(torso), pivot: p(1470.0, 1090.0), z: 3,
      outline: [p(1380.0, 1030.0), p(1540.0, 1020.0), p(1570.0, 1120.0), p(1560.0, 1360.0), p(1570.0, 1445.0), p(1370.0, 1445.0), p(1380.0, 1360.0), p(1385.0, 1200.0)]},
    {name: tail, parent: Some(torso), pivot: p(1590.0, 1220.0), z: 2,
      outline: [p(1520.0, 1120.0), p(1700.0, 1100.0), p(2130.0, 1250.0), p(2120.0, 1330.0), p(1900.0, 1370.0), p(1620.0, 1350.0), p(1580.0, 1300.0), p(1545.0, 1220.0)]},
  ],
}

/* ------------------------------------------------------------ पापा's rig */
let (paArmNPivot, paArmNOutline) = armEnd(~cut=1192.0, ~yTop=708.0, ~yBot=808.0, ~tip=830.0, ~towardTorso=1.0)
let (paArmFPivot, paArmFOutline) = armEnd(~cut=1395.0, ~yTop=718.0, ~yBot=805.0, ~tip=1810.0, ~towardTorso=-1.0)
let papaRig: rigSpec<small> = {
  sprite: ImagePath(root ++ "cutout/sprites/papa_spread.png"),
  partsDir: root ++ "cutout/parts/papa/",
  feet: p(1280.0, 1380.0),
  patches: [
    {patch: "open", image: ImagePath(root ++ "cutout/sprites/papa_mouth_open.png"), parent: head, at: p(1090.0, 440.0)},
    {patch: "round", image: ImagePath(root ++ "cutout/sprites/papa_mouth_round.png"), parent: head, at: p(1090.0, 440.0)},
    {patch: "half", image: ImagePath(root ++ "cutout/sprites/papa_mouth_half.png"), parent: head, at: p(1090.0, 440.0)},
  ],
  parts: [
    {name: torso, parent: None, pivot: p(1320.0, 1000.0), z: 5,
      outline: [p(1190.0, 700.0), p(1300.0, 680.0), p(1400.0, 700.0), p(1470.0, 780.0), p(1530.0, 900.0), p(1540.0, 1080.0), p(1480.0, 1150.0), p(1450.0, 1240.0), p(1120.0, 1240.0), p(1100.0, 1100.0), p(1100.0, 900.0), p(1150.0, 780.0)]},
    {name: head, parent: Some(torso), pivot: p(1290.0, 720.0), z: 9,
      outline: [p(1100.0, 520.0), p(1110.0, 420.0), p(1150.0, 350.0), p(1240.0, 320.0), p(1360.0, 330.0), p(1420.0, 400.0), p(1420.0, 520.0), p(1380.0, 600.0), p(1370.0, 740.0), p(1200.0, 740.0), p(1190.0, 600.0), p(1130.0, 580.0)]},
    {name: wingNear, parent: Some(torso), pivot: p(1200.0, 690.0), z: 4,
      outline: [p(1240.0, 320.0), p(1150.0, 350.0), p(1110.0, 420.0), p(1100.0, 520.0), p(1130.0, 580.0), p(1190.0, 650.0), p(1195.0, 705.0), p(900.0, 705.0), p(700.0, 700.0), p(480.0, 560.0), p(470.0, 170.0), p(1000.0, 150.0)]},
    {name: wingFar, parent: Some(torso), pivot: p(1450.0, 700.0), z: 1,
      outline: [p(1400.0, 700.0), p(1470.0, 780.0), p(1500.0, 760.0), p(1760.0, 715.0), p(2000.0, 700.0), p(2400.0, 780.0), p(2410.0, 110.0), p(1500.0, 100.0), p(1430.0, 400.0), p(1420.0, 600.0)]},
    {name: armNear, parent: Some(torso), pivot: paArmNPivot, z: 8, outline: paArmNOutline},
    {name: armFar, parent: Some(torso), pivot: paArmFPivot, z: 6, outline: paArmFOutline},
    {name: legNear, parent: Some(torso), pivot: p(1180.0, 1180.0), z: 7,
      outline: [p(1080.0, 1130.0), p(1240.0, 1120.0), p(1290.0, 1220.0), p(1290.0, 1330.0), p(1300.0, 1385.0), p(1060.0, 1390.0), p(1070.0, 1320.0), p(1090.0, 1220.0)]},
    {name: legFar, parent: Some(torso), pivot: p(1400.0, 1160.0), z: 3,
      outline: [p(1320.0, 1110.0), p(1460.0, 1100.0), p(1490.0, 1200.0), p(1480.0, 1330.0), p(1490.0, 1385.0), p(1310.0, 1390.0), p(1320.0, 1320.0), p(1325.0, 1200.0)]},
    {name: tail, parent: Some(torso), pivot: p(1530.0, 1000.0), z: 2,
      outline: [p(1480.0, 920.0), p(1700.0, 900.0), p(2070.0, 960.0), p(2070.0, 1060.0), p(1800.0, 1090.0), p(1560.0, 1080.0), p(1500.0, 1040.0)]},
  ],
}

/* ------------------------------------------------------------ कालू's rig */
/* A quadruped in side view: body, head, the hanging ear in front of the head,
   four legs (the far pair behind the body), the tail. He has no lines. */
let dBodyDog = PartName("body")
let dHeadDog = PartName("head")
let dEar = PartName("ear")
let legFN = PartName("legFrontNear")
let legFF = PartName("legFrontFar")
let legHN = PartName("legHindNear")
let legHF = PartName("legHindFar")
let dTail = PartName("tail")
let kaluRig: rigSpec<small> = {
  sprite: ImagePath(root ++ "cutout/sprites/kalu_side.png"),
  partsDir: root ++ "cutout/parts/kalu/",
  feet: p(1450.0, 1300.0),
  patches: [],
  parts: [
    {name: dBodyDog, parent: None, pivot: p(1450.0, 800.0), z: 4,
      outline: [p(1000.0, 620.0), p(1200.0, 560.0), p(1500.0, 560.0), p(1800.0, 620.0), p(1850.0, 800.0), p(1800.0, 980.0), p(1700.0, 1000.0), p(1500.0, 960.0), p(1300.0, 960.0), p(1100.0, 1000.0), p(1020.0, 900.0)]},
    {name: dHeadDog, parent: Some(dBodyDog), pivot: p(1080.0, 620.0), z: 7,
      outline: [p(700.0, 520.0), p(760.0, 380.0), p(880.0, 270.0), p(1050.0, 240.0), p(1200.0, 300.0), p(1240.0, 400.0), p(1120.0, 480.0), p(1120.0, 640.0), p(1000.0, 700.0), p(900.0, 660.0), p(720.0, 640.0)]},
    {name: dEar, parent: Some(dHeadDog), pivot: p(1200.0, 360.0), z: 8,
      outline: [p(1130.0, 330.0), p(1260.0, 330.0), p(1360.0, 500.0), p(1340.0, 740.0), p(1220.0, 760.0), p(1120.0, 640.0), p(1100.0, 480.0)]},
    {name: legFN, parent: Some(dBodyDog), pivot: p(1120.0, 960.0), z: 6,
      outline: [p(1040.0, 930.0), p(1200.0, 930.0), p(1220.0, 1080.0), p(1230.0, 1250.0), p(1260.0, 1310.0), p(1040.0, 1310.0), p(1050.0, 1250.0), p(1030.0, 1080.0)]},
    {name: legFF, parent: Some(dBodyDog), pivot: p(1270.0, 960.0), z: 1,
      outline: [p(1180.0, 930.0), p(1360.0, 930.0), p(1370.0, 1080.0), p(1360.0, 1250.0), p(1380.0, 1310.0), p(1200.0, 1310.0), p(1210.0, 1250.0), p(1190.0, 1080.0)]},
    {name: legHN, parent: Some(dBodyDog), pivot: p(1600.0, 960.0), z: 5,
      outline: [p(1520.0, 930.0), p(1680.0, 930.0), p(1700.0, 1080.0), p(1690.0, 1250.0), p(1720.0, 1310.0), p(1500.0, 1310.0), p(1510.0, 1250.0), p(1510.0, 1080.0)]},
    {name: legHF, parent: Some(dBodyDog), pivot: p(1790.0, 960.0), z: 2,
      outline: [p(1680.0, 930.0), p(1880.0, 920.0), p(1890.0, 1080.0), p(1870.0, 1250.0), p(1900.0, 1310.0), p(1700.0, 1310.0), p(1710.0, 1250.0), p(1690.0, 1080.0)]},
    {name: dTail, parent: Some(dBodyDog), pivot: p(1780.0, 660.0), z: 3,
      outline: [p(1740.0, 660.0), p(1760.0, 380.0), p(1950.0, 370.0), p(1960.0, 660.0), p(1860.0, 700.0)]},
  ],
}

/* ------------------------------------------------- कुकु's GREAT form */
/* The type says it: rigSpec<great>. This is the first rig the flight accepts. */
let (kgArmNPivot, kgArmNOutline) = armEnd(~cut=1170.0, ~yTop=768.0, ~yBot=875.0, ~tip=720.0, ~towardTorso=1.0)
let (kgArmFPivot, kgArmFOutline) = armEnd(~cut=1395.0, ~yTop=768.0, ~yBot=882.0, ~tip=1810.0, ~towardTorso=-1.0)
let kukuGreatRig: rigSpec<great> = {
  sprite: ImagePath(root ++ "cutout/sprites/kuku_great_spread.png"),
  partsDir: root ++ "cutout/parts/kuku_great/",
  feet: p(1300.0, 1430.0),
  patches: [],
  parts: [
    {name: torso, parent: None, pivot: p(1320.0, 960.0), z: 5,
      outline: [p(1170.0, 690.0), p(1290.0, 670.0), p(1400.0, 700.0), p(1470.0, 790.0), p(1530.0, 920.0), p(1540.0, 1070.0), p(1460.0, 1130.0), p(1420.0, 1240.0), p(1140.0, 1240.0), p(1110.0, 1100.0), p(1100.0, 900.0), p(1130.0, 780.0)]},
    {name: head, parent: Some(torso), pivot: p(1280.0, 700.0), z: 9,
      outline: [p(1030.0, 540.0), p(1040.0, 430.0), p(1080.0, 300.0), p(1170.0, 210.0), p(1280.0, 180.0), p(1420.0, 190.0), p(1500.0, 300.0), p(1500.0, 460.0), p(1450.0, 580.0), p(1400.0, 660.0), p(1380.0, 720.0), p(1180.0, 720.0), p(1160.0, 620.0), p(1050.0, 610.0)]},
    {name: wingNear, parent: Some(torso), pivot: p(1180.0, 700.0), z: 4,
      outline: [p(1170.0, 210.0), p(1080.0, 300.0), p(1040.0, 430.0), p(1030.0, 540.0), p(1050.0, 610.0), p(1150.0, 650.0), p(1165.0, 765.0), p(900.0, 765.0), p(700.0, 720.0), p(400.0, 560.0), p(390.0, 160.0), p(1000.0, 150.0)]},
    {name: wingFar, parent: Some(torso), pivot: p(1460.0, 700.0), z: 1,
      outline: [p(1400.0, 660.0), p(1470.0, 790.0), p(1500.0, 765.0), p(1760.0, 765.0), p(2000.0, 740.0), p(2260.0, 760.0), p(2250.0, 110.0), p(1520.0, 100.0), p(1500.0, 300.0), p(1500.0, 460.0), p(1450.0, 580.0)]},
    {name: armNear, parent: Some(torso), pivot: kgArmNPivot, z: 8, outline: kgArmNOutline},
    {name: armFar, parent: Some(torso), pivot: kgArmFPivot, z: 6, outline: kgArmFOutline},
    {name: legNear, parent: Some(torso), pivot: p(1160.0, 1160.0), z: 7,
      outline: [p(1060.0, 1110.0), p(1220.0, 1100.0), p(1280.0, 1200.0), p(1280.0, 1350.0), p(1300.0, 1445.0), p(1030.0, 1445.0), p(1040.0, 1360.0), p(1070.0, 1220.0)]},
    {name: legFar, parent: Some(torso), pivot: p(1470.0, 1090.0), z: 3,
      outline: [p(1380.0, 1030.0), p(1540.0, 1020.0), p(1580.0, 1120.0), p(1570.0, 1360.0), p(1590.0, 1445.0), p(1370.0, 1445.0), p(1375.0, 1360.0), p(1385.0, 1200.0)]},
    {name: tail, parent: Some(torso), pivot: p(1580.0, 1030.0), z: 2,
      outline: [p(1520.0, 940.0), p(1700.0, 920.0), p(2300.0, 980.0), p(2300.0, 1060.0), p(2000.0, 1120.0), p(1620.0, 1120.0), p(1560.0, 1060.0)]},
  ],
}

/* a state with every part at rest, placed by where the feet are on the stage */
let standing = (~feetX, ~feetY, ~size) => stand(kukuRig, ~feetX, ~feetY, ~size, ())

let posed = (st: puppetState, poses: array<(partName, partPose)>): puppetState => {
  let d = Js.Dict.empty()
  Js.Array2.forEach(poses, ((PartName(n), pose)) => Js.Dict.set(d, n, pose))
  {...st, parts: d}
}

/* THE CANONICAL POSE. The puppet sheet spreads every limb so the parts can be
   cut; the character sheet is how कुकु actually stands: wings half open and
   relaxed behind him, arms down. Every state begins here and adds to it —
   later entries in a pose list win, so a shot overrides only what it moves. */
let wingAt = (a, s) => {angle: Deg(a), dx: Px(0.0), dy: Px(0.0), s: Scale(s)}
let restWingNear = -45.0
let restWingFar = 15.0
let restArmNear = 62.0
let restArmFar = 75.0 /* hanging along the far flank, hand beside the belly */
let canonical = [
  (wingNear, wingAt(restWingNear, 0.6)),
  (wingFar, wingAt(restWingFar, 0.6)),
  (armNear, turn(-.restArmNear)),
  (armFar, turn(restArmFar)),
]
let posedCanonical = (st, poses) => posed(st, Js.Array2.concat(canonical, poses))
/* her sheet holds one small wing folded back: rest keeps the wings low */
let ledaCanonical = [(wingNear, wingAt(-40.0, 0.55)), (wingFar, wingAt(10.0, 0.55)), (armNear, turn(-66.0)), (armFar, turn(70.0))]
let castorCanonical = [(wingNear, wingAt(-45.0, 0.6)), (wingFar, wingAt(12.0, 0.6)), (armNear, turn(-66.0)), (armFar, turn(70.0))]
let vesperCanonical = [(wingNear, wingAt(-50.0, 0.55)), (wingFar, wingAt(15.0, 0.55)), (armNear, turn(-66.0)), (armFar, turn(70.0))]
let papaCanonical = [(wingNear, wingAt(-45.0, 0.55)), (wingFar, wingAt(12.0, 0.55)), (armNear, turn(-70.0)), (armFar, turn(72.0))]


/* ------------------------------------------------- कालू asleep: one piece */
let dCurl = PartName("curl")
let kaluAsleepRig: rigSpec<small> = {
  sprite: ImagePath(root ++ "cutout/sprites/kalu_asleep.png"),
  partsDir: root ++ "cutout/parts/kalu_asleep/",
  feet: p(1300.0, 1070.0),
  patches: [],
  parts: [
    {name: dCurl, parent: None, pivot: p(1300.0, 800.0), z: 1,
      outline: [p(600.0, 380.0), p(2060.0, 380.0), p(2060.0, 1120.0), p(600.0, 1120.0)]},
  ],
}

/* ---------------------------------------------------------- the stage */
let stageW = 1280
let stageH = 720
let fpsOut = Fps(24)

/* ------------------------------------------------------- shared helpers */
let easeOut = u => 1.0 -. Js.Math.pow_float(~base=1.0 -. u, ~exp=3.0)
let clamp01 = u => u < 0.0 ? 0.0 : u > 1.0 ? 1.0 : u
let groundY = 640.0
let courtyard = async () => {
  let plate = await plateLayer(~path=ImagePath(root ++ "sets/courtyard_plate.png"), ~w=Px(1280.0), ~h=Px(720.0))
  let lamp = await imageLayer(~z=1, ~path=ImagePath(root ++ "cutout/sprites/lamp_lit.png"), ~x=Px(548.0), ~y=Px(353.0), ~w=Px(110.0), ~h=Px(79.0))
  (plate, lamp)
}


let lampGlow = (~strength) => (t: sec) => {
  gx: Px(603.0),
  gy: Px(392.0),
  radius: Px(150.0),
  strength: Alpha(strength +. 0.04 *. Js.Math.sin(13.0 *. secf(t)) +. 0.03 *. Js.Math.sin(29.0 *. secf(t))),
}

/* कुकु's sprite smiles open, so rest and silence show his CLOSED patch */
let kukuMouth = shape =>
  switch shape {
  | "E" | "F" => Some("round")
  | "D" => Some("open")
  | "B" | "C" | "G" | "H" => Some("half")
  | _ => Some("closed")
  }

/* कुकु answers दादी: his line 9, on his own take */

/* फ्यूरिया's rest: her sheet holds the wings open, so wider than कुकु's */
let furiaCanonical = [
  (wingNear, wingAt(-22.0, 0.8)),
  (wingFar, wingAt(8.0, 0.8)),
  (armNear, turn(-66.0)),
  (armFar, turn(70.0)),
]


/* ------------------------------------------------- the light states */
/* One plate, four gradings, same geometry: dusk as generated; lamp-night, a
   blue multiply with the lamp's glow; dark, deeper blue and the lamp cold;
   golden, the letter's light from the courtyard's middle. */
type light = Dusk | LampNight | Dark | Golden
let lightName = l =>
  switch l {
  | Dusk => "dusk"
  | LampNight => "lampnight"
  | Dark => "dark"
  | Golden => "golden"
  }
/* z: puppets sit at 4-9; the tint at 20 grades plate AND puppets; the lamp's
   flame at 21 stays bright above the tint; the glow at 22 lights everything */
let lightLayers = (l, ~lamp: layer) =>
  switch l {
  | Dusk => [{...lamp, z: 21}]
  | LampNight => [
      tintLayer(~z=20, ~colour="#5a6fb8", ~w=Px(1280.0), ~h=Px(720.0)),
      {...lamp, z: 21},
      glowLayer(~z=22, ~colour="rgba(255,176,80,1)", ~glow=lampGlow(~strength=0.55)),
    ]
  | Dark => [
      tintLayer(~z=20, ~colour="#3a4a8a", ~w=Px(1280.0), ~h=Px(720.0)),
      tintLayer(~z=20, ~colour="#6a7098", ~w=Px(1280.0), ~h=Px(720.0)),
    ]
  | Golden => [
      tintLayer(~z=20, ~colour="#6a6a90", ~w=Px(1280.0), ~h=Px(720.0)),
      glowLayer(~z=22, ~colour="rgba(255,205,90,1)", ~glow=_t => {gx: Px(860.0), gy: Px(430.0), radius: Px(360.0), strength: Alpha(0.75)}),
    ]
  }
