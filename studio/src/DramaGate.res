/* DRAMA GATE - walks a story's typed spine (DramaCards) and BLOCKS
   (docs/08-DRAMA_GATES.md). Edge legality (no and-then) is already enforced
   at compile time; this gate checks what types alone cannot:
   FAIL: malformed premise, thin antithesis, unwritten mutual exclusion,
         opponent plan under three steps, flat fortune curve, shallow bottom
         (no all-is-lost), early minimum, stakes retreat, luck-caused rescue,
         climax without the antagonist acting, thin corkboard fields.
   warn: passivity census, antagonist-as-furniture, low BUT density,
         non-question forward questions, bottom on the final beat.
   Library only - runners register spines and call run. The human is the stop. */

let failed = ref(false)
let fail = msg => {
  failed := true
  Js.log("  FAIL  " ++ msg)
}
let warn = msg => Js.log("  warn  " ++ msg)
let ok = msg => Js.log("  ok    " ++ msg)

let thin = (s: string) => Js.String2.length(s) < 20

/* ---- Layer A: the ground truth ---- */
let checkTruth = (t: DramaCards.groundTruth) => {
  Js.log("- ground truth")
  if Js.String2.length(t.premise.x) < 12 || Js.String2.length(t.premise.y) < 12 {
    fail("premise malformed - Egri grammar is 'X leads to Y' with both X and Y substantive")
  } else {
    ok("premise: " ++ t.premise.x ++ " " ++ t.premise.leadsTo ++ " " ++ t.premise.y)
  }
  if thin(t.argument.claim) {
    fail("central dramatic argument is thin - it must be a claim someone could take the other side of")
  } else {
    ok("argument: " ++ t.argument.claim)
  }
  if thin(t.argument.antithesis) {
    fail("ANTITHESIS thin/missing - the other side gets its BEST case or the theme is a sermon")
  } else {
    ok("antithesis holds a real case")
  }
  if thin(t.designingPrinciple) {
    fail("designing principle thin - the one-line strategy that makes this telling original")
  }
  if thin(t.lighthouse) {
    fail("lighthouse scene missing - write the DNA scene FIRST, in prose (Gilroy)")
  }
  if thin(t.authorialStake) {
    fail("authorial stake thin - what does this risk saying that a safe version wouldn't?")
  }
  if thin(t.contestedObject.object_) {
    fail("contested object thin - the ONE thing hero and opponent are both fighting for")
  }
  if thin(t.contestedObject.whyBothCannotHave) {
    fail("mutual exclusion UNWRITTEN - if you cannot write why both cannot have it, they can, and you have no story")
  } else {
    ok("contested object: " ++ t.contestedObject.object_)
  }
  let planLen = Belt.Array.length(t.opponentPlan)
  if planLen < 3 {
    fail("opponent plan has " ++ Belt.Int.toString(planLen) ++ " steps (<3) - a villain who only reacts is the hero being kept safe")
  } else {
    ok("opponent plan: " ++ Belt.Int.toString(planLen) ++ " steps that succeed absent the hero")
  }
}

