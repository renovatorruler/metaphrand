// EP10 «ग से गाय» (V7) — the ~40 HERO SETUPS.
// Papercraft medium locked by style reference + explicit clause; character design
// locked by boards. Every other frame in the episode gets derived from these with
// nano, so the medium can't drift shot to shot.
import { execFileSync } from "child_process";
import fs from "fs";
const K = "/Users/dusty/Dev/metaphrand/stories/kuku/";
const OUT = K + "ep10prod/stills/"; fs.mkdirSync(OUT, { recursive: true });

const STYLE_KEY = "0c47270d-70f7-4dd0-887f-c06c88ef5fd9";
const E = K + "ep9prod/coldopen/elements/";
const C = K + "charsheets/";
const G_KUKU = E + "future_kuku_board_v1.png", G_FUR = E + "future_fyuria_board_v1.png";
const G_LEDA = E + "future_leda_board_v1.png", G_CAS = E + "future_castor_board_v1.png";
const G_VES = E + "future_vesper_board_v1.png";
const S_KUKU = C + "kuku.png", S_FUR = C + "furia.png", S_LEDA = C + "leda.png", S_CAS = C + "castor.png";
const RISHI = C + "rishi.png", CHEEL = C + "cheel.png", DADI = C + "dadi.png";

const PAPER = "STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY. CHARACTER REFERENCES: every other attached image is a locked character design; match each EXACTLY. 3D papercraft, layered cut-paper illustration, soft matte construction-paper textures, visible paper edges and folds, warm storybook palette, soft lighting, non-photorealistic, illustrated, not a photo. LANDSCAPE 16:9 SHOT. ";
const GREAT = "The dragon children are in their GREAT forms: towering winged paper dragons, each several times the height of a grown man, massive and imposing. ";
const NEG = " Full-bleed scene, the camera is INSIDE the world. NEGATIVE: no humans, no people, no human children, no human faces, no human shadows, no theater curtains, no stage, no proscenium, no frame-within-frame, no decorative border, no vignette, no readable text, no letters, no numbers, no glyphs, no captions, no watermark, no logos, no photorealism, no duplicate characters, no extra characters";
const LANE = "The lane is the gurukul's own straight downhill flight-courtyard slope of paper flagstones, with three small red paper markers set into it at intervals, a flat stretch at the bottom, and a closed paper stone wall at the very end. ";

