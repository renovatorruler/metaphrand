# «कर्क की तांती» — review response: six systemic problems

Author's V1 review, 2026-08-16. Five of these are structural, not per-image — fixing them will pre-empt a large share of any shot-by-shot notes.

## 1. The children don't age consistently

**Cause.** The adults have canonicals and Souls; the children never got any. Every photo described them fresh ("a girl of about five", "a teenage boy"), so each generation invented a different child. The couple holds because they're anchored; the kids drift because nothing anchors them.

**Fix.** The same element discipline, applied to the family. Two children at three life stages each:

| | 1990 | 2005 | 2018+ |
|---|---|---|---|
| Daughter | ~5 | ~15 | ~30 |
| Son | ~2 | ~11 | ~26 |

Six canonicals, derived the way the young couple was — one fresh cast at the target age composited with the previous stage for continuity, each shown to you beside its siblings before use. Roughly 15–20 credits for the canonicals, then every family photo regenerates against them.

## 2. Nobody knows who the extended family are

**Cause.** Same thing one layer out — the son-in-law, daughter-in-law and grandchildren are invented per shot.

**Fix, and a choice.** Either (a) canonicals for the two in-laws and two grandchildren — four more elements, and full consistency; or (b) keep extended-family shots deliberately wide, backlit or motion-blurred so no face registers, and let the couple and their two children carry all the recognisable faces. Option (b) is free and arguably truer to how family photos actually look. My recommendation is (b) with one exception: the daughter's wedding, where her husband should be a real recurring face.

## 3. Several 1976 shots stopped looking like our actors

**Cause.** Drift — the reference didn't hold on some frames, and the model fell back on generic period-film faces.

**Fix.** Identify and re-roll the affected shots. Name them by number from the Beat 1 sheet, or I'll do a pass comparing every 1976 photo against the young canonicals and flag the failures myself.

## 4. The courtship photos look NEWER than the wedding photos

**Cause.** The 1976 material was made in two separate batches, weeks apart, with different prompt wording — `b1_*` (courtship) asked for "early colour film stock, faded warm tones", while the origin sequence (`o1`–`o4`) asked for "1976 photograph, strongly faded and yellowed". Same year, two different looks, and the courtship set came out the newer of the two.

**Fix — and this solves it permanently.** Stop asking the model for era look at all. Apply the era grade in **post**, one deterministic ffmpeg recipe per era, to every photograph of that era. We already built and tested these recipes (`keyframes/contact_fade3.jpg`); they were shelved when you chose unfaded keyframes. Reinstating them for the photographs guarantees that every 1976 image is exactly as old as every other 1976 image, and it costs nothing.

## 5. The album framing stops after the old photos

**Cause.** Borders were prompted per-era and the modern prompts didn't ask for them.

**Fix, and I'd argue this becomes a feature.** Let the frame itself tell the history of photography, deliberately:

- **1976** — deckled white border, thick, slightly yellowed
- **1990** — thinner white border, square corners
- **2005** — glossy borderless print, faint orange date stamp in the corner
- **2018 onward** — full-bleed digital, no border at all

Applied in post like the grade, so it's uniform. The disappearance of the border becomes the moment the family stopped printing photographs — which is true, and quietly sad.

## 6. The pans and zooms aren't cinematic

**Cause.** Every shot got the same treatment: a linear push in or out at one speed, anchored dead centre. Real Ken Burns work varies speed, eases in and out, anchors off-centre, and above all *moves for a reason* — starting on a detail and pulling to reveal, or drifting across a face toward what it's looking at.

**Fix.** Rewrite the move engine: ease-in-out curves instead of linear ramps, per-shot anchor points chosen from the content, varied durations and distances, and roughly one shot in five held completely still so the moving ones mean something. Free, and I'd rather design each move against the actual image than apply a formula.

## Proposed order

1. Child and in-law canonicals (needs your approval on faces)
2. Regenerate the family photographs against them
3. Re-roll the drifted 1976 shots
4. Apply the post-grade + border system to every photograph, era by era
5. Rewrite the motion engine
6. Re-cut

Steps 4 and 5 are free. Steps 1–3 are roughly 60–80 credits.

**How do you want to review?** You said you have feedback on all the images — we can either go shot by shot now and fold your notes into the same rebuild, or I can execute these six fixes first and bring you a clean set to review against. I'd suggest the former: your notes and these fixes should land in one pass rather than two.
