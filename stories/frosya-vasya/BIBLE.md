# «ФРОСЯ И ВАСЯ» — production bible

Russian alphabet series. Sibling show to Kuku (Hindi). Same production discipline,
different art direction. Author/owner: the Russian-speaking parent.

## THE LAWS (copied from the Kuku pipeline — they are load-bearing)

1. **Location anchors on every shot in a set.** Generate the empty set as a wide plate
   FIRST, then attach that plate to every subsequent shot in that location and say
   "THE SAME <place> from the place reference". This is what keeps backgrounds identical.
2. **Style key attached to every generation** — charsheets, stills and clips alike.
3. **One canonical PNG per character**, reused forever. Never regenerate a character per shot.
4. **Full negative block on every prompt.** No exceptions.
5. **Letterless plates.** Cyrillic titles/letters are composited afterwards, never generated.
6. **True scale language.** They are matchbox-sized; giant household objects establish it.
7. **Idempotent scripts.** Skip if the file exists; retry 3× on failure.

## CHARACTERS

Canonical refs in `charsheets/` (one PNG per character, plus turnarounds/expressions
for reference and `small_*.jpg` for light uploads).

**ВАСЯ** — younger brother (~5). Oversized round head, **thin spindly arms and legs**,
small slender body. Short spiky brown hair, **big BUSHY eyebrows** (permanent signature —
they tilt but never thin out), big dark round **button nose**, freckles, rosy cheeks,
gap-tooth grin. Boyish patchwork outfit (dinosaurs, cars, stars, stripes, lightning),
a thick **giant-shoelace belt** with a chunky aglet, an **«А Б В» Cyrillic chest pocket**,
twice-rolled trouser cuffs. **Barefoot.**

**ФРОСЯ** — older sister (~7), **slightly taller** (about half a head; heads the same size).
Long soft **wavy** dark-brown hair with a whittled **pencil-stub** and a little orange
flower in it. Same button nose, freckles. Smile shows a full set with **one missing bottom
tooth**. Floral patchwork dress, a pouch fastened by a **large safety pin** (the pin is the
clasp — it has a job). **Barefoot.** Signature: sticks her **tongue out when concentrating**,
especially while air-writing.

### Never say in prompts
"boy", "child" (summons a realistic-kid prior), "gnome"/"elf" (gives pointed ears),
"stocky", "stubby limbs".
### Always say
**"ДОМОВОЙ (domovoy) — a small Slavic folklore HOUSE SPIRIT creature"** — tested against
"gnome-elf" and "brownie/hob"; домовой won (no elf ears, no aging) and is the true word.

### PROPORTIONS MUST BE NUMERIC
Adjectives lose to the model's human prior. State it as measurement:
> *"his whole standing body is TWO AND A HALF of his own head-heights tall; his head is as
> big as his entire torso — enormous, round and dominant; arms and legs are THIN STICKS."*
Calibration from testing: "TWO head-heights" → head far too big; softening the wording to
"leaves room for a torso" → drifts back to boy proportions. 2.5 + "head = torso" is the target.

### EYES — LOAD-BEARING FOR THE OPENING
The title sequence depends on **eyes opening in the dark**, so eyes must be visible against
black. Solid dark eyes fail. Spec: *round eyes, warm BROWN IRIS filling most of the eye, only
a NARROW crescent of white sclera, plus a small bright catchlight.* Too much white reads
anime/boyish; none reads invisible.

### THE DARK BUTTON NOSE IS LOAD-BEARING — KEEP IT
A/B tested (`charsheets/nose_compare.jpg`): with a **dark** button nose he reads as a
NON-HUMAN house spirit; with a **skin-toned** nose he instantly becomes a generic little boy.
It is the strongest single cue separating them from human children, and the shared family
trait linking Вася and Фрося. Always state it. In 3D styles make it a **very deep warm brown**
(not pure black) and keep it **small and flat against the face** — pure black + protruding
reads as an animal snout. In 2D painted art keep it as-is.

### SCALE PROPS NEED A SIZE COMPARISON
Naming the object isn't enough — state it relative to his body: *"an ordinary human boot
shoelace is ENORMOUS to him — as thick as his own arm, with an aglet the size of his hand."*
Otherwise it renders at normal accessory scale and the scale gag dies.

