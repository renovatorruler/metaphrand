"""अमल Ep1 — full multi-voice audio. Brian narrates the English action; the Indian cast performs the
Hindi dialogue (dialogue-takes); stitched, with a light bed. Digest-cached so re-runs only synth new."""
import os, sys, re, hashlib, subprocess
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import backends as bk

D = "/Users/dusty/dev/brehon-law/stories/amal"
A = f"{D}/ep1_audio"; os.makedirs(A, exist_ok=True)
FB = "XYJilqzgZnnmkbEWyhtr"   # fallback male

VID = {
 "N": "nPczCjzI2devNBz1zQrb",            # Brian, US narrator (English action)
 "RATAN": "XSBqeYvLRWlUwJ57A64w", "DEVA": "5ycO0zpSCEkvR4Ri6gk9", "MISHRA": "HtKVOQM66dc5A1XMu8Np",
 "BHERULAL": "sZk20flPPGUa0sDxsZ8t", "KHARE": "M1baVR22tUikfDMapkh7", "VERMA": "8re6K5bW5keUyIP58qVH",
 "THE MAN": "THK4VmOwUWou6Ja9qSM4", "DAULATRAM": "ocf4J1Vk0yOOFNBy3kNq", "BAPU": "XYJilqzgZnnmkbEWyhtr",
 "WATCHMAN": "8re6K5bW5keUyIP58qVH", "HUKMA": "8re6K5bW5keUyIP58qVH", "FARMER": "5ycO0zpSCEkvR4Ri6gk9",
 "MAN ONE": "XYJilqzgZnnmkbEWyhtr", "MAN TWO": "8re6K5bW5keUyIP58qVH", "MAN THREE": "sZk20flPPGUa0sDxsZ8t",
 "SUGNA": "FFmp1h1BMl0iVHA0JxrI", "AMMA": "bBX9H7So8de80VyvKd7E", "SUNITA": "PId0lEbL3SOYkQZSraml",
 "RESHMA": "subIZc6skATBQ1Rbqpi7", "AUNT": "imPEyYD5nNQE9HiF3K8M", "NANHI": "nfMYisZqs1GOjTFllho3",
 "KANTA": "OIIrFPBzLAigdcttMGWZ",
}
SPK = re.compile(r"^([A-Z][A-Z][A-Z ]*):\s*(.*)$")


def ff(args):
    subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y"] + args, check=True)


def clean(t):
    return re.sub(r"\s*\([^)]*\)\s*", " ", t).strip()   # drop stage-direction parentheticals


# --- parse EP1.md into ordered (speaker, text) segments (skip the preamble before scene 1) ---
segs, action, started = [], [], False
for raw in open(f"{D}/EP1.md", encoding="utf-8").read().splitlines():
    ln = raw.strip()
    if ln.startswith("## "):
        started = True
    if not started:
        continue
    if not ln or ln.startswith(("#", "**", "---", "*", "|", "> ")):
        if action:
            segs.append(("N", " ".join(action))); action = []
        continue
    m = SPK.match(ln)
    if m:
        if action:
            segs.append(("N", " ".join(action))); action = []
        spk, txt = m.group(1).strip(), clean(m.group(2))
        if txt:
            segs.append((spk, txt))
    else:
        action.append(ln)
if action:
    segs.append(("N", " ".join(action)))
print(f"{len(segs)} segments ({sum(1 for s in segs if s[0]=='N')} narration, "
      f"{sum(1 for s in segs if s[0]!='N')} dialogue)", flush=True)


def cached(key):
    p = f"{A}/seg_{hashlib.sha1(key.encode()).hexdigest()[:16]}.mp3"
    return p, os.path.exists(p)


# --- render: group consecutive dialogue into multi-speaker takes; N via single-voice TTS ---
parts, i = [], 0
while i < len(segs):
    spk, txt = segs[i]
    if spk == "N":
        p, hit = cached("N|" + txt)
        if not hit:
            open(p, "wb").write(bk.elevenlabs_tts(txt, VID["N"]))
        parts.append(p); i += 1
    else:
        run = []
        while i < len(segs) and segs[i][0] != "N":
            run.append(segs[i]); i += 1
        key = "D|" + "|".join(f"{s}:{t}" for s, t in run)
        p, hit = cached(key)
        if not hit:
            inputs = [{"text": t, "voice_id": VID.get(s, FB)} for s, t in run]
            open(p, "wb").write(bk.elevenlabs_dialogue(inputs))
        parts.append(p)
    if len(parts) % 10 == 0:
        print(f"  rendered {len(parts)} segments", flush=True)

# --- normalize + concat (uniform params so the demuxer doesn't choke) + a light bed ---
gap = bk.silence(280, A)
seq = []
for j, p in enumerate(parts):
    if j:
        seq.append(gap)
    seq.append(p)
norm = []
for k, p in enumerate(seq):
    nf = f"{A}/_n{k:04d}.mp3"
    ff(["-i", p, "-ar", "44100", "-ac", "1", "-c:a", "libmp3lame", "-b:a", "160k", nf]); norm.append(nf)
lst = f"{A}/_list.txt"
open(lst, "w").write("".join(f"file '{os.path.abspath(q)}'\n" for q in norm))
ff(["-f", "concat", "-safe", "0", "-i", lst, "-c", "copy", f"{A}/voices.mp3"])
VD = bk.duration(f"{A}/voices.mp3")
print(f"voices: {VD/60:.1f} min", flush=True)

ff(["-f", "lavfi", "-i", f"anoisesrc=color=brown:amplitude=0.16:duration={VD}",
    "-f", "lavfi", "-i", f"sine=frequency=62:duration={VD}",
    "-filter_complex", "[0:a]lowpass=f=200[r];[1:a]tremolo=f=0.3:d=0.5,volume=0.4[c];"
    "[r][c]amix=inputs=2:normalize=0,volume=0.5[bed]",
    "-map", "[bed]", "-t", f"{VD}", "-c:a", "libmp3lame", f"{A}/bed.mp3"])
ff(["-i", f"{A}/voices.mp3", "-i", f"{A}/bed.mp3", "-filter_complex",
    "[0:a]volume=1.2[v];[1:a]volume=0.10[b];[v][b]amix=inputs=2:duration=first:normalize=0,volume=0.96[o]",
    "-map", "[o]", "-c:a", "libmp3lame", "-b:a", "192k", f"{D}/ep1_audio.mp3"])
print(f"DONE -> ep1_audio.mp3 ({bk.duration(f'{D}/ep1_audio.mp3')/60:.1f} min)", flush=True)
