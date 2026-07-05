/* ============================================================================
   Cinema_Backends — the ONE external layer. Story-agnostic.

   Every call that leaves the process lives here and nowhere else: ffmpeg /
   ffprobe (child_process), the Replicate + ElevenLabs HTTP endpoints (Node's
   global `fetch`), the filesystem (`fs`), base64 of reference files, and the
   Buffer handling for binary payloads. The rest of the engine never re-touches
   HTTP, keys, model IDs, or shell — it composes these typed verbs.

   Keys are read from disk on demand: ~/.replicate_api_key, ~/.elevenlabs_api_key.

   Honesty: ReScript has no way to make "I called a paid endpoint" a compile
   error, so the discipline is structural — paid calls exist ONLY as the named
   functions below, each minted from its own newtype'd inputs. A bare string
   never reaches an endpoint; it must first be named (Prompt, VoiceId, ...).
   ============================================================================ */

/* ---- distinct concepts, distinct types (principle 1) --------------------- */
@unboxed type path = Path(string)
@unboxed type prompt = Prompt(string)
@unboxed type voiceId = VoiceId(string)
@unboxed type seconds = Seconds(float)
@unboxed type millis = Millis(int)
@unboxed type text = Text(string)

/* opaque binary blob — a Node Buffer under the hood. The only ways to get one
   are to fetch it from an endpoint or read it off disk; the only thing you can
   do with it is write it back. No naked Buffer leaks into the rest of the app. */
type blob

/* raised when an external call fails (bad status, missing key, ffmpeg nonzero). */
exception BackendError(string)

/* ---- filesystem ---------------------------------------------------------- */
let exists: path => bool
let writeBytes: (path, blob) => path // makes parent dirs; returns the path written
let readText: path => string
let writeText: (path, string) => unit
let tempDir: string => path          // a fresh scratch dir under the OS temp root
let fileSizeMb: path => float

/* ---- ffmpeg / ffprobe (child_process) ------------------------------------ */
/* Run ffmpeg with a fully-formed argv (no shell). Raises BackendError nonzero. */
let ffmpeg: array<string> => unit
/* Render Pango markup to a content-sized PNG via pango-view (ffmpeg has no text
   filter on this Mac). Caller overlays the PNG on a fixed canvas. */
let pango: (~markup: string, ~width: int, ~background: string, ~out: path) => path
/* Exact decoded duration of an audio/video file (ffmpeg -f null, parsed). */
let durationSec: path => seconds
/* A cached mono mp3 of `ms` of digital silence in `cacheDir`; returns its path. */
let silence: (millis, path) => path
/* Concatenate mp3 parts (ffmpeg concat demuxer) into one mono mp3 at `path`. */
let concatAudio: (array<path>, path) => path

/* ---- Replicate-hosted image / video -------------------------------------- */
/* Text (+ optional reference frames) -> PNG bytes. pro picks nano-banana-pro. */
let image: (~prompt: prompt, ~refs: array<path>, ~pro: bool) => promise<blob>
/* Same, via OpenAI gpt-image-2 (relayed through Replicate; bills your OpenAI
   account). 16:9, high quality. refs become input_images. */
let imageGpt2: (~prompt: prompt, ~refs: array<path>) => promise<blob>
/* Animate a still (Seedance). camera_fixed holds composition; lastFrame pins end. */
let imageToVideo: (
  ~image: path,
  ~prompt: prompt,
  ~seconds: seconds,
  ~cameraFixed: bool,
  ~lastFrame: option<path>,
) => promise<blob>
/* Animate a still via OpenAI Sora 2 Pro (image = first frame). Generates its OWN
   audio from the prompt — NO audio input. Relayed through Replicate; bills your
   OpenAI account. landscape; hi => 1080p. */
let videoSora: (~image: path, ~prompt: prompt, ~seconds: int, ~hi: bool) => promise<blob>

/* fal.ai — Seedance 2.0 TEXT-to-video (queue API). Feed the full filled template as
   the prompt. resolution = "480p"|"720p"; seconds 4..15; aspect e.g. "16:9";
   ~audio => the model authors its own native audio (OFF for shots we score). */
let falSeedance2: (
  ~prompt: prompt,
  ~seconds: int,
  ~resolution: string,
  ~aspect: string,
  ~audio: bool,
) => promise<blob>

/* OmniHuman (ByteDance) — audio-driven talking avatar: a still image + OUR audio
   (< 30s) -> lip-synced talking video in our own voice (base64 data URIs accepted). */
let falOmnihuman: (~image: path, ~audio: path) => promise<blob>

/* ---- ElevenLabs ---------------------------------------------------------- */
/* One continuous multi-speaker take: the lines in order, each with its voice. */
let dialogue: array<(text, voiceId)> => promise<blob>
/* Same continuous take, PLUS each input line's (start,end) seconds in input order
   (from voice_segments) — for landing name+line captions on a continuous take. */
let dialogueTimed: array<(text, voiceId)> => promise<(blob, array<(float, float)>)>
/* Single-voice take (one narrator performs everything, v3 expression tags). */
let tts: (~text: text, ~voice: voiceId, ~settings: Js.Json.t=?) => promise<blob>
/* Instrumental score bed (ElevenLabs Music). Naming a real artist -> 400. */
let music: (~prompt: prompt, ~ms: millis, ~instrumental: bool) => promise<blob>
