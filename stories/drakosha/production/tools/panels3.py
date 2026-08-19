import sys; sys.path.insert(0,'/tmp/sb8')
from draw import *
from PIL import Image, ImageDraw, ImageFont
import textwrap, math, random

P={}
def new():
    im=Image.new('RGB',(W,H)); d=ImageDraw.Draw(im); d._image=im; return im,d
MAMA_C=(214,84,70); VAS_C=(96,150,220); FRO_C=(96,190,176); BAB_C=(238,196,120)
PAPA_C=(150,116,70); YAGA_C=(196,96,92); TILE=(228,206,166); TILE_E=(154,124,88)

def tile(d,x,y,s,ch=None,lit=False,rot=0.0):
    c=math.cos(rot); si=math.sin(rot)
    pts=[(-s*0.62,-s*0.52),(s*0.62,-s*0.52),(s*0.62,s*0.52),(-s*0.62,s*0.52)]
    pts=[(x+px*c-py*si, y+px*si+py*c) for px,py in pts]
    if lit:
        o=Image.new('RGBA',(W,H),(0,0,0,0)); ImageDraw.Draw(o).ellipse([x-s*1.5,y-s*1.5,x+s*1.5,y+s*1.5],fill=(255,180,60,120))
        blur_paste(d,o,22)
    d.polygon(pts,fill=(255,238,186) if lit else TILE,outline=(214,138,44) if lit else TILE_E,width=max(2,int(s*0.06)))
    if ch: d.text((x,y),ch,font=ImageFont.truetype(FONT,int(s*0.62)),
                  fill=(206,116,26) if lit else (124,90,58),anchor='mm')

def stove_back(d, cx, base, r):
    """the back of the giants' stove — the plate behind Фрося where she sits"""
    d.pieslice([cx-r,base-r*1.5,cx+r,base+r*0.7],180,360,fill=(150,86,64),outline=(112,62,46),width=6)
    d.rectangle([cx-r,base-r*0.4,cx+r,base],fill=(150,86,64),outline=(112,62,46),width=6)
    for row in range(5):
        y=base-r*0.34-row*r*0.20
        off=(row%2)*r*0.16
        for i in range(-5,6):
            x=cx+i*r*0.32+off
            if (x-cx)**2/(r*r)+((y-base+r*0.4)**2)/((r*1.1)**2) < 1.05:
                d.rounded_rectangle([x,y,x+r*0.28,y+r*0.16],4,outline=(112,62,46),width=3)
    d.arc([cx-r*0.98,base-r*1.46,cx+r*0.98,base+r*0.66],184,356,fill=(184,120,92),width=5)
    for i,(sx,sy) in enumerate([(-0.55,-0.86),(0.12,-1.02),(0.62,-0.72)]):
        d.ellipse([cx+sx*r-r*0.05,base+sy*r-r*0.05,cx+sx*r+r*0.05,base+sy*r+r*0.05],fill=(96,52,40))

def hand_from_edge(d, x, y, s, side='right', holding=None):
    """a child's hand entering frame — the thing that says 'we are inside this'"""
    sd=1 if side=='right' else -1
    d.line([(x+sd*s*3.0,y+s*0.7),(x,y)],fill=SKIN,width=int(s*0.80))
    d.ellipse([x-s*0.62,y-s*0.58,x+s*0.62,y+s*0.62],fill=SKIN)
    for i in range(4):
        a=math.radians(-60+ i*34)*(-sd if sd<0 else 1)
        fx=x-sd*s*0.30+math.cos(a)*s*0.66; fy=y+math.sin(a)*s*0.66
        d.ellipse([fx-s*0.19,fy-s*0.19,fx+s*0.19,fy+s*0.19],fill=SKIN)
    d.ellipse([x-s*0.60,y-s*0.52,x+s*0.10,y+s*0.10],fill=(250,214,188))

