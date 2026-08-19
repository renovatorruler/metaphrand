/* कुकु और अक्षर — the episode assembler, ported from ep5prod/assemble_ep5.sh.

   Structure of a build: every segment renders to its own silent clip, the clips
   concat into a scene picture, the scene's takes and effects are placed on one
   dialogue bus, the score is ducked underneath, the two mix and mux, and the
   scenes concat between title and credits.

   Three rules earned the hard way and enforced here rather than remembered:

   1. Only SPEECH advances the clock. Effects ride underneath a shot; letting a
      sound cue extend a cut once stretched shots to absurd lengths. The `take`
      variant makes every walk over takes say what it does with each kind.
   2. The per-segment cache is keyed on the SEGMENT SPEC, not its slot index.
      Keying on scene+index silently reused stale pictures through a 93-segment
      rewire — the build reported success and changed nothing on screen.
   3. Two voices may never overlap, and a cut may never demand more footage than
      its source has. Both are checked before a frame is written. */

open Cinema_Backends

@val @scope(("process", "env")) external dumpDir: option<string> = "KUKU_DUMP"
@val @scope(("process", "env")) external skipPreflight: option<string> = "PREFLIGHT_SKIP"

/* frame geometry and the dialogue metronome — must match across a whole episode */
let width = 1280
let height = 720
let fps = 24
let lead = 0.3 /* first line sits this far into a shot */
let gap = 0.28 /* silence between two lines in the same shot */
let tail = 0.38 /* hold after the last line before we cut */

let i2s = Belt.Int.toString
/* shortest round-trip form: ffmpeg parses these as numbers, so 6.6 and 6.600 are
   the same cut — only the value matters. */
let f = (x: float): string => Js.Float.toString(x)
let f2 = (x: float): string => Js.Float.toFixedWithPrecision(x, ~digits=2)
let f3 = (x: float): string => Js.Float.toFixedWithPrecision(x, ~digits=3)
let round3 = (x: float): float => Js.Math.round(x *. 1000.0) /. 1000.0

/* EVERY SEGMENT LENGTH IS A WHOLE NUMBER OF FRAMES.

   The picture is rendered as `round(dur*fps)` frames, so it lasts a whole number of
   frames whatever `dur` says — but the audio clock used to advance by the exact
   float. The two therefore disagreed by up to half a frame per segment, and the
   error accumulated down the scene: measured at -80ms over s5's 36 segments, which
   is two frames of lip-sync error by the end of a scene.

   Aligning here makes the disagreement impossible rather than small: video length
   and audio advance are the same number. It rounds UP so a segment can never be
   shorter than the speech it has to hold. */
let frameAlign = (x: float): float => {
  let n = Belt.Int.toFloat(fps)
  Js.Math.ceil_float(round3(x *. n)) /. n
}

/* ambience that must dip under a spoken line. Anything not in here plays flat:
   a door slam is an event and should punch through, a river is a bed. */
let ambience = [
  /* Ep5 */
  "stream_loud",
  "wind_gust",
  "evening_crickets",
  "hands_in_water",
  "rope_creak",
  "kite_flutter",
  "run_planks",
  /* Ep6 — omitted at first, so Ep6 beds never ducked under speech */
  "morning_birds_pond",
  "pond_water_calm",
  "day_crickets",
  "leaves_rustle",
  "reeds_wind",
  "stream_bridge_ropes",
]

type placed = {take: Kuku_Edl.take, at: float, stop: float, duck: bool}
type event = {path: string, abs: float, stop: float, duck: bool, speech: bool}

let isSpeech = (t: Kuku_Edl.take): bool =>
  switch t {
  | Speech(_) => true
  | Effect(_) => false
  }

/* Lay this segment's takes on a local timeline and report how long the shot must
   be to hold them. An explicit `at` always wins; otherwise the first line starts
   at `lead` and each later line follows the previous by `gap`. */
