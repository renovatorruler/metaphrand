// Minimal typed bindings to better-sqlite3 (the trope engine's store).
// External FFI only — no escape hatches.

type db
type stmt

@module("better-sqlite3") @new external openDb: string => db = "default"
@send external exec: (db, string) => unit = "exec"
@send external prepare: (db, string) => stmt = "prepare"
@send external runArray: (stmt, array<string>) => unit = "run"
@send external allArray: (stmt, array<string>) => array<Js.Json.t> = "all"
@send external allNone: stmt => array<Js.Json.t> = "all"
@send external getArray: (stmt, array<string>) => Js.Nullable.t<Js.Json.t> = "get"
@send external transaction: (db, unit => unit) => unit => unit = "transaction"
@send external close: db => unit = "close"

let bulk = (d: db, f: unit => unit) => {
  let wrapped = transaction(d, f)
  wrapped()
}
