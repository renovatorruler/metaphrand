@module("fs") external writeFileSync: (string, string) => unit = "writeFileSync"
@module("fs") external readFileSync: (string, string) => string = "readFileSync"
@module("fs") external existsSync: string => bool = "existsSync"

let saveWorld = (b: Process.bible, path: string): unit =>
  writeFileSync(path, Process.bibleToText(b))

let loadWorld = (path: string): option<Process.bible> =>
  existsSync(path) ? Some(Process.bibleFromText(readFileSync(path, "utf8"))) : None
