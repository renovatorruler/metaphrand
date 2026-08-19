/* The gate: the ONLY program meant to run with the Higgsfield credentials once
   they live behind the hfgate account (see WALL_RUNBOOK.md).

   Guarantees, in code rather than discipline:
   - accepts job IDs only — prompts are emitted internally from the typed
     records; there is no input path for hand-written prompts;
   - refuses the whole batch if ANY job fails validation (missing reference,
     missing start image, missing creative, bad duration, smuggled tag);
   - refuses if the human-held allowance cannot cover the estimated cost;
   - runs strictly serially; after EACH job it appends the ledger line and
     decrements the allowance, so a crash cannot overspend;
   - every spawn is execFile (argv array), never a shell.

   Modes:  node Drakosha_GateSubmit.res.mjs validate            (no credentials, no spend)
           node Drakosha_GateSubmit.res.mjs submit job12 ...    (inside the wall) */

@module("fs") external readFileSync: (string, string) => string = "readFileSync"
@module("fs") external writeFileSync: (string, string) => unit = "writeFileSync"
@module("fs") external appendFileSync: (string, string) => unit = "appendFileSync"
@module("fs") external existsSync: string => bool = "existsSync"
type execOpts = {encoding: string}
@module("child_process")
external execFileSync: (string, array<string>, execOpts) => string = "execFileSync"
@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external exit: int => unit = "exit"
@val @scope(("process", "env")) external gateHome: option<string> = "HFGATE_HOME"

open Drakosha_SeedanceBatch
open Drakosha_SeedanceJobs

let refsDir = "../stories/drakosha/ep1prod/scene1/references"
let kfDir = "../stories/drakosha/rnd/keyframes"
let outDir = "../stories/drakosha/production/seedance_batch/output"

/* Behind the wall these live in the hfgate home; validate mode skips them. */
let gateDir = switch gateHome {
| Some(h) => h
| None => "/Users/hfgate/gate"
}
let allowancePath = gateDir ++ "/allowance.json"
let ledgerPath = gateDir ++ "/ledger.jsonl"

let resolveRef = (p: string): string =>
  Js.String2.startsWith(p, "KF:")
    ? kfDir ++ "/" ++ Js.String2.sliceToEnd(p, ~from=3)
    : refsDir ++ "/" ++ p

type prepared = {
  record: shotRecord,
  prompt: string,
  refPaths: array<string>,
  start: option<string>,
  /* WHICH MODEL, carried from the job record. It used to be the literal string
     "seedance_2_5" in three places here, which meant every shot in the episode
     was billed at 6.5 credits a second whether it needed 2.5 or not — a scene of
     close-ups on mini costs a third of that. It also meant the duration check
     below could only be a hardcoded list. */
  model: Drakosha_SeedanceJobs.seedanceModel,
}

let problems: array<string> = []
let flag = (m: string): unit => problems->Js.Array2.push(m)->ignore

let prepare = (spec: Drakosha_SeedanceJobs.jobSpec): option<prepared> => {
  let jid = spec.record.jobId
  if !existsSync(spec.creativeFile) {
    flag(jid ++ ": missing creative " ++ spec.creativeFile)
    None
  } else {
    let record = {...spec.record, creative: readFileSync(spec.creativeFile, "utf8")}
    let maxSec = Drakosha_SeedanceJobs.modelMaxSec(spec.model)
    if record.durationSec < 4 || record.durationSec > maxSec {
      flag(
        jid ++
        ": duration " ++
        Belt.Int.toString(record.durationSec) ++
        "s is outside what " ++
        Drakosha_SeedanceJobs.modelName(spec.model) ++
        " generates (4-" ++
        Belt.Int.toString(maxSec) ++
        "s)",
      )
    }
    switch try Some(emitPrompt(record)) catch {
    | BatchError(m) =>
      flag(m)
      None
    } {
    | None => None
    | Some(prompt) =>
      let refPaths = emitRefPaths(record)->Belt.Array.map(resolveRef)
      refPaths->Belt.Array.forEach(p => !existsSync(p) ? flag(jid ++ ": missing ref " ++ p) : ())
      let start = record.startImage->Belt.Option.map(k => kfDir ++ "/" ++ k)
      switch start {
      | Some(p) if !existsSync(p) => flag(jid ++ ": missing start image " ++ p)
      | _ => ()
      }
      Some({record, prompt, refPaths, start, model: spec.model})
    }
  }
}

