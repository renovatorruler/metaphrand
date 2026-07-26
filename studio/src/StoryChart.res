// THE STORY CHART — a natal chart for a story. Twelve fixed houses (the questions
// every story answers), dealt occupants (tropes + modes), a rolled rasa contour,
// one buried house (the Sod), and the fit-laws printed on the card.
// Deterministic per seed. `commit` persists to story_charts.
//
// Usage: node src/StoryChart.res.mjs deal <seed> [commit]

@scope("process") @val external argv: array<string> = "argv"

let dbPath = "data/tropes.db"

let houses = [
  ("1 SURFACE", "what the world looks like at the start, and what everyone believes"),
  ("2 LACK", "what is actually missing or broken under it"),
  ("3 WANT", "what the protagonist wants, counted in people"),
  ("4 WALL", "the system that stands against them"),
  ("5 VILLAINS-LAW", "who breaks the rules, and for whom"),
  ("6 DOORWAY", "the first step that cannot be taken back"),
  ("7 DONOR", "who hands over the tool, the truth, or the skill"),
  ("8 MIRROR", "the midpoint flip: the consensus object re-read to its opposite"),
  ("9 PRICE", "who bleeds for the ending"),
  ("10 TURN", "which direction the ending swerves"),
  ("11 VERDICT", "the closing chord"),
  ("12 ORBIT", "the non-load-bearing life: texture, chaos, the world for its own sake"),
]

let rasas = ["shringara (love)", "hasya (comedy)", "karuna (sorrow)", "raudra (fury)", "veera (heroic)", "bhayanaka (dread)", "bibhatsa (disgust)", "adbhuta (wonder)", "shanta (peace)"]

let jstr = (row, key) =>
  switch Js.Json.decodeObject(row) {
  | Some(o) => switch Js.Dict.get(o, key) {
    | Some(v) => switch Js.Json.decodeString(v) { | Some(s) => s | None => "" }
    | None => "" }
  | None => ""
  }

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

let skipSet = db => {
  let skip = Js.Dict.empty()
  Sqlite.allNone(Sqlite.prepare(db, "SELECT name FROM deck_blocklist"))->Js.Array2.forEach(r => Js.Dict.set(skip, jstr(r, "name"), true))
  let eat = json =>
    switch Js.Json.parseExn(json)->Js.Json.decodeArray {
    | Some(arr) => arr->Js.Array2.forEach(o =>
        switch Js.Json.decodeObject(o) {
        | Some(ob) => switch Js.Dict.get(ob, "name") {
          | Some(v) => switch Js.Json.decodeString(v) { | Some(nm) => Js.Dict.set(skip, nm, true) | None => () }
          | None => () }
        | None => ()
        })
    | None => ()
    }
  Sqlite.allNone(Sqlite.prepare(db, "SELECT tropes_json FROM brief_ledger ORDER BY created_at DESC LIMIT 3"))->Js.Array2.forEach(r => eat(jstr(r, "tropes_json")))
  Sqlite.allNone(Sqlite.prepare(db, "SELECT chart_json FROM story_charts ORDER BY created_at DESC LIMIT 2"))->Js.Array2.forEach(r => eat(jstr(r, "chart_json")))
  skip
}

