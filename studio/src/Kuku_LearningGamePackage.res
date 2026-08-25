@module("fs") external readText: (string, string) => string = "readFileSync"
@module("fs") external writeText: (string, string, string) => unit = "writeFileSync"
@send external replaceAll: (string, string, string) => string = "replaceAll"
@send external includes: (string, string) => bool = "includes"

let logicSource = "src/Kuku_LearningGameLogic.res.mjs"
let clientSource = "src/Kuku_LearningGameClient.res.mjs"
let logicTarget = "../stories/kuku/game/logic.js"
let clientTarget = "../stories/kuku/game/assets/game.js"

let exportBlock = `export {
  meta ,
  setup ,
  validateAction ,
  applyAction ,
  isGameOver ,
  viewFor ,
}
`

let directLogic = readText(logicSource, "utf8")
  ->replaceAll("function setup(", "export function setup(")
  ->replaceAll("function validateAction(", "export function validateAction(")
  ->replaceAll("function applyAction(", "export function applyAction(")
  ->replaceAll("function isGameOver(", "export function isGameOver(")
  ->replaceAll("function viewFor(", "export function viewFor(")
  ->replaceAll("var meta =", "export const meta =")
  ->replaceAll(exportBlock, "")

if includes(directLogic, "export {") || !includes(directLogic, "export const meta =") ||
  !includes(directLogic, "export function setup(") {
  raise(Failure("could not normalize the ReScript rules shim to direct ESM exports"))
}

writeText(logicTarget, directLogic, "utf8")
writeText(clientTarget, readText(clientSource, "utf8"), "utf8")
Js.log("Kuku browser artifacts packaged from ReScript sources")

