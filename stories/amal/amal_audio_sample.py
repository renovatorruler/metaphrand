"""AMAL — voice-cast sample: render ONE scene (Sc9, the teacher) as a multi-voice Hindi dialogue take,
so we can hear Ratan + Deva before committing the full 37-scene render. Reuses the prior voice cast."""
import os, sys, re
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import backends as bk

D = "/Users/dusty/dev/brehon-law/stories/amal"
VID = {"RATAN": "XSBqeYvLRWlUwJ57A64w", "DEVA": "5ycO0zpSCEkvR4Ri6gk9"}
SPK = re.compile(r"^([A-Z][A-Z][A-Z '’&]*):\s*(.*)$")
clean = lambda t: re.sub(r"\s*\([^)]*\)\s*", " ", t).strip()

# pull Sc9's dialogue lines
full = open(f"{D}/EP1_PAGES.md", encoding="utf-8").read()
sc9 = full[full.index("## SCENE 9 "):full.index("## SCENE 10 ")]
lines = []
for raw in sc9.splitlines():
    m = SPK.match(raw.strip())
    if m and m.group(1).strip() in VID:
        txt = clean(m.group(2))
        if txt:
            lines.append((m.group(1).strip(), txt))

print(f"Sc9: {len(lines)} dialogue lines", flush=True)
for s, t in lines:
    print(f"  {s}: {t[:50]}", flush=True)

inputs = [{"text": t, "voice_id": VID[s]} for s, t in lines]
out = f"{D}/amal_sample_sc9.mp3"
open(out, "wb").write(bk.elevenlabs_dialogue(inputs))
print(f"DONE -> {out} ({bk.duration(out):.0f}s)", flush=True)
