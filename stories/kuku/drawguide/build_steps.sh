#!/bin/bash
# Draw-guide step art — SIX genuinely additive steps, each adding one thing, so there is no
# "now draw the rest of the owl" jump. Everything is derived from the canon character sheets.
#   1 आकार   two shapes: head circle + body oval
#   2 हिस्से  + the leftover parts (wings/tail/limbs/ears) as grey blobs, correctly placed
#   3 किनारा  the outer contour only — one continuous line around the whole character
#   4 चेहरा   + the face inside the head circle (eyes, snout, mouth)
#   5 रेखा    + every remaining interior line
#   6 रंग     the finished character
set -e
cd /Users/dusty/Dev/metaphrand/stories/kuku/drawguide
mkdir -p steps
CS=sheets
W=900

for c in leda castor kalu kuku vesper furia mitasur reechh dadi; do
  ffmpeg -y -v error -i "$CS/$c.png" -vf "scale=${W}:-1,edgedetect=low=0.06:high=0.22,negate,eq=contrast=1.7" "steps/${c}_line.png"
  ffmpeg -y -v error -i "steps/${c}_line.png" -vf "eq=contrast=0.42:brightness=0.36" "steps/${c}_trace.png"
done

python3 <<'PY'
from PIL import Image, ImageFilter, ImageDraw, ImageChops
CHARS=['leda','castor','kalu','kuku','vesper','furia','mitasur','reechh','dadi']
W=900
INK=(70,70,70); GUIDE=(185,185,185); PART=(214,214,214); PARTLINE=(150,150,150)

def build_mask(path):
    im=Image.open(path).convert('RGB')
    h=int(im.size[1]*W/im.size[0])
    im=im.resize((W,h))
    bg=im.getpixel((3,3))
    m=Image.new('L', im.size, 0); px=im.load(); mp=m.load()
    for y in range(h):
        for x in range(W):
            r,g,b=px[x,y]
            mp[x,y]=255 if abs(r-bg[0])+abs(g-bg[1])+abs(b-bg[2])>38 else 0
    m=m.filter(ImageFilter.MedianFilter(5))
    # close thin gaps so holes cannot leak to the border, then fill them
    m=m.filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.MinFilter(9))
    inv=ImageChops.invert(m)
    ImageDraw.floodfill(inv, (0,0), 0)
    ImageDraw.floodfill(inv, (W-1,0), 0)
    m=ImageChops.lighter(m, inv)
    return m, (W,h)

def widest(mp,size,y0,y1):
    best=(0,0,0,0)
    for y in range(y0,y1):
        xs=[x for x in range(size[0]) if mp[x,y]>128]
        if not xs: continue
        if xs[-1]-xs[0]>best[0]: best=(xs[-1]-xs[0], y, xs[0], xs[-1])
    return best[1],best[2],best[3]

for c in CHARS:
    m,size=build_mask(f'sheets/{c}.png')
    bb=m.getbbox(); x0,y0,x1,y1=bb; H=y1-y0
    mp=m.load()
    body_bottom=y1-int(H*0.06)                       # ignore the cast-shadow ellipse
    hy,hx0,hx1=widest(mp,size,y0,y0+int(H*0.46))
    by,bx0,bx1=widest(mp,size,y0+int(H*0.42),body_bottom)
    hr=(hx1-hx0)/2; hcx=(hx0+hx1)/2; hcy=hy
    br=(bx1-bx0)/2; bcx=(bx0+bx1)/2
    HEAD=[hcx-hr,hcy-hr,hcx+hr,hcy+hr]
    BODY=[bcx-br,hcy,bcx+br,body_bottom]
    crop=(max(0,x0-16), max(0,y0-16), min(size[0],x1+16), min(size[1],y1+16))

    def canvas():
        im=Image.new('RGB', size, (255,255,255)); return im, ImageDraw.Draw(im)
    def shapes_on(d, faint=False):
        col=GUIDE if faint else INK
        d.ellipse(HEAD, outline=col, width=3)
        d.ellipse(BODY, outline=col, width=3)

    # ---- 1: the two shapes ----
    im,d=canvas(); shapes_on(d)
    d.line([hcx,hcy-hr-8,hcx,body_bottom+8], fill=GUIDE, width=2)
    d.line([hcx-hr,hcy+hr*0.10,hcx+hr,hcy+hr*0.10], fill=GUIDE, width=2)
    d.ellipse([hcx-4,hcy-4,hcx+4,hcy+4], fill=(200,60,60))
    im.crop(crop).save(f'steps/{c}_s1.png')

    # ---- 2: + the leftover parts, correctly placed ----
    ell=Image.new('L', size, 0); de=ImageDraw.Draw(ell)
    de.ellipse(HEAD, fill=255); de.ellipse(BODY, fill=255)
    parts=ImageChops.subtract(m, ell)
    parts=parts.filter(ImageFilter.MedianFilter(7))
    # the cast shadow on the ground is not a body part — drop it
    pp=parts.load()
    for yy in range(body_bottom, size[1]):
        for x in range(size[0]): pp[x,yy]=0
    im,d=canvas()
    im.paste(PART, mask=parts)
    edge=ImageChops.difference(parts, parts.filter(ImageFilter.MinFilter(5)))
    im.paste(PARTLINE, mask=edge)
    d=ImageDraw.Draw(im); shapes_on(d)
    im.crop(crop).save(f'steps/{c}_s2.png')

    # ---- 3: the outer contour only ----
    outline=ImageChops.difference(m, m.filter(ImageFilter.MinFilter(5)))
    im,d=canvas(); im.paste(INK, mask=outline)
    im.crop(crop).save(f'steps/{c}_s3.png')

    # ---- 4: + the face, inside the head circle ----
    line=Image.open(f'steps/{c}_line.png').convert('RGB').resize(size)
    facemask=Image.new('L', size, 0)
    ImageDraw.Draw(facemask).ellipse([hcx-hr*0.94,hcy-hr*0.94,hcx+hr*0.94,hcy+hr*0.94], fill=255)
    im,d=canvas(); im.paste(INK, mask=outline)
    im.paste(line, mask=facemask)
    im.paste(INK, mask=ImageChops.multiply(outline, facemask.point(lambda v:255)))
    im.crop(crop).save(f'steps/{c}_s4.png')

    # ---- 5: every remaining line ----
    Image.open(f'steps/{c}_line.png').convert('RGB').resize(size).crop(crop).save(f'steps/{c}_s5.png')
    print(f'{c}: 5 build steps + colour')
PY
echo "STEPS: $(ls steps/*.png | wc -l | tr -d ' ') images"
