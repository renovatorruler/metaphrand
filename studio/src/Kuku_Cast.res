/* कुकु और अक्षर — one locked ElevenLabs cast registry.

   Production dialogue and table reads must use the same character identities.
   Keeping the ids here prevents a one-off renderer from silently recasting a
   familiar character. */

let voiceOf = (who: string): option<string> =>
  switch who {
  | "KUKU" => Some("NbvR1eY6Q8ivACdEO8PV")
  | "FYURIA" => Some("FFmp1h1BMl0iVHA0JxrI")
  | "VESPER" => Some("subIZc6skATBQ1Rbqpi7")
  | "DADI" => Some("nfMYisZqs1GOjTFllho3")
  | "MITASUR" => Some("bBG9wwa23659EgIkMbc1")
  | "CASTOR" => Some("4iqKdEXMW8NRF8USiS3Q")
  | "LEDA" => Some("nUX4UWK0Tf1qh5zvFZWR")
  | "PAPA" => Some("5ycO0zpSCEkvR4Ri6gk9")
  | "CHEEL" => Some("PId0lEbL3SOYkQZSraml")
  | "SUTRADHAR" => Some("OIIrFPBzLAigdcttMGWZ")
  | "RISHI" => Some("ocf4J1Vk0yOOFNBy3kNq")
  /* Episode casting only: the city guard borrows the unused Papa performer.
     This does not make the guard Papa inside story canon. */
  | "NAGAR_RAKSHAK" => Some("5ycO0zpSCEkvR4Ri6gk9")
  | _ => None
  }

/* A chorus is episode cast, not a permanent four-person band. Ep9's five
   trainees include Castor and Leda and do not include Mitasur. */
let chorusMembersFor = (dir: string): array<string> =>
  if Js.String2.includes(dir, "ep9prod") {
    ["KUKU", "FYURIA", "VESPER", "CASTOR", "LEDA"]
  } else {
    ["KUKU", "FYURIA", "VESPER", "MITASUR"]
  }

let mimicVoiceKey = (name: string): option<string> =>
  switch name {
  | "कुकु" => Some("KUKU")
  | "फ्यूरिया" => Some("FYURIA")
  | "वैस्पर" => Some("VESPER")
  | "दादी" => Some("DADI")
  | "पापा" => Some("PAPA")
  | "मिटासुर" => Some("MITASUR")
  | "कैस्टर" => Some("CASTOR")
  | "लेडा" => Some("LEDA")
  | "चील" => Some("CHEEL")
  | _ => None
  }

let tableReadNarrator = "SUTRADHAR"
