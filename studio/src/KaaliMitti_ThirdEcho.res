/* काली मिट्टी की कहानियाँ — “तीसरी गूँज” full audio production.

   This driver makes paid work impossible without a reviewed dry plan:

     DRY=1 node src/KaaliMitti_ThirdEcho.res.mjs

     PAID=1 GENERATE_DIALOGUE=1 LOCAL_ALIGN=1 \
       APPROVED_PLAN_SHA256=<exact dry-plan hash> \
       node src/KaaliMitti_ThirdEcho.res.mjs

   Six deterministic ElevenLabs v3 dialogue requests supply three characters
   and one distinct first-answer voice. Local MLX Whisper word timestamps plus
   deterministic Kuku_LocalWordAlign projection—not approximate turn metadata—
   define reusable boundaries. Every echo, playback and learned supernatural
   copy is then assembled locally. Eleven existing,
   content-addressed ElevenLabs Sound Effects v2 assets supply the Mandu beds
   and foley without being regenerated. Music is intentionally silent.

   DRY always wins. A paid-attempt claim is written immediately before every
   provider call; a claim with no completed immutable cache forbids an automatic
   retry. */

open Cinema_Backends
module Core = EnochBrown_ColdOpenV8Core

@val @scope(("process", "env")) external envDry: option<string> = "DRY"
@val @scope(("process", "env")) external envPaid: option<string> = "PAID"
@val @scope(("process", "env")) external envGenerateDialogue: option<string> = "GENERATE_DIALOGUE"
@val @scope(("process", "env")) external envGenerateSfx: option<string> = "GENERATE_SFX"
@val @scope(("process", "env")) external envApprovedPlan: option<string> = "APPROVED_PLAN_SHA256"
@val @scope(("process", "env")) external envLocalAlign: option<string> = "LOCAL_ALIGN"
@val @scope(("process", "env")) external envAlignCachedOnly: option<string> = "ALIGN_CACHED_ONLY"
@val @scope(("process", "env")) external envMlxWhisperModel: option<string> = "MLX_WHISPER_MODEL"
@val @scope(("process", "env")) external envWhisperCppModel: option<string> = "WHISPER_CPP_MODEL"
@val @scope("process") external exit: int => unit = "exit"

exception ThirdEchoError(string)
exception LocalLineRecovery(int, string, string)

let pipelineVersion = "kaali-mitti-third-echo-v2.3.0-local-turn-recovery"
let assemblyVersion = "kaali-mitti-third-echo-mix-v2.4.0-acoustic-onsets-audible-breath-review-gate"
let scriptPath = "../stories/kaali-mitti/third-echo/TEESRI_GOONJ_AUDIO_FIRST_v2.md"
let approvedScriptSha256 = "1267e6e476074e4491b194003b85850e2136f7cd9d4ddf7051b4600caef5f661"
let projectDir = "../stories/kaali-mitti/third-echo/production/audio_v2"
let cacheDir = projectDir ++ "/cache"
let rawDialogueDir = cacheDir ++ "/provider_raw/dialogue"
/* The v1 SFX requests were valid and are content-addressed. Reuse those exact
   immutable provider assets instead of spending ElevenLabs credits again. */
let rawSfxDir = "../stories/kaali-mitti/third-echo/production/audio_v1/cache/provider_raw/sfx"
let stemDir = cacheDir ++ "/line_stems"
let localAlignmentDir = cacheDir ++ "/local_alignment"
let localAlignmentRawDir = localAlignmentDir ++ "/raw"
let localAlignmentDerivedDir = localAlignmentDir ++ "/derived"
let claimDir = cacheDir ++ "/paid_claims"
let planDir = projectDir ++ "/plans"
let mixDir = projectDir ++ "/mix"
let reviewDir = projectDir ++ "/review"

let initialLead = 2.20
let reviewTail = 0.08
let maxCharactersPerDialogueRequest = 2000
let maxNewDialogueRequests = 6
let maxNewDialogueCharacters = 7000
let maxNewCloudAlignmentRequests = 0
let maxNewSfxRequests = 11
let maxNewSfxSeconds = 83.0

/* These artifacts already exist on the production Mac. The driver never
   downloads a model and forces Hugging Face offline mode when it launches the
   local CLI. Exact hashes keep a cached alignment tied to the audited local
   implementation and model bytes. */
let localMlxPython = "../.venv/bin/python"
let localMlxCli = "../.venv/lib/python3.12/site-packages/mlx_whisper/cli.py"
let localMlxTranscribe = "../.venv/lib/python3.12/site-packages/mlx_whisper/transcribe.py"
let localMlxWriters = "../.venv/lib/python3.12/site-packages/mlx_whisper/writers.py"
let defaultMlxWhisperModel = "/Users/dusty/.cache/huggingface/hub/models--mlx-community--whisper-large-v3-mlx/snapshots/49e6aa286ad60c14352c404340ded53710378a11"
let approvedLocalPythonSha256 = "fe46716a94d8efa4514feb3c39ba3e270deee2187556986f6ddcff54aba7bb9a"
let approvedMlxCliSha256 = "758c0e3cf168d65f99c25da76417b480d61de6420d99c39e6547f165ac5ca910"
let approvedMlxTranscribeSha256 = "21f015e0d56c5e6194d07d86d772730940fff52d8f06d55838ae92ebccc24fbb"
let approvedMlxWritersSha256 = "34bd3c9b4b0f2dce1e62feacba4188f100b7cdc1f85c44a8222b0cac4f92d00f"
let approvedMlxModelConfigSha256 = "34982ce6ae286095000f82ae9583b3431639e8b092bf60c961f203745e6500e3"
let approvedMlxModelWeightsSha256 = "05ff791ce3630fae47e7c51004e9666204d786246ec07cac6110af768099b40d"
let localMlxVersion = "mlx-whisper-0.4.3"
let localEdgeSimilarityFloor = 0.50
let localProjectionVersion = "global-known-lines-v6-all-line-bounded-recovery-observed-joins-silence-cuts"
let localSilenceConfig = "silencedetect=noise=-45dB:d=0.06"
let localNonverbalSilenceConfig = "silencedetect=noise=-45dB:d=0.04"
/* The final behind-gate performance is unusually soft. A separate, stricter
   floor preserves its quiet consonant tails while the ordinary dialogue keeps
   the production-wide -45 dB handoff policy. */
let localSoftSpeechSilenceConfig = "silencedetect=noise=-55dB:d=0.06"
let insideGateReviewOnlyReason =
  "The cached inside-the-gate take contains both separately audible phrases, but two independent local Hindi ASR passes only support a phonetic near-match for ‘दरवाज़ा खोलो ना’; this mix is for review, not final dialogue acceptance."
let localAlignmentConfig =
  "mlx-whisper-0.4.3|large-v3-mlx|offline|language=hi|task=transcribe|temperature=0|best-of=5|condition-on-previous=true|word-timestamps=true|Hindi-ASR-floor=0.50/0.50/0.75/0.50|per-line-first-last-anchor-floor=0.50|Kuku_LocalWordAlign=" ++
  Kuku_LocalWordAlign.algorithmVersion
let localWhisperCpp = "/opt/homebrew/bin/whisper-cli"
let defaultWhisperCppModel = "/private/tmp/metaphrand-whisper/ggml-large-v3-turbo-q5_0.bin"
let approvedWhisperCppSha256 = "40bca494d49af736058eb3f33cbcebaa020eacf6d0087b623f334946e1ab2128"
let approvedWhisperCppModelSha256 = "394221709cd5ad1f40c46e6031ca61bce88931e6e088c188294c6d5a55ffa7e2"
let localWhisperCppConfig = "whisper.cpp-1.9.2|large-v3-turbo-q5_0|language=hi|output-json-full=true|no-prompt"
let localTurnLeadPadding = 1.50
/* Eleven's voice_segments omit inter-line pauses, so their clock falls up to
   1.157 s behind the decoded waveform in last_take. Keep the requested 1.5 s
   provider-core pad and add a measured 1.25 s decode-tail guard. */
let localTurnTailPadding = 2.75
let localTurnAlignmentConfig =
  "mlx-whisper-0.4.3|large-v3-mlx|offline|language=hi|task=transcribe|temperature=0|best-of=5|condition-on-previous=false|word-timestamps=true|pcm=s16le-16k-mono|provider-pad=1.50|measured-decode-tail-guard=1.25|first-last-anchor-floor=0.50|provider-core-associated"

type speaker = Meera | Kunal | Rafiq | UnknownVoice

type castMember = {
  speaker: speaker,
  accountName: string,
  voiceId: string,
  publicOwnerId: option<string>,
  castingReason: string,
}

type dialogueLine = {
  id: string,
  speaker: speaker,
  text: string,
  tag: string,
  requireInSource: bool,
}

type dialogueSegment = {
  id: string,
  seed: int,
  purpose: string,
  lines: array<dialogueLine>,
}

type timedLine = {id: string, start: float, end_: float}
type textSpan = {id: string, from: int, to_: int}
type transcriptMap = {text: string, spans: array<textSpan>}

type segmentCache = {
  segmentId: string,
  rawPath: string,
  duration: float,
  timings: array<timedLine>,
}

type lineAsset = {
  id: string,
  path: string,
  sha256: string,
  duration: float,
  tightPath: string,
  tightSha256: string,
  tightDuration: float,
}

type treatment =
  | Normal
  | NaturalEchoOne
  | NaturalEchoTwo
  | Playback
  | EntityHidden
  | EntityNear
  | EntityFull
  | EntityBehindGate
  | BreathOnly

type storyCue = {
  id: string,
  sourceLineId: string,
  treatment: treatment,
  gapAfter: float,
}

type voicePlacement = {
  id: string,
  sourceLineId: string,
  path: string,
  start: float,
  duration: float,
  treatment: treatment,
  gainDb: float,
}

type sfxPlacement = {
  id: string,
  assetId: string,
  path: string,
  assetSha256: string,
  start: float,
  trimStart: float,
  duration: float,
  gainDb: float,
  fadeIn: float,
  fadeOut: float,
}

type timelineBuild = {
  turns: array<Core.turnWindow>,
  placements: array<voicePlacement>,
  masterDuration: float,
}

type generatedSfxSpec = {
  id: string,
  prompt: string,
  seconds: float,
  influence: float,
  loop: bool,
}

type audioAsset = {id: string, path: string, sha256: string, duration: float}

type localAlignmentContext = {
  modelPath: string,
  modelConfigPath: string,
  modelWeightsPath: string,
}

type localSupplement = {
  lineId: string,
  requestSha256: string,
  rawPath: string,
  receiptPath: string,
  clipStart: float,
  clipEnd: float,
  anchorSource: string,
}

type localEvidence = {
  method: string,
  rawPath: string,
  fallbackReason: option<string>,
  supplements: array<localSupplement>,
}

type wordAnchor = {start: float, end_: float, similarity: float}

type recoveredLexicalBlock = {
  words: array<Kuku_LocalWordAlign.timedWord>,
  start: float,
  end_: float,
  coverage: float,
  meanSimilarity: float,
}

type loudnessStats = {integrated: float, truePeak: float, lra: float}
type volumeStats = {meanDb: float, maxDb: float}

let fail = (message: string): 'a => raise(ThirdEchoError(message))
let trim = Js.String2.trim
let lower = Js.String2.toLowerCase
let contains = (value: string, fragment: string): bool => Js.String2.includes(value, fragment)
let starts = (value: string, prefix: string): bool => Js.String2.startsWith(value, prefix)
let compact = value => value->Js.String2.replaceByRe(%re(`/\s+/g`), " ")->trim
let secondsValue = (Seconds(value)): float => value
let pathString = (Path(value)): string => value
let shortHash = hash => Js.String2.slice(hash, ~from=0, ~to_=20)
let floatMin = (a: float, b: float): float => a < b ? a : b
let floatMax = (a: float, b: float): float => a > b ? a : b

let speakerName = speaker => switch speaker {
| Meera => "MEERA"
| Kunal => "KUNAL"
| Rafiq => "RAFIQ"
| UnknownVoice => "UNKNOWN_VOICE"
}

let treatmentName = treatment => switch treatment {
| Normal => "normal"
| NaturalEchoOne => "natural_echo_one"
| NaturalEchoTwo => "natural_echo_two"
| Playback => "recorder_playback"
| EntityHidden => "entity_hidden"
| EntityNear => "entity_near"
| EntityFull => "entity_full"
| EntityBehindGate => "entity_behind_locked_gate"
| BreathOnly => "breath_only"
}

let cast: array<castMember> = [
  {
    speaker: Meera,
    accountName: "Mahira — Third Echo Meera",
    voiceId: "subIZc6skATBQ1Rbqpi7",
    publicOwnerId: None,
    castingReason: "Reserved adult field recordist: practical, controlled, then sharply protective without melodrama.",
  },
  {
    speaker: Kunal,
    accountName: "Krish — Third Echo Kunal",
    voiceId: "eUfplp5rzZJd9uBGf0sv",
    publicOwnerId: Some("7398804d9eaf2f463899a907587c33a390591775784f87857b6d0e1e4e3e66f6"),
    castingReason: "Young brother with easy teasing energy whose loss of humour and then voice makes the danger audible.",
  },
  {
    speaker: Rafiq,
    accountName: "Aravinda — Third Echo Rafiq",
    voiceId: "SMQ9Cz6R2KznIR4Fr825",
    publicOwnerId: Some("7398804d9eaf2f463899a907587c33a390591775784f87857b6d0e1e4e3e66f6"),
    castingReason: "Measured older caretaker who becomes decisive without delivering lore or exposition.",
  },
  {
    speaker: UnknownVoice,
    accountName: "Shivank — Third Echo first human answer",
    voiceId: "M1baVR22tUikfDMapkh7",
    publicOwnerId: None,
    castingReason: "A distinct ordinary adult human voice for the fully intelligible first answer; it must not sound like Kunal, Meera or Rafiq.",
  },
]

let line = (~id, ~speaker, ~text, ~tag="", ~requireInSource=true): dialogueLine =>
  {id, speaker, text, tag, requireInSource}

let segments: array<dialogueSegment> = [
  {
    id: "seventh_take",
    seed: 832201,
    purpose: "Audibly establish the recorder, the paid deadline, the normal echo, and a distinct human-sounding answer.",
    lines: [
      line(~id="K00", ~speaker=Kunal, ~text="रिकॉर्डर निकाल दिया। बैटरी आधी है।"),
      line(~id="M00", ~speaker=Meera, ~text="इतनी काफ़ी है। लाल बटन दबा।"),
      line(~id="K00A", ~speaker=Kunal, ~text="चल रहा है।"),
      line(~id="M01", ~speaker=Meera, ~text="मांडू इको पॉइंट। टेक सात।"),
      line(~id="K01", ~speaker=Kunal, ~tag="[playfully]", ~text="मीरा दी, छह बार बोल चुका हूँ। कभी बच्चे, कभी बाइक। अबकी बार कोई आया ना, उससे ही बुलवा लेना।"),
      line(~id="M01A", ~speaker=Meera, ~tag="[matter-of-fact]", ~text="आज साफ़ फ़ाइल नहीं गई तो पेमेंट अगले महीने। बस एक बार।"),
      line(~id="K02", ~speaker=Kunal, ~text="वही बोलूँ?"),
      line(~id="M02", ~speaker=Meera, ~text="हाँ। रिकॉर्डर चल रहा है। बोल।"),
      line(~id="K03", ~speaker=Kunal, ~tag="[calling into the distance]", ~text="कोई है?"),
      line(~id="U01", ~speaker=UnknownVoice, ~tag="[calling clearly from a distance]", ~text="अभी नहीं।"),
      line(~id="K04", ~speaker=Kunal, ~tag="[startled]", ~text="दीदी... वो तू थी?"),
      line(~id="M03", ~speaker=Meera, ~text="नहीं।"),
      line(~id="K05", ~speaker=Kunal, ~text="मैंने सिर्फ़ “कोई है” कहा था। “अभी नहीं” मैंने नहीं कहा।"),
      line(~id="M04", ~speaker=Meera, ~tag="[controlled]", ~text="मुझे पता है।"),
      line(~id="K06", ~speaker=Kunal, ~text="रिकॉर्डर ने पकड़ा?"),
      line(~id="M05", ~speaker=Meera, ~text="हाँ। दोनों आवाज़ें साफ़ आई हैं।"),
      line(~id="K07", ~speaker=Kunal, ~text="तो गूँज नहीं थी। किसी आदमी ने जवाब दिया है।"),
    ],
  },
  {
    id: "recording_witness",
    seed: 832202,
    purpose: "Rafiq states why he is there, hears the exact three-part playback, and tests a rational hidden-person theory.",
    lines: [
      line(~id="R01", ~speaker=Rafiq, ~tag="[measured, approaching]", ~text="मीरा बिटिया, तुम लोग अभी तक रिकॉर्ड कर रहे हो? मैं फाटक बंद करने आया हूँ।"),
      line(~id="M06", ~speaker=Meera, ~text="रफ़ीक़ चाचा, पहले ये सुनिए। मेरे रिकॉर्डर में किसी की आवाज़ आई है।"),
      line(~id="K08", ~speaker=Kunal, ~text="मैंने “कोई है” बोला था। मेरी गूँज खत्म हुई, फिर किसी ने “अभी नहीं” कहा।"),
      line(~id="R02", ~speaker=Rafiq, ~text="यहाँ तुम दोनों के अलावा कोई नहीं होना चाहिए। चलाओ।"),
      line(~id="M07", ~speaker=Meera, ~text="एक सेकंड। मैं रिकॉर्डिंग पीछे कर रही हूँ।"),
      line(~id="M08", ~speaker=Meera, ~text="पहले कुनाल था। फिर उसकी दो गूँज। ये तीसरी आवाज़ बाद में आई।"),
      line(~id="R03", ~speaker=Rafiq, ~text="कुनाल, आख़िरी बात तुमने नहीं कही?"),
      line(~id="K09", ~speaker=Kunal, ~text="नहीं, चाचा।"),
      line(~id="R04", ~speaker=Rafiq, ~text="गूँज अपनी तरफ़ से नया जवाब नहीं बनाती। कोई अंदर छूट गया होगा।"),
      line(~id="K10", ~speaker=Kunal, ~tag="[trying to make it ordinary]", ~text="या नीचे छुपकर फ़ोन से चला रहा होगा। आवाज़ पत्थर से घूमकर आई होगी।"),
      line(~id="R05", ~speaker=Rafiq, ~tag="[firmly]", ~text="हो सकता है। अगर कोई अंदर है, उसे बाहर निकालना मेरा काम है। तुम दोनों यहीं रहो। मीरा, रिकॉर्डर बंद करो और सामान बाँधो।"),
      line(~id="M09", ~speaker=Meera, ~text="ठीक है, चाचा।"),
    ],
  },
  {
    id: "empty_search",
    seed: 832203,
    purpose: "Rafiq's closing sweep finds nobody; he refuses another take and makes everyone leave.",
    lines: [
      line(~id="R06A", ~speaker=Rafiq, ~tag="[calling into the distance]", ~text="ओ भैया! जगह बंद हो रही है।"),
      line(~id="R06B", ~speaker=Rafiq, ~tag="[calling into the distance]", ~text="बाहर आ जाइए!"),
      line(~id="K11", ~speaker=Kunal, ~text="रफ़ीक़ चाचा, कोई मिला?"),
      line(~id="R07", ~speaker=Rafiq, ~text="नीचे तक देख आया। कोई नहीं। अब मेरे साथ बाहर चलो।"),
      line(~id="M10", ~speaker=Meera, ~tag="[quiet urgency]", ~text="चाचा, बस दस सेकंड। मुझे एक साफ़ गूँज रिकॉर्ड करनी है।"),
      line(~id="R08", ~speaker=Rafiq, ~text="नहीं, बिटिया। बारिश ऊपर आ गई है। मुझे फाटक बंद करना है।"),
      line(~id="M11", ~speaker=Meera, ~text="आज फ़ाइल नहीं भेजी तो मेरा पेमेंट फिर एक महीना अटक जाएगा।"),
      line(~id="R09", ~speaker=Rafiq, ~tag="[decisive]", ~text="पैसे के लिए मौसम नहीं रुकेगा। रिकॉर्डर बैग में रखो।"),
      line(~id="K12", ~speaker=Kunal, ~text="सुना, दीदी? चल।"),
      line(~id="M12", ~speaker=Meera, ~text="चल रही हूँ।"),
    ],
  },
  {
    id: "last_take",
    seed: 832204,
    purpose: "Meera alone makes the consequential mistake; the exact voice-copy sends everyone straight to the gate.",
    lines: [
      line(~id="K13", ~speaker=Kunal, ~text="दीदी, क्या कर रही है?"),
      line(~id="M13", ~speaker=Meera, ~text="रिकॉर्डर फिर चला दिया। बस एक लाइन।"),
      line(~id="K14", ~speaker=Kunal, ~text="रफ़ीक़ चाचा ने मना किया है।"),
      line(~id="M14", ~speaker=Meera, ~text="दस सेकंड। आज ही भेजना है। फिर मैं खुद बंद कर दूँगी।"),
      line(~id="K15", ~speaker=Kunal, ~text="बस एक। इसके बाद नहीं।"),
      line(~id="R10", ~speaker=Rafiq, ~tag="[calling from ahead]", ~text="मीरा! पीछे मत रहो।"),
      line(~id="M15", ~speaker=Meera, ~tag="[calling back]", ~text="आ रहे हैं, चाचा। कुनाल, बोल।"),
      line(~id="K16", ~speaker=Kunal, ~tag="[calling into the distance]", ~text="मीरा दी, अब चलें?"),
      line(~id="K17", ~speaker=Kunal, ~tag="[frightened]", ~text="दीदी... ये मेरी आवाज़ थी। पर मैंने दोबारा नहीं बोला।"),
      line(~id="M16", ~speaker=Meera, ~tag="[urgent]", ~text="रिकॉर्डर बंद। अभी।"),
      line(~id="M17", ~speaker=Meera, ~text="रिकॉर्डर मेरे पास है। बाकी सामान छोड़। चल!"),
      line(~id="R11", ~speaker=Rafiq, ~text="क्या हुआ?"),
      line(~id="K18", ~speaker=Kunal, ~text="उसने मेरी लाइन मेरी आवाज़ में लौटा दी।"),
      line(~id="R12", ~speaker=Rafiq, ~tag="[controlled urgency]", ~text="बात बंद। मेरी चाबियों के पीछे चलते रहो।"),
      line(~id="KLAUGH", ~speaker=Kunal, ~tag="[a small nervous relieved laugh]", ~text="हा।", ~requireInSource=false),
      line(~id="K19", ~speaker=Kunal, ~tag="[horrified]", ~text="दीदी... वो मेरी हँसी थी।"),
      line(~id="ES03", ~speaker=Kunal, ~tag="[calling clearly from behind, no breath before the word]", ~text="दीदी?"),
      line(~id="M18", ~speaker=Meera, ~tag="[firmly protective]", ~text="कुनाल, मेरा हाथ पकड़।"),
      line(~id="K20", ~speaker=Kunal, ~tag="[close, breathing hard]", ~text="पकड़ लिया। मैं यहीं हूँ।"),
      line(~id="M19", ~speaker=Meera, ~text="मेरी बाँह मत छोड़ना। अब कुछ मत बोल।"),
      line(~id="R13", ~speaker=Rafiq, ~tag="[urgent]", ~text="फाटक पास है। चलते रहो।"),
    ],
  },
  {
    id: "voice_taken",
    seed: 832205,
    purpose: "The delay shrinks to half a second and then to a same-syllable theft at the fall.",
    lines: [
      line(~id="K21", ~speaker=Kunal, ~tag="[voice suddenly weakening]", ~text="दीदी... मेरी आवाज़..."),
      line(~id="M20", ~speaker=Meera, ~tag="[firm, frightened]", ~text="कुनाल, चुप। बस मेरी बाँह पकड़े रह।"),
      line(~id="R14", ~speaker=Rafiq, ~tag="[commanding]", ~text="फाटक खुला है। कुनाल, बाहर। मीरा, उसके साथ।"),
      line(~id="K22", ~speaker=Kunal, ~tag="[a cry cut off in the throat]", ~text="दी—"),
      line(~id="ES06", ~speaker=Kunal, ~tag="[full voice, urgent, no breath]", ~text="दीदी!"),
      line(~id="M21", ~speaker=Meera, ~tag="[recovering from a hard fall]", ~text="मैं ठीक हूँ। कुनाल? कुनाल, बोल!"),
      line(~id="KB01", ~speaker=Kunal, ~tag="[strained breath, trying to speak, unable to voice]", ~text="ह...", ~requireInSource=false),
      line(~id="R15", ~speaker=Rafiq, ~tag="[commanding]", ~text="उठो। दोनों बाहर।"),
      line(~id="M22", ~speaker=Meera, ~tag="[frightened, close]", ~text="कुनाल, मेरी आवाज़ सुन पा रहा है?"),
      line(~id="KB02", ~speaker=Kunal, ~tag="[strained breath, trying to speak, then a cough]", ~text="ह...", ~requireInSource=false),
      line(~id="R16", ~speaker=Rafiq, ~tag="[gently but urgently]", ~text="गले पर ज़ोर मत डालो।"),
      line(~id="M23", ~speaker=Meera, ~text="सुन रहा है तो फाटक पर दो बार उँगली मार।"),
      line(~id="KB03", ~speaker=Kunal, ~tag="[strained breath, unable to voice]", ~text="ह...", ~requireInSource=false),
      line(~id="M24", ~speaker=Meera, ~tag="[steadying him]", ~text="ठीक है। मेरा हाथ पकड़े रह। हम नीचे जा रहे हैं।"),
    ],
  },
  {
    id: "inside_the_gate",
    seed: 832206,
    purpose: "The warm full Kunal voice calls from behind the locked gate, dry and bodiless.",
    lines: [
      line(~id="ES07A", ~speaker=Kunal, ~tag="[warm, natural, no breath before the word]", ~text="दीदी..."),
      line(~id="ES07B", ~speaker=Kunal, ~tag="[warm, natural, gently asking]", ~text="दरवाज़ा खोलो ना।"),
    ],
  },
]

