import os, sys, json, subprocess
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import backends as bk
from examples import score

ROOT = "/Users/dusty/dev/brehon-law"
BASE = f"{ROOT}/stories/sky-king"
TMP = f"{BASE}/audio_v3"; os.makedirs(TMP, exist_ok=True)

BIRDY_V = "bIHbv24MWmeRgasZH58o"
BISHOP_V = "pqHfZKP75CvOlQylNhV4"

# Cold open, per line: (voice, text, is_radio). Birdy is IN the cockpit (direct);
# Bishop comes through the headset (radio).
S1 = [
    (BISHOP_V, "How you doing up there.", True),
    (BIRDY_V,  "Doing okay. It's real pretty up here.", False),
    (BISHOP_V, "You're gonna want to start bringing her down soon. While you've still got the light.", True),
    (BIRDY_V,  "Yeah. Couple more minutes.", False),
    (BIRDY_V,  "You seeing this? The mountain.", False),
    (BISHOP_V, "I'm on the ground, partner. I'll take your word for it.", True),
    (BIRDY_V,  "Man. I didn't think it'd look like this.", False),
    (BISHOP_V, "You still with me?", True),
    (BIRDY_V,  "Still here.", False),
    (BIRDY_V,  "Hey. Thanks for staying up with me. Sorry to keep you so late.", False),
    (BISHOP_V, "That's what I'm here for.", True),
    (BIRDY_V,  "Okay.", False),
]

RADIO = ("highpass=f=300,lowpass=f=3000,acompressor=threshold=-18dB:ratio=6:attack=3:release=50,"
         "volume=3dB")

def silence(secs, out):
    subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-f", "lavfi",
                    "-i", "anullsrc=r=44100:cl=stereo", "-t", f"{secs}", "-c:a", "libmp3lame",
                    "-b:a", "160k", out], check=True)
    return out

def line(voice, text, radio, out):
    raw = out + ".raw.mp3"
    open(raw, "wb").write(bk.elevenlabs_tts(text, voice))
    subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-i", raw,
                    "-af", RADIO if radio else "anull", "-c:a", "libmp3lame", "-b:a", "160k", out],
                   check=True)
    return out

def concat(parts, out):
    lst = out + ".txt"
    with open(lst, "w") as f:
        for p in parts:
            f.write(f"file '{os.path.abspath(p)}'\n")
    subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-f", "concat", "-safe", "0",
                    "-i", lst, "-c:a", "libmp3lame", "-b:a", "160k", out], check=True)
    return out

sil6 = silence(0.6, f"{TMP}/sil6.mp3")
sil7 = silence(0.7, f"{TMP}/sil7.mp3")

# scene 1 — per line, radio on Bishop
s1_parts = []
for i, (v, txt, r) in enumerate(S1):
    s1_parts += [line(v, txt, r, f"{TMP}/s1_{i:02d}.mp3"), sil6]
    print("s1 line", i, "radio" if r else "direct", flush=True)
s1 = concat(s1_parts[:-1], f"{TMP}/scene1_radio.mp3")

# scenes 2-4 — keep the good existing multi-voice takes
man = json.load(open(f"{BASE}/performance/sky-king.manifest.json"))
later = [os.path.join(ROOT, m["path"]) for m in man if m["scene"] in ("s2", "s3", "s4")]

full = [s1]
for p in later:
    full += [sil7, p]
dialog = concat(full, f"{TMP}/dialog_v3.mp3")

# pad (music opens on the sky / closes out) then duck the M83 music under
padded = f"{TMP}/dialog_padded_v3.mp3"
subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-i", dialog,
                "-af", "adelay=6000:all=1,apad=pad_dur=14", "-c:a", "libmp3lame", "-b:a", "160k", padded],
               check=True)
SCORED = f"{BASE}/scored_v3.mp3"
score.mix_under(padded, f"{BASE}/music_m83.mp3", SCORED, gain=0.30)
print("SCORED v3 ->", SCORED, flush=True)
subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
                "-of", "default=nw=1:nk=1", SCORED])
