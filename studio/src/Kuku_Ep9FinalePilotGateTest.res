let check = (condition, message) =>
  if !condition {
    raise(Failure(message))
  }

let expectPilotError = (run, expectedFragment) => {
  let message = try {
    run()
    raise(Failure("expected calibration pilot validation to fail"))
  } catch {
  | Kuku_Ep9FinalePilotGate.PilotGateError(message) => message
  }
  check(Js.String2.includes(message, expectedFragment), "unexpected pilot-gate error: " ++ message)
}

let hashA = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
let hashB = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

let fixture = `{
  "shots": [
    {
      "id":"B07","classId":"B_WIDE_ENVIRONMENT","model":"veo3_1_lite",
      "durationSeconds":8,"quoteGate":8,"promptFile":"../prompts/B07.txt",
      "promptSha256":"${hashA}","startFrame":"../frames/B07.png",
      "startFrameSha256":"${hashA}","output":"../clips/B07.mp4","status":"pilot_ready"
    },
    {
      "id":"B10","classId":"B_WIDE_ENVIRONMENT","model":"minimax_hailuo",
      "variant":"minimax-2.3-fast","durationSeconds":10,"quoteGate":7,
      "promptFile":"../prompts/B10.txt","promptSha256":"${hashA}",
      "startFrame":"../frames/B10.png","startFrameSha256":"${hashA}",
      "output":"../clips/B10.mp4","status":"pilot_ready"
    },
    {
      "id":"C03","classId":"C_SIMPLE_CHARACTER","model":"seedance1_5",
      "durationSeconds":8,"quoteGate":9.6,"promptFile":"../prompts/C03.txt",
      "promptSha256":"${hashA}","startFrame":"../frames/C03.png",
      "startFrameSha256":"${hashA}","output":"../clips/C03.mp4","status":"pilot_ready"
    },
    {
      "id":"C04","classId":"C_SIMPLE_CHARACTER","model":"kling2_6",
      "durationSeconds":10,"quoteGate":10,"promptFile":"../prompts/C04.txt",
      "promptSha256":"${hashA}","startFrame":"../frames/C04.png",
      "startFrameSha256":"${hashA}","output":"../clips/C04.mp4","status":"pilot_ready"
    }
  ]
}`

let goodInspectors: Kuku_Ep9FinalePilotGate.inspectors = {
  exists: path => !Js.String2.endsWith(path, ".mp4"),
  sha256: _ => hashA,
  probeFrame: _ => {width: 1280.0, height: 720.0, sampleAspectRatio: "1:1"},
  probeVideo: _ => {
    width: 1364.0,
    height: 768.0,
    duration: 10.125,
    fps: 24.0,
    videoStreams: 1,
    audioStreams: 0,
  },
}

let emptySpend = `{"events":[]}`

let validateFixture = (raw, spend, inspectors) =>
  Kuku_Ep9FinalePilotGate.validateLifecycleRaw(
    ~manifestRaw=raw,
    ~manifestDirectory="/fixture/manifests",
    ~spendRaw=spend,
    ~spendDirectory="/fixture/budget",
    ~inspectors,
  )

let fixtureResult = validateFixture(fixture, emptySpend, goodInspectors)
check(fixtureResult.pilotIds == ["B07", "B10", "C03", "C04"], "pilot IDs and order")
check(fixtureResult.seconds == 36.0, "pilot duration total")
check(fixtureResult.quoteGate == 34.6, "pilot quote ceiling")
check(fixtureResult.readyCount == 4, "all-ready count")
check(fixtureResult.acceptedCount == 0, "initial accepted count")
check(fixtureResult.fallbackCount == 0, "initial fallback count")
check(fixtureResult.resolvedCount == 0, "initial resolved count")
check(fixtureResult.acceptedCredits == 0.0, "initial accepted spend")

expectPilotError(
  () =>
    validateFixture(
      Js.String2.replace(fixture, `"status":"pilot_ready"`, `"status":"blocked"`),
      emptySpend,
      goodInspectors,
    )->ignore,
  "exactly four",
)

expectPilotError(
  () =>
    validateFixture(
      Js.String2.replace(fixture, `"model":"veo3_1_lite"`, `"model":"kling2_6"`),
      emptySpend,
      goodInspectors,
    )->ignore,
  "drifted",
)

expectPilotError(
  () =>
    validateFixture(
      Js.String2.replace(fixture, `"output":"../clips/C04.mp4"`, `"output":"../clips/C03.mp4"`),
      emptySpend,
      goodInspectors,
    )->ignore,
  "duplicates the path",
)

let badHashInspectors: Kuku_Ep9FinalePilotGate.inspectors = {
  ...goodInspectors,
  sha256: _ => hashB,
}
expectPilotError(
  () => validateFixture(fixture, emptySpend, badHashInspectors)->ignore,
  "bytes do not match",
)

let badGeometryInspectors: Kuku_Ep9FinalePilotGate.inspectors = {
  ...goodInspectors,
  probeFrame: _ => {width: 1920.0, height: 1080.0, sampleAspectRatio: "1:1"},
}
expectPilotError(
  () => validateFixture(fixture, emptySpend, badGeometryInspectors)->ignore,
  "exactly 1280x720",
)

