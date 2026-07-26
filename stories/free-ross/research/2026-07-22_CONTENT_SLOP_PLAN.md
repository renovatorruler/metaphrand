# THE CONTENT-SLOP PLAN (planning only; author commission 2026-07-22)

The premise, from the author: the language layer is now near-solved (Pangram on the calibrated Empty Rack v2: 7% AI, read as human-written/AI-assisted). The next front is STORY CONTENT — the model's narrative choices are as groove-ridden as its sentences were, and in a few years readers will recognize these as AI-slop signatures even when the prose reads human. Goal: get ahead of that catalog before the public writes it. THIS DOCUMENT IS A PLAN; nothing is built yet.

## THE SELF-AUDIT (evidence that the problem is real; from this project's own output)

1. THE EMPTIED CONTAINER — three consecutive flips on one metaphor-shape (grain elevator, nursery, gun rack): "emptiness read as despair was actually making room." Author-caught.
2. THE BENEVOLENT TWIST — deeper groove: every twist resolves toward love/hope (guns sold for the grandchild; room cleared for the baby; grain sold for spring). The reverse twist (innocent surface, monstrous underneath) never got rolled.
3. THE COVETOUS CUSTODIAN — the villain three times running: the man who managed what wasn't his (uncle Walt, partner Dell, neighbor Dodd).
4. MOTIVE MONOCULTURE — inheritance/property/control every time; no lust, shame, spite, ideology, madness, concealment-of-a-lesser-crime, or argument-escalation (which dominates real homicide).
5. THE LOYAL-FEMALE-RELATIVE CLIENT — Carla, Lacy: the woman who won't accept the easy answer and is always vindicated. The client is never wrong, never lying, never the killer.
6. THE QUIET OBJECT CODA — every ending: someone alone, handling a meaningful object (latches, boxed crib, paint chip). Formula.
7. PERFECT CHEKHOV COMPLIANCE — 100% of planted items pay off; no loose threads, dead ends, or props that were just props. Inhumanly efficient.
8. TOTAL MORAL TIDINESS — justice always lands; the system always works; nobody gray wins; families reconcile.
9. ZERO CHAOS — cast is 100% load-bearing; tone never mixes; violence always off-screen and pre-story (suspected safety-training leak = content cowardice). Contrast the author's sample: women laughing past a corpse, the thermostat prank, Pete's crude joke after a beheading, Billy sneaking out — texture people and tonal mixing everywhere.
10. TITLE GROOVE — "The + melancholy noun phrase" (The Porch Light, The Spare Room, The Leaving Man, The Empty Rack).
11. AUTHOR-NAMED: by-the-book stock foils; deliberate-looking diversity casting; LLM name attractors (Sarah Chen, Elara, Marcus) as an era timestamp.

## STEP 1 — THE CONTENT MEGALIST (a docs/10 for story choices)

Three harvest methods:
- SELF-HARVEST: audit this project's own corpus (the 110-case casebook, all episode designs, the older features) and COUNT my distributions: villain-shapes, motives, client-shapes, twist directions, ending valences, death types, title patterns. Every over-represented shape is a marker by definition.
- EXTERNAL HARVEST: collect the already-forming public catalogs of AI-story tells (serialized-fiction reader communities, slush-pile editors on AI submissions, LitRPG/webnovel forums) the way the language lists were harvested.
- COMPARATIVE METHOD (finds markers BEFORE the public names them): run the same counts on human baselines — the author's sample and published crime fiction; every divergence between my distribution and the human one is a marker even if nobody has named it yet.

## STEP 2 — THE PERSEUS STORY PROFILE (his event grammar, not just his sentences)

From the sample: problems solved with physical contraptions (the mannequin rig, the horse clicker, the lamp relay); information delivered in PUBLIC scenes (crowds, salons, town meetings) vs my default private interviews; multi-POV braid including women with their own interior logic (Bethany); violence sudden, physical, on-screen; comedy inside danger (status comedy: Barnett collaring Billy); every section ends on a hook; a standing population of non-load-bearing humans; world-pleasure moments allowed to exist for their own sake. Build as a features-with-quotes profile like the voice profile, so drafts can be audited against it.

## STEP 3 — ENTROPY SOURCES (variety as structure, not willpower; the natal-chart lesson applied to content)

- Motives rolled from real-world crime statistics (arguments and jealousy dwarf inheritance in reality).
- Names from census-by-era-and-region tables, never model priors.
- Twist DIRECTION rolled: warm reveal / cold reveal / no reveal / wrong reveal — the benevolent twist becomes one face of a die.
- Settings, death types, client-shapes, and ending valences rolled the same way.
- The compost heap (real news items) as case seeds — reality has no grooves.

## STEP 4 — THE REPETITION LEDGER + GATE

A running ledger across the series: each story's flip-shape, villain-shape, client-shape, motive, twist direction, ending valence, title pattern. A pre-presentation gate blocks a new story that matches its own recent history (like DramaGate blocks structureless spines). WHY IT MUST BE EXTERNAL: the empty-rack story was written WITH the empty-elevator and empty-room stories in the context window, and nothing felt repeated from inside. The grooves are invisible to the writer; externalize or repeat.

