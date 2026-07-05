/* Dez (Blake) — a quick sample of the HESITANT, deferential delivery the user asked
   for: Dez is younger and a bit beta to Birdy, so he defers — pauses, tentative,
   trailing. Pauses via ellipses + one soft filler; no manufactured stammer.
   Run: node src/Cinema_SkyDezSample.res.mjs */
open Cinema_Backends

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"
let dez = VoiceId("mWRBtRP92mUXZzi4RZ0Y") // Blake — thoughtful late-20s

let lines = [
  "You worked that gate... two years, though.",
  "You, uh... did you put in for the turn? Or...",
  "You never once asked for the turn. Not once. You just... take whatever the box puts up.",
]

let main = async () => {
  let segs = lines->Belt.Array.map(l => (Text(l), dez))
  let take = await dialogue(segs)
  let out = Path(dir ++ "/SKY-KING_dez-hesitant-sample.mp3")
  let Path(p) = writeBytes(out, take)
  Js.log("DEZ SAMPLE -> " ++ p)
}

main()->ignore
