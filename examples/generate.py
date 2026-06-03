"""Generate a screenplay from a one-line premise, end to end.

Runs the top-down algorithm for real: a premise becomes a metaphor DAG proposed
by a local open-source model (ollama), assembled deterministically into a Story,
then driven toward CONCRETE language — bare physical fact, not ornament — before
it is rendered to a Fountain screenplay. The graph is the stored seed; only the
wording is fuzzy, and its concreteness is measured at every step.

Run with:
    python -m examples.generate "A premise in one line"
    python -m examples.generate              # uses the default premise below
"""

import sys

from brehon import Story, concreteness
from brehon.generate import DagGenerator
from brehon.render import FountainRenderer, OutlineRenderer

DEFAULT_PREMISE = (
    "A lighthouse keeper discovers the light he tends was built to wreck ships, "
    "not to save them"
)


def _print_report(label: str, rep: "concreteness.ConcretenessReport") -> None:
    print(f"=== CONCRETENESS ({label}) ===")
    print(rep.summary())
    for node_id, found in rep.offenders:
        crimes = ", ".join(f"{f.kind}:{f.text}" for f in found)
        print(f"  ✗ {node_id}: {crimes}")
    print()


def main(argv: list[str]) -> None:
    premise = " ".join(argv).strip() or DEFAULT_PREMISE
    print(f"premise: {premise}\n")
    print("proposing the metaphor DAG via local ollama (first run loads the model)…\n")

    gen = DagGenerator()
    story = gen.generate(premise, concretize=False)  # the raw proposal
    _print_report("raw proposal", concreteness.report(story))

    print("concretizing ornamental beats into bare physical fact…\n")
    after = concreteness.concretize(story, gen.client, warnings=gen.warnings)
    _print_report("after concretize", after)
    for message in gen.warnings:
        print(f"[generate] {message}", file=sys.stderr)

    print("=== OUTLINE (the full DAG) ===\n")
    print(OutlineRenderer().render(story))
    print(
        f"\n{len(story)} metaphors, {len(story.leaves())} on the page, "
        f"{sum(len(story.parents(m.id)) > 1 for m in story.walk())} shared (multi-parent)"
    )

    script = FountainRenderer().render(story)
    print("\n=== SCREENPLAY (the structural spine, Fountain) ===\n")
    print(script)

    # The stored graph is the deterministic seed: round-trips byte-for-byte.
    assert Story.from_json(story.to_json()).to_json() == story.to_json()

    story.save("stories/generated.json")
    with open("stories/generated.fountain", "w", encoding="utf-8") as handle:
        handle.write(script)
    print("\nsaved -> stories/generated.json, stories/generated.fountain")


if __name__ == "__main__":
    main(sys.argv[1:])
