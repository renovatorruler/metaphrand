/* Episode 9 future-dream cold-open audio plan and guarded renderer.

   The 120-second picture is already locked. This file deliberately excludes the
   obsolete narrated table read: the finished scene has character dialogue,
   effects and score, but no narrator.

   Safe/default commands (no paid provider call):
     node src/Kuku_Ep9ColdOpenAudio.res.mjs
     MODE=plan node src/Kuku_Ep9ColdOpenAudio.res.mjs
     CAST_APPROVED=1 MODE=mix node src/Kuku_Ep9ColdOpenAudio.res.mjs

   Paid commands require BOTH explicit gates. Setting only one gate fails before
   an ElevenLabs function can be reached:
     PAID=1 GENERATE=1 MODE=preview node src/Kuku_Ep9ColdOpenAudio.res.mjs
     PAID=1 GENERATE=1 CAST_APPROVED=1 MODE=render node src/Kuku_Ep9ColdOpenAudio.res.mjs

   `preview` renders five actual final lines in the established child cast. It
   checks future-scene performance and timing; it is not a recasting audition.
   If those performances are accepted,
   `render` reuses the cached takes instead of buying them again. `render` writes
   a content-addressed timed dialogue stem and never overwrites the picture or
   published full mix.
*/

open Cinema_Backends

@val @scope(("process", "env")) external envMode: option<string> = "MODE"
@val @scope(("process", "env")) external envPaid: option<string> = "PAID"
@val @scope(("process", "env")) external envGenerate: option<string> = "GENERATE"
@val @scope(("process", "env")) external envCastApproved: option<string> = "CAST_APPROVED"
@val @scope(("process", "env")) external envDry: option<string> = "DRY"
@val @scope("process") external exit: int => unit = "exit"

exception ColdOpenAudio(string)

let dir = "../stories/kuku/ep9prod/coldopen"
let audioDir = dir ++ "/audio"
let cacheDir = audioDir ++ "/cache"
let outDir = audioDir ++ "/out"
let newSfxDir = audioDir ++ "/sfx"
let providerReceiptPath = audioDir ++ "/EP9_COLD_OPEN_HIGGSFIELD_AUDIO_BATCH_V2.receipt.json"
let planPath = audioDir ++ "/coldopen_audio_plan_v1.json"
let rawScorePath = audioDir ++ "/score/EP9_COLD_OPEN_SCORE_SONILO_SIEGE_V2.m4a"
let duration = 120.0
let pipelineVersion = "ep9-cold-open-audio-v3"
let previewMixConfig = "concat-mono-mp3-96k-gap900ms-v1"
let dialogueMixConfig =
  "per-line-loudnorm-I-17-TP-1.5-LRA11|absolute-120s-silence-anchor|delay-editorial-at|amix-raw|stereo-44100-wav-v2"
let sfxMixConfig =
  "frame-audited-cues|per-cue-filter-and-gain|amix-raw|master-volume-0.70|limiter-0.85|stereo-44100-wav-v3"
let scoreMixConfig =
  "sonilo-siege-v2|loudnorm-I-23-TP-2-LRA12|local-low-siege-reinforcement-open-shield-end-v2|no-baked-dialogue-duck|absolute-hard-stop-113|stereo-44100-wav"
let bedPreviewMixConfig = "score-plus-generated-and-repository-sfx|amix-raw|limiter-0.84|stereo-44100-aac192-v2"
let fullPreviewMixConfig =
  "approved-dialogue-plus-score-sfx|dialogue-sidechain-duck|amix-raw|limiter-0.78-no-makeup|sync-audit-v1|stereo-44100-aac192|video-copy-v5"

type actionMarker = {
  id: string,
  at: float,
  shot: string,
  visibleAction: string,
}

/* These are picture facts, audited against the locked 24 fps cut. Dialogue and
   effects are attached to these facts rather than guessed from prose. */
let actionMarkers: array<actionMarker> = [
  {id: "CITY_RAIDER_FIRE", at: 1.542, shot: "co01", visibleAction: "first raider releases fire over the city"},
  {id: "CIVILIANS_RUNNING_ON_BRIDGE", at: 7.00, shot: "co02", visibleAction: "families are visibly running across the bridge"},
  {id: "BRIDGE_RAIDER_FIRE_CHARGE", at: 10.25, shot: "co02", visibleAction: "bridge raider visibly charges a violet-black blast"},
  {id: "BRIDGE_RAIDER_FIRE_RELEASE", at: 10.375, shot: "co02", visibleAction: "bridge raider releases the violet-black blast"},
  {id: "RAIDER_BARRAGE_ENTERS", at: 27.10, shot: "co05", visibleAction: "incoming raider fireballs enter above the bridge"},
  {id: "FYURIA_FIRE_SPLIT", at: 29.250, shot: "co05", visibleAction: "Fyuria begins a controlled fire jet"},
  {id: "COMMANDER_FIRE_CLASH_ONE_CHARGE", at: 39.75, shot: "co06", visibleAction: "commander's throat and cracks charge before the clash"},
  {id: "COMMANDER_FIRE_CLASH_ONE", at: 40.083, shot: "co06", visibleAction: "commander releases fire at close range"},
  {id: "FYURIA_FIRE_CLASH_ONE", at: 40.292, shot: "co06", visibleAction: "Fyuria releases her counter-fire"},
  {id: "FYURIA_FIRE_CLASH_TWO", at: 44.000, shot: "co07", visibleAction: "Fyuria begins the second fire clash"},
  {id: "COMMANDER_FIRE_CLASH_TWO", at: 44.083, shot: "co07", visibleAction: "commander releases purple fire into the second clash"},
  {id: "MAIN_PIN_RELEASE", at: 48.083, shot: "co07", visibleAction: "the concealed support pin begins moving and debris releases"},
  {id: "RELEASED_BEAM_SPLASH", at: 49.40, shot: "co07", visibleAction: "the released beam and debris strike the river"},
  {id: "FYURIA_CATCHES_BRIDGE", at: 50.417, shot: "co08", visibleAction: "Fyuria takes the bridge weight and landing dust rises"},
  {id: "VESPER_CURRENT_PREREVEAL", at: 55.458, shot: "co08/co09", visibleAction: "Vesper's current begins before his full city reveal"},
  {id: "VESPER_CURRENT_REVEAL", at: 56.00, shot: "co09", visibleAction: "Vesper's blue current enters the burning city"},
  {id: "RAIDER_FIRES_AT_VESPER", at: 59.833, shot: "co09", visibleAction: "a raider releases fire toward Vesper's current"},
  {id: "RAIDER_CURRENT_IMPACT", at: 60.00, shot: "co09", visibleAction: "raider fire hits Vesper's current"},
  {id: "CURRENT_BRIDGE_LOAD_EDITORIAL", at: 70.20, shot: "co10", visibleAction: "editorial bridge-load cue; no single discrete transfer frame is visible"},
  {id: "LEDA_CASTOR_ARRIVE", at: 71.00, shot: "co11", visibleAction: "Leda and Castor enter the repair run"},
  {id: "LEDA_FINDS_PIN", at: 75.00, shot: "co11", visibleAction: "Leda isolates the pin inside the cracked tower"},
  {id: "CASTOR_SHRINKS", at: 79.60, shot: "co12", visibleAction: "Castor compresses to enter the crack"},
  {id: "CASTOR_REGROWS", at: 83.833, shot: "co12", visibleAction: "Castor visibly regrows inside the mechanism"},
  {id: "CASTOR_BRACES_BAR", at: 85.00, shot: "co12", visibleAction: "Castor braces and pushes the metal bar"},
  {id: "PIN_LOCK_EDITORIAL", at: 86.40, shot: "co12", visibleAction: "editorial lock cue; the picture does not expose a single snap frame"},
  {id: "BRIDGE_RESOLVED_CUT", at: 87.00, shot: "co13", visibleAction: "the cut reveals the bridge already restored"},
  {id: "FAMILIES_RESUME_CROSSING", at: 88.292, shot: "co13", visibleAction: "the first civilian visibly resumes crossing"},
  {id: "KUKU_SHIELD_CHARGE", at: 94.00, shot: "co14", visibleAction: "Kuku begins the golden shield breath and charge"},
  {id: "KUKU_GLYPH_APPEARS", at: 95.000, shot: "co14", visibleAction: "the golden construct and glyph first rise"},
  {id: "KUKU_SHIELD_SOLID", at: 98.375, shot: "co14", visibleAction: "the cut reveals the golden glyph shield standing solid"},
  {id: "COMMANDER_BREATHES_AT_SHIELD", at: 103.750, shot: "co15", visibleAction: "the commander launches black fire at the golden shield"},
  {id: "BLACK_FIRE_HITS_SHIELD", at: 104.00, shot: "co15", visibleAction: "black fire divides around the standing shield"},
  {id: "LARGER_ENEMY_SHADOW", at: 109.667, shot: "co16", visibleAction: "the larger enemy shadow fills the formation"},
  {id: "BEDROOM_CUT", at: 113.00, shot: "co17", visibleAction: "hard cut from battle to the bedroom"},
]

let marker = (id: string): float =>
  switch actionMarkers->Belt.Array.getBy(item => item.id == id) {
  | Some(item) => item.at
  | None => raise(ColdOpenAudio("unknown action marker: " ++ id))
  }

type voice = {
  key: string,
  character: string,
  performer: string,
  voiceId: string,
  status: string,
  reason: string,
}

let lockedCastVoice = (key: string): string =>
  switch Kuku_Cast.voiceOf(key) {
  | Some(voiceId) => voiceId
  | None => raise(ColdOpenAudio("missing locked Kuku cast voice: " ++ key))
  }

/* Future scale and mastery come from the picture and performance direction,
   not an adult recast. The familiar child voices are an identity anchor: the
   audience should recognize each dragon before anyone explains the dream. */
