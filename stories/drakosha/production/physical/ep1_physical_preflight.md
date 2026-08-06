# Episode 1 physical preflight

**Status: FAIL — NOT CLEARED FOR SHOOTING**

> This report is generated from the machine-readable registry and interaction manifest. A camera angle or a sentence in the screenplay cannot override a failed measurement.

- Registry schema: `drakosha.physical-registry/v1`
- Manifest profile: `shooting_release`
- Screenplay SHA-256: `3f71be94d267bb732048b9e8259457d1f54849bac508c710ec25dfa4afb330ee`
- Registry SHA-256: `05ef4fff48a83c0ce8843b6fd21281ecc04dfeeae75a5ae69b92c338c7d99731`
- Manifest SHA-256: `2a0215922a58993569042a0c369d970671dcb57fb86053a28a6a14122f277144`
- Physical-backlog SHA-256: `f080f880643c8e1ba6d41770779977be497c1ce6de0ef2f2fb3a55b613388f1c`
- Parsed shots: 297
- Blocking findings: 3
- Warnings: 0

## Release-level result

- No production-cleared screenplay or receipt may be written from this draft.
- `PHY_BACKLOG_OPEN` — 18 unresolved production interactions remain; first: PHYQ-01-SOCK-PASSAGE, PHYQ-02-SOCK-DRAWER, PHYQ-03-DRESSER-ESCAPE, PHYQ-04-TOP-CAROUSEL, PHYQ-05-MAGIC-WORK-ZONE, PHYQ-06-MAMA-TRANSFORM, PHYQ-07-SCOOTER-SPAWN-MOUNT, PHYQ-08-SCOOTER-RAMP-TURNS, PHYQ-09-CAT-BLOCK, PHYQ-10-TANK-DROP-FIT
- `COV_SHOT_MISSING` — 288 screenplay blocks have no classification; first: SH010, SH011, SH012, SH013, SH014, SH015, SH016, SH017, SH018, SH019, SH020, SH021
- `COV_PENDING` — 9 shots are still pending physical classification

## Detailed findings

| Code | Level | Scope | Finding | Required remedy |
|---|---|---|---|---|
| `PHY_BACKLOG_OPEN` | BLOCK | physical backlog | 18 unresolved production interactions remain; first: PHYQ-01-SOCK-PASSAGE, PHYQ-02-SOCK-DRAWER, PHYQ-03-DRESSER-ESCAPE, PHYQ-04-TOP-CAROUSEL, PHYQ-05-MAGIC-WORK-ZONE, PHYQ-06-MAMA-TRANSFORM, PHYQ-07-SCOOTER-SPAWN-MOUNT, PHYQ-08-SCOOTER-RAMP-TURNS, PHYQ-09-CAT-BLOCK, PHYQ-10-TANK-DROP-FIT | Resolve the consolidated interaction items and move their measured, approved definitions into the manifest before release. |
| `COV_SHOT_MISSING` | BLOCK | coverage | 288 screenplay blocks have no classification; first: SH010, SH011, SH012, SH013, SH014, SH015, SH016, SH017, SH018, SH019, SH020, SH021 | Classify every SH block as physical, none, or pending. Release requires zero pending or missing rows. |
| `COV_PENDING` | BLOCK | coverage | 9 shots are still pending physical classification | Complete the physical/nonphysical classification before release. |

## Passed checks

- screenplay hash matches the reviewed source
- 297 stable shot blocks parsed

## Generated geometry proofs

- None.

## Release rule

The shooting-script generator must refuse to publish Markdown or HTML while this report contains a blocking finding.
