/* COMPOST — the heap validator (docs/09 organ 1). Keeps the source honest:
   every entry real (source line present), specific (minimum flesh), and
   schema-true (kind/date/source/snag). The heap the stories steal from.
   Run: node src/Compost.res.mjs */

@module("fs") external readFileSync: (string, string) => string = "readFileSync"
@module("fs") external readdirSync: string => array<string> = "readdirSync"
@val @scope("process") external exit: int => unit = "exit"

let dir = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/compost"

type entry = {file: string, kind: string, snag: string}

let kinds = ["incident", "person", "image", "line", "fact"]

let field = (text: string, name: string): option<string> =>
  Js.String2.split(text, "\n")
  ->Belt.Array.getBy(l => Js.String2.startsWith(Js.String2.trim(l), name ++ ":"))
  ->Belt.Option.map(l => Js.String2.trim(Js.String2.sliceToEnd(Js.String2.trim(l), ~from=Js.String2.length(name) + 1)))

let main = () => {
  let files = readdirSync(dir)->Belt.Array.keep(f => Js.String2.endsWith(f, ".md"))
  let failed = ref(false)
  let entries = []
  files->Belt.Array.forEach(f => {
    let text = readFileSync(dir ++ "/" ++ f, "utf8")
    let kind = field(text, "kind")
    let source = field(text, "source")
    let snag = field(text, "snag")
    let date = field(text, "date")
    let bodyLen = Js.String2.length(Js.String2.trim(text))
    let bad = msg => {
      failed := true
      Js.log("  FAIL  " ++ f ++ " — " ++ msg)
    }
    switch (kind, source, snag, date) {
    | (None, _, _, _) => bad("no kind: line")
    | (_, None, _, _) => bad("no source: line — nothing invented enters the heap; unsourced = deleted")
    | (_, _, None, _) => bad("no snag: line — if it didn't hook you, it isn't compost")
    | (_, _, _, None) => bad("no date: line")
    | (Some(k), Some(s), Some(sn), Some(_)) =>
      if !Belt.Array.some(kinds, x => x == k) {
        bad("kind '" ++ k ++ "' not one of incident|person|image|line|fact")
      } else if Js.String2.length(s) < 12 {
        bad("source too thin to check")
      } else if bodyLen < 400 {
        bad("too thin (" ++ Belt.Int.toString(bodyLen) ++ " chars) — specifics or it composts nothing")
      } else {
        Js.Array2.push(entries, {file: f, kind: k, snag: sn})->ignore
      }
    }
  })
  Js.log("COMPOST — " ++ Belt.Int.toString(Belt.Array.length(entries)) ++ " valid entr" ++ (Belt.Array.length(entries) == 1 ? "y" : "ies"))
  entries->Belt.Array.forEach(e => Js.log("  " ++ e.kind ++ "  " ++ e.file ++ " — " ++ e.snag))
  if failed.contents {
    Js.log("COMPOST: FAIL — fix or delete the entries above")
    exit(1)
  }
}
main()