let placeTakes = (seg: Kuku_Edl.segment, durs: Kuku_Edl.durs): (array<placed>, float) => {
  let clock = ref(0.0)
  let spoken = ref(0)
  let out = []
  seg.takes->Belt.Array.forEach(t => {
    let speech = isSpeech(t)
    let explicit = switch t {
    | Speech({at}) => at
    | Effect({at}) => at
    }
    let at = switch explicit {
    | Some(a) => a
    | None => spoken.contents == 0 ? lead : clock.contents +. gap
    }
    let d = Kuku_Edl.eventDur(durs, t)
    let duck = switch t {
    | Speech(_) => true
    | Effect({duck}) => duck
    }
    let _ = Js.Array2.push(out, {take: t, at, stop: at +. d, duck})
    /* only speech advances the clock — effects ride underneath */
    if speech {
      clock := Js.Math.max_float(clock.contents, at +. d)
      spoken := spoken.contents + 1
    }
  })
  let speechEnds = out->Belt.Array.keep(p => isSpeech(p.take))->Belt.Array.map(p => p.stop)
  let need = Belt.Array.length(speechEnds) == 0
    ? 0.0
    : Belt.Array.reduce(speechEnds, 0.0, Js.Math.max_float) +. tail
  (out, need)
}

let segDuration = (seg: Kuku_Edl.segment, durs: Kuku_Edl.durs): (float, array<placed>) => {
  let (placed, need) = placeTakes(seg, durs)
  if seg.bridge {
    switch seg.dur {
    | Some(d) => (frameAlign(d), placed)
    | None => raise(BackendError("bridge segment without an explicit dur"))
    }
  } else {
    let dur = Js.Math.max_float(seg.dur->Belt.Option.getWithDefault(0.0), need)
    if dur <= 0.0 {
      raise(BackendError("segment with no duration: " ++ Kuku_Edl.sourceToString(seg.src)))
    }
    (frameAlign(dur), placed)
  }
}

/* ---- rendering one segment ----------------------------------------------- */

/* tr/br are for the word-picture inset, which sits beside the characters rather
   than over them — a centred overlay would cover the faces that are speaking. */
let overlayPos = (pos: string): string =>
  switch pos {
  | "c" => "(W-w)/2:(H-h)/2"
  | "shield" => "(W-w)/2:(H-h)/2-H*0.10"
  | "bc" => "(W-w)/2:H*0.58"
  | "tr" => "W-w-W*0.05:H*0.07"
  | "br" => "W-w-W*0.05:H-h-H*0.07"
  | "tl" => "W*0.05:H*0.07"
  | _ => "(W-w)/2:H*0.08"
  }

