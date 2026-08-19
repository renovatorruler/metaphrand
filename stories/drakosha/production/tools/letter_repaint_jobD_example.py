import subprocess, numpy as np, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter
FONT='/System/Library/Fonts/Supplemental/Georgia Bold.ttf'
CARVE=np.array([0.58,0.44,0.34])      # darker than the model's own engraving
V='stories/drakosha/production/seedance_batch/output/2026-08-18_EP1_s7jobD_v1_mini.mp4'
OUT='/tmp/jobD_letters.mp4'
LETTERS=['А','О','М','С','К','Т','Л','Б']
# from line46_VASYA.mp3, shifted by the dub offset used in the mix
# The MODEL's own mouth timing, measured from the generated track. Our recording
# says the eight letters in 7.4s; his lips take 9.7s. Placing the recording as one
# block made every letter drift further out of sync than the last, so each letter
# is now cut out and pinned to the window where his mouth actually moves — and the
# glow is driven by the same list, so lips, voice and light all agree.
SPEAK=[(0.30,0.70),(1.48,1.88),(2.90,3.35),(3.95,4.35),
       (5.20,5.65),(7.35,7.80),(8.35,8.80),(9.33,9.80)]
W,H,FPS=1280,720,24

def find_tiles(im):
    r,g,b=im[:,:,0],im[:,:,1],im[:,:,2]
    face=(r>185)&(g>135)&(b>100)&(r-b>50)&(r-b<130)
    rows=face.sum(axis=1); band=[y for y in range(len(rows)) if rows[y]>300]
    if not band: return None,[]
    y0,y1=band[0],band[-1]
    # ONLY THE REAL ROW. In the front view we see the BACKS of the tiles along the
    # bottom edge — blank wood — and the detector was finding them and painting
    # letters onto them, inventing a defect the model never made. The lettered row
    # sits in the middle of frame; anything hugging the bottom is a back.
    if y1>520 or y0<180: return None,[]
    prof=face[y0:y1,:].sum(axis=0); th=(y1-y0)*0.35
    runs=[];s=None
    for x,v in enumerate(prof):
        if v>th and s is None: s=x
        if v<=th and s is not None:
            if x-s>35: runs.append((s,x)); 
            s=None
    if s is not None and len(prof)-s>35: runs.append((s,len(prof)))
    return (y0,y1),runs

_gcache={}
def glyph(letter,w,h,cx,cy,gh):
    key=(letter,w,h,round(cx,1),round(cy,1),round(gh,1))
    if key in _gcache: return _gcache[key]
    S=3
    probe=ImageFont.truetype(FONT,100)
    d0=ImageDraw.Draw(Image.new('L',(8,8)))
    bb=d0.textbbox((0,0),letter,font=probe)
    size=max(8,int(100.0*gh/max(1,(bb[3]-bb[1]))))
    f=ImageFont.truetype(FONT,size*S)
    img=Image.new('L',(w*S,h*S),0); d=ImageDraw.Draw(img)
    bb=d.textbbox((0,0),letter,font=f)
    d.text((cx*S-(bb[2]-bb[0])/2-bb[0], cy*S-(bb[3]-bb[1])/2-bb[1]),letter,font=f,fill=255)
    a=np.array(img.resize((w,h),Image.LANCZOS)).astype(float)/255.0
    _gcache[key]=a
    return a

