/* SKY KING — TABLE-READ VIDEO: performed audio + on-screen NAME + LINE, so a
   scene can be judged by ear while you SEE who's speaking. Reads a gated
   <id>.scene.txt (verify-then-parse) AND <id>.performance.json (per-line v3 audio
   tags, authored by Cinema_SkyPerform). Each line: its tag prepended for delivery
   + a per-character v3 voice setting; rendered as a [name+line card + audio] clip;
   the clips concatenate to the scene.  Run: node src/Cinema_SkySceneVideo.res.mjs <id> */
open Cinema_Backends

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"
let tmp = dir ++ "/scenevid_rs"
let cache = tmp ++ "/cache"

@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external exit: int => unit = "exit"

let narr = VoiceId("nPczCjzI2devNBz1zQrb")
let bill = VoiceId("pqHfZKP75CvOlQylNhV4")

let voiceFor = who =>
  switch who {
  | "BIRDY" => VoiceId("raMcNf2S8wCmuaBcyI6E")
  | "MAYA" => VoiceId("b0XAJReHClzJsXv2FxoO")
  | "DEZ" => VoiceId("iP95p4xoKVk53GoZ742B")
  | "TANNER" => VoiceId("cjVigY5qzO86Huf0OWal")
  | "GUS" => VoiceId("CwhRBWXzGAHq8TQ4Fs17")
  | "WARD" => VoiceId("cWo9xRzWIidua0ZsVaGx")
  | "NARRATOR" => narr
  | _ => bill
  }

let vs = (stability, style) => {
  let d = Js.Dict.empty()
  Js.Dict.set(d, "stability", Js.Json.number(stability))
  Js.Dict.set(d, "similarity_boost", Js.Json.number(0.8))
  Js.Dict.set(d, "style", Js.Json.number(style))
  Js.Dict.set(d, "use_speaker_boost", Js.Json.boolean(true))
  Js.Json.object_(d)
}
/* per-character v3 expression (lower stability = more expressive, higher style =
   more coloured). The per-line audio tag (from performance.json) rides on top. */
let settingsFor = who =>
  switch who {
  | "BIRDY" => vs(0.45, 0.45)
  | "DEZ" => vs(0.4, 0.5)
  | "TANNER" => vs(0.65, 0.15)
  | "MAYA" => vs(0.45, 0.4)
  | "GUS" => vs(0.45, 0.45)
  | "WARD" => vs(0.55, 0.3)
  | _ => vs(0.5, 0.25)
  }

let fields = sp =>
  switch sp {
  | Write.Action(t) => ("NARRATOR", t, false)
  | Write.Dialogue({who, radio, text}) => (Js.String2.trim(Js.String2.toUpperCase(who)), text, radio)
  }

let esc = s =>
  s
  ->Js.String2.replaceByRe(%re("/&/g"), "&amp;")
  ->Js.String2.replaceByRe(%re("/</g"), "&lt;")
  ->Js.String2.replaceByRe(%re("/>/g"), "&gt;")

let key = (VoiceId(v), txt) => {
  let san = (v ++ "_" ++ txt)->Js.String2.replaceByRe(%re("/[^A-Za-z0-9]/g"), "")
  Js.String2.slice(san, ~from=0, ~to_=44) ++ "_" ++ Belt.Int.toString(Js.String2.length(txt))
}

let displayName = who => who == "NARRATOR" ? "NARRATION" : who

/* load per-line tags from <id>.performance.json (empty strings if absent). */
let loadTags = (path, n) => {
  let tags = Belt.Array.make(n, "")
  if exists(path) {
    switch Js.Json.decodeArray(Js.Json.parseExn(readText(path))) {
    | Some(arr) =>
      arr->Belt.Array.forEach(o =>
        switch Js.Json.decodeObject(o) {
        | Some(d) =>
          let gi = Js.Dict.get(d, "i")->Belt.Option.flatMap(Js.Json.decodeNumber)->Belt.Option.map(Belt.Float.toInt)
          let gt = Js.Dict.get(d, "tag")->Belt.Option.flatMap(Js.Json.decodeString)
          switch (gi, gt) {
          | (Some(ix), Some(tg)) =>
            if ix >= 0 && ix < n {
              Belt.Array.setExn(tags, ix, tg)
            }
          | _ => ()
          }
        | None => ()
        }
      )
    | None => ()
    }
  }
  tags
}

