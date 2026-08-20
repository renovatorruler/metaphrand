/* EP9 outro: the episode ends on Rishi's deliberately cut-off "तुम्हारा पहला अभ्यास—", and
   the parent asked to see it land as an ending ("if it's supposed to end there, let's add
   the outro track"). This builds a 14s outro segment: the night-valley end card with a
   music_v2 instrumental sting, encoded to exactly the review proxy's format so the rebuild
   driver can concat it straight onto the proxy.

   Run from studio/:  node src/Kuku_Ep9Outro.res.mjs */

open Cinema_Backends

@val @scope("process") external exitProcess: int => unit = "exit"

let finale = "../stories/kuku/ep9prod/finale"
let mp3 = finale ++ "/audio/EP9_OUTRO_STING_V1.mp3"
let card = finale ++ "/references/gpt_paper/ST_endcard.png"
let out = finale ++ "/local/fx/EP9_OUTRO_SEGMENT_540P_V1.mp4"

let main = async () => {
  if !(exists(Path(mp3)) && fileSizeMb(Path(mp3)) *. 1.0e6 > 20000.0) {
    let blob = await music(
      ~prompt=Prompt(
        "Gentle end-credits outro for a warm Indian children's animated show: soft bansuri " ++
        "flute melody over sparse santoor and light tabla, a music-box quality, resolving " ++
        "peacefully like a lullaby's last line, hopeful final note that fades to quiet",
      ),
      ~ms=Millis(14000),
      ~instrumental=true,
    )
    let _ = writeBytes(Path(mp3), blob)
    Js.log("outro sting generated (music_v2)")
  } else {
    Js.log("outro sting cached")
  }
  if !exists(Path(card)) {
    Js.Console.error("end card still is not downloaded yet: " ++ card)
    exitProcess(1)
  }
  /* match the review proxy exactly: 960x540, h264, yuv420p, 24fps, aac 128k 48kHz stereo */
  ffmpeg([
    "-nostdin", "-v", "error", "-y",
    "-loop", "1", "-framerate", "24", "-t", "14", "-i", card,
    "-i", mp3,
    "-filter_complex",
    "[0:v]scale=960:540:force_original_aspect_ratio=increase,crop=960:540,setsar=1," ++
    "fade=t=in:st=0:d=1,fade=t=out:st=12.5:d=1.5[v];" ++
    "[1:a]aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo," ++
    "afade=t=out:st=12:d=2[a]",
    "-map", "[v]", "-map", "[a]",
    "-c:v", "libx264", "-preset", "veryfast", "-crf", "27", "-pix_fmt", "yuv420p",
    "-r", "24", "-c:a", "aac", "-b:a", "128k", "-ar", "48000", "-ac", "2",
    "-t", "14", "-movflags", "+faststart", out,
  ])
  let Seconds(d) = probeDuration(Path(out))
  Js.log("outro segment: " ++ out ++ " (" ++ Js.Float.toFixedWithPrecision(d, ~digits=1) ++ "s)")
}

main()
->Js.Promise2.catch(e => {
  Js.log2("OUTRO FAILED:", e)
  exitProcess(1)
  Js.Promise.resolve()
})
->ignore
