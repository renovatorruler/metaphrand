// KukuEp12_Sets.res — the «द से दीया» courtyard: its plate, and the shots on it.
//
// EP12 has ONE set, so it has one master plate, and every shot in the episode is
// generated against that plate. This is the lesson EP10 paid for twice: when a
// location is re-imagined from words each time, thirty shots become thirty places.
//
// Prompts here obey PromptGate — they describe what is in frame and name nothing
// that is absent. A prompt that mentions a thing in order to exclude it summons it.
//
//   node src/KukuEp12_Sets.res.mjs plate     # the courtyard, dusk
//   node src/KukuEp12_Sets.res.mjs gate      # prompt check, no spend

@module("fs") external existsSync: string => bool = "existsSync"
@module("process") external cwd: unit => string = "cwd"
@module("process") external argv: array<string> = "argv"

module P = Kuku_PromptSpec

let root = cwd() ++ "/../stories/kuku/ep12/"

/* EP12 USES ITS OWN STYLE KEY. The shared default is a crop of EP10's lane, and
   it leaked that lane — red markers and all — into a courtyard shot. This one is
   a landmark-free patch of EP12's own wall and flagstone: paper material with no
   place in it. */
let () = PromptGate.setStrict(true)
let () = P.useStyleKey(cwd() ++ "/../stories/kuku/ep12/style/ep12_style_key.png")
let setsDir = root ++ "sets/"
let platePath = setsDir ++ "courtyard_plate.png"
let blockout = root ++ "sets/blender/blockouts/s00_plate.png"
/* The paper MATERIAL, taken from a Higgsfield 3D-Papercraft render of our own
   दादी: individually cut paper blocks with real paper thickness and soft rounded
   edges. Cropped free of characters and of the flowers that render invented, so
   it donates material and nothing else — the EP10 style key taught us that a key
   carrying landmarks puts those landmarks in every frame of the episode. */
let paperDonor = root ++ "style/papercraft_donor.png"

// The set, described once. Every noun here is visible in frame.
let courtyardProse = "A small square courtyard of pale paper flagstone, walled on every side. \
The far wall stands about waist high on a grown-up and is built from individual cut paper blocks laid in courses, each block a separate piece of paper with real thickness and soft rounded edges, each casting its own small soft shadow on the course behind it, and a row of flat coping stones caps the top edge from corner to corner. \
Set into the middle of that far wall is a small square NICHE, and the floor of the niche is a plain stone shelf just wide enough for one small lamp. \
Beyond the wall the land falls away and a wide valley of soft green paper hills spreads to the horizon, with low flat paper clouds resting above them. \
On the near side of the courtyard a plain wooden paper door stands in a taller wall. \
The courtyard floor is laid in large flat paper slabs, each slab a separate sheet of paper with a fine visible grain and a soft lifted edge where it meets the next."

let plateLight = "Evening, with the sun already low and below the frame. The light comes level and warm across the stone from one side, and the sky above the valley holds the last gold."

let platePrompt =
  "SET PLATE — this image IS the location, built once and used for every shot of the episode.\n\n" ++
  "STYLE: the FIRST attached image is the look — folded and cut paper, matte paper surfaces, soft rounded paper edges, flat layered paper shapes. Every surface in this picture is made of paper.\n" ++
  "PAPER MATERIAL: the SECOND attached image is the paper to match — each surface built from separate pieces of cut paper with real paper thickness, soft rounded cut edges, a fine visible paper grain, and the small soft shadow each paper piece casts on the one behind it. Build every surface of this courtyard from that same paper.\n" ++
  "STAGING: the THIRD attached image is a grey geometry study of this exact courtyard from this exact viewpoint. Take the placement from it — where the far wall stands, where the niche sits in that wall, how wide the courtyard is, where the door stands, how far the valley lies beyond.\n\n" ++
  "SETTING: " ++ courtyardProse ++ "\n" ++
  "LIGHTING: " ++ plateLight ++ "\n\n" ++
  "VIEWPOINT: standing in the courtyard on the door side, at the height of a grown-up's chest, looking level across the floor toward the far wall and the valley beyond it.\n" ++
  "The only things in this picture are the ones named above: the flagstone floor, the four walls, the coping stone, the niche, the door, the valley, the hills and the clouds. \
The courtyard stands quiet and open, ready for the story to arrive."

let doPlate = () => {
  let base = existsSync(paperDonor) ? [P.styleKey(), paperDonor] : [P.styleKey()]
  let refs = existsSync(blockout) ? Js.Array2.concat(base, [blockout]) : base
  if !existsSync(blockout) {
    Js.log("NOTE: no Blender staging render — generating the plate from prose alone")
  }
  ignore(
    Kuku_Engine.plate(~episode="EP12", ~id="ep12_courtyard_plate", ~prompt=platePrompt, ~refs, ~dst=platePath, ()),
  )
}


/* ---- shot 02: दादी lights the दीया -------------------------------------------
   The first shot of the episode to carry a character, and the one that proves the
   look. Generated against the plate so the courtyard is inherited, not reinvented. */
