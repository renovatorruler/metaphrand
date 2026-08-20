/* कुकु और अक्षर EP9 — full episode assembly for review.

   Order the parent asked for: dream sequence (cold open) → intro title → main story →
   word review → outro track. The outro is the show's OWN credits reel (stories/kuku/KUKU_CREDITS.mp4),
   not a generated sting — an earlier build used a music_v2 cue by mistake.

   The parts differ in size and frame rate (title/credits are 1280x720@30, the review proxy
   is 960x540@24), so every part is normalised to the proxy's format before concat; a stream
   copy of mismatched parts produces a file players refuse to seek.

   Run from studio/:
     node src/Kuku_Ep9AssembleEpisode.res.mjs <main-story.mp4> <episode-out.mp4> */

open Cinema_Backends

@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external exitProcess: int => unit = "exit"
@module("node:path") external dirname: string => string = "dirname"
@module("node:path") external resolve2: (string, string) => string = "resolve"

exception AssembleError(string)
let fail = m => raise(AssembleError(m))

let kuku = "../stories/kuku"
let coldOpenPicture = kuku ++ "/ep9prod/coldopen/out/KUKU_EP9_COLD_OPEN_V1.mp4"
let coldOpenMix = kuku ++ "/ep9prod/coldopen/audio/out/EP9_COLD_OPEN_FULL_MIX_f44e2b00a2e5.wav"
let title = kuku ++ "/KUKU_TITLE.mp4"
let credits = kuku ++ "/KUKU_CREDITS.mp4"
/* the show's closing ritual: every word the episode taught, held long enough to read */
let wordReview = kuku ++ "/ep9prod/finale/out/EP9_WORD_REVIEW_720P_V1.mp4"

/* one format for every part: the 720p master format */
let normalise = (~input, ~audio: option<string>, ~out) => {
  let base = ["-nostdin", "-v", "error", "-y", "-i", input]
  let withAudio = switch audio {
  | Some(a) => Belt.Array.concat(base, ["-i", a])
  | None => base
  }
  let maps = switch audio {
  | Some(_) => ["-map", "0:v:0", "-map", "1:a:0"]
  | None => ["-map", "0:v:0", "-map", "0:a:0?"]
  }
  ffmpeg(Belt.Array.concatMany([
    withAudio,
    maps,
    [
      "-vf", "scale=1280:720:force_original_aspect_ratio=increase,crop=1280:720,setsar=1,fps=24",
      "-c:v", "libx264", "-preset", "slow", "-crf", "19", "-pix_fmt", "yuv420p",
      "-r", "24", "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-ac", "2",
      "-movflags", "+faststart", out,
    ],
  ]))
  let Seconds(d) = probeDuration(Path(out))
  d
}

let main = (~mainStory, ~out) => {
  [coldOpenPicture, coldOpenMix, title, credits, wordReview, mainStory]->Belt.Array.forEach(p =>
    if !exists(Path(p)) {
      fail("missing episode part: " ++ p)
    }
  )
  let work = dirname(out) ++ "/.episode_parts"
  ensureDirPath(Path(work))

  let dream = work ++ "/01_cold_open.mp4"
  let ttl = work ++ "/02_title.mp4"
  let show = work ++ "/03_main.mp4"
  let review = work ++ "/04_word_review.mp4"
  let outro = work ++ "/05_credits.mp4"

  let dDream = normalise(~input=coldOpenPicture, ~audio=Some(coldOpenMix), ~out=dream)
  let dTitle = normalise(~input=title, ~audio=None, ~out=ttl)
  let dShow = normalise(~input=mainStory, ~audio=None, ~out=show)
  let dReview = normalise(~input=wordReview, ~audio=None, ~out=review)
  let dOutro = normalise(~input=credits, ~audio=None, ~out=outro)

  let listPath = work ++ "/episode.concat.txt"
  writeText(
    Path(listPath),
    [dream, ttl, show, review, outro]
    ->Belt.Array.map(p => "file '" ++ resolve2(".", p) ++ "'")
    ->Js.Array2.joinWith("\n") ++ "\n",
  )
  ffmpeg([
    "-nostdin", "-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", listPath,
    "-c", "copy", "-movflags", "+faststart", out,
  ])
  let Seconds(total) = probeDuration(Path(out))
  let fmt = s => {
    let m = Belt.Float.toInt(s) / 60
    let sec = mod(Belt.Float.toInt(s), 60)
    Belt.Int.toString(m) ++ ":" ++ (sec < 10 ? "0" : "") ++ Belt.Int.toString(sec)
  }
  Js.log("EPISODE ASSEMBLED: " ++ out)
  Js.log("  dream sequence " ++ fmt(dDream))
  Js.log("  title          " ++ fmt(dTitle))
  Js.log("  main story     " ++ fmt(dShow))
  Js.log("  word review    " ++ fmt(dReview))
  Js.log("  outro          " ++ fmt(dOutro))
  Js.log("  total          " ++ fmt(total))
  if Js.Math.abs_float(total -. (dDream +. dTitle +. dShow +. dReview +. dOutro)) > 0.5 {
    fail("assembled total does not match the sum of its parts")
  }
}

switch argv->Belt.Array.sliceToEnd(2) {
| [mainStory, out] =>
  try main(~mainStory=resolve2(".", mainStory), ~out=resolve2(".", out)) catch {
  | AssembleError(m)
  | BackendError(m) => {
      Js.Console.error("EPISODE ASSEMBLY FAILED: " ++ m)
      exitProcess(1)
    }
  }
| _ => {
    Js.Console.error("usage: node src/Kuku_Ep9AssembleEpisode.res.mjs <main.mp4> <episode.mp4>")
    exitProcess(2)
  }
}
