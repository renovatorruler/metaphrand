from brehon import Story
from brehon.prompt import lint_prose, to_beat_sheet, to_prompt, write_story


def _seed():
    s = Story()
    root, prev, nxt = s.mirror(
        "a man who hides becomes a man who stands",
        manifestation="He stands at the door with his hand on it.",
        previous="the hider", next="the stander", narrator_voice="x",
    )
    s.instantiate(prev.id, "he is looked through", kind="beat", id="b1")
    s.instantiate(prev.id, "he refuses the call", kind="beat", id="b2",
                  attributes={"doorway": 1})
    s.instantiate(nxt.id, "he is forced to act", kind="beat", id="b3",
                  attributes={"doorway": 2})
    s.instantiate(nxt.id, "he stands and pays", kind="beat", id="b4")
    return s


def test_to_prompt_holds_the_craft():
    p = to_prompt(_seed())
    assert "a man who hides becomes a man who stands" in p   # the transformation
    assert "THE MIRROR" in p
    assert "he refuses the call" in p                        # a beat's meaning
    assert "DOORWAY 1" in p and "DOORWAY 2" in p
    assert "embody" in p and "never name the meaning" in p   # the rules


def test_to_prompt_orders_previous_then_next():
    p = to_prompt(_seed())
    assert p.index("PREVIOUS STATE") < p.index("NEXT STATE")


class _Client:
    def __init__(self, reply):
        self.reply = reply
        self.seen = None

    def complete(self, prompt, *, system=None):
        self.seen = prompt
        return self.reply


def test_write_story_sends_the_managed_prompt():
    client = _Client("FADE IN. He stands at the door.")
    out = write_story(_seed(), client)
    assert "TRANSFORMATION" in client.seen
    assert out.startswith("FADE IN")


def test_lint_prose_flags_the_code_owned_rules():
    issues = lint_prose("He was brave. He felt proud.\nThe glass bled light like fire.")
    kinds = {k for k, _, _ in issues}
    assert "telling" in kinds and "flowery" in kinds


def test_lint_prose_passes_clean_prose():
    assert lint_prose("He bolts the door from the inside. He sets the cup down.") == []


def _seed_with_events():
    s = Story()
    root, prev, nxt = s.mirror(
        "a man who hides becomes a man who stands",
        manifestation="He stands at the door with his hand on the bolt.",
        previous="the hider", next="the stander", narrator_voice="x",
    )
    s.instantiate(prev.id, "he refuses the call", kind="beat", id="b1",
                  attributes={"doorway": 1},
                  manifestation="He closes the chart and winds the crank again.")
    s.instantiate(nxt.id, "he stands", kind="beat", id="b2",
                  manifestation="He steps into the open and takes the fire meant for the boy.")
    return s


def test_to_beat_sheet_is_a_concrete_ordered_sheet():
    sheet = to_beat_sheet(_seed_with_events())
    assert "beat sheet" in sheet
    assert "He closes the chart" in sheet            # the concrete event, not the meaning
    assert "DOORWAY 1" in sheet
    assert "THE MIRROR" in sheet and "hand on the bolt" in sheet
    assert "TO THE WRITER" in sheet
    assert sheet.index("BEFORE") < sheet.index("THE MIRROR") < sheet.index("AFTER")
