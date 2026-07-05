"""cinema — a story-agnostic film-production engine.

The ENGINE (reusable steps) is separated from the DATA (one project's specifics):
a new story runs through the same modules with only a new project config.

    backends    — the shared API layer (Replicate image/video/3D, ElevenLabs)
    characters  — description -> portrait -> turnaround model sheet (consistency)
    audio       — scenes -> performance -> multi-voice audio drama (+ timing manifest)
    project     — the per-project data structure the engine consumes

Score, set-building, frame conditioning, video assembly, and upload are proven in
the examples/ modules and are being migrated here; see cinema/SPEC.md for the map.
"""
