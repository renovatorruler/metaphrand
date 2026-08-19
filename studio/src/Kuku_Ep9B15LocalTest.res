let check = (condition, message) =>
  if !condition {
    raise(Failure(message))
  }

let close = (left, right) => Js.Math.abs_float(left -. right) < 0.001

check(Kuku_Ep9B15Local.width == 1280, "B15 delivery width")
check(Kuku_Ep9B15Local.height == 720, "B15 delivery height")
check(Kuku_Ep9B15Local.fps == 24, "B15 delivery frame rate")
check(Kuku_Ep9B15Local.durationSeconds == 10.0, "B15 exact duration")
check(Kuku_Ep9B15Local.frameCount == 240, "B15 exact frame count")
check(!Kuku_Ep9B15Local.hasNativeAudio, "B15 remains silent")
check(Kuku_Ep9B15Local.dragonCount == 5, "B15 has exactly five dragon rigs")
check(Kuku_Ep9B15Local.glyphCount == 1, "B15 has one rigid glyph")
check(Kuku_Ep9B15Local.goatCount == 1, "B15 has one stationary goat")
check(Kuku_Ep9B15Local.glyphWidth == 340, "glyph width never changes")
check(Kuku_Ep9B15Local.glyphHeight == 400, "glyph height never changes")
check(close(Kuku_Ep9B15Local.groupXAt(0.0), 0.0), "transport rig begins on its mark")
check(close(Kuku_Ep9B15Local.groupYAt(0.0), 0.0), "transport rig begins level")
check(close(Kuku_Ep9B15Local.groupXAt(10.0), -.170.0), "transport rig reaches the cloud")
check(close(Kuku_Ep9B15Local.groupYAt(10.0), -.20.0), "transport rig ends above its start")
check(Kuku_Ep9B15Local.groupYAt(5.0) > 0.0, "transport rig follows the calm curved route")

Js.Console.log("Kuku_Ep9B15LocalTest: ok")
