/* BLIND ATTRIBUTION - the voice-differentiation gate (port of
   metaphrand/blind_attribution.py; docs/04 step 4). Strip the cue, read the
   line cold, name the speaker. The model, given ONLY the voice cards as the
   key, attributes each dialogue line; we compare to the truth. High accuracy
   == distinct voices; confusions == two characters sharing one nervous
   system. Companion to Preflight: that checks the cards EXIST, this checks
   they were HONORED. Runs through Session (budget-guarded) in chunks. */

type rec_ = {idx: int, true_: string, guess: option<string>, text: string}
type result_ = {records: array<rec_>, cast: array<string>, unmapped: array<string>}

let system =
  "You are a voice-identification engine, not a writer. You are given VOICE CARDS describing how each " ++
  "character in a cast speaks - sentence shape, emotion, vocabulary, directness, tics - and then a list " ++
  "of numbered dialogue lines with the speaker's name REMOVED.\n\n" ++
  "For each line, name the SINGLE character whose voice it best matches. Judge by MANNER and VOICE - the " ++
  "shape, rhythm, diction, length, directness - NOT by the topic and NOT by who the plot would assign it " ++
  "to. If a line is generic and could be almost anyone, still pick the closest - you will be wrong often " ++
  "on generic lines, and that is exactly the signal we want.\n\n" ++
  "Return ONLY JSON: {\"calls\": [{\"line\": <int>, \"speaker\": \"<one key from the cards>\"}]}. " ++
  "Use the lowercase key shown in each card header. One call per line, no commentary."

/* the valid character keys, from the card headers (### Name - `key`) */
let keysFromCards = (cards: string): array<string> => {
  let keys = []
  let re = %re("/`([a-z][a-z0-9_]+)`/g")
  let go = ref(true)
  while go.contents {
    switch Js.Re.exec_(re, cards) {
    | Some(m) =>
      switch Js.Re.captures(m)->Belt.Array.get(1)->Belt.Option.flatMap(Js.Nullable.toOption) {
      | Some(k) =>
        if !Belt.Array.some(keys, x => x == k) {
          Js.Array2.push(keys, k)->ignore
        }
      | None => ()
      }
    | None => go := false
    }
  }
  keys
}

/* [(key, line)] for every "SPEAKER: text" dialogue line; action prose skipped.
   alias maps on-page cues (e.g. Devanagari) to card keys. */
let parseDialogue = (script: string, ~alias: Js.Dict.t<string>=Js.Dict.empty()): array<(string, string)> => {
  let out = []
  Js.String2.split(script, "\n")->Belt.Array.forEach(raw => {
    let s = Js.String2.trim(raw)
    let first = Js.String2.charAt(s, 0)
    if s != "" && !Js.String2.includes("#*>|`-", first) {
      switch Js.Re.exec_(%re("/^([^:：]{1,22}?)\s*[:：]\s*(.+)$/"), s) {
      | Some(m) => {
          let g = Js.Re.captures(m)
          let label =
            g->Belt.Array.get(1)->Belt.Option.flatMap(Js.Nullable.toOption)->Belt.Option.getWithDefault("")->Js.String2.trim
          let text0 =
            g->Belt.Array.get(2)->Belt.Option.flatMap(Js.Nullable.toOption)->Belt.Option.getWithDefault("")->Js.String2.trim
          let text = Js.String2.replaceByRe(text0, %re("/\([^)]*\)/g"), "")->Js.String2.trim
          if Js.String2.length(text) >= 2 {
            switch Js.Dict.get(alias, label) {
            | Some(key) => Js.Array2.push(out, (key, text))->ignore
            | None =>
              /* multi-word label = a slugline/note, not a cue */
              if !Js.Re.test_(%re("/\s/"), label) {
                Js.Array2.push(out, (Js.String2.toLowerCase(label), text))->ignore
              }
            }
          }
        }
      | None => ()
      }
    }
  })
  out
}

let parseCalls = (raw: string): Js.Dict.t<string> => {
  let out = Js.Dict.empty()
  let jsonText = switch Js.Re.exec_(%re("/\{[\s\S]*\}/"), raw) {
  | Some(m) =>
    Js.Re.captures(m)->Belt.Array.get(0)->Belt.Option.flatMap(Js.Nullable.toOption)->Belt.Option.getWithDefault(raw)
  | None => raw
  }
  switch Js.Json.parseExn(jsonText) {
  | json =>
    switch Js.Json.decodeObject(json)
    ->Belt.Option.flatMap(o => Js.Dict.get(o, "calls"))
    ->Belt.Option.flatMap(Js.Json.decodeArray) {
    | Some(calls) =>
      calls->Belt.Array.forEach(c =>
        switch Js.Json.decodeObject(c) {
        | Some(o) => {
            let line = Js.Dict.get(o, "line")->Belt.Option.flatMap(Js.Json.decodeNumber)
            let speaker = Js.Dict.get(o, "speaker")->Belt.Option.flatMap(Js.Json.decodeString)
            switch (line, speaker) {
            | (Some(l), Some(sp)) =>
              Js.Dict.set(out, Belt.Int.toString(Belt.Float.toInt(l)), Js.String2.toLowerCase(Js.String2.trim(sp)))
            | _ => ()
            }
          }
        | None => ()
        }
      )
    | None => ()
    }
  | exception _ => ()
  }
  out
}

