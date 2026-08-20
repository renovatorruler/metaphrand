"""СОК in sparkler-light, v2 — built to read as burning light rather than a drawn line.

Four things separate a sparkler from a neon tube, and v1 had none of them:
  1. the core blows out to WHITE and only the falloff is gold — a stroke that is
     orange all the way through reads as a drawn line
  2. sparks live along the whole letter for as long as it burns, popping and
     dropping, not just at the writing head
  3. brightness varies along the stroke, so no part of it is uniform
  4. the letter throws light INTO the darkness around it and onto the room
"""
import numpy as np, math, subprocess, os, sys
from PIL import Image
from scipy.ndimage import gaussian_filter

W,H,FPS = 1280,720,24
SRC, OUT = sys.argv[1], sys.argv[2]
rng = np.random.default_rng(11)

def arc(cx,cy,r,a0,a1,n=520):
    t=np.linspace(math.radians(a0),math.radians(a1),n)
    return np.stack([cx+np.cos(t)*r, cy+np.sin(t)*r],1)
def line(x0,y0,x1,y1,n=200):
    t=np.linspace(0,1,n); return np.stack([x0+(x1-x0)*t, y0+(y1-y0)*t],1)

def letter(ch,cx,cy,s):
    if ch=='С': return [arc(cx,cy,s*0.5,58,302)]
    if ch=='О': return [arc(cx,cy,s*0.5,0,360,n=620)]
    if ch=='К': return [line(cx-s*0.32,cy-s*0.5,cx-s*0.32,cy+s*0.5,260),
                        line(cx-s*0.28,cy+s*0.04,cx+s*0.34,cy-s*0.5,190),
                        line(cx-s*0.28,cy+s*0.04,cx+s*0.36,cy+s*0.5,190)]
SIZE=118
LETTERS=[('С',232,250),('О',392,250),('К',548,250)]
STROKES={ch:letter(ch,cx,cy,SIZE) for ch,cx,cy in LETTERS}
PARAM={}
for ch,st in STROKES.items():
    segs=[]; run=0
    for s_ in st:
        d=np.r_[0,np.cumsum(np.hypot(*np.diff(s_,axis=0).T))]
        segs.append(d+run); run=d[-1]+run+8
    PARAM[ch]=[x/run for x in segs]

_c={}
def R(s):
    if s not in _c: _c[s]=np.random.default_rng(s)
    return _c[s]

def splat(buf,pts,b,spread=0.0,k=1):
    """stamp points additively; spread>0 jitters copies to give the stroke body"""
    b=np.asarray(b,np.float32)
    if b.ndim==0: b=np.full(len(pts),float(b),np.float32)
    for j in range(k):
        p = pts if spread==0 else pts+rng.normal(0,spread,pts.shape)
        x,y=p[:,0],p[:,1]
        m=(x>1)&(x<W-2)&(y>1)&(y<H-2)
        if not m.any(): continue
        xs,ys,bs=x[m],y[m],b[m]/k
        x0=np.floor(xs).astype(int); y0=np.floor(ys).astype(int)
        fx=xs-x0; fy=ys-y0
        for dx,dy,wg in ((0,0,(1-fx)*(1-fy)),(1,0,fx*(1-fy)),(0,1,(1-fx)*fy),(1,1,fx*fy)):
            np.add.at(buf,(y0+dy,x0+dx),bs*wg)

SPARKS=[]   # x,y,vx,vy,life,age,peak
def emit(pts,n,hot=1.0):
    if len(pts)==0: return
    idx=rng.integers(0,len(pts),n)
    for i in idx:
        SPARKS.append([pts[i,0],pts[i,1],rng.normal(0,17),rng.normal(-9,15),
                       rng.uniform(0.30,0.95),0.0,rng.uniform(0.6,1.0)*hot])
def step_sparks(buf,dt):
    keep=[]
    for s in SPARKS:
        s[5]+=dt
        if s[5]>=s[4]: continue
        s[0]+=s[2]*dt; s[1]+=s[3]*dt; s[3]+=46*dt; s[2]*=0.985
        a=1.0-s[5]/s[4]
        flick=0.55+0.45*math.sin(s[5]*47+s[0])
        splat(buf,np.array([[s[0],s[1]]]),s[6]*a*a*flick*2.6)
        keep.append(s)
    SPARKS[:]=keep

