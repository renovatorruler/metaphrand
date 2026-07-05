"""THE HEIR — full multi-voice audio of the whole screenplay.

Reads the entire Fountain screenplay (from FADE IN:, skipping the title page),
casts every speaker to a distinct Kokoro voice, and renders one MP3: the narrator
reads the action, each character reads their own lines. American voice pack
(lang_code "a") for the wider pool needed by a large cast; minor one-scene parts
share a voice with someone they never share a scene with.

    python -m examples.heir_full_audio [out.mp3]

MP3 only — the WAV is a scratch intermediate and is deleted.
"""

from __future__ import annotations

import os
import subprocess
import sys
import time
import wave

from metaphrand.audio import KokoroBackend, SilentBackend, parse_screenplay

SCREENPLAY = "stories/the-heir/screenplay.fountain"
NARRATOR = "am_michael"

# Principals get their own voice; recurring minors too; one-scene extras reuse a
# voice belonging to someone they never appear beside.
CAST = {
    # principals
    "NADIR": "am_adam",
    "BAYAR": "am_onyx",
    "YUSUF": "am_puck",
    "RUSTAM": "am_fenrir", "GENERAL RUSTAM": "am_fenrir",
    "TURAN": "am_liam", "GENERAL TURAN": "am_liam",
    "ASLAN": "am_eric",
    "ANATOLY": "am_santa",
    "KERIM": "am_echo",
    "LENA": "af_bella",
    "MIRA": "af_nova",
    "SEVDA": "af_sarah",
    "FERIDA": "af_kore", "JUDGE FERIDA": "af_kore",
    "AYGÜN": "af_nicole",
    "CLAIRE VOSS": "af_alloy",
    "NESRIN": "af_sky",
    "PRIYA": "af_jessica",
    # recurring / notable minors
    "HAMID": "am_eric",
    "ESKIN": "am_santa", "GOVERNOR ESKIN": "am_santa",
    "VURAL": "am_liam", "GENERAL VURAL": "am_liam",
    "ADAK": "am_fenrir", "COLONEL ADAK": "am_fenrir",
    "DEMIR": "am_echo",
    "YALIN": "am_santa",
    "CLERK": "af_river",
    "WATCHMAN": "am_echo",
    "COLLEAGUE": "am_echo",
    "YOUNG TEACHER": "am_eric",
    "YOUNG MAN": "am_echo",
    "DIRECTOR": "am_santa",
    "BOY": "af_aoede",
    "GROUND AGENT": "af_river",
    "DEPUTY": "am_eric",
    "ARCHIVIST": "am_santa",
    "REPORTER": "af_river",
    "WESTERN AMBASSADOR": "af_heart",
    "OLD MAN ONE": "am_santa",
    "AIDE": "am_echo",
    "YOUNG SOLDIER": "am_echo", "SOLDIER": "am_echo",
    "YOUNG OFFICER": "am_echo",
    "PROTOCOL OFFICER": "am_echo",
    "CHIEF JUSTICE": "am_liam",
    "FOREIGN MINISTER": "am_santa",
    "MINISTER OF INTERIOR": "am_santa", "INTERIOR MINISTER": "am_santa",
    "FINANCE MINISTER": "am_eric",
    "RADIO": "af_heart",
}


def from_fade_in(text: str) -> str:
    i = text.find("FADE IN:")
    return text[i:] if i != -1 else text


def to_mp3(wav_path: str, mp3_path: str, bitrate: str = "160k") -> None:
    subprocess.run(
        ["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-i", wav_path,
         "-codec:a", "libmp3lame", "-b:a", bitrate, mp3_path],
        check=True,
    )


def stitch(utterances, backend, path: str, gap_seconds: float = 0.4) -> float:
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
            try:
                pcm = backend.synth(u.text, u.voice)
            except Exception as exc:  # one bad line shouldn't sink a 2-hour render
                print(f"  [skip] {u.voice}: {exc}", file=sys.stderr)
                pcm = b""
            out.writeframes(pcm)
            frames += len(pcm)
            if k % 100 == 0:
                print(f"  ...{k}/{len(utterances)} ({frames/2/rate/60:.1f} min)", file=sys.stderr)
    return frames / 2 / rate


def main(argv: list[str]) -> None:
    out = argv[0] if argv else "stories/the-heir/the-heir_full_table-read.mp3"
    text = from_fade_in(open(SCREENPLAY, encoding="utf-8").read())
    utterances = parse_screenplay(text, CAST, NARRATOR)
    print(f"=== FULL TABLE READ — THE HEIR — {len(utterances)} utterances ===")

    try:
        backend: object = KokoroBackend(lang_code="a", speed=0.97)
        kind = "Kokoro"
    except Exception as exc:
        print(f"[audio] Kokoro unavailable ({exc}); SilentBackend", file=sys.stderr)
        backend = SilentBackend()
        kind = "Silent"

    t0 = time.time()
    wav_tmp = out.rsplit(".", 1)[0] + ".tmp.wav"
    seconds = stitch(utterances, backend, wav_tmp)
    to_mp3(wav_tmp, out)
    os.remove(wav_tmp)
    print(f"\n{kind}: {len(utterances)} utterances -> {out}  "
          f"({seconds/60:.1f} min audio, rendered in {time.time()-t0:.0f}s)")


if __name__ == "__main__":
    main(sys.argv[1:])
