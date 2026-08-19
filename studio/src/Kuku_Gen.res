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
@module("path") external resolvePath: string => string = "resolve"
@module("fs") external realpathSync: string => string = "realpathSync"

/* This legacy generator is deliberately Kuku-only. Without this runtime
   boundary its arbitrary <episode-dir> argument could be pointed at Drakosha
   Scene 1 and evade that show's manifest/readiness/receipt gate. */
let isKukuPath = path =>
  Js.String2.includes(path, "/stories/kuku/") || Js.String2.endsWith(path, "/stories/kuku")

let requireRealKukuPath = (path: string, label: string): string => {
  let absolute = resolvePath(path)
  let real = try realpathSync(absolute) catch {
  | Js.Exn.Error(error) =>
    raise(
      BackendError(
        "cannot resolve " ++ label ++ ": " ++
        Js.Exn.message(error)->Belt.Option.getWithDefault("unknown filesystem error"),
      ),
    )
  }
  if !isKukuPath(absolute) || !isKukuPath(real) {
    raise(
      BackendError(
        "Kuku_Gen may write only inside stories/kuku; Drakosha Scene 1 must use Drakosha_SceneFlowCli",
      ),
    )
  }
  real
}

let requireKukuEpisodeDir = dir => requireRealKukuPath(dir, "Kuku episode directory")

let safeShotName = (name: string): string => {
  if name == "" || Js.String2.includes(name, "/") || Js.String2.includes(name, "\\") ||
    Js.String2.includes(name, "..") {
    raise(BackendError("unsafe Kuku shot name: " ++ name))
  }
  name
}

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

/* "no humans" was added 2026-08-06 after two shipped stills grew human children —
   a prompt said "the children" without "dragon" and the model filled in people.
   EVERY being in अक्षर घाटी is a dragon, a goblin, a parrot or a dog; a human on
   screen breaks the world. The ban lives HERE, in the always-appended block,
   because lesson 14 is that a trimmed negative lets the defect return. */
let negativeCore = "Full-bleed scene, the camera is INSIDE the world. NEGATIVE: no humans, no people, no human children, no human faces, no human shadows, no theater curtains, no stage, no proscenium, no frame-within-frame, no decorative border, no vignette, no readable text, no letters, no numbers, no glyphs, no captions, no watermark, no logos, no photorealism, no duplicate characters, no extra characters"

/* Ep8 introduces the series' first antagonist, and the author asked for a
   thrilling, "scary" feel. "nothing scary" therefore cannot be unconditional any
   more — but it must not simply be deleted either, or every shot in the show
   drifts darker. A shot opts in with `"menace": true`, which trades the blanket
   ban for a NARROW one: the fear is scale, shadow and stillness — a predator's
   calm — never gore, teeth, blood, wounds, or horror lighting. Everything not
   opted in keeps the original rail exactly as it was. */
let negativeSafe = negativeCore ++ ", nothing scary."
let negativeMenace =
  negativeCore ++
  ", no blood, no wounds, no gore, no bared fangs, no drooling, no red glowing eyes, no skulls, no horror lighting, no jump-scare framing. The menace is SCALE, SHADOW and STILLNESS — a calm predator who is enjoying herself — suitable for a four-year-old who should lean in, not look away."

/* dialogue stills hold under a spoken line, so the mouth must not contradict it */
let mouthClosed = "Mouth gently closed, clear readable expression."

