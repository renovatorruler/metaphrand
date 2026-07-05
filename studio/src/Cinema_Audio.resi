/* ============================================================================
   Cinema_Audio — story-agnostic multi-voice audio drama.

     scenes -> performance JSON -> ElevenLabs v3 dialogue -> stitched mp3 + manifest

   Each scene renders as ONE continuous dialogue take (the cast plays off each
   other, no per-line voice drift); takes are digest-cached so re-runs only synth
   what changed; a manifest (group -> scene, duration) is written for the video
   assembler. A narrator role is just another voice — it carries action lines.
   ============================================================================ */

@unboxed type title = Title(string)
@unboxed type role = Role(string)          // a speaking part key, e.g. "RAY" or "N" (narrator)
@unboxed type voiceName = VoiceName(string) // the human-readable voice label
@unboxed type sceneId = SceneId(string)
@unboxed type line = Line(string)          // one spoken line of text

/* who plays a role: the label + the ElevenLabs voice id. */
type castMember = {role: role, voiceName: voiceName, voiceId: Cinema_Backends.voiceId}

/* a scene = its id + its ordered (role, line) beats. */
type scene = {id: sceneId, beats: array<(role, line)>}

/* the built performance — the maintained artifact, serialized to JSON. */
type performance

/* Build (and write) the performance JSON from cast + scenes. gapMs is the silence
   inserted between takes. */
let performance: (
  ~title: title,
  ~cast: array<castMember>,
  ~scenes: array<scene>,
  ~gapMs: Cinema_Backends.millis,
  ~out: Cinema_Backends.path,
) => performance

/* Render a written performance to one stitched mp3 (digest-cached takes +
   silence gaps), writing a sibling `.manifest.json`. Returns the mp3 path. */
let render: (performance, ~out: Cinema_Backends.path) => promise<Cinema_Backends.path>

/* Re-read a performance written earlier (zero spend). */
let load: Cinema_Backends.path => performance

/* The AM-radio voice effect, done with FFMPEG FILTERS only (highpass 420 +
   lowpass 2900 + a peaking EQ at 1800 + acompressor) — no Web Audio, no JS DSP.
   Returns the path of the filtered mp3 (a sibling `.radio.mp3`). */
let radioize: Cinema_Backends.path => Cinema_Backends.path

/* The airport-PA / tannoy effect (boxy band + terminal slapback echo).
   Returns the path of the filtered mp3 (a sibling `.pa.mp3`). */
let paize: Cinema_Backends.path => Cinema_Backends.path
