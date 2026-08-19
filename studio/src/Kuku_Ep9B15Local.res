/* Deterministic, zero-credit B15 transport shot.

   Accepted A08 supplies the gate and cloud-stage plate. Accepted A09 supplies
   the exact five dragon appearances and goat through local foreground masks.
   A locally authored, locked Devanagari glyph is one rigid transport object.
   Every dragon and the glyph share the same displacement curve; the goat and
   gate remain fixed, so the rescue geography reads clearly with sound off. */

module B = Cinema_Backends

exception B15LocalError(string)

let fail = message => raise(B15LocalError(message))

let width = 1280
let height = 720
let fps = 24
let durationSeconds = 10.0
let frameCount = 240
let hasNativeAudio = false
let dragonCount = 5
let glyphCount = 1
let goatCount = 1
let glyphWidth = 340
let glyphHeight = 400

let progressAt = seconds =>
  Js.Math.max_float(0.0, Js.Math.min_float(1.0, seconds /. durationSeconds))

let groupXAt = seconds => -.170.0 *. progressAt(seconds)

let groupYAt = seconds => {
  let progress = progressAt(seconds)
  16.0 *. Js.Math.sin(Js.Math._PI *. progress) -. 20.0 *. progress
}

type buildResult = {
  output: string,
  contact: string,
  startFrame: string,
  outputSha256: string,
  startFrameSha256: string,
  probe: string,
}

let requireFile = path =>
  if !B.exists(B.Path(path)) {
    fail("expected B15 source is missing: " ++ path)
  }

let requireSuccess = (~label, result: B.runResult) =>
  if result.code != 0 {
    fail(
      label ++ " failed (exit " ++ Belt.Int.toString(result.code) ++ "): " ++
      Js.String2.slice(result.stderr, ~from=0, ~to_=1600),
    )
  }

let build = (~root): buildResult => {
  let source = root ++ "/references/A08.png"
  let local = root ++ "/local/b14_b15"
  let instances = local ++ "/instances"
  let output = root ++ "/clips/B15.mp4"
  let contact = root ++ "/qa/B15_local_contact.png"
  let startFrame = root ++ "/start_frames/B15.png"
  let chosen = local ++ "/air_path_chosen_rgba.png"
  let goat = local ++ "/goat_rgba.png"
  let glyph = local ++ "/rescue_b_transport_rgba.png"
  let furia = instances ++ "/furia_1.png"
  let leda = instances ++ "/leda_1.png"
  let castor = instances ++ "/castor_1.png"
  let kuku = instances ++ "/kuku_1.png"
  let vesper = instances ++ "/vesper_2.png"

  [source, chosen, goat, glyph, furia, leda, castor, kuku, vesper]
  ->Belt.Array.forEach(requireFile)
  B.ensureDirPath(B.Path(root ++ "/clips"))
  B.ensureDirPath(B.Path(root ++ "/qa"))
  B.ensureDirPath(B.Path(root ++ "/start_frames"))

  let xMove = "-17*t"
  let yMove = "+16*sin(PI*t/10)-2*t"
  B.ffmpeg([
    "-y", "-v", "error",
    "-loop", "1", "-framerate", Belt.Int.toString(fps), "-i", source,
    "-loop", "1", "-framerate", Belt.Int.toString(fps), "-i", chosen,
    "-loop", "1", "-framerate", Belt.Int.toString(fps), "-i", goat,
    "-loop", "1", "-framerate", Belt.Int.toString(fps), "-i", glyph,
    "-loop", "1", "-framerate", Belt.Int.toString(fps), "-i", furia,
    "-loop", "1", "-framerate", Belt.Int.toString(fps), "-i", leda,
    "-loop", "1", "-framerate", Belt.Int.toString(fps), "-i", castor,
    "-loop", "1", "-framerate", Belt.Int.toString(fps), "-i", kuku,
    "-loop", "1", "-framerate", Belt.Int.toString(fps), "-i", vesper,
    "-filter_complex",
    `[0:v]scale=1280:720:force_original_aspect_ratio=increase,crop=1280:720,setsar=1[base];[1:v]format=rgba,colorchannelmixer=aa=0.42[path];[2:v]format=rgba[goat];[3:v]format=rgba[glyph];[4:v]scale=220:215:flags=lanczos,format=rgba[furia];[5:v]scale=240:160:flags=lanczos,format=rgba[leda];[6:v]scale=225:220:flags=lanczos,format=rgba[castor];[7:v]scale=240:175:flags=lanczos,format=rgba[kuku];[8:v]scale=220:160:flags=lanczos,format=rgba[vesper];[base][path]overlay=0:0[p];[p][goat]overlay=405:185[g];[g][glyph]overlay=x='720${xMove}':y='155${yMove}'[x1];[x1][furia]overlay=x='675${xMove}':y='400${yMove}'[x2];[x2][kuku]overlay=x='505${xMove}':y='400${yMove}'[x3];[x3][leda]overlay=x='820${xMove}':y='60${yMove}'[x4];[x4][castor]overlay=x='925${xMove}':y='310${yMove}'[x5];[x5][vesper]overlay=x='805${xMove}':y='480${yMove}',format=yuv420p[out]`,
    "-map", "[out]", "-frames:v", Belt.Int.toString(frameCount),
    "-r", Belt.Int.toString(fps), "-an", "-c:v", "libx264", "-preset", "slow",
    "-crf", "16", "-movflags", "+faststart", output,
  ])

  B.ffmpeg([
    "-y", "-v", "error", "-i", output,
    "-vf", "fps=1,scale=320:180,tile=5x2", "-frames:v", "1", contact,
  ])
  B.ffmpeg([
    "-y", "-v", "error", "-i", output, "-frames:v", "1", startFrame,
  ])

  let probe = B.run(
    ~cmd="ffprobe",
    ~args=[
      "-v", "error", "-show_entries",
      "stream=codec_type,codec_name,width,height,r_frame_rate,nb_frames:format=duration",
      "-of", "default=nw=1", output,
    ],
  )
  requireSuccess(~label="B15 ffprobe", probe)
  {
    output,
    contact,
    startFrame,
    outputSha256: B.sha256File(B.Path(output)),
    startFrameSha256: B.sha256File(B.Path(startFrame)),
    probe: probe.stdout,
  }
}
