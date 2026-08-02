/* कुकु और अक्षर — lip-sync the shots in lip_plan.json through fal.ai OmniHuman.

   Resumable: each finished shot is recorded in lipclips/_manifest.json and skipped
   on a re-run, so a crash costs nothing and a partial run degrades to "some shots
   move, the rest stay still".

   The audio handed to OmniHuman is built with the SAME lead/gap placement the
   assembler uses, so the returned video lines up with the episode timeline frame
   for frame. Building it from 0.0 would put every mouth 0.3s ahead of its voice.

   fal rejects data-URI audio (file_download_error, 2026-07), so the still and the
   wav are staged into the public shelf directory and passed as URLs.

   Run from studio/:  node src/Kuku_Lipsync.res.mjs
   DRY=1 does everything except spend. */

open Cinema_Backends

@val @scope(("process", "env")) external envDry: option<string> = "DRY"
@val @scope(("process", "env")) external envLimit: option<string> = "LIMIT"
@val @scope(("process", "env")) external envConc: option<string> = "CONC"

/* fal's queue accepts concurrent jobs, so shots go out in small batches rather
   than one at a time — 27 sequential jobs at ~7 min each is three hours. (The
   strictly-sequential rule elsewhere in this pipeline is a HIGGSFIELD CLI
   constraint; it does not apply here.) Kept modest to stay well inside rate
   limits, and the batch is a barrier so the manifest is written once per batch
   and never races. */
@val @scope("Promise") external allPromises: array<promise<'a>> => promise<array<'a>> = "all"

let dir = "/Users/dusty/Dev/metaphrand/stories/kuku/ep5prod"
let shelf = "/Users/dusty/kuku-public/lip"
let publicBase = "https://dustys-mac-studio.tail9e29c.ts.net:10000/kukuvid/lip"
let rate = 0.14 /* USD per second of synced video */
let padSeconds = 0.8 /* frozen tail so the clip always covers its segment */

type shot = {
  scene: string,
  seg: int,
  who: string,
  still: string,
  takes: array<int>,
  secs: float,
  beat: option<string>,
}

let fld = (j, k) => j->Js.Json.decodeObject->Belt.Option.flatMap(o => Js.Dict.get(o, k))
let asStr = o => o->Belt.Option.flatMap(Js.Json.decodeString)
let asNum = o => o->Belt.Option.flatMap(Js.Json.decodeNumber)

let decodeShots = (raw: string): array<shot> => {
  let j = Js.Json.parseExn(raw)
  let arr = fld(j, "shots")->Belt.Option.flatMap(Js.Json.decodeArray)->Belt.Option.getWithDefault([])
  arr->Belt.Array.map(s => {
    scene: fld(s, "scene")->asStr->Belt.Option.getWithDefault(""),
    seg: fld(s, "seg")->asNum->Belt.Option.getWithDefault(0.0)->Belt.Float.toInt,
    who: fld(s, "who")->asStr->Belt.Option.getWithDefault(""),
    still: fld(s, "still")->asStr->Belt.Option.getWithDefault(""),
    takes: fld(s, "takes")
    ->Belt.Option.flatMap(Js.Json.decodeArray)
    ->Belt.Option.getWithDefault([])
    ->Belt.Array.map(x => Js.Json.decodeNumber(x)->Belt.Option.getWithDefault(0.0)->Belt.Float.toInt),
    secs: fld(s, "secs")->asNum->Belt.Option.getWithDefault(0.0),
    beat: fld(s, "beat")->asStr,
  })
}

let pad2 = (i: int): string => i < 10 ? "0" ++ Belt.Int.toString(i) : Belt.Int.toString(i)
let tagOf = (s: shot): string => s.scene ++ "_" ++ pad2(s.seg)

