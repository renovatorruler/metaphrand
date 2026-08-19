/* ============================================================================
   Drakosha_SceneFlow — the Kuku-style generation flow for «Фрося и Вася»
   Scene 1, as a gated ReScript CLI (the Python draft of 2026-08-05 is dead;
   CLAUDE.md governing law).

   Usage (from studio/):
     node src/Drakosha_SceneFlow.res.mjs <scene1.production.v1.json> <stage> [--go]
   Stages: refs | storyboard | motion

   Discipline (enforced by Drakosha_SceneReadiness itself):
   - the canonical manifest is the single input and the formal readiness gate is
     rerun immediately before every Higgsfield call;
   - every attempt writes a provenance receipt tied to the manifest, prompt,
     references, model, output bytes, and attempt number;
   - without --go nothing is spent: the run prints its plan and exits 1;
   - unreceipted outputs are rejected; each subject has at most two attempts.

   External processes (higgsfield CLI, curl) go through Cinema_Backends.run —
   the one sanctioned spawn point. No shell, no quoting.
   ============================================================================ */

module B = Cinema_Backends

/* ---- tiny JSON helpers ---------------------------------------------------- */

let jObj = (j: Js.Json.t): option<Js.Dict.t<Js.Json.t>> => Js.Json.decodeObject(j)
let jStr = (j: Js.Json.t): option<string> => Js.Json.decodeString(j)
let jArr = (j: Js.Json.t): option<array<Js.Json.t>> => Js.Json.decodeArray(j)
let field = (o: Js.Dict.t<Js.Json.t>, k: string): option<Js.Json.t> => Js.Dict.get(o, k)
let strField = (o, k) => field(o, k)->Belt.Option.flatMap(jStr)
let numField = (o, k) => field(o, k)->Belt.Option.flatMap(Js.Json.decodeNumber)

exception FlowError(string)

let die = (msg: string) => raise(FlowError(msg))

/* ---- manifest ------------------------------------------------------------- */

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
  generationSpec: option<generationSpec>,
}
type manifest = {
  path: string,
  dir: string, /* directory containing the manifest */
  root: string, /* workspaceRoot resolved to an absolute path */
  raw: string,
  sceneId: string,
  revision: int,
  maxPaidAttemptsPerTarget: int,
  approvals: Js.Dict.t<string>,
  assets: array<asset>,
}

@module("path") external dirname: string => string = "dirname"
@module("path") external join2: (string, string) => string = "join"
@module("path") external resolvePath: string => string = "resolve"
@module("path") external relativePath: (string, string) => string = "relative"

let canonicalManifestPath = (): string =>
  resolvePath("../stories/drakosha/ep1prod/scene1/scene1.production.v1.json")

let stringArrayField = (object, key): option<array<string>> =>
  field(object, key)
  ->Belt.Option.flatMap(jArr)
  ->Belt.Option.map(values => values->Belt.Array.keepMap(jStr))

let parseGenerationSpec = (object: Js.Dict.t<Js.Json.t>): option<generationSpec> =>
  field(object, "generationSpec")->Belt.Option.flatMap(jObj)->Belt.Option.map(spec => {
    let required = (key: string): string =>
      switch strField(spec, key) {
      | Some(value) => value
      | None => die("generationSpec is missing '" ++ key ++ "'")
      }
    let requiredArray = (key: string): array<string> =>
      switch stringArrayField(spec, key) {
      | Some(values) => values
      | None => die("generationSpec is missing array '" ++ key ++ "'")
      }
    {
      stage: required("stage"),
      subjectId: required("subjectId"),
      model: required("model"),
      styleKey: required("styleKey"),
      promptSha256: required("promptSha256"),
      requestSha256: required("requestSha256"),
      referenceAssetIds: requiredArray("referenceAssetIds"),
      externalReferences: requiredArray("externalReferences"),
      providerArgs: requiredArray("providerArgs"),
      outputPath: required("outputPath"),
    }
  })

let readinessStage = stage =>
  switch stage {
  | "refs" => Drakosha_SceneReadiness.ReferenceBoard
  | "storyboard" => Drakosha_SceneReadiness.Storyboard
  | "motion" => Drakosha_SceneReadiness.Motion
  | other => die(`unknown stage '${other}' (refs | storyboard | motion)`)
  }

let requireFormalReadiness = (manifestPath: string, stage: string): string => {
  let absolute = resolvePath(manifestPath)
  if absolute != canonicalManifestPath() {
    die("Scene 1 generation accepts only the canonical manifest: " ++ canonicalManifestPath())
  }
  let raw = B.readText(B.Path(absolute))
  let decoded = try {
    Drakosha_SceneReadiness.decodeManifest(raw)
  } catch {
  | Drakosha_SceneReadiness.ReadinessError(message) =>
    die("formal readiness input error: " ++ message)
  }
  if decoded.sceneId != "EP1-S01" {
    die("generation runner is pinned to EP1-S01, found " ++ decoded.sceneId)
  }
  let evaluation = Drakosha_SceneReadiness.evaluate(
    ~manifest=decoded,
    ~manifestPath=absolute,
    ~stage=readinessStage(stage),
  )
  if Drakosha_SceneReadiness.hasBlockers(evaluation) {
    Drakosha_SceneReadiness.printCard(evaluation)
    die("formal readiness gate returned BLOCKED")
  }
  raw
}

let loadManifestRaw = (manifestPath: string, raw: string): manifest => {
  if !B.exists(B.Path(manifestPath)) {
    die("manifest not found: " ++ manifestPath)
  }
  let json = try Js.Json.parseExn(raw) catch {
  | _ => die("manifest is not valid JSON: " ++ manifestPath)
  }
  let o = switch jObj(json) {
  | Some(o) => o
  | None => die("manifest is not an object")
  }
  let dir = dirname(resolvePath(manifestPath))
  let sceneId = switch strField(o, "sceneId") {
  | Some(value) => value
  | None => die("manifest has no sceneId")
  }
  let revision = switch numField(o, "revision") {
  | Some(value) => Belt.Float.toInt(value)
  | None => die("manifest has no numeric revision")
  }
  let generationPolicy = switch field(o, "generationPolicy")->Belt.Option.flatMap(jObj) {
  | Some(value) => value
  | None => die("manifest has no generationPolicy object")
  }
  let maxPaidAttemptsPerTarget = switch numField(generationPolicy, "maxPaidAttemptsPerTarget") {
  | Some(value) => Belt.Float.toInt(value)
  | None => die("generationPolicy.maxPaidAttemptsPerTarget is missing")
  }
  if maxPaidAttemptsPerTarget != 2 {
    die("generationPolicy.maxPaidAttemptsPerTarget must be exactly 2")
  }
  let rootRel = switch strField(o, "workspaceRoot") {
  | Some(r) => r
  | None => die("manifest has no workspaceRoot")
  }
  let approvals = switch field(o, "approvals")->Belt.Option.flatMap(jObj) {
  | Some(ap) => {
      let out = Js.Dict.empty()
      ap
      ->Js.Dict.entries
      ->Belt.Array.forEach(((k, v)) =>
        switch jStr(v) {
        | Some(s) => Js.Dict.set(out, k, s)
        | None => ()
        }
      )
      out
    }
  | None => die("manifest has no approvals object")
  }
  let assets = switch field(o, "assets")->Belt.Option.flatMap(jArr) {
  | Some(items) =>
    items->Belt.Array.keepMap(item =>
      jObj(item)->Belt.Option.flatMap(io =>
        switch strField(io, "id") {
        | Some(id) => Some({
            id,
            path: strField(io, "path"),
            sha256: strField(io, "sha256"),
            generationSpec: parseGenerationSpec(io),
          })
        | None => None
        }
      )
    )
  | None => die("manifest has no assets array")
  }
  {
    path: resolvePath(manifestPath),
    dir,
    root: resolvePath(join2(dir, rootRel)),
    raw,
    sceneId,
    revision,
    maxPaidAttemptsPerTarget,
    approvals,
    assets,
  }
}

