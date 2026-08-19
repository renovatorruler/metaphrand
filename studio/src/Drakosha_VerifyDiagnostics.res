/* Read-only verifier for the hash-indexed Drakosha diagnostic set.

   This command reconstructs the report, proof, and index bytes from the
   current registry, manifest, backlog, screenplay, and evaluator.  It accepts
   both PASS and FAIL preflight verdicts: the purpose is to prove that the
   diagnostics on disk are complete and current, not to clear the screenplay.

   Run from studio/:
     node src/Drakosha_VerifyDiagnostics.res.mjs <registry.json> <manifest.json> */

open Cinema_Backends

@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external exit: int => unit = "exit"
@module("node:path") external dirname: string => string = "dirname"
@module("node:path") external resolve2: (string, string) => string = "resolve"

let requireUnchanged = (label: string, expected: string, path: string): unit => {
  let actual = readText(Path(path))
  if Drakosha_Spatial.sha256(actual) != Drakosha_Spatial.sha256(expected) {
    raise(
      Drakosha_OutputSafety.OutputSafetyError(
        label ++ " changed during diagnostic verification: " ++ path,
      ),
    )
  }
}

let verifySet = (set: Drakosha_Diagnostics.diagnosticSet): unit =>
  try {
    Drakosha_Diagnostics.verify(set)
  } catch {
  | Js.Exn.Error(error) =>
    raise(
      Drakosha_OutputSafety.OutputSafetyError(
        "cannot read the diagnostic set: " ++
        Js.Exn.message(error)->Belt.Option.getWithDefault("unknown filesystem error"),
      ),
    )
  }

let main = () =>
  switch (Belt.Array.get(argv, 2), Belt.Array.get(argv, 3)) {
  | (Some(registryArgument), Some(manifestArgument)) =>
    try {
      let registryPath = Drakosha_OutputSafety.absolutePath(registryArgument)
      let manifestPath = Drakosha_OutputSafety.absolutePath(manifestArgument)
      let registryRaw = readText(Path(registryPath))
      let manifestRaw = readText(Path(manifestPath))
      let registry = Drakosha_Spatial.decodeRegistry(registryRaw)
      let manifest = Drakosha_Spatial.decodeManifest(manifestRaw)
      let base = dirname(manifestPath)
      let screenplayPath = resolve2(base, manifest.source.path)
      let backlogPath = resolve2(base, manifest.backlog.path)
      let backlogRaw = readText(Path(backlogPath))
      Drakosha_Spatial.validateBacklogRaw(~manifest, ~raw=backlogRaw)
      let screenplay = readText(Path(screenplayPath))
      let evaluation = Drakosha_Spatial.evaluate(~registry, ~manifest, ~screenplay)
      let set = Drakosha_Diagnostics.build(
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

      verifySet(set)

      /* Detect replacements during this verification window.  A standalone
         verifier cannot make paths immutable, so downstream consumers must
         still run it immediately before using the diagnostics. */
      requireUnchanged("registry input", registryRaw, registryPath)
      requireUnchanged("manifest input", manifestRaw, manifestPath)
      requireUnchanged("screenplay input", screenplay, screenplayPath)
      requireUnchanged("physical backlog input", backlogRaw, backlogPath)
      verifySet(set)

      let verdict = Drakosha_Spatial.hasBlockers(evaluation) ? "FAIL" : "PASS"
      Js.log("VERIFIED DRAKOSHA DIAGNOSTIC SET")
      Js.log("verdict: " ++ verdict)
      Js.log("index: " ++ set.indexPath)
      Js.log("report: " ++ set.reportPath)
      Js.log(
        "indexed files: " ++ Belt.Int.toString(Belt.Array.length(set.contentFiles)),
      )
    } catch {
    | Drakosha_OutputSafety.OutputSafetyError(message) => {
        Js.log("DIAGNOSTIC VERIFICATION FAILED: " ++ message)
        exit(1)
      }
    | Drakosha_Spatial.SpatialError(message) => {
        Js.log("DIAGNOSTIC VERIFICATION INPUT ERROR: " ++ message)
        exit(2)
      }
    | Js.Exn.Error(error) => {
        Js.log(
          "DIAGNOSTIC VERIFICATION ERROR: " ++
          Js.Exn.message(error)->Belt.Option.getWithDefault("unknown JavaScript error"),
        )
        exit(2)
      }
    }
  | _ => {
      Js.log(
        "usage: node src/Drakosha_VerifyDiagnostics.res.mjs <registry.json> <manifest.json>",
      )
      exit(2)
    }
  }

main()
