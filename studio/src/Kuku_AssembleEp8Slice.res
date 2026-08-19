/* कुकु और अक्षर — Ep8 «च से चील», full-episode assembly.
   Run from studio/:  node src/Kuku_AssembleEp8Slice.res.mjs

   EP8's title track is a J-CUT (author's note, 2026-08-10): the title music
   starts while the «च से चील» episode card is still on screen, then the title
   visuals come in already in progress. Audio is NOT shifted — the first 3.4s
   of the title VIDEO are replaced by the card, so picture joins the song at
   3.4s exactly in sync. The card therefore lives here, not in the cold-open
   EDL. Built fresh on every run over the verbatim ep2prod title. */
open Cinema_Backends

@val @scope("process") external exit: int => unit = "exit"

let dir = "../stories/kuku/ep8prod"
let cardHold = 3.4

let buildJcutTitle = () => {
  let src = dir ++ "/../ep2prod/out/title24.mp4"
  if !exists(Path(src)) {
    raise(BackendError("missing shared title track: " ++ src))
  }
  ensureDirPath(Path(dir ++ "/out"))
  let f = v => Js.Float.toFixedWithPrecision(v, ~digits=2)
  /* one pass: [0] card png, [1] letter glyph, [2] the shared title track.
     Card picture (with the च glyph fading in at 0.4s, top-centre, as the EDL
     rendered it) fills 0..3.4s; the title video is trimmed to start at 3.4s;
     the title AUDIO plays whole and unshifted from 0. Encode matches the
     scene segments: 1280x720 / 24fps / yuv420p / crf18 / aac 44.1k stereo. */
  ffmpeg([
    "-y",
    "-loop", "1", "-framerate", "24", "-t", f(cardHold), "-i", dir ++ "/cards/c1.png",
    "-loop", "1", "-framerate", "24", "-t", f(cardHold), "-i", dir ++ "/glyphs/fx_cha.png",
    "-i", src,
    "-filter_complex",
    "[0:v]scale=1280:720,fps=24[card];" ++
    "[1:v]format=rgba,scale=435:-1,fade=t=in:st=0.4:d=0.5:alpha=1[g];" ++
    "[card][g]overlay=(W-w)/2:H*0.08:shortest=1[cardg];" ++
    "[2:v]trim=start=" ++ f(cardHold) ++ ",setpts=PTS-STARTPTS,scale=1280:720,fps=24[tv];" ++
    "[cardg][tv]concat=n=2:v=1:a=0,format=yuv420p[v]",
    "-map", "[v]", "-map", "2:a",
    "-c:v", "libx264", "-crf", "18",
    "-c:a", "aac", "-b:a", "192k", "-ar", "44100", "-ac", "2",
    dir ++ "/out/title24.mp4",
  ])
  Js.log("title24 (EP8 J-cut) rebuilt: music from the «च से चील» card, picture joins at " ++ f(cardHold) ++ "s")
}

let main = () => {
  switch {
    buildJcutTitle()
    Kuku_Assemble.assembleEpisode(
      ~dir,
      ~edlFile="ep8_edl.json",
      ~dursFile="ep8_durs.json",
      ~outName="KUKU_EP8_V5.mp4",
      ~titleAfter="s0_cold",
    )
  } {
  | () => ()
  | exception Cinema_Backends.BackendError(m) => {
      Js.log("\nASSEMBLY FAILED\n" ++ m)
      exit(1)
    }
  | exception Kuku_Edl.EdlError(m) => {
      Js.log("\nEDL ERROR\n" ++ m)
      exit(1)
    }
  }
}

main()