let voices: array<voice> = [
  {
    key: "NAGAR_RAKSHAK",
    character: "नगर-रक्षक",
    performer: "Shyam",
    voiceId: lockedCastVoice("NAGAR_RAKSHAK"),
    status: "locked-existing",
    reason: "Established episode casting; the guard is not Papa in story canon.",
  },
  {
    key: "FUTURE_FYURIA",
    character: "भविष्य की फ्यूरिया",
    performer: "Tarini",
    voiceId: lockedCastVoice("FYURIA"),
    status: "locked-existing",
    reason: "Same Furia voice; controlled battle performance signals future mastery without changing identity.",
  },
  {
    key: "FUTURE_VESPER",
    character: "भविष्य का वैस्पर",
    performer: "Mahira J",
    voiceId: lockedCastVoice("VESPER"),
    status: "locked-existing",
    reason: "Same Vesper voice; calm precision replaces sleepiness during the future battle.",
  },
  {
    key: "FUTURE_LEDA",
    character: "भविष्य की लेडा",
    performer: "Mini",
    voiceId: lockedCastVoice("LEDA"),
    status: "locked-existing",
    reason: "Same Leda voice; focused projection makes her recognizable while showing trained authority.",
  },
  {
    key: "FUTURE_CASTOR",
    character: "भविष्य का कैस्टर",
    performer: "Bittu",
    voiceId: lockedCastVoice("CASTOR"),
    status: "locked-existing",
    reason: "Same Castor voice; decisive timing carries competence without an adult vocal replacement.",
  },
  {
    key: "FUTURE_KUKU",
    character: "भविष्य का कुकु",
    performer: "Amit",
    voiceId: lockedCastVoice("KUKU"),
    status: "locked-existing",
    reason: "Same Kuku voice; reassurance and command rhythm show the future leader while preserving recognition.",
  },
  {
    key: "CHILD_FYURIA",
    character: "बच्ची फ्यूरिया",
    performer: "Tarini",
    voiceId: lockedCastVoice("FYURIA"),
    status: "locked-existing",
    reason: "The bedroom scene returns to the established present-day cast.",
  },
  {
    key: "DADI",
    character: "दादी",
    performer: "Gungun",
    voiceId: lockedCastVoice("DADI"),
    status: "locked-existing",
    reason: "Established Dadi identity.",
  },
]

type line = {
  id: string,
  character: string,
  voiceKey: string,
  at: float,
  end_: float,
  shot: string,
  tag: string,
  text: string,
  preview: bool,
}

/* Windows are editorial windows, not a request to make characters race. Any
   generated take that does not fit fails review; it is never time-stretched. */
let lines: array<line> = [
  {id: "L01", character: "नगर-रक्षक", voiceKey: "NAGAR_RAKSHAK", at: 7.3, end_: 12.2, shot: "co02", tag: "[urgent] [calling out loudly]", text: "आख़िरी पुल खुला है! सब लोग नदी पार कीजिए!", preview: false},
  {id: "L02", character: "भविष्य की फ्यूरिया", voiceKey: "FUTURE_FYURIA", at: 20.5, end_: 25.8, shot: "co04", tag: "[calm and commanding] [calling across a distance]", text: "पुल पार करते रहिए! मैं रास्ता खुला रखूँगी!", preview: true},
  {id: "L03", character: "भविष्य की फ्यूरिया", voiceKey: "FUTURE_FYURIA", at: 34.4, end_: 38.0, shot: "co06", tag: "[clear and commanding]", text: "सब लोग नीचे झुक जाइए!", preview: false},
  {id: "L04", character: "भविष्य की फ्यूरिया", voiceKey: "FUTURE_FYURIA", at: 50.2, end_: 55.5, shot: "co08", tag: "[straining] [clear and commanding]", text: "रस्सियाँ पकड़े रहिए! मैं पुल थामे हुए हूँ!", preview: false},
  {id: "L05", character: "भविष्य की फ्यूरिया", voiceKey: "FUTURE_FYURIA", at: 57.0, end_: 61.2, shot: "co09", tag: "[straining] [clear and commanding]", text: "वैस्पर—बाकी आग भी शहर से बाहर!", preview: false},
  {id: "L06", character: "भविष्य का वैस्पर", voiceKey: "FUTURE_VESPER", at: 62.5, end_: 68.5, shot: "co09/co10", tag: "[calm and precise]", text: "नीचे तीसरी धारा उठ रही है। पुल मेरे पीछे मोड़ो।", preview: true},
  {id: "L07", character: "भविष्य की फ्यूरिया", voiceKey: "FUTURE_FYURIA", at: 68.7, end_: 70.7, shot: "co10", tag: "[decisive]", text: "मोड़ रही हूँ।", preview: false},
  {id: "L08", character: "भविष्य की लेडा", voiceKey: "FUTURE_LEDA", at: 71.0, end_: 76.6, shot: "co11", tag: "[focused] [calling across a distance]", text: "दायाँ बुर्ज, तीसरी दरार। जंजीर ठीक है। कुंडी निकल गई है।", preview: true},
  {id: "L09", character: "भविष्य का कैस्टर", voiceKey: "FUTURE_CASTOR", at: 76.7, end_: 79.3, shot: "co11/co12", tag: "[decisive]", text: "मैं अंदर जा रहा हूँ।", preview: true},
  {id: "L10", character: "भविष्य की लेडा", voiceKey: "FUTURE_LEDA", at: 79.3, end_: 83.5, shot: "co12", tag: "[focused]", text: "आधा पंजा नीचे। अब बाईं ओर।", preview: false},
  {id: "L11", character: "भविष्य का कैस्टर", voiceKey: "FUTURE_CASTOR", at: 83.5, end_: 85.95, shot: "co12", tag: "[straining]", text: "कुंडी मिल गई।", preview: false},
  {id: "L12", character: "भविष्य की लेडा", voiceKey: "FUTURE_LEDA", at: 85.95, end_: 87.3, shot: "co12/co13", tag: "[sharply]", text: "अब!", preview: false},
  {id: "L13", character: "भविष्य का कुकु", voiceKey: "FUTURE_KUKU", at: 94.5, end_: 100.0, shot: "co14/co15", tag: "[reassuring] [projecting over noise]", text: "रास्ता अभी खुला है! आख़िरी परिवार नदी पार कीजिए!", preview: true},
  {id: "L14", character: "भविष्य की लेडा", voiceKey: "FUTURE_LEDA", at: 110.5, end_: 112.9, shot: "co16", tag: "[sharply]", text: "अब!", preview: false},
  {id: "L15", character: "बच्ची फ्यूरिया", voiceKey: "CHILD_FYURIA", at: 113.05, end_: 114.75, shot: "co17", tag: "[out of breath] [quietly]", text: "दादी—", preview: false},
  {id: "L16", character: "दादी", voiceKey: "DADI", at: 114.75, end_: 120.0, shot: "co17", tag: "[softly]", text: "सपना था, बेटी। तुम घर पर हो। मैं यहीं हूँ। सो जाओ।", preview: false},
]

type soundCue = {
  id: string,
  markerId: string,
  at: float,
  asset: string,
  gain: float,
  filter: string,
  bus: string,
  purpose: string,
}

let sfxPath = (name: string): string => newSfxDir ++ "/" ++ name

/* Four purpose-built assets are the only missing paid effects. Vesper, Leda,
   Castor and Kuku retain their established non-fire sonic identities. */
