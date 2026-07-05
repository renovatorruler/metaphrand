/* A few more cockpit angles of Birdy for the dialogue section, generated THROUGH
   the cast flow (SkyKing_Cast.frame -> Cinema_Frames.shot, face-locked on the
   Birdy sheet, gpt-image-2 on Replicate). Cheap stills, not Sora. */

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"

let shots = [
  (
    "cockpit_birdy_close",
    "Interior of a Bombardier Dash 8 Q400 turboprop cockpit at sunset. A closer shot of the man " ++
    "from the reference, in ground-crew clothes, an orange hi-visibility vest and an aviation " ++
    "headset, looking out the windscreen at the golden evening sky with a calm, thoughtful " ++
    "expression. Warm low sunlight on his face, real cockpit instruments and switches around him.",
  ),
  (
    "cockpit_birdy_yoke",
    "Interior of a Q400 turboprop cockpit at sunset, seen from behind and over the shoulder of the " ++
    "man from the reference: his hands resting on the control yoke, his orange vest and headset " ++
    "visible, and ahead through the windscreen a calm golden sunset sky with a faint pink snow " ++
    "mountain far in the distance. Warm light, real instruments.",
  ),
  (
    "cockpit_birdy_profile",
    "Interior of a Q400 turboprop cockpit at sunset, a side profile of the man from the reference " ++
    "looking out the side cockpit window, warm sunset light across his face, his orange vest and " ++
    "aviation headset visible, calm and quiet. Real cockpit interior.",
  ),
]

let rec run = async i =>
  if i >= Belt.Array.length(shots) {
    ()
  } else {
    let (name, desc) = Belt.Array.getExn(shots, i)
    let out = Cinema_Backends.Path(dir ++ "/frames/" ++ name ++ ".png")
    if !Cinema_Backends.exists(out) {
      let _ = await SkyKing_Cast.frame(~desc, ~present=["BIRDY"], ~out)
    }
    Js.log(name ++ " -> frames/" ++ name ++ ".png")
    await run(i + 1)
  }

let main = async () => await run(0)
main()->ignore
