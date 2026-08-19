/* Deterministic local word/timestamp alignment for known Hindi transcripts.

   Whisper supplies timestamped observations; the approved screenplay supplies
   the words and their segment order. This module never invents a transcript.
   It uses a global fuzzy sequence alignment, rejects weak or reordered matches,
   and treats detected silence only as corroborating boundary evidence. */

exception LocalWordAlignment(string)

let algorithmVersion = "kuku-local-word-align-v2-punctuation-boundaries"
let minOverallCoverage = 0.62
let minObservedPrecision = 0.55
let minMeanSimilarity = 0.78
let minSequenceScore = 0.50
let minAverageTokenProbability = 0.12

type timedWord = {
  text: string,
  start: float,
  end_: float,
  probability: float,
}

type knownSegment = {order: int, text: string}
type silenceGap = {start: float, end_: float}
type block = {
  order: int,
  start: float,
  end_: float,
  expectedWords: int,
  matchedWords: int,
  coverage: float,
}

type quality = {
  expectedWords: int,
  observedWords: int,
  matchedWords: int,
  coverage: float,
  observedPrecision: float,
  meanSimilarity: float,
  sequenceScore: float,
  averageTokenProbability: float,
  silenceSupportedBoundaries: int,
  boundaryCount: int,
  confidence: float,
}

type derived = {blocks: array<block>, quality: quality}
type expectedWord = {text: string, order: int}
type sequenceAlignment = {
  observedByExpected: array<option<int>>,
  similarityByExpected: array<float>,
  cost: float,
  sequenceScore: float,
}

let fail = message => raise(LocalWordAlignment(message))
let trim = Js.String2.trim

@send external normalizeUnicode: (string, string) => string = "normalize"

let normalizedWords = (value: string): array<string> =>
  normalizeUnicode(value, "NFKC")
  ->Js.String2.toLowerCase
  /* Punctuation separates spoken words. Removing it in place would silently
     merge अक्षर-पुल into अक्षरपुल while the acoustic aligner hears two words. */
  ->Js.String2.replaceByRe(%re("/[^0-9a-z\p{L}\p{M}]+/gu"), " ")
  ->Js.String2.replaceByRe(%re("/[\s\u200B-\u200D\uFEFF]+/g"), " ")
  ->Js.String2.split(" ")
  ->Belt.Array.keep(word => word != "")

let levenshtein = (left: string, right: string): int => {
  let a = Js.String2.split(left, "")
  let b = Js.String2.split(right, "")
  let width = Belt.Array.length(b) + 1
  let previous = Belt.Array.make(width, 0)
  let current = Belt.Array.make(width, 0)
  for column in 0 to width - 1 {
    Belt.Array.setExn(previous, column, column)
  }
  for row in 1 to Belt.Array.length(a) {
    Belt.Array.setExn(current, 0, row)
    for column in 1 to width - 1 {
      let substitution =
        Belt.Array.getExn(previous, column - 1) +
        (Belt.Array.getExn(a, row - 1) == Belt.Array.getExn(b, column - 1) ? 0 : 1)
      let deletion = Belt.Array.getExn(previous, column) + 1
      let insertion = Belt.Array.getExn(current, column - 1) + 1
      Belt.Array.setExn(current, column, min(substitution, min(deletion, insertion)))
    }
    for column in 0 to width - 1 {
      Belt.Array.setExn(previous, column, Belt.Array.getExn(current, column))
    }
  }
  Belt.Array.getExn(previous, width - 1)
}

let wordSimilarity = (left: string, right: string): float => {
  if left == right {
    1.0
  } else {
    let longest = max(Js.String2.length(left), Js.String2.length(right))
    longest == 0
      ? 1.0
      : max(0.0, 1.0 -. Belt.Int.toFloat(levenshtein(left, right)) /. Belt.Int.toFloat(longest))
  }
}

