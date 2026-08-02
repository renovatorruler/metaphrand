# Ep5 build baseline

Recorded from the reviewed, published Python build on 2026-07-29, then used to prove
the ReScript port (`studio/src/Kuku_Assemble.res`) equivalent.

## What is in here

- `durations.txt` — every scene, every segment, and the episode, as
  `<file>.mp4 <seconds>`. This is the regression oracle. `Kuku_Verify.checkDurations`
  reads it; `node src/Kuku_VerifyEp5.res.mjs` fails the build on any drift.
- `framehash.txt` — sampled frame hashes. **Only the `t*` (video) lines are
  meaningful.**

## What is NOT reproducible, and why

**Audio is not bit-reproducible. Do not treat an audio hash as a regression signal.**

`amix` sums many float streams and the summation order varies between runs, so two
runs of *identical* code produce audio differing by about one 16-bit LSB. Measured:

| comparison | max difference |
|---|---|
| same code, run twice | −90.3 dB |
| Python build vs ReScript port | −90.3 dB |

Both sit at the noise floor — the port is equivalent, and the run-to-run wobble is
inaudible.

A previous investigation measured "−3.1 dB" between the two builds and briefly looked
like a real defect. It was an artifact of the comparison: subtracting two *AAC-decoded*
streams whose encoder priming differs by a sample compares a loud signal against a
slightly shifted copy of itself. Compare the WAV stage (`build/<scene>_dlg.wav`), not
the muxed mp4, and compare the generated filter graph rather than the samples.

## Proving the assembler after a change

The decisive check is the filter graph, not the waveform:

```
KUKU_DUMP=/tmp node src/Kuku_AssembleEp5.res.mjs      # writes /tmp/res_fc_<scene>.txt
diff /tmp/res_fc_s1.txt <reference>
```

Video **is** deterministic: the picture streams were byte-identical across the port
(`ffmpeg -i x.mp4 -map 0:v -f md5 -`), and all 128 durations matched.
