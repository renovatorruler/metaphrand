// EP10 «ग से गाय» (V7) — IN-BETWEEN FRAMES derived from the hero setups.
// Each derivation edits its hero with nano so the papercraft medium, palette and
// character designs are inherited rather than re-invented. ~150 frames at 2cr.
// Naming: <hero>__<variant>.png so every frame's parent is provable.
import { execFileSync } from "child_process";
import fs from "fs";
const K = "/Users/dusty/Dev/metaphrand/stories/kuku/";
const S = K + "ep10prod/stills/", OUT = K + "ep10prod/inbetweens/";
fs.mkdirSync(OUT, { recursive: true });

const KEEP = "Keep the papercraft medium, palette, lighting, camera framing, characters and background EXACTLY as in the attached image. Change ONLY what is described. No readable text, letters, numbers or glyphs anywhere. ";

// [hero, variant, instruction]
const D = [
  // scene 0 — the ring, the flight, the landing
  ["h01_ring_wide", "a_rishi_enters", "the old dragon-sage now stands at the left edge of the courtyard, staff planted, facing the five."],
  ["h01_ring_wide", "b_furia_steps_out", "the red dragon has stepped one pace forward out of the row, wings half lifted, eager."],
  ["h01_ring_wide", "c_four_watch", "the red dragon is gone from the row; the remaining four look up and to the right, following something in the sky."],
  ["h03_furia_mark", "a_crouch", "she crouches lower on the mark, wings drawn back, about to launch."],
  ["h03_furia_mark", "b_look_up", "she looks up and to the right at the hanging bell, chin lifted."],
  ["h04_launch", "a_higher", "she is higher and further through the ring, only her tail still inside it."],
  ["h05_bell_touch", "a_swinging", "the bell swings harder, its clapper visibly to one side."],
  ["h06_landing_paw", "a_paw_scuff", "closer on her hind claws: one claw has scuffed a short mark past the painted spot on the flagstone."],
  ["h06_landing_paw", "b_wings_fold", "her wings are folded and settled, head turned back toward the mark, sheepish."],
  ["h09_rishi_boon", "a_stern", "his hand is raised in warning, expression graver."],
  ["h09_rishi_boon", "b_lower_hand", "his hand has come down to rest on the staff, the warning finished."],

  // scene 0-अ — the tower, the rope, the theft
  ["h10_cheel_tower", "a_head_turn", "the eagle's head turns further down and to the left, fixed on something below."],
  ["h10_cheel_tower", "b_wings_open", "her wings are opening, about to drop from the parapet."],
  ["h11_shards_close", "a_talon_near", "a single dark talon has entered the frame beside the shards."],
  ["h12_rope_slip", "a_free", "the rope is fully free of the post and falling away, the post bare."],
  ["h13_bell_taken", "a_higher", "she is higher above the arch, the bell swinging beneath her."],
  ["h14_furia_choice", "a_look_down", "she has turned further, now looking straight down at the courtyard, wings braking."],
  ["h14_furia_choice", "b_dive", "she has tipped into a dive toward the lane below."],

  // scene 1 — the runaway, the failed lift
  ["h07_cart_tethered", "a_cow_lifts_head", "the cow has lifted her head from the hay and looks toward the rope, alert."],
  ["h07_cart_tethered", "b_rope_gone", "the red rope is gone from the post and the cart has begun to move, one wheel turned."],
  ["h15_cart_runs", "a_faster", "the cart is further down the lane and moving faster, more hay flying, dust behind the wheels."],
  ["h15_cart_runs", "b_marker_one", "the cart is passing the first red marker on the lane."],
  ["h16_five_flank", "a_closer", "the five dragons fly closer to the cart, wings angled down."],
  ["h17_group_lift", "a_worse_tilt", "the cart tilts further to one side, the cow sliding harder, hay spilling."],
  ["h18_cow_slips", "a_recovers", "the cow has regained her footing and stands square again in the cart."],
  ["h19_wheels_return", "a_dust", "more dust rises around the wheels as they settle onto the lane."],

  // scene 2 — braking, markers, failed breath
  ["h20_furia_brake", "a_strain", "her wings are at full extension and her face shows effort, the cart's nose closer behind her."],
  ["h20_furia_brake", "b_drift_left", "the cart behind her has drifted toward the left edge of the lane."],
  ["h21_vesper_above", "a_call", "the blue dragon's mouth is open, calling down, one wing dipped toward the lane."],
  ["h21_vesper_above", "b_yawn", "the blue dragon is mid-yawn, eyes half closed, wings slack."],
  ["h22_castor_calm", "a_cow_turns", "the cow has turned her head toward the yellow dragon."],
  ["h22_castor_calm", "b_cow_steps", "the cow has taken one step toward the yellow dragon and stands squarer."],
  ["h23_marker_pass", "a_second", "a second red marker is visible ahead down the lane beyond the first."],
  ["h24_kuku_breath_fail", "a_scatter", "the thin golden breath has broken into scattered paper flecks and is dying in the air."],
  ["h24_kuku_breath_fail", "b_startled", "the green dragon's mouth is closed and his eyes are wide, startled."],

  // scene 3 — the flat, the sound, the forging
  ["h25_leda_knock", "a_listen", "the lilac dragon has lifted her claw from the stone and turned her head, listening."],
  ["h26_tings", "a_brighter", "the golden rings of light are brighter and wider."],
  ["h26_tings", "b_fifth", "a fifth, closest ring of golden light has appeared inside the others."],
  ["h27_kuku_hears", "a_wider", "his eyes are wider and his head lifts, recognition arriving."],
  ["h28_forging", "a_stronger", "the golden stream is broader and brighter, reaching further down the lane."],
  ["h28_forging", "b_finishing", "the golden stream is thinning as the breath ends."],
  ["h29_ga_stands", "a_glow", "the golden shape glows more strongly and casts warm light on the stones around it."],
  ["h29_ga_stands", "b_dusk_gone", "the sky behind has darkened; the golden shape is now the brightest thing in frame, lighting the lane."],
  ["h30_bracelets", "a_second_medallion", "a second small blank golden medallion has appeared on the bracelet beside the first, glowing."],

  // scene 4 — last approach
  ["h31_vesper_yawn", "a_snap_awake", "the blue dragon's eyes are wide open, alert, wings caught mid-correction."],
  ["h32_cart_drifts", "a_recovered", "the cart has come back to the middle of the lane."],
  ["h33_cheel_flyover", "a_past", "the eagle is further away, climbing, the bell small beneath her."],
  ["h34_furia_refuses", "a_turn_back", "she has turned fully back toward the cart, the sky behind her empty."],

  // scene 5 — the stop
  ["h35_last_marker", "a_over", "the wheels are past the third marker and onto the flat stretch."],
  ["h36_three_beats", "a_second_beat", "her wings are at the bottom of a deeper, slower beat, more dust rolling."],
  ["h36_three_beats", "b_third_beat", "her wings are fully extended in a long final beat, the cart much closer and slower."],
  ["h37_cart_into_curve", "a_deeper", "the cart's nose is deeper into the curve, riding up its inner slope, wheels almost stopped."],
  ["h38_stopped", "a_settled", "the dust has settled completely and the cow's head is up, calm."],

  // scene 6 — after
  ["h39_shrink_glow", "a_fading", "the columns of golden light are fading, lower and dimmer."],
  ["h40_small_five_sit", "a_cow_closer", "the cow has come one step closer to the seated dragon children."],
  ["h40_small_five_sit", "b_cow_sniffs", "the cow has lowered her head to sniff the nearest small dragon."],
  ["h41_castor_in_hay", "a_laughing", "the small yellow dragon is laughing harder, hay scattered around him."],
  ["h42_doorway_dadi", "a_dog_forward", "the small paper dog has come forward to the threshold of the doorway."],
  ["h43_vesper_asleep", "a_deeper", "the small dragon has slumped further, fully asleep on the cushion."],
  ["h44_tower_door", "a_wider", "the stone door has ground further open; the darkness inside is wider and deeper."],
];

