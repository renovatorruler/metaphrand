/* SKY KING cold open — the wordless MOOD-SET establishing frames (~40s opening).
   No characters; neutral Portra realism (the approved look), the authentic Q400,
   NOT the rejected teal-orange. Stills first; animate only after the look is OK. */
open Cinema_Backends

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"

let shots = [
  (
    "mood_plane",
    "Photoreal film still, Kodak Portra 400, naturalistic true color, neutral white balance. " ++
    "A twin-engine Bombardier Dash 8 Q400 turboprop airliner with no airline markings, banking " ++
    "slowly high in a calm evening sky going soft orange and gold at sunset, the twin propellers " ++
    "catching the last light. Seen wide from a little above and behind. Soft natural light, gentle " ++
    "film grain, documentary realism. NOT teal and orange grade, no halation glow, no CGI gloss.",
  ),
  (
    "mood_land",
    "Photoreal film still, Kodak Portra 400, naturalistic true color. A high aerial view at sunset " ++
    "of dark green forest, a long inlet of calm water the color of copper in the low light, and a " ++
    "distant snow-capped mountain with faint pink alpenglow on its peak. Vast and quiet, soft " ++
    "evening light, gentle grain, documentary realism. NOT teal and orange, no halation.",
  ),
  (
    "mood_mountain",
    "Photoreal film still, Kodak Portra 400, naturalistic true color. A large snow-capped mountain " ++
    "like Mount Rainier seen from high altitude at sunset, pink and gold alpenglow on the snow at " ++
    "the top, soft blue shadows below, a calm evening sky around it. Grand and still, soft light, " ++
    "fine grain, realism. NOT teal and orange, no halation, no CGI gloss.",
  ),
]

let rec run = async i =>
  if i >= Belt.Array.length(shots) {
    ()
  } else {
    let (name, prompt) = Belt.Array.getExn(shots, i)
    let out = Path(dir ++ "/frames/" ++ name ++ "_gpt2.png")
    let b = await imageGpt2(~prompt=Prompt(prompt), ~refs=[])
    let _ = writeBytes(out, b)
    Js.log(name ++ " -> " ++ dir ++ "/frames/" ++ name ++ "_gpt2.png  (" ++ Js.Float.toString(fileSizeMb(out)) ++ " MB)")
    await run(i + 1)
  }

let main = async () => await run(0)
main()->ignore
