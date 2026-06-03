from brehon import Story
from brehon.dossier import Dossier, Fact, attach, leak, reference_block
from brehon.prompt import to_prompt
from brehon.world import HERO, MENTOR, Character, World


def _story_with_cast():
    s = Story()
    s.mirror("a son becomes his father", previous="the boy", next="the man")
    s.instantiate("previous-state", "opening", kind="beat", id="b1",
                  attributes={"function": "Opening Image"})
    s.instantiate("next-state", "finale", kind="beat", id="b2",
                  attributes={"function": "Finale"})
    World([
        Character("ray", "RAY", HERO, "to be right", "m"),
        Character("earl", "EARL", MENTOR, "the road already walked", "m"),
    ]).attach(s)
    return s


def _bible():
    return [Dossier("EARL", [
        Fact("He came home from the war and stopped talking.", "surface"),
        Fact("At Anzio he left a wounded friend behind in the surf to save himself.",
             "submerged"),
    ])]


def test_attach_stores_backstory_on_character():
    s = _story_with_cast()
    attach(s, _bible())
    earl = next(n for n in s.walk() if n.kind == "character" and n.meaning == "EARL")
    assert len(earl.attributes["backstory"]) == 2
    assert earl.attributes["backstory"][0]["depth"] == "surface"


def test_reference_block_marks_submerged_and_feeds_the_prompt():
    s = _story_with_cast()
    attach(s, _bible())
    block = reference_block(s)
    assert "WHAT YOU KNOW" in block
    assert "never stated" in block            # the submerged fact is leashed
    assert "Anzio" in to_prompt(s)            # the writer is told, in the prompt


def test_leak_flags_a_surfaced_submerged_fact():
    s = _story_with_cast()
    attach(s, _bible())
    spilled = ("INT. BAR\n\nEARL: At Anzio I left a wounded friend behind in the "
               "surf to save myself.")
    assert not leak(spilled, s).passed        # the cause was exposited -> leak
    shown = "INT. KITCHEN\n\nEarl sits at the table and says nothing for an hour."
    assert leak(shown, s).passed              # only the symptom -> clean


def test_no_backstory_is_silent():
    s = _story_with_cast()                     # nothing attached
    assert reference_block(s) == ""
    assert leak("any script at all", s).passed
