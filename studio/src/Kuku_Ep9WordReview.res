/* कुकु और अक्षर EP9 — the end-of-episode word review.

   The show's closing ritual: every word the episode taught with ब, each shown as a picture
   with the word beside it, and Dadi naming it. The parent's one instruction about pacing —
   "make sure to not rush it, give it enough time so that kids can read it" — is why each
   card holds for 7 seconds: roughly 1s for the picture to land, the word spoken about a
   second in, then four-plus seconds of silence with the word still on screen. A child who
   is sounding it out gets to finish.

   Audio: Dadi's locked voice for the words (-17 LUFS like all cast lines), over one gentle
   bed at -26 LUFS, same mixing rules as the episode.

   Run from studio/:  node src/Kuku_Ep9WordReview.res.mjs */

open Cinema_Backends

@val @scope("process") external exitProcess: int => unit = "exit"
@module("node:path") external resolve2: (string, string) => string = "resolve"

let finale = "../stories/kuku/ep9prod/finale"
let cardDir = finale ++ "/local/review_cards"
let voiceDir = finale ++ "/audio/word_review"
let outPath = finale ++ "/out/EP9_WORD_REVIEW_720P_V1.mp4"

/* (word, image basename) — the five ब words the episode lives */
let words: array<(string, string)> = [
  ("बच्चा", "WORD_baccha"),
  ("बड़ा", "WORD_bada"),
  ("बादल", "WORD_badal"),
  ("बकरी", "WORD_bakri"),
  ("बचाना", "WORD_bachana"),
]

let holdSeconds = 7
let dadiVoice = switch Kuku_Cast.voiceOf("DADI") {
| Some(v) => v
| None => "nfMYisZqs1GOjTFllho3"
}

let present = (p, minBytes) => exists(p) && fileSizeMb(p) *. 1.0e6 > minBytes

let main = async () => {
  ensureDirPath(Path(voiceDir))
  ensureDirPath(Path(cardDir))
  ensureDirPath(Path(finale ++ "/out"))

  /* 1. Dadi names each word, unhurried */
  for i in 0 to Belt.Array.length(words) - 1 {
    switch Belt.Array.get(words, i) {
    | None => ()
    | Some((word, slug)) => {
        let out = Path(voiceDir ++ "/" ++ slug ++ ".mp3")
        if !present(out, 2000.0) {
          let rawPath = voiceDir ++ "/." ++ slug ++ ".raw.mp3"
          let outStr = voiceDir ++ "/" ++ slug ++ ".mp3"
          let blob = await tts(~text=Text(word ++ "।"), ~voice=VoiceId(dadiVoice))
          let _ = writeBytes(Path(rawPath), blob)
          ffmpeg([
            "-y", "-v", "error", "-i", rawPath,
            "-af", "loudnorm=I=-17:TP=-1.5:LRA=11",
            "-c:a", "libmp3lame", "-q:a", "3", outStr,
          ])
          removeFile(Path(rawPath))
          Js.log("  voice OK " ++ word)
        }
      }
    }
  }

  /* 2. one gentle bed for the whole segment */
  let bed = finale ++ "/audio/score/cue11_word_review.mp3"
  if !present(Path(bed), 20000.0) {
    let blob = await music(
      ~prompt=Prompt(
        "Very gentle, simple, unhurried cue for a preschool learning segment: soft music-box " ++
        "and a light bansuri phrase over sparse warm santoor, calm and patient with plenty of " ++
        "space between notes, nothing urgent or busy — room for a child to think. " ++
        "Fully instrumental, no voices, no lyrics.",
      ),
      ~ms=Millis((holdSeconds * Belt.Array.length(words) + 3) * 1000),
      ~instrumental=true,
    )
    let _ = writeBytes(Path(bed), blob)
    let tmp = finale ++ "/audio/score/.cue11.tmp.mp3"
    ffmpeg([
      "-y", "-v", "error", "-i", bed,
      "-af", "loudnorm=I=-26:TP=-1.5:LRA=11",
      "-c:a", "libmp3lame", "-q:a", "3", tmp,
    ])
    copyFile(Path(tmp), Path(bed))
    removeFile(Path(tmp))
    Js.log("  bed generated and levelled to -26 LUFS")
  }

  /* 3. one 7s segment per word: picture left, word right, voice ~1s in */
  let segments = words->Belt.Array.mapWithIndex((i, (_, slug)) => {
    let card = cardDir ++ "/" ++ slug ++ ".png"
    if !exists(Path(card)) {
      raise(BackendError("card not composed yet: " ++ card))
    }
    let seg = cardDir ++ "/seg_" ++ Belt.Int.toString(i) ++ ".mp4"
    ffmpeg([
      "-nostdin", "-v", "error", "-y",
      "-loop", "1", "-framerate", "24", "-t", Belt.Int.toString(holdSeconds), "-i", card,
      "-i", voiceDir ++ "/" ++ slug ++ ".mp3",
      "-filter_complex",
      "[0:v]scale=1280:720,setsar=1,fade=t=in:st=0:d=0.4," ++
      "fade=t=out:st=" ++ Js.Float.toString(Belt.Int.toFloat(holdSeconds) -. 0.4) ++ ":d=0.4[v];" ++
      "[1:a]aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo," ++
      "adelay=delays=1000:all=1,apad=whole_dur=" ++ Belt.Int.toString(holdSeconds) ++
      ",atrim=0:" ++ Belt.Int.toString(holdSeconds) ++ "[a]",
      "-map", "[v]", "-map", "[a]",
      "-c:v", "libx264", "-preset", "slow", "-crf", "19", "-pix_fmt", "yuv420p", "-r", "24",
      "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-ac", "2",
      "-t", Belt.Int.toString(holdSeconds), seg,
    ])
    seg
  })

  /* 4. join, then lay the bed under the whole thing */
  let listPath = cardDir ++ "/segments.txt"
  writeText(
    Path(listPath),
    /* the concat demuxer resolves relative paths against the LIST file, not the cwd */
    segments->Belt.Array.map(p => "file '" ++ resolve2(".", p) ++ "'")->Js.Array2.joinWith("\n") ++ "\n",
  )
  let joined = cardDir ++ "/joined.mp4"
  ffmpeg([
    "-nostdin", "-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", listPath,
    "-c", "copy", joined,
  ])
  let total = holdSeconds * Belt.Array.length(words)
  ffmpeg([
    "-nostdin", "-v", "error", "-y", "-i", joined, "-i", bed,
    "-filter_complex",
    "[1:a]aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo," ++
    "afade=t=in:st=0:d=1.5,afade=t=out:st=" ++ Belt.Int.toString(total - 2) ++ ":d=2[bed];" ++
    "[0:a][bed]amix=inputs=2:duration=first:dropout_transition=0:normalize=0," ++
    "alimiter=limit=0.95[a]",
    "-map", "0:v:0", "-map", "[a]",
    "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-ac", "2",
    "-t", Belt.Int.toString(total), "-movflags", "+faststart", outPath,
  ])
  let Seconds(d) = probeDuration(Path(outPath))
  Js.log("WORD REVIEW: " ++ outPath)
  Js.log(
    "  " ++ Js.Float.toFixedWithPrecision(d, ~digits=1) ++ "s — " ++
    Belt.Int.toString(Belt.Array.length(words)) ++ " words held " ++
    Belt.Int.toString(holdSeconds) ++ "s each",
  )
}

main()
->Js.Promise2.catch(e => {
  Js.log2("WORD REVIEW FAILED:", e)
  exitProcess(1)
  Js.Promise.resolve()
})
->ignore
