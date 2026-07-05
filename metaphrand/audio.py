"""Multi-voice audio rendering — the story as a cast recording.

Like :class:`~metaphrand.render.FountainRenderer`, this walks only the structural
spine (root -> acts in order -> beats), but instead of text it emits a
deterministic list of :class:`Utterance` objects — ``(voice, text)`` pairs.
The narrator voice reads action; each character reads their own dialogue,
according to a *cast* map. Parentheticals and scene headings are not spoken by
default (they are delivery notes and orientation, not lines).

A pluggable :class:`TTSBackend` turns each utterance into 16-bit PCM, and the
clips are stitched (with small gaps) into a single mono WAV using only the
standard library. Voice assignment lives in the stored seed (``cast`` and
``narrator_voice`` on the root's attributes), so the casting is part of the
deterministic data.

Backends:
* :class:`SilentBackend` — zero dependencies; emits silence sized to the text.
  Lets the full pipeline run and be tested without any model or network.
* :class:`KokoroBackend` — the free/local Kokoro model (Apache-2.0). Needs
  ``kokoro`` and ``numpy`` installed and the model weights available.
"""

from __future__ import annotations

import re
import wave
from dataclasses import dataclass
from typing import Iterator, Optional, Protocol

from metaphrand.story import Story


@dataclass(frozen=True)
class Utterance:
    """One thing to be spoken, by one voice."""

    voice: str
    text: str
    source_id: str  # the beat this came from, for tracing


def _for_speech(text: str) -> str:
    """Light normalisation so written punctuation reads aloud cleanly.

    Turns dashes into spoken pauses and drops markdown emphasis, so prose
    written for the page (``a -- b``, ``the lens--hollow--turns``, ``*italics*``)
    is not voiced as stray symbols.
    """
    text = text.replace(" -- ", ", ")
    text = re.sub(r"\s*[—–]\s*", ", ", text)  # em/en dash -> a spoken pause
    text = text.replace("*", "")              # markdown emphasis is silent
    text = re.sub(r"\s+", " ", text)          # collapse runs of whitespace
    return text.strip()


class AudioRenderer:
    """Walk the spine and produce a cast recording.

    Cast and narrator voice default to the root's attributes (``cast`` is a
    ``{CHARACTER: voice}`` map; ``narrator_voice`` is a single voice id), and
    may be overridden via the constructor.
    """

    def __init__(
        self,
        cast: Optional[dict[str, str]] = None,
        narrator: Optional[str] = None,
        *,
        speak_slugs: bool = False,
    ) -> None:
        self._cast = cast
        self._narrator = narrator
        self.speak_slugs = speak_slugs

    def _resolve_voices(self, story: Story) -> tuple[dict[str, str], str]:
        root = story.get(story.root_id) if story.root_id else None
        attrs = root.attributes if root else {}
        cast = self._cast if self._cast is not None else dict(attrs.get("cast", {}))
        narrator = self._narrator or attrs.get("narrator_voice") or "narrator"
        return cast, narrator

    def utterances(self, story: Story) -> list[Utterance]:
        """The deterministic spoken script: a flat list of utterances."""
        if story.root_id is None:
            return []
        cast, narrator = self._resolve_voices(story)
        root = story.get(story.root_id)
        out: list[Utterance] = []
        for beat in self._spine_nodes(story, root):
            attrs = beat.attributes
            if self.speak_slugs and attrs.get("slug"):
                out.append(Utterance(narrator, _for_speech(attrs["slug"]), beat.id))
            if beat.manifestation:
                out.append(Utterance(narrator, _for_speech(beat.manifestation), beat.id))
            character = attrs.get("character")
            if character and attrs.get("dialogue"):
                voice = cast.get(character, narrator)
                out.append(Utterance(voice, _for_speech(attrs["dialogue"]), beat.id))
        return out

    def _spine_nodes(self, story: Story, root) -> Iterator:
        """Page nodes in narrative order: acts->beats, or previous->mirror->next."""
        if root.kind == "mirror":
            states = [m for m in story.children(root.id) if m.kind == "state"]
            previous = next((s for s in states if s.attributes.get("role") == "previous"), None)
            following = next((s for s in states if s.attributes.get("role") == "next"), None)
            if previous is None and states:
                previous = states[0]
            if following is None and len(states) > 1:
                following = states[1]
            if previous is not None:
                yield from story.walk(previous.id)
            yield root  # the mirror scene, at the hinge
            if following is not None:
                yield from story.walk(following.id)
        else:
            for act in (m for m in story.children(root.id) if m.kind == "act"):
                for beat in story.children(act.id):
                    yield story.get(beat.id)

    def to_wav(
        self,
        story: Story,
        backend: "TTSBackend",
        path: str,
        *,
        gap_seconds: float = 0.4,
    ) -> list[Utterance]:
        """Synthesize every utterance and stitch them into one mono WAV."""
        utterances = self.utterances(story)
        rate = backend.sample_rate
        gap = b"\x00\x00" * int(rate * gap_seconds)
        with wave.open(path, "wb") as out:
            out.setnchannels(1)
            out.setsampwidth(2)
            out.setframerate(rate)
            for index, utterance in enumerate(utterances):
                if index:
                    out.writeframes(gap)
                out.writeframes(backend.synth(utterance.text, utterance.voice))
        return utterances


