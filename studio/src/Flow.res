/* The whole flow, end to end — run on STUBS, so it makes zero model calls and
   spends zero tokens. It proves the pipeline COMPOSES: an idea becomes a
   shippable scene, with every gate threaded through and enforced by the types.
   (`npm run flow`) */

open Process

let main = async () => {
  Js.log("=== studio - running the whole flow (stubs only; no model calls) ===")

  let noJudge = (_: string): promise<array<Gate.violation>> => Js.Promise.resolve([])  // free: no model judge in the flow demo
  let noConceptJudge = (_: conceptGate, _: string): promise<option<reasonText>> => Js.Promise.resolve(None)
  let stubWriter = (_: string): promise<string> => Js.Promise.resolve("RAY blocks the door.\nRAY: Give me the keys.\nSAM: No.")  // canned: no model in the flow demo
  let stubWorld = (_: string): promise<string> => Js.Promise.resolve("CHARACTER | Ray | Aries Leo Aries Gemini Sagittarius Leo Capricorn Gemini Sagittarius\nSECRET | the debt")

  /* --- develop the world, with you in the loop --- */
  let spark = conceive(Idea("a compromised opium-belt official drinking himself numb to what he signs"))
  Js.log("1.  conceive     - seed in hand")

  let dev = await begin(spark, stubWorld)
  let _offer = show(dev) /* the room shows you a world to react to */
  Js.log("2.  begin / show - the room proposes a world")

  let step = await respond(dev, Approve, stubWorld)
  let shaped = switch step {
  | Continue(_) => {
      Js.log("    (still developing - would loop here)")
      None
    }
  | Done(s) => {
      Js.log("3.  respond      - you approved; converged to `shaped`")
      Some(s)
    }
  | Stalled(_) => {
      Js.log("    (out of gas - would return to you for approval)")
      None
    }
  }

  switch shaped {
  | None => Js.log("    flow stopped in development")
  | Some(s) => {
      let developed = await finish(s)
      Js.log("4.  finish       - finishing ran; world is `developed`")

      let production = breakInto(developed, [EpisodeTitle("तौल")])
      Js.log2("5.  breakInto    - episodes:", Array.length(theEpisodes(production)))

      /* --- write one scene and run it through BOTH gates --- */
      let bible = theBible(developed)
      let brief = {
        want: Want("get the weighing slip signed tonight"),
        wall: Wall("the man who must sign it knows what it really weighs"),
        turn: Turn("he signs, but only once Ratan drinks with him"),
        present: [CharacterName("Ratan"), CharacterName("Bherulal")],
        live: [HeldCard("Sugna is the killer")],
      }
      let draft = await draftScene(brief, bible, stubWriter)
      Js.log("6.  draftScene   - a scene drafted from the brief")

      switch await gateConcept(draft, noConceptJudge) {
      | Error(_) => Js.log("    concept gate FAILED - back to the writer")
      | Ok(concept) => {
          Js.log("7.  gateConcept  - passed -> conceptCleared (the thinking)")
          let approval = approve(draft, concept)
          Js.log("8.  approve      - your yes: this is the right scene")
          switch await gateLanguage(draft, approval, noJudge) {
          | Error(_) => Js.log("    language gate FAILED - slop caught, back to the writer")
          | Ok(clean) => {
              let _scene = Shippable(draft, clean)
              Js.log("9.  gateLanguage - passed -> languageClean (the writing)")
              Js.log("10. Shippable    - the scene reaches the page")
            }
          }
        }
      }
    }
  }
  Js.log("=== done: idea -> shippable scene, every gate threaded and enforced ===")

  /* --- the language floor, now real: clean line passes, the monkey-line slop
         is rejected. Free, still no model. --- */
  Js.log("")
  Js.log("--- language floor on real lines (free; no model) ---")
  Belt.Array.forEach(
    [
      "He sees four black African monkeys jumping in the tree.",
      "Four of them. Monkeys. African. Black.",
      "The bustling bazaar stood as a testament to the town.",
      "It's not just a job to him, it's who he is.",
      "She whispered “later.”",
      "The old fort stands as a symbol of the kingdom.",
      "Nailed it 🔥",
    ],
    line =>
      switch Gate.craftlint(Gate.raw(line)) {
      | Ok(_) => Js.log("PASS   | " ++ line)
      | Error(fs) =>
        Js.log("REJECT | " ++ line ++ "   <- " ++ Js.Array2.joinWith(Belt.Array.map(fs, f => Gate.describe(f.violation)), ", "))
      },
  )

  /* --- the development phase is now metered: each `respond` burns gas, stalls
         after two rounds, and only your approval refuels it --- */
  Js.log("")
  Js.log("--- metered development (respond is gas-capped at two per refuel) ---")
  let rec untilStall = async (dev, round) =>
    switch await respond(dev, Revise(NoteText("make it harder")), stubWorld) {
    | Done(_) => dev
    | Continue(next) => {
        Js.log("  round " ++ Belt.Int.toString(round) ++ ": revised, still developing")
        await untilStall(next, round + 1)
      }
    | Stalled(stuck) => {
        Js.log("  round " ++ Belt.Int.toString(round) ++ ": OUT OF GAS -> back to you")
        stuck
      }
    }
  let stalled = await untilStall(await begin(conceive(Idea("a metered seed")), stubWorld), 1)
  Js.log("  ... you approve two more ...")
  let _ = await untilStall(approveMore(stalled, Gas.approve()), 1)

  /* --- the gate->repair loop, metered: fixable slop converges; slop the repair
         can't fix hits the gas brake and returns to you --- */
  Js.log("")
  Js.log("--- metered gate->repair loop ---")
  let demoBrief = {want: Want("x"), wall: Wall("y"), turn: Turn("z"), present: [], live: []}
  let slopDraft = {brief: demoBrief, action: [ActionLine("Four of them. Monkeys. African. Black.")], lines: [], ordered: ["Four of them. Monkeys. African. Black."]}
  let goodRepair = (d: draft, _fs): promise<draft> =>
    Js.Promise.resolve({...d, action: [ActionLine("He sees four black monkeys in the tree.")]})
  let noopRepair = (d: draft, _fs): promise<draft> => Js.Promise.resolve(d)
  switch await gateConcept(slopDraft, noConceptJudge) {
  | Error(_) => Js.log("  (concept gate failed unexpectedly)")
  | Ok(concept) => {
      let approval = approve(slopDraft, concept)
      let langGate = d => gateLanguage(d, approval, noJudge)
      switch await repairToward(slopDraft, langGate, goodRepair, Gas.perPhase) {
      | Cleared(_, _) => Js.log("  fixable slop:   repaired -> CLEARED")
      | Stuck(_, fs) => Js.log2("  fixable slop:   STUCK, findings:", Array.length(fs))
      }
      switch await repairToward(slopDraft, langGate, noopRepair, Gas.perPhase) {
      | Cleared(_, _) => Js.log("  unfixable slop: cleared")
      | Stuck(_, fs) => Js.log2("  unfixable slop: OUT OF GAS after 2 repairs -> back to you; still wrong:", Array.length(fs))
      }
    }
  }
}

main()->ignore
