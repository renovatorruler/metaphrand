# «Фрося и Вася» physical-production gate

This directory is the fail-closed bridge between the story script and a shooting script. The prose may request an action; only structured, measured geometry may certify it.

## Current status

Episode 1 is **not yet cleared for shooting**. The generated [preflight report](./ep1_physical_preflight.md) remains the release authority. The former chest-high two-child sock heave has been removed from the screenplay and replaced with the author-approved hook-and-shoelace blocking. The remaining production work is now explicit:

- select and measure the conventional dresser, blunted hook, 7.5-inch shoelace, and deliberately light hero sock;
- prove the corner placement, sheltered right-side passage, drawer-front cover, and hook engagement at the real top edge of the drawer's right side panel;
- add evaluator support or certified proxy evidence for rope climbing, rim transfer, deformable-cloth hauling, the interior fall, the full-arm hang, and the final short drop;
- test the loose sock around the dresser's rear-right corner and through the side passage with a flexible swept envelope rather than a rigid flat-width box;
- most shooting blocks have not yet received their mandatory physical/nonphysical coverage classification.

The approved editorial solution is not itself a physical certificate. Numbers from unapproved proxies remain useful for finding contradictions, but they cannot produce a passing release verdict.

## Authoritative inputs

- [physical_registry.v1.json](./physical_registry.v1.json) contains absolute dimensions, poses, states, named anchors, positioned openings, positioned interior volumes, bound destinations, affordances, capabilities, mass, handling methods, and evidence provenance.
- [ep1_physical_manifest.v1.json](./ep1_physical_manifest.v1.json) binds exact hashed `SH###` blocks to author decisions and structured interactions.
- [ep1_physical_backlog.v1.json](./ep1_physical_backlog.v1.json) preserves the consolidated action-critical modeling queue so unresolved production work is not rediscovered line by line.
- The Markdown [Object and Scale Registry v1](../../2026-08-04_OBJECT_SCALE_REGISTRY_v1.md) remains useful design prose, but it is no longer sufficient evidence for a shooting action by itself.

The registry distinguishes, for example:

- `low_drawer.floor_front`;
- `low_drawer.floor_right_side`;
- `low_drawer.front_rim_top`;
- `low_drawer.right_side_rim_top`;
- `low_drawer.mouth`, the exposed pullout slot.

Those names are never aliases. A floor anchor cannot be substituted for the physical top edge of either drawer panel, and the top of the front panel cannot be substituted for the top of the right side panel used in the approved climb. The full drawer interior also cannot stand in for the much shallower strip exposed when the drawer is only slightly open. The rejected story-convenient chest-high rim is no longer present in the machine registry.

The drawer destination also binds its floor and the dresser underbody/support anchor. The evaluator requires the floor to be vertically aligned with the bound rim, requires it to coincide with the interior bottom, and rejects support geometry that rises into the drawer. This prevents an internally convenient drawer tuple from floating independently of the furniture section that owns it.

The manifest hash-binds the backlog and repeats its exact unresolved IDs. Any unresolved item blocks release even after shot coverage is filled, so the queue cannot become a forgotten advisory document.

## Evidence law

Release checks currently accept only:

- `author_locked` canon;
- `physical_measurement` records;
- `derived` values whose entire input chain is certifying.

The following are fail-closed whenever an interaction consumes them:

- `story_required` and `unmeasured`;
- `estimate` and `catalog_reference` in the shooting-release profile;
- `asset_measurement` until the asset pipeline cryptographically verifies both the selected asset and its measurement receipt.

This is deliberate. “The scene needs the drawer to be this low” is an asset-search request, not proof that such a dresser has been selected.

Decision status and evidence provenance are the gate’s governance inputs, not cryptographic proof of who typed them. They must be changed only from an explicit author decision or a real measurement receipt. The current proxies remain `estimate`/`story_required`, so relabeling them merely to obtain green output would be falsifying an input, not resolving the action. A later asset pipeline should bind physical measurements to selected-asset hashes and signed/controlled receipts.

## Coverage law

The gate parses `^### SH###` headings from the actual Markdown, hashes the entire screenplay and each individual shot block, and then requires:

1. exactly one coverage row for every parsed shot;
2. an unchanged block hash;
3. either a structured physical interaction or a closed nonphysical reason backed by an explicit `author_approved` exemption;
4. reciprocal links between every physical shot and interaction;
5. at least one explicit decision link per physical interaction, with `author_approved` status for every linked decision.

`pending`, missing, stale, proposed, superseded, and rejected records all block release.

