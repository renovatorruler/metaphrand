# Scene 8 boards — drawn as CAMERA SETUPS, not stage elevations.
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math, textwrap

W,H = 1000,562
FONT='/Library/Fonts/Arial Unicode.ttf'
SKIN=(244,205,176); SKSH=(220,176,148)
WALL=(178,140,104); WALLD=(146,110,78); WALLL=(198,162,124)
FLOOR=(160,118,80); FLOORD=(126,90,58); FLOORL=(184,142,100)
KERCH=(196,66,50); KERCHD=(158,44,34); KGOLD=(224,180,96)
APRON=(242,233,214); APRSH=(212,200,180)
SKIRT=(152,54,46); BLOUSE=(198,152,98); BRAID=(216,172,104)
VHAIR=(118,82,50); VHAIRD=(92,62,36); FHAIR=(70,50,40); FHAIRL=(98,72,58)
GOLD=(255,196,84); GOLDL=(255,232,164); EYE=(48,36,28)

def blur_paste(d, layer, radius):
    base=d._image.convert('RGBA')
    d._image.paste(Image.alpha_composite(base, layer.filter(ImageFilter.GaussianBlur(radius))).convert('RGB'),(0,0))

def shadow(d,cx,y,w,a=72):
    o=Image.new('RGBA',(W,H),(0,0,0,0)); ImageDraw.Draw(o).ellipse([cx-w,y-w*0.17,cx+w,y+w*0.17],fill=(0,0,0,a))
    blur_paste(d,o,7)

# ---------------------------------------------------------------- backgrounds
def wall_band(d, top, bottom):
    row=0; y=top-70
    while y < bottom:
        off=66 if row%2 else 0
        for i in range(-1,10):
            x=i*132+off
            d.rounded_rectangle([x+5,y+5,x+132,y+78],20,fill=WALL,outline=WALLD,width=4)
            d.arc([x+9,y+9,x+128,y+74],185,320,fill=WALLL,width=3)
        y+=78; row+=1

def floor_persp(d, horizon, vpx, vpy=None, light=False):
    """floor from `horizon` down, planks converging toward vpx"""
    d.rectangle([0,horizon,W,H],fill=FLOORL if light else FLOOR)
    vy = vpy if vpy is not None else horizon-40
    for i in range(-6,18):
        x_bottom=i*150-300
        d.line([(x_bottom,H),(vpx,vy)],fill=FLOORD,width=3)
    # a few cross-boards for depth
    yy=horizon+6; step=8
    while yy<H:
        d.line([(0,yy),(W,yy)],fill=(0,0,0),width=1)
        step*=1.42; yy+=step
    d.line([(0,horizon),(W,horizon)],fill=(92,64,42),width=6)

def lights(d, pts=None, small=False):
    pts = pts or [(-10,40),(150,76),(330,92),(510,88),(690,68),(870,42),(1010,22)]
    for a,b in zip(pts,pts[1:]): d.line([a,b],fill=(56,44,36),width=4)
    cols=[(214,60,50),(66,108,190),(232,182,60),(88,162,84),(214,60,50),(236,236,224),(66,108,190)]
    s=0.6 if small else 1.0
    for (x,y),c in zip(pts,cols):
        d.line([(x,y),(x,y+8*s)],fill=(56,44,36),width=3)
        d.polygon([(x,y+8*s),(x+12*s,y+26*s),(x,y+46*s),(x-12*s,y+26*s)],fill=c)

def room(d, horizon=300, vpx=500, show_lights=True, mat=None, ceiling=False):
    d.rectangle([0,0,W,H],fill=(56,42,32))
    wall_band(d, -40, horizon+4)
    floor_persp(d, horizon, vpx)
    if mat:
        x,y,w2,h2=mat
        d.polygon([(x,y+h2),(x+w2,y+h2),(x+w2-30,y),(x+30,y)],fill=(202,182,148),outline=(166,138,104),width=4)
    if ceiling:
        d.polygon([(0,0),(W,0),(W,64),(0,84)],fill=(38,28,22))
    if show_lights: lights(d)

