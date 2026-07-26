// Loads the dhruvilgala/tvtropes dataset + IMDb genres into studio/data/tropes.db.
// Header-mapped (column order read from each file's header row, never assumed).
// Usage:
//   node src/TropeImport.res.mjs load <TVTropesDataDir>
//   node src/TropeImport.res.mjs imdb <filteredBasicsTsv>
//   node src/TropeImport.res.mjs tconsts
//   node src/TropeImport.res.mjs stats

@scope("process") @val external argv: array<string> = "argv"
@scope("process") @val external exit: int => unit = "exit"
@module("node:fs") external readFileSync: (string, string) => string = "readFileSync"

let dbPath = "data/tropes.db"

let schema = `
CREATE TABLE IF NOT EXISTS tropes(trope_id TEXT PRIMARY KEY, name TEXT, description TEXT);
CREATE TABLE IF NOT EXISTS works(title_id TEXT PRIMARY KEY, title TEXT, medium TEXT, clean_title TEXT, tconst TEXT);
CREATE TABLE IF NOT EXISTS work_tropes(title_id TEXT, trope_id TEXT, example TEXT, PRIMARY KEY(title_id, trope_id)) WITHOUT ROWID;
CREATE TABLE IF NOT EXISTS imdb_basics(tconst TEXT PRIMARY KEY, title_type TEXT, primary_title TEXT, start_year TEXT, genres TEXT);
CREATE INDEX IF NOT EXISTS idx_wt_trope ON work_tropes(trope_id);
CREATE INDEX IF NOT EXISTS idx_works_clean ON works(clean_title);
CREATE INDEX IF NOT EXISTS idx_works_tconst ON works(tconst);
`

// Reads a CSV whose first row is the header; calls onRecord with a name->value lookup.
let eachRecord = (path: string, onRecord: ((string => string) => unit)) => {
  let content = readFileSync(path, "utf8")
  let header: ref<option<Js.Dict.t<int>>> = ref(None)
  Csv.parse(content, row => {
    switch header.contents {
    | None => {
        let d = Js.Dict.empty()
        row->Js.Array2.forEachi((name, idx) => Js.Dict.set(d, name, idx))
        header := Some(d)
      }
    | Some(h) => {
        let field = name =>
          switch Js.Dict.get(h, name) {
          | Some(idx) =>
            switch row->Js.Array2.unsafe_get(idx)->Js.Nullable.return->Js.Nullable.toOption {
            | Some(v) => v
            | None => ""
            }
          | None => ""
          }
        onRecord(field)
      }
    }
  })
}

let loadTropes = (db, path) => {
  let ins = Sqlite.prepare(db, "INSERT OR IGNORE INTO tropes(trope_id, name, description) VALUES (?,?,?)")
  let count = ref(0)
  Sqlite.bulk(db, () => {
    eachRecord(path, f => {
      Sqlite.runArray(ins, [f("TropeID"), f("Trope"), f("Description")])
      count := count.contents + 1
    })
  })
  Js.log2("tropes rows:", count.contents)
}

let loadMedium = (db, path, medium) => {
  let insWork = Sqlite.prepare(db, "INSERT OR IGNORE INTO works(title_id, title, medium) VALUES (?,?,?)")
  let insWt = Sqlite.prepare(db, "INSERT OR IGNORE INTO work_tropes(title_id, trope_id, example) VALUES (?,?,?)")
  let count = ref(0)
  Sqlite.bulk(db, () => {
    eachRecord(path, f => {
      Sqlite.runArray(insWork, [f("title_id"), f("Title"), medium])
      Sqlite.runArray(insWt, [f("title_id"), f("trope_id"), f("Example")])
      count := count.contents + 1
    })
  })
  Js.log2(medium ++ " example rows:", count.contents)
}

