/* Drakosha_Room.res — the SET BIBLE for the home behind the stove.

   The room drifted because it existed only as prose: every shot re-described it
   and the ramp changed sides twice in one day. Here the room is DATA —
   landmarks at fixed positions on a plan — and the blocking, the canonical
   prose and the plate choice all derive from this one source.

   Plan coordinates are CENTIMETRES at Фрося's scale (she is 8.9 cm).
     +x runs across the hall, from the bed wall (-x) to the ramp wall (+x)
     +y runs ALONG the hall, from the kitchen end (y=0) to the sealed iron wall
     +z is height above the floorboards

   The two author plates are opposed views of this one room:
     SET-HOME-ROOM-01 stands at the kitchen end looking toward +y
     SET-HOME-ROOM-02 stands at the iron wall looking back toward -y
   Anything visible in both is fixed by seeing it from two sides. */

type wall = BedWall | RampWall | IronWall | KitchenWall

/* where a camera stands; a plate exists per vantage */
type vantage =
  | FromKitchen /* at the kitchen end looking down the hall — plate 01 */
  | FromIronWall /* at the sealed wall looking back — plate 02, and the writing shots */
  | LowOnBoards /* down at plank height, looking along */
  | AtTheHatch /* turned toward the bed wall and the cleanout hatch */

/* THREE KINDS OF THING, AND THEY ARE NOT THE SAME. 2026-08-30, author:
   "the little chairs cannot be landmarks because they're gonna be moved all the
   time... once we're gonna put the family sitting at the table, do they become
   a landmark?" No.

   A LANDMARK is architecture — it cannot move, so a camera and a body can be
   positioned against it. Walls, the hatch door, the niche, the hole in the
   floor, the ramp, the built-in stove and the wall shelves.

   A FURNISHING has a usual place and gets moved: the table, the cushions, the
   armchairs, the beds, the cradle. The plan records where it normally stands;
   a shot may say otherwise.

   A BODY is placed per shot and never lives here at all — position, facing and
   height, in Drakosha_Shot. */
type landmark = {
  name: string,
  x: float, /* cm across */
  y: float, /* cm along, kitchen end = 0 */
  z: float, /* cm above the boards */
  w: float, /* cm wide */
  d: float, /* cm deep */
  h: float, /* cm tall */
  note: string,
}

/* DERIVED, not eyeballed. 2026-08-31, author: "You know the original heights of
   our characters. You could also look up what's a standard height of fireplace
   opening." Then, on being shown a русская печь: "We're not using Russian
   fireplace here." The show speaks Russian; the HOUSE is American. Standing law
   — unspecified setting is Western.

   An American masonry firebox, in inches:
     front opening      24-29 tall (30 recommended interior minimum), 36 wide
     back wall          rises vertical 14, then slopes forward to the throat
     hearth to damper   ~37  <- the true inside height
     depth              16-20 (20 is code minimum)
   Фрося is 3.5in, so the damper stands 10.6 of her above the hearth. */
let hallWidth = 64.0
let hallLength = 112.0
let wallHeight = 50.0
/* SIZED BY A PREVIZ PASS, NOT BY ARITHMETIC. 2026-08-31: a 4-second camera push
   over 120 x 200 showed the whole family as a small cluster on an empty plain,
   with the side walls so far out they never entered frame. The furniture is
   correct — it derives from the bodies — so the ROOM came down to it.
   THE WALLS ARE THEN DERIVED FROM REAL OBJECTS, not chosen. Author's method,
   2026-08-31: "if we're gonna actually put the matchsticks beds the size they're
   supposed to be behind where the mom is sitting, then we'll be able to find
   where that wall ends. And if we'll be able to place the ramp properly relative
   to the table zone, we'll find where the other wall ends."

     BED WALL (-x): sized by the LONGEST sleeper, not the shortest. Папа is
       11.43, so the parents' box is 13.14 — and with its head at the wall its
       foot reached -12.9 while Мама sits at -9.6, leaving no room to walk
       between them. Wall moved out to -27:
         Мама's back    -10.8  (she sits at -9.6)
         gap to walk AND push her cushion back   7.1
         bed foot       -17.9
         bed length     13.14
         wall           -32

     ZONES ALONG THE LENGTH, which is what set 80 rather than 75:
         back area      y  0 .. 42   stove and counter along the wall, the
                                     couch beside them, the two chairs facing
                                     each other across the old table, then the
                                     play rug and the cradle. It had 30 and was
                                     the thing squeezed every time the room grew
         clear floor    y 42 .. 50
         road mouth     y 50 .. 85   the opening and the whole ramp run, with
                                     the HATCH OPPOSITE ITS HEAD on the far wall
         clear floor    y 85 .. 92
         table zone     y 68 .. 80   table, cushions, Яга backing the plate,
                                     with 10 of clear floor behind her — the
                                     group was 3.8 off the plate and read as
                                     shoved against it

     The back area was 20 deep and could not hold its own furniture. Author,
     2026-08-31: "the back area needs to have the stove, the two armchairs, an
     old table, a couch, a play rug, and currently it's not deep enough."
     RAMP WALL (+x): the floor opening is 9cm across and hugs that wall, and the
       ramp needs its full 30cm of run at 25 degrees, clear of the table zone.
       Wall lands at +24, opening x 14 to 23.
     IRON WALL (+y): Яга sits at y 72 with her back to it; the plate has her
       backed against the plate. Wall at 75.

   Ceiling stays 50 — 5.6 of Фрося, a 10m ceiling at human scale. */

/* FIRST ESTIMATE, 2026-08-30 — read off the two author plates by eye. These are
   the numbers the author corrects on the blueprint before anything is spent. */