/* the speech-only bus for one segment, placed exactly as the assembler places it */
let buildAudio = (~s: shot, ~durs: Kuku_Edl.durs): string => {
  let dst = shelf ++ "/" ++ tagOf(s) ++ ".wav"
  if exists(Path(dst)) {
    dst
  } else {
    let clock = ref(0.0)
    let placed = s.takes->Belt.Array.mapWithIndex((n, idx) => {
      let at = n == 0 ? Kuku_Assemble.lead : clock.contents +. Kuku_Assemble.gap
      let d = Kuku_Edl.takeDur(durs, idx)
      clock := at +. d
      (dir ++ "/" ++ Kuku_Edl.eventPath(Speech({idx, at: None})), at)
    })
    let total = clock.contents +. Kuku_Assemble.tail
    let inputs = Belt.Array.concatMany(placed->Belt.Array.map(((p, _)) => ["-i", p]))
    let chains = placed->Belt.Array.mapWithIndex((k, (_, at)) =>
      "[" ++
      Belt.Int.toString(k) ++
      ":a]aresample=44100,adelay=" ++
      Belt.Int.toString(Belt.Float.toInt(at *. 1000.0)) ++
      ":all=1[d" ++
      Belt.Int.toString(k) ++ "]"
    )
    let mix = Js.Array2.joinWith(
      placed->Belt.Array.mapWithIndex((k, _) => "[d" ++ Belt.Int.toString(k) ++ "]"),
      "",
    )
    let fc =
      Js.Array2.joinWith(chains, ";") ++
      ";" ++
      mix ++
      "amix=inputs=" ++
      Belt.Int.toString(Belt.Array.length(placed)) ++
      ":duration=longest:normalize=0,atrim=0:" ++
      Js.Float.toString(total) ++
      ",apad=whole_dur=" ++
      Js.Float.toString(total) ++ "[o]"
    ensureDirPath(Path(shelf))
    ffmpeg(
      Belt.Array.concatMany([
        ["-y"],
        inputs,
        ["-filter_complex", fc, "-map", "[o]", "-ac", "1", "-ar", "44100", dst],
      ]),
    )
    dst
  }
}

