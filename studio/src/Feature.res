/* SKY KING — flesh Act 1 (+ a few Act 2 scenes) and DIAGNOSE.
   Per scene: the writer drafts it, then we note the drama verdict and the language
   verdict (floor + judge) beside the kept prose. No repair (we want to SEE the raw
   writing and where the gate fights it). Per-scene try/catch so nothing kills the
   batch. `node src/Feature.res.mjs`. */

open Process

@module("fs") external writeFileSync: (string, string) => unit = "writeFileSync"
@module("fs") external appendFileSync: (string, string) => unit = "appendFileSync"

let out = "/Users/dusty/dev/brehon-law/stories/sky-king/SCENES.md"

let birdy = make(~name=CharacterName("BIRDY"), ~chart={sun: Pisces, moon: Cancer, mars: Cancer, mercury: Pisces, jupiter: Pisces, venus: Pisces, saturn: Capricorn, rahu: Virgo, ketu: Pisces})
let maya = make(~name=CharacterName("MAYA"), ~chart={sun: Taurus, moon: Cancer, mars: Virgo, mercury: Taurus, jupiter: Cancer, venus: Taurus, saturn: Libra, rahu: Gemini, ketu: Sagittarius})
let bishop = make(~name=CharacterName("BISHOP"), ~chart={sun: Capricorn, moon: Taurus, mars: Capricorn, mercury: Virgo, jupiter: Sagittarius, venus: Capricorn, saturn: Aquarius, rahu: Leo, ketu: Aquarius})
let dez = make(~name=CharacterName("DEZ"), ~chart={sun: Sagittarius, moon: Leo, mars: Aries, mercury: Sagittarius, jupiter: Gemini, venus: Leo, saturn: Aries, rahu: Gemini, ketu: Sagittarius})

let sPlan = HeldCard("BIRDY has quietly decided to end his life; this flight is meant to be his goodbye. NEVER stated on the page; only ever implied.")
let sSim = HeldCard("BIRDY secretly taught himself to fly on a home flight simulator; it is the one place he ever felt capable.")
let sPills = HeldCard("MAYA found the pills he hid and has been too frightened to say a word.")
let sDebt = HeldCard("BIRDY works sixty-hour weeks at minimum wage and hides a crushing debt from MAYA.")

let bible = {cast: [birdy, maya, bishop, dez], secrets: [sPlan, sSim, sPills, sDebt]}

