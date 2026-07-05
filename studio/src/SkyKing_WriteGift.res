/* ACT 2, beat 4 — THE GIFT, IN THE OPEN. Higher and steadier now, Birdy has the feel
   of it. The Q400 crosses the last light with a fighter escort and Bishop's calm voice
   in his ear. Rainier holds the last of the sun; the Sound goes dark, the lights come
   on. Bishop, keeping him talking, draws him out - and Birdy, gentle and sad-but-
   cheerful, has almost nothing to tell: no one who'll much miss him, nothing he ever
   did. And up here, flying it clean and sure, he is doing the one thing - and being
   SEEN, which (not the beauty) begins to turn him toward wanting to live. STORIES
   motif planted. Recognition BEGINS (not the full awe / barrel roll). Engine-written. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-gift.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-gift",
  slug: "INT. Q400 FLIGHT DECK / SKY OVER RAINIER - DUSK",
  logline: "Higher now, and steadier - Birdy has the feel of it. The Q400 crosses the last light with two fighters off its wing and Bishop's calm voice in his ear. Rainier holds the last of the sun; the Sound goes dark below and the lights come on. Bishop, keeping him talking, asks about him, and Birdy - gentle, a little sad, cheerful about it - has almost nothing to tell: no one who'll much miss him, nothing he ever did. And up here, flying it clean and sure, he is doing the one thing, and Bishop and the men off his wing begin to see it.",
  cast: [
    {
      name: "BIRDY",
      who: "fully himself now - gentle, plain, sad-but-cheerful, self-deprecating; flying it clean and sure (the gift, finally in the open); he has no stories, nothing he ever did, and he is cheerful and apologetic about it, which is the whole tragedy; up here he is alive for the first time.",
      register: "soft, plain, sad-but-cheerful (the Richard-Russell key); self-deprecating, warm, apologetic; his flying said as flat literal callouts; NEVER aviation poetry, NEVER self-pity, NEVER a Line.",
      earnsEloquence: false,
      lexicon: "the panel, the flows, the callouts said flat and literal; his own empty life said plainly and lightly, never bitter.",
    },
    {
      name: "BISHOP",
      who: "the human thread; calm, kind, steady; keeps Birdy talking, keeps him company, keeps him alive; gently draws him out with small human questions; he begins to hear the man and to see the flier.",
      register: "warm, calm, careful; small human questions; plain and kind; NEVER a speech, NEVER on-the-nose, NEVER states the theme.",
      earnsEloquence: false,
      lexicon: "the radio, the altitudes, the man said calm and literal; his kindness plain, never a sermon.",
    },
  ],
  layer: {
    peshat: "Birdy flies the Q400 in the last light with a fighter escort, talking to the controller, who asks about him",
    sod: "the gift, finally in the open: the gentlest nobody, who never did a single thing with his life, is flying an airliner clean and sure in the last light, and it is beautiful; drawn out by the one kind voice, he reveals he has nothing - no one who'll much miss him, nothing he ever made or dared - and he is cheerful and sorry about it, which is the whole tragedy; up here, doing the one thing, he is finally alive and finally SEEN - by Bishop, by the men off his wing - and that being-seen, NOT the beauty, is what begins quietly to turn him from flying toward death to wanting to live; the STORIES motif is planted - he has none, and he is making one now",
  },
  beats: [
    {
      who: "BISHOP",
      want: "to keep Birdy calm and talking - and, humanly, to know him",
      wall: "there is nothing Birdy will reach for; he deflects gentle and small",
      turn: "Bishop asks about him - anyone at home, kids, what he does - and Birdy answers plain and sad-cheerful: not really, no, nothing much; he loads bags, he watches; he never did anything",
      subtext: "Bishop keeps him alive by keeping him company; the kindness draws Birdy out; the emptiness of a life that never dared, said cheerfully, which is worse than bitter",
    },
    {
      who: "BIRDY",
      want: "to just fly this - to have the one thing",
      wall: "he was never good at anything anyone saw; it's an airliner he has no business in",
      turn: "he flies it clean and sure - a steady turn, a level crossing, the callouts under his breath, the gift in the open; the last light on the mountain is just there, texture; and Bishop, quiet, hears how well he is flying it",
      subtext: "the competence finally spent where it can be seen; the sim made real; the beauty is NOT the point - the point is he can DO this, and someone is watching",
    },
    {
      who: "BISHOP",
      want: "for Birdy to know he isn't nothing - to be seen",
      wall: "Birdy won't believe it and deflects any kindness",
      turn: "Bishop says a plain true thing about the flying - that it's good, that not just anyone could do it - and the men off his wing hold formation on him; Birdy, gentle, doesn't quite know what to do with being seen; something small turns, the first flicker toward wanting to live",
      subtext: "recognition, NOT beauty, is what begins to turn him; being SEEN for the one thing he can do; the held awe building toward the midpoint; the man who did nothing, doing something, and being told it",
    },
  ],
  rules: [
    "Action lines = ONLY what the camera sees or the mic hears (the flight deck, the panel, the mountain in the last light, the fighters off the wing, the Sound going dark, the lights coming on). No interiority, no naming feelings.",
    "BEAUTY IS TEXTURE, NOT THE POINT: Rainier / the Olympics / the last light / the city lights are SHOWN plainly and briefly; do NOT wax lyrical, NO aviation poetry, NO 'cathedral of sky.' The emotional point is Birdy being SEEN for what he can do, not the view.",
    "BIRDY is gentle, plain, SAD-BUT-CHEERFUL (Richard-Russell): self-deprecating, apologetic, warm; he reveals he has nothing - no one who'll much miss him, nothing he ever did - CHEERFULLY, which is the tragedy. NEVER self-pity, NEVER a Line, NEVER poetry. His flying = flat literal callouts.",
    "The STORIES motif is a PLANT, never stated: Birdy has no stories, never did anything; up here he's making one. Let it live UNDER the plain exchange; never say 'stories' as a theme.",
    "RECOGNITION begins here (NOT the full awe / barrel roll): Bishop says a plain true thing about the flying; the pilots hold formation; Birdy doesn't know what to do with being seen. It is the being-SEEN, not the beauty, that starts to turn him toward wanting to live. Keep it SMALL and unfinished.",
    "BISHOP is calm, kind, careful - draws Birdy out with small human questions; NEVER a speech, NEVER on-the-nose, NEVER states the theme.",
    "The pilots (Deacon/Banjo) are a near-silent escort - at most ONE short line or a held-formation beat; keep the scene BIRDY + BISHOP.",
    "NO cross-character echo or reworded mirroring, NO character echoing themselves, NO summarizing 'Lines'/poster-taglines, NO manufactured false-start stammers, NO thematic telegraphing, NO flat echoes. American vernacular. Recorded, not written.",
    "End SMALL and unfinished - Birdy flying on, seen for the first time, something just beginning to turn; NOT resolved (the midpoint / barrel roll comes later).",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=5)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: THE GIFT, IN THE OPEN (Act 2) ===\n")
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
