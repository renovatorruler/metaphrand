/* CLI wrapper for the deterministic Frosya-and-Vasya physical gate.

   Run from studio/:
     node src/Drakosha_Preflight.res.mjs <registry.json> <manifest.json>

   The screenplay and output paths are resolved relative to the manifest. */

open Cinema_Backends

@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external exit: int => unit = "exit"
@module("node:path") external dirname: string => string = "dirname"
@module("node:path") external resolve2: (string, string) => string = "resolve"

let main = () =>
  switch (Belt.Array.get(argv, 2), Belt.Array.get(argv, 3)) {
  | (Some(registryPath), Some(manifestPath)) =>
    try {
      let registryRaw = readText(Path(registryPath))
      let manifestRaw = readText(Path(manifestPath))
      let registry = registryRaw->Drakosha_Spatial.decodeRegistry
      let manifest = manifestRaw->Drakosha_Spatial.decodeManifest
      let base = dirname(manifestPath)
      let screenplayPath = resolve2(base, manifest.source.path)
      let backlogPath = resolve2(base, manifest.backlog.path)
      let backlogRaw = readText(Path(backlogPath))
      Drakosha_Spatial.validateBacklogRaw(~manifest, ~raw=backlogRaw)
      let screenplay = readText(Path(screenplayPath))
      let evaluation = Drakosha_Spatial.evaluate(~registry, ~manifest, ~screenplay)
      let diagnostics = Drakosha_Diagnostics.build(
        ~base,
        ~protectedPaths=[
          {Drakosha_OutputSafety.label: "registry input", path: registryPath},
          {Drakosha_OutputSafety.label: "manifest input", path: manifestPath},
          {Drakosha_OutputSafety.label: "screenplay input", path: screenplayPath},
          {Drakosha_OutputSafety.label: "physical backlog input", path: backlogPath},
        ],
        ~registry,
        ~manifest,
        ~evaluation,
        ~registryRaw,
        ~manifestRaw,
        ~backlogRaw,
      )
      Drakosha_Diagnostics.publish(diagnostics)
      let blockers =
        evaluation.findings->Belt.Array.keep(f => f.severity == Drakosha_Spatial.Blocking)
      Js.log("DRAKOSHA PHYSICAL PREFLIGHT")
      Js.log("screenplay: " ++ screenplayPath)
      Js.log("report: " ++ diagnostics.reportPath)
      Js.log("diagnostic index: " ++ diagnostics.indexPath)
      evaluation.passed->Belt.Array.forEach(p => Js.log("  ok   " ++ p))
      if Belt.Array.length(blockers) > 0 {
        Js.log("\nBLOCKING:")
        blockers->Belt.Array.forEach(f =>
          Js.log("  FAIL " ++ f.code ++ " [" ++ f.scope ++ "]: " ++ f.detail)
        )
        Js.log(
          "\nPREFLIGHT FAILED — " ++
          Belt.Int.toString(Belt.Array.length(blockers)) ++ " blocking findings",
        )
        exit(1)
      } else {
        Js.log("\nPREFLIGHT PASSED")
      }
    } catch {
    | Drakosha_OutputSafety.OutputSafetyError(message) => {
        Js.log("DRAKOSHA PREFLIGHT OUTPUT ERROR: " ++ message)
        exit(2)
      }
    | Drakosha_Spatial.SpatialError(message) => {
        Js.log("DRAKOSHA PREFLIGHT INPUT ERROR: " ++ message)
        exit(2)
      }
    | Js.Exn.Error(error) => {
        Js.log(
          "DRAKOSHA PREFLIGHT ERROR: " ++
          Js.Exn.message(error)->Belt.Option.getWithDefault("unknown JavaScript error"),
        )
        exit(2)
      }
    }
  | _ => {
      Js.log("usage: node src/Drakosha_Preflight.res.mjs <registry.json> <manifest.json>")
      exit(2)
    }
  }

main()
