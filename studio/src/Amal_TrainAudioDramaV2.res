/* AMAL — complete audio-first train cold open, author revision 2026-08-31.

   The production is dialogue-led but never dialogue-only: an old steam
   passenger train remains audible beneath every spoken line, while footsteps,
   cloth, carriage hardware, flies, platform changes, and the final spill make
   otherwise visual action legible. Provider dialogue is split at dramatic
   movement boundaries and kept below ElevenLabs' 2,000-character reliability
   ceiling per request.

     DRY=1 node src/Amal_TrainAudioDramaV2.res.mjs

     PAID=1 GENERATE_DIALOGUE=1 GENERATE_SFX=1 \
       APPROVED_PLAN_SHA256=<exact dry-plan hash> \
       node src/Amal_TrainAudioDramaV2.res.mjs

   DRY always wins. Every paid request is claimed before it leaves the process;
   an existing claim with no immutable cache blocks automatic retry. */

open Cinema_Backends
module Core = EnochBrown_ColdOpenV8Core

@val @scope(("process", "env")) external envDry: option<string> = "DRY"
@val @scope(("process", "env")) external envPaid: option<string> = "PAID"
@val @scope(("process", "env")) external envGenerateDialogue: option<string> = "GENERATE_DIALOGUE"
@val @scope(("process", "env")) external envGenerateSfx: option<string> = "GENERATE_SFX"
@val @scope(("process", "env")) external envApprovedPlan: option<string> = "APPROVED_PLAN_SHA256"
@val @scope(("process", "env")) external envRecoverSystemBusySfx: option<string> = "RECOVER_SYSTEM_BUSY_SFX"
@val @scope("process") external exit: int => unit = "exit"

exception TrainAudioDramaError(string)

let pipelineVersion = "amal-train-audio-drama-v2.0.1"
let assemblyVersion = "amal-train-audio-drama-mix-v2.0.0"
let scriptPath = "../stories/amal/2026-08-31_TRAIN_AUDIO_FIRST_COLD_OPEN_v2.md"
let approvedScriptSha256 = "46b00cdc52aea77c3a0aeae3600a92549feaef1eed9dea1427260b158a82c1e7"
let projectDir = "../stories/amal/production/train_audio_drama_v2"
let cacheDir = projectDir ++ "/cache"
let rawDialogueDir = cacheDir ++ "/provider_raw/dialogue"
let rawSfxDir = cacheDir ++ "/provider_raw/sfx"
let claimDir = cacheDir ++ "/paid_claims"
let mixDir = projectDir ++ "/mix"
let planDir = projectDir ++ "/plans"
let reviewDir = projectDir ++ "/review"

let initialLead = 2.50
let reviewTail = 4.00
let maxCharactersPerDialogueRequest = 2000
let maxNewDialogueRequests = 9
let maxNewDialogueCharacters = 6500
let maxNewSfxRequests = 2
let maxNewSfxSeconds = 58.0

type speaker = Kamla | Suresh | Woman | Rajesh | Constable | SecondConstable

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
}

type dialogueSegment = {
  id: string,
  seed: int,
  lines: array<dialogueLine>,
  gapAfter: float,
  purpose: string,
}

type timedLine = {
  id: string,
  start: float,
  end_: float,
}

type segmentCache = {
  segmentId: string,
  rawPath: string,
  duration: float,
  timings: array<timedLine>,
}

type segmentPlacement = {
  segmentId: string,
  path: string,
  start: float,
  duration: float,
}

type timelineBuild = {
  turns: array<Core.turnWindow>,
  placements: array<segmentPlacement>,
  masterDuration: float,
}

type generatedSfxSpec = {
  id: string,
  prompt: string,
  seconds: float,
  influence: float,
  loop: bool,
}

type fixedAsset = {
  id: string,
  path: string,
  sha256: string,
  duration: float,
  source: string,
}

type audioAsset = {
  id: string,
  path: string,
  sha256: string,
  duration: float,
  source: string,
}

type loudnessStats = {
  integrated: float,
  truePeak: float,
  lra: float,
}

let fail = (message: string): 'a => raise(TrainAudioDramaError(message))
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
| Kamla => "KAMLA"
| Suresh => "SURESH"
| Woman => "WOMAN"
| Rajesh => "RAJESH"
| Constable => "CONSTABLE"
| SecondConstable => "SECOND_CONSTABLE"
}

let cast: array<castMember> = [
  {
    speaker: Suresh,
    accountName: "Aravinda — AMAL Suresh v2",
    voiceId: "SMQ9Cz6R2KznIR4Fr825",
    publicOwnerId: Some("7398804d9eaf2f463899a907587c33a390591775784f87857b6d0e1e4e3e66f6"),
    castingReason: "Middle-aged, gentle, warm and emotionally modulated; replaces the rejected flat Gajendra performance.",
  },
  {
    speaker: Rajesh,
    accountName: "Krish — AMAL Rajesh",
    voiceId: "eUfplp5rzZJd9uBGf0sv",
    publicOwnerId: Some("7398804d9eaf2f463899a907587c33a390591775784f87857b6d0e1e4e3e66f6"),
    castingReason: "Young, easygoing counterweight to his older brother.",
  },
  {
    speaker: Kamla,
    accountName: "Madhusmita — AMAL Kamla",
    voiceId: "0VYKG6D7F62aQxdckt3c",
    publicOwnerId: Some("7398804d9eaf2f463899a907587c33a390591775784f87857b6d0e1e4e3e66f6"),
    castingReason: "Conversational energy and domestic warmth; approved in the opening proof.",
  },
  {
    speaker: Woman,
    accountName: "Mahira — AMAL Woman",
    voiceId: "subIZc6skATBQ1Rbqpi7",
    publicOwnerId: None,
    castingReason: "Can contract into guarded monosyllables and later break into accusation and panic.",
  },
  {
    speaker: Constable,
    accountName: "Raju — AMAL Constable",
    voiceId: "8re6K5bW5keUyIP58qVH",
    publicOwnerId: None,
    castingReason: "Plain authority that can move from reassurance to irritation and command.",
  },
  {
    speaker: SecondConstable,
    accountName: "Shivank — AMAL Second Constable",
    voiceId: "M1baVR22tUikfDMapkh7",
    publicOwnerId: None,
    castingReason: "A distinct adult witness voice for the reveal; used for only one shocked line.",
  },
]

let line = (~id, ~speaker, ~text, ~tag=""): dialogueLine => {id, speaker, text, tag}

