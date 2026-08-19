@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external exitProcess: int => unit = "exit"
@module("node:path") external resolvePath: string => string = "resolve"

let main = () =>
  switch argv->Belt.Array.sliceToEnd(2) {
  | [budgetArgument, spendArgument] =>
    try {
      Kuku_Ep9FinaleBudget.validate(
        ~budgetPath=resolvePath(budgetArgument),
        ~spendPath=resolvePath(spendArgument),
      )->Kuku_Ep9FinaleBudget.printResult
    } catch {
    | Kuku_Ep9FinaleBudget.BudgetError(message) => {
        Js.Console.error("KUKU EP9 FINALE BUDGET ERROR: " ++ message)
        exitProcess(1)
      }
    }
  | _ => {
      Js.Console.error(
        "usage: node src/Kuku_Ep9FinaleBudgetCli.res.mjs <budget.json> <spend-ledger.json>",
      )
      exitProcess(2)
    }
  }

main()
