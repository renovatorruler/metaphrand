// KukuEp10_Shots.res — every shot of «द से दीया», staged against the one plate.
//
// THE LAW OF THIS FILE (audit, 2026-09-04). Every inconsistent frame in the first
// build traced to prose the type system allowed: one "doing" string stamped on
// every cast member, so a character's own line described the group or somebody
// else; small/great form asserted in two places that disagreed; the dead lamp
// named so it could be forbidden; the letter described as a shape the model then
// drew. So:
//   · cast is an array of castEntry — each member carries ITS OWN pose and form;
//     there is no shared string to stamp;
//   · form drives the prose, the scale rule and the board from one value;
//   · the lamp is a typed state derived from the light; Cold means ABSENT — the
//     prompt names a bare shelf, never a cold lamp;
//   · the letter is a VFX layer; the model renders only its LIGHT;
//   · PromptGate's strict law refuses any prompt that breaks these in text.
//
//   node src/KukuEp10_Shots.res.mjs gate      # every finding, no spend
//   node src/KukuEp10_Shots.res.mjs list
//   node src/KukuEp10_Shots.res.mjs still <id> | stills | clip <id>

@module("fs") external existsSync: string => bool = "existsSync"
@module("fs") external mkdirSync: (string, {"recursive": bool}) => unit = "mkdirSync"
@module("process") external cwd: unit => string = "cwd"
@module("process") external argv: array<string> = "argv"

module P = Kuku_PromptSpec

let root = cwd() ++ "/../stories/kuku/ep10/"
let () = PromptGate.setStrict(true)
let () = P.useStyleKey(cwd() ++ "/../stories/kuku/ep10/style/ep10_style_key.png")
let plate = root ++ "sets/courtyard_plate.png"
let stillsDir = root ++ "stills/"
let clipsDir = root ++ "clips/"

/* ---- typed story state -------------------------------------------------------- */
type light = Dusk | LampNight | Dark | Golden | NextDusk
type lampState = Lit | Cold
let lampOf = l =>
  switch l {
  | Dusk | LampNight | NextDusk => Lit
  | Dark | Golden => Cold
  }

type member = Kuku | Fyuria | Leda | Castor | Vesper | Dadi | Papa | Kalu
type castEntry = {who: member, form: P.form, pose: string}
let dev = m =>
  switch m {
  | Kuku => "कुकु"
  | Fyuria => "फ्यूरिया"
  | Leda => "लेडा"
  | Castor => "कैस्टर"
  | Vesper => "वैस्पर"
  | Dadi => "दादी"
  | Papa => "पापा"
  | Kalu => "कालू"
  }
let isDragon = m =>
  switch m {
  | Kuku | Fyuria | Leda | Castor | Vesper => true
  | Dadi | Papa | Kalu => false
  }

/* a named entry; `pose` MUST name the actor — the gate refuses a pose that does not */
let e = (who, pose) => {who, form: P.Small, pose}
let g = (who, pose) => {who, form: P.Great, pose}

/* LEGACY: the first build's rows carried one shared string for the whole cast.
   Kept only so the file compiles while rows are rewritten; every legacy row is
   refused by the gate, which is the point. */
let legacy = (members: array<member>, doing: string) => Js.Array2.map(members, w => e(w, doing))

let lightProse = l =>
  switch l {
  | Dusk => "Evening, the sun already below the frame. Warm level light lies across the paper stone, and the sky above the valley holds the last gold."
  | LampNight => "Night has come. The small flame in the niche is the one warm light, glowing on the paper stone closest to it, and the courtyard beyond falls away into soft blue shadow."
  | Dark => "Deep blue darkness. All light comes from the night sky, enough to see outlines and the shine of open eyes."
  | Golden => "A warm golden glow standing in the air before the niche is the one source of light. Warm gold falls on the faces near it and on the paper stone of the wall, and the courtyard beyond holds deep blue night."
  | NextDusk => "The following evening. Warm level light across the paper stone, the same gold as the first evening, quiet and settled."
  }

/* camera stations, checked against the Blender geometry; the prose names the
   lamp only when the lamp exists */
let camProse = (c, lamp) => {
  let shelf = lamp == Lit ? "the lamp on its stone shelf" : "the bare stone shelf of the niche"
  switch c {
  | "wide" => "A wide view from the door side of the courtyard, taking in the flagstone floor, the low wall and the niche, with the valley beyond."
  | "niche" => "A straight view of the niche in the low wall, " ++ shelf ++ " filling the middle of the frame."
  | "flame" => "A close view of " ++ shelf ++ ", filling the middle of the frame."
  | "lampmed" => "A medium view holding the niche at one side of the frame and the character acting on it at the other."
  | "faces" => "A view from beside the niche, looking back across the courtyard at the faces."
  | "childeye" => "A low view at a small child's eye height, the niche raised above."
  | "overfuria" => "A view over फ्यूरिया's shoulder toward the niche."
  | "door" => "A view across the courtyard toward the wooden paper door in the taller wall."
  | "valley" => "A view over the low wall out to the paper hills of the valley below."
  | "group34" => "A low three-quarter view across the seated group, the niche at the far side of the frame."
  | "high" => "A high wide view looking down into the whole courtyard."
  | _ => "A wide view of the courtyard."
  }
}

type kind = Motion | Still
type row = {
  id: string,
  kind: kind,
  secs: int,
  cam: string,
  light: light,
  cast: array<castEntry>,
  frame: string, /* the instant a still shows */
  action: string, /* for motion: the change across the shot */
}

let m = (id, secs, cam, light, members, frame, action) =>
  {id, kind: Motion, secs, cam, light, cast: legacy(members, frame), frame, action}
let s = (id, secs, cam, light, members, frame) =>
  {id, kind: Still, secs, cam, light, cast: legacy(members, frame), frame, action: ""}
/* the lawful constructors: explicit per-member entries */
let mm = (id, secs, cam, light, cast, frame, action) => {id, kind: Motion, secs, cam, light, cast, frame, action}
let ss = (id, secs, cam, light, cast, frame) => {id, kind: Still, secs, cam, light, cast, frame, action: ""}

let five = [Kuku, Fyuria, Leda, Castor, Vesper]
let fiveKalu = [Kuku, Fyuria, Leda, Castor, Vesper, Kalu]
let withDadiDoor = Js.Array2.concat(fiveKalu, [Dadi])
let withDadiNiche = Js.Array2.concat(fiveKalu, [Dadi])
let childrenOnly = fiveKalu
let seated = "the five children sit in a half circle on the flagstones facing the niche, small enough that the low wall rises above them"

