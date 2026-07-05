/* First Sora 2 Pro clip: animate the plane mood-set still. The gpt-image-2 frame
   is the first frame; prompt drives smooth gliding motion + quiet ambient only
   (our music goes under it in post). Landscape, 1080p, 8s. */
open Cinema_Backends

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"

let main = async () => {
  let frame = Path(dir ++ "/frames/mood_plane_gpt2.png")
  let out = Path(dir ++ "/clips/mood_plane_sora.mp4")
  let prompt = Prompt(
    "Smooth slow cinematic aerial shot: the twin-engine turboprop airliner glides steadily " ++
    "through the calm golden sunset sky, gentle parallax as the camera tracks alongside, the " ++
    "propellers turning, soft clouds drifting far below. Very smooth and serene, no fast moves, " ++
    "no cuts, no camera shake. Quiet ambient air and a faint distant engine hum only — no music, " ++
    "no voices, no narration.",
  )
  let started = Js.Date.now()
  let b = await videoSora(~image=frame, ~prompt, ~seconds=8, ~hi=true)
  let _ = writeBytes(out, b)
  let secs = (Js.Date.now() -. started) /. 1000.0
  Js.log(
    "SORA CLIP -> " ++
    dir ++
    "/clips/mood_plane_sora.mp4  (" ++
    Js.Float.toString(fileSizeMb(out)) ++
    " MB, rendered in " ++
    Js.Float.toFixedWithPrecision(secs, ~digits=0) ++ "s)",
  )
}

main()->ignore
