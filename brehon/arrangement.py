"""The arrangement layer — story-time vs plot-time (the order of telling).

Brehon's beat order is chronological: the spine is the events as they happen. But
a film is not obliged to tell them in that order. The order of *telling* is a craft
choice independent of the order of *events* — open near the end and flash back,
start in the middle, bookend the film on a moment we return to and only then
understand. The model doesn't do this on its own; it tells everything front to
back, exactly like the seed.

This layer separates the two clocks:

* **story-time** — the chronological spine (fixed, and causal by construction);
* **plot-order** — the presentation sequence, held on the root as a ``plot_order``
  list of beat ids. Absent, it defaults to chronological and nothing changes.

A *frame* (cold open) is a beat shown first and returned to at its real
chronological spot — the death we open on, flash back from, and arrive at again,
now able to feel it. :func:`frame` sets one up.

The gate checks the re-ordering is legal the way the doorways gate checks the
spine: every beat is still presented, a cold open sits on a real turn (not a random
beat), and a frame returns (no orphaned jump). Causality needs no separate check —
story-time is the spine, and the spine is causal by construction. Reordering the
*telling* never reorders the *events*.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING

from brehon import cinema as _cinema

if TYPE_CHECKING:
    from brehon.metaphor import Metaphor
    from brehon.story import Story


def story_order(story: "Story") -> list["Metaphor"]:
    """Chronological: the events as they happen (the spine)."""
    return _cinema.spine_beats(story)


def plot_order(story: "Story") -> list["Metaphor"]:
    """Presentation: the order the audience meets the beats.

    Honors a ``plot_order`` list of ids on the root; absent, it is chronological.
    A beat id may appear twice (a frame: the cold open and its later return).
    """
    if story.root_id is None:
        return []
    chrono = story_order(story)
    ids = story.get(story.root_id).attributes.get("plot_order")
    if not ids:
        return chrono
    by_id = {b.id: b for b in chrono}
    return [by_id[i] for i in ids if i in by_id]


def frame(story: "Story", beat_id: str) -> None:
    """Set a cold-open frame: show ``beat_id`` first, flash back, return to it.

    Presentation becomes: the framed beat, then everything chronologically before
    it (the flashback), then the framed beat again at its real spot and onward.
    """
    chrono = [b.id for b in story_order(story)]
    if beat_id not in chrono:
        raise KeyError(beat_id)
    k = chrono.index(beat_id)
    story.get(story.root_id).attributes["plot_order"] = [beat_id] + chrono[:k] + chrono[k:]


def is_linear(story: "Story") -> bool:
    return [b.id for b in plot_order(story)] == [b.id for b in story_order(story)]


@dataclass
class ArrangementReport:
    linear: bool
    cold_opens: list[str]
    issues: list[str]

    @property
    def passed(self) -> bool:
        return not self.issues

    def summary(self) -> str:
        if self.issues:
            return "; ".join(self.issues)
        if self.linear:
            return "chronological"
        return "framed: cold open on " + ", ".join(self.cold_opens)


def arrangement(story: "Story") -> ArrangementReport:
    """Check the telling order is a legal re-arrangement of the events."""
    if story.root_id is None:
        return ArrangementReport(True, [], [])
    chrono = story_order(story)
    chrono_ids = [b.id for b in chrono]
    chrono_index = {bid: i for i, bid in enumerate(chrono_ids)}
    is_turn = {
        b.id: (b.kind == "mirror"
               or bool(b.attributes.get("function") or b.attributes.get("doorway")))
        for b in chrono
    }
    plot = [b.id for b in plot_order(story)]
    if not plot:
        return ArrangementReport(True, [], [])

    linear = plot == chrono_ids
    issues: list[str] = []
    cold_opens: list[str] = []

    dropped = [bid for bid in chrono_ids if bid not in set(plot)]
    if dropped:
        issues.append(f"{len(dropped)} beat(s) never presented")

    first = plot[0]
    if chrono_index.get(first, 0) > 0:        # we opened later than the beginning
        cold_opens.append(first)
        if not is_turn.get(first, False):
            issues.append(f"cold open {first!r} sits on a weak beat, not a turn")
        if plot.count(first) < 2:
            issues.append(f"cold open {first!r} never returns (frame doesn't close)")

    return ArrangementReport(linear, cold_opens, issues)
