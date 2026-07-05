/* ACT 2 — THE CALL, v3 (2026-07-02). Fix: v2 still hinted Birdy was interested in
   surrender (the "is there a guy you talk to after" question = the stated turn in
   disguise). GONE. Per the Richard Russell principle: Birdy NEVER expresses any
   interest in coming down / an after / a deal / jail — not as a question, not as a
   joke. He talks about everything BUT the thing: he apologizes, runs himself down,
   deflects; when Maya's "I came" lands, it shows ONLY in his body (a hand going
   still) and in a self-deprecating deflection ("figured wrong about some stuff"),
   never a want. Maya imposes a future (the ladder demand) and he goes along the way
   he goes along with everything - which commits to nothing. Two moving machines,
   intercut; the card, the escort, the split. Engine-written. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-call.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-call",
  slug: "INT. FBI SEDAN (MOVING) / INT. Q400 FLIGHT DECK - NIGHT (INTERCUT)",
  logline: "Night. A federal sedan moves Maya across the city, the call on speaker in her hand because the Bureau insisted, an agent in the front seat holding a card of things she is supposed to say - while the Q400 tracks the other way over the black water with a fighter off each wing. The FBI hears a wife talking about nothing. Birdy hears the one thing that can reach him: she came. He never says a word about coming down, or an after, or what happens to him - he apologizes, he makes himself small, he goes quiet - and the only sign it reached him is his hand going still on the throttle.",
  cast: [
    {
      name: "MAYA",
      who: "Birdy's wife, a care-home night nurse - tired, plain, working-class; she stopped waiting up on this marriage a long time ago and is cracked open now, mad and guilty and tender all at once. She is talking to her HUSBAND, not briefing a stranger: she assumes everything, explains nothing, and comes at the feeling sideways through some small specific thing. She will not read the card.",
      register: "plain, specific, and REAL - ONE thought at a time. She does NOT restate a fact or feeling in a second matching clause; she does NOT narrate her own situation for anyone; she does NOT wrap a line up with a summarizing tag. Her anger lands on a specific petty old thing, not a general 'I'm mad' announced then repeated. Fragments, a thought dropped mid-air, the mundane detail; the big feeling stays under a small complaint.",
      earnsEloquence: false,
      lexicon: "specific household things (the ladder, Ken next door, the spare room) said sideways and mad; the big feeling never named, only leaked through the small one.",
    },
    {
      name: "BIRDY",
      who: "up in the dark with a fighter off each wing, gentle, sad-but-cheerful, keeping it light because that is what he does; he has made his private peace and he says nothing about it; hearing Maya - learning she CAME - reaches him, but he will not name it, will not ask about coming down or an after, will not believe he is worth any of the fuss; he apologizes and makes himself small.",
      register: "soft, plain, sad-but-cheerful, apologetic, self-deprecating (Richard Russell: 'a guy like me', 'figured wrong'); flat literal callouts under the talk; NEVER a stated or implied want, NEVER a question about after/jail/coming-down, NEVER poetry.",
      earnsEloquence: false,
      lexicon: "the panel, fuel, altitude, the escort, flat and literal; his own smallness said lightly, never bitter.",
    },
    {
      name: "SHAW",
      who: "the field agent from Maya's door, now in the front passenger seat with the negotiation card; her errand is to get the wife to deliver the script - keep him calm, keep him talking, get him following the escort down - and the wife will not; her frustration is physical: circling a line, tapping the card, holding it against the seatback; professional, pressured, never cruel.",
      register: "controlled, procedural, quiet-urgent; when Maya won't look at her she talks ABOUT Maya, to the driver.",
      earnsEloquence: false,
      lexicon: "the card, the points, the negotiator language, flat.",
    },
    {
      name: "VOSS",
      who: "the older agent driving; twenty years of exactly this; says almost nothing, watches the mirror, makes the one veteran call - let her talk - when Shaw wants to step in.",
      register: "flat, unhurried; two lines in the whole scene.",
      earnsEloquence: false,
      lexicon: "the road, the mirror, plain.",
    },
    {
      name: "BISHOP",
      who: "the controller who patches the call up onto the frequency and steps back; a careful, humane presence at the edge of it.",
      register: "calm, brief, out of the way.",
      earnsEloquence: false,
      lexicon: "the patch, the frequency, said calm.",
    },
  ],
  layer: {
    peshat: "driven across the city with the FBI's script in her face, a wife refuses the card and just talks to her husband, who never says a word about coming down",
    sod: "two vehicles carry a marriage in different directions - her face lit by a dashboard, his by a panel - and the state sits in the front seat wanting its script read; the card is the machine's version of love (manage him, steer him, bring him down) and she cannot read it because the true thing is not manageable: she is mad, and she came; the car hears a woman talking about a ladder while the plane hears the only thing that reaches a man who thought nobody would miss him; and Birdy never says he wants to live, never asks how coming down would go, never bargains - because a guy like him doesn't believe he gets to; the recognition lands and he can only apologize for having figured wrong, and go quiet; the sign it reached him is not a word, it is his hand going still on the throttle while she orders him to come get the ladder",
  },
  beats: [
    {
      who: "SHAW",
      want: "to brief Maya into the script before the patch goes live - the card, the points, deliver them",
      wall: "Maya barely hears her; the city slides past; and the patch comes through EARLY - Bishop's voice is suddenly in the car",
      turn: "the call starts before the machine is ready - 'There she is. Hi.' - and Maya answers with the name only she uses: '...Sam.' Off-script from the first word",
      subtext: "the machine's plan colliding with the marriage; the card already useless; the speakerphone means everyone hears everything - both ways",
    },
    {
      who: "MAYA",
      want: "(imposed) read the card; (hers) make it real - say true plain things, be mad, be here",
      wall: "the card keeps coming into her sightline - Shaw circles a line and holds it up; the whole car is listening; years of numbness",
      turn: "she turns her body to the window and goes where she needs to go - plain, mad, real: I'm mad at you... but I came - and Shaw, low, to the driver: what is she doing - and Voss, eyes on the road, without turning: let her talk",
      subtext: "the wife refusing to perform the state's marriage counseling; the demand under the anger is COME HOME, never said; the machine yielding to the human thing",
    },
    {
      who: "BIRDY",
      want: "to keep it light, scare nobody, make nothing heavy, take up as little room as he can",
      wall: "she CAME - and the plain mad true things she says reach him where any script would have bounced off",
      turn: "his hand goes still on the throttle (the only sign); he does not ask to come down, does not ask what happens after, does not bargain - he thanks her plainly and then makes himself small, apologizes, says he figured wrong about some stuff; the escort slides up and he gives it a little wave, keeping it light",
      subtext: "recognition arriving as physical stillness and a self-deprecating deflection; a man who can't believe he's worth the fuss; the will to live never named, never even approached",
    },
    {
      who: "MAYA",
      want: "to put a future on him he didn't ask for - to make him promise an ordinary tomorrow",
      wall: "he won't reach for it himself; all she can do is order it, mundane and stubborn",
      turn: "she gives him a chore with a tomorrow inside it - when this is done, you go to Ken's, you get our ladder back - and Birdy goes along the way he goes along with everything, 'okay,' committing to nothing; the sedan takes the airport exit while the Q400's lights track the other way over the water; unresolved",
      subtext: "Maya fighting for him by being bossy about a ladder; his 'okay' the deflection-by-agreement that is his whole disease; two vehicles, two directions, the marriage in the frame; nobody names anything",
    },
  ],
  rules: [
    "ACTION LINES ARE FULL SENTENCES, PRESENT TENSE (Breaking Bad register): every action line has a subject and a finite verb - 'The sedan threads the empty lanes. The panel lights Birdy's face green.' BANNED: the verbless fragment pile.",
    "ORIENT EVERY VOICE: before any new or redirected speaker, write the physical move first - Shaw turns around from the front seat; Maya turns to the window; Bishop's voice comes through the speaker; Voss watches the mirror. The scene must play EARS-ONLY - a listener with no cues must always know who is talking and to whom.",
    "INTERCUT TWO MOVING MACHINES: the sedan threads city streets while the Q400 tracks the opposite way over the black water; her face is dash-lit, his panel-lit. The rhyme is never named - just cut between them.",
    "THE SECOND CHANNEL runs under the whole call. Ground: the card business - Shaw circles a line, taps it, holds it against the seatback; Maya refuses with her body; Shaw's frustration goes to the driver; Voss: let her talk. Air: the escort slides closer, Birdy waves at it, flat callouts, his hand on the throttle. Keep cutting to the physical.",
    "DUAL AUDIENCE, NEVER EXPLAINED: the call is on speaker - the car hears a wife mad about a ladder; Birdy hears the one thing that reaches him: SHE CAME. Nobody explains either conversation.",
    "THE RICHARD RUSSELL LAW - THE HARD ONE: Birdy NEVER expresses any interest in surrender. He does NOT say he wants to live, to come down, to not die. He does NOT ask what happens after, whether there's a guy he talks to, how jail goes, whether they'd let him do anything - NOT as a statement, NOT as a question, NOT as a joke. He talks about everything BUT the thing: he apologizes, he makes himself small ('a guy like me', 'I figured wrong about some stuff', 'didn't think it'd be all this fuss'), he keeps it light, he waves at the fighter. If ANY line has him angling toward coming down or an after, cut it.",
    "THE ONLY SIGN THE RECOGNITION REACHED HIM IS BEHAVIOR: his hand goes still on the throttle. Show it; do not gloss it; do not let him narrate it.",
    "BAN wistful domestic postcards (no porch lights, no rooms-kept-as-he-left-them, no boxes-as-imagery). Maya's lines DO things - demand, accuse, order the ladder. If a line is a poignant image, replace it with a demand.",
    "BAN the dead-air / lost-signal device (that belongs to Act 3). The line stays up; tension lives in the card, the escort, and what is not said.",
    "Maya calls him SAM - only she uses that name; first thing she says. A bare 'I'm mad at you' and a bare 'But I came' are the load-bearing beats - keep them plain with NOTHING padded around them (no restatement, no explaining how she came). The ladder is her imposed future, but ONE short specific mad line - e.g. 'You still gotta get the ladder back off Ken' - NOT a doubled 'when this is done, when it's all done' and NO summarizing button like 'so that's on you'; Birdy's answer is a bare 'okay'.",
    "MAYA'S VOICE - THE HARD FIX (she has been reading as an AI bot; overhaul her): (a) NO PARALLEL RESTATEMENT - she never says the same fact or feeling twice in one breath in matching clauses ('I'm real mad. I've been mad the whole ride over.' BANNED; 'I came... I got in the car and came.' BANNED; 'when this is done, when it's all done' BANNED). One thought per line; a second clause must ADD or CHANGE, never echo the first. (b) NO SELF-NARRATION - she is talking to her HUSBAND and never describes her own situation for the audience ('they came and got me and I'm in a car right now, that's where I'm talking to you from' BANNED); she under-explains, assumes shared context. (c) NO BUTTONED MONOLOGUE - her demands are short, specific, mundane, mad, with no summarizing tag. (d) Her anger comes at Birdy SIDEWAYS through a specific petty real thing (a chore, the ladder, an old grievance), never a general declared-then-repeated feeling.",
    "WHISPER TAGS: the Shaw/Voss sidebar is spoken low, under the call, so the people on the phone don't hear it - mark BOTH Shaw's aside to Voss AND Voss's reply (WHISPER): e.g. 'SHAW (WHISPER): She's not saying any of it, what is she doing.' / 'VOSS (WHISPER): Let her talk.' Only those private front-seat asides are whispered; everything on the phone line is normal voice.",
    "BIRDY never confronts and never states or implies a feeling; his callouts stay flat and literal under the emotional talk; his self-deprecation is light, never bitter, never poetic.",
    "Kill every catalog tell: doubled openers, engineered refrains, appended-fact fragments, list drumbeats, cross-character mirroring (ESPECIALLY Maya-Birdy), summarizing Lines, thematic telegraphing, movie-procedural register, the stated/implied turn, manufactured stammers. American vernacular. Recorded, not written.",
    "End unresolved and fast: after Birdy's bare 'okay' to the ladder, the split - the sedan exits toward the airport, the plane's lights track the other way over the water. No button, no resolution, nobody comments.",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=5)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: THE CALL v3 (no stated/implied turn; Russell register) ===\n")
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
