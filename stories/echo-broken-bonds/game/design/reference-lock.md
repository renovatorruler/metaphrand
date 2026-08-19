# Echo and the Broken Bonds — Reference Lock v1

**Lock ID:** `REFERENCE_LOCK_v1`  
**Inspected and frozen:** 2026-08-05, America/Puerto_Rico  
**Purpose:** quality comparison only. No reference byte may ship or enter an asset-generation prompt.

The comparison bar is fixed before visual generation: **Echo must match Mini Force's silent setup → activation → large-form reveal and problem → specific counteraction → held consequence, while matching PBS KIDS' age-appropriate direct manipulation with one active cue, large targets, immediate literal feedback, and a cohesive full-stage world.**

## Immutable source anchors

| ID | Official source | Exact frozen state | Only property borrowed |
|---|---|---|---|
| `MF-E1-0516` | `https://www.youtube.com/watch?v=1-b0HsZJfWE&t=316s` | Video ID `1-b0HsZJfWE`, `05:16.000` | A small hero and much larger immediate danger read in one silent glance. |
| `MF-E1-0720-0731` | `https://www.youtube.com/watch?v=1-b0HsZJfWE&t=440s` | `07:20.000–07:31.000`; checkpoints `07:20`, `07:23`, `07:26`, `07:31` | Setup → activation → unmistakable scale reveal → immediate return to action within 11 seconds. |
| `MF-E3-0944-1014` | `https://www.youtube.com/watch?v=yAxghmk9mRE&t=584s` | Video ID `yAxghmk9mRE`, `09:44.000–10:14.000`; checkpoints `09:44`, `09:59`, `10:04`, `10:09`, `10:14` | Specific constraint → comprehension → counteraction → impact → held consequence within 30 seconds. |
| `PBS-TT-FIRST` | `https://pbskids.org/games/play/treehouse-trouble/108680` | First construction challenge immediately after **Retry**, parts drawer open | One target and one cue, direct manipulation, large geometry, immediate literal feedback. |
| `PBS-AGE` | `https://www.pbs.org/parents/shows/hero-elementary/about` | Official Hero Elementary audience statement inspected 2026-08-05 | Establishes that the interaction reference targets ages 4–7; it does not validate Echo. |
| `ASTRO-CEILING` | `https://www.playstation.com/en-us/games/astro-bot/` | Official product/gameplay media inspected 2026-08-05 | Nonbinding ceiling for color, animation response, environmental reaction, and charm only. |

ASTRO BOT cannot decide camera, geometry, input, or a pass. It is a PS5 3D platformer; Echo is a pointer/touch, fixed-stage browser game.

## Frozen PBS measurements

The inspected desktop page used a `1563×929` CSS viewport. The game iframe measured `1075.19×692.98` CSS px in the frozen state.

- Inventory: approximately 24% of stage width.
- Primary drop region: approximately `83×83` CSS px, about 12% of stage height.
- Major circular controls: approximately `90–96` CSS px.
- Attention competition: one placement target and one animated tutorial cue.
- Echo translation at `1280×720`: inventory `≤25%` width; core draggable/drop regions `≥80×80` CSS px; primary controls `≥88×88` CSS px; snap response `≤150 ms`; release response `≤250 ms`; visible world consequence begins `≤500 ms`; one active cue.

These values, not later changes to the live PBS page, govern every round.

## Five release-blocking A/B properties

Each round judges all five; no substitution or cherry-picking is allowed.

1. **Vulnerability hierarchy:** randomized, unlabeled one-second still versus `MF-E1-0516`; subject, danger, and scale relationship must read muted and grayscale.
2. **Player-caused scale transformation:** randomized, unlabeled raw clip versus `MF-E1-0720-0731`; setup, activation, complete larger form, small operator, and return to action must fit the same eleven-second window.
3. **Problem-specific causal payoff:** randomized, unlabeled raw clip versus `MF-E3-0944-1014`; the exact problem, chosen counteraction, impact, and resulting safety change must fit the same thirty-second window.
4. **Held consequence:** randomized final two-second clip plus before/after stills versus the final held consequence of `MF-E3-0944-1014`; the changed world must remain unobscured long enough to inspect and must persist until the next fresh action.
5. **Interaction competition:** randomized stage still versus `PBS-TT-FIRST`, accompanied by blinded geometry/cue counts; Echo must present no more simultaneous competition while meeting or exceeding the frozen target sizes and feedback limits.

A tie, abstention, “incomparable,” unavailable source, missing packet, or critic disagreement without a two-of-three majority is an Echo loss. Echo must win four of five properties.

## Reference evidence packet

Before the first billable visual request **and** before the first scored runtime round, create `evidence/reference/reference-evidence-manifest.json`. It must contain source URL, video ID or game state, capture UTC, exact time range, source/display dimensions, crop/letterbox rule, audio state, file path, byte size, and SHA-256 for:

- `mf-e1-0516.png`;
- `mf-e1-0720-0731.mp4` and four checkpoint PNGs;
- `mf-e3-0944-1014.mp4` and five checkpoint PNGs;
- `pbs-treehouse-first.png` plus a JSON geometry record;
- a screenshot/PDF of the official PBS audience statement; and
- source-page metadata captures proving the official URLs and inspection state.

Reference clips are exact time trims only: no reframing beyond a recorded player-content crop, no speed change, interpolation, color treatment, replaced audio, or edit. For blind packets only, the locked test harness applies the same opaque neutral rectangle `x=1080, y=0, width=200, height=40` on the common `1280×720` canvas to both candidates, hiding Echo's evidence watermark without selectively hiding picture content. It may also add identical neutral letterboxing. No other pixel or audio transform is permitted. Unmasked raw Echo evidence and original QA reference bytes remain hash-bound and are inspected separately by the integrity verifier.

Capture only through ordinary, permitted playback from the official public pages. Do not bypass access controls or DRM. If a required item cannot lawfully or technically be preserved, the A/B gate remains blocked; do not replace it mid-streak with a more convenient reference.

The manifest and files become read-only when first hashed. Their manifest hash is included in `planning-lock.json`, `content-manifest.json`, `evidence-manifest.json`, every comparison packet, and the post-verdict round record. Any changed reference byte, crop, measurement, source, property, mask, or viewing condition creates `REFERENCE_LOCK_v2` and resets the passing streak.

## Rights boundary

Reference evidence is local QA material only. It is excluded by package-closure tests, forbidden as model input, forbidden from public progress-page embedding, and never redistributed. The progress page may show source links, measurements, and Echo's own captures; it may not host protected reference frames or clips.
