/*
 * Zero-spend, fail-closed lifecycle gate for the four Episode 9 calibration
 * pilots. This module only reads manifests/files and invokes ffprobe. It has no
 * provider client and no submission path.
 */

module B = Cinema_Backends

@module("node:path") external dirname: string => string = "dirname"
@module("node:path") external resolve2: (string, string) => string = "resolve"

exception PilotGateError(string)

let die = message => raise(PilotGateError(message))

let objectOf = (json, where) =>
  switch Js.Json.decodeObject(json) {
  | Some(value) => value
  | None => die(where ++ " must be an object")
  }

let field = (object_, key, where) =>
  switch Js.Dict.get(object_, key) {
  | Some(value) => value
  | None => die(where ++ "." ++ key ++ " is required")
  }

let stringField = (object_, key, where) =>
  switch field(object_, key, where)->Js.Json.decodeString {
  | Some(value) if value != "" => value
  | Some(_) => die(where ++ "." ++ key ++ " must not be empty")
  | None => die(where ++ "." ++ key ++ " must be a string")
  }

let optionalStringField = (object_, key, where) =>
  switch Js.Dict.get(object_, key) {
  | None => None
  | Some(value) =>
    switch Js.Json.decodeString(value) {
    | Some(decoded) if decoded != "" => Some(decoded)
    | Some(_) => die(where ++ "." ++ key ++ " must not be empty when present")
    | None => die(where ++ "." ++ key ++ " must be a string when present")
    }
  }

let numberField = (object_, key, where) =>
  switch field(object_, key, where)->Js.Json.decodeNumber {
  | Some(value) => value
  | None => die(where ++ "." ++ key ++ " must be a number")
  }

let optionalNumberField = (object_, key, where) =>
  switch Js.Dict.get(object_, key) {
  | None => None
  | Some(value) =>
    switch Js.Json.decodeNumber(value) {
    | Some(decoded) => Some(decoded)
    | None => die(where ++ "." ++ key ++ " must be a number when present")
    }
  }

let arrayField = (object_, key, where) =>
  switch field(object_, key, where)->Js.Json.decodeArray {
  | Some(value) => value
  | None => die(where ++ "." ++ key ++ " must be an array")
  }

let close = (left, right) => Js.Math.abs_float(left -. right) < 0.0001

type frameProbe = {width: float, height: float, sampleAspectRatio: string}

type videoProbe = {
  width: float,
  height: float,
  duration: float,
  fps: float,
  videoStreams: int,
  audioStreams: int,
}

type inspectors = {
  exists: string => bool,
  sha256: string => string,
  probeFrame: string => frameProbe,
  probeVideo: string => videoProbe,
}

type pilotRule = {
  id: string,
  classId: string,
  model: string,
  variant: option<string>,
  duration: float,
  quoteGate: float,
  minimumWidth: float,
  minimumHeight: float,
  maximumWidth: float,
  maximumHeight: float,
  minimumFps: float,
  maximumFps: float,
  durationTolerance: float,
  localFallbackAllowed: bool,
}

let pilotRules = [
  {
    id: "B07",
    classId: "B_WIDE_ENVIRONMENT",
    model: "veo3_1_lite",
    variant: None,
    duration: 8.0,
    quoteGate: 8.0,
    minimumWidth: 1280.0,
    minimumHeight: 720.0,
    maximumWidth: 1920.0,
    maximumHeight: 1080.0,
    minimumFps: 23.0,
    maximumFps: 30.1,
    durationTolerance: 0.75,
    localFallbackAllowed: false,
  },
  {
    id: "B10",
    classId: "B_WIDE_ENVIRONMENT",
    model: "minimax_hailuo",
    variant: Some("minimax-2.3-fast"),
    duration: 10.0,
    quoteGate: 7.0,
    minimumWidth: 1280.0,
    minimumHeight: 720.0,
    maximumWidth: 1920.0,
    maximumHeight: 1080.0,
    minimumFps: 23.0,
    maximumFps: 25.0,
    durationTolerance: 0.75,
    localFallbackAllowed: false,
  },
  {
    id: "C03",
    classId: "C_SIMPLE_CHARACTER",
    model: "seedance1_5",
    variant: None,
    duration: 8.0,
    quoteGate: 9.6,
    minimumWidth: 960.0,
    minimumHeight: 540.0,
    maximumWidth: 1920.0,
    maximumHeight: 1080.0,
    minimumFps: 23.0,
    maximumFps: 30.1,
    durationTolerance: 0.75,
    localFallbackAllowed: true,
  },
  {
    id: "C04",
    classId: "C_SIMPLE_CHARACTER",
    model: "kling2_6",
    variant: None,
    duration: 10.0,
    quoteGate: 10.0,
    minimumWidth: 1280.0,
    minimumHeight: 720.0,
    maximumWidth: 1920.0,
    maximumHeight: 1080.0,
    minimumFps: 23.0,
    maximumFps: 30.1,
    durationTolerance: 0.75,
    localFallbackAllowed: false,
  },
]