let main = async () => {
  let dry = envDry == Some("1")
  let plan = decodeShots(readText(Path(dir ++ "/lip_plan.json")))
  let shots = switch envLimit->Belt.Option.flatMap(x => Belt.Int.fromString(x)) {
  | Some(n) => Belt.Array.slice(plan, ~offset=0, ~len=n)
  | None => plan
  }
  let durs = Kuku_Edl.loadDurs(Path(dir ++ "/ep5_durs.json"))
  let edl = Kuku_Edl.load(Path(dir ++ "/ep5_edl.json"))
  let scenes = Js.Dict.empty()
  edl.scenes->Belt.Array.forEach(sc => Js.Dict.set(scenes, sc.name, sc))

  let totalSec = Belt.Array.reduce(shots, 0.0, (a, s) => a +. s.secs)
  Js.log(
    "plan: " ++
    Belt.Int.toString(Belt.Array.length(shots)) ++
    " shots / " ++
    Js.Float.toFixedWithPrecision(totalSec, ~digits=1) ++
    "s = $" ++
    Js.Float.toFixedWithPrecision(totalSec *. rate, ~digits=2),
  )

  /* every shot must still be the still the plan expects — an EDL that moved on
     since the plan was computed would sync the wrong face */
  shots->Belt.Array.forEach(s => {
    let png = dir ++ "/stills/" ++ s.still ++ ".png"
    if !exists(Path(png)) {
      raise(BackendError("missing still " ++ png ++ " for " ++ tagOf(s)))
    }
    switch Js.Dict.get(scenes, s.scene) {
    | Some(sc) =>
      switch Belt.Array.get(sc.segments, s.seg) {
      | Some(seg) => {
          /* Either the segment still points at the still the plan expects, or this
             shot has ALREADY been applied and now carries the clip plus the
             still_was it came from. Both are fine; anything else means the EDL
             moved on since the plan was computed and we would sync the wrong face. */
          let ok = switch (seg.src, seg.stillWas) {
          | (Still(n), _) => n == s.still
          | (File(_), Some(w)) => w == s.still
          | _ => false
          }
          if !ok {
            raise(
              BackendError(
                "EDL drifted: " ++
                tagOf(s) ++
                " is " ++
                Kuku_Edl.sourceToString(seg.src) ++
                ", plan expects still:" ++ s.still ++ " — recompute the plan",
              ),
            )
          }
        }
      | None => raise(BackendError("no segment " ++ tagOf(s)))
      }
    | None => raise(BackendError("no scene " ++ s.scene))
    }
  })

  ensureDirPath(Path(dir ++ "/lipclips"))
  ensureDirPath(Path(shelf))
  let manPath = Path(dir ++ "/lipclips/_manifest.json")
  let man = exists(manPath)
    ? Js.Json.parseExn(readText(manPath))->Js.Json.decodeObject->Belt.Option.getWithDefault(Js.Dict.empty())
    : Js.Dict.empty()

  let alreadyDone = shots->Belt.Array.keep(s =>
    Js.Dict.get(man, tagOf(s)) != None && exists(Path(dir ++ "/lipclips/" ++ tagOf(s) ++ ".mp4"))
  )
  let pending = shots->Belt.Array.keep(s =>
    !(Js.Dict.get(man, tagOf(s)) != None && exists(Path(dir ++ "/lipclips/" ++ tagOf(s) ++ ".mp4")))
  )
  Js.log(
    Belt.Int.toString(Belt.Array.length(alreadyDone)) ++
    " already done, " ++
    Belt.Int.toString(Belt.Array.length(pending)) ++ " to do",
  )

  /* One shot, end to end. Returns the manifest row on success so the caller can
     merge rows after the batch settles — nothing mutates shared state mid-flight. */
  let processShot = async (s: shot): option<(string, string, string, float)> => {
    let tag = tagOf(s)
    let final = dir ++ "/lipclips/" ++ tag ++ ".mp4"
    let wav = buildAudio(~s, ~durs)
    let Seconds(alen) = probeDuration(Path(wav))
    if dry {
      None
    } else {
      let raw = dir ++ "/lipclips/" ++ tag ++ "_raw.mp4"
      /* Only pay when the raw download is genuinely absent. A crash after the
         download but before the finish step must not re-bill fal. */
      let fetched = if exists(Path(raw)) {
        Js.log("   " ++ tag ++ ": raw already downloaded — finishing without re-billing")
        true
      } else {
        /* fal caps image_url at 5 MB and these stills are 5-8 MB PNGs, so most
           shots came back "file_too_large". Stage a 1280-wide JPEG instead: about
           105 KB, 50x smaller, well inside the cap — and small enough that fal's
           fetch stops timing out, which was the other failure. OmniHuman returns
           1472x800 anyway, so nothing is lost by not sending 2752x1536. */
        let staged = shelf ++ "/" ++ tag ++ ".jpg"
        if !exists(Path(staged)) {
          ffmpeg([
            "-y", "-i", dir ++ "/stills/" ++ s.still ++ ".png",
            "-vf", "scale=1280:-2", "-q:v", "3", staged,
          ])
        }
        /* transient fetch failures happen under concurrency; retry before giving up */
        let rec attempt = async (n: int): bool =>
          switch await falOmnihumanUrl(
            ~imageUrl=publicBase ++ "/" ++ tag ++ ".jpg",
            ~audioUrl=publicBase ++ "/" ++ tag ++ ".wav",
          ) {
          | clip => {
              let _ = writeBytes(Path(raw), clip)
              true
            }
          | exception Js.Exn.Error(e) => {
              let m = Js.Exn.message(e)->Belt.Option.getWithDefault("?")
              if n < 3 {
                Js.log("   retry " ++ Belt.Int.toString(n) ++ " " ++ tag)
                await attempt(n + 1)
              } else {
                Js.log("   FAIL " ++ tag ++ ": " ++ m)
                false
              }
            }
          | exception BackendError(m) =>
            if n < 3 {
              Js.log("   retry " ++ Belt.Int.toString(n) ++ " " ++ tag)
              await attempt(n + 1)
            } else {
              Js.log("   FAIL " ++ tag ++ ": " ++ m)
              false
            }
          }
        await attempt(1)
      }
      if fetched {
        /* OmniHuman returns its own geometry (1472x800, 1.84:1). Force it back to
           the episode's exact 16:9 frame by CROPPING rather than scaling — a plain
           scale to 1280x720 squashes the face by ~3.5%. Then freeze the last frame
           so the clip always covers its segment. */
        ffmpeg([
          "-y", "-i", raw,
          "-vf",
          "scale=" ++
          Belt.Int.toString(Kuku_Assemble.width) ++
          ":" ++
          Belt.Int.toString(Kuku_Assemble.height) ++
          ":force_original_aspect_ratio=increase,crop=" ++
          Belt.Int.toString(Kuku_Assemble.width) ++
          ":" ++
          Belt.Int.toString(Kuku_Assemble.height) ++
          ",fps=" ++
          Belt.Int.toString(Kuku_Assemble.fps) ++
          ",tpad=stop_mode=clone:stop_duration=" ++
          Js.Float.toString(padSeconds) ++ ",format=yuv420p",
          "-an", "-c:v", "libx264", "-crf", "18", final,
        ])
        Js.log("   OK " ++ tag ++ " (" ++ s.who ++ ", " ++ Js.Float.toFixedWithPrecision(alen, ~digits=1) ++ "s)")
        Some((tag, s.still, s.who, alen))
      } else {
        None
      }
    }
  }

  let conc = switch envConc->Belt.Option.flatMap(x => Belt.Int.fromString(x)) {
  | Some(n) if n > 0 => n
  | _ => 4
  }
  let done_ = ref(Belt.Array.length(alreadyDone))
  let failed = ref(0)

  let rec runBatch = async (start: int): unit =>
    if start >= Belt.Array.length(pending) {
      ()
    } else {
      let batch = Belt.Array.slice(pending, ~offset=start, ~len=conc)
      Js.log(
        "\n-- batch " ++
        Belt.Int.toString(start / conc + 1) ++
        ": " ++
        Js.Array2.joinWith(batch->Belt.Array.map(tagOf), " ") ++ " --",
      )
      let rows = await allPromises(batch->Belt.Array.map(s => processShot(s)))
      /* barrier: the manifest is written once per batch, so concurrent shots can
         never interleave a half-written file */
      rows->Belt.Array.forEach(r =>
        switch r {
        | Some((tag, still, who, secs)) => {
            let rec_ = Js.Dict.empty()
            Js.Dict.set(rec_, "still", Js.Json.string(still))
            Js.Dict.set(rec_, "who", Js.Json.string(who))
            Js.Dict.set(rec_, "secs", Js.Json.number(secs))
            Js.Dict.set(man, tag, Js.Json.object_(rec_))
            done_ := done_.contents + 1
          }
        | None => failed := failed.contents + 1
        }
      )
      writeText(manPath, Js.Json.stringifyWithSpace(Js.Json.object_(man), 1))
      Js.log(
        "   [" ++
        Belt.Int.toString(done_.contents) ++
        "/" ++
        Belt.Int.toString(Belt.Array.length(shots)) ++ " done]",
      )
      await runBatch(start + conc)
    }

  if dry {
    pending->Belt.Array.forEach(s =>
      Js.log(
        tagOf(s) ++
        "  " ++
        s.who ++
        "  " ++
        s.still ++
        switch s.beat {
        | Some(b) => "  [" ++ b ++ "]"
        | None => ""
        },
      )
    )
  } else {
    await runBatch(0)
  }

  Js.log(
    "\n" ++
    Belt.Int.toString(done_.contents) ++
    "/" ++
    Belt.Int.toString(Belt.Array.length(shots)) ++
    " shots ready" ++
    (failed.contents > 0 ? ", " ++ Belt.Int.toString(failed.contents) ++ " failed" : ""),
  )
  if dry {
    Js.log("DRY run — nothing submitted, nothing spent.")
  }
}

/* A rejected promise here used to surface as Node's ERR_UNHANDLED_REJECTION with
   no indication of what actually went wrong. Report the real reason and exit
   nonzero so a failed run is obvious. */
@val @scope("process") external exit: int => unit = "exit"

main()
->Js.Promise2.catch(e => {
  Js.log2("LIPSYNC FAILED:", e)
  exit(1)
  Js.Promise.resolve()
})
->ignore
