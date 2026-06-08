"""Audio-drama script: a tagged, machine-readable format for the ear.

A screenplay is a blueprint for pictures + sound; an audio drama is a blueprint
for *sound alone*. This module parses the tagged cue format (see
``stories/DEEPER-ActTwo-AudioDrama_*.txt``) into a structure the engine can
render: ordered spoken :class:`~brehon.audio.Utterance` objects **plus** a
sound plan — the ambience bed for every scene and every spot effect, each with
the search query that resolves it (Freesound) or, later, a generator prompt.

The grammar (one cue per line; ``#`` comments and blank lines ignored):

    [SCENE id | Title]            scene boundary
    AMB: description :: query      ambience bed for the whole scene
    SFX: description :: query      spot effect, placed in sequence (query may be empty = a silent beat)
    MOTIF: name -- desc :: query   a recurring sonic motif
    [BRIDGE: description :: query]  sound transition between scenes
    NAME (note): line              spoken line; NAME=GARY + "(V.O.)" => narration spine
    NAME (FILTER note): line        a processed voice (phone / TV / through-the-floor)

Scenes with no narration line are, by design, the world the narrator cannot
hear. The parser does not enforce that; it just preserves order so the renderer
and the reader both see it.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Optional

from brehon.audio import Utterance, _for_speech

NARRATOR_SPEAKER = "GARY"  # the one whose (V.O.) is the spine, not a filtered phone voice
_FILTER_WORDS = ("filter", "phone", "tv", "television", "through", "speaker", "muffled", "through glass")


@dataclass(frozen=True)
class SoundCue:
    """A sound to be resolved (fetched or generated) and placed in the mix."""

    kind: str          # "ambience" | "sfx" | "motif" | "bridge"
    description: str    # human-facing intent
    query: str          # search/generation query ("" = a silent beat, nothing to fetch)
    scene_id: str
    seq: int            # global order across the whole act


@dataclass(frozen=True)
class Line:
    """One spoken thing, by one speaker."""

    speaker: str
    text: str
    note: str           # the parenthetical delivery note
    kind: str           # "narration" | "dialogue"
    filtered: bool      # processed voice (phone / TV / through a wall)
    scene_id: str
    seq: int


@dataclass
class Scene:
    id: str
    title: str
    ambience: Optional[SoundCue] = None
    elements: list = field(default_factory=list)  # ordered Line | SoundCue


@dataclass
class AudioDrama:
    scenes: list = field(default_factory=list)

    # --- views -------------------------------------------------------------
    def lines(self) -> list:
        return [e for s in self.scenes for e in s.elements if isinstance(e, Line)]

    def cues(self) -> list:
        """Every sound the act needs, in order (ambience beds first per scene)."""
        out: list = []
        for s in self.scenes:
            if s.ambience:
                out.append(s.ambience)
            out.extend(e for e in s.elements if isinstance(e, SoundCue))
        return out

    def manifest(self) -> dict:
        """Unique, fetchable queries -> the cues that want them (skips silent beats)."""
        m: dict = {}
        for c in self.cues():
            if c.query:
                m.setdefault(("ambience" if c.kind == "ambience" else "sfx", c.query), []).append(c)
        return m

    def utterances(self, cast: dict, narrator: str = "narrator") -> list:
        """Flat spoken script for TTS: narration in the narrator voice, each
        character in their own, processed voices flagged in the voice id."""
        out: list = []
        for ln in self.lines():
            if ln.kind == "narration":
                voice = cast.get(NARRATOR_SPEAKER, narrator)
            else:
                voice = cast.get(ln.speaker, narrator)
            if ln.filtered:
                voice = voice + "|filtered"
            out.append(Utterance(voice, _for_speech(ln.text), ln.scene_id))
        return out


_SCENE = re.compile(r"^\[SCENE\s+(\S+)\s*\|\s*(.+?)\]\s*$")
_BRIDGE = re.compile(r"^\[BRIDGE:\s*(.+?)\]\s*$")
_TAG = re.compile(r"^(AMB|SFX|MOTIF)\s*(?:\([^)]*\))?\s*:\s*(.*)$")
_SPEAK = re.compile(r"^([A-Z][A-Z0-9 .'/&-]*?)\s*(?:\(([^)]*)\))?\s*:\s*(.+)$")


def _split_query(rest: str) -> tuple[str, str]:
    """`description :: query` -> (description, query); query is '' if absent."""
    if "::" in rest:
        desc, query = rest.split("::", 1)
        return desc.strip(), query.strip()
    return rest.strip(), ""


def parse_audio_drama(text: str) -> AudioDrama:
    ad = AudioDrama()
    scene: Optional[Scene] = None
    seq = 0

    def cur() -> Scene:
        assert scene is not None
        return scene

    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue

        m = _SCENE.match(line)
        if m:
            scene = Scene(id=m.group(1), title=m.group(2).strip())
            ad.scenes.append(scene)
            continue

        if scene is None:
            continue  # the title / format header before the first [SCENE]

        m = _BRIDGE.match(line)
        if m:
            desc, query = _split_query(m.group(1))
            seq += 1
            cur().elements.append(SoundCue("bridge", desc, query, cur().id, seq))
            continue

        m = _TAG.match(line)
        if m:
            tag, rest = m.group(1), m.group(2)
            desc, query = _split_query(rest)
            seq += 1
            if tag == "AMB":
                cur().ambience = SoundCue("ambience", desc, query, cur().id, seq)
            else:
                kind = "motif" if tag == "MOTIF" else "sfx"
                cur().elements.append(SoundCue(kind, desc, query, cur().id, seq))
            continue

        m = _SPEAK.match(line)
        if m:
            speaker = m.group(1).strip()
            note = (m.group(2) or "").strip()
            body = m.group(3).strip()
            note_l = note.lower()
            is_narration = speaker == NARRATOR_SPEAKER and "v.o." in note_l \
                and not any(w in note_l for w in ("phone", "tv", "filter"))
            filtered = (not is_narration) and any(w in note_l for w in _FILTER_WORDS)
            seq += 1
            cur().elements.append(Line(
                speaker=speaker, text=body, note=note,
                kind="narration" if is_narration else "dialogue",
                filtered=filtered, scene_id=cur().id, seq=seq))
            continue

        # anything else: treat as narrator-less stage prose attached to the scene
        seq += 1
        cur().elements.append(Line("", line, "", "dialogue", False, cur().id, seq))

    return ad


# Default casting for DEEPER — natural-language voice descriptions (for Maya1/Kokoro).
# Narration uses the GARY voice, close-mic. See stories/deeper_voices.md.
DEFAULT_CAST = {
    "GARY": "American man, late forties, soft and contained, self-serious, quiet intensity, a systems-talker on fog",
    "HALLORAN": "American man, sixties, plain-spoken technician, tired, careful, deflects feeling into shop-talk",
    "ROYCE": "American man, warm rolling preacher's cadence, intimate late-night-radio orator, persuasive",
    "SAL": "American man, fifties, working class, gruff but warm, plain and slow, feeling smuggled into the practical",
    "DONNA": "American woman, fifties, warm and attentive, care said sideways, brief",
    "LIND": "American man, sixty, gentle drifting academic, unhurried, a little vague",
    "FOSS": "American woman, forties, terse and patient, states a fact flat and lets it hang",
    "GUTHRIE": "American man, fifties, procedural, flat, skeptical until a fact moves him",
    "CAROL": "American woman, fifties, frightened, piling concrete domestic detail, urgent and insistent",
    "IRENE": "American woman, late seventies, warm and far away, proud, the present slipping",
    "AIDE": "American woman, twenties, kind, gentle, a caregiver",
    "LOPEZ": "American woman, forties, blunt, by-the-book, earth-plain, a little hard",
    "BRINKMAN": "American man, fifties, flat, careful, a supervisor",
    "DESK SERGEANT": "American man, forties, procedural, then quietly human",
    "DEV OFFICER": "American man, thirties, tired and kind, reciting a fundraising script",
}