## LOW-POLY LINE — LOCKED (2026-07-30)

Characters re-derived natively inside the Higgsfield **Low Poly** preset, Kuku-style
(text description + style key, no painted reference), because translating the painted art
into a style never held. Canonical files in `charsheets/`:

| File | What it is |
|---|---|
| `vasya_lowpoly.png` | **Вася — canonical.** Validated across 3 expressions × 3 lighting setups (`x1_furious`, `x2_terrified`, `x3_delighted`). |
| `frosya_lowpoly_v2.png` | **Фрося — canonical.** |
| `duo_reference.png` | **HEIGHT AUTHORITY.** Both staged together, feet on one line; Фрося measures **8.1% taller** (~half a head). Attach this to any shot with both of them. |

**Why a duo reference exists:** height is *relative*, so a solo sheet cannot encode it, and
in-place edits refuse to change proportions (an attempt to lengthen her legs produced a
1.000 height ratio — no change). Treat the pair relationship as its own anchor, exactly like
a location plate.

**Measure, don't eyeball.** Verify height by scaling both to a matched **FACE height**
(skin-region measurement) — a head/neck-width measurement breaks on Фрося because her long
hair defeats the narrowest-row logic.

### BROW SHAPE vs BROW TILT ARE SEPARATE PARAMETERS
Вася's **thick winged brows with the pointed outer flick** are permanent design; only their
**angle** carries emotion. Asking for a "friendly" brow without saying "keep them thick"
turns them into thin arcs and the signature vanishes. Phrase it as: *"keep the brows exactly
as thick and winged; ONLY rotate them so the inner ends lift."* Фрося's brows are the same
family but finer and softer.

### RELATIONAL FACTS NEED PICTURES, NOT WORDS
Scale, contact, and pose relationships between characters/props CANNOT be reliably prompted in
text — 10+ attempts failed. They transfer only from a REFERENCE IMAGE where the relationship is
visible. Locked relational refs in `ep1prod/plates/`: **`ref_haul_LOCKED_FINAL.png`** (the canonical
sock carry: heights, shared load, direction, strain, AND the natural slack lace tail with its
rounded nugget aglet — evolved across ~12 iterations, finished by the parent iterating our shot
in another AI; provenance doesn't matter, correctness does). A pose reference transfers its
ANATOMY along with its staging — converting a chunky-figure reference gave our kids thick limbs;
always restate "thin spindly arms and legs" when converting an external pose. Workflow: find
or make a picture of the desired relationship → convert to our characters/style → lock → attach
to every shot using it. A reference must be correct in EVERYTHING visible (a scale sheet missing
the props taught prop-less characters; a facing-camera pose sheet taught facing camera).

### THE PRODUCTION RECIPE (settled 2026-07-31, Scenes 1–2 shipped with it)
The edit defines the asset list; generation serves the edit. Per ~25s scene:
**1–2 motion clips** (the thing that must move) **+ ~5 face stills** (dialogue → fal.ai lip-sync
downstream, mouths gently closed) **+ fitted ElevenLabs reads** (generate audio FIRST, measure,
size the slots) **+ Sonilo music bed + local SFX** (ffmpeg-synthesized placeholders). ≈75–90
credits/scene. Assemble on one timeline with audio at absolute times; final encode ALWAYS
`libx264 -profile:v high -pix_fmt yuv420p -movflags +faststart` (plain `-c copy` concat does not
play on mobile clients). Мама's voice = Anna Zub PLACEHOLDER, recast pending.

### SFX COME FROM PRO SOUND EFFECTS, NOT SYNTHESIS
Synthesized foley failed audibly: the Scene-2 "chip tap" was a 50 ms 1390 Hz sine and read as an
electronic BEEP over Мама laying tiles. Never ship a tone as an impact. Use the PSE fetcher —
`studio/src/PseFetch.res` in the rosca-pitch worktree, full guide in `studio/PSE_FETCH_HANDOFF.md`.
`pullPath` is hardcoded: point it at `ep1prod/PSE_PULL_LIST.md`, `npx rescript build`, run
`STAR=1 TAKES=2 node src/PseFetch.res.mjs`, then PUT IT BACK to the Kuku list and rebuild —
that fetcher is shared with the Hindi show. Files land in `~/SFX/PSE/`; only CORE-owned libraries
download, so put the distinctive word FIRST in a query.
Our foley in `ep1prod/sfx/pse/`: `tuk1–4.wav` (four single impacts sliced out of a domino-topple
take — vary them across repeats so taps don't sound machine-stamped), `hearth.wav` (ember bed,
replaces synthesized roomtone), `fray.wav` (paper crinkle). Bed levels: music 0.22, hearth 0.30,
taps 0.85.

### LIP-SYNC ONLY AFTER THE CUT IS APPROVED (parent's rule, 2026-07-31)
Assemble and deliver the PRE-lip-sync cut (stills with Ken Burns in the dialogue slots) first.
Run the fal.ai pass only after the parent approves that cut. Order per scene: cut list approval →
generate assets → QC → assemble stills cut → PARENT APPROVAL → lip-sync → final assembly.

### FAL.AI LIP-SYNC PASS (proven on Scene 2)
Model: **`fal-ai/bytedance/omnihuman/v1.5`** (slashes, NOT `omnihuman-v1-5` — the queue silently
accepts a bad subpath and "completes" with a path error). Input: the approved dialogue still +
the fitted ElevenLabs line → talking clip of ~line length whose FIRST FRAME equals the still.
It holds the low-poly style, brows, noses and even a baby on the shoulder perfectly.
Gotchas: uploads over ~5 MB fail at worker-fetch time (`file_download_error`) — send JPEG q92,
and HEAD-check the CDN URL before submitting; drive the REST queue with **curl**, not urllib
(urllib got 404s on the same URLs). Key: `FAL_AI` in metaphrand/.env.
Assembly: replace each still's slot with freeze-first-frame (until the line's start offset) →
clip → freeze-last-frame via `tpad=start_mode=clone:stop_mode=clone`; keep the ElevenLabs mix
untouched — the clip is synced to the same audio file, so absolute times line up.

