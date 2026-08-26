# V07 «THE TABLE TURNS» — defect record and reshoot brief

Shot 2026-08-26. Job `v07table`, SH125-127, seedance_2_0_mini, 15s, 37.5 credits. Delivered file `2026-08-26_V07_table-turns_v1.mp4`, 15.10s.

**Status: IN THE CUT, NOT APPROVED.** The author accepted it into the assembly on 2026-08-26 and will reshoot only if allowance remains at the end of the show. This file exists so the reshoot does not have to rediscover any of this.

## What the shot is for

The wide where the family registers what Вася has become. Its entire reason to exist is that the three adults react DIFFERENTLY — the author's note, 2026-08-25: "I feel like it would be weird if they all stared in disbelief, since I'm sure Grandma would not be in disbelief." Яга gave him the gift and knows exactly what she is looking at, so she is the one whose face does not fall. Папа carries the plain shock. Мама is not shocked at all — she is looking at her own face, which is what makes her eyebrow check read as CHECKING rather than as one more beat of astonishment.

## What worked and must be preserved in any reshoot

- The turn. Frame zero is the plate exactly; by 0.25s all three heads have come round. Fast, clean, no drift.
- Screen direction. Every face ends toward the camera. Nobody turns away, nobody shows the back of their head, no face leaves the picture.
- Eyeline height. The adults are level; only the babies look up. This came from the scale arithmetic (see the job record) and is correct.
- Папа's travel. He starts facing the left of frame as the plate has him and finishes square to the lens.
- The camera move. Wide hold, in on Мама, glide down to the rug — all three stages execute in one continuous move, no cuts, no zoom bumps.
- The eyebrow touch happens.
- The babies. Confusion, then delight, then both crawl off toward the camera and out at the bottom right. This whole passage is good and should be left alone.
- Nobody stands, nothing is knocked over, the light holds steady, the background never changes.

## DEFECT 1 — the three adults wear the same face. THIS IS THE ONE THAT MATTERS.

All three land on roughly the same expression: brows drawn up in the middle, mouths closed, mild worry. The differentiation that justifies the shot is absent. Яга in particular looks worried, which is the exact opposite of the note.

**Cause.** The creative described three distinct INTENTIONS but three overlapping sets of ANATOMY. "Brows shoot up and stay up" (Папа), "brows draw in a fraction and stay drawn" (Мама), "one eyebrow climbs and stays climbed" (Яга) are all eyebrow-raise instructions differing only in degree, and mini averaged them into one face.

**Fix.** Give each adult a physically unmistakable, NON-OVERLAPPING shape, and let the difference live in different parts of the face rather than in degrees of the same part:
- ПАПА — the MOUTH does the work. Wide open, held open for the whole shot, cup frozen at his beard. Do not describe his brows at all.
- ЯГА — the EYES and the CUP do the work. Eyes stay down on her cup through the turn and come up last and slow; she keeps drinking. Do not give her a brow instruction competing with Папа's.
- МАМА — the MOUTH CLOSED and the HAND do the work. See defect 2 for what not to say about her brows.

## DEFECT 2 — Мама reads angry, not unsettled.

In the close-up (about 6.0–9.0s) her brows are drawn DOWN and together in a scowl, and at 7.5s she presses her eyebrow like someone with a headache rather than checking it. She looks annoyed, verging on furious.

**Cause.** Three anger-adjacent instructions stacked in one paragraph: "her brows draw in a fraction and stay drawn", "the eyes narrow a little", "her jaw sets". Each is defensible alone; together they are a scowl. This is the same class of error as the V06 "closed and serious" note that produced a sad face.

**Fix.** Ban all three phrasings for her. Build her out of: mouth stays closed and lips soften rather than press; brows stay LEVEL and do not draw together; eyes stay wide open rather than narrowing; the hand comes up light and quick and the fingertips brush the brow rather than press it. The feeling is a woman privately checking something about her own face, not a woman disapproving.

