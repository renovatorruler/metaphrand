/* Deterministic, zero-credit B02 motion sequence.

   The accepted cracked-gate frame supplies the world and chronology. Original
   code-native SVG layers provide the old school bell and the closed chest
   insert; they contain no writing or generated glyphs. ffmpeg performs only
   local compositing, camera drift and rigid motion. */

module B = Cinema_Backends
@module("node:path") external dirnamePath: string => string = "dirname"

exception B02LocalError(string)

let fail = message => raise(B02LocalError(message))

let width = 1280
let height = 720
let fps = 24
let durationSeconds = 8.0
let gateSeconds = 4.0
let bellSeconds = 2.0
let chestSeconds = 2.0

type buildResult = {
  output: string,
  contact: string,
  outputSha256: string,
  probe: string,
}

let segmentAt = seconds =>
  seconds < gateSeconds ? "gate" : seconds < gateSeconds +. bellSeconds ? "bell" : "chest"

let rippleX = seconds => -.50.0 +. 190.0 *. Js.Math.min_float(seconds, 2.0)
let rippleY = seconds => 520.0 -. 80.0 *. Js.Math.min_float(seconds, 2.0)

let bellAngle = seconds => 0.10 *. Js.Math.sin(Js.Math._PI *. seconds)

let ringOffset = seconds => 2.0 *. Js.Math.sin(10.0 *. Js.Math._PI *. seconds)

let requireFile = path =>
  if !B.exists(B.Path(path)) {
    fail("expected B02 source is missing: " ++ path)
  }

let requireSuccess = (~label, result: B.runResult) =>
  if result.code != 0 {
    fail(
      label ++ " failed (exit " ++ Belt.Int.toString(result.code) ++ "): " ++
      Js.String2.slice(result.stderr, ~from=0, ~to_=1200),
    )
  }

let renderSvg = (~svg, ~png, ~width, ~height, ~transparent) => {
  let directory = dirnamePath(svg)
  let raw = svg ++ ".png"
  let size = Js.Math.max_int(width, height)
  let preview = B.run(
    ~cmd="qlmanage",
    ~args=["-t", "-s", Belt.Int.toString(size), "-o", directory, svg],
  )
  requireSuccess(~label="B02 SVG raster", preview)
  requireFile(raw)
  let filter = transparent
    ? `crop=${Belt.Int.toString(width)}:${Belt.Int.toString(height)}:0:0,colorkey=0x00FF00:0.48:0.02,format=rgba`
    : `crop=${Belt.Int.toString(width)}:${Belt.Int.toString(height)}:0:0,format=rgba`
  B.ffmpeg(["-y", "-v", "error", "-i", raw, "-vf", filter, "-frames:v", "1", png])
  requireFile(png)
}

let rippleSvg = `
<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="1280" viewBox="0 0 1280 1280">
  <rect width="1280" height="1280" fill="#00ff00"/>
  <g fill="none" stroke-linecap="round">
    <path d="M30 134 Q112 18 198 76" stroke="#d3a54c" stroke-width="7"/>
    <path d="M56 145 Q122 48 190 90" stroke="#f0d580" stroke-width="3"/>
  </g>
</svg>`

let crackSvg = `
<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="1280" viewBox="0 0 1280 1280">
  <rect width="1280" height="1280" fill="#00ff00"/>
  <path d="M302 158 L313 184 L307 215 L316 248"
        fill="none" stroke="#41202f" stroke-width="6" stroke-linejoin="round"/>
  <path d="M302 158 L313 184 L307 215 L316 248"
        fill="none" stroke="#c8913b" stroke-width="1.5"/>
</svg>`

let gateDustSvg = `
<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="1280" viewBox="0 0 1280 1280">
  <rect width="1280" height="1280" fill="#00ff00"/>
  <g fill="#b88d61">
    <circle cx="326" cy="405" r="9"/><circle cx="353" cy="430" r="13"/>
    <circle cx="388" cy="443" r="8"/><circle cx="416" cy="452" r="11"/>
    <circle cx="301" cy="439" r="6"/><circle cx="452" cy="463" r="6"/>
  </g>
  <g fill="none" stroke="#caa374" stroke-width="3" stroke-linecap="round">
    <path d="M296 453 Q358 420 430 455"/><path d="M316 468 Q374 441 452 469"/>
  </g>
</svg>`

