"""The two doorways of no return — the Act 1 and Act 2 breaks, as a gate.

End of Act 1: an irreversible event that locks the hero out of the ordinary
world (no turning back = stakes). End of Act 2: the event that forces him into
the test. Beats carry these with an attribute ``doorway`` set to ``1`` or ``2``.

The gate is structural and deterministic: both doorways must be present, and
Doorway 1 must come before Doorway 2 in narrative order. Whether each is truly
*irreversible* is a semantic judgement left to the writer (or an LLM check).
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from brehon.metaphor import Metaphor
    from brehon.story import Story


def _doorway_of(node: "Metaphor") -> str:
    value = node.attributes.get("doorway")
    return str(value) if str(value) in ("1", "2") else ""


@dataclass
class DoorwayReport:
    has_one: bool
    has_two: bool
    ordered: bool
    reasons: list[str]

    @property
    def passed(self) -> bool:
        return not self.reasons

    def summary(self) -> str:
        return "doorways: " + ("both present, in order" if self.passed
                               else "; ".join(self.reasons))


def doorways(story: "Story") -> DoorwayReport:
    """Both doorways present, Doorway 1 before Doorway 2 in narrative order?"""
    pos_one = pos_two = None
    for index, node in enumerate(story.walk()):
        door = _doorway_of(node)
        if door == "1" and pos_one is None:
            pos_one = index
        elif door == "2" and pos_two is None:
            pos_two = index

    reasons: list[str] = []
    if pos_one is None:
        reasons.append("no Doorway 1 — nothing locks the hero out of the ordinary world")
    if pos_two is None:
        reasons.append("no Doorway 2 — nothing forces the hero into the test")
    ordered = not (pos_one is not None and pos_two is not None and pos_one > pos_two)
    if not ordered:
        reasons.append("doorways out of order — Doorway 1 must precede Doorway 2")

    return DoorwayReport(pos_one is not None, pos_two is not None, ordered, reasons)
