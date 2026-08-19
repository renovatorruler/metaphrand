/* English narrated table read of the bilingual Episode 1 spec.
   Action and sound-description lines are SPOKEN by the narrator; they are never
   converted into ElevenLabs sound-event tags. Dialogue keeps the established
   cast voices, with Russian letters and magical words preserved in Cyrillic. */

open Cinema_Backends
open Cinema_Audio

@val @scope("process") external argv: array<string> = "argv"

let sourcePath =
  "/Users/dusty/Dev/metaphrand/stories/drakosha/2026-08-04_EP1_den-rozhdeniya_SPEC_numbered_bilingual.md"
let performancePath =
  "/Users/dusty/Dev/metaphrand/stories/drakosha/audio/ep1_birthday_english_us_v3.performance.json"
let audioPath =
  "/Users/dusty/Dev/metaphrand/stories/drakosha/audio/ep1_birthday_english_us_v3.mp3"

type rawBeat = {sceneKey: string, speaker: string, text: string}
type chunk = {
  sceneKey: string,
  beats: array<(role, line)>,
  chars: int,
  parentVoice: string,
}

let cast: array<castMember> = [
  {
    role: Role("NARRATOR"),
    voiceName: VoiceName("Bella - Professional, Bright, Warm (US)"),
    voiceId: VoiceId("hpp4J3VqNfWAUOO0d1Us"),
  },
  {
    role: Role("FROSYA"),
    voiceName: VoiceName("Cherry Twinkle - Bubbly Cartoon Girl (US)"),
    voiceId: VoiceId("XJ2fW4ybq7HouelYYGcL"),
  },
  {
    role: Role("VASYA"),
    voiceName: VoiceName("Teddy Twinkle - Cute Cartoon Boy (US)"),
    voiceId: VoiceId("XjGYkUkzth8BPs29fmcV"),
  },
  {
    role: Role("MAMA"),
    voiceName: VoiceName("Sarah - Mature, Reassuring, Confident (US)"),
    voiceId: VoiceId("EXAVITQu4vr4xnSDxMaL"),
  },
  {
    role: Role("PAPA"),
    voiceName: VoiceName("Brian - Deep, Resonant and Comforting (US)"),
    voiceId: VoiceId("nPczCjzI2devNBz1zQrb"),
  },
  {
    role: Role("BABA_YAGA"),
    voiceName: VoiceName("Doris - Mora gritty elderly"),
    voiceId: VoiceId("YHcCpa6SBWnKDaCPZJQR"),
  },
  {
    role: Role("GIANT_CHILD"),
    voiceName: VoiceName("Jessica - Playful, Bright, Warm (US)"),
    voiceId: VoiceId("cgSgspJ2msm6clMCkdW9"),
  },
]

let idFrom = (s: string): option<string> => {
  let i = Js.String2.indexOf(s, "SP")
  i >= 0 && Js.String2.length(s) >= i + 5
    ? Some(Js.String2.slice(s, ~from=i, ~to_=i + 5))
    : None
}

let sceneForHeading = (id: string): option<string> =>
  switch id {
  | "SP001" => Some("title")
  | "SP004" => Some("scene_01")
  | "SP020" => Some("scene_02")
  | "SP035" => Some("scene_03")
  | "SP040" => Some("scene_04")
  | "SP056" => Some("scene_05")
  | "SP066" => Some("scene_06")
  | "SP080" => Some("scene_07")
  | "SP095" => Some("scene_08")
  | "SP123" => Some("scene_09")
  | "SP137" => Some("scene_10")
  | "SP161" => Some("scene_11")
  | "SP175" => Some("scene_12")
  | "SP205" => Some("scene_13")
  | "SP217" => Some("scene_14")
  | "SP226" => Some("final_card")
  | _ => None
  }

let stripHtml = (s: string): string =>
  s
  ->Js.String2.replaceByRe(%re("/<[^>]+>/g"), "")
  ->Js.String2.replaceByRe(%re("/&amp;/g"), "&")
  ->Js.String2.trim

