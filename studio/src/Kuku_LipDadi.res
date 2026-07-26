/* कुकु और अक्षर — Ep3 दादी lip-sync EXPERIMENT (author-sanctioned test of OmniHuman
   on all grandma talking segments). Reads lip_jobs.json ({img, aud, out}[] — public
   funnel URLs in, local mp4 paths out) and runs them sequentially. ~$0.14/s on fal.
   Run from studio/ with FAL_AI exported: node src/Kuku_LipDadi.res.mjs */
open Cinema_Backends

@val @scope("process") external cwd: unit => string = "cwd"
@module("fs") external readFileText: (string, string) => string = "readFileSync"

type job = {img: string, aud: string, out: string}
@scope("JSON") @val external parseJobs: string => array<job> = "parse"

let main = async () => {
  let jobs = parseJobs(readFileText(cwd() ++ "/../stories/kuku/ep3prod/lip_jobs.json", "utf8"))
  let done_ = ref(0)
  for i in 0 to Belt.Array.length(jobs) - 1 {
    switch Belt.Array.get(jobs, i) {
    | Some(j) =>
      switch await falOmnihumanUrl(~imageUrl=j.img, ~audioUrl=j.aud) {
      | clip => {
          let _ = writeBytes(Path(j.out), clip)
          done_ := done_.contents + 1
          Js.log("LIP OK " ++ j.out)
        }
      | exception Js.Exn.Error(e) =>
        Js.log("LIP FAIL " ++ j.out ++ ": " ++ Js.Exn.message(e)->Belt.Option.getWithDefault("?"))
      | exception _ => Js.log("LIP FAIL (raw) " ++ j.out)
      }
    | None => ()
    }
  }
  Js.log("DONE " ++ Belt.Int.toString(done_.contents) ++ "/" ++ Belt.Int.toString(Belt.Array.length(jobs)))
}
main()->ignore
