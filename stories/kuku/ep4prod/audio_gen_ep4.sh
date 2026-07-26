#!/bin/bash
# Ep4 cast recording — tags converted via the author's TAG_MAP contract (tagmap.json).
set -e
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep4prod
export $(grep ELEVENLABS ../../../.env)
mkdir -p takes
python3 <<'PY'
import json, re, subprocess, os, glob
M=json.load(open('ep4_manifest.json')); TM=json.load(open('tagmap.json'))
TAGS=TM['tags']; VIS=set(v for v in TM['visual'] if v)
V={'KUKU':'NbvR1eY6Q8ivACdEO8PV','FYURIA':'FFmp1h1BMl0iVHA0JxrI','VESPER':'subIZc6skATBQ1Rbqpi7',
   'DADI':'nfMYisZqs1GOjTFllho3','MITASUR':'bBG9wwa23659EgIkMbc1','CASTOR':'4iqKdEXMW8NRF8USiS3Q',
   'LEDA':'nUX4UWK0Tf1qh5zvFZWR'}
unknown=set()
def hindi_tag(p):
    if not p: return ''
    p=p.strip()
    if p in TAGS: return TAGS[p]+' '
    if p in VIS: return ''
    # multi-part: try comma halves (vocal half wins per the contract)
    parts=[x.strip() for x in p.split(',')]
    found=[TAGS[x] for x in parts if x in TAGS]
    if found: return ' '.join(found)+' '
    if all(x in VIS for x in parts): return ''
    unknown.add(p); return ''
def convert(text):
    return re.sub(r'\(([^)]+)\)', lambda m: hindi_tag(m.group(1)).strip(), text).strip()
def gen(fname,vid,text):
    p=f'takes/{fname}'
    if os.path.exists(p) and os.path.getsize(p)>2000: print('SKIP',fname); return
    subprocess.run(['curl','-s','-X','POST',f'https://api.elevenlabs.io/v1/text-to-speech/{vid}?output_format=mp3_44100_128',
      '-H',f'xi-api-key: {os.environ["ELEVENLABS_API_KEY"]}','-H','Content-Type: application/json',
      '-d',json.dumps({'text':text,'model_id':'eleven_v3'}),'-o',p],capture_output=True)
    print('OK' if os.path.getsize(p)>2000 else 'FAIL',fname)
CHOR={'CHORUS_ALL':['KUKU','FYURIA','VESPER','MITASUR'],'CHORUS_KIDS':['KUKU','FYURIA','VESPER']}
for e in M['events']:
    i,who=e['idx'],e['who']
    if who.endswith('_SFX'): continue
    text=hindi_tag(e.get('namep'))+convert(e['text'])
    if who in CHOR:
        for w in CHOR[who]: gen(f'{i:02d}_{w}.mp3',V[w],text)
    else: gen(f'{i:02d}.mp3',V[who],text)
if unknown: print('UNMAPPED (add to TAG_MAP):',unknown)
for e in M['events']:
    i=e['idx']
    if e['who'] in CHOR and not os.path.exists(f'takes/{i:02d}.mp3'):
        parts=sorted(glob.glob(f'takes/{i:02d}_*.mp3'))
        if len(parts)>=2:
            a=['ffmpeg','-y']
            for p in parts: a+=['-i',p]
            a+=['-filter_complex',f'amix=inputs={len(parts)}:duration=longest:normalize=1,volume=2','-c:a','libmp3lame','-q:a','3',f'takes/{i:02d}.mp3']
            subprocess.run(a,capture_output=True); print('mixed',i)
n=len([f for f in os.listdir('takes') if re.fullmatch(r'\d\d\.mp3',f)])
print(f"TAKES: {n}/77 (83 minus 6 SFX events)")
PY
