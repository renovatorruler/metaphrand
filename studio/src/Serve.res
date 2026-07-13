/* Dailies shelf — a tiny static file server for review artifacts,
   fronted by `tailscale serve` (the macOS app can't path-serve, only
   proxy a localhost port). Range-aware so audio scrubs on a phone.
   Binds loopback only; Tailscale is the sole way in.
   Run: DIR=/abs/releases PORT=8377 node src/Serve.res.mjs */

type req
type res
type server
@module("http") external createServer: ((req, res) => unit) => server = "createServer"
@send external listen: (server, int, string, unit => unit) => unit = "listen"
@get external urlOf: req => string = "url"
@get external headersOf: req => Js.Dict.t<string> = "headers"
@send external writeHead: (res, int, 'h) => unit = "writeHead"
@send external endBuf: (res, 'b) => unit = "end"
@send external endStr: (res, string) => unit = "end"
@module("fs") external readFileSync: string => 'b = "readFileSync" /* no encoding -> Buffer */
@module("fs") external existsSync: string => bool = "existsSync"
@module("fs") external readdirSync: string => array<string> = "readdirSync"
type stat
@module("fs") external statSync: string => stat = "statSync"
@send external isDirectory: stat => bool = "isDirectory"
@get external bufLength: 'b => int = "length"
@send external bufSlice: ('b, int, int) => 'b = "slice"
@val external decodeURIComponent: string => string = "decodeURIComponent"
@val @scope("process") external env: Js.Dict.t<string> = "env"

let dir = switch Js.Dict.get(env, "DIR") {
| Some(d) => d
| None => "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/audio/releases"
}
let port = switch Js.Dict.get(env, "PORT") {
| Some(p) => Belt.Int.fromString(p)->Belt.Option.getWithDefault(8377)
| None => 8377
}

let contentType = (name: string): string =>
  if Js.String2.endsWith(name, ".mp3") {
    "audio/mpeg"
  } else if Js.String2.endsWith(name, ".pdf") {
    "application/pdf"
  } else if Js.String2.endsWith(name, ".txt") || Js.String2.endsWith(name, ".fountain") {
    "text/plain; charset=utf-8"
  } else if Js.String2.endsWith(name, ".json") {
    "application/json"
  } else {
    "application/octet-stream"
  }

let rangeRe = %re("/bytes=(\d+)-(\d*)/")

let listing = (): string => {
  let rows =
    readdirSync(dir)
    ->Belt.Array.keep(f => !Js.String2.startsWith(f, "."))
    ->Belt.Array.map(f => {
      let mb = Js.Float.toFixedWithPrecision(
        Obj.magic(statSync(dir ++ "/" ++ f))["size"] /. 1048576.0,
        ~digits=1,
      )
      /* relative href — the shelf may be mounted under a path prefix */
      `<li><a href="${f}">${f}</a> <small>${mb} MB</small></li>`
    })
    ->Belt.Array.joinWith("\n", x => x)
  `<!doctype html><meta name="viewport" content="width=device-width, initial-scale=1">
<title>FOUR OLDS — dailies</title>
<style>body{font:16px -apple-system,sans-serif;margin:2em;max-width:40em}li{margin:.6em 0}small{color:#888}</style>
<h2>THE FOUR OLDS — dailies shelf</h2><ul>
${rows}
</ul>`
}

let handler = (req: req, res: res) => {
  let u = decodeURIComponent(Belt.Array.getExn(Js.String2.split(urlOf(req), "?"), 0))
  if Js.String2.includes(u, "..") {
    writeHead(res, 403, Js.Dict.empty())
    endStr(res, "forbidden")
  } else if u == "/" || u == "" {
    let headers = Js.Dict.empty()
    Js.Dict.set(headers, "Content-Type", "text/html; charset=utf-8")
    writeHead(res, 200, headers)
    endStr(res, listing())
  } else {
    let full = dir ++ u
    if existsSync(full) && !isDirectory(statSync(full)) {
      let buf = readFileSync(full)
      let total = bufLength(buf)
      let ct = contentType(u)
      let range =
        Js.Dict.get(headersOf(req), "range")->Belt.Option.flatMap(h =>
          Js.Re.exec_(rangeRe, h)
        )
      switch range {
      | Some(m) => {
          let g = Js.Re.captures(m)
          let start =
            Js.Nullable.toOption(Belt.Array.getExn(g, 1))
            ->Belt.Option.flatMap(Belt.Int.fromString)
            ->Belt.Option.getWithDefault(0)
          let stop =
            Js.Nullable.toOption(Belt.Array.getExn(g, 2))
            ->Belt.Option.flatMap(Belt.Int.fromString)
            ->Belt.Option.getWithDefault(total - 1)
          let stop = stop >= total ? total - 1 : stop
          let headers = Js.Dict.empty()
          Js.Dict.set(
            headers,
            "Content-Range",
            "bytes " ++
            Belt.Int.toString(start) ++
            "-" ++
            Belt.Int.toString(stop) ++
            "/" ++
            Belt.Int.toString(total),
          )
          Js.Dict.set(headers, "Accept-Ranges", "bytes")
          Js.Dict.set(headers, "Content-Length", Belt.Int.toString(stop - start + 1))
          Js.Dict.set(headers, "Content-Type", ct)
          writeHead(res, 206, headers)
          endBuf(res, bufSlice(buf, start, stop + 1))
        }
      | None => {
          let headers = Js.Dict.empty()
          Js.Dict.set(headers, "Content-Length", Belt.Int.toString(total))
          Js.Dict.set(headers, "Content-Type", ct)
          Js.Dict.set(headers, "Accept-Ranges", "bytes")
          writeHead(res, 200, headers)
          endBuf(res, buf)
        }
      }
    } else {
      writeHead(res, 404, Js.Dict.empty())
      endStr(res, "not found")
    }
  }
}

/* 0.0.0.0, not loopback: the macOS Tailscale network extension's Funnel
   ingress cannot connect to 127.0.0.1-bound targets (tailnet-side serve
   can — the asymmetry cost an hour; the Gloss server binds all
   interfaces and that is why it works through Funnel) */
let host = Js.Dict.get(env, "HOST")->Belt.Option.getWithDefault("0.0.0.0")
let _ = createServer(handler)->listen(port, host, () =>
  Js.log("dailies shelf on http://" ++ host ++ ":" ++ Belt.Int.toString(port) ++ " <- " ++ dir)
)
