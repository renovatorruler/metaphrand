# कुकु कड़ी 9 — मुख्य कहानी का ऑडियो प्लान

**दायरा:** 2:15–14:15, यानी cold open और title के बाद के 720 सेकंड  
**स्थिति:** निर्माण-तैयार योजना; कोई provider call नहीं किया गया  
**Picture आधार:** `EP9_FINALE_SHOOTING_SCRIPT.md`  
**आवाज़ आधार:** स्वीकृत full-cast performance; कोई नया voice render नहीं

## 1. इस ऑडियो का वादा

यह संगीत बच्चों की कहानी को छोटा या प्यारा बनाकर सुरक्षित नहीं करेगा। खतरा सचमुच बड़ा लगेगा, उड़ान सचमुच रोमांचक लगेगी और गुरुकुल सचमुच एक विशाल भविष्य का दरवाज़ा लगेगा। सुरक्षा कहानी के परिणाम से आएगी, pillow-fort जैसे हल्के संगीत से नहीं।

तीन ध्वनि-विचार पूरी कड़ी को जोड़ेंगे:

1. **पाँच बच्चों का motif:** `D–G–C–F–A`, खुली चौथों वाला पाँच-नोट वाक्य। शुरुआत में अधूरा, पहली उड़ान में साफ़, बचाव में दृढ़ और अंत में बड़ा लेकिन अधूरा रहेगा।
2. **ऋषि की छड़ी:** तीन बराबर, नीचे बजने वाली पखावज चोटें। सही उड़ान में पंख इसके साथ रहते हैं। गलत दूसरे चक्कर में पंख इससे आगे निकलते हैं।
3. **जीवित अक्षर की साँस:** गर्म हवा, bowed strings और low horn का छोटा उठता स्वर। यह आग, sparkle या जादुई घंटियों जैसा नहीं सुनना चाहिए।

## 2. स्वीकृत dialogue का नियम

अभी कोई validated per-line production timeline नहीं है। इसलिए editor को whole table-read file काटकर अंदाज़े से sync नहीं करना है। इन authoritative sources का उपयोग होगा:

- `ep9_table_read_plan_v2_dream.json`: scene, speaker और text का क्रम
- `EP9_FULL_CAST_TABLE_READ_V2_DREAM.manifest.json`: approved normalized chunk और duration
- `finale/audio/alignment/raw_provider/inventory_7e95184e4b7a95cd6646659b4ae2e1cd68370c6a057e94d52e07697de99fc5e2.json`: raw-provider provenance

Final dialogue stem तभी बनेगा जब हर रखी हुई line का in/out manually verified या validator-approved हो। आवाज़ को fit कराने के लिए नया performance, synthetic replacement या 2% से अधिक time-stretch नहीं होगा। पहले pauses और shooting-script में approved trims काटे जाएँगे।

