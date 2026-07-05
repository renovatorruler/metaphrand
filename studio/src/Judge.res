let prompt = (text: string): string =>
  "You are a ruthless line editor hunting AI-prose tells. Flag ONLY these three, the ones a regex can't see. When in doubt, flag.\n\n" ++
  "- comma-drip: meaning rationed into a chain of short comma-separated fragments for weight or false suspense, instead of a plain sentence. e.g. \"Forty-one people, a church group, the wrong neighborhood, all gone.\"\n" ++
  "- forced-triad: three parallel items grouped mainly for rhythm. e.g. \"innovation, inspiration, and insight.\"\n" ++
  "- arranged-for-effect: a sentence bent into a shape (antithesis, reversal, withholding) for impact instead of plainly stating the fact. e.g. \"Twenty-one years on one side of the door; the refill on the other.\"\n\n" ++
  "Output one label per tell present (comma-drip, forced-triad, or arranged-for-effect), one per line, nothing else. If none are present, output exactly: CLEAN\n\n" ++
  "PROSE:\n" ++ text

let parseKind = (line: string): option<Gate.violation> => {
  let l = Js.String2.toLowerCase(line)
  if Js.String2.includes(l, "comma-drip") {
    Some(Gate.CommaDrip)
  } else if Js.String2.includes(l, "forced-triad") {
    Some(Gate.ForcedTriad)
  } else if Js.String2.includes(l, "arranged-for-effect") {
    Some(Gate.ArrangedForEffect)
  } else {
    None
  }
}

let language = async (text: string): array<Gate.violation> => {
  let reply = await Session.ask(prompt(text))
  Js.String2.split(reply, "\n")->Belt.Array.keepMap(parseKind)
}

/* one prompt per concept gate; None means "not built yet, auto-pass, no call". */
let conceptPrompt = (gate: Process.conceptGate, text: string): option<string> =>
  switch gate {
  | Drama =>
    Some(
      "You are a story editor in the David Mamet tradition. Judge whether this scene has a DRAMATIC ENGINE: a character actively trying to get something specific FROM ANOTHER character in the scene, meeting resistance, and the scene shifting as a result. Prose that only describes situation, backstory, or how people feel is NOT drama.\n" ++
      "FLAG if no one is actively pursuing anything against opposition. PASS if there is a discernible want/wall/turn; on a genuine close call, PASS.\n" ++
      "Example: \"Ray and Sam are brothers who run a garage and worry about money\" -> FLAG (nobody is doing anything). \"Ray blocks the door and demands the keys; Sam throws them out the window\" -> PASS.\n\n" ++
      "Reply with exactly PASS, or: FLAG: <one short reason>.\n\nSCENE:\n" ++ text,
    )
  | HumanReaction | Heart | Structure | SecretsBuried | Cultural => None
  }

let concept = async (gate: Process.conceptGate, text: string): option<Process.reasonText> =>
  switch conceptPrompt(gate, text) {
  | None => None
  | Some(p) =>
    let reply = Js.String2.trim(await Session.ask(p))
    if Js.String2.startsWith(Js.String2.toLowerCase(reply), "pass") {
      None
    } else {
      let reason = switch Js.String2.indexOf(reply, ":") {
      | -1 => reply
      | i => Js.String2.sliceToEnd(reply, ~from=i + 1)->Js.String2.trim
      }
      Some(Process.ReasonText(reason))
    }
  }
