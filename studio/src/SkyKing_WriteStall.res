/* ACT 2 #10 — THE STALL (2026-07-02; SUPERSEDES sky-king-olympus, user: "the
   scene doesn't do anything... needs to move the plot... show more of Birdy's
   ability... we need people to love him. This is a movie."). The transcript
   lines (pilot-job joke, jail-for-life price, video games) now RIDE AN EVENT
   instead of being the event: flying slow toward the dark Olympic range he
   gets too slow and STALLS the Q400 - stick-shaker clattering through the
   keyed mic, a wing dropping toward a black ridge - and because his blip has
   no altitude readout, THE FIGHTERS ARE HIS TELEMETRY (the jets that came for
   a terrorist calling the fall for the room), while Banjo can barely fly slow
   enough to stay with him. HE CATCHES IT BY FEEL, apologizing while he saves
   it. The pilots' awe jumps a step (professional, never poetic); he gives a
   real flier's flat diagnosis and the absurd true source (video games); the
   job joke lands EARNED (he just proved it) and the jail price closes flat.
   PLOT OUT: the recovery burns fuel (the clock is real now), the near-miss
   births the shoot-down logic in the machine's mouth, and REYES LAUNCHES R1 -
   headset on, tells Mercer she's going up on the frequency. Engine-written. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-stall.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-stall",
  slug: "INT. Q400 FLIGHT DECK / NIGHT SKY / COMMAND POST - NIGHT (INTERCUT)",
  logline: "He swings the airplane west to go look at the other range, the dark one, and to see anything at all he flies slow - so slow the fighters hang off his wings on the edge of falling out of the sky themselves. Then he gets a little too slow. The stick-shaker hammers through his keyed mic, a wing lets go over a black ridge, and the only altitude readout anybody on the ground has is a fighter pilot's voice calling the fall. And the man flying the stolen airplane catches it - by feel, in the dark, apologizing the whole way down and the whole way back up - and when it's over, the people who heard it are different about him than they were a minute ago. The room gets its first taste of the other math too: next time he might not catch it. And a woman at the command post picks up a headset.",
  cast: [
    {
      name: "BIRDY",
      who: "flying slow toward the dark range to see it at all; he lets the speed bleed away a hair too far and the airplane quits flying. In the fall he is two things at once: the apologizer (sorry, sorry, hang on) and the gift (nose down into the fall, wings leveled by feel, the recovery no one taught him). Afterward he diagnoses it flat like a line pilot, names the absurd true source when asked, floats the job joke off the adrenaline, and lays the price down flat. He never names fear, never names wanting anything.",
      register: "soft, apologetic, halting - EXCEPT in the fall, where the callouts go short and flat and sure; the diagnosis afterward plain and technical; the joke floated light; the price flat like weather, deflected to fuel; never bitter, never poetic.",
      earnsEloquence: false,
      lexicon: "the nose, the power, the speed, she quit flying, said plain; video games said like an apology; jail said like weather.",
    },
    {
      name: "DEACON",
      who: "lead fighter pilot, holding formation at speeds his jet hates; when the Q400's wing lets go, he becomes the room's instruments - calling altitude and attitude down the net, flat and fast, the jet that came for a terrorist now flying telemetry for a falling man. The recovery moves him a full step: he asks the question a pilot has to ask (what happened / where did that come from) and gets two answers he'll never forget.",
      register: "measured, clipped in the emergency, professional; the awe arrives as silence and one flat sentence, never poetry.",
      earnsEloquence: false,
      lexicon: "the wing, the nose, angels, the calls flat and fast; hands said once.",
    },
    {
      name: "BANJO",
      who: "the wingman, fighting his own airplane just to stay slow enough to watch - blower cycling, hanging on the edge of his own stall while the turboprop wallows ahead. The one who says the awe out loud, short, to Deacon.",
      register: "dry, quick, working hard; his own cockpit workload audible in the clipped lines; the awe as an aside.",
      earnsEloquence: false,
      lexicon: "his own jet's edge, the speed, that was hands, said flat plane-to-plane.",
    },
    {
      name: "BISHOP",
      who: "at his scope with no altitude readout on the blip - blind while a man falls; he holds the frequency steady, feeds silence and small sure words, and afterward gets out of the way of the pilots' question. He never lies, never comforts, and when the price gets laid down flat, his open mic and his quiet are the answer again.",
      register: "flat, steady, quieter as it gets worse; small sure words in the fall (you're talking, keep flying it register); the honest silence after the price.",
      earnsEloquence: false,
      lexicon: "the frequency, the blip with no altitude, said plain.",
    },
    {
      name: "MERCER",
      who: "at the command post, watching a room full of people stand up during the fall; when it's over, he says the other math out loud to nobody in particular - the near-miss becoming policy in real time: next time he might not catch it, and it won't pick where it lands.",
      register: "flat, low, cold-practical; one or two lines; not cruel - arithmetic.",
      earnsEloquence: false,
      lexicon: "next time, where it comes down, said flat.",
    },
    {
      name: "REYES",
      who: "at the command post through the whole event - the stall, the recovery, the joke, the price; at the end she picks up a headset and tells Mercer she's going up on the frequency. The scene ends on her decision.",
      register: "silent through the event; at the end, two short flat lines - a decision, not a speech.",
      earnsEloquence: false,
      lexicon: "the frequency, him, said flat.",
    },
  ],
  layer: {
    peshat: "flying slow toward the dark mountains, the pilot stalls the airliner, recovers it by feel while the fighters call the fall, jokes about a job, states his price flat - and the negotiator decides to go on the air",
    sod: "the gift and the disease in one fall: the body that catches a dying airplane by feel is the same man apologizing for the trouble on the way down - competence and smallness fused so tight the audience can't love one without the other; the machine's instruments fail exactly where he lives (no altitude, no name, no file - the state is blind to him even falling) and the jets sent to kill a category end up flying telemetry to save a man; the recovery proves the gift is real, which makes the job joke unbearable and the flat price true - he is exactly good enough for the life he will never be allowed, and he knows the bill; the room learns the other math (next time he doesn't catch it) and mercy and murder both pick up speed from the same near-miss; and the woman who heard all of it reaches for the headset with a licensed lie in her pocket",
  },
  beats: [
    {
      who: "BANJO",
      want: "to stay on the wing - his jet is at the ragged bottom of its speed just holding formation with a wallowing turboprop",
      wall: "the Q400 keeps slowing - Birdy hangs the nose high to drift past the dark range and the fighters have nothing left to slow with",
      turn: "Banjo calls his own edge to Deacon (plane-to-plane, working hard) just as the Q400 gets a hair too slow - and the stick-shaker starts hammering through Birdy's keyed mic, and the left wing lets go over the black ridge",
      subtext: "the multimillion-dollar jets outflown downward by a bag handler's slowness; the audience hears the stall begin before anyone names it; the dark terrain waiting under all of it",
    },
    {
      who: "DEACON",
      want: "to be the room's instruments - the blip has no altitude, so his voice is the only readout anybody has",
      wall: "the fall is fast, the ridge is close, and there is nothing anyone on the ground or the wing can do but watch and call it",
      turn: "he calls it down the net flat and fast - wing down, nose falling, altitude unwinding - while Bishop holds the frequency with small sure words and the command post comes up out of its chairs; through the keyed mic: the shaker clattering, the engines, and Birdy's voice going short and flat and SURE for the first time all night (sorry - hang on - nose is coming down - there she is) as he flies INTO the fall and levels the wings by feel and climbs away from the ridge",
      subtext: "the state blind to him even falling; the apologizer and the gift in the same breath; the recovery nobody taught him, heard not seen; the room holding its breath as one body",
    },
    {
      who: "DEACON",
      want: "the answer a pilot has to have: what happened up there, and where did that come from",
      wall: "the true answers are impossible: a flat line-pilot diagnosis from a man who is not a pilot, and a source that sounds like a joke",
      turn: "Birdy gives both, plain: got slow, nose too high for the power he had, his fault - and, asked where he learned to catch it: video games, mostly, and the sim; a beat of silence on the net; Banjo, plane-to-plane, short: that was hands; Deacon says nothing, which says more",
      subtext: "the technical answer only a real flier gives, from the man the world filed as nobody; the absurd true source; the awe completing its second and third step in one exchange; nobody summarizes",
    },
    {
      who: "BIRDY",
      want: "to float back to light - the adrenaline draining into the only register he has",
      wall: "what he just proved makes the lightness heavier: he is exactly good enough for the life he will never have",
      turn: "the job joke, floated off the adrenaline (you think the airline'd give me a job after this - like a pilot job) and Bishop's warm true play-along (they'd give you a job doing about anything register); Birdy's small laugh at himself - and then the price, flat, like weather, deflected in the same breath to the fuel the recovery burned: it's jail for a guy who does this, life probably, and the tank's down around whatever it's down around; Bishop's open mic, and nothing in it",
      subtext: "the joke earned by the miracle before it; the dream sayable only as comedy at the exact moment it stopped being funny; the accepted bill (R1's wall); the fuel clock now real; the honest silence again",
    },
    {
      who: "REYES",
      want: "(the whole event decided it) to go up on the frequency herself",
      wall: "what she's carrying is the licensed blank - and she just heard the man price himself at life in prison",
      turn: "at the command post Mercer says the other math out loud, flat, to nobody in particular (next time he doesn't catch it, and it doesn't pick where it comes down) - the near-miss becoming policy - and Reyes picks up a headset and tells him she's going up on the frequency; end on her walking toward the radar room with the headset in her hand",
      subtext: "mercy and murder accelerating off the same near-miss; the negotiator launching R1 on screen; the lie in her pocket and the wall she heard with her own ears; the scene CAUSES the next one",
    },
  ],
  rules: [
    "THE EVENT IS THE SCENE: the stall and recovery are the engine; every transcript line (the job joke, the jail price, video games) arrives ONLY after and BECAUSE of the event. If a line could be lifted out without the event noticing, cut it.",
    "EARS-ONLY EMERGENCY: the stall is heard - the stick-shaker CLATTERING through Birdy's keyed mic, the engine note, his breathing, his voice going short and flat and sure; DEACON's calls are the altitude readout (the blip has NO altitude - established canon; the fighters are the room's only instruments and the page says so plainly). Full-sentence action lines carry the fall filmably.",
    "BIRDY IN THE FALL: short flat SURE callouts with small apologies threaded through (sorry - hang on - nose is coming down register) - the apologizer and the gift in the same breath; the recovery is flying INTO the fall (nose down, wings leveled by feel), rendered as plain procedure, NO thematic wink about nerve or cowardice, NO poetry.",
    "BANJO'S OWN STRUGGLE IS REAL TEXTURE: his jet can barely fly this slow (blower cycling, on his own edge) - the fighters' struggle to stay with the slow turboprop is shown, not commented; his awe line stays short and professional (that was hands register). BANNED: 'nobody taught him that', any poster-line summary of the gift.",
    "THE DIAGNOSIS THEN THE SOURCE: Deacon asks what happened - Birdy's answer is a REAL FLIER'S flat diagnosis (got slow, nose too high for the power, my fault register); asked where he learned it - video games, mostly, and the sim - said like an apology, and the net goes quiet a beat. Nobody laughs at him; nobody explains it.",
    "THE JOB JOKE lands only AFTER the recovery, floated off adrenaline; Bishop's play-along stays warm and TRUE AS A JOKE; THE PRICE stays a FLAT STATEMENT (no question mark, no seeking, no fear) deflected in the same breath into the fuel the recovery burned - the fuel clock is REAL from this scene on. THE RUSSELL LAW absolute: no deal talk, no coming-down talk, no wanting-to-live/die talk, no comfort from anyone; Bishop's open mic and silence answer the price.",
    "THE OTHER MATH (plot motion #2): after the recovery, MERCER says the shoot-down logic's seed out loud - flat, arithmetical, to nobody (next time he doesn't catch it, and it doesn't pick where it comes down register) - NO villain, no order given, just the machine's fear finding words. One or two lines maximum.",
    "REYES LAUNCHES R1 (plot motion #3, the ending): she was present through the whole event; after Mercer's math she picks up a headset and tells him she's going up on the frequency - two short flat lines, a decision not a speech - and the scene ENDS on her walking toward the radar room, headset in hand. No button after it.",
    "COMMAND POST PHYSICALITY: the room comes up out of its chairs during the fall and sits back down after - bodies, not commentary; Kemp and the screens may appear in action lines; nobody at the post speaks during the fall except the net traffic.",
    "ACTION LINES ARE FULL SENTENCES, PRESENT TENSE; ORIENT every voice (plane-to-plane asides marked and oriented; the command post beats placed); re-anchor returning characters lightly. LEGIBILITY: stall/stick-shaker rendered in plain self-evident words (the airplane quits flying, the warning hammering); at most two flavor terms, each self-evident.",
    "Kill every catalog tell: doubled openers, engineered refrains, appended-fact fragments, list drumbeats, cross-character mirroring, summarizing Lines, thematic telegraphing, stated/implied turns, manufactured stammers, parallel restatement. American vernacular. Recorded, not written.",
    "Voice-differentiate: BIRDY (soft-apologetic; flat-sure only in the fall), DEACON (clipped, measured, the calls), BANJO (dry, working, the aside), BISHOP (steady, smaller and quieter as it gets worse), MERCER (flat arithmetic), REYES (two flat lines, a decision).",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=5)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: THE STALL (the gift under death; the lines earned; R1 launched) ===\n")
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
