/* BIRDY voice audition — 4 American candidates, blind (numbered), each speaking three
   of Birdy's real lines from the Act 2 opener (gentle / apologetic / dreamy). The user
   picks by ear. Run: node src/Cinema_SkyBirdyAudition.res.mjs */
open Cinema_Backends

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"
let tmp = dir ++ "/audition_rs"
let narr = VoiceId("nPczCjzI2devNBz1zQrb") // Brian — the slate

/* three Birdy lines, lightly cleaned for TTS (apologetic / plain / dreamy) */
/* sad-but-cheerful: a light self-deprecating chuckle (cheerful) + a wistful sigh (sad) */
let lines = [
  "I don't. I'm sorry, I don't really have a call sign or anything. It's just me.",
  "No, I work the ramp. [chuckles] I just load the bags and stuff. I've watched it a bunch, though.",
  "[sighs] It's real pretty up here. All the lights and everything.",
]

/* blind, numbered — mapping kept out of the audio so the ear judges, not the name */
let candidates = [
  ("one", "raMcNf2S8wCmuaBcyI6E"), // Tyler (current — the bar)
  ("two", "XkfMHqldv3OgiJx0R5gy"), // Steve — Pacific Northwest / Seattle, relaxed
  ("three", "zfpxqh60b0TrMkJHDLsR"), // Peter — calm young, slight Brooklyn / Long Island
  ("four", "VZcBEw9QXVSghzV5UKLN"), // Michael Joshua — kept from round 2
]

let rec run = async (i, acc) =>
  if i >= Belt.Array.length(candidates) {
    acc
  } else {
    let (name, vid) = Belt.Array.getExn(candidates, i)
    let slate = await tts(~text=Text("Option " ++ name ++ "."), ~voice=narr)
    let sp = writeBytes(Path(tmp ++ "/slate_" ++ name ++ ".mp3"), slate)
    let segs = lines->Belt.Array.map(l => (Text(l), VoiceId(vid)))
    let take = await dialogue(segs)
    let tp = writeBytes(Path(tmp ++ "/take_" ++ name ++ ".mp3"), take)
    let g1 = silence(Millis(500), Path(tmp))
    let g2 = silence(Millis(1300), Path(tmp))
    await run(i + 1, Belt.Array.concatMany([acc, [sp, g1, tp, g2]]))
  }

let main = async () => {
  let parts = await run(0, [])
  let out = dir ++ "/SKY-KING_birdy-audition_round3.mp3"
  let _ = concatAudio(parts, Path(out))
  let Seconds(d) = durationSec(Path(out))
  Js.log("AUDITION -> " ++ out ++ "  (" ++ Js.Float.toFixedWithPrecision(d, ~digits=1) ++ "s)")
}

main()->ignore
