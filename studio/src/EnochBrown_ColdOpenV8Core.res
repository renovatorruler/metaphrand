/* Pure production rules for the Enoch Brown V8 cold-open proof.

   The important invariant is structural: sound and music are overlays on an
   already-timed voice lane. They never advance the dialogue cursor. Only a
   spoken turn's duration and its authored gap may move the next turn. */

exception TimelineError(string)

type cueMode = Bed | Transition | Hit | Foreground | Tail

type anchor =
  | Absolute(float)
  | TurnStart(string, float)
  | TurnEnd(string, float)

type clipLength = Fixed(float) | ToEnd(float)

type clipCue = {
  id: string,
  assetId: string,
  mode: cueMode,
  anchor: anchor,
  length: clipLength,
  trimStart: float,
  gainDb: float,
  fadeIn: float,
  fadeOut: float,
}

type resolvedClip = {
  spec: clipCue,
  start: float,
  end_: float,
}

type turnInput = {
  id: string,
  duration: float,
  gapAfter: float,
}

type turnWindow = {
  id: string,
  start: float,
  end_: float,
}

type holdSpec = {
  id: string,
  afterTurnId: string,
  seconds: float,
  reason: string,
}

type holdWindow = {
  spec: holdSpec,
  start: float,
  end_: float,
}

type revealStage =
  | Ordinary
  | Silence
  | Passerby
  | Threshold
  | Discovery
  | Survivor
  | Eyewitness
  | Reframe
  | DateReveal
  | TitleReveal

type stagedText = {
  id: string,
  stage: revealStage,
  text: string,
}

let fail = (message: string): 'a => raise(TimelineError(message))
let floatMax = (a: float, b: float): float => a > b ? a : b
let floatMin = (a: float, b: float): float => a < b ? a : b
let lower = Js.String2.toLowerCase
let contains = (value: string, fragment: string): bool => Js.String2.includes(value, fragment)

let modeName = mode => switch mode {
| Bed => "bed"
| Transition => "transition"
| Hit => "hit"
| Foreground => "foreground"
| Tail => "tail"
}

let stageName = stage => switch stage {
| Ordinary => "ordinary"
| Silence => "silence"
| Passerby => "passerby"
| Threshold => "threshold"
| Discovery => "discovery"
| Survivor => "survivor"
| Eyewitness => "eyewitness"
| Reframe => "reframe"
| DateReveal => "date"
| TitleReveal => "title"
}

let stageRank = stage => switch stage {
| Ordinary => 0
| Silence => 1
| Passerby => 2
| Threshold => 3
| Discovery => 4
| Survivor => 5
| Eyewitness => 6
| Reframe => 7
| DateReveal => 8
| TitleReveal => 9
}

let findTurn = (turns: array<turnWindow>, id: string): turnWindow =>
  switch Belt.Array.getBy(turns, turn => turn.id == id) {
  | Some(turn) => turn
  | None => fail("unknown turn anchor " ++ id)
  }

let buildTurnTimeline = (~turns: array<turnInput>, ~initialLead: float): array<turnWindow> => {
  if initialLead < 0.0 {
    fail("initial lead may not be negative")
  }
  let rows: array<turnWindow> = []
  let cursor = ref(initialLead)
  turns->Belt.Array.forEach(turn => {
    if turn.duration <= 0.2 {
      fail("turn " ++ turn.id ++ " has an invalid duration")
    }
    if turn.gapAfter < 0.0 || turn.gapAfter > 6.0 {
      fail("turn " ++ turn.id ++ " has an invalid authored gap")
    }
    let start = cursor.contents
    let end_ = start +. turn.duration
    Js.Array2.push(rows, {id: turn.id, start, end_})->ignore
    cursor := end_ +. turn.gapAfter
  })
  rows
}

let resolveAnchor = (~turns: array<turnWindow>, anchor): float => switch anchor {
| Absolute(seconds) => seconds
| TurnStart(id, offset) => findTurn(turns, id).start +. offset
| TurnEnd(id, offset) => findTurn(turns, id).end_ +. offset
}

