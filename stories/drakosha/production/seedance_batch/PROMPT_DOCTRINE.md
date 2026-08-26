# Prompt doctrine — lessons paid for in credits (EP1, 2026-08)
1. CONCORDANCE RULE. When a job has a start image, the FIRST FRAME block must
   describe the APPROVED KEYFRAME AS IT ACTUALLY IS — never the script's ideal.
   Intent goes in the motion text. Any spatial claim the keyframe visibly fails
   = refire the keyframe or edit the claim; a disagreement never ships.
   (Cost of violating: job10 — папа wearing the present's cloth as a hood.)
2. ANCHOR RULE. Every prop is its own object with a stated position ("stands ON
   THE FLOOR at his left; the cloth touches nothing but the юла") — never
   defined only through a character's body ("behind his back", "over his
   shoulder"). Occlusion language becomes wearable-cloth hallucinations.
3. STALE-LANGUAGE SWEEP. Before emission, grep creative text against retired
   canon words (coat, plaster seam, stove flank, candy-wrapper, burly...);
   fossils gently steer the model toward dead designs.
4. DIALOGUE LOCK. Every spoken line: speaker on camera in that shot + explicit
   "only X's lips move ... no offscreen voices". (Cost: Вася speaking папа's
   line in папа's voice, batch 2.)
5. CAST/REFS ARE EMITTED, never hand-written — enforced by the emitter/gate.
   (Cost: the wrong мама, 52cr probe.)
6. DO NOT NAME WHAT YOU ARE HIDING. If a shot's whole plan is that no glyph is
   visible, the prompt must not call the objects letter tiles — naming them
   letters is an instruction to draw letters, in the one shot designed so that
   none exists. Call them wooden blocks. The same goes for binding @TILES, whose
   tagline says "each carved with one Cyrillic letter". (Author, 2026-08-24: "make
   sure you're not doing something stupid like telling the model that these are
   letter tiles.") This applies only where the faces are turned away; where the
   glyphs ARE in frame and in the plate, describing them is just concordance.

## 7. Name the feeling, then make the face agree with it

Every character in a REACTIONS block gets one or two words of actual emotion before their choreography, and the choreography has to match:

```
Папа — SHOCK: starts mid-laugh … the mouth falls open and stays open …
```

This is not a softening of rule 2. A mood on its own still loses to a reference sheet — that never changed. A mood PLUS the anatomy that produces it is strictly more than the anatomy alone, because it gives the anatomy something to be checked against.

The cost of not having it: v07table, 2026-08-26. Мама was meant to be quietly unsettled at seeing her own face. Her paragraph said her brows draw in, her eyes narrow and her jaw sets — each defensible alone, all three together an angry face — and she came back scowling. Nothing in the text was wrong sentence by sentence, and nothing said what she was supposed to be feeling, so there was nothing to catch it against.

And the reason the wide failed as a whole: three different intentions written as three overlapping sets of anatomy. "Brows shoot up", "brows draw in", "one eyebrow climbs" are the same instruction at three volumes, so the model averaged three characters into one worried face. **Differentiate by which PART of the face does the work, not by degrees of the same part.** Папа the mouth, Яга the eyes and her cup, Мама the closed mouth and the hand.

`assertEmotionsDeclared` enforces the naming and the agreement. It cannot enforce that the emotion is the RIGHT one for the story — code cannot know that Яга should not be astonished. That stays a human job.

## 8. Вася-мама moves like a small boy, always

The body is a grown woman's. Everything it does is a seven-year-old's. The mismatch is the entire joke, and it is the reason the transformation is funny rather than merely strange.

So in every shot she is in: jumping on the spot with both fists in the air, arms flailing loose from the shoulder, hopping, knees bent, stamping. Nothing controlled, nothing graceful, nothing adult. She never stands like a woman, never gestures like a woman, and never composes herself.

The author, 2026-08-26, correcting me on exactly this: "she's not a grown woman, she's Вася in mom's body, should behave exactly like a child." I had written that a grown woman bouncing would read wrong — which is backwards. A grown woman bouncing is the point.

Only her VOICE and her EYEBROWS are visibly Вася's. Everything else has to be carried by how the body moves, so the movement is doing the heavy lifting and must never be softened toward the adult silhouette the reference sheet shows.

## 9. Diff review, and approved language is immutable

The author cannot read every line of every revision, and should not have to. Two rules make invention detectable at a glance:

**Review is a diff.** A revised prompt reaches the author as changed lines only, each tagged with its source: the author's note, a plate, the script, or previously approved take language. A line with no source does not get written. (2026-08-26: "grabbing at the air" — source none — was invented during a hand-language edit and survived to review; under this rule it is one flagged line.)

**Approved language is only extended, never rewritten.** The v09 freeze was caused by replacing take 5's working motion words ("flap there for the whole shot") with new phrasing ("settle to the end image as the babies come off") while binding an end plate. Text that produced an approved result is immutable; a new requirement gets added around it. Replacement is where invention enters.

## 10. Dub words, never sounds

The model generates its own audio and it is frame-locked to the body it animated. Dubbing exists for one reason only: the model's Russian is gibberish, so recorded lines replace the words. Anything without words — laughing, crying, squealing, gasping, the babies' noise — stays exactly as the model made it. It is already in sync, and a recording never will be.

So the first question about any line is not how to dub it but how much of it is words. A line like «Ха-ха-ха! Ой, не могу! Ха-ха-ха!» is one second and a half of speech wrapped in five seconds of laughter, and only that second and a half gets replaced. Find the words inside the render by envelope shape: laughter runs at six to twelve envelope pulses a second in bursts under a fifth of a second, while a spoken phrase holds a vowel and runs two to three pulses a second across a whole second or more. The two do not look alike.

Level the replaced phrase to the laughter on either side of it rather than to full scale, or the dub jumps out of the performance it is sitting inside.