| Picture समय | Scene | Approved source chunks | क्या रखना है |
|---|---:|---|---|
| 2:15–2:50 | 1 | `chunk_006` | चील की दो reactions, ऋषि की अक्षर-आवाज़ और टूटे द्वार वाली बात, चील का अंतिम सवाल |
| 2:50–3:40 | 2 | `chunk_007` | running drill, कुकु का उड़ने का लक्ष्य, फ्यूरिया की शुरुआत, वैस्पर की हवा, कैस्टर-लेडा का अभ्यास चुनना, कुकु की landing, लेडा और दादी की ऋषि पर reactions |
| 3:40–5:00 | 3 | `chunk_008`, `chunk_009` | जागे द्वार का कारण, कुकु को invitation, दादी की पूरी वरदान line, ऋषि की जिम्मेदारी, छड़ी की ताल, helper hierarchy, कुकु का अकेले न जाने का फैसला, दादी की सीमा |
| 5:00–6:10 | 4 | `chunk_010`, `chunk_011`, `chunk_013`; isolated chorus `chunk_012` | कुकु का force करना, लेडा का चार `ब` शब्द पहचानना, कैस्टर का खुद कुंडी खोलना, पाँच बराबर कड़े, दादी का shape instruction, कुकु का पूरा `ब`, बच्चों की हौसला line, लेडा का imprint observation |
| 6:10–7:15 | 5 | `chunk_014` | चारों बच्चों की नई control observations, कुकु का सबके पूरे होने तक रुकना, लेडा का “हम उड़ रहे हैं” |
| 7:15–8:35 | 6 | `chunk_015`, `chunk_016` | पहला चक्कर, फ्यूरिया और वैस्पर की flight lines, कुकु की खुशी, ऋषि की unequal praise, दूसरा चक्कर, कुकु का आदेश, ऋषि का “नहीं”, लेडा की ताल warning और संकट reactions |
| 8:35–9:45 | 7 | audited `chunk_017` | ऋषि का तीन-चक्कर clock, फ्यूरिया का जल्दी पकड़ना, कुकु का अकेले उठाना, वैस्पर के तीन रास्ते, लेडा की दबती warning और फिर पूरी stop line |
| 9:45–11:55 | 8 | `chunk_019`, `chunk_020`, `chunk_021` | नया अक्षर न बनाने का फैसला, चार जगह बाँटना, लेडा की alignment, वैस्पर का एक रास्ता, फ्यूरिया का signal तक रुकना, कैस्टर की जिम्मेदारी, rescue calls, तीसरा चक्कर, gate alignment और lock |
| 11:55–12:45 | 9 | `chunk_022`, `chunk_023` | कुकु की गलती, solo invitation का दूसरा इनकार, पाँच बराबर प्रशिक्षु, लेडा का दादी की अनुमति माँगना, portal test और दादी की अनुमति |
| 12:45–14:15 | 10 | `chunk_024`, `chunk_026`; isolated mimic `chunk_025` | छोटा recap, दादी की ताक़त वाली line, लेडा का independent activation, बाकी चारों के original-voice `ब`, तानसेन की नकल, departure, लेडा का Gurukul observation, फ्यूरिया का अंतिम सवाल और ऋषि की अधूरी line |

`chunk_018` raw audit inventory में नहीं है। उसे केवल तब उपयोग करें जब dialogue extractor उसकी provenance और line boundaries अलग से validate करे।

## 3. Credit सीमा

| काम | संख्या | प्रति asset | अभी की योजना |
|---|---:|---:|---:|
| Sonilo Music, 120 सेकंड | 3 | 7.5 | 22.5 credits |
| Seed Audio signature SFX | अधिकतम 25 | 0.2 | अधिकतम 5 credits |
| दो 60-second pickup cues के लिए बंद reserve | केवल जरूरत पर | अधिकतम 7.5 | अभी spend नहीं |
| **Absolute audio cap** |  |  | **35 credits** |

पहला usable pass मिलने पर reserve खर्च नहीं होगा। तीनों main cues और 25 SFX स्वीकार होने पर planned spend 27.5 credits है। बाकी 7.5 credits picture-lock के बाद दो छोटे pickup cues की स्पष्ट जरूरत पाए जाने पर ही उपयोग होंगे। किसी 120-second cue को दोबारा बनाना मौजूदा manifest में अधिकृत नहीं है।

## 4. तीन 120-second source cues

Editor source cue को छह साफ़ क्षेत्रों की तरह मानेगा। संगीत उल्टा नहीं चलाया जाएगा। Pitch नहीं बदलेगी। Time-stretch अधिकतम ±1.5% होगा और केवल bar alignment के लिए।

### W — Wonder और training

| Source समय | काम |
|---|---|
| W1 0:00–0:20 | पुरानी पुकार, गुरुकुल जागना, unresolved wonder |
| W2 0:20–0:40 | जमीन पर disciplined अभ्यास |
| W3 0:40–1:00 | कोशिश, बढ़ता साहस, पहली flight pulse |
| W4 1:00–1:20 | अकेले जाने और साथ रहने के बीच गंभीर चुनाव |
| W5 1:20–1:40 | अक्षर पहचान, कड़े और imprint |
| W6 1:40–2:00 | रूपांतरण, विशाल scale और lift-off |

**Sonilo prompt W:**

