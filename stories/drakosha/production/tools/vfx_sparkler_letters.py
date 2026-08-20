"""СОК written in sparkler-light over the mini plate.

Letters are built from STROKES, not font glyphs: С is an arc, О a ring, К three
lines. Points are sampled along each stroke, given a slow wobble, drawn as hot
cores, then bloomed and twinkled. That is what a sparkler actually looks like,
and it is what the character sheet asks for.
"""
import numpy as np, math, subprocess, os, sys
from PIL import Image
from scipy.ndimage import gaussian_filter

W,H,FPS = 1280,720,24
SRC = sys.argv[1]; OUT = sys.argv[2]
rng = np.random.default_rng(7)

# ---------------------------------------------------------------- letterforms
def arc(cx,cy,r,a0,a1,n=420,squash=1.0):
    t=np.linspace(math.radians(a0),math.radians(a1),n)
    return np.stack([cx+np.cos(t)*r, cy+np.sin(t)*r*squash],1)
def line(x0,y0,x1,y1,n=190):
    t=np.linspace(0,1,n)
    return np.stack([x0+(x1-x0)*t, y0+(y1-y0)*t],1)

def letter(ch,cx,cy,s):
    if ch=='С':  return [arc(cx,cy,s*0.5,55,305)]
    if ch=='О':  return [arc(cx,cy,s*0.5,0,360,n=520)]
    if ch=='К':
        return [line(cx-s*0.34,cy-s*0.5,cx-s*0.34,cy+s*0.5,240),
                line(cx-s*0.30,cy+s*0.02,cx+s*0.36,cy-s*0.5,170),
                line(cx-s*0.30,cy+s*0.02,cx+s*0.38,cy+s*0.5,170)]
    raise ValueError(ch)

SIZE=118
LETTERS=[('С',232,250),('О',392,250),('К',548,250)]
STROKES={ch:letter(ch,cx,cy,SIZE) for ch,cx,cy in LETTERS}
# arc-length parameter per point, so a write-on reveals in drawing order
PARAM={}
for ch,st in STROKES.items():
    segs=[]; total=0
    for s_ in st:
        d=np.r_[0,np.cumsum(np.hypot(*np.diff(s_,axis=0).T))]
        segs.append(d+total); total=d[-1]+total+6
    PARAM[ch]=[x/total for x in segs]

def wob(pts,t,amp,seed):
    k=rng_seeded(seed)
    ph=k.uniform(0,6.28,len(pts))
    f =k.uniform(0.7,1.6,len(pts))
    dx=np.sin(t*2.1*f+ph)*amp
    dy=np.cos(t*1.7*f+ph*1.3)*amp
    return pts+np.stack([dx,dy],1)
_cache={}
def rng_seeded(s):
    if s not in _cache: _cache[s]=np.random.default_rng(s)
    return _cache[s]

def splat(buf,pts,bright):
    """additively stamp points into a float buffer with bilinear weight"""
    x=pts[:,0]; y=pts[:,1]
    m=(x>1)&(x<W-2)&(y>1)&(y<H-2)
    x=x[m]; y=y[m]; b=np.asarray(bright)[m] if np.ndim(bright) else np.full(x.shape,bright)
    x0=np.floor(x).astype(int); y0=np.floor(y).astype(int)
    fx=x-x0; fy=y-y0
    for dx,dy,wgt in ((0,0,(1-fx)*(1-fy)),(1,0,fx*(1-fy)),(0,1,(1-fx)*fy),(1,1,fx*fy)):
        np.add.at(buf,(y0+dy,x0+dx),b*wgt)

EMBERS=[]   # (x,y,vx,vy,life,age,bright)

