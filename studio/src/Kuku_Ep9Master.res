/* कुकु और अक्षर EP9 — production master of the main story.

   Differs from the review proxy in three ways the parent asked for: the picture is CLEAN
   (no shot-number chips — those exist only so they can point at a shot), it stays at the
   full 1280x720 master size instead of the 540p review scale, and the score sits under the
   dialogue.

   Audio, in the order the mixing rules require:
     dialogue + sound effects   the already-mixed guide stem (lines at -17 LUFS, effects -20)
     score                      -26 LUFS beds, then SIDECHAIN-DUCKED by the dialogue stem so
                                music always gives way to a line rather than fighting it
   The episode's letter (ब) rides the top-right corner throughout, as on the review cut.

   Run from studio/:
     node src/Kuku_Ep9Master.res.mjs <clean-silent.mp4> <dialogue-sfx.m4a> <master-out.mp4> */

open Cinema_Backends

@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external exitProcess: int => unit = "exit"
@module("node:path") external dirname: string => string = "dirname"
@module("node:path") external resolve2: (string, string) => string = "resolve"

exception MasterError(string)
let fail = m => raise(MasterError(m))

let finale = "../stories/kuku/ep9prod/finale"

let objectOf = (j, w) =>
  switch Js.Json.decodeObject(j) {
  | Some(o) => o
  | None => fail(w ++ " is not an object")
  }
let field = (o, k, w) =>
  switch Js.Dict.get(o, k) {
  | Some(v) => v
  | None => fail(w ++ " missing " ++ k)
  }
let stringField = (o, k, w) =>
  switch field(o, k, w)->Js.Json.decodeString {
  | Some(s) => s
  | None => fail(w ++ "." ++ k ++ " must be text")
  }
let floatField = (o, k, w) =>
  switch field(o, k, w)->Js.Json.decodeNumber {
  | Some(n) => n
  | None => fail(w ++ "." ++ k ++ " must be a number")
  }
let arrayField = (o, k, w) =>
  switch field(o, k, w)->Js.Json.decodeArray {
  | Some(a) => a
  | None => fail(w ++ "." ++ k ++ " must be an array")
  }

