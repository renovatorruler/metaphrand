@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external exitProcess: int => unit = "exit"
@module("node:path") external resolvePath: string => string = "resolve"

switch argv->Belt.Array.sliceToEnd(2) {
| [manifestArgument] =>
  try {
    Kuku_Ep9FinaleAnchorStills.validate(~manifestPath=resolvePath(manifestArgument))
    ->Kuku_Ep9FinaleAnchorStills.printResult
  } catch {
  | Kuku_Ep9FinaleAnchorStills.AnchorStillsError(message) => {
      Js.Console.error("KUKU EP9 FINALE ANCHOR STILLS ERROR: " ++ message)
      exitProcess(1)
    }
  }
| _ => {
    Js.Console.error(
      "usage: node src/Kuku_Ep9FinaleAnchorStillsCli.res.mjs <anchor-stills.json>",
    )
    exitProcess(2)
  }
}
