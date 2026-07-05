"""AMAL Ep1 v2 — table-read audio from EP2_PAGES_HI.md. सूत्रधार (N) reads the Hindi action; the
cast performs the Hindi dialogue. Rendered PER SEGMENT (one TTS call each) so we get exact per-segment
timing for the English subtitle track. Ambient bed under it. Digest-cached. Writes ep2_timing.json.
`--dry` parses only (no API)."""
import os, sys, re, json, hashlib, subprocess
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import backends as bk

D = "/Users/dusty/dev/brehon-law/stories/amal"
A = f"{D}/ep2_audio"; os.makedirs(A, exist_ok=True)
FB = "XYJilqzgZnnmkbEWyhtr"
DEV = str.maketrans("०१२३४५६७८९", "0123456789")

VID = {
 "N": "ocf4J1Vk0yOOFNBy3kNq",
 "रतन": "XSBqeYvLRWlUwJ57A64w", "देवा": "5ycO0zpSCEkvR4Ri6gk9", "मिश्रा": "HtKVOQM66dc5A1XMu8Np",
 "भेरूलाल": "sZk20flPPGUa0sDxsZ8t", "कांता": "OIIrFPBzLAigdcttMGWZ", "अम्मा": "bBX9H7So8de80VyvKd7E",
 "सुगना": "FFmp1h1BMl0iVHA0JxrI", "मंजू": "PId0lEbL3SOYkQZSraml",
 "गोविंद": "THK4VmOwUWou6Ja9qSM4", "भँवर": "XYJilqzgZnnmkbEWyhtr", "चारण": "M1baVR22tUikfDMapkh7",
 "मुंशी": "M1baVR22tUikfDMapkh7", "पुजारी": "M1baVR22tUikfDMapkh7", "साहूकार": "THK4VmOwUWou6Ja9qSM4",
 "सिपाही": "8re6K5bW5keUyIP58qVH", "किसान": "8re6K5bW5keUyIP58qVH", "चरवाहा": "8re6K5bW5keUyIP58qVH",
 "मज़दूर": "8re6K5bW5keUyIP58qVH", "आदमी": "THK4VmOwUWou6Ja9qSM4",
 "औरत": "imPEyYD5nNQE9HiF3K8M", "चाची": "subIZc6skATBQ1Rbqpi7",
 "कंपाउंडर": "THK4VmOwUWou6Ja9qSM4", "किशन": "8re6K5bW5keUyIP58qVH", "टेम्पोवाला": "5ycO0zpSCEkvR4Ri6gk9",
 "क्लर्क": "HtKVOQM66dc5A1XMu8Np", "बूढ़ी औरत": "subIZc6skATBQ1Rbqpi7", "खरे": "M1baVR22tUikfDMapkh7",
 "गंगा": "XYJilqzgZnnmkbEWyhtr", "पीए": "THK4VmOwUWou6Ja9qSM4", "ड्राइवर": "8re6K5bW5keUyIP58qVH",
 "राणा": "JBFqnCBsd6RMkjVDRZzb", "धनराज": "M1baVR22tUikfDMapkh7", "अहलकार": "THK4VmOwUWou6Ja9qSM4",
}
CUES = set(VID) - {"N"}
clean = lambda t: re.sub(r"\s*\*?\([^)]*\)\*?\s*", " ", t).strip()   # strip *(parentheticals)*

# ---- parse: one segment per action-paragraph (N) and per dialogue line ----
segs, action, scene, started = [], [], 0, False
def flush():
    global action
    if action:
        segs.append({"scene": scene, "spk": "N", "hi": " ".join(action)}); action = []

for raw in open(f"{D}/EP2_PAGES_HI.md", encoding="utf-8").read().splitlines():
    ln = raw.strip()
    m = re.match(r"^## दृश्य ([०-९]+)", ln)
    if m:
        flush(); scene = int(m.group(1).translate(DEV)); started = True; continue
    mb = re.match(r"^〔ठहराव\s+([\d.]+)〕$", ln)
    if mb:
        flush(); segs.append({"scene": scene, "spk": "PAUSE", "hi": "", "dur": float(mb.group(1))}); continue
    if not started or not ln or ln.startswith(("#", "**", "*", "---", "|", ">")):
        flush(); continue
    cue = ln.split(":", 1)[0].strip() if ":" in ln else None
    if cue in CUES:
        flush()
        txt = clean(ln.split(":", 1)[1])
        if txt:
            segs.append({"scene": scene, "spk": cue, "hi": txt})
    else:
        action.append(ln)
flush()

nN = sum(1 for s in segs if s["spk"] == "N")
print(f"{len(segs)} segments ({nN} narration, {len(segs)-nN} dialogue) across {max(s['scene'] for s in segs)} scenes", flush=True)
spk = sorted({s["spk"] for s in segs if s["spk"] != "N"})
print("speakers:", " ".join(spk), flush=True)
unmapped = [s for s in spk if s not in VID]
print("UNMAPPED (fallback):", unmapped or "none", flush=True)
if "--dry" in sys.argv:
    for s in segs[:14]:
        print(f"  sc{s['scene']:>2} {s['spk']}: {s['hi'][:58]}")
    sys.exit(0)

ff = lambda a: subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y"] + a, check=True)
cache = lambda k: f"{A}/s_{hashlib.sha1(k.encode()).hexdigest()[:16]}.mp3"
GAP = 0.30

for n, s in enumerate(segs):
    if s["spk"] == "PAUSE":
        s["mp3"] = bk.silence(int(round(s["dur"] * 1000)), A); s["dur"] = bk.duration(s["mp3"]); continue
    p = cache(f"{VID.get(s['spk'], FB)}|{s['spk']}|{s['hi']}")
    if not os.path.exists(p):
        open(p, "wb").write(bk.elevenlabs_tts(s["hi"], VID.get(s["spk"], FB)))
    s["mp3"] = p; s["dur"] = bk.duration(p)
    if (n + 1) % 20 == 0:
        print(f"  rendered {n+1}/{len(segs)}", flush=True)

# stitch with gaps, capture each segment's start in the final voice track
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

# ambient bed (brown noise + 62Hz sine), mixed low
ff(["-f", "lavfi", "-i", f"anoisesrc=color=brown:amplitude=0.16:duration={VD}", "-f", "lavfi",
    "-i", f"sine=frequency=62:duration={VD}", "-filter_complex",
    "[0:a]lowpass=f=200[r];[1:a]tremolo=f=0.3:d=0.5,volume=0.4[c];[r][c]amix=inputs=2:normalize=0,volume=0.5[b]",
    "-map", "[b]", "-t", f"{VD}", "-c:a", "libmp3lame", f"{A}/bed.mp3"])
ff(["-i", f"{A}/voices.mp3", "-i", f"{A}/bed.mp3", "-filter_complex",
    "[0:a]volume=1.2[v];[1:a]volume=0.10[b];[v][b]amix=inputs=2:duration=first:normalize=0,volume=0.96[o]",
    "-map", "[o]", "-c:a", "libmp3lame", "-b:a", "192k", f"{D}/ep2_hindi.mp3"])

json.dump({"gap": GAP, "voices_dur": VD,
           "segments": [{"i": i, "scene": s["scene"], "spk": s["spk"], "hi": s["hi"],
                         "start": s["start"], "dur": round(s["dur"], 3)} for i, s in enumerate(segs)]},
          open(f"{D}/ep2_timing.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(f"DONE -> ep2_hindi.mp3 ({bk.duration(f'{D}/ep2_hindi.mp3')/60:.1f} min) + ep2_timing.json", flush=True)