type result = {
  pilotIds: array<string>,
  seconds: float,
  quoteGate: float,
  readyCount: int,
  acceptedCount: int,
  fallbackCount: int,
  resolvedCount: int,
  acceptedCredits: float,
}

let expectSha256 = (id, label, declared, absolutePath, inspectors) => {
  if !Js.Re.test_(%re("/^[a-f0-9]{64}$/"), declared) {
    die(id ++ " " ++ label ++ " SHA-256 must be 64 lowercase hexadecimal characters")
  }
  if !inspectors.exists(absolutePath) {
    die(id ++ " " ++ label ++ " is missing: " ++ absolutePath)
  }
  let actual = inspectors.sha256(absolutePath)
  if actual != declared {
    die(id ++ " " ++ label ++ " bytes do not match the declared SHA-256")
  }
}

let acceptedEventStatus = status =>
  status == "accepted" || status == "accepted_with_local_motion_dependency"

let validateLifecycleRaw = (
  ~manifestRaw,
  ~manifestDirectory,
  ~spendRaw,
  ~spendDirectory,
  ~inspectors,
): result => {
  let root = try manifestRaw->Js.Json.parseExn->objectOf("shot manifest") catch {
  | Js.Exn.Error(error) =>
    die(
      "shot manifest is not valid JSON: " ++
      Js.Exn.message(error)->Belt.Option.getWithDefault("unknown parse error"),
    )
  }
  let spendRoot = try spendRaw->Js.Json.parseExn->objectOf("spend ledger") catch {
  | Js.Exn.Error(error) =>
    die(
      "spend ledger is not valid JSON: " ++
      Js.Exn.message(error)->Belt.Option.getWithDefault("unknown parse error"),
    )
  }
  let expectedIds = Js.Dict.empty()
  pilotRules->Belt.Array.forEach(rule => Js.Dict.set(expectedIds, rule.id, true))

  let acceptedEvents: Js.Dict.t<array<Js.Dict.t<Js.Json.t>>> = Js.Dict.empty()
  let pilotEvents: Js.Dict.t<array<Js.Dict.t<Js.Json.t>>> = Js.Dict.empty()
  let ledgerJobIds = Js.Dict.empty()
  arrayField(spendRoot, "events", "spend ledger")->Belt.Array.forEachWithIndex((index, eventJson) => {
    let where = "spend ledger.events[" ++ Belt.Int.toString(index) ++ "]"
    let event = objectOf(eventJson, where)
    let targetId = stringField(event, "targetId", where)
    let jobId = stringField(event, "jobId", where)
    switch Js.Dict.get(ledgerJobIds, jobId) {
    | Some(owner) => die("duplicate spend-ledger jobId " ++ jobId ++ " on " ++ targetId ++ " and " ++ owner)
    | None => Js.Dict.set(ledgerJobIds, jobId, targetId)
    }
    if Js.Dict.get(expectedIds, targetId) != None {
      let allTargetEvents = switch Js.Dict.get(pilotEvents, targetId) {
      | Some(value) => value
      | None => {
          let value = []
          Js.Dict.set(pilotEvents, targetId, value)
          value
        }
      }
      allTargetEvents->Js.Array2.push(event)->ignore
      let status = stringField(event, "status", where)
      if acceptedEventStatus(status) {
        let events = switch Js.Dict.get(acceptedEvents, targetId) {
        | Some(value) => value
        | None => {
            let value = []
            Js.Dict.set(acceptedEvents, targetId, value)
            value
          }
        }
        events->Js.Array2.push(event)->ignore
      } else if Js.String2.startsWith(status, "accepted") {
        die(targetId ++ " uses an unrecognized accepted spend status: " ++ status)
      }
    }
  })

  let allIds = Js.Dict.empty()
  let allPaths = Js.Dict.empty()
  let pilots: Js.Dict.t<Js.Dict.t<Js.Json.t>> = Js.Dict.empty()
  let lifecycleCount = ref(0)

  arrayField(root, "shots", "shot manifest")->Belt.Array.forEachWithIndex((index, shotJson) => {
    let where = "shot manifest.shots[" ++ Belt.Int.toString(index) ++ "]"
    let shot = objectOf(shotJson, where)
    let id = stringField(shot, "id", where)
    if Js.Dict.get(allIds, id) != None {
      die("duplicate shot id: " ++ id)
    }
    Js.Dict.set(allIds, id, true)

    ["promptFile", "startFrame", "output"]->Belt.Array.forEach(key => {
      let relative = stringField(shot, key, where)
      let absolute = resolve2(manifestDirectory, relative)
      switch Js.Dict.get(allPaths, absolute) {
      | Some(owner) => die(id ++ "." ++ key ++ " duplicates the path declared by " ++ owner)
      | None => Js.Dict.set(allPaths, absolute, id ++ "." ++ key)
      }
    })

    let status = stringField(shot, "status", where)
    if status == "pilot_ready" || status == "pilot_accepted" || status == "pilot_local_fallback" {
      lifecycleCount := lifecycleCount.contents + 1
      if Js.Dict.get(expectedIds, id) == None {
        die("unexpected calibration lifecycle shot: " ++ id)
      }
    }
    if Js.Dict.get(expectedIds, id) != None {
      Js.Dict.set(pilots, id, shot)
    }
  })

  if lifecycleCount.contents != Belt.Array.length(pilotRules) {
    die("exactly four calibration shots must be ready, accepted, or an approved local fallback")
  }

  let seconds = ref(0.0)
  let quoteGate = ref(0.0)
  let pilotIds: array<string> = []
  let readyCount = ref(0)
  let acceptedCount = ref(0)
  let fallbackCount = ref(0)
  let acceptedCredits = ref(0.0)

  pilotRules->Belt.Array.forEach(rule => {
    let shot = switch Js.Dict.get(pilots, rule.id) {
    | Some(value) => value
    | None => die("required calibration shot is missing: " ++ rule.id)
    }
    let where = "calibration shot " ++ rule.id
    let lifecycleStatus = stringField(shot, "status", where)
    if lifecycleStatus != "pilot_ready" && lifecycleStatus != "pilot_accepted" &&
       lifecycleStatus != "pilot_local_fallback" {
      die(rule.id ++ " has an invalid calibration lifecycle state")
    }
    if stringField(shot, "classId", where) != rule.classId ||
       stringField(shot, "model", where) != rule.model ||
       optionalStringField(shot, "variant", where) != rule.variant ||
       !close(numberField(shot, "durationSeconds", where), rule.duration) ||
       !close(numberField(shot, "quoteGate", where), rule.quoteGate) {
      die(rule.id ++ " model, variant, duration, class, or quote gate drifted")
    }

    let prompt = resolve2(manifestDirectory, stringField(shot, "promptFile", where))
    let startFrame = resolve2(manifestDirectory, stringField(shot, "startFrame", where))
    let output = resolve2(manifestDirectory, stringField(shot, "output", where))
    let promptSha = stringField(shot, "promptSha256", where)
    let startFrameSha = stringField(shot, "startFrameSha256", where)

    expectSha256(rule.id, "prompt", promptSha, prompt, inspectors)
    expectSha256(rule.id, "start frame", startFrameSha, startFrame, inspectors)
    let probe = inspectors.probeFrame(startFrame)
    if probe.width != 1280.0 || probe.height != 720.0 || probe.sampleAspectRatio != "1:1" {
      die(
        rule.id ++ " start frame must be exactly 1280x720 with 1:1 sample aspect ratio; got " ++
        Js.Float.toString(probe.width) ++ "x" ++ Js.Float.toString(probe.height) ++ " SAR " ++
        probe.sampleAspectRatio,
      )
    }
    /* Re-hash after ffprobe so a concurrent replacement cannot pass by changing
       between the integrity and geometry checks. */
    if inspectors.sha256(prompt) != promptSha || inspectors.sha256(startFrame) != startFrameSha {
      die(rule.id ++ " input bytes changed while the pilot gate was running")
    }

    let matchingEvents = Js.Dict.get(acceptedEvents, rule.id)->Belt.Option.getWithDefault([])
    if lifecycleStatus == "pilot_ready" {
      readyCount := readyCount.contents + 1
      if optionalStringField(shot, "outputSha256", where) != None ||
         optionalStringField(shot, "acceptedJobId", where) != None ||
         optionalNumberField(shot, "acceptedAttempt", where) != None ||
         optionalStringField(shot, "acceptanceDependency", where) != None ||
         optionalStringField(shot, "fallbackMethod", where) != None ||
         optionalStringField(shot, "fallbackSource", where) != None ||
         optionalStringField(shot, "fallbackSourceSha256", where) != None ||
         optionalStringField(shot, "localFallbackOutput", where) != None ||
         optionalStringField(shot, "localFallbackOutputSha256", where) != None ||
         optionalStringField(shot, "localFallbackProvenance", where) != None ||
         optionalNumberField(shot, "failedAttempts", where) != None {
        die(rule.id ++ " pilot_ready record contains resolved-state fields")
      }
      if inspectors.exists(output) {
        die(rule.id ++ " is pilot_ready but its output already exists")
      }
      if Belt.Array.length(matchingEvents) != 0 {
        die(rule.id ++ " is pilot_ready but the spend ledger already contains an accepted event")
      }
    } else if lifecycleStatus == "pilot_accepted" {
      acceptedCount := acceptedCount.contents + 1
      if optionalStringField(shot, "fallbackMethod", where) != None ||
         optionalStringField(shot, "fallbackSource", where) != None ||
         optionalStringField(shot, "fallbackSourceSha256", where) != None ||
         optionalStringField(shot, "localFallbackOutput", where) != None ||
         optionalStringField(shot, "localFallbackOutputSha256", where) != None ||
         optionalStringField(shot, "localFallbackProvenance", where) != None ||
         optionalNumberField(shot, "failedAttempts", where) != None {
        die(rule.id ++ " pilot_accepted record contains local-fallback fields")
      }
      let outputSha = stringField(shot, "outputSha256", where)
      let acceptedJobId = stringField(shot, "acceptedJobId", where)
      let acceptedAttempt = numberField(shot, "acceptedAttempt", where)
      if acceptedAttempt != 1.0 && acceptedAttempt != 2.0 {
        die(rule.id ++ " acceptedAttempt must be one or two")
      }
      expectSha256(rule.id, "accepted output", outputSha, output, inspectors)
      let video = inspectors.probeVideo(output)
      let aspect = video.width /. video.height
      if video.videoStreams != 1 || video.audioStreams != 0 {
        die(rule.id ++ " accepted output must contain exactly one video stream and no native audio")
      }
      if video.width < rule.minimumWidth || video.width > rule.maximumWidth ||
         video.height < rule.minimumHeight || video.height > rule.maximumHeight ||
         aspect < 1.74 || aspect > 1.80 {
        die(
          rule.id ++ " accepted output resolution/aspect is not sane for " ++ rule.model ++ ": " ++
          Js.Float.toString(video.width) ++ "x" ++ Js.Float.toString(video.height),
        )
      }
      if video.fps < rule.minimumFps || video.fps > rule.maximumFps {
        die(
          rule.id ++ " accepted output frame rate is not sane for " ++ rule.model ++ ": " ++
          Js.Float.toString(video.fps) ++ " fps",
        )
      }
      if Js.Math.abs_float(video.duration -. rule.duration) > rule.durationTolerance {
        die(
          rule.id ++ " accepted output duration drifted from its locked model duration: " ++
          Js.Float.toString(video.duration) ++ "s",
        )
      }
      if inspectors.sha256(output) != outputSha {
        die(rule.id ++ " accepted output bytes changed while the lifecycle gate was running")
      }

      if Belt.Array.length(matchingEvents) != 1 {
        die(rule.id ++ " must have exactly one matching accepted spend event")
      }
      let event = Belt.Array.getExn(matchingEvents, 0)
      let eventWhere = "accepted spend event for " ++ rule.id
      let eventStatus = stringField(event, "status", eventWhere)
      let eventActualCredits = numberField(event, "actualCredits", eventWhere)
      let eventOutput = resolve2(spendDirectory, stringField(event, "output", eventWhere))
      if stringField(event, "classId", eventWhere) != rule.classId ||
         stringField(event, "model", eventWhere) != rule.model ||
         optionalStringField(event, "variant", eventWhere) != rule.variant ||
         !close(numberField(event, "durationSeconds", eventWhere), rule.duration) ||
         !close(numberField(event, "quoteCredits", eventWhere), rule.quoteGate) ||
         numberField(event, "attempt", eventWhere) != acceptedAttempt ||
         stringField(event, "jobId", eventWhere) != acceptedJobId ||
         stringField(event, "promptSha256", eventWhere) != promptSha ||
         stringField(event, "inputSha256", eventWhere) != startFrameSha ||
         stringField(event, "outputSha256", eventWhere) != outputSha ||
         eventOutput != output {
        die(rule.id ++ " accepted shot and spend-ledger event do not match exactly")
      }
      if eventActualCredits <= 0.0 || eventActualCredits > rule.quoteGate {
        die(rule.id ++ " accepted spend exceeds its quote or is not a positive charge")
      }

      let dependency = optionalStringField(shot, "acceptanceDependency", where)
      if rule.id == "B10" {
        switch dependency {
        | Some(value) =>
          let lower = Js.String2.toLowerCase(value)
          if !Js.String2.includes(lower, "local") || !Js.String2.includes(lower, "crack") {
            die("B10 acceptanceDependency must document the local crack-accent work")
          }
        | None => die("B10 pilot acceptance requires a documented local crack-accent dependency")
        }
      }
      switch dependency {
      | Some(value) =>
        if eventStatus != "accepted_with_local_motion_dependency" ||
           optionalStringField(event, "dependency", eventWhere) != Some(value) {
          die(rule.id ++ " local acceptance dependency does not match its spend event")
        }
      | None =>
        if eventStatus != "accepted" || optionalStringField(event, "dependency", eventWhere) != None {
          die(rule.id ++ " dependency-free acceptance must use a plain accepted spend event")
        }
      }
      acceptedCredits := acceptedCredits.contents +. eventActualCredits
    } else {
      fallbackCount := fallbackCount.contents + 1
      if !rule.localFallbackAllowed {
        die(rule.id ++ " is not approved for the pilot_local_fallback state")
      }
      if optionalStringField(shot, "outputSha256", where) != None ||
         optionalStringField(shot, "acceptedJobId", where) != None ||
         optionalNumberField(shot, "acceptedAttempt", where) != None ||
         optionalStringField(shot, "acceptanceDependency", where) != None {
        die(rule.id ++ " pilot_local_fallback record contains paid-acceptance fields")
      }
      if numberField(shot, "failedAttempts", where) != 2.0 {
        die(rule.id ++ " pilot_local_fallback must declare exactly two failedAttempts")
      }
      let fallbackMethod = stringField(shot, "fallbackMethod", where)
      let methodLower = Js.String2.toLowerCase(fallbackMethod)
      if rule.id == "C03" &&
         (!Js.String2.includes(methodLower, "local") ||
          !Js.String2.includes(methodLower, "2.5d") ||
          !Js.String2.includes(methodLower, "hop") ||
          !Js.String2.includes(methodLower, "landing")) {
        die("C03 fallbackMethod must document the local 2.5D hop and landing animation")
      }
      let fallbackSource = resolve2(manifestDirectory, stringField(shot, "fallbackSource", where))
      let fallbackSourceSha = stringField(shot, "fallbackSourceSha256", where)
      if fallbackSource != startFrame || fallbackSourceSha != startFrameSha {
        die(rule.id ++ " fallback source must be the exact locked start frame")
      }
      expectSha256(rule.id, "fallback source", fallbackSourceSha, fallbackSource, inspectors)
      if inspectors.sha256(fallbackSource) != fallbackSourceSha {
        die(rule.id ++ " fallback source bytes changed while the lifecycle gate was running")
      }
      if Belt.Array.length(matchingEvents) != 0 {
        die(rule.id ++ " local fallback cannot have an accepted spend event")
      }

      let localOutput = resolve2(
        manifestDirectory,
        stringField(shot, "localFallbackOutput", where),
      )
      if localOutput != output {
        die(rule.id ++ " localFallbackOutput must be the shot's canonical output path")
      }
      let localOutputSha = stringField(shot, "localFallbackOutputSha256", where)
      expectSha256(rule.id, "local fallback output", localOutputSha, localOutput, inspectors)
      let provenance = stringField(shot, "localFallbackProvenance", where)
      let provenanceLower = Js.String2.toLowerCase(provenance)
      if rule.id == "C03" &&
         (!Js.String2.includes(provenanceLower, "rescript") ||
          !Js.String2.includes(provenanceLower, "ffmpeg") ||
          !Js.String2.includes(provenanceLower, "zero-credit") ||
          !Js.String2.includes(provenanceLower, "locked start frame") ||
          !Js.String2.includes(provenanceLower, "four") ||
          !Js.String2.includes(provenanceLower, "witness")) {
        die(
          "C03 localFallbackProvenance must bind the zero-credit ReScript/ffmpeg build " ++
          "to the locked start frame and four witnesses",
        )
      }
      let localVideo = inspectors.probeVideo(localOutput)
      if localVideo.videoStreams != 1 || localVideo.audioStreams != 0 {
        die(rule.id ++ " local fallback output must contain exactly one video stream and no audio")
      }
      if localVideo.width != 1280.0 || localVideo.height != 720.0 {
        die(rule.id ++ " local fallback output must be exactly 1280x720")
      }
      if Js.Math.abs_float(localVideo.fps -. 24.0) > 0.01 {
        die(rule.id ++ " local fallback output must be exactly 24 fps")
      }
      if Js.Math.abs_float(localVideo.duration -. rule.duration) > 0.05 {
        die(rule.id ++ " local fallback output must be exactly eight seconds")
      }
      if inspectors.sha256(localOutput) != localOutputSha {
        die(rule.id ++ " local fallback output bytes changed while the lifecycle gate was running")
      }

      let failures = Js.Dict.get(pilotEvents, rule.id)->Belt.Option.getWithDefault([])
      if Belt.Array.length(failures) != 2 {
        die(rule.id ++ " local fallback requires exactly two ledger attempts and forbids a third")
      }
      let failureAttempts = Js.Dict.empty()
      failures->Belt.Array.forEachWithIndex((index, event) => {
        let eventWhere =
          "refunded safety event " ++ Belt.Int.toString(index + 1) ++ " for " ++ rule.id
        let attempt = numberField(event, "attempt", eventWhere)
        if attempt != 1.0 && attempt != 2.0 {
          die(rule.id ++ " refunded safety attempts must be numbered one and two")
        }
        let attemptKey = Js.Float.toString(attempt)
        if Js.Dict.get(failureAttempts, attemptKey) != None {
          die(rule.id ++ " refunded safety attempts must be distinct")
        }
        Js.Dict.set(failureAttempts, attemptKey, true)
        let eventPromptSha = stringField(event, "promptSha256", eventWhere)
        if !Js.Re.test_(%re("/^[a-f0-9]{64}$/"), eventPromptSha) ||
           (attempt == 2.0 && eventPromptSha != promptSha) {
          die(rule.id ++ " refunded retry prompt is not bound to the locked final prompt")
        }
        if stringField(event, "status", eventWhere) != "failed_refunded_safety" ||
           stringField(event, "classId", eventWhere) != rule.classId ||
           stringField(event, "model", eventWhere) != rule.model ||
           optionalStringField(event, "variant", eventWhere) != rule.variant ||
           !close(numberField(event, "durationSeconds", eventWhere), rule.duration) ||
           !close(numberField(event, "quoteCredits", eventWhere), rule.quoteGate) ||
           numberField(event, "actualCredits", eventWhere) != 0.0 ||
           stringField(event, "inputSha256", eventWhere) != startFrameSha {
          die(rule.id ++ " refunded safety attempt does not match the locked pilot")
        }
        if optionalStringField(event, "output", eventWhere) != None ||
           optionalStringField(event, "outputSha256", eventWhere) != None ||
           optionalStringField(event, "resultUrl", eventWhere) != None {
          die(rule.id ++ " refunded safety attempt must not claim a provider output")
        }
      })
    }

    pilotIds->Js.Array2.push(rule.id)->ignore
    seconds := seconds.contents +. rule.duration
    quoteGate := quoteGate.contents +. rule.quoteGate
  })

  if !close(seconds.contents, 36.0) || !close(quoteGate.contents, 34.6) {
    die("calibration pilot totals must remain 36 seconds and 34.6 quoted credits")
  }
  {
    pilotIds,
    seconds: seconds.contents,
    quoteGate: quoteGate.contents,
    readyCount: readyCount.contents,
    acceptedCount: acceptedCount.contents,
    fallbackCount: fallbackCount.contents,
    resolvedCount: acceptedCount.contents + fallbackCount.contents,
    acceptedCredits: acceptedCredits.contents,
  }
}