def space(d, glow=True, floor=False):
    d.rectangle([0,0,W,H],fill=(22,16,12))
    if glow:
        o=Image.new('RGBA',(W,H),(0,0,0,0)); dd=ImageDraw.Draw(o)
        for r,a in [(380,24),(260,32),(150,44)]:
            dd.ellipse([W//2-r,430-r//3,W//2+r,430+r//3],fill=(255,168,58,a))
        blur_paste(d,o,32)
    import random; random.seed(7)
    for _ in range(95):
        x=random.randint(0,W); y=random.randint(0,H); r=random.choice([1,1,2,2,3])
        d.ellipse([x-r,y-r,x+r,y+r],fill=(255,200,110) if r<3 else (255,232,170))

def occluder(d, poly, alpha=225, blur=9, col=(16,12,10)):
    """out-of-focus foreground mass — the thing that puts the camera INSIDE the room"""
    o=Image.new('RGBA',(W,H),(0,0,0,0)); ImageDraw.Draw(o).polygon(poly,fill=col+(alpha,))
    blur_paste(d,o,blur)

# ---------------------------------------------------------------- faces & figures
def face(d,cx,cy,R,brow='norm',m='flat',turn=0.0,tilt=0.0,lid=False,blush=True):
    """turn: -1 (facing screen-left) … +1 (screen-right). 0 = to camera."""
    ox=turn*R*0.30
    ex=R*0.36; ey=cy+R*0.06+tilt*R*0.10; er=R*0.20
    for s in(-1,1):
        px=cx+ox+s*ex*(1-abs(turn)*0.34)
        if abs(turn)>0.75 and s==-int(math.copysign(1,turn)): continue
        if lid:
            d.arc([px-er,ey-er,px+er,ey+er],200,340,fill=EYE,width=max(2,int(R*0.07)))
        else:
            d.ellipse([px-er,ey-er*1.15,px+er,ey+er*1.15],fill=(255,255,255))
            d.ellipse([px-er*0.62+turn*er*0.3,ey-er*0.72,px+er*0.62+turn*er*0.3,ey+er*0.72],fill=EYE)
            d.ellipse([px-er*0.46+turn*er*0.3,ey-er*0.56,px-er*0.08+turn*er*0.3,ey-er*0.16],fill=(255,255,255))
    for s in(-1,1):
        px=cx+ox+s*ex*(1-abs(turn)*0.34)
        if abs(turn)>0.75 and s==-int(math.copysign(1,turn)): continue
        if brow=='huge':
            d.polygon([(px-R*0.30,ey-R*0.36),(px+R*0.30,ey-R*0.42),(px+R*0.28,ey-R*0.16),(px-R*0.28,ey-R*0.12)],fill=(64,44,30))
        elif brow=='norm':
            d.line([(px-R*0.24,ey-R*0.30),(px+R*0.24,ey-R*0.34)],fill=(96,68,46),width=max(3,int(R*0.13)))
        elif brow=='up':
            d.arc([px-R*0.28,ey-R*0.58,px+R*0.28,ey-R*0.06],200,340,fill=(96,68,46),width=max(3,int(R*0.12)))
    if abs(turn)>0.25:   # cheek/jaw line reads the turn
        s=1 if turn>0 else -1
        ax0,ax1=sorted([cx+ox-s*R*0.1, cx+ox+s*R*1.5])
        d.arc([ax0,cy-R*0.5,ax1,cy+R*0.95],(300 if s>0 else 60),(60 if s>0 else 120),fill=SKSH,width=max(2,int(R*0.06)))
    d.ellipse([cx+ox*1.5-R*0.11,cy+R*0.20,cx+ox*1.5+R*0.11,cy+R*0.40],fill=SKSH)
    if blush:
        for s in(-1,1):
            px=cx+ox+s*R*0.60
            d.ellipse([px-R*0.15,cy+R*0.28,px+R*0.15,cy+R*0.44],fill=(238,168,150))
    my=cy+R*0.60; mx=cx+ox*1.4
    if m=='flat': d.line([(mx-R*0.22,my),(mx+R*0.22,my)],fill=(146,86,72),width=max(2,int(R*0.08)))
    elif m=='smile': d.arc([mx-R*0.30,my-R*0.26,mx+R*0.30,my+R*0.24],15,165,fill=(146,86,72),width=max(3,int(R*0.09)))
    elif m=='grin':
        d.chord([mx-R*0.34,my-R*0.30,mx+R*0.34,my+R*0.34],10,170,fill=(122,54,48))
        d.rectangle([mx-R*0.20,my-R*0.14,mx+R*0.20,my-R*0.02],fill=(255,252,244))
    elif m=='o': d.ellipse([mx-R*0.17,my-R*0.20,mx+R*0.17,my+R*0.22],fill=(122,54,48))
    elif m=='yell':
        d.ellipse([mx-R*0.28,my-R*0.30,mx+R*0.28,my+R*0.38],fill=(118,48,42))
        d.rectangle([mx-R*0.18,my-R*0.28,mx+R*0.18,my-R*0.14],fill=(255,252,244))
    elif m=='wail': d.ellipse([mx-R*0.24,my-R*0.24,mx+R*0.24,my+R*0.42],fill=(118,48,42))

def kerchief(d,cx,cy,R,turn=0.0):
    ox=turn*R*0.22
    d.pieslice([cx+ox-R*1.06,cy-R*1.12,cx+ox+R*1.06,cy+R*1.00],184,356,fill=KERCH)
    d.polygon([(cx+ox-R*1.05,cy-R*0.06),(cx+ox+R*1.05,cy-R*0.06),(cx+ox+R*0.96,cy+R*0.16),
               (cx+ox+R*0.4,cy+R*0.02),(cx+ox-R*0.4,cy+R*0.16),(cx+ox-R*0.96,cy+R*0.02)],fill=KERCH)
    for i in(-2,-1,0,1,2):
        d.line([(cx+ox+i*R*0.30,cy-R*0.98+abs(i)*R*0.13),(cx+ox+i*R*0.36,cy+R*0.04)],fill=KGOLD,width=max(2,int(R*0.09)))
    kx=cx+ox-R*1.02 if turn>0 else cx+ox+R*0.86
    d.polygon([(kx,cy-R*0.22),(kx+(0.38*R if turn<=0 else -0.38*R),cy-R*0.44),
               (kx+(0.34*R if turn<=0 else -0.34*R),cy+R*0.10),(kx+(0.04*R if turn<=0 else -0.04*R),cy+R*0.06)],fill=KERCHD)

def mama(d,cx,base,h,brow='norm',arms='down',m='flat',turn=0.0,low=0.0,shad=True):
    """low: 0 = eye level, 1 = strong low angle (head recedes), -1 = high angle (head grows)"""
    s=h/300.0; R=52*s*(1-0.16*low); hy=base-h+R*1.15
    if shad: shadow(d,cx,base+4,58*s*(1+0.2*low))
    hipw=56*s*(1+0.18*low)
    d.polygon([(cx-hipw,base),(cx+hipw,base),(cx+30*s,base-108*s),(cx-30*s,base-108*s)],fill=SKIRT)
    for k in range(1,4):
        d.line([(cx-hipw+k*(hipw/2),base),(cx-30*s+k*15*s,base-104*s)],fill=(132,44,38),width=int(3*s)+1)
    d.rounded_rectangle([cx-32*s,base-176*s,cx+32*s,base-96*s],int(14*s),fill=BLOUSE)
    d.polygon([(cx-30*s,base-2*s),(cx+30*s,base-2*s),(cx+22*s,base-140*s),(cx-22*s,base-140*s)],fill=APRON)
    d.line([(cx-22*s,base-138*s),(cx+22*s,base-138*s)],fill=APRSH,width=int(3*s)+1)
    aw=int(13*s)
    if arms=='down':
        for sd in(-1,1):
            d.line([(cx+sd*30*s,base-160*s),(cx+sd*44*s,base-86*s)],fill=BLOUSE,width=aw)
            d.ellipse([cx+sd*44*s-7*s,base-92*s,cx+sd*44*s+7*s,base-78*s],fill=SKIN)
    elif arms=='up':
        for sd in(-1,1):
            d.line([(cx+sd*30*s,base-160*s),(cx+sd*52*s,base-206*s)],fill=BLOUSE,width=aw)
            d.line([(cx+sd*52*s,base-206*s),(cx+sd*58*s,base-252*s)],fill=SKIN,width=aw)
            d.ellipse([cx+sd*58*s-11*s,base-266*s,cx+sd*58*s+11*s,base-244*s],fill=SKIN)
    elif arms=='brow':
        d.line([(cx-30*s,base-160*s),(cx-42*s,base-88*s)],fill=BLOUSE,width=aw)
        d.ellipse([cx-42*s-7*s,base-94*s,cx-42*s+7*s,base-80*s],fill=SKIN)
        ex_,ey_=cx+58*s, base-192*s
        d.line([(cx+30*s,base-160*s),(ex_,ey_)],fill=BLOUSE,width=aw)
        hx,hy2=cx+turn*R*0.30+R*0.42, hy-R*0.40
        d.line([(ex_,ey_),(hx,hy2)],fill=SKIN,width=aw)
        d.ellipse([hx-12*s,hy2-11*s,hx+12*s,hy2+13*s],fill=SKIN)
    elif arms=='hold':
        for sd in(-1,1):
            d.line([(cx+sd*30*s,base-160*s),(cx+sd*46*s,base-116*s)],fill=BLOUSE,width=aw)
            d.ellipse([cx+sd*46*s-8*s,base-124*s,cx+sd*46*s+8*s,base-108*s],fill=SKIN)
    bs=1 if turn<=0 else -1
    d.line([(cx+bs*R*0.80,hy+R*0.30),(cx+bs*R*1.02,base-150*s)],fill=BRAID,width=int(15*s))
    d.ellipse([cx-R,hy-R,cx+R,hy+R],fill=SKIN)
    d.ellipse([cx-R*0.86,hy+R*0.10,cx+R*0.86,hy+R],fill=SKIN)
    kerchief(d,cx,hy,R,turn)
    face(d,cx,hy,R,brow=brow,m=m,turn=turn)
    return hy,R

def vasya(d,cx,base,h,brow='huge',arms='down',m='flat',turn=0.0,low=0.0,shad=True):
    s=h/240.0; R=48*s*(1-0.16*low); hy=base-h+R*1.10
    if shad: shadow(d,cx,base+3,44*s*(1+0.2*low))
    lw=30*s*(1+0.2*low)
    d.rounded_rectangle([cx-lw,base-92*s,cx-4*s,base],int(9*s),fill=(78,104,152))
    d.rounded_rectangle([cx+4*s,base-92*s,cx+lw,base],int(9*s),fill=(88,116,166))
    d.rounded_rectangle([cx-36*s,base-146*s,cx+36*s,base-78*s],int(12*s),fill=(184,86,72))
    for px,py,c in [(-26,-138,(236,190,66)),(2,-134,(84,152,94)),(-10,-108,(70,124,182)),(16,-104,(214,150,64))]:
        d.rounded_rectangle([cx+px*s,base+py*s,cx+(px+22)*s,base+(py+22)*s],4,fill=c)
    aw=int(12*s)
    if arms=='down':
        for sd in(-1,1):
            d.line([(cx+sd*34*s,base-134*s),(cx+sd*46*s,base-72*s)],fill=SKIN,width=aw)
            d.ellipse([cx+sd*46*s-8*s,base-80*s,cx+sd*46*s+8*s,base-64*s],fill=SKIN)
    elif arms=='up':
        for sd in(-1,1):
            d.line([(cx+sd*34*s,base-134*s),(cx+sd*54*s,base-196*s)],fill=SKIN,width=aw)
            d.ellipse([cx+sd*54*s-11*s,base-210*s,cx+sd*54*s+11*s,base-188*s],fill=SKIN)
    elif arms=='hold':
        for sd in(-1,1):
            d.line([(cx+sd*34*s,base-134*s),(cx+sd*30*s,base-96*s)],fill=SKIN,width=aw)
            d.ellipse([cx+sd*30*s-9*s,base-104*s,cx+sd*30*s+9*s,base-88*s],fill=SKIN)
    d.ellipse([cx-R,hy-R,cx+R,hy+R],fill=SKIN)
    d.ellipse([cx-R*0.86,hy+R*0.10,cx+R*0.86,hy+R],fill=SKIN)
    ox=turn*R*0.22
    d.pieslice([cx+ox-R*1.02,hy-R*1.06,cx+ox+R*1.02,hy+R*0.50],186,354,fill=VHAIR)
    for i in range(7):
        x=cx+ox-R*0.92+i*R*0.30
        d.polygon([(x,hy-R*0.52),(x+R*0.16,hy-R*1.30),(x+R*0.30,hy-R*0.52)],fill=VHAIR if i%2 else VHAIRD)
    for sd in(-1,1):
        d.ellipse([cx+sd*R*1.02-R*0.17,hy-R*0.10,cx+sd*R*1.02+R*0.17,hy+R*0.30],fill=SKIN)
    face(d,cx,hy,R,brow=brow,m=m,turn=turn)
    return hy,R

def frosya(d,cx,base,h,m='smile',turn=0.0,bent=False,shad=True):
    s=h/240.0; R=46*s; hy=base-h+R*1.10
    if bent: hy=base-h*0.66
    if shad: shadow(d,cx,base+3,44*s)
    d.polygon([(cx-46*s,base),(cx+46*s,base),(cx+28*s,base-106*s),(cx-28*s,base-106*s)],fill=(92,158,150))
    import random; random.seed(3)
    for _ in range(14):
        fx=cx+random.uniform(-40,40)*s; fy=base-random.uniform(6,100)*s
        d.ellipse([fx-5*s,fy-5*s,fx+5*s,fy+5*s],fill=random.choice([(238,132,150),(250,214,120),(240,246,238)]))
    for sd in(-1,1):
        d.line([(cx+sd*28*s,base-100*s),(cx+sd*42*s,base-44*s)],fill=SKIN,width=int(11*s))
        d.ellipse([cx+sd*42*s-8*s,base-52*s,cx+sd*42*s+8*s,base-36*s],fill=SKIN)
    ox=turn*R*0.20
    d.ellipse([cx+ox-R*1.46,hy-R*1.28,cx+ox+R*1.46,hy+R*1.20],fill=FHAIR)
    for a in range(0,360,32):
        rx=cx+ox+math.cos(math.radians(a))*R*1.24; ry=hy+math.sin(math.radians(a))*R*1.06
        d.ellipse([rx-R*0.28,ry-R*0.28,rx+R*0.28,ry+R*0.28],fill=FHAIR if a%64 else FHAIRL)
    d.ellipse([cx-R,hy-R*0.94,cx+R,hy+R],fill=SKIN)
    fx0=cx+ox+(R*0.98 if turn<=0 else -R*0.98)
    for pt in range(5):
        ang=math.radians(72*pt-90)
        d.ellipse([fx0+math.cos(ang)*R*0.20-R*0.15,hy-R*0.72+math.sin(ang)*R*0.20-R*0.15,
                   fx0+math.cos(ang)*R*0.20+R*0.15,hy-R*0.72+math.sin(ang)*R*0.20+R*0.15],fill=(238,142,52))
    face(d,cx,hy,R,m=m,turn=turn)
    return hy,R

def baby(d,cx,base,h,kind='rus',pose='crawl',m='smile',turn=0.0,shad=True):
    s=h/120.0; R=30*s
    body=(216,176,116) if kind=='rus' else (238,182,192)
    if shad: shadow(d,cx,base+2,34*s,a=60)
    if pose=='crawl':
        d.rounded_rectangle([cx-36*s,base-38*s,cx+30*s,base-4*s],int(15*s),fill=body)
        for dx in(-26,-4,18): d.line([(cx+dx*s,base-10*s),(cx+dx*s-4*s,base)],fill=SKIN,width=int(8*s))
        hx=cx+40*s; hy=base-40*s
    elif pose=='toward':      # crawling straight at camera
        d.ellipse([cx-30*s,base-44*s,cx+30*s,base+2*s],fill=body)
        for sd in(-1,1):
            d.line([(cx+sd*22*s,base-30*s),(cx+sd*36*s,base-2*s)],fill=SKIN,width=int(10*s))
            d.ellipse([cx+sd*36*s-9*s,base-10*s,cx+sd*36*s+9*s,base+8*s],fill=SKIN)
        hx=cx; hy=base-44*s-R*0.55
    elif pose=='sit':
        d.rounded_rectangle([cx-26*s,base-46*s,cx+26*s,base],int(16*s),fill=body)
        for sd in(-1,1): d.line([(cx+sd*20*s,base-8*s),(cx+sd*36*s,base-2*s)],fill=SKIN,width=int(9*s))
        hx=cx; hy=base-46*s-R*0.75
    else:                      # climb
        d.rounded_rectangle([cx-24*s,base-52*s,cx+24*s,base-6*s],int(14*s),fill=body)
        d.line([(cx-18*s,base-44*s),(cx-40*s,base-72*s)],fill=SKIN,width=int(9*s))
        d.ellipse([cx-48*s,base-82*s,cx-32*s,base-64*s],fill=SKIN)
        hx=cx; hy=base-52*s-R*0.75
    d.ellipse([hx-R,hy-R,hx+R,hy+R],fill=SKIN)
    if kind=='rus': d.polygon([(hx-8*s,hy-R*0.92),(hx+6*s,hy-R*1.60),(hx+16*s,hy-R*0.86)],fill=(200,116,54))
    else: d.arc([hx-R*0.5,hy-R*1.32,hx+R*0.62,hy-R*0.42],195,345,fill=(126,94,72),width=int(5*s))
    face(d,hx,hy,R,brow='none',m=m,turn=turn)

# ---------------------------------------------------------------- annotations
def slate(d,txt):
    f=ImageFont.truetype(FONT,23); tw=d.textlength(txt,font=f)
    d.rounded_rectangle([14,14,14+tw+24,52],8,fill=(0,0,0))
    d.text((26,20),txt,font=f,fill=(255,222,146))

def bubble(d,x,y,txt,size=25):
    f=ImageFont.truetype(FONT,size); tw=d.textlength(txt,font=f)
    d.rounded_rectangle([x-12,y-10,x+tw+12,y+size+14],11,fill=(250,246,234),outline=(110,86,64),width=3)
    d.polygon([(x+18,y+size+12),(x+34,y+size+12),(x+20,y+size+30)],fill=(250,246,234),outline=(110,86,64))
    d.text((x,y),txt,font=f,fill=(58,42,32))

def arrow(d,p0,p1,col=(255,214,96),w=7):
    d.line([p0,p1],fill=col,width=w)
    a=math.atan2(p1[1]-p0[1],p1[0]-p0[0])
    for da in(2.6,-2.6):
        d.line([p1,(p1[0]-24*math.cos(a+da),p1[1]-24*math.sin(a+da))],fill=col,width=w)

def plan(d, dots, cam, note='', box=(W-236,H-176,W-14,H-14)):
    """top-down camera plan, fully clipped to its own box"""
    x0,y0,x1,y1=box
    o=Image.new('RGBA',(W,H),(0,0,0,0)); ImageDraw.Draw(o).rounded_rectangle([x0,y0,x1,y1],10,fill=(10,8,7,225))
    d._image.paste(Image.alpha_composite(d._image.convert('RGBA'),o).convert('RGB'),(0,0))
    d.rounded_rectangle([x0,y0,x1,y1],10,outline=(122,102,80),width=2)
    f=ImageFont.truetype(FONT,13)
    d.text((x0+10,y0+7),'ПЛАН СВЕРХУ',font=f,fill=(150,132,108))
    ix0,iy0,ix1,iy1=x0+14,y0+28,x1-14,y1-12
    iw,ih=int(ix1-ix0),int(iy1-iy0)
    inner=Image.new('RGBA',(iw,ih),(28,22,18,255)); di=ImageDraw.Draw(inner)
    for i in range(1,4): di.line([(0,ih*i/4),(iw,ih*i/4)],fill=(44,36,30),width=1)
    di.line([(0,1),(iw,1)],fill=(80,66,52),width=2)          # the wall the camera faces
    def P(px,py): return (iw*px, ih*py)
    cxp,cyp=P(cam[0],cam[1]); ang=math.radians(cam[2]); fov=math.radians(30)
    wedge=Image.new('RGBA',(iw,ih),(0,0,0,0))
    ImageDraw.Draw(wedge).polygon([(cxp,cyp),
        (cxp+math.cos(ang-fov)*400,cyp+math.sin(ang-fov)*400),
        (cxp+math.cos(ang+fov)*400,cyp+math.sin(ang+fov)*400)],fill=(255,200,90,60))
    inner=Image.alpha_composite(inner,wedge)
    di=ImageDraw.Draw(inner)
    for px,py,col,lab in dots:
        dx,dy=P(px,py)
        di.ellipse([dx-6,dy-6,dx+6,dy+6],fill=col,outline=(20,16,12))
        di.text((dx+9,dy-8),lab,font=ImageFont.truetype(FONT,12),fill=(212,198,176))
    di.polygon([(cxp-7,cyp-7),(cxp+7,cyp-7),(cxp+7,cyp+7),(cxp-7,cyp+7)],fill=(255,206,110))
    di.polygon([(cxp+math.cos(ang)*8-5,cyp+math.sin(ang)*8-5),(cxp+math.cos(ang)*22,cyp+math.sin(ang)*22),
                (cxp+math.cos(ang)*8+5,cyp+math.sin(ang)*8+5)],fill=(255,206,110))
    d._image.paste(inner.convert('RGB'),(int(ix0),int(iy0)))
    d.rectangle([ix0,iy0,ix1,iy1],outline=(74,62,50),width=2)

def back_of_head(d,cx,cy,R,kind='mama'):
    """foreground OTS mass — we are behind this person, so no face"""
    d.ellipse([cx-R,cy-R,cx+R,cy+R],fill=(58,40,32))
    if kind=='mama':
        d.pieslice([cx-R*1.06,cy-R*1.12,cx+R*1.06,cy+R*1.00],184,356,fill=(128,42,32))
        d.polygon([(cx-R*1.05,cy-R*0.06),(cx+R*1.05,cy-R*0.06),(cx+R*0.9,cy+R*0.22),
                   (cx,cy+R*0.06),(cx-R*0.9,cy+R*0.22)],fill=(128,42,32))
        for i in(-2,-1,0,1,2):
            d.line([(cx+i*R*0.30,cy-R*0.98+abs(i)*R*0.13),(cx+i*R*0.36,cy+R*0.06)],fill=(150,118,62),width=max(2,int(R*0.09)))
        d.line([(cx+R*0.5,cy+R*0.6),(cx+R*0.9,cy+R*2.2)],fill=(150,116,68),width=int(R*0.30))
    else:
        d.pieslice([cx-R*1.02,cy-R*1.06,cx+R*1.02,cy+R*0.50],186,354,fill=(74,50,30))
        for i in range(7):
            x=cx-R*0.92+i*R*0.30
            d.polygon([(x,cy-R*0.52),(x+R*0.16,cy-R*1.30),(x+R*0.30,cy-R*0.52)],fill=(74,50,30))

# ---------------------------------------------------------------- the rest of the family
PAPA_W=(126,92,58); PAPA_D=(98,70,42); MOSS=(96,118,72)
YAGA_D=(96,54,52); YAGA_S=(214,206,196); YAGA_K=(150,58,52)

def papa(d,cx,base,h,pose='sit',m='grin',turn=0.0,shad=True):
    """biggest in the room by a head; chunky knit, moss patches, huge brows"""
    s=h/300.0; R=54*s; hy=base-h+R*1.15
    if shad: shadow(d,cx,base+4,68*s)
    if pose=='sit':
        d.rounded_rectangle([cx-56*s,base-118*s,cx+56*s,base],int(18*s),fill=PAPA_W)
        d.rounded_rectangle([cx-58*s,base-206*s,cx+58*s,base-104*s],int(20*s),fill=PAPA_W)
    else:
        d.rounded_rectangle([cx-40*s,base-116*s,cx+40*s,base],int(14*s),fill=PAPA_D)
        d.rounded_rectangle([cx-58*s,base-212*s,cx+58*s,base-104*s],int(20*s),fill=PAPA_W)
    for px,py in [(-40,-190),(18,-166),(-16,-134)]:
        d.rounded_rectangle([cx+px*s,base+py*s,cx+(px+30)*s,base+(py+26)*s],6,fill=MOSS)
    for k in range(-4,5):
        d.line([(cx+k*13*s,base-206*s),(cx+k*13*s,base-104*s)],fill=PAPA_D,width=max(1,int(2*s)))
    aw=int(17*s)
    if pose=='sit':
        d.line([(cx-52*s,base-176*s),(cx-72*s,base-118*s)],fill=PAPA_W,width=aw)
        d.ellipse([cx-82*s,base-130*s,cx-62*s,base-110*s],fill=SKIN)
        d.line([(cx+52*s,base-176*s),(cx+74*s,base-146*s)],fill=PAPA_W,width=aw)
        d.ellipse([cx+66*s,base-158*s,cx+88*s,base-136*s],fill=SKIN)
        d.ellipse([cx+70*s,base-176*s,cx+92*s,base-154*s],fill=(224,224,230),outline=(150,150,160),width=2)
    else:
        for sd in(-1,1):
            d.line([(cx+sd*52*s,base-176*s),(cx+sd*72*s,base-108*s)],fill=PAPA_W,width=aw)
            d.ellipse([cx+sd*72*s-10*s,base-118*s,cx+sd*72*s+10*s,base-98*s],fill=SKIN)
    d.ellipse([cx-R,hy-R,cx+R,hy+R],fill=SKIN)
    d.ellipse([cx-R*0.88,hy+R*0.10,cx+R*0.88,hy+R],fill=SKIN)
    ox=turn*R*0.20
    d.pieslice([cx+ox-R*1.04,hy-R*1.08,cx+ox+R*1.04,hy+R*0.44],186,354,fill=PAPA_D)
    for i in range(5):
        x=cx+ox-R*0.8+i*R*0.4
        d.polygon([(x,hy-R*0.60),(x+R*0.18,hy-R*1.24),(x+R*0.34,hy-R*0.58)],fill=PAPA_D)
    face(d,cx,hy,R,brow='huge',m=m,turn=turn)
    return hy,R

def yaga(d,cx,base,h,pose='sit',m='smile',turn=0.0,shad=True):
    """small, hunched, sly; dark kerchief, sharp chin, she is pleased with herself"""
    s=h/250.0; R=44*s; hy=base-h+R*1.30
    if shad: shadow(d,cx,base+3,46*s)
    d.polygon([(cx-48*s,base),(cx+48*s,base),(cx+26*s,base-96*s),(cx-26*s,base-96*s)],fill=YAGA_D)
    d.rounded_rectangle([cx-30*s,base-166*s,cx+30*s,base-88*s],int(14*s),fill=(120,86,74))
    d.polygon([(cx-28*s,base-150*s),(cx+28*s,base-150*s),(cx+34*s,base-96*s),(cx-34*s,base-96*s)],fill=(168,140,120))
    aw=int(11*s)
    if pose=='sit':
        d.line([(cx-28*s,base-150*s),(cx-48*s,base-104*s)],fill=(120,86,74),width=aw)
        d.ellipse([cx-58*s,base-114*s,cx-40*s,base-96*s],fill=SKIN)
        d.line([(cx+28*s,base-150*s),(cx+52*s,base-128*s)],fill=(120,86,74),width=aw)
        d.ellipse([cx+44*s,base-140*s,cx+64*s,base-120*s],fill=SKIN)
    else:
        d.line([(cx-28*s,base-150*s),(cx-44*s,base-90*s)],fill=(120,86,74),width=aw)
        d.line([(cx+28*s,base-150*s),(cx+46*s,base-96*s)],fill=(120,86,74),width=aw)
        d.line([(cx+52*s,base-190*s),(cx+58*s,base+4*s)],fill=(104,76,50),width=int(7*s))  # her stick
    d.ellipse([cx-R,hy-R,cx+R,hy+R],fill=SKIN)
    d.ellipse([cx-R*0.80,hy+R*0.16,cx+R*0.80,hy+R*1.02],fill=SKIN)
    ox=turn*R*0.22
    d.pieslice([cx+ox-R*1.12,hy-R*1.18,cx+ox+R*1.12,hy+R*0.52],184,356,fill=YAGA_K)
    d.polygon([(cx+ox-R*1.10,hy-R*0.42),(cx+ox+R*1.10,hy-R*0.42),(cx+ox+R*1.02,hy+R*0.30),
               (cx+ox+R*0.72,hy-R*0.16),(cx+ox-R*0.72,hy-R*0.16),(cx+ox-R*1.02,hy+R*0.30)],fill=YAGA_K)
    for sd in(-1,1):
        d.ellipse([cx+ox+sd*R*0.86-R*0.14,hy-R*0.30,cx+ox+sd*R*0.86+R*0.14,hy+R*0.06],fill=YAGA_S)
    d.polygon([(cx+ox-R*0.16,hy+R*0.06),(cx+ox+R*0.30,hy+R*0.24),(cx+ox-R*0.10,hy+R*0.34)],fill=SKSH)
    for sd in(-1,1):
        px=cx+ox+sd*R*0.40*(1-abs(turn)*0.3)
        d.arc([px-R*0.20,hy-R*0.10,px+R*0.20,hy+R*0.22],200,340,fill=EYE,width=max(2,int(R*0.09)))
        d.line([(px-R*0.20,hy-R*0.22),(px+R*0.20,hy-R*0.28)],fill=(120,110,100),width=max(2,int(R*0.07)))
    my=hy+R*0.62; mx=cx+ox*1.3
    if m=='smile': d.arc([mx-R*0.28,my-R*0.30,mx+R*0.28,my+R*0.20],15,165,fill=(140,84,74),width=max(3,int(R*0.09)))
    elif m=='grin':
        d.chord([mx-R*0.30,my-R*0.30,mx+R*0.30,my+R*0.28],10,170,fill=(118,52,46))
    else: d.line([(mx-R*0.20,my),(mx+R*0.20,my)],fill=(140,84,74),width=max(2,int(R*0.08)))
    return hy,R

def tea_table(d, cx, base, w, who=('papa','yaga'), mama_at=None, cups=True, scale=1.0):
    """the party table the whole scene happens in front of"""
    h=int(46*scale)
    d.polygon([(cx-w,base),(cx+w,base),(cx+w*0.86,base+h),(cx-w*0.86,base+h)],fill=(150,108,70),outline=(112,80,52),width=max(2,int(4*scale)))
    for sd in(-1,1):
        d.rounded_rectangle([cx+sd*w*0.62,base+h,cx+sd*w*0.62+16*scale,base+h+52*scale],4,fill=(120,86,56))
    if cups:
        for i,dx in enumerate((-0.55,-0.18,0.26,0.62)):
            x=cx+w*dx
            d.ellipse([x-13*scale,base-16*scale,x+13*scale,base+6*scale],fill=(226,226,232),outline=(150,150,160),width=max(1,int(2*scale)))
        d.ellipse([cx-w*0.06-26*scale,base-22*scale,cx-w*0.06+26*scale,base+8*scale],fill=(214,168,96),outline=(170,124,64),width=max(1,int(2*scale)))
