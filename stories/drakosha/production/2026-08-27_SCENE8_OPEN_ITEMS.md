# Scene 8 — open items, parked 2026-08-27

Scene 8 is delivered: 24 shots, 201.06s, SH102–SH136 plus SH119 on the end. Manifest is `kuku_flow/SCENE8_ASSEMBLY.txt`, current cut is `seedance_batch/output/2026-08-27_SCENE8_assembly_v25.mp4`. Nothing below blocks moving on to scene 9; all of it is improvement work on shots that already play.

## 1. The re-record pass — the largest single win

The renders speak about 30% longer than the recorded lines, so several dubs sit loose against the mouths. Measured, render against recording: V08 celebration 3.90s vs 2.50s, V08 complaint 3.35s vs 2.81s, V09 plea 4.72s vs 4.32s. V11 is the one that matched — 1.55s of render against 1.52s recorded — and it is the only dub in the block that needs no allowance for it.

The fix is to re-record the affected lines against the measured speech-run durations as targets rather than reading them at natural pace, then re-dub with the existing speech-run method. This is ElevenLabs time, not video credits. Affected: V08 (both lines), V09, V10.

## 2. V07 — the table turns, SH125-127. NOT APPROVED

Staging is right, performances are wrong: all three adults wear the same worried face and Мама reads angry where she should read dry. It is in the cut because it is comprehensible and the scene needed to move. Full defect list and reshoot brief: `seedance_batch/2026-08-26_V07_DEFECTS_reshoot-brief.md`. Roughly 37.5 credits at 15s on mini.

## 3. Точка seal — SH108, the СОК seam

Visible seam where СОК resolves. Plays, but it is the one shot worth a re-roll if there is ever spare allowance. Roughly 12.5 credits.

## 4. Яга's closing shot — two versions exist

`2026-08-27_SH119_yaga_dub.mp4` (3.29s, opens on the sip) is in the cut. `2026-08-27_SH119_yaga_dub_tight.mp4` (2.12s, opens on the cup coming down) exists if the ending ever wants to be quicker. Also `2026-08-27_SH119_yaga_v1_trim.mp4` carries the model's untouched audio if the pitched hum is ever judged wrong — the pitch was set by ratio, not by measurement, because the f0 detector does not track a sustained hum.

## 5. Two shots would fail the negated-direction gate on re-emission

s8loopB/C/D/E each contain "Nothing appears in the empty left side of frame". They are delivered and fine. If any is ever re-emitted, `assertNoNegatedDirection` will refuse it until that line is restated as a positive range. That is correct behaviour, not a bug.

## 6. Everything is 720p and stays that way

`seedance_2_0_mini` offers 480p and 720p only. 1080p and 4k exist on `seedance_2_0` at 18/36/88 credits for 4s against mini's 10. Author, 2026-08-26: "I don't care about redoing it. I'm fine with that resolution." `bitrate_mode: high` is now set on the submit path — it prices identically to standard and cuts the compression mush that makes delivered frames poor plates.
