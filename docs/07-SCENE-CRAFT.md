# Scene Craft — The Mercurio Rubric

*The structured scene gate. Where `drama.py` (Mamet) asks "is this scene a fight?" and `showing.py` /
clear-pane ask "is it shown, not told?", this asks Jim Mercurio's question: **is each scene a complete
story that changes both the plot and a person?** Grounded in Mercurio, not paraphrase. Enforced by
`metaphrand/scene_craft.py` — a fixed rubric run by the local model, per-criterion, so a clean scene is
shown, not claimed.*

## The thesis (grounded)

> "The notion that a scene is a story in and of itself is not merely a clever paradigm; it is a
> fundamental truth." — Mercurio, *The Craft of Scene Writing* (2019), p. 24

A scene is **"a unit of storytelling defined by time and space, featuring a single action that causes
change in story and character."** Master the scene and you master the screenplay — the craft lives at the
micro level, not in the beat-sheet.

## The signature law — THE TWO CHANGES

Every scene must produce **both**:
1. a **plot change** — the external situation ends different from how it started; and
2. a **character change** — a person's inner state shifts, *caused by what they do in the scene.*

A scene with only a plot change is mechanics; only a character change is mood. The scenes that land
hardest carry **both at once** — a twist in the situation that is also a turn inside a person.

## The rubric (the gate's fixed criteria)

The local model judges each scene against these. CORE criteria fail the gate; the rest are flags to triage
(over-flagging is expected — the author's ear is the calibration; don't chase the score).

1. **single_action** *(core)* — one focused action, one time and place. Unity. *Violation:* two scenes
   fused, a meandering sequence, no single dramatic event.
2. **plot_change** *(core)* — the situation/value ends shifted from the open. *Violation:* nothing in the
   story moves; a static info or mood beat.
3. **character_change** *(core)* — a character's inner state shifts, caused by the scene's action.
   *Violation:* everyone ends inside exactly as they began. (Mercurio's signature; the one most scripts
   miss.)
4. **reversal** *(core)* — a surprise / directional shift, **set up** so it feels inevitable in hindsight
   and **rooted in character.** Per Bordwell, surprise is *a frustrated expectation:* establish the
   expectation, then plausibly break it. *Violation:* a frictionless straight line; the expected thing
   happens flatly.
5. **beats** — built of distinct, escalating beats, not one note repeated (the **Clurman Breakdown**:
   break the scene into beats; each should be actionable and varied). *Violation:* redundant beats, one
   emotional note held, no progression.
6. **escalation** — stakes and accountability rise; it is hard for the protagonist. *Violation:* ease; no
   mounting pressure; the hero gets it for free.

**Not in this gate (handled elsewhere — do not duplicate):** the fight — want / wall / cost / clock —
is `drama.py` (Mamet, `drama-enhancer`). Subtext / on-the-nose / talking-heads is `showing.py` + the
clear-pane skill. Mercurio's own subtext and "write cinematically" chapters live there; this gate stays on
his distinct contribution — the two changes, the set-up reversal, the beats.

## How it runs

`metaphrand/scene_craft.py` (`audit / report / gate`, like `naturalness.py`): split a script into scenes,
run the rubric per scene, emit a per-criterion verdict. A scene passes when all CORE criteria pass; the
flags feed the editor (`editor.py`) or the human, who is the stop.

## Credit & sources

Jim Mercurio, *The Craft of Scene Writing: Beat by Beat to a Better Script* (Quill Driver Books, 2019) —
the scene-as-story thesis, the two changes, the Clurman Breakdown (after stage director Harold Clurman),
reversals, and "14 Steps to a Better Screenplay." Surprise-as-frustrated-expectation after David Bordwell.
Value-charge lineage: Robert McKee, *Story*. Re-expressed here as a working rubric; the book is not
reproduced.
