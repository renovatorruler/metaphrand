"""AMAL Ep2 — burned-in English subtitles (.ass) for the assembled video.
Reads the per-segment English from ep2_en_subs.json (the translation agent's output) + timing from
ep2_timing.json. Builds TWO tracks, each in its own clip's local time:
  ep2_scene1.ass  — the cold open (scene 1), local time = absolute (clip1 starts at 0)
  ep2_main.ass    — scenes 3..39, local time = absolute - scene3_start (clip3)
Scene 2 (the title slot) is skipped. -> stories/amal/ep2_scene1.ass, ep2_main.ass"""
import json
D = "/Users/dusty/dev/brehon-law/stories/amal"
EN = json.load(open(f"{D}/ep2_en_subs.json", encoding="utf-8"))
man = json.load(open(f"{D}/ep2_timing.json", encoding="utf-8"))
segs = man["segments"]
S3 = min(s["start"] for s in segs if s["scene"] == 3)

HEAD = """[Script Info]
ScriptType: v4.00+
PlayResX: 1920
PlayResY: 1080
WrapStyle: 0
ScaledBorderAndShadow: yes

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,DejaVu Sans,44,&H00FFFFFF,&H000000FF,&H00101010,&H80000000,0,0,0,0,100,100,0,0,1,2.4,1.2,2,80,80,56,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""

def at(t):                       # ASS time  H:MM:SS.cc
    t = max(0.0, t); h = int(t // 3600); m = int(t % 3600 // 60); s = t % 60
    return f"{h:d}:{m:02d}:{s:05.2f}"

def chunks(text, n=11):
    w = text.split()
    return [" ".join(w[i:i + n]) for i in range(0, len(w), n)] or [text]

def esc(s):                      # ASS: protect braces/newlines
    return s.replace("{", "(").replace("}", ")").replace("\n", " ").strip()

def build(keep, t0, path):
    rows = []
    for s in segs:
        if not keep(s):
            continue
        en = esc(EN.get(str(s["i"]), ""))
        if not en:
            continue
        parts = chunks(en)
        start = s["start"] - t0
        per = s["dur"] / len(parts)
        for j, p in enumerate(parts):
            a = start + j * per; b = a + per - 0.06
            rows.append(f"Dialogue: 0,{at(a)},{at(b)},Default,,0,0,0,,{p}")
    open(path, "w", encoding="utf-8").write(HEAD + "\n".join(rows) + "\n")
    return len(rows)

n1 = build(lambda s: s["scene"] == 1, 0.0, f"{D}/ep2_scene1.ass")
n3 = build(lambda s: s["scene"] >= 3, S3, f"{D}/ep2_main.ass")
print(f"subs: scene1={n1} events | main(sc3-39)={n3} events  (S3={S3:.2f}s)", flush=True)
