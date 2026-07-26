// Step 5 — the entropy deck. Deterministically rolls a fresh trope brief that
// dodges (a) the groove blocklist and (b) tropes used by the last 3 briefs.
// No model. Same seed -> same roll.
//
// Usage:
//   node src/EntropyDeck.res.mjs roll <seed>
//   node src/EntropyDeck.res.mjs bands        show the frequency bands (debug)

@scope("process") @val external argv: array<string> = "argv"

let dbPath = "data/tropes.db"

let schema = `
CREATE TABLE IF NOT EXISTS deck_blocklist(trope_id TEXT PRIMARY KEY, name TEXT);
CREATE TABLE IF NOT EXISTS brief_ledger(brief_id TEXT PRIMARY KEY, seed TEXT, created_at TEXT, tropes_json TEXT);
`

let jstr = (row, key) =>
  switch Js.Json.decodeObject(row) {
  | Some(o) => switch Js.Dict.get(o, key) {
    | Some(v) => switch Js.Json.decodeString(v) { | Some(s) => s | None => "" }
    | None => "" }
  | None => ""
  }

// ---- deterministic RNG (LCG over a seeded integer) -----------------------
type rng = {mutable state: int}
let seedInt = (s: string): int => {
  let h = ref(2166136261)
  for i in 0 to Js.String2.length(s) - 1 {
    h := (h.contents->lxor(Js.String2.charCodeAt(s, i)->Belt.Float.toInt)) * 16777619
  }
  let v = h.contents->mod(2147483647)
  v < 0 ? -v : v + 1
}
let next = (r: rng): int => {
  r.state = (r.state * 1103515245 + 12345)->land(2147483647)
  r.state
}
// deterministic Fisher-Yates permutation of 0..n-1
let permute = (r: rng, n: int): array<int> => {
  let a = Belt.Array.makeBy(n, i => i)
  for i in n - 1 downto 1 {
    let j = next(r)->mod(i + 1)
    let tmp = a->Js.Array2.unsafe_get(i)
    a->Js.Array2.unsafe_set(i, a->Js.Array2.unsafe_get(j))
    a->Js.Array2.unsafe_set(j, tmp)
  }
  a
}

let rollMode = (r: rng): string => {
  let p = next(r)->mod(100)
  if p < 60 { "straight" } else if p < 85 { "subverted" } else if p < 95 { "inverted" } else { "averted" }
}

// pick k names from `band` (in permuted order) skipping `skip`
let pickFrom = (r: rng, band: array<string>, k: int, skip: Js.Dict.t<bool>): array<string> => {
  let order = permute(r, Js.Array2.length(band))
  let out = []
  let i = ref(0)
  while Js.Array2.length(out) < k && i.contents < Js.Array2.length(order) {
    let name = band->Js.Array2.unsafe_get(order->Js.Array2.unsafe_get(i.contents))
    if !(Js.Dict.get(skip, name)->Belt.Option.getWithDefault(false)) {
      let _ = Js.Array2.push(out, name)
      Js.Dict.set(skip, name, true) // don't repeat within a roll
    }
    i := i.contents + 1
  }
  out
}

let loadBands = db => {
  let rows = Sqlite.allNone(Sqlite.prepare(db, "SELECT name FROM trope_candidates ORDER BY n_crime DESC"))
  let names = rows->Js.Array2.map(r => jstr(r, "name"))
  let n = Js.Array2.length(names)
  let third = n / 3
  (
    names->Js.Array2.slice(~start=0, ~end_=third),
    names->Js.Array2.slice(~start=third, ~end_=2 * third),
    names->Js.Array2.slice(~start=2 * third, ~end_=n),
  )
}

