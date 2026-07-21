/* KUKU aur AKSHAR — Episode 1 FULL — batch DIALOGUE LIFT. Lifts all seven emitted
   scenes in one warm session, then verifies each. The baked director's notes
   PROTECT this show's register: the default doctrine pushes adult subtext, and a
   kids' letter-teaching show needs the opposite kept intact.

   Run from inside studio/ (after Kuku_WriteEp1Full):
     CLAUDE_STUDIO_BUDGET=16 node src/Kuku_LiftEp1.res.mjs
*/

@val @scope("process") external cwd: unit => string = "cwd"

let dir = cwd() ++ "/../stories/kuku/ep1"

let ids = [
  "ep1-s0-teaser",
  "ep1-s1-akshar",
  "ep1-s2-pilla",
  "ep1-s3-chhupam",
  "ep1-s4-bachaav",
  "ep1-s5-kalu-ghar",
  "ep1-s6-topi",
]

let notes = `This is a Hindi-teaching kids' show (ages four to seven, Super Kitties energy). PROTECT the register; do not sophisticate it. Rules for this lift: (1) Keep every Hindi dialogue line short, simple, present-tense, learnable; no adult subtext, no irony, no cleverness. (2) Heavy repetition of the letter क and its words (कुत्ता, कालू, काला, कान, कूदना, कीचड़, कुआँ, कटोरा, कंबल, केला, किताब) is REQUIRED pedagogy; never trim it. (3) VESPER ONLY may drift into English and must then be reminded with हिंदी में, वैस्पर! and repeat in Hindi; keep this device wherever it appears; never give English to anyone else. (4) Keep these exact recurring lines untouched wherever present: मैं पहले!, कुत्ता केला नहीं खाता, साँस, टोपी, अक्षर, हिंदी का हर अक्षर टोपी पहनता है, आज का अक्षर है क, शुभ रात्रि, वैस्पर. (5) You MAY make lines more alive, playful, and character-true (Furia fast and first, Vesper slow and dreamy, Papa plain and warm, Dadi warm host), and fix anything stilted. (6) English action lines stay action; all dialogue stays Devanagari except Vesper's marked drifts. (7) Nothing scary, no meanness, no shaming.`

let liftOne = async id => {
  let path = Cinema_Backends.Path(dir ++ "/" ++ id ++ ".scene.txt")
  if !Cinema_Backends.exists(path) {
    Js.log("== SKIP " ++ id ++ " (no scene file)")
    false
  } else {
    try {
      let sc = await Write.liftDialogue(~path, ~notes, ~maxTries=4)
      let _ = Write.emit(sc, ~txt=path)
      switch Write.verify(path) {
      | Ok() => {
          Js.log("== LIFTED+VERIFIED " ++ id)
          true
        }
      | Error(m) => {
          Js.log("== LIFTED BUT VERIFY FAILED " ++ id ++ ": " ++ m)
          false
        }
      }
    } catch {
    | Write.WriteError(m) => {
        Js.log("== LIFT FAILED " ++ id ++ ": " ++ m)
        false
      }
    | Session.SessionError(m) => {
        Js.log("== LIFT FAILED " ++ id ++ " (session): " ++ m)
        false
      }
    }
  }
}

let rec run = async (i, okCount) =>
  switch Belt.Array.get(ids, i) {
  | None => okCount
  | Some(id) => {
      let ok = await liftOne(id)
      await run(i + 1, ok ? okCount + 1 : okCount)
    }
  }

let main = async () => {
  let ok = await run(0, 0)
  Js.log(
    "\n=== LIFT DONE: " ++
    Belt.Int.toString(ok) ++
    "/" ++
    Belt.Int.toString(Belt.Array.length(ids)) ++
    " production-ready, " ++
    Belt.Int.toString(Session.callsMade()) ++ " model calls ===",
  )
  Session.close()
}

main()->ignore
