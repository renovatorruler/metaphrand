// Step 4 — the DIFF REPORT. Compares three trope distributions:
//   MINE     = share of my (claude) stories using each trope
//   AUTHOR   = share of the author's sample using each trope
//   BASELINE = share of human crime-genre works (Crime/Mystery/Thriller) using it
// Writes data/reports/DIFF_REPORT.md and rebuilds deck_blocklist (top grooves).
// No model. Needs the tagger to have run first (else MINE/AUTHOR are empty).
//
// Usage: node src/TropeHistogram.res.mjs report

@scope("process") @val external argv: array<string> = "argv"
@module("node:fs") external writeFileSync: (string, string) => unit = "writeFileSync"
@module("node:fs") external mkdirSync: (string, {"recursive": bool}) => unit = "mkdirSync"

let dbPath = "data/tropes.db"

let jstr = (row, key) =>
  switch Js.Json.decodeObject(row) {
  | Some(o) => switch Js.Dict.get(o, key) {
    | Some(v) => switch Js.Json.decodeString(v) {
      | Some(s) => s
      | None => switch Js.Json.decodeNumber(v) { | Some(n) => Js.Float.toString(n) | None => "" } }
    | None => "" }
  | None => ""
  }
let jnum = (row, key) =>
  switch Js.Json.decodeObject(row) {
  | Some(o) => switch Js.Dict.get(o, key) {
    | Some(v) => Belt.Option.getWithDefault(Js.Json.decodeNumber(v), 0.)
    | None => 0. }
  | None => 0.
  }

// share-of-stories map for a corpus source, keyed by trope name
let mineShare = (db, source): Js.Dict.t<float> => {
  let d = Js.Dict.empty()
  let rows = Sqlite.allArray(
    Sqlite.prepare(
      db,
      "SELECT st.name AS name, COUNT(DISTINCT st.story_id)*1.0 / " ++
      "(SELECT COUNT(*) FROM corpus_stories WHERE source=?) AS share " ++
      "FROM story_tropes st JOIN corpus_stories cs ON cs.story_id=st.story_id " ++
      "WHERE cs.source=? GROUP BY st.name",
    ),
    [source, source],
  )
  rows->Js.Array2.forEach(r => Js.Dict.set(d, jstr(r, "name"), jnum(r, "share")))
  d
}

let baselineShare = (db): Js.Dict.t<float> => {
  let d = Js.Dict.empty()
  let rows = Sqlite.allNone(
    Sqlite.prepare(
      db,
      "WITH crime_works AS (" ++
      "SELECT DISTINCT w.title_id FROM works w JOIN imdb_basics i ON i.tconst=w.tconst " ++
      "WHERE i.genres LIKE '%Crime%' OR i.genres LIKE '%Mystery%' OR i.genres LIKE '%Thriller%') " ++
      "SELECT t.name AS name, COUNT(DISTINCT wt.title_id)*1.0/(SELECT COUNT(*) FROM crime_works) AS share " ++
      "FROM work_tropes wt JOIN crime_works cw ON cw.title_id=wt.title_id " ++
      "JOIN tropes t ON t.trope_id=wt.trope_id " ++
      "JOIN trope_candidates tc ON tc.trope_id=wt.trope_id " ++ // shared, meta-page-filtered vocabulary
      "GROUP BY t.name",
    ),
  )
  rows->Js.Array2.forEach(r => Js.Dict.set(d, jstr(r, "name"), jnum(r, "share")))
  d
}

let evidenceQuote = (db, name): string => {
  let r = Sqlite.getArray(
    Sqlite.prepare(db, "SELECT quote FROM story_tropes st JOIN corpus_stories cs ON cs.story_id=st.story_id WHERE cs.source='claude' AND st.name=? LIMIT 1"),
    [name],
  )
  switch r->Js.Nullable.toOption { | Some(j) => jstr(j, "quote") | None => "" }
}

let get = (d, k) => Js.Dict.get(d, k)->Belt.Option.getWithDefault(0.)
let pct = f => (f *. 100.)->Js.Math.round->Belt.Float.toInt->Belt.Int.toString ++ "%"

