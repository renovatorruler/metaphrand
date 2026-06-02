import wave

from brehon import Story
from brehon.audio import AudioRenderer, SilentBackend, Utterance


def _story():
    s = Story()
    root = s.three_act(
        "p", title="T", narrator_voice="narr", cast={"SUPERVISOR": "boss"}
    )
    act = s.instantiate(root.id, "act", kind="act", id="act1")
    s.instantiate(
        act.id, "action beat", kind="beat",
        manifestation="A man crosses the room.",
        attributes={"slug": "INT. ROOM - NIGHT"},
        id="b1",
    )
    s.instantiate(
        act.id, "dialogue beat", kind="beat",
        manifestation="The supervisor leans in.",
        attributes={"character": "SUPERVISOR", "parenthetical": "softly",
                    "dialogue": "Don't worry about it."},
        id="b2",
    )
    return s


def test_narrator_reads_action_character_reads_dialogue():
    us = AudioRenderer().utterances(_story())
    assert us == [
        Utterance("narr", "A man crosses the room.", "b1"),
        Utterance("narr", "The supervisor leans in.", "b2"),
        Utterance("boss", "Don't worry about it.", "b2"),
    ]


def test_slugs_and_parentheticals_not_spoken_by_default():
    texts = [u.text for u in AudioRenderer().utterances(_story())]
    assert "INT. ROOM - NIGHT" not in texts
    assert "softly" not in texts


def test_speak_slugs_option_adds_scene_headings():
    us = AudioRenderer(speak_slugs=True).utterances(_story())
    assert us[0] == Utterance("narr", "INT. ROOM - NIGHT", "b1")


def test_constructor_overrides_seed_cast():
    us = AudioRenderer(cast={"SUPERVISOR": "other"}, narrator="n2").utterances(_story())
    assert us[0].voice == "n2"
    assert us[-1].voice == "other"


def test_unknown_character_falls_back_to_narrator():
    s = _story()
    s.instantiate(
        "act1", "stranger", kind="beat",
        attributes={"character": "GHOST", "dialogue": "Boo."}, id="b3",
    )
    us = AudioRenderer().utterances(s)
    assert us[-1] == Utterance("narr", "Boo.", "b3")


def test_em_dashes_normalised_for_speech():
    s = Story()
    root = s.three_act("p", narrator_voice="n")
    act = s.instantiate(root.id, "a", kind="act", id="act1")
    s.instantiate(act.id, "b", kind="beat", manifestation="A -- B -- C.", id="b1")
    assert AudioRenderer().utterances(s)[0].text == "A, B, C."


def test_to_wav_writes_valid_mono_pcm(tmp_path):
    path = str(tmp_path / "out.wav")
    us = AudioRenderer().to_wav(_story(), SilentBackend(sample_rate=8000), path)
    assert len(us) == 3
    with wave.open(path, "rb") as w:
        assert w.getnchannels() == 1
        assert w.getsampwidth() == 2
        assert w.getframerate() == 8000
        assert w.getnframes() > 0


def test_utterances_are_deterministic():
    s = _story()
    assert AudioRenderer().utterances(s) == AudioRenderer().utterances(
        Story.from_json(s.to_json())
    )
