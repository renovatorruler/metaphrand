/* Zero-cost structural and local-ffmpeg regression tests for the V8 proof. */

module B = Cinema_Backends
module Core = EnochBrown_ColdOpenV8Core

@val @scope("process") external exit: int => unit = "exit"

exception TestFailure(string)

let check = (condition: bool, message: string): unit =>
  if !condition {
    raise(TestFailure(message))
  }

let near = (actual: float, expected: float): bool => Js.Math.abs_float(actual -. expected) < 0.01

let expectTimelineError = (needle: string, action: unit => unit): unit => {
  let got = ref("")
  try action() catch {
  | Core.TimelineError(message) => got := message
  }
  check(Js.String2.includes(got.contents, needle), "expected timeline failure containing: " ++ needle)
}

let clip = (
  ~id: string,
  ~mode: Core.cueMode,
  ~anchor: Core.anchor,
  ~seconds: float,
): Core.clipCue => {
  id,
  assetId: "fixture",
  mode,
  anchor,
  length: Core.Fixed(seconds),
  trimStart: 0.0,
  gainDb: -6.0,
  fadeIn: 0.05,
  fadeOut: 0.05,
}

let timelineTests = (): unit => {
  let inputs: array<Core.turnInput> = [
    {id: "A", duration: 8.0, gapAfter: 0.5},
    {id: "B", duration: 4.0, gapAfter: 0.0},
  ]
  let turns = Core.buildTurnTimeline(~turns=inputs, ~initialLead=2.0)
  check(near(Core.findTurn(turns, "A").start, 2.0), "initial lead")
  check(near(Core.findTurn(turns, "B").start, 10.5), "only speech and authored gap advance dialogue")

  /* A ten-second sound overlay changes no turn start. */
  let transition = Core.resolveClip(
    ~turns,
    ~masterDuration=15.0,
    clip(~id="transition", ~mode=Core.Transition, ~anchor=Core.Absolute(0.0), ~seconds=10.0),
  )
  let bed = Core.resolveClip(
    ~turns,
    ~masterDuration=15.0,
    clip(~id="bed", ~mode=Core.Bed, ~anchor=Core.TurnStart("B", 0.0), ~seconds=4.0),
  )
  let overlap = Core.validateSfxOverlap(~turns, ~clips=[transition, bed])
  check(overlap >= 0.80, "valid sound plan must clear 80% overlap")
  check(near(Core.findTurn(turns, "B").start, 10.5), "sound overlay must not mutate dialogue timeline")

  let weakBed = Core.resolveClip(
    ~turns,
    ~masterDuration=15.0,
    clip(~id="weak", ~mode=Core.Bed, ~anchor=Core.Absolute(0.0), ~seconds=5.0),
  )
  expectTimelineError("less than 80%", () => Core.validateSfxOverlap(~turns, ~clips=[weakBed])->ignore)

  let foreground = Core.resolveClip(
    ~turns,
    ~masterDuration=15.0,
    clip(~id="foreground", ~mode=Core.Foreground, ~anchor=Core.TurnStart("A", 0.0), ~seconds=1.0),
  )
  expectTimelineError("foreground", () => Core.validateSfxOverlap(~turns, ~clips=[transition, foreground])->ignore)
}

let holdTests = (): unit => {
  let inputs: array<Core.turnInput> = [
    {id: "A", duration: 2.0, gapAfter: 1.25},
    {id: "B", duration: 2.0, gapAfter: 0.0},
  ]
  let turns = Core.buildTurnTimeline(~turns=inputs, ~initialLead=0.0)
  let holds = Core.resolveHolds(
    ~turns,
    ~turnInputs=inputs,
    ~holds=[{id: "H", afterTurnId: "A", seconds: 1.25, reason: "story turn"}],
  )
  check(near(Belt.Array.getExn(holds, 0).end_ -. Belt.Array.getExn(holds, 0).start, 1.25), "hold duration")
  Core.validateHoldsAreEmpty(~holds, ~clips=[])
  let intrusion = Core.resolveClip(
    ~turns,
    ~masterDuration=6.0,
    clip(~id="intrusion", ~mode=Core.Foreground, ~anchor=Core.TurnEnd("A", 0.2), ~seconds=0.5),
  )
  expectTimelineError("intrudes", () => Core.validateHoldsAreEmpty(~holds, ~clips=[intrusion]))
}

let revealTests = (): unit => {
  let valid: array<Core.stagedText> = [
    {id: "A", stage: Core.Ordinary, text: "A school is noisy."},
    {id: "B", stage: Core.Discovery, text: "Some pupils had been killed."},
    {id: "C", stage: Core.Eyewitness, text: "The boy reported four attackers."},
    {id: "D", stage: Core.DateReveal, text: "In 1764, before the United States."},
    {id: "E", stage: Core.TitleReveal, text: "The School Went Quiet."},
  ]
  Core.validateRevealOrder(valid)
  let bad: array<Core.stagedText> = [
    {id: "A", stage: Core.Ordinary, text: "The attackers came."},
    {id: "B", stage: Core.TitleReveal, text: "The School Went Quiet."},
  ]
  expectTimelineError("appears too early", () => Core.validateRevealOrder(bad))
}

let ffmpegMixTest = (): unit => {
  let B.Path(tmp) = B.tempDir("enoch-v8-mix-test-")
  let voice = tmp ++ "/voice.wav"
  let sfx = tmp ++ "/sfx.wav"
  let music = tmp ++ "/music.wav"
  let master = tmp ++ "/master.wav"
  B.ffmpeg(["-nostdin", "-v", "error", "-n", "-f", "lavfi", "-i", "sine=frequency=440:duration=3", "-ar", "48000", "-ac", "2", voice])
  B.ffmpeg(["-nostdin", "-v", "error", "-n", "-f", "lavfi", "-i", "sine=frequency=220:duration=3", "-ar", "48000", "-ac", "2", sfx])
  B.ffmpeg(["-nostdin", "-v", "error", "-n", "-f", "lavfi", "-i", "sine=frequency=110:duration=3", "-ar", "48000", "-ac", "2", music])
  B.ffmpeg([
    "-nostdin", "-v", "error", "-n", "-i", voice, "-i", sfx, "-i", music,
    "-filter_complex", Core.masterMixGraph(~duration=3.0), "-map", "[out]",
    "-ar", "48000", "-ac", "2", "-c:a", "pcm_s24le", master,
  ])
  check(B.exists(B.Path(master)), "synthetic three-lane master missing")
  let B.Seconds(duration) = B.probeDuration(B.Path(master))
  check(near(duration, 3.0), "synthetic three-lane master duration")
  check(B.sha256File(B.Path(master)) != B.sha256File(B.Path(voice)), "three-lane mix must differ from voice")
}

let main = (): unit => {
  timelineTests()
  holdTests()
  revealTests()
  ffmpegMixTest()
  Js.log("Enoch Brown V8 cold-open tests passed")
}

try main() catch {
| TestFailure(message) => {
    Js.log("ENOCH V8 TEST FAILED: " ++ message)
    exit(1)
  }
| Core.TimelineError(message) => {
    Js.log("ENOCH V8 TEST FAILED WITH TIMELINE ERROR: " ++ message)
    exit(1)
  }
| B.BackendError(message) => {
    Js.log("ENOCH V8 TEST FAILED WITH BACKEND ERROR: " ++ message)
    exit(1)
  }
}
