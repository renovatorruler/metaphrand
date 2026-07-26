#!/bin/bash
# Ep1 v9b — robust rebuild: fill each scene's (longer, re-tagged) bed by greedily tiling
# from ALL that scene's existing footage. No stretch (≤9.4s cuts), no adjacent repeats,
# varied offsets. क overlay timed to the reveal LINE, not a specific clip. No new clips.
set -e
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep1

# 1) reprocess re-tagged takes to elproc (only valid; keeps v8 for any missing)
while IFS=$'\t' read -r idx scene who radio whisper text; do
  case $idx in 6[0-9]|7[01]) continue;; esac
  sz=$(wc -c < "el/$idx.mp3" 2>/dev/null | tr -d " "); [ "${sz:-0}" -gt 2000 ] || continue
  f="aformat=sample_rates=48000:channel_layouts=stereo"
  { [ "$who" = "RADIO" ] || [ "$who" = "MUKHIYA" ] || [ "$radio" = "1" ]; } && f="highpass=f=300,lowpass=f=3400,volume=0.85,$f"
  [ "$whisper" = "1" ] && f="volume=0.8,$f"
  ffmpeg -y -i "el/$idx.mp3" -af "$f" -c:a pcm_s16le -ar 48000 -ac 2 "elproc/$idx.wav" 2>/dev/null
done < lines.tsv
echo "reprocessed re-tagged takes"

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
def clip_path(name):
    if os.path.exists(f'{name}.mp4'): return f'{name}.mp4'
    base=name.split('_f')[0]
    return os.path.join(CLIPDIR.get(base,'.'),f'{name}.mp4')
CUT=9.4; CLIPLEN=10.005
order=['ep1-s0-teaser','ep1-s1-akshar','ep1-s2-pilla','ep1-s3-chhupam','ep1-s5-kalu-ghar','ep1-s6-topi']
sfiles=[]
for scene in order:
    # bed + per-line positions
    idxs=scenes[scene]
    lines=["file 's060.wav'"]; t=0.6; linepos={}
    for k,i in enumerate(idxs):
        if k>0: lines.append("file 's035.wav'"); t+=0.35
        linepos[i]=t; lines.append(f"file '../elproc/{i}.wav'"); t+=dur(f'../elproc/{i}.wav')
    lines.append("file 's120.wav'"); t+=1.2
    open(f'bed_{scene}.txt','w').write('\n'.join(lines)+'\n')
    run('ffmpeg','-y','-f','concat','-safe','0','-i',f'bed_{scene}.txt','-c:a','pcm_s16le','-ar','48000','-ac','2',f'bed_{scene}.wav')
    bed=dur(f'bed_{scene}.wav')
    # pool: setups in story order + their existing fillers
    seen=[]
    for s0,s1,setup in spans[scene]:
        if setup not in seen: seen.append(setup)
    pool=[]
    for setup in seen:
        pool.append(setup); k=1
        while os.path.exists(clip_path(f'{setup}_f{k}')): pool.append(f'{setup}_f{k}'); k+=1
    # greedy tile bed: ≤CUT each, no adjacent same, varied offset per reuse
    segs=[]; remaining=bed; i=0; last=None; use={}
    while remaining>0.05:
        clip=pool[i%len(pool)]
        if clip==last and len(pool)>1: i+=1; clip=pool[i%len(pool)]
        cut=min(remaining, CUT)
        k=use.get(clip,0); use[clip]=k+1
        off=min(k*2.3, max(0.0, CLIPLEN-cut-0.05))
        segs.append((clip,round(cut,3),round(off,3))); remaining-=cut; last=clip; i+=1
    # render segments
    seglist=[]
    for si,(clip,d,off) in enumerate(segs):
        out=f'w9seg_{scene}_{si}.mp4'; cmd=['ffmpeg','-y']
        if off>0: cmd+=['-ss',f'{off:.3f}']
        cmd+=['-i',clip_path(clip),'-vf','scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=30',
              '-an','-c:v','libx264','-preset','veryfast','-pix_fmt','yuv420p','-t',f'{d:.3f}',out]
        run(*cmd); seglist.append(out)
    open(f'w9cat_{scene}.txt','w').write('\n'.join(f"file '{s}'" for s in seglist)+'\n')
    run('ffmpeg','-y','-f','concat','-safe','0','-i',f'w9cat_{scene}.txt','-c:v','libx264','-preset','veryfast','-pix_fmt','yuv420p',f'w9v_{scene}.mp4')
    v=dur(f'w9v_{scene}.mp4')
    assert abs(v-bed)<0.5, f'SYNC {scene} {v} {bed}'
    vin=f'w9v_{scene}.mp4'
    if scene=='ep1-s1-akshar':
        st=linepos[8]+1.4; en=linepos[10]  # reveal line 8 → just before Furia's line 10
        run('ffmpeg','-y','-i',vin,'-loop','1','-i','../../build/ka_overlay.png','-filter_complex',
            f'[1:v]format=rgba,fade=in:st={st:.2f}:d=0.5:alpha=1,fade=out:st={en-0.5:.2f}:d=0.5:alpha=1[ov];[0:v][ov]overlay=0:0:shortest=1[v]',
            '-map','[v]','-c:v','libx264','-preset','veryfast','-pix_fmt','yuv420p',f'w9vk_{scene}.mp4')
        vin=f'w9vk_{scene}.mp4'
    run('ffmpeg','-y','-i',vin,'-i',f'bed_{scene}.wav','-map','0:v','-map','1:a','-c:v','copy','-c:a','aac','-shortest',f'w9scene_{scene}.mp4')
    print(scene,'->',round(dur(f'w9scene_{scene}.mp4'),1),'s (', len(segs),'cuts from',len(pool),'clips )')
    sfiles.append(f'w9scene_{scene}.mp4')
parts=['../../KUKU_TITLE.mp4', sfiles[0], sfiles[1], sfiles[2], sfiles[3], 'scene_s4.mp4',
       sfiles[4], '../../recap/RECAP_SEGMENT.mp4', sfiles[5], '../../KUKU_CREDITS.mp4']
lines=[]
for i,p in enumerate(parts):
    run('ffmpeg','-y','-i',p,'-vf','scale=1280:720,setsar=1,fps=30','-c:v','libx264','-preset','veryfast','-pix_fmt','yuv420p','-c:a','aac','-ar','48000','-ac','2',f'w9part{i}.mp4')
    lines.append(f"file 'w9part{i}.mp4'")
open('w9final_cat.txt','w').write('\n'.join(lines)+'\n')
run('ffmpeg','-y','-f','concat','-safe','0','-i','w9final_cat.txt','-c','copy','-movflags','+faststart','../../KUKU_EP1_FULL.mp4')
d=dur('../../KUKU_EP1_FULL.mp4')
print('FULL v9:', f'{int(d)//60}:{int(d)%60:02d}')
PY
cp ../../KUKU_EP1_FULL.mp4 /Users/dusty/kuku-serve/KUKU_EP1_FULL_v9.mp4
curl -s -o /dev/null -w "v9 live: HTTP %{http_code}\n" "https://dustys-mac-studio.tail9e29c.ts.net/kuku/KUKU_EP1_FULL_v9.mp4"
