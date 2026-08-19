@val @scope("process") external exitProcess: int => unit = "exit"
@module("node:path") external resolvePath: string => string = "resolve"

try {
  let root = resolvePath("../stories/kuku/ep9prod/finale")
  let result = Kuku_Ep9C12Local.build(~root)
  Js.Console.log("C12 local rhythm insert: " ++ result.output)
  Js.Console.log("sha256: " ++ result.outputSha256)
  Js.Console.log("contact: " ++ result.contact)
  Js.Console.log(result.probe)
} catch {
| Kuku_Ep9C12Local.C12LocalError(message)
| Cinema_Backends.BackendError(message) => {
    Js.Console.error("C12 LOCAL MOTION FAILED: " ++ message)
    exitProcess(1)
  }
}
