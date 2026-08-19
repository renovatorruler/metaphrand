let check = (condition, message) =>
  if !condition {
    raise(Failure(message))
  }

let close = (left, right) => Js.Math.abs_float(left -. right) < 0.001

module C = Kuku_Ep9TransformationContinuity

check(C.width == 1280, "delivery width")
check(C.height == 720, "delivery height")
check(C.fps == 24, "delivery frame rate")
check(close(C.durationSeconds, 18.0), "exact animatic duration")
check(C.frameCount == 432, "exact animatic frame count")
check(C.panelCount == 6, "six continuity panels")
check(C.braceletCount == 5, "five equal bracelet inputs")
check(C.dragonCount == 5, "five dragons throughout")
check(!C.hasNativeAudio, "approval animatic is silent")
check(!C.usesRejectedA05, "rejected A05 is excluded")
check(!C.usesRejectedD02Attempt1, "rejected D02 attempt1 is excluded")
check(C.activationOrder == ["Kuku", "Furia", "Vesper", "Castor", "Leda"], "fixed cast order")
check(C.panelAt(0.0) == "FIVE EQUAL BRACELETS", "panel one")
check(C.panelAt(3.0) == "ONE WAVE, FIVE STARTS", "panel two")
check(C.panelAt(6.0) == "ALL FIVE CHANGING", "panel three")
check(C.panelAt(9.0) == "NO ONE FINISHES EARLY", "panel four")
check(C.panelAt(11.0) == "ONE SHARED FINISH PULSE", "panel five")
check(C.panelAt(14.0) == "PULSE TO WINGS TO TAKEOFF", "panel six")

/* Ignition may be sequential, but the first child cannot finish before the
   fifth starts, and all five are visibly in progress by the overlap panel. */
check(C.growthProgressAt(~dragonIndex=0, ~seconds=3.0) > 0.0, "first ignition starts")
check(close(C.growthProgressAt(~dragonIndex=4, ~seconds=3.0), 0.0), "fifth ignition may wait")
check(C.growthProgressAt(~dragonIndex=0, ~seconds=4.2) < 1.0, "first cannot finish during travel")
for index in 0 to 4 {
  check(C.growthProgressAt(~dragonIndex=index, ~seconds=6.0) > 0.0, "all five overlap")
  check(close(C.growthProgressAt(~dragonIndex=index, ~seconds=9.0), 0.80), "equal near-finish")
  check(C.growthProgressAt(~dragonIndex=index, ~seconds=10.499) < 1.0, "nobody finishes early")
  check(close(C.growthProgressAt(~dragonIndex=index, ~seconds=C.sharedFinishSeconds), 1.0), "shared finish")
}
check(C.takeoffStartsSeconds > C.sharedFinishSeconds, "takeoff follows the shared finish")

Js.Console.log("Kuku_Ep9TransformationContinuityTest: ok")
