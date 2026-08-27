/* PromptGate.res — the positive-description law, enforced.

   Author's hard rule (2026-08-27): a generation prompt names what IS on screen,
   never what is absent. The models in use have exactly one text channel —
   verified with `higgsfield model get` across seedance_2_0, seedance_2_0_mini,
   seedance_2_5 and nano_banana_pro: a `prompt` field and delivery knobs, with
   zero negative-prompt parameter — so a prohibition is just its noun smuggled
   into the scene behind a weak word ("no arch" still says "arch"). The session
   that produced this rule watched CAMERA draw a tripod, MARKED FLAGSTONE carve
   runes, and BELL ARCH build an arch the screenplay never had; each was fixed
   by describing what is there, and each fix held.

   Same shape as Gate.craftlint for scene prose: renderer output must pass here
   before it can reach a model. `scan` reports offending lines; `pass` is wired
   into every renderer, so text that forbids is unrenderable — a violation is a
   loud failure before any credit is spent, at latest when `lint:prompts` runs
   in the test chain. Fix a defect by changing state or description, never by
   adding a prohibition — if the gate blocks you, the answer is a better noun. */

let banned = Js.Re.fromStringWithFlags(
  "\\b(?:no|not|never|none|nothing|nobody|nowhere|neither|nor|cannot|can't|don't|doesn't|isn't|aren't|wasn't|won't|wouldn't|couldn't|shouldn't|mustn't|avoid|avoids|avoiding|without|except|forbid|forbids|forbidden|prohibited)\\b",
  ~flags="i",
)

let scan = (text: string): array<string> =>
  Js.Array2.reduce(Js.String2.split(text, "\n"), (acc, line) =>
    switch Js.String2.match_(line, banned) {
    | Some(m) =>
      switch m[0] {
      | Some(tok) => Js.Array2.concat(acc, ["[" ++ tok ++ "] " ++ Js.String2.trim(line)])
      | None => acc
      }
    | None => acc
    }
  , [])

let pass = (~which: string, text: string): string => {
  let bad = scan(text)
  if Js.Array2.length(bad) > 0 {
    Js.Exn.raiseError(
      "PromptGate: " ++
      which ++
      " forbids instead of describing — name what IS on screen:\n" ++
      Js.Array2.joinWith(bad, "\n"),
    )
  }
  text
}
