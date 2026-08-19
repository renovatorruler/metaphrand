import sys; sys.path.insert(0,'/tmp/sb8')
from draw import *
from PIL import Image, ImageDraw, ImageFont
import textwrap, math

P={}
def new():
    im=Image.new('RGB',(W,H)); d=ImageDraw.Draw(im); d._image=im; return im,d

MAMA_C=(214,84,70); VAS_C=(96,150,220); FRO_C=(96,190,176); BAB_C=(238,196,120)

# ============ BOARD B ============
# B0 — chips, camera low on the floor of the space, chips receding
im,d=new(); space(d)
f=ImageFont.truetype(FONT,1)
sizes=[(292,470,120),(470,432,94),(612,404,76),(726,384,62)]
for i,(x,y,s) in enumerate(sizes):
    lit=(i==0)
    if lit:
        o=Image.new('RGBA',(W,H),(0,0,0,0)); ImageDraw.Draw(o).ellipse([x-s*1.5,y-s*1.5,x+s*1.5,y+s*1.5],fill=(255,180,60,120))
        blur_paste(d,o,26)
    d.polygon([(x-s*0.62,y-s*0.44),(x+s*0.62,y-s*0.52),(x+s*0.70,y+s*0.30),(x-s*0.70,y+s*0.38)],
              fill=(255,238,186) if lit else (228,206,166), outline=(214,138,44) if lit else (154,124,88),width=4)
    ff=ImageFont.truetype(FONT,int(s*0.64))
    d.text((x,y-s*0.06),'МАМА'[i],font=ff,fill=(206,116,26) if lit else (124,90,58),anchor='mm')
vasya(d,842,352,150,m='o',arms='hold',turn=-0.6,shad=False)
occluder(d,[(-40,H+40),(-40,470),(190,506),(240,H+40)],alpha=200,blur=12)
slate(d,'НИЗКО У ПОЛА · фишки уходят вдаль, вспыхивают по одной')
plan(d,[(0.72,0.30,VAS_C,'Вася')],(0.16,0.74,-26))
P['B0']=im

# B0b — transform triptych (unchanged idea, three separate frames)
im,d=new(); space(d,glow=False)
for x0 in (26,362,698): d.rounded_rectangle([x0,66,x0+276,500],10,outline=(122,98,72),width=4)
vasya(d,164,452,262,m='flat',arms='up',shad=False)
vasya(d,500,452,262,m='flat',arms='up',shad=False)
for rr,ry in [(126,66),(96,46),(64,28)]: d.arc([500-rr,300-ry,500+rr,300+ry],0,360,fill=GOLD,width=8)
d.ellipse([836-104,146,836+104,458],outline=GOLD,width=9)
mama(d,836,438,238,brow='huge',arms='down',m='smile',shad=False)
d.text((836,470),'МАМА',font=ImageFont.truetype(FONT,40),fill=GOLDL,anchor='mm')
arrow(d,(306,282),(354,282),col=(210,178,120),w=5); arrow(d,(642,282),(690,282),col=(210,178,120),w=5)
slate(d,'ИНТРО (ген. один раз) → ЛЕНТЫ (из мультика кота) → КАРТА')
P['B0b']=im

# VM1 — camera BEHIND the real Мама's shoulder; she is huge in foreground, he is deep
im,d=new(); room(d,horizon=268,vpx=760)
frosya(d,300,384,116,m='o',turn=0.6)
mama(d,652,472,304,brow='huge',arms='up',m='o',turn=-0.55)
occluder(d,[(-60,H+60),(-60,300),(150,232),(330,300),(360,H+60)],alpha=245,blur=7)
back_of_head(d,150,236,148,kind='mama')
slate(d,'ЧЕРЕЗ ПЛЕЧО настоящей Мамы · он — в глубине')
plan(d,[(0.30,0.62,MAMA_C,'Мама'),(0.66,0.36,MAMA_C,'Вася-М'),(0.44,0.26,FRO_C,'Фрося')],(0.16,0.80,-42))
P['VM1']=im

# VM2 — tight 3/4, camera slightly BELOW her, head fills frame
im,d=new(); room(d,horizon=150,vpx=300,show_lights=False)
mama(d,470,H+330,880,brow='norm',arms='brow',m='flat',turn=-0.35,low=0.8,shad=False)
occluder(d,[(W+40,H+40),(W+40,300),(880,340),(830,H+40)],alpha=110,blur=18)
slate(d,'КРУПНО, чуть СНИЗУ · рука входит в кадр к своим бровям')
plan(d,[(0.52,0.42,MAMA_C,'Мама')],(0.52,0.86,-90))
P['VM2']=im

