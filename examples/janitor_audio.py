"""Render the janitor story to a multi-voice audio file.

The cast (narrator + per-character voices) is read from the seed. This script
runs end-to-end here with the dependency-free SilentBackend, which produces a
correctly-timed silent track. Swap in KokoroBackend (free/local, Apache-2.0)
for real speech once the model is installed:

    pip install kokoro numpy        # plus a system espeak-ng for phonemes

Run with:  python -m examples.janitor_audio
"""

from brehon.audio import AudioRenderer, SilentBackend, KokoroBackend  # noqa: F401
from examples.janitor import build


if __name__ == "__main__":
    story = build()
    renderer = AudioRenderer()  # cast + narrator come from the seed

    print("=== SPOKEN SCRIPT (voice : line) ===\n")
    for u in renderer.utterances(story):
        print(f"[{u.voice:>10}] {u.text}")

    # Dependency-free proof of the pipeline: a timed silent track.
    utterances = renderer.to_wav(story, SilentBackend(), "stories/janitor.wav")
    print(f"\n{len(utterances)} utterances stitched -> stories/janitor.wav (silent)")

    # For real speech, swap the backend (needs `kokoro` + `numpy` + model):
    #   renderer.to_wav(story, KokoroBackend(), "stories/janitor.wav")
