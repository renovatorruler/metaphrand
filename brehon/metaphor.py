"""The atomic unit of a story: the Metaphor."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any


@dataclass
class Metaphor:
    """A single metaphor — one assertion that exists in the story world.

    A metaphor is *not* a comparison. "Her skin was cold" is a metaphor in
    itself: its ``manifestation`` (what appears on the page) embodies a
    ``meaning`` (what it is about). A concrete metaphor is an *instantiation*
    of a more abstract one, and its ``meaning`` concretizes the parent's.

    Edges (parents/children) are not stored on the node — they live on the
    :class:`~brehon.story.Story` so a single metaphor can be shared by
    multiple parents (the graph is a DAG, not a tree).

    Attributes:
        id: Stable identifier. The authoritative handle in the stored graph;
            determinism rides on these being reproducible across runs.
        meaning: The abstract idea this metaphor embodies (its *tenor*).
            Present at every level — even the root three-act structure has a
            meaning: the story's controlling premise.
        manifestation: The concrete thing that appears in the story (its
            *vehicle*) — a line, an action, an image. Typically empty for
            abstract/internal metaphors and filled in at the leaves.
        kind: Free-form role tag (e.g. "three-act", "act", "beat", "image",
            "line"). Purely advisory — *everything* is still a metaphor.
        attributes: Arbitrary structured data (characters referenced, props,
            timing, generation seeds, …).
    """

    id: str
    meaning: str
    manifestation: str = ""
    kind: str = "metaphor"
    attributes: dict[str, Any] = field(default_factory=dict)

    def is_concretized(self) -> bool:
        """True once this metaphor has reached the page (has a manifestation)."""
        return bool(self.manifestation)

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "meaning": self.meaning,
            "manifestation": self.manifestation,
            "kind": self.kind,
            "attributes": self.attributes,
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "Metaphor":
        return cls(
            id=data["id"],
            meaning=data["meaning"],
            manifestation=data.get("manifestation", ""),
            kind=data.get("kind", "metaphor"),
            attributes=dict(data.get("attributes", {})),
        )
