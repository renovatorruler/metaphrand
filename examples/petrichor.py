"""PETRICHOR — the kids' film, encoded as a mirror-rooted seed.

The inversion of THE HEIR: the same mirror machinery run toward joy. The root
holds the transformation ("worst of both" -> "best of both"); its manifestation
is the midpoint scene where both worlds are held at once — the parents' secret
night garden. Doorway 1 = she volunteers for the Settling; doorway 2 = she
demands it. Every beat carries a Drama (want / cost / now). Pixar mode: the
beats are physical business, not speeches.

    python -m examples.petrichor
"""

from metaphrand import Story
from metaphrand.drama import Drama, attach
from metaphrand.pipeline import check


def build() -> Story:
    s = Story()
    root, before, after = s.mirror(
        "A girl who believes she is the worst combination of her parents' two "
        "bloodlines discovers she is the best of both",
        manifestation=(
            "Past midnight she follows soft thunder to the hidden corner: her "
            "mother raining gently in the dark over her father's unpruned wild "
            "patch, the two of them working together, practiced and easy — the "
            "only green thing left in the drought. An old wren's nest sits in "
            "the hedge above them. She backs away without a sound and pulls "
            "her braid tighter."
        ),
        previous="The girl who carries the suppression kit",
        next="The girl who runs the storm through the roots",
        title="Petrichor",
        credit="written by",
        author="metaphrand",
    )

    # -- BEFORE: the lie-world -------------------------------------------------
    s.instantiate(
        before.id, "the promise, planted as a love story", kind="beat", id="b-prologue",
        manifestation="Rain ends at the hedge-gap; two crowds disperse; one storm-woman "
        "and one garden-man stay, taking the smell in. Years later he tells the story at her "
        "bedside: that smell is why I spoke to your mother.",
        attributes={"slug": "EXT. THE HEDGE-GAP - YEARS AGO - DUSK",
                    "bond": "wren+her-parents", "deposit": "the smell"},
    )
    s.instantiate(
        before.id, "the suppression kit", kind="beat", id="b-kit",
        manifestation="She braids her hair flat to pin the weather down, pulls on her "
        "father's old gloves so nothing grows where she touches, and pockets the calm stone.",
        attributes={"slug": "INT. WREN'S ROOM - MORNING"},
    )
    s.instantiate(
        before.id, "the machine misfires in public", kind="beat", id="b-fair",
        manifestation="At the truce-day fair her micro-storm waters the brambles her own "
        "nerves sprouted; the stalls go down in wet thorns; each grandmother calls her by "
        "the other side's name.",
        attributes={"slug": "EXT. THE GRAFTING FAIR - DAY", "function": "inciting"},
    )
    s.instantiate(
        before.id, "she volunteers for the Settling", kind="beat", id="b-volunteer",
        manifestation="She puts her own name on the rite's slate and writes the equinox "
        "date beside it in her best handwriting.",
        attributes={"slug": "INT. THE MEETING BARN - NIGHT", "doorway": 1},
    )
    s.instantiate(
        before.id, "failing at halves", kind="beat", id="b-schools",
        manifestation="On the storm terraces her rain seeds a meadow through the clean "
        "stone; in the garden rows her one true calm bursts the topiary in an afternoon.",
        attributes={"slug": "EXT. BOTH TERRACES - WEEKS"},
    )

    s.instantiate(
        before.id, "the world at its own business", kind="beat", id="b-catchers",
        manifestation="Dawn queue at the rain-catchers: storm folk tip yesterday's mist "
        "into the shared barrel while weather-ribbon kites read the sky; across the wall "
        "the ration bell rings and garden folk mark their ledgers in pencil.",
        attributes={"slug": "EXT. BOTH SIDES OF THE WALL - DAWN"},
    )
    s.instantiate(
        before.id, "a creature that is also both", kind="beat", id="b-burr",
        manifestation="A tumbleweed blows over the wall mid-lesson, gets pitched back "
        "twice, and rolls home behind her anyway; she pulls it inside before the shears "
        "come out and names it Burr.",
        attributes={"slug": "EXT. THE GARDEN ROWS - DAY",
                    "bond": "wren+burr", "deposit": "kept time"},
    )

    # -- AFTER: through the mirror to the proof --------------------------------
    s.instantiate(
        after.id, "the secret detonates the family", kind="beat", id="b-split",
        manifestation="Her sprout-trail leads the grandmothers to the night garden by "
        "lantern light; by morning each has taken her own child home across the hedge.",
        attributes={"slug": "EXT. THE NIGHT GARDEN - DAWN",
                    "bond": "wren+her-parents", "wound": "the lanterns",
                    "blocks": "the way home"},
    )
    s.instantiate(
        after.id, "settle me now", kind="beat", id="b-demand",
        manifestation="On the dead fairground, in front of both crowds, she holds out "
        "the slate and says they can pick the side themselves.",
        attributes={"slug": "EXT. THE DEAD FAIRGROUND - DAY", "doorway": 2},
    )
    s.instantiate(
        after.id, "cured into emptiness", kind="beat", id="b-cured",
        manifestation="She makes a perfect small clear sky on command and both crowds "
        "applaud; the flower is gone from her hair, and the tumbleweed circles her "
        "twice, slows, and rolls away downhill.",
        attributes={"slug": "EXT. THE VILLAGE SQUARE - DAY", "function": "all is lost",
                    "bond": "wren+burr", "wound": "the unanswered knock",
                    "blocks": "the keeping of time"},
    )
    s.instantiate(
        after.id, "roots first, then rain", kind="beat", id="b-test",
        manifestation="In the dried riverbed between the two mobs she takes the gloves "
        "off, palms to the dead ground until the lattice grips, and then lets the braid "
        "come undone — and the roots hold the whole banked storm.",
        attributes={"slug": "EXT. THE RIVERBED - THE DUST-FRONT - DAY", "function": "climax"},
    )
    s.instantiate(
        after.id, "the smell rises and she is named", kind="beat", id="b-named",
        manifestation="Rain meets held earth and both mobs stop mid-shove and lift their faces into the smell; "
        "green rings out from the riverbed; the grandmothers start 'Squall—' 'Sprout—' "
        "and her parents say: her name is Wren.",
        attributes={"slug": "EXT. THE RIVERBED - GOLDEN DUSK", "function": "return",
                    "bond": "wren+her-parents", "thaw": "the smell",
                    "unlocks": "the way home"},
    )

    attach(s, {
        "mirror":      Drama("to unsee it and get back to bed unheard",
                             "the one green thing left, and her parents' hidden peace",
                             "their lantern is ten steps away and her sprouts are creeping toward the light"),
        "b-catchers":  Drama("both sides want yesterday's water to stretch one more week",
                             "the barrel line is longer every morning", "the catchers came up half-empty at dawn"),
        "b-burr":      Drama("to keep one creature that stays", "everything both-natured gets pitched back over the wall",
                             "the shears are already out for the weed"),
        "b-prologue":  Drama("to be the family the smell made", "the feud waits on both sides of the wall",
                             "the one evening rain ever fell on the gap"),
        "b-kit":       Drama("to get through one school day unnoticed", "every slip feeds both sides' verdict",
                             "the fair is tomorrow and everyone will be watching"),
        "b-fair":      Drama("to be applauded for one grown thing", "the truce day is the year's one chance",
                             "her storm is already curling over the stalls"),
        "b-volunteer": Drama("to belong somewhere whole", "half of herself, forever", "the slate closes at the equinox"),
        "b-schools":   Drama("to pass as one thing", "each grandmother is grading her blood",
                             "the equinox is weeks away and she has failed both tests"),
        "b-split":     Drama("to unsee what her trail uncovered", "her parents' peace, her own last shelter",
                             "the lanterns are already crossing the field"),
        "b-demand":    Drama("to stop being the feud's symbol", "the choice of side — surrendered too",
                             "both crowds are watching the slate in her hand"),
        "b-cured":     Drama("to feel the applause she earned", "the nothing where the both used to be",
                             "the tumbleweed is rolling away and she cannot care"),
        "b-test":      Drama("to hold still while the dust-front comes", "the valley's last water and both mobs' blood",
                             "the wall of dust is on the fields and the first stones are raised"),
        "b-named":     Drama("to hear her own name said out loud", "if the rain runs off, the war is tonight",
                             "the smell is rising while the crowds still hold their tools"),
    })
    return s


if __name__ == "__main__":
    print(check(build()).summary())
