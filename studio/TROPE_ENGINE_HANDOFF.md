# TROPE ENGINE — EXECUTION HANDOFF (written 2026-07-22 for a follow-on model)

You are executing a designed plan. Do not redesign. Where this document is silent, prefer the smallest change that satisfies the acceptance test. If genuinely blocked, stop and report the blocker; do not improvise around it.

## WHAT THIS IS

An engine that (1) stores the TV Tropes universe locally, (2) measures which tropes the AI's own stories over/under-use versus human crime fiction (the DIFF REPORT), and (3) rolls entropy-driven story requirements that steer new stories away from the AI's grooves. Full background: /Users/dusty/dev/metaphrand/stories/free-ross/research/2026-07-22_CONTENT_SLOP_PLAN.md.

## DECISIONS ALREADY LOCKED BY THE AUTHOR (do not reopen)

1. Data source: the dhruvilgala/tvtropes 2020 academic dataset. The 2020 cutoff is a FEATURE, not a gap — the author: the missing years are "the last six years of basically slop"; the baseline stays pre-slop-era human. No live scraping, no full wiki dump.
2. Store: SQLite at studio/data/tropes.db (already built).
3. Baseline for comparisons: works in the database whose IMDb genres contain Crime, Mystery, or Thriller (film + tv).
4. All code in ReScript in /Users/dusty/dev/metaphrand/studio/src/. NO Python anywhere in the project — this is a hard law. Shell one-liners for ops (gunzip/awk) are fine; source files are ReScript only.
5. Data directory stays gitignored (studio/.gitignore already has data/). Commit source only.
6. TV Tropes content is CC BY-NC-SA: internal tooling only; never redistribute the data.

## CURRENT STATE (verify before doing anything)

Everything below EXISTS and WORKS. Run the verification first; if the numbers match, do not rebuild any of it.

```
cd /Users/dusty/dev/metaphrand/studio
node src/TropeQuery.res.mjs stats
# expected:
#   tropes 30984
#   works 40435
#   examples 1714225
#   genre_linked ~13000 (12944 imdb_basics rows)
node src/TropeQuery.res.mjs show Breaking Bad   # expect: 1098 tropes, genres Crime,Drama,Thriller
node src/TropeQuery.res.mjs trope ChekhovsGun   # expect: description + example works
```

Existing modules (do not break them): src/Sqlite.res (better-sqlite3 bindings), src/Csv.res (strict RFC4180 parser), src/TropeImport.res (loader CLI), src/TropeQuery.res (query CLI). Raw data in studio/data/raw/ (do not re-download; the Drive zip and IMDb tsv.gz are there).

Build command: `npx rescript` in the studio dir. It must finish clean (one pre-existing unused-value warning in Cinema_Backends.res is normal). `npm run lint:hatches` must pass — the project BANS escape hatches (no Obj.magic, no %raw). Write external bindings instead.

## MODEL-WORK RULES (hard laws; violations have burned real money)

- ALL model work goes through `Session.ask`. READ `src/Session.resi` and follow `NATIVE_WORKERS.md`. Session prepares a provider-bound job; the trusted host delegates it through a same-provider native worker. Never shell out to `claude -p`, `codex exec`, or a provider API per item.
- Budget: respect `STUDIO_WORKER_BUDGET` (environment, human-set). Refuse to run tagging if it is unset.
- Test without spend: `STUDIO_FAKE_WORKER=1 STUDIO_FAKE_WORKER_BIN=scripts/fake-claude.mjs` (see the `smoke` script in `package.json`) exercises the pipeline with a local fake worker.
- Cache everything: skip work whose output already exists (key on content hashes). Re-runs must be ~free.

## STEP 1 — CANDIDATE TABLE (pure SQL, no model)

Goal: a shortlist of taggable tropes (the full 31K is too many to prompt with).

Create src/TropeCandidates.res with a CLI `node src/TropeCandidates.res.mjs build` that executes:

```sql
DROP TABLE IF EXISTS trope_candidates;
CREATE TABLE trope_candidates AS
SELECT t.trope_id, t.name,
       substr(t.description, 1, 300) AS blurb,
       COUNT(DISTINCT wt.title_id) AS n_works,
       SUM(CASE WHEN i.genres LIKE '%Crime%' OR i.genres LIKE '%Mystery%' OR i.genres LIKE '%Thriller%'
                THEN 1 ELSE 0 END) AS n_crime
FROM work_tropes wt
JOIN tropes t ON t.trope_id = wt.trope_id
JOIN works w ON w.title_id = wt.title_id
LEFT JOIN imdb_basics i ON i.tconst = w.tconst
GROUP BY t.trope_id, t.name
HAVING n_works >= 50 AND n_crime >= 5
ORDER BY n_crime DESC
LIMIT 1500;
```

