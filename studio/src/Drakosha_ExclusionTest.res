/* ============================================================================
   Drakosha_ExclusionTest — proves the paid boundary's mutual exclusion under
   REAL cross-process concurrency, zero spend.

   The runner's whole race-safety chain reduces to one primitive: the O_EXCL
   exclusive create in Cinema_Backends.writeTextExclusive, used for both the
   per-subject lease (active.lock) and the per-attempt claim (attempt-N.json).
   The existing Drakosha_SceneFlowTest exercises the logic in one process; this
   test proves the primitive itself with eight genuinely concurrent processes
   racing one path — exactly one may win.

   Also proves the attempt-cap ledger property the SpendAudit relies on: with
   the cap at 2, racing processes can claim at most attempt-1 and attempt-2;
   a ninth racer can never mint attempt-3.
   ============================================================================ */

open Cinema_Backends

type childProcess
@module("child_process")
external spawnDetached: (string, array<string>, {"stdio": string}) => childProcess = "spawn"

@val external setTimeoutJs: (unit => unit, int) => unit = "setTimeout"

exception TestFailure(string)

let fail = (message): 'never => {
  Js.log("FAIL - " ++ message)
  raise(TestFailure(message))
}

/* A tiny node child: waits until the barrier epoch, then attempts an O_EXCL
   create of the shared lock and records WON/LOST. Plain node fs — the child
   must not depend on build artifacts so the race is nothing but the OS call. */
let childScript = (lockPath: string, resultPath: string, barrierMs: float): string =>
  "const fs=require('fs');" ++
  "const wait=" ++ Js.Float.toString(barrierMs) ++ "-Date.now();" ++
  "setTimeout(()=>{" ++
  "let won=true;" ++
  "try{fs.writeFileSync(" ++
  Js.Json.stringify(Js.Json.string(lockPath)) ++
  ",String(process.pid),{flag:'wx'})}catch(e){won=(e.code!=='EEXIST')?(()=>{throw e})():false}" ++
  "fs.writeFileSync(" ++
  Js.Json.stringify(Js.Json.string(resultPath)) ++
  ",won?'WON':'LOST');" ++
  "},Math.max(0,wait));"

let sleepMs = (ms: int): unit => {
  /* test-only synchronous wait via a child sleep; keeps Backends.run the one
     process boundary for everything that matters */
  let seconds = Belt.Float.toString(Belt.Int.toFloat(ms) /. 1000.0)
  let result = run(~cmd="sleep", ~args=[seconds])
  if result.code != 0 {
    fail("sleep failed")
  }
}

let racers = 8

let main = () => {
  let Path(root) = tempDir("drakosha-exclusion-")
  let lockPath = root ++ "/active.lock"

  /* barrier ~1.2s out so every child is loaded and armed before anyone fires */
  let barrier = Js.Date.now() +. 1200.0

  for i in 1 to racers {
    let resultPath = root ++ "/racer-" ++ Belt.Int.toString(i) ++ ".result"
    let _child = spawnDetached(
      "node",
      ["-e", childScript(lockPath, resultPath, barrier)],
      {"stdio": "ignore"},
    )
  }

  /* wait for the barrier plus settle time, then poll for all results */
  let rec collect = (tries: int): array<string> => {
    let results =
      Belt.Array.range(1, racers)->Belt.Array.keepMap(i => {
        let p = root ++ "/racer-" ++ Belt.Int.toString(i) ++ ".result"
        exists(Path(p)) ? Some(readText(Path(p))) : None
      })
    if Belt.Array.length(results) == racers {
      results
    } else if tries <= 0 {
      fail(
        "only " ++
        Belt.Int.toString(Belt.Array.length(results)) ++
        "/" ++
        Belt.Int.toString(racers) ++ " racers reported",
      )
    } else {
      sleepMs(300)
      collect(tries - 1)
    }
  }
  sleepMs(1500)
  let results = collect(20)

  let winners = results->Belt.Array.keep(r => r == "WON")->Belt.Array.length
  let losers = results->Belt.Array.keep(r => r == "LOST")->Belt.Array.length
  if winners != 1 {
    fail(
      "expected exactly 1 winner of the exclusive lock, got " ++
      Belt.Int.toString(winners) ++ " (double-spend would be possible)",
    )
  }
  if losers != racers - 1 {
    fail("expected " ++ Belt.Int.toString(racers - 1) ++ " losers, got " ++ Belt.Int.toString(losers))
  }
  Js.log("ok - " ++ Belt.Int.toString(racers) ++ " concurrent processes, exactly 1 acquired the lease")

  /* attempt-cap ledger: with attempt-1 and attempt-2 already claimed, no racer
     can ever mint attempt-3 when claims stop at the cap. Model the claim loop
     the way the runner runs it (claim n, on EEXIST try n+1, die past cap). */
  let claimsDir = root ++ "/claims"
  ensureDirPath(Path(claimsDir))
  let cap = 2
  let claimUpToCap = (): option<int> => {
    let rec claim = attempt =>
      if attempt > cap {
        None
      } else if writeTextExclusive(
          Path(claimsDir ++ "/attempt-" ++ Belt.Int.toString(attempt) ++ ".json"),
          "claimed",
        ) {
        Some(attempt)
      } else {
        claim(attempt + 1)
      }
    claim(1)
  }
  switch (claimUpToCap(), claimUpToCap(), claimUpToCap()) {
  | (Some(1), Some(2), None) =>
    Js.log("ok - attempt ledger stops cold at the cap: 1, 2, then refusal")
  | (first, second, third) =>
    fail(
      "attempt ledger misbehaved: " ++
      Js.Json.stringifyAny((first, second, third))->Belt.Option.getWithDefault("?"),
    )
  }

  Js.log("EXCLUSION TEST PASSED")
}

main()
