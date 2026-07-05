open Process

type crew = {
  write: string => promise<string>,
  judgeConcept: (conceptGate, string) => promise<option<reasonText>>,
  judgeLanguage: string => promise<array<Gate.violation>>,
  repair: (draft, array<finding>) => promise<draft>,
}

type produced =
  | Shipped(draft)
  | Blocked(array<finding>)

let produceScene = async (brief: brief, bible: bible, crew: crew, gas: Gas.gas): produced => {
  let draft = await draftScene(brief, bible, crew.write)
  switch await repairToward(draft, d => gateConcept(d, crew.judgeConcept), crew.repair, gas) {
  | Stuck(_, fs) => Blocked(fs)
  | Cleared(concept, draftC) => {
      let approval = approve(draftC, concept)
      switch await repairToward(draftC, d => gateLanguage(d, approval, crew.judgeLanguage), crew.repair, gas) {
      | Stuck(_, fs) => Blocked(fs)
      | Cleared(_clean, draftL) => Shipped(draftL)
      }
    }
  }
}

/* scenes run one at a time (never concurrently). */
let produceEpisode = async (briefs: array<brief>, bible: bible, crew: crew, gas: Gas.gas): array<produced> => {
  let rec go = async (bs: list<brief>, acc: array<produced>): array<produced> =>
    switch bs {
    | list{} => acc
    | list{b, ...rest} => {
        let p = await produceScene(b, bible, crew, gas)
        await go(rest, Belt.Array.concat(acc, [p]))
      }
    }
  await go(Belt.List.fromArray(briefs), [])
}
