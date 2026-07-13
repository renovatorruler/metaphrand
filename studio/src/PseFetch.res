/* PSE fetcher — logs into Pro Sound Effects with the user's username/password
   (PSE page takes the email, Microsoft B2C at identity.prosoundeffects.com
   takes the password on #signInName/#password/#next), reads the FOUR OLDS
   pull list, searches each term, filters to OWNED libraries (learned +
   persisted), and downloads the top takes by capturing each pre-signed Azure
   blob URL and fetching it directly. Resumable; writes a manifest.
   Credentials: ~/.pse_credentials (line 1 email, line 2 password), chmod 600.
   Run: STAR=1 TAKES=2 node src/PseFetch.res.mjs */

/* ---- Playwright bindings (same @module style as Pdf.res) ---- */
type chromiumT
type context
type page
type locator
type request
@module("playwright") external chromium: chromiumT = "chromium"
@send external launchPersistentContext: (chromiumT, string, 'o) => promise<context> = "launchPersistentContext"
@send external ctxPages: context => array<page> = "pages"
@send external ctxNewPage: context => promise<page> = "newPage"
@send external ctxClose: context => promise<unit> = "close"
@send external goto: (page, string, 'o) => promise<unit> = "goto"
@send external locator: (page, string) => locator = "locator"
@send external first: locator => locator = "first"
@send external fill: (locator, string) => promise<unit> = "fill"
@send external clickOpt: (locator, 'o) => promise<unit> = "click"
@send external waitForOpt: (locator, 'o) => promise<unit> = "waitFor"
@send external isVisibleOpt: (locator, 'o) => promise<bool> = "isVisible"
@send external waitForURL: (page, Js.Re.t, 'o) => promise<unit> = "waitForURL"
@send external waitForTimeout: (page, int) => promise<unit> = "waitForTimeout"
@send external evaluate: (page, string) => promise<'a> = "evaluate"
@send external pageOn: (page, string, request => unit) => unit = "on"
@send external pageOff: (page, string, request => unit) => unit = "removeListener"
@send external reqUrl: request => string = "url"
@send external pageUrl: page => string = "url"
@send external screenshot: (page, 'o) => promise<unit> = "screenshot"
@send external innerText: (locator, 'o) => promise<string> = "innerText"
/* Playwright download event (the proven mechanism for launchPersistentContext) */
type download
@send external waitForEvent: (page, string, 'o) => promise<download> = "waitForEvent"
@send external suggestedFilename: download => string = "suggestedFilename"
@send external saveAs: (download, string) => promise<unit> = "saveAs"

/* node fetch for the pre-signed blob URL */
type response
@val external fetch: string => promise<response> = "fetch"
@get external okOf: response => bool = "ok"
@get external statusOf: response => int = "status"
@send external arrayBuffer: response => promise<'ab> = "arrayBuffer"
@val @scope("Buffer") external bufferFrom: 'a => 'b = "from"

@module("fs") external readFileSync: (string, string) => string = "readFileSync"
@module("fs") external writeFileSync: (string, 'a) => unit = "writeFileSync"
@module("fs") external existsSync: string => bool = "existsSync"
@module("fs") external mkdirSync: (string, 'a) => unit = "mkdirSync"
@module("fs") external rmSync: (string, 'o) => unit = "rmSync"
@module("fs") external appendFileSync: (string, string) => unit = "appendFileSync"
@val @scope("process") external env: Js.Dict.t<string> = "env"
@val @scope(("process", "env")) external home: string = "HOME"

let outDir = "/Users/dusty/SFX/PSE/"
let pullPath = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/audio/2026-07-12_PSE_PULL_LIST.md"
let logPath = "/tmp/pse_fetch.log"
let log = s => {
  Js.log(s)
  appendFileSync(logPath, s ++ "\n")
}

let takes = switch Js.Dict.get(env, "TAKES") {
| Some(t) => Belt.Int.fromString(t)->Belt.Option.getWithDefault(2)
| None => 2
}
let starOnly = Js.Dict.get(env, "STAR") == Some("1")
let limit = switch Js.Dict.get(env, "LIMIT") {
| Some(l) => Belt.Int.fromString(l)->Belt.Option.getWithDefault(9999)
| None => 9999
}

/* ---- pull list: backtick queries from numbered lines; ★ = Part One ---- */
let backtick = %re("/`([^`]+)`/g")
let numbered = %re("/^\s*\d+\.\s*(★?)/")
let parsePull = (): array<(bool, string)> => {
  let out = []
  let seen = Js.Dict.empty()
  let lines = Js.String2.split(readFileSync(pullPath, "utf8"), "\n")
  lines->Belt.Array.forEach(line =>
    switch Js.Re.exec_(numbered, line) {
    | None => ()
    | Some(m) => {
        let star =
          Js.Nullable.toOption(Belt.Array.getExn(Js.Re.captures(m), 1))->Belt.Option.getWithDefault(
            "",
          ) == "★"
        let re = %re("/`([^`]+)`/g")
        let continue = ref(true)
        while continue.contents {
          switch Js.Re.exec_(re, line) {
          | None => continue := false
          | Some(mm) =>
            switch Js.Nullable.toOption(Belt.Array.getExn(Js.Re.captures(mm), 1)) {
            | Some(q) =>
              if Js.Dict.get(seen, q) == None {
                Js.Dict.set(seen, q, true)
                Js.Array2.push(out, (star, q))->ignore
              }
            | None => ()
            }
          }
        }
      }
    }
  )
  ignore(backtick)
  /* star-first */
  let stars = out->Belt.Array.keep(((s, _)) => s)
  let rest = out->Belt.Array.keep(((s, _)) => !s)
  Belt.Array.concat(stars, rest)
}

/* ---- learned library ownership ---- */
let libsPath = outDir ++ "_libs.json"
type libState = {mutable owned: array<string>, mutable unowned: array<string>}
let libs: libState =
  existsSync(libsPath)
    ? Obj.magic(Js.Json.parseExn(readFileSync(libsPath, "utf8")))
    : {owned: [], unowned: []}
let ownedHas = l => libs.owned->Js.Array2.includes(l)
let unownedHas = l => libs.unowned->Js.Array2.includes(l)
let saveLibs = () =>
  writeFileSync(
    libsPath,
    bufferFrom(`{"owned":${Js.Json.stringify(Obj.magic(libs.owned))},"unowned":${Js.Json.stringify(
        Obj.magic(libs.unowned),
      )}}`),
  )
let libRe = %re("/\/sound-effects\/([A-Za-z0-9_]+)\//")
let libOf = href =>
  switch Js.Re.exec_(libRe, href) {
  | Some(m) => Js.Nullable.toOption(Belt.Array.getExn(Js.Re.captures(m), 1))->Belt.Option.getWithDefault("")
  | None => ""
  }

/* ---- login ---- */
let clickIf = async (page, sel) =>
  try await clickOpt(first(locator(page, sel)), {"timeout": 4000}) catch {
  | _ => ()
  }

let isAuthed = async page => {
  try await goto(
    page,
    "https://www.prosoundeffects.com/sound-effects/PSE_CW/XUiJB/moody-winds-vast-dark-whistling",
    {"waitUntil": "domcontentloaded", "timeout": 30000},
  ) catch {
  | _ => ()
  }
  await waitForTimeout(page, 2500)
  try await isVisibleOpt(first(locator(page, "text=Included in your CORE")), {"timeout": 6000}) catch {
  | _ => false
  }
}

let login = async page => {
  let already = await isAuthed(page)
  if already {
    log("already authenticated.")
  } else {
    let creds = Js.String2.split(Js.String2.trim(readFileSync(home ++ "/.pse_credentials", "utf8")), "\n")
    let email = Js.String2.trim(Belt.Array.getExn(creds, 0))
    let password = Js.String2.trim(Belt.Array.getExn(creds, 1))
    await goto(page, "https://www.prosoundeffects.com/login", {"waitUntil": "domcontentloaded", "timeout": 30000})
    await waitForTimeout(page, 2500)
    await clickIf(page, "button:text-is('Accept')")
    await fill(first(locator(page, "input[type=\"email\"], input[type=\"text\"]")), email)
    await waitForTimeout(page, 400)
    try await clickOpt(first(locator(page, "button:text-is('Next')")), {"timeout": 5000}) catch {
    | _ => ()
    }
    /* Microsoft B2C password page */
    await waitForURL(page, %re("/identity\.prosoundeffects\.com/i"), {"timeout": 20000})
    await waitForOpt(first(locator(page, "#password")), {"state": "visible", "timeout": 15000})
    try await fill(first(locator(page, "#signInName")), email) catch {
    | _ => ()
    }
    await fill(first(locator(page, "#password")), password)
    try await clickOpt(first(locator(page, "#next")), {"timeout": 8000}) catch {
    | _ => ()
    }
    await waitForTimeout(page, 4000)
    log("after B2C submit, url: " ++ pageUrl(page))
    try await screenshot(page, {"path": "/tmp/b2c_after_submit.png"}) catch {
    | _ => ()
    }
    /* B2C may show a "Stay signed in?" (KMSI) page — accept it if present */
    await clickIf(page, "#next")
    await clickIf(page, "button:has-text('Yes')")
    try await waitForURL(page, %re("/www\.prosoundeffects\.com/i"), {"timeout": 30000}) catch {
    | _ => ()
    }
    /* the /signin-oidc callback exchanges the code for tokens via MSAL
       (async); poll until the session settles rather than checking once */
    await waitForTimeout(page, 3000)
    let ok = ref(false)
    let tries = ref(0)
    while !ok.contents && tries.contents < 8 {
      let a = await isAuthed(page)
      if a {
        ok := true
      } else {
        await waitForTimeout(page, 3000)
      }
      tries := tries.contents + 1
    }
    if !ok.contents {
      Js.Exn.raiseError("login failed after B2C submit — check ~/.pse_credentials")
    }
    log("authenticated.")
  }
}

/* one-time: learn the CORE Standard library codes (42 of them) from the
   bundle page, so ownership is a fast prefix check instead of a per-sound
   page visit. Codes appear in the library thumbnail URLs (PSE_XXX_512.webp). */
let seedOwned = async page => {
  if Belt.Array.length(libs.owned) == 0 {
    await goto(page, "https://www.prosoundeffects.com/core-7/standard", {"waitUntil": "domcontentloaded", "timeout": 30000})
    await waitForTimeout(page, 2500)
    let s = ref(0)
    while s.contents < 6 {
      let _ = await evaluate(page, "(window.scrollTo(0, document.body.scrollHeight))")
      await waitForTimeout(page, 800)
      s := s.contents + 1
    }
    let codes: array<string> = await evaluate(
      page,
      "([...new Set((document.body.innerHTML.match(/PSE_[A-Z0-9]+/g)||[]))])",
    )
    /* keep the codes but drop the _512 art suffix artifacts (regex already
       stops at non-alnum, so PSE_CW etc. are clean) */
    libs.owned = codes
    saveLibs()
    log("seeded " ++ Belt.Int.toString(Belt.Array.length(codes)) ++ " owned Standard libraries: " ++ codes->Belt.Array.joinWith(" ", x => x))
  }
}

/* ---- search ---- */
/* an IIFE: page.evaluate of a bare arrow string returns the function, not
   its result — invoke it here so we get the array back */
let hrefsJs = "(() => [...new Set([...document.querySelectorAll('a[href*=\"/sound-effects/\"]')].map(a => a.getAttribute('href')).filter(h => /\\/sound-effects\\/[A-Za-z0-9_]+\\/[A-Za-z0-9]+\\//.test(h)))])()"

let tryOne = async (page, words: array<string>) => {
  let url =
    "https://www.prosoundeffects.com/search?type=sounds&" ++
    words->Belt.Array.map(k => "keywords=" ++ Js.Global.encodeURIComponent(k))->Belt.Array.joinWith("&", x => x)
  await goto(page, url, {"waitUntil": "domcontentloaded", "timeout": 30000})
  try await waitForOpt(first(locator(page, "a[href*=\"/sound-effects/\"]")), {"timeout": 9000}) catch {
  | _ => ()
  }
  await waitForTimeout(page, 700)
  /* the results grid lazy-loads on scroll — load several pages of it so
     owned-library sounds surface even when premium libraries rank first */
  let s = ref(0)
  while s.contents < 5 {
    let _ = await evaluate(page, "(window.scrollTo(0, document.body.scrollHeight))")
    await waitForTimeout(page, 900)
    s := s.contents + 1
  }
  let hrefs: array<string> = await evaluate(page, hrefsJs)
  hrefs
}

/* merge broad + narrow searches (both the first-two-words and the first-word
   alone), deduped — so a query lands both specific and owned-flagship hits */
let searchHrefs = async (page, query) => {
  let words =
    Js.String2.split(Js.String2.toLowerCase(Js.String2.trim(query)), " ")->Belt.Array.keep(w =>
      Js.String2.length(w) > 1
    )
  let ladders =
    Belt.Array.length(words) >= 2
      ? [Belt.Array.slice(words, ~offset=0, ~len=2), [Belt.Array.getExn(words, 0)]]
      : [[Belt.Array.getExn(words, 0)]]
  let seen = Js.Dict.empty()
  let merged = []
  let i = ref(0)
  while i.contents < Belt.Array.length(ladders) {
    let h = await tryOne(page, Belt.Array.getExn(ladders, i.contents))
    h->Belt.Array.forEach(href =>
      if Js.Dict.get(seen, href) == None {
        Js.Dict.set(seen, href, true)
        Js.Array2.push(merged, href)->ignore
      }
    )
    i := i.contents + 1
  }
  merged
}

/* ---- download by capturing the signed blob URL ---- */
/* the download IS this blob URL (a pre-signed SAS link); matching the path
   is enough — don't require a specific query param */
let signedRe = %re("/blob\.core\.windows\.net\/library\/(wav|mp3)\//i")
let downloadHref = async (page, href) => {
  let lib = libOf(href)
  if unownedHas(lib) {
    "SKIP" /* library already proven not entitled */
  } else {
    try {
      await goto(page, "https://www.prosoundeffects.com" ++ href, {"waitUntil": "domcontentloaded", "timeout": 30000})
      {
        /* the "Included in your CORE" badge is the fast, accurate ownership
           signal — premium sounds show a $5 buy instead and never download */
        let owned =
          try await isVisibleOpt(first(locator(page, "text=Included in your CORE")), {"timeout": 8000}) catch {
          | _ => false
          }
        if !owned {
          if !unownedHas(lib) {
            libs.unowned = Belt.Array.concat(libs.unowned, [lib])
            saveLibs()
          }
          "NOT OWNED"
        } else {
          if !ownedHas(lib) {
            libs.owned = Belt.Array.concat(libs.owned, [lib])
            saveLibs()
          }
          await waitForTimeout(page, 400)
          let dlP = waitForEvent(page, "download", {"timeout": 20000})
          try await clickOpt(first(locator(page, "button:has-text('Download')")), {"timeout": 8000}) catch {
          | _ => ()
          }
          let dlOpt = try Some(await dlP) catch {
          | _ => None
          }
          switch dlOpt {
          | None => "no-download"
          | Some(dl) => {
              let fname = suggestedFilename(dl)
              let dest = outDir ++ fname
              if existsSync(dest) {
                fname ++ " (existed)"
              } else {
                await saveAs(dl, dest)
                fname
              }
            }
          }
        }
      }
    } catch {
    | _ => "ERR"
    }
  }
}

let bad = s =>
  Js.String2.startsWith(s, "NOT OWNED") ||
  Js.String2.startsWith(s, "SKIP") ||
  Js.String2.startsWith(s, "ERR") ||
  Js.String2.startsWith(s, "no-download") ||
  Js.String2.startsWith(s, "HTTP")

let manPath = outDir ++ "_manifest.json"

let main = async () => {
  mkdirSync(outDir, {"recursive": true})
  /* always start from a clean browser profile — reused MSAL/B2C state makes
     re-login fail intermittently; a fresh profile logs in reliably */
  try rmSync("/Users/dusty/.pse_browser", {"recursive": true, "force": true}) catch {
  | _ => ()
  }
  let ctx = await launchPersistentContext(
    chromium,
    "/Users/dusty/.pse_browser",
    {"headless": Js.Dict.get(env, "HEADED") != Some("1"), "acceptDownloads": true},
  )
  let page = switch ctxPages(ctx)->Belt.Array.get(0) {
  | Some(p) => p
  | None => await ctxNewPage(ctx)
  }
  await login(page)
  ignore(seedOwned)

  let all = parsePull()
  let queries = (starOnly ? all->Belt.Array.keep(((s, _)) => s) : all)->Belt.Array.slice(~offset=0, ~len=limit)
  log(Belt.Int.toString(Belt.Array.length(queries)) ++ " queries, " ++ Belt.Int.toString(takes) ++ " takes each -> " ++ outDir)

  let manifest: Js.Dict.t<array<string>> =
    existsSync(manPath) ? Obj.magic(Js.Json.parseExn(readFileSync(manPath, "utf8"))) : Js.Dict.empty()
  let got = ref(0)
  let miss = ref(0)
  let qi = ref(0)
  let n = Belt.Array.length(queries)
  while qi.contents < n {
    let (star, q) = Belt.Array.getExn(queries, qi.contents)
    let have = Js.Dict.get(manifest, q)->Belt.Option.getWithDefault([])
    if Belt.Array.length(have) >= takes {
      log("  [=] " ++ q)
    } else {
      let hrefs = await searchHrefs(page, q)
      /* drop libraries already proven unowned; try known-owned first, then
         unknowns (which teach us their entitlement) */
      let ranked =
        hrefs
        ->Belt.Array.keep(h => !unownedHas(libOf(h)))
        ->Belt.SortArray.stableSortBy((a, b) =>
          (ownedHas(libOf(b)) ? 1 : 0) - (ownedHas(libOf(a)) ? 1 : 0)
        )
      /* debug: which libraries are on offer for this query */
      let libsSeen = Js.Dict.empty()
      ranked->Belt.Array.forEach(h => Js.Dict.set(libsSeen, libOf(h), true))
      log("      libs: " ++ Js.Dict.keys(libsSeen)->Belt.Array.joinWith(" ", x => x))
      let acc = have
      let checked = ref(0)
      let hi = ref(0)
      while Belt.Array.length(acc) < takes && checked.contents < 24 && hi.contents < Belt.Array.length(ranked) {
        let href = Belt.Array.getExn(ranked, hi.contents)
        let r = await downloadHref(page, href)
        if !bad(r) {
          got := got.contents + 1
          Js.Array2.push(acc, r)->ignore
          log("  [" ++ (star ? "★" : " ") ++ "] " ++ q ++ "  ->  " ++ r)
        } else if r != "SKIP" {
          checked := checked.contents + 1
        }
        hi := hi.contents + 1
      }
      Js.Dict.set(manifest, q, acc)
      if Belt.Array.length(acc) == 0 {
        miss := miss.contents + 1
        log("  [!] " ++ q ++ "  ->  none owned in " ++ Belt.Int.toString(Belt.Array.length(ranked)))
      }
      writeFileSync(manPath, bufferFrom(Js.Json.stringify(Obj.magic(manifest))))
    }
    qi := qi.contents + 1
  }
  log(
    "DONE — " ++
    Belt.Int.toString(got.contents) ++
    " new files, " ++
    Belt.Int.toString(miss.contents) ++
    " empty. owned libs: " ++
    libs.owned->Belt.Array.joinWith(" ", x => x),
  )
  await ctxClose(ctx)
}
main()->ignore
