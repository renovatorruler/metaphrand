/* SlopScore v0.1 — the miner's first instruments (docs/10 enforcement map §2).
   Scores a prose file against the raw lexicons + mechanical metrics.
   Usage: node src/SlopScore.res.mjs <file1> <file2> ... */

@module("fs") external readFileSync: (string, string) => string = "readFileSync"
@val @scope("process") external argv: array<string> = "argv"
@val @scope("JSON") external parseJson: string => 'a = "parse"

let rawDir = "/Users/dusty/dev/metaphrand/docs/ai-markers/raw"

/* lexicons */
let antislop: array<(string, float)> = parseJson(readFileSync(rawDir ++ "/slop_phrase_prob_adjustments.json", "utf8"))
let forensicsWords: array<array<string>> = parseJson(readFileSync(rawDir ++ "/slop-forensics_main_data_slop_list.json", "utf8"))
let ngrams: array<string> = parseJson(readFileSync(rawDir ++ "/antislop-vllm_main_banlists_banned_ngrams.json", "utf8"))
let nxbyRegexes: array<string> = parseJson(readFileSync(rawDir ++ "/antislop-vllm_main_banlists_regex_not_x_but_y.json", "utf8"))

let fancyTags = ["murmured", "rasped", "chimed", "interjected", "exclaimed", "chuckled", "smirked", "purred", "drawled", "intoned", "quipped", "mused", "stammered", "croaked", "boomed", "bellowed", "barked", "hissed", "growled", "whispered", "breathed", "sighed"]

let lower = s => Js.String2.toLowerCase(s)

let countOccur = (hay: string, needle: string) => {
  let parts = Js.String2.split(hay, needle)
  Js.Array2.length(parts) - 1
}

let wordsOf = (t: string) =>
  Js.String2.splitByRe(t, %re("/[^a-z']+/"))
  ->Js.Array2.map(o => Belt.Option.getWithDefault(o, ""))
  ->Js.Array2.filter(w => Js.String2.length(w) > 0)

let mean = (a: array<float>) =>
  Js.Array2.length(a) == 0 ? 0. : Js.Array2.reduce(a, (x, y) => x +. y, 0.) /. Belt.Int.toFloat(Js.Array2.length(a))

let stdev = (a: array<float>) => {
  let m = mean(a)
  let v = mean(Js.Array2.map(a, x => (x -. m) *. (x -. m)))
  Js.Math.sqrt(v)
}

