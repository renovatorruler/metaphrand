/* Test gpt-image-2 on a CHARACTER: Birdy in the Q400 cockpit, conditioned on the
   locked Birdy face (test_birdy_cockpit_v1.png) as a reference — so we learn
   whether gpt-image-2 can hold our established character, not just landscapes. */
open Cinema_Backends

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"

let main = async () => {
  let out = Path(dir ++ "/frames/mood_cockpit_birdy_gpt2.png")
  let prompt = Prompt(
    "Photoreal cinematic film still, Kodak Portra 400 look, naturalistic true color, neutral " ++
    "white balance. The same man shown in the reference image, around 30, sits alone in the " ++
    "captain's left seat of a Bombardier Dash 8 Q400 twin-turboprop cockpit at sunset. He wears " ++
    "an aviation headset and an orange high-visibility ground-crew safety vest over a grey hoodie, " ++
    "one hand resting on the control yoke, looking out the windscreen at a calm golden sunset sky " ++
    "with a faint pink snow mountain in the distance. Soft natural sunset light through the glass, " ++
    "real cockpit instruments and switches visible, gentle film grain, understated documentary " ++
    "realism. Keep his face identical to the reference. No teal-and-orange grade, no halation, " ++
    "no posed hero shot.",
  )
  let refs = [Path(dir ++ "/test_birdy_cockpit_v1.png")]
  let b = await imageGpt2(~prompt, ~refs)
  let _ = writeBytes(out, b)
  Js.log("char frame -> " ++ dir ++ "/frames/mood_cockpit_birdy_gpt2.png  (" ++ Js.Float.toString(fileSizeMb(out)) ++ " MB)")
}

main()->ignore