### READ STDERR BEFORE BLAMING THE FILTER
A whole batch of "nsfw blocks" turned out to be `not_enough_credits` — the CLI error surfaces
only on stderr and looks identical to a filter block from the JSON-parse side. Full-character
clips (mama + babies, Вася solo) passed FIRST TRY once credits were restored. The filter is real
but rarer than it looked; always print the raw error before switching strategies.

### THE SAFETY FILTER FIRES RANDOMLY ON THE KIDS
nano_banana_pro intermittently returns `Error: NSFW content detected` on entirely innocent
prompts involving the (barefoot child) characters — including edits of its own output. It is
inconsistent: the same inputs can pass then fail. Don't fight it: rephrase around body words,
drop character sheets from attachments when they're not needed, or make the change
programmatically (the aglet on the carry ref was drawn in PIL after 3 blocks).

### EDIT vs REGENERATE
**Edit** to change a detail — it reliably preserves everything else (proven repeatedly).
**Regenerate** only for a new design; every regeneration re-rolls the whole image (fixing two
details cost sleeves, head size and render style in one test). Edits cannot make structural
proportion changes — use a fresh generation or a staging rule for those.

### KNOWN DRIFT IN SCENES (accepted)
Silhouette, personality, proportions and emotion hold well. Hair tone (drifts blond under warm
rim-light), exact patch layout, and nose darkness drift shot to shot. Mitigate by naming
"consistent medium brown hair, no blond" as an anchor in every prompt. Parent has accepted
this level.

## МАМА REDESIGN — IN PROGRESS (2026-08-02…04, awaiting parent go)

The approved-and-shot Мама (`charsheets/mama_lowpoly_v1.png`, the round dumpling) reads as
"an adult woman", not as the kids' species — parent wants her REDERIVED FROM ФРОСЯ:
same creature, aged. Findings so far:

- **Derivation works for the FACE**: generating "her mother, the same creature aged 30 years"
  with Фрося's sheet attached carries the exact face geometry (nose/eyes/brows). Candidates
  `mama_v2_a/b/c.png`; parent picked **A** as the base face.
- **Structural edits DO NOT take** (re-proven): the 9-point iteration on A (head +10%, shorter
  neck, narrower shoulders, rounder cheeks, bigger ears) changed ONLY the face in both an edit
  (`mama_v2_a_edit.png`) and a reference-heavy regen (`mama_v2_a_regen.png`). Bodies came back
  near-copies. Structure needs numeric proportions in a FRESH generation, not percentages, not
  edits.
