/* ============================================================================
   Gas — the attempt meter. NOT dollars (that's parked); this is *iterations*.

   A phase may run a fixed number of times on its own. When the gas runs out it
   must come back to you. The loop that burns gas cannot ignore an empty tank
   (it's a sum, and a missed case is a build error), and only YOUR approval
   refuels it — so a phase can't run away the way that 4-way batch did.
   ============================================================================ */

@unboxed type gas = Gas(int)     // runs this phase has left before it must stop

/* The default allowance: a phase runs twice on its own, then it's back to you. */
let perPhase: gas

/* Your go-ahead — abstract, so the loop can't fabricate one to keep itself
   running. It has to actually hand control back and wait for you. */
type approval
let approve: unit => approval

/* A tank is full or empty, and a caller must handle both. */
type tank =
  | Fuel(gas)      // you may run; this is the gas left afterward
  | Empty          // out of gas — stop and return to the director

let burn: gas => tank            // spend one run
let refuel: approval => gas      // ONLY your approval refills the tank
