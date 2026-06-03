"""A hand-written mirror-rooted story — the structure, crafted not generated.

The root IS the mirror moment: the transformation the story works on the reader,
its manifestation the mirror scene where both worlds are held at once. Its two
children are the world the keeper leaves (previous) and the world he becomes
(next); every beat hangs under one or the other. Read top to bottom it is a
transformation; rendered (previous -> mirror -> next) it is a screenplay, the
mirror landing at the hinge because the structure puts it there.

Nothing here is enforced. The journey shows through — an ordinary world, a
refusal that makes the cost felt, an emergence with the elixir — but as craft,
not a checklist. The ``function`` tags are notes to a writer, ignored by the
engine.

Run with:  python -m examples.mirror
"""

from brehon import Story, concreteness
from brehon.render import FountainRenderer, OutlineRenderer


def build() -> Story:
    s = Story()

    # The ROOT is the mirror: the transformation, and the scene that holds both
    # worlds at once — his hand on the crank, the log of twenty years, the beam
    # already on the rocks; he neither turns it nor lets go.
    root, before, after = s.mirror(
        "A man who keeps the machine running because he was told to becomes a "
        "man who stops it, though stopping costs him the only place he belongs",
        manifestation=(
            "He stands at the crank at three in the morning, one hand on the "
            "handle. The logbook lies open to twenty years of his own writing: "
            "LIGHT BURNING. SEA CLEAR. Through the glass the beam runs white and "
            "steady onto the Mason's Reef. He does not turn the handle. He does "
            "not let go of it."
        ),
        previous="The keeper who winds the light",
        next="The keeper who lets it go dark",
        title="Pell Light",
        credit="written by",
        author="brehon",
        narrator_voice="am_michael",
        cast={"FISHERMAN": "am_fenrir"},
        slug="INT. LANTERN ROOM - NIGHT",
    )

    # -- PREVIOUS STATE: the man who winds the light ------------------------
    s.instantiate(
        before.id, "His life is the maintenance of the machine", kind="beat",
        manifestation="At dusk he climbs the ninety-one steps, fills the oil, and "
        "winds the crank thirty-three turns. The light comes up. He writes the date.",
        attributes={"slug": "INT. PELL LIGHT - STAIRS - DUSK", "function": "ordinary world"},
        id="b-ritual",
    )
    s.instantiate(
        before.id, "No one comes; the light is all he is", kind="beat",
        manifestation="The supply boat leaves a sack of meal and a three-week-old "
        "newspaper on the bottom step and pushes off before he is down to take it.",
        attributes={"slug": "EXT. PELL LIGHT - JETTY - DAY", "function": "ordinary world"},
        id="b-supply",
    )
    s.instantiate(
        before.id, "The call: the light is not what he was told it was", kind="beat",
        manifestation="A fisherman mending net on the jetty will not take the rope "
        "from his hand.",
        attributes={
            "function": "call",
            "character": "FISHERMAN",
            "dialogue": "Twenty years I've rowed wide of your light. Ask the Mason's "
            "Reef why.",
        },
        id="b-fisherman",
    )
    s.instantiate(
        before.id, "Refusal: he sees the proof and keeps winding", kind="beat",
        manifestation="That night he lays the beam against the chart. It falls a "
        "thumb's width south of the channel, square on the reef. He closes the chart "
        "and winds the crank thirty-three turns.",
        attributes={"slug": "INT. PELL LIGHT - CHART TABLE - NIGHT", "function": "refusal"},
        id="b-chart",
    )

    # -- (the MIRROR, the root itself, falls here at the hinge) -------------

    # -- NEXT STATE: the man who lets it go dark ---------------------------
    s.instantiate(
        after.id, "He stops", kind="beat",
        manifestation="He takes his hand off the crank. The spring runs down. The "
        "lamp gutters and the beam pulls back across the water.",
        attributes={"slug": "INT. LANTERN ROOM - NIGHT", "function": "the turn"},
        id="b-stop",
    )
    s.instantiate(
        after.id, "The new world: he hears what the gears drowned", kind="beat",
        manifestation="For the first time in twenty years the tower is dark, and he "
        "hears the sea he could never hear over the gears.",
        attributes={"function": "emergence"},
        id="b-dark",
    )
    s.instantiate(
        after.id, "The elixir: a hull crosses the line and holds", kind="beat",
        manifestation="At first light a fishing boat crosses the line where the beam "
        "used to fall. It passes the reef and holds its course.",
        attributes={"slug": "EXT. THE REEF - DAWN", "function": "elixir"},
        id="b-boat",
    )
    s.instantiate(
        after.id, "The cost: he leaves the only place he belongs", kind="beat",
        manifestation="He leaves the logbook open to the last line, the ink still "
        "wet -- LIGHT OUT -- and goes down the ninety-one steps. He does not come "
        "back up.",
        attributes={"slug": "INT. PELL LIGHT - STAIRS - DAY", "function": "return"},
        id="b-leave",
    )

    return s


if __name__ == "__main__":
    story = build()

    print("=== OUTLINE (root = the mirror; two branches) ===\n")
    print(OutlineRenderer().render(story))

    rep = concreteness.annotate(story)
    print(f"\nconcreteness: {rep.summary()}")

    script = FountainRenderer().render(story)
    print("\n=== SCREENPLAY (previous -> mirror -> next) ===\n")
    print(script)

    story.save("stories/lighthouse.json")
    with open("stories/lighthouse.fountain", "w", encoding="utf-8") as handle:
        handle.write(script)
    print("saved -> stories/lighthouse.json, stories/lighthouse.fountain")
