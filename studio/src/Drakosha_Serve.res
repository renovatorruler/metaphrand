/* Serve the whole drakosha media tree over the tailnet, read-only.

   WHY THIS EXISTS. The delivery path uploads a file per call and it times out
   above roughly 10MB — the scene 8 assembly failed twice at 11.5MB and once at
   6.6MB. The tree is 3364 images and clips across 5.9GB, including every
   unsuccessful take, and the author wants to browse the lot. Uploading is not a
   route to that; serving is.

   RANGE REQUESTS ARE NOT OPTIONAL. iOS Safari refuses to play a video at all
   unless the server answers byte ranges, and the tailnet here is mostly iPads
   and iPhones. Node's own static helpers do not do this, so it is done by hand.

   BINDS TO THE TAILSCALE ADDRESS ONLY. Not 0.0.0.0 — the tree should not appear
   on cafe wifi because a server was left running. If the tailscale interface is
   not up, this refuses to start rather than falling back to a wider bind. */

type stream
type serverRequest
type serverResponse
type server
type stats

@module("http") external createServer: ((serverRequest, serverResponse) => unit) => server = "createServer"
@send external listen: (server, int, string, unit => unit) => unit = "listen"
@get external reqUrl: serverRequest => string = "url"
@get external reqHeaders: serverRequest => Js.Dict.t<string> = "headers"
@send external writeHead: (serverResponse, int, Js.Dict.t<string>) => unit = "writeHead"
@send external endWith: (serverResponse, string) => unit = "end"
@send external endEmpty: serverResponse => unit = "end"
@send external pipe: (stream, serverResponse) => unit = "pipe"

@module("fs") external existsSync: string => bool = "existsSync"
@module("fs") external readdirSync: string => array<string> = "readdirSync"
@module("fs") external statSync: string => stats = "statSync"
@send external isDirectory: stats => bool = "isDirectory"
@get external statSize: stats => float = "size"
@get external statMtime: stats => float = "mtimeMs"

type readOpts = {start: float, @as("end") end_: float}
@module("fs") external createReadStreamRange: (string, readOpts) => stream = "createReadStream"
@module("fs") external createReadStreamAll: string => stream = "createReadStream"

@val external decodeURIComponent: string => string = "decodeURIComponent"
@val external encodeURIComponent: string => string = "encodeURIComponent"
@val @scope("process") external argv: array<string> = "argv"
@val @scope(("process", "stdout")) external write: string => unit = "write"

let root = "/Users/dusty/dev/metaphrand/stories/drakosha"

let ext = (name: string): string => {
  let i = Js.String2.lastIndexOf(name, ".")
  i < 0 ? "" : Js.String2.toLowerCase(Js.String2.sliceToEnd(name, ~from=i + 1))
}

let contentType = (name: string): string =>
  switch ext(name) {
  | "mp4" => "video/mp4"
  | "mov" => "video/quicktime"
  | "webm" => "video/webm"
  | "png" => "image/png"
  | "jpg" | "jpeg" => "image/jpeg"
  | "gif" => "image/gif"
  | "svg" => "image/svg+xml"
  | "mp3" => "audio/mpeg"
  | "wav" => "audio/wav"
  | "json" => "application/json; charset=utf-8"
  | "html" => "text/html; charset=utf-8"
  | "md" | "txt" | "res" | "resi" | "fountain" => "text/plain; charset=utf-8"
  | _ => "application/octet-stream"
  }

let isVideo = (n: string): bool => switch ext(n) { | "mp4" | "mov" | "webm" => true | _ => false }
let isImage = (n: string): bool => switch ext(n) { | "png" | "jpg" | "jpeg" | "gif" => true | _ => false }
let isAudio = (n: string): bool => switch ext(n) { | "mp3" | "wav" => true | _ => false }

let human = (bytes: float): string =>
  bytes > 1048576.0
    ? Js.Float.toFixedWithPrecision(bytes /. 1048576.0, ~digits=1) ++ " MB"
    : Js.Float.toFixedWithPrecision(bytes /. 1024.0, ~digits=0) ++ " KB"

/* Path traversal guard: the resolved path must still start with root. A request
   for /../../.ssh must not walk out of the tree. */
let safeJoin = (rel: string): option<string> => {
  let cleaned =
    rel
    ->Js.String2.split("/")
    ->Belt.Array.keep(seg => seg != "" && seg != "." && seg != "..")
    ->Js.Array2.joinWith("/")
  let full = cleaned == "" ? root : root ++ "/" ++ cleaned
  Js.String2.startsWith(full, root) ? Some(full) : None
}