## DEFECT 3 — Папа drinks.

At about 3.0s he drinks from his cup. The creative said twice that he never drinks and that the cup stays frozen halfway to his mouth. The instruction was in both the REACTIONS and HANDS blocks and lost anyway.

**Fix.** Probably needs the cup made part of the shock shape rather than a separate prohibition — e.g. the cup tips slightly in his hand as he forgets he is holding it. A positive action beats a prohibition. Note also that Яга's drink DID execute correctly, so a drink instruction is reliably followed; the failure is that a no-drink instruction is not.

## DEFECT 4 — the last second is an empty frame.

The babies exit around 13.5s and the final second holds on empty rug and furniture. Harmless in the cut because it will be trimmed, but a reshoot should either end earlier or give the camera somewhere to arrive.

## DEFECT 5 — the turn is nearly a cut.

Done inside a quarter of a second. Correct per the prompt ("snap round"), but on screen it reads as a jump rather than a movement. A reshoot could ask for the heads to come round over about half a second.

## Process notes for the reshoot

- The prompt ran at 9392 characters against a 9400 ceiling. There is no room to ADD instructions; anything new must displace something. The reshoot should budget for this and cut the descriptive passages first, never the locks.
- Bindings were correct and should be reused: start frame `2026-08-22_S8_SHOT1_table_start.png`, references page-08 (Папа), page-09 (Яга), page-07 (Мама), C-RUS-01, C-MUS-01.
- Вася-мама was deliberately not bound and never named. That worked — she never appeared in frame. Keep it.
- The five-pass self-review before submission caught six real defects (Папа's facing written as his-left; the babies' crawl direction contradicting the exit corner in three places; "still/stillness" for Мама; "faces blank" for the babies; Яга's drink mistimed to after the camera leaves; Мама's cup on the wrong hand). It did NOT catch defects 1 or 2, which are about anatomy COLLIDING ACROSS characters rather than about any single sentence being wrong. Add a pass that reads the reaction block character-by-character and asks: which facial part is doing the work for each one, and do any two of them use the same part?

## The gate that now enforces this (added 2026-08-26)

`assertEmotionsDeclared` in `studio/src/Drakosha_SeedanceDryRun.res`. Author's rule: every character description carries one or two words of actual emotion, and the choreography of the face after it has to match that emotion.

Syntax in the REACTIONS block:

```
Папа — SHOCK: starts mid-laugh … the mouth stays open but goes slack …
Бабушка-Яга — SATISFACTION: her eyes stay down on her cup … one eyebrow climbs …
```

The gate checks three things: that the emotion is declared; that it is a word the gate knows, since an unknown word has no anatomy to check against; and that the paragraph contains at least one piece of anatomy belonging to that emotion and none contradicting it. Contradictions are looked for only in the last third of the paragraph, because these paragraphs are journeys and the label names where the face ENDS. Negated phrases are ignored, so a negative lock like "her jaw never drops" does not fire.

It was verified against this exact shot before being switched on. Labelled with the emotions the shot intended — Папа SHOCK, Яга SATISFACTION, Мама UNEASE, Руся and Муся DELIGHT — the gate passes everyone except Мама, and fails her on "eyes narrow" and "jaw sets" as anatomy that ends on a different feeling than the one declared. That is precisely the defect that reached the screen.

**So the reshoot has a mechanical acceptance test.** Write Мама's paragraph so that it passes `UNEASE`, which means removing the narrowing eyes and the setting jaw and building her instead out of the anatomy UNEASE owns: mouth stays closed, lips close, brows stay level, eyes stay open and steady.

**Take `v07table` off `emotionGateGrandfathered` when the reshoot creative is written.** It sits on that list only because the delivered creative is bound by hash to the approval the author gave it, and editing delivered text to satisfy a later rule would falsify the record of what was actually sent. New text is new work and gets the new rule.
