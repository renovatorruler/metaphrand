"""The drama layer — every scene is a fight, or it's a postcard (Mamet).

`VOICE_GUIDE` makes it a rule: before the four PaRDeS layers, a scene needs its *engine* —
who wants what from whom, what's at stake if they don't get it, and why now. This turns
that rule from a prompt the writer is trusted to follow into a **gate** the engine checks.
Each page-level scene (a spine beat) carries a :class:`Drama`; the gate names any scene
that has none, or whose want / stakes / now is missing — the postcards, where people trade
information and nothing is at risk.

The drama is the scene's engine, not its surface: it never appears on the page (that's the
Sod's job), it's the thing the page is built to dramatize. So it lives in the graph, on the
beat, and the renderer never speaks it.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING, Optional

if TYPE_CHECKING:
    from metaphrand.metaphor import Metaphor
    from metaphrand.story import Story


@dataclass
class Drama:
    """A scene's engine: who wants what from whom, the cost, and why now."""

    want: str        # who wants what from whom
    stakes: str      # what happens if they do not get it
    now: str         # why this scene has to happen now

    def complete(self) -> bool:
        return bool(self.want.strip() and self.stakes.strip() and self.now.strip())

    def to_dict(self) -> dict:
        return {"want": self.want, "stakes": self.stakes, "now": self.now}


def attach(story: "Story", dramas: dict) -> None:
    """Hang a :class:`Drama` on each named beat (stored in the node's attributes, so it
    serializes with the graph and the renderers can ignore it)."""
    for beat_id, drama in dramas.items():
        story.get(beat_id).attributes["drama"] = drama.to_dict()


def of(node: "Metaphor") -> Optional[Drama]:
    """The Drama hung on a node, or ``None``."""
    data = node.attributes.get("drama")
    if isinstance(data, dict):
        return Drama(str(data.get("want", "")), str(data.get("stakes", "")), str(data.get("now", "")))
    return None


@dataclass
class DramaReport:
    total: int                 # scenes on the spine
    dramatized: int            # scenes carrying a complete drama
    postcards: list[str]       # beat ids with no engine (or a partial one)

    @property
    def passed(self) -> bool:
        return not self.postcards

    def summary(self) -> str:
        head = f"{self.dramatized}/{self.total} scenes carry a want, a cost, and a now"
        if self.passed:
            return head + " — every scene is a fight"
        return head + "; postcards (no engine): " + ", ".join(self.postcards)


def drama(story: "Story") -> DramaReport:
    """Mamet's gate: every scene on the spine has to be a fight — a want, a cost, a now.
    A scene with no drama (or a partial one) is a postcard; the gate names them."""
    from metaphrand.cinema import spine_beats  # the page scenes, in narrative order

    scenes = spine_beats(story)
    postcards: list[str] = []
    dramatized = 0
    for beat in scenes:
        d = of(beat)
        if d is not None and d.complete():
            dramatized += 1
        else:
            postcards.append(beat.id)
    return DramaReport(len(scenes), dramatized, postcards)
