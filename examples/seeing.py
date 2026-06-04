"""THE SEEING — the undercover/cult story, encoded as a managed beat sheet.

An undercover cop with no self of his own is sent into a cult that promises to make
its members famous artists, and can't tell anymore which of his selves is the cover.
Tone: a deadpan tragicomedy in the key of *Patriot* (the flesh carries that).
The data structure fixes the deep craft (the transformation, the mirror, the two
doorways, which beat fills which slot, the cast, the submerged backstory) and hands
the rest — the flesh, the continuity, the words — to the writer.

Run with:  python -m examples.seeing
"""

from brehon import Story
from brehon.arrangement import frame
from brehon.dossier import Dossier, Fact, attach as attach_bibles
from brehon.prompt import to_beat_sheet
from brehon.world import (
    ALLY, GUARDIAN, HERALD, HERO, MENTOR, SHADOW, SHAPESHIFTER, TRICKSTER,
    Character, World,
)


def build() -> Story:
    s = Story()
    root, before, after = s.mirror(
        "A man who dissolved himself into his function until there was no self left to "
        "leak -- a professional nobody -- is handed a self by people who are lying to "
        "him, and has to decide, with the law screaming in his ear, whether the truest "
        "thing he ever made was a con or a confession",
        manifestation="At the Collective's rebirth rite, told to burn the man who "
        "couldn't and make the truest thing he has in front of them all, the cop who "
        "came to perform sincerity makes something real, and cannot tell afterward "
        "whether he conned them or confessed.",
        previous="the professional nobody, emptiness wearing competence",
        next="the man who found a self, and what it cost him",
        title="THE SEEING",
        narrator_voice="am_adam",
        cast={"DANNY": "am_michael", "MARSH": "am_onyx", "NORA": "af_sarah",
              "ELI": "am_liam", "REYES": "af_kore", "PRIYA": "af_bella",
              "COWAN": "am_puck", "AUGUST": "am_echo", "BRENNAN": "am_fenrir"},
    )

    # -- BEFORE the rite: the empty man, seen, and seduced ------------
    # Everything up to the Midpoint lives here, so the spine is genuinely
    # chronological and a cold open on the rite flashes back through all of it.
    s.instantiate(before.id, "Danny runs a con to its clean end, shakes the mark's hand under a name that isn't his, then sits alone in a sublet that isn't his either, with nothing left to be",
                  kind="beat", id="b-cover", attributes={"function": "Opening Image"})
    s.instantiate(before.id, "Reyes slides the cult file across the desk and tells him he's perfect for it: there's nothing of him to get in the way",
                  kind="beat", id="b-theme", attributes={"function": "Theme Stated", "character": "REYES", "dialogue": "yes"})
    s.instantiate(before.id, "The eaten life on the counter: an ex-wife's number he won't dial, a roll of film he never develops, a letter from a kid he put away that he leaves unanswered",
                  kind="beat", id="b-empty", attributes={"function": "Set-Up"})
    s.instantiate(before.id, "Eli comes out of the river under a tarp; the ruling reads suicide; his sister won't sign it and badgers the city until a detective is handed the file",
                  kind="beat", id="b-river")  # flesh: the case
    s.instantiate(before.id, "A letter to the cover name, from a kid doing eleven years on Danny's word, sits on the counter asking when Danny is getting out",
                  kind="beat", id="b-petey")  # flesh: the cost of the job
    s.instantiate(before.id, "Danny comes inside the Collective; they circle him for the Seeing and name, one by one, the man they say is in there, and he stays in the chair",
                  kind="beat", id="b-inside", attributes={"function": "Catalyst"})
    s.instantiate(before.id, "He tells himself it's the job; he reports a little less each week, stays a little later, and starts sleeping at the loft",
                  kind="beat", id="b-debate", attributes={"function": "Debate"})
    s.instantiate(before.id, "Danny stands at Brennan's grave, the handler who raised him on the job and told him once that the gift was also the wound, and one day he'd have to choose",
                  kind="beat", id="b-brennan")  # flesh: the dead mentor
    s.instantiate(before.id, "The cover puts a pencil in his hand for the first time in thirty years; he makes one true thing, they hang it on the wall, and he doesn't go home",
                  kind="beat", id="b-firsttrue", attributes={"doorway": 1})
    s.instantiate(before.id, "Nora corners him outside the gallery with her brother's unmailed letters; she's after the truth, and she'll take nothing performed, which no one has ever asked of him before",
                  kind="beat", id="b-nora", attributes={"function": "B Story", "character": "NORA", "dialogue": "yes"})
    s.instantiate(before.id, "Deeper in: the work, the table they keep for him, Marsh walking him through the loft with a hand on his shoulder, the badge's calls going to voicemail, the cover no longer coming off at the door",
                  kind="beat", id="b-fun", attributes={"function": "Fun and Games"})
    s.instantiate(before.id, "The machine runs in plain sight: members sign their savings over as patronage, the gallery launders it, and the work leaves the building under Marsh's name and comes back as money",
                  kind="beat", id="b-money")  # flesh: the economics
    s.instantiate(before.id, "Priya, twenty and gifted, takes the chair at the center of the Seeing, the chair Eli sat in four years back, and lets them name the great one she is going to be",
                  kind="beat", id="b-priya")  # flesh: the clock starts
    s.instantiate(before.id, "August, a dentist who sold his practice to come inside, breaks down in the circle as they tell him he was never ordinary, and writes another check",
                  kind="beat", id="b-august")  # flesh: the world's daily life

    # -- the MIRROR is the Midpoint: DANNY'S rite (con or confession?) -

    # -- AFTER the rite: the consequences, and the test --------------
    s.instantiate(after.id, "A buyer shakes Eli's photograph and calls him Marsh's assistant; Danny pulls the thread and finds the dead boy's paintings sold for years under Marsh's name, and Priya already in the chair to be next",
                  kind="beat", id="b-truth", attributes={"function": "Bad Guys Close In"})
    s.instantiate(after.id, "Cowan keeps the second set of books and handles the members who crack; he clocks the cop in Danny before anyone else and starts watching the doors",
                  kind="beat", id="b-cowan")  # flesh: suspicion mounts
    s.instantiate(after.id, "Danny drives past the house that used to be his, his ex-wife's car in the drive of a life that went on without him, and doesn't slow down",
                  kind="beat", id="b-maria")  # flesh: the cost
    s.instantiate(after.id, "Reyes tapes the wire to his chest: walk in on the night they rebirth Priya, give her Marsh, burn it down -- and to keep a badge that was never any realer, he has to torch the only self that was ever his",
                  kind="beat", id="b-wire", attributes={"doorway": 2})
    s.instantiate(after.id, "Alone in the apartment that was never his, the wire on the table between his two phones, he cannot say which of the two men it would be taped to; the gift pulling him under is the exact gift that put Eli in the river",
                  kind="beat", id="b-abyss", attributes={"function": "Dark Night of the Soul"})
    s.instantiate(after.id, "The one question that always stopped him cold; at the kitchen table at four in the morning, the wire and the badge laid out in front of him, he says the answer out loud for the first time in his life",
                  kind="beat", id="b-what", attributes={"function": "Break into Three"})
    s.instantiate(after.id, "Priya's rebirth rite, Danny wired to hand Reyes the leader: instead he steps into the circle, pulls Priya out before the machine closes on her, and burns the whole con down with his own name on the record",
                  kind="beat", id="b-finale", attributes={"function": "Finale"})
    s.instantiate(after.id, "Months on, Danny develops the roll of film at last; in the prints stands a man who is finally somewhere, and across a diner table Nora looks at him and sees him plain",
                  kind="beat", id="b-final", attributes={"function": "Final Image"})

    # -- CAST: the archetypal ensemble --------------------------------
    World([
        Character("danny", "DANNY", HERO, "to stay no one, in clean and out clean", "m"),
        Character("marsh", "MARSH", SHADOW, "to confer the greatness he was denied", "m"),
        Character("nora", "NORA", ALLY, "to make someone admit what really happened to her brother", "f"),
        Character("eli", "ELI", HERALD, "to have been seen all the way down (he is dead)", "m"),
        Character("reyes", "REYES", GUARDIAN, "to keep the badge a real self, and her officer on the right side of it", "f"),
        Character("priya", "PRIYA", SHAPESHIFTER, "to be the great one they promised her", "f"),
        Character("brennan", "BRENNAN", MENTOR, "the road already walked: the gift is the wound (he is dead)", "m"),
        Character("cowan", "COWAN", TRICKSTER, "to keep the Collective's secrets and his place in it", "m"),
        Character("august", "AUGUST", ALLY, "to not have been ordinary", "m"),
    ]).attach(s)

    # -- BACKSTORY: the iceberg (full bible in stories/seeing_bible.md) --
    attach_bibles(s, [
        Dossier("DANNY", [
            Fact("Black coffee he lets go cold, eats standing up, sleeps fine in a stranger's bed and not in his own.", "surface"),
            Fact("Four foster houses by fifteen; learned to read a new house in an afternoon and become the kid it wanted; never unpacked the bag.", "submerged"),
            Fact("Drew as a boy to disappear into the page; a teacher said he vanished into a page the way other kids vanish out a door, and he stopped the next day, because being seen was worse than being hit.", "submerged"),
            Fact("Took undercover work for the self-erasure, not despite it; suspects there is no one under the covers and cannot look at the suspicion.", "submerged"),
            Fact("Pisces sun, Gemini moon, Scorpio rising, Sun conjunct Neptune -- the self that dissolves when he reaches for it; a kid named Petey does eleven years on his word and writes to the cover name.", "submerged"),
        ]),
        Dossier("MARSH", [
            Fact("Paint under his nails each morning from a tube he never otherwise opens.", "surface"),
            Fact("A real young painter once, ended by a critic in four sentences he can still recite, outdone by a rival who couldn't draw; built the Collective because he could not be let in the gate.", "submerged"),
            Fact("Sells the members' work under his own name and calls it tuition; tells them their fame is ripening out of the light.", "submerged"),
            Fact("Recognizes Danny on sight as another empty one, the only kind who really understands the offer; he is courting a mirror, not conning a mark.", "submerged"),
            Fact("Loved Eli, and went down to the river alone every week for a month after, at the hour the boy went in.", "submerged"),
        ]),
        Dossier("ELI", [
            Fact("A gifted painter, twenty-three, no family but the Collective; ruled a suicide, pulled from the river.", "surface"),
            Fact("He was the proof the others were sold on; his paintings left the building under Marsh's name for four years while he was told his hour was coming.", "submerged"),
            Fact("A buyer called him Marsh's assistant, the floor went out, and the self the Collective built him died, and the boy with it.", "submerged"),
        ]),
        Dossier("NORA", [
            Fact("Night-shift x-ray tech; reads bones for a living and trusts what's there over what people swear.", "surface"),
            Fact("Raised Eli after their mother left, signed him into the class that became the cult, and will not forgive herself; keeps his unmailed letters in a coffee can.", "submerged"),
            Fact("She is the only one who loved Eli for himself and not the promise -- the real version of the thing the cult forges.", "submerged"),
        ]),
        Dossier("REYES", [
            Fact("Twenty-two years on the job, a pension she can taste, a daughter at the academy.", "surface"),
            Fact("Believes the badge is a real self you can put on and have it be true -- the law as its own cult, and she its truest member.", "submerged"),
        ]),
    ])

    # Arrangement: open cold on the rite -- the question incarnate (con or
    # confession?). Flash back through the whole first half (which reveals the man
    # is a cop), return to the rite at the Midpoint, then let the second half -- the
    # truth, the wire, the second rite -- detonate it.
    frame(s, root.id)
    return s


if __name__ == "__main__":
    print(to_beat_sheet(build()))
