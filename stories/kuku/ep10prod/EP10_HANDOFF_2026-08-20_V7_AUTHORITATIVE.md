# Episode 10 handoff — 2026-08-20 (V7, AUTHORITATIVE — supersedes all earlier EP10 handoffs)

## Author ruling of record

The author reviewed both live lineages on 2026-08-20 and ruled:

- **V6 («गेंद» / easy-to-animate courtyard story) is REJECTED** — the author's words: it "felt too lame." The animation-simplicity argument did not outweigh the loss of story.
- **The cart-and-track lineage stands, with seven craft fixes applied. It is now V7.**

Any session that reads `EP10_HANDOFF_2026-08-20.md` (the V6 handoff) must treat it as historical. V7 is the episode.

## Authoritative inputs

- Screenplay: `stories/kuku/2026-08-20_EP10_ga_gaay_SPEC_SCREENPLAY_v7_AUDIO_FIRST.md`
  - SHA-256: `e5ca84926f999623aa9d0631df9fd36d682a34e9784ef15ed985beb9e201b661`
- Episode 9 continuity source: `stories/kuku/2026-08-11_EP9_ba_bada_SPEC_SCREENPLAY.md`
  - SHA-256: `248cad48c04c85c69766541e85abc1056a23dba4d51b5f8b1bdbe6a7aca05888`
- Cold-open production plan: `stories/kuku/ep10prod/EP10_COLDOPEN_EDL_v1.md`

Historical only, do not build from: v5, v5.1, v6, the V4 audio-first table read, and every earlier table-read receipt.

## The seven fixes that make V7 differ from V5

1. The title word `गाय` is now spoken by the children and rings in the golden recognition beat (scene 3 word-family: गाय · गाड़ी · गौरी · गिरना).
2. The `ग` curve now does work a flat wall could not: the cart's nose climbs the curve's slope, the scrape tone rising as it decelerates, then settles into the curve without a jolt.
3. Middle repetitions differentiated — Vesper's late call in scene 4, Castor's first calming attempt failing before the second lands.
4. Cheel no longer narrates the consequence of her own sabotage; rope sound plus Leda's warning carry it.
5. The three-clause sky boon is taught in calm scene 0; the crisis carries only the one-clause recall.
6. Dadi's interrogation removed; Furia states the facts in one line and Dadi blesses.
7. Vesper's sleep is earned — his yawn nearly costs the cart, he vows to stay awake, and Dadi's closing line pays it off.

## Authorization state

- **Cold open: AUTHORIZED to build** (author, 2026-08-20). Six lineage-safe setups plus the cart-lineage divergence are specified in the EDL.
- **Not authorized:** a new full-episode paid table read, voice requests, or full-episode image/video generation. Report request counts, billable characters, SFX inventory and projected duration before any paid full-episode run.

## Audio-first contract (unchanged from V5, still binding)

- Generate only explicit character dialogue and the two declared choruses.
- Mix real local sound for every `(ध्वनि:)` row; a narrator never reads cue prose.
- Skip ordinary action rows, headings, metadata, and handoff files.
- Use the full approved 67.4-second title song.
- Preserve the authored flight, group-lift, braking, forging and stopping durations; do not concatenate them into a rapid dialogue reel.
- Causality must survive with eyes closed; images support, they do not carry.

## Visual-style defect on record (2026-08-20)

The eleven cold-open frames in `ep10prod/coldopen/frames/` were generated WITHOUT a papercraft style clause and came back in a flat painterly 2D-CG look. The series style is **papercraft**. The author accepted these frames rather than re-render them, and ruled that all future Kuku image and animation work must:

- state the papercraft look explicitly in the prompt (layered cut-paper, visible paper edge and fibre, shallow diorama depth, paper-shadow separation between layers);
- pass an APPROVED PAPERCRAFT FRAME as a style reference alongside the character board — a character board alone only fixes design, not medium;
- verify one test frame before generating a batch.

If the cold open is ever animated, the style must be corrected first, or the drift is baked into motion.

## Palette defect on record (2026-08-20)

The 44 hero setups in `ep10prod/stills/` came back warm/sepia-leaning rather than the season's bright, vibrant, saturated construction-paper palette. The author accepted them rather than re-render, and ruled the palette law explicit going forward:

