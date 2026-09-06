/* Puppet.res — jointed paper puppets, animated by code, drawn on a canvas.

   A character is generated ONCE as a spread-pose sprite on a flat keyable
   sheet, cut into parts along polygons, and from then on every motion is a
   number: which part rotates about which pivot, by how much, when. Nothing is
   re-imagined between shots, so nothing can drift; continuity is a value
   carried from one shot to the next.

   The type discipline the author asked for: no built-in reaches a drawing
   call bare. A pixel is a Px, an angle a Deg, a time a Sec, a scale a Scale;
   a part is addressed by PartName; a file by ImagePath. A part image cannot
   be handed where a stage image is expected, and a pivot in sprite space
   cannot be confused with a stage position.

   Rendering: frames are drawn with @napi-rs/canvas, written as PNGs to a
   temporary directory outside the repository, and encoded once through
   Cinema_Backends.ffmpeg. */

/* ---------------------------------------------------------------- newtypes */
@unboxed type px = Px(float) /* a pixel measure, in whichever space its owner says */
@unboxed type deg = Deg(float) /* degrees, clockwise positive on screen */
@unboxed type sec = Sec(float)
@unboxed type scale = Scale(float)
@unboxed type alpha = Alpha(float)
@unboxed type partName = PartName(string)
@unboxed type imagePath = ImagePath(string)
@unboxed type fps = Fps(int)

let pxf = (Px(v)) => v
let secf = (Sec(v)) => v
let degf = (Deg(v)) => v
let scalef = (Scale(v)) => v
let rad = (Deg(d)) => d *. Js.Math._PI /. 180.0

/* ---------------------------------------------------------- canvas binding */
type canvas
type ctx
type image
type buffer

@module("@napi-rs/canvas") external createCanvas: (int, int) => canvas = "createCanvas"
@module("@napi-rs/canvas") external loadImageRaw: string => promise<image> = "loadImage"
@get external imageWidth: image => float = "width"
@get external imageHeight: image => float = "height"
@send external getContext: (canvas, string) => ctx = "getContext"
@send external toBuffer: (canvas, string) => buffer = "toBuffer"
@send external save: ctx => unit = "save"
@send external restore: ctx => unit = "restore"
@send external translate: (ctx, float, float) => unit = "translate"
@send external rotate: (ctx, float) => unit = "rotate"
@send external scaleCtx: (ctx, float, float) => unit = "scale"
@send external drawImage: (ctx, image, float, float) => unit = "drawImage"
@send external drawImageSized: (ctx, image, float, float, float, float) => unit = "drawImage"
@send external drawCanvas: (ctx, canvas, float, float) => unit = "drawImage"
@set external setGlobalAlpha: (ctx, float) => unit = "globalAlpha"
@set external setFillStyle: (ctx, string) => unit = "fillStyle"
@set external setSmoothing: (ctx, bool) => unit = "imageSmoothingEnabled"
@send external fillRect: (ctx, float, float, float, float) => unit = "fillRect"
@send external clearRect: (ctx, float, float, float, float) => unit = "clearRect"
@send external beginPath: ctx => unit = "beginPath"
@send external moveTo: (ctx, float, float) => unit = "moveTo"
@send external lineTo: (ctx, float, float) => unit = "lineTo"
@send external closePath: ctx => unit = "closePath"
@send external clip: ctx => unit = "clip"
@send external fill: ctx => unit = "fill"
@send external ellipse: (ctx, float, float, float, float, float, float, float) => unit = "ellipse"
@set external setStrokeStyle: (ctx, string) => unit = "strokeStyle"
@set external setLineWidth: (ctx, float) => unit = "lineWidth"
@set external setLineCap: (ctx, string) => unit = "lineCap"
@send external stroke: ctx => unit = "stroke"
@set external setCompositeOp: (ctx, string) => unit = "globalCompositeOperation"
type gradient
@send external createRadialGradient: (ctx, float, float, float, float, float, float) => gradient = "createRadialGradient"
@send external addColorStop: (gradient, float, string) => unit = "addColorStop"
@set external setFillGradient: (ctx, gradient) => unit = "fillStyle"

