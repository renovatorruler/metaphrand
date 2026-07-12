/* THE FOUR OLDS v14 — sc22 split into two smaller units after repeated
   model-turn timeouts on the fused seed. Same content, two scenes:
   22a = Mack finds out + joins; 22b = tradecraft + cover stories.
   Run: CLAUDE_STUDIO_BUDGET=18 node src/FourOlds_V14_Sc22Split.res.mjs */

@module("fs") external existsSync: string => bool = "existsSync"

let dir = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/v14/"

type job = {seed: Seed.sceneSeed, out: string}

let mk = (id, file, slug, logline, cast, peshat, sod, beats, rules): job => {
  seed: {
    id,
    slug,
    logline,
    cast,
    layer: {peshat, sod},
    beats,
    rules: Belt.Array.concat(rules, V14Rules.common),
  },
  out: dir ++ file,
}

let jobs: array<job> = [
  mk(
    "v14-22a-mack-finds-out",
    "sc22a_mack.scene.txt",
    "INT. TRI-COUNTY AUCTION BARN - NIGHT",
    "Mack, who books the freight, knows what six empty archival boxes should weigh — and his own scale disagrees by thirty kilos, four times. He walks the shop at night, lifts one tarp, and calls the room to the plywood table: 'Nothing on this manifest breathes, gentlemen.' By the end of it he sits down and takes out his pen.",
    [V14Cast.mack, V14Cast.cricket, V14Cast.gunny, V14Cast.dutch, V14Cast.stitch, V14Cast.joss, V14Cast.tito],
    "the fixer catches the caper by arithmetic and joins it by choice",
    "the man of paper discovers the one thing paper can't explain and chooses the country over the contract; his signature is the most expensive one in the room and he spends it",
    [
      {
        who: "MACK",
        want: "an explanation for thirty kilos, four times",
        wall: "he already knows; he wants to hear them say it",
        turn: "the tarp comes up off a couch shaped like a man — at the table: 'Nothing on this manifest breathes, gentlemen.' — Cricket answers in checklist grammar, plain, complete, under four sentences — MACK: 'You understand there's no backing out once you're up there. Bad heart at four g's, your age, no doctor closer than a quarter million miles.' / GUNNY, not unkindly: 'Boone, I've buried better men than me for worse reasons than this. Sit down or go home. Either's fine. Quit standing there doing arithmetic on our behalf.' — a beat — Mack sits, and takes out his pen",
        subtext: "the arithmetic was never the question",
      },
      {
        who: "JOSS",
        want: "to be told what he's part of",
        wall: "he's known for days",
        turn: "'You're all insane. What do you need from me?' — and Tito raps the crate wall twice",
        subtext: "the kids choose in, out loud, once",
      },
    ],
    [
      "Mack's discovery must be shown as ARITHMETIC first — the freight booking sheet, his own floor scale, four heavy lines penciled and circled — then the night walk and the tarp. No dialogue until the table.",
      "Cricket's answer to 'nothing on this manifest breathes' is the ONE place the plan is said out loud in the film: plain, complete, under four sentences, checklist grammar, no oratory, no theme.",
      "Under two pages. End on the pen coming out.",
    ],
  ),
  mk(
    "v14-22b-tradecraft",
    "sc22b_tradecraft.scene.txt",
    "INT. TRI-COUNTY AUCTION BARN - NIGHT (LATER)",
    "The operation drops off the grid: nothing electronic, handwritten letters under a feed-cooperative letterhead, the ham net on schedule in code, a book cipher out of a swollen 1971 Reader's Digest — and cover stories for July, one per man, rehearsed once around the table.",
    [V14Cast.mack, V14Cast.dutch, V14Cast.gunny, V14Cast.stitch, V14Cast.joss, V14Cast.tito, V14Cast.danny, V14Cast.cricket],
    "the conspiracy learns to move like 1775",
    "the one playbook the surveillance state can't model is the Revolutionary one — and the film shows every mechanism plainly (letters, cipher, cover stories) so the audience believes the machine can't see what it can't imagine",
    [
      {
        who: "MACK",
        want: "the operation off every grid tonight",
        wall: "two hundred habits of modern life",
        turn: "'From tonight, everything changes how it moves. Nothing electronic. No phones, no email, no cloud. Nothing with a battery you didn't build yourself.' / JOSS: 'Then how do two hundred guys across four states coordinate a—' / DUTCH: 'Handwritten letters. The ham net, on schedule, in code. A book cipher.' — the swollen 1971 Reader's Digest on the table — JOSS: 'That's insane. That's — that's Revolutionary War stuff.' / GUNNY: 'They've got every algorithm ever written. We've got Valley Forge.'",
        subtext: "the old skills are unconfiscatable",
      },
      {
        who: "DANNY",
        want: "carry his share without ceremony",
        wall: "the cipher is homework and the cover story is a lie he'll tell the whole county",
        turn: "the kitchen-table cipher drill — 'Fourteen. Two. Nine.' — Cricket thumbing to page fourteen, column two, nine words down — 'That's a grocery list.' / 'This week it is.' — then the cover-story round at the shop: GUNNY: his sister's, Montgomery; STITCH: airplane parts, Wichita — 'true enough'; DUTCH: the archival-standards conference in Dayton — a beat — 'There is one.'; and Danny, assigned his father's: 'Fishing.'",
        subtext: "the family absorbs the operation the way it absorbs everything: practically",
      },
    ],
    [
      "REQUIRED montage beats: envelopes addressed TRI-COUNTY FEED COOPERATIVE, RE: PARTS into rural mailboxes, little red flags up; a mail carrier tossing one in the tray between coupon packs; Tito's film camera — two frames of the finished couch, the canister dropped into a Folgers can half-full of them, the can into the bottom of his toolbox.",
      "Under two and a half pages. The cover-story round is dry comedy in register — one line each, no reactions.",
    ],
  ),
]