- Kuku's colour identity is **bright and vibrant** — saturated matte paper stock, not aged, dusty or sepia.
- **The style reference carries the palette.** `e8_s0_rishi.png` and `e8_d4_kuku.png` fix the papercraft medium correctly but are themselves muted frames, so they dragged the whole batch warm. Choose a bright representative frame as the style reference, or pass both a medium reference and a palette reference.
- The V7 script sets scene 0 at साँझ (dusk), which compounds the warmth. Where dusk is required, keep the paper stock saturated and let only the sky carry the warm shift.
- Palette is correctable after the fact with a free local saturation/vibrance pass; medium is not. Check medium hardest at test-frame time.

## Lighting doctrine — «the last golden evening» (author-approved 2026-08-20)

The warm palette of the EP10 stills is now DIEGETIC and deliberate, not a defect to correct. V7 already sets scene 0 at साँझ with every later scene marked लगातार: the whole episode is one unbroken evening, so the episode is shot at golden hour by design.

Three rules make the warmth do work:

1. **The light is the clock.** Vesper, already the lookout, also calls the sun. Each red marker the cart passes sits in lower, redder light than the last, so the tension rises through colour rather than announcement. The rescue must finish before the light goes.
2. **The letter becomes the light.** The `ग` is forged from golden breath as the sun drops behind the gurukul wall; once it stands, IT is the light source for the remaining rescue shots and for Gauri being calmed. The series thesis lands as image: the letters are made of the same light as the day, and when the day goes, what a child has learned is what still shines.
3. **Contrast preserves the gold.** दादी's courtyard through the open doorway and the tower door stay COOLER. If everything is one temperature the gurukul stops reading as golden.

Season-level device: earlier episodes are bright daylight; EP10 is the last golden evening before Cheel's tower opens. The season's arc may run noon → dusk → night, with palette as the arc's clock.

Technical note: warm ≠ washed out. Golden hour is SATURATED. A free local saturation/vibrance pass is applied to the hero setups (`stills/` → `stills_graded/`) so derived frames inherit rich paper stock under warm light; sepia flatness is corrected, the golden light is kept.

## Two more image laws on record (2026-08-21)

1. **The कड़ा is never optional.** Any dragon child in GREAT form must visibly wear their golden bracelet — it is the source of the transformation and the surface the letters imprint on. Several EP10 frames rendered great forms bare-armed. Every prompt (hero and derivation) must state the bracelet explicitly, and it must survive edits.
2. **Derivations must MOVE a character, never ADD one.** Instructions of the form "the red dragon has stepped forward" caused nano to insert a second red dragon while leaving the original in place. Derivation prompts must say so directly: "the SAME single red dragon has moved — there is still exactly ONE red dragon in the frame; do not add a second." Affected frames: `inbetweens/h01_ring_wide__a_rishi_enters.png`, `__b_furia_steps_out.png` (both show duplicate Furia; excluded from the review cut).

## Assembly law — speaker-matched picture

The first review animatic distributed frames round-robin within each scene, so the picture frequently showed a character who was not the one speaking. Fixed in `assemble_v7_numbered.mjs`: each dialogue cue now selects a frame in which the SPEAKER is the subject, preferring frames from the current scene, then any frame of that speaker, and only then a scene establishing shot. Never show character A while character B talks.

## The deterministic prompt law (author ruling 2026-08-22, refined same day)

Every generation prompt is rendered deterministically by code from a typed spec — never hand-composed per shot. The rendered output is plain labeled text (SHOT/STYLE/SUBJECTS/HARD RULES sections), which models follow better than raw JSON; the author's refined ruling is that determinism is the requirement, not the JSON format. The module is `studio/src/Kuku_PromptSpec.res` (imageSpec / editSpec / videoSpec); the style, bright-vibrant palette, कड़ा bracelet, exactly-one-of-each-character and negative laws are constants inside the serializer, so a driver cannot omit them. Drivers are ReScript files in `studio/src` (see `KukuEp10_SpecRun.res`) run as compiled `.res.mjs` from `studio/`. S014 was regenerated at 10s (25cr) so Fyuria completes her loops; `assemble_v7_numbered.mjs` now stretches a clip cue's segment to the clip's full length and builds its own matching dialogue mix. NOTE: one higgsfield CLI video invocation double-submitted (a 6s job at 15cr alongside the 10s at 25cr) — reconcile transactions after every video spend.

