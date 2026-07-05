/* SKY KING — ACT VIDEO: assemble a list of gated scenes into ONE caption video
   (name + line on screen, performed audio underneath), for YouTube review. Uses
   the SAME cast + fx (radio/PA/whisper) + perform.json overlay + cache as the
   table-read renderer (Cinema_SkySceneRead), so the per-line audio is REUSED
   from tableread_rs/cache (no re-TTS). Each scene gets a title card; each line a
   name+line card; all clips concat drift-free (each clip carries its own synced
   audio). Run: node src/SkyKing_ActVideo.res.mjs <act-name> <id1> <id2> ...
   (voiceFor is duplicated from Cinema_SkySceneRead — keep in sync.) */
open Cinema_Backends

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"
let cache = dir ++ "/tableread_rs/cache" // REUSE the table-read audio cache
let tmp = dir ++ "/actvid_rs"

@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external exit: int => unit = "exit"

let narr = VoiceId("nPczCjzI2devNBz1zQrb")
let bill = VoiceId("pqHfZKP75CvOlQylNhV4")

/* DUPLICATED from Cinema_SkySceneRead.voiceFor — keep identical. */
let voiceFor = who =>
  switch Js.String2.trim(Js.String2.toUpperCase(who)) {
  | "BIRDY" => VoiceId("VZcBEw9QXVSghzV5UKLN")
  | "MAYA" => VoiceId("hpp4J3VqNfWAUOO0d1Us")
  | "DORIS" => VoiceId("wGcFBfKz5yUQqhqr0mVy")
  | "REYES" => VoiceId("lVpo6IOLjDX4LxkYRZyj")
  | "COLE" => VoiceId("EGvjD0PIKVzXUvyMkwel")
  | "SHAW" => VoiceId("XrExE9yKIg1WjnnlVkGX")
  | "ARTHUR" => bill
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
  | _ => VoiceId("SAz9YHcvj6GT2YYXdXww")
  }

type fx = Clean | Radio | Pa
let radioChars = ["TOWER", "RADIO", "CONTROLLER"] // NOT Deacon/Banjo — seen in person; they use explicit (RADIO) tags
let isRadio = who => Belt.Array.some(radioChars, c => c == Js.String2.trim(Js.String2.toUpperCase(who)))

let key = (VoiceId(v), txt) => {
  let san = (v ++ "_" ++ txt)->Js.String2.replaceByRe(%re("/[^A-Za-z0-9]/g"), "")
  Js.String2.slice(san, ~from=0, ~to_=40) ++ "_" ++ Belt.Int.toString(Js.String2.length(txt))
}

let perfFor = id => {
  let p = Path(dir ++ "/" ++ id ++ ".perform.json")
  if exists(p) {
    switch Js.Json.parseExn(readText(p))->Js.Json.decodeObject {
    | Some(o) =>
      o
      ->Js.Dict.entries
      ->Belt.Array.keepMap(((k, v)) => Js.Json.decodeString(v)->Belt.Option.map(s => (k, s)))
      ->Js.Dict.fromArray
    | None => Js.Dict.empty()
    }
  } else {
    Js.Dict.empty()
  }
}

let slugOf = id =>
  Js.Json.parseExn(readText(Path(dir ++ "/" ++ id ++ ".scene.txt.receipt.json")))
  ->Js.Json.decodeObject
  ->Belt.Option.flatMap(o => Js.Dict.get(o, "slug"))
  ->Belt.Option.flatMap(Js.Json.decodeString)
  ->Belt.Option.getWithDefault("SCENE")

/* reuse the cached per-line audio; generate only if somehow missing. */
let audioPath = async (vc, finalTxt, fx) => {
  let k = key(vc, finalTxt)
  let base = Path(cache ++ "/" ++ k ++ ".mp3")
  if !exists(base) {
    let b = await tts(~text=Text(finalTxt), ~voice=vc)
    let _ = writeBytes(base, b)
  }
  switch fx {
  | Clean => base
  | Radio =>
    let r = Path(cache ++ "/" ++ k ++ ".radio.mp3")
    if !exists(r) {
      let _ = Cinema_Audio.radioize(base)
    }
    r
  | Pa =>
    let p = Path(cache ++ "/" ++ k ++ ".pa.mp3")
    if !exists(p) {
      let _ = Cinema_Audio.paize(base)
    }
    p
  }
}

let esc = s =>
  s
  ->Js.String2.replaceByRe(%re("/&/g"), "&amp;")
  ->Js.String2.replaceByRe(%re("/</g"), "&lt;")
  ->Js.String2.replaceByRe(%re("/>/g"), "&gt;")

let lineCard = (who, txt, idx) => {
  let markup = if who == "" {
    "<span font=\"Georgia Italic 27\" foreground=\"#aeb6c2\">" ++ esc(txt) ++ "</span>"
  } else {
    "<span font=\"Georgia Bold 46\" foreground=\"#ffffff\">" ++
    esc(who) ++
    "</span>\n\n<span font=\"Georgia 31\" foreground=\"#dbe0ea\">" ++ esc(txt) ++ "</span>"
  }
  pango(~markup, ~width=820, ~background="#0e1218", ~out=Path(tmp ++ "/card" ++ Belt.Int.toString(idx) ++ ".png"))
}

