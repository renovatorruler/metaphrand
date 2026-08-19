# Scene 6 — the pencil, the rule, the withheld secret

Shot 2026-08-18. This is the record of what was decided, what it cost, and which defects became gate code rather than notes.

---

## What the scene is

Бабушка-Яга gives Фрося a pencil that makes whatever she writes the name of, and gives Вася a breath that turns him into whatever word he reads aloud. Then she gives them the rule, tells them their two gifts share one secret, and refuses to say what it is. Мама answers by naming the thing nobody else has said out loud — neither child can actually use their gift yet — and turns to fetch her own, which is scene 7.

The scene runs about 62 seconds across five generations.

---

## The five jobs

| Job | Shots | Model | Sec | Credits | What happens |
|---|---|---|---|---|---|
| s6jobA | SH066–068 | 2.0 mini | 12 | 30 | The pocket, the pencil into the palm, her face, the glow between their closed hands |
| s6jobB | SH069–073 | 2.0 mini | 13 | 32.5 | «И машину можно», the condition, the beckon, the breath on Вася's crown |
| s6jobC | SH074–077 | 2.5 | 17 | 110.5 | «И всё?» and the rule, cutting to the two children on the middle clause |
| s6jobD | SH078 | 2.0 mini | 8 | 20 | «Подарки у вас разные» and the word landing on both children |
| s6jobE | SH079–081 | 2.0 mini | 13 | 32.5 | «Какой секрет?», «Сами узнаете», and Мама's line |

**225.5 credits, about $9.70, against a 400-credit allowance.** The remaining 174.5 is reshoot headroom and is the reason the budget was set above the estimate rather than at it.

## Why one job costs five times the others

Four of the five run on Seedance 2.0 Mini at 2.5 credits a second. Mini is the default answer for this show: almost every shot is two or three characters in close-up with five references, well inside mini's limit of nine images, and the footage is indistinguishable at this scale.

s6jobC is the exception because `line39_YAGA` is a 13.28-second speech. With the two-second head the duration gate reserves for the beat before anyone speaks, it needs 17 seconds, and **mini and 2.0 both stop generating at 15.** Splitting the rule across two mini jobs would have cost 75 credits instead of 110 and was rejected: the speech would have had to be cut mid-sentence, and the two halves would then have had to match each other. The rule is also the one moment in the scene Бабушка-Яга is not playing, so if any shot deserves the expensive model it is that one.

**The general policy: mini unless the shot cannot be made on mini.** The two things that force 2.5 are a duration past 15 seconds and a reference count past nine.

---

## What became gate code

Every item here was a defect first. None of them is written down as a rule to remember.

**`assertModelFits`** — the model is now a field on the job record instead of the string `"seedance_2_5"` hardcoded in the emitter and twice more in the submitter. The gate holds each model's real ceilings (15s/9 refs for mini and 2.0, 30s/30 refs for 2.5) and refuses a job that exceeds them. Going over does not error at the API — it truncates or silently drops references, which is a spent credit and a clip that has to be shot again. The dry run also prices the whole batch now and prints the total before anything is submitted.

**`decidedOnly`** — the line index no longer returns superseded takes. `line34_YAGA.mp3` holds the OLD wording of the same speech as `line34_YAGA_FINAL.mp3`, and the duration gate found both, added them, and demanded a 20-second shot for 8.8 seconds of dialogue. Once any take of a line is marked `_FINAL`, `_APPROVED` or `_CONTROL`, every other take of that line stops existing as far as the gates are concerned. This is the "A FILENAME IS A DECISION" law, enforced instead of remembered.

**`assertHandsWritten`** — every job must carry a HANDS block that names every character in it and says what their hands ARE doing, in positive terms. s6jobB's choreography said "Бабушка-Яга has NO broom in any frame" and she came back holding the broom in two of four shots; because that hand was full, the crooked-finger beckon she was supposed to make never happened. Her reference sheet is a picture of a woman holding a broom, and **a picture beats the word "no".** The only thing that displaces what a sheet shows is a competing instruction of the same kind: "her hands are folded together low at her waist, one over the other" occupies the cell, and "no broom" leaves it empty for the sheet to fill. The gate therefore counts positive hand verbs and rejects a block that leans on prohibitions.

