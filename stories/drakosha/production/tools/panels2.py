import sys; sys.path.insert(0,'/tmp/sb8')
from draw import *
from PIL import Image, ImageDraw, ImageFont
import textwrap, math

P={}
def new():
    im=Image.new('RGB',(W,H)); d=ImageDraw.Draw(im); d._image=im; return im,d
MAMA_C=(214,84,70); VAS_C=(96,150,220); FRO_C=(96,190,176); BAB_C=(238,196,120)
PAPA_C=(150,116,70); YAGA_C=(196,96,92)

def party_bg(d, cx=560, base=250, w=250, scale=0.8, papa_m='grin', yaga_m='smile',
             mama=None, mama_turn=-0.4, dim=True):
    """the tea table and whoever is at it — ALWAYS behind the children"""
    yaga(d,cx+w*0.78,base-6,150*scale,pose='sit',m=yaga_m,turn=-0.5)
    papa(d,cx-w*0.62,base+4,196*scale,pose='sit',m=papa_m,turn=0.45)
    if mama is not None:
        mama_f(d,cx+w*0.12,base+2,178*scale,brow='norm',arms='hold',m=mama,turn=mama_turn)
    tea_table(d,cx,base+34,w,scale=scale)
    if dim:
        o=Image.new('RGBA',(W,H),(0,0,0,0))
        ImageDraw.Draw(o).rectangle([0,0,W,base+90],fill=(18,12,8,58))
        blur_paste(d,o,0)
mama_f=mama   # alias so party_bg can shadow the name

# ================= BOARD A =================
# A1 · SH102 — floor level; kids in front, the party behind them
im,d=new(); room(d,horizon=232,vpx=560,mat=(120,346,760,210))
party_bg(d,cx=560,base=214,w=228,scale=0.78,mama='smile')
frosya(d,286,514,262,m='flat',turn=0.55)
vasya(d,686,524,244,m='smile',arms='hold',turn=-0.5)
d.ellipse([612,470,700,506],fill=(150,112,74),outline=(112,80,52),width=3)   # tile pouch
for dx,dy in [(-16,-6),(10,2),(30,-10),(-40,6)]:
    d.rounded_rectangle([656+dx,486+dy,656+dx+22,486+dy+18],3,fill=(228,206,166),outline=(154,124,88),width=2)
occluder(d,[(-60,H+60),(-60,470),(96,506),(60,H+60)],alpha=150,blur=14)
slate(d,'SH102 · С ПОЛА · дети впереди, стол со взрослыми — позади')
plan(d,[(0.30,0.62,FRO_C,'Фрося'),(0.62,0.64,VAS_C,'Вася'),(0.36,0.26,PAPA_C,'Папа'),
        (0.56,0.22,MAMA_C,'Мама'),(0.72,0.24,YAGA_C,'Яга')],(0.46,0.92,-88))
P['A1']=im

# A2 · SH103 — overhead, tiles spill
im,d=new()
d.rectangle([0,0,W,H],fill=(150,110,74))
for i in range(9): d.line([(0,i*70-20),(W,i*70+10)],fill=FLOORD,width=4)
d.polygon([(60,120),(880,60),(960,470),(120,540)],fill=(202,182,148),outline=(166,138,104),width=5)
d.ellipse([560,180,760,320],fill=(150,112,74),outline=(112,80,52),width=5)
import random; random.seed(11)
for _ in range(13):
    x=random.uniform(180,620); y=random.uniform(250,440); a=random.uniform(-0.5,0.5)
    dx,dy=math.cos(a)*34,math.sin(a)*34
    d.polygon([(x-dx,y-dy-24),(x+dx,y+dy-20),(x+dx,y+dy+22),(x-dx,y-dy+26)],fill=(228,206,166),outline=(154,124,88),width=3)
d.line([(600,300),(430,392)],fill=(200,168,120),width=8)
for sd in(-1,1):
    d.ellipse([700+sd*70-46,120-30,700+sd*70+46,120+40],fill=SKIN)   # his knees at the top edge
d.polygon([(120,540),(300,470),(360,H)],fill=(92,158,150))            # Фрося's knee, bottom-left
slate(d,'SH103 · СВЕРХУ · фишки высыпаются, колени в кадре = это ПОЛ')
plan(d,[(0.50,0.50,VAS_C,'Вася'),(0.24,0.66,FRO_C,'Фрося')],(0.50,0.50,-90))
P['A2']=im

