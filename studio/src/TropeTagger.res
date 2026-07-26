// Step 3 — the tagger. Reads a corpus story, asks the warm Session which candidate
// tropes appear, VERIFIES each claimed quote exists in the text (code, not trust),
// and stores only verified tags. Two stages: shortlist (A), then verify+mode (B).
//
// Usage:
//   node src/TropeTagger.res.mjs selftest         no model; proves the pure logic
//   node src/TropeTagger.res.mjs plan              no model; prints turn cost
//   node src/TropeTagger.res.mjs run <story_id>    REAL model spend (needs budget)
//   node src/TropeTagger.res.mjs run-all           REAL model spend (needs budget)

@scope("process") @val external argv: array<string> = "argv"
@scope("process") @val external exit: int => unit = "exit"
@scope("process") @val external env: Js.Dict.t<string> = "env"

let dbPath = "data/tropes.db"
let chunkSize = 150
let batchSize = 10
let minQuoteChars = 12

// ---- pure helpers (unit-tested by `selftest`) ----------------------------

let norm = (s: string): string =>
  s
  ->Js.String2.toLowerCase
  ->Js.String2.replaceByRe(Js.Re.fromStringWithFlags("\\s+", ~flags="g"), " ")
  ->Js.String2.trim

// A quote counts if it shares a contiguous run of >= anchorWords real words with the
// story. Strict enough that a hallucination can't fake a 4-word run; loose enough that
// the model trimming or fixing a word at the edges doesn't nuke a real tag.
let anchorWords = 4
let verifyQuote = (storyNorm: string, quote: string): bool => {
  let qw = norm(quote)->Js.String2.split(" ")->Js.Array2.filter(w => w != "")
  let n = Js.Array2.length(qw)
  if n < anchorWords {
    // very short quote: require exact presence and a real length
    Js.String2.length(norm(quote)) >= minQuoteChars && Js.String2.includes(storyNorm, norm(quote))
  } else {
    let hit = ref(false)
    for i in 0 to n - anchorWords {
      if !hit.contents {
        let window = qw->Js.Array2.slice(~start=i, ~end_=i + anchorWords)->Js.Array2.joinWith(" ")
        if Js.String2.includes(storyNorm, window) {
          hit := true
        }
      }
    }
    hit.contents
  }
}

let allowedMode = m =>
  switch m {
  | "straight" | "subverted" | "inverted" | "averted" => m
  | _ => "straight"
  }

// Stage A reply: one trope name per line. Keep only lines that are known candidate names.
let parseStageA = (known: Js.Dict.t<bool>, reply: string): array<string> => {
  reply
  ->Js.String2.split("\n")
  ->Js.Array2.map(l => l->Js.String2.replaceByRe(Js.Re.fromStringWithFlags("[^A-Za-z0-9]", ~flags="g"), "")->Js.String2.trim)
  ->Js.Array2.filter(l => l != "" && Js.Dict.get(known, l)->Belt.Option.getWithDefault(false))
}

// Stage B reply lines: "Name | mode | quote"  or  "Name | absent"
type claim = {name: string, mode: string, quote: string}
let parseStageB = (reply: string): array<claim> => {
  reply
  ->Js.String2.split("\n")
  ->Js.Array2.map(line => {
    let parts = line->Js.String2.split("|")->Js.Array2.map(Js.String2.trim)
    if Js.Array2.length(parts) >= 3 && Js.String2.toLowerCase(parts->Js.Array2.unsafe_get(1)) != "absent" {
      let name = parts->Js.Array2.unsafe_get(0)
      let mode = allowedMode(Js.String2.toLowerCase(parts->Js.Array2.unsafe_get(1)))
      let quote = parts->Js.Array2.sliceFrom(2)->Js.Array2.joinWith("|")->Js.String2.trim
      Some({name, mode, quote})
    } else {
      None
    }
  })
  ->Js.Array2.filter(o => o != None)
  ->Js.Array2.map(o => Belt.Option.getExn(o))
}

