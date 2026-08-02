/* कुकु और अक्षर — screenplay -> production manifest.

   Reads a finished Hindi screenplay and emits the manifest the rest of the line
   consumes: one numbered event per spoken line (with its performance parenthetical
   kept separate, because that becomes the voice-engine tag), plus every (ध्वनि: …)
   cue tagged with the scene and the line it follows.

   Shape matches ep5_manifest.json exactly:
     {events:[{idx, scene, who, namep, text}], sfx:[{scene, after, cue}]}

   Run from studio/:
     node src/Kuku_Parse.res.mjs <screenplay.md> <out_manifest.json> */

open Cinema_Backends

@val @scope("process") external argv: array<string> = "argv"

/* Devanagari speaker label -> the roman key the voice map and take files use.
   Animals have no voice: their lines are sound effects, marked _SFX so the
   generator routes them away from TTS. */
let speakerKey = (name: string): option<string> =>
  switch name {
  | "कुकु" => Some("KUKU")
  | "फ्यूरिया" => Some("FYURIA")
  | "वैस्पर" => Some("VESPER")
  | "दादी" | "दादी माया" => Some("DADI")
  | "पापा" => Some("PAPA")
  | "मिटासुर" => Some("MITASUR")
  | "कैस्टर" => Some("CASTOR")
  | "लेडा" => Some("LEDA")
  | "सब" | "सब बच्चे" => Some("CHORUS_ALL")
  | "कालू" => Some("KALU_SFX")
  | "रीछ" => Some("REECHH_SFX")
  /* तानसेन never gets his own take — every line of his is another cast member's
     recording reused, so he is a sound cue, never a voice. */
  | "तानसेन" => Some("TANSEN_SFX")
  | _ => None
  }

let trim = Js.String2.trim

/* «दृश्य 7 — …» -> 7 */
let sceneNumber = (line: string): option<int> =>
  if Js.String2.startsWith(line, "दृश्य") {
    let rest = trim(Js.String2.sliceToEnd(line, ~from=Js.String2.length("दृश्य")))
    let digits = Js.Array2.joinWith(
      Js.String2.split(rest, "")->Belt.Array.keep(c => c >= "0" && c <= "9"),
      "",
    )
    Belt.Int.fromString(digits)
  } else {
    None
  }

/* a spoken line is «SPEAKER: (parenthetical) text» — the parenthetical is optional
   in the source but the series law requires one, so its absence is reported. */
let splitSpeaker = (line: string): option<(string, string)> =>
  switch Js.String2.indexOf(line, ":") {
  | -1 => None
  | i => {
      let name = trim(Js.String2.slice(line, ~from=0, ~to_=i))
      let rest = trim(Js.String2.sliceToEnd(line, ~from=i + 1))
      /* a name is short and has no sentence punctuation — guards against a colon
         appearing inside dialogue */
      Js.String2.length(name) > 0 && Js.String2.length(name) <= 12 ? Some((name, rest)) : None
    }
  }

let splitParenthetical = (rest: string): (option<string>, string) =>
  if Js.String2.startsWith(rest, "(") {
    switch Js.String2.indexOf(rest, ")") {
    | -1 => (None, rest)
    | j => (
        Some(trim(Js.String2.slice(rest, ~from=1, ~to_=j))),
        trim(Js.String2.sliceToEnd(rest, ~from=j + 1)),
      )
    }
  } else {
    (None, rest)
  }

/* «(ध्वनि: …)» — one cue line, possibly several sounds inside it */
let soundCue = (line: string): option<string> =>
  if Js.String2.startsWith(line, "(ध्वनि:") {
    let inner = Js.String2.sliceToEnd(line, ~from=Js.String2.length("(ध्वनि:"))
    let cut = switch Js.String2.lastIndexOf(inner, ")") {
    | -1 => inner
    | j => Js.String2.slice(inner, ~from=0, ~to_=j)
    }
    Some(trim(cut))
  } else {
    None
  }

type event = {idx: int, scene: int, who: string, namep: string, text: string}
type cue = {scene: int, after: int, cue: string}

