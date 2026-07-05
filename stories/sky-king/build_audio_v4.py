import os, sys, json, subprocess
ROOT = "/Users/dusty/dev/brehon-law"
BASE = f"{ROOT}/stories/sky-king"
A = f"{BASE}/audio_v3"
TMP = f"{BASE}/audio_v4"; os.makedirs(TMP, exist_ok=True)

def dur(p):
    return float(subprocess.check_output(["ffprobe", "-v", "error", "-show_entries",
        "format=duration", "-of", "default=nw=1:nk=1", p]).strip())

def concat(parts, out):
    lst = out + ".txt"
    open(lst, "w").write("\n".join(f"file '{os.path.abspath(p)}'" for p in parts))
    subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-f", "concat", "-safe", "0",
                    "-i", lst, "-c:a", "libmp3lame", "-b:a", "160k", out], check=True)
    return out

# scene 1: Bishop NEW radio + Birdy direct
order = [("00", 1), ("01", 0), ("02", 1), ("03", 0), ("04", 0), ("05", 1),
         ("06", 0), ("07", 1), ("08", 0), ("09", 0), ("10", 1), ("11", 0)]
sil6, sil7 = f"{A}/sil6.mp3", f"{A}/sil7.mp3"
s1_parts = []
for idx, radio in order:
    s1_parts += [f"{A}/s1_{idx}.radio.mp3" if radio else f"{A}/s1_{idx}.mp3", sil6]
s1 = concat(s1_parts[:-1], f"{TMP}/scene1_v4.mp3")

man = json.load(open(f"{BASE}/performance/sky-king.manifest.json"))
later = [os.path.join(ROOT, m["path"]) for m in man if m["scene"] in ("s2", "s3", "s4")]
full = [s1]
for p in later:
    full += [sil7, p]
dialog = concat(full, f"{TMP}/dialog_v4.mp3")

ddur = dur(dialog)
padded = f"{TMP}/padded_v4.mp3"
subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-i", dialog,
                "-af", "adelay=13000:all=1,apad=pad_dur=10", "-c:a", "libmp3lame", "-b:a", "160k", padded],
               check=True)
T = 13 + ddur + 10
OS = T - 11
# Music dynamic: full ~0.60 for 13s, simmer to 0.18 over 2s, swell back to ~0.45 in the last 11s.
vol = (f"if(lt(t,13),0.85,if(lt(t,15),0.85-(t-13)*0.335,"
       f"if(lt(t,{OS:.2f}),0.18,0.18+(t-{OS:.2f})*0.024)))")
SCORED = f"{BASE}/scored_v4.mp3"
subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-i", padded, "-i", f"{BASE}/music_m83.mp3",
    "-filter_complex",
    f"[1:a]aresample=44100,volume='{vol}':eval=frame[m];[0:a][m]amix=inputs=2:duration=first:normalize=0[mix]",
    "-map", "[mix]", "-c:a", "libmp3lame", "-b:a", "160k", SCORED], check=True)
print("scored_v4 ->", SCORED, "  total", round(T, 1), "s", flush=True)
