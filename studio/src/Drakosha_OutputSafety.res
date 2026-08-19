/* Filesystem guards shared by the Drakosha preflight and release CLIs.

   Manifest-controlled diagnostics are allowed only beneath the manifest's
   directory.  We check both the lexical path and its nearest existing real
   ancestor so an existing symlink cannot redirect a write outside that tree.
   All collision comparisons use the same projected real path. */

exception OutputSafetyError(string)

@module("node:fs") external existsSync: string => bool = "existsSync"
@module("node:fs") external realpathSync: string => string = "realpathSync"
@module("node:fs") external renameSync: (string, string) => unit = "renameSync"
@module("node:fs") external unlinkSync: string => unit = "unlinkSync"
type fileStats = {dev: float, ino: float}
@module("node:fs") external lstatSync: string => fileStats = "lstatSync"
@module("node:fs") external statSync: string => fileStats = "statSync"
@send external statsIsDirectory: fileStats => bool = "isDirectory"
@get external fsErrorCodeNullable: Js.Exn.t => Js.Nullable.t<string> = "code"
@module("node:path") external dirname: string => string = "dirname"
@module("node:path") external isAbsolute: string => bool = "isAbsolute"
@module("node:path") external relative2: (string, string) => string = "relative"
@module("node:path") external resolve1: string => string = "resolve"
@module("node:path") external resolve2: (string, string) => string = "resolve"

type namedPath = {label: string, path: string}

let absolutePath = (path: string): string => resolve1(path)

let isAbsentErrorCode = code => code == "ENOENT" || code == "ENOTDIR"

let lstatIfExists = (path: string): option<fileStats> =>
  try {
    Some(lstatSync(path))
  } catch {
  | Js.Exn.Error(error) =>
    switch fsErrorCodeNullable(error)->Js.Nullable.toOption {
    | Some(code) if isAbsentErrorCode(code) => None
    | Some(code) =>
      raise(OutputSafetyError("cannot inspect filesystem entry " ++ path ++ ": " ++ code))
    | None =>
      raise(
        OutputSafetyError(
          "cannot inspect filesystem entry " ++ path ++ ": " ++
          Js.Exn.message(error)->Belt.Option.getWithDefault("unknown filesystem error"),
        ),
      )
    }
  }

let directoryEntryExists = (path: string): bool => lstatIfExists(path) != None

let removeFileEntry = (path: string): unit =>
  switch lstatIfExists(path) {
  | None => ()
  | Some(stats) =>
    if statsIsDirectory(stats) {
      raise(OutputSafetyError("refusing to invalidate directory at file output path " ++ path))
    }
    try {
      unlinkSync(path)
    } catch {
    | Js.Exn.Error(error) =>
      raise(
        OutputSafetyError(
          "cannot invalidate output entry " ++ path ++ ": " ++
          Js.Exn.message(error)->Belt.Option.getWithDefault("unknown filesystem error"),
        ),
      )
    }
  }

let escapes = (relative: string): bool =>
  relative == ".." ||
  Js.String2.startsWith(relative, "../") ||
  Js.String2.startsWith(relative, "..\\") ||
  isAbsolute(relative)

let rec nearestExisting = (path: string): string =>
  if directoryEntryExists(path) {
    path
  } else {
    let parent = dirname(path)
    if parent == path {
      raise(OutputSafetyError("cannot find an existing ancestor for " ++ path))
    }
    nearestExisting(parent)
  }

/* Identity of an existing path, or where a not-yet-existing path will land
 after resolving every existing ancestor (including symlinked directories). */
let canonicalIdentity = (path: string): string => {
  let absolute = absolutePath(path)
  if directoryEntryExists(absolute) {
    realpathSync(absolute)
  } else {
    let ancestor = nearestExisting(dirname(absolute))
    let suffix = relative2(ancestor, absolute)
    resolve2(realpathSync(ancestor), suffix)
  }
}

/* Default macOS volumes are commonly case-insensitive.  Treat case-only
   aliases as collisions even on a case-sensitive development volume so a
   diagnostic set cannot become destructive when moved between filesystems.
   Manifest output names are ASCII-only, but normalizing separators keeps the
   comparison conservative on every supported host. */
let conservativeIdentity = (path: string): string =>
  canonicalIdentity(path)
  ->Js.String2.split("\\")
  ->Js.Array2.joinWith("/")
  ->Js.String2.toLowerCase

let manifestOutputPath = (~baseDir: string, ~relativePath: string, ~label: string): string => {
  if Js.String2.trim(relativePath) == "" {
    raise(OutputSafetyError(label ++ " must be a nonempty relative file path"))
  }
  if isAbsolute(relativePath) {
    raise(
      OutputSafetyError(label ++ " must be relative to the manifest directory: " ++ relativePath),
    )
  }
  let base = absolutePath(baseDir)
  let candidate = resolve2(base, relativePath)
  let lexicalRelative = relative2(base, candidate)
  if lexicalRelative == "" || escapes(lexicalRelative) {
    raise(OutputSafetyError(label ++ " escapes or names the manifest directory: " ++ relativePath))
  }
  if directoryEntryExists(candidate) && !existsSync(candidate) {
    raise(
      OutputSafetyError(
        label ++ " is a dangling filesystem entry and cannot be written safely: " ++ relativePath,
      ),
    )
  }
  let realBase = realpathSync(base)
  let realCandidate = canonicalIdentity(candidate)
  let realRelative = relative2(realBase, realCandidate)
  if realRelative == "" || escapes(realRelative) {
    raise(
      OutputSafetyError(
        label ++ " escapes the manifest directory through an existing path: " ++ relativePath,
      ),
    )
  }
  candidate
}

let pathsCollide = (left: string, right: string): bool => {
  let leftAbsolute = absolutePath(left)
  let rightAbsolute = absolutePath(right)
  let leftIdentity = conservativeIdentity(leftAbsolute)
  let rightIdentity = conservativeIdentity(rightAbsolute)
  if leftIdentity == rightIdentity ||
    Js.String2.startsWith(leftIdentity, rightIdentity ++ "/") ||
    Js.String2.startsWith(rightIdentity, leftIdentity ++ "/") {
    true
  } else if directoryEntryExists(leftAbsolute) && directoryEntryExists(rightAbsolute) {
    /* realpath cannot distinguish two names for the same hard-linked file. */
    let leftStats = statSync(leftAbsolute)
    let rightStats = statSync(rightAbsolute)
    leftStats.dev == rightStats.dev && leftStats.ino == rightStats.ino
  } else {
    false
  }
}

let assertNoCollisions = (~outputs: array<namedPath>, ~protectedPaths: array<namedPath>): unit => {
  outputs->Belt.Array.forEachWithIndex((i, output) => {
    outputs->Belt.Array.forEachWithIndex((j, other) =>
      if j > i && pathsCollide(output.path, other.path) {
        raise(
          OutputSafetyError(
            output.label ++
            " collides with " ++
            other.label ++
            ": " ++
            canonicalIdentity(output.path),
          ),
        )
      }
    )
    protectedPaths->Belt.Array.forEach(protected =>
      if pathsCollide(output.path, protected.path) {
        raise(
          OutputSafetyError(
            output.label ++
            " collides with " ++
            protected.label ++
            ": " ++
            canonicalIdentity(output.path),
          ),
        )
      }
    )
  })
}

let atomicRename = (~temporaryPath: string, ~destinationPath: string): unit =>
  renameSync(temporaryPath, destinationPath)