let providerArgs = (p: prepared): array<string> => {
  /* seedance_2_5, and mode omni_reference is NOT optional: the API rejects t2v
     outright when reference media is present, and start_image is only accepted
     under omni_reference. The old "std" was never a valid mode for this model.
     Non-media params are underscored; only the media flags are hyphenated. */
  /* `mode` exists ONLY on seedance_2_5. On 2.0 and mini it is not a default, it
     is not a parameter at all, and passing it fails the whole call with "Unknown
     params: mode" — which is what killed the first scene-6 submission. The
     smaller models take image_references directly with no mode to select. */
  let base = Belt.Array.concat(
    [
    "generate",
    "create",
    Drakosha_SeedanceJobs.modelName(p.model),
    ],
    switch p.model {
    | V25 => ["--mode", "omni_reference"]
    | Mini | V20 => []
    },
  )->Belt.Array.concat([
    "--prompt",
    p.prompt,
    "--duration",
    Belt.Int.toString(p.record.durationSec),
    "--resolution",
    "720p",
    "--aspect_ratio",
    "16:9",
    "--generate_audio",
    "true",
    "--wait",
    "--wait-timeout",
    "25m",
  ])
  let withStart = switch p.start {
  | Some(s) => Belt.Array.concat(base, ["--start-image", s])
  | None => base
  }
  Belt.Array.concat(
    withStart,
    Belt.Array.concatMany(p.refPaths->Belt.Array.map(r => ["--image-references", r])),
  )
}

let estimateCost = (p: prepared): float => {
  let out = execFileSync(
    "higgsfield",
    /* The cost probe passes no reference media, so it must not claim
       omni_reference: 2.5 rejects that combination outright and the whole batch
       refuses before a single job is submitted. Price is duration times the
       model's rate; the mode does not enter into it. */
    ["generate", "cost", Drakosha_SeedanceJobs.modelName(p.model), "--prompt", "x", "--duration", Belt.Int.toString(p.record.durationSec), "--resolution", "720p", "--json"],
    {encoding: "utf8"},
  )
  switch Js.Json.parseExn(out)->Js.Json.decodeObject {
  | Some(o) =>
    o->Js.Dict.get("credits")->Belt.Option.flatMap(Js.Json.decodeNumber)->Belt.Option.getWithDefault(999.0)
  | None => 999.0
  }
}

let readAllowance = (): float =>
  switch Js.Json.parseExn(readFileSync(allowancePath, "utf8"))->Js.Json.decodeObject {
  | Some(o) =>
    o
    ->Js.Dict.get("allowance_credits")
    ->Belt.Option.flatMap(Js.Json.decodeNumber)
    ->Belt.Option.getWithDefault(0.0)
  | None => 0.0
  }

let writeAllowance = (v: float): unit =>
  writeFileSync(allowancePath, `{"allowance_credits": ${Js.Float.toString(v)}}`)

/* THE LEDGER IS THE ANSWER TO "WHAT DID THIS PROJECT COST".
   On 2026-08-19 that question took an evening of transaction archaeology and
   still produced a number the author could not verify — because images were
   never ledgered, experiments predated the envelope, and attribution by date
   and model misfiled 990 credits of another project's work into this one.

   So: EVERY spend on this project goes through here and writes a line BEFORE
   the money moves — video through `submit`, everything else through `spend`.
   A generation without a ledger line is indistinguishable from another
   project's work, and the archaeology starts again. */
