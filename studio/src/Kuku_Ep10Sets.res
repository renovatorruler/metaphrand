/* Kuku_Ep10Sets.res — the SET BIBLE for EP10.

   Sets drifted because they existed only as prose: every generation reinvented
   the geography. Here a set is DATA — landmarks at fixed positions on a plan —
   and three things are derived from that one source:

     1. a blueprint (SVG plan view) the author approves before anything is spent
     2. the canonical prose the prompt engine emits (never hand-written per shot)
     3. the reference-plate paths a shot attaches, chosen by camera vantage

   The plan coordinate system is metres on a top-down map: +x runs across the
   set, +y runs DOWN the lane (away from the courtyard). Elevation is metres
   above the flat stretch, so the lane's slope is real data, not an adjective. */

type set = Courtyard | Lane | FlatStone | Tower | Doorway | GrassVerge

/* where a camera stands for a shot; a plate exists per (set, vantage) */
type vantage =
  | TopLookingDown /* at the post, looking down the lane */
  | BottomLookingUp /* at the wall, looking back up */
  | Overhead /* high above, looking down */
  | GroundLevel /* standing in the set, eye height */
  | AtTheRing /* courtyard: facing the flight ring */

type landmark = {
  name: string,
  x: float, /* metres across */
  y: float, /* metres down the lane */
  z: float, /* metres above the flat */
  note: string,
}

/* ---- the LANE: the episode's spine ---------------------------------------- */
/* 60 m of straight downhill flagstone. The post is the rope point at the top;
   three markers sit ON the centreline at even 12 m intervals; the last 12 m is
   flat; a closed stone wall ends it. Every lane shot is somewhere on this line. */
let laneLength = 60.0
let laneWidth = 8.0
let laneDrop = 9.0 /* metres of fall from post to flat */

let laneLandmarks = [
  {name: "STONE POST", x: -4.6, y: 0.0, z: laneDrop, note: "the rope tie-point at the top of the slope, on the LEFT kerb"},
  {name: "CART START", x: 0.0, y: 2.0, z: laneDrop *. 0.97, note: "where the tethered cart stands"},
  {name: "MARKER 1", x: 0.0, y: 12.0, z: laneDrop *. 0.75, note: "first distance mark: a broad red band PAINTED flat across the lane's paving — colour on the road surface itself, part of the flagstones, smooth under any wheel"},
  {name: "MARKER 2", x: 0.0, y: 24.0, z: laneDrop *. 0.5, note: "second distance mark: a broad red band PAINTED flat across the lane's paving — colour on the road surface itself, part of the flagstones, smooth under any wheel"},
  {name: "MARKER 3", x: 0.0, y: 36.0, z: laneDrop *. 0.25, note: "third and last distance mark: a broad red band PAINTED flat across the lane's paving — colour on the road surface itself, part of the flagstones, smooth under any wheel"},
  {name: "FLAT BEGINS", x: 0.0, y: 48.0, z: 0.0, note: "the slope ends; the last 12 m is level"},
  {name: "GA-STONE", x: 0.0, y: 55.0, z: 0.0, note: "the flat stone where the golden ga-shape is forged"},
  {name: "END WALL", x: 0.0, y: 60.0, z: 0.0, note: "closed paper stone wall across the full width, its face plain bare stone from kerb to kerb — the lane is a dead end"},
]

let courtyardLandmarks = [
  /* The bell belongs to the ring — the screenplay hangs it there («उससे काँसे की
     घंटी लटक रही है»), steals it from there («उड़ान-घेरे से … खोल लेती है»), and pays
     it off there («खाली उड़ान-घेरे … केवल खुला हुक हिल रहा है»). It is one landmark,
     not two, so no shot can put the bell anywhere else. */
  {name: "FLIGHT RING", x: 0.0, y: -18.0, z: laneDrop, note: "a COMPLETE CIRCLE of stone standing upright on its edge, built of layered paper arcs and UNBROKEN ALL THE WAY ROUND, its lowest point meeting the courtyard flagstones — FOURTEEN METRES across, wide enough for an enormous dragon to fly through with wings spread, a full closed circle. A SHORT BRONZE HOOK is fixed to the inside of its crown, reaching down into the ring's opening"},
  /* Named "MARKED FLAGSTONE" once, and the model carved runes into it — the same
     way "CAMERA" drew a tripod. A landmark's NAME is prompt text: it must never
     name a property we do not want rendered. */
  {name: "LAUNCH CIRCLE", x: 0.0, y: -12.0, z: laneDrop, note: "where a dragon stands to begin her flight: a circle of plain flagstones laid in rings, every stone BLANK and uncarved, plain smooth paper faces"},
  {name: "TEMPLE GATEWAY", x: 0.0, y: -30.0, z: laneDrop, note: "far behind the ring, the paper temple gateway"},
  {name: "TOWER", x: 16.0, y: -26.0, z: laneDrop +. 14.0, note: "चील's closed stone tower, off to the RIGHT and high"},
  {name: "LANE HEAD", x: 0.0, y: 0.0, z: laneDrop, note: "the courtyard's edge, where the lane begins"},
]

