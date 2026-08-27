/* KukuEp10_Shots.res — all 52 EP10 hero setups authored against the story
   clock. A shot declares its BEAT and its framing; Kuku_Ep10State derives what
   must be true there — गौरी's place, great/small form, the lighting clock,
   whether the ग-shape exists. A shot physically cannot omit the cow from a
   running cart: she is injected from state, and using the golden shape before
   it is forged raises at render time.

   Output: ep10prod/EP10_SHOT_PROMPTS_SPEC.md.

   Run from studio/:
     node src/KukuEp10_Shots.res.mjs                      # render the doc, generate nothing
     node src/KukuEp10_Shots.res.mjs go h01_ring_wide ... # regenerate named shots via the spec
   Regeneration backs up the existing frame as PRE_SPEC_<name>.png first. */

module P = Kuku_PromptSpec
module S = Kuku_Ep10State

@module("fs") external writeFileSync: (string, string) => unit = "writeFileSync"
@module("fs") external copyFileSync: (string, string) => unit = "copyFileSync"
@module("fs") external existsSync: string => bool = "existsSync"
type execOpts = {"encoding": string, "timeout": int}
@module("child_process")
external execFileSync: (string, array<string>, execOpts) => string = "execFileSync"
@scope("process") @val external argv: array<string> = "argv"

/* canonical recurring props — locked descriptions, deterministic across shots */
let bell = doing => P.Prop({what: "THE BELL — the bronze paper bell of the flight ring on its paper cord", doing})
let redRope = doing => P.Prop({what: "THE ROPE — the thick red paper-twine rope", doing})
let marker = doing => P.Prop({what: "A RED DISTANCE MARK — a flat red paper paving stone set FLUSH into the lane, level with the surrounding flagstones, its face smooth with the road so wheels roll straight over it", doing})
let kada = doing => P.Prop({what: "THE कड़ा — a golden paper bracelet cuff with two small blank golden medallions set into it", doing})
let shards = doing => P.Prop({what: "GLYPH-SHARDS — small jagged black broken paper shards", doing})
let doorway = doing => P.Prop({what: "THE DOORWAY — an open golden paper doorway standing between two worlds", doing})
let dog = doing => P.Prop({what: "A SMALL PAPER DOG", doing})
let towerDoor = doing => P.Prop({what: "THE TOWER DOOR — a tall closed paper stone door set into the tower", doing})
let soundRings = doing => P.Prop({what: "SOUND-RINGS — small golden paper rings of light", doing})
let lightColumns = doing => P.Prop({what: "FIVE COLUMNS of soft golden paper light", doing})
let cartProp = doing => P.Prop({what: "THE CART — the wooden paper hay cart on four wooden paper wheels, loaded with paper hay", doing})
let gaProp = doing => P.Prop({what: "THE GOLDEN SHAPE — a large solid golden-stone form: a tall curved hook opening toward the top of the lane, with a straight upright braced at its back (an abstract shape only, never writing)", doing})

/* settings come from the SET BIBLE — one geography, derived, never retyped */
module Sets = Kuku_Ep10Sets
let courtyard = Sets.setProse(Sets.Courtyard)
let lane = Sets.setProse(Sets.Lane)
let flatStone = Sets.setProse(Sets.FlatStone)
let tower = Sets.setProse(Sets.Tower)
/* a lane plate attaches only where the shot's camera matches the survey's:
   looking down the slope. Overheads, low angles and inserts stay plate-free. */
let lanePlate = y => Sets.lanePlateAt(y)
let courtyardPlate = Sets.masterPlate(Sets.Courtyard)
/* h29 is the shape's first appearance and therefore its reference */
let gaRef = [Sets.plateDir->Js.String2.replace("sets/", "stills/") ++ "h29_ga_stands.png"]

type entry = {id: string, spec: P.imageSpec, added: array<string>, derived: array<string>}

@val external raiseError: string => 'a = "globalThis.Error" /* placeholder, unused */