# A3 · SH104-106 — WRITE(СОК) card, OTS
im,d=new(); space(d,glow=False)
d.polygon([(196,152),(918,206),(872,506),(120,420)],fill=(236,218,186))
d.polygon([(196,152),(918,206),(914,232),(200,180)],fill=(222,202,168))
for i,(ch,lit) in enumerate([('С',True),('О',False),('К',False)]):
    x=350+i*186; y=290+i*14; sc=1.0-i*0.06
    if lit:
        o=Image.new('RGBA',(W,H),(0,0,0,0)); ImageDraw.Draw(o).ellipse([x-118,y-118,x+118,y+118],fill=(255,182,60,150))
        blur_paste(d,o,28)
    d.text((x,y),ch,font=ImageFont.truetype(FONT,int(120*sc)),fill=(214,124,26) if lit else (122,92,62),anchor='mm')
d.polygon([(772,352),(902,286),(924,326),(796,388)],fill=(220,164,86),outline=(154,108,62),width=4)
d.polygon([(772,352),(742,372),(778,388)],fill=(72,58,48))
d.ellipse([874,290,962,376],fill=SKIN,outline=(216,166,136),width=3)
occluder(d,[(-60,H+60),(-60,150),(120,96),(300,190),(340,H+60)],alpha=245,blur=8)
back_of_head(d,116,140,132,kind='frosya')
slate(d,'SH104-106 · ЧЕРЕЗ ПЛЕЧО · буквы-PNG вспыхивают под голос')
plan(d,[(0.30,0.70,FRO_C,'Фрося')],(0.22,0.90,-64))
P['A3']=im

# A4 · SH107-108 — she offers, he takes; party still visible past them
im,d=new(); room(d,horizon=244,vpx=420,mat=(90,340,820,200))
party_bg(d,cx=600,base=222,w=196,scale=0.66,papa_m='grin',yaga_m='grin')
frosya(d,258,506,286,m='smile',turn=0.75)
vasya(d,700,512,252,m='o',arms='hold',turn=-0.7)
o=Image.new('RGBA',(W,H),(0,0,0,0)); ImageDraw.Draw(o).ellipse([470-120,404-70,470+120,404+70],fill=(255,206,120,86))
blur_paste(d,o,26)
d.polygon([(444,378),(508,378),(498,436),(454,436)],fill=(214,214,220),outline=(132,132,142),width=4)
d.ellipse([440,366,512,392],fill=(240,152,60),outline=(196,116,40),width=3)
d.line([(352,432),(438,404)],fill=SKIN,width=17); d.line([(614,438),(516,412)],fill=SKIN,width=17)
slate(d,'SH107-108 · СБОКУ · напёрсток передаётся из рук в руки')
plan(d,[(0.24,0.62,FRO_C,'Фрося'),(0.66,0.62,VAS_C,'Вася'),(0.40,0.26,PAPA_C,'Папа'),(0.66,0.24,YAGA_C,'Яга')],(0.46,0.92,-86))
P['A4']=im

# A5 · SH109-111 — САЛАТ appears / Вася recoils, close 3/4
im,d=new(); room(d,horizon=196,vpx=300,show_lights=False)
vasya(d,540,H+140,600,m='yell',arms='hold',turn=-0.35,low=0.6,shad=False)
d.polygon([(150,472),(210,466),(202,H),(140,H)],fill=(214,214,220))
occluder(d,[(-60,H+60),(-60,392),(160,436),(120,H+60)],alpha=130,blur=16)
bubble(d,120,68,'Фу-у-у! Овощи!',24)
slate(d,'SH111 · КРУПНО 3/4 · отшатнулся, но сок не пролил')
plan(d,[(0.52,0.42,VAS_C,'Вася')],(0.42,0.88,-80))
P['A5']=im

