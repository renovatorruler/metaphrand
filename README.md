# brehon

A screenplay engine built on a single, unusual idea:

> **Everything on the page is a metaphor.**

Not a metaphor in the English-class sense — not a simile, not "her skin was as
cold as ice." We mean the bare fact that *her skin was cold* is itself a
metaphor. It need not be compared to anything; its mere presence in the story
carries meaning. A simile is not a metaphor. The thing that happens *is*.

## The model

A story is a **directed acyclic graph of metaphors**.

- Each **metaphor** embodies an abstract `meaning` (what it is about) and, once
  it reaches the page, a concrete `manifestation` (the line, the image, the
  action).
- A concrete metaphor is an **instantiation** of a more abstract one. Descending
  the graph = concretizing. The leaves are what literally appears on the page.
- The single most abstract metaphor is the **three-act structure** — the root
  of the graph. Its `meaning` is the story's controlling premise.
- It is a **DAG, not a tree**: one metaphor can be instantiated under several
  parents, so a single beat ("her skin was cold") can serve both the structural
  spine (the Act II midpoint) and a theme (the absence of another's warmth)
  without being duplicated. Edges only ever flow abstract → concrete, so the
  graph stays acyclic.

## Why a stored data structure

Generation should be **part-deterministic**: the exact words may vary run to
run, but the *core elements* — the metaphors and how they instantiate each
other — must not. So the graph is the canonical artifact. It serializes to a
**canonical JSON** form (nodes sorted by id, narrative child-order preserved)
that round-trips byte-for-byte. The graph is the source of truth; turning it
into words is a separate, deliberately fuzzy layer.

```python
from brehon import Story

story = Story()
root = story.three_act("Love demands a death of the self")
act2 = story.instantiate(root.id, "The self is besieged by another", kind="act")
beat = story.instantiate(
    act2.id, "Her skin was cold",
    manifestation="She does not pull her hand away. Her skin is cold.",
    kind="beat",
)

theme = story.instantiate(root.id, "The absence of another's warmth", kind="theme")
story.link(theme.id, beat.id)  # one beat, two parents — the DAG at work

story.save("story.json")
```

## Generating from a premise

The graph need not be hand-authored. `DagGenerator` asks a pluggable
`LLMClient` — by default a local, open-source `ollama` model, so no API keys —
to propose the whole story as one JSON document, then assembles it through the
same `Story` API. Only the *proposal* is fuzzy; the graph it lands in is the
same deterministic seed every other layer speaks, with unknown edges and voices
repaired rather than trusted.

```python
from brehon.generate import generate_story
from brehon.render import FountainRenderer

story = generate_story("A lighthouse keeper's light was built to wreck ships")
print(FountainRenderer().render(story))   # a Fountain screenplay
story.save("stories/generated.json")      # the deterministic seed
```

## Layout

| Path | What it is |
| --- | --- |
| `brehon/metaphor.py` | `Metaphor` — the atomic unit. |
| `brehon/story.py` | `Story` — the DAG, with `instantiate`/`link`, traversal, cycle protection, and canonical serialization. |
| `brehon/render.py` | The text rendering seam. `OutlineRenderer` (debug view of the whole DAG) and `FountainRenderer` (a real screenplay in [Fountain](https://fountain.io) format, walking only the structural spine). |
| `brehon/audio.py` | Multi-voice audio. `AudioRenderer` walks the spine into `(voice, text)` utterances (narrator reads action, characters read dialogue); pluggable `TTSBackend` (`KokoroBackend` free/local, `SilentBackend` dependency-free) stitched to one WAV. |
| `brehon/generate.py` | The generation seam. `DagGenerator` turns a one-line premise into the metaphor DAG via a pluggable `LLMClient` (`OllamaClient` = free/local, zero API keys); a deterministic `build_story` assembles the proposal through the `Story` API, repairing bad edges and voices rather than trusting the model. |
| `examples/three_act.py` | A tiny end-to-end story graph. |
| `examples/janitor.py` | A full generated story: builds the DAG, renders the screenplay, saves the seed. |
| `examples/janitor_audio.py` | Renders the same seed to a multi-voice audio file. |
| `examples/generate.py` | Generate a screenplay from a premise with a local model, end to end. |
| `examples/render_audio.py` | Render any stored seed to a multi-voice audio file (Kokoro, or silent fallback). |
| `stories/` | Stored seeds (`*.json`) and rendered scripts (`*.fountain`). |
| `tests/` | The DAG and determinism guarantees. |

## Develop

```bash
pip install -e ".[dev]"
pytest
python -m examples.three_act

# Generate a screenplay from a one-line premise (uses a local ollama model):
python -m examples.generate "A lighthouse keeper's light was built to wreck ships"

# Render a stored seed to multi-voice audio (Python <=3.12; needs espeak-ng):
pip install -e ".[audio]"
python -m examples.render_audio stories/generated.json stories/generated.wav
```

## Status

The metaphor DAG and its deterministic serialization; a deterministic
`FountainRenderer` (stored seed → screenplay) and `AudioRenderer` (seed →
multi-voice recording); and a `DagGenerator` that builds the DAG from a one-line
premise via a local open-source model — the fuzzy proposal landing in the same
deterministic graph every other layer already speaks.

Still open: a *fuzzy re-render* layer — paraphrasing an existing beat's wording
while holding its metaphor stack fixed, so a stored story can be re-voiced
without changing its core elements.
