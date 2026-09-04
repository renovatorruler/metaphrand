// KukuEp12_TableRead.res — the «द से दीया» table read.
//
// One take per line, eleven_v3, with each line's Hindi performance parenthetical
// carried through as an audio tag (SERIES LAW 2: every line has one, and they map
// to v3 voice tags at recording). Voices come from Kuku_Cast, which is locked —
// a table read that invents a voice is not a table read of this show.
//
// Takes are cached by content: a line already synthesised at this exact text and
// voice is reused, so a re-run costs nothing. ElevenLabs is a metered service on
// its own bill, so nothing here re-fires a call whose response has not returned.
//
//   node src/KukuEp12_TableRead.res.mjs          # synth missing takes, then assemble
//   node src/KukuEp12_TableRead.res.mjs --dry    # list the lines and their voices

@module("fs") external readFileSync: (string, string) => string = "readFileSync"
@module("fs") external writeFileSync: (string, string) => unit = "writeFileSync"
@module("fs") external existsSync: string => bool = "existsSync"
@module("fs") external mkdirSync: (string, {"recursive": bool}) => unit = "mkdirSync"
@module("process") external cwd: unit => string = "cwd"
@module("process") external argv: array<string> = "argv"

module B = Cinema_Backends

let root = cwd() ++ "/../stories/kuku/ep12/"
let cueFile = root ++ "cue_index.json"
let outDir = root ++ "table_read/"
let cuesDir = outDir ++ "cues/"

type cue = {shot: string, who: string, direction: string, text: string}
/* पापा joins the cast in v5; Kuku_Cast already holds his locked voice. */

let cues: array<cue> = {
  let raw = Js.Json.parseExn(readFileSync(cueFile, "utf8"))
  let arr = raw->Js.Json.decodeArray->Belt.Option.getWithDefault([])
  Js.Array2.map(arr, j => {
    let o = j->Js.Json.decodeObject->Belt.Option.getWithDefault(Js.Dict.empty())
    let g = k =>
      Js.Dict.get(o, k)->Belt.Option.flatMap(Js.Json.decodeString)->Belt.Option.getWithDefault("")
    {shot: g("shot"), who: g("who"), direction: g("direction"), text: g("text")}
  })
}

/* «सब» is the five children together — a chorus, not a voice. It reads on कुकु's
   voice for the table read; the mix comes later. */
let roleOf = who => who == "सब" ? "कुकु" : who

let voiceOf = who =>
  switch Kuku_Cast.voiceOf(
    Kuku_Cast.mimicVoiceKey(roleOf(who))->Belt.Option.getWithDefault(roleOf(who)),
  ) {
  | Some(v) => v
  | None => Js.Exn.raiseError("no locked Kuku voice for " ++ who)
  }

/* The performance parenthetical becomes a v3 audio tag in front of the line. */
let directed = c => c.direction == "" ? c.text : "[" ++ c.direction ++ "] " ++ c.text

let pad3 = n => {
  let t = Belt.Int.toString(n)
  Js.String2.length(t) >= 3 ? t : Js.String2.repeat("0", 3 - Js.String2.length(t)) ++ t
}

/* CONTENT-ADDRESSED. A take is named by index, speaker AND a hash of the exact
   words on the locked voice, so an inserted scene can never shift a recorded
   line under a different frame — that is how 43 of 79 lines played under the
   wrong picture in v3. */
let hash = (s: string) => {
  /* djb2 in float arithmetic — no bitwise ops, every intermediate exact in a double */
  let h = ref(5381.0)
  Js.String2.split(s, "")->Js.Array2.forEach(ch => {
    h := mod_float(h.contents *. 33.0 +. Js.String2.charCodeAt(ch, 0), 2147483647.0)
  })
  Js.Float.toString(h.contents)
}
let takeKey = c => hash(voiceOf(c.who) ++ "|" ++ directed(c))
let takePath = (i, c) => cuesDir ++ pad3(i + 1) ++ "_" ++ c.who ++ "_" ++ takeKey(c) ++ ".mp3"

let dry = Js.Array2.includes(argv, "--dry")
let plan = Js.Array2.includes(argv, "--plan")

let main = async () => {
  mkdirSync(cuesDir, {"recursive": true})
  if plan {
    /* spend-free: what a run WOULD do */
    let missing = Js.Array2.reducei(cues, (n, c, i) => existsSync(takePath(i, c)) ? n : n + 1, 0)
    Js.log("plan: " ++ Belt.Int.toString(missing) ++ " takes would be recorded, " ++
      Belt.Int.toString(Js.Array2.length(cues) - missing) ++ " reused")
  } else if dry {
    Js.Array2.forEachi(cues, (c, i) =>
      Js.log(
        pad3(i + 1) ++ "  " ++ c.shot ++ "  " ++
        c.who ++ "  (" ++ c.direction ++ ")  " ++ c.text,
      )
    )
    Js.log(Belt.Int.toString(Js.Array2.length(cues)) ++ " lines")
  } else {
    let made = ref(0)
    let reused = ref(0)
    /* strictly sequential: one metered call at a time, each awaited */
    let rec go = async i =>
      if i < Js.Array2.length(cues) {
        let c = Js.Array2.unsafe_get(cues, i)
        let dst = takePath(i, c)
        if existsSync(dst) {
          reused := reused.contents + 1
        } else {
          let blob = await B.tts(~text=B.Text(directed(c)), ~voice=B.VoiceId(voiceOf(c.who)))
          ignore(B.writeBytes(B.Path(dst), blob))
          made := made.contents + 1
          Js.log("take " ++ Belt.Int.toString(i + 1) ++ "  " ++ c.who ++ "  " ++ c.text)
        }
        await go(i + 1)
      }
    await go(0)
    Js.log(
      "table read: " ++ Belt.Int.toString(made.contents) ++ " new takes, " ++
      Belt.Int.toString(reused.contents) ++ " reused",
    )
  }
}

let () = ignore(main())
