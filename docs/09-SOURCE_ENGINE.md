# The Source Engine — where stories come from

*The missing half, named 2026-07-16. The gate suite (docs/08) is an immune
system: it kills known failure modes. It cannot create life. Constraint
satisfaction produces stories where every element serves the assignment — a
brochure — and no gate can lint a brochure into a story. Life comes from a
SOURCE that exists before any commission. This doc defines that source.
Operational today: the compost heap, the clarity judge, the human-reaction
gate. Designed, not yet built: the cast bank, the improv pass.*

## The diagnosis (why generated stories die)

1. **Everything load-bearing.** Generation by constraint satisfaction makes
   every element exist FOR the assignment. Living stories are full of things
   that exist because they are true or loved. Aliveness is the non-load-bearing
   residue; synthesis produces zero of it by construction.
2. **No source.** The pipeline starts at the commission. Human writers run on
   decades of accumulated real material with no use in mind, and feed
   commissions FROM the heap. Every time this project's work came alive, real
   material had entered it (Russell, the Wikipedia war, the r/Art coup);
   every time it died, it was synthesized whole.
3. **People after plot.** A person cast to fill a spine slot is a type.
   (The Lebowski law: Walter is John Milius, imported whole.)
4. **Nothing discovered.** Cards then execution; execution cannot be
   surprised; no surprise in the writer, none in the reader.
5. **Selection by gate, not appetite.** One candidate, linted — instead of
   many candidates, most killed by felt-sense before structure begins.

## Organ 1 — the compost heap (`stories/compost/`) — LIVE

A permanently growing corpus of REAL specifics, collected with no story in
mind. One file per entry, schema:

    # <title>
    kind: incident | person | image | line | fact
    date: <when it happened>
    source: <url / provenance — real, checkable>
    snag: <one line: why it hooks>

    <the specifics, plain — names, numbers, exact quotes>

Laws:
- **Real only.** Nothing invented may enter the heap. An entry without a
  checkable source is deleted, not kept.
- **Specific only.** "Mods abuse power" is not compost; "the r/Art protest
  removed every moderator" is.
- **The theft rule:** no story's ground truth is accepted until it cites
  entries the commission did not require — stolen grain, by receipt. (Wire
  into `DramaCards.groundTruth` when the next story starts.)
- **Foraging is a job:** research agents can be sent to harvest reality on a
  topic ("the five strangest true X"), each find entered with its source.
- `Compost.res` validates the heap (schema, source present, minimum
  specificity) and counts it.

## Organ 2 — the clarity judge (`Clarity.res`) — LIVE

The curiosity-not-confusion law (user, 2026-07-16): the reader must know WHO /
WHERE / WHAT at every moment; the only open questions are NEXT and WHY.
Withheld orientation is fog, not intrigue. The judge reads as a first-time
reader, must produce a one-sentence account of what happened, and flags every
moment it lost the WHO/WHERE/WHAT. Fog fails. Runs on scenes, pitches, and
summaries — anything a first-time reader will meet.

## Organ 3 — the human-reaction gate (`Judge.res`, HumanReaction) — LIVE

The named slot that sat empty. An ordinary viewer, not a critic: did you FEEL
anything; is anyone here a person you could describe to a friend; would you
keep watching for the people? Strict on close calls — a scene that maybe
moves nobody, moves nobody. Companion laws: stakes denominated in people;
the parable check (docs/08 — the argument must be able to lose).

## Organ 4 — the appetite pass (checklist now; mechanize later)

Premises are generated in BATCHES (through `Entropy.res`, which names each
slot's cliché and off-mode alternatives) and most are killed before any
structure is built. The lame-predictors, applied adversarially:
- Would you retell this at a dinner table tonight?
- Can you quote anyone in it?
- Does anything in it exist that the assignment did not require?
- Can the theme LOSE?
- One-sentence orientation: can a stranger say what it is after one hearing?

## Organ 5 — the Gauntlet (`Gauntlet.res`) — LIVE

Every text gate faces a permanent adversarial pair: the disease it hunts
(must FLAG) and a clean control (must PASS) — fixtures fossilized from real
user catches (the dead barn scene is fixture #1; the fog register; Russell's
real ATC exchange as the human-gate control). Hermetic, asserted, nonzero
exit on any miss. The mechanical section is free and always runs; the judge
section costs model calls and runs whenever a judge's prompt changes — a
prompt is code with tests now. Every future user catch gets fossilized as a
fixture the same day.

## Organ 6 — designed, not built

- **The cast bank:** people who exist before assignments (chart + voice +
  donor + wound), accumulated like compost; commissions get cast from the
  bank; at least one principal predates the story.
- **The improv pass:** between cards and the clean-room render — fast,
  ungated, in-voice improvisation to discover behavior; the good accidents
  are promoted into the cards; then the gated render proceeds.

## Credit

The user's laws, one week of rejections, and the working writer's oldest
tool: the notebook.
