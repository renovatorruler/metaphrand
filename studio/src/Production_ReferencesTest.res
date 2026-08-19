/* Zero-network adversarial tests for immutable, content-addressed provider
   inputs. Every case uses a fresh synthetic packet and OS temporary root. */

module B = Cinema_Backends
module F = Production_TestFixtures
module R = Production_References
module W = Production_WorkOrder

@module("node:path") external dirname: string => string = "dirname"

let fail = message => {
  Js.Console.error("FAIL - " ++ message)
  assert(false)
}

let check = (condition, message) =>
  if !condition {
    fail(message)
  }

let requireOrder = evaluation =>
  switch evaluation.W.workOrder {
  | Some(order) => order
  | None => fail("synthetic fixture did not compile:\n" ++ W.explain(evaluation))
  }

let compiled = (fixture: F.fixture) =>
  requireOrder(W.compile(~packetPath=fixture.packetPath, ~targetId="T-SYNTHETIC"))

let expectedPath = (~stateDir, ~sha256) =>
  stateDir ++ "/inputs/sha256/" ++ Js.String2.slice(sha256, ~from=0, ~to_=2) ++ "/" ++
  sha256 ++ ".blob"

let expectReferenceError = (label, operation) => {
  let message = try {
    operation()
    None
  } catch {
  | R.ReferenceError(message) => Some(message)
  }
  switch message {
  | Some(message) => message
  | None => fail(label ++ ": expected Production_References.ReferenceError")
  }
}

let correctSnapshotAndRestart = () => {
  let fixture = F.create()
  let order = compiled(fixture)
  let first = R.snapshot(~stateDir=fixture.stateDir, ~workOrder=order)
  check(Belt.Array.length(first) == 2, "snapshot did not preserve both approved references")

  first->Belt.Array.forEachWithIndex((index, snapshot) => {
    let source = Belt.Array.getExn(order.references, index)
    let resolvedSource = if index == 0 {
      fixture.firstReferencePath
    } else {
      fixture.secondReferencePath
    }
    check(snapshot.assetId == source.assetId, "snapshot changed the reference asset identity")
    check(snapshot.sha256 == source.sha256, "snapshot changed the approved SHA-256")
    check(
      snapshot.path != source.path && snapshot.path != resolvedSource,
      "snapshot exposed the mutable source path",
    )
    check(
      snapshot.path == expectedPath(~stateDir=fixture.stateDir, ~sha256=snapshot.sha256),
      "snapshot path is not the canonical content-addressed destination",
    )
    check(B.exists(B.Path(snapshot.path)), "content-addressed snapshot is missing")
    check(
      B.sha256File(B.Path(snapshot.path)) == snapshot.sha256,
      "content-addressed snapshot bytes do not match the approved hash",
    )
  })
  R.verify(~stateDir=fixture.stateDir, ~references=first)

  /* A new caller after restart must converge on the exact same immutable
     objects rather than creating a second copy or changing identity. */
  let restartedOrder = compiled(fixture)
  let restarted = R.snapshot(~stateDir=fixture.stateDir, ~workOrder=restartedOrder)
  check(
    Belt.Array.length(restarted) == Belt.Array.length(first),
    "restart/re-snapshot changed the reference count",
  )
  restarted->Belt.Array.forEachWithIndex((index, reference) => {
    let original = Belt.Array.getExn(first, index)
    check(
      reference.assetId == original.assetId && reference.path == original.path &&
      reference.sha256 == original.sha256,
      "restart/re-snapshot did not return identical immutable references",
    )
  })
  R.verify(~stateDir=fixture.stateDir, ~references=restarted)
  let rehydrated = R.rehydrate(~stateDir=fixture.stateDir, ~workOrder=restartedOrder)
  rehydrated->Belt.Array.forEachWithIndex((index, reference) => {
    let original = Belt.Array.getExn(first, index)
    check(
      reference.assetId == original.assetId && reference.path == original.path &&
      reference.sha256 == original.sha256,
      "read-only restart rehydration changed immutable reference identity",
    )
  })
  Js.log("ok - canonical snapshots and deterministic restart/re-snapshot")
}

let rehydrateNeverCreatesMissingSnapshots = () => {
  let fixture = F.create()
  let order = compiled(fixture)
  let first = Belt.Array.getExn(order.references, 0)
  let destination = expectedPath(~stateDir=fixture.stateDir, ~sha256=first.sha256)
  check(!B.exists(B.Path(destination)), "fresh fixture unexpectedly has a reference snapshot")
  let error = expectReferenceError("read-only rehydration without snapshot", () =>
    R.rehydrate(~stateDir=fixture.stateDir, ~workOrder=order)->ignore
  )
  check(Js.String2.includes(error, "is missing"), "missing snapshot failed for an unrelated reason")
  check(!B.exists(B.Path(destination)), "read-only rehydration created missing snapshot authority")
  Js.log("ok - restart rehydration is read-only and fails on missing snapshots")
}

