/* Ep6 build guards: every still segment must show the picture the EDL names, and
   (once a baseline exists) no duration may drift. Exits nonzero so it can gate a
   publish.  Run from studio/: node src/Kuku_VerifyEp6.res.mjs */
@val @scope("process") external exit: int => unit = "exit"

let dir = "/Users/dusty/Dev/metaphrand/stories/kuku/ep6prod"

let main = () => {
  let pic = Kuku_Verify.checkPicture(~dir, ~edlFile="ep6_edl.json")
  let dur = Kuku_Verify.checkDurations(~dir, ~tolerance=0.02)
  if pic + dur > 0 {
    Js.log("\nFAILED: " ++ Belt.Int.toString(pic) ++ " picture, " ++ Belt.Int.toString(dur) ++ " duration")
    exit(1)
  } else {
    Js.log("\nALL GUARDS PASS")
  }
}

main()
