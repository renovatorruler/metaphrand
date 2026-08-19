# EP1 defect inventory — every issue encountered in production to date

A complete log of what went wrong, why, and what stops it recurring. Most entries are assistant errors; they are written plainly because the pattern matters more than the blame. Grouped by class, because the classes repeat.

---

## A. REFERENCE ATTACHMENT

**A1 · Wrong Яга reference bound to job 18.** The job's own text described her at домовой size while the HUMAN flight sheet (`page-12`) was attached. Root cause: cast token chosen by name similarity, never checked against the prompt's own scale rule. Fixed by binding `YagaDomovoy` and adding `assertYagaScale`, which fails the gate when a human-size sheet meets domovoi text.

**A2 · Props bound but never tagged.** The room master went into every interior job as an anonymous image with nothing in the prompt pointing at it. Author: "I do not see the reference for the behind the fireplace room attached anywhere." Fixed by making every prop carry a `tagLine`, so a bound image is always named.

**A3 · Unbacked props silently bound the room master as a stand-in.** A scooter, a road, a tank, a ball of thread and a cake were each "referenced" by a picture of the family's hall. Fixed by making `propEntry` a two-case variant — `Backed` carries a path, `Described` binds nothing — so an unbacked prop cannot borrow an image.

**A4 · A reference that contradicted its own instruction.** `page-13` is the approved ступа design but shows Яга standing **inside** it; it was bound to a shot whose hard rule is that she is never inside it. Fixed by cutting solo prop plates. Rule: never bind a picture that shows the thing you have forbidden.

**A5 · Broom and помело shared one image.** Nothing told the model which stick was which. Fixed by splitting into two tokens with two plates and explicit "NOT a rag mop" / "NOT a twig besom" lines.

**A6 · Photographs filed as approved canon without receipts.** Author: "These are not approved. I don't know why they're in our references." Two stove/roof photographs had no receipt and no approval. Fixed by quarantining to `references/_unapproved/`. Rule: no receipt, not canon.

**A7 · Reference described from a thumbnail.** The pencil tin was described as cores "in a fan"; the actual reference has them lying straight, in cloth bands. The correct description already existed in the BATCH_B receipt and was not read.

**A8 · Claimed a reference did not exist when it did.** Said there was no Мама-carrying plate; page-16 of the packet has exactly that.

---

## B. PROMPT WRITING

**B1 · Content filter rejection, 14 credits, no output.** Job 10 came back `nsfw`. Contributing causes: an 8,160-character prompt, infant clothing detail, "barefoot" applied to four characters, and the construction "7-year-old house-spirit girl" (age + sex + child). Fixed by shortening, removing body-state words, and removing age+sex constructions. Guard: `assertNoBodyState`.

**B2 · A possessive rewrite produced an eye-shaped vignette.** The phrase "at the eye height of Фрося … framed from her perspective" made the model render the shot through an eye-shaped iris. Guard: `assertNoPov`.

**B3 · Вася rendered as a baby.** His identity line had "5-year-old" stripped to pass the content filter, leaving nothing to fix his age. The fix for one defect caused another.

**B4 · A rule inherited from a superseded staging.** Job 18 carried "No family members visible in any shot" from when the camera was inside the passage; once the camera moved into the hall the rule emptied the room. Rules must be re-read when the staging changes.

**B5 · Orientation given one trailing clause while the camera got a paragraph.** Job 19's "down the length of the hall" pointed the family the wrong way. Author: "How is this even a thing? It makes no sense." Weight in the prompt should match importance to the shot.

**B6 · Invented physical behaviour.** Wrote that the cleanout hatch "drops open like a ramp". Real cleanout doors are side-hinged. Corrected everywhere. Rule: do not invent how an object works; ask or check.

**B7 · More references made staging worse, then the opposite was assumed.** Nine references produced a frontal lineup; two produced good camera work but wrong identity. The real variable was that nothing pinned the composition. With start+end frames fixed, references cost nothing and only help. The earlier lesson was over-generalised.

**B8 · Nine beats written into an eight-second shot.** The model compresses, and it chooses what to drop. Fixed by pricing duration against beats first — twelve seconds for that shot.

