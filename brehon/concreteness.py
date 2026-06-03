"""Track and enforce concreteness — the anti-ornament layer.

In the brehon (Jaynesian) sense every manifestation is already a metaphor: an
abstract meaning (*metaphrand*) carried by a concrete thing (*metaphier*). The
sin is not *having* metaphors — it is *decorating* them. A manifestation must be
a bare physical fact ("Her skin is cold"), never ornament ("her skin was cold
as the absence of his warmth", "the glass bleeds rainbows", "cracks bloom like
veins in ice").

This module measures how concrete a manifestation is and flags the ornamental
crimes — simile, decorative personification / purple verbs, abstract
meaning-naming nouns, and markdown emphasis — so generation can drive a story
toward ~0% flowery. The linter is deliberately lexical and conservative: it
catches the obvious crimes without false-flagging plain prose (the hand-written
janitor story scores clean), and the LLM ``concretize`` pass handles the rest.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from typing import TYPE_CHECKING, Iterator, Optional

if TYPE_CHECKING:
    from brehon.generate import LLMClient
    from brehon.metaphor import Metaphor
    from brehon.story import Story


# Ornamental / personifying verbs that almost never describe a bare physical
# fact in this register. Matched as whole words, across common inflections.
_PURPLE = {
    "bleed", "bleeds", "bled", "bleeding",
    "bloom", "blooms", "bloomed", "blooming",
    "shimmer", "shimmers", "shimmered", "shimmering",
    "glisten", "glistens", "glistened", "glistening",
    "glimmer", "glimmers", "glimmered", "glimmering",
    "weep", "weeps", "wept", "weeping",
    "thrum", "thrums", "thrummed", "thrumming",
    "sing", "sings", "sang", "singing",
    "breathe", "breathes", "breathed", "breathing",
    "whisper", "whispers", "whispered", "whispering",
    "murmur", "murmurs", "murmured", "murmuring",
    "dance", "dances", "danced", "dancing",
    "caress", "caresses", "caressed", "caressing",
    "devour", "devours", "devoured", "devouring",
}

# Abstract nouns that name the *meaning* outright (the on-the-nose sin) or read
# as poetic labels rather than concrete things.
_ABSTRACT = {
    "refusal", "betrayal", "guilt", "fate", "destiny", "sorrow", "despair",
    "longing", "oblivion", "eternity", "soul", "redemption", "salvation",
    "innocence", "abyss", "void", "doom", "anguish", "yearning", "essence",
}

_LIKE = re.compile(r"\blike\b", re.IGNORECASE)
_AS_AS = re.compile(r"\bas\b\s+\w+\s+\bas\b", re.IGNORECASE)
_EMPHASIS = re.compile(r"\*[^*]+\*")
_WORD = re.compile(r"[a-z]+")


@dataclass(frozen=True)
class Finding:
    """One ornamental crime found in a line."""

    kind: str   # "simile" | "purple-verb" | "abstract" | "emphasis"
    text: str   # the offending token


def findings(text: str) -> list[Finding]:
    """Every ornamental crime in ``text`` (an empty list means bare/concrete)."""
    out: list[Finding] = []
    as_as = _AS_AS.search(text)
    if as_as:
        out.append(Finding("simile", as_as.group(0)))
    elif _LIKE.search(text):
        out.append(Finding("simile", "like"))
    for word in _WORD.findall(text.lower()):
        if word in _PURPLE:
            out.append(Finding("purple-verb", word))
        elif word in _ABSTRACT:
            out.append(Finding("abstract", word))
    if _EMPHASIS.search(text):
        out.append(Finding("emphasis", "*…*"))
    return out


def score(text: str) -> float:
    """Concreteness in 0.0–1.0: 1.0 is bare fact; each crime costs ~a third."""
    if not text.strip():
        return 1.0
    return round(max(0.0, 1.0 - 0.34 * len(findings(text))), 2)


def is_flowery(text: str) -> bool:
    """True if the line carries any ornament at all."""
    return bool(findings(text))


def _assessed_text(node: "Metaphor") -> str:
    """The page text of a node: its action line plus any spoken dialogue."""
    parts = [node.manifestation, node.attributes.get("dialogue", "")]
    return " ".join(p for p in parts if p)


def _assessed_nodes(story: "Story") -> Iterator[tuple["Metaphor", str]]:
    for node in story.walk():
        text = _assessed_text(node)
        if text.strip():
            yield node, text


@dataclass
class ConcretenessReport:
    """How much of a story's page text is still ornamental."""

    total: int
    flowery: int
    offenders: list[tuple[str, list[Finding]]]  # (node_id, findings)

    @property
    def fraction(self) -> float:
        return self.flowery / self.total if self.total else 0.0

    def summary(self) -> str:
        pct = f"{self.fraction:.0%}"
        return f"{self.flowery}/{self.total} page metaphors still flowery ({pct})"