## THE TROPE ENGINE (author's proposal, 2026-07-22 — adopted as the plan's implementation)

The author's design: build a trope database (TV Tropes as the source), score samples of my writing against it into a HISTOGRAM of which tropes I gravitate toward (the bias profile), then drive generation from an entropy source so the rolled story sits outside my grooves. Requirements + entropy + engine, standing without the LLM (the scaffolding law).

DESIGN DECISIONS:
1. THE DATABASE. Phase 1 is a CURATED catalog (300-500 core narrative tropes hand-picked from TV Tropes' plot/character/motive/twist/ending categories), typed in ReScript — not the full ~30k wiki, most of which is fandom minutiae. Full-harvest is a later phase. License note: TV Tropes is CC BY-NC-SA; internal analysis tooling is fine, mind any redistribution (same flag as Open Pangram's NC license).
2. THE FREE BASELINE GOLDMINE. TV Tropes WORK pages are fan-authored trope inventories of human works — the human-baseline histogram (200 crime films/shows' work pages) comes pre-labeled, no tagging needed. My corpus gets tagged; the human corpus is already tagged by the internet. The DIFF between the two histograms IS the content-marker list, quantified.
3. THE TAGGER. LLM-as-tagger through the one warm Session chokepoint, budget-capped (CLAUDE_STUDIO_BUDGET, skip-if-exists caching per story hash — the burned-once laws). Every tag must cite a line-quote as evidence; code verifies the quote exists in the text before the tag counts (no hallucinated tags). Tag the MODE too: played straight / subverted / inverted / averted — slop is distribution and mode, not presence; tropes are not the enemy, grooves are.
4. THE ENTROPY DECK. Weighted sampling over the catalog where weights = target distribution (human baseline, or deliberately anti-my-bias) MINUS recency decay from the repetition ledger (recently used shapes lose weight automatically — the anti-groove pressure formalized). Seeds logged for reproducibility; the author's physical-dice ritual stays available for top-level rolls. ROLL-THEN-FIT doctrine (from the prose chart): rolled tropes get a reconciliation pass into a coherent brief — conflicts resolved, fitting logged — and the fitted brief still must pass the drama gates; entropy feeds the gates, never bypasses them.
5. THE BRIEF. A typed StoryBrief card (like DramaCards): rolled tropes + case seed (casebook) + arena rules + voice profile (Hollis/Perseus) = the requirements the draft must satisfy.
6. THE GATE. Post-draft, the tagger re-tags the DRAFT and diffs against (a) the brief (did the story use what was rolled?), (b) the groove blocklist (the self-audit list above), (c) the ledger (distance from recent stories). Blocks on failure, like DramaGate.

STUDIO MODULES (ReScript only, per the governing law; .resi files are the spec): TropeDb.res, TropeTagger.res, TropeHistogram.res, EntropyDeck.res, StoryBrief.res, TropeGate.res; ledger feeds Battery.res.

KNOWN LIMIT, stated honestly: the engine diversifies the SKELETON (countable choices: villain-shape, motive, twist direction, ending valence). Groove 9 (zero chaos, no texture-cast, tonal uniformity) lives in EXECUTION, not trope choice — that stays with the Perseus story profile and the author's hand.

PHASES: (1) curated catalog + tagger + my-corpus histogram + author-sample histogram → the DIFF REPORT (immediate value: the quantified marker list). (2) Entropy deck + brief generator. (3) Gate + ledger wired into the battery. (4) Optional full TV Tropes harvest + work-page baselines at scale.

DATA ACQUISITION (verified 2026-07-22): THE SPINE = the dhruvilgala/tvtropes academic dataset (github.com/dhruvilgala/tvtropes, ~650MB via Google Drive): 30k tropes with descriptions, 1.9M work-trope examples WITH example text, 40k works (film/tv/lit) cross-matched to IMDb + Goodreads IDs — join IMDb's free public title.basics table for GENRE filtering, so the crime-genre human baseline is a query. THE RESERVE = RyokoExtra/TvTroper on Hugging Face (raw text of ~650k wiki pages, 20GB zip) for full descriptions/laconics at scale (Phase 4). Rejected as inferior: DBTropes RDF (stale), tropescraper/figshare (films only). THE GAP = the spine's scrape is ~2020; PATCH = an on-demand single-page fetcher (rate-limited, disk-cached, NC-license internal use) that pulls any missing work's trope list live and persists it. STORAGE = SQLite at studio/data/tropes.db (gitignored, regenerable; loaders committed), better-sqlite3 under typed ReScript. MODULES = TropeImport.res (load dumps + IMDb genres), TropeQuery.res + CLI (show→tropes = the author's ask-about-a-show feature; trope→example works), then the analysis/generation modules per the design above. FIRST ACTION ON GO: pull the 650MB dataset + IMDb genre table, load SQLite, prove the query layer by answering a show the author names from the local DB.

## PROPOSED BUILD ORDER (awaiting the author's shaping)

1. Self-harvest audit of the existing corpus (the material is already on disk).
2. Perseus story profile from the sample in hand.
3. Entropy tables (motives, names, twist directions, valences).
4. Repetition ledger + gate.

Graduate the megalist to docs/13 once it exists. Nothing above is built yet; plan only, per instruction.
