/* SKY KING — one hero frame, to prove the live Replicate image endpoint through
   ReScript AND re-confirm the look (neutral Portra realism, NOT the rejected
   "Drive" teal-orange) on the cheapest possible unit before the full batch.
   Birdy in the Q400 captain's seat, ground-crew hi-vis vest, original face. */
open Cinema_Backends

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"

let main = async () => {
  let out = Path(dir ++ "/frames/co_hero_cockpit.png")
  let prompt = Cinema_Frames.Description(
    "Photoreal film still, Kodak Portra 400, naturalistic true color, neutral white balance. " ++
    "Interior of a Bombardier Dash 8 Q400 twin-turboprop cockpit at golden hour. " ++
    "A gentle, ordinary man about 29 sits in the captain's left seat wearing an aviation headset " ++
    "and a hi-visibility orange ground-crew safety vest over a grey polo, hands resting near the " ++
    "control yoke. He gazes out the windscreen at a calm sunset sky with pink alpenglow on the " ++
    "snow cap of Mount Rainier far in the distance. Candid, slightly off-center composition seen " ++
    "from the empty co-pilot seat. Soft motivated sunset light through the glass, real cockpit " ++
    "instruments and switches visible, fine film grain, documentary realism, understated. " ++
    "NOT teal and orange, no halation glow, no posed hero shot, no yellow piss-filter cast.",
  )
  let refs = [Path(dir ++ "/test_birdy_cockpit_v1.png"), Path(dir ++ "/sheets/birdy_turnaround.png")]
  let p = await Cinema_Frames.shot(
    ~prompt,
    ~out,
    ~refs,
    ~register=Cinema_Frames.Photoreal,
    ~faceLock=true,
    ~avoid=[Cinema_Frames.ActorName("Richard Russell")],
  )
  let Path(pp) = p
  Js.log("HERO FRAME -> " ++ pp ++ "  (" ++ Js.Float.toString(fileSizeMb(p)) ++ " MB)")
}

main()->ignore
