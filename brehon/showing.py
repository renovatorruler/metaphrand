"""The Show-not-tell layer — detect telling, convert it to showing.

A told claim ("he was brave", "she felt jealous", "there was no out-arguing him")
asks the reader to take the writer's word for it. The show-not-tell pass finds
those claims and trades each for a moment the reader concludes for themselves.

The **tell-detector** is deterministic and lexical, in the same spirit as the
concreteness linter: it flags interiority verbs (knew, felt, realized…), the
linking-verb-plus-trait pattern (was brave, seemed scared), and a few summary
constructions. The :func:`show` pass uses an LLM to dramatize what it flags; the
detector is the authority on whether a line is still telling.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from typing import TYPE_CHECKING, Iterator, Optional

if TYPE_CHECKING:
    from brehon.generate import LLMClient
    from brehon.metaphor import Metaphor
    from brehon.story import Story

# Verbs that narrate the inside of a head instead of showing it.
_INTERIORITY = {
    "knew", "know", "knows", "felt", "feels", "feel", "realized", "realised",
    "realize", "realizes", "understood", "understands", "understand", "sensed",
    "senses", "wanted", "wants", "decided", "decides", "remembered", "remembers",
    "believed", "believes", "hoped", "hopes", "feared", "fears", "wondered",
    "wonders", "recognized", "recognised", "thought", "thinks",
}

# Character traits/emotions that should be shown, not asserted.
_TRAITS = (
    "brave|cowardly|coward|scared|afraid|fearful|jealous|envious|angry|furious|sad|"
    "happy|proud|ashamed|lonely|nervous|anxious|calm|kind|cruel|smart|clever|stupid|"
    "strong|weak|confident|shy|bitter|miserable|desperate|hopeful|terrified|"
    "embarrassed|guilty|restless|ruthless|gentle|fierce|content"
)
_STATE = re.compile(
    r"\b(?:was|were|is|are|been|seemed|seems|looked|looks|appeared|appears|became|"
    r"becomes|grew)\b(?:\s+\w+){0,2}?\s+\b(?:" + _TRAITS + r")\b",
    re.IGNORECASE,
)
_SUMMARY = re.compile(
    r"\bthere (?:was|were|is|are) no [\w-]+ing\b|\bthe (?:truth|fact) (?:was|is)\b",
    re.IGNORECASE,
)
_WORD = re.compile(r"[a-z']+")


@dataclass(frozen=True)
class Tell:
    """One place the prose tells instead of shows."""

    kind: str   # "interiority" | "state" | "summary"
    text: str


def tells(text: str) -> list[Tell]:
    """Every place ``text`` tells instead of shows (empty == it shows)."""
    out: list[Tell] = []
    for word in _WORD.findall(text.lower()):
        if word in _INTERIORITY:
            out.append(Tell("interiority", word))
    for match in _STATE.finditer(text):
        out.append(Tell("state", match.group(0).strip()))
    summary = _SUMMARY.search(text)
    if summary:
        out.append(Tell("summary", summary.group(0)))
    return out


def is_telling(text: str) -> bool:
    return bool(tells(text))


def show_score(text: str) -> float:
    """1.0 = it shows; each tell costs ~a third."""
    if not text.strip():
        return 1.0
    return round(max(0.0, 1.0 - 0.34 * len(tells(text))), 2)


def _page_text(node: "Metaphor") -> str:
    parts = [node.manifestation, node.attributes.get("dialogue", "")]
    return " ".join(p for p in parts if p)


def _page_nodes(story: "Story") -> Iterator[tuple["Metaphor", str]]:
    for node in story.walk():
        text = _page_text(node)
        if text.strip():
            yield node, text


@dataclass
class ShowReport:
    total: int
    telling: int
    offenders: list[tuple[str, list[Tell]]]

    @property
    def fraction(self) -> float:
        return self.telling / self.total if self.total else 0.0

    def summary(self) -> str:
        return f"{self.telling}/{self.total} page beats still telling ({self.fraction:.0%})"


def report(story: "Story") -> ShowReport:
    total = telling = 0
    offenders: list[tuple[str, list[Tell]]] = []
    for node, text in _page_nodes(story):
        found = tells(text)
        total += 1
        if found:
            telling += 1
            offenders.append((node.id, found))
    return ShowReport(total, telling, offenders)


def _accept(old: str, new: str) -> bool:
    return bool(new) and (not tells(new) or len(tells(new)) < len(tells(old)))


def _dramatize(client: "LLMClient", line: str) -> str:
    from brehon.generate import _extract_json  # lazy: avoid an import cycle

    prompt = (
        "Rewrite this line so it SHOWS instead of tells — replace any claim about a "
        "character (he was brave, she felt jealous, he knew it was a lie) with a "
        "concrete action, image, or behaviour the reader concludes it from. No "
        "interiority verbs (knew, felt, realized), no 'was/seemed + trait'. Keep the "
        "same beat.\n\n"
        f"LINE: {line}\n\n"
        'Return JSON: {"line": "<your shown rewrite>"}'
    )
    try:
        reply = client.complete(prompt, system="You convert telling into showing. Output only JSON.")
        data = _extract_json(reply)
    except Exception:
        return ""
    return str(data.get("line", "")).strip()


def show(
    story: "Story",
    client: "LLMClient",
    *,
    max_rounds: int = 2,
    warnings: Optional[list[str]] = None,
) -> ShowReport:
    """Rewrite telling into showing, in place, until under budget."""
    warn = warnings if warnings is not None else []
    rep = report(story)
    for _ in range(max_rounds):
        if rep.telling == 0:
            break
        for node_id, _found in rep.offenders:
            node = story.get(node_id)
            if is_telling(node.manifestation):
                new = _dramatize(client, node.manifestation)
                if _accept(node.manifestation, new):
                    node.manifestation = new
                else:
                    warn.append(f"could not show beat {node_id!r}")
        rep = report(story)
    return rep
