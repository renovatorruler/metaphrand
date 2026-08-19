/* Pronunciation registry — the show teaches reading, so two spellings exist
   for every taught word and they must never be confused:

     display : what the child SEES (always the true Russian spelling)
     audio   : what the voice model is GIVEN (phonetic respelling with stress)

   Russian stress is lexical and unmarked in writing, so a multi-syllable word
   handed to a TTS model unmarked is a coin flip. Proven on ОСА: the stress mark
   alone was not enough; only the syllable respelling А-СА́ read correctly.

   RULE (author, 2026-08-11): every taught word of MORE THAN ONE SYLLABLE gets
   an explicit audio spelling. One-syllable words pass through unchanged.
   The display spelling is never altered for any reason. */

type word = {display: string, audio: string}

let words: array<word> = [
  /* single syllable — unambiguous, pass through */
  {display: `СОК`, audio: `СОК`},
  {display: `МАК`, audio: `МАК`},
  {display: `КОТ`, audio: `КОТ`},
  {display: `БАК`, audio: `БАК`},
  /* multi-syllable — respelled for the voice */
  {display: `ОСА`, audio: `А-СА́`},
  {display: `САЛАТ`, audio: `СА-ЛА́Т`},
  {display: `САМОКАТ`, audio: `СА-МА-КА́Т`},
  {display: `МОТОК`, audio: `МА-ТО́К`},
  {display: `МАМА`, audio: `МА́-МА`},
  {display: `юла`, audio: `ю-ЛА́`},
  {display: `осой`, audio: `асо́й`},
]

exception PronunciationError(string)

let syllables = (s: string): int => {
  let vowels = `аеёиоуыэюяАЕЁИОУЫЭЮЯ`
  s->Js.String2.split("")->Belt.Array.reduce(0, (n, c) => Js.String2.includes(vowels, c) ? n + 1 : n)
}

/* Build gate: a multi-syllable taught word with no respelling is an error. */
let validate = (): unit =>
  words->Belt.Array.forEach(w =>
    if syllables(w.display) > 1 && w.display == w.audio {
      raise(
        PronunciationError(
          w.display ++ " has " ++ Belt.Int.toString(syllables(w.display)) ++
          " syllables but no audio respelling — Russian stress is unmarked, the voice model will guess",
        ),
      )
    }
  )

let audioFor = (display: string): string =>
  switch words->Belt.Array.getBy(w => w.display == display) {
  | Some(w) => w.audio
  | None => display
  }

let () = validate()
