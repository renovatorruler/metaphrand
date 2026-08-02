#!/bin/bash
# CONSTRUCTION steps — how a character is actually built, not how a finished render decomposes.
#   1  गति की रेखा + गोला   line of action, and the head as a BALL with a cross that WRAPS it
#   2  मूल आकृतियाँ         the mannequin: egg body, tapered limb tubes, ball joints, wing planes
#   3  किनारा               the silhouette drawn OVER the faint construction
#   4  चेहरा                features placed ON the wrapped guides
#   5  सारी रेखाएँ          every remaining line
#   6  रोशनी और छाया        the finished character, one light source
# Volumes are drawn with cross-contour curves so they read as 3D, not as flat shapes.
set -e
cd /Users/dusty/Dev/metaphrand/stories/kuku/drawguide
mkdir -p steps
python3 <<'PY'
from PIL import Image, ImageFilter, ImageDraw, ImageChops
import numpy as np, math

CHARS=['leda','castor','kalu','kuku','vesper','furia','mitasur','reechh','dadi']
W=900
INK=(60,60,60); GUIDE=(176,176,176); VOL=(120,120,120); FAINT=(212,212,212)

def build_mask(path):
    im=Image.open(path).convert('RGB')
    h=int(im.size[1]*W/im.size[0]); im=im.resize((W,h))
    bg=np.array(im.getpixel((3,3)),dtype=int)
    a=np.array(im,dtype=int)
    m=(np.abs(a-bg).sum(axis=2)>38).astype(np.uint8)*255
    m=Image.fromarray(m).filter(ImageFilter.MedianFilter(5))
    m=m.filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.MinFilter(9))
    inv=ImageChops.invert(m)
    ImageDraw.floodfill(inv,(0,0),0); ImageDraw.floodfill(inv,(W-1,0),0)
    return ImageChops.lighter(m,inv), (W,h)

def widest(arr,y0,y1):
    best=(0,0,0,0)
    for y in range(y0,y1):
        xs=np.nonzero(arr[y])[0]
        if xs.size==0: continue
        if xs[-1]-xs[0]>best[0]: best=(xs[-1]-xs[0],y,xs[0],xs[-1])
    return best[1],best[2],best[3]

def taper(d, p0, p1, r0, r1, fill):
    """a tapered tube — draw overlapping discs down the axis"""
    n=max(8,int(math.hypot(p1[0]-p0[0],p1[1]-p0[1])/3))
    for i in range(n+1):
        t=i/n
        x=p0[0]+(p1[0]-p0[0])*t; y=p0[1]+(p1[1]-p0[1])*t
        r=r0+(r1-r0)*t
        d.ellipse([x-r,y-r,x+r,y+r], fill=fill)

def ball(d, cx, cy, r, col=VOL, cross=True, lean=0.0):
    """a sphere: outline + a vertical and horizontal guide that CURVE around it"""
    d.ellipse([cx-r,cy-r,cx+r,cy+r], outline=col, width=3)
    if not cross: return
    # vertical centre line — an arc bowing toward the facing side
    bow=r*(0.34+abs(lean))
    d.arc([cx-bow+lean*r, cy-r, cx+bow+lean*r, cy+r], 270, 90, fill=col, width=3)
    # eye line — an arc bowing downward, i.e. the equator seen from slightly above
    d.arc([cx-r, cy-r*0.30, cx+r, cy+r*0.62], 0, 180, fill=col, width=3)

