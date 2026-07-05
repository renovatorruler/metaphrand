# AMAL Rudaali library — DRAMATIC B theme sources (series-level, reusable)

The Rudaali (रुदाली) lament is AMAL's fixed DRAMATIC B theme: a solo Rajasthani female voice
keening wordless grief (the priced girl / the silenced mother). User-provided source recordings.
**These are the one cue whose sound is fixed by the user — do not regenerate; treat and place.**

## Tracks

| file | len | mean / peak | what it is | intended use |
|---|---|---|---|---|
| `../amal_score_rudaali_processed.mp3` | 37.0s | −21 / −9.5 dB | the LOCKED Ep2 theme — user's original `rudaliindian.mp3` run through the taming chain | **in use, Ep2** (Sc1, Sc4, Sc11), featured & very soft |
| `rudaali_indian_v2_long_with-outro.mp3` | 62.4s | −17.2 / −1.2 dB | longer cut of that same recording, with an **instrumental + percussion outro** tail | future episodes (the outro tail suits a scene that resolves into motion) |
| `rudaali_emotional_outro.mp3` | 151.8s | −15.5 / −0.5 dB | a separate, **more emotional** take | an **episode OUTRO** (which episode TBD) |

## Before use — the taming pass (REQUIRED)

The raw sources peak near 0 dBFS and "get louder / can be overpowering" (user). Apply the same
chain used to make `amal_score_rudaali_processed.mp3` before placing under any scene:
- `acompressor` to tame the dynamics (the wail swells hard), then
- convolution hall reverb (`afir` with a synthesized pink-noise IR, exp decay) to set it back in space.
Then place it **featured and soft** — score the turn, not wall-to-wall (it carries grief, never guilt;
keep held cards buried).

## Provenance
Originals uploaded by user 2026-06-22 (`acfb1aac-rudaliindian_2.mp3`, `acd178e7-rudali.mp3`);
first Rudaali source was `016039f6-rudaliindian.mp3` → processed to `amal_score_rudaali_processed.mp3`.
