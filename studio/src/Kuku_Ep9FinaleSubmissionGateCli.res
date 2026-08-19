@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external exitProcess: int => unit = "exit"
@module("node:path") external resolvePath: string => string = "resolve"

let numberArgument = (value, label) =>
  switch Belt.Float.fromString(value) {
  | Some(number) => number
  | None => {
      Js.Console.error(label ++ " must be a number")
      exitProcess(2)
      0.0
    }
  }

switch argv->Belt.Array.sliceToEnd(2) {
| [
    routeArgument,
    sourceArgument,
    budgetArgument,
    spendArgument,
    targetId,
    model,
    variantArgument,
    durationArgument,
    quoteArgument,
    promptSha256,
    startFrameSha256,
  ] =>
  try {
    let request: Kuku_Ep9FinaleSubmissionGate.request = {
      targetId,
      model,
      variant: variantArgument == "-" ? None : Some(variantArgument),
      durationSeconds: numberArgument(durationArgument, "duration"),
      quoteCredits: numberArgument(quoteArgument, "exact quote"),
      promptSha256,
      startFrameSha256,
    }
    Kuku_Ep9FinaleSubmissionGate.authorize(
      ~routePath=resolvePath(routeArgument),
      ~sourcePath=resolvePath(sourceArgument),
      ~budgetPath=resolvePath(budgetArgument),
      ~spendPath=resolvePath(spendArgument),
      ~request,
    )
    ->Kuku_Ep9FinaleSubmissionGate.printResult
  } catch {
  | Kuku_Ep9FinaleSubmissionGate.SubmissionGateError(message) => {
      Js.Console.error("KUKU EP9 SUBMISSION BLOCKED: " ++ message)
      exitProcess(1)
    }
  }
| _ => {
    Js.Console.error(
      "usage: node src/Kuku_Ep9FinaleSubmissionGateCli.res.mjs " ++
      "<route-v2.json> <paid-shots-v1.json> <budget-v2.json> <live-spend.json> " ++
      "<target-id> <model> <variant-or--> <duration-seconds> <exact-quote-credits> " ++
      "<prompt-sha256> <start-frame-sha256>",
    )
    exitProcess(2)
  }
}
