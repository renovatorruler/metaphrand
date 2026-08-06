# «Фрося и Вася» — Episode 1 AI-Marker Audit

Source reviewed: `2026-08-04_EP1_den-rozhdeniya_SPEC_numbered_bilingual.md`

Date: 2026-08-04

The screenplay was not changed. Existing `SP###` identifiers are used throughout this report.

## Outcome

This screenplay does **not** have a broad AI-prose problem. Its dramatic wants are clear, the physical comedy carries the middle of the episode, and Frosya, Vasya, Mama, Papa, and Baba Yaga have distinguishable functions and voices.

The run found:

- no banned AI-vocabulary;
- no negative-parallelism or corrective-definition constructions;
- no copula-dodge language;
- no decorative emoji;
- no mechanical rule-of-three matches in dialogue;
- no flat cross-character echoes;
- no genuine comma-drip passages;
- a small set of judgment-level screenplay tells, concentrated in action prose rather than dialogue.

The current deterministic gates are **not directly compatible with this bilingual screenplay format**. If the file were treated as generated scene input, the gates would reject standard screenplay punctuation and every `(Sound: ...)` label. Those raw failures must not be treated as 126 writing defects.

## Exact deterministic results

The English translation was scanned because the active regular expressions are English-language rules. The Russian screenplay was reviewed in the judgment pass rather than fed into English regexes.

- Blocks scanned: **209**
- Action blocks: **96**
- Dialogue blocks: **113**

### `Gate.craftlint`

- **57** curly-quote findings
- **11** em-dash findings
- **2** fragment-append findings
- **0** AI-vocabulary findings
- **0** negative-parallelism findings
- **0** copula-dodge findings
- **0** emoji findings

Triage:

- The 57 curly-quote findings come from normal typographic apostrophes and quotation marks in the English translation. They are a formatting-policy failure, not evidence of AI prose.
- Most em dashes occur in dialogue, sound effects, or deliberately interrupted sounds. The one materially relevant action-prose occurrence is SP199.
- SP087 is falsely flagged because Vasya reads isolated letters.
- SP227 is falsely flagged because the educational end card lists the episode words.

### `Craft.gateAction`

- **50** colon-reveal findings
- **5** narration em-dash findings
- **1** clipped-fragment finding
- **0** action rule-of-three findings
- **0** negative-parallelism findings
- **0** antithesis-instruction findings
- **0** corrective-definition findings
- **0** copula-inflation findings

Triage:

- Almost every colon finding is the final two characters of `Sound:`. The remaining matches introduce literal letters or title-card words. None is the AI-style rhetorical reveal this rule is meant to catch.
- SP043, SP096, SP209, and part of SP222 use em dashes inside sound notation. These are punctuation choices, not prose tells.
- SP065 is flagged for the standalone action sentence “Silence.” That is normal screenplay grammar in this context.
- SP199 is the one action-line em-dash finding that overlaps a genuine judgment-level issue.

### `Craft.gateDialogue` and cross-line echo

- **0** dialogue-pattern violations
- **0** flat-echo violations

This is a meaningful clean result: none of the spoken lines triggered the framework’s universally banned dialogue constructions.

## Judgment pass: confirmed revision candidates

These are the lines worth reconsidering in a later revision. They are not automatic rewrite instructions.

### High-confidence

- **SP053 and SP204 — repeated knowing-smile tic.** Mama first “hides a smile” and later “allows herself a smile,” while Baba Yaga’s smile supplies the adjoining button. The repetition makes the author visible and gives two scenes the same polished reaction beat.
- **SP096 — unfilmable intention.** The adults “try not to interfere.” The audience cannot see trying-not-to-interfere unless the adults are given concrete behavior.
- **SP124 — narrator supplies interior knowledge.** “A word she has known for a long time” explains Frosya’s knowledge instead of showing only what she does with the tiles.
- **SP180 and SP184 — arranged solution choreography.** The repeated look from problem to tool and back, followed by “her eyes light up,” is an overly prepared visual-thinking sequence. SP184 also forms a conspicuous three-item eye-line list.
- **SP199 — forced triad plus interior label.** “Dusty, rumpled, and glowing with pride” packages Vasya’s return into a polished three-beat description and names the feeling instead of giving him a visible action. This is the strongest confirmed AI-style action line.
- **SP222 — explanatory tail.** The scratch of the pencil followed by nothing already conveys failure. “The word is incomplete, so no car appears” explains the beat after it has played.

### Medium-confidence / mainly a shooting-script concern

- **SP013 — interpretive tail.** “To them, the car is moving by itself” states the characters’ conclusion after the visible information has already established what they can and cannot see. It is useful for locking story logic in a spec script, but a shooting script should carry this entirely through viewpoint.
- **SP109 — hedged micro-change.** “Just perceptibly shorter” is difficult to read onscreen and sounds like prose protecting a seasonal setup. The pencil-wear rule is useful; the degree of visibility needs a concrete visual choice later.
- **SP163 — abstract action.** “The chase is already racing among them” makes the chase itself the performer. The physical routes of Frosya and Vasya-Wasp would be clearer than this polished abstraction.
- **SP176 — omniscient explanation.** “A sealed pocket with no other way in” states a set fact the characters and audience cannot yet verify. This is acceptable as spec-level geography, but it should become demonstrable staging in the shooting script.

## Judgment labels from `Judge.language`

Applied using the framework’s three-label rubric:

- **comma-drip:** none
- **forced-triad:** SP184, SP199
- **arranged-for-effect:** SP180, SP184; SP204 is borderline because the paired smiles manufacture a tidy scene button

## Deliberate stylization that should not be changed automatically

These lines resemble marker families in isolation, but their story or character function currently justifies them:

- **SP076:** Baba Yaga’s balanced “different gifts / one secret” line is knowingly folkloric and belongs to her voice.
- **SP171:** “It wasn’t me” / “It was us” is a crafted reversal, but it marks an actual moral change rather than a dead echo.
- **SP200:** “I tied it. By myself. With a triple knot!” is clipped and punchy, but the rhythm is credible as five-year-old pride and is a purposeful character payoff.
- **SP213:** “Both are fire. They take after me” is polished, but it is a Baba Yaga family joke and an earned departure button.
- **SP087 and SP227:** isolated letters and the word list are educational mechanics, not fragmentary prose.

## Screenplay-humanizer overview

- **Action/description:** generally concrete and legible; the confirmed problems are the unfilmable intentions, arranged eye-line choreography, repeated smiles, and a few explanatory tails listed above.
- **Dialogue:** passes overall. Exposition is motivated by magic rules, character voices remain distinguishable, and the script does not rely on stock AI exchanges.
- **Format:** scene headings and present-tense action are consistent. The bilingual markup itself causes false positives in gates that expect plain generated scene text.
- **Structure/story:** passes. Frosya wants the car and then the scooter; Vasya wants his turn; their conflict causes the loss; the rescue requires both magic systems. The ending preserves the season goal rather than tying everything into a false final bow.
- **Conflict/reaction:** passes. The children create resistance for each other, make the problem worse, and earn the rescue. The birthday applause is literal celebration, not an artificial crowd-validation beat.

## Passes not executed as mutations

- The dialogue-lift operation was not run because it rewrites dialogue, and this audit was expressly non-mutating.
- Content-slop/trope checking was not run because this screenplay has no rolled brief ID for `TropeGate` to compare against.
