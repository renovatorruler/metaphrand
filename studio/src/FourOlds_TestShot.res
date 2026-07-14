/* THE FOUR OLDS trailer — TEST SHOT: the barn roll-call wide. The hardest
   consistency case first: all four olds in one frame, composed with their
   reference boards as identity refs, then animated via Seedance (image->
   video) with the template's committed-camera law.
   Run: node src/FourOlds_TestShot.res.mjs */

@module("fs") external existsSync: string => bool = "existsSync"
@module("fs") external mkdirSync: (string, 'a) => unit = "mkdirSync"

let sheets = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/trailer/sheets/"
let shots = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/trailer/shots/"

let framePrompt = "A cinematic 16:9 film still, Kodak Portra 400, inside a Nebraska barn at night. A genuine 1970s APOLLO PROCEDURES TRAINER fills half the barn — a heavy government-surplus console rig: worn gray-green enamel metal panels, banks of toggle switches and circuit-breaker rows, round instrument gauges, small warm indicator lamps lit, thick cable runs to a floor junction, the whole assembly bolted to the concrete, fifty years maintained and clean. A bare bulb and a work lamp pool warm light over it. THE FOUR MEN ARE THE FOUR REFERENCE CHARACTERS PROVIDED, exactly as designed, ALL FOUR MID-TASK: (1) the tall lean 79-year-old farmer in the tan canvas jacket seated at the main console, both hands working a switch row mid-procedure, eyes on the gauges; (2) the slight 76-year-old engineer in the pressed gray shirt and wire glasses standing at the panel's end, writing a figure in a thick open logbook against his forearm; (3) the sturdy 74-year-old in the denim shirt with the rag on his shoulder crouched at an open access panel, a multimeter probe in the guts of the machine; (4) the broad squared 71-year-old in the plain navy ballcap standing at parade rest reading a roll call from a clipboard held level. Steam off a tin cup on a crate, a percolator behind. Natural film grain, true skin texture, warm practical light only — a real photograph, not CG. STRICT: no text, no lettering, no logos anywhere, gauge faces blurred by depth."

let motionPrompt = "Subject: four old men operating a genuine 1970s Apollo procedures trainer inside a barn at night. Maintain consistent identity, clothing, hairstyle, and appearance of all four men throughout — the same four men as the input frame, no new people. Location: Nebraska barn interior, night, warm work-lamp pool. Visual style: Kodak Portra 400 film, warm practicals, soft dark falloff, fine grain, observational realism. Camera: a single locked tripod wide shot, no camera movement, no zoom — a patient documentary frame. Timed beats, ALL FOUR MEN ACTIVE THROUGHOUT: 0-2s the standing man in the ballcap reads from his clipboard and gives a small formal nod, while the seated farmer works two switches in sequence and a small indicator lamp changes; 2-4s the engineer writes in his logbook and turns a page without looking up, while the crouched man withdraws his probe from the access panel and closes it; 4-6s the crouched man stands and wipes his hands on the rag, the farmer rests his hand flat on the console, the standing man lowers the clipboard — the ritual completing. Audio: quiet room — a low electrical hum from the trainer, a percolator ticking, a chair creak, wind faint on the boards, no music, no speech audio. Goal: a real crew running a real machine they have kept alive for fifty years — recorded, not staged. Exclusions: no new characters, no camera motion, no lighting changes, no text or logos."

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
