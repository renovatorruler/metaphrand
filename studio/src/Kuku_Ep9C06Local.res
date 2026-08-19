/* Deterministic, zero-credit C06 overhead cooperation shot.

   The shot deliberately avoids faces and dialogue blocking. Five visibly
   different, unbraceleted dragon paws enter one blank ring at equal spacing;
   five differently patterned response waves then travel from those five
   contacts. The ring remains blank because the physical BA does not exist yet.
   No provider, network client, credential, or model process is available here. */

module B = Cinema_Backends
@module("node:path") external dirnamePath: string => string = "dirname"

exception C06LocalError(string)

let fail = message => raise(C06LocalError(message))

let width = 1280
let height = 720
let fps = 24
let durationSeconds = 10.0
let pawCount = 5
let waveCount = 5
let ringRadius = 190
let contactSeconds = 2.0
let firstWaveSeconds = 2.35

type buildResult = {
  output: string,
  contact: string,
  endFrame: string,
  endFrameSha256: string,
  outputSha256: string,
  probe: string,
}

let entryProgress = seconds =>
  seconds <= 0.0 ? 0.0 : seconds >= contactSeconds ? 1.0 : seconds /. contactSeconds

let waveIndexAt = seconds =>
  seconds < firstWaveSeconds
    ? 0
    : {
        let raw = 1 + Belt.Float.toInt((seconds -. firstWaveSeconds) /. 0.42)
        raw > 5 ? 5 : raw
      }

let requireFile = path =>
  if !B.exists(B.Path(path)) {
    fail("expected C06 local artifact is missing: " ++ path)
  }

let requireSuccess = (~label, result: B.runResult) =>
  if result.code != 0 {
    fail(
      label ++ " failed (exit " ++ Belt.Int.toString(result.code) ++ "): " ++
      Js.String2.slice(result.stderr, ~from=0, ~to_=1200),
    )
  }

let renderSvg = (~svg, ~png, ~transparent) => {
  let directory = dirnamePath(svg)
  let raw = svg ++ ".png"
  let preview = B.run(~cmd="qlmanage", ~args=["-t", "-s", "1280", "-o", directory, svg])
  requireSuccess(~label="C06 SVG raster", preview)
  requireFile(raw)
  let filter = transparent
    ? "crop=1280:720:0:0,colorkey=0x00FF00:0.42:0.03,format=rgba"
    : "crop=1280:720:0:0,format=rgba"
  B.ffmpeg(["-y", "-v", "error", "-i", raw, "-vf", filter, "-frames:v", "1", png])
  requireFile(png)
}

let backgroundSvg = `
<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="720" viewBox="0 0 1280 720">
  <defs>
    <linearGradient id="sand" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#dca46f"/><stop offset=".48" stop-color="#c8875e"/>
      <stop offset="1" stop-color="#9d6252"/>
    </linearGradient>
    <radialGradient id="light" cx="50%" cy="42%" r="67%">
      <stop offset="0" stop-color="#f9d39a" stop-opacity=".72"/>
      <stop offset="1" stop-color="#7a4960" stop-opacity=".18"/>
    </radialGradient>
    <filter id="grain"><feTurbulence type="fractalNoise" baseFrequency=".68" numOctaves="2" seed="19"/><feColorMatrix type="saturate" values="0"/><feComponentTransfer><feFuncA type="table" tableValues="0 .055"/></feComponentTransfer></filter>
  </defs>
  <rect width="1280" height="720" fill="url(#sand)"/>
  <g fill="none" stroke="#835054" stroke-width="5" opacity=".56">
    <path d="M-40 118 H330 L356 78 H760 L788 118 H1320"/>
    <path d="M-20 330 H262 L292 281 H616 L648 330 H1008 L1036 282 H1305"/>
    <path d="M-25 566 H358 L390 512 H806 L838 566 H1305"/>
    <path d="M154 -10 L114 118 L142 330 L96 566 L126 740"/>
    <path d="M1118 -10 L1157 118 L1125 330 L1170 566 L1140 740"/>
  </g>
  <g fill="none" stroke="#f1bf83" stroke-width="3" opacity=".42">
    <path d="M0 126 H330 M790 126 H1280 M0 574 H360 M840 574 H1280"/>
  </g>
  <rect width="1280" height="720" fill="url(#light)"/>
  <rect width="1280" height="720" filter="url(#grain)" opacity=".62"/>
</svg>`

