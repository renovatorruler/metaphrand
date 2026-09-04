/* Read-only ElevenLabs Hindi Voice Library screen.

   This command requests catalog metadata only. It never adds a voice to the
   account and never calls a speech, sound-effects, or music endpoint. */
open Cinema_Backends

@val @scope("process") external argv: array<string> = "argv"

let compact = value => value->Js.String2.replaceByRe(%re(`/\s+/g`), " ")->Js.String2.trim

let main = async () => {
  let search = Belt.Array.get(argv, 2)->Belt.Option.getWithDefault("")
  let page = await sharedHindiVoicesSearch(~search, ~page=0)
  Js.log(
    "Hindi Voice Library" ++ (search == "" ? "" : " search=\"" ++ search ++ "\"") ++
    ": " ++ Belt.Int.toString(Belt.Array.length(page.voices)) ++
    " returned / " ++ Belt.Int.toString(page.totalCount) ++ " total" ++
    (page.hasMore ? " (more pages available)" : ""),
  )
  page.voices->Belt.Array.forEachWithIndex((index, voice) => {
    Js.log(
      Belt.Int.toString(index + 1) ++ "\t" ++ voice.name ++ "\t" ++ voice.voiceId ++ "\t" ++
      voice.publicOwnerId ++ "\t" ++ voice.gender ++ "\t" ++ voice.age ++ "\t" ++
      voice.accent ++ "\t" ++ voice.descriptive ++ "\t" ++ voice.useCase ++ "\t" ++
      "usage1y=" ++ Belt.Int.toString(voice.usageCharacterCount1y) ++ "\tclones=" ++
      Belt.Int.toString(voice.clonedByCount) ++ "\trate=" ++ Js.Float.toString(voice.rate) ++
      "\t" ++ compact(voice.description),
    )
  })
}

main()->ignore
