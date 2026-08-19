/* Deterministic, zero-credit preparation for paid first-pass shots C13-C15.

   This module prepares only local inputs and a proposal. It never uploads,
   quotes, submits, generates provider media, touches the spend ledger or edits
   the shared paid-shot manifests/EDLs. The three frames preserve chronology:

   - C13 is a closer reframe of the accepted B13 ending.
   - C14 uses the accepted broken-gate/goat geography plus the locked physical
     Devanagari BA matte and Kuku's accepted present-day giant appearance.
   - C15 preserves the accepted five-dragon/goat/gate rescue geography before
     Leda initiates the stop.
*/

module B = Cinema_Backends

exception C13C15PrepError(string)

let fail = message => raise(C13C15PrepError(message))

let width = 1280
let height = 720
let hasNativeAudio = false
let providerCalls = 0
let creditsSpent = 0.0

let c13FinalUseSeconds = 8
let c14FinalUseSeconds = 10
let c15FinalUseSeconds = 8
let acquisitionSeconds = 10

let c13DragonCount = 1
let c14DragonCount = 1
let c15DragonCount = 5
let goatCountPerShot = 1
let glyphCountC14 = 1

type buildResult = {
  c13Start: string,
  c14Start: string,
  c15Start: string,
  c13Contact: string,
  c14Contact: string,
  c15Contact: string,
  batchContact: string,
  proposal: string,
  c13StartSha256: string,
  c14StartSha256: string,
  c15StartSha256: string,
  c13PromptSha256: string,
  c14PromptSha256: string,
  c15PromptSha256: string,
  proposalSha256: string,
}

let requireFile = path =>
  if !B.exists(B.Path(path)) {
    fail("required accepted/local input is missing: " ++ path)
  }

let requireSuccess = (~label, result: B.runResult) =>
  if result.code != 0 {
    fail(
      label ++ " failed (exit " ++ Belt.Int.toString(result.code) ++ "): " ++
      Js.String2.slice(result.stderr, ~from=0, ~to_=1800),
    )
  }

let hash = path => B.sha256File(B.Path(path))

let writeProposal = (
  ~path,
  ~b13Source,
  ~a07Source,
  ~a09Source,
  ~kukuSource,
  ~glyphSource,
  ~c13Start,
  ~c14Start,
  ~c15Start,
  ~c13Prompt,
  ~c14Prompt,
  ~c15Prompt,
  ~c13Contact,
  ~c14Contact,
  ~c15Contact,
  ~batchContact,
) => {
  let body = `{
  "project": "kuku-episode-9-finale",
  "version": 1,
  "status": "proposal_ready_zero_credit",
  "scope": ["C13", "C14", "C15"],
  "authority": {
    "providerCallsMade": 0,
    "creditsSpent": 0,
    "liveQuoteObtained": false,
    "submissionAuthorizedByThisProposal": false,
    "sharedPaidShotManifestEdited": false,
    "edlEdited": false,
    "spendLedgerEdited": false
  },
  "bindingSources": [
    "../../../2026-08-11_EP9_ba_bada_SPEC_SCREENPLAY.md",
    "../EP9_FINALE_SHOOTING_SCRIPT.md",
    "ep9_finale_route.v2.json",
    "ep9_finale_paid_shots.v1.json"
  ],
  "shots": [
    {
      "id": "C13",
      "storyTime": "8:53-9:01",
      "modelFromRouteV2": "kling2_6",
      "acquisitionSecondsFromRouteV2": 10,
      "finalUseSeconds": 8,
      "status": "inputs_ready_proposal_only",
      "hardBlocker": null,
      "startFrame": "../start_frames/C13.png",
      "startFrameSha256": "${hash(c13Start)}",
      "promptFile": "../prompts/C13.txt",
      "promptSha256": "${hash(c13Prompt)}",
      "chronology": "Exact accepted B13 ending, reframed closer; goat remains inside the same airborne cloud pocket and Furia remains the only dragon.",
      "localPostDependency": "Keep cloud rotation/deformation separable from Furia performance; do not accept a clip that lands Furia on the cloud.",
      "provenance": [
        {"path": "../clips/B13.mp4", "sha256": "${hash(b13Source)}", "use": "accepted preceding-shot final state"}
      ],
      "qaContact": "../qa/C13_input_start_contact.png",
      "qaContactSha256": "${hash(c13Contact)}"
    },
    {
      "id": "C14",
      "storyTime": "9:01-9:11",
      "modelFromRouteV2": "kling2_6",
      "acquisitionSecondsFromRouteV2": 10,
      "finalUseSeconds": 10,
      "status": "inputs_ready_proposal_only",
      "hardBlocker": null,
      "startFrame": "../start_frames/C14.png",
      "startFrameSha256": "${hash(c14Start)}",
      "promptFile": "../prompts/C14.txt",
      "promptSha256": "${hash(c14Prompt)}",
      "chronology": "The same physical BA created in Scene 4 is grounded below the still-broken gate; the goat remains inside the cloud and Kuku approaches alone.",
      "localPostDependency": "The exact BA front shape is a locked local matte; preserve it if provider motion deforms the glyph.",
      "provenance": [
        {"path": "../references/A07_clean_delogo.png", "sha256": "${hash(a07Source)}", "use": "accepted broken-gate/cloud/goat geography"},
        {"path": "../local/b14_b15/instances/kuku_1.png", "sha256": "${hash(kukuSource)}", "use": "accepted present-day giant Kuku cutout"},
        {"path": "../local/b14_b15/rescue_b_transport_rgba.png", "sha256": "${hash(glyphSource)}", "use": "locked single physical Devanagari BA matte"}
      ],
      "qaContact": "../qa/C14_input_start_contact.png",
      "qaContactSha256": "${hash(c14Contact)}"
    },
    {
      "id": "C15",
      "storyTime": "9:35-9:43",
      "modelFromRouteV2": "kling2_6",
      "acquisitionSecondsFromRouteV2": 10,
      "finalUseSeconds": 8,
      "status": "inputs_ready_proposal_only",
      "hardBlocker": null,
      "startFrame": "../start_frames/C15.png",
      "startFrameSha256": "${hash(c15Start)}",
      "promptFile": "../prompts/C15.txt",
      "promptSha256": "${hash(c15Prompt)}",
      "chronology": "Accepted rescue geography before the teamwork solution: exactly five giant dragons, one broken gate and one goat inside one cloud pocket; no BA has entered the aerial rescue.",
      "agencyGuard": "Pale-lavender Leda at upper right is the sole initiator and must cross into the shared eye-line before any other dragon reacts.",
      "provenance": [
        {"path": "../references/A09_attempt2.png", "sha256": "${hash(a09Source)}", "use": "accepted five-dragon/goat/gate rescue geography"}
      ],
      "qaContact": "../qa/C15_input_start_contact.png",
      "qaContactSha256": "${hash(c15Contact)}"
    }
  ],
  "batchQaContact": "../qa/C13_C15_start_frames_contact.png",
  "batchQaContactSha256": "${hash(batchContact)}",
  "nextAuthorityStep": "Orchestrator may inspect this proposal, patch shared state separately, run the repository submission gate, obtain one exact live quote per shot and request a fresh one-use authorization before any provider call."
}
`
  B.writeText(B.Path(path), body)
}

