# Frosya Composable Alphabet — Handoff

Updated: 2026-08-23

## Current production state

- Episode 1 letters: `А О М С К Т Л Б`.
- Each letter has graphite plus `ignite_25`, `ignite_50`, `ignite_75`, `ignite_90`, and full `magic` states.
- The graphite PNG remains the geometry master for the four ignition states.
- The eight accepted full-magic PNGs are frozen locally in `exports/frosya_ep1_alphabet_v1.zip` and restored byte-for-byte during production builds.
- The full-magic `А` was restored from that archive after an experimental multi-trace version made it inconsistent with the other seven letters. The user approved the restored consistency on 2026-08-23.

Canonical full-magic `А` SHA-256:

```text
a26add0aaf9841f538c7df5359c229d1f59d876bc7c1931334894b853514108a
```

The hashes for all eight full-magic assets are enforced in `studio/src/Drakosha_FrosyaAlphabet.res`.

## Important repository constraint

Generated media and archives (`*.png`, `*.zip`) are intentionally ignored by the repository and must not be force-added. They remain in the shared production workspace. Do not replace `assets/magic/А.png` with a glow experiment. Experimental variants belong only under `qa/glow_lab` or `qa/iterations`.

## Rebuild and verification

Run from `studio/`:

```sh
npm run build
node src/Drakosha_FrosyaAlphabet.res.mjs build-magic-a
node src/Drakosha_FrosyaAlphabet.res.mjs verify
node src/Drakosha_FrosyaAlphabet.res.mjs background-preview
```

`build-magic-a` restores the canonical `А`. `verify` checks geometry and exact hashes for all eight locked full-magic assets. The comparison preview is written to:

```text
stories/drakosha/production/alphabet/frosya/previews/magic_ep1_light_vs_dark_brown.png
```

Automated checks establish file integrity only. The user remains the final visual approval gate.
