#!/bin/bash
# v5 cast recording: parse the full-Hindi screenplay -> 59-event manifest -> record changed
# takes, copy survivors, mix choruses, render Leda voice auditions.
set -e
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep2prod
export $(grep ELEVENLABS ../../../.env)
mkdir -p takes_v5
python3 <<'PY'
import json, re, subprocess, os, shutil

# ---------- parse v5 ----------
src = open('../EP2_SCREENPLAY_v5_PROPOSED.md', encoding='utf-8').read()
body = src.split('## दृश्य 1')[1]
SP = {'कुकु':'KUKU','फ्यूरिया':'FYURIA','वैस्पर':'VESPER','दादी':'DADI','पापा':'PAPA',
      'मिटासुर':'MITASUR','लेडा':'LEDA','कुकु / फ्यूरिया / वैस्पर':'CHORUS3','फ्यूरिया / वैस्पर':'CHORUS2'}
events, scene = [], 1
for block in body.split('\n\n'):
    block = block.strip()
    if block.startswith('## दृश्य'):
        scene = int(re.search(r'दृश्य (\d+)', block).group(1)); continue
    m = re.match(r'\*\*(.+?)\*\*', block)
    if not m: continue
    name = re.sub(r'\s*\*?\(.*?\)\*?\s*', '', m.group(1)).strip()
    if name not in SP: continue
    lines = block.split('\n')[1:]
    paren = None
    text_lines = []
    for ln in lines:
        ln = ln.strip()
        pm = re.match(r'^\*\((.+?)\)\*$', ln)
        if pm and not text_lines: paren = pm.group(1); continue
        ln = re.sub(r'^\*\((.+?)\)\*$', '', ln).strip()
        if ln: text_lines.append(ln.strip('*'))
    text = ' '.join(text_lines).strip()
    if not text: continue
    if 'आआआ' in text and '!!!' in text: text = 'SHRIEK'
    events.append({'idx': len(events)+1, 'scene': scene, 'who': SP[name], 'paren': paren, 'text': text})
json.dump(events, open('ep2v5_lines.json','w'), ensure_ascii=False, indent=1)
print(f"parsed {len(events)} events")
assert len(events) == 58, [ (e['idx'], e['who'], e['text'][:20]) for e in events ]
spot = {4:'VESPER', 23:'LEDA', 34:'VESPER', 39:'CHORUS2', 53:'PAPA', 56:'FYURIA', 58:'DADI'}
for i, w in spot.items(): assert events[i-1]['who'] == w, (i, events[i-1])

# ---------- survivors ----------
KEEP = {4:'sfx_shriek1.mp3', 34:'sfx_shriek2.mp3', 18:'takes/10.mp3', 19:'takes/09.mp3',
        20:'takes/11.mp3', 22:'takes/13.mp3', 26:'takes/15.mp3', 27:'takes/16.mp3', 46:'takes/29.mp3'}
for new, old in KEEP.items():
    shutil.copy(old, f'takes_v5/{new:02d}.mp3'); print('kept', new, '<-', old)

# ---------- tags ----------
TAG = {'पढ़ते हुए, ख़ुश होकर':'[delighted]','प्यार से, कैमरे की ओर':'[warmly]','कान बजते हुए':'[dazed]',
'हँसते हुए, कैमरे की ओर':'[chuckles warmly]','धीरे से, अपने आप से':'[quietly] [sad]',
'शरारती ख़ुशी से':'[mischievously]','चमकते थैले को सीने से लगाकर':'[gleefully]',
'अपने बोर्ड को देखकर, हैरान':'[gasps] [alarmed]','धीरे से, इशारा करते हुए':'[softly]',
'गंभीर होकर, सबको पास बुलाते हुए':'[serious] [warmly]','धीरे से, अंग्रेज़ी में':'[softly]',
'धीरे-धीरे ढूँढ़ते हुए':'[hesitantly]','तुतलाती, ख़ुश':'[baby voice] [delighted]',
'निहाल होकर':'[warmly] [delighted]','नन्हे पैर जमाकर':'[bravely]','भागते हुए, चिढ़ाते हुए':'[teasing]',
'थोड़ा ऊँचा, फिर भी नरम':'[gently, a little louder]','घबराकर':'[alarmed]','छोटी-सी आवाज़ में':'[timidly]',
'ख़ुशी से उछलकर':'[excited]','हैरानी की फुसफुसाहट में':'[whispers] [amazed]','मुस्कुराते हुए':'[warmly]',
'ख़ुशी से':'[joyfully]','साफ़ आवाज़ में, हैरानी से':'[amazed]','धीरे से':'[softly]','गंभीर':'[serious]'}
def tag(p):
    if not p: return ''
    return (TAG.get(p, '') or '') + ' ' if TAG.get(p) else ''

