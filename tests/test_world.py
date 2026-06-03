import json

from brehon.world import (
    ALLY,
    HERALD,
    HERO,
    MENTOR,
    SHAPESHIFTER,
    Character,
    World,
    fullness,
    populate,
)


def _world(*chars):
    w = World()
    for c in chars:
        w.add(c)
    return w


def test_fullness_passes_a_real_world():
    w = _world(
        Character("ray", "Ray", HERO, "to be right", "m"),
        Character("ruth", "Ruth", MENTOR, "to hold her sons together", "f"),
        Character("june", "June", SHAPESHIFTER, "to keep the man she loves", "f"),
        Character("sully", "Sully", ALLY, "to keep his friend in the booth", "m"),
    )
    assert fullness(w).passed


def test_fullness_flags_all_male():
    w = _world(
        Character("ray", "Ray", HERO, "x", "m"),
        Character("tommy", "Tommy", HERALD, "to count", "m"),
        Character("sully", "Sully", ALLY, "company", "m"),
        Character("doc", "Doc", MENTOR, "to mend", "m"),
    )
    rep = fullness(w)
    assert not rep.passed
    assert any("women" in r for r in rep.reasons)


def test_fullness_flags_props():
    w = _world(
        Character("ray", "Ray", HERO, "x", "m"),
        Character("ruth", "Ruth", MENTOR, "to hold", "f"),
        Character("june", "June", SHAPESHIFTER, "", "f"),  # no want -> a prop
        Character("sully", "Sully", ALLY, "company", "m"),
    )
    rep = fullness(w)
    assert not rep.passed
    assert any("prop" in r for r in rep.reasons)


def test_fullness_flags_corridor():
    w = _world(
        Character("ray", "Ray", HERO, "x", "m"),
        Character("june", "June", SHAPESHIFTER, "y", "f"),
    )
    assert any("corridor" in r for r in fullness(w).reasons)


def test_world_round_trips():
    w = _world(Character("ray", "Ray", HERO, "to be right", "m", "the spine"))
    assert World.from_dict(w.to_dict()).to_dict() == w.to_dict()


class _SeqClient:
    """Returns a fixed sequence of replies (last one repeats)."""

    def __init__(self, replies):
        self.replies = list(replies)
        self.calls = 0

    def complete(self, prompt, *, system=None):
        reply = self.replies[min(self.calls, len(self.replies) - 1)]
        self.calls += 1
        return reply


_ALL_MALE = json.dumps({"characters": [
    {"name": "Ray", "archetype": "hero", "gender": "m", "want": "to be right"},
    {"name": "Tommy", "archetype": "herald", "gender": "m", "want": "to count"},
    {"name": "Sully", "archetype": "ally", "gender": "m", "want": "company"},
]})

_BALANCED = json.dumps({"characters": [
    {"name": "Ray", "archetype": "hero", "gender": "m", "want": "to be right"},
    {"name": "Tommy", "archetype": "herald", "gender": "m", "want": "to count"},
    {"name": "Sully", "archetype": "ally", "gender": "m", "want": "company"},
    {"name": "Ruth", "archetype": "mentor", "gender": "f", "want": "to hold her sons"},
    {"name": "June", "archetype": "shapeshifter", "gender": "f", "want": "to keep him"},
]})


def test_populate_repairs_until_world():
    client = _SeqClient([_ALL_MALE, _BALANCED])
    warnings: list[str] = []
    w = populate("a premise", client, hero_name="Ray", warnings=warnings)
    assert fullness(w).passed
    assert warnings == []
    assert w.hero().name == "Ray"
    assert client.calls == 2  # propose + one repair


def test_populate_warns_if_still_thin():
    client = _SeqClient([_ALL_MALE])  # never adds women
    warnings: list[str] = []
    populate("p", client, max_rounds=2, warnings=warnings)
    assert any("women" in x for x in warnings)
