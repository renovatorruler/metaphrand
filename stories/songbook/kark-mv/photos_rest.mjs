// Beats 3–6 + ending singles. Skip-if-exists; every prompt states WIDE 16:9
// LANDSCAPE SCENE (portrait-drag has bitten twice) and the Malwa lock.
import { execFileSync } from "child_process";
import fs from "fs";

const D = "/Users/dusty/Dev/metaphrand/stories/songbook/kark-mv/";
const MID_H = D + "elements/husband_mid.png", MID_W = D + "elements/wife_mid.png";
const OLD_H = D + "elements/husband_c3.png", OLD_W = D + "elements/wife_c6.png";
const WIDE = "WIDE 16:9 LANDSCAPE SCENE — never a portrait or headshot. ";
const MALWA = "ALL PEOPLE ARE NORTH INDIAN FROM THE MALWA REGION. No readable text or signage anywhere. ";

const era = {
  b3: "A real 1998–2005 COLOUR PHOTOGRAPH with a thin white border: consumer film/early-digital print, slightly oversaturated, mild flash, a little grain. North India, Malwa. ",
  b4: "A real 2012–2018 DIGITAL PHOTOGRAPH: clean modern colour, slight HDR crunch, phone-camera sharpness. North India, Malwa. ",
  b5: "A real 2019–2021 SMARTPHONE PHOTOGRAPH: bright clean digital colour, slightly oversharpened. North India, Malwa. ",
  b6: "A present-day photograph, clinical and plain: cool hospital light, honest and unglamorous, no border. North India. ",
};

const midPeople = (ha, wa) => `The MAN is the person in the FIRST reference image aged about ${ha}; the WOMAN is the person in the SECOND reference image aged about ${wa}. Keep BOTH faces exactly as in their references. `;
const oldPeople = (ha, wa) => `The MAN is the person in the FIRST reference image aged about ${ha}; the WOMAN is the person in the SECOND reference image aged about ${wa}. Keep BOTH faces exactly as in their references. `;

