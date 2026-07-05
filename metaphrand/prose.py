"""The fuzzy renderer — where the metaphor graph becomes prose, grown by the LLM.

:class:`~metaphrand.render.FountainRenderer` dumps each beat's bare manifestation: a skeleton.
This is the missing half. Given the graph (each beat's bare fact and the meaning it serves),
the canon (the world's ground truth), and the bibles (the iceberg — what you know and must
not say), the LLM expands each beat, in spine order, into concrete prose that makes the fact
land and carries its meaning without naming it. Continuity is fed forward (the story so far).

With ``repair=True`` it closes the loop: each passage is checked — the iceberg must stay
under (:func:`metaphrand.dossier.leak`) and the prose must be free of ornament
(:func:`metaphrand.concreteness.findings`) — and a failure is fed back and rewritten via
:func:`metaphrand.repair.repair`, so the renderer fixes its own drafts.

Needs a prose-mode client (e.g. ``OllamaClient(json_mode=False)``).
"""

from __future__ import annotations

from typing import TYPE_CHECKING, Optional

from metaphrand import canon as _canon
from metaphrand import concreteness as _concreteness
from metaphrand import craftlint as _craftlint
from metaphrand import dossier as _dossier
from metaphrand.cinema import spine_beats

if TYPE_CHECKING:
    from metaphrand.generate import LLMClient
    from metaphrand.metaphor import Metaphor
    from metaphrand.story import Story

_SYSTEM = (
    "You are a novelist writing close, concrete prose. Show, never tell: bare physical fact, "
    "plain verbs, no naming the feeling, no simile, no ornament. Carry the meaning in what "
    "happens, not in commentary. Output only the passage — no title, no headers, no notes."
)


def _serves(story: "Story", beat: "Metaphor") -> list[str]:
    """The themes/motifs this beat carries — its meaning context, never for the page."""
    return [p.meaning for p in story.parents(beat.id) if p.kind in ("theme", "motif")]


def check_passage(story: "Story", passage: str) -> tuple[bool, str]:
    """Gate one rendered passage: no ornament, and no submerged backstory exposited.
    Returns ``(passed, reason)`` — the reason is actionable feedback for a rewrite."""
    problems: list[str] = []
    crimes = sorted({f"{f.kind} ({f.text})" for f in _concreteness.findings(passage)})
    if crimes:
        problems.append("strip this ornament: " + ", ".join(crimes))
    tells = _craftlint.feedback(passage, mode="prose")  # clickbait cadence + two-word punch lines
    if tells:
        problems.append(tells)
    leaks = _dossier.leak(passage, story).leaks
    if leaks:
        facts = "; ".join(f'"{fact}"' for _char, fact, _line in leaks[:3])
        problems.append("you stated hidden backstory that must stay submerged: " + facts)
    return (not problems, "; ".join(problems))


class ProseRenderer:
    """Walk the spine and grow each beat into prose, conditioned on canon + iceberg.

    ``repair`` turns on the self-correcting loop; ``self.repairs`` records
    ``(beat_id, tries, passed)`` for each beat after a render.
    """

    def __init__(self, *, tail_chars: int = 700, repair: bool = False, max_tries: int = 3) -> None:
        self.tail_chars = tail_chars
        self.repair = repair
        self.max_tries = max_tries
        self.repairs: list[tuple[str, int, bool]] = []

    def render(self, story: "Story", client: "LLMClient", *,
               warnings: Optional[list[str]] = None) -> str:
        warn = warnings if warnings is not None else []
        canon_block = _canon.block(story)
        iceberg = _dossier.reference_block(story)
        self.repairs = []
        prose = ""
        for beat in spine_beats(story):
            fact = (beat.manifestation or beat.meaning or "").strip()
            if not fact:
                continue
            base = self._prompt(story, beat, fact, prose, canon_block, iceberg)

            if self.repair:
                from metaphrand.repair import repair as _repair

                def generate(feedback: str, base: str = base, fact: str = fact) -> str:
                    prompt = base if not feedback else (
                        base + "\n\nYOUR LAST DRAFT FAILED THE EDITOR: " + feedback
                        + ". Rewrite the passage fixing exactly that — stay concrete and plain, "
                        "and never state the hidden backstory.")
                    try:
                        return client.complete(prompt, system=_SYSTEM).strip()
                    except Exception:
                        return fact

                result = _repair(generate, lambda p: check_passage(story, p), max_tries=self.max_tries)
                passage = result.value
                self.repairs.append((beat.id, result.tries, result.passed))
                if not result.passed:
                    warn.append(f"beat {beat.id!r} still failed after {result.tries} tries: {result.reason}")
            else:
                try:
                    passage = client.complete(base, system=_SYSTEM).strip()
                except Exception:
                    passage = fact
                    warn.append(f"could not render beat {beat.id!r}")
                self.repairs.append((beat.id, 1, True))

            prose = (prose + "\n\n" + passage).strip() if prose else passage
        return prose

    def _prompt(self, story: "Story", beat: "Metaphor", fact: str, prose: str,
                canon_block: str, iceberg: str) -> str:
        sections: list[str] = []
        if canon_block:
            sections.append(canon_block)
        if iceberg:
            sections.append(iceberg)
        if prose:
            sections.append("THE STORY SO FAR (continue seamlessly; do not repeat it):\n"
                            + prose[-self.tail_chars:])
        serves = _serves(story, beat)
        ask: list[str] = []
        if serves:
            ask.append("This passage quietly serves (never state these): " + "; ".join(serves) + ".")
        ask.append(f"The bare fact of what happens now: {fact}")
        ask.append("Write the next passage of the novel — a short paragraph or two, vivid and "
                   "concrete, that makes this fact land and carries its meaning without naming it. "
                   "No markdown or italics, no simile, no purple verbs.")
        sections.append("\n".join(ask))
        return "\n\n".join(sections)
