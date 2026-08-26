/* KukuEp10_Package.res — emit a self-contained PROMPT PACKAGE for a shot.
   Everything a model needs in one folder, in the order it is supplied:
   the rendered prompt, the backplate, the character references, and — for a
   clip — the starting frame. Nothing in a package is hand-written: the prompt
   comes from Kuku_PromptSpec, the references from the shot's own spec.

   Run from studio/:
     node src/KukuEp10_Package.res.mjs h22_castor_calm       # one still shot
     node src/KukuEp10_Package.res.mjs s2c_castor_talks      # one clip
     node src/KukuEp10_Package.res.mjs --all                 # every shot */

module P = Kuku_PromptSpec

@module("fs") external writeFileSync: (string, string) => unit = "writeFileSync"
@module("fs") external copyFileSync: (string, string) => unit = "copyFileSync"
@module("fs") external existsSync: string => bool = "existsSync"
@module("fs") external mkdirSync: (string, {"recursive": bool}) => unit = "mkdirSync"
@module("path") external basename: string => string = "basename"
type execOpts = {"encoding": string, "timeout": int}
@module("child_process")
external execFileSync: (string, array<string>, execOpts) => string = "execFileSync"
@scope("process") @val external argv: array<string> = "argv"

let opts = {"encoding": "utf8", "timeout": 300000}
let root = P.kukuRoot ++ "ep10prod/packages/"

let str = Js.Json.string
let obj = kvs => Js.Json.object_(Js.Dict.fromArray(kvs))

/* the style reference lives on the provider as an upload id; there is no local
   copy and no way to fetch one back, so the package names it rather than
   pretending to ship it */
let styleNote = "SLOT 1 — STYLE REFERENCE\n\nUpload id: " ++ P.styleKey ++ "\n\nThis is the art-style reference attached FIRST to every generation. It lives on\nHiggsfield as a stored upload; the CLI offers no way to download it back, so it\ncannot be included here as a file. Anything reproducing this package must pass\nthis id as the first --image.\n"

let write = (dir, name, srcPath, slot, role) =>
  if existsSync(srcPath) {
    let ext = Js.String2.sliceToEnd(srcPath, ~from=Js.String2.lastIndexOf(srcPath, "."))
    let dst = dir ++ "/" ++ Belt.Int.toString(slot) ++ "_" ++ role ++ ext
    copyFileSync(srcPath, dst)
    Some((slot, role, basename(dst), srcPath))
  } else {
    Js.log("  missing: " ++ srcPath)
    None
  }

let packShot = (e: KukuEp10_Shots.entry) => {
  let dir = root ++ e.id
  mkdirSync(dir, {"recursive": true})
  writeFileSync(dir ++ "/prompt.txt", P.imagePrompt(e.spec))
  writeFileSync(dir ++ "/1_style_reference.txt", styleNote)
  let refs = P.imageRefs(e.spec)
  let items = []
  Js.Array2.forEachi(refs, (r, i) => {
    if i > 0 {
      let role = Js.String2.includes(r, "/sets/")
        ? "backplate"
        : Js.String2.includes(r, "_board")
        ? "character_" ++ {
            let b = basename(r)
            let noExt = Js.String2.slice(b, ~from=0, ~to_=Js.String2.lastIndexOf(b, "."))
            noExt
            ->Js.String2.replace("future_", "")
            ->Js.String2.replace("_board_bracelet", "")
            ->Js.String2.replace("_board_v1", "")
            ->Js.String2.replace("_board", "")
          }
        : "reference_" ++ Belt.Int.toString(i)
      switch write(dir, "", r, i + 1, role) {
      | Some(x) => Js.Array2.push(items, x)->ignore
      | None => ()
      }
    }
  })
  writeFileSync(
    dir ++ "/manifest.json",
    Js.Json.stringifyWithSpace(
      obj([
        ("shot", str(e.id)),
        ("kind", str("still")),
        ("model", str("nano_banana_pro")),
        ("aspect_ratio", str("16:9")),
        ("resolution", str("2k")),
        (
          "attachments_in_order",
          Js.Json.array(
            Js.Array2.concat(
              [obj([("slot", str("1")), ("role", str("style_reference")), ("file", str("(upload id, see 1_style_reference.txt)"))])],
              Js.Array2.map(items, ((slot, role, file, src)) =>
                obj([
                  ("slot", str(Belt.Int.toString(slot))),
                  ("role", str(role)),
                  ("file", str(file)),
                  ("source", str(src)),
                ])
              ),
            ),
          ),
        ),
        ("prompt_file", str("prompt.txt")),
        ("derived_notes", Js.Json.array(Js.Array2.map(e.derived, str))),
      ]),
      2,
    ),
  )
  Js.log("packaged " ++ e.id ++ " -> " ++ dir)
  dir
}

