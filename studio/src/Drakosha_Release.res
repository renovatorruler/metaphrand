/* The only supported way to mint a production-cleared Drakosha screenplay.

   A release is fail-closed: it first decodes enough manifest metadata to
   protect every input path, then invalidates the previous screenplay and
   receipt before evaluating content.  On PASS it creates an invocation-owned
   temporary directory beside the destination; the screenplay is atomically
   renamed into place first and the receipt last, making the receipt the commit
   marker without touching unrelated deterministic `.tmp` neighbors. */

open Cinema_Backends

@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external exit: int => unit = "exit"
@module("node:path") external dirname: string => string = "dirname"
@module("node:path") external resolve2: (string, string) => string = "resolve"
@module("node:fs") external mkdtempSync: string => string = "mkdtempSync"
@module("node:fs") external rmdirSync: string => unit = "rmdirSync"

type releasePaths = {
  screenplay: string,
  receipt: string,
}

type releaseAttempt = {
  directory: string,
  screenplayTemporary: string,
  receiptTemporary: string,
}

let releasePaths = (path: string): releasePaths => {
  let screenplay = Drakosha_OutputSafety.absolutePath(path)
  let receipt = screenplay ++ ".receipt.json"
  {screenplay, receipt}
}

let releaseOutputRows = (paths: releasePaths): array<Drakosha_OutputSafety.namedPath> => [
  {Drakosha_OutputSafety.label: "cleared screenplay", path: paths.screenplay},
  {Drakosha_OutputSafety.label: "release receipt", path: paths.receipt},
]

let invalidateRelease = (paths: releasePaths): unit => {
  let errors: array<string> = []
  let remove = (label, path) =>
    try {
      Drakosha_OutputSafety.removeFileEntry(path)
    } catch {
    | Drakosha_OutputSafety.OutputSafetyError(message) => {
        let _ = Js.Array2.push(errors, label ++ ": " ++ message)
      }
    | Js.Exn.Error(error) => {
        let _ = Js.Array2.push(
          errors,
          label ++ ": " ++ Js.Exn.message(error)->Belt.Option.getWithDefault("unknown error"),
        )
      }
    }
  /* Receipt is the commit marker, so invalidate it first.  Every path is
     attempted even if an earlier unlink fails. */
  remove("release receipt", paths.receipt)
  remove("cleared screenplay", paths.screenplay)
  if Belt.Array.length(errors) > 0 {
    raise(
      Drakosha_OutputSafety.OutputSafetyError(
        "release invalidation incomplete: " ++ errors->Js.Array2.joinWith("; "),
      ),
    )
  }
}

let createReleaseAttempt = (paths: releasePaths): releaseAttempt => {
  let parent = dirname(paths.screenplay)
  ensureDirPath(Path(parent))
  let directory = mkdtempSync(parent ++ "/.drakosha-release-")
  {
    directory,
    screenplayTemporary: directory ++ "/screenplay.md",
    receiptTemporary: directory ++ "/receipt.json",
  }
}

let cleanupReleaseAttempt = (attempt: releaseAttempt): unit => {
  Drakosha_OutputSafety.removeFileEntry(attempt.receiptTemporary)
  Drakosha_OutputSafety.removeFileEntry(attempt.screenplayTemporary)
  try {
    rmdirSync(attempt.directory)
  } catch {
  | Js.Exn.Error(error) =>
    raise(
      Drakosha_OutputSafety.OutputSafetyError(
        "cannot remove invocation-owned release temp directory " ++ attempt.directory ++ ": " ++
        Js.Exn.message(error)->Belt.Option.getWithDefault("unknown error"),
      ),
    )
  }
}

let retryInvalidationAfterFailure = (paths: releasePaths): unit =>
  try {
    invalidateRelease(paths)
  } catch {
  | Drakosha_OutputSafety.OutputSafetyError(message) =>
    Js.log(
      "RELEASE CLEANUP ERROR: " ++ message ++
      ". A stale output entry may remain on disk, but verify-release will reject it.",
    )
  | Js.Exn.Error(error) =>
    Js.log(
      "RELEASE CLEANUP ERROR: " ++
      Js.Exn.message(error)->Belt.Option.getWithDefault("unknown cleanup error") ++
      ". A stale output entry may remain on disk, but verify-release will reject it.",
    )
  }

let publish = (
  ~paths: releasePaths,
  ~screenplay: string,
  ~registryRaw: string,
  ~manifestRaw: string,
  ~backlogRaw: string,
  ~evaluation: Drakosha_Spatial.evaluation,
): unit => {
  let receipt = Js.Dict.empty()
  Js.Dict.set(receipt, "schema", Js.Json.string("drakosha.physical-release-receipt/v1"))
  Js.Dict.set(receipt, "screenplaySha256", Js.Json.string(evaluation.sourceSha256))
  Js.Dict.set(receipt, "registrySha256", Js.Json.string(Drakosha_Spatial.sha256(registryRaw)))
  Js.Dict.set(receipt, "manifestSha256", Js.Json.string(Drakosha_Spatial.sha256(manifestRaw)))
  Js.Dict.set(receipt, "backlogSha256", Js.Json.string(Drakosha_Spatial.sha256(backlogRaw)))
  Js.Dict.set(receipt, "preflight", Js.Json.string("PASS"))

  let attempt = createReleaseAttempt(paths)
  try {
    writeText(Path(attempt.screenplayTemporary), screenplay)
    Drakosha_OutputSafety.atomicRename(
      ~temporaryPath=attempt.screenplayTemporary,
      ~destinationPath=paths.screenplay,
    )
    writeText(
      Path(attempt.receiptTemporary),
      Js.Json.stringifyWithSpace(Js.Json.object_(receipt), 2) ++ "\n",
    )
    Drakosha_OutputSafety.atomicRename(
      ~temporaryPath=attempt.receiptTemporary,
      ~destinationPath=paths.receipt,
    )
    cleanupReleaseAttempt(attempt)
  } catch {
  | Drakosha_OutputSafety.OutputSafetyError(message) => {
      try {
        cleanupReleaseAttempt(attempt)
      } catch {
      | _ => ()
      }
      raise(Drakosha_OutputSafety.OutputSafetyError("release publication failed: " ++ message))
    }
  | Js.Exn.Error(error) => {
      try {
        cleanupReleaseAttempt(attempt)
      } catch {
      | _ => ()
      }
      raise(
        Drakosha_OutputSafety.OutputSafetyError(
          "release publication failed: " ++
          Js.Exn.message(error)->Belt.Option.getWithDefault("unknown error"),
        ),
      )
    }
  }
}