let landmarksOf = s =>
  switch s {
  | Lane => laneLandmarks
  | Courtyard => courtyardLandmarks
  | FlatStone => Js.Array2.filter(laneLandmarks, l => l.y >= 44.0)
  | Tower => [
      {name: "PARAPET", x: 16.0, y: -26.0, z: laneDrop +. 14.0, note: "where चील perches, looking DOWN-LEFT at the courtyard"},
      {name: "TOWER DOOR", x: 16.0, y: -24.0, z: laneDrop +. 10.0, note: "tall closed stone door in the tower face"},
    ]
  | Doorway => [
      {name: "THE DOORWAY", x: 0.0, y: 0.0, z: 0.0, note: "the golden arch standing free between the worlds"},
      {name: "VILLAGE BEYOND", x: 0.0, y: 4.0, z: 0.0, note: "seen THROUGH the arch: दादी's village courtyard"},
    ]
  | GrassVerge => [
      {name: "GRASS PATCH", x: -9.0, y: 6.0, z: laneDrop *. 0.9, note: "गौरी's grazing patch, LEFT of the lane head"},
      {name: "LANE (BEYOND)", x: 0.0, y: 6.0, z: laneDrop *. 0.9, note: "the lane visible past her"},
    ]
  }

let setName = s =>
  switch s {
  | Courtyard => "courtyard"
  | Lane => "lane"
  | FlatStone => "flat_stone"
  | Tower => "tower"
  | Doorway => "doorway"
  | GrassVerge => "grass_verge"
  }

let vantageName = v =>
  switch v {
  | TopLookingDown => "top_looking_down"
  | BottomLookingUp => "bottom_looking_up"
  | Overhead => "overhead"
  | GroundLevel => "ground_level"
  | AtTheRing => "at_the_ring"
  }

/* the camera description that goes into a prompt, derived — never typed per shot */
let vantageProse = (s, v) =>
  switch (s, v) {
  | (Lane, TopLookingDown) => "we look from the stone post at the TOP of the lane, at head height, looking straight DOWN the slope: the three red markers recede away from us along the centreline, the flat stretch and the closed stone wall are visible far below"
  | (Lane, BottomLookingUp) => "we look from the flat stretch at the BOTTOM of the lane, at head height, looking back UP the slope: the markers climb away from us, the stone post and the courtyard edge at the top of frame"
  | (Lane, Overhead) => "we look from high above the lane, straight DOWN: the lane runs top-to-bottom through the frame, the three red markers evenly spaced on its centreline, the closed wall across the bottom"
  | (Lane, _) => "we look from beside the lane at head height, the slope running left to right across frame, the markers on its centreline"
  | (Courtyard, AtTheRing) => "we look from the courtyard flagstones, facing the great stone flight ring, the bronze bell hanging from the inside of the ring's crown, the temple gateway far behind the ring"
  | (Courtyard, Overhead) => "we look from high above the courtyard, down: the ring, the launch circle, and the head of the lane running away"
  | (Courtyard, _) => "we look from the courtyard flagstones at head height, the flight ring in view"
  | (FlatStone, BottomLookingUp) => "we look from low on the flat stretch, back up the lane, the closed stone wall behind us"
  | (FlatStone, _) => "we look from low and close on the flat stone at the end of the lane, the closed stone wall behind it"
  | (Tower, _) => "we look up at the tower parapet from below and to the left, the courtyard far beneath"
  | (Doorway, _) => "we face the standing golden arch square-on, the village courtyard visible through it"
  | (GrassVerge, _) => "we look from the grass verge at head height, the lane beyond"
  }

/* Set prose scoped to what the CAMERA CAN SEE. Listing every landmark on a 60 m
   lane inside a five-second close beat is noise the model has to reconcile —
   the same class of mistake as naming five dragons in a two-character shot. */