let made = 0, failed = [];
for (const [hero, variant, instr] of D) {
  const src = S + hero + ".png";
  const dst = OUT + hero + "__" + variant + ".png";
  if (!fs.existsSync(src)) { console.log("NO HERO " + hero); failed.push(hero); continue; }
  if (fs.existsSync(dst)) { console.log("skip " + variant); continue; }
  let raw;
  try {
    raw = execFileSync("higgsfield", ["generate", "create", "nano_banana_pro",
      "--prompt", KEEP + instr, "--image", src,
      "--aspect_ratio", "16:9", "--resolution", "2k", "--wait", "--json"], { encoding: "utf8", timeout: 900000 });
  } catch (e) { raw = String(e.stdout || "") + String(e.stderr || e.message); }
  let url = (raw.match(/https:\/\/[^"\s]*\.(png|webp|jpg)/) || [null])[0];
  if (!url) { try { const j = JSON.parse(raw); const a = Array.isArray(j) ? j : [j]; url = a[0].result_url || null; } catch (e) {} }
  if (url) { execFileSync("curl", ["-sL", "--retry", "3", "-o", dst, url], { timeout: 300000 }); made++; console.log("OK " + hero + "__" + variant); }
  else { failed.push(variant); console.log("FAIL " + variant + ": " + raw.slice(0, 100)); }
}
console.log(`INBETWEENS DONE: made=${made} failed=${failed.length} ${failed.join(",")}`);
