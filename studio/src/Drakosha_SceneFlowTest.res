/* Zero-spend integration test of the only public Scene 1 generation boundary.
   A temporary canonical workspace and fake provider executable exercise the
   real readiness, lease, attempt-claim, receipt, and idempotency paths. */

open Cinema_Backends

@module("path") external resolvePath: string => string = "resolve"
@val @scope("process") external chdir: string => unit = "chdir"
@val @scope("process") external cwd: unit => string = "cwd"
@val @scope("process") external env: Js.Dict.t<string> = "env"

let fail = message => {
  Js.log("FAIL - " ++ message)
  assert(false)
}

let expectFlowError = (label, work) => {
  let blocked = try {
    work()
    false
  } catch {
  | Drakosha_SceneFlow.FlowError(_) => true
  }
  if !blocked {
    fail(label ++ ": expected FlowError")
  }
}

let providerCalls = logPath =>
  if exists(Path(logPath)) {
    readText(Path(logPath))
    ->Js.String2.split("\n")
    ->Belt.Array.keep(line => Js.String2.startsWith(line, "generate create"))
    ->Belt.Array.length
  } else {
    0
  }

let setupFixture = () => {
  let sourceRoot = resolvePath("..")
  let sourceManifest = sourceRoot ++ "/stories/drakosha/ep1prod/scene1/scene1.production.v1.json"
  let raw = readText(Path(sourceManifest))
  let decoded = Drakosha_SceneReadiness.decodeManifest(raw)
  let Path(root) = tempDir("drakosha-scene-flow-")
  let studioDir = root ++ "/studio"
  let sceneDir = root ++ "/stories/drakosha/ep1prod/scene1"
  let manifestPath = sceneDir ++ "/scene1.production.v1.json"
  ensureDirPath(Path(studioDir))
  writeText(Path(manifestPath), raw)
  copyFile(
    Path(sourceRoot ++ "/" ++ decoded.humanState),
    Path(root ++ "/" ++ decoded.humanState),
  )
  decoded.assets->Belt.Array.forEach(asset =>
    switch asset.path {
    | Some(relative) =>
      copyFile(Path(sourceRoot ++ "/" ++ relative), Path(root ++ "/" ++ relative))
    | None => ()
    }
  )

  let fakeMedia = root ++ "/fake-provider.png"
  writeText(Path(fakeMedia), Js.String2.repeat("x", 25000))
  let fakeLog = root ++ "/provider.log"
  let fakeBinDir = root ++ "/bin"
  let fakeProvider = fakeBinDir ++ "/higgsfield"
  ensureDirPath(Path(fakeBinDir))
  writeText(
    Path(fakeProvider),
    "#!/bin/sh\n" ++
    "printf '%s\\n' \"$*\" >> " ++ fakeLog ++ "\n" ++
    "if [ \"$1\" = \"account\" ]; then exit 0; fi\n" ++
    "printf '[{\"result_url\":\"file://" ++ fakeMedia ++ "\"}]\\n'\n",
  )
  let chmod = run(~cmd="chmod", ~args=["+x", fakeProvider])
  if chmod.code != 0 {
    fail("could not prepare fake provider: " ++ chmod.stderr)
  }
  (root, studioDir, sceneDir, manifestPath, raw, fakeBinDir, fakeLog)
}