const SHOTS = [
  // — scene 0: the flight ring —
  ["h01_ring_wide", [G_FUR], GREAT + "WIDE: five towering paper dragon children stand in a row on the courtyard flagstones facing a large inverted stone flight ring of layered paper arcs. Golden paper bracelets on their forearms. Paper temple gateway far behind, dusk paper clouds."],
  ["h02_rishi_teach", [RISHI], "MEDIUM: the old paper rishi stands at the edge of the flight courtyard, staff planted on the flagstones, one hand raised mid-instruction, dusk light. The flight ring soft behind him."],
  ["h03_furia_mark", [G_FUR], GREAT + "CLOSE-MEDIUM: the towering orange-red paper dragon girl stands eager on a marked flagstone, wings half-raised, chin lifted."],
  ["h04_launch", [G_FUR], GREAT + "WIDE LOW ANGLE: the orange-red paper dragon launches straight out through the inverted paper stone ring, wings at full stretch, paper dust curling from the flagstones."],
  ["h05_bell_touch", [], "CLOSE: a bronze paper bell hung in a paper stone arch above the courtyard, swinging once, dusk sky of layered paper clouds behind it."],
  ["h06_landing_paw", [G_FUR], GREAT + "MEDIUM: the orange-red paper dragon has landed on her marked flagstone, wings still open and settling, one hind claw scuffed just past the mark, paper dust in the air."],
  ["h07_cart_tethered", [], LANE + "WIDE: a wooden paper hay cart stands at the top of the slope, tied by a thick red paper-twine rope to a stone post; a brown-and-white paper cow stands in it eating paper hay."],
  ["h08_gauri_close", [], "CLOSE: a gentle brown-and-white paper cow with dark paper eyes and a small paper bell at her neck, chewing paper hay, calm."],
  ["h09_rishi_boon", [RISHI], "MEDIUM: the old paper rishi speaks gravely to camera-left, staff in both hands, dusk light warm on his paper robes — the moment of a solemn warning."],

  // — scene 0-अ: the tower —
  ["h10_cheel_tower", [CHEEL], "MEDIUM: a great paper eagle perches on the parapet of a closed paper stone tower at dusk, wings folded, head turned down toward the courtyard, small black broken paper glyph-shards scattered near her talons."],
  ["h11_shards_close", [], "CLOSE: small jagged black paper shards lying on weathered paper stone, catching the last dusk light."],
  ["h12_rope_slip", [], "CLOSE: a thick red paper-twine knot slipping loose from a weathered paper stone post, the rope end whipping away, fibres catching light. No characters."],
  ["h13_bell_taken", [CHEEL], "MEDIUM: the great paper eagle lifts from the paper stone arch with the bronze paper bell in her talons, its cut binding swinging, dusk clouds behind, wings at full power."],
  ["h14_furia_choice", [G_FUR], GREAT + "CLOSE: the towering orange-red paper dragon hovers, turned away from the sky and looking down toward the courtyard, jaw set, wings beating."],

  // — scene 1: the runaway and the failed lift —
  ["h15_cart_runs", [], LANE + "WIDE ACTION: the paper hay cart rolls fast down the slope, the frightened paper cow braced inside, paper hay flying, the loose red rope trailing."],
  ["h16_five_flank", [G_KUKU, G_LEDA], GREAT + "WIDE: five towering paper dragons fly alongside and above the running paper cart on the slope, wings spread, dusk."],
  ["h17_group_lift", [G_FUR, G_CAS], GREAT + "WIDE LOW: the five towering paper dragons grip the paper cart's four wheels and strain upward; the front wheels lift while the back stay down, the cart twisting, the paper cow sliding."],
  ["h18_cow_slips", [], "CLOSE: the brown-and-white paper cow losing footing inside the tilting paper cart, legs braced, paper hay scattering."],
  ["h19_wheels_return", [], "CLOSE: four wooden paper wheels settling back onto the paper flagstone lane, dust puffing, the cart righting."],

  // — scene 2: braking, markers, the failed breath —
  ["h20_furia_brake", [G_FUR], GREAT + "WIDE: the towering orange-red paper dragon flies backwards ahead of the running cart, wings pushing air against it, the cart's nose behind her."],
  ["h21_vesper_above", [G_VES], GREAT + "HIGH WIDE: seen from above, a towering paper dragon hovers high over the lane calling down; the cart small below between the paper markers."],
  ["h22_castor_calm", [G_CAS], GREAT + "MEDIUM: a towering paper dragon flies close beside the cart, head lowered gently toward the frightened paper cow, speaking softly."],
  ["h23_marker_pass", [], "CLOSE: a small red paper marker set into the paper flagstone lane as wooden paper wheels rush past it, dust lifting."],
  ["h24_kuku_breath_fail", [G_KUKU], GREAT + "MEDIUM: a towering green paper dragon exhales a thin golden paper-cut breath that scatters and dies in the air, his expression startled."],

  // — scene 3: the flat, the sound, the forging —
  ["h25_leda_knock", [G_LEDA], GREAT + "MEDIUM: a towering paper dragon lands on the flat paper stone at the bottom of the lane and raps the stone once with a claw, listening."],
  ["h26_tings", [], "CLOSE ABSTRACT: small golden paper rings of light rippling outward above a paper stone flagstone at dusk — the visual echo of a sound. No characters."],
  ["h27_kuku_hears", [G_KUKU], GREAT + "CLOSE: a towering green paper dragon's face lit gold from below, eyes wide with recognition, listening hard."],
  ["h28_forging", [G_KUKU], GREAT + "WIDE: the towering green paper dragon exhales a broad stream of golden paper light onto the flat paper stone at the bottom of the lane; the four other towering dragons stand behind him, wings raised."],
  ["h29_ga_stands", [], "WIDE: a large solid golden-stone shape stands on the flat paper stone at the end of the lane — a tall curved form with an open hook-like curve facing up the lane and a straight upright at its back braced against the paper stone wall. Abstract shape only, no writing."],
  ["h30_bracelets", [G_CAS], "CLOSE: a golden paper bracelet on a paper dragon's forearm, glowing warm, two small blank golden medallions set into it. No letters or symbols."],

  // — scene 4: the last approach —
  ["h31_vesper_yawn", [G_VES], GREAT + "MEDIUM: a towering paper dragon high above the lane mid-yawn, eyes half shut, wings slack for an instant."],
  ["h32_cart_drifts", [], LANE + "WIDE: the running paper cart drifting toward the left edge of the lane, one wheel near the paper kerb, dust streaming."],
  ["h33_cheel_flyover", [CHEEL], "WIDE: the great paper eagle sweeps low over the running cart with the bronze paper bell in her talons, wings wide, taunting."],
  ["h34_furia_refuses", [G_FUR], GREAT + "CLOSE: the towering orange-red paper dragon looks away from the departing eagle and back down at the cart, jaw set, refusing."],

  // — scene 5: the stop —
  ["h35_last_marker", [], "CLOSE: the third red paper marker under rushing wooden paper wheels, the flat stretch and a tall golden curved stone shape visible ahead."],
  ["h36_three_beats", [G_FUR], GREAT + "WIDE: the towering orange-red paper dragon holds ahead of the slowing cart, wings in one deep deliberate beat, paper dust rolling."],
  ["h37_cart_into_curve", [], "WIDE: the paper cart's nose rides up into the open curve of the tall golden stone shape at the end of the lane, wheels almost stopped, the paper cow steady inside."],
  ["h38_stopped", [], "WIDE: the paper cart at rest, cradled in the curve of the golden stone shape, the paper cow calm, dusk light, dust settling."],

  // — scene 6/7/8: after —
  ["h39_shrink_glow", [], "WIDE ABSTRACT: five columns of soft golden paper light standing on the courtyard flagstones at dusk, no figures visible, paper clouds behind."],
  ["h40_small_five_sit", [S_KUKU, S_FUR], "WIDE: five small paper dragon children sit in a quiet row on the paper flagstones near the stopped cart, small and gentle, the paper cow standing closer to them now."],
  ["h41_castor_in_hay", [S_CAS], "MEDIUM: a small paper dragon child sitting down in a heap of paper hay, laughing, the paper cow's nose near him."],
  ["h42_doorway_dadi", [DADI], "MEDIUM: an open golden paper doorway between two worlds at dusk; through it a village paper courtyard where an elderly paper grandmother stands, concerned, a small paper dog beside her."],
  ["h43_vesper_asleep", [S_KUKU], "CLOSE: a small paper dragon child asleep with his head resting on a blue paper cushion beside the glowing paper doorway, breathing slow."],
  ["h44_tower_door", [CHEEL], "MEDIUM: the great paper eagle stands before a tall closed paper stone door on the tower, the bronze paper bell at her talons, the stone beginning to grind open a hair's width, darkness beyond."],
];

