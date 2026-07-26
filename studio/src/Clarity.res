/* CLARITY — the confusion detector (the curiosity-not-confusion law; docs/09).
   Curiosity is a clear surface plus an open question ahead: the reader knows
   exactly what is happening and wants to know what happens next. Confusion is
   not knowing what you are looking at NOW. Intrigue lives only in the forward
   question — withheld orientation is fog, and fog fails this gate.
   Model judge on the warm Session; run on scenes, pitches, and summaries. */

type missing = Who | Where | What
type flag = {quote: string, missing: missing, reason: string}

type verdict =
  | Clear(string) /* the reader's one-sentence account of what happened */
  | Lost(string, array<flag>) /* summary attempt + where orientation broke */
  | Illegible /* the reader could not even say what happened */

let prompt = (text: string): string =>
  "You are a FIRST-TIME reader with zero context. Read this passage once, at " ++
  "reading speed. At every moment you must know three things: WHO is present, " ++
  "WHERE this is happening, and WHAT is happening.\n\n" ++
  "IMPORTANT DISTINCTION: an open question pointing FORWARD (why did she do " ++
  "that? what happens next? what is he planning?) is GOOD - that is curiosity; " ++
  "never flag it. Flag ONLY the moments where you do not know what you are " ++
  "looking at NOW - an unexplained referent, a person you cannot place, a " ++
  "location that never established itself, an event you cannot parse.\n\n" ++
  "OUTPUT FORMAT, exactly:\n" ++
  "Line 1 - SUMMARY: <one plain sentence saying what happened>, or SUMMARY: CANNOT\n" ++
  "Then either the single word CLEAR, or one line per confusion:\n" ++
  "LOST | <short exact quote from the passage where you got lost> | WHO or WHERE or WHAT | <reason, max 12 words>\n" ++
  "No other commentary.\n\nTHE PASSAGE:\n" ++ text

let parseMissing = (s: string): missing => {
  let u = Js.String2.toUpperCase(s)
  if Js.String2.includes(u, "WHO") {
    Who
  } else if Js.String2.includes(u, "WHERE") {
    Where
  } else {
    What
  }
}

let audit = async (text: string): verdict => {
  let reply = await Session.ask(prompt(text))
  let lines = Js.String2.split(reply, "\n")->Belt.Array.map(Js.String2.trim)->Belt.Array.keep(l => l != "")
  let summary =
    lines
    ->Belt.Array.getBy(l => Js.String2.startsWith(Js.String2.toUpperCase(l), "SUMMARY:"))
    ->Belt.Option.map(l => Js.String2.trim(Js.String2.sliceToEnd(l, ~from=8)))
    ->Belt.Option.getWithDefault("CANNOT")
  let flags = lines->Belt.Array.keepMap(l =>
    if Js.String2.startsWith(Js.String2.toUpperCase(l), "LOST") {
      let parts = Js.String2.split(l, "|")->Belt.Array.map(Js.String2.trim)
      switch (parts->Belt.Array.get(1), parts->Belt.Array.get(2), parts->Belt.Array.get(3)) {
      | (Some(q), Some(m), Some(r)) => Some({quote: q, missing: parseMissing(m), reason: r})
      | (Some(q), Some(m), None) => Some({quote: q, missing: parseMissing(m), reason: ""})
      | _ => None
      }
    } else {
      None
    }
  )
  if Js.String2.toUpperCase(summary) == "CANNOT" {
    Illegible
  } else if Belt.Array.length(flags) > 0 {
    Lost(summary, flags)
  } else {
    Clear(summary)
  }
}

let show = (v: verdict): string =>
  switch v {
  | Clear(s) => "CLEAR - a first-time reader says: " ++ s
  | Lost(s, flags) =>
    "LOST at " ++
    Belt.Int.toString(Belt.Array.length(flags)) ++
    " point(s) (reader's summary attempt: " ++
    s ++
    ")\n" ++
    flags->Belt.Array.joinWith("\n", f =>
      "  LOST @ \"" ++
      f.quote ++
      "\" - missing " ++
      switch f.missing {
      | Who => "WHO"
      | Where => "WHERE"
      | What => "WHAT"
      } ++
      (f.reason == "" ? "" : " - " ++ f.reason)
    )
  | Illegible => "ILLEGIBLE - the reader could not say what happened at all"
  }

/* the gate: fog fails; a clear pane passes whatever question it leaves open */
let gate = async (text: string): (bool, string) => {
  let v = await audit(text)
  switch v {
  | Clear(_) => (true, show(v))
  | Lost(_, _) | Illegible => (false, show(v))
  }
}
