# EP1 production record — session of 2026-08-14 → 16

Everything decided, generated, filed and learned in this session. Written because twice in one session work stalled on facts that existed but were not recorded — the Russian voice cast, and the per-line expression tags. Nothing here is inferred; where something is unknown it says so.

---

## 1. CAST AND VOICES

The Russian cast lives in `stories/drakosha/audio/ep1_birthday_english_v3.performance.json`. **The filename says "english" but the `cast` block inside is the native-Russian cast.** That is why it was missed twice. Corroborated in `stories/frosya-vasya/BIBLE.md`.

| character | voice | voice_id | native ru |
|---|---|---|---|
| ФРОСЯ | Ekaterina — professional female | `GN4wbsbejSnGSa1AzjH5` | yes, Moscow |
| ВАСЯ | Leonid — Warm and Calm Russian | `bg9LrEYQkRYwqkxA8VOy` | yes, Moscow |
| МАМА | Olga — Elegant Russian Voice | `jF2jkOwefhvnRzZHn0sl` | yes, standard |
| **ПАПА** | **Nester Surovy — Gravely yet Refined** | **`pM78bgjPVk0JXtaEnFoj`** | **RECAST 2026-08-16** |
| БАБА-ЯГА | Doris — Mora gritty elderly | `YHcCpa6SBWnKDaCPZJQR` | **no — English voice, chosen for age/rasp** |
| NARRATOR | Anna Zub — Warm Multilingual | `deqzqEZ3ngCdcOl0jF1F` | yes |
| GIANT CHILD | Mini — Lively Cute Little Female | `nUX4UWK0Tf1qh5zvFZWR` | — |

**ПАПА was recast from Anton `TpZlRcB7rTBboAYWa2DC` to Nester Surovy.** Anton is a narration voice (`descriptive=calm`) and could not be made to sound happy or loud by any tag, stability or speed setting. All six of his lines were re-rendered: 11, 13, 19, 24, 26, and the «Ура!» currently filed as 110.

Model is `eleven_v3`, output `mp3_44100_128`, throughout.

Settings that worked for Nester: `stability 0.15`, `similarity_boost 0.6`, `style 0.85`.

---

## 2. LINES — TEA SCENE (scene 4b, SH048–055)

| # | speaker | text | tag | file | status |
|---|---|---|---|---|---|
| 1 | МАМА | Мама, ты же говорила, что в этом году не выберешься. | unknown | `line22_MAMA.mp3` | original, kept |
| 2 | ЯГА | На седьмой день рождения старшей внучки? Я бы ради такого дня и не в такую трубу полезла. | unknown | `line23_YAGA.mp3` | original, kept |
| 3 | ПАПА | Молодец вы, тёща! Я б в ваши годы не полез! | `[laughs heartily]` | `line24_PAPA_FINAL.mp3` | NEW |
| 4 | ЯГА | Всё так же говоришь, как с плеча рубишь. | `[dryly, with a sly smile]` | `line25_YAGA_FINAL.mp3` | NEW |
| 5 | ПАПА | Зато сразу слышно, что я рад. | `[cheerfully, unbothered]` | `line26_PAPA_FINAL.mp3` | re-rendered, Nester |
| 6 | ЯГА | Слышно. Через три стены. | unknown | `line27a_YAGA_FINAL.mp3` | split from original line27 |
| 7 | ЯГА | А я вам тут свечек к торту привезла. Так, мелочь. | `[mischievously]` | `line27b_YAGA_FINAL.mp3` | NEW |
| 8 | МАМА | Ой, ну зачем ты… Спасибо, мам. | `[fondly]` | `line27c_MAMA_FINAL.mp3` | NEW |

"unknown" tags are honest — no performance manifest exists for the Russian renders, so the tags that produced those approved reads are not recoverable. Preserve those files as audio; do not attempt to reproduce them.

### Why the dialogue changed

The original exchange was written for a ПАПА who spoke **incorrect, rough Russian**. That was changed so children hear correct Russian, but the jab «говоришь, будто дрова колешь» stayed — pointing at a coarseness that no longer existed. That is why the beat felt unmotivated.

The fix: his line became a **tactless blurt inside a compliment** — he praises her chimney climb while saying he wouldn't manage it at her age. The gaffe works because **he makes himself the inferior term**; the sentence's object of criticism is himself, which is why it cannot invert into sarcasm. Every version where the judgement fell on her read as a dig.

