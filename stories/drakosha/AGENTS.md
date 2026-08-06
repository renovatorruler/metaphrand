# Frosya and Vasya production instructions

For any Episode 1, Scene 1 production task, read these files completely before planning, prompting, generating, or editing assets:

1. `ep1prod/scene1/CURRENT.md`
2. `ep1prod/scene1/scene1.production.v1.json`

Those two files are the current operational authority for Scene 1. The spec script remains the story authority, but older shooting drafts, visual batches, and proposals are not production authority unless `CURRENT.md` explicitly promotes them.

Rules:

- Do not generate from chat memory alone.
- Do not silently reopen a closed decision.
- When the user changes or approves a production decision, update both current-state files in the same turn.
- Every generation must use the references declared for its shot in the manifest.
- Stop before generation when a shot has an unresolved blocking asset or contradictory state.
- Preserve rejected and superseded assets, but never treat them as current merely because they remain on disk.

