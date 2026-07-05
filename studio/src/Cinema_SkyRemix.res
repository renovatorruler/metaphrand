/* SKY KING cold open — MUSIC SWAP. The first bed went cheerful/percussive; the
   user wants the M83 "Outro" register: a slow soaring emotional swell, no drums.
   Generate that bed via the ReScript Music endpoint and re-mix the ALREADY
   rendered voice body (no re-TTS). Output a fresh scored preview. */
open Cinema_Backends

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"
let tmp = dir ++ "/cold_open_rs"

let main = async () => {
  /* 1. emotional ambient bed — cached, so we only pay once while iterating. */
  let bed = Path(tmp ++ "/music_outro.mp3")
  if !exists(bed) {
    let prompt = Prompt(
      "Slow-building cinematic instrumental, deeply emotional, dreamy and widescreen. " ++
      "Sustained layered synthesizer pads and warm strings swell gradually to a luminous, " ++
      "bittersweet, triumphant-yet-melancholic peak, then settle. A soft analog synth melody " ++
      "floats on top. Hopeful ache, nostalgic, cinematic. ABSOLUTELY NO drums, no percussion, " ++
      "no beat, no claps, no rhythm section — only sustained pads, strings and synth. " ++
      "Like the emotional end-credits swell of a modern indie science-fiction film.",
    )
    let b = await music(~prompt, ~ms=Millis(130000), ~instrumental=true)
    let _ = writeBytes(bed, b)
    Js.log("bed generated")
  } else {
    Js.log("bed cached")
  }

  /* 2. pad the existing voice body: 6s to open on the sky, 8s tail for the swell. */
  let body = tmp ++ "/body.mp3"
  let padded = tmp ++ "/padded3.mp3"
  ffmpeg([
    "-nostdin", "-loglevel", "error", "-y", "-i", body,
    "-af", "adelay=6000:all=1,apad=pad_dur=8", "-codec:a", "libmp3lame", "-b:a", "160k", padded,
  ])

  /* 3. mix. Floor a touch higher than before (the bed now carries the emotion),
     bigger swell into the cut. */
  let Seconds(total) = durationSec(Path(padded))
  let os = Js.Float.toFixedWithPrecision(total -. 10.0, ~digits=2)
  let vol =
    "if(lt(t,6),0.80,if(lt(t,9),0.80-(t-6)*0.1867,if(lt(t," ++
    os ++ "),0.24,0.24+(t-" ++ os ++ ")*0.034)))"
  let Path(bedp) = bed
  let scored = dir ++ "/cold_open_v2_narrated_outro.mp3"
  ffmpeg([
    "-nostdin", "-loglevel", "error", "-y", "-i", padded, "-i", bedp,
    "-filter_complex",
    "[1:a]aresample=44100,volume='" ++ vol ++ "':eval=frame[m];[0:a][m]amix=inputs=2:duration=first:normalize=0[mix]",
    "-map", "[mix]", "-codec:a", "libmp3lame", "-b:a", "160k", scored,
  ])
  Js.log("NARRATED COLD OPEN (outro bed) -> " ++ scored ++ "  (" ++ Js.Float.toString(total) ++ "s)")
}

main()->ignore