He addresses her as **вы**; every one of his original lines carefully avoids a pronoun. This is standard for a Russian son-in-law and carries no characterisation — an earlier claim that it marked him as an outsider was wrong.

`рубить с плеча` = to speak or act without weighing it first, still an axe image, and it names what he actually did. It replaced `дрова колешь`, which describes manner rather than tact.

---

## 3. TEA SCENE SHOT LIST AND TOOLS

Order was set by the author, driven by physical continuity: one pour for Яга, one pour for Папа himself, nothing pouring twice, and Мама's hand reaching her mouth only after his line.

| shot | plate | tool | line | output |
|---|---|---|---|---|
| 1 | `f18_mama_cu_author.png` | OmniHuman | 22 | `tea_shots/shot1_MAMA_omnihuman.mp4` |
| 2 | `f18_yaga_ots_author.png` | OmniHuman | 23 | `shot2_YAGA_omnihuman.mp4` |
| 3 | `f18_master_prepour_author.png` → `f18.png` | Seedance 2.0 Mini, start+end, 6s | 24 | `shot3_pour_seedance.mp4` |
| 4 | `f18_yaga_cu_pour_author.jpeg` | OmniHuman | 25 | `shot4_YAGA_omnihuman.mp4` |
| 5 | `f18_papa_cu_author_FINAL.png` | OmniHuman | 26 | `shot5_PAPA_omnihuman.mp4` |
| 6 | `f18_yaga_cu_talk_author.png` | OmniHuman | 27a | `shot6_YAGA_omnihuman.mp4` |
| 7+8 | `f18_master_candlebox_author.png` → `f18_candlebox_open_author.png` | Seedance 2.0 Mini, start+end, 8s | 27b + 27c | `shot78_candlebox_seedance.mp4` |

Assembled: `2026-08-16_EP1_scene4b_TEA_SCENE_v1.mp4`, 33.16s, normalised to 1472×832 @ 25fps.

On the two Seedance shots the model's own generated audio was **replaced** with ours. On shot 7+8, Яга's line sits at +0.30s and Мама's thanks at +4.90s so it lands as the lid opens.

Cost for the scene ≈ **$3.40**: OmniHuman $0.14/sec of audio; Seedance 2.0 Mini 2.5 credits/sec (~$0.043/credit).

---

## 4. TOOL SELECTION RULES (learned the hard way)

**OmniHuman takes a still image + audio and generates the video.** It cannot be layered onto an existing clip. For lip-sync over generated motion the tool is `fal-ai/latentsync` (video-to-video, $0.20 flat up to 40s) or `fal-ai/sync-lipsync/v2` ($3/min).

**OmniHuman animates the performer, not the room.** Expression, eyes, blink and head motion all come from the audio — there is no prompt or expression control. Steam, poured liquid and other environment motion will not animate.

**Use Seedance only where two frames must be interpolated.** Everything else is cheaper and more faithful through OmniHuman.

**Seedance 2.0 Mini accepts `start_image` AND `end_image`**, keeps `generate_audio`, and costs 2.5 cr/sec — one third of 2.5. Limit is 9 images counting both frames. Kling 2.6 has NO end frame; Kling 3.0 and Minimax Hailuo do.

**References are free** — price is duration only. Attach the character sheets and prop plates always. The earlier "fewer references = better staging" lesson applies only when nothing pins the composition; with both frames fixed, references can only help identity.

### fal.ai mechanics

Key is `FAL_AI` in `/Users/dusty/dev/metaphrand/.env` — **not** `FAL_KEY`, and not in the home directory.

fal rejects base64 data-URI audio. Upload first: `POST https://rest.alpha.fal.ai/storage/upload/initiate` with `{content_type, file_name}` → returns `{upload_url, file_url}`; PUT the bytes to `upload_url`; pass `file_url`. Then `POST https://queue.fal.run/fal-ai/bytedance/omnihuman` with `{image_url, audio_url}`, poll `status_url` until `COMPLETED`, GET `response_url`, download `video.url`.

### Higgsfield mechanics

`--image` with a local file over ~1MB fails silently at the request layer ("no response received"). Upload first with `higgsfield upload create <path>` and pass the returned UUID.

`higgsfield generate list --json` exposes each job's full prompt — **this is the only reliable way to tell our jobs from the co-user's on this shared account.** Timestamps are not sufficient; four images were once misattributed and downloaded on that basis.

---

## 5. ELEVENLABS CRAFT NOTES