let renderSegment = (
  ~dir: string,
  ~scene: string,
  ~idx: int,
  ~seg: Kuku_Edl.segment,
  ~dur: float,
): string => {
  let pad = idx < 10 ? "0" ++ i2s(idx) : i2s(idx)
  let out = dir ++ "/build/" ++ scene ++ "_" ++ pad ++ ".mp4"
  let base = dir ++ "/build/" ++ scene ++ "_" ++ pad ++ "_base.mp4"
  let hasFx = Belt.Array.length(seg.fx) > 0
  let tgt = hasFx ? base : out
  let n = Js.Math.max_int(2, Belt.Float.toInt(Js.Math.round(dur *. Belt.Int.toFloat(fps))))
  let src = Kuku_Edl.sourcePath(seg.src)->Belt.Option.map(p => dir ++ "/" ++ p)

  /* SHOT OVERFLOW: a cut may not ask for more footage than the source holds. */
  switch (seg.src, src) {
  | (Clip(_), Some(p)) | (File(_), Some(p)) => {
      let Seconds(len) = probeDuration(Path(p))
      let want = seg.inPoint->Belt.Option.getWithDefault(0.0) +. dur
      if want > len +. 0.05 {
        raise(
          BackendError(
            "SHOT OVERFLOW: " ++
            scene ++
            "#" ++
            i2s(idx) ++
            " " ++
            Kuku_Edl.sourceToString(seg.src) ++
            " needs " ++
            f2(want) ++
            "s but source is " ++
            f2(len) ++
            "s — replan",
          ),
        )
      }
    }
  | _ => ()
  }

  /* CACHE KEY: the segment spec plus its length. Keyed on the slot index alone,
     a changed `src` reused the old picture and the rewire changed nothing. */
  let stamp = Path(dir ++ "/build/" ++ scene ++ "_" ++ pad ++ ".key")
  /* "r2" is the RENDER RECIPE version — bumped when the ffmpeg recipe itself
     changes (zoompan -> drift). Without it, a recipe change reuses every cached
     segment and the "fix" changes nothing on screen. */
  /* r3: stills static + image inputs forced to 24fps + frame-aligned durations */
  /* r4: the key carries the CONTENT HASH of the source image/clip and every fx
     overlay. Lesson 9 returned in a new disguise on 2026-08-06: two stills were
     re-rendered under their existing names (human children removed), the spec
     didn't change, every segment cache-hit, and the "fixed" episode shipped the
     old pixels to the review cut. The name is a claim; the bytes are the truth. */
  /* r5: shield-position glyph overlays have an explicit story-timed visibility
     window, so the exact अक्षर stays on the shield plate instead of floating
     across transitional frames. */
  let contentHash = (rel: string): string =>
    exists(Path(dir ++ "/" ++ rel)) ? sha256File(Path(dir ++ "/" ++ rel)) : "absent"
  let srcHash = switch Kuku_Edl.sourcePath(seg.src) {
  | Some(rel) => contentHash(rel)
  | None => "seq"
  }
  let fxHash =
    seg.fx
    ->Belt.Array.map(x => contentHash(x.png))
    ->Js.Array2.joinWith(",")
  let key =
    Js.Json.stringify(Kuku_Edl.encodeSegment(seg)) ++
    "|" ++ f3(dur) ++ "|r5|" ++ srcHash ++ "|" ++ fxHash
  let fresh = exists(stamp) && readText(stamp) == key
  if !fresh {
    removeFile(Path(out))
    removeFile(Path(base))
  }

  let needBase = !(hasFx && exists(Path(out))) && !exists(Path(tgt))
  if needBase {
    switch (seg.src, src) {
    | (Still(_), Some(p)) => {
        /* STILLS DO NOT MOVE.

           This used to drift a 1280x720 window diagonally across a 16% overscan.
           Two things were wrong with it. First, `-loop 1` feeds an image at 25fps
           by default, and the trailing `fps=24` then DROPS one frame every second
           — invisible on a motionless picture, but on a moving one it is a visible
           hitch once a second. That is the "camera shaking" flagged on the review
           cut, and it is also the real cause of the earlier "frame rate issue"
           that swapping zoompan for a drift failed to fix, because the decimation
           was never the zoompan's doing. Second, crop's x/y are integer pixels, so
           even at a matched rate a slow pan advances ~1.07px per frame and stutters
           between 1 and 2 pixel steps.

           Ep5 held its stills still and looked right. So does this. `-framerate`
           is set anyway so the input genuinely runs at 24 and nothing is ever
           decimated. */
        let vf =
          "scale=" ++
          i2s(width) ++
          ":" ++
          i2s(height) ++
          ":force_original_aspect_ratio=increase,crop=" ++
          i2s(width) ++
          ":" ++
          i2s(height) ++
          ",format=yuv420p"
        ffmpeg([
          "-y", "-loop", "1", "-framerate", i2s(fps), "-t", f(dur), "-i", p,
          "-vf", vf, "-frames:v", i2s(n),
          "-c:v", "libx264", "-crf", "18", "-an", tgt,
        ])
      }
    | (Card(_), Some(p)) =>
      ffmpeg([
        "-y", "-loop", "1", "-framerate", i2s(fps), "-i", p, "-t", f(dur),
        "-vf", "scale=" ++ i2s(width) ++ ":" ++ i2s(height) ++ ",fps=" ++ i2s(fps) ++ ",format=yuv420p",
        "-c:v", "libx264", "-crf", "18", "-an", tgt,
      ])
    | (Clip(_), Some(p)) | (File(_), Some(p)) => {
        let fade = switch seg.fadeout {
        | Some(fo) => ",fade=t=out:st=" ++ f(dur -. fo) ++ ":d=" ++ f(fo)
        | None => ""
        }
        /* -ss AFTER -i: output seek, as the Python had it. Input seek would land
           on a different keyframe and shift the picture against the dialogue. */
        ffmpeg([
          "-y", "-i", p, "-ss", f(seg.inPoint->Belt.Option.getWithDefault(0.0)), "-t", f(dur),
          "-vf",
          "fps=" ++ i2s(fps) ++ ",scale=" ++ i2s(width) ++ ":" ++ i2s(height) ++ fade ++ ",format=yuv420p",
          "-c:v", "libx264", "-crf", "18", "-an", tgt,
        ])
      }
    | (Seq, _) => {
        let cards = seg.cards
        /* Split the segment into whole FRAMES, not into equal floats. Dividing a
           duration by the card count and rounding each part independently loses or
           gains frames, and the recap then runs long or short against the audio it
           is recapping. The remainder goes to the last card, so the parts sum to
           exactly the segment's frame count. */
        let count = Belt.Array.length(cards)
        let per = n / count
        let lines = cards->Belt.Array.mapWithIndex((k, c) => {
          let frames = k == count - 1 ? n - per * (count - 1) : per
          let pp = dir ++ "/build/" ++ scene ++ "_" ++ pad ++ "_p" ++ i2s(k) ++ ".mp4"
          ffmpeg([
            "-y", "-loop", "1", "-framerate", i2s(fps),
            "-i", dir ++ "/cards/" ++ c ++ ".png", "-frames:v", i2s(frames),
            "-vf",
            "scale=" ++ i2s(width) ++ ":" ++ i2s(height) ++ ",fps=" ++ i2s(fps) ++ ",format=yuv420p",
            "-c:v", "libx264", "-crf", "18", "-an", pp,
          ])
          "file '" ++ scene ++ "_" ++ pad ++ "_p" ++ i2s(k) ++ ".mp4'"
        })
        let cat = dir ++ "/build/" ++ scene ++ "_" ++ pad ++ "_cat.txt"
        writeText(Path(cat), Js.Array2.joinWith(lines, "\n") ++ "\n")
        ffmpeg(["-y", "-f", "concat", "-safe", "0", "-i", cat, "-c", "copy", tgt])
      }
    | (Still(_), None) | (Card(_), None) | (Clip(_), None) | (File(_), None) =>
      raise(BackendError("segment source resolved to no path"))
    }
  }

  /* fx overlays (the drawn letter, mostly) fade in over the base picture */
  if hasFx && !exists(Path(out)) {
    let inputs = Belt.Array.concatMany([
      ["-y", "-i", base],
      Belt.Array.concatMany(seg.fx->Belt.Array.map(x => ["-loop", "1", "-i", dir ++ "/" ++ x.png])),
    ])
    let parts = []
    let prev = ref("0:v")
    seg.fx->Belt.Array.forEachWithIndex((k, x) => {
      let px = Belt.Float.toInt(Belt.Int.toFloat(width) *. x.scale)
      let _ = Js.Array2.push(
        parts,
        "[" ++ i2s(k + 1) ++ ":v]format=rgba,scale=" ++ i2s(px) ++ ":-1,fade=t=in:st=" ++ f(x.at) ++ ":d=0.5:alpha=1[f" ++ i2s(k) ++ "]",
      )
      let lbl = "a" ++ i2s(k)
      let overlayEnable = x.pos == "shield"
        ? ":enable='between(t,2.0,2.9)+between(t,5.0,7.0)'"
        : ""
      let _ = Js.Array2.push(
        parts,
        "[" ++ prev.contents ++ "][f" ++ i2s(k) ++ "]overlay=" ++ overlayPos(x.pos) ++ ":shortest=1" ++ overlayEnable ++ "[" ++ lbl ++ "]",
      )
      prev := lbl
    })
    let _ = Js.Array2.push(parts, "[" ++ prev.contents ++ "]format=yuv420p[ov]")
    ffmpeg(
      Belt.Array.concat(
        inputs,
        [
          "-filter_complex", Js.Array2.joinWith(parts, ";"),
          "-map", "[ov]", "-c:v", "libx264", "-crf", "18", "-an", out,
        ],
      ),
    )
  }

  writeText(stamp, key)
  out
}