let generatedSfx: array<generatedSfxSpec> = [
  {
    id: "open_wind_bed",
    prompt: "Quiet open stone hilltop ambience in Mandu at late monsoon dusk: soft natural wind over damp flagstones and sparse insects, wide documentary field recording, steady texture suitable for seamless looping.",
    seconds: 20.0,
    influence: 0.68,
    loop: true,
  },
  {
    id: "distant_peacock",
    prompt: "A single distant Indian peacock call heard across a broad open hilltop at dusk, realistic outdoor field recording.",
    seconds: 4.0,
    influence: 0.72,
    loop: false,
  },
  {
    id: "rain_bed",
    prompt: "Steady monsoon rain on an open hilltop stone courtyard, fine droplets on broad flagstones, a very distant low thunder roll near the end, consistent rainfall suitable for looping; wide documentary field recording.",
    seconds: 20.0,
    influence: 0.68,
    loop: true,
  },
  {
    id: "retreat_footsteps",
    prompt: "Three adults in ordinary shoes walking briskly together across wet stone paving, occasional shallow water steps, continuous realistic close production foley with steady forward movement.",
    seconds: 12.0,
    influence: 0.74,
    loop: true,
  },
  {
    id: "slip_fall",
    prompt: "One adult shoe suddenly slips on wet stone followed by a heavy clothed body landing hard on stone, realistic close production foley, one concise event.",
    seconds: 4.0,
    influence: 0.78,
    loop: false,
  },
  {
    id: "keys_approach",
    prompt: "Heavy old iron keys jingling at the belt of an adult taking measured footsteps on damp stone, realistic close production foley.",
    seconds: 6.0,
    influence: 0.74,
    loop: false,
  },
  {
    id: "recorder_control",
    prompt: "A handheld professional field recorder button clicks followed by a short clean electronic confirmation tone, realistic close foley.",
    seconds: 2.0,
    influence: 0.78,
    loop: false,
  },
  {
    id: "packing",
    prompt: "A compact field-recording bag zipper closes, followed by a small metal microphone stand folding shut, clean close production foley with a short pause between events.",
    seconds: 4.0,
    influence: 0.76,
    loop: false,
  },
  {
    id: "gate_open",
    prompt: "An old heavy iron gate latch lifts and the gate swings open, realistic close production foley.",
    seconds: 3.0,
    influence: 0.78,
    loop: false,
  },
  {
    id: "gate_close_lock",
    prompt: "An old heavy iron gate swings shut, then a chain pulls tight around it and a padlock clicks closed, realistic close production foley.",
    seconds: 6.0,
    influence: 0.78,
    loop: false,
  },
  {
    id: "finger_taps",
    prompt: "Two distinct human fingertip taps on an iron gate, evenly spaced, dry realistic close foley.",
    seconds: 2.0,
    influence: 0.80,
    loop: false,
  },
]

/* The cursor advances only for authored vocal beats. Copies can be sourced from
   a prior line without paying for a second performance. The one exception is
   the same-syllable theft: ES06 is placed as an overlay at K22's start by the
   timeline builder, rather than serialized after it. */
let cue = (~id, ~sourceLineId=?, ~treatment=Normal, ~gapAfter=0.0): storyCue => {
  id,
  sourceLineId: sourceLineId->Belt.Option.getWithDefault(id),
  treatment,
  gapAfter,
}

let storyCues: array<storyCue> = [
  cue(~id="K00"),
  cue(~id="M00", ~gapAfter=2.15),
  cue(~id="K00A"),
  cue(~id="M01"),
  cue(~id="K01"),
  cue(~id="M01A"),
  cue(~id="K02"),
  cue(~id="M02"),
  cue(~id="K03", ~gapAfter=0.40),
  cue(~id="ECHO_K03_1", ~sourceLineId="K03", ~treatment=NaturalEchoOne, ~gapAfter=0.16),
  cue(~id="ECHO_K03_2", ~sourceLineId="K03", ~treatment=NaturalEchoTwo, ~gapAfter=2.00),
  cue(~id="ENTITY_01", ~sourceLineId="U01", ~treatment=EntityHidden, ~gapAfter=0.45),
  cue(~id="K04"),
  cue(~id="M03"),
  cue(~id="K05"),
  cue(~id="M04"),
  cue(~id="K06"),
  cue(~id="M05"),
  cue(~id="K07", ~gapAfter=0.75),

  cue(~id="R01"),
  cue(~id="M06"),
  cue(~id="K08"),
  cue(~id="R02"),
  cue(~id="M07", ~gapAfter=2.15),
  cue(~id="PLAY_K03", ~sourceLineId="K03", ~treatment=Playback, ~gapAfter=0.10),
  cue(~id="PLAY_ECHO_K03_1", ~sourceLineId="K03", ~treatment=Playback, ~gapAfter=0.10),
  cue(~id="PLAY_ECHO_K03_2", ~sourceLineId="K03", ~treatment=Playback, ~gapAfter=0.16),
  cue(~id="PLAY_ENTITY_01", ~sourceLineId="U01", ~treatment=Playback, ~gapAfter=0.40),
  cue(~id="M08"),
  cue(~id="R03"),
  cue(~id="K09"),
  cue(~id="R04"),
  cue(~id="K10"),
  cue(~id="R05"),
  cue(~id="M09", ~gapAfter=4.60),

  cue(~id="R06A"),
  cue(~id="R06B", ~gapAfter=0.40),
  cue(~id="ECHO_R06B_1", ~sourceLineId="R06B", ~treatment=NaturalEchoOne, ~gapAfter=0.16),
  cue(~id="ECHO_R06B_2", ~sourceLineId="R06B", ~treatment=NaturalEchoTwo, ~gapAfter=4.20),
  cue(~id="K11"),
  cue(~id="R07"),
  cue(~id="M10"),
  cue(~id="R08"),
  cue(~id="M11"),
  cue(~id="R09"),
  cue(~id="K12"),
  cue(~id="M12", ~gapAfter=2.80),

  cue(~id="K13"),
  cue(~id="M13"),
  cue(~id="K14"),
  cue(~id="M14"),
  cue(~id="K15"),
  cue(~id="R10"),
  cue(~id="M15"),
  cue(~id="K16", ~gapAfter=0.40),
  cue(~id="ECHO_K16_1", ~sourceLineId="K16", ~treatment=NaturalEchoOne, ~gapAfter=0.16),
  cue(~id="ECHO_K16_2", ~sourceLineId="K16", ~treatment=NaturalEchoTwo, ~gapAfter=1.00),
  cue(~id="ENTITY_K16", ~sourceLineId="K16", ~treatment=EntityNear, ~gapAfter=0.45),
  cue(~id="K17"),
  cue(~id="M16", ~gapAfter=2.15),
  cue(~id="M17", ~gapAfter=0.90),
  cue(~id="R11"),
  cue(~id="K18"),
  cue(~id="R12", ~gapAfter=1.10),

  cue(~id="KLAUGH", ~gapAfter=2.00),
  cue(~id="ENTITY_LAUGH", ~sourceLineId="KLAUGH", ~treatment=EntityNear, ~gapAfter=0.55),
  cue(~id="K19", ~gapAfter=0.40),
  cue(~id="ENTITY_03", ~sourceLineId="ES03", ~treatment=EntityNear, ~gapAfter=0.38),
  cue(~id="M18"),
  cue(~id="K20", ~gapAfter=0.42),
  cue(~id="ENTITY_K20", ~sourceLineId="K20", ~treatment=EntityFull, ~gapAfter=0.30),
  cue(~id="M19"),
  cue(~id="R13", ~gapAfter=0.70),

  cue(~id="K21", ~gapAfter=0.50),
  cue(~id="ENTITY_K21", ~sourceLineId="K21", ~treatment=EntityFull, ~gapAfter=0.30),
  cue(~id="M20", ~gapAfter=3.40),
  cue(~id="R14", ~gapAfter=4.40),
  /* The fall plate sits in this gap. K22 is held until the impact is over. */
  cue(~id="K22", ~gapAfter=0.70),
  cue(~id="M21"),
  cue(~id="KB01", ~treatment=BreathOnly),
  cue(~id="R15", ~gapAfter=7.00),

  cue(~id="M22"),
  cue(~id="KB02", ~treatment=BreathOnly),
  cue(~id="R16"),
  cue(~id="M23", ~gapAfter=1.05),
  cue(~id="KB03", ~treatment=BreathOnly),
  cue(~id="M24", ~gapAfter=4.50),
  cue(~id="ENTITY_07A", ~sourceLineId="ES07A", ~treatment=EntityBehindGate, ~gapAfter=1.15),
  cue(~id="ENTITY_07B", ~sourceLineId="ES07B", ~treatment=EntityBehindGate, ~gapAfter=0.0),
]

let jsonString = value => Js.Json.string(value)
let jsonNumber = value => Js.Json.number(value)
let addString = (root: Js.Dict.t<Js.Json.t>, key, value): unit => Js.Dict.set(root, key, jsonString(value))
let addNumber = (root: Js.Dict.t<Js.Json.t>, key, value): unit => Js.Dict.set(root, key, jsonNumber(value))
let addBool = (root: Js.Dict.t<Js.Json.t>, key, value): unit => Js.Dict.set(root, key, Js.Json.boolean(value))

let stringField = (json: Js.Json.t, key: string): string =>
  json->Js.Json.decodeObject->Belt.Option.flatMap(object_ => Js.Dict.get(object_, key))->Belt.Option.flatMap(Js.Json.decodeString)->Belt.Option.getWithDefault("")

let numberField = (json: Js.Json.t, key: string): float =>
  json->Js.Json.decodeObject->Belt.Option.flatMap(object_ => Js.Dict.get(object_, key))->Belt.Option.flatMap(Js.Json.decodeNumber)->Belt.Option.getWithDefault(-1.0)

let arrayField = (json: Js.Json.t, key: string): array<Js.Json.t> =>
  json->Js.Json.decodeObject->Belt.Option.flatMap(object_ => Js.Dict.get(object_, key))->Belt.Option.flatMap(Js.Json.decodeArray)->Belt.Option.getWithDefault([])

let memberFor = speaker => switch Belt.Array.getBy(cast, member => member.speaker == speaker) {
| Some(member) => member
| None => fail("cast has no " ++ speakerName(speaker))
}

let allLines = (): array<dialogueLine> => segments->Belt.Array.map(segment => segment.lines)->Belt.Array.concatMany

let lineFor = id => switch Belt.Array.getBy(allLines(), row => row.id == id) {
| Some(row) => row
| None => fail("unknown source line " ++ id)
}

let providerText = (row: dialogueLine) => row.tag == "" ? row.text : row.tag ++ " " ++ row.text
let segmentCharacters = segment => segment.lines->Belt.Array.reduce(0, (sum, row) => sum + Js.String2.length(providerText(row)))
let totalDialogueCharacters = () => segments->Belt.Array.reduce(0, (sum, segment) => sum + segmentCharacters(segment))

let castSignature = () => cast->Belt.Array.map(member =>
  speakerName(member.speaker) ++ "=" ++ member.voiceId ++ "=" ++ member.publicOwnerId->Belt.Option.getWithDefault("account")
)->Js.Array2.joinWith("|")

let dialogueRequestSignature = (segment: dialogueSegment) => Js.Array2.joinWith([
  "endpoint=/v1/text-to-dialogue/with-timestamps",
  "model=eleven_v3",
  "language=hi",
  "normalization=on",
  "seed=" ++ Belt.Int.toString(segment.seed),
  "output_format=mp3_44100_128",
  segment.lines->Belt.Array.map(row =>
    row.id ++ "=" ++ speakerName(row.speaker) ++ "=" ++ memberFor(row.speaker).voiceId ++ "=" ++ providerText(row)
  )->Js.Array2.joinWith("||"),
], "###")

let dialogueRequestHash = (segment: dialogueSegment) => sha256Text(dialogueRequestSignature(segment))
let dialogueRawPath = (segment: dialogueSegment) => rawDialogueDir ++ "/" ++ segment.id ++ "_" ++ shortHash(dialogueRequestHash(segment)) ++ ".mp3"
let dialogueTimingPath = (segment: dialogueSegment) => dialogueRawPath(segment) ++ ".timings.json"
let dialogueReceiptPath = (segment: dialogueSegment) => dialogueRawPath(segment) ++ ".receipt.json"

let transcriptMap = (segment: dialogueSegment): transcriptMap => {
  let buffer = ref("")
  let spans: array<textSpan> = []
  segment.lines->Belt.Array.forEach(row => {
    if buffer.contents != "" { buffer := buffer.contents ++ " " }
    let from = Js.String2.length(buffer.contents)
    buffer := buffer.contents ++ row.text
    Js.Array2.push(spans, {id: row.id, from, to_: Js.String2.length(buffer.contents)})->ignore
  })
  {text: buffer.contents, spans}
}

let legacyCloudAlignmentRequestHash = (segment: dialogueSegment): string => {
  let mapped = transcriptMap(segment)
  sha256Text(
    "endpoint=/v1/forced-alignment|recipe=character-span-v2|dialogue_request=" ++
    dialogueRequestHash(segment) ++ "|transcript=" ++ mapped.text,
  )
}

let localAlignmentRecipeSignature = (segment: dialogueSegment): string => {
  let mapped = transcriptMap(segment)
  Js.Array2.joinWith([
    "method=local-mlx-whisper-plus-kuku-word-align",
    localAlignmentConfig,
    "dialogue_request=" ++ dialogueRequestHash(segment),
    "transcript_sha256=" ++ sha256Text(mapped.text),
    "python_sha256=" ++ approvedLocalPythonSha256,
    "mlx_cli_sha256=" ++ approvedMlxCliSha256,
    "mlx_transcribe_sha256=" ++ approvedMlxTranscribeSha256,
    "mlx_writers_sha256=" ++ approvedMlxWritersSha256,
    "model_config_sha256=" ++ approvedMlxModelConfigSha256,
    "model_weights_sha256=" ++ approvedMlxModelWeightsSha256,
  ], "|")
}

let localAlignmentRecipeHash = (segment: dialogueSegment): string =>
  sha256Text(localAlignmentRecipeSignature(segment))

/* Keep the already completed MLX inference cache independent from projection
   policy. A stricter projector can therefore be introduced without rerunning
   a valid local model pass or mutating its immutable evidence. */
let localAlignmentKey = (~segment: dialogueSegment, ~cache: segmentCache): string =>
  sha256Text(localAlignmentRecipeSignature(segment) ++ "|audio_sha256=" ++ sha256File(Path(cache.rawPath)))

let localProjectionSignature = (segment: dialogueSegment): string => Js.Array2.joinWith([
  localProjectionVersion,
  localSilenceConfig,
  localNonverbalSilenceConfig,
  "turn_recovery=" ++ localTurnAlignmentConfig,
  "edge_similarity_floor=" ++ Js.Float.toString(localEdgeSimilarityFloor),
  "primary_mlx_key=" ++ localAlignmentRecipeHash(segment),
  "fallback_config=" ++ localWhisperCppConfig,
  "fallback_binary_sha256=" ++ approvedWhisperCppSha256,
  "fallback_model_sha256=" ++ approvedWhisperCppModelSha256,
], "|")

let localTurnBounds = (~cache: segmentCache, ~coarse: timedLine): (float, float) => (
  floatMax(0.0, coarse.start -. localTurnLeadPadding),
  floatMin(cache.duration, coarse.end_ +. localTurnTailPadding),
)

let localTurnRecoveryKey = (
  ~segment: dialogueSegment,
  ~cache: segmentCache,
  ~row: dialogueLine,
  ~coarse: timedLine,
): string => {
  let (clipStart, clipEnd) = localTurnBounds(~cache, ~coarse)
  sha256Text(Js.Array2.joinWith([
    localTurnAlignmentConfig,
    "segment=" ++ segment.id,
    "line=" ++ row.id,
    "audio_sha256=" ++ sha256File(Path(cache.rawPath)),
    "dialogue_request=" ++ dialogueRequestHash(segment),
    "clip_start=" ++ Js.Float.toString(clipStart),
    "clip_end=" ++ Js.Float.toString(clipEnd),
    "transcript_sha256=" ++ sha256Text(row.text),
    "python_sha256=" ++ approvedLocalPythonSha256,
    "mlx_cli_sha256=" ++ approvedMlxCliSha256,
    "mlx_transcribe_sha256=" ++ approvedMlxTranscribeSha256,
    "mlx_writers_sha256=" ++ approvedMlxWritersSha256,
    "model_config_sha256=" ++ approvedMlxModelConfigSha256,
    "model_weights_sha256=" ++ approvedMlxModelWeightsSha256,
  ], "|"))
}

let localTurnRawPath = (
  ~segment: dialogueSegment,
  ~cache: segmentCache,
  ~row: dialogueLine,
  ~coarse: timedLine,
): string => localAlignmentRawDir ++ "/" ++ segment.id ++ "_" ++ row.id ++ "_" ++
  shortHash(localTurnRecoveryKey(~segment, ~cache, ~row, ~coarse)) ++ ".turn.mlx.json"

let localTurnReceiptPath = (
  ~segment: dialogueSegment,
  ~cache: segmentCache,
  ~row: dialogueLine,
  ~coarse: timedLine,
): string => localTurnRawPath(~segment, ~cache, ~row, ~coarse) ++ ".receipt.json"

let localDerivedKey = (~segment: dialogueSegment, ~cache: segmentCache): string =>
  sha256Text(
    localAlignmentKey(~segment, ~cache) ++ "|projection=" ++ localProjectionSignature(segment),
  )

let localRawAlignmentPath = (~segment: dialogueSegment, ~cache: segmentCache): string =>
  localAlignmentRawDir ++ "/" ++ segment.id ++ "_" ++ shortHash(localAlignmentKey(~segment, ~cache)) ++ ".mlx.json"

let localWhisperCppKey = (~segment: dialogueSegment, ~cache: segmentCache): string =>
  sha256Text(Js.Array2.joinWith([
    localWhisperCppConfig,
    "dialogue_request=" ++ dialogueRequestHash(segment),
    "audio_sha256=" ++ sha256File(Path(cache.rawPath)),
    "binary_sha256=" ++ approvedWhisperCppSha256,
    "model_sha256=" ++ approvedWhisperCppModelSha256,
  ], "|"))

let localWhisperCppRawPath = (~segment: dialogueSegment, ~cache: segmentCache): string =>
  localAlignmentRawDir ++ "/" ++ segment.id ++ "_" ++
  shortHash(localWhisperCppKey(~segment, ~cache)) ++ ".whisper.json"

let dialogueAlignmentPath = (~segment: dialogueSegment, ~cache: segmentCache): string =>
  localAlignmentDerivedDir ++ "/" ++ segment.id ++ "_" ++ shortHash(localDerivedKey(~segment, ~cache)) ++ ".json"

let dialogueAlignmentReceiptPath = (~segment: dialogueSegment, ~cache: segmentCache): string =>
  dialogueAlignmentPath(~segment, ~cache) ++ ".receipt.json"

let legacyCloudAlignmentClaimPath = (segment: dialogueSegment): string =>
  claimDir ++ "/alignment_" ++ segment.id ++ "_" ++ legacyCloudAlignmentRequestHash(segment) ++ ".claim.json"

let sfxRequestSignature = (spec: generatedSfxSpec) => Js.Array2.joinWith([
  "endpoint=/v1/sound-generation",
  "model=eleven_text_to_sound_v2",
  "output_format=mp3_44100_128",
  "loop=" ++ (spec.loop ? "true" : "false"),
  "seconds=" ++ Js.Float.toString(spec.seconds),
  "prompt_influence=" ++ Js.Float.toString(spec.influence),
  "text=" ++ spec.prompt,
], "|")

let sfxRequestHash = (spec: generatedSfxSpec) => sha256Text(sfxRequestSignature(spec))
let sfxRawPath = (spec: generatedSfxSpec) => rawSfxDir ++ "/" ++ spec.id ++ "_" ++ shortHash(sfxRequestHash(spec)) ++ ".mp3"
let sfxReceiptPath = (spec: generatedSfxSpec) => sfxRawPath(spec) ++ ".receipt.json"

let validateAudio = (path, label): float => {
  if !exists(Path(path)) { fail(label ++ " is missing: " ++ path) }
  let decode = run(~cmd="ffmpeg", ~args=["-nostdin", "-v", "error", "-i", path, "-f", "null", "-"])
  if decode.code != 0 { fail(label ++ " does not decode: " ++ Js.String2.slice(decode.stderr, ~from=0, ~to_=360)) }
  let duration = probeDuration(Path(path))->secondsValue
  if duration <= 0.08 { fail(label ++ " has invalid duration") }
  duration
}

let validateScript = (): unit => {
  if !exists(Path(scriptPath)) { fail("approved audio-first screenplay is missing") }
  let actual = sha256File(Path(scriptPath))
  if actual != approvedScriptSha256 { fail("screenplay changed; expected " ++ approvedScriptSha256 ++ ", got " ++ actual) }
  let source = compact(readText(Path(scriptPath)))
  let cursor = ref(0)
  allLines()->Belt.Array.keep(row => row.requireInSource)->Belt.Array.forEach(row => {
    let needle = compact(row.text)
    let tail = Js.String2.sliceToEnd(source, ~from=cursor.contents)
    let relative = Js.String2.indexOf(tail, needle)
    if relative < 0 { fail(row.id ++ " is not present in the approved screenplay order") }
    cursor := cursor.contents + relative + Js.String2.length(needle)
  })
  let combined = allLines()->Belt.Array.map(row => row.text)->Js.Array2.joinWith(" ")
  ["रिकॉर्डर निकाल दिया", "मांडू इको पॉइंट", "अभी नहीं", "मैं फाटक बंद करने आया हूँ", "गूँज अपनी तरफ़ से नया जवाब नहीं बनाती", "रिकॉर्डर फिर चला दिया", "पर मैंने दोबारा नहीं बोला", "मेरी आवाज़", "दरवाज़ा खोलो ना"]
  ->Belt.Array.forEach(fragment => if !contains(combined, fragment) { fail("missing approved story beat: " ++ fragment) })
  if contains(combined, "सूत्रधार") || contains(lower(combined), "narrator") { fail("third echo must remain narrator-free") }
  segments->Belt.Array.forEach(segment => {
    let count = segmentCharacters(segment)
    if count <= 0 || count > maxCharactersPerDialogueRequest {
      fail(segment.id ++ " has " ++ Belt.Int.toString(count) ++ " provider characters; maximum reliable request is 2,000")
    }
  })
  if Belt.Array.length(segments) != 6 || Belt.Array.length(segments) > maxNewDialogueRequests || totalDialogueCharacters() > maxNewDialogueCharacters {
    fail("dialogue design exceeds the six-request paid ceiling")
  }
}

let validateCast = (): unit => {
  if Belt.Array.length(cast) != 4 { fail("third echo v2 requires three characters plus one distinct first-answer voice") }
  cast->Belt.Array.forEachWithIndex((index, member) => {
    if trim(member.voiceId) == "" || trim(member.accountName) == "" || trim(member.castingReason) == "" { fail("incomplete cast member " ++ speakerName(member.speaker)) }
    if index > 0 && Belt.Array.some(Js.Array2.slice(cast, ~start=0, ~end_=index), prior => prior.voiceId == member.voiceId) {
      fail("two human characters share a voice " ++ member.voiceId)
    }
  })
  if memberFor(Meera).voiceId != "subIZc6skATBQ1Rbqpi7" { fail("the asset-map-approved Mahira voice is not selected for Meera") }
  if memberFor(Kunal).voiceId != "eUfplp5rzZJd9uBGf0sv" { fail("the approved Krish voice is not selected for Kunal and the learned copies") }
  if memberFor(UnknownVoice).voiceId == memberFor(Kunal).voiceId || memberFor(UnknownVoice).voiceId == memberFor(Rafiq).voiceId {
    fail("the first human-sounding answer must be unmistakably distinct from Kunal and Rafiq")
  }
}

let validateSfxDesign = (): unit => {
  generatedSfx->Belt.Array.forEach(spec => {
    let prompt = lower(trim(spec.prompt))
    if starts(prompt, "no ") || contains(prompt, " no ") || contains(prompt, "without ") { fail("SFX prompts must positively describe only audible content: " ++ spec.id) }
    if spec.seconds < 0.5 || spec.seconds > 30.0 || spec.influence < 0.0 || spec.influence > 1.0 { fail("invalid generated SFX settings for " ++ spec.id) }
  })
  let seconds = generatedSfx->Belt.Array.reduce(0.0, (sum, spec) => sum +. spec.seconds)
  if Belt.Array.length(generatedSfx) != 11 || Belt.Array.length(generatedSfx) > maxNewSfxRequests || Js.Math.abs_float(seconds -. 83.0) > 0.001 || seconds > maxNewSfxSeconds +. 0.001 {
    fail("SFX design must remain the reviewed eleven-call, 83-second identifiable-asset map")
  }
}

let validateStoryCues = (): unit => {
  storyCues->Belt.Array.forEachWithIndex((index, row) => {
    lineFor(row.sourceLineId)->ignore
    if row.gapAfter < 0.0 || row.gapAfter > 12.0 { fail("invalid authored gap after " ++ row.id) }
    if index > 0 && Belt.Array.some(Js.Array2.slice(storyCues, ~start=0, ~end_=index), prior => prior.id == row.id) { fail("duplicate story cue " ++ row.id) }
  })
  let indexOf = id => switch Belt.Array.getIndexBy(storyCues, row => row.id == id) {
  | Some(index) => index
  | None => fail("missing story cue " ++ id)
  }
  if indexOf("ENTITY_01") <= indexOf("ECHO_K03_2") || Belt.Array.getExn(storyCues, indexOf("ECHO_K03_2")).gapAfter < 2.0 {
    fail("the first entity must wait until the natural echo dies plus two seconds")
  }
  if Belt.Array.length(storyCues->Belt.Array.keep(row => starts(row.id, "PLAY_ENTITY"))) != 1 { fail("the opening event may be played back exactly once") }
  if Belt.Array.getExn(storyCues, indexOf("KLAUGH")).gapAfter != 2.0 || lineFor("KLAUGH").id != Belt.Array.getExn(storyCues, indexOf("ENTITY_LAUGH")).sourceLineId {
    fail("the copied laugh must reuse the exact stem after two seconds")
  }
  if Belt.Array.getExn(storyCues, indexOf("K21")).gapAfter != 0.5 { fail("the penultimate voice copy delay must be exactly half a second") }
  if indexOf("ENTITY_07B") != Belt.Array.length(storyCues) - 1 || Belt.Array.getExn(storyCues, indexOf("ENTITY_07B")).gapAfter != 0.0 {
    fail("the final dry gate line must cut immediately")
  }
  ["KB01", "KB02", "KB03"]->Belt.Array.forEach(id => {
    let row = Belt.Array.getExn(storyCues, indexOf(id))
    if row.treatment != BreathOnly { fail(id ++ " may contain breath only") }
  })
}

