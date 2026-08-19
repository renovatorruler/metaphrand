module B = Cinema_Backends
module W = Production_WorkOrder
module Safety = Production_OutputSafety

exception ReferenceError(string)

@module("node:path") external dirname: string => string = "dirname"
@val @scope("process") external processPid: int = "pid"

let die = message => raise(ReferenceError(message))

let destination = (~stateDir, ~sha256) =>
  try {
    Safety.manifestOutputPath(
      ~baseDir=stateDir,
      ~relativePath="inputs/sha256/" ++ Js.String2.slice(sha256, ~from=0, ~to_=2) ++ "/" ++
        sha256 ++ ".blob",
      ~label="immutable reference snapshot " ++ sha256,
    )
  } catch {
  | Safety.OutputSafetyError(message) => die(message)
  }

let sourcePath = (~workOrder: W.workOrder, ~reference: W.reference) =>
  try {
    Safety.manifestOutputPath(
      ~baseDir=dirname(workOrder.packetPath),
      ~relativePath=reference.path,
      ~label="source reference " ++ reference.assetId,
    )
  } catch {
  | Safety.OutputSafetyError(message) => die(message)
  }

let verifyFile = (~path, ~sha256, ~label) => {
  if !B.exists(B.Path(path)) {
    die(label ++ " is missing")
  }
  if B.sha256File(B.Path(path)) != sha256 {
    die(label ++ " does not match its approved SHA-256")
  }
}

let snapshotOne = (~stateDir, ~workOrder: W.workOrder, ~reference: W.reference) => {
  let source = sourcePath(~workOrder, ~reference)
  verifyFile(~path=source, ~sha256=reference.sha256, ~label="source reference " ++ reference.assetId)
  let target = destination(~stateDir, ~sha256=reference.sha256)
  B.ensureDirPath(B.Path(dirname(target)))
  if B.exists(B.Path(target)) {
    verifyFile(
      ~path=target,
      ~sha256=reference.sha256,
      ~label="existing immutable reference " ++ reference.assetId,
    )
  } else {
    let claim = target ++ ".claim.json"
    let claimBody =
      "{\"schema\":\"production-reference-claim/v1\",\"sha256\":" ++
      Js.Json.stringify(Js.Json.string(reference.sha256)) ++ "}\n"
    if !B.writeTextExclusive(B.Path(claim), claimBody) {
      if !B.exists(B.Path(target)) {
        die("immutable reference claim is incomplete for " ++ reference.assetId)
      }
      verifyFile(
        ~path=target,
        ~sha256=reference.sha256,
        ~label="concurrently snapshotted reference " ++ reference.assetId,
      )
    } else {
      let temporary = target ++ "." ++ Belt.Int.toString(processPid) ++ ".pending"
      if B.exists(B.Path(temporary)) {
        die("immutable reference temporary path is already occupied")
      }
      B.copyFile(B.Path(source), B.Path(temporary))
      verifyFile(
        ~path=temporary,
        ~sha256=reference.sha256,
        ~label="copied immutable reference " ++ reference.assetId,
      )
      verifyFile(
        ~path=source,
        ~sha256=reference.sha256,
        ~label="source reference after copy " ++ reference.assetId,
      )
      if B.exists(B.Path(target)) {
        die("immutable reference destination was occupied during snapshot")
      }
      try Safety.atomicRename(~temporaryPath=temporary, ~destinationPath=target) catch {
      | Safety.OutputSafetyError(message) => die(message)
      | _ => die("could not commit immutable reference " ++ reference.assetId)
      }
      verifyFile(
        ~path=target,
        ~sha256=reference.sha256,
        ~label="committed immutable reference " ++ reference.assetId,
      )
    }
  }
  ({assetId: reference.assetId, path: target, sha256: reference.sha256}: W.reference)
}

let snapshot = (~stateDir, ~workOrder: W.workOrder) =>
  workOrder.references->Belt.Array.map(reference =>
    snapshotOne(~stateDir, ~workOrder, ~reference)
  )

let rehydrate = (~stateDir, ~workOrder: W.workOrder) =>
  workOrder.references->Belt.Array.map(reference => {
    let source = sourcePath(~workOrder, ~reference)
    verifyFile(
      ~path=source,
      ~sha256=reference.sha256,
      ~label="source reference " ++ reference.assetId,
    )
    let target = destination(~stateDir, ~sha256=reference.sha256)
    verifyFile(
      ~path=target,
      ~sha256=reference.sha256,
      ~label="committed immutable reference " ++ reference.assetId,
    )
    ({assetId: reference.assetId, path: target, sha256: reference.sha256}: W.reference)
  })

let verify = (~stateDir, ~references: array<W.reference>) =>
  references->Belt.Array.forEach(reference => {
    let expected = destination(~stateDir, ~sha256=reference.sha256)
    if reference.path != expected {
      die("provider reference path is not the canonical content-addressed snapshot")
    }
    verifyFile(
      ~path=reference.path,
      ~sha256=reference.sha256,
      ~label="immutable provider reference " ++ reference.assetId,
    )
  })
