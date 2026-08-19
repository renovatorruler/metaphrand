# Echo and the Broken Bonds — Runtime Test Oracle v1

Every row is release-blocking. Evidence must name the immutable `content_id`, show synchronized monotonic timestamps, and assert the evaluator snapshot plus visible state. A video or self-emitted event log without the paired assertions is insufficient.

## Oracle fields

- **Given:** exact saved/evaluator state before input.
- **Input:** pointer, touch, keyboard, wait, reload, or counterfactual action.
- **Must become:** evaluator state and visible persistent result.
- **Must never occur:** forbidden evaluator event, world state, UI action, or story advance.
- **Dwell/evidence:** minimum observation and required raw proof.

## Exhaustive lane rule

Every dynamic oracle ID in this file runs on **both** the locked local lane and locked constrained lane at `1280×720`, device scale factor 1.0. Rows that name both viewports additionally run at `1366×768`; rows that name pointer, touch, keyboard, mute, captions, grayscale, color-vision simulation, or reduced motion additionally run in every named mode. `C05` is the sole static-source row and has lane `SOURCE_ONLY`. No other `N/A`, waiver, or “not applicable” result exists unless a new frozen oracle version names the reason before the candidate is built.

## Opening, assistance, and safe attempts

The exhaustive held-decision inventory is: `CLAMP_WAIT`, `CLAMP_PARTIAL`, `REVEAL_WAIT`, `SPEED_PACK_DOCK_WAIT`, `SPEED_PACK_DEPLOY_READY`, `SHELL_PACK_DOCK_WAIT`, `SHELL_PACK_DEPLOY_READY`, `NAVIGATION_SLEEPING`, `NAVIGATION_DOCK_WAIT`, `NAVIGATION_COPY_READY`, `NESTED_READY_BOTH`, `FIRST_SIDE_RESOLVED(LEFT)`, and `FIRST_SIDE_RESOLVED(RIGHT)`. A committed transformation may finish; none of these waiting states has a time-, animation-, audio-, or cosmetic-clock computational edge.

| ID | Given | Input | Must become | Must never occur | Dwell / evidence |
|---|---|---|---|---|---|
| O01 | Clamp rattling; Echo already camouflaged; no active Power Script | Hold valid clamp target | Wobble damps within 250 ms; Echo's ordinary wrench turns | Bond, alpha/beta, stealth/detection, roster advance, player tightening | Raw 0:10 capture + state assertions |
| O02 | O01 mid-hold | Release before repair completes | Wobble returns; wrench pauses; same prompt remains | Reset, red/wrong cue, lost state, roster advance | Three early-release timings |
| O03 | O01 | Hold outside clamp / leave target | Literal no-grip response within 250 ms; target remains | Snap from distant point, hidden penalty, story advance | Pointer and touch evidence |
| O04 | Every held decision state | No input for 60 seconds | World/evaluator snapshot remains byte-identical except allowed cosmetic loop clock | Harm, auto-solve, beta, countdown, escalating distress, time-triggered outgoing computational transition | One 60 s raw soak per held-state class plus static transition-table proof |
| O05 | Any actionable held state | Wait 6±0.5 seconds | Exactly one existing relationship receives tactile/framing help | Object motion, selection, Deploy, answer text, second competing cue | Raw help capture + cue-count assertion |
| O06 | O05 | Continue waiting to second help beat | Same relationship becomes clearer | New answer, side preference, input, state change | Raw capture + snapshot diff |

## Authorized actor and non-computational canon