# VM3 — camera ON the planks; babies come TOWARD lens, he is deep and small
im,d=new()
d.rectangle([0,0,W,H],fill=(56,42,32)); wall_band(d,-40,196); floor_persp(d,192,520)
mama(d,556,286,150,brow='huge',arms='up',m='o',turn=-0.2,shad=True)
baby(d,700,470,230,kind='rus',pose='toward',m='grin',turn=-0.2)
baby(d,286,520,270,kind='mus',pose='toward',m='o',turn=0.25)
occluder(d,[(-40,H+40),(-40,486),(W+40,452),(W+40,H+40)],alpha=170,blur=13)
arrow(d,(470,286),(392,330)); arrow(d,(596,284),(664,318))
slate(d,'ОБЪЕКТИВ НА ПОЛУ · ползут ПРЯМО В КАМЕРУ')
plan(d,[(0.50,0.22,MAMA_C,'Вася-М'),(0.40,0.60,BAB_C,'Руся'),(0.60,0.64,BAB_C,'Муся')],(0.50,0.92,-90))
P['VM3']=im

# VM4 — LOW angle looking up: he towers, babies loom at the bottom edge
im,d=new(); room(d,horizon=452,vpx=500,ceiling=True)
lights(d,pts=[(-10,96),(180,60),(420,44),(660,54),(920,88)])
frosya(d,806,432,166,m='grin',bent=True,turn=-0.55)
mama(d,452,506,430,brow='huge',arms='up',m='yell',low=1.0)
baby(d,352,540,230,kind='rus',pose='climb',m='grin',turn=0.4)
baby(d,610,556,215,kind='mus',pose='crawl',m='o',turn=-0.5)
occluder(d,[(-40,H+40),(-40,520),(180,536),(150,H+40)],alpha=150,blur=14)
bubble(d,122,86,'Ай! Фрося! Они меня едят!')
slate(d,'СНИЗУ ВВЕРХ · он возвышается, малыши лезут в нижний край')
plan(d,[(0.46,0.42,MAMA_C,'Вася-М'),(0.38,0.52,BAB_C,'Руся'),(0.56,0.54,BAB_C,'Муся'),(0.80,0.36,FRO_C,'Фрося')],(0.44,0.90,-84))
P['VM4']=im

# VM5 — OTS from behind Вася-Мама onto Мама at the table
im,d=new(); room(d,horizon=286,vpx=180,show_lights=False)
mama(d,362,486,300,brow='norm',arms='hold',m='flat',turn=-0.5)
d.polygon([(-20,486),(660,450),(742,516),(-30,566)],fill=(154,112,72),outline=(112,80,52),width=5)
d.polygon([(120,566),(150,566),(150,H),(120,H)],fill=(126,90,58))
d.ellipse([392,442,440,478],fill=(206,206,212),outline=(126,126,136),width=3)
occluder(d,[(W+60,H+60),(W+60,20),(792,60),(742,352),(846,H+60)],alpha=245,blur=8)
back_of_head(d,900,168,150,kind='mama')
bubble(d,462,150,'Брови-то твои, Вася.')
slate(d,'ЧЕРЕЗ ПЛЕЧО Васи-Мамы · она не встаёт из-за стола')
plan(d,[(0.34,0.34,MAMA_C,'Мама'),(0.74,0.72,MAMA_C,'Вася-М')],(0.80,0.82,-140))
P['VM5']=im

# VM6 — HIGH angle down onto Вася sitting among the babies
im,d=new()
d.rectangle([0,0,W,H],fill=(56,42,32)); wall_band(d,-40,120); floor_persp(d,116,500,vpy=-260)
o=Image.new('RGBA',(W,H),(0,0,0,0)); ImageDraw.Draw(o).ellipse([500-260,330-200,500+260,330+200],fill=(255,208,120,70))
blur_paste(d,o,44)
vasya(d,500,470,236,m='flat',arms='down',low=-0.8)
baby(d,286,486,158,kind='rus',pose='sit',m='flat',turn=0.5)
baby(d,714,500,152,kind='mus',pose='sit',m='wail',turn=-0.5)
for dx in(-12,12): d.line([(714+dx,456),(714+dx+(6 if dx>0 else -6),486)],fill=(126,178,226),width=6)
for rr in(84,124): d.ellipse([500-rr,300-rr*0.5,500+rr,300+rr*0.5],outline=(255,222,146),width=4)
slate(d,'СВЕРХУ ВНИЗ · сдулся, малыши вокруг')
plan(d,[(0.50,0.50,VAS_C,'Вася'),(0.34,0.58,BAB_C,'Руся'),(0.66,0.60,BAB_C,'Муся')],(0.50,0.88,-90))
P['VM6']=im