let segments: array<dialogueSegment> = [
  {
    id: "ordinary_world",
    seed: 831001,
    gapAfter: 0.65,
    purpose: "Name the husband, wife and devar through ordinary family friction before any suspicion exists.",
    lines: [
      line(~id="O01", ~speaker=Kamla, ~tag="[animated]", ~text="मैंने कहा था ना, सुबह वाली गाड़ी पकड़ लेते। अब बैठो इस लू में। और वो अचार वाला डब्बा तुमने ऊपर रखा है कि नीचे? मुझे तो याद ही नहीं आ रहा।"),
      line(~id="O02", ~speaker=Suresh, ~tag="[warmly teasing]", ~text="अपने देवर से पूछो। सामान उसी ने चढ़ाया था।"),
      line(~id="O03", ~speaker=Kamla, ~text="राजेश? सुन रहे हो? अचार का डब्बा कहाँ रखा?"),
      line(~id="O04", ~speaker=Rajesh, ~tag="[calling from nearby]", ~text="ऊपर है, भाभी। आपकी लाल पोटली के पीछे।"),
      line(~id="O05", ~speaker=Kamla, ~text="और पानी?"),
      line(~id="O06", ~speaker=Rajesh, ~tag="[playfully]", ~text="पानी मेरे पास है। अब कुछ और खोया है तो अभी बता दो।"),
      line(~id="O07", ~speaker=Suresh, ~tag="[amused]", ~text="बाद में मत पूछना। ये पूरी बोगी में ढूँढवाएगी।"),
      line(~id="O08", ~speaker=Kamla, ~tag="[mock offended]", ~text="अच्छा जी? शादी में तुम्हारा रुमाल भी मैं ही ढूँढूँगी, सुरेश।"),
      line(~id="O09", ~speaker=Kamla, ~text="और हाँ, उतरते ही जीजाजी को खबर कर देना। पिछली बार देर हुई थी तो शादी भर मुँह फुलाए बैठे रहे।"),
      line(~id="O10", ~speaker=Suresh, ~tag="[easy reassurance]", ~text="कर दूँगा।"),
    ],
  },
  {
    id: "reserved_woman",
    seed: 831002,
    gapAfter: 0.90,
    purpose: "Let the stranger close every conversational door, then have Kamla privately notice the pattern while Suresh initially defends her.",
    lines: [
      line(~id="R01", ~speaker=Kamla, ~tag="[friendly, brushing away a fly]", ~text="उई। ये मक्खियाँ कहाँ से आ गईं इतनी? बहन, आपके ही पास भिनभिना रही हैं। कुछ मीठा रखा है क्या?"),
      line(~id="R02", ~speaker=Woman, ~tag="[briefly]", ~text="नहीं।"),
      line(~id="R03", ~speaker=Kamla, ~text="बच्चा कितने महीने का है?"),
      line(~id="R04", ~speaker=Woman, ~tag="[guarded]", ~text="छह।"),
      line(~id="R05", ~speaker=Kamla, ~text="लड़का है?"),
      line(~id="R06", ~speaker=Woman, ~tag="[briefly]", ~text="हाँ।"),
      line(~id="R07", ~speaker=Kamla, ~tag="[gently concerned]", ~text="इतनी गरमी में सिर तक लपेट रखा है। कपड़ा थोड़ा हटा दो, हवा लगेगी।"),
      line(~id="R08", ~speaker=Woman, ~tag="[closed off]", ~text="सो रहा है। ठीक है वो।"),
      line(~id="R09", ~speaker=Kamla, ~tag="[lower, privately to her family]", ~text="बड़ी चुप-चुप सी हैं। दो बात पूछो तो एक शब्द में निपटा देती हैं।"),
      line(~id="R10", ~speaker=Suresh, ~tag="[gently]", ~text="बच्चा साथ हो तो सफ़र में आदमी थक जाता है, कमला। रहने दो।"),
      line(~id="R11", ~speaker=Kamla, ~tag="[mildly defensive]", ~text="मैं कौन-सा उसका बक्सा खोल रही हूँ। बच्चे को हवा लग जाए, बस इतना कहा।"),
    ],
  },
  {
    id: "first_suspicion",
    seed: 831003,
    gapAfter: 5.50,
    purpose: "Make Suresh's diverted attention audible, motivate the stretch aloud, then move into the brothers' first whisper.",
    lines: [
      line(~id="S01", ~speaker=Kamla, ~text="हाँ, तो मैं कह रही थी—जीजी का घर स्टेशन से दस मिनट है, पर रिक्शे वाले दिन में लूटते हैं। सुरेश?"),
      line(~id="S02", ~speaker=Suresh, ~tag="[distracted]", ~text="हूँ?"),
      line(~id="S03", ~speaker=Kamla, ~text="सुन भी रहे हो?"),
      line(~id="S04", ~speaker=Suresh, ~text="हाँ।"),
      line(~id="S05", ~speaker=Kamla, ~text="मैंने क्या कहा?"),
      line(~id="S06", ~speaker=Suresh, ~tag="[caught out]", ~text="अचार ऊपर है।"),
      line(~id="S07", ~speaker=Rajesh, ~tag="[amused]", ~text="वो मैंने कहा था, भैया।"),
      line(~id="S08", ~speaker=Kamla, ~text="अरे सुरेश, कहाँ जा रहे हो?"),
      line(~id="S09", ~speaker=Suresh, ~tag="[casual cover]", ~text="कहीं नहीं। पैर अकड़ गए हैं। ज़रा बीच में खड़ा होकर अंगड़ाई ले लूँ।"),
      line(~id="S10", ~speaker=Kamla, ~text="अब बैठो भी। रास्ता रोक रहे हो।"),
      line(~id="S11", ~speaker=Suresh, ~tag="[low, uneasy]", ~text="राजेश। इधर आ ज़रा।"),
      line(~id="S12", ~speaker=Rajesh, ~text="क्या हुआ, भैया?"),
      line(~id="S13", ~speaker=Suresh, ~tag="[whispers, troubled]", ~text="धीरे बोल। उस औरत को देख। बच्चे को। इतनी गरमी है और उसने मुँह तक ढक रखा है। गाड़ी चली तब से बच्चा एक बार भी हिला तेरे को?"),
      line(~id="S14", ~speaker=Rajesh, ~tag="[matter-of-fact]", ~text="सो रहा होगा। छोटे बच्चे दिन भर सोते हैं। ठंड भी जल्दी लग जाती है इनको, इसीलिए ढका होगा। तुम भी ना।"),
      line(~id="S15", ~speaker=Suresh, ~tag="[still uneasy]", ~text="इतने झटकों में भी?"),
      line(~id="S16", ~speaker=Rajesh, ~tag="[dismissive but affectionate]", ~text="भैया, आराम से बैठो।"),
    ],
  },
  {
    id: "first_station",
    seed: 831004,
    gapAfter: 4.50,
    purpose: "Use the platform errand to give Suresh a second, gentler attempt through the window.",
    lines: [
      line(~id="P01", ~speaker=Suresh, ~text="कमला, मैं पानी और कुछ खाने का ले आता हूँ।"),
      line(~id="P02", ~speaker=Kamla, ~text="जल्दी आना। राजेश, तुम सामान देखना।"),
      line(~id="P03", ~speaker=Suresh, ~tag="[calling through the window]", ~text="कमला, पकड़ो। पानी चाहिए?"),
      line(~id="P04", ~speaker=Kamla, ~text="पहले बताओ नमकीन लाए कि मीठा। राजेश को भी देना।"),
      line(~id="P05", ~speaker=Rajesh, ~tag="[nearby, amused]", ~text="भाभी, मैं आपके सामने बैठा हूँ।"),
      line(~id="P06", ~speaker=Kamla, ~text="तो हाथ बढ़ाओ ना।"),
      line(~id="P07", ~speaker=Suresh, ~tag="[gently, through the window]", ~text="बहन जी, सब ठीक है? बच्चा कैसा है? एक बार चेहरा दिखा दीजिए।"),
      line(~id="P08", ~speaker=Woman, ~tag="[curt]", ~text="सो रहा है। उसे रहने दो।"),
    ],
  },
  {
    id: "family_huddle",
    seed: 831005,
    gapAfter: 6.00,
    purpose: "Turn the private suspicion into a decision while Rajesh makes the social cost explicit.",
    lines: [
      line(~id="H01", ~speaker=Kamla, ~tag="[lower]", ~text="सुरेश, आपने उसे फिर क्यों टोका?"),
      line(~id="H02", ~speaker=Suresh, ~tag="[uneasy, trying to stay calm]", ~text="चेहरा नहीं दिखा रही। बच्चा हिला भी नहीं। मुझे ठीक नहीं लग रहा।"),
      line(~id="H03", ~speaker=Rajesh, ~tag="[cautioning him]", ~text="भैया, अकेली औरत है। आप बार-बार देखोगे तो उसे क्या लगेगा?"),
      line(~id="H04", ~speaker=Kamla, ~tag="[hushed, now worried]", ~text="राजेश, मैंने भी गौर किया है। बच्चा एक बार रोया नहीं, करवट नहीं ली। और ये मक्खियाँ बार-बार उसी कपड़े पर जा रही हैं।"),
      line(~id="H05", ~speaker=Rajesh, ~tag="[skeptical]", ~text="तुम दोनों ने अब बात पकड़ ली है।"),
      line(~id="H06", ~speaker=Suresh, ~tag="[quiet resolve]", ~text="अगले स्टेशन पर सिपाही को बता दूँगा। बस एक बार देख लेगा।"),
      line(~id="H07", ~speaker=Rajesh, ~text="और कुछ ना निकला तो?"),
      line(~id="H08", ~speaker=Suresh, ~tag="[plainly]", ~text="तो सबके सामने माफ़ी माँग लूँगा।"),
    ],
  },
  {
    id: "escape_and_pursuit",
    seed: 831006,
    gapAfter: 4.00,
    purpose: "Let the woman hear the police plan, abandon her trunk and force the story into the next coach.",
    lines: [
      line(~id="E01", ~speaker=Suresh, ~tag="[decisive]", ~text="राजेश, चल। सिपाही से बात करके आते हैं।"),
      line(~id="E02", ~speaker=Kamla, ~text="सुरेश, जल्दी लौटना। गाड़ी छूट ना जाए।"),
      line(~id="E03", ~speaker=Kamla, ~tag="[calling after the woman]", ~text="अरे बहन, कहाँ जा रही हो?"),
      line(~id="E04", ~speaker=Woman, ~tag="[urgent, clipped]", ~text="रास्ता दो।"),
      line(~id="E05", ~speaker=Kamla, ~text="आपका बक्सा यहीं है।"),
      line(~id="E06", ~speaker=Woman, ~tag="[moving away]", ~text="वापस आऊँगी।"),
      line(~id="E07", ~speaker=Suresh, ~tag="[returning with the police]", ~text="यहीं बैठी थी।"),
      line(~id="E08", ~speaker=Kamla, ~tag="[urgent]", ~text="अगले डिब्बे में गई है, सुरेश। बक्सा यहीं छोड़ गई।"),
      line(~id="E09", ~speaker=Constable, ~tag="[firm]", ~text="चलिए।"),
    ],
  },
  {
    id: "false_relief",
    seed: 831007,
    gapAfter: 0.80,
    purpose: "Turn suspicion back on Suresh, compel only a partial look, and let authority declare the matter finished.",
    lines: [
      line(~id="C01", ~speaker=Constable, ~tag="[calling through the crowd]", ~text="बहन जी! ज़रा रुकिए।"),
      line(~id="C02", ~speaker=Woman, ~tag="[alarmed]", ~text="क्या है? मैंने क्या किया?"),
      line(~id="C03", ~speaker=Constable, ~tag="[firm but calm]", ~text="बच्चे को एक बार देखना है।"),
      line(~id="C04", ~speaker=Woman, ~tag="[louder, accusing]", ~text="उस आदमी से पूछो। मेरे पीछे पड़ा है जब से चढ़ा है। औरत अकेली देखी तो घूरता रहा। सीट छोड़ दी, फिर भी पीछे आ गया।"),
      line(~id="C05", ~speaker=Suresh, ~tag="[embarrassed but controlled]", ~text="साहब, मेरी पत्नी उसी डिब्बे में बैठी है। मैं बस बच्चे का चेहरा—"),
      line(~id="C06", ~speaker=Woman, ~tag="[cutting him off]", ~text="झूठ बोल रहा है।"),
      line(~id="C07", ~speaker=Constable, ~tag="[reassuring the woman]", ~text="ठीक है, सुरेश जी। आप पीछे रहिए। बहन जी, बच्चे को जगाएँगे नहीं। कपड़ा थोड़ा हटा दीजिए। बस चेहरा देखेंगे।"),
      line(~id="C08", ~speaker=Constable, ~tag="[relieved, then dismissive]", ~text="देखा? सो रहा है। बात ख़त्म। चलिए।"),
      line(~id="C09", ~speaker=Suresh, ~tag="[more insistent]", ~text="साहब, एक मिनट। पूरा कपड़ा हटवाइए।"),
      line(~id="C10", ~speaker=Constable, ~tag="[irritated]", ~text="बस कीजिए, सुरेश जी। अकेली औरत है। बच्चा दिखा दिया उसने।"),
      line(~id="C11", ~speaker=Suresh, ~tag="[controlled urgency]", ~text="मक्खियाँ उसके ऊपर बैठ रही हैं। इतने झटकों में वो हिला तक नहीं।"),
      line(~id="C12", ~speaker=Woman, ~tag="[a sharp warning]", ~text="हाथ मत लगाना मेरे बच्चे को।"),
    ],
  },
  {
    id: "the_grab",
    seed: 831008,
    gapAfter: 2.60,
    purpose: "Give the physical grab and opening room to occur in sound before anyone explains what fell out.",
    lines: [
      line(~id="G01", ~speaker=Woman, ~tag="[screaming, struggling]", ~text="नहीं! मत छू उसको! छोड़! दे दे मुझे!"),
    ],
  },
  {
    id: "the_reveal",
    seed: 831009,
    gapAfter: 0.0,
    purpose: "Identify the stitches and opium in two broken discoveries, then end inside the mother's scream.",
    lines: [
      line(~id="X01", ~speaker=SecondConstable, ~tag="[shocked, losing his words]", ~text="बच्चे के पेट पर... ये टाँके किसने लगाए?"),
      line(~id="X02", ~speaker=Rajesh, ~tag="[horrified]", ~text="भैया... ये अफ़ीम है?"),
      line(~id="X03", ~speaker=Constable, ~tag="[shouting to the crowd]", ~text="सब पीछे हटो!"),
      line(~id="X04", ~speaker=Woman, ~tag="[screaming, breaking apart]", ~text="मेरा बच्चा! दे दो! मेरा बच्चा है वो! दे दो मुझे!"),
    ],
  },
]

