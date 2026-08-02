# metaphrand

Metaphrand is a private, AI-assisted story and film-production studio. It turns a
story idea into structured scene seeds, gated screenplay text, voices, images,
video, music, and assembled episodes.

This repository is not a Python package. The active engine is the typed ReScript
project in `studio/`; `stories/` contains the creative source and production
records for individual worlds.

## The active production flow

```text
story bible + scene seed
        ↓
one provider-bound native worker job
        ↓
mechanical craft gate + dialogue lift
        ↓
scene text + verifiable receipt
        ↓
voice / still / video / score generation
        ↓
EDL + preflight + ffmpeg assembly
        ↓
finished deliverable / YouTube upload
```

The model writes sentences, but it does not own the structure. A `Seed.sceneSeed`
contains the cast, surface and buried layers, wants, walls, turns, and hard rules.
`Write.writeScene` turns that seed into prose, gates it, and emits a receipt. A
required dialogue pass lifts the scene before production can read it.

## Repository map

| Path | Purpose |
| --- | --- |
| `studio/src/Seed.res` | Typed scene structure; no finished prose field. |
| `studio/src/Session.res` | The provider-neutral job boundary: native handoff, sequential consumption, explicit budget. |
| `studio/src/Write.res` | Scene generation, craft gates, dialogue lift, receipts, and verification. |
| `studio/src/Cinema_*.res` | Story-agnostic audio, image, video, assembly, and upload tools. |
| `studio/src/Kuku_*.res` | Production tooling for the Hindi preschool series. |
| `studio/src/Trope*.res` | Local trope corpus, tagging, comparison reports, and story-brief gates. |
| `docs/` | The writing and story-design doctrine. |
| `stories/` | Bibles, screenplays, scene receipts, manifests, EDLs, and project-specific source. |
| `culture/` | Cultural reference notes used during story development. |

`Gate` / `Pipeline` / `Process` / `Runner` are an older generic typed pipeline that
still documents useful ideas and powers the zero-cost flow demonstration. Current
scene production uses `Seed` / `Write`.

## Build and test

```bash
cd studio
npm ci
npm test
```

`npm test` performs five zero-cost checks:

1. no ReScript escape hatches;
2. no new Python migration debt;
3. no newly tracked generated media;
4. compilation and deterministic gate tests;
5. receipt, budget, timeout, provider-isolation, native-handoff, and fake-session safety tests.

Useful commands:

```bash
npm run build             # compile ReScript
npm run flow              # idea-to-scene flow with stubs; no model calls
npm run smoke             # process-isolation test with the fake worker
npm run audit:workspace   # strict report of all remaining local Python debt
```

## Native model work

The engine does not select or launch a real model provider. A trusted Codex or
Claude host supplies its own identity, one unique job directory, and a positive
worker budget:

```bash
STUDIO_NATIVE_WORKER_PROVIDER=codex \
STUDIO_NATIVE_JOB_DIR="$(mktemp -d)" \
STUDIO_WORKER_BUDGET=4 \
node src/<Driver>.res.mjs
```

The driver emits a job and refuses until the orchestrator delegates it through a
native worker of the same provider. See `studio/NATIVE_WORKERS.md`. Never raise
the budget merely to get past a refusal. The normal test suite uses an explicit
fake worker and makes no external calls.

## Migration and generated media

New implementation code is ReScript. A known set of older Kuku shell tools still
invokes Python; `studio/scripts/python-legacy-allowlist.txt` is an exact ratchet,
not permission to add more. Each port lowers that file until it can be removed.

Generated media is ignored and should not be newly committed. Thousands of legacy
Git LFS assets remain in repository history and the current index; removing them
is a separate repository-maintenance operation because it affects other clones.