let shots = [
  /* ---- अंक १ — the ordinary world, dusk ---- */
  mm("s01_dadi_carries", 9, "wide", Dusk,
    [e(Dadi, "दादी walks out from the wooden door carrying the small clay lamp level in both hands")],
    "दादी walks out from the wooden door carrying the small clay lamp in both hands",
    "दादी crosses the courtyard from the door toward the low wall, the small clay lamp held level in both hands."),
  mm("s02_lamp_lit", 8, "niche", Dusk,
    [e(Dadi, "दादी kneels at the low wall and settles the small clay lamp onto the stone shelf of the niche")],
    "दादी kneeling at the low wall, settling the small clay lamp onto the stone shelf of the niche",
    "दादी's hands lower the lamp onto the shelf; the wick takes and a small flame rises and stands upright."),
  mm("s03_five_settle", 8, "group34", Dusk,
    [
      e(Kuku, "कुकु walks forward toward the lamp and sits down at the middle of the half circle"),
      e(Fyuria, "फ्यूरिया walks forward beside कुकु and sits down at कुकु's right"),
      e(Leda, "लेडा walks forward and sits down at कुकु's left"),
      e(Castor, "कैस्टर walks forward at the end of the row and sits down beside फ्यूरिया"),
      e(Vesper, "वैस्पर walks forward and sits down at the far end beside लेडा"),
      e(Kalu, "कालू curls into a sleeping coil on the flagstones beside the half circle"),
    ],
    "कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर sit in a half circle on the flagstones facing the niche, small enough that the low wall rises above the seated dragons, and कालू curls into a sleeping coil on the flagstones beside the half circle",
    "कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर walk forward together toward the lamp in one steady row and lower themselves into a half circle, moving at the same pace from the first frame to the last, while कालू curls down into a sleeping coil beside the half circle."),
  ss("s04_castor_teased", 10, "faces", Dusk,
    [
      e(Kuku, "कुकु sits at the middle of the half circle on the flagstones, smiling at the joke"),
      e(Fyuria, "फ्यूरिया sits at कुकु's right, leaning toward कैस्टर with a teasing grin"),
      e(Leda, "लेडा sits at कुकु's left, laughing at कैस्टर"),
      e(Castor, "कैस्टर sits at the right end of the half circle, grinning wide and pointing a paw at कालू"),
      e(Vesper, "वैस्पर sits at the left end of the half circle, watching quietly"),
      e(Kalu, "कालू lies curled asleep on the flagstones beside the half circle"),
    ],
    "कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर sit in a half circle on the flagstones facing the niche, small under the low wall; फ्यूरिया leans toward कैस्टर with a teasing grin, कैस्टर grins back and points a paw at कालू, लेडा laughs at कैस्टर, कुकु smiles, वैस्पर watches quietly, and कालू lies curled asleep beside the half circle"),
  ss("s05_castor_asks", 9, "faces", Dusk,
    [
      e(Kuku, "कुकु sits at the middle of the half circle, looking at the lamp"),
      e(Fyuria, "फ्यूरिया sits at कुकु's right, glancing sideways at कैस्टर"),
      e(Leda, "लेडा sits at कुकु's left with claws folded together"),
      e(Castor, "कैस्टर sits at the right end of the half circle, leaning forward with a question, looking up toward the niche"),
      e(Vesper, "वैस्पर sits at the left end of the half circle, listening"),
      e(Kalu, "कालू lies curled asleep on the flagstones beside the half circle"),
    ],
    "कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर sit in a half circle on the flagstones facing the niche, small under the low wall; कैस्टर leans forward with a question, looking up toward the niche, फ्यूरिया glances at कैस्टर, कुकु looks at the lamp, लेडा and वैस्पर listen, and कालू lies curled asleep beside the half circle"),
  ss("s06_dadi_explains", 13, "group34", Dusk,
    [
      e(Kuku, "कुकु sits at the middle of the half circle, looking up at दादी"),
      e(Fyuria, "फ्यूरिया sits at कुकु's right, wings folded, listening to दादी"),
      e(Leda, "लेडा sits at कुकु's left, sitting straight, eyes on दादी"),
      e(Castor, "कैस्टर sits at the right end of the half circle, mouth a little open as दादी answers"),
      e(Vesper, "वैस्पर sits at the left end of the half circle, head tilted toward दादी"),
      e(Kalu, "कालू lies curled asleep on the flagstones beside the half circle"),
      e(Dadi, "दादी kneels beside the lit niche, face turned toward the seated dragons as दादी speaks"),
    ],
    "दादी kneeling beside the lit niche, face turned toward कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर, who sit in a half circle on the flagstones before दादी looking up as दादी speaks, and कालू lies curled asleep beside the half circle"),
  ss("s07_kuku_understands", 9, "faces", Dusk,
    [
      e(Kuku, "कुकु sits close against दादी's side, looking at the small flame"),
      e(Fyuria, "फ्यूरिया sits at the right of the half circle, looking at the small flame too"),
      e(Leda, "लेडा sits at the left of the half circle, quiet, watching कुकु"),
      e(Castor, "कैस्टर sits at the right end of the half circle, chin resting on both paws"),
      e(Vesper, "वैस्पर sits at the left end of the half circle, still and thoughtful"),
      e(Kalu, "कालू lies curled asleep on the flagstones beside the half circle"),
      e(Dadi, "दादी kneels beside the niche with कुकु close against दादी's side, looking at the small flame"),
    ],
    "कुकु sitting close against दादी's side, कुकु and दादी both looking at the small flame, फ्यूरिया, लेडा, कैस्टर and वैस्पर seated in the half circle on the flagstones around the pair, and कालू lies curled asleep beside the half circle"),
  ss("s08_vesper_asks", 11, "faces", Dusk,
    [
      e(Kuku, "कुकु sits at the middle of the half circle, turning to look at वैस्पर"),
      e(Fyuria, "फ्यूरिया sits at कुकु's right, one wing shrugging at the question"),
      e(Leda, "लेडा sits at कुकु's left, looking from वैस्पर to दादी"),
      e(Castor, "कैस्टर sits at the right end of the half circle, wide-eyed at the question"),
      e(Vesper, "वैस्पर sits at the left end of the half circle, turned toward दादी with a serious question"),
      e(Kalu, "कालू lies curled asleep on the flagstones beside the half circle"),
      e(Dadi, "दादी kneels beside the niche answering वैस्पर calmly"),
    ],
    "वैस्पर turned toward दादी with a serious question, दादी kneeling beside the niche answering calmly, कुकु, फ्यूरिया, लेडा and कैस्टर seated in the half circle on the flagstones looking from वैस्पर to दादी, and कालू lies curled asleep beside the half circle"),
  ss("s09_leda_counts_nights", 10, "faces", Dusk,
    [
      e(Kuku, "कुकु sits at the middle of the half circle, watching लेडा count"),
      e(Fyuria, "फ्यूरिया sits at कुकु's right, rolling eyes fondly at लेडा's counting"),
      e(Leda, "लेडा sits at कुकु's left, holding up small claws and counting on each one"),
      e(Castor, "कैस्टर sits at the right end of the half circle, trying to count along on both paws"),
      e(Vesper, "वैस्पर sits at the left end of the half circle, nodding at लेडा's count"),
      e(Kalu, "कालू lies curled asleep on the flagstones beside the half circle"),
      e(Dadi, "दादी kneels beside the niche smiling at लेडा"),
    ],
    "लेडा holding up small claws and counting on each one, दादी kneeling beside the niche smiling at लेडा, कुकु, फ्यूरिया, कैस्टर and वैस्पर seated in the half circle on the flagstones watching लेडा count, and कालू lies curled asleep beside the half circle"),
  mm("s10_first_gust", 6, "flame", Dusk, [],
    "the lamp alone on its shelf",
    "A gust reaches the niche; the flame lies flat along the shelf and climbs slowly upright again."),
  ss("s11_vesper_warns", 11, "valley", Dusk,
    [
      e(Vesper, "वैस्पर stands at the low wall looking down the valley, worried"),
      e(Fyuria, "फ्यूरिया stands beside वैस्पर at the low wall, relaxed and unconcerned, wings loose"),
    ],
    "वैस्पर standing at the low wall looking down the valley, worried, and फ्यूरिया standing beside वैस्पर at the wall, relaxed and unconcerned"),
  ss("s12_dadi_hands_over", 12, "group34", Dusk,
    [
      e(Kuku, "कुकु sits at the middle of the half circle, looking up at दादी"),
      e(Fyuria, "फ्यूरिया sits at कुकु's right, looking up at दादी with a confident grin"),
      e(Leda, "लेडा sits at कुकु's left, sitting very straight, looking up at दादी with a firm promise"),
      e(Castor, "कैस्टर sits at the right end of the half circle, looking up at दादी"),
      e(Vesper, "वैस्पर sits at the left end of the half circle, looking up at दादी, thoughtful"),
      e(Kalu, "कालू lies curled asleep on the flagstones beside the half circle"),
      e(Dadi, "दादी rises to standing beside the niche, looking down at the seated dragons"),
    ],
    "दादी rising to standing beside the niche, कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर seated in the half circle on the flagstones looking up at दादी, लेडा sitting very straight with a firm promise, and कालू lies curled asleep beside the half circle"),
  ss("s13_dadi_at_door", 10, "door", Dusk,
    [
      e(Kuku, "कुकु sits at the middle of the half circle, turned to watch दादी at the door"),
      e(Fyuria, "फ्यूरिया sits at कुकु's right, looking back toward the door"),
      e(Leda, "लेडा sits at कुकु's left, looking back toward the door"),
      e(Castor, "कैस्टर sits at the right end of the half circle, waving a paw toward दादी"),
      e(Vesper, "वैस्पर sits at the left end of the half circle, looking back toward the door"),
      e(Dadi, "दादी pauses in the open doorway looking back across the courtyard at the seated dragons"),
    ],
    "दादी paused in the open doorway looking back across the courtyard, कुकु watching दादी from the middle of the half circle, फ्यूरिया, लेडा, कैस्टर and वैस्पर seated beside कुकु on the flagstones looking back toward the door"),
  mm("s14_door_closes", 7, "door", LampNight,
    [
      e(Kuku, "कुकु sits at the middle of the half circle facing the door"),
      e(Fyuria, "फ्यूरिया sits at कुकु's right facing the door"),
      e(Leda, "लेडा sits at कुकु's left facing the door"),
      e(Castor, "कैस्टर sits at the right end of the half circle facing the door"),
      e(Vesper, "वैस्पर sits at the left end of the half circle facing the door"),
    ],
    "कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर seated in the half circle on the flagstones, the wooden door across the courtyard",
    "The door swings closed. The courtyard darkens to the lamp alone, and कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर sit small in the lamplight."),

  /* ---- अंक २-अ — three attempts, then the loss ---- */
  ss("s15_furia_offers", 9, "overfuria", LampNight,
    [
      e(Kuku, "कुकु sits at the middle of the half circle, looking up at फ्यूरिया"),
      e(Fyuria, "फ्यूरिया rises to standing with one wing half opened, eager"),
      e(Leda, "लेडा reaches a claw toward फ्यूरिया in caution"),
      e(Castor, "कैस्टर sits at the right end of the half circle, watching फ्यूरिया"),
      e(Vesper, "वैस्पर sits at the left end of the half circle, watching फ्यूरिया"),
    ],
    "फ्यूरिया rising to standing with one wing half opened, लेडा reaching a claw toward फ्यूरिया in caution, कुकु, कैस्टर and वैस्पर seated on the flagstones watching फ्यूरिया"),
  mm("s16_wing_kills_it", 9, "lampmed", LampNight,
    [e(Fyuria, "फ्यूरिया stands at the niche with one wing spread across the opening")],
    "फ्यूरिया at the niche with one wing spread across the opening",
    "फ्यूरिया spreads a wing over the niche; the flame is driven flat and shrinks to a thin blue thread."),
  ss("s17_furia_shaken", 11, "faces", LampNight,
    [
      e(Kuku, "कुकु sits at the middle of the half circle, looking at फ्यूरिया with concern"),
      e(Fyuria, "फ्यूरिया sits back on both heels with wings folded tight, shaken"),
      e(Leda, "लेडा turns toward फ्यूरिया, speaking gently"),
      e(Castor, "कैस्टर sits at the right end of the half circle, looking at the flame"),
      e(Vesper, "वैस्पर sits at the left end of the half circle, looking at फ्यूरिया"),
    ],
    "फ्यूरिया sitting back on both heels with wings folded tight, shaken, लेडा turned toward फ्यूरिया speaking gently, कुकु, कैस्टर and वैस्पर seated on the flagstones around the pair"),
  mm("s18_castor_cups", 10, "childeye", LampNight,
    [e(Castor, "कैस्टर kneels at the niche with both small paws curved around the flame")],
    "कैस्टर at the niche with both small paws curved around the flame",
    "कैस्टर brings both paws around the flame like a bowl; the gap between the paws lets the wind straight through and the flame ducks."),
  ss("s19_castor_small", 10, "faces", LampNight,
    [
      e(Kuku, "कुकु reaches over to pat कैस्टर's shoulder"),
      e(Fyuria, "फ्यूरिया sits at the right of the half circle, watching कैस्टर"),
      e(Leda, "लेडा sits at the left of the half circle, watching कैस्टर kindly"),
      e(Castor, "कैस्टर sits looking down at both of the small paws कैस्टर holds open"),
      e(Vesper, "वैस्पर sits at the left end of the half circle, thinking"),
    ],
    "कैस्टर looking down at both small open paws, कुकु reaching over to pat कैस्टर's shoulder, फ्यूरिया, लेडा and वैस्पर seated on the flagstones watching कैस्टर"),
  ss("s20_vesper_plans", 11, "faces", LampNight,
    [
      e(Kuku, "कुकु sits at the middle of the half circle, looking at वैस्पर"),
      e(Fyuria, "फ्यूरिया sits at the right of the half circle, wings folded, listening to वैस्पर"),
      e(Leda, "लेडा sits at the left of the half circle, listening to वैस्पर"),
      e(Castor, "कैस्टर sits at the right end of the half circle, looking at the leaf in वैस्पर's claw"),
      e(Vesper, "वैस्पर holds a paper leaf up in one claw, thinking"),
    ],
    "वैस्पर holding a paper leaf up in one claw, thinking, कुकु, फ्यूरिया, लेडा and कैस्टर seated on the flagstones looking at वैस्पर"),
  mm("s21_wall_flies", 9, "lampmed", LampNight,
    [e(Vesper, "वैस्पर stacks paper leaves into a small wall of leaves in front of the niche")],
    "वैस्पर stacking paper leaves into a small wall of leaves in front of the niche",
    "वैस्पर lays the last leaf on the little wall of leaves; a gust takes the whole stack and carries it up out of frame."),
  ss("s22_vesper_learns", 10, "faces", LampNight,
    [
      e(Kuku, "कुकु sits at the middle of the half circle, following the leaf with wide eyes"),
      e(Fyuria, "फ्यूरिया sits at the right of the half circle, looking up after the leaf"),
      e(Leda, "लेडा sits at the left of the half circle, looking at वैस्पर"),
      e(Castor, "कैस्टर sits at the right end of the half circle, pointing up after the leaf"),
      e(Vesper, "वैस्पर watches the last leaf go, claws still held open"),
    ],
    "वैस्पर watching the last leaf go with claws still held open, कुकु and कैस्टर looking up after the leaf, फ्यूरिया and लेडा seated on the flagstones looking at वैस्पर"),
  ss("s23_leda_finds_rhythm", 12, "faces", LampNight,
    [
      e(Kuku, "कुकु sits at the middle of the half circle, turning to watch लेडा"),
      e(Fyuria, "फ्यूरिया sits at the right of the half circle, turning toward लेडा"),
      e(Leda, "लेडा sits with one claw raised, counting the gusts aloud"),
      e(Castor, "कैस्टर sits at the right end of the half circle, turning toward लेडा with a hopeful face"),
      e(Vesper, "वैस्पर sits at the left end of the half circle, listening to लेडा's count"),
    ],
    "लेडा with one claw raised, counting the gusts aloud, कुकु, फ्यूरिया, कैस्टर and वैस्पर seated on the flagstones turning to watch लेडा"),
  mm("s24_all_shield", 12, "group34", LampNight,
    [
      e(Kuku, "कुकु leans in toward the niche on लेडा's count"),
      e(Fyuria, "फ्यूरिया leans in toward the niche beside कुकु, wings held tight"),
      e(Leda, "लेडा kneels a little back from the niche with one claw raised, counting"),
      e(Castor, "कैस्टर leans in toward the niche at the right, both paws out"),
      e(Vesper, "वैस्पर leans in toward the niche at the left"),
    ],
    "कुकु, फ्यूरिया, कैस्टर and वैस्पर leaning in together around the niche on लेडा's count, लेडा a little back with one claw raised, counting",
    "On लेडा's count कुकु, फ्यूरिया, कैस्टर and वैस्पर lean in together and close around the lamp while लेडा keeps counting; the flame steadies and stands tall between कुकु, फ्यूरिया, कैस्टर and वैस्पर."),
  ss("s25_it_is_working", 10, "faces", LampNight,
    [
      e(Kuku, "कुकु sits close to the niche, face lit by the flame, smiling"),
      e(Fyuria, "फ्यूरिया sits close to the niche, face lit, holding still"),
      e(Leda, "लेडा sits a little back with one claw raised, still counting"),
      e(Castor, "कैस्टर sits close to the niche, face lit and delighted, mouth open in a cheer"),
      e(Vesper, "वैस्पर sits close to the niche, face lit, eyes on the flame"),
    ],
    "कैस्टर's face lit and delighted, लेडा still counting with one claw raised, कुकु, फ्यूरिया and वैस्पर close beside कैस्टर with faces lit by the flame"),
  mm("s26_the_lamp_dies", 11, "flame", LampNight, [],
    "the lamp on its shelf with the flame low",
    "A long gust arrives off the count. The flame flattens, shrinks, turns blue and goes out. A single thin thread of smoke lifts from the wick and the light leaves the courtyard."),
  mm("s27_darkness", 10, "group34", Dark,
    [
      e(Kuku, "कुकु sits motionless at the middle of the half circle, eyes open in the dark"),
      e(Fyuria, "फ्यूरिया sits motionless at कुकु's right, wings drawn in"),
      e(Leda, "लेडा sits motionless at कुकु's left, claw still half raised"),
      e(Castor, "कैस्टर sits motionless at the right end of the half circle, staring at the niche"),
      e(Vesper, "वैस्पर sits motionless at the left end of the half circle, head bowed"),
      e(Kalu, "कालू lies curled asleep on the flagstones beside the half circle"),
    ],
    "कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर sitting motionless in blue darkness in a half circle facing the niche, and कालू lies curled asleep beside the half circle",
    "कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर stay exactly where each one sits in the dark, and the only movement in frame is the wind stirring the folded wings of each seated dragon, while कालू sleeps on."),
  ss("s28_castor_says_it", 9, "faces", Dark,
    [
      e(Kuku, "कुकु sits at the middle of the half circle in the blue dark, staring at the niche"),
      e(Fyuria, "फ्यूरिया sits at the right of the half circle in the blue dark, wings drawn in"),
      e(Leda, "लेडा sits at the left of the half circle in the blue dark, claw lowered"),
      e(Castor, "कैस्टर's face in the blue dark, eyes wide, looking at the bare niche"),
      e(Vesper, "वैस्पर sits at the left end of the half circle in the blue dark, very still"),
    ],
    "कैस्टर's face in the blue dark, eyes wide, looking at the bare niche, कुकु, फ्यूरिया, लेडा and वैस्पर seated beside कैस्टर on the flagstones in the blue dark"),

  /* ---- अंक २-ब — no fire left ---- */
  mm("s29_castor_at_door", 10, "door", Dark,
    [e(Castor, "कैस्टर runs to the closed wooden door and pushes both paws against it")],
    "कैस्टर running to the closed wooden door and pushing both paws against it",
    "कैस्टर runs across the dark courtyard and pushes both paws against the door; the door stays shut and कैस्टर is far too small to move it."),
  ss("s30_no_fire_inside", 11, "door", Dark,
    [
      e(Kuku, "कुकु stands a few steps back from the door, watching कैस्टर"),
      e(Fyuria, "फ्यूरिया stands close behind कैस्टर, turning toward the door as if to call out"),
      e(Leda, "लेडा holds a claw out toward फ्यूरिया to stop फ्यूरिया"),
      e(Castor, "कैस्टर stands with both paws flat on the closed door, looking up at it"),
      e(Vesper, "वैस्पर stands at the back near the low wall, looking at the door"),
    ],
    "कैस्टर with both paws flat on the closed wooden door, फ्यूरिया close behind कैस्टर, लेडा holding a claw out to stop फ्यूरिया, कुकु and वैस्पर standing back on the flagstones watching"),
  mm("s31_papa_calls", 12, "valley", Dark, [],
    "the dark valley below the low wall",
    "Far down in the dark valley a small voice calls up, and the wind pulls the sound sideways and scatters it."),
  ss("s32_kuku_hears_papa", 10, "faces", Dark,
    [
      e(Kuku, "कुकु stands at the low wall, staring down into the dark valley"),
      e(Fyuria, "फ्यूरिया stands behind कुकु, wings half lifted in alarm"),
      e(Leda, "लेडा stands behind कुकु, looking toward the valley"),
      e(Castor, "कैस्टर stands by the door, turning toward the wall"),
      e(Vesper, "वैस्पर stands beside कुकु at the wall, listening"),
    ],
    "कुकु standing at the low wall staring down into the dark valley, वैस्पर beside कुकु listening, फ्यूरिया and लेडा behind कुकु, कैस्टर turning from the door toward the wall"),
  /* SERIES LAW (author, 2026-09-02): every episode puts the कड़े on and flies at
     least once. v5 kept the five small throughout, which broke it. Paid here —
     and the great form fails TWICE: the wind is stronger aloft, and at seven
     metres in a five-metre courtyard they cannot go near the lamp at all. After
     five great dragons have failed, no strength-based answer is left. */
  ss("s33a_kade_called", 11, "group34", Dark,
    [
      e(Kuku, "कुकु stands in the dark at the middle of the row with one paw laid over the golden band on the other wrist"),
      e(Fyuria, "फ्यूरिया stands at कुकु's right with one paw pressed over the golden band on the other wrist, eager"),
      e(Leda, "लेडा stands at कुकु's left with one paw over the golden band on the other wrist, giving the order"),
      e(Castor, "कैस्टर stands at the right end of the row, one paw clapped over the golden band on the other wrist"),
      e(Vesper, "वैस्पर stands at the left end of the row, one paw laid over the golden band on the other wrist, jaw set"),
    ],
    "कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर standing on the flagstones in the dark, each with one paw laid over the golden band on the other wrist, लेडा giving the order"),
  mm("s33b_transform", 10, "wide", Dark,
    [
      g(Kuku, "कुकु stands at the middle of the courtyard in great form, a golden wave of light settling around कुकु"),
      g(Fyuria, "फ्यूरिया stands at कुकु's right in great form, wings opening wide, a golden wave of light settling around फ्यूरिया"),
      g(Leda, "लेडा stands at कुकु's left in great form, head lifted, a golden wave of light settling around लेडा"),
      g(Castor, "कैस्टर stands at the right end in great form, looking down at both enormous paws, a golden wave of light settling around कैस्टर"),
      g(Vesper, "वैस्पर stands at the left end in great form, wings half open, a golden wave of light settling around वैस्पर"),
    ],
    "कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर standing in great form filling the courtyard, shoulders level with the top of the low wall, a golden wave of light settling around each dragon",
    "Five bands ring at once. A golden wave of light climbs कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर from the band upward and opens outward, and कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर stand great in the courtyard, shoulders level with the top of the low wall, wings unfolding wide."),
  mm("s33c_they_rise", 9, "valley", Dark,
    [
      g(Kuku, "कुकु in great form lifts from the flagstones over the low wall, wings wide"),
      g(Fyuria, "फ्यूरिया in great form lifts at कुकु's right, wings beating hard, first over the wall"),
      g(Leda, "लेडा in great form lifts at कुकु's left, wings wide and level"),
      g(Castor, "कैस्टर in great form lifts at the right end, wings pumping"),
      g(Vesper, "वैस्पर in great form lifts at the left end, wings wide, eyes on the valley"),
    ],
    "कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर in great form lifting from the flagstones over the low wall toward the dark valley, wings wide and gold-edged",
    "कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर rise together over the low wall in one movement and out into the sky above the valley, wings wide and gold-edged against the dark."),
  mm("s33d_thrown_back", 11, "wide", Dark,
    [
      g(Kuku, "कुकु in great form is driven backward over the wall, wings spread, coming down on the flagstones"),
      g(Fyuria, "फ्यूरिया in great form tumbles back at कुकु's right, wings spread wide, landing hard"),
      g(Leda, "लेडा in great form comes down at कुकु's left with wings spread, bracing on both paws"),
      g(Castor, "कैस्टर in great form is thrown back at the right end, wings spread, landing squarely on four paws"),
      g(Vesper, "वैस्पर in great form comes down at the left end with wings spread, breathing heavily"),
    ],
    "कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर in great form driven backward into the courtyard, wings spread, coming down on the flagstones",
    "The valley wind meets कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर head on and carries कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर back over the wall; each dragon comes down on the flagstones with wings still open, breathing hard."),
  ss("s33e_too_big", 12, "faces", Dark,
    [
      g(Kuku, "कुकु in great form stands crowded at the middle of the courtyard, looking down at the niche far below"),
      g(Fyuria, "फ्यूरिया in great form stands at कुकु's right with head hanging, defeated"),
      g(Leda, "लेडा in great form stands at कुकु's left, looking at कैस्टर"),
      g(Castor, "कैस्टर in great form stands at the right end, bending down toward the niche far below, speaking slowly"),
      g(Vesper, "वैस्पर in great form stands at the left end, wings drawn in tight to fit the courtyard"),
    ],
    "कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर in great form crowding the courtyard, shoulders level with the top of the low wall, कैस्टर bending down toward the niche far below, फ्यूरिया's head hanging, कुकु looking down at the niche, लेडा looking at कैस्टर, वैस्पर with wings drawn in tight"),
  mm("s33f_shrink_back", 10, "group34", Dark,
    [
      g(Kuku, "कुकु in great form stands at the middle with one paw laid over the golden band on the other wrist"),
      g(Fyuria, "फ्यूरिया in great form stands at कुकु's right with one paw over the golden band on the other wrist, head bowed"),
      g(Leda, "लेडा in great form stands at कुकु's left with one paw over the golden band on the other wrist, counting quietly"),
      g(Castor, "कैस्टर in great form stands at the right end with one paw clapped over the golden band on the other wrist"),
      g(Vesper, "वैस्पर in great form stands at the left end with one paw over the golden band on the other wrist, wings folding"),
    ],
    "कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर in great form standing in the courtyard, each with one paw laid over the golden band on the other wrist, golden waves of light settling downward around each dragon",
    "Five bands ring again. The golden waves of light settle downward around कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर, and कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर stand once more on the flagstones at child height, the courtyard wide around each dragon."),
  ss("s34_neither_can", 11, "faces", Dark,
    [
      e(Kuku, "कुकु stands behind वैस्पर, looking toward the valley"),
      e(Fyuria, "फ्यूरिया stands behind वैस्पर with wings drooping"),
      e(Leda, "लेडा stands behind वैस्पर, a claw resting on कुकु's shoulder"),
      e(Castor, "कैस्टर stands behind वैस्पर, up on tiptoe trying to see over the wall"),
      e(Vesper, "वैस्पर stands at the low wall straining to see down into the dark valley"),
    ],
    "वैस्पर at the low wall straining to see down into the dark valley, कुकु, फ्यूरिया, लेडा and कैस्टर standing behind वैस्पर on the flagstones"),
  mm("s35_breath_scatters", 11, "overfuria", Dark,
    [e(Kuku, "कुकु faces the bare niche with head raised, breathing out")],
    "कुकु facing the bare niche with head raised",
    "कुकु breathes out a loose golden mist; the mist rises, spreads and thins away into the dark, and the air before the niche is clear again."),
  ss("s36_kuku_realises", 11, "faces", Dark,
    [
      e(Kuku, "कुकु looks down at both empty open claws in the blue dark, puzzled"),
      e(Fyuria, "फ्यूरिया stands at कुकु's right, watching कुकु"),
      e(Leda, "लेडा stands at कुकु's left, looking at कुकु's claws"),
      e(Castor, "कैस्टर stands at the right end, looking at the bare niche"),
      e(Vesper, "वैस्पर stands at the left end, looking at कुकु thoughtfully"),
    ],
    "कुकु looking down at both empty open claws in the blue dark, फ्यूरिया, लेडा, कैस्टर and वैस्पर standing beside कुकु on the flagstones"),
  ss("s37_leda_instructs", 13, "faces", Dark,
    [
      e(Kuku, "कुकु stands facing लेडा, listening, uncertain"),
      e(Fyuria, "फ्यूरिया stands behind लेडा, quiet"),
      e(Leda, "लेडा stands close to कुकु, speaking to कुकु steadily"),
      e(Castor, "कैस्टर stands behind लेडा, listening"),
      e(Vesper, "वैस्पर stands behind लेडा, nodding slowly"),
    ],
    "लेडा close to कुकु speaking steadily, कुकु listening, फ्यूरिया, कैस्टर and वैस्पर standing behind लेडा on the flagstones"),
  ss("s38_furia_gives_first", 12, "faces", Dark,
    [
      e(Kuku, "कुकु stands facing फ्यूरिया, surprised"),
      e(Fyuria, "फ्यूरिया turns to कुकु with wings folded flat and low, calm"),
      e(Leda, "लेडा stands beside कुकु, watching फ्यूरिया"),
      e(Castor, "कैस्टर stands at the right, watching फ्यूरिया"),
      e(Vesper, "वैस्पर stands at the left, watching फ्यूरिया"),
    ],
    "फ्यूरिया turned to कुकु with wings folded flat and low, कुकु facing फ्यूरिया, लेडा, कैस्टर and वैस्पर standing around the pair on the flagstones"),

  /* ---- द की खोज ---- */
  ss("s39_kuku_hears_it", 13, "childeye", Dark,
    [
      e(Kuku, "कुकु sits close below the bare niche, face lit only by blue night, thinking aloud"),
      e(Fyuria, "फ्यूरिया sits behind कुकु at the right, wings folded, waiting"),
      e(Leda, "लेडा sits behind कुकु at the left, watching कुकु closely"),
      e(Castor, "कैस्टर sits at the right end, chin on both paws, waiting"),
      e(Vesper, "वैस्पर sits at the left end, looking at the niche"),
    ],
    "कुकु sitting close below the bare niche, face lit only by blue night, thinking aloud, फ्यूरिया, लेडा, कैस्टर and वैस्पर seated behind कुकु on the flagstones"),
  ss("s40_say_it_again", 10, "faces", Dark,
    [
      e(Kuku, "कुकु sits at the middle of the half circle, saying the words again clearly"),
      e(Fyuria, "फ्यूरिया sits at the right of the half circle, turning to listen to कुकु"),
      e(Leda, "लेडा leans in toward कुकु, excited"),
      e(Castor, "कैस्टर sits at the right end, turning to listen to कुकु"),
      e(Vesper, "वैस्पर sits at the left end, turning to listen to कुकु"),
    ],
    "लेडा leaning in toward कुकु, कुकु saying the words again clearly, फ्यूरिया, कैस्टर and वैस्पर seated on the flagstones turning to listen to कुकु"),
  ss("s41_castor_milk", 11, "faces", Dark,
    [
      e(Kuku, "कुकु sits at the middle of the half circle, grinning at कैस्टर"),
      e(Fyuria, "फ्यूरिया sits at the right of the half circle, smirking at कैस्टर"),
      e(Leda, "लेडा laughs at कैस्टर"),
      e(Castor, "कैस्टर is up on both hind legs with both paws raised, delighted"),
      e(Vesper, "वैस्पर sits at the left end, shaking head fondly at कैस्टर"),
    ],
    "कैस्टर up on both hind legs with both paws raised, delighted, लेडा laughing at कैस्टर, कुकु, फ्यूरिया and वैस्पर seated on the flagstones grinning at कैस्टर"),
  ss("s42_vesper_far", 11, "faces", Dark,
    [
      e(Kuku, "कुकु sits at the middle of the half circle, listening to वैस्पर"),
      e(Fyuria, "फ्यूरिया sits at the right of the half circle, looking at वैस्पर"),
      e(Leda, "लेडा sits at the left of the half circle, nodding at वैस्पर's word"),
      e(Castor, "कैस्टर sits at the right end, looking toward the valley with वैस्पर"),
      e(Vesper, "वैस्पर looks out over the dark valley while speaking, slow and quiet"),
    ],
    "वैस्पर looking out over the dark valley while speaking, कुकु, फ्यूरिया, लेडा and कैस्टर seated on the flagstones listening to वैस्पर"),
  ss("s43_leda_ten", 10, "faces", Dark,
    [
      e(Kuku, "कुकु sits at the middle of the half circle, watching लेडा's claws"),
      e(Fyuria, "फ्यूरिया sits at the right of the half circle, counting along under breath"),
      e(Leda, "लेडा holds up both claws, counting off each one to ten"),
      e(Castor, "कैस्टर sits at the right end, holding up both paws to copy लेडा"),
      e(Vesper, "वैस्पर sits at the left end, smiling at लेडा"),
    ],
    "लेडा holding up both claws counting off each one to ten, कैस्टर holding up both paws to copy लेडा, कुकु, फ्यूरिया and वैस्पर seated on the flagstones watching लेडा"),
  ss("s44_furia_run", 11, "faces", Dark,
    [
      e(Kuku, "कुकु sits at the middle of the half circle, looking up at फ्यूरिया"),
      e(Fyuria, "फ्यूरिया is up on both feet with wings half open, bright again"),
      e(Leda, "लेडा sits at the left of the half circle, smiling up at फ्यूरिया"),
      e(Castor, "कैस्टर sits at the right end, clapping both paws for फ्यूरिया"),
      e(Vesper, "वैस्पर sits at the left end, looking up at फ्यूरिया"),
    ],
    "फ्यूरिया up on both feet with wings half open, bright again, कुकु, लेडा, कैस्टर and वैस्पर seated on the flagstones looking up at फ्यूरिया"),
  ss("s45_kuku_gathers", 12, "group34", Dark,
    [
      e(Kuku, "कुकु sits at the middle of the half circle looking round at फ्यूरिया, लेडा, कैस्टर and वैस्पर, gathering the words together"),
      e(Fyuria, "फ्यूरिया sits at कुकु's right, looking at कुकु"),
      e(Leda, "लेडा sits at कुकु's left, looking at कुकु with a quiet smile"),
      e(Castor, "कैस्टर sits at the right end, leaning toward कुकु"),
      e(Vesper, "वैस्पर sits at the left end, looking at कुकु"),
    ],
    "कुकु looking round at फ्यूरिया, लेडा, कैस्टर and वैस्पर, gathering the words together, फ्यूरिया, लेडा, कैस्टर and वैस्पर seated on the flagstones around कुकु looking back at कुकु"),

  /* ---- the shape, and a mistake ---- */
  ss("s46_leda_draws", 12, "faces", Dark,
    [
      e(Kuku, "कुकु sits at the middle of the half circle, eyes following लेडा's claw"),
      e(Fyuria, "फ्यूरिया sits at the right of the half circle, watching लेडा's claw"),
      e(Leda, "लेडा traces in the air with one claw, a faint golden glow hanging where the claw has passed"),
      e(Castor, "कैस्टर sits at the right end, copying लेडा's claw in the air with one paw"),
      e(Vesper, "वैस्पर sits at the left end, watching लेडा's claw"),
    ],
    "लेडा tracing in the air with one claw, a faint golden glow hanging where the claw has passed, कुकु, फ्यूरिया, कैस्टर and वैस्पर seated on the flagstones watching लेडा's claw"),
  mm("s47_wrong_way", 11, "niche", Dark,
    [e(Kuku, "कुकु breathes toward the empty air before the niche")],
    "कुकु breathing toward the empty air before the niche",
    "A faint golden glow forms in the dark air before the niche and brightens a little, then holds, small and uncertain."),
  mm("s48_wind_goes_through", 10, "niche", Dark, [],
    "a faint golden glow hanging in the air before the niche",
    "A gust arrives and passes straight through the glow; the golden light shudders and dims to a faint trace."),
  ss("s49_leda_corrects", 12, "faces", Dark,
    [
      e(Kuku, "कुकु stands facing the niche breathing hard, ready to try again"),
      e(Fyuria, "फ्यूरिया stands behind कुकु, wings lifted in encouragement"),
      e(Leda, "लेडा points urgently past कुकु toward the valley"),
      e(Castor, "कैस्टर stands at the right, looking from लेडा's claw to the valley"),
      e(Vesper, "वैस्पर stands at the left, nodding at लेडा's correction"),
    ],
    "लेडा pointing urgently past कुकु toward the valley, कुकु breathing hard, फ्यूरिया, कैस्टर and वैस्पर standing around the pair on the flagstones"),
  ss("s50_all_encourage", 10, "group34", Dark,
    [
      e(Kuku, "कुकु stands facing the niche, drawing a deep breath"),
      e(Fyuria, "फ्यूरिया is up on both feet turned toward कुकु, wings half open, calling out"),
      e(Leda, "लेडा is up on both feet turned toward कुकु, one claw raised, calling out"),
      e(Castor, "कैस्टर is up on both feet turned toward कुकु, both paws raised, calling out"),
      e(Vesper, "वैस्पर is up on both feet turned toward कुकु, calling out"),
    ],
    "फ्यूरिया, लेडा, कैस्टर and वैस्पर up on both feet turned toward कुकु and calling out together, कुकु facing the niche drawing a deep breath"),

  /* ---- अंक ३ — the letter that does not go out ---- */
  mm("s51_curve_forms", 12, "niche", Golden,
    [e(Kuku, "कुकु breathes steadily toward the air before the niche")],
    "कुकु breathing steadily toward the air before the niche",
    "A warm golden glow gathers in the dark air before the niche and brightens, growing steadily with its own light."),
  mm("s52_line_rises", 10, "niche", Golden,
    [e(Kuku, "कुकु stands before the niche, still breathing out toward the golden glow")],
    "कुकु standing before the niche with a warm golden glow standing in the air before it",
    "The golden glow before the niche grows taller and fuller and settles into a complete, steady brightness that lights कुकु's face."),
  mm("s53_wind_cannot_touch", 11, "niche", Golden, [],
    "a warm golden glow standing steady in the air before the niche",
    "A full gust comes off the valley straight into the golden glow. Paper leaves and dust on the flagstones stream past the niche, while the glow holds perfectly steady and its golden light stays completely still."),
  ss("s54_it_is_not_fire", 11, "faces", Golden,
    [
      e(Kuku, "कुकु stands nearest the niche, face lit gold, breathing out slowly"),
      e(Fyuria, "फ्यूरिया stands at the right, wings loose, staring at the golden glow"),
      e(Leda, "लेडा stands calm beside वैस्पर, face lit gold"),
      e(Castor, "कैस्टर stands at the right end, both paws pressed to cheeks in wonder"),
      e(Vesper, "वैस्पर stares at the golden glow with mouth open"),
    ],
    "वैस्पर staring at the golden glow with mouth open, लेडा calm beside वैस्पर, कुकु nearest the niche with face lit gold, फ्यूरिया and कैस्टर standing at the right in wonder"),
  mm("s55_light_goes_down", 11, "valley", Golden, [],
    "the low wall with a warm golden glow standing behind it",
    "The golden light spills over the low wall and reaches down the dark valley in a wide steady glow."),
  mm("s56_papa_climbs", 12, "valley", Golden,
    [e(Papa, "पापा climbs the path below toward the golden light")],
    "पापा on the path below, climbing toward the golden light",
    "Far down the path पापा appears in the golden light and climbs steadily up toward the courtyard."),
  ss("s57_papa_asks", 12, "group34", Golden,
    [
      e(Kuku, "कुकु stands beside पापा, looking up at पापा, quiet"),
      e(Fyuria, "फ्यूरिया stands at the right, looking at पापा"),
      e(Leda, "लेडा stands at the left, looking at पापा"),
      e(Castor, "कैस्टर stands at the right end, bouncing on both feet"),
      e(Vesper, "वैस्पर stands at the left end, looking from पापा to the golden glow"),
      e(Papa, "पापा stands in the courtyard looking at the golden glow before the niche, astonished"),
    ],
    "पापा standing in the courtyard looking at the golden glow before the niche, कुकु beside पापा looking up, फ्यूरिया, लेडा, कैस्टर and वैस्पर standing around on the flagstones looking at पापा"),
  ss("s58_papa_kneels", 12, "faces", Golden,
    [
      e(Kuku, "कुकु stands facing पापा, face lit gold"),
      e(Fyuria, "फ्यूरिया stands behind कुकु at the right, watching पापा"),
      e(Leda, "लेडा stands behind कुकु at the left, watching पापा"),
      e(Castor, "कैस्टर stands at the right end, watching पापा"),
      e(Vesper, "वैस्पर stands at the left end, watching पापा"),
      e(Papa, "पापा kneels down to कुकु's height with one hand on कुकु's shoulder"),
    ],
    "पापा kneeling down to कुकु's height with one hand on कुकु's shoulder, कुकु facing पापा, फ्यूरिया, लेडा, कैस्टर and वैस्पर standing behind कुकु on the flagstones"),
  ss("s59_dadi_returns", 12, "door", Golden,
    [
      e(Kuku, "कुकु stands near the niche, turning toward the door"),
      e(Fyuria, "फ्यूरिया stands at the right, turning toward the door"),
      e(Leda, "लेडा stands at the left, turning toward the door"),
      e(Castor, "कैस्टर stands at the right end, waving a paw at दादी"),
      e(Vesper, "वैस्पर stands at the left end, turning toward the door"),
      e(Papa, "पापा stands in the courtyard beside कुकु, turning toward the door"),
      e(Dadi, "दादी stands in the open doorway looking across at the bare niche and the golden glow before it"),
    ],
    "दादी in the open doorway looking across at the bare niche and the golden glow before it, पापा standing beside कुकु in the courtyard, कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर turning toward the door"),
  ss("s60_castor_jokes", 9, "faces", Golden,
    [
      e(Kuku, "कुकु stands at the middle, smiling at the joke"),
      e(Fyuria, "फ्यूरिया stands at the right, laughing"),
      e(Leda, "लेडा stands at the left, laughing"),
      e(Castor, "कैस्टर laughs with both paws raised, face lit gold"),
      e(Vesper, "वैस्पर stands at the left end, smiling"),
      e(Dadi, "दादी laughs back at कैस्टर"),
    ],
    "कैस्टर laughing with both paws raised, दादी laughing back at कैस्टर, कुकु, फ्यूरिया, लेडा and वैस्पर standing around on the flagstones laughing"),

  /* ---- the review ---- */
  ss("s61_dadi_reviews", 13, "group34", Golden,
    [
      e(Kuku, "कुकु sits at दादी's right side in the golden light"),
      e(Fyuria, "फ्यूरिया sits at दादी's left side in the golden light"),
      e(Leda, "लेडा sits facing दादी, sitting straight"),
      e(Castor, "कैस्टर sits facing दादी, a paw already raised with an answer"),
      e(Vesper, "वैस्पर sits facing दादी, raising a claw with an answer"),
      e(Kalu, "कालू lies curled asleep on the flagstones beside the circle"),
      e(Dadi, "दादी sits down on the flagstones among the seated dragons, asking the question"),
    ],
    "दादी sitting down on the flagstones among कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर, who sit around दादी in the golden light, कैस्टर and वैस्पर raising a paw with an answer, and कालू lies curled asleep beside the circle"),
  ss("s62_words_come", 12, "faces", Golden,
    [
      e(Kuku, "कुकु sits at दादी's right side, speaking last and quietest"),
      e(Fyuria, "फ्यूरिया sits at दादी's left side, calling out an answer with a grin"),
      e(Leda, "लेडा sits facing दादी, holding up both claws with an answer"),
      e(Castor, "कैस्टर sits facing दादी, having just called out an answer, pleased"),
      e(Vesper, "वैस्पर sits facing दादी, giving an answer slowly"),
      e(Kalu, "कालू lies curled asleep on the flagstones beside the circle"),
      e(Dadi, "दादी sits among the seated dragons listening to each answer in turn"),
    ],
    "लेडा, फ्यूरिया, कैस्टर and वैस्पर each speaking an answer in turn, कुकु last and quietest at दादी's right side, दादी sitting among the seated dragons listening, and कालू lies curled asleep beside the circle"),
  ss("s63_dadi_and_kuku", 11, "faces", Golden,
    [
      e(Kuku, "कुकु sits close under दादी's hand, face lit gold, looking up at दादी"),
      e(Fyuria, "फ्यूरिया sits at the right, watching कुकु and दादी"),
      e(Leda, "लेडा sits at the left, watching कुकु and दादी with a soft smile"),
      e(Castor, "कैस्टर sits at the right end, quiet for once"),
      e(Vesper, "वैस्पर sits at the left end, watching कुकु and दादी"),
      e(Dadi, "दादी rests one hand on कुकु's head, lit gold"),
    ],
    "दादी with one hand resting on कुकु's head, कुकु and दादी both lit gold, फ्यूरिया, लेडा, कैस्टर and वैस्पर seated around the pair on the flagstones"),

  /* ---- the changed world ---- */
  mm("s64_kuku_carries", 12, "wide", NextDusk,
    [
      e(Kuku, "कुकु walks out from the door carrying the small clay lamp in both hands"),
      e(Dadi, "दादी sits by the wall watching कुकु"),
    ],
    "कुकु walking out from the door carrying the small clay lamp in both hands, दादी seated by the wall watching कुकु",
    "कुकु crosses the courtyard exactly as दादी did on the first evening, sets the lamp on the niche shelf and lights it, while दादी watches from beside the wall."),
  ss("s65_same_words", 10, "niche", NextDusk,
    [
      e(Kuku, "कुकु kneels at the niche with the newly lit lamp"),
      e(Dadi, "दादी sits behind कुकु watching, smiling"),
    ],
    "कुकु kneeling at the niche with the newly lit lamp, दादी seated behind कुकु watching"),
  mm("s66_night_holds", 10, "high", NextDusk,
    [
      e(Kuku, "कुकु sits at the middle of the half circle facing the niche"),
      e(Fyuria, "फ्यूरिया sits at कुकु's right facing the niche"),
      e(Leda, "लेडा sits at कुकु's left facing the niche"),
      e(Castor, "कैस्टर sits at the right end of the half circle facing the niche"),
      e(Vesper, "वैस्पर sits at the left end of the half circle facing the niche"),
      e(Kalu, "कालू lies curled asleep on the flagstones beside the half circle"),
    ],
    "the courtyard from above: the lit lamp in its niche with a warm golden glow standing beside it, कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर seated in a half circle facing the niche, and कालू asleep on the stones",
    "The courtyard settles into night: the lamp burns in the niche, the golden glow stands beside it exactly where it was made, कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर sit still in the half circle, and कालू sleeps on the stones."),
]


