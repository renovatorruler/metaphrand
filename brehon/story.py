"""The Story: a directed acyclic graph of metaphors, rooted at the three-act
structure.

This module is the deterministic core of the project. A ``Story`` is a graph
of :class:`~brehon.metaphor.Metaphor` nodes connected by *instantiation*
edges (parent -> child, abstract -> concrete). It is:

* a **DAG** — a metaphor may be instantiated under more than one parent, so a
  single concrete beat can serve both a structural parent (the Act II
  midpoint) and a thematic one (the cost of love);
* **acyclic** — instantiation only ever flows from abstract to concrete;
  attempting to close a loop raises :class:`CycleError`;
* **deterministic** — child order is meaningful and preserved, ids are
  reproducible, and :meth:`Story.to_json` emits a canonical form so the same
  logical story always serializes to the same bytes.
"""

from __future__ import annotations

import json
import re
from typing import Any, Iterator, Optional

from brehon.metaphor import Metaphor


class CycleError(ValueError):
    """Raised when an edge would make the metaphor graph cyclic."""


def _slug(text: str) -> str:
    """Reduce arbitrary text to a stable, id-friendly slug."""
    slug = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    return slug or "metaphor"


class Story:
    """A DAG of metaphors with a single most-abstract root.

    Nodes are stored in a flat registry keyed by id; edges live in ordered
    adjacency maps. Child order is significant (it is narrative order) and is
    always preserved. Parent order is maintained for stable serialization.
    """

    def __init__(self) -> None:
        self._metaphors: dict[str, Metaphor] = {}
        self._children: dict[str, list[str]] = {}
        self._parents: dict[str, list[str]] = {}
        self.root_id: Optional[str] = None

    # -- construction ------------------------------------------------------

    def add(self, metaphor: Metaphor) -> Metaphor:
        """Register a metaphor with no edges. Ids must be unique."""
        if metaphor.id in self._metaphors:
            raise ValueError(f"duplicate metaphor id: {metaphor.id!r}")
        self._metaphors[metaphor.id] = metaphor
        self._children.setdefault(metaphor.id, [])
        self._parents.setdefault(metaphor.id, [])
        return metaphor

    def instantiate(
        self,
        parent_id: Optional[str],
        meaning: str,
        *,
        manifestation: str = "",
        kind: str = "metaphor",
        id: Optional[str] = None,
        attributes: Optional[dict[str, Any]] = None,
    ) -> Metaphor:
        """Create a new metaphor as a concretization of ``parent_id``.

        This is the core verb of the model. Pass ``parent_id=None`` to mint a
        metaphor with no parent yet (e.g. the root). If ``id`` is omitted, a
        deterministic id is derived from ``meaning`` (de-duplicated with a
        numeric suffix), so building the same story in the same order yields
        the same ids.
        """
        node_id = id or self._auto_id(meaning)
        metaphor = Metaphor(
            id=node_id,
            meaning=meaning,
            manifestation=manifestation,
            kind=kind,
            attributes=dict(attributes or {}),
        )
        self.add(metaphor)
        if parent_id is not None:
            self.link(parent_id, node_id)
        return metaphor

    def link(self, parent_id: str, child_id: str) -> None:
        """Add an instantiation edge parent -> child (abstract -> concrete).

        Adding a second (or third) parent to an existing child is how shared
        metaphors are expressed. Raises :class:`CycleError` if the edge would
        introduce a cycle.
        """
        if parent_id not in self._metaphors:
            raise KeyError(f"unknown parent id: {parent_id!r}")
        if child_id not in self._metaphors:
            raise KeyError(f"unknown child id: {child_id!r}")
        if parent_id == child_id or parent_id in self.descendants(child_id):
            raise CycleError(
                f"linking {parent_id!r} -> {child_id!r} would create a cycle"
            )
        if child_id not in self._children[parent_id]:
            self._children[parent_id].append(child_id)
            self._parents[child_id].append(parent_id)

    def set_root(self, metaphor_id: str) -> None:
        """Designate the most-abstract metaphor (the three-act structure)."""
        if metaphor_id not in self._metaphors:
            raise KeyError(f"unknown metaphor id: {metaphor_id!r}")
        self.root_id = metaphor_id

    def three_act(
        self, meaning: str, *, id: str = "three-act", **attributes: Any
    ) -> Metaphor:
        """Convenience: create the root three-act-structure metaphor.

        ``meaning`` is the story's controlling premise — the single idea the
        whole graph concretizes.
        """
        root = self.instantiate(
            None, meaning, kind="three-act", id=id, attributes=attributes
        )
        self.set_root(root.id)
        return root

    def _auto_id(self, meaning: str) -> str:
        base = _slug(meaning)
        if base not in self._metaphors:
            return base
        n = 2
        while f"{base}-{n}" in self._metaphors:
            n += 1
        return f"{base}-{n}"

    # -- access ------------------------------------------------------------

    def __contains__(self, metaphor_id: object) -> bool:
        return metaphor_id in self._metaphors

    def __len__(self) -> int:
        return len(self._metaphors)

    def get(self, metaphor_id: str) -> Metaphor:
        return self._metaphors[metaphor_id]

    def children(self, metaphor_id: str) -> list[Metaphor]:
        return [self._metaphors[c] for c in self._children[metaphor_id]]

    def parents(self, metaphor_id: str) -> list[Metaphor]:
        return [self._metaphors[p] for p in self._parents[metaphor_id]]

    def roots(self) -> list[Metaphor]:
        """All metaphors with no parent (usually just the three-act root)."""
        return [
            self._metaphors[i]
            for i in self._metaphors
            if not self._parents[i]
        ]

    def leaves(self) -> list[Metaphor]:
        """All metaphors with no children — the page-level metaphors."""
        return [
            self._metaphors[i]
            for i in self._metaphors
            if not self._children[i]
        ]

    def descendants(self, metaphor_id: str) -> set[str]:
        seen: set[str] = set()
        stack = list(self._children.get(metaphor_id, []))
        while stack:
            current = stack.pop()
            if current in seen:
                continue
            seen.add(current)
            stack.extend(self._children.get(current, []))
        return seen

    def ancestors(self, metaphor_id: str) -> set[str]:
        seen: set[str] = set()
        stack = list(self._parents.get(metaphor_id, []))
        while stack:
            current = stack.pop()
            if current in seen:
                continue
            seen.add(current)
            stack.extend(self._parents.get(current, []))
        return seen

    def walk(self, start_id: Optional[str] = None) -> Iterator[Metaphor]:
        """Deterministic pre-order traversal from a root (default: the root).

        A shared metaphor reachable by several paths is yielded once, on its
        first visit, so callers see each metaphor a single time.
        """
        origin = start_id or self.root_id
        if origin is None:
            return
        seen: set[str] = set()
        stack = [origin]
        while stack:
            current = stack.pop()
            if current in seen:
                continue
            seen.add(current)
            yield self._metaphors[current]
            # push children reversed so first child is visited first
            stack.extend(reversed(self._children[current]))

    # -- serialization (canonical / deterministic) ------------------------

    def to_dict(self) -> dict[str, Any]:
        """A canonical dict: nodes sorted by id, child order preserved."""
        return {
            "root_id": self.root_id,
            "metaphors": [
                self._metaphors[i].to_dict()
                for i in sorted(self._metaphors)
            ],
            "edges": [
                {"parent": parent, "child": child}
                for parent in sorted(self._children)
                for child in self._children[parent]
            ],
        }

    def to_json(self, *, indent: int = 2) -> str:
        return json.dumps(self.to_dict(), indent=indent, sort_keys=True)

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "Story":
        story = cls()
        for node in data.get("metaphors", []):
            story.add(Metaphor.from_dict(node))
        for edge in data.get("edges", []):
            story.link(edge["parent"], edge["child"])
        root = data.get("root_id")
        if root is not None:
            story.set_root(root)
        return story

    @classmethod
    def from_json(cls, text: str) -> "Story":
        return cls.from_dict(json.loads(text))

    def save(self, path: str) -> None:
        with open(path, "w", encoding="utf-8") as handle:
            handle.write(self.to_json())
            handle.write("\n")

    @classmethod
    def load(cls, path: str) -> "Story":
        with open(path, encoding="utf-8") as handle:
            return cls.from_json(handle.read())