# A6 · SH112-114 — Руся and the salad, lens on the planks
im,d=new()
d.rectangle([0,0,W,H],fill=(56,42,32)); wall_band(d,-40,178); floor_persp(d,174,420)
party_bg(d,cx=640,base=158,w=150,scale=0.5,papa_m='grin',yaga_m='smile')
d.ellipse([560,330,1010,520],fill=(214,194,156),outline=(164,134,98),width=5)
for dx,dy in [(-120,-30),(-60,-52),(10,-36),(-40,4),(60,-14),(-150,10)]:
    d.ellipse([784+dx-46,404+dy-26,784+dx+46,404+dy+26],fill=(112,172,92),outline=(72,124,62),width=3)
baby(d,214,392,180,kind='rus',pose='crawl',m='flat',turn=0.35)
arrow(d,(316,340),(486,352))
arrow(d,(470,478),(210,514),col=(196,166,116))
occluder(d,[(-60,H+60),(-60,500),(W+60,470),(W+60,H+60)],alpha=150,blur=12)
slate(d,'SH112-114 · ОБЪЕКТИВ НА ПОЛУ · вполз — понюхал — молча уполз')
plan(d,[(0.22,0.46,BAB_C,'Руся'),(0.64,0.50,(112,172,92),'салат'),(0.62,0.18,PAPA_C,'стол')],(0.46,0.92,-90))
P['A6']=im

# A7 · SH117-118 — the poppy to Мама AT THE TABLE (the family is finally in shot properly)
im,d=new(); room(d,horizon=330,vpx=380,ceiling=True)
lights(d,pts=[(-10,74),(250,44),(540,38),(820,58),(1020,88)])
papa(d,842,404,252,pose='sit',m='grin',turn=-0.6)
yaga(d,690,392,182,pose='sit',m='grin',turn=-0.7)
tea_table(d,790,432,208,scale=0.9)
mama(d,470,506,392,brow='norm',arms='hold',m='smile',turn=-0.35,low=0.7)
frosya(d,180,548,278,m='smile',turn=0.8)
d.line([(250,406),(372,318)],fill=(84,124,74),width=9)
d.ellipse([334,272,424,350],fill=(206,62,52),outline=(150,40,34),width=4)
d.ellipse([364,300,394,328],fill=(64,48,40))
bubble(d,60,58,'Мам, это тебе.',24)
slate(d,'SH117-118 · С ВЫСОТЫ РЕБЁНКА · Мама встаёт от стола, семья за ней')
plan(d,[(0.22,0.70,FRO_C,'Фрося'),(0.46,0.48,MAMA_C,'Мама'),(0.66,0.28,YAGA_C,'Яга'),(0.80,0.30,PAPA_C,'Папа')],(0.20,0.90,-64))
P['A7']=im

# A8 · SH119 — Яга hums; pencil shorter; behind the ear
im,d=new(); room(d,horizon=280,vpx=700,show_lights=False)
yaga(d,250,470,330,pose='sit',m='grin',turn=0.55)
tea_table(d,190,486,168,scale=0.86,cups=True)
d.rounded_rectangle([560,110,980,240],10,fill=(24,18,14),outline=(120,98,72),width=3)
d.polygon([(600,190),(742,158),(756,182),(614,214)],fill=(220,164,86),outline=(154,108,62),width=3)
d.polygon([(600,190),(578,200),(602,214)],fill=(72,58,48))
d.polygon([(800,190),(898,168),(912,192),(814,216)],fill=(220,164,86),outline=(154,108,62),width=3)
d.polygon([(800,190),(778,200),(802,214)],fill=(72,58,48))
d.text((770,132),'было / стало',font=ImageFont.truetype(FONT,20),fill=(200,182,150),anchor='mm')
frosya(d,760,540,268,m='smile',turn=-0.35)
d.line([(806,430),(846,398)],fill=(220,164,86),width=9)
slate(d,'SH119 · ЯГА ХМЫКАЕТ · врезка «было/стало» · карандаш за ухо')
plan(d,[(0.22,0.46,YAGA_C,'Яга'),(0.70,0.66,FRO_C,'Фрося')],(0.50,0.92,-96))
P['A8']=im


