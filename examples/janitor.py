"""The janitor story, encoded as a metaphor DAG.

Premise: a janitor discovers a dark secret of the university he works at.

This is the generation algorithm run top-down: root -> acts + themes ->
motifs (the cast vehicles) -> beats (the page-level leaves). Every beat hangs
under its act (structure) AND a motif or theme (meaning), so the graph is a
true DAG. Manifestations follow the Embodiment Rule: a leaf states only its
vehicle, never its meaning.

Run with:  python -m examples.janitor
"""

from brehon import Story
from brehon.render import OutlineRenderer


def build() -> Story:
    s = Story()

    # -- ROOT: the controlling idea -------------------------------------
    root = s.three_act(
        "An institution stays clean only because someone is paid to "
        "carry away what it refuses to admit",
        id="three-act",
    )

    # -- ACTS: the structural spine (children of the root) --------------
    act1 = s.instantiate(
        root.id,
        "Keeper of surfaces: the building belongs to him, and no one sees him",
        kind="act",
        id="act1",
    )
    act2 = s.instantiate(
        root.id,
        "The buried: sent behind the sealed door, his cleanliness was a cover",
        kind="act",
        id="act2",
    )
    act3 = s.instantiate(
        root.id,
        "The mirror: he was the mechanism, and he stops cleaning",
        kind="act",
        id="act3",
    )

    # -- THEMES: the abstract domains that must recur (children of root) -
    dirt = s.instantiate(root.id, "What will not come out", kind="theme", id="dirt")
    unseen = s.instantiate(
        root.id, "Looked through; the keys of the invisible", kind="theme", id="unseen"
    )
    buried = s.instantiate(
        root.id, "What is sealed away and discarded", kind="theme", id="buried"
    )
    dark = s.instantiate(
        root.id, "Truth is visible only on the night shift", kind="theme", id="dark"
    )
    names = s.instantiate(
        root.id, "Names carved, taped, or erased", kind="theme", id="names"
    )

    # -- MOTIFS: the cast vehicles (each shared across acts) ------------
    # The stain: dirt + buried at once, and the root's literal embodiment.
    stain = s.instantiate(
        dirt.id, "The dark that comes back through the paint", kind="motif", id="stain"
    )
    s.link(buried.id, stain.id)

    # The reflective floor: his pride in Act I, his refusal in Act III.
    floor = s.instantiate(
        dirt.id, "The floor you can see your face in", kind="motif", id="mirror-floor"
    )

    # Keys: access without belonging.
    keys = s.instantiate(
        unseen.id, "The keys of the invisible man", kind="motif", id="keys"
    )

    # The sealed wing: buried + unseen.
    sealed = s.instantiate(
        buried.id, "The one door his ring will not open", kind="motif", id="sealed-wing"
    )
    s.link(unseen.id, sealed.id)

    # Names over doors vs. the masking-tape name.
    doors = s.instantiate(
        names.id, "Donor names in stone; his own in masking tape", kind="motif",
        id="door-names",
    )

    # Mara's ID: the erased name made into an object; names + unseen.
    mara_id = s.instantiate(
        names.id, "The student ID with the erased name", kind="motif", id="mara-id"
    )
    s.link(unseen.id, mara_id.id)

    # -- ACT I BEATS ----------------------------------------------------
    s.instantiate(
        act1.id, "He has the building once the seen people leave", kind="beat",
        manifestation="At six the last of them filed out and the building became his.",
        id="b-empty",
    )
    s.link(dark.id, "b-empty")

    s.instantiate(
        act1.id, "He is looked through", kind="beat",
        manifestation="He held the door. Forty-one of them went through. "
        "The forty-second said thanks to the door.",
        id="b-door",
    )
    s.link(unseen.id, "b-door")

    s.instantiate(
        floor.id, "Pride in a surface no one notices", kind="beat",
        manifestation="He ran the buffer until the corridor came up shining and "
        "his own face moved in the floor beneath him.",
        id="b-buff",
    )
    s.link(act1.id, "b-buff")

    s.instantiate(
        doors.id, "The names that count and the name that does not", kind="beat",
        manifestation="Pell. Vance. Holloway, cut into the stone over each door. "
        "His own name was a strip of masking tape on locker 12, re-inked where it "
        "had worn.",
        id="b-name-tape",
    )
    s.link(act1.id, "b-name-tape")

    s.instantiate(
        sealed.id, "Every door but one", kind="beat",
        manifestation="His ring opened every door in the building. One it never "
        "opened: the wing they had posted for asbestos eight years ago and never "
        "touched.",
        id="b-sealed-intro",
    )
    s.link(act1.id, "b-sealed-intro")
    s.link(keys.id, "b-sealed-intro")

    s.instantiate(
        act1.id, "Inciting: he is sent in", kind="beat",
        manifestation="The work order said PREP B-WING FOR DEMO. Clipped beneath it "
        "was a key he had never been issued.",
        id="b-work-order",
    )
    s.link(sealed.id, "b-work-order")

    # -- ACT II BEATS ---------------------------------------------------
    s.instantiate(
        act2.id, "A room hidden inside a renovation", kind="beat",
        manifestation="Behind the new drywall the old doorframe was still there, "
        "painted over. The floor inside was a fresh sheet of grey.",
        id="b-drywall",
    )
    s.link(buried.id, "b-drywall")

    s.instantiate(
        stain.id, "The thing he is paid to make disappear", kind="beat",
        manifestation="He had painted the floor three times. Each morning the dark "
        "came back up through the newest grey, a little east of where he had "
        "centered it.",
        id="b-stain-returns",
    )
    s.link(act2.id, "b-stain-returns")

    s.instantiate(
        mara_id.id, "The erased name surfaces", kind="beat",
        manifestation="The drain backed up. He reached past the trap and brought out "
        "a student ID, swollen, the photo still readable. The name under it was "
        "Mara Okafor.",
        id="b-drain",
    )
    s.link(act2.id, "b-drain")

    s.instantiate(
        stain.id, "Complicity: he was here before", kind="beat",
        manifestation="He knew the room by the way the mop had dragged. He had worked "
        "it once, on overtime, signed for the hours, and never asked whose night it "
        "had been.",
        id="b-recognize",
    )
    s.link(act2.id, "b-recognize")

    s.instantiate(
        dirt.id, "The institution begins to clean him", kind="beat",
        manifestation="His supervisor put a hand on his shoulder, mentioned a raise, "
        "and said not to worry about B-wing. Maintenance had that one covered now.",
        id="b-cleaned-him",
    )
    s.link(act2.id, "b-cleaned-him")

    # -- ACT III BEATS --------------------------------------------------
    # The hinge: a leaf that points straight at the controlling idea,
    # the way the "magi" line does in O. Henry. Hence the link to root.
    s.instantiate(
        act3.id, "The choice: carry it away once more, or set it down", kind="beat",
        id="b-choice",
    )
    s.link(root.id, "b-choice")

    s.instantiate(
        stain.id, "He stops cleaning", kind="beat",
        manifestation="He set the roller down in the tray and left the floor the way "
        "it was.",
        id="b-stop-paint",
    )
    s.link(act3.id, "b-stop-paint")

    s.instantiate(
        dark.id, "He lets the truth stay visible", kind="beat",
        manifestation="On his way out he left the wing's lights burning.",
        id="b-light",
    )
    s.link(act3.id, "b-light")

    s.instantiate(
        mara_id.id, "Payoff: he files her name where his own is kept", kind="beat",
        manifestation="He taped Mara Okafor's ID to locker 12, beside the strip with "
        "his own name. The only two names in the building that had not been paid for.",
        id="b-tape-id",
    )
    s.link(act3.id, "b-tape-id")
    s.link(doors.id, "b-tape-id")

    s.instantiate(
        act3.id, "Cost: to refuse to carry refuse is to become it", kind="beat",
        manifestation="Two weeks later they collected his keys at the gate.",
        id="b-cost",
    )
    s.link(unseen.id, "b-cost")

    s.instantiate(
        floor.id, "Payoff: he declines to disappear into the surface", kind="beat",
        manifestation="He never buffed that corridor again. The floor went dull, and "
        "his face stopped coming up in it.",
        id="b-final-floor",
    )
    s.link(act3.id, "b-final-floor")

    return s


if __name__ == "__main__":
    story = build()
    print(OutlineRenderer().render(story))
    print()
    print(
        f"{len(story)} metaphors, {len(story.leaves())} on the page, "
        f"{sum(len(story.parents(m.id)) > 1 for m in story.walk())} shared (multi-parent)"
    )

    # The stored graph is the deterministic seed.
    reloaded = Story.from_json(story.to_json())
    assert reloaded.to_json() == story.to_json()
    print("graph round-trips deterministically ✓")

    story.save("stories/janitor.json")
    print("saved -> stories/janitor.json")
