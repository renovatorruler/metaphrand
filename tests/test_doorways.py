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


def test_orders_doorways_by_spine_not_dag_crosslinks():
    """A Doorway-2 beat also linked under an early theme must still be ordered by
    its place on the spine, not by whichever path the DAG walk reaches first."""
    s = Story()
    root = s.three_act("p", narrator_voice="n")
    theme = s.instantiate(root.id, "isolation", kind="theme", id="th")
    act = s.instantiate(root.id, "a", kind="act", id="act1")
    s.instantiate(act.id, "lock", kind="beat", id="d1",
                  attributes={"doorway": 1}, manifestation="he bolts the door")
    s.instantiate(act.id, "cross", kind="beat", id="d2",
                  attributes={"doorway": 2}, manifestation="he boards the train")
    s.link(theme.id, "d2")     # d2 also hangs under the early theme (a DAG crosslink)
    assert doorways(s).passed  # spine order is still d1 -> d2, despite the crosslink