// ---- DB access -----------------------------------------------------------

let jstr = (row, key) =>
  switch Js.Json.decodeObject(row) {
  | Some(o) => switch Js.Dict.get(o, key) {
    | Some(v) => switch Js.Json.decodeString(v) { | Some(s) => s | None => "" }
    | None => "" }
  | None => ""
  }

let firstSentence = (blurb: string): string => {
  let flat = norm(blurb)
  switch Js.String2.indexOf(flat, ". ") {
  | -1 => Js.String2.length(flat) > 120 ? Js.String2.substring(flat, ~from=0, ~to_=120) : flat
  | i => Js.String2.substring(flat, ~from=0, ~to_=i)
  }
}

let candidates = db =>
  Sqlite.allNone(Sqlite.prepare(db, "SELECT name, blurb FROM trope_candidates ORDER BY n_crime DESC"))

let knownNames = (cands): Js.Dict.t<bool> => {
  let d = Js.Dict.empty()
  cands->Js.Array2.forEach(r => Js.Dict.set(d, jstr(r, "name"), true))
  d
}

// normalized-name -> (trope_id, canonicalName) over the SHARED candidate vocabulary,
// so a free-named model tag only counts if it maps to a trope the baseline also uses.
let normName = (s: string): string =>
  s->Js.String2.toLowerCase->Js.String2.replaceByRe(Js.Re.fromStringWithFlags("[^a-z0-9]", ~flags="g"), "")

let candIndex = (db): Js.Dict.t<(string, string)> => {
  let d = Js.Dict.empty()
  Sqlite.allNone(Sqlite.prepare(db, "SELECT tc.name, tc.trope_id FROM trope_candidates tc"))
  ->Js.Array2.forEach(r => Js.Dict.set(d, normName(jstr(r, "name")), (jstr(r, "trope_id"), jstr(r, "name"))))
  d
}

let chunk = (arr, size) => {
  let out = []
  let i = ref(0)
  while i.contents < Js.Array2.length(arr) {
    let _ = Js.Array2.push(out, arr->Js.Array2.slice(~start=i.contents, ~end_=i.contents + size))
    i := i.contents + size
  }
  out
}

// ---- prompts -------------------------------------------------------------

// Single-turn tagging: the model already knows TV Tropes; don't re-send a 1500-name
// list. Ask it to name what it sees with an on-page quote; we keep only shared-vocab
// matches and verify the quotes.
let tagPrompt = story =>
  "You are tagging a short crime story with TV Tropes (tvtropes.org).\n\nSTORY:\n" ++
  story ++
  "\n\nName every TV Trope that genuinely appears in this story. For EACH, output one line:\n" ++
  "CanonicalName | mode | quote\n" ++
  "  CanonicalName: the standard TV Tropes page name in CamelCase (e.g. ChekhovsGun, RedHerring, BittersweetEnding, AssholeVictim)\n" ++
  "  mode: straight | subverted | inverted | averted\n" ++
  "  quote: a short EXACT phrase (4 to 10 words) copied word-for-word from the story, no paraphrasing\n" ++
  "Include character tropes, plot tropes, ending tropes, and setting tropes. Aim for at least 15 if present. Output only the lines, nothing else."

let recallPrompt = (already: array<string>) =>
  "Good. Now name ADDITIONAL TV Tropes that appear in the SAME story above and are NOT in this list:\n" ++
  already->Js.Array2.joinWith(", ") ++
  "\nSame format: CanonicalName | mode | quote. Only genuinely-present tropes. Output only the lines."