/* The author's own list, 2026-08-30: "the landmarks are the metal riveted plate
   behind the table, the ramp opening and the ramp, the hatch and the niche. And
   also the stove, since it doesn't move." The two shelves went back in a moment
   later: "that little shelf, I believe we can keep there. It is attached to the
   wall. It's not likely to move. Neither the shelf next to the stove." Bolted to
   a wall is the test, not size. */
/* ---- BODIES AND ERGONOMICS ------------------------------------------------
   Heights registry, stories/frosya-vasya/BIBLE.md:256. Everything a body uses is
   derived from a body, never typed by eye — because typed by eye is how the
   family table ended up 13 cm tall next to an 8.9 cm Фрося.

   The author's own plate is the check: that table is a plank laid across two
   THREAD SPOOLS, and a wooden spool is 4.5 cm. The derivation below lands on
   4.26, which is the spool. Every other height was out by about the same three.

   Ratios are ordinary human furniture measured against a 175 cm adult. */
let inch = 2.54
let vasyaH = 3.15 *. inch
let frosyaH = 3.50 *. inch
let yagaH = 3.60 *. inch
let mamaH = 3.90 *. inch
let papaH = 4.50 *. inch

/* HANDLEBAR HEIGHT IS A FACT ABOUT HER, NOT ABOUT THE PROP. Author, 2026-09-01:
   flat-footed on the scale sheet the bar sits at the base of her neck, and once
   she puts one foot up on the deck it drops to where her sleeves end — "across
   the middle of her chest." So it is derived off her torso: her hip is 30% of
   her height, her head is measured off the authority sheet, the torso is what is
   left, and the bar crosses the middle of it. It was 2.25in and read a tenth of
   her body height too tall. */
let frosyaHead = 1.54 *. inch
let frosyaHip = 0.30 *. frosyaH
let frosyaTorso = frosyaH -. frosyaHip -. frosyaHead
let barHeight = frosyaHip +. frosyaTorso *. 0.55

let seat = 0.26 /* stool, bed, chair seat */
let coffeeTop = 0.24
let tableTop = 0.43
let couchBack = 0.45
let chairBack = 0.50
let counter = 0.53 /* worktop, stove top */
let pouf = 0.28 /* THICKER than a human cushion ratio. With a 1.5cm pouf the
   1.75in spool table landed at Мама's shoulders; at 2.5cm it lands at her seated
   elbow, which is what a table is for. Their legs are stubs, so the seat has to
   do the work a chair does for us. */
/* MEASURED off FAMILY_SCALE_AUTHORITY_v2 with a ruler, 2026-08-31. HUMAN REACH
   RATIOS DO NOT TRANSFER. The head takes the top third of the body and the arms
   are short sticks, so a домовой reaches about 0.75 of their own height overhead
   where a human reaches 1.2.
     shoulder   .50 .53 .53 .53 .48  (Вася Фрося Яга Мама Папа)
     arm        .18 .22 .23 .25 .31  — it grows with the body
     reach up   .69 .75 .76 .78 .78
   The kitchen shelf sat at 8.52, ABOVE Мама's 7.75 maximum. Author: "even too
   tall for Papa to put anything on it." It was.

   Then, on being shown the reach arithmetic: "You don't really need to measure
   reach. You just have to put it at shoulder level or nose level of mom." Which
   is how a person actually places a shelf, so that is the rule. The measurements
   above only served to confirm the old one was out of range. */
let chestH = 0.49 /* of body height */

/* nose sits a little under halfway up the head, and the head is measured */
let noseOf = (bodyH, headH) => bodyH -. headH +. headH *. 0.45
let doorway = 1.16
/* WIDTH CLEARANCE IS SET BY THE HEAD, NOT THE SHOULDERS. On a body whose head
   is nearly half its height, the head is the widest part: Мама's is 4.24 across
   against 3.39 of shoulder. Anything two of them sit or walk side by side in has
   to clear HEADS. Author, 2026-08-31: "we really cannot measure anything off
   Mama's shoulders because her head is a lot bigger, so there is no way three
   Mamas can sit on it."

   headOf gives the measured head; sideBySide gives what n of them need with a
   little air between. */
let shoulders = 0.26 /* only useful for a shoulder itself, never for clearance */
let headMamaW = 1.67 *. inch
let headPapaW = 2.10 *. inch
let sideBySide = (n, headW) => float_of_int(n) *. headW *. 1.16

/* A CUSHION IS WIDE, NOT DEEP. Across, it has to clear the head that sits over
   it. Along the sitter's facing it can be no deeper than the THIGH, or the
   cushion swallows the leg and the knee has nowhere to go. Мама's thigh is 1.57.
   Applying the head rule to both dimensions at once made them 5.09 square and
   ate the legs. Author, 2026-08-31. */
/* ROUND POUFS. SET-HOME-ROOM-01 has them circular, so they are cylinders, and
   a solo pouf only has to carry the hips — the head rule governs things people
   sit in SIDE BY SIDE, not a stool one person sits on. Author, 2026-08-31. */
let cushionR = headMamaW *. 0.45
let lieDown = 1.10 /* a bed is longer than its sleeper */

let floorThickness = 3.0
let joistDepth = 3.0
let roadFloorT = 2.0

/* ROAD DEPTH IS DERIVED FROM THE HEADROOM, not typed. It was 14, and the floor
   slab, the joists and the road surface ate 8 of it — leaving 6cm of clear
   space under the joists when Фрося alone is 8.89. Nobody could stand up down
   there. Author, 2026-08-31: "it looks like it's like a step, and it's only
   half of Фрося's height deep." It was.

   The road is a walkable corridor, so it takes a full adult standing height and
   a little: Папа is 11.43. */
