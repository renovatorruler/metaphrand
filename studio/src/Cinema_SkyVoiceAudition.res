/* SKY KING — Birdy recasting audition. Two representative Birdy lines (gentle
   wonder + the quiet refusal) rendered in each candidate voice, so the user can
   pick the right one by ear. One stitched mp3 per candidate. ReScript only. */
open Cinema_Backends

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"
let tmp = dir ++ "/audition_rs"

let lines = [
  "Real something. You ought to see this mountain. Pink all over the top.",
  "Yeah. I'm not ready to do that just yet.",
]

/* (label, voiceId) — AMERICAN gentle/everyman candidates (Birdy is Pacific NW).
   Tyler already rendered; these three are the other usable American options. */
let candidates = [
  ("Eric", "cjVigY5qzO86Huf0OWal"),
  ("Roger", "CwhRBWXzGAHq8TQ4Fs17"),
  ("Elijah", "cWo9xRzWIidua0ZsVaGx"),
]

let renderLine = async (tag: string, i: int, voice: string, txt: string): path => {
  let p = Path(tmp ++ "/" ++ tag ++ "_" ++ Belt.Int.toString(i) ++ ".mp3")
  let b = await tts(~text=Text(txt), ~voice=VoiceId(voice))
  writeBytes(p, b)
}

let rec renderCand = async (tag: string, voice: string, i: int, acc: array<path>): array<path> =>
  if i >= Belt.Array.length(lines) {
    acc
  } else {
    let lp = await renderLine(tag, i, voice, Belt.Array.getExn(lines, i))
    let beat = silence(Millis(600), Path(tmp))
    await renderCand(tag, voice, i + 1, Belt.Array.concatMany([acc, [lp, beat]]))
  }

let rec runAll = async (i: int): unit =>
  if i >= Belt.Array.length(candidates) {
    ()
  } else {
    let (tag, voice) = Belt.Array.getExn(candidates, i)
    let parts = await renderCand(tag, voice, 0, [])
    let out = dir ++ "/SKY-KING_birdy-audition_" ++ tag ++ ".mp3"
    let _ = concatAudio(parts, Path(out))
    Js.log("AUDITION " ++ tag ++ " -> " ++ out)
    await runAll(i + 1)
  }

let main = async () => await runAll(0)
main()->ignore
