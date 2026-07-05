@module("fs") external existsSync: string => bool = "existsSync"
@module("fs") external writeFileSync: (string, string) => unit = "writeFileSync"
@module("fs") external unlinkSync: string => unit = "unlinkSync"

let path = ".studio.lock"

let acquire = (): bool =>
  if existsSync(path) {
    false
  } else {
    writeFileSync(path, "locked")
    true
  }

let release = (): unit =>
  if existsSync(path) {
    unlinkSync(path)
  }