The first version of this gate passed s6jobA by matching the words "CLOSE ON HANDS," inside a shot description. Headers must now start a line — a gate that can be satisfied by an accident of phrasing is not a gate.

Worth noting for the reshoot policy: s6jobC came back CLEAN of the broom on the same old prompt that failed in s6jobB. The sheet's props are stochastic, which is exactly why the fix has to be a positive instruction rather than a stronger prohibition — a prohibition that works four times out of five still costs a reshoot on the fifth.

**The facial-anatomy rule inside `assertReactionsWritten`** — a reactions block must say what the FACE PARTS do, with at least one piece of anatomy per character. Мама's block said "starts flat and unimpressed, and by the end that goes to something firmer" — every word of it about how she FEELS — and she smiled warmly through the entire take, because her reference sheet smiles and **an adjective does not outrank a picture.** This is the broom failure in a different cell, and it has the same fix: what beats a sheet is an instruction about the same thing the sheet is showing. "Her mouth stays a level line and never turns up at the corners" works; "flat and unimpressed" does not.

**`assertTagLinesAreIdentityOnly`** — a cast reference line may no longer say what is in a character's hands. @YAGA's line said "birch broom in hand" and @FROSYA's said "no pencil", and both were fed to the model in EVERY job. That is why she held a broom through a dinner she was eating with both hands, and why the job in which Фрося RECEIVES the pencil also told the model she had none. The choreography owns hands, shot by shot; the reference line owns identity.

**The `--mode` flag is 2.5-only.** On mini and 2.0 `mode` is not a parameter at all, and passing it fails the whole call with "Unknown params: mode". The cost probe must also not pass `omni_reference`, because it sends no reference media and 2.5 rejects that combination — which refused the entire second batch before a single job was submitted. Nothing was spent; the gate computes every cost before it submits anything, which is exactly what that ordering is for.

---

## The script was stale in two places and has been amended at source

SH068 read «Карандаш лежит поперёк неё и почти достаёт до локтя» — the pencil almost reaching Фрося's elbow. That is pre-miniaturisation canon. **Whatever Бабушка-Яга brings is sized for whoever receives it**, so the pencil sits in the girl's palm and goes behind her ear. The stage direction now says so.

SH068's dialogue read «имя её напишешь, она и явится», which the approved recording supersedes: `line34_YAGA_FINAL` says «напишешь имя, поставишь точку, и будет по-твоему». The recording is the decision, so the script now carries the recorded words. Left alone, this would have resurfaced on every future pass, because the gate reads the script and the prompts are copied from it.

---

## Staging decisions taken without the author

**Nobody is ever seen walking.** SH066 is tight on her pocket and carries no room at all, so the geography changes across that cut for free. Вася's arrival at SH072 is his head entering the bottom of frame on a beckon, never a crossing.

**The gift is one gesture, not five shots.** The script breaks SH066–068 into pocket, palm and insert. It plays as pocket → hands → her face → hands again, with the glow arriving on the last four words of the line and nowhere earlier.

**The rule cuts away in the middle.** s6jobC was first written as a single 13.7-second locked close-up on one face, which reads as a lecture. It now cuts to Фрося and Вася on «кого оно называет, в того и обернёшься» — which is SH076 in the script, and the beat where the rule actually lands on them — and returns to her for the second half. That is also the only reason Фрося is in the job at all.

**SH081's chuckle and the children's exchanged look were cut.** Both are confirmation shots: they tell the audience what it has just watched. Мама's turn to the rear wall is the cut into scene 7.

---

## The dub

`kuku_flow/dub_clip.sh` lays approved recordings over a generated clip. The generated audio survives as the bed wherever nobody speaks — cloth, the knock of the pencil, the room — and is muted only across the spans a real recording covers, because what the model says under a moving mouth is invented Russian-shaped noise.

**Placement comes from the generated audio's own speech envelope, never from the script's timings.** The model marks where it animated each mouth; a recording placed anywhere else makes the lips disagree with the words. In s6jobA the model's speech runs 3.25s → 11.75s, so the 8.80s recording sits at 3.20.