```text
Create one original, exactly 120-second instrumental cinematic adventure cue for a children’s animated season finale, with no vocals and no spoken words. The emotion is serious wonder becoming disciplined courage. Five young dragons who cannot yet fly discover an ancient aerial school, refuse to leave one friend behind, awaken equal bracelets, grow into large youthful dragon forms, and achieve their first true flight. The danger and scale must feel real; child-safe does not mean cute, cozy, comic, bouncy, or small.

Use one recurring five-note team motif, D–G–C–F–A, shaped as open fourths and a final third, never as a nursery tune. Use grounded low strings, warm French horns, restrained sarangi or ravanhatta color, pakhawaj, low frame drum, soft nagara, and broad breath-like orchestral swells. Keep a clear middle-frequency space for Hindi child dialogue. Include a recurring three-strike low pakhawaj staff pulse, steady and dignified.

Build six clean, editable twenty-second regions with musical joins at 00:20, 00:40, 01:00, 01:20, and 01:40. 00:00–00:20: ancient unresolved call, sparse and large. 00:20–00:40: grounded training pulse, earnest rather than playful. 00:40–01:00: attempts gain lift and courage. 01:00–01:20: a morally serious choice to stay together, with tension but no sentimentality. 01:20–01:40: discovery and a warm living-letter sonority, without sparkle effects. 01:40–02:00: powerful transformation and first-flight payoff, the five-note motif finally broad and airborne, ending on an editable open fifth rather than a final victory cadence.

No pizzicato comedy, ukulele, marimba, xylophone, glockenspiel, celesta, toy piano, handclaps, bouncy woodwinds, nursery-rhyme contour, waltz, cute magic sparkles, choir, vocals, trailer braams, electronic risers, horror, borrowed melody, or franchise imitation. Start immediately; no opening silence. End exactly at 02:00 with a clean two-beat tail.
```

### R — खतरनाक aerial rescue

| Source समय | काम |
|---|---|
| R1 0:00–0:20 | गलत तेज़ ताल; पंख छड़ी से आगे निकलते हैं |
| R2 0:20–0:40 | द्वार टूटता है; बकरी वाला बादल उठता है |
| R3 0:40–1:05 | पाँच ताक़तें अलग-अलग काम करके संकट बढ़ाती हैं |
| R4 1:05–1:25 | लेडा सबको रोकती है; geography साफ़ होती है |
| R5 1:25–1:45 | पाँच जिम्मेदार actions एक rescue chain बनती हैं |
| R6 1:45–2:00 | अंतिम approach और lock से ठीक पहले maximum pressure |

**Sonilo prompt R:**

```text
Create one original, exactly 120-second instrumental cinematic aerial-rescue score for a children’s animated season finale, with no vocals and no spoken words. Five newly transformed youthful dragons have real power but poor coordination. They ignore a slow training rhythm, crack an ancient sky gate, and lift a goat inside a cloud toward danger. Their separate rescue attempts make the situation worse until the quietest child stops everyone, sees the true geography, and turns five different abilities into one precise rescue chain. Treat the danger seriously and thrillingly. It must never sound like children playing, a pillow-fort adventure, a comedy chase, or a cute magical mishap.

Reuse the same five-note team identity D–G–C–F–A, but fragment and overlap it during failure, then align it during teamwork. Use urgent low cello and viola ostinati, muscular pakhawaj and nagara, taut tasha strokes, low horns, controlled brass swells, and thin high-string tension. The slow three-strike staff pulse must remain audible underneath the faster wing rhythm so the mistake is musically clear. Keep the 1–4 kHz dialogue range open and leave brief score holes for the gate crack, Leda’s command to stop, the goat bell inside the cloud, and the permanent lock.

Structure exact editable regions: 00:00–00:20 wrong rhythm accelerating against the slower pulse; 00:20–00:40 the gate fracture and sudden aerial emergency; 00:40–01:05 forceful but scattered individual attempts with no comic accents; 01:05–01:25 percussion thins sharply for Leda’s visual and verbal stop, then geography becomes clear; 01:25–01:45 coordinated rescue chain, each layer entering in order; 01:45–02:00 maximum controlled pressure approaching the gate, ending just before resolution on a hard, editable suspended hit.

No playful staccato, pizzicato, ukulele, marimba, xylophone, glockenspiel, celesta, toy piano, comedy stingers, handclaps, bouncy woodwinds, choir, vocals, nursery melody, superhero fanfare, electronic risers, trailer braams, horror shrieks, borrowed melody, or franchise imitation. Begin in motion at 00:00. End exactly at 02:00 with no long reverb tail.
```

### D — भावनात्मक विदाई और Gurukul reveal

