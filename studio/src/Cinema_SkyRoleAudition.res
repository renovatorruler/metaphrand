/* Re-audition DEZ (younger/beta), TANNER (nerdy), SUPERVISOR (Adam banned), DORIS
   (older) — 3 vetted-American options each, blind/numbered, on their own lines. One
   reel per role. Ward is KEPT (not here). Run: node src/Cinema_SkyRoleAudition.res.mjs */
open Cinema_Backends

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"
let tmp = dir ++ "/audition_rs"
let narr = VoiceId("nPczCjzI2devNBz1zQrb")

let roles = [
  (
    "dez", // younger than Birdy, a bit beta / admiring — the truth-teller
    ["You worked that gate two years.", "Did you put in for the turn.", "You never once asked for the turn. Not once. You just take whatever the box puts up."],
    [
      ("one", "mWRBtRP92mUXZzi4RZ0Y"), // Blake — thoughtful late 20s
      ("two", "mBqbvkxIFe5HjjaoiN4P"), // Justin — friendly, youthful, approachable
      ("three", "sUzXYdokj3o9QQ91yPRF"), // Brooks — young
    ],
  ),
  (
    "tanner", // young, nerdy — the green lead
    ["We good on the count. Twelve for the forward, eight aft.", "No, those are marked forward.", "I signed the load sheet already."],
    [
      ("one", "IkksQWAjbvt9CKa7hRkh"), // Weissman — eager
      ("two", "Riw1Wp5PIcFW1ZJAsxKi"), // Andrew — youthful, cool
      ("three", "I1ejplf72DWHJzwAiw4n"), // Tyler — young, quirky
    ],
  ),
  (
    "supervisor", // cold, procedural watch supervisor (Adam banned)
    ["Unauthorized aircraft airborne out of the field. Single occupant, no rating, squawking a ground code.", "I'm classifying it as a possible.", "They're putting fighters up."],
    [
      ("one", "8iPB8F25Y94jdslCQJuC"), // Ray — deep, calm
      ("two", "QTn7zgOqA9G2UKp3tNJb"), // Keith Hinton — deep radio
      ("three", "EGvjD0PIKVzXUvyMkwel"), // Cevin — deep, authoritative, Detroit
    ],
  ),
  (
    "doris", // OLDER, proud, sharp care-home patient
    ["You go home to nothing.", "There's no one waiting up for you either, is there.", "Give them here, then. Not because you talked me into it."],
    [
      ("one", "wGcFBfKz5yUQqhqr0mVy"), // Maria Moody — octogenarian
      ("two", "xIzR6egd3S3LJZbVW0c1"), // Nana Margaret — little old lady
      ("three", "aIu5oHglU5AHNc2x0AZu"), // Jane Hackett — old, conversational
    ],
  ),
]

let renderCand = async (role, lines, (name, vid)) => {
  let slate = await tts(~text=Text("Option " ++ name ++ "."), ~voice=narr)
  let sp = writeBytes(Path(tmp ++ "/" ++ role ++ "_slate_" ++ name ++ ".mp3"), slate)
  let segs = lines->Belt.Array.map(l => (Text(l), VoiceId(vid)))
  let take = await dialogue(segs)
  let tp = writeBytes(Path(tmp ++ "/" ++ role ++ "_take_" ++ name ++ ".mp3"), take)
  [sp, silence(Millis(400), Path(tmp)), tp, silence(Millis(1200), Path(tmp))]
}

let rec cands = async (role, lines, cs, i, acc) =>
  if i >= Belt.Array.length(cs) {
    acc
  } else {
    let part = await renderCand(role, lines, Belt.Array.getExn(cs, i))
    await cands(role, lines, cs, i + 1, Belt.Array.concat(acc, part))
  }

let rec runRoles = async i =>
  if i >= Belt.Array.length(roles) {
    ()
  } else {
    let (role, lines, cs) = Belt.Array.getExn(roles, i)
    let parts = await cands(role, lines, cs, 0, [])
    let out = dir ++ "/SKY-KING_" ++ role ++ "-audition_v3.mp3"
    let _ = concatAudio(parts, Path(out))
    Js.log(role ++ " -> " ++ out)
    await runRoles(i + 1)
  }

let main = async () => await runRoles(0)
main()->ignore
