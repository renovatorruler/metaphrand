/* BREHON walkthrough — silent capture. Drives the prototype's own go() router
   beat by beat (the script's Screen lines are literal calls), records one
   continuous Playwright video with narration-estimated holds, logs each
   beat's timestamp (the cut sheet for the audio mix later), and converts to
   MP4. No audio, no model calls — the pacing preview.
   Run: node src/Brehon_Capture.res.mjs */

type chromiumT
type browser
type context
type page
type video
@module("playwright") external chromium: chromiumT = "chromium"
@send external launch: (chromiumT, 'o) => promise<browser> = "launch"
@send external newContext: (browser, 'o) => promise<context> = "newContext"
@send external ctxNewPage: context => promise<page> = "newPage"
@send external ctxClose: context => promise<unit> = "close"
@send external browserClose: browser => promise<unit> = "close"
@send external goto: (page, string, 'o) => promise<unit> = "goto"
@send external waitForTimeout: (page, int) => promise<unit> = "waitForTimeout"
@send external evaluate: (page, string) => promise<'a> = "evaluate"

@module("fs") external writeFileSync: (string, 'a) => unit = "writeFileSync"
@val @scope("Buffer") external bufferFrom: 'a => 'b = "from"
@module("fs") external readdirSync: string => array<string> = "readdirSync"
@module("fs") external mkdirSync: (string, 'a) => unit = "mkdirSync"
@module("child_process") external execSync: (string, 'a) => 'b = "execSync"

let base = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/brehon"
let vidDir = base ++ "/capture"
let out = base ++ "/BREHON-WALKTHROUGH_2026-07-15_v2_silent.mp4"

let sh = (cmd: string): unit => {
  let opts = Js.Dict.empty()
  Js.Dict.set(opts, "stdio", Obj.magic("pipe"))
  let _ = execSync(cmd, opts)
}

/* (beatId, doc, jsCall, holdMs) — holds estimated from narration word count
   (~2.5 wps + pad); the audio render replaces these with measured lengths. */
type doc = Preroll | Proto
let beats = [
  ("b0_c1", Preroll, "showCard(1)", 16000),
  ("b0_c2", Preroll, "showCard(2)", 14000),
  ("b0_c3", Preroll, "showCard(3)", 16000),
  ("b0_c4", Preroll, "showCard(4)", 14000),
  ("b1_record", Proto, "go('casedetail', {case:'AB12CD'})", 24000),
  ("b2_signin", Proto, "go('signin', {})", 6000),
  ("b3_game", Proto, "go('onboarding', {step:'game'})", 4000),
  ("b3_rule", Proto, "go('onboarding', {step:'game', phase:'rule'})", 13000),
  ("b4_jaws", Proto, "go('onboarding', {step:'game', phase:'attempt'})", 26000),
  ("b5_rate", Proto, "go('onboarding', {step:'game', phase:'rate'})", 10000),
  ("b6_reveal", Proto, "go('onboarding', {step:'game', phase:'reveal', choice:'BROKEN'})", 20000),
  ("b7_mark", Proto, "filled.onbName = true; go('onboarding', {step:'mark'})", 12000),
  ("b7_wand", Proto, "go('onboarding', {step:'wand'})", 11000),
  ("b8_thread", Proto, "go('thread', {thread:'pizza'})", 18000),
  ("b9_demand", Proto, "startChallenge('pizza', 0); go('challenge', {thread:'pizza', attemptidx:0, step:'demand'})", 18000),
  ("b10_bond", Proto, "startChallenge('pizza', 0); go('challenge', {thread:'pizza', attemptidx:0, step:'surety'})", 20000),
  ("b11_transcript", Proto, "go('transcript', {case:'QF83RN'})", 16000),
  ("b12_ruling", Proto, "go('casedetail', {case:'SB63KH'})", 36000),
  ("b13_return", Proto, "go('casedetail', {case:'AB12CD'})", 26000),
]

/* auto-scroll any screen whose content runs past the fold: hold the top,
   glide to the bottom over the beat, settle. Fire-and-forget inside the page;
   smoothstep ease. holdMs is baked into the snippet per beat. */
let scroller = (holdMs: int): string => {
  let hold = Belt.Int.toString(holdMs)
  "(function(){" ++
  "var cands=Array.prototype.slice.call(document.querySelectorAll('.screen,.folio,.feed'));" ++
  "var sc=null;for(var i=0;i<cands.length;i++){var e=cands[i];if(e.scrollHeight>e.clientHeight+40&&e.offsetParent){sc=e;break;}}" ++
  "if(!sc)return 0;" ++
  "var dist=sc.scrollHeight-sc.clientHeight;" ++
  "var delay=1800,tail=1400,dur=" ++ hold ++ "-delay-tail;if(dur<800)dur=800;" ++
  "var t0=null;" ++
  "function step(ts){if(!t0)t0=ts;var p=(ts-t0)/dur;if(p>1)p=1;var e=p*p*(3-2*p);sc.scrollTop=dist*e;if(p<1)requestAnimationFrame(step);}" ++
  "setTimeout(function(){requestAnimationFrame(step);},delay);" ++
  "return dist;})()"
}

let main = async () => {
  mkdirSync(vidDir, {"recursive": true})
  let browser = await launch(chromium, {"headless": true})
  /* 780x1688 viewport = a 390x844 phone at 2x. The prototype is scaled up
     via CSS transform (crisp vector re-raster), with height:50dvh
     compensating the doubled dvh box — zoom broke dvh, and Playwright
     letterboxes rather than upscales a small viewport. */
  let ctx = await newContext(
    browser,
    {
      "viewport": {"width": 780, "height": 1688},
      "recordVideo": {"dir": vidDir, "size": {"width": 780, "height": 1688}},
    },
  )
  let page = await ctxNewPage(ctx)

  /* cut sheet: beat -> (startMs, holdMs) into the recording */
  let cuts = []
  let clock = ref(0)
  let current = ref(Preroll)
  /* preroll is natively 960-wide; zoom applies to the prototype only */
  await goto(page, "file://" ++ base ++ "/preroll.html", {"waitUntil": "load"})
  /* small settle before the first card so the cut sheet stays honest */
  await waitForTimeout(page, 500)
  clock := 500

  let n = Belt.Array.length(beats)
  let rec go_ = async i =>
    if i < n {
      let (id, doc, call, hold) = Belt.Array.getExn(beats, i)
      if doc != current.contents {
        await goto(page, "file://" ++ base ++ "/prototype.html", {"waitUntil": "load"})
        let _ = await evaluate(
          page,
          "(function(){var s=document.createElement('style');" ++
          "s.textContent='.app{max-width:390px;height:50dvh;transform:scale(2);transform-origin:top center;}';" ++
          "document.head.appendChild(s);return 1;})()",
        )
        current := doc
        clock := clock.contents + 400 /* navigation costs ~a beat; measured roughly */
        await waitForTimeout(page, 400)
      }
      let _ = await evaluate(page, call)
      /* long screens glide to the bottom during the hold */
      if doc == Proto {
        let _ = await evaluate(page, scroller(hold))
      }
      Js.Array2.push(cuts, (id, clock.contents, hold))->ignore
      await waitForTimeout(page, hold)
      clock := clock.contents + hold
      await go_(i + 1)
    }
  await go_(0)

  await ctxClose(ctx)
  await browserClose(browser)

  /* newest webm in capture dir */
  let webms = readdirSync(vidDir)->Belt.Array.keep(f => Js.String2.endsWith(f, ".webm"))
  switch webms->Belt.Array.get(Belt.Array.length(webms) - 1) {
  | None => Js.log("NO VIDEO RECORDED")
  | Some(w) => {
      /* standard 9:16 phone canvas: scale to full height, thin side bars */
      sh(
        "/opt/homebrew/bin/ffmpeg -y -loglevel error -i \"" ++
        vidDir ++ "/" ++ w ++
        "\" -vf \"scale=-2:1920,pad=1080:1920:(ow-iw)/2:0:black\" -c:v libx264 -pix_fmt yuv420p -r 30 -crf 20 \"" ++
        out ++ "\"",
      )
      let sheet =
        cuts
        ->Belt.Array.map(((id, start, hold)) =>
          `{"beat":"${id}","startMs":${Belt.Int.toString(start)},"holdMs":${Belt.Int.toString(hold)}}`
        )
        ->Belt.Array.joinWith(",\n  ", x => x)
      writeFileSync(base ++ "/capture_cuts_v1.json", bufferFrom("[\n  " ++ sheet ++ "\n]"))
      Js.log("SILENT MP4 -> " ++ out)
      Js.log("CUT SHEET -> capture_cuts_v1.json (" ++ Belt.Int.toString(clock.contents / 1000) ++ "s total)")
    }
  }
}
main()->ignore
