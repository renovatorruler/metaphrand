"""अमल — The Train: multi-voice audio drama with v3 expression tags.

Hindi character lines render as multi-speaker dialogue takes (authentic Indian voices, the cast playing
off each other); the narrator (Brian, neutral US) renders as clean single-voice English for the action.
Then a synthesized train bed under it all.
"""
import os, sys, hashlib, subprocess
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import backends as bk

D = "/Users/dusty/dev/brehon-law/stories/amal/storyboard"
A = f"{D}/train_audio"; os.makedirs(A, exist_ok=True)

VID = {"N": "nPczCjzI2devNBz1zQrb",          # Brian — neutral US narrator (English)
       "WOMAN": "FFmp1h1BMl0iVHA0JxrI",      # Tarini
       "KAMLA": "bBX9H7So8de80VyvKd7E",      # Leela Ben (aunty)
       "SURESH": "XSBqeYvLRWlUwJ57A64w",     # Natraj
       "RAJESH": "5ycO0zpSCEkvR4Ri6gk9",     # Shyam
       "CONSTABLE": "XYJilqzgZnnmkbEWyhtr"}  # Ash

# ordered scene: ("N", english action) or (role, "[v3 tag] hindi line")
SCENE = [
 ("N", "A crowded train, the heat sitting heavy in the carriage. By the barred window, a woman holds a baby wrapped to the crown in a faded green cloth. Across from her, a tired husband, his wife mid-sentence, and his younger brother."),
 ("KAMLA", "[cheerfully] मैंने कहा था ना सुबह वाली गाड़ी पकड़ लेते। अब बैठो इस लू में। और वो अचार वाला डब्बा तुमने ऊपर रखा कि नीचे? मुझे तो याद ही नहीं आ रहा।"),
 ("SURESH", "[tired] रखा है कहीं।"),
 ("KAMLA", "[chattering] और जीजाजी को फ़ोन कर देना उतरते ही, वरना वो फिर शादी भर मुँह फुलाए बैठे रहेंगे।"),
 ("KAMLA", "[swatting at flies] उई, ये मक्खियाँ कहाँ से आ गईं इतनी। बहन, तुम्हारे ही ऊपर भिनभिना रही हैं। कुछ मीठा रखा है क्या साथ में?"),
 ("N", "The woman only shakes her head. She says nothing."),
 ("KAMLA", "[warmly, prying] कितने महीने का है? लड़का है ना?"),
 ("KAMLA", "[concerned] इतनी गरमी में इत्ता लपेट के रखा है बेचारे को, घुटन नहीं होगी उसको? ज़रा खोलो ऊपर से।"),
 ("WOMAN", "[flatly, guarded] सो रहा है। ठीक है वो।"),
 ("N", "Suresh has stopped listening to his wife. He is watching the woman. The flat hand. The cloth drawn over the child's face. He stands, stretches, angles for a look at the baby, and she turns the bundle away."),
 ("SURESH", "[low, quietly] राजेश। इधर आ ज़रा। उस औरत को देख। बच्चे को। इतनी गरमी है और मुँह तक ढका है। और गाड़ी चली तब से, वो बच्चा एक बार हिला तेरे को?"),
 ("RAJESH", "[dismissively] सो रहा होगा भैया। छोटे बच्चे दिन भर सोते हैं। ठंड भी जल्दी लग जाती है इनको। तुम भी ना।"),
 ("N", "At the next station, Suresh comes to the window from the platform."),
 ("SURESH", "[nervously] बहन। बच्चा ठीक तो है ना? ज़रा चेहरा दिखाओ, एक बार।"),
 ("WOMAN", "[defensively] आप अपना देखो। ठीक है वो।"),
 ("N", "Back in his seat, he can't let it go."),
 ("SURESH", "[quietly, certain] मैं कह रहा हूँ कुछ गड़बड़ है। मेरा दिल नहीं मान रहा।"),
 ("RAJESH", "[brushing it off] भैया छोड़ो भी। फ़ालतू में दिमाग़ खराब मत करो।"),
 ("KAMLA", "[leaning in] क्या हुआ? क्या छोड़ दूँ?"),
 ("RAJESH", "[low] भैया को लग रहा है उस औरत के बच्चे में कुछ गड़बड़ है।"),
 ("KAMLA", "[hushed] मुझे भी ना ठीक नहीं लगा था। मैंने खोलने को बोला तो खोला ही नहीं। और वो मक्खियाँ... राम राम।"),
 ("SURESH", "[decided] अगले स्टेशन पे मैं सिपाही को बता दूँगा।"),
 ("N", "The woman has gone very still, listening to the shape of it. At the next station she watches the two men get off, leans to the window, and sees Suresh talking to a constable, pointing back at the carriage. She gets up, leaves her trunk, and moves quickly into the next bogie, the bundle held close."),
 ("KAMLA", "[pointing, urgent] उधर गई, उस तरफ़ वाले डिब्बे में।"),
 ("N", "The constables reach her in the crowded aisle."),
 ("CONSTABLE", "[sternly, calm] बहन जी, ज़रा रुकिए। दो मिनट बात करनी है।"),
 ("WOMAN", "[agitated, loud] क्या है? मैंने क्या किया? वो आदमी मेरे पीछे पड़ा है तब से। औरत अकेली देखी तो, मैं इसीलिए सीट छोड़ के आई।"),
 ("WOMAN", "[angrily, accusing] गंदी नज़र से देख रहा था मुझे। इसकी घरवाली बैठी है वहीं, पूछ लो।"),
 ("SURESH", "[insistent] मैडम, बस बच्चा एक बार दिखा दो। बस एक बार।"),
 ("WOMAN", "[clutching the bundle] बच्चा सो रहा है मेरा।"),
 ("CONSTABLE", "[reassuringly] अरे जगाएँगे नहीं बहन जी। बस एक नज़र, और आप जाओ अपने रास्ते।"),
 ("N", "Cornered, she folds the green cloth down from the top. A baby's face shows in the gap, eyes closed, still. It could be a child asleep. The constable lets his breath out."),
 ("CONSTABLE", "[relieved, then annoyed] सो ही तो रहा है। क्यों बेकार में परेशान कर रहे हो भाई साहब? चलो।"),
 ("SURESH", "[desperately] साहब, रुको। ठीक से देखो ज़रा। पूरा खोल के।"),
 ("CONSTABLE", "[sharply, angry] बस करो अब! बहन जी अकेली जा रही हैं और तुम सुबह से पीछे पड़े हो। चलो हटो।"),
 ("N", "Suresh looks at the bundle, at the flies. Then he steps in and pulls the child out of her arms."),
 ("WOMAN", "[screaming] नहीं! मत छू उसको! छोड़! दे दे मुझे!"),
 ("N", "The green cloth comes away. The face that looked asleep does not change, and below it the small body has been opened at the belly and stitched and split, and the opium spills out onto the berth. For one second no one moves. Then she throws herself at him, and the constables catch her and hold her."),
 ("WOMAN", "[wailing, breaking] मेरा बच्चा! दे दो! मेरा बच्चा है वो!"),
 ("N", "Her screaming fills the carriage, and goes on filling it, as we pull away."),
]


