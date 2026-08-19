# EP1 «День рождения» — state of play, 2026-08-19

Written as a handoff. Someone who has never seen this project should be able to read this document and carry on without asking the author to repeat herself. Everything asserted here was checked against the filesystem or the account on 2026-08-19; where something is unknown it says so.

**The author is the sole creative authority.** She is making this for her own children. She reviews on a phone, she cannot read prose staging quickly, and she has repeatedly and correctly caught claims made without checking. **Check before you assert. Twice in this session I told her a reference did not exist when it did, and the second time cost a 32.5-credit reshoot in the wrong direction.**

---

# 1. WHERE THE EPISODE STANDS

**Scenes 1 through 7 are cut, dubbed and assembled: 6 minutes 37 seconds.**

`production/kuku_flow/2026-08-19_0500_EP1_den-rozhdeniya_SCENES1-7_v1.mp4`
(plus `_small.mp4`, 854px, ~20 MB — send the small one, the full one will not reach her)

| scene | source | length | state |
|---|---|---|---|
| 1–4b | `2026-08-16_EP1_scene1-4b_ASSEMBLY_v5.mp4` | 3:33 | shot before the current gates; expect older staging defects |
| 5 pt 1 | `2026-08-18_EP1_s5job2_v2_RUdub_v4_sfx.mp4` | 0:20 | dubbed, SFX |
| 5 pt 2 | `2026-08-18_EP1_s5job3_RUdub_v1.mp4` | 0:16 | **dubbed 2026-08-18** — was shot and forgotten for a day |
| 6 | `2026-08-18_1900_EP1_SCENE6_pencil-rule-secret_v4.mp4` | 1:06 | **accepted by the author** |
| 7 | `2026-08-19_0400_EP1_SCENE7_chest-and-letters_v6.mp4` | 1:22 | **accepted by the author** |

**Scene 8 is next. Nothing is staged or generated, BY DESIGN: the author is building the composable alphabet first in an external image tool.** The full transformation system — both children's magic cards, the alphabet contract, what waits on whom — is in `2026-08-19_SCENE8_TRANSFORMATION_SYSTEM.md`. Read it before touching scene 8.

## Money

- Account: **2977.62 credits** (Higgsfield, ultra plan). ~$0.043/credit.
- Scene 6 cost **285.5** credits (253 accepted + 32.5 one rejected take).
- Scene 7 cost **217.5** credits, all seven jobs first-take-usable.
- `/Users/dusty/dev/metaphrand/.hfgate/allowance.json` holds **82.5** — this is a SELF-IMPOSED per-scene envelope, NOT the account balance. Do not confuse the two in front of the author; it reads as if her money vanished.
- Ledger of every generation: `/Users/dusty/dev/metaphrand/.hfgate/ledger.jsonl`

## THE LEDGER RULE (2026-08-19, author's instruction — scope set by her)

**ALL VIDEO WORK IS LOGGED, no exceptions.** The gate's `submit` is the only path that spends video credits, and it writes the ledger line before the money moves. If a video generation ever has to happen outside the gate (an emergency, a UI experiment meant for this show), it gets a `spend` line immediately: `node src/Drakosha_GateSubmit.res.mjs spend video <cost> <job-id> [note]`. A video without a ledger line is a bug.

**Images are explicitly OUT of scope for now.** The author generates most stills herself, outside this project's pipeline, and does not want that logged. **If she starts generating images through Higgsfield for this project, an image ledger wrapper gets built at that point** — same shape as the video wall. Do not nag her about unlogged images; do not attribute her UI image work to this project unless she says so.

Why the rule exists: on 2026-08-19 the cost question took an evening of transaction archaeology, produced a number she could not verify, and misfiled 990 credits of another project's work into this one.

- Ledger lines carry `project: drakosha-ep1`, so multiple projects share one account without the archaeology recurring.
- The submit retry **verifies against the server before resubmitting** after a network error — a "no response" failure on 2026-08-18 had actually submitted, and the blind retry double-charged 32.5 credits.

---

# 2. WHERE EVERYTHING LIVES

Root: `/Users/dusty/dev/metaphrand/stories/drakosha/`