| ID | Given | Input / story action | Must become | Must never occur | Dwell / evidence |
|---|---|---|---|---|---|
| H01 | Clamp rattling; `NO_ACTIVE_POWER_SCRIPT`; Lulu nearby | Lulu hears, turns, and points | Ordinary clamp location becomes visually explicit; evaluator/term hash unchanged | Bond, Reveal, alpha/beta, ownership fact, automatic repair | Before/after evaluator equality + actor/event assertion |
| H02 | Roster still open; Echo has completed ordinary repair and holds loose green mark | Echo independently camouflages and hides as roster chime seals four marks | Story ledger records Echo hidden and green mark unplaced/outside; evaluator/term hash unchanged | Player-authored stealth choice, alpha/beta, membership, fifth mark placement | Continuous raw opening + story/evaluator assertions |
| H03 | Complete corrupted launch script `E0` is ready; authorized actor is Blaze | **Blaze** presses the physical launch Deploy | Exactly one beta to canonical `E1`; whole Speed Pack enters tram override; tram runaway state begins | Linkkeeper/player Deploy event, malformed term, partial pack, second beta, correct demo launch | AST before/action/after + actor ID + raw continuous launch clip |
| H04 | Echo visible; trial cable still powers score; complete Navigation Kit remains canonical `E7` | Blaze releases shared grip; Echo physically pulls cable | Trial/marker darken and kit becomes physically powered/awake; exact evaluator/term hash remains `E7` | Alpha/beta, kit repair/completion, copied occurrence, Blaze bid permanently erased | Before/after evaluator equality + cable/actor/world assertions |
| H05 | One-use result already evaluated; exoframe and brake route exist | Blaze runs/drives frame and pulls physical brake | Physical actor/world state advances to brake caught; evaluator result hash stays unchanged | New beta, autonomous exoframe, new Blaze power, player performing brake pull | Actor trace + before/after evaluator equality + raw action clip |
| H06 | Any hero locomotion, unmasking, bell ring, safety-line loop, support, or center-lock action | Canonical character action completes | Only declared physical/story ledger fields change | Alpha/beta, source movement/clearing, ownership change, sample before Tavi safe | Source event-class assertion across full run + mutation test |

## Reveal and one-use rescue

| ID | Given | Input | Must become | Must never occur | Dwell / evidence |
|---|---|---|---|---|---|
| R01 | Corrupted route; Reveal available | Hold Lens on both actual endpoints | Existing raised Bond remains lit; brake Role Spot identified; term hash unchanged | Alpha/beta, source movement, Deploy, lure fill | AST before/after equality + raw capture |
| R02 | R01 | Hold Lens on nearer same-rune lure | Lure stays unconnected and gives literal endpoint mismatch | Wrong/shame cue, lure ownership, beta | Three invalid approaches |
| R03 | Fresh complete Speed Pack and ready one-use Team-Up | Dock whole pack; release; press Deploy | Exactly one beta; source cradle empty; sole owned spot filled; exoframe result | Lure fill, second use, autonomous frame, more than one beta | AST/action/render assertions + ≤11 s raw clip |
| R04 | Speed Pack held over non-input or wrong surface | Release | Object remains attached/returns safely; ready surface absent | Beta, source loss, prior story erasure | All invalid target classes |
| R05 | Exoframe result | Observe/action | Blaze visibly drives it and physically pulls the same east brake | Exoframe autonomous rescue or new hero power | Raw action clip + world actor assertion |

## Simple repetition and whole-kit repetition

| ID | Given | Input | Must become | Must never occur | Dwell / evidence |
|---|---|---|---|---|---|
| P01 | One complete shell pack; empty two-slot harness | Drag pictured inner shell | Entire closed boundary moves | Loose component extraction or partial pack | Pointer/touch capture |
| P02 | P01 ready | Deploy once | Source empty; exactly two complete shell drones; PAIR persists; coupling remains connected | Third source/copy, missing half, erased PAIR | Object-count + AST + render assertions |
| P03 | Navigation Kit still sleeping | Touch/drag/wait before wake | Whole kit rotates in locked cradle; held story state remains | Component extraction, wake-by-wait, ready Deploy | 60 s soak + attempts |
| P04 | Complete awake Navigation Kit; empty source input | Drag any pictured inner element | Whole closed kit moves | Shell/pathfinder/beacon extraction | Every visible inner component |
| P05 | P04 ready | Deploy once | Source cradle empty; exactly two complete sealed kits; fresh distinct inner binders; PAIR persists | Third kit, shared binder, partial copy, automatic nested Deploy | AST identity ledger + rendered counts |

