/* PREFLIGHT - the per-work hard-stop (port of metaphrand/preflight.py; docs/05
   per-work pass). A required pass with no enforcing gate gets skipped: AMAL was
   drafted eleven versions deep on top of a missing natal-chart/voice-card pass
   because nothing STOPPED it. Production refuses to start while any required
   design artifact is absent, stub-thin, or missing a cast member's entry.
   Call Preflight.require_ at the top of every draft/produce entry point. */

@module("fs") external readFileSync: (string, string) => string = "readFileSync"
@module("fs") external existsSync: string => bool = "existsSync"
@module("fs") external readdirSync: string => array<string> = "readdirSync"
@val @scope("process") external exit: int => unit = "exit"

type artifact = {
  filename: string,
  label: string,
  perCharacter: bool, /* must carry an entry for EVERY cast member */
  minChars: int, /* guard against a stub ticking the box */
}

/* The per-work manifest (docs/05), expressed as DATA the gate enforces. */
let required: array<artifact> = [
  {filename: "BIBLE.md", label: "World bible - register, place, the engine", perCharacter: false, minChars: 200},
  {filename: "BACKSTORY.md", label: "Iceberg backstories - informs, never stated", perCharacter: false, minChars: 200},
  {filename: "CHARTS.md", label: "Natal charts - the voice generator (docs/04)", perCharacter: true, minChars: 200},
  {filename: "VOICE_CARDS.md", label: "Voice cards read from the charts (six axes)", perCharacter: true, minChars: 200},
]

let escapeRe = (s: string): string =>
  Js.String2.replaceByRe(s, %re("/[.*+?^${}()|[\]\\]/g"), "\\$&")

/* house naming law dates deliverables: accept `YYYY-MM-DD_FILENAME` variants,
   latest wins; the undated canonical name also counts. */
let resolve = (sdir: string, filename: string): option<string> => {
  let re = Js.Re.fromStringWithFlags("^(\\d{4}-\\d{2}-\\d{2}_)?" ++ escapeRe(filename) ++ "$", ~flags="")
  let matches =
    readdirSync(sdir)
    ->Belt.Array.keep(f => Js.Re.test_(re, f))
    ->Belt.SortArray.String.stableSort
  matches->Belt.Array.get(Belt.Array.length(matches) - 1)->Belt.Option.map(f => sdir ++ "/" ++ f)
}

/* empty array == the gate is green */
let audit = (~storiesDir: string, ~slug: string, ~cast: array<string>): array<string> => {
  let sdir = storiesDir ++ "/" ++ slug
  if !existsSync(sdir) {
    ["story dir missing: stories/" ++ slug ++ "/"]
  } else {
    let fails = []
    required->Belt.Array.forEach(art => {
      switch resolve(sdir, art.filename) {
      | None => Js.Array2.push(fails, "MISSING  " ++ art.filename ++ " - " ++ art.label)->ignore
      | Some(path) => {
        let text = readFileSync(path, "utf8")
        if Js.String2.length(Js.String2.trim(text)) < art.minChars {
          Js.Array2.push(
            fails,
            "EMPTY    " ++ art.filename ++ " - " ++ art.label ++ " (<" ++ Belt.Int.toString(art.minChars) ++ " chars)",
          )->ignore
        } else if art.perCharacter && Belt.Array.length(cast) > 0 {
          let low = Js.String2.toLowerCase(text)
          let missing = cast->Belt.Array.keep(c => {
            let re = Js.Re.fromStringWithFlags("\\b" ++ escapeRe(Js.String2.toLowerCase(c)) ++ "\\b", ~flags="")
            !Js.Re.test_(re, low)
          })
          if Belt.Array.length(missing) > 0 {
            Js.Array2.push(
              fails,
              "PARTIAL  " ++ art.filename ++ " - no entry for: " ++ missing->Belt.Array.joinWith(", ", x => x),
            )->ignore
          }
        }
      }
      }
    })
    fails
  }
}

let report = (~slug: string, fails: array<string>): string =>
  if Belt.Array.length(fails) == 0 {
    "preflight [" ++ slug ++ "]: PASS - every per-work design artifact present and complete."
  } else {
    "preflight [" ++
    slug ++
    "]: FAIL - " ++
    Belt.Int.toString(Belt.Array.length(fails)) ++
    " gap(s). DRAFTING / PRODUCTION IS BLOCKED until these exist (docs/05 per-work pass; Preflight.res is the manifest):\n" ++
    fails->Belt.Array.joinWith("\n", f => "  x " ++ f)
  }

let passes = (~storiesDir, ~slug, ~cast) => Belt.Array.length(audit(~storiesDir, ~slug, ~cast)) == 0

/* hard-stop: call at the top of any draft/produce entry point */
let require_ = (~storiesDir, ~slug, ~cast): unit => {
  let fails = audit(~storiesDir, ~slug, ~cast)
  if Belt.Array.length(fails) > 0 {
    Js.log(report(~slug, fails))
    exit(1)
  }
}