let strongThreshold = (left: string, right: string): float => {
  let longest = max(Js.String2.length(left), Js.String2.length(right))
  longest <= 2 ? 0.99 : longest <= 4 ? 0.72 : 0.62
}

let isStrong = (left: string, right: string, similarity: float): bool =>
  similarity >= strongThreshold(left, right)

let sequenceAlign = (
  expected: array<expectedWord>,
  observed: array<timedWord>,
): sequenceAlignment => {
  let rows = Belt.Array.length(expected) + 1
  let columns = Belt.Array.length(observed) + 1
  let cellCount = rows * columns
  let costs = Belt.Array.make(cellCount, 0.0)
  let moves = Belt.Array.make(cellCount, 0)
  let index = (row, column) => row * columns + column
  for row in 1 to rows - 1 {
    Belt.Array.setExn(costs, index(row, 0), Belt.Int.toFloat(row))
    Belt.Array.setExn(moves, index(row, 0), 1)
  }
  for column in 1 to columns - 1 {
    Belt.Array.setExn(costs, index(0, column), Belt.Int.toFloat(column) *. 0.90)
    Belt.Array.setExn(moves, index(0, column), 2)
  }
  for row in 1 to rows - 1 {
    for column in 1 to columns - 1 {
      let expectedWord = Belt.Array.getExn(expected, row - 1).text
      let observedWord = Belt.Array.getExn(observed, column - 1).text
      let similarity = wordSimilarity(expectedWord, observedWord)
      let substitutionCost = similarity < 0.30 ? 1.20 : 1.0 -. similarity
      let diagonal = Belt.Array.getExn(costs, index(row - 1, column - 1)) +. substitutionCost
      let deletion = Belt.Array.getExn(costs, index(row - 1, column)) +. 1.0
      let insertion = Belt.Array.getExn(costs, index(row, column - 1)) +. 0.90
      let best = ref(diagonal)
      let move = ref(0)
      if deletion < best.contents -. 0.000001 {
        best := deletion
        move := 1
      }
      if insertion < best.contents -. 0.000001 {
        best := insertion
        move := 2
      }
      Belt.Array.setExn(costs, index(row, column), best.contents)
      Belt.Array.setExn(moves, index(row, column), move.contents)
    }
  }
  let observedByExpected: array<option<int>> = Belt.Array.make(rows - 1, None)
  let similarityByExpected = Belt.Array.make(rows - 1, 0.0)
  let row = ref(rows - 1)
  let column = ref(columns - 1)
  while row.contents > 0 || column.contents > 0 {
    let move = Belt.Array.getExn(moves, index(row.contents, column.contents))
    if row.contents > 0 && column.contents > 0 && move == 0 {
      let expectedIndex = row.contents - 1
      let observedIndex = column.contents - 1
      Belt.Array.setExn(observedByExpected, expectedIndex, Some(observedIndex))
      Belt.Array.setExn(
        similarityByExpected,
        expectedIndex,
        wordSimilarity(
          Belt.Array.getExn(expected, expectedIndex).text,
          Belt.Array.getExn(observed, observedIndex).text,
        ),
      )
      row := row.contents - 1
      column := column.contents - 1
    } else if row.contents > 0 && (column.contents == 0 || move == 1) {
      row := row.contents - 1
    } else if column.contents > 0 {
      column := column.contents - 1
    } else {
      fail("sequence alignment backtrace became stuck")
    }
  }
  let cost = Belt.Array.getExn(costs, index(rows - 1, columns - 1))
  let denominator = max(rows - 1, columns - 1)
  {
    observedByExpected,
    similarityByExpected,
    cost,
    sequenceScore: denominator == 0
      ? 1.0
      : max(0.0, 1.0 -. cost /. Belt.Int.toFloat(denominator)),
  }
}

let jsonObject = (json: Js.Json.t, label: string): Js.Dict.t<Js.Json.t> =>
  switch Js.Json.decodeObject(json) {
  | Some(value) => value
  | None => fail(label ++ " must be an object")
  }

