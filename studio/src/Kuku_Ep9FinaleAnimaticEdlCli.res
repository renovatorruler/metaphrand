@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external exitProcess: int => unit = "exit"
@module("node:path") external resolvePath: string => string = "resolve"

switch argv->Belt.Array.sliceToEnd(2) {
| [manifestArgument] =>
  try {
    let manifestPath = resolvePath(manifestArgument)
    if Kuku_Ep9FinaleAnimaticEdlV2.isV2(~manifestPath) {
      Kuku_Ep9FinaleAnimaticEdlV2.validate(~manifestPath)
      ->Kuku_Ep9FinaleAnimaticEdlV2.printResult
    } else {
      Kuku_Ep9FinaleAnimaticEdl.validate(~manifestPath)
      ->Kuku_Ep9FinaleAnimaticEdl.printResult
    }
  } catch {
  | Kuku_Ep9FinaleAnimaticEdl.AnimaticEdlError(message) => {
      Js.Console.error("KUKU EP9 FINALE ANIMATIC EDL ERROR: " ++ message)
      exitProcess(1)
    }
  | Kuku_Ep9FinaleAnimaticEdlV2.AnimaticEdlV2Error(message) => {
      Js.Console.error("KUKU EP9 FINALE ANIMATIC EDL V2 ERROR: " ++ message)
      exitProcess(1)
    }
  }
| _ => {
    Js.Console.error(
      "usage: node src/Kuku_Ep9FinaleAnimaticEdlCli.res.mjs <animatic-edl-v1-or-v2.json>",
    )
    exitProcess(2)
  }
}
