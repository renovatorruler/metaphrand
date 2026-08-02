/* Run both Ep5 build guards. Exits nonzero if either fails, so it can gate a
   publish.  Run from studio/:  node src/Kuku_VerifyEp5.res.mjs */

@val @scope("process") external exit: int => unit = "exit"

let dir = "/Users/dusty/Dev/metaphrand/stories/kuku/ep5prod"

let main = () => {
  let pic = Kuku_Verify.checkPicture(~dir, ~edlFile="ep5_edl.json")
  /* one frame at 24fps is 0.042s; anything under that is container rounding */
  let dur = Kuku_Verify.checkDurations(~dir, ~tolerance=0.02)
  if pic + dur > 0 {
    Js.log("\nFAILED: " ++ Belt.Int.toString(pic) ++ " picture, " ++ Belt.Int.toString(dur) ++ " duration")
    exit(1)
  } else {
    Js.log("\nALL GUARDS PASS")
  }
}

main()
