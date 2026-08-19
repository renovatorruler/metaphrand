# Scene 8+ — the transformation system (designed with the author, 2026-08-19)

The standard machinery for ALL magic in the series, both children, every episode. Everything here was decided by the author on 2026-08-19; nothing is speculative.

---

## ФРОСЯ'S CARD — writing magic

The sequence, fixed:

1. **Shot A** — she writes; her face and arm; THE PAPER IS NOT VISIBLE. Per-scene shot.
2. **Shot B** — OTS onto the paper: her hand with the pencil hovering, the word ALREADY WRITTEN in her child hand. This is the standard plate.
3. She sounds it out — **letters light one by one** with her voice.
4. She says the whole word — **the whole word lights**.
5. **«Точка.»** — the hand comes down and places the dot. (Canon: this is Grandma's rule paying off — «напишешь имя, ПОСТАВИШЬ ТОЧКУ, и будет по-твоему», the line34_FINAL wording.)
6. **The dot lights and rises off the paper** — flash.
7. The object appears — the NEXT shot's business, usually a cut to the room with the object present (the f27→f28 pattern).

The card ends at the rising dot. What the dot becomes belongs to the scene. That is what makes one card serve every summoning.

## THE COMPOSABLE ALPHABET — validated 2026-08-19

**The author builds the alphabet in an external image LLM. Do not build letters, do not run compositing experiments on letter LOOKS — she owns the look.** The pipeline owns placement, timing and assembly.

The contract, proven by test (her С over her paper plate — composites in `/tmp` that session, method below):

- Letters arrive as **transparent PNGs (RGBA, straight alpha, exported against transparency)** — her С measured: alpha 0-254, 63% fully transparent, graduated glow falloff, zero fringing.
- Each letter: **regular state + magic (lit) state, same canvas, same position** — so the swap cannot jitter.
- The hand+pencil is **its own PNG layer with baked shadow**, composited ABOVE the letters. Separate PNGs per hand position (hover / tap), each with its own shadow.
- Paper plate: `kuku_flow/frames/s8_writing/PLATE-PAPER-BLANK_v1.png` (1672×941). Letter С: `LETTER-S_v1.png`. The СОК mockups (drafts of the look): `OTS-PAPER-SOK_draft_v1.png`, `_v2.png`, `_glow-C_v3.png`.
- Working scale from the test: letter body ≈ **34% of paper height** at first-letter position — leaves room for 6-letter words (МАШЫНА). Lock this when she confirms.
- Compositing: PIL `alpha_composite` for normal layers; screen/additive available per layer if a lit letter reads dim over the bright paper. The glow's semi-transparent haze picking up paper texture is what makes it read as light ON the paper — do not flatten it.

The lit С is PURE GOLD LIGHT with no graphite core — so unlit→lit reads as "the writing became light". If the author ever wants "the graphite ignites" instead, the lit PNG needs a faint dark core; her call, flagged, not decided.

## ВАСЯ'S CARD — reading magic

1. **INTRO** (generate ONCE, reusable forever): transformation space (dark void, gold sparks), Вася standing, arms raised, serious face, ribbons BEGIN to circle. Recipe: seedance mini, ~5s, **start image `C-VAS-TRANSFORM-PRE_author.png` → end image `C-VAS-TRANSFORM-CHARGED_author.png`**, ~13 credits, through the gate. NOT YET GENERATED.
2. **DISSOLVE** (reuse forever): cut from the author's own 8s cat animation — `magic/transform_vasya_cat_AUTHOR.mp4` (job 70259916, 11 Aug, found via share link → thumbnail URL → job id → `generate get`). The middle segment where the boy becomes pure light. NOT YET EXTRACTED.
3. **REVEAL** (per target): from pure-light frame to the target-with-word. кот = the back half of the same animation. оса and мама have REVEAL cards (`REVEAL-OSA_author.png`, `REVEAL-MAMA_author.png`). New targets: flash-cut to card (free) or a 3-4s mini (≈10 cr).

## ВАСЯ'S CHIPS

Letter chips fall on the floor OF THE TRANSFORMATION SPACE (no real-world floor to match — deliberate). Standard: an alphabet of chips, **regular state + magic state** per letter — the author is building these in her external tool alongside Фрося's letters. Placement, the drop, the settle-shake, and light-up on his voice are compositing — **no Higgsfield for chip animation** (author's explicit instruction).

## VOICE-DRIVEN LIGHTING — the shared rig

The utterance-window machinery (built for the А-О-М-С-К-Т-Л-Б shot): detect each utterance in the recording, swap regular→lit on its window. Works for chips, letters, anything two-state. `speech_windows.sh` measures; the splitter cuts per-letter audio (`vas_L1_A.mp3` pattern).

---

## STATE OF SCENE 8 OTHERWISE

- Full stills coverage exists — see the frames inventory in the handoff (f24–f38 cover СОК/САЛАТ/МАК/МАМА beats; f35/f36 cat+tank; f37 wasp chase; f38 wasp flips the table; f30/f30_blank Вася-Мама beside real Мама).
- Word cards (gold on black): `kuku_flow/words/*.png` — incl. МАШЫНА with the boxes for missing letters (the failure state; belongs to the machine plot later).
- Nothing staged, nothing generated, envelope not set. The author is producing the alphabet first.

## WHAT WAITS ON WHOM

- **Author**: the composable alphabet (Фрося letters + Вася chips, two states each, transparent PNGs); finalized OTS paper look; Мама voice pick (21/22/23/24); the go for the Вася INTRO generation.
- **Pipeline**: on alphabet arrival — registration QA (auto-diff states for drift), СОК end-to-end proof cut to her real voice; the INTRO job when she says go; dissolve extraction from the cat animation (free, can happen any time).
