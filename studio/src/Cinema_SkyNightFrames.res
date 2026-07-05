/* Scene 4 (night/home) frames, through the cast flow (face-locked on the Birdy +
   Maya sheets via SkyKing_Cast). Poverty + warm dim tungsten + the sim glow, not
   the cold-open sunset. gpt-image-2 on Replicate. */

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"

/* (name, desc, present) */
let shots = [
  ("n1_kitchen", "Interior, a small money-tight kitchen at night lit by a single bare bulb, a space heater glowing orange in the corner. A gentle man around 30 in a worn grey hoodie and t-shirt (NO hi-vis work vest - he is home, off shift) sits at a small worn table across from a tired woman around 30 in an old sweater; a thin dinner on two plates between them. Warm dim tungsten light, worn surfaces, lived-in poverty. Naturalistic, documentary, Kodak Portra.", ["BIRDY", "MAYA"]),
  ("n2_dinner", "Close insert: a thin dinner on a worn kitchen table under one bare bulb - white rice and a single fried egg split across two mismatched plates, a stack of mail by a salt shaker with one envelope torn open. Warm dim light, naturalistic, poverty without melodrama.", []),
  ("n3_letter", "Close insert of a folded rejection letter from a flight-training program lying on a worn kitchen table, official letterhead, a polite denial, under a dim bulb. Naturalistic, quiet, melancholy.", []),
  ("n4_eat", "A gentle man around 30 in a worn grey hoodie (off shift, NO hi-vis vest) and a tired woman around 30 in an old sweater eating a thin dinner in silence at a small kitchen table, one bare bulb overhead, space-heater glow, a long quiet between them. Warm dim, naturalistic - the distance between two people who still love each other.", ["BIRDY", "MAYA"]),
  ("n5_sink", "A tired woman around 30 in an old sweater at a kitchen sink at night, rinsing a plate, worn down, lit by one dim bulb. Naturalistic, melancholy, lived-in.", ["MAYA"]),
  ("n6_touch", "A tired woman around 30 rests her hand on the shoulder of a gentle man around 30 in a worn grey hoodie (NO vest, at home) seated at a small kitchen table - a brief touch as she passes on her way out - dim warm light. Tender and worn. Naturalistic.", ["BIRDY", "MAYA"]),
  ("n7_rig", "A cramped dark spare room: a secondhand office chair patched with tape, a monitor on a plank-and-cinderblock desk, a bargain flight yoke and throttle clamped to the edge, one clamp shimmed. Lit only by the cool glow of the monitor. Naturalistic, the poverty of a dream.", []),
  ("n8_fly", "A gentle man around 30 in a worn t-shirt and a worn headset (at home, NO work vest) at a home flight simulator in a dark room, the glow of the cockpit screen and panel lights moving across his face, grinning faintly, lost in it, late at night. Naturalistic, intimate - the one place he is happy.", ["BIRDY"]),
  ("n9_screen", "A home flight-simulator monitor glowing in a dark room: a simulated turboprop cockpit at night, a runway strung with blue lights, dark mountains beyond the windscreen. Naturalistic screen glow, slight grain.", []),
  ("n10_asleep", "A gentle man around 30 in a worn t-shirt (at home, NO vest) asleep in a taped office chair at a home flight simulator late at night, head dropped to one side, a worn headset still on, hands slid into his lap, the cockpit screen still glowing in the dark room. Naturalistic, tender, melancholy.", ["BIRDY"]),
  ("n11_cover", "A tired woman around 30 in a robe lays a comforter over a man around 30 (in a worn t-shirt, NO vest) asleep in a chair before a glowing flight-simulator screen in a dark room, tucking it at his shoulder, careful of his headset. Tender, intimate - the love that endures. Warm low light and screen glow. Naturalistic.", ["BIRDY", "MAYA"]),
]

let rec run = async i =>
  if i >= Belt.Array.length(shots) {
    ()
  } else {
    let (name, desc, present) = Belt.Array.getExn(shots, i)
    let out = Cinema_Backends.Path(dir ++ "/frames/" ++ name ++ ".png")
    if !Cinema_Backends.exists(out) {
      let _ = await SkyKing_Cast.frame(~desc, ~present, ~out)
    }
    Js.log(name ++ " done")
    await run(i + 1)
  }

let main = async () => await run(0)
main()->ignore
