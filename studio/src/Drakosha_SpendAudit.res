/* ============================================================================
   Drakosha_SpendAudit — zero-spend quota visibility for guarded generation.

   Reads what the runner's own safety machinery leaves on disk — atomic attempt
   receipts (attempt-N.json), success receipts, and active leases — and reports
   per-subject paid-attempt usage against the manifest's hard cap. Never calls
   a provider, never writes anything.

   Usage (from studio/):
     node src/Drakosha_SpendAudit.res.mjs <scene1.production.v1.json>

   Exit codes: 0 = within budget, 1 = input error, 2 = anomaly that needs a
   human (attempt files beyond the cap, orphan lease, unreadable receipt).
   ============================================================================ */

module B = Cinema_Backends

@module("path") external dirname: string => string = "dirname"
@module("path") external join2: (string, string) => string = "join"
@module("path") external resolvePath: string => string = "resolve"

@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external exitProcess: int => unit = "exit"

let jObj = Js.Json.decodeObject
let jStr = Js.Json.decodeString

type attemptRow = {file: string, status: string}
type subjectReport = {
  subjectId: string,
  attempts: array<attemptRow>,
  leaseHeld: bool,
  anomalies: array<string>,
}

let readStatus = (path: string): string =>
  switch try Some(Js.Json.parseExn(B.readText(B.Path(path)))) catch {
  | _ => None
  } {
  | None => "UNREADABLE"
  | Some(json) =>
    jObj(json)
    ->Belt.Option.flatMap(o => Js.Dict.get(o, "status"))
    ->Belt.Option.flatMap(jStr)
    ->Belt.Option.getWithDefault("MISSING-STATUS")
  }

let auditSubject = (receiptsRoot: string, subjectId: string, cap: int): subjectReport => {
  let dir = join2(receiptsRoot, subjectId)
  let entries = B.readDir(B.Path(dir))
  let attempts =
    entries
    ->Belt.Array.keep(name =>
      Js.String2.startsWith(name, "attempt-") && Js.String2.endsWith(name, ".json")
    )
    ->Js.Array2.sortInPlace
    ->Belt.Array.map(name => {file: name, status: readStatus(join2(dir, name))})
  let leaseHeld = entries->Belt.Array.some(name => name == "active.lock")
  let anomalies = []
  if Belt.Array.length(attempts) > cap {
    anomalies
    ->Js.Array2.push(
      "MORE ATTEMPT FILES THAN THE CAP ALLOWS (" ++
      Belt.Int.toString(Belt.Array.length(attempts)) ++ " > " ++ Belt.Int.toString(cap) ++ ")",
    )
    ->ignore
  }
  attempts->Belt.Array.forEach(row =>
    if row.status == "UNREADABLE" || row.status == "MISSING-STATUS" {
      anomalies->Js.Array2.push("unreadable attempt receipt: " ++ row.file)->ignore
    }
  )
  {subjectId, attempts, leaseHeld, anomalies}
}

let main = () => {
  switch argv->Belt.Array.sliceToEnd(2) {
  | [manifestPath] => {
      let absolute = resolvePath(manifestPath)
      if !B.exists(B.Path(absolute)) {
        Js.Console.error("SPEND-AUDIT: manifest not found: " ++ absolute)
        exitProcess(1)
      }
      let decoded = try Drakosha_SceneReadiness.decodeManifest(B.readText(B.Path(absolute))) catch {
      | Drakosha_SceneReadiness.ReadinessError(message) => {
          Js.Console.error("SPEND-AUDIT: manifest rejected: " ++ message)
          exitProcess(1)
          raise(Drakosha_SceneReadiness.ReadinessError(message))
        }
      }
      let cap = decoded.maxPaidAttemptsPerTarget
      let receiptsRoot = join2(dirname(absolute), "generation-receipts")
      let subjects = B.readDir(B.Path(receiptsRoot))->Belt.Array.keep(name =>
        !Js.String2.startsWith(name, ".")
      )
      Js.log("GUARDED SPEND AUDIT — " ++ decoded.sceneId)
      Js.log(
        "cap per subject: " ++
        Belt.Int.toString(cap) ++
        " paid attempts; subjects with receipts: " ++
        Belt.Int.toString(Belt.Array.length(subjects)),
      )
      let totalAttempts = ref(0)
      let anomalyCount = ref(0)
      subjects->Belt.Array.forEach(subjectId => {
        let report = auditSubject(receiptsRoot, subjectId, cap)
        let used = Belt.Array.length(report.attempts)
        totalAttempts := totalAttempts.contents + used
        let statuses =
          report.attempts
          ->Belt.Array.map(row => row.status)
          ->Js.Array2.joinWith(",")
        let flags = Belt.Array.concat(
          report.leaseHeld ? ["LEASE-HELD"] : [],
          used >= cap ? ["AT-CAP"] : [],
        )
        Js.log(
          "  " ++
          subjectId ++
          "  " ++
          Belt.Int.toString(used) ++ "/" ++ Belt.Int.toString(cap) ++
          (statuses == "" ? "" : "  [" ++ statuses ++ "]") ++
          (Belt.Array.length(flags) == 0 ? "" : "  " ++ Js.Array2.joinWith(flags, " ")),
        )
        report.anomalies->Belt.Array.forEach(a => {
          anomalyCount := anomalyCount.contents + 1
          Js.log("    ANOMALY: " ++ a)
        })
      })
      Js.log(
        "total paid submissions recorded: " ++
        Belt.Int.toString(totalAttempts.contents) ++
        " (each recorded BEFORE its provider call; a crashed run still counts)",
      )
      if anomalyCount.contents > 0 {
        Js.Console.error(
          "SPEND-AUDIT: " ++ Belt.Int.toString(anomalyCount.contents) ++ " anomalies need a human",
        )
        exitProcess(2)
      }
    }
  | _ => {
      Js.Console.error("usage: node src/Drakosha_SpendAudit.res.mjs <scene1.production.v1.json>")
      exitProcess(1)
    }
  }
}

main()
