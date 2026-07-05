/* SKY KING — CONTINUOUS TABLE-READ VIDEO: the whole scene performed as ONE
   ElevenLabs v3 text-to-dialogue take (natural turn-taking + the per-line audio
   tags from performance.json), with name+line captions landed EXACTLY via the
   returned voice_segments timing.  Run: node src/Cinema_SkyDialogueVideo.res.mjs <id> */
open Cinema_Backends

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"
let tmp = dir ++ "/dialoguevid_rs"

@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external exit: int => unit = "exit"

let narr = VoiceId("nPczCjzI2devNBz1zQrb")
let bill = VoiceId("pqHfZKP75CvOlQylNhV4")
/* current cast — kept in sync with Cinema_SkySceneRead.voiceFor. */
let voiceFor = who =>
  switch Js.String2.trim(Js.String2.toUpperCase(who)) {
  | "BIRDY" => VoiceId("VZcBEw9QXVSghzV5UKLN")
  | "MAYA" => VoiceId("hpp4J3VqNfWAUOO0d1Us")
  | "DORIS" => VoiceId("wGcFBfKz5yUQqhqr0mVy")
  | "REYES" => VoiceId("lVpo6IOLjDX4LxkYRZyj")
  | "COLE" => VoiceId("EGvjD0PIKVzXUvyMkwel")
  | "SHAW" => VoiceId("XrExE9yKIg1WjnnlVkGX")
  | "DEZ" => VoiceId("mWRBtRP92mUXZzi4RZ0Y")
  | "TANNER" => VoiceId("IkksQWAjbvt9CKa7hRkh")
  | "GUS" => VoiceId("0GKwxxcRYcg0OlQ1l822")
  | "WARD" => VoiceId("CwhRBWXzGAHq8TQ4Fs17")
  | "MARQUEZ" => VoiceId("iP95p4xoKVk53GoZ742B")
  | "DEACON" => VoiceId("DNKm8TNHmk5sujtJn8zk")
  | "BANJO" => VoiceId("KjZZHIOnbFqvGnNEwISh")
  | "TOWER" => VoiceId("2GuF5ZgBYwz69Rmc9gM2")
  | "SUPERVISOR" => VoiceId("JcwFVpR60FiOW4cPEqI2")
  | "VOSS" => VoiceId("TTyZrDYo6LQowrH8mixJ")
  | "MERCER" => VoiceId("dIa7afHH94O36L8tjJ0L")
  | "CONTROLLER" => VoiceId("2GuF5ZgBYwz69Rmc9gM2")
  | "RADIO" => VoiceId("pqHfZKP75CvOlQylNhV4")
  | "BISHOP" => VoiceId("PKu46bbccMP1b22TyeI0")
  | "PRICE" => VoiceId("lVwI5jj77lJwTyfW90VR")
  | "KEMP" => VoiceId("GxEkXZFVTiRn1HdPNqar")
  | "NARRATOR" => narr
  | _ => bill
  }

let fields = sp =>
  switch sp {
  | Write.Action(t) => ("NARRATOR", t)
  | Write.Dialogue({who, text, radio: _}) => (Js.String2.trim(Js.String2.toUpperCase(who)), text)
  }

let esc = s =>
  s
  ->Js.String2.replaceByRe(%re("/&/g"), "&amp;")
  ->Js.String2.replaceByRe(%re("/</g"), "&lt;")
  ->Js.String2.replaceByRe(%re("/>/g"), "&gt;")

let displayName = who => who == "NARRATOR" ? "NARRATION" : who

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

let clipFor = (Path(card), dur, idx) => {
  let out = tmp ++ "/clip" ++ Belt.Int.toString(idx) ++ ".mp4"
  ffmpeg([
    "-nostdin", "-loglevel", "error", "-y", "-loop", "1", "-i", card,
    "-filter_complex", "color=c=0x0e1218:s=1280x720[bg];[bg][0:v]overlay=(W-w)/2:(H-h)/2[v]",
    "-map", "[v]", "-t", Js.Float.toString(dur), "-r", "24", "-c:v", "libx264", "-preset", "veryfast",
    "-pix_fmt", "yuv420p", out,
  ])
  Path(out)
}

let f1 = x => Js.Float.toFixedWithPrecision(x, ~digits=1)

let timesToJson = ts =>
  "[" ++
  ts
  ->Belt.Array.map(((s, e)) => "[" ++ Js.Float.toString(s) ++ "," ++ Js.Float.toString(e) ++ "]")
  ->Js.Array2.joinWith(",") ++ "]"

let loadTimes = (path, n) => {
  let rows = switch Js.Json.decodeArray(Js.Json.parseExn(readText(path))) {
  | Some(r) => r
  | None => []
  }
  Belt.Array.makeBy(n, i =>
    switch Belt.Array.get(rows, i)->Belt.Option.flatMap(Js.Json.decodeArray) {
    | Some(pair) =>
      let g = j => Belt.Array.get(pair, j)->Belt.Option.flatMap(Js.Json.decodeNumber)->Belt.Option.getWithDefault(0.0)
      (g(0), g(1))
    | None => (0.0, 0.0)
    }
  )
}

