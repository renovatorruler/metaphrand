"""The janitor story, encoded as a metaphor DAG and rendered to a screenplay.

Premise: a janitor discovers a dark secret of the university he works at.

This is the generation algorithm run top-down: root -> acts + themes ->
motifs (the cast vehicles) -> beats (the page-level leaves). Every beat hangs
under its act (structure) AND a motif or theme (meaning), so the graph is a
true DAG. Beat manifestations follow the Embodiment Rule (state the vehicle,
never the meaning) and carry screenplay hints in their attributes (scene
headings, dialogue) for the FountainRenderer.

Run with:  python -m examples.janitor
"""

from brehon import Story
from brehon.render import OutlineRenderer, FountainRenderer


def build() -> Story:
    s = Story()

    # -- ROOT: the controlling idea -------------------------------------
    root = s.three_act(
        "An institution stays clean only because someone is paid to "
        "carry away what it refuses to admit",
        id="three-act",
        title="The Night Shift",
        credit="written by",
        author="brehon",
        source="generated from a metaphor DAG",
        # Casting lives in the seed, so voice assignment is deterministic data.
        narrator_voice="af_heart",
        cast={"SUPERVISOR": "am_adam"},
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
        manifestation="At six, the last of them file out, and the building becomes "
        "WALT's.",
        attributes={"slug": "INT. PELL SCIENCE HALL - LOBBY - EVENING"},
        id="b-empty",
    )
    s.link(dark.id, "b-empty")

    s.instantiate(
        act1.id, "He is looked through", kind="beat",
        manifestation="He holds the door. Forty-one of them go through. "
        "The forty-second thanks the door.",
        id="b-door",
    )
    s.link(unseen.id, "b-door")

    s.instantiate(
        floor.id, "Pride in a surface no one notices", kind="beat",
        manifestation="He runs the buffer until the corridor comes up shining and "
        "his own face moves in the floor beneath him.",
        attributes={"slug": "INT. PELL SCIENCE HALL - MAIN CORRIDOR - NIGHT"},
        id="b-buff",
    )
    s.link(act1.id, "b-buff")

    s.instantiate(
        doors.id, "The names that count and the name that does not", kind="beat",
        manifestation="He passes the doors -- PELL, VANCE, HOLLOWAY -- cut into the "
        "stone above each one. Nowhere in the building is his own name cut into "
        "anything.",
        id="b-name-tape",
    )
    s.link(act1.id, "b-name-tape")

    s.instantiate(
        sealed.id, "Every door but one", kind="beat",
        manifestation="His ring opens every door in the building. One it does not: "
        "the wing posted for asbestos eight years ago and never touched.",
        attributes={"slug": "INT. PELL SCIENCE HALL - B-WING DOORS - NIGHT"},
        id="b-sealed-intro",
    )
    s.link(act1.id, "b-sealed-intro")
    s.link(keys.id, "b-sealed-intro")

    s.instantiate(
        act1.id, "Inciting: he is sent in", kind="beat",
        manifestation="The work order reads PREP B-WING FOR DEMO. Clipped beneath it "
        "is a key he has never been issued.",
        attributes={"slug": "INT. MAINTENANCE OFFICE - MORNING"},
        id="b-work-order",
    )
    s.link(sealed.id, "b-work-order")

    # -- ACT II BEATS ---------------------------------------------------
    s.instantiate(
        act2.id, "A room hidden inside a renovation", kind="beat",
        manifestation="Behind the new drywall, the old doorframe is still there, "
        "painted over. The floor inside is a fresh sheet of grey.",
        attributes={"slug": "INT. B-WING - SEALED LAB - NIGHT"},
        id="b-drywall",
    )
    s.link(buried.id, "b-drywall")

    s.instantiate(
        stain.id, "The thing he is paid to make disappear", kind="beat",
        manifestation="He has painted the floor three times. Each morning the dark "
        "comes back up through the newest grey, a little east of where he centered "
        "it.",
        id="b-stain-returns",
    )
    s.link(act2.id, "b-stain-returns")

    s.instantiate(
        mara_id.id, "The erased name surfaces", kind="beat",
        manifestation="The drain backs up. He reaches past the trap and lifts out a "
        "student ID, swollen, the photo still readable. The name under it is MARA "
        "OKAFOR.",
        id="b-drain",
    )
    s.link(act2.id, "b-drain")

    s.instantiate(
        stain.id, "Complicity: he was here before", kind="beat",
        manifestation="He knows the room by the way the mop drags. He worked it once, "
        "on overtime, signed for the hours, and never asked whose night it had been.",
        id="b-recognize",
    )
    s.link(act2.id, "b-recognize")

    s.instantiate(
        dirt.id, "The institution begins to clean him", kind="beat",
        manifestation="His supervisor finds him at the time clock, sets a hand on his "
        "shoulder, mentions a raise.",
        attributes={
            "slug": "INT. MAINTENANCE OFFICE - DAY",
            "character": "SUPERVISOR",
            "parenthetical": "easy, friendly",
            "dialogue": "Don't you worry about B-wing, Walt. Maintenance has that one "
            "covered now.",
        },
        id="b-cleaned-him",
    )
    s.link(act2.id, "b-cleaned-him")

    # -- ACT III BEATS --------------------------------------------------
    # The hinge: a leaf that points straight at the controlling idea,
    # the way the "magi" line does in O. Henry. Hence the link to root.
    s.instantiate(
        act3.id, "The choice: carry it away once more, or set it down", kind="beat",
        manifestation="He stands over the dark shape with the roller loaded. For a "
        "long time, he does not move.",
        attributes={"slug": "INT. B-WING - SEALED LAB - NIGHT"},
        id="b-choice",
    )
    s.link(root.id, "b-choice")

    s.instantiate(
        stain.id, "He stops cleaning", kind="beat",
        manifestation="He sets the roller down in the tray and leaves the floor the "
        "way it is.",
        id="b-stop-paint",
    )
    s.link(act3.id, "b-stop-paint")

    s.instantiate(
        dark.id, "He lets the truth stay visible", kind="beat",
        manifestation="On his way out, he leaves the wing's lights burning.",
        id="b-light",
    )
    s.link(act3.id, "b-light")

    s.instantiate(
        mara_id.id, "Payoff: he files her name where his own is kept", kind="beat",
        manifestation="He tapes MARA OKAFOR's ID to locker 12, beside the strip with "
        "his own name -- the only two names in the building no one paid to carve.",
        attributes={"slug": "INT. STAFF LOCKER ROOM - NIGHT"},
        id="b-tape-id",
    )
    s.link(act3.id, "b-tape-id")
    s.link(doors.id, "b-tape-id")

    s.instantiate(
        act3.id, "Cost: to refuse to carry refuse is to become it", kind="beat",
        manifestation="Two weeks later, they collect his keys at the gate.",
        attributes={"slug": "EXT. CAMPUS GATE - DAY"},
        id="b-cost",
    )
    s.link(unseen.id, "b-cost")

    s.instantiate(
        floor.id, "Payoff: he declines to disappear into the surface", kind="beat",
        manifestation="No one buffs that corridor again. The floor goes dull, and his "
        "face stops coming up in it.",
        attributes={"slug": "INT. PELL SCIENCE HALL - MAIN CORRIDOR - DAY"},
        id="b-final-floor",
    )
    s.link(act3.id, "b-final-floor")

    return s


if __name__ == "__main__":
    story = build()

    print("=== OUTLINE (the full DAG) ===\n")
    print(OutlineRenderer().render(story))
    print()
    print(
        f"{len(story)} metaphors, {len(story.leaves())} on the page, "
        f"{sum(len(story.parents(m.id)) > 1 for m in story.walk())} shared (multi-parent)"
    )

    print("\n=== SCREENPLAY (the structural spine, Fountain) ===\n")
    script = FountainRenderer().render(story)
    print(script)

    # The stored graph is the deterministic seed.
    reloaded = Story.from_json(story.to_json())
    assert reloaded.to_json() == story.to_json()
    assert FountainRenderer().render(reloaded) == script
    print("graph round-trips and re-renders identically ✓")

    story.save("stories/janitor.json")
    with open("stories/janitor.fountain", "w", encoding="utf-8") as handle:
        handle.write(script)
    print("saved -> stories/janitor.json, stories/janitor.fountain")
