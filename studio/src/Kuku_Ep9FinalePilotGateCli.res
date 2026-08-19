@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external exitProcess: int => unit = "exit"
@module("node:path") external resolvePath: string => string = "resolve"

switch argv->Belt.Array.sliceToEnd(2) {
| [manifestArgument, spendArgument] =>
  try {
    Kuku_Ep9FinalePilotGate.validate(
      ~manifestPath=resolvePath(manifestArgument),
      ~spendPath=resolvePath(spendArgument),
    )
    ->Kuku_Ep9FinalePilotGate.printResult
  } catch {
  | Kuku_Ep9FinalePilotGate.PilotGateError(message) => {
      Js.Console.error("KUKU EP9 CALIBRATION PILOT GATE BLOCKED: " ++ message)
      exitProcess(1)
    }
  | Kuku_Ep9FinaleShotPlan.ShotPlanError(message) => {
      Js.Console.error("KUKU EP9 CALIBRATION PILOT GATE BLOCKED: " ++ message)
      exitProcess(1)
    }
  }
| _ => {
    Js.Console.error(
      "usage: node src/Kuku_Ep9FinalePilotGateCli.res.mjs <paid-shots.json> <spend-ledger.json>",
    )
    exitProcess(2)
  }
}