# ============ BOARD A ============
# A1 — high 3/4 wide from the ramp side
im,d=new(); room(d,horizon=176,vpx=820,mat=(196,318,560,150))
mama(d,806,300,196,brow='norm',arms='hold',m='smile',turn=-0.6)
d.polygon([(430,382),(576,368),(586,438),(438,452)],fill=(128,90,60),outline=(96,64,42),width=4)
d.polygon([(430,382),(576,368),(566,352),(440,364)],fill=(148,106,70),outline=(96,64,42),width=3)
frosya(d,318,486,208,m='smile',turn=0.55)
vasya(d,646,494,196,m='smile',arms='hold',turn=-0.55)
occluder(d,[(-40,H+40),(-40,430),(120,470),(90,H+40)],alpha=140,blur=15)
slate(d,'СВЕРХУ 3/4 от рампы · коврик, сундук, взрослые в глубине')
plan(d,[(0.36,0.54,FRO_C,'Фрося'),(0.60,0.56,VAS_C,'Вася'),(0.74,0.28,MAMA_C,'Мама')],(0.22,0.86,-56))
P['A1']=im

# A2 — OTS over Фрося's shoulder onto the paper in perspective
im,d=new(); space(d,glow=False)
d.polygon([(196,152),(918,206),(872,506),(120,420)],fill=(236,218,186))
d.polygon([(196,152),(918,206),(914,232),(200,180)],fill=(222,202,168))
for i,(ch,lit) in enumerate([('С',True),('О',False),('К',False)]):
    x=350+i*186; y=290+i*14; s=1.0-i*0.06
    if lit:
        o=Image.new('RGBA',(W,H),(0,0,0,0)); ImageDraw.Draw(o).ellipse([x-118,y-118,x+118,y+118],fill=(255,182,60,150))
        blur_paste(d,o,28)
    d.text((x,y),ch,font=ImageFont.truetype(FONT,int(120*s)),fill=(214,124,26) if lit else (122,92,62),anchor='mm')
d.polygon([(772,352),(902,286),(924,326),(796,388)],fill=(220,164,86),outline=(154,108,62),width=4)
d.polygon([(772,352),(742,372),(778,388)],fill=(72,58,48))
d.ellipse([874,290,962,376],fill=SKIN,outline=(216,166,136),width=3)
occluder(d,[(-60,H+60),(-60,150),(120,96),(300,190),(340,H+60)],alpha=245,blur=8)
back_of_head(d,116,140,132,kind='frosya')
slate(d,'ЧЕРЕЗ ПЛЕЧО Фроси · буквы-PNG вспыхивают под голос')
plan(d,[(0.30,0.70,FRO_C,'Фрося')],(0.22,0.90,-64))
P['A2']=im

# A3 — low near the floor, thimble large in foreground
im,d=new(); room(d,horizon=214,vpx=560,mat=(150,286,700,190))
vasya(d,690,398,182,m='o',arms='hold',turn=-0.5)
frosya(d,352,436,214,m='smile',turn=0.6)
o=Image.new('RGBA',(W,H),(0,0,0,0)); ImageDraw.Draw(o).ellipse([470-170,470-90,470+170,470+90],fill=(255,206,120,96))
blur_paste(d,o,28)
d.polygon([(414,404),(528,404),(512,520),(432,520)],fill=(214,214,220),outline=(132,132,142),width=4)
d.ellipse([412,388,530,424],fill=(240,152,60),outline=(196,116,40),width=3)
slate(d,'НИЗКО · напёрсток крупно на переднем плане')
plan(d,[(0.34,0.42,FRO_C,'Фрося'),(0.66,0.32,VAS_C,'Вася'),(0.48,0.58,(240,152,60),'сок')],(0.44,0.90,-84))
P['A3']=im

# A4 — close 3/4, slightly low
im,d=new(); room(d,horizon=190,vpx=260,show_lights=False)
vasya(d,470,H+180,660,m='yell',arms='up',turn=-0.3,low=0.7,shad=False)
occluder(d,[(-40,H+40),(-40,380),(140,420),(110,H+40)],alpha=130,blur=16)
bubble(d,556,74,'Фу-у-у! Овощи!',24)
slate(d,'КРУПНО 3/4, чуть снизу · одна точка — три реакции')
plan(d,[(0.50,0.40,VAS_C,'Вася')],(0.40,0.88,-78))
P['A4']=im

