let check = (condition, message) =>
  if !condition {
    raise(Failure(message))
  }

let close = (left, right) => Js.Math.abs_float(left -. right) < 0.001

check(close(Kuku_Ep9C03Local.xOffset(0.0), 0.0), "starts at accepted frame position")
check(close(Kuku_Ep9C03Local.yOffset(0.0), 0.0), "starts grounded")
check(close(Kuku_Ep9C03Local.xOffset(2.0), 0.0), "the local puppet does not slide sideways")
check(
  close(Kuku_Ep9C03Local.yOffset(2.85), -.Kuku_Ep9C03Local.maxHopPixels),
  "one low apex",
)
check(Kuku_Ep9C03Local.maxHopPixels < 29.0, "hop remains below four percent of frame height")
check(close(Kuku_Ep9C03Local.yOffset(3.5), 0.0), "returns to the ground")
check(close(Kuku_Ep9C03Local.yOffset(4.2), 0.0), "landing recovery ends grounded")
check(close(Kuku_Ep9C03Local.yOffset(8.0), 0.0), "final hold stays grounded")
check(close(Kuku_Ep9C03Local.xOffset(8.0), 0.0), "does not collide with Vesper")

Js.Console.log("Kuku_Ep9C03LocalTest: ok")
