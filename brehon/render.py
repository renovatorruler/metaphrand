"""The rendering seam — where the metaphor graph becomes words.

This is the deliberately *non-deterministic* layer, and its real form is an
open decision (LLM-rendered vs. template/algorithmic). For now we define the
contract and ship one trivial, fully-deterministic renderer that prints the
graph as an indented outline — useful for inspecting structure, and a stand-in
until the surface layer is chosen.
"""

from __future__ import annotations

from typing import Protocol

from brehon.story import Story


class Renderer(Protocol):
    """Turns a stored metaphor graph into text. Implementations may be fuzzy
    (LLM) or exact (templates); the graph is always the source of truth."""

    def render(self, story: Story) -> str: ...


class OutlineRenderer:
    """Deterministic debug view: the graph as an indented outline.

    Shared metaphors (reached by multiple parents) are shown in full on first
    visit and as a back-reference thereafter, so the DAG stays legible.
    """

    def render(self, story: Story) -> str:
        if story.root_id is None:
            return ""
        lines: list[str] = []
        seen: set[str] = set()
        self._render(story, story.root_id, 0, seen, lines)
        return "\n".join(lines)

    def _render(
        self,
        story: Story,
        node_id: str,
        depth: int,
        seen: set[str],
        lines: list[str],
    ) -> None:
        node = story.get(node_id)
        indent = "  " * depth
        label = node.manifestation or node.meaning
        if node_id in seen:
            lines.append(f"{indent}- [{node.kind}] {label}  (↗ shared)")
            return
        seen.add(node_id)
        lines.append(f"{indent}- [{node.kind}] {label}")
        for child in story.children(node_id):
            self._render(story, child.id, depth + 1, seen, lines)
