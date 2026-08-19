# Echo and the Broken Bonds — Runtime Test Envelope v1

This envelope limits what a passing build may claim. It is not child testing and makes no claim about learning, appeal, or devices that were not exercised.

## Named local lane

- Hardware class: Mac Studio, Apple M2 Ultra, 24 CPU cores, 64 GB memory.
- OS: macOS 26.4.1, build 25E253.
- Browser/controller: headed Google Chrome for Testing 143.0.7499.4, Chromium revision 1200, driven by Playwright 1.57.0. `browser-lock.json` records the absolute binary, executable/core-framework/app-tree SHA-256 values, launch arguments, and context settings. Every run recomputes and verifies them before navigation.
- Viewports: 1280×720 and 1366×768 at device scale factor 1.0; landscape pointer and emulated touch runs.
- Refresh target: 60 Hz.

Because this is powerful desktop hardware, passing this lane alone authorizes only the phrase **“verified on the named Mac Studio lane.”** It does not authorize “runs on any computer/tablet.”

## Constrained browser lane

The same release candidate must also pass with a fresh temporary profile, cache/storage cleared, Chromium CDP CPU slowdown fixed at 4×, and the locked network profile: 80 ms latency, 10 Mbps down, 5 Mbps up, and 0% packet loss. The whole browser process tree must remain below 4 GiB peak RSS; this is a measured hard-fail threshold, not a claim that RAM has been physically restricted. Exact CDP calls, values, browser bytes, launch flags, viewport, device scale, and capture state come from `browser-lock.json` and are recorded for every run. This is a stress proxy, not a substitute for a real lower-end device claim.

## Build and load budgets

- Production/release build only; debug overlays off except the evaluator-log capture channel.
- Initial compressed transfer at most 25 MB; complete playable compressed transfer at most 60 MB.
- Cold title-screen interactive in at most 5.0 seconds on the named local lane after cache/storage clear.
- Warm title-screen interactive in at most 2.0 seconds.
- On the constrained lane, cold title-screen interactive in at most 8.0 seconds and warm title-screen interactive in at most 3.5 seconds.
- No missing/fallback/unknown-rights asset may load. Packaged dependency closure and runtime asset-use telemetry must agree.
- No scrollbars, cumulative layout shift, font swap, missing frame, audio start pop, or unexpected network request during the captured run.

## Runtime budgets

- Climax p95 frame time at most 18.2 ms; p99 at most 25 ms; no single non-load hitch over 50 ms on the local lane.
- At least 55 delivered frames per second through the measured climax window on the local lane.
- Pointer-down to visible input response p95 below 100 ms.
- Snap response at most 150 ms; every release response at most 250 ms; visible world consequence begins at most 500 ms.
- Post-GC used JavaScript heap at or below 500 MB after one complete run and every one of ten replays, and the bounded leak test below passes.
- Audio-output/visual-cue/caption-paint pairwise drift stays within 80 ms over a complete playthrough.
- On the constrained lane: climax p95 frame time at most 33.3 ms; p99 at most 50 ms; no single non-load hitch over 100 ms; at least 30 delivered frames per second; pointer-down to visible input response p95 below 150 ms; post-GC used JavaScript heap at or below 600 MB after one complete run and every one of ten replays; the same bounded leak test; browser process-tree peak RSS below 4 GiB; and zero console errors, missing resources, or evaluator failures. The 150/250/500 ms snap/release/world-consequence limits and 80 ms three-clock drift limit do not relax.

Capture overhead is never used for performance scoring. Each candidate needs raw unedited evidence and a separate no-recording performance run tied to the same `content_id`, source bytes, asset closure, test-system ID, and precommitted session.

## Canonical duration and measurement algorithms