let resolveClip = (
  ~turns: array<turnWindow>,
  ~masterDuration: float,
  spec: clipCue,
): resolvedClip => {
  let start = resolveAnchor(~turns, spec.anchor)
  let duration = switch spec.length {
  | Fixed(seconds) => seconds
  | ToEnd(endBefore) => masterDuration -. start -. endBefore
  }
  if start < 0.0 || duration <= 0.0 || start +. duration > masterDuration +. 0.001 {
    fail("cue " ++ spec.id ++ " resolves outside the master")
  }
  if spec.trimStart < 0.0 || spec.fadeIn < 0.0 || spec.fadeOut < 0.0 ||
     spec.fadeIn +. spec.fadeOut > duration {
    fail("cue " ++ spec.id ++ " has invalid trim or fades")
  }
  {spec, start, end_: start +. duration}
}

let intersection = (~aStart: float, ~aEnd: float, ~bStart: float, ~bEnd: float): float =>
  floatMax(0.0, floatMin(aEnd, bEnd) -. floatMax(aStart, bStart))

let overlapSeconds = (clip: resolvedClip, turns: array<turnWindow>): float =>
  turns->Belt.Array.reduce(0.0, (total, turn) =>
    total +. intersection(
      ~aStart=clip.start,
      ~aEnd=clip.end_,
      ~bStart=turn.start,
      ~bEnd=turn.end_,
    )
  )

let validateSfxOverlap = (~turns: array<turnWindow>, ~clips: array<resolvedClip>): float => {
  let qualifyingDuration = ref(0.0)
  let qualifyingOverlap = ref(0.0)
  clips->Belt.Array.forEachWithIndex((index, clip) => {
    if index > 0 && Belt.Array.some(Js.Array2.slice(clips, ~start=0, ~end_=index), prior => prior.spec.id == clip.spec.id) {
      fail("duplicate cue id " ++ clip.spec.id)
    }
    let duration = clip.end_ -. clip.start
    let overlap = overlapSeconds(clip, turns)
    let fraction = overlap /. duration
    switch clip.spec.mode {
    | Bed => {
        if fraction < 0.80 {
          fail("bed cue " ++ clip.spec.id ++ " overlaps narration by less than 80%")
        }
        qualifyingDuration := qualifyingDuration.contents +. duration
        qualifyingOverlap := qualifyingOverlap.contents +. overlap
      }
    | Transition => {
        if overlap <= 0.05 || duration -. overlap <= 0.05 || duration -. overlap > 4.0 {
          fail("transition cue " ++ clip.spec.id ++ " must bridge exposed and narrated audio with at most four exposed seconds")
        }
        qualifyingDuration := qualifyingDuration.contents +. duration
        qualifyingOverlap := qualifyingOverlap.contents +. overlap
      }
    | Hit => if duration > 2.5 {
        fail("hit cue " ++ clip.spec.id ++ " exceeds 2.5 seconds")
      }
    | Foreground => if overlap > 0.05 {
        fail("foreground cue " ++ clip.spec.id ++ " overlaps narration")
      }
    | Tail => {
        let finalTurn = Belt.Array.getExn(turns, Belt.Array.length(turns) - 1)
        if clip.start +. 0.001 < finalTurn.end_ {
          fail("tail cue " ++ clip.spec.id ++ " begins before narration ends")
        }
      }
    }
  })
  if qualifyingDuration.contents <= 0.0 {
    fail("sound plan has no bed or transition cue")
  }
  let aggregate = qualifyingOverlap.contents /. qualifyingDuration.contents
  if aggregate < 0.80 {
    fail("ordinary SFX overlap is below 80%")
  }
  aggregate
}

