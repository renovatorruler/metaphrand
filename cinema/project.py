"""cinema.project — the per-project data structure the engine consumes.

A Project is pure DATA: title, register, cast descriptions, the voice map, and the
scene list. The engine modules act on it; a new story is a new Project with no
engine changes — which is the whole point of the split.
"""
from __future__ import annotations

from dataclasses import dataclass, field

from . import audio, characters


@dataclass
class Project:
    slug: str                                    # id -> output folder
    title: str
    register: str = "live-action"                # "live-action" | "storyboard"
    cast: dict = field(default_factory=dict)     # name -> visual description (for sheets)
    voices: dict = field(default_factory=dict)   # role -> (voice_name, voice_id)
    roles: dict = field(default_factory=dict)    # dialogue role -> cast name
    scenes: list = field(default_factory=list)   # [(scene_id, [(role, text), ...]), ...]
    root: str = "stories"
    enforce_preflight: bool = False              # True once the work is "in production": build_* hard-
    #                                              stops until the design artifacts (charts, voice cards)
    #                                              exist — see metaphrand/preflight.py

    @property
    def dir(self) -> str:
        return f"{self.root}/{self.slug}"

    @property
    def sheets_dir(self) -> str:
        return f"{self.dir}/sheets"

    @property
    def perf_dir(self) -> str:
        return f"{self.dir}/performance"

    def _preflight(self) -> None:
        """Hard-stop a production step while the per-work design artifacts are missing."""
        if self.enforce_preflight:
            from metaphrand import preflight   # lazy: the production engine shouldn't import it at load
            preflight.require(self.slug)

    # ---- engine entry points (each just hands the project's data to a module) ----
    def build_cast(self, turnarounds: bool = True) -> dict:
        self._preflight()
        return characters.build_cast(self.cast, self.sheets_dir, turnarounds=turnarounds)

    def build_audio(self) -> str:
        self._preflight()
        perf = audio.build_performance(self.title, self.voices, self.scenes,
                                       f"{self.perf_dir}/{self.slug}.performance.json")
        return audio.render(perf, f"{self.perf_dir}/{self.slug}.mp3")

    def sheet_for(self, role: str) -> str | None:
        """The turnaround a shot should condition on, given a dialogue role."""
        name = self.roles.get(role)
        return f"{self.sheets_dir}/{name}_turnaround.png" if name else None
