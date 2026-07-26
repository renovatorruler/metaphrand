// Step 2 — register the texts whose trope habits we measure. No model.
// Strips the doc header above the first '---' line so only the story body counts.
// Usage:
//   node src/TropeCorpus.res.mjs add <source> <path>     source in claude|author
//   node src/TropeCorpus.res.mjs body <story_id>          print the stored body (debug)
//   node src/TropeCorpus.res.mjs list

@scope("process") @val external argv: array<string> = "argv"
@scope("process") @val external exit: int => unit = "exit"
@module("node:fs") external readFileSync: (string, string) => string = "readFileSync"
type hash
@module("node:crypto") external createHash: string => hash = "createHash"
@send external update: (hash, string) => hash = "update"
@send external digestHex: (hash, @as("hex") _) => string = "digest"

let dbPath = "data/tropes.db"

let schema = `
CREATE TABLE IF NOT EXISTS corpus_stories(
  story_id TEXT PRIMARY KEY, path TEXT, source TEXT, body TEXT, added_at TEXT);
CREATE TABLE IF NOT EXISTS story_tropes(
  story_id TEXT, trope_id TEXT, name TEXT, mode TEXT, quote TEXT, run_id TEXT,
  PRIMARY KEY(story_id, trope_id));
CREATE TABLE IF NOT EXISTS runs(
  run_id TEXT PRIMARY KEY, started_at TEXT, model TEXT, calls INTEGER, notes TEXT);
`

// Strip a leading markdown doc-header block: everything up to and including the
// first line that is exactly '---' (our story files put the doc note above it).
let stripHeader = (raw: string): string => {
  let lines = raw->Js.String2.split("\n")
  let idx = ref(-1)
  lines->Js.Array2.forEachi((l, i) =>
    if idx.contents == -1 && Js.String2.trim(l) == "---" {
      idx := i
    }
  )
  if idx.contents >= 0 {
    lines
    ->Js.Array2.slice(~start=idx.contents + 1, ~end_=Js.Array2.length(lines))
    ->Js.Array2.joinWith("\n")
    ->Js.String2.trim
  } else {
    Js.String2.trim(raw)
  }
}

let hashOf = (s: string): string =>
  createHash("sha256")->update(s)->digestHex->Js.String2.substring(~from=0, ~to_=12)

let add = (db, source, path) => {
  let raw = readFileSync(path, "utf8")
  let body = stripHeader(raw)
  let id = hashOf(body)
  let ins = Sqlite.prepare(
    db,
    "INSERT OR REPLACE INTO corpus_stories(story_id, path, source, body, added_at) VALUES (?,?,?,?,?)",
  )
  Sqlite.runArray(ins, [id, path, source, body, Js.Date.make()->Js.Date.toISOString])
  Js.log("registered " ++ id ++ " [" ++ source ++ "] " ++ Belt.Int.toString(Js.String2.length(body)) ++ " chars  " ++ path)
}

let main = () => {
  let db = Sqlite.openDb(dbPath)
  Sqlite.exec(db, schema)
  switch (
    argv->Js.Array2.unsafe_get(2)->Js.Nullable.return->Js.Nullable.toOption,
    argv->Js.Array2.unsafe_get(3)->Js.Nullable.return->Js.Nullable.toOption,
    argv->Js.Array2.unsafe_get(4)->Js.Nullable.return->Js.Nullable.toOption,
  ) {
  | (Some("add"), Some(source), Some(path)) =>
    if source == "claude" || source == "author" {
      add(db, source, path)
    } else {
      Js.log("source must be claude|author")
      exit(1)
    }
  | (Some("list"), _, _) =>
    Js.log2("corpus:", Sqlite.allNone(Sqlite.prepare(db, "SELECT source, COUNT(*) AS n, GROUP_CONCAT(story_id) AS ids FROM corpus_stories GROUP BY source")))
  | (Some("body"), Some(id), _) => {
      let r = Sqlite.getArray(Sqlite.prepare(db, "SELECT body FROM corpus_stories WHERE story_id=?"), [id])
      switch r->Js.Nullable.toOption {
      | Some(j) => switch Js.Json.decodeObject(j) {
        | Some(o) => switch Js.Dict.get(o, "body") {
          | Some(v) => switch Js.Json.decodeString(v) { | Some(s) => Js.log(s) | None => () }
          | None => () }
        | None => () }
      | None => Js.log("no such story_id")
      }
    }
  | _ => {
      Js.log("usage: TropeCorpus add <claude|author> <path> | list | body <id>")
      exit(1)
    }
  }
  Sqlite.close(db)
}

main()
