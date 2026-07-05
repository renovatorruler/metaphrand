/* SKY KING — generic TABLE-READ audio for judging a scene BY EAR (the user
   reviews by listening, not reading). Reads a gated <id>.scene.txt via
   Write.read (verify-then-parse, so only a real gated scene is voiced): Brian
   narrates the ACTION lines, the cast voices the dialogue, (RADIO) lines are
   radioized. NO music bed - this is for evaluating the writing + the voices.
   Run: node src/Cinema_SkySceneRead.res.mjs <scene-id>  (e.g. sky-king-late) */
open Cinema_Backends

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"
let tmp = dir ++ "/tableread_rs"
let cache = tmp ++ "/cache"

@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external exit: int => unit = "exit"

let narr = VoiceId("nPczCjzI2devNBz1zQrb") // Brian — narrator (action lines)
let bill = VoiceId("pqHfZKP75CvOlQylNhV4") // Bill — radio callers / unknown

/* one voice per Sky King speaker; unknown/radio names fall to Bill. */
let voiceFor = who =>
  switch Js.String2.trim(Js.String2.toUpperCase(who)) {
  /* full American cast, distinct (no collisions). Birdy chosen via audition. */
  | "BIRDY" => VoiceId("VZcBEw9QXVSghzV5UKLN") // Michael Joshua — calm, plain, relatable everyman (CHOSEN)
  | "MAYA" => VoiceId("hpp4J3VqNfWAUOO0d1Us") // Bella — middle-aged, warm
  | "DORIS" => VoiceId("wGcFBfKz5yUQqhqr0mVy") // Maria Moody — octogenarian, older (CHOSEN)
  | "REYES" => VoiceId("lVpo6IOLjDX4LxkYRZyj") // Deborah — authoritative American female (federal agent; returns Act 3)
  | "COLE" => VoiceId("EGvjD0PIKVzXUvyMkwel") // Cevin — blunt, Detroit (crude FBI agent; the short-bus lampshade)
  | "SHAW" => VoiceId("XrExE9yKIg1WjnnlVkGX") // Matilda — professional American female (field agent at Maya's door; placeholder)
  | "ARTHUR" => bill // next-room patient, one line
  | "DEZ" => VoiceId("mWRBtRP92mUXZzi4RZ0Y") // Blake — thoughtful late-20s (younger/beta to Birdy; deliver hesitant, deferential)
  | "TANNER" => VoiceId("IkksQWAjbvt9CKa7hRkh") // Weissman — eager, nerdy (CHOSEN)
  | "GUS" => VoiceId("0GKwxxcRYcg0OlQ1l822") // David (Texan) — the fuel guy
  | "WARD" => VoiceId("CwhRBWXzGAHq8TQ4Fs17") // Roger — laid-back, resonant, worn boss
  | "DEACON" => VoiceId("DNKm8TNHmk5sujtJn8zk") // Ed Mathews — American, slight New England (CHOSEN)
  | "BANJO" => VoiceId("KjZZHIOnbFqvGnNEwISh") // Matthew — Californian young (CHOSEN)
  | "TOWER" => VoiceId("2GuF5ZgBYwz69Rmc9gM2") // Connery — measured, composed (CHOSEN); radio'd
  | "SUPERVISOR" => VoiceId("JcwFVpR60FiOW4cPEqI2") // Gunner — authoritative middle-aged (RECAST 2026-07-02; Ray rejected as breathy)
  | "VOSS" => VoiceId("TTyZrDYo6LQowrH8mixJ") // Joseph Ortman — deep, raspy, weathered veteran (FBI driver)
  | "MERCER" => VoiceId("dIa7afHH94O36L8tjJ0L") // Dejuan — calm, precise, "trusted government" (SAC; PLACEHOLDER pending user ear)
  | "CONTROLLER" => VoiceId("2GuF5ZgBYwz69Rmc9gM2") // Connery — command-net relay voice (radioized via tag)
  | "RADIO" => VoiceId("pqHfZKP75CvOlQylNhV4") // Bill — disembodied comms voice (base klaxon / command net; radio-filtered)
  | "BISHOP" => VoiceId("PKu46bbccMP1b22TyeI0") // Jacob Michael — warm Midwestern baritone (CHOSEN)
  | "PRICE" => VoiceId("lVwI5jj77lJwTyfW90VR") // BlueAshby — 30-40s, clean authoritative (CHOSEN 2026-07-02; Jim rejected as breathy)
  | "KEMP" => VoiceId("GxEkXZFVTiRn1HdPNqar") // Phil — articulate 40s professional (DHS liaison; PLACEHOLDER, audition if flagged)
  | _ => VoiceId("SAz9YHcvj6GT2YYXdXww") // River — neutral radio / unknown callers
  }

