"""metaphrand.preflight — the per-work GATE: the design artifacts that MUST exist before a story is
drafted or produced.

The problem this fixes: a required pass with no enforcing gate gets skipped. We skipped the
natal-chart + voice-card half of the per-work pass (docs/05 §"Per-work, before drafting"; docs/04)
for AMAL and drafted eleven screenplay versions on top of the gap, because nothing *stopped* us —
there was no missing file to notice and nothing halted the next phase. Documentation is not
enforcement.

This makes the skip impossible to miss: production refuses to start while any required artifact is
absent or incomplete. Wire it into EVERY entry point that drafts or produces (the scene-writer, the
render / assemble / upload scripts, the cast builder):

    from metaphrand.preflight import require
    require("amal")          # raises SystemExit with a report if the gate is red

CLI:  python -m metaphrand.preflight amal     # exit 0 == green, 1 == blocked
"""
from __future__ import annotations

import importlib
import os
import re
import sys
from dataclasses import dataclass

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STORIES = os.path.join(ROOT, "stories")
if ROOT not in sys.path:
    sys.path.insert(0, ROOT)


@dataclass
class Artifact:
    filename: str
    label: str
    per_character: bool = False   # must carry an entry for EVERY cast member, not just exist
    min_chars: int = 200          # guard against a stub/empty file ticking the box


# The per-work pass manifest (docs/05), expressed as DATA the gate enforces rather than prose to
# remember. Add a story's required design artifacts here; the gate does the rest.
REQUIRED: list[Artifact] = [
    Artifact("BIBLE.md",       "World bible — register, place, the engine"),
    Artifact("BACKSTORY.md",   "Iceberg backstories — informs, never stated"),
    Artifact("CHARTS.md",      "Natal charts — the voice generator (docs/04)", per_character=True),
    Artifact("VOICE_CARDS.md", "Voice cards read from the charts (six axes)",  per_character=True),
]


def _cast(slug: str) -> list[str]:
    """The cast keys from projects/<slug>.py — the single source of truth for who exists."""
    mod = importlib.import_module(f"projects.{slug}")
    proj = getattr(mod, "PROJECT", None)
    cast = (getattr(proj, "cast", None) if proj else None) or getattr(mod, "CAST_LOOKS", {})
    return sorted(cast.keys())


def audit(slug: str) -> list[str]:
    """Return a list of failure strings; empty list == the gate is green."""
    sdir = os.path.join(STORIES, slug)
    if not os.path.isdir(sdir):
        return [f"story dir missing: stories/{slug}/"]
    fails: list[str] = []
    try:
        cast = _cast(slug)
    except Exception as e:                                   # noqa: BLE001 — report, don't crash
        cast = []
        fails.append(f"cannot load cast from projects/{slug}.py ({e})")
    for art in REQUIRED:
        path = os.path.join(sdir, art.filename)
        if not os.path.exists(path):
            fails.append(f"MISSING  {art.filename:14} — {art.label}")
            continue
        text = open(path, encoding="utf-8").read()
        if len(text.strip()) < art.min_chars:
            fails.append(f"EMPTY    {art.filename:14} — {art.label} (<{art.min_chars} chars)")
            continue
        if art.per_character and cast:
            low = text.lower()
            missing = [c for c in cast if not re.search(rf"\b{re.escape(c)}\b", low)]
            if missing:
                fails.append(f"PARTIAL  {art.filename:14} — no entry for: {', '.join(missing)}")
    return fails


def report(slug: str, fails: list[str]) -> str:
    if not fails:
        return f"preflight [{slug}]: PASS — every per-work design artifact present and complete."
    body = "\n".join(f"  ✗ {f}" for f in fails)
    return (f"preflight [{slug}]: FAIL — {len(fails)} gap(s). DRAFTING / PRODUCTION IS BLOCKED until "
            f"these exist (docs/05 per-work pass; metaphrand/preflight.py is the manifest):\n{body}")


def passes(slug: str) -> bool:
    return not audit(slug)


def require(slug: str) -> None:
    """Call at the top of any draft/production entry point — hard-stops while the gate is red."""
    fails = audit(slug)
    if fails:
        raise SystemExit(report(slug, fails))


if __name__ == "__main__":
    slug = sys.argv[1] if len(sys.argv) > 1 else "amal"
    fails = audit(slug)
    print(report(slug, fails), flush=True)
    sys.exit(1 if fails else 0)
