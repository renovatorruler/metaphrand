# The Panel Pipeline — plan v1 (2026-07-29)

Turning a screenplay into consistent graphic-novel panels and motion shots, with Blender as the geometry layer and image models as the style layer. Written for the author's approval; nothing built yet.

## The governing principle

Two halves, one gate between them.

**Left half (cheap, deterministic, repeatable):** script breakdown → assets → set → blocking → cameras → GRAY RENDERS. All Blender. Costs nothing per iteration. Every result is exactly reproducible.

**The gate:** the author approves *geometry* — who is where, what the camera sees — from a marked plan diagram plus a gray contact sheet.

**Right half (expensive, stochastic):** style pass — gray renders become panels via the image model; camera moves become motion shots via the video model. Only ever run on approved geometry.

Nothing on the right runs until the left is signed off. That is the whole economic and sanity argument for the design.

## The three roles, and which stage owns them

| role | owns | artifact |
|---|---|---|
| DIRECTOR | Stage 0 (spec → shooting script) and Stage 5 (approval) | SHOOTING_SCRIPT.md, the signed plan |
| PRODUCTION DESIGNER | Stage 1 (breakdown), Stage 2 (assets), Stage 3 (set + sockets) | BREAKDOWN.md, character/prop libraries, `<set>.blend` |
| CINEMATOGRAPHER | Stage 4 (blocking + camera solve), Stage 6 (gray renders) | BLOCKING data, camera list, gray shots |

---

## STAGE 0 — spec script → shooting script

What we have today is a spec script: scenes, action, dialogue. What the pipeline consumes is a shooting script: numbered shots, each declaring its size, its subject, its angle, and what the audience learns in it. The AMAL train script (`2026-07-20_TRAIN_SHOOTING_SCRIPT_v2`) is already in this form and is the template — bracketed shot IDs like `[1-08]`, one line of camera intent, dialogue attached to shots rather than floating.

Per shot, the record carries: shot ID · size (WIDE/MED/MCU/CU/INSERT) · subject(s) · angle or eyeline source · lens intent · what changes in it · estimated duration · still-or-motion.

**Gate 0:** the author approves the shot list before any 3D work. Cheapest possible place to restructure a scene.

## STAGE 1 — the breakdown

Extracted from the shooting script into typed inventories:

- **CAST tiers.** Speaking; non-speaking but *attended* (the camera rests on them, so they need a real face); pure background (never in focus, reusable stock figures).
- **PROPS.** Anything touched, handed, looked at, or that changes state. AMAL train: the bundle, the green cloth, the snack packet, the steel trunk, the newspaper.
- **SET.** Location and its measured architecture.
- **WARDROBE** per character — this text becomes the reference prompt, so it is written once and reused forever.
- **CONTINUITY STATES.** What differs between shots: cloth drawn up vs folded down, trunk present vs abandoned, who has moved seats.

**Design rule discovered tonight:** a prop that is *held* is generated as part of the character mesh, not placed separately — that is how the woman's bundle came out right. Separate prop assets are only for things resting on surfaces or handed between people.

## STAGE 2 — asset generation, and the normalize step

Per cast member: reference sheet → Tripo mesh → **normalize** → library.

Two hard-won rules:

1. **References are generated furniture-free.** A seated figure floats in the pose against a plain background, with no chair, bench or stool. Proven tonight. This eliminates the imported-stool problem at the source; downstream surgery is impossible because Tripo returns ~150 disconnected mesh pieces.
2. **Normalize means three things, applied once per asset:** real-world scale from a height table; one canonical facing (documented, verified empirically per generator — current Tripo output faces +X at rotation 0); and **origin placed at the anchor that touches the world** — pelvis/seat-contact for seated, floor-between-feet for standing, resting base or grip point for props. Never align by bounding box: bounding boxes vary with whatever junk came in the mesh, which is precisely what broke placement tonight.

Normalized assets live as collections in `characters.blend` and `props.blend`; shots *link* them, so a fix propagates everywhere.

**Pose budget.** No rigs, so every pose is a separate mesh. Principals get 3–5 (neutral, gesture, lean-in, turn-away, stand); attended extras 1–2; background 1. At ~11 credits per figurine this is the main asset cost and must be planned per episode, not improvised.

**Gate 2:** reference sheets are approved *before* meshing — an image costs 2 credits to redo, a mesh 9.

## STAGE 3 — the set, and sockets

Sets are built programmatically from measured dimensions (`coach.blend` exists). What makes them usable is that they carry **named sockets** — empties holding both position and rotation:

- seat sockets: `SEAT_A_WIN`, `SEAT_A_MID`, `SEAT_A_AISLE`, `SEAT_B_*`, `SIDE_1`, `SIDE_2`, `STAND_1`…
- prop sockets: `RACK_A`, `UNDER_SEAT_A`, `WINDOW_LEDGE`…
- character sub-sockets on each asset: `HEAD`, `EYES`, `HAND_L`, `HAND_R` — needed for eyeline maths and prop handoffs.