let setProseFor = (s, names) => {
  let chosen = Js.Array2.filter(landmarksOf(s), l => Js.Array2.includes(names, l.name))
  let lm = Js.Array2.joinWith(Js.Array2.map(chosen, l => l.name ++ " (" ++ l.note ++ ")"), "; ")
  switch s {
  | Courtyard => "THE FLIGHT COURTYARD — an open paper-flagstone courtyard at the top of the lane. In this shot: " ++ lm
  | Lane => "THE LANE — the gurukul's straight downhill flight-courtyard slope of paper flagstones with low paper kerbs both sides. In this shot: " ++ lm
  | FlatStone => "THE FLAT STONE — the level last stretch at the bottom of the lane. In this shot: " ++ lm
  | Tower => "THE TOWER — चील's closed paper stone tower. In this shot: " ++ lm
  | Doorway => "THE THRESHOLD — the golden paper doorway between the worlds. In this shot: " ++ lm
  | GrassVerge => "THE GRASS VERGE — the paper-grass patch beside the head of the lane. In this shot: " ++ lm
  }
}

/* canonical prose for the set, derived from the landmark table */
let setProse = s => {
  let lm = Js.Array2.joinWith(Js.Array2.map(landmarksOf(s), l => l.name ++ " (" ++ l.note ++ ")"), "; ")
  switch s {
  | Lane =>
    "THE LANE — the gurukul's straight downhill flight-courtyard slope of paper flagstones, " ++
    Belt.Float.toString(laneLength) ++
    " m long and " ++
    Belt.Float.toString(laneWidth) ++
    " m wide, falling " ++
    Belt.Float.toString(laneDrop) ++
    " m from top to bottom, with low paper kerbs on both sides. Fixed landmarks, always in these places: " ++ lm
  | Courtyard =>
    "THE FLIGHT COURTYARD — an open paper-flagstone courtyard at the top of the lane. Fixed landmarks, always in these places: " ++ lm
  | FlatStone => "THE FLAT STONE — the level last stretch at the bottom of the lane. Fixed landmarks: " ++ lm
  | Tower => "THE TOWER — चील's closed paper stone tower above and right of the courtyard. Fixed landmarks: " ++ lm
  | Doorway => "THE THRESHOLD — the golden paper doorway standing between the dragon world and the village. Fixed landmarks: " ++ lm
  | GrassVerge => "THE GRASS VERGE — the paper-grass patch beside the head of the lane. Fixed landmarks: " ++ lm
  }
}

/* ---- blueprint: a plan view rendered from the same data -------------------- */
let f = Belt.Float.toString

/* Two panels from one dataset: a PLAN (looking straight down) and an ELEVATION
   (looking from the side), so the fall of the lane is drawn, not described. */
