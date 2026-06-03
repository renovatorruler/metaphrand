from brehon import Story
from brehon.pipeline import check
from brehon.world import ALLY, HERO, Character, World
from brehon.weave import Thread, Weave


def _clean_story():
    """A small spine that clears spine + doorways + concreteness + show-not-tell."""
    s = Story()
    root = s.three_act("p", narrator_voice="n")
    act = s.instantiate(root.id, "a", kind="act", id="act1")
    s.instantiate(act.id, "m1", kind="beat", id="b1", attributes={"doorway": 1},
                  manifestation="He bolts the door from the inside.")
    s.instantiate(act.id, "m2", kind="beat", id="b2", attributes={"doorway": 2},
                  manifestation="He sets the roller down and leaves the floor as it is.")
    return s


def test_check_reports_every_stage():
    names = [s.name for s in check(_clean_story()).stages]
    assert names == ["spine", "doorways", "concreteness", "show-not-tell"]


def test_clean_story_passes():
    assert check(_clean_story()).passed


def test_world_and_weave_stages_appear_when_supplied():
    s = _clean_story()
    world = World([
        Character("ray", "Ray", HERO, "x", "m"),
        Character("ann", "Ann", ALLY, "her own want", "f"),
        Character("sam", "Sam", ALLY, "his own want", "m"),
        Character("liz", "Liz", ALLY, "her own want", "f"),
    ])
    spine = Thread("a", "A", "q", "spine", ["ray"], ["b1", "b2"])
    heart = Thread("b", "B", "q", "heart", ["ray", "ann"], ["x1", "x2"])
    weave = Weave([spine, heart], ["b1", "x1", "b2", "x2"])
    names = [st.name for st in check(s, world=world, weave=weave).stages]
    assert "world" in names and "weave" in names


def test_check_flags_failures():
    s = Story()
    root = s.three_act("p", narrator_voice="n")
    act = s.instantiate(root.id, "a", kind="act", id="act1")
    # tells, and no doorways marked
    s.instantiate(act.id, "m", kind="beat", id="b1",
                  manifestation="He was brave, and he felt proud of it.")
    corridor = World([Character("ray", "Ray", HERO, "x", "m")])
    by = {st.name: st for st in check(s, world=corridor).stages}
    assert not by["doorways"].passed
    assert not by["world"].passed
    assert not by["show-not-tell"].passed
    assert by["concreteness"].passed  # telling is not flowery — different gate