- **Canonical trace duration:** start on the first fully rendered Gate Plaza frame after the Play commit (`slice.trace.start`); end after the final Echo-departure image has remained unobscured for two seconds (`slice.trace.end`). The precommitted no-idle input trace must measure `414.0±3.0` seconds. Title/loading time and voluntary safe waits are excluded; no authored animation, dialogue, beat, or hold may be skipped to meet the range.
- **Climax window:** every `requestAnimationFrame` interval from the first frame carrying `slice.navigation.both_ready_visible` through the last frame carrying `slice.navigation.two_clamp_hold_complete`, inclusive. No frame inside this window is discarded. Nearest-rank percentiles use the sorted interval list and index `ceil(p×n)`; the worst is `max`; delivered FPS is `(frame_count-1)/(last_frame_time-first_frame_time)×1000`.
- **Hitch:** any rAF interval above the lane limit after `title_interactive`. Only intervals explicitly inside browser navigation before `title_interactive` are load intervals. Asset/network activity during gameplay is not reclassified as load.
- **Cold/warm interactive:** `performance.timeOrigin` to the first frame where the title is fully painted, Play is enabled, required fonts/assets are final, and input receives a visible response. Cold uses a fresh temporary profile plus empty HTTP cache/storage; warm is one reload of the identical package in the same profile.
- **Input latency:** trusted event `performance.now()` to the first rAF whose rendered-world projection hash includes that input sequence number. Report every sample and nearest-rank p95; no coalesced or failed event is omitted.
- **Snap/release/consequence:** the same input timestamp to, respectively, registered target-lock state, first literal response frame, and first changed world-projection frame. Exact definitions are instrumented in the frozen harness.
- **Memory:** CDP `HeapProfiler.collectGarbage`, then `Runtime.getHeapUsage`, creates `sample_0` after the baseline complete run and `sample_1` through `sample_10` after each of ten replays. The bounded leak test fails if `sample_10` exceeds `sample_0` by more than 20 MB **or** 10%, or if the least-squares slope over all eleven ordered samples exceeds 2 MB/replay. This is a bounded-noise tolerance, not a claim of mathematically zero growth. Whole-browser RSS sums the locked browser root and descendants sampled every 100 ms; peak is the maximum sum.
- **Audio/visual/caption drift:** each cue ID records predicted audible-output performance time from `AudioContext.getOutputTimestamp()`, first matching visual-cue paint rAF, and first matching caption-paint rAF. Report signed/absolute audio↔visual, audio↔caption, and visual↔caption differences for every cue plus each maximum. All three pairings stay within 80 ms. Raw capture waveform/frame inspection independently spot-checks at least five precommitted cues.

The complete test/capture/metrics harness, runtime, commands, percentile code, process-tree sampler, and input traces are hashed before the first scored run under `candidate-evidence.md`. A changed algorithm or harness resets the streak.

## Interaction/state verification

- Each lane requires **twenty consecutive** complete deterministic runs in one precommitted scored session: an alternating, seed-frozen ten left-first and ten right-first sequence. Every attempt and failure is retained; a failure ends that session and cannot be replaced by a later run under the same scored nomination.
- Rapid touch/pointer fuzzing around both nested controls proves no buffered second Deploy and no double reduction.
- Quit/rejoin is exercised from `NESTED_READY_BOTH`, `FIRST_LEFT_DEPLOYING_COMMITTED`, `FIRST_RIGHT_DEPLOYING_COMMITTED`, both `FIRST_SIDE_RESOLVED(side)` states, both `SECOND_*_DEPLOYING_COMMITTED` states, `TAVI_SAFE_PRE_SAMPLE`, and `TERMINAL_AFTERMATH`; `test-oracle.md` supplies the exact expected state and forbidden transitions.
- Captions, mute, keyboard focus, touch emulation, reduced-motion, grayscale, and color-independent cues are checked in both viewports.
- Console warnings count as defects unless an explicit harmless allowlist entry is frozen before the run; errors, unhandled rejections, missing resources, and evaluator invariant failures are always zero-tolerance.

## Unlocked future lane

A real representative tablet or modest laptop should be named before any broader shipping-readiness claim. Adding that lane does not require child participation, but it does require the physical device/browser version and fresh evidence.

## Streak reset

Any change to the browser bundle, controller, OS, launch flags, viewport, device scale, network/CPU settings, runtime content bytes, or measurement method creates a new envelope and resets all consecutive passes. A failing lane cannot be replaced mid-streak with an easier configuration.
