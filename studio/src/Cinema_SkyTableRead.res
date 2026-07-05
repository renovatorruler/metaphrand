/* Produce the cold-open table read FROM THE GATED SCENE. Write.read verifies the
   receipt first — a scene that didn't come through the engine cannot be produced.
   Then: ~40s wordless music, soft taper, the narrator reads the action and the
   cast read the dialogue (Bishop on the radio), over the approved bed. */
open Cinema_Backends

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"
let tmp = dir ++ "/cold_open_rs"
let cache = tmp ++ "/cache"
let scenePath = Path(dir ++ "/sky-king-cold-open.scene.txt")

let narr = VoiceId("nPczCjzI2devNBz1zQrb")  // Brian — narrator
let birdy = VoiceId("raMcNf2S8wCmuaBcyI6E") // Tyler
let bishop = VoiceId("pqHfZKP75CvOlQylNhV4") // Bill

let voiceFor = who =>
  switch Js.String2.toUpperCase(who) {
  | "BISHOP" => bishop
  | _ => birdy
  }

let key = (VoiceId(v), txt) => {
  let san = (v ++ "_" ++ txt)->Js.String2.replaceByRe(%re("/[^A-Za-z0-9]/g"), "")
  Js.String2.slice(san, ~from=0, ~to_=40) ++ "_" ++ Belt.Int.toString(Js.String2.length(txt))
}

let renderSeg = async (voice, txt, radio) => {
  let k = key(voice, txt)
  let base = Path(cache ++ "/" ++ k ++ ".mp3")
  if !exists(base) {
    let b = await tts(~text=Text(txt), ~voice)
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
    let beat = silence(Millis(750), Path(tmp))
    await renderAll(segs, i + 1, Belt.Array.concatMany([acc, [sp, beat]]))
  }

let f = x => Js.Float.toFixedWithPrecision(x, ~digits=2)

let main = async () =>
  switch Write.read(scenePath) {
  | Error(m) => Js.log("REFUSED — scene did not verify: " ++ m)
  | Ok(lns) =>
    let segs = lns->Belt.Array.map(segOf)
    let withBeats = await renderAll(segs, 0, [])
    let parts = Belt.Array.slice(withBeats, ~offset=0, ~len=Belt.Array.length(withBeats) - 1)
    let Path(body) = concatAudio(parts, Path(tmp ++ "/tr_body.mp3"))
    let padded = tmp ++ "/tr_padded.mp3"
    ffmpeg([
      "-nostdin", "-loglevel", "error", "-y", "-i", body,
      "-af", "adelay=40000:all=1,apad=pad_dur=3", "-codec:a", "libmp3lame", "-b:a", "160k", padded,
    ])
    let Seconds(total) = durationSec(Path(padded))
    let vol = "if(lt(t,28),0.85,if(lt(t,42),0.85-(t-28)*0.045,if(lt(t,124),0.22,if(lt(t,130),0.22-(t-124)*0.0367,0))))"
    let scored = dir ++ "/cold_open_tableread_engine_v1.mp3"
    ffmpeg([
      "-nostdin", "-loglevel", "error", "-y", "-i", padded, "-i", tmp ++ "/music_outro.mp3",
      "-filter_complex",
      "[1:a]aresample=44100,volume='" ++ vol ++ "':eval=frame[m];[0:a][m]amix=inputs=2:duration=first:normalize=0[mix]",
      "-map", "[mix]", "-codec:a", "libmp3lame", "-b:a", "160k", scored,
    ])
    Js.log("TABLE READ (engine scene) -> " ++ scored ++ " | total " ++ f(total) ++ "s")
  }

main()->ignore
