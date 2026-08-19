/* Deterministic, zero-spend readiness gate for one compact scene manifest.

   It protects the boundary between planning and paid/slow generation. A stage
   can proceed only when the current scene packet, complexity budget, asset
   hashes, approvals, shot references, and stage-specific requirements agree.

   Run through Drakosha_SceneReadinessCli from studio/; this module stays pure
   so regression tests and later production wrappers can reuse the same gate.

   Stages: reference_board | storyboard | motion | lipsync | delivery */

open Cinema_Backends

exception ReadinessError(string)

type stage = ReferenceBoard | Storyboard | Motion | Lipsync | Delivery
type severity = Blocking | Warning
type finding = {code: string, severity: severity, scope: string, detail: string}

type generationSpec = {
  stage: string,
  subjectId: string,
  model: string,
  styleKey: string,
  promptSha256: string,
  requestSha256: string,
  referenceAssetIds: array<string>,
  externalReferences: array<string>,
  providerArgs: array<string>,
  outputPath: string,
}

type asset = {
  id: string,
  path: option<string>,
  sha256: option<string>,
  status: string,
  provenance: string,
  receiptPath: option<string>,
  receiptSha256: option<string>,
  receiptSubjectId: option<string>,
  generationSpec: option<generationSpec>,
  role: string,
  requiredForStages: array<stage>,
}

type shot = {
  id: string,
  duration: float,
  method: string,
  references: array<string>,
  principalAction: option<string>,
  status: string,
}

type manifest = {
  schema: string,
  sceneId: string,
  revision: int,
  maxPaidAttemptsPerTarget: int,
  receiptSchema: string,
  workspaceRoot: string,
  humanState: string,
  storySpine: array<string>,
  approvals: Js.Dict.t<string>,
  assets: array<asset>,
  shots: array<shot>,
}

type metrics = {
  slots: int,
  motionClips: int,
  runtimeSec: float,
  hashedAssets: int,
}

type evaluation = {
  stage: stage,
  manifest: manifest,
  findings: array<finding>,
  passed: array<string>,
  metrics: metrics,
}

let stageName = stage =>
  switch stage {
  | ReferenceBoard => "reference_board"
  | Storyboard => "storyboard"
  | Motion => "motion"
  | Lipsync => "lipsync"
  | Delivery => "delivery"
  }

let decodeStage = value =>
  switch value {
  | "reference_board" => ReferenceBoard
  | "storyboard" => Storyboard
  | "motion" => Motion
  | "lipsync" => Lipsync
  | "delivery" => Delivery
  | other =>
    raise(
      ReadinessError(
        "unsupported stage '" ++ other ++
        "' (expected reference_board, storyboard, motion, lipsync, or delivery)",
      ),
    )
  }

let objOf = (json: Js.Json.t, where: string): Js.Dict.t<Js.Json.t> =>
  switch Js.Json.decodeObject(json) {
  | Some(value) => value
  | None => raise(ReadinessError(where ++ ": expected an object"))
  }

let arrOf = (json: Js.Json.t, where: string): array<Js.Json.t> =>
  switch Js.Json.decodeArray(json) {
  | Some(value) => value
  | None => raise(ReadinessError(where ++ ": expected an array"))
  }

let get = (object: Js.Dict.t<Js.Json.t>, key: string): option<Js.Json.t> =>
  Js.Dict.get(object, key)

let reqStr = (object, key, where): string =>
  switch get(object, key)->Belt.Option.flatMap(Js.Json.decodeString) {
  | Some(value) if Js.String2.trim(value) != "" => value
  | _ => raise(ReadinessError(where ++ ": missing nonempty string field '" ++ key ++ "'"))
  }

let optStr = (object, key): option<string> =>
  get(object, key)->Belt.Option.flatMap(Js.Json.decodeString)

let reqNum = (object, key, where): float =>
  switch get(object, key)->Belt.Option.flatMap(Js.Json.decodeNumber) {
  | Some(value) if Js.Float.isFinite(value) => value
  | _ => raise(ReadinessError(where ++ ": missing finite number field '" ++ key ++ "'"))
  }

let reqArray = (object, key, where): array<Js.Json.t> =>
  switch get(object, key) {
  | Some(value) => arrOf(value, where ++ "." ++ key)
  | None => raise(ReadinessError(where ++ ": missing array field '" ++ key ++ "'"))
  }

