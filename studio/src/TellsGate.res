/* TELLS GATE - greps a prose deliverable against the named-tells registry
   (Tells.res). Stage-7 bailiff for expository surfaces: treatments,
   summaries, pitch copy, editor reads, docs. NEVER pointed at scenes -
   dialogue is exempt by construction (people hedge; that's human).
   Block-tier hit = exit 1. Warn-tier prints. Judge tier prints as the
   finishing checklist. Run: node src/TellsGate.res.mjs <file> [file...] */

@module("fs") external readFileSync: (string, string) => string = "readFileSync"
@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external exit: int => unit = "exit"

let blocked = ref(false)

let checkFile = (path: string) => {
  let text = readFileSync(path, "utf8")
  let lines = Js.String2.split(text, "\n")
  Js.log("TELLS GATE on " ++ path)
  let hits = ref(0)
  Tells.tells->Belt.Array.forEach(t => {
    lines->Belt.Array.forEachWithIndex((i, line) => {
      /* use/mention escape: a line QUOTING a banned pattern (a registry, a law
         doc) carries the pragma and is exempt */
      if !Js.String2.includes(line, "tells:ok") && Js.Re.test_(t.re, line) {
        hits := hits.contents + 1
        let tag = switch t.severity {
        | Tells.Block => {
            blocked := true
            "  FAIL  "
          }
        | Tells.Warn => "  warn  "
        }
        Js.log(
          tag ++
          t.name ++
          " @ line " ++
          Belt.Int.toString(i + 1) ++
          ": " ++
          Js.String2.trim(Js.String2.slice(line, ~from=0, ~to_=110)),
        )
        Js.log("        fix: " ++ t.fix)
      }
    })
  })
  if hits.contents == 0 {
    Js.log("  ok    no mechanical tells")
  }
}

let main = () => {
  let files = argv->Belt.Array.sliceToEnd(2)
  if Belt.Array.length(files) == 0 {
    Js.log("usage: node src/TellsGate.res.mjs <file.md> [more files]")
    exit(2)
  } else {
    files->Belt.Array.forEach(checkFile)
    Js.log("")
    Js.log("JUDGE TIER (run in the finishing pass, by eye):")
    Tells.judgeTier->Belt.Array.forEach(q => Js.log("  - " ++ q))
    if blocked.contents {
      Js.log("TELLS GATE: FAIL")
      exit(1)
    } else {
      Js.log("TELLS GATE: PASS (mechanical tier)")
    }
  }
}
main()
