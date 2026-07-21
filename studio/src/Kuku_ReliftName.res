/* KUKU Ep1 — targeted batch re-lift: author-corrected spelling of Vesper's name.
   वेस्पर (े) must become वैस्पर (ै) in every dialogue line, nothing else changed.
   Goes through liftDialogue so every receipt stays valid.

   Run from inside studio/:
     CLAUDE_STUDIO_BUDGET=14 node src/Kuku_ReliftName.res.mjs
*/

@val @scope("process") external cwd: unit => string = "cwd"

let dir = cwd() ++ "/../stories/kuku/ep1"

let ids = [
  "ep1-s1-akshar",
  "ep1-s2-pilla",
  "ep1-s3-chhupam",
  "ep1-s4-bachaav",
  "ep1-s5-kalu-ghar",
  "ep1-s6-topi",
]

let notes = `One spelling correction from the author, applied to every dialogue line it appears in, and NOTHING else may change: the name वेस्पर is misspelled; the correct spelling is वैस्पर (with the ै vowel sign, not े). Rewrite every dialogue line that contains वेस्पर identically except with वैस्पर. Do not touch any other word, any punctuation, or any line that does not contain the name.`

let liftOne = async id => {
  let path = Cinema_Backends.Path(dir ++ "/" ++ id ++ ".scene.txt")
  try {
    let sc = await Write.liftDialogue(~path, ~notes, ~maxTries=3)
    let _ = Write.emit(sc, ~txt=path)
    switch Write.verify(path) {
    | Ok() => {
        Js.log("== OK " ++ id)
        true
      }
    | Error(m) => {
        Js.log("== VERIFY FAILED " ++ id ++ ": " ++ m)
        false
      }
    }
  } catch {
  | Write.WriteError(m) => {
      Js.log("== FAILED " ++ id ++ ": " ++ m)
      false
    }
  | Session.SessionError(m) => {
      Js.log("== FAILED " ++ id ++ " (session): " ++ m)
      false
    }
  }
}

let rec run = async (i, ok) =>
  switch Belt.Array.get(ids, i) {
  | None => ok
  | Some(id) => {
      let r = await liftOne(id)
      await run(i + 1, r ? ok + 1 : ok)
    }
  }

let main = async () => {
  let ok = await run(0, 0)
  Js.log("=== " ++ Belt.Int.toString(ok) ++ "/6 renamed, " ++ Belt.Int.toString(Session.callsMade()) ++ " calls ===")
  Session.close()
}
main()->ignore
