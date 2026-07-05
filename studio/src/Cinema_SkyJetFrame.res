/* The jet-reveal frame: the Q400 with two fighter escorts at sunset — the cold
   open's dramatic turn. gpt-image-2, conditioned on the plane shot. */
open Cinema_Backends

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"

let main = async () => {
  let out = Path(dir ++ "/frames/jet_reveal.png")
  let prompt = Prompt(
    "Photoreal film still, Kodak Portra 400, naturalistic true color. The same twin-engine " ++
    "Bombardier Q400 turboprop airliner with no airline markings flying through a calm golden " ++
    "sunset sky, with two grey F-15 fighter jets in close escort formation alongside it, one off " ++
    "each wing, holding station close to the airliner. Wide cinematic angle, soft sunset light, " ++
    "gentle film grain, documentary realism. Same aircraft and sunset palette as the reference. " ++
    "NOT teal and orange, no halation.",
  )
  let b = await imageGpt2(~prompt, ~refs=[Path(dir ++ "/frames/mood_plane_gpt2.png")])
  let _ = writeBytes(out, b)
  Js.log("jet_reveal -> frames/jet_reveal.png  (" ++ Js.Float.toString(fileSizeMb(out)) ++ " MB)")
}

main()->ignore