let generatedSfx: array<generatedSfxSpec> = [
  {
    id: "steam_train_interior",
    prompt: "Seamless sustained interior ride inside an old Indian steam passenger train: rhythmic steel wheels crossing rail joints, weighty wooden coach rattle, low steam locomotive chuffs transmitted through the carriage floor, gentle open-window air, documentary field recording with a steady unchanging travel phase.",
    seconds: 30.0,
    influence: 0.62,
    loop: true,
  },
  {
    id: "steam_train_station_cycle",
    prompt: "An old Indian steam passenger train completes one rural station cycle in a documentary field recording: first eight seconds of wheels decelerating with rail clatter and brake flange squeal, then six seconds idling with piston chuffs and a broad steam release beside an indistinct busy platform, then a long steam whistle and fourteen seconds accelerating away as chuffs and wheel rhythm build with real mechanical weight.",
    seconds: 28.0,
    influence: 0.72,
    loop: false,
  },
]

let fixedAssets: array<fixedAsset> = [
  {
    id: "adult_passenger_walla",
    path: "../stories/amal/production/train_audio_proof_v1/cache/provider_raw/sfx/adult_passenger_walla_212d7b8262b34be25199.mp3",
    sha256: "7eaaee8331e56fcf0b302b6d2e7706c08f2175f4605dce648f24464d23ace568",
    duration: 12.0,
    source: "immutable ElevenLabs eleven_text_to_sound_v2 asset generated for the accepted opening proof",
  },
  {
    id: "close_houseflies",
    path: "../stories/amal/production/train_audio_proof_v1/cache/provider_raw/sfx/close_houseflies_f47dd9af5dc50279cc8b.mp3",
    sha256: "4c483ab04944344adf6a27003d1d3d0a800a25bc2b125832ecf9fc01e184097c",
    duration: 6.0,
    source: "immutable ElevenLabs eleven_text_to_sound_v2 asset generated for the accepted opening proof",
  },
  {
    id: "metal_luggage_jolt",
    path: "/Users/dusty/SFX/PSE/METLCrsh_Metal Cans Movement_PSE_SMV1_Z7NDA.wav",
    sha256: "f042160dde6816bdb25d8726cbc117d649045bc7a3a54504c6808610624f045f",
    duration: 56.096,
    source: "owned PSE CORE local library asset",
  },
  {
    id: "cloth_rustle",
    path: "/Users/dusty/SFX/PSE/CLOTHMvmt_Cloth Rustle Close Up Heavy Fabric Movement 01_PSE_GEN2_QN1BA.wav",
    sha256: "a20e79d16ba04eff3ab8d3dd7845a3861baea8b76cc2c217abf67d721dde8a7b",
    duration: 2.304,
    source: "owned PSE CORE local library asset",
  },
  {
    id: "fan_rattle",
    path: "/Users/dusty/SFX/PSE/AMBRoom_Vent Rattle Hallway Air Conditioning Shaking CU_PSE_GEN_gYLeA.wav",
    sha256: "11231f36ea56cf4ff3a5686ff4c6ba311ddfbbe7176de9f6015dd8057d9c4465",
    duration: 55.013333,
    source: "owned PSE CORE local library asset; mechanical ceiling-fan proxy",
  },
  {
    id: "seat_scrape",
    path: "/Users/dusty/SFX/PSE/WOODMvmt_Wood Scrape Chair Cement_PSE_GEN_R61Oy.wav",
    sha256: "f2b3236b5d1eda2b41bce031b861ec9168ff722fdbf375cd638b621355b87aee",
    duration: 25.248,
    source: "owned PSE CORE local library asset",
  },
  {
    id: "steam_hiss",
    path: "/Users/dusty/SFX/PSE/AIRHiss_Air Burst Compressor Air Steam_PSE_GEN3_pkUEf.wav",
    sha256: "3d02203384bd09b08eef72be3c4ce99970122aea5f1f8a0e9bfc53bb82185fb6",
    duration: 17.0,
    source: "owned PSE CORE local library asset",
  },
  {
    id: "metal_footsteps",
    path: "/Users/dusty/SFX/PSE/FEETHmn_Sneakers Two Footsteps Metal_PSE_FTS_O72Dr.wav",
    sha256: "2161e334573f8efc9692b0f4916530ea349fecedfc9aa848e0cf37e7e8563d4e",
    duration: 1.503854,
    source: "owned PSE CORE local library asset",
  },
  {
    id: "coach_door",
    path: "/Users/dusty/SFX/PSE/DOORMetl_Old Metal Hatch Creaky Eerie Boat_PSE_GEN_1THqJ.wav",
    sha256: "94eba6d91bca1df864271581f56ee230e34d01def8988687e3d3baed6c57dd1c",
    duration: 3.557333,
    source: "owned PSE CORE local library asset; old inter-coach door proxy",
  },
  {
    id: "fabric_tear",
    path: "/Users/dusty/SFX/PSE/PAPRRip_Ripping Paper Single Short Tear Quick_PSE_GEN_yF9PG.wav",
    sha256: "c539983dbea0108e2844771dacb46d0cd602f5dd30dc4de6d52df754115fe493",
    duration: 0.976,
    source: "owned PSE CORE local library asset; dry cloth-tear layer",
  },
  {
    id: "wrapped_packets_spill",
    path: "/Users/dusty/SFX/PSE/PAPRHndl_Paper Movements Impact Crunchy Crinkle 03_PSE_GEN2_6bsjL.wav",
    sha256: "09e3bed37aa3d3ecfb98b1d67ee0ac3d044fb489296817d3aa51415eff1fe5d4",
    duration: 6.656,
    source: "owned PSE CORE local library asset",
  },
  {
    id: "heavy_fabric_move",
    path: "/Users/dusty/SFX/PSE/CLOTHFlp_Heavy Cotton Fabric Whoosh By_PSE_GEN_fFE6x.wav",
    sha256: "866fc024de266bf1aeacf2f48c23b69b93c71acd69fa49b8214823680ce5ad2f",
    duration: 12.0,
    source: "owned PSE CORE local library asset",
  },
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

let providerText = (line: dialogueLine) => line.tag == "" ? line.text : line.tag ++ " " ++ line.text
let allLines = (): array<dialogueLine> => segments->Belt.Array.map(segment => segment.lines)->Belt.Array.concatMany
let segmentCharacters = (segment: dialogueSegment) => segment.lines->Belt.Array.reduce(0, (sum, row) => sum + Js.String2.length(providerText(row)))
let totalDialogueCharacters = () => segments->Belt.Array.reduce(0, (sum, segment) => sum + segmentCharacters(segment))

let castSignature = () => cast->Belt.Array.map(member =>
  speakerName(member.speaker) ++ "=" ++ member.voiceId ++ "=" ++ member.publicOwnerId->Belt.Option.getWithDefault("account")
)->Js.Array2.joinWith("|")

let segmentFor = id => switch Belt.Array.getBy(segments, (segment: dialogueSegment) => segment.id == id) {
| Some(segment) => segment
| None => fail("unknown dialogue segment " ++ id)
}

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
  if duration <= 0.2 { fail(label ++ " has invalid duration") }
  duration
}

