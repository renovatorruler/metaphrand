/* The only public Scene 1 generation boundary. All provider helpers, prompts,
   receipt writers, and stage functions remain private to the implementation. */

exception FlowError(string)

let runStage: (~manifestPath: string, ~stage: string, ~go: bool) => unit
