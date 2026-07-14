/* THE FOUR OLDS trailer — TEST SHOT: the barn roll-call wide. The hardest
   consistency case first: all four olds in one frame, composed with their
   reference boards as identity refs, then animated via Seedance (image->
   video) with the template's committed-camera law.
   Run: node src/FourOlds_TestShot.res.mjs */

@module("fs") external existsSync: string => bool = "existsSync"
@module("fs") external mkdirSync: (string, 'a) => unit = "mkdirSync"

let sheets = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/trailer/sheets/"
let shots = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/trailer/shots/"

let framePrompt = "A cinematic 16:9 film still, Kodak Portra 400, inside a Nebraska barn at night. Four old men at a plywood flight-simulator mock-up in a pool of warm work-lamp light, the rest of the barn falling into soft dark, hay bales and clean tools on the walls, night black through the open door. THE FOUR MEN ARE THE FOUR REFERENCE CHARACTERS PROVIDED, exactly as designed — same faces, same clothes: (1) the tall lean 79-year-old farmer in the tan canvas jacket sits centered at the plywood console, hands resting on it; (2) the slight precise 76-year-old engineer in the pressed gray shirt and wire glasses sits beside him holding an open logbook; (3) the sturdy 74-year-old in the denim shirt with the rag on his shoulder leans back in a folding chair with a tin coffee cup; (4) the broad squared 71-year-old in the plain navy ballcap and buttoned khaki shirt stands at the end, formal, mid-roll-call. Steam off two coffee cups, a percolator on a crate. Natural film grain, true skin texture, warm practical light only — a real photograph, not CG. STRICT: no text, no lettering, no logos anywhere."

let motionPrompt = "Subject: four old men at a plywood flight-simulator console inside a barn at night, held in a warm work-lamp pool. Maintain consistent identity, clothing, hairstyle, and appearance of all four men throughout — the same four men as the input frame, no new people. Location: Nebraska barn interior, night. Visual style: Kodak Portra 400 film, warm practicals, soft dark falloff, fine grain, observational realism. Camera: a single locked tripod wide shot, no camera movement, no zoom, no cinematic moves — a patient documentary frame. Timed beats: 0-2s the standing man in the ballcap speaks a formal roll call, small precise nod, the others still; 2-4s the seated farmer reaches and flips one plywood toggle, the engineer makes a small pencil mark in the logbook; 4-6s the man with the coffee cup raises it and drinks, steam moving, the standing man clasps his hands behind his back. Audio: quiet room — a percolator ticking, a chair creak, wind faint on the boards, no music, no speech audio. Goal: the feeling of a real, patient documentary frame inside a fifty-year ritual — recorded, not staged. Exclusions: no new characters, no camera motion, no lighting changes, no text or logos."

let main = async () => {
  mkdirSync(shots, {"recursive": true})
  let frame = shots ++ "sc_rollcall_frame.png"
  let clip = shots ++ "sc_rollcall_test.mp4"
  /* 1: compose the start frame with the four boards as identity refs */
  if !existsSync(frame) {
    try {
      let b = await Cinema_Backends.image(
        ~prompt=Cinema_Backends.Prompt(framePrompt),
        ~refs=[
          Cinema_Backends.Path(sheets ++ "small/cricket.jpg"),
          Cinema_Backends.Path(sheets ++ "small/dutch.jpg"),
          Cinema_Backends.Path(sheets ++ "small/stitch.jpg"),
          Cinema_Backends.Path(sheets ++ "small/gunny.jpg"),
        ],
        ~pro=true,
      )
      let _ = Cinema_Backends.writeBytes(Cinema_Backends.Path(frame), b)
      Js.log("FRAME OK")
    } catch {
    | Cinema_Backends.BackendError(m) => Js.log("FRAME FAIL — " ++ m)
    }
  } else {
    Js.log("FRAME exists")
  }
  /* 2: animate it (only when the frame exists) */
  if existsSync(frame) && !existsSync(clip) {
    try {
      let b = await Cinema_Backends.imageToVideo(
        ~image=Cinema_Backends.Path(frame),
        ~prompt=Cinema_Backends.Prompt(motionPrompt),
        ~seconds=Cinema_Backends.Seconds(6.0),
        ~cameraFixed=true,
        ~lastFrame=None,
      )
      let _ = Cinema_Backends.writeBytes(Cinema_Backends.Path(clip), b)
      Js.log("CLIP OK")
    } catch {
    | Cinema_Backends.BackendError(m) => Js.log("CLIP FAIL — " ++ m)
    }
  }
  Js.log("TEST SHOT DONE")
}
main()->ignore
