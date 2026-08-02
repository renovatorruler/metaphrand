/* कुकु और अक्षर — the build guards, ported from ep5prod/verify_picture.py plus a
   new duration-parity check against a recorded baseline.

   PICTURE: every still segment must actually show the still the EDL names. This
   caught a 93-segment rewire that reported success and changed nothing on screen,
   and before that an intact bridge in eleven shots after the bridge collapsed.
   Similarity is ffmpeg's own SSIM against the source image rather than a
   hand-rolled hash — a matching pair scores ~0.99, a wrong picture far lower.

   DURATIONS: after a port or a refactor, every scene and segment must still be
   exactly as long as the recorded baseline. A cut that drifts by a frame per
   segment is invisible in review and ruins the lip sync. */

open Cinema_Backends

exception Failed(string)

/* SSIM prints "SSIM Y:0.995589 (23.55) All:0.995589 (23.55)" on stderr. Both
   inputs are flattened to the same size and to grey first, so the score reflects
   content rather than scaling or colour. */
/* THE STILL MUST GO THROUGH THE SAME RECIPE AS THE RENDER — this check has produced
   144 false failures once already, by comparing a built frame against the FULL still
   when the render was showing a cropped window of it.

   Recipe r3: stills no longer move. The render is a centred 1280x720 crop of the
   image scaled to cover, so that is exactly what the reference goes through here.
   If the render's recipe changes again, THIS MUST CHANGE WITH IT. */
let ssim = (~video: string, ~image: string): option<float> => {
  let r = run(
    ~cmd="ffmpeg",
    ~args=[
      "-v", "info", "-i", video, "-i", image, "-frames:v", "1",
      "-lavfi",
      "[0:v]scale=320:180,format=gray[a];" ++
      "[1:v]scale=1280:720:force_original_aspect_ratio=increase,crop=1280:720," ++
      "scale=320:180,format=gray[b];[a][b]ssim",
      "-f", "null", "-",
    ],
  )
  let marker = "All:"
  switch Js.String2.lastIndexOf(r.stderr, marker) {
  | -1 => None
  | i => {
      let rest = Js.String2.sliceToEnd(r.stderr, ~from=i + Js.String2.length(marker))
      let head = Js.String2.trim(Belt.Array.getExn(Js.String2.split(rest, " "), 0))
      Belt.Float.fromString(head)
    }
  }
}

/* Mean luma and chroma of a frame, via ffmpeg's signalstats (printed as text, so
   no binary round-trip). Used for the lip-sync check below. */
let firstFloatAfter = (hay: string, key: string): option<float> =>
  switch Js.String2.indexOf(hay, key) {
  | -1 => None
  | i => {
      let rest = Js.String2.sliceToEnd(hay, ~from=i + Js.String2.length(key))
      Belt.Float.fromString(Js.String2.trim(Belt.Array.getExn(Js.String2.split(rest, "\n"), 0)))
    }
  }

let colorStats = (file: string): option<(float, float, float)> => {
  let r = run(
    ~cmd="ffmpeg",
    ~args=[
      "-v", "error", "-i", file,
      "-vf", "scale=64:64,signalstats,metadata=mode=print:file=-",
      "-frames:v", "1", "-f", "null", "-",
    ],
  )
  switch (
    firstFloatAfter(r.stdout, "lavfi.signalstats.YAVG="),
    firstFloatAfter(r.stdout, "lavfi.signalstats.UAVG="),
    firstFloatAfter(r.stdout, "lavfi.signalstats.VAVG="),
  ) {
  | (Some(y), Some(u), Some(v)) => Some((y, u, v))
  | _ => None
  }
}

/* OmniHuman REFRAMES the shot it is given — the returned clip is a tighter crop of
   the still, so SSIM against the source scores ~0.45 even when the character is
   correct. SSIM is therefore the wrong test for a lip-synced segment. What still
   must hold is IDENTITY: this cast is strongly colour-coded (green कुकु, red
   फ्यूरिया, blue वैस्पर, grey दादी, brown मिटासुर), so mean luma+chroma separates
   them cleanly and is invariant to reframing. Measured on the real assets: the
   correct still differs by 1.3, the nearest wrong character by 15, the furthest
   by 62. */
let charThreshold = 8.0

let charDistance = (~video: string, ~image: string): option<float> =>
  switch (colorStats(video), colorStats(image)) {
  | (Some((y1, u1, v1)), Some((y2, u2, v2))) =>
    Some(
      Js.Math.max_float(
        Js.Math.abs_float(y1 -. y2),
        Js.Math.max_float(Js.Math.abs_float(u1 -. u2), Js.Math.abs_float(v1 -. v2)),
      ),
    )
  | _ => None
  }

let pad2 = (i: int): string => i < 10 ? "0" ++ Belt.Int.toString(i) : Belt.Int.toString(i)

/* A still segment (or a lip-synced clip generated FROM a still) must resemble its
   source. 0.90 is far above what a wrong picture scores and far below what a
   push-in costs. */
let threshold = 0.90

