@val @scope("process") external exit: int => unit = "exit"

let fail = message => {
  Js.log("FAIL: " ++ message)
  exit(1)
}

let check = (condition: bool, message: string): unit =>
  if !condition {
    fail(message)
  }

let known: array<Kuku_LocalWordAlign.knownSegment> = [
  {order: 1, text: "यह ब है। ऊपर सीधी रेखा है।"},
  {order: 2, text: "अब मैं पूरा ब बनाऊँगा।"},
]

/* The local recognizer may omit the short opening but correctly recognize the
   later ordered phrases. Fuzzy spelling differences mirror the real Hindi
   smoke result: सीदी/सीधी, पुरा/पूरा, and बनाउंगा/बनाऊँगा. */
let observed: array<Kuku_LocalWordAlign.timedWord> = [
  {text: "उपर", start: 0.08, end_: 0.65, probability: 0.88},
  {text: "सीदी", start: 0.70, end_: 1.32, probability: 0.84},
  {text: "रेखा", start: 1.40, end_: 1.95, probability: 0.91},
  {text: "है", start: 2.02, end_: 2.28, probability: 0.95},
  {text: "अब", start: 3.02, end_: 3.18, probability: 0.97},
  {text: "मैं", start: 3.20, end_: 3.38, probability: 0.91},
  {text: "पुरा", start: 3.42, end_: 3.88, probability: 0.89},
  {text: "ब", start: 3.92, end_: 4.05, probability: 0.96},
  {text: "बनाउंगा", start: 4.10, end_: 4.88, probability: 0.86},
]

let derived = Kuku_LocalWordAlign.derive(
  known,
  observed,
  [{start: 2.40, end_: 2.92}],
)
check(Belt.Array.length(derived.blocks) == 2, "two known segments produce two blocks")
check(Belt.Array.getExn(derived.blocks, 0).start == 0.0, "known first-segment order restores omitted opening")
check(Belt.Array.getExn(derived.blocks, 1).start >= 3.0, "second segment keeps its observed handoff")
check(derived.quality.coverage >= Kuku_LocalWordAlign.minOverallCoverage, "fuzzy coverage gate")
check(derived.quality.silenceSupportedBoundaries == 1, "silence corroborates but does not create boundary")

let rawFixture =
  "{\"transcription\":[{\"tokens\":[" ++
  "{\"text\":\"[_BEG_]\",\"offsets\":{\"from\":0,\"to\":0},\"p\":0.9}," ++
  "{\"text\":\" उ\",\"offsets\":{\"from\":80,\"to\":180},\"p\":0.9}," ++
  "{\"text\":\"प\",\"offsets\":{\"from\":180,\"to\":260},\"p\":0.8}," ++
  "{\"text\":\"र\",\"offsets\":{\"from\":260,\"to\":340},\"p\":0.9}," ++
  "{\"text\":\" अब\",\"offsets\":{\"from\":500,\"to\":500},\"p\":0.95}," ++
  "{\"text\":\" म\",\"offsets\":{\"from\":500,\"to\":600},\"p\":0.92}," ++
  "{\"text\":\"ैं\",\"offsets\":{\"from\":600,\"to\":720},\"p\":0.88}" ++
  "]}]}"
let parsed = Kuku_LocalWordAlign.parseWhisperJson(rawFixture)
check(Belt.Array.length(parsed) == 3, "BPE pieces coalesce into timed words")
check(Belt.Array.getExn(parsed, 0).text == "उपर", "Devanagari BPE word coalescing")
check(Belt.Array.getExn(parsed, 1).text == "अब", "zero-duration word is retained as sequence evidence")

let rejectedOrder = ref(false)
try {
  let reversed: array<Kuku_LocalWordAlign.timedWord> = [
    {text: "अब", start: 0.0, end_: 0.2, probability: 0.9},
    {text: "मैं", start: 0.2, end_: 0.4, probability: 0.9},
    {text: "पूरा", start: 0.4, end_: 0.7, probability: 0.9},
    {text: "ब", start: 0.7, end_: 0.8, probability: 0.9},
    {text: "बनाऊँगा", start: 0.8, end_: 1.2, probability: 0.9},
    {text: "ऊपर", start: 1.4, end_: 1.7, probability: 0.9},
    {text: "सीधी", start: 1.7, end_: 2.0, probability: 0.9},
    {text: "रेखा", start: 2.0, end_: 2.3, probability: 0.9},
    {text: "है", start: 2.3, end_: 2.5, probability: 0.9},
  ]
  let _ = Kuku_LocalWordAlign.derive(known, reversed, [])
} catch {
| Kuku_LocalWordAlign.LocalWordAlignment(_) => rejectedOrder := true
}
check(rejectedOrder.contents, "reordered observations fail closed")

let rejectedNoise = ref(false)
try {
  let unrelated: array<Kuku_LocalWordAlign.timedWord> = [
    {text: "आकाश", start: 0.0, end_: 0.4, probability: 0.9},
    {text: "समुद्र", start: 0.5, end_: 0.9, probability: 0.9},
  ]
  let _ = Kuku_LocalWordAlign.derive(known, unrelated, [])
} catch {
| Kuku_LocalWordAlign.LocalWordAlignment(_) => rejectedNoise := true
}
check(rejectedNoise.contents, "low-confidence unrelated observations fail closed")

/* Optional read-only verification against the already-completed CPU smoke. It
   is intentionally skipped when the temporary fixture is absent and never
   launches whisper-cli. */
let smokePath = "/private/tmp/metaphrand-whisper/chunk_011_smoke.json"
if Cinema_Backends.exists(Cinema_Backends.Path(smokePath)) {
  let smokeObserved = Kuku_LocalWordAlign.parseWhisperJson(
    Cinema_Backends.readText(Cinema_Backends.Path(smokePath)),
  )
  let smokeKnown: array<Kuku_LocalWordAlign.knownSegment> = [
    {order: 148, text: "यह ब है। ऊपर सीधी रेखा है। दाईं ओर की लकीर नीचे जाती है। नीचे का गोल मोड़ बंद है।"},
    {order: 149, text: "अब मैं पूरा ब बनाऊँगा।"},
  ]
  let smoke = Kuku_LocalWordAlign.derive(smokeKnown, smokeObserved, [])
  check(Belt.Array.length(smoke.blocks) == 2, "real smoke preserves two-speaker order")
  check(Belt.Array.getExn(smoke.blocks, 0).start == 0.0, "real smoke restores omitted opening ownership")
  check(Belt.Array.getExn(smoke.blocks, 1).start >= 11.5, "real smoke finds Kuku handoff near 12 seconds")
}

Js.log("KUKU LOCAL WORD ALIGN TESTS PASSED — fuzzy order, zero-time tokens, silence support, and rejection gates")