let magicWordToEnglish = (s: string): string =>
  s
  ->Js.String2.replaceByRe(%re("/СОК [(]juice[)]/g"), "juice")
  ->Js.String2.replaceByRe(%re("/САЛАТ [(]salad[)]/g"), "salad")
  ->Js.String2.replaceByRe(%re("/МАК [(]poppy[)]/g"), "poppy")
  ->Js.String2.replaceByRe(%re("/МАМА [(]Mama[)]/g"), "Mama")
  ->Js.String2.replaceByRe(%re("/КОТ [(]cat[)]/g"), "cat")
  ->Js.String2.replaceByRe(%re("/ОСА́? [(]wasp[)]/g"), "wasp")
  ->Js.String2.replaceByRe(%re("/БАК [(]large metal container[)]/g"), "metal container")
  ->Js.String2.replaceByRe(%re("/САМОКАТ [(]kick scooter[)]/g"), "kick scooter")
  ->Js.String2.replaceByRe(%re("/МОТОК [(]ball of thread[)]/g"), "ball of thread")

let removeMagicGlosses = (s: string): string =>
  s
  ->Js.String2.replaceByRe(%re("/ [(]juice[)]/g"), "")
  ->Js.String2.replaceByRe(%re("/ [(]salad[)]/g"), "")
  ->Js.String2.replaceByRe(%re("/ [(]poppy[)]/g"), "")
  ->Js.String2.replaceByRe(%re("/ [(]Mama[)]/g"), "")
  ->Js.String2.replaceByRe(%re("/ [(]cat[)]/g"), "")
  ->Js.String2.replaceByRe(%re("/ [(]wasp[)]/g"), "")
  ->Js.String2.replaceByRe(%re("/ [(]large metal container[)]/g"), "")
  ->Js.String2.replaceByRe(%re("/ [(]kick scooter[)]/g"), "")
  ->Js.String2.replaceByRe(%re("/ [(]ball of thread[)]/g"), "")

let performanceTag = (direction: string): string => {
  let d = Js.String2.toLowerCase(direction)
  if Js.String2.includes(d, "whisper") {
    "[whispering]"
  } else if Js.String2.includes(d, "pant") || Js.String2.includes(d, "out of breath") {
    "[out of breath]"
  } else if Js.String2.includes(d, "panic") {
    "[panicked]"
  } else if Js.String2.includes(d, "horrif") {
    "[horrified]"
  } else if Js.String2.includes(d, "surpris") || Js.String2.includes(d, "amazed") {
    "[surprised]"
  } else if Js.String2.includes(d, "spellbound") ||
            Js.String2.includes(d, "unable to believe") {
    "[awed]"
  } else if Js.String2.includes(d, "creaky") {
    "[raspy] [fondly]"
  } else if Js.String2.includes(d, "gruff") {
    "[gruffly]"
  } else if Js.String2.includes(d, "dryly") {
    "[dryly]"
  } else if Js.String2.includes(d, "sly") ||
            Js.String2.includes(d, "mischiev") ||
            Js.String2.includes(d, "glint") {
    "[mischievously]"
  } else if Js.String2.includes(d, "firm") ||
            Js.String2.includes(d, "no room for argument") ||
            Js.String2.includes(d, "establishing the rule") {
    "[firmly]"
  } else if Js.String2.includes(d, "warning") {
    "[warningly]"
  } else if Js.String2.includes(d, "through clenched teeth") ||
            Js.String2.includes(d, "boiling") ||
            Js.String2.includes(d, "threat") {
    "[angrily]"
  } else if Js.String2.includes(d, "offended") ||
            Js.String2.includes(d, "hurt") {
    "[upset]"
  } else if Js.String2.includes(d, "stubborn") {
    "[stubbornly]"
  } else if Js.String2.includes(d, "shy") {
    "[shyly]"
  } else if Js.String2.includes(d, "proud") {
    "[proudly]"
  } else if Js.String2.includes(d, "puzzled") ||
            Js.String2.includes(d, "warily") ||
            Js.String2.includes(d, "at a loss") {
    "[puzzled]"
  } else if Js.String2.includes(d, "businesslike") ||
            Js.String2.includes(d, "brisk") {
    "[matter-of-fact]"
  } else if Js.String2.includes(d, "quiet") ||
            Js.String2.includes(d, "soft") {
    "[softly]"
  } else if Js.String2.includes(d, "joy") ||
            Js.String2.includes(d, "delight") ||
            Js.String2.includes(d, "pleased") ||
            Js.String2.includes(d, "celebrat") ||
            Js.String2.includes(d, "happy") ||
            Js.String2.includes(d, "excited") {
    "[cheerfully]"
  } else if Js.String2.includes(d, "loud") {
    "[loudly]"
  } else if Js.String2.includes(d, "grand") {
    "[grandly]"
  } else if Js.String2.includes(d, "serious") {
    "[seriously]"
  } else if Js.String2.includes(d, "calm") ||
            Js.String2.includes(d, "unruffled") {
    "[calmly]"
  } else {
    ""
  }
}

