"""THE HEIR — a multi-voice table read of the opening.

Reads the Fountain screenplay, casts each speaker to a Kokoro voice, and renders
one MP3: the narrator reads the action lines, each character reads their own
dialogue (parentheticals and scene headings stay silent). British voices
throughout — Lena is English, Nadir is London-educated, and the deadpan register
suits the rest. Casting lives here, in plain sight, as data.

    python -m examples.heir_table_read [out.wav]

Defaults to the opening movement (the death, the funeral, the marriage night) —
roughly the first five minutes. Falls back to SilentBackend if Kokoro is absent
so the pipeline still yields a correctly-timed file.
"""

from __future__ import annotations

import os
import subprocess
import sys
import time
import wave

from metaphrand.audio import KokoroBackend, SilentBackend, parse_screenplay

SCREENPLAY = "stories/the-heir/screenplay.fountain"

# Narrator + per-character voices (Kokoro British pack; lang_code "b").
NARRATOR = "bm_george"   # calm, measured — the camera's eye
CAST = {
    "NADIR": "bm_lewis",            # the heir: younger, refined, conciliatory
    "BAYAR": "bm_daniel",           # the old wolf: dry, low, unhurried
    "LENA": "bf_emma",              # English, exact, the one who says the true thing
    "PROTOCOL OFFICER": "bm_fable", # a nervier, lighter male
}


def opening(text: str, start: str = "FADE IN:",
            end: str = "INT. ASTAN CENTRAL HOSPITAL") -> str:
    """Slice scenes 1-3 (after the title page, before the hospital)."""
    i, j = text.find(start), text.find(end)
    return text[i:j] if i != -1 and j != -1 else text


def stitch(utterances, backend, path: str, gap_seconds: float = 0.45) -> float:
    """Synthesize each utterance and stitch into one mono WAV. Returns seconds."""
    rate = backend.sample_rate
    gap = b"\x00\x00" * int(rate * gap_seconds)
    frames = 0
    with wave.open(path, "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(rate)
        for k, u in enumerate(utterances):
            if k:
                out.writeframes(gap)
                frames += len(gap)
            pcm = backend.synth(u.text, u.voice)
            out.writeframes(pcm)
            frames += len(pcm)
    return frames / 2 / rate


def to_mp3(wav_path: str, mp3_path: str, bitrate: str = "192k") -> None:
    """Encode a WAV to MP3 with ffmpeg. Deliverables are MP3, never WAV."""
    subprocess.run(
        ["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-i", wav_path,
         "-codec:a", "libmp3lame", "-b:a", bitrate, mp3_path],
        check=True,
    )


def main(argv: list[str]) -> None:
    out = argv[0] if argv else "stories/the-heir/the-heir_table-read_opening.mp3"
    text = opening(open(SCREENPLAY, encoding="utf-8").read())
    utterances = parse_screenplay(text, CAST, NARRATOR)

    who = {v: k for k, v in CAST.items()}
    who[NARRATOR] = "NARRATOR"
    print(f"=== TABLE READ - THE HEIR (opening) - {len(utterances)} lines ===\n")
    for u in utterances:
        print(f"[{who.get(u.voice, u.voice):>16}] {u.text[:88]}")

    try:
        backend: object = KokoroBackend(lang_code="b", speed=0.96)
        kind = "Kokoro (real speech)"
    except Exception as exc:
        print(f"[audio] Kokoro unavailable ({exc}); using SilentBackend", file=sys.stderr)
        backend = SilentBackend()
        kind = "Silent (timed placeholder)"

    t0 = time.time()
    wav_tmp = out.rsplit(".", 1)[0] + ".tmp.wav"
    seconds = stitch(utterances, backend, wav_tmp)
    to_mp3(wav_tmp, out)  # MP3 is the deliverable; the WAV is a scratch intermediate
    os.remove(wav_tmp)
    print(f"\n{kind}: {len(utterances)} utterances -> {out}"
          f"  ({seconds / 60:.1f} min audio, rendered in {time.time() - t0:.0f}s)")


if __name__ == "__main__":
    main(sys.argv[1:])
