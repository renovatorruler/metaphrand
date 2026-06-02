"""Multi-voice audio rendering — the story as a cast recording.

Like :class:`~brehon.render.FountainRenderer`, this walks only the structural
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

import wave
from dataclasses import dataclass
from typing import Optional, Protocol

from brehon.story import Story


@dataclass(frozen=True)
class Utterance:
    """One thing to be spoken, by one voice."""

    voice: str
    text: str
    source_id: str  # the beat this came from, for tracing


def _for_speech(text: str) -> str:
    """Light normalisation so written punctuation reads aloud cleanly."""
    return text.replace(" -- ", ", ").strip()


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
        acts = [m for m in story.children(root.id) if m.kind == "act"]
        for act in acts:
            for beat in story.children(act.id):
                beat = story.get(beat.id)
                attrs = beat.attributes
                if self.speak_slugs and attrs.get("slug"):
                    out.append(Utterance(narrator, _for_speech(attrs["slug"]), beat.id))
                if beat.manifestation:
                    out.append(
                        Utterance(narrator, _for_speech(beat.manifestation), beat.id)
                    )
                character = attrs.get("character")
                if character and attrs.get("dialogue"):
                    voice = cast.get(character, narrator)
                    out.append(
                        Utterance(voice, _for_speech(attrs["dialogue"]), beat.id)
                    )
        return out

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