/* ---- turning a row into a spec -------------------------------------------- */

let subjectOf = (x: castEntry): P.subject =>
  switch x.who {
  | Dadi => P.Dadi({doing: x.pose})
  | Papa =>
    P.Prop({
      what: "पापा — a grown paper dragon father, taller and broader than कुकु, a plain travelling wrap across पापा's shoulders, the same pale papercraft build as the rest of this family",
      doing: x.pose,
    })
  | Kalu => P.Prop({what: "कालू — a small dark paper dog with soft folded paper ears", doing: x.pose})
  | Kuku => P.Dragon({name: P.Kuku, form: x.form, doing: x.pose})
  | Fyuria => P.Dragon({name: P.Fyuria, form: x.form, doing: x.pose})
  | Leda => P.Dragon({name: P.Leda, form: x.form, doing: x.pose})
  | Castor => P.Dragon({name: P.Castor, form: x.form, doing: x.pose})
  | Vesper => P.Dragon({name: P.Vesper, form: x.form, doing: x.pose})
  }

/* the lamp exists only when it is lit; Cold means it is not described at all */
let diyaLit = P.Prop({
  what: "THE DIYA — a small round clay paper lamp, a shallow dish with a pinched lip and a short cotton wick",
  doing: "standing on the stone shelf of the niche with a single small flame upright on its wick",
})
/* the letter is a VFX layer; the model renders only its light */
let glow = P.Prop({
  what: "A SOFT POOL OF WARM GOLDEN LIGHT — a warm golden glow hanging in the air before the niche, its edges fading gently into the dark, about as tall as a seated child",
  doing: "burning steadily, casting warm gold onto the faces near it and onto the paper stone of the wall behind it",
})

