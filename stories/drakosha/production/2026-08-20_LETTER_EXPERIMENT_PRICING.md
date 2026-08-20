# The letter experiment — what it costs (2026-08-20)

The shot: a locked overhead start frame we author ourselves — correct tiles, correct letters, finger already in place — and the model told only to walk the finger along the row, lighting each tile as it is touched. No sound needed. No dialogue.

All prices below are from `higgsfield generate cost` on our own account today, not from memory. Balance at time of pricing: **4,946 credits**.

## The models that can do it

| model | 5s | notes |
|---|---|---|
| **kling2_6, sound off** | **5.0** | start image. Sound on doubles it to 10, and we do not need sound. |
| kling3_0_turbo, 720p | 7.5 | start image. 1080p is 10. |
| **kling3_0, std, sound off** | **7.5** | **start image AND end image** — the only one that takes both. |
| grok_video | 7.5 | start image only. |
| kling3_0, pro | 8.75 | |
| grok_video_v15, 480p | 12.5 | |
| grok_video_v15, 720p | 22.5 | |
| kling3_0, 4k | 30.0 | |

For comparison, what we have been shooting on: **seedance_2_0_mini at 5s costs 12.5**. Kling 2.6 with sound off is **two and a half times cheaper** than our default, and Kling 3.0 with both frames pinned is still cheaper.

Adding an end image to kling3_0 does not change the price — 7.5 either way.

kling3_0 also takes arbitrary durations, not just 5 and 10: **3s costs 4.5**, 7s costs 10.5. A three-second finger walk is a legitimate shot and the cheapest test on the board.

## The experiment as a bake-off

Three runs, the same authored start frame, the same instruction:

| run | model | what it tests | credits |
|---|---|---|---|
| A | kling2_6, 5s, sound off | can a start frame alone hold eight tiles and their letters | 5.0 |
| B | kling3_0, 5s, std, sound off, **start + end frame** | does pinning both ends hold the letters through the middle — the author's own hypothesis | 7.5 |
| C | grok_video, 5s | a different family entirely, in case the failure is Kling-shaped | 7.5 |
| | **total** | | **20.0** |

Twenty credits answers the question that has cost us a scene's worth of rework. If it is worth trimming further, run B alone at 3 seconds for **4.5**, since B is the hypothesis that actually matters.

## What the test must be judged on

Not "do the letters look right in a frame". That is how the last conclusion went wrong. The three failures to watch for, all of them temporal:

1. **glyph drift** — does `Б` stay `Б` from first frame to last, or become `6` on the way
2. **count drift** — are there still exactly eight tiles at the end
3. **the pointing** — does the finger arrive at the tile the light is on, on every one of them

Judge it by stepping the whole clip, not by sampling.
