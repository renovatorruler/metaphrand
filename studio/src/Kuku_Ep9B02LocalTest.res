let check = (condition, message) =>
  if !condition {
    raise(Failure(message))
  }

let close = (left, right) => Js.Math.abs_float(left -. right) < 0.001

check(Kuku_Ep9B02Local.segmentAt(0.0) == "gate", "echo starts at the gate")
check(Kuku_Ep9B02Local.segmentAt(3.99) == "gate", "crack completes before the cut")
check(Kuku_Ep9B02Local.segmentAt(4.0) == "bell", "bell follows the gate")
check(Kuku_Ep9B02Local.segmentAt(6.0) == "chest", "closed chest is last")
check(close(Kuku_Ep9B02Local.rippleX(0.0), -.50.0), "ripple enters from frame left")
check(close(Kuku_Ep9B02Local.rippleX(2.0), 330.0), "ripple reaches the gate")
check(close(Kuku_Ep9B02Local.rippleY(2.0), 360.0), "ripple follows the tether upward")
check(close(Kuku_Ep9B02Local.bellAngle(0.0), 0.0), "bell starts at rest")
check(close(Kuku_Ep9B02Local.bellAngle(2.0), 0.0), "bell completes one swing")
check(close(Kuku_Ep9B02Local.ringOffset(0.0), 0.0), "blank ring begins centered")
check(Kuku_Ep9B02Local.width == 1280, "delivery width")
check(Kuku_Ep9B02Local.height == 720, "delivery height")
check(Kuku_Ep9B02Local.fps == 24, "delivery frame rate")
check(Kuku_Ep9B02Local.durationSeconds == 8.0, "delivery duration")

Js.Console.log("Kuku_Ep9B02LocalTest: ok")
