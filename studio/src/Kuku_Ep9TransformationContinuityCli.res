@val @scope("process") external exitProcess: int => unit = "exit"
@module("node:path") external resolvePath: string => string = "resolve"

try {
  let root = resolvePath("../stories/kuku/ep9prod/finale")
  let result = Kuku_Ep9TransformationContinuity.build(~root)
  Js.Console.log("continuity animatic: " ++ result.video)
  Js.Console.log("video sha256: " ++ result.videoSha256)
  Js.Console.log("continuity board: " ++ result.board)
  Js.Console.log("board sha256: " ++ result.boardSha256)
  Js.Console.log("QA contact: " ++ result.contact)
  Js.Console.log("contact sha256: " ++ result.contactSha256)
  Js.Console.log(result.probe)
} catch {
| Kuku_Ep9TransformationContinuity.TransformationContinuityError(message)
| Cinema_Backends.BackendError(message) => {
    Js.Console.error("TRANSFORMATION CONTINUITY BUILD FAILED: " ++ message)
    exitProcess(1)
  }
}
