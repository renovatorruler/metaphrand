/* Deterministic, zero-credit C12 rhythm-comparison insert.

   The accepted B09 five-dragon flight stays fully visible in the right panel.
   A narrow left panel reuses the accepted C05 Rishi/staff performance, without
   showing the younger children. A slow gold ring leaves the real staff tip
   every 1.5 seconds while the flight panel carries the already faster wing
   rhythm. This is an editorial comparison, not a new identity or magic rule.
   No SVG rasterizer, provider, network client, credential, model, or audio is
   available from this module. */

module B = Cinema_Backends

exception C12LocalError(string)

let fail = message => raise(C12LocalError(message))

let width = 1280
let height = 720
let fps = 24
let durationSeconds = 3.0
let staffPulseSeconds = 1.5
let wingPulseSeconds = 0.5
let wingMarkCount = 5
let rishiPanelWidth = 360
let flightPanelWidth = 920
let rishiCount = 1
let flyingDragonCount = 5
let nativeAudio = false

type buildResult = {
  output: string,
  contact: string,
  outputSha256: string,
  probe: string,
}

let pulseCount = (~duration, ~period) => Belt.Float.toInt(duration /. period)

let requireFile = path =>
  if !B.exists(B.Path(path)) {
    fail("expected accepted C12 reuse source is missing: " ++ path)
  }

let requireSuccess = (~label, result: B.runResult) =>
  if result.code != 0 {
    fail(
      label ++ " failed (exit " ++ Belt.Int.toString(result.code) ++ "): " ++
      Js.String2.slice(result.stderr, ~from=0, ~to_=1200),
    )
  }

let build = (~root): buildResult => {
  let flightSource = root ++ "/clips/B09.mp4"
  let rishiSource = root ++ "/clips/C05.mp4"
  let clips = root ++ "/clips"
  let qa = root ++ "/qa"
  let output = clips ++ "/C12.mp4"
  let contact = qa ++ "/C12_local_contact.png"

  requireFile(flightSource)
  requireFile(rishiSource)
  B.ensureDirPath(B.Path(clips))
  B.ensureDirPath(B.Path(qa))

  /* The ring is centered on the accepted staff tip after the C05 portrait
     crop. It expands only during the first half of each 36-frame period and
     dissolves before the next slow pulse. */
  let pulsePhase = `mod(N,36)/18`
  let pulseRadius = `25+65*(${pulsePhase})`
  let pulseDistance = `sqrt(pow(X-108,2)+pow(Y-164,2))`
  let pulseAlpha =
    `if(lt(mod(N,36),18),190*(1-${pulsePhase})*exp(-pow((${pulseDistance}-${pulseRadius})/7,2)),0)`

  B.ffmpeg([
    "-y", "-v", "error", "-i", flightSource, "-i", rishiSource,
    "-f", "lavfi", "-i", "nullsrc=s=360x720:r=24:d=3,format=rgba",
    "-filter_complex",
    `[0:v]trim=start=0.3:end=3.3,setpts=PTS-STARTPTS,split=2[flightback][flightfront];` ++
    `[flightback]scale=1280:720,crop=920:720:x=180,gblur=sigma=24[flightbg];` ++
    `[flightfront]scale=920:518,eq=brightness='0.018*sin(2*PI*t/.5)':eval=frame[flightfg];` ++
    `[flightbg][flightfg]overlay=0:101[flight];` ++
    `[1:v]trim=start=2.0:end=5.0,setpts=PTS-STARTPTS,` ++
    `crop=540:1080:x=220:y=0,scale=360:720[rishi];` ++
    `[2:v]geq=r='255':g='220':b='105':a='${pulseAlpha}',gblur=sigma=1[pulse];` ++
    `[rishi][pulse]overlay=0:0[staff];` ++
    `[staff][flight]hstack=inputs=2,drawbox=x=356:y=0:w=8:h=720:color=0xd7a94a@.92:t=fill,` ++
    `scale=1312:738,crop=1280:720:x='16+1.5*sin(t*.8)':y='9+1.2*sin(t*.65)',` ++
    `format=yuv420p[out]`,
    "-map", "[out]", "-frames:v", "72", "-r", "24", "-an",
    "-c:v", "libx264", "-preset", "slow", "-crf", "16", "-movflags", "+faststart", output,
  ])

  B.ffmpeg([
    "-y", "-v", "error", "-i", output,
    "-vf", "fps=1,scale=320:180,tile=3x1", "-frames:v", "1", contact,
  ])

  let probe = B.run(
    ~cmd="ffprobe",
    ~args=[
      "-v", "error", "-show_entries",
      "stream=codec_type,codec_name,width,height,r_frame_rate,nb_frames:format=duration",
      "-of", "default=nw=1", output,
    ],
  )
  requireSuccess(~label="C12 ffprobe", probe)
  {output, contact, outputSha256: B.sha256File(B.Path(output)), probe: probe.stdout}
}