let props = r =>
  switch (lampOf(r.light), r.light) {
  | (Lit, _) => [diyaLit]
  | (Cold, Golden) => [glow]
  | (Cold, _) => []
  }

let names = cast => Js.Array2.joinWith(Js.Array2.map(cast, x => dev(x.who)), ", ")

/* form drives the scale rule from the cast alone; mixed forms are refused */
let scaleRule = cast => {
  let dragons = Js.Array2.filter(cast, x => isDragon(x.who))
  let greats = Js.Array2.filter(dragons, x => x.form == P.Great)
  if Js.Array2.length(dragons) == 0 {
    ""
  } else if Js.Array2.length(greats) == Js.Array2.length(dragons) {
    "GREAT FORM: " ++ names(dragons) ++ " each stand about seven metres tall, taller than the courtyard is wide, shoulders level with the top of the low wall and heads above it, wings broad enough to reach across the flagstones; a wide golden band shines on one wrist of each dragon."
  } else if Js.Array2.length(greats) == 0 {
    "SMALL FORM: " ++ names(dragons) ++ " are each about knee high to a grown-up, and the low wall rises well above the small dragons' heads."
  } else {
    Js.Exn.raiseError("PROMPT: mixed forms in one shot — " ++ names(dragons))
  }
}

let setting = "दादी's courtyard: a small square of pale paper flagstone walled on every side, a low wall of cut paper blocks along the valley side with a square niche set into it, a wooden paper door in the taller wall, and the paper hills of the valley beyond."