let roleFor = (speaker: string): role =>
  switch speaker {
  | "FROSYA" => Role("FROSYA")
  | "VASYA"
  | "VASYA-CAT"
  | "VASYA-MAMA"
  | "VASYA-WASP" => Role("VASYA")
  | "MAMA" => Role("MAMA")
  | "PAPA" => Role("PAPA")
  | "BABA YAGA" => Role("BABA_YAGA")
  | "GIANT CHILD’S VOICE" => Role("GIANT_CHILD")
  | _ => Role("NARRATOR")
  }

let dialogueFrom = (html: string): (string, string) => {
  let plain = stripHtml(html)
  let colon = Js.String2.indexOf(plain, ":")
  let speaker = colon >= 0 ? Js.String2.slice(plain, ~from=0, ~to_=colon) : "NARRATOR"
  let rest =
    colon >= 0
      ? Js.String2.sliceToEnd(plain, ~from=colon + 1)->Js.String2.trim
      : plain
  let (direction, spoken) =
    if Js.String2.startsWith(rest, "(") {
      let close = Js.String2.indexOf(rest, ")")
      close > 0
        ? (
            Js.String2.slice(rest, ~from=1, ~to_=close),
            Js.String2.sliceToEnd(rest, ~from=close + 1)->Js.String2.trim,
          )
        : ("", rest)
    } else {
      ("", rest)
    }
  let inlineDirected =
    spoken
    ->Js.String2.replace(
      "(after a pause, slyly)",
      "[pause] [mischievously]",
    )
  let clean =
    inlineDirected
    ->removeMagicGlosses
    ->Js.String2.replaceByRe(%re("/VZHUKH/g"), "ВЖУХ")
    ->Js.String2.trim
  let tag = performanceTag(direction)
  (speaker, tag == "" ? clean : tag ++ " " ++ clean)
}

let narrationFrom = (id: string, html: string): string => {
  let plain =
    stripHtml(html)
    /* Keep the described event as narration; remove only the screenplay label.
       Parentheses are punctuation to the reader, not an ElevenLabs SFX cue. */
    ->Js.String2.replaceByRe(%re("/[(]Sound: */g"), "")
    ->Js.String2.replaceByRe(%re("/VZHUKH/g"), "ВЖУХ")
    ->magicWordToEnglish
    ->Js.String2.trim
  let fixed =
    switch id {
    | "SP001" => "“Frosya and Vasya.” Episode One: “The Birthday.”"
    | "SP222" =>
      "Beneath the car it reads: М, А, three blank spaces, А. The pencil scratches across the paper, and nothing else happens. The word is incomplete, so no car appears."
    | "SP227" =>
      "An illustrated hand scatters the letters across the screen. They form the episode words: juice, salad, poppy, Mama, cat, wasp, metal container, kick scooter, and ball of thread."
    | _ => plain
    }
  if id == "SP001" {
    "[warmly] " ++ fixed
  } else if switch sceneForHeading(id) {
  | Some(_) => true
  | None => false
  } {
    "[storytelling] " ++ fixed
  } else if Js.String2.includes(fixed, "Silence") ||
            Js.String2.includes(fixed, "Everyone is asleep") ||
            Js.String2.includes(fixed, "The end") {
    "[quietly] " ++ fixed
  } else {
    fixed
  }
}