let existingOutputInspectors: Kuku_Ep9FinalePilotGate.inspectors = {
  ...goodInspectors,
  exists: _ => true,
}
expectPilotError(
  () => validateFixture(fixture, emptySpend, existingOutputInspectors)->ignore,
  "output already exists",
)

let dependency = "Add a subtle local tracked crack accent in post."
let acceptedFixture = Js.String2.replace(
  fixture,
  `"output":"../clips/B10.mp4","status":"pilot_ready"`,
  `"output":"../clips/B10.mp4","outputSha256":"${hashA}","acceptedJobId":"job-b10-2","acceptedAttempt":2,"acceptanceDependency":"${dependency}","status":"pilot_accepted"`,
)
let acceptedSpend = `{
  "events":[{
    "targetId":"B10","classId":"B_WIDE_ENVIRONMENT","model":"minimax_hailuo",
    "variant":"minimax-2.3-fast","durationSeconds":10,"quoteCredits":7,
    "actualCredits":7,"attempt":2,"jobId":"job-b10-2",
    "status":"accepted_with_local_motion_dependency","dependency":"${dependency}",
    "promptSha256":"${hashA}","inputSha256":"${hashA}",
    "output":"../clips/B10.mp4","outputSha256":"${hashA}"
  }]
}`
let mixedInspectors: Kuku_Ep9FinalePilotGate.inspectors = {
  ...goodInspectors,
  exists: path => !Js.String2.endsWith(path, ".mp4") || Js.String2.endsWith(path, "/B10.mp4"),
}
let mixedResult = validateFixture(acceptedFixture, acceptedSpend, mixedInspectors)
check(mixedResult.readyCount == 3, "mixed lifecycle ready count")
check(mixedResult.acceptedCount == 1, "mixed lifecycle accepted count")
check(mixedResult.fallbackCount == 0, "mixed lifecycle fallback count")
check(mixedResult.resolvedCount == 1, "mixed lifecycle resolved count")
check(mixedResult.acceptedCredits == 7.0, "mixed lifecycle accepted credits")

expectPilotError(
  () => validateFixture(acceptedFixture, acceptedSpend, goodInspectors)->ignore,
  "accepted output is missing",
)

let badVideoInspectors: Kuku_Ep9FinalePilotGate.inspectors = {
  ...mixedInspectors,
  probeVideo: _ => {
    width: 1364.0,
    height: 768.0,
    duration: 10.125,
    fps: 24.0,
    videoStreams: 1,
    audioStreams: 1,
  },
}
expectPilotError(
  () => validateFixture(acceptedFixture, acceptedSpend, badVideoInspectors)->ignore,
  "no native audio",
)

let badFpsInspectors: Kuku_Ep9FinalePilotGate.inspectors = {
  ...mixedInspectors,
  probeVideo: _ => {
    width: 1364.0,
    height: 768.0,
    duration: 10.125,
    fps: 60.0,
    videoStreams: 1,
    audioStreams: 0,
  },
}
expectPilotError(
  () => validateFixture(acceptedFixture, acceptedSpend, badFpsInspectors)->ignore,
  "frame rate is not sane",
)

expectPilotError(
  () => validateFixture(acceptedFixture, emptySpend, mixedInspectors)->ignore,
  "exactly one matching accepted spend event",
)

expectPilotError(
  () =>
    validateFixture(
      acceptedFixture,
      Js.String2.replace(acceptedSpend, `"actualCredits":7`, `"actualCredits":8`),
      mixedInspectors,
    )->ignore,
  "exceeds its quote",
)

expectPilotError(
  () =>
    validateFixture(
      Js.String2.replace(acceptedFixture, `"acceptedJobId":"job-b10-2"`, `"acceptedJobId":"forged"`),
      acceptedSpend,
      mixedInspectors,
    )->ignore,
  "do not match exactly",
)

let fallbackMethod =
  "Deterministic local 2.5D cutout with one low hop and a grounded landing; no provider rerender."
let fallbackProvenance =
  "Zero-credit deterministic ReScript/ffmpeg composite from the locked start frame; Furia performs one low hop while the other four children remain witnesses; no provider submission."