def write_card(key, word, lit, slate_txt, glow_obj=None):
    """Фрося writes: OTS over her shoulder, letters lighting one at a time"""
    im,d=new(); space(d,glow=False)
    d.polygon([(196,152),(918,206),(872,506),(120,420)],fill=(236,218,186))
    d.polygon([(196,152),(918,206),(914,232),(200,180)],fill=(222,202,168))
    n=len(word); step=min(186, int(560/n)); x0=350-(n-3)*step*0.34
    for i,ch in enumerate(word):
        x=x0+i*step; y=290+i*10; sc=(1.0-i*0.04)*(1.0 if n<=3 else 0.82)
        if i==lit:
            o=Image.new('RGBA',(W,H),(0,0,0,0)); ImageDraw.Draw(o).ellipse([x-118,y-118,x+118,y+118],fill=(255,182,60,150))
            blur_paste(d,o,28)
        d.text((x,y),ch,font=ImageFont.truetype(FONT,int(120*sc)),
               fill=(214,124,26) if i==lit else (122,92,62),anchor='mm')
    d.polygon([(772,352),(902,286),(924,326),(796,388)],fill=(220,164,86),outline=(154,108,62),width=4)
    d.polygon([(772,352),(742,372),(778,388)],fill=(72,58,48))
    d.ellipse([874,290,962,376],fill=SKIN,outline=(216,166,136),width=3)
    if glow_obj=='salad':
        d.ellipse([560,398,760,478],fill=(214,194,156),outline=(164,134,98),width=4)
        for dx,dy in [(-46,-14),(-8,-26),(34,-16),(6,4)]:
            d.ellipse([660+dx-30,432+dy-16,660+dx+30,432+dy+16],fill=(112,172,92),outline=(72,124,62),width=3)
    elif glow_obj=='poppy':
        d.line([(680,470),(742,388)],fill=(84,124,74),width=8)
        d.ellipse([706,346,790,424],fill=(206,62,52),outline=(150,40,34),width=4)
        d.ellipse([736,374,762,400],fill=(64,48,40))
    occluder(d,[(-60,H+60),(-60,150),(120,96),(300,190),(340,H+60)],alpha=245,blur=8)
    back_of_head(d,116,140,132,kind='frosya')
    slate(d,slate_txt)
    plan(d,[(0.30,0.70,FRO_C,'Фрося')],(0.22,0.90,-64))
    P[key]=im

write_card('A5b','САЛАТ',2,'SH109-110 · ТА ЖЕ КАРТА, ДРУГАЯ ИГРА · пять букв, по-деловому', glow_obj='salad')
write_card('A8b','МАК',0,'SH115-116 · ТА ЖЕ КАРТА · хихикает, уже играет', glow_obj='poppy')

# ================= BOARD B =================
# B1 · SH120-121 — he digs in the pouch, she nods at the tiles
im,d=new(); room(d,horizon=250,vpx=620,mat=(150,352,700,190))
party_bg(d,cx=580,base=228,w=200,scale=0.7,papa_m='grin',yaga_m='smile',mama='flat',mama_turn=-0.2)
vasya(d,676,520,268,m='o',arms='hold',turn=-0.55)
d.ellipse([600,466,684,502],fill=(150,112,74),outline=(112,80,52),width=3)
frosya(d,258,510,262,m='flat',turn=0.6)
for i,dx in enumerate((-40,0,40,80)):
    d.polygon([(430+dx,470),(468+dx,466),(470+dx,494),(432+dx,498)],fill=(228,206,166),outline=(154,124,88),width=3)
occluder(d,[(-60,H+60),(-60,466),(90,500),(56,H+60)],alpha=150,blur=14)
bubble(d,96,62,'А я? Мне слово! Лёгкое!',23)
slate(d,'SH120-121 · роется в мешочке · она кивает на фишки, не трогая их')
plan(d,[(0.26,0.62,FRO_C,'Фрося'),(0.64,0.64,VAS_C,'Вася'),(0.40,0.26,PAPA_C,'Папа'),
        (0.58,0.22,MAMA_C,'Мама'),(0.74,0.24,YAGA_C,'Яга')],(0.46,0.92,-88))
P['B1']=im

