/* One cheap PAID call through the ReScript backend, to prove the live ElevenLabs
   binding works end to end (fetch -> blob -> disk -> ffprobe). One TTS line. */
open Cinema_Backends

let main = async () => {
  let out = Path("/Users/dusty/dev/brehon-law/stories/sky-king/rs_tts_test.mp3")
  let blob = await tts(~text=Text("Radio check. One, two."), ~voice=VoiceId("pqHfZKP75CvOlQylNhV4"))
  let _ = writeBytes(out, blob)
  let Seconds(d) = durationSec(out)
  let mb = fileSizeMb(out)
  Js.log(
    "RS TTS OK — " ++
    Js.Float.toString(mb) ++ " MB, duration " ++ Js.Float.toString(d) ++ "s",
  )
}

main()->ignore
