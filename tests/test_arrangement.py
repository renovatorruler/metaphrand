from brehon import Story
from brehon.arrangement import arrangement, frame, is_linear, plot_order, story_order
from brehon.render import FountainRenderer


def _story():
    s = Story()
    s.mirror("a son becomes his father", manifestation="He stands at the door.",
             previous="the boy", next="the man")
    s.instantiate("previous-state", "Booth.", kind="beat", id="b1",
                  manifestation="Booth.", attributes={"function": "Opening Image"})
    s.instantiate("previous-state", "A knock at the door.", kind="beat", id="b-knock",
                  manifestation="A knock at the door.", attributes={"doorway": 1})
    s.instantiate("next-state", "The war.", kind="beat", id="b2",
                  manifestation="The war.", attributes={"doorway": 2})
    s.instantiate("next-state", "Home.", kind="beat", id="b3",
                  manifestation="Home.", attributes={"function": "Final Image"})
    return s


def test_default_is_chronological():
    s = _story()
    assert is_linear(s)
    rep = arrangement(s)
    assert rep.linear and rep.passed
    assert rep.summary() == "chronological"


def test_frame_sets_a_cold_open_that_returns():
    s = _story()
    frame(s, "b-knock")
    assert not is_linear(s)
    ids = [b.id for b in plot_order(s)]
    assert ids[0] == "b-knock"          # opens on the knock
    assert ids.count("b-knock") == 2    # ...and returns to it
    rep = arrangement(s)
    assert rep.passed
    assert rep.cold_opens == ["b-knock"]


def test_frame_on_a_weak_beat_fails():
    s = _story()
    s.instantiate("previous-state", "loose texture", kind="beat", id="weak")  # no turn
    chrono = [b.id for b in story_order(s)]
    s.get(s.root_id).attributes["plot_order"] = ["weak", *[i for i in chrono if i != "weak"], "weak"]
    rep = arrangement(s)
    assert not rep.passed
    assert any("not a turn" in i for i in rep.issues)


def test_frame_that_never_returns_fails():
    s = _story()
    chrono = [b.id for b in story_order(s)]
    s.get(s.root_id).attributes["plot_order"] = ["b-knock", *[i for i in chrono if i != "b-knock"]]
    rep = arrangement(s)
    assert not rep.passed
    assert any("never returns" in i for i in rep.issues)


def test_renderer_honors_the_frame():
    s = _story()
    frame(s, "b-knock")
    script = FountainRenderer().render(s)
    assert script.index("A knock at the door.") < script.index("Booth.")  # cold open first
    assert "FLASHBACK TO:" in script