# A5 — floor level, bowl large foreground right, Руся entering small
im,d=new()
d.rectangle([0,0,W,H],fill=(56,42,32)); wall_band(d,-40,178); floor_persp(d,174,420)
d.ellipse([560,330,1010,520],fill=(214,194,156),outline=(164,134,98),width=5)
for dx,dy in [(-120,-30),(-60,-52),(10,-36),(-40,4),(60,-14),(-150,10)]:
    d.ellipse([784+dx-46,404+dy-26,784+dx+46,404+dy+26],fill=(112,172,92),outline=(72,124,62),width=3)
baby(d,214,392,180,kind='rus',pose='crawl',m='flat',turn=0.35)
arrow(d,(316,352),(520,368))
arrow(d,(470,470),(210,502),col=(196,166,116))
occluder(d,[(-40,H+40),(-40,500),(W+40,470),(W+40,H+40)],alpha=150,blur=12)
slate(d,'ОБЪЕКТИВ НА ПОЛУ · вполз — понюхал — молча уполз')
plan(d,[(0.24,0.44,BAB_C,'Руся'),(0.66,0.50,(112,172,92),'салат')],(0.46,0.92,-92))
P['A5']=im

# A6 — child's eyeline UP at Мама, poppy in foreground
im,d=new(); room(d,horizon=376,vpx=420,ceiling=True)
lights(d,pts=[(-10,80),(240,52),(520,46),(800,66),(1020,96)])
mama(d,624,520,412,brow='norm',arms='hold',m='smile',turn=-0.5,low=0.8)
frosya(d,206,540,262,m='smile',turn=0.7)
d.line([(272,404),(392,306)],fill=(84,124,74),width=9)
d.ellipse([352,258,442,338],fill=(206,62,52),outline=(150,40,34),width=4)
d.ellipse([382,286,412,314],fill=(64,48,40))
bubble(d,66,66,'Мам, это тебе.',24)
slate(d,'С ВЫСОТЫ РЕБЁНКА, СНИЗУ ВВЕРХ · мак на переднем плане')
plan(d,[(0.28,0.66,FRO_C,'Фрося'),(0.62,0.36,MAMA_C,'Мама')],(0.24,0.88,-62))
P['A6']=im

# ============ compose ============
F_T=ImageFont.truetype(FONT,22); F_N=ImageFont.truetype(FONT,16)
F_H=ImageFont.truetype(FONT,32); F_S=ImageFont.truetype(FONT,15)
INK=(236,229,216); DIM=(172,162,146); ACC=(226,116,92); BG=(24,21,18)
PW,IH,NH,GAP,COLS=660,372,142,14,2

def np_(key,title,note,badge):
    p=Image.new('RGB',(PW,IH+NH),(30,26,22)); p.paste(P[key].resize((PW,IH)),(0,0))
    d=ImageDraw.Draw(p)
    d.text((12,IH+9),title,font=F_T,fill=INK)
    bw=d.textlength(badge,font=F_S)+18
    d.rounded_rectangle([PW-bw-10,IH+9,PW-10,IH+33],4,outline=ACC,width=1)
    d.text((PW-bw-1,IH+13),badge,font=F_S,fill=ACC)
    y=IH+42
    for ln in textwrap.wrap(note,width=76)[:5]:
        d.text((12,y),ln,font=F_N,fill=DIM); y+=19
    return p

