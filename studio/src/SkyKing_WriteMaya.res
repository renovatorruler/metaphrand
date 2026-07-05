/* Act 1 texture (Maya, WITHOUT Birdy) — THE PATIENT WHO SEES HER (v2, real drama).
   REBUILT after feedback: the pill/window haggle was transactional and the lines
   clichéd. New engine: DORIS (very old, proud, sharp) waited all evening for a
   daughter who didn't come and won't say so; when MAYA reaches for the phone to call
   the daughter, Doris forbids it and, cornered, turns the knife on Maya - a cruel,
   specific, TRUE guess about the empty house Maya goes home to. Maya doesn't answer;
   she sets the phone down and STAYS, past her shift, because no one's waiting on her
   either. Doris SEES her by wounding, not interrogating; Maya reveals herself by the
   undialed phone and the staying, not by talking. NO stock old-person lines. NO Birdy.
   Two women alone; the plant Birdy's flight will crack open. Engine-written. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-maya.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-maya",
  slug: "INT. CARE HOME - NIGHT",
  logline: "Late shift. Doris - old, proud, sharp - has been waiting all evening for a daughter who didn't come, and won't say so. When Maya reaches for the phone to call her, Doris forbids it and, cornered, turns the knife on Maya instead: a cruel, specific guess about the house Maya goes home to, that lands because it's true. Maya doesn't answer. She sets the phone down and stays, longer than the job needs, because there's no one waiting on her either.",
  cast: [
    {
      name: "MAYA",
      who: "Birdy's wife, in her own world: a night nurse, warm and real and tender with her patients - and the instant it's about her own life she goes still and gives nothing, the exact way Birdy deflects. Here she reveals herself not in words but in the phone she won't dial and in staying past her shift.",
      register: "gentle, unhurried, genuinely warm with Doris; when Doris wounds her she is SILENT - she absorbs, she does not defend or fire back; her few words are plain and true, never a deflection-cliché, never a comfort-speech.",
      earnsEloquence: false,
      lexicon: "the work said flat and literal; her own life she does not speak of at all - her silence carries it.",
    },
    {
      name: "DORIS",
      who: "very old, proud, and sharp, frightened underneath; her daughter didn't come again and she would rather be cruel than pitied. She wounds Maya to move the light off herself. NOT sweet, NOT sassy-wise, NOT a sage - specific, difficult, particular, and scared.",
      register: "old and hard and proud; her cruelty is specific and aimed, not stock; she does NOT talk like a sitcom grandma or a greeting card; short, exact, cutting; the true thing she lands on Maya is plain, never poetic.",
      earnsEloquence: false,
      lexicon: "her room, the door she keeps watching, her daughter, plain and blunt; no self-pity spoken aloud.",
    },
  ],
  layer: {
    peshat: "a night nurse and a proud old woman whose daughter didn't come; the nurse moves to call the daughter, the old woman forbids it and wounds her instead; the nurse sets the phone down and stays",
    sod: "two women alone - one dying, one in a dead marriage - and neither will say it; Doris covers the hurt of a daughter who didn't come by wounding the one person who did; her cruel guess about Maya's empty house lands because it's true; Maya, who absorbs everything and defends nothing (exactly like Birdy), doesn't answer - she sets the phone down and stays past her shift, because there is no one at home waiting on her either; the reveal is in the staying, not the talking; this capacity to be present, withheld from her own life, is what Birdy's flight will crack open",
  },
  beats: [
    {
      who: "MAYA",
      want: "to reach the daughter who didn't come - to mend the empty evening for her",
      wall: "Doris will not be pitied, and forbids the call",
      turn: "Maya reads the signs - Doris waiting, dressed for a visit that didn't happen, the chair turned to the door - and reaches for the phone; Doris stops her cold",
      subtext: "Doris waited all evening and won't say it; Maya sees it and wants to mend it; Doris would rather be cruel than caught needing anyone",
    },
    {
      who: "DORIS",
      want: "to stop the call - and to not be the one exposed",
      wall: "Maya is gentle and won't quite let it go; the truth of the empty evening is sitting right there",
      turn: "cornered, Doris turns the knife on Maya - a cruel, specific guess about the house Maya goes home to - and it lands; Maya goes still and says nothing, the phone undialed in her hand",
      subtext: "Doris wounds Maya to move the light off herself; the jab happens to be true; Maya's silence confirms it - she will not defend herself, the exact way her husband never will; two alone people recognizing each other without a word",
    },
    {
      who: "MAYA",
      want: "to not leave Doris alone with it - and to not be alone herself",
      wall: "the cruel thing is said and sitting between them; it's past her shift, she could go",
      turn: "Maya sets the phone down and stays - no lecture, no comfort-speech, one small real unhurried act of presence; Doris, disarmed, lets her; a moment of two women alone passes; then Maya, kind, goes",
      subtext: "Maya answers cruelty and loneliness with presence, not words; she stays past her shift because nothing pulls her home; the withheld tenderness and the capacity to STAY, spent on a stranger - the plant for Act 2",
    },
  ],
  rules: [
    "Action lines = ONLY what the camera sees or the mic hears. No interiority, no naming feelings.",
    "REAL DRAMA, not a transaction: the engine is the daughter who didn't come, the forbidden phone call, and Doris's pride - genuine stakes (dignity, loneliness). NO mundane negotiation over pills, food, a blanket, or a window as the spine. Every beat is a real collision of wants.",
    "NO CLICHÉD lines. BANNED outright: any stock old-person line ('longer than you've been alive,' 'back in my day,' 'when you get to my age,' 'at my age,' 'you young people,' 'I've earned the right'). Doris is SPECIFIC and surprising; her sharpness is particular to HER, never sitcom-grandma or greeting-card.",
    "DORIS SEES Maya by WOUNDING her - one cruel, specific, TRUE jab that displaces her own hurt - NOT by gentle interrogation and NOT by dispensing wisdom. The seeing is a weapon, not a sermon.",
    "MAYA mostly does NOT respond - her stillness, her silence, the undialed phone, and her STAYING carry the scene more than lines. She absorbs and does not defend herself (exactly like Birdy). Her few lines are plain and true; NO deflection-clichés, NO comfort-speech.",
    "DORIS is genuinely OLD, proud, difficult, frightened under it - NOT sweet, NOT sassy-wise, NOT a sage/oracle. Grounded, specific, real.",
    "The husband (Birdy) is NEVER named and never appears; Doris's jab gestures at Maya's empty house obliquely. Maya's silence carries what it costs her.",
    "The reveal is through ACTION - the phone Maya doesn't dial, staying past her shift - more than through dialogue.",
    "Recorded, not written: plain, specific, grounded; NO metaphor, NO Line, NO aviation, no appended-fact tags, no flat echoes, no melodrama, no deathbed speech.",
    "End SMALL: Maya stays a beat too long, then goes; she carries it; no self-pity, no stated epiphany.",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=5)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: MAYA v2 (the patient who sees her — real drama) ===\n")
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
