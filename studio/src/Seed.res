/* ============================================================================
   Seed — what I am ALLOWED to author. Structure, never prose.

   The whole point: I write the SEED (the scene's wants, walls, turns, the voice
   cards, the buried layer), and the engine writes the SENTENCES. There is no
   prose field here — no place for me to smuggle a finished line in. The closest
   I can get to "writing" is describing a want or a constraint; the model is what
   turns that into the words you hear.

   (Honest hole: a want/wall written too specifically can still lead the model by
   the nose. The fields are short by design, and the gate judges the OUTPUT, but
   this is the seam to watch.)
   ============================================================================ */

/* how a character SOUNDS — the model writes their lines from this, not from me. */
type voiceCard = {
  name: string, // "BIRDY"
  who: string, // role/situation: "ground crew, ~30, took an empty airliner up"
  register: string, // "gentle, apologetic, self-deprecating; never sharp or wry"
  earnsEloquence: bool, // may they speak in polished lines, or only plainly?
  lexicon?: string, // the metaphor-world they speak THROUGH (Birdy = flight/weather/weight)
}

/* the PaRDeS contract: what shows, and what must NEVER reach the page. */
type layer = {
  peshat: string, // the literal surface the scene shows
  sod: string, // the buried theme — the model must carry it, never state it
}

/* one unit of drama: who wants what, the wall, the turn. */
type beat = {
  who: string,
  want: string,
  wall: string,
  turn: string,
  subtext?: string, // what the character WANTS here but cannot say — lives in the gap
}

type sceneSeed = {
  id: string, // "sky-king-cold-open"
  slug: string, // "EXT. SKY — DUSK / INT. Q400 COCKPIT — CONTINUOUS"
  logline: string, // one line: what this scene IS
  cast: array<voiceCard>,
  layer: layer,
  beats: array<beat>,
  rules: array<string>, // hard craft constraints handed to the model
}
