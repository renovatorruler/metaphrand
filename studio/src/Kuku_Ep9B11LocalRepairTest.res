let check = (condition, message) =>
  if !condition {
    raise(Failure(message))
  }

let close = (left, right) => Js.Math.abs_float(left -. right) < 0.001

check(Kuku_Ep9B11LocalRepair.goatCount == 1, "edit guarantees exactly one visible goat")
check(Kuku_Ep9B11LocalRepair.bellCount == 1, "edit preserves exactly one bell")
check(!Kuku_Ep9B11LocalRepair.nativeAudio, "local repair remains silent")
check(
  close(
    Kuku_Ep9B11LocalRepair.groundedSourceEndSeconds -.
    Kuku_Ep9B11LocalRepair.groundedSourceStartSeconds,
    Kuku_Ep9B11LocalRepair.groundedWindowSeconds,
  ),
  "grounded provider window is exact",
)
check(
  close(
    Kuku_Ep9B11LocalRepair.cleanSourceEndSeconds -.
    Kuku_Ep9B11LocalRepair.cleanSourceStartSeconds,
    Kuku_Ep9B11LocalRepair.cleanWindowSeconds,
  ),
  "accepted clean-background window is exact",
)
check(
  close(
    Kuku_Ep9B11LocalRepair.groundedWindowSeconds +.
    Kuku_Ep9B11LocalRepair.cleanWindowSeconds -.
    Kuku_Ep9B11LocalRepair.crossfadeSeconds,
    Kuku_Ep9B11LocalRepair.durationSeconds,
  ),
  "crossfade edit totals exactly six seconds",
)

let revealFrame = Belt.Float.toInt(
  Kuku_Ep9B11LocalRepair.packRevealSeconds *.
  Belt.Int.toFloat(Kuku_Ep9B11LocalRepair.fps),
)
let baseSwapEndFrame = Belt.Float.toInt(
  (Kuku_Ep9B11LocalRepair.crossfadeOffsetSeconds +.
  Kuku_Ep9B11LocalRepair.crossfadeSeconds) *.
  Belt.Int.toFloat(Kuku_Ep9B11LocalRepair.fps),
)
check(revealFrame >= Kuku_Ep9B11LocalRepair.mistOpaqueStartFrame, "A07 pack begins only after full cover")
check(revealFrame <= Kuku_Ep9B11LocalRepair.mistOpaqueEndFrame, "A07 pack appears entirely under full cover")
check(baseSwapEndFrame <= Kuku_Ep9B11LocalRepair.mistOpaqueEndFrame, "no-goat B10 plate completes before cover opens")
check(
  close(
    Kuku_Ep9B11LocalRepair.crossfadeOffsetSeconds +.
    Kuku_Ep9B11LocalRepair.crossfadeSeconds,
    Kuku_Ep9B11LocalRepair.packLiftSeconds,
  ),
  "complete cloud pocket starts rising when the hidden base swap ends",
)
check(Kuku_Ep9B11LocalRepair.packY(6.0) < Kuku_Ep9B11LocalRepair.packY(2.4), "complete A07 pocket rises after reveal")
check(Kuku_Ep9B11LocalRepair.packX(6.0) > Kuku_Ep9B11LocalRepair.packX(2.4), "rising pocket clears the gate base instead of reading as a platform")
check(Kuku_Ep9B11LocalRepair.packWidth == 700, "masked pocket width remains explicit")
check(Kuku_Ep9B11LocalRepair.packHeight == 458, "masked pocket height remains explicit")
check(Kuku_Ep9B11LocalRepair.width == 1280, "delivery width")
check(Kuku_Ep9B11LocalRepair.height == 720, "delivery height")
check(Kuku_Ep9B11LocalRepair.fps == 24, "delivery frame rate")
check(Kuku_Ep9B11LocalRepair.durationSeconds == 6.0, "delivery duration")

Js.Console.log("Kuku_Ep9B11LocalRepairTest: ok")