let parseSpec = (): array<rawBeat> => {
  let currentId = ref("")
  let currentScene = ref("title")
  let beats = ref([])
  readText(Path(sourcePath))
  ->Js.String2.split("\n")
  ->Belt.Array.forEach(raw => {
    switch idFrom(raw) {
    | Some(id) => currentId := id
    | None => ()
    }
    if Js.String2.startsWith(raw, "<small>") {
      let id = currentId.contents
      if id != "SP002" && id != "SP003" {
        switch sceneForHeading(id) {
        | Some(key) => currentScene := key
        | None => ()
        }
        if Js.String2.includes(raw, ":</strong>") {
          let (speaker, text) = dialogueFrom(raw)
          beats := Belt.Array.concat(
            beats.contents,
            [{sceneKey: currentScene.contents, speaker, text}],
          )
        } else {
          beats := Belt.Array.concat(
            beats.contents,
            [{
              sceneKey: currentScene.contents,
              speaker: "NARRATOR",
              text: narrationFrom(id, raw),
            }],
          )
        }
      }
    }
  })
  beats.contents
}

let chunkBeats = (raw: array<rawBeat>): array<chunk> =>
  Belt.Array.reduce(raw, [], (chunks, b) => {
    let beat = (roleFor(b.speaker), Line(b.text))
    /* Mama and Papa may share a request with other roles, but never with each
       other. This prevents the parent-to-parent voice bleed heard in v1 while
       retaining enough surrounding dialogue for natural v3 performance. */
    let newParentVoice = b.speaker == "MAMA" || b.speaker == "PAPA" ? b.speaker : ""
    let n = Belt.Array.length(chunks)
    switch Belt.Array.get(chunks, n - 1) {
    | Some(last)
        if last.sceneKey == b.sceneKey &&
          (newParentVoice == "" || last.parentVoice == "" || last.parentVoice == newParentVoice) &&
          Belt.Array.length(last.beats) < 20 &&
          last.chars + Js.String2.length(b.text) <= 1800 => {
        let merged = {
          ...last,
          beats: Belt.Array.concat(last.beats, [beat]),
          chars: last.chars + Js.String2.length(b.text),
          parentVoice: last.parentVoice == "" ? newParentVoice : last.parentVoice,
        }
        Belt.Array.concat(Belt.Array.slice(chunks, ~offset=0, ~len=n - 1), [merged])
      }
    | _ =>
      Belt.Array.concat(chunks, [{
        sceneKey: b.sceneKey,
        beats: [beat],
        chars: Js.String2.length(b.text),
        parentVoice: newParentVoice,
      }])
    }
  })

let main = async () => {
  let mode = Belt.Array.get(argv, 2)->Belt.Option.getWithDefault("prepare")
  let raw = parseSpec()
  let chunks = chunkBeats(raw)
  let scenes: array<scene> =
    chunks->Belt.Array.mapWithIndex((i, c) => {
      id: SceneId(
        c.sceneKey ++ "_take_" ++ Belt.Int.toString(i + 1),
      ),
      beats: c.beats,
    })
  let characters =
    raw->Belt.Array.reduce(0, (total, b) => total + Js.String2.length(b.text))
  let p = performance(
    ~title=Title("Frosya and Vasya - Episode 1: The Birthday - Native US English narrated read"),
    ~cast,
    ~scenes,
    ~gapMs=Millis(450),
    ~out=Path(performancePath),
  )
  Js.log(
    "PREPARED — " ++
    Belt.Int.toString(Belt.Array.length(raw)) ++
    " spoken segments, " ++
    Belt.Int.toString(Belt.Array.length(chunks)) ++
    " cached dialogue takes, " ++
    Belt.Int.toString(characters) ++
    " tagged characters",
  )
  Js.log("PERFORMANCE — " ++ performancePath)
  if mode == "render" {
    let _ = await render(p, ~out=Path(audioPath))
    Js.log("AUDIO — " ++ audioPath)
  }
}

main()->ignore