let deal = (db, seed, commit) => {
  Sqlite.exec(db, "CREATE TABLE IF NOT EXISTS story_charts(chart_id TEXT PRIMARY KEY, seed TEXT, created_at TEXT, chart_json TEXT);")
  let r = {state: seedInt(seed)}
  let rows = Sqlite.allNone(Sqlite.prepare(db, "SELECT name, blurb FROM trope_candidates ORDER BY n_crime DESC"))
  let names = rows->Js.Array2.map(rw => jstr(rw, "name"))
  let blurbs = Js.Dict.empty()
  rows->Js.Array2.forEach(rw => Js.Dict.set(blurbs, jstr(rw, "name"), jstr(rw, "blurb")))
  let n = Js.Array2.length(names)
  let third = n / 3
  let bands = [
    names->Js.Array2.slice(~start=0, ~end_=third),
    names->Js.Array2.slice(~start=third, ~end_=2 * third),
    names->Js.Array2.slice(~start=2 * third, ~end_=n),
  ]
  // band quota per house index: 4 high, 5 mid, 3 rare
  let houseBand = [0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2]
  let skip = skipSet(db)
  let picks = []
  for h in 0 to 11 {
    let band = bands->Js.Array2.unsafe_get(houseBand->Js.Array2.unsafe_get(h))
    let order = permute(r, Js.Array2.length(band))
    let chosen = ref("")
    let i = ref(0)
    while chosen.contents == "" && i.contents < Js.Array2.length(order) {
      let nm = band->Js.Array2.unsafe_get(order->Js.Array2.unsafe_get(i.contents))
      if !(Js.Dict.get(skip, nm)->Belt.Option.getWithDefault(false)) {
        chosen := nm
        Js.Dict.set(skip, nm, true)
      }
      i := i.contents + 1
    }
    let _ = Js.Array2.push(picks, (chosen.contents, rollMode(r)))
  }
  let buried = next(r)->mod(12)
  let rasaOrder = permute(r, Js.Array2.length(rasas))
  let contour = Belt.Array.makeBy(5, i => rasas->Js.Array2.unsafe_get(rasaOrder->Js.Array2.unsafe_get(i)))

  Js.log("# STORY CHART  (seed: " ++ seed ++ ")\n")
  picks->Js.Array2.forEachi(((nm, mode), h) => {
    let (hname, q) = houses->Js.Array2.unsafe_get(h)
    let mark = h == buried ? "  << BURIED (the Sod: operates, never stated)" : ""
    Js.log(hname ++ " — " ++ q)
    Js.log("   " ++ nm ++ " (" ++ mode ++ ")" ++ mark)
    let b = Js.Dict.get(blurbs, nm)->Belt.Option.getWithDefault("")
    Js.log("   " ++ b->Js.String2.substring(~from=0, ~to_=160)->Js.String2.replaceByRe(Js.Re.fromStringWithFlags("\\s+", ~flags="g"), " ")->Js.String2.trim)
  })
  Js.log("\nRASA CONTOUR (open / build / mid / late / close): " ++ contour->Js.Array2.joinWith(" -> "))
  Js.log("\nFIT LAWS: the MIRROR must contradict the SURFACE. The TURN must not point where the WANT points. The buried house is never stated on the page. Fit before writing; the fitted brief still passes the drama gates.")

  let json =
    Js.Json.stringifyAny(picks->Js.Array2.mapi(((nm, mode), h) => {
      let o = Js.Dict.empty()
      let (hname, _) = houses->Js.Array2.unsafe_get(h)
      Js.Dict.set(o, "house", Js.Json.string(hname))
      Js.Dict.set(o, "name", Js.Json.string(nm))
      Js.Dict.set(o, "mode", Js.Json.string(mode))
      Js.Dict.set(o, "buried", Js.Json.boolean(h == buried))
      Js.Json.object_(o)
    }))->Belt.Option.getWithDefault("[]")
  if commit {
    let chartId = "chart_" ++ seed ++ "_" ++ Js.Float.toString(Js.Date.now())
    Sqlite.runArray(
      Sqlite.prepare(db, "INSERT INTO story_charts(chart_id, seed, created_at, chart_json) VALUES (?,?,?,?)"),
      [chartId, seed, Js.Date.make()->Js.Date.toISOString, json],
    )
    Js.log("\ncommitted: " ++ chartId)
  } else {
    Js.log("\n(preview — add `commit` to persist)")
  }
}

let main = () => {
  let db = Sqlite.openDb(dbPath)
  switch (argv->Js.Array2.unsafe_get(2)->Js.Nullable.return->Js.Nullable.toOption, argv->Js.Array2.unsafe_get(3)->Js.Nullable.return->Js.Nullable.toOption) {
  | (Some("deal"), Some(seed)) => {
      let commit = argv->Js.Array2.unsafe_get(4)->Js.Nullable.return->Js.Nullable.toOption == Some("commit")
      deal(db, seed, commit)
    }
  | _ => Js.log("usage: StoryChart deal <seed> [commit]")
  }
  Sqlite.close(db)
}

let isEntry =
  switch argv->Js.Array2.unsafe_get(1)->Js.Nullable.return->Js.Nullable.toOption {
  | Some(p) => Js.String2.includes(p, "StoryChart")
  | None => false
  }
if isEntry {
  main()
}
