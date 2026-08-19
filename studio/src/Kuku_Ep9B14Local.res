/* Deterministic, zero-credit B14 route-choice motion.

   The accepted A09 rescue plate fixes the five-dragon, goat-cloud and broken-
   gate geography. Three code-authored air paths appear from Vesper's position.
   The unsafe direct and high routes fade independently; the calm curved route
   remains. ffmpeg performs only local compositing and a restrained camera drift. */

module B = Cinema_Backends

exception B14LocalError(string)

let fail = message => raise(B14LocalError(message))

let width = 1280
let height = 720
let fps = 24
let durationSeconds = 8.0
let frameCount = 192
let hasNativeAudio = false

let pathOrigin = (790, 520)
let gateTarget = (555, 205)

let directVisibleAt = seconds => seconds < 3.6
let highVisibleAt = seconds => seconds < 4.8
let chosenVisibleAt = _seconds => true

type buildResult = {
  output: string,
  contact: string,
  outputSha256: string,
  probe: string,
}

let requireFile = path =>
  if !B.exists(B.Path(path)) {
    fail("expected B14 source is missing: " ++ path)
  }

let requireSuccess = (~label, result: B.runResult) =>
  if result.code != 0 {
    fail(
      label ++ " failed (exit " ++ Belt.Int.toString(result.code) ++ "): " ++
      Js.String2.slice(result.stderr, ~from=0, ~to_=1600),
    )
  }

let build = (~root): buildResult => {
  let source = root ++ "/start_frames/B14.png"
  let local = root ++ "/local/b14_b15"
  let output = root ++ "/clips/B14.mp4"
  let contact = root ++ "/qa/B14_local_contact.png"
  let direct = local ++ "/air_path_direct_rgba.png"
  let high = local ++ "/air_path_high_rgba.png"
  let chosen = local ++ "/air_path_chosen_rgba.png"

  [source, direct, high, chosen]->Belt.Array.forEach(requireFile)
  B.ensureDirPath(B.Path(root ++ "/clips"))
  B.ensureDirPath(B.Path(root ++ "/qa"))

  B.ffmpeg([
    "-y", "-v", "error",
    "-loop", "1", "-framerate", Belt.Int.toString(fps), "-i", source,
    "-loop", "1", "-framerate", Belt.Int.toString(fps), "-i", direct,
    "-loop", "1", "-framerate", Belt.Int.toString(fps), "-i", high,
    "-loop", "1", "-framerate", Belt.Int.toString(fps), "-i", chosen,
    "-filter_complex",
    `[0:v]scale=1296:729,crop=1280:720:x='8+2*sin(0.55*t)':y='4+1.5*sin(0.41*t)'[base];[1:v]format=rgba,fade=t=in:st=0.12:d=0.38:alpha=1,fade=t=out:st=2.65:d=0.95:alpha=1[direct];[2:v]format=rgba,fade=t=in:st=0.42:d=0.38:alpha=1,fade=t=out:st=3.75:d=1.05:alpha=1[high];[3:v]format=rgba,colorchannelmixer=aa=0.50,fade=t=in:st=0.22:d=0.42:alpha=1[chosenLow];[3:v]format=rgba,colorchannelmixer=aa=0.44,fade=t=in:st=4.05:d=1.10:alpha=1[chosenBright];[base][direct]overlay=0:0[b1];[b1][high]overlay=0:0[b2];[b2][chosenLow]overlay=0:0[b3];[b3][chosenBright]overlay=0:0,format=yuv420p[out]`,
    "-map", "[out]", "-frames:v", Belt.Int.toString(frameCount),
    "-r", Belt.Int.toString(fps), "-an", "-c:v", "libx264", "-preset", "slow",
    "-crf", "16", "-movflags", "+faststart", output,
  ])

  B.ffmpeg([
    "-y", "-v", "error", "-i", output,
    "-vf", "fps=1,scale=320:180,tile=4x2", "-frames:v", "1", contact,
  ])

  let probe = B.run(
    ~cmd="ffprobe",
    ~args=[
      "-v", "error", "-show_entries",
      "stream=codec_type,codec_name,width,height,r_frame_rate,nb_frames:format=duration",
      "-of", "default=nw=1", output,
    ],
  )
  requireSuccess(~label="B14 ffprobe", probe)
  {output, contact, outputSha256: B.sha256File(B.Path(output)), probe: probe.stdout}
}