let validateScript = (): unit => {
  if !exists(Path(scriptPath)) { fail("audio-first source script is missing") }
  let actual = sha256File(Path(scriptPath))
  if actual != approvedScriptSha256 { fail("audio-first source changed; expected " ++ approvedScriptSha256 ++ ", got " ++ actual) }
  let source = compact(readText(Path(scriptPath)))
  let cursor = ref(0)
  allLines()->Belt.Array.forEach(row => {
    let needle = compact(row.text)
    let tail = Js.String2.sliceToEnd(source, ~from=cursor.contents)
    let relative = Js.String2.indexOf(tail, needle)
    if relative < 0 { fail(row.id ++ " is not present in source order") }
    cursor := cursor.contents + relative + Js.String2.length(needle)
  })
  let combined = allLines()->Belt.Array.map(row => row.text)->Js.Array2.joinWith(" ")
  [
    "अपने देवर से पूछो",
    "राजेश? सुन रहे हो?",
    "तुम्हारा रुमाल भी मैं ही ढूँढूँगी, सुरेश",
    "बड़ी चुप-चुप सी हैं",
    "बच्चा साथ हो तो सफ़र में आदमी थक जाता है, कमला",
    "अरे सुरेश, कहाँ जा रहे हो",
    "ज़रा बीच में खड़ा होकर अंगड़ाई ले लूँ",
    "राजेश। इधर आ ज़रा",
    "धीरे बोल",
    "तो सबके सामने माफ़ी माँग लूँगा",
    "ये टाँके किसने लगाए",
    "ये अफ़ीम है",
  ]->Belt.Array.forEach(fragment => if !contains(combined, fragment) { fail("missing author-directed audio orientation: " ++ fragment) })
  if contains(lower(combined), "narrator") || contains(combined, "सूत्रधार") || contains(combined, "रतन") || contains(combined, "देवा") {
    fail("train cold open must remain narrator-free and must not introduce Ratan or Deva")
  }
  if memberFor(Suresh).voiceId == "6xalENe4gtaDq8XTGd7G" { fail("rejected flat Suresh voice remains selected") }
  let sureshTags = allLines()->Belt.Array.keep(row => row.speaker == Suresh)->Belt.Array.map(row => row.tag)->Js.Array2.joinWith(" ")
  ["warmly", "gently", "distracted", "whispers", "insistent", "urgency"]->Belt.Array.forEach(tag =>
    if !contains(lower(sureshTags), tag) { fail("Suresh performance arc is missing " ++ tag) }
  )
  segments->Belt.Array.forEach(segment => {
    let count = segmentCharacters(segment)
    if count <= 0 || count > maxCharactersPerDialogueRequest {
      fail(segment.id ++ " has " ++ Belt.Int.toString(count) ++ " provider characters; maximum reliable request is 2,000")
    }
    if segment.gapAfter < 0.0 || segment.gapAfter > 6.0 { fail(segment.id ++ " has invalid authored movement gap") }
  })
  if Belt.Array.length(segments) > maxNewDialogueRequests || totalDialogueCharacters() > maxNewDialogueCharacters {
    fail("dialogue design exceeds hard paid ceilings")
  }
}

let validateCast = (): unit => {
  if Belt.Array.length(cast) != 6 { fail("complete train scene requires six distinct speaking voices") }
  cast->Belt.Array.forEachWithIndex((index, member) => {
    if trim(member.voiceId) == "" || trim(member.accountName) == "" || trim(member.castingReason) == "" { fail("incomplete cast member " ++ speakerName(member.speaker)) }
    if index > 0 && Belt.Array.some(Js.Array2.slice(cast, ~start=0, ~end_=index), prior => prior.voiceId == member.voiceId) {
      fail("two speaking characters share voice " ++ member.voiceId)
    }
  })
}

let validateFixedAssets = (): unit => fixedAssets->Belt.Array.forEach(asset => {
  if !exists(Path(asset.path)) { fail("fixed sound asset is missing: " ++ asset.id) }
  if sha256File(Path(asset.path)) != asset.sha256 { fail("fixed sound asset bytes changed: " ++ asset.id) }
  let duration = validateAudio(asset.path, "fixed sound " ++ asset.id)
  if Js.Math.abs_float(duration -. asset.duration) > 0.08 { fail("fixed sound duration changed: " ++ asset.id) }
})

let validateSfxDesign = (): unit => {
  generatedSfx->Belt.Array.forEach(spec => {
    let prompt = lower(trim(spec.prompt))
    if starts(prompt, "no ") || contains(prompt, " no ") || contains(prompt, "without ") { fail("SFX prompts must positively describe only audible content: " ++ spec.id) }
    if spec.seconds < 0.5 || spec.seconds > 30.0 || spec.influence < 0.0 || spec.influence > 1.0 { fail("invalid generated SFX settings for " ++ spec.id) }
  })
  if Belt.Array.some(fixedAssets, asset => contains(lower(asset.id), "bell")) { fail("rejected bell-only train asset is still in the sound plan") }
  let seconds = generatedSfx->Belt.Array.reduce(0.0, (sum, spec) => sum +. spec.seconds)
  if Belt.Array.length(generatedSfx) > maxNewSfxRequests || seconds > maxNewSfxSeconds +. 0.001 { fail("generated train sound design exceeds hard paid ceilings") }
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
  addString(root, "schema", "amal.dialogue-segment-timings/v2")
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
    Some({id: spec.id, path, sha256: hash, duration, source: "ElevenLabs eleven_text_to_sound_v2"})
  }
}

let generatedSpecById = (id: string): generatedSfxSpec => switch Belt.Array.getBy(generatedSfx, (spec: generatedSfxSpec) => spec.id == id) {
| Some(spec) => spec
| None => fail("unknown generated sound " ++ id)
}

let audioAssetFor = (id: string): audioAsset => switch Belt.Array.getBy(fixedAssets, (asset: fixedAsset) => asset.id == id) {
| Some(asset) => {id: asset.id, path: asset.path, sha256: asset.sha256, duration: asset.duration, source: asset.source}
| None => {
    let spec = generatedSpecById(id)
    switch verifySfxCache(spec) {
    | Some(asset) => asset
    | None => {id: spec.id, path: sfxRawPath(spec), sha256: sfxRequestHash(spec), duration: spec.seconds, source: "planned ElevenLabs eleven_text_to_sound_v2 request"}
    }
  }
}

let wordsIn = value => value->compact == "" ? 0 : value->compact->Js.String2.split(" ")->Belt.Array.length
let estimateLineDuration = (row: dialogueLine) => floatMax(0.75, Belt.Int.toFloat(wordsIn(row.text)) /. 2.15)
let estimateSegmentDuration = (segment: dialogueSegment) => segment.lines->Belt.Array.reduce(0.0, (sum, row) => sum +. estimateLineDuration(row) +. 0.12)

let buildEstimatedTimeline = (): timelineBuild => {
  let turns: array<Core.turnWindow> = []
  let placements: array<segmentPlacement> = []
  let cursor = ref(initialLead)
  segments->Belt.Array.forEach(segment => {
    let local = ref(0.0)
    segment.lines->Belt.Array.forEach(row => {
      let start = cursor.contents +. local.contents
      let end_ = start +. estimateLineDuration(row)
      Js.Array2.push(turns, {id: row.id, start, end_})->ignore
      local := local.contents +. estimateLineDuration(row) +. 0.12
    })
    let duration = floatMax(local.contents, estimateSegmentDuration(segment))
    Js.Array2.push(placements, {segmentId: segment.id, path: dialogueRawPath(segment), start: cursor.contents, duration})->ignore
    cursor := cursor.contents +. duration +. segment.gapAfter
  })
  {turns, placements, masterDuration: cursor.contents +. reviewTail}
}

let buildActualTimeline = (caches: array<segmentCache>): timelineBuild => {
  let turns: array<Core.turnWindow> = []
  let placements: array<segmentPlacement> = []
  let cursor = ref(initialLead)
  segments->Belt.Array.forEach(segment => {
    let cache: segmentCache = switch Belt.Array.getBy(caches, (item: segmentCache) => item.segmentId == segment.id) {
    | Some(value) => value
    | None => fail("actual timeline has no cache for " ++ segment.id)
    }
    cache.timings->Belt.Array.forEach(row => Js.Array2.push(turns, {
      id: row.id,
      start: cursor.contents +. row.start,
      end_: cursor.contents +. row.end_,
    })->ignore)
    Js.Array2.push(placements, {segmentId: segment.id, path: cache.rawPath, start: cursor.contents, duration: cache.duration})->ignore
    cursor := cursor.contents +. cache.duration +. segment.gapAfter
  })
  {turns, placements, masterDuration: cursor.contents +. reviewTail}
}

let continuousCues = (~masterDuration: float, ~prefix: string, ~assetId: string, ~sourceSeconds: float, ~crossfade: float, ~gainDb: float): array<Core.clipCue> => {
  let rows: array<Core.clipCue> = []
  let start = ref(0.0)
  let index = ref(1)
  while start.contents < masterDuration -. 0.01 {
    let duration = floatMin(sourceSeconds, masterDuration -. start.contents)
    if duration < 0.45 { start := masterDuration } else {
      let fade = floatMin(crossfade, duration /. 3.0)
      Js.Array2.push(rows, {
        id: prefix ++ Belt.Int.toString(index.contents),
        assetId,
        mode: Core.Bed,
        anchor: Core.Absolute(start.contents),
        length: Core.Fixed(duration),
        trimStart: 0.0,
        gainDb,
        fadeIn: fade,
        fadeOut: fade,
      })->ignore
      start := start.contents +. sourceSeconds -. crossfade
      index := index.contents + 1
    }
  }
  rows
}