## Nested Deploys and counterfactual causality

| ID | Given | Input | Must become | Must never occur | Dwell / evidence |
|---|---|---|---|---|---|
| N01-L | `NESTED_READY_BOTH` | Fresh left release | Left result/clamp only; left ring flat; right kit/redex raised; PAIR persists; one-sided twist | Right beta/clamp, queued input, sample, door open | ≥2 s settled hold in raw 30 s clip |
| N01-R | `NESTED_READY_BOTH` | Fresh right release | Mirrored semantic result with separately registered world-correct right state | Left beta/clamp, runtime mirroring artifacts, sample, door open | ≥2 s settled hold in raw 30 s clip |
| N02 | First transformation running | Tap/hold opposite control repeatedly | Input acknowledged/cancelled only; no queue | Acceleration, skip, second beta, hidden opposite Deploy | Rapid-input trace and video |
| N03 | `FIRST_SIDE_RESOLVED(side)` | Touch evaluated side or PAIR | Finished route/PAIR highlights only | New Deploy or state loss | Both orders |
| N04-LR | Left-first held result | Fresh post-return right release | Right beta; both clamps/results persist; twist stops; center lock permitted | Replaying left, lost clamp, early sample | Raw clip + final AST hash |
| N04-RL | Right-first held result | Fresh post-return left release | Left beta; identical final AST/world state | Replaying right, lost clamp, order-dependent terminal | Raw clip + byte-equal convergence assertion |
| C01 | Any ready rescue redex with Deploy handler disabled by test injection | Valid release/press | No beta and no rescue world change; explicit test-only blocked state | Scripted transformation, clamp, brake, door, sample | Counterfactual integration capture |
| C02 | Test fixture substitutes a different valid evaluator snapshot ID | Render one frame/state | Renderer follows injected snapshot and displays matching owned spots/results | Original storyboard state or timer-selected visual | Snapshot-to-render integration assertion |
| C03 | Reducer returns no transition | Advance cosmetic/story clocks | Computational world projection remains unchanged | Parallel timer-driven rescue change | Mutation test + state/render hash |
| C04 | Every computational render | Compare attached transition/snapshot hash | Rendered world state's declared source hash equals current evaluator snapshot | Missing/mismatched hash or unaccounted rescue mutation | Automated assertion on every frame transition |
| C05 | Compiled transition table/state graph for every held decision state | Static graph inspection | Every computational outgoing edge requires a fresh declared player input or an already committed non-interactive story action | Timeout, animation-end, audio-end, wall-clock, or cosmetic-loop edge commits a beta/rescue transition | Machine-readable transition report + source locations; 60 s O04 soak is corroboration, not the sole proof |
| C06 | Identical content/input trace with evidence envelope present versus absent | Run full trace and all oracle checkpoints in both modes | Evaluator/event/save hashes and audio cue IDs are identical; checkpoint pixels outside diagnostic rectangle are identical | Envelope/session/nonce/mode-dependent mechanic, story, timing, asset, audio, input, or world branch | Static dependency report + byte/state diff + masked pixel diff + production-mode raw run |

## Rescue, sample, aftermath, rejoin, and accessibility

