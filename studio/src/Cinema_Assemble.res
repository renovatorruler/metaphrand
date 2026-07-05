/* See Cinema_Assemble.resi for the contract. A faithful port of cinema/assemble:
   normalize each shot to an exact-length clip (Ken Burns / static / video), then
   chain xfade cross-dissolves over them, synced to the audio. All ffmpeg via
   Cinema_Backends. */

@unboxed type weight = Weight(float)
@unboxed type px = Px(int)
@unboxed type fps = Fps(int)

type kind = Video | KbIn | KbOut | Static
type shot = {src: Cinema_Backends.path, kind: kind, weight: weight}
type resolution = {width: px, height: px}

let f3 = (x: float): string => Js.Float.toFixedWithPrecision(x, ~digits=3)
let i = Belt.Int.toString

/* one normalized clip of exactly `seconds`. Stills get Ken Burns; videos play
   once then freeze their last frame to fill the hold (no loop seam). */
let clip = (
  ~src: Cinema_Backends.path,
  ~kind: kind,
  ~seconds: float,
  ~res: resolution,
  ~fps: fps,
  ~out: Cinema_Backends.path,
): Cinema_Backends.path => {
  let Cinema_Backends.Path(s) = src
  let Cinema_Backends.Path(o) = out
  let Px(w) = res.width
  let Px(h) = res.height
  let Fps(fps) = fps
  switch kind {
  | Video => {
      let vf =
        "scale=" ++ i(w) ++ ":" ++ i(h) ++ ":force_original_aspect_ratio=increase,crop=" ++
        i(w) ++ ":" ++ i(h) ++ ",fps=" ++ i(fps) ++ ",tpad=stop_mode=clone:stop_duration=" ++
        f3(seconds) ++ ",format=yuv420p"
      Cinema_Backends.ffmpeg([
        "-nostdin", "-loglevel", "error", "-y", "-i", s, "-t", f3(seconds),
        "-vf", vf, "-an", "-c:v", "libx264", "-preset", "ultrafast", "-crf", "20", o,
      ])
    }
  | Static => {
      /* no motion -> skip zoompan entirely (just scale + hold); much cheaper. */
      let vf =
        "scale=" ++ i(w) ++ ":" ++ i(h) ++ ":force_original_aspect_ratio=increase,crop=" ++
        i(w) ++ ":" ++ i(h) ++ ",format=yuv420p"
      Cinema_Backends.ffmpeg([
        "-nostdin", "-loglevel", "error", "-y", "-loop", "1", "-t", f3(seconds),
        "-i", s, "-r", i(fps), "-vf", vf, "-c:v", "libx264", "-preset", "ultrafast",
        "-crf", "20", o,
      ])
    }
  | KbIn | KbOut => {
      /* Fast Ken Burns: a slow moving-crop DRIFT, then one downscale. zoompan is
         CPU-only and effectively single-threaded (~2.5 fps here; benchmarked: 5s
         of output took 48s on a 24-core machine). crop can animate POSITION per
         frame (eval=frame) but not size, so the move is a gentle diagonal drift,
         not a push - and it renders the same 5s in 0.04s (~1200x faster).
         KbIn/KbOut drift in opposite diagonals; travel stays in the middle 50%
         of the overscan so the subject never slides out of frame. */
      let over = 1.16
      let bw = Belt.Float.toInt(Belt.Int.toFloat(w) *. over)
      let bh = Belt.Float.toInt(Belt.Int.toFloat(h) *. over)
      let d = f3(Js.Math.max_float(0.1, seconds))
      let (xE, yE) = switch kind {
      | KbOut => ("(iw-ow)*(0.75-0.5*t/" ++ d ++ ")", "(ih-oh)*(0.75-0.5*t/" ++ d ++ ")")
      | _ => ("(iw-ow)*(0.25+0.5*t/" ++ d ++ ")", "(ih-oh)*(0.25+0.5*t/" ++ d ++ ")")
      }
      /* NB: this ffmpeg's crop has no `eval` option; x/y carry the per-frame (T)
         flag and animate by default, so we omit eval entirely. */
      let vf =
        "scale=" ++ i(bw) ++ ":" ++ i(bh) ++ ":force_original_aspect_ratio=increase,crop=" ++
        i(bw) ++ ":" ++ i(bh) ++ ",crop=w=" ++ i(w) ++ ":h=" ++ i(h) ++ ":x='" ++ xE ++
        "':y='" ++ yE ++ "',fps=" ++ i(fps) ++ ",format=yuv420p"
      Cinema_Backends.ffmpeg([
        "-nostdin", "-loglevel", "error", "-y", "-loop", "1", "-t", f3(seconds),
        "-i", s, "-vf", vf, "-c:v", "libx264", "-preset", "ultrafast", "-crf", "20", o,
      ])
    }
  }
  out
}

