@val @scope("process") external exitProcess: int => unit = "exit"
@module("node:path") external resolvePath: string => string = "resolve"

try {
  let root = resolvePath("../stories/kuku/ep9prod/finale")
  let result = Kuku_Ep9B09Reuse.build(~root)
  Js.Console.log("B09 local reuse: " ++ result.output)
  Js.Console.log("sha256: " ++ result.outputSha256)
  Js.Console.log("contact: " ++ result.contact)
  Js.Console.log(result.probe)
} catch {
| Kuku_Ep9B09Reuse.B09ReuseError(message)
| Cinema_Backends.BackendError(message) => {
    Js.Console.error("B09 LOCAL REUSE FAILED: " ++ message)
    exitProcess(1)
  }
}
