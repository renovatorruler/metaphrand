"""The Ray seed — encoded as a managed beat sheet.

The program's output is a BEAT SHEET, not a screenplay. The data structure fixes
the craft (the transformation, the mirror, the two doorways, the concrete event of
each beat and the meaning it embodies, the cast); ``to_beat_sheet`` renders it into
the prompt you hand an LLM. The LLM writes the screenplay FROM the sheet and owns
the continuity, the world, and the words — it does not invent the beats.

Run with:  python -m examples.ray
"""

from brehon import Story
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
        manifestation="Ray drives two towns over to the recruiting office with his "
        "father's loaded pistol, to put a bullet in the man who signed his brother up. "
        "The recruiter is younger than he expected, and tired. In the dark glass of the "
        "door Ray catches his own reflection — a man with a steady hand on a gun — and "
        "knows, for the first time, that he is the warrior, not the man against it. He "
        "sets the gun down and signs the enlistment, taking the place that should have "
        "been his brother's.",
        previous="the word-warrior who calls his cowardice principle",
        next="the warrior, finally awake",
        title="Ray",
        narrator_voice="am_michael",
        cast={"RAY": "am_michael", "TOMMY": "am_eric", "RUTH": "af_sarah",
              "JUNE": "af_bella", "ANNIE": "af_nicole"},
    )

    # -- BEFORE: the word-warrior -------------------------------------
    s.instantiate(
        before.id, "His fight only ever found his mouth, not his hands", kind="beat",
        id="b-booth", attributes={"character": "RAY", "dialogue": "yes"},
        manifestation="In the back booth of the bar, Ray takes a man apart in an argument "
        "about the war — and under the table his right fist is white and shaking.")
    s.instantiate(
        before.id, "The warrior he buried lives, plainly, in his brother", kind="beat",
        id="b-creek",
        manifestation="Years back, nine-year-old Tommy keeps walking back into a beating "
        "he can't win at the creek, grinning through the blood, while fourteen-year-old "
        "Ray watches from the porch and turns a page.")
    s.instantiate(
        before.id, "Ray can't bless his brother's courage; he can only attack it",
        kind="beat", id="b-argue", attributes={"character": "TOMMY", "dialogue": "yes"},
        manifestation="Tommy comes to the kitchen already enlisted; Ray argues with every "
        "weapon he owns, all of it true; Tommy says only, \"I know all that, Ray,\" and goes.")
    s.instantiate(
        before.id, "His own rightness becomes the thing that kills the one who believed him",
        kind="beat", id="b-telegram", attributes={"doorway": 1},
        manifestation="The telegram comes. Tommy is dead — pointless, exactly as Ray always "
        "swore it would be. Ray doesn't weep; he goes cold and still.")
    s.instantiate(
        before.id, "What he buried has nowhere left to live but in him, and turns to rage",
        kind="beat", id="b-rage", attributes={"character": "RUTH", "dialogue": "yes"},
        manifestation="At the wake Ray can't stand the sympathy; his mother Ruth, who has "
        "buried warrior men before, watches him go cold and furious instead of broken.")

    # -- (the MIRROR, the root, is the recruiter's office) ------------

    # -- AFTER: the warrior awakened ----------------------------------
    s.instantiate(
        after.id, "He sheds the woman who loved the safe man and turns to the one who loved the warrior",
        kind="beat", id="b-women", attributes={"character": "ANNIE", "dialogue": "yes"},
        manifestation="Ray ends it with June, who loved the clever, safe man, and goes to "
        "Annie — his dead brother's fiancee, the one woman who ever loved the warrior.")
    s.instantiate(
        after.id, "He is forced into the one test his whole life was built to dodge",
        kind="beat", id="b-front", attributes={"doorway": 2},
        manifestation="Ray ships out, and the shooting starts; there is no walking out of a "
        "war, and his nerve has never once held.")
    s.instantiate(
        after.id, "The cold hands never come; the warrior wakes", kind="beat", id="b-wake",
        attributes={"character": "RAY"},
        manifestation="The first time the world comes apart around him, Ray waits for the "
        "cold hands that always stopped him — and they don't come. He is already moving, "
        "sure and unhurried, and something in his chest says: there you are.")
    s.instantiate(
        after.id, "He comes home the man he always was, with nothing left to prove",
        kind="beat", id="b-home",
        manifestation="Ray comes home on his own legs. In the same bar a new sharp kid runs "
        "Ray's old lines about the war; Ray, with nothing left to prove, just nods and walks "
        "out into the daylight.")

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
    return s


if __name__ == "__main__":
    print(to_beat_sheet(build()))
