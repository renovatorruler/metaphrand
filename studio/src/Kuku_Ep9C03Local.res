/* Deterministic, zero-credit C03 fallback.

   ReScript owns the full build. ffmpeg derives a soft silhouette mask, uses it
   to make both a clean plate and a Furia layer from the accepted C03 start
   frame, then performs one deliberately low hop. No provider, network client,
   credential, or model process is used. */

module B = Cinema_Backends

exception C03LocalError(string)

let fail = message => raise(C03LocalError(message))

let width = 1280
let height = 720
let durationSeconds = 8.0
let fps = 24
let layerX = 320
let layerY = 280
let maxHopPixels = 10.0

type buildResult = {
  output: string,
  mask: string,
  cleanPlate: string,
  layer: string,
  contact: string,
  probe: string,
}

let xOffset = _ => 0.0

let yOffset = t =>
  if t < 1.0 {
    0.0
  } else if t < 2.2 {
    -.3.0 *. Js.Math.abs_float(Js.Math.sin(Js.Math._PI *. (t -. 1.0) /. 0.4))
  } else if t < 3.5 {
    -.maxHopPixels *. Js.Math.sin(Js.Math._PI *. (t -. 2.2) /. 1.3)
  } else if t < 4.2 {
    -.3.0 *. Js.Math.sin(Js.Math._PI *. (t -. 3.5) /. 0.7) *.
    (1.0 -. (t -. 3.5) /. 0.7)
  } else {
    0.0
  }

let ellipse = (~cx, ~cy, ~rx, ~ry) =>
  `lte(pow((X-${Belt.Int.toString(cx)})/${Belt.Int.toString(rx)},2)+pow((Y-${Belt.Int.toString(cy)})/${Belt.Int.toString(ry)},2),1)`

let rotatedEllipse = (~cx, ~cy, ~rx, ~ry, ~angle) => {
  let x = `(X-${Belt.Int.toString(cx)})`
  let y = `(Y-${Belt.Int.toString(cy)})`
  let a = Js.Float.toString(angle)
  `lte(pow((${x}*cos(${a})+${y}*sin(${a}))/${Belt.Int.toString(rx)},2)+pow((-${x}*sin(${a})+${y}*cos(${a}))/${Belt.Int.toString(ry)},2),1)`
}

let maskParts = [
  ellipse(~cx=540, ~cy=385, ~rx=69, ~ry=62),
  ellipse(~cx=582, ~cy=414, ~rx=45, ~ry=29),
  rotatedEllipse(~cx=517, ~cy=465, ~rx=30, ~ry=79, ~angle=-0.08),
  rotatedEllipse(~cx=492, ~cy=520, ~rx=49, ~ry=82, ~angle=0.08),
  rotatedEllipse(~cx=430, ~cy=420, ~rx=67, ~ry=24, ~angle=-0.12),
  rotatedEllipse(~cx=448, ~cy=435, ~rx=53, ~ry=23, ~angle=0.38),
  rotatedEllipse(~cx=405, ~cy=505, ~rx=72, ~ry=22, ~angle=0.12),
  rotatedEllipse(~cx=358, ~cy=484, ~rx=46, ~ry=18, ~angle=0.33),
  ellipse(~cx=337, ~cy=465, ~rx=22, ~ry=15),
  rotatedEllipse(~cx=462, ~cy=493, ~rx=15, ~ry=37, ~angle=0.18),
  rotatedEllipse(~cx=552, ~cy=490, ~rx=34, ~ry=12, ~angle=0.42),
  ellipse(~cx=455, ~cy=554, ~rx=22, ~ry=49),
  ellipse(~cx=530, ~cy=552, ~rx=22, ~ry=47),
  ellipse(~cx=449, ~cy=600, ~rx=31, ~ry=13),
  ellipse(~cx=540, ~cy=592, ~rx=34, ~ry=13),
  ellipse(~cx=511, ~cy=322, ~rx=18, ~ry=29),
  ellipse(~cx=535, ~cy=311, ~rx=18, ~ry=28),
  ellipse(~cx=559, ~cy=328, ~rx=18, ~ry=29),
  ellipse(~cx=486, ~cy=345, ~rx=20, ~ry=27),
  ellipse(~cx=472, ~cy=370, ~rx=18, ~ry=25),
  ellipse(~cx=386, ~cy=474, ~rx=15, ~ry=20),
  ellipse(~cx=361, ~cy=456, ~rx=14, ~ry=19),
  ellipse(~cx=340, ~cy=442, ~rx=12, ~ry=16),
]

let geometryExpression = Js.Array2.joinWith(maskParts, "+")

let coreParts = [
  ellipse(~cx=545, ~cy=391, ~rx=49, ~ry=47),
  ellipse(~cx=582, ~cy=414, ~rx=34, ~ry=22),
  rotatedEllipse(~cx=516, ~cy=467, ~rx=21, ~ry=76, ~angle=-0.08),
  rotatedEllipse(~cx=494, ~cy=521, ~rx=30, ~ry=73, ~angle=0.08),
]

