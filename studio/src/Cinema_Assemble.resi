/* ============================================================================
   Cinema_Assemble — story-agnostic edit: a shot list + an audio track -> a cut.

   Each shot is a still (subtle Ken Burns) or a video clip (Seedance). Cross-
   dissolves at every cut; clip lengths are weight-proportional and scaled so the
   picture lands exactly on the audio. All ffmpeg goes through Cinema_Backends.
   ============================================================================ */

@unboxed type weight = Weight(float) // relative share of the runtime
@unboxed type px = Px(int)           // a pixel dimension
@unboxed type fps = Fps(int)         // frames per second

/* The kind of clip — a sum type, so an unknown string can never slip through as a
   silent default. kbIn/kbOut = Ken-Burns push in / pull out; static = held still;
   video = a real motion clip (plays once, then freezes its last frame). */
type kind = Video | KbIn | KbOut | Static

type shot = {src: Cinema_Backends.path, kind: kind, weight: weight}

/* the output resolution (e.g. Px(1920) x Px(1080)). */
type resolution = {width: px, height: px}

/* Cut `shots` to `audio`, cross-dissolving every cut, synced to audio length.
   Returns the written mp4 path. */
let assemble: (
  ~shots: array<shot>,
  ~audio: Cinema_Backends.path,
  ~out: Cinema_Backends.path,
  ~res: resolution,
  ~fps: fps,
  ~xfade: Cinema_Backends.seconds,
) => Cinema_Backends.path