let underRoadHead = papaH *. 1.15
let roadDrop = underRoadHead +. floorThickness +. joistDepth +. roadFloorT
/* THE BOARD'S SLOPE IS SET BY THE HOLE, not by taste. A rider has to be BELOW
   the joists before the board passes under the solid floor, or she rides into
   them. At 30 degrees across a 20cm opening the board only fell 11.5 and the
   joists hang at -6, leaving 5.5 of headroom for an 8.9 girl. Author,
   2026-08-31: "you have to fix that hole in the middle of the floor."

   At 40 degrees the same opening gives her 12.5. */
/* 40 degrees was steep — it read as a chute rather than a way down, and she has
   to ride it. 30 degrees is the gentlest the room's length allows: the run grows
   to 33cm and the opening with it, and the hole has to finish clear of the table
   zone at y 62. Author, 2026-08-31: "it feels a bit too steep." */
let rampSlope = 0.577 /* tan 30 degrees */

/* THE BOARD LANDS ON THE ROAD SURFACE, not on the road's underside. Its foot
   was set to -roadDrop, which is the bottom of the road slab, so the last 2cm
   of board drove down through the surface instead of meeting it. Author,
   2026-08-31: "it should be a smooth transition between the floor and the
   ramp." */
/* THE RAMP LANDS ON THE BOARDS, not on the slab. It was falling the full depth to the
   concrete, which is a gravel bed and a plank below the surface she actually rides on —
   so its foot hung in the air above the road. */
/* THE BOARDS AND THE DUST THEY SIT IN — needed up here because the ramp's fall
   is measured to the surface she rides on, not to the slab underneath. */
let plankThickness = 0.55
let gravelDepth = 0.5 /* the gravel bed the boards are laid ON, and the posts stand IN */

let rampDrop = roadDrop -. roadFloorT -. gravelDepth -. plankThickness
let rampRun = rampDrop /. rampSlope

/* AND THE HOLE IS LONGER THAN THE BOARD'S RUN, so the whole descent AND the
   landing are visible through it. It was shorter than the run, which hid the
   last stretch and the touchdown under the floorboards — you could see the
   board start and never see it arrive. */
let openingLen = rampRun +. 2.0
let rampHeadY = 50.0

/* ---- THE UNDERFLOOR ROAD, scene 10 -------------------------------------------
   Built from the author's approved plates, 2026-08-27:
     _MASTER_ramp_rough        facing the ramp   — wall LEFT,  posts RIGHT
     _MASTER_reverse_rough     facing away       — wall RIGHT, posts LEFT
     _wall_straight_*          straight elevation — coursing, light height, post spacing
     _reverse_rough_KUKHNYA-junction             — a branch curving off, signposted КУХНЯ
     SET-ROAD-02_crossroads_signposts            — a crossroads out in the post forest

   IT IS NOT A CORRIDOR. It is a forest of posts on stone footings standing in
   gravel under the whole house, with plank roads laid through it and signposts at
   the junctions naming the rooms overhead. The stretch beside the outer wall — the
   one with the grate and the ramp — is only the piece nearest home.

   HOW WIDE THE ROADWAY IS, IS A FACT ABOUT THE CAT. SH164 has him lie across it on
   the diagonal and close "almost the whole passage"; SH169 and SH170 have her try a
   gap at each shoulder and fail. So it is his length on the diagonal plus a gap at
   each side that falls short of what she and the scooter need. Typed as a round
   number it would stop being true the moment either of them was re-measured. */
let catSpan = vasyaH *. 0.85 /* his length ACROSS the road, lying on the diagonal */
let herPassing = frosyaHead *. 1.15 /* her head is her widest part, plus the bars */
/* THE GAPS ARE NEARLY NOTHING. The first pass sized them at most of what she needs,
   which made each shoulder gap a near-miss and pushed the road out to 13.5 — a
   carriageway. Author, 2026-09-01: "it's like a little plank road." The gaps only
   have to be VISIBLY there and obviously hopeless, which is a third of her width,
   and the road comes back to ten — two scooter lengths, a footpath. */
let catGap = herPassing *. 0.35
/* THE ROAD IS AS WIDE AS THE RAMP PLUS A WAY PAST IT. The ramp spans the full width of
   the floor opening — it IS the opening — and it lands on the wall side of the road,
   so the road has to carry it and still let her by. Sized from the cat alone it came
   out at 9.9, and then either the ramp covered the whole road or it had to be shrunk
   to a plank narrower than the hole it hangs in. Author, 2026-09-01: "this ramp is too
   narrow, and it has to span the full width of the opening anyway."
   The cat still works: his diagonal span is 6.8, so he closes all but a shoulder gap
   either side. */
/* THE RAMP SPANS THE OPENING AND SITS HARD AGAINST THE WALL, so the road has to be
   wider than the ramp by enough to walk round it. The bypass is what she needs to get
   past with the scooter, plus a bit — she should not have to thread it. */
let rampWidth = catSpan +. catGap *. 2.0
let roadWay = rampWidth +. herPassing *. 0.7
/* THE RAMP IS A WEDGE IN PLAN AS WELL AS IN SECTION. It spans the full width of the
   floor opening at its HEAD, because it is the opening; but nothing says it has to
   land that wide. It narrows on the way down, so its FOOT takes only the wall side of
   the road and she rides past on the other. That is what settles the argument between
   the two things that were both claiming the road's width: the cat sets the road, the
   opening sets the ramp's head, and the taper lets both be true. */
