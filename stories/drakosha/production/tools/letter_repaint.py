import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter
FONT='/System/Library/Fonts/Supplemental/Georgia Bold.ttf'
CARVE=np.array([0.78,0.66,0.55])   # measured from the show's own engraving

def find_tiles(im, rowmin=300, minw=35):
    r,g,b=im[:,:,0],im[:,:,1],im[:,:,2]
    face=(r>185)&(g>135)&(b>100)&(r-b>50)&(r-b<130)
    rows=face.sum(axis=1); band=[y for y in range(len(rows)) if rows[y]>rowmin]
    if not band: return None,[]
    y0,y1=band[0],band[-1]
    prof=face[y0:y1,:].sum(axis=0); th=(y1-y0)*0.35
    runs=[];s=None
    for x,v in enumerate(prof):
        if v>th and s is None: s=x
        if v<=th and s is not None:
            if x-s>minw: runs.append((s,x))
            s=None
    if s is not None and len(prof)-s>minw: runs.append((s,len(prof)))
    return (y0,y1),runs

def dilate(m,k=2):
    out=m.copy()
    for dy in range(-k,k+1):
        for dx in range(-k,k+1):
            out |= np.roll(np.roll(m,dy,axis=0),dx,axis=1)
    return out

def glyph_layer(letter, w, h, cx, cy, gh):
    """Render the letter so its ink box is centred on (cx,cy) and gh tall —
       i.e. exactly where and how big the ORIGINAL engraving was."""
    S=4
    probe=ImageFont.truetype(FONT,100)
    d0=ImageDraw.Draw(Image.new('L',(10,10)))
    bb=d0.textbbox((0,0),letter,font=probe)
    size=max(8,int(100.0*gh/max(1,(bb[3]-bb[1]))))
    f=ImageFont.truetype(FONT,size*S//1)
    img=Image.new('L',(w*S,h*S),0); d=ImageDraw.Draw(img)
    bb=d.textbbox((0,0),letter,font=f)
    gw2,gh2=bb[2]-bb[0],bb[3]-bb[1]
    d.text((cx*S-gw2/2-bb[0], cy*S-gh2/2-bb[1]), letter, font=f, fill=255)
    return np.array(img.resize((w,h),Image.LANCZOS)).astype(float)/255.0

def repaint_tile(im, X0,X1,Y0,Y1, letter):
    patch=im[Y0:Y1,X0:X1].copy()
    # A median blur SMOOTHS a stroke instead of removing it, so the background
    # estimate still contained the glyph and the erase left ghosts. A max filter
    # wider than the stroke deletes dark ink outright; the median after it puts
    # the grain back without reintroducing the letter.
    pi=Image.fromarray(np.clip(patch,0,255).astype(np.uint8))
    bg=np.array(pi.filter(ImageFilter.MaxFilter(size=11))
                  .filter(ImageFilter.MedianFilter(size=9))).astype(float)
    old=((bg.sum(axis=2)-patch.sum(axis=2))>22)
    if old.sum()<40: return im
    # A max filter lifts the whole estimate, so the erased area came out lighter
    # than the face around it and the new engraving washed out against it.
    # Rescale bg to the face's own level, measured where there was never a glyph.
    clear=~dilate(old,4)
    if clear.sum()>200:
        ratio=(patch[clear].mean(axis=0)+1e-6)/(bg[clear].mean(axis=0)+1e-6)
        bg=bg*ratio
    ys,xs=np.nonzero(old)
    # min/max include bevel shadow stragglers and inflated the letter. Percentiles
    # measure the glyph itself.
    ylo,yhi=np.percentile(ys,2),np.percentile(ys,98)
    xlo,xhi=np.percentile(xs,2),np.percentile(xs,98)
    cx,cy=(xlo+xhi)/2.0,(ylo+yhi)/2.0
    gh=(yhi-ylo+1)*0.94
    old=dilate(old,3)
    m=np.repeat(old[:,:,None],3,axis=2)
    cleaned=np.where(m,bg,patch)                    # only the engraving is erased
    gm=glyph_layer(letter,X1-X0,Y1-Y0,cx,cy,gh)[:,:,None]
    body=cleaned*(1-gm)+cleaned*CARVE*gm
    lift=np.clip(np.roll(gm,1,axis=0)-gm,0,1)
    body=body*(1-lift*0.5)+np.clip(cleaned*1.2,0,255)*(lift*0.5)
    im[Y0:Y1,X0:X1]=body
    return im

def process(frame_rgb, letters, inset=0.11, rowmin=300):
    im=frame_rgb.astype(float)
    band,runs=find_tiles(im,rowmin=rowmin)
    if band is None: return frame_rgb,0
    y0,y1=band; h=y1-y0; iy=int(h*inset)
    for i,(a,b) in enumerate(runs):
        if i>=len(letters): break
        w=b-a; ix=int(w*inset)
        im=repaint_tile(im,a+ix,b-ix,y0+iy,y1-iy,letters[i])
    return np.clip(im,0,255).astype(np.uint8),len(runs)
