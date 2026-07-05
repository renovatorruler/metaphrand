/* ACT 2 #12 — THE CLIP (2026-07-03; the slice between R1 and R2; the chorus).
   The frequency was PUBLIC all along (scanner streams) - and tonight the
   country finds it, one ordinary room at a time. THE DESIGN: no new speaking
   characters at all - every human in the scene is WORDLESS (action lines
   only); the ONLY dialogue is BIRDY's own voice coming out of phone and
   laptop speakers, snippets the audience already knows from earlier scenes
   (the bad-thing apology, the job joke, "Well, I'll be.") - the unescapable
   voice now filling garages and bedrooms and the beach road. A kid clips
   thirty seconds and posts it; the numbers climb; and a rocket company's
   founder (never named, never voiced - a POST on a screen) reposts it to the
   whole country. PLOT: the shield loads - by the time R2's fireworks logic
   speaks, there is no quiet way to do anything to this man. The awe stays
   intimate (single rooms, single faces); the SCALE is carried by repetition,
   not spectacle. Ends on the numbers still climbing in dark rooms. Engine-
   written. */

let outPath = "/Users/dusty/dev/brehon-law/stories/sky-king/sky-king-clip.scene.txt"

let seed: Seed.sceneSeed = {
  id: "sky-king-clip",
  slug: "INT./EXT. VARIOUS - SEATTLE - NIGHT (INTERCUT)",
  logline: "The frequency was public the whole time - anyone with a scanner app could always listen to the sky - and tonight, one ordinary room at a time, the country finds it. A mechanic shuts off his impact wrench because of something a phone on the workbench just said. A kid in a dark bedroom clips thirty seconds of a soft voice apologizing for stealing an airplane and posts it. The line of headlights on the beach road doubles, then doubles again. And a rocket company's founder, awake at midnight like everybody else, reposts the clip to an audience the size of the country - so that by the time anyone in a command post says the word 'options,' there is no quiet way left to use any of them.",
  cast: [
    {
      name: "BIRDY",
      who: "present only as his own voice coming out of speakers - phone speakers, laptop speakers, a truck's bluetooth - snippets of what he has already said on the frequency tonight, landing in rooms he will never see, on people who stop what they're doing. He does not know any of this is happening.",
      register: "the snippets are VERBATIM or near-verbatim reprises of established lines (the bad-thing apology, the job exchange, small wonder lines) - tinny, compressed, coming out of small speakers; nothing new is said.",
      earnsEloquence: false,
      lexicon: "only what he has already said tonight.",
    },
  ],
  layer: {
    peshat: "scanner audio of the stolen-plane frequency spreads across the country in real time; a clip goes viral; a famous billionaire amplifies it; crowds and numbers grow",
    sod: "the chorus verse of the ballad: the world that never once looked at him now cannot stop listening - and the love arrives the only way the modern world knows how to deliver it, as a number going up in dark rooms; every stopped wrench and propped phone is one more person finding the voice of their own unlived life; the same wave that is falling in love with him is quietly building the wall that protects him - watched men cannot be disappeared - and nobody doing the watching knows they are doing anything at all; the machine's secrecy dies not by leak but by the oldest fact of radio: the sky talks in the clear, and always did",
  },
  beats: [
    {
      who: "BIRDY",
      want: "(his voice, loose in the world) nothing - the rooms it lands in do the wanting",
      wall: "none - that is the point: there is no gate on a public frequency, and there never was",
      turn: "a garage at night: a mechanic under a truck slides out because of something the phone on the workbench said; he wipes his hands and turns it up; the soft voice apologizes out of the little speaker and the impact wrench stays on the floor",
      subtext: "the first stopped room; work interrupted by a voice like the listener's own; nobody says anything - the wordless country beginning to gather",
    },
    {
      who: "BIRDY",
      want: "(the clip being born)",
      wall: "thirty seconds is all a clip holds - the kid has to choose which thirty",
      turn: "a dark bedroom lit by a monitor: a teenager with a scanner stream open drags a selection across an audio waveform - the bad-thing apology inside it - types nothing clever, posts it; the number under it says a handful, then says more",
      subtext: "the ballad's first pressing; the choice of verse made by a kid on instinct; the machine of the folk starting to sing without knowing it",
    },
    {
      who: "BIRDY",
      want: "(the wave finding its size)",
      wall: "none left",
      turn: "the beach road from the sights scene, wider now: the line of stopped cars has doubled and doubled, phones propped on dashboards all playing the same voice a half-second out of sync; INTERCUT the numbers climbing under the kid's post; a bar with the game muted and one phone held up to the room; the voice saying the job-joke lines to forty strangers who laugh and then go quiet",
      subtext: "the chorus assembling; the love as a number in dark rooms; the awe kept intimate - one face at a time - while the scale runs in the counts; the half-second echo down the beach road = the country as one cracked speaker",
    },
    {
      who: "BIRDY",
      want: "(the shield closing over him)",
      wall: "-",
      turn: "a phone face-up on a nightstand somewhere expensive: the clip arrives; a thumb we never see whole reposts it from an account with a rocket company in its bio and an audience the size of the country; the number under the kid's clip stops looking like a number; end on three dark rooms in a row, each lit by a screen, each playing his voice, the counts still climbing",
      subtext: "the billionaire never named, never voiced, never shown whole - a thumb and a bio and a number; the wall against the fireworks built by people who think they are only listening; the film ends the verse inside the folklore being born",
    },
  ],
  rules: [
    "NO NEW SPEAKING CHARACTERS - NONE: every human in the scene (the mechanic, the kid, the bar, the drivers, the thumb) exists in ACTION LINES ONLY, wordless. The ONLY dialogue lines are BIRDY (RADIO) - his voice out of phone/laptop/car speakers.",
    "BIRDY'S SNIPPETS ARE REPRISES, NOT NEW MATERIAL: verbatim or near-verbatim fragments of established lines from earlier tonight - 'I, uh. I kind of did a bad thing here.' / the airplane's-not-really-mine apology / the job exchange ('You think an airline'd give me a job after that, like a flying job') / small wonder lines ('Well, I'll be.'). NOTHING new is written for him; the scene quotes the film.",
    "THE BILLIONAIRE IS A DEVICE, NOT A CHARACTER: never named (real or fictional name), never voiced, never shown whole - a phone on a nightstand, a thumb, an account bio with a rocket company in it, a follower count the size of a country, a repost. One beat, cold, done. No commentary from anyone.",
    "SCREENS ARE PROPS, NOT GRAPHICS-PORN: numbers described plainly in action lines (the number under it says a handful, then says more; the number stops looking like a number) - no invented usernames, no comment text on screen, no hashtag recitals. The film never reads the internet aloud.",
    "THE AWE STAYS INTIMATE: one room, one face, one stopped wrench at a time; SCALE is carried by repetition and the counts, never by crowds roaring or montage hysteria. Nobody cheers. The register is people going QUIET.",
    "THE BEACH ROAD CALLBACK: the sights scene's line of headlights, wider now, phones a half-second out of sync down the row - one image, plainly described.",
    "ACTION LINES ARE FULL SENTENCES, PRESENT TENSE; each new room ORIENTED in one stroke (a garage at night; a dark bedroom lit by a monitor; a bar with the game muted); the scene must play EARS-ONLY - the sound design is his tinny voice arriving in different acoustics.",
    "SOURCED FACTS ONLY: the frequency is public by nature (scanner streams) - the page may show the kid's stream app plainly but NOBODY explains legality or history; no character explains anything (there are no characters to explain).",
    "NO summarizing, NO thematic telegraphing, NO narrator knowingness (banned words like 'viral', 'folk hero', 'legend' do NOT appear); the closest the page comes is the counts climbing. Kill every catalog tell. American vernacular. Recorded, not written.",
    "END inside the wave, unresolved: three dark rooms in a row, each lit by a screen, each playing his voice, the counts still climbing. No button.",
    "KEEP IT SHORT: this is a verse, not an act - roughly 20 to 28 lines total.",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=5)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: THE CLIP (the chorus; the shield loads) ===\n")
    Js.log(Cinema_Backends.readText(out))
    Js.log("\n=== VERIFY (expect PENDING until lift) ===")
    switch Write.verify(out) {
    | Ok() => Js.log("VERIFY OK")
    | Error(m) => Js.log("VERIFY: " ++ m)
    }
  } catch {
  | Write.WriteError(m) => Js.log("WRITE FAILED (gate):\n" ++ m)
  | Session.SessionError(m) => Js.log("SESSION: " ++ m)
  }
  Session.close()
}

main()->ignore
