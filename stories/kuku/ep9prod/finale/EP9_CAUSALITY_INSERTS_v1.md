# Episode 9 — the causality gap, and the fix

Drafted 2026-08-18 against `2026-08-11_EP9_ba_bada_BEATSHEET.md` (lines 19, 127–131, 171–182)
and the shipped `ep9_finale_animatic_edl.v4.json`.

The parent's note: *"Honestly, the script is weak, I have no idea why is the gurukul door weak,
why do they need to make bigger letters… What's this deal with the baby goat, it never
explains it."*

## Finding: the script is not weak. The picture never shows what the script says.

I checked every beat's `storyEvent` against what the animatic actually renders for it. The
causal chain is fully authored in the EDL. Three of its load-bearing beats are wired to
pictures that do not contain the event.

| beat | what the EDL says happens | what the cut actually shows |
|---|---|---|
| `S01-B03` (S3, 2s, silent) | the echo wakes the broken gate, the old bell, the empty golden circle | generic gate plate — no missing section, so "broken" reads as "old" |
| `S03-B08-L1` (S25, 7s, silent) | five claws take equal space on the circle | close-up of Kuku — and the "why gate-sized" comparison is nowhere in the episode |
| `S06-B14` (S73–S75, **16s**, 3 sub-shots) | **the gate's wave sweeps the cloud and lifts the goat kid off solid ground** | three talking close-ups: Furia, Dadi, Leda. **The lift is never on screen.** |

That last row is the whole goat problem. Sixteen seconds are spent on the beat that creates
the entire rescue stakes, and the event itself was never rendered — only the faces of people
reacting to it. Then `S07-B01` says "the first orbit completes" and `S08-B11` says "the second
orbit dies, the third lights" — a countdown the audience was never shown a dial for. Leda's
line about three orbits therefore sounds like invented jeopardy.

It is the collision of two correct rules: *every spoken line shows its speaker's face* pushed
every dialogue beat to a close-up, and the events those lines describe fell out of the frame.

## Fix: compositions that hold the speaker AND the event

No new beats, no retiming, no new dialogue, no re-recording. Five stills, wired into beats
that already exist.

**A — why the gate is weak** → `S01-B03` (silent, 2s)
`ST_gate_gap.png`: the echo-thread arrives at a gate with a **clean empty notch** punched out
of its frame, sky visible through it, bell swinging. The gate is not *worn*, it is
**incomplete** — its hold was a letter and the letter is gone.

**B — why the letter must be that big** → `S03-B08-L1` (silent, 7s, inside Rishi's
instruction scene, where the "why" belongs)
`ST_gate_scale.png`: Rishi's raised staff beside the notch for scale — the hole dwarfs him —
and a ghost outline of `ब` rising to fill it exactly, like a puzzle piece coming home. One
image answers "why bigger letters": **the letter is a structural part, cut to size.**

**C — the goat, and the clock** → `S06-B14-L1`, `S06-B14-L3`, `S08-B11-L1` (all keep their
speakers' faces)
- `ST_goat_lift_furia.png` — Furia large in the foreground shouting, and **behind her the
  goat's cloud being torn up off the meadow**. Orbit ring one lit.
- `ST_goat_lift_leda.png` — Leda in the foreground, the cloud now high on a visible spiral.
  Ring one spent, ring two lit.
- `ST_leda_orbit3.png` — Leda mid-line pointing; three countable rings, the third blazing,
  the goat riding it close to the gate.

The orbit dial rides along in the backgrounds, so the countdown costs no extra beat and
`S07-B01` / `S08-B11` finally read as a clock.

## The two-gates problem — fixed by regeneration (2026-08-18)

The episode carried **two different Gurukul gates**. The older local clips showed it as a
small *closed* golden door floating in a lavender sky, drawn flat; the papercraft canon is a
mountaintop post-and-lintel gateway of cracked pale gold with a bell and a missing notch.
Audited every clip: the old design appeared in `B02` (S3), `B04` (S18), `B10` (S72) and
`B13` (S77). `B06` (S59) and `B07` (S62) show flight only — no gate in frame — so they stayed.

Regenerated the three remaining ones as papercraft start frames (`GB04/GB10/GB13_start.png`,
gpt_image_2) then 5s of motion each through **Seedance 2.5** (`FFG04/FFG10/FFG13.mp4`), all
built on the `ST_gate_gap` design so the gate is now one structure across the episode.

**S18 got a second fix for free.** The note *"S18 has the dialogue of Guruji, but we're
showing the door in the sky"* was the same shot: Rishi speaks over it and was not in frame.
`FFG04` puts him large at frame left, braced against the pull, his staff bending and the
golden thread running from it up to the gate — speaker and event in one shot.

Originals `B02/B04/B10/B13.mp4` are kept in `clips/`, overridden not deleted.

## Cost

5 stills × 7 credits = **35 credits**. No video generation, no retime, no re-record.
(The first draft of this document estimated 14 for two stills; the goat thread turned out to
need three, because the problem was larger than the two "why" questions.)
