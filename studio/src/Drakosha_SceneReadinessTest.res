/* Zero-spend regression tests for the compact scene-readiness gate. */

open Cinema_Backends

let fail = message => {
  Js.log("FAIL - " ++ message)
  assert(false)
}

let expectCode = (label, code, evaluation) =>
  if !(evaluation.Drakosha_SceneReadiness.findings->Belt.Array.some(finding => finding.code == code)) {
    fail(label ++ ": expected finding " ++ code)
  }

let expectNoCode = (label, code, evaluation) =>
  if evaluation.Drakosha_SceneReadiness.findings->Belt.Array.some(finding => finding.code == code) {
    fail(label ++ ": unexpected finding " ++ code)
  }

let manifestPath = "../stories/drakosha/ep1prod/scene1/scene1.production.v1.json"

let productionStageFixture = () => {
  let manifest = readText(Path(manifestPath))->Drakosha_SceneReadiness.decodeManifest
  let references = Drakosha_SceneReadiness.evaluate(
    ~manifest,
    ~manifestPath,
    ~stage=Drakosha_SceneReadiness.ReferenceBoard,
  )
  if Drakosha_SceneReadiness.hasBlockers(references) {
    references.findings->Belt.Array.forEach(finding => Js.log(finding.code ++ ": " ++ finding.detail))
    fail("the current compact cut must be ready for reference-board development")
  }

  let storyboard = Drakosha_SceneReadiness.evaluate(
    ~manifest,
    ~manifestPath,
    ~stage=Drakosha_SceneReadiness.Storyboard,
  )
  expectCode("storyboard waits for its reference-board approval", "APPROVAL_PENDING", storyboard)
  expectCode("storyboard waits for missing foundation assets", "ASSET_REQUIRED_MISSING", storyboard)

  let motion = Drakosha_SceneReadiness.evaluate(
    ~manifest,
    ~manifestPath,
    ~stage=Drakosha_SceneReadiness.Motion,
  )
  expectCode("motion waits for approved references", "ASSET_NOT_APPROVED", motion)
  expectCode("motion waits for completed shots", "SHOT_NOT_READY", motion)
}

let structuralFailureFixture = () => {
  let manifest = readText(Path(manifestPath))->Drakosha_SceneReadiness.decodeManifest
  let firstShot = Belt.Array.getExn(manifest.shots, 0)
  let duplicated = {
    ...manifest,
    shots: Belt.Array.concat(manifest.shots, [{...firstShot, id: "C01"}, {...firstShot, id: "C11"}]),
  }
  let duplicateEvaluation = Drakosha_SceneReadiness.evaluate(
    ~manifest=duplicated,
    ~manifestPath,
    ~stage=Drakosha_SceneReadiness.ReferenceBoard,
  )
  expectCode("duplicate shot ids are rejected", "SHOT_ID_DUPLICATE", duplicateEvaluation)
  expectCode("edit-slot budget is enforced", "COMPLEXITY_SLOT_BUDGET", duplicateEvaluation)

  let unknownReference = {
    ...manifest,
    shots: manifest.shots->Belt.Array.mapWithIndex((index, shot) =>
      index == 0 ? {...shot, references: ["DOES_NOT_EXIST"]} : shot
    ),
  }
  let referenceEvaluation = Drakosha_SceneReadiness.evaluate(
    ~manifest=unknownReference,
    ~manifestPath,
    ~stage=Drakosha_SceneReadiness.ReferenceBoard,
  )
  expectCode("unknown shot references are rejected", "SHOT_REFERENCE_UNKNOWN", referenceEvaluation)

  let firstAsset = Belt.Array.getExn(manifest.assets, 0)
  let badHash = {
    ...manifest,
    assets: manifest.assets->Belt.Array.mapWithIndex((index, asset) =>
      index == 0 ? {...firstAsset, sha256: Some("bad-hash")} : asset
    ),
  }
  let hashEvaluation = Drakosha_SceneReadiness.evaluate(
    ~manifest=badHash,
    ~manifestPath,
    ~stage=Drakosha_SceneReadiness.ReferenceBoard,
  )
  expectCode("asset byte drift is rejected", "ASSET_HASH_MISMATCH", hashEvaluation)

  let motionShot = Belt.Array.getExn(manifest.shots, 1)
  let tooMuchMotion = {
    ...manifest,
    shots: manifest.shots->Belt.Array.mapWithIndex((index, shot) =>
      index == 2
        ? {
            ...motionShot,
            id: "C03",
            principalAction: Some("extra motion"),
            status: "references_ready_working",
          }
        : shot
    ),
  }
  let motionEvaluation = Drakosha_SceneReadiness.evaluate(
    ~manifest=tooMuchMotion,
    ~manifestPath,
    ~stage=Drakosha_SceneReadiness.ReferenceBoard,
  )
  expectCode("motion-clip budget is enforced", "COMPLEXITY_MOTION_BUDGET", motionEvaluation)
}

