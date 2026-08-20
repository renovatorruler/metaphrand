// PREVIZ batch — disposable one-off. 32 rough stills + 4 cheap 480p clips for the
// «कर्क की तांती» outline. Rough by design: no Souls, faces will drift, eras approximate.
// Skip-if-exists so a rerun never re-buys. Prompts carry the no-text law.
import { execFileSync } from "child_process";
import fs from "fs";

const DIR = "/Users/dusty/Dev/metaphrand/stories/songbook/kark-mv/previz";
fs.mkdirSync(DIR, { recursive: true });

const FILM = "Cinematic 35mm documentary-realism film still, muted filmic grade. No text, no letters, no readable signage anywhere. ";
const SINGER = "a charismatic Rajasthani folk star, vigorous man of 58, groomed silver-streaked beard, immaculate saffron turban, deep-red silk kurta, ochre shawl, heavy silver cuffs, ravanhatta and bow, red threads on his bowing wrist, on a hospital helipad rooftop ";
const HIM60 = "a thin Indian man of 60 with hollow cheeks, knitted cap, shawl over hospital pyjamas, hospital ID band and red sacred thread on his wrist, dry half-smile ";
const HER55 = "an Indian woman of 55 in a deep-green cotton sari, grey-streaked bun, nose stud, steady competent bearing ";