let sourceMutationCannotAlterSnapshot = () => {
  let fixture = F.create()
  let order = compiled(fixture)
  let references = R.snapshot(~stateDir=fixture.stateDir, ~workOrder=order)
  let subject = Belt.Array.getExn(references, 0)
  let immutableHashBefore = B.sha256File(B.Path(subject.path))

  B.writeText(B.Path(fixture.firstReferencePath), "mutated source after immutable snapshot\n")
  check(
    B.sha256File(B.Path(subject.path)) == immutableHashBefore && immutableHashBefore == subject.sha256,
    "source mutation altered the already committed immutable snapshot",
  )
  R.verify(~stateDir=fixture.stateDir, ~references)
  let error = expectReferenceError("re-snapshot after source drift", () =>
    R.snapshot(~stateDir=fixture.stateDir, ~workOrder=order)->ignore
  )
  check(
    Js.String2.includes(error, "source reference"),
    "source drift failed for an unrelated reason: " ++ error,
  )
  Js.log("ok - source mutation cannot alter or silently refresh an existing snapshot")
}

let corruptSnapshotIsRejected = () => {
  let fixture = F.create()
  let references = R.snapshot(~stateDir=fixture.stateDir, ~workOrder=compiled(fixture))
  let subject = Belt.Array.getExn(references, 0)
  B.writeText(B.Path(subject.path), "corrupt immutable snapshot\n")
  let error = expectReferenceError("corrupt snapshot verification", () =>
    R.verify(~stateDir=fixture.stateDir, ~references)
  )
  check(
    Js.String2.includes(error, "does not match its approved SHA-256"),
    "corrupt snapshot failed for an unrelated reason: " ++ error,
  )
  Js.log("ok - corrupt immutable snapshots fail closed")
}

let forgedAndNoncanonicalReferencesAreRejected = () => {
  let fixture = F.create()
  let order = compiled(fixture)
  let source = Belt.Array.getExn(order.references, 0)
  let canonical = R.snapshot(~stateDir=fixture.stateDir, ~workOrder=order)
  let snapshot = Belt.Array.getExn(canonical, 0)

  let forgedSourcePath: W.reference = {
    assetId: snapshot.assetId,
    path: fixture.firstReferencePath,
    sha256: snapshot.sha256,
  }
  let sourceError = expectReferenceError("mutable source-path forgery", () =>
    R.verify(~stateDir=fixture.stateDir, ~references=[forgedSourcePath])
  )
  check(
    Js.String2.includes(sourceError, "not the canonical content-addressed snapshot"),
    "source-path forgery failed for an unrelated reason: " ++ sourceError,
  )

  let aliasPath = fixture.stateDir ++ "/inputs/sha256/../sha256/" ++
    Js.String2.slice(snapshot.sha256, ~from=0, ~to_=2) ++ "/" ++ snapshot.sha256 ++ ".blob"
  let noncanonical: W.reference = {...source, path: aliasPath}
  let aliasError = expectReferenceError("noncanonical path alias", () =>
    R.verify(~stateDir=fixture.stateDir, ~references=[noncanonical])
  )
  check(
    Js.String2.includes(aliasError, "not the canonical content-addressed snapshot"),
    "noncanonical alias failed for an unrelated reason: " ++ aliasError,
  )
  Js.log("ok - forged and noncanonical reference paths fail closed")
}

let incompleteClaimFailsClosed = () => {
  let fixture = F.create()
  let order = compiled(fixture)
  let source = Belt.Array.getExn(order.references, 0)
  let target = expectedPath(~stateDir=fixture.stateDir, ~sha256=source.sha256)
  B.ensureDirPath(B.Path(dirname(target)))
  B.writeText(B.Path(target ++ ".claim.json"), "{\"synthetic\":\"incomplete claim\"}\n")
  check(!B.exists(B.Path(target)), "incomplete-claim fixture unexpectedly contains a destination")

  let error = expectReferenceError("incomplete snapshot claim", () =>
    R.snapshot(~stateDir=fixture.stateDir, ~workOrder=order)->ignore
  )
  check(
    Js.String2.includes(error, "claim is incomplete"),
    "incomplete claim failed for an unrelated reason: " ++ error,
  )
  check(!B.exists(B.Path(target)), "incomplete claim created or accepted a destination")
  Js.log("ok - incomplete immutable-reference claims fail closed")
}

let existingDestinationCollisionFailsClosed = () => {
  let fixture = F.create()
  let order = compiled(fixture)
  let source = Belt.Array.getExn(order.references, 0)
  let target = expectedPath(~stateDir=fixture.stateDir, ~sha256=source.sha256)
  B.ensureDirPath(B.Path(dirname(target)))
  B.writeText(B.Path(target), "hostile bytes occupying content-addressed destination\n")

  let error = expectReferenceError("existing destination collision", () =>
    R.snapshot(~stateDir=fixture.stateDir, ~workOrder=order)->ignore
  )
  check(
    Js.String2.includes(error, "does not match its approved SHA-256"),
    "destination collision failed for an unrelated reason: " ++ error,
  )
  check(
    B.readText(B.Path(target)) == "hostile bytes occupying content-addressed destination\n",
    "collision handling overwrote the occupied destination",
  )
  Js.log("ok - existing content-addressed destination collisions fail closed")
}

correctSnapshotAndRestart()
rehydrateNeverCreatesMissingSnapshots()
sourceMutationCannotAlterSnapshot()
corruptSnapshotIsRejected()
forgedAndNoncanonicalReferencesAreRejected()
incompleteClaimFailsClosed()
existingDestinationCollisionFailsClosed()
Js.log("PASS - immutable content-addressed reference snapshots")
