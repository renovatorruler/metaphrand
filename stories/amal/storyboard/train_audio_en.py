"""अमल — The Train: ENGLISH version. Same authentic-Indian cast reading English (Indian-accented, true
to the characters); neutral-US narrator unchanged. Indian-English register kept (bhaiya, sahab, na).
"""
import os, sys, hashlib, subprocess
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import backends as bk

D = "/Users/dusty/dev/brehon-law/stories/amal/storyboard"
A = f"{D}/train_audio_en"; os.makedirs(A, exist_ok=True)

VID = {"N": "nPczCjzI2devNBz1zQrb", "WOMAN": "FFmp1h1BMl0iVHA0JxrI", "KAMLA": "bBX9H7So8de80VyvKd7E",
       "SURESH": "XSBqeYvLRWlUwJ57A64w", "RAJESH": "5ycO0zpSCEkvR4Ri6gk9", "CONSTABLE": "XYJilqzgZnnmkbEWyhtr"}

SCENE = [
 ("N", "A crowded train, the heat sitting heavy in the carriage. By the barred window, a woman holds a baby wrapped to the crown in a faded green cloth. Across from her, a tired husband, his wife mid-sentence, and his younger brother."),
 ("KAMLA", "[cheerfully] I told you na, we should have caught the morning train. Now sit in this heat. And that pickle box, did you put it up top or down below? I can't even remember now."),
 ("SURESH", "[tired] It's somewhere."),
 ("KAMLA", "[chattering] And phone jijaji the moment we get off, otherwise he'll sit with a long face the whole wedding."),
 ("KAMLA", "[swatting at flies] Uff, where have all these flies come from. Sister, they are buzzing right over you. Have you kept something sweet there?"),
 ("N", "The woman only shakes her head. She says nothing."),
 ("KAMLA", "[warmly, prying] How many months is he? It's a boy, na?"),
 ("KAMLA", "[concerned] You have wrapped the poor thing so tight in this heat, won't he suffocate? Open it a little from the top."),
 ("WOMAN", "[flatly, guarded] He is sleeping. He is fine."),
 ("N", "Suresh has stopped listening to his wife. He is watching the woman. The flat hand. The cloth drawn over the child's face. He stands, stretches, angles for a look at the baby, and she turns the bundle away."),
 ("SURESH", "[low, quietly] Rajesh. Come here a second. Look at that woman. The baby. It is so hot and she has covered even his face. And since the train started, did you see that baby move even once?"),
 ("RAJESH", "[dismissively] He's sleeping, bhaiya. Small babies sleep all day. And they catch cold quickly also. You, honestly."),
 ("N", "At the next station Suresh gets down, and comes back to the window with a packet of snacks, holding it up to his wife."),
 ("SURESH", "[casual, over-friendly] Here, take this. Do you want water also?"),
 ("KAMLA", "[pleased, chattering] Arre, so many things you have brought. Keep some for Rajesh also. Did you get the salty one or the sweet one?"),
 ("N", "As she takes the packet, Suresh leans in at the window, and his eyes go past her, to the woman and the bundle."),
 ("SURESH", "[casual, probing] Everything all right, sister? How is the little one keeping? ... Can I see his face, just once?"),
 ("WOMAN", "[guarded, drawing the cloth closed] He is fine. He is sleeping."),
 ("N", "The whistle goes. Suresh climbs back up and sits, but he keeps looking down the carriage. He cannot let it go."),
 ("SURESH", "[quietly, certain] I am telling you, something is wrong. I asked to see the baby's face, twice, she would not show. My heart won't accept it."),
 ("RAJESH", "[brushing it off] Bhaiya, leave it. A woman is travelling alone with a small child, and you are staring and questioning her. Someone will make a scene."),
 ("KAMLA", "[leaning in] What is it? What are you two going on about?"),
 ("RAJESH", "[low] Bhaiya thinks there is something wrong with that woman's baby."),
 ("KAMLA", "[hushed, drawn in] You know, I also did not feel right. I told her to open the cloth and she just would not. And the child has not made one sound, not once. And those flies... ram ram."),
 ("RAJESH", "[wavering] You two are imagining things. ... Though the flies are a bit much."),
 ("SURESH", "[decided] At the next station, I am telling the constable. Let them check, that is all."),
 ("N", "The woman has gone very still, listening to the shape of it. At the next station she watches the two men get off, leans to the window, and sees Suresh talking to a constable, pointing back at the carriage. She gets up, leaves her trunk, and moves quickly into the next bogie, the bundle held close."),
 ("KAMLA", "[pointing, urgent] She went that way, into the next bogie."),
 ("N", "The constables reach her in the crowded aisle."),
 ("CONSTABLE", "[sternly, calm] Madam, stop a moment. We need to talk, two minutes."),
 ("WOMAN", "[agitated, loud] What is it? What have I done? That man has been after me since morning. He saw a woman alone, so I left my seat and came here."),
 ("WOMAN", "[angrily, accusing] He was looking at me with dirty eyes. His own wife is sitting right there, ask her."),
 ("SURESH", "[insistent] Madam, just show the baby once. Just once."),
 ("WOMAN", "[clutching the bundle] My baby is sleeping."),
 ("CONSTABLE", "[reassuringly] We won't wake him, madam. Just one look, and you go on your way."),
 ("N", "Cornered, she folds the green cloth down from the top. A baby's face shows in the gap, eyes closed, still. It could be a child asleep. The constable lets his breath out."),
 ("CONSTABLE", "[relieved, then annoyed] He is only sleeping. Why are you troubling her for nothing, bhai sahab? Come on."),
 ("SURESH", "[desperately] Sahab, wait. Look properly. Open it fully."),
 ("CONSTABLE", "[sharply, angry] That is enough now! The lady is travelling alone and you have been after her since morning. Move aside."),
 ("N", "Suresh looks at the bundle, at the flies. Then he steps in and pulls the child out of her arms."),
 ("WOMAN", "[screaming] No! Don't touch him! Let go! Give him back to me!"),
 ("N", "The green cloth comes away. The face that looked asleep does not change, and below it the small body has been opened at the belly and stitched and split, and the opium spills out onto the berth. For one second no one moves. Then she throws herself at him, and the constables catch her and hold her."),
 ("WOMAN", "[wailing, breaking] My baby! Give him! He is my baby!"),
 ("N", "Her screaming fills the carriage, and goes on filling it, as we pull away."),
]


def ff(args):
    subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y"] + args, check=True)


def cached(key):
    p = f"{A}/seg_{hashlib.sha1(key.encode()).hexdigest()[:16]}.mp3"
    return p, os.path.exists(p)


parts = []
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
            open(p, "wb").write(bk.elevenlabs_dialogue([{"text": t, "voice_id": VID[r]} for r, t in run]))
        parts.append(p)
    print(f"  segment {len(parts)} done", flush=True)

gap = bk.silence(320, A)
seq = []
for j, p in enumerate(parts):
    if j: seq.append(gap)
    seq.append(p)
norm = []
for k, p in enumerate(seq):
    nf = f"{A}/_norm{k:03d}.mp3"
    ff(["-i", p, "-ar", "44100", "-ac", "1", "-c:a", "libmp3lame", "-b:a", "160k", nf]); norm.append(nf)
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
    "-map", "[out]", "-c:a", "libmp3lame", "-b:a", "192k", f"{D}/train_scene_audio_en.mp3"])
print(f"DONE -> train_scene_audio_en.mp3 ({bk.duration(f'{D}/train_scene_audio_en.mp3'):.0f}s)", flush=True)
