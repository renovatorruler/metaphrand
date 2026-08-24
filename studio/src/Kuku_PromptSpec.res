/* Kuku_PromptSpec.res — the deterministic prompt law for Kuku generation.

   Every prompt supplied to an image or video model is RENDERED BY CODE from one
   of these typed specs — never a hand-composed string. The output is plain
   labeled text (models follow prose best); determinism comes from the types:
   each production incident that hand-written prompts allowed (style drift to
   2D, the sepia palette, cloned dragons, missing कड़ा bracelets, stage
   curtains, rendered glyphs) is a constant the renderer always emits or a fact
   derived from the subject list, so a driver cannot forget it. */

type dragonName = Kuku | Fyuria | Leda | Castor | Vesper
type form = Small | Great

type subject =
  | Dragon({name: dragonName, form: form, doing: string})
  | Gauri({doing: string})
  | RishiMuni({doing: string})
  | Dadi({doing: string})
  | Cheel({doing: string})
  | Prop({what: string, doing: string}) // a non-character subject with a locked canonical description

type shot =
  | Wide | WideLow | HighWide | MediumWide | Medium | CloseMedium | Close | Insert
  | WideAction | CloseAbstract | WideAbstract

type imageSpec = {
  scene: string,
  shot: shot,
  subjects: array<subject>,
  setting: string,
  lighting: string,
  /* the approved SET PLATE for this shot's location and camera vantage. When
     present it is attached SECOND (after the style key, before the character
     boards) and the set stops being re-imagined from words every generation. */
  plate: option<string>,
  extraRules: array<string>,
}

type editSpec = {
  change: string,
  keep: array<string>,
  extraRules: array<string>,
}

type videoSpec = {
  scene: string,
  blocking: array<string>,
  beats: array<string>,
  camera: string,
  physics: array<string>,
  lighting: string,
  audio: string,
  extraRules: array<string>,
}

let nameOf = n =>
  switch n {
  | Kuku => "KUKU"
  | Fyuria => "FYURIA"
  | Leda => "LEDA"
  | Castor => "CASTOR"
  | Vesper => "VESPER"
  }

let colorOf = n =>
  switch n {
  | Kuku => "green"
  | Fyuria => "orange-red"
  | Leda => "lilac-purple"
  | Castor => "golden-yellow"
  | Vesper => "pale blue"
  }

let shotName = s =>
  switch s {
  | Wide => "WIDE"
  | WideLow => "WIDE LOW ANGLE"
  | HighWide => "HIGH WIDE"
  | MediumWide => "MEDIUM-WIDE"
  | Medium => "MEDIUM"
  | CloseMedium => "CLOSE-MEDIUM"
  | Close => "CLOSE"
  | Insert => "INSERT CLOSE"
  | WideAction => "WIDE ACTION"
  | CloseAbstract => "CLOSE ABSTRACT"
  | WideAbstract => "WIDE ABSTRACT"
  }

/* the fixed laws */
let styleKey = "0c47270d-70f7-4dd0-887f-c06c88ef5fd9"
let styleLaw = "3D papercraft, layered cut-paper illustration, soft matte construction-paper textures, visible paper edges and folds, non-photorealistic, illustrated, not a photo"
let paletteLaw = "bright, vibrant, warm storybook palette — never sepia, never muted, never monochrome"
let negatives = [
  "no humans, no people, no human children, no human faces, no human shadows",
  "no theater curtains, no stage, no proscenium, no frame-within-frame, no decorative border, no vignette",
  "no readable text, no letters, no numbers, no glyphs, no captions, no watermark, no logos",
  "no photorealism",
  "no duplicate characters, no identical characters, no cloned dragons, no extra characters",
]

let bullets = xs => Js.Array2.joinWith(Js.Array2.map(xs, x => "- " ++ x), "\n")

let subjectText = s =>
  switch s {
  | Dragon({name, form, doing}) =>
    "- " ++
    nameOf(name) ++
    " — " ++
    colorOf(name) ++
    " paper dragon, " ++
    (form == Great
      ? "GREAT form: ENORMOUS. Do not judge this by adjectives — measure her against what is in frame: a wooden hay cart would fit between her two front claws, a grown man would reach only to her knee, and her head rides above the tops of the trees and walls around her. She must never read as a small or medium-sized creature, and never as merely animal-sized"
      : "small everyday form: a small paper dragon child, no taller than a human child") ++
    ", wearing a golden कड़ा paper cuff on ONE forearm (mandatory, clearly visible, never on both). Exactly ONE " ++
    nameOf(name) ++
    " in frame. " ++ doing
  | Gauri({doing}) =>
    "- GAURI — gentle brown-and-white paper cow, dark paper eyes, small paper bell at her neck. Exactly ONE in frame. " ++ doing
  | RishiMuni({doing}) =>
    "- RISHI — the paper guru crane from the attached character sheet. Exactly ONE in frame. " ++ doing
  | Dadi({doing}) =>
    "- DADI — the paper grandmother bird from the attached character sheet. Exactly ONE in frame. " ++ doing
  | Cheel({doing}) =>
    "- CHEEL — a great paper eagle, sharp-eyed, imposing. Exactly ONE in frame. " ++ doing
  | Prop({what, doing}) => "- " ++ what ++ " — " ++ doing
  }

let isCharacter = s =>
  switch s {
  | Prop(_) => false
  | _ => true
  }