let soundCues: array<soundCue> = [
  {id: "S01", markerId: "OPENING", at: 0.0, asset: "../stories/kuku/ep8prod/sfx/mountain_wind_high.mp3", gain: 0.18, filter: "highpass=f=90:width_type=o:width=1", bus: "ambience", purpose: "high city wind and distance"},
  {id: "S02", markerId: "OPENING", at: 0.35, asset: "../stories/kuku/ep8prod/sfx/wingbeat_huge.mp3", gain: 0.58, filter: "lowpass=f=6500", bus: "action", purpose: "attackers descend into the siege"},
  {id: "S03", markerId: "CITY_RAIDER_FIRE", at: marker("CITY_RAIDER_FIRE"), asset: sfxPath("ash-crack-raider-black-fire.wav"), gain: 0.74, filter: "atrim=start=1.10:end=3.60,asetpts=PTS-STARTPTS,highpass=f=45", bus: "fire", purpose: "release-aligned coarse raider fire over the city"},
  {id: "S04", markerId: "BRIDGE_RAIDER_FIRE_RELEASE", at: marker("BRIDGE_RAIDER_FIRE_RELEASE"), asset: sfxPath("ash-crack-raider-black-fire.wav"), gain: 0.68, filter: "atrim=start=1.10:end=3.60,asetpts=PTS-STARTPTS,asetrate=44100*0.94,aresample=44100,highpass=f=45,afade=t=out:st=2.35:d=0.25", bus: "fire", purpose: "release-aligned lower-pitched raider fire beside fleeing families"},
  {id: "S05", markerId: "FYURIA_REVEAL", at: 12.65, asset: "../stories/kuku/ep8prod/sfx/wingbeat_huge.mp3", gain: 0.66, filter: "lowpass=f=7000", bus: "action", purpose: "adult Fyuria reveal"},
  {id: "S05B", markerId: "RAIDER_BARRAGE_ENTERS", at: marker("RAIDER_BARRAGE_ENTERS"), asset: sfxPath("ash-crack-raider-black-fire.wav"), gain: 0.58, filter: "atrim=start=1.10:end=3.60,asetpts=PTS-STARTPTS,asetrate=44100*1.06,aresample=44100,highpass=f=55,afade=t=out:st=2.1:d=0.3", bus: "fire", purpose: "release-aligned incoming raider fireball barrage"},
  {id: "S06", markerId: "FYURIA_FIRE_SPLIT", at: marker("FYURIA_FIRE_SPLIT"), asset: sfxPath("fyuria-controlled-fire.wav"), gain: 0.82, filter: "atrim=start=0.60:end=3.80,asetpts=PTS-STARTPTS,highpass=f=55,afade=t=out:st=2.9:d=0.3", bus: "fire", purpose: "release-aligned Fyuria controlled fire jet"},
  {id: "S07", markerId: "COMMANDER_FIRE_CLASH_ONE", at: marker("COMMANDER_FIRE_CLASH_ONE"), asset: sfxPath("commander-black-fire.wav"), gain: 0.78, filter: "atrim=start=0.65:end=3.35,asetpts=PTS-STARTPTS,highpass=f=40,afade=t=out:st=2.4:d=0.3", bus: "fire", purpose: "release-aligned commander pressure-blast against Fyuria"},
  {id: "S08", markerId: "FYURIA_FIRE_CLASH_ONE", at: marker("FYURIA_FIRE_CLASH_ONE"), asset: sfxPath("fyuria-controlled-fire.wav"), gain: 0.64, filter: "atrim=start=0.60:end=3.40,asetpts=PTS-STARTPTS,highpass=f=65", bus: "fire", purpose: "release-aligned Fyuria counter-fire"},
  {id: "S09", markerId: "COMMANDER_FIRE_CLASH_TWO", at: marker("COMMANDER_FIRE_CLASH_TWO"), asset: sfxPath("commander-black-fire.wav"), gain: 0.80, filter: "atrim=start=0.65:end=3.35,asetpts=PTS-STARTPTS,highpass=f=40,afade=t=out:st=2.4:d=0.3", bus: "fire", purpose: "release-aligned commander second blast"},
  {id: "S10", markerId: "FYURIA_FIRE_CLASH_TWO", at: marker("FYURIA_FIRE_CLASH_TWO"), asset: sfxPath("fyuria-controlled-fire.wav"), gain: 0.68, filter: "atrim=start=0.60:end=3.80,asetpts=PTS-STARTPTS,highpass=f=65", bus: "fire", purpose: "release-aligned Fyuria controlled counter-breath"},
  {id: "S11", markerId: "MAIN_PIN_RELEASE", at: marker("MAIN_PIN_RELEASE"), asset: "../stories/kuku/ep5prod/sfx/crack_kadak.mp3", gain: 0.88, filter: "highpass=f=65", bus: "action", purpose: "main support pin releases"},
  {id: "S12", markerId: "RELEASED_BEAM_SPLASH", at: marker("RELEASED_BEAM_SPLASH"), asset: "../stories/kuku/ep5prod/sfx/deck_tighten.mp3", gain: 0.54, filter: "areverse,lowpass=f=5000,atrim=0:1.5", bus: "action", purpose: "released beam and debris strike the river"},
  {id: "S13", markerId: "FYURIA_CATCHES_BRIDGE", at: marker("FYURIA_CATCHES_BRIDGE"), asset: "../stories/kuku/ep5prod/sfx/rope_creak.mp3", gain: 0.68, filter: "lowpass=f=5500", bus: "action", purpose: "Fyuria catches the bridge under strain"},
  {id: "S14", markerId: "VESPER_CURRENT_PREREVEAL", at: marker("VESPER_CURRENT_PREREVEAL"), asset: "../stories/kuku/ep8prod/sfx/tail_whoosh_miss.mp3", gain: 0.55, filter: "highpass=f=120", bus: "power", purpose: "Vesper's clean fast air turn leads his reveal"},
  {id: "S15", markerId: "VESPER_CURRENT_REVEAL", at: marker("VESPER_CURRENT_REVEAL") +. 0.50, asset: "../stories/kuku/ep5prod/sfx/wind_gust.mp3", gain: 0.34, filter: "highpass=f=140:width_type=o:width=1,lowpass=f=6500", bus: "power", purpose: "Vesper's sustained blue current"},
  {id: "S16", markerId: "RAIDER_FIRES_AT_VESPER", at: marker("RAIDER_FIRES_AT_VESPER"), asset: sfxPath("ash-crack-raider-black-fire.wav"), gain: 0.62, filter: "atrim=start=1.10:end=3.60,asetpts=PTS-STARTPTS,asetrate=44100*1.04,aresample=44100", bus: "fire", purpose: "release-aligned raider fire drawn into Vesper's current"},
  {id: "S17", markerId: "CURRENT_BRIDGE_LOAD_EDITORIAL", at: marker("CURRENT_BRIDGE_LOAD_EDITORIAL"), asset: "../stories/kuku/ep6prod/sfx/stream_bridge_ropes.mp3", gain: 0.36, filter: "highpass=f=75,lowpass=f=5500", bus: "action", purpose: "editorial air, river and bridge-load continuity cue"},
  {id: "S18", markerId: "LEDA_CASTOR_ARRIVE", at: marker("LEDA_CASTOR_ARRIVE"), asset: "../stories/kuku/ep8prod/sfx/wingbeat_huge.mp3", gain: 0.50, filter: "lowpass=f=6500,atrim=0:2.6", bus: "action", purpose: "Leda and Castor arrive"},
  {id: "S19", markerId: "LEDA_FINDS_PIN", at: marker("LEDA_FINDS_PIN"), asset: "../stories/kuku/ep8prod/sfx/glint_chime.mp3", gain: 0.38, filter: "highpass=f=450,atrim=0:1.1", bus: "power", purpose: "Leda precisely identifies the hidden pin"},
  {id: "S20", markerId: "CASTOR_SHRINKS", at: marker("CASTOR_SHRINKS"), asset: "../stories/kuku/ep8prod/sfx/tail_whoosh_miss.mp3", gain: 0.42, filter: "areverse,atempo=1.35,highpass=f=180,atrim=0:1.5", bus: "power", purpose: "Castor compresses inward while shrinking"},
  {id: "S21", markerId: "CASTOR_REGROWS", at: marker("CASTOR_REGROWS"), asset: "../stories/kuku/ep5prod/sfx/two_foot_thud.mp3", gain: 0.58, filter: "lowpass=f=3500", bus: "power", purpose: "Castor regrows against the mechanism"},
  {id: "S21B", markerId: "CASTOR_BRACES_BAR", at: marker("CASTOR_BRACES_BAR"), asset: "../stories/kuku/ep5prod/sfx/rope_creak.mp3", gain: 0.38, filter: "lowpass=f=3500,atrim=0:1.5", bus: "action", purpose: "Castor braces the bar under load"},
  {id: "S22", markerId: "PIN_LOCK_EDITORIAL", at: marker("PIN_LOCK_EDITORIAL"), asset: "../stories/kuku/ep5prod/sfx/letter_lock_stone.mp3", gain: 0.82, filter: "highpass=f=45,atrim=0:2.1", bus: "action", purpose: "editorial metal-and-stone lock resolution"},
  {id: "S23", markerId: "BRIDGE_RESOLVED_CUT", at: marker("BRIDGE_RESOLVED_CUT"), asset: "../stories/kuku/ep5prod/sfx/deck_tighten.mp3", gain: 0.52, filter: "lowpass=f=6000", bus: "action", purpose: "resolved bridge deck settles on the cut"},
  {id: "S24", markerId: "FAMILIES_RESUME_CROSSING", at: marker("FAMILIES_RESUME_CROSSING"), asset: "../stories/kuku/ep5prod/sfx/run_planks.mp3", gain: 0.34, filter: "highpass=f=80", bus: "action", purpose: "families visibly resume crossing"},
  {id: "S25", markerId: "KUKU_SHIELD_CHARGE", at: marker("KUKU_SHIELD_CHARGE"), asset: "../stories/kuku/ep8prod/sfx/sparks_forge.mp3", gain: 0.56, filter: "highpass=f=110", bus: "power", purpose: "Kuku's warm golden breath charges and knits the glyph"},
  {id: "S26", markerId: "KUKU_SHIELD_SOLID", at: marker("KUKU_SHIELD_SOLID"), asset: "../stories/kuku/ep6prod/sfx/forge_whoosh_land.mp3", gain: 0.42, filter: "atrim=0.9:4.2,asetpts=PTS-STARTPTS", bus: "power", purpose: "the golden glyph becomes a solid shield"},
  {id: "S27", markerId: "COMMANDER_BREATHES_AT_SHIELD", at: marker("COMMANDER_BREATHES_AT_SHIELD"), asset: sfxPath("commander-black-fire.wav"), gain: 0.84, filter: "atrim=start=0.65:end=3.35,asetpts=PTS-STARTPTS,highpass=f=40,afade=t=out:st=2.4:d=0.3", bus: "fire", purpose: "release-aligned commander black-fire breath at the shield"},
  {id: "S28", markerId: "BLACK_FIRE_HITS_SHIELD", at: marker("BLACK_FIRE_HITS_SHIELD"), asset: sfxPath("black-fire-golden-shield-impact.wav"), gain: 0.88, filter: "atrim=start=0:end=4.65,asetpts=PTS-STARTPTS,highpass=f=45,afade=t=out:st=4.25:d=0.40", bus: "action", purpose: "single black-fire impact splits around Kuku's golden shield"},
  {id: "S29", markerId: "LARGER_ENEMY_SHADOW", at: marker("LARGER_ENEMY_SHADOW"), asset: "../stories/kuku/ep8prod/sfx/wingbeat_huge.mp3", gain: 0.55, filter: "asetrate=44100*0.84,aresample=44100,lowpass=f=3000", bus: "action", purpose: "larger enemy shadow displaces the air"},
  {id: "S30", markerId: "BEDROOM_CUT", at: marker("BEDROOM_CUT"), asset: "../stories/kuku/ep4prod/sfx/hush_room.mp3", gain: 0.18, filter: "lowpass=f=7000", bus: "ambience", purpose: "hard cut to bedroom room tone"},
  {id: "S31", markerId: "BEDROOM_CUT", at: marker("BEDROOM_CUT") +. 0.50, asset: "../stories/kuku/ep4prod/sfx/towel_soft.mp3", gain: 0.25, filter: "highpass=f=90", bus: "action", purpose: "blanket and Dadi movement"},
  {id: "S32", markerId: "BEDROOM_CUT", at: marker("BEDROOM_CUT") +. 3.00, asset: "../stories/kuku/ep5prod/sfx/snore_soft_boy.mp3", gain: 0.10, filter: "lowpass=f=4500", bus: "ambience", purpose: "sleeping Vesper remains nearby"},
]

