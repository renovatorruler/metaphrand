/* Act 1 — home at night: the gift in secret + the rote marriage. Birdy is fully
   alive and brave ONLY at the flight sim in the spare room, where it's safe, unseen,
   and unreal; he won't reach at anything that could cost him — the marriage, the
   life, the real sky. Maya is kind and tired and worn to autopilot (kind, which is
   worse); the home is comfortable ENOUGH, and that comfort is the death. No villain,
   no poverty, no melodrama. Recorded-not-written. Engine-written; the Sod stays under. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-home.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-home",
  slug: "INT. BIRDY AND MAYA'S HOME - NIGHT",
  logline: "Late at night in the spare room, Birdy flies a perfect flight on a home simulator - the one place he's fully alive, because it's a game in the dark that costs nothing and no one sees; his wife Maya tries for one small real moment, gives it up kind and tired, and covers him where he falls asleep pretending.",
  cast: [
    {
      name: "BIRDY",
      who: "a gifted coward; fully alive and sure-handed and brave ONLY at the home flight sim, where it's safe and unseen and not real; with his wife he's plainly agreeable and gone, and won't reach at anything that could cost him. The same man who will one day steal a plane.",
      register: "gentle, warm, agreeable, absent; deflects with a small ordinary line without looking up; never reaches, never confronts; plain and a little dull. Recorded, not written.",
      earnsEloquence: false,
      lexicon: "the sim and flight said FLAT and literal - the flows, the runway lights, the panel, the callouts - and the house said flat; NEVER a metaphor for a feeling.",
    },
    {
      name: "MAYA",
      who: "Birdy's wife; kind, tired, worn to autopilot; she loves him and stopped reaching for him a while ago. NOT a nag, never cruel - her not-fighting is the point.",
      register: "quiet, plain, tired; the small ordinary things; no heat, no complaint - a woman who has stopped expecting more and is gentle about it.",
      earnsEloquence: false,
      lexicon: "the house, the hour, the routine, said flat and literal.",
    },
  ],
  layer: {
    peshat: "a couple's ordinary comfortable-enough night at home - a man at a flight simulator in the spare room, a wife heading to bed",
    sod: "that the one place he is fully alive and brave is a game in the dark where it costs nothing and no one sees; that he pours everything into the safe pretend and nothing into the real - the marriage, the life, the actual sky; that the home is comfortable ENOUGH and that comfort is the death; and that his wife, kind and tired, has stopped reaching for him too, and covers him where he falls asleep pretending",
  },
  beats: [
    {
      who: "BIRDY",
      want: "to fly the sim - the one place he is fully himself",
      wall: "it's a game in a dark spare room, not real, and it costs him nothing",
      turn: "he runs a perfect flight, absorbed and sure and alive, better than anyone would guess, where no one will ever see it",
      subtext: "this is the ONLY place his gift lives and the only place he is brave, precisely because it's safe and unreal - he will be magnificent where it can't cost him anything and won't dare it anywhere it could",
    },
    {
      who: "MAYA",
      want: "one small real moment with him before bed",
      wall: "he's in the sim, agreeable but gone, not there",
      turn: "she says the ordinary tired thing, he answers plainly without looking up, and she lets it go and heads to bed - kind, no fight",
      subtext: "she loves him and stopped reaching a while ago; the marriage is comfortable and numb and neither will risk breaking the quiet; her kindness - no nag, no fight - is worse than anger, because it means she's stopped expecting more",
    },
    {
      who: "MAYA",
      want: "to just let him be",
      wall: "he's asleep at the sim, the screen still glowing",
      turn: "she brings a blanket, covers him where he fell asleep pretending, turns off the lamp, and goes to bed",
      subtext: "this is the rut - she covers him like this often; the tenderness is real AND it's the shape of two people who have quietly stopped, comfortable in the numb",
    },
  ],
  rules: [
    "Action lines = ONLY what the camera sees or the mic hears. No interiority, no naming feelings.",
    "THEME = COWARDICE + comfort-is-the-horror, never stated: he is fully alive and brave ONLY at the sim (safe, unseen, unreal) and will not reach at the real - the marriage, the dream. The home is comfortable ENOUGH and that is the death. NO ONE says coward, brave, afraid, dream, numb, comfortable, or reach.",
    "NO villain, NO poverty, NO melodrama: they are ordinary middle-class, the home comfortable enough; the horror is the comfort itself, not any hardship.",
    "MAYA is KIND and tired and worn to autopilot - NOT a nag, NEVER cruel; her not-fighting IS the point (kind, which is worse). She loves him; she has stopped reaching.",
    "BIRDY deflects with plain, agreeable, ordinary lines, never reaches, and is fully absorbed and alive ONLY at the sim.",
    "Recorded, not written - plain, mundane, a little dull; NO metaphors, NO clever lines, NO reaching; the sim and flight spoken as flat literal shop-talk.",
    "The home sim flies the Q400 / a big regional TURBOPROP - the kind of aircraft he loads by day and will one day take, NOT a small Cessna; a regional-flight callsign; real turboprop flows and callouts (this quietly foreshadows the flight).",
    "Show his GIFT plainly - he flies the sim beautifully, real flows and callouts under his breath - hidden, where no one sees.",
    "End on Maya covering him asleep at the sim, the screen still glowing - plain, the rut, no sentiment.",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=4)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: HOME (gift in secret + rote marriage) ===\n")
    Js.log(Cinema_Backends.readText(out))
    Js.log("\n=== VERIFY ===")
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