const stills = [
  ["s01_hospital_night", FILM + "a mid-size Indian city hospital at night seen from outside, one wall of lit windows, monsoon clouds massing above, a single small oil lamp glowing on one windowsill among the fluorescent windows."],
  ["s02_diya_wrist", FILM + "close shot: an old thin male hand resting on a hospital windowsill beside a small burning clay oil lamp, wrist wearing a white hospital ID band and a faded fraying red sacred thread, city night bokeh outside the glass."],
  ["s05_ward_drip", FILM + "close shot in a dim hospital ward: an IV drip bag and line catching cold fluorescent light, the needle taped into the back of a thin elderly male hand, a red sacred thread visible on the same wrist."],
  ["s06_taanti_pole", FILM + "close shot: a red sacred thread knotted around the chrome pole of a hospital IV stand, thread ends swaying slightly, blurred ward behind."],
  ["s07_forms", FILM + HER55 + "at a crowded hospital registration counter, filling a form fast with one hand while holding a thick plastic bag of medical reports with the other, absolute calm competence amid the crowd blur."],
  ["s08_thermos", FILM + "an Indian hospital corridor bench: " + HIM60 + "and " + HER55 + "sit side by side sharing tea from one steel thermos cup, his shoulder leaning on hers, both almost smiling, fluorescent light."],
  ["s10_doctor_gray", FILM + "a hospital consultation room seen through a door crack: a doctor in a white coat across a desk from " + HER55 + ", her back straight, listening; the man's knitted cap visible in the chair beside her; cold light, papers on the desk."],
  ["s11_his_smile", FILM + "close portrait: " + HIM60 + "in a wheelchair looking up back over his shoulder at someone behind him, the dry affectionate half-smile of a man mid-joke, corridor fluorescents overhead."],
  ["s12_fair_eve", FILM + "night view from a hospital window: far across the dark town, the small glowing lights of a village fairground — a lit ferris wheel tiny in the distance, string lights, the first storm clouds above."],
  ["s13_mangu_ivwind", FILM + SINGER + "singing beside a hospital IV stand that stands incongruously on the helipad, a red sacred thread tied to its pole streaming horizontal in the wind, storm-dusk sky, city lights below."],
  ["s14_2018_selfie", FILM + "a village fair at night in 2018: dense crowd holding up smartphones, an LED-lit ferris wheel; center, a healthy Indian couple in their mid-60s — he sturdy in a cream kurta and knitted cap gone, she in a deep-green sari with nose stud — laughing together at young people taking selfies around them."],
  ["s15_2018_thread", FILM + "at a small stone Tejaji shrine at the fair's edge, 2018: a sturdy Indian man in his mid-60s holds out his wrist while a priest ties a red thread — the man is not even looking, chatting away toward his wife beside him, decades of habit in the gesture, string lights above."],
  ["s16_rooftop_algoza", FILM + "far silhouette on a distant rooftop water tank against a storm-dusk sky: a lone figure playing a double flute, city lights below, seen from far away across rooftops."],
  ["s17_2005_fair", FILM + "a village fair in 2005: families with small point-and-shoot film cameras, auto-rickshaws parked in rows at the edge, cassette stall with big speakers, a modest iron ferris wheel, tungsten string bulbs, dusty evening light."],
  ["s18_scooter", FILM + "2005, a rural road at golden hour: an Indian woman about 50 in a green sari drives a scooter, her husband about 55 rides pillion holding two bags of vegetables, both mid-laugh, fields streaming past."],
  ["s19_bangles", FILM + "2005 fair bangle stall glowing with glass bangles: a man about 55 buys red glass bangles while his wife about 50 waves a hand in protest — but her other wrist is already held out; the stallkeeper mid-smile."],
  ["s20_needle_flash", FILM + "harsh cold close-up, present day: a chemotherapy drip chamber dripping once, the line running down to a taped needle in a thin hand, clinical white light, everything else black."],
  ["s21_1990_fair", FILM + "a village fair in 1990 on 16mm film grain, faded Kodachrome color: families posing stiffly for one film camera on a tripod, a smaller hand-cranked iron ferris wheel, kerosene lamps on stalls, hand-painted colorful hoarding shapes with no writing."],
  ["s22_kids_shoulders", FILM + "1990, 16mm grain: a young Indian father in his mid-30s carries a small girl on his shoulders through fair crowd, his wife in a green sari carries a sleeping boy on her hip AND two cloth bags, kerosene light, everyone lit warm."],
  ["s23_her_carrying", FILM + "1990, 16mm grain: young mother in green sari, early 30s, walking fast and level through a bus-stand crowd carrying a child, a cloth bag, a steel tiffin and folded documents pinned under one arm — nothing slipping, face calm."],
  ["s24_mangu_quarrel", FILM + SINGER + "mid-argument with the sky, bow arm flung fully wide, singing hard upward away from the camera at the storm, back arched, threads streaming."],
  ["s25_dholak_palm", FILM + "close shot on the hospital helipad: a dholak drum resting on a seated player's lap, his palm lying FLAT and still on the skin, waiting, storm light."],
  ["s26_lifting", FILM + HER55 + "braced, lifting her husband from wheelchair to hospital bed with locked-out technique, his arm around her neck, her spine straight — competence not struggle, dim ward light."],
  ["s27_1976_approach", FILM + "1976, faded warm postcard grade: bullock carts and two camels at the dark edge of a village fairground, pressure lanterns hissing white, a wooden ferris wheel silhouetted, crowd in dhotis and ghagras."],
  ["s28_wheel_1976", FILM + "1976, faded warm grade: a hand-built WOODEN ferris wheel at night lit by pressure lanterns and torches, wide happy crowd below, sparks rising from a food fire."],
  ["s29_mangu_storm", FILM + SINGER + "at storm peak: wind at maximum, shawl and threads streaming horizontal, first heavy raindrops hitting his face, singing full force into the lens, the troupe silhouetted behind."],
  ["s31_first_thread", FILM + "1976, faded warm grade, close shot at a small stone Tejaji shrine in firelight: a very young man's wrist held out, an old priest tying the FIRST red thread, a young bride's henna-decorated hand resting on the young man's forearm."],
  ["s32_newlyweds", FILM + "1976, faded warm grade: a newlywed Indian couple at a firelit shrine — she about 20 in a red-green ghagra with a nose stud, mischievous certain eyes; he about 25, lean, bewildered and in love — she is pulling him forward by the hand."],
  ["s33_2026_rain_wheel", FILM + "present-day village fair in first monsoon rain at night: a giant lit ferris wheel turning through rain streaks, crowd cheering with faces up, string lights reflecting in fresh puddles, warm and euphoric."],
  ["s34_grandkid_wrist", FILM + "present-day, rain, close shot at the shrine: a small child's wrist held out by a grandfather's thin old hand (hospital band and fresh red thread on his own wrist), a new red thread being tied on the child, rain drops on all three hands."],
  ["s35_family_rain", FILM + "present-day fair in the rain: three generations of one family laughing under the rain by the shrine — the thin grandfather in his knitted cap, the grandmother in green sari holding his arm, two adult children, small grandkids jumping in puddles, string lights."],
  ["s36_flute_boy", FILM + "present-day fair edge in rain at night: a barefoot boy of ten stands on a cart shaft playing a wooden double flute, eyes closed, rain running off his chin, the lit wheel blurred far behind."],
  ["s37_devra_threads", FILM + "night, rain just ended: extreme close on the stone post of a small Tejaji shrine wrapped in hundreds of red sacred threads — most faded to pink and grey, one brand new bright red one on top, water drops falling from the stone, one oil lamp flame reflected."],
];

