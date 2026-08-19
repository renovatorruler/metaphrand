/* Deterministic, zero-credit B05 wingbeat plate.

   The accepted five-dragon frame is never regenerated. Code-native wing-air
   and dust layers make two shared beats visible, while a final local camera
   tilt begins the third beat and stops before liftoff. The source bodies and
   all five blank bracelets remain untouched. */

module B = Cinema_Backends
@module("node:path") external dirnamePath: string => string = "dirname"

exception B05LocalError(string)

let fail = message => raise(B05LocalError(message))

let width = 1280
let height = 720
let fps = 24
let durationSeconds = 8.0
let dragonCount = 5
let firstBeatStart = 0.45
let secondBeatStart = 2.75
let thirdBeatStart = 5.25
let liftoffBegins = 8.0

type buildResult = {
  output: string,
  contact: string,
  outputSha256: string,
  probe: string,
}

let beatAt = seconds =>
  seconds < secondBeatStart
    ? 1
    : seconds < thirdBeatStart
    ? 2
    : 3

let cameraTiltY = seconds =>
  seconds <= thirdBeatStart
    ? 36.0
    : Js.Math.max_float(
        0.0,
        36.0 -. 36.0 *. (seconds -. thirdBeatStart) /. (liftoffBegins -. thirdBeatStart),
      )

let dustRise = (~seconds, ~start) =>
  seconds <= start ? 0.0 : Js.Math.min_float(22.0, 12.0 *. (seconds -. start))

let requireFile = path =>
  if !B.exists(B.Path(path)) {
    fail("expected B05 source is missing: " ++ path)
  }

let requireSuccess = (~label, result: B.runResult) =>
  if result.code != 0 {
    fail(
      label ++ " failed (exit " ++ Belt.Int.toString(result.code) ++ "): " ++
      Js.String2.slice(result.stderr, ~from=0, ~to_=1200),
    )
  }

let renderSvg = (~svg, ~png, ~width, ~height) => {
  let directory = dirnamePath(svg)
  let raw = svg ++ ".png"
  let preview = B.run(
    ~cmd="qlmanage",
    ~args=["-t", "-s", Belt.Int.toString(Js.Math.max_int(width, height)), "-o", directory, svg],
  )
  requireSuccess(~label="B05 SVG raster", preview)
  requireFile(raw)
  B.ffmpeg([
    "-y", "-v", "error", "-i", raw,
    "-vf",
    `crop=${Belt.Int.toString(width)}:${Belt.Int.toString(height)}:0:0,colorkey=0x000000:0.15:0.06,format=rgba`,
    "-frames:v", "1", png,
  ])
  requireFile(png)
}

let wingAirSvg = `
<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="1280" viewBox="0 0 1280 1280">
  <rect width="1280" height="1280" fill="#000000"/>
  <g fill="none" stroke="#8c6335" stroke-linecap="round">
    <path d="M74 333 Q102 417 80 510" stroke-width="5"/><path d="M118 351 Q150 425 135 500" stroke-width="3"/>
    <path d="M252 383 Q222 438 225 505" stroke-width="4"/><path d="M352 395 Q385 448 382 510" stroke-width="3"/>
    <path d="M304 105 Q404 246 470 343" stroke-width="6"/><path d="M979 104 Q865 242 790 346" stroke-width="6"/>
    <path d="M342 141 Q429 250 497 329" stroke-width="3"/><path d="M940 145 Q855 252 764 334" stroke-width="3"/>
    <path d="M804 407 Q831 449 821 513" stroke-width="4"/><path d="M990 404 Q1018 448 1018 509" stroke-width="4"/>
    <path d="M1034 421 Q1058 462 1052 520" stroke-width="4"/><path d="M1187 411 Q1210 461 1201 520" stroke-width="4"/>
  </g>
</svg>`

let dustSvg = `
<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="1280" viewBox="0 0 1280 1280">
  <rect width="1280" height="1280" fill="#000000"/>
  <g fill="#9f714a">
    <ellipse cx="118" cy="194" rx="92" ry="28"/><ellipse cx="286" cy="215" rx="138" ry="30"/>
    <ellipse cx="492" cy="190" rx="132" ry="34"/><ellipse cx="696" cy="213" rx="148" ry="31"/>
    <ellipse cx="902" cy="192" rx="130" ry="33"/><ellipse cx="1104" cy="211" rx="146" ry="30"/>
  </g>
  <g fill="none" stroke="#bd8547" stroke-linecap="round">
    <path d="M35 226 Q232 166 430 221" stroke-width="4"/>
    <path d="M364 233 Q640 148 918 226" stroke-width="5"/>
    <path d="M835 226 Q1041 168 1248 218" stroke-width="4"/>
  </g>
</svg>`

