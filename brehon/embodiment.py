"""The embodiment / legibility round-trip — concrete AND meaning-bearing.

Concreteness is necessary but not sufficient: a bare physical fact is only a
*metaphor* if it carries its meaning. The test is a round-trip — meaning →
concrete fact → can the meaning be read back off the fact alone? A beat fails two
ways: it **restates** the meaning (on-the-nose telling — caught deterministically
by word overlap), or it is **illegible** (a model, shown only the manifestation,
cannot recover the intended meaning).

The on-the-nose check stands without a model. The legibility check needs one — it
asks the model what a line means, then scores the recovery deterministically.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from brehon.generate import LLMClient
    from brehon.story import Story

_STOP = {
    "the", "a", "an", "and", "or", "but", "of", "to", "in", "on", "at", "for",
    "with", "as", "is", "was", "were", "be", "been", "being", "are", "am", "he",
    "she", "it", "his", "her", "him", "they", "them", "their", "that", "this",
    "these", "those", "by", "from", "into", "out", "up", "down", "off", "over",
    "not", "no", "so", "who", "which", "what", "when", "where", "why", "how",
    "all", "any", "some", "then", "than", "there", "here", "you", "your", "i",
    "we", "our", "us", "my", "me", "had", "has", "have", "will", "would",
}
_WORD = re.compile(r"[a-z]+")


def _content(text: str) -> set[str]:
    return {w for w in _WORD.findall(text.lower()) if w not in _STOP and len(w) > 2}


def restates_meaning(manifestation: str, meaning: str, *, threshold: float = 0.6) -> bool:
    """True if the manifestation literally restates the meaning (on-the-nose)."""
    target = _content(meaning)
    if not target:
        return False
    return len(target & _content(manifestation)) / len(target) >= threshold


def _recovers(inferred: str, meaning: str, *, threshold: float = 0.34) -> bool:
    target = _content(meaning)
    if not target:
        return True
    return len(target & _content(inferred)) / len(target) >= threshold


@dataclass
class LegibilityReport:
    total: int
    offenders: list[tuple[str, str]]   # (node_id, "on-the-nose" | "illegible")

    @property
    def passed(self) -> bool:
        return not self.offenders

    def summary(self) -> str:
        if self.passed:
            return f"{self.total} page beats embodied & legible"
        detail = ", ".join(f"{i}:{kind}" for i, kind in self.offenders)
        return f"{len(self.offenders)}/{self.total} not embodied — {detail}"


def _infer_meaning(client: "LLMClient", manifestation: str) -> str:
    from brehon.generate import _extract_json  # lazy: avoid an import cycle

    prompt = (
        "Read this line and say, in a short phrase, what it MEANS — the idea it "
        "embodies, not a paraphrase of the action.\n\n"
        f"LINE: {manifestation}\n\n"
        'Return JSON: {"meaning": "<the meaning>"}'
    )
    try:
        data = _extract_json(client.complete(
            prompt, system="You read the meaning off concrete prose. Output only JSON."))
    except Exception:
        return ""
    return str(data.get("meaning", "")).strip()


def legibility(story: "Story", client: "LLMClient") -> LegibilityReport:
    """Round-trip every page beat: is its meaning recoverable from the fact?"""
    total = 0
    offenders: list[tuple[str, str]] = []
    for node in story.walk():
        manifestation, meaning = node.manifestation.strip(), node.meaning.strip()
        if not (manifestation and meaning):
            continue
        total += 1
        if restates_meaning(manifestation, meaning):
            offenders.append((node.id, "on-the-nose"))
            continue
        if not _recovers(_infer_meaning(client, manifestation), meaning):
            offenders.append((node.id, "illegible"))
    return LegibilityReport(total, offenders)