let key = (VoiceId(v), txt) => {
  let san = (v ++ "_" ++ txt)->Js.String2.replaceByRe(%re("/[^A-Za-z0-9]/g"), "")
  Js.String2.slice(san, ~from=0, ~to_=40) ++ "_" ++ Belt.Int.toString(Js.String2.length(txt))
}
/* delivery effect per line: clean, aviation radio, or the terminal PA tannoy. */
type fx = Clean | Radio | Pa

let renderSeg = async (vc, txt, fx) => {
  let k = key(vc, txt)
  let base = Path(cache ++ "/" ++ k ++ ".mp3")
  if !exists(base) {
    let b = await tts(~text=Text(txt), ~voice=vc)
    let _ = writeBytes(base, b)
  }
  switch fx {
  | Clean => base
  | Radio => {
      let r = Path(cache ++ "/" ++ k ++ ".radio.mp3")
      if !exists(r) {
        let _ = Cinema_Audio.radioize(base)
      }
      r
    }
  | Pa => {
      let p = Path(cache ++ "/" ++ k ++ ".pa.mp3")
      if !exists(p) {
        let _ = Cinema_Audio.paize(base)
      }
      p
    }
  }
}
/* voices forced through the radio filter even untagged. BISHOP removed 2026-07-02:
   he now appears IN-ROOM (the dot scene) — his radio moments carry explicit
   (RADIO) tags in the scene text instead. DEACON/BANJO REMOVED 2026-07-05 (user:
   they were radio-filtered even IN PERSON in the ready room / on the ramp) — they
   are SEEN in person (base, intercept ramp) and heard on radio (airborne), so they
   rely on explicit (RADIO) tags per line, never the blanket list. radioChars is
   ONLY for truly-disembodied voices never seen in person. */
let radioChars = ["TOWER", "RADIO", "CONTROLLER"]
let isRadio = who =>
  Belt.Array.some(radioChars, c => c == Js.String2.trim(Js.String2.toUpperCase(who)))

let segOf = sp =>
  switch sp {
  | Write.Action(t) => (narr, t, Clean)
  | Write.Dialogue({who, radio, text, whisper}) => {
      let w = Js.String2.trim(Js.String2.toUpperCase(who))
      let fx = w == "PA" ? Pa : radio || isRadio(who) ? Radio : Clean
      (voiceFor(who), (whisper ? "[whispering] " : "") ++ text, fx)
    }
  }

/* optional per-scene PERFORMANCE overlay: <id>.perform.json = { "<lineIndex>":
   "[tag][tag]" } — eleven_v3 expression tags prepended at RENDER time only, so
   the scene text (and its receipt hash) stays clean. Absent file = flat read. */
let perfFor = id => {
  let p = Path(dir ++ "/" ++ id ++ ".perform.json")
  if exists(p) {
    switch Js.Json.parseExn(readText(p))->Js.Json.decodeObject {
    | Some(o) =>
      o
      ->Js.Dict.entries
      ->Belt.Array.keepMap(((k, v)) => Js.Json.decodeString(v)->Belt.Option.map(s => (k, s)))
      ->Js.Dict.fromArray
    | None => Js.Dict.empty()
    }
  } else {
    Js.Dict.empty()
  }
}
let rec renderAll = async (segs, i, acc) =>
  if i >= Belt.Array.length(segs) {
    acc
  } else {
    let (v, t, r) = Belt.Array.getExn(segs, i)
    let sp = await renderSeg(v, t, r)
    let beat = silence(Millis(600), Path(tmp))
    await renderAll(segs, i + 1, Belt.Array.concatMany([acc, [sp, beat]]))
  }