let rampFootWidth = rampWidth
/* THE PLANK ROAD IS A PATH LAID ON THE GROUND, NOT THE GROUND ITSELF. Author,
   2026-09-01: "the plank goes onto the road, and currently you made the whole road
   just the width of the plank... the rest of the space is just a bunch of the
   joists." Right — under the house is one gravel floor carrying a forest of posts,
   and the boards are a track laid across it near the wall. The first build made the
   boards the full width between wall and colonnade, which turned a path through a
   cellar into a corridor. */
let wallFace = hallWidth /. 2.0 -. 1.0 /* inner face of the hearth masonry, continued down */
let gravelWall = roadWay *. 0.25 /* narrow bank at the wall; the ramp crosses it */
/* THE GRAVEL IS A BYPASS, NOT A SECOND ROAD. Author, 2026-09-01: "there should be
   just a bit of a bypass, so you could go behind the board, but it should not be
   twice as wide as the board." So it is derived from what it is for — one of them
   walking past the boards — and not from a fraction of the roadway, which is how it
   ended up nearly as wide as the road itself. */
let gravelPost = herPassing *. 1.05
let planksFar = wallFace -. gravelWall /* the boards' wall-side edge */
let planksNear = planksFar -. roadWay
let postLine = planksNear -. gravelPost /* the FIRST post row; more stand beyond it */
/* THE POST GRID IS THE RULER, AND A ROAD IS ONE BAY. Author, 2026-09-01: "the road
   is between the joists. Your joists are too far apart. That's why the road is too
   wide." Exactly backwards from how this was built: the road was derived from the
   cat and the posts were then spaced off the road, so the bays came out enormous and
   every road looked like it spanned three of them. Post pitch, joist pitch and bay
   are ONE number now, and the boards run down the middle of a single bay. */
let bayPitch = roadWay *. 1.22
let postPitch = bayPitch
let joistPitch = bayPitch
let bulbPitch = roadWay *. 0.52
let roadMid = (planksFar +. planksNear) /. 2.0
/* THE ROAD RUNS PAST THE HOUSE. The domovoi hall is inside a bricked-up fireplace
   inside a human house, and this space is under the HUMAN floorboards — so it does
   not stop where the hall does. Scene 10 needs it not to: she rides away down it,
   turns somewhere out of sight and comes back, and the plates all show it receding
   to a vanishing point. Built to the hall's footprint it ended in a black wall a
   few body-lengths past the ramp. */
/* THE ROAD IS NOT INFINITE. It runs the fireplace's own footprint and stops at the
   fireplace's own masonry, continued down — author, 2026-09-01. Built at 2.6x the hall
   it ran off into a void in both directions.

   The two ends are NOT the same. At the BACK the wall runs the full width, exactly as
   the back wall of the hearth does above it. At the FRONT it is only a stub, from the
   side wall as far as the first post row, and it ends there — past that the space is
   open for the other roads to run through. */
/* AND THEN IT GOES ON PAST THE HOUSE. The living room above ends at the hall's own
   length, but the crawl space does not — author, 2026-09-01: push the front wall back
   another twenty feet, so there is road beyond the КУХНЯ junction to ride into.
   Written in feet-at-build-scale, because that is the space the author is looking at:
   BUILD_SCALE puts Фрося at 1.25 m, so one built foot is 0.3048 / 0.1406 units. */
let builtFoot = 0.3048 /. 0.1406
/* THIRTY-FIVE FEET PAST THE HOUSE, not twenty. She rides away, turns out of sight and
   comes back — SH156 has the scooter recede, turn and approach again all off camera —
   and twenty left the far wall close enough to see from the ramp. Author, 2026-09-01:
   "I just want to make sure there is good space for her to do the laps." */
let roadRun = hallLength +. builtFoot *. 35.0

/* THE BRANCH IS AS WIDE AS THE GAP IT HAS TO FIT THROUGH. Taken as a fraction of the
   main road it came out at 7.2, which left half a unit of clearance past the post
   footings on the bend — clear on paper, touching on screen. Author, 2026-09-01: "the
   road needs to be slightly narrower so it could easily not touch the two joists."
   So: the clear span between two footings, less a quarter of it for margin. */
let footHalf = bayPitch *. 0.17
let branchWay = (bayPitch /. 2.0 -. footHalf) *. 1.1

/* THE RAMP IS NARROWER THAN THE ROAD IT LANDS ON. Off the ramp plate it is a little
   under half the road's width, hugging the wall side, with the rest of the boards left
   clear to walk past it. Built 13 wide against a 9.95 road it covered the road
   completely and blocked the whole length of its run — author, 2026-09-01: "either the
   ramp is too wide, which is probably what it is, or the road is too narrow."
   Derived from the road so it can never again be wider than the thing it lands on. */
/* HARD AGAINST THE WALL. The hearth's masonry runs straight down and the ramp leans on
   it — there is no gravel strip behind it. Anchored to the road's edge instead it stood
   off the wall by a gravel width, which is not what the plate shows and not what we
   agreed. Author, 2026-09-01: "it steps in from the wall when it should be completely
   against the wall." */
let rampX = wallFace -. rampWidth /. 2.0

/* THE DUST IS LEVEL WITH THE BOARDS. The gravel bed was laid a plank's thickness below
   the road, so the boards stood proud of it like a stage and anything crossing between
   them dropped through. Author, 2026-09-01: "the ramp goes through the boards to the
   grey area — raise that dust area so it's on the same level as the floorboards."
   Its top now matches theirs; the boards are bedded IN the gravel, not on it. */


