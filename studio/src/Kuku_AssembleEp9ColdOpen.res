/* Assemble only Episode 9's future-dream cold open: no title or credits.
   Run from studio/: node src/Kuku_AssembleEp9ColdOpen.res.mjs */

@val @scope("process") external exit: int => unit = "exit"

let dir = "../stories/kuku/ep9prod/coldopen"

let main = () => {
  try {
    let edl = Kuku_Edl.load(Cinema_Backends.Path(dir ++ "/ep9_coldopen_edl.json"))
    let durs = Kuku_Edl.loadDurs(Cinema_Backends.Path(dir ++ "/ep9_coldopen_durs.json"))
    Cinema_Backends.ensureDirPath(Cinema_Backends.Path(dir ++ "/build"))
    Cinema_Backends.ensureDirPath(Cinema_Backends.Path(dir ++ "/out"))

    switch Belt.Array.get(edl.scenes, 0) {
    | None => raise(Kuku_Edl.EdlError("cold-open EDL contains no scene"))
    | Some(scene) => {
        let missing = Kuku_Assemble.missingAssets(~dir, ~scene, ~durs)
        if Belt.Array.length(missing) > 0 {
          raise(
            Cinema_Backends.BackendError(
              "cold-open assets still missing: " ++ Js.Array2.joinWith(missing, ", "),
            ),
          )
        }
        let (sceneFile, seconds, events, segments) = Kuku_Assemble.buildScene(~dir, ~scene, ~durs)
        let output = dir ++ "/out/KUKU_EP9_COLD_OPEN_V1.mp4"
        Cinema_Backends.copyFile(Cinema_Backends.Path(sceneFile), Cinema_Backends.Path(output))
        Js.log(
          "COLD OPEN: " ++
          Js.Float.toFixedWithPrecision(seconds, ~digits=1) ++
          "s / " ++
          Belt.Int.toString(segments) ++
          " clips / " ++
          Belt.Int.toString(events) ++
          " audio events -> " ++
          output,
        )
      }
    }
  } catch {
  | Cinema_Backends.BackendError(message) => {
      Js.log("\nASSEMBLY FAILED\n" ++ message)
      exit(1)
    }
  | Kuku_Edl.EdlError(message) => {
      Js.log("\nEDL ERROR\n" ++ message)
      exit(1)
    }
  }
}

main()