const clips = [
  ["c01_2018_fair", "A village fair at night in 2018, dense Indian crowd, an LED-lit ferris wheel turning steadily, dozens of smartphones held up glowing, string lights swaying gently, stall smoke drifting, handheld documentary feel, cinematic. No text or readable signage anywhere."],
  ["c02_wheel_back", "A fairground ferris wheel turning BACKWARD at night while its lights change era: LED strips flicker into tungsten bulbs, then into kerosene glow, the wheel's structure aging from steel to iron to wood as it turns, the crowd below blurring through decades of clothing styles, continuous single shot, dreamlike but photoreal, cinematic. No text anywhere."],
  ["c03_1976_leads", "1976 faded warm film look: a newlywed Indian bride in a red-green ghagra pulls her hesitant young husband by the hand through a dense firelit village-fair crowd toward a small stone shrine, pressure lanterns swinging, she looks back at him laughing, he stumbles after her smiling, handheld, warm grain. No text anywhere."],
  ["c04_2026_vow", "Present-day Indian village fair in heavy first monsoon rain at night: at a small stone shrine, a thin old man in a knitted cap — hospital band on his wrist — ties a red sacred thread onto his own wrist with his teeth and free hand, then looks up at his wife and speaks one short sentence to her through the rain, both drenched, string lights glowing, crowd celebrating behind, intimate handheld close shot, cinematic. No text anywhere."],
];

const run = (args) => {
  try { return execFileSync("higgsfield", args, { encoding: "utf8", timeout: 900000 }); }
  catch (e) { return String(e.stdout || "") + String(e.stderr || e.message); }
};
const urlOf = (raw, ext) => (raw.match(new RegExp("https://[^\"\\s]*\\." + ext)) || [null])[0];

let made = 0, skipped = 0, failed = [];
for (const [name, prompt] of stills) {
  const out = `${DIR}/${name}.png`;
  if (fs.existsSync(out)) { skipped++; continue; }
  const raw = run(["generate", "create", "nano_banana_pro", "--prompt", prompt, "--aspect_ratio", "16:9", "--resolution", "2k", "--wait", "--json"]);
  const url = urlOf(raw, "(png|webp|jpg)");
  if (url) { run2curl(url, out); made++; console.log("OK " + name); }
  else { failed.push(name); console.log("FAIL " + name + ": " + raw.slice(0, 200)); }
}
function run2curl(url, out) { execFileSync("curl", ["-sL", "--retry", "2", "-o", out, url], { timeout: 300000 }); }

for (const [name, prompt] of clips) {
  const out = `${DIR}/${name}.mp4`;
  if (fs.existsSync(out)) { skipped++; continue; }
  const raw = run(["generate", "create", "seedance_2_5", "--prompt", prompt, "--duration", "5", "--aspect_ratio", "16:9", "--resolution", "480p", "--generate_audio", "false", "--wait", "--json"]);
  const url = urlOf(raw, "mp4");
  if (url) { run2curl(url, out); made++; console.log("OK " + name); }
  else { failed.push(name); console.log("FAIL " + name + ": " + raw.slice(0, 200)); }
}
console.log(`\nmade=${made} skipped=${skipped} failed=${failed.length} ${failed.join(",")}`);
