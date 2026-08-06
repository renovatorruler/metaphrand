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

## МАМА — LOCKED FINAL (2026-08-06): `charsheets/mama_v7_match.png` (v6 + apron match enlarged to real-object scale at author's direction)
Head-law compliant (head = family band, verified on the true-scale chart v9). Produced by the
now-canonical proportion pipeline: **author pixels → arithmetic (deterministic +27% head
enlargement of the approved mock) → scale-chart proof → surface-only edit to heal seams →
chart re-proof.** Generation was never allowed to touch proportions or identity. Design:
golden-blonde side braid, red-gold candy-wrapper kerchief, green-hazel eyes, mustard blouse,
cream whip-stitched apron with blank-tile pocket, russet skirt, barefoot. LAW LESSONS BANKED:
(1) an edit CANNOT move structure — use arithmetic for structure, edits only for surfaces;
(2) a reference teaches everything visible INCLUDING its flaws — never hand a flawed mock to
a regeneration; (3) verify proportions on the true-scale chart (background-remover cutouts,
feet on one line, 1.4in head bands) before locking anything.

## ПАПА — LOCKED FINAL (2026-08-06): `charsheets/papa_v6_fuzz2.png`
Derived from Вася (bushy winged brows, button nose, warm eyes carried through). Bear expressed
per the family construction amendment: **bulk lives in torso silhouette and fur texture, NEVER
in limbs** — thin spindly arms with dark fuzz, round belly under wide suspenders, very dark
shaggy hair, dense dark beard as a RUFF hugging the round dome (the beard never stretches the
skull). Face aged the Мама way — smaller calmer settled eyes, zero wrinkles, late twenties.
Visible head unit sized to the family band (author-approved 0.82× shrink of the first bear
build). Costume: slate-blue work shirt, fabric suspenders, brown canvas trousers with one
patch, barefoot. **KEY CANON (author, 2026-08-06): the key stays SMALL (~1 inch — a human
mailbox/clock/music-box key, a real found object), worn at the hip on the twine strap as the
хозяин's badge and his all-purpose tool. The Codex registry's 5.25in giant key is REJECTED
(author: real keys are ~3in max, and a body-length prop is an animation liability). Open story
option: it's the key that winds the giants' clock — Papa's evening ritual = the tick that opens
Scene 1.** Failed giant-key edits archived in ep1prod/build/. Forearm fuzz restored at the ORIGINAL v3 density by attaching v3's arms as the calibration reference — density/amount survives in pictures, not adjectives (the word 'fuzzy' produced fur sleeves). 

