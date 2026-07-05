import os, subprocess
from PIL import Image, ImageDraw, ImageFont
D="stories/amal/title_culture"; W="stories/amal/_title_v3"; os.makedirs(W,exist_ok=True)
AUD="stories/amal/audio/amal_title_theme_instrumental_v1.mp3"; OUT="stories/amal/amal_title_sequence_v3.mp4"
ORDER=["hand_poppy","d_darbar","mahakal","d_wedding","kumbh","d_scale","mata_pujan","d_pen","d_grounddown","d_title"]
ff=lambda a: subprocess.run(["ffmpeg","-nostdin","-loglevel","error","-y"]+a,check=True)
CLIP=8.5; X=1.3; vf="setpts=1.7*PTS,scale=1280:720:force_original_aspect_ratio=increase,crop=1280:720,setsar=1,format=yuv420p"
# अमल overlay (transparent)
DEV="/System/Library/Fonts/Supplemental/Devanagari Sangam MN.ttc"
ov=Image.new("RGBA",(1280,720),(0,0,0,0)); dr=ImageDraw.Draw(ov)
f=ImageFont.truetype(DEV,190); t="अमल"; bb=dr.textbbox((0,0),t,font=f); tw,th=bb[2]-bb[0],bb[3]-bb[1]
dr.text(((1280-tw)//2-bb[0],(720-th)//2-bb[1]),t,font=f,fill=(228,221,208,255)); ov.save(f"{W}/amal_ov.png")
slowed=[]
for name in ORDER:
    base=f"{W}/s_{name}.mp4"
    ff(["-i",f"{D}/{name}_anim.mp4","-vf",vf,"-t",f"{CLIP}","-an","-r","25","-c:v","libx264","-pix_fmt","yuv420p",base])
    if name=="d_title":
        tit=f"{W}/s_title_final.mp4"
        ff(["-i",base,"-loop","1","-i",f"{W}/amal_ov.png","-filter_complex",
            f"[1:v]format=rgba,fade=t=in:st=4.0:d=2.2:alpha=1[ov];[0:v][ov]overlay=0:0:shortest=1[o]",
            "-map","[o]","-t",f"{CLIP}","-r","25","-c:v","libx264","-pix_fmt","yuv420p",tit])
        slowed.append(tit)
    else: slowed.append(base)
ins=[]
for c in slowed: ins+=["-i",c]
ins+=["-i",AUD]; N=len(slowed)
parts=[]; prev="[0:v]"
for i in range(1,N):
    off=i*(CLIP-X); parts.append(f"{prev}[{i}:v]xfade=transition=fade:duration={X}:offset={off:.3f}[x{i}]"); prev=f"[x{i}]"
T=N*CLIP-(N-1)*X
fc=";".join(parts)+f";{prev}fade=t=in:st=0:d=2,fade=t=out:st={T-3:.2f}:d=3[v];[{N}:a]loudnorm=I=-14:TP=-1.2,afade=t=in:st=0:d=2,afade=t=out:st={T-3:.2f}:d=3[a]"
ff(ins+["-filter_complex",fc,"-map","[v]","-map","[a]","-t",f"{T}","-c:v","libx264","-crf","20","-pix_fmt","yuv420p","-r","25","-c:a","aac","-b:a","192k","-movflags","+faststart",OUT])
print("DONE",OUT,f"{os.path.getsize(OUT)/1e6:.1f}MB",f"{T:.0f}s")