/* the shot builder: declares framing, derives continuity from the beat */
let mk = (
  ~id: string,
  ~beat: S.beat,
  ~scene: string,
  ~shot: P.shot,
  ~dragons: array<(P.dragonName, string)>=[],
  ~others: array<P.subject>=[],
  ~gauri: option<string>=?,
  ~cart: option<(bool, string)>=?, /* (cart bed visible, cart doing) */
  ~ga: option<string>=?, /* the golden shape — render-time error before it is forged */
  ~props: array<P.subject>=[],
  ~setting: string,
  ~at: option<float>=?, /* metres down the lane — supplies plate AND progression */
  ~cartAt: option<float>=?,
  ~plate: option<string>=?,
  ~objects: array<string>=[],
  ~lightingOverride: option<string>=?,
  ~extraRules: array<string>=[],
  ~added: array<string>=[],
  (),
): entry => {
  let derived = []
  let beatName = switch beat {
  | S.RingDrill => "RingDrill" | S.Briefing => "Briefing" | S.TowerMischief => "TowerMischief"
  | S.RopeSlips => "RopeSlips" | S.Runaway => "Runaway" | S.Braking => "Braking"
  | S.FlatSound => "FlatSound" | S.Forging => "Forging" | S.LastApproach => "LastApproach"
  | S.TheStop => "TheStop" | S.AfterStop => "AfterStop" | S.DoorwayNight => "DoorwayNight"
  | S.TowerEnd => "TowerEnd"
  }
  let _ = Js.Array2.push(derived, "story beat " ++ beatName)
  let form = S.dragonForm(beat)
  let dragonSubjects = Js.Array2.map(dragons, ((n, doing)) => P.Dragon({name: n, form, doing}))
  if Js.Array2.length(dragons) > 0 {
    let _ = Js.Array2.push(
      derived,
      "form: " ++ (form == P.Great ? "GREAT" : "small") ++ " (from the story clock)",
    )
  }
  let cartSubjects = switch cart {
  | Some((_, doing)) => [cartProp(doing)]
  | None => []
  }
  let bedVisibleAndAboard = switch cart {
  | Some((bed, _)) => bed && S.gauriAboard(beat)
  | None => false
  }
  let gauriSubjects = switch (gauri, bedVisibleAndAboard) {
  | (Some(g), _) => [P.Gauri({doing: g})]
  | (None, true) => {
      let _ = Js.Array2.push(derived, "गौरी injected aboard the cart (story state: she is in the cart from the briefing to the stop)")
      [P.Gauri({doing: "braced inside the cart"})]
    }
  | (None, false) => []
  }
  /* THE ग IS NEVER GENERATED. Devanagari from an image model is wrong every time
     and differently wrong in every frame, so the letter is composited locally
     (ep10prod/ga_composite.mjs) onto a deliberately EMPTY stone. A shot that
     features it therefore asks for clear ground and records that it needs the
     composite pass. */
  let gaSubjects = []
  let extraRules = switch ga {
  | Some(_) =>
    if !S.gaExists(beat) {
      Js.Exn.raiseError("CONTINUITY ERROR in " ++ id ++ ": the golden ग-shape does not exist before the forging beat")
    } else {
      let _ = Js.Array2.push(derived, "ग COMPOSITED LOCALLY — generated frame must leave the stone empty")
      Js.Array2.concat(
        [
          "THE FLAT STONE IS BARE: plain smooth paper stone, clearly lit, open room above it — at this moment of the story the stone carries only itself.",
        ],
        extraRules,
      )
    }
  | None => extraRules
  }
  /* a lane position supplies its own plate and its own progression sentence */
  let plate = switch (plate, at) {
  | (Some(p), _) => Some(p)
  | (None, Some(a)) => Some(Sets.lanePlateAt(a))
  | (None, None) => None
  }
  let extraRules = switch at {
  | Some(a) => {
      let _ = Js.Array2.push(derived, "lane position " ++ Belt.Float.toString(a) ++ " m — plate and progression derived")
      let _ = Js.Array2.push(
        derived,
        "cart clock " ++
        Belt.Float.toString(switch cartAt {
        | Some(c) => c
        | None => a
        }) ++ " m",
      )
      Js.Array2.concat(
        Js.Array2.length(dragons) > 0 && form == P.Great
          ? [Sets.lanePosition(a, cartAt), Sets.greatFormStaging, Sets.greatFormFraming]
          : [Sets.lanePosition(a, cartAt)],
        extraRules,
      )
    }
  | None => extraRules
  }
  switch plate {
  | Some(p) => Js.Array2.push(derived, "SET PLATE attached: " ++ p)->ignore
  | None => ()
  }
  let lighting = switch lightingOverride {
  | Some(l) => l
  | None => {
      let _ = Js.Array2.push(derived, "lighting from the dusk clock")
      S.lighting(beat)
    }
  }
  {
    id,
    spec: {
      scene,
      shot,
      subjects: Js.Array2.concatMany(dragonSubjects, [others, gauriSubjects, cartSubjects, gaSubjects, props]),
      setting,
      lighting,
      plate,
      objects,
      extraRules,
    },
    added,
    derived,
  }
}

let allFiveRow = doing => [
  (P.Kuku, "stands at the far left of the row, " ++ doing),
  (P.Fyuria, "stands second from left in the row, " ++ doing),
  (P.Leda, "stands at the center of the row, " ++ doing),
  (P.Castor, "stands second from right in the row, " ++ doing),
  (P.Vesper, "stands at the far right of the row, " ++ doing),
]