let s02Spec: P.imageSpec = {
  scene: "दादी sets the small lamp in the wall niche and lights it. The flame catches and stands.",
  shot: P.Medium,
  subjects: [
    P.Dadi({
      doing: "kneeling at the low wall with one hand steadying the small clay lamp on the niche shelf, her other hand just drawing back from the new flame",
    }),
    P.Prop({
      what: "THE DIYA — a small round clay paper lamp, a shallow dish with a pinched lip, a short cotton wick standing in it",
      doing: "sitting on the stone shelf of the niche with a single small flame standing upright on its wick",
    }),
  ],
  setting: courtyardProse,
  lighting: "Evening, the sun already below the frame. The warm level light lies across the stone, and the new flame is the one bright point in the niche, casting a small warm glow onto the stone around it.",
  plate: Some(platePath),
  blockout: None,
  objects: [],
  extraRules: [
    "THE NICHE HOLDS THE LAMP: the small clay lamp stands on the niche shelf, and the flame rises from its wick inside the sheltered square of the niche.",
    "दादी IS AT THE WALL: she kneels close to the low wall so her shoulders are about level with the coping stone, and her face is turned toward the flame she has just lit.",
    "दादी माया IS A PAPER DRAGON ELDER, exactly as her attached character board shows her: a pale grey paper dragon with small curved horns along her head, a long dragon snout, round wire spectacles, a rust-and-cream knitted paper shawl over her shoulders, folded paper dragon wings at her back and a dragon tail resting along the stone.",
    "THE COURTYARD IS THE ATTACHED PLATE: the same flagstone floor, the same low wall and coping, the same niche in the same place, the same door, the same valley and hills beyond.",
  ],
}

let doShot02 = () =>
  ignore(
    Kuku_Engine.still(
      ~episode="EP12",
      ~id="e01_dadi_lights",
      ~spec=s02Spec,
      ~dst=root ++ "stills/e01_dadi_lights.png",
      (),
    ),
  )

/* ---- shot 02 as motion ---------------------------------------------------------
   Cinema Studio, five seconds, anchored to the approved still. The only motion in
   frame is दादी's hand settling the lamp and the flame catching — a shot that is
   complete in one place, which is the whole design of this episode. */
let s02Clip: P.videoSpec = {
  scene: "दादी settles the small clay lamp onto the niche shelf, and the flame catches and stands upright.",
  cameraTravels: false,
  cast: [
    P.Dadi({doing: "kneeling at the low wall, both hands settling the small clay lamp onto the stone shelf of the niche, then drawing slowly back"}),
  ],
  blocking: [
    "दादी stays kneeling at the low wall through the whole shot, her shoulders about level with the coping stone.",
    "The lamp stays on the niche shelf from the moment her hands leave it.",
  ],
  beats: [
    "Her hands lower the lamp the last small distance onto the stone shelf and let it settle.",
    "The wick takes, and a single small flame rises and stands upright inside the niche.",
    "Her hands draw slowly back and rest, and she watches the flame steady.",
  ],
  camera: "The camera holds completely still throughout, framing her and the lit niche together from the side.",
  physics: [
    "The flame moves the way a real small flame moves: it rises, wavers gently, and settles upright.",
    "The warm glow on the stone grows as the flame takes hold, brightest on the niche walls closest to it.",
  ],
  lighting: "Evening, the sun already below the frame, the warm level light lying across the stone. The new flame is the one bright point, glowing on the stone around it.",
  audio: "SILENT",
  extraRules: [
    "दादी माया IS A PAPER DRAGON ELDER as her board shows: pale grey paper dragon, small curved horns, long snout, round wire spectacles, rust-and-cream knitted paper shawl, folded paper wings, dragon tail along the stone.",
    "EVERY SURFACE IS PAPER: folded and cut paper, matte paper faces, soft rounded paper edges.",
    "THE COURTYARD IS THE ONE IN THE START FRAME: same flagstones, same low wall and coping, same niche, same door, same valley beyond.",
  ],
}

let doClip02 = () =>
  ignore(
    Kuku_Engine.clip(
      ~episode="EP12",
      ~id="e01_dadi_lights",
      ~spec=s02Clip,
      ~model="cinematic_studio_video_4_0",
      ~secs=5,
      ~start=root ++ "stills/e01_dadi_lights.png",
      ~workflow="cinematic_studio_video_4_0",
      ~dst=root ++ "clips/EP12_e01_dadi_lights.mp4",
      (),
    ),
  )

let () = {
  let cmd = Belt.Array.get(argv, 2)->Belt.Option.getWithDefault("gate")
  switch cmd {
  | "plate" => doPlate()
  | "s02" => doShot02()
  | "clip02" => doClip02()
  | _ =>
    let findings = Js.Array2.concat(PromptGate.scan(platePrompt), PromptGate.scan(P.imagePrompt(s02Spec)))
    if Js.Array2.length(findings) == 0 {
      Js.log("PROMPT GATE CLEAN — the courtyard plate names only what is in frame")
    } else {
      Js.log("PROMPT GATE: " ++ Js.Array2.joinWith(findings, "; "))
    }
  }
}