let timedLineJson = (row: timedLine) => {
  let root = Js.Dict.empty()
  addString(root, "id", row.id)
  addNumber(root, "start_seconds", row.start)
  addNumber(root, "end_seconds", row.end_)
  Js.Json.object_(root)
}

let validateTimings = (~segment: dialogueSegment, ~rows: array<timedLine>, ~duration: float): unit => {
  if Belt.Array.length(rows) != Belt.Array.length(segment.lines) { fail(segment.id ++ " timing cardinality mismatch") }
  let priorEnd = ref(-1.0)
  rows->Belt.Array.forEachWithIndex((index, row) => {
    let expected = Belt.Array.getExn(segment.lines, index)
    if row.id != expected.id { fail(segment.id ++ " timing order changed at " ++ expected.id) }
    if row.start < 0.0 || row.end_ <= row.start || row.end_ > duration +. 0.10 { fail("invalid provider timing for " ++ row.id) }
    if row.start +. 0.05 < priorEnd.contents { fail("provider dialogue overlaps out of order at " ++ row.id) }
    priorEnd := row.end_
  })
}

let timingJson = (~segment: dialogueSegment, ~rows: array<timedLine>, ~audioPath: string, ~duration: float): string => {
  let root = Js.Dict.empty()
  addString(root, "schema", "kaali-mitti.dialogue-segment-timings/v1")
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "segment_id", segment.id)
  addString(root, "request_sha256", dialogueRequestHash(segment))
  addString(root, "audio", audioPath)
  addString(root, "audio_sha256", sha256File(Path(audioPath)))
  addNumber(root, "audio_duration_seconds", duration)
  Js.Dict.set(root, "voice_segments", Js.Json.array(rows->Belt.Array.map(timedLineJson)))
  Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n"
}

let loadTimings = (~segment: dialogueSegment, ~path: string, ~audioPath: string, ~duration: float): array<timedLine> => {
  let json = Js.Json.parseExn(readText(Path(path)))
  if stringField(json, "segment_id") != segment.id || stringField(json, "request_sha256") != dialogueRequestHash(segment) || stringField(json, "audio_sha256") != sha256File(Path(audioPath)) || Js.Math.abs_float(numberField(json, "audio_duration_seconds") -. duration) > 0.10 {
    fail(segment.id ++ " timing sidecar does not match content-addressed audio")
  }
  let rows = arrayField(json, "voice_segments")->Belt.Array.map(row => ({
    id: stringField(row, "id"),
    start: numberField(row, "start_seconds"),
    end_: numberField(row, "end_seconds"),
  }))
  validateTimings(~segment, ~rows, ~duration)
  rows
}

let verifyDialogueCache = (segment: dialogueSegment): option<segmentCache> => {
  let rawPath = dialogueRawPath(segment)
  let timingPath = dialogueTimingPath(segment)
  let receiptPath = dialogueReceiptPath(segment)
  let present = [exists(Path(rawPath)), exists(Path(timingPath)), exists(Path(receiptPath))]
  let count = present->Belt.Array.reduce(0, (sum, value) => sum + (value ? 1 : 0))
  if count == 0 { None } else if count != 3 {
    fail(segment.id ++ " dialogue cache is incomplete; paid retry is forbidden")
  } else {
    let duration = validateAudio(rawPath, "cached dialogue " ++ segment.id)
    let receipt = Js.Json.parseExn(readText(Path(receiptPath)))
    if stringField(receipt, "request_sha256") != dialogueRequestHash(segment) || stringField(receipt, "asset_sha256") != sha256File(Path(rawPath)) || stringField(receipt, "timings_sha256") != sha256File(Path(timingPath)) || Js.Math.abs_float(numberField(receipt, "duration_seconds") -. duration) > 0.10 {
      fail(segment.id ++ " dialogue receipt does not match cached bytes")
    }
    let timings = loadTimings(~segment, ~path=timingPath, ~audioPath=rawPath, ~duration)
    Some({segmentId: segment.id, rawPath, duration, timings})
  }
}

let streamingSha256File = (path: string): string => {
  /* Cinema_Backends.sha256File reads a file into one Node buffer; the audited
     MLX weights are 3 GB. shasum streams those bytes and avoids Node's 2 GB
     buffer ceiling. */
  let result = run(~cmd="/usr/bin/shasum", ~args=["-a", "256", path])
  if result.code != 0 { fail("could not hash local artifact " ++ path ++ ": " ++ result.stderr) }
  let hash = result.stdout->trim->Js.String2.split(" ")->Belt.Array.get(0)->Belt.Option.getWithDefault("")
  if Js.String2.length(hash) != 64 { fail("invalid SHA-256 output for " ++ path) }
  hash
}

let assertLocalArtifact = (~label, ~path, ~sha256): unit => {
  if !exists(Path(path)) { fail(label ++ " is missing: " ++ path) }
  let actual = streamingSha256File(path)
  if actual != sha256 { fail(label ++ " SHA-256 changed: " ++ actual ++ " != " ++ sha256) }
}

let requireLocalAlignmentContext = (): localAlignmentContext => {
  let modelPath = envMlxWhisperModel->Belt.Option.getWithDefault(defaultMlxWhisperModel)
  let context = {
    modelPath,
    modelConfigPath: modelPath ++ "/config.json",
    modelWeightsPath: modelPath ++ "/weights.npz",
  }
  assertLocalArtifact(~label="local Python", ~path=localMlxPython, ~sha256=approvedLocalPythonSha256)
  assertLocalArtifact(~label="MLX Whisper CLI", ~path=localMlxCli, ~sha256=approvedMlxCliSha256)
  assertLocalArtifact(~label="MLX Whisper transcriber", ~path=localMlxTranscribe, ~sha256=approvedMlxTranscribeSha256)
  assertLocalArtifact(~label="MLX Whisper JSON writer", ~path=localMlxWriters, ~sha256=approvedMlxWritersSha256)
  assertLocalArtifact(~label="MLX Whisper model config", ~path=context.modelConfigPath, ~sha256=approvedMlxModelConfigSha256)
  assertLocalArtifact(~label="MLX Whisper model weights", ~path=context.modelWeightsPath, ~sha256=approvedMlxModelWeightsSha256)
  context
}

let parseMlxWhisperSegments = (raw: string): array<array<Kuku_LocalWordAlign.timedWord>> => {
  let json = Js.Json.parseExn(raw)
  let segments: array<array<Kuku_LocalWordAlign.timedWord>> = []
  let priorStart = ref(-1.0)
  arrayField(json, "segments")->Belt.Array.forEach(segmentJson => {
    let observed: array<Kuku_LocalWordAlign.timedWord> = []
    arrayField(segmentJson, "words")->Belt.Array.forEach(wordJson => {
      let rawText = stringField(wordJson, "word")
      let start = numberField(wordJson, "start")
      let end_ = numberField(wordJson, "end")
      let probability = numberField(wordJson, "probability")
      let pieces = Kuku_LocalWordAlign.normalizedWords(rawText)
      if !Js.Float.isFinite(start) || !Js.Float.isFinite(end_) ||
         !Js.Float.isFinite(probability) || start < 0.0 || end_ < start ||
         probability < 0.0 || probability > 1.0 {
        fail("invalid MLX Whisper word timestamp")
      }
      /* MLX can emit a zero-duration preview token immediately before the
         timestamped lexical token. It is not acoustic evidence. Ignore it just
         like whisper.cpp's preview duplicates; never project it into a line. */
      if Belt.Array.length(pieces) > 0 && end_ -. start >= 0.02 {
        if start +. 0.001 < priorStart.contents { fail("non-monotonic MLX Whisper word timestamp") }
        pieces->Belt.Array.forEachWithIndex((index, text) => {
          let count = Belt.Array.length(pieces)
          let pieceStart = start +. (end_ -. start) *. Belt.Int.toFloat(index) /. Belt.Int.toFloat(count)
          let pieceEnd = start +. (end_ -. start) *. Belt.Int.toFloat(index + 1) /. Belt.Int.toFloat(count)
          Js.Array2.push(
            observed,
            ({text, start: pieceStart, end_: pieceEnd, probability}: Kuku_LocalWordAlign.timedWord),
          )->ignore
          priorStart := pieceStart
        })
      }
    })
    if Belt.Array.length(observed) == 0 { fail("MLX Whisper segment contains no word timestamps") }
    Js.Array2.push(segments, observed)->ignore
  })
  if Belt.Array.length(segments) == 0 { fail("MLX Whisper JSON contains no timed segments") }
  segments
}

let parseMlxWhisperJson = (raw: string): array<Kuku_LocalWordAlign.timedWord> =>
  parseMlxWhisperSegments(raw)->Belt.Array.concatMany

let sanitizeProjectionWords = (
  words: array<Kuku_LocalWordAlign.timedWord>,
): array<Kuku_LocalWordAlign.timedWord> => {
  let clean: array<Kuku_LocalWordAlign.timedWord> = []
  words->Belt.Array.forEach(word => {
    if word.end_ -. word.start >= 0.02 {
      let duplicate = switch Belt.Array.get(clean, Belt.Array.length(clean) - 1) {
      | Some(prior) => prior.text == word.text &&
          Js.Math.abs_float(prior.start -. word.start) < 0.005 &&
          Js.Math.abs_float(prior.end_ -. word.end_) < 0.005
      | None => false
      }
      if !duplicate { Js.Array2.push(clean, word)->ignore }
    }
  })
  if Belt.Array.length(clean) == 0 { fail("local projection evidence has no nonzero lexical words") }
  clean
}

let floatAfter = (line: string, marker: string): option<float> => {
  let index = Js.String2.indexOf(line, marker)
  index < 0
    ? None
    : Js.String2.sliceToEnd(line, ~from=index + Js.String2.length(marker))
      ->trim
      ->Js.String2.split(" ")
      ->Belt.Array.get(0)
      ->Belt.Option.flatMap(Belt.Float.fromString)
}

let silenceGapCache: Js.Dict.t<array<Kuku_LocalWordAlign.silenceGap>> = Js.Dict.empty()

let detectLocalSilenceGapsWith = (
  ~cache: segmentCache,
  ~config: string,
  ~includeOuter=false,
): array<Kuku_LocalWordAlign.silenceGap> => {
  let result = run(
    ~cmd="ffmpeg",
    ~args=[
      "-nostdin", "-hide_banner", "-i", cache.rawPath,
      "-af", config, "-f", "null", "-",
    ],
  )
  if result.code != 0 { fail("local silence analysis failed for " ++ cache.segmentId) }
  let gaps: array<Kuku_LocalWordAlign.silenceGap> = []
  let pending: ref<option<float>> = ref(None)
  result.stderr->Js.String2.split("\n")->Belt.Array.forEach(line => {
    switch floatAfter(line, "silence_start:") {
    | Some(start) => pending := Some(start)
    | None => ()
    }
    switch (pending.contents, floatAfter(line, "silence_end:")) {
    | (Some(start), Some(end_)) => {
        if end_ > start && (includeOuter || (start > 0.01 && end_ < cache.duration -. 0.01)) {
          Js.Array2.push(gaps, {start, end_})->ignore
        }
        pending := None
      }
    | _ => ()
    }
  })
  gaps
}

let detectLocalSilenceGaps = (cache: segmentCache): array<Kuku_LocalWordAlign.silenceGap> =>
  detectLocalSilenceGapsWith(~cache, ~config=localSilenceConfig)

let localSilenceGaps = (cache: segmentCache): array<Kuku_LocalWordAlign.silenceGap> =>
  switch Js.Dict.get(silenceGapCache, cache.rawPath) {
  | Some(gaps) => gaps
  | None => {
      let gaps = detectLocalSilenceGaps(cache)
      Js.Dict.set(silenceGapCache, cache.rawPath, gaps)
      gaps
    }
  }

let nonverbalSilenceGapCache: Js.Dict.t<array<Kuku_LocalWordAlign.silenceGap>> = Js.Dict.empty()

let localNonverbalSilenceGaps = (cache: segmentCache): array<Kuku_LocalWordAlign.silenceGap> =>
  switch Js.Dict.get(nonverbalSilenceGapCache, cache.rawPath) {
  | Some(gaps) => gaps
  | None => {
      let gaps = detectLocalSilenceGapsWith(~cache, ~config=localNonverbalSilenceConfig)
      Js.Dict.set(nonverbalSilenceGapCache, cache.rawPath, gaps)
      gaps
    }
  }

let softSpeechSilenceGapCache: Js.Dict.t<array<Kuku_LocalWordAlign.silenceGap>> = Js.Dict.empty()
let softSpeechOuterSilenceGapCache: Js.Dict.t<array<Kuku_LocalWordAlign.silenceGap>> = Js.Dict.empty()

let localSoftSpeechSilenceGaps = (cache: segmentCache): array<Kuku_LocalWordAlign.silenceGap> =>
  switch Js.Dict.get(softSpeechSilenceGapCache, cache.rawPath) {
  | Some(gaps) => gaps
  | None => {
      let gaps = detectLocalSilenceGapsWith(~cache, ~config=localSoftSpeechSilenceConfig)
      Js.Dict.set(softSpeechSilenceGapCache, cache.rawPath, gaps)
      gaps
    }
  }

let localSoftSpeechOuterSilenceGaps = (cache: segmentCache): array<Kuku_LocalWordAlign.silenceGap> =>
  switch Js.Dict.get(softSpeechOuterSilenceGapCache, cache.rawPath) {
  | Some(gaps) => gaps
  | None => {
      let gaps = detectLocalSilenceGapsWith(
        ~cache,
        ~config=localSoftSpeechSilenceConfig,
        ~includeOuter=true,
      )
      Js.Dict.set(softSpeechOuterSilenceGapCache, cache.rawPath, gaps)
      gaps
    }
  }

let safeSilenceGapBetweenFrom = (
  ~gaps: array<Kuku_LocalWordAlign.silenceGap>,
  ~left: timedLine,
  ~right: timedLine,
): Kuku_LocalWordAlign.silenceGap => {
  let nominal = (left.end_ +. right.start) /. 2.0
  let relaxed = gaps->Belt.Array.keep(gap => {
    let midpoint = (gap.start +. gap.end_) /. 2.0
    gap.start >= left.end_ -. 1.50 && gap.end_ <= right.start +. 1.50 &&
    midpoint > left.start && midpoint < right.end_
  })
  let strict = relaxed->Belt.Array.keep(gap =>
    gap.start >= left.end_ -. 0.02 && gap.end_ <= right.start +. 0.02
  )
  /* Very short internal pauses are not line handoffs. Prefer a substantial
     quiet gap whenever one exists; this keeps K22's throat-break separate from
     the following copied “दीदी”. */
  let strictSubstantial = strict->Belt.Array.keep(gap => gap.end_ -. gap.start >= 0.12)
  let relaxedSubstantial = relaxed->Belt.Array.keep(gap => gap.end_ -. gap.start >= 0.12)
  let candidates = Belt.Array.length(strictSubstantial) > 0
    ? strictSubstantial
    : Belt.Array.length(relaxedSubstantial) > 0
      ? relaxedSubstantial
      : Belt.Array.length(strict) > 0 ? strict : relaxed
  if Belt.Array.length(candidates) == 0 {
    fail("no silence-safe cut between " ++ left.id ++ " and " ++ right.id)
  }
  candidates->Belt.Array.reduce(Belt.Array.getExn(candidates, 0), (best, gap) => {
    let bestDistance = Js.Math.abs_float((best.start +. best.end_) /. 2.0 -. nominal)
    let distance = Js.Math.abs_float((gap.start +. gap.end_) /. 2.0 -. nominal)
    distance < bestDistance ? gap : best
  })
}

let safeSilenceGapBetween = (
  ~cache: segmentCache,
  ~left: timedLine,
  ~right: timedLine,
): Kuku_LocalWordAlign.silenceGap =>
  safeSilenceGapBetweenFrom(~gaps=localSilenceGaps(cache), ~left, ~right)

let safeSoftSpeechSilenceGapBetween = (
  ~cache: segmentCache,
  ~left: timedLine,
  ~right: timedLine,
): Kuku_LocalWordAlign.silenceGap =>
  safeSilenceGapBetweenFrom(~gaps=localSoftSpeechSilenceGaps(cache), ~left, ~right)

let anchorFor = (
  ~expected: string,
  ~observed: array<Kuku_LocalWordAlign.timedWord>,
  ~mappedIndex: int,
): wordAnchor => {
  let mapped = Belt.Array.getExn(observed, mappedIndex)
  let best = ref({start: mapped.start, end_: mapped.end_, similarity: Kuku_LocalWordAlign.wordSimilarity(expected, mapped.text)})
  let consider = (left: int, right: int): unit => {
    if left >= 0 && right < Belt.Array.length(observed) {
      let first = Belt.Array.getExn(observed, left)
      let last = Belt.Array.getExn(observed, right)
      let text = Js.Array2.slice(observed, ~start=left, ~end_=right + 1)->Belt.Array.map(row => row.text)->Js.Array2.joinWith("")
      let similarity = Kuku_LocalWordAlign.wordSimilarity(expected, text)
      if similarity > best.contents.similarity +. 0.000001 {
        best := {start: first.start, end_: last.end_, similarity}
      }
    }
  }
  consider(mappedIndex - 1, mappedIndex)
  consider(mappedIndex, mappedIndex + 1)
  best.contents
}

let recoveryIndexFromMessage = (message: string): option<int> => {
  let marker = "segment "
  let markerIndex = Js.String2.indexOf(message, marker)
  if markerIndex < 0 {
    None
  } else {
    let tail = Js.String2.sliceToEnd(message, ~from=markerIndex + Js.String2.length(marker))
    tail->Js.String2.split(" ")->Belt.Array.get(0)->Belt.Option.flatMap(Belt.Int.fromString)
  }
}

let requestLineRecovery = (
  ~segment: dialogueSegment,
  ~spoken: array<dialogueLine>,
  ~index: int,
  ~reason: string,
): 'a => {
  if index < 0 || index >= Belt.Array.length(spoken) {
    fail(segment.id ++ " local alignment named an invalid spoken-line index: " ++ reason)
  }
  let row = Belt.Array.getExn(spoken, index)
  raise(LocalLineRecovery(index, row.id, reason))
}

let safeNonverbalWindow = (
  ~cache: segmentCache,
  ~row: dialogueLine,
  ~priorEnd: float,
  ~nextStart: float,
): timedLine => {
  if nextStart <= priorEnd +. 0.08 {
    fail("local neighbours leave no acoustic nonverbal window for " ++ row.id)
  }
  let clippedGaps = localNonverbalSilenceGaps(cache)->Belt.Array.keepMap(gap => {
    let start = floatMax(priorEnd, gap.start)
    let end_ = floatMin(nextStart, gap.end_)
    end_ > start +. 0.015 ? Some({start, end_}: Kuku_LocalWordAlign.silenceGap) : None
  })
  let activities: array<Kuku_LocalWordAlign.silenceGap> = []
  let cursor = ref(priorEnd)
  clippedGaps->Belt.Array.forEach(gap => {
    if gap.start > cursor.contents +. 0.08 {
      Js.Array2.push(activities, {start: cursor.contents, end_: gap.start})->ignore
    }
    cursor := floatMax(cursor.contents, gap.end_)
  })
  if nextStart > cursor.contents +. 0.08 {
    Js.Array2.push(activities, {start: cursor.contents, end_: nextStart})->ignore
  }
  if Belt.Array.length(activities) == 0 {
    fail("no detected non-speech activity island for " ++ row.id)
  }
  /* Provider turn clocks can drift by whole lines. The longest bounded
     non-silent island between the two lexically proven neighbours is the only
     safe generic choice for a tag-only laugh/breath event. */
  let activity = activities->Belt.Array.reduce(Belt.Array.getExn(activities, 0), (best, item) =>
    item.end_ -. item.start > best.end_ -. best.start ? item : best
  )
  let start = activity.start +. 0.015
  let end_ = activity.end_ -. 0.015
  if end_ <= start +. 0.05 { fail("nonverbal activity island is too short for " ++ row.id) }
  {id: row.id, start, end_}
}

let deriveLocalTimings = (
  ~segment: dialogueSegment,
  ~cache: segmentCache,
  ~observed: array<Kuku_LocalWordAlign.timedWord>,
  ~evidenceLabel: string,
  ~recoveredLineIds: array<string>,
): (array<timedLine>, Kuku_LocalWordAlign.quality) => {
  let spoken = segment.lines->Belt.Array.keep(row => row.requireInSource)
  let known = spoken->Belt.Array.mapWithIndex((index, row) =>
    ({order: index, text: row.text}: Kuku_LocalWordAlign.knownSegment)
  )
  let gaps = localSilenceGaps(cache)
  let derived = try Kuku_LocalWordAlign.deriveWithQualityFloor(
    known,
    observed,
    gaps,
    ~minimumCoverage=0.70,
    ~minimumObservedPrecision=0.62,
    ~minimumMeanSimilarity=0.75,
    ~minimumSequenceScore=0.52,
  ) catch {
  | Kuku_LocalWordAlign.LocalWordAlignment(message) => switch recoveryIndexFromMessage(message) {
    | Some(index) => requestLineRecovery(
        ~segment,
        ~spoken,
        ~index,
        ~reason=segment.id ++ " " ++ evidenceLabel ++ " global alignment rejected: " ++ message,
      )
    | None => fail(segment.id ++ " " ++ evidenceLabel ++ " global alignment rejected: " ++ message)
    }
  }
  let expected = Kuku_LocalWordAlign.flattenExpected(known)
  let sequence = Kuku_LocalWordAlign.sequenceAlign(expected, observed)
  let provisional: array<timedLine> = []
  let expectedCursor = ref(0)
  let spokenCursor = ref(0)
  segment.lines->Belt.Array.forEach(row => {
    if row.requireInSource {
      let words = Kuku_LocalWordAlign.normalizedWords(row.text)
      let firstExpectedIndex = expectedCursor.contents
      let lastExpectedIndex = expectedCursor.contents + Belt.Array.length(words) - 1
      let firstObservedIndex = switch Belt.Array.getExn(sequence.observedByExpected, firstExpectedIndex) {
      | Some(value) => value
      | None => requestLineRecovery(
          ~segment, ~spoken, ~index=spokenCursor.contents,
          ~reason=segment.id ++ "/" ++ row.id ++ " " ++ evidenceLabel ++ " has no first-word mapping",
        )
      }
      let lastObservedIndex = switch Belt.Array.getExn(sequence.observedByExpected, lastExpectedIndex) {
      | Some(value) => value
      | None => requestLineRecovery(
          ~segment, ~spoken, ~index=spokenCursor.contents,
          ~reason=segment.id ++ "/" ++ row.id ++ " " ++ evidenceLabel ++ " has no last-word mapping",
        )
      }
      let first = anchorFor(
        ~expected=Belt.Array.getExn(words, 0), ~observed, ~mappedIndex=firstObservedIndex,
      )
      let last = anchorFor(
        ~expected=Belt.Array.getExn(words, Belt.Array.length(words) - 1),
        ~observed,
        ~mappedIndex=lastObservedIndex,
      )
      if first.similarity < localEdgeSimilarityFloor || last.similarity < localEdgeSimilarityFloor {
        requestLineRecovery(
          ~segment, ~spoken, ~index=spokenCursor.contents,
          ~reason=segment.id ++ "/" ++ row.id ++ " " ++ evidenceLabel ++
            " edge anchors rejected: first=" ++ Js.Float.toFixedWithPrecision(first.similarity, ~digits=3) ++
            ", last=" ++ Js.Float.toFixedWithPrecision(last.similarity, ~digits=3),
        )
      }
      let block = Belt.Array.getExn(derived.blocks, spokenCursor.contents)
      if starts(row.id, "U") {
        let allExact = words->Belt.Array.mapWithIndex((localIndex, word) => {
          switch Belt.Array.getExn(sequence.observedByExpected, expectedCursor.contents + localIndex) {
          | Some(observedIndex) => Belt.Array.getExn(observed, observedIndex).text == word
          | None => false
          }
        })->Belt.Array.every(value => value)
        if !allExact || block.matchedWords != Belt.Array.length(words) || block.coverage < 0.999 {
          requestLineRecovery(
            ~segment, ~spoken, ~index=spokenCursor.contents,
            ~reason="critical reply " ++ row.id ++ " must be a complete exact local lexical match",
          )
        }
      }
      let coarse = switch Belt.Array.getBy(cache.timings, timing => timing.id == row.id) {
      | Some(value) => value
      | None => fail("provider proximity window is missing for " ++ row.id)
      }
      let locallyRecovered = Belt.Array.some(recoveredLineIds, id => id == row.id)
      let maximumTail = locallyRecovered ? localTurnTailPadding : 2.0
      let maximumOnsetDrift = locallyRecovered ? localTurnTailPadding : 0.25
      if first.start < coarse.start -. 2.0 || last.end_ > coarse.end_ +. maximumTail ||
         first.start > coarse.end_ +. maximumOnsetDrift || last.end_ < coarse.start -. 0.25 ||
         last.end_ <= first.start {
        requestLineRecovery(
          ~segment, ~spoken, ~index=spokenCursor.contents,
          ~reason=segment.id ++ "/" ++ row.id ++ " " ++ evidenceLabel ++ " escaped its coarse turn window",
        )
      }
      Js.Array2.push(provisional, {id: row.id, start: first.start, end_: last.end_})->ignore
      expectedCursor := expectedCursor.contents + Belt.Array.length(words)
      spokenCursor := spokenCursor.contents + 1
    } else {
      let timing = switch Belt.Array.getBy(cache.timings, timing => timing.id == row.id) {
      | Some(value) => value
      | None => fail("provider fallback timing is missing for " ++ row.id)
      }
      Js.Array2.push(provisional, timing)->ignore
    }
  })
  let rows = provisional->Belt.Array.mapWithIndex((index, row) => {
    let source = Belt.Array.getExn(segment.lines, index)
    if source.requireInSource { row } else {
      let priorEnd = index == 0 ? 0.0 : Belt.Array.getExn(provisional, index - 1).end_
      let nextStart = index == Belt.Array.length(provisional) - 1
        ? cache.duration
        : Belt.Array.getExn(provisional, index + 1).start
      safeNonverbalWindow(~cache, ~row=source, ~priorEnd, ~nextStart)
    }
  })
  validateTimings(~segment, ~rows, ~duration=cache.duration)
  if Belt.Array.length(rows) > 1 {
    for index in 0 to Belt.Array.length(rows) - 2 {
      safeSilenceGapBetween(
        ~cache,
        ~left=Belt.Array.getExn(rows, index),
        ~right=Belt.Array.getExn(rows, index + 1),
      )->ignore
    }
  }
  (rows, derived.quality)
}