let main = () =>
  switch (Belt.Array.get(argv, 2), Belt.Array.get(argv, 3), Belt.Array.get(argv, 4)) {
  | (Some(registryArgument), Some(manifestArgument), Some(releaseArgument)) => {
      let registryPath = Drakosha_OutputSafety.absolutePath(registryArgument)
      let manifestPath = Drakosha_OutputSafety.absolutePath(manifestArgument)
      let paths = releasePaths(releaseArgument)
      let cleanupAllowed = ref(false)
      try {
        /* This check uses path metadata only.  It prevents invalidation from
         deleting either input named directly on the command line. */
        Drakosha_OutputSafety.assertNoCollisions(
          ~outputs=releaseOutputRows(paths),
          ~protectedPaths=[
            {Drakosha_OutputSafety.label: "registry input", path: registryPath},
            {Drakosha_OutputSafety.label: "manifest input", path: manifestPath},
          ],
        )
        /* Decode only the manifest before invalidation: its source/backlog
           paths must be known so a malicious or mistaken release destination
           cannot delete an indirect input.  A prior receipt remains unusable
           if this decode fails because verification re-decodes this manifest. */
        let manifestRaw = readText(Path(manifestPath))
        let manifest = manifestRaw->Drakosha_Spatial.decodeManifest
        let base = dirname(manifestPath)
        let screenplayPath = resolve2(base, manifest.source.path)
        let backlogPath = resolve2(base, manifest.backlog.path)

        /* Reject aliases before deleting anything. */
        Drakosha_OutputSafety.assertNoCollisions(
          ~outputs=releaseOutputRows(paths),
          ~protectedPaths=[
            {Drakosha_OutputSafety.label: "screenplay input", path: screenplayPath},
            {Drakosha_OutputSafety.label: "physical backlog input", path: backlogPath},
          ],
        )
        cleanupAllowed := true
        invalidateRelease(paths)

        let registryRaw = readText(Path(registryPath))
        let registry = registryRaw->Drakosha_Spatial.decodeRegistry
        let backlogRaw = readText(Path(backlogPath))
        Drakosha_Spatial.validateBacklogRaw(~manifest, ~raw=backlogRaw)
        let screenplay = readText(Path(screenplayPath))
        let evaluation = Drakosha_Spatial.evaluate(~registry, ~manifest, ~screenplay)
        let diagnostics = Drakosha_Diagnostics.build(
          ~base,
          ~protectedPaths=Belt.Array.concat(
            [
              {Drakosha_OutputSafety.label: "registry input", path: registryPath},
              {Drakosha_OutputSafety.label: "manifest input", path: manifestPath},
              {Drakosha_OutputSafety.label: "screenplay input", path: screenplayPath},
              {Drakosha_OutputSafety.label: "physical backlog input", path: backlogPath},
            ],
            releaseOutputRows(paths),
          ),
          ~registry,
          ~manifest,
          ~evaluation,
          ~registryRaw,
          ~manifestRaw,
          ~backlogRaw,
        )
        Drakosha_Diagnostics.publish(diagnostics)

        if Drakosha_Spatial.hasBlockers(evaluation) {
          invalidateRelease(paths)
          Js.log("RELEASE REFUSED — physical preflight has blocking findings")
          Js.log("No production-cleared screenplay or receipt exists.")
          exit(1)
        } else {
          publish(~paths, ~screenplay, ~registryRaw, ~manifestRaw, ~backlogRaw, ~evaluation)
          Js.log("PRODUCTION-CLEARED SCREENPLAY -> " ++ paths.screenplay)
          Js.log("RELEASE RECEIPT -> " ++ paths.receipt)
        }
      } catch {
      | Drakosha_OutputSafety.OutputSafetyError(message) => {
          if cleanupAllowed.contents {
            retryInvalidationAfterFailure(paths)
          }
          Js.log("RELEASE OUTPUT ERROR: " ++ message)
          exit(2)
        }
      | Drakosha_Spatial.SpatialError(message) => {
          if cleanupAllowed.contents {
            retryInvalidationAfterFailure(paths)
          }
          Js.log("RELEASE INPUT ERROR: " ++ message)
          exit(2)
        }
      | Js.Exn.Error(error) => {
          if cleanupAllowed.contents {
            retryInvalidationAfterFailure(paths)
          }
          Js.log(
            "RELEASE ERROR: " ++
            Js.Exn.message(error)->Belt.Option.getWithDefault("unknown JavaScript error"),
          )
          exit(2)
        }
      }
    }
  | _ => {
      Js.log(
        "usage: node src/Drakosha_Release.res.mjs <registry.json> <manifest.json> <cleared-screenplay.md>",
      )
      exit(2)
    }
  }

main()
