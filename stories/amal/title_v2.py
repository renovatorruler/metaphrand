import os, subprocess
from PIL import Image, ImageDraw, ImageFont, ImageEnhance, ImageFilter
D = "/Users/dusty/dev/brehon-law/stories/amal"
FR, AUD = f"{D}/title_frames", f"{D}/audio/amal_title_theme_instrumental_v1.mp3"
W = f"{D}/_title_v2"; os.makedirs(W, exist_ok=True)
OUT = f"{D}/amal_title_sequence_v2.mp4"
DEV = "/System/Library/Fonts/Supplemental/Devanagari Sangam MN.ttc"
LAT = "/System/Library/Fonts/Helvetica.ttc"
RED, BONE, BLACK = (182,52,44), (228,221,208), (9,8,7)
Wd, Ht = 1920, 1080
ff = lambda a: subprocess.run(["ffmpeg","-nostdin","-loglevel","error","-y"]+a, check=True)

# soft vignette mask (bright centre -> dark edge), reused
vig = Image.new("L",(Wd,Ht),0); ImageDraw.Draw(vig).ellipse([-Wd*0.30,-Ht*0.30,Wd*1.30,Ht*1.30],fill=255)
vig = vig.filter(ImageFilter.GaussianBlur(180))

def grade(src):
    im = Image.open(src).convert("RGB"); sw,sh=im.size; s=max(Wd/sw,Ht/sh)
    im=im.resize((round(sw*s),round(sh*s)),Image.LANCZOS); x=(im.width-Wd)//2; y=(im.height-Ht)//2
    im=im.crop((x,y,x+Wd,y+Ht)); im=ImageEnhance.Contrast(im).enhance(1.06)
    dark=ImageEnhance.Brightness(im).enhance(0.45)
    return Image.composite(im,dark,vig)

def shadowtext(d, xy, t, font, fill):
    x,y=xy
    d.text((x+2,y+2), t, font=font, fill=(0,0,0)); d.text((x,y), t, font=font, fill=fill)

def credit(im, role, names):
    d=ImageDraw.Draw(im); cx=Wd//2; y=int(Ht*0.72)
    if role:
        rf=ImageFont.truetype(LAT,30); rt="  ".join(role)
        shadowtext(d,(cx-d.textlength(rt,font=rf)/2,y),rt,rf,BONE); y+=56
    nf=ImageFont.truetype(LAT,56)
    for n in names:
        shadowtext(d,(cx-d.textlength(n,font=nf)/2,y),n,nf,BONE); y+=74
    return im

def card(devanagari, latin=None, big=380, color=RED):
    im=Image.new("RGB",(Wd,Ht),BLACK); d=ImageDraw.Draw(im)
    f=ImageFont.truetype(DEV,big); bb=d.textbbox((0,0),devanagari,font=f)
    tw,th=bb[2]-bb[0],bb[3]-bb[1]; ty=(Ht-th)//2-bb[1]-(40 if latin else 0)
    d.text(((Wd-tw)//2-bb[0],ty),devanagari,font=f,fill=color)
    if latin:
        d.line([(Wd//2-110,ty+th+62),(Wd//2+110,ty+th+62)],fill=BONE,width=3)
        lf=ImageFont.truetype(LAT,40); lt="   ".join(latin.upper().split())
        d.text(((Wd-d.textlength(lt,font=lf))//2,ty+th+98),lt,font=lf,fill=BONE)
    return im

# credit map: frame name -> (role, [names]); blanks stay clean
CR = {
 "02_belt_dawn":("STARRING",["RAGHUVIR SOLANKI","DEVENDRA PATHAK"]),
 "03_the_cut":("",["AARTI NIMJE","SALIM SHEIKH"]),
 "04_scale_opium":("",["BHAIRAV SINGH RATHORE"]),
 "05_scale_cash":("WRITTEN BY",["ANURAG VAJPEYI"]),
 "07_thumbprint":("MUSIC",["TAPAN SHARMA"]),
 "08_dry_well":("CINEMATOGRAPHY",["MURAD ALI"]),
 "09_veiled":("CREATED & DIRECTED BY",["VIKRAMADITYA RATHORE"]),
}
frames = sorted(x for x in os.listdir(FR) if x.endswith(".png"))
stills=[]
t0=f"{W}/00_title.png"; card("अमल").save(t0); stills.append(t0)
for fn in frames:
    im=grade(f"{FR}/{fn}")
    if fn[:-4] in {k[:-0] for k in []}: pass
    key=fn[:-4] if fn[:-4] in CR else None
    if key: credit(im, *CR[key])
    p=f"{W}/{fn}"; im.save(p); stills.append(p)
tE=f"{W}/zz_ep.png"; card("चीरा","The Incision",big=300,color=BONE).save(tE); stills.append(tE)

N=len(stills); TOTAL,X=75.0,1.2; Dur=(TOTAL+(N-1)*X)/N
clips=[]
for i,s in enumerate(stills):
    c=f"{W}/clip{i:02d}.mp4"
    ff(["-loop","1","-t",f"{Dur:.3f}","-i",s,"-vf","scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,setsar=1,format=yuv420p","-r","25",c]); clips.append(c)
ins=[]
for c in clips: ins+=["-i",c]
ins+=["-i",AUD]
parts,prev=[],"[0:v]"
for i in range(1,N):
    off=i*(Dur-X); parts.append(f"{prev}[{i}:v]xfade=transition=fade:duration={X}:offset={off:.3f}[x{i}]"); prev=f"[x{i}]"
fc=";".join(parts)+f";{prev}fade=t=in:st=0:d=1.2,fade=t=out:st={TOTAL-2.5:.2f}:d=2.5[v];[{N}:a]loudnorm=I=-14:TP=-1.2,afade=t=out:st={TOTAL-2.5:.2f}:d=2.5[a]"
ff(ins+["-filter_complex",fc,"-map","[v]","-map","[a]","-c:v","libx264","-crf","20","-pix_fmt","yuv420p","-r","25","-c:a","aac","-b:a","192k","-shortest","-movflags","+faststart",OUT])
print("DONE",OUT,f"{os.path.getsize(OUT)/1e6:.1f} MB")
