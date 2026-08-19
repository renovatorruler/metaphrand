# Episode 1, Scene 1 — current production state

**Operational authority:** this file and [`scene1.production.v1.json`](./scene1.production.v1.json).  
**Revision:** 30 — 2026-08-06.  
**Manifest SHA-256:** `024e9c1dba55bede540b2a5be582226cc775c8c5ceaa26b29765877d2936af18`.  
**Status:** storyboard APPROVED (all 7 stills, first-try, incl. C04/C07 framing deviations accepted by the author); animatic in review; motion still gated.

**Rev 29 (2026-08-05):** motion clips generated first-try (receipted, pending author review in the assembled cut: C02 direction law HOLDS, but late-clip drift — wall knobs, shrinking sock, faces — only first 5s used; C08 excellent incl. the foot-toe on the stuck car, one drift: a bed replaces the master's window wall). SCENE1_CUT_v1.mp4 assembled: 41.5s, approved stills + clips on the rev-14 animatic timing, approved RU voices, PSE foley (birds/motor-buzz/steps/flop), mobile encode. Awaiting the author's CUT review; lip-sync (C03 + C06) only after approval per the standing gate.

**Rev 28 (2026-08-05):** author supplied a superior C06 still (true scale: tiny Фрося peeking beside the towering dresser, open bottom drawer in frame) — adopted as author-final, replacing the sh002a reuse.

**Rev 27 (2026-08-05):** C06 resolved by REUSE, author-directed: sh002a_frosya_peek_end_v1 (already approved_reuse for the room-facing end) is the C06 still — Фрося scanning from the mouth; C06_R3 (right identity, wrong end of corridor) archived as alternate. Motion specs minted for C02 (conditioned on the author's start frame + direction law) and C08 (single crossing, rug-fringe snag, nose-toward-mouth per car law). Motion generation authorized.

**Rev 26 (2026-08-05):** C06_R2 rejected (identity FIXED by the trimmed prompt, but drawer fronts with handles appeared again and staging read outside the passage). C06_R3 respec: conditioned on the AUTHOR'S golden passage image (SOCK_DRAG_START) as the environment reference — pictures beat words — prompt asks for the same corridor empty of the children, Фрося alone. R2 archived in storyboard/superseded/.

**Rev 24 (2026-08-05):** the author supplied the definitive C02 start frame (s1_sock_drag_start_author_final.png — passage-camera angle, canonical board direction, plain dresser side, sock length unjudgeable by design) and declared the original passage plate FINAL as the location anchor. Floorboard law recorded: passage boards run ALONG the passage (room-master mismatch accepted as a set cheat). The generated plate lineage (PASSAGE_ANCHOR, SOCK_DRAG_START_R2) is removed; author assets rule. C06_R2 respec next with an identity-first trimmed prompt.

**Rev 21 (2026-08-05):** author rejected the passage plate (facet panels read as DRAWER FRONTS; wall law violated at the root), C06 v2 (off-model Фрося + inherited fronts; at cap — C06_R2 respec authorized after plate approval), and SOCK_DRAG_START_R2 attempt 1 (stiff propped sock; final attempt after plate approval). Plate attempt 2 (FINAL) authorized with the DRESSER WALL LAW in the bound prompt; all three rejects archived. Character-drift fix for the respecs: trimmed prompt stack + 'match the attached ФРОСЯ reference EXACTLY'.

**Rev 20 (2026-08-05):** motion map v4 approved (hiding law + car-stops-short + screen law). C06 attempt 2 (FINAL) respec'd: staged from INSIDE the mouth per the hiding law, referencing the passage plate; v1 (Фрося in open room) archived in storyboard/superseded/.

**Rev 19 (2026-08-05):** motion map approved and registered as direction authority. SOCK_DRAG_START_R2 respec authorized (attempts of the prior subject were spent; author approved the map that mandates the direction fix): sock behind the kids toward the rear crack + dresser-side rule in the bound prompt.

**Rev 18 (2026-08-05):** SOCK_DRAG_START attempt 1 rejected by the author (sock undersized — read ~1 child-height, must be ~3); attempt 2 (FINAL) authorized with hardened sock-scale language; v1 archived in references/rejected/.

**Rev 16 (2026-08-05):** author approved the true-scale PASSAGE_ANCHOR and C04 attempt 2 — both promoted. Animatic approval (given at the rev-14 review) recorded. Old working plates superseded and removed from stage requirements. SOCK_DRAG_START spec minted against the promoted passage. OPEN NOTES parked by the author to prioritize the sample: (1) character identity drifting in busy re-shots, (2) Фрося must never be inside the drawer (C04 shows her inside; accepted for the sample). C03 re-shoot cancelled — v1 stands.

**Rev 15 — TRUE-SCALE PASS (2026-08-05, author-ordered):** proportions were drifting (characters reading too big against human objects). Author reconfirmed the registry: **Фрося 3.5in stays canonical**; human objects standard-size; **passage width locked at 4.5in** (derived from approved C03/C07 framing). A locked TRUE-SCALE prompt block now goes into every RE-SHOT subject only (adding it to receipted prompts would re-spend them). Scope: new PASSAGE_ANCHOR plate (replaces working plate on approval), new SOCK_DRAG_START frame (spec minted after passage approval — it references the new plate), C04 attempt 2 (FINAL; v1 archived in storyboard/superseded/), C03 attempt 2 after passage approval. Animatic approval (rev 14 review) remains valid; affected slots re-cut after re-shoots.

**Rev 14 (2026-08-05):** approved RU takes promoted to `audio/ru/` with the canonical timing artifact `audio/ru_timing.v1.json` (sha-listed takes, slot starts, 41.5s runtime); RUSSIAN_DIALOGUE_AUDIO registered user_supplied/approved.

**Rev 13 (2026-08-05):** per-shot statuses refreshed to reflect the resolved blockers (drawer/car/storyboard/RU-audio all approved); C02/C08 remain working-reference states pending motion.

**Rev 12 (2026-08-05):** author approved ALL SEVEN storyboard stills in one review (explicitly including C04's Фрося-in-drawer variance from the approved blocking and C07's fully-visible peek). All seven rows promoted guarded_generation with receipts; `approvals.storyboard` = approved. Next: dialogue-timed still animatic for author approval, then motion.

**Rev 11 (2026-08-05):** author approved drawer attempt 2 → DRAWER_SIDE_INTERIOR promoted (guarded_generation, receipt-bound); `approvals.referenceBoard` = approved; seven storyboard generationSpec rows minted (C03–C07, C09, C10) with bound prompt/request hashes — the batch runs as ONE guarded set for ONE contact-sheet review.

**Rev 10 (2026-08-05):** drawer attempt 2 (final) generated with the carpet correction and registered as a receipted candidate, `pending_author_review`.

**Rev 7–9 author review results (2026-08-05; 8–9 = promotion mechanics for RED_CAR — provenance guarded_generation + top-level receipt binding):**
- **RED_CAR: APPROVED** by the author and promoted (path/sha256 set, status `approved`;
  attempt-1 candidate bytes unchanged).
- **DRAWER_SIDE_INTERIOR: REJECTED** — "the carpet is incorrect": attempt 1 invented a
  grey-green faceted rug; the room master's floor is bare worn planks with a flat-woven
  fringed runner in muted red-blue stripes. The bound prompt now names the master's floor
  explicitly; new prompt/request hashes are in the manifest. **Attempt 2 (final) authorized.**
  Attempt-1 media+receipt archived in `references/rejected/`.
- **Russian dialogue: APPROVED** — ten takes in `audio_candidates/ru/` (Фрося = ElevenLabs
  Ekaterina, Вася = Leonid, both eleven_v3; the giant child's «Ой, застряла!» is an explicit
  PLACEHOLDER pending real casting). Measured lengths (s): c02 2.80 · c03 4.24 · c05 1.44/1.60 ·
  c06 2.00/1.52 · c08 2.40/6.32 · c09 2.24/1.28 — total 25.84; every line fits its compact-cut
  slot (C08 pair 8.72 into 9.0). These become the timing source for the animatic.

**Rev 3 change (tooling only, no story/asset decisions changed):** Scene 1 now has one guarded
generation boundary: `studio/src/Drakosha_SceneFlowCli.res.mjs`. It calls the formal readiness
gate again immediately before every paid submission, resolves references from that exact
manifest snapshot, permits at most two paid attempts per target, and rejects any existing
output without a matching provenance receipt. Generated candidates remain unapproved until
the author promotes their existing manifest rows. Direct Scene 1 provider calls outside this
runner are repository-lint failures.

**Rev 4 operational update (no asset approved):** guarded attempt 1 produced a drawer/interior
candidate and a red-car candidate. Both media files and their adjacent receipts are registered
in the manifest under `candidate`; the production asset rows remain `missing_blocker` pending
the author's visual review. No storyboard or motion generation has been authorized.

**Rev 5 enforcement hardening (no asset approved):** each planned generated asset now carries
its canonical stage, subject, model, style key, prompt hash, full provider arguments, reference
set, request hash, and output path. The attempt-1 receipts were augmented to bind the provider
arguments that were actually submitted. The runner now uses an atomic attempt claim and an
exclusive per-target lease, exposes only `runStage`, and clean-builds before production runs.

**Rev 6 enforcement closure (no asset approved):** the human authority now binds the exact
manifest hash. The paid boundary revalidates inside its exclusive lease and immediately before
submission, sends immutable content-addressed copies of approved references, and records any
pre-submit stop or post-submit authority change. The older Kuku generator is filesystem-confined
to real `stories/kuku` paths and cannot be redirected into this scene through arguments, traversal,
or symlinks.

**Rev 30 — THE AUTHOR-FRAME LAW (2026-08-06, supersedes prior shot approvals for USE):** only material built from AUTHOR-SUPPLIED frames (or deterministic derivations of them: crops, patches, upscales) is production canon. Approved-and-kept: the Kling sock-drag (author start frame → C03 arrival) and the 18s peek sequence (author corner frame family). Everything else — generated standalone stills used as shots, the omni clips, cuts v1/v2 — is retired to garbage/ as reference history; earlier storyboard approvals stand as HISTORY but no longer authorize USE. Production method from here: author keyframes → two-keyframe Kling → deterministic camera moves; per-shot keyframe plans go to the author for approval BEFORE any motion. Approved voices/audio remain canon.

This document is the mandatory rehydration packet after a new session or context compression. Do not reconstruct Scene 1 from conversation history.

## Enforced readiness gates

The zero-spend ReScript gate in `studio/src/Drakosha_SceneReadiness.res` validates this packet before production work:

- `reference_board` is allowed after the compact cut is approved and all current declared files match their hashes;
- `storyboard` additionally requires an approved reference board and the drawer/car foundation assets;
- `motion` additionally requires approved references, a completed storyboard, an approved still animatic, final dialogue timing, and ready shot states;
- `lipsync` and `delivery` remain closed until their upstream approvals and assets exist.

The gate also blocks more than 11 edit slots, more than 2 motion clips, a working runtime above 55 seconds, unknown shot references, duplicate IDs, missing files, changed asset bytes, or motion clips without one declared principal action.

Generated assets additionally require a successful `frosya.generation-receipt/v1` receipt whose
output hash and captured reference hashes still match. A raw image file is never a production
asset by itself.

Run from `studio/`:

- `npm run readiness:scene1:references`
- `npm run readiness:scene1:storyboard`
- `npm run readiness:scene1:motion`
- `npm run readiness:scene1:lipsync`
- `npm run readiness:scene1:delivery`

A `READY` result permits only the named stage. A `BLOCKED` result is a stop condition, not a suggestion.

## Story authority

The story remains SP004–SP019 in [`2026-08-04_EP1_den-rozhdeniya_SPEC_numbered_bilingual.md`](../../2026-08-04_EP1_den-rozhdeniya_SPEC_numbered_bilingual.md), except that the later approved side-passage geography controls over the obsolete under-dresser wording in SP012–SP019.

The scene must accomplish only four things:

1. Frosya and Vasya cooperate to return a striped sock.
2. Their exchange establishes the house rule: `Так дом устроен.`
3. They discover a cool red car with real headlights that appears to move by itself.
4. Near-discovery forces them to retreat; Frosya looks back at the car.

## Current compact cut

Working runtime is approximately 42 seconds until the approved Russian voices are imported and measured. This cut has **10 edit slots, 8–9 still sources, and 2 true motion clips**.

| Slot | Working time | Method | Essential picture and sound |
|---|---:|---|---|
| `C01` | 2.0 s | existing still + slow push | Approved low room master; dresser, open bottom drawer, concealed right-side passage; ticking and distant panting. |
| `C02` | 5.0 s | **motion clip 1** | From the room-facing end of the passage, Frosya and Vasya approach from the rear corner dragging the sock. Vasya: `А почему великаны всё время носки теряют?` |
| `C03` | 4.5 s | dialogue still + lip-sync | They stop near the front end. Frosya: `Потому что не считают. У меня всё посчитано. Доставай крючок.` |
| `C04` | 4.0 s | one wide still + sound | Editorial ellipsis: operation already underway. Vasya is securely seated on the real right drawer-side rim, pulling his shoelace; Frosya guides the attached sock below. Do not show tying, casting, climbing, or continuous cloth hauling. |
| `C05` | 3.5 s | payoff still + audio | Inside drawer: Vasya is already hidden beneath the sock. Soft flop. Frosya offscreen: `Вась?` Vasya, muffled: `Носок на месте.` |
| `C06` | 5.0 s | dialogue still + lip-sync | Cut ahead: both are safely back down; belt restored. Vasya asks offscreen: `А почему мы кладём на место?` Frosya checks the room and answers: `Так дом устроен.` Motor begins. |
| `C07` | 2.0 s | two-character reaction still | At the room-facing passage entrance, Frosya peeks above Vasya. Both remain hidden. |
| `C08` | 9.0 s | **motion clip 2**, dialogue over picture | The red car drives once across the open room; only the giant child's lower legs are visible; no remote. Vasya and Frosya's delighted car lines play offscreen over the car. |
| `C09` | 3.0 s | danger still + lighting/shadow VFX | Headlights and a giant shadow fill the passage. The giant child says `Ой, застряла!`; Frosya answers `Назад!` No generated image contains the car, giant hand, and children interacting together. |
| `C10` | 3.5 s | final still + footsteps | Vasya is already disappearing around the rear corner while Frosya takes one last look at the distant red headlights. Sound completes the retreat. |

## Locked production rules

- **Direction authority:** `SCENE1_MOTION_MAP_v4.png` (author-approved, manifest asset MOTION_MAP). Screen law: passage camera at the room end; forward = toward camera; the sock is always BEHIND the kids — pulled, never pushed.
- **Hiding law (author):** the children NEVER set foot in the open room. Their whole territory is the passage plus the drawer's right corner reached from the mouth. C06 = a step inside the mouth (scan from cover); C07 = at the lip, eyes out only.
- **Car law (author):** the car NEVER enters or touches the mouth. It stops short, snagged in the rug fringe across from the passage («застряла!»), halting nose-toward-the-mouth so its beams rake into the passage for C09/C10.
- **Dresser-side rule (author, 2026-08-05):** inside the passage the visible dresser wall is its plain SIDE PANEL — no drawer fronts, seams, handles or mouldings may appear where the side should be. Drawer fronts exist only on the room-facing front.

- Low-poly 3D children's-animation style.
- Frosya is approximately 3.5 inches tall; Vasya approximately 3.15 inches.
- Scene 1 Frosya is pre-gift: orange flower, floral patchwork dress, safety-pin pouch, **no magic pencil anywhere**.
- Vasya has his giant-shoelace belt and no letter-tile pouch.
- The characters and car never travel beneath the dresser.
- The dresser stands normally near the wall. The right-side passage is seen cinematically from within; no exterior master may imply a five-inch furniture gap.
- Passage orientation: dresser on camera-left, plaster wall on camera-right. The camera for `C02` is at the room-facing end, looking toward the rear corner; the children approach the camera.
- The remote is never shown. Frosya and Vasya know only that the car appears to move by itself.
- No generated letters, captions, signage, logos, or watermarks.
- One principal physical action per motion clip. No long continuous choreography.
- Use editorial ellipsis, before/after states, sound, lip-sync stills, and compositing before requesting additional motion generation.

## Current assets

### Approved and reusable

- `previs/plates/s1_dresser_room_anchor_locked.jpg` — approved room/dresser master.
- `references/frosya_pregift_lowpoly.png` — mandatory Frosya state.
- `references/vasya_lowpoly_cutout.png` — local Vasya production reference.
- `../../../frosya-vasya/ep1prod/plates/prop_sock.png` — striped sock reference.
- `previs/stills/sh002a_frosya_peek_end_v1.png` — approved for reuse at the room-facing end of the passage, not the rear entrance.

### Working references supplied in the latest review

- `previs/plates/s1_side_passage_anchor_working.jpg` — empty passage; establishes the current camera orientation.
- `previs/stills/s1_sock_drag_start_working.jpg` — relational starting frame for `C02`; characters are small in frame because they are at the distant rear end, not because their physical scale should be reduced.

These two working references are useful and may support the compact storyboard. They have not been renamed `locked` because the user has not explicitly declared them final production assets.

### Forbidden or superseded

- `references/scene1_character_scale_calibration.png` — rejected apparent scale; never use as authority.
- `previs/stills/sh002_sock_passage_v1.png` and `sh002_sock_passage_v3_scale.png` — wrong geography/scale and pre-gift pencil violation.
- `production/SCENE1_VISUAL_BATCH.md` and its generated clips — failed six-setup direct-generation experiment; retain only as diagnostic material.
- `SCENE1_SIMPLIFIED_SHOOTING_PROPOSAL.md` — superseded 13-slot / approximately 19-image proposal; not the current compact cut.
- The 17-shot Scene 1 section in the episode shooting draft — story/blocking source only; not the current generation plan.

## Candidates awaiting author review

- `references/drawer_side_interior_candidate_v1.png` — guarded attempt 1 for
  `DRAWER_SIDE_INTERIOR`; not approved.
- `references/red_hero_car_candidate_v1.png` — guarded attempt 1 for `RED_CAR`; not approved.

Each candidate has an adjacent `.receipt.json` file and an immutable attempt record under
`generation-receipts/`. The manifest records their media and receipt hashes. Rejecting a
candidate does not erase attempt 1; at most one additional paid attempt is permitted for that
target.

## Blocking assets still required

1. Author approval and formal promotion of a consistent drawer-side/drawer-interior reference.
2. Author approval and formal promotion of a red hero-car reference suitable for `C08` and the distant headlights in `C09–C10`.
3. Approved Russian voice files and measured line lengths before final timing and lip-sync.

The following are needed as shot stills after those blockers are resolved: Frosya dialogue (`C03`), hoist-in-progress (`C04`), sock-covered Vasya (`C05`), ground/room-check dialogue (`C06`), two-character peek (`C07`), danger (`C09`), and final look (`C10`). Generate them as one storyboard/contact-sheet batch for a single review.

## Next production action

Review the two guarded reference candidates. Promote only accepted assets with their generation receipts, then create one complete compact-storyboard contact sheet. Do not generate another motion clip before that contact sheet and a still-image animatic are accepted.

## Change protocol

When a decision changes:

1. update this file and the JSON manifest in the same turn;
2. name the superseded decision or asset explicitly;
3. advance the revision number;
4. run JSON/reference validation;
5. summarize only the material change to the user.