let field = (object_: Js.Dict.t<Js.Json.t>, key: string): option<Js.Json.t> =>
  Js.Dict.get(object_, key)

let stringField = (object_, key, label): string =>
  switch field(object_, key)->Belt.Option.flatMap(Js.Json.decodeString) {
  | Some(value) => value
  | None => fail(label ++ "." ++ key ++ " must be a string")
  }

let optionalNumber = (object_, key): option<float> =>
  field(object_, key)->Belt.Option.flatMap(Js.Json.decodeNumber)

let parseClock = (value: string): option<float> => {
  let normalized = value->Js.String2.replaceByRe(%re("/,/g"), ".")
  let pieces = Js.String2.split(normalized, ":")
  if Belt.Array.length(pieces) != 3 {
    None
  } else {
    switch (
      Belt.Array.get(pieces, 0)->Belt.Option.flatMap(Belt.Float.fromString),
      Belt.Array.get(pieces, 1)->Belt.Option.flatMap(Belt.Float.fromString),
      Belt.Array.get(pieces, 2)->Belt.Option.flatMap(Belt.Float.fromString),
    ) {
    | (Some(hours), Some(minutes), Some(seconds)) => Some(hours *. 3600.0 +. minutes *. 60.0 +. seconds)
    | _ => None
    }
  }
}

let timingFrom = (object_: Js.Dict.t<Js.Json.t>, label: string): (float, float) => {
  let fromOffsets = switch field(object_, "offsets")->Belt.Option.flatMap(Js.Json.decodeObject) {
  | Some(offsets) =>
    switch (optionalNumber(offsets, "from"), optionalNumber(offsets, "to")) {
    | (Some(start), Some(end_)) => Some((start /. 1000.0, end_ /. 1000.0))
    | _ => None
    }
  | None => None
  }
  switch fromOffsets {
  | Some(value) => value
  | None =>
    switch (optionalNumber(object_, "start"), optionalNumber(object_, "end")) {
    | (Some(start), Some(end_)) => (start, end_)
    | _ =>
      switch field(object_, "timestamps")->Belt.Option.flatMap(Js.Json.decodeObject) {
      | Some(timestamps) =>
        switch (
          field(timestamps, "from")->Belt.Option.flatMap(Js.Json.decodeString)->Belt.Option.flatMap(parseClock),
          field(timestamps, "to")->Belt.Option.flatMap(Js.Json.decodeString)->Belt.Option.flatMap(parseClock),
        ) {
        | (Some(start), Some(end_)) => (start, end_)
        | _ => fail(label ++ " has no usable token timestamps")
        }
      | None => fail(label ++ " has no usable token timestamps")
      }
    }
  }
}

let beginsWithWhitespace = (value: string): bool => {
  if value == "" {
    false
  } else {
    let first = Js.String2.slice(value, ~from=0, ~to_=1)
    first == " " || first == "\n" || first == "\t" || first == "\r"
  }
}

let isSpecialToken = (value: string): bool =>
  Js.String2.includes(value, "<|") || Js.String2.includes(value, "[_") ||
  Js.String2.includes(value, "[BLANK_AUDIO]")

let combinedProbability = (left: float, right: float): float => {
  if left < 0.0 {
    right
  } else if right < 0.0 {
    left
  } else {
    min(left, right)
  }
}