def board(title,sub,items,out):
    rows=(len(items)+COLS-1)//COLS
    Wb=COLS*PW+(COLS+1)*GAP; Hb=124+rows*(IH+NH+GAP)
    b=Image.new('RGB',(Wb,Hb),BG); d=ImageDraw.Draw(b)
    d.text((GAP+2,18),title,font=F_H,fill=INK)
    y=62
    for ln in textwrap.wrap(sub,width=130):
        d.text((GAP+2,y),ln,font=F_N,fill=DIM); y+=19
    for i,p in enumerate(items):
        x=GAP+(i%COLS)*(PW+GAP); yy=114+(i//COLS)*(IH+NH+GAP)
        b.paste(p,(x,yy)); d.rectangle([x-1,yy-1,x+PW,yy+IH+NH],outline=(64,55,46))
    b.save(out,quality=93); print(out,b.size)

B=[np_('B0','0 · Чтение фишек — МАМА','Камера у самого пола: фишки уходят вдаль, ближняя вспыхивает первой. Свет по голосу на line62 «Ма… ма. МАМА!». Фишки — PNG автора. Потом «ВЖУХ!»','CARD · composite'),
   np_('B0b','0б · Трансформация','ИНТРО генерируется ОДИН РАЗ: start = руки вверх, end = в лентах (~13 кр, годится на весь сериал). Растворение — из готового мультика с котом. Карта МАМА. Вспышка →','mini · GEN 5s ×1'),
   np_('VM1','VM1 · Две мамы. Тишина.','Не плоский общий, а через плечо настоящей Мамы: она крупно у левого края, спиной к нам; он — глубже, меньше, с её лицом и своими бровями. Глубина и делает сравнение. РИСК близнецов, один повтор в бюджете.','mini · GEN ~7s (!)'),
   np_('VM2','VM2 · Мама проверяет брови','Крупно, камера чуть ниже её глаз, лицо в 3/4 — она ни на кого не смотрит. Рука входит в кадр снизу к своим бровям. Без слов.','mini · GEN ~4s'),
   np_('VM3','VM3 · Предательство малышей','Объектив лежит на досках. Малыши ползут ПРЯМО В КАМЕРУ и вырастают из кадра, он — крошечный в глубине. Топот коленок и визг — SFX.','mini · GEN ~5s'),
   np_('VM4','VM4 · КУЛЬМИНАЦИЯ — «Они меня едят!»','Снизу вверх: он возвышается, малыши лезут в нижний край кадра, потолок с лампочками сверху. Голос МАЛЬЧИКА изо рта мамы (line63-64) — в этом и шутка. Фрося в глубине справа. РИСК: повтор в бюджете.','mini · GEN ~10s (!)'),
   np_('VM5','VM5 · «Брови-то твои, Вася.»','Через его плечо: тёмная масса Васи-Мамы у правого края, она за столом в 3/4 — не встаёт, не повышает голос. Line65, голос после рекаста.','mini · GEN ~3s'),
   np_('VM6','VM6 · «Вжух!» — назад','Сверху вниз на сдувшегося Васю: доски расходятся под ним, малыши сидят вокруг, один ревёт (SFX). Line66. Сцена кончается на его лице.','mini · GEN ~4s')]
board('SCENE 8 · BOARD B — ВАСЯ-МАМА (кульминация эпизода)',
 'Каждый кадр — своя точка съёмки: через плечо, с пола, снизу вверх, сверху вниз. В углу план сверху: жёлтый значок — камера, точки — кто где стоит. Около 33 секунд, конверт 400, снимаем в канонной комнате сцены 7.',
 B,'/tmp/SCENE8_BOARD_B_v6.jpg')

A=[np_('A1','1 · Установка — угол с ковриком','Сверху 3/4 от рампы, а не плоский общий: коврик и сундук уходят вглубь, взрослые в глубине. Стартовый кадр берём из хвоста сцены 7. Line52 поверх конца.','mini · GEN ~4s'),
   np_('A2','2 · КАРТА ПИСЬМА — СОК','Через плечо Фроси: её тёмный силуэт слева, бумага уходит в перспективу. Буквы — PNG автора, вспыхивают по одной под слоги. «Точка.» — записи НЕТ, нужна новая.','CARD · composite'),
   np_('A3','3 · Сок в напёрстке','Низко у пола: напёрсток крупно на переднем плане, Фрося подаёт (l53), Вася берёт двумя руками (l54). Пол читается как пол, потому что мы на нём лежим.','mini · GEN ~6s'),
   np_('A4','4 · Лестница реакций Васи','Крупно 3/4, чуть снизу. Одна точка съёмки, три бита режем врозь: восторг (l54), «Фу! Овощи!» (l56), «А я? Мне слово!» (l60).','mini · GEN ~10s'),
   np_('A5','5 · Руся и салат — тихий бит','Объектив на полу: плошка огромная справа, Руся вползает слева маленький. Обнюхал, лист качнулся, молча уполз. Передышка между двумя шутками.','mini · GEN ~8s'),
   np_('A6','6 · МАК — тёплый бит','С высоты ребёнка, снизу вверх на Маму — так мы весь эпизод и смотрим на взрослых. Мак крупно на переднем плане (l58/l59). Голос Мамы — после рекаста.','mini · GEN ~7s')]
board('SCENE 8 · BOARD A — сок, салат, мак',
 'Карты ничего не стоят; здесь всего четыре mini-джоба. Салат — маленькая передышка между шутками, кульминация на доске B.',
 A,'/tmp/SCENE8_BOARD_A_v6.jpg')