let skipSet = db => {
  let skip = Js.Dict.empty()
  Sqlite.allNone(Sqlite.prepare(db, "SELECT name FROM deck_blocklist"))->Js.Array2.forEach(r =>
    Js.Dict.set(skip, jstr(r, "name"), true)
  )
  Sqlite.allNone(
    Sqlite.prepare(db, "SELECT tropes_json FROM brief_ledger ORDER BY created_at DESC LIMIT 3"),
  )->Js.Array2.forEach(r => {
    switch Js.Json.parseExn(jstr(r, "tropes_json"))->Js.Json.decodeArray {
    | Some(arr) =>
      arr->Js.Array2.forEach(o =>
        switch Js.Json.decodeObject(o) {
        | Some(ob) => switch Js.Dict.get(ob, "name") {
          | Some(v) => switch Js.Json.decodeString(v) { | Some(nm) => Js.Dict.set(skip, nm, true) | None => () }
          | None => () }
        | None => ()
        }
      )
    | None => ()
    }
  })
  skip
}

let blurbOf = (db, name) => {
  let r = Sqlite.getArray(Sqlite.prepare(db, "SELECT blurb FROM trope_candidates WHERE name=? LIMIT 1"), [name])
  switch r->Js.Nullable.toOption { | Some(j) => jstr(j, "blurb") | None => "" }
}

let roll = (db, seed, commit) => {
  let r = {state: seedInt(seed)}
  let (high, mid, rare) = loadBands(db)
  let skip = skipSet(db)
  let picks = Belt.Array.concatMany([
    pickFrom(r, high, 2, skip),
    pickFrom(r, mid, 3, skip),
    pickFrom(r, rare, 2, skip),
  ])
  let withModes = picks->Js.Array2.map(name => (name, rollMode(r)))

  // persist to ledger only on explicit commit (so a bare `roll` is reproducible)
  let json =
    Js.Json.stringifyAny(withModes->Js.Array2.map(((name, mode)) => {
      let o = Js.Dict.empty()
      Js.Dict.set(o, "name", Js.Json.string(name))
      Js.Dict.set(o, "mode", Js.Json.string(mode))
      Js.Json.object_(o)
    }))->Belt.Option.getWithDefault("[]")
  let briefId = "brief_" ++ seed ++ "_" ++ Js.Float.toString(Js.Date.now())
  if commit {
    Sqlite.runArray(
      Sqlite.prepare(db, "INSERT INTO brief_ledger(brief_id, seed, created_at, tropes_json) VALUES (?,?,?,?)"),
      [briefId, seed, Js.Date.make()->Js.Date.toISOString, json],
    )
  }

  // print the brief card
  Js.log("# STORY BRIEF  (seed: " ++ seed ++ ")\n")
  Js.log("Write a Free Ross case that USES each trope below, in the rolled mode.\n")
  withModes->Js.Array2.forEachi(((name, mode), i) => {
    let tag = i < 2 ? "[common]" : i < 5 ? "[mid]" : "[rare]"
    Js.log((i + 1)->Belt.Int.toString ++ ". " ++ name ++ "  (" ++ mode ++ ")  " ++ tag)
    Js.log("   " ++ blurbOf(db, name)->Js.String2.substring(~from=0, ~to_=180)->Js.String2.replaceByRe(Js.Re.fromStringWithFlags("\\s+", ~flags="g"), " ")->Js.String2.trim)
  })
  Js.log(commit ? "\ncommitted brief_id: " ++ briefId : "\n(preview only — add `commit` to record it in the ledger)")
}

let main = () => {
  let db = Sqlite.openDb(dbPath)
  Sqlite.exec(db, schema)
  switch (argv->Js.Array2.unsafe_get(2)->Js.Nullable.return->Js.Nullable.toOption, argv->Js.Array2.unsafe_get(3)->Js.Nullable.return->Js.Nullable.toOption) {
  | (Some("roll"), Some(seed)) => {
      let commit = argv->Js.Array2.unsafe_get(4)->Js.Nullable.return->Js.Nullable.toOption == Some("commit")
      roll(db, seed, commit)
    }
  | (Some("bands"), _) => {
      let (h, m, ra) = loadBands(db)
      Js.log2("HIGH band size:", Js.Array2.length(h))
      Js.log2("MID band size:", Js.Array2.length(m))
      Js.log2("RARE band size:", Js.Array2.length(ra))
    }
  | _ => Js.log("usage: EntropyDeck roll <seed> | bands")
  }
  Sqlite.close(db)
}

main()