let blueprint = s => {
  let lms = landmarksOf(s)
  let hasLane = s == Lane || s == Courtyard || s == FlatStone

  let ys = Js.Array2.map(lms, l => l.y)
  let minY = Js.Math.minMany_float(Js.Array2.concat(ys, hasLane ? [0.0] : []))
  let maxY = Js.Math.maxMany_float(Js.Array2.concat(ys, hasLane ? [laneLength] : []))
  let zs = Js.Array2.map(lms, l => l.z)
  let maxZ = Js.Math.maxMany_float(Js.Array2.concat(zs, [1.0]))

  let w = 1240.0
  let top = 132.0
  let span = maxY -. minY
  let scale = Js.Math.min_float(17.0, 980.0 /. Js.Math.max_float(span, 1.0))
  let h = top +. span *. scale +. 90.0

  let planX = 250.0 /* plan centreline */
  let elevX = 900.0 /* elevation baseline (z = 0) */
  let zScale = 9.0

  let py = y => top +. (y -. minY) *. scale
  let px = x => planX +. x *. scale
  let ez = z => elevX +. z *. zScale

  let laneBody = hasLane
    ? "<rect x='" ++
      f(px(-.laneWidth /. 2.0)) ++
      "' y='" ++
      f(py(0.0)) ++
      "' width='" ++
      f(laneWidth *. scale) ++
      "' height='" ++
      f(laneLength *. scale) ++
      "' fill='#e9e1d0' stroke='#8a7f68' stroke-width='2'/>" ++
      "<line x1='" ++
      f(px(0.0)) ++
      "' y1='" ++
      f(py(0.0)) ++
      "' x2='" ++
      f(px(0.0)) ++
      "' y2='" ++
      f(py(laneLength)) ++
      "' stroke='#b9ad93' stroke-width='1' stroke-dasharray='7 7'/>" ++
      "<rect x='" ++
      f(px(-.laneWidth /. 2.0) -. 6.0) ++
      "' y='" ++
      f(py(laneLength)) ++
      "' width='" ++
      f(laneWidth *. scale +. 12.0) ++
      "' height='10' fill='#6d6151'/>"
    : ""

  /* elevation: the ground line through every landmark's height */
  let elevPath =
    hasLane
      ? {
          let pts = Js.Array2.joinWith(
            Js.Array2.map(Js.Array2.sortInPlaceWith(Js.Array2.copy(lms), (a, b) =>
                a.y < b.y ? -1 : 1
              ), l => f(ez(l.z)) ++ "," ++ f(py(l.y))),
            " ",
          )
          "<polyline points='" ++ pts ++ "' fill='none' stroke='#8a7f68' stroke-width='2.5'/>"
        }
      : ""

  let rows = Js.Array2.joinWith(
    Js.Array2.mapi(lms, (l, i) => {
      let cy = py(l.y)
      let cx = px(l.x)
      let isMarker = Js.String2.startsWith(l.name, "MARKER")
      /* markers are genuinely red in the world, so their map glyph is red; every
     other landmark is a quiet sand outline — a bold dark dot on the map kept
     being rendered as a coloured slab standing at that spot in the plate */
  let colour = isMarker ? "#c0392b" : "#b9ad93"
      let labelX = 470.0
      let labelY = cy +. (mod(i, 2) == 0 ? -1.0 : 13.0)
      "<circle cx='" ++
      f(cx) ++
      "' cy='" ++
      f(cy) ++
      "' r='" ++ (isMarker ? "8" : "6") ++ "' fill='" ++
      colour ++
      "'/>" ++
      (hasLane
        ? "<circle cx='" ++ f(ez(l.z)) ++ "' cy='" ++ f(cy) ++ "' r='4' fill='" ++ colour ++ "'/>"
        : "") ++
      "<line x1='" ++
      f(cx +. 10.0) ++
      "' y1='" ++
      f(cy) ++
      "' x2='" ++
      f(labelX -. 8.0) ++
      "' y2='" ++
      f(labelY -. 4.0) ++
      "' stroke='#cfc6b2' stroke-width='1'/>" ++
      "<text x='" ++
      f(labelX) ++
      "' y='" ++
      f(labelY) ++
      "' font-family='Helvetica' font-size='15' font-weight='bold' fill='#2c3e50'>" ++
      l.name ++
      "</text>" ++
      "<text x='" ++
      f(labelX) ++
      "' y='" ++
      f(labelY +. 15.0) ++
      "' font-family='Helvetica' font-size='11.5' fill='#7f8c8d'>" ++
      f(l.y) ++
      " m along · " ++
      f(l.z) ++
      " m up · " ++
      l.note ++
      "</text>"
    }),
    "",
  )

  "<svg xmlns='http://www.w3.org/2000/svg' width='" ++
  f(w) ++
  "' height='" ++
  f(h) ++
  "' viewBox='0 0 " ++
  f(w) ++
  " " ++
  f(h) ++
  "'>" ++
  "<rect width='100%' height='100%' fill='#fbf8f1'/>" ++
  "<text x='40' y='54' font-family='Helvetica' font-size='25' font-weight='bold' fill='#2c3e50'>EP10 SET BLUEPRINT — " ++
  Js.String2.toUpperCase(setName(s)) ++
  "</text>" ++
  "<text x='40' y='80' font-family='Helvetica' font-size='13.5' fill='#7f8c8d'>metres. LEFT: plan, looking straight down; the lane runs down the page away from the courtyard." ++
  (hasLane ? "  RIGHT: elevation, looking from the side; the line is the ground falling " ++ f(maxZ) ++ " m." : "") ++
  "</text>" ++
  "<text x='" ++
  f(planX -. 46.0) ++
  "' y='" ++
  f(top -. 16.0) ++
  "' font-family='Helvetica' font-size='12' font-weight='bold' fill='#8a7f68'>PLAN</text>" ++
  (hasLane
    ? "<text x='" ++
      f(elevX -. 20.0) ++
      "' y='" ++
      f(top -. 16.0) ++
      "' font-family='Helvetica' font-size='12' font-weight='bold' fill='#8a7f68'>ELEVATION</text>" ++
      "<line x1='" ++
      f(elevX) ++
      "' y1='" ++
      f(top -. 8.0) ++
      "' x2='" ++
      f(elevX) ++
      "' y2='" ++
      f(h -. 70.0) ++
      "' stroke='#e0d8c6' stroke-width='1'/>"
    : "") ++
  laneBody ++
  elevPath ++
  rows ++
  "</svg>"
}

