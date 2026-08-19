exception OutputSafetyError(string)

type namedPath = {label: string, path: string}

let manifestOutputPath: (~baseDir: string, ~relativePath: string, ~label: string) => string
let pathsCollide: (string, string) => bool
let assertNoCollisions: (~outputs: array<namedPath>, ~protectedPaths: array<namedPath>) => unit
let atomicRename: (~temporaryPath: string, ~destinationPath: string) => unit