let cueSpecs = (~turns: array<Core.turnWindow>, ~masterDuration: float): array<Core.clipCue> => Belt.Array.concatMany([
  continuousCues(~masterDuration, ~prefix="B001_STEAM_RIDE_", ~assetId="steam_train_interior", ~sourceSeconds=30.0, ~crossfade=1.50, ~gainDb=-1.5),
  continuousCues(~masterDuration, ~prefix="B002_WALLA_", ~assetId="adult_passenger_walla", ~sourceSeconds=12.0, ~crossfade=1.20, ~gainDb=-9.0),
  continuousCues(~masterDuration, ~prefix="B003_FAN_", ~assetId="fan_rattle", ~sourceSeconds=52.0, ~crossfade=2.0, ~gainDb=-11.0),
  [
    {id: "T001_OPENING_DEPARTURE", assetId: "steam_train_station_cycle", mode: Core.Transition, anchor: Core.Absolute(0.0), length: Core.Fixed(14.0), trimStart: 14.0, gainDb: 0.5, fadeIn: 0.10, fadeOut: 0.80},
    {id: "T002_FIRST_ARRIVAL", assetId: "steam_train_station_cycle", mode: Core.Transition, anchor: Core.TurnStart("P01", -5.0), length: Core.Fixed(12.0), trimStart: 0.0, gainDb: 0.5, fadeIn: 0.30, fadeOut: 0.70},
    {id: "T003_FIRST_STEAM", assetId: "steam_hiss", mode: Core.Transition, anchor: Core.TurnStart("P01", -0.40), length: Core.Fixed(8.0), trimStart: 1.0, gainDb: -6.0, fadeIn: 0.20, fadeOut: 0.80},
    {id: "T004_FIRST_DEPARTURE", assetId: "steam_train_station_cycle", mode: Core.Transition, anchor: Core.TurnEnd("P08", 0.20), length: Core.Fixed(14.0), trimStart: 14.0, gainDb: 0.5, fadeIn: 0.20, fadeOut: 1.0},
    {id: "T005_SECOND_ARRIVAL", assetId: "steam_train_station_cycle", mode: Core.Transition, anchor: Core.TurnStart("E01", -5.0), length: Core.Fixed(12.0), trimStart: 0.0, gainDb: 0.5, fadeIn: 0.30, fadeOut: 0.70},
    {id: "T006_SECOND_STEAM", assetId: "steam_hiss", mode: Core.Transition, anchor: Core.TurnStart("E01", -0.40), length: Core.Fixed(11.0), trimStart: 0.0, gainDb: -6.0, fadeIn: 0.20, fadeOut: 0.80},
    {id: "T007_FINAL_DEPARTURE", assetId: "steam_train_station_cycle", mode: Core.Transition, anchor: Core.TurnStart("X04", 0.25), length: Core.Fixed(4.0), trimStart: 14.0, gainDb: 1.0, fadeIn: 0.15, fadeOut: 1.20},
    {id: "H001_LUGGAGE_JOLT", assetId: "metal_luggage_jolt", mode: Core.Hit, anchor: Core.TurnStart("O02", -0.10), length: Core.Fixed(1.40), trimStart: 4.0, gainDb: -13.0, fadeIn: 0.03, fadeOut: 0.30},
    {id: "H002_FLY_FIRST", assetId: "close_houseflies", mode: Core.Hit, anchor: Core.TurnStart("R01", -0.55), length: Core.Fixed(1.80), trimStart: 0.0, gainDb: -10.0, fadeIn: 0.10, fadeOut: 0.25},
    {id: "H003_FLY_CLOTH", assetId: "close_houseflies", mode: Core.Hit, anchor: Core.TurnStart("R07", 0.25), length: Core.Fixed(2.10), trimStart: 2.0, gainDb: -12.0, fadeIn: 0.10, fadeOut: 0.25},
    {id: "H004_CLOTH_TIGHTENS", assetId: "cloth_rustle", mode: Core.Hit, anchor: Core.TurnEnd("R07", 0.05), length: Core.Fixed(1.25), trimStart: 0.15, gainDb: -10.0, fadeIn: 0.03, fadeOut: 0.18},
    {id: "H005_FLY_DISTRACTS", assetId: "close_houseflies", mode: Core.Hit, anchor: Core.TurnStart("S01", -0.35), length: Core.Fixed(1.60), trimStart: 3.8, gainDb: -14.0, fadeIn: 0.08, fadeOut: 0.20},
    {id: "H006_STAND", assetId: "seat_scrape", mode: Core.Hit, anchor: Core.TurnEnd("S09", 0.05), length: Core.Fixed(1.35), trimStart: 0.20, gainDb: -12.0, fadeIn: 0.03, fadeOut: 0.22},
    {id: "H007_BUNDLE_TURNS", assetId: "heavy_fabric_move", mode: Core.Hit, anchor: Core.TurnEnd("S09", 0.38), length: Core.Fixed(1.55), trimStart: 2.0, gainDb: -10.0, fadeIn: 0.03, fadeOut: 0.25},
    {id: "H008_SIT", assetId: "seat_scrape", mode: Core.Hit, anchor: Core.TurnEnd("S10", 0.05), length: Core.Fixed(1.20), trimStart: 1.8, gainDb: -13.0, fadeIn: 0.03, fadeOut: 0.22},
    {id: "H009_PACKET", assetId: "wrapped_packets_spill", mode: Core.Hit, anchor: Core.TurnEnd("P03", 0.12), length: Core.Fixed(1.20), trimStart: 0.0, gainDb: -14.0, fadeIn: 0.02, fadeOut: 0.20},
    {id: "H010_FLY_HUDDLE", assetId: "close_houseflies", mode: Core.Hit, anchor: Core.TurnStart("H04", 0.30), length: Core.Fixed(2.10), trimStart: 1.0, gainDb: -12.0, fadeIn: 0.08, fadeOut: 0.24},
    {id: "H011_MEN_STEP_DOWN", assetId: "metal_footsteps", mode: Core.Hit, anchor: Core.TurnEnd("E02", 0.15), length: Core.Fixed(1.45), trimStart: 0.0, gainDb: -8.0, fadeIn: 0.02, fadeOut: 0.18},
    {id: "H012_TRUNK_LATCH", assetId: "metal_luggage_jolt", mode: Core.Hit, anchor: Core.TurnStart("E03", -0.25), length: Core.Fixed(1.15), trimStart: 8.0, gainDb: -13.0, fadeIn: 0.02, fadeOut: 0.20},
    {id: "H013_WOMAN_LEAVES", assetId: "metal_footsteps", mode: Core.Hit, anchor: Core.TurnEnd("E06", 0.18), length: Core.Fixed(1.45), trimStart: 0.0, gainDb: -7.0, fadeIn: 0.02, fadeOut: 0.15},
    {id: "H014_COACH_DOOR", assetId: "coach_door", mode: Core.Hit, anchor: Core.TurnEnd("E06", 0.75), length: Core.Fixed(2.30), trimStart: 0.20, gainDb: -10.0, fadeIn: 0.03, fadeOut: 0.25},
    {id: "H015_PURSUIT_STEPS", assetId: "metal_footsteps", mode: Core.Hit, anchor: Core.TurnEnd("E09", 0.30), length: Core.Fixed(1.45), trimStart: 0.0, gainDb: -6.0, fadeIn: 0.02, fadeOut: 0.12},
    {id: "H016_FALSE_REVEAL_CLOTH", assetId: "cloth_rustle", mode: Core.Hit, anchor: Core.TurnEnd("C07", 0.08), length: Core.Fixed(1.75), trimStart: 0.25, gainDb: -8.0, fadeIn: 0.03, fadeOut: 0.25},
    {id: "H017_FINAL_FLY", assetId: "close_houseflies", mode: Core.Hit, anchor: Core.TurnStart("C11", 0.20), length: Core.Fixed(2.10), trimStart: 3.0, gainDb: -9.0, fadeIn: 0.08, fadeOut: 0.22},
    {id: "H018_GRAB_FABRIC", assetId: "heavy_fabric_move", mode: Core.Hit, anchor: Core.TurnStart("G01", -0.20), length: Core.Fixed(1.65), trimStart: 5.0, gainDb: -6.0, fadeIn: 0.02, fadeOut: 0.18},
    {id: "H019_TEAR", assetId: "fabric_tear", mode: Core.Hit, anchor: Core.TurnEnd("G01", 0.18), length: Core.Fixed(0.90), trimStart: 0.0, gainDb: -5.0, fadeIn: 0.01, fadeOut: 0.10},
    {id: "H020_BODY_AND_PACKETS", assetId: "wrapped_packets_spill", mode: Core.Hit, anchor: Core.TurnEnd("G01", 0.55), length: Core.Fixed(2.35), trimStart: 2.0, gainDb: -5.0, fadeIn: 0.02, fadeOut: 0.20},
  ],
])

let resolveCues = (~turns: array<Core.turnWindow>, ~masterDuration: float): (array<Core.resolvedClip>, float) => {
  let clips = cueSpecs(~turns, ~masterDuration)->Belt.Array.map(spec => Core.resolveClip(~turns, ~masterDuration, spec))
  clips->Belt.Array.forEachWithIndex((index, clip) => {
    if index > 0 && Belt.Array.some(Js.Array2.slice(clips, ~start=0, ~end_=index), prior => prior.spec.id == clip.spec.id) { fail("duplicate cue id " ++ clip.spec.id) }
    let asset = audioAssetFor(clip.spec.assetId)
    if clip.spec.trimStart +. clip.end_ -. clip.start > asset.duration +. 0.02 { fail("cue " ++ clip.spec.id ++ " exceeds source " ++ asset.id) }
  })
  let steam = clips->Belt.Array.keep(clip => clip.spec.assetId == "steam_train_interior")
  turns->Belt.Array.forEach(turn => {
    let covered = steam->Belt.Array.reduce(0.0, (sum, clip) => sum +. Core.intersection(~aStart=turn.start, ~aEnd=turn.end_, ~bStart=clip.start, ~bEnd=clip.end_))
    if covered +. 0.02 < turn.end_ -. turn.start { fail("steam-train bed does not cover dialogue " ++ turn.id) }
  })
  (clips, 1.0)
}

let anchorSignature = anchor => switch anchor {
| Core.Absolute(seconds) => "absolute:" ++ Js.Float.toString(seconds)
| Core.TurnStart(id, offset) => "turn-start:" ++ id ++ ":" ++ Js.Float.toString(offset)
| Core.TurnEnd(id, offset) => "turn-end:" ++ id ++ ":" ++ Js.Float.toString(offset)
}