let resolveHolds = (
  ~turns: array<turnWindow>,
  ~turnInputs: array<turnInput>,
  ~holds: array<holdSpec>,
): array<holdWindow> => holds->Belt.Array.map(spec => {
  if spec.seconds < 0.5 || spec.seconds > 6.0 || Js.String2.trim(spec.reason) == "" {
    fail("hold " ++ spec.id ++ " has invalid duration or no reason")
  }
  let index = switch Belt.Array.getIndexBy(turns, turn => turn.id == spec.afterTurnId) {
  | Some(index) => index
  | None => fail("hold " ++ spec.id ++ " names an unknown turn")
  }
  if index >= Belt.Array.length(turns) - 1 {
    fail("hold " ++ spec.id ++ " must sit between spoken turns")
  }
  let prior = Belt.Array.getExn(turns, index)
  let next = Belt.Array.getExn(turns, index + 1)
  let input = Belt.Array.getExn(turnInputs, index)
  if Js.Math.abs_float(input.gapAfter -. spec.seconds) > 0.001 ||
     Js.Math.abs_float(next.start -. (prior.end_ +. spec.seconds)) > 0.01 {
    fail("hold " ++ spec.id ++ " does not own the complete authored gap")
  }
  {spec, start: prior.end_, end_: next.start}
})

let validateHoldsAreEmpty = (~holds: array<holdWindow>, ~clips: array<resolvedClip>): unit =>
  holds->Belt.Array.forEach(hold => clips->Belt.Array.forEach(clip => {
    if intersection(
      ~aStart=hold.start,
      ~aEnd=hold.end_,
      ~bStart=clip.start,
      ~bEnd=clip.end_,
    ) > 0.01 {
      fail("cue " ++ clip.spec.id ++ " intrudes on hold " ++ hold.spec.id)
    }
  }))

let requireStage = (rows: array<stagedText>, fragment: string, earliest: revealStage): unit =>
  rows->Belt.Array.forEach(row => {
    if contains(lower(row.text), fragment) && stageRank(row.stage) < stageRank(earliest) {
      fail("protected reveal '" ++ fragment ++ "' appears too early in " ++ row.id)
    }
  })

let validateRevealOrder = (rows: array<stagedText>): unit => {
  let previous = ref(-1)
  rows->Belt.Array.forEach(row => {
    let rank = stageRank(row.stage)
    if rank < previous.contents {
      fail("reveal stages move backwards at " ++ row.id)
    }
    previous := rank
  })
  requireStage(rows, "brown", Discovery)
  requireStage(rows, "dead", Discovery)
  requireStage(rows, "wounded", Survivor)
  requireStage(rows, "attackers", Eyewitness)
  requireStage(rows, "killed", Discovery)
  requireStage(rows, "1764", DateReveal)
  requireStage(rows, "declaration", DateReveal)
  requireStage(rows, "united states", DateReveal)
  requireStage(rows, "massacre", DateReveal)
  requireStage(rows, "the school went quiet", TitleReveal)
  ["colonial", "pennsylvania", "lenape", "indian"]->Belt.Array.forEach(fragment =>
    requireStage(rows, fragment, DateReveal)
  )
}

let validateAnomalyTiming = (~turns: array<turnWindow>, ~silenceTurnId: string): unit => {
  let anomaly = findTurn(turns, silenceTurnId).start
  if anomaly > 25.0 {
    fail("silence/anomaly beat begins after 25 seconds")
  }
}

let masterMixConfig =
  "v8-master|48k-stereo|sfx-sc=0.025/8/5/220|music-sc=0.018/6/20/400|loudnorm=-15.5/-2/9|limit=.82-level-disabled"

let masterMixGraph = (~duration: float): string =>
  "[0:a]aformat=sample_fmts=fltp:channel_layouts=stereo,asplit=3[voice][sfx_key][music_key];" ++
  "[1:a][sfx_key]sidechaincompress=threshold=0.025:ratio=8:attack=5:release=220:makeup=1[ducked_sfx];" ++
  "[2:a][music_key]sidechaincompress=threshold=0.018:ratio=6:attack=20:release=400:makeup=1[ducked_music];" ++
  "[voice][ducked_sfx][ducked_music]amix=inputs=3:duration=first:normalize=0:dropout_transition=0," ++
  "atrim=0:" ++ Js.Float.toString(duration) ++ "," ++
  "loudnorm=I=-15.5:TP=-2:LRA=9,alimiter=limit=0.82:level=disabled[out]"