let runLocalMlxWhisper = (
  ~segment: dialogueSegment,
  ~cache: segmentCache,
  ~context: localAlignmentContext,
): string => {
  let destination = localRawAlignmentPath(~segment, ~cache)
  if exists(Path(destination)) {
    parseMlxWhisperJson(readText(Path(destination)))->ignore
    destination
  } else {
    let scratch = tempDir("third-echo-local-mlx-")->pathString
    let outputName = segment.id ++ "_" ++ shortHash(localAlignmentKey(~segment, ~cache))
    let outputJson = scratch ++ "/" ++ outputName ++ ".json"
    Js.log("LOCAL MLX WHISPER -> " ++ segment.id ++ " (zero provider calls)")
    let result = run(
      ~cmd="/usr/bin/env",
      ~args=[
        "HF_HUB_OFFLINE=1",
        "TRANSFORMERS_OFFLINE=1",
        localMlxPython,
        "-m", "mlx_whisper.cli",
        cache.rawPath,
        "--model", context.modelPath,
        "--output-name", outputName,
        "--output-dir", scratch,
        "--output-format", "json",
        "--verbose", "False",
        "--task", "transcribe",
        "--language", "hi",
        "--temperature", "0",
        "--best-of", "5",
        "--condition-on-previous-text", "True",
        "--word-timestamps", "True",
      ],
    )
    if result.code != 0 || !exists(Path(outputJson)) {
      fail(
        "local MLX Whisper failed for " ++ segment.id ++ ": " ++
        Js.String2.sliceToEnd(result.stderr ++ "\n" ++ result.stdout, ~from=max(0, Js.String2.length(result.stderr ++ "\n" ++ result.stdout) - 1200)),
      )
    }
    parseMlxWhisperJson(readText(Path(outputJson)))->ignore
    ensureDirPath(Path(localAlignmentRawDir))
    if !publishFileExclusive(Path(outputJson), Path(destination)) {
      fail("immutable local MLX cache appeared during publication: " ++ destination)
    }
    destination
  }
}

let verifyLocalTurnEvidence = (
  ~segment: dialogueSegment,
  ~cache: segmentCache,
  ~row: dialogueLine,
  ~coarse: timedLine,
): option<localSupplement> => {
  let rawPath = localTurnRawPath(~segment, ~cache, ~row, ~coarse)
  let receiptPath = localTurnReceiptPath(~segment, ~cache, ~row, ~coarse)
  let hasRaw = exists(Path(rawPath))
  let hasReceipt = exists(Path(receiptPath))
  if !hasRaw && !hasReceipt {
    None
  } else if hasRaw != hasReceipt {
    fail("local turn-recovery cache is incomplete for " ++ segment.id ++ "/" ++ row.id)
  } else {
    parseMlxWhisperJson(readText(Path(rawPath)))->ignore
    let requestSha256 = localTurnRecoveryKey(~segment, ~cache, ~row, ~coarse)
    let (clipStart, clipEnd) = localTurnBounds(~cache, ~coarse)
    let receipt = Js.Json.parseExn(readText(Path(receiptPath)))
    if stringField(receipt, "schema") != "kaali-mitti.local-turn-evidence/v1" ||
       stringField(receipt, "request_sha256") != requestSha256 ||
       stringField(receipt, "segment_id") != segment.id ||
       stringField(receipt, "line_id") != row.id ||
       stringField(receipt, "audio_sha256") != sha256File(Path(cache.rawPath)) ||
       stringField(receipt, "transcript_sha256") != sha256Text(row.text) ||
       stringField(receipt, "raw_json") != rawPath ||
       stringField(receipt, "raw_json_sha256") != sha256File(Path(rawPath)) ||
       stringField(receipt, "alignment_config") != localTurnAlignmentConfig ||
       stringField(receipt, "model_config_sha256") != approvedMlxModelConfigSha256 ||
       stringField(receipt, "model_weights_sha256") != approvedMlxModelWeightsSha256 ||
       Js.Math.abs_float(numberField(receipt, "clip_start_seconds") -. clipStart) > 0.001 ||
       Js.Math.abs_float(numberField(receipt, "clip_end_seconds") -. clipEnd) > 0.001 ||
       stringField(receipt, "provider_calls") != "0" {
      fail("local turn-recovery receipt does not match " ++ segment.id ++ "/" ++ row.id)
    }
    Some({
      lineId: row.id,
      requestSha256,
      rawPath,
      receiptPath,
      clipStart,
      clipEnd,
      anchorSource: "unselected",
    })
  }
}

let runLocalTurnMlxWhisper = (
  ~segment: dialogueSegment,
  ~cache: segmentCache,
  ~row: dialogueLine,
  ~coarse: timedLine,
  ~context: localAlignmentContext,
): localSupplement => switch verifyLocalTurnEvidence(~segment, ~cache, ~row, ~coarse) {
| Some(value) => value
| None => {
    let requestSha256 = localTurnRecoveryKey(~segment, ~cache, ~row, ~coarse)
    let (clipStart, clipEnd) = localTurnBounds(~cache, ~coarse)
    let scratch = tempDir("third-echo-local-turn-")->pathString
    let clipPath = scratch ++ "/" ++ row.id ++ ".wav"
    let outputName = segment.id ++ "_" ++ row.id ++ "_" ++ shortHash(requestSha256)
    let outputJson = scratch ++ "/" ++ outputName ++ ".json"
    let trimResult = run(
      ~cmd="ffmpeg",
      ~args=[
        "-nostdin", "-v", "error", "-i", cache.rawPath,
        "-ss", Js.Float.toString(clipStart),
        "-t", Js.Float.toString(clipEnd -. clipStart),
        "-vn", "-ar", "16000", "-ac", "1", "-c:a", "pcm_s16le", clipPath,
      ],
    )
    if trimResult.code != 0 || !exists(Path(clipPath)) {
      fail("could not make physical PCM recovery clip for " ++ segment.id ++ "/" ++ row.id)
    }
    let clipDuration = validateAudio(clipPath, "local recovery clip " ++ segment.id ++ "/" ++ row.id)
    if Js.Math.abs_float(clipDuration -. (clipEnd -. clipStart)) > 0.12 {
      fail("physical PCM recovery clip duration drifted for " ++ segment.id ++ "/" ++ row.id)
    }
    Js.log("LOCAL MLX TURN RECOVERY -> " ++ segment.id ++ "/" ++ row.id ++ " (zero provider calls)")
    let result = run(
      ~cmd="/usr/bin/env",
      ~args=[
        "HF_HUB_OFFLINE=1",
        "TRANSFORMERS_OFFLINE=1",
        localMlxPython,
        "-m", "mlx_whisper.cli",
        clipPath,
        "--model", context.modelPath,
        "--output-name", outputName,
        "--output-dir", scratch,
        "--output-format", "json",
        "--verbose", "False",
        "--task", "transcribe",
        "--language", "hi",
        "--temperature", "0",
        "--best-of", "5",
        "--condition-on-previous-text", "False",
        "--word-timestamps", "True",
      ],
    )
    if result.code != 0 || !exists(Path(outputJson)) {
      fail(
        "local MLX turn recovery failed for " ++ segment.id ++ "/" ++ row.id ++ ": " ++
        Js.String2.sliceToEnd(
          result.stderr ++ "\n" ++ result.stdout,
          ~from=max(0, Js.String2.length(result.stderr ++ "\n" ++ result.stdout) - 1200),
        ),
      )
    }
    parseMlxWhisperJson(readText(Path(outputJson)))->ignore
    ensureDirPath(Path(localAlignmentRawDir))
    let rawPath = localTurnRawPath(~segment, ~cache, ~row, ~coarse)
    if !publishFileExclusive(Path(outputJson), Path(rawPath)) {
      fail("immutable local turn evidence appeared during publication: " ++ rawPath)
    }
    let receiptPath = localTurnReceiptPath(~segment, ~cache, ~row, ~coarse)
    let receipt = Js.Dict.empty()
    addString(receipt, "schema", "kaali-mitti.local-turn-evidence/v1")
    addString(receipt, "request_sha256", requestSha256)
    addString(receipt, "segment_id", segment.id)
    addString(receipt, "line_id", row.id)
    addString(receipt, "audio", cache.rawPath)
    addString(receipt, "audio_sha256", sha256File(Path(cache.rawPath)))
    addString(receipt, "transcript", row.text)
    addString(receipt, "transcript_sha256", sha256Text(row.text))
    addNumber(receipt, "provider_core_start_seconds", coarse.start)
    addNumber(receipt, "provider_core_end_seconds", coarse.end_)
    addNumber(receipt, "clip_start_seconds", clipStart)
    addNumber(receipt, "clip_end_seconds", clipEnd)
    addString(receipt, "pcm_recipe", "ffmpeg|pcm_s16le|16000Hz|mono|physical temporary clip")
    addString(receipt, "alignment_config", localTurnAlignmentConfig)
    addString(receipt, "python_sha256", approvedLocalPythonSha256)
    addString(receipt, "mlx_cli_sha256", approvedMlxCliSha256)
    addString(receipt, "mlx_transcribe_sha256", approvedMlxTranscribeSha256)
    addString(receipt, "mlx_writers_sha256", approvedMlxWritersSha256)
    addString(receipt, "model_config_sha256", approvedMlxModelConfigSha256)
    addString(receipt, "model_weights_sha256", approvedMlxModelWeightsSha256)
    addString(receipt, "raw_json", rawPath)
    addString(receipt, "raw_json_sha256", sha256File(Path(rawPath)))
    addString(receipt, "provider_calls", "0")
    if !writeTextExclusive(
      Path(receiptPath),
      Js.Json.stringifyWithSpace(Js.Json.object_(receipt), 1) ++ "\n",
    ) {
      fail("local turn evidence receipt already exists unexpectedly: " ++ receiptPath)
    }
    {
      lineId: row.id,
      requestSha256,
      rawPath,
      receiptPath,
      clipStart,
      clipEnd,
      anchorSource: "unselected",
    }
  }
}

let shiftedTurnWords = (supplement: localSupplement): array<Kuku_LocalWordAlign.timedWord> =>
  sanitizeProjectionWords(parseMlxWhisperJson(readText(Path(supplement.rawPath))))
  ->Belt.Array.map((word: Kuku_LocalWordAlign.timedWord) =>
    ({
      text: word.text,
      start: word.start +. supplement.clipStart,
      end_: word.end_ +. supplement.clipStart,
      probability: word.probability,
    }: Kuku_LocalWordAlign.timedWord)
  )

let recoverLexicalBlock = (
  ~row: dialogueLine,
  ~coarse: timedLine,
  ~observed: array<Kuku_LocalWordAlign.timedWord>,
  ~label: string,
): recoveredLexicalBlock => {
  let windowStart = coarse.start -. localTurnLeadPadding -. 0.30
  let windowEnd = coarse.end_ +. localTurnTailPadding +. 0.30
  let expectedWords = Kuku_LocalWordAlign.normalizedWords(row.text)
  let lastExpected = Belt.Array.getExn(expectedWords, Belt.Array.length(expectedWords) - 1)
  let rawWindow = observed->Belt.Array.keep(word => word.end_ >= windowStart && word.start <= windowEnd)
  let window: array<Kuku_LocalWordAlign.timedWord> = []
  rawWindow->Belt.Array.forEach(word => {
    /* Hindi ASR commonly joins an enclitic final word (for example खोलो ना ->
       कुलूना). In a physically bounded single-turn clip, expose only an exact
       expected suffix as its own timed token; the unmatched prefix remains and
       must still survive the normal coverage/quality gate. */
    if word.text != lastExpected && Js.String2.endsWith(word.text, lastExpected) {
      let prefixText = Js.String2.slice(
        word.text,
        ~from=0,
        ~to_=Js.String2.length(word.text) - Js.String2.length(lastExpected),
      )
      if prefixText != "" {
        let split = word.start +. (word.end_ -. word.start) *.
          Belt.Int.toFloat(Js.String2.length(prefixText)) /.
          Belt.Int.toFloat(Js.String2.length(word.text))
        Js.Array2.push(window, ({
          text: prefixText,
          start: word.start,
          end_: split,
          probability: word.probability,
        }: Kuku_LocalWordAlign.timedWord))->ignore
        Js.Array2.push(window, ({
          text: lastExpected,
          start: split,
          end_: word.end_,
          probability: word.probability,
        }: Kuku_LocalWordAlign.timedWord))->ignore
      } else {
        Js.Array2.push(window, word)->ignore
      }
    } else {
      Js.Array2.push(window, word)->ignore
    }
  })
  if Belt.Array.length(window) == 0 {
    fail(label ++ " has no local words near provider core " ++ row.id)
  }
  let known = [({order: 0, text: row.text}: Kuku_LocalWordAlign.knownSegment)]
  let expected = Kuku_LocalWordAlign.flattenExpected(known)
  let sequence = Kuku_LocalWordAlign.sequenceAlign(expected, window)
  let firstMapped = switch Belt.Array.getExn(sequence.observedByExpected, 0) {
  | Some(value) => value
  | None => fail(label ++ " has no first-word mapping for " ++ row.id)
  }
  let lastMapped = switch Belt.Array.getExn(
    sequence.observedByExpected,
    Belt.Array.length(expectedWords) - 1,
  ) {
  | Some(value) => value
  | None => fail(label ++ " has no last-word mapping for " ++ row.id)
  }
  let first = anchorFor(
    ~expected=Belt.Array.getExn(expectedWords, 0),
    ~observed=window,
    ~mappedIndex=firstMapped,
  )
  let last = anchorFor(
    ~expected=Belt.Array.getExn(expectedWords, Belt.Array.length(expectedWords) - 1),
    ~observed=window,
    ~mappedIndex=lastMapped,
  )
  if first.similarity < localEdgeSimilarityFloor || last.similarity < localEdgeSimilarityFloor {
    fail(
      label ++ " edge anchors rejected for " ++ row.id ++ ": first=" ++
      Js.Float.toFixedWithPrecision(first.similarity, ~digits=3) ++ ", last=" ++
      Js.Float.toFixedWithPrecision(last.similarity, ~digits=3),
    )
  }
  let strong = ref(0)
  let similaritySum = ref(0.0)
  let strongByExpected = Belt.Array.make(Belt.Array.length(expectedWords), false)
  expectedWords->Belt.Array.forEachWithIndex((index, expectedWord) => {
    switch Belt.Array.getExn(sequence.observedByExpected, index) {
    | Some(observedIndex) => {
        let observedWord = Belt.Array.getExn(window, observedIndex)
        let similarity = Kuku_LocalWordAlign.wordSimilarity(expectedWord, observedWord.text)
        if Kuku_LocalWordAlign.isStrong(expectedWord, observedWord.text, similarity) {
          Belt.Array.setExn(strongByExpected, index, true)
          strong := strong.contents + 1
          similaritySum := similaritySum.contents +. similarity
        }
      }
    | None => ()
    }
  })
  let countCombinedEdge = (index: int, anchor: wordAnchor): unit => {
    let expectedWord = Belt.Array.getExn(expectedWords, index)
    let threshold = Kuku_LocalWordAlign.strongThreshold(expectedWord, expectedWord)
    if !Belt.Array.getExn(strongByExpected, index) && anchor.similarity >= threshold {
      Belt.Array.setExn(strongByExpected, index, true)
      strong := strong.contents + 1
      similaritySum := similaritySum.contents +. anchor.similarity
    }
  }
  countCombinedEdge(0, first)
  if Belt.Array.length(expectedWords) > 1 {
    countCombinedEdge(Belt.Array.length(expectedWords) - 1, last)
  }
  let coverage = Belt.Int.toFloat(strong.contents) /. Belt.Int.toFloat(Belt.Array.length(expectedWords))
  let meanSimilarity = strong.contents == 0
    ? 0.0
    : similaritySum.contents /. Belt.Int.toFloat(strong.contents)
  let minimumCoverage = Belt.Array.length(expectedWords) <= 1 ? 1.0 : 0.50
  if coverage < minimumCoverage || meanSimilarity < 0.75 {
    fail(
      label ++ " lexical gate rejected " ++ row.id ++ ": coverage=" ++
      Js.Float.toFixedWithPrecision(coverage, ~digits=3) ++ ", mean_similarity=" ++
      Js.Float.toFixedWithPrecision(meanSimilarity, ~digits=3),
    )
  }
  if starts(row.id, "U") {
    let allExact = expectedWords->Belt.Array.mapWithIndex((index, expectedWord) =>
      switch Belt.Array.getExn(sequence.observedByExpected, index) {
      | Some(observedIndex) => Belt.Array.getExn(window, observedIndex).text == expectedWord
      | None => false
      }
    )->Belt.Array.every(value => value)
    if !allExact || strong.contents != Belt.Array.length(expectedWords) {
      fail("critical reply " ++ row.id ++ " lacks complete exact turn-recovery evidence")
    }
  }
  if last.end_ <= first.start || first.start > coarse.end_ +. localTurnTailPadding ||
     last.end_ < coarse.start -. localTurnLeadPadding {
    fail(label ++ " recovered " ++ row.id ++ " outside its provider-associated turn")
  }
  let selected = window->Belt.Array.keep(word =>
    word.end_ > first.start -. 0.001 && word.start < last.end_ +. 0.001
  )
  let collapseExactObservedJoin = (
    words: array<Kuku_LocalWordAlign.timedWord>,
    anchor: wordAnchor,
  ): array<Kuku_LocalWordAlign.timedWord> => {
    let joined = words->Belt.Array.keep(word =>
      word.start >= anchor.start -. 0.001 && word.end_ <= anchor.end_ +. 0.001
    )
    if Belt.Array.length(joined) <= 1 {
      words
    } else {
      let probability = joined->Belt.Array.reduce(
        Belt.Array.getExn(joined, 0).probability,
        (lowest, word) => floatMin(lowest, word.probability),
      )
      let combined: Kuku_LocalWordAlign.timedWord = {
        text: joined->Belt.Array.map(word => word.text)->Js.Array2.joinWith(""),
        start: Belt.Array.getExn(joined, 0).start,
        end_: Belt.Array.getExn(joined, Belt.Array.length(joined) - 1).end_,
        probability,
      }
      let collapsed = Js.Array2.concat(
        words->Belt.Array.keep(word =>
          word.end_ <= anchor.start +. 0.001 || word.start >= anchor.end_ -. 0.001
        ),
        [combined],
      )
      Js.Array2.sortInPlaceWith(collapsed, (left, right) =>
        left.start < right.start ? -1 : left.start > right.start ? 1 : 0
      )->ignore
      collapsed
    }
  }
  /* Never collapse adjacent evidence for a one-word line: the neighbour can be
     a deliberate repeated/copy line (K22 “दी—” immediately before ES06
     “दीदी!”). */
  let firstCollapsed = Belt.Array.length(expectedWords) > 1
    ? collapseExactObservedJoin(selected, first)
    : selected
  let words = Belt.Array.length(expectedWords) > 1
    ? collapseExactObservedJoin(firstCollapsed, last)
    : firstCollapsed
  if Belt.Array.length(words) == 0 { fail(label ++ " recovered an empty lexical block for " ++ row.id) }
  {words, start: first.start, end_: last.end_, coverage, meanSimilarity}
}

let mergeRecoveredBlock = (
  ~base: array<Kuku_LocalWordAlign.timedWord>,
  ~replacement: recoveredLexicalBlock,
): array<Kuku_LocalWordAlign.timedWord> => {
  let retained = base->Belt.Array.keep(word =>
    word.end_ <= replacement.start -. 0.015 || word.start >= replacement.end_ +. 0.015
  )
  let merged = Js.Array2.concat(retained, replacement.words)
  Js.Array2.sortInPlaceWith(merged, (left, right) =>
    left.start < right.start ? -1 : left.start > right.start ? 1 : 0
  )->ignore
  sanitizeProjectionWords(merged)
}

let recoverOneLocalLine = (
  ~segment: dialogueSegment,
  ~cache: segmentCache,
  ~row: dialogueLine,
  ~context: localAlignmentContext,
  ~primaryObserved: array<Kuku_LocalWordAlign.timedWord>,
  ~baseObserved: array<Kuku_LocalWordAlign.timedWord>,
): (array<Kuku_LocalWordAlign.timedWord>, localSupplement) => {
  let coarse = switch Belt.Array.getBy(cache.timings, timing => timing.id == row.id) {
  | Some(value) => value
  | None => fail("provider proximity window is missing for turn recovery " ++ row.id)
  }
  let pending = runLocalTurnMlxWhisper(~segment, ~cache, ~row, ~coarse, ~context)
  /* The physical no-context crop is independent lexical proof. Its word clocks
     can start at zero in leading silence, so a full-take MLX block is preferred
     as the temporal replacement when the same edge/coverage gates pass. */
  let proof = recoverLexicalBlock(
    ~row,
    ~coarse,
    ~observed=shiftedTurnWords(pending),
    ~label=segment.id ++ "/" ++ row.id ++ " bounded MLX proof",
  )
  let primaryAttempt = try Some(recoverLexicalBlock(
    ~row,
    ~coarse,
    ~observed=primaryObserved,
    ~label=segment.id ++ "/" ++ row.id ++ " full-take MLX anchor",
  )) catch {
  | ThirdEchoError(_) => None
  }
  let (replacement, anchorSource) = switch primaryAttempt {
  | Some(block) => (block, "mlx_primary_global")
  | None => (proof, "mlx_bounded_turn")
  }
  let supplement = {...pending, anchorSource}
  (mergeRecoveredBlock(~base=baseObserved, ~replacement), supplement)
}

let deriveWithTurnRecovery = (
  ~segment: dialogueSegment,
  ~cache: segmentCache,
  ~context: localAlignmentContext,
  ~primaryObserved: array<Kuku_LocalWordAlign.timedWord>,
  ~baseObserved: array<Kuku_LocalWordAlign.timedWord>,
  ~evidenceLabel: string,
): (array<timedLine>, Kuku_LocalWordAlign.quality, array<localSupplement>) => {
  let rec loop = (
    observed: array<Kuku_LocalWordAlign.timedWord>,
    supplements: array<localSupplement>,
  ) => try {
    let recoveredLineIds = supplements->Belt.Array.map(item => item.lineId)
    let (rows, quality) = deriveLocalTimings(
      ~segment, ~cache, ~observed, ~evidenceLabel, ~recoveredLineIds,
    )
    (rows, quality, supplements)
  } catch {
  | LocalLineRecovery(index, lineId, reason) => {
      if Belt.Array.some(supplements, item => item.lineId == lineId) {
        fail(segment.id ++ "/" ++ lineId ++ " still failed after bounded turn recovery: " ++ reason)
      }
      let spoken = segment.lines->Belt.Array.keep(row => row.requireInSource)
      if index < 0 || index >= Belt.Array.length(spoken) {
        fail("turn recovery index escaped " ++ segment.id)
      }
      let row = Belt.Array.getExn(spoken, index)
      if row.id != lineId { fail("turn recovery line identity mismatch for " ++ segment.id) }
      let (merged, supplement) = recoverOneLocalLine(
        ~segment, ~cache, ~row, ~context, ~primaryObserved, ~baseObserved=observed,
      )
      Js.log("LOCAL TURN EVIDENCE MERGED -> " ++ segment.id ++ "/" ++ lineId)
      loop(merged, Js.Array2.concat(supplements, [supplement]))
    }
  | ThirdEchoError(message) if contains(
      message,
      "global alignment rejected: low-confidence local alignment",
    ) => {
      /* A globally weak two-line take cannot name a failing segment. Recover
         each authored spoken turn independently, under the same edge-anchor
         and provider-association gates, then rerun the untouched global gate.
         If every turn has evidence and quality is still weak, fail closed. */
      let spoken = segment.lines->Belt.Array.keep(row => row.requireInSource)
      let nextIndex = ref(-1)
      for index in 0 to Belt.Array.length(spoken) - 1 {
        let row = Belt.Array.getExn(spoken, index)
        if nextIndex.contents < 0 && !Belt.Array.some(supplements, item => item.lineId == row.id) {
          nextIndex := index
        }
      }
      if nextIndex.contents < 0 {
        fail(segment.id ++ " remains globally low-quality after bounded evidence for every spoken line: " ++ message)
      }
      let row = Belt.Array.getExn(spoken, nextIndex.contents)
      let (merged, supplement) = recoverOneLocalLine(
        ~segment, ~cache, ~row, ~context, ~primaryObserved, ~baseObserved=observed,
      )
      Js.log("LOCAL ALL-LINE RECOVERY MERGED -> " ++ segment.id ++ "/" ++ row.id)
      loop(merged, Js.Array2.concat(supplements, [supplement]))
    }
  }
  loop(baseObserved, [])
}

let requireLocalWhisperCppModel = (): string => {
  let modelPath = envWhisperCppModel->Belt.Option.getWithDefault(defaultWhisperCppModel)
  assertLocalArtifact(
    ~label="local whisper.cpp 1.9.2 binary",
    ~path=localWhisperCpp,
    ~sha256=approvedWhisperCppSha256,
  )
  assertLocalArtifact(
    ~label="local whisper.cpp large-v3-turbo-q5_0 model",
    ~path=modelPath,
    ~sha256=approvedWhisperCppModelSha256,
  )
  modelPath
}