let addObservedPieces = (
  words: array<timedWord>,
  ~raw: string,
  ~start: float,
  ~end_: float,
  ~probability: float,
  ~forceBoundary: bool,
): unit => {
  if !isSpecialToken(raw) && end_ >= start && start >= 0.0 {
    let normalized = normalizedWords(raw)
    let count = Belt.Array.length(normalized)
    normalized->Belt.Array.forEachWithIndex((index, text) => {
      let pieceStart = start +. (end_ -. start) *. Belt.Int.toFloat(index) /. Belt.Int.toFloat(count)
      let pieceEnd = start +. (end_ -. start) *. Belt.Int.toFloat(index + 1) /. Belt.Int.toFloat(count)
      let newWord = forceBoundary || beginsWithWhitespace(raw) || index > 0 || Belt.Array.length(words) == 0
      if newWord {
        let _ = Js.Array2.push(words, {text, start: pieceStart, end_: pieceEnd, probability})
      } else {
        let lastIndex = Belt.Array.length(words) - 1
        let previous = Belt.Array.getExn(words, lastIndex)
        Belt.Array.setExn(words, lastIndex, {
          text: previous.text ++ text,
          start: previous.start,
          end_: max(previous.end_, pieceEnd),
          probability: combinedProbability(previous.probability, probability),
        })
      }
    })
  }
}

let parseWhisperJson = (raw: string): array<timedWord> => {
  let root = raw->Js.Json.parseExn->jsonObject("Whisper JSON")
  let transcription = switch field(root, "transcription")->Belt.Option.flatMap(Js.Json.decodeArray) {
  | Some(value) => value
  | None => fail("Whisper JSON has no transcription array")
  }
  let words: array<timedWord> = []
  transcription->Belt.Array.forEachWithIndex((segmentIndex, segmentJson) => {
    let segment = jsonObject(segmentJson, "Whisper transcription segment")
    let tokens = switch field(segment, "tokens")->Belt.Option.flatMap(Js.Json.decodeArray) {
    | Some(value) if Belt.Array.length(value) > 0 => value
    | _ => fail(
        "Whisper segment " ++ Belt.Int.toString(segmentIndex) ++
        " has no word/token timestamps; -ojf output is required",
      )
    }
    let firstLexical = ref(true)
    tokens->Belt.Array.forEachWithIndex((tokenIndex, tokenJson) => {
      let token = jsonObject(tokenJson, "Whisper token")
      let text = stringField(token, "text", "Whisper token")
      let (start, end_) = timingFrom(
        token,
        "Whisper token " ++ Belt.Int.toString(segmentIndex) ++ ":" ++ Belt.Int.toString(tokenIndex),
      )
      let lexical = Belt.Array.length(normalizedWords(text)) > 0 && !isSpecialToken(text)
      addObservedPieces(
        words,
        ~raw=text,
        ~start,
        ~end_,
        ~probability=optionalNumber(token, "p")->Belt.Option.getWithDefault(-1.0),
        ~forceBoundary=firstLexical.contents,
      )
      if lexical {
        firstLexical := false
      }
    })
  })
  if Belt.Array.length(words) == 0 {
    fail("Whisper JSON contained no usable timed words")
  }
  let previousStart = ref(-1.0)
  words->Belt.Array.forEach(word => {
    if word.start +. 0.001 < previousStart.contents || word.end_ < word.start {
      fail("Whisper word timestamps are non-monotonic")
    }
    previousStart := word.start
  })
  words
}

let flattenExpected = (segments: array<knownSegment>): array<expectedWord> => {
  let result: array<expectedWord> = []
  segments->Belt.Array.forEach(segment => {
    let words = normalizedWords(segment.text)
    if Belt.Array.length(words) == 0 {
      fail("known segment " ++ Belt.Int.toString(segment.order) ++ " has no normalized words")
    }
    words->Belt.Array.forEach(text => {
      let _ = Js.Array2.push(result, {text, order: segment.order})
    })
  })
  result
}

let silenceSupportCount = (blocks: array<block>, gaps: array<silenceGap>): int => {
  let supported = ref(0)
  if Belt.Array.length(blocks) > 1 {
    for index in 0 to Belt.Array.length(blocks) - 2 {
      let left = Belt.Array.getExn(blocks, index)
      let right = Belt.Array.getExn(blocks, index + 1)
      let target = (left.end_ +. right.start) /. 2.0
      let found = Belt.Array.some(gaps, gap => {
        let midpoint = (gap.start +. gap.end_) /. 2.0
        gap.end_ >= left.end_ -. 0.35 && gap.start <= right.start +. 0.35 &&
        abs_float(midpoint -. target) <= 0.65
      })
      if found {
        supported := supported.contents + 1
      }
    }
  }
  supported.contents
}

