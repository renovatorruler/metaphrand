# Kuku Episode 9 finale: finish handoff

Date: 2026-08-16  
Status: incomplete production; clean 12-minute main-story animatic exists; no provider job is running

## Read this first

The user wants this episode finished quickly. Do not restart discovery, redesign the production system, or build more validation infrastructure.

The user's complaint about being down to 33% referred primarily to their LLM usage/context credits, not specifically to Higgsfield credits. The prior workflow used too much LLM work on audits, subagents, ReScript guards, and bespoke local repairs. Conserve LLM usage from this point forward:

- work from this handoff and the prepared assets;
- do not repeat repository-wide audits;
- do not spawn a tree of agents;
- produce a visible cut before producing more documentation;
- timebox any local repair to 20 minutes;
- review generated shots in sequence immediately;
- do not make another technical progress reel with large overlays.

The current host is Codex. Follow `docs/PROVIDER_ISOLATION.md`: use native Codex workers only unless the user explicitly authorizes another provider. Do not use Claude CLI, Anthropic API, or `codex exec` as a worker substitute.

## Product and story

This is the Season 1 finale of the independent Kuku children's series. The episode promises that the five child dragons can become large bracelet forms, fly, rescue the goat and broken gate together, and leave for Gurukul training.

Authoritative story files:

- `stories/kuku/2026-08-11_EP9_ba_bada_BEATSHEET.md`
- `stories/kuku/2026-08-11_EP9_ba_bada_SPEC_SCREENPLAY.md`
- `stories/kuku/ep9prod/finale/EP9_FINALE_SHOOTING_SCRIPT.md`
- `stories/kuku/AKSHAR_GURUKUL_CANON.md`
- `stories/kuku/CHARACTER_BIBLE.md`

The main story is exactly 12:00. The already produced cold open is 2:00. A planned 0:15 title makes the intended review runtime 14:15 before credits.

## Non-negotiable continuity rules

1. Kuku, Furia, Vesper, Castor and Leda receive equal bracelets.
2. The first group transformation overlaps and all five finish together. Kuku must not become large before the other four.
3. All five take off together after the shared completion pulse.
4. Later, each trainee can transform independently. Leda demonstrates this first near the ending.
5. Present-day large bracelet forms are youthful trainees, not the fully trained future-war forms from the dream cold open.
6. Ordinary child forms do not fly.
7. The rescue `ब` must remain a rigid, recognizable Devanagari `ब`; it is a physical load-bearing structure, not a flat graphic overlay.
8. Leda identifies the pattern and stops the failed solo rescues. Castor finds and presses the hidden chest latch.
9. Rishi is wingless. Dadi is winged.
10. Exactly five children remain equal in framing, power and consequence.

## Best current review cut

Use this as the starting picture. It has the original cast guide dialogue, no large text overlays, full-frame imagery, and the revised dimensional chest scene.

- Phone version: `stories/kuku/ep9prod/finale/review/EP9_MAIN_STORY_CLEAN_FULL_AUDIO_GUIDE_540P_V3.mp4`
  - 12:00, 960x540, H.264/AAC, fast-start, 17,646,690 bytes
  - SHA-256: `bfb08868492c83b82e347e0f9267640e880ad053572c6e3a3aaeac121e7fafee`
- 720p version: `stories/kuku/ep9prod/finale/review/EP9_MAIN_STORY_CLEAN_FULL_AUDIO_GUIDE_720P_V3.mp4`
  - 12:00, 1280x720, H.264/AAC, fast-start, 153,404,331 bytes
  - SHA-256: `3e78475312d5bebe44debb2fca8198a38f89f1b9773c5bf0bad0b6326559d9de`
- Contact sheet: `stories/kuku/ep9prod/finale/review/EP9_MAIN_STORY_CLEAN_ANIMATIC_720P_V3_CONTACT.png`

The dark slates in this animatic are honest missing-picture markers. They are not intended for the final episode.

Builders:

- `studio/src/Kuku_Ep9FastRoughAnimatic.res`
- `studio/src/Kuku_Ep9FastGuideProxy.res`
- Review-only overrides: `stories/kuku/ep9prod/finale/review/EP9_ROUGH_ANIMATIC_OVERRIDES_V1.json`

`npm run build` passes. Existing warnings are unrelated unused-value warnings.

## Audio state

The V3 animatic already carries 138 existing original-cast guide clips across the 12-minute story. It uses approximately 7:48.5 of speech and leaves approximately 4:11.5 for action and pauses.

This is guide dialogue, not the final music-and-effects mix. Do not reopen the dialogue-alignment project before picture lock.

Useful audio paths:

