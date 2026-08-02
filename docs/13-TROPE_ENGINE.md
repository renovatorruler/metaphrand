# docs/13 — THE TROPE ENGINE (v1, 2026-07-22)

The content-slop engine. The language layer (docs/10-12, SlopScore) fixed how the prose *sounds*; this fixes what the story *does* — the AI's habit of reaching for the same villain, the same twist, the same ending. It measures which tropes the AI over-uses versus human crime fiction, then rolls story requirements that steer away from those grooves. Built on the scaffolding law: an external database + an entropy source + typed requirements, standing without the model. Origin/plan: stories/free-ross/research/2026-07-22_CONTENT_SLOP_PLAN.md.

## LOCKED DECISIONS (author)

- Data: the dhruvilgala/tvtropes 2020 academic dataset. The 2020 cutoff is a FEATURE — the missing years are the AI-slop era; the human baseline stays pre-slop.
- Store: SQLite, studio/data/tropes.db (gitignored; regenerable; loaders committed).
- Baseline = human works whose IMDb genres contain Crime, Mystery, or Thriller.
- ReScript only. TV Tropes content is CC BY-NC-SA: internal tooling only, never redistributed.

## THE DATABASE (built, verified)

30,984 tropes · 40,435 works (17,019 film / 7,921 tv / 15,495 lit) · 1,714,225 work-trope examples · 12,985 works genre-linked to IMDb. Tables: tropes, works, work_tropes, imdb_basics, trope_candidates (the ~1,500 recurring, meta-page-filtered shortlist), corpus_stories + story_tropes + runs (the AI/author texts and their verified tags), deck_blocklist + brief_ledger (the roller's memory).

## MODULE MAP (studio/src)

| module | job | model? |
|---|---|---|
| Sqlite.res | typed better-sqlite3 bindings | no |
| Csv.res | strict RFC4180 parser (embedded newlines/quotes) | no |
| TropeImport.res | load the dataset + IMDb genres into SQLite | no |
| TropeQuery.res | ask the DB: show→tropes, trope→works | no |
| TropeCandidates.res | build the 1,500-trope shortlist | no |
| TropeCorpus.res | register texts to measure (header-stripped, hashed) | no |
| TropeTagger.res | tag a story; every tag needs a verified on-page quote | YES (native worker, budget-capped) |
| TropeHistogram.res | the DIFF REPORT + rebuild the blocklist | no |
| EntropyDeck.res | deterministic roll dodging blocklist + recent briefs | no |
| TropeGate.res | check a draft uses its brief and no grooves | YES (small) |

## CLI CHEATSHEET (run in studio/)

```
node src/TropeQuery.res.mjs show Breaking Bad          # tropes of a work
node src/TropeQuery.res.mjs trope ChekhovsGun          # a trope + example works
node src/TropeCandidates.res.mjs build                 # (re)build the shortlist
node src/TropeCorpus.res.mjs add claude <path>         # register a text
node src/TropeTagger.res.mjs selftest                  # prove quote-verification, no spend
node src/TropeTagger.res.mjs plan                      # ~turn cost, no spend
STUDIO_NATIVE_WORKER_PROVIDER=<host> STUDIO_NATIVE_JOB_DIR=<dir> STUDIO_WORKER_BUDGET=<cap> node src/TropeTagger.res.mjs run-all
node src/TropeHistogram.res.mjs report                 # write data/reports/DIFF_REPORT.md
node src/EntropyDeck.res.mjs roll <seed>               # preview a brief (reproducible)
node src/EntropyDeck.res.mjs roll <seed> commit        # record it in the ledger
STUDIO_NATIVE_WORKER_PROVIDER=<host> STUDIO_NATIVE_JOB_DIR=<dir> STUDIO_WORKER_BUDGET=<cap> node src/TropeGate.res.mjs check <brief_id> <draft>
```

## THE VERIFIED-QUOTE LAW

A trope tag counts only if the model returns a verbatim quote that CODE confirms exists in the text (whitespace-normalized substring, min length). Proven by `selftest`: real quotes pass (even with mangled spacing), fabricated and too-short quotes are dropped. This makes the histogram immune to a model that hallucinates tags.

## STANDING WORKFLOW FOR A NEW STORY

1. `EntropyDeck roll <case-seed> commit` → a brief of 7 tropes (2 common, 3 mid, 2 rare) in rolled modes, dodging my grooves and the last 3 briefs.
2. Write the case to the brief, in the Perseus/Hollis voice.
3. `TropeGate check <brief_id> <draft>` → must use ≥5/7 brief tropes and 0 grooves.
4. Periodically re-run the tagger + `TropeHistogram report` to refresh the groove blocklist as the corpus grows.

## STATUS (2026-07-22)

Built and unit-tested: everything above. The DIFF REPORT's human baseline is populated and clean (top crime tropes: ChekhovsGun, AssholeVictim, BigBad, Foreshadowing, BittersweetEnding, DownerEnding, PoliceAreUseless, DirtyCop). REMAINING: one budget-gated run — `TropeTagger run-all` (~70 native-worker turns) — fills the MINE/AUTHOR columns so sections A/B/C name my actual grooves; then `TropeHistogram report` refreshes. Full step-by-step for a follow-on model: studio/TROPE_ENGINE_HANDOFF.md.