# B2 · SH122-123 — READ-ASSEMBLE card, low on the planks
im,d=new(); space(d)
sizes=[(292,470,120),(470,432,94),(612,404,76),(726,384,62)]
for i,(x,y,s) in enumerate(sizes):
    lit=(i==0)
    if lit:
        o=Image.new('RGBA',(W,H),(0,0,0,0)); ImageDraw.Draw(o).ellipse([x-s*1.5,y-s*1.5,x+s*1.5,y+s*1.5],fill=(255,180,60,120))
        blur_paste(d,o,26)
    d.polygon([(x-s*0.62,y-s*0.44),(x+s*0.62,y-s*0.52),(x+s*0.70,y+s*0.30),(x-s*0.70,y+s*0.38)],
              fill=(255,238,186) if lit else (228,206,166),outline=(214,138,44) if lit else (154,124,88),width=4)
    d.text((x,y-s*0.06),'МАМА'[i],font=ImageFont.truetype(FONT,int(s*0.64)),
           fill=(206,116,26) if lit else (124,90,58),anchor='mm')
vasya(d,842,352,150,m='o',arms='hold',turn=-0.6,shad=False)
occluder(d,[(-60,H+60),(-60,470),(190,506),(240,H+60)],alpha=200,blur=12)
slate(d,'SH122-123 · НИЗКО У ПОЛА · ведёт пальцем, читает, «ВЖУХ!»')
plan(d,[(0.72,0.30,VAS_C,'Вася')],(0.16,0.74,-26))
P['B2']=im

# B3 · SH124-125 — two Мамы, AND the family watching in silence behind them
im,d=new(); room(d,horizon=286,vpx=760)
party_bg(d,cx=560,base=250,w=214,scale=0.74,papa_m='o',yaga_m='grin',dim=False)
mama(d,700,498,318,brow='huge',arms='up',m='o',turn=-0.5)
occluder(d,[(-70,H+70),(-70,300),(150,226),(346,306),(376,H+70)],alpha=246,blur=7)
back_of_head(d,150,230,150,kind='mama')
frosya(d,392,414,150,m='o',turn=0.5)
slate(d,'SH125 · ЧЕРЕЗ ПЛЕЧО настоящей Мамы · СЕМЬЯ ЗА НИМИ МОЛЧИТ')
plan(d,[(0.28,0.66,MAMA_C,'Мама'),(0.62,0.44,MAMA_C,'Вася-М'),(0.40,0.34,FRO_C,'Фрося'),
        (0.44,0.16,PAPA_C,'Папа'),(0.70,0.16,YAGA_C,'Яга')],(0.16,0.84,-46))
P['B3']=im

# B4 · SH126 — real Мама, brow check
im,d=new(); room(d,horizon=150,vpx=300,show_lights=False)
mama(d,470,H+330,880,brow='norm',arms='brow',m='flat',turn=-0.35,low=0.8,shad=False)
occluder(d,[(W+60,H+60),(W+60,300),(880,340),(830,H+60)],alpha=110,blur=18)
slate(d,'SH126 · КРУПНО, чуть СНИЗУ · трогает СВОИ брови, убирает руку')
plan(d,[(0.52,0.42,MAMA_C,'Мама')],(0.52,0.86,-90))
P['B4']=im

# B5 · SH127-128 — squeal and launch, lens on the planks
im,d=new()
d.rectangle([0,0,W,H],fill=(56,42,32)); wall_band(d,-40,196); floor_persp(d,192,520)
party_bg(d,cx=560,base=176,w=150,scale=0.46,papa_m='o',yaga_m='grin')
mama(d,556,286,150,brow='huge',arms='up',m='o',turn=-0.2)
baby(d,700,470,230,kind='rus',pose='toward',m='grin',turn=-0.2)
baby(d,286,520,270,kind='mus',pose='toward',m='o',turn=0.25)
arrow(d,(470,286),(392,330)); arrow(d,(596,284),(664,318))
occluder(d,[(-60,H+60),(-60,486),(W+60,452),(W+60,H+60)],alpha=170,blur=13)
slate(d,'SH127-128 · ОБЪЕКТИВ НА ПОЛУ · визг и топот, ползут В КАМЕРУ')
plan(d,[(0.50,0.22,MAMA_C,'Вася-М'),(0.40,0.60,BAB_C,'Руся'),(0.60,0.64,BAB_C,'Муся')],(0.50,0.92,-90))
P['B5']=im

