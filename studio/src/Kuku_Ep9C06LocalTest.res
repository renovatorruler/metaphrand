let check = (condition, message) =>
  if !condition {
    raise(Failure(message))
  }

let close = (left, right) => Js.Math.abs_float(left -. right) < 0.001

check(Kuku_Ep9C06Local.pawCount == 5, "five equal paw contacts")
check(Kuku_Ep9C06Local.waveCount == 5, "five distinct wave patterns")
check(Kuku_Ep9C06Local.waveIndexAt(2.0) == 0, "no wave before all paws arrive")
check(Kuku_Ep9C06Local.waveIndexAt(2.36) == 1, "first contact wave")
check(Kuku_Ep9C06Local.waveIndexAt(4.5) == 5, "all five waves remain visible")
check(close(Kuku_Ep9C06Local.entryProgress(0.0), 0.0), "paws start outside the ring")
check(close(Kuku_Ep9C06Local.entryProgress(2.0), 1.0), "all paws reach equal contacts")
check(Kuku_Ep9C06Local.ringRadius == 190, "blank ring geometry is fixed")
check(Kuku_Ep9C06Local.width == 1280, "delivery width")
check(Kuku_Ep9C06Local.height == 720, "delivery height")
check(Kuku_Ep9C06Local.fps == 24, "delivery frame rate")
check(Kuku_Ep9C06Local.durationSeconds == 10.0, "delivery duration")

Js.Console.log("Kuku_Ep9C06LocalTest: ok")