let runLocalWhisperCpp = (~segment: dialogueSegment, ~cache: segmentCache): string => {
  let destination = localWhisperCppRawPath(~segment, ~cache)
  if exists(Path(destination)) {
    Kuku_LocalWordAlign.parseWhisperJson(readText(Path(destination)))->ignore
    destination
  } else {
    let modelPath = requireLocalWhisperCppModel()
    let scratch = tempDir("third-echo-local-whisper-cpp-")->pathString
    let outputBase = scratch ++ "/" ++ segment.id ++ "_" ++
      shortHash(localWhisperCppKey(~segment, ~cache))
    let outputJson = outputBase ++ ".json"
    Js.log("LOCAL WHISPER.CPP FALLBACK -> " ++ segment.id ++ " (zero provider calls)")
    let result = run(
      ~cmd=localWhisperCpp,
      ~args=[
        "-m", modelPath,
        "-f", cache.rawPath,
        "-l", "hi",
        "-ojf",
        "-of", outputBase,
      ],
    )
    if result.code != 0 || !exists(Path(outputJson)) {
      fail(
        "local whisper.cpp fallback failed for " ++ segment.id ++ ": " ++
        Js.String2.sliceToEnd(
          result.stderr ++ "\n" ++ result.stdout,
          ~from=max(0, Js.String2.length(result.stderr ++ "\n" ++ result.stdout) - 1200),
        ),
      )
    }
    Kuku_LocalWordAlign.parseWhisperJson(readText(Path(outputJson)))->ignore
    ensureDirPath(Path(localAlignmentRawDir))
    if !publishFileExclusive(Path(outputJson), Path(destination)) {
      fail("immutable local whisper.cpp cache appeared during publication: " ++ destination)
    }
    destination
  }
}

let alignmentQualityJson = (quality: Kuku_LocalWordAlign.quality): Js.Json.t => {
  let root = Js.Dict.empty()
  addNumber(root, "expected_words", Belt.Int.toFloat(quality.expectedWords))
  addNumber(root, "observed_words", Belt.Int.toFloat(quality.observedWords))
  addNumber(root, "matched_words", Belt.Int.toFloat(quality.matchedWords))
  addNumber(root, "coverage", quality.coverage)
  addNumber(root, "observed_precision", quality.observedPrecision)
  addNumber(root, "mean_similarity", quality.meanSimilarity)
  addNumber(root, "sequence_score", quality.sequenceScore)
  addNumber(root, "average_token_probability", quality.averageTokenProbability)
  addNumber(root, "confidence", quality.confidence)
  Js.Json.object_(root)
}

let localSupplementJson = (supplement: localSupplement): Js.Json.t => {
  let root = Js.Dict.empty()
  addString(root, "line_id", supplement.lineId)
  addString(root, "request_sha256", supplement.requestSha256)
  addString(root, "raw_json", supplement.rawPath)
  addString(root, "raw_json_sha256", sha256File(Path(supplement.rawPath)))
  addString(root, "receipt", supplement.receiptPath)
  addString(root, "receipt_sha256", sha256File(Path(supplement.receiptPath)))
  addNumber(root, "clip_start_seconds", supplement.clipStart)
  addNumber(root, "clip_end_seconds", supplement.clipEnd)
  addString(root, "anchor_source", supplement.anchorSource)
  Js.Json.object_(root)
}

let supplementFingerprint = (supplements: array<localSupplement>): string => sha256Text(
  supplements->Belt.Array.map(supplement => Js.Array2.joinWith([
    supplement.lineId,
    supplement.requestSha256,
    sha256File(Path(supplement.rawPath)),
    sha256File(Path(supplement.receiptPath)),
    Js.Float.toString(supplement.clipStart),
    Js.Float.toString(supplement.clipEnd),
    supplement.anchorSource,
  ], "|"))->Js.Array2.joinWith("||"),
)

let alignmentJson = (
  ~segment: dialogueSegment,
  ~cache: segmentCache,
  ~rows: array<timedLine>,
  ~quality: Kuku_LocalWordAlign.quality,
  ~evidence: localEvidence,
  ~context: localAlignmentContext,
): string => {
  let mapped = transcriptMap(segment)
  let primaryRawPath = localRawAlignmentPath(~segment, ~cache)
  let root = Js.Dict.empty()
  addString(root, "schema", "kaali-mitti.local-line-alignment/v3")
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "method", evidence.method)
  addString(root, "algorithm_version", Kuku_LocalWordAlign.algorithmVersion)
  addString(root, "alignment_config", localAlignmentConfig)
  addString(root, "projection_version", localProjectionVersion)
  addString(root, "projection_sha256", sha256Text(localProjectionSignature(segment)))
  addString(root, "silence_config", localSilenceConfig)
  addString(root, "nonverbal_silence_config", localNonverbalSilenceConfig)
  addString(root, "segment_id", segment.id)
  addString(root, "request_sha256", localDerivedKey(~segment, ~cache))
  addString(root, "recipe_sha256", localAlignmentRecipeHash(segment))
  addString(root, "dialogue_request_sha256", dialogueRequestHash(segment))
  addString(root, "audio", cache.rawPath)
  addString(root, "audio_sha256", sha256File(Path(cache.rawPath)))
  addNumber(root, "audio_duration_seconds", cache.duration)
  addString(root, "transcript", mapped.text)
  addString(root, "transcript_sha256", sha256Text(mapped.text))
  addString(root, "primary_mlx_json", primaryRawPath)
  addString(root, "primary_mlx_json_sha256", sha256File(Path(primaryRawPath)))
  addString(root, "selected_evidence_json", evidence.rawPath)
  addString(root, "selected_evidence_json_sha256", sha256File(Path(evidence.rawPath)))
  switch evidence.fallbackReason {
  | Some(reason) => addString(root, "primary_rejection_reason", reason)
  | None => ()
  }
  addString(root, "turn_recovery_config", localTurnAlignmentConfig)
  addString(root, "turn_recovery_fingerprint", supplementFingerprint(evidence.supplements))
  addString(root, "mlx_version", localMlxVersion)
  addString(root, "python_sha256", approvedLocalPythonSha256)
  addString(root, "mlx_cli_sha256", approvedMlxCliSha256)
  addString(root, "mlx_transcribe_sha256", approvedMlxTranscribeSha256)
  addString(root, "mlx_writers_sha256", approvedMlxWritersSha256)
  addString(root, "model_path", context.modelPath)
  addString(root, "model_config_sha256", approvedMlxModelConfigSha256)
  addString(root, "model_weights_sha256", approvedMlxModelWeightsSha256)
  addString(root, "whisper_cpp_config", localWhisperCppConfig)
  addString(root, "whisper_cpp_binary_sha256", approvedWhisperCppSha256)
  addString(root, "whisper_cpp_model_sha256", approvedWhisperCppModelSha256)
  let legacyClaim = legacyCloudAlignmentClaimPath(segment)
  if exists(Path(legacyClaim)) {
    addString(root, "bypassed_failed_cloud_claim", legacyClaim)
    addString(root, "bypassed_failed_cloud_claim_sha256", sha256File(Path(legacyClaim)))
  }
  addString(root, "cloud_alignment_policy", "zero cloud alignment calls; any prior failed claim is retained unchanged and is not retried")
  Js.Dict.set(root, "quality", alignmentQualityJson(quality))
  Js.Dict.set(root, "turn_recovery_evidence", Js.Json.array(
    evidence.supplements->Belt.Array.map(localSupplementJson),
  ))
  Js.Dict.set(root, "provider_timing_fallback_lines", Js.Json.array(segment.lines->Belt.Array.keep(row => !row.requireInSource)->Belt.Array.map(row => Js.Json.string(row.id))))
  Js.Dict.set(root, "lines", Js.Json.array(rows->Belt.Array.map(timedLineJson)))
  Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n"
}

let writeAlignmentReceipt = (
  ~segment: dialogueSegment,
  ~cache: segmentCache,
  ~path: string,
  ~evidence: localEvidence,
): unit => {
  let root = Js.Dict.empty()
  addString(root, "schema", "kaali-mitti.local-line-alignment-receipt/v3")
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "segment_id", segment.id)
  addString(root, "request_sha256", localDerivedKey(~segment, ~cache))
  addString(root, "alignment", path)
  addString(root, "alignment_sha256", sha256File(Path(path)))
  addString(root, "evidence_method", evidence.method)
  addString(root, "selected_evidence_json", evidence.rawPath)
  addString(root, "selected_evidence_json_sha256", sha256File(Path(evidence.rawPath)))
  addString(root, "turn_recovery_fingerprint", supplementFingerprint(evidence.supplements))
  Js.Dict.set(root, "turn_recovery_evidence", Js.Json.array(
    evidence.supplements->Belt.Array.map(localSupplementJson),
  ))
  addString(root, "audio_sha256", sha256File(Path(cache.rawPath)))
  addString(root, "provider_calls", "0")
  if !writeTextExclusive(Path(dialogueAlignmentReceiptPath(~segment, ~cache)), Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n") {
    fail("local alignment receipt already exists unexpectedly: " ++ segment.id)
  }
}

let loadStoredSupplements = (
  ~segment: dialogueSegment,
  ~cache: segmentCache,
  json: Js.Json.t,
): array<localSupplement> => {
  let supplements: array<localSupplement> = []
  arrayField(json, "turn_recovery_evidence")->Belt.Array.forEach(item => {
    let lineId = stringField(item, "line_id")
    if Belt.Array.some(supplements, prior => prior.lineId == lineId) {
      fail("duplicate stored turn-recovery evidence for " ++ segment.id ++ "/" ++ lineId)
    }
    let row = switch Belt.Array.getBy(segment.lines, row => row.id == lineId && row.requireInSource) {
    | Some(value) => value
    | None => fail("stored turn-recovery evidence names an unknown spoken line " ++ lineId)
    }
    let coarse = switch Belt.Array.getBy(cache.timings, timing => timing.id == lineId) {
    | Some(value) => value
    | None => fail("stored turn-recovery evidence has no provider core for " ++ lineId)
    }
    let expected = switch verifyLocalTurnEvidence(~segment, ~cache, ~row, ~coarse) {
    | Some(value) => value
    | None => fail("stored turn-recovery evidence bytes are missing for " ++ lineId)
    }
    let anchorSource = stringField(item, "anchor_source")
    if anchorSource != "mlx_primary_global" && anchorSource != "mlx_bounded_turn" {
      fail("stored turn-recovery evidence has unknown anchor source for " ++ lineId)
    }
    if stringField(item, "request_sha256") != expected.requestSha256 ||
       stringField(item, "raw_json") != expected.rawPath ||
       stringField(item, "raw_json_sha256") != sha256File(Path(expected.rawPath)) ||
       stringField(item, "receipt") != expected.receiptPath ||
       stringField(item, "receipt_sha256") != sha256File(Path(expected.receiptPath)) ||
       Js.Math.abs_float(numberField(item, "clip_start_seconds") -. expected.clipStart) > 0.001 ||
       Js.Math.abs_float(numberField(item, "clip_end_seconds") -. expected.clipEnd) > 0.001 {
      fail("stored turn-recovery evidence does not match immutable cache for " ++ lineId)
    }
    Js.Array2.push(supplements, {...expected, anchorSource})->ignore
  })
  supplements
}

let applyStoredSupplements = (
  ~segment: dialogueSegment,
  ~cache: segmentCache,
  ~primaryObserved: array<Kuku_LocalWordAlign.timedWord>,
  ~baseObserved: array<Kuku_LocalWordAlign.timedWord>,
  ~supplements: array<localSupplement>,
): array<Kuku_LocalWordAlign.timedWord> => {
  let observed = ref(baseObserved)
  supplements->Belt.Array.forEach(supplement => {
    let row = Belt.Array.getBy(segment.lines, row => row.id == supplement.lineId)
      ->Belt.Option.getExn
    let coarse = Belt.Array.getBy(cache.timings, timing => timing.id == supplement.lineId)
      ->Belt.Option.getExn
    let proof = recoverLexicalBlock(
      ~row,
      ~coarse,
      ~observed=shiftedTurnWords(supplement),
      ~label=segment.id ++ "/" ++ row.id ++ " stored bounded MLX proof",
    )
    let replacement = switch supplement.anchorSource {
    | "mlx_primary_global" => recoverLexicalBlock(
        ~row,
        ~coarse,
        ~observed=primaryObserved,
        ~label=segment.id ++ "/" ++ row.id ++ " stored full-take MLX anchor",
      )
    | "mlx_bounded_turn" => proof
    | _ => fail("unknown stored anchor source for " ++ row.id)
    }
    observed := mergeRecoveredBlock(~base=observed.contents, ~replacement)
  })
  observed.contents
}

let loadAlignedTimings = (~segment: dialogueSegment, ~cache: segmentCache): option<array<timedLine>> => {
  let path = dialogueAlignmentPath(~segment, ~cache)
  let receiptPath = dialogueAlignmentReceiptPath(~segment, ~cache)
  if !exists(Path(path)) && !exists(Path(receiptPath)) { None } else if !exists(Path(path)) || !exists(Path(receiptPath)) {
    fail("local alignment cache is incomplete for " ++ segment.id)
  } else {
    let mapped = transcriptMap(segment)
    let json = Js.Json.parseExn(readText(Path(path)))
    let primaryRawPath = localRawAlignmentPath(~segment, ~cache)
    let evidenceMethod = stringField(json, "method")
    let evidencePath = stringField(json, "selected_evidence_json")
    let expectedEvidencePath = switch evidenceMethod {
    | "mlx_primary_global" => primaryRawPath
    | "mlx_primary_global_plus_mlx_turn_recovery" => primaryRawPath
    | "whisper_cpp_global_fallback" => localWhisperCppRawPath(~segment, ~cache)
    | "whisper_cpp_global_plus_mlx_turn_recovery" => localWhisperCppRawPath(~segment, ~cache)
    | _ => fail("unknown local alignment evidence method for " ++ segment.id)
    }
    let supplements = loadStoredSupplements(~segment, ~cache, json)
    if stringField(json, "schema") != "kaali-mitti.local-line-alignment/v3" ||
       stringField(json, "segment_id") != segment.id ||
       stringField(json, "request_sha256") != localDerivedKey(~segment, ~cache) ||
       stringField(json, "recipe_sha256") != localAlignmentRecipeHash(segment) ||
       stringField(json, "projection_sha256") != sha256Text(localProjectionSignature(segment)) ||
       stringField(json, "nonverbal_silence_config") != localNonverbalSilenceConfig ||
       stringField(json, "audio_sha256") != sha256File(Path(cache.rawPath)) ||
       stringField(json, "transcript_sha256") != sha256Text(mapped.text) ||
       stringField(json, "primary_mlx_json") != primaryRawPath ||
       !exists(Path(primaryRawPath)) ||
       stringField(json, "primary_mlx_json_sha256") != sha256File(Path(primaryRawPath)) ||
       evidencePath != expectedEvidencePath || !exists(Path(evidencePath)) ||
       stringField(json, "selected_evidence_json_sha256") != sha256File(Path(evidencePath)) ||
       stringField(json, "turn_recovery_config") != localTurnAlignmentConfig ||
       stringField(json, "turn_recovery_fingerprint") != supplementFingerprint(supplements) ||
       ((evidenceMethod == "whisper_cpp_global_plus_mlx_turn_recovery" ||
         evidenceMethod == "mlx_primary_global_plus_mlx_turn_recovery")) !=
         (Belt.Array.length(supplements) > 0) ||
       stringField(json, "model_config_sha256") != approvedMlxModelConfigSha256 ||
       stringField(json, "model_weights_sha256") != approvedMlxModelWeightsSha256 ||
       stringField(json, "whisper_cpp_binary_sha256") != approvedWhisperCppSha256 ||
       stringField(json, "whisper_cpp_model_sha256") != approvedWhisperCppModelSha256 ||
       Js.Math.abs_float(numberField(json, "audio_duration_seconds") -. cache.duration) > 0.10 {
      fail("local alignment cache does not match " ++ segment.id)
    }
    let rows = arrayField(json, "lines")->Belt.Array.map(row => ({
      id: stringField(row, "id"),
      start: numberField(row, "start_seconds"),
      end_: numberField(row, "end_seconds"),
    }))
    validateTimings(~segment, ~rows, ~duration=cache.duration)
    let primaryObserved = sanitizeProjectionWords(
      parseMlxWhisperJson(readText(Path(primaryRawPath))),
    )
    let primarySelected = evidenceMethod == "mlx_primary_global" ||
      evidenceMethod == "mlx_primary_global_plus_mlx_turn_recovery"
    let baseObserved = sanitizeProjectionWords(primarySelected
      ? parseMlxWhisperJson(readText(Path(evidencePath)))
      : Kuku_LocalWordAlign.parseWhisperJson(readText(Path(evidencePath))))
    let observed = applyStoredSupplements(
      ~segment, ~cache, ~primaryObserved, ~baseObserved, ~supplements,
    )
    let (rederived, _) = deriveLocalTimings(
      ~segment,
      ~cache,
      ~observed,
      ~evidenceLabel=evidenceMethod,
      ~recoveredLineIds=supplements->Belt.Array.map(item => item.lineId),
    )
    rows->Belt.Array.forEachWithIndex((index, row) => {
      let expected = Belt.Array.getExn(rederived, index)
      if row.id != expected.id || Js.Math.abs_float(row.start -. expected.start) > 0.001 ||
         Js.Math.abs_float(row.end_ -. expected.end_) > 0.001 {
        fail("local alignment no longer re-derives for " ++ row.id)
      }
    })
    let receipt = Js.Json.parseExn(readText(Path(receiptPath)))
    if stringField(receipt, "schema") != "kaali-mitti.local-line-alignment-receipt/v3" ||
       stringField(receipt, "request_sha256") != localDerivedKey(~segment, ~cache) ||
       stringField(receipt, "alignment_sha256") != sha256File(Path(path)) ||
       stringField(receipt, "evidence_method") != evidenceMethod ||
       stringField(receipt, "selected_evidence_json") != evidencePath ||
       stringField(receipt, "selected_evidence_json_sha256") != sha256File(Path(evidencePath)) ||
       stringField(receipt, "turn_recovery_fingerprint") != supplementFingerprint(supplements) ||
       stringField(receipt, "audio_sha256") != sha256File(Path(cache.rawPath)) ||
       stringField(receipt, "provider_calls") != "0" {
      fail("local alignment receipt does not match " ++ segment.id)
    }
    Some(rows)
  }
}

let verifySfxCache = (spec: generatedSfxSpec): option<audioAsset> => {
  let path = sfxRawPath(spec)
  let receiptPath = sfxReceiptPath(spec)
  let hasAudio = exists(Path(path))
  let hasReceipt = exists(Path(receiptPath))
  if !hasAudio && !hasReceipt { None } else if hasAudio != hasReceipt {
    fail("generated SFX cache is incomplete; paid retry is forbidden: " ++ spec.id)
  } else {
    let duration = validateAudio(path, "cached SFX " ++ spec.id)
    let receipt = Js.Json.parseExn(readText(Path(receiptPath)))
    let hash = sha256File(Path(path))
    if stringField(receipt, "request_sha256") != sfxRequestHash(spec) || stringField(receipt, "asset_sha256") != hash || Js.Math.abs_float(numberField(receipt, "duration_seconds") -. duration) > 0.10 {
      fail("generated SFX receipt does not match cached bytes: " ++ spec.id)
    }
    Some({id: spec.id, path, sha256: hash, duration})
  }
}

let sfxSpecById = id => switch Belt.Array.getBy(generatedSfx, spec => spec.id == id) {
| Some(spec) => spec
| None => fail("unknown generated SFX " ++ id)
}

let audioAssetFor = id => {
  let spec = sfxSpecById(id)
  switch verifySfxCache(spec) {
  | Some(asset) => asset
  | None => {id, path: sfxRawPath(spec), sha256: sfxRequestHash(spec), duration: spec.seconds}
  }
}

let missingDialogueSegments = () => segments->Belt.Array.keep(segment => verifyDialogueCache(segment) == None)
let missingAlignmentSegments = () => segments->Belt.Array.keep(segment => switch verifyDialogueCache(segment) {
| Some(cache) => loadAlignedTimings(~segment, ~cache) == None
| None => true
})
let missingGeneratedSfx = () => generatedSfx->Belt.Array.keep(spec => verifySfxCache(spec) == None)

let claimPaid = (~kind, ~id, ~hash): unit => {
  ensureDirPath(Path(claimDir))
  let path = claimDir ++ "/" ++ kind ++ "_" ++ id ++ "_" ++ hash ++ ".claim.json"
  let root = Js.Dict.empty()
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "kind", kind)
  addString(root, "id", id)
  addString(root, "request_sha256", hash)
  addString(root, "policy", "Claim written immediately before provider call. Existing claim plus missing immutable cache forbids automatic retry.")
  if !writeTextExclusive(Path(path), Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n") {
    fail("paid attempt already claimed with missing cache: " ++ kind ++ " " ++ id)
  }
}

let publishFetched = (~audio, ~extension, ~destination, ~label): float => {
  let scratch = tempDir("third-echo-provider-")->pathString
  let temporary = scratch ++ "/asset." ++ extension
  writeBytes(Path(temporary), audio)->ignore
  let duration = validateAudio(temporary, label)
  if !publishFileExclusive(Path(temporary), Path(destination)) { fail("refusing to overwrite immutable provider asset: " ++ destination) }
  duration
}

let prepareCast = async (): unit => {
  let index = ref(0)
  while index.contents < Belt.Array.length(cast) {
    let member = Belt.Array.getExn(cast, index.contents)
    let voice = VoiceId(member.voiceId)
    if !(await voiceAvailable(~voice)) {
      switch member.publicOwnerId {
      | Some(owner) => {
          Js.log("ADDING APPROVED SHARED VOICE -> " ++ speakerName(member.speaker) ++ " / " ++ member.voiceId)
          await addSharedVoice(~publicOwner=PublicOwnerId(owner), ~voice, ~name=member.accountName)
          if !(await voiceAvailable(~voice)) { fail("shared voice remains unavailable after add: " ++ member.voiceId) }
        }
      | None => fail("approved account voice is unavailable: " ++ member.voiceId)
      }
    }
    index := index.contents + 1
  }
}

let writeDialogueReceipt = (~segment: dialogueSegment, ~cache: segmentCache): unit => {
  let root = Js.Dict.empty()
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "kind", "dialogue")
  addString(root, "segment_id", segment.id)
  addString(root, "model", "eleven_v3")
  addString(root, "language_code", "hi")
  addNumber(root, "seed", Belt.Int.toFloat(segment.seed))
  addString(root, "request_sha256", dialogueRequestHash(segment))
  addString(root, "asset", cache.rawPath)
  addString(root, "asset_sha256", sha256File(Path(cache.rawPath)))
  addString(root, "timings", dialogueTimingPath(segment))
  addString(root, "timings_sha256", sha256File(Path(dialogueTimingPath(segment))))
  addNumber(root, "duration_seconds", cache.duration)
  if !writeTextExclusive(Path(dialogueReceiptPath(segment)), Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n") { fail("dialogue receipt already exists unexpectedly: " ++ segment.id) }
}

let renderDialogueSegment = async (segment: dialogueSegment): segmentCache => switch verifyDialogueCache(segment) {
| Some(cache) => cache
| None => {
    let hash = dialogueRequestHash(segment)
    claimPaid(~kind="dialogue", ~id=segment.id, ~hash)
    Js.log("PAID ELEVENLABS V3 DIALOGUE -> " ++ segment.id ++ " / " ++ Belt.Int.toString(segmentCharacters(segment)) ++ " characters")
    let inputs = segment.lines->Belt.Array.map(row => (Text(providerText(row)), VoiceId(memberFor(row.speaker).voiceId)))
    let (audio, providerTimings) = await productionDialogueTimed(~lines=inputs, ~languageCode="hi", ~seed=segment.seed)
    let rawPath = dialogueRawPath(segment)
    let duration = publishFetched(~audio, ~extension="mp3", ~destination=rawPath, ~label="dialogue " ++ segment.id)
    let timings = providerTimings->Belt.Array.mapWithIndex((index, timing) => {
      let (start, end_) = timing
      {id: Belt.Array.getExn(segment.lines, index).id, start, end_}
    })
    validateTimings(~segment, ~rows=timings, ~duration)
    if !writeTextExclusive(Path(dialogueTimingPath(segment)), timingJson(~segment, ~rows=timings, ~audioPath=rawPath, ~duration)) { fail("timing sidecar already exists unexpectedly: " ++ segment.id) }
    let cache = {segmentId: segment.id, rawPath, duration, timings}
    writeDialogueReceipt(~segment, ~cache)
    cache
  }
}

