/* Deterministic, zero-credit repair for the first B11 provider attempt.

   The provider attempt leaves its goat standing on a bright platform. This
   repair keeps the clean grounded opening, lets opaque mist cover that goat,
   swaps under cover to the accepted A07 goat-inside-cloud state, and then
   lifts that complete cloud pocket. The background also changes under the
   same cover to the accepted post-tether B10 plate, which contains no goat.
   At every visible instant there is exactly one goat and one bell. No
   provider, network, model, credential, or audio call is available here. */

module B = Cinema_Backends

exception B11LocalRepairError(string)

let fail = message => raise(B11LocalRepairError(message))

let width = 1280
let height = 720
let fps = 24
let durationSeconds = 6.0
let groundedSourceStartSeconds = 2.3
let groundedSourceEndSeconds = 4.7
let groundedWindowSeconds = 2.4
let cleanSourceStartSeconds = 5.5
let cleanSourceEndSeconds = 9.9
let cleanWindowSeconds = 4.4
let crossfadeSeconds = 0.8
let crossfadeOffsetSeconds = 1.6
let packRevealSeconds = 1.75
let packLiftSeconds = 2.4
let mistOpaqueStartFrame = 38
let mistOpaqueEndFrame = 58
let goatCount = 1
let bellCount = 1
let nativeAudio = false
let packWidth = 700
let packHeight = 458

type buildResult = {
  output: string,
  contact: string,
  outputSha256: string,
  contactSha256: string,
  probe: string,
}

let packY = seconds =>
  seconds < packLiftSeconds ? 270.0 : 270.0 -. 50.0 *. (seconds -. packLiftSeconds)

let packX = seconds =>
  seconds < packLiftSeconds ? 280.0 : 280.0 +. 45.0 *. (seconds -. packLiftSeconds)

let requireFile = path =>
  if !B.exists(B.Path(path)) {
    fail("expected accepted B11 repair source is missing: " ++ path)
  }

let requireSuccess = (~label, result: B.runResult) =>
  if result.code != 0 {
    fail(
      label ++ " failed (exit " ++ Belt.Int.toString(result.code) ++ "): " ++
      Js.String2.slice(result.stderr, ~from=0, ~to_=1600),
    )
  }

let build = (~root): buildResult => {
  let groundedSource = root ++ "/clips/candidates/B11_attempt1.mp4"
  let cleanBackground = root ++ "/clips/B10.mp4"
  let acceptedPocket = root ++ "/references/A07_clean_delogo.png"
  let candidates = root ++ "/clips/candidates"
  let qa = root ++ "/qa"
  let output = candidates ++ "/B11_local_repair_candidate.mp4"
  let contact = qa ++ "/B11_local_repair_contact.png"

  requireFile(groundedSource)
  requireFile(cleanBackground)
  requireFile(acceptedPocket)
  B.ensureDirPath(B.Path(candidates))
  B.ensureDirPath(B.Path(qa))

  /* The source crop leaves margin around the complete A07 pocket, so no mask
     touches a rectangular crop boundary. This mask follows the accepted
     pocket's visible cloud lobes. It keeps
     the goat, bell, hollow and cloud shell together, while excluding Rishi,
     the gate, orbit lines, forest and almost all surrounding sky. */
  let pocketMask =
    `255*gt(` ++
    `lte(pow((X-710)/255,2)+pow((Y-330)/145,2),1)+` ++
    `lte(pow((X-510)/150,2)+pow((Y-400)/140,2),1)+` ++
    `lte(pow((X-860)/140,2)+pow((Y-415)/150,2),1)+` ++
    `lte(pow((X-425)/145,2)+pow((Y-510)/150,2),1)+` ++
    `lte(pow((X-595)/175,2)+pow((Y-535)/135,2),1)+` ++
    `lte(pow((X-765)/195,2)+pow((Y-555)/125,2),1)+` ++
    `lte(pow((X-925)/145,2)+pow((Y-530)/145,2),1),0)`

  /* The cover is fully opaque before the A07 pack begins to appear and stays
     opaque until the no-goat B10 background has replaced the grounded plate.
     This temporal overlap is the one-goat invariant, not just a visual hope. */
  let mistOpacity =
    `if(between(N,24,38),255*(N-24)/14,` ++
    `if(between(N,38,58),255,if(between(N,58,76),255*(76-N)/18,0)))`
  let mistShape =
    `gt(` ++
    `lte(pow((X-640)/360,2)+pow((Y-505)/230,2),1)+` ++
    `lte(pow((X-390)/210,2)+pow((Y-520)/170,2),1)+` ++
    `lte(pow((X-890)/210,2)+pow((Y-515)/170,2),1)+` ++
    `lte(pow((X-610)/250,2)+pow((Y-345)/145,2),1),0)`

  B.ffmpeg([
    "-y", "-v", "error", "-i", groundedSource, "-i", cleanBackground,
    "-loop", "1", "-framerate", "24", "-i", acceptedPocket,
    "-f", "lavfi", "-i",
    `nullsrc=s=1300x850:r=24:d=6,geq=lum='${pocketMask}',gblur=sigma=4`,
    "-f", "lavfi", "-i", "nullsrc=s=1280x720:r=24:d=6,format=rgba",
    "-filter_complex",
    `[0:v]trim=start=2.3:end=4.7,setpts=PTS-STARTPTS,` ++
    `scale=1280:720,fps=24,settb=AVTB[grounded];` ++
    `[1:v]trim=start=5.5:end=9.9,setpts=PTS-STARTPTS,` ++
    `scale=1280:720,fps=24,settb=AVTB[clean];` ++
    `[grounded][clean]xfade=transition=fade:duration=0.8:offset=1.6[base];` ++
    `[2:v]crop=1300:850:x=800:y=450,format=rgba[pocketrgb];` ++
    `[pocketrgb][3:v]alphamerge,scale=700:458,` ++
    `fade=t=in:st=1.75:d=0.6:alpha=1[pocket];` ++
    `[4:v]geq=r='222':g='218':b='240':a='(${mistOpacity})*${mistShape}',` ++
    `gblur=sigma=8[mist];` ++
    `[base][pocket]overlay=x='280+4*sin(t*1.1)+if(lt(t,2.4),0,45*(t-2.4))':` ++
    `y='if(lt(t,2.4),270,270-50*(t-2.4))':enable='gte(t,1.75)'[swap];` ++
    `[swap][mist]overlay=0:0,eq=saturation=.98:contrast=1.01,format=yuv420p[out]`,
    "-map", "[out]", "-frames:v", "144", "-r", "24", "-an",
    "-c:v", "libx264", "-preset", "slow", "-crf", "16", "-movflags", "+faststart", output,
  ])

  B.ffmpeg([
    "-y", "-v", "error", "-i", output,
    "-vf", "fps=1,scale=426:240,tile=3x2", "-frames:v", "1", contact,
  ])

  let probe = B.run(
    ~cmd="ffprobe",
    ~args=[
      "-v", "error", "-show_entries",
      "stream=codec_type,codec_name,width,height,r_frame_rate,nb_frames:format=duration",
      "-of", "default=nw=1", output,
    ],
  )
  requireSuccess(~label="B11 repair ffprobe", probe)
  {
    output,
    contact,
    outputSha256: B.sha256File(B.Path(output)),
    contactSha256: B.sha256File(B.Path(contact)),
    probe: probe.stdout,
  }
}