let lengthSignature = length => switch length {
| Core.Fixed(seconds) => "fixed:" ++ Js.Float.toString(seconds)
| Core.ToEnd(before) => "to-end:" ++ Js.Float.toString(before)
}

let cueSignature = (spec: Core.clipCue) => Js.Array2.joinWith([
  spec.id, spec.assetId, Core.modeName(spec.mode), anchorSignature(spec.anchor), lengthSignature(spec.length),
  Js.Float.toString(spec.trimStart), Js.Float.toString(spec.gainDb), Js.Float.toString(spec.fadeIn), Js.Float.toString(spec.fadeOut),
], "|")

let missingDialogueSegments = () => segments->Belt.Array.keep(segment => verifyDialogueCache(segment) == None)
let missingGeneratedSfx = () => generatedSfx->Belt.Array.keep(spec => verifySfxCache(spec) == None)

let planSignature = (~estimated: timelineBuild, ~missingDialogue: array<dialogueSegment>, ~missingSfx: array<generatedSfxSpec>): string => Js.Array2.joinWith([
  pipelineVersion,
  assemblyVersion,
  approvedScriptSha256,
  castSignature(),
  segments->Belt.Array.map(segment => dialogueRequestSignature(segment) ++ "|gap=" ++ Js.Float.toString(segment.gapAfter))->Js.Array2.joinWith("||||"),
  generatedSfx->Belt.Array.map(sfxRequestSignature)->Js.Array2.joinWith("||||"),
  fixedAssets->Belt.Array.map(asset => asset.id ++ "=" ++ asset.sha256)->Js.Array2.joinWith("|"),
  cueSpecs(~turns=estimated.turns, ~masterDuration=estimated.masterDuration)->Belt.Array.map(cueSignature)->Js.Array2.joinWith("||"),
  "missing_dialogue=" ++ missingDialogue->Belt.Array.map(dialogueRequestHash)->Js.Array2.joinWith("|"),
  "missing_sfx=" ++ missingSfx->Belt.Array.map(sfxRequestHash)->Js.Array2.joinWith("|"),
  "initial=" ++ Js.Float.toString(initialLead),
  "tail=" ++ Js.Float.toString(reviewTail),
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
  Js.Json.object_(root)
}

let segmentJson = (segment: dialogueSegment) => {
  let root = Js.Dict.empty()
  addString(root, "id", segment.id)
  addString(root, "purpose", segment.purpose)
  addNumber(root, "seed", Belt.Int.toFloat(segment.seed))
  addNumber(root, "characters", Belt.Int.toFloat(segmentCharacters(segment)))
  addNumber(root, "gap_after_seconds", segment.gapAfter)
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

let fixedJson = (asset: fixedAsset) => {
  let root = Js.Dict.empty()
  addString(root, "id", asset.id)
  addString(root, "path", asset.path)
  addString(root, "sha256", asset.sha256)
  addNumber(root, "duration_seconds", asset.duration)
  addString(root, "source", asset.source)
  Js.Json.object_(root)
}

let writePlan = (~estimated: timelineBuild, ~overlap: float, ~missingDialogue: array<dialogueSegment>, ~missingSfx: array<generatedSfxSpec>): string => {
  let signature = planSignature(~estimated, ~missingDialogue, ~missingSfx)
  let planHash = sha256Text(signature)
  let path = planDir ++ "/AMAL_TRAIN_AUDIO_DRAMA_V2_PLAN_" ++ shortHash(planHash) ++ ".json"
  ensureDirPath(Path(planDir))
  let missingDialogueChars = missingDialogue->Belt.Array.reduce(0, (sum, segment) => sum + segmentCharacters(segment))
  let missingSfxSeconds = missingSfx->Belt.Array.reduce(0.0, (sum, spec) => sum +. spec.seconds)
  let root = Js.Dict.empty()
  addString(root, "schema", "amal.train-audio-drama-plan/v2")
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "assembly_version", assemblyVersion)
  addString(root, "canonical_script", scriptPath)
  addString(root, "canonical_script_sha256", approvedScriptSha256)
  addString(root, "plan_sha256", planHash)
  addString(root, "scope", "Complete narrator-free train cold open through the opium reveal and final scream.")
  addString(root, "dialogue_model", "ElevenLabs eleven_v3 Text to Dialogue with timestamps; Hindi language normalization; deterministic seed per movement.")
  addString(root, "sfx_model", "ElevenLabs eleven_text_to_sound_v2 for steam ride and station cycle; immutable proof SFX plus owned PSE foley for details.")
  addString(root, "mix_policy", "Steam engine, wheel rhythm, coach rattle, walla and fan remain continuous beneath dialogue; station sounds and foley overlap speech; voice-keyed sidechain ducking protects intelligibility.")
  addString(root, "performance_policy", "Suresh uses a newly cast warm, modulated middle-aged voice and an authored progression from teasing to gentle to distracted to whispered concern to controlled urgency.")
  addNumber(root, "estimated_master_seconds", estimated.masterDuration)
  addNumber(root, "estimated_ambience_overlap_fraction", overlap)
  addNumber(root, "missing_dialogue_requests", Belt.Int.toFloat(Belt.Array.length(missingDialogue)))
  addNumber(root, "missing_dialogue_characters", Belt.Int.toFloat(missingDialogueChars))
  addNumber(root, "maximum_new_dialogue_requests", Belt.Int.toFloat(maxNewDialogueRequests))
  addNumber(root, "maximum_new_dialogue_characters", Belt.Int.toFloat(maxNewDialogueCharacters))
  addNumber(root, "per_request_dialogue_character_ceiling", Belt.Int.toFloat(maxCharactersPerDialogueRequest))
  addNumber(root, "missing_sfx_requests", Belt.Int.toFloat(Belt.Array.length(missingSfx)))
  addNumber(root, "missing_sfx_seconds", missingSfxSeconds)
  addNumber(root, "estimated_sfx_credits_at_40_per_second", missingSfxSeconds *. 40.0)
  addString(root, "paid_gate", "PAID=1 plus the required GENERATE flag and APPROVED_PLAN_SHA256 equal to this exact plan; DRY=1 always wins.")
  Js.Dict.set(root, "cast", Js.Json.array(cast->Belt.Array.map(castJson)))
  Js.Dict.set(root, "dialogue_segments", Js.Json.array(segments->Belt.Array.map(segmentJson)))
  Js.Dict.set(root, "generated_sfx", Js.Json.array(generatedSfx->Belt.Array.map(sfxJson)))
  Js.Dict.set(root, "fixed_sound_assets", Js.Json.array(fixedAssets->Belt.Array.map(fixedJson)))
  let text = Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n"
  if exists(Path(path)) {
    if readText(Path(path)) != text { fail("content-addressed plan path contains different bytes") }
  } else if !writeTextExclusive(Path(path), text) { fail("could not publish content-addressed plan") }
  Js.log("PLAN -> " ++ path)
  Js.log("PLAN SHA-256 -> " ++ planHash)
  Js.log("MISSING DIALOGUE -> " ++ Belt.Int.toString(Belt.Array.length(missingDialogue)) ++ " requests / " ++ Belt.Int.toString(missingDialogueChars) ++ " characters")
  Js.log("MISSING SFX -> " ++ Belt.Int.toString(Belt.Array.length(missingSfx)) ++ " requests / " ++ Js.Float.toString(missingSfxSeconds) ++ " seconds / " ++ Js.Float.toString(missingSfxSeconds *. 40.0) ++ " credits")
  planHash
}

let requirePaidPlan = (~planHash: string, ~missingDialogue: array<dialogueSegment>, ~missingSfx: array<generatedSfxSpec>): unit => {
  let dialogueChars = missingDialogue->Belt.Array.reduce(0, (sum, segment) => sum + segmentCharacters(segment))
  let sfxSeconds = missingSfx->Belt.Array.reduce(0.0, (sum, spec) => sum +. spec.seconds)
  if Belt.Array.length(missingDialogue) > maxNewDialogueRequests || dialogueChars > maxNewDialogueCharacters || Belt.Array.length(missingSfx) > maxNewSfxRequests || sfxSeconds > maxNewSfxSeconds +. 0.001 { fail("missing provider work exceeds paid ceilings") }
  if envDry == Some("1") || envPaid != Some("1") { fail("paid generation is locked; require PAID=1 with DRY unset") }
  if Belt.Array.length(missingDialogue) > 0 && envGenerateDialogue != Some("1") { fail("missing dialogue requires GENERATE_DIALOGUE=1") }
  if Belt.Array.length(missingSfx) > 0 && envGenerateSfx != Some("1") { fail("missing SFX requires GENERATE_SFX=1") }
  if envApprovedPlan != Some(planHash) { fail("APPROVED_PLAN_SHA256 does not match exact missing-work plan") }
}

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
    if kind == "sfx" && envRecoverSystemBusySfx == Some(id) {
      let recoveryPath = claimDir ++ "/recovery_system_busy_" ++ id ++ "_" ++ hash ++ ".json"
      let recovery = Js.Dict.empty()
      addString(recovery, "pipeline_version", pipelineVersion)
      addString(recovery, "kind", kind)
      addString(recovery, "id", id)
      addString(recovery, "request_sha256", hash)
      addString(recovery, "reason", "One controlled retry after ElevenLabs returned HTTP 429 system_busy; captured request-id prefix e08376aaac413aa8700; the provider delivered no audio bytes.")
      addString(recovery, "policy", "This recovery receipt is exclusive. A second retry is blocked.")
      if !writeTextExclusive(Path(recoveryPath), Js.Json.stringifyWithSpace(Js.Json.object_(recovery), 1) ++ "\n") {
        fail("controlled system-busy recovery already consumed for " ++ id ++ "; refusing another retry")
      }
      Js.log("CONTROLLED SYSTEM-BUSY RECOVERY 1/1 -> " ++ id)
    } else {
      fail("paid attempt already claimed with missing cache: " ++ kind ++ " " ++ id)
    }
  }
}