for c in CHARS:
    m,size=build_mask(f'sheets/{c}.png')
    arr=np.array(m)
    ys,xs=np.nonzero(arr)
    x0,x1,y0,y1=xs.min(),xs.max(),ys.min(),ys.max(); H=y1-y0
    body_bottom=y1-int(H*0.06)
    hy,hx0,hx1=widest(arr,y0,y0+int(H*0.46))
    by,bx0,bx1=widest(arr,y0+int(H*0.42),body_bottom)
    hr=(hx1-hx0)/2; hcx=(hx0+hx1)/2; hcy=hy
    br=(bx1-bx0)/2; bcx=(bx0+bx1)/2
    bcy=(hcy+body_bottom)/2; byr=(body_bottom-hcy)/2
    crop=(max(0,x0-18), max(0,y0-18), min(size[0],x1+18), min(size[1],y1+18))

    # limbs / wings / ears: connected parts left over once the ball and egg are removed
    ell=Image.new('L', size, 0); de=ImageDraw.Draw(ell)
    de.ellipse([hcx-hr,hcy-hr,hcx+hr,hcy+hr], fill=255)
    de.ellipse([bcx-br,hcy,bcx+br,body_bottom], fill=255)
    parts=np.array(ImageChops.subtract(m, ell).filter(ImageFilter.MedianFilter(7)))
    parts[body_bottom:,:]=0
    lab=np.zeros_like(parts,dtype=np.int32); cur=0; blobs=[]
    for sy in range(0,parts.shape[0],2):
        for sx in range(0,parts.shape[1],2):
            if parts[sy,sx]>128 and lab[sy,sx]==0:
                cur+=1; stack=[(sy,sx)]; pix=[]
                while stack:
                    yy,xx=stack.pop()
                    if yy<0 or xx<0 or yy>=parts.shape[0] or xx>=parts.shape[1]: continue
                    if lab[yy,xx] or parts[yy,xx]<=128: continue
                    lab[yy,xx]=cur; pix.append((yy,xx))
                    stack += [(yy+1,xx),(yy-1,xx),(yy,xx+1),(yy,xx-1)]
                if len(pix)>380: blobs.append(np.array(pix))

    def canvas():
        im=Image.new('RGB', size, (255,255,255)); return im, ImageDraw.Draw(im)

    def draw_volumes(d, col=VOL, with_cross=True):
        # egg body first (behind), then the limb tubes, then the head ball
        d.ellipse([bcx-br,hcy,bcx+br,body_bottom], outline=col, width=3)
        if with_cross:
            d.arc([bcx-br*0.42, hcy, bcx+br*0.42, body_bottom], 270, 90, fill=col, width=2)
            d.arc([bcx-br, bcy-byr*0.34, bcx+br, bcy+byr*0.5], 0, 180, fill=col, width=2)
        for pix in blobs:
            yy=pix[:,0]; xx=pix[:,1]
            cy_,cx_=yy.mean(),xx.mean()
            u=np.stack([xx-cx_, yy-cy_]); cov=u@u.T/len(pix)
            w_,v_=np.linalg.eigh(cov)
            axis=v_[:,-1]; L=math.sqrt(max(w_[-1],1))*2.1; Rw=math.sqrt(max(w_[0],1))*1.7
            p0=(cx_-axis[0]*L, cy_-axis[1]*L); p1=(cx_+axis[0]*L, cy_+axis[1]*L)
            # the end nearer the body is the joint (thicker)
            d0=math.hypot(p0[0]-bcx,p0[1]-bcy); d1=math.hypot(p1[0]-bcx,p1[1]-bcy)
            if d1<d0: p0,p1=p1,p0
            if L/max(Rw,1) > 1.7:
                tube=Image.new('L', size, 0); dt=ImageDraw.Draw(tube)
                taper(dt, p0, p1, Rw*1.05, Rw*0.45, 255)
                edge=ImageChops.difference(tube, tube.filter(ImageFilter.MinFilter(5)))
                d.bitmap((0,0), edge.point(lambda v:255 if v>90 else 0), fill=col)
                d.ellipse([p0[0]-Rw*0.5,p0[1]-Rw*0.5,p0[0]+Rw*0.5,p0[1]+Rw*0.5], outline=col, width=2)
            else:
                d.ellipse([cx_-Rw*1.5, cy_-Rw*1.5, cx_+Rw*1.5, cy_+Rw*1.5], outline=col, width=3)
        ball(d, hcx, hcy, hr, col=col, cross=with_cross)

    # ---- 1: line of action + the ball ----
    im,d=canvas()
    top=(hcx, hcy-hr*1.05); midx=bcx+(bcx-hcx)*0.55
    for t in range(0,101):
        u=t/100
        x=(1-u)**2*top[0]+2*(1-u)*u*midx+u**2*(bcx)
        y=(1-u)**2*top[1]+2*(1-u)*u*bcy+u**2*(body_bottom+6)
        d.ellipse([x-3,y-3,x+3,y+3], fill=(206,90,70))
    ball(d, hcx, hcy, hr, col=INK, cross=True)
    im.crop(crop).save(f'steps/{c}_c1.png')

    # ---- 2: the mannequin ----
    im,d=canvas(); draw_volumes(d, col=VOL, with_cross=True)
    im.crop(crop).save(f'steps/{c}_c2.png')

    # ---- 3: silhouette over faint construction ----
    outline=ImageChops.difference(m, m.filter(ImageFilter.MinFilter(5)))
    im,d=canvas(); draw_volumes(d, col=FAINT, with_cross=False)
    im.paste(INK, mask=outline)
    im.crop(crop).save(f'steps/{c}_c3.png')

    # ---- 4: features on the wrapped guides ----
    line=Image.open(f'steps/{c}_line.png').convert('RGB').resize(size)
    fm=Image.new('L', size, 0)
    ImageDraw.Draw(fm).ellipse([hcx-hr*0.96,hcy-hr*0.96,hcx+hr*0.96,hcy+hr*0.96], fill=255)
    im,d=canvas(); im.paste(INK, mask=outline); im.paste(line, mask=fm)
    d=ImageDraw.Draw(im); ball(d, hcx, hcy, hr, col=FAINT, cross=True)
    im.paste(INK, mask=outline)
    im.crop(crop).save(f'steps/{c}_c4.png')

    print(f'{c}: construction built ({len(blobs)} limb/wing volumes)')
PY
echo "CONSTRUCTION: $(ls steps/*_c*.png | wc -l | tr -d ' ') images"