let assemble = (
  ~shots: array<shot>,
  ~audio: Cinema_Backends.path,
  ~out: Cinema_Backends.path,
  ~res: resolution,
  ~fps: fps,
  ~xfade: Cinema_Backends.seconds,
): Cinema_Backends.path => {
  let Cinema_Backends.Seconds(xf) = xfade
  let Cinema_Backends.Path(outStr) = out
  let Fps(fpsN) = fps
  let n = Array.length(shots)
  let Cinema_Backends.Seconds(dur) = Cinema_Backends.durationSec(audio)
  let wsum = {
    let s = Belt.Array.reduce(shots, 0.0, (acc, sh) => {
      let Weight(w) = sh.weight
      acc +. w
    })
    s == 0.0 ? 1.0 : s
  }
  /* xfades overlap, so holds must overshoot the audio by (n-1)*xfade. */
  let total = dur +. Belt.Int.toFloat(n - 1) *. xf
  let holds = Belt.Array.map(shots, sh => {
    let Weight(w) = sh.weight
    total *. w /. wsum
  })

  let Cinema_Backends.Path(tmp) = Cinema_Backends.tempDir("cine_asm_")
  /* build each clip at hold+xfade so the dissolve has overlap to consume. */
  let clips = Belt.Array.mapWithIndex(shots, (idx, sh) => {
    let hold = Belt.Array.getExn(holds, idx)
    let c = clip(
      ~src=sh.src,
      ~kind=sh.kind,
      ~seconds=hold +. xf,
      ~res,
      ~fps,
      ~out=Cinema_Backends.Path(tmp ++ "/c" ++ (idx < 10 ? "0" : "") ++ i(idx) ++ ".mp4"),
    )
    (c, hold)
  })

  let Px(w) = res.width
  let Px(h) = res.height
  /* inputs: every clip, then the audio last. */
  let inputArgs = Belt.Array.concatMany(
    Belt.Array.map(clips, ((Cinema_Backends.Path(c), _)) => ["-i", c]),
  )
  let audioArgs = {
    let Cinema_Backends.Path(a) = audio
    ["-i", a]
  }

  /* [k:v]fps,scale,setsar,format[vk] for each clip. */
  let normParts = Belt.Array.makeBy(n, k =>
    "[" ++ i(k) ++ ":v]fps=" ++ i(fpsN) ++ ",scale=" ++ i(w) ++ ":" ++ i(h) ++
    ",setsar=1,format=yuv420p[v" ++ i(k) ++ "]"
  )

  /* the xfade chain: dissolve clip j into j+1 at the running offset. */
  let rec chain = (j: int, prev: string, base: float, acc: array<string>): array<string> =>
    if j >= n - 1 {
      acc
    } else {
      let holdJ = snd(Belt.Array.getExn(clips, j))
      let holdJ1 = snd(Belt.Array.getExn(clips, j + 1))
      let base' = base +. holdJ
      let tj = Js.Math.max_float(0.05, Js.Math.min_float(xf, Js.Math.min_float(holdJ *. 0.7, holdJ1 *. 0.7)))
      let lbl = j == n - 2 ? "vout" : "x" ++ i(j + 1)
      let part =
        "[" ++ prev ++ "][v" ++ i(j + 1) ++ "]xfade=transition=fade:duration=" ++ f3(tj) ++
        ":offset=" ++ f3(base' -. tj /. 2.0) ++ "[" ++ lbl ++ "]"
      chain(j + 1, lbl, base', Belt.Array.concat(acc, [part]))
    }
  let xfadeParts = chain(0, "v0", 0.0, [])

  /* single shot: no xfade chain; map v0 straight out. */
  let (filter, mapLabel) =
    n == 1
      ? (Js.Array2.joinWith(normParts, ";"), "[v0]")
      : (Js.Array2.joinWith(Belt.Array.concat(normParts, xfadeParts), ";"), "[vout]")

  let cmd = Belt.Array.concatMany([
    ["-nostdin", "-loglevel", "error", "-y"],
    inputArgs,
    audioArgs,
    [
      "-filter_complex", filter,
      "-map", mapLabel, "-map", i(n) ++ ":a",
      "-c:v", "libx264", "-pix_fmt", "yuv420p", "-preset", "veryfast", "-crf", "21",
      "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-shortest", "-movflags", "+faststart",
      outStr,
    ],
  ])
  Cinema_Backends.ffmpeg(cmd)
  Js.log(
    outStr ++ ": " ++ i(n) ++ " shots, " ++ f3(dur) ++ "s, " ++
    Js.Float.toFixedWithPrecision(Cinema_Backends.fileSizeMb(out), ~digits=1) ++ " MB",
  )
  out
}
