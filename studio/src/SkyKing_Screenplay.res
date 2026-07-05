/* SKY KING — assemble the whole picture into one Fountain screenplay, in story
   order. Reads each scene via Write.read (which VERIFIES it — a PENDING or
   tampered scene is refused, not silently included), so the screenplay is
   guaranteed to contain only production-ready pages. Emits Fountain (title page
   + centered act breaks + INT./EXT. headings + CUE/(RADIO)/(WHISPER) dialogue)
   to a .fountain AND a .txt copy (the .txt for phone reading). ReScript only. */
open Cinema_Backends

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"

type item =
  | Act(string)
  | Scene(string)

/* story order (the ballad structure; deal1/2/3 = R1/R2/R3). */
let order = [
  Act("ACT ONE — THE EVENT"),
  Scene("fence"),
  Scene("stop"),
  Scene("base"),
  Scene("dot"),
  Scene("keep"),
  Scene("intercept"),
  Scene("mandate"),
  Scene("ground"),
  Scene("verse1"),
  Act("ACT TWO — FALLING FOR HIM"),
  Scene("verse2"),
  Scene("rainier"),
  Scene("maya"),
  Scene("news"),
  Scene("verse3"),
  Scene("call"),
  Scene("sights"),
  Scene("deal1"),
  Scene("clip"),
  Scene("deal2"),
  Scene("roll"),
  Act("ACT THREE — THE BALLAD"),
  Scene("deal3"),
  Scene("finale"),
]

let slugOf = id => {
  let recv = Js.Json.parseExn(readText(Path(dir ++ "/sky-king-" ++ id ++ ".scene.txt.receipt.json")))
  recv
  ->Js.Json.decodeObject
  ->Belt.Option.flatMap(o => Js.Dict.get(o, "slug"))
  ->Belt.Option.flatMap(Js.Json.decodeString)
  ->Belt.Option.getWithDefault("SCENE")
}

let fountainOf = sp =>
  switch sp {
  | Write.Action(t) => t
  | Write.Dialogue({who, radio, whisper, text}) =>
    who ++ (radio ? " (RADIO)" : "") ++ (whisper ? " (WHISPER)" : "") ++ "\n" ++ text
  }

let sceneBlock = id =>
  switch Write.read(Path(dir ++ "/sky-king-" ++ id ++ ".scene.txt")) {
  | Error(m) =>
    Js.log("!! SKIPPED " ++ id ++ " — not production-ready: " ++ m)
    None
  | Ok(lns) =>
    let heading = slugOf(id)
    let body = lns->Belt.Array.map(fountainOf)->Belt.Array.joinWith("\n\n", x => x)
    Some(heading ++ "\n\n" ++ body)
  }

let titlePage =
  "Title: **SKY KING**\n" ++
  "Credit: written by\n" ++
  "Author: THE WRITERS' ROOM\n" ++
  "Source: A fiction. No real names. Inspired by the 2018 event.\n" ++
  "Draft date: 4 July 2026\n" ++
  "Notes: Feature. The one free day.\n"

let itemBlock = it =>
  switch it {
  | Act(name) => Some("===\n\n> **" ++ name ++ "** <")
  | Scene(id) => sceneBlock(id)
  }

let main = () => {
  let blocks = order->Belt.Array.keepMap(itemBlock)
  let doc = titlePage ++ "\n\n" ++ Belt.Array.joinWith(blocks, "\n\n\n", x => x) ++ "\n"
  let fpath = dir ++ "/SKY-KING_screenplay_2026-07-04_v1.fountain"
  let tpath = dir ++ "/SKY-KING_screenplay_2026-07-04_v1.txt"
  writeText(Path(fpath), doc)
  writeText(Path(tpath), doc)
  let scenes = order->Belt.Array.keep(it =>
    switch it {
    | Scene(_) => true
    | Act(_) => false
    }
  )
  Js.log(
    "SCREENPLAY -> " ++
    fpath ++
    "  (" ++
    Belt.Int.toString(Belt.Array.length(scenes)) ++
    " scenes requested, " ++
    Belt.Int.toString(Belt.Array.length(blocks) - 3) ++
    " assembled; " ++
    Belt.Int.toString(Js.String2.length(doc)) ++ " chars)",
  )
}

main()