type shot = {name: string, kind: string, refs: array<string>, prompt: string, menace: bool, startFrom: string}

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
    menace: fld(s, "menace")->Belt.Option.flatMap(Js.Json.decodeBoolean)->Belt.Option.getWithDefault(false),
    /* an APPROVED still to animate. Empty means pure text-to-video, which for a
       show with locked designs is a last resort: 2026-08-10 the text-to-video
       clips came back with two फ्यूरियाs and a toddler rendered adult-sized,
       because prose cannot hold cast, count or scale against pixels. */
    startFrom: fld(s, "startFrom")->asStr,
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
      let dir = requireKukuEpisodeDir(dir)
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

      let render = (~name: string, ~refs: array<string>, ~prompt: string, ~isClip: bool, ~menace: bool, ~startFrom: string) => {
        let name = safeShotName(name)
        let outputDir = requireRealKukuPath(
          isClip ? dir ++ "/clips" : dir ++ "/stills",
          "Kuku output directory",
        )
        let out = outputDir ++ "/" ++ name ++ (isClip ? ".mp4" : ".png")
        let minBytes = isClip ? 100000.0 : 20000.0
        if exists(Path(out)) && fileSizeMb(Path(out)) *. 1.0e6 > minBytes {
          skipped := skipped.contents + 1
        } else if dry {
          Js.log("  would render " ++ name ++ "  refs=[" ++ Js.Array2.joinWith(refs, ",") ++ "]")
        } else {
          /* style key FIRST, then the character sheets in frame order */
          let refArgs = isClip && startFrom != ""
            ? []
            : Belt.Array.concatMany(
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
            (menace ? negativeMenace : negativeSafe)
          /* ANCHORED CLIP: the approved still IS frame one, so the model supplies
             motion only. No style key and no character sheets are attached — the
             frame already fixes design, cast, count, scale, staging and light,
             and extra references only give it room to disagree with itself.
             generate_audio is off: this show's sound is designed, not generated. */
          let anchored = isClip && startFrom != ""
          let startPath = dir ++ "/stills/" ++ startFrom ++ ".png"
          let base = if anchored {
            [
              /* mode=omni_reference is REQUIRED by the API whenever a start or end
                 image is supplied — without it the job is rejected outright. */
              "generate", "create", "seedance_2_5", "--mode", "omni_reference",
              "--prompt", prompt, "--start-image", startPath,
            ]
          } else if isClip {
            ["generate", "create", "gemini_omni", "--prompt", body, "--image", styleKey]
          } else {
            ["generate", "create", "nano_banana_pro", "--prompt", body, "--image", styleKey]
          }
          let tail = if anchored {
            [
              "--duration", "5", "--aspect_ratio", "16:9", "--resolution", "720p",
              "--generate_audio", "false", "--wait", "--json",
            ]
          } else if isClip {
            ["--duration", "10", "--aspect_ratio", "16:9", "--resolution", "720p", "--wait", "--json"]
          } else {
            ["--aspect_ratio", "16:9", "--resolution", "2k", "--wait", "--json"]
          }

          /* A DOWNLOAD FAILURE MUST NOT RE-GENERATE. The generation is already
             paid for the moment the API returns a URL; re-running the whole
             command to recover from a dropped curl buys the same clip twice (up
             to 3x for one network blip). Download retries loop on the URL alone. */
          let rec fetchTo = (url: string, k: int): bool =>
            if k > 3 {
              false
            } else {
              let d = run(~cmd="curl", ~args=["-sL", "--retry", "2", "-o", out, url])
              if d.code == 0 && exists(Path(out)) && fileSizeMb(Path(out)) *. 1.0e6 > minBytes {
                true
              } else {
                Js.log("  re-download " ++ Belt.Int.toString(k) ++ " " ++ name ++ " (NOT re-generating)")
                sleepSync(6)
                fetchTo(url, k + 1)
              }
            }

          /* A REJECTED REQUEST IS NOT TRANSIENT. Retrying a validation error just
             burns wall-clock and hides the cause: on 2026-08-10 nine clips retried
             three times each against "start_image ... only allowed for mode
             'omni_reference'", and the log said only "FAIL after 3 tries" — the
             real message had to be reproduced by hand. Print what the server said,
             and stop immediately when it cannot succeed on a repeat. */
          let permanent = (s: string): bool =>
            Js.String2.includes(s, "only allowed") ||
            Js.String2.includes(s, "not allowed") ||
            Js.String2.includes(s, "Invalid") ||
            Js.String2.includes(s, "invalid") ||
            Js.String2.includes(s, "required") ||
            Js.String2.includes(s, "unauthorized") ||
            Js.String2.includes(s, "missing the permission")

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
              | Some(url) =>
                if fetchTo(url, 1) {
                  made := made.contents + 1
                  Js.log("  OK " ++ name)
                  sleepSync(4)
                } else {
                  failed := failed.contents + 1
                  Js.log("  FAIL " ++ name ++ ": generated but could not download " ++ url)
                }
              | None => {
                  let msg = Js.String2.trim(r.stderr ++ " " ++ r.stdout)
                  let short = Js.String2.slice(msg, ~from=0, ~to_=300)
                  if permanent(msg) {
                    failed := failed.contents + 1
                    Js.log("  FAIL " ++ name ++ " — request rejected, not retrying: " ++ short)
                  } else {
                    Js.log("  retry " ++ Belt.Int.toString(n) ++ " " ++ name ++ ": " ++ short)
                    sleepSync(12)
                    attempt(n + 1)
                  }
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
          render(~name=s.name, ~refs=s.refs, ~prompt=s.prompt, ~isClip=false, ~menace=s.menace, ~startFrom="")
        }
      )
      clips
      ->Belt.Array.keep(c => wanted(c.name))
      ->Belt.Array.forEachWithIndex((i, c) =>
        if mine(i) {
          render(~name=c.name, ~refs=c.refs, ~prompt=c.prompt, ~isClip=true, ~menace=c.menace, ~startFrom=c.startFrom)
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
