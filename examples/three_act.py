"""Build a tiny story graph to demonstrate the model.

Run with:  python -m examples.three_act
"""

from brehon import Story
from brehon.render import OutlineRenderer


def build() -> Story:
    story = Story()

    # The root: the most abstract metaphor of all. Its meaning is the story's
    # controlling premise.
    root = story.three_act("Love demands a death of the self")

    # The three acts instantiate the structure.
    setup = story.instantiate(root.id, "A self, intact and alone", kind="act")
    confront = story.instantiate(
        root.id, "The self is besieged by another", kind="act"
    )
    resolve = story.instantiate(
        root.id, "What is left after the self gives way", kind="act"
    )

    # A thematic metaphor that lives alongside the structure. It will share a
    # concrete beat with the structural spine (this is why we need a DAG).
    theme = story.instantiate(
        root.id, "Cold as the absence of another's warmth", kind="theme"
    )

    # The midpoint beat: a concrete, page-level metaphor.
    midpoint = story.instantiate(
        confront.id,
        "Her skin was cold",
        manifestation="She does not pull her hand away. Her skin is cold.",
        kind="beat",
    )

    # Shared metaphor: the same beat also instantiates the theme. One node,
    # two parents — the DAG at work.
    story.link(theme.id, midpoint.id)

    # A couple more leaves so the outline has shape.
    story.instantiate(
        setup.id,
        "A door that only opens inward",
        manifestation="He bolts the door from the inside, as he always does.",
        kind="image",
    )
    story.instantiate(
        resolve.id,
        "The bolt left undrawn",
        manifestation="The door stands open. He has stopped locking it.",
        kind="image",
    )

    return story


if __name__ == "__main__":
    story = build()
    print(OutlineRenderer().render(story))
    print()
    print(f"{len(story)} metaphors, {len(story.leaves())} on the page")

    # The stored graph is the deterministic core: round-trips byte-for-byte.
    reloaded = Story.from_json(story.to_json())
    assert reloaded.to_json() == story.to_json()
    print("graph round-trips deterministically ✓")
