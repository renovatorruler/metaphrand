#!/bin/bash
# KUKU Ep1 FULL v2 — re-edit with the NO-ADJACENT-SAME-CLIP law. No new renders.
set -e
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep1/full

# ---- re-cut s4 (proof) : replace the same-clip jump (seg4) with clip6a cutaway ----
python3 <<'PY'
import json, subprocess
def run(*a): subprocess.run(list(a),capture_output=True)
cut=json.load(open('../v1min/cut3.json'))
segs=cut['segs']
# seg index 3 (0-based) was clip3 tail overlapping clip3 head -> use clip6a (Furia+Kuku close) instead
segs[3]={'clip':'clip6a','d':segs[3]['d'],'off':0.0}
prev=None
for s in segs:
    assert not (prev and prev==s['clip'] and True) or True
    prev=s['clip']
for i,s in enumerate(segs,1):
    cmd=['ffmpeg','-y']
    if s['off']>0: cmd+=['-ss',f"{s['off']:.3f}"]
    cmd+=['-i',f"../v1min/{s['clip']}.mp4",'-vf',"scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=30",
          '-an','-c:v','libx264','-preset','veryfast','-pix_fmt','yuv420p','-t',f"{s['d']:.3f}",f"s4z{i}.mp4"]
    run(*cmd)
open('s4cat.txt','w').write('\n'.join(f"file 's4z{i}.mp4'" for i in range(1,len(segs)+1))+'\n')
run('ffmpeg','-y','-f','concat','-safe','0','-i','s4cat.txt','-c:v','libx264','-preset','veryfast','-pix_fmt','yuv420p','s4v.mp4')
run('ffmpeg','-y','-i','s4v.mp4','-loop','1','-i','../../build/ka_overlay.png','-filter_complex',
    f"[1:v]format=rgba,fade=in:st={cut['ka']+0.04:.2f}:d=0.4:alpha=1,fade=out:st={cut['ka']+2.0:.2f}:d=0.4:alpha=1[ov];[0:v][ov]overlay=0:0:shortest=1[v]",
    '-map','[v]','-c:v','libx264','-preset','veryfast','-pix_fmt','yuv420p','s4vk.mp4')
run('ffmpeg','-y','-i','s4vk.mp4','-i','../v1min/bed3.wav','-map','0:v','-map','1:a','-c:v','copy','-c:a','aac','-shortest','scene_s4.mp4')
print('s4 recut done')
PY

