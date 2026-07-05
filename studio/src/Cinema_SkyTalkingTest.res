/* OmniHuman talking-shot test — the OWN-AUDIO path. A Birdy face still + our exact
   ElevenLabs performance -> lip-synced video in our OWN voice. Proves the split:
   wordless = Seedance 2.0, talking = OmniHuman over our real audio. The line is two
   verbatim home-scene Birdy lines run together (~3.5s). Budget: OmniHuman ~$0.14/s
   x ~4s ~= $0.55. One call. Run: node src/Cinema_SkyTalkingTest.res.mjs */
open Cinema_Backends

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king/video-tests"
let img = Path(dir ++ "/driving_birdy_900.jpg")
let audioOut = Path(dir ++ "/birdy_line_talkingtest.mp3")
let videoOut = Path(dir ++ "/SKY-KING_talking-test_omnihuman_birdy_v1.mp4")

let birdy = VoiceId("raMcNf2S8wCmuaBcyI6E")
let line = "I'm alright. I ate. I won't. Just this leg."

let main = async () => {
  let t0 = Js.Date.now()
  let Path(ap) = audioOut
  let Path(vp) = videoOut
  Js.log("=== OmniHuman talking-shot test — Birdy, our own ElevenLabs voice (~$0.55) ===")
  try {
    /* 1) our exact ElevenLabs performance of the line (eleven_v3) — cached */
    if !exists(audioOut) {
      let voice = await dialogue([(Text(line), birdy)])
      let _ = writeBytes(audioOut, voice)
      Js.log("audio (new) -> " ++ ap)
    } else {
      Js.log("audio (cached) -> " ++ ap)
    }
    /* 2) OmniHuman: the still + our audio -> lip-synced talking video */
    let vid = await falOmnihuman(~image=img, ~audio=audioOut)
    let _ = writeBytes(videoOut, vid)
    let secs = (Js.Date.now() -. t0) /. 1000.0
    Js.log("WROTE: " ++ vp)
    Js.log("elapsed: " ++ Js.Float.toFixed(secs) ++ "s")
  } catch {
  | BackendError(m) => Js.log("BACKEND ERROR: " ++ m)
  }
}

main()->ignore
