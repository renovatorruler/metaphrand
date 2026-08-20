import { execFileSync } from "child_process";
import fs from "fs";
const D = "/Users/dusty/Dev/metaphrand/stories/songbook/kark-mv/";
const E = D + "elements/", P = D + "photos/", B = D + "btape/", K = D + "keyframes/", R = D + "rebuilt/";
fs.mkdirSync(R, { recursive: true });

// The shrine, corrected: NO threads wrapped on the structure. The तांती goes on the wrist.
const SHRINE = "The shrine is a small waist-high stone Tejaji shrine with a painted folk idol of a horseman with a cobra in its niche and a small oil lamp burning before it. IMPORTANT: the shrine stone is CLEAN and BARE — absolutely NO threads, strings or cloth tied, wrapped or hanging anywhere on the shrine structure, post or lintel. ";
const NOBORDER = "Full-bleed photograph with NO border, NO white frame, NO album mat — the image fills the entire frame edge to edge. ";
const MALWA = "ALL PEOPLE ARE NORTH INDIAN FROM THE MALWA REGION. No readable text or signage anywhere. ";
const WIDE = "WIDE 16:9 LANDSCAPE SCENE, never a portrait or headshot. ";

const YH = E + "husband_young.png", YW = E + "wife_young.png";
const MH = E + "husband_mid.png", MW = E + "wife_mid.png";
const OH = E + "husband_c3.png", OW = E + "wife_c6.png";

