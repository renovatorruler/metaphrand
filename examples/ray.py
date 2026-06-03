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
    s.instantiate(before.id, "Boys line the depot with cardboard suitcases while the town's women and old men see them off, and blue-star flags go up in the front windows",
                  kind="beat", id="b-depot")
    s.instantiate(before.id, "The man of all words sits to write his brother a letter, crumples three failed tries, and works their dead father's Anzio lighter down into the packed duffel instead",
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
    s.instantiate(after.id, "The mill runs day and night on government contracts; the same women who buried the men assemble the shells the next ones will fire",
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

    # Arrangement: open on the death notice, flash back through the setup, and
    # return to it -- the audience knows Tommy is gone from the first scene, and
    # every beat of him enlisting is shadowed by it.
    frame(s, "b-telegram")
    return s


if __name__ == "__main__":
    print(to_beat_sheet(build()))
