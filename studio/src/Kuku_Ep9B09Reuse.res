/* Deterministic, zero-credit B09 second-lap wide.

   Two already accepted five-dragon flight passages are offset, accelerated,
   and joined locally. This makes the wings visibly outrun the established
   training rhythm without inventing a sixth dragon or regenerating anyone. */

module B = Cinema_Backends

exception B09ReuseError(string)

let fail = message => raise(B09ReuseError(message))

let width = 1280
let height = 720
let fps = 24
let durationSeconds = 4.0
let sourceCount = 2
let sourceWindowSeconds = 3.3
let retimedWindowSeconds = 2.2
let crossfadeSeconds = 0.4
let speedFactor = sourceWindowSeconds /. retimedWindowSeconds

type buildResult = {
  output: string,
  contact: string,
  outputSha256: string,
  probe: string,
}

let runningTime = (~retimed, ~crossfade) => retimed *. 2.0 -. crossfade

let requireFile = path =>
  if !B.exists(B.Path(path)) {
    fail("expected accepted B09 reuse source is missing: " ++ path)
  }

let requireSuccess = (~label, result: B.runResult) =>
  if result.code != 0 {
    fail(
      label ++ " failed (exit " ++ Belt.Int.toString(result.code) ++ "): " ++
      Js.String2.slice(result.stderr, ~from=0, ~to_=1200),
    )
  }

let build = (~root): buildResult => {
  let sourceB06 = root ++ "/clips/B06.mp4"
  let sourceB07 = root ++ "/clips/B07.mp4"
  let clips = root ++ "/clips"
  let qa = root ++ "/qa"
  let output = clips ++ "/B09.mp4"
  let contact = qa ++ "/B09_reuse_contact.png"

  requireFile(sourceB06)
  requireFile(sourceB07)
  B.ensureDirPath(B.Path(clips))
  B.ensureDirPath(B.Path(qa))

  B.ffmpeg([
    "-y", "-v", "error", "-i", sourceB06, "-i", sourceB07,
    "-filter_complex",
    `[0:v]trim=start=1.0:end=4.3,setpts=(PTS-STARTPTS)*0.666666667,scale=1280:720,fps=24,settb=AVTB[a];` ++
    `[1:v]trim=start=3.1:end=6.4,setpts=(PTS-STARTPTS)*0.666666667,scale=1280:720,fps=24,settb=AVTB[b];` ++
    `[a][b]xfade=transition=fade:duration=0.4:offset=1.8,` ++
    `scale=1312:738,crop=1280:720:x='16+2*sin(t*2.2)':y='9+1.5*sin(t*1.7)',format=yuv420p[out]`,
    "-map", "[out]", "-frames:v", "96", "-r", "24", "-an",
    "-c:v", "libx264", "-preset", "slow", "-crf", "16", "-movflags", "+faststart", output,
  ])

  B.ffmpeg([
    "-y", "-v", "error", "-i", output,
    "-vf", "fps=1,scale=320:180,tile=4x1", "-frames:v", "1", contact,
  ])

  let probe = B.run(
    ~cmd="ffprobe",
    ~args=[
      "-v", "error", "-show_entries",
      "stream=codec_type,codec_name,width,height,r_frame_rate,nb_frames:format=duration",
      "-of", "default=nw=1", output,
    ],
  )
  requireSuccess(~label="B09 ffprobe", probe)
  {output, contact, outputSha256: B.sha256File(B.Path(output)), probe: probe.stdout}
}