let alignDialogueSegment = async (~segment: dialogueSegment, ~cache: segmentCache): segmentCache =>
  switch loadAlignedTimings(~segment, ~cache) {
  | Some(timings) => {segmentId: cache.segmentId, rawPath: cache.rawPath, duration: cache.duration, timings}
  | None => {
      if envLocalAlign != Some("1") {
        fail("missing local alignment for " ++ segment.id ++ "; run with LOCAL_ALIGN=1 (zero provider calls)")
      }
      let context = requireLocalAlignmentContext()
      let primaryRawPath = runLocalMlxWhisper(~segment, ~cache, ~context)
      let primaryObserved = sanitizeProjectionWords(
        parseMlxWhisperJson(readText(Path(primaryRawPath))),
      )
      let primaryAttempt = try Ok(deriveLocalTimings(
        ~segment,
        ~cache,
        ~observed=primaryObserved,
        ~evidenceLabel="mlx_primary_global",
        ~recoveredLineIds=[],
      )) catch {
      | ThirdEchoError(message) => Error(message)
      | Kuku_LocalWordAlign.LocalWordAlignment(message) => Error(message)
      | LocalLineRecovery(_, _, reason) => Error(reason)
      }
      let (timings, quality, evidence) = switch primaryAttempt {
      | Ok((timings, quality)) => (
          timings,
          quality,
          {
            method: "mlx_primary_global",
            rawPath: primaryRawPath,
            fallbackReason: None,
            supplements: [],
          },
        )
      | Error(primaryReason) => {
          let primaryRecovery = try Ok(deriveWithTurnRecovery(
            ~segment,
            ~cache,
            ~context,
            ~primaryObserved,
            ~baseObserved=primaryObserved,
            ~evidenceLabel="mlx_primary_global",
          )) catch {
          | ThirdEchoError(message) => Error(message)
          | LocalLineRecovery(_, _, reason) => Error(reason)
          | Kuku_LocalWordAlign.LocalWordAlignment(message) => Error(message)
          }
          switch primaryRecovery {
          | Ok((timings, quality, supplements)) => (
              timings,
              quality,
              {
                method: "mlx_primary_global_plus_mlx_turn_recovery",
                rawPath: primaryRawPath,
                fallbackReason: Some(primaryReason),
                supplements,
              },
            )
          | Error(primaryRecoveryReason) => {
              Js.log("PRIMARY LOCAL ALIGNMENT INCOMPLETE -> " ++ segment.id ++ "; using offline whisper.cpp evidence")
              let fallbackRawPath = runLocalWhisperCpp(~segment, ~cache)
              let fallbackObserved = sanitizeProjectionWords(
                Kuku_LocalWordAlign.parseWhisperJson(readText(Path(fallbackRawPath))),
              )
              let (timings, quality, supplements) = deriveWithTurnRecovery(
                ~segment,
                ~cache,
                ~context,
                ~primaryObserved,
                ~baseObserved=fallbackObserved,
                ~evidenceLabel="whisper_cpp_global_fallback",
              )
              (
                timings,
                quality,
                {
                  method: Belt.Array.length(supplements) == 0
                    ? "whisper_cpp_global_fallback"
                    : "whisper_cpp_global_plus_mlx_turn_recovery",
                  rawPath: fallbackRawPath,
                  fallbackReason: Some(primaryReason ++ " | primary turn recovery: " ++ primaryRecoveryReason),
                  supplements,
                },
              )
            }
          }
        }
      }
      ensureDirPath(Path(localAlignmentDerivedDir))
      let path = dialogueAlignmentPath(~segment, ~cache)
      if !writeTextExclusive(
        Path(path),
        alignmentJson(~segment, ~cache, ~rows=timings, ~quality, ~evidence, ~context),
      ) {
        fail("local alignment cache already exists unexpectedly: " ++ segment.id)
      }
      writeAlignmentReceipt(~segment, ~cache, ~path, ~evidence)
      {segmentId: cache.segmentId, rawPath: cache.rawPath, duration: cache.duration, timings}
    }
  }

let renderAllDialogue = async (): array<segmentCache> => {
  if Belt.Array.length(missingDialogueSegments()) > 0 { await prepareCast() }
  let caches: array<segmentCache> = []
  let index = ref(0)
  while index.contents < Belt.Array.length(segments) {
    let segment = Belt.Array.getExn(segments, index.contents)
    let cache = await renderDialogueSegment(segment)
    let aligned = await alignDialogueSegment(~segment, ~cache)
    Js.Array2.push(caches, aligned)->ignore
    index := index.contents + 1
  }
  caches
}

let alignCachedDialogueOnly = async (): int => {
  if envLocalAlign != Some("1") { fail("ALIGN_CACHED_ONLY=1 requires LOCAL_ALIGN=1") }
  if envPaid == Some("1") || envGenerateDialogue == Some("1") || envGenerateSfx == Some("1") {
    fail("ALIGN_CACHED_ONLY is a zero-provider mode; remove PAID and GENERATE flags")
  }
  let aligned = ref(0)
  let index = ref(0)
  while index.contents < Belt.Array.length(segments) {
    let segment = Belt.Array.getExn(segments, index.contents)
    switch verifyDialogueCache(segment) {
    | Some(cache) => {
        let _ = await alignDialogueSegment(~segment, ~cache)
        aligned := aligned.contents + 1
      }
    | None => ()
    }
    index := index.contents + 1
  }
  aligned.contents
}

let writeSfxReceipt = (~spec: generatedSfxSpec, ~path: string, ~duration: float): unit => {
  let root = Js.Dict.empty()
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "kind", "sfx")
  addString(root, "id", spec.id)
  addString(root, "model", "eleven_text_to_sound_v2")
  addString(root, "request_sha256", sfxRequestHash(spec))
  addString(root, "asset", path)
  addString(root, "asset_sha256", sha256File(Path(path)))
  addNumber(root, "duration_seconds", duration)
  addBool(root, "loop", spec.loop)
  if !writeTextExclusive(Path(sfxReceiptPath(spec)), Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n") { fail("SFX receipt already exists unexpectedly: " ++ spec.id) }
}

let renderGeneratedSfx = async (): unit => {
  ensureDirPath(Path(rawSfxDir))
  let index = ref(0)
  while index.contents < Belt.Array.length(generatedSfx) {
    let spec = Belt.Array.getExn(generatedSfx, index.contents)
    switch verifySfxCache(spec) {
    | Some(_) => ()
    | None => {
        let hash = sfxRequestHash(spec)
        claimPaid(~kind="sfx", ~id=spec.id, ~hash)
        Js.log("PAID ELEVENLABS SFX V2 -> " ++ spec.id ++ " / " ++ Js.Float.toString(spec.seconds) ++ " seconds")
        let audio = await soundEffect(~prompt=Prompt(spec.prompt), ~seconds=spec.seconds, ~influence=spec.influence, ~loop=spec.loop)
        let path = sfxRawPath(spec)
        let duration = publishFetched(~audio, ~extension="mp3", ~destination=path, ~label="SFX " ++ spec.id)
        writeSfxReceipt(~spec, ~path, ~duration)
      }
    }
    index := index.contents + 1
  }
}

let derivativeManifest = path => path ++ ".manifest.json"

let verifyDerivative = (~path, ~fingerprint): bool => {
  let manifest = derivativeManifest(path)
  if !exists(Path(path)) && !exists(Path(manifest)) { false } else if !exists(Path(path)) || !exists(Path(manifest)) {
    fail("content-addressed derivative is incomplete: " ++ path)
  } else {
    let json = Js.Json.parseExn(readText(Path(manifest)))
    if stringField(json, "fingerprint_sha256") != fingerprint || stringField(json, "audio_sha256") != sha256File(Path(path)) { fail("content-addressed derivative does not match manifest: " ++ path) }
    validateAudio(path, "cached derivative")->ignore
    true
  }
}

let publishDerivative = (~temporary, ~path, ~fingerprint, ~kind): unit => {
  let duration = validateAudio(temporary, kind)
  if !publishFileExclusive(Path(temporary), Path(path)) { fail("refusing to overwrite derivative: " ++ path) }
  let root = Js.Dict.empty()
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "kind", kind)
  addString(root, "fingerprint_sha256", fingerprint)
  addString(root, "audio", path)
  addString(root, "audio_sha256", sha256File(Path(path)))
  addNumber(root, "duration_seconds", duration)
  if !writeTextExclusive(Path(derivativeManifest(path)), Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n") { fail("refusing to overwrite derivative manifest") }
}

let cacheForSegment = (~caches: array<segmentCache>, id): segmentCache => switch Belt.Array.getBy(caches, cache => cache.segmentId == id) {
| Some(cache) => cache
| None => fail("missing dialogue cache " ++ id)
}

let segmentContainingLine = id => switch Belt.Array.getBy(segments, segment => Belt.Array.some(segment.lines, row => row.id == id)) {
| Some(segment) => segment
| None => fail("no dialogue segment contains " ++ id)
}

let buildLineStem = (~caches: array<segmentCache>, row: dialogueLine): lineAsset => {
  let segment = segmentContainingLine(row.id)
  let cache = cacheForSegment(~caches, segment.id)
  let softBehindGate = segment.id == "inside_the_gate"
  let timing = switch Belt.Array.getBy(cache.timings, timing => timing.id == row.id) {
  | Some(timing) => timing
  | None => fail("missing provider timing for " ++ row.id)
  }
  let timingIndex = switch Belt.Array.getIndexBy(cache.timings, item => item.id == row.id) {
  | Some(index) => index
  | None => fail("missing provider timing index for " ++ row.id)
  }
  /* `voice_segments` metadata was only turn metadata, not an edit decision
     list. V1 cut active phonemes at those boundaries. V2.1 uses local word
     alignment and partitions every internal provider take at the exact
     midpoint of the aligned inter-line gap. Adjacent normal stems therefore
     cover the source continuously, with no missing samples and no invented
     pause. First/last request padding is bounded so request lead/tail silence
     does not become story pacing. */
  let startGap = if timingIndex == 0 { None } else {
    let prior = Belt.Array.getExn(cache.timings, timingIndex - 1)
    Some(softBehindGate
      ? safeSoftSpeechSilenceGapBetween(~cache, ~left=prior, ~right=timing)
      : safeSilenceGapBetween(~cache, ~left=prior, ~right=timing))
  }
  let endGap = if timingIndex == Belt.Array.length(cache.timings) - 1 { None } else {
    let next = Belt.Array.getExn(cache.timings, timingIndex + 1)
    Some(softBehindGate
      ? safeSoftSpeechSilenceGapBetween(~cache, ~left=timing, ~right=next)
      : safeSilenceGapBetween(~cache, ~left=timing, ~right=next))
  }
  let leadingSoftGap = softBehindGate && timingIndex == 0
    ? localSoftSpeechOuterSilenceGaps(cache)->Belt.Array.getBy(gap =>
        gap.start <= 0.02 && gap.end_ < timing.end_ +. 0.60
      )
    : None
  let trailingSoftGap = softBehindGate && timingIndex == Belt.Array.length(cache.timings) - 1
    ? localSoftSpeechOuterSilenceGaps(cache)->Belt.Array.getBy(gap =>
        gap.end_ >= cache.duration -. 0.02 && gap.start > timing.start -. 0.20
      )
    : None
  let start = switch startGap {
  | Some(gap) => (gap.start +. gap.end_) /. 2.0
  | None => switch leadingSoftGap {
    | Some(gap) => floatMax(0.0, gap.end_ -. 0.02)
    | None => floatMax(0.0, timing.start -. 0.12)
    }
  }
  let end_ = switch endGap {
  | Some(gap) => (gap.start +. gap.end_) /. 2.0
  | None => switch trailingSoftGap {
    | Some(gap) => floatMin(cache.duration, gap.start +. 0.02)
    | None => floatMin(cache.duration, timing.end_ +. 0.15)
    }
  }
  if (startGap == None && leadingSoftGap == None && start > timing.start +. 0.005) ||
     (endGap == None && trailingSoftGap == None && end_ +. 0.005 < timing.end_) {
    fail("aligned stem would cut spoken characters in " ++ row.id)
  }
  let fingerprint = sha256Text(Js.Array2.joinWith([
    assemblyVersion,
    "line-stem|dual-local-word-alignment|detected-silence-midgap-partition|bounded-request-edges|48k-mono-s24",
    row.id,
    sha256File(Path(cache.rawPath)),
    Js.Float.toString(timing.start),
    Js.Float.toString(timing.end_),
    Js.Float.toString(start),
    Js.Float.toString(end_),
  ], "###"))
  ensureDirPath(Path(stemDir))
  let path = stemDir ++ "/" ++ row.id ++ "_" ++ shortHash(fingerprint) ++ ".wav"
  if !verifyDerivative(~path, ~fingerprint) {
    let scratch = tempDir("third-echo-stem-")->pathString
    let temporary = scratch ++ "/stem.wav"
    ffmpeg([
      "-nostdin", "-v", "error", "-n", "-i", cache.rawPath,
      "-af", "atrim=start=" ++ Js.Float.toString(start) ++ ":end=" ++ Js.Float.toString(end_) ++ ",asetpts=PTS-STARTPTS,aresample=48000,aformat=sample_fmts=fltp:channel_layouts=mono",
      "-ar", "48000", "-ac", "1", "-c:a", "pcm_s24le", temporary,
    ])
    publishDerivative(~temporary, ~path, ~fingerprint, ~kind="continuous forced-aligned dialogue partition " ++ row.id)
  }
  /* Reusable echoes/copies must not inherit a second of quiet caused by a
     coarse ASR token edge. The same verified boundary gap supplies the
     acoustic onset/offset handles without trimming through speech. */
  let tightStart = switch startGap {
  | Some(gap) => floatMax(start, gap.end_ -. 0.015)
  | None => softBehindGate ? start : floatMax(start, timing.start -. 0.06)
  }
  let tightEnd = switch endGap {
  | Some(gap) => floatMin(end_, gap.start +. 0.015)
  | None => softBehindGate ? end_ : floatMin(end_, timing.end_ +. 0.10)
  }
  let tightFingerprint = sha256Text(Js.Array2.joinWith([
    assemblyVersion,
    "tight-speech|dual-local-word-alignment|15ms-silence-gap-handles|5ms-edge-fades|48k-mono-s24",
    row.id,
    sha256File(Path(cache.rawPath)),
    Js.Float.toString(timing.start),
    Js.Float.toString(timing.end_),
    Js.Float.toString(tightStart),
    Js.Float.toString(tightEnd),
  ], "###"))
  let tightPath = stemDir ++ "/" ++ row.id ++ "_tight_" ++ shortHash(tightFingerprint) ++ ".wav"
  if !verifyDerivative(~path=tightPath, ~fingerprint=tightFingerprint) {
    let scratch = tempDir("third-echo-tight-speech-")->pathString
    let temporary = scratch ++ "/stem.wav"
    let tightDuration = tightEnd -. tightStart
    ffmpeg([
      "-nostdin", "-v", "error", "-n", "-i", cache.rawPath,
      "-af", "atrim=start=" ++ Js.Float.toString(tightStart) ++ ":end=" ++ Js.Float.toString(tightEnd) ++
      ",asetpts=PTS-STARTPTS,aresample=48000,aformat=sample_fmts=fltp:channel_layouts=mono," ++
      "afade=t=in:st=0:d=0.005,afade=t=out:st=" ++ Js.Float.toString(floatMax(0.0, tightDuration -. 0.005)) ++ ":d=0.005",
      "-ar", "48000", "-ac", "1", "-c:a", "pcm_s24le", temporary,
    ])
    publishDerivative(~temporary, ~path=tightPath, ~fingerprint=tightFingerprint, ~kind="forced-aligned reusable speech stem " ++ row.id)
  }
  {
    id: row.id,
    path,
    sha256: sha256File(Path(path)),
    duration: validateAudio(path, "line stem " ++ row.id),
    tightPath,
    tightSha256: sha256File(Path(tightPath)),
    tightDuration: validateAudio(tightPath, "tight speech stem " ++ row.id),
  }
}

let buildAllLineStems = (caches): array<lineAsset> => allLines()->Belt.Array.map(row => buildLineStem(~caches, row))

let lineAssetFor = (~assets: array<lineAsset>, id): lineAsset => switch Belt.Array.getBy(assets, asset => asset.id == id) {
| Some(asset) => asset
| None => fail("missing line asset " ++ id)
}

let wordsIn = value => value->compact == "" ? 0 : value->compact->Js.String2.split(" ")->Belt.Array.length
let estimateLineDuration = id => {
  let row = lineFor(id)
  row.id == "KLAUGH" ? 0.75 : starts(row.id, "KB") ? 1.10 : floatMax(0.65, Belt.Int.toFloat(wordsIn(row.text)) /. 2.15)
}

let treatmentExtraDuration = treatment => switch treatment {
| NaturalEchoOne => 0.65
| NaturalEchoTwo => 0.85
| _ => 0.0
}

let placementDuration = (~sourceDuration, ~treatment) => sourceDuration +. treatmentExtraDuration(treatment)

let buildTimeline = (~assets: option<array<lineAsset>>): timelineBuild => {
  let turns: array<Core.turnWindow> = []
  let placements: array<voicePlacement> = []
  let cursor = ref(initialLead)
  let placedTurn = id => switch Belt.Array.getBy(turns, turn => turn.id == id) {
  | Some(turn) => turn
  | None => fail("overlay anchor has not been placed: " ++ id)
  }
  let assetInfo = (sourceLineId, treatment) => switch assets {
  | Some(rows) => {
      let asset = lineAssetFor(~assets=rows, sourceLineId)
      /* These three copied-voice escalation beats are timed from the audible
         syllable, not from half of the surrounding source-take silence. */
      let onsetCriticalNormal = treatment == Normal && (
        sourceLineId == "K20" || sourceLineId == "K21" || sourceLineId == "K22"
      )
      treatment == Normal && !onsetCriticalNormal
        ? (asset.path, asset.duration)
        : (asset.tightPath, asset.tightDuration)
    }
  | None => ("planned:" ++ sourceLineId, estimateLineDuration(sourceLineId))
  }

  storyCues->Belt.Array.forEach(row => {
    let (path, sourceDuration) = assetInfo(row.sourceLineId, row.treatment)
    let duration = if row.id == "PLAY_ECHO_K03_1" {
      sourceDuration +. 0.65
    } else if row.id == "PLAY_ECHO_K03_2" {
      sourceDuration +. 0.85
    } else {
      placementDuration(~sourceDuration, ~treatment=row.treatment)
    }
    let start = switch row.id {
    | "ENTITY_K20" => placedTurn("K20").end_ +. 0.75
    | "ENTITY_K21" => placedTurn("K21").start +. 0.50
    | _ => cursor.contents
    }
    let end_ = start +. duration
    Js.Array2.push(turns, {id: row.id, start, end_})->ignore
    Js.Array2.push(placements, {
      id: row.id,
      sourceLineId: row.sourceLineId,
      path,
      start,
      duration,
      treatment: row.treatment,
      gainDb: switch row.id {
      | "PLAY_ECHO_K03_1" => -6.0
      | "PLAY_ECHO_K03_2" => -11.0
      | "ENTITY_01" => 2.0
      | "PLAY_ENTITY_01" => 2.5
      | _ => 0.0
      },
    })->ignore
    cursor := switch row.id {
    | "ENTITY_K20" => end_ +. row.gapAfter
    | "ENTITY_K21" => floatMax(placedTurn("K21").end_, end_) +. row.gapAfter
    | _ => end_ +. row.gapAfter
    }
  })

  /* The entity completes Kunal's cry 60 ms after the same syllable begins. It
     is an overlay, not the next cursor beat. The real K22 stem remains audible
     underneath, breaking in the throat while the copy finishes the word. */
  let k22 = placedTurn("K22")
  let (es06Path, es06SourceDuration) = assetInfo("ES06", EntityFull)
  let es06Start = k22.start +. 0.06
  let es06Duration = placementDuration(~sourceDuration=es06SourceDuration, ~treatment=EntityFull)
  let es06End = es06Start +. es06Duration
  Js.Array2.push(turns, {id: "ENTITY_06_OVERLAP", start: es06Start, end_: es06End})->ignore
  Js.Array2.push(placements, {
    id: "ENTITY_06_OVERLAP",
    sourceLineId: "ES06",
    path: es06Path,
    start: es06Start,
    duration: es06Duration,
    treatment: EntityFull,
    gainDb: 0.0,
  })->ignore

  /* Outside the locked gate, the real Kunal stays physically beside Meera.
     Reused breath-only stems persist under the final bodiless call; they never
     become speech and never share the entity treatment. */
  let finalBodyStart = placedTurn("M24").end_ +. 0.35
  let finalBodyEnd = placedTurn("ENTITY_07B").end_
  let (bodyPath, bodySourceDuration) = assetInfo("KB03", BreathOnly)
  let bodyCursor = ref(finalBodyStart)
  let bodyIndex = ref(1)
  while bodyCursor.contents < finalBodyEnd -. 0.08 {
    let bodyDuration = floatMin(bodySourceDuration, finalBodyEnd -. bodyCursor.contents)
    Js.Array2.push(placements, {
      id: "FINAL_REAL_KUNAL_BREATH_" ++ Belt.Int.toString(bodyIndex.contents),
      sourceLineId: "KB03",
      path: bodyPath,
      start: bodyCursor.contents,
      duration: bodyDuration,
      treatment: BreathOnly,
      gainDb: -1.5,
    })->ignore
    bodyCursor := bodyCursor.contents +. floatMax(0.45, bodySourceDuration +. 0.22)
    bodyIndex := bodyIndex.contents + 1
  }

  let finalEnd = floatMax(cursor.contents, es06End)
  {turns, placements, masterDuration: finalEnd +. reviewTail}
}

let turnFor = (~timeline: timelineBuild, id): Core.turnWindow => switch Belt.Array.getBy(timeline.turns, turn => turn.id == id) {
| Some(turn) => turn
| None => fail("timeline has no turn " ++ id)
}

let addSfxPlacement = (~rows: array<sfxPlacement>, ~asset: audioAsset, ~id, ~start, ~trimStart, ~duration, ~gainDb, ~fadeIn=0.02, ~fadeOut=0.04): unit => {
  if start < 0.0 || trimStart < 0.0 || duration <= 0.04 || trimStart +. duration > asset.duration +. 0.01 {
    fail("invalid SFX placement " ++ id)
  }
  Js.Array2.push(rows, {
    id,
    assetId: asset.id,
    path: asset.path,
    assetSha256: asset.sha256,
    start,
    trimStart,
    duration,
    gainDb,
    fadeIn: floatMin(fadeIn, duration /. 3.0),
    fadeOut: floatMin(fadeOut, duration /. 3.0),
  })->ignore
}

let addLoop = (~rows: array<sfxPlacement>, ~asset: audioAsset, ~prefix, ~from, ~until, ~gainDb): unit => {
  let crossfade = 0.80
  let cursor = ref(from)
  let index = ref(1)
  while cursor.contents < until -. 0.04 {
    let duration = floatMin(asset.duration, until -. cursor.contents)
    if duration < 0.10 { cursor := until } else {
      addSfxPlacement(
        ~rows,
        ~asset,
        ~id=prefix ++ Belt.Int.toString(index.contents),
        ~start=cursor.contents,
        ~trimStart=0.0,
        ~duration,
        ~gainDb,
        ~fadeIn=0.35,
        ~fadeOut=0.65,
      )
      cursor := cursor.contents +. asset.duration -. crossfade
      index := index.contents + 1
    }
  }
}

let tightenOneShot = (asset: audioAsset): audioAsset => {
  let fingerprint = sha256Text(assemblyVersion ++ "|tight-one-shot|-45db-20ms/80ms|" ++ asset.id ++ "|" ++ asset.sha256)
  let path = cacheDir ++ "/tight_sfx/" ++ asset.id ++ "_" ++ shortHash(fingerprint) ++ ".wav"
  if !verifyDerivative(~path, ~fingerprint) {
    let scratch = tempDir("third-echo-tight-sfx-")->pathString
    let temporary = scratch ++ "/tight.wav"
    ffmpeg([
      "-nostdin", "-v", "error", "-n", "-i", asset.path,
      "-af", "silenceremove=start_periods=1:start_duration=0.02:start_threshold=-45dB:start_silence=0.005:stop_periods=-1:stop_duration=0.08:stop_threshold=-45dB,aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo",
      "-ar", "48000", "-ac", "2", "-c:a", "pcm_s24le", temporary,
    ])
    publishDerivative(~temporary, ~path, ~fingerprint, ~kind="silence-trimmed identifiable one-shot " ++ asset.id)
  }
  {id: asset.id, path, sha256: sha256File(Path(path)), duration: validateAudio(path, "tight one-shot " ++ asset.id)}
}