/* ---- assets ---------------------------------------------------------------
   A scene with a missing asset is SKIPPED, not half-rendered: a silently short
   episode is easier to catch than a scene with a hole in it. */
let missingAssets = (~dir: string, ~scene: Kuku_Edl.scene, ~durs: Kuku_Edl.durs): array<string> => {
  let miss = []
  scene.segments->Belt.Array.forEach(seg => {
    switch Kuku_Edl.sourcePath(seg.src) {
    | Some(p) =>
      if !exists(Path(dir ++ "/" ++ p)) {
        let _ = Js.Array2.push(miss, p)
      }
    | None => ()
    }
    seg.cards->Belt.Array.forEach(c =>
      if !exists(Path(dir ++ "/cards/" ++ c ++ ".png")) {
        let _ = Js.Array2.push(miss, "cards/" ++ c)
      }
    )
    /* fx paths in the EDL are relative to the EPISODE dir, not the process cwd —
       the Python ran with cwd set there, this driver runs from studio/ */
    seg.fx->Belt.Array.forEach(x =>
      if !exists(Path(dir ++ "/" ++ x.png)) {
        let _ = Js.Array2.push(miss, x.png)
      }
    )
    seg.takes->Belt.Array.forEach(t =>
      switch Kuku_Edl.eventDur(durs, t) {
      | _ => ()
      | exception _ => {
          let _ = Js.Array2.push(miss, Kuku_Edl.eventPath(t))
        }
      }
    )
  })
  miss
}