let main = async () => {
  let id = Belt.Array.get(argv, 2)->Belt.Option.getWithDefault("")
  if id == "" {
    Js.log("usage: node src/Cinema_SkySceneRead.res.mjs <scene-id>")
  } else {
    switch Write.read(Path(dir ++ "/" ++ id ++ ".scene.txt")) {
    | Error(m) => Js.log("REFUSED — scene did not verify: " ++ m)
    | Ok(lns) =>
      /* CASTING GATE (user law): no default voice for a NAMED character — every
         speaker must be deliberately cast in voiceFor. System voices (PA) are
         allowlisted. Refuses the render instead of shipping an uncast voice. */
      let sysVoices = ["PA"]
      let defaultVoice = "SAz9YHcvj6GT2YYXdXww"
      let uncast = lns->Belt.Array.reduce([], (acc, sp) =>
        switch sp {
        | Write.Dialogue({who}) => {
            let w = Js.String2.trim(Js.String2.toUpperCase(who))
            let VoiceId(v) = voiceFor(w)
            if (
              v == defaultVoice &&
              !Belt.Array.some(sysVoices, s => s == w) &&
              !Belt.Array.some(acc, s => s == w)
            ) {
              Belt.Array.concat(acc, [w])
            } else {
              acc
            }
          }
        | Write.Action(_) => acc
        }
      )
      if Belt.Array.length(uncast) > 0 {
        Js.log(
          "REFUSED — uncast named speakers (no default voices for named characters): " ++
          Belt.Array.joinWith(uncast, ", ", x => x) ++
          ". Cast them in voiceFor (audition if needed) before rendering.",
        )
        exit(1)
      }
      let perf = perfFor(id)
      let tagOf = i => Js.Dict.get(perf, Belt.Int.toString(i))->Belt.Option.getWithDefault("")
      if Belt.Array.length(Js.Dict.keys(perf)) > 0 {
        Js.log(
          "PERFORMANCE overlay: " ++
          Belt.Int.toString(Belt.Array.length(Js.Dict.keys(perf))) ++ " tagged lines",
        )
      }
      /* PERFORM LINT (user law, studio/PERFORMANCE.md): soft/breathy tags belong
         only to soft characters — professionals get crisp-untagged procedure and
         [tense]/[serious] reactions. Warns; taste can override deliberately. */
      let softTagRe = %re("/\[(quietly|softly|calm|calmly|gently|whisper|whispering)\]/i")
      let softOk = ["BIRDY", "MAYA", "DORIS"]
      lns->Belt.Array.forEachWithIndex((i, sp) =>
        switch sp {
        | Write.Dialogue({who}) => {
            let w = Js.String2.trim(Js.String2.toUpperCase(who))
            let tg = tagOf(i)
            if tg != "" && Js.Re.test_(softTagRe, tg) && !Belt.Array.some(softOk, s => s == w) {
              Js.log(
                "PERFORM LINT: soft tag " ++
                tg ++
                " on " ++
                w ++
                " (line " ++
                Belt.Int.toString(i) ++ ") — pros play crisp/tense, see studio/PERFORMANCE.md",
              )
            }
          }
        | Write.Action(_) => ()
        }
      )
      let segs = lns->Belt.Array.mapWithIndex((i, sp) => {
        let (v, t, r) = segOf(sp)
        let tg = tagOf(i)
        (v, tg == "" ? t : tg ++ " " ++ t, r)
      })
      let withBeats = await renderAll(segs, 0, [])
      let parts = Belt.Array.slice(withBeats, ~offset=0, ~len=Belt.Array.length(withBeats) - 1)
      let out = dir ++ "/" ++ id ++ "_tableread.mp3"
      let _ = concatAudio(parts, Path(out))
      let Seconds(d) = durationSec(Path(out))
      Js.log(
        "TABLE READ -> " ++
        out ++
        "  (" ++
        Belt.Int.toString(Belt.Array.length(lns)) ++
        " lines, " ++
        Js.Float.toFixedWithPrecision(d, ~digits=1) ++ "s)",
      )
    }
  }
  exit(0)
}
main()->ignore
