#!/bin/bash
# Ep3 cast recording. Every line carries Hindi parentheticals (series law) — both the
# leading one and any mid-line ones convert to inline ElevenLabs v3 tags.
set -e
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep3prod
export $(grep ELEVENLABS ../../../.env)
mkdir -p takes
python3 <<'PY'
import json, re, subprocess, os, glob

M = json.load(open('ep3_manifest.json'))
V = {'KUKU':'NbvR1eY6Q8ivACdEO8PV','FYURIA':'FFmp1h1BMl0iVHA0JxrI','VESPER':'subIZc6skATBQ1Rbqpi7',
     'DADI':'nfMYisZqs1GOjTFllho3','MITASUR':'bBG9wwa23659EgIkMbc1','CASTOR':'4iqKdEXMW8NRF8USiS3Q',
     'LEDA':'nUX4UWK0Tf1qh5zvFZWR'}
TAG = {
'गुनगुनाते हुए, ख़ुश':'[humming happily]','दौड़ता हुआ, उत्सुक':'[excited, out of breath]','गर्व से':'[proudly]',
'अटककर, उलझन में':'[hesitating, confused]','आती हुई, चहकती':'[cheerfully]','कोशिश करते हुए':'[trying hard]',
'घबराकर':'[alarmed]','धीमे से, दूर से':'[softly]','जोश में':'[excited]','ठान कर':'[determined]',
'ताली बजाकर, तुतलाते':'[baby voice, delighted]','तुतलाती, गर्व से':'[baby voice] [proudly]',
'हँसकर':'[laughing warmly]','छोटी आवाज़ में, भावुक':'[small voice, emotional]','गर्मजोशी से':'[warmly]',
'प्यार से बुलाते हुए':'[warmly]','झेंपते हुए':'[sheepishly]','उत्साह से':'[enthusiastically]','ज़ोर से':'[loudly]',
'समझाते हुए':'[explaining patiently]','उनींदा, अंग्रेज़ी में बहककर':'[sleepy, drifting off]',
'चिढ़ाकर, प्यार से':'[teasing fondly]','मुस्कुराकर, ढूँढ़ते हुए':'[smiling, hesitant]',
'शाबाशी देते हुए':'[praising warmly]','मज़े से':'[playfully]','जीभ नचाकर':'[playfully rolling the r]',
'जीभ नचाकर, और ज़ोर से':'[rolling the r, louder]','पूरी कोशिश से':'[trying very hard]',
'हँसते हुए, प्यार से':'[laughing fondly]','उदास':'[sad]','उछलकर':'[excitedly]','दिलासा देते हुए':'[comforting, gentle]',
'प्यार से':'[lovingly]','नींद में, चौंककर':'[sleepy, startled]','उनींदी':'[drowsy]',
'धीमे, कान लगाकर':'[quietly, listening]','जागकर, हैरान':'[just woken, puzzled]','एकदम जागकर':'[suddenly wide awake]',
'चिल्लाकर':'[shouting]','शांत, साफ़':'[calm and clear]','दौड़ता हुआ आया, हाँफते':'[panting, urgent]',
'हाँफते हुए':'[panting]','चिल्लाकर, घबराकर':'[shouting, alarmed]','रुकते हुए, हाँफते, हार मानकर':'[panting, defeated]',
'शांत आवाज़, सबसे साफ़':'[calm, very clear]','चहककर':'[delighted]','चिंता से':'[worried]',
'एक साथ, पूरे भरोसे से':'[with full confidence]','हाँफते, ख़ुश':'[panting, delighted]','फुर्ती से':'[briskly]',
'जोश से':'[eagerly]','धीमे, साँस रोककर':'[hushed, holding his breath]','फुसफुसाकर':'[whispering]',
'पूरी ताक़त से':'[with all their might]','हाँफते हुए, हैरान':'[panting, amazed]','धीरे, सँभालकर':'[gently, careful]',
'डरते हुए':'[scared]','हँसकर, धीमे':'[chuckling softly]','तरस खाकर':'[with warm sympathy]','नरमी से':'[gently]',
'ऊँची, ख़ुश आवाज़ में':'[loud and joyful]','गंभीर, प्यार से':'[serious and loving]',
'काँपती, भावुक आवाज़':'[trembling, emotional]','रुककर, फिर ज़ोर से, रोता-हँसता':'[pausing, then loud, laughing through tears]',
'तालियाँ बजाते, ज़ोर से':'[cheering]','धीमे से, मिटासुर को':'[softly, warm]','हैरान':'[surprised]',
'हल्की हँसी के साथ':'[with a light laugh]','गिनवाते हुए, सीधे बच्चों से — और सुननेवालों से':'[counting out, warm]',
'गिनवाते हुए':'[counting out, warm]','ठहरकर, सयानी आवाज़ में':'[slow and wise]','धीरे से, ख़ुद से':'[quietly, to herself]',
'हँसी दबाकर':'[suppressing a laugh]','धीमी, लोरी जैसी आवाज़ में':'[soft, like a lullaby]',
'दादी की आवाज़, लोरी जैसी गुनगुनाती':'[singing a soft slow lullaby]','फिर चहककर':'[then, brightly]',
'खींचते हुए':'[straining]',
}
unknown = set()
def tagify(p):
    if not p: return ''
    t = TAG.get(p.strip())
    if t is None:
        unknown.add(p.strip()); return ''
    return t + ' '