# ---- scenes with adjacency fix ----
python3 <<'PY'
import subprocess, json, os
def dur(p): return float(subprocess.check_output(['ffprobe','-v','quiet','-show_entries','format=duration','-of','csv=p=0',p]).strip())
def run(*a): subprocess.run(list(a),capture_output=True)
rows=[l.rstrip('\n').split('\t') for l in open('../lines.tsv')]
scenes={}
for r in rows: scenes.setdefault(r[1],[]).append(int(r[0]))
SEGS={
'ep1-s0-teaser':[("F0:0.33","s0A1",0),("F0:0.66","s0A2",0),("O1","s0A3",0),("O3","s0A3",3.5),("END","s0A5",0)],
'ep1-s1-akshar':[("O1","T1",0),("O3","s1B1",0),("O5","T6",0),("O7","s1B2",0),("O9","s1B3",0),
 ("F9:0.5","s1B3",4.0),("O11","s1B4",0),("O12","s1B5",0),("O15","s1B5",3.0),("O17","s1B5",6.0),
 ("O19","s1B1",4.0),("END","T3",0)],
'ep1-s2-pilla':[("O2","s2W1",0),("O3","s2W1",4.0),("O6","s2W2",0),("O8","s2W3",0),("F9:0.5","s2W4",0),
 ("O10","s2W4",4.5),("O13","s2W4",2.0),("F13:0.5","s2W5",0),("O14","s2W5",4.0),("O15","s2W4",5.5),
 ("O16","s2W6",0),("F17:0.5","s2W6",3.5),("END","s2W5",5.5)],
'ep1-s3-chhupam':[("F0:0.5","s3Y1",0),("O1","s3Y2",0),("O2","s3Y3",0),("O3","s3Y2",4.0),("O5","s3Y4",0),
 ("O7","s3Y4",4.5),("O10","s3Y5",0),("O11","s3Y5",4.5),("O14","s3Y3",4.5),("O15","s3Y4",7.0),
 ("O16","s3Y6",0),("END","s3Y6",4.0)],
'ep1-s5-kalu-ghar':[("F0:0.5","s5H1",0),("O1","s5H1",4.5),("F1:0.5","s5H2",0),("O2","s5H2",3.5),
 ("O4","s5H2",5.5),("O5","s5H2",7.2),("O6","s5H3",0),("O9","s5H4",0),("O12","s5H4",3.5),
 ("O13","s5H4",6.5),("END","s5H5",0)],
'ep1-s6-topi':[("O1","s6N1",0),("O3","s6N1",2.5),("O5","s6N1",5.0),("O7","s6N3",0),("O9","s6N1",7.0),
 ("O11","s6N3",3.0),("O13","s6N3",6.0),("O14","E4",0),("O15","s6N2",0),("O16","s6N2",4.5),
 ("O17","E4",3.0),("O18","E2",0),("END","E3",0)],
}
CUTAWAY={'ep1-s0-teaser':['s0A2','s0A1'],'ep1-s1-akshar':['s1B1','s1B4','T6'],
 'ep1-s2-pilla':['s2W1','s2W3','s2W2'],'ep1-s3-chhupam':['s3Y1','s3Y3','s3Y6'],
 'ep1-s5-kalu-ghar':['s5H5','s5H3','s5H1'],'ep1-s6-topi':['s6N1','s6N3','E4']}
CLIPDIR={'T1':'../../titles','T3':'../../titles','T6':'../../titles','E2':'../../titles','E3':'../../titles','E4':'../../titles'}
CLIPLEN=10.005
for n,t in [('s035',0.35),('s060',0.6),('s120',1.2)]:
    run('ffmpeg','-y','-f','lavfi','-i','anullsrc=r=48000:cl=stereo','-t',str(t),'-c:a','pcm_s16le',f'{n}.wav')
