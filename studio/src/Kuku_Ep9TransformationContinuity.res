/* Zero-credit approval animatic for the EP9 five-dragon transformation.

   This is deliberately a continuity board, not final footage. It uses only
   accepted local picture sources and code-authored semantic overlays. The six
   panels prove equal bracelets, sequential ignition with overlapping change,
   one shared finish beat, and a takeoff visibly caused after that finish.
   It never calls a provider and never writes a production manifest or EDL. */

module B = Cinema_Backends

exception TransformationContinuityError(string)

let fail = message => raise(TransformationContinuityError(message))

let width = 1280
let height = 720
let fps = 24
let durationSeconds = 18.0
let frameCount = 432
let panelCount = 6
let braceletCount = 5
let dragonCount = 5
let hasNativeAudio = false
let usesRejectedA05 = false
let usesRejectedD02Attempt1 = false
let sharedFinishSeconds = 10.5
let takeoffStartsSeconds = 13.5
let activationOrder = ["Kuku", "Furia", "Vesper", "Castor", "Leda"]
let panelDurations = [2.5, 3.0, 2.5, 2.5, 3.0, 4.5]

let panelAt = seconds =>
  if seconds < 2.5 {
    "FIVE EQUAL BRACELETS"
  } else if seconds < 5.5 {
    "ONE WAVE, FIVE STARTS"
  } else if seconds < 8.0 {
    "ALL FIVE CHANGING"
  } else if seconds < 10.5 {
    "NO ONE FINISHES EARLY"
  } else if seconds < 13.5 {
    "ONE SHARED FINISH PULSE"
  } else {
    "PULSE TO WINGS TO TAKEOFF"
  }

let activationDelay = index => 0.20 +. Belt.Int.toFloat(index) *. 0.30

let growthProgressAt = (~dragonIndex, ~seconds) => {
  if seconds < 2.5 +. activationDelay(dragonIndex) {
    0.0
  } else if seconds < 5.5 {
    Js.Math.min_float(0.20, (seconds -. 2.5 -. activationDelay(dragonIndex)) *. 0.10)
  } else if seconds < 8.0 {
    0.35
  } else if seconds < sharedFinishSeconds {
    0.80
  } else {
    1.0
  }
}

type buildResult = {
  video: string,
  board: string,
  contact: string,
  videoSha256: string,
  boardSha256: string,
  contactSha256: string,
  probe: string,
}

@module("path") external dirnamePath: string => string = "dirname"

let requireFile = path =>
  if !B.exists(B.Path(path)) {
    fail("expected accepted continuity source is missing: " ++ path)
  }

let requireSuccess = (~label, result: B.runResult) =>
  if result.code != 0 {
    fail(
      label ++ " failed (exit " ++ Belt.Int.toString(result.code) ++ "): " ++
      Js.String2.slice(result.stderr, ~from=0, ~to_=1800),
    )
  }

let renderSvg = (~svg, ~png) => {
  let directory = dirnamePath(svg)
  let raw = svg ++ ".png"
  let preview = B.run(
    ~cmd="qlmanage",
    ~args=["-t", "-s", "1280", "-o", directory, svg],
  )
  requireSuccess(~label="continuity SVG raster", preview)
  requireFile(raw)
  B.ffmpeg([
    "-y", "-v", "error", "-i", raw,
    "-vf", "crop=1280:720:0:0,colorkey=0x00FF00:0.42:0.04,format=rgba",
    "-frames:v", "1", png,
  ])
  requireFile(png)
}

let names = `
  <g font-family="Arial, Helvetica, sans-serif" font-size="18" font-weight="700"
     fill="#fff5cc" text-anchor="middle">
    <text x="347" y="648">KUKU</text><text x="595" y="648">FURIA</text>
    <text x="824" y="648">VESPER</text><text x="1041" y="648">CASTOR</text>
    <text x="1207" y="648">LEDA</text>
  </g>`