let page = (title: string, body: string): string =>
  "<!doctype html><html><head><meta charset='utf-8'>" ++
  "<meta name='viewport' content='width=device-width,initial-scale=1'>" ++
  "<title>" ++ title ++ "</title><style>" ++
  ":root{--bg:#14110f;--fg:#efe7dd;--dim:#9a8d80;--line:#2e2823;--accent:#d9a441}" ++
  "*{box-sizing:border-box}body{margin:0;padding:16px;background:var(--bg);color:var(--fg);" ++
  "font:15px/1.5 -apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif}" ++
  "h1{font-size:17px;font-weight:600;margin:0 0 4px}" ++
  ".crumb{color:var(--dim);font-size:13px;margin-bottom:16px;word-break:break-all}" ++
  ".crumb a{color:var(--accent);text-decoration:none}" ++
  "ul.dirs{list-style:none;margin:0 0 24px;padding:0;display:flex;flex-wrap:wrap;gap:8px}" ++
  "ul.dirs a{display:block;padding:8px 14px;background:#1e1a17;border:1px solid var(--line);" ++
  "border-radius:8px;color:var(--fg);text-decoration:none;font-size:14px}" ++
  ".grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(230px,1fr));gap:14px}" ++
  ".card{background:#1b1815;border:1px solid var(--line);border-radius:10px;overflow:hidden}" ++
  ".card img,.card video{width:100%;display:block;background:#000;aspect-ratio:16/9;object-fit:contain}" ++
  ".meta{padding:8px 10px;font-size:12px;word-break:break-all}" ++
  ".meta a{color:var(--fg);text-decoration:none}" ++
  ".meta span{color:var(--dim);display:block;margin-top:2px}" ++
  ".other{padding:8px 10px;font-size:13px}.other a{color:var(--accent);text-decoration:none}" ++
  "</style></head><body>" ++ body ++ "</body></html>"

let listing = (dir: string, rel: string): string => {
  let entries = readdirSync(dir)->Belt.Array.keep(n => !Js.String2.startsWith(n, "."))
  let dirs = entries->Belt.Array.keep(n => isDirectory(statSync(dir ++ "/" ++ n)))
  let files = entries->Belt.Array.keep(n => !isDirectory(statSync(dir ++ "/" ++ n)))
  /* newest first — the take you just shot is the one you want to see */
  let sorted = files->Belt.SortArray.stableSortBy((a, b) =>
    statMtime(statSync(dir ++ "/" ++ b)) > statMtime(statSync(dir ++ "/" ++ a)) ? 1 : -1
  )
  let base = rel == "" ? "" : "/" ++ rel
  let up =
    rel == ""
      ? ""
      : "<div class='crumb'><a href='" ++
        (switch Js.String2.lastIndexOf(rel, "/") {
        | -1 => "/"
        | i => "/" ++ Js.String2.slice(rel, ~from=0, ~to_=i)
        }) ++ "'>&larr; up</a> &nbsp; /" ++ rel ++ "</div>"
  let dirHtml =
    Belt.Array.length(dirs) == 0
      ? ""
      : "<ul class='dirs'>" ++
        dirs
        ->Belt.SortArray.stableSortBy((a, b) => a < b ? -1 : 1)
        ->Belt.Array.map(d =>
          "<li><a href='" ++ base ++ "/" ++ encodeURIComponent(d) ++ "'>" ++ d ++ "/</a></li>"
        )
        ->Js.Array2.joinWith("") ++ "</ul>"
  let media = sorted->Belt.Array.keep(n => isVideo(n) || isImage(n) || isAudio(n))
  let others = sorted->Belt.Array.keep(n => !(isVideo(n) || isImage(n) || isAudio(n)))
  let cards =
    media
    ->Belt.Array.map(n => {
      let href = base ++ "/" ++ encodeURIComponent(n)
      let sz = human(statSize(statSync(dir ++ "/" ++ n)))
      let preview = if isVideo(n) {
        "<video src='" ++ href ++ "' controls preload='metadata' playsinline></video>"
      } else if isImage(n) {
        "<a href='" ++ href ++ "'><img src='" ++ href ++ "' loading='lazy'></a>"
      } else {
        "<audio src='" ++ href ++ "' controls style='width:100%'></audio>"
      }
      "<div class='card'>" ++ preview ++ "<div class='meta'><a href='" ++ href ++ "'>" ++ n ++
      "</a><span>" ++ sz ++ "</span></div></div>"
    })
    ->Js.Array2.joinWith("")
  let otherHtml =
    Belt.Array.length(others) == 0
      ? ""
      : "<div class='other'>" ++
        others
        ->Belt.Array.map(n =>
          "<a href='" ++ base ++ "/" ++ encodeURIComponent(n) ++ "'>" ++ n ++ "</a>"
        )
        ->Js.Array2.joinWith(" &middot; ") ++ "</div>"
  page(
    rel == "" ? "drakosha" : rel,
    "<h1>" ++ (rel == "" ? "drakosha" : rel) ++ "</h1>" ++ up ++ dirHtml ++
    "<div class='grid'>" ++ cards ++ "</div>" ++ otherHtml,
  )
}

/* Range: bytes=START-[END]. Answering 206 with Content-Range is what lets iOS
   scrub, and what lets it start playback at all. */
