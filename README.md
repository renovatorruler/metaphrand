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

## Layout

| Path | What it is |
| --- | --- |
| `brehon/metaphor.py` | `Metaphor` — the atomic unit. |
| `brehon/story.py` | `Story` — the DAG, with `instantiate`/`link`, traversal, cycle protection, and canonical serialization. |
| `brehon/render.py` | The rendering seam (words). Ships a deterministic outline view; the real surface layer (LLM vs. template) is **not yet decided**. |
| `examples/three_act.py` | A tiny end-to-end story graph. |
| `tests/` | The DAG and determinism guarantees. |

## Develop

```bash
pip install -e ".[dev]"
pytest
python -m examples.three_act
```

## Status

Foundation: the metaphor DAG and its deterministic serialization. Still open:
how leaves become screenplay text (the deliberately non-deterministic layer).