# ---------------- 1 · knees + tiles, "что можно сделать?"
im,d=new()
d.rectangle([0,0,W,H],fill=(152,112,76))
for i in range(10): d.line([(0,i*66-24),(W,i*66+8)],fill=FLOORD,width=4)
d.polygon([(70,150),(890,86),(966,458),(126,548)],fill=(202,182,148),outline=(166,138,104),width=5)
random.seed(21)
letters='АОМСКТЛБ'
for i in range(14):
    x=random.uniform(210,700); y=random.uniform(210,430)
    tile(d,x,y,84,ch=letters[i%8],rot=random.uniform(-0.55,0.55))
d.ellipse([560,90,800,250],fill=(150,112,74),outline=(112,80,52),width=5)   # the pouch
d.polygon([(690,0),(1010,0),(1010,190),(760,140)],fill=SKIN)                # Вася's knee, top-right
d.polygon([(0,430),(300,510),(230,H),(0,H)],fill=(92,158,150))              # Фрося's knee, bottom-left
d.polygon([(0,470),(240,536),(196,H),(0,H)],fill=(78,138,132))
slate(d,'1 · СВЕРХУ · колени по диагонали, фишки между ними')
plan(d,[(0.30,0.70,FRO_C,'Фрося'),(0.70,0.28,VAS_C,'Вася')],(0.50,0.50,-90))
P['S1']=im

# ---------------- 2 · her hand builds СОК out of tiles
im,d=new()
d.rectangle([0,0,W,H],fill=(150,110,74))
for i in range(9): d.line([(0,i*72-16),(W,i*72+14)],fill=FLOORD,width=4)
d.polygon([(20,120),(940,70),(990,470),(60,530)],fill=(202,182,148),outline=(166,138,104),width=5)
for i,ch in enumerate('СО'):
    tile(d,286+i*150,318,118,ch=ch,rot=0.04*(1 if i%2 else -1))
tile(d,592,300,118,ch='К',rot=-0.22)
for x,y,ch,r in [(806,196,'Т',0.4),(880,398,'Б',-0.3),(180,180,'А',0.2),(700,470,'М',0.5)]:
    tile(d,x,y,84,ch=ch,rot=r)
hand_from_edge(d,610,286,96,side='right')
arrow(d,(700,150),(624,244),col=(255,214,96),w=6)
slate(d,'2 · КРУПНО СВЕРХУ · её рука складывает СОК из фишек')
plan(d,[(0.42,0.56,FRO_C,'Фрося')],(0.44,0.50,-90))
P['S2']=im

# ---------------- 3 · Фрося large, seated, writing; stove back behind her
im,d=new()
d.rectangle([0,0,W,H],fill=(46,34,26))
stove_back(d,470,352,430)
floor_persp(d,352,470)
o=Image.new('RGBA',(W,H),(0,0,0,0)); ImageDraw.Draw(o).ellipse([470-300,120,470+300,420],fill=(255,190,110,40))
blur_paste(d,o,50)
s=1.0
cx,base,h=430,556,392
R=46*(h/240.0)
d.polygon([(cx-160,base),(cx+150,base),(cx+96,base-190),(cx-96,base-206)],fill=(92,158,150))
random.seed(4)
for _ in range(20):
    fx=cx+random.uniform(-130,120); fy=base-random.uniform(10,190)
    d.ellipse([fx-7,fy-7,fx+7,fy+7],fill=random.choice([(238,132,150),(250,214,120),(240,246,238)]))
d.line([(cx-84,base-30),(cx-186,base-6)],fill=SKIN,width=30)   # folded legs
d.ellipse([cx-214,base-26,cx-166,base+16],fill=SKIN)
hy=base-h+R*1.05
d.line([(cx+70,base-186),(cx+150,base-96)],fill=SKIN,width=27)  # writing arm, going DOWN out of sight
d.ellipse([cx+134,base-116,cx+186,base-64],fill=SKIN)
d.ellipse([cx-R*1.46,hy-R*1.30,cx+R*1.46,hy+R*1.20],fill=FHAIR)
for a in range(0,360,30):
    rx=cx+math.cos(math.radians(a))*R*1.26; ry=hy+math.sin(math.radians(a))*R*1.08
    d.ellipse([rx-R*0.30,ry-R*0.30,rx+R*0.30,ry+R*0.30],fill=FHAIR if a%60 else FHAIRL)
