"""The World layer — the archetypal ensemble and the Fullness gate.

A story is a populated world, not the protagonist's spine. This module builds
the cast from Hero's-Journey *functions* (mentor, ally, herald, shapeshifter…),
each a person with their own want, and gates against the recurring failure mode:
a thin, all-functional, all-male corridor instead of a world.

The **Fullness gate** is deterministic — it stands without any model, and it is
what decides whether a cast is a world. The :func:`populate` pass uses an LLM to
fill the archetype slots, but the gate is the authority.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from typing import TYPE_CHECKING, Any, Optional

if TYPE_CHECKING:
    from brehon.generate import LLMClient
    from brehon.story import Story

# Hero's-Journey archetypal functions. The cast is built from these, not invented.
HERO = "hero"
MENTOR = "mentor"
ALLY = "ally"
HERALD = "herald"
SHAPESHIFTER = "shapeshifter"        # often the love interest
GUARDIAN = "threshold-guardian"
SHADOW = "shadow"
TRICKSTER = "trickster"

ARCHETYPES = (HERO, MENTOR, ALLY, HERALD, SHAPESHIFTER, GUARDIAN, SHADOW, TRICKSTER)

_MIN_CAST = 4  # a hero plus at least three others; fewer is a corridor


@dataclass
class Character:
    """A person in the world: an archetypal function with a want of their own."""

    id: str
    name: str
    archetype: str = ALLY
    want: str = ""        # their own want/thread; empty == a prop, not a person
    gender: str = "?"     # "f" | "m" | "x" | "?"
    thread: str = ""      # one line on their arc through the story

    def is_prop(self) -> bool:
        """A character with no want of their own is a prop, not a person."""
        return not self.want.strip()

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": self.id, "name": self.name, "archetype": self.archetype,
            "want": self.want, "gender": self.gender, "thread": self.thread,
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "Character":
        return cls(
            id=str(data["id"]), name=str(data.get("name", data["id"])),
            archetype=str(data.get("archetype", ALLY)),
            want=str(data.get("want", "")), gender=str(data.get("gender", "?")),
            thread=str(data.get("thread", "")),
        )


@dataclass
class FullnessReport:
    """Whether a cast is a world or a corridor."""

    total: int
    women: int
    men: int
    props: int
    reasons: list[str]

    @property
    def passed(self) -> bool:
        return not self.reasons

    def summary(self) -> str:
        verdict = "world" if self.passed else "corridor"
        return (
            f"{self.total} characters ({self.women}f/{self.men}m), "
            f"{self.props} props — {verdict}"
            + ("" if self.passed else ": " + "; ".join(self.reasons))
        )


def fullness(world: "World") -> FullnessReport:
    """Deterministic gate: is this a populated world, or a thin male corridor?"""
    chars = list(world.characters)
    non_hero = [c for c in chars if c.archetype != HERO]
    women = [c for c in chars if c.gender == "f"]
    men = [c for c in chars if c.gender == "m"]
    props = [c for c in non_hero if c.is_prop()]

    reasons: list[str] = []
    if len(chars) < _MIN_CAST:
        reasons.append("cast too small — a corridor, not a world")
    if not women:
        reasons.append("no women in the cast")
    if props:
        reasons.append(f"{len(props)} character(s) with no want of their own (props)")
    return FullnessReport(len(chars), len(women), len(men), len(props), reasons)


@dataclass
class World:
    """The ensemble — characters keyed by archetypal function."""

    characters: list[Character] = field(default_factory=list)

    def add(self, character: Character) -> Character:
        self.characters.append(character)
        return character

    def hero(self) -> Optional[Character]:
        return next((c for c in self.characters if c.archetype == HERO), None)

    def by_archetype(self, archetype: str) -> list[Character]:
        return [c for c in self.characters if c.archetype == archetype]

    def to_dict(self) -> dict[str, Any]:
        return {"characters": [c.to_dict() for c in self.characters]}

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "World":
        return cls([Character.from_dict(c) for c in data.get("characters", [])])

    def attach(self, story: "Story", *, parent_id: Optional[str] = None) -> None:
        """Seat the cast in a Story as ``kind="character"`` nodes (ignored by the
        spine renderers, but carried in the canonical graph)."""
        anchor = parent_id or story.root_id
        for c in self.characters:
            node = story.instantiate(
                anchor, c.name, kind="character", id=f"char-{c.id}",
                attributes={"archetype": c.archetype, "want": c.want,
                            "gender": c.gender, "thread": c.thread},
            )
            _ = node


# -- the LLM pass: populate the archetype slots, gated by fullness ----------

_SYSTEM = """\
You populate the WORLD of a story — the cast — using Joseph Campbell's
Hero's-Journey archetypes. The cast is built from FUNCTIONS, not invented at
random: hero, mentor, ally, herald, shapeshifter (often the love interest),
threshold-guardian, shadow, trickster.

