# कुकु और अक्षर — production lessons

*Every entry here is a defect that shipped, or nearly shipped, and cost real money or
a re-cut. This document is the explanation; **`studio/src/Kuku_Preflight.res` is the
enforcement**. A lesson that lives only in prose gets re-learned — Ep6 repeated two
Ep5 mistakes before the gate existed.*

## Run the gate

```
cd studio
npm run preflight -- ../stories/kuku/ep6prod ep6
```

**Twice per episode, both times mandatory:**

1. **After the shot list is designed, BEFORE generating anything.** This is where the
   money is. It catches unmapped speakers, missing character references and word
   pictures while they still cost nothing.
2. **After the EDL is built, before assembling.** Catches dangling references,
   front-loaded effects, reused stills and orphaned paid assets.

Exit code is nonzero when a blocking check fails. Do not assemble past it.

---

## The lessons

### 1. Word cards must show the word
**Ep5:** five of six recap cards showed the wrong thing. The author's note: *"the most
important aspect of the show is to educate kids into learning the letters… if you show
प से पतंग, you should show the kite. And not just some random photo, but things in the
show itself."*
**Check:** `word-cards-have-pictures` — a distinct picture exists per carded word.
**Still human:** whether the picture actually depicts the word. Look at the contact
sheet before compiling the cards. Ep6's तीन card is exactly three countable ducks.

### 2. One picture per character per scene — never reused across scenes
**Ep5:** the same दादी close-up ran from scene 1 to scene 8. It read as a slideshow and
cost a re-cut with 43 fresh images.
**Check:** `no-dialogue-still-across-scenes` — blocking.

### 3. Sound effects go where the event happens
**Ep5:** every cue was placed at 0.0s, so the bridge broke audibly about four seconds
before it broke on screen.
**Check:** `sfx-not-front-loaded` — blocking if most effects sit at 0.0s.
**Design rule:** a cue attaches to the dialogue line it FOLLOWS, never to the top of a
scene.

### 4. Dialogue must sit above ambience
**Ep5:** the stream was louder than the voices. Fixed with −17 LUFS on every take, and
ambience ducked to 0.30 under speech.
**Check:** `dialogue-levelled` — blocking; every take carries a levelling marker.
**Design rule:** level at RECORD time, not in the mix. Beds −26 LUFS, event effects
−20, dialogue −17.

### 5. Every speaker needs a voice before recording starts
**Ep5:** the recorder crashed at take 105 because पापा had no map entry — he had no
lines in Ep4.
**Check:** `speaker-has-voice` — blocking. Run it before spending.

### 6. Every dialogue shot must attach its speaker's own reference sheet
**Ep5:** produced two कैस्टरs and no लेडा, because her sheet was never attached.
**Check:** `shot-refs-include-speaker` — blocking.
**Also:** a new character needs a sheet BEFORE any scene art. तानसेन's was drawn first
in Ep6 for exactly this reason.

### 7. The picture has to move
**Ep6, first EDL:** built only from speaker close-ups. All 11 clips and 46 story shots
rendered and then sat unused while the cut played as 137 consecutive talking heads.
**Check:** `picture-has-variety` (warn) + `no-paid-orphans` (warn) — an asset that was
paid for and never used is the signal.

### 8. Never pay twice
**Ep6:** mimicry takes were named after the dialogue index they follow, so splitting one
line shifted every index and eight takes were re-recorded under new names.
**Rule:** derive a generated file's name from its CONTENT (voice + text), never from a
position that any edit can move.
**Check:** `no-paid-orphans` catches the stranded copies after the fact.

### 9. A cache key must include the content
**Ep5:** the assembler keyed rendered segments on scene+index. A 93-segment rewire
reported success, took the normal time, and changed **not one frame**. It looked
finished.
**Now:** `Kuku_Assemble` keys each segment on its full spec plus duration.

### 10. Guards must be mechanical, and must be able to fail
**Ep5:** eyeballing contact sheets let the same class of defect through repeatedly —
eleven of twelve shots after the bridge collapsed still showed it intact.
**Now:** `Kuku_Verify` compares every built segment against the still the EDL names, by
perceptual hash, and checks duration parity against a recorded baseline.
**Rule:** before trusting a guard, confirm it FAILS on a known-bad input. A guard that
can only pass is worthless.

### 11. Don't trust a description of state — measure it
Recurring. The "−3.1 dB audio regression" that was my own comparison method comparing
AAC streams with different priming. The mimicry index asserted as 109 when the manifest
said 114. Two `pgrep` waiters that matched their own command line and hung forever.
**Rule:** when a number matters, print it from the artefact, not from the plan.

### 12. Write well; the bar is not "no metaphor"
**Ep5:** a line reached screen reading «बादल तुम्हारे ऊपर था, और सच मेरे पास था» and was
cut as *"nonsensical… this kind of obscene, dumb poetry is not needed in a children's
show."* The lesson first drawn was "ban metaphors" — **that was wrong.** The author's
correction: *"There is no rule for or against metaphors. There is only a rule against
shit writing and shit metaphors."*
**Rule:** a five-year-old must picture it in one second, and it must be true.

### 13. Things said must be shown
**Ep5:** the closing narration said वैस्पर fell asleep on the bridge; no shot showed it.
**Rule:** every concrete thing a character states as visible needs a picture.

### 14. Curtains, stages and readable text keep coming back
**Ep5:** the theatre-curtain framing returned twice after the negative prompt was
trimmed, and generated glyphs are always gibberish.
**Now:** the negative block lives in `Kuku_Gen`, appended to every prompt, so no shot
description can omit it. Every letterform on screen is composited typography.

