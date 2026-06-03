"""Character bibles — the backstory you build, feed, and keep submerged.

A writer knows far more about a character than ever reaches the page: the wound
that shaped them, how they grew up, the dead father's war, the secret they keep.
Almost none of it is exposited; it informs how they move and choose, and the
audience feels the weight without being told the cause. The model breaks this
twice — it skips the background work, and once it has the material it states all
of it ("if the material exists, it gets referenced").

This faculty is the three-move answer:

* **build** — :func:`write_bible` generates each character's backstory (the model is
  genuinely good at *inventing* it, which is exactly why it must be leashed next);
* **feed** — the bible is attached to the cast (:func:`attach`) and rendered into the
  managed prompt as *"what you know, and must not say"* (see :mod:`brehon.prompt`);
* **gate** — :func:`leak` checks the finished script: anywhere a SUBMERGED fact has
  surfaced as exposition is a leak, and is reported for cutting.

Every fact carries a depth: ``surface`` (shown in the story, never told) or
``submerged`` (informs, never appears — what broke the father at Anzio; we feel the
silence, we are never given the cause). Most of a real bible is submerged. Its job
is to exist.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import TYPE_CHECKING, Optional

if TYPE_CHECKING:
    from brehon.generate import LLMClient
    from brehon.story import Story

_WORD = re.compile(r"[a-z']+")
_STOP = {
    "the", "a", "an", "and", "or", "but", "of", "to", "in", "on", "at", "for",
    "with", "his", "her", "him", "she", "they", "them", "their", "that", "this",
    "who", "into", "out", "from", "as", "is", "was", "were", "be", "are", "it",
    "he", "you", "your", "by", "had", "has", "have", "not", "no", "than", "then",
}

_SUBMERGED = "submerged"
_SURFACE = "surface"


def _content(text: str) -> set[str]:
    return {w for w in _WORD.findall(text.lower()) if w not in _STOP and len(w) > 2}


@dataclass(frozen=True)
class Fact:
    """One thing known about a character, at a depth."""

    text: str
    depth: str = _SUBMERGED   # "surface" (shown) | "submerged" (informs only)

    def to_dict(self) -> dict:
        return {"text": self.text, "depth": self.depth}


@dataclass
class Dossier:
    """A character's bible: who they are under the story."""

    character: str          # matches a character node's name (its meaning)
    facts: list[Fact] = field(default_factory=list)

    @property
    def submerged(self) -> list[Fact]:
        return [f for f in self.facts if f.depth == _SUBMERGED]


def attach(story: "Story", dossiers) -> None:
    """Store each dossier on its character node, as a ``backstory`` attribute."""
    by_name = {d.character.lower(): d for d in _as_list(dossiers)}
    for node in story.walk():
        if node.kind != "character":
            continue
        dossier = by_name.get(node.meaning.lower())
        if dossier is not None:
            node.attributes["backstory"] = [f.to_dict() for f in dossier.facts]


def _as_list(dossiers) -> list[Dossier]:
    if isinstance(dossiers, dict):
        return list(dossiers.values())
    return list(dossiers)


def reference_block(story: "Story") -> str:
    """Render the attached bibles as the prompt's 'what you know' block.

    The whole point is the discipline: this is handed to the writer as context that
    shapes behaviour and choice, marked so it never becomes a line of dialogue or a
    paragraph of narration. Empty if no backstory is attached.
    """
    lines: list[str] = []
    for node in story.walk():
        if node.kind != "character":
            continue
        facts = node.attributes.get("backstory") or []
        if not facts:
            continue
        lines.append(f"  {node.meaning}:")
        for fact in facts:
            mark = ("(stays under — never stated)"
                    if fact.get("depth") == _SUBMERGED else "(may be shown, never told)")
            lines.append(f"    - {fact.get('text', '')} {mark}")
    if not lines:
        return ""
    header = (
        "WHAT YOU KNOW ABOUT THESE PEOPLE — and must NOT say. This is the iceberg: "
        "it shapes how they move, choose, and flinch; it NEVER becomes dialogue or "
        "narration. Show the symptom, submerge the cause."
    )
    return "\n".join([header, *lines])


@dataclass
class LeakReport:
    leaks: list[tuple[str, str, str]]   # (character, submerged fact, the offending line)

    @property
    def passed(self) -> bool:
        return not self.leaks

    def summary(self) -> str:
        if self.passed:
            return "backstory stayed under the waterline"
        first = self.leaks[0]
        more = f" (+{len(self.leaks) - 1} more)" if len(self.leaks) > 1 else ""
        return f"{len(self.leaks)} backstory leak(s): {first[0]} — \"{first[2][:48]}…\"{more}"


def leak(script: str, story: "Story", *, threshold: float = 0.5, min_words: int = 3) -> LeakReport:
    """Flag SUBMERGED backstory that surfaced as exposition in the script.

    A leak is a sentence whose content words overlap a submerged fact past
    ``threshold`` — i.e. the script came out and *stated* what should have stayed
    under the water. Surface facts are exempt (they are meant to show).
    """
    sentences = [s.strip() for s in re.split(r"(?<=[.!?])\s+|\n", script) if s.strip()]
    leaks: list[tuple[str, str, str]] = []
    for node in story.walk():
        if node.kind != "character":
            continue
        for fact in node.attributes.get("backstory") or []:
            if fact.get("depth") != _SUBMERGED:
                continue
            target = _content(fact.get("text", ""))
            if len(target) < min_words:
                continue
            for sentence in sentences:
                if len(target & _content(sentence)) / len(target) >= threshold:
                    leaks.append((node.meaning, fact.get("text", ""), sentence))
                    break
    return LeakReport(leaks)


def write_bible(
    story: "Story",
    premise: str,
    client: "LLMClient",
    *,
    warnings: Optional[list[str]] = None,
) -> list[Dossier]:
    """Generate a backstory bible for each character — most of it submerged.

    The model invents the background work it would otherwise skip; the depth tags
    and the leak gate are what stop it from spilling onto the page.
    """
    from brehon.generate import _extract_json  # lazy: avoid an import cycle

    warn = warnings if warnings is not None else []
    dossiers: list[Dossier] = []
    for node in story.walk():
        if node.kind != "character":
            continue
        name = node.meaning
        prompt = (
            f"Write the private backstory of {name} for the story: {premise}. "
            f"They want: {node.attributes.get('want', '')}. Cover the wound, the "
            "ghost (often inherited), upbringing, want versus need, the secret, and a "
            "contradiction. Mark each fact SURFACE (it is shown in the story, never "
            "told) or SUBMERGED (it only informs, never appears) — most must be "
            "submerged.\n\n"
            'Return JSON: {"facts": [{"text": "<fact>", "depth": "surface|submerged"}]}'
        )
        try:
            data = _extract_json(client.complete(
                prompt, system="You write a character bible. Output only JSON."))
            facts = [Fact(str(f.get("text", "")).strip(),
                         _SUBMERGED if str(f.get("depth", _SUBMERGED)).lower().startswith("sub")
                         else _SURFACE)
                     for f in data.get("facts", []) if str(f.get("text", "")).strip()]
        except Exception:
            facts = []
            warn.append(f"could not write a bible for {name!r}")
        dossiers.append(Dossier(name, facts))
    return dossiers
