# The Performance Doctrine — directing the table-read

The table-read renderer (`Cinema_SkySceneRead`) reads an optional per-scene
overlay `<id>.perform.json` — `{ "<lineIndex>": "[tag][tag]" }` — and prepends
eleven_v3 expression tags at RENDER time only. The scene text and its receipt
hash stay clean; the direction is a saved, per-line, editable artifact. Retakes
are surgical: change one line's tag, only that line re-renders, the rest replays
from cache.

## The direction law (user, 2026-07-02 — after two voices were rejected as
"weird breathy talking; ATC people don't talk like that")

**Tension ≠ quiet.** Soft tags on professionals render BREATHY and read as chill
exactly when the room should be anxious.

1. **Procedure plays UNTAGGED.** Hails, clearances, readbacks, orders, briefings
   — the phraseology carries itself. No tag is the crisp read.
2. **Reactions get [tense] / [serious] / [surprised].** The anxiety of pros is
   controlled tightness, never softness. A room under threat gets TIGHTER, not
   quieter — but that tightening is carried by these tags, not by [quietly].
3. **Soft tags belong to soft characters only.** [quietly], [softly], [calm],
   [gently] are reserved for the gentle voices — BIRDY (sad-cheerful, halting),
   MAYA (plain, tired), DORIS — plus the NARRATOR (action lines), whose quiet
   carries still beats and endings ([quietly], [quietly][slowly]).
4. **Whispering is staging, not direction.** A private aside marked in the
   SCRIPT as `(WHISPER)` renders with the real whisper treatment automatically.
   Never fake it with a perform tag.
5. **Birdy's palette:** [softly], [nervous], [hesitant], and an occasional
   [sighs] breathed before an owning-up line. Never [excited], never performed.
6. **Sparseness is direction too.** A breather scene tags almost nothing; the
   most emotional line in a scene often lands hardest UNTAGGED between two
   tagged neighbors. Do not paint every line.

## Working vocabulary (validated on eleven_v3)

- Crisp/pro: (no tag), [tense], [serious], [surprised]
- Soft (allowlisted characters + narrator): [quietly], [softly], [hesitant],
  [nervous], [sighs], [slowly]
- Color, use sparingly: [curious], [bored] (pre-tension routine only)

## Enforcement

- The renderer REFUSES to render any named speaker without a deliberate cast
  voice in `voiceFor` (no default voices for named characters — user law; the
  PA system voice is allowlisted).
- The renderer LINTS the overlay: a soft tag on a non-allowlisted character's
  dialogue prints `PERFORM LINT: …` naming the line. It warns rather than
  fails — taste can override — but an override should be a decision, not a slip.
- Delivery effects are per-line: clean / radio (aviation comms) / PA (tannoy:
  boxy band + terminal slapback). Fighter pilots (DEACON, BANJO) and TOWER are
  always radio; `(RADIO)`/`(WHISPER)` tags in the script drive the rest.