let commonRules = r => Js.Array2.filter([
  "THE COURTYARD IS THE ATTACHED PLATE: the same flagstones, the same low wall of cut paper blocks, the same niche in the same place, the same door, the same valley beyond.",
  "EVERY SURFACE IS CUT PAPER: separate pieces of paper with real thickness, soft rounded cut edges, a fine visible paper grain, and the small soft shadow each piece casts on the one behind it.",
  scaleRule(r.cast),
  lampOf(r.light) == Cold ? "THE NICHE SHELF IS BARE STONE, in shadow." : "",
], x => x != "")

let specOf = (r): P.imageSpec => {
  scene: r.frame,
  shot: P.Medium,
  subjects: Js.Array2.concat(Js.Array2.map(r.cast, subjectOf), props(r)),
  setting,
  lighting: lightProse(r.light),
  plate: Some(plate),
  blockout: None,
  objects: [],
  extraRules: Js.Array2.concat(commonRules(r), ["VIEWPOINT: " ++ camProse(r.cam, lampOf(r.light))]),
}

let stillPath = r => stillsDir ++ r.id ++ ".png"
let doStill = r => ignore(Kuku_Engine.still(~episode="EP10", ~id=r.id, ~spec=specOf(r), ~dst=stillPath(r), ()))

/* ---- motion ----------------------------------------------------------------- */
let clipSpecOf = (r): P.videoSpec => {
  scene: r.action,
  cameraTravels: false,
  cast: Js.Array2.concat(Js.Array2.map(r.cast, subjectOf), props(r)),
  blocking: [
    "The courtyard stays exactly as it is in the start frame: the same flagstones, the same low wall of cut paper blocks, the same niche in the same place, the same door, the same valley beyond.",
    "Each named character keeps the position shown in the start frame, apart from the movement described below.",
  ],
  beats: [r.action],
  camera: "The camera holds completely still throughout. " ++ camProse(r.cam, lampOf(r.light)),
  physics: Js.Array2.concat(
    ["Paper behaves as paper: it bends and lifts at its edges and settles back, keeping its thickness."],
    lampOf(r.light) == Lit ? ["The flame moves the way a real small flame moves: it leans, wavers and recovers."] : [],
  ),
  lighting: lightProse(r.light),
  audio: "SILENT",
  extraRules: Js.Array2.concat(commonRules(r), [
    "ONE CONTINUOUS MOVEMENT: the shot contains a single unbroken action that carries from the first frame to the last, moving a little in every frame at an even pace throughout.",
  ]),
}