Review-notes round 1 applied through it: `stills/s011_castor_calm_solo.png` (cart+cow removed for cue S011; the original h22 frame is untouched for scene 2) and `clips/S014_furia_ring_flight.mp4` (Seedance 2.0 Mini, 12.5cr, start-image anchored to h03_furia_mark__b_look_up). `assemble_v7_numbered.mjs` gained a `CUE_MEDIA` map — per-cue still or clip overrides that win over the pool rules.

### The story-state engine (2026-08-23)

The prompt law gained a continuity layer: `studio/src/Kuku_Ep10State.res` is the single source of truth for what is true WHEN (गौरी aboard the cart from the briefing to the stop; great forms until the shrink; the dusk lighting clock; the ग-shape existing only after the forging; the bell leaving the arch with चील). Shots in `KukuEp10_Shots.res` declare a BEAT plus framing; the builder derives the rest — a shot whose cart bed is visible during the runaway gets गौरी injected automatically, and using the ग-shape before the forging raises at render time. This engine found and fixed a sixth empty-cart frame (h20) the manual audit missed. Cart-continuity rerolls done through it: h16, h20, h21 (+2 re-derived variants), h32, h33, h36.

### The set bible (2026-08-23)

Sets drifted because they existed only as prose. `studio/src/Kuku_Ep10Sets.res` now holds each set as DATA — landmarks at fixed metric positions (the lane: 60 m long, 8 m wide, falling 9 m; post at 0 m, markers at 12/24/36 m on the centreline, flat from 48 m, wall at 60 m) — and derives three things from that one source: the blueprint (plan + elevation SVG, `sets/*_blueprint.svg`), the canonical set prose the prompt engine emits, and the reference-plate path a shot attaches.

Pipeline per set: blueprint (free, author-approved) → master plate via nano with the blueprint attached as a map (2cr) → Seedance Mini camera survey of the EMPTY set from the plate (25cr) → vantage plates extracted from the survey (free). `Kuku_PromptSpec.imageSpec` gained `plate`, attached SECOND (style key → set plate → character boards), with a law telling the model the plate IS the location.

Lane bible complete: `sets/lane_blueprint.svg|png`, `sets/lane_plate.png`, `sets/lane_survey.mp4`, and four vantage plates (`lane_top_looking_down|upper_mid|lower_mid|flat_approach_plate.png`). `lanePlateAt(y)` picks the plate from a shot's position along the lane. Plates attached to the six down-the-lane wide shots (h15, h16, h20, h32, h33, h36); overheads, low angles and inserts stay plate-free because the survey's camera does not match theirs. Proof: h15 regenerated on the plate reproduces the lane exactly (see PRE_SPEC_h15_cart_runs.png for the old, unrelated place).

Two plate laws learned the hard way: the blueprint's WORDS AND NUMBERS ARE NOT PROPS (the first lane plate carved "STONE POST" and numbered the markers), and a plate shows the set BEFORE the story (no ga-shape, no cart, no rope). Both are now constants in `KukuEp10_SetBible.platePrompt`.

Remaining: courtyard, flat_stone, tower, doorway, grass_verge plates + surveys; then regenerate shots set by set.

### Blender blockouts (2026-08-23) — geometry stops being a guess

Blender 5.1.2 is installed (`/opt/homebrew/bin/blender`). `studio/src/KukuEp10_Blender.res` emits the set data (the same landmark table) as `sets/blender/<set>_scene.json` including named cameras positioned in set metres; `sets/blender/build_set.py` reads it and constructs the real geometry — sloped lane surface, kerbs, hillside, post, markers, end wall — then renders any camera headless and free. Blender's API is Python-only (same exception as the Defold runtime); ReScript still owns the data.

Proven end to end: four lane cameras rendered from one build (`*_blockout.png`), then a nano STYLE PASS (`KukuEp10_SetBible.res stylepass <set> <cam_tag>`, 2cr) turns a grey blockout into a finished papercraft plate that keeps the blockout's exact camera and geometry. This gives angles the video survey could not — e.g. bottom-looking-up — with no breathing walls.

Known gap in the style pass: it renders landmarks named in the set prose even when the camera cannot see them (the bottom-looking-up test grew an end wall behind the courtyard). The prompt needs a rule that the blockout is the authority on what is in frame, and prose landmarks not visible in it must not be added.

### AI-generated 3D dioramas (2026-08-23)