| Source समय | काम |
|---|---|
| D1 0:00–0:20 | बचाव के बाद थकान, गलती स्वीकार करना |
| D2 0:20–0:40 | पाँच बराबर प्रशिक्षु बनने का फैसला |
| D3 0:40–1:00 | दादी portal को खुद जाँचती हैं; भरोसा कमाया जाता है |
| D4 1:00–1:20 | लेडा और फिर बाकी बच्चों का independent transformation |
| D5 1:20–1:40 | घर से उड़ना; वापसी की डोरी पीछे रहती है |
| D6 1:40–2:00 | विशाल Gurukul, पाँच landing circles और unresolved training ring |

**Sonilo prompt D:**

```text
Create one original, exactly 120-second instrumental cinematic finale cue for an animated adventure for seven-year-olds, with no vocals and no spoken words. After a dangerous rescue, a child admits his mistake, refuses a place that excludes his four friends, and the group is accepted as five equal trainees. Their grandmother personally tests a two-way route home. The quiet younger girl transforms independently first, the others follow independently, and all five fly through the repaired gate. Clouds reveal an enormous ancient aerial school with many dark future learning places. Five landing circles awaken, then a huge training ring turns upside down and offers the next impossible challenge. The ending must feel earned, emotionally warm, vast, and forward-looking, never sugary, cute, sentimental, or fully resolved.

Use the same team motif D–G–C–F–A. Begin it on solo low strings with space between notes, then let French horns, warm sarangi or ravanhatta color, broad strings, restrained pakhawaj and deep frame drum complete it as the five become equal. Use no choir. The grandmother’s trust should be carried by firm grounded harmony, not a tearful melody. The transformation should have muscular lift. The school reveal should widen into deep orchestral space while keeping room for Hindi dialogue. At the final upside-down ring, remove the expected resolution and hold an open, questioning fifth.

Create six clean twenty-second edit regions: 00:00–00:20 aftermath and honest regret; 00:20–00:40 equality decision, firm rather than sentimental; 00:40–01:00 the two-way portal is physically tested, with quiet tension resolving into trust; 01:00–01:20 independent transformation, led by one clear rising statement; 01:20–01:40 departure flight with the home motif still underneath; 01:40–02:00 enormous Gurukul reveal, five lights awakening, then an unresolved training-ring question. End exactly at 02:00 on a dry suspended open fifth suitable for a hard episode cut.

No lullaby, waltz, pizzicato, ukulele, marimba, xylophone, glockenspiel, celesta, toy piano, magic sparkle music, handclaps, bouncy woodwinds, choir, vocals, sentimental solo piano, triumphant final cadence, trailer braams, electronic risers, borrowed melody, or franchise imitation. Start immediately and preserve clean edit points at every listed boundary.
```

## 5. Exact score edit map: 2:15–14:15

`OUT` का अर्थ score बंद है; ambience, dialogue और causal SFX चलते रहेंगे। एक ही 12-second source हिस्सा 60 सेकंड के भीतर दोबारा नहीं आएगा। जानबूझकर लौटने वाले transformation और flight motifs कम से कम कई मिनट बाद ही दोहरेंगे।

