from brehon import Story
from brehon.cinema import (
    classify, modality, silent_legibility, silent_spine, spine_beats,
)


class FakeClient:
    """Minimal LLMClient stand-in: returns a fixed reply."""

    def __init__(self, reply: str) -> None:
        self.reply = reply

    def complete(self, prompt: str, system: str = "") -> str:
        return self.reply


def _story():
    s = Story()
    root, before, after = s.mirror(
        "a coward becomes a warrior",
        manifestation="he sets the loaded pistol down on the desk and signs the form",
        previous="the coward", next="the warrior",
    )
    s.instantiate(before.id, "he loads the pistol one round at a time",
                  kind="beat", id="b1")
    s.instantiate(before.id, "he argues the room into silence",
                  kind="beat", id="b2", attributes={"dialogue": "yes"})
    s.instantiate(before.id, "he tells his brother the war is a lie",
                  kind="beat", id="b3", attributes={"dialogue": "yes"})
    s.instantiate(after.id, "he drags the wounded kid across open ground",
                  kind="beat", id="b4")
    return s


def test_classify_visual_vs_verbal():
    s = _story()
    assert classify(s.get("b1")) == "visual"          # loads the pistol
    assert classify(s.get("b2")) == "verbal"          # argues, flagged dialogue
    assert classify(s.get("b4")) == "visual"          # drags
    assert classify(s.get(s.root_id)) == "visual"     # the mirror is staged


def test_spine_beats_in_narrative_order():
    s = _story()
    assert [b.id for b in spine_beats(s)] == ["b1", "b2", "b3", s.root_id, "b4"]


def test_modality_counts_runs_and_passes():
    rep = modality(_story())
    assert rep.total == 5
    assert rep.visual == 3                # b1, mirror, b4
    assert rep.longest_talk_run == 2      # b2, b3
    assert rep.passed                     # run <= 2 and 60% visual


def test_modality_flags_a_long_talking_run():
    s = _story()
    s.instantiate("previous-state", "he explains the ledger of the dead",
                  kind="beat", id="b3b", attributes={"dialogue": "yes"})
    rep = modality(s)
    assert rep.longest_talk_run == 3      # b2, b3, b3b
    assert not rep.passed


def test_modality_flags_talky_key_beat():
    s = _story()
    s.instantiate(s.get(s.root_id).id, "ignored", kind="state", id="x")  # noise
    s.instantiate("next-state", "he announces the moral of the story",
                  kind="beat", id="fin", attributes={"dialogue": "yes",
                                                     "function": "Finale"})
    rep = modality(s)
    assert "finale" in rep.talky_key_beats
    assert not rep.passed


def test_silent_spine_strips_dialogue():
    spine = silent_spine(_story())
    assert "loads the pistol" in spine
    assert "drags the wounded kid" in spine


def test_silent_legibility_round_trip():
    s = _story()
    ok = silent_legibility(s, FakeClient('{"arc": "a coward turns into a warrior"}'))
    assert ok.passed
    bad = silent_legibility(s, FakeClient('{"arc": "a baker opens a shop"}'))
    assert not bad.passed