def parse_screenplay(text: str, cast: dict[str, str], narrator: str) -> list[Utterance]:
    """Parse a Fountain-ish screenplay into utterances for a cast recording.

    The narrator reads the action; each cast character reads their own dialogue.
    Scene headings and transitions are not spoken; an unlisted speaker (a one-line
    extra) falls to the narrator. Blocks are separated by blank lines.

    Character cues may be bare (``RAY``) or colon-terminated (``RAY:``), with or
    without a parenthetical (``RAY (CONT'D):``) — the colon form is friendlier to
    text-to-speech. A standalone wryly on its own line (``(beat)``) is not spoken
    and does not break the speaker: the dialogue after it stays attributed to the
    character who was talking, rather than falling to the narrator.
    """
    voices = {name.upper(): voice for name, voice in cast.items()}
    out: list[Utterance] = []

    def norm(s: str) -> str:  # drop a trailing colon and any stray space
        return s.strip().rstrip(":").strip()

    def is_cue(line: str) -> bool:
        base = norm(re.sub(r"\(.*?\)", "", line))
        return (bool(base) and base == base.upper()
                and 1 <= len(base.split()) <= 4 and any(c.isalpha() for c in base))

    def spoken(parts: list[str]) -> str:
        return " ".join(p for p in parts
                        if not (p.startswith("(") and p.endswith(")")))

    last_voice: Optional[str] = None
    pending = False  # a lone wryly is holding the current speaker open

    for block in re.split(r"\n\s*\n", text):
        lines = [ln.strip() for ln in block.splitlines() if ln.strip()]
        if not lines:
            continue
        head = lines[0].upper()
        if (head.startswith(("INT.", "EXT.", "INT/", "EXT/", "I/E"))
                or head in ("FADE IN:", "FADE OUT.", "FADE TO BLACK.")
                or head.endswith("TO:")):
            last_voice, pending = None, False  # action breaks any dialogue run
            continue
        if len(lines) == 1 and lines[0].startswith("(") and lines[0].endswith(")"):
            if last_voice is not None:
                pending = True  # wryly between a cue and its continued dialogue
            continue
        opens_wryly = lines[0].startswith("(") and lines[0].endswith(")")
        if is_cue(lines[0]):
            name = norm(re.sub(r"\(.*?\)", "", lines[0])).upper()
            last_voice = voices.get(name, narrator)
            dialogue = spoken(lines[1:])
            if dialogue.strip():
                out.append(Utterance(last_voice, _for_speech(dialogue), "screenplay"))
            pending = False
        elif (pending or opens_wryly) and last_voice is not None:
            dialogue = spoken(lines)  # continued dialogue (after a lone wryly, or a block that opens with one)
            if dialogue.strip():
                out.append(Utterance(last_voice, _for_speech(dialogue), "screenplay"))
            pending = False
        else:
            out.append(Utterance(narrator, _for_speech(spoken(lines)), "screenplay"))
            last_voice, pending = None, False
    return out


class TTSBackend(Protocol):
    """Turns text in a given voice into 16-bit, mono PCM frames."""

    sample_rate: int

    def synth(self, text: str, voice: str) -> bytes: ...


class SilentBackend:
    """A dependency-free backend that emits silence sized to the text.

    Useful for exercising the full pipeline (timing, stitching, file format)
    with no model or network — the output is a silent track of roughly the
    right length.
    """

    def __init__(self, sample_rate: int = 24000, chars_per_second: float = 14.0) -> None:
        self.sample_rate = sample_rate
        self.chars_per_second = chars_per_second

    def synth(self, text: str, voice: str) -> bytes:
        seconds = max(0.3, len(text) / self.chars_per_second)
        return b"\x00\x00" * int(self.sample_rate * seconds)


class KokoroBackend:
    """The free/local Kokoro model. Requires ``kokoro`` and ``numpy``.

    Voice ids look like ``af_heart``, ``am_adam`` (American) or ``bf_emma``,
    ``bm_george`` (British); the leading letter must match ``lang_code``.
    """

    def __init__(self, lang_code: str = "a", speed: float = 1.0) -> None:
        from kokoro import KPipeline  # lazy: only needed to actually synthesize

        self.sample_rate = 24000
        self.speed = speed
        self._pipeline = KPipeline(lang_code=lang_code)

    def synth(self, text: str, voice: str) -> bytes:
        import numpy as np

        chunks = []
        for _, _, audio in self._pipeline(text, voice=voice, speed=self.speed):
            arr = audio.detach().cpu().numpy() if hasattr(audio, "detach") else np.asarray(audio)
            chunks.append(arr.astype(np.float32))
        if not chunks:
            return b""
        samples = np.concatenate(chunks)
        pcm = (np.clip(samples, -1.0, 1.0) * 32767.0).astype("<i2")
        return pcm.tobytes()