Acceptance: `SELECT COUNT(*) FROM trope_candidates;` returns 1500 (or slightly fewer if the HAVING bites harder; 1200+ is fine). Spot-check that ChekhovsGun and TheReveal are present.

## STEP 2 — CORPUS REGISTRATION (no model)

Goal: register the texts whose trope habits we are measuring.

Schema (add via exec in a new src/TropeCorpus.res):

```sql
CREATE TABLE IF NOT EXISTS corpus_stories(
  story_id TEXT PRIMARY KEY,        -- first 12 hex of sha256 of file content
  path TEXT, source TEXT,           -- source in ('claude','author')
  added_at TEXT);
CREATE TABLE IF NOT EXISTS story_tropes(
  story_id TEXT, trope_id TEXT,
  mode TEXT,                        -- 'straight'|'subverted'|'inverted'|'averted'
  quote TEXT,                       -- verbatim evidence, verified to exist in the text
  run_id TEXT,
  PRIMARY KEY(story_id, trope_id));
CREATE TABLE IF NOT EXISTS runs(
  run_id TEXT PRIMARY KEY, started_at TEXT, model TEXT, calls INTEGER, notes TEXT);
```

CLI: `node src/TropeCorpus.res.mjs add <source> <path>` (computes hash, inserts, prints story_id). Register these (all under /Users/dusty/dev/metaphrand/stories/free-ross/):
- claude: research/2026-07-22_STORY_the-empty-rack_v2.md, research/2026-07-22_STORY_the-spare-room_full.md, research/2026-07-21_EPISODE_the-leaving-man_v2_PLAIN.md, S2_the-porch-light_v2.md (in stories/free-ross/)
- author: the sample at /Users/dusty/.claude/uploads/eeac6f11-d79f-4ae2-8e85-15472785dee4/372ad41f-Novel.md — COPY IT FIRST to stories/free-ross/research/PERSEUS_SAMPLE_novel.md (uploads dir is not permanent), register the copy.

Strip markdown headers above the first `---` before hashing/tagging (the files carry doc headers; only the story body counts).

Acceptance: `SELECT source, COUNT(*) FROM corpus_stories GROUP BY source;` → claude 4, author 1.

## STEP 3 — THE TAGGER (model calls; the heart of Phase 1)

Goal: for each corpus story, verified trope tags.

src/TropeTagger.res, CLI `node src/TropeTagger.res.mjs run <story_id>` and `run-all`.

Two stages per story, all through Session:
- Stage A (shortlist): chunk trope_candidates into groups of 150 (trope name + blurb first sentence). One Session turn per chunk: "Here is a story. Here are 150 trope names with one-line meanings. List ONLY the trope names that plausibly appear in this story. Output one name per line, nothing else." Collect the union. 1500/150 = 10 turns per story.
- Stage B (verify): for each shortlisted trope (expect 20-60), one Session turn batched 10 at a time: "For each trope below, if it truly appears in the story, output: TropeName | mode(straight/subverted/inverted/averted) | a verbatim quote (max 25 words) from the story that evidences it. If it does not appear, output: TropeName | absent. Quotes must be copied exactly."
- CODE VERIFICATION (non-negotiable): normalize whitespace on both sides; the quote must appear as a substring of the story text, else the tag is DROPPED and counted as rejected. Insert only verified tags into story_tropes. Log run in runs (calls counted).

Prompt discipline: pass the story text once per chunk turn (it is the same Session; if Session supports context reuse across turns, send the story once and reference it — read Session.resi and do whatever it actually supports; do not invent capabilities).

Acceptance: run-all completes within budget; every story has >= 10 verified tags; `SELECT COUNT(*) FROM story_tropes WHERE quote='' ` returns 0; rejected-quote count printed per story (some rejections are normal).

## STEP 4 — HISTOGRAMS + THE DIFF REPORT (pure SQL + formatting, no model)

src/TropeHistogram.res, CLI `node src/TropeHistogram.res.mjs report` writing data/reports/DIFF_REPORT.md.

