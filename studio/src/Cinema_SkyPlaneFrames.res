/* More plane-flying angles for the opening montage, conditioned on the approved
   plane still so it's the SAME Q400 and the same sunset palette. gpt-image-2. */
open Cinema_Backends

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"
let planeRef = Path(dir ++ "/frames/mood_plane_gpt2.png")

let shots = [
  (
    "mood_plane2",
    "Photoreal film still, Kodak Portra 400, naturalistic true color. Low angle looking up at the " ++
    "same twin-engine Bombardier Q400 turboprop airliner with no airline markings as it banks " ++
    "across a glowing gold and soft-pink sunset sky, the underside of the fuselage and wings " ++
    "catching warm light, propellers turning, a few soft clouds. Cinematic, serene. Same aircraft " ++
    "and sunset palette as the reference. NOT teal and orange, no halation.",
  ),
  (
    "mood_plane3",
    "Photoreal film still, Kodak Portra 400, naturalistic true color. An immense calm sunset sky " ++
    "over distant water and islands, the same small twin-engine Q400 turboprop airliner flying " ++
    "alone, tiny and far off-center against the vastness. Lonely, serene, epic scale, soft golden " ++
    "light. Same aircraft and palette as the reference. NOT teal and orange, no halation.",
  ),
  (
    "mood_plane4",
    "Photoreal film still, Kodak Portra 400, naturalistic true color. A closer side-on tracking " ++
    "view of the same twin-engine Q400 turboprop airliner gliding level through calm sunset air, a " ++
    "warm low sun flaring softly behind it, the fuselage and propeller catching gold light, soft " ++
    "clouds drifting past. Intimate, smooth, cinematic. Same aircraft and palette as the " ++
    "reference. NOT teal and orange, no halation.",
  ),
]

let rec run = async i =>
  if i >= Belt.Array.length(shots) {
    ()
  } else {
    let (name, prompt) = Belt.Array.getExn(shots, i)
    let out = Path(dir ++ "/frames/" ++ name ++ "_gpt2.png")
    let b = await imageGpt2(~prompt=Prompt(prompt), ~refs=[planeRef])
    let _ = writeBytes(out, b)
    Js.log(name ++ " -> frames/" ++ name ++ "_gpt2.png  (" ++ Js.Float.toString(fileSizeMb(out)) ++ " MB)")
    await run(i + 1)
  }

let main = async () => await run(0)
main()->ignore
