/* ONE controlled Seedance 2.0 (fal) smoke test — a single WORDLESS, film-real Sky
   King establisher. Corrected template: NO DV/handheld; Kodak Portra 400 / Drive /
   Kohrra; the camera MOVEMENT is an off-modal entropy pick — a slow lateral track,
   NOT the modal push-in. 5s, 720p, 16:9. Budget: 5s x 720p ~= $1.50. One call, no
   batch. Run: node src/Cinema_SkyVideoTest.res.mjs */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/video-tests/ramp-dawn_seedance2_720p_5s_v1.mp4"

let prompt = Cinema_Backends.Prompt(`Main subject: BIRDY, a gentle ordinary man about 30, a tired, kind, unremarkable face, short brown hair, a day of stubble; a worn heather-grey hoodie under an orange hi-vis safety vest with faded reflective stripes, scuffed work gloves, dark canvas work trousers, steel-toe boots. Real skin with pores and a dawn-cold flush, no makeup, plain. He works without hurry. Maintain consistent identity, clothing, hairstyle, and appearance throughout.

Location: a small, prosperous regional-airport ramp at first light. Wet grey tarmac holding thin puddles that mirror a pale sky; a Bombardier Q400 turboprop parked on the stand, its forward cargo door open, a belt loader angled up to it; a short train of baggage carts, a red tug, a yellow ground-power unit, orange cones; sodium apron lamps still burning against the blue-grey dawn; a second Q400 further down the row. A working, lived-in, well-kept operation — not poor, not glamorous. No crowds, no onlookers, no signage clutter, no advertising, no glossy jet airliners.

Visual Style: naturalistic documentary realism; Kodak Portra 400 film, Kohrra / Drive register; candid, off-centre framing; true muted colour, a cold dawn palette; real photographic film grain; nothing stylised, no CG sheen, no illustration look.

Camera Style: 35mm film feel; ONE motivated move on a dolly — a slow, steady lateral track, NOT a push-in. Motivated available light only (the sodium lamps and grey dawn). Fine organic grain, gentle. No DV handheld, no shake, no autofocus hunting, no gimbal glide, no teal-and-orange grade, no modern HDR.

Timed beats:
00:00-00:02  The camera tracks slowly leftward across the wet apron; foreground baggage carts slide past in near-silhouette; the open cargo door of the Q400 begins to clear the frame.
00:02-00:05  The track settles as it discovers BIRDY at the belt loader, lifting a suitcase onto the belt into the cargo hold; his breath fogs in the cold; behind him the red tug rolls past; the turboprop sits still and huge beside his small figure.

Audio: natural ambient only — a turboprop APU whining down off-frame, the belt-loader motor, a tug engine passing, low ground-crew chatter, wind across the apron. No music, no narration.

Goal: an ordinary working dawn on the ramp, shot like real observed documentary film — plain, cold, true; a small man and the big plane he loads, both just there in the grey. Like a frame from Drive on Kodak Portra, not a render.`)

let main = async () => {
  let t0 = Js.Date.now()
  Js.log("=== Seedance 2.0 (fal) smoke test — ramp dawn, film-real, 5s/720p (~$1.50) ===")
  try {
    let blob = await Cinema_Backends.falSeedance2(
      ~prompt,
      ~seconds=5,
      ~resolution="720p",
      ~aspect="16:9",
      ~audio=true,
    )
    let _ = Cinema_Backends.writeBytes(Cinema_Backends.Path(outPath), blob)
    let secs = (Js.Date.now() -. t0) /. 1000.0
    Js.log("WROTE: " ++ outPath)
    Js.log("elapsed: " ++ Js.Float.toFixed(secs) ++ "s")
  } catch {
  | Cinema_Backends.BackendError(m) => Js.log("BACKEND ERROR: " ++ m)
  }
}

main()->ignore
