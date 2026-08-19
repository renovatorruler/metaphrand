/* Deterministic, zero-credit B01 motion plate.

   The accepted empty Cheel-nest frame remains the visual source. A slow
   camera drift keeps the plate alive while two thin, right-facing gold arcs
   carry the delayed letter echo out of the nest. No model or network call is
   available from this module. */

module B = Cinema_Backends

exception B01LocalError(string)

let fail = message => raise(B01LocalError(message))

let width = 1280
let height = 720
let fps = 24
let durationSeconds = 10.0
let rippleOriginX = 640
let rippleOriginY = 340
let firstStartFrame = 12
let secondStartFrame = 30
let endFrame = 198
let pixelsPerFrame = 4.5

type buildResult = {
  output: string,
  contact: string,
  outputSha256: string,
  probe: string,
}

let rippleRadius = (~frame, ~startFrame) =>
  frame < startFrame ? 0.0 : Belt.Int.toFloat(frame - startFrame) *. pixelsPerFrame

let rippleActive = (~frame, ~startFrame) => frame >= startFrame && frame <= endFrame

let requireFile = path =>
  if !B.exists(B.Path(path)) {
    fail("expected B01 source is missing: " ++ path)
  }

let build = (~root): buildResult => {
  let source = root ++ "/start_frames/B01.png"
  let clips = root ++ "/clips"
  let qa = root ++ "/qa"
  let output = clips ++ "/B01.mp4"
  let contact = qa ++ "/B01_local_contact.png"

  requireFile(source)
  B.ensureDirPath(B.Path(clips))
  B.ensureDirPath(B.Path(qa))

  let alpha =
    `if(gt(X,${Belt.Int.toString(rippleOriginX)})*lt(abs(hypot(X-${Belt.Int.toString(rippleOriginX)},Y-${Belt.Int.toString(rippleOriginY)})-(N-${Belt.Int.toString(firstStartFrame)})*${Js.Float.toString(pixelsPerFrame)}),2.5)*between(N,${Belt.Int.toString(firstStartFrame)},180),180,if(gt(X,${Belt.Int.toString(rippleOriginX)})*lt(abs(hypot(X-${Belt.Int.toString(rippleOriginX)},Y-${Belt.Int.toString(rippleOriginY)})-(N-${Belt.Int.toString(secondStartFrame)})*${Js.Float.toString(pixelsPerFrame)}),2.5)*between(N,${Belt.Int.toString(secondStartFrame)},${Belt.Int.toString(endFrame)}),140,0))`

  B.ffmpeg([
    "-y",
    "-v",
    "error",
    "-loop",
    "1",
    "-framerate",
    Belt.Int.toString(fps),
    "-i",
    source,
    "-f",
    "lavfi",
    "-i",
    `color=c=black@0.0:s=${Belt.Int.toString(width)}x${Belt.Int.toString(height)}:r=${Belt.Int.toString(fps)}:d=${Js.Float.toString(durationSeconds)},format=rgba`,
    "-filter_complex",
    `[0:v]scale=1344:756,zoompan=z='min(1.0+0.00008*on,1.018)':x='iw/2-(iw/zoom/2)+4*sin(on/38)':y='ih/2-(ih/zoom/2)+2*sin(on/51)':d=1:s=${Belt.Int.toString(width)}x${Belt.Int.toString(height)}:fps=${Belt.Int.toString(fps)}[base];[1:v]geq=r='245':g='190':b='60':a='${alpha}',boxblur=1:1[ripple];[base][ripple]overlay=format=auto,format=yuv420p[out]`,
    "-map",
    "[out]",
    "-t",
    Js.Float.toString(durationSeconds),
    "-r",
    Belt.Int.toString(fps),
    "-an",
    "-c:v",
    "libx264",
    "-preset",
    "slow",
    "-crf",
    "17",
    "-movflags",
    "+faststart",
    output,
  ])

  B.ffmpeg([
    "-y",
    "-v",
    "error",
    "-i",
    output,
    "-vf",
    "fps=1,scale=320:180,tile=5x2",
    "-frames:v",
    "1",
    contact,
  ])

  let probe = B.run(
    ~cmd="ffprobe",
    ~args=[
      "-v",
      "error",
      "-show_entries",
      "stream=codec_type,codec_name,width,height,r_frame_rate:format=duration",
      "-of",
      "default=nw=1",
      output,
    ],
  )
  if probe.code != 0 {
    fail("B01 ffprobe failed: " ++ probe.stderr)
  }

  {output, contact, outputSha256: B.sha256File(B.Path(output)), probe: probe.stdout}
}