Three distributions:
1. MINE: share of claude-source stories containing each trope: `SELECT trope_id, COUNT(*)*1.0/(SELECT COUNT(*) FROM corpus_stories WHERE source='claude') AS share FROM story_tropes st JOIN corpus_stories cs ON cs.story_id=st.story_id WHERE cs.source='claude' GROUP BY trope_id;`
2. AUTHOR: same for source='author'.
3. BASELINE: share of crime-genre works containing each trope:
```sql
WITH crime_works AS (
  SELECT DISTINCT w.title_id FROM works w JOIN imdb_basics i ON i.tconst=w.tconst
  WHERE i.genres LIKE '%Crime%' OR i.genres LIKE '%Mystery%' OR i.genres LIKE '%Thriller%')
SELECT wt.trope_id, COUNT(DISTINCT wt.title_id)*1.0/(SELECT COUNT(*) FROM crime_works) AS share
FROM work_tropes wt JOIN crime_works cw ON cw.title_id=wt.title_id
GROUP BY wt.trope_id;
```

Report sections (markdown, human-readable, trope NAMES not ids):
- A. OVERUSED BY ME: tropes where my share >= 0.5 AND baseline share < 0.15, sorted by (my share - baseline), top 50, each with one evidence quote from story_tropes.
- B. MY BLIND SPOTS: baseline share >= 0.10 AND my share = 0 (tropes common in human crime fiction that I never touch), top 50.
- C. AUTHOR VS ME: tropes the author's sample uses that I never do, and vice versa.
- D. RAW COUNTS appendix.

Acceptance: the file exists, sections non-empty, and section A visibly contains known grooves (expect entries like BittersweetEnding-adjacent shapes; if section A is empty the thresholds are too tight — halve them once and note it).

## STEP 5 — THE ENTROPY DECK (no model)

src/EntropyDeck.res, CLI `node src/EntropyDeck.res.mjs roll <seed>`.

- Blocklist: top-25 tropes from report section A (store as table deck_blocklist, rebuilt by the report step).
- Frequency bands over trope_candidates by n_crime: HIGH = top third, MID = middle, RARE = bottom.
- A roll (deterministic for a seed; use a simple LCG over the seed, no Math.random): 2 from HIGH, 3 from MID, 2 from RARE, all excluding blocklist AND excluding any trope used by the last 3 briefs (table brief_ledger). Per trope roll a mode: straight 60%, subverted 25%, inverted 10%, averted 5%.
- Output: markdown brief card (trope name + blurb + rolled mode) printed AND inserted into brief_ledger(brief_id, seed, created_at, tropes_json).

Acceptance: same seed → identical roll; different seeds differ; nothing from the blocklist ever appears; consecutive rolls share no tropes.

## STEP 6 — THE GATE (model calls, small)

src/TropeGate.res, CLI `node src/TropeGate.res.mjs check <brief_id> <draft_path>`: run the Stage-B tagger against ONLY the brief's 7 tropes plus the 25-trope blocklist. PASS if >= 5 of 7 brief tropes are verified-present AND 0 blocklist tropes present. Print a verdict block with the evidence quotes.

Acceptance: gate an existing story against a fresh roll — it should FAIL the brief-presence check (it wasn't written to the brief) and report cleanly.

## STEP 7 — DOCTRINE DOC

Write docs/13-TROPE_ENGINE.md in /Users/dusty/dev/metaphrand/docs/: what the engine is, the locked decisions, module map, CLI cheatsheet, and the standing workflow for a new story: roll → brief → write → gate → report refresh. Keep it under two pages. Update task #72 as steps complete.

## PITFALLS (every one of these has already bitten; read twice)

1. zsh: `echo ===X===` FAILS (zsh glob). Quote echo strings.
2. ReScript %re: backslashes in %re strings misbehave — use Js.Re.fromStringWithFlags("\\s+", ~flags="g").
3. Paths: build in /Users/dusty/dev/metaphrand/studio (main tree). There are WORKTREES with their own studio copies — do not touch them, do not `cd` into them.
4. better-sqlite3 stmt.run takes an ARRAY of params (see Sqlite.res bindings). Wrap bulk inserts in Sqlite.bulk (transaction) or imports take hours.
5. readFileSync needs the "utf8" arg or you get a Buffer.
6. The lint bans Obj.magic and %raw — clean externals only (`npm run lint:hatches`).
7. Do not re-download the data; do not commit anything under data/; do not touch genderedness_filtered.csv (unused by design).
8. Story files carry doc headers above a `---` line — strip before hashing/tagging.
9. Session: read src/Session.resi before writing tagger code; use only what exists.
10. If a Session/tagging step would exceed budget, STOP and report; never loop retries against the budget.