let svgFrame = (~number, ~title, ~subtitle, ~body) => `
<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="1280" viewBox="0 0 1280 1280">
  <rect width="1280" height="1280" fill="#00ff00"/>
  <rect x="0" y="0" width="1280" height="110" fill="#17152d" opacity="0.94"/>
  <rect x="0" y="610" width="1280" height="110" fill="#17152d" opacity="0.94"/>
  <text x="32" y="31" font-family="Arial, Helvetica, sans-serif" font-size="20"
        font-weight="700" fill="#f5c95b">STORYBOARD / ZERO-CREDIT CONTINUITY ANIMATIC / NOT FINAL FOOTAGE</text>
  <text x="32" y="82" font-family="Arial, Helvetica, sans-serif" font-size="40"
        font-weight="800" fill="white">${number}  ${title}</text>
  <text x="640" y="691" text-anchor="middle" font-family="Arial, Helvetica, sans-serif"
        font-size="27" font-weight="700" fill="white">${subtitle}</text>
  ${body}
</svg>`

let p1Body = `
  <g fill="none" stroke="#ffd466" stroke-width="7">
    <circle cx="347" cy="519" r="30"/><circle cx="595" cy="519" r="30"/>
    <circle cx="824" cy="519" r="30"/><circle cx="1041" cy="500" r="30"/>
    <circle cx="1207" cy="492" r="30"/>
  </g>
  <g fill="#17152d" stroke="#ffd466" stroke-width="3">
    <rect x="292" y="558" width="110" height="36" rx="18"/><rect x="540" y="558" width="110" height="36" rx="18"/>
    <rect x="769" y="558" width="110" height="36" rx="18"/><rect x="986" y="539" width="110" height="36" rx="18"/>
    <rect x="1152" y="531" width="110" height="36" rx="18"/>
  </g>
  <g font-family="Arial, Helvetica, sans-serif" font-size="18" font-weight="800" fill="#fff5cc" text-anchor="middle">
    <text x="347" y="582">EQUAL</text><text x="595" y="582">EQUAL</text><text x="824" y="582">EQUAL</text>
    <text x="1041" y="563">EQUAL</text><text x="1207" y="555">EQUAL</text>
  </g>`

let p2Body = `
  <path d="M347 455 C485 410 555 505 595 455 S760 410 824 455 S970 505 1041 455 S1145 410 1207 455"
        fill="none" stroke="#ffd466" stroke-width="9" stroke-linecap="round"/>
  <path d="M1190 434 L1230 455 L1190 476" fill="none" stroke="#ffd466" stroke-width="9"/>
  <g fill="#17152d" stroke="#ffd466" stroke-width="4">
    <circle cx="347" cy="455" r="25"/><circle cx="595" cy="455" r="25"/>
    <circle cx="824" cy="455" r="25"/><circle cx="1041" cy="455" r="25"/><circle cx="1207" cy="455" r="25"/>
  </g>
  <g font-family="Arial, Helvetica, sans-serif" font-size="22" font-weight="800" fill="white" text-anchor="middle">
    <text x="347" y="463">1</text><text x="595" y="463">2</text><text x="824" y="463">3</text>
    <text x="1041" y="463">4</text><text x="1207" y="463">5</text>
  </g>
  ${names}`

