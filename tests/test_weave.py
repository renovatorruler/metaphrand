import json

from brehon.weave import Thread, Weave, _runs, braid, is_monorail


def _spine():
    return Thread("a", "A", "can the word-man become the warrior", "spine", ["ray"], ["b1", "b3"])


def _heart():
    return Thread("b", "B", "can the warrior still be loved", "heart", ["ray", "june"], ["b2", "b4"])


def test_runs_counts_blocks():
    assert _runs(["A", "A", "B", "B"]) == 2
    assert _runs(["A", "B", "A", "B"]) == 4


def test_monorail_flags_single_thread():
    w = Weave([_spine()], ["b1", "b3"])
    assert any("monorail" in r for r in is_monorail(w).reasons)


def test_woven_passes():
    w = Weave([_spine(), _heart()], ["b1", "b2", "b3", "b4"])
    assert is_monorail(w).passed


def test_flags_blocks_not_interleaved():
    w = Weave([_spine(), _heart()], ["b1", "b3", "b2", "b4"])
    assert any("blocks" in r for r in is_monorail(w).reasons)


def test_flags_thread_that_does_not_refract():
    lonely = Thread("b", "B", "q", "heart", ["june"], ["b2", "b4"])  # shares no character
    w = Weave([_spine(), lonely], ["b1", "b2", "b3", "b4"])
    assert any("refract" in r for r in is_monorail(w).reasons)


def test_weave_round_trips():
    w = Weave([_spine(), _heart()], ["b1", "b2", "b3", "b4"])
    assert Weave.from_dict(w.to_dict()).to_dict() == w.to_dict()


class _Client:
    def __init__(self, reply):
        self.reply = reply
        self.seen = None

    def complete(self, prompt, *, system=None):
        self.seen = prompt
        return self.reply


def test_braid_returns_a_woven_weave():
    reply = json.dumps({
        "threads": [
            {"id": "a", "label": "A", "question": "spine", "role": "spine",
             "character_ids": ["ray"], "beat_ids": ["b1", "b3"]},
            {"id": "b", "label": "B", "question": "heart", "role": "heart",
             "character_ids": ["ray", "june"], "beat_ids": ["b2", "b4"]},
        ],
        "order": ["b1", "b2", "b3", "b4"],
    })
    warnings: list[str] = []
    w = braid("premise", _spine(), ["ray", "june"], _Client(reply), warnings=warnings)
    assert is_monorail(w).passed
    assert warnings == []
