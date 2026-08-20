# The composite law — we never composite a shot, only a layer onto a live plate

Written 2026-08-19 from the author's objection.

> If we do composites for one and two, I feel like it's just gonna read extremely stiff. Currently we have one composite in the show, and it does read a bit stiff, but it's a very short segment of much longer video. I feel like these composite things are going to be constantly interrupting the magic.

She is right, and the risk is structural rather than cosmetic: **the beats we keep proposing to composite are the magic beats.** Letters lighting, words being written, transformations. If every one of those is a still frame with an overlay on it, then the spine of the show is the stiffest thing in it, and the liveness only returns between the moments that matter.

---

## THE DEFECT, NAMED

A composite reads stiff for six reasons, and all six are fixable:

1. **Nothing moves but the effect.** Real footage has micro-motion everywhere — breathing, cloth settling, hair, the tremor in a child's hand, string lights swinging. A still plate has none, so the one moving element reads as a sticker on a photograph.
2. **No camera.** Live shots drift. A locked-off plate reads as a slide in a presentation.
3. **No shutter.** Overlay elements jump between positions with hard edges instead of smearing.
4. **The seam is a cut.** Hard-cutting from live footage to a composite at a similar framing puts the two levels of aliveness side by side, which is exactly where the eye catches it.
5. **Grid timing.** Effects landing on even intervals read mechanical. Real events overlap and are unevenly spaced.
6. **The light does not answer.** A letter lights up and nothing else in frame gets warmer, so the glow is obviously not in the room.

The one composite already in the episode — the letter row laid over the chest in scene 7 — fails on all six. It is a flat rectangle sitting on a picture.

---

## THE LAW

**A composite is a live generated plate with one layer added on top. It is never a still frame with an effect on it.**

The plate is generated exactly as any other shot: the children breathe, a knee shifts, the pencil trembles, the cord sways, the lights swing. Only the thing the model cannot do — the specific Cyrillic letters, the author's glow states — comes from us.

This means **compositing does not save generation credits.** It saves reshoots. Every shot with letters in it still costs its seconds. What we buy is that the letters are right the first time.

### The six fixes, against the six defects

1. **Shoot the plate as video, always.** This alone removes most of the stiffness, because everything except the letters is real motion.
2. **Give the composited frame a camera.** A slow 2-4% push, or a low-amplitude handheld wobble applied to the whole finished frame. Costs nothing.
3. **Blur what moves.** Any overlay element that travels gets motion blur matched to the plate's shutter.
4. **Never cut live-to-composite at a matched framing.** Cut on motion, or change the framing across the cut so the eye is busy.
5. **Time to the voice, not to a grid.** Letters light on the measured onsets of her actual recording, and the glow decays unevenly.
6. **Let the light answer.** When a letter lights, brighten the plate around it — a soft radial lift on the paper, the hand, the floor. This is the single strongest "it is really there" cue and it is a few lines of compositing.

### Two more rules of thumb

- **Keep any heavily composited shot short and bracket it with live shots.** The audience forgives a second and a half of anything.
- **Put the effect on a face wherever possible.** The author's own storyboard already does this: the juice appearing is never filmed, only the glow crossing Вася's face. A reaction is live by definition.

---

## THE TILE SHOTS — WITHDRAWN PROPOSAL, AND WHAT THE FOOTAGE ACTUALLY SAYS

I proposed that the tiles lie face down and be turned over. The author:

> Nobody plays with letter tiles by turning them over. And I don't believe our video is capable of making sure that we have the right number of tiles, even if we were to leave them blank.

The first objection is simply right — it was a contrivance in service of a technical problem. The second sent me to the footage, and the footage disagrees with both of us in a useful way.

**s7jobD**, locked top-down, each tile about 13% of frame height: eight tiles, right count, even spacing, no drift across the whole beat. The only error in the row was `Б` drawn as the digit `6` — one glyph, on a tile that never moves, repairable in post in minutes.

**s7jobE**, the same tiles seen from across the room inside the chest, each about 2% of frame height: no letters at all, just scratches on wood.

So the model is not incapable of holding a countable set of tiles. **A glyph needs room to exist.** Above roughly a tenth of frame height the model draws letters; below it, it draws texture, and no prompt changes that. Every letter disaster in scene 7 was a small-in-frame shot.

### What follows

1. **Frame tiles big or don't ask for letters.** A shot either gives a tile ~10%+ of frame height, or states that its tiles are texture and not meant to be read. Both are legitimate; the sin is asking for legible letters at 2%.
2. **Shot 1 does not need legible tiles.** "Что можно написать?" plays on the children and the scatter. Nobody has to read the field before she picks from it.
3. **Shot 2 is the jobD case** — tight, locked, short, tiles large. This is the model's proven zone, with single-glyph repainting as the expected finishing step rather than a rescue.
4. **Cut on the placement.** A tile in motion never needs to carry a letter, because we cut as the hand comes down and rejoin with the tile at rest. Ordinary grammar, no tracking, no contrivance.

### Enforcement

`assertTileScaleStated` in `studio/src/Drakosha_SeedanceDryRun.res`. Any creative mentioning tiles must carry a `TILE SCALE` line giving the tile height as a percentage of frame height. Below 8% the dry run fails, unless the line says `NOT READABLE`, which is an admitted decision rather than an accident.