let main = async () => {
  let id = Belt.Array.get(argv, 2)->Belt.Option.getWithDefault("")
  if id == "" {
    Js.log("usage: node src/Cinema_SkyDialogueVideo.res.mjs <scene-id>")
  } else {
    switch Write.read(Path(dir ++ "/" ++ id ++ ".scene.txt")) {
    | Error(m) => Js.log("REFUSED — scene did not verify: " ++ m)
    | Ok(allLines) =>
      /* optional [start] [count] to render a continuous take of a LINE RANGE
         (the whole-scene take exceeds ElevenLabs' non-streaming timeout). */
      let start = Belt.Array.get(argv, 3)->Belt.Option.flatMap(Belt.Int.fromString)->Belt.Option.getWithDefault(0)
      let count = Belt.Array.get(argv, 4)->Belt.Option.flatMap(Belt.Int.fromString)->Belt.Option.getWithDefault(Belt.Array.length(allLines))
      let lines = Belt.Array.slice(allLines, ~offset=start, ~len=count)
      let n = Belt.Array.length(lines)
      let tags = loadTags(Path(dir ++ "/" ++ id ++ ".performance.json"), n)
      let inputs = lines->Belt.Array.mapWithIndex((i, sp) => {
        let (who, txt) = fields(sp)
        let tag = Belt.Array.getExn(tags, i)
        (Text(tag == "" ? txt : tag ++ " " ++ txt), voiceFor(who))
      })
      let audioPath = Path(dir ++ "/" ++ id ++ "_dialogue.mp3")
      let timesPath = Path(dir ++ "/" ++ id ++ "_dialogue.times.json")
      let times = if exists(audioPath) && exists(timesPath) {
        Js.log("using cached continuous take")
        loadTimes(timesPath, n)
      } else {
        Js.log("text-to-dialogue (with timing) for " ++ Belt.Int.toString(n) ++ " lines (~realtime) ...")
        let (audio, ts) = await dialogueTimed(inputs)
        let _ = writeBytes(audioPath, audio)
        writeText(timesPath, timesToJson(ts))
        ts
      }
      let Seconds(total) = durationSec(audioPath)
      Js.log("continuous take: " ++ f1(total) ++ "s")
      /* ElevenLabs voice_segments run on a timeline ~3-4% SHORTER than the actual
         mp3 (segments end before the audio does), which ran the captions AHEAD and
         growing. Scale every segment time onto the real audio duration. */
      let maxEnd = times->Belt.Array.reduce(0.0, (m, (_s, e)) => Js.Math.max_float(m, e))
      let factor = maxEnd > 0.0 ? total /. maxEnd : 1.0
      Js.log("timeline scale: audio " ++ f1(total) ++ "s / segments " ++ f1(maxEnd) ++ "s = " ++ Js.Float.toFixedWithPrecision(factor, ~digits=4))
      let starts = times->Belt.Array.map(((s, _e)) => s *. factor)
      /* one card per line */
      let cards = lines->Belt.Array.mapWithIndex((i, sp) => {
        let (who, txt) = fields(sp)
        cardFor(who, txt, i)
      })
      /* DRIFT-FREE: one encode, audio is the master timeline (input 0), each card
         overlaid at its ABSOLUTE segment time via enable='between(t,S,E)'. No
         concatenation, so no per-clip rounding can accumulate. */
      let Path(ap) = audioPath
      let inputs = Belt.Array.concat(
        ["-i", ap],
        Belt.Array.concatMany(cards->Belt.Array.map(((Path(c)) => ["-loop", "1", "-i", c]))),
      )
      let f3 = x => Js.Float.toFixedWithPrecision(x, ~digits=3)
      let overlays = lines->Belt.Array.mapWithIndex((i, _sp) => {
        let st = Belt.Array.getExn(starts, i)
        let en = i < n - 1 ? Belt.Array.getExn(starts, i + 1) : total
        let prev = i == 0 ? "b" : "o" ++ Belt.Int.toString(i - 1)
        "[" ++
        prev ++
        "][" ++
        Belt.Int.toString(i + 1) ++
        ":v]overlay=x=(W-w)/2:y=(H-h)/2:enable='between(t," ++
        f3(st) ++ "," ++ f3(en) ++ ")'[o" ++ Belt.Int.toString(i) ++ "]"
      })
      let filter = "color=c=0x0e1218:s=1280x720:r=24[b];" ++ Js.Array2.joinWith(overlays, ";")
      let out = dir ++ "/" ++ id ++ "_dialoguevideo.mp4"
      ffmpeg(
        Belt.Array.concatMany([
          ["-nostdin", "-loglevel", "error", "-y"],
          inputs,
          [
            "-filter_complex", filter,
            "-map", "[o" ++ Belt.Int.toString(n - 1) ++ "]", "-map", "0:a",
            "-shortest", "-r", "24", "-c:v", "libx264", "-preset", "veryfast", "-pix_fmt", "yuv420p",
            "-c:a", "aac", "-b:a", "160k", out,
          ],
        ]),
      )
      Js.log("CONTINUOUS NAME+LINE VIDEO (drift-free) -> " ++ out ++ " (" ++ f1(total) ++ "s)")
    }
  }
  exit(0)
}
main()->ignore