d.ellipse([cx-R,hy-R*0.94,cx+R,hy+R],fill=SKIN)
for pt in range(5):
    ang=math.radians(72*pt-90)
    d.ellipse([cx+R*0.98+math.cos(ang)*R*0.20-R*0.15,hy-R*0.74+math.sin(ang)*R*0.20-R*0.15,
               cx+R*0.98+math.cos(ang)*R*0.20+R*0.15,hy-R*0.74+math.sin(ang)*R*0.20+R*0.15],fill=(238,142,52))
face(d,cx,hy,R,m='flat',turn=0.45,tilt=0.5,lid=True)
d.polygon([(cx+96,base-70),(cx+300,base-40),(cx+300,base+30),(cx+80,base+10)],fill=(214,196,164))
occluder(d,[(cx+60,base+60),(cx+340,base+40),(cx+360,H+60),(cx+40,H+60)],alpha=200,blur=10)
slate(d,'3 · ОНА КРУПНО, СИДИТ · бумаги НЕ видно · за ней ЗАДНЯЯ СТЕНКА ПЕЧКИ')
plan(d,[(0.46,0.54,FRO_C,'Фрося'),(0.46,0.16,(150,86,64),'печка')],(0.30,0.88,-64))
P['S3']=im

# ---------------- 4 · overhead on the paper, СОК lit, точка going down
im,d=new()
d.rectangle([0,0,W,H],fill=(126,90,60))
for i in range(9): d.line([(0,i*72-30),(W,i*72)],fill=(104,72,46),width=4)
d.polygon([(96,86),(906,120),(936,506),(66,470)],fill=(236,218,186),outline=(198,180,150),width=4)
for i,ch in enumerate('СОК'):
    x=250+i*180
    o=Image.new('RGBA',(W,H),(0,0,0,0)); ImageDraw.Draw(o).ellipse([x-116,286-116,x+116,286+116],fill=(255,182,60,132))
    blur_paste(d,o,26)
    d.text((x,286),ch,font=ImageFont.truetype(FONT,138),fill=(214,124,26),anchor='mm')
px,py=736,330
o=Image.new('RGBA',(W,H),(0,0,0,0)); ImageDraw.Draw(o).ellipse([px-70,py-70,px+70,py+70],fill=(255,200,90,140))
blur_paste(d,o,18)
d.ellipse([px-19,py-19,px+19,py+19],fill=(206,116,26))
d.polygon([(px+14,py-34),(px+150,py-186),(px+206,py-140),(px+56,py-6)],fill=(220,164,86),outline=(154,108,62),width=5)
d.polygon([(px+14,py-34),(px-16,py-16),(px+34,py+8)],fill=(72,58,48))
d.ellipse([px+150,py-230,px+272,py-114],fill=SKIN,outline=(216,166,136),width=4)
arrow(d,(px+40,py-150),(px+18,py-62),col=(255,222,146),w=6)
slate(d,'4 · СВЕРХУ · С-О-К вспыхивают · «Точка!» — карандаш ставит точку')
plan(d,[(0.46,0.52,FRO_C,'Фрося')],(0.46,0.52,-90))
P['S4']=im

# ---------------- 5 · glow passes over Вася's face
im,d=new(); room(d,horizon=170,vpx=300,show_lights=False)
o=Image.new('RGBA',(W,H),(0,0,0,0)); ImageDraw.Draw(o).polygon([(60,0),(520,0),(660,H),(200,H)],fill=(255,196,90,120))
blur_paste(d,o,44)
vasya(d,470,H+220,700,m='o',arms='down',brow='huge',turn=-0.25,low=0.6,shad=False)
o=Image.new('RGBA',(W,H),(0,0,0,0)); ImageDraw.Draw(o).polygon([(120,0),(430,0),(560,H),(250,H)],fill=(255,214,130,86))
blur_paste(d,o,30)
arrow(d,(150,64),(392,120),col=(255,222,146),w=6)
slate(d,'5 · КРУПНО · по лицу ПРОХОДИТ отсвет магии — самой магии не видно')
plan(d,[(0.50,0.44,VAS_C,'Вася'),(0.26,0.30,FRO_C,'Фрося (вне кадра)')],(0.46,0.88,-84))
P['S5']=im

