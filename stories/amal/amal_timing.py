"""Derive the per-scene timing manifest from the cached table-read audio segments (no re-synth),
matching amal_audio_hi.py's block grouping + 300ms gaps. -> ep1_timing.json for the assembler."""
import os, sys, re, hashlib, json
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import backends as bk

D = "/Users/dusty/dev/brehon-law/stories/amal"; A = f"{D}/ep1_hi_audio"
DEV = str.maketrans("०१२३४५६७८९", "0123456789")
VID = {"N": 1, "रतन": 1, "देवा": 1, "मिश्रा": 1, "भेरूलाल": 1, "कांता": 1, "अम्मा": 1, "बापू": 1,
       "सुगना": 1, "बुआ": 1, "मंजू": 1, "लीला": 1, "लड़के की माँ": 1, "मुंशी": 1, "फ़िक्सर": 1,
       "छोरा": 1, "सेठ": 1, "मैनेजर": 1, "भाट": 1, "साथी": 1, "धनराज": 1, "गुंडा": 1, "सिपाही": 1,
       "पुजारी": 1}
CUES = set(VID) - {"N"}
clean = lambda t: re.sub(r"\s*\([^)]*\)\s*", " ", t).strip()
cache = lambda k: f"{A}/s_{hashlib.sha1(k.encode()).hexdigest()[:16]}.mp3"

segs, action, started, scene = [], [], False, 0
def flush():
    global action
    if action:
        segs.append(("N", " ".join(action), scene)); action = []

for raw in open(f"{D}/EP1_PAGES_HI.md", encoding="utf-8").read().splitlines():
    ln = raw.strip()
    m = re.match(r"## दृश्य ([०-९]+)", ln)
    if m:
        started = True; flush(); scene = int(m.group(1).translate(DEV)); continue
    if not started:
        continue
    if not ln or ln.startswith(("#", "**", "*", "---", "|", ">")):
        flush(); continue
    cue = ln.split(":", 1)[0].strip() if ":" in ln else None
    if cue in CUES:
        flush(); txt = clean(ln.split(":", 1)[1])
        if txt:
            segs.append((cue, txt, scene))
    else:
        action.append(ln)
flush()

blocks, i = [], 0
while i < len(segs):
    spk, txt, sc = segs[i]
    if spk == "N":
        blocks.append((sc, cache("N|" + txt))); i += 1
    else:
        run, bsc = [], sc
        while i < len(segs) and segs[i][0] != "N":
            run.append((segs[i][0], segs[i][1])); i += 1
        blocks.append((bsc, cache("D|" + "|".join(f"{s}:{t}" for s, t in run))))

GAP, t, starts = 0.3, 0.0, {}
for j, (sc, p) in enumerate(blocks):
    if j:
        t += GAP
    if sc not in starts:
        starts[sc] = t
    t += bk.duration(p) if os.path.exists(p) else 0.0
total = t
scs = sorted(starts)
manifest = []
for k, sc in enumerate(scs):
    st = starts[sc]
    en = starts[scs[k + 1]] if k + 1 < len(scs) else total
    manifest.append({"scene": sc, "start": round(st, 2), "dur": round(en - st, 2)})
json.dump({"total": round(total, 2), "scenes": manifest}, open(f"{D}/ep1_timing.json", "w"), indent=1)
print(f"total {total/60:.1f} min, {len(manifest)} scenes with audio", flush=True)
for m in manifest:
    print(f"  sc{m['scene']:02d}: start {m['start']:6.1f}s  dur {m['dur']:5.1f}s", flush=True)