let score = (path: string) => {
  let raw = readFileSync(path, "utf8")
  let t = lower(raw)
  let ws = wordsOf(t)
  let nWords = Js.Array2.length(ws)
  let per1k = (n: int) => Belt.Float.toString(Js.Math.round(Belt.Int.toFloat(n) /. Belt.Int.toFloat(nWords) *. 10000.) /. 10.)

  /* slop words (forensics 1000): exact word matches */
  let wordSet = Js.Dict.empty()
  Js.Array2.forEach(ws, w => {
    let c = Belt.Option.getWithDefault(Js.Dict.get(wordSet, w), 0)
    Js.Dict.set(wordSet, w, c + 1)
  })
  let slopWordHits = ref(0)
  let slopWordList: array<string> = []
  Js.Array2.forEach(forensicsWords, entry => {
    let w = Js.Array2.unsafe_get(entry, 0)
    switch Js.Dict.get(wordSet, w) {
    | Some(c) => {
        slopWordHits := slopWordHits.contents + c
        Js.Array2.push(slopWordList, w ++ "×" ++ Belt.Int.toString(c))->ignore
      }
    | None => ()
    }
  })

  /* antislop phrases (517): substring matches, phrases only (contain a space) or distinctive words */
  let phraseHits = ref(0)
  let phraseList: array<string> = []
  Js.Array2.forEach(antislop, ((p, _)) => {
    let pl = lower(p)
    if Js.String2.length(pl) > 3 {
      let c = countOccur(t, pl)
      if c > 0 && Js.String2.includes(pl, " ") {
        phraseHits := phraseHits.contents + c
        Js.Array2.push(phraseList, pl)->ignore
      }
    }
  })

  /* banned ngrams (400, stopword-stripped — approximate by substring on the raw pair) */
  let ngramHits = ref(0)
  let ngramList: array<string> = []
  Js.Array2.forEach(ngrams, g => {
    let c = countOccur(t, lower(g))
    if c > 0 {
      ngramHits := ngramHits.contents + c
      Js.Array2.push(ngramList, g)->ignore
    }
  })

  /* not-x-but-y constructions */
  let nxby = ref(0)
  Js.Array2.forEach(nxbyRegexes, rs => {
    switch Js.Re.fromStringWithFlags(rs, ~flags="gi") {
    | re =>
      let m = Js.String2.match_(t, re)
      switch m {
      | Some(arr) => nxby := nxby.contents + Js.Array2.length(arr)
      | None => ()
      }
    }
  })

  /* em dashes per 1k words */
  let emDash = countOccur(raw, "\xe2\x80\x94") + countOccur(raw, "—")

  /* sentences */
  let sentRe = Js.Re.fromStringWithFlags("[.!?]+[\\s\"\\)]", ~flags="")
  let sents =
    Js.String2.splitByRe(raw, sentRe)
    ->Js.Array2.map(o => Belt.Option.getWithDefault(o, ""))
    ->Js.Array2.filter(s => Js.String2.length(Js.String2.trim(s)) > 1)
  let sentLens = Js.Array2.map(sents, s => Belt.Int.toFloat(Js.Array2.length(wordsOf(lower(s)))))
  let sMean = mean(sentLens)
  let sStd = stdev(sentLens)
  let burstiness = sMean == 0. ? 0. : sStd /. sMean

  /* paragraphs */
  let paras =
    Js.String2.split(raw, "\n\n")->Js.Array2.filter(p => Js.String2.length(Js.String2.trim(p)) > 0)
  let paraLens = Js.Array2.map(paras, p => Belt.Int.toFloat(Js.Array2.length(wordsOf(lower(p)))))
  let pStd = stdev(paraLens)
  let pMean = mean(paraLens)

  /* participial tails: ", xxxing ..." to end of sentence */
  let tailRe = Js.Re.fromStringWithFlags(",\\s+\\w+ing\\b[^.!?]{0,60}[.!?]", ~flags="g")
  let tails = switch Js.String2.match_(t, tailRe) {
  | Some(a) => Js.Array2.length(a)
  | None => 0
  }

  /* echo-fragments: short subjectless verb-initial sentence whose head verb appears in the previous sentence */
  let pastVerbs = ["said", "told", "kept", "went", "sat", "drove", "took", "got", "came", "stood", "left", "made", "did", "had", "ran", "put", "knocked", "washed", "walked", "looked", "turned", "stopped", "waited", "watched"]
  let echoFrags = ref(0)
  let echoList: array<string> = []
  let fragCount = ref(0)
  Js.Array2.forEachi(sents, (sent, i) => {
    let sws = wordsOf(lower(sent))
    let n = Js.Array2.length(sws)
    if n > 0 && n <= 7 {
      let head = Js.Array2.unsafe_get(sws, 0)
      let isVerbHead = Js.Array2.includes(pastVerbs, head) || (Js.String2.endsWith(head, "ed") && Js.String2.length(head) > 4)
      if isVerbHead {
        fragCount := fragCount.contents + 1
      }
    }
    /* forward echo: sentence OPENS with a bare verb that appeared in the previous sentence (any length) */
    if n > 0 && i > 0 {
      let head = Js.Array2.unsafe_get(sws, 0)
      let isVerbHead = Js.Array2.includes(pastVerbs, head) || (Js.String2.endsWith(head, "ed") && Js.String2.length(head) > 4)
      let prev = wordsOf(lower(Js.Array2.unsafe_get(sents, i - 1)))
      if isVerbHead && Js.Array2.includes(prev, head) {
        echoFrags := echoFrags.contents + 1
        Js.Array2.push(echoList, "FWD: " ++ Js.String2.slice(Js.String2.trim(sent), ~from=0, ~to_=50))->ignore
      }
      /* reverse echo: previous sentence was a 1-3 word verb fragment whose verb reappears here */
      let pn = Js.Array2.length(prev)
      if pn >= 1 && pn <= 3 {
        let phead = Js.Array2.unsafe_get(prev, 0)
        let pIsVerb = Js.Array2.includes(pastVerbs, phead) || (Js.String2.endsWith(phead, "ed") && Js.String2.length(phead) > 4)
        if pIsVerb && Js.Array2.includes(sws, phead) {
          echoFrags := echoFrags.contents + 1
          Js.Array2.push(echoList, "REV: " ++ Js.String2.slice(Js.String2.trim(sent), ~from=0, ~to_=50))->ignore
        }
      }
    }
  })

  /* -ly adverbs */
  let lys = Js.Array2.filter(ws, w => Js.String2.endsWith(w, "ly") && Js.String2.length(w) > 4)->Js.Array2.length

  /* said-ratio */
  let saidC = Belt.Option.getWithDefault(Js.Dict.get(wordSet, "said"), 0)
  let fancyC = Js.Array2.reduce(fancyTags, (acc, tag) => acc + Belt.Option.getWithDefault(Js.Dict.get(wordSet, tag), 0), 0)

  Js.log("== " ++ path)
  Js.log("words: " ++ Belt.Int.toString(nWords) ++ " | sentences: " ++ Belt.Int.toString(Js.Array2.length(sents)) ++ " | paragraphs: " ++ Belt.Int.toString(Js.Array2.length(paras)))
  Js.log("slop-words/1k: " ++ per1k(slopWordHits.contents) ++ "  [" ++ Js.Array2.joinWith(slopWordList, ", ") ++ "]")
  Js.log("slop-phrases: " ++ Belt.Int.toString(phraseHits.contents) ++ "  [" ++ Js.Array2.joinWith(phraseList, ", ") ++ "]")
  Js.log("banned-ngrams: " ++ Belt.Int.toString(ngramHits.contents) ++ "  [" ++ Js.Array2.joinWith(ngramList, ", ") ++ "]")
  Js.log("not-x-but-y: " ++ Belt.Int.toString(nxby.contents))
  Js.log("em-dashes: " ++ Belt.Int.toString(emDash))
  Js.log("participial-tails: " ++ Belt.Int.toString(tails))
  Js.log("subjectless-frags: " ++ Belt.Int.toString(fragCount.contents) ++ " | ECHO-FRAGS: " ++ Belt.Int.toString(echoFrags.contents) ++ "  [" ++ Js.Array2.joinWith(echoList, " | ") ++ "]")
  Js.log("-ly adverbs/1k: " ++ per1k(lys))
  Js.log("sent mean: " ++ Belt.Float.toString(Js.Math.round(sMean *. 10.) /. 10.) ++ " | stdev: " ++ Belt.Float.toString(Js.Math.round(sStd *. 10.) /. 10.) ++ " | burstiness: " ++ Belt.Float.toString(Js.Math.round(burstiness *. 100.) /. 100.))
  Js.log("para mean: " ++ Belt.Float.toString(Js.Math.round(pMean *. 10.) /. 10.) ++ " | stdev: " ++ Belt.Float.toString(Js.Math.round(pStd *. 10.) /. 10.))
  Js.log("said: " ++ Belt.Int.toString(saidC) ++ " | fancy tags: " ++ Belt.Int.toString(fancyC))
  Js.log("")
}

let files = Js.Array2.sliceFrom(argv, 2)
Js.Array2.forEach(files, score)
