import json

import pytest

from brehon.generate import (
    DagGenerator,
    _extract_json,
    build_story,
    generate_story,
)
from brehon.render import FountainRenderer
from brehon.story import Story


# A canned proposal in the JSON contract. Deliberately exercises the DAG
# (a beat under both an act and a theme), dialogue+cast, the "three-act" hinge,
# a bad voice, an unknown "also" id, and a self-referential motif parent.
SPEC = {
    "title": "Low Tide",
    "premise": "A harbour keeps its dead by refusing to let the water leave",
    "author": "brehon",
    "narrator_voice": "af_sky",
    "cast": {"harbourmaster": "am_onyx"},
    "themes": [
        {"id": "salt", "meaning": "What the sea leaves behind"},
        {"id": "debt", "meaning": "What is owed to the drowned"},
    ],
    "motifs": [
        {"id": "rope", "meaning": "The line that ties the boat and the body", "parents": ["debt", "rope"]},
    ],
    "acts": [
        {"id": "act1", "meaning": "The keeper counts the boats in", "beats": [
            {"id": "b-count", "meaning": "He is the one who notices absence", "also": ["salt"],
             "manifestation": "He counts thirty masts at dusk and twenty-nine at dawn.",
             "slug": "EXT. HARBOUR WALL - DAWN"},
        ]},
        {"id": "act2", "meaning": "The water will not give them back", "beats": [
            {"id": "b-warn", "meaning": "He is told to stop counting", "also": ["debt", "ghost-id"],
             "manifestation": "The harbourmaster finds him on the wall with the ledger.",
             "character": "harbourmaster", "parenthetical": "quiet",
             "dialogue": "Some numbers we don't write down, son."},
        ]},
        {"id": "act3", "meaning": "He lets the tide out", "beats": [
            {"id": "b-open", "meaning": "He chooses the count over the calm", "also": ["three-act", "rope"],
             "manifestation": "He opens the sea-gate and lets the low tide carry the names out."},
        ]},
    ],
}


def _build(warnings=None):
    return build_story(SPEC, warnings=warnings)


def test_structure_acts_and_beats_in_order():
    s = _build()
    root = s.get(s.root_id)
    assert root.kind == "three-act"
    acts = [m for m in s.children(root.id) if m.kind == "act"]
    assert [a.id for a in acts] == ["act1", "act2", "act3"]
    assert [b.id for b in s.children("act1")] == ["b-count"]


def test_root_carries_title_and_clamped_cast():
    s = _build()
    root = s.get(s.root_id)
    assert root.attributes["title"] == "Low Tide"
    # af_sky is valid; am_onyx is valid; cast key is upper-cased.
    assert root.attributes["narrator_voice"] == "af_sky"
    assert root.attributes["cast"] == {"HARBOURMASTER": "am_onyx"}


def test_dag_beat_has_act_and_theme_parents():
    s = _build()
    parents = {p.id for p in s.parents("b-count")}
    assert parents == {"act1", "salt"}  # structure + meaning -> a real DAG


def test_hinge_beat_links_to_root():
    s = _build()
    assert s.root_id in {p.id for p in s.parents("b-open")}


def test_unknown_also_id_is_dropped_to_warnings():
    warnings: list[str] = []
    s = _build(warnings)
    assert "ghost-id" not in s
    assert any("ghost-id" in w for w in warnings)


def test_self_referential_motif_parent_dropped_as_cycle():
    warnings: list[str] = []
    s = _build(warnings)
    assert "rope" in s
    assert any("rope -> rope" in w or "cyclic" in w for w in warnings)


def test_invalid_voice_falls_back():
    spec = json.loads(json.dumps(SPEC))
    spec["narrator_voice"] = "not_a_voice"
    spec["cast"] = {"harbourmaster": "zz_bogus"}
    s = build_story(spec)
    root = s.get(s.root_id)
    assert root.attributes["narrator_voice"] == "af_heart"        # default
    assert root.attributes["cast"]["HARBOURMASTER"] == "af_heart"  # -> narrator


def test_round_trip_is_byte_stable():
    s = _build()
    first = s.to_json()
    assert Story.from_json(first).to_json() == first


def test_renders_a_fountain_screenplay():
    script = FountainRenderer().render(_build())
    assert "Title: Low Tide" in script
    assert "# ACT ONE" in script
    assert "EXT. HARBOUR WALL - DAWN" in script
    assert "HARBOURMASTER" in script and "Some numbers we don't write down" in script


def test_missing_acts_raises():
    with pytest.raises(ValueError):
        build_story({"title": "Empty", "premise": "p", "acts": []})


def test_acts_without_beats_raise():
    with pytest.raises(ValueError):
        build_story({"title": "X", "premise": "p", "acts": [{"id": "a1", "meaning": "m", "beats": []}]})


def test_extract_json_strips_code_fence():
    payload = {"a": 1}
    fenced = "```json\n" + json.dumps(payload) + "\n```"
    assert _extract_json(fenced) == payload


def test_extract_json_recovers_from_surrounding_prose():
    payload = {"title": "T", "acts": []}
    noisy = "Sure! Here you go:\n" + json.dumps(payload) + "\nHope that helps."
    assert _extract_json(noisy) == payload


class _FakeClient:
    """Records the prompt and returns a fixed reply — no network."""

    def __init__(self, reply: str) -> None:
        self.reply = reply
        self.seen_prompt = None
        self.seen_system = None

    def complete(self, prompt: str, *, system=None) -> str:
        self.seen_prompt = prompt
        self.seen_system = system
        return self.reply


def test_generator_uses_client_and_builds_story():
    client = _FakeClient(json.dumps(SPEC))
    story = generate_story("a harbour premise", client=client)
    assert client.seen_system and "CONCRETENESS" in client.seen_system
    assert "a harbour premise" in client.seen_prompt
    # premise argument overrides the spec's premise as the root meaning.
    assert story.get(story.root_id).meaning == "a harbour premise"


def test_generator_collects_warnings():
    client = _FakeClient("```json\n" + json.dumps(SPEC) + "\n```")
    gen = DagGenerator(client=client)
    gen.generate("p")
    assert any("ghost-id" in w for w in gen.warnings)