let directed = (line: line): string => line.tag ++ " " ++ line.text
let charCount = (value: string): int => Js.String2.length(value)
let round3 = (value: float): float => Js.Math.round(value *. 1000.0) /. 1000.0

let voiceFor = (key: string): voice =>
  switch voices->Belt.Array.getBy(voice => voice.key == key) {
  | Some(voice) => voice
  | None => raise(ColdOpenAudio("uncast voice key: " ++ key))
  }

let addString = (d: Js.Dict.t<Js.Json.t>, key: string, value: string): unit =>
  Js.Dict.set(d, key, Js.Json.string(value))

let addNumber = (d: Js.Dict.t<Js.Json.t>, key: string, value: float): unit =>
  Js.Dict.set(d, key, Js.Json.number(value))

let stringField = (json: Js.Json.t, key: string): option<string> =>
  json
  ->Js.Json.decodeObject
  ->Belt.Option.flatMap(object_ => Js.Dict.get(object_, key))
  ->Belt.Option.flatMap(Js.Json.decodeString)

let jsonVoice = (voice: voice): Js.Json.t => {
  let d = Js.Dict.empty()
  addString(d, "key", voice.key)
  addString(d, "character", voice.character)
  addString(d, "performer", voice.performer)
  addString(d, "voice_id", voice.voiceId)
  addString(d, "status", voice.status)
  addString(d, "reason", voice.reason)
  Js.Json.object_(d)
}

let jsonLine = (line: line): Js.Json.t => {
  let d = Js.Dict.empty()
  addString(d, "id", line.id)
  addString(d, "character", line.character)
  addString(d, "voice_key", line.voiceKey)
  addNumber(d, "at_seconds", line.at)
  addNumber(d, "end_seconds", line.end_)
  addNumber(d, "available_seconds", round3(line.end_ -. line.at))
  addString(d, "shot", line.shot)
  addString(d, "expression_tags", line.tag)
  addString(d, "spoken_text", line.text)
  addString(d, "directed_text", directed(line))
  Js.Dict.set(d, "directed_characters", Js.Json.number(Belt.Int.toFloat(charCount(directed(line)))))
  Js.Dict.set(d, "cast_preview", Js.Json.boolean(line.preview))
  Js.Json.object_(d)
}

let jsonSound = (cue: soundCue): Js.Json.t => {
  let d = Js.Dict.empty()
  addString(d, "id", cue.id)
  addString(d, "action_marker", cue.markerId)
  addNumber(d, "at_seconds", cue.at)
  addString(d, "asset", cue.asset)
  addNumber(d, "gain", cue.gain)
  addString(d, "filter", cue.filter)
  addString(d, "bus", cue.bus)
  addString(d, "purpose", cue.purpose)
  Js.Json.object_(d)
}

let jsonActionMarker = (item: actionMarker): Js.Json.t => {
  let d = Js.Dict.empty()
  addString(d, "id", item.id)
  addNumber(d, "at_seconds", item.at)
  addString(d, "shot", item.shot)
  addString(d, "visible_action", item.visibleAction)
  Js.Json.object_(d)
}

let requireProviderReceipt = (): unit => {
  if !exists(Path(providerReceiptPath)) {
    raise(ColdOpenAudio(
      "generated Higgsfield audio is missing its immutable batch receipt: " ++
      providerReceiptPath,
    ))
  }
  let receipt = Js.Json.parseExn(readText(Path(providerReceiptPath)))
  let expectedScore =
    stringField(receipt, "score_sha256")->Belt.Option.getWithDefault("")
  if expectedScore == "" || !exists(Path(rawScorePath)) ||
     sha256File(Path(rawScorePath)) != expectedScore {
    raise(ColdOpenAudio("replacement score bytes do not match the Higgsfield batch receipt"))
  }
  [
    ("fyuria_controlled_fire_sha256", sfxPath("fyuria-controlled-fire.wav")),
    ("ash_crack_raider_black_fire_sha256", sfxPath("ash-crack-raider-black-fire.wav")),
    ("commander_black_fire_sha256", sfxPath("commander-black-fire.wav")),
    ("black_fire_golden_shield_impact_sha256", sfxPath("black-fire-golden-shield-impact.wav")),
  ]->Belt.Array.forEach(((key, path)) => {
    let expected = stringField(receipt, key)->Belt.Option.getWithDefault("")
    if expected == "" || !exists(Path(path)) || sha256File(Path(path)) != expected {
      raise(ColdOpenAudio("generated effect bytes do not match their receipt: " ++ path))
    }
  })
}

let validate = (): unit => {
  if Belt.Array.length(lines) != 16 {
    raise(ColdOpenAudio("cold open must contain exactly 16 spoken lines"))
  }
  [
    ("FUTURE_FYURIA", "FYURIA"),
    ("FUTURE_VESPER", "VESPER"),
    ("FUTURE_LEDA", "LEDA"),
    ("FUTURE_CASTOR", "CASTOR"),
    ("FUTURE_KUKU", "KUKU"),
    ("CHILD_FYURIA", "FYURIA"),
  ]->Belt.Array.forEach(((sceneKey, castKey)) => {
    if voiceFor(sceneKey).voiceId != lockedCastVoice(castKey) {
      raise(ColdOpenAudio(
        sceneKey ++ " must use the original locked " ++ castKey ++
        " voice; future form may not silently recast the character",
      ))
    }
  })
  let previousEnd = ref(0.0)
  lines->Belt.Array.forEach(line => {
    ignore(voiceFor(line.voiceKey))
    if line.at < 0.0 || line.end_ > duration || line.end_ <= line.at {
      raise(ColdOpenAudio(line.id ++ " has an invalid editorial window"))
    }
    if line.at < previousEnd.contents {
      raise(ColdOpenAudio(line.id ++ " overlaps the preceding spoken line"))
    }
    if line.text == "" || !Js.String2.startsWith(line.tag, "[") {
      raise(ColdOpenAudio(line.id ++ " is missing text or Eleven v3 direction"))
    }
    previousEnd := line.end_
  })
  actionMarkers->Belt.Array.forEach(item => {
    if item.at < 0.0 || item.at >= duration || item.visibleAction == "" || item.shot == "" {
      raise(ColdOpenAudio(item.id ++ " has an invalid picture action marker"))
    }
  })
  if lines[0].at < marker("CIVILIANS_RUNNING_ON_BRIDGE") {
    raise(ColdOpenAudio("the bridge announcement begins before civilians are visible on the bridge"))
  }
  let missingGenerated: array<string> = []
  soundCues->Belt.Array.forEach(cue => {
    if cue.at < 0.0 || cue.at >= duration {
      raise(ColdOpenAudio(cue.id ++ " has an invalid start time"))
    }
    if !exists(Path(cue.asset)) {
      if Js.String2.startsWith(cue.asset, newSfxDir ++ "/") {
        if !(missingGenerated->Belt.Array.some(asset => asset == cue.asset)) {
          let _ = Js.Array2.push(missingGenerated, cue.asset)
        }
      } else {
        raise(ColdOpenAudio(cue.id ++ " is missing its required reused asset: " ++ cue.asset))
      }
    }
    if cue.markerId != "OPENING" && cue.markerId != "FYURIA_REVEAL" {
      ignore(marker(cue.markerId))
    }
  })
  if Belt.Array.length(missingGenerated) > 0 {
    Js.log(
      "audio plan is waiting for " ++ Belt.Int.toString(Belt.Array.length(missingGenerated)) ++
      " approved generated effect files; no generation was attempted",
    )
  }
}

let writePlan = (): (int, int) => {
  let finalChars = lines->Belt.Array.reduce(0, (n, line) => n + charCount(directed(line)))
  let previewChars =
    lines
    ->Belt.Array.keep(line => line.preview)
    ->Belt.Array.reduce(0, (n, line) => n + charCount(directed(line)))
  let root = Js.Dict.empty()
  addString(root, "version", pipelineVersion)
  addNumber(root, "picture_duration_seconds", duration)
  addString(root, "picture_policy", "locked; audio work must not regenerate or resize video")
  addString(root, "narrator", "none")
  addString(root, "paid_gate", "PAID=1 and GENERATE=1 are both required")
  addString(root, "cast_status", "future and present-day identities use the same locked child voices; preview checks performance and timing only")
  Js.Dict.set(root, "voices", Js.Json.array(voices->Belt.Array.map(jsonVoice)))
  Js.Dict.set(root, "dialogue", Js.Json.array(lines->Belt.Array.map(jsonLine)))
  Js.Dict.set(root, "action_markers", Js.Json.array(actionMarkers->Belt.Array.map(jsonActionMarker)))
  Js.Dict.set(root, "sound_cues", Js.Json.array(soundCues->Belt.Array.map(jsonSound)))
  Js.Dict.set(root, "final_directed_characters", Js.Json.number(Belt.Int.toFloat(finalChars)))
  Js.Dict.set(root, "preview_directed_characters", Js.Json.number(Belt.Int.toFloat(previewChars)))
  addString(root, "cost_note", "Character counts are request-size evidence, not a promise of provider billing or remaining quota.")
  addString(root, "score_arc", "threat; heroic promise; tactical trap; five-dragon solution; unresolved larger enemy; hard cut to a nearly silent bedroom")
  addString(root, "mix_policy", "dialogue target -17 LUFS; replacement siege score targets -23 LUFS; waveform-driven sidechain ducking preserves pressure between spoken words; decisive actions stay audible; phone and mono checks required")
  addString(root, "score_status", "replacement siege score required; old playful score is rejected and excluded by filename")
  addNumber(root, "approved_preflight_quote_credits", 9.9)
  addNumber(root, "actual_higgsfield_ledger_cost_credits", 18.1)
  addNumber(root, "provider_cost_quote_variance_credits", 8.2)
  addString(root, "provider_cost_note", "Higgsfield quoted 0.6 credit for each Seed Audio request before generation, but its completed transaction ledger charged 2.5/2.8/2.5/2.8 credits; no duplicate or retry was made")
  writeText(Path(planPath), Js.Json.stringifyWithSpace(Js.Json.object_(root), 1))
  (finalChars, previewChars)
}

