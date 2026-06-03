"""Render a stored seed to a multi-voice audio file.

The cast (narrator + per-character voices) is read from the seed, so casting is
deterministic data, not a flag. Uses the free/local :class:`KokoroBackend` when
it is installed (``pip install -e ".[audio]"`` on Python <=3.12, plus system
``espeak-ng``); otherwise it falls back to the dependency-free
:class:`SilentBackend` so the pipeline still produces a correctly-timed file.

Run with:
    python -m examples.render_audio                              # janitor seed
    python -m examples.render_audio stories/generated.json out.wav
"""

import sys

from brehon import Story
from brehon.audio import AudioRenderer, KokoroBackend, SilentBackend


def main(argv: list[str]) -> None:
    seed = argv[0] if argv else "stories/janitor.json"
    out = argv[1] if len(argv) > 1 else seed.rsplit(".", 1)[0] + ".wav"

    story = Story.load(seed)
    renderer = AudioRenderer()  # cast + narrator come from the seed

    try:
        backend: object = KokoroBackend()
        kind = "Kokoro (real speech)"
    except Exception as exc:  # missing model/deps -> still produce a timed file
        print(f"[audio] Kokoro unavailable ({exc}); using SilentBackend", file=sys.stderr)
        backend = SilentBackend()
        kind = "Silent (timed placeholder)"

    print(f"=== SPOKEN SCRIPT  (seed: {seed}, backend: {kind}) ===\n")
    utterances = renderer.utterances(story)
    for utterance in utterances:
        print(f"[{utterance.voice:>10}] {utterance.text}")

    renderer.to_wav(story, backend, out)  # re-walks the spine and stitches
    print(f"\n{len(utterances)} utterances stitched -> {out}")


if __name__ == "__main__":
    main(sys.argv[1:])