@module("fs") external readFileBuffer: string => buffer = "readFileSync"
@module("fs") external writeFileBuffer: (string, buffer) => unit = "writeFileSync"
@module("fs") external writeFileSync: (string, string) => unit = "writeFileSync"
@module("fs") external readFileSync: (string, string) => string = "readFileSync"
@module("fs") external mkdirSync: (string, {"recursive": bool}) => unit = "mkdirSync"
@module("fs") external mkdtempSync: string => string = "mkdtempSync"
@module("fs") external rmSync: (string, {"recursive": bool, "force": bool}) => unit = "rmSync"
@module("fs") external existsSync: string => bool = "existsSync"
@module("os") external tmpdir: unit => string = "tmpdir"
@module("path") external join: (string, string) => string = "join"

/* decoding is asynchronous in this library, so every loader is awaited once
   while a shot is being set up; drawing itself is synchronous */
let loadImage = (ImagePath(p)) => loadImageRaw(p)

/* ------------------------------------------------------------------- rigs */
/* A part is a region of the spread-pose sprite. Its outline is a polygon in
   SPRITE coordinates; so is its pivot. Parts form a tree: a child's rotation
   is applied inside its parent's, so a forearm follows the upper arm. z orders
   drawing within the puppet, higher in front. */
type spritePoint = (px, px)
/* A JOINT CAP: a disc in the part's own colour, with a darker paper edge,
   drawn over its pivot in the parent's space, so the straight cut end of a
   hinged piece never shows when it swings — the round paper joint a real
   cutout puppet has. */
type cap = {radius: px, colour: string, edge: string}
type partSpec = {
  name: partName,
  parent: option<partName>,
  pivot: spritePoint,
  outline: array<spritePoint>,
  z: int,
  cap?: cap,
}
/* THE FORM IS A TYPE. Only the great forms fly, after the कड़ा; a small-form
   puppet handed to a flight is a compile error, never a story mistake found
   in a render. The parameter is phantom: nothing at runtime, everything at
   the boundary where a shot is authored. */
type small
type great
/* A PATCH: an alternative picture of a small region — a mouth shape — drawn in
   its parent part's space at a sprite-space box, shown when the state names
   it. The sprite's own mouth shows when no patch is named. */
type patchSpec = {patch: string, image: imagePath, parent: partName, at: spritePoint}
type rigSpec<'form> = {
  sprite: imagePath,
  parts: array<partSpec>,
  patches: array<patchSpec>,
  feet: spritePoint, /* the ground contact point, in sprite space */
  partsDir: string,
}

/* How one part is posed at one instant: an angle about its pivot, a nudge, a
   scale about the same pivot. Rest is the sprite as generated. */
type partPose = {angle: deg, dx: px, dy: px, s: scale}
let rest = {angle: Deg(0.0), dx: Px(0.0), dy: Px(0.0), s: Scale(1.0)}
let turn = a => {...rest, angle: Deg(a)}

/* The puppet on the stage: where its sprite origin sits, how big (depth),
   which way it faces, how it banks, and every part's pose. */
type puppetState = {
  x: px,
  y: px,
  size: scale,
  facingLeft: bool, /* the sprite as generated faces left; false mirrors it */
  bank: deg,
  parts: Js.Dict.t<partPose>,
  opacity: alpha,
  mouth: option<string>, /* the patch showing, if any */
}

let poseOf = (st, PartName(n)) =>
  switch Js.Dict.get(st.parts, n) {
  | Some(p) => p
  | None => rest
  }

/* A cut part, ready to draw: its image and where its box sits in sprite space. */
type part = {spec: partSpec, img: image, ox: float, oy: float}
type rig<'form> = {
  spec: rigSpec<'form>,
  parts: array<part>,
  patches: array<(patchSpec, image)>,
  spriteW: float,
  spriteH: float,
}

/* a puppet standing on the ground at a stage point, every part at rest */
let stand = (_spec: rigSpec<'form>, ~feetX, ~feetY, ~size, ~facingLeft=true, ()) => {
  {
    x: Px(feetX),
    y: Px(feetY),
    size: Scale(size),
    facingLeft,
    bank: Deg(0.0),
    parts: Js.Dict.empty(),
    opacity: Alpha(1.0),
    mouth: None,
  }
}

let partFile = (dir, PartName(n)) => join(dir, n ++ ".png")
let partMeta = (dir, PartName(n)) => join(dir, n ++ ".box.json")

/* CUT: every part image is the sprite clipped by its polygon, saved once with
   the box it came from. Rerunning is free and deterministic. */
