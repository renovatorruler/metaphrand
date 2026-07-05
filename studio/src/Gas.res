@unboxed type gas = Gas(int)

let perPhase = Gas(2)

/* concrete here, abstract in Gas.resi — so only this module mints an approval,
   and a phase loop can't conjure one to keep itself alive. */
type approval = Approval
let approve = (): approval => Approval

type tank =
  | Fuel(gas)
  | Empty

let burn = (Gas(n): gas): tank => n > 0 ? Fuel(Gas(n - 1)) : Empty
let refuel = (_a: approval): gas => perPhase