/* RAMP RAILING. Author, 2026-09-01: "put a couple of posts as a ramp railing...
   at the normal railing height, since we're doing it all in human measurements."
   A guardrail is set by where a standing adult's hand falls, which is a bit over
   half their height — 0.53 of Папа puts it at 0.85m once BUILD_SCALE is applied,
   a normal rail. Derived off him so it cannot drift if his height is re-measured. */
let railHeight = papaH *. 0.53

let landmarks = [
  /* --- the KITCHEN END, y small ------------------------------------------- */
  {name: "STOVE", x: 29.3, y: 2.4, z: 0.0, w: 0.34 *. mamaH, d: 0.28 *. mamaH, h: counter *. mamaH +. 4.6,
   note: "the stove sits IN THE CORNER, touching both the back wall and the side wall. It is a plinth up to the counter line with the FIREBOX ABOVE IT — the lit arch is above the counter surface, not down at floor level — and the flue climbs the wall from the top of the firebox. SET-HOME-ROOM-02"},
  {name: "CHEST NICHE", x: -31.5, y: 12.0, z: 0.0, w: 1.0, d: 0.45 *. papaH, h: 0.50 *. papaH,
   note: "the niche is in the LEFT wall, in front of the couch, and holds the chest — a recess reaching Папа's waist, not a doorway"},

  /* --- the BED WALL, -x, running up toward the table ------------------------ */
  {name: "HATCH DOOR", x: -31.5, y: 60.0, z: 2.6, w: 1.2, d: headPapaW *. 1.25, h: papaH *. 0.62,
   note: "Яга's little iron door — a HATCH, not a doorway. Its sill sits 2.6 OFF THE FLOOR and it stands about 62% of Папа, so anyone using it steps up and stoops through; it must never read as a door you walk through upright. It was full doorway height and sitting on the floor. Sits between the cradle and the beds and overlaps neither. Author, 2026-08-31"},

  /* --- the RAMP WALL, +x --------------------------------------------------- */
  {name: "FLOOR OPENING", x: rampX, y: rampHeadY +. openingLen /. 2.0, z: 0.0, w: rampWidth, d: openingLen, h: 0.0,
   note: "the rope-railed opening in the boards. It is WIDER than the board — 13 against 7.62 — so you can see down past the ramp to the road below. At 9 wide the board filled it and the hole read as a shallow notch in the floor rather than a way down. Author, 2026-08-31"},
  {name: "RAMP HEAD", x: rampX, y: rampHeadY, z: 0.0, w: rampWidth, d: 3.0, h: 0.0,
   note: "the top of the warped board, at the KITCHEN end of the opening, level with the floorboards — this is where she rides on"},
  {name: "RAMP", x: rampX, y: rampHeadY +. rampRun /. 2.0, z: -.rampDrop /. 2.0, w: rampWidth, d: rampRun, h: rampDrop,
   note: "the warped board. It spans the FULL WIDTH of the opening — a board narrower than its hole left daylight down both sides and read as a plank dropped into a pit rather than a way down. Its top face is flush with the floorboards at the head, so there is no lip to ride over. Author, 2026-08-31"},
  {name: "RAMP FOOT", x: rampX, y: rampHeadY +. rampRun, z: -.rampDrop, w: rampWidth, d: 3.0, h: 0.0,
   note: "the bottom of the board where it meets the underfloor road. SET-ROAD-01 fixes the depth: at least 5.0in / 12.7cm of clear standing room under the joists — one full adult height, a walkable corridor and never a crawl gap"},

  /* --- the TABLE END, y large ---------------------------------------------- */
  {name: "KITCHEN SHELF", x: 8.0, y: 2.0, z: noseOf(mamaH, headMamaW), w: 15.0, d: 1.5, h: 0.4,
   note: "the long shelf of cups and pots over the work bench, at Мама's NOSE — she can see the surface and set a pot on it. It used to hang above her fingertips at full stretch"},
  {name: "WALL SHELF", x: 29.4, y: 106.5, z: noseOf(mamaH, headMamaW), w: 3.2, d: 9.0, h: 0.4,
   note: "the little shelf of metal cups on the ramp wall, RUNNING RIGHT INTO THE CORNER where it meets the iron wall — it stopped 5.5 short of it. A LEDGE projecting 3.2 from the wall face, at Мама's nose. Author, 2026-08-31"},
  {name: "IRON WALL", x: 0.0, y: 112.0, z: 0.0, w: 64.0, d: 2.0, h: 50.0,
   note: "the riveted iron plate sealing the old fireplace — the far wall"},
]

/* usual places; a shot may move any of these */
let bedLen = papaH *. 1.15 /* the longest sleeper sets the one box size */

/* THE ROW'S SPACING DERIVES TOO. Bed WIDTH was derived and the bed POSITIONS
   were typed at a fixed 8 apart, so when the boxes widened to clear Папа's head
   the gaps shrank from 2.5 to 1.3 and they read as shoved together again.
   Author, 2026-08-31: "didn't we already fix this?" We had — for one width. */
let bedW = headPapaW *. 1.25
let bedGap = 2.5
let bedPitch = bedW +. bedGap
/* THE BED WALL READS, FROM THE KITCHEN END: cradle, hatch, beds — and the run
   sits toward the iron end, the way SET-HOME-ROOM-01 has it. The hatch moves
   with the beds and the cradle sits beside it. Author, 2026-08-31. */
let bedY = n => 70.0 +. float_of_int(n) *. bedPitch

