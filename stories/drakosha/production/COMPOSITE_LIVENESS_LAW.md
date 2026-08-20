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

## THE TILE SHOTS — TWO WITHDRAWN PROPOSALS, AND THE ACTUAL RECORD

I proposed the tiles lie face down and be turned over. The author: nobody plays with letter tiles that way. Correct — it was a contrivance in service of a technical problem.

I then proposed that tile size was the governing variable, citing s7jobD as a shot where the model held eight tiles. **s7jobD was thrown out.** Its glyphs were wrong and the finger pointed at the wrong tiles, and I did not know that because I sampled still frames from it and pointing is a fault that only exists in motion. The author:

> You are not capable of looking at things. That footage had to be thrown out and replaced with our own composite.

### The actual record for scene 7

| shot | what happened |
|---|---|
| top-down row of eight | one tile plainly wrong; the pointing wrong as well. Discarded, replaced with our own composite. |
| Мама laying the tiles out | wrong count, wrong letters. |
| the small-tile row | letters wrong; covered with a plate. |

Nothing survived. Not one letter shot in the scene shipped as generated footage. **There is no tile size at which the model becomes reliable with Cyrillic**, and the earlier gate that claimed there was has been removed.

### The rule that follows

**Every glyph the model draws is assumed wrong.** A shot containing a letter the audience must read is planned from the start around replacing those glyphs on the moving footage: a locked or near-locked camera, the tile or paper at rest at the moment it is read, and enough pixels on the glyph to repaint cleanly.

**And the labelling follows the performance.** Whatever tile the finger actually touches becomes the letter he says. We do not ask the model to point correctly at letters it cannot draw — we let it point wherever it points and assign the letters to match. The row order is ours to choose; the performance is not.

This is the difference between repainting and overlaying, and it is also the answer to the stiffness. A repaint sits on tiles that are already lit, already moving, already in the plate's grain. A plate laid over a shot — the caption bar in scene 7 — is a sticker, and that is the composite that reads stiff.

### Enforcement

`assertGlyphsPlanned` in `studio/src/Drakosha_SeedanceDryRun.res` refuses any creative mentioning letters or tiles without a GLYPHS block naming its strategy — NOT READABLE, REPAINT or PLATE — and a REPAINT shot must say when the letters come to rest.

### Still open

The author's own suggestion, untested: **a start frame and an end frame, both ours, with the model only interpolating between them.** It may hold the letters where a free generation cannot. It is one short shot to find out, and it should be run as an experiment with that name on it rather than folded into a plan.