/* ---- Layers B+C: the spine ---- */
let checkSpine = (s: DramaCards.spine) => {
  let beats = s.beats
  let n = Belt.Array.length(beats)

  /* corkboard interrogation: every beat knows its want and its wall */
  Js.log("- corkboard (want/obstacle per beat)")
  if thin(s.opening.povWant) || thin(s.opening.obstacle) {
    fail("opening '" ++ s.opening.id ++ "' fails the corkboard - what is the POV character trying to get, and what stands against it?")
  }
  beats->Belt.Array.forEach(b => {
    if thin(b.povWant) || thin(b.obstacle) {
      fail("beat '" ++ b.id ++ "' fails the corkboard - thin want/obstacle")
    }
    if !Js.String2.includes(b.question, "?") {
      warn("beat '" ++ b.id ++ "' forward question is not a question")
    }
  })
  ok("all beats interrogated")

  /* fortune telemetry (Vonnegut) */
  Js.log("- fortune curve")
  let fortunes = Belt.Array.concat([s.opening.fortune], beats->Belt.Array.map(b => b.fortune))
  let hi = fortunes->Belt.Array.reduce(-5, (a, v) => v > a ? v : a)
  let lo = fortunes->Belt.Array.reduce(5, (a, v) => v < a ? v : a)
  let total = Belt.Array.length(fortunes)
  let loIdx = fortunes->Belt.Array.reduceWithIndex(0, (acc, v, i) =>
    v < Belt.Array.getExn(fortunes, acc) ? i : acc
  )
  if hi - lo < 6 {
    fail("FLAT fortune curve (spread " ++ Belt.Int.toString(hi - lo) ++ " < 6) - nothing is ever truly won or lost")
  } else {
    ok("fortune spread " ++ Belt.Int.toString(hi - lo) ++ " (" ++ Belt.Int.toString(lo) ++ ".." ++ Belt.Int.toString(hi) ++ ")")
  }
  if lo > -3 {
    fail("NO ALL-IS-LOST - the bottom is " ++ Belt.Int.toString(lo) ++ " (> -3): the hero is never truly hurt. Vonnegut: be a sadist")
  }
  if loIdx * 2 <= total {
    fail("the bottom lands EARLY (beat " ++ Belt.Int.toString(loIdx + 1) ++ " of " ++ Belt.Int.toString(total) ++ ") - the all-is-lost belongs near the second doorway")
  }
  if loIdx == total - 1 {
    warn("the bottom is the FINAL beat - no recovery, the swell has nothing to lift")
  }

  /* stakes monotonicity (McKee: never retreat) */
  Js.log("- stakes")
  let stakes = Belt.Array.concat([s.opening.stakes], beats->Belt.Array.map(b => b.stakes))
  let ids = Belt.Array.concat([s.opening.id], beats->Belt.Array.map(b => b.id))
  let retreated = ref(false)
  stakes->Belt.Array.forEachWithIndex((i, v) =>
    if i > 0 && v < Belt.Array.getExn(stakes, i - 1) {
      retreated := true
      fail("STAKES RETREAT at '" ++ Belt.Array.getExn(ids, i) ++ "' (" ++ Belt.Int.toString(Belt.Array.getExn(stakes, i - 1)) ++ " -> " ++ Belt.Int.toString(v) ++ ") - the threat may never shrink before the climax")
    }
  )
  if !retreated.contents {
    ok("stakes never retreat (" ++ Belt.Int.toString(Belt.Array.getExn(stakes, 0)) ++ " -> " ++ Belt.Int.toString(Belt.Array.getExn(stakes, Belt.Array.length(stakes) - 1)) ++ ")")
  }

  /* coincidence direction (Pixar 19) */
  Js.log("- causes")
  let prevFortune = ref(s.opening.fortune)
  beats->Belt.Array.forEach(b => {
    switch b.cause {
    | Coincidence =>
      if b.fortune > prevFortune.contents {
        fail("LUCK-CAUSED RESCUE at '" ++ b.id ++ "' - coincidence may get characters INTO trouble, never out")
      }
    | _ => ()
    }
    prevFortune := b.fortune
  })
  let protagCount = beats->Belt.Array.keep(b => b.cause == DramaCards.Protagonist)->Belt.Array.length
  if protagCount * 3 < n {
    warn("passivity census: protagonist causes only " ++ Belt.Int.toString(protagCount) ++ "/" ++ Belt.Int.toString(n) ++ " beats - a passenger, not a hero")
  } else {
    ok("protagonist causes " ++ Belt.Int.toString(protagCount) ++ "/" ++ Belt.Int.toString(n) ++ " beats")
  }
  let antagCount = beats->Belt.Array.keep(b => b.antagonistAction != None)->Belt.Array.length
  if antagCount * 4 < n {
    warn("antagonist-as-furniture: opposition acts in only " ++ Belt.Int.toString(antagCount) ++ "/" ++ Belt.Int.toString(n) ++ " beats")
  } else {
    ok("antagonist acts in " ++ Belt.Int.toString(antagCount) ++ "/" ++ Belt.Int.toString(n) ++ " beats")
  }
  let butCount = beats->Belt.Array.keep(b => b.edge == DramaCards.But)->Belt.Array.length
  if butCount * 4 < n {
    warn("low BUT density (" ++ Belt.Int.toString(butCount) ++ "/" ++ Belt.Int.toString(n) ++ ") - all-therefore is a straight line; where are the reversals?")
  }

  /* climax roll-call (McKee: Principle of Antagonism) */
  Js.log("- climax roll-call")
  switch beats->Belt.Array.getBy(b => b.id == s.climaxId) {
  | None => fail("climax beat '" ++ s.climaxId ++ "' not found in the spine")
  | Some(c) =>
    switch c.antagonistAction {
    | None => fail("CLIMAX WITHOUT THE ANTAGONIST - '" ++ c.id ++ "' has no opposition acting in it. Absence is a build error, not a style note")
    | Some(a) =>
      if thin(a) {
        fail("climax antagonist action is thin - what is the opposition DOING while the hero wins?")
      } else {
        ok("antagonist present and acting at the climax: " ++ a)
      }
    }
    let maxStakes = stakes->Belt.Array.reduce(0, (a, v) => v > a ? v : a)
    if c.stakes < maxStakes {
      warn("climax stakes (" ++ Belt.Int.toString(c.stakes) ++ ") below the story max (" ++ Belt.Int.toString(maxStakes) ++ ")")
    }
  }
}

/* ---- Layer D: the scene card (for the drafting stage) ---- */
let checkCard = (c: DramaCards.sceneCard) => {
  if thin(c.want) || thin(c.wall) || thin(c.cost) || thin(c.clock) {
    fail("card '" ++ c.scene ++ "': thin litmus field (want/wall/cost/clock) - Mamet's three questions are not answered")
  }
  if c.truthIn == c.truthOut {
    fail("card '" ++ c.scene ++ "': truthIn == truthOut - nothing happened (Mazin)")
  }
  if c.chargeIn == c.chargeOut {
    fail("card '" ++ c.scene ++ "': the value's charge never flips - a nonevent (McKee)")
  }
  if thin(c.audienceDelta) {
    fail("card '" ++ c.scene ++ "': empty audience ledger - what does the audience know NOW that it didn't?")
  }
}

let run = (s: DramaCards.spine): bool => {
  failed := false
  Js.log("DRAMA GATE on " ++ s.story)
  checkTruth(s.truth)
  checkSpine(s)
  if failed.contents {
    Js.log("DRAMA GATE: FAIL - " ++ s.story)
  } else {
    Js.log("DRAMA GATE: PASS - " ++ s.story ++ " (" ++ Belt.Int.toString(Belt.Array.length(s.beats) + 1) ++ " beats, truth held, curve alive, antagonist at the climax)")
  }
  !failed.contents
}