/* The ARMCHAIRS and LOW TABLE are out of the set for now. Built as one solid
   10.8cm box in the middle of the floor they read as a grey block, not
   furniture, and they stood in the traffic between the table and the road
   mouth. Author, 2026-08-31: "I have no idea what is this huge gray block in
   the middle of a room. You have to get rid of that." They come back as two
   separate chairs against the play-area wall when that corner is dressed. */
let furnishings = [
  /* ONE BOX FOR EVERYONE. Author, 2026-08-31: "let's make them all the same
     size, because based on our mythology, they are made out of really large
     match boxes for the ones with huge matches." So the size is set by the
     longest sleeper — Папа at 11.43 — and the other three simply have room to
     spare, which is what an identical salvaged box would give them.

     SPACING: 2.5cm between boxes and 3 clear at each end of the row. They were
     butted together with half a centimetre between them, which reads as one
     long bench rather than four beds. Author, 2026-08-31. */
  {name: "PAPA BED", x: -31.0 +. bedLen /. 2.0, y: bedY(0), z: 0.0, w: bedLen, d: bedW, h: 2.2, note: "long-match box, head to the wall"},
  {name: "MAMA BED", x: -31.0 +. bedLen /. 2.0, y: bedY(1), z: 0.0, w: bedLen, d: bedW, h: 2.2, note: "long-match box, head to the wall"},
  {name: "FROSYA BED", x: -31.0 +. bedLen /. 2.0, y: bedY(2), z: 0.0, w: bedLen, d: bedW, h: 2.2, note: "long-match box, head to the wall — one of the beds you see over Мама's shoulder from the table"},
  {name: "VASYA BED", x: -31.0 +. bedLen /. 2.0, y: bedY(3), z: 0.0, w: bedLen, d: bedW, h: 2.2, note: "long-match box, head to the wall; he sleeps across it, as scene 14 has him"},

  /* GEOGRAPHY FROM SET-HOME-ROOM-02, the plate that looks back from the iron
     wall at this end. Its camera faces -y, so screen-LEFT is +x:
       stove, the two armchairs and the round table are all on the +x side,
       the couch and the play rug are on -x.
     They were mirrored, and the rug was round. Author, 2026-08-31: "you
     basically flipped them and the rug is square, not circular." */
  {name: "STOVE COUNTER", x: 13.8, y: 2.5, z: 0.0, w: 27.6, d: 3.0, h: counter *. mamaH,
   note: "the long work counter, butting straight into the stove with no gap and running the back wall as far as the couch — kettles and pots on top, the coloured thread spools stored underneath"},
  /* D-EP1-SCOOTER-01: deck 2.00 x 0.45in, wheels 0.42in across. The bar is no
     longer a typed inch figure — see barHeight. The object the whole scene
     turns on. */
  {name: "SCOOTER", x: 6.3, y: 36.2, z: 0.0, w: 1.6, d: 5.08, h: barHeight,
   note: "Фрося's kick scooter, staged off the author's plan sketch #3: out in the hall with a real run at the opening, angled across to the ramp mouth so she rolls and turns onto the head rather than starting on it"},
  {name: "CHAIR NEAR", x: 14.0, y: 16.0, z: 0.0, w: 5.0, d: 5.0, h: chairBack *. frosyaH,
   note: "one of the two patterned tub chairs; it faces its pair across the round table, in front of the stove counter"},
  {name: "CHAIR FAR", x: 26.0, y: 16.0, z: 0.0, w: 5.0, d: 5.0, h: chairBack *. frosyaH,
   note: "the other tub chair, facing back the other way"},
  {name: "OLD TABLE", x: 20.0, y: 17.5, z: 0.0, w: 4.6, d: 4.6, h: 1.75 *. inch,
   note: "the round table on its braided-rope pedestal, between the two chairs. NOT the plank table — that one is a plank across two spools at the iron wall"},
  {name: "PLAY RUG", x: -18.0, y: 13.0, z: 0.0, w: 13.0, d: 13.0, h: 0.15,
   note: "the SQUARE woven rug the toys live on — the yarn ball, the basket and the box sit on it. It lies just in front of the COUCH, not out by the hatch and never anywhere near the ramp. Author, 2026-08-31"},
  {name: "COUCH", x: -20.0, y: 2.9, z: 0.0, w: sideBySide(3, headMamaW) +. 1.6, d: 4.6, h: couchBack *. mamaH,
   note: "the couch against the back wall with the flowered rug over it. Sized to seat THREE BY THE HEAD, not by the shoulder — three of Мама's heads with air between them, plus two arms"},
  {name: "CRADLE", x: -29.0, y: 50.0, z: 0.0, w: 5.0, d: 5.0, h: 0.50 *. mamaH,
   note: "the knitted cradle on its crossed stand, sitting NEXT TO THE HATCH at the kitchen side of it — the bed wall reads cradle, hatch, then the four beds"},
  /* FOUR BEDS — everyone their own matchbox, re-locked by the author 2026-08-07
     and again 2026-08-31. Not a shared parental bed.

     A BED IS LONGER THAN ITS SLEEPER, so they are four different lengths rather
     than one size: Папа is 11.43 and a 10.5 box is shorter than he is. Heads to
     the wall, feet into the room, so the longest bed is the one that fixes the
     wall. The babies need no cot — scene 14 has them asleep on Мама. */
  {name: "BASIN STOOL", x: 29.0, y: 106.0, z: 0.0, w: 1.91, d: 1.91, h: 0.75 *. inch,
   note: "R-HOME-STOOL-01, a cut wine-cork stool, 0.75in high. The small red stool with the wash basin, on the right wall under the shelf, in the corner"},
  /* THE TABLE'S NIGHT POSITION IS A CLEARANCE THE ROOM HAS TO HOLD. At night it
     is turned a quarter and stood long-side against the ramp wall under the
     shelf, so the beds can be reached. That means the strip between the ramp
     railing and the riveted plate must take the table's LONG side plus room to
     walk past it. Author, 2026-08-31: "big enough for them to take that table
     that's on two spools, rotate it, and put the long side against the wall
     comfortably there under the shelf."

       railing (opening far edge)  y  85.2
       iron plate inner face       y 111.0
       strip available                25.8
       table long side                15.1
       left to walk past               10.7   */
  {name: "TABLE", x: 0.0, y: 98.0, z: 0.0, w: 15.1, d: 6.5, h: 2.75,
   note: "the plank-on-spools family table in front of the sealed iron wall. HEIGHT IS SET BY THE SEATED BODY, NOT THE STANDING ONE. At 4.45 the top landed just under Мама's chin, because their legs are stubs and sitting drops them almost not at all. A table wants to be at the elbow: pouf 1.4 plus 46% of the seated shoulder rise = 2.75. The pouf itself is capped by the LEGS — it can be no taller than knee-to-floor or their feet leave the boards. Author: build a table and sit them at it and see how that works out"},
  {name: "COASTER RUG", x: -7.0, y: 93.0, z: 0.0, w: 13.0, d: 13.0, h: 0.15,
   note: "a woven drink coaster used as a round rug — the babies' patch, beside Мама and in front of the table. Round, and big enough for both of them with room to play, as 2026-08-22_S8_SHOT1_table_start has it"},
  {name: "CUSHION A", x: -9.6, y: 98.0, z: 0.0, w: cushionR *. 2.0, d: cushionR *. 2.0, h: 1.4, note: "Мама's seat, the short end with her back to the matchbox beds"},
  {name: "CUSHION B", x: 9.6, y: 98.0, z: 0.0, w: cushionR *. 2.0, d: cushionR *. 2.0, h: 1.4, note: "Папа's seat, the opposite short end with his back to the little shelf"},
  {name: "CUSHION C", x: 0.0, y: 102.0, z: 0.0, w: cushionR *. 2.0, d: cushionR *. 2.0, h: 1.4, note: "Яга's seat, the long side with her back to the riveted plate, facing the room"},
]

