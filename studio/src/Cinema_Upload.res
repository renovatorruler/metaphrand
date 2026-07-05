/* See Cinema_Upload.resi for the contract. The OAuth device flow + resumable
   upload, ported from examples/youtube_upload.py. Real Node bindings only
   (fetch, fs, URLSearchParams, Buffer); no escape hatches.

   fetch options are TYPED records (one shape per call), not a Js.Json blob — that
   lets the PUT body be a Buffer (binary) while a form/JSON body is a string, each
   in its own record, with no untyped envelope. */

@unboxed type path = Path(string)
@unboxed type videoTitle = VideoTitle(string)
@unboxed type videoDesc = VideoDesc(string)
@unboxed type userCode = UserCode(string)
@unboxed type verifyUrl = VerifyUrl(string)
@unboxed type deviceCode = DeviceCode(string)
@unboxed type videoId = VideoId(string)
@unboxed type secs = Secs(int)

exception UploadError(string)

type pending = {url: verifyUrl, code: userCode, device: deviceCode, interval: secs, expiresIn: secs}

/* ---- fs / os ------------------------------------------------------------- */
type buffer
@module("fs") external readFileText: (string, string) => string = "readFileSync"
@module("fs") external readFileBuf: string => buffer = "readFileSync"
@module("fs") external writeFileText: (string, string) => unit = "writeFileSync"
@module("fs") external chmodSync: (string, int) => unit = "chmodSync"
@get external bufLength: buffer => int = "length"
@module("os") external homedir: unit => string = "homedir"

/* ---- fetch + form encoding (Node globals) -------------------------------- */
type response
type headersObj
type urlParams
/* the three request envelopes, each fully typed (no untyped options blob). */
type strReq = {method: string, headers: Js.Dict.t<string>, body: string}
type bufReq = {method: string, headers: Js.Dict.t<string>, body: buffer}
@val external fetchStr: (string, strReq) => promise<response> = "fetch"
@val external fetchBuf: (string, bufReq) => promise<response> = "fetch"
@get external status: response => int = "status"
@get external ok: response => bool = "ok"
@get external respHeaders: response => headersObj = "headers"
@send external headerGet: (headersObj, string) => Js.Nullable.t<string> = "get"
@send external jsonBody: response => promise<Js.Json.t> = "json"
@send external textBody: response => promise<string> = "text"
@new external makeParams: unit => urlParams = "URLSearchParams"
@send external paramSet: (urlParams, string, string) => unit = "set"
@send external paramsToString: urlParams => string = "toString"

/* ---- timers -------------------------------------------------------------- */
@val external setTimeout: (unit => unit, int) => unit = "setTimeout"
@val @scope("Date") external now: unit => float = "now"
let sleep = (ms: int): promise<unit> =>
  Js.Promise.make((~resolve, ~reject as _) => setTimeout(() => resolve(. ()), ms))

/* ---- json helpers -------------------------------------------------------- */
let fld = (j, k) => j->Js.Json.decodeObject->Belt.Option.flatMap(o => Js.Dict.get(o, k))
let asStr = o => o->Belt.Option.flatMap(Js.Json.decodeString)
let asNum = o => o->Belt.Option.flatMap(Js.Json.decodeNumber)
let str = Js.Json.string

let dictOf = (pairs: array<(string, string)>): Js.Dict.t<string> => {
  let d = Js.Dict.empty()
  Belt.Array.forEach(pairs, ((k, v)) => Js.Dict.set(d, k, v))
  d
}

/* ---- config files -------------------------------------------------------- */
let oauthPath = homedir() ++ "/.youtube_oauth.json"
let tokensPath = homedir() ++ "/.youtube_tokens.json"
let scope = "https://www.googleapis.com/auth/youtube.upload"

let oauth = (): (string, string) => {
  let j = Js.Json.parseExn(readFileText(oauthPath, "utf8"))
  (
    asStr(fld(j, "client_id"))->Belt.Option.getWithDefault(""),
    asStr(fld(j, "client_secret"))->Belt.Option.getWithDefault(""),
  )
}

/* ---- form POST (the OAuth endpoints want x-www-form-urlencoded) ----------- */
let postForm = async (url: string, fields: array<(string, string)>): Js.Json.t => {
  let params = makeParams()
  Belt.Array.forEach(fields, ((k, v)) => paramSet(params, k, v))
  let resp = await fetchStr(url, {
    method: "POST",
    headers: dictOf([("Content-Type", "application/x-www-form-urlencoded")]),
    body: paramsToString(params),
  })
  /* Google returns the error body as JSON too, so parse regardless of status. */
  await jsonBody(resp)
}

/* ---- auth: device flow --------------------------------------------------- */
let authStart = async (): pending => {
  let (cid, _csec) = oauth()
  let d = await postForm("https://oauth2.googleapis.com/device/code", [("client_id", cid), ("scope", scope)])
  switch asStr(fld(d, "device_code")) {
  | None => raise(UploadError("device/code failed"))
  | Some(device) => {
      let url =
        asStr(fld(d, "verification_url"))
        ->Belt.Option.orElse(asStr(fld(d, "verification_uri")))
        ->Belt.Option.getWithDefault("")
      let code = asStr(fld(d, "user_code"))->Belt.Option.getWithDefault("")
      Js.log("VERIFICATION_URL: " ++ url)
      Js.log("USER_CODE: " ++ code)
      Js.log("(polling for approval — approve on your phone)")
      {
        url: VerifyUrl(url),
        code: UserCode(code),
        device: DeviceCode(device),
        interval: Secs(asNum(fld(d, "interval"))->Belt.Option.getWithDefault(5.0)->Belt.Float.toInt),
        expiresIn: Secs(asNum(fld(d, "expires_in"))->Belt.Option.getWithDefault(1800.0)->Belt.Float.toInt),
      }
    }
  }
}

