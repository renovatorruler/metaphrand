/* WHICH REFERENCE IS CURRENT — enforced from the receipts, not from the filename.

   2026-08-27: I bound SET-HOME-ROOM-01_author_master_FINAL.png for three
   keyframes. It was superseded on 2026-08-13 and its own receipt says so —
   "retained, never deleted, no longer bound" — but it is the file called FINAL,
   so it is the one a hand reaches for. The room came back with Яга's hatch
   glowing, which its card forbids at rest.

   The knowledge was already on disk and nothing consulted it. This does.

   A receipt's `supersedes` field names the file it replaces. Walk every receipt,
   collect those names, and refuse any of them. The emitter's own bindings are
   checked at emit time; `check` also takes paths on the command line so a
   hand-run image job can be validated before it spends. */

type stats
@module("fs") external readdirSync: string => array<string> = "readdirSync"
@module("fs") external readFileSync: (string, string) => string = "readFileSync"
@module("fs") external existsSync: string => bool = "existsSync"
@val @scope("process") external argv: array<string> = "argv"
@val @scope(("process", "stdout")) external write: string => unit = "write"
@val @scope("process") external exit: int => unit = "exit"

exception RefError(string)

let refsDir = "../stories/drakosha/ep1prod/scene1/references"

let basename = (p: string): string =>
  switch Js.String2.lastIndexOf(p, "/") {
  | -1 => p
  | i => Js.String2.sliceToEnd(p, ~from=i + 1)
  }

/* A `supersedes` value is either a string or an array, and either form may carry
   a trailing " — retained, no longer bound" note. Take the filename off the front. */
let nameOf = (raw: string): string =>
  raw
  ->Js.String2.split("—")
  ->Belt.Array.getExn(0)
  ->Js.String2.trim
  ->basename

let supersededNames = (): array<string> => {
  if !existsSync(refsDir) {
    []
  } else {
    readdirSync(refsDir)
    ->Belt.Array.keep(f => Js.String2.endsWith(f, ".receipt.json"))
    ->Belt.Array.reduce([], (acc, f) => {
      switch Js.Json.parseExn(readFileSync(refsDir ++ "/" ++ f, "utf8"))->Js.Json.decodeObject {
      | Some(o) =>
        switch Js.Dict.get(o, "supersedes") {
        | Some(v) =>
          switch Js.Json.classify(v) {
          | Js.Json.JSONString(s) => Belt.Array.concat(acc, [nameOf(s)])
          | Js.Json.JSONArray(a) =>
            Belt.Array.concat(
              acc,
              a->Belt.Array.keepMap(x =>
                switch Js.Json.decodeString(x) {
                | Some(s) => Some(nameOf(s))
                | None => None
                }
              ),
            )
          | _ => acc
          }
        | None => acc
        }
      | None => acc
      }
    })
  }
}

let assertNotSuperseded = (paths: array<string>): unit => {
  let dead = supersededNames()
  paths->Belt.Array.forEach(p => {
    let b = basename(p)
    if dead->Belt.Array.some(d => d == b) {
      raise(
        RefError(
          "the reference \"" ++
          b ++
          "\" is recorded as SUPERSEDED by a receipt in the references folder and must not be bound. Its filename is not the authority — the receipts are. Find the file whose receipt says \"Current bound reference\".",
        ),
      )
    }
  })
}

let () = {
  let args = argv->Js.Array2.slice(~start=2, ~end_=99)
  if Belt.Array.length(args) > 0 {
    switch assertNotSuperseded(args) {
    | () => write("REFS OK — none of the " ++ Belt.Int.toString(Belt.Array.length(args)) ++ " path(s) are superseded\n")
    | exception RefError(m) =>
      write("REFS REFUSED — " ++ m ++ "\n")
      exit(1)
    }
  } else {
    let dead = supersededNames()
    write("superseded references on record (" ++ Belt.Int.toString(Belt.Array.length(dead)) ++ "):\n")
    dead->Belt.Array.forEach(d => write("  " ++ d ++ "\n"))
  }
}
