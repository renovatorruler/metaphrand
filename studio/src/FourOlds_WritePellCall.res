/* THE FOUR OLDS — Pell's own scene, v1. Author's note: Pell only ever showed up to
   annoy the protagonist; needs a throughline of his own, at a scale that matches a
   Moon-mission plot, not generic county compliance work. Engine-written. */

let outPath = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/draft/engine_pell_holloway.scene.txt"

let seed: Seed.sceneSeed = {
  id: "four-olds-pell-holloway-call",
  slug: "INT. FEDERAL COMPLIANCE FIELD OFFICE - DAY",
  logline: "Pell's national director puts him under real personal pressure over the Accord's heritage-asset recovery numbers, days before the live global Fourth of July broadcast — revealing that the Dawes farm is one pin on a national map, not the whole job, and that Pell's own career is what is actually on the line.",
  cast: [
    {
      name: "PELL",
      who: "regional enforcement lead for the Lunar Heritage Neutralization Accord's heritage-asset recovery program, 50s. A commendation photo two years old still hangs on his office wall — he used to be good at this. Now behind on his numbers and feeling it.",
      register: "recites official Accord doctrine easily, like he's said it a hundred times, when performing his role. The moment his OWN performance is what's under discussion, he turns clipped, careful, defensive — plain bureaucratic sentences, not doctrine.",
      earnsEloquence: false,
      lexicon: "verified/unverified, parcels, regional numbers, flight articles, the Accord — spreadsheet language.",
    },
    {
      name: "HOLLOWAY",
      who: "Pell's national director inside the Accord's enforcement apparatus. Appears only as a voice/face on a screen. Sees the whole program as numbers on a dashboard, not people.",
      register: "flat, transactional, interrupts, never raises his voice because he never needs to. Speaks entirely in metrics, optics, and institutional stakes.",
      earnsEloquence: false,
      lexicon: "regional averages, camera-ready optics, review boards, the President's office, headlines.",
    },
  ],
  layer: {
    peshat: "a performance-review phone call between a regional bureaucrat and his national boss about quarterly recovery numbers, days before a live global broadcast",
    sod: "the same machine grinding down Cricket is, in the very next breath, grinding down the man sent to grind down Cricket — Pell is being squeezed exactly like Cricket was, and cannot see the mirror he is standing in",
  },
  beats: [
    {
      who: "HOLLOWAY",
      want: "get Pell to close more verified recoveries before the Fourth of July broadcast",
      wall: "Pell tries to defend the one good recovery he has as meaningful",
      turn: "Holloway reveals the real stakes are bigger than Pell realized — the President's own office asked for this region by name — making clear it is Pell's career on the line, not just a metric",
      subtext: "Holloway does not see Pell as a person he is threatening, only a number he is correcting",
    },
    {
      who: "PELL",
      want: "prove he still has value, land on something that will satisfy Holloway",
      wall: "his only real lead is one farmer's barn, small next to what is being demanded of him",
      turn: "he commits fully to the Dawes lead the moment the call ends, pulling the folder before Holloway has even fully hung up",
      subtext: "he still privately believes he is the man in the commendation photo on his wall, and is trying to get back to being him",
    },
  ],
  rules: [
    "Pell is the REGIONAL ENFORCEMENT LEAD for the Lunar Heritage Neutralization Accord's heritage-asset recovery program specifically — NOT a generic tax/compliance officer. Every reference to his work connects to recovering verified Apollo-program hardware, tied to the live July Fourth global broadcast the President's office is personally watching. The Dawes farm must read as ONE ITEM on a much larger regional canvas Pell manages — never let it become the whole subject of the call.",
    "Holloway is cold and transactional, never cruel for its own sake — he is simply, completely indifferent to Pell as a person, the way a spreadsheet is indifferent. He speaks entirely in numbers, optics, and institutional stakes.",
    "NEVER state the theme aloud (that the system is grinding down its own enforcer the same way it grinds down Cricket) — carry it only through the shape of the scene, never through a line that names it.",
    "Plain, procedural, bureaucratic register throughout. Rule-of-three, rhetorical triads, and any 'inspiring' political cadence are BANNED for both characters — that register belongs exclusively to Marwani's broadcast speeches elsewhere in this screenplay and must never leak here.",
    "Pell may recite Harmony/Accord doctrine in a rehearsed, 'said it a hundred times' cadence when performing his official role. His UNGUARDED voice, when his own position is under discussion, turns plainer and more defensive — a different register, not the same one.",
    "Fountain screenplay format: a slugline, plain action lines describing only what a camera would see, CHARACTER NAME: dialogue cues, an (ON SCREEN) parenthetical for Holloway since he appears only by video call.",
    "Kill every AI-writing tell: em-dash overuse, negative parallelism, corrective-definition ('that's not X, that's Y'), inflated-significance vocabulary (testament, underscores, pivotal), cute authorial conceits or metaphors, ironic narrator asides. Concrete, plain, physically grounded action lines only.",
    "End on Pell alone at his desk, the call over, already reaching for the Dawes/Frontier folder. No summarizing button line, no line that explains what he is feeling.",
  ],
}

let main = async () => {
  try {
    let sc = await Write.writeScene(~seed, ~maxTries=5)
    let out = Cinema_Backends.Path(outPath)
    let _ = Write.emit(sc, ~txt=out)
    Js.log("=== ENGINE WROTE: PELL / HOLLOWAY CALL ===\n")
    Js.log(Cinema_Backends.readText(out))
    Js.log("\n=== VERIFY ===")
    switch Write.verify(out) {
    | Ok() => Js.log("VERIFY OK")
    | Error(m) => Js.log("VERIFY: " ++ m)
    }
  } catch {
  | Write.WriteError(m) => Js.log("WRITE FAILED (gate):\n" ++ m)
  | Session.SessionError(m) => Js.log("SESSION: " ++ m)
  | Cinema_Backends.BackendError(m) => Js.log("BACKEND: " ++ m)
  | Js.Exn.Error(e) => Js.log("JS EXN: " ++ (Js.Exn.message(e)->Belt.Option.getWithDefault("(no message)")))
  | e => Js.log2("UNKNOWN EXN:", e)
  }
  Session.close()
}

main()->ignore
