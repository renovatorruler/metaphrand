"""The data structure as a managed prompt.

The brehon graph is a **seed**, not a generator: it holds the deep craft an LLM
won't choose well on its own — the transformation, the mirror, the two doorways,
the meaning each beat must embody, the cast — in a structure we can edit
deterministically. :func:`to_prompt` renders that seed into the instruction we
hand the model. The model grows one coherent story from it and owns what it is
good at (continuity, the physical world, the texture of a scene). :func:`lint_prose`
then checks the result on the few rules the model reliably breaks and the code can
cleanly verify — flowery language and telling-instead-of-showing.

The point is control, not generation. An LLM will gladly write any premise; the
seed is what keeps the result from coming out like every other machine-written
story.
"""

from __future__ import annotations

from typing import TYPE_CHECKING, Optional

if TYPE_CHECKING:
    from brehon.generate import LLMClient
    from brehon.story import Story

_RULES = (
    "- Every beat is a bare PHYSICAL FACT that EMBODIES its meaning — put it on the "
    "page, never name the meaning. No flowery language, no similes, no "
    '"he felt / knew / was brave / was jealous".',
    "- Hold the world: one place and one time per scene, each person in one place at "
    "a time, cause before effect. Keeping it coherent is your job.",
    "- Keep the structure and the order: the previous state, then the mirror scene, "
    "then the next state. The two doorways are points of no return.",
    "- Plain, common names — no invented-literary words.",
    "- TELL IT IN PICTURES. Carry every turn in what people DO, not what they say. A "
    "stranger who speaks no English must be able to follow the spine with the sound "
    "off: each beat has to put a physical action or image on screen, and the opening "
    "image, the mirror, and the finale must land for the eye. Dialogue is seasoning "
    "— never run more than two talking scenes back to back without an active one, "
    "and as the hero is broken open let the film grow quieter and more visual.",
    "- GROW FLESH, don't shrink-wrap. The fixed beats are the bones, not the whole "
    "animal. Build the body around them: at least one subplot with its own arc the "
    "hero does not drive; a want of their own for every named character, pursued off "
    "the hero's line; the larger situation the premise only implies; and detail that "
    "doesn't pay off. A story that is only the fixed beats expanded has failed.",
)


def _beat_lines(story: "Story", parent_id: str, out: list[str]) -> None:
    for i, beat in enumerate(story.children(parent_id), 1):
        door = beat.attributes.get("doorway")
        tag = f"   << DOORWAY {door}: no turning back after this" if door else ""
        out.append(f"  {i}. embody: {beat.meaning}{tag}")
        if beat.attributes.get("character") and beat.attributes.get("dialogue"):
            out.append(f"     ({beat.attributes['character']} speaks here)")


def to_prompt(story: "Story", *, form: str = "screenplay") -> str:
    """Render the seed into the controlling prompt for the LLM."""
    if story.root_id is None:
        return ""
    root = story.get(story.root_id)
    out: list[str] = [
        f"Write one complete, continuous {form}. You hold the whole world in your "
        "head and keep it coherent — that part is yours. The STRUCTURE below is "
        "FIXED: realize each beat, and do not drop, reorder, or change what one "
        "means. Everything ELSE — the flesh around those bones — you must invent "
        "generously (see THE FLESH).",
        "",
        f"TRANSFORMATION (the whole point): {root.meaning}",
    ]
    if root.manifestation:
        out.append(f"THE MIRROR (the hinge scene — both worlds held at once): {root.manifestation}")

    if root.kind == "mirror":
        states = [m for m in story.children(root.id) if m.kind == "state"]
        states.sort(key=lambda s: 0 if s.attributes.get("role") == "previous" else 1)
        for state in states:
            label = (state.attributes.get("role") or "state").upper()
            out += ["", f"{label} STATE — {state.meaning}:"]
            _beat_lines(story, state.id, out)
    else:
        acts = [m for m in story.children(root.id) if m.kind == "act"]
        for index, act in enumerate(acts, 1):
            out += ["", f"ACT {index} — {act.meaning}:"]
            _beat_lines(story, act.id, out)

    cast = [m for m in story.walk() if m.kind == "character"]
    if cast:
        out += ["", "CAST (each a real person with a want of their own):"]
        for c in cast:
            out.append(f"  - {c.meaning} — {c.attributes.get('archetype', '')}; "
                       f"wants {c.attributes.get('want', '')}")

    from brehon.dossier import reference_block  # the backstory you know, not say
    bible = reference_block(story)
    if bible:
        out += ["", bible]

    out += [
        "",
        "THE FLESH (yours to invent — the fixed beats above are the load-bearing "
        "bones, not the whole animal):",
        "  - Build at least one SUBPLOT with its own beginning, middle, and end that "
        "the protagonist does not drive, and may not even be in.",
        "  - Give every named character a want of their own, pursued whether or not "
        "it serves the hero, that goes on when he leaves the room.",
        "  - Invent the larger situation the premise only hints at: who else is "
        "affected, what forces are moving, the daily life of the place.",
        "  - Allow contingency — specifics and small events that do NOT pay off; a "
        "real world is not a machine where every part is load-bearing.",
    ]
    out += ["", "RULES (non-negotiable; checked on your output):", *_RULES, "",
            f"Write the {form} now, scene by scene, in order."]
    return "\n".join(out)


