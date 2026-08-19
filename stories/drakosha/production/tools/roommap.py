import sys; sys.path.insert(0,'/tmp/sb8')
from PIL import Image, ImageDraw, ImageFont
import math
FONT='/Library/Fonts/Arial Unicode.ttf'
W,H=1560,940
BG=(26,22,18); PAPER=(214,196,164); INK=(238,231,218); DIM=(168,158,142)
im=Image.new('RGB',(W,H),BG); d=ImageDraw.Draw(im)
F_H=ImageFont.truetype(FONT,34); F=ImageFont.truetype(FONT,19); FS=ImageFont.truetype(FONT,15); FB=ImageFont.truetype(FONT,22)

d.text((30,24),'СЦЕНА 8 · КТО ГДЕ СТОИТ  (исходные позиции)',font=F_H,fill=INK)
d.text((30,68),'По уточнению автора: Мама сидит на своём обычном месте, Руся и Муся играют на коврике перед столом рядом с ней.',font=F,fill=DIM)
d.text((30,92),'Это и есть их стартовая точка — оттуда они и рванут к Васе-Маме.',font=F,fill=DIM)

X0,Y0,X1,Y1=60,140,960,880
d.rounded_rectangle([X0,Y0,X1,Y1],14,fill=(44,36,30),outline=(120,100,78),width=3)
for gx in range(X0+60,X1,60): d.line([(gx,Y0),(gx,Y1)],fill=(52,43,36),width=1)
for gy in range(Y0+60,Y1,60): d.line([(X0,gy),(X1,gy)],fill=(52,43,36),width=1)

# --- stove back (top wall)
d.rounded_rectangle([X0+10,Y0+10,X1-10,Y0+86],8,fill=(84,74,70),outline=(140,128,120),width=3)
for i in range(26):
    x=X0+22+i*34
    d.ellipse([x,Y0+16,x+7,Y0+23],fill=(168,156,146))
    d.ellipse([x,Y0+74,x+7,Y0+81],fill=(168,156,146))
# the cake, on the edge
d.rounded_rectangle([X1-250,Y0+92,X1-130,Y0+128],6,fill=(226,196,150),outline=(178,142,100),width=3)
for i in range(5):
    cxx=X1-238+i*26
    d.line([(cxx,Y0+92),(cxx,Y0+76)],fill=(240,232,214),width=4)
    d.ellipse([cxx-4,Y0+66,cxx+4,Y0+78],fill=(255,196,84))