let progressBody = percent => {
  let filled = percent == 35 ? 49 : 112
  let y = percent == 35 ? 430 : 385
  `
  <g fill="#ffd466" opacity="0.16" stroke="#ffd466" stroke-width="5">
    <ellipse cx="347" cy="430" rx="130" ry="190"/><ellipse cx="595" cy="430" rx="130" ry="190"/>
    <ellipse cx="824" cy="430" rx="120" ry="185"/><ellipse cx="1041" cy="430" rx="115" ry="175"/>
    <ellipse cx="1207" cy="430" rx="92" ry="165"/>
  </g>
  <g fill="#17152d" stroke="#fff5cc" stroke-width="3">
    <rect x="277" y="550" width="140" height="24" rx="12"/><rect x="525" y="550" width="140" height="24" rx="12"/>
    <rect x="754" y="550" width="140" height="24" rx="12"/><rect x="971" y="550" width="140" height="24" rx="12"/>
    <rect x="1137" y="550" width="140" height="24" rx="12"/>
  </g>
  <g fill="#ffd466">
    <rect x="277" y="550" width="${Belt.Int.toString(filled)}" height="24" rx="12"/>
    <rect x="525" y="550" width="${Belt.Int.toString(filled)}" height="24" rx="12"/>
    <rect x="754" y="550" width="${Belt.Int.toString(filled)}" height="24" rx="12"/>
    <rect x="971" y="550" width="${Belt.Int.toString(filled)}" height="24" rx="12"/>
    <rect x="1137" y="550" width="${Belt.Int.toString(filled)}" height="24" rx="12"/>
  </g>
  <text x="640" y="${Belt.Int.toString(y)}" text-anchor="middle" font-family="Arial, Helvetica, sans-serif"
        font-size="42" font-weight="800" fill="#fff5cc">ALL FIVE: ${Belt.Int.toString(percent)}%</text>
  ${names}`
}

let p5Body = `
  <ellipse cx="640" cy="422" rx="602" ry="240" fill="#ffd466" opacity="0.10"
           stroke="#fff0a8" stroke-width="15"/>
  <ellipse cx="640" cy="422" rx="570" ry="208" fill="none" stroke="#ffd466"
           stroke-width="8" stroke-dasharray="18 13"/>
  <path d="M145 585 L145 395 M365 585 L365 350 M610 585 L610 415 M835 585 L835 345 M1085 585 L1085 410"
        fill="none" stroke="#fff0a8" stroke-width="6" stroke-linecap="round" opacity="0.78"/>
  <g font-family="Arial, Helvetica, sans-serif" font-size="19" font-weight="800" fill="#fff5cc" text-anchor="middle">
    <text x="145" y="586">KUKU</text><text x="365" y="586">FURIA</text><text x="610" y="586">VESPER</text>
    <text x="835" y="586">CASTOR</text><text x="1085" y="586">LEDA</text>
  </g>`

let p6Body = `
  <rect x="620" y="110" width="40" height="500" fill="#17152d" opacity="0.94"/>
  <path d="M570 360 L710 360" stroke="#ffd466" stroke-width="13" stroke-linecap="round"/>
  <path d="M690 332 L730 360 L690 388" fill="none" stroke="#ffd466" stroke-width="13"/>
  <g font-family="Arial, Helvetica, sans-serif" font-size="24" font-weight="800" fill="#fff5cc" text-anchor="middle">
    <text x="320" y="145">SHARED PULSE AT FIVE FEET</text>
    <text x="960" y="145">THEN ALL FIVE AIRBORNE</text>
  </g>
  <g fill="none" stroke="#ffd466" stroke-width="8" opacity="0.9">
    <ellipse cx="90" cy="530" rx="48" ry="13"/><ellipse cx="210" cy="530" rx="48" ry="13"/>
    <ellipse cx="330" cy="530" rx="48" ry="13"/><ellipse cx="450" cy="530" rx="48" ry="13"/>
    <ellipse cx="570" cy="530" rx="48" ry="13"/>
  </g>`