let checkPicture = (~dir: string, ~edlFile: string): int => {
  let edl = Kuku_Edl.load(Path(dir ++ "/" ++ edlFile))
  let bad = []
  let checked = ref(0)
  let skipped = ref(0)

  edl.scenes->Belt.Array.forEach(sc =>
    sc.segments->Belt.Array.forEachWithIndex((gi, seg) => {
      /* a lip-synced clip carries the still it was generated from */
      let (expect, isLip) = switch (seg.src, seg.stillWas) {
      | (File(_), Some(w)) => (Some(w), true)
      | (Still(n), _) => (Some(n), false)
      | _ => (None, false)
      }
      switch expect {
      | None => ()
      | Some(name) => {
          let png = dir ++ "/stills/" ++ name ++ ".png"
          let vid = dir ++ "/build/" ++ sc.name ++ "_" ++ pad2(gi) ++ ".mp4"
          if !exists(Path(png)) || !exists(Path(vid)) {
            skipped := skipped.contents + 1
          } else if isLip {
            /* reframed by the generator — check identity, not framing */
            switch charDistance(~video=vid, ~image=png) {
            | None => skipped := skipped.contents + 1
            | Some(d) => {
                checked := checked.contents + 1
                if d > charThreshold {
                  let _ = Js.Array2.push(
                    bad,
                    "  " ++
                    sc.name ++
                    " seg" ++
                    Belt.Int.toString(gi) ++
                    " (lip) expected " ++
                    name ++
                    "  colour-distance=" ++
                    Js.Float.toFixedWithPrecision(d, ~digits=1),
                  )
                }
              }
            }
          } else {
            switch ssim(~video=vid, ~image=png) {
            | None => skipped := skipped.contents + 1
            | Some(s) => {
                checked := checked.contents + 1
                if s < threshold {
                  let _ = Js.Array2.push(
                    bad,
                    "  " ++
                    sc.name ++
                    " seg" ++
                    Belt.Int.toString(gi) ++
                    " expected " ++
                    name ++
                    "  ssim=" ++
                    Js.Float.toFixedWithPrecision(s, ~digits=3),
                  )
                }
              }
            }
          }
        }
      }
    })
  )

  Js.log(
    "picture: checked " ++
    Belt.Int.toString(checked.contents) ++
    " still segments, " ++
    Belt.Int.toString(skipped.contents) ++ " skipped",
  )
  if Belt.Array.length(bad) > 0 {
    Js.log("\nPICTURE MISMATCH — built segment does not match the still the EDL names:")
    bad->Belt.Array.forEach(b => Js.log(b))
  } else {
    Js.log("picture: OK — every still segment shows the image the EDL names.")
  }
  Belt.Array.length(bad)
}

/* ---- duration parity ------------------------------------------------------
   baseline/durations.txt is "<name>.mp4 <seconds>" per line, recorded from a
   build that was reviewed and published. */
let checkDurations = (~dir: string, ~tolerance: float): int => {
  let baseline = Path(dir ++ "/baseline/durations.txt")
  if !exists(baseline) {
    Js.log("durations: no baseline recorded — skipping")
    0
  } else {
    let bad = []
    let checked = ref(0)
    let missing = ref(0)
    Js.String2.split(readText(baseline), "\n")->Belt.Array.forEach(line => {
      let parts = Js.String2.split(Js.String2.trim(line), " ")
      switch (Belt.Array.get(parts, 0), Belt.Array.get(parts, 1)) {
      | (Some(name), Some(want)) if name != "" =>
        switch Belt.Float.fromString(want) {
        | None => ()
        | Some(wantF) => {
            /* scene and episode files live in out/, segments in build/ */
            let inOut = Path(dir ++ "/out/" ++ name)
            let inBuild = Path(dir ++ "/build/" ++ name)
            let p = exists(inOut) ? Some(inOut) : exists(inBuild) ? Some(inBuild) : None
            switch p {
            | None => missing := missing.contents + 1
            | Some(path) => {
                let Seconds(got) = probeDuration(path)
                checked := checked.contents + 1
                if Js.Math.abs_float(got -. wantF) > tolerance {
                  let _ = Js.Array2.push(
                    bad,
                    "  " ++
                    name ++
                    ": baseline " ++
                    Js.Float.toFixedWithPrecision(wantF, ~digits=6) ++
                    "s, built " ++
                    Js.Float.toFixedWithPrecision(got, ~digits=6) ++ "s",
                  )
                }
              }
            }
          }
        }
      | _ => ()
      }
    })
    Js.log(
      "durations: checked " ++
      Belt.Int.toString(checked.contents) ++
      " files, " ++
      Belt.Int.toString(missing.contents) ++ " absent",
    )
    if Belt.Array.length(bad) > 0 {
      Js.log("\nDURATION DRIFT from the recorded baseline:")
      bad->Belt.Array.forEach(b => Js.log(b))
    } else {
      Js.log("durations: OK — every file matches the baseline.")
    }
    Belt.Array.length(bad)
  }
}