let packClip = (c: KukuEp10_SceneClips.clip) => {
  let dir = root ++ c.tag
  mkdirSync(dir, {"recursive": true})
  writeFileSync(dir ++ "/prompt.txt", P.videoPrompt(c.spec))
  writeFileSync(dir ++ "/1_style_reference.txt", styleNote)
  let start = write(dir, "", c.start, 2, "starting_frame")
  writeFileSync(
    dir ++ "/manifest.json",
    Js.Json.stringifyWithSpace(
      obj([
        ("shot", str(c.tag)),
        ("kind", str("clip")),
        ("model", str(c.cheap ? "seedance_2_0_mini" : "seedance_2_5")),
        ("mode", str(c.cheap ? "(none)" : "omni_reference")),
        ("duration_seconds", str(Belt.Int.toString(c.secs))),
        ("resolution", str(c.cheap ? "720p" : "1080p")),
        (
          "attachments_in_order",
          Js.Json.array(
            switch start {
            | Some((slot, role, file, src)) => [
                obj([("slot", str(Belt.Int.toString(slot))), ("role", str(role)), ("file", str(file)), ("source", str(src))]),
              ]
            | None => []
            },
          ),
        ),
        ("prompt_file", str("prompt.txt")),
      ]),
      2,
    ),
  )
  Js.log("packaged " ++ c.tag ++ " -> " ++ dir)
  dir
}

/* a contact sheet so the package can be eyeballed without opening five files */
let preview = dir => {
  let files = execFileSync("bash", ["-lc", "ls " ++ dir ++ "/[0-9]_*.png 2>/dev/null | head -6"], opts)
  let list = Js.Array2.filter(Js.String2.split(Js.String2.trim(files), "\n"), f => f != "")
  if Js.Array2.length(list) == 1 {
    let _ = execFileSync("cp", [list[0], dir ++ "/preview.jpg"], opts)
    Js.log("  preview.jpg")
  } else if Js.Array2.length(list) > 1 {
    let inputs = Js.Array2.reduce(list, (acc, f) => Js.Array2.concat(acc, ["-i", f]), [])
    let n = Js.Array2.length(list)
    let scaled = Js.Array2.joinWith(
      Js.Array2.mapi(list, (_, i) =>
        "[" ++ Belt.Int.toString(i) ++ "]scale=420:236:force_original_aspect_ratio=decrease,pad=420:236:(ow-iw)/2:(oh-ih)/2:color=0x101010[v" ++ Belt.Int.toString(i) ++ "]"
      ),
      ";",
    )
    let chain = Js.Array2.joinWith(Js.Array2.mapi(list, (_, i) => "[v" ++ Belt.Int.toString(i) ++ "]"), "")
    let fc = scaled ++ ";" ++ chain ++ "hstack=inputs=" ++ Belt.Int.toString(n) ++ "[out]"
    let _ = execFileSync(
      "ffmpeg",
      Js.Array2.concatMany(["-v", "error", "-y"], [inputs, ["-filter_complex", fc, "-map", "[out]", "-frames:v", "1", dir ++ "/preview.jpg"]]),
      opts,
    )
    Js.log("  preview.jpg")
  }
}

let args = Js.Array2.sliceFrom(argv, 2)
let wantAll = Js.Array2.some(args, a => a == "--all")
let names = Js.Array2.filter(args, a => !Js.String2.startsWith(a, "--"))

let dirs = []
Js.Array2.forEach(KukuEp10_Shots.shots, e =>
  if wantAll || Js.Array2.includes(names, e.id) {
    Js.Array2.push(dirs, packShot(e))->ignore
  }
)
Js.Array2.forEach(KukuEp10_SceneClips.all, c =>
  if wantAll || Js.Array2.includes(names, c.tag) {
    Js.Array2.push(dirs, packClip(c))->ignore
  }
)
Js.Array2.forEach(dirs, preview)
Js.log("\n" ++ Belt.Int.toString(Js.Array2.length(dirs)) ++ " package(s) in " ++ root)
