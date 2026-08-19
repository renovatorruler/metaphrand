let check = (condition, message) =>
  if !condition {
    raise(Failure(message))
  }

let close = (left, right) => Js.Math.abs_float(left -. right) < 0.001

check(
  close(Kuku_Ep9B01Local.rippleRadius(~frame=12, ~startFrame=12), 0.0),
  "first ripple begins at the nest",
)
check(
  close(Kuku_Ep9B01Local.rippleRadius(~frame=36, ~startFrame=12), 108.0),
  "first ripple expands deterministically",
)
check(
  Kuku_Ep9B01Local.rippleActive(~frame=120, ~startFrame=12),
  "ripple crosses the sky during the shot",
)
check(
  !Kuku_Ep9B01Local.rippleActive(~frame=220, ~startFrame=12),
  "ripple clears before the final hold",
)
check(Kuku_Ep9B01Local.width == 1280, "delivery width")
check(Kuku_Ep9B01Local.height == 720, "delivery height")
check(Kuku_Ep9B01Local.fps == 24, "delivery frame rate")
check(Kuku_Ep9B01Local.durationSeconds == 10.0, "delivery duration")

Js.Console.log("Kuku_Ep9B01LocalTest: ok")
