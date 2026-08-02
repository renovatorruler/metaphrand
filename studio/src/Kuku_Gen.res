/* कुकु और अक्षर — stills and motion clips via the higgsfield CLI.

   Reads a shot list (JSON) and renders each entry once. The design that matters:

   * The STYLE KEY IS ALWAYS THE FIRST --image, and the character sheets follow in
     frame order. The prompt itself says so ("the FIRST attached image is the art
     style"), so the argument order is load-bearing, not cosmetic.
   * Skip is on "exists AND non-trivial size", never bare existence — a zero-byte
     file from a failed download must be retried, not cached forever.
   * Strictly sequential with a pause between calls. The CLI fails in bursts.
   * The negative block is fixed and always appended. Curtains, stages and readable
     text have each crept back into shipped frames; they are banned here rather than
     in each prompt, where a writer can forget them.

   Run from studio/:
     node src/Kuku_Gen.res.mjs <episode-dir> <shots.json>   (DRY=1 to price it) */

open Cinema_Backends

@val @scope("process") external argv: array<string> = "argv"
@val @scope(("process", "env")) external envDry: option<string> = "DRY"
@val @scope(("process", "env")) external envOnly: option<string> = "ONLY"

/* SHARD=i/n renders only every n-th shot starting at i, so several processes can
   run at once without duplicating work. Generation is billed per image, not per
   minute, so the only reason this was ever serial is that the CLI used to fail when
   hammered — the retry loop below covers that. */
@val @scope(("process", "env")) external envShard: option<string> = "SHARD"

let shard: (int, int) = switch envShard {
| Some(s) =>
  switch Js.String2.split(s, "/") {
  | [a, b] =>
    switch (Belt.Int.fromString(a), Belt.Int.fromString(b)) {
    | (Some(i), Some(n)) if n > 0 && i >= 0 && i < n => (i, n)
    | _ => (0, 1)
    }
  | _ => (0, 1)
  }
| None => (0, 1)
}

let styleKey = "0c47270d-70f7-4dd0-887f-c06c88ef5fd9"
let sheetDir = "/Users/dusty/Dev/metaphrand/stories/kuku/charsheets"

let stylePreamble = "STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY. CHARACTER REFERENCES: every other attached image is a locked character design; match each EXACTLY. 3D papercraft, layered cut-paper illustration, soft matte construction-paper textures, visible paper edges and folds, warm storybook palette, soft lighting, non-photorealistic, illustrated, not a photo. LANDSCAPE 16:9 SHOT."

let negative = "Full-bleed scene, the camera is INSIDE the world. NEGATIVE: no theater curtains, no stage, no proscenium, no frame-within-frame, no decorative border, no vignette, no readable text, no letters, no numbers, no glyphs, no captions, no watermark, no logos, no photorealism, no duplicate characters, no extra characters, nothing scary."

/* dialogue stills hold under a spoken line, so the mouth must not contradict it */
let mouthClosed = "Mouth gently closed, clear readable expression."

type shot = {name: string, kind: string, refs: array<string>, prompt: string}

let fld = (j, k) => j->Js.Json.decodeObject->Belt.Option.flatMap(o => Js.Dict.get(o, k))
let asStr = o => o->Belt.Option.flatMap(Js.Json.decodeString)->Belt.Option.getWithDefault("")
let asArr = o => o->Belt.Option.flatMap(Js.Json.decodeArray)->Belt.Option.getWithDefault([])

let decodeShots = (j: Js.Json.t, key: string, kind: string): array<shot> =>
  fld(j, key)
  ->asArr
  ->Belt.Array.map(s => {
    name: fld(s, "name")->asStr,
    kind: fld(s, "kind")->asStr == "" ? kind : fld(s, "kind")->asStr,
    refs: fld(s, "refs")->asArr->Belt.Array.map(r => Js.Json.decodeString(r)->Belt.Option.getWithDefault("")),
    prompt: fld(s, "prompt")->asStr,
  })

/* the CLI answers with either a bare object or a one-element array */
let resultUrl = (raw: string): option<string> =>
  switch Js.Json.parseExn(raw) {
  | j => {
      let obj = switch Js.Json.decodeArray(j) {
      | Some(a) => Belt.Array.get(a, 0)->Belt.Option.getWithDefault(j)
      | None => j
      }
      switch fld(obj, "result_url")->Belt.Option.flatMap(Js.Json.decodeString) {
      | Some(u) if u != "" => Some(u)
      | _ => None
      }
    }
  | exception _ => None
  }

let sleepSync = (seconds: int): unit => {
  let _ = run(~cmd="sleep", ~args=[Belt.Int.toString(seconds)])
}

