"""The pipeline — run a story through the spec's gates, stage by stage.

This is the spec (``STORY_SPEC.md``) made operational: a story is checked against
each layer's gate in order, and the result says where it passes and where it
fails. The gates are the system; the LLM only fills the slots inside each stage.

``check`` is deterministic except for the optional embodiment stage (which needs
a model). Pass the ``world`` and ``weave`` when you have them; omit them and those
stages are simply skipped.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import TYPE_CHECKING, Optional

from brehon import concreteness, doorways as _doorways, embodiment, showing
from brehon import weave as _weave
from brehon import world as _world

if TYPE_CHECKING:
    from brehon.generate import LLMClient
    from brehon.story import Story
    from brehon.weave import Weave
    from brehon.world import World


@dataclass
class StageReport:
    name: str
    passed: bool
    detail: str

    def line(self) -> str:
        mark = "PASS" if self.passed else "FAIL"
        return f"[{mark}] {self.name:<13} {self.detail}"


@dataclass
class PipelineResult:
    stages: list[StageReport] = field(default_factory=list)

    @property
    def passed(self) -> bool:
        return all(s.passed for s in self.stages)

    def failures(self) -> list[StageReport]:
        return [s for s in self.stages if not s.passed]

    def summary(self) -> str:
        return "\n".join(s.line() for s in self.stages)


def check(
    story: "Story",
    *,
    world: Optional["World"] = None,
    weave: Optional["Weave"] = None,
    client: Optional["LLMClient"] = None,
) -> PipelineResult:
    """Run the story through every gate the spec defines, in order."""
    stages: list[StageReport] = []

    # 1 — Spine
    root = story.get(story.root_id) if story.root_id else None
    stages.append(StageReport(
        "spine", root is not None and root.kind in ("mirror", "three-act"),
        f"root = {root.kind if root else 'none'}"))
    door = _doorways.doorways(story)
    stages.append(StageReport("doorways", door.passed, door.summary()))

    # 3 — World  (skipped if no cast supplied)
    if world is not None:
        full = _world.fullness(world)
        stages.append(StageReport("world", full.passed, full.summary()))

    # 4 — Weave  (skipped if no weave supplied)
    if weave is not None:
        braid = _weave.is_monorail(weave)
        stages.append(StageReport("weave", braid.passed, braid.summary()))

    # 5 — Metaphor: concrete + embodied
    flow = concreteness.report(story)
    stages.append(StageReport("concreteness", flow.flowery == 0, flow.summary()))
    if client is not None:
        legible = embodiment.legibility(story, client)
        stages.append(StageReport("embodiment", legible.passed, legible.summary()))

    # 6 — Render: show, don't tell
    told = showing.report(story)
    stages.append(StageReport("show-not-tell", told.telling == 0, told.summary()))

    return PipelineResult(stages)
