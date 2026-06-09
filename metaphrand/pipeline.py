"""The pipeline — run a story through the spec's gates, stage by stage.

This is the spec (``docs/02-STORY_SPEC.md``) made operational: a story is checked against
each layer's gate in order, and the result says where it passes and where it
fails. The gates are the system; the LLM only fills the slots inside each stage.

``check`` is deterministic except for the optional embodiment stage (which needs
a model). Pass the ``world`` and ``weave`` when you have them; omit them and those
stages are simply skipped.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import TYPE_CHECKING, Optional

from metaphrand import arrangement as _arrangement, canon as _canon, cinema as _cinema
from metaphrand import concreteness, density as _density, doorways as _doorways, drama as _drama
from metaphrand import dossier as _dossier, embodiment, kishotenketsu as _kishotenketsu, showing
from metaphrand import generate as _generate
from metaphrand import weave as _weave
from metaphrand import world as _world
from metaphrand.render import FountainRenderer

if TYPE_CHECKING:
    from metaphrand.generate import LLMClient
    from metaphrand.story import Story
    from metaphrand.weave import Weave
    from metaphrand.world import World


@dataclass
class StageReport:
    name: str
    passed: bool
    detail: str

    def line(self) -> str:
        mark = "PASS" if self.passed else "FAIL"
        return f"[{mark}] {self.name:<13} {self.detail}"


@dataclass
class PipelineResult:
    stages: list[StageReport] = field(default_factory=list)

    @property
    def passed(self) -> bool:
        return all(s.passed for s in self.stages)

    def failures(self) -> list[StageReport]:
        return [s for s in self.stages if not s.passed]

    def summary(self) -> str:
        return "\n".join(s.line() for s in self.stages)


def check(
    story: "Story",
    *,
    world: Optional["World"] = None,
    weave: Optional["Weave"] = None,
    client: Optional["LLMClient"] = None,
    script: Optional[str] = None,
) -> PipelineResult:
    """Run the story through every gate the spec defines, in order."""
    stages: list[StageReport] = []

    # 1 — Spine
    root = story.get(story.root_id) if story.root_id else None
    stages.append(StageReport(
        "spine", root is not None and root.kind in ("mirror", "three-act", "kishotenketsu"),
        f"root = {root.kind if root else 'none'}"))
    ktk = _kishotenketsu.shape(story)
    if ktk.count:  # gate kishōtenketsu only when the story actually uses it
        stages.append(StageReport("kishotenketsu", ktk.passed, ktk.summary()))
        if any(n.attributes.get("descent") for n in _kishotenketsu.structures(story)):
            desc = _kishotenketsu.descent(story)  # opt-in descent rules
            stages.append(StageReport("descent", desc.passed, desc.summary()))
    # doorways are a three-act/mirror device; skip them for a pure kishōtenketsu spine
    if root is not None and (root.kind in ("three-act", "mirror")
                             or any(n.attributes.get("doorway") for n in story.walk())):
        door = _doorways.doorways(story)
        stages.append(StageReport("doorways", door.passed, door.summary()))
    arr = _arrangement.arrangement(story)
    stages.append(StageReport("arrangement", arr.passed, arr.summary()))

    # 2b — Drama: every scene is a fight, or it's a postcard (Mamet). Opt-in — gated only
    # once any scene carries a drama, so stories that haven't specified one aren't failed.
    if any(n.attributes.get("drama") for n in story.walk()):
        dram = _drama.drama(story)
        stages.append(StageReport("drama", dram.passed, dram.summary()))

    # 3 — World  (skipped if no cast supplied)
    if world is not None:
        full = _world.fullness(world)
        stages.append(StageReport("world", full.passed, full.summary()))

    # 4 — Weave  (skipped if no weave supplied)
    if weave is not None:
        braid = _weave.is_monorail(weave)
        stages.append(StageReport("weave", braid.passed, braid.summary()))

    # 5 — Metaphor: concrete + embodied
    flow = concreteness.report(story)
    stages.append(StageReport("concreteness", flow.flowery == 0, flow.summary()))
    if client is not None:
        legible = embodiment.legibility(story, client)
        stages.append(StageReport("embodiment", legible.passed, legible.summary()))
    if client is not None and _canon.facts(story):
        cons = _canon.consistency(story, client)
        stages.append(StageReport("consistency", cons.passed, cons.summary()))

    # 6 — Render: show, don't tell
    told = showing.report(story)
    stages.append(StageReport("show-not-tell", told.telling == 0, told.summary()))

    # 7 — Cinema: tell it in pictures (the sound-off test)
    mod = _cinema.modality(story)
    stages.append(StageReport("visual", mod.passed, mod.summary()))
    if client is not None:
        silent = _cinema.silent_legibility(story, client)
        stages.append(StageReport("silent-spine", silent.passed, silent.summary()))

    # 8 — Density: flesh on the bones (anti-shrink-wrap)
    dens = _density.density(story, world=world)
    stages.append(StageReport("density", dens.passed, dens.summary()))

    # 9 — Backstory: the iceberg stays under (only when a script is supplied)
    if script is not None:
        spill = _dossier.leak(script, story)
        stages.append(StageReport("backstory", spill.passed, spill.summary()))

    return PipelineResult(stages)


@dataclass
class StoryResult:
    """Everything the end-to-end run produces, and how it scored."""

    story: "Story"
    world: "World"
    weave: "Weave"
    screenplay: str
    report: PipelineResult
    warnings: list[str] = field(default_factory=list)


def generate(
    premise: str,
    client: "LLMClient",
    *,
    concretize: bool = True,
    show: bool = True,
    bible: bool = False,
) -> StoryResult:
    """Run a premise through the whole spec, stage by stage, gated at each step.

    Spine (mirror + doorways) -> World (archetypal cast, repaired to clear the
    Fullness gate) -> Weave (A/B threads) -> Metaphor (concretize the flowery) ->
    Render (show what was told). Returns the artifacts plus a final
    :class:`PipelineResult` — a story that has been driven, and measured, against
    every gate. The LLM is the worker inside each stage; the gates are the system.
    """
    warnings: list[str] = []

    # Spine — the LLM proposes a mirror-rooted, doorway-marked DAG.
    story = _generate.generate_spine(premise, client, warnings=warnings)

    # World — populate the archetypal ensemble, repaired until it is a world.
    world = _world.populate(premise, client, warnings=warnings)
    world.attach(story)

    # Bible — build each character's backstory; most of it stays submerged, fed to
    # the prompt as "what you know, and must not say," and checked by the leak gate.
    if bible:
        _dossier.attach(story, _dossier.write_bible(story, premise, client, warnings=warnings))

    # Weave — braid an A-story with B-stories that refract it.
    hero = world.hero()
    beat_ids = [m.id for m in story.walk() if m.kind == "beat"]
    spine = _weave.Thread("a", "A", premise, "spine",
                          [hero.id] if hero else [], beat_ids)
    weave = _weave.braid(premise, spine, [c.id for c in world.characters],
                         client, warnings=warnings)

    # Metaphor — drive the flowery to bare physical fact.
    if concretize:
        concreteness.concretize(story, client, warnings=warnings)

    # Render — convert any remaining telling to showing, then to a screenplay.
    if show:
        showing.show(story, client, warnings=warnings)
    screenplay = FountainRenderer().render(story)

    report = check(story, world=world, weave=weave, client=client, script=screenplay)
    return StoryResult(story, world, weave, screenplay, report, warnings)
