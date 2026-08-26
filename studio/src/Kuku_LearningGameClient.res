type domDocument
type browserWindow
type canvas
type context
type gradient
type textMetrics
type domRect
type domEvent
type imageElement
type response
type promise<'a>
type storage
type urlSearchParams
type audioContext
type oscillator
type gainNode
type audioParam
type audioDestination
type audioElement
type audioSession
type speechSynthesis
type speechVoice
type speechUtterance
type gameNavigator
type gamepad
type gamepadButton

@val external browserDocument: domDocument = "document"
@val external browserWindow: browserWindow = "window"
@val external requestAnimationFrame: (float => unit) => int = "requestAnimationFrame"
@val external fetchResource: string => promise<response> = "fetch"

@send external getElementById: (domDocument, string) => canvas = "getElementById"
@set external setDocumentTitle: (domDocument, string) => unit = "title"
@get external windowWidth: browserWindow => int = "innerWidth"
@get external windowHeight: browserWindow => int = "innerHeight"
@get external windowDpr: browserWindow => float = "devicePixelRatio"
@send external addWindowListener: (browserWindow, string, domEvent => unit) => unit = "addEventListener"
@send external addCanvasListener: (canvas, string, domEvent => unit) => unit = "addEventListener"
@send external setCanvasAttribute: (canvas, string, string) => unit = "setAttribute"
@send external preventDefault: domEvent => unit = "preventDefault"
@get external eventCode: domEvent => string = "code"
@get external eventRepeat: domEvent => bool = "repeat"
@get external eventClientX: domEvent => float = "clientX"
@get external eventClientY: domEvent => float = "clientY"

@set external setCanvasWidth: (canvas, int) => unit = "width"
@set external setCanvasHeight: (canvas, int) => unit = "height"
@send external getCanvasContext: (canvas, string) => context = "getContext"
@send external canvasRect: canvas => domRect = "getBoundingClientRect"
@get external rectLeft: domRect => float = "left"
@get external rectTop: domRect => float = "top"
@get external rectWidth: domRect => float = "width"
@get external rectHeight: domRect => float = "height"

@send external beginPath: context => unit = "beginPath"
@send external closePath: context => unit = "closePath"
@send external clipContext: context => unit = "clip"
@send external moveTo: (context, float, float) => unit = "moveTo"
@send external lineTo: (context, float, float) => unit = "lineTo"
@send external quadraticCurveTo: (context, float, float, float, float) => unit = "quadraticCurveTo"
@send external arc: (context, float, float, float, float, float) => unit = "arc"
@send external ellipse: (context, float, float, float, float, float, float, float) => unit = "ellipse"
@send external fill: context => unit = "fill"
@send external stroke: context => unit = "stroke"
@send external fillRect: (context, float, float, float, float) => unit = "fillRect"
@send external clearRect: (context, float, float, float, float) => unit = "clearRect"
@send external fillText: (context, string, float, float) => unit = "fillText"
@send external drawImageCrop: (
  context,
  imageElement,
  float,
  float,
  float,
  float,
  float,
  float,
  float,
  float,
) => unit = "drawImage"
@send external measureText: (context, string) => textMetrics = "measureText"
@get external textWidth: textMetrics => float = "width"
@send external saveContext: context => unit = "save"
@send external restoreContext: context => unit = "restore"
@send external translateContext: (context, float, float) => unit = "translate"
@send external rotateContext: (context, float) => unit = "rotate"
@send external scaleContext: (context, float, float) => unit = "scale"
@send external setTransform: (context, float, float, float, float, float, float) => unit = "setTransform"
@send external createLinearGradient: (context, float, float, float, float) => gradient = "createLinearGradient"
@send external addColorStop: (gradient, float, string) => unit = "addColorStop"

@new external makeImageElement: unit => imageElement = "Image"
@set external setImageElementSrc: (imageElement, string) => unit = "src"
@get external imageElementComplete: imageElement => bool = "complete"
@get external imageElementNaturalWidth: imageElement => int = "naturalWidth"

@set external setFillStyle: (context, string) => unit = "fillStyle"
@set external setFillGradient: (context, gradient) => unit = "fillStyle"
@set external setStrokeStyle: (context, string) => unit = "strokeStyle"
@set external setLineWidth: (context, float) => unit = "lineWidth"
@set external setLineCap: (context, string) => unit = "lineCap"
@set external setLineJoin: (context, string) => unit = "lineJoin"
@set external setFont: (context, string) => unit = "font"
@set external setTextAlign: (context, string) => unit = "textAlign"
@set external setTextBaseline: (context, string) => unit = "textBaseline"
@set external setGlobalAlpha: (context, float) => unit = "globalAlpha"
@set external setShadowColor: (context, string) => unit = "shadowColor"
@set external setShadowBlur: (context, float) => unit = "shadowBlur"
@set external setShadowOffsetX: (context, float) => unit = "shadowOffsetX"
@set external setShadowOffsetY: (context, float) => unit = "shadowOffsetY"