def ff(args):
    subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y"] + args, check=True)


def cached(key):
    p = f"{A}/seg_{hashlib.sha1(key.encode()).hexdigest()[:16]}.mp3"
    return p, os.path.exists(p)


parts = []
# walk the scene, grouping consecutive Hindi (character) lines into multi-speaker dialogue takes
i = 0
while i < len(SCENE):
    role, text = SCENE[i]
    if role == "N":
        p, hit = cached("N|" + text)
        if not hit:
            open(p, "wb").write(bk.elevenlabs_tts(text, VID["N"]))
        parts.append(p); i += 1
    else:
        run = []
        while i < len(SCENE) and SCENE[i][0] != "N":
            run.append(SCENE[i]); i += 1
        key = "DLG|" + "|".join(f"{r}:{t}" for r, t in run)
        p, hit = cached(key)
        if not hit:
            inputs = [{"text": t, "voice_id": VID[r]} for r, t in run]
            open(p, "wb").write(bk.elevenlabs_dialogue(inputs))
        parts.append(p)
    print(f"  segment {len(parts)} done", flush=True)

# concat with small gaps; normalize every part to a uniform format first — the dialogue takes and the
# narrator TTS come back with different channel/rate params, which breaks the concat demuxer
gap = bk.silence(320, A)   # milliseconds
seq = []
for j, p in enumerate(parts):
    if j: seq.append(gap)
    seq.append(p)
norm = []
for k, p in enumerate(seq):
    nf = f"{A}/_norm{k:03d}.mp3"
    ff(["-i", p, "-ar", "44100", "-ac", "1", "-c:a", "libmp3lame", "-b:a", "160k", nf])
    norm.append(nf)
lst = f"{A}/_list.txt"
open(lst, "w").write("".join(f"file '{os.path.abspath(q)}'\n" for q in norm))
ff(["-f", "concat", "-safe", "0", "-i", lst, "-c", "copy", f"{A}/voices.mp3"])
VD = bk.duration(f"{A}/voices.mp3")
print(f"voices: {VD:.1f}s", flush=True)

ff(["-f", "lavfi", "-i", f"anoisesrc=color=brown:amplitude=0.28:duration={VD}",
    "-f", "lavfi", "-i", f"anoisesrc=color=pink:amplitude=0.14:duration={VD}",
    "-f", "lavfi", "-i", f"sine=frequency=70:duration={VD}",
    "-filter_complex",
    "[0:a]lowpass=f=240[r];[1:a]bandpass=f=900:width_type=h:w=1300,tremolo=f=11:d=0.5[t];"
    "[2:a]tremolo=f=1.7:d=0.92,lowpass=f=150,volume=0.7[c];[r][t][c]amix=inputs=3:normalize=0,highpass=f=38,volume=0.8[bed]",
    "-map", "[bed]", "-t", f"{VD}", "-c:a", "libmp3lame", f"{A}/bed.mp3"])
ff(["-i", f"{A}/voices.mp3", "-i", f"{A}/bed.mp3", "-filter_complex",
    "[0:a]volume=1.25[v];[1:a]volume=0.16[b];[v][b]amix=inputs=2:duration=first:normalize=0,volume=0.95[out]",
    "-map", "[out]", "-c:a", "libmp3lame", "-b:a", "192k", f"{D}/train_scene_audio.mp3"])
print(f"DONE -> train_scene_audio.mp3 ({bk.duration(f'{D}/train_scene_audio.mp3'):.0f}s)", flush=True)