/* which author plate a camera at each vantage is conditioned on */
let plateFor = (v: vantage): string =>
  switch v {
  | FromKitchen => "SET-HOME-ROOM-01_author_master_v4_hatch_cradle-clear.png"
  | FromIronWall => "SET-HOME-ROOM-02_author_far_wall_v2.png"
  | LowOnBoards => "SET-HOME-ROOM-01_author_low_angle.png"
  | AtTheHatch => "SET-HOME-ROOM-01_author_hatch_angle.png"
  }

/* ---- THE LOWER STOREY -----------------------------------------------------
   The house has two floors and the ramp is what joins them: the family's hall
   above, the underfloor road beneath it, sharing one slab. Author, 2026-08-30:
   "why don't we build it properly as two stories? We'll need that bottom story
   anyway once we're going to be doing the ramp, underground floorboards part of
   the story."

   Depth comes from a real crawl space — one foot, the minimum — so the road
   surface sits 30.5 cm under the boards. From the author's road plates: a plank
   floor (not concrete), the same giant sandstone blocks forming the wall on ONE
   side, and a colonnade of wooden posts carrying the joists on the other, with
   the hall's floorboards close overhead as the ceiling. */

/* EVERY HEIGHT DOWN HERE DERIVES FROM roadDrop. They used to be typed — 28 and
   27 — sized for a 30.5 drop, and when the drop changed to 14 they did not
   follow: a colonnade post stood 27cm tall and punched up through the boards
   beside the family table, wearing the wall grid, in the middle of a shot.
   2026-08-31. */
let joistTop = -.floorThickness /* joists hang under the boards */
let joistBase = joistTop -. joistDepth
let roadTop = -.roadDrop +. roadFloorT

/* THE LOWER STOREY IS THE SAME FOOTPRINT AS THE HOUSE. These were typed as
   90 x 260 and never followed the hall down from 120 x 200 to 54 x 75, so the
   road slab stuck out 18cm past each wall and 185cm past the ends — which read
   in a 3/4 view as a second floor beyond the room. Author, 2026-08-31: "why am
   I looking at two slabs of the floor?" 2026-08-31. */
