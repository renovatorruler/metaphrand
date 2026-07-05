import os, subprocess
from PIL import Image, ImageDraw, ImageFont
D = "/Users/dusty/dev/brehon-law/stories/amal"
W = f"{D}/_title_v5"; os.makedirs(W, exist_ok=True)
MUS = f"{D}/audio/amal_title_saka_suno_v1.mp3"; MSS, MLEN = 123.0, 60.0  # climax-to-end window
OUT = f"{D}/amal_title_sequence_v5.mp4"; PREV = f"{D}/amal_title_sequence_v5_preview.mp4"
DEV = "/System/Library/Fonts/Supplemental/Devanagari Sangam MN.ttc"; LAT = "/System/Library/Fonts/Helvetica.ttc"
RED, BONE = (190,54,44), (228,221,208); Wd, Ht = 1920, 1080
X = 0.7                          # fade-through-black duration
def ff(a): subprocess.run(["ffmpeg","-nostdin","-loglevel","error","-y"]+a, check=True)
def dur(p):
    return float(subprocess.run(["ffprobe","-v","error","-show_entries","format=duration","-of","csv=p=0",p],
                                capture_output=True,text=True).stdout.strip() or 5.0)
# (name, clip, still_fallback, credit_key)
BEATS = [
 ("fort",  f"{D}/title_v4/fort_inside_anim.mp4",   f"{D}/title_v4/fort_inside.png",        None),
 ("lance", f"{D}/title_v5/lancing_v2_anim.mp4",    f"{D}/title_v5/lancing_v2.png",         "starring"),
 ("ratan", f"{D}/title_v5/ratan_desk_v2_anim.mp4", f"{D}/title_v5/ratan_desk_v2.png",      "c2"),
 ("court", f"{D}/title_v5/rana_court_v2b_anim.mp4",f"{D}/title_v5/rana_court_v2b.png",     "c3"),
 ("sale",  f"{D}/title_v5/sale_v2_anim.mp4",       f"{D}/title_v5/sale_v2.png",            "written"),
 ("deva",  f"{D}/title_v5/deva_family_v2_anim.mp4",f"{D}/title_v5/deva_family_v2.png",     "music"),
 ("kanta", f"{D}/title_v5/ratan_kanta_v2_anim.mp4",f"{D}/title_v5/ratan_kanta_v2.png",     "director"),
 ("TITLE", None, None, None),
]
N=len(BEATS); DUR=(MLEN+(N-1)*X)/N    # 8 beats, 0.7s fades -> 60.0s
CR = {
 "starring":("STARRING",["RAGHUVIR SOLANKI"]),
 "c2":("",["DEVENDRA PATHAK"]),
 "c3":("",["AARTI NIMJE    SALIM SHEIKH"]),
 "written":("WRITTEN BY",["ANURAG VAJPEYI"]),
 "music":("MUSIC",["TAPAN SHARMA"]),
 "director":("CREATED & DIRECTED BY",["VIKRAMADITYA RATHORE"]),
}
def shadow(d,xy,t,f,fill):
    x,y=xy; d.text((x+2,y+2),t,font=f,fill=(0,0,0,210)); d.text((x,y),t,font=f,fill=fill)
def credit_png(key,path):
    im=Image.new("RGBA",(Wd,Ht),(0,0,0,0)); d=ImageDraw.Draw(im); cx=Wd//2; y=int(Ht*0.78)
    role,names=CR[key]
    if role:
        rf=ImageFont.truetype(LAT,28); rt="   ".join(role); shadow(d,(cx-d.textlength(rt,font=rf)/2,y),rt,rf,BONE+(255,)); y+=50
    nf=ImageFont.truetype(LAT,50)
    for n in names: shadow(d,(cx-d.textlength(n,font=nf)/2,y),n,nf,BONE+(255,)); y+=66
    im.save(path)