---

## The take log

| Job | Take | Verdict |
|---|---|---|
| s6jobA | v1, mini 12s | **ACCEPTED.** All four shots landed: the pocket, the pencil sized for her palm, her face opening, the glow arriving on the last four words. No broom — both her hands were busy giving the gift away, which is the shot's own protection. |
| s6jobB | v1, mini 13s | **REJECTED.** She carries the broom through the condition and the beckon, and because that hand is full the crooked finger never happens. The blow onto Вася's crown is good and is lost with the take. 32.5 credits. |
| s6jobB | v2, mini 13s | **ACCEPTED.** No broom, the finger crooks, the blow lands, and Фрося holds the pencil against her chest with both hands exactly as the HANDS block asks. |
| s6jobC | v1, 2.5 17s | **ACCEPTED.** Clean of the broom on the old prompt, the raised finger arrives for the second half of the rule, and the cutaway to both children listening open-mouthed is the best beat in the scene. |
| s6jobD | v1, mini 8s | **ACCEPTED.** The over-shoulder onto both children lands: Фрося's brows come down, Вася's mouth opens, and both of them stop being pleased at the word «секрет». |
| s6jobE | v1, mini 13s | **PARTIALLY ACCEPTED.** Фрося's «Какой секрет?» and Бабушка-Яга's «Сами узнаете» are both right — the grandmother's eyes crease almost shut and her hands are folded exactly as written. Мама's shot fails: she smiles warmly through a line that has to land flat, and she never makes the turn. First 4.45s kept, rest replaced. |
| s6jobF | v1, mini 11s | **ACCEPTED.** No smile — mouth open and level, brows low — and the turn to the rear wall happens on the last beat, which is the cut into scene 7. |

**Spend: 253 credits of the 400 allowance, of which 32.5 was a rejected take.** Two reshoots across six jobs; the second cost 27.5 rather than 32.5 because only the failing performance was reshot.

**Scene 6 is `kuku_flow/2026-08-18_1600_EP1_SCENE6_pencil-rule-secret_v1.mp4`, 65.7 seconds.**

## One thing that could not be prompted away

Мама carries a matchstick in every take. It is not in her tag line and the choreography explicitly excludes "no match, no stick" — it comes from her reference sheet, and it survived the same positive-instruction treatment that displaced the broom. At this scale a match is a plausible household tool, the beds are matchboxes, and it costs the scene nothing, so it is accepted rather than fought. Worth knowing before spending credits on it: **some things in a sheet are not props the model added, they are the character as drawn.**

`s6jobA`'s footage predates the HANDS block, so the prompt now in `emitted/s6jobA.prompt.txt` is not the prompt that produced the clip. The clip passed on its merits and is not worth 30 credits to re-cut for provenance; noting it here is cheaper than pretending the emitted directory is a shooting record.

## The dub, in practice

`line39_YAGA` is 13.28 seconds and s6jobC gave it 11.4 seconds of moving mouth — the model paced the three sentences to the cutaway it was given. Rather than speed the recording up, which the author has already had to accept once, the recording was **split at its own sentence boundaries and re-gapped**: the two pauses between sentences were cut from 0.45s and 0.65s down to 0.25s each, saving 0.6s and leaving the performance untouched. The result is `line39_YAGA_regapped.mp3` at 12.93s, which fits.

That is the general answer when an approved read overruns its picture. Trim the silence between sentences before you touch the sentences.

**And check that it actually fit.** The first re-gap left the line 0.49s longer than the clip, and `-shortest` cut «Снова Васей станешь» down to «Снова Васи» without a word of warning anywhere. The author caught it by ear. `dub_clip.sh` now measures every recording against the video before it mixes and REFUSES with the exact overrun, so the fix is a tighter gap or an earlier placement instead of a shipped truncation.

**Then transcribe the result and read it.** Every line of the finished scene was run back through mlx_whisper and compared to the script. That is thirty seconds of work and it is the only check that catches a word lost at the end of a clip. Note that whisper hallucinates on a quiet opening window — the first 30s of the scene came back as «Девушки отдыхают» until it was re-run in a window that starts at the first word. Transcribe in slices that begin on speech.
