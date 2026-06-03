import json

from brehon import Story
from brehon.embodiment import legibility, restates_meaning


def test_restates_meaning_detects_on_the_nose():
    assert restates_meaning("He felt completely invisible to everyone.",
                            "he is invisible to everyone")
    assert not restates_meaning(
        "Forty-one walk past; the forty-second thanks the door.",
        "he is invisible to everyone")


class _Client:
    """Returns a fixed inferred meaning for any line."""

    def __init__(self, inferred):
        self.inferred = inferred

    def complete(self, prompt, *, system=None):
        return json.dumps({"meaning": self.inferred})


def _story(manifestation, meaning):
    s = Story()
    root = s.three_act("p", narrator_voice="n")
    act = s.instantiate(root.id, "a", kind="act", id="act1")
    s.instantiate(act.id, meaning, kind="beat", manifestation=manifestation, id="b1")
    return s


def test_legible_beat_passes():
    s = _story("Forty-one walk past; the forty-second thanks the door.",
               "he is invisible, unseen by people")
    rep = legibility(s, _Client("the man is invisible and unseen"))
    assert rep.passed


def test_illegible_beat_flagged():
    s = _story("He cleans the lens with a rag.",
               "the surface hides a murderous function")
    rep = legibility(s, _Client("a man is doing some cleaning"))
    assert not rep.passed
    assert rep.offenders[0][1] == "illegible"


def test_on_the_nose_flagged_without_model():
    s = _story("He feels invisible and unseen by everyone.", "he is invisible, unseen")
    rep = legibility(s, _Client("anything"))
    assert rep.offenders and rep.offenders[0][1] == "on-the-nose"