# ---------------- 6 · back of his head huge, Фрося offering
im,d=new(); room(d,horizon=272,vpx=700)
party_bg=None
frosya(d,606,514,300,m='grin',turn=-0.55)
d.line([(536,404),(452,436)],fill=SKIN,width=19)
d.polygon([(408,406),(468,406),(458,468),(418,468)],fill=(214,214,220),outline=(132,132,142),width=4)
d.ellipse([404,394,472,420],fill=(240,152,60),outline=(196,116,40),width=3)
occluder(d,[(-70,H+70),(-70,300),(140,214),(346,300),(376,H+70)],alpha=246,blur=7)
back_of_head(d,146,220,152,kind='vasya')
bubble(d,470,86,'Соку хочешь?',25)
slate(d,'6 · ЧЕРЕЗ ЕГО ЗАТЫЛОК · она радостно протягивает напёрсток')
plan(d,[(0.26,0.72,VAS_C,'Вася'),(0.62,0.42,FRO_C,'Фрося')],(0.18,0.86,-46))
P['S6']=im

# ---------------- 7 · his eye through the juice
im,d=new(); room(d,horizon=140,vpx=300,show_lights=False)
vasya(d,430,H+300,860,m='flat',arms='down',brow='huge',turn=-0.15,low=0.7,shad=False)
gx,gy,gr=612,236,148
d.line([(gx+40,gy+150),(gx+150,gy+330)],fill=SKIN,width=52)
d.polygon([(gx-gr*0.86,gy-gr*0.92),(gx+gr*0.86,gy-gr*0.92),(gx+gr*0.68,gy+gr*1.02),(gx-gr*0.68,gy+gr*1.02)],
          fill=(226,226,234),outline=(140,140,152),width=6)
o=Image.new('RGBA',(W,H),(0,0,0,0))
ImageDraw.Draw(o).ellipse([gx-gr*0.82,gy-gr*0.86,gx+gr*0.82,gy+gr*0.36],fill=(244,158,58,236))
blur_paste(d,o,2)
d.ellipse([gx-gr*0.82,gy-gr*0.86,gx+gr*0.82,gy-gr*0.62],fill=(252,190,96))
d.ellipse([gx-gr*0.52,gy-gr*0.52,gx+gr*0.52,gy+gr*0.16],fill=(255,255,255))
d.ellipse([gx-gr*0.30,gy-gr*0.42,gx+gr*0.30,gy+gr*0.06],fill=(52,40,30))
d.ellipse([gx-gr*0.20,gy-gr*0.34,gx-gr*0.02,gy-gr*0.14],fill=(255,255,255))
for fx,fy,fr in [(gx-gr*0.5,gy+gr*0.62,10),(gx+gr*0.2,gy+gr*0.72,7),(gx+gr*0.48,gy+gr*0.5,9)]:
    d.ellipse([fx-fr,fy-fr,fx+fr,fy+fr],fill=(255,206,120))
for i in range(4):
    d.ellipse([gx-gr*0.9+i*10,gy+gr*1.02+i*3,gx-gr*0.9+i*10+16,gy+gr*1.02+i*3+10],fill=SKIN)
bubble(d,72,60,'Ты теперь так ВСЕГДА можешь?',22)
slate(d,'7 · КРУПНО · смотрит СКВОЗЬ сок — глаз преломляется в напёрстке')
plan(d,[(0.48,0.44,VAS_C,'Вася')],(0.46,0.88,-84))
P['S7']=im

# ================= compose =================
F_T=ImageFont.truetype(FONT,22); F_N=ImageFont.truetype(FONT,16)
F_H=ImageFont.truetype(FONT,32); F_S=ImageFont.truetype(FONT,15)
INK=(236,229,216); DIM=(172,162,146); ACC=(226,116,92); BG=(24,21,18)
PW,IH,NH,GAP,COLS=660,372,150,14,2