def convert(text):
    # mid-line (परन) -> [tag]
    def sub(m):
        return tagify(m.group(1)).strip()
    return re.sub(r'\(([^)]+)\)', sub, text).strip()

def gen(fname, vid, text):
    p = f'takes/{fname}'
    if os.path.exists(p) and os.path.getsize(p) > 2000: print('SKIP', fname); return
    body = json.dumps({'text': text, 'model_id': 'eleven_v3'})
    subprocess.run(['curl','-s','-X','POST',
        f'https://api.elevenlabs.io/v1/text-to-speech/{vid}?output_format=mp3_44100_128',
        '-H', f'xi-api-key: {os.environ["ELEVENLABS_API_KEY"]}','-H','Content-Type: application/json',
        '-d', body, '-o', p], capture_output=True)
    print('OK' if os.path.getsize(p) > 2000 else 'FAIL', fname)

CHOR = {'CHORUS_ALL':['KUKU','FYURIA','VESPER','MITASUR'],
        'CHORUS_KIDS':['KUKU','FYURIA','VESPER'],
        'CHORUS_FVM':['FYURIA','VESPER','MITASUR']}
for e in M['events']:
    i, who = e['idx'], e['who']
    if who in ('KALU_SFX','REECHH_SFX'): continue  # SFX pipeline
    lead = tagify(e.get('namep'))
    text = lead + convert(e['text'])
    if who == 'DADI_SONG':
        gen(f'{i:02d}.mp3', V['DADI'], text)
    elif who in CHOR:
        for w in CHOR[who]: gen(f'{i:02d}_{w}.mp3', V[w], text)
    else:
        gen(f'{i:02d}.mp3', V[who], text)
if unknown: print('UNMAPPED PARENS:', unknown)

for e in M['events']:
    i = e['idx']
    if e['who'] in CHOR and not os.path.exists(f'takes/{i:02d}.mp3'):
        parts = sorted(glob.glob(f'takes/{i:02d}_*.mp3'))
        if len(parts) >= 2:
            args = ['ffmpeg','-y']
            for p in parts: args += ['-i', p]
            args += ['-filter_complex', f'amix=inputs={len(parts)}:duration=longest:normalize=1,volume=2',
                     '-c:a','libmp3lame','-q:a','3', f'takes/{i:02d}.mp3']
            subprocess.run(args, capture_output=True); print('mixed', i)

import re as _re
n = len([f for f in os.listdir('takes') if _re.fullmatch(r'\d\d\.mp3', f)])
print(f"TAKES: {n}/90 (95 minus 5 SFX-only events)")
PY