let main = () => {
  let src = Belt.Array.get(argv, 2)
  let dst = Belt.Array.get(argv, 3)
  switch (src, dst) {
  | (Some(srcPath), Some(dstPath)) => {
      let lines = Js.String2.split(readText(Path(srcPath)), "\n")
      let events = []
      let cues = []
      let unknown = []
      let noTag = []
      let scene = ref(0)
      let idx = ref(0)

      lines->Belt.Array.forEach(raw => {
        let line = trim(raw)
        if line != "" {
          switch sceneNumber(line) {
          | Some(n) => scene := n
          | None =>
            switch soundCue(line) {
            | Some(c) => {
                let _ = Js.Array2.push(cues, {scene: scene.contents, after: idx.contents, cue: c})
              }
            | None =>
              switch splitSpeaker(line) {
              | Some((name, rest)) =>
                switch speakerKey(name) {
                | Some(who) => {
                    let (tag, text) = splitParenthetical(rest)
                    if text != "" {
                      idx := idx.contents + 1
                      if tag == None {
                        let _ = Js.Array2.push(noTag, idx.contents)
                      }
                      let _ = Js.Array2.push(
                        events,
                        {
                          idx: idx.contents,
                          scene: scene.contents,
                          who,
                          namep: tag->Belt.Option.getWithDefault(""),
                          text,
                        },
                      )
                    }
                  }
                | None =>
                  if !Belt.Array.some(unknown, u => u == name) {
                    let _ = Js.Array2.push(unknown, name)
                  }
                }
              | None => ()
              }
            }
          }
        }
      })

      let eventJson = events->Belt.Array.map(e => {
        let o = Js.Dict.empty()
        Js.Dict.set(o, "idx", Js.Json.number(Belt.Int.toFloat(e.idx)))
        Js.Dict.set(o, "scene", Js.Json.number(Belt.Int.toFloat(e.scene)))
        Js.Dict.set(o, "who", Js.Json.string(e.who))
        Js.Dict.set(o, "namep", Js.Json.string(e.namep))
        Js.Dict.set(o, "text", Js.Json.string(e.text))
        Js.Json.object_(o)
      })
      let cueJson = cues->Belt.Array.map(c => {
        let o = Js.Dict.empty()
        Js.Dict.set(o, "scene", Js.Json.number(Belt.Int.toFloat(c.scene)))
        Js.Dict.set(o, "after", Js.Json.number(Belt.Int.toFloat(c.after)))
        Js.Dict.set(o, "cue", Js.Json.string(c.cue))
        Js.Json.object_(o)
      })
      let root = Js.Dict.empty()
      Js.Dict.set(root, "events", Js.Json.array(eventJson))
      Js.Dict.set(root, "sfx", Js.Json.array(cueJson))
      writeText(Path(dstPath), Js.Json.stringifyWithSpace(Js.Json.object_(root), 1))

      /* per-speaker line counts, so the voice map can be checked before spending */
      let counts = Js.Dict.empty()
      events->Belt.Array.forEach(e =>
        Js.Dict.set(counts, e.who, Js.Dict.get(counts, e.who)->Belt.Option.getWithDefault(0) + 1)
      )
      Js.log(
        "events=" ++
        Belt.Int.toString(Belt.Array.length(events)) ++
        "  sound cues=" ++
        Belt.Int.toString(Belt.Array.length(cues)) ++
        "  scenes=" ++
        Belt.Int.toString(scene.contents),
      )
      Js.Dict.entries(counts)->Belt.Array.forEach(((k, v)) =>
        Js.log("  " ++ k ++ ": " ++ Belt.Int.toString(v))
      )
      if Belt.Array.length(unknown) > 0 {
        Js.log("\nUNRECOGNISED SPEAKER LABELS (add to speakerKey or fix the script):")
        unknown->Belt.Array.forEach(u => Js.log("  " ++ u))
      }
      if Belt.Array.length(noTag) > 0 {
        Js.log(
          "\nLINES WITH NO PERFORMANCE PARENTHETICAL (series law 2): " ++
          Js.Array2.joinWith(noTag->Belt.Array.map(Belt.Int.toString), ", "),
        )
      }
      Js.log("\nwrote " ++ dstPath)
    }
  | _ => Js.log("usage: node src/Kuku_Parse.res.mjs <screenplay.md> <out_manifest.json>")
  }
}

main()