| what | where |
|---|---|
| shooting script (the source of truth for dialogue) | `2026-08-04_EP1_den-rozhdeniya_SHOOTING_numbered_bilingual.md` |
| character/prop/set reference images | `ep1prod/scene1/references/` |
| generated clips, raw | `production/seedance_batch/output/` (31 mp4) |
| emitted prompts + args for review | `production/seedance_batch/emitted/` |
| per-job choreography (the prompts' source) | `production/seedance_batch/creative/*.creative.txt` |
| dubbed clips + assemblies (217 mp4, 2.4 GB) | `production/kuku_flow/` |
| all recorded Russian lines (235 mp3) | `production/kuku_flow/audio/` |
| line durations + transcripts | `production/kuku_flow/audio/LINE_INDEX.json` |
| the author's letter frames for scene 7 | `production/kuku_flow/frames/s7_letters/1-A.png … 8-B.png` |
| pre-made magic clips | `production/kuku_flow/magic/`, `production/kuku_flow/spell/` |
| word graphics | `production/kuku_flow/words/` (sok, salat, mak, mama, mashina, kot, bak, osa, motok, samokat, vzhukh, letters) |

Typed job records and gates: `/Users/dusty/dev/metaphrand/studio/src/`
- `Drakosha_SeedanceBatch.res` — the registry: cast tokens, prop tokens, tag lines, scale lines, prompt emitter
- `Drakosha_SeedanceJobs.res` — job records (`all` = live queue, `retired`/`retiredBatch` = shot)
- `Drakosha_SeedanceDryRun.res` — every gate; run with `node src/Drakosha_SeedanceDryRun.res.mjs`
- `Drakosha_GateSubmit.res` — the only thing that spends credits

Build: `cd studio && npx rescript build`. **ReScript only — no Python in the project tree** (scratch scripts in `/tmp` are fine).

---

# 3. HOW A SCENE GETS MADE

1. **Stage it** — decide geography once for the whole scene, then write one `.creative.txt` per job.
2. **Add the job record** to `Drakosha_SeedanceJobs.res` with cast, props, duration and model.
3. **Run the dry run** until green. It emits the real prompts to `emitted/` for reading.
4. **Read the emitted prompt**, not the creative file. The registry prepends reference lines and scale, and defects hide in what gets prepended.
5. **Submit** — `HFGATE_HOME=/Users/dusty/dev/metaphrand/.hfgate node src/Drakosha_GateSubmit.res.mjs submit s7jobA s7jobB …`
6. **Review every clip** by pulling frames before accepting. Never accept unseen.
7. **Dub** with `production/kuku_flow/dub_clip.sh`.
8. **Assemble**, re-encode each piece to a common format first, then concat.
9. **Retire** accepted jobs out of `all` into `retired` so their pre-gate creatives cannot hold the dry run red forever.

## The models

Set per job. Mini is the default and 2.5 must be argued for.

| model | cost | max duration | max image refs |
|---|---|---|---|
| `seedance_2_0_mini` | 2.5 cr/s | **15s** | 9 |
| `seedance_2_0` | 4.5 cr/s | 15s | 9 |
| `seedance_2_5` | 6.5 cr/s | 30s | 30 |

`--mode omni_reference` exists **only on 2.5**; passing it to mini fails the whole call. The cost probe must never pass it either (it sends no media and 2.5 rejects that).

Mini's 15-second ceiling usually SAVES money: it forces a long speech into two short jobs (60 credits) rather than one long 2.5 job (143).

---

# 4. THE LAWS (all learned the expensive way)

## LAW 1 — Only shoot what moves the story
`production/STAGING_MATRIX_DOCTRINE.md`. Lift a shot out; if the story survives, it should not have been generated. No transit, no establishing-for-its-own-sake, no confirmation, no logistics.

## LAW 2 — Specify everything you do shoot
Same document. Every character in frame needs POSITION, HANDS, EYELINE and FACE. **An unwritten cell is not empty — it gets filled from the reference sheet or from the last instruction about that person.**

## LAW 3 — Every character owns a wall
`production/SCENE_GEOGRAPHY_LAW.md`. Geography is decided ONCE per scene, not per shot. "Soft and out of focus" is not a background. Also: a top-down shot must contain something that identifies the surface (a knee, the mat, the chest) or it reads as a table instead of a floor.

## THE ONE THAT MATTERS MOST — a picture beats a word
A reference sheet outranks any prohibition. «NO broom» produced a broom. «no pencil» produced confusion. «flat and unimpressed» produced a warm smile because her sheet smiles. **What displaces a sheet is a competing instruction of the same kind**: say what the hands ARE doing, say what the mouth and brows DO. Never say what is absent.

Corollary, paid for: some sheet content is the character as drawn, not a prop the model added. Мама carries a matchstick in every single take through explicit exclusion. Accept those.

## Where the model cannot be trusted at all: WRITING
Every shot containing letter tiles came back wrong — wrong glyphs, duplicated tiles, Cyrillic Б rendered as the digit 6, whole rows of nonsense. Three shots, three different failures. **The letters are the content of a literacy show and must never be generated.**

The answer that worked: **the author supplies still frames with the correct letters, and the edit cuts them on the voice.** Scene 7's reading shot is eight of her stills, each held across its own letter. This killed three problems at once — lip sync (no mouth on screen), the pointing finger (correct in every frame by construction), and the glow (the lit tile is the named tile by construction).

Where a still is not possible, cover the row with a **caption plate** (a dark rounded rectangle with the letters set in Georgia Bold, generously spaced). Scene 7 job E does this. Size it to the row only — a full-width bar buried the chest.

---

# 5. THE DUB

`production/kuku_flow/dub_clip.sh <video> <out> "<mp3>@<t>[:<mp3>@<t>…]" [keep:<from>-<to>,…]`

- It **detects every speech window in the generated track and mutes all of them.** Earlier versions took a hand-written mute list and every span I mistyped left the model's invented Russian audible under ours.
- `keep:` preserves named spans. **Use it for every non-speech sound worth having** — a laugh, a lid, tiles hitting the floor, a latch. The auto-mute cannot tell speech from foley and will silence both.
- It **refuses to write** if any recording would run past the end of the clip, reporting the exact overrun. `-shortest` used to truncate the last word silently; «Снова Васей станешь» shipped as «Снова Васи» and only the author's ear caught it.

## Placement — the single most important audio rule

**Never place a line as one block.** The model's pacing and the recording's pacing disagree, and a single offset makes every phrase drift further out than the last. This has now bitten three times.

**Split the recording at its own sentence or word boundaries and pin each piece to the mouth movement it belongs to.** Measure the mouth movements with `production/kuku_flow/speech_windows.sh <video>`.

Worked examples, all in the current cut:
- `vas_L1_A.mp3 … vas_L8_B.mp3` — Вася's eight letters, cut apart and placed individually
- `mama47_p1..p3.mp3` — one line, three sentences, three separate mouth blocks with a four-second gap
- `mama49_p1..p2.mp3` — «Знаешь.» … long pause … «А брат твой пока знает восемь.»

## Splices must match pitch
A letter re-rendered to sound "final" came back at 139 Hz against the original's 271 Hz — a grown man in a boy's mouth. **Measure f0 before sending.** The fix that worked was not re-recording but editing his own take: same recording, pitched down ~5% and slowed ~10% with a beat of silence in front. One continuous move, never sliced — slicing inside a short sound garbles it audibly.

---

# 6. THE CAST

`production/2026-08-16_EP1_PRODUCTION_RECORD.md` §1 has the table. The cast block lives in `audio/ep1_birthday_english_v3.performance.json` — the filename says english, the contents are the Russian cast, and this has been missed twice.

| character | voice | id |
|---|---|---|
| ФРОСЯ | Ekaterina | `GN4wbsbejSnGSa1AzjH5` |
| ВАСЯ | Leonid | `bg9LrEYQkRYwqkxA8VOy` |
| МАМА | Olga | `jF2jkOwefhvnRzZHn0sl` — **UNDER RECAST, see below** |
| ПАПА | Nester Surovy | `pM78bgjPVk0JXtaEnFoj` |
| БАБА-ЯГА | Doris | `YHcCpa6SBWnKDaCPZJQR` (English voice, chosen for age/rasp) |

## МАМА's voice is an OPEN DECISION
`production/2026-08-18_MAMA_VOICE_SHORTLIST_OPEN.md`. The field is closed to **four takes**: 21 and 22 (Elen Kuragina `TPIitICAZ8CqlGZ81AKm`), 23 and 24 (Ilinca `FcZStbCG9g9QxDlJioSD`), in `audio/mama_audition/`. Do not audition more voices. The author's note: *Kuragina doesn't enunciate enough, Ilinca over-enunciates.* On Kuragina the dial is `stability`; on Ilinca it is `similarity_boost`.

Whichever wins, **every Мама line in the episode is re-rendered and re-dubbed** — scenes 1 through 7, not just one scene. No credits, but a full pass.

## МАМА's register depends on who she is talking to
Three failed attempts before this was understood. **To Бабушка-Яга: dry, level, unimpressed. To her children: warm, patient, firm underneath.** Written flat for both, she plays as *angry* — the author's word, about scene 7. She is not the obstacle in these scenes; she is the one who out-thinks the room and enjoys it.

## Performance tags matter more than settings
The first Мама audition was rendered with no tags at all, so thirteen candidates all sounded identically flat and the comparison was nearly worthless. Power order: **style → low stability → the tag**. High style drops a voice into a chest register — that is what aged Вася.

---

# 7. WHAT THE AUTHOR HAS ASKED FOR, IN HER OWN TERMS

- **Two to three episodes a week.** Hand over a script, walk away, come back to something not atrocious. Everything above exists to serve that.
- **Convert every defect into gate code**, not notes. "I really cannot waste credits on this stupidity."
- **Send files, not links.** She reviews on a phone. **Audio must be sent with `display: "render"`** — sent as attachments it arrives as download cards she cannot play. For a batch she compares, **number first and keep names short** (`01-Kuragina.mp3`); long shared prefixes get truncated in the middle and every file looks identical.
- **Video is the reliable channel.** Artifact pages with embedded audio were blocked by the page's content policy.
- She will say when something is accepted. Scenes 6 and 7 are accepted. **Do not regenerate accepted work.**

---

# 8. SCENE 8 — WHAT IS THERE ALREADY

SH102–SH140. The payoff scene: the children use the magic. Four escalating steps — СОК, САЛАТ (Руся crawls in, inspects, crawls out, silent, funniest beat in the episode), МАК (given to Мама; the pencil visibly shortens afterward), then **МАМА** — Вася assembles his own word, reads it, shouts ВЖУХ and turns into his mother while the babies swarm him.

**All the assets for the transformation already exist. Do not tell the author they need making.**

| asset | path |
|---|---|
| Вася-Мама character | `ep1prod/scene1/references/T-VAS-MAMA-01_approved.png` |
| Вася hands up, before the ribbons | `ep1prod/scene1/references/C-VAS-TRANSFORM-PRE_author.png` |
| Вася wrapped in golden ribbons | `ep1prod/scene1/references/C-VAS-TRANSFORM-CHARGED_author.png` |
| Вася as cat | `ep1prod/scene1/references/T-VAS-CAT-01_approved.png` |
| Вася as wasp | `ep1prod/scene1/references/T-VAS-WASP-01_approved.png` |
| the magic mat | `ep1prod/scene1/references/SET-MAGIC-MAT_author.png` |
| Мама reveal | `ep1prod/scene1/references/REVEAL-MAMA_author.png` |
| **transformation clip, 5s** | `production/kuku_flow/magic/transform_vasya.mp4` |
| **materialisation clip, 5s** | `production/kuku_flow/magic/materialize_frosya.mp4` |
| **spell sequence, 16s, six beats** | `production/kuku_flow/spell/` — placement, ignition, charge, flash, reveal, road |
| word graphics | `production/kuku_flow/words/*.png` |

The registry already has `VasyaCat` and `VasyaWasp` cast tokens. **`VasyaMama` does not exist yet and needs adding** to `Drakosha_SeedanceBatch.res` pointing at `T-VAS-MAMA-01_approved.png`.

The three magic clips were sent to the author on 2026-08-19 for review, to decide what is reusable and what needs improving before scene 8 is staged. **That review is the next thing waiting on her.**

ANSWERED 2026-08-19: she supplies a COMPOSABLE ALPHABET (transparent PNGs, two states per letter) built in an external tool; the pipeline composites and cuts on voice. Full spec in `2026-08-19_SCENE8_TRANSFORMATION_SYSTEM.md`. The alpha-compositing contract was validated with her first letter over her paper plate — test composites saved as `kuku_flow/frames/s8_writing/TEST-COMPOSE-S-*.jpg`.

---

# 9. OPEN ITEMS

1. **Мама's voice** — pick one of takes 21/22/23/24, then re-render and re-dub every Мама line in the episode.
2. **The magic clips** — author to review the three sent on 2026-08-19.
3. **Scene 8** — unstaged. Needs the letters decision first.
4. **Бабушка-Яга in scene 7** appears only in the last 2.3 seconds (79.7–82.0). The author noticed and asked why. Options offered: reuse a slice earlier, hold the final shot longer, or shoot one short reaction (~20 credits). Undecided.
5. **The pencil is sharpened at both ends** in scene 7 and the author chose to live with it. The registry line is corrected for scene 8 onward: one end sharpened, the other blunt, flat and bare.
6. **A repaint tool exists** at `/tmp/letterfix.py` (letters) and the pencil-masking approach is documented in this session — both work and neither is in the repo yet. If they are wanted permanently, move them out of `/tmp`.
7. **`stories/frosya-vasya/` and `stories/drakosha/`** are still unmerged; `BIBLE.md` lives in the former.
