#!/bin/bash
# Ep2 animatic assembly. Audio-first: per scene, dialogue takes are placed on a
# timeline, one continuous score cue ducks under them (0.5 -> 0.22), and video
# segments (stills with push-in / muted 24fps clips / typst cards) are cut to
# exactly that timeline. Then scenes concat with the series title/credits.
set -e
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep2prod
mkdir -p build out
python3 <<'PY'
import json, subprocess, os, math

EDL   = json.load(open('ep2_edl.json'))
DURS  = {int(k): v for k, v in json.load(open('take_durs.json')).items()}
W, H, FPS = 1280, 720, 24
LEAD, GAP, TAIL = 0.5, 0.45, 0.6

def run(args):
    r = subprocess.run(args, capture_output=True, text=True)
    if r.returncode != 0:
        raise SystemExit(f"FFMPEG FAIL: {' '.join(args)}\n{r.stderr[-1500:]}")

def vsrc(seg):
    s = seg['src']
    if s.startswith('still:'): return 'still', f"stills/{s[6:]}.png"
    if s.startswith('clip:'):  return 'clip',  f"clips/{s[5:]}.mp4"
    if s.startswith('file:'):  return 'clip',  s[5:]
    if s.startswith('card:'):  return 'card',  f"cards/{s[5:]}.png"
    if s == 'seq':             return 'seq',   None
    raise SystemExit(f"bad src {s}")

def place_takes(seg):
    """Assign absolute-in-segment take times; return (takes, min_dur)."""
    t = 0.0; placed = []
    for tk in seg.get('takes', []):
        at = tk['at'] if 'at' in tk else (LEAD if not placed else t + GAP)
        d = DURS[tk['i']]
        placed.append({'i': tk['i'], 'at': at, 'end': at + d})
        t = at + d
    need = (placed[-1]['end'] + TAIL) if placed else 0.0
    return placed, need

def seg_duration(seg):
    placed, need = place_takes(seg)
    dur = seg.get('dur', 0.0)
    dur = max(dur, need)
    if dur <= 0: raise SystemExit(f"segment with no duration: {seg['src']}")
    return round(dur, 3), placed

def render_seg(scene, si, seg, dur):
    out = f"build/{scene}_{si:02d}.mp4"
    base = f"build/{scene}_{si:02d}_base.mp4"
    tgt = base if seg.get('fx') else out
    kind, path = vsrc(seg)
    n = max(2, round(dur * FPS))
    if not (seg.get('fx') and os.path.exists(out)) and not os.path.exists(tgt):
        if kind == 'still':
            vf = (f"scale=3840:2160,zoompan=z='1+0.085*on/{n-1}'"
                  f":x='(iw-iw/zoom)/2':y='(ih-ih/zoom)/2':d={n}:s={W}x{H}:fps={FPS},format=yuv420p")
            run(['ffmpeg','-y','-i',path,'-vf',vf,'-frames:v',str(n),
                 '-c:v','libx264','-crf','18','-an',tgt])
        elif kind == 'card':
            run(['ffmpeg','-y','-loop','1','-i',path,'-t',f"{dur}",
                 '-vf',f"scale={W}:{H},fps={FPS},format=yuv420p",
                 '-c:v','libx264','-crf','18','-an',tgt])
        elif kind == 'clip':
            fade = f",fade=t=out:st={dur-seg['fadeout']}:d={seg['fadeout']}" if seg.get('fadeout') else ""
            run(['ffmpeg','-y','-i',path,'-ss',f"{seg.get('in',0.0)}",'-t',f"{dur}",
                 '-vf',f"fps={FPS},scale={W}:{H}{fade},format=yuv420p",
                 '-c:v','libx264','-crf','18','-an',tgt])
        elif kind == 'seq':
            # recap card cycle: intro card03 2.55s, then the 7 word cards fill the rest
            intro = 2.55; rest = (dur - intro) / 7.0
            parts = [('cards/card03.png', intro)] + [(f'cards/card{k:02d}.png', rest) for k in range(4, 11)]
            with open(f'build/{scene}_{si:02d}_cat.txt','w') as f:
                for k,(p,d) in enumerate(parts):
                    pp = f"build/{scene}_{si:02d}_p{k}.mp4"
                    run(['ffmpeg','-y','-loop','1','-i',p,'-t',f"{d:.3f}",
                         '-vf',f"scale={W}:{H},fps={FPS},format=yuv420p",
                         '-c:v','libx264','-crf','18','-an',pp])
                    f.write(f"file '{scene}_{si:02d}_p{k}.mp4'\n")
            run(['ffmpeg','-y','-f','concat','-safe','0','-i',f'build/{scene}_{si:02d}_cat.txt',
                 '-c','copy',tgt])
    if seg.get('fx') and not os.path.exists(out):
        fx = seg['fx'][0]
        px = int(W * fx['scale'])
        pos = {'tc': f"(W-w)/2:H*0.08", 'c': f"(W-w)/2:(H-h)/2", 'bc': f"(W-w)/2:H*0.60"}[fx.get('pos','tc')]
        # -loop 1 image input REQUIRES overlay shortest=1 (the law)
        run(['ffmpeg','-y','-i',base,'-loop','1','-i',fx['png'],'-filter_complex',
             f"[1:v]format=rgba,scale={px}:-1,fade=t=in:st={fx['at']}:d=0.5:alpha=1[f];"
             f"[0:v][f]overlay={pos}:shortest=1,format=yuv420p",
             '-c:v','libx264','-crf','18','-an',out])
    return out