let audioFor = async (who, ttsText, radio) => {
  let vc = voiceFor(who)
  let k = key(vc, ttsText)
  let base = Path(cache ++ "/" ++ k ++ ".mp3")
  if !exists(base) {
    let b = await tts(~text=Text(ttsText), ~voice=vc, ~settings=settingsFor(who))
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

let cardFor = (who, txt, idx) => {
  let markup = if who == "NARRATOR" {
    "<span font=\"Georgia Italic 27\" foreground=\"#aeb6c2\">" ++ esc(txt) ++ "</span>"
  } else {
    "<span font=\"Georgia Bold 48\" foreground=\"#ffffff\">" ++
    esc(displayName(who)) ++
    "</span>\n\n<span font=\"Georgia 31\" foreground=\"#dbe0ea\">" ++ esc(txt) ++ "</span>"
  }
  pango(~markup, ~width=780, ~background="#0e1218", ~out=Path(tmp ++ "/card" ++ Belt.Int.toString(idx) ++ ".png"))
}

let clipFor = (Path(card), Path(audio), idx) => {
  let out = tmp ++ "/clip" ++ Belt.Int.toString(idx) ++ ".mp4"
  ffmpeg([
    "-nostdin", "-loglevel", "error", "-y",
    "-loop", "1", "-i", card,
    "-i", audio,
    "-filter_complex",
    "color=c=0x0e1218:s=1280x720[bg];[bg][0:v]overlay=(W-w)/2:(H-h)/2[v];[1:a]apad=pad_dur=0.4[a]",
    "-map", "[v]", "-map", "[a]",
    "-shortest", "-r", "24", "-c:v", "libx264", "-preset", "veryfast", "-pix_fmt", "yuv420p",
    "-c:a", "aac", "-b:a", "160k", "-ar", "44100", out,
  ])
  Path(out)
}

let rec build = async (lines, tags, i, clips) =>
  if i >= Belt.Array.length(lines) {
    clips
  } else {
    let (who, txt, radio) = fields(Belt.Array.getExn(lines, i))
    let tag = Belt.Array.getExn(tags, i)
    let ttsText = tag == "" ? txt : tag ++ " " ++ txt
    let audio = await audioFor(who, ttsText, radio)
    let card = cardFor(who, txt, i)
    let clip = clipFor(card, audio, i)
    await build(lines, tags, i + 1, Belt.Array.concat(clips, [clip]))
  }

let main = async () => {
  let id = Belt.Array.get(argv, 2)->Belt.Option.getWithDefault("")
  if id == "" {
    Js.log("usage: node src/Cinema_SkySceneVideo.res.mjs <scene-id>")
  } else {
    switch Write.read(Path(dir ++ "/" ++ id ++ ".scene.txt")) {
    | Error(m) => Js.log("REFUSED — scene did not verify: " ++ m)
    | Ok(lines) =>
      let tags = loadTags(Path(dir ++ "/" ++ id ++ ".performance.json"), Belt.Array.length(lines))
      let clips = await build(lines, tags, 0, [])
      let list = clips->Belt.Array.map(((Path(c)) => "file '" ++ c ++ "'"))->Js.Array2.joinWith("\n")
      writeText(Path(tmp ++ "/list.txt"), list)
      let out = dir ++ "/" ++ id ++ "_namelinevideo.mp4"
      ffmpeg([
        "-nostdin", "-loglevel", "error", "-y", "-f", "concat", "-safe", "0",
        "-i", tmp ++ "/list.txt", "-c", "copy", out,
      ])
      let tagged = tags->Belt.Array.keep(t => t != "")->Belt.Array.length
      let Seconds(dtot) = durationSec(Path(out))
      Js.log(
        "NAME+LINE VIDEO -> " ++
        out ++
        " (" ++
        Belt.Int.toString(Belt.Array.length(lines)) ++
        " lines, " ++
        Belt.Int.toString(tagged) ++
        " tagged, " ++
        Js.Float.toFixedWithPrecision(dtot, ~digits=1) ++ "s)",
      )
    }
  }
  exit(0)
}
main()->ignore