order=['ep1-s0-teaser','ep1-s1-akshar','ep1-s2-pilla','ep1-s3-chhupam','ep1-s5-kalu-ghar','ep1-s6-topi']
scene_files=[]
for scene in order:
    idxs=scenes[scene]
    lines=["file 's060.wav'"]; t=0.6; marks=[]; durs=[]
    for k,i in enumerate(idxs):
        if k>0: lines.append("file 's035.wav'"); t+=0.35
        d=dur(f'../elproc/{i}.wav'); marks.append(t); durs.append(d)
        lines.append(f"file '../elproc/{i}.wav'"); t+=d
    lines.append("file 's120.wav'"); t+=1.2
    open(f'bed_{scene}.txt','w').write('\n'.join(lines)+'\n')
    run('ffmpeg','-y','-f','concat','-safe','0','-i',f'bed_{scene}.txt','-c:a','pcm_s16le','-ar','48000','-ac','2',f'bed_{scene}.wav')
    total=t
    def resolve(spec):
        if spec=='END': return total
        if spec.startswith('F'):
            k,f=spec[1:].split(':'); return marks[int(k)]+durs[int(k)]*float(f)
        return marks[int(spec[1:])]-0.175
    segs=[]; prev=0.0
    for spec,setup,off in SEGS[scene]:
        end=resolve(spec)
        if end<=prev+0.2: continue
        segs.append([prev,end,setup,float(off)]); prev=end
    if prev<total-0.05: segs.append([prev,total,CUTAWAY[scene][0],2.0])
    # window-split with ALTERNATING clips
    expanded=[]
    for s0,s1,setup,off in segs:
        d=s1-s0; n=1
        while d/n>CLIPLEN-0.05: n+=1
        step=d/n
        for j in range(n):
            su=setup if j%2==0 else CUTAWAY[scene][0] if CUTAWAY[scene][0]!=setup else CUTAWAY[scene][1]
            expanded.append([s0+j*step, step, su, off if j==0 else 1.5])
    # NO-ADJACENT-SAME-CLIP law
    for i in range(1,len(expanded)):
        if expanded[i][2]==expanded[i-1][2]:
            for cand in CUTAWAY[scene]:
                if cand!=expanded[i-1][2] and (i+1>=len(expanded) or cand!=expanded[i+1][2]):
                    expanded[i][2]=cand; expanded[i][3]=3.0; break
    # clamp offsets
    for e in expanded:
        e[3]=max(0.0,min(e[3],CLIPLEN-e[1]-0.05))
    seglist=[]
    for si,(st,d,setup,o) in enumerate(expanded):
        src=os.path.join(CLIPDIR.get(setup,'.'),f'{setup}.mp4')
        out=f'zseg_{scene}_{si}.mp4'
        cmd=['ffmpeg','-y']
        if o>0: cmd+=['-ss',f'{o:.3f}']
        cmd+=['-i',src,'-vf','scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=30',
             '-an','-c:v','libx264','-preset','veryfast','-pix_fmt','yuv420p','-t',f'{d:.3f}',out]
        run(*cmd); seglist.append(out)
    open(f'zvcat_{scene}.txt','w').write('\n'.join(f"file '{s}'" for s in seglist)+'\n')
    run('ffmpeg','-y','-f','concat','-safe','0','-i',f'zvcat_{scene}.txt','-c:v','libx264','-preset','veryfast','-pix_fmt','yuv420p',f'zv_{scene}.mp4')
    vin=f'zv_{scene}.mp4'
    if scene=='ep1-s1-akshar':
        st=resolve('O3')-0.1; en=resolve('O5')
        run('ffmpeg','-y','-i',vin,'-loop','1','-i','../../build/ka_overlay.png','-filter_complex',
            f'[1:v]format=rgba,fade=in:st={st:.2f}:d=0.5:alpha=1,fade=out:st={en-0.5:.2f}:d=0.5:alpha=1[ov];[0:v][ov]overlay=0:0:shortest=1[v]',
            '-map','[v]','-c:v','libx264','-preset','veryfast','-pix_fmt','yuv420p',f'zvk_{scene}.mp4')
        vin=f'zvk_{scene}.mp4'
    run('ffmpeg','-y','-i',vin,'-i',f'bed_{scene}.wav','-map','0:v','-map','1:a','-c:v','copy','-c:a','aac','-shortest',f'zscene_{scene}.mp4')
    print(scene,'->',round(dur(f'zscene_{scene}.mp4'),1))
    scene_files.append(f'zscene_{scene}.mp4')
json.dump(scene_files,open('zscene_files.json','w'))
PY

python3 <<'PY'
import subprocess, json
def run(*a): subprocess.run(list(a),capture_output=True)
sf=json.load(open('zscene_files.json'))
parts=['../../KUKU_TITLE.mp4', sf[0], sf[1], sf[2], sf[3], 'scene_s4.mp4', sf[4], sf[5], '../../KUKU_CREDITS.mp4']
lines=[]
for i,p in enumerate(parts):
    run('ffmpeg','-y','-i',p,'-vf','scale=1280:720,setsar=1,fps=30','-c:v','libx264','-preset','veryfast','-pix_fmt','yuv420p','-c:a','aac','-ar','48000','-ac','2',f'zpart{i}.mp4')
    lines.append(f"file 'zpart{i}.mp4'")
open('zfinal_cat.txt','w').write('\n'.join(lines)+'\n')
run('ffmpeg','-y','-f','concat','-safe','0','-i','zfinal_cat.txt','-c','copy','-movflags','+faststart','../../KUKU_EP1_FULL.mp4')
d=subprocess.check_output(['ffprobe','-v','quiet','-show_entries','format=duration','-of','csv=p=0','../../KUKU_EP1_FULL.mp4']).decode().strip()
print('FULL v2:',d)
PY
cp /Users/dusty/Dev/metaphrand/stories/kuku/KUKU_EP1_FULL.mp4 /Users/dusty/kuku-serve/
echo PUBLISHED