# Scene 1 low-poly production flow (Kuku-style)

The Kuku pipeline shape — pinned style key, plates first, canonical character PNGs,
fixed negative block, SCENE/MOTION/AUDIO clip grammar, idempotent scripts — wired
into the drakosha authority system. The manifest (`../scene1.production.v1.json`)
is the single input; `../CURRENT.md` stays the human authority. Nothing here
invents shots: the stage scripts encode the approved 10-slot compact cut verbatim.

## Safety model

Every stage script:
- verifies the **sha256 of every declared asset** it uses against the manifest
  (byte drift = hard stop);
- checks the **approval** its stage requires in `approvals` (pending = hard stop);
- requires an explicit **`--go` flag** — running a script bare only prints what it
  would do. No accidental credit spend;
- is **idempotent only through a verified receipt**; a bare existing output is blocked;
- acquires an **exclusive per-target lease** and atomically claims each paid attempt;
- permits at most **two paid submissions per target**, persisted across process restarts;
- binds each receipt to the canonical stage, subject, model, prompt hash, style key,
  complete reference set, provider arguments, output path, and output bytes;
- clean-builds ReScript immediately before execution, so a stale generated `.mjs`
  cannot bypass reviewed source;
- retries downloading an existing result URL without submitting another paid generation.

The ReScript readiness gate (`npm run readiness:scene1:<stage>` from `studio/`)
is called inside the guarded runner immediately before every possible provider
submission. The flow does not have a standalone or weaker version of that gate.
Passing readiness is necessary but not sufficient: the runner also compares the
actual prompt/model/references/arguments/output with that target's reviewed
`generationSpec`. Storyboard and motion targets must receive such specs before
those stages can submit anything.

## Stages

Public entrypoint: **`studio/src/Drakosha_SceneFlowCli.res`**. Its implementation is
ReScript per the governing law, and `Drakosha_SceneFlow.resi` exposes only `runStage`;
provider helpers cannot be called by other modules. The 2026-08-05 Python draft is
deleted. Run from `studio/`:

| Stage | Command | Gate required | Produces |
|---|---|---|---|
| 0 refs | `npm run flow:scene1:refs` | formal `reference_board` readiness | receipted `references/drawer_side_interior_candidate_v1.png`, `references/red_hero_car_candidate_v1.png` |
| 1 storyboard | `npm run flow:scene1:storyboard` | `referenceBoard: approved` + `DRAWER_SIDE_INTERIOR`/`RED_CAR` promoted with receipts | 7 stills (C03–C07, C09, C10) in `storyboard/` — ONE review |
| 2 motion | `npm run flow:scene1:motion` | `storyboard: approved` **and** `animatic: approved` | `clips/C02_sock_drag_v1.mp4`, `clips/C08_car_cross_v1.mp4` |
| 3 assemble | (added when Russian voices land) | measured line lengths | pre-lip-sync cut, mobile-encoded |
| 4 lip-sync | (fal.ai OmniHuman — `Cinema_Backends.falOmnihuman`) | **author approves the assembled pre-lip-sync cut** | final cut |

The npm scripts carry `--go` (they exist to be run deliberately); invoking the CLI
without `--go` is a dry run that spends nothing.

After each author approval: promote the existing `DRAWER_SIDE_INTERIOR` and `RED_CAR` rows with
their path, media hash, receipt path, and receipt hash; flip the approval key, bump `revision`,
and note it in CURRENT.md. Do not introduce replacement IDs or aliases.

## Style

The pinned show style key `856a99ee-…` (Higgsfield Low Poly preset, resolved once —
see `stories/frosya-vasya/BIBLE.md`). Character text blocks come from CURRENT.md's
locked rules: Фрося **pre-gift** (no pencil), Вася **no letter pouch**, both
numeric-proportioned (2.5 head-heights), домовой vocabulary only.

## Dialogue

Russian voices are not yet approved (blocking asset #3). When they land: fitted
ElevenLabs reads first, measure, size the slots, assemble, get the cut approved,
ONLY THEN lip-sync (fal.ai `fal-ai/bytedance/omnihuman/v1.5`, first-frame-equals-
still trick, freeze-pad each slot — recipe in BIBLE.md).