type rendered = {line: line, file: string, seconds: float}

let requirePaidGate = (): unit => {
  if envDry == Some("1") {
    raise(ColdOpenAudio("DRY=1 forbids paid audio generation"))
  }
  if envPaid != Some("1") || envGenerate != Some("1") {
    raise(ColdOpenAudio(
      "paid audio is locked; PAID=1 and GENERATE=1 must both be explicitly set",
    ))
  }
}

let requireCastApproval = (): unit => {
  if envCastApproved != Some("1") {
    raise(ColdOpenAudio(
      "full dialogue is locked until the future-performance preview is heard and CAST_APPROVED=1 is set",
    ))
  }
}

let cachedTake = (line: line): string => {
  let voice = voiceFor(line.voiceKey)
  let signature = pipelineVersion ++ "|" ++ voice.voiceId ++ "|" ++ directed(line)
  cacheDir ++ "/" ++ line.id ++ "_" ++ sha256Text(signature) ++ ".mp3"
}

let requestFingerprintFor = (selected: array<line>): string =>
  sha256Text(
    pipelineVersion ++ "|" ++
    selected
    ->Belt.Array.map(line => {
      let voice = voiceFor(line.voiceKey)
      line.id ++ "|" ++ voice.voiceId ++ "|" ++ directed(line) ++ "|" ++
      Js.Float.toString(line.at) ++ "|" ++ Js.Float.toString(line.end_)
    })
    ->Js.Array2.joinWith("||"),
  )

let requestStampFor = (selected: array<line>): string =>
  Js.String2.slice(requestFingerprintFor(selected), ~from=0, ~to_=12)

let mixFingerprintFor = (~rows: array<rendered>, ~mixConfig: string): string =>
  sha256Text(
    pipelineVersion ++ "|" ++ mixConfig ++ "|" ++
    rows
    ->Belt.Array.map(row =>
      row.line.id ++ "|" ++ sha256File(Path(row.file)) ++ "|" ++
      Js.Float.toString(row.line.at) ++ "|" ++ Js.Float.toString(row.line.end_) ++ "|" ++
      Js.Float.toString(duration)
    )
    ->Js.Array2.joinWith("||"),
  )

let shortMixFingerprintFor = (~rows: array<rendered>, ~mixConfig: string): string =>
  Js.String2.slice(mixFingerprintFor(~rows, ~mixConfig), ~from=0, ~to_=12)

let renderLine = async (line: line): rendered => {
  let voice = voiceFor(line.voiceKey)
  let file = cachedTake(line)
  if !exists(Path(file)) {
    /* Lowest paid boundary: even an imported helper cannot call TTS without the
       same two explicit approvals used by the command-line entry point. */
    requirePaidGate()
    let audio = await tts(~text=Text(directed(line)), ~voice=VoiceId(voice.voiceId))
    let _ = writeBytes(Path(file), audio)
    Js.log(
      "paid take " ++ line.id ++ " completed (" ++
      Belt.Int.toString(charCount(directed(line))) ++ " directed characters)",
    )
  }
  let Seconds(seconds) = probeDuration(Path(file))
  {line, file, seconds}
}

let renderSelected = async (
  ~selected: array<line>,
  ~maxNewRequests: int,
  ~requireFit: bool,
): array<rendered> => {
  ensureDirPath(Path(cacheDir))
  let missing = selected->Belt.Array.keep(line => !exists(Path(cachedTake(line))))
  if Belt.Array.length(missing) > maxNewRequests {
    raise(ColdOpenAudio(
      "paid batch would need " ++ Belt.Int.toString(Belt.Array.length(missing)) ++
      " new requests; this mode is capped at " ++ Belt.Int.toString(maxNewRequests),
    ))
  }
  /* Existing preview takes are checked before a full-render request is allowed,
     preventing an already-known overflow from being followed by fresh spending. */
  if requireFit {
    let cachedOverflows: array<string> = []
    selected->Belt.Array.forEach(line => {
      let file = cachedTake(line)
      if exists(Path(file)) {
        let Seconds(seconds) = probeDuration(Path(file))
        if seconds > line.end_ -. line.at {
          let _ = Js.Array2.push(
            cachedOverflows,
            line.id ++ " " ++ Js.Float.toFixedWithPrecision(seconds, ~digits=2) ++
            "s/" ++ Js.Float.toFixedWithPrecision(line.end_ -. line.at, ~digits=2) ++ "s",
          )
        }
      }
    })
    if Belt.Array.length(cachedOverflows) > 0 {
      raise(ColdOpenAudio(
        "cached preview does not fit the picture: " ++
        Js.Array2.joinWith(cachedOverflows, ", ") ++
        "; revise it before authorizing more paid lines",
      ))
    }
  }
  Js.log(
    "paid batch ceiling: " ++ Belt.Int.toString(Belt.Array.length(missing)) ++
    " new requests / " ++
    Belt.Int.toString(missing->Belt.Array.reduce(0, (n, line) => n + charCount(directed(line)))) ++
    " directed characters",
  )
  let rows: array<rendered> = []
  for i in 0 to Belt.Array.length(selected) - 1 {
    switch Belt.Array.get(selected, i) {
    | Some(line) => {
        let row = await renderLine(line)
        /* Stop at the first newly discovered overflow. This prevents one bad
           paid take from being followed by avoidable provider requests. */
        if requireFit && row.seconds > row.line.end_ -. row.line.at {
          raise(ColdOpenAudio(
            "generated speech does not fit the picture: " ++ row.line.id ++ " " ++
            Js.Float.toFixedWithPrecision(row.seconds, ~digits=2) ++ "s/" ++
            Js.Float.toFixedWithPrecision(row.line.end_ -. row.line.at, ~digits=2) ++
            "s; stopped before requesting later lines",
          ))
        }
        let _ = Js.Array2.push(rows, row)
      }
    | None => ()
    }
  }
  rows
}

let rowsFromExistingCache = (selected: array<line>, label: string): array<rendered> =>
  selected->Belt.Array.map(line => {
    let file = cachedTake(line)
    if !exists(Path(file)) {
      raise(ColdOpenAudio(label ++ " is missing cached take " ++ line.id))
    }
    let Seconds(seconds) = probeDuration(Path(file))
    {line, file, seconds}
  })

let jsonRendered = (row: rendered): Js.Json.t => {
  let voice = voiceFor(row.line.voiceKey)
  let d = Js.Dict.empty()
  addString(d, "line_id", row.line.id)
  addString(d, "character", row.line.character)
  addString(d, "performer", voice.performer)
  addString(d, "voice_id", voice.voiceId)
  addString(d, "file", row.file)
  addString(d, "sha256", sha256File(Path(row.file)))
  addNumber(d, "duration_seconds", row.seconds)
  addNumber(d, "available_seconds", round3(row.line.end_ -. row.line.at))
  Js.Dict.set(d, "fits_picture_window", Js.Json.boolean(row.seconds <= row.line.end_ -. row.line.at))
  Js.Json.object_(d)
}

let soundFingerprint = (): string =>
  sha256Text(
    pipelineVersion ++ "|" ++ sfxMixConfig ++ "|" ++
    soundCues
    ->Belt.Array.map(cue =>
      cue.id ++ "|" ++ Js.Float.toString(cue.at) ++ "|" ++
      cue.markerId ++ "|" ++ Js.Float.toString(cue.gain) ++ "|" ++ cue.filter ++ "|" ++
      cue.bus ++ "|" ++ sha256File(Path(cue.asset))
    )
    ->Js.Array2.joinWith("||"),
  )

let currentSfxStemPath = (): string => {
  let stamp = Js.String2.slice(soundFingerprint(), ~from=0, ~to_=12)
  outDir ++ "/EP9_COLD_OPEN_SFX_STEM_" ++ stamp ++ ".wav"
}

let scoreEnvelope =
  /* The old fixed window automation suppressed twenty-four seconds of action,
     even while nobody spoke. The replacement score stays alive here; the final
     mix ducks it from the literal dialogue waveform instead. Three quiet spots
     in the generated score are reinforced locally from its own low-frequency
     siege material. The battle then cuts absolutely at the bedroom edit: no
     anticipatory fade, tail or reverb crosses frame 2712. */
  "[0:a]loudnorm=I=-23:TP=-2:LRA=12,asplit=4[basein][openin][shieldin][endin];" ++
  "[basein]atrim=start=0:end=113,asetpts=PTS-STARTPTS," ++
  "apad=whole_dur=120,atrim=start=0:end=120[base];" ++
  "[openin]atrim=start=27:end=40,asetpts=PTS-STARTPTS," ++
  "highpass=f=45,lowpass=f=320,volume=0.42," ++
  "afade=t=in:st=0:d=0.12,afade=t=out:st=12.5:d=0.5[open];" ++
  "[shieldin]atrim=start=56:end=63,asetpts=PTS-STARTPTS," ++
  "highpass=f=45,lowpass=f=320,volume=0.95," ++
  "afade=t=in:st=0:d=0.10,afade=t=out:st=6.65:d=0.35," ++
  "adelay=92500:all=1[shield];" ++
  "[endin]atrim=start=40:end=42,asetpts=PTS-STARTPTS," ++
  "highpass=f=45,lowpass=f=360,volume=0.92," ++
  "afade=t=in:st=0:d=0.06,adelay=111000:all=1[end];" ++
  "[base][open][shield][end]amix=inputs=4:duration=longest:normalize=0," ++
  "alimiter=limit=0.95:level=false,atrim=start=0:end=113," ++
  "apad=whole_dur=120,atrim=start=0:end=120[out]"

