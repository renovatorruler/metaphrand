/* CLI wrapper for the guarded Scene 1 generation library. */

@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external exitProcess: int => unit = "exit"

let main = () => {
  let args = argv->Belt.Array.sliceToEnd(2)
  let go = args->Belt.Array.some(argument => argument == "--go")
  let positional = args->Belt.Array.keep(argument => argument != "--go")
  try {
    switch positional {
    | [manifestPath, stage] => Drakosha_SceneFlow.runStage(~manifestPath, ~stage, ~go)
    | _ =>
      raise(
        Drakosha_SceneFlow.FlowError(
          "usage: node src/Drakosha_SceneFlowCli.res.mjs <scene1.production.v1.json> <refs|storyboard|motion> [--go]",
        ),
      )
    }
  } catch {
  | Drakosha_SceneFlow.FlowError(message) => {
      Js.Console.error("GATE: " ++ message)
      exitProcess(1)
    }
  | Cinema_Backends.BackendError(message) => {
      Js.Console.error("GATE: backend failure: " ++ message)
      exitProcess(1)
    }
  | Js.Exn.Error(error) => {
      Js.Console.error(
        "GATE: unexpected error: " ++
        Js.Exn.message(error)->Belt.Option.getWithDefault("unknown JavaScript error"),
      )
      exitProcess(1)
    }
  }
}

main()