let requireApproval = (m: manifest, key: string): unit =>
  switch Js.Dict.get(m.approvals, key) {
  | Some("approved") => ()
  | Some(other) =>
    die(`approvals.${key} is '${other}', not 'approved'. BLOCKED is a stop condition, not a suggestion (CURRENT.md).`)
  | None => die(`approvals.${key} is not declared in the manifest.`)
  }

let assetPath = (m: manifest, id: string): string => {
  switch m.assets->Belt.Array.getBy(a => a.id == id) {
  | None => die(`asset id ${id} not declared in the manifest`)
  | Some(a) => {
      let relative = switch a.path {
      | Some(value) => value
      | None => die(`asset id ${id} has no approved path in the manifest`)
      }
      let p = resolvePath(join2(m.root, relative))
      if !B.exists(B.Path(p)) {
        die(`declared asset ${id} missing on disk: ${p}`)
      }
      switch a.sha256 {
      | Some(want) => {
          let got = B.sha256File(B.Path(p))
          if got != want {
            die(
              `asset ${id} bytes changed (sha256 ${Js.String2.slice(got, ~from=0, ~to_=12)}… != declared ${Js.String2.slice(want, ~from=0, ~to_=12)}…). Re-declare it first.`,
            )
          }
        }
      | None => ()
      }
      p
    }
  }
}

let assetById = (m: manifest, id: string): asset =>
  switch m.assets->Belt.Array.getBy(asset => asset.id == id) {
  | Some(asset) => asset
  | None => die(`asset id ${id} is not a path-bearing asset in the canonical manifest`)
  }

/* Pinned Low Poly style key — resolved once for the whole show. */
let styleKey = "856a99ee-5cc9-4fad-ad8d-998d79edb4f4"

let safeSubjectId = subjectId => {
  if Js.String2.includes(subjectId, "/") || Js.String2.includes(subjectId, "\\") ||
    Js.String2.includes(subjectId, "..") {
    die("unsafe generation subject id: " ++ subjectId)
  }
  subjectId
}

let intendedOutputPath = (m: manifest, out: string): string => relativePath(m.root, out)

let safeSceneOutputPath = (m: manifest, path: string, label: string): string => {
  let relative = relativePath(m.dir, resolvePath(path))
  try {
    Drakosha_OutputSafety.manifestOutputPath(
      ~baseDir=m.dir,
      ~relativePath=relative,
      ~label,
    )
  } catch {
  | Drakosha_OutputSafety.OutputSafetyError(message) => die(message)
  }
}

let generationReceiptDir = (m: manifest, subjectId: string): string =>
  safeSceneOutputPath(
    m,
    join2(join2(m.dir, "generation-receipts"), safeSubjectId(subjectId)),
    "generation receipt directory",
  )

let declaredAssetHash = (m: manifest, assetId: string): string =>
  switch assetById(m, assetId).sha256 {
  | Some(value) => value
  | None => die(`reference asset ${assetId} has no declared SHA-256`)
  }

let receiptReferenceRows = (m: manifest, referenceAssetIds: array<string>): array<Js.Json.t> =>
  referenceAssetIds->Belt.Array.map(assetId => {
    let asset = assetById(m, assetId)
    let path = switch asset.path {
    | Some(relative) => resolvePath(join2(m.root, relative))
    | None => die(`reference asset ${assetId} has no declared path`)
    }
    let declared = declaredAssetHash(m, assetId)
    let row = Js.Dict.empty()
    Js.Dict.set(row, "assetId", Js.Json.string(assetId))
    Js.Dict.set(row, "path", Js.Json.string(relativePath(m.root, path)))
    Js.Dict.set(row, "sha256", Js.Json.string(declared))
    Js.Dict.set(row, "declaredSha256", Js.Json.string(declared))
    Js.Json.object_(row)
  })

let requestHash = (
  ~m: manifest,
  ~stage: string,
  ~subjectId: string,
  ~model: string,
  ~prompt: string,
  ~referenceAssetIds: array<string>,
  ~extraRefs: array<string>,
  ~providerArgs: array<string>,
  ~out: string,
): string => {
  let referenceSignature =
    referenceAssetIds
    ->Belt.Array.map(assetId => assetId ++ ":" ++ declaredAssetHash(m, assetId))
    ->Js.Array2.joinWith(",")
  B.sha256Text(
    Js.Array2.joinWith(
      [
        m.sceneId,
        stage,
        subjectId,
        model,
        B.sha256Text(prompt),
        referenceSignature,
        Js.Array2.joinWith(extraRefs, ","),
        Js.Array2.joinWith(providerArgs, "\u{1f}"),
        intendedOutputPath(m, out),
      ],
      "\n",
    ),
  )
}

let sameStrings = (left: array<string>, right: array<string>): bool =>
  Js.Array2.joinWith(left, "\u{1f}") == Js.Array2.joinWith(right, "\u{1f}")

let requireCanonicalRequest = (
  ~m: manifest,
  ~stage: string,
  ~subjectId: string,
  ~model: string,
  ~prompt: string,
  ~referenceAssetIds: array<string>,
  ~extraRefs: array<string>,
  ~providerArgs: array<string>,
  ~out: string,
): unit => {
  let target = assetById(m, subjectId)
  let spec = switch target.generationSpec {
  | Some(value) => value
  | None =>
    die(
      "canonical manifest has no generationSpec for " ++ subjectId ++
      "; declare the exact request before any paid submission",
    )
  }
  let actualRequest = requestHash(
    ~m,
    ~stage,
    ~subjectId,
    ~model,
    ~prompt,
    ~referenceAssetIds,
    ~extraRefs,
    ~providerArgs,
    ~out,
  )
  if spec.stage != stage || spec.subjectId != subjectId || spec.model != model ||
    spec.styleKey != styleKey || spec.promptSha256 != B.sha256Text(prompt) ||
    spec.requestSha256 != actualRequest || !sameStrings(spec.referenceAssetIds, referenceAssetIds) ||
    !sameStrings(spec.externalReferences, extraRefs) || !sameStrings(spec.providerArgs, providerArgs) ||
    spec.outputPath != intendedOutputPath(m, out) {
    die(
      "actual provider request for " ++ subjectId ++
      " does not match its canonical generationSpec; update and review the manifest before spending",
    )
  }
}