let cut = async (r: rigSpec<'form>) => {
  mkdirSync(r.partsDir, {"recursive": true})
  let sprite = await loadImage(r.sprite)
  let w = imageWidth(sprite)
  let h = imageHeight(sprite)
  Js.Array2.forEach(r.parts, p => {
    let xs = Js.Array2.map(p.outline, ((Px(x), _)) => x)
    let ys = Js.Array2.map(p.outline, ((_, Px(y))) => y)
    let minOf = a => Js.Array2.reduce(a, (m, v) => v < m ? v : m, infinity)
    let maxOf = a => Js.Array2.reduce(a, (m, v) => v > m ? v : m, -.infinity)
    let bx = Js.Math.floor_float(minOf(xs))
    let by = Js.Math.floor_float(minOf(ys))
    let bw = Js.Math.ceil_float(maxOf(xs)) -. bx
    let bh = Js.Math.ceil_float(maxOf(ys)) -. by
    let full = createCanvas(Belt.Float.toInt(w), Belt.Float.toInt(h))
    let c = getContext(full, "2d")
    save(c)
    beginPath(c)
    Js.Array2.forEachi(p.outline, ((Px(x), Px(y)), i) => i == 0 ? moveTo(c, x, y) : lineTo(c, x, y))
    closePath(c)
    clip(c)
    drawImage(c, sprite, 0.0, 0.0)
    restore(c)
    let box = createCanvas(Belt.Float.toInt(bw), Belt.Float.toInt(bh))
    drawCanvas(getContext(box, "2d"), full, -.bx, -.by)
    writeFileBuffer(partFile(r.partsDir, p.name), toBuffer(box, "image/png"))
    writeFileSync(
      partMeta(r.partsDir, p.name),
      Js.Json.stringify(
        Js.Json.object_(
          Js.Dict.fromArray([("x", Js.Json.number(bx)), ("y", Js.Json.number(by))]),
        ),
      ),
    )
    let PartName(n) = p.name
    Js.log("cut " ++ n ++ " " ++ Js.Float.toString(bw) ++ "x" ++ Js.Float.toString(bh))
  })
}

