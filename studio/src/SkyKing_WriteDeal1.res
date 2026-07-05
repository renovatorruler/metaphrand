/* ACT 2B — R1: THE OFFER, v3 (2026-07-04; RESHAPED per user). Two fixes to v2:
   (1) THE OPENER — no "how are you doing up there" wellness-greeting; instead
   BIRDY DERAILS HER: she keys in with her script ready and he is already
   mid-wonder (the lights, the water) and offering the FEDERAL NEGOTIATOR the
   view - the hijacker putting her at ease - and she has to abandon her opener
   and follow him. (2) MRS. CORLEY MOVES TO THE HANG-UP: it is NOT an opener
   block anymore; after the offer is refused and she is out of moves, on the
   way out, he gently tells her she sounds like a teacher he had - the wound
   revealed as a parting observation, the last thing, never explained. The
   licensed-lie frame + Bishop's silent conscience + the kind refusal ("a guy
   like me" / the user's line) all stand. Engine-written. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-deal1.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-deal1",
  slug: "INT. SEATTLE APPROACH - RADAR ROOM / Q400 FLIGHT DECK - DUSK (INTERCUT)",
  logline: "Reyes comes into the radar room with a headset and a script in her head and a blank check in her pocket, gets patched up onto the frequency by the one man who has never lied to the pilot - and before she can say the first thing she planned to say, the gentlest voice of the night is already telling her to look at the water, at the lights coming on, like she called him. She has to put the script down and follow him. And when she finally makes the offer - bring it down, no jail, her word - he thanks her kindly and doesn't believe a syllable, because he already knows what waits for a guy like him. It's on the way out, when there's nothing left to say, that he tells her she sounds like a teacher he had.",
  cast: [
    {
      name: "REYES",
      who: "the negotiator, walking in with the license nobody defined and an opener she never gets to use - because he greets HER with the view, and she has to drop the technique and meet him where he is; she makes the offer plain with her own name on it, and the man is kind to her about not believing it; nobody catches her, which is the problem; and the last thing she gets from him, on the way out, is a wound she can't see the bottom of.",
      register: "brisk-professional walking in, then disarmed - she abandons the script and goes plain sooner than she meant to; the offer flat and specific; the silences lengthening; she does not defend the lie and does not confess it; the Corley line lands on her and she has no floor under it.",
      earnsEloquence: false,
      lexicon: "the offer, no jail, my word, said flat; the script she doesn't get to run.",
    },
    {
      name: "BIRDY",
      who: "up in the last of the light, at peace like a man who accepted the bill long ago; he greets the negotiator with the sky because that is what is in front of him and because putting other people at ease is the only power he has ever had; offered the one thing that could change the night he thanks her and lets it go by, KNOWING what waits for a guy like him; and only at the very end, kindly, does the old wound show - she talks like a teacher he had once.",
      register: "soft, plain, sad-but-cheerful; the opening WONDER genuine and small (look at the water / the lights); the disbelief KIND ('that's real nice of you to say' register); the price flat, no fear; the Corley line at the hang-up gentle, plain, WITHOUT accusation; never bitter.",
      earnsEloquence: false,
      lexicon: "the lights, the water, the sky; a guy like me; fuel flat; a teacher he once had, at the end.",
    },
    {
      name: "BISHOP",
      who: "at his scope three feet from her, the man who has never told Birdy one false word, listening to the offer made on his frequency; he patches her up, steps back, and says nothing; his stillness is the scene's conscience and the page never names it.",
      register: "two or three flat lines at most (the patch); otherwise silence and small physical stillness.",
      earnsEloquence: false,
      lexicon: "the frequency, the patch, said plain and rarely.",
    },
  ],
  layer: {
    peshat: "the negotiator means to open with a script and instead gets shown the view; she makes the real-sounding offer, he declines it kindly, and on the way out he tells her she sounds like an old teacher",
    sod: "the man being lied to disarms the liar with a kindness she did not plan for - he hands the federal negotiator the sunset because easing other people is the only authority a lifetime ever gave him, and it wrecks her worse than resistance would; his refusal is not despair, it is the arithmetic of a guy who has learned good things are always for somebody else; and the wound he finally shows - the slow, managed teacher-voice he has been handled with his whole life - he shows on the way out, kindly, protecting her from it even as he names it; the man who never lies sits silent at his scope while the lie is made on his frequency, the room's conscience with a headset on; she leaves needing the one thing the machine never issues, a promise that's true",
  },
  beats: [
    {
      who: "BIRDY",
      want: "(unasked) to share the thing in front of him - the last light on the water, the lights coming on",
      wall: "the person keying in has an agenda; but he doesn't know that, and the wonder comes out first anyway",
      turn: "Bishop patches her up; before Reyes can run her opener, Birdy is already talking to her - look at the water, you can see the lights coming on down there - and she has to set the script down and answer the man, not the plan",
      subtext: "the hijacker putting the negotiator at ease; the disarming that isn't a tactic; her technique stranded before she can use it; Bishop patching them and going still",
    },
    {
      who: "REYES",
      want: "to get to the offer now that the opener is gone - and make it land, her own name on it",
      wall: "the offer is a blank and she knows it; and the man has already priced the night",
      turn: "she goes plain sooner than she meant to and says it flat and specific - bring this airplane down, you're not going to jail, not tonight, not after, her word, she'll stand there herself - and the answer comes gentle and immovable: that's real nice of her to say; a guy like him doesn't get that; he'd rather not come down and find out what they do",
      subtext: "the licensed lie performed in full, witnessed only by herself and a silent controller; his settled arithmetic meeting her blank; the refusal without the word no",
    },
    {
      who: "BIRDY",
      want: "to be kind to her - she came out in the middle of all this for him too",
      wall: "the kindness lands harder on her than any catch would",
      turn: "he thanks her, tells her she's been real kind, and lets the offer go by like a nice thought; deflects to something small and true (the escort, the fuel getting on); the frequency goes quiet around her; she has nothing left to try",
      subtext: "he protects the woman sent to lie to him; unworthiness as settled fact, not wound; the gentlest refusal on record; Bishop's stillness judging without a word",
    },
    {
      who: "BIRDY",
      want: "(the hang-up) nothing - just a plain thing he notices as it's ending",
      wall: "-",
      turn: "as it's clearly over - her hand going toward the key to sign off - Birdy, gentle, unprompted: she talks like Mrs. Corley, a teacher he had, who used to talk to him real slow so he'd get it; Reyes, thrown, asks if the teacher was good to him; 'she was fine, she meant well, everybody meant well'; and that's the last of it - Reyes unkeys, sets the headset down, and goes; Bishop at his scope; the headset where she left it",
      subtext: "the short-bus wound shown ONLY on the way out, as a parting observation, never explained; the managed teacher-voice she used on him named without accusation; her not understanding what she stepped on; the walk that becomes R2",
    },
  ],
  rules: [
    "THE OPENER IS BIRDY, NOT A GREETING: after Bishop patches her up, BIRDY speaks first - genuine small WONDER offered to her (the water, the last light, the lights coming on down there) - and Reyes must abandon her planned opener and follow him. BANNED: any 'how are you doing up there' / 'you still with me' / wellness-check greeting from anyone. She does NOT get to run her script.",
    "MRS. CORLEY IS THE HANG-UP, NOT THE OPEN: the teacher beat appears ONLY at the very end, after the offer is refused and it's clearly over, as a parting observation - gentle, plain, unprompted, WITHOUT accusation. Targets (land these or very close): 'You talk like Mrs. Corley. She had me for a couple years. She used to talk to me real slow like that, so I'd get it.' / Reyes thrown: 'Was she good to you?' / 'She was fine. She meant well. Everybody meant well.' Then Reyes unkeys and goes. Do NOT place any Corley material earlier.",
    "THE OFFER is plain and specific (no jail, her word, she'll stand there herself), made once with one restatement at most; the REFUSAL never uses the word no: kind thanks ('that's real nice of you to say' register), the settled fact ('I don't think it works like that for a guy like me' register, light), and the user's line flat and unafraid: he knows they're gonna do something to him - he'd rather not come down and find out what. NOT despair, NOT a death wish - arithmetic; the Russell law otherwise absolute.",
    "THE LIE IS NEVER NAMED in any direction; Bishop says NOTHING about it - his silence and small physical stillness (a squared strip, a hand flat, the cold coffee, not looking at her) are the only commentary; the page never explains them.",
    "BIRDY IS KIND TO HER throughout: he eases her, thanks her for coming out, deflects to something small and true (the escort riding easy, the fuel getting on - one flat callout keeps the clock live); the kindness lands as worse than a catch; the page never says so.",
    "CONTINUITY: Reyes ENTERS off the command-post corridor carrying the headset (from SIGHTS); DUSK - the last light still on the water (this precedes full dark); re-anchor Reyes and Bishop lightly; SOURCED FACTS ONLY.",
    "ACTION LINES ARE FULL SENTENCES, PRESENT TENSE; ORIENT every voice; INTERCUT radar room and flight deck; the SECOND CHANNEL stays physical (the headset cord, the scope's looping track, Bishop's stillness, the panel glow and the lights below on Birdy's side).",
    "END FAST and cold: she unkeys after the Corley beat, sets the headset on the console, walks out; Bishop watches the scope; the headset stays in frame. NO button, NOTHING after.",
    "Kill every catalog tell: doubled openers, engineered refrains, appended-fact fragments, list drumbeats, cross-character mirroring, summarizing Lines, thematic telegraphing, stated/implied turns, manufactured stammers, parallel restatement, trailing-'so.' on anyone but Maya. American vernacular. Recorded, not written.",
    "Voice-differentiate: REYES (brisk, then disarmed, then floorless at the Corley line), BIRDY (soft wonder; kind; immovable), BISHOP (two flat lines and stillness).",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=5)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: R1 v3 (Birdy derails the opener; Corley at the hang-up) ===\n")
    Js.log(Cinema_Backends.readText(out))
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