let stringsOf = (values: array<Js.Json.t>, where: string): array<string> =>
  values->Belt.Array.mapWithIndex((index, value) =>
    switch Js.Json.decodeString(value) {
    | Some(text) if Js.String2.trim(text) != "" => text
    | _ =>
      raise(
        ReadinessError(
          where ++ "[" ++ Belt.Int.toString(index) ++ "]: expected a nonempty string",
        ),
      )
    }
  )

let decodeApprovals = (json: Js.Json.t): Js.Dict.t<string> => {
  let source = objOf(json, "manifest.approvals")
  let decoded = Js.Dict.empty()
  Js.Dict.entries(source)->Belt.Array.forEach(((key, value)) =>
    switch Js.Json.decodeString(value) {
    | Some(status) if
        status == "approved" || status == "pending" || status == "rejected" ||
          status == "superseded" =>
      Js.Dict.set(decoded, key, status)
    | _ =>
      raise(
        ReadinessError(
          "manifest.approvals." ++ key ++
          ": expected approved, pending, rejected, or superseded",
        ),
      )
    }
  )
  decoded
}

let decodeManifest = (raw: string): manifest => {
  let root = try {
    Js.Json.parseExn(raw)->objOf("manifest")
  } catch {
  | Js.Exn.Error(error) =>
    raise(
      ReadinessError(
        "manifest JSON parse failed: " ++
        Js.Exn.message(error)->Belt.Option.getWithDefault("unknown JSON error"),
      ),
    )
  }
  let authority =
    switch get(root, "authority") {
    | Some(value) => objOf(value, "manifest.authority")
    | None => raise(ReadinessError("manifest: missing object field 'authority'"))
    }
  let revisionNumber = reqNum(root, "revision", "manifest")
  let revision = Belt.Float.toInt(revisionNumber)
  if revision <= 0 || Belt.Int.toFloat(revision) != revisionNumber {
    raise(ReadinessError("manifest.revision: expected a positive integer"))
  }
  let assets = reqArray(root, "assets", "manifest")->Belt.Array.mapWithIndex((index, row) => {
    let where = "manifest.assets[" ++ Belt.Int.toString(index) ++ "]"
    let object = objOf(row, where)
    let status = reqStr(object, "status", where)
    if !([
      "approved",
      "approved_reuse",
      "working_reference",
      "missing_blocker",
      "pending_external_reference",
    ]->Belt.Array.some(candidate => candidate == status)) {
      raise(ReadinessError(where ++ ": unsupported status '" ++ status ++ "'"))
    }
    let provenance = reqStr(object, "provenance", where)
    if !([
      "legacy_approved",
      "user_supplied",
      "guarded_generation",
      "planned_guarded_generation",
      "external_pending",
    ]->Belt.Array.some(candidate => candidate == provenance)) {
      raise(ReadinessError(where ++ ": unsupported provenance '" ++ provenance ++ "'"))
    }
    let requiredForStages =
      reqArray(object, "requiredForStages", where)
      ->stringsOf(where ++ ".requiredForStages")
      ->Belt.Array.map(decodeStage)
    let generationSpec = switch get(object, "generationSpec") {
    | None => None
    | Some(value) => {
        let spec = objOf(value, where ++ ".generationSpec")
        let stage = reqStr(spec, "stage", where ++ ".generationSpec")
        if !(stage == "refs" || stage == "storyboard" || stage == "motion") {
          raise(ReadinessError(where ++ ".generationSpec.stage: unsupported stage '" ++ stage ++ "'"))
        }
        Some({
          stage,
          subjectId: reqStr(spec, "subjectId", where ++ ".generationSpec"),
          model: reqStr(spec, "model", where ++ ".generationSpec"),
          styleKey: reqStr(spec, "styleKey", where ++ ".generationSpec"),
          promptSha256: reqStr(spec, "promptSha256", where ++ ".generationSpec"),
          requestSha256: reqStr(spec, "requestSha256", where ++ ".generationSpec"),
          referenceAssetIds: reqArray(spec, "referenceAssetIds", where ++ ".generationSpec")
            ->stringsOf(where ++ ".generationSpec.referenceAssetIds"),
          externalReferences: reqArray(spec, "externalReferences", where ++ ".generationSpec")
            ->stringsOf(where ++ ".generationSpec.externalReferences"),
          providerArgs: reqArray(spec, "providerArgs", where ++ ".generationSpec")
            ->stringsOf(where ++ ".generationSpec.providerArgs"),
          outputPath: reqStr(spec, "outputPath", where ++ ".generationSpec"),
        })
      }
    }
    {
      id: reqStr(object, "id", where),
      path: optStr(object, "path"),
      sha256: optStr(object, "sha256"),
      status,
      provenance,
      receiptPath: optStr(object, "receiptPath"),
      receiptSha256: optStr(object, "receiptSha256"),
      receiptSubjectId: optStr(object, "receiptSubjectId"),
      generationSpec,
      role: reqStr(object, "role", where),
      requiredForStages,
    }
  })
  let shots = reqArray(root, "shots", "manifest")->Belt.Array.mapWithIndex((index, row) => {
    let where = "manifest.shots[" ++ Belt.Int.toString(index) ++ "]"
    let object = objOf(row, where)
    let duration = reqNum(object, "workingDurationSec", where)
    if duration <= 0.0 {
      raise(ReadinessError(where ++ ".workingDurationSec: expected a positive number"))
    }
    {
      id: reqStr(object, "id", where),
      duration,
      method: reqStr(object, "method", where),
      references: reqArray(object, "references", where)->stringsOf(where ++ ".references"),
      principalAction: optStr(object, "principalAction"),
      status: reqStr(object, "status", where),
    }
  })
  let approvals =
    switch get(root, "approvals") {
    | Some(value) => decodeApprovals(value)
    | None => raise(ReadinessError("manifest: missing object field 'approvals'"))
    }
  let generationPolicy = switch get(root, "generationPolicy") {
  | Some(value) => objOf(value, "manifest.generationPolicy")
  | None => raise(ReadinessError("manifest: missing object field 'generationPolicy'"))
  }
  let maxAttemptsNumber = reqNum(
    generationPolicy,
    "maxPaidAttemptsPerTarget",
    "manifest.generationPolicy",
  )
  let maxPaidAttemptsPerTarget = Belt.Float.toInt(maxAttemptsNumber)
  if maxPaidAttemptsPerTarget != 2 || Belt.Int.toFloat(maxPaidAttemptsPerTarget) != maxAttemptsNumber {
    raise(ReadinessError("manifest.generationPolicy.maxPaidAttemptsPerTarget: expected exactly 2"))
  }
  let receiptSchema = reqStr(generationPolicy, "receiptSchema", "manifest.generationPolicy")
  if receiptSchema != "frosya.generation-receipt/v1" {
    raise(ReadinessError("manifest.generationPolicy.receiptSchema: unsupported schema '" ++ receiptSchema ++ "'"))
  }
  let manifest = {
    schema: reqStr(root, "schema", "manifest"),
    sceneId: reqStr(root, "sceneId", "manifest"),
    revision,
    maxPaidAttemptsPerTarget,
    receiptSchema,
    workspaceRoot: reqStr(root, "workspaceRoot", "manifest"),
    humanState: reqStr(authority, "humanState", "manifest.authority"),
    storySpine: reqArray(root, "storySpine", "manifest")->stringsOf("manifest.storySpine"),
    approvals,
    assets,
    shots,
  }
  if manifest.schema != "frosya.scene-production/v1" {
    raise(ReadinessError("manifest.schema: unsupported schema '" ++ manifest.schema ++ "'"))
  }
  if Belt.Array.length(manifest.storySpine) == 0 {
    raise(ReadinessError("manifest.storySpine: at least one story beat is required"))
  }
  manifest
}

