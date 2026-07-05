/* Cast validation reel — the SUPPORTING voices, on their own lines (named slates).
   Dez, Tanner, Ward (Act 1) + the re-cast Supervisor (Adam was banned) + Doris.
   Run: node src/Cinema_SkyCastCheck.res.mjs */
open Cinema_Backends

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"
let tmp = dir ++ "/castcheck_rs"
let narr = VoiceId("nPczCjzI2devNBz1zQrb") // Brian — the slate

/* (character, chosen voiceId, their lines) */
let entries = [
  (
    "Dez, Birdy's friend on the ramp",
    "iP95p4xoKVk53GoZ742B", // Chris — down-to-earth
    [
      "You worked that gate two years.",
      "Did you put in for the turn.",
      "You never once asked for the turn. Not once. You just take whatever the box puts up.",
    ],
  ),
  (
    "Tanner, the young lead",
    "bIHbv24MWmeRgasZH58o", // Will — young, relaxed
    ["We good on the count. Twelve for the forward, eight aft.", "No, those are marked forward.", "I signed the load sheet already."],
  ),
  (
    "Ward, the ramp boss",
    "CwhRBWXzGAHq8TQ4Fs17", // Roger — laid-back, worn
    [
      "I gave it to Marquez. It's his as of Monday.",
      "You're the best hand I got out there. You know that.",
      "So I want you to bring him up on it. The chief stuff.",
    ],
  ),
  (
    "The watch supervisor",
    "QgfJwCRSjPjNs6RJeblX", // Russell — authoritative (Adam banned)
    [
      "Unauthorized aircraft airborne out of the field. Single occupant, no rating, squawking a ground code.",
      "I'm classifying it as a possible.",
      "They're putting fighters up.",
    ],
  ),
  (
    "Doris, the care-home patient",
    "5u41aNhyCU6hXOcjPPv0", // Carol — American elderly
    ["You go home to nothing.", "There's no one waiting up for you either, is there.", "Give them here, then. Not because you talked me into it."],
  ),
]

let rec run = async (i, acc) =>
  if i >= Belt.Array.length(entries) {
    acc
  } else {
    let (name, vid, lines) = Belt.Array.getExn(entries, i)
    let slate = await tts(~text=Text(name ++ "."), ~voice=narr)
    let sp = writeBytes(Path(tmp ++ "/slate_" ++ Belt.Int.toString(i) ++ ".mp3"), slate)
    let segs = lines->Belt.Array.map(l => (Text(l), VoiceId(vid)))
    let take = await dialogue(segs)
    let tp = writeBytes(Path(tmp ++ "/take_" ++ Belt.Int.toString(i) ++ ".mp3"), take)
    let g1 = silence(Millis(500), Path(tmp))
    let g2 = silence(Millis(1300), Path(tmp))
    await run(i + 1, Belt.Array.concatMany([acc, [sp, g1, tp, g2]]))
  }

let main = async () => {
  let parts = await run(0, [])
  let out = dir ++ "/SKY-KING_castcheck_supporting.mp3"
  let _ = concatAudio(parts, Path(out))
  let Seconds(d) = durationSec(Path(out))
  Js.log("SUPPORTING CAST CHECK -> " ++ out ++ "  (" ++ Js.Float.toFixedWithPrecision(d, ~digits=1) ++ "s)")
}

main()->ignore
