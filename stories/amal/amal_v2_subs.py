"""AMAL Ep1 v2 — English subtitle track (.srt) synced to the Hindi audio.
Narration cues = the English ACTION from the English script (EP1_PAGES_v2.md). Dialogue cues = an
English translation of each Hindi line (the audio is Hindi; the captions are English). Timing comes
from ep1_v2_timing.json; cues are chunked for readability and offset by the assemble LEAD.
-> stories/amal/ep1_v2_en.srt"""
import os, re, json
D = "/Users/dusty/dev/brehon-law/stories/amal"
LEAD = 4.0          # seconds of silence the assemble prepends before scene 1
norm = lambda s: re.sub(r"\s+", "", s)

# English translation of every Hindi dialogue line, keyed by the line (whitespace-insensitive).
PAIRS = [
 ("कांस्टेबल देवा। इतरसी से ट्रांसफर हुआ है। रतन सिंह पँवार साहब को रिपोर्ट करना है।", "Constable Deva. Transferred from Itarsi. I'm to report to Ratan Singh Panwar, sir."),
 ("साहब राउंड पे हैं।", "Sahib's out on rounds."),
 ("अच्छा। कब तक आ जाएँगे, जी?", "I see. When will he be back?"),
 ("आ जाएँगे।", "He'll come."),
 ("मैं... यहीं बैठ जाऊँ? या क्वार्टर —", "Should I... wait here? Or the quarters—"),
 ("बैठ जा।", "Sit."),
 ("वो... किसलिए दिया उसने?", "That... what did he give that for?"),
 ("चाय-पानी।", "Tea money."),
 ("किस बात की?", "For what, though?"),
 ("नया है। बैठ जा, बेटा। साहब आएँगे तो बता देंगे, किस बात की।", "You're new. Sit down, son. When the sahib comes he'll tell you what for."),
 ("साहब। कांस्टेबल देवा। आपके अंडर पोस्टिंग मिली है।", "Sir. Constable Deva. I've been posted under you."),
 ("हाँ।", "Yes."),
 ("साहब, ट्रैक्टर पलट गया था रात में, बड़े भाई पे। बस इतना लिख दीजिए कि हादसा था। घर में मातम है, साहब, और कुछ नहीं चाहिए।", "Sir, the tractor turned over in the night, on my elder brother. Just write that it was an accident. There's mourning at home, sir — we want nothing else."),
 ("हो गया। जा।", "Done. Go."),
 ("साहब... पोस्टमॉर्टम नहीं होगा?", "Sir... won't there be a postmortem?"),
 ("किसके लिए?", "For whom?"),
 ("आदमी मरा है, साहब। एक बार देख तो —", "A man's dead, sir. At least take a look—"),
 ("देख के क्या मिलेगा?", "And what will looking get you?"),
 ("...पता नहीं। पर नियम तो —", "...I don't know. But the rules—"),
 ("रोज़ कोई न कोई मरता है यहाँ। सबका पोस्टमॉर्टम करूँ तो और कोई काम नहीं हो पाएगा।", "Someone dies here every day. If I did a postmortem on each, nothing else would ever get done."),
 ("तू इतरसी से है ना।", "You're from Itarsi, aren't you."),
 ("जी।", "Yes, sir."),
 ("वहाँ अफ़ीम नहीं होती।", "They don't grow opium there."),
 ("अफ़ीम? मतलब... सच में?", "Opium? You mean... really?"),
 ("यहाँ की खेती है, सरकारी पट्टे पे। पूरा इलाक़ा इसी पे चलता है। ज़्यादा देखेगा तो सबसे पहले अपनी नौकरी जाएगी।", "It's the crop here, on a government licence. The whole district runs on it. Look too hard and the first thing you'll lose is your job."),
 ("ब्याज चढ़ता जा रहा है, सिंह साहब। मैं नहीं कहता, बहियाँ कहती हैं।", "The interest keeps mounting, Singh sahib. It's not me saying it — the ledgers say it."),
 ("अगले महीने बाक़ी।", "The rest next month."),
 ("ये तो ब्याज का भी आधा है।", "This is barely half the interest."),
 ("हर महीने यही सुनता हूँ, साहब। एक जौहरी आया था पिछले हफ़्ते। पुरानी मुहर है, सोना भारी है — अच्छा दाम देगा। मैं रोके बैठा हूँ, आपकी इज़्ज़त का सवाल है। पर कब तक?", "I hear the same thing every month, sahib. A jeweller came last week. It's an old signet, the gold is heavy — he'll pay well. I've held it back out of respect for you. But how long?"),
 ("वो मुहर बेचने की चीज़ नहीं है, सेठ।", "That signet is not a thing to be sold, seth."),
 ("चारण बाबा, फिर शुरू मत हो।", "Charan baba, don't start again."),
 ("वो मुहर पुरखों के रकत से भारी है, सोने से नहीं। सुनो, बेटा। राजा भोज का बंस था — परमार, पँवार। खिलजी की आँधी इसी माटी पे टूटी थी, सात सौ बरस पहले। पूरा गढ़ गिरा। और एक था जिसका सिर धड़ से अलग हो गया, और तलवार फिर भी चलती रही। गिर के भी नहीं गिरा। वो मुहर उसी की उँगली की है।", "That signet is heavy with the blood of ancestors, not with gold. Listen, son. They were of Raja Bhoj's line — Parmar, Panwar. Khilji's storm broke on this very soil, seven hundred years ago. The whole fort fell. And one had his head severed from his body, and still the sword kept moving. Fallen, he did not fall. That signet is from his finger."),
 ("सुबह कोटेश्वर के पास, खेत के किनारे एक लड़की पड़ी मिली, साहब।", "This morning, near Koteshwar, a girl was found at the edge of a field, sir."),
 ("किसकी?", "Whose?"),
 ("बड़े घर की। गिर गई होगी रात में, अँधेरे में। घरवाले कह रहे हैं जल्दी निपटा दो — शादी का घर है, बात फैलनी नहीं चाहिए।", "From the big house. Must have fallen in the night, in the dark. The family says settle it quickly — there's a wedding coming, word mustn't spread."),
 ("कौन सा बड़ा घर?", "Which big house?"),
 ("भेरूलाल सेठ का।", "Bherulal seth's."),
 ("लड़की थी?", "A girl, was it?"),
 ("थी। अब नहीं है।", "She was. Now she isn't."),
 ("रख दे, ढेर पे।", "Put it on the pile."),
 ("साहब। एक बार देख आएँ? पास ही तो है, कोटेश्वर। आधा घंटा।", "Sir. Should we go and look, just once? Koteshwar's close. Half an hour."),
 ("गिर गई।", "She fell."),
 ("आपने देखा नहीं और —", "You haven't even seen it, and—"),
 ("रिपोर्ट है ना सिपाही की।", "There's the constable's report, isn't there."),
 ("पर साहब, लड़की है, बड़े घर का मामला है, अगर कल कोई पूछे —", "But sir, it's a girl, it's a big house's matter — if someone asks tomorrow—"),
 ("कोई नहीं पूछेगा।", "No one will ask."),
 ("पेंशन के काग़ज़ आ गए आज। दफ़्तर से फ़ोन भी था। दो साल और।", "The pension papers came today. The office called as well. Two more years."),
 ("दो साल बाद घर पे रहेंगे। दिन भर क्या करेंगे, यही सोच रही हूँ। आप तो कभी घर पे रुके ही नहीं।", "Two years and you'll be home all day. I keep wondering what you'll do with yourself. You were never one to sit at home."),
 ("तेरे हाथ का खाना खाऊँगा।", "I'll eat your cooking."),
 ("मक्खन मत लगाइए। खाना खाइए, ठंडा हो रहा है।", "Don't sweet-talk me. Eat — it's going cold."),
 ("चार जने थे हम लोग, याद है? तू, मैं, ये, और कैलाश। अब दो बचे।", "There were four of us, remember? You, me, him, and Kailash. Now there are two left."),
 ("हम्म।", "Mm."),
 ("देख कितने लोग आए। तीन महीने पहले वर्दी में था आदमी, हुकुम चलता था इसका। रिटायर क्या हुआ, सब भूल गए। आज इतने भी नहीं कि चिता को कंधा देने वाले पूरे पड़ें।", "Look how many came. Three months ago the man was in uniform, gave the orders. He retired, and everyone forgot. Today there aren't even enough to carry the pyre."),
 ("अपने को कौन याद करेगा, रतन? दो-चार बरस, और अपनी भी यही राख है। न बेटा, न नाम — कोई पूछने वाला नहीं कि आदमी कैसा था।", "Who'll remember us, Ratan? A few years, and we're this same ash. No son, no name — no one to ask what kind of man he was."),
 ("याद है चंबल?", "Remember Chambal?"),
 ("छोड़ अब, गोविंद।", "Let it go now, Govind."),
 ("नहीं, सुन। बीहड़ में जब तू अकेला घुस गया था, उन डाकुओं के पीछे। पूरा थाना बाहर खड़ा था, पतलून गीली किए, और तू अंदर। और शाम तक तू उन्हें बाँध के बाहर ले आया। अकेला। अख़बार में फोटो छपी थी तेरी।", "No, listen. When you went alone into the ravines, after those dacoits. The whole station stood outside, wetting their trousers, and you went in. And by evening you brought them out tied up. Alone. Your photo was in the paper."),
 ("बहुत साल पहले की बात है। दूसरा आदमी था।", "That was many years ago. A different man."),
 ("वही तो। तू अलग था, रतन। हम सब भरती हुए थे पेट के लिए। तेरे में कुछ और था। आदमी कहाँ बदलता है, यार। बस दब जाता है, ऊपर से। मिट्टी पड़ जाती है। पर नीचे वही रहता है।", "Exactly. You were different, Ratan. The rest of us joined for the wages. There was something else in you. A man doesn't really change, brother. He just gets buried, on top. The earth covers him. But underneath, he's the same."),
 ("किसने पाया?", "Who found her?"),
 ("मैंने, साहब। सुबह, भैंस लेके आया था। यहीं पड़ी थी।", "I did, sir. In the morning, I'd brought the buffalo. She was lying right here."),
 ("किस तरफ़ मुँह?", "Which way was she facing?"),
 ("नीचे। मेड़ के नीचे।", "Face down. Below the bund."),
 ("घुटने भर का मेड़।", "A bund knee-high."),
 ("साहब?", "Sir?"),
 ("कुछ नहीं।", "Nothing."),
 ("रात में अँधेरे में गिर गई होगी, साहब। चक्कर आ गया होगा। लड़कियाँ कमज़ोर होती हैं।", "She must have fallen in the dark, sir. Felt dizzy, maybe. Girls are weak."),
 ("साहब, वो तो कल बंद हो गई थी। आपने ही साइन किया था।", "Sir, that was closed yesterday. You signed it off yourself."),
 ("खोल रहा हूँ फिर से।", "I'm opening it again."),
 ("पोस्टमॉर्टम के लिए? साहब, बड़े घर का मामला है। भेरूलाल सेठ का। उन्होंने ख़ुद कहलवाया था जल्दी निपटाने को।", "For a postmortem? Sir, it's a big house's matter. Bherulal seth's. He sent word himself to settle it fast."),
 ("तो?", "So?"),
 ("तो... कुछ नहीं, साहब। बस... बात ऊपर तक जाएगी।", "So... nothing, sir. Just... word will reach the top."),
 ("इसे आज ही भिजवा। यहीं ज़िले के अस्पताल, डॉक्टर भँवर के पास।", "Send it today. The district hospital here, to Dr. Bhanwar."),
 ("अरे बैठ, रतन। बैठ। चाय बोलूँ? सुन, ये कोटेश्वर वाली फ़ाइल। पोस्टमॉर्टम भिजवा दी तूने?", "Arre, sit, Ratan, sit. Shall I send for tea? Listen, this Koteshwar file. You've sent it for a postmortem?"),
 ("भिजवा दी।", "I have."),
 ("पच्चीस साल की नौकरी है तेरी, यार। दो साल बचे हैं। और तू एक गिरी हुई लड़की पे — किसलिए? बता तो सही, हुआ क्या है।", "Twenty-five years of service, yaar. Two left. And you, over a girl who fell — what for? Tell me, what's the matter?"),
 ("मेड़ घुटने भर का था।", "The bund was knee-high."),
 ("तो? लोग घुटने भर से भी गिर के मर जाते हैं, फिसल के सिर लग जाए तो। देख। फ़ाइल बंद थी। बंद रहने दे। आराम से दो साल काट, पेंशन ले, घर बैठ। इस झंझट में क्या रखा है — एक लड़की, बड़ा घर, ऊपर तक रसूख़। जाने दे, भाई। मेरे लिए नहीं, अपने लिए।", "So? People die falling from knee height too, if the head hits wrong. Look. The file was closed. Let it stay closed. Do your two years in peace, take your pension, go home. What's in this mess — one girl, a big house, reach to the very top. Let it go, brother. Not for me — for yourself."),
 ("हो गया, मिश्रा। चली गई फ़ाइल।", "It's done, Mishra. The file's gone."),
 ("चली गई। ठीक है। चाय पी के जा।", "Gone. All right. Have your tea before you go."),
 ("साहब... वो... कम हो रहा है।", "Sir... it's... going down."),
 ("काल भैरव हैं, बेटा। अवंती के कोतवाल। इन पे फूल-पत्ती नहीं चढ़ती ज़्यादा। न मिठाई, न सिफ़ारिश। बस यही — दारू। और जो झूठ बोले इनके सामने, उसका हिसाब ये ख़ुद लेते हैं। किसी थाने की ज़रूरत नहीं।", "It's Kaal Bhairav, son. The kotwal of Avanti. Flowers don't move him much. No sweets, no recommendations. Only this — liquor. And whoever lies before him, he settles the account himself. He needs no police station."),
 ("तुम पुलिस वाले अब आए हो? लड़की तो जल गई कल।", "You police have come now? The girl was burned yesterday."),
 ("माँजी, उसकी शादी की कोई बात थी?", "Mother, was there talk of her marriage?"),
 ("बात! तय हो गई थी। धनराज सेठ से।", "Talk! It was fixed. To Dhanraj seth."),
 ("धनराज? वो तो... मैंने सुना है वो बूढ़ा आदमी है।", "Dhanraj? But... I've heard he's an old man."),
 ("साठ का है, बेटा, कम नहीं। पर यहाँ उमर नहीं देखते। हैसियत देखते हैं। घर पे कर्ज़ा था भेरूलाल के — पट्टे की औसत पूरी नहीं हुई दो साल से। तो लड़की उतार दो कर्ज़े में, बूढ़े के घर। ऐसे ही चलता है।", "Sixty, son, not a day less. But here they don't look at age. They look at standing. Bherulal had debt on the house — the licence quota hasn't been met for two years. So hand the girl over against the debt, into the old man's house. That's how it goes."),
 ("खा, खा। दुबला हो गया है। और सुन, लड़के की फोटो आई है राजस्थान से। अच्छा घर है, खाता-पीता। मंजू वहाँ राज करेगी। सरहद पार है बस, पर बस का सीधा है, तीन घंटे में।", "Eat, eat. You've gone thin. And listen, the boy's photo came from Rajasthan. Good family, well-off. Manju will rule the house there. It's just across the border, but there's a direct bus, three hours."),
 ("मंजू। तू देखी है फोटो? तुझे... ठीक लगा?", "Manju. Have you seen the photo? Did it... seem all right to you?"),
 ("जैसा आप सब ठीक समझें, भैया।", "Whatever you all think best, brother."),
 ("मैं तुझसे पूछ रहा हूँ। तुझे।", "I'm asking you. You."),
 ("अरे, क्या पूछ रहा है इससे। शरमाती है। तू बस अपनी नौकरी ठीक से कर, बाक़ी सब हो जाएगा।", "Oh, what are you asking her for. She's shy. You just do your job properly, the rest takes care of itself."),
 ("उसी दिन?", "The same day?"),
 ("डॉक्टर साहब ने जल्दी कर दी, साहब। बोले, आपका मामला है, अटकाना नहीं।", "The doctor was quick, sir. Said it's your case, not to hold it up."),
 ("रिपोर्ट मिल गई होगी। साफ़ है। गिरने से मौत।", "You'll have got the report. It's clean. Death by a fall."),
 ("उसी दिन कैसे साफ़ हो गई, भँवर?", "How did it come back clean the same day, Bhanwar?"),
 ("नियम से हुआ है। पच्चीस साल से यही नियम है, सिंह साहब। और तेरे भी इतने केस इसी नियम से बंद हुए हैं। एक बार भी तूने नहीं पूछा \"उसी दिन कैसे।\" आज क्या बदल गया?", "It was done by the rules. The same rules for twenty-five years, Singh sahib. And this many of your cases were closed by these same rules. Not once did you ask 'how, the same day.' What's changed today?"),
 ("पता नहीं।", "I don't know."),
 ("घर जा, सिंह साहब। दो साल बचे हैं तेरे। एक मरी हुई लड़की के लिए उन्हें ख़राब मत कर। वो वापस नहीं आएगी, और तू भी नहीं आएगा।", "Go home, Singh sahib. You've two years left. Don't ruin them for a dead girl. She isn't coming back — and neither are you."),
 ("तू उस रात खेत पे था?", "Were you in the field that night?"),
 ("मैं कुछ नहीं जानता, साहब। मज़दूर आदमी हूँ। सुबह आता हूँ, शाम जाता हूँ।", "I know nothing, sir. I'm a labouring man. I come at dawn, I leave at dusk."),
 ("मैं तुझे फँसा नहीं रहा। बस पूछ रहा हूँ।", "I'm not trapping you. I'm only asking."),
 ("बड़ा घर है उधर, साहब। भेरूलाल सेठ का। उधर का मामला है। मुझसे मत पूछो।", "It's a big house over there, sir. Bherulal seth's. It's their matter. Don't ask me."),
 ("अब आए हो।", "Now you come."),
 ("...सुगना।", "...Sugna."),
 ("वर्दी में आए हो। पूछताछ करने।", "You've come in uniform. To ask questions."),
 ("मुझे नहीं पता था कि ये तेरा घर है। सच कह रहा हूँ, सुगना। मुझे नहीं —", "I didn't know this was your house. I'm telling the truth, Sugna. I didn't—"),
 ("तुझे कभी कुछ पता कहाँ था।", "When did you ever know anything."),
 ("किसकी... किसकी लड़की थी?", "Whose... whose girl was she?"),
 ("लीला थी। सुगना की बड़ी बेटी। सोलह की थी बस।", "It was Leela. Sugna's eldest daughter. Only sixteen."),
 ("मैंने...", "I..."),
 ("तूने क्या?", "You what?"),
 ("कौन है? ...ओह।", "Who is it? ...Oh."),
 ("मेरा भाई। पुलिस में है। पच्चीस साल से नहीं आया। आज आया है।", "My brother. He's in the police. Hasn't come in twenty-five years. Today he's come."),
 ("पच्चीस साल इस घर का मुँह नहीं देखा तुमने। सुगना का भाई हो, और शादी में नहीं आए, बेटी होने पे नहीं आए, कुछ नहीं। और आज, इसी रात, चले आए। वर्दी पहन के।", "Twenty-five years you didn't show your face at this house. You're Sugna's brother, and you didn't come for the wedding, didn't come when the daughters were born, nothing. And today, this very night, here you are. In uniform."),
 ("लड़की कैसे मरी, भेरूलाल?", "How did the girl die, Bherulal?"),
 ("जो हुआ सो हुआ। लीला चली गई। उससे क्या लौटेगा? अब अगर पुलिस आए, पोस्टमॉर्टम हो, बात फैले — तो किसका नुक़सान? तुम्हारी बहन का। इस घर का। छोटा है ना, चार साल का। उसके नाम पट्टा बनना है अगले साल। उसके लिए घर का नाम साफ़ चाहिए। एक मरी हुई लड़की के लिए ज़िंदा बच्चे का भविष्य नहीं डुबाते।", "What's done is done. Leela's gone. What comes back from that? Now if the police come, a postmortem, word spreads — whose loss is it? Your sister's. This house's. The little one, four years old. The licence is to be made in his name next year. For that the family name must be clean. You don't sink a living child's future for a dead girl."),
 ("इलाके में हादसे होते रहते हैं, साहब। आदमी रात को निकलता है, बाइक फिसल जाती है, बस। होता रहता है। आप तो जानते ही हो।", "Accidents keep happening in these parts, sir. A man goes out at night, the bike slips, that's all. It happens. You know that well enough."),
]
EN_D = {norm(h): e for h, e in PAIRS}

