let check = (condition, message) =>
  if !condition {
    raise(Failure(message))
  }

check(Kuku_Ep9B14Local.width == 1280, "B14 delivery width")
check(Kuku_Ep9B14Local.height == 720, "B14 delivery height")
check(Kuku_Ep9B14Local.fps == 24, "B14 delivery frame rate")
check(Kuku_Ep9B14Local.durationSeconds == 8.0, "B14 exact duration")
check(Kuku_Ep9B14Local.frameCount == 192, "B14 exact frame count")
check(!Kuku_Ep9B14Local.hasNativeAudio, "B14 remains silent")
check(Kuku_Ep9B14Local.pathOrigin == (790, 520), "all paths originate at Vesper")
check(Kuku_Ep9B14Local.gateTarget == (555, 205), "all paths terminate at the gate")
check(Kuku_Ep9B14Local.directVisibleAt(1.0), "direct candidate is initially visible")
check(!Kuku_Ep9B14Local.directVisibleAt(3.7), "direct candidate is rejected first")
check(Kuku_Ep9B14Local.highVisibleAt(4.0), "high candidate survives the first rejection")
check(!Kuku_Ep9B14Local.highVisibleAt(4.9), "high candidate is rejected separately")
check(Kuku_Ep9B14Local.chosenVisibleAt(8.0), "calm curved route remains through the end")

Js.Console.log("Kuku_Ep9B14LocalTest: ok")