def np_(key,title,note,badge):
    p=Image.new('RGB',(PW,IH+NH),(30,26,22)); p.paste(P[key].resize((PW,IH)),(0,0))
    d=ImageDraw.Draw(p)
    d.text((12,IH+9),title,font=F_T,fill=INK)
    bw=d.textlength(badge,font=F_S)+18
    d.rounded_rectangle([PW-bw-10,IH+9,PW-10,IH+33],4,outline=ACC,width=1)
    d.text((PW-bw-1,IH+13),badge,font=F_S,fill=ACC)
    y=IH+42
    for ln in textwrap.wrap(note,width=76)[:6]:
        d.text((12,y),ln,font=F_N,fill=DIM); y+=19
    return p

def board(title,sub,items,out):
    rows=(len(items)+COLS-1)//COLS
    lines=textwrap.wrap(sub,width=130)
    head=62+len(lines)*19+16
    Wb=COLS*PW+(COLS+1)*GAP; Hb=head+10+rows*(IH+NH+GAP)
    b=Image.new('RGB',(Wb,Hb),BG); d=ImageDraw.Draw(b)
    d.text((GAP+2,18),title,font=F_H,fill=INK)
    y=62
    for ln in lines: d.text((GAP+2,y),ln,font=F_N,fill=DIM); y+=19
    for i,p in enumerate(items):
        x=GAP+(i%COLS)*(PW+GAP); yy=head+(i//COLS)*(IH+NH+GAP)
        b.paste(p,(x,yy)); d.rectangle([x-1,yy-1,x+PW,yy+IH+NH],outline=(64,55,46))
    b.save(out,quality=93); print(out,b.size)

S=[np_('S1','1 · «Что можно сделать?»','Сверху: колени по диагонали друг от друга, между ними рассыпаны ФИШКИ — те самые восемь букв. Дети пробуют, что вообще из них складывается. Колени в кадре = это ПОЛ.','mini · GEN ~5s'),
   np_('S2','2 · Она складывает СОК ИЗ ФИШЕК','Крупно сверху: её рука двигает фишки и находит слово, которое СКЛАДЫВАЕТСЯ. Это и есть ответ на «что можно сделать» — восемь букв решают, какие слова вообще существуют в этой серии.','mini · GEN ~4s'),
   np_('S3','3 · Она крупно, сидит и пишет','Бумаги НЕ видно — угол не тот, и это правильно: мы видим ребёнка, а не эффект. За ней ЗАДНЯЯ СТЕНКА ПЕЧКИ — по посадке и углу там должна быть именно она. Это back plate.','mini · GEN ~6s'),
   np_('S4','4 · Сверху · С-О-К и ТОЧКА','На бумаге уже написано. Она проговаривает по буквам — буквы вспыхивают. Потом «Точка!» — и карандаш ОПУСКАЕТСЯ и ставит точку. Магия — от физического действия.','CARD · composite'),
   np_('S5','5 · По лицу проходит отсвет','Режем на Васю. Самой вспышки НЕ показываем — по его лицу проходит отсвет, и он поражён. Появление сока не снимаем вообще: в следующем кадре он просто есть.','mini · GEN ~4s'),
   np_('S6','6 · Через его затылок','Затылок Васи огромный на переднем плане, за ним Фрося радостно протягивает напёрсток: «Соку хочешь?» Мы смотрим его глазами, не со стороны.','mini · GEN ~5s'),
   np_('S7','7 · Смотрит СКВОЗЬ сок','Подносит напёрсток к глазу и разглядывает — настоящий ли. Глаз преломляется в соке. «Ты теперь так ВСЕГДА можешь?» Потом можно отъехать, и он опускает напёрсток.','mini · GEN ~6s')]
board('СЦЕНА 8 · ЭПИЗОД СОК — по раскадровке автора (7 кадров)',
 'Перерисовано по твоему листу. Ключевое, что меняется: слово сначала СКЛАДЫВАЕТСЯ ИЗ ФИШЕК, и только потом пишется; появление сока не показываем вообще — только отсвет на лице; точку ставит карандаш физически. Три кадра из семи — вообще без генерации новых фонов, если задняя стенка печки становится плейтом.',
 S,'/tmp/SCENE8_SOK_authorboard_v1.jpg')
