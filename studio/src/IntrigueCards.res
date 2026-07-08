// IntrigueCards — the Intrigue Builder pass, typed (doctrine: studio/INTRIGUE.md).
// A chain plants hints that read as insignificant, reveals something worth the
// wait, and each reveal opens the next question, terminating into the story's
// final reveal. The gate makes the doctrine's violations unrepresentable or
// mechanically detected.

@unboxed type sceneId = SceneId(string)
@unboxed type question = Question(string)

// Why the reveal deserves the buildup — must be declared (law 1: worth it).
type excitement =
  | Spectacle(string) // a big image or event (the ring of flags)
  | Reversal(string) // recontextualizes what came before (the couch in the crate)
  | Identity(string) // who someone really is (the mastermind)
  | Mechanism(string) // how the impossible was done (the roster)

// Law 2: plot-native chains may run in parallel; looks-unrelated chains may not.
type relation = PlotNative | LooksUnrelated

// How loud a hint is at plant time. #Insignificant plants don't make a chain
// "live"; the first #Curious (or louder) hint does.
type weight = [#Insignificant | #Curious | #Loud]

type hint = {
  scene: sceneId,
  surface: string, // what it looks like when planted — must be dismissible
  weight: weight,
}

type link = {
  hints: array<hint>,
  reveal: sceneId,
  answers: question, // the standing question this reveal closes
  opens: option<question>, // the next question; None only on a chain's last link
  excitement: excitement,
}

type chain = {
  name: string,
  relation: relation,
  links: array<link>,
  terminal: bool, // ties into the story's end-reveal window (law 4)
}

// ---- the gate ----------------------------------------------------------------

type violation = {chain: string, rule: string, detail: string}

let sceneIndex = (order: array<sceneId>, SceneId(s): sceneId) =>
  order->Belt.Array.getIndexBy(x => {
    let SceneId(o) = x
    o == s
  })

// A chain is live from its first >=Curious hint to its final reveal (law 2).
let liveInterval = (order, c: chain) => {
  let firstLoud =
    c.links
    ->Belt.Array.flatMap(l => l.hints)
    ->Belt.Array.keep(h => h.weight != #Insignificant)
    ->Belt.Array.keepMap(h => sceneIndex(order, h.scene))
    ->Belt.Array.reduce(None, (acc, i) =>
      switch acc {
      | None => Some(i)
      | Some(a) => Some(min(a, i))
      }
    )
  let lastReveal =
    c.links
    ->Belt.Array.keepMap(l => sceneIndex(order, l.reveal))
    ->Belt.Array.reduce(None, (acc, i) =>
      switch acc {
      | None => Some(i)
      | Some(a) => Some(max(a, i))
      }
    )
  switch (firstLoud, lastReveal) {
  | (Some(a), Some(b)) => Some((a, b))
  | _ => None
  }
}

let audit = (~order: array<sceneId>, ~finalWindowFrom: sceneId, chains: array<chain>) => {
  let out = []

  let fail = (c, rule, detail) => out->Js.Array2.push({chain: c, rule, detail})->ignore

  chains->Belt.Array.forEach(c => {
    // hints precede their reveal
    c.links->Belt.Array.forEach(l => {
      let ri = sceneIndex(order, l.reveal)
      l.hints->Belt.Array.forEach(h => {
        switch (sceneIndex(order, h.scene), ri) {
        | (Some(hi), Some(r)) if hi >= r =>
          fail(c.name, "hint-precedes-reveal", h.surface)
        | (None, _) => fail(c.name, "unknown-scene", h.surface)
        | (_, None) => {
            let SceneId(r) = l.reveal
            fail(c.name, "unknown-scene", r)
          }
        | _ => ()
        }
      })
    })

    // first hint of the whole chain must be quiet (law 5)
    switch c.links->Belt.Array.get(0)->Belt.Option.flatMap(l => l.hints->Belt.Array.get(0)) {
    | Some(h) if h.weight == #Loud => fail(c.name, "first-hint-too-loud", h.surface)
    | None => fail(c.name, "chain-without-hints", "first link has no hints")
    | _ => ()
    }

    // links chain: opened question == next link's answered question (law 3)
    c.links->Belt.Array.forEachWithIndex((i, l) => {
      switch (l.opens, c.links->Belt.Array.get(i + 1)) {
      | (Some(Question(q)), Some(next)) => {
          let Question(a) = next.answers
          if q != a {
            fail(c.name, "broken-chain", `opens "${q}" but next answers "${a}"`)
          }
        }
      | (None, Some(_)) => fail(c.name, "dead-link", "non-final link opens nothing")
      | (Some(Question(q)), None) if !c.terminal =>
        fail(c.name, "dangling-question", q)
      | _ => ()
      }
    })

    // terminal chains must land in the final window (law 4)
    if c.terminal {
      let lastReveal = c.links->Belt.Array.get(Belt.Array.length(c.links) - 1)
      switch (
        lastReveal->Belt.Option.flatMap(l => sceneIndex(order, l.reveal)),
        sceneIndex(order, finalWindowFrom),
      ) {
      | (Some(r), Some(w)) if r < w =>
        fail(c.name, "terminal-too-early", "last reveal before the final window")
      | _ => ()
      }
    }
  })

  // at most one looks-unrelated chain live at a time (law 2)
  let intervals =
    chains
    ->Belt.Array.keep(c => c.relation == LooksUnrelated)
    ->Belt.Array.keepMap(c => liveInterval(order, c)->Belt.Option.map(iv => (c.name, iv)))
  intervals->Belt.Array.forEachWithIndex((i, (nameA, (a1, a2))) => {
    intervals
    ->Belt.Array.sliceToEnd(i + 1)
    ->Belt.Array.forEach(((nameB, (b1, b2))) => {
      if a1 <= b2 && b1 <= a2 {
        fail(nameA, "two-unrelated-chains-live", `overlaps "${nameB}"`)
      }
    })
  })

  out
}

let report = (violations: array<violation>) =>
  switch Belt.Array.length(violations) {
  | 0 => "intrigue gate: PASS"
  | n =>
    let lines =
      violations->Belt.Array.map(v => `  [${v.chain}] ${v.rule}: ${v.detail}`)
    `intrigue gate: ${Belt.Int.toString(n)} violation(s)\n` ++ lines->Js.Array2.joinWith("\n")
  }
