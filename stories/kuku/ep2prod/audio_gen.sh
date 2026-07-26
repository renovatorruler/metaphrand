#!/bin/bash
# Ep2 cast recording from the author's screenplay. Parentheticals -> v3 tags.
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep2prod
export $(grep ELEVENLABS ../../../.env)
mkdir -p takes
python3 <<'PY'
import json, subprocess, os, re
lines=json.load(open('ep2_lines.json'))
V={'KUKU':'NbvR1eY6Q8ivACdEO8PV','FYURIA':'FFmp1h1BMl0iVHA0JxrI','VESPER':'subIZc6skATBQ1Rbqpi7',
   'DADI':'nfMYisZqs1GOjTFllho3','PAPA':'5ycO0zpSCEkvR4Ri6gk9','MITASUR':'bBG9wwa23659EgIkMbc1'}
TAGMAP={'reading, delighted':'[delighted]','ears ringing':'[dazed]','chuckling, to camera':'[chuckles warmly]',
'quiet, to himself':'[quietly] [sad]','small':'[timidly]','a whisper of wonder':'[whispers] [amazed]',
'soft':'[softly]','soft, in English':'[softly]','alarm':'[alarmed]','grinning':'[proudly]',
'reaching, finding it':'[hesitantly]','to camera, warm':'[warmly]','planting his little feet':'[bravely]',
'a little louder, still gentle':'[gently, a little louder]','startled colossal scream':None,
'colossal scream to be heard':None}
def tag(p):
    if not p: return ''
    if p in TAGMAP: return (TAGMAP[p] or '')+' '
    return f'[{p.split(",")[0].strip()}] '
def gen(fname,vid,text):
    if os.path.exists(f'takes/{fname}') and os.path.getsize(f'takes/{fname}')>2000:
        print('SKIP',fname); return
    payload=json.dumps({'text':text,'model_id':'eleven_v3'})
    subprocess.run(['curl','-s','-X','POST',
      f'https://api.elevenlabs.io/v1/text-to-speech/{vid}?output_format=mp3_44100_128',
      '-H',f'xi-api-key: {os.environ["ELEVENLABS_API_KEY"]}','-H','Content-Type: application/json',
      '-d',payload,'-o',f'takes/{fname}'],capture_output=True)
    ok=os.path.getsize(f'takes/{fname}')>2000
    print('OK' if ok else 'FAIL',fname)
for l in lines:
    i=l['idx']; who=l['who']; text=l['text']
    if text=='SHRIEK':
        gen(f'{i:02d}.mp3', V['VESPER'], '[screaming at the top of his lungs, long] आआआआआआआआआ!')
    elif who=='CHORUS3':
        for w in ['KUKU','FYURIA','VESPER']: gen(f'{i:02d}_{w}.mp3', V[w], tag(l['paren'])+text)
    elif who=='CHORUS2':
        for w in ['FYURIA','VESPER']: gen(f'{i:02d}_{w}.mp3', V[w], tag(l['paren'])+text)
    else:
        gen(f'{i:02d}.mp3', V[who], tag(l['paren'])+text)
print('done')
PY
# mix chorus components
python3 <<'PY'
import json, subprocess, os, glob
lines=json.load(open('ep2_lines.json'))
for l in lines:
    i=l['idx']
    if l['who'] in ('CHORUS3','CHORUS2'):
        parts=sorted(glob.glob(f'takes/{i:02d}_*.mp3'))
        if len(parts)>=2 and not os.path.exists(f'takes/{i:02d}.mp3'):
            args=['ffmpeg','-y']
            for p in parts: args+=['-i',p]
            n=len(parts)
            args+=['-filter_complex', f'amix=inputs={n}:duration=longest:normalize=1,volume={min(n,2)}','-c:a','libmp3lame','-q:a','3',f'takes/{i:02d}.mp3']
            subprocess.run(args,capture_output=True)
            print('mixed',i)
PY
echo "TAKES: $(ls takes/[0-9][0-9].mp3 2>/dev/null | wc -l | tr -d ' ')/40"
