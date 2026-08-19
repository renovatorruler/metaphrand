let check = (condition, message) =>
  if !condition {
    raise(Failure(message))
  }

check(Kuku_Ep9C12Local.wingMarkCount == 5, "one fast rhythm mark for each dragon")
check(Kuku_Ep9C12Local.rishiCount == 1, "accepted crop contains exactly one Rishi")
check(Kuku_Ep9C12Local.flyingDragonCount == 5, "accepted B09 panel preserves all five flyers")
check(!Kuku_Ep9C12Local.nativeAudio, "local editorial insert remains silent")
check(Kuku_Ep9C12Local.rishiPanelWidth + Kuku_Ep9C12Local.flightPanelWidth == 1280, "panels fill delivery width exactly")
check(Kuku_Ep9C12Local.staffPulseSeconds > Kuku_Ep9C12Local.wingPulseSeconds, "staff remains slower than wings")
check(Kuku_Ep9C12Local.pulseCount(~duration=3.0, ~period=1.5) == 2, "two slow staff pulses")
check(Kuku_Ep9C12Local.pulseCount(~duration=3.0, ~period=0.5) == 6, "six fast wing pulses")
check(Kuku_Ep9C12Local.width == 1280, "delivery width")
check(Kuku_Ep9C12Local.height == 720, "delivery height")
check(Kuku_Ep9C12Local.fps == 24, "delivery frame rate")
check(Kuku_Ep9C12Local.durationSeconds == 3.0, "delivery duration")

Js.Console.log("Kuku_Ep9C12LocalTest: ok")
