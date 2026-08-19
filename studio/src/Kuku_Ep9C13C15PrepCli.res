@val @scope("process") external exitProcess: int => unit = "exit"
@module("node:path") external resolvePath: string => string = "resolve"

try {
  let root = resolvePath("../stories/kuku/ep9prod/finale")
  let result = Kuku_Ep9C13C15Prep.build(~root)
  Js.Console.log("C13 start: " ++ result.c13Start ++ " " ++ result.c13StartSha256)
  Js.Console.log("C14 start: " ++ result.c14Start ++ " " ++ result.c14StartSha256)
  Js.Console.log("C15 start: " ++ result.c15Start ++ " " ++ result.c15StartSha256)
  Js.Console.log("batch QA: " ++ result.batchContact)
  Js.Console.log("proposal: " ++ result.proposal ++ " " ++ result.proposalSha256)
} catch {
| Kuku_Ep9C13C15Prep.C13C15PrepError(message)
| Cinema_Backends.BackendError(message) => {
    Js.Console.error("C13-C15 PREP FAILED: " ++ message)
    exitProcess(1)
  }
}
