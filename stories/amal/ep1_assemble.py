"""अमल Ep1 — assemble the video. Re-derives the per-segment timeline from the cached audio durations,
batch-translates the Hindi dialogue to English via claude -p, writes a timed SRT, cuts the per-scene
images to the scene timings, and burns the English subtitles. Output: ep1_video.mp4."""
import os, sys, re, json, hashlib, subprocess
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import backends as bk

D = "/Users/dusty/dev/brehon-law/stories/amal"
A = f"{D}/ep1_audio"; IMG = f"{D}/ep1_images"
SPK = re.compile(r"^([A-Z][A-Z][A-Z ]*):\s*(.*)$")
GAP = 0.280
# scene header (the ## tag) -> the image generated for it (order-independent; the NEW-* scenes interleave)
TAG2IMG = {
 "दृश्य एक":"01_field", "दृश्य दो":"02_room", "दृश्य तीन":"03_office", "NEW-FIELD-DUSK":"04_field_dusk",
 "NEW-WITNESS":"17_witness", "दृश्य चार":"05_devahome", "NEW-SUNITA":"06_sunita_night",
 "दृश्य पाँच":"07_mandi", "NEW-TEASTALL":"08_teastall", "दृश्य छह":"09_postmortem",
 "NEW-RATAN-ROUTINE":"10_routine", "NEW-RATAN-WOUND":"11_wound", "दृश्य सात":"12_alliance",
 "NEW-WOMENS-HOUSE":"13_womenshouse", "NEW-PRESSURE":"14_pressure", "दृश्य आठ":"15_school",
 "दृश्य नौ":"16_jeep", "NEW-DEVA-ACTS":"18_deva_morning", "दृश्य दस":"19_envelope",
 "दृश्य ग्यारह":"20_close",
}