| Picture समय | Source edit | Local treatment | Story काम |
|---|---|---|---|
| 2:15–2:33 | W1 `0:00–0:18` | low strings और air; dialogue पर 5 dB duck | चील से निकलती पुरानी पुकार |
| 2:33–2:50 | OUT | gate room tone, bell, crack और cloud-road | गुरुकुल जागना causally साफ़ रहे |
| 2:50–3:10 | W2 `0:20–0:40` | full but light percussion | जमीन वाला wing drill |
| 3:10–3:30 | W3 `0:40–1:00` | horns हटाने के लिए gentle low-pass; foot and grass foley आगे | कोशिशें बढ़ती हैं |
| 3:30–3:40 | OUT | rising valley wind और cloud-road | ऋषि का arrival बड़ा लगे |
| 3:40–4:00 | W1 `0:00–0:20` | wider stereo than first use; no extra percussion | जागा द्वार और invitation |
| 4:00–4:18 | W4 `1:00–1:18` | restrained; dialogue priority | दादी और ऋषि की जिम्मेदारी |
| 4:18–4:33 | OUT | केवल तीन-beat staff pulse, chest latch और gate strain | rule पहली बार साफ़ सुने |
| 4:33–4:53 | D2 `0:20–0:40` | low, firm harmony | कुकु अकेला स्थान छोड़ता है |
| 4:53–5:00 | OUT | ring hum और पाँच हल्की pulses | घेरा नहीं खुलता |
| 5:00–5:20 | W5 `1:20–1:40` | dialogue notch 1.5–4 kHz | लेडा शब्द-संबंध सुनती है |
| 5:20–5:38 | OUT | latch, कैस्टर movement और bracelet split | कुंडी और पाँच कड़े मुख्य घटना हैं |
| 5:38–5:54 | W3 `0:40–0:56` | no horns; soft pulse | कड़े पहनना और shape बनना |
| 5:54–6:10 | W6 `1:40–1:56` | full rise; 5:58 पर SFX के लिए 3 dB dip | पूरा भौतिक अक्षर और imprint |
| 6:10–6:30 | D4 `1:00–1:20` | transformation statement full | एक wave पाँचों को बदलती है |
| 6:30–6:44 | W5 `1:26–1:40` | lower register and wider reverb | चार control problems; कुकु रुकता है |
| 6:44–6:52 | W1 `0:12–0:20` | percussion-free, broad room | scale को बिना dialogue महसूस करना |
| 6:52–7:12 | D5 `1:20–1:40` | full lift; giant wingbeats आगे | तीन wingbeats और पहली उड़ान |
| 7:12–7:15 | OUT | केवल हवा और पाँच अलग shadows | scene transition |
| 7:15–7:35 | W2 `0:20–0:40` | staff pulse और wings बराबर | सही पहला चक्कर |
| 7:35–7:55 | W3 `0:40–1:00` | full stereo, brighter than training use | फ्यूरिया, वैस्पर और कैस्टर की खुशी |
| 7:55–8:05 | W6 `1:40–1:50` | motif only; percussion हल्की | lap पूरा और कुकु की खुशी |
| 8:05–8:25 | R1 `0:00–0:20` | slow staff pulse untouched | गलत दूसरा चक्कर |
| 8:25–8:45 | R2 `0:20–0:40` | 8:29 पर brief low-frequency cut for cloud suction | gate टूटता है और बकरी उठती है |
| 8:45–9:10 | R3 `0:40–1:05` | full urgency | पहली अलग-अलग विफल कोशिशें |
| 9:10–9:25 | OUT | competing wind paths, size shift, wings और bell | powers की टक्कर समझ आए |
| 9:25–9:45 | R4 `1:05–1:25` | 9:35 पर 250 ms hard dip, फिर लगभग percussion-free | लेडा सबको रोकती है |
| 9:45–10:05 | D2 `0:20–0:40` | darker low-string version | कुकु control बाँटता है |
| 10:05–10:25 | R5 `1:25–1:45` | layers क्रम में प्रवेश करें | path, भार और जिम्मेदारियाँ तय होती हैं |
| 10:25–10:45 | W6 `1:40–2:00` | heroic motif, less reverb | पाँच actions पहली बार chain बनते हैं |
| 10:45–11:05 | R3 `0:40–1:00` | percussion 2 dB नीचे; cloud interior SFX आगे | कैस्टर बकरी तक पहुँचता है |
| 11:05–11:25 | W3 `0:40–1:00` | low, steady forward motion | तीसरा चक्कर और chosen path |
| 11:25–11:35 | R6 `1:45–1:55` | maximum controlled pressure | अक्षर सीधा घूमता है |
| 11:35–11:43 | OUT | permanent lock SFX अकेला; फिर आधा सेकंड शांत हवा | decisive `खट` picture से जुड़ा रहे |
| 11:43–12:03 | D1 `0:00–0:20` | rescue release से regret तक continuous | gate शांत, बकरी नीचे, कुकु गलती मानता है |
| 12:03–12:23 | D2 `0:20–0:40` | firm center, no sentimental swell | पाँच बराबर प्रशिक्षु |
| 12:23–12:43 | D3 `0:40–1:00` | dialogue under 5 dB; portal open पर 2 dB rise | दादी रास्ता खुद जाँचती हैं |
| 12:43–12:45 | OUT | tether tension tail | दादी की अनुमति के बाद साफ़ cut |
| 12:45–12:55 | W5 `1:20–1:30` | small recap, no sparkle | बच्चा-बादल-बकरी rhythm |
| 12:55–13:15 | D4 `1:00–1:20` | full transformation motif | लेडा पहले, फिर चारों independently |
| 13:15–13:35 | D5 `1:20–1:40` | broad flight; home tether low motif में बना रहे | विदाई और gate crossing |
| 13:35–13:55 | D6 `1:40–2:00` | maximum width; dialogue notch | Gurukul और पाँच landing lights |
| 13:55–14:15 | W1 `0:00–0:20` | high air plus low open fifth; no final cadence | उलटा training ring और अगली कड़ी का सवाल |

