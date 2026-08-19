/* Deterministic, zero-spend validator for the Episode 9 finale anchor-still batch. */

module B = Cinema_Backends

@module("node:path") external dirname: string => string = "dirname"
@module("node:path") external resolve2: (string, string) => string = "resolve"
@module("node:path") external isAbsolute: string => bool = "isAbsolute"

exception AnchorStillsError(string)

let die = message => raise(AnchorStillsError(message))

let objectOf = (json, where) =>
  switch Js.Json.decodeObject(json) {
  | Some(value) => value
  | None => die(where ++ " must be an object")
  }

let field = (object_, key, where) =>
  switch Js.Dict.get(object_, key) {
  | Some(value) => value
  | None => die(where ++ "." ++ key ++ " is required")
  }

let stringField = (object_, key, where) =>
  switch field(object_, key, where)->Js.Json.decodeString {
  | Some(value) if Js.String2.trim(value) != "" => value
  | Some(_) => die(where ++ "." ++ key ++ " must not be empty")
  | None => die(where ++ "." ++ key ++ " must be a string")
  }

let numberField = (object_, key, where) =>
  switch field(object_, key, where)->Js.Json.decodeNumber {
  | Some(value) => value
  | None => die(where ++ "." ++ key ++ " must be a number")
  }

let boolField = (object_, key, where) =>
  switch field(object_, key, where)->Js.Json.decodeBoolean {
  | Some(value) => value
  | None => die(where ++ "." ++ key ++ " must be a boolean")
  }

let arrayField = (object_, key, where) =>
  switch field(object_, key, where)->Js.Json.decodeArray {
  | Some(value) => value
  | None => die(where ++ "." ++ key ++ " must be an array")
  }

let close = (left, right) => Js.Math.abs_float(left -. right) < 0.0001

let wordCount = text => {
  let trimmed = Js.String2.trim(text)
  trimmed == "" ? 0 : trimmed->Js.String2.splitByRe(%re("/\s+/"))->Belt.Array.length
}

let resolveRequiredFile = (~manifestDirectory, ~relativePath, ~where) => {
  if isAbsolute(relativePath) {
    die(where ++ " must be relative to the manifest")
  }
  let resolved = resolve2(manifestDirectory, relativePath)
  if !B.exists(B.Path(resolved)) {
    die(where ++ " does not resolve to an existing file: " ++ relativePath)
  }
  resolved
}

let readRequiredText = (~path, ~where) =>
  try B.readText(B.Path(path)) catch {
  | B.BackendError(message) => die(where ++ " cannot be read: " ++ message)
  | Js.Exn.Error(error) =>
    die(
      where ++ " cannot be read: " ++
      Js.Exn.message(error)->Belt.Option.getWithDefault("unknown filesystem error"),
    )
  }

type result = {
  count: int,
  model: string,
  firstTakeCredits: float,
  retryCredits: float,
  promptWordMaximum: int,
  referenceCount: int,
  overlayPath: string,
}