let currentScoreStemPath = (): string => {
  if !exists(Path(rawScorePath)) {
    raise(ColdOpenAudio("generated score source is missing: " ++ rawScorePath))
  }
  let stamp =
    sha256Text(pipelineVersion ++ "|" ++ scoreMixConfig ++ "|" ++ sha256File(Path(rawScorePath)))
    ->Js.String2.slice(~from=0, ~to_=12)
  outDir ++ "/EP9_COLD_OPEN_SCORE_STEM_" ++ stamp ++ ".wav"
}

let renderScoreStem = (): string => {
  requireProviderReceipt()
  let scoreStemPath = currentScoreStemPath()
  if !exists(Path(scoreStemPath)) {
    ffmpeg([
      "-nostdin", "-loglevel", "error", "-n", "-i", rawScorePath,
      "-filter_complex", scoreEnvelope, "-map", "[out]",
      "-ac", "2", "-ar", "44100", scoreStemPath,
    ])
  }
  let Seconds(seconds) = probeDuration(Path(scoreStemPath))
  if Js.Math.abs_float(seconds -. duration) > 0.01 {
    raise(ColdOpenAudio(
      "processed score is not exactly 120 seconds: " ++
      Js.Float.toFixedWithPrecision(seconds, ~digits=3),
    ))
  }
  scoreStemPath
}

/* A completely local preview using already-owned effects. It lets timing and
   action emphasis be reviewed before any voice or music purchase. */
let renderSfxPreview = (): unit => {
  soundCues->Belt.Array.forEach(cue => {
    if !exists(Path(cue.asset)) {
      raise(ColdOpenAudio(
        "SFX render is waiting for the approved generated asset: " ++ cue.asset,
      ))
    }
  })
  requireProviderReceipt()
  let stamp = Js.String2.slice(soundFingerprint(), ~from=0, ~to_=12)
  let stemPath = outDir ++ "/EP9_COLD_OPEN_SFX_STEM_" ++ stamp ++ ".wav"
  let videoPath = dir ++ "/out/KUKU_EP9_COLD_OPEN_SFX_PREVIEW_" ++ stamp ++ ".mp4"
  let manifestPath = outDir ++ "/EP9_COLD_OPEN_SFX_STEM_" ++ stamp ++ ".manifest.json"
  if !exists(Path(stemPath)) {
    let inputs = soundCues->Belt.Array.map(cue => ["-i", cue.asset])->Belt.Array.concatMany
    let chains = soundCues->Belt.Array.mapWithIndex((i, cue) =>
      "[" ++ Belt.Int.toString(i) ++ ":a]aresample=44100," ++
      cue.filter ++ ",volume=" ++ Js.Float.toString(cue.gain) ++ "," ++
      "adelay=" ++ Belt.Int.toString(Belt.Float.toInt(Js.Math.round(cue.at *. 1000.0))) ++
      ":all=1[s" ++ Belt.Int.toString(i) ++ "]"
    )
    let mixInputs =
      soundCues->Belt.Array.mapWithIndex((i, _) => "[s" ++ Belt.Int.toString(i) ++ "]")
    let graph =
      Js.Array2.joinWith(chains, ";") ++ ";" ++
      Js.Array2.joinWith(mixInputs, "") ++
      "amix=inputs=" ++ Belt.Int.toString(Belt.Array.length(soundCues)) ++
      ":duration=longest:normalize=0,volume=0.70,alimiter=limit=0.85:level=false," ++
      "atrim=0:" ++ Js.Float.toString(duration) ++
      ",apad=whole_dur=" ++ Js.Float.toString(duration) ++ "[out]"
    ffmpeg(Belt.Array.concatMany([
      ["-nostdin", "-loglevel", "error", "-n"],
      inputs,
      ["-filter_complex", graph, "-map", "[out]", "-ac", "2", "-ar", "44100", stemPath],
    ]))
  }
  let picturePath = dir ++ "/out/KUKU_EP9_COLD_OPEN_V1.mp4"
  if !exists(Path(picturePath)) {
    raise(ColdOpenAudio("locked cold-open picture is missing: " ++ picturePath))
  }
  if !exists(Path(videoPath)) {
    ffmpeg([
      "-nostdin", "-loglevel", "error", "-n",
      "-i", picturePath, "-i", stemPath,
      "-map", "0:v:0", "-map", "1:a:0",
      "-c:v", "copy", "-c:a", "aac", "-b:a", "192k",
      "-t", Js.Float.toString(duration), "-movflags", "+faststart", videoPath,
    ])
  }
  let Seconds(stemDuration) = probeDuration(Path(stemPath))
  let Seconds(videoDuration) = probeDuration(Path(videoPath))
  let manifest = Js.Dict.empty()
  addString(manifest, "stem", stemPath)
  addString(manifest, "picture_preview", videoPath)
  addNumber(manifest, "stem_duration_seconds", stemDuration)
  addNumber(manifest, "picture_duration_seconds", videoDuration)
  addString(manifest, "status", "effects-only review; combines repository effects with four purpose-built generated fire assets; no dialogue and no final score")
  addString(manifest, "generated_effect_provenance", "Higgsfield Seed Audio 1.0 generation receipts and hashes are required beside the four generated assets")
  addString(manifest, "mix_config", sfxMixConfig)
  Js.Dict.set(manifest, "sound_cues", Js.Json.array(soundCues->Belt.Array.map(jsonSound)))
  if !exists(Path(manifestPath)) {
    writeText(Path(manifestPath), Js.Json.stringifyWithSpace(Js.Json.object_(manifest), 1))
  }
  Js.log("LOCAL SFX PREVIEW -> " ++ videoPath)
}

let renderBedPreview = (): unit => {
  renderSfxPreview()
  let sfxStemPath = currentSfxStemPath()
  let scoreStemPath = renderScoreStem()
  let fingerprint = sha256Text(
    pipelineVersion ++ "|" ++ bedPreviewMixConfig ++ "|" ++
    sha256File(Path(sfxStemPath)) ++ "|" ++ sha256File(Path(scoreStemPath)),
  )
  let stamp = Js.String2.slice(fingerprint, ~from=0, ~to_=12)
  let mixPath = outDir ++ "/EP9_COLD_OPEN_MUSIC_SFX_STEM_" ++ stamp ++ ".wav"
  let videoPath = dir ++ "/out/KUKU_EP9_COLD_OPEN_MUSIC_SFX_PREVIEW_" ++ stamp ++ ".mp4"
  let manifestPath = outDir ++ "/EP9_COLD_OPEN_MUSIC_SFX_STEM_" ++ stamp ++ ".manifest.json"
  if !exists(Path(mixPath)) {
    ffmpeg([
      "-nostdin", "-loglevel", "error", "-n",
      "-i", scoreStemPath, "-i", sfxStemPath,
      "-filter_complex",
      "[0:a][1:a]amix=inputs=2:duration=longest:normalize=0," ++
      "alimiter=limit=0.84,atrim=0:120[out]",
      "-map", "[out]", "-ac", "2", "-ar", "44100", mixPath,
    ])
  }
  let picturePath = dir ++ "/out/KUKU_EP9_COLD_OPEN_V1.mp4"
  if !exists(Path(videoPath)) {
    ffmpeg([
      "-nostdin", "-loglevel", "error", "-n",
      "-i", picturePath, "-i", mixPath,
      "-map", "0:v:0", "-map", "1:a:0",
      "-c:v", "copy", "-c:a", "aac", "-b:a", "192k",
      "-t", "120", "-movflags", "+faststart", videoPath,
    ])
  }
  let Seconds(mixDuration) = probeDuration(Path(mixPath))
  let Seconds(videoDuration) = probeDuration(Path(videoPath))
  let manifest = Js.Dict.empty()
  addString(manifest, "score_source", rawScorePath)
  addString(manifest, "score_stem", scoreStemPath)
  addString(manifest, "sfx_stem", sfxStemPath)
  addString(manifest, "mix", mixPath)
  addString(manifest, "picture_preview", videoPath)
  addString(manifest, "score_mix_config", scoreMixConfig)
  addString(manifest, "preview_mix_config", bedPreviewMixConfig)
  addNumber(manifest, "mix_duration_seconds", mixDuration)
  addNumber(manifest, "video_duration_seconds", videoDuration)
  addString(manifest, "provider_receipt", providerReceiptPath)
  addString(manifest, "status", "music and effects only; combines the generated siege score, four generated fire assets, and repository effects; no dialogue")
  if !exists(Path(manifestPath)) {
    writeText(Path(manifestPath), Js.Json.stringifyWithSpace(Js.Json.object_(manifest), 1))
  }
  Js.log("MUSIC + SFX PREVIEW -> " ++ videoPath)
}

let previewReceiptPath = (selected: array<line>): string =>
  outDir ++ "/EP9_COLD_OPEN_FUTURE_PERFORMANCE_PREVIEW_REQUEST_" ++
  requestStampFor(selected) ++ ".manifest.json"