let lowerStorey = [
  {name: "ROAD FLOOR", x: 0.0, y: roadRun /. 2.0, z: -.roadDrop, w: hallWidth, d: roadRun, h: roadFloorT,
   note: "the road surface running under the house, below the family's boards"},
  {name: "ROAD WALL", x: hallWidth /. 2.0, y: roadRun /. 2.0, z: -.roadDrop, w: 2.0, d: roadRun, h: roadDrop -. floorThickness,
   note: "the sandstone wall along the ramp side of the road. It sits DIRECTLY UNDER the hall's ramp wall and is the same thickness, so the wall simply continues down. It used to be 4cm thick and set 3cm inboard, which put it inside the floor opening — looking down the hole you met a wall that had stepped in, instead of seeing the road. Author, 2026-08-31"},
  {name: "POST FOREST", x: postLine, y: roadRun /. 2.0, z: roadTop, w: postPitch, d: roadRun, h: joistBase -. roadTop,
   note: "the posts carrying the joists. The builder reads x as the FIRST row nearest the boards and fills a GRID outward from it to the far wall, every postPitch in both directions — a forest, not a colonnade. Each post is timber on a stone footing standing in the gravel"},
  {name: "ROAD PLANKS", x: roadMid, y: roadRun /. 2.0, z: -.roadDrop +. roadFloorT +. gravelDepth, w: roadWay, d: roadRun, h: plankThickness,
   note: "the roadway itself: wide hand-laid salvage boards running ALONG the road, butted joins, open seams, nail heads. It is only this wide — everything either side of it is gravel"},
  {name: "ROAD FAR WALL", x: -.hallWidth /. 2.0, y: roadRun /. 2.0, z: -.roadDrop +. roadFloorT, w: 2.0, d: roadRun, h: roadDrop -. floorThickness,
   note: "the far side of the crawl space, past the post forest, running the road's whole length and meeting the back wall in the corner. It was simply missing — the space had a wall on the ramp side, a wall at the back and a stub at the front, and NOTHING out beyond the posts, so it stood open to the void and the world lit it from a direction that has no source. Author, 2026-09-01: \"does the underground floorboard space have walls on all the sides? Because if it doesn't, I don't know what we're doing\""},
  {name: "ROAD BACK WALL", x: 0.0, y: 0.0, z: -.roadDrop +. roadFloorT, w: hallWidth, d: 2.0, h: roadDrop -. floorThickness,
   note: "the hearth's back wall carried down below the boards. It spans the WHOLE width, right to left, and closes that end of the road"},
  {name: "ROAD FRONT WALL", x: (wallFace +. postLine) /. 2.0, y: roadRun, z: -.roadDrop +. roadFloorT, w: wallFace -. postLine, d: 2.0, h: roadDrop -. floorThickness,
   note: "the front end, and only a STUB: it reaches from the side wall as far as the first post row and stops. Beyond it the crawl space is open, which is where the other roads go"},
  {name: "GRAVEL BED", x: 0.0, y: roadRun /. 2.0, z: -.roadDrop +. roadFloorT, w: hallWidth, d: roadRun, h: gravelDepth +. plankThickness -. 0.04,
   note: "the gravel floor of the whole crawl space. Its top sits a HAIR below the boards — level to the eye, but not coplanar. Exactly level, the two surfaces z-fought and the renderer picked between them at random, which read as grey boards laid among the timber ones. Author, 2026-09-01: \"why is there a board in the middle that's gray like the gravel\". It runs wall to wall; the plank road is laid ON it and the posts stand IN it. Every road plate shows gravel wherever there are no boards"},
  /* THE КУХНЯ JUNCTION, off SET-ROAD-01_author_reverse_rough_KUKHNYA-junction.
     The plank road forks: a narrower branch curves away from the wall, in between
     the posts, and a signpost at the fork names where it goes. The underfloor is a
     NETWORK — the crossroads plate has three more arms, ГОСТИНАЯ / ДЕТСКАЯ /
     СПАЛЬНЯ one way and КРЫЛЬЦО the other — and this is the arm scene 10 can see.

     IT FORKS PAST THE RAMP FOOT, not before the ramp head. Built on the kitchen
     side it sat at y=46, which is the correct side for the kitchen and the wrong
     side for everything else: the ramp lands at y=83, and the road back to y=46
     runs UNDER the ramp, where the headroom closes to nothing at the foot. The fork
     was on a stretch of road no one could reach. Author, 2026-09-01: "you either
     put the junction on the wrong end of the road or we're looking at it from the
     wrong side." Wrong end. It belongs where the road runs free, which is also the
     way she rides in scene 10 — so the fork is on her route rather than behind her. */
  {name: "KUKHNYA BRANCH", x: planksNear, y: rampHeadY +. rampRun +. (roadRun -. rampHeadY -. rampRun) *. 0.62, z: -.roadDrop +. roadFloorT +. gravelDepth, w: branchWay, d: roadWay *. 2.6, h: 0.55,
   note: "the branch road to the kitchen, set two thirds of the way down her run rather than just past the ramp — she passes it mid-lap instead of the moment she lands. The builder slides it along until its straight leg crosses the post row midway between two posts, so moving it costs nothing. it leaves the main boards at their near edge and curves away from the wall between the posts, narrower than the road it leaves"},
  {name: "KUKHNYA SIGN", x: planksNear -. 1.6, y: rampHeadY +. rampRun +. (roadRun -. rampHeadY -. rampRun) *. 0.62 +. 3.0, z: -.roadDrop +. roadFloorT +. gravelDepth, w: 0.7, d: 0.7, h: railHeight,
   note: "the signpost standing in the gravel at the fork, an arrow board on a stick pointing down the branch. КУХНЯ. SAME HEIGHT AS THE RAILING MATCHSTICKS upstairs — author, 2026-09-01: it must not be taller than Фрося, and it reads as the same salvaged stick the rope fence is built from. Its twin at the crossroads carries three arms"},
  {name: "ROAD GRATE", x: wallFace -. 0.3, y: rampHeadY +. rampRun +. 6.0, z: -.roadDrop +. roadFloorT +. 2.2, w: 0.6, d: 4.4, h: 4.0,
   note: "the small iron grate set low in the stone wall a little past the ramp foot — the cleanout hatch seen from underneath. It appears in the ramp plate and the straight elevation"},
  {name: "JOISTS", x: 0.0, y: roadRun /. 2.0, z: joistBase, w: hallWidth, d: roadRun, h: joistDepth,
   note: "the joists under the hall's floorboards, running across the road as its ceiling"},
]

/* the datum the two storeys share */
let roadDatum = [
  {name: "ROAD SURFACE", x: 17.2, y: 56.2, z: -.roadDrop, w: 60.0, d: 120.0, h: 0.0,
   note: "the underfloor road the ramp lands on; the crawl space ceiling is the family's floorboards above it"},
]
