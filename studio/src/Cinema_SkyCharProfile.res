/* Re-establish the canonical Birdy CHARACTER PROFILE in gpt-image-2's world,
   conditioned on the approved locked face so the identity is preserved. Every
   gpt-image-2 scene then conditions on THIS, so reference and scenes match. */
open Cinema_Backends

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"

let main = async () => {
  let out = Path(dir ++ "/sheets/birdy_sheet_gpt2.png")
  let prompt = Prompt(
    "Character turnaround model sheet, photoreal, Kodak Portra 400 look, true color, even neutral " ++
    "studio lighting, plain light grey seamless background. The SAME man shown four times in one " ++
    "horizontal row, full body standing, in four views left to right: front view, three-quarter " ++
    "view, side profile view, and back view. He is an ordinary gentle man around 30 with short " ++
    "tousled brown hair, wearing a grey hoodie under an orange high-visibility ground-crew safety " ++
    "vest, dark work trousers and boots. His face, hair, build, and clothing are identical in all " ++
    "four views. Relaxed neutral standing pose, arms at his sides. Keep his face identical to the " ++
    "reference image. No text, no labels, no grid lines.",
  )
  let refs = [Path(dir ++ "/sheets/birdy_profile_gpt2.png")]
  let b = await imageGpt2(~prompt, ~refs)
  let _ = writeBytes(out, b)
  Js.log("birdy sheet -> " ++ dir ++ "/sheets/birdy_sheet_gpt2.png  (" ++ Js.Float.toString(fileSizeMb(out)) ++ " MB)")
}

main()->ignore
