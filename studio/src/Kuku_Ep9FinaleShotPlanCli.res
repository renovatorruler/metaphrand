@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external exitProcess: int => unit = "exit"
@module("node:path") external resolvePath: string => string = "resolve"

switch argv->Belt.Array.sliceToEnd(2) {
| [manifestArgument] =>
  try {
    Kuku_Ep9FinaleShotPlan.validate(~manifestPath=resolvePath(manifestArgument))
    ->Kuku_Ep9FinaleShotPlan.printResult
  } catch {
  | Kuku_Ep9FinaleShotPlan.ShotPlanError(message) => {
      Js.Console.error("KUKU EP9 FINALE SHOT PLAN ERROR: " ++ message)
      exitProcess(1)
    }
  }
| _ => {
    Js.Console.error("usage: node src/Kuku_Ep9FinaleShotPlanCli.res.mjs <paid-shots.json>")
    exitProcess(2)
  }
}