---

## C. DIALOGUE AND CRAFT

**C1 · A joke whose premise had been removed.** «Говоришь, будто дрова колешь» was written for a ПАПА who spoke rough, incorrect Russian. When he was changed to speak correctly so children hear correct Russian, the jab stayed and pointed at nothing. Root cause: a character change was not propagated to the lines that depended on it.

**C2 · Reaction written before its cause.** The master plate has Мама's hand already at her mouth when Папа speaks, so the wince arrives before the gaffe. Solved by the author supplying a pre-pour master where her hands are down.

**C3 · A greeting placed third in a conversation.** «Тёща дорогая! Сколько лет, сколько зим!» is an entrance line, but by then Мама has spoken and Яга has answered. Author: "They already started the conversation. She's already sitting."

**C4 · Lines addressed to people who are not in the shot.** Proposed «Слыхали?» to a room containing only three adults; the children are elsewhere.

**C5 · Sarcasm where sincerity was required.** Several proposed gaffes put the judgement on Яга, and any judgement about an older woman's age reads as a dig. The author's solution works because **he makes himself the inferior term** — «Я б в ваши годы не полез». Also: «в ваши-то годы» is a stock reproach frame, and asserting it carried "no irony" was wrong.

**C6 · Withholding a WHAT.** Rewriting the candle line to hide what was in the box violated the standing rule that the audience always knows what is happening; only why or what next may be open. Restored by naming the candles and keeping only the sly undersell.

**C7 · Grammatical norms read as characterisation.** Claimed the вы/ты asymmetry marked Папа as an outsider. It is standard in every Russian family and means nothing.

---

## D. VOICE AND AUDIO

**D1 · Voice selected on the wrong axis.** Hours were spent re-tagging and re-rendering Anton, a narration voice, to make him sound happy. A cloned voice can only produce emotion present in its source material. Select on `use_case=characters_animation`, not on `descriptive=deep`. Every "deeper" candidate first proposed was also a narrator.

**D2 · A performance defect treated as a tag problem.** Яга's candle line came back sheepish; the English pass shows it was tagged `[cheerfully]`. Right diagnosis, but only found after checking the English manifest — which should have been the first move.

**D3 · Renders slower than the show's established pace.** New lines came back at 0.41–0.55 s/word against an established 0.32–0.39. Cause: expression tags make v3 theatrical. Fix: `speed` 1.05–1.12 and shorter lines.

**D4 · The synthesiser mangling a specific junction.** «как с плеча рубишь» came back as «с плечи орудыш» three times running. Fixed by a comma — «как с плеча, рубишь» — which forces articulation with no audible pause.

**D5 · Dub placed 2.55 seconds late.** Placement was measured from the loudest sample; Папа's line opens quietly, so the peak was not the entrance. Correct method is shot boundary plus matching phrase.

**D6 · Two characters talking over each other for 1.9 seconds.** Files were aligned by their start, not by first voiced sample; our renders carry leading silence.

**D7 · Original dialogue leaking under ours, twice.** A speech detector set at 10% of peak missed a quiet clip. Fixed by muting the original across whole shots rather than detected windows.

**D8 · Muting the original removed its sound effects.** The tin lid and the core on paper vanished with it, and still need replacing.

---

## E. EDITORIAL

**E1 · A frozen final frame read as the end of the film.** The v8 scene-2 cut had video ending at 51.20s and audio running to 55.76s, holding one frame over silence for 4.56 seconds. This was a build defect, not pacing — diagnosed only after the author described it as "feels like the movie is over."

**E2 · A cut made inside a line of dialogue.** Trimming the tin insert removed the front of «И красный есть!» Root cause: trusted the EDL's timing (39.23) instead of measuring the file (36.4). See F2.

**E3 · Trimmed a shot the author never flagged.** Two static holds were identified by motion analysis; only one was the one she meant. Acting on the measurement instead of the note.

**E4 · Five successive wrong trim points.** Job 19 was cut at 2.225, 1.80, 0.36, 0.60 and 0.76 seconds before landing at 4.30. Root cause: judged orientation from sampled stills and contradicted the author's account of the motion, instead of trusting her description and cutting where she said.