Higgsfield's 3D catalogue turns an approved plate into real geometry, which is the fastest route to a Blender set: `hunyuan3d_v3_image_to_3d` (11cr) and `tripo_h3_1_image_to_3d` (9cr) were both run on `sets/lane_plate.png`. **Tripo won clearly** — stone-course textures, the stone post present, trees, kerb walls, the end wall and all three markers as distinct forms; Hunyuan produced a cruder, flatter relief. Meshes are in `sets/blender/assets/` and `sets/blender/inspect_glb.py` imports any GLB, reports mesh count/tris/dimensions and renders four turntable views.

Costs: text-to-3D `tripo_3d` 5cr, `tripo_h3_1_image_to_3d` 9cr, `tripo_h3_1_multiview_to_3d` 9cr, `hunyuan3d_v3_image_to_3d` 11cr.

Limits found: both return ONE fused mesh (nothing separable — the post cannot be moved, props must be generated individually), the depth is relief-like rather than a true survey (the lane's 9 m fall reads nearly flat), occluded/back faces are invented, and the meshes are heavy (Tripo 1.89M tris / 53 MB; decimate before use). Scale is arbitrary and must be normalised against the metric set data.

Next test worth running: `tripo_h3_1_multiview_to_3d` (9cr) fed with several consistent views of the same set — which the Blender blockout can now produce for free — so the mesh gets correct proportions AND our design instead of one viewpoint's guess.

### Set-bible pass (2026-08-24)

The lane now agrees with itself. All six down-the-lane wide shots (h15, h16, h20, h32, h33, h36) were regenerated against `sets/lane_plate.png` — same flagstones, kerbs, rubble wall, stone post, three markers and horizon in every one, with गौरी aboard throughout.

**Scale law fixed.** «several times the height of a grown man» never landed — the dragons kept rendering cow-sized. `Kuku_PromptSpec` now anchors GREAT form to objects in frame instead of adjectives: a hay cart would fit between her front claws, a grown man reaches only to her knee, her head rides above the trees and walls. h16 re-rolled on the new law reads correctly.

**Derivation staleness is now detected, not remembered.** `ep10prod/rederive.mjs` compares each in-between's mtime against its hero's and re-derives only what the hero has outrun, with the edit prompt rendered by `Kuku_PromptSpec.editPrompt`. 21 stale frames were caught and re-derived this pass (18 + h01's 3 twice, since h01 was re-rolled again onto the improved courtyard plate — 6cr of that was avoidable and is the cost of not sequencing plate-approval before hero regeneration).

**Courtyard plate approved** (`sets/courtyard_plate.png`, second version). The first version rendered the flight ring human-sized, which an enormous dragon cannot fly through — so the set bible now carries DIMENSIONS as well as positions: the ring is 14 m across, the bell arch spans 10 m so a flying dragon passes beneath it. Landmarks needing a size must state it; position alone is not enough. h01 is wired to this plate and regenerated on it.

Remaining: plates for flat_stone, tower, doorway, grass_verge; tier-2 lighting-only shots; the S008 lane-geography clip (25cr, unauthorised); then SFX bed, title song, ग/गाय glyph composites.

### The spine pass (2026-08-24) — the episode finally sits on its sets

Author's verdict before this pass: "nothing seems fixed, nothing reflects the set we designed." He was right — **7 of 52 shots were on an approved plate**; the machinery had been built and applied to a seventh of the episode. Two things changed.

**1. Every set now has an approved plate** — lane, courtyard, flat stone, tower, doorway, grass verge. **50 of 52 shots are bound to one.** The plate law now adapts to shot size: a WIDE shot must reproduce the plate's exact camera, while a CLOSE or MEDIUM shot inherits the place — the same ground, walls, textures, palette and landmark positions — without being forced back to the plate's vantage. Without that split, close shots could not use plates at all.

Two plates needed correction on arrival: the grass verge rendered the blueprint's own labels into the world (the same defect the lane plate had — the rule exists but nano still leaks text when the blueprint is attached), and the doorway's village came out alpine half-timbered instead of a north-Indian courtyard.

**2. Progression is now data.** Plates fix WHERE a shot is; they do nothing for a chase, because every shot was an independent illustration with no idea where on the lane it happened. `Kuku_Ep10Sets.lanePosition(at, cartAt)` now derives, from the same metric table as the blueprint: how far down the 60 m lane the shot sits, how many of the three markers are behind that point and how many ahead, how far the end wall must read, and separately where the cart is at that moment. 27 chase shots carry positions; the cart's position increases monotonically, and scene 3 states that the cart is still ~30 m up the slope while लेडा works at the flat stone ahead of it — the suspense that was nowhere in the prompts before.

Also fixed: `regen_spine.sh` exists because a for-loop over a shell variable silently produced nothing when backgrounded, and each generation takes ~2 minutes so a 14-shot batch exceeds any foreground timeout. Batches go through the script, and progress is checked by file mtimes rather than the log (bash buffers stdout when not a tty).

### The ग is composited, never generated (2026-08-24)

Author, on seeing the forged letter come out as a different golden object in every frame: "we shouldn't even be bothering asking the AI to render this letter correctly." He was restating a law this handoff already carried and I had broken — Devanagari is never generated; glyphs are composited locally.

`Kuku_Ep10Shots` no longer describes the ग as a prop for the model. A shot that features it now emits the opposite instruction — THE FLAT STONE IS EMPTY, no shape, sculpture, hook, curve, letter or ornament anywhere near it — and records `ग COMPOSITED LOCALLY` in its derived notes. `ep10prod/ga_composite.mjs` builds the letter from the real glyph (Kohinoor Devanagari, five offset layers dark-to-bright for cut-paper thickness, warm gold), then composites it with a warm pool and a squashed contact shadow so it stands on the stone rather than floating. It is byte-identical in every shot by construction, and each pre-composite frame is kept as `RAW_<shot>.png` so placement can be re-tuned forever at zero cost.

KNOWN LIMIT, documented in the script: the letter composites ON TOP, so where the cart is baked into the frame the ग cannot sit BEHIND it. Those placements put the letter beside the cart — it reads as the cart having come to rest at the ग rather than being cradled in its curve. For the finished episode the frame should be generated with neither cart nor letter, and both composited in depth order.

The same rule governs गाय and कुकु's broken क: any Devanagari that must be legible is composited, never prompted. Shots referring to broken glyph-shards are safe because they ask for abstract black paper shards, not letters.

### Why the chase still jumped — and the fix (2026-08-24, later)

Author: "the position of the cart jumps from left lane to right lane, or from first sign to second, to third, back to first." Measured: **44 of 96 chase shots moved BACKWARDS up the lane.**

The cause was not the frames. Every frame carried a correct lane position — and the assembler ignored it completely, choosing each picture by who was speaking. Three further mistakes surfaced while fixing it, each worth remembering:

1. **I constrained the camera, not the cart.** The camera legitimately leaps ahead to the flat stone in scene 3 while the cart is still up the slope. The thing that must never reverse is the CART. The engine now publishes a *cart clock* per shot (`shot_positions.json`), not a camera position.
2. **My hand-assigned clocks overlapped.** Scene 3 ran 32–40 while scene 4 ran 34–39, so the cart genuinely had nowhere forward to go and the assembler fell back to the furthest-behind frame. The clock is now strictly increasing along story order and agrees with the physical markers (12/24/36 m).
3. **Frames were not scene-scoped.** A speaker's "subject frames" spanned the whole episode, so a scene-1 line could pull फ्यूरिया's scene-5 shot and pin the cart at the finish for seventeen consecutive shots. The engine now publishes `shot_beats.json`; the cut scopes every candidate to its scene, and when a speaker owns no shot in that scene it falls back to THE SCENE'S OWN frames — never outside. Letting the out-of-scene candidates through when the scoped list came up empty was the actual leak.

With scene scoping in place the cart clock is monotonic for free, because the scenes' ranges no longer overlap (Runaway 4–13, Braking 15–26, Flat/Forging 27–32.5, LastApproach 33–35, TheStop 36–55). Enforcing order WITHIN a scene as well was wrong and froze the cut on one picture for seventeen shots — intercutting between characters at the same moment is normal grammar. The assembler now asserts the boundary invariant on every build and prints the ranges.

Result: scene boundaries one-way, 0 out-of-scene frames, frames used 70 → 106 of 124.

**Empty carts:** h19 declared `cart bed not visible` when the bed is plainly in shot, so गौरी was never injected and the cart ran empty through the middle of the chase; h36 lost her to the model. Both fixed. When a cart frame looks empty, check the shot's `~cart` bed flag first — the injection law only fires when the bed is declared visible.
