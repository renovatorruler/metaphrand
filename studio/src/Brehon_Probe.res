/* One-off probe: which element actually scrolls on the Brehon prototype's
   long screens, and does programmatic scrollTop stick?
   Run: node src/Brehon_Probe.res.mjs */
type chromiumT
type browser
type context
type page
@module("playwright") external chromium: chromiumT = "chromium"
@send external launch: (chromiumT, 'o) => promise<browser> = "launch"
@send external newContext: (browser, 'o) => promise<context> = "newContext"
@send external ctxNewPage: context => promise<page> = "newPage"
@send external browserClose: browser => promise<unit> = "close"
@send external goto: (page, string, 'o) => promise<unit> = "goto"
@send external waitForTimeout: (page, int) => promise<int> = "waitForTimeout"
@send external evaluate: (page, string) => promise<string> = "evaluate"

let base = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/brehon"

let probe = "(function(){" ++
  "var out=[];" ++
  "var els=document.querySelectorAll('*');" ++
  "for(var i=0;i<els.length;i++){var e=els[i];" ++
  "if(e.scrollHeight>e.clientHeight+40&&e.clientHeight>200){" ++
  "e.scrollTop=120;var stuck=e.scrollTop;" ++
  "out.push((e.className||e.tagName)+' sh='+e.scrollHeight+' ch='+e.clientHeight+' scrollTop(120)->'+stuck);" ++
  "e.scrollTop=0;}}" ++
  "return JSON.stringify(out);})()"

let main = async () => {
  let browser = await launch(chromium, {"headless": true})
  let ctx = await newContext(browser, {"viewport": {"width": 390, "height": 844}, "deviceScaleFactor": 2})
  let page = await ctxNewPage(ctx)
  await goto(page, "file://" ++ base ++ "/prototype.html", {"waitUntil": "load"})
  let _ = await waitForTimeout(page, 100)
  let screens = [
    ("thread", "go('thread', {thread:'pizza'})"),
    ("casedetail", "go('casedetail', {case:'AB12CD'})"),
    ("transcript", "go('transcript', {case:'QF83RN'})"),
  ]
  let n = Belt.Array.length(screens)
  let rec go_ = async i =>
    if i < n {
      let (name, call) = Belt.Array.getExn(screens, i)
      let _ = await evaluate(page, call)
      let _ = await waitForTimeout(page, 400)
      let r = await evaluate(page, probe)
      Js.log("== " ++ name ++ " ==\n" ++ r)
      await go_(i + 1)
    }
  await go_(0)
  await browserClose(browser)
}
main()->ignore
