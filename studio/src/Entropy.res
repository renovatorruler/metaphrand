/* THE ENTROPY ENGINE (general, meta-layer). A generator regresses to the MODE of
   every open variable and stacks those peaks into the most AVERAGE output. This
   exposes a task's open SLOTS and, for each, the model's own CLICHE plus off-modal
   but COHERENT alternatives (a category-swap, not noise) - so the director can
   knock variables off-center BEFORE anything is generated: perturb high, execute
   normal. Domain-agnostic; the caller supplies the task (a scene, an image, audio).
   Run: CLAUDE_STUDIO_BUDGET=2 node src/Entropy.res.mjs "<task>" */

@val @scope("process") external argv: array<string> = "argv"

let proposePrompt = task =>
  "You are an ENTROPY ENGINE fighting a generator's regression to the mean. A generator fills every open variable with its single most likely (modal, cliche) value, and those peaks stack into the most AVERAGE version of the task. Your job is to expose that, so a human can knock variables off-center.\n\n" ++
  "TASK:\n" ++ task ++ "\n\n" ++
  "List the 5-8 key OPEN VARIABLES (slots) this task leaves underspecified - the places a generator quietly defaults. INCLUDE any choice already in the task that is itself a cliche. For EACH slot give:\n" ++
  "- MODE: the cliche value a generator defaults to (name it honestly, even if it's the current choice)\n" ++
  "- OFF: 3-4 off-modal alternatives that are NON-obvious but still fully COHERENT with the story - a category-swap, not random noise (like a story's challenger going human -> alien, then just a Martian). A few words each.\n\n" ++
  "Format EXACTLY, one block per slot, nothing else:\n" ++
  "SLOT: <short name>\n" ++
  "MODE: <the cliche>\n" ++
  "OFF: <a> / <b> / <c> / <d>\n"

let main = async () => {
  let task = Belt.Array.get(argv, 2)->Belt.Option.getWithDefault("")
  if task == "" {
    Js.log("usage: node src/Entropy.res.mjs \"<task>\"")
  } else {
    let raw = await Session.ask(proposePrompt(task))
    Js.log(raw)
  }
  Session.close()
}
main()->ignore