let probeStartFrame = absolutePath => {
  let run = B.run(
    ~cmd="ffprobe",
    ~args=[
      "-v",
      "error",
      "-select_streams",
      "v:0",
      "-show_entries",
      "stream=width,height,sample_aspect_ratio",
      "-of",
      "json",
      absolutePath,
    ],
  )
  if run.code != 0 {
    die(
      "ffprobe failed for " ++ absolutePath ++ ": " ++
      (run.stderr == "" ? "exit " ++ Belt.Int.toString(run.code) : Js.String2.trim(run.stderr)),
    )
  }
  let root = try run.stdout->Js.Json.parseExn->objectOf("ffprobe result") catch {
  | Js.Exn.Error(error) =>
    die(
      "ffprobe returned invalid JSON for " ++ absolutePath ++ ": " ++
      Js.Exn.message(error)->Belt.Option.getWithDefault("unknown parse error"),
    )
  }
  let streams = arrayField(root, "streams", "ffprobe result")
  if Belt.Array.length(streams) != 1 {
    die("ffprobe must find exactly one first video stream in " ++ absolutePath)
  }
  let stream = Belt.Array.getExn(streams, 0)->objectOf("ffprobe result.streams[0]")
  {
    width: numberField(stream, "width", "ffprobe result.streams[0]"),
    height: numberField(stream, "height", "ffprobe result.streams[0]"),
    sampleAspectRatio: stringField(stream, "sample_aspect_ratio", "ffprobe result.streams[0]"),
  }
}