let buildSfxPlacements = (~timeline: timelineBuild): array<sfxPlacement> => {
  let rows: array<sfxPlacement> = []
  let openBed = audioAssetFor("open_wind_bed")
  let peacock = audioAssetFor("distant_peacock")
  let rainBed = audioAssetFor("rain_bed")
  let footsteps = audioAssetFor("retreat_footsteps")
  let fall = tightenOneShot(audioAssetFor("slip_fall"))
  let keys = audioAssetFor("keys_approach")
  let recorder = audioAssetFor("recorder_control")
  let packing = audioAssetFor("packing")
  let gateOpen = audioAssetFor("gate_open")
  let gateClose = audioAssetFor("gate_close_lock")
  let taps = audioAssetFor("finger_taps")
  let rainStart = floatMax(0.0, turnFor(~timeline, "M12").end_ +. 0.25)
  addLoop(~rows, ~asset=openBed, ~prefix="OPEN_BED_", ~from=0.0, ~until=timeline.masterDuration, ~gainDb=-2.0)
  addLoop(~rows, ~asset=rainBed, ~prefix="RAIN_BED_", ~from=rainStart, ~until=timeline.masterDuration, ~gainDb=-1.0)
  addSfxPlacement(~rows, ~asset=peacock, ~id="ONE_DISTANT_PEACOCK", ~start=3.20, ~trimStart=0.0, ~duration=peacock.duration, ~gainDb=-5.0, ~fadeIn=0.08, ~fadeOut=0.40)

  let retreatStart = turnFor(~timeline, "R13").end_ +. 0.20
  let k22 = turnFor(~timeline, "K22")
  let fallStart = k22.start -. fall.duration -. 0.18
  addLoop(~rows, ~asset=footsteps, ~prefix="RETREAT_FOOTSTEPS_", ~from=retreatStart, ~until=fallStart, ~gainDb=-1.5)
  addSfxPlacement(~rows, ~asset=fall, ~id="SLIP_AND_FALL", ~start=fallStart, ~trimStart=0.0, ~duration=fall.duration, ~gainDb=2.5, ~fadeIn=0.02, ~fadeOut=0.02)

  addSfxPlacement(~rows, ~asset=keys, ~id="KEYS_APPROACH", ~start=floatMax(0.10, turnFor(~timeline, "R01").start -. 1.10), ~trimStart=0.0, ~duration=keys.duration, ~gainDb=-1.0)
  let searchWindowStart = turnFor(~timeline, "M09").end_ +. recorder.duration +. 0.20
  let searchWindowEnd = turnFor(~timeline, "R06A").start -. 0.10
  if searchWindowEnd -. searchWindowStart > 0.10 {
    addSfxPlacement(~rows, ~asset=keys, ~id="KEYS_SEARCH_OUT", ~start=searchWindowStart, ~trimStart=0.0, ~duration=floatMin(keys.duration, searchWindowEnd -. searchWindowStart), ~gainDb=-3.0)
  }
  let searchReturnDuration = floatMin(3.70, keys.duration)
  addSfxPlacement(
    ~rows,
    ~asset=keys,
    ~id="KEYS_SEARCH_RETURN",
    ~start=turnFor(~timeline, "K11").start -. searchReturnDuration -. 0.10,
    ~trimStart=0.0,
    ~duration=searchReturnDuration,
    ~gainDb=-2.0,
  )
  addSfxPlacement(~rows, ~asset=recorder, ~id="RECORDER_OPENING", ~start=turnFor(~timeline, "M00").end_ +. 0.05, ~trimStart=0.0, ~duration=recorder.duration, ~gainDb=0.5)
  addSfxPlacement(~rows, ~asset=recorder, ~id="RECORDER_PLAYBACK", ~start=turnFor(~timeline, "M07").end_ +. 0.05, ~trimStart=0.0, ~duration=recorder.duration, ~gainDb=0.5)
  addSfxPlacement(~rows, ~asset=recorder, ~id="RECORDER_FIRST_STOP", ~start=turnFor(~timeline, "M09").end_ +. 0.05, ~trimStart=0.0, ~duration=recorder.duration, ~gainDb=0.5)
  addSfxPlacement(~rows, ~asset=recorder, ~id="RECORDER_STOLEN_START", ~start=turnFor(~timeline, "K13").start -. recorder.duration -. 0.08, ~trimStart=0.0, ~duration=recorder.duration, ~gainDb=0.5)
  addSfxPlacement(~rows, ~asset=recorder, ~id="RECORDER_FINAL_STOP", ~start=turnFor(~timeline, "M16").end_ +. 0.05, ~trimStart=0.0, ~duration=recorder.duration, ~gainDb=0.5)
  addSfxPlacement(~rows, ~asset=packing, ~id="BAG_ZIP_AFTER_STOP", ~start=turnFor(~timeline, "M17").end_ +. 0.08, ~trimStart=0.0, ~duration=0.75, ~gainDb=0.5)
  addSfxPlacement(~rows, ~asset=gateOpen, ~id="GATE_OPEN", ~start=turnFor(~timeline, "R14").start -. gateOpen.duration -. 0.10, ~trimStart=0.0, ~duration=gateOpen.duration, ~gainDb=2.0)
  let gateCloseStart = turnFor(~timeline, "R15").end_ +. 0.30
  addSfxPlacement(~rows, ~asset=gateClose, ~id="GATE_CLOSE_CHAIN_LOCK", ~start=gateCloseStart, ~trimStart=0.0, ~duration=gateClose.duration, ~gainDb=2.5)
  addSfxPlacement(~rows, ~asset=taps, ~id="KUNAL_TWO_TAPS", ~start=turnFor(~timeline, "M23").end_ +. 0.35, ~trimStart=0.0, ~duration=taps.duration, ~gainDb=1.0)
  /* Outside, their bodies resume a slow retreat after Meera steadies Kunal.
     The movement cuts dead when the voice calls from inside the locked gate. */
  let finalWalkStart = turnFor(~timeline, "M24").end_ +. 0.35
  let finalWalkEnd = turnFor(~timeline, "ENTITY_07A").start
  let finalWalkCursor = ref(finalWalkStart)
  let finalWalkIndex = ref(1)
  while finalWalkCursor.contents < finalWalkEnd -. 0.08 {
    let duration = floatMin(footsteps.duration, finalWalkEnd -. finalWalkCursor.contents)
    addSfxPlacement(~rows, ~asset=footsteps, ~id="OUTSIDE_SLOW_STEPS_" ++ Belt.Int.toString(finalWalkIndex.contents), ~start=finalWalkCursor.contents, ~trimStart=0.0, ~duration, ~gainDb=-5.0, ~fadeIn=0.08, ~fadeOut=0.025)
    finalWalkCursor := finalWalkCursor.contents +. footsteps.duration -. 0.35
    finalWalkIndex := finalWalkIndex.contents + 1
  }
  rows
}

let storyCueSignature = (row: storyCue) => Js.Array2.joinWith([
  row.id,
  row.sourceLineId,
  treatmentName(row.treatment),
  Js.Float.toString(row.gapAfter),
], "|")

let soundPlacementPolicy =
  "sfx-v3|reuse-v1-content-addressed-assets|wind-full|single-peacock-once|rain-from-stolen-take|five-audible-recorder-controls-in-authored-gaps|retreat-steps-to-fall|fall-ends-180ms-before-k22|gate-open-before-command|gate-close-chain-lock|two-dry-finger-taps|outside-steps-hard-stop-at-final-voice|rain-smooth-minus-6db-k22-overlap"

let voiceTreatmentPolicy =
  "voice-v7|global-mlx+kuku-word-align|hash-pinned-whispercpp-fallback|bounded-no-context-mlx-turn-proof|zero-cloud-alignment|strict-detected-silence-shared-normal-partitions|soft-final-gate=-55db-acoustic-islands|15ms-acoustic-handles-for-reuse|tag-only-nonverbals-use-longest-between-neighbours-acoustic-island|zero-authored-gap-for-ordinary-dialogue|single-bus-loudnorm|first-answer=distinct-human-centred-unnotched|playback-answer=+2.5db|natural-echo=reused-source+aecho|learned-entity=same-kunal-stems|k20/k21/k22-use-acoustic-tight-stems|k20=end+750ms|k21=onset+500ms|k22=onset+60ms|breath-only=highpass4000+11db+audibility-qc|final=behind-gate-dry-no-silenceremove|inside-gate=review-only-phonetic-near-match"

let planSignature = (~estimated: timelineBuild, ~missingDialogue, ~missingAlignment, ~missingSfx): string => Js.Array2.joinWith([
  pipelineVersion,
  assemblyVersion,
  approvedScriptSha256,
  castSignature(),
  segments->Belt.Array.map(segment => dialogueRequestSignature(segment))->Js.Array2.joinWith("||||"),
  storyCues->Belt.Array.map(storyCueSignature)->Js.Array2.joinWith("||"),
  generatedSfx->Belt.Array.map(sfxRequestSignature)->Js.Array2.joinWith("||||"),
  "missing_dialogue=" ++ missingDialogue->Belt.Array.map(dialogueRequestHash)->Js.Array2.joinWith("|"),
  "missing_local_alignment=" ++ missingAlignment->Belt.Array.map(localAlignmentRecipeHash)->Js.Array2.joinWith("|"),
  "local_projection=" ++ localProjectionVersion,
  "local_silence=" ++ localSilenceConfig,
  "local_nonverbal_silence=" ++ localNonverbalSilenceConfig,
  "local_soft_speech_silence=" ++ localSoftSpeechSilenceConfig,
  "local_turn_recovery=" ++ localTurnAlignmentConfig,
  "local_fallback=" ++ localWhisperCppConfig ++ "|" ++ approvedWhisperCppSha256 ++ "|" ++ approvedWhisperCppModelSha256,
  "maximum_cloud_alignment_requests=" ++ Belt.Int.toString(maxNewCloudAlignmentRequests),
  "missing_sfx=" ++ missingSfx->Belt.Array.map(sfxRequestHash)->Js.Array2.joinWith("|"),
  "estimated_master=" ++ Js.Float.toString(estimated.masterDuration),
  "initial=" ++ Js.Float.toString(initialLead),
  "tail=" ++ Js.Float.toString(reviewTail),
  voiceTreatmentPolicy,
  soundPlacementPolicy,
  "review_only=" ++ insideGateReviewOnlyReason,
  Core.masterMixConfig,
], "###")

let castJson = (member: castMember) => {
  let root = Js.Dict.empty()
  addString(root, "speaker", speakerName(member.speaker))
  addString(root, "account_name", member.accountName)
  addString(root, "voice_id", member.voiceId)
  addString(root, "casting_reason", member.castingReason)
  switch member.publicOwnerId {
  | Some(owner) => { addString(root, "public_owner_id", owner); addBool(root, "shared_voice_add_if_missing", true) }
  | None => addBool(root, "shared_voice_add_if_missing", false)
  }
  Js.Json.object_(root)
}

let lineJson = (row: dialogueLine) => {
  let root = Js.Dict.empty()
  addString(root, "id", row.id)
  addString(root, "speaker", speakerName(row.speaker))
  addString(root, "voice_id", memberFor(row.speaker).voiceId)
  addString(root, "source_text", row.text)
  addString(root, "expression_tag", row.tag)
  addString(root, "provider_text", providerText(row))
  addBool(root, "required_in_screenplay", row.requireInSource)
  Js.Json.object_(root)
}

let segmentJson = (segment: dialogueSegment) => {
  let root = Js.Dict.empty()
  addString(root, "id", segment.id)
  addString(root, "purpose", segment.purpose)
  addNumber(root, "seed", Belt.Int.toFloat(segment.seed))
  addNumber(root, "characters", Belt.Int.toFloat(segmentCharacters(segment)))
  addString(root, "request_sha256", dialogueRequestHash(segment))
  addString(root, "raw_cache", dialogueRawPath(segment))
  Js.Dict.set(root, "lines", Js.Json.array(segment.lines->Belt.Array.map(lineJson)))
  Js.Json.object_(root)
}

let sfxJson = (spec: generatedSfxSpec) => {
  let root = Js.Dict.empty()
  addString(root, "id", spec.id)
  addString(root, "model", "eleven_text_to_sound_v2")
  addString(root, "request_sha256", sfxRequestHash(spec))
  addString(root, "raw_cache", sfxRawPath(spec))
  addString(root, "prompt", spec.prompt)
  addNumber(root, "duration_seconds", spec.seconds)
  addNumber(root, "prompt_influence", spec.influence)
  addBool(root, "loop", spec.loop)
  Js.Json.object_(root)
}

let storyCueJson = (row: storyCue) => {
  let root = Js.Dict.empty()
  addString(root, "id", row.id)
  addString(root, "source_line_id", row.sourceLineId)
  addString(root, "treatment", treatmentName(row.treatment))
  addNumber(root, "authored_gap_after_seconds", row.gapAfter)
  Js.Json.object_(root)
}

let writePlan = (~estimated, ~missingDialogue, ~missingAlignment, ~missingSfx): string => {
  let signature = planSignature(~estimated, ~missingDialogue, ~missingAlignment, ~missingSfx)
  let planHash = sha256Text(signature)
  let path = planDir ++ "/KAALI_MITTI_THIRD_ECHO_PLAN_" ++ shortHash(planHash) ++ ".json"
  ensureDirPath(Path(planDir))
  let missingDialogueChars = missingDialogue->Belt.Array.reduce(0, (sum, segment) => sum + segmentCharacters(segment))
  let missingSfxSeconds = missingSfx->Belt.Array.reduce(0.0, (sum, spec) => sum +. spec.seconds)
  let root = Js.Dict.empty()
  addString(root, "schema", "kaali-mitti.third-echo-production-plan/v1")
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "assembly_version", assemblyVersion)
  addString(root, "canonical_screenplay", scriptPath)
  addString(root, "canonical_screenplay_sha256", approvedScriptSha256)
  addString(root, "plan_sha256", planHash)
  addString(root, "scope", "Complete narrator-free five-to-six-minute horror story, from the audibly operated recorder through the human answer and the copied voice behind the locked gate.")
  addString(root, "dialogue_model", "ElevenLabs eleven_v3 Text to Dialogue; Hindi normalization; six deterministic requests. Edit evidence is derived locally and never calls a provider alignment endpoint.")
  addString(root, "alignment_policy", "LOCAL_ALIGN=1 first projects flattened MLX large-v3 words across the ordered known lines. A line rejected only by a missing/weak local block receives a content-addressed physical PCM crop, bounded no-context MLX transcription, exact edge-anchor checks, and provider-core association; the crop proves words while full-take clocks and detected quiet gaps define edits. Hash-pinned local whisper.cpp remains independent fallback evidence. U* replies require complete exact matches. Cloud alignment is disabled with a hard request ceiling of zero.")
  addString(root, "local_projection_version", localProjectionVersion)
  addString(root, "local_silence_config", localSilenceConfig)
  addString(root, "local_nonverbal_silence_config", localNonverbalSilenceConfig)
  addString(root, "local_soft_speech_silence_config", localSoftSpeechSilenceConfig)
  addString(root, "local_turn_recovery_config", localTurnAlignmentConfig)
  addString(root, "sfx_model", "Eleven existing content-addressed ElevenLabs eleven_text_to_sound_v2 assets totaling 83 source seconds; valid v1 assets are reused, not regenerated.")
  addString(root, "music_policy", "Intentional silence. Mandu wind, monsoon rain, body-location foley, exact echoes and performance are the score.")
  addString(root, "voice_treatment_policy", voiceTreatmentPolicy)
  addString(root, "sound_placement_policy", soundPlacementPolicy)
  addString(root, "first_answer_cast_note", "The first ‘अभी नहीं’ uses a fourth, distinct ordinary human voice. Learned copies after that use Kunal's exact source performance.")
  addBool(root, "review_only", true)
  addString(root, "review_only_reason", insideGateReviewOnlyReason)
  addString(root, "sfx_identifiability_gate", "Every narrative event has its own provider asset. No semantic event is recovered by guessing a trim inside a composite plate.")
  addNumber(root, "estimated_master_seconds", estimated.masterDuration)
  addNumber(root, "missing_dialogue_requests", Belt.Int.toFloat(Belt.Array.length(missingDialogue)))
  addNumber(root, "missing_dialogue_characters", Belt.Int.toFloat(missingDialogueChars))
  addNumber(root, "maximum_new_dialogue_requests", Belt.Int.toFloat(maxNewDialogueRequests))
  addNumber(root, "maximum_new_dialogue_characters", Belt.Int.toFloat(maxNewDialogueCharacters))
  addNumber(root, "per_request_dialogue_character_ceiling", Belt.Int.toFloat(maxCharactersPerDialogueRequest))
  addNumber(root, "missing_local_alignment_jobs", Belt.Int.toFloat(Belt.Array.length(missingAlignment)))
  addNumber(root, "missing_cloud_alignment_requests", 0.0)
  addNumber(root, "maximum_new_cloud_alignment_requests", Belt.Int.toFloat(maxNewCloudAlignmentRequests))
  addNumber(root, "missing_sfx_requests", Belt.Int.toFloat(Belt.Array.length(missingSfx)))
  addNumber(root, "missing_sfx_seconds", missingSfxSeconds)
  addNumber(root, "estimated_sfx_credits_at_40_per_second", missingSfxSeconds *. 40.0)
  addString(root, "paid_gate", "PAID=1 plus the required GENERATE flag and APPROVED_PLAN_SHA256 equal to this exact plan; DRY=1 always wins.")
  Js.Dict.set(root, "cast", Js.Json.array(cast->Belt.Array.map(castJson)))
  Js.Dict.set(root, "dialogue_segments", Js.Json.array(segments->Belt.Array.map(segmentJson)))
  Js.Dict.set(root, "story_cues", Js.Json.array(storyCues->Belt.Array.map(storyCueJson)))
  Js.Dict.set(root, "generated_sfx", Js.Json.array(generatedSfx->Belt.Array.map(sfxJson)))
  let text = Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n"
  if exists(Path(path)) {
    if readText(Path(path)) != text { fail("content-addressed plan path contains different bytes") }
  } else if !writeTextExclusive(Path(path), text) { fail("could not publish content-addressed plan") }
  Js.log("PLAN -> " ++ path)
  Js.log("PLAN SHA-256 -> " ++ planHash)
  Js.log("MISSING DIALOGUE -> " ++ Belt.Int.toString(Belt.Array.length(missingDialogue)) ++ " requests / " ++ Belt.Int.toString(missingDialogueChars) ++ " characters")
  Js.log("MISSING LOCAL ALIGNMENT -> " ++ Belt.Int.toString(Belt.Array.length(missingAlignment)) ++ " zero-provider jobs; CLOUD ALIGNMENT -> 0 requests")
  Js.log("MISSING SFX -> " ++ Belt.Int.toString(Belt.Array.length(missingSfx)) ++ " requests / " ++ Js.Float.toString(missingSfxSeconds) ++ " seconds / " ++ Js.Float.toString(missingSfxSeconds *. 40.0) ++ " estimated credits")
  planHash
}

let requirePaidPlan = (~planHash, ~missingDialogue, ~missingAlignment, ~missingSfx): unit => {
  let dialogueChars = missingDialogue->Belt.Array.reduce(0, (sum, segment) => sum + segmentCharacters(segment))
  let sfxSeconds = missingSfx->Belt.Array.reduce(0.0, (sum, spec) => sum +. spec.seconds)
  if Belt.Array.length(missingDialogue) > maxNewDialogueRequests || dialogueChars > maxNewDialogueCharacters || Belt.Array.length(missingSfx) > maxNewSfxRequests || sfxSeconds > maxNewSfxSeconds +. 0.001 { fail("missing provider work exceeds paid ceilings") }
  if envDry == Some("1") || envPaid != Some("1") { fail("paid generation is locked; require PAID=1 with DRY unset") }
  if Belt.Array.length(missingDialogue) > 0 && envGenerateDialogue != Some("1") { fail("missing dialogue requires GENERATE_DIALOGUE=1") }
  if Belt.Array.length(missingAlignment) > 0 && envLocalAlign != Some("1") { fail("missing edit boundaries require LOCAL_ALIGN=1; cloud alignment is disabled") }
  if Belt.Array.length(missingSfx) > 0 && envGenerateSfx != Some("1") { fail("missing SFX requires GENERATE_SFX=1") }
  if envApprovedPlan != Some(planHash) { fail("APPROVED_PLAN_SHA256 does not match the exact missing-work plan") }
}

let placementFilter = (item: voicePlacement) => {
  let base = switch item.treatment {
  | BreathOnly => "aresample=48000,aformat=sample_fmts=fltp:channel_layouts=mono,"
  | Normal => "aresample=48000,aformat=sample_fmts=fltp:channel_layouts=mono,"
  | _ => "aresample=48000,aformat=sample_fmts=fltp:channel_layouts=mono,highpass=f=55,"
  }
  let body = switch item.treatment {
  | Normal => "aformat=channel_layouts=stereo"
  | NaturalEchoOne => "highpass=f=150,lowpass=f=5000,apad=pad_dur=0.8,aecho=0.8:0.45:390:0.24,aformat=channel_layouts=stereo,volume=-7dB"
  | NaturalEchoTwo => "highpass=f=220,lowpass=f=3900,apad=pad_dur=1.0,aecho=0.8:0.38:520:0.18,aformat=channel_layouts=stereo,volume=-12dB"
  | Playback => switch item.id {
      | "PLAY_ECHO_K03_1" => "highpass=f=300,lowpass=f=3200,apad=pad_dur=0.8,aecho=0.8:0.42:390:0.20,aformat=channel_layouts=stereo,acompressor=threshold=0.10:ratio=3:attack=4:release=80"
      | "PLAY_ECHO_K03_2" => "highpass=f=360,lowpass=f=2800,apad=pad_dur=1.0,aecho=0.8:0.35:520:0.15,aformat=channel_layouts=stereo,acompressor=threshold=0.10:ratio=3:attack=4:release=80"
      | "PLAY_ENTITY_01" => "highpass=f=180,lowpass=f=6000,aformat=channel_layouts=stereo,acompressor=threshold=0.12:ratio=2:attack=4:release=80"
      | _ => "highpass=f=280,lowpass=f=3400,aformat=channel_layouts=stereo,acompressor=threshold=0.10:ratio=3:attack=4:release=80"
      }
  | EntityHidden => "highpass=f=90,lowpass=f=8000,aformat=channel_layouts=stereo"
  | EntityNear => "highpass=f=110,lowpass=f=6200,equalizer=f=1100:t=q:w=1.0:g=-3,pan=stereo|c0=0.30*c0|c1=0.95*c0,volume=-1dB"
  | EntityFull => "highpass=f=72,lowpass=f=10500,pan=stereo|c0=0.22*c0|c1=0.98*c0,volume=0.8dB"
  | EntityBehindGate => "highpass=f=90,lowpass=f=3900,equalizer=f=1250:t=q:w=1.0:g=-2,aformat=channel_layouts=stereo,volume=-1dB"
  | BreathOnly => "highpass=f=4000,lowpass=f=10000,acompressor=threshold=0.04:ratio=3:attack=3:release=70,aformat=channel_layouts=stereo,volume=11dB"
  }
  base ++ body
}

let processedPlacementVolume = (item: voicePlacement): volumeStats => {
  let result = run(~cmd="ffmpeg", ~args=[
    "-nostdin", "-hide_banner", "-i", item.path,
    "-af", "atrim=0:" ++ Js.Float.toString(item.duration) ++ "," ++ placementFilter(item) ++
      ",volume=" ++ Js.Float.toString(item.gainDb) ++ "dB,volumedetect",
    "-f", "null", "-",
  ])
  if result.code != 0 { fail("processed placement volume analysis failed for " ++ item.id) }
  let valueFor = marker => switch result.stderr->Js.String2.split("\n")->Belt.Array.getBy(line => contains(line, marker)) {
  | Some(line) => switch floatAfter(line, marker) {
    | Some(value) => value
    | None => fail("processed placement volume is non-finite for " ++ item.id ++ " / " ++ marker)
    }
  | None => fail("processed placement volume omitted " ++ marker ++ " for " ++ item.id)
  }
  {meanDb: valueFor("mean_volume:"), maxDb: valueFor("max_volume:")}
}

let validateBreathAudibility = (placements: array<voicePlacement>): unit =>
  placements->Belt.Array.keep(item => item.treatment == BreathOnly)->Belt.Array.forEach(item => {
    let stats = processedPlacementVolume(item)
    if stats.meanDb < -42.0 || stats.maxDb < -30.0 {
      fail(
        item.id ++ " breath is effectively inaudible after de-voicing: mean=" ++
        Js.Float.toString(stats.meanDb) ++ " dB, max=" ++ Js.Float.toString(stats.maxDb) ++ " dB",
      )
    }
    if stats.meanDb > -20.0 || stats.maxDb > -3.0 {
      fail(
        item.id ++ " breath is too prominent after makeup: mean=" ++
        Js.Float.toString(stats.meanDb) ++ " dB, max=" ++ Js.Float.toString(stats.maxDb) ++ " dB",
      )
    }
  })

let validateTimeline = timeline => {
  let firstEntityDelay = turnFor(~timeline, "ENTITY_01").start -. turnFor(~timeline, "ECHO_K03_2").end_
  let k20Delay = turnFor(~timeline, "ENTITY_K20").start -. turnFor(~timeline, "K20").end_
  let k21Delay = turnFor(~timeline, "ENTITY_K21").start -. turnFor(~timeline, "K21").start
  let k22Delay = turnFor(~timeline, "ENTITY_06_OVERLAP").start -. turnFor(~timeline, "K22").start
  if firstEntityDelay < 1.99 { fail("first entity enters before the processed echo tail plus two seconds") }
  if Js.Math.abs_float(k20Delay -. 0.75) > 0.015 || Js.Math.abs_float(k21Delay -. 0.50) > 0.015 || Js.Math.abs_float(k22Delay -. 0.06) > 0.015 {
    fail("entity onset progression changed")
  }
  if !(firstEntityDelay > k20Delay && k20Delay > k21Delay && k21Delay > k22Delay) { fail("entity copy delays do not shrink monotonically") }
  let playbackCount = timeline.placements->Belt.Array.keep(item => starts(item.id, "PLAY_"))->Belt.Array.length
  if playbackCount != 4 { fail("the one playback must contain exactly four reused opening components") }
  let breathPlacements = timeline.placements->Belt.Array.keep(item => item.treatment == BreathOnly)
  if Belt.Array.length(breathPlacements) < 4 || Belt.Array.some(breathPlacements, item => item.duration > 3.5) { fail("breath-only performance gate failed") }
  if !Belt.Array.some(breathPlacements, item => starts(item.id, "FINAL_REAL_KUNAL_BREATH_")) { fail("real Kunal has no nearby body/breath under the final gate voice") }
  if timeline.masterDuration < 210.0 || timeline.masterDuration > 410.0 { fail("full story runtime " ++ Js.Float.toString(timeline.masterDuration) ++ "s falls outside the reviewed 3:30–6:50 envelope") }
}

let buildVoiceLane = (~timeline: timelineBuild): string => {
  ensureDirPath(Path(mixDir))
  let placements = timeline.placements
  validateBreathAudibility(placements)
  let config = "voice|forced-character-aligned-continuous-partitions|tight-reuse-echo-playback-entity|breath-devoiced-hp4k-makeup11db-qc=-42mean/-30max|48k-stereo|single-bus-loudnorm=-19/-3/11"
  let fingerprint = sha256Text(Js.Array2.joinWith([
    assemblyVersion,
    config,
    voiceTreatmentPolicy,
    Js.Float.toString(timeline.masterDuration),
    placements->Belt.Array.map(item => Js.Array2.joinWith([
      item.id, item.sourceLineId, sha256File(Path(item.path)), treatmentName(item.treatment), Js.Float.toString(item.start), Js.Float.toString(item.duration), Js.Float.toString(item.gainDb),
    ], "="))->Js.Array2.joinWith("||"),
  ], "###"))
  let path = mixDir ++ "/voice_" ++ shortHash(fingerprint) ++ ".wav"
  if !verifyDerivative(~path, ~fingerprint) {
    let scratch = tempDir("third-echo-voice-")->pathString
    let temporary = scratch ++ "/voice.wav"
    let inputs = placements->Belt.Array.map(item => ["-i", item.path])->Belt.Array.concatMany
    let chains = placements->Belt.Array.mapWithIndex((index, item) => {
      let label = Belt.Int.toString(index)
      let trimDuration = item.duration
      "[" ++ label ++ ":a]atrim=0:" ++ Js.Float.toString(trimDuration) ++ ",asetpts=PTS-STARTPTS," ++ placementFilter(item) ++ "," ++
      "apad=pad_dur=" ++ Js.Float.toString(floatMax(0.0, item.duration -. trimDuration)) ++ ",atrim=0:" ++ Js.Float.toString(item.duration) ++ "," ++
      "volume=" ++ Js.Float.toString(item.gainDb) ++ "dB,adelay=" ++ Belt.Int.toString(Belt.Float.toInt(item.start *. 48000.0)) ++ "S:all=1[v" ++ label ++ "]"
    })
    let labels = placements->Belt.Array.mapWithIndex((index, _) => "[v" ++ Belt.Int.toString(index) ++ "]")->Js.Array2.joinWith("")
    let graph = Js.Array2.joinWith(chains, ";") ++ ";anullsrc=r=48000:cl=stereo:d=" ++ Js.Float.toString(timeline.masterDuration) ++ "[clock];[clock]" ++ labels ++ "amix=inputs=" ++ Belt.Int.toString(Belt.Array.length(placements) + 1) ++ ":duration=first:normalize=0:dropout_transition=0,highpass=f=55,loudnorm=I=-19:TP=-3:LRA=11,atrim=0:" ++ Js.Float.toString(timeline.masterDuration) ++ "[out]"
    ffmpeg(Belt.Array.concatMany([["-nostdin", "-v", "error", "-n"], inputs, ["-filter_complex", graph, "-map", "[out]", "-ar", "48000", "-ac", "2", "-c:a", "pcm_s24le", temporary]]))
    publishDerivative(~temporary, ~path, ~fingerprint, ~kind="assembled third-echo voice, playback and entity lane")
  }
  path
}

