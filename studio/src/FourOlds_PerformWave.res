/* THE FOUR OLDS — the performance wave: run the performance pass over
   every audio scene that lacks a valid performance JSON. Resumable; a
   scene whose existing performance passes Perf.load is skipped.
   Run: CLAUDE_STUDIO_TURN_TIMEOUT_MS=240000 CLAUDE_STUDIO_BUDGET=15 node src/FourOlds_PerformWave.res.mjs */

@module("fs") external readdirSync: string => array<string> = "readdirSync"
@module("fs") external mkdirSync: (string, 'a) => unit = "mkdirSync"

let audioDir = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/audio/"

let main = async () => {
  mkdirSync(audioDir ++ "perf", {"recursive": true})
  let scenes =
    readdirSync(audioDir)
    ->Belt.Array.keep(f => Js.Re.test_(%re("/^a\d[\da-z_]*\.scene\.txt$/"), f))
    ->Js.Array2.sortInPlace
  let ok = ref(0)
  let bad = ref(0)
  let sinceReset = ref(0)
  let n = Belt.Array.length(scenes)
  let rec go = async k =>
    if k < n {
      /* keep per-scene cost flat: a warm session accumulates every prior
         scene in context — reset it every eight performances */
      if sinceReset.contents >= 8 {
        Session.close()
        sinceReset := 0
      }
      let f = Belt.Array.getExn(scenes, k)
      let base = Js.String2.replace(f, ".scene.txt", "")
      let scenePath = audioDir ++ f
      let perfPath = audioDir ++ "perf/" ++ base ++ ".perf.json"
      switch Perf.load(~perfPath, ~scenePath) {
      | Ok(_) => Js.log("SKIP " ++ base ++ " (performed)")
      | Error(_) =>
        try {
          switch await Perform.run(~scenePath, ~outPath=perfPath) {
          | Ok(lines) => {
              ok := ok.contents + 1
              sinceReset := sinceReset.contents + 1
              Js.log("OK   " ++ base ++ " (" ++ Belt.Int.toString(lines) ++ " lines)")
            }
          | Error(m) => {
              bad := bad.contents + 1
              sinceReset := sinceReset.contents + 1
              Js.log("GATE " ++ base ++ " — " ++ m)
            }
          }
        } catch {
        | Session.SessionError(m) => {
            bad := bad.contents + 1
            Js.log("FAIL " ++ base ++ " (session): " ++ m)
          }
        | _ => {
            bad := bad.contents + 1
            Js.log("FAIL " ++ base ++ " (unexpected)")
          }
        }
      }
      await go(k + 1)
    }
  await go(0)
  Js.log(
    "PERFORM WAVE DONE — " ++
    Belt.Int.toString(ok.contents) ++
    " performed, " ++
    Belt.Int.toString(bad.contents) ++ " with gate rejects, of " ++ Belt.Int.toString(n),
  )
  Session.close()
}
main()->ignore