let loadMatch = (db, path, hasTconst) => {
  let upd = hasTconst
    ? Sqlite.prepare(db, "UPDATE works SET clean_title = ?, tconst = ? WHERE title_id = ?")
    : Sqlite.prepare(db, "UPDATE works SET clean_title = ? WHERE title_id = ?")
  let count = ref(0)
  Sqlite.bulk(db, () => {
    eachRecord(path, f => {
      if hasTconst {
        Sqlite.runArray(upd, [f("CleanTitle"), f("tconst"), f("title_id")])
      } else {
        Sqlite.runArray(upd, [f("CleanTitle"), f("title_id")])
      }
      count := count.contents + 1
    })
  })
  Js.log2("match rows applied from " ++ path ++ ":", count.contents)
}

let loadImdb = (db, path) => {
  let content = readFileSync(path, "utf8")
  let ins = Sqlite.prepare(
    db,
    "INSERT OR IGNORE INTO imdb_basics(tconst, title_type, primary_title, start_year, genres) VALUES (?,?,?,?,?)",
  )
  let count = ref(0)
  Sqlite.bulk(db, () => {
    content
    ->Js.String2.split("\n")
    ->Js.Array2.forEach(line => {
      let cols = line->Js.String2.split("\t")
      if Js.Array2.length(cols) >= 9 {
        let g = i =>
          switch cols->Js.Array2.unsafe_get(i)->Js.Nullable.return->Js.Nullable.toOption {
          | Some(v) => v
          | None => ""
          }
        Sqlite.runArray(ins, [g(0), g(1), g(2), g(5), g(8)])
        count := count.contents + 1
      }
    })
  })
  Js.log2("imdb rows:", count.contents)
}

let printStats = db => {
  let q = sql => {
    let rows = Sqlite.allNone(Sqlite.prepare(db, sql))
    Js.log2(sql, rows)
  }
  q("SELECT COUNT(*) AS n FROM tropes")
  q("SELECT COUNT(*) AS n FROM works")
  q("SELECT COUNT(*) AS n FROM work_tropes")
  q("SELECT COUNT(*) AS n FROM imdb_basics")
  q("SELECT medium, COUNT(*) AS n FROM works GROUP BY medium")
  q("SELECT COUNT(*) AS matched FROM works WHERE tconst IS NOT NULL AND tconst != ''")
}

let main = () => {
  let db = Sqlite.openDb(dbPath)
  Sqlite.exec(db, "PRAGMA journal_mode=WAL;")
  Sqlite.exec(db, "PRAGMA synchronous=OFF;")
  Sqlite.exec(db, schema)
  switch (argv->Js.Array2.unsafe_get(2)->Js.Nullable.return->Js.Nullable.toOption, argv->Js.Array2.unsafe_get(3)->Js.Nullable.return->Js.Nullable.toOption) {
  | (Some("load"), Some(dir)) => {
      loadTropes(db, dir ++ "/tropes.csv")
      loadMedium(db, dir ++ "/film_tropes.csv", "film")
      loadMedium(db, dir ++ "/tv_tropes.csv", "tv")
      loadMedium(db, dir ++ "/lit_tropes.csv", "lit")
      loadMatch(db, dir ++ "/film_imdb_match.csv", true)
      loadMatch(db, dir ++ "/tv_imdb_match.csv", true)
      loadMatch(db, dir ++ "/lit_goodreads_match.csv", false)
      printStats(db)
    }
  | (Some("imdb"), Some(path)) => {
      loadImdb(db, path)
      printStats(db)
    }
  | (Some("tconsts"), _) => {
      let rows = Sqlite.allNone(
        Sqlite.prepare(db, "SELECT DISTINCT tconst FROM works WHERE tconst IS NOT NULL AND tconst != ''"),
      )
      rows->Js.Array2.forEach(r => {
        switch Js.Json.decodeObject(r) {
        | Some(o) =>
          switch Js.Dict.get(o, "tconst") {
          | Some(v) =>
            switch Js.Json.decodeString(v) {
            | Some(s) => Js.log(s)
            | None => ()
            }
          | None => ()
          }
        | None => ()
        }
      })
    }
  | (Some("stats"), _) => printStats(db)
  | _ => {
      Js.log("usage: TropeImport load <dir> | imdb <tsv> | tconsts | stats")
      exit(1)
    }
  }
  Sqlite.close(db)
}

main()