let stageBPrompt = (story, names: array<string>) => {
  let list = names->Js.Array2.joinWith("\n")
  "STORY:\n" ++
  story ++
  "\n\nFor EACH trope below, decide if it truly appears in the story.\n" ++
  "If it appears, output a line: TropeName | mode | quote\n" ++
  "  mode is one of: straight, subverted, inverted, averted\n" ++
  "  quote is a VERBATIM span (max 25 words) copied exactly from the story that evidences it\n" ++
  "If it does not appear, output: TropeName | absent\n" ++
  "Output one line per trope, nothing else.\n\nTROPES:\n" ++ list
}

// ---- orchestration -------------------------------------------------------

let runStory = async (~ask: string => promise<string>, db, runId, storyId) => {
  let body = Sqlite.getArray(Sqlite.prepare(db, "SELECT body FROM corpus_stories WHERE story_id=?"), [storyId])
  switch body->Js.Nullable.toOption {
  | None => {
      Js.log("no such story_id: " ++ storyId)
      0
    }
  | Some(b) => {
      let story = jstr(b, "body")
      let storyNorm = norm(story)
      let idx = candIndex(db)
      let ins = Sqlite.prepare(
        db,
        "INSERT OR REPLACE INTO story_tropes(story_id, trope_id, name, mode, quote, run_id) VALUES (?,?,?,?,?,?)",
      )
      let kept = Js.Dict.empty()
      let rejectedQuote = ref(0)
      let offVocab = ref(0)

      // ingest one model reply of "Name | mode | quote" lines
      let ingest = reply =>
        parseStageB(reply)->Js.Array2.forEach(c => {
          switch Js.Dict.get(idx, normName(c.name)) {
          | None => offVocab := offVocab.contents + 1
          | Some((tid, canonical)) =>
            if verifyQuote(storyNorm, c.quote) {
              Sqlite.runArray(ins, [storyId, tid, canonical, c.mode, c.quote, runId])
              Js.Dict.set(kept, canonical, true)
            } else {
              rejectedQuote := rejectedQuote.contents + 1
            }
          }
        })

      // turn 1: tag; turn 2: recall. Each guarded so one bad turn won't kill the run.
      switch await ask(tagPrompt(story)) {
      | reply => ingest(reply)
      | exception Session.SessionError(m) => Js.log("  " ++ storyId ++ " tag turn failed: " ++ m)
      }
      switch await ask(recallPrompt(Js.Dict.keys(kept))) {
      | reply => ingest(reply)
      | exception Session.SessionError(m) => Js.log("  " ++ storyId ++ " recall turn failed: " ++ m)
      }

      let n = Js.Array2.length(Js.Dict.keys(kept))
      Js.log(
        "  " ++ storyId ++ " verified tags: " ++ Belt.Int.toString(n) ++
        "  rejected-quote: " ++ Belt.Int.toString(rejectedQuote.contents) ++
        "  off-vocab: " ++ Belt.Int.toString(offVocab.contents),
      )
      n
    }
  }
}

// ---- CLI -----------------------------------------------------------------

let requireBudget = () =>
  switch Js.Dict.get(env, "CLAUDE_STUDIO_BUDGET") {
  | Some(v) if v != "" => ()
  | _ => {
      Js.log("REFUSING: CLAUDE_STUDIO_BUDGET is not set. Real tagging spends model budget; set the cap first.")
      exit(1)
    }
  }

let realRun = async (db, storyIds) => {
  requireBudget()
  let runId = "run_" ++ Js.Float.toString(Js.Date.now())
  Sqlite.runArray(
    Sqlite.prepare(db, "INSERT INTO runs(run_id, started_at, model, calls, notes) VALUES (?,?,?,?,?)"),
    [runId, Js.Date.make()->Js.Date.toISOString, "warm-session", "0", "tagger"],
  )
  for i in 0 to Js.Array2.length(storyIds) - 1 {
    // one story failing must not abort the others
    switch await runStory(~ask=Session.ask, db, runId, storyIds->Js.Array2.unsafe_get(i)) {
    | _ => ()
    | exception e => Js.log2("  story errored, continuing:", e)
    }
  }
  Sqlite.runArray(
    Sqlite.prepare(db, "UPDATE runs SET calls=? WHERE run_id=?"),
    [Belt.Int.toString(Session.callsMade()), runId],
  )
  Session.close()
}

