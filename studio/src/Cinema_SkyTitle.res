/* Title sequence: the side-tracking plane clip (slowed, dreamy) with the
   pre-rendered "SKY KING" PNG (Futura, pango-view) overlaid with a soft drop
   shadow and a fade-in; the built-up part of the SAME track replayed so the
   music swells; held ~9s, clean fade; crossfaded onto the end of the cold open.
   ffmpeg here has no drawtext, so the title is an overlay PNG. */
open Cinema_Backends

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"

let main = async () => {
  let titleSeq = dir ++ "/clips/title_seq.mp4"

  /* 1. title sequence (~9.6s): plane slowed + SKY KING overlay + built-up music */
  ffmpeg([
    "-nostdin", "-loglevel", "error", "-y",
    "-i", dir ++ "/clips/mood_plane4_sora.mp4", // [0]
    "-loop", "1", "-i", dir ++ "/frames/title_text.png", // [1]
    "-ss", "79", "-t", "9.6", "-i", dir ++ "/cold_open_rs/music_outro.mp3", // [2]
    "-filter_complex",
    "[0:v]setpts=1.17*PTS,scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,setsar=1[bg];" ++
    "[1:v]format=rgba,split[w][s];" ++
    "[s]colorchannelmixer=rr=0:gg=0:bb=0:aa=0.6,fade=t=in:st=1:d=1.4:alpha=1[shadow];" ++
    "[w]fade=t=in:st=1:d=1.4:alpha=1[white];" ++
    "[bg][shadow]overlay=(W-w)/2+4:(H*0.70-h/2)+4[t1];" ++
    "[t1][white]overlay=(W-w)/2:(H*0.70-h/2),format=yuv420p,fade=t=out:st=9.1:d=0.5[v];" ++
    "[2:a]afade=t=in:st=0:d=0.6,afade=t=out:st=8.8:d=0.8[a]",
    "-map", "[v]", "-map", "[a]", "-t", "9.6", "-r", "24", "-c:v", "libx264", "-pix_fmt", "yuv420p",
    "-c:a", "aac", "-b:a", "160k", titleSeq,
  ])

  /* 2. crossfade onto the end of the cold open */
  let Seconds(coDur) = durationSec(Path(dir ++ "/SKY-KING_coldopen.mp4"))
  let off = Js.Float.toFixedWithPrecision(coDur -. 0.8, ~digits=2)
  let out = dir ++ "/SKY-KING_coldopen_titled.mp4"
  ffmpeg([
    "-nostdin", "-loglevel", "error", "-y",
    "-i", dir ++ "/SKY-KING_coldopen.mp4", "-i", titleSeq,
    "-filter_complex",
    "[0:v][1:v]xfade=transition=fade:duration=0.8:offset=" ++ off ++ "[v];[0:a][1:a]acrossfade=d=0.8[a]",
    "-map", "[v]", "-map", "[a]", "-r", "24", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-c:a", "aac",
    "-b:a", "160k", out,
  ])
  Js.log("TITLED COLD OPEN -> " ++ out ++ "  (" ++ Js.Float.toString(fileSizeMb(Path(out))) ++ " MB)")
}

main()->ignore
