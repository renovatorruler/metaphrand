/* Command-line wrapper for the reusable, zero-spend scene-readiness gate. */

open Cinema_Backends
open Drakosha_SceneReadiness

@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external exit: int => unit = "exit"
@module("node:path") external resolve1: string => string = "resolve"

let main = () =>
  switch (Belt.Array.get(argv, 2), Belt.Array.get(argv, 3)) {
  | (Some(manifestArgument), Some(stageArgument)) =>
    try {
      let manifestPath = resolve1(manifestArgument)
      let manifest = readText(Path(manifestPath))->decodeManifest
      let evaluation = evaluate(~manifest, ~manifestPath, ~stage=decodeStage(stageArgument))
      printCard(evaluation)
      if hasBlockers(evaluation) {
        exit(1)
      }
    } catch {
    | ReadinessError(message) => {
        Js.log("SCENE READINESS INPUT ERROR: " ++ message)
        exit(2)
      }
    | BackendError(message) => {
        Js.log("SCENE READINESS FILE ERROR: " ++ message)
        exit(2)
      }
    | Js.Exn.Error(error) => {
        Js.log(
          "SCENE READINESS ERROR: " ++
          Js.Exn.message(error)->Belt.Option.getWithDefault("unknown JavaScript error"),
        )
        exit(2)
      }
    }
  | _ => {
      Js.log(
        "usage: node src/Drakosha_SceneReadinessCli.res.mjs <scene-manifest.json> <reference_board|storyboard|motion|lipsync|delivery>",
      )
      exit(2)
    }
  }

main()