let bellSvg = `
<svg xmlns="http://www.w3.org/2000/svg" width="620" height="620" viewBox="0 0 620 620">
  <rect width="620" height="620" fill="#00ff00"/>
  <defs>
    <linearGradient id="bronze" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#f0c45c"/><stop offset=".42" stop-color="#b97924"/>
      <stop offset="1" stop-color="#64401d"/>
    </linearGradient>
  </defs>
  <g stroke="#53301d" stroke-linejoin="round">
    <path d="M260 310 L260 430" stroke="#8b6a42" stroke-width="14"/>
    <path d="M224 425 Q260 395 296 425 L310 454 L210 454 Z" fill="#95601f" stroke-width="8"/>
    <path d="M182 448 Q260 410 338 448 L374 548 Q260 592 146 548 Z" fill="url(#bronze)" stroke-width="10"/>
    <path d="M151 540 Q260 584 369 540" fill="none" stroke="#f5d473" stroke-width="12"/>
    <circle cx="260" cy="580" r="18" fill="#80511e" stroke-width="8"/>
  </g>
</svg>`

let chestBaseSvg = `
<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="1280" viewBox="0 0 1280 1280">
  <defs>
    <linearGradient id="wall" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#2d2552"/><stop offset="1" stop-color="#6f4b66"/>
    </linearGradient>
    <linearGradient id="wood" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#a96832"/><stop offset=".45" stop-color="#6b371f"/>
      <stop offset="1" stop-color="#3f211b"/>
    </linearGradient>
    <filter id="soft"><feDropShadow dx="0" dy="18" stdDeviation="18" flood-color="#130d1d" flood-opacity=".65"/></filter>
  </defs>
  <rect width="1280" height="720" fill="url(#wall)"/>
  <path d="M0 545 Q290 500 640 530 T1280 520 V720 H0 Z" fill="#32263d"/>
  <g opacity=".28" fill="#f8dba1"><circle cx="190" cy="180" r="5"/><circle cx="1040" cy="145" r="4"/><circle cx="1120" cy="260" r="6"/><circle cx="250" cy="330" r="3"/></g>
  <g filter="url(#soft)" stroke="#2e1818" stroke-width="12">
    <path d="M286 319 Q286 183 422 153 H858 Q994 183 994 319 Z" fill="url(#wood)"/>
    <path d="M255 315 H1025 V610 Q1025 650 985 650 H295 Q255 650 255 610 Z" fill="url(#wood)"/>
    <path d="M255 330 H1025" stroke="#d69a4f" stroke-width="18"/>
    <path d="M304 370 H976 M304 598 H976" stroke="#b47738" stroke-width="14" opacity=".75"/>
    <circle cx="640" cy="500" r="107" fill="#241a2d" stroke="#d9a848" stroke-width="22"/>
    <circle cx="640" cy="500" r="87" fill="#17121f" stroke="#684731" stroke-width="8"/>
  </g>
</svg>`

let ringSvg = `
<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="1280" viewBox="0 0 1280 1280">
  <rect width="1280" height="1280" fill="#00ff00"/>
  <circle cx="640" cy="500" r="57" fill="none" stroke="#f4c84b" stroke-width="24"/>
  <path d="M610 451 Q640 432 670 451" fill="none" stroke="#e9cf87" stroke-width="7" stroke-linecap="round"/>
</svg>`

let latchSvg = `
<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="1280" viewBox="0 0 1280 1280">
  <rect width="1280" height="1280" fill="#00ff00"/>
  <g stroke="#5b371a" stroke-width="8" stroke-linejoin="round">
    <rect x="600" y="290" width="80" height="118" rx="14" fill="#e2b54c"/>
    <rect x="615" y="335" width="50" height="62" rx="10" fill="#9a6a24"/>
    <circle cx="640" cy="363" r="11" fill="#39211a"/>
  </g>
</svg>`