# English ACTION per scene, in order, from the English script.
en_action = {}
scene, buf = 0, []
def flush_act():
    if buf:
        en_action.setdefault(scene, []).append(" ".join(buf)); buf.clear()
for raw in open(f"{D}/EP1_PAGES_v2.md", encoding="utf-8").read().splitlines():
    ln = raw.strip()
    m = re.match(r"^## SCENE (\d+)", ln)
    if m:
        flush_act(); scene = int(m.group(1)); continue
    if not scene or not ln or ln.startswith(("#", "**", "*", "---", "|", ">")):
        flush_act(); continue
    if re.match(r"^[A-Z][A-Z .()]+:\s", ln):       # a dialogue cue -> not action
        flush_act(); continue
    buf.append(ln)
flush_act()

man = json.load(open(f"{D}/ep1_v2_timing.json", encoding="utf-8"))
segs = man["segments"]


def chunks(text, n=12):
    w = text.split()
    return [" ".join(w[i:i + n]) for i in range(0, len(w), n)] or [text]


def ts(t):
    t = max(0.0, t); h = int(t // 3600); m = int(t % 3600 // 60); s = t % 60
    return f"{h:02d}:{m:02d}:{s:06.3f}".replace(".", ",")


idx, out, miss = {}, [], 0
cue = 1
for s in segs:
    en = ""
    if s["spk"] == "N":
        lst = en_action.get(s["scene"], [])
        k = idx.get(s["scene"], 0); idx[s["scene"]] = k + 1
        en = lst[k] if k < len(lst) else ""
    else:
        en = EN_D.get(norm(s["hi"]), "")
        if not en:
            miss += 1; en = s["hi"]            # fallback: show the Hindi, flag it
    if not en.strip():
        continue
    parts = chunks(en)
    start = s["start"] + LEAD
    per = s["dur"] / len(parts)
    for j, p in enumerate(parts):
        a = start + j * per; b = a + per - 0.05
        out.append(f"{cue}\n{ts(a)} --> {ts(b)}\n{p}\n"); cue += 1

open(f"{D}/ep1_v2_en.srt", "w", encoding="utf-8").write("\n".join(out))
print(f"subtitles: {cue-1} cues -> ep1_v2_en.srt  (dialogue misses: {miss})", flush=True)