/* ---- one scene ----------------------------------------------------------- */

let buildScene = (~dir: string, ~scene: Kuku_Edl.scene, ~durs: Kuku_Edl.durs): (string, float, int, int) => {
  let name = scene.name
  let clips = []
  let events = []
  let clock = ref(0.0)

  scene.segments->Belt.Array.forEachWithIndex((idx, seg) => {
    let (dur, placed) = segDuration(seg, durs)
    let _ = Js.Array2.push(clips, renderSegment(~dir, ~scene=name, ~idx, ~seg, ~dur))
    placed->Belt.Array.forEach(p => {
      let _ = Js.Array2.push(
        events,
        {
          path: dir ++ "/" ++ Kuku_Edl.eventPath(p.take),
          abs: clock.contents +. p.at,
          stop: clock.contents +. p.stop,
          duck: p.duck,
          speech: isSpeech(p.take),
        },
      )
    })
    clock := clock.contents +. dur
  })
  let total = round3(clock.contents)

  /* SPEECH-OVERLAP GUARD: two foreground voices may never collide. */
  let spoken = events->Belt.Array.keep(e => e.speech)
  let sorted = Belt.SortArray.stableSortBy(spoken, (a, b) => a.abs < b.abs ? -1 : a.abs > b.abs ? 1 : 0)
  Belt.Array.forEachWithIndex(sorted, (k, b) =>
    switch Belt.Array.get(sorted, k - 1) {
    | Some(a) =>
      if b.abs < a.stop -. 0.05 {
        raise(
          BackendError(
            "SPEECH OVERLAP in " ++
            name ++
            ": " ++
            a.path ++
            " ends " ++
            f2(a.stop) ++
            " but " ++
            b.path ++
            " starts " ++
            f2(b.abs) ++
            " — fix the EDL 'at'",
          ),
        )
      }
    | None => ()
    }
  )

  /* picture */
  let catPath = dir ++ "/build/" ++ name ++ "_cat.txt"
  writeText(
    Path(catPath),
    Js.Array2.joinWith(
      clips->Belt.Array.map(c => {
        let parts = Js.String2.split(c, "/")
        "file '" ++ Belt.Array.getExn(parts, Belt.Array.length(parts) - 1) ++ "'"
      }),
      "\n",
    ) ++ "\n",
  )
  let picture = dir ++ "/build/" ++ name ++ "_v.mp4"
  ffmpeg(["-y", "-f", "concat", "-safe", "0", "-i", catPath, "-c", "copy", picture])

  /* dialogue + effects bus, with ambience ducking under every spoken line */
  let speechWindows = spoken->Belt.Array.map(e => (e.abs, e.stop))
  let dlg = dir ++ "/build/" ++ name ++ "_dlg.wav"
  if Belt.Array.length(events) > 0 {
    let inputs = Belt.Array.concatMany(events->Belt.Array.map(e => ["-i", e.path]))
    let chains = events->Belt.Array.mapWithIndex((k, e) => {
      let stem = {
        let parts = Js.String2.split(e.path, "/")
        let base = Belt.Array.getExn(parts, Belt.Array.length(parts) - 1)
        switch Js.String2.lastIndexOf(base, ".") {
        | -1 => base
        | i => Js.String2.slice(base, ~from=0, ~to_=i)
        }
      }
      let duckf = if Belt.Array.some(ambience, a => a == stem) && Belt.Array.length(speechWindows) > 0 {
        let w =
          speechWindows
          ->Belt.Array.keep(((a, b)) => b > e.abs && a < e.stop)
          ->Belt.Array.map(((a, b)) =>
            "between(t," ++
            f2(Js.Math.max_float(0.0, a -. e.abs -. 0.15)) ++
            "," ++
            f2(Js.Math.max_float(0.0, b -. e.abs +. 0.25)) ++ ")"
          )
        Belt.Array.length(w) == 0
          ? ""
          : ",volume='if(" ++ Js.Array2.joinWith(w, "+") ++ ",0.30,1.0)':eval=frame"
      } else {
        ""
      }
      "[" ++
      i2s(k) ++
      ":a]aresample=44100" ++
      duckf ++
      ",adelay=" ++
      i2s(Belt.Float.toInt(e.abs *. 1000.0)) ++
      ":all=1[d" ++
      i2s(k) ++
      "]"
    })
    let mix = Js.Array2.joinWith(events->Belt.Array.mapWithIndex((k, _) => "[d" ++ i2s(k) ++ "]"), "")
    let fc =
      Js.Array2.joinWith(chains, ";") ++
      ";" ++
      mix ++
      "amix=inputs=" ++
      i2s(Belt.Array.length(events)) ++
      ":duration=longest:normalize=0,atrim=0:" ++
      f(total) ++
      ",apad=whole_dur=" ++
      f(total) ++ "[out]"
    /* KUKU_DUMP=1 writes the dialogue filter graph for byte-level comparison
       against a reference build — how the port was proven equivalent. */
    switch dumpDir {
    | Some(d) => writeText(Path(d ++ "/res_fc_" ++ name ++ ".txt"), fc)
    | None => ()
    }
    ffmpeg(
      Belt.Array.concatMany([
        ["-y"],
        inputs,
        ["-filter_complex", fc, "-map", "[out]", "-ac", "2", "-ar", "44100", dlg],
      ]),
    )
  }

  /* score, ducked under every event that asks for it */
  let duckers =
    events
    ->Belt.Array.keep(e => e.duck)
    ->(a => Belt.SortArray.stableSortBy(a, (x, y) => x.abs < y.abs ? -1 : x.abs > y.abs ? 1 : 0))
  let windows = []
  duckers->Belt.Array.forEach(e => {
    let a = Js.Math.max_float(0.0, e.abs -. 0.15)
    let b = e.stop +. 0.25
    switch Belt.Array.get(windows, Belt.Array.length(windows) - 1) {
    | Some((_, prevB)) if a -. prevB < 0.3 =>
      Belt.Array.setExn(
        windows,
        Belt.Array.length(windows) - 1,
        (fst(Belt.Array.getExn(windows, Belt.Array.length(windows) - 1)), b),
      )
    | _ => {
        let _ = Js.Array2.push(windows, (a, b))
      }
    }
  })
  let vexpr = if Belt.Array.length(windows) > 0 {
    "'if(" ++
    Js.Array2.joinWith(windows->Belt.Array.map(((a, b)) => "between(t," ++ f2(a) ++ "," ++ f2(b) ++ ")"), "+") ++
    ",0.22," ++
    f(scene.scoreVol) ++ ")'"
  } else {
    f(scene.scoreVol)
  }
  let fo = Js.Math.max_float(0.0, total -. 1.3)
  let score = dir ++ "/build/" ++ name ++ "_score.wav"
  ffmpeg([
    "-y", "-ss", f(scene.cueIn), "-i", dir ++ "/" ++ scene.cue,
    "-af",
    "aresample=44100,apad=whole_dur=" ++
    f(total) ++
    ",atrim=0:" ++
    f(total) ++
    ",volume=" ++
    vexpr ++
    ":eval=frame,afade=t=in:st=0:d=0.8,afade=t=out:st=" ++
    f2(fo) ++ ":d=1.3",
    "-ac", "2", "-ar", "44100", score,
  ])

  let mixed = dir ++ "/build/" ++ name ++ "_mix.wav"
  if Belt.Array.length(events) > 0 {
    ffmpeg([
      "-y", "-i", dlg, "-i", score,
      "-filter_complex", "amix=inputs=2:duration=longest:normalize=0,atrim=0:" ++ f(total),
      "-ac", "2", "-ar", "44100", mixed,
    ])
  } else {
    ffmpeg(["-y", "-i", score, "-c", "copy", mixed])
  }

  let outPath = dir ++ "/out/" ++ name ++ ".mp4"
  ffmpeg([
    "-y", "-i", picture, "-i", mixed,
    "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-ar", "44100", "-shortest", outPath,
  ])
  (outPath, total, Belt.Array.length(events), Belt.Array.length(clips))
}

