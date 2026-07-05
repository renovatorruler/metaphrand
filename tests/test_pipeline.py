import json

from metaphrand import Story
from metaphrand.pipeline import check
from metaphrand.world import ALLY, HERO, Character, World
from metaphrand.weave import Thread, Weave


def _clean_story():
    """A small spine that clears spine + doorways + concreteness + show-not-tell."""
    s = Story()
    root = s.three_act("p", narrator_voice="n")
    act = s.instantiate(root.id, "a", kind="act", id="act1")
    s.instantiate(act.id, "m1", kind="beat", id="b1", attributes={"doorway": 1},
                  manifestation="He bolts the door from the inside.")
    s.instantiate(act.id, "m2", kind="beat", id="b2", attributes={"doorway": 2},
                  manifestation="He sets the roller down and leaves the floor as it is.")
    # flesh: untagged beats so the spine isn't a bare skeleton (density gate)
    s.instantiate(act.id, "sub1", kind="beat", id="f1",
                  manifestation="His neighbor hammers a sign into the next yard.")
    s.instantiate(act.id, "sub2", kind="beat", id="f2",
                  manifestation="A dog drags its chain across the gravel and lies down.")
    # heart: the gate is opt-out, so the canonical fixture carries one banked bond
    s.instantiate(act.id, "sub3", kind="beat", id="f3",
                  manifestation="She leaves the thermos on the gate post for him without a word.",
                  attributes={"bond": "him+her", "deposit": "the thermos"})
    return s


def test_check_reports_every_stage():
    names = [s.name for s in check(_clean_story()).stages]
    assert names == ["spine", "doorways", "arrangement", "heart", "concreteness",
                     "show-not-tell", "visual", "density"]


def test_clean_story_passes():
    assert check(_clean_story()).passed


def test_world_and_weave_stages_appear_when_supplied():
    s = _clean_story()
    world = World([
        Character("ray", "Ray", HERO, "x", "m"),
        Character("ann", "Ann", ALLY, "her own want", "f"),
        Character("sam", "Sam", ALLY, "his own want", "m"),
        Character("liz", "Liz", ALLY, "her own want", "f"),
    ])
    spine = Thread("a", "A", "q", "spine", ["ray"], ["b1", "b2"])
    heart = Thread("b", "B", "q", "heart", ["ray", "ann"], ["x1", "x2"])
    weave = Weave([spine, heart], ["b1", "x1", "b2", "x2"])
    names = [st.name for st in check(s, world=world, weave=weave).stages]
    assert "world" in names and "weave" in names


def test_check_flags_failures():
    s = Story()
    root = s.three_act("p", narrator_voice="n")
    act = s.instantiate(root.id, "a", kind="act", id="act1")
    # tells, and no doorways marked
    s.instantiate(act.id, "m", kind="beat", id="b1",
                  manifestation="He was brave, and he felt proud of it.")
    corridor = World([Character("ray", "Ray", HERO, "x", "m")])
    by = {st.name: st for st in check(s, world=corridor).stages}
    assert not by["doorways"].passed
    assert not by["world"].passed
    assert not by["show-not-tell"].passed
    assert by["concreteness"].passed  # telling is not flowery — different gate


# -- the end-to-end run, driven by a mock that answers each stage ----------

_SPINE = json.dumps({
    "title": "The Lamp",
    "transformation": "a keeper who tends a machine because he is told to becomes a man who stops it",
    "mirror": "He stands at the crank with his hand on the handle and does not turn it.",
    "previous_state": "the keeper who winds the light",
    "next_state": "the keeper who lets it go dark",
    "narrator_voice": "am_michael",
    "cast": {"FISHERMAN": "am_fenrir"},
    "previous_beats": [
        {"id": "b-routine", "meaning": "the keeper's routine",
         "manifestation": "At dusk he climbs the stairs past Ruth's room and winds the crank."},
        {"id": "b-lock", "meaning": "the lock that shuts him out", "doorway": 1,
         "manifestation": "He reads the telegram on the porch and does not sit down."},
    ],
    "next_beats": [
        {"id": "b-cross", "meaning": "the threshold he crosses", "doorway": 2,
         "manifestation": "He boards the train while June calls his name, and the doors close behind him."},
        {"id": "b-stand", "meaning": "the stand he makes",
         "manifestation": "He steps into the open and pulls Sully's boy out of the fire."},
    ],
})

_WORLD = json.dumps({"characters": [
    {"name": "Walt", "archetype": "hero", "gender": "m", "want": "to do his job"},
    {"name": "Ruth", "archetype": "mentor", "gender": "f", "want": "to hold the family"},
    {"name": "June", "archetype": "shapeshifter", "gender": "f", "want": "to keep him"},
    {"name": "Sully", "archetype": "ally", "gender": "m", "want": "to keep his friend close"},
]})

_WEAVE = json.dumps({
    "threads": [
        {"id": "a", "label": "A", "question": "spine", "role": "spine",
         "character_ids": ["walt"], "beat_ids": ["b-routine", "b-lock", "b-cross", "b-stand"]},
        {"id": "b", "label": "B", "question": "heart", "role": "heart",
         "character_ids": ["walt", "june"], "beat_ids": ["x1", "x2"]},
    ],
    "order": ["b-routine", "x1", "b-lock", "x2", "b-cross", "b-stand"],
})

_MEANING = json.dumps({"meaning":
    "the keeper's routine, the lock that shuts, the threshold he crosses, the stand he makes"})


class _PipelineClient:
    """Answers each pipeline stage from its prompt — no network."""

    def complete(self, prompt, *, system=None):
        sys_l = (system or "").lower()
        if "mirror" in sys_l and "transformation" in sys_l:
            return _SPINE
        if "hero's-journey" in sys_l:
            return _WORLD
        if "braid" in sys_l:
            return _WEAVE
        if "read the meaning" in sys_l:
            return _MEANING
        if "pictures" in sys_l:  # the silent-spine round-trip (sound-off test)
            return json.dumps({"arc": "a keeper learns to stop the light he was told to keep"})
        return json.dumps({"line": "He stands in the room."})  # concretize/show fallback


def test_generate_end_to_end_passes_every_gate():
    from metaphrand.pipeline import generate

    result = generate("a keeper learns the truth", _PipelineClient())
    assert result.report.passed, "\n" + result.report.summary()
    assert result.story.get(result.story.root_id).kind == "mirror"
    assert "winds the crank" in result.screenplay          # the spine rendered
    assert len(result.world.characters) >= 4               # a populated world
    assert any(t.role == "heart" for t in result.weave.threads)  # a B-story

