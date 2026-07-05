# Frame look + shot grammar — production-engine standard (AMAL series)

Approved 2026-06-23. The visual standard for AMAL's stills-and-audio films. Reference implementation:
`stories/amal/frame_style_samples.py` (the SUF / film-stock knob), `stories/amal/ep2_frames_v2.py` (the
per-shot prompts + the `SHOTS` play-order map), `stories/amal/ep2_assemble_v2.py` (the multi-shot assembler).

## 1. The look (the SUF suffix, every frame)
- **Film stock: Kodak Portra 400** — fine organic grain, soft natural contrast, gentle natural warmth, true
  skin tones. (The stock is a swappable knob; Portra is the chosen one. We A/B'd Fuji Pro 400H — too
  airy/lifestyle for a crime drama.) **NEVER** a heavy yellow/amber "piss-filter", sepia, or teal-and-orange.
- **Grounded realism** in the register of **Kohrra / Delhi Crime / Paatal Lok** — naturalistic available light.
- **Backgrounds VISIBLE with depth** — the room/landscape reads behind the figures, **never swallowed by
  black** (this killed the old Old-Master tenebrism). Even night scenes are lit by headlamps/moonlight/sodium —
  *legible, not a black void.*
- **Medium and WIDE framing** — people IN their world; close-ups reserved for the `_a2` angles.
- **The world is the PROSPEROUS opium belt with real money** — clean functional ordinary places, outright
  affluence at the big houses. **NOT** a slum, NOT dire poverty, nothing derelict. (The story's engine is
  obscene casual cash, not destitution.)
- **CLOTHING is clean and matches station** — the wealthy in crisp pressed kurtas; ordinary people neat;
  nobody filthy/threadbare.
- **CANDID, never posed** — every shot is a caught, in-the-moment film still; characters are absorbed in the
  scene, NEVER posing for or smiling into the camera. (The "posed studio photo / smiling at the lens" is an AI
  tell that breaks the scene — e.g. Bherulal must not stand grinning arm-in-arm with Ratan like a holiday snap;
  his warmth is oily and Ratan is cold.)

## 2. The shot grammar (kills the "teleporting cut" — come close to a shooting script)
Per scene, a play-order list of shots in `SHOTS = {scene: [names]}`:
- **`_est` — establishing shot.** A wide "we're here now", held ~2.5–3s as the scene opens. On every
  location's first appearance + recurring ones (home, workplace, the morgue, the big houses, the ghat).
- **`scNN` — the main shot.**
- **`_a2` — second/closer angle(s).** A tighter cut inside long scenes so the picture tracks the audio instead
  of one frozen image. (The Rana durbar got 4 angles across its length.)
The assembler (`shot_windows`) gives the EST a fixed lead, splits the remaining scene time across the rest, and
composites the subtitle onto whichever shot is up.

## 3. Still-open polish
- **Narration bridges** — 2–3 short सूत्रधार "on arrival" lines where geography hard-jumps. Held back so the
  approved audio/score/subs aren't re-rendered; add only if a jump still reads with the EST shots in.
- Soft inter-scene dips (the EST shots currently carry the transition; the cold-open→title keeps its full
  recipe — see `TRANSITIONS.md`).