def render_letter(buf,ch,t_since,now):
    """t_since: seconds since this letter began writing on. None = not yet."""
    reveal = 1.0 if t_since is None else min(1.0, max(0.0, t_since/0.42))
    for si,(s_,prm) in enumerate(zip(STROKES[ch],PARAM[ch])):
        keep = prm<=reveal
        if not keep.any(): continue
        pts=wob(s_[keep],now,1.9,hash((ch,si))%9999)
        k=rng_seeded(hash((ch,si,'b'))%9999)
        tw=0.80+0.20*np.sin(now*6.0+k.uniform(0,6.28,len(pts)))
        splat(buf,pts,1.35*tw)
        # a second, jitter-free pass gives the stroke a continuous body so the
        # letter reads as light rather than as a dotted outline
        splat(buf,s_[keep],0.55)
        # the burning head of the stroke throws embers while it writes
        if t_since is not None and reveal<1.0 and si==0 and now*FPS%1<1:
            head=pts[-1]
            for _ in range(3):
                EMBERS.append([head[0],head[1],
                               rng.normal(0,26),rng.normal(-34,16),
                               rng.uniform(0.5,1.1),0.0,rng.uniform(0.5,1.0)])

def step_embers(buf,dt):
    keep=[]
    for e in EMBERS:
        e[5]+=dt
        if e[5]>=e[4]: continue
        e[0]+=e[2]*dt; e[1]+=e[3]*dt; e[3]+=52*dt
        a=1.0-e[5]/e[4]
        splat(buf,np.array([[e[0],e[1]]]),e[6]*a*a*0.9)
        keep.append(e)
    EMBERS[:]=keep

def glow(buf):
    """hot core + three bloom radii, tinted warm — screened over the plate"""
    core=np.clip(buf,0,4.0)
    b0=gaussian_filter(core,0.7)
    b1=gaussian_filter(core,2.2); b2=gaussian_filter(core,7.5); b3=gaussian_filter(core,24.0)
    lum=core*0.9+b0*1.10+b1*0.95+b2*0.62+b3*0.45
    out=np.zeros((H,W,3),np.float32)
    out[...,0]=lum*1.00
    out[...,1]=lum*0.74
    out[...,2]=lum*0.36
    white=np.clip(core*1.6,0,1)[...,None]*np.array([0.25,0.22,0.16],np.float32)
    return out+white

# ---------------------------------------------------------------- the schedule
CLIP=4.096
WRITE_AT=1.85          # the trail has fired by here; the letter starts forming
CUT_LAST=3.05          # the last repeat stops as she looks up — she never goes back down
REPS=[('С',CLIP),('О',CLIP),('К',CUT_LAST)]

plate_dir='/tmp/sb8/vfx/plate'; os.makedirs(plate_dir,exist_ok=True)
for f in os.listdir(plate_dir): os.remove(os.path.join(plate_dir,f))
subprocess.run(['ffmpeg','-v','error','-i',SRC,'-vsync','0',f'{plate_dir}/p%05d.png'],check=True)
PLATE=sorted(os.listdir(plate_dir))
print('plate frames',len(PLATE))

frames_dir='/tmp/sb8/vfx/frames'; os.makedirs(frames_dir,exist_ok=True)
for f in os.listdir(frames_dir): os.remove(os.path.join(frames_dir,f))

n=0; now=0.0
for ri,(ch,dur) in enumerate(REPS):
    nf=int(round(dur*FPS))
    for i in range(nf):
        t=i/FPS
        pf=PLATE[min(i,len(PLATE)-1)]
        plate=np.asarray(Image.open(os.path.join(plate_dir,pf)).convert('RGB'),np.float32)/255.0
        buf=np.zeros((H,W),np.float32)
        for li,(lch,_,_) in enumerate(LETTERS):
            if li<ri:                       # already written, steady
                render_letter(buf,lch,None,now)
            elif li==ri:                    # being written now
                if t>=WRITE_AT: render_letter(buf,lch,t-WRITE_AT,now)
        step_embers(buf,1/FPS)
        g=glow(buf)
        out=np.clip(1-(1-plate)*(1-np.clip(g,0,1)),0,1)   # screen
        Image.fromarray((out*255).astype(np.uint8)).save(f'{frames_dir}/f{n:05d}.png')
        n+=1; now+=1/FPS
print('frames',n)
subprocess.run(['ffmpeg','-v','error','-y','-framerate',str(FPS),'-i',f'{frames_dir}/f%05d.png',
                '-c:v','libx264','-pix_fmt','yuv420p','-crf','18',OUT],check=True)
print('wrote',OUT)