let shots: array<entry> = [
  /* — RingDrill — */
  mk(
    ~id="h01_ring_wide",
    ~beat=RingDrill,
    ~scene="Scene 0 opening — the five stand before the flight ring for the evening drill.",
    ~shot=P.Wide,
    ~dragons=allFiveRow("on the courtyard flagstones, facing the flight ring"),
    ~setting=courtyard ++ ", dusk paper clouds above",
    ~plate=courtyardPlate,
    ~added=["the five enumerated by name, color and row order — the prose said only \"five towering paper dragon children\""],
    (),
  ),
  mk(
    ~id="h02_rishi_teach",
    ~beat=RingDrill,
    ~scene="ऋषि opens the drill with instructions.",
    ~shot=P.Medium,
    ~others=[P.RishiMuni({doing: "stands at the edge of the flight courtyard, staff planted on the flagstones, one hand raised mid-instruction; the flight ring soft behind him"})],
    ~setting=courtyard ++ ",
    ~plate=courtyardPlate, a real outdoor place",
    (),
  ),
  mk(
    ~id="h03_furia_mark",
    ~beat=RingDrill,
    ~scene="फ्यूरिया is first up, on her mark.",
    ~shot=P.CloseMedium,
    ~dragons=[(P.Fyuria, "stands eager on her marked flagstone, wings half-raised, chin lifted")],
    ~setting=courtyard,
    ~plate=courtyardPlate,
    ~added=["lighting (none in the prose)"],
    (),
  ),
  mk(
    ~id="h04_launch",
    ~beat=RingDrill,
    ~scene="फ्यूरिया launches through the ring.",
    ~shot=P.WideLow,
    ~dragons=[(P.Fyuria, "launches straight out through the inverted paper stone ring, wings at full stretch, paper dust curling from the flagstones")],
    ~setting=courtyard,
    ~plate=courtyardPlate,
    ~added=["lighting (none in the prose)"],
    (),
  ),
  mk(
    ~id="h05_bell_touch",
    ~beat=RingDrill,
    ~scene="Her pass rings the bell.",
    ~shot=P.Close,
    ~props=[bell("hanging from its short bronze hook on the inside of the flight ring's crown, caught mid-swing from a passing touch, a curl of paper dust drifting where a claw just left frame")],
    ~setting="the crown of the great stone flight ring, its layered paper stone curving through frame, dusk sky of layered paper clouds behind",
    ~plate=courtyardPlate,
    (),
  ),
  mk(
    ~id="h06_landing_paw",
    ~beat=RingDrill,
    ~scene="फ्यूरिया lands a claw past her mark.",
    ~shot=P.Medium,
    ~dragons=[(P.Fyuria, "has landed on her marked flagstone, wings still open and settling, one hind claw scuffed just past the mark, paper dust in the air")],
    ~setting=courtyard,
    ~plate=courtyardPlate,
    ~added=["lighting (none in the prose)"],
    (),
  ),
  mk(
    ~id="h45_leda_watch_ring",
    ~beat=RingDrill,
    ~scene="लेडा keeps her eyes on the mark.",
    ~shot=P.Medium,
    ~dragons=[(P.Leda, "stands on the courtyard flagstones, head lifted and turned up to the right, watching the sky intently — the calm one who keeps her eyes on the mark")],
    ~setting=courtyard ++ ",
    ~plate=courtyardPlate, the inverted stone flight ring soft behind her",
    (),
  ),
  mk(
    ~id="h51_gauri_grazing",
    ~beat=RingDrill,
    ~scene="गौरी grazing near the lane — the calm before.",
    ~shot=P.Medium,
    ~gauri="grazing calmly on paper grass, unhurried, her bell hanging still",
    ~setting="the grass verge beside the gurukul courtyard, the lane beyond",
    ~added=["ENTIRE SPEC rebuilt — the original prompt existed only in a wiped scratchpad"],
    ~plate=Sets.masterPlate(Sets.GrassVerge),
    (),
  ),
  mk(
    ~id="h52_gauri_hay_cart",
    ~beat=RingDrill,
    ~scene="गौरी helps herself to the hay.",
    ~shot=P.Medium,
    ~gauri="standing beside the cart, stretching her neck up into it, pulling out a mouthful of paper hay",
    ~cart=(true, "standing tethered at the top of the slope"),
    ~props=[redRope("tying it to the stone post")],
    ~setting=lane,
    ~plate=Sets.lanePlateAt(4.0),
    ~added=["ENTIRE SPEC rebuilt — the original prompt existed only in a wiped scratchpad"],
    (),
  ),
  /* — Briefing (गौरी aboard from here) — */
  mk(
    ~id="h07_cart_tethered",
    ~beat=Briefing,
    ~scene="ऋषि's safety briefing — the tethered cart, the rope, the markers, the flat, the wall.",
    ~shot=P.Wide,
    ~gauri="stands in the cart eating the paper hay",
    ~cart=(true, "stands at the top of the slope"),
    ~props=[redRope("ties the cart to a stone post, knotted thick")],
    ~setting=lane,
    ~plate=Sets.lanePlateAt(4.0),
    ~added=["lighting (none in the prose)"],
    (),
  ),
  mk(
    ~id="h08_gauri_close",
    ~beat=Briefing,
    ~scene="गौरी, introduced.",
    ~shot=P.Close,
    ~gauri="chewing paper hay, calm, dark paper eyes",
    ~setting="beside the hay cart at the top of the lane",
    ~added=["lighting and setting (the prose was only \"CLOSE\" plus the cow)"],
    ~plate=Sets.lanePlateAt(4.0),
    (),
  ),
  mk(
    ~id="h09_rishi_boon",
    ~beat=Briefing,
    ~scene="ऋषि's solemn warning — चील's boon.",
    ~shot=P.Medium,
    ~others=[P.RishiMuni({doing: "speaks gravely to camera-left, staff in both hands — the moment of a solemn warning"})],
    ~setting=courtyard,
    ~plate=courtyardPlate,
    ~lightingOverride="dusk light warm on his paper robes — warm golden dusk, the last golden evening",
    (),
  ),
  /* A dedicated WIDE for the ring drill. The old start frame (h04_launch) was a
     low angle tight on the ring, so a clip begun there had no courtyard to hold
     on to and invented a rocky plateau. This one contains the whole drill path
     ऋषि describes — mark, ring, bell — with air around it. */
  mk(
    ~id="h53_ring_drill_wide",
    ~beat=RingDrill,
    ~scene="The whole flight drill laid out: फ्यूरिया waits on her mark and the ring stands ahead of her with the bronze bell hanging inside it.",
    ~shot=P.Wide,
    ~dragons=[(P.Fyuria, "stands ON THE CENTRE OF THE LAUNCH CIRCLE — the concentric rings of flagstones in the courtyard floor, exactly where the reference image has them — wings half-raised and chin lifted, facing the ring — small in the frame, with a great deal of open courtyard and sky around her")],
    ~setting=Sets.setProseFor(Sets.Courtyard, ["LAUNCH CIRCLE", "FLIGHT RING"]),
    ~plate=courtyardPlate,
    ~extraRules=[
      "SIZE IN THE WORLD AND SIZE IN THE FRAME ARE TWO DIFFERENT THINGS. She is still enormous compared with the flagstones she stands on — and the VIEWPOINT IS VERY FAR AWAY, so she appears SMALL in this picture: at most a QUARTER of the frame's height, a distant figure in a large space.",
      "FRAME THIS VERY WIDE AND FROM FAR BACK: the marked flagstone and the whole ring, bell included, are visible at once, well clear of the frame edges, with a broad band of sky above and open flagstones between them. Each sits whole inside the frame.",
      "leave enough empty air in the frame for her to fly from the mark, up through the ring and back again while staying inside the picture.",
      "she stands where the launch circle already is in the reference image; the ring stands beyond it, with clear flying space between and above them.",
      "THE BELL HANGS FROM THE RING ITSELF: a bronze bell on a short hook fixed to the inside of the ring's crown, hanging down into the opening she must fly through — the bell belongs to this ring alone.",
      "the viewpoint is at courtyard level, level with the ground, looking straight across the courtyard",
      "THE RING IS TURNED THREE-QUARTERS TO THE VIEWPOINT, seen obliquely as an ellipse, so its opening reads clearly as a HOLE IN SPACE with a near rim and a far rim, and the courtyard behind it stays visible through the opening. This is what makes flying THROUGH it readable.",
      "फ्यूरिया stands on the near side of the ring, so the flight path runs from camera-near, through the opening, and away to the far side",
    ],
    ~added=["a wide drill-stage frame; the old start frame was too tight for the action to happen inside it"],
    (),
  ),
  /* — TowerMischief — */
  mk(
    ~id="h10_cheel_tower",
    ~beat=TowerMischief,
    ~scene="चील watches the courtyard from her tower.",
    ~shot=P.Medium,
    ~others=[P.Cheel({doing: "perches on the parapet of the closed paper stone tower, wings folded, head turned down toward the courtyard"})],
    ~props=[shards("scattered near her talons on the parapet")],
    ~setting=tower,
    ~plate=Sets.masterPlate(Sets.Tower),
    ~added=["lighting refined from plain \"dusk\" to the cool-tower doctrine"],
    (),
  ),
  mk(
    ~id="h11_shards_close",
    ~beat=TowerMischief,
    ~scene="What चील broke — the glyph-shards.",
    ~shot=P.Close,
    ~props=[shards("lying on weathered paper stone, catching the last dusk light")],
    ~setting="the weathered stone of the tower parapet",
    ~plate=Sets.masterPlate(Sets.Tower),
    (),
  ),
  /* — RopeSlips — */
  mk(
    ~id="h12_rope_slip",
    ~beat=RopeSlips,
    ~scene="The knot gives — the cart is loose.",
    ~shot=P.Close,
    /* the old frame showed a rope already SNAPPED — frayed ends, no load. The
       beat is a knot slipping under tension, so the rope must be whole and taut,
       running out of frame to the cart it is holding. */
    ~props=[redRope("wrapped in three tight turns around the weathered stone post and knotted, WHOLE AND UNBROKEN, drawn bar-tight and straining under load; it runs out of the RIGHT of frame toward the cart it holds")],
    ~setting=Sets.setProseFor(Sets.Lane, ["STONE POST", "CART START"]),
    ~extraRules=[
      "the rope is INTACT along its whole visible length — a continuous twisted paper cord with clean edges, every strand whole and wound tight from end to end",
      "frame close on the post and knot, but keep enough of the paper flagstones and the low kerb beneath to place this at the head of the lane",
      "the rope leaves the frame at the RIGHT still under tension, going to the cart out of shot",
    ],
    ~added=["time-of-day (the prose said only \"fibres catching light\")"],
    ~plate=Sets.lanePlateAt(4.0),
    (),
  ),
  mk(
    ~id="h13_bell_taken",
    ~beat=RopeSlips,
    ~scene="चील takes the bell.",
    ~shot=P.Medium,
    /* the old frame was the AFTERMATH — bell already taken, already airborne, cord
   already cut — so a clip begun there had nothing left to do. This is the
   instant BEFORE: still perched, bell still hanging, binding still whole. */
    ~others=[P.Cheel({doing: "perched on the crown of the great stone flight ring, leaning down with her beak and one talon to the bell's bronze binding, wings half-raised and ready — the bell still hangs whole beneath her"})],
    ~props=[bell("still hanging from the crown of the arch on its whole, uncut binding, directly beneath her")],
    ~setting=Sets.setProseFor(Sets.Courtyard, ["FLIGHT RING"]),
    ~plate=courtyardPlate,
    ~extraRules=[
      "the bell hangs untouched from the arch and its binding is WHOLE — this is the moment before the theft",
      "FRAME ON THE FLIGHT RING: the great ring fills most of the frame, complete inside the frame with air on every side, the bronze bell hanging from the inside of its crown down into the opening",
      "चील is perched ON THE CROWN OF THE RING directly above the bell, small against it — the ring is fourteen metres across and she is a bird",
      "leave clear sky above the ring for her to rise into",
    ],
    (),
  ),
  mk(
    ~id="h14_furia_choice",
    ~beat=RopeSlips,
    ~scene="फ्यूरिया chooses the cart over the chase.",
    ~shot=P.Close,
    ~dragons=[(P.Fyuria, "hovers, turned away from the open sky and looking down toward the courtyard, jaw set, wings beating")],
    ~setting="the sky over the courtyard",
    ~added=["lighting (none in the prose)"],
    ~plate=courtyardPlate,
    (),
  ),
  /* — Runaway — */
  mk(
    ~id="h15_cart_runs",
    ~beat=Runaway,
    ~scene="The cart runs — गौरी aboard.",
    ~shot=P.WideAction,
    ~gauri="braced frightened inside the rolling cart",
    ~cart=(true, "rolls fast down the slope, paper hay flying"),
    ~props=[redRope("loose, trailing behind the cart")],
    ~setting=lane,
    ~at=6.0,
    ~cartAt=4.0,
    
    ~added=["lighting (none in the prose)"],
    (),
  ),
  mk(
    ~id="h16_five_flank",
    ~beat=Runaway,
    ~scene="The five give chase in formation.",
    ~shot=P.Wide,
    ~dragons=[
      (P.Fyuria, "flies out ahead of the cart, lowest and fastest"),
      (P.Kuku, "flies on the left flank of the cart, low"),
      (P.Leda, "flies on the right flank, head turned down to the lane, calling"),
      (P.Castor, "flies tight beside the cart"),
      (P.Vesper, "flies highest, above the group"),
    ],
    ~cart=(true, "runs down the slope below them"),
    ~setting=lane,
    ~at=16.0,
    ~cartAt=8.0,
    
    ~added=["per-dragon flight positions — the prose said only \"five towering paper dragons fly alongside and above\""],
    (),
  ),
  mk(
    ~id="h17_group_lift",
    ~beat=Runaway,
    ~scene="The failed lift — front wheels up, back wheels down.",
    ~shot=P.WideLow,
    ~dragons=[
      (P.Kuku, "grips the cart's front-left wheel and strains upward"),
      (P.Fyuria, "grips the cart's front-right wheel and strains upward"),
      (P.Castor, "grips the cart's rear-left wheel and strains upward"),
      (P.Leda, "grips the cart's rear-right wheel and strains upward"),
      (P.Vesper, "grips the cart's center rail from above and strains upward"),
    ],
    ~gauri="sliding inside the tilting cart",
    ~cart=(true, "its front wheels lifted while the back stay down, the cart twisting"),
    ~setting=lane,
    ~at=19.0,
    ~cartAt=10.0,
    ~added=["per-dragon grip positions and lighting (the prose had neither)"],
    (),
  ),
  mk(
    ~id="h18_cow_slips",
    ~beat=Runaway,
    ~scene="गौरी loses her footing.",
    ~shot=P.Close,
    ~gauri="losing footing inside the tilting cart, legs braced, paper hay scattering",
    ~cart=(true, "tilting mid-lift"),
    ~setting=lane,
    ~at=19.0,
    ~cartAt=11.0,
    ~added=["lighting (none in the prose)"],
    (),
  ),
  mk(
    ~id="h19_wheels_return",
    ~beat=Runaway,
    ~scene="The lift is abandoned — wheels back down.",
    ~shot=P.Close,
    /* the bed IS in shot at this framing — claiming otherwise is what let the
       cart run empty through the middle of the chase */
    ~cart=(true, "its four wooden wheels settling back onto the flagstone lane, dust puffing, the cart righting"),
    ~setting=lane,
    ~at=21.0,
    ~cartAt=13.0,
    ~added=["lighting (none in the prose)"],
    (),
  ),
  mk(
    ~id="h46_leda_calls_lane",
    ~beat=Runaway,
    ~scene="लेडा calls the lane.",
    ~shot=P.MediumWide,
    ~dragons=[(P.Leda, "flies low alongside the downhill lane, head turned down to the lane, mouth open calling instructions, one wing dipped toward the ground")],
    ~setting=lane,
    ~at=14.0,
    ~cartAt=6.0,
    (),
  ),
  /* — Braking — */
  mk(
    ~id="h20_furia_brake",
    ~beat=Braking,
    ~scene="फ्यूरिया air-brakes the cart.",
    ~shot=P.Wide,
    ~dragons=[(P.Fyuria, "flies backwards ahead of the running cart, wings pushing air against it")],
    ~cart=(true, "running, its nose just behind her"),
    ~setting=lane,
    ~at=26.0,
    ~cartAt=15.0,
    
    ~added=["lighting (none in the prose)"],
    (),
  ),
  mk(
    ~id="h21_vesper_above",
    ~beat=Braking,
    ~scene="वैस्पर calls the lane from above.",
    ~shot=P.HighWide,
    ~dragons=[(P.Vesper, "hovers high over the lane, calling down")],
    ~cart=(true, "small below on the lane between the markers"),
    ~setting=lane,
    ~at=26.0,
    ~cartAt=17.0,
    ~added=["lighting (none in the prose)"],
    (),
  ),
  mk(
    ~id="h22_castor_calm",
    ~beat=Braking,
    ~scene="कैस्टर keeps गौरी calm.",
    ~shot=P.Medium,
    ~dragons=[(P.Castor, "flies ALONG the lane directly above and behind the cart, his long body and tail stretching back UP the slope behind him and fully inside the lane, wings swept back and held high above the kerb line. Only his head and neck come down toward the frightened cow. He is turned nose-forward down the lane, his whole length in line with it, and his tail runs back along the open lane through clear air, between the kerbs the whole way")],
    ~gauri="frightened in the cart, looking up at him",
    ~cart=(true, "running"),
    ~setting=lane,
    ~at=28.0,
    ~cartAt=19.0,
    ~added=["lighting (none in the prose)"],
    (),
  ),
  mk(
    ~id="h23_marker_pass",
    ~beat=Braking,
    ~scene="The first marker flashes past.",
    ~shot=P.Close,
    ~props=[marker("set into the flagstone lane as wooden paper wheels rush past it, dust lifting")],
    ~setting=lane,
    ~at=24.0,
    ~cartAt=24.0,
    ~added=["lighting (none in the prose)"],
    (),
  ),
  mk(
    ~id="h24_kuku_breath_fail",
    ~beat=Braking,
    ~scene="कुकु's breath scatters into shapeless golden wisps, and the flat stone stays bare.",
    ~shot=P.Medium,
    ~dragons=[(P.Kuku, "exhales a thin golden paper-cut breath that scatters and dies in the air, his expression startled")],
    ~setting=lane,
    ~at=30.0,
    ~cartAt=26.0,
    ~added=["lighting (none in the prose)"],
    (),
  ),
  mk(
    ~id="h47_leda_warns",
    ~beat=Braking,
    ~scene="लेडा's warning.",
    ~shot=P.Close,
    ~dragons=[(P.Leda, "head and shoulders, wings raised behind her, expression sharp with warning, calling out")],
    ~setting=lane,
    ~at=30.0,
    ~cartAt=25.0,
    ~lightingOverride="golden dusk light across her lilac paper scales",
    (),
  ),
  /* — FlatSound — */
  mk(
    ~id="h25_leda_knock",
    ~beat=FlatSound,
    ~scene="लेडा raps the flat stone and listens.",
    ~shot=P.Medium,
    ~dragons=[(P.Leda, "lands on the flat paper stone at the bottom of the lane and raps the stone once with a claw, listening")],
    ~setting=flatStone,
    ~plate=Sets.masterPlate(Sets.FlatStone),
    ~at=50.0,
    ~cartAt=27.0,
    ~added=["lighting (none in the prose)"],
    (),
  ),
  mk(
    ~id="h26_tings",
    ~beat=FlatSound,
    ~scene="The stone answers — the ting.",
    ~shot=P.CloseAbstract,
    ~props=[soundRings("rippling outward above a paper flagstone — the visual echo of a sound")],
    ~setting=flatStone,
    ~plate=Sets.masterPlate(Sets.FlatStone),
    ~at=50.0,
    ~cartAt=28.0,
    ~lightingOverride="deep dusk; the golden rings are the brightest thing in frame",
    (),
  ),
  mk(
    ~id="h27_kuku_hears",
    ~beat=FlatSound,
    ~scene="कुकु hears it — recognition.",
    ~shot=P.Close,
    ~dragons=[(P.Kuku, "his face lit gold from below, eyes wide with recognition, listening hard")],
    ~setting=flatStone,
    ~plate=Sets.masterPlate(Sets.FlatStone),
    ~at=50.0,
    ~cartAt=29.0,
    ~lightingOverride="deep dusk; the golden ting-light from below is the brightest thing on his face",
    (),
  ),
  mk(
    ~id="h48_leda_counts",
    ~beat=FlatSound,
    ~scene="लेडा counts the timing.",
    ~shot=P.Medium,
    ~dragons=[(P.Leda, "hovers steady above the flat paper stone at the bottom of the lane, one foreclaw raised as if marking a beat, eyes fixed forward, counting")],
    ~setting=flatStone,
    ~plate=Sets.masterPlate(Sets.FlatStone),
    ~at=50.0,
    ~cartAt=30.0,
    ~added=["lighting (none in the prose)"],
    (),
  ),
  /* — Forging — */
  mk(
    ~id="h28_forging",
    ~beat=Forging,
    ~scene="The forging — कुकु pours the ग onto the flat stone.",
    ~shot=P.Wide,
    ~dragons=[
      (P.Kuku, "exhales a broad stream of golden paper light onto the flat paper stone at the bottom of the lane"),
      (P.Fyuria, "stands behind him, wings raised"),
      (P.Leda, "stands behind him, wings raised"),
      (P.Castor, "stands behind him, wings raised"),
      (P.Vesper, "stands behind him, wings raised"),
    ],
    ~setting=flatStone,
    ~plate=Sets.masterPlate(Sets.FlatStone),
    ~at=52.0,
    ~cartAt=31.0,
    ~added=["the four watching dragons enumerated by name (prose: \"the four other towering dragons\")"],
    (),
  ),
  mk(
    ~id="h29_ga_stands",
    ~beat=Forging,
    ~scene="The golden shape stands, braced against the wall.",
    ~shot=P.Wide,
    ~ga="stands newly forged on the flat stone at the end of the lane, its open hook-curve facing up the lane, its upright braced against the paper stone wall",
    ~setting=flatStone,
    ~plate=Sets.masterPlate(Sets.FlatStone),
    ~at=55.0,
    ~cartAt=32.0,
    ~lightingOverride="deep dusk; the golden shape catches the last light",
    (),
  ),
  mk(
    ~id="h30_bracelets",
    ~beat=Forging,
    ~scene="The कड़ा glows — the letter is earned.",
    ~shot=P.Close,
    ~dragons=[(P.Castor, "only his forearm in frame, wearing the कड़ा")],
    ~props=[kada("on his forearm, glowing warm, its two blank medallions catching the glow")],
    ~setting=flatStone,
    ~plate=Sets.masterPlate(Sets.FlatStone),
    ~at=55.0,
    ~cartAt=32.5,
    ~lightingOverride="deep dusk; the bracelet's warm glow lights the frame",
    ~added=["whose forearm it is (prose said \"a paper dragon's forearm\")"],
    (),
  ),
  /* — LastApproach — */
  mk(
    ~id="h31_vesper_yawn",
    ~beat=LastApproach,
    ~scene="वैस्पर's yawn — the watch slips.",
    ~shot=P.Medium,
    ~dragons=[(P.Vesper, "high above the lane mid-yawn, eyes half shut, wings slack for an instant")],
    ~setting=lane,
    ~at=34.0,
    ~cartAt=33.0,
    ~added=["lighting (none in the prose)"],
    (),
  ),
  mk(
    ~id="h32_cart_drifts",
    ~beat=LastApproach,
    ~scene="The cart drifts toward the kerb.",
    ~shot=P.Wide,
    ~cart=(true, "drifting toward the left edge of the lane, one wheel near the paper kerb, dust streaming"),
    ~setting=lane,
    ~at=35.0,
    ~cartAt=34.0,
    
    ~added=["lighting (none in the prose)"],
    (),
  ),
  mk(
    ~id="h33_cheel_flyover",
    ~beat=LastApproach,
    ~scene="चील taunts them with the bell.",
    ~shot=P.Wide,
    ~others=[P.Cheel({doing: "sweeps low over the running cart with the bronze bell in her talons, wings wide, taunting"})],
    ~cart=(true, "running below her"),
    ~props=[bell("in her talons")],
    ~setting=lane,
    ~at=38.0,
    ~cartAt=34.5,
    
    ~added=["lighting (none in the prose)"],
    (),
  ),
  mk(
    ~id="h34_furia_refuses",
    ~beat=LastApproach,
    ~scene="फ्यूरिया refuses the bait again.",
    ~shot=P.Close,
    ~dragons=[(P.Fyuria, "looks away from the departing eagle and back down at the cart below, jaw set, refusing")],
    ~setting=lane,
    ~at=39.0,
    ~cartAt=35.0,
    ~added=["lighting (none in the prose)"],
    (),
  ),
  /* — TheStop — */
  mk(
    ~id="h35_last_marker",
    ~beat=TheStop,
    ~scene="The third marker — the flat and the shape ahead.",
    ~shot=P.Close,
    ~props=[marker("the THIRD red marker, under rushing wooden paper wheels")],
    ~ga="visible ahead on the flat stretch",
    ~setting=lane,
    ~at=36.0,
    ~cartAt=36.0,
    ~added=["lighting (none in the prose)"],
    ~objects=gaRef,
    (),
  ),
  mk(
    ~id="h36_three_beats",
    ~beat=TheStop,
    ~scene="फ्यूरिया's three deliberate beats.",
    ~shot=P.Wide,
    ~dragons=[(P.Fyuria, "holds ahead of the slowing cart, wings in one deep deliberate beat, paper dust rolling")],
    ~cart=(true, "slowing behind her"),
    ~setting=lane,
    ~at=44.0,
    ~cartAt=42.0,
    
    ~added=["lighting (none in the prose)"],
    (),
  ),
  mk(
    ~id="h37_cart_into_curve",
    ~beat=TheStop,
    ~scene="The cart rides into the golden curve.",
    ~shot=P.Wide,
    ~gauri="steady inside the cart",
    ~cart=(true, "its nose riding up into the open curve of the golden shape, wheels almost stopped"),
    ~ga="cradling the cart's nose",
    ~setting=flatStone,
    ~plate=Sets.masterPlate(Sets.FlatStone),
    ~at=55.0,
    ~cartAt=54.0,
    ~added=["lighting (none in the prose)"],
    ~objects=gaRef,
    (),
  ),
  mk(
    ~id="h38_stopped",
    ~beat=TheStop,
    ~scene="Stopped. Safe.",
    ~shot=P.Wide,
    ~gauri="calm in the cart",
    ~cart=(true, "at rest, cradled in the curve of the golden shape, dust settling"),
    ~ga="holding the cart",
    ~setting=flatStone,
    ~plate=Sets.masterPlate(Sets.FlatStone),
    ~at=55.0,
    ~cartAt=55.0,
    ~objects=gaRef,
    (),
  ),
  mk(
    ~id="h49_leda_relief",
    ~beat=TheStop,
    ~scene="लेडा lets go — relief.",
    ~shot=P.Medium,
    ~dragons=[(P.Leda, "stands on the flagstones with wings folded and shoulders dropped in relief, a tired warm smile")],
    ~setting=courtyard,
    ~plate=courtyardPlate,
    ~lightingOverride="evening light low behind her — soft warm afterglow",
    (),
  ),
  /* — AfterStop (small forms, गौरी out of the cart) — */
  mk(
    ~id="h39_shrink_glow",
    ~beat=AfterStop,
    ~scene="The five shrink back to small — seen only as light.",
    ~shot=P.WideAbstract,
    ~props=[lightColumns("standing alone on the courtyard flagstones where the five dragons were, paper clouds behind")],
    ~setting=courtyard,
    ~plate=courtyardPlate,
    (),
  ),
  mk(
    ~id="h40_small_five_sit",
    ~beat=AfterStop,
    ~scene="Small again, sitting with गौरी.",
    ~shot=P.Wide,
    ~dragons=allFiveRow("sitting quietly on the flagstones near the stopped cart"),
    ~gauri="standing closer to them now",
    ~cart=(false, "stopped nearby"),
    ~setting=flatStone,
    ~plate=Sets.masterPlate(Sets.FlatStone),
    ~added=["the five named with a row order (prose: \"five small paper dragon children\"); NOTE: no small character sheet exists for Vesper — his design rides on the color law alone"],
    (),
  ),
  mk(
    ~id="h41_castor_in_hay",
    ~beat=AfterStop,
    ~scene="कैस्टर in the hay, laughing.",
    ~shot=P.Medium,
    ~dragons=[(P.Castor, "sitting down in a heap of paper hay, laughing")],
    ~gauri="her nose near him",
    ~setting=flatStone,
    ~plate=Sets.masterPlate(Sets.FlatStone),
    ~added=["lighting (none in the prose)"],
    (),
  ),
  mk(
    ~id="h50_leda_small_sits",
    ~beat=AfterStop,
    ~scene="Small लेडा watches, patient.",
    ~shot=P.Medium,
    ~dragons=[(P.Leda, "sits quietly on the paper flagstones near the wooden cart, wings folded, watching something gently and patiently")],
    ~cart=(false, "stopped nearby"),
    ~setting=flatStone,
    ~plate=Sets.masterPlate(Sets.FlatStone),
    (),
  ),
  /* — DoorwayNight — */
  mk(
    ~id="h42_doorway_dadi",
    ~beat=DoorwayNight,
    ~scene="दादी at the doorway between the worlds.",
    ~shot=P.Medium,
    ~others=[P.Dadi({doing: "stands in the courtyard beyond the doorway, concerned"})],
    ~props=[doorway("open at dusk; through it a village paper courtyard"), dog("beside her")],
    ~setting="the threshold between the dragon world and the village world",
    ~added=["lighting refined from plain \"dusk\" to the cool-doorway doctrine"],
    ~plate=Sets.masterPlate(Sets.Doorway),
    (),
  ),
  mk(
    ~id="h43_vesper_asleep",
    ~beat=DoorwayNight,
    ~scene="वैस्पर asleep beside the doorway.",
    ~shot=P.Close,
    ~dragons=[(P.Vesper, "asleep with his head resting on a blue paper cushion, breathing slow")],
    ~props=[doorway("glowing softly beside him")],
    ~setting="beside the glowing doorway",
    ~added=["IDENTITY FIX: the original prompt attached कुकु's small sheet and said only \"a small paper dragon child\" for a वैस्पर shot; NOTE: no small Vesper sheet exists"],
    ~plate=Sets.masterPlate(Sets.Doorway),
    (),
  ),
  /* — TowerEnd — */
  mk(
    ~id="h44_tower_door",
    ~beat=TowerEnd,
    ~scene="चील before the tower door as it grinds open a hair.",
    ~shot=P.Medium,
    ~others=[P.Cheel({doing: "stands before the tall closed paper stone door, the bronze bell at her talons"})],
    ~props=[bell("at her talons"), towerDoor("beginning to grind open a hair's width, darkness beyond")],
    ~setting=tower,
    ~plate=Sets.masterPlate(Sets.Tower),
    ~added=["lighting (none in the prose)"],
    (),
  ),
]

