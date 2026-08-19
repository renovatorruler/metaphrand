# EP1 jobs 10–19 — prompt audit and corrections (v2, 2026-08-13)

Scope: the children arrive home, Фрося receives her presents, and Баба-Яга arrives. Jobs 10 through 19, SH018 through SH046.

The wiring problem you remembered — Мама and Папа coming out different in every shot — is already solved and was solved before this audit. Every character in these ten jobs now resolves through the typed registry, so the @TAG line in the prompt and the reference image bound to the job come from the same record and cannot disagree. What was still wrong was the writing: the choreography text carried descriptions that contradict approved canon, and three of them would have produced unusable footage.

## 1 · Description gaps found and corrected

**The юла was described with the wrong mechanism.** The prompts said "a central twist handle" and "two small seats". The approved prop sheet shows a rope wound around the top neck ending in a wooden pull-toggle, and two proper little wooden chairs with slatted backs, armrests and stitched patchwork cushions. Papa does not twist anything; he hauls a rope straight out. That is a different animation, not a different adjective. Job 12's entire shot B was built on the wrong action.

**The art tin was described as something we do not have.** The prompts said "a flat box". The approved asset is a round shallow metal tin with a rolled rim and worn bare metal, its lid painted in parallel diagonal red and orange stripes chipped back to metal at the edges. Inside, a cream woven cloth liner holds exactly five faceted hexagonal cores — red, orange, yellow, green, blue — lying flat side by side in a single straight row, points all one way, under two stitched cream cloth bands.

Correction to my own first pass on this, caught by the author: I described the cores as standing in a fan. They lie flat in a row. I also wrote "never fabric slots" as a constraint, which was wrong in the other direction — the cloth retaining bands are real, and the v1 prompt's "fabric slots" was closer to the asset than my correction was. The constraint now names what is actually there instead of forbidding it.

**Half the batch was still describing the old room.** Jobs 10, 17, 18 and 19 had been updated to the hall inside the bricked-up fireplace — boulder bricks, the riveted iron plate as the far wall, the plank-on-spools table, the bulb garland, the little rusty iron door. Jobs 11 through 16 were still saying "the main room behind the stove" and "the thread-spool table". The batch was internally inconsistent, which is exactly how a set drifts between shots.

**Баба-Яга was given a face that is not hers.** The prompts described "sharp chin, ember eyes" — invented, and closer to the menacing stereotype the show refuses. Approved canon is a warm sly face with a gold tooth, a wine-red kerchief with white polka dots, and an olive-green shawl with a stitched patch.

**She was also re-described inside the creative text** in jobs 15, 16 and 19, which fights the @YAGA line the emitter adds from the registry. Two descriptions of the same character in one prompt is how you get two different characters. Removed. Her name is also normalised from "BABA YAGA" to "YAGA" so it matches the tag.

**Папа had invented costume detail** — "wood shavings in his hair" — that appears nowhere on his sheet. Removed.

## 2 · The serious one: job 15 broke the scale law

The transformation sheet fixes Баба-Яга at human height, about 147 cm, and domovoi height, about 9 cm, at a ratio of 1:16, and states plainly that the change happens **after the chimney**. The shooting script agrees: SH037 has the tiny silhouette emerge *from* the spiral.

Job 15 described "a wooden mortar the size of a teacup" and locked it in with "the mortar is teacup-sized against the human roof" — three shots before she shrinks. She would have arrived already tiny, and the spiral in job 16 would have had nothing to do.

Corrected: jobs 15 and 16 now carry an explicit SCALE LOCK. She is a full-sized human woman in a human-sized mortar over the roof, and the shrink happens only inside the spiral, with the two sizes never in the same frame.

## 3 · Reference gaps — assets that do not exist

| # | What | Needed by | Status |
|---|---|---|---|
| 1 | The human house exterior: roof and chimney | jobs 15, 16 | **Blocking.** The only file was the unapproved photograph, now quarantined. |
| 2 | The soot passage interior | job 18 shot A | Missing. Also stood on a quarantined photograph. Job 18 passes the gate on the iron door and ступа, but the passage geography itself is unbacked text. |
| 3 | Клочок бумаги — the paper scrap | job 14 shot C | Missing. Also on the scenes 7–9 list. |
| 4 | The shelf and its two thimbles | job 17 shot A | Missing. |
| 5 | The cloth cover over the юла | jobs 10, 11 | Missing. Minor — plain cloth. |
| 6 | Яга's pestle and lashed bundles | jobs 15, 16, 18, 19 | Missing, and contradicted — see the ruling below. |

Everything else these ten jobs need exists and is bound: Фрося, Вася, Мама, Папа, Руся and Муся, Яга in both forms, the hall, the юла, the tin, the little iron door with its two states, and the ступа.

## 4 · Three rulings I need from you

**The pestle and the bundles.** The shooting script is explicit at SH034: «Пест лежит поперёк борта, помело правит сзади, а свёртки крепко привязаны». The approved ступа sheet, dated two days later and labelled approved canon, shows a plain carved mortar with no pestle across the rim, no bundles lashed anywhere, and the broom held in her hand rather than steering behind. Both are approved documents and they disagree. I have left the script's version in the prompts because it is the more specific instruction, but the newer sheet would normally win. Which is it?

**The scale correction.** I applied the transformation sheet's law to jobs 15 and 16 rather than the prompt's teacup. Confirm.

**Which Яга sheet binds in flight.** The registry currently binds page-12, «Яга в ступе — flight canon». Page-10 is «Яга — human flight form, лапти». For jobs 15 and 16, where she is human-sized, page-10 may be the better binding.

## 5 · The Russian question

Your instinct is that the whole prompt may need to be in Russian so the model stops mispronouncing. I can't confirm that, and I think there is a better answer.

The mispronunciations you heard — ношки for носки, Фроша for Фрося — came out of Seedance generating its own dialogue audio. Writing the surrounding cinematography in Russian doesn't obviously change how it pronounces a quoted Russian line, and it works against the model: Seedance follows shot, lens and blocking instructions best in English, which is why the doctrine specifies English for the directive blocks and Russian only inside the quoted lines.

The stronger fix is that we already solved this problem once, elsewhere. Final episode audio is not Seedance's — it is ElevenLabs v3 driven by the pronunciation registry, which is what fixed ОСА, МОТОК, САМОКАТ and САЛАТ by respelling them phonetically for the voice. If the clips are generated with the dialogue lines removed and the audio laid over, the video model never speaks Russian at all and the failure mode disappears completely rather than being argued with.

The cost of that is lip sync: a silent generation gives no mouth movement to match. So the real question is whether these shots need visible speech, and that is a decision about the show, not about prompts.

If you want to settle the language question with evidence rather than theory, the cheap test is one job generated twice — English directives with Russian quoted lines, against the whole prompt in Russian — and listen. One job, two clips.

## 6 · Where the batch stands

Eight of the ten jobs pass the reference gate and are ready for your read.

Jobs 15 and 16 fail the gate, correctly, on the missing roof reference. They cannot be submitted until the human-world exterior exists, which needs your decision on what that world looks like before anything can be made.

The emitted prompts live in `production/seedance_batch/emitted/`. They are review material only — the submission path regenerates them from the typed records at submit time, so editing one by hand changes nothing and cannot leak into a job.
