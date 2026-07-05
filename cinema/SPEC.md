# cinema — the production engine (SPEC)

A **story-agnostic** film-production engine. The discipline: the **ENGINE** (reusable steps)
is separate from the **DATA** (one project). The test of "solid" is brutal — *a completely
different story and cast runs through the same engine with only a new project file.* If the
engine has to change to make a new story work, it isn't solid yet.

Proven 2026-06-15: the same `cinema.characters` engine produced a 1850s Texan detective **and**
a medieval warrior queen from one-line descriptions, no code change. The same `cinema.audio`
engine renders a single-narrator film **and** a nine-character episode from the same module.

---

## The split

**DATA — one file per story** (`projects/<name>.py`): a `Project` holding `title`, `register`
(live-action | storyboard), `cast` (name → look description), `voices` (role → voice), `roles`
(dialogue role → cast name), `scenes` ([(scene_id, [(role, text), …])]). Nothing else.

**ENGINE — `cinema/`** (knows no story):
| module | does |
|---|---|
| `backends` | the only place external APIs live: Replicate (image / image→video / image→3D), ElevenLabs (dialogue / music), ffmpeg audio utils, model IDs, keys, retries. |
| `characters` | description → **portrait** → multi-view **turnaround model sheet** → contact sheet. Bakes in the consistency best-practices + the **actor-likeness guard**. |
| `audio` | scenes → **performance JSON** → multi-voice dialogue (one continuous take per scene, digest-cached) → stitched mp3 + a **timing manifest** for the assembler. |
| `project` | the `Project` dataclass + its engine entry points (`build_cast`, `build_audio`, `sheet_for`). |

**Done — extracted into `cinema/`:**
| module | does |
|---|---|
| `frames` | `location_master()` + `shot(prompt, refs, register, face_lock, avoid)`; storyboard **or** photoreal, conditioned on turnarounds + set master/clay. Carries the commercial-likeness lock. |
| `assemble` | shot list + audio → cut: Ken-Burns stills, video clips (freeze-hold), cross-dissolves, scaled to land on the audio. |

**Migration still pending** — proven-but-still-in-`examples/`:
| coming to cinema | currently | becomes |
|---|---|---|
| `sets` | `examples/civilwar_set3d.py` + `examples/setplan.py` | layout-data → Blender set + cameras + clay (already data-driven via `build_*_from_layout`). |
| `score` | `examples/score.py` | cue-table → ducked beds (already table-driven: `FAMILIES`, `CHAPTER_CUES`). |
| `upload` | `examples/youtube_upload.py` | already generic — move as-is. |

---

## Adding a new project (the whole job)

1. Write `projects/<name>.py`: a `Project` with the cast looks, the voice map, and the scenes.
2. `python -m projects.<name> cast` → portraits + turnarounds under `stories/<name>/sheets/`.
3. `python -m projects.<name> audio` → multi-voice episode + timing manifest.
4. (engine, story-agnostic) build sets from the scene locations, render frames conditioned on the
   turnarounds + sets, score from the cue table, assemble against the manifest, upload.

No engine edits at any step. That is the deliverable.

---

## Pipeline flow

```
story/screenplay ──> project.py (DATA)
                         │
   ┌─────────────────────┼───────────────────────────────┐
   ▼                     ▼                                ▼
characters            audio                            sets
(turnaround sheets)  (multi-voice + manifest)         (layout → Blender → cameras → clay)
   └──────────┬──────────┴───────────────┬──────────────┘
              ▼                           ▼
            frames  ──(conditioned on sheets + set clay)──>  storyboard OR photoreal
              │
              ▼
       [video] image→video (Seedance) on the shots that earn motion
              │
              ▼
         assemble (manifest-timed, cross-dissolves, score ducked under, hook banner) ──> master ──> upload
```

## Best practices baked in (so we never relearn them)
- **Character consistency:** a turnaround model sheet (front / 3-4 / profile + full body), flat
  studio light, neutral bg, consistent wardrobe; condition every shot on the sheet; a face-swap/
  retouch pass for the last ~5% of drift.
- **Commercial likeness — the three-part lock (learned the hard way):** a tight CU invents the most
  face pixels and drifts to the nearest famous actor ("ruggedly handsome detective" → Jake
  Gyllenhaal; "handsome 50s lead" → Clooney), even when a wider shot in the same scene held fine.
  Defend with all three, not one: (1) **cascade** — condition a CU on an already-good *wider frame of
  the same character* PLUS the turnaround, never the turnaround alone; (2) **face_lock + avoid** in
  `frames.shot` — the original-likeness demand and a named negative for the known drift target;
  (3) a **likeness gate** — eyeball every lead face against the sheet AND against "does this read as
  a real actor" before it ships; regenerate on a fail. The accepted turnaround is the bar; a shot
  that leaves it is wrong even if it's pretty.
- **World/geometry consistency:** render every shot from ONE coordinate-built set; ambiguous props
  (an open shed) need defining geometry (a back wall) so the model can't flip them.
- **Clay only needs blocking:** the model fixes anatomy/seating/scale; never over-tune the clay.
- **Live-action register:** same blocking, a photoreal prompt instead of storyboard; animate
  selectively (~15-25% of shots).
- **Audio:** one continuous dialogue take per scene; a light narrator carries action.
- **Score:** sparse, ducked under voice, frequency-carved; mood/family from a cue table.