let build = (~root): buildResult => {
  let prompts = root ++ "/prompts"
  let starts = root ++ "/start_frames"
  let qa = root ++ "/qa"
  let manifests = root ++ "/manifests"
  let b13Source = root ++ "/clips/B13.mp4"
  let a07Source = root ++ "/references/A07_clean_delogo.png"
  let a09Source = root ++ "/references/A09_attempt2.png"
  let kukuSource = root ++ "/local/b14_b15/instances/kuku_1.png"
  let glyphSource = root ++ "/local/b14_b15/rescue_b_transport_rgba.png"
  let c13Prompt = prompts ++ "/C13.txt"
  let c14Prompt = prompts ++ "/C14.txt"
  let c15Prompt = prompts ++ "/C15.txt"
  let c13Start = starts ++ "/C13.png"
  let c14Start = starts ++ "/C14.png"
  let c15Start = starts ++ "/C15.png"
  let c13Contact = qa ++ "/C13_input_start_contact.png"
  let c14Contact = qa ++ "/C14_input_start_contact.png"
  let c15Contact = qa ++ "/C15_input_start_contact.png"
  let batchContact = qa ++ "/C13_C15_start_frames_contact.png"
  let proposal = manifests ++ "/ep9_finale_character_batch_c13_c15.proposal.v1.json"
  let c13Full = root ++ "/local/c13_c15/c13_b13_final_full.png"

  [
    b13Source,
    a07Source,
    a09Source,
    kukuSource,
    glyphSource,
    c13Prompt,
    c14Prompt,
    c15Prompt,
  ]->Belt.Array.forEach(requireFile)

  B.ensureDirPath(B.Path(starts))
  B.ensureDirPath(B.Path(qa))
  B.ensureDirPath(B.Path(manifests))
  B.ensureDirPath(B.Path(root ++ "/local/c13_c15"))

  /* Exact last clean accepted B13 state, then a closer 16:9 reframe. */
  let c13Extract = B.run(
    ~cmd="ffmpeg",
    ~args=[
      "-y",
      "-v",
      "error",
      "-sseof",
      "-0.05",
      "-i",
      b13Source,
      "-frames:v",
      "1",
      c13Full,
    ],
  )
  requireSuccess(~label="C13 accepted-tail extraction", c13Extract)
  let c13Build = B.run(
    ~cmd="ffmpeg",
    ~args=[
      "-y",
      "-v",
      "error",
      "-i",
      c13Full,
      "-vf",
      "crop=1024:576:260:45,scale=1280:720:flags=lanczos,setsar=1",
      "-frames:v",
      "1",
      c13Start,
    ],
  )
  requireSuccess(~label="C13 start-frame build", c13Build)

  /* Kuku begins behind the exact locked BA matte, with his paws approaching
     its lower-left outer edge. The goat remains in the established pocket. */
  let c14Build = B.run(
    ~cmd="ffmpeg",
    ~args=[
      "-y",
      "-v",
      "error",
      "-i",
      a07Source,
      "-i",
      glyphSource,
      "-i",
      kukuSource,
      "-filter_complex",
      "[0:v]scale=1280:720:flags=lanczos,setsar=1[base];[1:v]scale=365:430:flags=lanczos,format=rgba[glyph];[2:v]scale=410:299:flags=lanczos,format=rgba[kuku];[base][kuku]overlay=260:365[b1];[b1][glyph]overlay=530:270[b2];[b2]format=rgb24[out]",
      "-map",
      "[out]",
      "-frames:v",
      "1",
      c14Start,
    ],
  )
  requireSuccess(~label="C14 start-frame build", c14Build)

  /* A09 already contains the exact pre-solution five-dragon geography. */
  let c15Build = B.run(
    ~cmd="ffmpeg",
    ~args=[
      "-y",
      "-v",
      "error",
      "-i",
      a09Source,
      "-vf",
      "scale=1280:720:flags=lanczos,setsar=1",
      "-frames:v",
      "1",
      c15Start,
    ],
  )
  requireSuccess(~label="C15 start-frame build", c15Build)

  let c13Qa = B.run(
    ~cmd="ffmpeg",
    ~args=[
      "-y",
      "-v",
      "error",
      "-i",
      c13Full,
      "-i",
      c13Start,
      "-filter_complex",
      "[0:v]scale=640:360:flags=lanczos[a];[1:v]scale=640:360:flags=lanczos[b];[a][b]hstack=inputs=2[out]",
      "-map",
      "[out]",
      "-frames:v",
      "1",
      c13Contact,
    ],
  )
  requireSuccess(~label="C13 QA contact", c13Qa)

  let c14Qa = B.run(
    ~cmd="ffmpeg",
    ~args=[
      "-y",
      "-v",
      "error",
      "-i",
      a07Source,
      "-i",
      c14Start,
      "-filter_complex",
      "[0:v]scale=640:360:flags=lanczos[a];[1:v]scale=640:360:flags=lanczos[b];[a][b]hstack=inputs=2[out]",
      "-map",
      "[out]",
      "-frames:v",
      "1",
      c14Contact,
    ],
  )
  requireSuccess(~label="C14 QA contact", c14Qa)

  let c15Qa = B.run(
    ~cmd="ffmpeg",
    ~args=[
      "-y",
      "-v",
      "error",
      "-i",
      a09Source,
      "-i",
      c15Start,
      "-filter_complex",
      "[0:v]scale=640:360:flags=lanczos[a];[1:v]scale=640:360:flags=lanczos[b];[a][b]hstack=inputs=2[out]",
      "-map",
      "[out]",
      "-frames:v",
      "1",
      c15Contact,
    ],
  )
  requireSuccess(~label="C15 QA contact", c15Qa)

  let batchQa = B.run(
    ~cmd="ffmpeg",
    ~args=[
      "-y",
      "-v",
      "error",
      "-i",
      c13Start,
      "-i",
      c14Start,
      "-i",
      c15Start,
      "-filter_complex",
      "[0:v]scale=640:360:flags=lanczos[a];[1:v]scale=640:360:flags=lanczos[b];[2:v]scale=640:360:flags=lanczos[c];[a][b][c]hstack=inputs=3[out]",
      "-map",
      "[out]",
      "-frames:v",
      "1",
      batchContact,
    ],
  )
  requireSuccess(~label="C13-C15 batch QA contact", batchQa)

  writeProposal(
    ~path=proposal,
    ~b13Source,
    ~a07Source,
    ~a09Source,
    ~kukuSource,
    ~glyphSource,
    ~c13Start,
    ~c14Start,
    ~c15Start,
    ~c13Prompt,
    ~c14Prompt,
    ~c15Prompt,
    ~c13Contact,
    ~c14Contact,
    ~c15Contact,
    ~batchContact,
  )

  {
    c13Start,
    c14Start,
    c15Start,
    c13Contact,
    c14Contact,
    c15Contact,
    batchContact,
    proposal,
    c13StartSha256: hash(c13Start),
    c14StartSha256: hash(c14Start),
    c15StartSha256: hash(c15Start),
    c13PromptSha256: hash(c13Prompt),
    c14PromptSha256: hash(c14Prompt),
    c15PromptSha256: hash(c15Prompt),
    proposalSha256: hash(proposal),
  }
}