let validate = (~manifestPath): result => {
  let manifestDirectory = dirname(manifestPath)
  if !B.exists(B.Path(manifestPath)) {
    die("anchor manifest cannot be read: file does not exist")
  }
  let root = try B.readText(B.Path(manifestPath))->Js.Json.parseExn->objectOf("anchor manifest") catch {
  | B.BackendError(message) => die("anchor manifest cannot be read: " ++ message)
  | Js.Exn.Error(error) =>
    die(
      "anchor manifest is not valid JSON: " ++
      Js.Exn.message(error)->Belt.Option.getWithDefault("unknown parse error"),
    )
  }

  let policy = field(root, "policy", "anchor manifest")->objectOf("anchor manifest.policy")
  let aspectRatio = stringField(policy, "aspectRatio", "anchor manifest.policy")
  let resolution = stringField(policy, "resolution", "anchor manifest.policy")
  let model = stringField(policy, "model", "anchor manifest.policy")
  let quoteGate = numberField(policy, "quoteGate", "anchor manifest.policy")
  let maximumAttempts = numberField(policy, "maximumAttemptsPerAnchor", "anchor manifest.policy")
  let firstTakeCeiling = numberField(policy, "firstTakeCeilingCredits", "anchor manifest.policy")
  let retryCeiling = numberField(policy, "retryCeilingCredits", "anchor manifest.policy")
  let generatedTextForbidden = boolField(policy, "generatedTextForbidden", "anchor manifest.policy")
  let overlayRelative = stringField(policy, "exactLetterOverlay", "anchor manifest.policy")

  if aspectRatio != "16:9" {
    die("anchor manifest.policy.aspectRatio must be 16:9")
  }
  if resolution != "2k" {
    die("anchor manifest.policy.resolution must be 2k")
  }
  if model != "nano_banana_pro" {
    die("anchor manifest.policy.model must be nano_banana_pro")
  }
  if !close(quoteGate, 2.0) {
    die("anchor manifest.policy.quoteGate must be 2 credits")
  }
  if !close(maximumAttempts, 2.0) {
    die("anchor manifest.policy.maximumAttemptsPerAnchor must be 2")
  }
  if !close(firstTakeCeiling, 24.0) {
    die("anchor manifest.policy.firstTakeCeilingCredits must be 24")
  }
  if !close(retryCeiling, 24.0) {
    die("anchor manifest.policy.retryCeilingCredits must be 24")
  }
  if !generatedTextForbidden {
    die("anchor manifest.policy.generatedTextForbidden must be true")
  }

  let overlayPath = resolveRequiredFile(
    ~manifestDirectory,
    ~relativePath=overlayRelative,
    ~where="anchor manifest.policy.exactLetterOverlay",
  )

  let anchors = arrayField(root, "anchors", "anchor manifest")
  if Belt.Array.length(anchors) != 12 {
    die("anchor manifest must contain exactly 12 anchors")
  }

  let expectedFirstTake = Belt.Array.length(anchors)->Belt.Int.toFloat *. quoteGate
  let expectedRetries =
    Belt.Array.length(anchors)->Belt.Int.toFloat *. quoteGate *. (maximumAttempts -. 1.0)
  if !close(firstTakeCeiling, expectedFirstTake) {
    die("first-take ceiling does not equal anchor count times quote gate")
  }
  if !close(retryCeiling, expectedRetries) {
    die("retry ceiling does not equal one retry per anchor at the quote gate")
  }

  let ids = Js.Dict.empty()
  let outputs = Js.Dict.empty()
  let promptWordMaximum = ref(0)
  let referenceCount = ref(0)

  anchors->Belt.Array.forEachWithIndex((index, anchorJson) => {
    let where = "anchor manifest.anchors[" ++ Belt.Int.toString(index) ++ "]"
    let anchor = objectOf(anchorJson, where)
    let id = stringField(anchor, "id", where)
    let output = stringField(anchor, "output", where)
    let promptRelative = stringField(anchor, "promptFile", where)

    if Js.Dict.get(ids, id) != None {
      die("duplicate anchor id: " ++ id)
    }
    Js.Dict.set(ids, id, true)
    if isAbsolute(output) {
      die(where ++ ".output must be relative to the manifest")
    }
    let resolvedOutput = resolve2(manifestDirectory, output)
    if Js.Dict.get(outputs, resolvedOutput) != None {
      die("duplicate anchor output: " ++ output)
    }
    Js.Dict.set(outputs, resolvedOutput, true)

    let promptPath = resolveRequiredFile(
      ~manifestDirectory,
      ~relativePath=promptRelative,
      ~where=where ++ ".promptFile",
    )
    let promptWords = readRequiredText(~path=promptPath, ~where=where ++ ".promptFile")->wordCount
    if promptWords == 0 {
      die(id ++ " prompt must not be empty")
    }
    if promptWords > 200 {
      die(id ++ " prompt exceeds the 200-word ceiling")
    }
    if promptWords > promptWordMaximum.contents {
      promptWordMaximum := promptWords
    }

    let references = arrayField(anchor, "references", where)
    references->Belt.Array.forEachWithIndex((referenceIndex, referenceJson) => {
      let referenceWhere =
        where ++ ".references[" ++ Belt.Int.toString(referenceIndex) ++ "]"
      let referenceRelative = switch Js.Json.decodeString(referenceJson) {
      | Some(value) if Js.String2.trim(value) != "" => value
      | Some(_) => die(referenceWhere ++ " must not be empty")
      | None => die(referenceWhere ++ " must be a string")
      }
      resolveRequiredFile(
        ~manifestDirectory,
        ~relativePath=referenceRelative,
        ~where=referenceWhere,
      )->ignore
      referenceCount := referenceCount.contents + 1
    })
  })

  {
    count: Belt.Array.length(anchors),
    model,
    firstTakeCredits: firstTakeCeiling,
    retryCredits: retryCeiling,
    promptWordMaximum: promptWordMaximum.contents,
    referenceCount: referenceCount.contents,
    overlayPath,
  }
}

let printResult = result => {
  Js.log("KUKU EP9 FINALE ANCHOR STILLS — VALID")
  Js.log(
    Belt.Int.toString(result.count) ++ " anchors | " ++ result.model ++ " | 2K 16:9 | " ++
    Js.Float.toString(result.firstTakeCredits) ++ " first-take credits | " ++
    Js.Float.toString(result.retryCredits) ++ " retry credits",
  )
  Js.log(
    Belt.Int.toString(result.referenceCount) ++ " references resolved | longest prompt " ++
    Belt.Int.toString(result.promptWordMaximum) ++ " words | exact-letter overlay resolved",
  )
}
