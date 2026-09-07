// KukuEp10_Puppets.res — the puppets of EP10 and the shots that move them.
//
// कुकु was generated ONCE as a spread-pose sprite on a blue sheet (receipted,
// 2 credits). Everything below is numbers: where each part is cut, where it
// hinges, how it moves. A render costs nothing and is the same every time.
//
//   node src/KukuEp10_Puppets.res.mjs cut       # cut the parts from the sprite
//   node src/KukuEp10_Puppets.res.mjs check     # rest pose + exploded pose, on grey
//   node src/KukuEp10_Puppets.res.mjs fly       # the proof: कुकु flies in and lands at the niche

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
    {
      name: armNear,
      parent: Some(torso),
      pivot: p(1158.0, 835.0),
      z: 8,
      cap: {radius: Px(56.0), colour: "#9fb068", edge: "#7c8d4b"},
      outline: [p(1168.0, 762.0), p(830.0, 770.0), p(800.0, 830.0), p(825.0, 900.0), p(1165.0, 908.0)],
    },
    {
      name: armFar,
      parent: Some(torso),
      pivot: p(1410.0, 835.0),
      z: 6,
      cap: {radius: Px(54.0), colour: "#94a45f", edge: "#6f8244"},
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
    {
      name: armNear,
      parent: Some(torso),
      pivot: p(1178.0, 665.0),
      z: 8,
      cap: {radius: Px(40.0), colour: "#d8646c", edge: "#a8444e"},
      outline: [p(1190.0, 618.0), p(840.0, 612.0), p(820.0, 660.0), p(850.0, 712.0), p(1188.0, 715.0)],
    },
    {
      name: armFar,
      parent: Some(torso),
      pivot: p(1418.0, 720.0),
      z: 6,
      cap: {radius: Px(40.0), colour: "#c6535c", edge: "#963a44"},
      outline: [p(1400.0, 660.0), p(1820.0, 700.0), p(1830.0, 800.0), p(1430.0, 800.0)],
    },
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
    {name: armNear, parent: Some(torso), pivot: p(1180.0, 822.0), z: 8, cap: {radius: Px(40.0), colour: "#c9aee6", edge: "#9a80b8"},
      outline: [p(1192.0, 768.0), p(840.0, 772.0), p(820.0, 820.0), p(850.0, 872.0), p(1190.0, 875.0)]},
    {name: armFar, parent: Some(torso), pivot: p(1410.0, 850.0), z: 6, cap: {radius: Px(40.0), colour: "#b89ad8", edge: "#8c6fae"},
      outline: [p(1395.0, 795.0), p(1800.0, 805.0), p(1830.0, 860.0), p(1800.0, 905.0), p(1425.0, 905.0)]},
    {name: legNear, parent: Some(torso), pivot: p(1210.0, 1150.0), z: 7,
      outline: [p(1140.0, 1110.0), p(1260.0, 1100.0), p(1320.0, 1200.0), p(1320.0, 1380.0), p(1340.0, 1450.0), p(1110.0, 1455.0), p(1120.0, 1380.0), p(1150.0, 1300.0), p(1130.0, 1200.0)]},
    {name: legFar, parent: Some(torso), pivot: p(1500.0, 1100.0), z: 3,
      outline: [p(1405.0, 1040.0), p(1520.0, 1030.0), p(1600.0, 1100.0), p(1600.0, 1380.0), p(1610.0, 1445.0), p(1395.0, 1445.0), p(1400.0, 1380.0), p(1410.0, 1200.0)]},
    {name: tail, parent: Some(torso), pivot: p(1600.0, 1080.0), z: 2,
      outline: [p(1545.0, 960.0), p(1700.0, 930.0), p(2420.0, 1000.0), p(2430.0, 1080.0), p(2100.0, 1200.0), p(1650.0, 1200.0), p(1610.0, 1130.0), p(1560.0, 1060.0)]},
  ],
}

/* ---------------------------------------------------------- कैस्टर's rig */
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
    {name: armNear, parent: Some(torso), pivot: p(1180.0, 757.0), z: 8, cap: {radius: Px(42.0), colour: "#e7b95a", edge: "#b8862e"},
      outline: [p(1192.0, 700.0), p(900.0, 705.0), p(880.0, 750.0), p(900.0, 810.0), p(1190.0, 815.0)]},
    {name: armFar, parent: Some(torso), pivot: p(1410.0, 790.0), z: 6, cap: {radius: Px(42.0), colour: "#d9a94a", edge: "#a67a28"},
      outline: [p(1395.0, 728.0), p(1800.0, 740.0), p(1830.0, 800.0), p(1800.0, 855.0), p(1425.0, 850.0)]},
    {name: legNear, parent: Some(torso), pivot: p(1130.0, 1120.0), z: 7,
      outline: [p(1060.0, 1070.0), p(1200.0, 1060.0), p(1230.0, 1160.0), p(1225.0, 1300.0), p(1245.0, 1365.0), p(1035.0, 1370.0), p(1040.0, 1290.0), p(1070.0, 1200.0)]},
    {name: legFar, parent: Some(torso), pivot: p(1440.0, 1060.0), z: 3,
      outline: [p(1360.0, 990.0), p(1500.0, 980.0), p(1540.0, 1100.0), p(1530.0, 1320.0), p(1530.0, 1385.0), p(1330.0, 1385.0), p(1340.0, 1320.0), p(1355.0, 1200.0)]},
    {name: tail, parent: Some(torso), pivot: p(1560.0, 960.0), z: 2,
      outline: [p(1500.0, 890.0), p(1700.0, 880.0), p(2270.0, 920.0), p(2280.0, 1010.0), p(2000.0, 1050.0), p(1600.0, 1040.0), p(1545.0, 1000.0)]},
  ],
}