let made = 0, failed = [];
for (const [name, refs, body] of SHOTS) {
  const out = OUT + name + ".png";
  if (fs.existsSync(out)) { fs.mkdirSync(OUT + "gpt_batch/", {recursive:true}); fs.renameSync(out, OUT + "gpt_batch/" + name + ".png"); }
  const args = ["generate", "create", "nano_banana_pro", "--prompt", PAPER + body + NEG, "--image", STYLE_KEY];
  refs.forEach(r => { if (fs.existsSync(r)) args.push("--image", r); });
  args.push("--aspect_ratio", "16:9", "--resolution", "2k", "--wait", "--json");
  let raw;
  try { raw = execFileSync("higgsfield", args, { encoding: "utf8", timeout: 1200000 }); }
  catch (e) { raw = String(e.stdout || "") + String(e.stderr || e.message); }
  let url = (raw.match(/https:\/\/[^"\s]*\.(png|webp|jpg)/) || [null])[0];
  if (!url) { try { const j = JSON.parse(raw); const a = Array.isArray(j) ? j : [j]; url = a[0].result_url || null; } catch (e) {} }
  if (url) { execFileSync("curl", ["-sL", "--retry", "3", "-o", out, url], { timeout: 300000 }); made++; console.log("OK " + name); }
  else { failed.push(name); console.log("FAIL " + name + ": " + raw.slice(0, 110)); }
}
console.log(`HERO BATCH DONE: made=${made} failed=${failed.length} ${failed.join(",")}`);