let encodeReceipt = (
  ~m: manifest,
  ~stage: string,
  ~subjectId: string,
  ~model: string,
  ~prompt: string,
  ~referenceAssetIds: array<string>,
  ~extraRefs: array<string>,
  ~providerArgs: array<string>,
  ~out: string,
  ~attempt: int,
  ~status: string,
  ~resultUrl: option<string>=?,
  ~failure: option<string>=?,
): string => {
  let receipt = Js.Dict.empty()
  Js.Dict.set(receipt, "schema", Js.Json.string("frosya.generation-receipt/v1"))
  Js.Dict.set(receipt, "sceneId", Js.Json.string(m.sceneId))
  Js.Dict.set(receipt, "inputManifestRevision", Js.Json.number(Belt.Int.toFloat(m.revision)))
  Js.Dict.set(receipt, "inputManifestSha256", Js.Json.string(B.sha256Text(m.raw)))
  Js.Dict.set(receipt, "stage", Js.Json.string(stage))
  Js.Dict.set(receipt, "subjectId", Js.Json.string(subjectId))
  Js.Dict.set(receipt, "model", Js.Json.string(model))
  Js.Dict.set(receipt, "styleKey", Js.Json.string(styleKey))
  Js.Dict.set(receipt, "promptSha256", Js.Json.string(B.sha256Text(prompt)))
  Js.Dict.set(
    receipt,
    "requestSha256",
    Js.Json.string(
      requestHash(
        ~m,
        ~stage,
        ~subjectId,
        ~model,
        ~prompt,
        ~referenceAssetIds,
        ~extraRefs,
        ~providerArgs,
        ~out,
      ),
    ),
  )
  Js.Dict.set(receipt, "referenceAssets", Js.Json.array(receiptReferenceRows(m, referenceAssetIds)))
  Js.Dict.set(receipt, "externalReferences", Js.Json.array(extraRefs->Belt.Array.map(Js.Json.string)))
  Js.Dict.set(receipt, "providerArgs", Js.Json.array(providerArgs->Belt.Array.map(Js.Json.string)))
  Js.Dict.set(receipt, "attempt", Js.Json.number(Belt.Int.toFloat(attempt)))
  Js.Dict.set(receipt, "status", Js.Json.string(status))
  Js.Dict.set(receipt, "readiness", Js.Json.string("PASS"))
  Js.Dict.set(receipt, "outputPath", Js.Json.string(intendedOutputPath(m, out)))
  if status == "succeeded" && B.exists(B.Path(out)) {
    Js.Dict.set(receipt, "outputSha256", Js.Json.string(B.sha256File(B.Path(out))))
  }
  switch resultUrl {
  | Some(url) => Js.Dict.set(receipt, "resultUrl", Js.Json.string(url))
  | None => ()
  }
  switch failure {
  | Some(message) => Js.Dict.set(receipt, "failure", Js.Json.string(message))
  | None => ()
  }
  Js.Dict.set(receipt, "recordedAt", Js.Json.string(Js.Date.make()->Js.Date.toISOString))
  Js.Json.stringifyWithSpace(Js.Json.object_(receipt), 2) ++ "\n"
}

let attemptReceiptPath = (m: manifest, subjectId: string, attempt: int): string => {
  let dir = generationReceiptDir(m, subjectId)
  B.ensureDirPath(B.Path(dir))
  join2(dir, "attempt-" ++ Belt.Int.toString(attempt) ++ ".json")
}

let successReceiptPath = out => out ++ ".receipt.json"

let writeAttemptReceipt = (
  ~m,
  ~stage,
  ~subjectId,
  ~model,
  ~prompt,
  ~referenceAssetIds,
  ~extraRefs,
  ~providerArgs,
  ~out,
  ~attempt,
  ~status,
  ~resultUrl=?,
  ~failure=?,
) =>
  B.writeText(
    B.Path(attemptReceiptPath(m, subjectId, attempt)),
    encodeReceipt(
      ~m,
      ~stage,
      ~subjectId,
      ~model,
      ~prompt,
      ~referenceAssetIds,
      ~extraRefs,
      ~providerArgs,
      ~out,
      ~attempt,
      ~status,
      ~resultUrl?,
      ~failure?,
    ),
  )

let subjectLockPath = (m: manifest, subjectId: string): string => {
  let dir = generationReceiptDir(m, subjectId)
  B.ensureDirPath(B.Path(dir))
  join2(dir, "active.lock")
}

@val @scope("process") external processPid: int = "pid"

