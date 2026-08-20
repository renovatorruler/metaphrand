# Frosya composable alphabet

This directory contains the locked handwriting reference for Frosya's 33-letter uppercase Russian alphabet and the production-ready assets needed for Episode 1.

## Canon

- The handwriting is based on approved exploration sample 5, including its hooked, quirky `Л`.
- All smudges and pencil dust belong to the glyph itself. There is no paper texture inside an individual letter asset.
- The graphite letter is the master geometry. Ignition and magical states are derived from its alpha mask and are never redrawn.
- Every individual asset is a 2048 × 2048 transparent RGBA PNG.
- Every asset uses anchor `(1024, 1430)` and baseline `1430`.
- The outer 307 pixels on every side remain fully transparent.
- The flat compositing paper is exactly RGB `(244, 225, 192)` / `#F4E1C0`.

## Current scope

The complete 33-letter handwriting canon is locked in `masters/full_alphabet_reference_v1.png`.

Episode 1 has six production states for these eight letters:

`А О М С К Т Л Б`

The six states are:

1. `graphite`
2. `ignite_25`
3. `ignite_50`
4. `ignite_75`
5. `ignite_90`
6. `magic`

That is 48 production PNGs. The remaining 25 letters still need to be isolated from the locked reference and passed through the same deterministic pipeline.

## Rebuild and verify

From `studio/`:

```sh
rescript && node src/Drakosha_FrosyaAlphabet.res.mjs build
rescript && node src/Drakosha_FrosyaAlphabet.res.mjs verify
```

`build` recreates the exact flat paper and all 32 derived ignition/magic assets from the eight graphite masters. `verify` checks file presence, 2048 × 2048 RGBA format, and the required transparent safety border.

## Useful previews

- `previews/graphite_ep1_contact_sheet.png`
- `previews/magic_ep1_contact_sheet.png`
- `previews/magic_ep1_on_paper_contact_sheet.png`
- `previews/ignite_90_ep1_on_paper_contact_sheet.png`
- `previews/graphite_magic_registration_ep1.png`
- `previews/С_ignition_progression.png`
- `previews/graphite_word_composites.png`
- `previews/magic_word_composites.png`

The word composites cover `СОК`, `КОТ`, `ОСА`, and `МАМА`.

`ignite_75` retains the earlier luminous-graphite treatment. `ignite_90` preserves the cleaner neon-like version: one continuous white core inside a clearly defined gold envelope. Full `magic` is a separate, reference-matched phase change. Its handwritten stroke remains fully continuous and stable. A thin warm-white core sits inside a softly diffused gold body, with broad honey-amber bloom and four particle scales around it: fine amber dust, gold motes, pale hot motes, and rare soft white flare points. Low-frequency modulation changes the brightness subtly without creating gaps or broken sections. No graphite remains visible at full magic. The treatment is designed and tested on the exact canonical light paper and the dark magical-space background. All public demo previews use the canonical `#F4E1C0` paper; black appears only in technical alpha QA.

## Source and extraction note

The two reference sheets were generated with ChatGPT's native image generation, not Higgsfield. The Episode 1 source panel visually represented transparency with a baked checkerboard rather than a real alpha channel. Its letter strokes were therefore isolated by luminance, placed on true transparent canvases, normalized only for scale/anchor/baseline, and then frozen. The checkerboard is not present in any production asset.

See `manifest.json` for machine-readable paths and metadata, and `prompts/` for the generation specifications.
