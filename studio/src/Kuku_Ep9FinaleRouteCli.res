@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external exitProcess: int => unit = "exit"
@module("node:path") external resolvePath: string => string = "resolve"

switch argv->Belt.Array.sliceToEnd(2) {
| [routeArgument] =>
  try {
    Kuku_Ep9FinaleRoute.validate(~routePath=resolvePath(routeArgument))
    ->Kuku_Ep9FinaleRoute.printResult
  } catch {
  | Kuku_Ep9FinaleRoute.RouteError(message) => {
      Js.Console.error("KUKU EP9 FINALE ROUTE ERROR: " ++ message)
      exitProcess(1)
    }
  }
| _ => {
    Js.Console.error("usage: node src/Kuku_Ep9FinaleRouteCli.res.mjs <ep9-route-v2.json>")
    exitProcess(2)
  }
}