def report(story: "Story") -> ConcretenessReport:
    """Measure the story's flowery fraction without mutating it."""
    total = flowery = 0
    offenders: list[tuple[str, list[Finding]]] = []
    for node, text in _assessed_nodes(story):
        found = findings(text)
        total += 1
        if found:
            flowery += 1
            offenders.append((node.id, found))
    return ConcretenessReport(total, flowery, offenders)


def annotate(story: "Story") -> ConcretenessReport:
    """Write a ``concreteness`` score onto every page metaphor, and report."""
    for node, text in _assessed_nodes(story):
        node.concreteness = score(text)
    return report(story)


def _accept(old: str, new: str) -> bool:
    """Take a rewrite only if it is clean, or at least less ornamental."""
    return bool(new) and (not findings(new) or len(findings(new)) < len(findings(old)))


def _rewrite(client: "LLMClient", line: str, *, dialogue: bool = False) -> str:
    """Ask the model to restate one line as a bare physical fact."""
    from brehon.generate import _extract_json  # lazy: avoids an import cycle

    what = "line of dialogue" if dialogue else "line of action"
    prompt = (
        f"Rewrite this {what} as a bare, literal, physical fact — the same "
        "event, stripped of all ornament. Forbidden: simile (no 'like', no "
        "'as X as'), personification, purple verbs (bleeds, blooms, sings, "
        "breathes, thrums…), abstract nouns that name a feeling or meaning, and "
        "markdown. Use concrete nouns and plain verbs; keep it to one sentence.\n\n"
        f"LINE: {line}\n\n"
        'Return JSON: {"line": "<your concrete rewrite>"}'
    )
    try:
        reply = client.complete(prompt, system="You concretize prose. Output only JSON.")
        data = _extract_json(reply)
    except Exception:
        return ""
    return str(data.get("line", "")).strip()


def concretize(
    story: "Story",
    client: "LLMClient",
    *,
    max_rounds: int = 2,
    warnings: Optional[list[str]] = None,
) -> ConcretenessReport:
    """Rewrite ornamental page text into bare physical fact, in place.

    Only the *wording* changes — every metaphor's meaning, kind, and edges stay
    fixed (this is the README's "fuzzy re-render keeping the stack fixed",
    pointed at concreteness). Bounded by ``max_rounds``; stops early at 0%.
    """
    warn = warnings if warnings is not None else []
    rep = annotate(story)
    for _ in range(max_rounds):
        if rep.flowery == 0:
            break
        for node_id, _found in rep.offenders:
            node = story.get(node_id)
            if is_flowery(node.manifestation):
                new = _rewrite(client, node.manifestation)
                if _accept(node.manifestation, new):
                    node.manifestation = new
                else:
                    warn.append(f"could not concretize action {node_id!r}")
            spoken = node.attributes.get("dialogue", "")
            if spoken and is_flowery(spoken):
                new = _rewrite(client, spoken, dialogue=True)
                if _accept(spoken, new):
                    node.attributes = {**node.attributes, "dialogue": new}
                else:
                    warn.append(f"could not concretize dialogue {node_id!r}")
        rep = annotate(story)
    return rep