- Main guide dialogue: `stories/kuku/ep9prod/finale/review/EP9_MAIN_STORY_GUIDE_DIALOGUE_V1.m4a`
- Latest cold-open mix: `stories/kuku/ep9prod/coldopen/audio/out/EP9_COLD_OPEN_FULL_MIX_f44e2b00a2e5.wav`
- Cold-open picture: `stories/kuku/ep9prod/coldopen/out/KUKU_EP9_COLD_OPEN_V1.mp4`
- Table-read plan: `stories/kuku/ep9prod/ep9_table_read_plan_v2_dream.json`
- Six guide-only review lines: `stories/kuku/ep9prod/finale/audio/EP9_DIALOGUE_MANUAL_REVIEW_kuku-ep9-finale-dialogue-v5-candidate-content-bound.json`

## Good zero-Higgsfield replacements completed

### Chest discovery

The rejected flat chest/safe clip has been replaced. The new staging clearly shows pink Leda pointing out the hidden latch and yellow Castor pressing it while remaining outside the chest.

- Master still: `stories/kuku/ep9prod/finale/references/C08_chest_discovery_native_v1.png`
  - SHA-256: `4640fe24cd611a2fcfa92aac8926193633288524c56527b0f36ab630ccf591e6`
- Ten-second local move: `stories/kuku/ep9prod/finale/local/C08_chest_discovery_native_move_v1.mp4`
  - SHA-256: `2e2468d6f806f7022065cbcb8551abdb3c641cd546a91e099ac582f104ec7895`

### Dimensional rescue `ब`

This replaces the rejected flat white panel/sticker look. It shows five separate youthful large dragons holding one thick golden `ब`, with the goat visible in its inner route and wingless Rishi by the cracked gate.

- `stories/kuku/ep9prod/finale/references/FFR_rescue_b_dimensional_native_v1.png`
- SHA-256: `4d8a5b0e338d8527156becaa8deda6b33676f1123376d4fde5632c52c91660c5`
- Normalized motion start: `stories/kuku/ep9prod/finale/finish_fast/start_frames/FFR01_rescue_b_dimensional.png`
- SHA-256: `d030ee8026dcf853f84503f9de5ad563540e85953182fa72c7c23d86b6057cc5`

### Gate approach

This was generated natively after the prior turn was interrupted. It shows all five transformed trainees approaching the repaired gate, wingless Rishi beside it, the tether attached, and the Gurukul cloud road visible through the threshold.

- Master: `stories/kuku/ep9prod/finale/references/FFR04_gate_approach_native_v1.png`
- SHA-256: `aeac1ba7da0c2e00bf6d8a89d5cbf17e7e851aee469788848e0a2136b16ec42c`
- Normalized start frame: `stories/kuku/ep9prod/finale/finish_fast/start_frames/FFR04_gate_approach.png`
- SHA-256: `cb02d1eaa39d3402cc86db123501102fb0e70d341f7e6f19a6284ef1fb566a1a`

The remaining-five proposal still marks the gate-crossing shot blocked because it was written before this image existed. The next model may patch that proposal to use `FFR04_gate_approach.png`; do not regenerate the start frame.

## Assets that must not be used

- `stories/kuku/ep9prod/finale/references/A05.png`
- `stories/kuku/ep9prod/finale/references/A05_attempt2.png`
- `stories/kuku/ep9prod/finale/clips/B05.mp4`
- `stories/kuku/ep9prod/finale/clips/candidates/D02_attempt1.mp4`

These encode the withdrawn Kuku-first transformation in which equal bracelets produce unequal growth.

Also reject from final picture:

- `stories/kuku/ep9prod/finale/clips/C08.mp4` — flat chest and fake 2D movement
- `stories/kuku/ep9prod/finale/clips/B11.mp4` — goat/cloud composite fails causality and looks artificial
- `stories/kuku/ep9prod/finale/clips/B15.mp4` — flat sticker-like `ब` rescue

`B14` is only an instructional/tactical animatic insert, not final cinema.

## Finish-fast generation package

The complete prepared first-pass plan is nine paid video shots. The chest shot was removed from the paid list because the native/local replacement works.

Prepared proposals:

- `stories/kuku/ep9prod/finale/finish_fast/ep9_finish_fast_priority_batch.proposal.v1.json`
- `stories/kuku/ep9prod/finale/finish_fast/ep9_finish_fast_remaining_five.proposal.v1.json`

All prompt files are in `stories/kuku/ep9prod/finale/finish_fast/prompts/`. Start frames are in `stories/kuku/ep9prod/finale/finish_fast/start_frames/`.

### Priority group

1. `FF01_EQUAL_FIVE_TRANSFORMATION` — Gemini Omni, 8 seconds, recorded ceiling 24 HF credits.
2. `FF02_SHARED_FIVE_TAKEOFF` — Veo Lite, 8 seconds, recorded ceiling 8. This must wait for the accepted final frame of FF01.
3. `FF03_RISHI_GOAT_ORBIT_CONNECTION` — Hailuo 2.3 Fast, 10 seconds, recorded ceiling 7.
4. `FF04_LEDA_STOPS_FAILED_RESCUES` — Kling 2.6, 10 seconds, recorded ceiling 10.

