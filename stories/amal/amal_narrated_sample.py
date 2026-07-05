"""AMAL — narrated-sample: Sc9 the full way — Hindi सूत्रधार narration woven through the dialogue,
with the ambient bed. Validates narrator language + voice + the mix before the 37-scene render."""
import os, sys, hashlib, subprocess
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import backends as bk

D = "/Users/dusty/dev/brehon-law/stories/amal"
A = f"{D}/_narr_sample"; os.makedirs(A, exist_ok=True)
VID = {"N": "ocf4J1Vk0yOOFNBy3kNq",        # narrator candidate (grave male)
       "RATAN": "XSBqeYvLRWlUwJ57A64w", "DEVA": "5ycO0zpSCEkvR4Ri6gk9"}

# Sc9 in order: N = Hindi narration of the action; RATAN/DEVA = dialogue
SEGS = [
 ("N", "सड़क किनारे एक ढाबे पे जीप रुकी है। रतन और देवा खाट पे बैठे हैं, बीच में दाल-बाफले की दो थालियाँ। सुबह की लाश के बाद से देवा चुप है।"),
 ("DEVA", "साहब... सुबह वाला आदमी। सच में ट्रैक्टर?"),
 ("N", "रतन बाफला तोड़ के खाता है।"),
 ("RATAN", "तू क्या समझता है?"),
 ("DEVA", "मुझे लगा किसी ने मारा।"),
 ("RATAN", "तो?"),
 ("DEVA", "तो हम पुलिस हैं, साहब। रिपोर्ट सही होनी चाहिए।"),
 ("N", "रतन उसकी तरफ़ देखता है — नई वर्दी, शहर का भरोसा।"),
 ("RATAN", "पुलिस। यहाँ हर महीने चार-पाँच लाशें गिरती हैं, देवा। किसान, मज़दूर, कभी कोई औरत। सब हादसा। तू हर एक का पोस्टमॉर्टम करवाएगा?"),
 ("DEVA", "ज़रूरत हो तो —"),
 ("RATAN", "किसके खिलाफ़ लिखेगा? नाम पता है? जिसके खिलाफ़ लिखेगा वो थाने से बड़ा है, एमएलए से बड़ा है। तेरी रिपोर्ट उसके घर चाय के साथ पहुँचती है।"),
 ("N", "देवा के पास इसका कोई जवाब नहीं।"),
 ("RATAN", "एक था, मेरे साथ। बहुत साल पहले। तेरे जैसा। सब सही करना चाहता था।"),
 ("DEVA", "फिर?"),
 ("RATAN", "फिर एक दिन वो भी हादसे में गया। बाइक फिसल गई। रिपोर्ट मैंने लिखी थी।"),
 ("N", "ख़ामोशी। देवा उसे देखता रहता है। रतन खाता रहता है।"),
 ("RATAN", "यहाँ टिकना है तो दो बात याद रख — देखना मत, पूछना मत। जो हाथ में आए रख ले, और शाम को ज़िंदा घर चला जा।"),
 ("DEVA", "ये क़ानून है?"),
 ("RATAN", "ये ज़िंदा रहना है। क़ानून किताब में है, और किताब शहर में है। तू शहर छोड़ के आ गया।"),
 ("N", "देवा अपनी थाली की तरफ़ देखता है। उसका भरोसा थोड़ा कम हो गया है।"),
 ("DEVA", "लोग कहते थे आप अलग हो।"),
 ("N", "रतन जवाब नहीं देता। खाना खत्म करके उठ जाता है।"),
 ("RATAN", "चल। दिन बाक़ी है।"),
 ("N", "वो जीप की तरफ़ चल देता है। देवा एक पल और बैठा रहता है, फिर पीछे जाता है।"),
]

ff = lambda a: subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y"] + a, check=True)
cache = lambda k: f"{A}/s_{hashlib.sha1(k.encode()).hexdigest()[:16]}.mp3"

parts, i = [], 0
while i < len(SEGS):
    spk, txt = SEGS[i]
    if spk == "N":
        p = cache("N|" + txt)
        if not os.path.exists(p):
            open(p, "wb").write(bk.elevenlabs_tts(txt, VID["N"]))
        parts.append(p); i += 1
    else:
        run = []
        while i < len(SEGS) and SEGS[i][0] != "N":
            run.append(SEGS[i]); i += 1
        p = cache("D|" + "|".join(f"{s}:{t}" for s, t in run))
        if not os.path.exists(p):
            open(p, "wb").write(bk.elevenlabs_dialogue([{"text": t, "voice_id": VID[s]} for s, t in run]))
        parts.append(p)
    print(f"  {len(parts)} segments", flush=True)

gap = bk.silence(300, A)
seq = [x for j, p in enumerate(parts) for x in ((gap, p) if j else (p,))]
norm = []
for k, p in enumerate(seq):
    nf = f"{A}/_n{k:03d}.mp3"; ff(["-i", p, "-ar", "44100", "-ac", "1", "-c:a", "libmp3lame", "-b:a", "160k", nf]); norm.append(nf)
open(f"{A}/_l.txt", "w").write("".join(f"file '{os.path.abspath(q)}'\n" for q in norm))
ff(["-f", "concat", "-safe", "0", "-i", f"{A}/_l.txt", "-c", "copy", f"{A}/voices.mp3"])
VD = bk.duration(f"{A}/voices.mp3")
ff(["-f", "lavfi", "-i", f"anoisesrc=color=brown:amplitude=0.16:duration={VD}", "-f", "lavfi",
    "-i", f"sine=frequency=62:duration={VD}", "-filter_complex",
    "[0:a]lowpass=f=200[r];[1:a]tremolo=f=0.3:d=0.5,volume=0.4[c];[r][c]amix=inputs=2:normalize=0,volume=0.5[b]",
    "-map", "[b]", "-t", f"{VD}", "-c:a", "libmp3lame", f"{A}/bed.mp3"])
ff(["-i", f"{A}/voices.mp3", "-i", f"{A}/bed.mp3", "-filter_complex",
    "[0:a]volume=1.2[v];[1:a]volume=0.10[b];[v][b]amix=inputs=2:duration=first:normalize=0,volume=0.96[o]",
    "-map", "[o]", "-c:a", "libmp3lame", "-b:a", "192k", f"{D}/amal_narrated_sc9.mp3"])
print(f"DONE -> amal_narrated_sc9.mp3 ({bk.duration(f'{D}/amal_narrated_sc9.mp3'):.0f}s)", flush=True)