@send external responseJson: response => promise<'a> = "json"
@send external thenPromise: (promise<'a>, 'a => 'b) => promise<'b> = "then"
@send external thenPromiseAsync: (promise<'a>, 'a => promise<'b>) => promise<'b> = "then"
@send external catchPromise: (promise<'a>, domEvent => unit) => promise<unit> = "catch"
@send external pushArray: (array<'a>, 'a) => int = "push"
@send external shiftArray: array<'a> => 'a = "shift"
@get external arrayLength: array<'a> => int = "length"
@get_index external arrayGet: (array<'a>, int) => 'a = ""
@set_index external arraySet: (array<'a>, int, 'a) => unit = ""
@send external splitString: (string, string) => array<string> = "split"
@send external joinStrings: (array<string>, string) => string = "join"
@send external startsWithString: (string, string) => bool = "startsWith"
@val external numberString: float => string = "String"
@val external intToFloat: int => float = "Number"
@scope("Number") @val external parseIntNumber: (string, int) => float = "parseInt"
@scope("Number") @val external numberIsFinite: float => bool = "isFinite"

@val external browserStorage: storage = "localStorage"
@send external storageGetItem: (storage, string) => string = "getItem"
@send external storageSetItem: (storage, string, string) => unit = "setItem"

@val @scope("location") external locationSearch: string = "search"
@new external makeSearchParams: string => urlSearchParams = "URLSearchParams"
@send external searchHas: (urlSearchParams, string) => bool = "has"
@send external searchGet: (urlSearchParams, string) => string = "get"

@new external makeAudioContext: unit => audioContext = "AudioContext"
@get external audioCurrentTime: audioContext => float = "currentTime"
@get external audioState: audioContext => string = "state"
@get external audioOutput: audioContext => audioDestination = "destination"
@send external resumeAudio: audioContext => promise<unit> = "resume"
@send external makeGain: audioContext => gainNode = "createGain"
@send external makeOscillator: audioContext => oscillator = "createOscillator"
@get external gainValue: gainNode => audioParam = "gain"
@get external oscillatorFrequency: oscillator => audioParam = "frequency"
@set external setOscillatorType: (oscillator, string) => unit = "type"
@send external setParamAt: (audioParam, float, float) => unit = "setValueAtTime"
@send external rampParamAt: (audioParam, float, float) => unit = "exponentialRampToValueAtTime"
@send external connectOscillator: (oscillator, gainNode) => unit = "connect"
@send external connectGain: (gainNode, audioDestination) => unit = "connect"
@send external startOscillator: (oscillator, float) => unit = "start"
@send external stopOscillator: (oscillator, float) => unit = "stop"

@new external makeAudioElement: string => audioElement = "Audio"
@send external playAudioElement: audioElement => promise<unit> = "play"
@send external pauseAudioElement: audioElement => unit = "pause"
@send external loadAudioElement: audioElement => unit = "load"
@set external setAudioElementSrc: (audioElement, string) => unit = "src"
@set external setAudioElementCrossOrigin: (audioElement, string) => unit = "crossOrigin"

@val @scope("navigator") external audioSessionNullable: Js.Nullable.t<audioSession> = "audioSession"
@set external setAudioSessionType: (audioSession, string) => unit = "type"

@val external browserSpeech: speechSynthesis = "speechSynthesis"
@send external speechCancel: speechSynthesis => unit = "cancel"
@send external speechVoices: speechSynthesis => array<speechVoice> = "getVoices"
@send external speechSpeak: (speechSynthesis, speechUtterance) => unit = "speak"
@get external voiceLanguage: speechVoice => string = "lang"
@new external makeUtterance: string => speechUtterance = "SpeechSynthesisUtterance"
@set external setUtteranceLanguage: (speechUtterance, string) => unit = "lang"
@set external setUtteranceVoice: (speechUtterance, speechVoice) => unit = "voice"
@set external setUtteranceRate: (speechUtterance, float) => unit = "rate"
@set external setUtterancePitch: (speechUtterance, float) => unit = "pitch"

@val external gameNavigator: gameNavigator = "navigator"
@send external getGamepads: gameNavigator => array<gamepad> = "getGamepads"
@get external gamepadButtons: gamepad => array<gamepadButton> = "buttons"
@get external gamepadAxes: gamepad => array<float> = "axes"
@get external gamepadButtonPressed: gamepadButton => bool = "pressed"

@scope("Math") @val external floorFloat: float => int = "floor"
@scope("Math") @val external minFloat: (float, float) => float = "min"
@scope("Math") @val external maxFloat: (float, float) => float = "max"
@scope("Math") @val external sinFloat: float => float = "sin"
@scope("Math") @val external cosFloat: float => float = "cos"
@scope("Math") @val external absFloat: float => float = "abs"
@scope("Math") @val external pi: float = "PI"

type question = {
  id: string,
  kind: string,
  prompt: string,
  speak: string,
  audio: string,
  icon: string,
  choices: array<string>,
  answer: int,
  focus: string,
  success: string,
}

type guide = Kuku | Furia | Vesper

let guideForQuestion = (question: question): guide =>
  switch question.kind {
  | "picture" => Vesper
  | "word" => Furia
  | _ => Kuku
  }

type content = {
  version: int,
  title: string,
  subtitle: string,
  start: string,
  startHint: string,
  repeat: string,
  soundOn: string,
  soundOff: string,
  correct: string,
  retry: string,
  hint: string,
  completeTitle: string,
  completeBody: string,
  restart: string,
  progress: string,
  paused: string,
  loading: string,
  loadError: string,
  keyboardHelp: string,
  choiceKeys: array<string>,
  categoryGlyph: string,
  categoryPicture: string,
  categoryWord: string,
  guideKuku: string,
  guideFuria: string,
  guideVesper: string,
  devLabel: string,
  questions: array<question>,
}

type rect = {x: float, y: float, w: float, h: float}
type layout = {
  sound: rect,
  repeat: rect,
  start: rect,
  restart: rect,
  prompt: rect,
  choices: array<rect>,
  portrait: bool,
}

type masteryItem = {id: string, kind: string, mutable count: int}
type saved = {mutable sound: bool, mastery: array<masteryItem>}
type retryItem = {questionIndex: int, due: int}
type padInput = {left: bool, right: bool, confirm: bool, repeatPrompt: bool}

type gameState = {
  mutable content: content,
  mutable loaded: bool,
  mutable loadFailed: bool,
  mutable phase: int,
  mutable paused: bool,
  mutable width: float,
  mutable height: float,
  mutable dpr: float,
  mutable layout: layout,
  mutable seed: int,
  mutable deck: array<int>,
  mutable deckCursor: int,
  mutable retryQueue: array<retryItem>,
  mutable currentIndex: int,
  mutable choiceOrder: array<int>,
  mutable focusedChoice: int,
  mutable selectedChoice: int,
  mutable wrongChoice: int,
  mutable misses: int,
  mutable score: int,
  mutable simTime: float,
  mutable accumulator: float,
  mutable lastFrame: float,
  mutable feedbackStart: float,
  mutable wrongUntil: float,
  mutable inputUnlockAt: float,
  mutable sound: bool,
  mastery: array<masteryItem>,
  mutable speechAvailable: bool,
  mutable speechOverride: int,
  mutable padLeft: bool,
  mutable padRight: bool,
  mutable padConfirm: bool,
  mutable padRepeat: bool,
  mutable fps: float,
  mutable frameMs: float,
  mutable lastInput: string,
}

let defaultSaved = (): saved => {sound: true, mastery: []}

let loadSaved = (): saved => {
  try {
    let raw = storageGetItem(browserStorage, "kuku-akshar-aangan.v1")
    let fields = splitString(raw, "|")
    if arrayLength(fields) < 2 || arrayGet(fields, 0) != "v1" {
      defaultSaved()
    } else {
      let mastery: array<masteryItem> = []
      if arrayLength(fields) >= 3 {
        let rows = splitString(arrayGet(fields, 2), ",")
        for index in 0 to arrayLength(rows) - 1 {
          let cells = splitString(arrayGet(rows, index), "~")
          if arrayLength(cells) == 3 {
            let parsed = parseIntNumber(arrayGet(cells, 2), 10)
            if numberIsFinite(parsed) {
              let count = floorFloat(parsed)
              if arrayGet(cells, 0) != "" && count > 0 {
                let _ = pushArray(mastery, {
                  id: arrayGet(cells, 0),
                  kind: arrayGet(cells, 1),
                  count,
                })
              }
            }
          }
        }
      }
      {sound: arrayGet(fields, 1) != "0", mastery}
    }
  } catch {
  | _ => defaultSaved()
  }
}

let storeSaved = (value: saved): unit => {
  try {
    let rows: array<string> = []
    for index in 0 to arrayLength(value.mastery) - 1 {
      let item = arrayGet(value.mastery, index)
      let _ = pushArray(
        rows,
        item.id ++ "~" ++ item.kind ++ "~" ++ numberString(intToFloat(item.count)),
      )
    }
    let payload = "v1|" ++ (if value.sound {"1"} else {"0"}) ++ "|" ++ joinStrings(rows, ",")
    storageSetItem(browserStorage, "kuku-akshar-aangan.v1", payload)
  } catch {
  | _ => ()
  }
}

let queryHas = (name: string): bool => searchHas(makeSearchParams(locationSearch), name)

let queryInt = (name: string, fallback: int): int => {
  let raw = searchGet(makeSearchParams(locationSearch), name)
  let parsed = parseIntNumber(raw, 10)
  if numberIsFinite(parsed) {floorFloat(parsed)} else {fallback}
}

let rngStep = (seed: int): int => {
  let modulus = 2147483647.0
  let base = if seed <= 0 {1947.0} else {intToFloat(seed)}
  let normalized = base -. intToFloat(floorFloat(base /. modulus)) *. modulus
  let product = normalized *. 48271.0
  let next = product -. intToFloat(floorFloat(product /. modulus)) *. modulus
  let result = floorFloat(next)
  if result <= 0 {1} else {result}
}

let audioGetter: ref<unit => audioContext> = ref(makeAudioContext)

let getAudio = (): audioContext => {
  let audio = audioGetter.contents()
  audioGetter.contents = () => audio
  audio
}

let playCue = (kind: string, enabled: bool): unit => {
  if enabled {
    try {
      let audio = getAudio()
      if audioState(audio) == "suspended" {
        let _ = resumeAudio(audio)
      }
      let now = audioCurrentTime(audio)
      let gain = makeGain(audio)
      let gainParam = gainValue(gain)
      setParamAt(gainParam, 0.0001, now)
      rampParamAt(gainParam, if kind == "correct" {0.11} else {0.075}, now +. 0.012)
      let oscillator = makeOscillator(audio)
      setOscillatorType(oscillator, if kind == "retry" {"triangle"} else {"sine"})
      let frequency = oscillatorFrequency(oscillator)
      let first = if kind == "correct" {523.25} else if kind == "retry" {196.0} else {330.0}
      setParamAt(frequency, first, now)
      if kind == "correct" {
        setParamAt(frequency, 659.25, now +. 0.16)
      }
      let duration = if kind == "correct" {0.42} else if kind == "retry" {0.22} else {0.07}
      rampParamAt(gainParam, 0.0001, now +. duration)
      connectOscillator(oscillator, gain)
      connectGain(gain, audioOutput(audio))
      startOscillator(oscillator, now)
      stopOscillator(oscillator, now +. duration +. 0.02)
    } catch {
    | _ => ()
    }
  }
}

// iOS only allows later, automatic prompt playback when the same media element first
// played from a child's tap. Keep one element for the entire session and reuse it.
let promptAudio = makeAudioElement("")
setAudioElementCrossOrigin(promptAudio, "anonymous")

// Installed iOS web apps otherwise follow the hardware Silent switch. The parent app
// uses the same feature-detected setting; repeating it here keeps the embedded game
// correct when it is also served on its own.
switch Js.Nullable.toOption(audioSessionNullable) {
| Some(session) => setAudioSessionType(session, "playback")
| None => ()
}

// Invalidates a late play() rejection from an older prompt, so it cannot start browser
// speech over a newer question.
let promptAttempt = {contents: 0}

let speakNative = (text: string, enabled: bool): bool => {
  try {
    speechCancel(browserSpeech)
    let voices = speechVoices(browserSpeech)
    let hindiIndex = {contents: -1}
    for index in 0 to arrayLength(voices) - 1 {
      if startsWithString(voiceLanguage(arrayGet(voices, index)), "hi") {
        hindiIndex.contents = index
      }
    }
    if enabled && text != "" {
      let utterance = makeUtterance(text)
      setUtteranceLanguage(utterance, "hi-IN")
      setUtteranceRate(utterance, 0.82)
      setUtterancePitch(utterance, 1.08)
      if hindiIndex.contents >= 0 {
        setUtteranceVoice(utterance, arrayGet(voices, hindiIndex.contents))
      }
      speechSpeak(browserSpeech, utterance)
    }
    hindiIndex.contents >= 0
  } catch {
  | _ => false
  }
}

let cancelSpeech = (): unit => {
  promptAttempt.contents = promptAttempt.contents + 1
  pauseAudioElement(promptAudio)
  try {
    speechCancel(browserSpeech)
  } catch {
  | _ => ()
  }
}

let padButton = (buttons: array<gamepadButton>, index: int): bool =>
  index >= 0 && index < arrayLength(buttons) && gamepadButtonPressed(arrayGet(buttons, index))

let pollGamepad = (): padInput => {
  try {
    let pads = getGamepads(gameNavigator)
    let found = {contents: -1}
    for index in 0 to arrayLength(pads) - 1 {
      if found.contents < 0 {
        try {
          let buttons = gamepadButtons(arrayGet(pads, index))
          if arrayLength(buttons) > 0 {
            found.contents = index
          }
        } catch {
        | _ => ()
        }
      }
    }
    if found.contents < 0 {
      {left: false, right: false, confirm: false, repeatPrompt: false}
    } else {
      let pad = arrayGet(pads, found.contents)
      let buttons = gamepadButtons(pad)
      let axes = gamepadAxes(pad)
      let horizontal = if arrayLength(axes) > 0 {arrayGet(axes, 0)} else {0.0}
      {
        left: padButton(buttons, 14) || horizontal < -0.55,
        right: padButton(buttons, 15) || horizontal > 0.55,
        confirm: padButton(buttons, 0),
        repeatPrompt: padButton(buttons, 2) || padButton(buttons, 4),
      }
    }
  } catch {
  | _ => {left: false, right: false, confirm: false, repeatPrompt: false}
  }
}

let blankQuestion: question = {
  id: "",
  kind: "",
  prompt: "",
  speak: "",
  audio: "",
  icon: "",
  choices: ["", "", ""],
  answer: 0,
  focus: "",
  success: "",
}

let blankContent: content = {
  version: 1,
  title: "",
  subtitle: "",
  start: "",
  startHint: "",
  repeat: "",
  soundOn: "",
  soundOff: "",
  correct: "",
  retry: "",
  hint: "",
  completeTitle: "",
  completeBody: "",
  restart: "",
  progress: "",
  paused: "",
  loading: "",
  loadError: "",
  keyboardHelp: "",
  choiceKeys: ["", "", ""],
  categoryGlyph: "",
  categoryPicture: "",
  categoryWord: "",
  guideKuku: "",
  guideFuria: "",
  guideVesper: "",
  devLabel: "",
  questions: [blankQuestion],
}

let emptyRect = (): rect => {x: 0.0, y: 0.0, w: 0.0, h: 0.0}

let blankLayout: layout = {
  sound: emptyRect(),
  repeat: emptyRect(),
  start: emptyRect(),
  restart: emptyRect(),
  prompt: emptyRect(),
  choices: [emptyRect(), emptyRect(), emptyRect()],
  portrait: false,
}

let persisted = loadSaved()

let state: gameState = {
  content: blankContent,
  loaded: false,
  loadFailed: false,
  phase: 0,
  paused: false,
  width: 1280.0,
  height: 720.0,
  dpr: 1.0,
  layout: blankLayout,
  seed: queryInt("seed", 1947),
  deck: [],
  deckCursor: 0,
  retryQueue: [],
  currentIndex: 0,
  choiceOrder: [0, 1, 2],
  focusedChoice: 0,
  selectedChoice: -1,
  wrongChoice: -1,
  misses: 0,
  score: 0,
  simTime: 0.0,
  accumulator: 0.0,
  lastFrame: 0.0,
  feedbackStart: 0.0,
  wrongUntil: 0.0,
  inputUnlockAt: 0.0,
  sound: persisted.sound,
  mastery: persisted.mastery,
  speechAvailable: false,
  speechOverride: -1,
  padLeft: false,
  padRight: false,
  padConfirm: false,
  padRepeat: false,
  fps: 0.0,
  frameMs: 0.0,
  lastInput: "",
}

let gameCanvas = getElementById(browserDocument, "game")
let ctx = getCanvasContext(gameCanvas, "2d")
let promptAtlas = makeImageElement()
setImageElementSrc(promptAtlas, "./assets/illustrations-v2/primer-atlas.png")
let kukuGuideImage = makeImageElement()
setImageElementSrc(kukuGuideImage, "./assets/characters-v1/kuku.png")
let furiaGuideImage = makeImageElement()
setImageElementSrc(furiaGuideImage, "./assets/characters-v1/furia.png")
let vesperGuideImage = makeImageElement()
setImageElementSrc(vesperGuideImage, "./assets/characters-v1/vesper.png")

let nextRandom = (): float => {
  state.seed = rngStep(state.seed)
  intToFloat(state.seed) /. 2147483647.0
}

let randomIndex = (limit: int): int =>
  if limit <= 1 {
    0
  } else {
    floorFloat(nextRandom() *. intToFloat(limit))
  }

let clamp = (value: float, low: float, high: float): float => maxFloat(low, minFloat(high, value))

let rectContains = (box: rect, x: float, y: float): bool =>
  x >= box.x && x <= box.x +. box.w && y >= box.y && y <= box.y +. box.h

let makeLayout = (width: float, height: float): layout => {
  let portrait = height > width *. 1.08
  let compactPortrait = portrait && height < 660.0
  let compactLandscape = !portrait && height < 430.0
  let margin = clamp(width *. 0.035, 14.0, 28.0)
  let soundSize = if compactLandscape {44.0} else if portrait {48.0} else {54.0}
  let sound = {
    x: width -. margin -. soundSize,
    y: margin,
    w: soundSize,
    h: soundSize,
  }
  if portrait {
    let promptTop = 102.0
    let promptHeight = if compactPortrait {
      clamp(height *. 0.265, 150.0, 180.0)
    } else {
      clamp(height *. 0.285, 190.0, 252.0)
    }
    let prompt = {
      x: margin,
      y: promptTop,
      w: width -. margin *. 2.0,
      h: promptHeight,
    }
    let gap = if compactPortrait {6.0} else {12.0}
    let choiceTop = prompt.y +. prompt.h +. (if compactPortrait {10.0} else {24.0})
    let bottomReserve = if compactPortrait {12.0} else {68.0}
    let available = height -. choiceTop -. bottomReserve -. gap *. 2.0
    let choiceHeight = if compactPortrait {
      minFloat(104.0, maxFloat(64.0, available /. 3.0))
    } else {
      clamp(available /. 3.0, 104.0, 126.0)
    }
    let choiceWidth = width -. margin *. 2.0
    let choices = [
      {x: margin, y: choiceTop, w: choiceWidth, h: choiceHeight},
      {x: margin, y: choiceTop +. choiceHeight +. gap, w: choiceWidth, h: choiceHeight},
      {x: margin, y: choiceTop +. (choiceHeight +. gap) *. 2.0, w: choiceWidth, h: choiceHeight},
    ]
    let startWidth = minFloat(width -. margin *. 3.0, 360.0)
    let actionHeight = if compactPortrait {78.0} else {104.0}
    {
      sound,
      repeat: {x: prompt.x +. prompt.w -. 112.0, y: prompt.y +. 14.0, w: 96.0, h: 48.0},
      start: {
        x: (width -. startWidth) /. 2.0,
        y: height -. (if compactPortrait {170.0} else {214.0}),
        w: startWidth,
        h: actionHeight,
      },
      restart: {
        x: (width -. startWidth) /. 2.0,
        y: height -. (if compactPortrait {150.0} else {190.0}),
        w: startWidth,
        h: actionHeight,
      },
      prompt,
      choices,
      portrait,
    }
  } else {
    let prompt = {
      x: width *. 0.245,
      y: if compactLandscape {58.0} else {maxFloat(64.0, height *. 0.105)},
      w: width *. 0.72,
      h: if compactLandscape {
        clamp(height *. 0.37, 112.0, 136.0)
      } else {
        clamp(height *. 0.35, 138.0, 238.0)
      },
    }
    let gap = if compactLandscape {10.0} else {clamp(width *. 0.018, 12.0, 24.0)}
    let choiceTop = height *. (if compactLandscape {0.60} else {0.625})
    let choiceWidth = (width -. margin *. 2.0 -. gap *. 2.0) /. 3.0
    let choiceHeight = if compactLandscape {
      maxFloat(84.0, height -. choiceTop -. 12.0)
    } else {
      maxFloat(104.0, height -. choiceTop -. maxFloat(30.0, height *. 0.07))
    }
    let choices = [
      {x: margin, y: choiceTop, w: choiceWidth, h: choiceHeight},
      {x: margin +. choiceWidth +. gap, y: choiceTop, w: choiceWidth, h: choiceHeight},
      {x: margin +. (choiceWidth +. gap) *. 2.0, y: choiceTop, w: choiceWidth, h: choiceHeight},
    ]
    let startWidth = clamp(width *. 0.34, 300.0, 470.0)
    let actionHeight = if compactLandscape {68.0} else {96.0}
    {
      sound,
      repeat: {
        x: prompt.x +. prompt.w -. 128.0,
        y: prompt.y +. (if compactLandscape {8.0} else {16.0}),
        w: 108.0,
        h: if compactLandscape {44.0} else {52.0},
      },
      start: {
        x: (width -. startWidth) /. 2.0,
        y: if compactLandscape {height -. 80.0} else {height *. 0.70},
        w: startWidth,
        h: actionHeight,
      },
      restart: {
        x: (width -. startWidth) /. 2.0,
        y: if compactLandscape {height -. 78.0} else {height *. 0.67},
        w: startWidth,
        h: actionHeight,
      },
      prompt,
      choices,
      portrait,
    }
  }
}

let resize = () => {
  let width = intToFloat(windowWidth(browserWindow))
  let height = intToFloat(windowHeight(browserWindow))
  let requestedDpr = queryInt("testDpr", 0)
  let rawDpr = if queryHas("dev") && requestedDpr > 0 {
    intToFloat(requestedDpr)
  } else {
    windowDpr(browserWindow)
  }
  let dpr = clamp(rawDpr, 1.0, 1.5)
  state.width = width
  state.height = height
  state.dpr = dpr
  state.layout = makeLayout(width, height)
  setCanvasWidth(gameCanvas, floorFloat(width *. dpr))
  setCanvasHeight(gameCanvas, floorFloat(height *. dpr))
}

let rec masteryCountAt = (id: string, index: int): int =>
  if index >= arrayLength(state.mastery) {
    0
  } else if arrayGet(state.mastery, index).id == id {
    arrayGet(state.mastery, index).count
  } else {
    masteryCountAt(id, index + 1)
  }

let masteryCount = (id: string): int => masteryCountAt(id, 0)

let rec incrementMasteryAt = (question: question, index: int): unit =>
  if index >= arrayLength(state.mastery) {
    let _ = pushArray(state.mastery, {id: question.id, kind: question.kind, count: 1})
  } else if arrayGet(state.mastery, index).id == question.id {
    let item = arrayGet(state.mastery, index)
    item.count = item.count + 1
  } else {
    incrementMasteryAt(question, index + 1)
  }

let persist = () => storeSaved({sound: state.sound, mastery: state.mastery})

let rec deckHas = (questionIndex: int, at: int): bool =>
  if at >= arrayLength(state.deck) {
    false
  } else if arrayGet(state.deck, at) == questionIndex {
    true
  } else {
    deckHas(questionIndex, at + 1)
  }

let chooseQuestionForKind = (kind: string): int => {
  let questions = state.content.questions
  let bestIndex = {contents: -1}
  let bestMastery = {contents: 1000000}
  let bestTie = {contents: 2.0}
  for index in 0 to arrayLength(questions) - 1 {
    let question = arrayGet(questions, index)
    if question.kind == kind && !deckHas(index, 0) {
      let learned = masteryCount(question.id)
      let tie = nextRandom()
      if learned < bestMastery.contents || (learned == bestMastery.contents && tie < bestTie.contents) {
        bestIndex.contents = index
        bestMastery.contents = learned
        bestTie.contents = tie
      }
    }
  }
  if bestIndex.contents >= 0 {
    bestIndex.contents
  } else {
    randomIndex(arrayLength(questions))
  }
}

let swapInts = (items: array<int>, left: int, right: int) => {
  let held = arrayGet(items, left)
  arraySet(items, left, arrayGet(items, right))
  arraySet(items, right, held)
}

let shuffleInts = (items: array<int>) => {
  let cursor = {contents: arrayLength(items) - 1}
  while cursor.contents > 0 {
    let other = randomIndex(cursor.contents + 1)
    swapInts(items, cursor.contents, other)
    cursor.contents = cursor.contents - 1
  }
}

let shuffleIntsFrom = (items: array<int>, start: int) => {
  let cursor = {contents: arrayLength(items) - 1}
  while cursor.contents > start {
    let other = start + randomIndex(cursor.contents - start + 1)
    swapInts(items, cursor.contents, other)
    cursor.contents = cursor.contents - 1
  }
}

let buildDeck = () => {
  state.deck = []
  // Put one question from every guide in the opening three slots. A retry can
  // become due only after those three have been answered, so Kuku, Vesper, and
  // Furia are all introduced even when retries later consume deck slots.
  let openingKinds = ["glyph", "picture", "word"]
  for index in 0 to arrayLength(openingKinds) - 1 {
    let _ = pushArray(state.deck, chooseQuestionForKind(arrayGet(openingKinds, index)))
  }
  shuffleInts(state.deck)

  let remainingKinds = [
    "glyph",
    "picture",
    "picture",
    "word",
    "glyph",
    "picture",
    "picture",
  ]
  for index in 0 to arrayLength(remainingKinds) - 1 {
    let _ = pushArray(state.deck, chooseQuestionForKind(arrayGet(remainingKinds, index)))
  }
  shuffleIntsFrom(state.deck, 3)
  state.deckCursor = 0
}

let shuffleChoices = () => {
  state.choiceOrder = [0, 1, 2]
  shuffleInts(state.choiceOrder)
}

let speakQuestion = () => {
  if state.phase == 2 && state.loaded {
    let question = arrayGet(state.content.questions, state.currentIndex)
    let enabled = state.sound && state.speechOverride != 0
    if !enabled {
      cancelSpeech()
      state.speechAvailable = state.speechOverride == 1
    } else if question.audio == "" {
      let available = speakNative(question.speak, true)
      state.speechAvailable = if state.speechOverride == 1 {true} else {available}
    } else {
      cancelSpeech()
      let attempt = promptAttempt.contents
      state.speechAvailable = true
      try {
        setAudioElementSrc(promptAudio, question.audio)
        loadAudioElement(promptAudio)
        let playing = playAudioElement(promptAudio)
        let _ = catchPromise(playing, _error => {
          if promptAttempt.contents == attempt && state.phase == 2 && state.sound {
            let available = speakNative(question.speak, true)
            state.speechAvailable = if state.speechOverride == 1 {true} else {available}
          }
        })
      } catch {
      | _ => {
          let available = speakNative(question.speak, true)
          state.speechAvailable = if state.speechOverride == 1 {true} else {available}
        }
      }
    }
  }
}

let startQuestion = (questionIndex: int) => {
  state.currentIndex = questionIndex
  state.focusedChoice = 0
  state.selectedChoice = -1
  state.wrongChoice = -1
  state.misses = 0
  state.wrongUntil = 0.0
  state.inputUnlockAt = state.simTime +. 180.0
  shuffleChoices()
  speakQuestion()
}

let nextQuestion = () => {
  if state.score >= 10 {
    state.phase = 4
    cancelSpeech()
  } else {
    let useRetry = arrayLength(state.retryQueue) > 0 && arrayGet(state.retryQueue, 0).due <= state.score
    let questionIndex = if useRetry {
      shiftArray(state.retryQueue).questionIndex
    } else if state.deckCursor < arrayLength(state.deck) {
      let next = arrayGet(state.deck, state.deckCursor)
      state.deckCursor = state.deckCursor + 1
      next
    } else {
      randomIndex(arrayLength(state.content.questions))
    }
    state.phase = 2
    startQuestion(questionIndex)
  }
}

let startSession = (seed: int) => {
  state.seed = seed
  state.score = 0
  state.retryQueue = []
  state.simTime = 0.0
  state.accumulator = 0.0
  state.lastFrame = 0.0
  buildDeck()
  nextQuestion()
  playCue("tap", state.sound)
}

let scheduleRetry = () => {
  let current = state.currentIndex
  let alreadyQueued = {contents: false}
  for index in 0 to arrayLength(state.retryQueue) - 1 {
    if arrayGet(state.retryQueue, index).questionIndex == current {
      alreadyQueued.contents = true
    }
  }
  if !alreadyQueued.contents && arrayLength(state.retryQueue) < 8 {
    let _ = pushArray(state.retryQueue, {questionIndex: current, due: state.score + 3})
  }
}

let answerChoice = (position: int) => {
  if state.phase == 2 && state.simTime >= state.inputUnlockAt && position >= 0 && position < 3 {
    let question = arrayGet(state.content.questions, state.currentIndex)
    let sourceChoice = arrayGet(state.choiceOrder, position)
    state.focusedChoice = position
    state.selectedChoice = position
    if sourceChoice == question.answer {
      state.phase = 3
      state.feedbackStart = state.simTime
      state.score = state.score + 1
      incrementMasteryAt(question, 0)
      persist()
      playCue("correct", state.sound)
      cancelSpeech()
    } else {
      state.wrongChoice = position
      state.misses = state.misses + 1
      state.wrongUntil = state.simTime +. 720.0
      state.inputUnlockAt = state.simTime +. 280.0
      if state.misses == 1 {
        scheduleRetry()
      }
      playCue("retry", state.sound)
    }
  }
}

let repeatPrompt = () => {
  if state.phase == 2 {
    state.lastInput = "repeat"
    playCue("tap", state.sound)
    speakQuestion()
  }
}

let toggleSound = () => {
  state.sound = !state.sound
  persist()
  if state.sound {
    playCue("tap", true)
    speakQuestion()
  } else {
    cancelSpeech()
  }
}

let font = (weight: int, size: float): string =>
  numberString(intToFloat(weight)) ++ " " ++ numberString(size) ++
  "px 'Noto Sans Devanagari','Kohinoor Devanagari','Mangal',system-ui,sans-serif"

let roundedPath = (box: rect, radius: float) => {
  let r = minFloat(radius, minFloat(box.w, box.h) /. 2.0)
  beginPath(ctx)
  moveTo(ctx, box.x +. r, box.y)
  lineTo(ctx, box.x +. box.w -. r, box.y)
  quadraticCurveTo(ctx, box.x +. box.w, box.y, box.x +. box.w, box.y +. r)
  lineTo(ctx, box.x +. box.w, box.y +. box.h -. r)
  quadraticCurveTo(
    ctx,
    box.x +. box.w,
    box.y +. box.h,
    box.x +. box.w -. r,
    box.y +. box.h,
  )
  lineTo(ctx, box.x +. r, box.y +. box.h)
  quadraticCurveTo(ctx, box.x, box.y +. box.h, box.x, box.y +. box.h -. r)
  lineTo(ctx, box.x, box.y +. r)
  quadraticCurveTo(ctx, box.x, box.y, box.x +. r, box.y)
  closePath(ctx)
}

let fillRounded = (box: rect, radius: float, color: string) => {
  roundedPath(box, radius)
  setFillStyle(ctx, color)
  fill(ctx)
}

let strokeRounded = (box: rect, radius: float, color: string, width: float) => {
  roundedPath(box, radius)
  setStrokeStyle(ctx, color)
  setLineWidth(ctx, width)
  stroke(ctx)
}

let drawPaperCard = (box: rect, color: string, edge: string, raised: bool) => {
  saveContext(ctx)
  if raised {
    setShadowColor(ctx, "rgba(40,50,45,0.24)")
    setShadowBlur(ctx, 15.0)
    setShadowOffsetY(ctx, 8.0)
  }
  fillRounded({x: box.x +. 3.0, y: box.y +. 5.0, w: box.w, h: box.h}, 24.0, edge)
  setShadowColor(ctx, "rgba(0,0,0,0)")
  setShadowBlur(ctx, 0.0)
  setShadowOffsetY(ctx, 0.0)
  fillRounded(box, 24.0, color)
  strokeRounded(box, 24.0, "rgba(63,75,68,0.17)", 2.0)
  restoreContext(ctx)
}

let drawCircle = (x: float, y: float, radius: float, color: string) => {
  beginPath(ctx)
  arc(ctx, x, y, radius, 0.0, pi *. 2.0)
  setFillStyle(ctx, color)
  fill(ctx)
}

let drawEllipse = (x: float, y: float, rx: float, ry: float, color: string) => {
  beginPath(ctx)
  ellipse(ctx, x, y, rx, ry, 0.0, 0.0, pi *. 2.0)
  setFillStyle(ctx, color)
  fill(ctx)
}

let drawCheck = (x: float, y: float, size: float, color: string) => {
  beginPath(ctx)
  moveTo(ctx, x -. size *. 0.46, y)
  lineTo(ctx, x -. size *. 0.10, y +. size *. 0.34)
  lineTo(ctx, x +. size *. 0.52, y -. size *. 0.42)
  setStrokeStyle(ctx, color)
  setLineWidth(ctx, maxFloat(4.0, size *. 0.14))
  setLineCap(ctx, "round")
  setLineJoin(ctx, "round")
  stroke(ctx)
}

let drawCross = (x: float, y: float, size: float, color: string) => {
  beginPath(ctx)
  moveTo(ctx, x -. size, y -. size)
  lineTo(ctx, x +. size, y +. size)
  moveTo(ctx, x +. size, y -. size)
  lineTo(ctx, x -. size, y +. size)
  setStrokeStyle(ctx, color)
  setLineWidth(ctx, maxFloat(4.0, size *. 0.28))
  setLineCap(ctx, "round")
  stroke(ctx)
}

let drawStar = (x: float, y: float, outer: float, inner: float, color: string, rotation: float) => {
  beginPath(ctx)
  for point in 0 to 9 {
    let angle = rotation -. pi /. 2.0 +. intToFloat(point) *. pi /. 5.0
    let radius = if mod(point, 2) == 0 {outer} else {inner}
    let px = x +. cosFloat(angle) *. radius
    let py = y +. sinFloat(angle) *. radius
    if point == 0 {
      moveTo(ctx, px, py)
    } else {
      lineTo(ctx, px, py)
    }
  }
  closePath(ctx)
  setFillStyle(ctx, color)
  fill(ctx)
}

let drawWrappedCentered = (
  text: string,
  centerX: float,
  topY: float,
  maxWidth: float,
  lineHeight: float,
  maxLines: int,
) => {
  let words = splitString(text, " ")
  let line = {contents: ""}
  let lineIndex = {contents: 0}
  let cursor = {contents: 0}
  while cursor.contents < arrayLength(words) && lineIndex.contents < maxLines {
    let word = arrayGet(words, cursor.contents)
    let candidate = if line.contents == "" {word} else {line.contents ++ " " ++ word}
    let fits = textWidth(measureText(ctx, candidate)) <= maxWidth
    if fits || line.contents == "" {
      line.contents = candidate
      cursor.contents = cursor.contents + 1
    } else {
      fillText(ctx, line.contents, centerX, topY +. intToFloat(lineIndex.contents) *. lineHeight)
      line.contents = ""
      lineIndex.contents = lineIndex.contents + 1
    }
  }
  if line.contents != "" && lineIndex.contents < maxLines {
    fillText(ctx, line.contents, centerX, topY +. intToFloat(lineIndex.contents) *. lineHeight)
  }
}

let drawCloud = (x: float, y: float, scale: float, color: string) => {
  drawEllipse(x, y, 72.0 *. scale, 25.0 *. scale, color)
  drawCircle(x -. 36.0 *. scale, y -. 12.0 *. scale, 25.0 *. scale, color)
  drawCircle(x +. 4.0 *. scale, y -. 24.0 *. scale, 38.0 *. scale, color)
  drawCircle(x +. 42.0 *. scale, y -. 10.0 *. scale, 27.0 *. scale, color)
}

let drawBackground = (time: float) => {
  let sky = createLinearGradient(ctx, 0.0, 0.0, 0.0, state.height)
  addColorStop(sky, 0.0, "#bfe9f2")
  addColorStop(sky, 0.58, "#eaf6d5")
  addColorStop(sky, 1.0, "#b8df87")
  setFillGradient(ctx, sky)
  fillRect(ctx, 0.0, 0.0, state.width, state.height)

  setGlobalAlpha(ctx, 0.75)
  let drift = sinFloat(time /. 3500.0) *. 14.0
  drawCloud(state.width *. 0.18 +. drift, state.height *. 0.18, 0.85, "#f8fff4")
  drawCloud(state.width *. 0.72 -. drift *. 0.7, state.height *. 0.12, 0.62, "#f9fff7")
  setGlobalAlpha(ctx, 1.0)

  beginPath(ctx)
  moveTo(ctx, 0.0, state.height *. 0.60)
  lineTo(ctx, state.width *. 0.17, state.height *. 0.28)
  lineTo(ctx, state.width *. 0.34, state.height *. 0.60)
  lineTo(ctx, state.width *. 0.54, state.height *. 0.34)
  lineTo(ctx, state.width *. 0.73, state.height *. 0.60)
  lineTo(ctx, state.width, state.height *. 0.27)
  lineTo(ctx, state.width, state.height)
  lineTo(ctx, 0.0, state.height)
  closePath(ctx)
  setFillStyle(ctx, "#7fbd73")
  fill(ctx)

  beginPath(ctx)
  moveTo(ctx, 0.0, state.height *. 0.70)
  quadraticCurveTo(ctx, state.width *. 0.25, state.height *. 0.52, state.width *. 0.48, state.height *. 0.72)
  quadraticCurveTo(ctx, state.width *. 0.72, state.height *. 0.48, state.width, state.height *. 0.68)
  lineTo(ctx, state.width, state.height)
  lineTo(ctx, 0.0, state.height)
  closePath(ctx)
  setFillStyle(ctx, "#a9d97c")
  fill(ctx)

  setGlobalAlpha(ctx, 0.13)
  setStrokeStyle(ctx, "#355742")
  setLineWidth(ctx, 1.0)
  for stripe in 0 to 34 {
    let y = intToFloat(stripe) *. 23.0 +. 7.0
    beginPath(ctx)
    moveTo(ctx, 0.0, y)
    lineTo(ctx, state.width, y +. sinFloat(intToFloat(stripe)) *. 6.0)
    stroke(ctx)
  }
  setGlobalAlpha(ctx, 1.0)
}

let guideKey = (guide: guide): string =>
  switch guide {
  | Kuku => "kuku"
  | Furia => "furia"
  | Vesper => "vesper"
  }

let guideName = (guide: guide): string =>
  switch guide {
  | Kuku => state.content.guideKuku
  | Furia => state.content.guideFuria
  | Vesper => state.content.guideVesper
  }

let guideAccent = (guide: guide): string =>
  switch guide {
  | Kuku => "#3d8f56"
  | Furia => "#c44562"
  | Vesper => "#4f91aa"
  }

let guideImage = (guide: guide): imageElement =>
  switch guide {
  | Kuku => kukuGuideImage
  | Furia => furiaGuideImage
  | Vesper => vesperGuideImage
  }

let guideSourceCrop = (compact: bool): rect =>
  if compact {
    {x: 40.0, y: 45.0, w: 320.0, h: 250.0}
  } else {
    {x: 0.0, y: 0.0, w: 400.0, h: 536.0}
  }

let drawGuidePortrait = (guide: guide, box: rect, compact: bool) => {
  let accent = guideAccent(guide)
  drawPaperCard(box, "#fff8e8", accent, true)
  let nameHeight = clamp(box.h *. 0.17, 22.0, 31.0)
  let imageBox = {
    x: box.x +. 6.0,
    y: box.y +. 6.0,
    w: maxFloat(1.0, box.w -. 12.0),
    h: maxFloat(1.0, box.h -. nameHeight -. 14.0),
  }
  saveContext(ctx)
  roundedPath(imageBox, minFloat(17.0, imageBox.h /. 4.0))
  clipContext(ctx)
  setFillStyle(ctx, "#fbf3df")
  fillRect(ctx, imageBox.x, imageBox.y, imageBox.w, imageBox.h)
  let image = guideImage(guide)
  if imageElementComplete(image) && imageElementNaturalWidth(image) > 0 {
    let crop = guideSourceCrop(compact)
    let imageScale = minFloat(imageBox.w /. crop.w, imageBox.h /. crop.h)
    let width = crop.w *. imageScale
    let height = crop.h *. imageScale
    drawImageCrop(
      ctx,
      image,
      crop.x,
      crop.y,
      crop.w,
      crop.h,
      imageBox.x +. (imageBox.w -. width) /. 2.0,
      imageBox.y +. (imageBox.h -. height) /. 2.0,
      width,
      height,
    )
  }
  restoreContext(ctx)

  let nameBox = {
    x: box.x +. 8.0,
    y: box.y +. box.h -. nameHeight -. 6.0,
    w: maxFloat(1.0, box.w -. 16.0),
    h: nameHeight,
  }
  fillRounded(nameBox, nameHeight /. 2.0, accent)
  setFillStyle(ctx, "#ffffff")
  setTextAlign(ctx, "center")
  setTextBaseline(ctx, "middle")
  setFont(ctx, font(850, clamp(nameHeight *. 0.56, 13.0, 17.0)))
  fillText(ctx, guideName(guide), nameBox.x +. nameBox.w /. 2.0, nameBox.y +. nameBox.h *. 0.52)
}

let guidePlayBox = (): rect => {
  let prompt = state.layout.prompt
  if state.layout.portrait {
    {
      x: prompt.x +. 12.0,
      y: prompt.y +. 48.0,
      w: clamp(prompt.w *. 0.31, 92.0, 116.0),
      h: clamp(prompt.h -. 106.0, 82.0, 134.0),
    }
  } else {
    let margin = clamp(state.width *. 0.035, 14.0, 28.0)
    let raw = {
      x: margin,
      y: prompt.y,
      w: maxFloat(100.0, prompt.x -. margin -. 14.0),
      h: maxFloat(130.0, arrayGet(state.layout.choices, 0).y -. prompt.y -. 18.0),
    }
    if raw.w < 190.0 {
      let compactHeight = minFloat(raw.h, raw.w *. 1.18)
      {x: raw.x, y: raw.y +. (raw.h -. compactHeight) /. 2.0, w: raw.w, h: compactHeight}
    } else {
      raw
    }
  }
}

let drawGuideForQuestion = (question: question) => {
  let box = guidePlayBox()
  drawGuidePortrait(guideForQuestion(question), box, state.layout.portrait || box.w < 190.0)
}

let drawGuideTrio = (centerY: float, maxHeight: float) => {
  if state.layout.portrait {
    let margin = 12.0
    let gap = 6.0
    let cardWidth = (state.width -. margin *. 2.0 -. gap *. 2.0) /. 3.0
    let cardHeight = minFloat(maxHeight, cardWidth *. 1.28)
    let top = centerY -. cardHeight /. 2.0
    drawGuidePortrait(Furia, {x: margin, y: top, w: cardWidth, h: cardHeight}, true)
    drawGuidePortrait(Kuku, {x: margin +. cardWidth +. gap, y: top, w: cardWidth, h: cardHeight}, true)
    drawGuidePortrait(
      Vesper,
      {x: margin +. (cardWidth +. gap) *. 2.0, y: top, w: cardWidth, h: cardHeight},
      true,
    )
  } else {
    let gap = clamp(state.width *. 0.015, 10.0, 18.0)
    let preferredWidth = clamp(state.width *. 0.14, 118.0, 170.0)
    let cardWidth = minFloat(preferredWidth, (state.width -. 32.0 -. gap *. 2.0) /. 3.0)
    let cardHeight = minFloat(maxHeight, cardWidth *. 1.55)
    let left = (state.width -. cardWidth *. 3.0 -. gap *. 2.0) /. 2.0
    let top = centerY -. cardHeight /. 2.0
    drawGuidePortrait(Furia, {x: left, y: top, w: cardWidth, h: cardHeight}, false)
    drawGuidePortrait(Kuku, {x: left +. cardWidth +. gap, y: top, w: cardWidth, h: cardHeight}, false)
    drawGuidePortrait(
      Vesper,
      {x: left +. (cardWidth +. gap) *. 2.0, y: top, w: cardWidth, h: cardHeight},
      false,
    )
  }
}

let drawSpeaker = (x: float, y: float, size: float, muted: bool, color: string) => {
  beginPath(ctx)
  moveTo(ctx, x -. size *. 0.46, y -. size *. 0.17)
  lineTo(ctx, x -. size *. 0.20, y -. size *. 0.17)
  lineTo(ctx, x +. size *. 0.08, y -. size *. 0.43)
  lineTo(ctx, x +. size *. 0.08, y +. size *. 0.43)
  lineTo(ctx, x -. size *. 0.20, y +. size *. 0.17)
  lineTo(ctx, x -. size *. 0.46, y +. size *. 0.17)
  closePath(ctx)
  setFillStyle(ctx, color)
  fill(ctx)
  if muted {
    drawCross(x +. size *. 0.32, y, size *. 0.22, color)
  } else {
    beginPath(ctx)
    arc(ctx, x +. size *. 0.06, y, size *. 0.32, -0.72, 0.72)
    setStrokeStyle(ctx, color)
    setLineWidth(ctx, maxFloat(3.0, size *. 0.10))
    setLineCap(ctx, "round")
    stroke(ctx)
  }
}

let drawSoundButton = () => {
  let box = state.layout.sound
  drawPaperCard(box, "#fff8dd", "#d7bd73", true)
  drawSpeaker(box.x +. box.w /. 2.0, box.y +. box.h /. 2.0, box.w *. 0.48, !state.sound, "#294c46")
}

let drawProgress = (large: bool) => {
  let compactPortrait = state.layout.portrait && state.height < 660.0
  let compactLandscape = !state.layout.portrait && state.height < 430.0
  let width = if large {
    minFloat(state.width *. (if compactLandscape {0.72} else {0.78}), 640.0)
  } else {
    minFloat(state.width *. (if compactLandscape {0.32} else {0.48}), 360.0)
  }
  let height = if large {
    if compactLandscape {52.0} else if compactPortrait {64.0} else {84.0}
  } else if compactLandscape {
    36.0
  } else {
    44.0
  }
  let y = if large {
    if compactLandscape {140.0} else if compactPortrait {state.height *. 0.46} else {state.height *. 0.48}
  } else if state.layout.portrait {
    52.0
  } else if compactLandscape {
    10.0
  } else {
    14.0
  }
  let x = (state.width -. width) /. 2.0
  fillRounded({x, y, w: width, h: height}, height /. 2.0, "#8f6a27")
  fillRounded({x: x +. 5.0, y: y +. 5.0, w: width -. 10.0, h: height -. 10.0}, height /. 2.0, "#dcae43")
  let gemGap = (width -. 28.0) /. 10.0
  let radius = if large {if compactPortrait || compactLandscape {17.0} else {24.0}} else if compactLandscape {10.0} else {13.0}
  for index in 0 to 9 {
    let gemX = x +. 14.0 +. gemGap *. (intToFloat(index) +. 0.5)
    let gemY = y +. height /. 2.0
    let filled = index < state.score
    drawCircle(gemX +. 1.0, gemY +. 2.0, radius +. 2.0, "rgba(91,62,24,0.30)")
    drawCircle(gemX, gemY, radius, if filled {"#ffe36e"} else {"#f1d89b"})
    if filled {
      drawCheck(gemX, gemY, radius *. 0.72, "#72511c")
    } else {
      drawCircle(gemX -. radius *. 0.22, gemY -. radius *. 0.24, radius *. 0.15, "rgba(255,255,255,0.54)")
    }
  }
}

let categoryLabel = (kind: string): string =>
  if kind == "glyph" {
    state.content.categoryGlyph
  } else if kind == "picture" {
    state.content.categoryPicture
  } else {
    state.content.categoryWord
  }

let drawHeader = () => {
  let compactLandscape = !state.layout.portrait && state.height < 430.0
  setFillStyle(ctx, "#234c45")
  setTextAlign(ctx, "left")
  setTextBaseline(ctx, "middle")
  setFont(ctx, font(800, if compactLandscape {17.0} else if state.layout.portrait {22.0} else {24.0}))
  fillText(
    ctx,
    state.content.title,
    if state.layout.portrait {16.0} else if compactLandscape {14.0} else {24.0},
    if compactLandscape {28.0} else {31.0},
  )
  drawProgress(false)
  drawSoundButton()
}

let drawRepeatButton = () => {
  let box = state.layout.repeat
  fillRounded(box, 18.0, "#e9f3df")
  strokeRounded(box, 18.0, "#6b8c78", 2.0)
  drawSpeaker(box.x +. 23.0, box.y +. box.h /. 2.0, 25.0, false, "#294c46")
  if box.w >= 104.0 {
    setFillStyle(ctx, "#294c46")
    setTextAlign(ctx, "left")
    setTextBaseline(ctx, "middle")
    setFont(ctx, font(700, 13.0))
    fillText(ctx, state.content.repeat, box.x +. 41.0, box.y +. box.h /. 2.0 +. 1.0)
  }
}

let answerPosition = (question: question): int => {
  let found = {contents: 0}
  for position in 0 to 2 {
    if arrayGet(state.choiceOrder, position) == question.answer {
      found.contents = position
    }
  }
  found.contents
}

let atlasTile = (column: int, row: int): rect => {
  let sourceY = if row == 0 {0.0} else if row == 1 {333.0} else {666.0}
  let sourceHeight = if row == 2 {358.0} else {333.0}
  {x: intToFloat(column) *. 384.0, y: sourceY, w: 384.0, h: sourceHeight}
}

let promptAtlasCrop = (question: question): rect => {
  if question.kind == "glyph" {
    atlasTile(0, 0)
  } else {
    switch question.id {
    | "pic_kaan"
    | "word_kaan" => atlasTile(0, 0)
    | "pic_machhli" => atlasTile(1, 0)
    | "pic_roti" => atlasTile(2, 0)
    | "pic_nal" => atlasTile(3, 0)
    | "pic_patang" => atlasTile(0, 1)
    | "pic_tota" => atlasTile(1, 1)
    | "pic_aam"
    | "word_aam" => atlasTile(2, 1)
    | "pic_chammach" => atlasTile(3, 1)
    | "pic_bakri" => atlasTile(0, 2)
    | "pic_gaay" => atlasTile(1, 2)
    | "pic_naak"
    | "word_naak" => atlasTile(2, 2)
    | "word_taaraa" => atlasTile(3, 2)
    | _ => emptyRect()
    }
  }
}

let drawPromptToken = (question: question, centerX: float, centerY: float, height: float) => {
  let crop = promptAtlasCrop(question)
  if crop.w > 0.0 && imageElementComplete(promptAtlas) && imageElementNaturalWidth(promptAtlas) > 0 {
    let width = height *. crop.w /. crop.h
    drawImageCrop(
      ctx,
      promptAtlas,
      crop.x,
      crop.y,
      crop.w,
      crop.h,
      centerX -. width /. 2.0,
      centerY -. height /. 2.0,
      width,
      height,
    )
  } else {
    setFont(ctx, font(700, height *. 0.82))
    fillText(ctx, question.icon, centerX, centerY)
  }
}

let drawPrompt = (question: question) => {
  let box = state.layout.prompt
  drawPaperCard(box, "#fff9e7", "#d8c18b", true)
  let categoryY = box.y +. 30.0
  setFillStyle(ctx, "#55776a")
  setTextAlign(ctx, "center")
  setTextBaseline(ctx, "middle")
  setFont(ctx, font(800, if state.layout.portrait {16.0} else {18.0}))
  fillText(ctx, categoryLabel(question.kind), box.x +. box.w /. 2.0, categoryY)

  if state.layout.portrait {
    drawGuideForQuestion(question)
    drawPromptToken(
      question,
      box.x +. box.w *. 0.66,
      box.y +. box.h *. 0.46,
      clamp(box.h *. 0.39, 78.0, 104.0),
    )
    setFillStyle(ctx, "#243f3b")
    setFont(ctx, font(800, clamp(state.width *. 0.060, 21.0, 28.0)))
    // Keep long Hindi prompts in the right-hand column so they never run
    // underneath the guide portrait or its name tab on narrow screens.
    drawWrappedCentered(
      question.prompt,
      box.x +. box.w *. 0.67,
      box.y +. box.h -. 54.0,
      box.w *. 0.55,
      31.0,
      2,
    )
  } else {
    drawPromptToken(
      question,
      box.x +. box.w *. 0.15,
      box.y +. box.h *. 0.56,
      clamp(box.h *. 0.62, 86.0, 142.0),
    )
    setFillStyle(ctx, "#243f3b")
    setFont(ctx, font(800, clamp(state.width *. 0.027, 24.0, 38.0)))
    drawWrappedCentered(
      question.prompt,
      box.x +. box.w *. 0.60,
      box.y +. box.h *. 0.50,
      box.w *. 0.62,
      43.0,
      2,
    )
  }
  drawRepeatButton()

  if state.phase == 3 {
    let statusHeight = if state.layout.portrait {48.0} else {52.0}
    let status = {
      x: box.x +. 16.0,
      y: box.y +. box.h -. statusHeight -. 10.0,
      w: box.w -. 32.0,
      h: statusHeight,
    }
    fillRounded(status, 17.0, "#d9f1b8")
    setFillStyle(ctx, "#28533e")
    setTextAlign(ctx, "center")
    setTextBaseline(ctx, "middle")
    setFont(ctx, font(800, if state.layout.portrait {17.0} else {21.0}))
    fillText(ctx, question.success, status.x +. status.w /. 2.0, status.y +. status.h /. 2.0)
  } else if state.wrongChoice >= 0 && state.simTime < state.wrongUntil {
    let message = if state.misses >= 2 {state.content.hint} else {state.content.retry}
    let status = {x: box.x +. 22.0, y: box.y +. box.h -. 44.0, w: box.w -. 44.0, h: 36.0}
    fillRounded(status, 15.0, "#f7e4b2")
    setFillStyle(ctx, "#654c29")
    setTextAlign(ctx, "center")
    setTextBaseline(ctx, "middle")
    setFont(ctx, font(750, 16.0))
    fillText(ctx, message, status.x +. status.w /. 2.0, status.y +. status.h /. 2.0)
  }
}

let drawChoice = (question: question, position: int) => {
  let base = arrayGet(state.layout.choices, position)
  let wrong = state.wrongChoice == position && state.simTime < state.wrongUntil
  let correctFeedback = state.phase == 3 && state.selectedChoice == position
  let correctPosition = answerPosition(question)
  let hinted = state.phase == 2 && state.misses >= 2 && position == correctPosition
  let pulse = if hinted {sinFloat(state.simTime /. 150.0) *. 3.0} else {0.0}
  let box = {x: base.x -. pulse, y: base.y -. pulse, w: base.w +. pulse *. 2.0, h: base.h +. pulse *. 2.0}
  let face = if correctFeedback {
    "#dcf4b8"
  } else if wrong {
    "#f8ddca"
  } else if hinted {
    "#fff1ad"
  } else {
    "#fff9e8"
  }
  drawPaperCard(box, face, if correctFeedback {"#82ad59"} else {"#d3b879"}, true)

  if position == state.focusedChoice && state.phase == 2 {
    strokeRounded({x: box.x +. 4.0, y: box.y +. 4.0, w: box.w -. 8.0, h: box.h -. 8.0}, 20.0, "#244c56", 5.0)
    beginPath(ctx)
    moveTo(ctx, box.x +. 9.0, box.y +. box.h /. 2.0)
    lineTo(ctx, box.x +. 25.0, box.y +. box.h /. 2.0 -. 13.0)
    lineTo(ctx, box.x +. 25.0, box.y +. box.h /. 2.0 +. 13.0)
    closePath(ctx)
    setFillStyle(ctx, "#244c56")
    fill(ctx)
  }

  let badgeRadius = if state.layout.portrait {16.0} else {18.0}
  drawCircle(box.x +. 26.0, box.y +. 26.0, badgeRadius, "#365e57")
  setFillStyle(ctx, "#ffffff")
  setTextAlign(ctx, "center")
  setTextBaseline(ctx, "middle")
  setFont(ctx, font(800, 15.0))
  fillText(ctx, arrayGet(state.content.choiceKeys, position), box.x +. 26.0, box.y +. 27.0)

  let sourceIndex = arrayGet(state.choiceOrder, position)
  let choiceText = arrayGet(question.choices, sourceIndex)
  let fontSize = if question.kind == "word" {
    clamp(box.h *. 0.40, 38.0, 58.0)
  } else {
    clamp(box.h *. 0.52, 50.0, 84.0)
  }
  setFillStyle(ctx, "#223c38")
  setTextAlign(ctx, "center")
  setTextBaseline(ctx, "middle")
  setFont(ctx, font(850, fontSize))
  fillText(ctx, choiceText, box.x +. box.w /. 2.0, box.y +. box.h /. 2.0 +. 6.0)

  if wrong {
    drawCircle(box.x +. box.w -. 28.0, box.y +. 28.0, 19.0, "#fff7ef")
    drawCross(box.x +. box.w -. 28.0, box.y +. 28.0, 8.0, "#b25b47")
  } else if correctFeedback {
    drawCircle(box.x +. box.w -. 30.0, box.y +. 30.0, 21.0, "#fffbe1")
    drawCheck(box.x +. box.w -. 30.0, box.y +. 30.0, 18.0, "#3e7e45")
  } else if hinted {
    drawStar(box.x +. box.w -. 30.0, box.y +. 30.0, 21.0, 9.0, "#e0a51d", state.simTime /. 500.0)
  }
}

let drawCorrectReward = (question: question) => {
  if state.phase == 3 {
    let progress = clamp((state.simTime -. state.feedbackStart) /. 920.0, 0.0, 1.0)
    let eased = 1.0 -. (1.0 -. progress) *. (1.0 -. progress)
    let (startX, startY) = switch guideForQuestion(question) {
    | Kuku => {
        let box = guidePlayBox()
        (
          box.x +. box.w *. (if state.layout.portrait {0.60} else {0.58}),
          box.y +. box.h *. (if state.layout.portrait {0.50} else {0.36}),
        )
      }
    | Furia
    | Vesper => {
        let position = if state.selectedChoice >= 0 {state.selectedChoice} else {answerPosition(question)}
        let box = arrayGet(state.layout.choices, position)
        (box.x +. box.w /. 2.0, box.y +. box.h *. 0.25)
      }
    }
    let endX = state.width /. 2.0
    let endY = if state.layout.portrait {74.0} else {36.0}
    let x = startX +. (endX -. startX) *. eased
    let y = startY +. (endY -. startY) *. eased -. sinFloat(progress *. pi) *. 58.0
    setGlobalAlpha(ctx, 1.0 -. progress *. 0.15)
    drawCircle(x, y, 35.0 +. progress *. 12.0, "rgba(255,218,68,0.27)")
    setFillStyle(ctx, "#d79812")
    setTextAlign(ctx, "center")
    setTextBaseline(ctx, "middle")
    setFont(ctx, font(900, 45.0 +. progress *. 11.0))
    fillText(ctx, question.focus, x, y +. 3.0)
    for index in 0 to 9 {
      let angle = intToFloat(index) *. pi *. 0.2 +. state.simTime /. 500.0
      let radius = 35.0 +. progress *. (25.0 +. intToFloat(mod(index, 3)) *. 7.0)
      drawStar(
        x +. cosFloat(angle) *. radius,
        y +. sinFloat(angle) *. radius,
        7.0,
        3.0,
        if mod(index, 2) == 0 {"#ffd947"} else {"#fff2a6"},
        angle,
      )
    }
    setGlobalAlpha(ctx, 1.0)
  }
}

let drawPlay = () => {
  let question = arrayGet(state.content.questions, state.currentIndex)
  drawHeader()
  if !state.layout.portrait {
    drawGuideForQuestion(question)
  }
  drawPrompt(question)
  for position in 0 to 2 {
    drawChoice(question, position)
  }
  if !state.layout.portrait && state.height >= 430.0 {
    setFillStyle(ctx, "rgba(35,66,58,0.76)")
    setTextAlign(ctx, "center")
    setTextBaseline(ctx, "middle")
    setFont(ctx, font(650, 14.0))
    fillText(ctx, state.content.keyboardHelp, state.width /. 2.0, state.height -. 15.0)
  }
  drawCorrectReward(question)
}

let drawStart = () => {
  let compactPortrait = state.layout.portrait && state.height < 660.0
  let compactLandscape = !state.layout.portrait && state.height < 430.0
  drawSoundButton()
  setTextAlign(ctx, "center")
  setTextBaseline(ctx, "middle")
  setFillStyle(ctx, "#234c45")
  let titleSize = if compactLandscape {
    28.0
  } else if compactPortrait {
    clamp(state.width *. 0.080, 26.0, 31.0)
  } else {
    clamp(state.width *. (if state.layout.portrait {0.088} else {0.052}), 34.0, 66.0)
  }
  setFont(ctx, font(900, titleSize))
  let titleY = if compactPortrait {
    78.0
  } else if compactLandscape {
    30.0
  } else if state.layout.portrait {
    130.0
  } else {
    74.0
  }
  fillText(ctx, state.content.title, state.width /. 2.0, titleY)
  setFillStyle(ctx, "#496d61")
  setFont(
    ctx,
    font(700, if compactPortrait || compactLandscape {16.0} else {clamp(state.width *. 0.024, 19.0, 30.0)}),
  )
  let subtitleY = if compactPortrait {
    118.0
  } else if compactLandscape {
    62.0
  } else if state.layout.portrait {
    188.0
  } else {
    122.0
  }
  fillText(ctx, state.content.subtitle, state.width /. 2.0, subtitleY)
  let trioCenter = if compactPortrait {
    state.height *. 0.39
  } else if compactLandscape {
    125.0
  } else if state.layout.portrait {
    state.height *. 0.43
  } else {
    state.height *. 0.42
  }
  let trioHeight = if compactPortrait {
    minFloat(state.height *. 0.21, 165.0)
  } else if compactLandscape {
    90.0
  } else if state.layout.portrait {
    minFloat(state.height *. 0.23, 165.0)
  } else {
    minFloat(state.height *. 0.43, 310.0)
  }
  drawGuideTrio(trioCenter, trioHeight)
  let box = state.layout.start
  drawPaperCard(box, "#ffe071", "#c59127", true)
  setFillStyle(ctx, "#3e4b36")
  setFont(ctx, font(900, clamp(box.h *. 0.31, 25.0, 34.0)))
  fillText(ctx, state.content.start, box.x +. box.w /. 2.0, box.y +. box.h /. 2.0)
  setFillStyle(ctx, "#3c6258")
  if !compactLandscape {
    setFont(ctx, font(650, if compactPortrait {13.0} else {15.0}))
    fillText(
      ctx,
      state.content.startHint,
      state.width /. 2.0,
      box.y +. box.h +. (if compactPortrait {28.0} else {34.0}),
    )
  }
}

let drawComplete = () => {
  let compactPortrait = state.layout.portrait && state.height < 660.0
  let compactLandscape = !state.layout.portrait && state.height < 430.0
  drawSoundButton()
  setTextAlign(ctx, "center")
  setTextBaseline(ctx, "middle")
  setFillStyle(ctx, "#234c45")
  let titleSize = if compactLandscape {
    28.0
  } else if compactPortrait {
    32.0
  } else {
    clamp(state.width *. 0.062, 38.0, 70.0)
  }
  setFont(ctx, font(900, titleSize))
  let titleY = if compactPortrait {
    70.0
  } else if compactLandscape {
    28.0
  } else if state.layout.portrait {
    120.0
  } else {
    82.0
  }
  fillText(ctx, state.content.completeTitle, state.width /. 2.0, titleY)
  let trioCenter = if compactPortrait {
    state.height *. 0.31
  } else if compactLandscape {
    92.0
  } else if state.layout.portrait {
    state.height *. 0.35
  } else {
    state.height *. 0.34
  }
  let trioHeight = if compactPortrait {
    minFloat(state.height *. 0.20, 155.0)
  } else if compactLandscape {
    82.0
  } else if state.layout.portrait {
    minFloat(state.height *. 0.21, 155.0)
  } else {
    minFloat(state.height *. 0.31, 225.0)
  }
  drawGuideTrio(trioCenter, trioHeight)
  drawProgress(true)
  setFillStyle(ctx, "#365d52")
  setFont(ctx, font(750, clamp(state.width *. 0.031, 21.0, 32.0)))
  let bodyY = if compactPortrait {
    state.height *. 0.62
  } else if compactLandscape {
    214.0
  } else if state.layout.portrait {
    state.height *. 0.61
  } else {
    state.height *. 0.62
  }
  fillText(ctx, state.content.completeBody, state.width /. 2.0, bodyY)
  let box = state.layout.restart
  drawPaperCard(box, "#ffe071", "#c59127", true)
  setFillStyle(ctx, "#3e4b36")
  setFont(ctx, font(900, clamp(box.h *. 0.32, 25.0, 34.0)))
  fillText(ctx, state.content.restart, box.x +. box.w /. 2.0, box.y +. box.h /. 2.0)
}

let devMode = queryHas("dev")

let drawDevOverlay = () => {
  if devMode {
    let currentQuestion = if state.loaded {arrayGet(state.content.questions, state.currentIndex)} else {blankQuestion}
    let questionId = currentQuestion.id
    setCanvasAttribute(gameCanvas, "data-phase", numberString(intToFloat(state.phase)))
    setCanvasAttribute(gameCanvas, "data-score", numberString(intToFloat(state.score)))
    setCanvasAttribute(gameCanvas, "data-question", questionId)
    setCanvasAttribute(gameCanvas, "data-answer", numberString(intToFloat(answerPosition(currentQuestion))))
    setCanvasAttribute(gameCanvas, "data-misses", numberString(intToFloat(state.misses)))
    setCanvasAttribute(gameCanvas, "data-retries", numberString(intToFloat(arrayLength(state.retryQueue))))
    setCanvasAttribute(gameCanvas, "data-masteries", numberString(intToFloat(arrayLength(state.mastery))))
    setCanvasAttribute(gameCanvas, "data-dpr", numberString(state.dpr))
    setCanvasAttribute(gameCanvas, "data-portrait", if state.layout.portrait {"true"} else {"false"})
    setCanvasAttribute(gameCanvas, "data-guide", guideKey(guideForQuestion(currentQuestion)))
    setCanvasAttribute(gameCanvas, "data-sound", if state.sound {"true"} else {"false"})
    setCanvasAttribute(gameCanvas, "data-speech", if state.speechAvailable {"hi"} else {"visual"})
    setCanvasAttribute(gameCanvas, "data-input", state.lastInput)
    let box = {x: 8.0, y: state.height -. 105.0, w: 260.0, h: 96.0}
    fillRounded(box, 10.0, "rgba(18,28,27,0.82)")
    setFillStyle(ctx, "#dff7df")
    setTextAlign(ctx, "left")
    setTextBaseline(ctx, "top")
    setFont(ctx, "12px ui-monospace,monospace")
    fillText(ctx, state.content.devLabel ++ "  q=" ++ questionId, box.x +. 9.0, box.y +. 8.0)
    fillText(ctx, "phase=" ++ numberString(intToFloat(state.phase)) ++ " score=" ++ numberString(intToFloat(state.score)), box.x +. 9.0, box.y +. 27.0)
    fillText(ctx, "fps=" ++ numberString(floorFloat(state.fps)->intToFloat) ++ " frame=" ++ numberString(state.frameMs), box.x +. 9.0, box.y +. 46.0)
    fillText(ctx, "input=" ++ state.lastInput ++ " speech=" ++ (if state.speechAvailable {"hi"} else {"visual"}), box.x +. 9.0, box.y +. 65.0)
  }
}

let drawPaused = () => {
  if state.paused && state.loaded {
    setFillStyle(ctx, "rgba(23,41,38,0.62)")
    fillRect(ctx, 0.0, 0.0, state.width, state.height)
    let box = {x: state.width *. 0.2, y: state.height *. 0.42, w: state.width *. 0.6, h: 96.0}
    drawPaperCard(box, "#fff8df", "#d3b879", true)
    setFillStyle(ctx, "#294c46")
    setTextAlign(ctx, "center")
    setTextBaseline(ctx, "middle")
    setFont(ctx, font(850, 28.0))
    fillText(ctx, state.content.paused, state.width /. 2.0, box.y +. box.h /. 2.0)
  }
}

let drawLoading = () => {
  let centerX = state.width /. 2.0
  let centerY = state.height /. 2.0
  for index in 0 to 2 {
    let pulse = 8.0 +. sinFloat(state.simTime /. 240.0 +. intToFloat(index)) *. 3.0
    drawCircle(centerX +. (intToFloat(index) -. 1.0) *. 36.0, centerY, pulse, "#3f8d5b")
  }
}

let draw = () => {
  setTransform(ctx, state.dpr, 0.0, 0.0, state.dpr, 0.0, 0.0)
  clearRect(ctx, 0.0, 0.0, state.width, state.height)
  drawBackground(state.simTime)
  if !state.loaded {
    drawLoading()
  } else if state.phase == 1 {
    drawStart()
  } else if state.phase == 2 || state.phase == 3 {
    drawPlay()
  } else if state.phase == 4 {
    drawComplete()
  }
  drawPaused()
  drawDevOverlay()
}

let moveFocus = (direction: int) => {
  if state.phase == 2 {
    state.focusedChoice = mod(state.focusedChoice + direction + 3, 3)
    state.lastInput = "move"
    playCue("tap", state.sound)
  }
}

let confirmAction = () => {
  if state.paused || !state.loaded {
    ()
  } else if state.phase == 1 {
    state.lastInput = "start"
    startSession(state.seed)
  } else if state.phase == 2 {
    state.lastInput = "confirm"
    answerChoice(state.focusedChoice)
  } else if state.phase == 4 {
    state.lastInput = "restart"
    startSession(rngStep(state.seed))
  }
}

let pointerPosition = (event: domEvent): (float, float) => {
  let bounds = canvasRect(gameCanvas)
  let scaleX = state.width /. rectWidth(bounds)
  let scaleY = state.height /. rectHeight(bounds)
  (
    (eventClientX(event) -. rectLeft(bounds)) *. scaleX,
    (eventClientY(event) -. rectTop(bounds)) *. scaleY,
  )
}

let handlePointer = (event: domEvent) => {
  preventDefault(event)
  if !state.paused && state.loaded {
    let (x, y) = pointerPosition(event)
    state.lastInput = "pointer"
    if rectContains(state.layout.sound, x, y) {
      toggleSound()
    } else if state.phase == 1 && rectContains(state.layout.start, x, y) {
      startSession(state.seed)
    } else if state.phase == 2 {
      if rectContains(state.layout.repeat, x, y) {
        repeatPrompt()
      } else {
        let hit = {contents: -1}
        for position in 0 to 2 {
          if rectContains(arrayGet(state.layout.choices, position), x, y) {
            hit.contents = position
          }
        }
        if hit.contents >= 0 {
          state.focusedChoice = hit.contents
          answerChoice(hit.contents)
        }
      }
    } else if state.phase == 4 && rectContains(state.layout.restart, x, y) {
      startSession(rngStep(state.seed))
    }
  }
}

let handleKey = (event: domEvent) => {
  if !eventRepeat(event) {
    let code = eventCode(event)
    let handled = {contents: true}
    state.lastInput = code
    if code == "Enter" || code == "Space" {
      confirmAction()
    } else if code == "ArrowLeft" || code == "ArrowUp" {
      moveFocus(-1)
    } else if code == "ArrowRight" || code == "ArrowDown" {
      moveFocus(1)
    } else if code == "Digit1" || code == "Numpad1" {
      answerChoice(0)
    } else if code == "Digit2" || code == "Numpad2" {
      answerChoice(1)
    } else if code == "Digit3" || code == "Numpad3" {
      answerChoice(2)
    } else if code == "KeyR" {
      repeatPrompt()
    } else if code == "KeyM" {
      toggleSound()
    } else {
      handled.contents = false
    }
    if handled.contents {
      preventDefault(event)
    }
  }
}

let updateGamepad = () => {
  let pad = pollGamepad()
  if pad.left && !state.padLeft {
    state.lastInput = "pad-left"
    moveFocus(-1)
  }
  if pad.right && !state.padRight {
    state.lastInput = "pad-right"
    moveFocus(1)
  }
  if pad.confirm && !state.padConfirm {
    state.lastInput = "pad-confirm"
    confirmAction()
  }
  if pad.repeatPrompt && !state.padRepeat {
    state.lastInput = "pad-repeat"
    repeatPrompt()
  }
  state.padLeft = pad.left
  state.padRight = pad.right
  state.padConfirm = pad.confirm
  state.padRepeat = pad.repeatPrompt
}

let updateStep = (step: float) => {
  state.simTime = state.simTime +. step
  updateGamepad()
  if state.wrongChoice >= 0 && state.simTime >= state.wrongUntil {
    state.wrongChoice = -1
  }
  if state.phase == 3 && state.simTime -. state.feedbackStart >= 1050.0 {
    nextQuestion()
  }
}

let rec frame = (now: float) => {
  let rawFrame = if state.lastFrame <= 0.0 {16.67} else {now -. state.lastFrame}
  state.lastFrame = now
  let bounded = clamp(rawFrame, 0.0, 100.0)
  state.frameMs = bounded
  let instantFps = if bounded > 0.0 {1000.0 /. bounded} else {60.0}
  state.fps = if state.fps <= 0.0 {instantFps} else {state.fps *. 0.92 +. instantFps *. 0.08}
  if !state.paused {
    state.accumulator = state.accumulator +. bounded
    while state.accumulator >= 16.67 {
      updateStep(16.67)
      state.accumulator = state.accumulator -. 16.67
    }
  }
  draw()
  let _ = requestAnimationFrame(frame)
}

let onBlur = (_event: domEvent) => {
  state.paused = true
  cancelSpeech()
}

let onFocus = (_event: domEvent) => {
  state.paused = false
  state.lastFrame = 0.0
}

type testCommand = {kind: string, index: int, ms: float}
type snapshot = {
  phase: int,
  score: int,
  questionId: string,
  choices: array<string>,
  answerPosition: int,
  misses: int,
  seed: int,
  sound: bool,
  speechAvailable: bool,
  width: float,
  height: float,
  dpr: float,
  portrait: bool,
  lastInput: string,
  masteryItems: int,
  retryItems: int,
}

type testHook = {
  snapshot: unit => snapshot,
  dispatch: testCommand => unit,
  reset: int => unit,
  forceQuestion: string => bool,
  setSpeechAvailable: bool => unit,
}

@set external setTestHook: (browserWindow, testHook) => unit = "__KUKU_TEST__"

let snapshotState = (): snapshot => {
  let question = if state.loaded {arrayGet(state.content.questions, state.currentIndex)} else {blankQuestion}
  let visibleChoices = [
    arrayGet(question.choices, arrayGet(state.choiceOrder, 0)),
    arrayGet(question.choices, arrayGet(state.choiceOrder, 1)),
    arrayGet(question.choices, arrayGet(state.choiceOrder, 2)),
  ]
  {
    phase: state.phase,
    score: state.score,
    questionId: question.id,
    choices: visibleChoices,
    answerPosition: answerPosition(question),
    misses: state.misses,
    seed: state.seed,
    sound: state.sound,
    speechAvailable: state.speechAvailable,
    width: state.width,
    height: state.height,
    dpr: state.dpr,
    portrait: state.layout.portrait,
    lastInput: state.lastInput,
    masteryItems: arrayLength(state.mastery),
    retryItems: arrayLength(state.retryQueue),
  }
}

let dispatchTest = (command: testCommand) => {
  if command.kind == "start" {
    startSession(state.seed)
  } else if command.kind == "answer" {
    state.inputUnlockAt = state.simTime
    answerChoice(command.index)
  } else if command.kind == "repeat" {
    repeatPrompt()
  } else if command.kind == "sound" {
    toggleSound()
  } else if command.kind == "tick" {
    let remaining = {contents: maxFloat(0.0, command.ms)}
    while remaining.contents > 0.0 {
      let step = minFloat(16.67, remaining.contents)
      updateStep(step)
      remaining.contents = remaining.contents -. step
    }
  }
  draw()
}

let forceQuestion = (id: string): bool => {
  let found = {contents: -1}
  for index in 0 to arrayLength(state.content.questions) - 1 {
    if arrayGet(state.content.questions, index).id == id {
      found.contents = index
    }
  }
  if found.contents >= 0 {
    state.phase = 2
    startQuestion(found.contents)
    true
  } else {
    false
  }
}

let setSpeechAvailableForTest = (available: bool) => {
  state.speechOverride = if available {1} else {0}
  state.speechAvailable = available
  if !available {
    cancelSpeech()
  }
}

let installTestHook = () => {
  if devMode {
    setTestHook(browserWindow, {
      snapshot: snapshotState,
      dispatch: dispatchTest,
      reset: seed => startSession(seed),
      forceQuestion,
      setSpeechAvailable: setSpeechAvailableForTest,
    })
  }
}

resize()
addWindowListener(browserWindow, "resize", _ => resize())
addWindowListener(browserWindow, "keydown", handleKey)
addWindowListener(browserWindow, "blur", onBlur)
addWindowListener(browserWindow, "focus", onFocus)
addCanvasListener(gameCanvas, "pointerdown", handlePointer)

let contentRequest: promise<content> = thenPromiseAsync(
  fetchResource("./assets/strings.json"),
  response => responseJson(response),
)
let contentLoaded = thenPromise(contentRequest, (loaded: content) => {
  state.content = loaded
  state.loaded = true
  state.phase = 1
  state.speechAvailable = speakNative("", false)
  setDocumentTitle(browserDocument, loaded.title)
  setCanvasAttribute(gameCanvas, "aria-label", loaded.title ++ ". " ++ loaded.subtitle)
  installTestHook()
})
let _ = catchPromise(contentLoaded, _error => {
  state.loadFailed = true
})

let _ = requestAnimationFrame(frame)