Rules:
- Every character is a PERSON with their own want — never a prop that exists only
  to feed the hero one line.
- A real world has women in it (mother, partner, sister, rival…). Build them in
  as people with their own wants, not as decoration.
- Give 5-8 characters. Each gets: name, archetype (from the list), gender
  (f/m/x), want (their own), thread (one line on their arc).

Return ONE JSON object: {"characters": [{name, archetype, gender, want, thread}]}.\
"""


def _propose(premise: str, client: "LLMClient", hero_name: Optional[str]) -> "World":
    from brehon.generate import _extract_json  # lazy: avoid an import cycle

    prompt = (
        f"Premise: {premise}\n\n"
        + (f"The hero is {hero_name}.\n\n" if hero_name else "")
        + "Build the cast. Return the JSON object."
    )
    try:
        reply = client.complete(prompt, system=_SYSTEM)
        data = _extract_json(reply)
    except Exception:
        return World()
    world = World()
    for i, c in enumerate(data.get("characters", [])):
        if not str(c.get("name", "")).strip():
            continue
        cid = str(c.get("id") or c.get("name", f"c{i}")).lower().replace(" ", "-")
        world.add(Character.from_dict({**c, "id": cid}))
    return world


def _repair(premise: str, world: "World", report: FullnessReport,
            client: "LLMClient") -> "World":
    from brehon.generate import _extract_json

    have = ", ".join(f"{c.name} ({c.archetype}, {c.gender})" for c in world.characters)
    prompt = (
        f"Premise: {premise}\n\nCurrent cast: {have or '(none)'}\n\n"
        f"Problems: {'; '.join(report.reasons)}\n\n"
        "Add the MISSING characters (especially women with their own wants) so this "
        "is a real world. Return the JSON object with the FULL cast (old + new)."
    )
    try:
        reply = client.complete(prompt, system=_SYSTEM)
        data = _extract_json(reply)
    except Exception:
        return world
    fixed = World()
    for i, c in enumerate(data.get("characters", [])):
        if not str(c.get("name", "")).strip():
            continue
        cid = str(c.get("id") or c.get("name", f"c{i}")).lower().replace(" ", "-")
        fixed.add(Character.from_dict({**c, "id": cid}))
    return fixed if fixed.characters else world


def populate(
    premise: str,
    client: "LLMClient",
    *,
    hero_name: Optional[str] = None,
    max_rounds: int = 2,
    warnings: Optional[list[str]] = None,
) -> "World":
    """Build the archetypal ensemble for ``premise``, gated by Fullness.

    The LLM proposes the cast; the deterministic gate decides if it is a world,
    and drives up to ``max_rounds`` repairs (adding the missing women / wants).
    Remaining gate failures are recorded in ``warnings``.
    """
    warn = warnings if warnings is not None else []
    world = _propose(premise, client, hero_name)
    report = fullness(world)
    rounds = 0
    while report.reasons and rounds < max_rounds:
        world = _repair(premise, world, report, client)
        report = fullness(world)
        rounds += 1
    if report.reasons:
        warn.extend(report.reasons)
    return world