let build = (~picture, ~dialogue, ~out) => {
  [picture, dialogue]->Belt.Array.forEach(p =>
    if !exists(Path(p)) {
      fail("missing input: " ++ p)
    }
  )
  let Seconds(pictureSeconds) = probeDuration(Path(picture))
  let total = Js.Float.toString(Js.Math.round(pictureSeconds))

  let scorePath = finale ++ "/manifests/ep9_score_cues.v1.json"
  let cues = if exists(Path(scorePath)) {
    let root = objectOf(Js.Json.parseExn(readText(Path(scorePath))), "score manifest")
    arrayField(root, "cues", "score manifest")->Belt.Array.map(c => {
      let o = objectOf(c, "score cue")
      (
        resolve2(finale ++ "/manifests", stringField(o, "path", "score cue")),
        floatField(o, "startSeconds", "score cue"),
        switch Js.Dict.get(o, "gain")->Belt.Option.flatMap(Js.Json.decodeNumber) {
        | Some(g) => g
        | None => 1.0
        },
      )
    })
  } else {
    []
  }
  let cues = cues->Belt.Array.keep(((p, _, _)) => exists(Path(p)))
  Js.log(Belt.Int.toString(Belt.Array.length(cues)) ++ " score cues under the dialogue")

  /* input 0 = picture, input 1 = dialogue+sfx stem, inputs 2.. = score cues */
  let inputs = ref(["-nostdin", "-v", "error", "-y", "-i", picture, "-i", dialogue])
  cues->Belt.Array.forEach(((p, _, _)) => {
    inputs := Belt.Array.concat(inputs.contents, ["-i", p])
  })
  let bug = finale ++ "/local/fx/ba_bug.png"
  let hasBug = exists(Path(bug))
  if hasBug {
    inputs := Belt.Array.concat(inputs.contents, ["-loop", "1", "-i", bug])
  }
  let bugIndex = 2 + Belt.Array.length(cues)

  /* score: place each cue, fade its edges, sum, then duck under the dialogue stem */
  /* each cue carries its own bed level: action cues at full, dialogue-led cues stepped back */
  let scoreFilters = cues->Belt.Array.mapWithIndex((i, (_, start, gain)) => {
    let idx = Belt.Int.toString(i + 2)
    let delayMs = Belt.Int.toString(Belt.Float.toInt(start *. 1000.0))
    "[" ++ idx ++ ":a]aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo," ++
    "volume=" ++ Js.Float.toString(gain) ++ "," ++
    "afade=t=in:st=0:d=2,areverse,afade=t=in:st=0:d=3,areverse," ++
    "adelay=delays=" ++ delayMs ++ ":all=1[m" ++ idx ++ "]"
  })
  let scoreMix =
    Belt.Array.length(cues) == 0
      ? ""
      : cues->Belt.Array.mapWithIndex((i, _) => "[m" ++ Belt.Int.toString(i + 2) ++ "]")
        ->Js.Array2.joinWith("") ++
        "amix=inputs=" ++ Belt.Int.toString(Belt.Array.length(cues)) ++
        ":duration=longest:dropout_transition=0:normalize=0[score];"

  let audioChain = if Belt.Array.length(cues) == 0 {
    "[1:a]aresample=48000,apad=whole_dur=" ++ total ++ ",atrim=0:" ++ total ++ "[aout];"
  } else {
    Js.Array2.joinWith(scoreFilters, ";") ++ ";" ++ scoreMix ++
    /* the dialogue stem is both the mix's spine and the ducking key */
    "[1:a]aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo,asplit=2[dry][key];" ++
    "[score][key]sidechaincompress=threshold=0.05:ratio=7:attack=25:release=420:makeup=1[duck];" ++
    "[dry][duck]amix=inputs=2:duration=first:dropout_transition=0:normalize=0," ++
    "alimiter=limit=0.95,apad=whole_dur=" ++ total ++ ",atrim=0:" ++ total ++ "[aout];"
  }

  let videoChain = hasBug
    ? "[0:v]scale=1280:720:force_original_aspect_ratio=increase,crop=1280:720,setsar=1[v];" ++
      "[" ++ Belt.Int.toString(bugIndex) ++ ":v]format=rgba,scale=96:-1," ++
      "colorchannelmixer=aa=0.55[bug];[v][bug]overlay=W-w-20:16[vout]"
    : "[0:v]scale=1280:720:force_original_aspect_ratio=increase,crop=1280:720,setsar=1[vout]"

  ffmpeg(Belt.Array.concatMany([
    inputs.contents,
    [
      "-filter_complex", audioChain ++ videoChain,
      "-map", "[vout]", "-map", "[aout]",
      "-c:v", "libx264", "-preset", "slow", "-crf", "19", "-pix_fmt", "yuv420p",
      "-r", "24", "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-ac", "2",
      "-t", total, "-movflags", "+faststart", out,
    ],
  ]))

  let Seconds(d) = probeDuration(Path(out))
  if Js.Math.abs_float(d -. pictureSeconds) > 0.2 {
    fail("master duration drifted from the picture: " ++ Js.Float.toString(d))
  }
  Js.log("MASTER: " ++ out)
  Js.log("  " ++ Js.Float.toFixedWithPrecision(d, ~digits=1) ++ "s, 1280x720, clean picture")
  Js.log("  sha256 " ++ sha256File(Path(out)))
}

switch argv->Belt.Array.sliceToEnd(2) {
| [picture, dialogue, out] =>
  try build(
    ~picture=resolve2(".", picture),
    ~dialogue=resolve2(".", dialogue),
    ~out=resolve2(".", out),
  ) catch {
  | MasterError(m)
  | BackendError(m) => {
      Js.Console.error("MASTER FAILED: " ++ m)
      exitProcess(1)
    }
  }
| _ => {
    Js.Console.error(
      "usage: node src/Kuku_Ep9Master.res.mjs <clean-silent.mp4> <dialogue-sfx.m4a> <out.mp4>",
    )
    exitProcess(2)
  }
}