let parseRange = (header: string, total: float): option<(float, float)> =>
  if !Js.String2.startsWith(header, "bytes=") {
    None
  } else {
    let spec = Js.String2.sliceToEnd(header, ~from=6)
    switch Js.String2.split(spec, "-") {
    | [s, e] =>
      let start = s == "" ? 0.0 : Belt.Float.fromString(s)->Belt.Option.getWithDefault(0.0)
      let end_ =
        e == "" ? total -. 1.0 : Belt.Float.fromString(e)->Belt.Option.getWithDefault(total -. 1.0)
      let end2 = end_ >= total ? total -. 1.0 : end_
      start <= end2 && start >= 0.0 ? Some((start, end2)) : None
    | _ => None
    }
  }

let serveFile = (path: string, name: string, req: serverRequest, res: serverResponse): unit => {
  let st = statSync(path)
  let total = statSize(st)
  let ct = contentType(name)
  switch reqHeaders(req)->Js.Dict.get("range") {
  | Some(r) =>
    switch parseRange(r, total) {
    | Some((start, end_)) =>
      let len = end_ -. start +. 1.0
      let h = Js.Dict.empty()
      h->Js.Dict.set("Content-Type", ct)
      h->Js.Dict.set("Content-Length", Js.Float.toString(len))
      h->Js.Dict.set(
        "Content-Range",
        "bytes " ++ Js.Float.toString(start) ++ "-" ++ Js.Float.toString(end_) ++ "/" ++ Js.Float.toString(total),
      )
      h->Js.Dict.set("Accept-Ranges", "bytes")
      res->writeHead(206, h)
      createReadStreamRange(path, {start: start, end_: end_})->pipe(res)
    | None =>
      let h = Js.Dict.empty()
      h->Js.Dict.set("Content-Range", "bytes */" ++ Js.Float.toString(total))
      res->writeHead(416, h)
      res->endEmpty
    }
  | None =>
    let h = Js.Dict.empty()
    h->Js.Dict.set("Content-Type", ct)
    h->Js.Dict.set("Content-Length", Js.Float.toString(total))
    h->Js.Dict.set("Accept-Ranges", "bytes")
    res->writeHead(200, h)
    createReadStreamAll(path)->pipe(res)
  }
}

/* One unreadable file must not take the server down — it runs for hours while
   the author browses, and a broken symlink or a file deleted mid-listing would
   otherwise kill it. Every request is wrapped and the reason is logged. */
let rec handler = (req: serverRequest, res: serverResponse): unit =>
  try {
    handleRequest(req, res)
  } catch {
  | Js.Exn.Error(e) =>
    write("  ERROR " ++ reqUrl(req) ++ " -> " ++ Js.Exn.message(e)->Belt.Option.getWithDefault("?") ++ "\n")
    res->writeHead(500, Js.Dict.fromArray([("Content-Type", "text/plain")]))
    res->endWith("server error")
  | _ =>
    write("  ERROR " ++ reqUrl(req) ++ " -> non-JS exception\n")
    res->writeHead(500, Js.Dict.fromArray([("Content-Type", "text/plain")]))
    res->endWith("server error")
  }

and handleRequest = (req: serverRequest, res: serverResponse): unit => {
  let raw = reqUrl(req)
  let noQuery = switch Js.String2.indexOf(raw, "?") {
  | -1 => raw
  | i => Js.String2.slice(raw, ~from=0, ~to_=i)
  }
  let rel = decodeURIComponent(noQuery)->Js.String2.replaceByRe(%re("/^\/+/"), "")
  switch safeJoin(rel) {
  | None =>
    res->writeHead(403, Js.Dict.fromArray([("Content-Type", "text/plain")]))
    res->endWith("forbidden")
  | Some(path) =>
    if !existsSync(path) {
      res->writeHead(404, Js.Dict.fromArray([("Content-Type", "text/plain")]))
      res->endWith("not found: /" ++ rel)
    } else if isDirectory(statSync(path)) {
      let h = Js.Dict.empty()
      h->Js.Dict.set("Content-Type", "text/html; charset=utf-8")
      res->writeHead(200, h)
      res->endWith(listing(path, rel))
    } else {
      let name = switch Js.String2.lastIndexOf(path, "/") {
      | -1 => path
      | i => Js.String2.sliceToEnd(path, ~from=i + 1)
      }
      serveFile(path, name, req, res)
    }
  }
}

let () = {
  let port = argv->Belt.Array.get(2)->Belt.Option.flatMap(Belt.Int.fromString)->Belt.Option.getWithDefault(8787)
  let host = argv->Belt.Array.get(3)->Belt.Option.getWithDefault("100.94.98.40")
  createServer(handler)->listen(port, host, () =>
    write(
      "serving " ++ root ++ "\n" ++
      "  http://" ++ host ++ ":" ++ Belt.Int.toString(port) ++ "/\n" ++
      "  http://dustys-mac-studio.tail9e29c.ts.net:" ++ Belt.Int.toString(port) ++ "/\n",
    )
  )
}