let verifyPreviewReceipt = (selected: array<line>): array<rendered> => {
  let receiptPath = previewReceiptPath(selected)
  if !exists(Path(receiptPath)) {
    raise(ColdOpenAudio(
      "the current five-character future-performance preview has not been generated and heard",
    ))
  }
  let rows = rowsFromExistingCache(selected, "future-performance preview")
  let currentTakeSet = mixFingerprintFor(~rows, ~mixConfig=previewMixConfig)
  let receipt = Js.Json.parseExn(readText(Path(receiptPath)))
  let recordedTakeSet =
    stringField(receipt, "take_set_fingerprint")
    ->Belt.Option.getWithDefault("")
  if recordedTakeSet != currentTakeSet {
    raise(ColdOpenAudio(
      "future-performance preview take bytes no longer match the reviewed receipt; generate and hear a new preview",
    ))
  }
  let audioPath = stringField(receipt, "audio")->Belt.Option.getWithDefault("")
  let audioHash = stringField(receipt, "audio_sha256")->Belt.Option.getWithDefault("")
  if audioPath == "" || !exists(Path(audioPath)) || sha256File(Path(audioPath)) != audioHash {
    raise(ColdOpenAudio("future-performance preview audio no longer matches its reviewed receipt"))
  }
  let overflows = rows->Belt.Array.keep(row => row.seconds > row.line.end_ -. row.line.at)
  if Belt.Array.length(overflows) > 0 {
    let details = overflows->Belt.Array.map(row =>
      row.line.id ++ " " ++ Js.Float.toFixedWithPrecision(row.seconds, ~digits=2) ++
      "s/" ++ Js.Float.toFixedWithPrecision(row.line.end_ -. row.line.at, ~digits=2) ++ "s"
    )
    raise(ColdOpenAudio(
      "reviewed future-performance preview does not fit the honest picture windows: " ++
      Js.Array2.joinWith(details, ", ") ++ "; revise it before buying the remaining lines",
    ))
  }
  rows
}

let renderPreview = async (): unit => {
  let selected = lines->Belt.Array.keep(line => line.preview)
  let rows = await renderSelected(~selected, ~maxNewRequests=5, ~requireFit=false)
  let takeSetFingerprint = mixFingerprintFor(~rows, ~mixConfig=previewMixConfig)
  let stamp = shortMixFingerprintFor(~rows, ~mixConfig=previewMixConfig)
  let previewPath = outDir ++ "/EP9_COLD_OPEN_FUTURE_PERFORMANCE_PREVIEW_" ++ stamp ++ ".mp3"
  let receiptPath = previewReceiptPath(selected)
  let parts: array<path> = []
  rows->Belt.Array.forEachWithIndex((i, row) => {
    if i > 0 {
      let _ = Js.Array2.push(parts, silence(Millis(900), Path(cacheDir)))
    }
    let _ = Js.Array2.push(parts, Path(row.file))
  })
  if !exists(Path(previewPath)) {
    let _ = concatAudio(parts, Path(previewPath))
  }
  let Seconds(total) = probeDuration(Path(previewPath))
  let audioHash = sha256File(Path(previewPath))
  let manifest = Js.Dict.empty()
  addString(manifest, "audio", previewPath)
  addString(manifest, "audio_sha256", audioHash)
  addString(manifest, "request_fingerprint", requestFingerprintFor(selected))
  addString(manifest, "take_set_fingerprint", takeSetFingerprint)
  addString(manifest, "mix_config", previewMixConfig)
  addNumber(manifest, "duration_seconds", total)
  addString(manifest, "status", "locked child cast; preview checks future-battle performance and timing, not casting")
  Js.Dict.set(manifest, "takes", Js.Json.array(rows->Belt.Array.map(jsonRendered)))
  if exists(Path(receiptPath)) {
    let prior = Js.Json.parseExn(readText(Path(receiptPath)))
    let priorTakeSet = stringField(prior, "take_set_fingerprint")->Belt.Option.getWithDefault("")
    let priorAudioHash = stringField(prior, "audio_sha256")->Belt.Option.getWithDefault("")
    if priorTakeSet != takeSetFingerprint || priorAudioHash != audioHash {
      raise(ColdOpenAudio(
        "an immutable preview receipt already exists for different audio bytes; revise the request version",
      ))
    }
  } else {
    writeText(Path(receiptPath), Js.Json.stringifyWithSpace(Js.Json.object_(manifest), 1))
  }
  Js.log("FUTURE CAST PREVIEW -> " ++ previewPath)
}

let verifyExistingOutput = (
  ~audioPath: string,
  ~manifestPath: string,
  ~expectedTakeSet: string,
): unit => {
  if !exists(Path(audioPath)) {
    ()
  } else if !exists(Path(manifestPath)) {
    raise(ColdOpenAudio("existing audio has no integrity manifest: " ++ audioPath))
  } else {
    let manifest = Js.Json.parseExn(readText(Path(manifestPath)))
    let expectedAudioHash = stringField(manifest, "audio_sha256")->Belt.Option.getWithDefault("")
    let recordedTakeSet =
      stringField(manifest, "take_set_fingerprint")->Belt.Option.getWithDefault("")
    if expectedAudioHash == "" || sha256File(Path(audioPath)) != expectedAudioHash {
      raise(ColdOpenAudio("existing audio bytes do not match their immutable manifest: " ++ audioPath))
    }
    if recordedTakeSet != expectedTakeSet {
      raise(ColdOpenAudio("existing audio take set does not match its immutable manifest"))
    }
  }
}

let buildDialogueStem = (rows: array<rendered>, dialogueStemPath: string): unit => {
  let inputs = rows->Belt.Array.map(row => ["-i", row.file])->Belt.Array.concatMany
  let chains = rows->Belt.Array.mapWithIndex((i, row) =>
    "[" ++ Belt.Int.toString(i) ++ ":a]aresample=44100," ++
    "loudnorm=I=-17:TP=-1.5:LRA=11," ++
    "adelay=" ++ Belt.Int.toString(Belt.Float.toInt(row.line.at *. 1000.0)) ++
    ":all=1[d" ++ Belt.Int.toString(i) ++ "]"
  )
  let mixInputs = rows->Belt.Array.mapWithIndex((i, _) => "[d" ++ Belt.Int.toString(i) ++ "]")
  let graph =
    Js.Array2.joinWith(chains, ";") ++ ";" ++
    "anullsrc=r=44100:cl=stereo:d=" ++ Js.Float.toString(duration) ++ "[clock];" ++
    "[clock]" ++ Js.Array2.joinWith(mixInputs, "") ++
    "amix=inputs=" ++ Belt.Int.toString(Belt.Array.length(rows) + 1) ++
    ":duration=first:normalize=0:dropout_transition=0,atrim=0:" ++
    Js.Float.toString(duration) ++ "[out]"
  ffmpeg(Belt.Array.concatMany([
    ["-nostdin", "-loglevel", "error", "-n"],
    inputs,
    ["-filter_complex", graph, "-map", "[out]", "-ac", "2", "-ar", "44100", dialogueStemPath],
  ]))
}

let floatAfterMarker = (line: string, marker: string): option<float> => {
  let index = Js.String2.indexOf(line, marker)
  index < 0
    ? None
    : Js.String2.sliceToEnd(line, ~from=index + Js.String2.length(marker))
      ->Js.String2.trim
      ->Js.String2.split(" ")
      ->Belt.Array.get(0)
      ->Belt.Option.flatMap(Belt.Float.fromString)
}

/* Regression guard for the exact failure the user caught. The first audible
   dialogue must remain on the bridge-running shot, never at time zero. */
let verifyDialogueLeadIn = (dialogueStemPath: string): float => {
  let result = run(
    ~cmd="ffmpeg",
    ~args=[
      "-nostdin", "-hide_banner", "-i", dialogueStemPath,
      "-af", "silencedetect=noise=-42dB:d=0.08", "-f", "null", "-",
    ],
  )
  if result.code != 0 {
    raise(ColdOpenAudio("dialogue sync analysis failed: " ++ result.stderr))
  }
  let firstSilenceEnd =
    result.stderr
    ->Js.String2.split("\n")
    ->Belt.Array.keepMap(line => floatAfterMarker(line, "silence_end:"))
    ->Belt.Array.get(0)
  switch firstSilenceEnd {
  | None => raise(ColdOpenAudio("dialogue stem has no measurable opening silence"))
  | Some(firstAudible) => {
      let expected = lines[0].at
      if firstAudible < expected -. 0.05 || firstAudible > expected +. 0.80 {
        raise(ColdOpenAudio(
          "dialogue sync regression: first audible speech is " ++
          Js.Float.toFixedWithPrecision(firstAudible, ~digits=3) ++
          "s; expected it over the bridge action near " ++
          Js.Float.toFixedWithPrecision(expected, ~digits=3) ++ "s",
        ))
      }
      firstAudible
    }
  }
}

