@val @scope("process") external exitProcess: int => unit = "exit"
@module("node:path") external resolvePath: string => string = "resolve"

try {
  let root = resolvePath("../stories/kuku/ep9prod/finale")
  let result = Kuku_Ep9B11LocalRepair.build(~root)
  Js.Console.log("B11 local repair candidate: " ++ result.output)
  Js.Console.log("sha256: " ++ result.outputSha256)
  Js.Console.log("contact: " ++ result.contact)
  Js.Console.log("contact sha256: " ++ result.contactSha256)
  Js.Console.log(result.probe)
} catch {
| Kuku_Ep9B11LocalRepair.B11LocalRepairError(message)
| Cinema_Backends.BackendError(message) => {
    Js.Console.error("B11 LOCAL REPAIR FAILED: " ++ message)
    exitProcess(1)
  }
}