This mechanism cannot infer every physical verb hidden in arbitrary prose. The long-term invariant is therefore stronger: the shooting document must be generated from a fully classified manifest, and its generator must call this validation core before writing Markdown or HTML.

## Current implemented interaction checks

- `move_object`: exact handled orientation and transformed grips, final-frame actor stances, provenance, closed handling method, loaded vertical/three-dimensional reach, mass/capacity, actor/actor and actor/object collision, complete translated formation width/headroom, and unproved-turn rejection. The evaluator never chooses a best-case rotation.
- `place_into`: all of the above as applicable, plus a single target-state destination that binds its rim, positioned aperture, and positioned interior; ground-supported stance evidence; actor/target collision; team lift capacity; aperture fit; straight-down entry; and clearance-preserving final containment. The manifest cannot mix a low anchor with an unrelated opening or volume.
- generated side elevations use the same registry coordinates as the validator and carry screenplay/registry/manifest/backlog provenance hashes;
- approach-facts SVGs draw only the registered target footprint and affordances; their evidence may still be noncertifying, and they never invent a route, cover location, dresser, or visible-room zone.

In schema v1, actor stances use the final handled/target frame and must have `z=0`. Any platform, ramp, ledge, or other elevated support requires explicit registered support geometry before a later schema may certify it. Object orientations are explicit: `xyz` is identity and `yxz` is a right-handed +90° yaw (`x′=-y, y′=x, z′=z`); bounds and grip points transform together. Every opening declares its physical plane, center, and two clear spans. The current `place_into` contract intentionally certifies only a positioned `xy` aperture on the top face of its bound interior; side insertion requires a later swept-path model rather than a guessed rotation.

Concealment is deliberately fail-closed. Every state consumed as a `place_into` target or `move_object` path must explicitly classify `visibilityRisk` as `none` or `exposed_to_giants`; omission is a blocker, not an implicit safe value. Visibility risk belongs to the registered target/path state, not to a switch in the interaction manifest, so a shot writer cannot accidentally turn the requirement off. When exposure is present, schema v1 blocks even if the state carries a `protected_approach` tag: that tag is descriptive, not proof. Passing concealment will require a later structured relationship among the approach path, cover volumes, the full handled formation, and the exposed observer zone. The generated approach artifact therefore shows registered facts only and never draws an imagined safe route.

Cornering is equally fail-closed. A `ninety_degree_turn` always blocks in schema v1; even a `turn_envelope_measured` tag is noncertifying until the registry can carry the actual sampled or swept actor-plus-object envelope and its evidence receipt.

Before the rest of Episode 1 can pass, the remaining action families need structured variants for rider support and swept envelopes, transformations and exclusion zones, pass-through apertures/orientations, sightlines, collision trajectories, and pull/knot mechanics. Until those are represented, coverage remains blocking rather than pretending the scenes were checked.

## Commands

From `studio/`:

```sh
npm run test:spatial
npm run preflight:drakosha
npm run verify-preflight:drakosha
npm run release:drakosha
npm run verify-release:drakosha
```

`test:spatial` must pass. `preflight:drakosha` is expected to exit nonzero while the current shooting draft is invalid; it still publishes the report and SVG proofs as one atomic diagnostic set. [ep1_physical_preflight.index.json](./ep1_physical_preflight.index.json) is the set’s commit marker and hashes the exact inputs, report, and proofs. An old or partially replaced file is not current merely because it remains on disk. `verify-preflight:drakosha` reconstructs the set and verifies every indexed byte; both a verified `PASS` and a verified `FAIL` are meaningful diagnostic states.

`release:drakosha` is the hard publication boundary. It writes `production/cleared/EP1_SHOOTING_CLEARED.md` only after a fully passing verdict, using a receipt as the final atomic commit marker. `verify-release:drakosha` rechecks all four input hashes and reruns the current evaluator. Hosting and shot-generation jobs must first pass that verifier and must never consume the working shooting Markdown directly. The current failed draft produces no cleared file.

The repository-wide `npm test` includes the spatial regression tests.

## Required workflow for a physical rewrite

1. Record the story decision as `proposed`; do not write it into the authoritative shooting script yet.
2. Add/select measured states, named anchors, openings, paths, and handling capabilities.
3. Add the structured interaction and its exact shot coverage.
4. Run preflight, run `verify-preflight:drakosha`, and inspect the coordinate-derived elevation plus the clearly labeled approach-topology diagnostic.
5. Obtain author approval for the actual feasible action and change the decision to `author_approved`.
6. Generate the shooting Markdown/HTML only after the gate passes.

If any source block or registry input changes, the hashes and verdict become stale automatically. The fix is to rerun the physical review—not to edit the expected hashes by themselves.