# Blake Snyder's "Save the Cat!" 15 beats, with page targets on a 110-page script.
BEAT_SHEET = (
    ("Opening Image", "1"), ("Theme Stated", "6"), ("Set-Up", "1-10"),
    ("Catalyst", "13"), ("Debate", "13-25"), ("Break into Two", "28"),
    ("B Story", "33"), ("Fun and Games", "33-55"), ("Midpoint", "55"),
    ("Bad Guys Close In", "61-75"), ("All Is Lost", "83"),
    ("Dark Night of the Soul", "83-85"), ("Break into Three", "94"),
    ("Finale", "94-109"), ("Final Image", "110"),
)


def to_beat_sheet(story: "Story", *, title: Optional[str] = None) -> str:
    """Render the seed as a Save-the-Cat BEAT SHEET — the story's STRUCTURE.

    The fifteen functional beats, each at its page target, with a one-line note on
    how this story hits it. This is the skeleton an LLM hangs scenes on — not the
    scenes. The mirror auto-fills the Midpoint; the two doorways fill Break into
    Two and All Is Lost; other beats are placed by a ``function`` attribute.
    Beats the seed doesn't fill show as "—" — the structural gaps still to close.
    """
    if story.root_id is None:
        return ""
    root = story.get(story.root_id)
    slots: dict[str, list[str]] = {name: [] for name, _ in BEAT_SHEET}
    names = {name.lower(): name for name, _ in BEAT_SHEET}

    def put(name: str, line: str) -> None:
        line = line.strip()
        if line and name in slots:
            slots[name].append(line)

    if root.kind == "mirror":
        put("Midpoint", root.manifestation or root.meaning)
    for node in story.walk():
        if node.kind != "beat":
            continue
        line = node.meaning or node.manifestation
        function = str(node.attributes.get("function", "")).strip().lower()
        if function in names:
            put(names[function], line)
        door = str(node.attributes.get("doorway", ""))
        if door == "1":
            put("Break into Two", line)
        elif door == "2":
            put("All Is Lost", line)

    heading = (title or root.attributes.get("title") or "Untitled").upper()
    out = [f"{heading} — BEAT SHEET (Save the Cat!)", "", f"LOGLINE: {root.meaning}", ""]
    for name, page in BEAT_SHEET:
        out.append(f"{name} (p.{page}): {' / '.join(slots[name]) or '—'}")

    cast = [m for m in story.walk() if m.kind == "character"]
    if cast:
        out += ["", "CAST: " + ", ".join(
            f"{c.meaning} ({c.attributes.get('archetype', '')})" for c in cast)]
    out += ["", "TO THE WRITER: this is the structure, not the prose. Expand each beat "
            "into scenes around its page mark; keep the beats and what they mean; you "
            "own the continuity and the words."]
    return "\n".join(out)


def write_story(
    story: "Story", client: "LLMClient", *, form: str = "screenplay",
    system: Optional[str] = None,
) -> str:
    """Hand the model the managed prompt and let it grow the story."""
    system = system or (
        "You are a master screenwriter. Follow the fixed structure and the rules "
        "exactly; the rest of the craft — the continuity, the world, the words — is yours."
    )
    return client.complete(to_prompt(story, form=form), system=system)


def lint_prose(text: str) -> list[tuple[str, str, list[str]]]:
    """Check generated prose on the rules the code owns: flowery, and telling.

    Returns ``(kind, line, offending tokens)`` for each violation. These are the
    rules where the LLM reliably slips *and* the code can verify cleanly; the
    world and continuity are deliberately not checked here — those are the model's.
    """
    from brehon import concreteness, showing

    issues: list[tuple[str, str, list[str]]] = []
    for line in (ln.strip() for ln in text.splitlines() if ln.strip()):
        flowery = concreteness.findings(line)
        if flowery:
            issues.append(("flowery", line, [f.text for f in flowery]))
        telling = showing.tells(line)
        if telling:
            issues.append(("telling", line, [t.text for t in telling]))
    return issues
