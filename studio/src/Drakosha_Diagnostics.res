/* Atomic, hash-indexed publication for Drakosha preflight diagnostics.

   Report/proof files are replaced from invocation-owned neighbors, so an
   in-tree hard link is never truncated in place.  The index is renamed last
   and is the only commit marker for the set.  Old unindexed proofs may remain
   on disk, but they are never current. */

open Cinema_Backends

@module("node:fs") external mkdtempSync: string => string = "mkdtempSync"
@module("node:fs") external rmdirSync: string => unit = "rmdirSync"
@module("node:path") external dirname: string => string = "dirname"

type diagnosticFile = {
  relativePath: string,
  destinationPath: string,
  body: string,
}

type diagnosticSet = {
  reportPath: string,
  indexPath: string,
  contentFiles: array<diagnosticFile>,
  indexBody: string,
}

let build = (
  ~base: string,
  ~protectedPaths: array<Drakosha_OutputSafety.namedPath>,
  ~registry: Drakosha_Spatial.registry,
  ~manifest: Drakosha_Spatial.manifest,
  ~evaluation: Drakosha_Spatial.evaluation,
  ~registryRaw: string,
  ~manifestRaw: string,
  ~backlogRaw: string,
): diagnosticSet => {
  let registrySha256 = Drakosha_Spatial.sha256(registryRaw)
  let manifestSha256 = Drakosha_Spatial.sha256(manifestRaw)
  let backlogSha256 = Drakosha_Spatial.sha256(backlogRaw)
  let reportBody = Drakosha_Spatial.reportMarkdown(
    ~registry,
    ~manifest,
    ~evaluation,
    ~registrySha256,
    ~manifestSha256,
    ~backlogSha256,
  )
  let reportPath = Drakosha_OutputSafety.manifestOutputPath(
    ~baseDir=base,
    ~relativePath=manifest.output.reportPath,
    ~label="preflight report output",
  )
  let artifactFiles = evaluation.artifacts->Belt.Array.mapWithIndex((index, artifact) => {
    let label = "proof output #" ++ Belt.Int.toString(index + 1)
    {
      relativePath: artifact.relativePath,
      destinationPath: Drakosha_OutputSafety.manifestOutputPath(
        ~baseDir=base,
        ~relativePath=artifact.relativePath,
        ~label,
      ),
      body: "<!-- screenplay-sha256: " ++ evaluation.sourceSha256 ++ "; registry-sha256: " ++ registrySha256 ++ "; manifest-sha256: " ++ manifestSha256 ++ "; backlog-sha256: " ++ backlogSha256 ++ " -->\n" ++ artifact.body,
    }
  })
  let contentFiles = Belt.Array.concat(
    [{relativePath: manifest.output.reportPath, destinationPath: reportPath, body: reportBody}],
    artifactFiles,
  )
  let indexPath = Drakosha_OutputSafety.manifestOutputPath(
    ~baseDir=base,
    ~relativePath=manifest.output.indexPath,
    ~label="diagnostic-set index output",
  )
  let outputs = Belt.Array.concat(
    contentFiles->Belt.Array.mapWithIndex((index, file) => {
      Drakosha_OutputSafety.label: index == 0 ? "preflight report output" : "proof output #" ++ Belt.Int.toString(index),
      path: file.destinationPath,
    }),
    [{Drakosha_OutputSafety.label: "diagnostic-set index output", path: indexPath}],
  )
  Drakosha_OutputSafety.assertNoCollisions(~outputs, ~protectedPaths)

  let fileRows = contentFiles->Belt.Array.map(file => {
    let row = Js.Dict.empty()
    Js.Dict.set(row, "path", Js.Json.string(file.relativePath))
    Js.Dict.set(row, "sha256", Js.Json.string(Drakosha_Spatial.sha256(file.body)))
    Js.Json.object_(row)
  })
  let index = Js.Dict.empty()
  Js.Dict.set(index, "schema", Js.Json.string("drakosha.diagnostic-set/v1"))
  Js.Dict.set(index, "verdict", Js.Json.string(Drakosha_Spatial.hasBlockers(evaluation) ? "FAIL" : "PASS"))
  Js.Dict.set(index, "screenplaySha256", Js.Json.string(evaluation.sourceSha256))
  Js.Dict.set(index, "registrySha256", Js.Json.string(registrySha256))
  Js.Dict.set(index, "manifestSha256", Js.Json.string(manifestSha256))
  Js.Dict.set(index, "backlogSha256", Js.Json.string(backlogSha256))
  Js.Dict.set(index, "files", Js.Json.array(fileRows))
  {
    reportPath,
    indexPath,
    contentFiles,
    indexBody: Js.Json.stringifyWithSpace(Js.Json.object_(index), 2) ++ "\n",
  }
}

let cleanupAttempt = (~directory: string, ~temporaryPaths: array<string>): unit => {
  temporaryPaths->Belt.Array.forEach(path =>
    try {
      Drakosha_OutputSafety.removeFileEntry(path)
    } catch {
    | _ => ()
    }
  )
  try {
    rmdirSync(directory)
  } catch {
  | _ => ()
  }
}

let publish = (set: diagnosticSet): unit => {
  let base = dirname(set.indexPath)
  ensureDirPath(Path(base))
  let directory = mkdtempSync(base ++ "/.drakosha-diagnostics-")
  let orderedFiles = Belt.Array.concat(
    set.contentFiles,
    [{relativePath: "index", destinationPath: set.indexPath, body: set.indexBody}],
  )
  let temporaryPaths = orderedFiles->Belt.Array.mapWithIndex((index, _) =>
    directory ++ "/entry-" ++ Belt.Int.toString(index)
  )
  try {
    orderedFiles->Belt.Array.forEachWithIndex((index, file) => {
      let temporaryPath = temporaryPaths[index]
      writeText(Path(temporaryPath), file.body)
      ensureDirPath(Path(dirname(file.destinationPath)))
    })
    /* The index is last in orderedFiles, so it becomes visible only after the
       complete report/proof set has been installed. */
    orderedFiles->Belt.Array.forEachWithIndex((index, file) =>
      Drakosha_OutputSafety.atomicRename(
        ~temporaryPath=temporaryPaths[index],
        ~destinationPath=file.destinationPath,
      )
    )
    cleanupAttempt(~directory, ~temporaryPaths)
  } catch {
  | Drakosha_OutputSafety.OutputSafetyError(message) => {
      cleanupAttempt(~directory, ~temporaryPaths)
      raise(Drakosha_OutputSafety.OutputSafetyError("diagnostic publication failed: " ++ message))
    }
  | Js.Exn.Error(error) => {
      cleanupAttempt(~directory, ~temporaryPaths)
      raise(
        Drakosha_OutputSafety.OutputSafetyError(
          "diagnostic publication failed: " ++
          Js.Exn.message(error)->Belt.Option.getWithDefault("unknown error"),
        ),
      )
    }
  }
}

let verify = (set: diagnosticSet): unit => {
  let actualIndex = readText(Path(set.indexPath))
  if actualIndex != set.indexBody {
    raise(
      Drakosha_OutputSafety.OutputSafetyError(
        "diagnostic-set index is missing, stale, or does not match the current evaluator",
      ),
    )
  }
  set.contentFiles->Belt.Array.forEach(file => {
    let actual = readText(Path(file.destinationPath))
    if Drakosha_Spatial.sha256(actual) != Drakosha_Spatial.sha256(file.body) {
      raise(
        Drakosha_OutputSafety.OutputSafetyError(
          "diagnostic file hash mismatch: " ++ file.relativePath,
        ),
      )
    }
  })
}
