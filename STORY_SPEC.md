# Story Spec

*What a story must satisfy — the grammar the brehon scaffolding encodes.*

This spec was derived empirically: we developed one story ("Ray") as a test rig, and
every place it broke we found a requirement. The story was never the deliverable —
**these requirements are.**

Governing principle: this is a **scaffolding the LLM uses, not LLM-based software.**
Each requirement below is a *pass, gate, or faculty* the system runs; the model only
fills bounded slots. Delete the model and the spec still stands — a person can satisfy
it by hand.

**Baseline (the original brehon model):** a DAG of metaphors, rooted at a three-act
"controlling premise," rendered by walking the spine; the graph is the source of truth,
words are a fuzzy layer. The layers below are how that has been *modified*.

---

## 0 — Aim (the why)

A story exists to take the reader's **ego consciousness** (Jungian) on a transformation:
to deliver, vicariously, an experience that changes them. **The hard part is
connection, not the change** — getting the ego to *board the ride* and take it as its
own. *(Modifies: replaces "controlling premise" as the root's purpose.)*

## 1 — Spine (the transformation skeleton)

- **Root = the mirror moment** (the transformation itself), with two children:
  **previous state** and **next state.** The render linearizes *previous → mirror →
  next*, so the mirror lands at the hinge by construction. *(Was: root = three-act premise.)*
- **Two doorways of no return.** End of Act 1: an irreversible event that locks the hero
  out of the ordinary world (no turning back = stakes). End of Act 2: the event that
  forces him into the test. *(Added.)*
- **Tested, not declared.** Act 3 forces the hero back into the exact arena he fled,
  transformed — proving the change, not announcing it. *(Added.)*
- **Connection machinery.** Campbell's early beats (ordinary world, call, refusal…)
  exist to get the ego to board; include by *function*, not as a rigid checklist. *(Added.)*

## 2 — Metaphor (the unit)

- **Jaynesian.** Every element is a metaphor: an abstract meaning (metaphrand) carried
  by a concrete thing (metaphier). Not simile, not ornament. *(Original, sharpened.)*
- **Concrete — faculty: the concreteness linter.** Manifestations are bare physical
  fact; ~0% flowery (no simile, purple verbs, abstract labels, markdown); concreteness
  is scored and tracked. *(Added.)*
- **Embodied — faculty: the legibility round-trip.** Concrete is necessary but not
  sufficient. The bare fact must *carry its meaning*: meaning → concrete → can the
  meaning be read back off the page? If not, it's a prop, not a metaphor. *(Added.)*
- **Altitude & names.** Work at core-story altitude (the dramatic engine — "Rocky
  fighting"), in plain common words. No invented-literary names. *(Added.)*

## 3 — World (the ensemble) — *the largest modification*

- **A story is a populated world, not the protagonist's spine.** *(Added.)*
- **Cast by archetype.** Build the ensemble from Hero's-Journey functions — mentor,
  ally, herald, shapeshifter / love-interest, threshold guardian, shadow — each a person
  with their own want and thread. *This is where the women come from.* *(Added.)*
- **Archetypal weight.** Character moves and relationship shifts must mean something in
  depth-psychology terms (e.g. taking the dead brother's betrothed = levirate /
  anima-shift / shadow), not a whim. *(Added.)*
- **Gate: Fullness.** Before pages: *is this a world or a corridor?* Where are the women?
  Who has a life that doesn't revolve around the hero? All-functional / all-male ⇒ not
  built yet. *(Added.)*

## 4 — Weave (the threads)

Run an **A-story braided with one or more B-stories** that refract the theme through
other people; the B-story usually carries the heart. Interleave the threads — never a
monorail. *(Added.)*

## 5 — Render (words on the page)

- **Active, not passive.** Tell it like a story — scene, momentum, voice, dramatic irony
  — not a flat AI summary / book report. *(Added.)*
- **Pass: show-not-tell.** Convert every *told* claim ("he's brave," "she was jealous")
  into a dramatized moment the reader concludes for themselves. *If it was worth telling,
  it's worth showing.* *(Added.)*
- **One protagonist.** Lock POV to whoever changes; the camera stays in his chest;
  everyone else is seen from his side. *(Added.)*

---

## The pipeline

Generating a story = running these in order, each gating the next:

1. **Aim** — the transformation signal.
2. **Spine** — mirror root + two branches + doorways + the test.
3. **World** — archetypal ensemble (clear the Fullness gate).
4. **Weave** — A / B threads.
5. **Metaphor** — concretize + embodiment check, per beat.
6. **Render** — active prose + the show-not-tell pass.

The LLM is the worker inside each step. The steps, the order, and the gates are the
system.
