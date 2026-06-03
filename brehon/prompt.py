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
        "head and keep it coherent — that part is yours. What is FIXED is below: "
        "realize each element exactly, and do not add, drop, or reorder the "
        "structure, or change what a beat means.",
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

    out += ["", "RULES (non-negotiable; checked on your output):", *_RULES, "",
            f"Write the {form} now, scene by scene, in order."]
    return "\n".join(out)


def to_beat_sheet(story: "Story", *, title: Optional[str] = None) -> str:
    """Render the seed as a BEAT SHEET — the prompt you hand an LLM.

    Concrete beats in narrative order (before -> the mirror -> after), each the
    event plus the meaning it embodies and any structural marker. The program's
    job ends here: an LLM writes the screenplay *from* this and owns the
    continuity, the world, and the words; it does not invent the beats.
    """
    if story.root_id is None:
        return ""
    root = story.get(story.root_id)
    heading = (title or root.attributes.get("title") or "Untitled").upper()
    out: list[str] = [f"{heading} — a beat sheet", "",
                      f"TRANSFORMATION: {root.meaning}", ""]
    counter = [1]

    def emit(parent_id: str) -> None:
        for beat in story.children(parent_id):
            door = beat.attributes.get("doorway")
            mark = f"   [DOORWAY {door} — point of no return]" if door else ""
            speaks = ("   [has dialogue]" if beat.attributes.get("character")
                      and beat.attributes.get("dialogue") else "")
            event = beat.manifestation.strip() or f"(a beat that embodies: {beat.meaning})"
            out.append(f"{counter[0]}. {event}{mark}")
            out.append(f"      embodies — {beat.meaning}{speaks}")
            counter[0] += 1

    if root.kind == "mirror":
        states = sorted((m for m in story.children(root.id) if m.kind == "state"),
                        key=lambda s: 0 if s.attributes.get("role") == "previous" else 1)
        if states:
            out.append(f"BEFORE — {states[0].meaning}:")
            emit(states[0].id)
            out.append("")
        out.append(f"{counter[0]}. THE MIRROR (the hinge, both worlds at once): {root.manifestation}")
        out.append(f"      embodies — {root.meaning}")
        counter[0] += 1
        out.append("")
        if len(states) > 1:
            out.append(f"AFTER — {states[1].meaning}:")
            emit(states[1].id)
            out.append("")
    else:
        for index, act in enumerate((m for m in story.children(root.id) if m.kind == "act"), 1):
            out.append(f"ACT {index} — {act.meaning}:")
            emit(act.id)
            out.append("")

    cast = [m for m in story.walk() if m.kind == "character"]
    if cast:
        out.append("CAST:")
        for c in cast:
            out.append(f"  - {c.meaning} — {c.attributes.get('archetype', '')}: "
                       f"wants {c.attributes.get('want', '')}")
        out.append("")

    out.append(
        "TO THE WRITER: expand this beat sheet into a screenplay. Write each beat as "
        "a scene — action and dialogue — in this exact order, changing none of the "
        "events and none of what they mean. You own the continuity, the world, and "
        "the words. Show every beat as a bare physical fact; never name its meaning; "
        "use plain, common names.")
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