let ringSvg = `
<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="720" viewBox="0 0 1280 720">
  <rect width="1280" height="720" fill="#00ff00"/>
  <defs>
    <linearGradient id="gold" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#fff0a1"/><stop offset=".38" stop-color="#d9a43a"/>
      <stop offset=".68" stop-color="#8f5a25"/><stop offset="1" stop-color="#f0c95e"/>
    </linearGradient>
  </defs>
  <circle cx="640" cy="360" r="190" fill="#6d3d42" fill-opacity=".13" stroke="#5c3842" stroke-width="35" opacity=".42"/>
  <circle cx="640" cy="360" r="190" fill="none" stroke="url(#gold)" stroke-width="25"/>
  <circle cx="640" cy="360" r="174" fill="none" stroke="#ffe49a" stroke-width="3" opacity=".82"/>
  <circle cx="640" cy="360" r="204" fill="none" stroke="#61363e" stroke-width="4" opacity=".46"/>
</svg>`

let pawSvg = (~angle, ~body, ~accent, ~pattern) => `
<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="720" viewBox="0 0 1280 720">
  <rect width="1280" height="720" fill="#00ff00"/>
  <g transform="rotate(${Belt.Int.toString(angle)} 640 360)">
    <g transform="translate(640 72)" stroke="#4d3344" stroke-width="7" stroke-linejoin="round">
      <path d="M-58 -118 Q-43 -159 -17 -170 H20 Q48 -153 58 -118 L48 51 Q43 77 18 88 H-19 Q-45 76 -50 49 Z" fill="${body}"/>
      <path d="M-48 37 Q-77 55 -70 84 Q-63 106 -38 95 L-13 74" fill="${body}"/>
      <path d="M48 37 Q77 55 70 84 Q63 106 38 95 L13 74" fill="${body}"/>
      <path d="M-22 70 Q-39 92 -27 111 Q-15 126 0 97 Q15 126 27 111 Q39 92 22 70" fill="${body}"/>
      <path d="M-69 84 Q-62 113 -37 97 M69 84 Q62 113 37 97 M-27 108 Q-15 132 0 98 M27 108 Q15 132 0 98" fill="none" stroke="#f5dfbb" stroke-width="8" stroke-linecap="round"/>
      <g fill="none" stroke="${accent}" stroke-width="6" stroke-linecap="round">${pattern}</g>
    </g>
  </g>
</svg>`

let waveSvg = (~angle, ~pattern) => `
<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="720" viewBox="0 0 1280 720">
  <rect width="1280" height="720" fill="#00ff00"/>
  <g transform="rotate(${Belt.Int.toString(angle)} 640 360)" fill="none" stroke="#ffe38a" stroke-width="8" stroke-linecap="round" stroke-linejoin="round">
    ${pattern}
  </g>
</svg>`

