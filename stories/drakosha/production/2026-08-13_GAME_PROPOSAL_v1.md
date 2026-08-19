# «Фрося и Вася» — интерактивный аудио-эпизод: proposal v1

The child is the magic. An audio-first episode where the story stops when a spell is needed, and the listening child must WRITE the letters to make it fire. Фрося and Вася speak to the child directly; the child's finger is the pencil.

## 1 · Why this works with what we have

The show's canon already IS a game design:

- **Мама's rule is the level system.** «Какие буквы я вам выдам, только из тех волшебные слова и получатся» — the game issues letters exactly as мама does: А О М С К Т Л Б first, then one new letter per episode. The curriculum is diegetic; nothing needs inventing.
- **Вася can't read yet — that's the child's job.** The natural framing: Вася knows what he wants to become but can't assemble the word. Фрося is busy/elsewhere/annoyed with him. He asks the child. This makes the child needed rather than tested.
- **The spell grammar is built.** Tiles fall, the word ignites left to right, the reveal fires — all existing plates. In the game, the ignition happens only when the child finishes writing: their writing is literally what lights the letters.
- **The cast is recorded infrastructure.** ElevenLabs voices + expression tags + the pronunciation registry produce any new line on demand, including praise and hint variants.

## 2 · The core loop (one "spell")

1. **Story beat (audio, ~30–60s).** Scene stills + existing plates on screen; the episode plays like the radio drama it already is.
2. **The ask.** Вася, to the child, in character: «Помоги мне! Нужно слово КОТ. Пиши со мной: К!» A large letter tile appears with the letter shown faintly.
3. **Writing.** The child traces the letter with a finger. Stroke-by-stroke: start-point dot pulses, the stroke path glows as the finger moves, gentle snap-back if the finger leaves the corridor. Three completed traces → the tile "carves" and thuds into place on the mat (existing tile art).
4. **The word.** All letters placed → Вася reads it aloud syllable by syllable (existing audio pattern) → **the child's completed word ignites** with the existing ignition plates → ВЖУХ → reveal plate → the story continues.
5. **No fail state.** A struggling trace never blocks: after two wobbly attempts the corridor widens and Фрося's voice guides («Сверху вниз… вот так!»). Mastery is tracked silently for repetition, never shown as failure.

## 3 · Pedagogy — the practices the good ones use

Modeled on the strongest letter apps (LetterSchool, Duolingo ABC, Endless Alphabet) and the Russian primer tradition (Жукова: sounds not letter-names, syllable fusion early):

- **Sounds, not names**: Вася says «К» as /к/, never «ка» — the show already does this in SP087.
- **Fading scaffolds**: trace-over-model → trace-over-dots → copy beside model → write from memory. Each letter climbs this ladder across episodes, not in one sitting.
- **Stroke order enforced gently**: start-point cue + direction arrow on first attempts, removed as the child succeeds.
- **Immediate diegetic reward**: the reward is the story continuing — the cat appears because YOU wrote it. No stars, no coins.
- **Spaced repetition**: previously learned letters recur inside new words (мама's rule again — old letters stay in the pouch).
- **Short sessions**: an episode chapter ≤ 8–10 minutes; a clean stopping point after every spell.
- **Audio-first UI**: pre-readers can't read menus; every interaction is spoken. One tap to start, no text navigation.

## 4 · Visual asset plan (same quality as the video)

Reused as-is: the magic mat, tile plates + ignition states, casting frames, reveal plates, room masters, character sheets, word cards. New per episode:

- **Letter-tile faces for the full alphabet** — typography, free, one template.
- **Stroke-corridor overlays** per letter — vector, free, derived from a single font skeleton.
- **A handful of scene stills** for story beats not already covered (~5–8 per episode at measured cost).
- Everything passes the same registry/emitter discipline as video frames.

## 5 · Technology

- **ReScript web app** (the studio law holds; ReScript is a first-class web language). Canvas + pointer events; runs on a tablet in the browser; installable as an offline PWA so the kids can play without network.
- **Trace recognition is geometry, not ML**: each letter is stroke templates with tolerance corridors; finger path is scored against them ($P point-cloud recognizer or per-stroke checkpoints — the standard approach in tracing apps). Deterministic, testable, no API calls.
- **Audio engine**: pre-rendered line pools (ask, hint ×3, praise ×3, retry ×2 per spell) so nothing is synthesized at runtime; the pronunciation registry guarantees every spoken word.
- **The typed pipeline extends naturally**: an episode is data — beats, asks, letters, assets — validated like the video plan (every asked letter must be in the issued set; every asset must exist).
- Deployment options: any static host; notably `higgsfield game` can deploy browser games if we want it hosted there.

## 6 · Production plan

**Phase 0 — playable proof (1–2 days, ~0 credits).** One spell: КОТ. Existing plates, existing audio, new tracing engine with the three letters. Success = a child completes the loop unaided and smiles at the ignition.

**Phase 1 — Episode chapter 1.** The birthday story's first act as interactive audio: 3 spells (СОК, МАМА, КОТ), letter ladder for А О М С К Т Л Б at trace-over-model level. New audio lines for asks/hints/praise through the cast.

**Phase 2 — the full episode + letter progression.** All nine words, scaffold levels persisted per letter, Фрося's МА□□□А ending as the cliffhanger ask the child can't complete yet — the missing letters are the reason to come back.

**Playtest gate at every phase: her kids.** Their confusion is the only defect register that matters.

## 7 · Open questions for the author

1. Device target: tablet finger-tracing, or also paper-and-pencil with the parent confirming (Вася: «Написала? Покажи маме!»)?
2. Does the child write on the tile, on the mat, or on Фрося's paper scrap? (Affects the art.)
3. Russian letterforms: печатные буквы only, or introduce письменные later?
4. Should Фрося ever be the asker (she can read — her asks would be speed/quantity based), or is asking always Вася's role?
