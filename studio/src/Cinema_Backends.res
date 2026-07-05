/* See Cinema_Backends.resi for the contract. This is the one place the process
   touches the outside world: child_process (ffmpeg), fetch (Replicate +
   ElevenLabs), fs, and Buffer for binary. Bindings follow Session.res's style —
   real @module/@val/@send/@get externals, no escape hatches. */

@unboxed type path = Path(string)
@unboxed type prompt = Prompt(string)
@unboxed type voiceId = VoiceId(string)
@unboxed type seconds = Seconds(float)
@unboxed type millis = Millis(int)
@unboxed type text = Text(string)

exception BackendError(string)

/* ---- Node Buffer: opaque binary. We only ever build one (from disk or an
   ArrayBuffer) and read it back (write to disk / base64). ----------------- */
type buffer
type blob = Blob(buffer)
@val @scope("Buffer") external bufferFrom: Js.TypedArray2.ArrayBuffer.t => buffer = "from"
@val @scope("Buffer") external bufferFromB64: (string, string) => buffer = "from"
@send external toStringEnc: (buffer, string) => string = "toString"

/* ---- child_process: synchronous ffmpeg, the way Session binds child_process. */
/* spawnSync returns a typed result with BOTH streams + the exit status, so we
   never steer on exceptions: ffmpeg's progress/errors (always on stderr) are in
   hand whether it exits 0 (encode OK) or nonzero (`-f null -`, or a real fault).
   This mirrors the Python, which reads p.stderr regardless of the return code. */
type spawnOpts = {encoding: string, maxBuffer: int}
type spawnResult = {
  status: Js.Nullable.t<int>,
  stdout: Js.Nullable.t<string>,
  stderr: Js.Nullable.t<string>,
}
@module("child_process")
external spawnSync: (string, array<string>, spawnOpts) => spawnResult = "spawnSync"

let ffmpegCapture = (args: array<string>): spawnResult =>
  spawnSync("ffmpeg", args, {encoding: "utf8", maxBuffer: 67108864})

let orEmpty = (n: Js.Nullable.t<string>): string => Js.Nullable.toOption(n)->Belt.Option.getWithDefault("")

/* ---- fs ------------------------------------------------------------------ */
@module("fs") external existsSync: string => bool = "existsSync"
@module("fs") external readFileBuf: string => buffer = "readFileSync"
@module("fs") external readFileText: (string, string) => string = "readFileSync"
@module("fs") external writeFileBuf: (string, buffer) => unit = "writeFileSync"
@module("fs") external writeFileText: (string, string) => unit = "writeFileSync"
type mkdirOpts = {recursive: bool}
@module("fs") external mkdirSync: (string, mkdirOpts) => unit = "mkdirSync"
@module("fs") external mkdtempSync: string => string = "mkdtempSync"
type stats = {size: float}
@module("fs") external statSync: string => stats = "statSync"

/* ---- path / os ----------------------------------------------------------- */
@module("path") external dirname: string => string = "dirname"
@module("path") external resolvePath: string => string = "resolve"
@module("os") external tmpdir: unit => string = "tmpdir"
@val @scope("process") external cwd: unit => string = "cwd"

