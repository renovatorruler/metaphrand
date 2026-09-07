/* Puppet_Key.res — from a sheet sprite to a clean cutout, with a number that
   says so.

   A sprite is generated on one flat sheet in a colour the character does not
   wear. The cutout is made by a COLOUR RULE, not a chroma distance: on a blue
   sheet everything the character can be — pink, green, cream, gold, grey,
   black — has more red-and-green than blue, and the sheet has not. The rule
   gives a soft alpha ramp. Two things the rule alone leaves behind, and the
   author will not accept: the model paints the paper's cast shadow on the
   sheet hugging the outline, and the outline's own pixels are half sheet.
   So the matte is ERODED a few sprite pixels (well under one pixel on the
   stage), softened one pixel, and the remaining colour is despilled.

   Then it is MEASURED: `rim` walks the matte's boundary and counts pixels
   that are still sheet-coloured. A character passes on a number. */

open Puppet

type sheet = BlueSheet | GreenSheet
/* which colour law the character's own pixels obey, so the clamp can be exact:
   SheetChannel caps only the sheet's channel; RedDominant says no pixel of this
   character has green or blue beyond red — true of pink फ्यूरिया and golden
   कैस्टर — and catches cyan, which a blue-channel cap lets through. */
type clamp = SheetChannel | RedDominant
type keyRule = {
  sheet: sheet,
  clamp: clamp,
  rCoef: float, /* blue: the weight of red in (rCoef·r + 0.2g − b); lower catches desaturated blues, higher keeps blue-tinted shadows on the figure */
  bias: float, /* blue: added to the sum; green: the g−max(r,b) level that is still character */
  width: float, /* the ramp's width */
  erode: int, /* sprite pixels taken off the matte's edge */
  darkBelow: float, /* 0 = off; else the figure is also required to be darker than this luminance — for a black character drawn on a pale paper mat, which no channel rule can tell from him */
}

let f = Js.Float.toString

let alphaExpr = r => {
  let rule = switch r.sheet {
  | BlueSheet => "(" ++ f(r.rCoef) ++ "*r(X,Y)+0.2*g(X,Y)-b(X,Y)+" ++ f(r.bias) ++ ")/" ++ f(r.width)
  | GreenSheet => "(" ++ f(r.bias) ++ "-(g(X,Y)-max(r(X,Y),b(X,Y))))/" ++ f(r.width)
  }
  r.darkBelow > 0.0
    ? "255*clip(min(" ++ rule ++ ",(" ++ f(r.darkBelow) ++ "-(r(X,Y)+g(X,Y)+b(X,Y))/3)/30),0,1)"
    : "255*clip(" ++ rule ++ ",0,1)"
}
/* No despill. ffmpeg's despill strips the sheet channel from every pixel
   where it exceeds a fraction of the others: on pale blue वैस्पर it took a
   third of the green and turned him lilac. The clamp below is the only colour
   correction, and it touches only sheet-dominant pixels. */
let erosions = n => Js.Array2.joinWith(Belt.Array.make(n, "erosion"), ",")

/* THE CLAMP. Despill is a soft correction and leaves the model's own
   sheet-tinted shadows on the figure — the outlines the author refused. On a
   blue sheet no pixel of the character may be blue-dominant, on a green sheet
   none green-dominant: the offending channel is capped just above the larger
   of the other two. Deterministic, and what `rim` then measures is honest. */
let clampOf = r =>
  switch (r.clamp, r.sheet) {
  | (RedDominant, _) => "geq=r='r(X,Y)':g='min(g(X,Y),r(X,Y)+10)':b='min(b(X,Y),r(X,Y)+10)':a='alpha(X,Y)'"
  | (SheetChannel, BlueSheet) => "geq=r='r(X,Y)':g='g(X,Y)':b='min(b(X,Y),max(r(X,Y),g(X,Y))+8)':a='alpha(X,Y)'"
  | (SheetChannel, GreenSheet) => "geq=r='r(X,Y)':g='min(g(X,Y),max(r(X,Y),b(X,Y))+8)':b='b(X,Y)':a='alpha(X,Y)'"
  }

/* the whole chain: rule → alpha, alpha eroded and softened, despilled colour */
let chain = (rule, ~pre="", ~post="") =>
  pre ++
  "format=rgba,geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':a='" ++
  alphaExpr(rule) ++
  "',split[rgb][al];[al]alphaextract," ++
  erosions(rule.erode) ++
  ",boxblur=1:1[am];[rgb][am]alphamerge," ++
  clampOf(rule) ++
  post

let key = (~rule, ~src, ~dst) =>
  Cinema_Backends.ffmpeg(["-y", "-v", "error", "-i", src, "-filter_complex", "[0:v]" ++ chain(rule), dst])

/* a mouth patch: one box of an edit, keyed the same way, with a soft
   elliptical edge so the swap has no seam */
