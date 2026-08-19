/* कुकु और अक्षर — Ep7 «आ की रात», the 2-minute slice (title card + scenes 1–2).
   Run from studio/:  node src/Kuku_AssembleEp7Slice.res.mjs */
@val @scope("process") external exit: int => unit = "exit"

let main = () =>
  switch Kuku_Assemble.assembleEpisode(
    ~dir="../stories/kuku/ep7prod",
    ~edlFile="ep7_edl.json",
    ~dursFile="ep7_durs.json",
    ~outName="KUKU_EP7_V1.mp4",
  ) {
  | () => ()
  | exception Cinema_Backends.BackendError(m) => {
      Js.log("\nASSEMBLY FAILED\n" ++ m)
      exit(1)
    }
  | exception Kuku_Edl.EdlError(m) => {
      Js.log("\nEDL ERROR\n" ++ m)
      exit(1)
    }
  }

main()
