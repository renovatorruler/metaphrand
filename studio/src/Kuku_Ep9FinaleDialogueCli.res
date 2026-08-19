@val @scope(("process", "env")) external envDry: option<string> = "DRY"
@val @scope(("process", "env")) external envPaid: option<string> = "PAID"
@val @scope(("process", "env")) external envLocalAlign: option<string> = "LOCAL_ALIGN"
@val @scope(("process", "env")) external envElevenAlign: option<string> = "ELEVEN_ALIGN"
@val @scope(("process", "env")) external envVakyanshAligner: option<string> = "VAKYANSH_ALIGNER"
@val @scope(("process", "env")) external envVakyanshModel: option<string> = "VAKYANSH_MODEL"
@val @scope(("process", "env")) external envVakyanshVocab: option<string> = "VAKYANSH_VOCAB"
@val @scope(("process", "env")) external envWhisperModel: option<string> = "WHISPER_MODEL"
@val @scope("process") external exit: int => unit = "exit"

let main = async () => {
  let dry = envDry == Some("1")
  let paid = envPaid == Some("1")
  let localRequested = envLocalAlign == Some("1")
  let elevenRequested = envElevenAlign == Some("1")
  try {
    let mode = Kuku_Ep9FinaleDialogue.alignmentModeFor(~localRequested, ~elevenRequested)
    await Kuku_Ep9FinaleDialogue.recover(
      ~dry,
      ~paid,
      ~mode,
      ~localRequested,
      ~vakyanshToolPath=envVakyanshAligner,
      ~vakyanshModelPath=envVakyanshModel,
      ~vakyanshVocabPath=envVakyanshVocab,
      ~whisperModelPath=envWhisperModel,
    )
  } catch {
  | Kuku_Ep9FinaleDialogue.DialogueRecovery(message) => {
      Js.log("KUKU EP9 PRODUCTION DIALOGUE FAILED: " ++ message)
      exit(1)
    }
  | Cinema_Backends.BackendError(message) => {
      Js.log("KUKU EP9 PRODUCTION DIALOGUE BACKEND FAILED: " ++ message)
      exit(1)
    }
  }
}

main()->ignore