/* ---- the episode --------------------------------------------------------- */

let assembleEpisode = (
  ~dir: string,
  ~edlFile: string,
  ~dursFile: string,
  ~outName: string,
  ~titleAfter: option<string>=?,
): unit => {
  /* PREFLIGHT IS NOT OPTIONAL. Every check it runs exists because that defect
     shipped or nearly shipped on a previous episode (stories/kuku/PRODUCTION_LESSONS.md).
     Assembling past a blocking failure is how an episode gets built on a missing
     asset, a reused close-up or a silent sound cue — each of which has cost a
     re-cut. PREFLIGHT_SKIP=1 exists only for deliberately assembling a partial cut
     while assets are still rendering, and it says so loudly. */
  let prefix = switch Js.String2.split(edlFile, "_") {
  | [p, _] => p
  | _ => ""
  }
  if prefix != "" {
    let r = run(~cmd="node", ~args=["src/Kuku_Preflight.res.mjs", dir, prefix])
    Js.log(r.stdout)
    if r.code != 0 {
      switch skipPreflight {
      | Some("1") =>
        Js.log(">>> PREFLIGHT FAILED, continuing because PREFLIGHT_SKIP=1. This cut is NOT publishable.")
      | _ =>
        raise(
          BackendError(
            "preflight failed — fix the blocking items above, or set PREFLIGHT_SKIP=1 to build a knowingly partial cut",
          ),
        )
      }
    }
  }

  let edl = Kuku_Edl.load(Path(dir ++ "/" ++ edlFile))
  let durs = Kuku_Edl.loadDurs(Path(dir ++ "/" ++ dursFile))
  ensureDirPath(Path(dir ++ "/build"))
  ensureDirPath(Path(dir ++ "/out"))

  let sceneFiles = []
  let report = []
  let skipped = []

  edl.scenes->Belt.Array.forEach(sc => {
    let miss = missingAssets(~dir, ~scene=sc, ~durs)
    if Belt.Array.length(miss) > 0 {
      let _ = Js.Array2.push(skipped, sc.name ++ ": missing " ++ Js.Array2.joinWith(miss, ", "))
    } else {
      let (file, total, nEvents, nSegs) = buildScene(~dir, ~scene=sc, ~durs)
      let _ = Js.Array2.push(sceneFiles, file)
      let _ = Js.Array2.push(
        report,
        sc.name ++
        ": " ++
        Js.Float.toFixedWithPrecision(total, ~digits=1) ++
        "s / " ++
        i2s(nEvents) ++
        " events / " ++
        i2s(nSegs) ++ " segs",
      )
    }
  })

  /* title and credits are shared with Ep2's build — copied verbatim, never
     re-muxed, so their duration cannot drift against the baseline */
  ["title24", "credits24"]->Belt.Array.forEach(nm => {
    let dst = Path(dir ++ "/out/" ++ nm ++ ".mp4")
    let src = Path(dir ++ "/../ep2prod/out/" ++ nm ++ ".mp4")
    if !exists(dst) && exists(src) {
      copyFile(src, dst)
    }
  })

  /* ~titleAfter names the scene AFTER which the title song plays — for an
     episode with a cold open, the title belongs after it, not before. Omitted,
     the title leads as before. */
  let sceneLines = sceneFiles->Belt.Array.map(s => {
    let parts = Js.String2.split(s, "/")
    "file '" ++ Belt.Array.getExn(parts, Belt.Array.length(parts) - 1) ++ "'"
  })
  let titleLine = "file 'title24.mp4'"
  let bodyLines = switch titleAfter {
  | Some(after) => {
      let out = []
      sceneFiles->Belt.Array.forEachWithIndex((i, s) => {
        let _ = Js.Array2.push(out, Belt.Array.getExn(sceneLines, i))
        if Js.String2.includes(s, "/" ++ after ++ ".mp4") {
          let _ = Js.Array2.push(out, titleLine)
        }
      })
      /* if the named scene was skipped (missing assets), the title must not
         silently vanish from the episode — fall back to title-first */
      if Js.Array2.includes(out, titleLine) {
        out
      } else {
        Belt.Array.concat([titleLine], sceneLines)
      }
    }
  | None => Belt.Array.concat([titleLine], sceneLines)
  }
  let lines = Belt.Array.concat(bodyLines, ["file 'credits24.mp4'"])
  let cat = dir ++ "/out/ep_cat.txt"
  writeText(Path(cat), Js.Array2.joinWith(lines, "\n") ++ "\n")
  let final = dir ++ "/out/" ++ outName
  ffmpeg(["-y", "-f", "concat", "-safe", "0", "-i", cat, "-c", "copy", final])

  /* THE REVIEW CUT — author's rule: an approval cut never carries the title or
     credits; he should not sit through the intro to review the episode. Emitted on
     every build so the publishable file and the reviewable file always both exist,
     and the review one is what gets shared for approval. */
  let reviewCat = dir ++ "/out/ep_review_cat.txt"
  writeText(
    Path(reviewCat),
    Js.Array2.joinWith(
      sceneFiles->Belt.Array.map(sf => {
        let parts = Js.String2.split(sf, "/")
        "file '" ++ Belt.Array.getExn(parts, Belt.Array.length(parts) - 1) ++ "'"
      }),
      "\n",
    ) ++ "\n",
  )
  let review = dir ++ "/out/" ++ Js.String2.replace(outName, ".mp4", "_REVIEW.mp4")
  ffmpeg(["-y", "-f", "concat", "-safe", "0", "-i", reviewCat, "-c", "copy", review])

  report->Belt.Array.forEach(r => Js.log(r))
  skipped->Belt.Array.forEach(s => Js.log("SKIPPED " ++ s))
  let Seconds(d) = probeDuration(Path(final))
  Js.log("EPISODE: " ++ Js.Float.toFixedWithPrecision(d, ~digits=1) ++ "s -> " ++ final)
  let Seconds(rd) = probeDuration(Path(review))
  Js.log("REVIEW:  " ++ Js.Float.toFixedWithPrecision(rd, ~digits=1) ++ "s -> " ++ review ++ "  (no title/credits — share THIS for approval)")
}