let renderAll = async (): unit => {
  requireCastApproval()
  /* Verify the exact five preview take bytes and their immutable receipt before
     buying any of the eleven remaining lines. */
  let previewLines = lines->Belt.Array.keep(line => line.preview)
  ignore(verifyPreviewReceipt(previewLines))
  let rows = await renderSelected(~selected=lines, ~maxNewRequests=11, ~requireFit=true)
  let overflows = rows->Belt.Array.keep(row => row.seconds > row.line.end_ -. row.line.at)
  if Belt.Array.length(overflows) > 0 {
    let details = overflows->Belt.Array.map(row =>
      row.line.id ++ " " ++ Js.Float.toFixedWithPrecision(row.seconds, ~digits=2) ++
      "s/" ++ Js.Float.toFixedWithPrecision(row.line.end_ -. row.line.at, ~digits=2) ++ "s"
    )
    raise(ColdOpenAudio(
      "generated speech does not fit these honest picture windows: " ++
      Js.Array2.joinWith(details, ", ") ++ "; do not speed or cut it",
    ))
  }
  let takeSetFingerprint = mixFingerprintFor(~rows, ~mixConfig=dialogueMixConfig)
  let stamp = shortMixFingerprintFor(~rows, ~mixConfig=dialogueMixConfig)
  let dialogueStemPath = outDir ++ "/EP9_COLD_OPEN_DIALOGUE_STEM_" ++ stamp ++ ".wav"
  let renderManifestPath =
    outDir ++ "/EP9_COLD_OPEN_DIALOGUE_STEM_" ++ stamp ++ ".manifest.json"
  verifyExistingOutput(
    ~audioPath=dialogueStemPath,
    ~manifestPath=renderManifestPath,
    ~expectedTakeSet=takeSetFingerprint,
  )
  if !exists(Path(dialogueStemPath)) {
    buildDialogueStem(rows, dialogueStemPath)
  }
  let firstAudible = verifyDialogueLeadIn(dialogueStemPath)
  let Seconds(total) = probeDuration(Path(dialogueStemPath))
  let manifest = Js.Dict.empty()
  addString(manifest, "audio", dialogueStemPath)
  addString(manifest, "audio_sha256", sha256File(Path(dialogueStemPath)))
  addString(manifest, "take_set_fingerprint", takeSetFingerprint)
  addString(manifest, "mix_config", dialogueMixConfig)
  addNumber(manifest, "duration_seconds", total)
  addNumber(manifest, "first_audible_seconds", firstAudible)
  addString(manifest, "first_audible_picture_fact", "families visibly running on the bridge")
  addString(manifest, "status", "dialogue stem only; not the approved final mix")
  Js.Dict.set(manifest, "takes", Js.Json.array(rows->Belt.Array.map(jsonRendered)))
  if exists(Path(renderManifestPath)) {
    let prior = Js.Json.parseExn(readText(Path(renderManifestPath)))
    let priorAudioHash = stringField(prior, "audio_sha256")->Belt.Option.getWithDefault("")
    if priorAudioHash != sha256File(Path(dialogueStemPath)) {
      raise(ColdOpenAudio("immutable dialogue-stem manifest does not match the current audio"))
    }
  } else {
    writeText(Path(renderManifestPath), Js.Json.stringifyWithSpace(Js.Json.object_(manifest), 1))
  }
  Js.log("TIMED DIALOGUE STEM -> " ++ dialogueStemPath)
}

/* Local-only review assembly. It refuses missing takes rather than calling a
   provider, and copies the locked H.264 picture stream byte-for-byte. */
let renderFullPreview = (): unit => {
  requireCastApproval()
  let previewLines = lines->Belt.Array.keep(line => line.preview)
  ignore(verifyPreviewReceipt(previewLines))
  let rows = rowsFromExistingCache(lines, "approved full dialogue")
  let overflows = rows->Belt.Array.keep(row => row.seconds > row.line.end_ -. row.line.at)
  if Belt.Array.length(overflows) > 0 {
    raise(ColdOpenAudio("approved dialogue no longer fits the locked picture"))
  }

  let takeSetFingerprint = mixFingerprintFor(~rows, ~mixConfig=dialogueMixConfig)
  let dialogueStamp = shortMixFingerprintFor(~rows, ~mixConfig=dialogueMixConfig)
  let dialogueStemPath = outDir ++ "/EP9_COLD_OPEN_DIALOGUE_STEM_" ++ dialogueStamp ++ ".wav"
  let dialogueManifestPath =
    outDir ++ "/EP9_COLD_OPEN_DIALOGUE_STEM_" ++ dialogueStamp ++ ".manifest.json"
  if !exists(Path(dialogueStemPath)) {
    raise(ColdOpenAudio("timed dialogue stem is missing; run approved render first"))
  }
  verifyExistingOutput(
    ~audioPath=dialogueStemPath,
    ~manifestPath=dialogueManifestPath,
    ~expectedTakeSet=takeSetFingerprint,
  )
  let dialogueFirstAudible = verifyDialogueLeadIn(dialogueStemPath)

  renderBedPreview()
  let sfxStemPath = currentSfxStemPath()
  let scoreStemPath = currentScoreStemPath()
  let bedFingerprint = sha256Text(
    pipelineVersion ++ "|" ++ bedPreviewMixConfig ++ "|" ++
    sha256File(Path(sfxStemPath)) ++ "|" ++ sha256File(Path(scoreStemPath)),
  )
  let bedStamp = Js.String2.slice(bedFingerprint, ~from=0, ~to_=12)
  let bedPath = outDir ++ "/EP9_COLD_OPEN_MUSIC_SFX_STEM_" ++ bedStamp ++ ".wav"
  if !exists(Path(bedPath)) {
    raise(ColdOpenAudio("current music-and-effects stem is missing"))
  }

  let fingerprint = sha256Text(
    pipelineVersion ++ "|" ++ fullPreviewMixConfig ++ "|" ++
    sha256File(Path(dialogueStemPath)) ++ "|" ++ sha256File(Path(bedPath)),
  )
  let stamp = Js.String2.slice(fingerprint, ~from=0, ~to_=12)
  let mixPath = outDir ++ "/EP9_COLD_OPEN_FULL_MIX_" ++ stamp ++ ".wav"
  let videoPath = dir ++ "/out/KUKU_EP9_COLD_OPEN_FULL_AUDIO_PREVIEW_" ++ stamp ++ ".mp4"
  let manifestPath = outDir ++ "/EP9_COLD_OPEN_FULL_MIX_" ++ stamp ++ ".manifest.json"
  if !exists(Path(mixPath)) {
    ffmpeg([
      "-nostdin", "-loglevel", "error", "-n",
      "-i", bedPath, "-i", dialogueStemPath,
      "-filter_complex",
      /* Compress only the battle bed, and only while the actual approved voice
         waveform is present. This keeps the siege pulse between spoken words. */
      "[0:a][1:a]sidechaincompress=threshold=0.018:ratio=5:attack=25:release=280:" ++
      "makeup=1:mix=1[ducked];" ++
      "[ducked][1:a]amix=inputs=2:duration=longest:normalize=0," ++
      "alimiter=limit=0.78:level=false,atrim=0:120,apad=whole_dur=120[out]",
      "-map", "[out]", "-ac", "2", "-ar", "44100", mixPath,
    ])
  }
  let picturePath = dir ++ "/out/KUKU_EP9_COLD_OPEN_V1.mp4"
  if !exists(Path(videoPath)) {
    ffmpeg([
      "-nostdin", "-loglevel", "error", "-n",
      "-i", picturePath, "-i", mixPath,
      "-map", "0:v:0", "-map", "1:a:0",
      "-c:v", "copy", "-c:a", "aac", "-b:a", "192k",
      "-t", "120", "-movflags", "+faststart", videoPath,
    ])
  }
  let Seconds(mixDuration) = probeDuration(Path(mixPath))
  let Seconds(videoDuration) = probeDuration(Path(videoPath))
  if Js.Math.abs_float(mixDuration -. duration) > 0.01 ||
     Js.Math.abs_float(videoDuration -. duration) > 0.01 {
    raise(ColdOpenAudio("full preview is not exactly 120 seconds"))
  }
  let manifest = Js.Dict.empty()
  addString(manifest, "dialogue_stem", dialogueStemPath)
  addString(manifest, "music_sfx_stem", bedPath)
  addString(manifest, "audio", mixPath)
  addString(manifest, "audio_sha256", sha256File(Path(mixPath)))
  addString(manifest, "picture_preview", videoPath)
  addString(manifest, "picture_preview_sha256", sha256File(Path(videoPath)))
  addString(manifest, "mix_config", fullPreviewMixConfig)
  addNumber(manifest, "audio_duration_seconds", mixDuration)
  addNumber(manifest, "video_duration_seconds", videoDuration)
  addNumber(manifest, "dialogue_first_audible_seconds", dialogueFirstAudible)
  addString(manifest, "dialogue_first_audible_picture_fact", "families visibly running on the bridge")
  addNumber(manifest, "score_hard_cut_seconds", marker("BEDROOM_CUT"))
  addString(manifest, "provider_receipt", providerReceiptPath)
  addString(manifest, "status", "full audio review mix; locked picture copied without re-encoding")
  if !exists(Path(manifestPath)) {
    writeText(Path(manifestPath), Js.Json.stringifyWithSpace(Js.Json.object_(manifest), 1))
  }
  Js.log("FULL AUDIO PREVIEW -> " ++ videoPath)
}

let main = async () => {
  validate()
  ensureDirPath(Path(audioDir))
  ensureDirPath(Path(outDir))
  let (finalChars, previewChars) = writePlan()
  Js.log(
    "audio plan: 16 lines / " ++ Belt.Int.toString(finalChars) ++
    " final directed characters / " ++ Belt.Int.toString(previewChars) ++
    " future-performance-preview directed characters",
  )
  switch envMode->Belt.Option.getWithDefault("plan") {
  | "plan" => Js.log("PLAN ONLY — no ElevenLabs call was made.")
  | "sfx" => renderSfxPreview()
  | "bed" => renderBedPreview()
  | "mix" => renderFullPreview()
  | "preview" => {
      requirePaidGate()
      await renderPreview()
    }
  | "render" => {
      requirePaidGate()
      await renderAll()
    }
  | mode => raise(ColdOpenAudio("unknown MODE=" ++ mode ++ "; use plan, sfx, bed, preview, render or mix"))
  }
}

main()
->Js.Promise2.catch(error => {
  Js.log2("EP9 COLD-OPEN AUDIO FAILED:", error)
  exit(1)
  Js.Promise.resolve()
})
->ignore