let main = () => {
  switch (Belt.Array.get(argv, 2), Belt.Array.get(argv, 3)) {
  | (Some(dir), Some(shotsFile)) => {
      let dry = envDry == Some("1")
      let only = envOnly
      let j = Js.Json.parseExn(readText(Path(dir ++ "/" ++ shotsFile)))
      let stills = decodeShots(j, "stills", "story")
      let clips = decodeShots(j, "clips", "clip")
      ensureDirPath(Path(dir ++ "/stills"))
      ensureDirPath(Path(dir ++ "/clips"))

      let wanted = (n: string) =>
        switch only {
        | Some(o) => Js.String2.includes(n, o)
        | None => true
        }

      let made = ref(0)
      let skipped = ref(0)
      let failed = ref(0)

      let render = (~name: string, ~refs: array<string>, ~prompt: string, ~isClip: bool) => {
        let out = isClip ? dir ++ "/clips/" ++ name ++ ".mp4" : dir ++ "/stills/" ++ name ++ ".png"
        let minBytes = isClip ? 100000.0 : 20000.0
        if exists(Path(out)) && fileSizeMb(Path(out)) *. 1.0e6 > minBytes {
          skipped := skipped.contents + 1
        } else if dry {
          Js.log("  would render " ++ name ++ "  refs=[" ++ Js.Array2.joinWith(refs, ",") ++ "]")
        } else {
          /* style key FIRST, then the character sheets in frame order */
          let refArgs = Belt.Array.concatMany(
            refs
            ->Belt.Array.keep(r => r != "" && exists(Path(sheetDir ++ "/" ++ r ++ ".png")))
            ->Belt.Array.map(r => ["--image", sheetDir ++ "/" ++ r ++ ".png"]),
          )
          let body =
            stylePreamble ++
            " " ++
            prompt ++
            " " ++
            (isClip ? "" : mouthClosed ++ " ") ++
            negative
          let base = isClip
            ? [
                "generate", "create", "gemini_omni", "--prompt", body,
                "--image", styleKey,
              ]
            : ["generate", "create", "nano_banana_pro", "--prompt", body, "--image", styleKey]
          let tail = isClip
            ? ["--duration", "10", "--aspect_ratio", "16:9", "--resolution", "720p", "--wait", "--json"]
            : ["--aspect_ratio", "16:9", "--resolution", "2k", "--wait", "--json"]

          let rec attempt = (n: int): unit =>
            if n > 3 {
              failed := failed.contents + 1
              Js.log("  FAIL " ++ name ++ " after 3 tries")
            } else {
              let r = run(
                ~cmd="higgsfield",
                ~args=Belt.Array.concatMany([base, refArgs, tail]),
              )
              switch r.code == 0 ? resultUrl(r.stdout) : None {
              | Some(url) => {
                  let d = run(~cmd="curl", ~args=["-s", "-o", out, url])
                  if d.code == 0 && exists(Path(out)) && fileSizeMb(Path(out)) *. 1.0e6 > minBytes {
                    made := made.contents + 1
                    Js.log("  OK " ++ name)
                    sleepSync(4)
                  } else {
                    Js.log("  retry " ++ Belt.Int.toString(n) ++ " " ++ name ++ " (download)")
                    sleepSync(10)
                    attempt(n + 1)
                  }
                }
              | None => {
                  Js.log("  retry " ++ Belt.Int.toString(n) ++ " " ++ name)
                  sleepSync(12)
                  attempt(n + 1)
                }
              }
            }
          attempt(1)
        }
      }

      Js.log(
        "shot list: " ++
        Belt.Int.toString(Belt.Array.length(stills)) ++
        " stills, " ++
        Belt.Int.toString(Belt.Array.length(clips)) ++ " clips",
      )
      let (si, sn) = shard
      if sn > 1 {
        Js.log("shard " ++ Belt.Int.toString(si) ++ " of " ++ Belt.Int.toString(sn))
      }
      let mine = (idx: int) => mod(idx, sn) == si

      stills
      ->Belt.Array.keep(s => wanted(s.name))
      ->Belt.Array.forEachWithIndex((i, s) =>
        if mine(i) {
          render(~name=s.name, ~refs=s.refs, ~prompt=s.prompt, ~isClip=false)
        }
      )
      clips
      ->Belt.Array.keep(c => wanted(c.name))
      ->Belt.Array.forEachWithIndex((i, c) =>
        if mine(i) {
          render(~name=c.name, ~refs=c.refs, ~prompt=c.prompt, ~isClip=true)
        }
      )

      Js.log(
        "\nmade=" ++
        Belt.Int.toString(made.contents) ++
        " skipped=" ++
        Belt.Int.toString(skipped.contents) ++
        " failed=" ++
        Belt.Int.toString(failed.contents),
      )
      if dry {
        Js.log("DRY run — nothing generated, nothing spent.")
      }
    }
  | _ => Js.log("usage: node src/Kuku_Gen.res.mjs <episode-dir> <shots.json>")
  }
}

main()