# ---------- per scene ----------
scene_files = []
report = []
for sc in EDL['scenes']:
    name = sc['name']
    segs, clock, events = [], 0.0, []
    for si, seg in enumerate(sc['segments']):
        dur, placed = seg_duration(seg)
        f = render_seg(name, si, seg, dur)
        segs.append(f)
        for p in placed:
            events.append({'i': p['i'], 'abs': clock + p['at'], 'end': clock + p['end']})
        clock += dur
    S = round(clock, 3)

    # video concat
    with open(f'build/{name}_cat.txt','w') as f:
        for s in segs: f.write(f"file '{os.path.basename(s)}'\n")
    run(['ffmpeg','-y','-f','concat','-safe','0','-i',f'build/{name}_cat.txt','-c','copy',f'build/{name}_v.mp4'])

    # dialogue bus
    if events:
        args = ['ffmpeg','-y']
        for e in events: args += ['-i', f"takes/{e['i']:02d}.mp3"]
        chains, mix = [], []
        for k, e in enumerate(events):
            chains.append(f"[{k}:a]aresample=44100,adelay={int(e['abs']*1000)}:all=1[d{k}]")
            mix.append(f"[d{k}]")
        fc = ';'.join(chains) + f";{''.join(mix)}amix=inputs={len(events)}:duration=longest:normalize=0,atrim=0:{S},apad=whole_dur={S}[out]"
        run(args + ['-filter_complex', fc, '-map','[out]','-ac','2','-ar','44100', f'build/{name}_dlg.wav'])

    # score: duck under dialogue windows
    windows = []
    for e in sorted(events, key=lambda x: x['abs']):
        a, b = max(0, e['abs']-0.15), e['end']+0.25
        if windows and a - windows[-1][1] < 0.3: windows[-1][1] = b
        else: windows.append([a, b])
    base_v = sc.get('score_vol', 0.5)
    duck = '+'.join(f"between(t,{a:.2f},{b:.2f})" for a, b in windows)
    vexpr = f"'if({duck},0.22,{base_v})'" if windows else f"{base_v}"
    fo = max(0.0, S-1.3)
    run(['ffmpeg','-y','-i',sc['cue'],'-af',
         f"aresample=44100,apad=whole_dur={S},atrim=0:{S},volume={vexpr}:eval=frame,afade=t=in:st=0:d=0.8,afade=t=out:st={fo:.2f}:d=1.3",
         '-ac','2','-ar','44100', f'build/{name}_score.wav'])

    # final scene audio + mux
    if events:
        run(['ffmpeg','-y','-i',f'build/{name}_dlg.wav','-i',f'build/{name}_score.wav',
             '-filter_complex', f"amix=inputs=2:duration=longest:normalize=0,atrim=0:{S}",
             '-ac','2','-ar','44100', f'build/{name}_mix.wav'])
    else:
        os.replace(f'build/{name}_score.wav', f'build/{name}_mix.wav')
    run(['ffmpeg','-y','-i',f'build/{name}_v.mp4','-i',f'build/{name}_mix.wav',
         '-c:v','copy','-c:a','aac','-b:a','192k','-ar','44100','-shortest', f'out/{name}.mp4'])
    scene_files.append(f'out/{name}.mp4')
    report.append(f"{name}: {S:.1f}s / {len(events)} takes / {len(segs)} segs")

# ---------- episode ----------
for nm, src in [('title24','../KUKU_TITLE.mp4'), ('credits24','../KUKU_CREDITS.mp4')]:
    if not os.path.exists(f'out/{nm}.mp4'):
        run(['ffmpeg','-y','-i',src,'-vf',f"fps={FPS},scale={W}:{H},format=yuv420p",
             '-c:v','libx264','-crf','18','-c:a','aac','-b:a','192k','-ar','44100', f'out/{nm}.mp4'])
with open('out/ep_cat.txt','w') as f:
    f.write("file 'title24.mp4'\n")
    for s in scene_files: f.write(f"file '{os.path.basename(s)}'\n")
    f.write("file 'credits24.mp4'\n")
run(['ffmpeg','-y','-f','concat','-safe','0','-i','out/ep_cat.txt','-c','copy','out/KUKU_EP2_ANIMATIC.mp4'])
d = subprocess.run(['ffprobe','-v','error','-show_entries','format=duration','-of','csv=p=0','out/KUKU_EP2_ANIMATIC.mp4'],capture_output=True,text=True).stdout.strip()
print('\n'.join(report))
print(f"EPISODE: {float(d):.1f}s -> out/KUKU_EP2_ANIMATIC.mp4")
PY