let build = (~root): buildResult => {
  let source = root ++ "/start_frames/B02.png"
  let local = root ++ "/local/b02"
  let clips = root ++ "/clips"
  let qa = root ++ "/qa"
  let output = clips ++ "/B02.mp4"
  let contact = qa ++ "/B02_local_contact.png"
  let gateClip = local ++ "/gate.mp4"
  let bellClip = local ++ "/bell.mp4"
  let chestClip = local ++ "/chest.mp4"

  requireFile(source)
  B.ensureDirPath(B.Path(local))
  B.ensureDirPath(B.Path(clips))
  B.ensureDirPath(B.Path(qa))

  let svgAssets = [
    ("ripple", rippleSvg, 1280, 720, true),
    ("crack", crackSvg, 1280, 720, true),
    ("gate_dust", gateDustSvg, 1280, 720, true),
    ("bell", bellSvg, 520, 620, true),
    ("chest_base", chestBaseSvg, 1280, 720, false),
    ("ring", ringSvg, 1280, 720, true),
    ("latch", latchSvg, 1280, 720, true),
  ]
  svgAssets->Belt.Array.forEach(((name, body, assetWidth, assetHeight, transparent)) => {
    let svg = local ++ "/" ++ name ++ ".svg"
    let png = local ++ "/" ++ name ++ ".png"
    B.writeText(B.Path(svg), body)
    renderSvg(~svg, ~png, ~width=assetWidth, ~height=assetHeight, ~transparent)
  })

  B.ffmpeg([
    "-y", "-v", "error",
    "-loop", "1", "-framerate", Belt.Int.toString(fps), "-i", source,
    "-loop", "1", "-framerate", Belt.Int.toString(fps), "-i", local ++ "/ripple.png",
    "-loop", "1", "-framerate", Belt.Int.toString(fps), "-i", local ++ "/crack.png",
    "-loop", "1", "-framerate", Belt.Int.toString(fps), "-i", local ++ "/gate_dust.png",
    "-filter_complex",
    `[0:v]scale=1312:738,crop=1280:720:x='16+2*sin(0.7*t)':y='9+2*sin(0.5*t)'[base];[1:v]format=rgba,colorchannelmixer=aa=.78,fade=t=out:st=1.65:d=0.35:alpha=1[ripple];[2:v]format=rgba,fade=t=in:st=2:d=0.38:alpha=1[crack];[3:v]format=rgba,colorchannelmixer=aa=.46,fade=t=in:st=2.15:d=0.35:alpha=1,fade=t=out:st=3.45:d=0.45:alpha=1[dust];[base][ripple]overlay=x='-50+190*t':y='520-80*t':enable='between(t,0,2)'[g1];[g1][crack]overlay=0:0:enable='gte(t,2)'[g2];[g2][dust]overlay=0:0:enable='gte(t,2.1)',format=yuv420p[out]`,
    "-map", "[out]", "-frames:v", "96", "-r", Belt.Int.toString(fps), "-an",
    "-c:v", "libx264", "-preset", "slow", "-crf", "16", gateClip,
  ])

  B.ffmpeg([
    "-y", "-v", "error",
    "-loop", "1", "-framerate", Belt.Int.toString(fps), "-i", source,
    "-loop", "1", "-framerate", Belt.Int.toString(fps), "-i", local ++ "/bell.png",
    "-filter_complex",
    `[0:v]scale=1380:776,crop=1280:720:50:28,gblur=sigma=11,colorchannelmixer=rr=.56:gg=.48:bb=.68[bg];[1:v]format=rgba,rotate=angle='0.10*sin(PI*t)':ow=iw:oh=ih:fillcolor=none[bell];[bg][bell]overlay=380:-40,format=yuv420p[out]`,
    "-map", "[out]", "-frames:v", "48", "-r", Belt.Int.toString(fps), "-an",
    "-c:v", "libx264", "-preset", "slow", "-crf", "16", bellClip,
  ])

  B.ffmpeg([
    "-y", "-v", "error",
    "-loop", "1", "-framerate", Belt.Int.toString(fps), "-i", local ++ "/chest_base.png",
    "-loop", "1", "-framerate", Belt.Int.toString(fps), "-i", local ++ "/ring.png",
    "-loop", "1", "-framerate", Belt.Int.toString(fps), "-i", local ++ "/latch.png",
    "-filter_complex",
    `[0:v]scale=1280:720[base];[1:v]format=rgba[ring];[2:v]format=rgba[latch];[base][ring]overlay=x='2*sin(10*PI*t)':y='2*cos(10*PI*t)'[c1];[c1][latch]overlay=x='3*sin(12*PI*t)':y=0,format=yuv420p[out]`,
    "-map", "[out]", "-frames:v", "48", "-r", Belt.Int.toString(fps), "-an",
    "-c:v", "libx264", "-preset", "slow", "-crf", "16", chestClip,
  ])

  B.ffmpeg([
    "-y", "-v", "error", "-i", gateClip, "-i", bellClip, "-i", chestClip,
    "-filter_complex", "[0:v]setsar=1[g];[1:v]setsar=1[b];[2:v]setsar=1[c];[g][b][c]concat=n=3:v=1:a=0,format=yuv420p[out]",
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
  requireSuccess(~label="B02 ffprobe", probe)
  {output, contact, outputSha256: B.sha256File(B.Path(output)), probe: probe.stdout}
}