/* ---------------------------------------------------------- वैस्पर's rig */
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
    {name: armNear, parent: Some(torso), pivot: p(1180.0, 833.0), z: 8, cap: {radius: Px(40.0), colour: "#a9d3ea", edge: "#6f9db8"},
      outline: [p(1192.0, 788.0), p(830.0, 792.0), p(810.0, 830.0), p(830.0, 875.0), p(1190.0, 880.0)]},
    {name: armFar, parent: Some(torso), pivot: p(1410.0, 852.0), z: 6, cap: {radius: Px(40.0), colour: "#94c2de", edge: "#5f8aa6"},
      outline: [p(1395.0, 800.0), p(1800.0, 810.0), p(1830.0, 860.0), p(1800.0, 905.0), p(1425.0, 905.0)]},
    {name: legNear, parent: Some(torso), pivot: p(1170.0, 1160.0), z: 7,
      outline: [p(1090.0, 1110.0), p(1240.0, 1100.0), p(1260.0, 1200.0), p(1260.0, 1360.0), p(1270.0, 1445.0), p(1050.0, 1445.0), p(1060.0, 1360.0), p(1080.0, 1200.0)]},
    {name: legFar, parent: Some(torso), pivot: p(1470.0, 1090.0), z: 3,
      outline: [p(1380.0, 1030.0), p(1540.0, 1020.0), p(1570.0, 1120.0), p(1560.0, 1360.0), p(1570.0, 1445.0), p(1370.0, 1445.0), p(1380.0, 1360.0), p(1385.0, 1200.0)]},
    {name: tail, parent: Some(torso), pivot: p(1590.0, 1220.0), z: 2,
      outline: [p(1520.0, 1120.0), p(1700.0, 1100.0), p(2130.0, 1250.0), p(2120.0, 1330.0), p(1900.0, 1370.0), p(1620.0, 1350.0), p(1580.0, 1300.0), p(1545.0, 1220.0)]},
  ],
}

/* ------------------------------------------------------------ पापा's rig */
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
    {name: armNear, parent: Some(torso), pivot: p(1180.0, 758.0), z: 8, cap: {radius: Px(36.0), colour: "#8fb08a", edge: "#5f7f5c"},
      outline: [p(1192.0, 708.0), p(880.0, 712.0), p(860.0, 755.0), p(880.0, 805.0), p(1190.0, 808.0)]},
    {name: armFar, parent: Some(torso), pivot: p(1410.0, 762.0), z: 6, cap: {radius: Px(36.0), colour: "#7fa07a", edge: "#55704f"},
      outline: [p(1395.0, 718.0), p(1760.0, 725.0), p(1790.0, 760.0), p(1760.0, 805.0), p(1425.0, 805.0)]},
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


/* ---------------------------------------------------------------- checks */
let stageW = 1280
let stageH = 720
let fpsOut = Fps(24)

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

/* --------------------------------------------- the dialogue proof: talk */
/* दादी speaks her line 8 to कुकु at the niche. Her mouth follows the viseme
   track of her own take; her head moves with the speech; कुकु listens, looks
   up at her, nods twice. The lamp glows and flickers. */
let lampGlow = (~strength) => (t: sec) => {
  gx: Px(603.0),
  gy: Px(392.0),
  radius: Px(150.0),
  strength: Alpha(strength +. 0.04 *. Js.Math.sin(13.0 *. secf(t)) +. 0.03 *. Js.Math.sin(29.0 *. secf(t))),
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

/* कुकु's sprite smiles open, so rest and silence show his CLOSED patch */
let kukuMouth = shape =>
  switch shape {
  | "E" | "F" => Some("round")
  | "D" => Some("open")
  | "B" | "C" | "G" | "H" => Some("half")
  | _ => Some("closed")
  }

/* कुकु answers दादी: his line 9, on his own take */
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

/* फ्यूरिया's rest: her sheet holds the wings open, so wider than कुकु's */
let furiaCanonical = [
  (wingNear, wingAt(-22.0, 0.8)),
  (wingFar, wingAt(8.0, 0.8)),
  (armNear, turn(-66.0)),
  (armFar, turn(70.0)),
]

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
    }
  | Some("checkfuria") => ignore(checkRig(furiaRig, "furia"))
  | Some("checkleda") => ignore(checkRig(ledaRig, "leda"))
  | Some("checkcastor") => ignore(checkRig(castorRig, "castor"))
  | Some("checkvesper") => ignore(checkRig(vesperRig, "vesper"))
  | Some("checkpapa") => ignore(checkRig(papaRig, "papa"))
  | Some("lineup") => ignore(lineup())
  | Some("checkkalu") => ignore(checkRig(kaluRig, "kalu"))
  | Some("talk") => ignore(talk())
  | Some("talkkuku") => ignore(talkKuku())
  | Some("talk3") => ignore(talk3())
  | Some("lights") => ignore(lights())
  | Some("check") => ignore(check())
  | Some("run") => ignore(runIn())
  | Some("fly") =>
    Js.log("the flight takes a great-form rig only (rig<great>); कुकु's great form has no sprite yet — one Sheet generation, 2 credits, on the author's budget line")
  | _ => Js.log("usage: cut | check | run | talk | lights | fly")
  }
