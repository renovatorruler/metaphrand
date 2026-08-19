@val @scope("process") external exitProcess: int => unit = "exit"
@module("node:path") external resolvePath: string => string = "resolve"

try {
  let root = resolvePath("../stories/kuku/ep9prod/finale")
  let result = Kuku_Ep9C03Local.build(~root)
  Js.Console.log("C03 local fallback: " ++ result.output)
  Js.Console.log("mask: " ++ result.mask)
  Js.Console.log("clean plate: " ++ result.cleanPlate)
  Js.Console.log("Furia layer: " ++ result.layer)
  Js.Console.log("contact: " ++ result.contact)
  Js.Console.log(result.probe)
} catch {
| Kuku_Ep9C03Local.C03LocalError(message)
| Cinema_Backends.BackendError(message) => {
    Js.Console.error("C03 LOCAL FALLBACK FAILED: " ++ message)
    exitProcess(1)
  }
}

