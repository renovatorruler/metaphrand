/* FREE smoke test of the Cinema external layer. Touches NO paid API — it only
   drives ffmpeg through Cinema_Backends: generate 0.5s of silence as mp3, then
   read its decoded duration back. Proves the child_process binding, the fs
   plumbing, the silence cache, and durationSec all work end to end.

   Run: `node src/Cinema_Smoke.res.mjs` (after `npx rescript`). */

open Cinema_Backends

let main = async () => {
  let cache = Path(".cinema-smoke")
  /* 500 ms of digital silence -> a real mp3 on disk (cached). */
  let mp3 = silence(Millis(500), cache)
  let Path(p) = mp3
  Js.log("silence mp3 -> " ++ p)
  /* decode it back: ffmpeg -f null, parsed. Should read ~0.5s. */
  let Seconds(d) = durationSec(mp3)
  Js.log("durationSec = " ++ Js.Float.toString(d) ++ "s")
  if exists(mp3) && d > 0.3 && d < 0.8 {
    Js.log("CINEMA OK")
  } else {
    Js.log("CINEMA FAIL: unexpected duration or missing file")
  }
}

let safe = async () =>
  switch await main() {
  | () => ()
  | exception BackendError(m) => Js.log("CINEMA FAIL: " ++ m)
  | exception _ => Js.log("CINEMA FAIL: unexpected error")
  }

safe()->ignore