let clipPath = r => clipsDir ++ "EP10_" ++ r.id ++ ".mp4"
let fullLength = ["s01", "s02", "s03", "s24", "s26", "s27", "s31", "s51", "s52", "s53", "s56", "s64", "s66"]
let clipSecs = r => {
  let stem = Js.Array2.unsafe_get(Js.String2.split(r.id, "_"), 0)
  Js.Array2.includes(fullLength, stem) ? r.secs : 5
}

let verdict = v =>
  switch v {
  | Kuku_Engine.Current => "current"
  | Kuku_Engine.NoReceipt => "no receipt"
  | Kuku_Engine.RefDrift(p) => "reference drifted: " ++ p
  | Kuku_Engine.PromptDrift => "prompt changed"
  | Kuku_Engine.AssetDrift => "pixels changed after generation"
  | Kuku_Engine.RulesDrift => "made under an older law"
  }

/* a clip animates an APPROVED still: one whose receipt is current under the
   present prompt and the present law */
let doClip = r =>
  switch Kuku_Engine.freshness(~asset=stillPath(r), ~prompt=P.imagePrompt(specOf(r))) {
  | Kuku_Engine.Current =>
    ignore(
      Kuku_Engine.clip(~episode="EP10", ~id=r.id, ~spec=clipSpecOf(r),
        ~model="cinematic_studio_video_4_0", ~secs=clipSecs(r), ~start=Kuku_Engine.StartFrame(stillPath(r)),
        ~setRefs=[P.styleKey(), plate],
        ~workflow="cinematic_studio_video_4_0", ~dst=clipPath(r), ()),
    )
  | v => Js.log("PREMISE STALE: start frame for " ++ r.id ++ " is " ++ verdict(v) ++ " — regenerate the still first")
  }

