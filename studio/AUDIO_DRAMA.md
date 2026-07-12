# AUDIO_DRAMA — requirements & best practices for a full-cast production

Gathered 2026-07-12 for the FOUR OLDS audio-play question. Sources: BBC
radio-drama scene conventions, Radio Theatre Project format guidelines,
Audible Originals production practice, the classic radio-drama canon (War
of the Worlds' described-image technique), modern full-cast benchmarks
(Audible Originals, We're Alive, Homecoming, Wolf 359), and this studio's
own hard-won audio laws (the eyes-closed test from DEEPER; the ElevenLabs
per-line performance stack; the blind-attribution voice gate).

## 1. The one law everything follows

**The ear is the only camera.** Every event must be audible: heard as
sound, said as dialogue, or carried by narration. A beat that is silent
and visual (a man standing square in a doorway) does not exist for the
listener until it is re-authored. The eyes-closed test runs on every
scene: play it in the head with eyes shut — anything that vanishes needs
sound, speech, or cutting.

## 2. Script format (BBC scene style, the industry default)

- Numbered scenes; numbered speeches (production reference).
- CHARACTER NAME on its own line or leading the speech; dialogue beneath.
- SOUND cues in CAPS on their own lines, blank line before and after:
  `SFX: BARN DOOR ROLLS. WIND CUTS OFF.`
- MUSIC cues the same, with behavior: `MUSIC: THEME UNDER, THEN OUT.`
- Performance parentheticals are the norm, not the exception — audio has
  no faces, so (dry), (off), (close), (into radio), (over speaker) carry
  what a face would.
- Perspective tags: CLOSE (at the listener's ear), OFF (across the room),
  APPROACHING / MOVING OFF — the audio version of blocking.
- Courier 12, generous margins; roughly one minute per page.
- NO visual action lines. Anything a screenplay's action line carried must
  be reassigned to SFX, dialogue, or narration.

## 3. Craft laws

1. **Presence management.** A silent character vanishes in ~30 seconds.
   Keep speaking populations small (2–4 is the sweet spot); re-anchor
   silent characters by address, movement sound, or breath. Big rooms need
   voice-traffic control.
2. **Voice differentiation is structural, not casting garnish.** Every
   speaker identifiable within two words — age, pitch, rhythm, region.
   (This studio's blind-attribution gate is literally this requirement.)
3. **Name-tagging, hidden.** Characters address each other by name more
   often than film so the ear can tag speakers — the craft is hiding the
   tags (vocatives at line ends, varied, never two lines running).
4. **Audio signatures per location.** Each recurring place is established
   in its first seconds by a signature bed: the diner = griddle + crockery
   + bell; the barn = wind + hum + switch clicks; the crate = breath +
   structure groan + amber-light silence. Transitions ride sound bridges.
5. **SFX must be blind-legible.** Use sounds the ear already knows (a
   torque gun, a screen door, a percolator). An ambiguous sound needs a
   dialogue anchor within seconds ("Mind the door.") or it reads as noise.
6. **Silence is the scarcest weapon.** Wall-to-wall sound deafens; a held
   silence (three hundred feet to contact light) detonates — but only if
   the show spends silence rarely.
7. **Music tiers:** transitions, emotional under-scoring, act punctuation
   — never continuous. Diegetic music (a radio in the room) beats score
   where available.
8. **The narrator decision** — the single biggest design choice:
   (a) none (pure drama; Audible Originals often run clean — demanding but
   immersive); (b) a character narrator, retrospective first person (the
   warmest option; think Elsa in 1883); (c) a minimal stage-setter. Decide
   BEFORE adaptation; it changes every scene's information plan.
9. **Exposition redistribution.** Chyrons, inserts, stencils, screens —
   all visual — become: in-world broadcasts (anchors, streamers, pressers),
   documents read aloud naturally ("Read it to me."), or narrator lines.
10. **Episode architecture.** Full-cast productions run in chapters:
    20–45 minutes each, hard act turns, cold opens, out-hooks. A feature
    becomes 6–10 chapters. Listeners drop mid-chapter and return — each
    chapter re-anchors world and voices in its first minute.
11. **Cast economics.** Principals under ~10 distinct voices for ear
    clarity; minor roles doubled by cast. (We carry 13 principals — fine
    with doubling and careful traffic.)
12. **Perform it aloud while writing.** The draft test is spoken, not
    read. (Audible's own authors' first advice.)

## 4. This studio's production reality

The stack already exists and has shipped: ElevenLabs v3 with stored
per-line performance JSON (the maintained artifact), Kokoro for drafts,
Freesound real recordings for sharp Foley + AudioLDM beds for ambience,
ElevenLabs Music/MusicGen for score, the tableread tooling for assembly.
A full-cast FOUR OLDS is buildable end-to-end in-house.

## 5. THE FOUR OLDS fit — what is natively audio gold

- **The world is already made of radio.** The Tuesday net, headset
  discipline, morse, the knock code (two-two is a SOUND motif), Joss's
  Ridge Road relay, the open loop at the standoff, the coda's three-second
  light-lag — the medium is the story's own nervous system.
- **The broadcasts are a built-in exposition engine**: Marwani's pressers,
  anchors, the streamer, the seminar — all diegetic audio already.
- **The climax is literally an audio event**: "We'll talk right here.
  Whole world's listening anyway." — a standoff conducted ON an open
  radio loop. "…is that a burger?" is an audio joke.
- **Vacuum is an audio gift, not a problem**: the Moon has no sound, so
  everything arrives through helmet comms — breath, compression, static —
  the most intimate register audio owns.
- **The voice cards + blind-attribution discipline** were built for ears.

## 6. The five hard conversions (the real adaptation work)

1. **THE REVEAL (color over the rise)** — the film's most visual frame.
   Audio answer: the described image, the oldest weapon in radio (War of
   the Worlds) — the world SEES it for us: mission control's stunned
   half-sentences, the diner, a panelist losing composure, Warsaw. The
   planet describes the flags; we never need eyes.
2. **The primer burn** — same instrument: ground commentary + the diner
   coming off its stools; the gala's silence where applause should be.
3. **The porch-lights / Earth-wave finale** — light is silent. Audio
   answer: the wave arrives as RADIO — after "Look up," stations around
   the world begin keying two clicks; static blooms with thousands of
   two-click answers on every frequency, hams relaying city names like a
   roll call, until the noise floor of the whole planet is the knock code.
4. **Wordless beats** (the zinnia seam, the dockworker's three seconds,
   Shen's palm) — re-authored in breath, latch sounds, held air, or a
   narrator's single line, case by case; the dockworker beat is breath +
   torque clicks + one swallowed decision and may be STRONGER blind.
5. **Stencils, screens, inserts** ($0.00 QUARTERLY, OLD IDEAS/CULTURE/
   CUSTOMS/HABITS, the pay stub) — read aloud where a person would truly
   read aloud (the bank clerk already reads the screen; Pell reads
   manifests for a living; Danny reads mail to himself at a kitchen table).

## 7. Decisions required before any redesign

1. **Narrator**: none / character-retrospective (candidates: Joss years
   later; Danny) / minimal stage-setter.
2. **Form**: one feature-length production with act breaks, or chaptered
   (8 × ~25 min maps cleanly onto the current act structure).
3. **Relationship to the screenplay**: parallel artifact generated from
   the same scene seeds (the engine emits BOTH formats), or a one-way
   adaptation pass on the finished v14.