let rational = (value, where) => {
  let pieces = Js.String2.split(value, "/")
  switch (Belt.Array.get(pieces, 0), Belt.Array.get(pieces, 1)) {
  | (Some(numeratorText), Some(denominatorText)) =>
    switch (Belt.Float.fromString(numeratorText), Belt.Float.fromString(denominatorText)) {
    | (Some(numerator), Some(denominator)) if denominator > 0.0 => numerator /. denominator
    | _ => die(where ++ " must be a positive rational frame rate")
    }
  | _ => die(where ++ " must be expressed as numerator/denominator")
  }
}

let probeAcceptedVideo = absolutePath => {
  let run = B.run(
    ~cmd="ffprobe",
    ~args=[
      "-v",
      "error",
      "-show_entries",
      "stream=codec_type,width,height,avg_frame_rate,r_frame_rate:format=duration",
      "-of",
      "json",
      absolutePath,
    ],
  )
  if run.code != 0 {
    die(
      "ffprobe failed for accepted output " ++ absolutePath ++ ": " ++
      (run.stderr == "" ? "exit " ++ Belt.Int.toString(run.code) : Js.String2.trim(run.stderr)),
    )
  }
  let root = try run.stdout->Js.Json.parseExn->objectOf("accepted-output ffprobe result") catch {
  | Js.Exn.Error(error) =>
    die(
      "ffprobe returned invalid accepted-output JSON for " ++ absolutePath ++ ": " ++
      Js.Exn.message(error)->Belt.Option.getWithDefault("unknown parse error"),
    )
  }
  let videoStreams = ref(0)
  let audioStreams = ref(0)
  let width = ref(0.0)
  let height = ref(0.0)
  let fps = ref(0.0)
  arrayField(root, "streams", "accepted-output ffprobe result")
  ->Belt.Array.forEachWithIndex((index, streamJson) => {
    let where = "accepted-output ffprobe result.streams[" ++ Belt.Int.toString(index) ++ "]"
    let stream = objectOf(streamJson, where)
    switch stringField(stream, "codec_type", where) {
    | "video" => {
        videoStreams := videoStreams.contents + 1
        width := numberField(stream, "width", where)
        height := numberField(stream, "height", where)
        let average = stringField(stream, "avg_frame_rate", where)->rational(where ++ ".avg_frame_rate")
        fps := (
          average > 0.0
            ? average
            : stringField(stream, "r_frame_rate", where)->rational(where ++ ".r_frame_rate")
        )
      }
    | "audio" => audioStreams := audioStreams.contents + 1
    | _ => ()
    }
  })
  let format = field(root, "format", "accepted-output ffprobe result")
    ->objectOf("accepted-output ffprobe result.format")
  let duration = switch stringField(format, "duration", "accepted-output ffprobe result.format")
    ->Belt.Float.fromString {
  | Some(value) if value > 0.0 => value
  | _ => die("accepted-output ffprobe duration must be a positive number")
  }
  {
    width: width.contents,
    height: height.contents,
    duration,
    fps: fps.contents,
    videoStreams: videoStreams.contents,
    audioStreams: audioStreams.contents,
  }
}