let coreExpression = Js.Array2.joinWith(coreParts, "+")

/* Saturated red/pink is unique to Furia in this bounded region. The compact
   neutral-colour core keeps her cream belly, eyes and teeth while excluding
   the green Kuku and blue Vesper pixels that overlap her silhouette in depth. */
let maskExpression =
  `if(gt((gt(${geometryExpression},0)*gt(r(X,Y),g(X,Y)*1.08)*gt(r(X,Y),b(X,Y)*1.02))+gt(${coreExpression},0),0),255,0)`

let requireSuccess = (~label, result: B.runResult) =>
  if result.code != 0 {
    fail(
      label ++ " failed (exit " ++ Belt.Int.toString(result.code) ++ "): " ++
      Js.String2.slice(result.stderr, ~from=0, ~to_=800),
    )
  }

let requireFile = path =>
  if !B.exists(B.Path(path)) {
    fail("expected local artifact is missing: " ++ path)
  }

let build = (~root): buildResult => {
  let source = root ++ "/start_frames/C03.png"
  let local = root ++ "/local"
  let qa = root ++ "/qa"
  let clips = root ++ "/clips"
  let mask = local ++ "/c03_furia_mask.png"
  let borderMask = local ++ "/c03_furia_border_mask.png"
  let cleanPlate = local ++ "/c03_clean_plate.png"
  let layer = local ++ "/c03_furia_rgba.png"
  let output = clips ++ "/C03.mp4"
  let contact = qa ++ "/C03_local_contact.png"

  requireFile(source)
  B.ensureDirPath(B.Path(local))
  B.ensureDirPath(B.Path(qa))
  B.ensureDirPath(B.Path(clips))

  let exposedDilationChain = Belt.Array.make(3, "dilation")->Js.Array2.joinWith(",")
  B.ffmpeg([
    "-y",
    "-v",
    "error",
    "-i",
    source,
    "-vf",
    `format=rgb24,geq=r='${maskExpression}':g='${maskExpression}':b='${maskExpression}',format=gray,boxblur=1:1`,
    "-frames:v",
    "1",
    mask,
  ])

  /* Furia only moves upward. Subtracting the mask shifted upward by the exact
     maximum hop leaves the narrow lower contour that can ever be exposed.
     Cleaning only that contour avoids both a duplicate/ghost Furia and the
     large inpainted hole produced by replacing the whole character. */
  B.ffmpeg([
    "-y",
    "-v",
    "error",
    "-i",
    mask,
    "-filter_complex",
    `[0:v]split[outer][move];[move]crop=${Belt.Int.toString(width)}:${Belt.Int.toString(height - Belt.Float.toInt(maxHopPixels))}:0:${Belt.Int.toString(Belt.Float.toInt(maxHopPixels))},pad=${Belt.Int.toString(width)}:${Belt.Int.toString(height)}:0:0:color=black[shifted];[outer][shifted]blend=all_mode=subtract,${exposedDilationChain},boxblur=1:1[out]`,
    "-map",
    "[out]",
    "-frames:v",
    "1",
    borderMask,
  ])

  B.ffmpeg([
    "-y",
    "-v",
    "error",
    "-i",
    source,
    "-vf",
    `removelogo=f=${borderMask}`,
    "-frames:v",
    "1",
    cleanPlate,
  ])

  B.ffmpeg([
    "-y",
    "-v",
    "error",
    "-i",
    source,
    "-i",
    mask,
    "-filter_complex",
    `[0:v]format=rgba[subject];[1:v]format=gray[alpha];[subject][alpha]alphamerge,crop=320:360:${Belt.Int.toString(layerX)}:${Belt.Int.toString(layerY)}[out]`,
    "-map",
    "[out]",
    "-frames:v",
    "1",
    layer,
  ])

  let overlayX = Belt.Int.toString(layerX)
  let overlayY =
    `${Belt.Int.toString(layerY)}+if(lt(t,1),0,if(lt(t,2.2),-3*abs(sin(PI*(t-1)/0.4)),if(lt(t,3.5),-${Js.Float.toString(maxHopPixels)}*sin(PI*(t-2.2)/1.3),if(lt(t,4.2),-3*sin(PI*(t-3.5)/0.7)*(1-(t-3.5)/0.7),0))))`

  B.ffmpeg([
    "-y",
    "-v",
    "error",
    "-loop",
    "1",
    "-framerate",
    Belt.Int.toString(fps),
    "-i",
    cleanPlate,
    "-loop",
    "1",
    "-framerate",
    Belt.Int.toString(fps),
    "-i",
    layer,
    "-filter_complex",
    `[0:v][1:v]overlay=x='${overlayX}':y='${overlayY}':eval=frame,format=yuv420p[out]`,
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
    "16",
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
    "fps=1,scale=320:180,tile=4x2",
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
  requireSuccess(~label="C03 ffprobe", probe)
  {output, mask, cleanPlate, layer, contact, probe: probe.stdout}
}