## БАБА ЯГА — LOCKED FINAL (2026-08-06): `charsheets/baba_v9_gold.png` (author-approved on the v2 chart)
Derived from Мама's sheet (option D staff pose), then family-fitted: **+30% head** (deterministic
chin-anchored enlarge, approved on-chart before any styling), hunched at **3.6in registry height**
— taller than Фрося, shorter than Мама. Aging stays in the family language: eyes/posture/hair,
max 2–3 facet creases, no wrinkle vocabulary. Canon marks: **light GREEN-HAZEL sly hooded eyes**
(author reverted the dark-eye experiment — the pale iris against the lid shadow is what reads
"хитрая"; also quietly makes her Мама's мама), **two little teeth — white one hanging OVER the
lip (full 3D volume), GOLD one inside the mouth shadow** (deterministic recolor preserving facet
shading; the gleam moment is an ANIMATION beat — 2–3 frame star sparkle + PSE ding when she
grins, not baked into the sheet), **мухомор kerchief** — deep red, solid white dots that DIM with
the fabric shading (dots in shadow ~55% white), knot tails fully red, **birch БЕРЁЗКА broom**
leaned on as her staff, bristles UP, bare handle planted; **no shawl pin/hook** (removed —
babies will ride her shoulders; nothing sharp lives there). Barefoot indoors is canon — her
ЛАПТИ (birch-bast shoes) are an OUTDOOR/arrival costume layer + doorway gag, not yet designed.
White-teeth variant kept at `charsheets/baba_v9_white.png`. Build lesson banked: after multiple
failed mask-composite passes, the final sheet IS the nano recolor output taken WHOLESALE (it had
preserved eyes/mouth/broom/hook-removal pixel-perfectly) with only dot-shading + gold applied on
top — when a surface edit is clean, taking it whole beats carving it up. Prop library ideas
approved-in-principle, NOT on the sheet: ступа+пестик (her vehicle), herb/mushroom garland,
belt pouches, broom-perching crow.

## БАБА ЯГА — HUMAN FORM, LOCKED (2026-08-06): `charsheets/baba_human_lapti.png`
(`baba_human_lowpoly.png` is the same sheet pre-лапти, kept as source.) **She wears ЛАПТИ in
the human/flight form** — woven tan bast slippers, cords cross-laced over gray ОНУЧИ wraps —
and is BAREFOOT only in the домовой form: the shrink-at-the-door beat includes stepping out of
her лапти (they stay by the door, human-sized). Cutout: `ep1prod/build/cutouts/baba_human_cut.png`
(remover only — a DIY corner-color alpha ate her foot and dragged a bg patch; the beige-on-beige
lesson applies to EVERY cutout, no exceptions).
Her sky-flight form: TRUE HUMAN PROPORTIONS (~6 heads hunched, wiry village-бабушка build) for
scenes at people-scale — she flies in at human size, then shrinks through the ДЫМОХОД into the
3.6in домовой form. Same identity marks as the small form: мухомор kerchief, green patched
shawl, patched plum/mauve/olive skirt, white wisps, sly hooded green-hazel eyes, round button
nose, TWO teeth — **GOLD tooth on HER RIGHT (viewer-left), tucked inside the mouth; WHITE tooth
on her left (viewer-right), hanging over the lip** — tooth sides are canon, spell them out in
every prompt. One prop only: the tied birch besom, bristles up. Pair reference:
`charsheets/BABA_TRANSFORMATION_PAIR.jpg` — **TRUE SCALE** (author law: never show the two forms
same-size): human form ~147 см (proposed canon, author may adjust) vs 3.6in/9 см = **≈1:16
after the дымоход**; the sheet carries a zoom inset for the small form. Build lessons banked: (1) attaching the small-form
sheet as reference FORCES its proportions — proportion changes must be TEXT-ONLY prompts with
the head ratio stated numerically; (2) the model prints caption text at the bottom despite
negatives — crop deterministically (this sheet is the cropped `baba_human_g_clean`).
**PRESENTATION RITUAL (author, 2026-08-06): stamp the option LETTER on every option image** —
the author reviews images, not filenames.

## СТУПА + ПОМЕЛО — LOCKED (2026-08-06): `charsheets/baba_stupa_flight.png` (flight canon)
Яга flies IN THE СТУПА at human scale: a carved wooden mortar (folk rosette band), tilted
mid-air with a wind swirl beneath, her legs hidden below the rim. Tool grammar, canonical:
the tied birch BESOM stays in her hand (bristles up), and the ПОМЕЛО — long pole with a
SHAGGY RAG head, visually distinct from the besom — trails out of the ступа behind her
(помелом след заметает). Neutral prop reference for the vessel itself (grounded goblet
silhouette, full base visible): `charsheets/stupa_prop_ref.png`. Compositing cutout:
`ep1prod/build/cutouts/baba_stupa_flight_cut.png`.

## FAMILY SCALE AUTHORITY v2: `charsheets/FAMILY_SCALE_AUTHORITY_v2.jpg` (all five locked sheets)
Supersedes v1. Registry heights (В 3.15 / Ф 3.5 / **Яга 3.6 hunched** / М 3.9 / П 4.5in), heads
all ≈ one 1.4in family band, **heels on the ground line** (align by heel contact — the toe tip
sits ~2% of body height lower in these ¾ renders; never align by lowest pixel). Cutouts via
`image_background_remover` (own color-heuristic masks fail on beige-on-beige — banked lesson).
Яга's crown is measured in head columns only (left 62% of her bbox) — the upright broom must
never count as her height (same per-character crown-override lesson as the staff mock).

## МАМА v3 — superseded design pass (2026-08-06): `charsheets/mama_v3_final.png`
Derived from Фрося (candidate A face), then made DISTINCT by author direction:
**golden-blonde thick SIDE BRAID + the red-gold candy-wrapper kerchief over it; GREEN-HAZEL
eyes; mustard blouse, cream whip-stitched apron with the blank-tile pocket, plain russet skirt
with one patch; barefoot.** No florals, no pinks/teals — zero overlap with Фрося's palette.
Face = candidate A unchanged (reads under 40). `mama_lowpoly_v1.png` (dumpling) is RETIRED —
it appears in shot «Я САМ» Scenes 2–3; reshoot decision pending. STILL OPEN on v3: the family
head-law proportion pass (head same absolute size as the kids, body ≈3 head-heights) — the
sheet inherits A's proportions and needs that check before heavy scene use.

## МАМА REDESIGN — history (2026-08-02…04)

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
