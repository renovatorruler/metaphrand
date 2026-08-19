let check = (condition, message) =>
  if !condition {
    raise(Failure(message))
  }

let manifest = "../stories/kuku/ep9prod/finale/manifests/ep9_finale_animatic_edl.v1.json"
let result = Kuku_Ep9FinaleAnimaticEdl.validate(~manifestPath=manifest)

check(result.beatCount == 97, "beat count")
check(result.totalSeconds == 720, "main-story duration")
check(result.paidSeconds == 370, "paid seconds")
check(result.localMotionSeconds == 160, "local-motion seconds")
check(result.twoPointFiveDSeconds == 121, "2.5D seconds")
check(result.reuseSeconds == 69, "reuse seconds")
check(result.paidShotCount == 45, "paid-shot ID coverage")
check(result.placeholderCount == 82, "accepted-asset placeholders after eleven paid and four local motion clips")
check(Kuku_Ep9FinaleAnimaticEdl.parseTimecode("14:15", "test") == 855, "timecode parser")
check(
  Kuku_Ep9FinaleAnimaticEdl.approvedAssetPath(
    ~manifestPath=manifest,
    ~relativePath="../clips/C01.mp4",
  ),
  "approved paid-clip path",
)
check(
  !Kuku_Ep9FinaleAnimaticEdl.approvedAssetPath(
    ~manifestPath=manifest,
    ~relativePath="../../../../outside/C01.mp4",
  ),
  "unapproved path rejection",
)

let manifestV2 = "../stories/kuku/ep9prod/finale/manifests/ep9_finale_animatic_edl.v2.json"
let resultV2 = Kuku_Ep9FinaleAnimaticEdlV2.validate(~manifestPath=manifestV2)

check(resultV2.beatCount == 97, "v2 beat count")
check(resultV2.totalSeconds == 720, "v2 main-story duration")
check(resultV2.paidSeconds == 242, "v2 paid final seconds")
check(resultV2.localMotionSeconds == 275, "v2 local-motion seconds")
check(resultV2.twoPointFiveDSeconds == 121, "v2 2.5D seconds")
check(resultV2.reuseSeconds == 82, "v2 reuse seconds")
check(resultV2.paidShotCount == 28, "v2 paid-shot coverage")
check(resultV2.routeShotCount == 45, "v2 route ID coverage")
check(resultV2.convertedSeconds == 128, "v2 paid-to-local/reuse conversion")
check(resultV2.paidAcquisitionSeconds == 266, "v2 paid acquisition backing")
check(resultV2.placeholderCount == 82, "v2 accepted-asset placeholders after eleven paid and four local motion clips")
check(Kuku_Ep9FinaleAnimaticEdlV2.isV2(~manifestPath=manifestV2), "v2 detection")
check(!Kuku_Ep9FinaleAnimaticEdlV2.isV2(~manifestPath=manifest), "v1 detection")

Js.log("Kuku_Ep9FinaleAnimaticEdlTest: ok")