Priority first-pass ceiling: 49 HF credits.

### Remaining group

1. `FFR01_CASTOR_INSIDE_B` — Kling 2.6, 10 seconds, ceiling 10. Use the dimensional `ब` start.
2. `FFR02_RESCUE_SETTLEMENT_GOAT_LANDING` — Kling 2.6, 10 seconds, ceiling 10. Use the dimensional `ब` start.
3. `FFR03_LEDA_INDEPENDENT_TRANSFORM` — Kling 2.6, 10 seconds, ceiling 10.
4. `FFR04_FIVE_TRAINEES_THROUGH_GATE` — Veo Lite, 8 seconds, ceiling 8. Use `finish_fast/start_frames/FFR04_gate_approach.png`.
5. `FFR05_GURUKUL_CLOUD_REVEAL` — Hailuo 2.3 Fast, 10 seconds, ceiling 7. Use `finish_fast/start_frames/FFR05_gurukul_full_cloud_veil.png`.

Remaining first-pass ceiling: 45 HF credits.

Total first-pass ceiling: 94 HF credits. Do not automatically retry anything. Review every result silently and in its neighboring cut. FF02 is conditional on FF01 acceptance.

## Provider and approval state

No paid provider job is running.

The route file currently has an active all-paid submission hold:

- `stories/kuku/ep9prod/finale/manifests/ep9_finale_route.v2.json`

A live quote attempt for the first batch was blocked before it reached Higgsfield because the current approval system requires a fresh explicit user approval to send these unpublished Kuku prompts and reference images to Higgsfield. No prompt was sent and no credit was spent.

Before any external quote/upload/submission, ask the user for this narrow approval:

> I approve sending the fictional Kuku Episode 9 prompts and reference images for FF01, FF03 and FF04 to Higgsfield, and spending up to 41 Higgsfield credits for one attempt of each. Do not retry automatically.

After that approval:

1. obtain a fresh exact quote for each of FF01, FF03 and FF04;
2. stop if any quote exceeds 24, 7 or 10 respectively;
3. submit one attempt each;
4. inspect the outputs with sound off before doing anything else;
5. if FF01 passes, extract its exact final frame and prepare FF02;
6. if any result fails, do not retry without reporting the specific failure.

## Credit/account notes

The user's 33% comment was about LLM credits. Do not conflate it with Higgsfield again.

For reference only, the last read-only Higgsfield audit found:

- balance: 1,258.12 HF credits;
- known Episode 9 HF spend: 1,334.1;
- cold-open video/boards/audio: 1,141.1;
- main-story/finale tracked spend: 193;
- 70 of the 193 main-story credits produced discarded results;
- no queued or running HF job.

These figures explain prior waste but should not trigger another audit.

## Exact next workflow

1. Do not re-read every historical artifact. Start with the V3 clean cut and the two finish-fast proposal files.
2. Patch only the FFR04 proposal entry to use the already-created gate approach frame.
3. Obtain the narrow external-provider approval quoted above.
4. Generate FF01, FF03 and FF04 once each.
5. Put accepted results into the 12-minute cut immediately and show the new sequence.
6. Generate FF02 only from FF01's accepted endpoint.
7. Generate the remaining five only when their neighboring states are locked.
8. Assemble the 12-minute main story, then prepend the 2-minute cold open and 15-second title.
9. Add music and effects only after picture lock. Use the existing original-cast dialogue.
10. Deliver a phone-friendly fast-start proxy after every meaningful assembly pass.

## Operational rules for the next model

- No technical banner over usable footage.
- No long status prose instead of a visible artifact.
- No more bespoke ReScript mini-frameworks for individual shots.
- No provider generation before exact prompt/reference/cost approval.
- No automatic retries and no third attempts.
- No scene may be accepted in isolation if the incoming or outgoing state does not match.
- A still may carry dialogue, but action, transformation, flight, rescue and the Gurukul reveal require visible motion.
- Preserve the dirty worktree. Do not reset, delete, or clean unrelated files.
- The entire `stories/kuku/ep9prod/finale/` tree is currently untracked in Git; do not mistake that for disposable work.

## Current completion truth

The episode is not finished. What is finished is:

- the approved two-minute future-dream cold-open picture;
- a complete clean 12-minute main-story animatic with original-cast guide dialogue;
- the corrected equal-transformation story rule;
- the dimensional chest replacement;
- the dimensional rescue-`ब` master;
- the gate-approach master;
- exact prompts and start frames for the remaining essential motion shots.

The remaining job is production and assembly, not more planning.
