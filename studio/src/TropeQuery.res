// Query CLI over studio/data/tropes.db.
// Usage:
//   node src/TropeQuery.res.mjs show <title words...>     tropes of a work
//   node src/TropeQuery.res.mjs trope <TropeName>          description + example works
//   node src/TropeQuery.res.mjs stats

@scope("process") @val external argv: array<string> = "argv"
@scope("process") @val external exit: int => unit = "exit"

let dbPath = "data/tropes.db"

let jstr = (row: Js.Json.t, key: string): string =>
  switch Js.Json.decodeObject(row) {
  | Some(o) =>
    switch Js.Dict.get(o, key) {
    | Some(v) =>
      switch Js.Json.decodeString(v) {
      | Some(s) => s
      | None =>
        switch Js.Json.decodeNumber(v) {
        | Some(n) => Js.Float.toString(n)
        | None => ""
        }
      }
    | None => ""
    }
  | None => ""
  }

let clean = (s: string): string =>
  s->Js.String2.toLowerCase->Js.String2.replaceByRe(%re("/[^a-z0-9]/g"), "")

let oneLine = (s: string, max: int): string => {
  let ws = Js.Re.fromStringWithFlags("\\s+", ~flags="g")
  let flat = s->Js.String2.replaceByRe(ws, " ")->Js.String2.trim
  Js.String2.length(flat) > max ? Js.String2.substring(flat, ~from=0, ~to_=max) ++ "..." : flat
}

let pick = (db, cands: array<Js.Json.t>) => {
  let w = cands->Js.Array2.unsafe_get(0)
  Js.log(
    "WORK: " ++ jstr(w, "title") ++ "  [" ++ jstr(w, "medium") ++ "]  year:" ++ jstr(w, "start_year") ++ "  genres:" ++ jstr(w, "genres"),
  )
  let tropes = Sqlite.allArray(
    Sqlite.prepare(
      db,
      "SELECT t.name, wt.example FROM work_tropes wt JOIN tropes t ON t.trope_id = wt.trope_id " ++
      "WHERE wt.title_id = ? ORDER BY t.name",
    ),
    [jstr(w, "title_id")],
  )
  Js.log2("tropes:", Js.Array2.length(tropes))
  tropes->Js.Array2.forEach(r => {
    Js.log("  - " ++ jstr(r, "name") ++ " :: " ++ oneLine(jstr(r, "example"), 110))
  })
}

let showWork = (db, nameWords: array<string>) => {
  let needle = clean(nameWords->Js.Array2.joinWith(""))
  let find = Sqlite.prepare(
    db,
    "SELECT w.title_id, w.title, w.medium, w.clean_title, w.tconst, i.start_year, i.genres " ++
    "FROM works w LEFT JOIN imdb_basics i ON i.tconst = w.tconst " ++
    "WHERE w.clean_title = ? OR LOWER(w.title) = LOWER(?) " ++
    "ORDER BY (w.tconst IS NULL), w.medium LIMIT 5",
  )
  let cands = Sqlite.allArray(find, [needle, nameWords->Js.Array2.joinWith("")])
  if Js.Array2.length(cands) == 0 {
    let fuzzy = Sqlite.prepare(
      db,
      "SELECT w.title_id, w.title, w.medium, w.clean_title, w.tconst, i.start_year, i.genres " ++
      "FROM works w LEFT JOIN imdb_basics i ON i.tconst = w.tconst " ++
      "WHERE w.clean_title LIKE ? ORDER BY LENGTH(w.clean_title) LIMIT 5",
    )
    let cands2 = Sqlite.allArray(fuzzy, ["%" ++ needle ++ "%"])
    if Js.Array2.length(cands2) == 0 {
      Js.log("no match in the database for: " ++ nameWords->Js.Array2.joinWith(" "))
      exit(1)
    } else {
      pick(db, cands2)
    }
  } else {
    pick(db, cands)
  }
}
and pick = (db, cands: array<Js.Json.t>) => {
  let w = cands->Js.Array2.unsafe_get(0)
  Js.log(
    "WORK: " ++ jstr(w, "title") ++ "  [" ++ jstr(w, "medium") ++ "]  year:" ++ jstr(w, "start_year") ++ "  genres:" ++ jstr(w, "genres"),
  )
  let tropes = Sqlite.allArray(
    Sqlite.prepare(
      db,
      "SELECT t.name, wt.example FROM work_tropes wt JOIN tropes t ON t.trope_id = wt.trope_id " ++
      "WHERE wt.title_id = ? ORDER BY t.name",
    ),
    [jstr(w, "title_id")],
  )
  Js.log2("tropes:", Js.Array2.length(tropes))
  tropes->Js.Array2.forEach(r => {
    Js.log("  - " ++ jstr(r, "name") ++ " :: " ++ oneLine(jstr(r, "example"), 110))
  })
}

let showTrope = (db, name: string) => {
  let t = Sqlite.allArray(
    Sqlite.prepare(db, "SELECT trope_id, name, description FROM tropes WHERE name = ? OR trope_id = ? LIMIT 1"),
    [name, name],
  )
  if Js.Array2.length(t) == 0 {
    Js.log("no trope named: " ++ name)
    exit(1)
  } else {
    let tr = t->Js.Array2.unsafe_get(0)
    Js.log("TROPE: " ++ jstr(tr, "name"))
    Js.log(oneLine(jstr(tr, "description"), 400))
    let works = Sqlite.allArray(
      Sqlite.prepare(
        db,
        "SELECT w.title, w.medium, i.genres FROM work_tropes wt " ++
        "JOIN works w ON w.title_id = wt.title_id " ++
        "LEFT JOIN imdb_basics i ON i.tconst = w.tconst " ++
        "WHERE wt.trope_id = ? LIMIT 15",
      ),
      [jstr(tr, "trope_id")],
    )
    Js.log2("example works:", Js.Array2.length(works))
    works->Js.Array2.forEach(r =>
      Js.log("  - " ++ jstr(r, "title") ++ " [" ++ jstr(r, "medium") ++ "] " ++ jstr(r, "genres"))
    )
  }
}

let main = () => {
  let db = Sqlite.openDb(dbPath)
  let args = argv->Js.Array2.slice(~start=3, ~end_=Js.Array2.length(argv))
  switch argv->Js.Array2.unsafe_get(2)->Js.Nullable.return->Js.Nullable.toOption {
  | Some("show") => showWork(db, args)
  | Some("trope") => showTrope(db, args->Js.Array2.joinWith(""))
  | Some("stats") => {
      let q = sql => Js.log2(sql, Sqlite.allNone(Sqlite.prepare(db, sql)))
      q("SELECT COUNT(*) AS tropes FROM tropes")
      q("SELECT COUNT(*) AS works FROM works")
      q("SELECT COUNT(*) AS examples FROM work_tropes")
      q("SELECT COUNT(*) AS genre_linked FROM works w JOIN imdb_basics i ON i.tconst = w.tconst")
    }
  | _ => Js.log("usage: TropeQuery show <title> | trope <TropeName> | stats")
  }
  Sqlite.close(db)
}

main()
