/* Table-read audio for scene 4 (night/home), FROM the gated scene. Brian narrates
   the action; Tyler=Birdy, Suzanne=Maya, Bill (radio) = the sim headset voices.
   A low looped bed underneath for atmosphere. Only produces a verified scene. */
open Cinema_Backends

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"
let tmp = dir ++ "/cold_open_rs"
let cache = tmp ++ "/cache"
let scenePath = Path(dir ++ "/sky-king-night.scene.txt")

let narr = VoiceId("nPczCjzI2devNBz1zQrb")  // Brian — narrator
let tyler = VoiceId("raMcNf2S8wCmuaBcyI6E") // Birdy
let maya = VoiceId("b0XAJReHClzJsXv2FxoO")  // Suzanne
let voice = VoiceId("pqHfZKP75CvOlQylNhV4") // Bill — headset friends (radio)

let voiceFor = who =>
  switch Js.String2.toUpperCase(who) {
  | "BIRDY" => tyler
  | "MAYA" => maya
  | "VOICE" => voice
  | _ => narr
  }

let key = (VoiceId(v), txt) => {
  let san = (v ++ "_" ++ txt)->Js.String2.replaceByRe(%re("/[^A-Za-z0-9]/g"), "")
  Js.String2.slice(san, ~from=0, ~to_=40) ++ "_" ++ Belt.Int.toString(Js.String2.length(txt))
}
let renderSeg = async (vc, txt, radio) => {
  let k = key(vc, txt)
  let base = Path(cache ++ "/" ++ k ++ ".mp3")
  if !exists(base) {
    let b = await tts(~text=Text(txt), ~voice=vc)
    let _ = writeBytes(base, b)
  }
  if radio {
    let r = Path(cache ++ "/" ++ k ++ ".radio.mp3")
    if !exists(r) {
      let _ = Cinema_Audio.radioize(base)
    }
    r
  } else {
    base
  }
}
let segOf = sp =>
  switch sp {
  | Write.Action(t) => (narr, t, false)
  | Write.Dialogue({who, radio, text}) => (voiceFor(who), text, radio)
  }
let rec renderAll = async (segs, i, acc) =>
  if i >= Belt.Array.length(segs) {
    acc
  } else {
    let (v, t, r) = Belt.Array.getExn(segs, i)
    let sp = await renderSeg(v, t, r)
    let beat = silence(Millis(620), Path(tmp))
    await renderAll(segs, i + 1, Belt.Array.concatMany([acc, [sp, beat]]))
  }
let f = x => Js.Float.toFixedWithPrecision(x, ~digits=2)

let main = async () =>
  switch Write.read(scenePath) {
  | Error(m) => Js.log("REFUSED - scene did not verify: " ++ m)
  | Ok(lns) =>
    let segs = lns->Belt.Array.map(segOf)
    let withBeats = await renderAll(segs, 0, [])
    let parts = Belt.Array.slice(withBeats, ~offset=0, ~len=Belt.Array.length(withBeats) - 1)
    let Path(body) = concatAudio(parts, Path(tmp ++ "/night_body.mp3"))
    let padded = tmp ++ "/night_padded.mp3"
    ffmpeg([
      "-nostdin", "-loglevel", "error", "-y", "-i", body,
      "-af", "adelay=1500:all=1,apad=pad_dur=3", "-codec:a", "libmp3lame", "-b:a", "160k", padded,
    ])
    let Seconds(total) = durationSec(Path(padded))
    let os = f(total -. 3.0)
    let scored = dir ++ "/sky-king-night_audio.mp3"
    ffmpeg([
      "-nostdin", "-loglevel", "error", "-y", "-i", padded,
      "-stream_loop", "-1", "-i", tmp ++ "/music_outro.mp3",
      "-filter_complex",
      "[1:a]aresample=44100,volume=0.16,afade=t=in:st=0:d=2,afade=t=out:st=" ++ os ++ ":d=3[m];[0:a][m]amix=inputs=2:duration=first:normalize=0[mix]",
      "-map", "[mix]", "-codec:a", "libmp3lame", "-b:a", "160k", scored,
    ])
    Js.log("NIGHT AUDIO -> " ++ scored ++ "  | total " ++ f(total) ++ "s")
  }

main()->ignore