let imagePrompt = (s: imageSpec) =>
  Js.Array2.joinWith(
    [
      "SHOT: " ++ shotName(s.shot) ++ ", LANDSCAPE 16:9, full-bleed scene, the camera is INSIDE the world.",
      "STYLE: " ++ styleLaw ++ ". The FIRST attached image is the art style; match it EXACTLY.",
      "PALETTE: " ++ paletteLaw ++ ".",
      switch s.plate {
      | Some(_) =>
        /* a wide shot stands where the plate stands; a close shot is the same
           place seen from nearer, so it must inherit materials and landmarks
           without being forced back to the plate's camera */
        (switch s.shot {
        | Wide | WideLow | WideAction | HighWide | MediumWide | WideAbstract =>
          "SET PLATE: the SECOND attached image IS this location, already built — reproduce it faithfully: the same ground, the same landmarks in the same places, the same walls, kerbs and horizon, the same camera vantage. Do not redesign the place, do not move its landmarks, do not invent new architecture."
        | Medium | CloseMedium | Close | Insert | CloseAbstract =>
          "SET PLATE: the SECOND attached image is THIS SAME LOCATION, already built. This shot is closer in, so the framing differs — but the place does not: identical ground material and paving, identical walls, kerbs, stone and paper textures, identical palette and light, and any landmark of it that falls inside this tighter frame sits exactly where the plate puts it. Never invent different architecture or a different kind of ground."
        }) ++
        " Every attached image after it is a locked character design; match each EXACTLY, including the golden bracelet."
      | None =>
        "CHARACTER REFERENCES: every attached image after the first is a locked character design; match each EXACTLY, including the golden bracelet."
      },
      "SCENE: " ++ s.scene,
      "SUBJECTS:\n" ++ Js.Array2.joinWith(Js.Array2.map(s.subjects, subjectText), "\n"),
      "SETTING: " ++ s.setting,
      "LIGHTING: " ++ s.lighting,
      "HARD RULES:\n" ++
      bullets(
        Js.Array2.concat(
          Js.Array2.some(s.subjects, isCharacter)
            ? negatives
            : Js.Array2.concat(
                ["this is an object/insert shot: no characters at all — no dragons, no birds, no animals, no figures anywhere in frame"],
                negatives,
              ),
          s.extraRules,
        ),
      ),
    ],
    "\n",
  )

let editKeepLaw = [
  "same 3D papercraft medium and layered cut-paper texture",
  "same bright vibrant palette and same lighting",
  "same character designs, poses and expressions unless the change says otherwise",
  "same composition and camera",
]

let editPrompt = (e: editSpec) =>
  Js.Array2.joinWith(
    [
      "TASK: edit the attached image — apply ONLY the change below.",
      "CHANGE: " ++ e.change,
      "KEEP:\n" ++ bullets(Js.Array2.concat(editKeepLaw, e.keep)),
      "HARD RULES:\n" ++ bullets(Js.Array2.concat(negatives, e.extraRules)),
    ],
    "\n",
  )

let paperPhysics = [
  "papercraft world physics: stiff cut-paper wings flex slightly at their folds, motion has real weight",
  "the character's design and colors stay identical in every frame — no morphing, no redesign",
  "the golden bracelet stays on ONE forearm only, the same forearm as in the start image",
]

let videoPrompt = (v: videoSpec) =>
  Js.Array2.joinWith(
    [
      "SCENE: " ++ v.scene,
      "FIRST FRAME: the provided start image IS frame one — every character already in position; no empty establishing frame, no delayed reveal.",
      "FORMAT: SINGLE CONTINUOUS TAKE — no cuts, no fades, no transitions.",
      "BLOCKING:\n" ++ bullets(v.blocking),
      "ACTION TIMING:\n" ++ bullets(v.beats),
      "CAMERA: " ++ v.camera,
      "PHYSICS:\n" ++ bullets(Js.Array2.concat(paperPhysics, v.physics)),
      "LIGHTING: " ++ v.lighting,
      "AUDIO: " ++ v.audio,
      "STYLE: " ++ styleLaw ++ ". The whole clip stays in this medium — no drift to 2D animation, no photorealism.",
      "HARD RULES:\n" ++ bullets(Js.Array2.concat(negatives, v.extraRules)),
    ],
    "\n",
  )

/* reference-image law: style key FIRST, then one locked board per subject that
   has one, deduplicated, in subject order. Paths are relative to studio/. */
let kukuRoot = "../stories/kuku/"

let boardOf = s =>
  switch s {
  | Dragon({name, form}) =>
    switch form {
    | Great =>
      Some(
        kukuRoot ++
        "ep10prod/elements/future_" ++
        Js.String2.toLowerCase(nameOf(name)) ++ "_board_bracelet.png",
      )
    | Small =>
      switch name {
      | Kuku => Some(kukuRoot ++ "charsheets/kuku.png")
      | Fyuria => Some(kukuRoot ++ "charsheets/furia.png")
      | Leda => Some(kukuRoot ++ "charsheets/leda.png")
      | Castor => Some(kukuRoot ++ "charsheets/castor.png")
      | Vesper => None
      }
    }
  | RishiMuni(_) => Some(kukuRoot ++ "charsheets/rishi.png")
  | Cheel(_) => Some(kukuRoot ++ "charsheets/cheel.png")
  | Dadi(_) => Some(kukuRoot ++ "charsheets/dadi.png")
  | Gauri(_) => None
  | Prop(_) => None
  }

let imageRefs = (s: imageSpec) => {
  let head = switch s.plate {
  | Some(p) => [styleKey, p]
  | None => [styleKey]
  }
  let boards = Js.Array2.reduce(
    s.subjects,
    (acc, sub) =>
      switch boardOf(sub) {
      | Some(b) => Js.Array2.includes(acc, b) ? acc : Js.Array2.concat(acc, [b])
      | None => acc
      },
    [],
  )
  Js.Array2.concat(head, boards)
}
