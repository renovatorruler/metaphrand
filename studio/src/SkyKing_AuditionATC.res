/* SKY KING — ATC recasting audition (PRICE + SUPERVISOR rejected: "weird breathy
   talking, ATC people don't talk like that"). Each candidate reads the ACTUAL
   scene lines CLEAN — no expression tags (the [quietly]/[calm] overlay contributed
   to the breathiness; controllers render tag-free from now on). One stitched mp3
   per candidate per role. ReScript only. */
open Cinema_Backends

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"
let tmp = dir ++ "/audition_rs"

let priceLines = [
  "That's not me. I got nothing down that low.",
  "Off the ground? No. Tower didn't ship me anything tonight.",
  "He answered you?",
]
let supLines = [
  "What've you got.",
  "Nobody worked a handoff.",
  "Try him one more time.",
  "This is the one for DHS.",
]

/* (option label, name, voiceId) — vetted by DESCRIPTION for the crisp/clinical
   controller register, all American by description. */
let priceCands = [
  ("option1", "Mario", "OOZ5GsZLaGKDZsuJs1R1"), // calm, steady, CLINICAL (slight Chicago)
  ("option2", "BlueAshby", "lVwI5jj77lJwTyfW90VR"), // 30-40s, authoritative, news-read clean
  ("option3", "Phil", "GxEkXZFVTiRn1HdPNqar"), // 40yo, well articulated, professional
  ("option4", "Jeff", "lnFzEtvLAfx8I9DtiJTS"), // mid-40s, neutral with subtle southern grain
]
let supCands = [
  ("option1", "Dejuan", "dIa7afHH94O36L8tjJ0L"), // calm, precise, "trusted government"
  ("option2", "Gunner", "JcwFVpR60FiOW4cPEqI2"), // confident, authoritative middle-aged
  ("option3", "McKenna", "0CzFgqWMbnF10T0hetDR"), // authoritative, instructional
  ("option4", "Weinberger", "ltbmbnwfUORor5VY3adr"), // older, plain, explainer-clear
]

let renderLine = async (tag: string, i: int, voice: string, txt: string): path => {
  let p = Path(tmp ++ "/" ++ tag ++ "_" ++ Belt.Int.toString(i) ++ ".mp3")
  let b = await tts(~text=Text(txt), ~voice=VoiceId(voice))
  writeBytes(p, b)
}

let rec renderCand = async (tag, voice, lines, i, acc: array<path>): array<path> =>
  if i >= Belt.Array.length(lines) {
    acc
  } else {
    let lp = await renderLine(tag, i, voice, Belt.Array.getExn(lines, i))
    let beat = silence(Millis(600), Path(tmp))
    await renderCand(tag, voice, lines, i + 1, Belt.Array.concatMany([acc, [lp, beat]]))
  }

let rec runRole = async (role, lines, cands, i): unit =>
  if i >= Belt.Array.length(cands) {
    ()
  } else {
    let (opt, name, voice) = Belt.Array.getExn(cands, i)
    let parts = await renderCand(role ++ "_" ++ opt, voice, lines, 0, [])
    let out = dir ++ "/SKY-KING_" ++ role ++ "-audition_" ++ opt ++ "_" ++ name ++ ".mp3"
    let _ = concatAudio(parts, Path(out))
    Js.log("AUDITION " ++ role ++ " " ++ opt ++ " (" ++ name ++ ") -> " ++ out)
    await runRole(role, lines, cands, i + 1)
  }

let main = async () => {
  await runRole("price", priceLines, priceCands, 0)
  await runRole("supervisor", supLines, supCands, 0)
}
main()->ignore