let build = (~root): buildResult => {
  let local = root ++ "/local/transformation_continuity"
  let review = root ++ "/review"
  let qa = root ++ "/qa"
  let child = root ++ "/start_frames/D02.png"
  let valley = root ++ "/references/upload_proxies/valley.jpg"
  let flight = root ++ "/references/A06.png"
  let instances = root ++ "/local/b14_b15/instances"
  let kuku = instances ++ "/kuku_1.png"
  let furia = instances ++ "/furia_1.png"
  let vesper = instances ++ "/vesper_2.png"
  let castor = instances ++ "/castor_1.png"
  let leda = instances ++ "/leda_1.png"
  [child, valley, flight, kuku, furia, vesper, castor, leda]->Belt.Array.forEach(requireFile)
  B.ensureDirPath(B.Path(local))
  B.ensureDirPath(B.Path(review))
  B.ensureDirPath(B.Path(qa))

  let overlays = [
    svgFrame(~number="1", ~title="FIVE EQUAL BRACELETS", ~subtitle="Same bracelet. Same authority. Same possible future.", ~body=p1Body),
    svgFrame(~number="2", ~title="ONE WAVE, FIVE STARTS", ~subtitle="Ignition travels in order. No child finishes during the wave.", ~body=p2Body),
    svgFrame(~number="3", ~title="ALL FIVE CHANGING", ~subtitle="Every child is already changing. Growth overlaps.", ~body=progressBody(35)),
    svgFrame(~number="4", ~title="NO ONE FINISHES EARLY", ~subtitle="Same progress. Same power. Nobody is giant yet.", ~body=progressBody(80)),
    svgFrame(~number="5", ~title="ONE SHARED FINISH PULSE", ~subtitle="One pulse completes all five transformations together.", ~body=p5Body),
    svgFrame(~number="6", ~title="PULSE -&gt; WINGS -&gt; TAKEOFF", ~subtitle="The shared finish causes one team takeoff beat.", ~body=p6Body),
  ]
  overlays->Belt.Array.forEachWithIndex((index, body) => {
    let number = Belt.Int.toString(index + 1)
    let svg = local ++ "/overlay_" ++ number ++ ".svg"
    let png = local ++ "/overlay_" ++ number ++ ".png"
    B.writeText(B.Path(svg), body)
    renderSvg(~svg, ~png)
  })

  /* Panels 1-4 retain the accepted C02-derived five-child plate. */
  for index in 1 to 4 {
    B.ffmpeg([
      "-y", "-v", "error", "-i", child, "-i", local ++ "/overlay_" ++ Belt.Int.toString(index) ++ ".png",
      "-filter_complex", "[0:v]scale=1280:720[base];[1:v]format=rgba[o];[base][o]overlay=0:0,format=yuv420p[out]",
      "-map", "[out]", "-frames:v", "1", local ++ "/panel_" ++ Belt.Int.toString(index) ++ ".png",
    ])
  }

  /* A09-derived accepted cutouts are equalized on the accepted valley plate in
     fixed Kuku-Furia-Vesper-Castor-Leda order. Vesper's A09 lower body is
     occluded in source; the storyboard ground band honestly hides that crop. */
  let giantStage = local ++ "/giant_stage.png"
  B.ffmpeg([
    "-y", "-v", "error", "-i", valley, "-i", kuku, "-i", furia, "-i", vesper, "-i", castor, "-i", leda,
    "-filter_complex",
    "[0:v]scale=1280:720:force_original_aspect_ratio=increase,crop=1280:720[base];" ++
    "[1:v]scale=240:175:flags=lanczos,format=rgba[k];[2:v]scale=220:215:flags=lanczos,format=rgba[f];" ++
    "[3:v]scale=220:160:flags=lanczos,format=rgba[v];[4:v]scale=225:220:flags=lanczos,format=rgba[c];" ++
    "[5:v]scale=240:160:flags=lanczos,format=rgba[l];" ++
    "[base][k]overlay=25:395[x1];[x1][f]overlay=255:355[x2];[x2][v]overlay=505:420[x3];" ++
    "[x3][c]overlay=735:350[x4];[x4][l]overlay=985:415," ++
    "drawbox=x=0:y=565:w=1280:h=55:color=0x17152d@0.74:t=fill,format=yuv420p[out]",
    "-map", "[out]", "-frames:v", "1", giantStage,
  ])
  B.ffmpeg([
    "-y", "-v", "error", "-i", giantStage, "-i", local ++ "/overlay_5.png",
    "-filter_complex", "[1:v]format=rgba[o];[0:v][o]overlay=0:0,format=yuv420p[out]",
    "-map", "[out]", "-frames:v", "1", local ++ "/panel_5.png",
  ])

  /* Panel 6 is a causal two-key board: the same grounded five on the left,
     accepted A06 five-dragon flight on the right, with one explicit arrow. */
  B.ffmpeg([
    "-y", "-v", "error", "-i", giantStage, "-i", flight, "-i", local ++ "/overlay_6.png",
    "-filter_complex",
    "[0:v]scale=640:360,pad=640:720:0:180:color=0x17152d[left];" ++
    "[1:v]scale=640:360,pad=640:720:0:180:color=0x17152d[right];" ++
    "[left][right]hstack=inputs=2[split];[2:v]format=rgba[o];[split][o]overlay=0:0,format=yuv420p[out]",
    "-map", "[out]", "-frames:v", "1", local ++ "/panel_6.png",
  ])

  let board = review ++ "/EP9_TRANSFORMATION_CONTINUITY_BOARD_V1.png"
  B.ffmpeg([
    "-y", "-v", "error",
    "-i", local ++ "/panel_1.png", "-i", local ++ "/panel_2.png", "-i", local ++ "/panel_3.png",
    "-i", local ++ "/panel_4.png", "-i", local ++ "/panel_5.png", "-i", local ++ "/panel_6.png",
    "-filter_complex",
    "[0:v]scale=640:360[p1];[1:v]scale=640:360[p2];[2:v]scale=640:360[p3];" ++
    "[3:v]scale=640:360[p4];[4:v]scale=640:360[p5];[5:v]scale=640:360[p6];" ++
    "[p1][p2][p3]hstack=inputs=3[top];[p4][p5][p6]hstack=inputs=3[bottom];[top][bottom]vstack=inputs=2[out]",
    "-map", "[out]", "-frames:v", "1", board,
  ])

  let video = review ++ "/EP9_TRANSFORMATION_CONTINUITY_ANIMATIC_V1.mp4"
  B.ffmpeg([
    "-y", "-v", "error",
    "-loop", "1", "-framerate", "24", "-t", "2.5", "-i", local ++ "/panel_1.png",
    "-loop", "1", "-framerate", "24", "-t", "3.0", "-i", local ++ "/panel_2.png",
    "-loop", "1", "-framerate", "24", "-t", "2.5", "-i", local ++ "/panel_3.png",
    "-loop", "1", "-framerate", "24", "-t", "2.5", "-i", local ++ "/panel_4.png",
    "-loop", "1", "-framerate", "24", "-t", "3.0", "-i", local ++ "/panel_5.png",
    "-loop", "1", "-framerate", "24", "-t", "4.5", "-i", local ++ "/panel_6.png",
    "-filter_complex", "[0:v][1:v][2:v][3:v][4:v][5:v]concat=n=6:v=1:a=0,format=yuv420p[out]",
    "-map", "[out]", "-frames:v", Belt.Int.toString(frameCount), "-r", "24", "-an",
    "-c:v", "libx264", "-preset", "slow", "-crf", "16", "-movflags", "+faststart", video,
  ])

  let contact = qa ++ "/EP9_TRANSFORMATION_CONTINUITY_ANIMATIC_CONTACT_V1.png"
  B.ffmpeg([
    "-y", "-v", "error", "-i", video,
    "-vf", "select='eq(n,30)+eq(n,96)+eq(n,162)+eq(n,222)+eq(n,288)+eq(n,378)',scale=640:360,tile=3x2",
    "-vsync", "0", "-frames:v", "1", contact,
  ])

  let probe = B.run(
    ~cmd="ffprobe",
    ~args=[
      "-v", "error", "-show_entries",
      "stream=codec_type,codec_name,width,height,r_frame_rate,nb_frames:format=duration",
      "-of", "default=nw=1", video,
    ],
  )
  requireSuccess(~label="continuity animatic ffprobe", probe)
  {
    video,
    board,
    contact,
    videoSha256: B.sha256File(B.Path(video)),
    boardSha256: B.sha256File(B.Path(board)),
    contactSha256: B.sha256File(B.Path(contact)),
    probe: probe.stdout,
  }
}