let softMask = ",geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':a='alpha(X,Y)*(1-clip(pow(hypot((X-W/2)/(W/2),(Y-H/2)/(H/2)),6),0,1))'"
let patch = (~rule, ~src, ~dst, ~x, ~y, ~w, ~h) =>
  Cinema_Backends.ffmpeg([
    "-y", "-v", "error", "-i", src, "-filter_complex",
    "[0:v]" ++ chain(rule, ~pre="crop=" ++ Belt.Int.toString(w) ++ ":" ++ Belt.Int.toString(h) ++ ":" ++ Belt.Int.toString(x) ++ ":" ++ Belt.Int.toString(y) ++ ",", ~post=softMask),
    dst,
  ])

/* ------------------------------------------------------------ measuring */
let pixels = async path => {
  let img = await loadImage(ImagePath(path))
  let w = Belt.Float.toInt(imageWidth(img))
  let h = Belt.Float.toInt(imageHeight(img))
  let cv = createCanvas(w, h)
  let c = getContext(cv, "2d")
  drawImage(c, img, 0.0, 0.0)
  (w, h, imageDataBytes(getImageData(c, 0.0, 0.0, Belt.Int.toFloat(w), Belt.Int.toFloat(h))))
}

type rimReport = {boundary: int, sheetish: int, percent: float, kept: int, keptPercent: float}

/* RIM: of the opaque pixels that touch transparency (within two pixels),
   how many still carry the sheet's colour? And KEPT: of all opaque pixels,
   how many were sheet-coloured in the RAW — sheet that the rule let through
   as figure, which the clamp would otherwise hide from the first count. */
let rim = async (~sheet, ~raw, path) => {
  let (w, h, d) = await pixels(path)
  let (_, _, dr) = await pixels(raw)
  let get = i => Js.TypedArray2.Uint8ClampedArray.unsafe_get(d, i)
  let getRaw = i => Js.TypedArray2.Uint8ClampedArray.unsafe_get(dr, i)
  let alphaAt = (x, y) => get((y * w + x) * 4 + 3)
  let boundary = ref(0)
  let sheetish = ref(0)
  let opaque = ref(0)
  let kept = ref(0)
  for y in 2 to h - 3 {
    for x in 2 to w - 3 {
      if alphaAt(x, y) > 128 {
        opaque := opaque.contents + 1
        let ri = (y * w + x) * 4
        let (rr, rg, rb) = (getRaw(ri), getRaw(ri + 1), getRaw(ri + 2))
        let rawSheet = switch sheet {
        | BlueSheet => rb - Js.Math.max_int(rr, rg) > 12 || (rb - rr > 40 && rg - rr > 20)
        | GreenSheet => rg - Js.Math.max_int(rr, rb) > 12
        }
        if rawSheet {
          kept := kept.contents + 1
        }
        let edge =
          alphaAt(x - 2, y) < 128 || alphaAt(x + 2, y) < 128 || alphaAt(x, y - 2) < 128 || alphaAt(x, y + 2) < 128
        if edge {
          boundary := boundary.contents + 1
          let i = (y * w + x) * 4
          let (r, g, b) = (get(i), get(i + 1), get(i + 2))
          /* a blue sheet may come out cyan: blue-and-green well over red counts too */
          let sheetColoured = switch sheet {
          | BlueSheet => b - Js.Math.max_int(r, g) > 12 || (b - r > 40 && g - r > 20)
          | GreenSheet => g - Js.Math.max_int(r, b) > 12
          }
          if sheetColoured {
            sheetish := sheetish.contents + 1
          }
        }
      }
    }
  }
  {
    boundary: boundary.contents,
    sheetish: sheetish.contents,
    percent: boundary.contents == 0 ? 0.0 : 100.0 *. Belt.Int.toFloat(sheetish.contents) /. Belt.Int.toFloat(boundary.contents),
    kept: kept.contents,
    keptPercent: opaque.contents == 0 ? 0.0 : 100.0 *. Belt.Int.toFloat(kept.contents) /. Belt.Int.toFloat(opaque.contents),
  }
}

/* REGISTER: where an edit's head sits relative to the base sprite's, measured
   on an anchor box the edit did not change (eyes and brow), by brute force on
   luminance. Returns the offset to add to a box in base coordinates. */
let register = async (~base, ~edit, ~anchor: (int, int, int, int), ~radius) => {
  let (wb, _, db) = await pixels(base)
  let (we, _, de) = await pixels(edit)
  let lum = (d, w, x, y) => {
    let i = (y * w + x) * 4
    let g = j => Belt.Int.toFloat(Js.TypedArray2.Uint8ClampedArray.unsafe_get(d, j))
    0.299 *. g(i) +. 0.587 *. g(i + 1) +. 0.114 *. g(i + 2)
  }
  let (ax, ay, aw, ah) = anchor
  let best = ref((infinity, 0, 0))
  for dy in -radius to radius {
    for dx in -radius to radius {
      let s = ref(0.0)
      let y = ref(0)
      while y.contents < ah {
        let x = ref(0)
        while x.contents < aw {
          let dlt = lum(db, wb, ax + x.contents, ay + y.contents) -. lum(de, we, ax + x.contents + dx, ay + y.contents + dy)
          s := s.contents +. dlt *. dlt
          x := x.contents + 2
        }
        y := y.contents + 2
      }
      let (bs, _, _) = best.contents
      if s.contents < bs {
        best := (s.contents, dx, dy)
      }
    }
  }
  let (_, dx, dy) = best.contents
  (dx, dy)
}