let withSubjectLock = (m: manifest, subjectId: string, work: unit => 'value): 'value => {
  let lockPath = subjectLockPath(m, subjectId)
  if !B.writeTextExclusive(
    B.Path(lockPath),
    "scene=" ++ m.sceneId ++ " subject=" ++ subjectId ++
    " pid=" ++ Belt.Int.toString(processPid) ++
    " started=" ++ Js.Date.toISOString(Js.Date.make()) ++ "\n" ++
    "fail-closed lease: never delete while the pid above is alive; if that process is dead, " ++
    "delete this file manually and run the spend audit before regenerating.\n",
  ) {
    let holder = try B.readText(B.Path(lockPath)) catch {
    | _ => "(lease vanished mid-check — a concurrent run just finished; simply retry)"
    }
    die(
      "another guarded run already holds the generation lease for " ++ subjectId ++
      "; stop instead of submitting a concurrent job. Lease says: " ++ holder,
    )
  }
  try {
    let value = work()
    B.removeFile(B.Path(lockPath))
    value
  } catch {
  | FlowError(message) => {
      B.removeFile(B.Path(lockPath))
      raise(FlowError(message))
    }
  | B.BackendError(message) => {
      B.removeFile(B.Path(lockPath))
      raise(B.BackendError(message))
    }
  | Js.Exn.Error(error) => {
      B.removeFile(B.Path(lockPath))
      raise(
        FlowError(
          "unexpected error while holding the generation lease: " ++
          Js.Exn.message(error)->Belt.Option.getWithDefault("unknown JavaScript error"),
        ),
      )
    }
  }
}

let claimAttempt = (
  ~m,
  ~stage,
  ~subjectId,
  ~model,
  ~prompt,
  ~referenceAssetIds,
  ~extraRefs,
  ~providerArgs,
  ~out,
): int => {
  let rec claim = attempt => {
    if attempt > m.maxPaidAttemptsPerTarget {
      die(
        subjectId ++
        " already consumed " ++ Belt.Int.toString(m.maxPaidAttemptsPerTarget) ++
        " paid attempts; stop and review instead of regenerating",
      )
    }
    let started = encodeReceipt(
      ~m,
      ~stage,
      ~subjectId,
      ~model,
      ~prompt,
      ~referenceAssetIds,
      ~extraRefs,
      ~providerArgs,
      ~out,
      ~attempt,
      ~status="started",
    )
    if B.writeTextExclusive(B.Path(attemptReceiptPath(m, subjectId, attempt)), started) {
      attempt
    } else {
      claim(attempt + 1)
    }
  }
  claim(1)
}

let receiptMatchesOutput = (
  ~m: manifest,
  ~stage: string,
  ~subjectId: string,
  ~model: string,
  ~prompt: string,
  ~referenceAssetIds: array<string>,
  ~extraRefs: array<string>,
  ~providerArgs: array<string>,
  ~out: string,
): bool => {
  let receiptPath = successReceiptPath(out)
  if !B.exists(B.Path(receiptPath)) || !B.exists(B.Path(out)) {
    false
  } else {
    let parsed = try {
      Some(Js.Json.parseExn(B.readText(B.Path(receiptPath))))
    } catch {
    | _ => None
    }
    switch parsed->Belt.Option.flatMap(jObj) {
    | None => false
    | Some(receipt) =>
      strField(receipt, "schema") == Some("frosya.generation-receipt/v1") &&
      strField(receipt, "sceneId") == Some(m.sceneId) &&
      strField(receipt, "subjectId") == Some(subjectId) &&
      strField(receipt, "stage") == Some(stage) &&
      strField(receipt, "model") == Some(model) &&
      strField(receipt, "status") == Some("succeeded") &&
      strField(receipt, "readiness") == Some("PASS") &&
      strField(receipt, "outputPath") == Some(intendedOutputPath(m, out)) &&
      strField(receipt, "outputSha256") == Some(B.sha256File(B.Path(out))) &&
      strField(receipt, "requestSha256") == Some(
        requestHash(
          ~m,
          ~stage,
          ~subjectId,
          ~model,
          ~prompt,
          ~referenceAssetIds,
          ~extraRefs,
          ~providerArgs,
          ~out,
        ),
      )
    }
  }
}

/* ---- the show's fixed language -------------------------------------------- */

let neg = "NEGATIVE: no text, no letters, no captions, no signage, no logos, no watermark, no photorealism, no live action, nothing scary, no pointed ears, no shoes, no remote control anywhere in frame, no giant hands, no extra characters. "

let styleTxt = "STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY — low poly 3D, visible flat triangular facets, hard polygon edges, flat-shaded surfaces, rich warm saturated colours, cinematic warm practical light and deep coloured shadow. "

let frosyaTxt = "ФРОСЯ: a small домовой house-spirit girl (NOT a human child), long wavy dark-brown hair with a small ORANGE FLOWER on one side and NO pencil anywhere (pre-gift state), deep warm-brown button nose, freckles, fine soft winged brows, floral patchwork dress, pouch held shut by an ENORMOUS safety pin, barefoot, thin spindly arms and legs, body two and a half of her own head-heights tall. "

let vasyaTxt = "ВАСЯ: a small домовой house-spirit boy (NOT a human child), short spiky warm-brown hair, THICK DARK WINGED eyebrows, deep warm-brown button nose, freckles, gap-toothed mouth, boyish patchwork clothes with NO letter-tile pouch, a pale wrist-thick shoelace belt wrapped twice ending in a rounded nugget aglet, barefoot, thin spindly arms and legs, body two and a half of his own head-heights tall; half a head SHORTER than ФРОСЯ. "

let mouthClosed = "Mouth GENTLY CLOSED, relaxed — this face will be animated for dialogue later. "

let passageGeo = "PASSAGE GEOGRAPHY (locked): the camera is at the room-facing end of the concealed side passage, looking toward the rear corner; the dresser wall is on camera-LEFT, the plaster wall on camera-RIGHT. "

/* Locked true-scale block (author, 2026-08-05): Фрося 3.5in in a standard human
   world; passage 4.5in wide. Applied ONLY to re-shot subjects — appending it to
   an already-receipted prompt would invalidate that receipt and re-spend. */
let scaleTxt = "TRUE SCALE, NON-NEGOTIABLE: ФРОСЯ stands exactly 3.5 INCHES tall and ВАСЯ 3.15 INCHES — tiny house spirits in a full-size HUMAN home where every human object is completely standard-sized. The dresser is a normal full-size chest of drawers: its bottom drawer front alone is TWICE Фрося's height, and one drawer is a room to them. The striped sock is a standard adult sock, THREE times longer than Фрося is tall. Floorboards are each wider than she is tall; the runner rug's fringe cords are as thick as her arm. The concealed passage between the dresser side and the wall is 4.5 INCHES wide — the two children walking side by side almost brush both walls — and its walls tower more than EIGHT times their height, vanishing upward out of frame. When in doubt, the children must look SMALLER against the world, never bigger. "

/* ---- generation ------------------------------------------------------------ */

let parseResultUrl = (stdout: string): option<string> => {
  let i = Js.String2.indexOf(stdout, "[")
  let raw = i >= 0 ? Js.String2.sliceToEnd(stdout, ~from=i) : stdout
  switch try Some(Js.Json.parseExn(raw)) catch {
  | _ => None
  } {
  | None => None
  | Some(j) => {
      let rec0 = switch jArr(j) {
      | Some(items) => items->Belt.Array.get(0)
      | None => Some(j)
      }
      rec0->Belt.Option.flatMap(jObj)->Belt.Option.flatMap(o => strField(o, "result_url"))
    }
  }
}

let downloadExistingResult = (url: string, out: string, minBytes: float): bool => {
  let rec go = attempt => {
    if attempt > 2 {
      false
    } else {
      B.removeFile(B.Path(out))
      let result = B.run(
        ~cmd="curl",
        ~args=["-L", "--silent", "--show-error", "--fail", "-o", out, url],
      )
      if result.code == 0 && B.exists(B.Path(out)) && B.fileSizeMb(B.Path(out)) *. 1.0e6 >= minBytes {
        true
      } else {
        B.removeFile(B.Path(out))
        go(attempt + 1)
      }
    }
  }
  go(1)
}

let refArgs = (refs: array<string>): array<string> =>
  refs->Belt.Array.flatMap(r => ["--image", r])

let ensureHiggsfieldAuth = () => {
  let result = B.run(~cmd="higgsfield", ~args=["account", "status"])
  if result.code != 0 {
    die("Higgsfield is unavailable or not authenticated; run `higgsfield auth login`")
  }
}

/* A provider must never read a live authority path after its hash was checked.
   Copy each reference into a fresh, content-addressed scratch directory and
   submit only those immutable bytes. The provider call is synchronous, so the
   OS may reclaim the scratch directory after the process exits. */
let snapshotReferencePaths = (m: manifest, referenceAssetIds: array<string>): array<string> => {
  let B.Path(snapshotDir) = B.tempDir("drakosha-scene1-inputs-")
  referenceAssetIds->Belt.Array.mapWithIndex((index, assetId) => {
    let source = assetPath(m, assetId)
    let expected = declaredAssetHash(m, assetId)
    let snapshot = join2(
      snapshotDir,
      "ref-" ++ Belt.Int.toString(index) ++ "-" ++ expected ++ ".png",
    )
    B.copyFile(B.Path(source), B.Path(snapshot))
    let actual = B.sha256File(B.Path(snapshot))
    if actual != expected {
      die(
        `reference ${assetId} changed while its immutable provider snapshot was being made; no paid call is allowed`,
      )
    }
    snapshot
  })
}

let paidGenerate = (
  ~m: manifest,
  ~stage: string,
  ~subjectId: string,
  ~model: string,
  ~prompt: string,
  ~referenceAssetIds: array<string>,
  ~extraRefs: array<string>,
  ~out: string,
  ~label: string,
  ~tailArgs: array<string>,
  ~minBytes: float,
): bool => {
  let safeOutput = safeSceneOutputPath(m, out, "generation output")
  if safeOutput != resolvePath(out) {
    die("generation output did not resolve to its canonical Scene 1 path: " ++ out)
  }

  let freshRaw = requireFormalReadiness(m.path, stage)
  let fresh = loadManifestRaw(m.path, freshRaw)
  requireCanonicalRequest(
    ~m=fresh,
    ~stage,
    ~subjectId,
    ~model,
    ~prompt,
    ~referenceAssetIds,
    ~extraRefs,
    ~providerArgs=tailArgs,
    ~out,
  )
  let verifyExisting = (snapshot: manifest) => {
    if receiptMatchesOutput(
      ~m=snapshot,
      ~stage,
      ~subjectId,
      ~model,
      ~prompt,
      ~referenceAssetIds,
      ~extraRefs,
      ~providerArgs=tailArgs,
      ~out,
    ) {
      Js.Console.log("SKIP " ++ label ++ " (verified receipt)")
      true
    } else {
      die("existing output has no valid matching receipt: " ++ out)
    }
  }
  if B.exists(B.Path(out)) {
    verifyExisting(fresh)
  } else {
    withSubjectLock(fresh, subjectId, () => {
      /* The lease is the paid boundary. Everything that can affect the request
         is re-read and revalidated only after we own it, so a manifest edit or
         reference promotion racing the outer planning pass cannot spend against
         a stale snapshot. */
      let lockedRaw = requireFormalReadiness(m.path, stage)
      let locked = loadManifestRaw(m.path, lockedRaw)
      requireCanonicalRequest(
        ~m=locked,
        ~stage,
        ~subjectId,
        ~model,
        ~prompt,
        ~referenceAssetIds,
        ~extraRefs,
        ~providerArgs=tailArgs,
        ~out,
      )

      /* A competing run may have completed between the first existence check
         and this lease. Recheck after acquiring the exclusive subject lock. */
      if B.exists(B.Path(out)) {
        verifyExisting(locked)
      } else {
        if B.exists(B.Path(successReceiptPath(out))) {
          die("success receipt exists but its media is missing: " ++ successReceiptPath(out))
        }
        let refs = Belt.Array.concat(
          extraRefs,
          snapshotReferencePaths(locked, referenceAssetIds),
        )
        /* Authentication is checked only when media is genuinely absent. A
           verified existing output must remain auditable offline. */
        ensureHiggsfieldAuth()
        let attempt = claimAttempt(
          ~m=locked,
          ~stage,
          ~subjectId,
          ~model,
          ~prompt,
          ~referenceAssetIds,
          ~extraRefs,
          ~providerArgs=tailArgs,
          ~out,
        )

        /* Claiming an attempt is conservative. Evaluate once more immediately
           before spawning the provider. If authority changed after the claim,
           record the stopped attempt and make no paid call. */
        let stopBeforeSubmit = message => {
          writeAttemptReceipt(
            ~m=locked,
            ~stage,
            ~subjectId,
            ~model,
            ~prompt,
            ~referenceAssetIds,
            ~extraRefs,
            ~providerArgs=tailArgs,
            ~out,
            ~attempt,
            ~status="blocked_pre_submit",
            ~failure=message ++ "; provider was not called",
          )
          die(message ++ "; no paid call was made")
        }
        let submitRaw = try {
          let candidateRaw = requireFormalReadiness(m.path, stage)
          let submit = loadManifestRaw(m.path, candidateRaw)
          requireCanonicalRequest(
            ~m=submit,
            ~stage,
            ~subjectId,
            ~model,
            ~prompt,
            ~referenceAssetIds,
            ~extraRefs,
            ~providerArgs=tailArgs,
            ~out,
          )
          candidateRaw
        } catch {
        | FlowError(message) => stopBeforeSubmit("final readiness failed: " ++ message)
        | B.BackendError(message) => stopBeforeSubmit("final readiness backend failure: " ++ message)
        }
        /* Keep the value live: this exact snapshot is the one whose immutable
           reference copies and provider argv are submitted below. */
        if B.sha256Text(submitRaw) != B.sha256Text(lockedRaw) {
          stopBeforeSubmit("canonical authority changed immediately before submission")
        }

        let result = B.run(
          ~cmd="higgsfield",
          ~args=Belt.Array.concatMany([
            ["generate", "create", model, "--prompt", prompt],
            refArgs(refs),
            tailArgs,
          ]),
        )
        let resultUrl = result.code == 0 ? parseResultUrl(result.stdout) : None
        switch resultUrl {
        | None => {
            writeAttemptReceipt(
              ~m=locked,
              ~stage,
              ~subjectId,
              ~model,
              ~prompt,
              ~referenceAssetIds,
              ~extraRefs,
              ~providerArgs=tailArgs,
              ~out,
              ~attempt,
              ~status="failed",
              ~failure="provider returned no result URL; exit=" ++ Belt.Int.toString(result.code),
            )
            Js.Console.error("FAIL " ++ label ++ " (paid attempt " ++ Belt.Int.toString(attempt) ++ "/2)")
            false
        }
        | Some(url) => {
            let authorityStillMatches = () =>
              try {
                let unchangedRaw = requireFormalReadiness(m.path, stage)
                B.sha256Text(unchangedRaw) == B.sha256Text(lockedRaw)
              } catch {
              | FlowError(_) => false
              | B.BackendError(_) => false
              }
            if !authorityStillMatches() {
              writeAttemptReceipt(
                ~m=locked,
                ~stage,
                ~subjectId,
                ~model,
                ~prompt,
                ~referenceAssetIds,
                ~extraRefs,
                ~providerArgs=tailArgs,
                ~out,
                ~attempt,
                ~status="quarantined",
                ~resultUrl=url,
                ~failure="authority, readiness, or reference bytes changed while generation was running",
              )
              Js.Console.error("QUARANTINED " ++ label ++ " because production authority changed")
              false
            } else if !downloadExistingResult(url, out, minBytes) {
              writeAttemptReceipt(
                ~m=locked,
                ~stage,
                ~subjectId,
                ~model,
                ~prompt,
                ~referenceAssetIds,
                ~extraRefs,
                ~providerArgs=tailArgs,
                ~out,
                ~attempt,
                ~status="failed",
                ~resultUrl=url,
                ~failure="could not download or validate provider result",
              )
              Js.Console.error("FAIL " ++ label ++ " (download; no second generation submitted)")
              false
            } else if !authorityStillMatches() {
              /* The result download is outside the provider spend but may take
                 long enough for authority to change. Never commit success from
                 that stale window; remove the unapproved bytes and retain the
                 result URL in a quarantined attempt receipt. */
              B.removeFile(B.Path(out))
              writeAttemptReceipt(
                ~m=locked,
                ~stage,
                ~subjectId,
                ~model,
                ~prompt,
                ~referenceAssetIds,
                ~extraRefs,
                ~providerArgs=tailArgs,
                ~out,
                ~attempt,
                ~status="quarantined",
                ~resultUrl=url,
                ~failure="authority, readiness, or reference bytes changed while the provider result was downloading",
              )
              Js.Console.error("QUARANTINED " ++ label ++ " before success commit")
              false
            } else {
              let success = encodeReceipt(
                ~m=locked,
                ~stage,
                ~subjectId,
                ~model,
                ~prompt,
                ~referenceAssetIds,
                ~extraRefs,
                ~providerArgs=tailArgs,
                ~out,
                ~attempt,
                ~status="succeeded",
                ~resultUrl=url,
              )
              B.writeText(B.Path(attemptReceiptPath(locked, subjectId, attempt)), success)
              /* Media is committed first. This adjacent receipt is the final
                 commit marker that allows downstream Scene 1 code to use it. */
              B.writeText(B.Path(successReceiptPath(out)), success)
              Js.Console.log("OK " ++ label ++ " (receipted attempt " ++ Belt.Int.toString(attempt) ++ "/2)")
              true
            }
          }
        }
      }
    })
  }
}

let genImage = (
  ~m,
  ~stage,
  ~subjectId,
  ~prompt,
  ~referenceAssetIds,
  ~extraRefs,
  ~out,
  ~label,
): bool =>
  paidGenerate(
    ~m,
    ~stage,
    ~subjectId,
    ~model="nano_banana_pro",
    ~prompt,
    ~referenceAssetIds,
    ~extraRefs,
    ~out,
    ~label,
    ~tailArgs=["--aspect_ratio", "16:9", "--resolution", "2k", "--wait", "--json"],
    ~minBytes=20000.0,
  )

let genClip = (
  ~m,
  ~stage,
  ~subjectId,
  ~prompt,
  ~referenceAssetIds,
  ~extraRefs,
  ~out,
  ~label,
): bool =>
  paidGenerate(
    ~m,
    ~stage,
    ~subjectId,
    ~model="gemini_omni",
    ~prompt,
    ~referenceAssetIds,
    ~extraRefs,
    ~out,
    ~label,
    ~tailArgs=[
      "--duration",
      "10",
      "--aspect_ratio",
      "16:9",
      "--resolution",
      "720p",
      "--wait",
      "--wait-timeout",
      "12m",
      "--json",
    ],
    ~minBytes=100000.0,
  )

/* ---- stages ---------------------------------------------------------------- */

let stageRefs = (m: manifest): unit => {
  let refsDir = join2(m.dir, "references")
  B.ensureDirPath(B.Path(refsDir))

  let drawerPrompt =
    styleTxt ++
    "LOCATION DERIVATION: the SECOND attached image is the approved room master — THE SAME dresser, the same wood colour and moulding profile, the same warm practical light direction. Generate a CLOSER camera setup of ITS open bottom drawer: a three-quarter view from just above the drawer's RIGHT SIDE, showing (a) the sturdy flat RIM of the drawer side — wide enough for a matchbox-sized house spirit to sit on, (b) the drawer interior below with neatly folded soft linens and one clear empty gap where a sock belongs, (c) the drawer front and, far below, THE SAME FLOOR as the master: bare worn wooden planks; if any floor textile is visible it is ONLY the master's flat-woven fringed runner rug with muted faded red-and-blue stripes — never any other rug or carpet. No characters in frame. This is an empty set reference plate. " ++ neg
  let carPrompt =
    styleTxt ++
    "SCALE REFERENCE: the SECOND attached image shows ФРОСЯ only to establish the show's low-poly design language and her 3.5-inch height; DO NOT depict her in the output. PROP SHEET on a plain warm neutral background: a giant child's TOY CAR — a cool little sports car with smooth low-poly curves, GLOSSY BRIGHT RED body, two BIG ROUND HEADLIGHTS like friendly eyes (switched off), simple dark wheels, a small clear windscreen and an open one-seat cockpit. It is a toy from the giants' world: to ФРОСЯ it is a REAL CAR — about TWICE as long as she is tall, big enough for her to sit inside and drive. Three-quarter view, slightly low camera. NO remote control anywhere. Nothing else in frame. " ++ neg

  let ok1 = genImage(
    ~m,
    ~stage="refs",
    ~subjectId="DRAWER_SIDE_INTERIOR",
    ~prompt=drawerPrompt,
    ~referenceAssetIds=["ROOM_MASTER"],
    ~extraRefs=[styleKey],
    ~out=join2(refsDir, "drawer_side_interior_candidate_v1.png"),
    ~label="drawer_side_interior",
  )
  let ok2 = genImage(
    ~m,
    ~stage="refs",
    ~subjectId="RED_CAR",
    ~prompt=carPrompt,
    ~referenceAssetIds=["FROSYA_PREGIFT"],
    ~extraRefs=[styleKey],
    ~out=join2(refsDir, "red_hero_car_candidate_v1.png"),
    ~label="red_hero_car",
  )
  /* Scale-corrected passage plate (author, 2026-08-05): replaces the working
     reference once approved. Derived from the room master for material/light. */
  let passagePrompt =
    styleTxt ++
    scaleTxt ++
    "LOCATION DERIVATION: the SECOND attached image is the approved room master — THE SAME dresser wood, the same plaster wall, the same warm practical light temperature. Generate the CONCEALED SIDE PASSAGE between the dresser's side and the wall, seen from INSIDE at floor level at the room-facing end, looking toward the dim rear corner: dresser SIDE wall on camera-LEFT rising out of frame, plaster wall on camera-RIGHT, worn floorboards below, a soft spill of warm room light entering from behind the camera and fading toward the rear. DRESSER WALL LAW: the camera-left wall is the dresser's plain SIDE PANEL — ONE smooth continuous surface of plain wood grain from floor to top of frame, with NO drawer fronts, NO horizontal seams or gaps, NO handles, NO knobs, NO mouldings, NO panel divisions of any kind; drawers exist only on the dresser's room-facing front, which cannot be seen from inside the passage. The passage is 4.5 INCHES wide — the beings who use it are 3.5 inches tall, so this is a narrow towering canyon to them, NOT a human hallway. Empty, no characters, no props. This is an empty set reference plate. " ++ neg
  let ok3 = switch (assetById(m, "PASSAGE_ANCHOR").generationSpec, true) {
  | (Some(_), _) =>
    genImage(
      ~m,
      ~stage="refs",
      ~subjectId="PASSAGE_ANCHOR",
      ~prompt=passagePrompt,
      ~referenceAssetIds=["ROOM_MASTER"],
      ~extraRefs=[styleKey],
      ~out=join2(refsDir, "passage_anchor_candidate_v1.png"),
      ~label="passage_anchor",
    )
  | (None, _) => true
  }

  /* The C02 relational start frame regenerates only after the new passage
     plate is itself approved and declared (it is that plate plus characters). */
  let dragStartPrompt =
    styleTxt ++
    scaleTxt ++
    passageGeo ++
    frosyaTxt ++
    vasyaTxt ++
    "RELATIONAL START FRAME for the sock-drag, DIRECTION LAW (approved motion map): the camera is at the room-facing end; the children move TOWARD the camera and the sock is ALWAYS BEHIND them, DEEPER in frame, stretching AWAY from the camera toward the dim rear crack — they PULL it, it is never beside them, never ahead of them, never pushed. Far away at the dim REAR end of the passage, ФРОСЯ and ВАСЯ face the camera mid-pull, leaning toward the camera, both gripping the ribbed cuff edge of the sock behind them; the standard ADULT-SIZED knitted striped sock — AS LONG AS THREE CHILDREN LAID HEAD TO FOOT — stretches from their hands AWAY toward the rear corner, its toe vanishing into the gloom by the baseboard crack. They read TINY at this distance, heads well below one-tenth of frame height; far away, not small-bodied, proportions exactly on-model. DRESSER WALL LAW: the wooden wall on camera-LEFT is the dresser SIDE PANEL — one smooth continuous plain wood surface with NO drawer fronts, NO drawer seams, NO handles, NO knobs, NO mouldings; drawers exist only on the room-facing front, which is NEVER visible inside the passage. " ++ neg
  let dragReady = switch assetById(m, "SOCK_DRAG_START_R2").generationSpec {
  | Some(_) =>
    switch assetById(m, "PASSAGE_ANCHOR").path {
    | Some(_) => true
    | None => false
    }
  | None => false
  }
  let ok4 = if dragReady {
    genImage(
      ~m,
      ~stage="refs",
      ~subjectId="SOCK_DRAG_START_R2",
      ~prompt=dragStartPrompt,
      ~referenceAssetIds=["PASSAGE_ANCHOR", "FROSYA_PREGIFT", "VASYA", "SOCK"],
      ~extraRefs=[styleKey],
      ~out=join2(refsDir, "sock_drag_start_r2_candidate_v1.png"),
      ~label="sock_drag_start",
    )
  } else {
    Js.Console.log("sock_drag_start: waiting for PASSAGE_ANCHOR approval (skipped, no spend)")
    true
  }
  Js.Console.log(
    ok1 && ok2 && ok3 && ok4
      ? "\nReceipted candidates written to references/. Author reviews; on approval promote the corresponding rows, flip approvals.referenceBoard, and bump the authority revision."
      : "\nOne or more candidates FAILED — nothing to review yet.",
  )
  if !ok1 || !ok2 || !ok3 || !ok4 {
    die("one or more reference candidates failed")
  }
}

let stageStoryboard = (m: manifest): unit => {
  requireApproval(m, "referenceBoard")
  let out = join2(m.dir, "storyboard")
  B.ensureDirPath(B.Path(out))
  let chars = frosyaTxt ++ vasyaTxt

  let shots: array<(string, array<string>, string)> = [
    (
      "C03_frosya_dostavay",
      ["PASSAGE_WORKING", "FROSYA_PREGIFT", "VASYA", "SOCK"],
      passageGeo ++
      chars ++
      "SHOT: MEDIUM CLOSE inside the passage near its front end. ФРОСЯ stands facing the camera three-quarter, chin up, mid-instruction, businesslike; ВАСЯ beside her at camera-right already reaching for the shoelace belt at his waist. The striped sock lies slack behind them. " ++
      mouthClosed,
    ),
    (
      "C04_hoist_wide",
      ["DRAWER_SIDE_INTERIOR", "FROSYA_PREGIFT", "VASYA", "SOCK"],
      scaleTxt ++
      chars ++ "SHOT: ONE WIDE STILL of an operation already underway (editorial ellipsis — no climbing, no tying, no casting shown). The open bottom drawer of the STANDARD FULL-SIZE dresser is a canyon to the two tiny spirits: its wooden side wall rises TWICE ФРОСЯ's full height, each folded linen stack is a boulder as tall as she is. ВАСЯ, tiny on the broad flat RIM of the drawer's right side wall, sits at what is to him a cliff edge, both hands pulling his pale shoelace upward in a taut line; down inside the drawer ФРОСЯ — dwarfed beside the linen stacks — steadies the enormous striped adult sock tied to the shoelace's lower end. Their combined size is small against the drawer, like two mice in a filing box. Calm, competent teamwork. ",
    ),
    (
      "C05_sock_na_meste",
      ["DRAWER_SIDE_INTERIOR", "SOCK"],
      "SHOT: INSIDE THE DRAWER, looking down into the linen gap. The striped sock lies freshly landed, still settling, one small bulge under it — someone is completely hidden beneath the sock; only the bulge shape suggests him. Nobody's face is visible. Soft warm light from above. ",
    ),
    (
      "C06_R3_tak_dom_ustroen",
      ["SOCK_DRAG_START", "FROSYA_PREGIFT"],
      "IDENTITY FIRST: the attached ФРОСЯ reference is a LOCKED design — match her EXACTLY: the same face, the same eyes and brows, the same wavy dark-brown hair with the orange flower, the same floral patchwork dress with the big safety-pin pouch, barefoot, NO pencil anywhere. She is 3.5 inches tall. " ++
      passageGeo ++
      "ENVIRONMENT: the FIRST place image shows THE EXACT corridor — the same smooth plain wooden wall on the left with NO drawers and NO handles, the same plaster wall on the right, the same huge floorboards running along the corridor, the same warm light. Reproduce THAT corridor exactly, from the same low camera position, but EMPTY of the two children shown in it. SHOT: ФРОСЯ ALONE stands a step inside the corridor near its bright end, half in dim shadow, the warm light catching one side of her face as she carefully scans outward FROM COVER — alert, calm, the older sibling doing the safety check. Nobody else in frame. " ++
      mouthClosed,
    ),
    (
      "C07_peek",
      ["PASSAGE_WORKING", "FROSYA_PREGIFT", "VASYA"],
      passageGeo ++
      chars ++
      "SHOT: at the room-facing passage entrance, a TWO-CHARACTER REACTION: ВАСЯ crouched low peeking around the edge, ФРОСЯ directly above him peeking over his head, both mostly hidden behind the dresser edge, four wide curious eyes catching warm light from the room. Both mouths closed. ",
    ),
    (
      "C09_danger",
      ["PASSAGE_WORKING", "FROSYA_PREGIFT", "VASYA"],
      passageGeo ++
      chars ++
      "SHOT: DANGER. The passage floods with hard WHITE-YELLOW HEADLIGHT GLARE from the room side; a COLOSSAL SOFT SHADOW of something large sweeps across the plaster wall. ФРОСЯ and ВАСЯ are small silhouettes pressed against the dresser wall, edge-lit by the glare, caught mid-turn to flee. The car itself is NOT in frame; no giant hand; only light and shadow tell the danger. ",
    ),
    (
      "C10_last_look",
      ["PASSAGE_WORKING", "FROSYA_PREGIFT", "VASYA", "RED_CAR"],
      passageGeo ++
      chars ++
      "SHOT: FINAL STILL, from deep inside the passage near the rear corner. ВАСЯ is already half-gone around the rear corner at frame edge (just a leg and trailing shoelace tail). ФРОСЯ has stopped mid-flight for ONE LAST LOOK back toward the room-facing end, where — far away and small — two warm RED-lit round headlights glow in the darkness. Longing on her face, body still turned to flee. The car is only distant glowing headlights, no details. ",
    ),
  ]

  let allOk = shots->Belt.Array.reduce(true, (acc, (name, referenceAssetIds, desc)) =>
    genImage(
      ~m,
      ~stage="storyboard",
      ~subjectId=name,
      ~prompt=styleTxt ++ desc ++ " " ++ neg,
      ~referenceAssetIds,
      ~extraRefs=[styleKey],
      ~out=join2(out, name ++ ".png"),
      ~label=name,
    ) && acc
  )
  Js.Console.log(
    allOk
      ? "\nStoryboard batch complete. Assemble the contact sheet, then ONE author review; on approval flip approvals.storyboard, bump revision. A still animatic precedes any motion."
      : "\nStoryboard batch has FAILURES — do not review a partial board.",
  )
  if !allOk {
    die("storyboard batch has failures")
  }
}

let stageMotion = (m: manifest): unit => {
  requireApproval(m, "storyboard")
  requireApproval(m, "animatic")
  let out = join2(m.dir, "clips")
  B.ensureDirPath(B.Path(out))
  let chars = frosyaTxt ++ vasyaTxt

  let c02 =
    styleTxt ++
    passageGeo ++
    chars ++
    "START FRAME REFERENCE: the FIRST place image is the EXACT starting arrangement and the EXACT corridor — the two children far away at the dim rear end with the striped sock, plain smooth dresser side wall on camera-LEFT (NO drawer fronts, NO handles), plaster on camera-RIGHT, huge floorboards running along the corridor. Begin from precisely this arrangement. PROP: the sock image is the LOCKED striped sock; colours never change; it is a standard ADULT sock as long as THREE children laid head to foot. DIRECTION LAW: the children move TOWARD the camera and the sock TRAILS BEHIND them, deeper in frame, sliding limp and heavy along the floor toward the rear — PULLED, never pushed, never beside or ahead of them. MOTION: ФРОСЯ and ВАСЯ haul the enormous limp sock from the rear corner TOWARD the camera, leaning into the pull, bare feet braced, the sock creasing and dragging flat on the boards behind them — one single continuous approach, nothing else happens. Dust motes drift in the warm light. Camera locked off. AUDIO: none needed. " ++ neg
  let c08 =
    styleTxt ++
    "SCENE: the approved big room with the dresser (the place reference) seen low from floor level near the dresser's base; warm evening practical light; the fringed runner rug lies in front of the dresser. PROP: the car image is the LOCKED hero car — glossy bright red, big round headlights ON, no remote control exists. MOTION: the red toy car drives ONCE across the open room floor from frame-right toward the dresser, headlights sweeping the boards, wheels humming; in the background above, only the LOWER LEGS AND SOCKED FEET of a giant child follow a few steps behind it — never a face, never hands, never a remote. CAR LAW: at the end of its single run the car STOPS SHORT of the dresser, its wheels snagging in the runner rug's fringe, nose pointed at the dark gap beside the dresser so its headlight beams rake into that gap; the car NEVER enters or touches the gap. Motor whirs helplessly, wheels spinning in the fringe. Camera locked off. AUDIO: none needed. NEGATIVE also: no house spirits in this shot, no ФРОСЯ, no ВАСЯ. " ++ neg

  let ok1 = genClip(
    ~m,
    ~stage="motion",
    ~subjectId="C02",
    ~prompt=c02,
    ~referenceAssetIds=["SOCK_DRAG_START", "SOCK", "FROSYA_PREGIFT", "VASYA"],
    ~extraRefs=[styleKey],
    ~out=join2(out, "C02_sock_drag_v1.mp4"),
    ~label="C02_sock_drag",
  )
  let ok2 = genClip(
    ~m,
    ~stage="motion",
    ~subjectId="C08",
    ~prompt=c08,
    ~referenceAssetIds=["ROOM_MASTER", "RED_CAR"],
    ~extraRefs=[styleKey],
    ~out=join2(out, "C08_car_cross_v1.mp4"),
    ~label="C08_car_cross",
  )
  Js.Console.log(
    ok1 && ok2
      ? "\nMotion clips done. Assemble the pre-lip-sync cut; fal.ai lip-sync ONLY after the author approves that cut (BIBLE.md gate)."
      : "\nOne or both clips FAILED.",
  )
  if !ok1 || !ok2 {
    die("one or both motion clips failed")
  }
}

let runStage = (~manifestPath: string, ~stage: string, ~go: bool): unit => {
  let raw = requireFormalReadiness(manifestPath, stage)
  let m = loadManifestRaw(manifestPath, raw)
  if !go {
    die(
      `DRY RUN: '${stage}' is ready against the canonical manifest, but --go was not supplied; no provider call was made`,
    )
  }
  switch stage {
  | "refs" => stageRefs(m)
  | "storyboard" => stageStoryboard(m)
  | "motion" => stageMotion(m)
  | other => die(`unknown stage '${other}' (refs | storyboard | motion)`)
  }
}