let publishFetched = (~audio, ~extension, ~destination, ~label): float => {
  let scratch = tempDir("amal-train-v2-provider-")->pathString
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
    Js.log("PAID TEXT TO DIALOGUE -> " ++ segment.id ++ " / " ++ Belt.Int.toString(segmentCharacters(segment)) ++ " characters")
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

let renderAllDialogue = async (): array<segmentCache> => {
  await prepareCast()
  let caches: array<segmentCache> = []
  let index = ref(0)
  while index.contents < Belt.Array.length(segments) {
    let cache = await renderDialogueSegment(Belt.Array.getExn(segments, index.contents))
    Js.Array2.push(caches, cache)->ignore
    index := index.contents + 1
  }
  caches
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
        Js.log("PAID SFX -> " ++ spec.id ++ " / " ++ Js.Float.toString(spec.seconds) ++ " seconds")
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

let buildVoiceLane = (~placements: array<segmentPlacement>, ~masterDuration: float): string => {
  ensureDirPath(Path(mixDir))
  let config = "voice|nine-provider-safe-dialogue-movements|hi-normalized|seeded|48k-stereo|per-take-loudnorm=-19/-3/11"
  let fingerprint = sha256Text(Js.Array2.joinWith([
    assemblyVersion,
    config,
    Js.Float.toString(masterDuration),
    placements->Belt.Array.map(item => item.segmentId ++ "=" ++ sha256File(Path(item.path)) ++ "@" ++ Js.Float.toString(item.start))->Js.Array2.joinWith("||"),
  ], "###"))
  let path = mixDir ++ "/voice_" ++ shortHash(fingerprint) ++ ".wav"
  if !verifyDerivative(~path, ~fingerprint) {
    let scratch = tempDir("amal-train-v2-voice-")->pathString
    let temporary = scratch ++ "/voice.wav"
    let inputs = placements->Belt.Array.map(item => ["-i", item.path])->Belt.Array.concatMany
    let chains = placements->Belt.Array.mapWithIndex((index, item) =>
      "[" ++ Belt.Int.toString(index) ++ ":a]aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo," ++
      "highpass=f=55,loudnorm=I=-19:TP=-3:LRA=11,adelay=" ++ Belt.Int.toString(Belt.Float.toInt(item.start *. 1000.0)) ++ ":all=1[v" ++ Belt.Int.toString(index) ++ "]"
    )
    let labels = placements->Belt.Array.mapWithIndex((index, _) => "[v" ++ Belt.Int.toString(index) ++ "]")->Js.Array2.joinWith("")
    let graph = Js.Array2.joinWith(chains, ";") ++ ";anullsrc=r=48000:cl=stereo:d=" ++ Js.Float.toString(masterDuration) ++ "[clock];[clock]" ++ labels ++ "amix=inputs=" ++ Belt.Int.toString(Belt.Array.length(placements) + 1) ++ ":duration=first:normalize=0:dropout_transition=0,atrim=0:" ++ Js.Float.toString(masterDuration) ++ "[out]"
    ffmpeg(Belt.Array.concatMany([["-nostdin", "-v", "error", "-n"], inputs, ["-filter_complex", graph, "-map", "[out]", "-ar", "48000", "-ac", "2", "-c:a", "pcm_s24le", temporary]]))
    publishDerivative(~temporary, ~path, ~fingerprint, ~kind="assembled multi-movement dialogue voice lane")
  }
  path
}

let clipFingerprint = (clip: Core.resolvedClip) => {
  let asset = audioAssetFor(clip.spec.assetId)
  Js.Array2.joinWith([cueSignature(clip.spec), asset.sha256, Js.Float.toString(clip.start), Js.Float.toString(clip.end_)], "|")
}

let buildSfxLane = (~clips: array<Core.resolvedClip>, ~masterDuration: float): string => {
  ensureDirPath(Path(mixDir))
  let config = "sfx|steam-body-continuous|per-source-loudnorm=-25/-4/12|highpass28|48k-stereo|limit=.88"
  let fingerprint = sha256Text(Js.Array2.joinWith([
    assemblyVersion,
    config,
    Js.Float.toString(masterDuration),
    clips->Belt.Array.map(clipFingerprint)->Js.Array2.joinWith("||"),
  ], "###"))
  let path = mixDir ++ "/sfx_" ++ shortHash(fingerprint) ++ ".wav"
  if !verifyDerivative(~path, ~fingerprint) {
    let scratch = tempDir("amal-train-v2-sfx-")->pathString
    let temporary = scratch ++ "/sfx.wav"
    let inputs = clips->Belt.Array.map(clip => ["-i", audioAssetFor(clip.spec.assetId).path])->Belt.Array.concatMany
    let chains = clips->Belt.Array.mapWithIndex((index, clip) => {
      let duration = clip.end_ -. clip.start
      let fadeOutStart = duration -. clip.spec.fadeOut
      let fadeIn = clip.spec.fadeIn > 0.0 ? "afade=t=in:st=0:d=" ++ Js.Float.toString(clip.spec.fadeIn) ++ "," : ""
      let fadeOut = clip.spec.fadeOut > 0.0 ? "afade=t=out:st=" ++ Js.Float.toString(fadeOutStart) ++ ":d=" ++ Js.Float.toString(clip.spec.fadeOut) ++ "," : ""
      "[" ++ Belt.Int.toString(index) ++ ":a]atrim=start=" ++ Js.Float.toString(clip.spec.trimStart) ++ ":end=" ++ Js.Float.toString(clip.spec.trimStart +. duration) ++ ",asetpts=PTS-STARTPTS,aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo,highpass=f=28,loudnorm=I=-25:TP=-4:LRA=12," ++ fadeIn ++ fadeOut ++ "volume=" ++ Js.Float.toString(clip.spec.gainDb) ++ "dB,adelay=" ++ Belt.Int.toString(Belt.Float.toInt(clip.start *. 1000.0)) ++ ":all=1[c" ++ Belt.Int.toString(index) ++ "]"
    })
    let labels = clips->Belt.Array.mapWithIndex((index, _) => "[c" ++ Belt.Int.toString(index) ++ "]")->Js.Array2.joinWith("")
    let graph = Js.Array2.joinWith(chains, ";") ++ ";anullsrc=r=48000:cl=stereo:d=" ++ Js.Float.toString(masterDuration) ++ "[clock];[clock]" ++ labels ++ "amix=inputs=" ++ Belt.Int.toString(Belt.Array.length(clips) + 1) ++ ":duration=first:normalize=0:dropout_transition=0,alimiter=limit=0.88,atrim=0:" ++ Js.Float.toString(masterDuration) ++ "[out]"
    ffmpeg(Belt.Array.concatMany([["-nostdin", "-v", "error", "-n"], inputs, ["-filter_complex", graph, "-map", "[out]", "-ar", "48000", "-ac", "2", "-c:a", "pcm_s24le", temporary]]))
    publishDerivative(~temporary, ~path, ~fingerprint, ~kind="layered steam-train ambience and foley lane")
  }
  path
}

let buildSilentMusic = (~masterDuration: float): string => {
  ensureDirPath(Path(mixDir))
  let fingerprint = sha256Text(assemblyVersion ++ "|intentional-silent-music|" ++ Js.Float.toString(masterDuration))
  let path = mixDir ++ "/music_silent_" ++ shortHash(fingerprint) ++ ".wav"
  if !verifyDerivative(~path, ~fingerprint) {
    let scratch = tempDir("amal-train-v2-music-")->pathString
    let temporary = scratch ++ "/music.wav"
    ffmpeg(["-nostdin", "-v", "error", "-n", "-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo", "-t", Js.Float.toString(masterDuration), "-c:a", "pcm_s24le", temporary])
    publishDerivative(~temporary, ~path, ~fingerprint, ~kind="intentional silent music lane")
  }
  path
}

let buildMaster = (~voicePath: string, ~sfxPath: string, ~musicPath: string, ~masterDuration: float): (string, string, string) => {
  ensureDirPath(Path(reviewDir))
  let fingerprint = sha256Text(Js.Array2.joinWith([assemblyVersion, Core.masterMixConfig, Js.Float.toString(masterDuration), sha256File(Path(voicePath)), sha256File(Path(sfxPath)), sha256File(Path(musicPath))], "###"))
  let wavPath = mixDir ++ "/master_" ++ shortHash(fingerprint) ++ ".wav"
  if !verifyDerivative(~path=wavPath, ~fingerprint) {
    let scratch = tempDir("amal-train-v2-master-")->pathString
    let temporary = scratch ++ "/master.wav"
    ffmpeg(["-nostdin", "-v", "error", "-n", "-i", voicePath, "-i", sfxPath, "-i", musicPath, "-filter_complex", Core.masterMixGraph(~duration=masterDuration), "-map", "[out]", "-ar", "48000", "-ac", "2", "-c:a", "pcm_s24le", temporary])
    publishDerivative(~temporary, ~path=wavPath, ~fingerprint, ~kind="final WAV master")
  }
  let m4aFingerprint = sha256Text(fingerprint ++ "|" ++ sha256File(Path(wavPath)) ++ "|aac-256k-48k-stereo")
  let m4aPath = reviewDir ++ "/AMAL_THE_TRAIN_AUDIO_FIRST_V2_" ++ shortHash(m4aFingerprint) ++ ".m4a"
  if !verifyDerivative(~path=m4aPath, ~fingerprint=m4aFingerprint) {
    let scratch = tempDir("amal-train-v2-review-")->pathString
    let temporary = scratch ++ "/review.m4a"
    ffmpeg(["-nostdin", "-v", "error", "-n", "-i", wavPath, "-map", "0:a:0", "-map_metadata", "-1", "-c:a", "aac", "-b:a", "256k", "-ar", "48000", "-ac", "2", "-movflags", "+faststart", "-metadata", "title=AMAL — The Train — Audio-First Cold Open v2", temporary])
    publishDerivative(~temporary, ~path=m4aPath, ~fingerprint=m4aFingerprint, ~kind="review M4A")
  }
  (wavPath, m4aPath, fingerprint)
}

let analyzeLoudness = (path: string, label: string): loudnessStats => {
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

let finalQc = (~voicePath: string, ~sfxPath: string, ~wavPath: string, ~m4aPath: string, ~masterDuration: float): (loudnessStats, loudnessStats, loudnessStats, loudnessStats) => {
  let wavDuration = validateAudio(wavPath, "final WAV")
  let m4aDuration = validateAudio(m4aPath, "review M4A")
  if masterDuration < 180.0 || masterDuration > 420.0 { fail("complete train scene runtime is outside honest 3–7 minute envelope") }
  if Js.Math.abs_float(wavDuration -. masterDuration) > 0.10 || Js.Math.abs_float(m4aDuration -. masterDuration) > 0.10 { fail("final duration QC failed") }
  let silence = run(~cmd="ffmpeg", ~args=["-nostdin", "-hide_banner", "-i", wavPath, "-af", "silencedetect=noise=-55dB:d=2.5", "-f", "null", "-"])
  if silence.stderr->Js.String2.split("\n")->Belt.Array.some(row => contains(row, "silence_duration:")) { fail("continuous train scene contains unintended silence longer than 2.5 seconds") }
  let voiceStats = analyzeLoudness(voicePath, "voice lane")
  let sfxStats = analyzeLoudness(sfxPath, "SFX lane")
  if sfxStats.integrated > voiceStats.integrated -. 2.0 { fail("unducked SFX lane is too close to dialogue loudness") }
  if sfxStats.integrated < voiceStats.integrated -. 14.0 { fail("steam-train body is too faint before sidechain") }
  let wavStats = analyzeLoudness(wavPath, "WAV")
  let m4aStats = analyzeLoudness(m4aPath, "M4A")
  if wavStats.integrated < -16.8 || wavStats.integrated > -15.2 || wavStats.truePeak > -1.5 { fail("WAV loudness or peak QC failed") }
  if m4aStats.integrated < -16.8 || m4aStats.integrated > -15.2 || m4aStats.truePeak > -1.0 { fail("M4A loudness or peak QC failed") }
  if m4aStats.lra < 2.0 || m4aStats.lra > 15.0 { fail("M4A loudness range QC failed") }
  Js.log("QC PASS -> " ++ Js.Float.toString(masterDuration) ++ " seconds / " ++ Js.Float.toString(m4aStats.integrated) ++ " LUFS / " ++ Js.Float.toString(m4aStats.truePeak) ++ " dBTP / dry voice-to-SFX margin " ++ Js.Float.toString(voiceStats.integrated -. sfxStats.integrated) ++ " dB")
  (voiceStats, sfxStats, wavStats, m4aStats)
}

let writeMasterManifest = (~timeline: timelineBuild, ~clips: array<Core.resolvedClip>, ~overlap, ~planHash, ~voicePath, ~sfxPath, ~musicPath, ~wavPath, ~m4aPath, ~fingerprint, ~voiceStats, ~sfxStats, ~wavStats, ~m4aStats, ~newDialogueRequests, ~newSfxRequests, ~newSfxSeconds): string => {
  let path = projectDir ++ "/AMAL_TRAIN_AUDIO_DRAMA_V2_MASTER_" ++ shortHash(fingerprint) ++ ".manifest.json"
  let root = Js.Dict.empty()
  addString(root, "schema", "amal.train-audio-drama-master/v2")
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "assembly_version", assemblyVersion)
  addString(root, "canonical_script", scriptPath)
  addString(root, "canonical_script_sha256", approvedScriptSha256)
  addString(root, "plan_sha256", planHash)
  addString(root, "master_fingerprint_sha256", fingerprint)
  addString(root, "scope", "Complete narrator-free train cold open through the opium reveal and final scream.")
  addNumber(root, "duration_seconds", timeline.masterDuration)
  addNumber(root, "ambience_overlap_fraction", overlap)
  addString(root, "voice_lane", voicePath)
  addString(root, "voice_lane_sha256", sha256File(Path(voicePath)))
  addString(root, "sfx_lane", sfxPath)
  addString(root, "sfx_lane_sha256", sha256File(Path(sfxPath)))
  addString(root, "music_lane", musicPath)
  addString(root, "music_policy", "Intentional silence; this cold open is driven by diegetic train sound and performance.")
  addString(root, "master_wav", wavPath)
  addString(root, "master_wav_sha256", sha256File(Path(wavPath)))
  addString(root, "review_m4a", m4aPath)
  addString(root, "review_m4a_sha256", sha256File(Path(m4aPath)))
  addNumber(root, "voice_lane_lufs", voiceStats.integrated)
  addNumber(root, "sfx_lane_lufs", sfxStats.integrated)
  addNumber(root, "voice_to_sfx_margin_db", voiceStats.integrated -. sfxStats.integrated)
  addNumber(root, "wav_integrated_lufs", wavStats.integrated)
  addNumber(root, "wav_true_peak_dbtp", wavStats.truePeak)
  addNumber(root, "m4a_integrated_lufs", m4aStats.integrated)
  addNumber(root, "m4a_true_peak_dbtp", m4aStats.truePeak)
  addNumber(root, "m4a_lra_lu", m4aStats.lra)
  addNumber(root, "new_dialogue_requests", Belt.Int.toFloat(newDialogueRequests))
  addNumber(root, "new_sfx_requests", Belt.Int.toFloat(newSfxRequests))
  addNumber(root, "new_sfx_seconds", newSfxSeconds)
  Js.Dict.set(root, "cast", Js.Json.array(cast->Belt.Array.map(castJson)))
  Js.Dict.set(root, "dialogue_segments", Js.Json.array(segments->Belt.Array.map(segmentJson)))
  Js.Dict.set(root, "generated_sfx", Js.Json.array(generatedSfx->Belt.Array.map(sfxJson)))
  Js.Dict.set(root, "fixed_sound_assets", Js.Json.array(fixedAssets->Belt.Array.map(fixedJson)))
  Js.Dict.set(root, "resolved_cues", Js.Json.array(clips->Belt.Array.map((clip: Core.resolvedClip) => {
    let row = Js.Dict.empty()
    addString(row, "id", clip.spec.id)
    addString(row, "asset_id", clip.spec.assetId)
    addNumber(row, "start_seconds", clip.start)
    addNumber(row, "end_seconds", clip.end_)
    addNumber(row, "gain_db", clip.spec.gainDb)
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
  validateFixedAssets()
  validateSfxDesign()

  let missingDialogue = missingDialogueSegments()
  let missingSfx = missingGeneratedSfx()
  let newDialogueRequests = Belt.Array.length(missingDialogue)
  let newSfxRequests = Belt.Array.length(missingSfx)
  let newSfxSeconds = missingSfx->Belt.Array.reduce(0.0, (sum, spec) => sum +. spec.seconds)
  let estimated = buildEstimatedTimeline()
  let (_, estimatedOverlap) = resolveCues(~turns=estimated.turns, ~masterDuration=estimated.masterDuration)
  let planHash = writePlan(~estimated, ~overlap=estimatedOverlap, ~missingDialogue, ~missingSfx)

  if envDry == Some("1") {
    Js.log("DRY PASS — complete source, relationship orientation, performance arc, cast, provider-safe segmentation, steam-train sound plan, fixed assets, exact missing work and paid ceilings validated; zero paid calls.")
  } else {
    if Belt.Array.length(missingDialogue) > 0 || Belt.Array.length(missingSfx) > 0 { requirePaidPlan(~planHash, ~missingDialogue, ~missingSfx) }
    let caches = await renderAllDialogue()
    await renderGeneratedSfx()
    let timeline = buildActualTimeline(caches)
    let (clips, overlap) = resolveCues(~turns=timeline.turns, ~masterDuration=timeline.masterDuration)
    let voicePath = buildVoiceLane(~placements=timeline.placements, ~masterDuration=timeline.masterDuration)
    let sfxPath = buildSfxLane(~clips, ~masterDuration=timeline.masterDuration)
    let musicPath = buildSilentMusic(~masterDuration=timeline.masterDuration)
    let (wavPath, m4aPath, fingerprint) = buildMaster(~voicePath, ~sfxPath, ~musicPath, ~masterDuration=timeline.masterDuration)
    let (voiceStats, sfxStats, wavStats, m4aStats) = finalQc(~voicePath, ~sfxPath, ~wavPath, ~m4aPath, ~masterDuration=timeline.masterDuration)
    let manifest = writeMasterManifest(~timeline, ~clips, ~overlap, ~planHash, ~voicePath, ~sfxPath, ~musicPath, ~wavPath, ~m4aPath, ~fingerprint, ~voiceStats, ~sfxStats, ~wavStats, ~m4aStats, ~newDialogueRequests, ~newSfxRequests, ~newSfxSeconds)
    Js.log("MASTER WAV -> " ++ wavPath)
    Js.log("REVIEW M4A -> " ++ m4aPath)
    Js.log("MANIFEST -> " ++ manifest)
  }
}

main()
->Js.Promise2.catch(error => {
  Js.log2("AMAL TRAIN AUDIO DRAMA V2 FAILED:", error)
  exit(1)
  Js.Promise.resolve()
})
->ignore
