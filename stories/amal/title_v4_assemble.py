import os, subprocess, json
from PIL import Image, ImageDraw, ImageFont
D = "/Users/dusty/dev/brehon-law/stories/amal"
W = f"{D}/_title_v4"; os.makedirs(W, exist_ok=True)
AUD = f"{D}/audio/amal_title_theme_saka_v2.mp3"
OUT = f"{D}/amal_title_sequence_v4.mp4"
PREV = f"{D}/amal_title_sequence_v4_preview.mp4"
DEV = "/System/Library/Fonts/Supplemental/Devanagari Sangam MN.ttc"
LAT = "/System/Library/Fonts/Helvetica.ttc"
RED, BONE = (190,54,44), (228,221,208)
Wd, Ht = 1920, 1080
DUR, X = 9.6, 2.0          # per-beat seconds, crossfade seconds  -> 10 beats = 78.0s
ND = round(DUR*25)         # 240 frames
def ff(a): subprocess.run(["ffmpeg","-nostdin","-loglevel","error","-y"]+a, check=True)
def dur(p):
    return float(subprocess.run(["ffprobe","-v","error","-show_entries","format=duration","-of","csv=p=0",p],
                                capture_output=True,text=True).stdout.strip() or 5.0)
OVR = {"fire": f"{D}/title_v4/fire_overlay_anim.mp4",
       "smoke":f"{D}/title_v4/smoke_overlay_anim.mp4",
       "sword":f"{D}/title_v4/sword_overlay_anim.mp4"}

# (name, kind, src, overlay, K-dim, credit-key)
BEATS = [
 ("fort_inside",  "anim",    f"{D}/title_v4/fort_inside.png",            f"{D}/title_v4/fort_inside_anim.mp4",  "sword",0.42, None),
 ("ratan_desk",   "kb",      f"{D}/title_v4/ratan_desk.png",             None,                                  "smoke",0.55, "starring"),
 ("g_deva_family","kb",      f"{D}/title_v4/g_deva_family.png",          None,                                  "smoke",0.32, "cast2"),
 ("g_rana_court", "anim",    f"{D}/title_v4/g_rana_court.png",           f"{D}/title_v4/g_rana_court_anim.mp4", "fire", 0.52, "cast3"),
 ("hand_poppy",   "reuse",   f"{D}/title_culture/hand_poppy_anim.mp4",   None,                                  "smoke",0.42, "written"),
 ("g_sale_anon",  "kb",      f"{D}/title_v4/g_sale_anon.png",            None,                                  "fire", 0.30, "music"),
 ("river_crowd",  "anim",    f"{D}/title_v4/river_crowd.png",            f"{D}/title_v4/river_crowd_anim.mp4",  "smoke",0.46, "dop"),
 ("g_ratan_kanta","kb",      f"{D}/title_v4/g_ratan_kanta.png",          None,                                  "smoke",0.40, "editor"),
 ("d_grounddown", "reuse",   f"{D}/title_culture/d_grounddown_anim.mp4", None,                                  "sword",0.46, "director"),
 ("fort_title",   "anim",    f"{D}/title_v4/fort_inside.png",            f"{D}/title_v4/fort_inside_anim.mp4",  "sword",0.50, "TITLE"),
]
CR = {
 "starring":("STARRING",["RAGHUVIR SOLANKI","DEVENDRA PATHAK"]),
 "cast2":("",["AARTI NIMJE","SALIM SHEIKH"]),
 "cast3":("",["BHAIRAV SINGH RATHORE"]),
 "written":("WRITTEN BY",["ANURAG VAJPEYI"]),
 "music":("MUSIC",["TAPAN SHARMA"]),
 "dop":("CINEMATOGRAPHY",["MURAD ALI"]),
 "editor":("EDITED BY",["NEHA KULKARNI"]),
 "director":("CREATED & DIRECTED BY",["VIKRAMADITYA RATHORE"]),
}
def shadow(d,xy,t,f,fill):
    x,y=xy; d.text((x+2,y+2),t,font=f,fill=(0,0,0,210)); d.text((x,y),t,font=f,fill=fill)
def credit_png(key,path):
    im=Image.new("RGBA",(Wd,Ht),(0,0,0,0)); d=ImageDraw.Draw(im); cx=Wd//2; y=int(Ht*0.74)
    role,names=CR[key]
    if role:
        rf=ImageFont.truetype(LAT,30); rt="   ".join(role)
        shadow(d,(cx-d.textlength(rt,font=rf)/2,y),rt,rf,BONE+(255,)); y+=54
    nf=ImageFont.truetype(LAT,54)
    for n in names:
        shadow(d,(cx-d.textlength(n,font=nf)/2,y),n,nf,BONE+(255,)); y+=72
    im.save(path)
