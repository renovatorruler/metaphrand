/* THE FOUR OLDS through the drama gate - the proving case for
   docs/08-DRAMA_GATES.md. Runs the SAFE outline (expected: FAIL, for the
   exact reasons the author caught by hand) and the dangerous v2 spine
   (expected: PASS, or expose real remaining holes).
   Run: node src/FourOlds_DramaRun.res.mjs */
@val @scope("process") external exit: int => unit = "exit"

let main = () => {
  Js.log("=== the SAFE outline (pre-audit) - expected FAIL ===")
  let oldOk = DramaGate.run(FourOlds_SpineOld.spine)
  Js.log("")
  Js.log("=== the dangerous spine (v2) ===")
  let newOk = DramaGate.run(FourOlds_Spine.spine)
  Js.log("")
  if oldOk {
    Js.log("NOTE: the safe outline PASSED - the gate is too weak; tighten it.")
  }
  exit(newOk && !oldOk ? 0 : 1)
}
main()
