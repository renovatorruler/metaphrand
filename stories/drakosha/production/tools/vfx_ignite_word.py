"""Composite the author's alphabet letters onto a dubbed plate, igniting on the voice."""
import subprocess, os, sys
from PIL import Image, ImageEnhance
SRC, OUT = sys.argv[1], sys.argv[2]
ALPHA='/Users/dusty/dev/metaphrand/stories/drakosha/production/alphabet/frosya/assets'
FPS=24; H_L=120
LET=[('С',0.55,(60,100)),('А',1.15,(196,100)),('Л',2.05,(332,100)),('А',3.05,(468,100)),('Т',3.95,(604,100))]
PULSE_T=5.35; PULSE_END=6.20
def load(ch,h):
    im=Image.open(f'{ALPHA}/magic/{ch}.png').convert('RGBA'); im=im.crop(im.getbbox())
    return im.resize((int(h*im.width/im.height),h),Image.LANCZOS)
MAGIC={ch:load(ch,H_L) for ch,_,_ in LET}
BRIGHT={ch:ImageEnhance.Brightness(MAGIC[ch]).enhance(1.4) for ch,_,_ in LET}
pd='/tmp/sb8/pl'; os.makedirs(pd,exist_ok=True)
for f in os.listdir(pd): os.remove(os.path.join(pd,f))
subprocess.run(['ffmpeg','-v','error','-i',SRC,'-vsync','0',f'{pd}/f%04d.png'],check=True)
frames=sorted(os.listdir(pd))
for i,fn in enumerate(frames):
    t=i/FPS
    im=Image.open(os.path.join(pd,fn)).convert('RGBA')
    for ch,t0,(x,y) in LET:
        if t<t0: continue
        a=min(1.0,(t-t0)/0.22)
        src=BRIGHT[ch] if PULSE_T<=t<=PULSE_END else MAGIC[ch]
        L=src if a>=1.0 else Image.blend(Image.new('RGBA',src.size,(0,0,0,0)),src,a)
        im.alpha_composite(L,(x,y))
    im.convert('RGB').save(os.path.join(pd,fn))
subprocess.run(['ffmpeg','-v','error','-y','-framerate',str(FPS),'-i',f'{pd}/f%04d.png','-i',SRC,
  '-map','0:v','-map','1:a','-c:v','libx264','-pix_fmt','yuv420p','-crf','18','-c:a','copy',OUT],check=True)
print('wrote',OUT)