# B6 · SH129-130 — hem chewing + hands up, from below
im,d=new(); room(d,horizon=452,vpx=500,ceiling=True)
lights(d,pts=[(-10,96),(180,60),(420,44),(660,54),(920,88)])
party_bg(d,cx=760,base=402,w=132,scale=0.42,papa_m='grin',yaga_m='grin')
frosya(d,806,432,166,m='grin',bent=True,turn=-0.55)
mama(d,452,506,430,brow='huge',arms='up',m='yell',low=1.0)
baby(d,352,540,230,kind='rus',pose='climb',m='grin',turn=0.4)
baby(d,610,556,215,kind='mus',pose='crawl',m='o',turn=-0.5)
occluder(d,[(-60,H+60),(-60,520),(180,536),(150,H+60)],alpha=150,blur=14)
bubble(d,110,84,'Ай! Фрося! Они меня едят!')
slate(d,'SH129-130 · СНИЗУ ВВЕРХ · поднял обе руки, чтобы их не задеть')
plan(d,[(0.46,0.42,MAMA_C,'Вася-М'),(0.38,0.52,BAB_C,'Руся'),(0.56,0.54,BAB_C,'Муся'),(0.78,0.34,FRO_C,'Фрося')],(0.44,0.90,-84))
P['B6']=im

# B7 · SH131 — the one-finger pry; Руся clings tighter
im,d=new(); room(d,horizon=390,vpx=300,show_lights=False)
mama(d,600,H+120,700,brow='huge',arms='down',m='yell',turn=-0.4,low=0.5,shad=False)
baby(d,392,520,300,kind='rus',pose='climb',m='grin',turn=0.5)
d.line([(470,352),(410,404)],fill=SKIN,width=26)
d.ellipse([386,388,442,438],fill=SKIN)
d.line([(404,424),(372,452)],fill=SKIN,width=13)
occluder(d,[(W+60,H+60),(W+60,120),(880,180),(846,H+60)],alpha=120,blur=16)
bubble(d,86,60,'Я не мама! Я Вася! Снимите их!',22)
slate(d,'SH131 · СРЕДНИЙ · отцепляет одним пальцем — Руся держится крепче')
plan(d,[(0.62,0.48,MAMA_C,'Вася-М'),(0.44,0.56,BAB_C,'Руся')],(0.40,0.90,-78))
P['B7']=im

# B8 · SH132-133 — Мама walks in, takes BOTH babies, then lands the line
im,d=new(); room(d,horizon=300,vpx=760,show_lights=True)
party_bg(d,cx=700,base=262,w=160,scale=0.5,papa_m='grin',yaga_m='grin')
mama(d,320,528,352,brow='norm',arms='hold',m='flat',turn=0.55)
baby(d,262,438,168,kind='rus',pose='sit',m='flat',turn=-0.4)
baby(d,392,446,160,kind='mus',pose='sit',m='o',turn=0.4)
mama(d,760,540,336,brow='huge',arms='down',m='flat',turn=-0.6)
bubble(d,300,66,'Брови-то твои, Вася.',24)
slate(d,'SH132-133 · СБОКУ · сняла обоих, держит на руках — и только потом фраза')
plan(d,[(0.30,0.58,MAMA_C,'Мама+2'),(0.70,0.60,MAMA_C,'Вася-М'),(0.62,0.22,PAPA_C,'стол')],(0.48,0.92,-88))
P['B8']=im

# B9 · SH134-135 — angry ВЖУХ, light, Вася back; tiles still on the floor
im,d=new(); room(d,horizon=296,vpx=500)
o=Image.new('RGBA',(W,H),(0,0,0,0)); ImageDraw.Draw(o).ellipse([500-250,300-190,500+250,300+190],fill=(255,208,120,74))
blur_paste(d,o,42)
party_bg(d,cx=620,base=252,w=150,scale=0.48,papa_m='o',yaga_m='grin')
vasya(d,470,512,286,m='yell',arms='down',turn=-0.2)
for i,dx in enumerate((-70,-24,22,68)):
    d.polygon([(300+dx,486),(340+dx,482),(342+dx,512),(302+dx,516)],fill=(228,206,166),outline=(154,124,88),width=3)
for rr in(90,132): d.ellipse([470-rr,320-rr*0.44,470+rr,320+rr*0.44],outline=(255,222,146),width=4)
bubble(d,660,72,'ВЖУХ!',26)
slate(d,'SH134-135 · обиженный ВЖУХ · фишки МАМА остаются на полу')
plan(d,[(0.46,0.56,VAS_C,'Вася'),(0.62,0.22,PAPA_C,'стол')],(0.48,0.90,-88))
P['B9']=im