def draw_letter(buf,ch,t_since,now,burning):
    reveal = 1.0 if t_since is None else min(1.0,max(0.0,t_since/0.42))
    for si,(s_,prm) in enumerate(zip(STROKES[ch],PARAM[ch])):
        keep=prm<=reveal
        if not keep.any(): continue
        p=s_[keep]
        k=R(hash((ch,si))%9999)
        ph=k.uniform(0,6.28,len(s_))[keep]; fr=k.uniform(0.6,1.7,len(s_))[keep]
        # a wobble, and brightness that varies ALONG the stroke so no part is flat
        p=p+np.stack([np.sin(now*2.0*fr+ph)*1.7, np.cos(now*1.6*fr+ph*1.3)*1.7],1)
        vary=0.55+0.45*np.sin(prm[keep]*38.0+now*3.1)
        splat(buf,p,1.7*vary,spread=0.55,k=3)   # body
        splat(buf,p,2.3*vary)                    # hot core
        emit(p, 2 if not burning else 5, hot=1.0 if not burning else 1.4)
        if t_since is not None and reveal<1.0 and si==0:
            emit(p[-6:],6,hot=1.6)

def tonemap(buf):
    """HDR-ish: blow the core to white, keep the falloff gold, halo the dark"""
    b0=gaussian_filter(buf,0.8)
    b1=gaussian_filter(buf,3.0)
    b2=gaussian_filter(buf,10.0)
    b3=gaussian_filter(buf,34.0)
    lum=buf*1.0+b0*1.25+b1*1.05+b2*0.70+b3*0.55
    x=1.0-np.exp(-lum*0.95)                 # soft shoulder to 1.0
    hot=np.clip((lum-1.6)/2.2,0,1)          # where it burns white
    warm=np.stack([x*1.00, x*0.62, x*0.20],-1)
    white=np.stack([hot,hot,hot],-1)*0.95
    return np.clip(warm+white,0,1), gaussian_filter(lum,70.0)

CLIP=4.096; WRITE_AT=1.85; CUT_LAST=3.05
REPS=[('С',CLIP),('О',CLIP),('К',CUT_LAST)]

plate_dir='/tmp/sb8/vfx/plate'
if not os.path.isdir(plate_dir) or not os.listdir(plate_dir):
    os.makedirs(plate_dir,exist_ok=True)
    subprocess.run(['ffmpeg','-v','error','-i',SRC,'-vsync','0',f'{plate_dir}/p%05d.png'],check=True)
PLATE=sorted(os.listdir(plate_dir))
fd='/tmp/sb8/vfx/frames2'; os.makedirs(fd,exist_ok=True)
for f in os.listdir(fd): os.remove(os.path.join(fd,f))

n=0; now=0.0
for ri,(ch,dur) in enumerate(REPS):
    for i in range(int(round(dur*FPS))):
        t=i/FPS
        plate=np.asarray(Image.open(os.path.join(plate_dir,PLATE[min(i,len(PLATE)-1)])).convert('RGB'),np.float32)/255.
        buf=np.zeros((H,W),np.float32)
        for li,(lch,_,_) in enumerate(LETTERS):
            if li<ri:  draw_letter(buf,lch,None,now,burning=False)
            elif li==ri and t>=WRITE_AT: draw_letter(buf,lch,t-WRITE_AT,now,burning=True)
        step_sparks(buf,1/FPS)
        light, spill = tonemap(buf)
        # the letters light the darkness AND the room — this is what seats them
        amb=np.stack([spill*0.115, spill*0.070, spill*0.028],-1)
        out=1-(1-plate)*(1-light)
        out=np.clip(out+amb,0,1)
        Image.fromarray((out*255).astype(np.uint8)).save(f'{fd}/f{n:05d}.png')
        n+=1; now+=1/FPS
print('frames',n)
subprocess.run(['ffmpeg','-v','error','-y','-framerate',str(FPS),'-i',f'{fd}/f%05d.png',
                '-c:v','libx264','-pix_fmt','yuv420p','-crf','17',OUT],check=True)
print('wrote',OUT)
