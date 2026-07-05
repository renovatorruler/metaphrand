# Seedance 2.0 — Video Prompt Template

A reusable skeleton. Fill each slot with OUR directions. Derived from a proven
Seedance 2.0 prompt (the Korean-neighborhood home-video piece).

## Why the structure works (keep these, they ARE the quality)
1. **Sectioned** — subject / location / visual style / camera / timed beats / audio /
   goal. The model gets one job per section.
2. **Hyper-specific** — exact clothing item by item, exact camera artifacts. Generic
   = the model's average; specific = singular. (This is where the [entropy engine]
   feeds in: it generates the OFF-MODAL specifics; the template houses them.)
3. **Consistency lock** — one explicit line: "Maintain consistent identity, clothing,
   hairstyle, and appearance throughout."
4. **Exclusions** — name what NOT to show, to kill the model's modal defaults
   ("No stores, ads, crowds"; "No music"; "No cinematic moves").
5. **A committed, SPECIFIC, real camera identity** — one real format/era, held
   consistently. This is the VISUAL "recorded, not written": glossy, stabilized,
   modern-graded footage reads as CG. NOTE: the source example reached this via a
   handheld DV-camcorder look — that is ONE fill, NOT the law and NOT ours. The
   principle is a committed *real* camera; the specific camera is a VARIABLE (for
   Sky King it's FILM-real — Kodak Portra / Drive / Kohrra — steady and
   observational, not DV, not shaky). Realism = a true, consistent camera + real
   subject motion, never imperfection for its own sake.
6. **Timed 2–3s beats** — a shot-by-shot clock, each beat = what the subject does +
   how the camera behaves. Keeps it controlled; the camera imperfections live INSIDE
   the beats.
7. **Ambient-only audio** unless a specific diegetic sound/line is needed.
8. **A one-line GOAL** — the feeling, tied to a reference ("like a forgotten home
   video from the early 2000s").

## THE TEMPLATE (copy, fill the [brackets])

**Main subject:** [WHO — exact age & look; clothing item by item; exact hair; skin
texture; demeanor/personality]. Maintain consistent identity, clothing, hairstyle,
and appearance throughout the entire video.

**Location:** [SPECIFIC authentic place; pile on real environmental detail —
surfaces, props, how the light behaves, weather]. [EXCLUSIONS: No [the modal clichés
to keep out]].

**Visual Style:** [the realism register — e.g. ultra-realistic documentary realism;
candid, unscripted; environmental authenticity; the film stock / era if any].

**Camera Style:** [the CAMERA's specific REAL identity — format/era; lens; the
grade. Pick ONE real identity and hold it. For Sky King: 35mm film feel, Kodak
Portra 400 / Drive / Kohrra register, motivated available light, organic fine
grain; steady and observational — NOT a DV camcorder, NOT handheld-shaky, NOT
autofocus-hunting.] **Camera MOVEMENT = an off-modal entropy pick** (not the default
slow cinematic push-in) — the specific, motivated move a real operator would make.
[NEGATIVES: no glossy modern HDR grade, no teal-and-orange, no show-off gimbal
glide, no CG-perfect stabilization for its own sake.]

**Timed beats:**
00:00–00:02  [subject action] + [camera behavior]
00:02–00:04  [...]
00:04–00:06  [...]
(continue in 2–3s blocks to the target length; put the camera's imperfections in
each beat; end beats can specify a cut, e.g. "cuts abruptly to black mid-motion".)

**Audio:** Natural ambient only — [the specific real sounds of this place]. No music.
No sound design. No narration. [OR: a single diegetic line/sound, named.]

**Goal:** [one line — the feeling & intent, tied to a reference: "captured like …".]

## Rules
- Specificity > generality (name the exact item, never "casual clothes").
- Lock consistency explicitly, every time.
- Use exclusions to knock out the model's defaults (crowds, ads, glossy grade, music).
- Commit to ONE specific, REAL camera identity and stay in it — glossy, modern-graded
  footage reads as CG. The realism is the TRUE camera + real subject motion, NOT
  handheld imperfection (that DV look was the source's fill, not ours; Sky King is
  film-real, steady, observational).
- Put camera behavior INSIDE the timed beats.
- Feed the subject/location/beat specifics AND the camera MOVEMENT from the entropy
  engine (off-modal but coherent choices) so it isn't the average version of the scene.
  The modal camera move — the slow push-in, the drift onto the subject — is the cliché
  to perturb OFF; pick the specific, motivated, off-centre move a real operator makes.

## Worked example — SKY KING (the ramp, dawn)
Sky King's look is NOT the DV-camcorder of the source prompt; it's film-real (Kodak
Portra / Drive). Same template, our directions:

**Main subject:** BIRDY, a gentle man around 30, tired kind unremarkable face (the
face-locked Birdy), a worn grey hoodie under an orange hi-vis safety vest with
reflective stripes, work gloves, a thermos. Realistic skin, no makeup, plain.
Maintain consistent identity, clothing, hairstyle, and appearance throughout.

**Location:** a small regional-airport ramp at dawn — gray wet tarmac under sodium
lights, a row of parked Q400 turboprops, a crew-room door, baggage carts, belt
loaders, ground-power units, cold breath-fog; a working, prosperous regional
operation, lived-in but not poor. No crowds, no glamour, no signage clutter, no
onlookers.

**Visual Style:** naturalistic documentary realism; Kodak Portra 400, Kohrra /
Delhi-Crime register; candid, off-centre framing, available light; true skin,
organic grain; muted, cold dawn. NO teal-and-orange grade, no gloss.

**Camera Style:** 35mm film feel, steady and observational — a working lens on
sticks or a slow motivated move, not a show-off. Motivated available light only
(sodium lamps, gray dawn). Fine organic grain. No DV handheld, no gimbal glide, no
cinematic push-ins for effect, no modern HDR grade.

**Timed beats:**
00:00–00:03  A baggage truck swings in fast across the apron and brakes at the crew
door; headlights wash the row of parked Q400s in the gray dawn. Handheld, a beat late.
00:03–00:06  Birdy climbs out with the thermos, breath fogging, and walks — not runs —
to the crew door; the camera drifts to hold him off-centre.
00:06–00:09  He stops at a wall terminal, taps his badge; the little screen loads his
name; his face doesn't change. Available light on his face, grain in the shadows.
00:09–00:12  Behind him a Q400 sits cold on the stand, cargo doors open — the plane he
loads, held a beat too long in the frame. A tug rolls past.

**Audio:** natural ambient only — turboprop APUs whining down, a belt loader, a tug
hauling carts, low ground-crew chatter, wind across the apron, the cold hum of the
ramp. No music. No narration.

**Goal:** an ordinary working dawn on the ramp, shot like real observed documentary
footage — plain, cold, true; the man and the plane he'll one day take, both just
sitting there in the gray.