# B10 · SH136 — the scene ENDS on Фрося on the floor, laughing
im,d=new()
d.rectangle([0,0,W,H],fill=(56,42,32)); wall_band(d,-40,150); floor_persp(d,146,500,vpy=-220)
party_bg(d,cx=560,base=126,w=120,scale=0.38,papa_m='grin',yaga_m='grin')
frosya(d,470,470,232,m='grin',bent=True,turn=0.2)
d.polygon([(300,470),(690,452),(700,H),(280,H)],fill=(92,158,150))
for i,dx in enumerate((-70,-24,22,68)):
    d.polygon([(760+dx,384),(796+dx,380),(798+dx,406),(762+dx,410)],fill=(228,206,166),outline=(154,124,88),width=3)
vasya(d,168,392,150,m='flat',arms='down',turn=0.5)
occluder(d,[(-60,H+60),(-60,520),(W+60,486),(W+60,H+60)],alpha=120,blur=14)
slate(d,'SH136 · СВЕРХУ · сцена кончается на Фросе, упавшей от хохота')
plan(d,[(0.48,0.56,FRO_C,'Фрося'),(0.18,0.40,VAS_C,'Вася'),(0.56,0.14,PAPA_C,'стол')],(0.48,0.90,-88))
P['B10']=im

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

A=[np_('A1','SH102 · Установка — вся комната','Камера на полу: Фрося с карандашом и Вася с фишками впереди, ПАПА и ЯГА пьют чай за столом позади, Мама между ними. Это единственный кадр, который объясняет зрителю, кто вообще в комнате.','mini · GEN ~5s'),
   np_('A2','SH103 · Фишки высыпаются','Сверху над детьми. Его колени сверху кадра и Фросино колено снизу — по ним читается, что это ПОЛ, а не стол (та самая ошибка сцены 7). Звук «тук-тук-тук».','mini · GEN ~4s'),
   np_('A3','SH104-106 · КАРТА ПИСЬМА — СОК','Через плечо Фроси. Буквы — PNG автора, вспыхивают по одной под слоги, потом всё слово. «Точка.» — записи НЕТ, нужна новая. Вспышка → напёрсток уже стоит.','CARD · composite'),
   np_('A4','SH107-108 · Сок из рук в руки','Сбоку: она подаёт напёрсток двумя пальцами «по-светски», он берёт обеими руками. За ними видно стол — Папа и Яга следят, но не встают.','mini · GEN ~7s'),
   np_('A5b','SH109-110 · КАРТА ПИСЬМА — САЛАТ','Она пишет ВТОРОЕ слово — и это НЕ повтор: СОК был осторожный первый раз, САЛАТ она пишет уже по-деловому, пять букв подряд. Вспышка → плошка салата. Тот же механизм карты, другая игра актрисы.','CARD · composite'),
   np_('A5','SH111 · «Фу-у-у! Овощи!»','Крупно 3/4, чуть снизу: отшатнулся вместе с напёрстком и НЕ пролил — в этом весь бит. Можно снять одной точкой вместе с l54 и l60.','mini · GEN ~9s'),
   np_('A6','SH112-114 · Руся и салат','Объектив на полу: плошка огромная справа, Руся вползает слева. Обнюхал, лист качнулся у носа, молча уполз — и кадр секунду остаётся пустым. Тихая передышка.','mini · GEN ~8s'),
   np_('A8b','SH115-116 · КАРТА ПИСЬМА — МАК','Третье слово, третья игра: тут она уже хихикает — пишет не по заданию, а потому что придумала подарок. Вспышка → алый мак со свободным стеблем лежит рядом.','CARD · composite'),
   np_('A7','SH117-118 · Мак — тёплый бит','С высоты ребёнка, снизу вверх: Мама встаёт от стола, за ней Яга и Папа. Мак крупно на переднем плане. Голос Мамы — после рекаста.','mini · GEN ~8s'),
   np_('A8','SH119 · Яга хмыкает · карандаш','Яга за столом одобрительно хмыкает — она эти подарки и выбрала. Потом врезка «было/стало»: карандаш стал короче. Фрося заправляет его за ухо.','mini · GEN ~5s')]
