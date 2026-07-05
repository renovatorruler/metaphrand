"""AMAL Ep1 — full table-read audio from the HINDI screenplay (EP1_PAGES_HI.md).
सूत्रधार (N) reads the action; the cast performs the dialogue; scene headings & sluglines are NOT
read (they go on-screen). Ambient bed under it. Digest-cached. `--dry` parses only (no API)."""
import os, sys, re, hashlib, subprocess
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import backends as bk

D = "/Users/dusty/dev/brehon-law/stories/amal"
A = f"{D}/ep1_hi_audio"; os.makedirs(A, exist_ok=True)
FB = "XYJilqzgZnnmkbEWyhtr"

VID = {
 "N": "ocf4J1Vk0yOOFNBy3kNq",
 "रतन": "XSBqeYvLRWlUwJ57A64w", "देवा": "5ycO0zpSCEkvR4Ri6gk9", "मिश्रा": "HtKVOQM66dc5A1XMu8Np",
 "भेरूलाल": "sZk20flPPGUa0sDxsZ8t", "कांता": "OIIrFPBzLAigdcttMGWZ", "अम्मा": "bBX9H7So8de80VyvKd7E",
 "बापू": "XYJilqzgZnnmkbEWyhtr", "सुगना": "FFmp1h1BMl0iVHA0JxrI", "बुआ": "imPEyYD5nNQE9HiF3K8M",
 "मंजू": "PId0lEbL3SOYkQZSraml", "लीला": "nfMYisZqs1GOjTFllho3", "लड़के की माँ": "subIZc6skATBQ1Rbqpi7",
 "मुंशी": "M1baVR22tUikfDMapkh7", "फ़िक्सर": "THK4VmOwUWou6Ja9qSM4", "छोरा": "8re6K5bW5keUyIP58qVH",
 "सेठ": "M1baVR22tUikfDMapkh7", "मैनेजर": "THK4VmOwUWou6Ja9qSM4", "भाट": "HtKVOQM66dc5A1XMu8Np",
 "साथी": "8re6K5bW5keUyIP58qVH", "धनराज": "THK4VmOwUWou6Ja9qSM4", "गुंडा": "M1baVR22tUikfDMapkh7",
 "सिपाही": "8re6K5bW5keUyIP58qVH", "पुजारी": "M1baVR22tUikfDMapkh7",
}
CUES = set(VID) - {"N"}
clean = lambda t: re.sub(r"\s*\([^)]*\)\s*", " ", t).strip()

segs, action, started = [], [], False
def flush():
    global action
    if action:
        segs.append(("N", " ".join(action))); action = []

for raw in open(f"{D}/EP1_PAGES_HI.md", encoding="utf-8").read().splitlines():
    ln = raw.strip()
    if ln.startswith("## दृश्य"):          # first scene header begins the read; skip the preamble
        started = True; flush(); continue
    if not started:
        continue
    if not ln or ln.startswith(("#", "**", "*", "---", "|", ">")):
        flush(); continue
    cue = ln.split(":", 1)[0].strip() if ":" in ln else None
    if cue in CUES:
        flush()
        txt = clean(ln.split(":", 1)[1])
        if txt:
            segs.append((cue, txt))
    else:
        action.append(ln)
flush()

nN = sum(1 for s in segs if s[0] == "N")
print(f"{len(segs)} segments  ({nN} narration, {len(segs)-nN} dialogue)", flush=True)
speakers = sorted({s for s, _ in segs if s != "N"})
print("dialogue speakers:", " ".join(speakers), flush=True)
unmapped = [s for s in speakers if s not in VID]
if unmapped:
    print("!! UNMAPPED (will fall back):", unmapped, flush=True)
if "--dry" in sys.argv:
    print("\n--- first 12 segments ---")
    for s, t in segs[:12]:
        print(f"  {s}: {t[:60]}")
    sys.exit(0)

ff = lambda a: subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y"] + a, check=True)
cache = lambda k: f"{A}/s_{hashlib.sha1(k.encode()).hexdigest()[:16]}.mp3"

parts, i = [], 0
while i < len(segs):
    spk, txt = segs[i]
    if spk == "N":
        p = cache("N|" + txt)
        if not os.path.exists(p):
            open(p, "wb").write(bk.elevenlabs_tts(txt, VID["N"]))
        parts.append(p); i += 1
    else:
        run = []
        while i < len(segs) and segs[i][0] != "N":
            run.append(segs[i]); i += 1
        p = cache("D|" + "|".join(f"{s}:{t}" for s, t in run))
        if not os.path.exists(p):
            open(p, "wb").write(bk.elevenlabs_dialogue([{"text": t, "voice_id": VID.get(s, FB)} for s, t in run]))
        parts.append(p)
    if len(parts) % 12 == 0:
        print(f"  rendered {len(parts)} blocks", flush=True)

gap = bk.silence(300, A)
seq = [x for j, p in enumerate(parts) for x in ((gap, p) if j else (p,))]
norm = []
for k, p in enumerate(seq):
    nf = f"{A}/_n{k:04d}.mp3"; ff(["-i", p, "-ar", "44100", "-ac", "1", "-c:a", "libmp3lame", "-b:a", "160k", nf]); norm.append(nf)
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
    "-map", "[o]", "-c:a", "libmp3lame", "-b:a", "192k", f"{D}/ep1_hindi_tableread.mp3"])
print(f"DONE -> ep1_hindi_tableread.mp3 ({bk.duration(f'{D}/ep1_hindi_tableread.mp3')/60:.1f} min)", flush=True)
