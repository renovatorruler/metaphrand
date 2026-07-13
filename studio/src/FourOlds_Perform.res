/* THE FOUR OLDS audio play — the PERFORMANCE PASS. One engine turn per
   scene: read the verified audio scene + the voice cards, and tag each
   dialogue line with eleven_v3 audio tags ([sighs], [pause], [tired]...).
   THE LAW: tags are performance, text is canon — a mechanical gate strips
   the tags and rejects the pass if one word moved. Output = the per-line
   performance JSON (the maintained artifact); the renderer prefers it.
   Run: CLAUDE_STUDIO_BUDGET=5 node src/FourOlds_Perform.res.mjs <scene.txt> <out.perf.json> */

@val @scope("process") external argv: array<string> = "argv"
@module("fs") external readFileSync: (string, string) => string = "readFileSync"
@module("fs") external writeFileSync: (string, 'a) => unit = "writeFileSync"
@val @scope("Buffer") external bufferFrom: 'a => 'b = "from"

/* the tag vocabulary we trust eleven_v3 with — documented + battle-tested */
let vocab = "[whispers] [sighs] [exhales] [laughs] [chuckles] [pause] [short pause] [hesitates] [tired] [excited] [angry] [sarcastic] [curious] [warmly] [flatly] [quietly] [slowly] [deliberate] [clears throat] [swallows] [breathes]"

let stripTags = (s: string): string =>
  s
  ->Js.String2.replaceByRe(%re("/\[[a-z ]+\]\s*/gi"), "")
  ->Js.String2.replaceByRe(%re("/\s+/g"), " ")
  ->Js.String2.trim

let main = async () => {
  let src = Belt.Array.get(argv, 2)->Belt.Option.getWithDefault("")
  let out = Belt.Array.get(argv, 3)->Belt.Option.getWithDefault("")
  if src == "" || out == "" {
    Js.log("usage: node src/FourOlds_Perform.res.mjs <scene.txt> <out.perf.json>")
  } else {
    switch Write.read(Cinema_Backends.Path(src)) {
    | Error(m) => Js.log("REFUSED — " ++ m)
    | Ok(lns) => {
        let dlg = [] /* (lineIndex, who, text) */
        lns->Belt.Array.forEachWithIndex((i, l) =>
          switch l {
          | Write.Dialogue({who, text}) => Js.Array2.push(dlg, (i, who, text))->ignore
          | Write.Action(_) => ()
          }
        )
        let sceneRaw = readFileSync(src, "utf8")
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
          "- Character registers (obey them): CRICKET flat, spare, operational — " ++
          "[flatly] [pause] [quietly], almost nothing else. DUTCH precise, dry — " ++
          "[deliberate] [clears throat]. STITCH easy drawl, storyteller — [chuckles] " ++
          "[warmly] and mid-story [pause]s. GUNNY military cadence, formal at ceremony — " ++
          "[deliberate] for ritual lines, heat allowed elsewhere.\n" ++
          "- Ceremony lines (roll call, net closed) stay clean and slow: [deliberate] " ++
          "or [slowly], nothing comic.\n" ++
          "- Output format: one line per input line, exactly:\n" ++
          "NUMBER | TAGGED TEXT\n" ++
          "No commentary, no extra lines.\n\n" ++
          "THE SCENE:\n" ++
          sceneRaw ++
          "\n\nTHE DIALOGUE LINES:\n" ++
          numbered
        let answer = await Session.ask(prompt)
        writeFileSync(out ++ ".raw.txt", bufferFrom(answer)) /* forensics */
        /* ---- the gate: words are law ---- */
        let tagged = Js.Dict.empty()
        let bad = ref(0)
        answer
        ->Js.String2.split("\n")
        ->Belt.Array.forEach(line => {
          let parts = Js.String2.split(line, " | ")
          if Belt.Array.length(parts) >= 2 {
            let idx = Js.String2.trim(Belt.Array.getExn(parts, 0))
            /* the model may echo a WHO column we didn't ask for — keep every
               suffix candidate and let the gate pick the one that passes */
            let cands = Belt.Array.makeBy(Belt.Array.length(parts) - 1, k =>
              parts->Belt.Array.sliceToEnd(k + 1)->Belt.Array.joinWith(" | ", x => x)->Js.String2.trim
            )
            Js.Dict.set(tagged, idx, Obj.magic(cands))
          }
        })
        let perf = []
        dlg->Belt.Array.forEach(((i, who, orig)) => {
          let key = Belt.Int.toString(i)
          let final = switch Js.Dict.get(tagged, key) {
          | Some(cands) => {
              let cands: array<string> = Obj.magic(cands)
              switch cands->Belt.Array.getBy(t => stripTags(t) == stripTags(orig)) {
              | Some(t) => t /* tags added, words intact */
              | None => {
                  bad := bad.contents + 1
                  Js.log(
                    "GATE REJECT line " ++
                    key ++
                    "\n  want: " ++
                    stripTags(orig) ++
                    "\n  got:  " ++
                    stripTags(Belt.Array.getExn(cands, 0)),
                  )
                  orig
                }
              }
            }
          | None => orig
          }
          Js.Array2.push(
            perf,
            `{"i":${key},"role":${Js.Json.stringify(Js.Json.string(who))},"text":${Js.Json.stringify(
                Js.Json.string(final),
              )}}`,
          )->ignore
        })
        writeFileSync(
          out,
          bufferFrom(
            `{"kind":"performance","model_id":"eleven_v3","source":${Js.Json.stringify(
                Js.Json.string(src),
              )},"lines":[` ++
            perf->Belt.Array.joinWith(",", x => x) ++ `]}`,
          ),
        )
        Js.log(
          "PERFORMANCE " ++
          out ++
          " — " ++
          Belt.Int.toString(Belt.Array.length(dlg)) ++
          " lines, " ++
          Belt.Int.toString(bad.contents) ++ " gate rejects",
        )
      }
    }
    Session.close()
  }
}
main()->ignore
