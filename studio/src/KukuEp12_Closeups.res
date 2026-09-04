// KukuEp12_Closeups.res — a close single on the speaker, one per spoken line.
//
// WHY THIS EXISTS. The dialogue frames were staged as group shots: six faces in
// frame, each head about a ninth of the picture. A lip-sync model needs one face
// large enough to track and unambiguous about who is speaking, so those frames
// cannot be synced at all. This generates the coverage a dialogue scene actually
// needs — a close single on whoever is talking — which is also what stops the
// episode reading as one unbroken wide shot.
//
//   node src/KukuEp12_Closeups.res.mjs list
//   node src/KukuEp12_Closeups.res.mjs one <n>
//   node src/KukuEp12_Closeups.res.mjs all

@module("fs") external readFileSync: (string, string) => string = "readFileSync"
@module("fs") external existsSync: string => bool = "existsSync"
@module("fs") external mkdirSync: (string, {"recursive": bool}) => unit = "mkdirSync"
@module("process") external cwd: unit => string = "cwd"
@module("process") external argv: array<string> = "argv"

module P = Kuku_PromptSpec
module S = KukuEp12_Shots

let root = cwd() ++ "/../stories/kuku/ep12/"

/* EP12 USES ITS OWN STYLE KEY. The shared default is a crop of EP10's lane, and
   it leaked that lane — red markers and all — into a courtyard shot. This one is
   a landmark-free patch of EP12's own wall and flagstone: paper material with no
   place in it. */
let () = PromptGate.setStrict(true)
let () = P.useStyleKey(cwd() ++ "/../stories/kuku/ep12/style/ep12_style_key.png")
let outDir = root ++ "closeups/"

type cue = {shot: string, who: string, direction: string, text: string, kind: string}

let cues: array<cue> = {
  let arr =
    Js.Json.parseExn(readFileSync(root ++ "cue_index.json", "utf8"))
    ->Js.Json.decodeArray
    ->Belt.Option.getWithDefault([])
  Js.Array2.map(arr, j => {
    let o = j->Js.Json.decodeObject->Belt.Option.getWithDefault(Js.Dict.empty())
    let g = k => Js.Dict.get(o, k)->Belt.Option.flatMap(Js.Json.decodeString)->Belt.Option.getWithDefault("")
    {shot: g("shot"), who: g("who"), direction: g("direction"), text: g("text"), kind: g("kind")}
  })
}

let memberOf = w =>
  switch w {
  | "दादी" => S.Dadi
  | "कुकु" => S.Kuku
  | "फ्यूरिया" => S.Fyuria
  | "वैस्पर" => S.Vesper
  | "लेडा" => S.Leda
  | "कैस्टर" => S.Castor
  | "पापा" => S.Papa
  | _ => S.Kuku /* «सब» — the chorus reads on कुकु's face, as it does in the table read */
  }
let roleOf = w =>
  switch memberOf(w) {
  | S.Kuku => "KUKU"
  | S.Fyuria => "FYURIA"
  | S.Leda => "LEDA"
  | S.Castor => "CASTOR"
  | S.Vesper => "VESPER"
  | S.Dadi => "DADI"
  | S.Papa => "PAPA"
  | S.Kalu => "KALU"
  }

/* Which act each line falls in decides the light. The shot number lives in the
   cue's Devanagari label, so it is read back rather than guessed. */
let dev = "०१२३४५६७८९"
let shotNum = c => {
  let digits = Js.String2.replace(c.shot, "शॉट ", "")
  Js.Array2.reduce(
    Js.String2.split(digits, ""),
    (acc, ch) => {
      let i = Js.String2.indexOf(dev, ch)
      i >= 0 ? acc * 10 + i : acc
    },
    0,
  )
}

let lightOf = c =>
  switch S.lightOfLabel(c.shot) {
  | Some(l) => l
  | None => Js.Exn.raiseError("CUE: " ++ c.shot ++ " has no row in the shot table")
  }

/* THE FRAME A LIP-SYNC MODEL CAN USE: one head filling most of the picture,
   facing near enough to camera that the mouth is fully visible, and lit from the
   front by the scene's own light source. */
let closeRule =
  "FRAMING: a close single on this one character alone. The head and shoulders fill the frame from top to bottom, the face turned about three quarters toward the camera so the whole muzzle and mouth are clearly visible, eyes open and looking slightly off camera. The character's face is the largest thing in the picture."

let specOf = (c): P.imageSpec => {
  let light = lightOf(c)
  {
    scene: "A close single on " ++ c.who ++ " in the courtyard, mid-speech.",
    shot: P.Close,
    subjects: [S.subjectOf(({who: memberOf(c.who), form: P.Small, pose: S.dev(memberOf(c.who)) ++ " faces the camera in close-up, mouth open in mid-speech, " ++ (c.direction == "" ? "attentive" : c.direction)}: S.castEntry))],
    setting: "दादी's courtyard, seen close: behind the character are the pale cut-paper blocks of the low wall, softly out of focus.",
    lighting: S.lightProse(light),
    plate: Some(root ++ "sets/courtyard_plate.png"),
    blockout: None,
    objects: [],
    extraRules: [
      closeRule,
      "EVERY SURFACE IS CUT PAPER: separate pieces of paper with real thickness, soft rounded cut edges and a fine visible paper grain.",
      "THE BACKGROUND IS THE SAME COURTYARD as the attached plate — the same cut-paper wall, held soft and close behind the character.",
    ],
  }
}

let pad3 = n => {
  let t = Belt.Int.toString(n)
  Js.String2.length(t) >= 3 ? t : Js.String2.repeat("0", 3 - Js.String2.length(t)) ++ t
}
let idOf = (i, c) => "cu" ++ pad3(i + 1) ++ "_" ++ roleOf(c.who)
let pathOf = (i, c) => outDir ++ idOf(i, c) ++ ".png"

let doOne = (i, c) =>
  ignore(Kuku_Engine.still(~episode="EP12", ~id=idOf(i, c), ~spec=specOf(c), ~dst=pathOf(i, c), ()))

let () = {
  mkdirSync(outDir, {"recursive": true})
  let cmd = Belt.Array.get(argv, 2)->Belt.Option.getWithDefault("list")
  let arg = Belt.Array.get(argv, 3)->Belt.Option.getWithDefault("")
  switch cmd {
  | "one" =>
    let i = Belt.Int.fromString(arg)->Belt.Option.getWithDefault(1) - 1
    switch Belt.Array.get(cues, i) {
    | Some(c) => doOne(i, c)
    | None => Js.log("no line " ++ arg)
    }
  | "all" =>
    Js.Array2.forEachi(cues, (c, i) =>
      if existsSync(pathOf(i, c)) {
        Js.log("skip " ++ idOf(i, c))
      } else {
        doOne(i, c)
      }
    )
  | _ =>
    Js.Array2.forEachi(cues, (c, i) =>
      Js.log(idOf(i, c) ++ "  " ++ c.shot ++ "  " ++ c.who ++ "  " ++ Js.String2.slice(c.text, ~from=0, ~to_=44))
    )
    Js.log(Belt.Int.toString(Js.Array2.length(cues)) ++ " close singles — one per spoken line")
  }
}
