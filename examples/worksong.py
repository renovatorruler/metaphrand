"""WORKSONG — the Ant & Grasshopper's kid, encoded as a mirror-rooted seed.

Sibling of examples/petrichor.py: the same mirror run toward joy, new world.
The root's manifestation is the midpoint — the foundation chamber where the
tally-marks turn out to be notation. Doorway 1 = she petitions for the Sealing;
doorway 2 = she demands it. Every beat carries a Drama; two beats are pure
world-flesh (the valley at its own business).

    python -m examples.worksong
"""

from metaphrand import Story
from metaphrand.drama import Drama, attach
from metaphrand.pipeline import check


def build() -> Story:
    s = Story()
    root, before, after = s.mirror(
        "A girl who believes she is the worst of ant and grasshopper "
        "discovers the two were one craft all along",
        manifestation=(
            "Floodwater has opened the lowest vault. Lantern up, she reads the "
            "foundation wall: tally-marks in rows — and the rows repeat in "
            "phrases, with rests, with a refrain. It is notation. The first "
            "granary was raised to songs. Carved at the cornerstone, three "
            "marks she has tapped her whole life without knowing why."
        ),
        previous="The girl who mutes herself to pass",
        next="The girl who strikes the count and lets it swing",
        bond="tala+reed", deposit="the three notes",
        title="Worksong",
        credit="written by",
        author="metaphrand",
    )

    # -- BEFORE: the lie-world ---------------------------------------------
    s.instantiate(
        before.id, "the fable performed, the father in the costume", kind="beat",
        id="b-pageant",
        manifestation="At the harvest pageant her father puts on the ragged "
        "grasshopper costume, begs at the painted door, dies in the paper snow, "
        "and bows to the colony's applause with his fiddle hidden under the rags.",
        attributes={"slug": "INT. THE GREAT GRANARY - HARVEST PAGEANT - NIGHT"},
    )
    s.instantiate(
        before.id, "the suppression kit", kind="beat", id="b-kit",
        manifestation="She winds the bindings over the spring in her legs, tucks "
        "wax in her cheek against the hum, and pockets her father's fiddle mute "
        "on the way to tally duty.",
        attributes={"slug": "INT. TALA'S ALCOVE - MORNING"},
    )
    s.instantiate(
        before.id, "the machine misfires in public", kind="beat", id="b-avalanche",
        manifestation="Halfway up the count her foot finds the offbeat; the tap "
        "travels up the stack; the grain pyramid lets go a tier at a time while "
        "the whole granary watches her hands keep conducting.",
        attributes={"slug": "INT. GRANARY FLOOR - TALLY DAY", "function": "inciting"},
    )
    s.instantiate(
        before.id, "the world at its own business", kind="beat", id="b-dairy",
        manifestation="Dawn at the aphid dairy: milkers work the rows while the "
        "dew-carts queue; across the valley the meadow camp hangs instruments "
        "out of the wet and argues about breakfast.",
        attributes={"slug": "EXT. THE VALLEY - DAWN"},
    )
    s.instantiate(
        before.id, "she petitions for the Sealing", kind="beat", id="b-petition",
        manifestation="She lays her tally-number token on Quern's desk and asks "
        "for the winter rite in front of the whole shift.",
        attributes={"slug": "INT. QUERN'S OFFICE - DAY", "doorway": 1},
    )
    s.instantiate(
        before.id, "failing at both halves", kind="beat", id="b-trials",
        manifestation="At the meadow jam she counts the band in out loud and the "
        "music stops dead; back in the tunnels her metronome heart syncopates "
        "the haul-chant and the line loses the load.",
        attributes={"slug": "EXT./INT. MEADOW AND TUNNELS - WEEKS"},
    )
    s.instantiate(
        before.id, "a creature that is also both", kind="beat", id="b-tick",
        manifestation="A hearth cricket the colony keeps shooing settles outside "
        "her alcove and keeps perfect time with her hidden foot until she lifts "
        "the curtain and lets him in.",
        attributes={"slug": "INT. TALA'S ALCOVE - NIGHT"},
    )

    # -- AFTER: through the mirror to the proof ------------------------------
    s.instantiate(
        after.id, "the flood and the blame", kind="beat", id="b-flood",
        manifestation="The storm takes the weakened sluice in the night; by noon "
        "the lower granaries are underwater, the refugee bands are marched to "
        "the valley mouth, and her father walks out with his people carrying "
        "the pageant costume.",
        attributes={"slug": "EXT. THE SLUICE GATES - STORM",
                    "bond": "tala+reed", "wound": "the costume carried out",
                    "blocks": "the duet"},
    )
    s.instantiate(
        after.id, "seal me now", kind="beat", id="b-demand",
        manifestation="On the flood-wrack she holds her number token over her "
        "head and asks for the rite today, in front of both crowds.",
        attributes={"slug": "EXT. THE GRANARY STEPS - DAY", "doorway": 2},
    )
    s.instantiate(
        after.id, "cured into emptiness", kind="beat", id="b-cured",
        manifestation="Her first perfect tally comes out flat as a ruled line and "
        "the granary applauds; that night the cricket cocks his head at her "
        "still foot, waits two bars, and hops off down the tunnel.",
        attributes={"slug": "INT. GRANARY FLOOR / HER ALCOVE - NIGHT",
                    "function": "all is lost"},
    )
    s.instantiate(
        after.id, "the count first, then the swing", kind="beat", id="b-test",
        manifestation="On the drum-boards between the colony wall and the "
        "camp of glass-going wings she strikes the plain count until the haul-lines fall "
        "in — then lets it lilt; the band catches it, the crowd breaks into "
        "crews, and the flooded grain comes up out of the water in time.",
        attributes={"slug": "EXT. THE VALLEY MOUTH - WINTER DAY", "function": "climax"},
    )
    s.instantiate(
        after.id, "the valley in one time, and her name", kind="beat", id="b-named",
        manifestation="Fiddle and tally-call trade verses over the work; the "
        "glass fades from the wings up and down the camp; at the re-staged pageant the "
        "colony hums three carved notes and she answers to them.",
        attributes={"slug": "INT. THE GREAT GRANARY - THE NEW PAGEANT - NIGHT",
                    "function": "return", "bond": "tala+reed",
                    "thaw": "the three notes", "unlocks": "the duet"},
    )

    attach(s, {
        "mirror":      Drama("to read the wall to the end before anyone comes",
                             "the colony's whole story of itself",
                             "her lantern is guttering and the watch is due"),
        "b-pageant":   Drama("to clap at the right times so nobody looks at her",
                             "her father's face under the rags",
                             "the pageant grasshopper is begging at the painted door"),
        "b-kit":       Drama("to pass one tally day as all ant",
                             "the spring in her legs gets one slip a season",
                             "tally day starts at the bell"),
        "b-avalanche": Drama("to hold the count to the top of the stack",
                             "the harvest ledger and the colony's eyes",
                             "her foot has already found the offbeat"),
        "b-dairy":     Drama("the dairy wants the dew in before the sun takes it",
                             "the carts are short-handed since the south burned",
                             "first light is on the rows"),
        "b-petition":  Drama("to belong to one ledger whole",
                             "half of herself, struck from the rolls",
                             "the Frost Tally closes the rite for the year"),
        "b-trials":    Drama("to pass as one thing in each world",
                             "each side is grading her blood",
                             "the frost is three weeks out and she has failed both"),
        "b-tick":      Drama("to keep one creature that keeps her time",
                             "the colony shoos what chirps",
                             "he is already at the curtain and the watch is coming"),
        "b-flood":     Drama("to reach the sluice before the surge does",
                             "the winter stores and the blame that follows them",
                             "the gate she weakened is groaning under the storm"),
        "b-demand":    Drama("to stop being the feud's evidence",
                             "even the choice of which half dies",
                             "both crowds are watching the token in her fist"),
        "b-cured":     Drama("to feel the applause she finally earned",
                             "the silence where the count used to swing",
                             "the cricket is waiting two bars at her door"),
        "b-test":      Drama("to hold the plain count while the shimmer spreads",
                             "the stores, the camp, and which one the winter takes",
                             "the wings at the valley mouth are going glass-bright"),
        "b-named":     Drama("to hear the colony say her name the only way it can be said",
                             "if the verse drops, the crews drop with it",
                             "the grain is still coming up and the frost is tonight"),
    })
    return s


if __name__ == "__main__":
    print(check(build()).summary())
