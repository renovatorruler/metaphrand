/* Smoke test for the primitives added to Cinema_Backends for the Python port:
   run/, readDir, ensureDirPath, removeFile, probeDuration. Cheap, no network.
   Run from studio/:  node src/Kuku_PrimCheck.res.mjs */
open Cinema_Backends

let ep5 = "/Users/dusty/Dev/metaphrand/stories/kuku/ep5prod"

let main = () => {
  /* run: exit code, stdout and stderr all come back */
  let r = run(~cmd="echo", ~args=["hello"])
  Js.log("run echo -> code=" ++ Belt.Int.toString(r.code) ++ " stdout=" ++ Js.String2.trim(r.stdout))

  let bad = run(~cmd="ffprobe", ~args=["-v", "error", "/no/such/file.mp4"])
  Js.log("run ffprobe(missing) -> nonzero=" ++ (bad.code != 0 ? "yes" : "NO (bug)"))

  /* readDir on a real dir, and on a missing one */
  let stills = readDir(Path(ep5 ++ "/stills"))
  let missing = readDir(Path(ep5 ++ "/does-not-exist"))
  Js.log(
    "readDir stills=" ++
    Belt.Int.toString(Belt.Array.length(stills)) ++
    " missing=" ++
    Belt.Int.toString(Belt.Array.length(missing)),
  )

  /* probeDuration against a file whose length we already know from the baseline */
  let Seconds(d) = probeDuration(Path(ep5 ++ "/out/KUKU_EP5_V1.mp4"))
  Js.log("probeDuration episode = " ++ Js.Float.toFixedWithPrecision(d, ~digits=6))

  /* ensureDirPath + removeFile round trip in the temp dir */
  let Path(tmp) = tempDir("prim_")
  ensureDirPath(Path(tmp ++ "/a/b"))
  let f = Path(tmp ++ "/a/b/x.txt")
  writeText(f, "x")
  let had = exists(f)
  removeFile(f)
  let gone = !exists(f)
  removeFile(f) /* second remove must be a no-op, not a throw */
  Js.log("ensureDirPath+removeFile ok=" ++ (had && gone ? "yes" : "NO (bug)"))
}

main()
