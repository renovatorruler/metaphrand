/* SKY KING — cold open (v2) AUDIO, orchestrated in ReScript. A "fancy table
   read": the screenplay performed by the cast (dialogue + the cleaned action
   lines read by the narrator), lightly scored.
   STRUCTURE: pure wordless music sets the mood, softly tapers down, then the
   scene plays low underneath. Uses the APPROVED 130s bed (music_outro.mp3) — NO
   regeneration. Voices: Tyler=Birdy, Bill=Bishop (radio), Brian=narrator.
   Action-line text is the screenplay's, through clear-pane/humanizer. */
open Cinema_Backends

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"
let tmp = dir ++ "/cold_open_rs"
let cache = tmp ++ "/cache"

let narrV = VoiceId("nPczCjzI2devNBz1zQrb")  // Brian — narrator (American)
let birdyV = VoiceId("raMcNf2S8wCmuaBcyI6E") // Tyler — Birdy
let bishopV = VoiceId("pqHfZKP75CvOlQylNhV4") // Bill — Bishop (radio)

type role = Narr | Birdy | Bishop
let voiceOf = r =>
  switch r {
  | Narr => narrV
  | Birdy => birdyV
  | Bishop => bishopV
  }
let isRadio = r =>
  switch r {
  | Bishop => true
  | _ => false
  }

let key = (VoiceId(v), txt) => {
  let san = (v ++ "_" ++ txt)->Js.String2.replaceByRe(%re("/[^A-Za-z0-9]/g"), "")
  Js.String2.slice(san, ~from=0, ~to_=40) ++ "_" ++ Belt.Int.toString(Js.String2.length(txt))
}

/* the spoken section — the screenplay's CLEANED action lines (Narr) woven with
   the dialogue. The two wide establishers stay wordless (the mood-set). */
let script = [
  (Narr, "A man sits alone at the controls, in ground-crew clothes and an orange vest. One hand on the yoke. He isn't doing much. He's looking out the window.", 700),
  (Bishop, "How's it look up there.", 700),
  (Birdy, "Real something. You ought to see this mountain. Pink all over the top.", 700),
  (Bishop, "I'll take your word for it. Stuck down here.", 550),
  (Narr, "He smiles a little. He banks the plane a few degrees, slow, so the light stays on his face. The horizon tips, then steadies.", 500),
  (Birdy, "Water's like glass. You can see the whole way down.", 700),
  (Bishop, "Yeah?", 650),
  (Birdy, "Didn't think it'd look like this.", 800),
  (Narr, "The plane flies on. He's easy, a man enjoying a flight. Then a shape slides into view outside the left window and stays there. A fighter jet, grey and armed, close enough to see the pilot's helmet turned toward him. Out the right window, another one rides his wing. Birdy glances at them. He doesn't seem surprised, like they've been there a while.", 850),
  (Birdy, "Your boys are still out here with me.", 700),
  (Bishop, "They're just keeping you company.", 800),
  (Narr, "The jets hold their stations off each wingtip, the little airliner between them.", 650),
  (Bishop, "Birdy. I need you to start thinking about bringing her down. While you've still got the light.", 800),
  (Narr, "Birdy watches the light flat on the water, far below.", 550),
  (Birdy, "Yeah. I'm not ready to do that just yet.", 850),
  (Narr, "He flies on. The jets ride his wings. The mountain's still in the glass, pink at the top.", 300),
]

let renderSeg = async (role: role, txt: string): path => {
  let k = key(voiceOf(role), txt)
  let base = Path(cache ++ "/" ++ k ++ ".mp3")
  if !exists(base) {
    let b = await tts(~text=Text(txt), ~voice=voiceOf(role))
    let _ = writeBytes(base, b)
  }
  if isRadio(role) {
    let radio = Path(cache ++ "/" ++ k ++ ".radio.mp3")
    if !exists(radio) {
      let _ = Cinema_Audio.radioize(base)
    }
    radio
  } else {
    base
  }
}

let rec renderAll = async (i: int, acc: array<path>): array<path> =>
  if i >= Belt.Array.length(script) {
    acc
  } else {
    let (role, txt, gap) = Belt.Array.getExn(script, i)
    let sp = await renderSeg(role, txt)
    let beat = silence(Millis(gap), Path(tmp))
    await renderAll(i + 1, Belt.Array.concatMany([acc, [sp, beat]]))
  }

let f = (x: float) => Js.Float.toFixedWithPrecision(x, ~digits=2)

let main = async () => {
  let bed = tmp ++ "/music_outro.mp3" // the APPROVED 130s bed — no regeneration
  let withBeats = await renderAll(0, [])
  let parts = Belt.Array.slice(withBeats, ~offset=0, ~len=Belt.Array.length(withBeats) - 1)
  let Path(body) = concatAudio(parts, Path(tmp ++ "/body.mp3"))

  /* ~40s of music in front (mood-set + the soft taper), short tail. */
  let padded = tmp ++ "/padded7.mp3"
  ffmpeg([
    "-nostdin", "-loglevel", "error", "-y", "-i", body,
    "-af", "adelay=40000:all=1,apad=pad_dur=3", "-codec:a", "libmp3lame", "-b:a", "160k", padded,
  ])

  let Seconds(total) = durationSec(Path(padded))
  /* full 0.85 to 28s; SOFT taper to 0.22 across 28-42s; hold low under the read;
     the 130s bed fades out at its own end (124-130s). */
  let vol =
    "if(lt(t,28),0.85,if(lt(t,42),0.85-(t-28)*0.045,if(lt(t,124),0.22,if(lt(t,130),0.22-(t-124)*0.0367,0))))"
  let scored = dir ++ "/cold_open_v2_tableread_v7.mp3"
  ffmpeg([
    "-nostdin", "-loglevel", "error", "-y", "-i", padded, "-i", bed,
    "-filter_complex",
    "[1:a]aresample=44100,volume='" ++ vol ++ "':eval=frame[m];[0:a][m]amix=inputs=2:duration=first:normalize=0[mix]",
    "-map", "[mix]", "-codec:a", "libmp3lame", "-b:a", "160k", scored,
  ])
  Js.log("COLD OPEN v7 (approved bed) -> " ++ scored ++ "  | total " ++ f(total) ++ "s | bed 130s")
}

main()->ignore
