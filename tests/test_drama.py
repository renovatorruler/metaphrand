from metaphrand import Story
from metaphrand.drama import Drama, attach, drama, of


def _story():
    s = Story()
    root = s.three_act("p")
    act = s.instantiate(root.id, "a", kind="act", id="act1")
    s.instantiate(act.id, "open", kind="beat", id="b1", manifestation="He opens the cell block.")
    s.instantiate(act.id, "sign", kind="beat", id="b2", manifestation="He signs the order.")
    return s


def test_attach_and_read_roundtrip():
    s = _story()
    attach(s, {"b1": Drama("free the men", "his name if he doesn't", "the yard is full")})
    d = of(s.get("b1"))
    assert d and d.want == "free the men" and d.complete()
    assert of(s.get("b2")) is None


def test_gate_passes_when_every_scene_is_a_fight():
    s = _story()
    attach(s, {
        "b1": Drama("free the men", "his legitimacy", "coronation day"),
        "b2": Drama("hold the throne", "the ditch", "the square is filling"),
    })
    rep = drama(s)
    assert rep.passed and rep.dramatized == 2 and rep.postcards == []


def test_gate_flags_a_postcard():
    s = _story()
    attach(s, {"b1": Drama("free the men", "his legitimacy", "coronation day")})  # b2 has none
    rep = drama(s)
    assert not rep.passed and rep.postcards == ["b2"]


def test_partial_drama_is_a_postcard():
    s = _story()
    attach(s, {"b1": Drama("free the men", "", "coronation day")})  # no stakes
    assert of(s.get("b1")).complete() is False
    assert "b1" in drama(s).postcards