def title_png(path):
    im=Image.new("RGB",(Wd,Ht),(6,5,4)); d=ImageDraw.Draw(im)
    f=ImageFont.truetype(DEV,380); bb=d.textbbox((0,0),"अमल",font=f); tw,th=bb[2]-bb[0],bb[3]-bb[1]
    tx=(Wd-tw)//2-bb[0]; ty=(Ht-th)//2-bb[1]-20
    d.text((tx+3,ty+3),"अमल",font=f,fill=(0,0,0)); d.text((tx,ty),"अमल",font=f,fill=RED)
    lf=ImageFont.truetype(LAT,36); lt="A   M   A   L"
    d.line([(Wd//2-130,ty+th+74),(Wd//2+130,ty+th+74)],fill=BONE,width=3)
    d.text((Wd//2-d.textlength(lt,font=lf)/2,ty+th+104),lt,font=lf,fill=BONE)
    im.save(path)

# ---------- STAGE 1: beats ----------
beat_files=[]
for i,(name,clip,still,credit) in enumerate(BEATS):
    out=f"{W}/b{i:02d}.mp4"; beat_files.append(out)
    if os.path.exists(out): print("skip",name,flush=True); continue
    if name=="TITLE":
        tp=f"{W}/titlecard.png"; title_png(tp)
        ff(["-loop","1","-t",f"{DUR}","-i",tp,"-vf",
            f"scale={Wd}:{Ht},setsar=1,fps=25,fade=t=in:st=0.6:d=2.6,format=yuv420p",
            "-r","25","-c:v","libx264","-crf","18",out]); print("beat title",flush=True); continue
    src = clip if (clip and os.path.exists(clip)) else still
    is_clip = src==clip
    ins=[]
    if is_clip:
        f=DUR/max(dur(src),0.1); ins+=["-i",src]
        base=(f"[0:v]setpts=PTS*{f:.4f},scale={Wd}:{Ht}:force_original_aspect_ratio=increase,crop={Wd}:{Ht},"
              f"setsar=1,fps=25,eq=contrast=1.04:saturation=0.98[g]")
    else:  # static fallback: gentle push on the still
        ins+=["-loop","1","-t",f"{DUR}","-i",src]
        base=(f"[0:v]zoompan=z='min(zoom+0.00022,1.05)':d={round(DUR*25)}:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':"
              f"s={Wd}x{Ht}:fps=25,setsar=1,eq=contrast=1.04:saturation=0.98[g]")
    fc=[base]; last="[g]"
    if credit:
        cp=f"{W}/cr_{credit}.png"; credit_png(credit,cp); ins+=["-loop","1","-t",f"{DUR}","-i",cp]
        fc.append(f"[1:v]format=rgba,fade=t=in:st=1.2:d=0.9:alpha=1,fade=t=out:st={DUR-1.7:.2f}:d=0.9:alpha=1[c]")
        fc.append(f"{last}[c]overlay=0:0[v]"); last="[v]"
    fc.append(f"{last}trim=0:{DUR},setpts=PTS-STARTPTS,format=yuv420p[vo]")
    ff(ins+["-filter_complex",";".join(fc),"-map","[vo]","-r","25","-c:v","libx264","-crf","18","-pix_fmt","yuv420p",out])
    print("beat",i,name,f"{os.path.getsize(out)/1e6:.1f}MB",flush=True)

# ---------- STAGE 2: fade-through-black chain + music ----------
ins=[]
for b in beat_files: ins+=["-i",b]
parts=[]; prev="[0:v]"
for i in range(1,N):
    off=i*(DUR-X); parts.append(f"{prev}[{i}:v]xfade=transition=fadeblack:duration={X}:offset={off:.3f}[x{i}]"); prev=f"[x{i}]"
TOTAL=N*DUR-(N-1)*X
vchain=";".join(parts)+f";{prev}fade=t=in:st=0:d=1.0,fade=t=out:st={TOTAL-0.5:.2f}:d=0.5,format=yuv420p[v]"
ins+=["-ss",f"{MSS}","-t",f"{MLEN}","-i",MUS]
achain=f"[{N}:a]loudnorm=I=-14:TP=-1.2,afade=t=in:st=0:d=1.5,afade=t=out:st={TOTAL-0.6:.2f}:d=0.6[a]"
ff(ins+["-filter_complex",vchain+";"+achain,"-map","[v]","-map","[a]","-t",f"{TOTAL:.3f}",
        "-c:v","libx264","-crf","19","-pix_fmt","yuv420p","-r","25","-c:a","aac","-b:a","160k","-movflags","+faststart",OUT])
print("MASTER",OUT,f"{os.path.getsize(OUT)/1e6:.1f}MB  {TOTAL:.1f}s",flush=True)

# ---------- STAGE 3: <10MB preview ----------
for (rw,rh,vb) in [(1280,720,1050),(1024,576,980),(960,540,900)]:
    ff(["-i",OUT,"-vf",f"scale={rw}:{rh}","-c:v","libx264","-b:v",f"{vb}k","-pass","1","-an","-f","mp4","/dev/null"])
    ff(["-i",OUT,"-vf",f"scale={rw}:{rh}","-c:v","libx264","-b:v",f"{vb}k","-pass","2","-c:a","aac","-b:a","96k","-movflags","+faststart",PREV])
    mb=os.path.getsize(PREV)/1e6; print(f"preview {rw}x{rh} {vb}k -> {mb:.1f}MB",flush=True)
    if mb<9.6: break
print("PREVIEW",PREV,f"{os.path.getsize(PREV)/1e6:.1f}MB",flush=True)
