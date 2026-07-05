"""INDIVISIBLE (working title) — the civil-war novel's spine as a mirror seed.

The whole book's skeleton (Part One drafted; Parts Two-Four outlined in
plotline-v1), so both doorways exist for the gate: D1 = the families hire Ray;
D2 = the manifest blown, flight becomes fight. The mirror is the midpoint
potluck — the parking-lot America they think is temporary. Bonds wired per the
heart ledger: deposits banked in Part One, wounds spent where the plot spends
them, thaws paid from the bank.

    python -m examples.civilwar
"""

from metaphrand import Story
from metaphrand.drama import Drama, attach
from metaphrand.pipeline import check


def build() -> Story:
    s = Story()
    root, before, after = s.mirror(
        "Families who pay to flee America become the Americans who stay",
        manifestation=(
            "One long table in the motel lot: seven pots, somebody's brisket "
            "defended with a raised fork, the chessboard reassembled mid-game "
            "under a work lamp, two kids up on the roof with a thermos and a "
            "flashlight. Nobody calls it anything."
        ),
        previous="The country sorting itself; the families buying the way out",
        next="The exits burned; the unsortables standing on one address",
        title="Indivisible",
        credit="written by",
        author="metaphrand",
    )

    # -- BEFORE: the sorting (Part One, drafted) -----------------------------
    s.instantiate(before.id, "the promise", kind="beat", id="b-estate",
                  manifestation="A Black family in period clothes bluffs four riders off a "
                  "plantation museum; a shot man is hidden in the root cellar; they shoot clear.")
    s.instantiate(before.id, "the marriage, banked", kind="beat", id="b-mugs",
                  manifestation="Two mugs of bad decaf on the porch rail at dusk, fifteen "
                  "minutes, her foot against his knee; that is the whole ceremony.",
                  attributes={"bond": "desmond+della", "deposit": "the two mugs"})
    s.instantiate(before.id, "the fence trade", kind="beat", id="b-fence",
                  manifestation="Banchan goes over the chain-link one way and foil-wrapped "
                  "cornbread the other, contraband both directions, never discussed at "
                  "either table.",
                  attributes={"bond": "min+nia", "deposit": "the fence trade"})
    s.instantiate(before.id, "the chessboard", kind="beat", id="b-board",
                  manifestation="Eleven years of Saturdays, the game never finished; both "
                  "men photograph the position before leaving it.",
                  attributes={"bond": "avram+sami", "deposit": "the chessboard"})
    s.instantiate(before.id, "registration day", kind="beat", id="b-pending",
                  manifestation="A bounce house at the registration site; the county-fair "
                  "thunk of a stamp; PENDING in purple ink, slantwise.")
    s.instantiate(before.id, "the world at the fair", kind="beat", id="b-fair",
                  manifestation="Green-vested volunteers hand out water bottles down the "
                  "line; kids go up and down in the bounce house while their parents hold "
                  "the forms.")
    s.instantiate(before.id, "the buses", kind="beat", id="b-buses",
                  manifestation="Counselors with first names carry an old man down his walk "
                  "in his recliner and put his slipper back on; the lawn furniture stays.",
                  attributes={"bond": "avram+sami", "wound": "packed mid-game",
                              "blocks": "the Saturday game"})
    s.instantiate(before.id, "the mugs go cold", kind="beat", id="b-cold",
                  manifestation="Three circular letters on the table; some nights now "
                  "the coffee goes cold untouched on the rail before the porch is over.",
                  attributes={"bond": "desmond+della", "wound": "the letters",
                              "blocks": "saying it out loud"})
    s.instantiate(before.id, "the card on the cabinet", kind="beat", id="b-hire",
                  manifestation="A notecard goes up under the magnet next to the spinach "
                  "recipe: a pilot's name, a strip past Bowie, a date eleven days out.",
                  attributes={"doorway": 1})

    # -- AFTER: the burn and the stand (Parts Two-Four, outlined) ------------
    s.instantiate(after.id, "the manifest blown", kind="beat", id="b-blown",
                  manifestation="The block-warden's logins are audited; he confesses at the "
                  "potluck table before the raid lands; the motel empties in ninety minutes "
                  "on a drilled plan.",
                  attributes={"doorway": 2, "bond": "min+nia", "wound": "the audit",
                              "blocks": "the fence"})
    s.instantiate(after.id, "the warning crosses the fence", kind="beat", id="b-warning",
                  manifestation="The manifest warning goes over the same chain-link the "
                  "cornbread used to, foil-wrapped, in the old spot at the old hour.",
                  attributes={"bond": "min+nia", "thaw": "the fence trade",
                              "unlocks": "the evacuation"})
    s.instantiate(after.id, "the board reassembled", kind="beat", id="b-reset",
                  manifestation="At the Wayfarer the chessboard comes out of the box marked "
                  "KITCHEN and is set from the phone photographs, mid-game, both men "
                  "checking each other's memory.",
                  attributes={"bond": "avram+sami", "thaw": "the chessboard",
                              "unlocks": "the Saturday game"})
    s.instantiate(after.id, "the stand", kind="beat", id="b-stand",
                  manifestation="The families take the motel back and defend one address "
                  "with lists, land titles, drilled wells, and a single empty low pass of "
                  "a Cessna; the cost of one motel becomes absurd on camera.")
    s.instantiate(after.id, "the compact", kind="beat", id="b-compact",
                  manifestation="A handwritten page of house rules and watch rotas, signed "
                  "by everyone who stays, goes under the front-desk glass next to a pair of "
                  "unused airline tickets.",
                  attributes={"bond": "desmond+della", "thaw": "the two mugs",
                              "unlocks": "saying it out loud"})

    attach(s, {
        "mirror":    Drama("everyone wants the evening to stay temporary",
                           "naming it would make staying a decision", "the buses run again Monday"),
        "b-estate":  Drama("to bluff four armed riders off the land",
                           "the man in the root cellar and the family upstairs", "the saddle is in plain view"),
        "b-mugs":    Drama("fifteen quiet minutes before the dishes",
                           "the day's dread is waiting just inside the door", "the sprinklers are already cycling"),
        "b-fence":   Drama("to keep the trade running without either house knowing",
                           "a mother's line and a father's clipboard", "the tub has to be back by Sunday"),
        "b-board":   Drama("to win without it ever finishing",
                           "the only hour neither man is a category", "the lunch rush lets go at one"),
        "b-pending": Drama("to get through the line as a family with nothing to explain",
                           "a stamp that has no end date", "the table is calling next"),
        "b-fair":    Drama("the volunteers want the line comfortable and moving",
                           "comfort is the mechanism", "the forms close at four"),
        "b-buses":   Drama("to load a street politely before noon",
                           "whatever does not fit the manifest", "the lift bus is behind schedule"),
        "b-cold":    Drama("to sit the porch like it is still a habit",
                           "admitting the season changed", "the third letter came today"),
        "b-hire":    Drama("to make the option live without making it a decision",
                           "eleven days to the airspace seal", "the magnet is in her hand"),
        "b-blown":   Drama("to confess before the raid makes it a discovery",
                           "the table he ate at all year", "the audit closed this morning"),
        "b-warning": Drama("to get the warning across without crossing the line",
                           "his mother's line, his father's lanyard", "the buses stage at dawn"),
        "b-reset":   Drama("to set the position exactly right",
                           "getting one square wrong would make it a new game", "the potluck starts at six"),
        "b-stand":   Drama("to make one motel cost more than it is worth taking",
                           "every name on the compact", "the enforcement convoy is on the access road"),
        "b-compact": Drama("to write the rules small enough to keep",
                           "signing means the wayfaring is over", "the ink is drying under the glass"),
    })
    return s


if __name__ == "__main__":
    print(check(build()).summary())
