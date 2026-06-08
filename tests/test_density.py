from brehon import Story
from brehon.density import density, is_bone
from brehon.world import ALLY, HERO, Character, World


def _seed(flesh_beats=0):
    s = Story()
    root, before, after = s.mirror(
        "a coward becomes a warrior", previous="the coward", next="the warrior",
    )
    s.instantiate(before.id, "opening", kind="beat", id="b1",
                  attributes={"function": "Opening Image"})   # bone
    s.instantiate(before.id, "lock", kind="beat", id="b2", attributes={"doorway": 1})  # bone
    s.instantiate(after.id, "finale", kind="beat", id="b3",
                  attributes={"function": "Finale"})           # bone
    for i in range(flesh_beats):
        s.instantiate(after.id, f"texture {i}", kind="beat", id=f"f{i}")  # flesh
    return s


def test_is_bone_tracks_function_and_doorway():
    s = _seed()
    assert is_bone(s.get("b1"))       # has a function
    assert is_bone(s.get("b2"))       # has a doorway
    s.instantiate("next-state", "loose texture", kind="beat", id="bx")
    assert not is_bone(s.get("bx"))   # untagged == flesh


def test_shrink_wrapped_seed_fails():
    rep = density(_seed(flesh_beats=0))
    assert rep.flesh == 0
    assert rep.shrink_wrapped
    assert not rep.passed


def test_fleshed_seed_passes():
    rep = density(_seed(flesh_beats=3))    # 3 flesh, 3 bone -> 50%
    assert rep.flesh == 3
    assert rep.flesh_ratio >= 0.33
    assert rep.passed


def test_undramatized_want_fails_the_gate():
    world = World([
        Character("ray", "Ray", HERO, "to win the room", "m"),
        Character("ann", "Ann", ALLY, "to be seen", "f"),   # never named in a beat
    ])
    rep = density(_seed(flesh_beats=3), world=world)
    assert "Ann" in rep.undramatized_wants
    assert "Ray" not in rep.undramatized_wants               # the hero doesn't count
    assert not rep.passed   # a declared-but-undramatized want fails, flesh or no flesh


def test_dramatized_cast_passes():
    world = World([
        Character("ray", "Ray", HERO, "to win the room", "m"),
        Character("ann", "Ann", ALLY, "to be seen", "f"),
    ])
    s = _seed(flesh_beats=2)
    s.instantiate("next-state", "Ann steps in", kind="beat", id="ann1",
                  manifestation="Ann crosses the room and takes the empty chair.")
    rep = density(s, world=world)
    assert rep.undramatized_wants == []   # Ann now has a beat of her own
    assert rep.passed
