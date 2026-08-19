let check = (condition, message) =>
  if !condition {
    raise(Failure(message))
  }

let expectAnchorError = (run, expectedFragment) => {
  let message = try {
    run()
    raise(Failure("expected anchor-stills validation to fail"))
  } catch {
  | Kuku_Ep9FinaleAnchorStills.AnchorStillsError(message) => message
  }
  check(Js.String2.includes(message, expectedFragment), "unexpected validation error: " ++ message)
}

let manifest = "../stories/kuku/ep9prod/finale/manifests/ep9_finale_anchor_stills.v1.json"
let result = Kuku_Ep9FinaleAnchorStills.validate(~manifestPath=manifest)

check(result.count == 12, "anchor count")
check(result.model == "nano_banana_pro", "model")
check(result.firstTakeCredits == 24.0, "first-take ceiling")
check(result.retryCredits == 24.0, "retry ceiling")
check(result.promptWordMaximum > 0 && result.promptWordMaximum <= 200, "prompt word ceiling")
check(result.referenceCount == 57, "reference count")
check(Kuku_Ep9FinaleAnchorStills.wordCount(" one\n two\tthree ") == 3, "word counter")

expectAnchorError(
  () => Kuku_Ep9FinaleAnchorStills.validate(~manifestPath=manifest ++ ".missing")->ignore,
  "cannot be read",
)

Js.log("Kuku_Ep9FinaleAnchorStillsTest: ok")
