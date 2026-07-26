#!/bin/bash
# Ep1 v9 — reprocess re-tagged audio, rebuild 6 story scenes, re-stitch with s4(proof)+recap.
set -e
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep1

# 1) reprocess re-rendered takes to elproc (radio/whisper EQ from flags)
while IFS=$'\t' read -r idx scene who radio whisper text; do
  case $idx in 6[0-9]|7[01]) continue;; esac   # skip s4 lines 60-71
  sz=$(wc -c < "el/$idx.mp3" 2>/dev/null | tr -d " "); [ "${sz:-0}" -gt 2000 ] || { continue; }  # skip un-rendered/quota-clobbered (keep v8 elproc)
  f="aformat=sample_rates=48000:channel_layouts=stereo"
  { [ "$who" = "RADIO" ] || [ "$who" = "MUKHIYA" ] || [ "$radio" = "1" ]; } && f="highpass=f=300,lowpass=f=3400,volume=0.85,$f"
  [ "$whisper" = "1" ] && f="volume=0.8,$f"
  ffmpeg -y -i "el/$idx.mp3" -af "$f" -c:a pcm_s16le -ar 48000 -ac 2 "elproc/$idx.wav" 2>/dev/null
done < lines.tsv
echo "reprocessed re-tagged takes"

# 2) rebuild the 6 story scenes from fresh beds + spans_v4 + fillers
cd full
python3 <<'PY'
import subprocess, json, os
def dur(p): return float(subprocess.check_output(['ffprobe','-v','quiet','-show_entries','format=duration','-of','csv=p=0',p]).strip())
def run(*a): subprocess.run(list(a),capture_output=True)
spans=json.load(open('spans_v4.json'))
rows=[l.rstrip('\n').split('\t') for l in open('../lines.tsv')]
scenes={}
for r in rows: scenes.setdefault(r[1],[]).append(int(r[0]))
for n,t in [('s035',0.35),('s060',0.6),('s120',1.2)]:
    run('ffmpeg','-y','-f','lavfi','-i','anullsrc=r=48000:cl=stereo','-t',str(t),'-c:a','pcm_s16le',f'{n}.wav')
CLIPDIR={'T1':'../../titles','T3':'../../titles','T6':'../../titles','E2':'../../titles','E3':'../../titles','E4':'../../titles'}
CLIPLEN=10.005
order=['ep1-s0-teaser','ep1-s1-akshar','ep1-s2-pilla','ep1-s3-chhupam','ep1-s5-kalu-ghar','ep1-s6-topi']
sfiles=[]
for scene in order:
    idxs=scenes[scene]
    lines=["file 's060.wav'"]; t=0.6
    for k,i in enumerate(idxs):
        if k>0: lines.append("file 's035.wav'"); t+=0.35
        lines.append(f"file '../elproc/{i}.wav'"); t+=dur(f'../elproc/{i}.wav')
    lines.append("file 's120.wav'"); t+=1.2
    open(f'bed_{scene}.txt','w').write('\n'.join(lines)+'\n')
    run('ffmpeg','-y','-f','concat','-safe','0','-i',f'bed_{scene}.txt','-c:a','pcm_s16le','-ar','48000','-ac','2',f'bed_{scene}.wav')
    old_total=spans[scene][-1][1]
    factor=dur(f'bed_{scene}.wav')/old_total
    counters={}; segsF=[]
    for s0,s1,setup in spans[scene]:
        d=(s1-s0)*factor; nn=1
        while d/nn>CLIPLEN-0.05: nn+=1
        step=d/nn
        for j in range(nn):
            if j==0: src=setup
            else:
                counters[setup]=counters.get(setup,0)+1; src=f"{setup}_f{counters[setup]}"
            segsF.append((step,src))
    seglist=[]
    for si,(d,src) in enumerate(segsF):
        base=src.split('_f')[0]
        path=f'{src}.mp4' if os.path.exists(f'{src}.mp4') else os.path.join(CLIPDIR.get(base,'.'),f'{src}.mp4')
        out=f'v9seg_{scene}_{si}.mp4'
        run('ffmpeg','-y','-i',path,'-vf','scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=30',
            '-an','-c:v','libx264','-preset','veryfast','-pix_fmt','yuv420p','-t',f'{d:.3f}',out)
        seglist.append(out)
    open(f'v9cat_{scene}.txt','w').write('\n'.join(f"file '{s}'" for s in seglist)+'\n')
    run('ffmpeg','-y','-f','concat','-safe','0','-i',f'v9cat_{scene}.txt','-c:v','libx264','-preset','veryfast','-pix_fmt','yuv420p',f'v9v_{scene}.mp4')
    v=dur(f'v9v_{scene}.mp4'); b=dur(f'bed_{scene}.wav')
    assert abs(v-b)<0.5, f'SYNC {scene} {v} {b}'
    vin=f'v9v_{scene}.mp4'
    if scene=='ep1-s1-akshar':
        st=spans[scene][2][0]*factor+0.1; en=spans[scene][2][1]*factor
        run('ffmpeg','-y','-i',vin,'-loop','1','-i','../../build/ka_overlay.png','-filter_complex',
            f'[1:v]format=rgba,fade=in:st={st:.2f}:d=0.5:alpha=1,fade=out:st={en-0.5:.2f}:d=0.5:alpha=1[ov];[0:v][ov]overlay=0:0:shortest=1[v]',
            '-map','[v]','-c:v','libx264','-preset','veryfast','-pix_fmt','yuv420p',f'v9vk_{scene}.mp4')
        vin=f'v9vk_{scene}.mp4'
    run('ffmpeg','-y','-i',vin,'-i',f'bed_{scene}.wav','-map','0:v','-map','1:a','-c:v','copy','-c:a','aac','-shortest',f'v9scene_{scene}.mp4')
    print(scene,'->',round(dur(f'v9scene_{scene}.mp4'),1),'s (delta %.2f)'%(v-b))
    sfiles.append(f'v9scene_{scene}.mp4')
# stitch: title + s0 s1 s2 s3 + s4(proof) + s5 + RECAP + s6 + credits
parts=['../../KUKU_TITLE.mp4', sfiles[0], sfiles[1], sfiles[2], sfiles[3], 'scene_s4.mp4',
       sfiles[4], '../../recap/RECAP_SEGMENT.mp4', sfiles[5], '../../KUKU_CREDITS.mp4']
lines=[]
for i,p in enumerate(parts):
    run('ffmpeg','-y','-i',p,'-vf','scale=1280:720,setsar=1,fps=30','-c:v','libx264','-preset','veryfast','-pix_fmt','yuv420p','-c:a','aac','-ar','48000','-ac','2',f'v9part{i}.mp4')
    lines.append(f"file 'v9part{i}.mp4'")
open('v9final_cat.txt','w').write('\n'.join(lines)+'\n')
run('ffmpeg','-y','-f','concat','-safe','0','-i','v9final_cat.txt','-c','copy','-movflags','+faststart','../../KUKU_EP1_FULL.mp4')
d=dur('../../KUKU_EP1_FULL.mp4')
print('FULL v9:', f'{int(d)//60}:{int(d)%60:02d}')
PY
cp ../../KUKU_EP1_FULL.mp4 /Users/dusty/kuku-serve/KUKU_EP1_FULL_v9.mp4
curl -s -o /dev/null -w "v9 live: HTTP %{http_code}\n" "https://dustys-mac-studio.tail9e29c.ts.net/kuku/KUKU_EP1_FULL_v9.mp4"