board('СЦЕНА 8 · ДОСКА A — СОК, САЛАТ, МАК  (SH102-SH119)',
 'Собрано по реальному сценарию. ТРИ отдельных кадра письма — она пишет каждое слово сама, и каждый раз играет иначе: СОК осторожно, САЛАТ по-деловому, МАК уже хихикая. В каждом кадре видно, кто в комнате: ПАПА и БАБУШКА-ЯГА за чаем, МАМА между столом и детьми, РУСЯ и МУСЯ ползают. Взрослые НЕ поражены — семья волшебная, подарки только что вручены; Яга довольна собой, Папа радуется, Мама одна нервничает.',
 A,'/tmp/SCENE8_BOARD_A_v9.jpg')

B=[np_('B1','SH120-121 · «Мне слово! Лёгкое!»','Он ставит напёрсток и роется в мешочке; она кивает на фишки, не касаясь их — правило Мамы: собирает сам. Стол со взрослыми по-прежнему в кадре.','mini · GEN ~8s'),
   np_('B2','SH122-123 · КАРТА ЧТЕНИЯ — МАМА','Фишки М-А-М-А, вспыхивают по одной под голос, ближняя первой. Он ведёт по ним пальцем и кричит «ВЖУХ!». Свет полностью закрывает его → ИНТРО (~13 кр, один раз на весь сериал) → ленты из мультика с котом.','CARD + mini ×1'),
   np_('B3','SH124-125 · Две мамы. Тишина.','Через плечо настоящей Мамы — и вот здесь фон работает: СЕМЬЯ ЗА НИМИ МОЛЧА СМОТРИТ, у Папы открыт рот, Яга довольна. Держим тишину дольше удобного. РИСК близнецов: оба референса, один повтор в бюджете.','mini · GEN ~7s (!)'),
   np_('B4','SH126 · Мама проверяет брови','Крупно, чуть снизу, лицо в 3/4 — она ни на кого не смотрит. Рука входит снизу к своим бровям, убеждается, убирает. Без слов.','mini · GEN ~4s'),
   np_('B5','SH127-128 · Предательство малышей','Объектив на досках: увидели, взвизгнули и поползли ПРЯМО В КАМЕРУ, вырастая из кадра. Он — крошечный в глубине. Топот коленок — SFX.','mini · GEN ~5s'),
   np_('B6','SH129-130 · «Они меня едят!»','Снизу вверх: поднял ОБЕ руки, чтобы случайно их не задеть — то есть он их бережёт, и потому смешно. Муся жуёт фартук, Руся лезет по юбке. Голос МАЛЬЧИКА изо рта мамы. РИСК: повтор в бюджете.','mini · GEN ~10s (!)'),
   np_('B7','SH131 · Один палец','Пытается отцепить Русю ОДНИМ пальцем — и тот вцепляется крепче. Эскалация, которую я в прошлой раскадровке потерял: «Я не мама! Я Вася!»','mini · GEN ~6s'),
   np_('B8','SH132-133 · Мама снимает обоих','Настоящая Мама подходит, снимает Русю, потом Мусю, берёт обоих на руки — и ТОЛЬКО ПОТОМ говорит «Брови-то твои, Вася». Она решает проблему руками и добивает фразой.','mini · GEN ~8s'),
   np_('B9','SH134-135 · Обиженный ВЖУХ','Кричит ВЖУХ не сдувшись, а ОБИЖЕННО. Свет — и снова обычный Вася, мешочек на поясе, фишки МАМА так и лежат на полу.','mini · GEN ~5s'),
   np_('B10','SH136 · Конец — Фрося от хохота','Сцена кончается НЕ на нём, а на ней: Фрося падает на пол и хохочет. Сверху вниз, он маленький в глубине. Это и есть точка сцены.','mini · GEN ~4s')]
board('СЦЕНА 8 · ДОСКА B — ВАСЯ-МАМА  (SH120-SH136)',
 'Кульминация эпизода. Исправлено по сценарию: Мама НЕ сидит за столом — она подходит и снимает малышей, и только потом говорит фразу; сцена кончается на Фросе, а не на Васе; добавлен потерянный бит с одним пальцем. У каждого кадра своя точка съёмки, в углу — план сверху.',
 B,'/tmp/SCENE8_BOARD_B_v9.jpg')