/* ---- the global fetch (Node >= 18) --------------------------------------- */
type response
@val external fetch: (string, 'opts) => promise<response> = "fetch"
@get external status: response => int = "status"
@get external ok: response => bool = "ok"
@send external arrayBuffer: response => promise<Js.TypedArray2.ArrayBuffer.t> = "arrayBuffer"
@send external textBody: response => promise<string> = "text"
@send external jsonBody: response => promise<Js.Json.t> = "json"

/* ---- timers (poll backoff) ----------------------------------------------- */
@val external setTimeout: (unit => unit, int) => unit = "setTimeout"
let sleep = (ms: int): promise<unit> =>
  Js.Promise.make((~resolve, ~reject as _) => setTimeout(() => resolve(. ()), ms))

/* ---- pinned model identities (the only place they live) ------------------ */
let imgPro = "google/nano-banana-pro"
let imgFast = "google/nano-banana"
let imgGpt2 = "openai/gpt-image-2"
let seedance = "a5fd550893da3b6f67997812759065652454ddaca10e96b83b59cbae1814cb36"

/* ---- keys: ONE gitignored .env, parsed once ------------------------------ */
let envFile = (): option<string> => {
  let here = cwd()
  [here ++ "/.env", here ++ "/../.env", "/Users/dusty/dev/brehon-law/.env"]->Belt.Array.getBy(
    existsSync,
  )
}

let envCache: ref<option<Js.Dict.t<string>>> = ref(None)

let loadEnv = (): Js.Dict.t<string> =>
  switch envCache.contents {
  | Some(d) => d
  | None =>
    let d = Js.Dict.empty()
    switch envFile() {
    | Some(p) =>
      readFileText(p, "utf8")
      ->Js.String2.split("\n")
      ->Belt.Array.forEach(line => {
        let t = Js.String2.trim(line)
        if t != "" && !Js.String2.startsWith(t, "#") {
          switch Js.String2.indexOf(t, "=") {
          | -1 => ()
          | i =>
            let k = Js.String2.trim(Js.String2.slice(t, ~from=0, ~to_=i))
            let v = Js.String2.trim(Js.String2.sliceToEnd(t, ~from=i + 1))
            Js.Dict.set(d, k, v)
          }
        }
      })
    | None => ()
    }
    envCache := Some(d)
    d
  }

/* read a key by its .env NAME (e.g. "REPLICATE_API_KEY"). */
let key = (name: string): string =>
  switch Js.Dict.get(loadEnv(), name) {
  | Some(v) if v != "" => v
  | _ => raise(BackendError("missing " ++ name ++ " in .env (repo-root /Users/dusty/dev/brehon-law/.env)"))
  }

/* ---- filesystem surface -------------------------------------------------- */
let exists = (Path(p)): bool => existsSync(p)

let ensureDir = (filePath: string): unit => {
  let dir = dirname(filePath)
  if dir != "" && !existsSync(dir) {
    mkdirSync(dir, {recursive: true})
  }
}

let writeBytes = (Path(p), Blob(b)): path => {
  ensureDir(p)
  writeFileBuf(p, b)
  Path(p)
}
let readText = (Path(p)): string => readFileText(p, "utf8")
let writeText = (Path(p), s: string): unit => {
  ensureDir(p)
  writeFileText(p, s)
}

/* a fresh scratch directory (for the assembler's intermediate clips). */
let tempDir = (prefix: string): path => Path(mkdtempSync(tmpdir() ++ "/" ++ prefix))
let fileSizeMb = (Path(p)): float => statSync(p).size /. 1.0e6

/* a data URI for a reference image, read straight off disk and base64'd. */
let dataUri = (Path(p)): string => {
  let lo = Js.String2.toLowerCase(p)
  let mime = if Js.String2.endsWith(lo, ".png") {
    "image/png"
  } else if Js.String2.endsWith(lo, ".mp3") {
    "audio/mpeg"
  } else if Js.String2.endsWith(lo, ".wav") {
    "audio/wav"
  } else if Js.String2.endsWith(lo, ".mp4") {
    "video/mp4"
  } else {
    "image/jpeg"
  }
  "data:" ++ mime ++ ";base64," ++ toStringEnc(readFileBuf(p), "base64")
}

/* ---- ffmpeg -------------------------------------------------------------- */
/* A real encode must exit 0; any nonzero status is a failure we surface with the
   stderr tail. (durationSec below uses -f null, which DOES exit nonzero by
   design, so it has its own reader and does not go through here.) */
let ffmpeg = (args: array<string>): unit => {
  let r = ffmpegCapture(args)
  switch Js.Nullable.toOption(r.status) {
  | Some(0) => ()
  | _ => {
      let s = orEmpty(r.stderr)
      let tail = Js.String2.sliceToEnd(s, ~from=max(0, Js.String2.length(s) - 400))
      raise(BackendError("ffmpeg failed: " ++ tail))
    }
  }
}

/* pango-view: render Pango markup to a (content-sized) PNG. This Mac's ffmpeg has
   no text filter, so on-screen text is rendered here and overlaid by ffmpeg. */
let pango = (~markup: string, ~width: int, ~background: string, ~out: path): path => {
  let Path(o) = out
  let r = spawnSync(
    "pango-view",
    [
      "-q",
      "--markup",
      "--align=center",
      "--background=" ++ background,
      "--width=" ++ Belt.Int.toString(width),
      "--margin=90",
      "-o",
      o,
      "-t",
      markup,
    ],
    {encoding: "utf8", maxBuffer: 67108864},
  )
  switch Js.Nullable.toOption(r.status) {
  | Some(0) => out
  | _ => raise(BackendError("pango-view failed: " ++ orEmpty(r.stderr)))
  }
}

/* exact decoded duration: ffmpeg -i FILE -f null - ; parse the last
   time=HH:MM:SS.ss off stderr (ffmpeg exits nonzero on a null muxer, so we read
   stderr unconditionally rather than steering on the exit code). */
let parseDuration = (stderr: string): seconds => {
  let re = %re("/time=(\d+):(\d+):(\d+\.\d+)/g")
  let last = ref(None)
  let rec scan = () =>
    switch Js.Re.exec_(re, stderr) {
    | Some(m) => {
        last := Some(m)
        scan()
      }
    | None => ()
    }
  scan()
  switch last.contents {
  | None => raise(BackendError("could not read duration from ffmpeg output"))
  | Some(m) => {
      let cap = i => Js.Nullable.toOption(Js.Re.captures(m)[i])->Belt.Option.getWithDefault("0")
      let h = Belt.Float.fromString(cap(1))->Belt.Option.getWithDefault(0.0)
      let mm = Belt.Float.fromString(cap(2))->Belt.Option.getWithDefault(0.0)
      let s = Belt.Float.fromString(cap(3))->Belt.Option.getWithDefault(0.0)
      Seconds(h *. 3600.0 +. mm *. 60.0 +. s)
    }
  }
}

let durationSec = (Path(p)): seconds => {
  let r = ffmpegCapture(["-nostdin", "-i", p, "-f", "null", "-"])
  /* ffmpeg prints the running time= to stderr; the last one is the full length. */
  parseDuration(orEmpty(r.stderr) ++ orEmpty(r.stdout))
}

let silence = (Millis(ms), Path(cacheDir)): path => {
  let out = cacheDir ++ "/silence_" ++ Belt.Int.toString(ms) ++ ".mp3"
  if !existsSync(out) {
    ensureDir(out)
    let secs = Js.Float.toFixedWithPrecision(Belt.Int.toFloat(ms) /. 1000.0, ~digits=3)
    ffmpeg([
      "-nostdin", "-loglevel", "error", "-y", "-f", "lavfi",
      "-i", "anullsrc=r=44100:cl=mono", "-t", secs,
      "-codec:a", "libmp3lame", "-b:a", "128k", out,
    ])
  }
  Path(out)
}

let concatAudio = (files: array<path>, Path(out)): path => {
  let lst = out ++ ".concat.txt"
  let body = Js.Array2.joinWith(
    Belt.Array.map(files, (Path(f)) => "file '" ++ resolvePath(f) ++ "'"),
    "\n",
  )
  ensureDir(out)
  writeFileText(lst, body ++ "\n")
  ffmpeg([
    "-nostdin", "-loglevel", "error", "-y", "-f", "concat",
    "-safe", "0", "-i", lst, "-codec:a", "libmp3lame", "-b:a", "96k", "-ac", "1", out,
  ])
  Path(out)
}

/* ---- HTTP plumbing ------------------------------------------------------- */
let headerObj = (pairs: array<(string, string)>): Js.Json.t => {
  let d = Js.Dict.empty()
  Belt.Array.forEach(pairs, ((k, v)) => Js.Dict.set(d, k, Js.Json.string(v)))
  Js.Json.object_(d)
}

let postOpts = (~headers: array<(string, string)>, ~body: Js.Json.t) => {
  let d = Js.Dict.empty()
  Js.Dict.set(d, "method", Js.Json.string("POST"))
  Js.Dict.set(d, "headers", headerObj(headers))
  Js.Dict.set(d, "body", Js.Json.string(Js.Json.stringify(body)))
  Js.Json.object_(d)
}
let getOpts = (~headers: array<(string, string)>) => {
  let d = Js.Dict.empty()
  Js.Dict.set(d, "method", Js.Json.string("GET"))
  Js.Dict.set(d, "headers", headerObj(headers))
  Js.Json.object_(d)
}

/* fetch a binary body off a URL -> bytes. */
let getBytes = async (url: string): blob => {
  let resp = await fetch(url, getOpts(~headers=[]))
  if !ok(resp) {
    raise(BackendError("download HTTP " ++ Belt.Int.toString(status(resp))))
  }
  let ab = await arrayBuffer(resp)
  Blob(bufferFrom(ab))
}

/* json helpers over a decoded body. */
let fld = (j: Js.Json.t, k: string): option<Js.Json.t> =>
  j->Js.Json.decodeObject->Belt.Option.flatMap(o => Js.Dict.get(o, k))
let asStr = (o: option<Js.Json.t>): option<string> => o->Belt.Option.flatMap(Js.Json.decodeString)

/* The Replicate output can be a bare URL string OR an array whose first element
   is the URL. One sum type, exhaustively handled — no "isinstance" ladder. */
let outputUrl = (out: option<Js.Json.t>): string =>
  switch out {
  | None => raise(BackendError("replicate: no output"))
  | Some(j) =>
    switch Js.Json.decodeString(j) {
    | Some(u) => u
    | None =>
      switch Js.Json.decodeArray(j) {
      | Some(arr) =>
        switch Belt.Array.get(arr, 0)->Belt.Option.flatMap(Js.Json.decodeString) {
        | Some(u) => u
        | None => raise(BackendError("replicate: output array had no url"))
        }
      | None =>
        /* object form: {"video": url} */
        switch fld(j, "video")->asStr {
        | Some(u) => u
        | None => raise(BackendError("replicate: unrecognized output shape"))
        }
      }
    }
  }

/* Poll a Replicate prediction until it leaves starting/processing. */
let rec poll = async (token: string, pred: Js.Json.t): Js.Json.t => {
  let st = fld(pred, "status")->asStr->Belt.Option.getWithDefault("")
  if st == "starting" || st == "processing" {
    let getUrl =
      fld(pred, "urls")
      ->Belt.Option.flatMap(u => fld(u, "get"))
      ->asStr
      ->Belt.Option.getWithDefault("")
    await sleep(4000)
    let next = try {
      let resp = await fetch(getUrl, getOpts(~headers=[("Authorization", "Bearer " ++ token)]))
      await jsonBody(resp)
    } catch {
    | _ => pred /* transient poll blip (502/network) — keep the old status, poll again, don't crash a long render */
    }
    await poll(token, next)
  } else {
    pred
  }
}

/* ---- Replicate image ----------------------------------------------------- */
let imageInputJson = (~prompt: string, ~refs: array<path>): Js.Json.t => {
  let input = Js.Dict.empty()
  Js.Dict.set(input, "prompt", Js.Json.string(prompt))
  Js.Dict.set(input, "aspect_ratio", Js.Json.string("16:9"))
  Js.Dict.set(input, "output_format", Js.Json.string("png"))
  if Array.length(refs) > 0 {
    Js.Dict.set(
      input,
      "image_input",
      Js.Json.array(Belt.Array.map(refs, r => Js.Json.string(dataUri(r)))),
    )
  }
  let body = Js.Dict.empty()
  Js.Dict.set(body, "input", Js.Json.object_(input))
  Js.Json.object_(body)
}

/* one attempt at the models/<slug>/predictions endpoint with Prefer: wait. */
let imageAttempt = async (~token: string, ~slug: string, ~body: Js.Json.t): option<string> => {
  let resp = await fetch(
    "https://api.replicate.com/v1/models/" ++ slug ++ "/predictions",
    postOpts(
      ~headers=[
        ("Authorization", "Bearer " ++ token),
        ("Content-Type", "application/json"),
        ("Prefer", "wait"),
      ],
      ~body,
    ),
  )
  if status(resp) == 429 {
    None /* caller backs off */
  } else if !ok(resp) {
    let t = await textBody(resp)
    raise(BackendError("image HTTP " ++ Belt.Int.toString(status(resp)) ++ ": " ++ Js.String2.slice(t, ~from=0, ~to_=200)))
  } else {
    let pred0 = await jsonBody(resp)
    let st0 = fld(pred0, "status")->asStr->Belt.Option.getWithDefault("")
    let pred = st0 == "succeeded" ? pred0 : await poll(token, pred0)
    switch fld(pred, "status")->asStr->Belt.Option.getWithDefault("") {
    | ("failed" | "canceled") as st =>
      /* surface the REAL error (e.g. "insufficient credits"), not a parse miss */
      raise(BackendError("prediction " ++ st ++ ": " ++ fld(pred, "error")->asStr->Belt.Option.getWithDefault("(no error)")))
    | _ =>
      switch fld(pred, "output") {
      | Some(_) as o => Some(outputUrl(o))
      | None => None /* transient; caller retries */
      }
    }
  }
}

let rec imageRetry = async (~token, ~slug, ~body, ~attempt: int): string => {
  let outcome = try {
    await imageAttempt(~token, ~slug, ~body)
  } catch {
  | BackendError(m) =>
    /* a thrown error (bad status, transient/moderation) is retryable too */
    Js.log("  image attempt " ++ Belt.Int.toString(attempt) ++ " error: " ++ m)
    attempt >= 5 ? raise(BackendError(m)) : None
  }
  switch outcome {
  | Some(url) => url
  | None =>
    if attempt >= 5 {
      raise(BackendError("image failed after retries"))
    } else {
      await sleep(8000 * (attempt + 1))
      await imageRetry(~token, ~slug, ~body, ~attempt=attempt + 1)
    }
  }
}

let image = async (~prompt: prompt, ~refs: array<path>, ~pro: bool): blob => {
  let Prompt(p) = prompt
  let token = key("REPLICATE_API_KEY")
  let slug = pro ? imgPro : imgFast
  let body = imageInputJson(~prompt=p, ~refs)
  let url = await imageRetry(~token, ~slug, ~body, ~attempt=0)
  await getBytes(url)
}

/* ---- OpenAI gpt-image-2 (relayed through Replicate; bills your OpenAI acct) */
let gptInputJson = (~prompt: string, ~refs: array<path>): Js.Json.t => {
  let input = Js.Dict.empty()
  Js.Dict.set(input, "prompt", Js.Json.string(prompt))
  Js.Dict.set(input, "aspect_ratio", Js.Json.string("16:9"))
  Js.Dict.set(input, "quality", Js.Json.string("high"))
  Js.Dict.set(input, "output_format", Js.Json.string("png"))
  /* no openai_api_key -> Replicate bills it on the Replicate balance (and the
     prediction's cost becomes visible). */
  if Array.length(refs) > 0 {
    Js.Dict.set(
      input,
      "input_images",
      Js.Json.array(Belt.Array.map(refs, r => Js.Json.string(dataUri(r)))),
    )
  }
  let body = Js.Dict.empty()
  Js.Dict.set(body, "input", Js.Json.object_(input))
  Js.Json.object_(body)
}

let imageGpt2 = async (~prompt: prompt, ~refs: array<path>): blob => {
  let Prompt(p) = prompt
  let token = key("REPLICATE_API_KEY")
  let body = gptInputJson(~prompt=p, ~refs)
  let url = await imageRetry(~token, ~slug=imgGpt2, ~body, ~attempt=0)
  await getBytes(url)
}

/* ---- OpenAI Sora 2 Pro image->video (relayed through Replicate) ----------
   First frame = the supplied image; Sora generates its OWN audio from the
   prompt (there is no audio input). landscape; hi => 1080p. */
let videoSora = async (~image: path, ~prompt: prompt, ~seconds: int, ~hi: bool): blob => {
  let Prompt(p) = prompt
  let token = key("REPLICATE_API_KEY")
  let input = Js.Dict.empty()
  Js.Dict.set(input, "prompt", Js.Json.string(p))
  Js.Dict.set(input, "input_reference", Js.Json.string(dataUri(image)))
  Js.Dict.set(input, "seconds", Js.Json.number(Belt.Int.toFloat(seconds)))
  Js.Dict.set(input, "resolution", Js.Json.string(hi ? "high" : "standard"))
  Js.Dict.set(input, "aspect_ratio", Js.Json.string("landscape"))
  /* no openai_api_key -> Replicate bills it; cost shows on the prediction. */
  let body = Js.Dict.empty()
  Js.Dict.set(body, "input", Js.Json.object_(input))
  let url = await imageRetry(~token, ~slug="openai/sora-2-pro", ~body=Js.Json.object_(body), ~attempt=0)
  await getBytes(url)
}

/* ---- Replicate image_to_video (Seedance) --------------------------------- */
let imageToVideo = async (
  ~image: path,
  ~prompt: prompt,
  ~seconds: seconds,
  ~cameraFixed: bool,
  ~lastFrame: option<path>,
): blob => {
  let Prompt(p) = prompt
  let Seconds(secs) = seconds
  let token = key("REPLICATE_API_KEY")
  let input = Js.Dict.empty()
  Js.Dict.set(input, "image", Js.Json.string(dataUri(image)))
  Js.Dict.set(input, "prompt", Js.Json.string(p))
  Js.Dict.set(input, "duration", Js.Json.number(Js.Math.round(secs)))
  Js.Dict.set(input, "resolution", Js.Json.string("1080p"))
  Js.Dict.set(input, "fps", Js.Json.number(24.0))
  Js.Dict.set(input, "camera_fixed", Js.Json.boolean(cameraFixed))
  switch lastFrame {
  | Some(lf) => Js.Dict.set(input, "last_frame_image", Js.Json.string(dataUri(lf)))
  | None => ()
  }
  let body = Js.Dict.empty()
  Js.Dict.set(body, "version", Js.Json.string(seedance))
  Js.Dict.set(body, "input", Js.Json.object_(input))
  let resp = await fetch(
    "https://api.replicate.com/v1/predictions",
    postOpts(
      ~headers=[("Authorization", "Bearer " ++ token), ("Content-Type", "application/json")],
      ~body=Js.Json.object_(body),
    ),
  )
  let pred0 = await jsonBody(resp)
  let pred = await poll(token, pred0)
  let st = fld(pred, "status")->asStr->Belt.Option.getWithDefault("")
  if st != "succeeded" {
    raise(BackendError("seedance " ++ st))
  }
  await getBytes(outputUrl(fld(pred, "output")))
}

/* ---- Replicate TEXT-to-video (seedance-1-pro, image omitted) -------------- */
/* Feed the full filled Seedance template as the prompt; no first frame. */
let videoText = async (~prompt: prompt, ~seconds: int, ~aspect: string): blob => {
  let Prompt(p) = prompt
  let token = key("REPLICATE_API_KEY")
  let input = Js.Dict.empty()
  Js.Dict.set(input, "prompt", Js.Json.string(p))
  Js.Dict.set(input, "duration", Js.Json.number(Belt.Int.toFloat(seconds)))
  Js.Dict.set(input, "resolution", Js.Json.string("1080p"))
  Js.Dict.set(input, "aspect_ratio", Js.Json.string(aspect))
  Js.Dict.set(input, "fps", Js.Json.number(24.0))
  Js.Dict.set(input, "camera_fixed", Js.Json.boolean(false))
  let body = Js.Dict.empty()
  Js.Dict.set(body, "version", Js.Json.string(seedance))
  Js.Dict.set(body, "input", Js.Json.object_(input))
  let resp = await fetch(
    "https://api.replicate.com/v1/predictions",
    postOpts(
      ~headers=[("Authorization", "Bearer " ++ token), ("Content-Type", "application/json")],
      ~body=Js.Json.object_(body),
    ),
  )
  let pred0 = await jsonBody(resp)
  let pred = await poll(token, pred0)
  let st = fld(pred, "status")->asStr->Belt.Option.getWithDefault("")
  if st != "succeeded" {
    raise(BackendError("seedance-text " ++ st))
  }
  await getBytes(outputUrl(fld(pred, "output")))
}

/* ---- fal.ai video (queue API) -------------------------------------------- */
/* Shared plumbing for every fal video model: submit the input to the queue, poll
   status_url until COMPLETED, GET response_url, download video.url. Every fal model
   rides this one path. */
let falAuth = (): array<(string, string)> => [
  ("Authorization", "Key " ++ key("FAL_AI")),
  ("Content-Type", "application/json"),
]

let falVideo = async (~endpoint: string, ~input: Js.Json.t): blob => {
  let auth = falAuth()
  let resp = await fetch("https://queue.fal.run/" ++ endpoint, postOpts(~headers=auth, ~body=input))
  if !ok(resp) {
    let t = await textBody(resp)
    raise(
      BackendError(
        "fal submit HTTP " ++
        Belt.Int.toString(status(resp)) ++ ": " ++ Js.String2.slice(t, ~from=0, ~to_=300),
      ),
    )
  }
  let sub = await jsonBody(resp)
  let statusUrl = fld(sub, "status_url")->asStr->Belt.Option.getWithDefault("")
  let responseUrl = fld(sub, "response_url")->asStr->Belt.Option.getWithDefault("")
  if statusUrl == "" || responseUrl == "" {
    raise(BackendError("fal: submit response missing status_url/response_url"))
  }
  /* poll the queue until COMPLETED (statuses: IN_QUEUE | IN_PROGRESS | COMPLETED) */
  let rec wait = async (): unit => {
    await sleep(5000)
    let st = try {
      let r = await fetch(statusUrl, getOpts(~headers=auth))
      let j = await jsonBody(r)
      fld(j, "status")->asStr->Belt.Option.getWithDefault("")
    } catch {
    | _ => "IN_PROGRESS" /* transient poll blip — treat as still running, poll again */
    }
    switch st {
    | "COMPLETED" => ()
    | "IN_QUEUE" | "IN_PROGRESS" => await wait()
    | other => raise(BackendError("fal status " ++ other))
    }
  }
  await wait()
  let rr = await fetch(responseUrl, getOpts(~headers=auth))
  let out = await jsonBody(rr)
  switch fld(out, "video")->Belt.Option.flatMap(v => fld(v, "url"))->asStr {
  | Some(u) => await getBytes(u)
  | None =>
    /* also accept video as a bare URL string, else surface the raw body */
    switch fld(out, "video")->asStr {
    | Some(u) => await getBytes(u)
    | None =>
      raise(
        BackendError(
          "fal: no video.url in result: " ++ Js.String2.slice(Js.Json.stringify(out), ~from=0, ~to_=600),
        ),
      )
    }
  }
}

/* Seedance 2.0 TEXT-to-video. Feed the full filled template as the prompt.
   resolution = "480p"|"720p"; seconds 4..15; ~audio => the model authors its own
   native ambient/diegetic audio (leave OFF for shots we score ourselves). */
let falSeedance2 = async (
  ~prompt: prompt,
  ~seconds: int,
  ~resolution: string,
  ~aspect: string,
  ~audio: bool,
): blob => {
  let Prompt(p) = prompt
  let input = Js.Dict.empty()
  Js.Dict.set(input, "prompt", Js.Json.string(p))
  Js.Dict.set(input, "resolution", Js.Json.string(resolution))
  Js.Dict.set(input, "duration", Js.Json.string(Belt.Int.toString(seconds)))
  Js.Dict.set(input, "aspect_ratio", Js.Json.string(aspect))
  Js.Dict.set(input, "generate_audio", Js.Json.boolean(audio))
  await falVideo(~endpoint="bytedance/seedance-2.0/text-to-video", ~input=Js.Json.object_(input))
}

/* OmniHuman (ByteDance) — audio-driven talking avatar. A still image + OUR audio
   (< 30s) -> lip-synced video in our own voice. image_url/audio_url take base64
   data URIs, so no upload step. THIS is the talking-shot path (Seedance's own audio
   is soundtrack-only, not lip-sync). */
let falOmnihuman = async (~image: path, ~audio: path): blob => {
  let input = Js.Dict.empty()
  Js.Dict.set(input, "image_url", Js.Json.string(dataUri(image)))
  Js.Dict.set(input, "audio_url", Js.Json.string(dataUri(audio)))
  await falVideo(~endpoint="fal-ai/bytedance/omnihuman", ~input=Js.Json.object_(input))
}

/* ---- ElevenLabs ---------------------------------------------------------- */
let dialogue = async (lines: array<(text, voiceId)>): blob => {
  let k = key("ELEVENLABS_API_KEY")
  let inputs = Belt.Array.map(lines, ((Text(t), VoiceId(v))) => {
    let d = Js.Dict.empty()
    Js.Dict.set(d, "text", Js.Json.string(t))
    Js.Dict.set(d, "voice_id", Js.Json.string(v))
    Js.Json.object_(d)
  })
  let body = Js.Dict.empty()
  Js.Dict.set(body, "inputs", Js.Json.array(inputs))
  Js.Dict.set(body, "model_id", Js.Json.string("eleven_v3"))
  let resp = await fetch(
    "https://api.elevenlabs.io/v1/text-to-dialogue?output_format=mp3_44100_128",
    postOpts(
      ~headers=[("xi-api-key", k), ("Content-Type", "application/json")],
      ~body=Js.Json.object_(body),
    ),
  )
  if !ok(resp) {
    let t = await textBody(resp)
    raise(BackendError("dialogue HTTP " ++ Belt.Int.toString(status(resp)) ++ ": " ++ Js.String2.slice(t, ~from=0, ~to_=200)))
  }
  let ab = await arrayBuffer(resp)
  Blob(bufferFrom(ab))
}

/* text-to-dialogue WITH per-line timing: one continuous performed take of the
   whole run, PLUS each input line's (start,end) seconds in input order (parsed
   from voice_segments). Lets a name+line video land captions exactly on a
   continuous performance. */
let dialogueTimed = async (lines: array<(text, voiceId)>): (blob, array<(float, float)>) => {
  let k = key("ELEVENLABS_API_KEY")
  let inputs = Belt.Array.map(lines, ((Text(t), VoiceId(v))) => {
    let d = Js.Dict.empty()
    Js.Dict.set(d, "text", Js.Json.string(t))
    Js.Dict.set(d, "voice_id", Js.Json.string(v))
    Js.Json.object_(d)
  })
  let body = Js.Dict.empty()
  Js.Dict.set(body, "inputs", Js.Json.array(inputs))
  Js.Dict.set(body, "model_id", Js.Json.string("eleven_v3"))
  let resp = await fetch(
    "https://api.elevenlabs.io/v1/text-to-dialogue/with-timestamps?output_format=mp3_44100_128",
    postOpts(
      ~headers=[("xi-api-key", k), ("Content-Type", "application/json")],
      ~body=Js.Json.object_(body),
    ),
  )
  if !ok(resp) {
    let t = await textBody(resp)
    raise(BackendError("dialogueTimed HTTP " ++ Belt.Int.toString(status(resp)) ++ ": " ++ Js.String2.slice(t, ~from=0, ~to_=200)))
  }
  let j = await jsonBody(resp)
  let obj = Js.Json.decodeObject(j)->Belt.Option.getExn
  let b64 =
    Js.Dict.get(obj, "audio_base64")->Belt.Option.flatMap(Js.Json.decodeString)->Belt.Option.getExn
  let audio = Blob(bufferFromB64(b64, "base64"))
  let n = Belt.Array.length(lines)
  let times = Belt.Array.make(n, (0.0, 0.0))
  let segs =
    Js.Dict.get(obj, "voice_segments")
    ->Belt.Option.flatMap(Js.Json.decodeArray)
    ->Belt.Option.getWithDefault([])
  Belt.Array.forEach(segs, s =>
    switch Js.Json.decodeObject(s) {
    | Some(sd) =>
      let gi =
        Js.Dict.get(sd, "dialogue_input_index")
        ->Belt.Option.flatMap(Js.Json.decodeNumber)
        ->Belt.Option.map(Belt.Float.toInt)
      let gs = Js.Dict.get(sd, "start_time_seconds")->Belt.Option.flatMap(Js.Json.decodeNumber)
      let ge = Js.Dict.get(sd, "end_time_seconds")->Belt.Option.flatMap(Js.Json.decodeNumber)
      switch (gi, gs, ge) {
      | (Some(ix), Some(st), Some(en)) =>
        if ix >= 0 && ix < n {
          Belt.Array.setExn(times, ix, (st, en))
        }
      | _ => ()
      }
    | None => ()
    }
  )
  (audio, times)
}

let tts = async (~text: text, ~voice: voiceId, ~settings: option<Js.Json.t>=?): blob => {
  let Text(t) = text
  let VoiceId(v) = voice
  let k = key("ELEVENLABS_API_KEY")
  let body = Js.Dict.empty()
  Js.Dict.set(body, "text", Js.Json.string(t))
  Js.Dict.set(body, "model_id", Js.Json.string("eleven_v3"))
  switch settings {
  | Some(s) => Js.Dict.set(body, "voice_settings", s)
  | None => ()
  }
  let resp = await fetch(
    "https://api.elevenlabs.io/v1/text-to-speech/" ++ v ++ "?output_format=mp3_44100_128",
    postOpts(
      ~headers=[("xi-api-key", k), ("Content-Type", "application/json")],
      ~body=Js.Json.object_(body),
    ),
  )
  if !ok(resp) {
    let tb = await textBody(resp)
    raise(BackendError("tts HTTP " ++ Belt.Int.toString(status(resp)) ++ ": " ++ Js.String2.slice(tb, ~from=0, ~to_=200)))
  }
  let ab = await arrayBuffer(resp)
  Blob(bufferFrom(ab))
}

let music = async (~prompt: prompt, ~ms: millis, ~instrumental: bool): blob => {
  let Prompt(p) = prompt
  let Millis(len) = ms
  let k = key("ELEVENLABS_API_KEY")
  let body = Js.Dict.empty()
  Js.Dict.set(body, "prompt", Js.Json.string(p))
  Js.Dict.set(body, "music_length_ms", Js.Json.number(Belt.Int.toFloat(len)))
  Js.Dict.set(body, "model_id", Js.Json.string("music_v1"))
  Js.Dict.set(body, "force_instrumental", Js.Json.boolean(instrumental))
  let resp = await fetch(
    "https://api.elevenlabs.io/v1/music?output_format=mp3_44100_128",
    postOpts(
      ~headers=[("xi-api-key", k), ("Content-Type", "application/json")],
      ~body=Js.Json.object_(body),
    ),
  )
  if !ok(resp) {
    let t = await textBody(resp)
    raise(BackendError("music HTTP " ++ Belt.Int.toString(status(resp)) ++ ": " ++ Js.String2.slice(t, ~from=0, ~to_=200)))
  }
  let ab = await arrayBuffer(resp)
  Blob(bufferFrom(ab))
}
