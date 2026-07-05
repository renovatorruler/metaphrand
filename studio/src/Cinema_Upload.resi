/* ============================================================================
   Cinema_Upload — push a finished cut to YouTube as UNLISTED.

   Two phases, the OAuth 2.0 device flow then a resumable upload:
     authStart  -> ask Google for a device + user code (print, return it)
     authPoll   -> poll the token endpoint until the user approves on their phone,
                   then cache the tokens to ~/.youtube_tokens.json
     upload     -> refresh the access token and resumable-PUT the file, unlisted

   Client id/secret live in ~/.youtube_oauth.json; tokens in ~/.youtube_tokens.json.
   This module owns its own HTTP + fs (a distinct external surface from the AI/
   ffmpeg layer in Cinema_Backends), so its bindings sit here.
   ============================================================================ */

@unboxed type path = Path(string)
@unboxed type videoTitle = VideoTitle(string)
@unboxed type videoDesc = VideoDesc(string)
@unboxed type userCode = UserCode(string)
@unboxed type verifyUrl = VerifyUrl(string)
@unboxed type deviceCode = DeviceCode(string)
@unboxed type videoId = VideoId(string)
@unboxed type secs = Secs(int) // a duration in seconds (poll interval / expiry)

exception UploadError(string)

/* what the user must do to authorize: a URL to open + a code to type. The
   deviceCode is carried back into authPoll. */
type pending = {url: verifyUrl, code: userCode, device: deviceCode, interval: secs, expiresIn: secs}

let authStart: unit => promise<pending>
let authPoll: pending => promise<unit>             // blocks until approved; caches tokens
let upload: (~file: path, ~title: videoTitle, ~desc: videoDesc) => promise<videoId>
