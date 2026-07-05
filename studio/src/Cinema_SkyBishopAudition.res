/* BISHOP voice audition — 4 warm, calm, American controller candidates (the human
   thread who talks Birdy through it), blind/numbered, on his sample lines. Deacon &
   Banjo already validated. Run: node src/Cinema_SkyBishopAudition.res.mjs */
open Cinema_Backends

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"
let tmp = dir ++ "/audition_rs"
let narr = VoiceId("nPczCjzI2devNBz1zQrb") // Brian — the slate

let lines = [
  "Sky King, this is Bishop. I'm right here with you. We're just gonna fly a while, okay.",
  "You're doing fine. Just keep her level for me. Nice and easy.",
  "Nobody's mad at you up here. I just want to get you home.",
]

let candidates = [
  ("one", "WwLGR2UgbhuTNMpk6oHi"), // Matt — warm, conversational, mid-Atlantic, mid-40s
  ("two", "vzUquQTlMvdV6PkeYguD"), // Michael Stevens — calm, warm, smooth
  ("three", "GxEkXZFVTiRn1HdPNqar"), // Friendly Phil — calm, friendly, 40
  ("four", "PKu46bbccMP1b22TyeI0"), // Jacob Michael — warm, resonant baritone, late 40s
]

let rec run = async (i, acc) =>
  if i >= Belt.Array.length(candidates) {
    acc
  } else {
    let (name, vid) = Belt.Array.getExn(candidates, i)
    let slate = await tts(~text=Text("Option " ++ name ++ "."), ~voice=narr)
    let sp = writeBytes(Path(tmp ++ "/bslate_" ++ name ++ ".mp3"), slate)
    let segs = lines->Belt.Array.map(l => (Text(l), VoiceId(vid)))
    let take = await dialogue(segs)
    let tp = writeBytes(Path(tmp ++ "/btake_" ++ name ++ ".mp3"), take)
    let g1 = silence(Millis(500), Path(tmp))
    let g2 = silence(Millis(1300), Path(tmp))
    await run(i + 1, Belt.Array.concatMany([acc, [sp, g1, tp, g2]]))
  }

let main = async () => {
  let parts = await run(0, [])
  let out = dir ++ "/SKY-KING_bishop-audition_4-options.mp3"
  let _ = concatAudio(parts, Path(out))
  let Seconds(d) = durationSec(Path(out))
  Js.log("BISHOP AUDITION -> " ++ out ++ "  (" ++ Js.Float.toFixedWithPrecision(d, ~digits=1) ++ "s)")
}

main()->ignore
