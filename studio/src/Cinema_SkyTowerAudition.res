/* TOWER (approach controller, Act 2 opener) audition — 3 vetted-American professional
   voices, run THROUGH the (hardened) radio effect, on the tower's own lines. Blind.
   Run: node src/Cinema_SkyTowerAudition.res.mjs */
open Cinema_Backends

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"
let tmp = dir ++ "/audition_rs"
let narr = VoiceId("nPczCjzI2devNBz1zQrb")

let lines = [
  "Seattle approach, aircraft squawking one-two-hundred northwest of the field, say your call sign.",
  "That's a ramp code. That's a pushback code. That's not... somebody's got a live airplane on a tug code.",
  "Okay. That's okay. You're doing fine. Are you a rated pilot, sir.",
]

let candidates = [
  ("one", "QgfJwCRSjPjNs6RJeblX"), // Russell — clear, authoritative baritone American
  ("two", "8iPB8F25Y94jdslCQJuC"), // Ray — deep, calm American
  ("three", "2GuF5ZgBYwz69Rmc9gM2"), // Connery — measured, composed American
]

let rec run = async (i, acc) =>
  if i >= Belt.Array.length(candidates) {
    acc
  } else {
    let (name, vid) = Belt.Array.getExn(candidates, i)
    let slate = await tts(~text=Text("Option " ++ name ++ "."), ~voice=narr)
    let sp = writeBytes(Path(tmp ++ "/tw_slate_" ++ name ++ ".mp3"), slate)
    let segs = lines->Belt.Array.map(l => (Text(l), VoiceId(vid)))
    let take = await dialogue(segs)
    let tp = writeBytes(Path(tmp ++ "/tw_take_" ++ name ++ ".mp3"), take)
    let rp = Cinema_Audio.radioize(tp) // the aviation-radio effect
    await run(i + 1, Belt.Array.concatMany([acc, [sp, silence(Millis(400), Path(tmp)), rp, silence(Millis(1300), Path(tmp))]]))
  }

let main = async () => {
  let parts = await run(0, [])
  let out = dir ++ "/SKY-KING_tower-audition_radio.mp3"
  let _ = concatAudio(parts, Path(out))
  let Seconds(d) = durationSec(Path(out))
  Js.log("TOWER AUDITION -> " ++ out ++ "  (" ++ Js.Float.toFixedWithPrecision(d, ~digits=1) ++ "s)")
}

main()->ignore
