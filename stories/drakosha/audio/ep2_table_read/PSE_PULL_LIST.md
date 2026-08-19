# «Фрося и Вася» EP2 English table read — SFX source resolution

The selective SFX plan no longer requires a library pull before mixing:

- Magic appearances use the canonical Drakosha `chime.mp3`.
- Bell tones use the existing `glint_chime.mp3`, with the canonical Drakosha
  chime as its configured fallback. The licensed local PSE dice-roll asset adds
  the small-metal rolling body when the bell escapes across the boards.
- A literal wolf howl is deliberately omitted. The narrator and Vasya's vocal
  performance carry that beat without competing animal audio.

The source paths and fallback behavior are authoritative in
`ep2_sfx_plan.json`.