V = {'KUKU':'NbvR1eY6Q8ivACdEO8PV','FYURIA':'FFmp1h1BMl0iVHA0JxrI','VESPER':'subIZc6skATBQ1Rbqpi7',
     'DADI':'nfMYisZqs1GOjTFllho3','PAPA':'5ycO0zpSCEkvR4Ri6gk9','MITASUR':'bBG9wwa23659EgIkMbc1'}

def gen(fname, vid, text):
    p = f'takes_v5/{fname}'
    if os.path.exists(p) and os.path.getsize(p) > 2000: print('SKIP', fname); return
    body = json.dumps({'text': text, 'model_id': 'eleven_v3'})
    subprocess.run(['curl','-s','-X','POST',
        f'https://api.elevenlabs.io/v1/text-to-speech/{vid}?output_format=mp3_44100_128',
        '-H', f'xi-api-key: {os.environ["ELEVENLABS_API_KEY"]}','-H','Content-Type: application/json',
        '-d', body, '-o', p], capture_output=True)
    print('OK' if os.path.getsize(p) > 2000 else 'FAIL', fname)

for e in events:
    i, who, text = e['idx'], e['who'], e['text']
    if text == 'SHRIEK' or i in KEEP or who == 'LEDA': continue
    if who == 'CHORUS3':
        for w in ('KUKU','FYURIA','VESPER'): gen(f'{i:02d}_{w}.mp3', V[w], tag(e['paren'])+text)
    elif who == 'CHORUS2':
        for w in ('FYURIA','VESPER'): gen(f'{i:02d}_{w}.mp3', V[w], tag(e['paren'])+text)
    else:
        gen(f'{i:02d}.mp3', V[who], tag(e['paren'])+text)

# chorus mixes
import glob
for e in events:
    i = e['idx']
    if e['who'] in ('CHORUS3','CHORUS2') and not os.path.exists(f'takes_v5/{i:02d}.mp3'):
        parts = sorted(glob.glob(f'takes_v5/{i:02d}_*.mp3'))
        if len(parts) >= 2:
            args = ['ffmpeg','-y']
            for p in parts: args += ['-i', p]
            args += ['-filter_complex', f'amix=inputs={len(parts)}:duration=longest:normalize=1,volume=2',
                     '-c:a','libmp3lame','-q:a','3', f'takes_v5/{i:02d}.mp3']
            subprocess.run(args, capture_output=True); print('mixed', i)

# ---------- Leda auditions (event 23: «म! म!») ----------
AUD = {'A_bittu':'4iqKdEXMW8NRF8USiS3Q','B_mini':'nUX4UWK0Tf1qh5zvFZWR','C_mahira':'subIZc6skATBQ1Rbqpi7'}
for label, vid in AUD.items():
    p = f'leda_audition_{label}.mp3'
    if os.path.exists(p) and os.path.getsize(p) > 2000: continue
    body = json.dumps({'text':'[baby voice] [delighted] म! म!','model_id':'eleven_v3'})
    subprocess.run(['curl','-s','-X','POST',
        f'https://api.elevenlabs.io/v1/text-to-speech/{vid}?output_format=mp3_44100_128',
        '-H', f'xi-api-key: {os.environ["ELEVENLABS_API_KEY"]}','-H','Content-Type: application/json',
        '-d', body, '-o', p], capture_output=True)
    shutil.copy(p, f'/Users/dusty/kuku-public/{p}')
    print('audition', label, os.path.getsize(p))

n = len([f for f in os.listdir('takes_v5') if re.fullmatch(r'\d\d\.mp3', f)])
print(f"TAKES_V5: {n}/57 (58 minus Leda pending voice pick)")
PY
