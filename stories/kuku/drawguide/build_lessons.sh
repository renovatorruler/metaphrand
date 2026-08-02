#!/bin/bash
# Lesson art built on how the books actually teach:
#  EMBERLEY  — a tiny alphabet of marks; each step adds exactly ONE mark; the new mark is
#              highlighted so the child always knows what to draw next.
#  KISTLER   — the 3D laws practised in every single lesson, not once: contour lines that wrap
#              a form, overlapping, shading away from a fixed light, and a cast shadow.
set -e
cd /Users/dusty/Dev/metaphrand/stories/kuku/drawguide
mkdir -p steps
python3 <<'PY'
from PIL import Image, ImageFilter, ImageDraw, ImageChops
import numpy as np, math

CHARS=['leda','castor','kalu','kuku','vesper','furia','mitasur','reechh','dadi']
W=900
NEW=(206,58,48); OLD=(178,178,178); INK=(60,60,60); FAINT=(216,216,216)

def build_mask(path):
    im=Image.open(path).convert('RGB')
    h=int(im.size[1]*W/im.size[0]); im=im.resize((W,h))
    bg=np.array(im.getpixel((3,3)),dtype=int)
    m=(np.abs(np.array(im,dtype=int)-bg).sum(axis=2)>38).astype(np.uint8)*255
    m=Image.fromarray(m).filter(ImageFilter.MedianFilter(5))
    m=m.filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.MinFilter(9))
    inv=ImageChops.invert(m)
    ImageDraw.floodfill(inv,(0,0),0); ImageDraw.floodfill(inv,(W-1,0),0)
    return ImageChops.lighter(m,inv),(W,h)

def widest(arr,y0,y1):
    best=(0,0,0,0)
    for y in range(y0,y1):
        xs=np.nonzero(arr[y])[0]
        if xs.size and xs[-1]-xs[0]>best[0]: best=(xs[-1]-xs[0],y,xs[0],xs[-1])
    return best[1],best[2],best[3]

for c in CHARS:
    m,size=build_mask(f'sheets/{c}.png'); arr=np.array(m)
    ys,xs=np.nonzero(arr); x0,x1,y0,y1=xs.min(),xs.max(),ys.min(),ys.max(); H=y1-y0
    bb_=y1-int(H*0.06)
    hy,hx0,hx1=widest(arr,y0,y0+int(H*0.46))
    by,bx0,bx1=widest(arr,y0+int(H*0.42),bb_)
    hr=(hx1-hx0)/2; hcx=(hx0+hx1)/2; hcy=hy
    br=(bx1-bx0)/2; bcx=(bx0+bx1)/2; bcy=(hcy+bb_)/2
    HEAD=[hcx-hr,hcy-hr,hcx+hr,hcy+hr]; BODY=[bcx-br,hcy,bcx+br,bb_]
    crop=(max(0,x0-18),max(0,y0-18),min(size[0],x1+18),min(size[1],y1+18))

    ell=Image.new('L',size,0); de=ImageDraw.Draw(ell)
    de.ellipse(HEAD,fill=255); de.ellipse(BODY,fill=255)
    parts=np.array(ImageChops.subtract(m,ell).filter(ImageFilter.MedianFilter(7)))
    parts[bb_:,:]=0
    # three part-groups by height: what is above the head, beside the body, below it
    band=np.zeros_like(parts)
    g={'top':np.zeros_like(parts),'side':np.zeros_like(parts),'low':np.zeros_like(parts)}
    yy,xx=np.nonzero(parts)
    for py,px in zip(yy,xx):
        k='top' if py<hcy else ('side' if py<bcy else 'low')
        g[k][py,px]=255
    groups=[(k,Image.fromarray(v)) for k,v in g.items() if v.any()]

    def canv():
        im=Image.new('RGB',size,(255,255,255)); return im,ImageDraw.Draw(im)
    def ball(d,col,cross):
        d.ellipse(HEAD,outline=col,width=4)
        if cross:
            d.arc([hcx-hr*0.34,hcy-hr,hcx+hr*0.34,hcy+hr],270,90,fill=col,width=3)
            d.arc([hcx-hr,hcy-hr*0.28,hcx+hr,hcy+hr*0.60],0,180,fill=col,width=3)
    def egg(d,col):
        d.ellipse(BODY,outline=col,width=4)
    def blobs(im,keys,col):
        for k,g_ in groups:
            if k in keys: im.paste(col,mask=g_)

    S=[]
    # 1 the ball
    im,d=canv(); ball(d,NEW,False); S.append(im)
    # 2 the cross that wraps it  (contour lines)
    im,d=canv(); ball(d,OLD,False); ball(d,NEW,True); S.append(im)
    # 3 the body egg behind it   (overlapping)
    im,d=canv(); egg(d,NEW); ball(d,OLD,True); S.append(im)
    # 4..6 one group of parts at a time
    shown=[]
    for k,_ in groups:
        im,d=canv(); blobs(im,shown,FAINT); blobs(im,[k],NEW)
        d=ImageDraw.Draw(im); egg(d,OLD); ball(d,OLD,True)
        shown.append(k); S.append(im)
    # 7 one line around it all
    outline=ImageChops.difference(m,m.filter(ImageFilter.MinFilter(5)))
    im,d=canv(); blobs(im,shown,FAINT); egg(d,FAINT); ball(d,FAINT,True)
    im.paste(NEW,mask=outline); S.append(im)
    # 8 the face on the wrapped guides
    line=Image.open(f'steps/{c}_line.png').convert('RGB').resize(size)
    fm=Image.new('L',size,0)
    ImageDraw.Draw(fm).ellipse([hcx-hr*0.96,hcy-hr*0.96,hcx+hr*0.96,hcy+hr*0.96],fill=255)
    facelines=ImageChops.multiply(ImageChops.invert(line.convert('L')),fm)
    im,d=canv(); im.paste(OLD,mask=outline); im.paste(NEW,mask=facelines); S.append(im)
    # 9 the last lines
    allline=ImageChops.invert(line.convert('L')).point(lambda v:255 if v>60 else 0)
    rest=ImageChops.subtract(allline,ImageChops.lighter(facelines,outline))
    im,d=canv(); im.paste(OLD,mask=outline); im.paste(OLD,mask=facelines); im.paste(NEW,mask=rest); S.append(im)
    for i,s in enumerate(S,1): s.crop(crop).save(f'steps/{c}_L{i:02d}.png')
    print(f'{c}: {len(S)} lesson steps')