## 6. Reusable SFX set

इन 25 signature effects को एक बार बनाएँ और फिर pitch, EQ, pan, distance, reverb और length के छोटे local variants से दोहराएँ। कोई effect comic, rubbery, sparkly या arcade-like नहीं होगा। Goat, Kalu, कदम, घास, कपड़ा, मिट्टी और सामान्य paw impacts licensed local/repository foley से आएँगे; इनके लिए credits नहीं रखें।

| ID | एक master effect | मुख्य उपयोग और reuse |
|---|---|---|
| S01 | काले टुकड़े पर चील का पंजा | 2:15; बाद में हल्का stone scrape |
| S02 | सुनहरी sound-ripple pass | 2:23; पाँच marks, learning lights और distant letter echoes |
| S03 | प्राचीन gate groan | 2:33, 3:40, 8:21, 11:07, 13:55 अलग distance पर |
| S04 | गुरुकुल की एक भारी घंटी | 2:33; 13:27 reveal पर बहुत दूर reprise |
| S05 | छड़ी की ठक और cloud-road bloom | 2:46, 3:32, 8:35, 13:19, 14:11 |
| S06 | तीन-beat staff stress pulse | 4:18 से recurring clock; सही/गलत wing rhythm का reference |
| S07 | छोटे पंख की हवा | 2:50–3:29, पाँच अलग pan positions |
| S08 | विशाल dragon wingbeat | 6:52 onward; अलग size और distance variants |
| S09 | तेज़ aerial pass और wake | फ्यूरिया 7:30, 8:43; group flyby 13:19 |
| S10 | वैस्पर की शांत wind lane | 7:43 और 10:07; केवल एक चुना path |
| S11 | cloud suction और orbit | 8:29–8:45, 10:41, 11:07; speed variants |
| S12 | gate crack और golden grip snap | 8:21; 11:35 पर softer mechanical close layer |
| S13 | पेटी/घेरे की अंदरूनी कुंडी | 4:26 और 5:23 |
| S14 | खाली ring का low hum | 4:26–5:20; training ring 13:55 पर deeper variant |
| S15 | एक ring का पाँच कड़ों में खुलना | 5:33, five clean outward movements |
| S16 | bracelet का foreleg पर बैठना | 5:38; scene 10 activations में हल्का tactile reuse |
| S17 | कुकु की सुनहरी अक्षर-साँस | 5:00 failed short tail, 5:54 full breath; आग जैसा नहीं |
| S18 | भारी physical letter rise/grow | 5:54–6:02; later structural weight under lifts |
| S19 | letter imprint का पाँच bracelets में जाना | 6:02, 6:10, 13:27 landing lights |
| S20 | youthful giant transformation grow/unfurl | 6:20, 11:55 reverse/down variant, 12:55 and 13:03 staggered |
| S21 | कैस्टर shrink | 7:51, 9:19, 10:41 |
| S22 | कैस्टर grow/brace | 7:51, 9:19, 10:51 |
| S23 | भारी structure grip, lift और rotate | 9:01, 9:51, 10:23, 10:59, 11:25 |
| S24 | permanent gate lock और settling resonance | 11:35; episode का सबसे साफ़ causal hit |
| S25 | सुनहरी tether tension और two-way portal open | 12:27, 12:35, 12:41 दिशा बदलकर |

## 7. SFX timeline के निर्णायक hits