let sfxPlacementFor = (~rows: array<sfxPlacement>, id): sfxPlacement => switch Belt.Array.getBy(rows, row => row.id == id) {
| Some(row) => row
| None => fail("SFX plan has no placement " ++ id)
}

let placementIntersection = (~aStart, ~aEnd, ~bStart, ~bEnd) => floatMax(0.0, floatMin(aEnd, bEnd) -. floatMax(aStart, bStart))

let validateSfxPlacements = (~timeline: timelineBuild, ~rows: array<sfxPlacement>): unit => {
  rows->Belt.Array.forEachWithIndex((index, row) => {
    if row.start < 0.0 || row.start +. row.duration > timeline.masterDuration +. 0.02 { fail("SFX lies outside master: " ++ row.id) }
    if index > 0 && Belt.Array.some(Js.Array2.slice(rows, ~start=0, ~end_=index), prior => prior.id == row.id) { fail("duplicate SFX placement " ++ row.id) }
  })
  if Belt.Array.length(rows->Belt.Array.keep(row => row.assetId == "distant_peacock")) != 1 { fail("the distant peacock may sound exactly once") }
  if Belt.Array.length(rows->Belt.Array.keep(row => row.assetId == "slip_fall")) != 1 { fail("the slip/fall transient may sound exactly once") }
  let fall = sfxPlacementFor(~rows, "SLIP_AND_FALL")
  let k22 = turnFor(~timeline, "K22")
  if fall.start +. fall.duration > k22.start -. 0.17 { fail("fall impact has not fully ended before Kunal's interrupted cry") }
  let playback = turnFor(~timeline, "PLAY_K03")
  rows->Belt.Array.keep(row => row.assetId == "keys_approach")->Belt.Array.forEach(keys => {
    if placementIntersection(~aStart=keys.start, ~aEnd=keys.start +. keys.duration, ~bStart=playback.start, ~bEnd=turnFor(~timeline, "PLAY_ENTITY_01").end_) > 0.01 {
      fail("Rafiq's keys must become completely still during the one playback")
    }
  })
  let openingControl = sfxPlacementFor(~rows, "RECORDER_OPENING")
  if openingControl.start < turnFor(~timeline, "M00").end_ +. 0.04 || openingControl.start +. openingControl.duration > turnFor(~timeline, "K00A").start -. 0.04 {
    fail("opening recorder control is not between the spoken button request and confirmation")
  }
  let playbackControl = sfxPlacementFor(~rows, "RECORDER_PLAYBACK")
  if playbackControl.start < turnFor(~timeline, "M07").end_ +. 0.04 || playbackControl.start +. playbackControl.duration > playback.start -. 0.04 {
    fail("playback controls must follow Meera's acknowledgement and finish before recorded speech")
  }
  let firstStop = sfxPlacementFor(~rows, "RECORDER_FIRST_STOP")
  if firstStop.start < turnFor(~timeline, "M09").end_ +. 0.04 || firstStop.start +. firstStop.duration > turnFor(~timeline, "R06A").start -. 0.20 {
    fail("the first recorder stop is not audible before Rafiq's search call")
  }
  let stolenStart = sfxPlacementFor(~rows, "RECORDER_STOLEN_START")
  if stolenStart.start < turnFor(~timeline, "M12").end_ || stolenStart.start +. stolenStart.duration > turnFor(~timeline, "K13").start -. 0.04 {
    fail("the stolen recording does not begin audibly before Kunal notices")
  }
  let finalStop = sfxPlacementFor(~rows, "RECORDER_FINAL_STOP")
  if finalStop.start < turnFor(~timeline, "M16").end_ +. 0.04 || finalStop.start +. finalStop.duration > turnFor(~timeline, "M17").start -. 0.04 {
    fail("the recorder is not audibly stopped before Meera says it is with her")
  }
  let gateOpen = sfxPlacementFor(~rows, "GATE_OPEN")
  let gateClose = sfxPlacementFor(~rows, "GATE_CLOSE_CHAIN_LOCK")
  if gateOpen.start +. gateOpen.duration > turnFor(~timeline, "R14").start -. 0.04 || gateClose.start < turnFor(~timeline, "R15").end_ +. 0.29 {
    fail("gate open/exit/close order changed")
  }
  let finalEntityStart = turnFor(~timeline, "ENTITY_07A").start
  rows->Belt.Array.keep(row => starts(row.id, "OUTSIDE_SLOW_STEPS_"))->Belt.Array.forEach(step => {
    if step.start +. step.duration > finalEntityStart +. 0.01 { fail("outside footsteps do not hard-stop at the final inside-gate voice") }
  })
  let rainClips = rows->Belt.Array.keep(row => row.assetId == "rain_bed")
  timeline.turns->Belt.Array.forEach(turn => {
    if turn.start >= turnFor(~timeline, "K13").start {
      let covered = rainClips->Belt.Array.reduce(0.0, (sum, clip) => sum +. placementIntersection(~aStart=turn.start, ~aEnd=turn.end_, ~bStart=clip.start, ~bEnd=clip.start +. clip.duration))
      if covered +. 0.04 < turn.end_ -. turn.start { fail("monsoon rain does not remain alive beneath " ++ turn.id) }
    }
  })
}

let buildSfxLane = (~timeline: timelineBuild, ~rows: array<sfxPlacement>): string => {
  ensureDirPath(Path(mixDir))
  let config = "sfx|elevenlabs-identifiable-assets|continuous-wind-rain-and-footsteps|48k-stereo|voice-overlap-rain-minus-6db|limit=.90"
  let fingerprint = sha256Text(Js.Array2.joinWith([
    assemblyVersion,
    config,
    soundPlacementPolicy,
    Js.Float.toString(timeline.masterDuration),
    rows->Belt.Array.map(item => Js.Array2.joinWith([
      item.id, item.assetId, item.assetSha256, Js.Float.toString(item.start), Js.Float.toString(item.trimStart), Js.Float.toString(item.duration), Js.Float.toString(item.gainDb),
    ], "="))->Js.Array2.joinWith("||"),
  ], "###"))
  let path = mixDir ++ "/sfx_" ++ shortHash(fingerprint) ++ ".wav"
  if !verifyDerivative(~path, ~fingerprint) {
    let scratch = tempDir("third-echo-sfx-")->pathString
    let temporary = scratch ++ "/sfx.wav"
    let inputs = rows->Belt.Array.map(item => ["-i", item.path])->Belt.Array.concatMany
    let chains = rows->Belt.Array.mapWithIndex((index, item) => {
      let label = Belt.Int.toString(index)
      let fadeOutStart = item.duration -. item.fadeOut
      let fadeIn = item.fadeIn > 0.0 ? "afade=t=in:st=0:d=" ++ Js.Float.toString(item.fadeIn) ++ "," : ""
      let fadeOut = item.fadeOut > 0.0 ? "afade=t=out:st=" ++ Js.Float.toString(fadeOutStart) ++ ":d=" ++ Js.Float.toString(item.fadeOut) ++ "," : ""
      "[" ++ label ++ ":a]atrim=start=" ++ Js.Float.toString(item.trimStart) ++ ":end=" ++ Js.Float.toString(item.trimStart +. item.duration) ++ ",asetpts=PTS-STARTPTS,aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo,highpass=f=25,loudnorm=I=-25:TP=-4:LRA=13," ++ fadeIn ++ fadeOut ++ "volume=" ++ Js.Float.toString(item.gainDb) ++ "dB,adelay=" ++ Belt.Int.toString(Belt.Float.toInt(item.start *. 1000.0)) ++ ":all=1[s" ++ label ++ "]"
    })
    let labels = rows->Belt.Array.mapWithIndex((index, _) => "[s" ++ Belt.Int.toString(index) ++ "]")->Js.Array2.joinWith("")
    let k22 = turnFor(~timeline, "K22")
    let theftEnd = floatMax(k22.end_, turnFor(~timeline, "ENTITY_06_OVERLAP").end_)
    let dipStart = k22.start -. 0.08
    let dipEnd = theftEnd +. 0.12
    let rainDip = "volume=eval=frame:volume='if(lt(t," ++ Js.Float.toString(dipStart) ++ "),1,if(lt(t," ++ Js.Float.toString(k22.start) ++ "),1-(t-" ++ Js.Float.toString(dipStart) ++ ")*6.2351625,if(lt(t," ++ Js.Float.toString(theftEnd) ++ "),0.501187,if(lt(t," ++ Js.Float.toString(dipEnd) ++ "),0.501187+(t-" ++ Js.Float.toString(theftEnd) ++ ")*4.156775,1))))',"
    let graph = Js.Array2.joinWith(chains, ";") ++ ";anullsrc=r=48000:cl=stereo:d=" ++ Js.Float.toString(timeline.masterDuration) ++ "[clock];[clock]" ++ labels ++ "amix=inputs=" ++ Belt.Int.toString(Belt.Array.length(rows) + 1) ++ ":duration=first:normalize=0:dropout_transition=0," ++ rainDip ++ "alimiter=limit=0.90:level=disabled,atrim=0:" ++ Js.Float.toString(timeline.masterDuration) ++ "[out]"
    ffmpeg(Belt.Array.concatMany([["-nostdin", "-v", "error", "-n"], inputs, ["-filter_complex", graph, "-map", "[out]", "-ar", "48000", "-ac", "2", "-c:a", "pcm_s24le", temporary]]))
    publishDerivative(~temporary, ~path, ~fingerprint, ~kind="assembled Mandu ambience and identifiable foley lane")
  }
  path
}

let buildSilentMusic = (~masterDuration): string => {
  ensureDirPath(Path(mixDir))
  let fingerprint = sha256Text(assemblyVersion ++ "|intentional-silent-score|" ++ Js.Float.toString(masterDuration))
  let path = mixDir ++ "/music_silent_" ++ shortHash(fingerprint) ++ ".wav"
  if !verifyDerivative(~path, ~fingerprint) {
    let scratch = tempDir("third-echo-music-")->pathString
    let temporary = scratch ++ "/music.wav"
    ffmpeg(["-nostdin", "-v", "error", "-n", "-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo", "-t", Js.Float.toString(masterDuration), "-c:a", "pcm_s24le", temporary])
    publishDerivative(~temporary, ~path, ~fingerprint, ~kind="intentional silent music lane")
  }
  path
}

let buildMaster = (~voicePath, ~sfxPath, ~musicPath, ~masterDuration): (string, string, string) => {
  ensureDirPath(Path(reviewDir))
  let fingerprint = sha256Text(Js.Array2.joinWith([
    assemblyVersion,
    Core.masterMixConfig,
    Js.Float.toString(masterDuration),
    sha256File(Path(voicePath)),
    sha256File(Path(sfxPath)),
    sha256File(Path(musicPath)),
  ], "###"))
  let wavPath = mixDir ++ "/KAALI_MITTI_THIRD_ECHO_REVIEW_MASTER_" ++ shortHash(fingerprint) ++ ".wav"
  if !verifyDerivative(~path=wavPath, ~fingerprint) {
    let scratch = tempDir("third-echo-master-")->pathString
    let temporary = scratch ++ "/master.wav"
    ffmpeg([
      "-nostdin", "-v", "error", "-n", "-i", voicePath, "-i", sfxPath, "-i", musicPath,
      "-filter_complex", Core.masterMixGraph(~duration=masterDuration),
      "-map", "[out]", "-ar", "48000", "-ac", "2", "-c:a", "pcm_s24le", temporary,
    ])
    publishDerivative(~temporary, ~path=wavPath, ~fingerprint, ~kind="third echo review-only WAV master")
  }
  let m4aFingerprint = sha256Text(fingerprint ++ "|" ++ sha256File(Path(wavPath)) ++ "|aac-256k-48k-stereo")
  let m4aPath = reviewDir ++ "/KAALI_MITTI_THIRD_ECHO_FULL_AUDIO_" ++ shortHash(m4aFingerprint) ++ ".m4a"
  if !verifyDerivative(~path=m4aPath, ~fingerprint=m4aFingerprint) {
    let scratch = tempDir("third-echo-review-")->pathString
    let temporary = scratch ++ "/review.m4a"
    ffmpeg([
      "-nostdin", "-v", "error", "-n", "-i", wavPath,
      "-map", "0:a:0", "-map_metadata", "-1", "-c:a", "aac", "-b:a", "256k", "-ar", "48000", "-ac", "2", "-movflags", "+faststart",
      "-metadata", "title=Kaali Mitti Ki Kahaniyan — Teesri Goonj — Full Audio",
      temporary,
    ])
    publishDerivative(~temporary, ~path=m4aPath, ~fingerprint=m4aFingerprint, ~kind="third echo review M4A")
  }
  (wavPath, m4aPath, fingerprint)
}

let analyzeLoudness = (path, label): loudnessStats => {
  let result = run(~cmd="ffmpeg", ~args=["-nostdin", "-hide_banner", "-i", path, "-af", "loudnorm=I=-16:TP=-2:LRA=9:print_format=json", "-f", "null", "-"])
  let left = Js.String2.lastIndexOf(result.stderr, "{")
  let right = Js.String2.lastIndexOf(result.stderr, "}")
  if result.code != 0 || left < 0 || right <= left { fail(label ++ " loudness analysis failed") }
  let json = Js.Json.parseExn(Js.String2.slice(result.stderr, ~from=left, ~to_=right + 1))
  let number = key => switch Belt.Float.fromString(stringField(json, key)) {
  | Some(value) => value
  | None => fail(label ++ " loudness analysis omitted " ++ key)
  }
  {integrated: number("input_i"), truePeak: number("input_tp"), lra: number("input_lra")}
}

let windowMeanDb = (~path, ~start, ~duration, ~label): float => {
  let result = run(~cmd="ffmpeg", ~args=[
    "-nostdin", "-hide_banner", "-ss", Js.Float.toString(start), "-t", Js.Float.toString(duration),
    "-i", path, "-af", "volumedetect", "-f", "null", "-",
  ])
  let marker = "mean_volume:"
  let row = switch result.stderr->Js.String2.split("\n")->Belt.Array.getBy(line => contains(line, marker)) {
  | Some(value) => value
  | None => fail(label ++ " volume analysis omitted mean_volume")
  }
  let from = Js.String2.indexOf(row, marker) + Js.String2.length(marker)
  let token = Js.String2.sliceToEnd(row, ~from)->trim->Js.String2.split(" ")->Belt.Array.get(0)->Belt.Option.getWithDefault("")
  switch Belt.Float.fromString(token) {
  | Some(value) => value
  | None => fail(label ++ " volume analysis returned invalid mean_volume")
  }
}

let finalQc = (~voicePath, ~sfxPath, ~wavPath, ~m4aPath, ~timeline): (loudnessStats, loudnessStats, loudnessStats, loudnessStats) => {
  let wavDuration = validateAudio(wavPath, "final WAV")
  let m4aDuration = validateAudio(m4aPath, "review M4A")
  if Js.Math.abs_float(wavDuration -. timeline.masterDuration) > 0.10 || Js.Math.abs_float(m4aDuration -. timeline.masterDuration) > 0.10 { fail("final duration QC failed") }
  let silence = run(~cmd="ffmpeg", ~args=["-nostdin", "-hide_banner", "-i", wavPath, "-af", "silencedetect=noise=-58dB:d=2.5", "-f", "null", "-"])
  if silence.stderr->Js.String2.split("\n")->Belt.Array.some(row => contains(row, "silence_duration:")) { fail("continuous Mandu sound world contains unintended silence longer than 2.5 seconds") }
  let voiceStats = analyzeLoudness(voicePath, "voice lane")
  let sfxStats = analyzeLoudness(sfxPath, "SFX lane")
  ["ENTITY_01", "PLAY_ENTITY_01"]->Belt.Array.forEach(id => {
    let turn = turnFor(~timeline, id)
    let duration = turn.end_ -. turn.start
    let voiceMean = windowMeanDb(~path=voicePath, ~start=turn.start, ~duration, ~label=id ++ " voice")
    let sfxMean = windowMeanDb(~path=sfxPath, ~start=turn.start, ~duration, ~label=id ++ " SFX")
    if voiceMean < -38.0 { fail(id ++ " is not audibly present in the voice lane") }
    if voiceMean -. sfxMean < 6.0 {
      fail(id ++ " has only " ++ Js.Float.toString(voiceMean -. sfxMean) ++ " dB clearance over ambience; require at least 6 dB")
    }
  })
  if sfxStats.integrated > voiceStats.integrated -. 1.5 { fail("unducked ambience and foley are too close to dialogue loudness") }
  if sfxStats.integrated < voiceStats.integrated -. 16.0 { fail("Mandu ambience is too faint before sidechain") }
  let wavStats = analyzeLoudness(wavPath, "WAV")
  let m4aStats = analyzeLoudness(m4aPath, "M4A")
  if wavStats.integrated < -16.8 || wavStats.integrated > -15.2 || wavStats.truePeak > -1.5 { fail("WAV loudness or peak QC failed") }
  if m4aStats.integrated < -16.8 || m4aStats.integrated > -15.2 || m4aStats.truePeak > -1.0 { fail("M4A loudness or peak QC failed") }
  if m4aStats.lra < 2.0 || m4aStats.lra > 16.0 { fail("M4A loudness range QC failed") }
  Js.log("QC PASS -> " ++ Js.Float.toString(timeline.masterDuration) ++ " seconds / " ++ Js.Float.toString(m4aStats.integrated) ++ " LUFS / " ++ Js.Float.toString(m4aStats.truePeak) ++ " dBTP")
  (voiceStats, sfxStats, wavStats, m4aStats)
}

let writeMasterManifest = (~timeline, ~sfxRows, ~planHash, ~voicePath, ~sfxPath, ~musicPath, ~wavPath, ~m4aPath, ~fingerprint, ~voiceStats, ~sfxStats, ~wavStats, ~m4aStats, ~newDialogueRequests, ~newLocalAlignmentJobs, ~newSfxRequests, ~newSfxSeconds): string => {
  let path = projectDir ++ "/KAALI_MITTI_THIRD_ECHO_MASTER_" ++ shortHash(fingerprint) ++ ".manifest.json"
  let root = Js.Dict.empty()
  addString(root, "schema", "kaali-mitti.third-echo-master/v1")
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "assembly_version", assemblyVersion)
  addString(root, "canonical_screenplay", scriptPath)
  addString(root, "canonical_screenplay_sha256", approvedScriptSha256)
  addString(root, "plan_sha256", planHash)
  addString(root, "master_fingerprint_sha256", fingerprint)
  addString(root, "scope", "Complete narrator-free third-echo horror story through the bodiless voice behind the locked gate.")
  addBool(root, "review_only", true)
  addString(root, "review_only_reason", insideGateReviewOnlyReason)
  addNumber(root, "duration_seconds", timeline.masterDuration)
  addString(root, "voice_lane", voicePath)
  addString(root, "voice_lane_sha256", sha256File(Path(voicePath)))
  addString(root, "sfx_lane", sfxPath)
  addString(root, "sfx_lane_sha256", sha256File(Path(sfxPath)))
  addString(root, "music_lane", musicPath)
  addString(root, "music_policy", "Intentional silence; Mandu ambience, rain, body-location foley, natural echoes and copied human voice are the score.")
  addString(root, "master_wav", wavPath)
  addString(root, "master_wav_sha256", sha256File(Path(wavPath)))
  addString(root, "review_m4a", m4aPath)
  addString(root, "review_m4a_sha256", sha256File(Path(m4aPath)))
  addNumber(root, "voice_lane_lufs", voiceStats.integrated)
  addNumber(root, "sfx_lane_lufs", sfxStats.integrated)
  addNumber(root, "wav_integrated_lufs", wavStats.integrated)
  addNumber(root, "wav_true_peak_dbtp", wavStats.truePeak)
  addNumber(root, "m4a_integrated_lufs", m4aStats.integrated)
  addNumber(root, "m4a_true_peak_dbtp", m4aStats.truePeak)
  addNumber(root, "m4a_lra_lu", m4aStats.lra)
  addNumber(root, "new_dialogue_requests", Belt.Int.toFloat(newDialogueRequests))
  addNumber(root, "new_local_alignment_jobs", Belt.Int.toFloat(newLocalAlignmentJobs))
  addNumber(root, "new_cloud_alignment_requests", 0.0)
  addNumber(root, "new_sfx_requests", Belt.Int.toFloat(newSfxRequests))
  addNumber(root, "new_sfx_seconds", newSfxSeconds)
  Js.Dict.set(root, "cast", Js.Json.array(cast->Belt.Array.map(castJson)))
  Js.Dict.set(root, "dialogue_segments", Js.Json.array(segments->Belt.Array.map(segmentJson)))
  Js.Dict.set(root, "generated_sfx", Js.Json.array(generatedSfx->Belt.Array.map(sfxJson)))
  Js.Dict.set(root, "voice_placements", Js.Json.array(timeline.placements->Belt.Array.map((item: voicePlacement) => {
    let row = Js.Dict.empty()
    addString(row, "id", item.id)
    addString(row, "source_line_id", item.sourceLineId)
    addString(row, "source_sha256", sha256File(Path(item.path)))
    addString(row, "treatment", treatmentName(item.treatment))
    addNumber(row, "start_seconds", item.start)
    addNumber(row, "end_seconds", item.start +. item.duration)
    Js.Json.object_(row)
  })))
  Js.Dict.set(root, "sfx_placements", Js.Json.array(sfxRows->Belt.Array.map((item: sfxPlacement) => {
    let row = Js.Dict.empty()
    addString(row, "id", item.id)
    addString(row, "asset_id", item.assetId)
    addString(row, "asset_sha256", item.assetSha256)
    addNumber(row, "start_seconds", item.start)
    addNumber(row, "end_seconds", item.start +. item.duration)
    addNumber(row, "gain_db", item.gainDb)
    Js.Json.object_(row)
  })))
  let text = Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n"
  if exists(Path(path)) {
    if readText(Path(path)) != text { fail("content-addressed master manifest contains different bytes") }
  } else if !writeTextExclusive(Path(path), text) { fail("could not publish master manifest") }
  path
}

let main = async (): unit => {
  validateScript()
  validateCast()
  validateSfxDesign()
  validateStoryCues()

  let missingDialogue = missingDialogueSegments()
  let missingAlignment = missingAlignmentSegments()
  let missingSfx = missingGeneratedSfx()
  let newDialogueRequests = Belt.Array.length(missingDialogue)
  let newSfxRequests = Belt.Array.length(missingSfx)
  let newSfxSeconds = missingSfx->Belt.Array.reduce(0.0, (sum, spec) => sum +. spec.seconds)
  let estimated = buildTimeline(~assets=None)
  validateTimeline(estimated)
  let planHash = writePlan(~estimated, ~missingDialogue, ~missingAlignment, ~missingSfx)

  if envDry == Some("1") {
    Js.log("DRY PASS — approved screenplay hash, six bounded v3 requests, offline local alignment, zero cloud-alignment calls, exact stem-reuse rules, timing progression and paid ceilings validated; zero paid calls.")
  } else if envAlignCachedOnly == Some("1") {
    let count = await alignCachedDialogueOnly()
    Js.log("LOCAL ALIGNMENT ONLY PASS -> " ++ Belt.Int.toString(count) ++ " cached dialogue segments; zero provider calls; no mix published.")
  } else {
    if Belt.Array.length(missingDialogue) > 0 || Belt.Array.length(missingSfx) > 0 {
      requirePaidPlan(~planHash, ~missingDialogue, ~missingAlignment, ~missingSfx)
    } else if Belt.Array.length(missingAlignment) > 0 && envLocalAlign != Some("1") {
      fail("missing edit boundaries require LOCAL_ALIGN=1; no paid or cloud alignment is needed")
    }
    let caches = await renderAllDialogue()
    await renderGeneratedSfx()
    let lineAssets = buildAllLineStems(caches)
    let timeline = buildTimeline(~assets=Some(lineAssets))
    validateTimeline(timeline)
    let sfxRows = buildSfxPlacements(~timeline)
    validateSfxPlacements(~timeline, ~rows=sfxRows)
    let voicePath = buildVoiceLane(~timeline)
    let sfxPath = buildSfxLane(~timeline, ~rows=sfxRows)
    let musicPath = buildSilentMusic(~masterDuration=timeline.masterDuration)
    let (wavPath, m4aPath, fingerprint) = buildMaster(~voicePath, ~sfxPath, ~musicPath, ~masterDuration=timeline.masterDuration)
    let (voiceStats, sfxStats, wavStats, m4aStats) = finalQc(~voicePath, ~sfxPath, ~wavPath, ~m4aPath, ~timeline)
    let manifest = writeMasterManifest(~timeline, ~sfxRows, ~planHash, ~voicePath, ~sfxPath, ~musicPath, ~wavPath, ~m4aPath, ~fingerprint, ~voiceStats, ~sfxStats, ~wavStats, ~m4aStats, ~newDialogueRequests, ~newLocalAlignmentJobs=Belt.Array.length(missingAlignment), ~newSfxRequests, ~newSfxSeconds)
    Js.log("MASTER WAV -> " ++ wavPath)
    Js.log("REVIEW M4A -> " ++ m4aPath)
    Js.log("MANIFEST -> " ++ manifest)
  }
}

main()
->Js.Promise2.catch(error => {
  Js.log2("KAALI MITTI THIRD ECHO FAILED:", error)
  exit(1)
  Js.Promise.resolve()
})
->ignore
