@val @scope(("process", "env")) external envDry: option<string> = "DRY"
@val @scope(("process", "env")) external envArchive: option<string> = "ARCHIVE"
@val @scope(("process", "env")) external envV2RawDir: option<string> = "KUKU_EP9_V2_RAW_DIR"
@val @scope(("process", "env")) external envV1RawDir: option<string> = "KUKU_EP9_V1_RAW_DIR"
@val @scope("process") external exit: int => unit = "exit"

let valueOr = (value, fallback) =>
  switch value {
  | Some(path) if Js.String2.trim(path) != "" => path
  | _ => fallback
  }

let main = () => {
  let dry = envDry == Some("1")
  let archiveRequested = envArchive == Some("1")
  let roots: Kuku_Ep9RawProviderArchive.roots = {
    v2: valueOr(envV2RawDir, Kuku_Ep9RawProviderArchive.defaultV2RawDir),
    v1: valueOr(envV1RawDir, Kuku_Ep9RawProviderArchive.defaultV1RawDir),
  }
  try {
    if !dry && !archiveRequested {
      raise(Kuku_Ep9RawProviderArchive.RawProviderArchive(
        "choose DRY=1 for read-only inspection or ARCHIVE=1 for explicit preservation",
      ))
    }
    let (input, inspection) = Kuku_Ep9RawProviderArchive.loadAndInspect(roots)
    Kuku_Ep9RawProviderArchive.printInspection(inspection)
    if Kuku_Ep9RawProviderArchive.hasBlockingIssue(inspection) {
      raise(Kuku_Ep9RawProviderArchive.RawProviderArchive(
        "raw-provider preflight failed; the exact missing/conflicting paths are listed above",
      ))
    }
    if dry {
      Js.log("DRY run — no directory, audio object, or inventory was written.")
    } else {
      let result = Kuku_Ep9RawProviderArchive.publish(input, roots, inspection)
      Js.log(
        "RAW PROVIDER ARCHIVE COMPLETE — " ++
        Belt.Int.toString(result.archivedCount) ++ " new, " ++
        Belt.Int.toString(result.reusedCount) ++ " reused",
      )
      Js.log("inventory: " ++ result.inventoryPath)
      Js.log("inventory sha256: " ++ result.inventorySha256)
      Js.log("inventory reused: " ++ (result.inventoryReused ? "yes" : "no"))
    }
  } catch {
  | Kuku_Ep9RawProviderArchive.RawProviderArchive(message) => {
      Js.log("KUKU EP9 RAW PROVIDER ARCHIVE FAILED: " ++ message)
      exit(1)
    }
  | Kuku_Ep9FinaleDialogue.DialogueRecovery(message) => {
      Js.log("KUKU EP9 RAW PROVIDER SOURCE VALIDATION FAILED: " ++ message)
      exit(1)
    }
  | Cinema_Backends.BackendError(message) => {
      Js.log("KUKU EP9 RAW PROVIDER BACKEND FAILED: " ++ message)
      exit(1)
    }
  }
}

main()