### 15. A marker must record what HAPPENED, not what was intended
**Ep6:** the parrot's 21 mimicry takes were pitched up with
`asetrate=44100*1.15`. But `asetrate` is an **absolute** sample rate, and these takes
are 48 kHz — so the shift came out 5.7%, not 15%, while the compensating `atempo`
still slowed by the full 15%. The parrot ended up barely pitched *and* 8.6% longer.
The step then wrote `1.15` into its marker file, so the error was invisible: the
marker recorded the intent, and nothing measured the effect.
**Cost:** a wrong-sounding parrot in a published review cut, plus a rebuild.
**Now:** three changes in `Kuku_Voices`, all mechanical —
1. the rate is probed from the file, never hardcoded;
2. every shift derives from a pristine pre-pitch snapshot in `takes/.pristine/`, so
   retuning `parrotPitch` is a one-line edit and never stacks or needs delta maths;
3. the step **asserts its own claim** — a pitch shift that preserves length must land
   on the pristine duration, and it raises if it does not. Tolerance is 2% or 50 ms,
   whichever is looser, because mp3 padding costs a short echo 21 ms.

**The general rule: any transform that claims to preserve something must measure that
it did.** "The maths is right" is what was believed both times this bug class shipped.
Derive absolute parameters from the asset; never hardcode a rate, size or duration
that the file itself can tell you.

### 16. A looped image feeds ffmpeg at 25fps, and the show is 24
**Ep6:** stills were panned across a 16% overscan. `-loop 1` defaults the image
input to **25fps**, and the trailing `fps=24` then dropped one frame every second.
On a motionless picture that is invisible — which is why Ep5, whose stills were
static, never showed it. On a *moving* picture it is a hitch once a second, which
the author reported as "camera shaking effects. This wasn't in the last video."
This is also the true cause of the earlier "frame rate issue": swapping zoompan for
a drift did not fix it, because the decimation was never the zoompan's doing.
**Now:** every looped-image input passes `-framerate 24`, so nothing is ever
decimated — and stills no longer move at all, matching Ep5.
**Rule:** when a filter graph names a frame rate, the INPUT must already be at that
rate. A rate conversion in the middle of a moving shot is a defect, not a resample.

### 17. Video is whole frames; audio is not. Align, don't round.
**Ep6:** each segment's picture is `round(dur*24)` frames long, but the audio clock
advanced by the exact float `dur`. The two disagreed by up to half a frame per
segment and the error accumulated down the scene — measured at **−80ms over s5's 36
segments**, and −51ms in the race scene, where the author reported "the dialogues
are getting out of sync."
**Now:** `frameAlign` rounds every segment duration UP to a whole frame before it is
used for either picture or sound, so video length and audio advance are the same
number and drift is not small but structurally zero. Re-measured after the fix:
worst scene −0.3ms, which is float representation noise. The recap sequence
distributes whole frames across its cards for the same reason.
**Rule:** any duration used by BOTH picture and sound must be quantised to a frame
before either consumes it. Rounding each side separately is the bug.

### 18. Takes are keyed on the words they say
**Ep6:** correcting a line in the manifest did not re-record it — the take file
existed, so it was skipped, and the cut would have kept the old reading forever
while every guard passed.
**Now:** each take carries a `.said` sidecar holding its exact spoken text. A changed
line re-records itself, and re-recording drops everything derived from the old audio
(levelling marker, pitch marker, pristine snapshot) — leave a stale pristine behind
and the parrot pitch step re-derives from it and silently undoes the edit. Existing
takes were adopted into the scheme rather than re-bought.

### 19. The image model cannot do exactness
The synthesis of most of the above. Anything requiring exactness — text, letterforms,
state changes, continuity between shots — moves to the compositing and validation
layer. Do not re-roll hoping.

---

## What the gate cannot check

Look at these yourself before publishing:

- whether a word picture depicts its word
- whether a shot shows the right STORY STATE (post-collapse, relit, repaired)
- whether the Hindi is natural for that character's age
- whether the नीति is earned and plain
- whether the letter's shape is actually taught, and distinguished from the letter it
  is most confusable with

### 20. A reference sheet is only as good as its ANGLES
**Ep8:** the author reported "a lack of consistency" across characters. The cause was
not a missing mechanism — every shot already attaches the style key plus each
character's sheet. It was that all ten legacy sheets were a **single 3/4 portrait**
(1792×2400, one pose, one expression). Ask for a character looking up, in profile,
from behind, or mid-run and the model has no reference for that view, so it invents
one — and invents a different one every time.
**Now:** every main-cast sheet is a three-view model sheet (side profile, front, head
close-up), generated WITH THE OLD SHEET ATTACHED as reference so the locked design is
preserved and only the missing angles are added — never a redesign. Originals kept in
`charsheets/v1_single_pose/`.
**Rule:** a new character's sheet is a turnaround from the start (चील's was, and she
held across seven shots without drifting).

### 21. Soul training is not the consistency tool for THIS show
**Tested 2026-08-07, empirically, not assumed.** Higgsfield `soul-id` trains a custom
character model. Findings on one real train (`KukuDragon`, soul_2):
1. It DOES train on a papercraft dragon — no `face_not_found` (an earlier account
   train, `GnomeTwo`, had failed that way, so this was a genuine risk).
2. Likeness held well.
3. **But the soul models accept at most ONE image reference**, and the soul occupies
   it — so the STYLE KEY cannot be attached. The test frame came back as a pop-up-book
   diorama with visible white studio backing: a straight violation of the show's
   full-bleed / no-frame-within-frame rule.
4. It ignored an explicit camera instruction ("from behind, head turned back").
5. One `custom_reference_id` per generation makes ensemble shots impossible; the show's
   frames routinely carry दादी plus four children.
**Conclusion:** stay on `nano_banana_pro` (14 reference slots) with turnaround sheets.
Revisit only if a soul-capable model ever accepts multiple references.
