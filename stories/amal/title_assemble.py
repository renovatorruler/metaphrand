"""AMAL title sequence assemble: 9 symbolic frames + अमल card, slow crossfades, over the instrumental."""
import os, subprocess
from PIL import Image, ImageDraw, ImageFont
D = "/Users/dusty/dev/brehon-law/stories/amal"
FR, AUD = f"{D}/title_frames", f"{D}/audio/amal_title_theme_instrumental_v1.mp3"
W = f"{D}/_title_work"; os.makedirs(W, exist_ok=True)
OUT = f"{D}/amal_title_sequence_v1.mp4"
ff = lambda a: subprocess.run(["ffmpeg","-nostdin","-loglevel","error","-y"]+a, check=True)

# title card: अमल, warm off-white on near-black
FONT = "/System/Library/Fonts/Supplemental/Devanagari Sangam MN.ttc"
card = Image.new("RGB", (1920,1080), (9,8,7)); dr = ImageDraw.Draw(card)
fn = ImageFont.truetype(FONT, 360); t = "अमल"
bb = dr.textbbox((0,0), t, font=fn); tw, th = bb[2]-bb[0], bb[3]-bb[1]
dr.text(((1920-tw)/2 - bb[0], (1080-th)/2 - bb[1]), t, font=fn, fill=(212,203,190))
title_png = f"{W}/title_amal.png"; card.save(title_png)

stills = sorted(f"{FR}/{x}" for x in os.listdir(FR) if x.endswith(".png")) + [title_png]
N = len(stills); TOTAL, X = 75.0, 1.2
Dur = (TOTAL + (N-1)*X)/N
clips = []
for i, s in enumerate(stills):
    c = f"{W}/c{i:02d}.mp4"
    ff(["-loop","1","-t",f"{Dur:.3f}","-i",s,"-vf",
        "scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,setsar=1,format=yuv420p",
        "-r","25",c]); clips.append(c)

ins = []
for c in clips: ins += ["-i", c]
ins += ["-i", AUD]
parts, prev = [], "[0:v]"
for i in range(1, N):
    off = i*(Dur - X); lbl = f"[x{i}]"
    parts.append(f"{prev}[{i}:v]xfade=transition=fade:duration={X}:offset={off:.3f}{lbl}"); prev = lbl
fc = ";".join(parts) + f";{prev}fade=t=in:st=0:d=1.5,fade=t=out:st={TOTAL-2.5:.2f}:d=2.5[v]"
ff(ins + ["-filter_complex", fc, "-map","[v]","-map",f"{N}:a",
    "-c:v","libx264","-pix_fmt","yuv420p","-r","25","-c:a","aac","-b:a","192k","-shortest",
    "-movflags","+faststart", OUT])
print("DONE ->", OUT, f"{os.path.getsize(OUT)/1e6:.1f} MB")