let plan = db => {
  let stories = Sqlite.allNone(Sqlite.prepare(db, "SELECT COUNT(*) AS n FROM corpus_stories"))
  let n = switch stories->Js.Array2.unsafe_get(0)->Js.Json.decodeObject {
    | Some(o) => switch Js.Dict.get(o, "n") { | Some(v) => Belt.Option.getWithDefault(Js.Json.decodeNumber(v), 0.) | None => 0. }
    | None => 0.
  }->Belt.Float.toInt
  Js.log("stories: " ++ Belt.Int.toString(n))
  Js.log("turns per story: 2 (tag + recall)")
  Js.log("EST TOTAL warm-session turns: " ++ Belt.Int.toString(2 * n))
}

let selftest = () => {
  let story = "Ross went up alone. The room at the top of the stairs was empty. He found a receipt dated the Thursday before she died."
  let sn = norm(story)
  let real = verifyQuote(sn, "The room at the top of the stairs was empty")
  let spaced = verifyQuote(sn, "The  room at the   top of the stairs was  empty")
  let fake = verifyQuote(sn, "He drew his revolver and kicked the door in")
  let tooShort = verifyQuote(sn, "empty")
  let a = parseStageA(Js.Dict.fromArray([("ChekhovsGun", true), ("BigBad", true)]), "ChekhovsGun\nNotATrope\n- BigBad\n")
  let b = parseStageB("ChekhovsGun | straight | a receipt dated the Thursday before she died\nRedHerring | absent\nBigBad | wackymode | he found a receipt")
  Js.log2("verify real quote (expect true):", real)
  Js.log2("verify whitespace-variant quote (expect true):", spaced)
  Js.log2("verify fabricated quote (expect false):", fake)
  Js.log2("verify too-short quote (expect false):", tooShort)
  Js.log2("stageA parse (expect [ChekhovsGun, BigBad]):", a)
  Js.log2("stageB parse (expect 2 claims, BigBad mode->straight):", b)
  let pass = real && spaced && !fake && !tooShort && Js.Array2.length(a) == 2 && Js.Array2.length(b) == 2
  Js.log(pass ? "SELFTEST: PASS" : "SELFTEST: FAIL")
  if !pass { exit(1) }
}

let main = async () => {
  switch argv->Js.Array2.unsafe_get(2)->Js.Nullable.return->Js.Nullable.toOption {
  | Some("selftest") => selftest()
  | Some("plan") => {
      let db = Sqlite.openDb(dbPath)
      plan(db)
      Sqlite.close(db)
    }
  | Some("run") =>
    switch argv->Js.Array2.unsafe_get(3)->Js.Nullable.return->Js.Nullable.toOption {
    | Some(id) => {
        let db = Sqlite.openDb(dbPath)
        await realRun(db, [id])
        Sqlite.close(db)
      }
    | None => Js.log("usage: run <story_id>")
    }
  | Some("run-all") => {
      let db = Sqlite.openDb(dbPath)
      let ids =
        Sqlite.allNone(Sqlite.prepare(db, "SELECT story_id FROM corpus_stories"))
        ->Js.Array2.map(r => jstr(r, "story_id"))
      await realRun(db, ids)
      Sqlite.close(db)
    }
  | _ => Js.log("usage: TropeTagger selftest | plan | run <story_id> | run-all")
  }
}

// Only run the CLI when THIS file is the entry point, so other modules can import
// the helpers (verifyQuote, parseStageB, stageBPrompt...) without triggering it.
let isEntry =
  switch argv->Js.Array2.unsafe_get(1)->Js.Nullable.return->Js.Nullable.toOption {
  | Some(p) => Js.String2.includes(p, "TropeTagger")
  | None => false
  }
if isEntry {
  main()->ignore
}
