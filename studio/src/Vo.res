/* See Vo.resi — the voiceover door: the performance law for author-approved
   narration. Same guarantees as Perform/Perf, different canon (a source file
   the human approved, hashed into the artifact). */

@module("fs") external readFileSync: (string, string) => string = "readFileSync"
@module("fs") external writeFileSync: (string, 'a) => unit = "writeFileSync"
@module("fs") external existsSync: string => bool = "existsSync"
@val @scope("Buffer") external bufferFrom: 'a => 'b = "from"

type response
@val external fetch: (string, 'a) => promise<response> = "fetch"
@get external statusOf: response => int = "status"
@send external arrayBuffer: response => promise<'ab> = "arrayBuffer"
@send external textOf: response => promise<string> = "text"

type performed = {i: int, text: string}
let indexOf = p => p.i

/* narration lines: every non-empty line that isn't a # comment */
let sourceLines = (raw: string): array<string> =>
  Js.String2.split(raw, "\n")
  ->Belt.Array.map(Js.String2.trim)
  ->Belt.Array.keep(l => l != "" && !Js.String2.startsWith(l, "#"))

type hashT
@module("crypto") external createHash: string => hashT = "createHash"
@send external hUpdate: (hashT, string) => hashT = "update"
@send external hDigest: (hashT, string) => string = "digest"
let hash = (s: string): string => createHash("sha256")->hUpdate(s)->hDigest("hex")

let prepare = async (~sourcePath: string, ~outPerf: string, ~direction: string): result<int, string> => {
  let raw = readFileSync(sourcePath, "utf8")
  let lines = sourceLines(raw)
  let n = Belt.Array.length(lines)
  if n == 0 {
    Error("empty source — nothing to perform")
  } else {
    let numbered =
      lines
      ->Belt.Array.mapWithIndex((i, t) => Belt.Int.toString(i) ++ " | " ++ t)
      ->Belt.Array.joinWith("\n", x => x)
    let prompt =
      "You are the performance director for a single-narrator product film, preparing " ++
      "voiceover for ElevenLabs eleven_v3 text-to-speech. Below are the narration lines, numbered.\n\n" ++
      "For EACH numbered line, return the SAME text with eleven_v3 audio tags inserted " ++
      "where the performance needs them. Tags available (use ONLY these): " ++
      Perform.vocab ++
      "\n\nRULES:\n" ++
      "- THE WORDS ARE LAW. Do not add, remove, or change ANY word, punctuation mark, " ++
      "or capitalization. Tags in square brackets are the ONLY insertions allowed.\n" ++
      "- These are long paragraph lines: 2 to 4 tags per line, placed where the register " ++
      "turns, never stacked, never one on every sentence.\n" ++
      "- Tags mark what the VOICE does, not what the narrator feels.\n" ++
      "- Output format: one line per input line, exactly:\n" ++
      "NUMBER | TAGGED TEXT\n" ++
      "No commentary, no extra lines.\n\n" ++
      "DIRECTOR'S NOTES (obey these over the default restraint):\n" ++
      direction ++
      "\n\nTHE LINES:\n" ++
      numbered
    let answer = await Session.ask(prompt)
    writeFileSync(outPerf ++ ".raw.txt", bufferFrom(answer))
    let tagged = Js.Dict.empty()
    let harvest = (reply: string) =>
      Js.String2.split(reply, "\n")->Belt.Array.forEach(line => {
        let parts = Js.String2.split(line, " | ")
        if Belt.Array.length(parts) >= 2 {
          let idx = Js.String2.trim(Belt.Array.getExn(parts, 0))
          let t = parts->Belt.Array.sliceToEnd(1)->Belt.Array.joinWith(" | ", x => x)->Js.String2.trim
          Js.Dict.set(tagged, idx, t)
        }
      })
    harvest(answer)
    let accepted = Js.Dict.empty()
    let rejected = []
    lines->Belt.Array.forEachWithIndex((i, orig) => {
      let key = Belt.Int.toString(i)
      switch Js.Dict.get(tagged, key) {
      | Some(t) =>
        if Perform.stripTags(t) == Perform.stripTags(orig) {
          Js.Dict.set(accepted, key, t)
        } else {
          Js.Array2.push(rejected, (i, orig))->ignore
        }
      | None => Js.Array2.push(rejected, (i, orig))->ignore
      }
    })
    /* one corrective retry on rejects — a reject is a failed take */
    if Belt.Array.length(rejected) > 0 {
      let redo =
        rejected
        ->Belt.Array.map(((i, t)) => Belt.Int.toString(i) ++ " | " ++ t)
        ->Belt.Array.joinWith("\n", x => x)
      let retry = await Session.ask(
        "Your previous answer altered the words of these lines; they were rejected. " ++
        "Tag them again. THE WORDS ARE LAW: reproduce each line EXACTLY — every word, " ++
        "punctuation mark, and capital — inserting only square-bracket audio tags " ++
        "(2-4 per line, same vocabulary). Output format: NUMBER | TAGGED TEXT, one per " ++
        "line, nothing else.\n\n" ++ redo,
      )
      harvest(retry)
      rejected->Belt.Array.forEach(((i, orig)) => {
        let key = Belt.Int.toString(i)
        switch Js.Dict.get(tagged, key) {
        | Some(t) =>
          if Perform.stripTags(t) == Perform.stripTags(orig) {
            Js.Dict.set(accepted, key, t)
          }
        | None => ()
        }
      })
    }
    let out = []
    let bad = ref(0)
    lines->Belt.Array.forEachWithIndex((i, orig) => {
      let key = Belt.Int.toString(i)
      let final = switch Js.Dict.get(accepted, key) {
      | Some(t) => t
      | None => {
          bad := bad.contents + 1
          orig
        }
      }
      Js.Array2.push(
        out,
        `{"i":${key},"text":${Js.Json.stringify(Js.Json.string(final))}}`,
      )->ignore
    })
    writeFileSync(
      outPerf,
      bufferFrom(
        `{"kind":"vo-performance","model_id":"eleven_v3","rejects":${Belt.Int.toString(bad.contents)},` ++
        `"source":${Js.Json.stringify(Js.Json.string(sourcePath))},` ++
        `"sourceHash":${Js.Json.stringify(Js.Json.string(hash(raw)))},"lines":[` ++
        out->Belt.Array.joinWith(",", x => x) ++ `]}`,
      ),
    )
    bad.contents > 0
      ? Error(Belt.Int.toString(bad.contents) ++ " gate rejects after retry")
      : Ok(n)
  }
}

/* the only constructor: re-run the word gate + coverage against the source */
let load = (~sourcePath: string, ~perfPath: string): result<array<performed>, string> =>
  if !existsSync(perfPath) {
    Error("NO VO PERFORMANCE — run Vo.prepare first; untagged narration does not render")
  } else {
    let raw = readFileSync(sourcePath, "utf8")
    let lines = sourceLines(raw)
    let json = Js.Json.parseExn(readFileSync(perfPath, "utf8"))
    let rejects: option<float> = Obj.magic(json)["rejects"]->Js.Nullable.toOption
    let srcHash: option<string> = Obj.magic(json)["sourceHash"]->Js.Nullable.toOption
    if rejects->Belt.Option.getWithDefault(0.0) > 0.0 {
      Error("VO GATE — the performance carries rejects; re-run Vo.prepare")
    } else if srcHash != Some(hash(raw)) {
      Error("VO GATE — the approved source changed since the performance; re-run Vo.prepare")
    } else {
      let perf: array<performed> = Obj.magic(json)["lines"]
      let err = ref(None)
      lines->Belt.Array.forEachWithIndex((i, orig) =>
        if err.contents == None {
          switch perf->Belt.Array.getBy(p => p.i == i) {
          | None => err := Some("line " ++ Belt.Int.toString(i) ++ " unperformed")
          | Some(p) =>
            if Perform.stripTags(p.text) != Perform.stripTags(orig) {
              err := Some("line " ++ Belt.Int.toString(i) ++ " words differ from the approved source")
            }
          }
        }
      )
      switch err.contents {
      | Some(m) => Error("VO GATE — " ++ m)
      | None => Ok(perf)
      }
    }
  }

let apiKey = Js.String2.trim(readFileSync("/Users/dusty/.elevenlabs_api_key", "utf8"))

let escapeRe = (s: string): string =>
  Js.String2.replaceByRe(s, %re("/[.*+?^${}()|[\]\\]/g"), "\\$&")

let tts = async (
  p: performed,
  ~voiceId: string,
  ~outMp3: string,
  ~say: array<(string, string)>=[],
  ~dict: array<(string, string)>=[],
) => {
  /* the pronunciation transform: recorded in the sidecar as the exact spoken text */
  let spoken =
    say->Belt.Array.reduce(p.text, (t, (from, to_)) =>
      Js.String2.replaceByRe(t, Js.Re.fromStringWithFlags(escapeRe(from), ~flags="g"), to_)
    )
  /* dictionary locators change pronunciation server-side; record them in the
     sidecar line so a locator change re-renders the beat */
  let dictTag =
    Belt.Array.length(dict) == 0
      ? ""
      : "\n#dict " ++ dict->Belt.Array.joinWith(",", ((id, v)) => id ++ ":" ++ v)
  let sidecarText = spoken ++ dictTag
  let sidecar = outMp3 ++ ".txt"
  let fresh = existsSync(outMp3) && existsSync(sidecar) && readFileSync(sidecar, "utf8") == sidecarText
  if fresh {
    true
  } else {
    let body = Js.Dict.empty()
    Js.Dict.set(body, "text", Js.Json.string(spoken))
    Js.Dict.set(body, "model_id", Js.Json.string("eleven_v3"))
    if Belt.Array.length(dict) > 0 {
      let locators =
        dict->Belt.Array.map(((id, v)) => {
          let o = Js.Dict.empty()
          Js.Dict.set(o, "pronunciation_dictionary_id", Js.Json.string(id))
          Js.Dict.set(o, "version_id", Js.Json.string(v))
          Js.Json.object_(o)
        })
      Js.Dict.set(body, "pronunciation_dictionary_locators", Js.Json.array(locators))
    }
    let headers = Js.Dict.empty()
    Js.Dict.set(headers, "xi-api-key", apiKey)
    Js.Dict.set(headers, "Content-Type", "application/json")
    let opts = Js.Dict.empty()
    Js.Dict.set(opts, "method", Obj.magic("POST"))
    Js.Dict.set(opts, "headers", Obj.magic(headers))
    Js.Dict.set(opts, "body", Obj.magic(Js.Json.stringify(Js.Json.object_(body))))
    let resp = await fetch(
      "https://api.elevenlabs.io/v1/text-to-speech/" ++ voiceId ++ "?output_format=mp3_44100_128",
      opts,
    )
    if statusOf(resp) == 200 {
      let ab = await arrayBuffer(resp)
      writeFileSync(outMp3, bufferFrom(ab))
      writeFileSync(sidecar, bufferFrom(sidecarText))
      true
    } else {
      let t = await textOf(resp)
      Js.log("HTTP " ++ Belt.Int.toString(statusOf(resp)) ++ " — " ++ Js.String2.slice(t, ~from=0, ~to_=160))
      false
    }
  }
}