let titleCardImg = (slug, idx) => {
  let markup =
    "<span font=\"Georgia Bold 40\" foreground=\"#c8d0dc\">" ++ esc(slug) ++ "</span>"
  pango(~markup, ~width=980, ~background="#0e1218", ~out=Path(tmp ++ "/title" ++ Belt.Int.toString(idx) ++ ".png"))
}

let clipFor = (Path(card), Path(audio), idx) => {
  let out = tmp ++ "/clip" ++ Belt.Int.toString(idx) ++ ".mp4"
  ffmpeg([
    "-nostdin", "-loglevel", "error", "-y",
    "-loop", "1", "-i", card,
    "-i", audio,
    "-filter_complex",
    "color=c=0x0e1218:s=1280x720[bg];[bg][0:v]overlay=(W-w)/2:(H-h)/2[v];[1:a]apad=pad_dur=0.45[a]",
    "-map", "[v]", "-map", "[a]",
    "-shortest", "-r", "24", "-c:v", "libx264", "-preset", "veryfast", "-pix_fmt", "yuv420p",
    "-c:a", "aac", "-b:a", "160k", "-ar", "44100", out,
  ])
  Path(out)
}

let counter = ref(0)
let next = () => {
  counter := counter.contents + 1
  counter.contents
}

let rec buildScene = async (id, lines, perf, i, clips) =>
  if i >= Belt.Array.length(lines) {
    clips
  } else {
    let sp = Belt.Array.getExn(lines, i)
    let (who, disp, whisperTxt, fx) = switch sp {
    | Write.Action(t) => (narr, "", t, Clean)
    | Write.Dialogue({who, radio, text, whisper}) =>
      let w = Js.String2.trim(Js.String2.toUpperCase(who))
      let f = w == "PA" ? Pa : radio || isRadio(who) ? Radio : Clean
      (voiceFor(who), w, (whisper ? "[whispering] " : "") ++ text, f)
    }
    let dispText = switch sp {
    | Write.Action(t) => t
    | Write.Dialogue({text}) => text
    }
    let tag = Js.Dict.get(perf, Belt.Int.toString(i))->Belt.Option.getWithDefault("")
    let finalTxt = tag == "" ? whisperTxt : tag ++ " " ++ whisperTxt
    let audio = await audioPath(who, finalTxt, fx)
    let ix = next()
    let card = lineCard(disp, dispText, ix)
    let clip = clipFor(card, audio, ix)
    await buildScene(id, lines, perf, i + 1, Belt.Array.concat(clips, [clip]))
  }

let rec buildAll = async (ids, j, clips) =>
  if j >= Belt.Array.length(ids) {
    clips
  } else {
    let id = Belt.Array.getExn(ids, j)
    switch Write.read(Path(dir ++ "/" ++ id ++ ".scene.txt")) {
    | Error(m) =>
      Js.log("!! SKIP " ++ id ++ ": " ++ m)
      await buildAll(ids, j + 1, clips)
    | Ok(lines) =>
      let ix = next()
      let tcard = titleCardImg(slugOf(id), ix)
      let tsil = silence(Millis(2600), Path(tmp))
      let tclip = clipFor(tcard, tsil, ix)
      let perf = perfFor(id)
      let sceneClips = await buildScene(id, lines, perf, 0, [tclip])
      Js.log("  built " ++ id ++ " (" ++ Belt.Int.toString(Belt.Array.length(lines)) ++ " lines)")
      await buildAll(ids, j + 1, Belt.Array.concat(clips, sceneClips))
    }
  }

let main = async () => {
  let actName = Belt.Array.get(argv, 2)->Belt.Option.getWithDefault("act")
  let ids = Belt.Array.sliceToEnd(argv, 3)
  if Belt.Array.length(ids) == 0 {
    Js.log("usage: node src/SkyKing_ActVideo.res.mjs <act-name> <id1> <id2> ...")
  } else {
    let clips = await buildAll(ids, 0, [])
    let list = clips->Belt.Array.map(((Path(c)) => "file '" ++ c ++ "'"))->Js.Array2.joinWith("\n")
    writeText(Path(tmp ++ "/list.txt"), list)
    let out = dir ++ "/SKY-KING_" ++ actName ++ "_namelinevideo.mp4"
    ffmpeg([
      "-nostdin", "-loglevel", "error", "-y", "-f", "concat", "-safe", "0",
      "-i", tmp ++ "/list.txt", "-c", "copy", out,
    ])
    let Seconds(dtot) = durationSec(Path(out))
    Js.log(
      "ACT VIDEO -> " ++
      out ++
      " (" ++
      Belt.Int.toString(Belt.Array.length(clips)) ++
      " clips, " ++
      Js.Float.toFixedWithPrecision(dtot /. 60.0, ~digits=1) ++ " min)",
    )
  }
  exit(0)
}
main()->ignore
