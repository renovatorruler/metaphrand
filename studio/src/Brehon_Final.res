/* BREHON walkthrough — the combined render. Re-drives the prototype with
   holds cut to the MEASURED narration (brehon_audio_cuts.json), records,
   then lays each beat's mp3 at its screen's start (+0.7s lead), masters to
   -16 LUFS, and muxes. b0a spans cards 1-2 (60/40 split at "Grown adults");
   b12a+b12b share the ruling screen with a 0.6s breath.
   Run: node src/Brehon_Final.res.mjs */

type chromiumT
type browser
type context
type page
@module("playwright") external chromium: chromiumT = "chromium"
@send external launch: (chromiumT, 'o) => promise<browser> = "launch"
@send external newContext: (browser, 'o) => promise<context> = "newContext"
@send external ctxNewPage: context => promise<page> = "newPage"
@send external ctxClose: context => promise<unit> = "close"
@send external browserClose: browser => promise<unit> = "close"
@send external goto: (page, string, 'o) => promise<unit> = "goto"
@send external waitForTimeout: (page, int) => promise<unit> = "waitForTimeout"
@send external evaluate: (page, string) => promise<'a> = "evaluate"

@module("fs") external readFileSync: (string, string) => string = "readFileSync"
@module("fs") external readdirSync: string => array<string> = "readdirSync"
@module("fs") external mkdirSync: (string, 'a) => unit = "mkdirSync"
@module("child_process") external execSync: (string, 'a) => 'b = "execSync"

let base = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/brehon"
let vidDir = base ++ "/capture_final"
let out = base ++ "/BREHON-WALKTHROUGH_2026-07-15_1830_v5_final.mp4"

let sh = (cmd: string): unit => {
  let opts = Js.Dict.empty()
  Js.Dict.set(opts, "stdio", Obj.magic("pipe"))
  let _ = execSync(cmd, opts)
}

/* measured audio */
type cut = {"beat": string, "mp3": string, "sec": float}
let cuts: array<cut> = Obj.magic(Js.Json.parseExn(readFileSync(base ++ "/brehon_audio_cuts.json", "utf8")))
let cutOf = (id: string): cut =>
  switch cuts->Belt.Array.getBy(c => c["beat"] == id) {
  | Some(c) => c
  | None => Js.Exn.raiseError("no audio cut for " ++ id)
  }

let lead = 0.7 /* cold-open cards keep cinematic air */
let tail = 0.5
let leadA = 0.35 /* the app section cuts promo-tight */
let tailA = 0.2

/* the same scroller as the silent capture */
let scroller = (holdMs: int): string => {
  let hold = Belt.Int.toString(holdMs)
  "(function(){" ++
  "var cands=Array.prototype.slice.call(document.querySelectorAll('.screen,.folio,.feed'));" ++
  "var sc=null;for(var i=0;i<cands.length;i++){var e=cands[i];if(e.scrollHeight>e.clientHeight+40&&e.offsetParent){sc=e;break;}}" ++
  "if(!sc)return 0;" ++
  "var dist=sc.scrollHeight-sc.clientHeight;" ++
  "var delay=1200,tailms=1000,dur=" ++ hold ++ "-delay-tailms;if(dur<800)dur=800;" ++
  "var t0=null;" ++
  "function step(ts){if(!t0)t0=ts;var p=(ts-t0)/dur;if(p>1)p=1;var e=p*p*(3-2*p);sc.scrollTop=dist*e;if(p<1)requestAnimationFrame(step);}" ++
  "setTimeout(function(){requestAnimationFrame(step);},delay);" ++
  "return dist;})()"
}

type doc = Preroll | Proto

let main = async () => {
  mkdirSync(vidDir, {"recursive": true})

  /* durations */
  let d = (id: string): float => cutOf(id)["sec"]
  let b0a = d("b0a_wiki")
  /* the video beat plan: (id, doc, jsCall, holdSec, audio placements (mp3, offsetIntoBeat)) */
  let beats: array<(string, doc, string, float, array<(string, float)>)> = [
    ("b0_c1", Preroll, "showCard(1)", lead +. b0a *. 0.60, [(cutOf("b0a_wiki")["mp3"], lead)]),
    ("b0_c2", Preroll, "showCard(2)", b0a *. 0.40 +. tail, []),
    ("b0_c3", Preroll, "showCard(3)", lead +. d("b0b_rart") +. tail, [(cutOf("b0b_rart")["mp3"], lead)]),
    ("b0_c4", Preroll, "showCard(4)", lead +. d("b0c_whatif") +. tail, [(cutOf("b0c_whatif")["mp3"], lead)]),
    ("b1", Proto, "go('casedetail', {case:'AB12CD'})", leadA +. d("b1_record") +. tailA, [(cutOf("b1_record")["mp3"], leadA)]),
    ("b2", Proto, "go('signin', {})", leadA +. d("b2_signin") +. tailA, [(cutOf("b2_signin")["mp3"], leadA)]),
    ("b3a", Proto, "go('onboarding', {step:'game'})", leadA +. d("b3a_game") +. 0.15, [(cutOf("b3a_game")["mp3"], leadA)]),
    ("b3b", Proto, "go('onboarding', {step:'game', phase:'rule'})", leadA +. d("b3b_rule") +. tailA, [(cutOf("b3b_rule")["mp3"], leadA)]),
    ("b4", Proto, "go('onboarding', {step:'game', phase:'attempt'})", leadA +. d("b4_jaws") +. tailA, [(cutOf("b4_jaws")["mp3"], leadA)]),
    ("b5", Proto, "go('onboarding', {step:'game', phase:'rate'})", leadA +. d("b5_rate") +. tailA, [(cutOf("b5_rate")["mp3"], leadA)]),
    ("b6", Proto, "go('onboarding', {step:'game', phase:'reveal', choice:'BROKEN'})", leadA +. d("b6_reveal") +. tailA, [(cutOf("b6_reveal")["mp3"], leadA)]),
    ("b7a", Proto, "filled.onbName = true; go('onboarding', {step:'mark'})", leadA +. d("b7a_mark") +. tailA, [(cutOf("b7a_mark")["mp3"], leadA)]),
    ("b7b", Proto, "go('onboarding', {step:'wand'})", leadA +. d("b7b_wand") +. tailA, [(cutOf("b7b_wand")["mp3"], leadA)]),
    ("b8", Proto, "go('thread', {thread:'pizza'})", leadA +. d("b8_thread") +. tailA, [(cutOf("b8_thread")["mp3"], leadA)]),
    ("b9", Proto, "startChallenge('pizza', 0); go('challenge', {thread:'pizza', attemptidx:0, step:'demand'})", leadA +. d("b9_demand") +. tailA, [(cutOf("b9_demand")["mp3"], leadA)]),
    ("b10", Proto, "startChallenge('pizza', 0); go('challenge', {thread:'pizza', attemptidx:0, step:'surety'})", leadA +. d("b10_bond") +. tailA, [(cutOf("b10_bond")["mp3"], leadA)]),
    ("b11", Proto, "go('transcript', {case:'QF83RN'})", leadA +. d("b11_transcript") +. tailA, [(cutOf("b11_transcript")["mp3"], leadA)]),
    (
      "b12",
      Proto,
      "go('casedetail', {case:'SB63KH'})",
      leadA +. d("b12a_ruling") +. 0.35 +. d("b12b_lineage") +. tailA,
      [(cutOf("b12a_ruling")["mp3"], leadA), (cutOf("b12b_lineage")["mp3"], leadA +. d("b12a_ruling") +. 0.35)],
    ),
    ("b13", Proto, "go('casedetail', {case:'AB12CD'})", leadA +. d("b13_return") +. tailA, [(cutOf("b13_return")["mp3"], leadA)]),
  ]

  /* ---- capture ---- */
  let browser = await launch(chromium, {"headless": true})
  let ctx = await newContext(
    browser,
    {
      "viewport": {"width": 780, "height": 1688},
      "recordVideo": {"dir": vidDir, "size": {"width": 780, "height": 1688}},
    },
  )
  let page = await ctxNewPage(ctx)
  let schedule = [] /* (mp3, absoluteStartSec) */
  let clock = ref(0.5)
  let current = ref(Preroll)
  await goto(page, "file://" ++ base ++ "/preroll.html", {"waitUntil": "load"})
  await waitForTimeout(page, 500)

  let n = Belt.Array.length(beats)
  let rec go_ = async i =>
    if i < n {
      let (id, doc, call, holdS, audio) = Belt.Array.getExn(beats, i)
      if doc != current.contents {
        await goto(page, "file://" ++ base ++ "/prototype.html", {"waitUntil": "load"})
        let _ = await evaluate(
          page,
          "(function(){var s=document.createElement('style');" ++
          "s.textContent='.app{max-width:390px;height:50dvh;transform:scale(2);transform-origin:top center;}';" ++
          "document.head.appendChild(s);return 1;})()",
        )
        current := doc
        clock := clock.contents +. 0.4
        await waitForTimeout(page, 400)
      }
      let holdMs = Belt.Float.toInt(holdS *. 1000.0)
      let _ = await evaluate(page, call)
      if doc == Proto {
        let _ = await evaluate(page, scroller(holdMs))
        /* the promo push-in: no app frame sits dead — scale 2.00 -> 2.05
           over the beat, reset instantly on the next cut */
        let _ = await evaluate(
          page,
          "(function(){var app=document.querySelector('.app');if(!app)return 0;" ++
          "app.style.transition='none';app.style.transform='scale(2)';void app.offsetHeight;" ++
          "app.style.transition='transform " ++
          Belt.Int.toString(holdMs) ++
          "ms linear';app.style.transform='scale(2.05)';return 1;})()",
        )
      }
      audio->Belt.Array.forEach(((mp3, off)) => Js.Array2.push(schedule, (mp3, clock.contents +. off))->ignore)
      Js.log(id ++ " @ " ++ Js.Float.toFixedWithPrecision(clock.contents, ~digits=1) ++ "s hold " ++ Js.Float.toFixedWithPrecision(holdS, ~digits=1))
      await waitForTimeout(page, holdMs)
      clock := clock.contents +. holdS
      await go_(i + 1)
    }
  await go_(0)
  await waitForTimeout(page, 800) /* end pad */
  await ctxClose(ctx)
  await browserClose(browser)

  /* ---- convert + mux ---- */
  let webms = readdirSync(vidDir)->Belt.Array.keep(f => Js.String2.endsWith(f, ".webm"))
  switch webms->Belt.Array.get(Belt.Array.length(webms) - 1) {
  | None => Js.log("NO VIDEO RECORDED")
  | Some(w) => {
      let vtmp = vidDir ++ "/video_only.mp4"
      sh(
        "/opt/homebrew/bin/ffmpeg -y -loglevel error -i \"" ++
        vidDir ++ "/" ++ w ++
        "\" -vf \"scale=-2:1920,pad=1080:1920:(ow-iw)/2:0:black\" -c:v libx264 -pix_fmt yuv420p -r 30 -crf 20 \"" ++
        vtmp ++ "\"",
      )
      /* tracks: VO at full gain + the two music stems, trimmed/faded/ducked.
         (path, start, vol, trimLen 0=none, fadeIn, fadeOut) */
      let f2 = v => Js.Float.toFixedWithPrecision(v, ~digits=2)
      let music = base ++ "/audio/music/"
      let voTracks = schedule->Belt.Array.map(((mp3, start)) => (mp3, start, 1.0, 0.0, 0.0, 0.0))
      /* music disabled (user call, 2026-07-15) — the beds stay on disk as
         stems; re-enabling is a re-mux, never a re-render */
      ignore(music)
      let tracks = voTracks
      let nA = Belt.Array.length(tracks)
      let ins = tracks->Belt.Array.joinWith("", ((mp3, _, _, _, _, _)) => " -i \"" ++ mp3 ++ "\"")
      let delays =
        tracks
        ->Belt.Array.mapWithIndex((k, (_, start, vol, trimLen, fadeIn, fadeOut)) => {
          let ms = Belt.Int.toString(Belt.Float.toInt(start *. 1000.0))
          let steps = []
          if trimLen > 0.0 {
            Js.Array2.push(steps, "atrim=0:" ++ f2(trimLen) ++ ",asetpts=PTS-STARTPTS")->ignore
          }
          if fadeIn > 0.0 {
            Js.Array2.push(steps, "afade=t=in:d=" ++ f2(fadeIn))->ignore
          }
          if fadeOut > 0.0 && trimLen > 0.0 {
            Js.Array2.push(steps, "afade=t=out:st=" ++ f2(trimLen -. fadeOut) ++ ":d=" ++ f2(fadeOut))->ignore
          }
          if vol != 1.0 {
            Js.Array2.push(steps, "volume=" ++ f2(vol))->ignore
          }
          Js.Array2.push(steps, "adelay=" ++ ms ++ "|" ++ ms)->ignore
          "[" ++
          Belt.Int.toString(k + 1) ++
          ":a]" ++
          steps->Belt.Array.joinWith(",", x => x) ++
          "[a" ++ Belt.Int.toString(k) ++ "]"
        })
        ->Belt.Array.joinWith(";", x => x)
      let labels = Belt.Array.makeBy(nA, k => "[a" ++ Belt.Int.toString(k) ++ "]")->Belt.Array.joinWith("", x => x)
      let filter =
        delays ++
        ";" ++
        labels ++
        "amix=inputs=" ++
        Belt.Int.toString(nA) ++
        ":duration=longest:normalize=0,loudnorm=I=-16:LRA=11:TP=-1.5,alimiter=limit=0.97[out]"
      sh(
        "/opt/homebrew/bin/ffmpeg -y -loglevel error -i \"" ++
        vtmp ++ "\"" ++
        ins ++
        " -filter_complex \"" ++
        filter ++ "\" -map 0:v -map \"[out]\" -c:v copy -c:a aac -b:a 160k -shortest \"" ++ out ++ "\"",
      )
      Js.log("FINAL -> " ++ out)
      Js.log("runtime ~" ++ Js.Float.toFixedWithPrecision(clock.contents, ~digits=0) ++ "s")
    }
  }
}
main()->ignore
