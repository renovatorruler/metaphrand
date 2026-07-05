"""The heart gate — bonds, deposits, wounds, thaws (the Good Wife rule)."""

from metaphrand import Story
from metaphrand.heart import heart
from metaphrand.pipeline import check


def _story_with(attrs_per_beat):
    s = Story()
    root, ki, sho, ten, ketsu = s.kishotenketsu("x", id="r", ki="a", sho="b", ten="c", ketsu="d")
    acts = [ki, sho, ten, ketsu]
    for i, attrs in enumerate(attrs_per_beat):
        s.instantiate(acts[min(i, 3)].id, f"m{i}", kind="beat", id=f"b{i}",
                      manifestation=f"Beat {i} happens on the page.", attributes=attrs)
    return s


def test_banked_thaw_passes():
    s = _story_with([
        {"bond": "a+b", "deposit": "the tape"},
        {"bond": "a+b", "wound": "the exposure", "blocks": "the search"},
        {"bond": "a+b", "thaw": "the tape", "unlocks": "the search"},
        {},
    ])
    rep = heart(s)
    assert rep.passed
    assert rep.bonds == ["a+b"] and rep.deposits == 1 and rep.thaws == 1
    assert rep.blocks == 1 and rep.unlocks == 1


def test_unbanked_thaw_fails():
    # the attorney begs and she just... warms up: structurally impossible
    s = _story_with([
        {"bond": "a+b", "deposit": "the tape"},
        {"bond": "a+b", "thaw": "the begging"},
    ])
    rep = heart(s)
    assert not rep.passed
    assert "unbanked thaw" in rep.violations[0]


def test_wound_before_any_deposit_fails():
    # you cannot lose on the page what was never shown banked
    s = _story_with([
        {"bond": "a+b", "wound": "the betrayal"},
        {"bond": "a+b", "deposit": "too late"},
    ])
    rep = heart(s)
    assert not rep.passed
    assert "unbanked wound" in rep.violations[0]


def test_declared_bond_without_deposit_fails():
    s = _story_with([{"bond": "a+b"}])
    rep = heart(s)
    assert not rep.passed
    assert "never banked" in rep.violations[0]


def test_heart_is_opt_out():
    # a story with no bonds now FAILS the heart gate by default...
    plain = _story_with([{}, {}])
    stages = {st.name: st for st in check(plain).stages}
    assert "heart" in stages and not stages["heart"].passed
    assert "no bonds declared" in stages["heart"].detail

    # ...unless the root deliberately opts out
    cold = _story_with([{}, {}])
    cold.get(cold.root_id).attributes["heart"] = "opt-out"
    assert all(st.name != "heart" for st in check(cold).stages)

    # and a banked story passes
    bonded = _story_with([
        {"bond": "a+b", "deposit": "the tape"},
        {"bond": "a+b", "thaw": "the tape"},
    ])
    stages = {st.name: st for st in check(bonded).stages}
    assert stages["heart"].passed