let productionInspectors: inspectors = {
  exists: path => B.exists(B.Path(path)),
  sha256: path => B.sha256File(B.Path(path)),
  probeFrame: probeStartFrame,
  probeVideo: probeAcceptedVideo,
}

let validate = (~manifestPath, ~spendPath): result => {
  let manifestRaw = try B.readText(B.Path(manifestPath)) catch {
  | B.BackendError(message) => die("shot manifest cannot be read: " ++ message)
  }
  let manifestSha = B.sha256Text(manifestRaw)
  let spendRaw = try B.readText(B.Path(spendPath)) catch {
  | B.BackendError(message) => die("spend ledger cannot be read: " ++ message)
  }
  let spendSha = B.sha256Text(spendRaw)

  /* Preserve all 45-shot budget/model/path invariants before narrowing to the
     four pilots. */
  Kuku_Ep9FinaleShotPlan.validate(~manifestPath)->ignore
  let result = validateLifecycleRaw(
    ~manifestRaw,
    ~manifestDirectory=dirname(manifestPath),
    ~spendRaw,
    ~spendDirectory=dirname(spendPath),
    ~inspectors=productionInspectors,
  )
  let finalRaw = try B.readText(B.Path(manifestPath)) catch {
  | B.BackendError(message) => die("shot manifest cannot be re-read: " ++ message)
  }
  if B.sha256Text(finalRaw) != manifestSha {
    die("shot manifest changed while the pilot gate was running")
  }
  let finalSpendRaw = try B.readText(B.Path(spendPath)) catch {
  | B.BackendError(message) => die("spend ledger cannot be re-read: " ++ message)
  }
  if B.sha256Text(finalSpendRaw) != spendSha {
    die("spend ledger changed while the pilot gate was running")
  }
  result
}

let printResult = result => {
  Js.log("KUKU EP9 CALIBRATION PILOT GATE — READY")
  Js.log(
    result.pilotIds->Js.Array2.joinWith(", ") ++ " | " ++ Js.Float.toString(result.seconds) ++
    "s | quote ceiling " ++ Js.Float.toString(result.quoteGate) ++ " credits",
  )
  Js.log(
    Belt.Int.toString(result.readyCount) ++ " ready | " ++
    Belt.Int.toString(result.acceptedCount) ++ " accepted | " ++
    Belt.Int.toString(result.fallbackCount) ++ " local fallback | " ++
    Belt.Int.toString(result.resolvedCount) ++ " resolved | " ++
    Js.Float.toString(result.acceptedCredits) ++ " accepted credits",
  )
  Js.log("All lifecycle states, exact hashes, media probes, and accepted spend events agree.")
}
