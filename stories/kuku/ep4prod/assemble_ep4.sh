#!/bin/bash
# Ep3 assembly — the Ep2 v5 machine generalized: SFX ride the timeline as events
# (ducking the score like dialogue), fx overlays stack per segment, card sequences
# are generic, cues may live in ep2prod (reused leitmotifs) with per-scene seek.
set -e
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep4prod
python3 <<'PY'
import json, subprocess, os

EDL   = json.load(open('ep4_edl.json'))
DURS  = json.load(open('ep4_durs.json'))
TAKED = {int(k): v for k, v in DURS['takes'].items()}
SFXD  = DURS['sfx']
BUILD, OUT = 'build', 'out'
os.makedirs(BUILD, exist_ok=True); os.makedirs(OUT, exist_ok=True)
W, H, FPS = 1280, 720, 24
LEAD, GAP, TAIL = 0.5, 0.45, 0.6

def run(args):
    r = subprocess.run(args, capture_output=True, text=True)
    if r.returncode != 0:
        raise SystemExit(f"FFMPEG FAIL: {' '.join(args)}\n{r.stderr[-1200:]}")

def probe(path):
    return float(subprocess.run(['ffprobe','-v','error','-show_entries','format=duration',
        '-of','csv=p=0',path],capture_output=True,text=True).stdout.strip())

def vsrc(seg):
    s = seg['src']
    if s.startswith('still:'): return 'still', f"stills/{s[6:]}.png"
    if s.startswith('clip:'):  return 'clip',  f"clips/{s[5:]}.mp4"
    if s.startswith('file:'):  return 'clip',  s[5:]
    if s.startswith('card:'):  return 'card',  f"cards/{s[5:]}.png"
    if s == 'seq':             return 'seq',   None
    raise SystemExit(f"bad src {s}")

def ev_dur(tk):
    if 'i' in tk: return TAKED[tk['i']]
    return SFXD[tk['sfx']]

def ev_path(tk):
    if 'i' in tk: return f"takes/{tk['i']:02d}.mp3"
    return f"sfx/{tk['sfx']}.mp3"

def place_takes(seg):
    t = 0.0; placed = []
    for tk in seg.get('takes', []):
        at = tk['at'] if 'at' in tk else (LEAD if not placed else t + GAP)
        d = ev_dur(tk)
        placed.append({'tk': tk, 'at': at, 'end': at + d, 'duck': 'i' in tk or tk.get('duck', True)})
        t = max(t, at + d)
    need = (max(p['end'] for p in placed) + TAIL) if placed else 0.0
    return placed, need

def seg_duration(seg):
    placed, need = place_takes(seg)
    if seg.get('bridge'):
        return round(seg['dur'], 3), placed
    dur = max(seg.get('dur', 0.0), need)
    if dur <= 0: raise SystemExit(f"segment with no duration: {seg['src']}")
    return round(dur, 3), placed