/* ---- render the review document ------------------------------------------- */
let withAdded = Js.Array2.filter(shots, e => Js.Array2.length(e.added) > 0)

let entryMd = e => {
  let addedBlock =
    Js.Array2.length(e.added) == 0
      ? "*clean port — every fact was already in the original prompt*"
      : "**ADDED:**\n" ++ Js.Array2.joinWith(Js.Array2.map(e.added, a => "- " ++ a), "\n")
  let derivedBlock =
    Js.Array2.length(e.derived) == 0
      ? ""
      : "\n**DERIVED FROM STORY STATE:**\n" ++
        Js.Array2.joinWith(Js.Array2.map(e.derived, a => "- " ++ a), "\n")
  let refs = Js.Array2.joinWith(P.imageRefs(e.spec), "\n  - ")
  "## " ++
  e.id ++
  "\n\n" ++
  addedBlock ++
  derivedBlock ++
  "\n\nREFS (style key first):\n  - " ++
  refs ++
  "\n\n```\n" ++
  P.imagePrompt(e.spec) ++
  "\n```\n"
}

let header =
  "# EP10 «ग से गाय» — all 52 hero shots under the deterministic prompt engine\n\n" ++
  "Rendered by `studio/src/KukuEp10_Shots.res`. Each shot declares its story BEAT; `Kuku_Ep10State.res` derives गौरी's place, great/small form, the lighting clock, and whether the golden ग-shape exists (using it before the forging is a render-time error). These facts live in ONE module and cannot be forgotten per shot.\n\n" ++
  "**Shots that needed information the original hand-written prompt never carried: " ++
  Belt.Int.toString(Js.Array2.length(withAdded)) ++
  " of " ++
  Belt.Int.toString(Js.Array2.length(shots)) ++
  "** (every shot also received a one-line `scene` field — that universal addition is not counted).\n\n---\n\n"