def clean(t): return re.sub(r"\s*\([^)]*\)\s*", " ", t).strip()
def digest(key): return f"{A}/seg_{hashlib.sha1(key.encode()).hexdigest()[:16]}.mp3"
def ff(args): subprocess.run(["ffmpeg","-nostdin","-loglevel","error","-y"]+args, check=True)
def ts(s):
    h=int(s//3600); m=int(s%3600//60); sec=s%60
    return f"{h:02d}:{m:02d}:{int(sec):02d},{int((sec-int(sec))*1000):03d}"


# --- parse EP1.md into scene-tagged segments (same as the audio build) ---
segs, action, scene, scene_tags = [], [], -1, []
for raw in open(f"{D}/EP1.md", encoding="utf-8").read().splitlines():
    ln = raw.strip()
    if ln.startswith("## "):
        if action: segs.append((scene,"N"," ".join(action))); action=[]
        scene += 1; scene_tags.append(ln[3:].strip()); continue
    if scene < 0:                       # skip the preamble before scene 1
        continue
    if not ln or ln.startswith(("#","**","---","*","|","> ")):
        if action: segs.append((scene,"N"," ".join(action))); action=[]
        continue
    m = SPK.match(ln)
    if m:
        if action: segs.append((scene,"N"," ".join(action))); action=[]
        spk,txt = m.group(1).strip(), clean(m.group(2))
        if txt: segs.append((scene,spk,txt))
    else:
        action.append(ln)
if action: segs.append((scene,"N"," ".join(action)))

# --- regroup into the same render-parts (N alone; consecutive dialogue → one take) and time them ---
parts, i = [], 0     # part = (kind, [(scene,spk,txt)...], mp3path)
while i < len(segs):
    sc,spk,txt = segs[i]
    if spk == "N":
        parts.append(("N",[segs[i]], digest("N|"+txt))); i+=1
    else:
        run=[]
        while i < len(segs) and segs[i][1] != "N": run.append(segs[i]); i+=1
        key="D|"+"|".join(f"{s}:{t}" for _,s,t in run)
        parts.append(("D",run,digest(key)))

# walk the timeline (gaps between parts, matching the audio's seq)
t = 0.0; timeline = []   # (start, end, kind, lines[(scene,spk,txt)])
for j,(kind,lines,mp3) in enumerate(parts):
    if j: t += GAP
    dur = bk.duration(mp3) if os.path.exists(mp3) else 2.0
    timeline.append((t, t+dur, kind, lines)); t += dur
TOTAL = t

# --- English subtitles for the Hindi dialogue (curated table, keyed by the cleaned line) ---
sys.path.insert(0, D)
from ep1_subs import TR
missing = sorted({txt for st,e,kind,lines in timeline if kind=="D" for sc,spk,txt in lines} - set(TR))
if missing:
    print("WARN: missing translations:", len(missing))
    for m in missing: print("    >", m)
def en(h): return TR.get(h, h)

# --- build SRT (narration cues + per-line dialogue cues, proportional within a take) ---
# the action lines quote a few Hindi phrases in Devanagari; render them English in the subtitles
NARR_FIX = {
 "राम राम, राम राम": "Ram Ram, Ram Ram",
 "साहब, एक बार और सोच लो": "sahib, think once more",
 "हाय लाडो, हाय मेरी लाडो": "Oh my darling, oh my child",
 "गिरधारी का लड़का, दो बीघा, पट्टा": "Girdhari's boy, two bigha, a license",
}
def fix_narr(s):
    for k,v in NARR_FIX.items(): s = s.replace(k,v)
    return s
def split_sentences(s): return [x.strip() for x in re.split(r"(?<=[.!?])\s+", s) if x.strip()]
cues=[]
for st,end,kind,lines in timeline:
    span=end-st
    if kind=="N":
        sents = split_sentences(lines[0][2]) or [lines[0][2]]
        tot=sum(len(x) for x in sents) or 1; c=st
        for x in sents:
            d=span*len(x)/tot; cues.append((c,c+d,fix_narr(x))); c+=d
    else:
        tot=sum(len(t) for _,_,t in lines) or 1; c=st
        for sc,spk,t in lines:
            d=span*len(t)/tot; cues.append((c,c+d, en(t))); c+=d
srt="\n".join(f"{n}\n{ts(a)} --> {ts(b)}\n{txt}\n" for n,(a,b,txt) in enumerate(cues,1))
open(f"{D}/ep1.srt","w",encoding="utf-8").write(srt)
print(f"SRT: {len(cues)} cues, {TOTAL/60:.1f} min")

# --- scene timeline (for image timing) ---
nsc = max(sc for sc,_,_ in segs)+1
scene_dur=[0.0]*nsc
for st,end,kind,lines in timeline:
    sc=lines[0][0]; scene_dur[sc]+=(end-st)
shots=[]
for i in range(nsc):
    img = TAG2IMG.get(scene_tags[i]) if i < len(scene_tags) else None
    p = f"{IMG}/{img}.png" if img else None
    if p and os.path.exists(p): shots.append((p, "static", max(scene_dur[i],0.5)))
    else: print("  no image for scene", i, scene_tags[i] if i<len(scene_tags) else "?")
print("scenes with images:", len(shots), "/", nsc)

# --- assemble (static images cut to scene durations, synced to the audio); reuse if already built ---
from cinema import assemble as asm
nosub = f"{D}/ep1_nosub.mp4"
if os.path.exists(nosub) and os.path.getmtime(nosub) >= os.path.getmtime(f"{D}/ep1_audio.mp3"):
    print("reuse existing ep1_nosub.mp4")
else:
    asm.assemble(shots, f"{D}/ep1_audio.mp3", nosub, res=(1920,1080), fps=24, xfade=0.6)

# --- burn subtitles: SRT -> styled ASS (bakes the style in; avoids fragile force_style escaping) ---
ff(["-i", f"{D}/ep1.srt", f"{D}/ep1.ass"])
ass = open(f"{D}/ep1.ass", encoding="utf-8").read()
if "PlayResX" not in ass:
    ass = ass.replace("[Script Info]", "[Script Info]\nPlayResX: 1920\nPlayResY: 1080", 1)
ass = re.sub(r"^Style: Default,[^\n]*$",
    "Style: Default,Arial,44,&H00FFFFFF,&H000000FF,&H00000000,&H78000000,0,0,0,0,"
    "100,100,0,0,1,2.6,1.2,2,80,80,54,1", ass, flags=re.M)
open(f"{D}/ep1.ass", "w", encoding="utf-8").write(ass)
ff(["-i", nosub, "-vf", f"subtitles={D}/ep1.ass",
    "-c:v", "libx264", "-preset", "veryfast", "-crf", "21", "-c:a", "copy",
    "-movflags", "+faststart", f"{D}/ep1_video.mp4"])
print(f"DONE -> ep1_video.mp4 ({bk.duration(f'{D}/ep1_video.mp4')/60:.1f} min)")