let report = db => {
  let mine = mineShare(db, "claude")
  let author = mineShare(db, "author")
  let base = baselineShare(db)

  // Section A: overused by me — mine>=0.5, baseline<0.15, sorted by gap
  let aThresh = ref(0.5)
  let bThresh = ref(0.15)
  let buildA = () =>
    Js.Dict.keys(mine)
    ->Js.Array2.filter(n => get(mine, n) >= aThresh.contents && get(base, n) < bThresh.contents)
    ->Js.Array2.map(n => (n, get(mine, n) -. get(base, n)))
    ->Js.Array2.sortInPlaceWith(((_, g1), (_, g2)) => g1 < g2 ? 1 : -1)
  let secA = ref(buildA())
  if Js.Array2.length(secA.contents) == 0 {
    aThresh := 0.25
    bThresh := 0.30
    secA := buildA()
  }
  let secA = secA.contents->Js.Array2.slice(~start=0, ~end_=50)

  // Section B: my blind spots — baseline>=0.05 (common in sparse tagging), mine==0
  let secB =
    Js.Dict.keys(base)
    ->Js.Array2.filter(n => get(base, n) >= 0.05 && get(mine, n) == 0.)
    ->Js.Array2.map(n => (n, get(base, n)))
    ->Js.Array2.sortInPlaceWith(((_, s1), (_, s2)) => s1 < s2 ? 1 : -1)
    ->Js.Array2.slice(~start=0, ~end_=50)

  // Section C: author uses, I never do (and vice versa)
  let authorNotMe =
    Js.Dict.keys(author)->Js.Array2.filter(n => get(author, n) > 0. && get(mine, n) == 0.)
  let meNotAuthor =
    Js.Dict.keys(mine)->Js.Array2.filter(n => get(mine, n) > 0. && get(author, n) == 0.)

  let lines = []
  let w = s => Js.Array2.push(lines, s)->ignore
  w("# TROPE DIFF REPORT")
  w("")
  w("MINE = my 4 Free Ross stories. AUTHOR = the Perseus sample. BASELINE = human Crime/Mystery/Thriller works in the DB.")
  w("A trope must clear the tagger's on-page-quote check to count. Empty MINE/AUTHOR sections mean the tagger has not run yet.")
  w("")
  w("## A. OVERUSED BY ME (my grooves)")
  w("_tropes I lean on that human crime fiction rarely uses; gap = my share minus baseline_")
  w("")
  if Js.Array2.length(secA) == 0 {
    w("_(empty — run the tagger first)_")
  } else {
    secA->Js.Array2.forEach(((n, gap)) =>
      w("- **" ++ n ++ "** — me " ++ pct(get(mine, n)) ++ " vs human " ++ pct(get(base, n)) ++ "  (gap +" ++ pct(gap) ++ ")  \n  e.g. \"" ++ evidenceQuote(db, n) ++ "\"")
    )
  }
  w("")
  w("## B. MY BLIND SPOTS")
  w("_tropes common in human crime fiction that I never once used_")
  w("")
  if Js.Array2.length(secB) == 0 {
    w("_(empty — run the tagger first)_")
  } else {
    secB->Js.Array2.forEach(((n, s)) => w("- **" ++ n ++ "** — human " ++ pct(s) ++ ", me 0%"))
  }
  w("")
  w("## C. AUTHOR VS ME")
  w("_author's sample uses, I never do:_ " ++ (Js.Array2.length(authorNotMe) == 0 ? "(none / tagger not run)" : authorNotMe->Js.Array2.joinWith(", ")))
  w("")
  w("_I use, author's sample does not:_ " ++ (Js.Array2.length(meNotAuthor) == 0 ? "(none / tagger not run)" : meNotAuthor->Js.Array2.joinWith(", ")))
  w("")
  w("## D. BASELINE TOP 30 (human crime fiction)")
  Js.Dict.keys(base)
  ->Js.Array2.map(n => (n, get(base, n)))
  ->Js.Array2.sortInPlaceWith(((_, s1), (_, s2)) => s1 < s2 ? 1 : -1)
  ->Js.Array2.slice(~start=0, ~end_=30)
  ->Js.Array2.forEach(((n, s)) => w("- " ++ n ++ " " ++ pct(s)))

  mkdirSync("data/reports", {"recursive": true})
  writeFileSync("data/reports/DIFF_REPORT.md", lines->Js.Array2.joinWith("\n"))

  // rebuild deck_blocklist from section A top 25
  Sqlite.exec(db, "CREATE TABLE IF NOT EXISTS deck_blocklist(trope_id TEXT PRIMARY KEY, name TEXT);")
  Sqlite.exec(db, "DELETE FROM deck_blocklist;")
  let ins = Sqlite.prepare(db, "INSERT OR IGNORE INTO deck_blocklist(trope_id, name) SELECT trope_id, name FROM tropes WHERE name=?")
  secA->Js.Array2.slice(~start=0, ~end_=25)->Js.Array2.forEach(((n, _)) => Sqlite.runArray(ins, [n]))

  Js.log("wrote data/reports/DIFF_REPORT.md")
  Js.log("section A (grooves): " ++ Belt.Int.toString(Js.Array2.length(secA)))
  Js.log("section B (blind spots): " ++ Belt.Int.toString(Js.Array2.length(secB)))
  Js.log("deck_blocklist rebuilt: " ++ Belt.Int.toString(Js.Array2.length(secA->Js.Array2.slice(~start=0, ~end_=25))))
}

let main = () => {
  let db = Sqlite.openDb(dbPath)
  switch argv->Js.Array2.unsafe_get(2)->Js.Nullable.return->Js.Nullable.toOption {
  | Some("report") => report(db)
  | _ => Js.log("usage: TropeHistogram report")
  }
  Sqlite.close(db)
}

main()