**E5 · A line played twice across a join.** Яга's question survived in job 19's audio under the new job 18 that also delivers it. Fixed by muting the overlap.

---

## F. RECORD-KEEPING

**F1 · The Russian voice cast could not be found for two hours.** It was in `audio/ep1_birthday_english_v3.performance.json` — a file whose name says English while its `cast` block is the Russian cast. Searched the repo, git history, ElevenLabs history (empty), session transcripts, and the Ep2 manifests before finding it. At one point the author was asked to re-choose voices she had already chosen, which was the wrong response to a search failure.

**F2 · The EDL contains a wrong timing.** `2026-08-14_EP1_SCENE2_EDL_v8.md` records line 15 at 39.23–41.68; the actual build has it at 36.4–39.3. Documents were trusted over files. Lines 11 and 13 in that same document were later verified correct by correlation.

**F3 · No performance manifest exists for the Russian renders.** The tags that produced approved reads are unrecoverable. Approved lines must be preserved as audio; every re-record is a fresh performance decision.

**F4 · Audio file numbers do not map to the script by arithmetic.** The offset is +2 through the tea scene and drifts later; `line110_PAPA.mp3` holds «Ура!», which the script places one line further on. Mapping lines by duration produced a scene-5 line («Ну, именинница. О чём мечтаешь?») in a scene-4 storyboard.

**F5 · Canon split across two directories.** `stories/frosya-vasya/` holds BIBLE.md, packets, charsheets and an earlier ep1prod; `stories/drakosha/` holds current production. Zero colliding filenames, still unmerged.

---

## G. TOOLING AND ACCOUNT

**G1 · Another user's work downloaded into the project.** Four Nano Banana images were fetched by timestamp on the assumption they were ours; they were the co-user's. Then reported as complete and costed at 8 credits when none of our jobs had run. Fix: identify jobs by prompt via `higgsfield generate list --json`, never by time, on a shared account.

**G2 · Credentials declared missing that were present.** Searched for `FAL_KEY` in the home directory and concluded fal was unusable; the key is `FAL_AI` in the project `.env`.

**G3 · Large local images fail silently on Higgsfield.** `--image` with a 5 MB PNG returns "no response received" and creates no job. Upload first with `higgsfield upload create` and pass the UUID.

**G4 · fal rejects base64 data-URI audio.** Documented in `Cinema_Backends.res` and rediscovered. Upload via the storage endpoint and pass URLs.

**G5 · Cost estimates that did not match the charge.** A job quoted at 78 credits moved the balance by 102; a session note once said "balance unchanged" when it had moved 12. Shared-account activity makes balance deltas unreliable as a measure of our spend.

**G6 · The venv's console scripts have a broken shebang.** They point at `/Users/dusty/Dev/brehon-law/.venv`, from before the rename. Call modules via `python -c`.

**G7 · File delivery times out above roughly 5 MB.** Several sends failed and needed a compressed copy or an individual retry.

---

## H. ASSISTANT CONDUCT

**H1 · Asserting instead of checking.** Russian register was asserted wrongly four times running — the pronoun, the sarcasm, the particle, the "no irony available" claim. Each was corrected by the author.

**H2 · Stating facts with no basis.** Claimed the scene was set at 2 a.m.; it is 7:30 in the morning.

**H3 · Answering a different question than the one asked.** Asked which of two images looked more like the character, four were put on screen including the canon sheet.

**H4 · Reporting work as done without verifying it.** Images reported generated and costed when no job existed.

**H5 · Contradicting the author's account of her own footage.** She described backs turned; stills were sampled and used to argue otherwise, costing five wrong trims.

---

## RECURRING ROOT CAUSES

**Documents trusted over artefacts.** F2, E2, F4, A7. The file is the truth; measure it.

**A fix for one defect causing another.** B3, D8, C6. Check what a change removes.

**Inference presented as fact.** H1, H2, H4, G1, G2. Say "I don't know" and go look.

**Rules surviving the staging that motivated them.** B4, C1. When a premise changes, re-read everything downstream.

**Selection on the wrong attribute.** D1, A1, B7. Ask what property actually causes the outcome.