PY

python3 <<'PY'
from PIL import Image, ImageDraw, ImageFilter
W=H=420; BOX=[75,75,345,345]
def sphere(shade=False, cast=False, contour=False, col=(150,190,132)):
    im=Image.new('RGB',(W,H),(255,255,255))
    if cast:
        sh=Image.new('RGBA',(W,H),(0,0,0,0)); ImageDraw.Draw(sh).ellipse([120,330,400,392],fill=(95,80,60,150))
        im.paste(Image.alpha_composite(im.convert('RGBA'),sh.filter(ImageFilter.GaussianBlur(11))).convert('RGB'),(0,0))
    d=ImageDraw.Draw(im)
    d.ellipse(BOX, fill=col if (shade or cast) else None, outline=(60,60,60), width=6)
    if shade:
        d.chord(BOX, 20, 165, fill=(108,150,95))
        d.ellipse([150,132,208,178], fill=(238,248,232))
        d.ellipse(BOX, outline=(60,60,60), width=6)
    if contour:
        d.arc([BOX[0]+92,BOX[1],BOX[2]-92,BOX[3]], 270, 90, fill=(70,70,70), width=4)
        d.arc([BOX[0],BOX[1]+72,BOX[2],BOX[3]-40], 0, 180, fill=(70,70,70), width=4)
    return im
sphere().save('steps/k1.png')
sphere(contour=True).save('steps/k2.png')
sphere(shade=True, contour=True).save('steps/k3.png')
sphere(shade=True, contour=True, cast=True).save('steps/k4.png')

# the four laws, one small diagram each
im=Image.new('RGB',(W,H),(255,255,255)); d=ImageDraw.Draw(im)
d.ellipse([40,120,250,330], fill=(214,226,240), outline=(60,60,60), width=6)
d.ellipse([160,150,380,370], fill=(150,190,132), outline=(60,60,60), width=6)
im.save('steps/law_overlap.png')
sphere(shade=True).save('steps/law_shade.png')
sphere(shade=True, cast=True).save('steps/law_shadow.png')
sphere(contour=True).save('steps/law_contour.png')

# the mark alphabet
def mark(fn,name):
    im=Image.new('RGB',(W,H),(255,255,255)); d=ImageDraw.Draw(im); fn(d); im.save(f'steps/mark_{name}.png')
mark(lambda d: d.ellipse([80,80,340,340], outline=(60,60,60), width=9), 'circle')
mark(lambda d: d.ellipse([45,120,375,300], outline=(60,60,60), width=9), 'oval')
mark(lambda d: d.arc([80,80,340,340], 40, 320, fill=(60,60,60), width=9), 'c')
mark(lambda d: d.polygon([(210,80),(300,330),(120,330)], outline=(60,60,60), width=9), 'triangle')
mark(lambda d: d.line([90,300,210,110,330,300], fill=(60,60,60), width=9, joint='curve'), 'v')
mark(lambda d: d.ellipse([175,175,245,245], fill=(60,60,60)), 'dot')
print('warm-up, laws and alphabet drawn')
PY
echo "LESSON ART: $(ls steps/*_L*.png steps/k?.png steps/law_*.png steps/mark_*.png | wc -l | tr -d ' ') images"