/* poll until the user approves (or the code expires). On success, cache tokens. */
let rec pollLoop = async (cid: string, csec: string, device: string, interval: int, deadline: float): unit =>
  if now() > deadline {
    raise(UploadError("device code expired before approval"))
  } else {
    await sleep(interval * 1000)
    let t = await postForm("https://oauth2.googleapis.com/token", [
      ("client_id", cid),
      ("client_secret", csec),
      ("device_code", device),
      ("grant_type", "urn:ietf:params:oauth:grant-type:device_code"),
    ])
    switch asStr(fld(t, "access_token")) {
    | Some(_) => {
        writeFileText(tokensPath, Js.Json.stringify(t))
        chmodSync(tokensPath, 0o600)
        Js.log("AUTHORIZED")
      }
    | None =>
      switch asStr(fld(t, "error")) {
      | Some("authorization_pending") => await pollLoop(cid, csec, device, interval, deadline)
      | Some("slow_down") => await pollLoop(cid, csec, device, interval + 5, deadline)
      | Some(e) => raise(UploadError("auth failed: " ++ e))
      | None => raise(UploadError("auth failed: unknown response"))
      }
    }
  }

let authPoll = async (p: pending): unit => {
  let (cid, csec) = oauth()
  let DeviceCode(device) = p.device
  let Secs(interval) = p.interval
  let Secs(expiresIn) = p.expiresIn
  await pollLoop(cid, csec, device, interval, now() +. Belt.Int.toFloat(expiresIn) *. 1000.0)
}

/* ---- refresh the access token ------------------------------------------- */
let accessToken = async (): string => {
  let (cid, csec) = oauth()
  let t = Js.Json.parseExn(readFileText(tokensPath, "utf8"))
  let refresh = asStr(fld(t, "refresh_token"))->Belt.Option.getWithDefault("")
  let r = await postForm("https://oauth2.googleapis.com/token", [
    ("client_id", cid),
    ("client_secret", csec),
    ("refresh_token", refresh),
    ("grant_type", "refresh_token"),
  ])
  switch asStr(fld(r, "access_token")) {
  | Some(tok) => tok
  | None => raise(UploadError("token refresh failed"))
  }
}

/* ---- the resumable upload ----------------------------------------------- */
let initSession = async (~tok: string, ~size: int, ~title: string, ~desc: string): string => {
  let snippet = Js.Dict.empty()
  Js.Dict.set(snippet, "title", str(title))
  Js.Dict.set(snippet, "description", str(desc))
  Js.Dict.set(snippet, "categoryId", str("1"))
  let st = Js.Dict.empty()
  Js.Dict.set(st, "privacyStatus", str("unlisted"))
  Js.Dict.set(st, "selfDeclaredMadeForKids", Js.Json.boolean(false))
  let meta = Js.Dict.empty()
  Js.Dict.set(meta, "snippet", Js.Json.object_(snippet))
  Js.Dict.set(meta, "status", Js.Json.object_(st))

  let resp = await fetchStr(
    "https://www.googleapis.com/upload/youtube/v3/videos?uploadType=resumable&part=snippet,status",
    {
      method: "POST",
      headers: dictOf([
        ("Authorization", "Bearer " ++ tok),
        ("Content-Type", "application/json; charset=UTF-8"),
        ("X-Upload-Content-Length", Belt.Int.toString(size)),
        ("X-Upload-Content-Type", "video/*"),
      ]),
      body: Js.Json.stringify(Js.Json.object_(meta)),
    },
  )
  switch Js.Nullable.toOption(headerGet(respHeaders(resp), "Location")) {
  | Some(loc) => loc
  | None => {
      let t = await textBody(resp)
      raise(UploadError("init session failed: " ++ Js.String2.slice(t, ~from=0, ~to_=200)))
    }
  }
}

let upload = async (~file: path, ~title: videoTitle, ~desc: videoDesc): videoId => {
  let Path(f) = file
  let VideoTitle(t) = title
  let VideoDesc(de) = desc
  let tok = await accessToken()
  let buf = readFileBuf(f)
  let size = bufLength(buf)
  let session = await initSession(~tok, ~size, ~title=t, ~desc=de)
  Js.log("uploading " ++ Belt.Int.toString(size / 1000000) ++ " MB ...")
  let resp = await fetchBuf(session, {
    method: "PUT",
    headers: dictOf([
      ("Authorization", "Bearer " ++ tok),
      ("Content-Type", "video/*"),
      ("Content-Length", Belt.Int.toString(size)),
    ]),
    body: buf,
  })
  if !ok(resp) {
    let tb = await textBody(resp)
    raise(UploadError("upload HTTP " ++ Belt.Int.toString(status(resp)) ++ ": " ++ Js.String2.slice(tb, ~from=0, ~to_=200)))
  }
  let res = await jsonBody(resp)
  switch asStr(fld(res, "id")) {
  | Some(id) => {
      Js.log("VIDEO_ID: " ++ id)
      Js.log("URL: https://youtu.be/" ++ id)
      Js.log("STUDIO: https://studio.youtube.com/video/" ++ id ++ "/edit")
      VideoId(id)
    }
  | None => raise(UploadError("upload succeeded but no video id returned"))
  }
}