/* ---- runner ---------------------------------------------------------- */
let runOne = async (j: job) => {
  let path = Cinema_Backends.Path(j.out)
  let done_ = existsSync(j.out) && Write.verify(path) == Ok()
  if done_ {
    Js.log("SKIP " ++ j.seed.id ++ " (verified)")
  } else {
    let sc = await Write.writeScene(~seed=j.seed, ~maxTries=4)
    let _ = Write.emit(sc, ~txt=path)
    let sc2 = await Write.liftDialogue(~path, ~maxTries=3)
    let _ = Write.emit(sc2, ~txt=path)
    switch Write.verify(path) {
    | Ok() => Js.log("OK   " ++ j.seed.id)
    | Error(m) => Js.log("BAD  " ++ j.seed.id ++ " — " ++ m)
    }
  }
}

let main = async () => {
  let failed = []
  let n = Belt.Array.length(jobs)
  let rec go = async i =>
    if i < n {
      let j = jobs[i]
      switch await (async () => await runOne(j))() {
      | _ => ()
      | exception Write.WriteError(m) => {
          Js.Array2.push(failed, j.seed.id)->ignore
          Js.log("FAIL " ++ j.seed.id ++ " (gate): " ++ m)
        }
      | exception Session.SessionError(m) => {
          Js.Array2.push(failed, j.seed.id)->ignore
          Js.log("FAIL " ++ j.seed.id ++ " (session): " ++ m)
        }
      }
      await go(i + 1)
    }
  await go(0)
  Js.log(
    "SC22 SPLIT DONE — " ++
    Belt.Int.toString(n - Belt.Array.length(failed)) ++
    "/" ++
    Belt.Int.toString(n) ++
    " ok" ++ (Belt.Array.length(failed) > 0 ? " | failed: " ++ Js.Array2.joinWith(failed, ", ") : ""),
  )
  Session.close()
}
main()->ignore
