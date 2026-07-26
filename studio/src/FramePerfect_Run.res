/* FRAME PERFECT through the drama gate — checkpoint 1 artifact.
   Run: node src/FramePerfect_Run.res.mjs */
@val @scope("process") external exit: int => unit = "exit"

let main = () => {
  let ok = DramaGate.run(FramePerfect_Spine.spine)
  exit(ok ? 0 : 1)
}
main()
