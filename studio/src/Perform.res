/* The performance pass as a library: one engine turn tags a scene's
   dialogue with eleven_v3 audio tags under the words-are-law gate.
   Runners call Perform.run; the artifact is the per-line performance JSON. */

@module("fs") external readFileSync: (string, string) => string = "readFileSync"
@module("fs") external writeFileSync: (string, 'a) => unit = "writeFileSync"
@val @scope("Buffer") external bufferFrom: 'a => 'b = "from"

let vocab = "[whispers] [sighs] [exhales] [laughs] [chuckles] [pause] [short pause] [hesitates] [tired] [excited] [angry] [sarcastic] [curious] [warmly] [flatly] [quietly] [slowly] [deliberate] [clears throat] [swallows] [breathes]"

let stripTags = (s: string): string =>
  s
  ->Js.String2.replaceByRe(%re("/\[[a-z ]+\]\s*/gi"), "")
  ->Js.String2.replaceByRe(%re("/\s+/g"), " ")
  ->Js.String2.trim

/* dialogue the engine embedded inside an ACTION line ("VESS (PA): ...") —
   dialogue in every sense, so the performance law covers it too */
let embeddedRe = %re("/^([A-Z][A-Z .'#-]+?)\s*\((PA|RADIO|TV|ON TV)\):\s*(.+)$/")
let embeddedOf = (t: string): option<(string, string)> =>
  switch Js.Re.exec_(embeddedRe, t) {
  | Some(m) => {
      let g = Js.Re.captures(m)
      let who =
        Js.Nullable.toOption(Belt.Array.getExn(g, 1))
        ->Belt.Option.getWithDefault("")
        ->Js.String2.trim
      let text = Js.Nullable.toOption(Belt.Array.getExn(g, 3))->Belt.Option.getWithDefault("")
      Some((who, text))
    }
  | None => None
  }

let run = async (~scenePath: string, ~outPath: string): result<int, string> => {
  switch Write.read(Cinema_Backends.Path(scenePath)) {
  | Error(m) => Error("scene refused — " ++ m)
  | Ok(lns) => {
      let dlg = []
      lns->Belt.Array.forEachWithIndex((i, l) =>
        switch l {
        | Write.Dialogue({who, text}) => Js.Array2.push(dlg, (i, who, text))->ignore
        | Write.Action(t) =>
          switch embeddedOf(t) {
          | Some((who, text)) => Js.Array2.push(dlg, (i, who, text))->ignore
          | None => ()
          }
        }
      )
      let sceneRaw = readFileSync(scenePath, "utf8")
      let numbered =
        dlg
        ->Belt.Array.map(((i, who, text)) => Belt.Int.toString(i) ++ " | " ++ who ++ " | " ++ text)
        ->Belt.Array.joinWith("\n", x => x)
      let prompt =
        "You are the performance director for a full-cast audio drama, preparing " ++
        "dialogue for ElevenLabs eleven_v3 text-to-speech. Below is the full scene " ++
        "(for context), then its dialogue lines, numbered.\n\n" ++
        "For EACH numbered line, return the SAME text with eleven_v3 audio tags " ++
        "inserted where the performance needs them. Tags available (use ONLY these): " ++
        vocab ++
        "\n\nRULES:\n" ++
        "- THE WORDS ARE LAW. Do not add, remove, or change ANY word, punctuation " ++
        "mark, or capitalization. Tags in square brackets are the ONLY insertions allowed.\n" ++
        "- A leading parenthetical like (reading) or (approaching) is part of the text — " ++
        "keep it EXACTLY as written, and place your tags AFTER it.\n" ++
        "- 0 to 2 tags per line. Most lines take ONE tag or none. Restraint reads " ++
        "as professional; a tag on every line reads as a cartoon.\n" ++
        "- Tags mark what the VOICE does, not what the character feels: an old man " ++
        "deflecting grief gets [flatly] or [pause], never [crying].\n" ++
        "- Broadcast voices (anchors, announcers, PA) stay professionally level: " ++
        "[pause] and pace tags only, no emotional tags unless the scene demands a crack.\n" ++
        "- A line marked (WHISPER) in the cue must carry [whispers].\n" ++
        "- Ceremony and ritual lines stay clean and slow: [deliberate] or [slowly], " ++
        "nothing comic.\n" ++
        "- Obey each character's register as written in the scene; the flat ones " ++
        "stay flat ([flatly], [quietly]), the storytellers may [chuckle], the " ++
        "formal ones get [deliberate].\n" ++
        "- Output format: one line per input line, exactly:\n" ++
        "NUMBER | TAGGED TEXT\n" ++
        "No commentary, no extra lines.\n\n" ++
        "THE SCENE:\n" ++
        sceneRaw ++
        "\n\nTHE DIALOGUE LINES:\n" ++
        numbered
      let answer = await Session.ask(prompt)
      writeFileSync(outPath ++ ".raw.txt", bufferFrom(answer))
      let tagged = Js.Dict.empty()
      answer
      ->Js.String2.split("\n")
      ->Belt.Array.forEach(line => {
        let parts = Js.String2.split(line, " | ")
        if Belt.Array.length(parts) >= 2 {
          let idx = Js.String2.trim(Belt.Array.getExn(parts, 0))
          let cands = Belt.Array.makeBy(Belt.Array.length(parts) - 1, k =>
            parts->Belt.Array.sliceToEnd(k + 1)->Belt.Array.joinWith(" | ", x => x)->Js.String2.trim
          )
          Js.Dict.set(tagged, idx, Obj.magic(cands))
        }
      })
      let firstPass = Js.Dict.empty() /* idx -> accepted tagged text */
      let rejected = [] /* (i, who, orig) — model altered the words */
      dlg->Belt.Array.forEach(((i, who, orig)) => {
        let key = Belt.Int.toString(i)
        switch Js.Dict.get(tagged, key) {
        | Some(cands) => {
            let cands: array<string> = Obj.magic(cands)
            switch cands->Belt.Array.getBy(t => stripTags(t) == stripTags(orig)) {
            | Some(t) => Js.Dict.set(firstPass, key, t)
            | None => Js.Array2.push(rejected, (i, who, orig))->ignore
            }
          }
        | None => Js.Array2.push(rejected, (i, who, orig))->ignore
        }
      })
      /* one corrective retry on the rejects only — a reject is a failed
         take, not a directorial choice */
      if Belt.Array.length(rejected) > 0 {
        let redo =
          rejected
          ->Belt.Array.map(((i, who, text)) => Belt.Int.toString(i) ++ " | " ++ who ++ " | " ++ text)
          ->Belt.Array.joinWith("\n", x => x)
        let retryPrompt =
          "Your previous answer altered the words of these lines, so they were " ++
          "rejected. Tag them again. THE WORDS ARE LAW: reproduce each line " ++
          "EXACTLY as given — every word, punctuation mark, and capital — and " ++
          "insert only square-bracket audio tags (0-2 per line, same vocabulary " ++
          "as before). Output format: NUMBER | TAGGED TEXT, one per line, " ++
          "nothing else.\n\n" ++ redo
        let retry = await Session.ask(retryPrompt)
        retry
        ->Js.String2.split("\n")
        ->Belt.Array.forEach(line => {
          let parts = Js.String2.split(line, " | ")
          if Belt.Array.length(parts) >= 2 {
            let idx = Js.String2.trim(Belt.Array.getExn(parts, 0))
            let cands = Belt.Array.makeBy(Belt.Array.length(parts) - 1, k =>
              parts->Belt.Array.sliceToEnd(k + 1)->Belt.Array.joinWith(" | ", x => x)->Js.String2.trim
            )
            switch rejected->Belt.Array.getBy(((i, _, _)) => Belt.Int.toString(i) == idx) {
            | Some((_, _, orig)) =>
              switch cands->Belt.Array.getBy(t => stripTags(t) == stripTags(orig)) {
              | Some(t) => Js.Dict.set(firstPass, idx, t)
              | None => ()
              }
            | None => ()
            }
          }
        })
      }
      let perf = []
      let bad = ref(0)
      dlg->Belt.Array.forEach(((i, who, orig)) => {
        let key = Belt.Int.toString(i)
        let final = switch Js.Dict.get(firstPass, key) {
        | Some(t) => t
        | None => {
            bad := bad.contents + 1
            orig
          }
        }
        Js.Array2.push(
          perf,
          `{"i":${key},"role":${Js.Json.stringify(Js.Json.string(who))},"text":${Js.Json.stringify(
              Js.Json.string(final),
            )}}`,
        )->ignore
      })
      writeFileSync(
        outPath,
        bufferFrom(
          `{"kind":"performance","model_id":"eleven_v3","rejects":${Belt.Int.toString(
              bad.contents,
            )},"source":${Js.Json.stringify(
              Js.Json.string(scenePath),
            )},"lines":[` ++
          perf->Belt.Array.joinWith(",", x => x) ++ `]}`,
        ),
      )
      bad.contents > 0
        ? Error(Belt.Int.toString(bad.contents) ++ " gate rejects after retry")
        : Ok(Belt.Array.length(dlg))
    }
  }
}
