"""AMAL Ep1 v2.1 ENGLISH — table-read audio from EP1_PAGES_v2_EN.md. Narrator (N) reads the English
action; the cast performs the English dialogue. Same ElevenLabs voices as the Hindi cut (multilingual).
Per-segment render for exact subtitle/assemble timing. -> ep1_v2en_hindi... no: ep1_v2en.mp3 + ep1_v2en_timing.json.
`--dry` parses only."""
import os, sys, re, json, hashlib, subprocess
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import backends as bk

D = "/Users/dusty/dev/brehon-law/stories/amal"
A = f"{D}/ep1_v2en_audio"; os.makedirs(A, exist_ok=True)
FB = "XYJilqzgZnnmkbEWyhtr"

VID = {
 "N": "ocf4J1Vk0yOOFNBy3kNq",
 "RATAN": "XSBqeYvLRWlUwJ57A64w", "DEVA": "5ycO0zpSCEkvR4Ri6gk9", "MISHRA": "HtKVOQM66dc5A1XMu8Np",
 "BHERULAL": "sZk20flPPGUa0sDxsZ8t", "KANTA": "OIIrFPBzLAigdcttMGWZ", "AMMA": "bBX9H7So8de80VyvKd7E",
 "SUGNA": "FFmp1h1BMl0iVHA0JxrI", "MANJU": "PId0lEbL3SOYkQZSraml",
 "GOVIND": "THK4VmOwUWou6Ja9qSM4", "BHANWAR": "XYJilqzgZnnmkbEWyhtr", "CHARAN": "M1baVR22tUikfDMapkh7",
 "MUNSHI": "M1baVR22tUikfDMapkh7", "PUJARI": "M1baVR22tUikfDMapkh7",
 "SIPAHI": "8re6K5bW5keUyIP58qVH", "KISAN": "8re6K5bW5keUyIP58qVH", "CHARVAHA": "8re6K5bW5keUyIP58qVH",
 "HAND": "8re6K5bW5keUyIP58qVH", "MAN": "THK4VmOwUWou6Ja9qSM4", "OLD MAN": "THK4VmOwUWou6Ja9qSM4",
 "AUNT": "imPEyYD5nNQE9HiF3K8M",
}
CUES = set(VID) - {"N"}
clean = lambda t: re.sub(r"\s*\*?\([^)]*\)\*?\s*", " ", t).strip()


def cue_of(line):
    if ":" not in line:
        return None
    c = re.sub(r"\s*\([^)]*\)", "", line.split(":", 1)[0]).strip()
    return c if c in CUES else None


segs, action, scene, started = [], [], 0, False
def flush():
    global action
    if action:
        segs.append({"scene": scene, "spk": "N", "txt": " ".join(action)}); action = []

for raw in open(f"{D}/EP1_PAGES_v2_EN.md", encoding="utf-8").read().splitlines():
    ln = raw.strip()
    m = re.match(r"^## SCENE (\d+)", ln)
    if m:
        flush(); scene = int(m.group(1)); started = True; continue
    if not started or not ln or ln.startswith(("#", "**", "*", "---", "|", ">")):
        flush(); continue
    c = cue_of(ln)
    if c:
        flush()
        txt = clean(ln.split(":", 1)[1])
        if txt:
            segs.append({"scene": scene, "spk": c, "txt": txt})
    else:
        action.append(ln)
flush()

nN = sum(1 for s in segs if s["spk"] == "N")
print(f"{len(segs)} segments ({nN} narration, {len(segs)-nN} dialogue) across {max(s['scene'] for s in segs)} scenes", flush=True)
spk = sorted({s["spk"] for s in segs if s["spk"] != "N"})
print("speakers:", " ".join(spk), flush=True)
print("UNMAPPED:", [s for s in spk if s not in VID] or "none", flush=True)
if "--dry" in sys.argv:
    for s in segs[:14]:
        print(f"  sc{s['scene']:>2} {s['spk']}: {s['txt'][:56]}")
    sys.exit(0)

ff = lambda a: subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y"] + a, check=True)
cache = lambda k: f"{A}/s_{hashlib.sha1(k.encode()).hexdigest()[:16]}.mp3"
GAP = 0.30

for n, s in enumerate(segs):
    p = cache(f"{s['spk']}|{s['txt']}")
    if not os.path.exists(p):
        open(p, "wb").write(bk.elevenlabs_tts(s["txt"], VID.get(s["spk"], FB)))
    s["mp3"] = p; s["dur"] = bk.duration(p)
    if (n + 1) % 20 == 0:
        print(f"  rendered {n+1}/{len(segs)}", flush=True)

gap = bk.silence(int(GAP * 1000), A)
norm, t = [], 0.0
for k, s in enumerate(segs):
    if k:
        norm.append(gap); t += GAP
    nf = f"{A}/_n{k:04d}.mp3"
    ff(["-i", s["mp3"], "-ar", "44100", "-ac", "1", "-c:a", "libmp3lame", "-b:a", "160k", nf])
    norm.append(nf); s["start"] = round(t, 3); t += s["dur"]
open(f"{A}/_l.txt", "w").write("".join(f"file '{os.path.abspath(q)}'\n" for q in norm))
ff(["-f", "concat", "-safe", "0", "-i", f"{A}/_l.txt", "-c", "copy", f"{A}/voices.mp3"])
VD = bk.duration(f"{A}/voices.mp3")
print(f"voices: {VD/60:.1f} min", flush=True)

ff(["-f", "lavfi", "-i", f"anoisesrc=color=brown:amplitude=0.16:duration={VD}", "-f", "lavfi",
    "-i", f"sine=frequency=62:duration={VD}", "-filter_complex",
    "[0:a]lowpass=f=200[r];[1:a]tremolo=f=0.3:d=0.5,volume=0.4[c];[r][c]amix=inputs=2:normalize=0,volume=0.5[b]",
    "-map", "[b]", "-t", f"{VD}", "-c:a", "libmp3lame", f"{A}/bed.mp3"])
ff(["-i", f"{A}/voices.mp3", "-i", f"{A}/bed.mp3", "-filter_complex",
    "[0:a]volume=1.2[v];[1:a]volume=0.10[b];[v][b]amix=inputs=2:duration=first:normalize=0,volume=0.96[o]",
    "-map", "[o]", "-c:a", "libmp3lame", "-b:a", "192k", f"{D}/ep1_v2en.mp3"])
json.dump({"gap": GAP, "voices_dur": VD,
           "segments": [{"i": i, "scene": s["scene"], "spk": s["spk"], "txt": s["txt"],
                         "start": s["start"], "dur": round(s["dur"], 3)} for i, s in enumerate(segs)]},
          open(f"{D}/ep1_v2en_timing.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(f"DONE -> ep1_v2en.mp3 ({bk.duration(f'{D}/ep1_v2en.mp3')/60:.1f} min) + ep1_v2en_timing.json", flush=True)