def render_seg(scene, si, seg, dur):
    out = f"{BUILD}/{scene}_{si:02d}.mp4"
    base = f"{BUILD}/{scene}_{si:02d}_base.mp4"
    tgt = base if seg.get('fx') else out
    kind, path = vsrc(seg)
    n = max(2, round(dur * FPS))
    if kind == 'clip':
        src_len = probe(path)
        if seg.get('in', 0.0) + dur > src_len + 0.05:
            raise SystemExit(f"SHOT OVERFLOW: {scene}#{si} {seg['src']} needs {seg.get('in',0)+dur:.2f}s but source is {src_len:.2f}s — replan")
    if not (seg.get('fx') and os.path.exists(out)) and not os.path.exists(tgt):
        if kind == 'still':
            vf = (f"scale=3840:2160,zoompan=z='1+0.085*on/{n-1}'"
                  f":x='(iw-iw/zoom)/2':y='(ih-ih/zoom)/2':d={n}:s={W}x{H}:fps={FPS},format=yuv420p")
            run(['ffmpeg','-y','-i',path,'-vf',vf,'-frames:v',str(n),'-c:v','libx264','-crf','18','-an',tgt])
        elif kind == 'card':
            run(['ffmpeg','-y','-loop','1','-i',path,'-t',f"{dur}",
                 '-vf',f"scale={W}:{H},fps={FPS},format=yuv420p",'-c:v','libx264','-crf','18','-an',tgt])
        elif kind == 'clip':
            fade = f",fade=t=out:st={dur-seg['fadeout']}:d={seg['fadeout']}" if seg.get('fadeout') else ""
            run(['ffmpeg','-y','-i',path,'-ss',f"{seg.get('in',0.0)}",'-t',f"{dur}",
                 '-vf',f"fps={FPS},scale={W}:{H}{fade},format=yuv420p",'-c:v','libx264','-crf','18','-an',tgt])
        elif kind == 'seq':
            cards = seg['cards']; rest = dur / len(cards)
            with open(f'{BUILD}/{scene}_{si:02d}_cat.txt','w') as f:
                for k, c in enumerate(cards):
                    pp = f"{BUILD}/{scene}_{si:02d}_p{k}.mp4"
                    run(['ffmpeg','-y','-loop','1','-i',f'cards/{c}.png','-t',f"{rest:.3f}",
                         '-vf',f"scale={W}:{H},fps={FPS},format=yuv420p",'-c:v','libx264','-crf','18','-an',pp])
                    f.write(f"file '{scene}_{si:02d}_p{k}.mp4'\n")
            run(['ffmpeg','-y','-f','concat','-safe','0','-i',f'{BUILD}/{scene}_{si:02d}_cat.txt','-c','copy',tgt])
    if seg.get('fx') and not os.path.exists(out):
        args = ['ffmpeg','-y','-i',base]
        for fx in seg['fx']: args += ['-loop','1','-i',fx['png']]
        fc = []; prev = '0:v'
        for k, fx in enumerate(seg['fx']):
            px = int(W * fx['scale'])
            pos = {'tc': "(W-w)/2:H*0.08", 'c': "(W-w)/2:(H-h)/2", 'bc': "(W-w)/2:H*0.58"}[fx.get('pos','tc')]
            fc.append(f"[{k+1}:v]format=rgba,scale={px}:-1,fade=t=in:st={fx['at']}:d=0.5:alpha=1[f{k}]")
            fc.append(f"[{prev}][f{k}]overlay={pos}:shortest=1[a{k}]"); prev = f'a{k}'
        fc.append(f"[{prev}]format=yuv420p[ov]")
        run(args + ['-filter_complex', ';'.join(fc), '-map','[ov]','-c:v','libx264','-crf','18','-an',out])
    return out

def scene_assets_ok(sc):
    missing = []
    for seg in sc['segments']:
        kind, path = vsrc(seg)
        if path and not os.path.exists(path): missing.append(path)
        if kind == 'seq':
            for c in seg['cards']:
                if not os.path.exists(f'cards/{c}.png'): missing.append(c)
        for tk in seg.get('takes', []):
            if 'i' in tk and tk['i'] not in TAKED: missing.append(f"take {tk['i']}")
            if 'sfx' in tk and tk['sfx'] not in SFXD: missing.append(f"sfx {tk['sfx']}")
        for fx in seg.get('fx', []):
            if not os.path.exists(fx['png']): missing.append(fx['png'])
    return missing