| ID | Given | Input | Must become | Must never occur | Dwell / evidence |
|---|---|---|---|---|---|
| A01 | Both clamps complete | Story action | Door opens; Tavi exits; Sunny supports/wraps; safety line loops on visible Echo | Sample before line loop | Raw continuous aftermath capture |
| A02 | A01 complete | Passive sample fires once | Transit Anchor 1 fills; sampler goes cold; rescue AST/world hashes unchanged | Alpha/beta, second sample, correctness cue, lost result | Before/after equality + one event |
| A03 | Terminal aftermath | Complete coda | Demo remains dark; bid suspended; record locked; token conditional; mark unplaced; trail to Gear Forest; Knot sees Echo with Linkkeeper | Membership, restored demo, permanently erased bid | Full-run state ledger |
| J01 | Each state named in test-envelope.md | Quit/reload/rejoin | Exact committed evaluator/world state specified in save oracle returns | Replay/skipped beta, duplicate source, backward/forward jump | One raw rejoin per state/order |
| X01 | Complete run | Mute; captions and instructional text hidden | All mechanics and six story beats remain visually reconstructable; icon/shape/tactile cues still support every input | Audio-only or text-only fact; blocked interaction; changed evaluator path | Raw silent/no-text full run + three critic scores |
| X02 | Complete run | Captions on; voice on | Line IDs, speaker, timing, and meaning match; drift ≤80 ms | Uncaptioned required line or caption-only mechanic | Full voiced run + sync log |
| X03 | Complete run | Reduced motion | Same causal states/holds/order with shorter transitions | Hidden intermediate, faster auto-step, missing consequence | Both evaluation orders |
| X04 | Both viewports | Keyboard, pointer, emulated touch | Focus visible; targets/latencies meet bar; one cue | Trap, overlap, hover-only requirement | Geometry and input logs |
| X05 | Complete run | Grayscale, then protanopia and deuteranopia simulation; captions off | All six story beats, ownership endpoints, ready/evaluated rings, source clearing, PAIR, and both nested sides remain distinguishable by shape/texture/position | Color-only cue, lost actor/side/state, alternate evaluator path | Three raw full runs + state-by-state critic checklist |
| X06 | Complete run | All nonessential written labels/prompts/captions hidden; voice remains on | Every action can be discovered and completed through world staging, icon/shape cues, and spoken support | Required reading, text-sized invisible hit target, automatic answer | Raw no-reading full run + input trace |

## Causal implementation proof

The source review must find one authoritative evaluator snapshot feeding every computational world projection. Story/cosmetic clocks may animate an already-authorized state, but cannot choose, commit, or synthesize a beta result. The release package must include an automatically generated dependency report mapping each rescue visual state to its evaluator snapshot/transition hash. Any computational visual without that mapping is an unaccounted parallel script and a hard failure.

## Exact rejoin oracle

Saving is atomic at input commit. A rejoin never re-emits the event that created the saved transition. Committed animations may resume at their saved cosmetic frame or settle directly to the required post-transition pose, but the evaluator result and object counts below are exact.

| Saved state | Required rejoin state | Forbidden on rejoin |
|---|---|---|
| `NESTED_READY_BOTH` | Same evaluator/world hash; two complete ready kits, source empty, PAIR present | Beta, chosen side, sample, door open |
| `FIRST_LEFT_DEPLOYING_COMMITTED` | `FIRST_SIDE_RESOLVED(LEFT)` with one left result/clamp, right plan complete/ready, PAIR present | Re-emitted left beta, right beta/clamp, lost source-clear history |
| `FIRST_RIGHT_DEPLOYING_COMMITTED` | `FIRST_SIDE_RESOLVED(RIGHT)` with mirrored semantic state from its authored right registration | Re-emitted right beta, left beta/clamp, runtime mirroring |
| `FIRST_SIDE_RESOLVED(LEFT)` | Byte-identical committed evaluator/world projection; fresh right input required | Auto/right beta, replay left, door open |
| `FIRST_SIDE_RESOLVED(RIGHT)` | Byte-identical committed evaluator/world projection; fresh left input required | Auto/left beta, replay right, door open |
| `SECOND_RIGHT_DEPLOYING_COMMITTED` | `TWO_CLAMPS_STORY_PENDING` with both results/clamps and PAIR; twist stopped | Re-emitted beta, lost left result, early Tavi exit/sample |
| `SECOND_LEFT_DEPLOYING_COMMITTED` | Same `TWO_CLAMPS_STORY_PENDING` evaluator/world hash as opposite order | Re-emitted beta, order-dependent result, early Tavi exit/sample |
| `TAVI_SAFE_PRE_SAMPLE` | Tavi outside/supported with line looped; navigation result unchanged; sample idempotency flag still unspent | Tavi back inside, line missing, sample already spent |
| `TERMINAL_AFTERMATH` | Exact A03 terminal ledger with sample flag spent once | Second sample, restored demo, membership, changed rescue term |
