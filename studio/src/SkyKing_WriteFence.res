/* COLD OPEN — THE FENCE (2026-07-03; the ballad restructure's threat verse).
   WORDLESS: pure CCTV action lines, golden hour. A man jumps the airport
   perimeter — hood up, no face, purposeful — read by the audience as TERROR
   (post-9/11 airport grammar arms itself; the page never editorializes). He
   moves camera to camera, exits one frame, enters another; we NEVER see him
   board; the last frame holds empty with a tail sitting in its far dark edge.
   The next scene (the dot) opens on the blip. He is NEVER named — "the man,"
   never BIRDY (the audience doesn't know him; the reveal is the voice, two
   scenes from now). Honors the cold-open law: no dialogue, no narrator prose
   tricks — the mood-set carries. Engine-written. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-fence.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-fence",
  slug: "EXT. SEA-TAC PERIMETER - CCTV - GOLDEN HOUR",
  logline: "Fixed security cameras, timestamps running, the low sun flaring the lenses gold. A man comes out of the scrub on the far side of the perimeter road, hood up, and goes over the fence like he's done it in his head a hundred times. Camera to camera, he crosses the service roads and the equipment rows with his face never once toward a lens, and the airport goes on being an airport around him - fuel trucks, a pushback, gulls - until he walks out of the last frame that ever sees him, and the frame holds: empty concrete, long shadows, and far off in the corner, the tail of a parked airliner.",
  cast: [
    {
      name: "THE MAN",
      who: "a figure on CCTV - hood up, work boots, a canvas bag across his back; face never toward a lens; moves with the unhurried certainty of somebody who knows every camera's blind side because standing under them was his job. The audience must read him as a THREAT; the film knows better and says nothing. He is never named.",
      register: "SILENT - he has no lines; he exists only in action lines, and the action lines never editorialize him.",
      earnsEloquence: false,
      lexicon: "none - wordless.",
    },
  ],
  layer: {
    peshat: "security cameras record a man jumping the airport perimeter fence at golden hour and crossing toward the aircraft; he is never identified and never seen boarding",
    sod: "the machine's own eyes watching the most overlooked man alive and filing him, at last, under the only category it has for a man it never learned - threat; the audience is the machine here, reading hood and fence and purpose exactly the way the world always read him: wrong; the low sun makes the whole trespass golden because this is the first minute of the one free day; and the cameras that never once noticed twenty years of him arriving to work now record every step of him leaving the world - the ballad's first verse, sung by surveillance footage",
  },
  beats: [
    {
      who: "THE MAN",
      want: "over the fence - in through the one seam he knows",
      wall: "chain-link, wire, the open ground between the scrub and the perimeter road, cameras on poles",
      turn: "he comes out of the scrub with the low sun behind him, crosses the ditch, and goes up and over the fence in one practiced motion - and the fixed camera just watches, timestamp running, nobody coming",
      subtext: "the trespass read as terror by every eye watching - the audience included; the ease of it worse than force; golden light on all of it",
    },
    {
      who: "THE MAN",
      want: "across the field - camera to camera, blind side to blind side",
      wall: "the working airport around him: a fuel truck crossing, a pushback under floodlights coming on early, gulls lifting off the grass",
      turn: "he exits one frame and enters the next, angle after angle - the service road, the equipment rows, the baggage carts - his face never once toward a lens, the airport never once noticing him, and the sun getting lower in every frame",
      subtext: "the world that never looked at him failing to look one last time; the surveillance grammar doing the audience's terror for it; the light already leaving",
    },
    {
      who: "THE MAN",
      want: "the far edge of the last frame",
      wall: "nothing - and that is the horror the audience is invited to feel: nothing stops him",
      turn: "he walks out of the last camera's frame toward the parked rows, and the frame HOLDS - empty concrete, long gold shadows, the timestamp ticking, and far off in the corner of the image, the tail of a parked airliner; we never see him board; hold on the empty frame",
      subtext: "the boarding withheld (the ballad never shows the hammer picked up - only the mountain); the empty frame as the world's last chance to have seen him, missed; the next thing the film knows is a blip",
    },
  ],
  rules: [
    "WORDLESS: ZERO dialogue lines. The entire scene is ACTION lines. No radio, no PA, no voices.",
    "CCTV GRAMMAR: fixed angles, one camera at a time; the man EXITS one frame and ENTERS another; timestamps run in the corners; lens flare off the low sun; he is never framed like cinema - always like surveillance (high, fixed, indifferent). Say the camera plainly when the angle changes ('A camera on the fuel farm picks him up crossing the service road.' register).",
    "HE IS NEVER NAMED: 'the man' / 'the figure' only — NEVER Birdy, never a description that identifies him (no face toward a lens, ever). The audience must be free to read terrorist.",
    "NEVER EDITORIALIZE: no mood words (no 'ominous', 'menacing', 'eerie'), no interiority, no narrator knowingness — the post-9/11 airport grammar arms the terror by itself. Plain filmable facts only, full present-tense sentences.",
    "GOLDEN HOUR THROUGHOUT (the light spine's first minute): the low sun, long shadows, gold flare on the lenses — stated plainly as what the camera records; the light gets lower frame to frame.",
    "THE AIRPORT KEEPS WORKING around him (a fuel truck, a pushback, gulls, floodlights coming on) — and never notices him. Do not stage a near-miss with a person; nobody sees him.",
    "THE BOARDING IS WITHHELD: he walks out of the last frame toward the parked rows and the film NEVER sees him board. End on the HELD EMPTY FRAME — concrete, shadows, the timestamp ticking, a tail far off in the corner. No button, nothing after the hold.",
    "Keep it SHORT: twelve to eighteen action lines total. Every line a full present-tense sentence. Kill every catalog tell (no fragment piles, no rule-of-three rhythm, no engineered refrain).",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=5)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: THE FENCE (cold open — the threat verse, wordless) ===\n")
    Js.log(Cinema_Backends.readText(out))
    Js.log("\n=== VERIFY (expect PENDING until lift) ===")
    switch Write.verify(out) {
    | Ok() => Js.log("VERIFY OK")
    | Error(m) => Js.log("VERIFY: " ++ m)
    }
  } catch {
  | Write.WriteError(m) => Js.log("WRITE FAILED (gate):\n" ++ m)
  | Session.SessionError(m) => Js.log("SESSION: " ++ m)
  }
  Session.close()
}

main()->ignore