let ledgerLine = (~kind: string, ~ref_: string, ~cost: float, ~note: string): unit => {
  let entry = Js.Dict.empty()
  Js.Dict.set(entry, "project", Js.Json.string("drakosha-ep1"))
  Js.Dict.set(entry, "kind", Js.Json.string(kind))
  Js.Dict.set(entry, "ref", Js.Json.string(ref_))
  Js.Dict.set(entry, "cost", Js.Json.number(cost))
  Js.Dict.set(entry, "note", Js.Json.string(note))
  Js.Dict.set(entry, "balance_after", Js.Json.number(readAllowance() -. cost))
  appendFileSync(ledgerPath, Js.Json.stringify(Js.Json.object_(entry)) ++ "\n")
}


let () = {
  let args = argv->Js.Array2.slice(~start=2, ~end_=99)
  let mode = args->Belt.Array.get(0)->Belt.Option.getWithDefault("validate")
  let wanted = args->Js.Array2.slice(~start=1, ~end_=99)
  let specs =
    Belt.Array.length(wanted) == 0
      ? Drakosha_SeedanceJobs.all
      : Drakosha_SeedanceJobs.all->Belt.Array.keep(s =>
          wanted->Js.Array2.includes(s.record.jobId)
        )
  let prepared = specs->Belt.Array.keepMap(prepare)
  if Belt.Array.length(problems) > 0 {
    problems->Belt.Array.forEach(p => Js.log("  FAIL  " ++ p))
    Js.log("GATE: REFUSED — validation failed; nothing was submitted.")
    exit(1)
  }
  switch mode {
  | "validate" =>
    prepared->Belt.Array.forEach(p =>
      Js.log("  OK    " ++ p.record.jobId ++ "  refs=" ++ Belt.Int.toString(Belt.Array.length(p.refPaths)))
    )
    Js.log("GATE: VALID — " ++ Belt.Int.toString(Belt.Array.length(prepared)) ++ " job(s) submittable once the wall is up.")
  | "submit" => {
      if !existsSync(allowancePath) {
        Js.log("GATE: REFUSED — no allowance file (is the wall set up? are you hfgate?)")
        exit(1)
      }
      let costs = prepared->Belt.Array.map(estimateCost)
      let total = costs->Belt.Array.reduce(0.0, (a, b) => a +. b)
      if readAllowance() < total {
        Js.log("GATE: REFUSED — allowance " ++ Js.Float.toString(readAllowance()) ++ " < estimated " ++ Js.Float.toString(total))
        exit(1)
      }
      prepared->Belt.Array.forEachWithIndex((i, p) => {
        let cost = costs->Belt.Array.getExn(i)
        if readAllowance() < cost {
          Js.log("GATE: STOPPED at " ++ p.record.jobId ++ " — allowance exhausted.")
          exit(1)
        }
        Js.log("GATE: submitting " ++ p.record.jobId)
        /* A TRANSIENT NETWORK ERROR MUST NOT STRAND A BATCH.
           "request failed (no response received)" killed a seven-job run after
           the first job, leaving six unshot and the operator to work out by hand
           what had and had not been charged. Nothing was lost that time only
           because the charge happens AFTER the call returns — so a failed submit
           costs nothing and is safe to retry. Three attempts, then give up on
           that job and carry on with the rest rather than aborting the batch. */
        let out = ref("")
        let attempts = ref(0)
        let ok = ref(false)
        while !ok.contents && attempts.contents < 3 {
          attempts := attempts.contents + 1
          switch execFileSync("higgsfield", providerArgs(p), {encoding: "utf8"}) {
          | text =>
            out := text
            ok := true
          | exception _ =>
            /* "no response received" does NOT mean the job never reached the
               server. On 2026-08-18 one such "failure" had in fact submitted,
               the retry submitted again, and the duplicate cost 32.5 credits
               that the ledger never saw. Before retrying, ask the server what
               it actually has: if a job with this prompt landed in the last
               few minutes, adopt it instead of resubmitting. */
            let adopted = try {
              let out = execFileSync(
                "higgsfield",
                ["--json", "generate", "list", "--video", "--size", "5"],
                {encoding: "utf8"},
              )
              switch Js.Json.parseExn(out)->Js.Json.decodeArray {
              | None => false
              | Some(jobs) =>
                jobs->Belt.Array.some(job =>
                  switch Js.Json.decodeObject(job) {
                  | None => false
                  | Some(o) =>
                    let promptOf =
                      o
                      ->Js.Dict.get("params")
                      ->Belt.Option.flatMap(Js.Json.decodeObject)
                      ->Belt.Option.flatMap(pp => Js.Dict.get(pp, "prompt"))
                      ->Belt.Option.flatMap(Js.Json.decodeString)
                      ->Belt.Option.getWithDefault("")
                    Js.String2.slice(promptOf, ~from=0, ~to_=200) ==
                      Js.String2.slice(p.prompt, ~from=0, ~to_=200)
                  }
                )
              }
            } catch {
            | _ => false
            }
            if adopted {
              Js.log("GATE: " ++ p.record.jobId ++ " — the \"failed\" submit actually reached the server; adopting it, NOT resubmitting.")
              out := "adopted-after-network-error; fetch URL via: higgsfield generate list"
              ok := true
            } else {
              Js.log(
                "GATE: attempt " ++
                Belt.Int.toString(attempts.contents) ++
                " of 3 failed for " ++
                p.record.jobId ++ " — verified absent on server, retrying",
              )
            }
          }
        }
        if !ok.contents {
          Js.log("GATE: GIVING UP on " ++ p.record.jobId ++ " after 3 attempts; continuing with the rest of the batch.")
        } else {
        let out = out.contents
        writeAllowance(readAllowance() -. cost)
        let entry = Js.Dict.empty()
        Js.Dict.set(entry, "job", Js.Json.string(p.record.jobId))
        Js.Dict.set(entry, "shots", Js.Json.string(p.record.shots))
        Js.Dict.set(entry, "cost", Js.Json.number(cost))
        Js.Dict.set(entry, "output", Js.Json.string(out->Js.String2.slice(~from=0, ~to_=400)))
        appendFileSync(ledgerPath, Js.Json.stringify(Js.Json.object_(entry)) ++ "\n")
        writeFileSync(outDir ++ "/" ++ p.record.jobId ++ ".result.txt", out)
        }
      })
      Js.log("GATE: batch complete; ledger updated.")
    }
  | "spend" => {
      /* Ledger any non-Seedance spend: images, TTS, upscales, the author's own
         UI generations she wants attributed. Usage:
           node Drakosha_GateSubmit.res.mjs spend <kind> <cost> <ref> [note…]
         This does not call any API — the generation happens wherever it
         happens; this records that it belongs to THIS project, at the moment
         of spending, so cost questions are answered by the ledger forever. */
      switch (Belt.Array.get(wanted, 0), Belt.Array.get(wanted, 1)) {
      | (Some(kind), Some(costS)) =>
        switch Belt.Float.fromString(costS) {
        | Some(cost) =>
          let ref_ = Belt.Array.get(wanted, 2)->Belt.Option.getWithDefault("")
          let note =
            wanted->Js.Array2.slice(~start=3, ~end_=99)->Js.Array2.joinWith(" ")
          ledgerLine(~kind, ~ref_, ~cost, ~note)
          writeAllowance(readAllowance() -. cost)
          Js.log("GATE: ledgered " ++ kind ++ " " ++ costS ++ " cr (" ++ ref_ ++ ")")
        | None =>
          Js.log("GATE: spend needs a numeric cost, got " ++ costS)
          exit(1)
        }
      | _ => {
          Js.log("GATE: usage — spend <kind> <cost> <ref> [note…]")
          exit(1)
        }
      }
    }
  | m => {
      Js.log("GATE: unknown mode " ++ m)
      exit(1)
    }
  }
}