Characters never receive coordinates. They are parented to a socket with a zeroed local transform. Consistency becomes a property of the file structure rather than something re-tuned per shot; move a bench and everyone on it follows.

Artifact: `<set>.blend` plus `SOCKETS.md` naming every socket and its purpose.

## STAGE 4 — blocking, and camera as grammar

**Blocking data** per scene: character → socket, plus pose variant and any facing offset. Small, readable, diffable, and the single source of truth for "who sits where."

**Cameras are declared as grammar, not coordinates.** A shot says *MCU on WOMAN along SURESH's eyeline* and the compiler solves the placement: it takes the line between the two `EYES` sockets, backs off the distance implied by the shot size and lens, applies the angle, and aims. Consequences that matter: eyelines are automatically correct, the 180-degree line can be computed and *enforced* as a build error, and re-blocking a character automatically re-solves every camera that referenced them.

This is the cinematographer encoded — and it is where the pipeline stops being a pile of scripts and becomes a system.

## STAGE 5 — the approval gate (the author's stage)

Auto-generated from the blocking and camera data, no hand drawing:

1. **SET_PLAN.svg** — bird's-eye plan of the set: every character a labelled marker at their socket, every camera a numbered frustum wedge, eyelines as dashed arrows, props marked, seat occupancy explicit. The same diagram language as `COACH_PLAN.svg`, generated rather than drawn.
2. **SHOT_SHEET.png** — a numbered contact sheet of gray renders, one thumbnail per shot, in script order.

The author marks these up; corrections go back into blocking data and regenerate in seconds. **Nothing proceeds to the style pass without this signature.**

## STAGE 6 — gray renders

Workbench or EEVEE, one frame per still shot; for motion shots, the animated camera rendered as a clay clip. Fast, free, deterministic. These are both the approval artifact and the input to the style pass.

## STAGE 7 — the style pass

**Panels:** per shot, `nano_banana_pro` with the gray render as first reference plus (a) the character reference sheets for everyone visible and (b) a fixed **STYLE KEY** — one approved panel every other panel references, so the look does not drift across a hundred images. Prompt built from a fixed template: the geometry instruction, the wardrobe text from the breakdown, the look-law block, the style clause. ~2 credits per panel.

**Motion shots:** clay camera move → `gemini_omni` with the style key attached. ~12 credits per shot. Honest limitation measured tonight: it follows layout and camera motion but re-proportions geometry, so it is for shots that stand alone, never two shots that must match exactly.

**Panel QC** before acceptance: face check against the hero reference, geometry drift check against the gray render, look-law check (no sepia), text check (no stray lettering).

## STAGE 8 — assembly

The panel presentation engine: panels arriving on the audio track's rhythm, occasional two-up layouts, parallax push on stills, hard cuts or ink-wipes, rare caption cards, voice-only dialogue. ffmpeg and compositing — the part closest to what the studio already does.

---

## Cross-cutting systems

**Consistency ledger.** Every character has one hero face image and a reference set; every rendered panel records which references were attached. Drift becomes auditable instead of mysterious.

**Cost ledger.** Every model job is priced before firing (law adopted 2026-07-29) and recorded per shot. Current rates: reference image 2 · figurine mesh 9–15 · panel repaint 2 · motion restyle 12.

**Typed gates** (studio doctrine — impossible states unrepresentable): a shot card naming a character absent from the cast list fails to compile; a camera whose subject is not blocked in the scene fails to compile; a continuity state that no shot establishes fails to compile.

## Known risks, stated plainly

1. **Faces are the quality cliff.** A wrong face is the distraction the author explicitly rejected. Mitigations: reference-attached repaint, hero face per character, noir lighting licence for shadowed faces, optional face-only touch-up.
2. **Style drift across many panels** — mitigated by the style key and a fixed prompt template.
3. **Pose cost** — no rigs; poses are meshes. Budget them per episode.
4. **Repaint geometry drift** — accept per-panel; never rely on two panels matching pixel-wise.
5. **Crowds** — reusable background figures placed at varied sockets; never bespoke.

## Build order

**Phase A — the spine (no new assets).** Shooting-script format, breakdown extraction, socket system in the coach set, blocking data, auto-generated SET_PLAN.svg and SHOT_SHEET.png, gray renders. Uses tonight's imperfect meshes deliberately: this phase proves the *approval loop*, which is where the author's time actually goes.

**Phase B — asset discipline.** Regenerate the cast furniture-free, implement the normalize step, stand up the character and prop libraries.

**Phase C — the style pass.** Style key, prompt template, batch repaint, panel QC.

**Phase D — assembly and motion.** Presentation engine, then motion shots.

Each phase ends in something the author judges. Phase A is the one that changes how the work feels day to day.