- **Aging vocabulary overshoots**: "laugh-lines / silver strands / tired eyelids" produced 50+.
  Target is ≤40. State the age as a target and FORBID the symptoms ("about forty, face still
  smooth and fresh, NO wrinkles, NO grey hair").

### THE FAMILY HEAD LAW (agreed with parent, pending visual proof)
**Every домовой in the family has the SAME absolute head size; age changes only the body.**
Kids stand 2.5 of their own head-heights; **Мама stands ~3** (parent's +30% head instinct —
the math agrees: it puts her at ~2.9 vs candidate A's human-ish ~3.7). Plus: near-invisible
neck, narrow sloping shoulders, round full cheeks, fuller middle. Papa later gets the same
head. One-line check for every future sheet: adult = LONGER BODY, never a smaller head.

Next step (needs explicit go): 2–3 fresh derivations from Фрося's sheet with the numeric
formulation. After lock: regenerate canonical with Руся+Муся riding, then reshoot Мама's
shots in Scenes 2–3 (~4 lip-synced stills + 2 clips ≈ 100 credits + fal passes).

## STYLE — DECISION PENDING

Two forks, both viable:
- **A. Hand-painted storybook** (current locked art). Warm saturated gouache, visible
  brush texture, bold caricature. Beautiful, but it is a *specific hand* — reproducing it
  is the "novel style transfer" problem and needs per-shot curation.
- **B. Re-derive natively inside a Higgsfield style preset** (Low Poly looked strongest;
  Paper Diorama would rhyme with Kuku). Characters are *born in the style* from a text
  description + style key, exactly as Kuku's were — consistency then comes nearly free.

Set `STYLE=` in the scripts once decided.

## WORLD

Домовые — house spirits living under the floor of an ordinary human house.
Matchbox-sized. Everything they own is a real household object at giant scale
(thread spool, button, thimble, safety pin, shoelace). Warm practical light only;
deep cool shadow; cozy-mystery, never horror.

## AUDIO

ElevenLabs `eleven_v3` with expression tags, native-Russian cast:
Narrator **Anna Zub** `deqzqEZ3ngCdcOl0jF1F` · **Вася = Leonid** `bg9LrEYQkRYwqkxA8VOy`
· **Фрося = Ekaterina** `GN4wbsbejSnGSa1AzjH5`. Songs: Suno.
Ремарки → v3 tags. Perform the actual screenplay dialogue; never narrate over it.

## EPISODES

- **Opening titles** — 35-panel storyboard done. Introduces the HOUSE, not the characters:
  no faces, only eyes in the dark; title emerges from the floorboard light.
- **EP1 «Я САМ»** — screenplay complete. Magic words САМ / СОМ / КОТ.

### EP1 PRODUCTION STATUS (2026-08-04)
| Scene | State | Deliverable (ep1prod/, media unversioned) |
|---|---|---|
| 1 подпол, sock haul | **DONE** | `SCENE1_FINAL20_mobile.mp4` (20s) |
| 2 за печкой, letter game | **DONE**, lip-synced | `SCENE2_FINAL.mp4` (stills) / `SCENE2_LIPSYNC.mp4` (27.5s) |
| 3 там же, «Я — сам?» | **DONE**, lip-synced | `SCENE3_LIPSYNC.mp4` (52.8s), cut list in `SCENE3_CUTLIST.md` |
| 1–3 combined | delivered | `EP1_SCENES_1-3.mp4` (1:40) |
| 4 погреб | next | needs new set plate (cold stone, first non-hearth light) + кувшин prop |

Scene-3 audio: 7 lines recorded (`audio/s3_*.mp3`); Фрося's grumble plays over the closing
clip unsynced (she's small in frame — no fal pass needed for far shots).
SFX all from PSE now (`sfx/pse/`): tuk1–4 domino taps, hearth beds, unroll/fray crinkles.
Мама's voice is still the Anna Zub PLACEHOLDER; real casting pending.
Scenes 2–3 will need Мама reshoots once the redesign locks (see МАМА REDESIGN above).