**Select voices by `use_case`, not by `descriptive`.** A voice cloned from narration cannot produce volume or delight no matter the tag. `characters_animation` and `entertainment_tv` voices can. Doris works for Яга because she is `characters_animation`.

Power order for pushing a voice off its centre: **`style`** (0.85–1.0) → **`stability`** low (0.15; 0.1 risks wobble) → the tag. A written interjection or `[laughs heartily]` beats any adjective.

**Pace target 0.32–0.39 s/word** — measured across the approved renders. Slower than that means the model has gone theatrical. Fix with `speed` 1.05–1.12 and by shortening the line.

**A comma forces articulation at a junction the model slurs.** «как с плеча рубишь» came back mangled three times running; writing it «как с плеча, рубишь» produced a clean read with no audible pause. Cheaper than rewording around the synthesiser.

Combining acute stress marks can drag the marked syllable. The approved older renders may not have used them.

**Яга's register: folksy and sly, never sweet or sheepish.** She undersells her own gifts. A `[cheerfully]` candle line came back small and approval-seeking and was rejected.

---

## 6. AUDIO LINE NUMBERING — WARNING

Audio files `lineNN_SPEAKER.mp3` map to **dialogue-only** lines in `2026-08-03_EP1_den-rozhdeniya_numbered_bilingual.md` (narration and stage directions excluded from the count). The offset is **+2** through the tea scene — verified by transcription, not arithmetic.

**The offset drifts later in the episode.** `line110_PAPA.mp3` contains «Ура!», which the script places at dialogue #109 (L215), while #108 (L212) is Яга's «Загадывай, внучка». The file is misnamed.

**Do not map audio to script by arithmetic.** Transcribe and match text. Local transcription is free:

```
/Users/dusty/dev/metaphrand/.venv/bin/python -c "
import mlx_whisper
print(mlx_whisper.transcribe('FILE.mp3', path_or_hf_repo='mlx-community/whisper-small-mlx', language='ru')['text'])"
```

The venv's console scripts have a broken shebang (points at the pre-rename `/Users/dusty/Dev/brehon-law/.venv`). Call the module through `python -c`, not `mlx_whisper` directly.

**`2026-08-14_EP1_SCENE2_EDL_v8.md` is wrong about line 15.** It records speech at 39.23–41.68; the actual v8 build has it at 36.4–39.3. Lines 11 and 13 in that document were verified correct by audio correlation. Treat the rest as unverified.

---

## 7. REFERENCES FILED THIS SESSION

In `ep1prod/scene1/references/`, all with receipts:

| file | what |
|---|---|
| `PROP-YAGA-KIT-01_author_three-items_no-figure.png` | ступа, помело, broom together, no figure |
| `PROP-STUPA-01_author_solo.png` | ступа alone, empty, on its foot |
| `PROP-POMELO-01_author_solo.png` | rag mop — NOT a twig besom |
| `PROP-BROOM-01_author_solo.png` | twig besom — NOT a rag mop |
| `PROP-CANDLEBOX-01_author_closed_and_open.png` | box in BOTH states, seven striped candles |
| `PROP-TEA-01_author_thimble_and_kettle.png` | dimpled thimble-cup and brass kettle |

`packet_v2/page-13.png` remains the approved ступа **design** but lost its prop binding: it shows Яга standing inside the ступа, and binding it to a shot whose rule is that she is never inside it hands the model a contradicting picture.

**Indoors the ступа stands empty on its foot and she stands beside it.** She rides in it; she does not stand in it in the house.

Broom and помело were split into separate tokens so they can never be conflated — one shared image previously left the model guessing which stick was which.

In `production/kuku_flow/frames/f18_angles/` — the author's tea-table plates, all 16:9: master, pre-pour master, candle-box master, candle-box open, Мама CU, Яга OTS, Яга CU pour, Яга CU talk, Папа CU FINAL. Two superseded Папа versions are kept as `_v1_drifted` and `_v2_superseded` rather than overwritten.

---

## 8. EDITORIAL DECISIONS