let audit = async (
  ~script: string,
  ~cards: string,
  ~alias: Js.Dict.t<string>=Js.Dict.empty(),
  ~maxLines: int=120,
  ~chunk: int=24,
): result_ => {
  let cast = keysFromCards(cards)
  let pairs = parseDialogue(script, ~alias)
  let unmapped = []
  pairs->Belt.Array.forEach(((k, _)) =>
    if !Belt.Array.some(cast, c => c == k) && !Belt.Array.some(unmapped, u => u == k) {
      Js.Array2.push(unmapped, k)->ignore
    }
  )
  let judged = pairs->Belt.Array.keep(((k, _)) => Belt.Array.some(cast, c => c == k))->Belt.Array.slice(~offset=0, ~len=maxLines)
  let guesses = Js.Dict.empty()
  let n = Belt.Array.length(judged)
  let rec go = async start =>
    if start < n {
      let block = judged->Belt.Array.slice(~offset=start, ~len=chunk)
      let numbered =
        block
        ->Belt.Array.mapWithIndex((i, (_, t)) => Belt.Int.toString(start + i) ++ "\t" ++ t)
        ->Belt.Array.joinWith("\n", x => x)
      let raw = await Session.ask(
        system ++
        "\n\nVOICE CARDS (the key):\n" ++
        cards ++
        "\n\nLINES (speaker removed):\n" ++
        numbered ++ "\n\nAttribute each numbered line to one character key.",
      )
      let calls = parseCalls(raw)
      calls->Js.Dict.entries->Belt.Array.forEach(((k, v)) => Js.Dict.set(guesses, k, v))
      await go(start + chunk)
    }
  await go(0)
  let records = judged->Belt.Array.mapWithIndex((i, (true_, text)) => {
    idx: i,
    true_,
    guess: Js.Dict.get(guesses, Belt.Int.toString(i)),
    text,
  })
  {records, cast, unmapped}
}

/* records whose guess is a real cast key */
let scored = (r: result_): array<rec_> =>
  r.records->Belt.Array.keep(rc =>
    switch rc.guess {
    | Some(g) => Belt.Array.some(r.cast, c => c == g)
    | None => false
    }
  )

let accuracy = (r: result_): (int, int) => {
  let sc = scored(r)
  (sc->Belt.Array.keep(rc => rc.guess == Some(rc.true_))->Belt.Array.length, Belt.Array.length(sc))
}

/* unordered character pairs the model could not keep apart -> count */
let confusions = (r: result_): array<((string, string), int)> => {
  let counter = Js.Dict.empty()
  scored(r)->Belt.Array.forEach(rc =>
    switch rc.guess {
    | Some(g) =>
      if g != rc.true_ {
        let key = rc.true_ < g ? rc.true_ ++ "|" ++ g : g ++ "|" ++ rc.true_
        Js.Dict.set(counter, key, Js.Dict.get(counter, key)->Belt.Option.getWithDefault(0) + 1)
      }
    | None => ()
    }
  )
  counter
  ->Js.Dict.entries
  ->Belt.Array.map(((k, v)) => {
    let parts = Js.String2.split(k, "|")
    ((Belt.Array.getExn(parts, 0), Belt.Array.getExn(parts, 1)), v)
  })
  ->Belt.SortArray.stableSortBy(((_, a), (_, b)) => b - a)
}

let report = (r: result_): string => {
  let (correct, total) = accuracy(r)
  if total == 0 {
    "blind attribution: no judged lines (check the script format / alias)."
  } else {
    let pct = 100 * correct / total
    let out = [
      "blind attribution - " ++
      Belt.Int.toString(total) ++
      " lines judged, " ++
      Belt.Int.toString(correct) ++
      " correct (" ++
      Belt.Int.toString(pct) ++ "%).",
    ]
    let worst = confusions(r)->Belt.Array.slice(~offset=0, ~len=6)
    if Belt.Array.length(worst) > 0 {
      Js.Array2.push(out, "worst blur (re-voice these pairs):")->ignore
      worst->Belt.Array.forEach((((a, b), nn)) =>
        Js.Array2.push(out, "  " ++ a ++ " <-> " ++ b ++ "  x" ++ Belt.Int.toString(nn))->ignore
      )
    }
    if Belt.Array.length(r.unmapped) > 0 {
      Js.Array2.push(
        out,
        "(not judged - speakers absent from the cards: " ++ r.unmapped->Belt.Array.joinWith(", ", x => x) ++ ")",
      )->ignore
    }
    out->Belt.Array.joinWith("\n", x => x)
  }
}

/* pass if accuracy >= threshold AND no pair confused more than maxPair times */
let gate = async (
  ~script: string,
  ~cards: string,
  ~alias: Js.Dict.t<string>=Js.Dict.empty(),
  ~threshold: float=0.70,
  ~maxPair: int=3,
): (bool, string) => {
  let r = await audit(~script, ~cards, ~alias)
  let (correct, total) = accuracy(r)
  let pct = total == 0 ? 0.0 : Belt.Int.toFloat(correct) /. Belt.Int.toFloat(total)
  let worst = confusions(r)->Belt.Array.get(0)
  let blurOk = switch worst {
  | None => true
  | Some((_, nn)) => nn <= maxPair
  }
  let ok = total > 0 && pct >= threshold && blurOk
  let tag = ref(Js.Float.toFixedWithPrecision(pct *. 100.0, ~digits=0) ++ "% attributed")
  switch worst {
  | Some(((a, b), nn)) => tag := tag.contents ++ ", worst blur " ++ a ++ "<->" ++ b ++ " x" ++ Belt.Int.toString(nn)
  | None => ()
  }
  (ok, tag.contents)
}