let shadowSvg = `
<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="1280" viewBox="0 0 1280 1280">
  <rect width="1280" height="1280" fill="#000000"/>
  <g fill="#6d524e">
    <ellipse cx="151" cy="610" rx="82" ry="16"/><ellipse cx="330" cy="613" rx="77" ry="15"/>
    <ellipse cx="626" cy="646" rx="135" ry="19"/><ellipse cx="914" cy="610" rx="84" ry="15"/>
    <ellipse cx="1122" cy="602" rx="75" ry="14"/>
  </g>
</svg>`

let build = (~root): buildResult => {
  let source = root ++ "/start_frames/B05.png"
  let local = root ++ "/local/b05"
  let clips = root ++ "/clips"
  let qa = root ++ "/qa"
  let output = clips ++ "/B05.mp4"
  let contact = qa ++ "/B05_local_contact.png"

  requireFile(source)
  B.ensureDirPath(B.Path(local))
  B.ensureDirPath(B.Path(clips))
  B.ensureDirPath(B.Path(qa))

  let assets = [
    ("wing_air", wingAirSvg, 1280, 720),
    ("dust", dustSvg, 1280, 260),
    ("shadows", shadowSvg, 1280, 720),
  ]
  assets->Belt.Array.forEach(((name, body, assetWidth, assetHeight)) => {
    let svg = local ++ "/" ++ name ++ ".svg"
    let png = local ++ "/" ++ name ++ ".png"
    B.writeText(B.Path(svg), body)
    renderSvg(~svg, ~png, ~width=assetWidth, ~height=assetHeight)
  })

  B.ffmpeg([
    "-y", "-v", "error",
    "-loop", "1", "-framerate", Belt.Int.toString(fps), "-i", source,
    "-loop", "1", "-framerate", Belt.Int.toString(fps), "-i", local ++ "/wing_air.png",
    "-loop", "1", "-framerate", Belt.Int.toString(fps), "-i", local ++ "/dust.png",
    "-loop", "1", "-framerate", Belt.Int.toString(fps), "-i", local ++ "/shadows.png",
    "-filter_complex",
    `[0:v]scale=1344:756,crop=1280:720:x=32:y='if(lt(t,5.25),36-2.5*sin(2*PI*t/2.3),max(0,36-36*(t-5.25)/2.75))'[base];[1:v]format=rgba,colorchannelmixer=aa=.32,split=2[aw1][aw2];[aw1]fade=t=in:st=0.45:d=0.25:alpha=1,fade=t=out:st=1.75:d=0.45:alpha=1[arc1];[aw2]fade=t=in:st=2.75:d=0.25:alpha=1,fade=t=out:st=4.2:d=0.5:alpha=1[arc2];[2:v]format=rgba,colorchannelmixer=aa=.34,gblur=sigma=2,split=2[dw1][dw2];[dw1]fade=t=in:st=0.55:d=0.25:alpha=1,fade=t=out:st=1.9:d=0.55:alpha=1[dust1];[dw2]fade=t=in:st=2.85:d=0.25:alpha=1,fade=t=out:st=4.65:d=0.65:alpha=1[dust2];[3:v]format=rgba,colorchannelmixer=aa=.20,fade=t=in:st=2.8:d=0.3:alpha=1,fade=t=out:st=4.5:d=0.5:alpha=1[shadows];[base][shadows]overlay=0:0[s1];[s1][arc1]overlay=x=0:y='8*(t-0.45)':enable='between(t,0.45,2.2)'[s2];[s2][dust1]overlay=x='-40*(t-0.55)':y='460-12*(t-0.55)':enable='between(t,0.55,2.45)'[s3];[s3][arc2]overlay=x=0:y='10*(t-2.75)':enable='between(t,2.75,4.7)'[s4];[s4][dust2]overlay=x='-55*(t-2.85)':y='455-15*(t-2.85)':enable='between(t,2.85,5.3)',format=yuv420p[out]`,
    "-map", "[out]", "-frames:v", "192", "-r", Belt.Int.toString(fps), "-an",
    "-c:v", "libx264", "-preset", "slow", "-crf", "16", "-movflags", "+faststart", output,
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
  requireSuccess(~label="B05 ffprobe", probe)
  {output, contact, outputSha256: B.sha256File(B.Path(output)), probe: probe.stdout}
}