/* where an approved plate for (set, vantage) lives, relative to studio/ */
let plateDir = "../stories/kuku/ep10prod/sets/"
let platePath = (s, tag) => plateDir ++ setName(s) ++ "_" ++ tag ++ "_plate.png"
/* the set's own establishing plate, with no vantage suffix */
let masterPlate = s => plateDir ++ setName(s) ++ "_plate.png"

/* which lane plate covers a point on the lane: the survey walked the centreline,
   so a shot's position along the lane picks its vantage plate deterministically */
/* Only plates that survived verification are listed. The first lane survey's
   two mid-lane frames were rejected: a forward dolly toward the dead-end wall
   made the wall breathe (approach, recede, approach), so those frames disagree
   with each other about how long the lane is. They are quarantined on disk as
   SUSPECT_*. Until a bounded re-survey replaces them, a mid-lane shot takes the
   nearest verified plate rather than an unverified one. */
let lanePlateAt = y =>
  if y < 30.0 {
    platePath(Lane, "top_looking_down")
  } else {
    platePath(Lane, "flat_approach")
  }

/* ---- progression: where a shot sits on the lane ---------------------------
   A chase reads only if the ground moves under it. These sentences are derived
   from the same metric table the blueprint and plates come from, so a shot
   cannot claim a position the set does not have. */
let markerPositions = [12.0, 24.0, 36.0]

/* A great-form dragon is wider than the lane is — but she is three times longer
   than she is wide, so the fix is ORIENTATION, not a wider set: turned along the
   lane she fits inside it; turned broadside she cannot, and her body goes
   through the wall. That was the real cause of the wall-clipping, and it costs
   nothing to fix. */
let greatFormFraming = "FRAMING FOR AN ENORMOUS DRAGON: play this WIDE. The viewpoint stands far enough back that the whole width of the lane, both kerbs and a good band of sky sit in frame, with clear space above and behind the dragon, his whole body inside the picture with open air around it. When he shares the shot with the cart, the two sit SEPARATED across the frame — dragon to one side, cart to the other, each whole and distinct."

/* The bell is STORY STATE, never set data: it hangs on the ring's hook until
   चील takes it, and after that the hook hangs bare. Fusing the bell into the
   ring's landmark note (2026-08-27, briefly) put a bell into post-theft frames
   the screenplay pays off as empty. mk() injects one of these by the clock. */
let bellOnRing = "THE BRONZE BELL hangs inside the ring's crown, fastened by its bronze binding to the short hook there, down into the opening — SMALL, about ONE METRE tall, a hand-bell against the fourteen-metre ring, light enough for an eagle to lift away in her talons"
let hookBare = "THE HOOK INSIDE THE RING'S CROWN HANGS BARE — a short bronze hook over empty air, swinging gently, the space beneath it open sky. The ring carries only itself"

let greatFormStaging = "ORIENTATION IN THE LANE: this dragon is far longer than she is wide, and the lane is " ++ Belt.Float.toString(laneWidth) ++ " metres between its kerbs. She lies ALONG the lane: her long axis runs parallel to it, nose forward in the direction of travel, body and tail trailing back up the slope behind her, her whole length inside the lane. Her wings are swept back along her body or held HIGH above the kerb line. Every part of her — body, tail, wings and limbs — stays between the kerbs, in open air, clear of kerb and wall."

let lanePosition = (at, cartAt) => {
  let behind = Js.Array2.length(Js.Array2.filter(markerPositions, m => m < at))
  let ahead = Js.Array2.length(markerPositions) - behind
  let toWall = laneLength -. at
  let base =
    "POSITION ON THE LANE: this shot happens " ++
    Belt.Float.toString(at) ++
    " metres down the " ++
    Belt.Float.toString(laneLength) ++
    " metre lane. Of the three red markers, " ++
    Belt.Int.toString(behind) ++
    " are already BEHIND this point and " ++
    Belt.Int.toString(ahead) ++
    " still lie AHEAD down the slope. The closed end wall is " ++
    Belt.Float.toString(toWall) ++ " metres further on — far down the lane, a distant line."
  switch cartAt {
  | None => base
  | Some(c) =>
    base ++
    " THE CART is " ++
    Belt.Float.toString(c) ++
    " metres down the lane at this moment — " ++
    Belt.Float.toString(laneLength -. c) ++
    " metres from the wall — and is still running."
  }
}