const shots = [
  // BEAT 3 — older kids, ~1998–2005, mid canonicals
  ["b3_26_busstop", MID_H, MID_W, era.b3 + WIDE + MALWA + midPeople(45, 40) + "Early morning at a village bus stop: two children in school uniforms — a girl of about fifteen and a boy of about eleven — wait with their bags; the mother is straightening the boy's collar while the girl looks away, visibly embarrassed by her mother; the father stands slightly apart with a cycle."],
  ["b3_27_study", MID_H, MID_W, era.b3 + WIDE + MALWA + midPeople(45, 40) + "Night in a cramped village study corner: a teenage girl bent over schoolbooks at a low table under a bare bulb; her father has fallen asleep sitting upright on the floor beside her, back against the wall, still keeping her company."],
  ["b3_28_scooter", MID_H, MID_W, era.b3 + WIDE + MALWA + midPeople(45, 40) + "A rural road at golden hour: the whole family of four crammed onto one scooter — the father driving, the small boy standing in front of him, the mother riding side-saddle behind with the teenage girl squeezed at the back holding shopping bags. Everyone laughing, fields streaming past."],
  ["b3_29_measure", MID_H, MID_W, era.b3 + WIDE + MALWA + midPeople(45, 40) + "Inside a village house: a teenage boy and his mother standing back to back against a wall while the father measures their heights with his hand — the boy is taller than her for the first time and grinning; she is pretending to be outraged."],
  ["b3_30_prizeday", MID_H, MID_W, era.b3 + WIDE + MALWA + midPeople(45, 40) + "A school prize-day photograph on a dusty ground: the teenage daughter holding a rolled certificate, her parents standing stiffly on either side, all three posed formally for the camera, other families blurred behind."],
  ["b3_31_rotis", MID_H, MID_W, era.b3 + WIDE + MALWA + midPeople(45, 40) + "A village kitchen: the mother teaching her teenage daughter to roll rotis at a low wooden board, both hands deep in flour, the daughter's roti a lopsided mess, both laughing at it."],
  ["b3_32_sofa", MID_H, MID_W, era.b3 + WIDE + MALWA + midPeople(45, 40) + "A formal family portrait at a small-town photo studio: the parents seated on a rented sofa against a painted backdrop with their two teenagers standing behind — the teenagers deliberately not smiling, the parents proud."],
  ["b3_33_mechanic", MID_H, MID_W, era.b3 + WIDE + MALWA + midPeople(45, 40) + "A courtyard: the father and his teenage son crouched over a dismantled motorcycle engine, parts spread on newspaper, both filthy with grease and completely absorbed, the mother visible at the door with tea."],
  ["b3_34_bangles2", MID_H, MID_W, era.b3 + WIDE + MALWA + midPeople(45, 40) + "The two of them alone at a village bangle stall, twenty-five years older than their first visit — he is holding up a bangle to her wrist, she is looking at his face rather than the bangle. The stallkeeper waits."],
  // BEAT 4 — kids with spouses, ~2012–2018, transition to old canonicals
  ["b4_36_wedding", OLD_H, OLD_W, era.b4 + WIDE + MALWA + oldPeople(52, 47) + "A village wedding: their grown daughter as a bride in red, seated; the mother's hand resting on her head in blessing, the father standing behind with his hand on his wife's shoulder. Marigolds, crowd, warm light."],
  ["b4_37_rooftop", OLD_H, OLD_W, era.b4 + WIDE + MALWA + oldPeople(52, 47) + "A big extended-family group photograph on a house roof in hard sunlight: about fifteen people squinting at the camera, the couple at the centre, a new son-in-law standing slightly apart at the edge, not yet absorbed into the family."],
  ["b4_38_empty", OLD_H, OLD_W, era.b4 + WIDE + MALWA + oldPeople(52, 47) + "The emptied house the evening after the wedding: the couple sitting alone on the floor of a room still strewn with marigold petals and folded chairs, two cups of tea, neither of them talking."],
  ["b4_39_videocall", OLD_H, OLD_W, era.b4 + WIDE + MALWA + oldPeople(52, 47) + "The couple sitting close on a charpai, a smartphone held up between them on a video call, both leaning in toward the small screen with their heads almost touching, faces lit by the phone."],
  // BEAT 5 — grandkids, ~2019–2021
  ["b5_41_newgrand", OLD_H, OLD_W, era.b5 + WIDE + MALWA + oldPeople(55, 50) + "A village room: the grandfather holding a newborn grandchild in his arms, holding it exactly as awkwardly as a new father would, his wife beside him laughing at his stiffness and reaching to adjust his hands."],
  ["b5_42_feeding", OLD_H, OLD_W, era.b5 + WIDE + MALWA + oldPeople(55, 50) + "A courtyard: the grandmother trying to feed a toddler grandchild from a steel bowl while the toddler turns its face away with total conviction; both equally stubborn, the grandfather laughing in the background."],
  ["b5_43_kite", OLD_H, OLD_W, era.b5 + WIDE + MALWA + oldPeople(55, 50) + "A rooftop at dusk: the grandfather standing behind a small boy of six, both hands over the boy's hands on the kite string, both looking up; a paper kite high in a wide orange sky."],
  ["b5_44_nap", OLD_H, OLD_W, era.b5 + WIDE + MALWA + oldPeople(55, 50) + "The hot afternoon: three generations asleep in a row on mats on a cool stone floor — the grandfather, a grown son, and two small grandchildren, all sprawled in different directions, a ceiling fan above."],
  ["b5_45_hands", OLD_H, OLD_W, era.b5 + WIDE + MALWA + "Extreme close-up of two hands side by side on a wooden table: an old man's weathered hand and a small grandchild's hand, palms up, the size and texture difference the whole subject of the photograph. Warm daylight."],
  ["b5_46_selfie", OLD_H, OLD_W, era.b5 + WIDE + MALWA + oldPeople(55, 50) + "A family selfie taken at arm's length: about eight people crowded into frame — the couple at the centre, grown children, grandchildren, someone's arm visible holding the phone, everyone squashed together and laughing."],
  // BEAT 6 — the cancer, present day
  ["b6_48_doorcrack", OLD_H, OLD_W, era.b6 + WIDE + MALWA + "Seen through the narrow crack of a half-open consultation-room door: a doctor in a white coat sits across a desk; the WOMAN from the SECOND reference image (age 52) sits with her back to us, spine perfectly straight, listening. Her husband's knitted cap is just visible on the chair beside her. Cold light, papers on the desk."],
  ["b6_49_corridorface", OLD_H, OLD_W, era.b6 + WIDE + MALWA + "A hospital corridor: the WOMAN from the SECOND reference image (age 52, green sari) stands against the wall holding a thick plastic bag of medical reports against her chest, staring at nothing, absolutely composed, NOT crying. Fluorescent light."],
  ["b6_50_hair", OLD_H, OLD_W, era.b6 + WIDE + MALWA + "Morning light on a pillow: a scatter of grey hair left on the white pillowcase where a head has been, the bed empty, a window behind. Quiet, plain, no people in the frame."],
  ["b6_51_cap", OLD_H, OLD_W, era.b6 + WIDE + MALWA + "A bedroom: the WOMAN (SECOND reference, 52) stands in front of the seated MAN (FIRST reference, 60, thin, bare-headed) and settles a knitted woolen cap onto his head with both hands; his eyes are down, hers are on the cap. Neither is performing for anyone."],
  ["b6_52_drip", OLD_H, OLD_W, era.b6 + WIDE + MALWA + "A chemotherapy day-ward: the MAN (FIRST reference, 60, knitted cap, shawl) sits in a reclining chair with a drip line running to a needle taped into the back of his hand; the WOMAN sits beside him reading a folded newspaper aloud. Other patients blurred behind."],
  ["b6_53_waiting", OLD_H, OLD_W, era.b6 + WIDE + MALWA + "A crowded hospital waiting area: the couple side by side on plastic chairs, he is mid-joke with a completely straight face and she is laughing against her will with a hand over her mouth. Everyone around them is grim."],
  ["b6_54_thermos", OLD_H, OLD_W, era.b6 + WIDE + MALWA + "A hospital bench in a corridor: the couple sitting shoulder to shoulder sharing tea from one steel thermos cup, passing it between them, both looking straight ahead at nothing."],
  ["b6_55_3am", OLD_H, OLD_W, era.b6 + WIDE + MALWA + "A hospital room at 3am: the WOMAN (SECOND reference, 52) asleep sitting upright in a hard plastic chair beside a bed, head fallen sideways, a shawl slipping off her shoulder; the MAN asleep in the bed beside her, a monitor glowing."],
  ["b6_57_ivtaanti", OLD_H, OLD_W, era.b6 + WIDE + MALWA + "Close on a hospital IV drip stand: a red sacred thread is knotted around the chrome pole, its ends hanging; the drip bag above, the ward soft-focused behind. The thread is the subject of the photograph. No people."],
  // Ending singles
  ["x_42_childwrist", OLD_H, OLD_W, "A present-day photograph in warm night rain at a village fair. " + WIDE + MALWA + "Close on hands only at a stone shrine: an old man's weathered hand (a white hospital band and a fresh red thread on his own wrist) steadies a small child's forearm while a priest's hands tie a new red sacred thread onto the child's wrist. Rain on all the hands, string-light bokeh behind."],
  ["x_43_fluteboy", OLD_H, OLD_W, "A present-day photograph in warm night rain at a village fair. " + WIDE + MALWA + "A barefoot Malwa village boy of about ten stands on the shaft of a wooden cart at the edge of the fair, playing a wooden algoza double-flute with his eyes closed, rain running off his chin and elbows; the lit ferris wheel blurred far behind him."],
];

const run = (args) => { try { return execFileSync("higgsfield", args, { encoding: "utf8", timeout: 900000 }); } catch (e) { return String(e.stdout || "") + String(e.stderr || e.message); } };
let made = 0, failed = [];
for (const [name, refA, refB, prompt] of shots) {
  const out = D + "photos/" + name + ".png";
  if (fs.existsSync(out)) continue;
  const raw = run(["generate", "create", "nano_banana_pro", "--prompt", prompt, "--image", refA, "--image", refB, "--aspect_ratio", "16:9", "--resolution", "2k", "--wait", "--json"]);
  const url = (raw.match(/https:\/\/[^"\s]*\.(png|webp|jpg)/) || [null])[0];
  if (url) { execFileSync("curl", ["-sL", "--retry", "2", "-o", out, url], { timeout: 300000 }); made++; console.log("OK " + name); }
  else { failed.push(name); console.log("FAIL " + name + ": " + raw.slice(0, 120)); }
}
console.log(`made=${made} failed=${failed.length} ${failed.join(",")}`);