let derive = (
  segments: array<knownSegment>,
  observed: array<timedWord>,
  gaps: array<silenceGap>,
): derived => {
  if Belt.Array.length(segments) == 0 || Belt.Array.length(observed) == 0 {
    fail("local alignment needs known segments and observed words")
  }
  let expected = flattenExpected(segments)
  let aligned = sequenceAlign(expected, observed)
  let strongByExpected = Belt.Array.make(Belt.Array.length(expected), false)
  let strongObserved = Js.Dict.empty()
  let strongCount = ref(0)
  let similaritySum = ref(0.0)
  let probabilitySum = ref(0.0)
  let probabilityCount = ref(0)
  expected->Belt.Array.forEachWithIndex((index, expectedWord) => {
    switch Belt.Array.getExn(aligned.observedByExpected, index) {
    | Some(observedIndex) => {
        let observedWord = Belt.Array.getExn(observed, observedIndex)
        let similarity = Belt.Array.getExn(aligned.similarityByExpected, index)
        if isStrong(expectedWord.text, observedWord.text, similarity) {
          Belt.Array.setExn(strongByExpected, index, true)
          Js.Dict.set(strongObserved, Belt.Int.toString(observedIndex), true)
          strongCount := strongCount.contents + 1
          similaritySum := similaritySum.contents +. similarity
          if observedWord.probability >= 0.0 {
            probabilitySum := probabilitySum.contents +. observedWord.probability
            probabilityCount := probabilityCount.contents + 1
          }
        }
      }
    | None => ()
    }
  })
  let expectedCount = Belt.Array.length(expected)
  let observedCount = Belt.Array.length(observed)
  let coverage = Belt.Int.toFloat(strongCount.contents) /. Belt.Int.toFloat(expectedCount)
  let observedPrecision =
    Belt.Int.toFloat(Js.Dict.keys(strongObserved)->Belt.Array.length) /. Belt.Int.toFloat(observedCount)
  let meanSimilarity = strongCount.contents == 0
    ? 0.0
    : similaritySum.contents /. Belt.Int.toFloat(strongCount.contents)
  let averageTokenProbability = probabilityCount.contents == 0
    ? -1.0
    : probabilitySum.contents /. Belt.Int.toFloat(probabilityCount.contents)
  if coverage < minOverallCoverage || observedPrecision < minObservedPrecision ||
     meanSimilarity < minMeanSimilarity || aligned.sequenceScore < minSequenceScore ||
     (averageTokenProbability >= 0.0 && averageTokenProbability < minAverageTokenProbability) {
    fail(
      "low-confidence local alignment: coverage=" ++ Js.Float.toFixedWithPrecision(coverage, ~digits=3) ++
      ", observed_precision=" ++ Js.Float.toFixedWithPrecision(observedPrecision, ~digits=3) ++
      ", mean_similarity=" ++ Js.Float.toFixedWithPrecision(meanSimilarity, ~digits=3) ++
      ", sequence_score=" ++ Js.Float.toFixedWithPrecision(aligned.sequenceScore, ~digits=3) ++
      ", token_probability=" ++ Js.Float.toFixedWithPrecision(averageTokenProbability, ~digits=3),
    )
  }
  let blocks: array<block> = []
  let expectedCursor = ref(0)
  let previousObservedIndex = ref(-1)
  let previousStart = ref(-1.0)
  segments->Belt.Array.forEachWithIndex((segmentIndex, segment) => {
    let segmentWords = normalizedWords(segment.text)
    let firstObserved: ref<option<int>> = ref(None)
    let lastObserved: ref<option<int>> = ref(None)
    let firstMatchedLocal = ref(-1)
    let lastMatchedLocal = ref(-1)
    let matched = ref(0)
    for localIndex in 0 to Belt.Array.length(segmentWords) - 1 {
      let expectedIndex = expectedCursor.contents + localIndex
      if Belt.Array.getExn(strongByExpected, expectedIndex) {
        switch Belt.Array.getExn(aligned.observedByExpected, expectedIndex) {
        | Some(observedIndex) => {
            if observedIndex <= previousObservedIndex.contents {
              fail("matched words are not in strict transcript order at segment " ++ Belt.Int.toString(segment.order))
            }
            if firstObserved.contents == None {
              firstObserved := Some(observedIndex)
              firstMatchedLocal := localIndex
            }
            lastObserved := Some(observedIndex)
            lastMatchedLocal := localIndex
            previousObservedIndex := observedIndex
            matched := matched.contents + 1
          }
        | None => fail("internal strong-match mapping error")
        }
      }
    }
    expectedCursor := expectedCursor.contents + Belt.Array.length(segmentWords)
    let segmentCoverage =
      Belt.Int.toFloat(matched.contents) /. Belt.Int.toFloat(Belt.Array.length(segmentWords))
    let minimum = Belt.Array.length(segmentWords) <= 1
      ? 1.0
      : Belt.Array.length(segmentWords) == 2 ? 0.50 : 0.40
    if matched.contents == 0 || segmentCoverage < minimum {
      fail(
        "segment " ++ Belt.Int.toString(segment.order) ++
        " has insufficient ordered word matches: " ++ Belt.Int.toString(matched.contents) ++ "/" ++
        Belt.Int.toString(Belt.Array.length(segmentWords)),
      )
    }
    switch (firstObserved.contents, lastObserved.contents) {
    | (Some(first), Some(last)) => {
        /* Known chunk order safely recovers omitted edge words: Whisper may
           miss a short opening such as "यह ब है", but a later strong match in
           the same first segment still proves which segment owns the opening.
           Interior boundaries still require ordered matches on both sides. */
        let start = segmentIndex == 0 && firstMatchedLocal.contents > 0
          ? 0.0
          : Belt.Array.getExn(observed, first).start
        let end_ = segmentIndex == Belt.Array.length(segments) - 1 &&
          lastMatchedLocal.contents < Belt.Array.length(segmentWords) - 1
          ? Belt.Array.getExn(observed, Belt.Array.length(observed) - 1).end_
          : Belt.Array.getExn(observed, last).end_
        if start +. 0.20 < previousStart.contents || end_ <= start {
          fail("segment times are not monotonic at " ++ Belt.Int.toString(segment.order))
        }
        previousStart := start
        let _ = Js.Array2.push(blocks, {
          order: segment.order,
          start,
          end_,
          expectedWords: Belt.Array.length(segmentWords),
          matchedWords: matched.contents,
          coverage: segmentCoverage,
        })
      }
    | _ => fail("segment " ++ Belt.Int.toString(segment.order) ++ " has no timing anchors")
    }
  })
  let supported = silenceSupportCount(blocks, gaps)
  let boundaryCount = max(0, Belt.Array.length(blocks) - 1)
  let baseConfidence =
    (coverage +. observedPrecision +. meanSimilarity +. aligned.sequenceScore) /. 4.0
  /* Silence can add at most three hundredths after the lexical/order gates
     already pass. It therefore corroborates a boundary but can never create or
     rescue one on its own. */
  let silenceRatio = boundaryCount == 0
    ? 0.0
    : Belt.Int.toFloat(supported) /. Belt.Int.toFloat(boundaryCount)
  let confidence = min(1.0, baseConfidence +. 0.03 *. silenceRatio)
  {
    blocks,
    quality: {
      expectedWords: expectedCount,
      observedWords: observedCount,
      matchedWords: strongCount.contents,
      coverage,
      observedPrecision,
      meanSimilarity,
      sequenceScore: aligned.sequenceScore,
      averageTokenProbability,
      silenceSupportedBoundaries: supported,
      boundaryCount,
      confidence,
    },
  }
}