/* ---- regeneration runner --------------------------------------------------- */
let stills = P.kukuRoot ++ "ep10prod/stills/"
let opts = {"encoding": "utf8", "timeout": 900000}

let generateShot = (e: entry) => {
  let dst = stills ++ e.id ++ ".png"
  let bak = stills ++ "PRE_SPEC_" ++ e.id ++ ".png"
  if existsSync(dst) && !existsSync(bak) {
    copyFileSync(dst, bak)
  }
  let args = Js.Array2.concat(
    Js.Array2.concat(
      ["generate", "create", "nano_banana_pro", "--prompt", P.imagePrompt(e.spec)],
      Js.Array2.reduce(P.imageRefs(e.spec), (acc, r) => Js.Array2.concat(acc, ["--image", r]), []),
    ),
    ["--aspect_ratio", "16:9", "--resolution", "2k", "--wait", "--json"],
  )
  let raw = execFileSync("higgsfield", args, opts)
  Kuku_Spend.record(
    ~episode="EP10", ~shot=e.id, ~kind="still", ~model="nano_banana_pro",
    ~credits=Kuku_Spend.priceOf("nano_banana_pro"), ~note="hero frame", (),
  )
  switch Js.String2.match_(raw, Js.Re.fromString("https://[^\"\\s]*\\.(png|webp|jpg)")) {
  | Some(m) =>
    switch m[0] {
    | Some(url) => {
        let _ = execFileSync("curl", ["-sL", "--retry", "3", "-o", dst, url], opts)
        Js.log("OK " ++ e.id)
      }
    | None => Js.log("FAIL " ++ e.id ++ " — no url in output")
    }
  | None => Js.log("FAIL " ++ e.id ++ " — " ++ Js.String2.slice(raw, ~from=0, ~to_=140))
  }
}

