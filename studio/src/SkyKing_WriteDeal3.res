/* ACT 3 #15 — R3: THE REAL DEAL, STILL REFUSED, v2 (2026-07-04). Changes from
   v1: (a) the GLASS-CROWN (SKY KING typed) is REMOVED from here and RELOCATED
   to the finale AFTER the naming (the glass must register the squadron's vote,
   not precede it); R3 now opens on Birdy in the dark and Reyes arriving with
   the paper. (b) the paper CARRIES THE BAN CLAUSE, read flat: no charges, a
   doctor, nobody puts you anywhere - AND you're done flying, for life, never at
   the controls again. The mercy with the pilot-killing term in it - and he
   thanks her anyway. This is the term the finale pays off ("you heard them.
   I'll never be able to fly again."). The refusal is unworthiness, not
   death-talk; he believes HER and not himself. Fuel critical; full dark.
   Engine-written. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-deal3.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-deal3",
  slug: "INT. SEATTLE APPROACH - RADAR ROOM / Q400 FLIGHT DECK - NIGHT (INTERCUT)",
  logline: "Reyes comes back with the thing she was told couldn't exist: real paper, real names, signed - no charges, a doctor, nobody puts him anywhere - and one hard line she reads him flat, that he is done flying for the rest of his life, never at the controls of anything again. She reads all of it, because reading it is the only argument left. And the gentlest man alive is moved that she went and did that for him, and believes every word she says, and cannot make himself believe it could be for a guy like him - while the fuel number stops being a number that allows for long conversations.",
  cast: [
    {
      name: "REYES",
      who: "back with the real thing - the deal she was told couldn't exist, signed and specific, the mercy and the one merciless term both on the page; she reads it flat and whole because reading it IS the argument, and there's no technique left in her, only the truth and the clock. She hears the refusal arrive gently and completely and understands the wall was never the paper.",
      register: "stripped plain; reads the terms flat, no negotiator voice at all - including the ban clause, read the way it's put down, no apology in it; her last pushes small and human; the failure received in silence, not a speech.",
      earnsEloquence: false,
      lexicon: "the paper, the names on it, the terms read verbatim-flat; done flying; I'm holding it.",
    },
    {
      name: "BIRDY",
      who: "in the dark, the panel and the fuel gauge the only light; moved - genuinely - that she went and did that for him; he believes HER completely, which is the heartbreak, because it is himself he cannot extend the belief to; a lifetime of closing doors has left no room where a real open one registers as his. Kind, grateful, light, immovable - and the fuel is going.",
      register: "soft, warm, genuinely touched ('you did that for me' register, plain, no tears); the refusal without the word no, gentler than ever - not that the paper's wrong, it can't be for him; flat fuel callouts under it; never bitter, never dark, NEVER death-talk.",
      earnsEloquence: false,
      lexicon: "the paper believed, HER believed; a guy like me; the tank, the gauge, flat.",
    },
    {
      name: "BISHOP",
      who: "at his scope through the offer, stillness again; when the refusal lands his hand stays flat on the console; he does not plead and does not lie.",
      register: "silence and small physical beats; one flat line at most.",
      earnsEloquence: false,
      lexicon: "the scope, the tag, the frequency, said plain and rarely.",
    },
  ],
  layer: {
    peshat: "the negotiator returns with a real signed deal - mercy plus a lifetime flying ban - and reads it to the pilot; he is moved, believes it's real, and still cannot believe it's for him; the fuel runs down",
    sod: "the world's hand finally arrives real and open and twenty years too late, and it comes holding the one thing that would cost him everything anyway - his life for his wings - and the tragedy is not that the deal was once a lie, it is that a lifetime of fake doors takes the hinges off the real one; he extends every ounce of his faith to HER and has none left for himself; the woman who moved a government for him learns the last thing a rescuer learns - you cannot hand a man his own worth across a radio; and the merciless clause riding inside the mercy is the seed the finale will flower: a man will choose to die a pilot over living grounded; the fuel underneath it all, going",
  },
  beats: [
    {
      who: "REYES",
      want: "to read him the real thing whole - the reading IS the argument",
      wall: "the clock (the fuel has stopped allowing long conversations) and the man's gentleness, which she now knows is a wall",
      turn: "she comes up the corridor with the paper, takes the headset standing, and reads it flat - no charges, a doctor, nobody puts you anywhere - names, signatures - and the one hard line, read the way it's put down: you're done flying, for the rest of your life, never at the controls again; and the thing that isn't on the page: I'm holding it, it's in my hand right now",
      subtext: "no technique left; the truth read like a checklist because a checklist is her most honest voice; the mercy and the ban both true; the ban clause planted for the finale",
    },
    {
      who: "BIRDY",
      want: "to be worthy of the kindness - which to him means being honest about it",
      wall: "the belief has one room in him and she is standing in it; there is no room where the door opens FOR HIM",
      turn: "he is moved, plainly, genuinely ('you did that for me; that's really something' register); he believes the paper, he believes HER; and the refusal arrives gentler than ever and complete - he doesn't think a thing like that lands on a guy like him - said without one gram of self-pity, and then the flat fuel callout underneath",
      subtext: "faith fully extended to her, none left for himself; the real door and the missing hinges; the refusal as courtesy, protecting her from his arithmetic; the clock loud now; he does NOT react to the ban clause as a loss (it confirms what he already knew)",
    },
    {
      who: "REYES",
      want: "(the last push, small and human) to make it land before the number on the board decides everything",
      wall: "there is no argument left - the wall was never the paper",
      turn: "she tries once more, small - there's a blank line with his name under it - and gets his gratitude instead of his yes; the held beat where she understands; her hand comes off the key onto the paper; Bishop's hand flat on the console; on the glass the naked blip rides out over the black water with no name on it yet; the fuel number drops and holds; end on the room saying nothing",
      subtext: "the rescuer's last lesson; worth cannot be handed over a radio; the blip still nameless (the naming is still to come, in the air); the failure received standing; unresolved into the finale",
    },
  ],
  rules: [
    "NO GLASS-CROWN HERE: the SKY KING tag is NOT typed in this scene and does NOT appear on any scope; the blip rides NAKED ('no name on it yet' / no tag) - the naming happens later, in the air, and Bishop types it only after. Do NOT include a tech, a designation request, or any typing of a name.",
    "THE PAPER IS REAL AND READ FLAT, and CARRIES THE BAN CLAUSE: Reyes reads actual terms plain and whole - no charges, a doctor, nobody puts you anywhere (the mercy) AND, read the way it's put down with NO apology in it, that he is done flying for the rest of his life, never at the controls of anything again (the ban). Her only additions are small and human ('It's real. I'm holding it. It's in my hand right now.' register). No negotiator warmth; the technique is gone.",
    "BIRDY'S REFUSAL IS THE FILM'S GENTLEST AND MOST COMPLETE: genuinely MOVED ('you did that for me' register, no tears written); believes the PAPER and believes HER - the disbelief attaches ONLY to himself ('I just don't figure it's mine' register, no self-pity); he does NOT grieve the ban clause aloud (it only confirms his arithmetic); THE RUSSELL LAW ABSOLUTE - no death-talk, no darkness, no intention, no bargaining; a flat fuel callout under it.",
    "NOBODY ARGUES HIM OUT OF IT: Reyes's last push is SMALL and human, once ('there's a blank line with your name under it' register); his answer is gratitude ('that was real good of you. Thank you.' register); her understanding arrives as a HELD BEAT and a hand coming off the key - never a speech.",
    "BISHOP is stillness (physical beats only; no dialogue about the offer). THE CLOCK IS LOUD (the fuel number cited plainly at least twice); FULL DARK (panel and scopes the only light).",
    "ACTION LINES ARE FULL SENTENCES, PRESENT TENSE; ORIENT every voice; INTERCUT radar room and flight deck; the SECOND CHANNEL stays physical (the paper in her hand, the headset cord, the naked blip on the scope, the fuel number, Bishop's hand).",
    "END unresolved into the finale: the naked blip riding out over the black water, the fuel number, the room saying nothing. No button.",
    "Kill every catalog tell: doubled openers, engineered refrains, appended-fact fragments, list drumbeats, cross-character mirroring, summarizing Lines, thematic telegraphing, stated/implied turns, manufactured stammers, parallel restatement, trailing-'so.'. American vernacular. Recorded, not written.",
    "Voice-differentiate: REYES (stripped flat; the checklist truth incl. the ban clause; small human pushes), BIRDY (warm, moved, immovable; the courtesy formulas his own), BISHOP (stillness).",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=5)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: R3 v2 (ban clause; glass-crown removed to finale) ===\n")
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