let stills = Js.Array2.filter(shots, r => r.kind == Still)
let motion = Js.Array2.filter(shots, r => r.kind == Motion)

/* light of a shot by its screenplay label — "शॉट ०७", "शॉट ३३-अ" — for the closeups */
let devDigits = "०१२३४५६७८९"
let idOfLabel = label => {
  let body = Js.String2.replace(label, "शॉट ", "")
  let parts = Js.String2.split(body, "-")
  let digits = Js.Array2.unsafe_get(parts, 0)
  let n = Js.Array2.reduce(Js.String2.split(digits, ""), (acc, ch) => {
    let i = Js.String2.indexOf(devDigits, ch)
    i >= 0 ? acc * 10 + i : acc
  }, 0)
  let suf = Js.Array2.length(parts) > 1
    ? switch Js.Array2.unsafe_get(parts, 1) { | "अ" => "a" | "ब" => "b" | "स" => "c" | "द" => "d" | "य" => "e" | "र" => "f" | x => x }
    : ""
  "s" ++ (n < 10 ? "0" : "") ++ Belt.Int.toString(n) ++ suf ++ "_"
}
let lightOfLabel = label => {
  let pre = idOfLabel(label)
  Js.Array2.find(shots, r => Js.String2.startsWith(r.id, pre))->Belt.Option.map(r => r.light)
}