| Picture समय | Hit |
|---|---|
| 2:15 / 2:23 / 2:33 / 2:46 | S01 → S02 → S03+S04 → S05 |
| 4:08 / 4:18 / 4:26 / 4:43 | staff plant, S06 rhythm, S13+S14, five S02 pulses |
| 5:00 / 5:23 / 5:33 / 5:38 / 5:54 / 6:02 | failed S17, S13, S15, staggered S16, full S17+S18, S19 |
| 6:20 / 6:52 / 7:00 | S20, तीन S08 wingbeats, S08+S09 lift |
| 7:30 / 7:43 / 7:51 | S09, S10, S21+S22 |
| 8:21 / 8:29 / 8:35 / 8:43 | S12, S11 suction, S05+S06 brace, S09+S11 cloud spin |
| 9:01 / 9:19 / 9:35 | S23 one-end lift, S21+S22 failed crack, wing stop और bell अकेली |
| 9:51 / 10:07 / 10:23 / 10:41 / 10:59 | S23 grip shift, S10 path, S23+S08 lift, S21, S23 forward move |
| 11:07 / 11:25 / 11:35 / 11:43 | S11 orbit clock, S23 rotate, S24 lock, suction tail गिरना |
| 11:55 / 12:27 / 12:35 / 12:41 | S20 down variants, S25 three directional portal tests |
| 12:55 / 13:03 / 13:19 / 13:27 / 13:45 / 13:55 | S20 Leda, four S20 staggers, S08+S05, S02+S04+S19, S08 landing, S03+S14 ring turn |

## 8. Mixing और ducking नियम

1. **Dialogue anchor:** approved voices लगभग `-17 LUFS` integrated target पर रहें; true peak `-1 dBFS` से नीचे। Character पहचान बदलने वाला denoise, formant shift या heavy compression नहीं।
2. **Score level:** dialogue के बिना सामान्य score लगभग `-22 LUFS`; dialogue के नीचे लगभग `-26 LUFS`। Sidechain broadband 2 dB और 1.5–4 kHz में अतिरिक्त 3–4 dB duck करे। Attack 60–90 ms, release 300–450 ms; pumping नहीं।
3. **Tension बची रहे:** duck के दौरान low strings और staff pulse पूरी तरह गायब न हों। वे dialogue से नीचे रहें, लेकिन scene की urgency जारी रखें।
4. **Causal SFX पहले:** पहली ring split, physical letter rise, transformation, gate crack, लेडा का stop, permanent lock, portal proof और upside-down ring पर score transient से 3–8 frames पहले नीचे जाए। Dialogue causal hit के ऊपर नहीं बैठेगा।
5. **SFX और consonants:** wingbeats, gate groans और cloud suction को speech के 1.5–4 kHz हिस्से में notch करें। जरूरत हो तो hit को 2–4 frames खिसकाएँ; dialogue को खींचकर sync न बिगाड़ें।
6. **Music holes:** 2:33–2:50, 3:30–3:40, 4:18–4:33, 4:53–5:00, 5:20–5:38, 7:12–7:15, 9:10–9:25, 11:35–11:43 और 12:43–12:45 जानबूझकर score-विहीन हैं। इन्हें “कुछ missing है” समझकर भरना नहीं।
7. **Reuse छिपाना:** हर वापसी अलग source start, अलग foreground SFX और अलग local treatment से होगी। Music reverse नहीं होगा। Melody को pitch-shift नहीं करेंगे। 6–12 frame equal-power crossfades barline पर होंगे।
8. **Final cut:** 14:15 पर ऋषि की dash line के साथ picture और score दोनों hard cut हों। अगले अभ्यास की आवाज़, उत्तर या lingering victory chord नहीं होगा।

## 9. Acceptance check

- Original child voices साफ़ और पहचानी जा रही हैं।
- छोटे रूपों में fire या real flight का कोई sound cue नहीं है।
- Present-day giant forms powerful हैं, लेकिन future cold-open adults जितने trained नहीं सुनते।
- तीन-beat staff pulse और wing rhythm का सही/गलत संबंध कान से समझ आता है।
- लेडा के “सब रुको” पर mix सचमुच रुककर उसकी agency सुनाता है।
- Gate lock का `खट` music से नहीं ढका है।
- Gurukul reveal बड़ा है, पर final ring unresolved है।
- पूरा score serious adventure है; कोई pillow-fort, cute magic या comedy-chase रंग नहीं।
- कुल authorized audio spend 35 credits से ऊपर नहीं जा सकता।
