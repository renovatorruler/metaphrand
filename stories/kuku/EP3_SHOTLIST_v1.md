# EP3 «र से रीछ» — SHOT LIST v1 (from screenplay v2, 95 events / 7 scenes)

Same law as Ep2: the video model renders only the shots below; dialogue rides TALK stills
or VO windows at exact take length. **New this episode: an SFX track** — 24 generated
effects placed per the script's (ध्वनि) cues; रीछ's growls ARE his voice (no TTS).

**Reused from Ep2 ($0):** s_dadi_rock · s_vesper_rock · s_fyuria_rock · s_dadi_night ·
s_fyuria_kitab · all cast sheets · score cues cue1 (feast), cue3 (lesson), cue6 (heart),
cue7 (night/recap) · title/credits songs · card + glyph machinery.

**New renders:** 17 stills (34cr) + 10 clips (300cr) + रीछ/रथ sheets (4cr) ≈ **338cr**.
**New EL:** ~90 takes · 3 score cues (cueA evening / cueB night-mystery / cueC chase) · 24 SFX.
**Local ($0):** 10 typst cards (title, recap intro, 6 words, the completed-name card
«मिटासु**र**», outro) · fx_r glyph · door-name overlays (नाम completes via letter-VFX,
never model-rendered text).

| दृश्य | Coverage plan |
|---|---|
| 1 — मिटासुर का घर, शाम (cueA) | c31_paint under the humming open; TALK: e3_mitasur_paint, e3_kuku_evening, e3_mitasur_stuck (the «...और आगे?» beat), e3_fyuria_evening, e3_vesper_evening (far), e3_toddlers (कैस्टर «ल!» / लेडा «र!»); door shows «मिटासु» via naam1 overlay; walk-off on SFX walkoff |
| 2 — दादी की चट्टान (cue3) | TALK on rock stills (dadi/vesper/fyuria reused; e3_kuku_rock, e3_mitasur_rock new); fx_r overlay on the reveal; कालू beat = e3_kalu_cu + kalu_rrr/kalu_bark SFX; call-response chorus takes |
| 3 — पहाड़ी, रात (cueB head) | c32_break carries the whole scene: दादी's lullaby VO over it, then sniff_steps → creak_strain → rope_snap SFX in sync; growl_hungry |
| 4 — कुकु का घर, रात (cueB tail → cueC head) | TALK: e3_kids_night (wake exchange), e3_mitasur_night; VO over c33_rolling (रथ careens, growl_scared, wheels_roll); c34_chasefail under फ्यूरिया's failing sprint + her defeated stop |
| 5 — ढलान (cueC) | TALK: e3_slope_vesper (the plan); c35_meadow (shortcut dash); c36_forge + fx_r (र THUDS in as खूँटा); e3_rope_team (rope lines); the held-breath beat + «रुकोओओ!» over c37_stop with rope_catch → stop_splash → soft_tumble; e3_reechh_grass + tummy_hungry (वैस्पर's diagnosis); कुकु's invitation |
| 6 — उत्सव, सुबह (cue1 → cue6 at the name) | c38_feast establish; TALK: e3_feast_dadi, फ्यूरिया gift beat on e3_fyuria_roti; c39_eat + big_bite + tummy_happy + growl_happy; the NAME: e3_mitasur_name + brush_three SFX + naam2 overlay completing «मिटासुर» on the door; cheer_clap |
| 7 — चट्टान, रात (cue7) | Recap cards r02–r08 cycle under दादी's counting; the completed-name card r09; नीति on s_dadi_night; फ्यूरिया writes र on s_fyuria_kitab + pencil SFX; c40_end pan (वैस्पर asleep IN the रथ, कालू, toddlers, रीछ snoring against the wheel) + growl_snore; शुभ रात्रि |

Assembly: same machine as Ep2 (assemble_ep2_v5.sh generalized) — SFX enter as pseudo-takes
on the timeline like Ep2's chick-cheep; growls duck the score exactly like dialogue.
