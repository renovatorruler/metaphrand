from brehon import Story
from brehon.doorways import doorways


def _spine(marks):
    """Four beats b1..b4 in order; ``marks`` maps beat id -> doorway value."""
    s = Story()
    root = s.three_act("p", narrator_voice="n")
    act = s.instantiate(root.id, "a", kind="act", id="act1")
    for bid in ("b1", "b2", "b3", "b4"):
        attrs = {"doorway": marks[bid]} if bid in marks else {}
        s.instantiate(act.id, "m", kind="beat", manifestation=bid, id=bid, attributes=attrs)
    return s


def test_both_present_and_ordered_passes():
    assert doorways(_spine({"b2": 1, "b3": 2})).passed


def test_missing_doorway_one():
    rep = doorways(_spine({"b3": 2}))
    assert not rep.passed
    assert any("Doorway 1" in r for r in rep.reasons)


def test_missing_doorway_two():
    rep = doorways(_spine({"b2": 1}))
    assert any("Doorway 2" in r for r in rep.reasons)


def test_out_of_order():
    rep = doorways(_spine({"b1": 2, "b3": 1}))  # doorway 2 before doorway 1
    assert any("order" in r for r in rep.reasons)