def title_png(path):
    im=Image.new("RGBA",(Wd,Ht),(0,0,0,0)); d=ImageDraw.Draw(im)
    f=ImageFont.truetype(DEV,360); bb=d.textbbox((0,0),"अमल",font=f)
    tw,th=bb[2]-bb[0],bb[3]-bb[1]; tx=(Wd-tw)//2-bb[0]; ty=(Ht-th)//2-bb[1]-20
    d.text((tx+3,ty+3),"अमल",font=f,fill=(0,0,0,220)); d.text((tx,ty),"अमल",font=f,fill=RED+(255,))
    lf=ImageFont.truetype(LAT,34); lt="A   M   A   L"
    d.line([(Wd//2-120,ty+th+70),(Wd//2+120,ty+th+70)],fill=BONE+(230,),width=3)
    shadow(d,(Wd//2-d.textlength(lt,font=lf)/2,ty+th+98),lt,lf,BONE+(255,))
    im.save(path)

# ---------- STAGE 1: build beats ----------
beat_files=[]
for i,b in enumerate(BEATS):
    name,kind,still,animclip,ovkey,K,credit = b
    out=f"{W}/beat{i:02d}.mp4"; beat_files.append(out)
    if os.path.exists(out): print("skip beat",name,flush=True); continue
    ov=OVR[ovkey]
    if kind=="anim" and animclip and os.path.exists(animclip):
        msrc, use_anim = animclip, True
    elif kind=="reuse" and os.path.exists(still):
        msrc, use_anim = still, True          # 'still' field holds the reuse clip path
    else:
        msrc, use_anim = still, False         # ken-burns beat (or anim fallback to the PNG)
    ins=[]
    if use_anim:
        f=DUR/max(dur(msrc),0.1)
        ins+=["-i",msrc]
        base=f"[0:v]setpts=PTS*{f:.4f},scale={Wd}:{Ht}:force_original_aspect_ratio=increase,crop={Wd}:{Ht},setsar=1,fps=25,format=gbrp[b]"
    else:  # ken burns push-in on the still (also fallback if anim missing)
        ins+=["-loop","1","-t",f"{DUR}","-i",msrc]
        base=(f"[0:v]zoompan=z='min(zoom+0.00026,1.065)':d={ND}:"
              f"x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s={Wd}x{Ht}:fps=25,setsar=1,format=gbrp[b]")
    ins+=["-stream_loop","-1","-t",f"{DUR}","-i",ov]
    fc=[base,
        f"[1:v]scale={Wd}:{Ht}:force_original_aspect_ratio=increase,crop={Wd}:{Ht},setsar=1,fps=25,"
        f"colorchannelmixer=rr={K}:gg={K}:bb={K},format=gbrp[o]",
        "[b][o]blend=all_mode=screen:shortest=1[m]",
        "[m]eq=contrast=1.07:saturation=0.90:brightness=-0.01,vignette=PI/4.2[g]"]
    last="[g]"
    if credit:
        cp=f"{W}/cr_{credit}.png"
        (title_png(cp) if credit=="TITLE" else credit_png(credit,cp))
        ins+=["-loop","1","-t",f"{DUR}","-i",cp]
        if credit=="TITLE":
            fc.append(f"[2:v]format=rgba,fade=t=in:st=2.4:d=2.6:alpha=1[c]")
        else:
            fc.append(f"[2:v]format=rgba,fade=t=in:st=1.4:d=0.9:alpha=1,fade=t=out:st={DUR-1.9:.2f}:d=0.9:alpha=1[c]")
        fc.append(f"{last}[c]overlay=0:0[v]"); last="[v]"
    fc.append(f"{last}trim=0:{DUR},setpts=PTS-STARTPTS,format=yuv420p[vo]")
    ff(ins+["-filter_complex",";".join(fc),"-map","[vo]","-r","25",
            "-c:v","libx264","-crf","18","-pix_fmt","yuv420p",out])
    print("beat",i,name,f"{os.path.getsize(out)/1e6:.1f}MB",flush=True)

# ---------- STAGE 2: xfade dissolve chain ----------
N=len(beat_files); ins=[]
for b in beat_files: ins+=["-i",b]
parts=[]; prev="[0:v]"
for i in range(1,N):
    off=i*(DUR-X)
    parts.append(f"{prev}[{i}:v]xfade=transition=dissolve:duration={X}:offset={off:.3f}[x{i}]"); prev=f"[x{i}]"
TOTAL=N*DUR-(N-1)*X
vchain=";".join(parts)+f";{prev}fade=t=in:st=0:d=1.4,fade=t=out:st={TOTAL-3.0:.2f}:d=3.0,format=yuv420p[v]"
ins+=["-i",AUD]
achain=f"[{N}:a]loudnorm=I=-14:TP=-1.2,afade=t=in:st=0:d=1.5,afade=t=out:st={TOTAL-3.0:.2f}:d=3.0[a]"
ff(ins+["-filter_complex",vchain+";"+achain,"-map","[v]","-map","[a]","-t",f"{TOTAL:.3f}",
        "-c:v","libx264","-crf","19","-pix_fmt","yuv420p","-r","25",
        "-c:a","aac","-b:a","160k","-movflags","+faststart",OUT])
print("MASTER",OUT,f"{os.path.getsize(OUT)/1e6:.1f}MB  {TOTAL:.1f}s",flush=True)

# ---------- STAGE 3: <10MB preview (two-pass, shrink res until it fits) ----------
for (rw,rh,vb) in [(1280,720,860),(1024,576,820),(960,540,760)]:
    ff(["-i",OUT,"-vf",f"scale={rw}:{rh}","-c:v","libx264","-b:v",f"{vb}k","-pass","1","-an","-f","mp4","/dev/null"])
    ff(["-i",OUT,"-vf",f"scale={rw}:{rh}","-c:v","libx264","-b:v",f"{vb}k","-pass","2",
        "-c:a","aac","-b:a","96k","-movflags","+faststart",PREV])
    mb=os.path.getsize(PREV)/1e6; print(f"preview {rw}x{rh} {vb}k -> {mb:.1f}MB",flush=True)
    if mb<9.6: break
print("PREVIEW",PREV,f"{os.path.getsize(PREV)/1e6:.1f}MB",flush=True)
