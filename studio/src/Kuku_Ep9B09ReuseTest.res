let check = (condition, message) =>
  if !condition {
    raise(Failure(message))
  }

let close = (left, right) => Js.Math.abs_float(left -. right) < 0.001

check(Kuku_Ep9B09Reuse.sourceCount == 2, "two accepted flight sources")
check(Kuku_Ep9B09Reuse.speedFactor > 1.0, "second lap is visibly faster")
check(close(Kuku_Ep9B09Reuse.runningTime(~retimed=2.2, ~crossfade=0.4), 4.0), "edit is exactly four seconds")
check(Kuku_Ep9B09Reuse.width == 1280, "delivery width")
check(Kuku_Ep9B09Reuse.height == 720, "delivery height")
check(Kuku_Ep9B09Reuse.fps == 24, "delivery frame rate")
check(Kuku_Ep9B09Reuse.durationSeconds == 4.0, "delivery duration")

Js.Console.log("Kuku_Ep9B09ReuseTest: ok")
