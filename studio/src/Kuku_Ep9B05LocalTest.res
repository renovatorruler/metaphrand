let check = (condition, message) =>
  if !condition {
    raise(Failure(message))
  }

let close = (left, right) => Js.Math.abs_float(left -. right) < 0.001

check(Kuku_Ep9B05Local.dragonCount == 5, "exactly five source dragons")
check(Kuku_Ep9B05Local.beatAt(0.0) == 1, "first shared beat")
check(Kuku_Ep9B05Local.beatAt(3.0) == 2, "second shared beat")
check(Kuku_Ep9B05Local.beatAt(5.5) == 3, "third beat begins before camera tilt")
check(close(Kuku_Ep9B05Local.cameraTiltY(0.0), 36.0), "camera begins at planted feet")
check(close(Kuku_Ep9B05Local.cameraTiltY(5.25), 36.0), "tilt waits for third beat")
check(close(Kuku_Ep9B05Local.cameraTiltY(8.0), 0.0), "camera reaches five faces before liftoff")
check(close(Kuku_Ep9B05Local.dustRise(~seconds=0.0, ~start=0.45), 0.0), "dust starts grounded")
check(Kuku_Ep9B05Local.dustRise(~seconds=3.0, ~start=2.75) > 0.0, "second beat raises dust")
check(Kuku_Ep9B05Local.width == 1280, "delivery width")
check(Kuku_Ep9B05Local.height == 720, "delivery height")
check(Kuku_Ep9B05Local.fps == 24, "delivery frame rate")
check(Kuku_Ep9B05Local.durationSeconds == 8.0, "delivery duration")

Js.Console.log("Kuku_Ep9B05LocalTest: ok")
