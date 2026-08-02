# studio

`studio/` is Metaphrand's active ReScript story and audiovisual production engine.
It uses types for structure, deterministic checks for the mechanical floor, and
small, explicitly budgeted model calls for work that requires judgment.

## Active scene path

1. `Seed.res` describes a scene without containing finished prose.
2. `Session.res` prepares a provider-bound job for the host's native worker and
   consumes its response one turn at a time.
3. `Write.writeScene` generates and mechanically gates the scene.
4. `Write.emit` writes the scene and a receipt with seed and scene hashes.
5. `Write.liftDialogue` first verifies its source receipt, then runs the required
   dialogue-doctrine pass and records the parent scene hash.
6. `Write.verify` accepts only an untampered, gated, dialogue-lifted scene.
7. Cinema and project-specific production modules call `Write.read`, which verifies
   before returning lines for voices or rendering.

`Write.extendScene` follows the same rule: it accepts only a verified, lifted scene,
preserves the existing lines, adds a beat, and returns the scene to `PENDING` until
the dialogue lift runs again.

## Other engine areas

- `Cinema_Backends` is the external boundary for files, processes, Replicate,
  fal.ai, ElevenLabs, and ffmpeg.
- `Cinema_Audio`, `Cinema_Frames`, and `Cinema_Assemble` are reusable production
  building blocks.
- `Kuku_*` modules implement the current preschool-episode pipeline: parsing,
  generation, EDL checking, preflight, assembly, verification, and upload.
- `Trope*`, `EntropyDeck`, and SQLite maintain a local trope corpus and steer new
  stories away from repeated model habits.
- `Gate` / `Pipeline` / `Process` / `Runner` are the earlier generic pipeline.
  They remain useful as typed examples and for `npm run flow`, but new scene work
  should use `Seed` / `Write`.

## Type and safety rules

- Distinct concepts use distinct types.
- Impossible states should be represented with variants instead of loose optional
  fields.
- `Obj.magic`, `%raw`, and `%identity` are banned.
- Native worker turns require an explicit host provider, unique job directory,
  and positive `STUDIO_WORKER_BUDGET`; there is no default provider.
- A budget alone cannot start a model process. The legacy Claude CLI adapter is
  disabled unless explicitly allowed for that task.
- Fake or explicitly opted-in process timeouts cannot answer a later request.
- Production prose must carry a valid receipt.

See `NATIVE_WORKERS.md` for the native Codex and Claude handoff procedure.

## Commands

```bash
npm ci
npm test
npm run build
npm run flow
npm run smoke
npm run audit:workspace
```

All normal tests are zero-cost. They use the explicit fake-worker mode, temporary
scene files, and no external network calls. They also prove that a native job can
be resumed from its response file and that Session cannot select a provider
implicitly.

The tracked-language check is currently a migration ratchet: 66 known Python
invocations in 41 legacy production files are recorded exactly. A new invocation
fails the build; completing a port requires lowering the baseline. The strict
workspace audit continues to report ignored and untracked Python until migration
reaches zero.
