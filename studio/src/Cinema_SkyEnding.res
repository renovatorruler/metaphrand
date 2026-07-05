/* The cinematic ENDING/title section (standalone, for approval):
   Birdy's last line over the cockpit -> on the closing action line, CUT to the
   exterior plane -> the SAME background bed RISES smoothly over ~3s (no cut, a
   real swell) -> "SKY KING" (thin letter-spaced Didot) fades in dead center ->
   holds. Reuses the cached voice takes + the existing track + plane clip. */
open Cinema_Backends

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"
let tmp = dir ++ "/cold_open_rs"
let cache = tmp ++ "/cache"
let tyler = VoiceId("raMcNf2S8wCmuaBcyI6E")
let brian = VoiceId("nPczCjzI2devNBz1zQrb")

let key = (VoiceId(v), txt) => {
  let san = (v ++ "_" ++ txt)->Js.String2.replaceByRe(%re("/[^A-Za-z0-9]/g"), "")
  Js.String2.slice(san, ~from=0, ~to_=40) ++ "_" ++ Belt.Int.toString(Js.String2.length(txt))
}
let take = async (voice, txt) => {
  let p = Path(cache ++ "/" ++ key(voice, txt) ++ ".mp3")
  if !exists(p) {
    let b = await tts(~text=Text(txt), ~voice)
    let _ = writeBytes(p, b)
  }
  p
}

let birdyLine = "I don't think I can do that yet. I'm sorry. I'm just not ready to put it down."
let narrLine = "The Q400 holds its slow turn into the last of the sun, the two jets riding its wings as the gold thins to a long red line on the horizon."

let f = x => Js.Float.toFixedWithPrecision(x, ~digits=2)
let ms = x => Belt.Int.toString(Belt.Float.toInt(x *. 1000.))

let main = async () => {
  let bp = await take(tyler, birdyLine)
  let np = await take(brian, narrLine)
  let Seconds(bd) = durationSec(bp)
  let Seconds(nd) = durationSec(np)
  let Path(bps) = bp
  let Path(nps) = np
  let Seconds(clip) = durationSec(Path(dir ++ "/clips/mood_plane4_sora.mp4"))

  let lead = 0.6
  let gap = 0.7
  let birdyEnd = lead +. bd
  let narrStart = birdyEnd +. gap
  let narrEnd = narrStart +. nd
  let swellStart = narrEnd +. 0.4
  let swellEnd = swellStart +. 3.0 /* the ~3s rise */
  let fadeOut = 2.8
  let total = swellEnd +. 6.5 +. fadeOut /* hold the title ~6.5s, then a graceful fade */
  let cutToExt = birdyEnd +. 0.3 /* cut to exterior just after the line */
  let extDur = total -. cutToExt
  let titleInLocal = swellStart +. 0.3 -. cutToExt
  let glideDur = clip *. 1.4 /* gentle slow, then FREEZE the last frame for the hold */
  let freezeDur = extDur -. glideDur

  /* 1. AUDIO — voices placed; the bed sits low then RISES smoothly over 3s */
  let endAudio = tmp ++ "/ending_audio.mp3"
  let vol =
    "if(lt(t," ++
    f(swellStart) ++
    "),0.26,if(lt(t," ++
    f(swellEnd) ++
    "),0.26+(t-" ++
    f(swellStart) ++ ")*0.213,0.9))"
  ffmpeg([
    "-nostdin", "-loglevel", "error", "-y",
    "-i", bps, "-i", nps, "-ss", "68", "-t", f(total), "-i", tmp ++ "/music_outro.mp3",
    "-filter_complex",
    "[0:a]adelay=" ++ ms(lead) ++ "|" ++ ms(lead) ++ "[b];" ++
    "[1:a]adelay=" ++ ms(narrStart) ++ "|" ++ ms(narrStart) ++ "[n];" ++
    "[2:a]volume='" ++ vol ++ "':eval=frame[m];" ++
    "[b][n][m]amix=inputs=3:duration=longest:normalize=0,alimiter=limit=0.97,afade=t=out:st=" ++ f(total -. fadeOut) ++ ":d=" ++ f(fadeOut) ++ "[a]",
    "-map", "[a]", "-codec:a", "libmp3lame", "-b:a", "160k", endAudio,
  ])

  /* 2. seg1 — cockpit (Birdy's last line) */
  let seg1 = tmp ++ "/seg1.mp4"
  ffmpeg([
    "-nostdin", "-loglevel", "error", "-y", "-loop", "1", "-t", f(cutToExt),
    "-i", dir ++ "/frames/cockpit_birdy_profile.png",
    "-vf", "scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,setsar=1,format=yuv420p,fps=24",
    "-r", "24", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-an", seg1,
  ])

  /* 3. seg2 — exterior plane (slowed, dreamy) + the title fading in center */
  let seg2 = tmp ++ "/seg2.mp4"
  ffmpeg([
    "-nostdin", "-loglevel", "error", "-y",
    "-i", dir ++ "/clips/mood_plane4_sora.mp4", "-loop", "1", "-i", dir ++ "/frames/title_didot.png",
    "-filter_complex",
    "[0:v]setpts=1.4*PTS,scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,setsar=1,format=yuv420p,fps=24,tpad=stop_mode=clone:stop_duration=" ++ f(freezeDur) ++ "[ext];" ++
    "[1:v]format=rgba,split[w][s];" ++
    "[s]colorchannelmixer=rr=0:gg=0:bb=0:aa=0.5,fade=t=in:st=" ++ f(titleInLocal) ++ ":d=1.6:alpha=1[shadow];" ++
    "[w]fade=t=in:st=" ++ f(titleInLocal) ++ ":d=1.6:alpha=1[white];" ++
    "[ext][shadow]overlay=(W-w)/2+3:(H-h)/2+3[e1];" ++
    "[e1][white]overlay=(W-w)/2:(H-h)/2,trim=0:" ++ f(extDur) ++ ",fade=t=out:st=" ++ f(extDur -. fadeOut) ++ ":d=" ++ f(fadeOut) ++ "[v]",
    "-map", "[v]", "-t", f(extDur), "-r", "24", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-an", seg2,
  ])

  /* 4. concat + mux the audio */
  let out = dir ++ "/SKY-KING_ending.mp4"
  ffmpeg([
    "-nostdin", "-loglevel", "error", "-y", "-i", seg1, "-i", seg2, "-i", endAudio,
    "-filter_complex", "[0:v][1:v]concat=n=2:v=1:a=0[v]",
    "-map", "[v]", "-map", "2:a", "-r", "24", "-c:v", "libx264", "-pix_fmt", "yuv420p",
    "-c:a", "aac", "-b:a", "160k", "-shortest", out,
  ])
  Js.log("ENDING -> " ++ out ++ "  (" ++ Js.Float.toString(fileSizeMb(Path(out))) ++ " MB, " ++ f(total) ++ "s)")
}

main()->ignore
