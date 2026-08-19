@val @scope("process") external exitProcess: int => unit = "exit"
@module("node:path") external resolvePath: string => string = "resolve"

try {
  let root = resolvePath("../stories/kuku/ep9prod/finale")
  let result = Kuku_Ep9B15Local.build(~root)
  Js.Console.log("B15 local motion: " ++ result.output)
  Js.Console.log("sha256: " ++ result.outputSha256)
  Js.Console.log("start frame: " ++ result.startFrame)
  Js.Console.log("start sha256: " ++ result.startFrameSha256)
  Js.Console.log("contact: " ++ result.contact)
  Js.Console.log(result.probe)
} catch {
| Kuku_Ep9B15Local.B15LocalError(message)
| Cinema_Backends.BackendError(message) => {
    Js.Console.error("B15 LOCAL MOTION FAILED: " ++ message)
    exitProcess(1)
  }
}
