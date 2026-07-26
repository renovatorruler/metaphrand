/* KUKU — OmniHuman talking-shot PROOF for the papercraft-dragon cast. A Kuku
   face-on still + one real tagged ElevenLabs line -> lip-synced clip in our own
   voice. Proves (or disproves) the audio-first talking/wordless split for this
   show's non-human characters before we commit Ep2 to it. ~4s x ~$0.14/s ≈ $0.55
   on fal. Run from studio/ with FAL_AI exported:
     node src/Kuku_TalkTest.res.mjs */
open Cinema_Backends

@val @scope("process") external cwd: unit => string = "cwd"

let dir = cwd() ++ "/../stories/kuku/talktest"
let img = Path(dir ++ "/kuku_talk_900.jpg")
let aud = Path(dir ++ "/kuku_test_line.mp3")
let out = Path(dir ++ "/KUKU_TALK_TEST.mp4")

let main = async () => {
  Js.log("=== OmniHuman papercraft-dragon test: Kuku speaks his own ElevenLabs line ===")
  switch await falOmnihumanUrl(~imageUrl="https://dustys-mac-studio.tail9e29c.ts.net:10000/kukuvid/kuku_talk_900.jpg", ~audioUrl="https://dustys-mac-studio.tail9e29c.ts.net:10000/kukuvid/kuku_test_line.mp3") {
  | clip => {
      let _ = writeBytes(out, clip)
      let Path(p) = out
      Js.log("WROTE " ++ p)
    }
  | exception Js.Exn.Error(e) =>
    Js.log2("FAL ERROR:", Js.Exn.message(e)->Belt.Option.getWithDefault("(no message)"))
  | exception e => Js.log2("RAW ERROR:", e)
  }
}
main()->ignore
