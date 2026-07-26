// Step 1 — the taggable shortlist. Pure SQL, no model.
// Reduces the 31K tropes to the ~1500 that actually recur, weighted to crime fiction.
// Usage: node src/TropeCandidates.res.mjs build | stats

@scope("process") @val external argv: array<string> = "argv"

let dbPath = "data/tropes.db"

let build = db => {
  Sqlite.exec(db, "DROP TABLE IF EXISTS trope_candidates;")
  Sqlite.exec(
    db,
    `CREATE TABLE trope_candidates AS
     SELECT t.trope_id, t.name,
            substr(t.description, 1, 300) AS blurb,
            COUNT(DISTINCT wt.title_id) AS n_works,
            SUM(CASE WHEN i.genres LIKE '%Crime%' OR i.genres LIKE '%Mystery%' OR i.genres LIKE '%Thriller%'
                     THEN 1 ELSE 0 END) AS n_crime
     FROM work_tropes wt
     JOIN tropes t ON t.trope_id = wt.trope_id
     JOIN works w ON w.title_id = wt.title_id
     LEFT JOIN imdb_basics i ON i.tconst = w.tconst
     WHERE t.name NOT LIKE '%FilmsOfThe%'
       AND t.name NOT LIKE '%SeriesOfThe%'
       AND t.name NOT LIKE '%OfThe19%'
       AND t.name NOT LIKE '%OfThe20%'
       AND t.name NOT LIKE '%Creator%'
       AND t.name NOT IN ('ShoutOut','ImageSource','HorrorFilms','ImageBooru','TropeMaker','TropeCodifier','SignatureScene')
     GROUP BY t.trope_id, t.name
     HAVING n_works >= 50 AND n_crime >= 5
     ORDER BY n_crime DESC
     LIMIT 1500;`,
  )
  Sqlite.exec(db, "CREATE INDEX IF NOT EXISTS idx_cand_name ON trope_candidates(name);")
}

let stats = db => {
  let q = sql => Js.log2(sql, Sqlite.allNone(Sqlite.prepare(db, sql)))
  q("SELECT COUNT(*) AS candidates FROM trope_candidates")
  q("SELECT name, n_works, n_crime FROM trope_candidates ORDER BY n_crime DESC LIMIT 8")
  q("SELECT name FROM trope_candidates WHERE name IN ('ChekhovsGun','TheReveal','RedHerring','BittersweetEnding')")
}

let main = () => {
  let db = Sqlite.openDb(dbPath)
  switch argv->Js.Array2.unsafe_get(2)->Js.Nullable.return->Js.Nullable.toOption {
  | Some("build") => {
      build(db)
      stats(db)
    }
  | Some("stats") => stats(db)
  | _ => Js.log("usage: TropeCandidates build | stats")
  }
  Sqlite.close(db)
}

main()
