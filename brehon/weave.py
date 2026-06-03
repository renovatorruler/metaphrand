"""The Weave layer — multiple threads, braided, gated against the monorail.

A movie runs an A-story braided with one or more B-stories that refract the
theme through other people; the B-story usually carries the heart. This module
models the threads and the interleaved reading order, and gates against the
recurring failure: a single line run straight to the horizon.

The **monorail gate** is deterministic. It checks three things, none of which
need a model: there is more than one thread; at least one other thread shares a
character with the spine (so it *refracts* it rather than running parallel); and
the beats are interleaved, not stacked in one block per thread.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from typing import TYPE_CHECKING, Any, Optional

if TYPE_CHECKING:
    from brehon.generate import LLMClient


@dataclass
class Thread:
    """One storyline: a question dramatized through a set of characters/beats."""

    id: str
    label: str                 # "A", "B", "C" …
    question: str              # what this thread dramatizes
    role: str = "subplot"      # "spine" | "heart" | "subplot"
    character_ids: list[str] = field(default_factory=list)
    beat_ids: list[str] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": self.id, "label": self.label, "question": self.question,
            "role": self.role, "character_ids": list(self.character_ids),
            "beat_ids": list(self.beat_ids),
        }

    @classmethod
    def from_dict(cls, d: dict[str, Any]) -> "Thread":
        return cls(
            id=str(d["id"]), label=str(d.get("label", "?")),
            question=str(d.get("question", "")), role=str(d.get("role", "subplot")),
            character_ids=[str(c) for c in d.get("character_ids", [])],
            beat_ids=[str(b) for b in d.get("beat_ids", [])],
        )


def _runs(seq: list[str]) -> int:
    """Count maximal runs of equal values: [A,A,B,B] -> 2, [A,B,A,B] -> 4."""
    runs = 0
    prev: object = object()
    for x in seq:
        if x != prev:
            runs += 1
            prev = x
    return runs


@dataclass
class WeaveReport:
    threads: int
    reasons: list[str]

    @property
    def passed(self) -> bool:
        return not self.reasons

    def summary(self) -> str:
        verdict = "woven" if self.passed else "monorail"
        return f"{self.threads} threads — {verdict}" + (
            "" if self.passed else ": " + "; ".join(self.reasons))


@dataclass
class Weave:
    """The braid: the threads plus the interleaved reading order of their beats."""

    threads: list[Thread] = field(default_factory=list)
    order: list[str] = field(default_factory=list)  # beat ids, in reading order

    def add(self, thread: Thread) -> Thread:
        self.threads.append(thread)
        return thread

    def _label_of(self, beat_id: str) -> Optional[str]:
        for t in self.threads:
            if beat_id in t.beat_ids:
                return t.label
        return None

    def thread_sequence(self) -> list[str]:
        """The thread label of each beat in reading order (unknowns dropped)."""
        return [lbl for lbl in (self._label_of(b) for b in self.order) if lbl is not None]

    def to_dict(self) -> dict[str, Any]:
        return {"threads": [t.to_dict() for t in self.threads], "order": list(self.order)}

    @classmethod
    def from_dict(cls, d: dict[str, Any]) -> "Weave":
        return cls([Thread.from_dict(t) for t in d.get("threads", [])],
                   [str(b) for b in d.get("order", [])])


def is_monorail(weave: "Weave") -> WeaveReport:
    """Deterministic gate: is this braided, or one line to the horizon?"""
    threads = weave.threads
    reasons: list[str] = []

    if len(threads) < 2:
        reasons.append("only one thread — a monorail")
    else:
        spine = next((t for t in threads if t.role == "spine"), threads[0])
        spine_chars = set(spine.character_ids)
        others = [t for t in threads if t is not spine]
        if spine_chars and not any(set(t.character_ids) & spine_chars for t in others):
            reasons.append("no other thread shares a character with the spine — not refracting it")

    seq = weave.thread_sequence()
    if seq and _runs(seq) <= len(set(seq)):
        reasons.append("threads run in blocks (A then B), not interleaved")
    return WeaveReport(len(threads), reasons)


# -- the LLM pass: propose the B-thread(s) and an interleave ----------------

_SYSTEM = """\
You braid a screenplay's threads. The A-story is the protagonist's spine. Add
one or two B-stories that refract the SAME theme through OTHER characters in the
world (the B-story usually carries the heart, e.g. a love story), each sharing at
least one character with the spine. Then interleave the beats — never all of A
then all of B.

Return ONE JSON object:
{"threads": [{"id","label","question","role","character_ids":[...],"beat_ids":[...]}],
 "order": ["beat-id", ...]}  (order = every beat, interleaved).\
"""


def braid(
    premise: str,
    spine: "Thread",
    character_ids: list[str],
    client: "LLMClient",
    *,
    warnings: Optional[list[str]] = None,
) -> "Weave":
    """Propose B-thread(s) and an interleaved order, gated by the monorail check."""
    from brehon.generate import _extract_json  # lazy: avoid an import cycle

    warn = warnings if warnings is not None else []
    prompt = (
        f"Premise: {premise}\n\n"
        f"A-story (spine): {spine.question}\n"
        f"Spine beats (in order): {spine.beat_ids}\n"
        f"Characters available: {character_ids}\n\n"
        "Add the B-thread(s) and return the full braided JSON."
    )
    try:
        reply = client.complete(prompt, system=_SYSTEM)
        data = _extract_json(reply)
    except Exception:
        return Weave([spine], list(spine.beat_ids))

    weave = Weave.from_dict(data)
    if spine.id not in {t.id for t in weave.threads}:
        weave.threads.insert(0, spine)
    if not weave.order:
        weave.order = list(spine.beat_ids)
    report = is_monorail(weave)
    if report.reasons:
        warn.extend(report.reasons)
    return weave
