"""The Ray seed — encoded as a managed beat sheet.

The program's output is a BEAT SHEET — the story's structure (the fifteen
Save-the-Cat beats, each at its page mark) — not a screenplay and not a scene
list. The data structure fixes the craft (the transformation, the mirror, the two
doorways, which beat fills which structural slot, the cast); ``to_beat_sheet``
renders it; an LLM hangs the scenes on it and owns the continuity and the words.

Run with:  python -m examples.ray
"""

from brehon import Story
from brehon.arrangement import frame
from brehon.dossier import Dossier, Fact, attach as attach_bibles
from brehon.prompt import to_beat_sheet
from brehon.world import (
    ALLY, GUARDIAN, HERALD, HERO, MENTOR, SHAPESHIFTER, TRICKSTER, Character, World,
)


def build() -> Story:
    s = Story()
    root, before, after = s.mirror(
        "A man who buried his warrior nature under words — and called his cowardice "
        "principle — is broken open by his brother's death and becomes the warrior he "
        "always was",
        manifestation="In the recruiting office, his father's loaded pistol in his coat, "
        "Ray sees his own steady hand on the gun in the door-glass, knows he is the "
        "warrior, and sets the gun down to sign the enlistment — taking his brother's slot.",
        previous="the word-warrior who calls his cowardice principle",
        next="the warrior, finally awake",
        title="Ray",
        narrator_voice="am_michael",
        cast={"RAY": "am_michael", "TOMMY": "am_eric", "RUTH": "af_sarah",
              "JUNE": "af_bella", "ANNIE": "af_nicole"},
    )

    # -- BEFORE: the word-warrior -------------------------------------
    s.instantiate(before.id, "Ray takes a man apart in a war argument while his fist, under the table, is white and shaking",
                  kind="beat", id="b-booth", attributes={"function": "Opening Image"})
    s.instantiate(before.id, "Young Tommy keeps walking back into a beating he can't win while young Ray watches from the porch",
                  kind="beat", id="b-creek", attributes={"function": "Set-Up"})
    s.instantiate(before.id, "Tommy, watching Ray win the room: 'You've got all the words, Ray. You just never had to use them'",
                  kind="beat", id="b-theme", attributes={"function": "Theme Stated", "character": "TOMMY", "dialogue": "yes"})
    s.instantiate(before.id, "Tommy sits at the kitchen table smoothing the folded Army enlistment paper flat under his thumb, over and over; he has already signed it",
                  kind="beat", id="b-catalyst", attributes={"function": "Catalyst", "character": "TOMMY", "dialogue": "yes"})
    s.instantiate(before.id, "Ray argues with every weapon he owns, all true; Tommy only says, 'I know all that, Ray,' and goes",
                  kind="beat", id="b-debate", attributes={"function": "Debate", "character": "TOMMY", "dialogue": "yes"})

    # -- FLESH: the town and the war, off Ray's line (subplot/texture) --
    s.instantiate(before.id, "Sully, turned away at the enlistment desk for a bad heart, pours the last round for the boys who passed and runs a tab he knows won't be paid",
                  kind="beat", id="b-sully")
    s.instantiate(before.id, "Kids with gym bags load into a van outside the strip-mall recruiting office, the only place still hiring in a county where the plant closed years ago",
                  kind="beat", id="b-depot")
    s.instantiate(before.id, "The man of all words sits to write his brother a letter, crumples three failed tries, and works the Zippo their father carried home from his war down into the packed duffel instead",
                  kind="beat", id="b-gift")
    s.instantiate(before.id, "The telegram: Tommy is dead, pointless, exactly as Ray swore — and Ray goes cold, not grieved",
                  kind="beat", id="b-telegram", attributes={"doorway": 1})

    # -- the MIRROR is the Midpoint (the recruiter's office) ----------

    # -- AFTER: the warrior awakened ----------------------------------
    s.instantiate(after.id, "Annie — Tommy's fiancee, the one woman who loved the warrior, not the talker",
                  kind="beat", id="b-bstory", attributes={"function": "B Story", "character": "ANNIE", "dialogue": "yes"})
    s.instantiate(after.id, "He loads his father's pistol and drives to find the recruiter who signed Tommy up",
                  kind="beat", id="b-fun", attributes={"function": "Fun and Games"})
    s.instantiate(after.id, "He ends it with June, who loved the safe man, and training grinds him toward the front",
                  kind="beat", id="b-close", attributes={"function": "Bad Guys Close In", "character": "JUNE", "dialogue": "yes"})

    # -- FLESH: the home front lives its own life while Ray is away --
    s.instantiate(after.id, "Ruth and Annie fold the dead boy's shirts into a box together, the mother and the girl he'd have married, the two left to outlive the warriors",
                  kind="beat", id="b-women")
    s.instantiate(after.id, "Ruth tends two graves now, Earl's and the boy's, side by side, and a gold-star flag hangs in her own front window",
                  kind="beat", id="b-graves")
    s.instantiate(after.id, "The plant at the edge of town sits dark and has for years; the recruiter's storefront is the one set of lights left on Main Street, and every kid knows the address",
                  kind="beat", id="b-mill")
    s.instantiate(after.id, "Annie goes back to the diner counter and pours coffee for the next boys shipping out, steady-eyed, the way she does everything",
                  kind="beat", id="b-annie-work")
    s.instantiate(after.id, "June marries the safe man after all, rice in her hair on the church steps, and does not look unhappy",
                  kind="beat", id="b-june")
    s.instantiate(after.id, "He ships out and the shooting starts — the test his life was built to dodge",
                  kind="beat", id="b-front", attributes={"doorway": 2})
    s.instantiate(after.id, "First firefight: Ray braces for the cold hands and the freeze, sure he's the coward he feared",
                  kind="beat", id="b-darknight", attributes={"function": "Dark Night of the Soul"})
    s.instantiate(after.id, "The cold hands never come; he's already moving — 'there you are' — the warrior wakes",
                  kind="beat", id="b-wake", attributes={"function": "Break into Three"})
    s.instantiate(after.id, "He moves under fire, hauls a pinned kid out of the open, holds the line — transfigured",
                  kind="beat", id="b-finale", attributes={"function": "Finale"})
    s.instantiate(after.id, "Home: a new kid runs Ray's old lines in the booth; Ray, nothing to prove, nods and walks out",
                  kind="beat", id="b-home", attributes={"function": "Final Image"})

    # -- CAST: the archetypal ensemble --------------------------------
    World([
        Character("ray", "RAY", HERO, "to be right, and above it all", "m"),
        Character("tommy", "TOMMY", HERALD, "to count for something, wordlessly", "m"),
        Character("earl", "EARL", MENTOR, "the warrior road already walked (he is dead)", "m"),
        Character("ruth", "RUTH", ALLY, "to hold a bloodline of warriors she keeps burying", "f"),
        Character("june", "JUNE", SHAPESHIFTER, "to keep the safe, clever man she fell for", "f"),
        Character("annie", "ANNIE", SHAPESHIFTER, "to love a living warrior, not a dead one", "f"),
        Character("sully", "SULLY", TRICKSTER, "to keep his friend in the booth beside him", "m"),
        Character("recruiter", "RECRUITER", GUARDIAN, "to fill a quota", "m"),
    ]).attach(s)

    # Backstory: the iceberg under each character (full bible in stories/ray_bible.md).
    # Fed to the prompt as "what you know, not say"; the leak gate guards the submerged.
    attach_bibles(s, [
        Dossier("EARL", [
            Fact("Came home from his war and didn't say four words a year for the rest of his life.", "surface"),
            Fact("Carried home a scratched-up Zippo he never once explained.", "surface"),
            Fact("At a hot LZ in Vietnam he froze in the door of the helicopter; a friend shoved past him to jump and was cut down on the skid, and Earl stepped off behind the body.", "submerged"),
            Fact("He believed to his grave the medal he was given belonged to that dead man, and the Zippo was the dead man's too.", "submerged"),
            Fact("The one war story he ever told -- the boat in, the dark, standing up into it -- he told the boy Tommy, and left out that he never stood up; the boy heard a hero where there was a confession.", "submerged"),
            Fact("Scorpio sun, Capricorn moon, Mars square Saturn -- the will and the brake welded together; couldn't stand the sound of a helicopter the rest of his life; carved soap animals and burned them before anyone saw.", "submerged"),
        ]),
        Dossier("RUTH", [
            Fact("Her hands never shake; she keeps two graves behind the church now.", "surface"),
            Fact("Earl told her the truth of the war once, drunk, the only time she ever saw him so; she has carried his shame alone for thirty years and never said a word, not even to the sons.", "submerged"),
            Fact("She lets Tommy march off chasing a hero who never existed because the truth would destroy the only piece of his father the boy owns.", "submerged"),
            Fact("Virgo sun, Scorpio moon -- the vault; can recite the kings of England in order, which has never once been required of her; guesses the killer by page forty and tells no one.", "submerged"),
        ]),
        Dossier("RAY", [
            Fact("When anything real is at stake his hands go cold and useless, so he learned to talk instead.", "surface"),
            Fact("He grew up under the father's silence, the war long over and the ghost long home, and decided as a boy, wordlessly, that war eats men and he would not be eaten.", "submerged"),
            Fact("He suspects the cold hands are his father's, inherited, and has spent forty years proving in arguments he always wins that his cowardice is a principle.", "submerged"),
            Fact("Gemini sun, Mars conjunct Saturn caged in the twelfth -- the warrior talked into a cage; county spelling champion who went out on 'necessary' at twelve; cried at a book age ten and hid it in the wall, where it still is.", "submerged"),
        ]),
        Dossier("TOMMY", [
            Fact("As a boy he walked back into beatings he couldn't win, again and again, grinning.", "surface"),
            Fact("Born after the war, he only knew the silent father and read the silence as strength; he built his whole self on the one war story, which he heard backwards.", "submerged"),
            Fact("He goes to war to become the hero his father never was, certain he is honoring the hero his father was.", "submerged"),
            Fact("Aries sun conjunct Mars, nothing in him brakes; could rebuild any engine in the county but couldn't spell; carried a buckeye for luck and named all his bantam hens.", "submerged"),
        ]),
        Dossier("ANNIE", [
            Fact("Steady-eyed; she decided a long time ago not to cry.", "surface"),
            Fact("Her own father shipped out and didn't come back; she loves the boys most likely to go, because leaving is the only love she trusts.", "submerged"),
        ]),
        Dossier("JUNE", [
            Fact("She wanted the safe life and picked the one man too smart to ever go.", "surface"),
            Fact("She lost a brother at seventeen to a fast car and a dare, and swore off the reckless kind; she built a future on Ray's cowardice, and it left her.", "submerged"),
        ]),
        Dossier("SULLY", [
            Fact("Turned back from this war 4-F, a bad heart; he pours the boys their last rounds.", "surface"),
            Fact("He has spent his life behind the bar watching other men become men, and never quite believes keeping the ones who go is its own kind of courage.", "submerged"),
        ]),
    ])

    # Arrangement: open on the death notice, flash back through the setup, and
    # return to it -- the audience knows Tommy is gone from the first scene, and
    # every beat of him enlisting is shadowed by it.
    frame(s, "b-telegram")
    return s


if __name__ == "__main__":
    print(to_beat_sheet(build()))
