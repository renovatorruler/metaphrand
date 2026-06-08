"""Canon — the shared world ground-truth the whole story is grown from.

The seed (the metaphor DAG) carries structure and per-node meaning, but no *world*:
nothing fixes who a character really is, what happened before the curtain, how two
people are related. Left unsaid, each generative stage invents its own answer — run the
backstory loop and you get four different origins for the same character.

Canon closes that gap. It is a small set of **authoritative facts** attached to the
story (``CanonFact(entity, claim)``), fed into every generative stage as ground truth the
model must not contradict. Continuity stays the LLM's job — it grows the backstory *from*
the canon — and :func:`consistency` is the safety net: an LLM-judged check (in the spirit
of the embodiment gate) that flags any generated fact contradicting the ground truth.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from brehon.generate import LLMClient
    from brehon.story import Story


@dataclass(frozen=True)
class CanonFact:
    """One authoritative fact. ``entity`` is who/what it is about (a character name, a
    place, an event); ``claim`` is the fixed truth every stage must respect."""

    entity: str
    claim: str

    def to_dict(self) -> dict:
        return {"entity": self.entity, "claim": self.claim}

    @classmethod
    def from_dict(cls, data: dict) -> "CanonFact":
        return cls(str(data.get("entity", "")), str(data.get("claim", "")))


def attach(story: "Story", facts_in) -> None:
    """Store the canon (authoritative ground truth) on the story's root."""
    if story.root_id is None:
        raise ValueError("cannot attach canon to a story with no root")
    story.get(story.root_id).attributes["canon"] = [
        (f if isinstance(f, CanonFact) else CanonFact.from_dict(f)).to_dict()
        for f in facts_in
    ]


def facts(story: "Story") -> list[CanonFact]:
    """The canon attached to the story (empty if none)."""
    if story.root_id is None:
        return []
    return [CanonFact.from_dict(d)
            for d in story.get(story.root_id).attributes.get("canon", [])]


def block(story: "Story") -> str:
    """Render the canon as the 'ground truth you must respect' prompt block.

    Empty when no canon is attached. Fed into every generative stage so the model grows
    backstory and prose that *agree* with the world instead of inventing it.
    """
    these = facts(story)
    if not these:
        return ""
    lines = [
        "GROUND TRUTH about this world — authoritative and fixed. Everything you write "
        "must be consistent with it; never invent anything that contradicts it:"
    ]
    lines += [f"  - {f.entity}: {f.claim}" for f in these]
    return "\n".join(lines)


@dataclass
class ConsistencyReport:
    conflicts: list  # (entity, the canon claim violated, the contradicting generated fact)

    @property
    def passed(self) -> bool:
        return not self.conflicts

    def summary(self) -> str:
        if self.passed:
            return "consistency: backstory agrees with canon"
        e, canon_claim, fact = self.conflicts[0]
        more = f" (+{len(self.conflicts) - 1} more)" if len(self.conflicts) > 1 else ""
        return f"{len(self.conflicts)} canon conflict(s): {e} — \"{fact[:44]}…\"{more}"


def consistency(story: "Story", client: "LLMClient") -> ConsistencyReport:
    """LLM-judged gate: flag generated backstory facts that contradict the canon.

    Continuity is enforced upstream (generation is conditioned on the canon block); this
    is the safety check — the model is shown its own facts and the ground truth and asked
    which ones conflict, the way the embodiment gate works. No canon -> nothing to check.
    """
    from brehon.generate import _extract_json  # lazy: avoid an import cycle

    these = facts(story)
    if not these:
        return ConsistencyReport([])
    canon_text = "\n".join(f"- {f.entity}: {f.claim}" for f in these)
    conflicts: list = []
    for node in story.walk():
        if node.kind != "character":
            continue
        backstory = node.attributes.get("backstory") or []
        if not backstory:
            continue
        gen_text = "\n".join(f"- {fact.get('text', '')}" for fact in backstory)
        prompt = (
            f"GROUND TRUTH (authoritative):\n{canon_text}\n\n"
            f"GENERATED FACTS about {node.meaning}:\n{gen_text}\n\n"
            "List ONLY the generated facts that directly CONTRADICT the ground truth. A "
            "fact that merely adds new detail is fine — flag only real contradictions.\n"
            'Return JSON: {"contradictions": [{"fact": "<generated fact>", '
            '"canon": "<the ground-truth line it violates>"}]}'
        )
        try:
            data = _extract_json(client.complete(
                prompt, system="You check factual consistency. Output only JSON."))
            for c in data.get("contradictions", []):
                fact = str(c.get("fact", "")).strip()
                if fact:
                    conflicts.append((node.meaning, str(c.get("canon", "")).strip(), fact))
        except Exception as exc:
            # Fail closed: a transport/parse error means this node's backstory was
            # never actually verified, so record it as an (unverified) conflict
            # rather than letting an unchecked character silently pass the gate.
            conflicts.append(
                (node.meaning, "", f"[consistency unverified: {type(exc).__name__}]")
            )
    return ConsistencyReport(conflicts)
