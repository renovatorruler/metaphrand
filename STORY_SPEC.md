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

## 6 — Cinema (tell it in pictures)

- **Seen vs heard.** Every beat splits into what the audience SEES (its
  manifestation — action and image) and what it HEARS (dialogue). The SEEN track is
  load-bearing; dialogue is seasoning. *(Added.)*
- **Gate: modality.** The spine must be majority visual, with no run of more than
  two talking-heads beats, and the load-bearing beats (opening image, mirror,
  finale) must land for the eye. *(Added.)*
- **Gate: the silent spine (sound-off test).** Strip every word of dialogue and read
  only the images in order — the transformation must still be legible. A story that
  collapses with the sound off is a radio play, not a film. *(Added.)*
- **Modality is an arc.** The verbal/visual balance may move across the film: a story
  about the limits of words should grow quieter and more visual as the hero changes.
  *(Added.)*

---

## 7 — Density (flesh on the bones)

- **Bones vs flesh.** A premise is a few load-bearing bones, not a skeleton, and a
  skeleton is not an animal. Beats that carry a structural function (a Save-the-Cat
  beat, a doorway) are *bones*; everything else — subplot, texture, the living world —
  is *flesh*. *(Added.)*
- **Gate: anti-shrink-wrap.** A seed that is almost all bone has been shrink-wrapped:
  the thinnest story stretched over exactly the beats it was handed. The gate flags
  too-little-flesh and declared-but-undramatized wants (a character handed a want in
  the cast who never gets a beat of their own to pursue it). *(Added.)*
- **Necessary is per-layer.** "Cut the inessential" keeps the *A-spine* lean; this
  keeps the *world* deep. A subplot or a texture only has to be necessary to its own
  purpose, not to the A-plot. Shrink-wrap is a tight spine with no body; spectacle is
  a body with no spine; a story needs both. *(Added.)*
- **The flesh is the model's to grow.** The seed fixes the bones; the prompt mandates
  the flesh (`to_prompt`'s THE FLESH block); the gate only names the lack. *(Added.)*

---

## 8 — Backstory (the iceberg under each character)

- **Build the bible.** Every character carries a backstory the audience never
  learns: the wound, the ghost (often inherited), upbringing, want vs. need, the
  secret, the contradiction. The model skips this work unless made to do it. *(Added.)*
- **Surface vs. submerged.** Each fact is tagged: *surface* (shown in the story,
  never told) or *submerged* (informs only, never appears — what broke the father at
  Anzio). Most of the bible is submerged; its job is to exist. *(Added.)*
- **Feed it as "what you know, and must not say."** The bible is rendered into the
  prompt (`dossier.reference_block`) as context that shapes behaviour and choice and
  never becomes dialogue or narration — the model's habit is to exposit whatever it
  holds, so the discipline is explicit. *(Added.)*
- **Gate: no leaks.** After the draft, `dossier.leak` checks the script against the
  submerged set; any buried fact that surfaced as exposition is a leak, to cut or
  bury. Show the symptom; submerge the cause. *(Added.)*

---

## The data structure is a managed prompt

The graph is not a generator or a simulator — it is a **seed**: the deep
craft an LLM won't choose well on its own (the transformation, the mirror, the
two doorways, the meaning each beat must embody, the cast), held in an editable
structure and rendered to a *prompt* (`brehon.prompt.to_prompt`). The LLM grows
one coherent story from that prompt and **owns what it is good at** — continuity,
the physical world, the texture of a scene. The gates below then check only the
rules the LLM reliably breaks and the code can cleanly verify (show-not-tell,
concreteness, structure). What the code cannot cleanly fix, it does not try to.

## The pipeline (the gates the code owns)

1. **Aim** — the transformation signal.
2. **Spine** — mirror root + two branches + doorways + the test.
3. **World** — archetypal ensemble (clear the Fullness gate).
4. **Weave** — A / B threads.
5. **Metaphor** — concretize + embodiment check, per beat.
6. **Render** — active prose + the show-not-tell pass.
7. **Cinema** — the modality gate + the silent-spine (sound-off) round-trip.
8. **Density** — flesh on the bones: the anti-shrink-wrap gate (bones vs flesh, undramatized wants).
9. **Backstory** — the character bible: built, fed as "what you know, not say," gated for leaks.

The LLM is the worker inside each step. The steps, the order, and the gates are the
system.
