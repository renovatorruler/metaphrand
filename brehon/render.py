"""The rendering seam — where the metaphor graph becomes words.

Rendering walks the *structural spine* of a story (the root's act children, in
narrative order, and their beats) and turns it into text. The theme and motif
branches are deliberately ignored here: they exist to keep the story coherent
and to make motifs recur, but they are not themselves on the page.

Two renderers ship:

* :class:`OutlineRenderer` — a deterministic debug view of the whole DAG.
* :class:`FountainRenderer` — a real screenplay in Fountain format
  (https://fountain.io), the plain-text standard any screenwriting app reads.

Both are deterministic: output is a pure function of the stored graph. The
*fuzzy* layer (paraphrasing a beat's wording while preserving the stack) is a
future renderer that will live alongside these.
"""

from __future__ import annotations

import re
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


_ACT_NAMES = {1: "ACT ONE", 2: "ACT TWO", 3: "ACT THREE", 4: "ACT FOUR"}


class FountainRenderer:
    """Render a story's structural spine as a Fountain screenplay.

    Walks the root's ``kind == "act"`` children in order, then each act's beats
    in narrative (child) order. Each beat becomes one or more Fountain elements:

    * ``attributes["slug"]``       -> a scene heading (INT./EXT. …)
    * ``manifestation``            -> an action paragraph
    * ``attributes["character"]``  -> a dialogue block, with optional
      ``attributes["parenthetical"]`` and ``attributes["dialogue"]``

    Acts are emitted as Fountain sections (``#``), which organise the script in
    an editor without printing in the final document. Title-page fields are
    read from the root's attributes (``title``, ``credit``, ``author``,
    ``source``, ``draft_date``).
    """

    TITLE_KEYS = ("title", "credit", "author", "source", "draft_date")

    def render(self, story: Story) -> str:
        if story.root_id is None:
            return ""
        root = story.get(story.root_id)
        out: list[str] = []
        self._title_page(root, out)

        if root.kind == "mirror":
            self._render_mirror(story, root, out)
        else:
            acts = [m for m in story.children(root.id) if m.kind == "act"]
            for index, act in enumerate(acts, start=1):
                label = _ACT_NAMES.get(index, f"ACT {index}")
                out.append(f"# {label}")
                out.append("")
                for beat in story.children(act.id):
                    self._emit_beat(story.get(beat.id), out)

        return self._normalise(out)

    def _render_mirror(self, story: Story, root, out: list[str]) -> None:
        """Linearize a mirror story: previous branch -> the mirror -> next branch.

        The mirror scene (the root's own manifestation) falls at the hinge by
        construction — no one places it at the midpoint; the structure does.
        State and other purely-structural nodes carry no page text, so they emit
        nothing as the branches are walked.
        """
        states = [m for m in story.children(root.id) if m.kind == "state"]
        previous = next((s for s in states if s.attributes.get("role") == "previous"), None)
        following = next((s for s in states if s.attributes.get("role") == "next"), None)
        if previous is None and states:
            previous = states[0]
        if following is None and len(states) > 1:
            following = states[1]

        if previous is not None:
            for node in story.walk(previous.id):
                self._emit_beat(node, out)
        self._emit_beat(root, out)  # the mirror, at the hinge
        if following is not None:
            for node in story.walk(following.id):
                self._emit_beat(node, out)

    def _title_page(self, root, out: list[str]) -> None:
        if not root.attributes.get("title"):
            return
        for key in self.TITLE_KEYS:
            value = root.attributes.get(key)
            if value:
                field = key.replace("_", " ").title()
                out.append(f"{field}: {value}")
        out.append("")  # a blank line closes the title page

    def _emit_beat(self, beat, out: list[str]) -> None:
        slug = beat.attributes.get("slug")
        if slug:
            out.append(slug.upper())
            out.append("")
        if beat.manifestation:
            out.append(beat.manifestation)
            out.append("")
        character = beat.attributes.get("character")
        if character:
            out.append(character.upper())
            parenthetical = beat.attributes.get("parenthetical")
            if parenthetical:
                out.append(f"({parenthetical})")
            out.append(beat.attributes.get("dialogue", ""))
            out.append("")

    @staticmethod
    def _normalise(out: list[str]) -> str:
        text = "\n".join(out)
        text = re.sub(r"\n{3,}", "\n\n", text).strip()
        return text + "\n"
