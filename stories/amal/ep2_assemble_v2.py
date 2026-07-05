"""AMAL Ep2 v2 — assemble in the Portra look with shooting-script grammar. Per scene a play-order list of
shots (establishing lead -> main -> closer angles) from ep2_frames_v2.SHOTS; subtitles track the active shot;
pre-composited stills (no libass). Cold-open -> title transition (locked recipe). Audio/score/subs/timing from
the approved cut. -> stories/amal/amal_ep2.mp4"""
import os, sys, json, shutil, subprocess
sys.path.insert(0, "/Users/dusty/dev/brehon-law/stories/amal")
from PIL import Image, ImageDraw, ImageFont
from ep2_frames_v2 import SHOTS
D = "/Users/dusty/dev/brehon-law/stories/amal"
F, W = f"{D}/ep2_frames_v2", f"{D}/_assemble_ep2v2"; CMP = f"{W}/cmp"
shutil.rmtree(CMP, ignore_errors=True); os.makedirs(CMP, exist_ok=True)
AUDIO, TITLE = f"{D}/ep2_scored_master.mp3", f"{D}/amal_title_sequence_v5.mp4"
EN = json.load(open(f"{D}/ep2_en_subs.json", encoding="utf-8"))
ff = lambda a: subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y"] + a, check=True)
def probe(f): return float(subprocess.run(["ffprobe","-v","error","-show_entries","format=duration","-of","default=nw=1:nk=1",f],capture_output=True,text=True).stdout.strip() or 0)

man = json.load(open(f"{D}/ep2_timing.json", encoding="utf-8")); segs = man["segments"]; VD = man["voices_dur"]
scenes = sorted({s["scene"] for s in segs})
first = {sc: min(s["start"] for s in segs if s["scene"] == sc) for sc in scenes}
dur = {sc: (first[scenes[i+1]] if i+1 < len(scenes) else VD) - first[sc] for i, sc in enumerate(scenes)}
byscene = {sc: sorted([s for s in segs if s["scene"] == sc], key=lambda s: s["start"]) for sc in scenes}
S2, S3 = first[2], first[3]

FCAND = ["/System/Library/Fonts/Supplemental/Arial.ttf", "/Library/Fonts/Arial.ttf", "/System/Library/Fonts/Helvetica.ttc"]
FONT = next((ImageFont.truetype(fp, 48) for fp in FCAND if os.path.exists(fp)), ImageFont.load_default())
_pd = ImageDraw.Draw(Image.new("RGB", (10, 10)))
def wrap(text, maxw=1740):
    lines, cur = [], ""
    for w in text.split():
        t = (cur + " " + w).strip()
        if _pd.textlength(t, font=FONT) <= maxw: cur = t
        else: lines.append(cur); cur = w
    if cur: lines.append(cur)
    return lines[:3]
def chunks(text, n=10):
    w = text.split(); return [" ".join(w[i:i+n]) for i in range(0, len(w), n)] or [text]

def SF(name):
    dst = f"{W}/p_{name}.png"
    if not os.path.exists(dst):
        ff(["-i", f"{F}/{name}.png", "-vf", "scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,setsar=1", dst])
    return dst
N = [0]
def composite(name, text):
    im = Image.open(SF(name)).convert("RGB"); d = ImageDraw.Draw(im)
    lines = wrap(text); lh = 60; y0 = 1022 - lh * len(lines)
    for k, ln in enumerate(lines):
        x = (1920 - d.textlength(ln, font=FONT)) / 2; y = y0 + k * lh
        d.text((x, y), ln, font=FONT, fill=(255, 255, 255), stroke_width=3, stroke_fill=(0, 0, 0))
    out = f"{CMP}/c{N[0]:05d}.jpg"; N[0] += 1; im.save(out, quality=90); return out

def shot_windows(shotlist, s0, s1):
    est = [n for n in shotlist if n.endswith("_est")]
    rest = [n for n in shotlist if not n.endswith("_est")] or list(shotlist)
    win = []; cur = s0
    for n in est:
        d = min(2.8, (s1 - s0) * 0.30 / max(len(est), 1)); win.append((n, cur, cur + d)); cur += d
    nr = max(len(rest), 1)
    for i, n in enumerate(rest):
        b = s1 if i == nr - 1 else cur + (s1 - cur) / (nr - i)
        win.append((n, cur, b)); cur = b
    return win

VENC = ["-c:v", "libx264", "-preset", "veryfast", "-crf", "21", "-pix_fmt", "yuv420p", "-r", "25"]
AENC = ["-c:a", "aac", "-b:a", "192k", "-ar", "44100"]