let loadRig = async (r: rigSpec<'form>): rig<'form> => {
  let sprite = await loadImage(r.sprite)
  let parts: array<part> = []
  for i in 0 to Js.Array2.length(r.parts) - 1 {
    let p = r.parts[i]
    let meta = Js.Json.parseExn(readFileSync(partMeta(r.partsDir, p.name), "utf8"))
    let num = k =>
      meta
      ->Js.Json.decodeObject
      ->Belt.Option.flatMap(o => Js.Dict.get(o, k))
      ->Belt.Option.flatMap(Js.Json.decodeNumber)
      ->Belt.Option.getWithDefault(0.0)
    let img = await loadImage(ImagePath(partFile(r.partsDir, p.name)))
    ignore(Js.Array2.push(parts, {spec: p, img, ox: num("x"), oy: num("y")}))
  }
  let patches: array<(patchSpec, image)> = []
  for i in 0 to Js.Array2.length(r.patches) - 1 {
    let ps = r.patches[i]
    let img = await loadImage(ps.image)
    ignore(Js.Array2.push(patches, (ps, img)))
  }
  {spec: r, parts, patches, spriteW: imageWidth(sprite), spriteH: imageHeight(sprite)}
}

/* the chain of ancestors, root first, so nested rotations compose in order */
let rec lineage = (rg: rig<'form>, name: partName): array<part> =>
  switch Js.Array2.find(rg.parts, p => p.spec.name == name) {
  | None => []
  | Some(p) =>
    switch p.spec.parent {
    | None => [p]
    | Some(par) => Js.Array2.concat(lineage(rg, par), [p])
    }
  }

let applyPose = (c, st, p: part) => {
  let {angle, dx, dy, s} = poseOf(st, p.spec.name)
  let (Px(pxv), Px(pyv)) = p.spec.pivot
  translate(c, pxv +. pxf(dx), pyv +. pxf(dy))
  rotate(c, rad(angle))
  scaleCtx(c, scalef(s), scalef(s))
  translate(c, -.pxv, -.pyv)
}

/* DRAW the puppet: stage transform, then for each part (by z) the transforms
   of its whole lineage, then the part image at its sprite-space box. */
let drawPuppet = (c, rg: rig<'form>, st: puppetState) => {
  save(c)
  setGlobalAlpha(c, switch st.opacity { | Alpha(a) => a })
  /* the state's x, y is where the FEET stand on the stage; the puppet banks
     about that point and mirrors about it, so a mirrored puppet stands exactly
     where an unmirrored one would */
  let (Px(fx), Px(fy)) = rg.spec.feet
  translate(c, pxf(st.x), pxf(st.y))
  rotate(c, rad(st.bank))
  scaleCtx(c, scalef(st.size) *. (st.facingLeft ? 1.0 : -1.0), scalef(st.size))
  translate(c, -.fx, -.fy)
  let ordered = Js.Array2.copy(rg.parts)
  ignore(Js.Array2.sortInPlaceWith(ordered, (a, b) => a.spec.z - b.spec.z))
  Js.Array2.forEach(ordered, p => {
    save(c)
    Js.Array2.forEach(lineage(rg, p.spec.name), anc => applyPose(c, st, anc))
    drawImage(c, p.img, p.ox, p.oy)
    restore(c)
    /* the cap sits on the joint itself: posed like the parent, not the part */
    switch p.spec.cap {
    | Some({radius: Px(r), colour, edge}) => {
        save(c)
        Js.Array2.forEach(
          switch p.spec.parent {
          | Some(par) => lineage(rg, par)
          | None => []
          },
          anc => applyPose(c, st, anc),
        )
        let (Px(cx), Px(cy)) = p.spec.pivot
        setFillStyle(c, colour)
        setStrokeStyle(c, edge)
        setLineWidth(c, 4.0)
        beginPath(c)
        ellipse(c, cx, cy, r, r, 0.0, 0.0, 2.0 *. Js.Math._PI)
        fill(c)
        stroke(c)
        restore(c)
      }
    | None => ()
    }
  })
  /* the named patch, in its parent's space, over everything */
  switch st.mouth {
  | Some(m) =>
    Js.Array2.forEach(rg.patches, ((ps, img)) =>
      if ps.patch == m {
        save(c)
        Js.Array2.forEach(lineage(rg, ps.parent), anc => applyPose(c, st, anc))
        let (Px(ax), Px(ay)) = ps.at
        drawImage(c, img, ax, ay)
        restore(c)
      }
    )
  | None => ()
  }
  restore(c)
}

/* ------------------------------------------------------------- speech */
/* Rhubarb's viseme track decides which mouth patch shows at an instant.
   A (rest) and X (silence) show the sprite's own mouth. */
type viseme = {from: float, to_: float, shape: string}
let visemes = (path: string): array<viseme> => {
  let j = Js.Json.parseExn(readFileSync(path, "utf8"))
  let cues =
    j
    ->Js.Json.decodeObject
    ->Belt.Option.flatMap(o => Js.Dict.get(o, "mouthCues"))
    ->Belt.Option.flatMap(Js.Json.decodeArray)
    ->Belt.Option.getWithDefault([])
  Js.Array2.map(cues, cue => {
    let o = cue->Js.Json.decodeObject->Belt.Option.getWithDefault(Js.Dict.empty())
    let num = k => Js.Dict.get(o, k)->Belt.Option.flatMap(Js.Json.decodeNumber)->Belt.Option.getWithDefault(0.0)
    let str = k => Js.Dict.get(o, k)->Belt.Option.flatMap(Js.Json.decodeString)->Belt.Option.getWithDefault("X")
    {from: num("start"), to_: num("end"), shape: str("value")}
  })
}
let rhubarbMouth = shape =>
  switch shape {
  | "E" | "F" => Some("round")
  | "D" => Some("open")
  | "B" | "C" | "G" | "H" => Some("half")
  | _ => None
  }
let mouthAt = (vs: array<viseme>, ~map=rhubarbMouth, t: sec) =>
  switch Js.Array2.find(vs, v => secf(t) >= v.from && secf(t) < v.to_) {
  | Some(v) => map(v.shape)
  | None => None
  }
/* how much talking is happening around t: 1 inside a non-rest cue, easing off */
let talking = (vs: array<viseme>, t: sec) =>
  switch Js.Array2.find(vs, v => secf(t) >= v.from && secf(t) < v.to_) {
  | Some(v) => v.shape == "X" || v.shape == "A" ? 0.0 : 1.0
  | None => 0.0
  }

/* ----------------------------------------------------------- animation */
/* keyframes with eased interpolation; before the first key holds the first
   value, after the last holds the last */
type key = {at: sec, v: float}
let easeInOut = u => u < 0.5 ? 4.0 *. u *. u *. u : 1.0 -. Js.Math.pow_float(~base=-2.0 *. u +. 2.0, ~exp=3.0) /. 2.0
let linear = u => u
let track = (keys: array<key>, ~ease=easeInOut, t: sec) => {
  let tv = secf(t)
  let n = Js.Array2.length(keys)
  if n == 0 {
    0.0
  } else if tv <= secf(keys[0].at) {
    keys[0].v
  } else if tv >= secf(keys[n - 1].at) {
    keys[n - 1].v
  } else {
    let i = ref(0)
    while i.contents < n - 2 && tv > secf(keys[i.contents + 1].at) {
      i := i.contents + 1
    }
    let a = keys[i.contents]
    let b = keys[i.contents + 1]
    let u = (tv -. secf(a.at)) /. (secf(b.at) -. secf(a.at))
    a.v +. (b.v -. a.v) *. ease(u)
  }
}
/* a cycle: amplitude * sin(2π hz t + phase) */
let cycle = (~hz, ~amp, ~phase=0.0, t: sec) => amp *. Js.Math.sin(2.0 *. Js.Math._PI *. hz *. secf(t) +. phase)

/* ---------------------------------------------------------------- stage */
/* the camera: a zoom about a look-at point; 1.0 shows the whole stage */
type camera = {zoom: scale, lookX: px, lookY: px}
let wholeStage = (w, h) => {zoom: Scale(1.0), lookX: Px(w /. 2.0), lookY: Px(h /. 2.0)}

/* a layer draws itself for an instant; z orders the stage, higher in front */
type layer = {z: int, draw: (ctx, sec) => unit}

let imageLayer = async (~z, ~path, ~x, ~y, ~w, ~h) => {
  let img = await loadImage(path)
  {z, draw: (c, _t) => drawImageSized(c, img, pxf(x), pxf(y), pxf(w), pxf(h))}
}
let plateLayer = (~path, ~w, ~h) => imageLayer(~z=0, ~path, ~x=Px(0.0), ~y=Px(0.0), ~w, ~h)
let puppetLayer = (~z, ~rig, ~state: sec => puppetState) => {
  z,
  draw: (c, t) => drawPuppet(c, rig, state(t)),
}
/* a soft contact shadow: an ellipse whose spread and depth follow a state */
type shadow = {cx: px, cy: px, rx: px, ry: px, a: alpha}
let shadowLayer = (~z, ~shadow: sec => shadow) => {
  z,
  draw: (c, t) => {
    let s = shadow(t)
    save(c)
    setGlobalAlpha(c, switch s.a { | Alpha(v) => v })
    setFillStyle(c, "#2a1d10")
    beginPath(c)
    ellipse(c, pxf(s.cx), pxf(s.cy), pxf(s.rx), pxf(s.ry), 0.0, 0.0, 2.0 *. Js.Math._PI)
    fill(c)
    restore(c)
  },
}
/* a sprite patch shown only while a predicate holds (mouth shapes, the lamp) */
let patchLayer = async (~z, ~path, ~x, ~y, ~w, ~h, ~on: sec => bool) => {
  let img = await loadImage(path)
  {z, draw: (c, t) => on(t) ? drawImageSized(c, img, pxf(x), pxf(y), pxf(w), pxf(h)) : ()}
}

type shot = {
  name: string,
  width: int,
  height: int,
  fps: fps,
  duration: sec,
  layers: array<layer>,
  camera: sec => camera,
  audio: option<string>,
  out: string,
}

let pad5 = i => {
  let s = Belt.Int.toString(i)
  Js.String2.repeat("0", 5 - Js.String2.length(s)) ++ s
}

/* RENDER: every frame drawn in full, PNGs in a temporary directory outside the
   repository, one ffmpeg encode, the frames removed. Deterministic: the same
   shot renders the same bytes. */
let render = (sh: shot) => {
  let Fps(fps) = sh.fps
  let n = Belt.Float.toInt(Js.Math.ceil_float(secf(sh.duration) *. Belt.Int.toFloat(fps)))
  let dir = mkdtempSync(join(tmpdir(), "puppet-" ++ sh.name ++ "-"))
  let cv = createCanvas(sh.width, sh.height)
  let c = getContext(cv, "2d")
  setSmoothing(c, true)
  let ordered = Js.Array2.copy(sh.layers)
  ignore(Js.Array2.sortInPlaceWith(ordered, (a, b) => a.z - b.z))
  let w = Belt.Int.toFloat(sh.width)
  let h = Belt.Int.toFloat(sh.height)
  for i in 0 to n - 1 {
    let t = Sec(Belt.Int.toFloat(i) /. Belt.Int.toFloat(fps))
    clearRect(c, 0.0, 0.0, w, h)
    save(c)
    let cam = sh.camera(t)
    let z = scalef(cam.zoom)
    /* zoom about the look-at point, keeping it where it was */
    translate(c, w /. 2.0, h /. 2.0)
    scaleCtx(c, z, z)
    translate(c, -.pxf(cam.lookX), -.pxf(cam.lookY))
    Js.Array2.forEach(ordered, l => l.draw(c, t))
    restore(c)
    let name = pad5(i)
    writeFileBuffer(join(dir, name ++ ".png"), toBuffer(cv, "image/png"))
  }
  let audioArgs = switch sh.audio {
  | Some(a) => ["-i", a, "-map", "0:v", "-map", "1:a", "-c:a", "aac", "-b:a", "160k", "-shortest"]
  | None => []
  }
  Cinema_Backends.ffmpeg(
    Js.Array2.concatMany(
      ["-y", "-v", "error", "-framerate", Belt.Int.toString(fps), "-i", join(dir, "%05d.png")],
      [audioArgs, ["-c:v", "libx264", "-crf", "18", "-pix_fmt", "yuv420p", "-r", Belt.Int.toString(fps), sh.out]],
    ),
  )
  rmSync(dir, {"recursive": true, "force": true})
  Js.log("rendered " ++ sh.out ++ " (" ++ Belt.Int.toString(n) ++ " frames)")
}

/* ONE FRAME of a shot to a PNG — for looking at a pose or a cut before
   rendering anything. Same drawing path as render. */
let frame = (sh: shot, t: sec, out: string) => {
  let cv = createCanvas(sh.width, sh.height)
  let c = getContext(cv, "2d")
  setSmoothing(c, true)
  let ordered = Js.Array2.copy(sh.layers)
  ignore(Js.Array2.sortInPlaceWith(ordered, (a, b) => a.z - b.z))
  let w = Belt.Int.toFloat(sh.width)
  let h = Belt.Int.toFloat(sh.height)
  save(c)
  let cam = sh.camera(t)
  let z = scalef(cam.zoom)
  translate(c, w /. 2.0, h /. 2.0)
  scaleCtx(c, z, z)
  translate(c, -.pxf(cam.lookX), -.pxf(cam.lookY))
  Js.Array2.forEach(ordered, l => l.draw(c, t))
  restore(c)
  writeFileBuffer(out, toBuffer(cv, "image/png"))
}

/* a flat colour ground, for looking at cuts against nothing */
let colourLayer = (~z, ~colour, ~w, ~h) => {
  z,
  draw: (c, _t) => {
    save(c)
    setFillStyle(c, colour)
    fillRect(c, -.pxf(w), -.pxf(h), 3.0 *. pxf(w), 3.0 *. pxf(h))
    restore(c)
  },
}

/* a contact sheet of a rendered shot, for looking before sending */
let contactSheet = (~video, ~out, ~cols, ~rows, ~everySec) =>
  Cinema_Backends.ffmpeg([
    "-y", "-v", "error", "-i", video,
    "-vf", "fps=1/" ++ Js.Float.toString(everySec) ++ ",scale=320:-1,tile=" ++ Belt.Int.toString(cols) ++ "x" ++ Belt.Int.toString(rows),
    "-frames:v", "1", out,
  ])

/* -------------------------------------------------------------- light */
/* The one plate, graded in code: a multiply tint darkens and colours the whole
   stage; a glow adds light around a point. Same geometry in every state, so
   the courtyard can never drift between dusk, lamp-night, dark and golden. */
let tintLayer = (~z, ~colour, ~w, ~h) => {
  z,
  draw: (c, _t) => {
    save(c)
    setCompositeOp(c, "multiply")
    setFillStyle(c, colour)
    fillRect(c, -.pxf(w), -.pxf(h), 3.0 *. pxf(w), 3.0 *. pxf(h))
    restore(c)
  },
}
type glow = {gx: px, gy: px, radius: px, strength: alpha}
let glowLayer = (~z, ~colour, ~glow: sec => glow) => {
  z,
  draw: (c, t) => {
    let g = glow(t)
    let (Px(x), Px(y), Px(r)) = (g.gx, g.gy, g.radius)
    save(c)
    setCompositeOp(c, "lighter")
    setGlobalAlpha(c, switch g.strength { | Alpha(a) => a })
    let grad = createRadialGradient(c, x, y, 0.0, x, y, r)
    addColorStop(grad, 0.0, colour)
    addColorStop(grad, 1.0, "rgba(0,0,0,0)")
    setFillGradient(c, grad)
    fillRect(c, x -. r, y -. r, 2.0 *. r, 2.0 *. r)
    restore(c)
  },
}