def process(im, t):
    band,runs=find_tiles(im)
    if band is None or len(runs)<6: return im   # a partial row is not the row
    y0,y1=band; h=y1-y0
    iy=int(h*0.11)
    faces=[]
    for (a,b) in runs:
        w=b-a; ix=int(w*0.11)
        faces.append((a+ix,b-ix,y0+iy,y1-iy))
    # baseline face level across the row, so the model's own glow is flattened
    # PER-CHANNEL baseline. A blown-out glow loses saturation as well as level,
    # so scaling by luminance alone turned the model's lit tile grey-green. The
    # reference is the per-channel median across the row, which is a normal tile.
    cols=[]
    for (X0,X1,Y0,Y1) in faces:
        p=im[Y0:Y1,X0:X1].astype(float)
        fm=(p[:,:,0]>150)&(p[:,:,1]>105)&(p[:,:,2]>70)
        cols.append(p[fm].mean(axis=0) if fm.sum()>50 else p.reshape(-1,3).mean(axis=0))
    base=np.median(np.array(cols),axis=0)
    out=im.astype(float)
    for i,(X0,X1,Y0,Y1) in enumerate(faces):
        if i>=len(LETTERS): break
        patch=im[Y0:Y1,X0:X1].astype(float)
        # Only pale WOOD counts as face. A finger crossing the tile was being
        # averaged into the statistics and threw the whole tile off-colour.
        pr,pg,pb=patch[:,:,0],patch[:,:,1],patch[:,:,2]
        facepx=(pr>150)&(pg>105)&(pb>70)&(pr-pb>40)&(pr-pb<140)
        if facepx.mean()<0.45:      # tile is occluded — leave it alone entirely
            continue
        pi=Image.fromarray(np.clip(patch,0,255).astype(np.uint8))
        bg=np.array(pi.filter(ImageFilter.MaxFilter(size=11))
                      .filter(ImageFilter.MedianFilter(size=9))).astype(float)
        old=((bg.sum(axis=2)-patch.sum(axis=2))>22)
        if old.sum()<40: continue
        ys,xs=np.nonzero(old)
        ylo,yhi=np.percentile(ys,2),np.percentile(ys,98)
        xlo,xhi=np.percentile(xs,2),np.percentile(xs,98)
        cx,cy=(xlo+xhi)/2.0,(ylo+yhi)/2.0
        gh=(yhi-ylo+1)*0.94
        # normalise bg to the tile's true face level, then use it EVERYWHERE:
        # partial erasure is what left the old letters showing through.
        clear=(~old)&facepx
        if clear.sum()>200:
            k=(patch[clear].mean(axis=0)+1e-6)/(bg[clear].mean(axis=0)+1e-6)
            bg=bg*np.clip(k,0.75,1.35)
        cleaned=bg
        # flatten the generated glow so ours is the only one
        m=cleaned[facepx].mean(axis=0) if facepx.sum()>50 else cleaned.reshape(-1,3).mean(axis=0)
        cleaned=cleaned*np.clip(base/np.maximum(m,1.0),0.45,1.8)
        lit=any(a<=t<=b for (a,b) in [SPEAK[i]] )
        if lit:
            cleaned=np.clip(cleaned*1.42+np.array([16,10,0]),0,255)
        gm=glyph(LETTERS[i],X1-X0,Y1-Y0,cx,cy,gh)[:,:,None]
        body=cleaned*(1-gm)+cleaned*CARVE*gm
        lift=np.clip(np.roll(gm,1,axis=0)-gm,0,1)
        body=body*(1-lift*0.5)+np.clip(cleaned*1.25,0,255)*(lift*0.5)
        out[Y0:Y1,X0:X1]=body
    return np.clip(out,0,255).astype(np.uint8)

rd=subprocess.Popen(['ffmpeg','-v','error','-i',V,'-f','rawvideo','-pix_fmt','rgb24','-'],stdout=subprocess.PIPE)
wr=subprocess.Popen(['ffmpeg','-v','error','-y','-f','rawvideo','-pix_fmt','rgb24','-s',f'{W}x{H}','-r',str(FPS),
                     '-i','-','-i',V,'-map','0:v','-map','1:a','-c:v','libx264','-crf','16','-preset','medium',
                     '-pix_fmt','yuv420p','-c:a','copy','-shortest',OUT],stdin=subprocess.PIPE)
n=0
while True:
    buf=rd.stdout.read(W*H*3)
    if len(buf)<W*H*3: break
    im=np.frombuffer(buf,np.uint8).reshape(H,W,3)
    wr.stdin.write(process(im, n/float(FPS)).tobytes())
    n+=1
wr.stdin.close(); wr.wait()
print('frames',n,'->',OUT)
