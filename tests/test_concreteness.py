import json

import pytest

from brehon import Story
from brehon.concreteness import (
    annotate,
    concretize,
    findings,
    is_flowery,
    report,
    score,
)
from examples.janitor import build as build_janitor


# --- the linter: catch the crimes, pass the bare fact -------------------

@pytest.mark.parametrize("line", [
    "He wipes the lens with a rag until it is clean.",
    "He sets the roller down in the tray and leaves the floor the way it is.",
    "He holds the door. Forty-one of them go through. The forty-second thanks the door.",
    "He tapes the student ID to locker 12.",
])
def test_bare_facts_are_not_flowery(line):
    assert findings(line) == []
    assert is_flowery(line) is False
    assert score(line) == 1.0


@pytest.mark.parametrize("line,kind", [
    ("The glass bleeds rainbows across the fog.", "purple-verb"),
    ("Cracks bloom like veins in ice.", "simile"),
    ("The hum stops and only the stone is singing back.", "purple-verb"),
    ("The lamp flickers, not from fault, but refusal.", "abstract"),
    ("A voice rises: *you are the bait*.", "emphasis"),
    ("Her skin was as cold as ice.", "simile"),
])
def test_crimes_are_flagged(line, kind):
    found = findings(line)
    assert found, f"expected a finding in {line!r}"
    assert kind in {f.kind for f in found}
    assert is_flowery(line) is True
    assert score(line) < 1.0


def test_like_is_a_simile_but_likely_is_not():
    assert findings("He is likely late.") == []
    assert any(f.kind == "simile" for f in findings("It moved like a wave."))


def test_bare_as_does_not_false_flag():
    # plain 'as' (not 'as X as') must not trip the simile check
    assert findings("He bolts the door from the inside, as he always does.") == []


# --- scoring & report over a story --------------------------------------

def _story(manifestation, *, dialogue=None):
    s = Story()
    root = s.three_act("p", title="T", narrator_voice="af_heart")
    act = s.instantiate(root.id, "a", kind="act", id="act1")
    attrs = {"dialogue": dialogue, "character": "X"} if dialogue else {}
    s.instantiate(
        act.id, "m", kind="beat", manifestation=manifestation,
        attributes=attrs, id="b1",
    )
    return s


def test_annotate_writes_concreteness_scores():
    flowery = _story("The glass bleeds rainbows across the fog.")
    annotate(flowery)
    assert flowery.get("b1").concreteness < 1.0

    plain = _story("He cleans the lens.")
    annotate(plain)
    assert plain.get("b1").concreteness == 1.0


def test_report_counts_flowery_fraction():
    s = Story()
    root = s.three_act("p", narrator_voice="af_heart")
    act = s.instantiate(root.id, "a", kind="act", id="act1")
    s.instantiate(act.id, "m", kind="beat", manifestation="He cleans the lens.", id="b1")
    s.instantiate(act.id, "m", kind="beat", manifestation="The sea breathes.", id="b2")
    rep = report(s)
    assert (rep.total, rep.flowery) == (2, 1)
    assert rep.fraction == 0.5
    assert rep.offenders[0][0] == "b2"


def test_dialogue_is_assessed_too():
    s = _story("He leans in.", dialogue="Cracks bloom like veins in ice.")
    assert report(s).flowery == 1


def test_janitor_story_is_concrete_gold_standard():
    rep = report(build_janitor())
    assert rep.flowery == 0, [o[0] for o in rep.offenders]


def test_concreteness_round_trips():
    s = _story("He cleans the lens.")
    annotate(s)
    first = s.to_json()
    assert Story.from_json(first).to_json() == first
    assert Story.from_json(first).get("b1").concreteness == 1.0


# --- the concretize repair pass (mocked client, offline) ----------------

class _RewriteClient:
    """Returns canned concrete rewrites; drives concretize() without a model."""

    def __init__(self, mapping):
        self.mapping = mapping
        self.calls = 0

    def complete(self, prompt, *, system=None):
        self.calls += 1
        for needle, concrete in self.mapping.items():
            if needle in prompt:
                return json.dumps({"line": concrete})
        return json.dumps({"line": "He stands in the room."})


class _StubbornClient:
    """Always returns something still ornamental — concretize can't win."""

    def complete(self, prompt, *, system=None):
        return json.dumps({"line": "The sea still breathes."})


def test_concretize_rewrites_a_flowery_beat():
    s = _story("The glass bleeds rainbows across the fog.")
    client = _RewriteClient({"bleeds rainbows": "He wipes the lens until it is clean."})
    rep = concretize(s, client)
    assert rep.flowery == 0
    assert s.get("b1").manifestation == "He wipes the lens until it is clean."
    assert s.get("b1").concreteness == 1.0


def test_concretize_warns_when_it_cannot_fix():
    s = _story("The sea breathes and the stone sings.")
    warnings: list[str] = []
    rep = concretize(s, _StubbornClient(), warnings=warnings)
    assert rep.flowery == 1
    assert any("concretize" in w for w in warnings)


def test_concretize_cleans_flowery_dialogue():
    s = _story("He leans in.", dialogue="Cracks bloom like veins in ice.")
    client = _RewriteClient({"veins in ice": "Some numbers we don't write down."})
    rep = concretize(s, client)
    assert rep.flowery == 0
    assert s.get("b1").attributes["dialogue"] == "Some numbers we don't write down."
