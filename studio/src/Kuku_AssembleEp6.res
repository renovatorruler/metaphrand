/* कुकु और अक्षर — Ep6 «त से तोता». Run from studio/: node src/Kuku_AssembleEp6.res.mjs

   The try/catch exists because a raised BackendError prints as a bare "Error: Error"
   through node's ESM stack formatter — the actual message (SHOT OVERFLOW, ffmpeg's
   stderr tail, SPEECH OVERLAP) sits in the payload and was being thrown away, which
   made every failure take an extra round trip to diagnose. */
@val @scope("process") external exit: int => unit = "exit"

let main = () =>
  switch Kuku_Assemble.assembleEpisode(
    ~dir="/Users/dusty/Dev/metaphrand/stories/kuku/ep6prod",
    ~edlFile="ep6_edl.json",
    ~dursFile="ep6_durs.json",
    ~outName="KUKU_EP6_V1.mp4",
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
