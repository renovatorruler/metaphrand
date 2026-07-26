# docs/10 — THE AI MARKERS MEGA LIST (v1, 2026-07-20)

The language engine's ground truth for the novel track. Compiled from ~40 sources across three territories: the canonical/academic literature (Wikipedia's AISIGNS field guide, Kobak 774-word excess lexicon, Liang 100+100, Juzek & Ward, Reinhart PNAS), the fiction communities (antislop 517, Sukino ~330, slop-forensics 1000+400, RoyalRoad/AO3/CharacterAI threads, StoryScope), and the computed lexicons (EQ-Bench 50,084-entry scored list, antislop-vllm 2,333 counted phrases + not-X-but-Y regexes, Slop Score 1,648). Raw harvests and machine-readable files: docs/ai-markers/raw/ (see _INVENTORY.md).

## THE FOUR DOCTRINES (how to use this list)

1. FREQUENCY, NOT PRESENCE. Single words are weak evidence (Originality.ai: "delve" appears just 146 times in 10M AI words). The tell is DENSITY and CLUSTERING — many markers co-occurring at high rate (lillupon's law). Enforcement scores per-1,000-words, never bans a lone instance of an ordinary word.
2. STRUCTURE SURVIVES LINE EDITS. StoryScope: narrative-feature detection loses only 1.6% accuracy after stylistic editing. Sentence-level cleanup cannot save a structurally AI-shaped story — the substance battery (drama, human reaction, structure) outranks this document, which is a FINISHING instrument.
3. WRITE TOWARD THE HUMAN SIGNS, not merely away from the tells. The negative space (below) is the actual style target; a text scrubbed of tells but written toward nothing is still dead.
4. LISTS AGE. Markers are era-specific (delve spiked 2023–24 then fell; em-dash suppressed in GPT-5.1-era models). Re-run the harvest quarterly; the era table below dates every major marker.

## TIER 1 — LEXICON (density-scored, per category; full lists in raw/)

A. ABSTRACT-NOUN SLOP: tapestry, symphony, kaleidoscope, landscape (abstract), realm, testament, cornerstone, catalyst, beacon, interplay, intricacies, nuances, synergy, paradigm, journey (metaphorical), odyssey, mosaic, treasure trove, myriad, plethora, camaraderie (162× GPT-4o), solace (95×), resilience, cacophony, crescendo, maelstrom, labyrinth, enigma, gossamer, wonderment, quietude, interconnectedness, canvas (metaphorical), depths, ministrations.
B. VERB SLOP: delve/delves/delved/delving, underscore(s/d/ing), showcase(s/d/ing), highlight (v), foster(ed/ing), bolster(ed/ing), garner(ed/ing), harness, leverage, elevate, empower, unlock, unleash, unveil, illuminate, elucidate, encompass, embark, navigate (metaphorical), streamline, revolutionize, transcend, resonate, epitomize, exemplify, facilitate, cultivate, propel, weave/wove/weaving (metaphorical), grapple, unravel, transform, surpass(ing), align(s) with, emphasize/emphasizing, thrum(med).
C. ADJECTIVE SLOP: intricate (119×), pivotal, crucial, vibrant, vital, meticulous (34.7×), palpable (95×), profound, nuanced, multifaceted, comprehensive, robust, seamless, groundbreaking, transformative, unwavering, unparalleled, invaluable, notable, noteworthy, commendable (9.8×), remarkable, enduring, burgeoning, bustling, ethereal, indelible, fleeting (84×), unspoken (102×), bittersweet, poignant, formidable, foundational, holistic, ever-evolving, cutting-edge.
D. ADVERB SLOP: meticulously, seamlessly, effortlessly, undoubtedly, notably, ultimately, arguably, additionally (sentence-initial), moreover, furthermore, aptly, compellingly, markedly, invariably, amidst (100×), alongside.
E. FICTION DIALOGUE-TAG VERBS (over-varied attribution): murmured, rasped, chimed, interjected, exclaimed, chuckled, smirked, purred, drawled, intoned, quipped, mused, stammered, croaked, boomed, bellowed, barked, hissed, growled, breathed (as tag), gruffly/warmly/softly + said.
F. SHIMMER/MOTION VERBS: flickered, glinted, gleamed, glimmered, shimmered, sparkled, twinkled, danced (light/eyes), pulsed, crackled, cascaded, coursed, rippled, reverberated, echoed, wafted, billowed.
G. FICTION TEXTURE FURNITURE: dust motes (dancing/swirling), lamplight, firelight, cobblestone, windowpanes, rivulets, hues, tendrils, silhouette, halo of light, golden light filtering, casting long shadows.
BUDGET RULE: category A–D words are budgeted, not banned — flag when density exceeds ~2 per 1,000 words per category or any single item repeats in a chapter. Categories E–G are style choices flagged at half that threshold in our house voice (plainness law: said > murmured).

## TIER 2 — PHRASE BANK (hard-flag; regexable; the full 2,333-entry counted list + 517 antislop + Sukino ~330 in raw/)

Whisper family: barely above a whisper; barely a whisper; voice barely audible; voice low and [husky/rough/steady].
Spine family: shiver(s)/chill down (up) the/her/his spine; sent shivers; felt a chill run.
Breath family: took a deep breath; breath hitched; breath caught in throat; let out a breath (s)he didn't know (s)he'd been holding.
Eyes family: eyes widened; eyes narrowed; eyes sparkling/glinting with mischief; eyes never leaving; a smile that didn't reach the/his/her eyes; searching his/her face; half-lidded eyes.
Couldn't-help family: couldn't help but (feel/notice/wonder); couldn't shake the feeling; found himself/herself [verb]-ing.
Air/atmosphere: the air was thick with; hung in the air; hung heavy; the atmosphere was charged; an unspoken tension; air filled with anticipation.
Time dilation: for what felt/seemed like an eternity; time seemed to slow/stand still.
Grip family: knuckles turning white/whitening; jaw clenched; fists balled; gripped like a vice; white-knuckled.
Heart family: heart pounding/racing/hammering (against ribs); heart skipped a beat; heart sank.
Sky openers/closers: the sun dipped below the horizon; dawn broke; painting the sky in hues of; golden hour light.
Resolve clichés: steeled herself/himself; squared his shoulders; a renewed sense of purpose; ready to face whatever [came/challenges lay ahead]; with a newfound [determination/sense of].
Ending slop: they would face it together; was only just beginning; only just getting started; little did (s)he/they know; life would never be the same; that was enough... for now; and together, they...
Doubling tics: maybe, just maybe; perhaps, just perhaps.
Mixture family: a mix(ture) of X and Y; expression a mix of _ and _; a hint of _; voice thick/laced/tinged with; with a mixture of.
Smile/smirk bank: a smile playing/tugging at (her) lips; wolfish grin; grins wickedly; knowing smile; smirk playing on her lips; chuckles darkly.
Silence: the room fell silent; silence stretched; silence hung heavy; the words hung in the air.
Misc high-count: practiced ease; with reckless abandon; moth to a flame; testament to; symphony of; tapestry of; dance of; unbeknownst to; despite herself/himself; torn between; the weight of; the world narrowed; bore silent witness; humble abode; cold and calculating; like an electric shock; threatens to consume; audible pop; swallowed hard; single tear; tucking/pushing a strand of hair (behind her ear); pinched the bridge of his nose; rubbed soothing circles; towers over; like a predator stalking its prey.
Narrative-pivot phrases (vale-ai-tells): something shifted/changed/clicked/snapped; everything changed; that changed everything; and then it clicked/hit me; that's when I/he realized; a turning point; watershed moment; wake-up call; the penny dropped; things fell into place; flipped the script.
Throat-clearers & crutches (narration leak): here's the thing; the truth is; it turns out; Full stop.; Let that sink in.; make no mistake; at the end of the day; in that moment.

## TIER 3 — CONSTRUCTIONS (regex + judge hybrid)

1. NEGATIVE PARALLELISM family (the #1 construction tell; regex suite in raw/antislop-vllm_..._regex_not_x_but_y.json): "not X, but Y"; "it's not (just) X, it's Y"; "not only X but (also) Y"; "It wasn't X. It was Y."; "Not X. Not Y. Z."; "no X, no Y, just Z"; "X stopped being X and started being Y"; "That's not X. That's Y." (corrective definition — already house-banned).
2. RULE OF THREE as rhythm: adjective-adjective-adjective; phrase, phrase, and phrase; triple descriptors (RoyalRoad: "the massive number of triple descriptors").
3. PARTICIPIAL TAILS: sentence-final ", [verb]-ing ..." clauses (GPT-4o 5.3× human; the superficial-analysis engine). Flag ≥2 per page.
4. COPULA AVOIDANCE: serves as / stands as / functions as / represents a — for "is". NOMINALIZATION density (2.1×).
5. FALSE AGENCY: abstractions performing human verbs (the decision emerged; the conversation moved; the room seemed to hold its breath) — avoids naming the actor.
6. FRAGMENT DRAMA: one-line dramatic paragraphs; staccato stacking ("X. And Y. And Z."); "[Noun]. That's it. That's the [thing]."; withhold-then-append fragments ("riders. Four. All black." — house-banned).
7. APHORISM BUTTONS: "X was not weakness. It was survival."-shaped self-quotable closers; announce-then-deliver; engineered colon reveals.
8. SIMILE TRAINS: repeated ", like ..." / ", as if ..." constructions with uniform shape; eyeball-kick metaphors (excessive, occasionally nonsensical).
9. EM-DASH DENSITY: spaced pairs in punched-up positions; also the newer evasions — semicolon inflation, ellipsis-to-dash editing behavior.
10. CURT-DIALOGUE CLIFFHANGERS: "it's quiet... too quiet"-grade beat-buttons; chapter-final punch addiction (the model "hates going long without a punchy moment").
11. SELF-CATECHISM: "The result? ..." "The goal? ..." question-then-answer.
12. ECHO DIALOGUE (house law): flat repetition of the other speaker's word; allowed 1–2× per novel, as a question.

## TIER 4 — DISCOURSE & STRUCTURE (judge-level; StoryScope-derived checks for the battery)

Theme stated by narrator (AI 77% vs human 52%) — the theme may never be explained on the page. Dialogue as philosophy debate (59 vs 34) — conversations argue through character, not as essays with quotation marks. Embodied-metaphor emotion quota (81 vs 38): tight chests, trembling hands, cold sweats — budget them; sometimes a character is just sad and says so. Reference specificity: humans name the actual book/author (47 vs 24) — never "a famous author." Plot shape: beware linear single-track causality, no subplots, tidy endings resolving every thread, uniform moral clarity; the human signs are flashbacks, loose ends, temporal mess, ambiguity. Foreshadowing and callbacks must EXIST (AI "lives in the moment" — LaughingTarget); plant-and-payoff is a checklist item, not an aspiration. Pacing: watch scene compression (pages-worth of drama done in a paragraph) and its twin, even-pacing drone. Continuity: props, rooms, wardrobe, names (the red door that turns blue). Paragraph geometry: 3+ consecutive same-length paragraphs; blocky alternation of dialogue-block/exposition-block/narration-block. Burstiness: uniform sentence rhythm; the oscillation tell (ponderous simile ↔ cliché fragment). Local-minimum wells: the same image/word/gesture recurring because the context reinforces it — track repeats across chapters. The lingering law (Omnipenne): human authors obsess — linger disproportionately on pet details; a text with no obsessions is machine-shaped.

## TIER 5 — DIALOGUE TELLS

Emotional announcement ("I know you're scared, Sarah. But love is..."); therapy-speak ("I can't handle processing your emotions right now"); over-explained interiority in speech; symmetrical diplomatic registers (both speakers doing "customer-service script having a breakdown"); no subtext, no avoidance, no power imbalance, no misdirection; over-attribution + fancy tags (Tier 1E) + adverbed tags; characters narrating the plot to each other; perfect-grammar speech from every register of character (house: dialogue-realism law — halting, messy, inarticulate about pain).

## TIER 6 — NAMING & WORLD DEFAULTS

Character names (the Elara constellation): Elara (85,513× over-represented; 133 published AI books), Elias, Elian, Elianore, Elysia, Elowen, Eldric, Eldrin, Lyra, Eira, Kael, Kaelen, Aria, Aiden, Jaxon, Seraphina, Isolde, Alaric, Aldric, Amara, Anya, Lila, Liora, Lysander, Thorne, plus default-diverse surname pair Chen/Martinez. Place names: Oakhaven, Ravenswood, Whisperwood, Moonwhisper, Eldoria, Elderglen, Eldermere, Havenwood, Meadowgrove, Zephyria, Atheria, Maplewood. RULE: every name in our novels comes from the cast bank / research, never from generation defaults; any name on this list is a build error.
Body-language cliché repertoire (the model's entire emotional vocabulary — budget hard): nervous = lip bite, fidgeting, hair tuck, avoided eyes; anger = clenched fists/jaw, narrowed eyes; attraction = blush, lean-in, dilated pupils; deception = face-touch, darting eyes; sadness = slumped shoulders, crying, looking down. House law: per character, invent a personal tell from the voice card; the generic repertoire is flagged.

## TIER 7 — FORMAT & ARTIFACTS (lint level)

Em-dash spacing style; curly/straight quote mixing; boldface emphasis; headed lists in prose; title-case headings; even paragraphing; emoji; markdown leaks; model artifacts (:contentReference[oaicite:], citeturn0search0, [cite: 1], 【†】, utm_source=chatgpt.com); placeholder leaks ([Your Name], INSERT_URL); knowledge-cutoff phrases; collaborative leaks (I hope this helps, Certainly!, Would you like).

## THE NEGATIVE SPACE — SIGNS OF HUMAN WRITING (the style target)

Plain copulas: there is, it has. Plain verbs: wrote not authored, used not utilized, died not passed away. Superlatives and definitives stated flat (the first, the only, one of the best). Hedges and intensifiers (very, perhaps, tends to). Wordy human constructions (in order to, the fact that). PROFANITY: LLMs use obscenities >100× less than humans — our R-rated register is, statistically, the single strongest human signal available. Obsessive lingering on pet details. Irrelevant specifics that serve nothing (the mess of life). Loose ends. Temporal complexity. Named real references. Emotion labeled directly sometimes. Fourth-wall risk. Uneven paragraphs. Rhythm that breaks its own pattern.

## ERA & MODEL NOTES

2023–mid-24: delve, tapestry, testament, vibrant era. Mid-24–mid-25: align with, fostering, showcasing era. Mid-25+: emphasizing, enhance, highlighting, showcasing; em-dash suppressed in newer GPT; "not X but Y" migrating to "no X, no Y" stacks and semicolons as the old tells get flagged (the arms race is circular — expect drift, re-harvest quarterly). Fiction fingerprints: Claude-family — unreadable/impassive expressions, "something else entirely", hair behind ear, smiles that don't reach eyes, restraint, epilogues; GPT-family — Elara, glinting mischief, voice smooth as silk, conspiratorial whispers, gossip mechanisms, dreams; Gemini — police-report character description before interiority, tidiest endings, "expression unreadable", pinched bridge of nose; DeepSeek — ozone smells, pupils blown wide, "like a lit fuse", front-loaded context.

## ENFORCEMENT MAP (the build plan for the language engine)

1. Tells.res EXPANSION (mechanical, blocking): Tier 2 phrase bank + Tier 6 name list + Tier 7 artifacts as literal/regex matches; Tier 3 constructions 1–2, 6–7, 9, 11 as regexes (import the not-X-but-Y suite from raw/). Source of truth: the machine-readable files in raw/ compiled into the gate at build time.
2. DENSITY SCORER (mechanical, triage): Tier 1 lexicon as per-category per-1,000-word scores with budget thresholds; Tier 4 paragraph-geometry and burstiness metrics; repeats-across-chapters tracker (local-minimum detector). Outputs a scored report per chapter, like craftlint.
3. JUDGE CHECKLIST (model-run, triage): Tier 3 items 3–5, 8, 10; Tier 4 structural checks (theme-explanation, foreshadow/callback existence, lingering, continuity); Tier 5 dialogue tells. Extends the naturalness critic and the battery's finishing wing.
4. THE HUMAN-SIGNS PASS (writing-time, not checking-time): the negative space list goes into the author prompt as the style target (plainness-over-craft law operationalized).
Ordering per pass-phasing law: substance battery first, this megalist's instruments run in FINISHING, fenced, after approval.

## SOURCES

Wikipedia:Signs_of_AI_writing + Signs_of_AI-generated_comments · Kobak et al., Science Advances 2025 (arXiv:2406.07016) · Liang et al., ICML 2024 (arXiv:2403.07183) · Juzek & Ward, COLING 2025 (arXiv:2412.11385) · Reinhart et al., PNAS 2025 · StoryScope (arXiv:2604.03136) · sam-paech: antislop-sampler, antislop-vllm, slop-forensics, slop-score, not-x-but-y-bench, EQ-Bench creative-writing-bench · Sukino Banned Tokens (HuggingFace) · stop-slop (hardikpandya) · vale-ai-tells (tbhb) · lguz humanize-writing-skill · avectats7 anti-ai-writing · GPTZero AI-vocabulary + Forbes coverage · Originality.ai 10M-word study · Pangram Labs blog + arXiv:2402.14873 · Grammarly common-AI-words · Embryo overused-words list · Walter Writes list · Hyacinth 42 phrases · Press Gazette newsroom guide · Hollis Robbins · Record Crash web-fiction guide · Carrie Jones · AJ Writes dialogue essay · lillupon (AO3/Tumblr) · River Editor body-language guide · RoyalRoad forum 162736 · r/CharacterAI, r/SillyTavernAI, r/fanfiction, r/writers, r/WritingWithAI threads · AI Central three-novels experiment · Goodreads Elara list · Neil Clarke/Clarkesworld · WaPo em-dash interactive · NYT Magazine (Kriss) · Chronicle (Belcher). Raw data: docs/ai-markers/raw/ (21 files, inventory inside).