let requiredApprovals = stage =>
  switch stage {
  | ReferenceBoard => ["compactCut"]
  | Storyboard => ["compactCut", "referenceBoard"]
  | Motion | Lipsync => ["compactCut", "referenceBoard", "storyboard", "animatic"]
  | Delivery => ["compactCut", "referenceBoard", "storyboard", "animatic", "finalAssembly"]
  }

let isMotionMethod = method =>
  method == "motion_clip" || method == "motion_clip_dialogue_over"

let stageRequiresApprovedAsset = stage =>
  switch stage {
  | Motion | Lipsync | Delivery => true
  | ReferenceBoard | Storyboard => false
  }

let stageNeedsShotReadiness = stage =>
  switch stage {
  | Motion | Lipsync | Delivery => true
  | ReferenceBoard | Storyboard => false
  }

let isShotBlocked = status =>
  Js.String2.startsWith(status, "blocked_") || Js.String2.startsWith(status, "missing_")

let evaluate = (~manifest: manifest, ~manifestPath: string, ~stage: stage): evaluation => {
  let findings: array<finding> = []
  let passed: array<string> = []
  let add = (code, severity, scope, detail) => {
    let _ = Js.Array2.push(findings, {code, severity, scope, detail})
  }
  let pass = detail => {
    let _ = Js.Array2.push(passed, detail)
  }
  let addBlocking = (code, scope, detail) => add(code, Blocking, scope, detail)
  let addWarning = (code, scope, detail) => add(code, Warning, scope, detail)

  let manifestDir =
    switch Cinema_Backends.run(~cmd="node", ~args=["-e", "process.stdout.write(require('path').dirname(process.argv[1]))", manifestPath]) {
    | {code: 0, stdout} => stdout
    | result => raise(ReadinessError("cannot resolve manifest directory: " ++ result.stderr))
    }
  let workspaceRoot =
    switch Cinema_Backends.run(~cmd="node", ~args=["-e", "process.stdout.write(require('path').resolve(process.argv[1],process.argv[2]))", manifestDir, manifest.workspaceRoot]) {
    | {code: 0, stdout} => stdout
    | result => raise(ReadinessError("cannot resolve workspace root: " ++ result.stderr))
    }
  let resolveWorkspace = relative =>
    switch Cinema_Backends.run(~cmd="node", ~args=["-e", "process.stdout.write(require('path').resolve(process.argv[1],process.argv[2]))", workspaceRoot, relative]) {
    | {code: 0, stdout} => stdout
    | result => raise(ReadinessError("cannot resolve workspace path: " ++ result.stderr))
    }

  let humanPath = resolveWorkspace(manifest.humanState)
  if !exists(Path(humanPath)) {
    addBlocking("STATE_FILE_MISSING", "authority", "current human state is missing: " ++ humanPath)
  } else {
    let humanRaw = readText(Path(humanPath))
    let expectedRevision = "**Revision:** " ++ Belt.Int.toString(manifest.revision)
    if !Js.String2.includes(humanRaw, expectedRevision) {
      addBlocking(
        "STATE_REVISION_MISMATCH",
        "authority",
        "human state does not declare " ++ expectedRevision,
      )
    } else {
      pass("human state revision matches manifest")
    }
    let manifestHash = sha256File(Path(manifestPath))
    let expectedManifestHash = "**Manifest SHA-256:** `" ++ manifestHash ++ "`"
    if !Js.String2.includes(humanRaw, expectedManifestHash) {
      addBlocking(
        "STATE_MANIFEST_HASH_MISMATCH",
        "authority",
        "human state does not bind the current manifest SHA-256 " ++ manifestHash,
      )
    } else {
      pass("human state binds exact manifest bytes")
    }
  }

  let assetIds = Js.Dict.empty()
  manifest.assets->Belt.Array.forEach(asset => {
    if Js.Dict.get(assetIds, asset.id) != None {
      addBlocking("ASSET_ID_DUPLICATE", asset.id, "asset id appears more than once")
    } else {
      Js.Dict.set(assetIds, asset.id, asset)
    }
    switch (asset.path, asset.sha256) {
    | (Some(relative), Some(expectedHash)) => {
        let absolute = resolveWorkspace(relative)
        if !exists(Path(absolute)) {
          addBlocking("ASSET_FILE_MISSING", asset.id, "declared file is missing: " ++ relative)
        } else {
          let actualHash = sha256File(Path(absolute))
          if actualHash != expectedHash {
            addBlocking(
              "ASSET_HASH_MISMATCH",
              asset.id,
              "expected " ++ expectedHash ++ " but found " ++ actualHash,
            )
          }
        }
      }
    | (Some(_), None) =>
      addBlocking("ASSET_HASH_MISSING", asset.id, "an asset path requires a SHA-256")
    | (None, Some(_)) =>
      addBlocking("ASSET_PATH_MISSING", asset.id, "an asset SHA-256 requires a path")
    | (None, None) => ()
    }
    switch (asset.receiptPath, asset.receiptSha256) {
    | (Some(_), None) =>
      addBlocking("ASSET_RECEIPT_HASH_MISSING", asset.id, "a receipt path requires a SHA-256")
    | (None, Some(_)) =>
      addBlocking("ASSET_RECEIPT_PATH_MISSING", asset.id, "a receipt SHA-256 requires a path")
    | _ => ()
    }
    if asset.path != None && asset.provenance == "planned_guarded_generation" {
      addBlocking(
        "ASSET_GENERATION_UNPROMOTED",
        asset.id,
        "a generated candidate must be promoted as guarded_generation with its receipt",
      )
    }
    if (asset.provenance == "planned_guarded_generation" || asset.provenance == "guarded_generation") &&
      asset.generationSpec == None {
      addBlocking(
        "ASSET_GENERATION_SPEC_REQUIRED",
        asset.id,
        "planned or promoted generated assets require a canonical generationSpec",
      )
    }
    if stage != ReferenceBoard &&
      (asset.id == "DRAWER_SIDE_INTERIOR" || asset.id == "RED_CAR") &&
      asset.status != "approved" && asset.status != "approved_reuse" {
      addBlocking(
        "FOUNDATION_ASSET_NOT_APPROVED",
        asset.id,
        "the drawer and car foundations require explicit approval before " ++ stageName(stage),
      )
    }
    if asset.requiredForStages->Belt.Array.some(required => required == stage) {
      switch asset.path {
      | None =>
        addBlocking(
          "ASSET_REQUIRED_MISSING",
          asset.id,
          asset.role ++ " is required for " ++ stageName(stage),
        )
      | Some(_) =>
        if stageRequiresApprovedAsset(stage) &&
          asset.status != "approved" && asset.status != "approved_reuse" {
          addBlocking(
            "ASSET_NOT_APPROVED",
            asset.id,
            "status '" ++ asset.status ++ "' cannot enter " ++ stageName(stage),
          )
        } else if asset.status == "working_reference" {
          addWarning(
            "ASSET_WORKING_REFERENCE",
            asset.id,
            "working reference is allowed for " ++ stageName(stage) ++ " but is not production-locked",
          )
        }
      }
    }
  })

  manifest.assets->Belt.Array.forEach(asset =>
    switch asset.generationSpec {
    | None => ()
    | Some(spec) => {
        if spec.subjectId != asset.id {
          addBlocking(
            "ASSET_GENERATION_SUBJECT_MISMATCH",
            asset.id,
            "generationSpec.subjectId must equal the asset id",
          )
        }
        if Belt.Array.length(spec.referenceAssetIds) == 0 {
          addBlocking(
            "ASSET_GENERATION_REFERENCES_EMPTY",
            asset.id,
            "generationSpec must bind at least one canonical reference asset",
          )
        }
        spec.referenceAssetIds->Belt.Array.forEach(referenceId =>
          switch Js.Dict.get(assetIds, referenceId) {
          | None =>
            addBlocking(
              "ASSET_GENERATION_REFERENCE_UNKNOWN",
              asset.id,
              "generationSpec references unknown asset '" ++ referenceId ++ "'",
            )
          | Some(reference) if reference.path == None || reference.sha256 == None =>
            addBlocking(
              "ASSET_GENERATION_REFERENCE_UNHASHED",
              asset.id,
              "generationSpec reference '" ++ referenceId ++ "' requires a hashed file",
            )
          | Some(_) => ()
          }
        )
        if asset.provenance == "guarded_generation" && asset.path != Some(spec.outputPath) {
          addBlocking(
            "ASSET_GENERATION_OUTPUT_MISMATCH",
            asset.id,
            "promoted output path must equal generationSpec.outputPath",
          )
        }
      }
    }
  )

  manifest.assets->Belt.Array.forEach(asset =>
    if asset.provenance == "guarded_generation" {
      switch (asset.path, asset.sha256, asset.receiptPath, asset.receiptSha256) {
      | (Some(outputRelative), Some(outputHash), Some(receiptRelative), Some(receiptHash)) => {
          let receiptAbsolute = resolveWorkspace(receiptRelative)
          if !exists(Path(receiptAbsolute)) {
            addBlocking(
              "ASSET_RECEIPT_FILE_MISSING",
              asset.id,
              "declared generation receipt is missing: " ++ receiptRelative,
            )
          } else if sha256File(Path(receiptAbsolute)) != receiptHash {
            addBlocking(
              "ASSET_RECEIPT_HASH_MISMATCH",
              asset.id,
              "generation receipt bytes do not match the manifest",
            )
          } else {
            let parsed = try {
              Some(Js.Json.parseExn(readText(Path(receiptAbsolute)))->objOf("receipt"))
            } catch {
            | _ => None
            }
            switch parsed {
            | None =>
              addBlocking(
                "ASSET_RECEIPT_INVALID",
                asset.id,
                "generation receipt is not valid JSON object data",
              )
            | Some(receipt) => {
                let verify = (key, expected, code) =>
                  switch get(receipt, key)->Belt.Option.flatMap(Js.Json.decodeString) {
                  | Some(actual) if actual == expected => ()
                  | Some(actual) =>
                    addBlocking(code, asset.id, key ++ " expected '" ++ expected ++ "' but found '" ++ actual ++ "'")
                  | None => addBlocking(code, asset.id, "receipt is missing string field '" ++ key ++ "'")
                  }
                verify("schema", manifest.receiptSchema, "ASSET_RECEIPT_SCHEMA_MISMATCH")
                verify("sceneId", manifest.sceneId, "ASSET_RECEIPT_SCENE_MISMATCH")
                verify("status", "succeeded", "ASSET_RECEIPT_STATUS_INVALID")
                verify("readiness", "PASS", "ASSET_RECEIPT_READINESS_INVALID")
                verify("outputPath", outputRelative, "ASSET_RECEIPT_OUTPUT_PATH_MISMATCH")
                verify("outputSha256", outputHash, "ASSET_RECEIPT_OUTPUT_HASH_MISMATCH")
                ["inputManifestSha256"]
                ->Belt.Array.forEach(key =>
                  switch get(receipt, key)->Belt.Option.flatMap(Js.Json.decodeString) {
                  | Some(value) if Js.String2.trim(value) != "" => ()
                  | _ =>
                    addBlocking(
                      "ASSET_RECEIPT_FIELD_MISSING",
                      asset.id,
                      "receipt is missing nonempty string field '" ++ key ++ "'",
                    )
                  }
                )
                let verifyArray = (key, expected: array<string>, code) =>
                  switch get(receipt, key)->Belt.Option.flatMap(Js.Json.decodeArray) {
                  | None => addBlocking(code, asset.id, "receipt is missing array field '" ++ key ++ "'")
                  | Some(values) => {
                      let actual = values->Belt.Array.keepMap(Js.Json.decodeString)
                      if Belt.Array.length(actual) != Belt.Array.length(values) ||
                        Js.Array2.joinWith(actual, "\u{1f}") != Js.Array2.joinWith(expected, "\u{1f}") {
                        addBlocking(code, asset.id, key ++ " does not match the canonical generationSpec")
                      }
                    }
                  }
                switch asset.generationSpec {
                | None => ()
                | Some(spec) => {
                    verify("subjectId", spec.subjectId, "ASSET_RECEIPT_SUBJECT_MISMATCH")
                    verify("stage", spec.stage, "ASSET_RECEIPT_STAGE_MISMATCH")
                    verify("model", spec.model, "ASSET_RECEIPT_MODEL_MISMATCH")
                    verify("styleKey", spec.styleKey, "ASSET_RECEIPT_STYLE_MISMATCH")
                    verify("promptSha256", spec.promptSha256, "ASSET_RECEIPT_PROMPT_MISMATCH")
                    verify("requestSha256", spec.requestSha256, "ASSET_RECEIPT_REQUEST_MISMATCH")
                    verify("outputPath", spec.outputPath, "ASSET_RECEIPT_SPEC_OUTPUT_MISMATCH")
                    verifyArray(
                      "externalReferences",
                      spec.externalReferences,
                      "ASSET_RECEIPT_EXTERNAL_REFERENCES_MISMATCH",
                    )
                    verifyArray(
                      "providerArgs",
                      spec.providerArgs,
                      "ASSET_RECEIPT_PROVIDER_ARGS_MISMATCH",
                    )
                  }
                }
                switch get(receipt, "inputManifestRevision")->Belt.Option.flatMap(Js.Json.decodeNumber) {
                | Some(value) if
                    value > 0.0 && value <= Belt.Int.toFloat(manifest.revision) &&
                      Belt.Int.toFloat(Belt.Float.toInt(value)) == value => ()
                | _ =>
                  addBlocking(
                    "ASSET_RECEIPT_REVISION_INVALID",
                    asset.id,
                    "receipt revision must be positive and no newer than the current manifest",
                  )
                }
                switch get(receipt, "attempt")->Belt.Option.flatMap(Js.Json.decodeNumber) {
                | Some(value) if
                    value >= 1.0 && value <= Belt.Int.toFloat(manifest.maxPaidAttemptsPerTarget) &&
                      Belt.Int.toFloat(Belt.Float.toInt(value)) == value => ()
                | _ =>
                  addBlocking(
                    "ASSET_RECEIPT_ATTEMPT_INVALID",
                    asset.id,
                    "receipt attempt must be an integer within the canonical paid-attempt ceiling",
                  )
                }
                switch get(receipt, "referenceAssets")->Belt.Option.flatMap(Js.Json.decodeArray) {
                | None =>
                  addBlocking(
                    "ASSET_RECEIPT_REFERENCES_MISSING",
                    asset.id,
                    "receipt must declare its reference asset hashes",
                  )
                | Some(rows) => {
                  switch asset.generationSpec {
                  | Some(spec) => {
                      if Belt.Array.length(rows) != Belt.Array.length(spec.referenceAssetIds) {
                        addBlocking(
                          "ASSET_RECEIPT_REFERENCE_SET_MISMATCH",
                          asset.id,
                          "receipt reference count does not match generationSpec",
                        )
                      }
                      spec.referenceAssetIds->Belt.Array.forEach(expectedId =>
                        if !(rows->Belt.Array.some(row =>
                          row
                          ->Js.Json.decodeObject
                          ->Belt.Option.flatMap(reference =>
                            get(reference, "assetId")->Belt.Option.flatMap(Js.Json.decodeString)
                          ) == Some(expectedId)
                        )) {
                          addBlocking(
                            "ASSET_RECEIPT_REFERENCE_SET_MISMATCH",
                            asset.id,
                            "receipt is missing canonical reference '" ++ expectedId ++ "'",
                          )
                        }
                      )
                    }
                  | None => ()
                  }
                  rows->Belt.Array.forEachWithIndex((index, row) => {
                    let where = "receipt.referenceAssets[" ++ Belt.Int.toString(index) ++ "]"
                    switch Js.Json.decodeObject(row) {
                    | None =>
                      addBlocking("ASSET_RECEIPT_REFERENCE_INVALID", asset.id, where ++ " is not an object")
                    | Some(reference) =>
                      switch (
                        get(reference, "assetId")->Belt.Option.flatMap(Js.Json.decodeString),
                        get(reference, "sha256")->Belt.Option.flatMap(Js.Json.decodeString),
                      ) {
                      | (Some(referenceId), Some(referenceHash)) =>
                        switch Js.Dict.get(assetIds, referenceId) {
                        | Some(current) if current.sha256 == Some(referenceHash) => ()
                        | Some(_) =>
                          addBlocking(
                            "ASSET_RECEIPT_REFERENCE_DRIFT",
                            asset.id,
                            "reference '" ++ referenceId ++ "' no longer has the captured hash",
                          )
                        | None =>
                          addBlocking(
                            "ASSET_RECEIPT_REFERENCE_UNKNOWN",
                            asset.id,
                            "receipt references unknown asset '" ++ referenceId ++ "'",
                          )
                        }
                      | _ =>
                        addBlocking(
                          "ASSET_RECEIPT_REFERENCE_INVALID",
                          asset.id,
                          where ++ " requires assetId and sha256",
                        )
                      }
                    }
                  })
                  }
                }
              }
            }
          }
        }
      | _ =>
        addBlocking(
          "ASSET_GENERATION_RECEIPT_REQUIRED",
          asset.id,
          "guarded_generation requires output path/hash and receipt path/hash",
        )
      }
    }
  )

  let shotIds = Js.Dict.empty()
  manifest.shots->Belt.Array.forEach(shot => {
    if Js.Dict.get(shotIds, shot.id) != None {
      addBlocking("SHOT_ID_DUPLICATE", shot.id, "shot id appears more than once")
    } else {
      Js.Dict.set(shotIds, shot.id, true)
    }
    shot.references->Belt.Array.forEach(reference =>
      if Js.Dict.get(assetIds, reference) == None {
        addBlocking(
          "SHOT_REFERENCE_UNKNOWN",
          shot.id,
          "references unknown asset '" ++ reference ++ "'",
        )
      }
    )
    if isMotionMethod(shot.method) && shot.principalAction == None {
      addBlocking(
        "MOTION_ACTION_MISSING",
        shot.id,
        "motion clip must declare exactly one principalAction",
      )
    }
    if stageNeedsShotReadiness(stage) && isShotBlocked(shot.status) {
      addBlocking(
        "SHOT_NOT_READY",
        shot.id,
        "status '" ++ shot.status ++ "' cannot enter " ++ stageName(stage),
      )
    }
    if stage == Delivery && shot.status != "final_ready" {
      addBlocking(
        "SHOT_NOT_FINAL",
        shot.id,
        "delivery requires status 'final_ready', found '" ++ shot.status ++ "'",
      )
    }
  })

  requiredApprovals(stage)->Belt.Array.forEach(name =>
    switch Js.Dict.get(manifest.approvals, name) {
    | Some("approved") => ()
    | Some(status) =>
      addBlocking(
        "APPROVAL_PENDING",
        name,
        "approval is '" ++ status ++ "' but " ++ stageName(stage) ++ " requires approved",
      )
    | None => addBlocking("APPROVAL_MISSING", name, "required approval is not declared")
    }
  )

  let slots = Belt.Array.length(manifest.shots)
  let motionClips = manifest.shots->Belt.Array.keep(shot => isMotionMethod(shot.method))->Belt.Array.length
  let runtimeSec = manifest.shots->Belt.Array.reduce(0.0, (total, shot) => total +. shot.duration)
  let hashedAssets = manifest.assets->Belt.Array.keep(asset => asset.path != None && asset.sha256 != None)->Belt.Array.length
  if slots > 11 {
    addBlocking(
      "COMPLEXITY_SLOT_BUDGET",
      "scene",
      Belt.Int.toString(slots) ++ " edit slots exceed the budget of 11",
    )
  } else {
    pass("edit-slot budget " ++ Belt.Int.toString(slots) ++ "/11")
  }
  if motionClips > 2 {
    addBlocking(
      "COMPLEXITY_MOTION_BUDGET",
      "scene",
      Belt.Int.toString(motionClips) ++ " motion clips exceed the budget of 2",
    )
  } else {
    pass("motion-clip budget " ++ Belt.Int.toString(motionClips) ++ "/2")
  }
  if runtimeSec > 55.0 {
    addBlocking(
      "COMPLEXITY_RUNTIME_BUDGET",
      "scene",
      Js.Float.toString(runtimeSec) ++ " seconds exceed the working budget of 55 seconds",
    )
  } else {
    pass("working runtime " ++ Js.Float.toString(runtimeSec) ++ "/55 seconds")
  }

  {stage, manifest, findings, passed, metrics: {slots, motionClips, runtimeSec, hashedAssets}}
}

