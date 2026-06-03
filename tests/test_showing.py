import json

import pytest

from brehon import Story
from brehon.showing import is_telling, report, show, show_score, tells


@pytest.mark.parametrize("line,kind", [
    ("He was brave.", "state"),
    ("She felt jealous of him.", "interiority"),
    ("He knew it was a lie.", "interiority"),
    ("There was no out-arguing Ray.", "summary"),
    ("He seemed nervous all evening.", "state"),
])
def test_telling_is_flagged(line, kind):
    found = tells(line)
    assert found, f"expected a tell in {line!r}"
    assert kind in {t.kind for t in found}
    assert is_telling(line)
    assert show_score(line) < 1.0


@pytest.mark.parametrize("line", [
    "His fist went white under the table.",
    "He crossed the room and bolted the door.",
    "She set the cup down without a word and left.",
])
def test_shown_prose_passes(line):
    assert tells(line) == []
    assert show_score(line) == 1.0


def _story(manifestation):
    s = Story()
    root = s.three_act("p", narrator_voice="n")
    act = s.instantiate(root.id, "a", kind="act", id="act1")
    s.instantiate(act.id, "m", kind="beat", manifestation=manifestation, id="b1")
    return s


def test_report_counts_telling_beats():
    rep = report(_story("He was brave."))
    assert (rep.total, rep.telling) == (1, 1)
    assert rep.offenders[0][0] == "b1"


class _Client:
    def __init__(self, mapping):
        self.mapping = mapping

    def complete(self, prompt, *, system=None):
        for needle, shown in self.mapping.items():
            if needle in prompt:
                return json.dumps({"line": shown})
        return json.dumps({"line": "He stands in the room."})


def test_show_pass_converts_a_telling_beat():
    s = _story("He was brave.")
    client = _Client({"He was brave": "He stepped between the boy and the gun."})
    rep = show(s, client)
    assert rep.telling == 0
    assert s.get("b1").manifestation == "He stepped between the boy and the gun."
