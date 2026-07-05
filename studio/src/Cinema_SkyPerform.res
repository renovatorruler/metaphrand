/* SKY KING — the PERFORMANCE LAYER (per-line audio tags). Reads a gated scene and,
   in ONE warm-Session call, authors an ElevenLabs v3 delivery tag for each DIALOGUE
   line (how it's performed, from the subtext), stored as <id>.performance.json —
   the maintained artifact the video reader applies. Only a verified scene is
   performed. Run: CLAUDE_STUDIO_BUDGET=2 node src/Cinema_SkyPerform.res.mjs <id> */
open Cinema_Backends

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"

@val @scope("process") external argv: array<string> = "argv"

let info = sp =>
  switch sp {
  | Write.Action(t) => ("NARRATOR", t, false)
  | Write.Dialogue({who, text, radio: _}) => (Js.String2.trim(Js.String2.toUpperCase(who)), text, true)
  }

let promptFor = lines => {
  let numbered =
    lines
    ->Belt.Array.mapWithIndex((i, sp) => {
      let (who, text, isD) = info(sp)
      Belt.Int.toString(i) ++ " [" ++ (isD ? who : "ACTION") ++ "]: " ++ text
    })
    ->Js.Array2.joinWith("\n")
  "You are a voice director prepping a table read for ElevenLabs v3 text-to-speech. Below is a numbered film scene.\n\n" ++
  "For each DIALOGUE line (one with a CHARACTER name in brackets), give ONE short v3 delivery tag in square brackets for how THAT line is performed, from the subtext. Use plain, common emotional/delivery words v3 understands: e.g. [warm], [dry], [flat], [amused], [tired], [gentle], [wry], [quietly], [under his breath], [a small laugh], [sighs], [matter-of-fact], [soft]. Keep them SUBTLE and 1-3 words. Not every line needs a strong colour - use a light one when the line is plain. Do NOT tag [ACTION] lines.\n\n" ++
  "Characters: BIRDY - gentle, warm, self-deprecating, jokes instead of complaining, never bitter, protects everyone. DEZ - dry, blunt, sore on Birdy's behalf, grumbling, loyal. TANNER - clipped, brisk, indifferent, barely present.\n\n" ++
  "Return ONLY the dialogue lines, one per line, EXACTLY in this format (index, a pipe, then the bracketed tag), nothing else:\n" ++
  "3|[warm]\n5|[dry]\n\n" ++
  "Scene:\n" ++ numbered
}

let parseTags = (raw, n) => {
  let tags = Belt.Array.make(n, "")
  raw
  ->Js.String2.splitByRe(%re("/\r?\n/"))
  ->Belt.Array.forEach(lnO =>
    switch lnO {
    | Some(ln) =>
      switch Js.Re.exec_(%re("/^(\d+)\s*\|\s*(\[[^\]]*\])/"), Js.String2.trim(ln)) {
      | Some(m) =>
        let caps = Js.Re.captures(m)
        let g = idx => Belt.Array.get(caps, idx)->Belt.Option.flatMap(Js.Nullable.toOption)
        switch (g(1), g(2)) {
        | (Some(is), Some(tag)) =>
          switch Belt.Int.fromString(is) {
          | Some(ix) =>
            if ix >= 0 && ix < n {
              Belt.Array.setExn(tags, ix, tag)
            }
          | None => ()
          }
        | _ => ()
        }
      | None => ()
      }
    | None => ()
    }
  )
  tags
}

let main = async () => {
  let id = Belt.Array.get(argv, 2)->Belt.Option.getWithDefault("")
  if id == "" {
    Js.log("usage: node src/Cinema_SkyPerform.res.mjs <scene-id>")
  } else {
    switch Write.read(Path(dir ++ "/" ++ id ++ ".scene.txt")) {
    | Error(m) => Js.log("REFUSED — scene did not verify: " ++ m)
    | Ok(lines) =>
      let raw = await Session.ask(promptFor(lines))
      let tags = parseTags(raw, Belt.Array.length(lines))
      let objs = lines->Belt.Array.mapWithIndex((i, sp) => {
        let (who, text, _isD) = info(sp)
        let d = Js.Dict.empty()
        Js.Dict.set(d, "i", Js.Json.number(Belt.Int.toFloat(i)))
        Js.Dict.set(d, "who", Js.Json.string(who))
        Js.Dict.set(d, "tag", Js.Json.string(Belt.Array.getExn(tags, i)))
        Js.Dict.set(d, "text", Js.Json.string(text))
        Js.Json.object_(d)
      })
      writeText(
        Path(dir ++ "/" ++ id ++ ".performance.json"),
        Js.Json.stringifyWithSpace(Js.Json.array(objs), 1),
      )
      let tagged = tags->Belt.Array.keep(t => t != "")->Belt.Array.length
      Js.log(
        "PERFORMANCE -> " ++
        id ++ ".performance.json (" ++
        Belt.Int.toString(tagged) ++ " tagged / " ++
        Belt.Int.toString(Belt.Array.length(lines)) ++ " lines)",
      )
    }
  }
  Session.close()
}
main()->ignore
