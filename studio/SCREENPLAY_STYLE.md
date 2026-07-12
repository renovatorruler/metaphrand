# SCREENPLAY_STYLE — the action-line law (1883 register)

Source study: Taylor Sheridan, *1883* 1x01 pilot (user-supplied PDF, studied
2026-07-11) + *Yellowstone* 1x01 cross-check. The user's directive: "The
action lines themselves work to build the intrigue... when I'm reading it, I
know in my mind's eye I'm imagining the episode. We gotta write it exactly
like that." This file governs every scene the engine writes or lifts for
every screenplay in this studio, starting with THE FOUR OLDS v14.

The one-sentence version: **stop writing captions, start directing the
reader's eye.** A paragraph is a shot. The prose is hot, present-tense, and
sells the picture.

## The rules

1. **One paragraph = one shot.** 1–3 sentences. Never more than 4 typed
   lines. If a paragraph describes two things the camera can't hold at once,
   it's two paragraphs.

2. **Verbs lead. Fragments are legal.** The subject carries over from the
   previous beat and gets dropped: "Races toward it, leaps on the dead man."
   / "Blinking. Tears run from them."

3. **The pull and the cut.** End a beat with `...` when the scene keeps
   moving through it (the eye slides to the next line). End with `--` when
   the next image interrupts this one. These are the two connectives; use
   them constantly. Periods close a beat dead — save them for beats that
   should land dead.

4. **CAPS are detonations.** Three legal uses: a character's first
   appearance (`CRICKET DAWES(79)`); a sound that changes the scene (`THE
   THUNDER OF A GUN SHOT SHATTERS THE SILENCE.` / `BOOM.`); an object the
   frame must find (`THE PINK SHEET`). One detonation per beat, maximum.

5. **Sound gets its own line.** Never buried mid-paragraph.

6. **Mini-slugs steer instead of prose transitions.** `AT THE GRILL --`
   `WITH CRICKET --` `ANGLE ON --` `BACK WITH THE EYES --` Replace every
   "Meanwhile, across the room" construction with one.

7. **CAMERA is named only when the shot itself is the storytelling.**
   Sheridan: "CAMERA stares at an empty staircase as his footsteps echo,
   then silence ..." Once or twice a script. Otherwise the camera is
   implied.

8. **One muscular simile per beat, maximum — concrete and opinionated.**
   Sheridan's are earthy and load-bearing: "long and lean, like a young
   horse"; "fat is a rich man's jacket." Never decorative stacking, never a
   conceit the camera can't photograph around.

9. **Interior cues are legal when harnessed to an action.** "Takes a moment
   to find the strength to open it. Finds it, pushes open the door." Short,
   physical, then move.

10. **The author may editorialize in one hard line when it sells the
    moment.** "But it is impossible to look past the sadness." Earned,
    sparing — roughly once a scene, not once a paragraph.

11. **Dialogue stays spare.** The action lines carry the menace between the
    lines. When a dialogue scene is working, action shrinks to one-liners:
    "Wade pushes back from the table." / "James studies them. Says
    nothing ..."

12. **White space is pace.** If a page reads slow, break paragraphs, not
    sentences. A Sheridan page is half air.

13. **Sluglines carry place and date with double-dash separators** when it
    matters: `EXT. DAWES FARM -- BROKEN BOW, NEBRASKA -- MARCH.`

## Reconciliation with the clear-pane / plainness laws

These do not conflict; they divide territory:

- **Clear-pane still governs information.** Intrigue lives in events, never
  in withheld facts. The banned patterns stay banned: rule-of-three as
  rhythm, corrective definition ("that's not X, that's Y"),
  **information-rationing** fragments ("riders. Four. All black." — doling
  out facts about ONE image for suspense).
- **Sheridan fragments are shot-cuts, not rationing.** "Blinking. Tears run
  from them." = two images in sequence, each complete when stated. The test:
  does each fragment give the camera a NEW thing to look at? Shot-cut. Does
  it delay a fact about the SAME thing? Rationing — banned.
- **What changes is the voice**, not the honesty: the action prose stops
  being a neutral caption and becomes a present-tense selling voice — hot,
  imagistic, directive. The reader should feel the cut points.

## Before / after (THE FOUR OLDS, sc03 opening — the calibration example)

**Before (v13 — a caption in a block):**

> A work light on a beam. Filling half the barn: a real Apollo-era
> procedures trainer, NASA gray, the actual flight-article instrument panel,
> switches worn smooth, a few gauges swapped for parts Cricket machined
> himself after NASA stopped answering the phone. A genuine crew couch is
> bolted into a plywood-and-angle-iron cradle he welded to hold it. A single
> triangular window is cut into the nose. Behind the glass, taped flat
> across the wall: a hand-painted backdrop, ash-gray ground and hard black
> sky, a crater rim in the middle distance. Every label is hand-lettered.

**After (the register this studio writes in now):**

> Black. A pull-cord CLICKS -- a work light swings on its beam ...
>
> Filling half the barn: an APOLLO PROCEDURES TRAINER. The real thing. NASA
> gray, switches worn smooth as river stones ...
>
> Some gauges aren't factory. Machined by hand. Lettered by hand. Cricket
> built his own parts when NASA stopped answering the phone.
>
> A genuine crew couch, bolted into a welded cradle. Above it, one
> triangular window, cut into the nose.
>
> Through the glass: the Moon. Ash-gray ground, hard black sky, a crater
> rim. Painted on the barn wall by a man who has never seen it and never
> stopped looking ...
>
> ALONG THE BACK WALL --
>
> Shelves, floor to roof. Spiral notebooks. Hundreds. Every spine dated in
> the same block hand. The first shelf starts in 1972.

## Engine wiring

Every `Seed.sceneSeed` for screenplay work MUST carry a rule pointing here:
"Action lines per studio/SCREENPLAY_STYLE.md — one shot per paragraph,
fragments as shot-cuts, ellipsis-pull / dash-cut connectives, CAPS
detonations, mini-slugs, one simile max per beat, one editorial line per
scene." Follow-up engineering: teach `Write.liftDialogue`'s doctrine loader
to also load this file so the lift pass enforces it mechanically.