const JOBS = [
  // 1976 origin — against the approved young canonicals
  ["o1_crowd_pull", [YH, YW], NOBORDER + WIDE + MALWA + "1976, night at a village fair lit by pressure lanterns, wooden ferris wheel and bullock carts behind. The young bride (SECOND reference, 20, red-pink ghagra-choli, odhni over her head, mehndi) pulls her young husband (FIRST reference, 25, white kurta, jet-black hair) by the hand through the dense crowd toward a shrine, she a step ahead looking back at him with mischievous certainty, he half-stumbling after her, smiling and bewildered."],
  ["o2_first_thread", [YH, YW], NOBORDER + WIDE + MALWA + SHRINE + "1976, lantern-lit night at a village fair. Close two-shot at the bare new shrine: the young husband (FIRST reference, 25) holds out his wrist and the young bride (SECOND reference, 20) ties the very FIRST red sacred thread onto it with her mehndi-covered hands. Both look down at the thread on his wrist."],
  ["o3_after", [YH, YW], NOBORDER + WIDE + MALWA + "1976, lantern-lit village fair at night. The young husband (FIRST reference, 25) looks down at the single new red thread on his own wrist with a small amused smile; his young bride (SECOND reference, 20) watches his face to see whether he understood what she just gave him."],
  ["o4_wheel_ride", [YH, YW], NOBORDER + WIDE + MALWA + "1976 at night: the young couple (FIRST and SECOND references, 25 and 20) ride together in the wooden gondola of a hand-built wooden ferris wheel, sitting close, her odhni blown back, both laughing, the lantern-lit fairground small below them."],
  // the six thread keyframes — same staging, clean shrine
  ["kf_1976", [YH, YW], NOBORDER + WIDE + MALWA + SHRINE + "1976, night at a village fair, pressure lanterns and a wooden ferris wheel behind. The shrine stands at the LEFT of frame; at the right in profile facing it, the young husband (FIRST reference, 25, white kurta) holds his wrist out and the young bride (SECOND reference, 20, red-pink ghagra-choli, odhni, mehndi) ties a red sacred thread onto it."],
  ["kf_1990", [MH, MW, B + "n4_thread_watch.png"], NOBORDER + WIDE + MALWA + SHRINE + "1990 at dusk, a village fair with kerosene lanterns and a small iron ferris wheel. The shrine at LEFT; at right in profile, the man (FIRST reference, aged 35, white kurta, jet-black hair) holds his wrist out and the woman (SECOND reference, aged 30, deep-blue cotton sari, pallu over her head) ties a red sacred thread onto it — while their small daughter, THE SAME CHILD as in the THIRD reference image, stands close holding her mother's sari and watching the knot intently."],
  ["kf_2005", [MH, MW], NOBORDER + WIDE + MALWA + SHRINE + "2005, night at a village fair with warm tungsten string bulbs, an iron ferris wheel and an auto-rickshaw at the edge. The shrine at LEFT; at right in profile, the man (FIRST reference, 45, checked shirt, first grey at the temples) holds his wrist out and the woman (SECOND reference, 40, rust-orange sari, pallu over head) ties a red sacred thread onto it. Harsh consumer camera flash on the couple."],
  ["kf_2018", [OH, OW], NOBORDER + WIDE + MALWA + SHRINE + "2018, dry night at a village fair, LED string lights and a lit ferris wheel, several people holding up smartphones in the blurred crowd. The shrine at LEFT; at right in profile, the man (FIRST reference, healthy, ~58, no cap, short grey-flecked hair, pale sky-blue shirt, NO hospital band) holds his wrist out and the woman (SECOND reference, ~53, deep maroon sari with thin gold border, pallu over head) ties a red sacred thread onto it — he is not even looking, chatting toward her, decades of habit."],
  ["kf_2021", [OH, OW, P + "b5_46_selfie.png"], NOBORDER + WIDE + MALWA + SHRINE + "About 2021, night at a village fair with string lights and a lit ferris wheel. The shrine at LEFT; at right in profile, the man (FIRST reference, healthy, ~55, mustard kurta, no cap, NO hospital band) holds his wrist out and the woman (SECOND reference, ~50, teal cotton sari, pallu over head) ties a red sacred thread onto it, while TWO SMALL GRANDCHILDREN — the same children as in the THIRD reference image — crowd in: the boy on tiptoe watching the knot, the girl holding her grandmother's sari."],
  ["kf_2026", [OH, OW], NOBORDER + WIDE + MALWA + SHRINE + "Present day, night at a village fair in warm monsoon rain, string lights and a lit ferris wheel, wet ground. The shrine at LEFT; at right in profile, the man (FIRST reference, 60, thin from illness, knitted woolen cap, brown shawl, a white hospital ID band on his wrist) holds that wrist out and the woman (SECOND reference, 52, deep-green Maheshwari sari, pallu over head) ties a fresh red sacred thread onto it BESIDE the hospital band. Both slightly wet from the rain."],
  // the three other rebuilds
  ["b4_37_rooftop", [OH, OW, P + "b4_36_wedding.png"], NOBORDER + WIDE + MALWA + "About 2015, hard midday sun on a village house rooftop: an extended-family group photograph of about twelve people squinting at the camera. At the centre stand the couple (FIRST reference ~55 and SECOND reference ~50); beside them their grown daughter and her new husband — THE SAME PEOPLE as in the THIRD reference image — and their grown son. The new son-in-law stands slightly apart at the edge of the group, not yet absorbed into the family. Everyone in good clothes, one small child on someone's hip."],
  ["b6_50_hair", [OH, OW], NOBORDER + WIDE + MALWA + "Present day, soft morning light in a modest bedroom, honest and unglamorous: the man (FIRST reference, 60, thin from illness, bare-headed) sits on the edge of the bed looking down at his own open palm, where a loose handful of grey hair has come away; the woman (SECOND reference, 52, green sari) sits behind him on the bed, one hand resting flat between his shoulder blades, looking at the same hand. Neither is performing grief. A window behind them."],
  ["b6_54_thermos", [OH, OW], NOBORDER + WIDE + MALWA + "Present day, a hospital corridor: a metal bench stands AGAINST THE CORRIDOR WALL in a waiting alcove, with the corridor itself clear and open for people to walk past. The couple (FIRST reference, 60, knitted cap and shawl; SECOND reference, 52, green sari) sit side by side on that bench sharing tea from one steel thermos cup, shoulder to shoulder, both looking straight ahead. Other people walk past along the open corridor. Cool fluorescent light."],
];

let made = 0, failed = [];
for (const [name, refs, prompt] of JOBS) {
  const out = R + name + ".png";
  if (fs.existsSync(out)) { console.log("skip " + name); continue; }
  const args = ["generate", "create", "nano_banana_pro", "--prompt", prompt];
  refs.forEach(r => { args.push("--image", r); });
  args.push("--aspect_ratio", "16:9", "--resolution", "2k", "--wait", "--json");
  let raw;
  try { raw = execFileSync("higgsfield", args, { encoding: "utf8", timeout: 900000 }); }
  catch (e) { raw = String(e.stdout || "") + String(e.stderr || e.message); }
  let url = (raw.match(/https:\/\/[^"\s]*\.(png|webp|jpg)/) || [null])[0];
  if (!url) { try { const j = JSON.parse(raw); const a = Array.isArray(j) ? j : [j]; url = a[0].result_url || null; } catch (e) {} }
  if (url) { execFileSync("curl", ["-sL", "--retry", "3", "-o", out, url], { timeout: 300000 }); made++; console.log("OK " + name); }
  else { failed.push(name); console.log("FAIL " + name + ": " + raw.slice(0, 120)); }
}
console.log(`made=${made} failed=${failed.length} ${failed.join(",")}`);