let build = (~root): buildResult => {
  let local = root ++ "/local/c06"
  let clips = root ++ "/clips"
  let qa = root ++ "/qa"
  let output = clips ++ "/C06.mp4"
  let contact = qa ++ "/C06_local_contact.png"
  let endFrame = local ++ "/C06_end_frame.png"

  B.ensureDirPath(B.Path(local))
  B.ensureDirPath(B.Path(clips))
  B.ensureDirPath(B.Path(qa))

  let svgAssets = [
    ("background", backgroundSvg, false),
    ("ring", ringSvg, true),
    ("paw_1", pawSvg(~angle=0, ~body="#78985a", ~accent="#395f45", ~pattern=`<path d="M-31 -93 L0 -73 L31 -93 M-31 -54 L0 -34 L31 -54"/>`), true),
    ("paw_2", pawSvg(~angle=72, ~body="#d55f6c", ~accent="#8f3a52", ~pattern=`<path d="M-29 -102 Q0 -82 29 -102 M-25 -60 Q0 -40 25 -60"/>`), true),
    ("paw_3", pawSvg(~angle=144, ~body="#79a8c8", ~accent="#456c99", ~pattern=`<circle cx="-22" cy="-88" r="7"/><circle cx="18" cy="-61" r="7"/><circle cx="-16" cy="-31" r="6"/>`), true),
    ("paw_4", pawSvg(~angle=216, ~body="#dda547", ~accent="#986228", ~pattern=`<path d="M0 -105 L19 -86 L0 -67 L-19 -86 Z M0 -52 L15 -37 L0 -22 L-15 -37 Z"/>`), true),
    ("paw_5", pawSvg(~angle=288, ~body="#b895ce", ~accent="#765795", ~pattern=`<path d="M-31 -91 Q-14 -108 2 -91 T34 -91 M-31 -48 Q-14 -65 2 -48 T34 -48"/>`), true),
    ("wave_1", waveSvg(~angle=0, ~pattern=`<path d="M595 228 Q640 263 685 228"/><path d="M608 256 Q640 280 672 256"/>`), true),
    ("wave_2", waveSvg(~angle=72, ~pattern=`<circle cx="610" cy="238" r="8"/><circle cx="640" cy="263" r="8"/><circle cx="670" cy="238" r="8"/>`), true),
    ("wave_3", waveSvg(~angle=144, ~pattern=`<path d="M595 236 L618 252 L640 232 L662 252 L685 236"/>`), true),
    ("wave_4", waveSvg(~angle=216, ~pattern=`<path d="M598 244 H617 M630 244 H650 M663 244 H682"/>`), true),
    ("wave_5", waveSvg(~angle=288, ~pattern=`<path d="M601 250 Q617 226 632 250 Q647 274 663 250 Q678 226 687 246"/>`), true),
  ]

  svgAssets->Belt.Array.forEach(((name, body, transparent)) => {
    let svg = local ++ "/" ++ name ++ ".svg"
    let png = local ++ "/" ++ name ++ ".png"
    B.writeText(B.Path(svg), body)
    renderSvg(~svg, ~png, ~transparent)
  })

  let inputArgs = Belt.Array.makeBy(12, index => [
    "-loop", "1", "-framerate", Belt.Int.toString(fps), "-i",
    local ++ "/" ++ (
      switch index {
      | 0 => "background"
      | 1 => "ring"
      | value if value >= 2 && value <= 6 => "paw_" ++ Belt.Int.toString(value - 1)
      | value => "wave_" ++ Belt.Int.toString(value - 6)
      }
    ) ++ ".png",
  ])->Belt.Array.concatMany

  let filter =
    `[0:v]scale=1280:720[base];[1:v]format=rgba[ring];` ++
    `[base][ring]overlay=0:0[s1];` ++
    `[2:v]format=rgba[p1];[3:v]format=rgba[p2];[4:v]format=rgba[p3];[5:v]format=rgba[p4];[6:v]format=rgba[p5];` ++
    `[s1][p1]overlay=x=0:y='-54*max(0,1-t/2)'[s2];` ++
    `[s2][p2]overlay=x='46*max(0,1-t/2)':y='-22*max(0,1-t/2)'[s3];` ++
    `[s3][p3]overlay=x='32*max(0,1-t/2)':y='40*max(0,1-t/2)'[s4];` ++
    `[s4][p4]overlay=x='-32*max(0,1-t/2)':y='40*max(0,1-t/2)'[s5];` ++
    `[s5][p5]overlay=x='-46*max(0,1-t/2)':y='-22*max(0,1-t/2)'[s6];` ++
    `[7:v]format=rgba,fade=t=in:st=2.35:d=.28:alpha=1,fade=t=out:st=8.8:d=.7:alpha=1[w1];` ++
    `[8:v]format=rgba,fade=t=in:st=2.77:d=.28:alpha=1,fade=t=out:st=8.8:d=.7:alpha=1[w2];` ++
    `[9:v]format=rgba,fade=t=in:st=3.19:d=.28:alpha=1,fade=t=out:st=8.8:d=.7:alpha=1[w3];` ++
    `[10:v]format=rgba,fade=t=in:st=3.61:d=.28:alpha=1,fade=t=out:st=8.8:d=.7:alpha=1[w4];` ++
    `[11:v]format=rgba,fade=t=in:st=4.03:d=.28:alpha=1,fade=t=out:st=8.8:d=.7:alpha=1[w5];` ++
    `[s6][w1]overlay=0:0[s7];[s7][w2]overlay=0:0[s8];[s8][w3]overlay=0:0[s9];` ++
    `[s9][w4]overlay=0:0[s10];[s10][w5]overlay=0:0,scale=1312:738,` ++
    `crop=1280:720:x='16+2*sin(t*.9)':y='9+2*sin(t*.7)',format=yuv420p[out]`

  B.ffmpeg(
    ["-y", "-v", "error"]
    ->Belt.Array.concat(inputArgs)
    ->Belt.Array.concat([
      "-filter_complex", filter, "-map", "[out]", "-frames:v", "240", "-r", "24", "-an",
      "-c:v", "libx264", "-preset", "slow", "-crf", "16", "-movflags", "+faststart", output,
    ]),
  )

  B.ffmpeg([
    "-y", "-v", "error", "-i", output,
    "-vf", "fps=1,scale=320:180,tile=5x2", "-frames:v", "1", contact,
  ])

  /* The waves have faded by the final frame, leaving the exact continuity
     state needed by C07: five paws, one intact blank ring, no early BA. */
  B.ffmpeg([
    "-y", "-v", "error", "-sseof", "-0.05", "-i", output,
    "-frames:v", "1", endFrame,
  ])
  requireFile(endFrame)

  let probe = B.run(
    ~cmd="ffprobe",
    ~args=[
      "-v", "error", "-show_entries",
      "stream=codec_type,codec_name,width,height,r_frame_rate,nb_frames:format=duration",
      "-of", "default=nw=1", output,
    ],
  )
  requireSuccess(~label="C06 ffprobe", probe)
  {
    output,
    contact,
    endFrame,
    endFrameSha256: B.sha256File(B.Path(endFrame)),
    outputSha256: B.sha256File(B.Path(output)),
    probe: probe.stdout,
  }
}