let publicBoundaryFixture = () => {
  let (_, studioDir, sceneDir, manifestPath, readyRaw, fakeBinDir, fakeLog) = setupFixture()
  let originalCwd = cwd()
  let originalPath = Js.Dict.get(env, "PATH")->Belt.Option.getWithDefault("")
  Js.Dict.set(env, "PATH", fakeBinDir ++ ":" ++ originalPath)
  chdir(studioDir)
  let canonicalManifestPath = resolvePath(
    "../stories/drakosha/ep1prod/scene1/scene1.production.v1.json",
  )

  /* A blocking formal decision must stop before even account status. */
  let blockedRaw = Js.String2.replace(
    readyRaw,
    "\"compactCut\": \"approved\"",
    "\"compactCut\": \"pending\"",
  )
  writeText(Path(manifestPath), blockedRaw)
  expectFlowError("blocked readiness stops the public boundary", () =>
    Drakosha_SceneFlow.runStage(~manifestPath=canonicalManifestPath, ~stage="refs", ~go=true)
  )
  if exists(Path(fakeLog)) {
    fail("provider executable was touched before blocked readiness returned")
  }
  writeText(Path(manifestPath), readyRaw)

  /* A ready gate is insufficient when the actual request fingerprint drifts. */
  let driftedSpecRaw = Js.String2.replace(
    readyRaw,
    "aeb96ab6f3cbdf7ac22a2d070ac3e2662b3bb0403e0dae22bb41c8f90960b062",
    "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
  )
  writeText(Path(manifestPath), driftedSpecRaw)
  expectFlowError("request drift stops before paid submission", () =>
    Drakosha_SceneFlow.runStage(~manifestPath=canonicalManifestPath, ~stage="refs", ~go=true)
  )
  if providerCalls(fakeLog) != 0 {
    fail("generationSpec drift allowed a provider submission")
  }
  writeText(Path(manifestPath), readyRaw)

  /* An active lease blocks the generation call even with a ready manifest. */
  let drawerReceiptDir = sceneDir ++ "/generation-receipts/DRAWER_SIDE_INTERIOR"
  let activeLock = drawerReceiptDir ++ "/active.lock"
  writeText(Path(activeLock), "occupied\n")
  expectFlowError("active subject lease blocks concurrent work", () =>
    Drakosha_SceneFlow.runStage(~manifestPath=canonicalManifestPath, ~stage="refs", ~go=true)
  )
  if providerCalls(fakeLog) != 0 {
    fail("active lease allowed a paid provider submission")
  }
  removeFile(Path(activeLock))

  /* Two existing atomic claims exhaust the target before provider submission. */
  let attempt1 = drawerReceiptDir ++ "/attempt-1.json"
  let attempt2 = drawerReceiptDir ++ "/attempt-2.json"
  if !writeTextExclusive(Path(attempt1), "claimed\n") ||
    writeTextExclusive(Path(attempt1), "duplicate\n") {
    fail("exclusive attempt files are not atomic")
  }
  if !writeTextExclusive(Path(attempt2), "claimed\n") {
    fail("second exclusive attempt claim could not be created")
  }
  expectFlowError("two attempt claims enforce the ceiling", () =>
    Drakosha_SceneFlow.runStage(~manifestPath=canonicalManifestPath, ~stage="refs", ~go=true)
  )
  if providerCalls(fakeLog) != 0 {
    fail("exhausted attempt ceiling allowed a provider submission")
  }
  removeFile(Path(attempt1))
  removeFile(Path(attempt2))

  /* The real public flow now performs two fake jobs and commits receipts. */
  Drakosha_SceneFlow.runStage(~manifestPath=canonicalManifestPath, ~stage="refs", ~go=true)
  if providerCalls(fakeLog) != 2 {
    fail("ready refs stage must submit exactly the two missing targets")
  }
  let drawerOut = sceneDir ++ "/references/drawer_side_interior_candidate_v1.png"
  let carOut = sceneDir ++ "/references/red_hero_car_candidate_v1.png"
  [drawerOut, carOut]->Belt.Array.forEach(output => {
    if !exists(Path(output)) || !exists(Path(output ++ ".receipt.json")) {
      fail("public flow did not commit media and its adjacent receipt: " ++ output)
    }
  })

  /* Re-entry recognizes receipts and submits no duplicate job. */
  Drakosha_SceneFlow.runStage(~manifestPath=canonicalManifestPath, ~stage="refs", ~go=true)
  if providerCalls(fakeLog) != 2 {
    fail("verified receipts did not make the public flow idempotent")
  }

  chdir(originalCwd)
  Js.Dict.set(env, "PATH", originalPath)
}

publicBoundaryFixture()
Js.log("PASS - guarded Scene 1 generation flow")