def build_clip(scs, t0, a0, a_dur, out):
    rows = []
    for sc in scs:
        s0 = first[sc] - t0; s1 = s0 + dur[sc]
        windows = shot_windows(SHOTS.get(sc, [f"sc{sc:02d}"]), s0, s1)
        cues = []
        for seg in byscene[sc]:
            en = EN.get(str(seg["i"]), "").strip()
            if not en: continue
            parts = chunks(en); per = seg["dur"] / len(parts)
            for j, p in enumerate(parts):
                a = seg["start"] - t0 + j * per; cues.append((a, a + per - 0.06, p))
        cues.sort()
        for (name, wa, wb) in windows:
            base = SF(name); cur = wa
            for (ca, cb, text) in cues:
                a = max(ca, wa, cur); b = min(cb, wb)
                if b <= a + 0.02: continue
                if a > cur + 0.04: rows.append((base, a - cur))
                rows.append((composite(name, text), max(b - a, 0.3))); cur = b
            if cur < wb - 0.04: rows.append((base, wb - cur))
    lp = f"{W}/list_{out}.txt"
    with open(lp, "w") as fh:
        for img, dd in rows: fh.write(f"file '{os.path.abspath(img)}'\nduration {max(dd, 0.04):.3f}\n")
        fh.write(f"file '{os.path.abspath(rows[-1][0])}'\n")
    ff(["-ss", f"{a0:.3f}", "-t", f"{a_dur:.3f}", "-i", AUDIO, "-ac", "2", "-ar", "44100", "-c:a", "aac", "-b:a", "192k", f"{W}/{out}_a.m4a"])
    ff(["-f", "concat", "-safe", "0", "-i", lp, "-i", f"{W}/{out}_a.m4a"] + VENC + AENC + ["-shortest", f"{W}/{out}.mp4"])
    print(f"  {out}: {len(rows)} pieces, {probe(W+'/'+out+'.mp4')/60:.1f} min", flush=True)

need = set()
for sc in scenes:
    if sc == 2: continue
    for n in SHOTS.get(sc, [f"sc{sc:02d}"]): need.add(n)
missing = [n for n in sorted(need) if not os.path.exists(f"{F}/{n}.png")]
if missing: sys.exit(f"frames missing ({len(missing)}): {missing[:12]}")

print("clip1 (cold open) ...", flush=True)
build_clip([1], 0.0, 0.0, S2, "clip1")
print("clip3 (Sc3-39) ...", flush=True)
build_clip([s for s in scenes if s >= 3], S3, S3, VD - S3, "clip3")

print("cold-open -> title head ...", flush=True)
D1 = probe(f"{W}/clip1.mp4"); MUSIC = f"{D}/audio/amal_title_saka_suno_v1.mp3"; TLEN = 3.5 + 60.0
thd = (f"[0:v]fps=25,setsar=1,scale=1920:1080,format=yuv420p,tpad=stop_mode=clone:stop_duration=3.5,fade=t=out:st={D1:.3f}:d=1.0[vco];"
       f"[1:v]fps=25,setsar=1,scale=1920:1080,format=yuv420p,fade=t=in:st=0:d=1.6[vt];"
       f"[vco][vt]concat=n=2:v=1:a=0[v];"
       f"[0:a]afade=t=out:st={D1-0.3:.3f}:d=0.3[aco];"
       f"[2:a]volume=0.95,afade=t=in:st=0:d=1.8,afade=t=out:st={TLEN-2:.2f}:d=2,adelay={int(D1*1000)}|{int(D1*1000)}[mus];"
       f"[aco][mus]amix=inputs=2:normalize=0:duration=longest,atrim=0:{D1+TLEN:.3f}[a]")
ff(["-i", f"{W}/clip1.mp4", "-i", TITLE, "-ss", "0", "-t", f"{TLEN+1:.2f}", "-i", MUSIC,
    "-filter_complex", thd, "-map", "[v]", "-map", "[a]"] + VENC + AENC + [f"{W}/head.mp4"])
print("concat head + clip3 -> amal_ep2.mp4 ...", flush=True)
norm = lambda i: (f"[{i}:v]fps=25,setsar=1,scale=1920:1080,format=yuv420p[v{i}];"
                  f"[{i}:a]aresample=44100,aformat=sample_fmts=fltp:channel_layouts=stereo[a{i}];")
fc = norm(0)+norm(1)+"[v0][a0][v1][a1]concat=n=2:v=1:a=1[v][a]"
ff(["-i", f"{W}/head.mp4", "-i", f"{W}/clip3.mp4", "-filter_complex", fc,
    "-map", "[v]", "-map", "[a]"] + VENC + AENC + ["-movflags", "+faststart", f"{D}/amal_ep2.mp4"])
print(f"DONE -> amal_ep2.mp4  {probe(D+'/amal_ep2.mp4')/60:.1f} min  {os.path.getsize(D+'/amal_ep2.mp4')/1e6:.0f} MB", flush=True)
