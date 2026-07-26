// Step 6 — the gate. Checks a finished draft against a rolled brief:
//   PASS iff the draft verifiably uses (nBrief - 2) of its brief tropes AND
//   contains ZERO blocklist (groove) tropes. Reuses the tagger's verified-quote
//   machinery so a claim needs a real on-page quote to count.
//
// Usage:
//   node src/TropeGate.res.mjs check <brief_id> <draft_path>   REAL model spend

@scope("process") @val external argv: array<string> = "argv"
@scope("process") @val external exit: int => unit = "exit"
@module("node:fs") external readFileSync: (string, string) => string = "readFileSync"

let dbPath = "data/tropes.db"

let jstr = (row, key) =>
  switch Js.Json.decodeObject(row) {
  | Some(o) => switch Js.Dict.get(o, key) {
    | Some(v) => switch Js.Json.decodeString(v) { | Some(s) => s | None => "" }
    | None => "" }
  | None => ""
  }

let briefTropes = (db, briefId): array<string> => {
  let r = Sqlite.getArray(Sqlite.prepare(db, "SELECT tropes_json FROM brief_ledger WHERE brief_id=?"), [briefId])
  switch r->Js.Nullable.toOption {
  | None => []
  | Some(j) =>
    switch Js.Json.parseExn(jstr(j, "tropes_json"))->Js.Json.decodeArray {
    | Some(arr) =>
      arr->Js.Array2.map(o =>
        switch Js.Json.decodeObject(o) {
        | Some(ob) => switch Js.Dict.get(ob, "name") {
          | Some(v) => Belt.Option.getWithDefault(Js.Json.decodeString(v), "")
          | None => "" }
        | None => ""
        }
      )->Js.Array2.filter(s => s != "")
    | None => []
    }
  }
}

let blocklist = (db): array<string> =>
  Sqlite.allNone(Sqlite.prepare(db, "SELECT name FROM deck_blocklist"))->Js.Array2.map(r => jstr(r, "name"))

let chunk = (arr, size) => {
  let out = []
  let i = ref(0)
  while i.contents < Js.Array2.length(arr) {
    let _ = Js.Array2.push(out, arr->Js.Array2.slice(~start=i.contents, ~end_=i.contents + size))
    i := i.contents + size
  }
  out
}

// strip a leading doc-header block up to and including the first '---' line
// (inlined, not imported from TropeCorpus, whose module self-runs its CLI)
let stripHeader = (raw: string): string => {
  let lines = raw->Js.String2.split("\n")
  let idx = ref(-1)
  lines->Js.Array2.forEachi((l, i) =>
    if idx.contents == -1 && Js.String2.trim(l) == "---" {
      idx := i
    }
  )
  if idx.contents >= 0 {
    lines->Js.Array2.slice(~start=idx.contents + 1, ~end_=Js.Array2.length(lines))->Js.Array2.joinWith("\n")->Js.String2.trim
  } else {
    Js.String2.trim(raw)
  }
}

let check = async (db, briefId, draftPath) => {
  TropeTagger.requireBudget()
  let raw = readFileSync(draftPath, "utf8")
  let story = stripHeader(raw)
  let storyNorm = TropeTagger.norm(story)

  let brief = briefTropes(db, briefId)
  if Js.Array2.length(brief) == 0 {
    Js.log("no brief found for id: " ++ briefId)
    exit(1)
  }
  let block = blocklist(db)
  let all = Belt.Array.concat(brief, block)

  let present = Js.Dict.empty()
  let batches = chunk(all, 10)
  for bi in 0 to Js.Array2.length(batches) - 1 {
    let reply = await Session.ask(TropeTagger.stageBPrompt(story, batches->Js.Array2.unsafe_get(bi)))
    TropeTagger.parseStageB(reply)->Js.Array2.forEach(c =>
      if TropeTagger.verifyQuote(storyNorm, c.quote) {
        Js.Dict.set(present, c.name, c.quote)
      }
    )
  }
  Session.close()

  let briefHit = brief->Js.Array2.filter(n => Js.Dict.get(present, n) != None)
  let blockHit = block->Js.Array2.filter(n => Js.Dict.get(present, n) != None)
  let need = Js.Array2.length(brief) - 2
  let pass = Js.Array2.length(briefHit) >= need && Js.Array2.length(blockHit) == 0

  Js.log("=== TROPE GATE: " ++ (pass ? "PASS" : "FAIL") ++ " ===")
  Js.log(
    "brief tropes used: " ++ Belt.Int.toString(Js.Array2.length(briefHit)) ++ "/" ++ Belt.Int.toString(Js.Array2.length(brief)) ++ " (need " ++ Belt.Int.toString(need) ++ ")",
  )
  brief->Js.Array2.forEach(n => {
    switch Js.Dict.get(present, n) {
    | Some(q) => Js.log("  used   " ++ n ++ "  :: " ++ q)
    | None => Js.log("  MISSING " ++ n)
    }
  })
  Js.log("groove tropes present (must be 0): " ++ Belt.Int.toString(Js.Array2.length(blockHit)))
  blockHit->Js.Array2.forEach(n => Js.log("  GROOVE " ++ n ++ "  :: " ++ Belt.Option.getWithDefault(Js.Dict.get(present, n), "")))
  if !pass { exit(2) }
}

let main = async () => {
  switch (argv->Js.Array2.unsafe_get(2)->Js.Nullable.return->Js.Nullable.toOption, argv->Js.Array2.unsafe_get(3)->Js.Nullable.return->Js.Nullable.toOption, argv->Js.Array2.unsafe_get(4)->Js.Nullable.return->Js.Nullable.toOption) {
  | (Some("check"), Some(briefId), Some(path)) => {
      let db = Sqlite.openDb(dbPath)
      await check(db, briefId, path)
      Sqlite.close(db)
    }
  | _ => Js.log("usage: TropeGate check <brief_id> <draft_path>")
  }
}

main()->ignore