let args = Js.Array2.sliceFrom(argv, 2)
if Js.Array2.length(args) > 0 && args[0] == "gate" {
  /* render every prompt through the PromptGate, collecting every violation so
     one run shows the whole cleanup list. Zero cost — the lint:prompts entry. */
  let bad = ref(0)
  Js.Array2.forEach(shots, e =>
    try {ignore(P.imagePrompt(e.spec))} catch {
    | Js.Exn.Error(err) => {
        bad := bad.contents + 1
        Js.log("== " ++ e.id ++ " ==")
        Js.log(switch Js.Exn.message(err) { | Some(m) => m | None => "?" })
      }
    }
  )
  if bad.contents > 0 {
    Js.Exn.raiseError(Belt.Int.toString(bad.contents) ++ " still prompts forbid")
  }
  Js.log("PROMPT GATE CLEAN: " ++ Belt.Int.toString(Js.Array2.length(shots)) ++ " still prompts describe, and every line names what is on screen")
} else if Js.Array2.length(args) > 0 && args[0] == "go" {
  let ids = Js.Array2.sliceFrom(args, 1)
  Js.Array2.forEach(ids, id =>
    switch Js.Array2.find(shots, e => e.id == id) {
    | Some(e) => generateShot(e)
    | None => Js.log("UNKNOWN SHOT " ++ id)
    }
  )
} else {
  /* positions are exported so the assembler can enforce a monotonic run: a chase
     is only a chase if the ground under it moves one way */
  let posPairs = Js.Array2.map(
    Js.Array2.filter(shots, e => Js.Array2.length(e.derived) > 0),
    e => {
      let at = Js.Array2.find(e.derived, d => Js.String2.startsWith(d, "cart clock "))
      switch at {
      | Some(d) => (e.id, Js.String2.split(d, " ")[2])
      | None => (e.id, "")
      }
    },
  )
  let beatPairs = Js.Array2.map(shots, e => {
    let b = Js.Array2.find(e.derived, d => Js.String2.startsWith(d, "story beat "))
    (e.id, Js.Json.string(switch b {
    | Some(d) => Js.String2.sliceToEnd(d, ~from=11)
    | None => ""
    }))
  })
  writeFileSync(
    "../stories/kuku/ep10prod/shot_beats.json",
    Js.Json.stringify(Js.Json.object_(Js.Dict.fromArray(beatPairs))),
  )
  writeFileSync(
    "../stories/kuku/ep10prod/shot_positions.json",
    Js.Json.stringify(
      Js.Json.object_(
        Js.Dict.fromArray(
          Js.Array2.map(
            Js.Array2.filter(posPairs, ((_, v)) => v != ""),
            ((k, v)) => (k, Js.Json.string(v)),
          ),
        ),
      ),
    ),
  )
  writeFileSync(
    "../stories/kuku/ep10prod/EP10_SHOT_PROMPTS_SPEC.md",
    header ++ Js.Array2.joinWith(Js.Array2.map(shots, entryMd), "\n"),
  )
  Js.log(
    "EP10_SHOT_PROMPTS_SPEC.md — " ++
    Belt.Int.toString(Js.Array2.length(shots)) ++
    " shots, " ++
    Belt.Int.toString(Js.Array2.length(withAdded)) ++ " needed added information",
  )
}