**Яга arrival** (`2026-08-14_EP1_scene4_YAGA-ARRIVAL_v4_full.mp4`, 23.91s): job17 full → job18 v2 (12s, regenerated with the correct домовой reference and a start frame taken from job17's last frame) → job19 from **4.30s**, entering on the family group a beat before Фрося's «Ба́бушка!». Earlier in-points at 2.30 and 1.50 were rejected because Яга's mouth was still visible and her line was audible twice.

**Job 18 v2 design**: start frame = job17's final frame; camera swings off it and settles; **one full second of stillness**; thud, dust from every edge, hatch jumps; hatch opens; she climbs out with all three objects; dusts off; camera pushes to close-up; her look stops screen-right; the line. Cost 78 credits.

**Scene 2** (`2026-08-16_EP1_scene2_SEQUENCE_v13_nester.mp4`, 51.08s): the v8 cut with the frozen tail removed — v8's video stream ended at 51.20 while its audio ran to 55.76, holding the last frame over silence for 4.56s, which read as the film ending. Папа's lines then swapped to Nester at 2.65s and 19.25s, positions found by audio correlation.

**Full assembly** `2026-08-16_EP1_scene1-4b_ASSEMBLY_v5.mp4`, 212.85s: scene 1 reel (88.5) → scene 2 (51.1) → flight clip15 → chimney clip16 → arrival (23.9) → tea (33.2). Normalised 1280×720 @ 24fps.

**Known weakness**: clip15, the sky flight, is from the Aug 6 no-reference run and contradicts current canon — wrong Яга design, smooth round ступа instead of the carved faceted one, and it carries a pestle and lashed bundles, both retired. clip16 survives because she is tiny and distant.

**Scene 1 audio is all model-generated**, predating the ElevenLabs dubs. The seam at 88.5s is the most audible problem in the cut.

---

## 9. OPEN ITEMS

- `stories/frosya-vasya/` and `stories/drakosha/` are still two directories. Zero colliding filenames. Blocked on two decisions: whether to delete the nine legacy `.py` files (ReScript-only law) and whether the July `ep1prod` goes to `archive/` rather than merging into the current one.
- A performance document covering the whole show, as a ReScript module beside `Drakosha_Pronunciation.res`, holding speaker, voice id, settings, text and tag per line — with tags marked unknown where they are.
- `line110_PAPA.mp3` misnamed; the audio↔script numbering needs verifying across all 114 by transcription.
- Scene 1 needs redubbing to match, or the seam will stay.
- The candle count (seven) is carried only by the picture now that Яга's line says «свечек» without the number.
- SFX still missing from the scene-2 cut: the tin lid and the core on paper, both lost when the original track was muted across those shots.

---

## 10. EDL — EXACT TIMINGS

Measured from the files, not from notes. Every boundary below was produced by `ffprobe`, not estimated.

### `2026-08-16_EP1_scene1-4b_ASSEMBLY_v5.mp4` — 212.784s, 1280×720 @ 24fps

| in | out | source |
|---|---|---|
| 0.000 | 88.513 | `rnd/seedance_test/skill_run/2026-08-06_EP1_scene1_skillrun_reel_v1.mp4` — scene 1, sock/heist/car |
| 88.513 | 139.596 | `kuku_flow/2026-08-16_EP1_scene2_SEQUENCE_v13_nester.mp4` — birthday, Папа redubbed |
| 139.596 | 147.653 | `rnd/seedance_test/skill_run2/clip15.mp4` — sky flight (OFF-CANON, see §8) |
| 147.653 | 155.710 | `rnd/seedance_test/skill_run2/clip16.mp4` — chimney drop |
| 155.710 | 179.623 | `kuku_flow/2026-08-14_EP1_scene4_YAGA-ARRIVAL_v4_full.mp4` — arrival |
| 179.623 | 212.784 | `kuku_flow/2026-08-16_EP1_scene4b_TEA_SCENE_v1.mp4` — tea |

### `2026-08-16_EP1_scene4b_TEA_SCENE_v1.mp4` — 33.136s, 1472×832 @ 25fps

| in | out | shot | file |
|---|---|---|---|
| 0.000 | 3.480 | 1 Мама | `tea_shots/shot1_MAMA_omnihuman.mp4` |
| 3.480 | 10.560 | 2 Яга OTS | `tea_shots/shot2_YAGA_omnihuman.mp4` |
| 10.560 | 16.640 | 3 the pour | `tea_shots/shot3_pour_seedance.mp4` |
| 16.640 | 19.720 | 4 Яга mid-pour | `tea_shots/shot4_YAGA_omnihuman.mp4` |
| 19.720 | 22.560 | 5 Папа | `tea_shots/shot5_PAPA_omnihuman.mp4` |
| 22.560 | 25.040 | 6 Яга, cup down | `tea_shots/shot6_YAGA_omnihuman.mp4` |
| 25.040 | 33.136 | 7+8 candle box | `tea_shots/shot78_candlebox_seedance.mp4` |

### `2026-08-14_EP1_scene4_YAGA-ARRIVAL_v4_full.mp4` — 23.913s

| in | out | source |
|---|---|---|
| 0.000 | 8.064 | `job17_arrival-notice.mp4` full |
| 8.064 | 20.128 | `job18_v2_hatch-climbout_12s.mp4` full — its first frame IS job17's last frame, so the join is invisible |
| 20.128 | 23.913 | `job19_babushka.mp4` **from 4.30s to end** |

### `2026-08-16_EP1_scene2_SEQUENCE_v13_nester.mp4` — 51.083s

Built from `2026-08-14_EP1_scene2_SEQUENCE_v12.mp4` (itself v8 truncated at 51.05 to kill the frozen tail) by this exact filter:

```
[0:a]volume=0:enable='between(t,2.55,8.00)',volume=0:enable='between(t,19.15,22.10)'[base];
[1:a]adelay=2650|2650[p1];[2:a]adelay=19250|19250[p2];
[base][p1][p2]amix=inputs=3:duration=first:dropout_transition=0,volume=2.2[a]
```

Input 1 is `line11_PAPA_nester.mp3`, input 2 is `line13_PAPA_nester.mp3`. Offsets 2.65s and 19.25s were found by envelope cross-correlation of the old Anton files against the mix, NOT taken from the EDL.

### Audio placement inside shot 7+8

Яга's candle line at **+0.30s**; Мама's thanks at **+4.90s**, so it lands as the lid opens. Seedance's own generated audio was discarded on both Seedance shots.

---

## 11. FILE MANIFEST

All paths relative to `stories/drakosha/`.

**Approved audio, tea scene** — `production/kuku_flow/audio/`, all 2026-08-16 except where noted
`line22_MAMA.mp3` (2026-08-09, original) · `line23_YAGA.mp3` (2026-08-09, original) · `line24_PAPA_FINAL.mp3` · `line25_YAGA_FINAL.mp3` · `line26_PAPA_FINAL.mp3` · `line27a_YAGA_FINAL.mp3` · `line27b_YAGA_FINAL.mp3` · `line27c_MAMA_FINAL.mp3`

**Папа recast set** — `line11_PAPA_nester.mp3` · `line13_PAPA_nester.mp3` · `line19_PAPA_nester.mp3` · `line26_PAPA_nester.mp3` · `line110_PAPA_nester.mp3` (misnamed, is script line 111)

**Rejected takes kept for reference** — `line24_PAPA_v2..v5*`, `cast_PAPA_test_*` (five deep narration voices), `cast_PAPA_char_*` (four character voices), `cast_PAPA_nester_x1..x4`, `line25_YAGA_s1..s4`, `line25_YAGA_t1..t3`, `line25_YAGA_u1..u3`, `line27b_YAGA_v2_candles_kakpolozheno.mp3`

**Author plates** — `production/kuku_flow/frames/f18_angles/`
`f18_mama_cu_author.png` (08-14) · `f18_yaga_ots_author.png` (08-14) · `f18_yaga_cu_pour_author.jpeg` (08-15) · `f18_yaga_cu_talk_author.png` (08-15) · `f18_papa_cu_author_FINAL.png` (08-15) · `f18_master_prepour_author.png` (08-16) · `f18_master_candlebox_author.png` (08-16) · `f18_candlebox_open_author.png` (08-16). Superseded: `f18_papa_cu_author_v1_drifted.png`, `_v2_superseded.png`. Master is `production/kuku_flow/frames/f18.png`.

**Generated shots** — `production/kuku_flow/tea_shots/`, all 2026-08-16, seven files as listed in §10.

**Prop references** — `ep1prod/scene1/references/`, receipts alongside
`PROP-YAGA-KIT-01_author_three-items_no-figure.png` · `PROP-STUPA-01_author_solo.png` · `PROP-POMELO-01_author_solo.png` · `PROP-BROOM-01_author_solo.png` (all 2026-08-14) · `PROP-CANDLEBOX-01_author_closed_and_open.png` · `PROP-TEA-01_author_thimble_and_kettle.png` (both 2026-08-16)

**Start frame for job 18 v2** — `rnd/keyframes/2026-08-14_KF_job18_start_from-job17-lastframe_hatch-puff.png`

**Superseded cuts, kept** — `2026-08-14_EP1_scene2_SEQUENCE_v8.mp4` (has the frozen tail) · `v9_tightened`, `v10_softtrim`, `v11`, `v12` · arrival trims `v1`,`v2`,`v3` · tea animatics `v1`–`v6`

**Paid assets are never deleted or overwritten.** Every rerender takes a new filename.

---

## 12. HANDOVER — READ THIS FIRST

If you are picking this project up cold, in this order:

1. This file, all sections.
2. `2026-08-16_EP1_DEFECT_INVENTORY.md` — 40+ defects by class with root causes. Section "Recurring root causes" is the shortest useful thing in the project.
3. `CLAUDE.md` at the repo root — ReScript-only law, with the Defold exception.
4. `2026-08-04_EP1_den-rozhdeniya_SHOOTING_numbered_bilingual.md` — the current shooting script (most recently modified EP1 script; there are several older ones with confusingly similar names).
5. `2026-08-04_OBJECT_SCALE_REGISTRY_v1.md` — object scales and what has been retired.
6. `stories/frosya-vasya/BIBLE.md` — series bible, in the OTHER directory, still unmerged.

**Standing constraints that are not negotiable:** paid assets are never deleted or overwritten; the display spelling of taught words is never altered; letterforms are always composited typography, never generated; Soul ID is ruled out for this show; nothing is submitted to a paid API without the author's word on that specific job.

**The account is shared with another user.** Identify jobs by prompt through `higgsfield generate list --json`. Never by timestamp. Never download a result you cannot prove is ours.

**Verify before asserting.** The author corrects errors quickly and expects the correction to stick. When a fact is not known, say so and go and measure it — the artefact is always available.

---

## 13. SET LAYOUT — KNOWN PROBLEM, DEFERRED (2026-08-16)

**The hall's zoning does not hold up.** The f18 tea-table plates carry the bedding crates in frame at the left, so one wall reads as kitchen, sitting area and sleeping area at once, with the dining table at one end and the beds at the other in a space too small to justify the separation. The beds were meant to move to the opposite wall; the plates predate that decision.

**Author's decision: live with it for EP1, redesign both walls for later episodes.** Not worth reshooting mid-episode.

**How EP1 avoids the problem:** never frame the dining zone and the sleeping zone together. The illogic exists only in a wide that connects them. All remaining EP1 coverage is singles, two-shots and inserts, none of which need the whole room — so the layout never surfaces on screen. **Do not shoot a connecting wide.**

**Consequence for the opposite wall:** it does not need to reconcile with the tea table. Design it as its own space with its own logic. Without a connecting wide the audience cannot assemble a floor plan, so the two can read as separate rooms.

**Reshoot list for the layout fix, whenever it happens:**
`f18.png` · `f18_master_prepour_author.png` · `f18_master_candlebox_author.png` · `f18_candlebox_open_author.png` · `f18_mama_cu_author.png` · `f18_yaga_ots_author.png` · `f18_yaga_cu_pour_author.jpeg` · `f18_yaga_cu_talk_author.png` · `f18_papa_cu_author_FINAL.png`

`f20.png` and `f21.png` need reshooting regardless — both still show the **lit fireplace**, retired in favour of the sealed riveted iron plate. Fix both problems in one pass rather than two.

---

## 14. SHOT DESIGN — THE PAIR RULE (2026-08-16)

**Every plate should be half of a pair — a start state and an end state of one shot — not a standalone composition.**

Single plates produce tableaux. A beautifully composed still of a pencil being offered is a *state*, so the shot can only sit in it; cut several together and the result is a slideshow, not animation. Draw instead "hand still in the pocket" and "pencil over the open palm", and that is one shot with an action inside it, which Seedance interpolates for roughly $0.50.

Proof from the tea scene: shots 1, 2, 4, 5 and 6 were single plates and are talking heads that hold still. Shots 3 and 7+8 were pairs and are the only two where anything happens.

**Build the plate list from the SHOT list, not the BEAT list.** Working per story beat produced one picture per beat and no coverage — no inserts, no singles, no reverses, no change of scale.

**Fewer moving shots beat more static ones.** The script's shot counts assume live action, where coverage is free once the set is built. Here each shot is a drawing, so the economics invert: merge script shots into fewer, longer, moving ones. Worked example for the gift beat — thirteen scripted shots merge to seven shots and ten plates, four of them moving.

**Tool per shot:** talking single → OmniHuman, one plate. Action or camera move → Seedance 2.0 Mini start+end, two plates. OmniHuman cannot move the camera or animate the room; Seedance cannot lip-sync our audio.

**Untested alternative:** two or three 12-second Seedance takes covering a whole beat, ~$1.30 each. Trades identity drift and approximate Russian lip movement for far less drawing, and gives up cutting for rhythm. Worth one experiment; do not plan a scene around it before that.

---

## 15. ЯГА CASTING — RE-CONFIRMED 2026-08-17

Auditioned against Doris/Mora `YHcCpa6SBWnKDaCPZJQR` on the same line at identical settings: Lucinda `fs3nd19KF2GO2hLTzkBm`, Kassandra `KFcKSkKkWqMVhCbLkuvh`, Elinor `gDQfVolj9RbmXgumLcOq`, Nieve `nAFxIJGj7iSTeltygOfB`, Morganna `7NsaqHdLuKNFvEfjpUno`, Granny/La Witch `M9RTtrzRACmbUzsEMq8p`, Noergel `lJsTszeSyrYhIQNECkbn`, Agatha `HH3kybY6uEJ2ebSa9Vy3`.

**Doris stays.** Agatha was the only serious rival — older and creakier — but rejected on ENSEMBLE grounds: she does not fit the rest of the cast. Also 70% slower on short lines (5.28s vs 3.12s on «Ну, именинница»), which would make Яга's quick jabs ponderous.

**Search note:** the pool of old female `characters_animation` voices is only ~15 voices TOTAL and was searched exhaustively. Do not re-run this audition. Filtering by `language=ru` is a mistake — Doris is `language=en` and speaks Russian fine; the ru filter excludes the pool she comes from.

**Age vs slyness on Doris is a single dial.** `stability` low (0.2) gives slyness but the voice drifts younger and smoother; high (0.5–0.6) returns the rasp and age but flattens the performance. There is no setting that gives both. Takes at 0.4–0.5 are the usable compromise.

### Line 34 revised (magic rule)

> Какую штуковину на белом свете душа пожелает, напишешь имя, поставишь точку, и будет по-твоему.

Replaces «имя её напишешь, она и явится». Two faults fixed: «она» was ambiguous once «точка» was added (both feminine, точка nearer), and an em-dash made the model read the first half as a question — use a comma.

### THE MAGIC RULE (decided 2026-08-17)

**Фрося writes and marks a точка. The thing appears when the full stop lands.** «И точка» in Russian also means *and that's final*, so the mark that ends a sentence is the word for a thing being settled. Scope is everything back to the previous stop, so her power grows with her vocabulary and the gesture never changes.

**Вася decodes** (builds a word from tiles, reads it aloud, shouts ВЖУХ). **Фрося encodes** (writes it, marks it). Reading and writing, one child each — that is the shared secret Яга refers to.

The pencil is the magic object, NOT the paper — she can write on a wall, the floor, anything. Rejected: lifting the pencil (she lifts it between every letter), holding up the paper (makes paper part of the equation), a wand gesture (arbitrary, and it demotes the letters to a password), circling (works but doesn't scale to longer text), underlining (works, but prosaic).

**The trigger teaches nothing and is not supposed to.** It is plumbing. The lesson is spelling, and the engine of every story is MISSPELLING — write it wrong, get the wrong thing.

**Not stated in dialogue beyond line 34.** The gesture is shown, not explained. Яга already explains Вася's rule; a second explanation makes her a manual.

### ЯГА — WORKING VOICE SETTINGS (found 2026-08-17)

**Doris `YHcCpa6SBWnKDaCPZJQR` · stability 0.40 · similarity_boost 0.80 · style 0.60 · `eleven_v3`**

Found by accident: this was the neutral baseline used to compare candidate voices, and it beat every take made by deliberately tuning. Both dials were being pushed to extremes — 0.20/0.90 gave slyness but a young smooth voice, 0.50–0.60/0.40–0.50 gave age but a flat read. 0.40/0.60 is the balance.

**`similarity_boost` is the age control and was the one underweighted.** At 0.65 the voice drifts off Doris's own timbre and sounds young. At 0.80 it stays near her recorded character and the rasp returns. Above 0.85 it stiffens.

Let the TAG do the acting; leave the dials here.

`line34_YAGA_FINAL.mp3` = this take, 8.80s.