let fallbackFixture = Js.String2.replace(
  acceptedFixture,
  `"output":"../clips/C03.mp4","status":"pilot_ready"`,
  `"output":"../clips/C03.mp4","failedAttempts":2,"fallbackMethod":"${fallbackMethod}","fallbackSource":"../frames/C03.png","fallbackSourceSha256":"${hashA}","localFallbackOutput":"../clips/C03.mp4","localFallbackOutputSha256":"${hashA}","localFallbackProvenance":"${fallbackProvenance}","status":"pilot_local_fallback"`,
)
let resolvedSpend = `{
  "events":[
    {
      "targetId":"B10","classId":"B_WIDE_ENVIRONMENT","model":"minimax_hailuo",
      "variant":"minimax-2.3-fast","durationSeconds":10,"quoteCredits":7,
      "actualCredits":7,"attempt":2,"jobId":"job-b10-2",
      "status":"accepted_with_local_motion_dependency","dependency":"${dependency}",
      "promptSha256":"${hashA}","inputSha256":"${hashA}",
      "output":"../clips/B10.mp4","outputSha256":"${hashA}"
    },
    {
      "targetId":"C03","classId":"C_SIMPLE_CHARACTER","model":"seedance1_5",
      "durationSeconds":8,"quoteCredits":9.6,"actualCredits":0,"attempt":1,
      "jobId":"job-c03-1","status":"failed_refunded_safety",
      "promptSha256":"${hashB}","inputSha256":"${hashA}"
    },
    {
      "targetId":"C03","classId":"C_SIMPLE_CHARACTER","model":"seedance1_5",
      "durationSeconds":8,"quoteCredits":9.6,"actualCredits":0,"attempt":2,
      "jobId":"job-c03-2","status":"failed_refunded_safety",
      "promptSha256":"${hashA}","inputSha256":"${hashA}"
    }
  ]
}`
let fallbackInspectors: Kuku_Ep9FinalePilotGate.inspectors = {
  ...mixedInspectors,
  exists: path =>
    !Js.String2.endsWith(path, ".mp4") || Js.String2.endsWith(path, "/B10.mp4") ||
    Js.String2.endsWith(path, "/C03.mp4"),
  probeVideo: path =>
    if Js.String2.endsWith(path, "/C03.mp4") {
      {
        width: 1280.0,
        height: 720.0,
        duration: 8.0,
        fps: 24.0,
        videoStreams: 1,
        audioStreams: 0,
      }
    } else {
      {
        width: 1364.0,
        height: 768.0,
        duration: 10.125,
        fps: 24.0,
        videoStreams: 1,
        audioStreams: 0,
      }
    },
}
let fallbackResult = validateFixture(fallbackFixture, resolvedSpend, fallbackInspectors)
check(fallbackResult.readyCount == 2, "fallback lifecycle ready count")
check(fallbackResult.acceptedCount == 1, "fallback lifecycle accepted count")
check(fallbackResult.fallbackCount == 1, "fallback lifecycle local count")
check(fallbackResult.resolvedCount == 2, "fallback lifecycle resolved count")

expectPilotError(
  () =>
    validateFixture(
      fallbackFixture,
      Js.String2.replace(resolvedSpend, `"actualCredits":0,"attempt":1`, `"actualCredits":1,"attempt":1`),
      fallbackInspectors,
    )->ignore,
  "does not match the locked pilot",
)

expectPilotError(
  () =>
    validateFixture(
      Js.String2.replace(
        fallbackFixture,
        `"status":"pilot_local_fallback"`,
        `"acceptedJobId":"forged-paid-job","status":"pilot_local_fallback"`,
      ),
      resolvedSpend,
      fallbackInspectors,
    )->ignore,
  "contains paid-acceptance fields",
)

expectPilotError(
  () =>
    validateFixture(
      fallbackFixture,
      Js.String2.replace(resolvedSpend, `"status":"failed_refunded_safety"`, `"status":"accepted"`),
      fallbackInspectors,
    )->ignore,
  "cannot have an accepted spend event",
)

let audibleFallbackInspectors: Kuku_Ep9FinalePilotGate.inspectors = {
  ...fallbackInspectors,
  probeVideo: path => {
    let video = fallbackInspectors.probeVideo(path)
    Js.String2.endsWith(path, "/C03.mp4") ? {...video, audioStreams: 1} : video
  },
}
expectPilotError(
  () => validateFixture(fallbackFixture, resolvedSpend, audibleFallbackInspectors)->ignore,
  "exactly one video stream and no audio",
)

expectPilotError(
  () =>
    validateFixture(
      Js.String2.replace(
        fallbackFixture,
        `"localFallbackOutputSha256":"${hashA}",`,
        "",
      ),
      resolvedSpend,
      fallbackInspectors,
    )->ignore,
  "localFallbackOutputSha256 is required",
)

/* This is the production-path integration check: real bytes, real hashes and
   real ffprobe metadata, with no provider/network calls. */
let manifest = "../stories/kuku/ep9prod/finale/manifests/ep9_finale_paid_shots.v1.json"
let spend = "../stories/kuku/ep9prod/finale/budget/ep9_finale_spend.v1.json"
let result = Kuku_Ep9FinalePilotGate.validate(~manifestPath=manifest, ~spendPath=spend)
check(result.pilotIds == ["B07", "B10", "C03", "C04"], "production pilot IDs")
check(result.seconds == 36.0, "production pilot duration")
check(result.quoteGate == 34.6, "production quote ceiling")
check(result.readyCount + result.acceptedCount + result.fallbackCount == 4, "production lifecycle count")
check(result.resolvedCount == result.acceptedCount + result.fallbackCount, "production resolved count")

Js.log("Kuku_Ep9FinalePilotGateTest: ok")
