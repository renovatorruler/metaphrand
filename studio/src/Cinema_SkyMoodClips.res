/* Animate the plane-montage stills with Sora 2 Pro. Cached per clip (skip ones
   already rendered), so I can add angles and re-run without re-paying. Starting
   with the side-tracking shot to read the real Replicate cost. */
open Cinema_Backends

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"

/* (frame basename, motion prompt) — quiet ambient only; our music goes under. */
let clips = [
  (
    "mood_plane4",
    "Smooth slow cinematic side-tracking shot: the twin-engine turboprop airliner glides level " ++
    "through the calm golden sunset, the camera tracking smoothly alongside it, the low sun flaring " ++
    "softly behind, clouds drifting past below, the propeller turning. Very smooth and serene, no " ++
    "fast moves, no cuts, no camera shake. Quiet ambient air and a faint engine hum only — no " ++
    "music, no voices, no narration.",
  ),
]

let rec run = async i =>
  if i >= Belt.Array.length(clips) {
    ()
  } else {
    let (name, motion) = Belt.Array.getExn(clips, i)
    let out = Path(dir ++ "/clips/" ++ name ++ "_sora.mp4")
    if !exists(out) {
      let b = await videoSora(~image=Path(dir ++ "/frames/" ++ name ++ "_gpt2.png"), ~prompt=Prompt(motion), ~seconds=8, ~hi=true)
      let _ = writeBytes(out, b)
      Js.log("clip " ++ name ++ " -> clips/" ++ name ++ "_sora.mp4  (" ++ Js.Float.toString(fileSizeMb(out)) ++ " MB)")
    } else {
      Js.log("clip " ++ name ++ " cached")
    }
    await run(i + 1)
  }

let main = async () => await run(0)
main()->ignore