let () = {
  mkdirSync(stillsDir, {"recursive": true})
  mkdirSync(clipsDir, {"recursive": true})
  let cmd = Belt.Array.get(argv, 2)->Belt.Option.getWithDefault("gate")
  let arg = Belt.Array.get(argv, 3)->Belt.Option.getWithDefault("")
  switch cmd {
  | "list" =>
    Js.Array2.forEach(shots, r =>
      Js.log(r.id ++ "  " ++ (r.kind == Motion ? "motion" : "still ") ++ "  " ++ Belt.Int.toString(r.secs) ++ "s  cam=" ++ r.cam ++ "  cast=" ++ Belt.Int.toString(Js.Array2.length(r.cast)))
    )
    Js.log(Belt.Int.toString(Js.Array2.length(shots)) ++ " shots — " ++ Belt.Int.toString(Js.Array2.length(motion)) ++ " motion, " ++ Belt.Int.toString(Js.Array2.length(stills)) ++ " stills")
  | "still" =>
    switch Js.Array2.find(shots, r => r.id == arg) {
    | Some(r) => doStill(r)
    | None => Js.log("no shot " ++ arg)
    }
  | "clip" =>
    switch Js.Array2.find(shots, r => r.id == arg) {
    | Some(r) => doClip(r)
    | None => Js.log("no shot " ++ arg)
    }
  | "stills" =>
    /* skip ONLY what is current under the present prompt and law */
    Js.Array2.forEach(stills, r =>
      switch Kuku_Engine.freshness(~asset=stillPath(r), ~prompt=P.imagePrompt(specOf(r))) {
      | Kuku_Engine.Current => Js.log("current " ++ r.id)
      | v => {
          Js.log("regenerate " ++ r.id ++ " — " ++ verdict(v))
          doStill(r)
        }
      }
    )
  | _ => {
      /* render without the throwing gate, then report EVERY finding of the law */
      PromptGate.setStrict(false)
      let bad = Js.Array2.reduce(shots, (acc, r) => {
        let txt = P.imagePrompt(specOf(r))
        let found = Js.Array2.concat(PromptGate.scan(txt), PromptGate.scanStrict(txt))
        let clipFound = r.kind == Motion
          ? {
              let ct = P.videoPrompt(clipSpecOf(r))
              Js.Array2.concat(PromptGate.scan(ct), PromptGate.scanStrict(ct))
            }
          : []
        Js.Array2.concat(acc, Js.Array2.map(Js.Array2.concat(found, clipFound), f => r.id ++ ": " ++ f))
      }, [])
      PromptGate.setStrict(true)
      if Js.Array2.length(bad) == 0 {
        Js.log("PROMPT GATE CLEAN — " ++ Belt.Int.toString(Js.Array2.length(shots)) ++ " EP10 shots obey the law")
      } else {
        Js.Array2.forEach(bad, b => Js.log(b))
        Js.log(Belt.Int.toString(Js.Array2.length(bad)) ++ " findings")
      }
    }
  }
}