let guardedReceiptFixture = () => {
  let manifest = readText(Path(manifestPath))->Drakosha_SceneReadiness.decodeManifest
  let promoted = {
    ...manifest,
    assets: manifest.assets->Belt.Array.map(asset =>
      if asset.id == "DRAWER_SIDE_INTERIOR" {
        {
          ...asset,
          path: Some("stories/drakosha/ep1prod/scene1/references/drawer_side_interior_candidate_v1.png"),
          sha256: Some("5734831e0aa489e90c57f723df838609a3cad2e5f690ab1ebcd73a5439dc3b55"),
          status: "approved",
          provenance: "guarded_generation",
          receiptPath: Some("stories/drakosha/ep1prod/scene1/references/drawer_side_interior_candidate_v1.png.receipt.json"),
          receiptSha256: Some("4ea40ee2e4f437843181264b2393c89adfd09c42a226b2ee63f4cc38d840b6f0"),
          receiptSubjectId: Some("DRAWER_SIDE_INTERIOR"),
        }
      } else {
        asset
      }
    ),
  }
  let accepted = Drakosha_SceneReadiness.evaluate(
    ~manifest=promoted,
    ~manifestPath,
    ~stage=Drakosha_SceneReadiness.ReferenceBoard,
  )
  expectNoCode("matching guarded receipt is accepted", "ASSET_RECEIPT_REQUEST_MISMATCH", accepted)
  expectNoCode("matching guarded receipt binds provider args", "ASSET_RECEIPT_PROVIDER_ARGS_MISMATCH", accepted)
  expectNoCode("matching guarded receipt binds reference set", "ASSET_RECEIPT_REFERENCE_SET_MISMATCH", accepted)

  let drifted = {
    ...promoted,
    assets: promoted.assets->Belt.Array.map(asset =>
      if asset.id == "DRAWER_SIDE_INTERIOR" {
        switch asset.generationSpec {
        | Some(spec) => {...asset, generationSpec: Some({...spec, requestSha256: "wrong-request"})}
        | None => asset
        }
      } else {
        asset
      }
    ),
  }
  let driftedEvaluation = Drakosha_SceneReadiness.evaluate(
    ~manifest=drifted,
    ~manifestPath,
    ~stage=Drakosha_SceneReadiness.ReferenceBoard,
  )
  expectCode(
    "canonical request drift invalidates promotion",
    "ASSET_RECEIPT_REQUEST_MISMATCH",
    driftedEvaluation,
  )

  let emptyReferences = {
    ...promoted,
    assets: promoted.assets->Belt.Array.map(asset =>
      if asset.id == "DRAWER_SIDE_INTERIOR" {
        switch asset.generationSpec {
        | Some(spec) => {...asset, generationSpec: Some({...spec, referenceAssetIds: []})}
        | None => asset
        }
      } else {
        asset
      }
    ),
  }
  let emptyEvaluation = Drakosha_SceneReadiness.evaluate(
    ~manifest=emptyReferences,
    ~manifestPath,
    ~stage=Drakosha_SceneReadiness.ReferenceBoard,
  )
  expectCode(
    "empty canonical reference set is rejected",
    "ASSET_GENERATION_REFERENCES_EMPTY",
    emptyEvaluation,
  )
  expectCode(
    "receipt cannot choose its own empty reference set",
    "ASSET_RECEIPT_REFERENCE_SET_MISMATCH",
    emptyEvaluation,
  )
}

productionStageFixture()
structuralFailureFixture()
guardedReceiptFixture()
Js.log("PASS - scene readiness gate")
