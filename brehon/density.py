"""The density layer — flesh on the bones (against the shrink-wrap fallacy).

A premise is a handful of load-bearing bones, not a whole skeleton, and a
skeleton is not an animal. The model's instinct — and a managed prompt that says
"do not add" reinforces it — is to *shrink-wrap*: stretch the thinnest possible
story over exactly the beats it was handed, so every element exists only because
the plot demanded it. A real world is the opposite: full of flesh that doesn't pay
off, people whose wants have nothing to do with the hero, events that happen
because the world has its own logic.

This layer measures that. It splits the beats into BONES (those that carry a
structural function — a Save-the-Cat beat, a doorway) and FLESH (everything else:
subplot, texture, the living world), and it names two tells of a shrink-wrapped
seed:

* too little flesh — the story is almost all load-bearing plot;
* declared-but-undramatized wants — a character given a want in the cast who never
  gets a beat of their own to pursue it.

The gate only names the lack; it does not fill it. The flesh itself is grown by
the model, mandated by the prompt (see :mod:`brehon.prompt`): the spine is fixed,
the body is invented. This is the structural counterweight to the drama-enhancer's
"cut the inessential" — that keeps the *A-spine* lean; this keeps the *world*
deep. Shrink-wrap is a tight spine with no body; spectacle is a body with no
spine; a story needs both.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING, Optional

if TYPE_CHECKING:
    from brehon.metaphor import Metaphor
    from brehon.story import Story
    from brehon.world import World


def is_bone(beat: "Metaphor") -> bool:
    """A beat that carries a structural function: a named beat or a doorway."""
    attrs = beat.attributes
    return bool(attrs.get("function") or attrs.get("doorway"))


@dataclass
class DensityReport:
    total: int
    bones: int
    undramatized_wants: list[str]   # cast given a want but never a beat
    min_flesh: float
    min_flesh_count: int

    @property
    def flesh(self) -> int:
        return self.total - self.bones

    @property
    def flesh_ratio(self) -> float:
        return self.flesh / self.total if self.total else 0.0

    @property
    def shrink_wrapped(self) -> bool:
        return self.flesh < self.min_flesh_count or self.flesh_ratio < self.min_flesh

    @property
    def passed(self) -> bool:
        # Both tells fail the gate: too little flesh, and a cast member handed a
        # want they never get a beat to pursue (set dressing for the hero's line).
        return not self.shrink_wrapped and not self.undramatized_wants

    def summary(self) -> str:
        head = f"{self.flesh}/{self.total} beats are flesh ({self.flesh_ratio:.0%})"
        notes = []
        if self.shrink_wrapped:
            notes.append("shrink-wrapped (almost all bone)")
        if self.undramatized_wants:
            notes.append("undramatized wants: " + ", ".join(self.undramatized_wants))
        if not notes:
            return head + ", world has its own life"
        return head + "; " + "; ".join(notes)


def density(
    story: "Story",
    *,
    world: Optional["World"] = None,
    min_flesh: float = 0.33,
    min_flesh_count: int = 2,
) -> DensityReport:
    """Measure flesh-to-bone on the spine and flag a shrink-wrapped seed.

    A beat is a *bone* if it carries a structural function; everything else is
    *flesh* (subplot, texture, the living world). A seed that is almost all bone
    is a skeleton, not a story. If a ``world`` is given, also report any secondary
    character handed a want they never get a beat to pursue — the surest tell that
    the cast is set dressing for the hero's line rather than a world of its own.
    """
    beats = [n for n in story.walk() if n.kind == "beat"]
    bones = sum(1 for b in beats if is_bone(b))

    undramatized: list[str] = []
    if world is not None:
        hero = world.hero()
        blob = " ".join(
            f"{b.meaning} {b.manifestation} {b.attributes.get('character', '')}"
            for b in beats
        ).lower()
        for character in world.characters:
            if hero is not None and character.id == hero.id:
                continue
            if character.want and character.name.lower() not in blob:
                undramatized.append(character.name)

    return DensityReport(len(beats), bones, undramatized, min_flesh, min_flesh_count)