let blockers = evaluation =>
  evaluation.findings->Belt.Array.keep(finding => finding.severity == Blocking)

let hasBlockers = evaluation => Belt.Array.length(blockers(evaluation)) > 0

let printCard = evaluation => {
  Js.log("SCENE READINESS — " ++ Js.String2.toUpperCase(stageName(evaluation.stage)))
  Js.log(
    "scene=" ++ evaluation.manifest.sceneId ++
    " revision=" ++ Belt.Int.toString(evaluation.manifest.revision),
  )
  Js.log(
    "slots=" ++ Belt.Int.toString(evaluation.metrics.slots) ++
    "/11 motion=" ++ Belt.Int.toString(evaluation.metrics.motionClips) ++
    "/2 runtime=" ++ Js.Float.toString(evaluation.metrics.runtimeSec) ++
    "/55s hashed-assets=" ++ Belt.Int.toString(evaluation.metrics.hashedAssets),
  )
  evaluation.passed->Belt.Array.forEach(message => Js.log("  ok    " ++ message))
  evaluation.findings->Belt.Array.forEach(finding =>
    switch finding.severity {
    | Blocking => Js.log("  BLOCK " ++ finding.code ++ " [" ++ finding.scope ++ "]: " ++ finding.detail)
    | Warning => Js.log("  WARN  " ++ finding.code ++ " [" ++ finding.scope ++ "]: " ++ finding.detail)
    }
  )
  if hasBlockers(evaluation) {
    Js.log("RESULT: BLOCKED")
  } else {
    Js.log("RESULT: READY FOR " ++ Js.String2.toUpperCase(stageName(evaluation.stage)))
  }
}
