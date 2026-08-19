let check = (condition, message) =>
  if !condition {
    raise(Failure("Kuku_Ep9C13C15PrepTest: " ++ message))
  }

check(Kuku_Ep9C13C15Prep.width == 1280, "start-frame width")
check(Kuku_Ep9C13C15Prep.height == 720, "start-frame height")
check(!Kuku_Ep9C13C15Prep.hasNativeAudio, "inputs request no native audio")
check(Kuku_Ep9C13C15Prep.providerCalls == 0, "prep makes no provider calls")
check(Kuku_Ep9C13C15Prep.creditsSpent == 0.0, "prep spends zero credits")
check(Kuku_Ep9C13C15Prep.acquisitionSeconds == 10, "route-v2 acquisition duration")
check(Kuku_Ep9C13C15Prep.c13FinalUseSeconds == 8, "C13 final use")
check(Kuku_Ep9C13C15Prep.c14FinalUseSeconds == 10, "C14 final use")
check(Kuku_Ep9C13C15Prep.c15FinalUseSeconds == 8, "C15 final use")
check(Kuku_Ep9C13C15Prep.c13DragonCount == 1, "C13 has only Furia")
check(Kuku_Ep9C13C15Prep.c14DragonCount == 1, "C14 has only Kuku")
check(Kuku_Ep9C13C15Prep.c15DragonCount == 5, "C15 preserves all five dragons")
check(Kuku_Ep9C13C15Prep.goatCountPerShot == 1, "one goat remains in each shot")
check(Kuku_Ep9C13C15Prep.glyphCountC14 == 1, "C14 uses exactly one physical BA")

Js.Console.log("Kuku_Ep9C13C15PrepTest: ok")
