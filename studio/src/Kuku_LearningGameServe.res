/* Loopback-only static server for the Kuku learning game.
   Tailscale Serve supplies the tailnet-only HTTPS front door. */

type req
type res
type server

@module("http") external createServer: ((req, res) => unit) => server = "createServer"
@send external listen: (server, int, string, unit => unit) => unit = "listen"
@get external urlOf: req => string = "url"
@send external writeHead: (res, int, Js.Dict.t<string>) => unit = "writeHead"
@send external endBuffer: (res, 'buffer) => unit = "end"
@send external endText: (res, string) => unit = "end"

@module("fs") external readFileSync: string => 'buffer = "readFileSync"
@val external decodeURIComponent: string => string = "decodeURIComponent"
@val @scope("process") external env: Js.Dict.t<string> = "env"

let gameDir = Js.Dict.get(env, "GAME_DIR")->Belt.Option.getWithDefault("../stories/kuku/game")

let port = switch Js.Dict.get(env, "PORT") {
| Some(value) => Belt.Int.fromString(value)->Belt.Option.getWithDefault(8405)
| None => 8405
}

let route = path =>
  switch path {
  | "/" | "/index.html" => Some(("index.html", "text/html; charset=utf-8"))
  | "/logic.js" => Some(("logic.js", "text/javascript; charset=utf-8"))
  | "/assets/game.js" => Some(("assets/game.js", "text/javascript; charset=utf-8"))
  | "/assets/strings.json" => Some(("assets/strings.json", "application/json; charset=utf-8"))
  | _ => None
  }

let handler = (req: req, res: res) => {
  let rawPath = Belt.Array.getExn(Js.String2.split(urlOf(req), "?"), 0)
  let path = decodeURIComponent(rawPath)

  switch route(path) {
  | Some((relativePath, contentType)) => {
      let body = readFileSync(gameDir ++ "/" ++ relativePath)
      let headers = Js.Dict.empty()
      Js.Dict.set(headers, "Content-Type", contentType)
      Js.Dict.set(headers, "Cache-Control", "no-cache")
      Js.Dict.set(headers, "X-Content-Type-Options", "nosniff")
      Js.Dict.set(headers, "Referrer-Policy", "no-referrer")
      writeHead(res, 200, headers)
      endBuffer(res, body)
    }
  | None => {
      let headers = Js.Dict.empty()
      Js.Dict.set(headers, "Content-Type", "text/plain; charset=utf-8")
      writeHead(res, 404, headers)
      endText(res, "not found")
    }
  }
}

let host = "127.0.0.1"

let _ = createServer(handler)->listen(port, host, () =>
  Js.log(
    "Kuku learning game on http://" ++
    host ++
    ":" ++
    Belt.Int.toString(port) ++
    " <- " ++
    gameDir,
  )
)