scene_files, report, skipped = [], [], []
for sc in EDL['scenes']:
    name = sc['name']
    missing = scene_assets_ok(sc)
    if missing:
        skipped.append(f"{name}: missing {missing}"); continue
    segs, clock, events = [], 0.0, []
    for si, seg in enumerate(sc['segments']):
        dur, placed = seg_duration(seg)
        segs.append(render_seg(name, si, seg, dur))
        for p in placed:
            events.append({'path': ev_path(p['tk']), 'abs': clock + p['at'], 'end': clock + p['end'], 'duck': p['duck']})
        clock += dur
    S = round(clock, 3)

    with open(f'{BUILD}/{name}_cat.txt','w') as f:
        for s in segs: f.write(f"file '{os.path.basename(s)}'\n")
    run(['ffmpeg','-y','-f','concat','-safe','0','-i',f'{BUILD}/{name}_cat.txt','-c','copy',f'{BUILD}/{name}_v.mp4'])

    if events:
        args = ['ffmpeg','-y']
        for e in events: args += ['-i', e['path']]
        chains, mix = [], []
        for k, e in enumerate(events):
            chains.append(f"[{k}:a]aresample=44100,adelay={int(e['abs']*1000)}:all=1[d{k}]")
            mix.append(f"[d{k}]")
        fc = ';'.join(chains) + f";{''.join(mix)}amix=inputs={len(events)}:duration=longest:normalize=0,atrim=0:{S},apad=whole_dur={S}[out]"
        run(args + ['-filter_complex', fc, '-map','[out]','-ac','2','-ar','44100', f'{BUILD}/{name}_dlg.wav'])

    windows = []
    for e in sorted([e for e in events if e['duck']], key=lambda x: x['abs']):
        a, b = max(0, e['abs']-0.15), e['end']+0.25
        if windows and a - windows[-1][1] < 0.3: windows[-1][1] = b
        else: windows.append([a, b])
    base_v = sc.get('score_vol', 0.5)
    duck = '+'.join(f"between(t,{a:.2f},{b:.2f})" for a, b in windows)
    vexpr = f"'if({duck},0.22,{base_v})'" if windows else f"{base_v}"
    ci = sc.get('cue_in', 0.0)
    fo = max(0.0, S-1.3)
    run(['ffmpeg','-y','-ss',f"{ci}",'-i',sc['cue'],'-af',
         f"aresample=44100,apad=whole_dur={S},atrim=0:{S},volume={vexpr}:eval=frame,afade=t=in:st=0:d=0.8,afade=t=out:st={fo:.2f}:d=1.3",
         '-ac','2','-ar','44100', f'{BUILD}/{name}_score.wav'])

    if events:
        run(['ffmpeg','-y','-i',f'{BUILD}/{name}_dlg.wav','-i',f'{BUILD}/{name}_score.wav',
             '-filter_complex', f"amix=inputs=2:duration=longest:normalize=0,atrim=0:{S}",
             '-ac','2','-ar','44100', f'{BUILD}/{name}_mix.wav'])
    else:
        os.replace(f'{BUILD}/{name}_score.wav', f'{BUILD}/{name}_mix.wav')
    run(['ffmpeg','-y','-i',f'{BUILD}/{name}_v.mp4','-i',f'{BUILD}/{name}_mix.wav',
         '-c:v','copy','-c:a','aac','-b:a','192k','-ar','44100','-shortest', f'{OUT}/{name}.mp4'])
    scene_files.append(f'{OUT}/{name}.mp4')
    report.append(f"{name}: {S:.1f}s / {len(events)} events / {len(segs)} segs")

for nm in ('title24','credits24'):
    if not os.path.exists(f'{OUT}/{nm}.mp4'):
        import shutil; shutil.copy(f'../ep2prod/out/{nm}.mp4', f'{OUT}/{nm}.mp4')
with open(f'{OUT}/ep_cat.txt','w') as f:
    f.write("file 'title24.mp4'\n")
    for s in scene_files: f.write(f"file '{os.path.basename(s)}'\n")
    f.write("file 'credits24.mp4'\n")
run(['ffmpeg','-y','-f','concat','-safe','0','-i',f'{OUT}/ep_cat.txt','-c','copy',f'{OUT}/KUKU_EP4_V1.mp4'])
d = probe(f'{OUT}/KUKU_EP4_V1.mp4')
print('\n'.join(report))
for s in skipped: print('SKIPPED', s)
print(f"EPISODE: {d:.1f}s -> {OUT}/KUKU_EP4_V1.mp4")
PY
