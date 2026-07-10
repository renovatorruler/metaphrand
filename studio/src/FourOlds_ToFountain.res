/* THE FOUR OLDS — convert one engine-emitted, VERIFIED scene into a Fountain
   fragment matching this project's existing draft/ convention (colon-terminated
   cues, per screenplay-tts-colon-cues). Reads via Write.read, which verifies
   first — an unlifted or tampered scene is refused, not silently converted.
   Run: node src/FourOlds_ToFountain.res.mjs <scene.txt path> <out .fountain path> */
open Cinema_Backends

@val @scope("process") external argv: array<string> = "argv"

/* some Action lines carry an embedded "NAME (PARENTHETICAL): dialogue" or
   "NAME: dialogue" that should have been its own cue — happens when a seed
   describes an off-screen/on-screen presence (a video call, a radio) without
   being explicit enough that it still needs full dialogue treatment. Recover
   it here rather than re-spend a generation on a formatting-only fix. */
let embeddedCue = Js.Re.fromString("^([A-Z][A-Z0-9 .']{1,30}(?:\\s*\\([A-Z. ]+\\))?): (.+)$")

let fountainOf = sp =>
  switch sp {
  | Write.Dialogue({who, radio, whisper, text}) =>
    who ++ (radio ? " (RADIO)" : "") ++ (whisper ? " (WHISPER)" : "") ++ ":\n" ++ text
  | Write.Action(t) =>
    switch Js.Re.exec_(embeddedCue, t) {
    | Some(res) =>
      let caps = Js.Re.captures(res)
      switch (caps[1]->Js.Nullable.toOption, caps[2]->Js.Nullable.toOption) {
      | (Some(n), Some(d)) => n ++ ":\n" ++ d
      | _ => t
      }
    | None => t
    }
  }

let main = () => {
  let inPath = Belt.Array.get(argv, 2)->Belt.Option.getWithDefault("")
  let outPath = Belt.Array.get(argv, 3)->Belt.Option.getWithDefault("")
  if inPath == "" || outPath == "" {
    Js.log("usage: node src/FourOlds_ToFountain.res.mjs <scene.txt> <out.fountain>")
  } else {
    switch Write.read(Path(inPath)) {
    | Error(m) => Js.log("REFUSED — not production-ready: " ++ m)
    | Ok(lns) => {
        let body = lns->Belt.Array.map(fountainOf)->Belt.Array.joinWith("\n\n", x => x)
        writeText(Path(outPath), body ++ "\n")
        Js.log("wrote " ++ outPath ++ " (" ++ Belt.Int.toString(Belt.Array.length(lns)) ++ " lines)")
      }
    }
  }
}
main()
