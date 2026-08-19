@val @scope("process") external exitProcess: int => unit = "exit"
@module("node:path") external resolvePath: string => string = "resolve"

try {
  let root = resolvePath("../stories/kuku/ep9prod/finale")
  let result = Kuku_Ep9C06Local.build(~root)
  Js.Console.log("C06 local motion: " ++ result.output)
  Js.Console.log("sha256: " ++ result.outputSha256)
  Js.Console.log("contact: " ++ result.contact)
  Js.Console.log("end frame: " ++ result.endFrame)
  Js.Console.log("end frame sha256: " ++ result.endFrameSha256)
  Js.Console.log(result.probe)
} catch {
| Kuku_Ep9C06Local.C06LocalError(message)
| Cinema_Backends.BackendError(message) => {
    Js.Console.error("C06 LOCAL MOTION FAILED: " ++ message)
    exitProcess(1)
  }
}