let briefs = [
  {want: Want("BIRDY wants BISHOP to quit steering him toward landing and just let him keep the sky one more minute"), wall: Wall("BISHOP stays calm and keeps gently turning the talk back to bringing the plane down"), turn: Turn("BIRDY puts him off with a soft, self-deprecating joke that lands like a goodbye, and we cut away before we understand it"), present: [name(birdy), name(bishop)], live: [sPlan]},
  {want: Want("DEZ wants BIRDY to walk into the office right now and demand the raise he is owed"), wall: Wall("BIRDY will not; he only wants the shift to end without a scene"), turn: Turn("BIRDY talks DEZ down, takes the smaller hit, and waves the next jet out into a sky he never gets to fly"), present: [name(birdy), name(dez)], live: [sDebt]},
  {want: Want("MAYA wants one true sentence out of BIRDY about how he actually is"), wall: Wall("BIRDY hands her the gentle, practiced 'I'm fine' instead"), turn: Turn("MAYA lets it go rather than push him, and the gap between them quietly widens"), present: [name(birdy), name(maya)], live: [sPlan, sPills]},
  {want: Want("MAYA wants BIRDY to let her into the one room where he still seems alive, his homemade flight simulator"), wall: Wall("BIRDY keeps the door half-closed; it is his, and he cannot say why it matters"), turn: Turn("MAYA glimpses the man she married flying for a few seconds, then watches the shutter come back down"), present: [name(birdy), name(maya)], live: [sSim, sPlan]},
  {want: Want("BIRDY wants DEZ to take the cash and not make a thing of it"), wall: Wall("DEZ knows BIRDY cannot afford it and will not take charity from a man worse off than himself"), turn: Turn("BIRDY makes him take it anyway, and DEZ, pocketing it, finally sees something is wrong with his friend"), present: [name(birdy), name(dez)], live: [sDebt, sPlan]},
  {want: Want("MAYA wants to tell BIRDY she found the pills and ask him to stay"), wall: Wall("her terror of breaking him, and his mask, will not let the words out"), turn: Turn("the question dies in her throat; she says goodnight instead, and hates herself for it"), present: [name(maya), name(birdy)], live: [sPills, sPlan]},
  {want: Want("BIRDY wants to give MAYA a perfect, ordinary last morning she will not recognize as a goodbye"), wall: Wall("MAYA, sensing something off, keeps trying to make him promise about tomorrow"), turn: Turn("she almost reaches him, he almost stays, but the weight wins and he lets the moment pass"), present: [name(birdy), name(maya)], live: [sPlan]},
  {want: Want("BIRDY wants DEZ to clock out early and leave him alone on the ramp"), wall: Wall("DEZ lingers, uneasy and half-knowing, not wanting to leave his friend like this"), turn: Turn("BIRDY sends him home with a warm lie and turns to the empty plane in the dark"), present: [name(birdy), name(dez)], live: [sPlan, sSim]},
  {want: Want("BIRDY wants to get the plane off the ground before anyone can stop him"), wall: Wall("the tower catches the rogue taxi and BISHOP orders him to shut it down"), turn: Turn("BIRDY pushes the throttles and lifts off, past the point of return, airborne and alone"), present: [name(birdy), name(bishop)], live: [sPlan, sSim]},
  {want: Want("BISHOP wants to keep BIRDY talking, and alive, long enough to find a way down"), wall: Wall("BIRDY wants to be left alone to finish what he came up here to do"), turn: Turn("BISHOP refuses to bark at him and just talks to him like a person, and BIRDY, startled, answers"), present: [name(birdy), name(bishop)], live: [sPlan]},
  {want: Want("BIRDY wants to see one truly beautiful thing before the end and asks BISHOP where the orca is"), wall: Wall("the fighter jets are closing and BISHOP has every reason to refuse and order him down"), turn: Turn("BISHOP gives him the heading instead, and the beauty starts to loosen something BIRDY thought was already dead"), present: [name(birdy), name(bishop)], live: [sPlan]},
  {want: Want("MAYA wants BISHOP to put her on the radio so she can talk her husband down"), wall: Wall("protocol, the closing jets, and the risk that her voice is the very thing that ends it"), turn: Turn("BISHOP breaks the rule and keys her in, and the stakes become unbearable for everyone in the room"), present: [name(maya), name(bishop)], live: [sPlan, sPills]},
  {want: Want("BIRDY wants to feel completely alive exactly once and rolls the plane through the gold light"), wall: Wall("this hour was meant to be his goodbye, not a reason to stay"), turn: Turn("the grace overwhelms him, 'I wasn't planning on landing' cracks into 'but maybe I could', and for the first time he wants to live"), present: [name(birdy), name(bishop)], live: [sPlan]},
]

let langVerdict = async (prose: string): string => {
  let floor = switch Gate.craftlint(Gate.raw(prose)) {
  | Ok(_) => []
  | Error(fs) => Belt.Array.map(fs, f => Gate.describe(f.violation))
  }
  let judged = await Judge.language(prose)
  let flags = Belt.Array.concat(floor, Belt.Array.map(judged, Gate.describe))
  Array.length(flags) == 0 ? "language PASS" : "language FLAG: " ++ Js.Array2.joinWith(flags, "; ")
}

let main = async () => {
  writeFileSync(out, "# SKY KING — fleshed scenes (engine output; gate verdicts noted)\n\n")
  let rec go = async (bs: list<brief>, n: int) =>
    switch bs {
    | list{} => Js.log("DONE - " ++ Belt.Int.toString(Session.callsMade()) ++ " total model calls.")
    | list{b, ...rest} => {
        try {
          let draft = await draftScene(b, bible, Session.ask)
          let prose = Js.Array2.joinWith(draft.ordered, "\n")
          let conceptV = switch await gateConcept(draft, Judge.concept) {
          | Ok(_) => "drama PASS"
          | Error(fs) => "drama FLAG: " ++ Js.Array2.joinWith(Belt.Array.map(fs, describeFinding), "; ")
          }
          let langV = await langVerdict(prose)
          let Turn(t) = b.turn
          appendFileSync(out, "## Scene " ++ Belt.Int.toString(n) ++ "\n*turn: " ++ t ++ "*\n*[" ++ conceptV ++ " | " ++ langV ++ "]*\n\n" ++ prose ++ "\n\n---\n\n")
          Js.log("scene " ++ Belt.Int.toString(n) ++ " done - " ++ Belt.Int.toString(Session.callsMade()) ++ " calls")
        } catch {
        | _ => {
            appendFileSync(out, "## Scene " ++ Belt.Int.toString(n) ++ "\n[error generating this scene; skipped]\n\n---\n\n")
            Js.log("scene " ++ Belt.Int.toString(n) ++ " ERRORED, continuing")
          }
        }
        await go(rest, n + 1)
      }
    }
  await go(Belt.List.fromArray(briefs), 1)
}

main()->ignore
