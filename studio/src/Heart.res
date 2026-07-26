/* HEART - relationships as ledgers, feeling as structure (port of
   metaphrand/heart.py; the Good Wife anatomy, docs/05 sweep 2). A bond banks
   history; wounds drop its temperature; a cold bond BLOCKS plot; the state
   moves again only through a banked DEPOSIT - never through argument. Enforced
   by construction: a thaw must cite a deposit planted EARLIER on the same
   bond. Deterministic, spine order. The gate is OPT-OUT: a deliberately
   heartless piece declares it. */

@unboxed type bond = Bond(string)
let bondName = (Bond(s)) => s

type move =
  | Deposit(string) /* banks history: the figs, the tape */
  | Wound(string) /* temperature down */
  | Thaw(string) /* temperature up - MUST name a banked deposit */
  | Blocks(string) /* the cold gating plot */
  | Unlocks(string) /* the thaw paying into plot */

type entry = {beat: string, bond: bond, move: move}

type report = {
  bonds: array<string>,
  deposits: int,
  wounds: int,
  thaws: int,
  blocks: int,
  unlocks: int,
  violations: array<string>,
}

let passed = (r: report) => Belt.Array.length(r.violations) == 0

let summary = (r: report): string =>
  if Belt.Array.length(r.bonds) == 0 {
    "no bonds declared - the story has no heart layer"
  } else if !passed(r) {
    Belt.Int.toString(Belt.Array.length(r.violations)) ++ " violation(s): " ++ r.violations->Belt.Array.joinWith("; ", x => x)
  } else {
    let traffic =
      r.blocks > 0 || r.unlocks > 0
        ? ", " ++ Belt.Int.toString(r.blocks) ++ " block(s)/" ++ Belt.Int.toString(r.unlocks) ++ " unlock(s)"
        : ", no cross-traffic (decorative)"
    Belt.Int.toString(Belt.Array.length(r.bonds)) ++
    " bond(s), " ++
    Belt.Int.toString(r.deposits) ++
    " deposit(s) banked, " ++
    Belt.Int.toString(r.wounds) ++
    " wound(s), " ++
    Belt.Int.toString(r.thaws) ++
    " thaw(s) - all paid from the bank" ++
    traffic
  }

/* Walk the entries in spine order and audit every bond's ledger. */
let audit = (entries: array<entry>): report => {
  let banked: Js.Dict.t<array<string>> = Js.Dict.empty() /* bond -> deposits so far */
  let seen = []
  let violations = []
  let deposits = ref(0)
  let wounds = ref(0)
  let thaws = ref(0)
  let blocks = ref(0)
  let unlocks = ref(0)

  entries->Belt.Array.forEach(e => {
    let b = bondName(e.bond)
    if !Belt.Array.some(seen, s => s == b) {
      Js.Array2.push(seen, b)->ignore
    }
    switch e.move {
    | Deposit(name) => {
        let cur = Js.Dict.get(banked, b)->Belt.Option.getWithDefault([])
        Js.Array2.push(cur, name)->ignore
        Js.Dict.set(banked, b, cur)
        deposits := deposits.contents + 1
      }
    | Wound(_) => {
        wounds := wounds.contents + 1
        if Js.Dict.get(banked, b)->Belt.Option.getWithDefault([])->Belt.Array.length == 0 {
          Js.Array2.push(
            violations,
            "unbanked wound on '" ++ b ++ "' at " ++ e.beat ++ ": nothing was deposited before it broke",
          )->ignore
        }
      }
    | Thaw(name) => {
        thaws := thaws.contents + 1
        let bank = Js.Dict.get(banked, b)->Belt.Option.getWithDefault([])
        if !Belt.Array.some(bank, d => d == name) {
          Js.Array2.push(
            violations,
            "unbanked thaw on '" ++
            b ++
            "' at " ++
            e.beat ++
            ": '" ++
            name ++ "' was never planted earlier - a thaw must spend a deposit, not an argument",
          )->ignore
        }
      }
    | Blocks(_) => blocks := blocks.contents + 1
    | Unlocks(_) => unlocks := unlocks.contents + 1
    }
  })

  if Belt.Array.length(seen) == 0 {
    Js.Array2.push(violations, "no bonds declared - the story has no heart layer (declare bonds, or opt out explicitly)")->ignore
  }
  seen->Belt.Array.forEach(b =>
    if Js.Dict.get(banked, b)->Belt.Option.getWithDefault([])->Belt.Array.length == 0 {
      Js.Array2.push(violations, "bond '" ++ b ++ "' declared but never banked a deposit")->ignore
    }
  )
  {
    bonds: seen,
    deposits: deposits.contents,
    wounds: wounds.contents,
    thaws: thaws.contents,
    blocks: blocks.contents,
    unlocks: unlocks.contents,
    violations: violations,
  }
}

/* opt-out is a named choice, never a default */
let gate = (entries: array<entry>, ~optOut: bool=false): (bool, string) =>
  if optOut {
    (true, "heart: opted out (a named choice on the work)")
  } else {
    let r = audit(entries)
    (passed(r), summary(r))
  }
