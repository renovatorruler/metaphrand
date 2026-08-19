/* Downstream guard for hosting and shot generation.

   A cleared screenplay is usable only together with its receipt.  This command
   verifies every receipt hash, validates the bound backlog, and reruns the
   current physical evaluator.  A copied, stale, or partially written Markdown
   file therefore cannot become a production input by itself. */

open Cinema_Backends

@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external exit: int => unit = "exit"
@module("node:path") external dirname: string => string = "dirname"
@module("node:path") external resolve2: (string, string) => string = "resolve"

let receiptString = (receipt: Js.Dict.t<Js.Json.t>, key: string): string =>
  switch Js.Dict.get(receipt, key)->Belt.Option.flatMap(Js.Json.decodeString) {
  | Some(value) if Js.String2.length(value) > 0 => value
  | _ => raise(Drakosha_Spatial.SpatialError("release receipt: missing nonempty string '" ++ key ++ "'"))
  }

let requireEqual = (label, expected, actual) =>
  if expected != actual {
    raise(
      Drakosha_Spatial.SpatialError(
        "release receipt: " ++ label ++ " mismatch; expected " ++ expected ++ " but found " ++ actual,
      ),
    )
  }

let main = () =>
  switch (Belt.Array.get(argv, 2), Belt.Array.get(argv, 3), Belt.Array.get(argv, 4)) {
  | (Some(registryArgument), Some(manifestArgument), Some(screenplayArgument)) =>
    try {
      let registryPath = Drakosha_OutputSafety.absolutePath(registryArgument)
      let manifestPath = Drakosha_OutputSafety.absolutePath(manifestArgument)
      let screenplayPath = Drakosha_OutputSafety.absolutePath(screenplayArgument)
      let receiptPath = screenplayPath ++ ".receipt.json"
      let registryRaw = readText(Path(registryPath))
      let manifestRaw = readText(Path(manifestPath))
      let screenplay = readText(Path(screenplayPath))
      let receiptRaw = readText(Path(receiptPath))
      let registry = Drakosha_Spatial.decodeRegistry(registryRaw)
      let manifest = Drakosha_Spatial.decodeManifest(manifestRaw)
      let backlogPath = resolve2(dirname(manifestPath), manifest.backlog.path)
      let backlogRaw = readText(Path(backlogPath))
      Drakosha_Spatial.validateBacklogRaw(~manifest, ~raw=backlogRaw)
      let receipt = switch Js.Json.parseExn(receiptRaw)->Js.Json.decodeObject {
      | Some(object) => object
      | None => raise(Drakosha_Spatial.SpatialError("release receipt: expected a JSON object"))
      }
      if receiptString(receipt, "schema") != "drakosha.physical-release-receipt/v1" || receiptString(receipt, "preflight") != "PASS" {
        raise(Drakosha_Spatial.SpatialError("release receipt: unsupported schema or non-PASS verdict"))
      }
      requireEqual("screenplay hash", receiptString(receipt, "screenplaySha256"), Drakosha_Spatial.sha256(screenplay))
      requireEqual("registry hash", receiptString(receipt, "registrySha256"), Drakosha_Spatial.sha256(registryRaw))
      requireEqual("manifest hash", receiptString(receipt, "manifestSha256"), Drakosha_Spatial.sha256(manifestRaw))
      requireEqual("backlog hash", receiptString(receipt, "backlogSha256"), Drakosha_Spatial.sha256(backlogRaw))
      let evaluation = Drakosha_Spatial.evaluate(~registry, ~manifest, ~screenplay)
      if Drakosha_Spatial.hasBlockers(evaluation) {
        raise(Drakosha_Spatial.SpatialError("release receipt matches files, but the current evaluator reports blocking findings"))
      }
      /* Detect replacements during the verification window. Downstream jobs
         must still invoke this verifier in-process/immediately before use; a
         path can never be made immutable by a standalone check. */
      requireEqual("screenplay changed during verification", Drakosha_Spatial.sha256(screenplay), readText(Path(screenplayPath))->Drakosha_Spatial.sha256)
      requireEqual("receipt changed during verification", Drakosha_Spatial.sha256(receiptRaw), readText(Path(receiptPath))->Drakosha_Spatial.sha256)
      requireEqual("registry changed during verification", Drakosha_Spatial.sha256(registryRaw), readText(Path(registryPath))->Drakosha_Spatial.sha256)
      requireEqual("manifest changed during verification", Drakosha_Spatial.sha256(manifestRaw), readText(Path(manifestPath))->Drakosha_Spatial.sha256)
      requireEqual("backlog changed during verification", Drakosha_Spatial.sha256(backlogRaw), readText(Path(backlogPath))->Drakosha_Spatial.sha256)
      Js.log("VERIFIED PRODUCTION-CLEARED SCREENPLAY -> " ++ screenplayPath)
    } catch {
    | Drakosha_Spatial.SpatialError(message) => {
        Js.log("RELEASE VERIFICATION FAILED: " ++ message)
        exit(1)
      }
    | Js.Exn.Error(error) => {
        Js.log(
          "RELEASE VERIFICATION ERROR: " ++
          Js.Exn.message(error)->Belt.Option.getWithDefault("unknown JavaScript error"),
        )
        exit(2)
      }
    }
  | _ => {
      Js.log(
        "usage: node src/Drakosha_VerifyRelease.res.mjs <registry.json> <manifest.json> <cleared-screenplay.md>",
      )
      exit(2)
    }
  }

main()