d.text((X1-190,Y0+142),'торт',font=FS,fill=(255,214,150),anchor='mm')
d.text(((X0+X1)//2,Y0+40),'ФРОНТ-ПЛЕЙТ  ·  плита (клёпаная)',font=FB,fill=(248,228,206),anchor='mm')
d.text(((X0+X1)//2,Y0+66),'здесь ТОРТ со свечами по краю',font=FS,fill=(255,214,150),anchor='mm')

# --- niche with the chest (left wall)
d.rounded_rectangle([X0+10,Y0+150,X0+64,Y0+270],6,fill=(96,74,58),outline=(140,112,84),width=3)
d.text((X0+80,Y0+196),'ниша · сундук',font=FS,fill=(196,182,158))
# --- hatch (left wall lower)
d.rounded_rectangle([X0+10,Y0+430,X0+58,Y0+520],6,fill=(70,60,52),outline=(130,110,86),width=3)
d.text((X0+72,Y0+468),'прочистная дверца',font=FS,fill=(196,182,158))
# --- ramp / floor opening (right)
d.polygon([(X1-16,Y0+300),(X1-16,Y0+560),(X1-150,Y0+498),(X1-150,Y0+360)],fill=(72,62,52),outline=(150,126,96),width=3)
d.text((X1-160,Y0+430),'рампа · люк в полу',font=FS,fill=(196,182,158),anchor='rm')

def person(cx,cy,r,col,label,sub=None,ring=False):
    if ring:
        d.ellipse([cx-r-11,cy-r-11,cx+r+11,cy+r+11],outline=(255,206,110),width=3)
    d.ellipse([cx-r,cy-r,cx+r,cy+r],fill=col,outline=(22,18,14),width=3)
    d.text((cx,cy),label,font=FB,fill=(26,20,16),anchor='mm')
    if sub: d.text((cx,cy+r+16),sub,font=FS,fill=(206,192,170),anchor='mm')

# --- the table
TX,TY=(X0+X1)//2+40,Y0+220
d.rounded_rectangle([TX-220,TY-56,TX+220,TY+56],12,fill=(150,108,70),outline=(112,80,52),width=4)
for dx in(-150,-50,60,150):
    d.ellipse([TX+dx-16,TY-18,TX+dx+16,TY+14],fill=(226,226,232),outline=(150,150,160),width=2)
d.text((TX,TY-84),'СТОЛ · чай',font=F,fill=(214,200,176),anchor='mm')

person(TX-280,TY,34,(214,84,70),'М','МАМА — на своём месте')
person(TX+58,TY-118,32,(196,96,92),'Я','БАБУШКА-ЯГА')
person(TX+282,TY,36,(150,116,70),'П','ПАПА')

# --- the babies' rug, in front of the table beside Мама
RX,RY=TX-190,TY+180
d.polygon([(RX-130,RY-58),(RX+130,RY-58),(RX+108,RY+58),(RX-108,RY+58)],fill=(186,120,110),outline=(150,90,84),width=3)
d.text((RX,RY-80),'КОВРИК малышей',font=F,fill=(214,200,176),anchor='mm')
person(RX-48,RY,26,(238,196,120),'Р','РУСЯ')
person(RX+52,RY,26,(238,182,192),'М','МУСЯ')

# --- the children's work zone, downstage
WX,WY=(X0+X1)//2-40,Y1-170
d.polygon([(WX-250,WY-90),(WX+250,WY-90),(WX+290,WY+90),(WX-290,WY+90)],fill=(200,180,146),outline=(166,138,104),width=4)
d.text((WX,WY-114),'РАБОЧАЯ ЗОНА — фишки и бумага',font=F,fill=(214,200,176),anchor='mm')
person(WX-140,WY+6,34,(96,190,176),'Ф','ФРОСЯ')
person(WX+150,WY+6,34,(96,150,220),'В','ВАСЯ')
for i in range(6):
    d.rounded_rectangle([WX-60+i*26,WY-16,WX-60+i*26+18,WY+12],3,fill=(228,206,166),outline=(154,124,88),width=2)

# --- camera for the СОК sequence
def cam(cx,cy,ang,lab):
    a=math.radians(ang); fov=math.radians(26)
    layer=Image.new('RGBA',(W,H),(0,0,0,0))
    ImageDraw.Draw(layer).polygon([(cx,cy),(cx+math.cos(a-fov)*300,cy+math.sin(a-fov)*300),
                                   (cx+math.cos(a+fov)*300,cy+math.sin(a+fov)*300)],fill=(255,200,90,26))
    im.paste(Image.alpha_composite(im.convert('RGBA'),layer).convert('RGB'),(0,0))
    d.polygon([(cx-9,cy-9),(cx+9,cy-9),(cx+9,cy+9),(cx-9,cy+9)],fill=(255,206,110))
    d.text((cx,cy+24),lab,font=FS,fill=(255,214,130),anchor='mm')
cam(WX-40,Y1-30,-90,'кадры 1-2-4 (сверху)')
cam(TX-60,TY+120,96,'кадр 3 — смотрим НА Фросю')
d.rounded_rectangle([X0+150,Y1-104,X0+560,Y1-46],8,outline=(240,130,120),width=3)
d.text((X0+355,Y1-75),'BACK PLATE — за Фросей.  КАКАЯ СТЕНА?',font=F,fill=(240,130,120),anchor='mm')
cam(WX+330,WY+70,-158,'кадры 6-7')

# --- the two moves that happen in this scene
def move(p0,p1,col,lab,off=(0,-16)):
    d.line([p0,p1],fill=col,width=5)
    a=math.atan2(p1[1]-p0[1],p1[0]-p0[0])
    for da in(2.6,-2.6):
        d.line([p1,(p1[0]-22*math.cos(a+da),p1[1]-22*math.sin(a+da))],fill=col,width=5)
    mx,my=(p0[0]+p1[0])//2+off[0],(p0[1]+p1[1])//2+off[1]
    d.text((mx,my),lab,font=FS,fill=col,anchor='mm')
move((RX+40,RY+64),(WX+140,WY-46),(255,150,90),'малыши → Вася-Мама',off=(70,10))
move((TX-286,TY+42),(WX+96,WY-66),(255,110,110),'Мама → снять малышей',off=(-96,-6))

# ---------------- right column: what this fixes
CX=1000
d.text((CX,150),'ЧТО ЭТО ДАЁТ',font=FB,fill=INK)
notes=[('Малыши сидят рядом с настоящей мамой.',
        'И всё равно уползают к поддельной. Предательство\nчитается именно потому, что ползти было недалеко —\nони бросили ту, что была под рукой.'),
       ('У рывка появилась дистанция.',
        'Коврик → рабочая зона. Есть что снимать: они\nстартуют от мамы и приезжают к Васе-Маме.'),
       ('Мама встаёт со своего места дважды.',
        'За маком (кадр 117) и снимать малышей (132-133).\nОба раза — от стола к детям, один и тот же путь.'),
       ('За Ягой — ФРОНТ-плейт, и там торт.',
        'Плита клёпаная, стол прямо перед ней. Торт со\nсвечами по краю — фон для всех кадров со столом.')]
y=190
for t,b in notes:
    d.text((CX,y),'•  '+t,font=F,fill=(240,214,180)); y+=26
    for ln in b.split('\n'):
        d.text((CX+18,y),ln,font=FS,fill=DIM); y+=20
    y+=16
d.rounded_rectangle([CX-10,y+6,W-30,y+120],10,outline=(226,116,92),width=2)
d.text((CX+6,y+22),'ОТКРЫТО',font=FS,fill=(226,116,92))
d.text((CX+6,y+46),'Какая стена — back plate за Фросей?',font=FS,fill=(232,220,200))
d.text((CX+6,y+66),'См. отдельную картинку с A / B / C / D.',font=FS,fill=(232,220,200))
d.text((CX+6,y+92),'Сборка СОК из фишек — решено: целиком, но МОЛЧА.',font=FS,fill=(178,168,150))
im.save('/tmp/SCENE8_ROOM_MAP.jpg',quality=94); print('ok',im.size)
