#!/bin/bash
# Swap every successfully-synced shot from its static still to the OmniHuman clip.
# Run after lipsync_ep5.sh, then re-run assemble_ep5.sh (the .key cache invalidates
# itself because the segment's src changed) and verify_picture.py.
#
# Only shots present in lipclips/_manifest.json AND on disk are swapped, so a partial
# run degrades to "some shots move, the rest stay still" rather than a broken build.
set -e
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep5prod
python3 - <<'PY'
import json, os, subprocess

MANP = 'lipclips/_manifest.json'
if not os.path.exists(MANP):
    raise SystemExit('no lipclips/_manifest.json — run lipsync_ep5.sh first')
man = json.load(open(MANP))
edl = json.load(open('ep5_edl.json'))
plan = {f"{s['scene']}_{s['seg']:02d}": s for s in json.load(open('lip_plan.json'))['shots']}

def dur(p):
    return float(subprocess.run(['ffprobe', '-v', 'error', '-show_entries',
                                 'format=duration', '-of', 'csv=p=0', p],
                                capture_output=True, text=True).stdout.strip())

scenes = {sc['name']: sc for sc in edl['scenes']}
swapped, skipped = [], []
for tag, rec in sorted(man.items()):
    clip = f'lipclips/{tag}.mp4'
    s = plan.get(tag)
    if not (s and os.path.exists(clip)):
        skipped.append((tag, 'no clip on disk'))
        continue
    seg = scenes[s['scene']]['segments'][s['seg']]
    want = f"still:{s['still']}"
    if seg.get('src') not in (want, f'file:{clip}'):
        skipped.append((tag, f"EDL moved on: {seg.get('src')}"))
        continue
    # the segment's length is set by its speech; the clip must cover it
    need = s['secs'] + 0.38
    have = dur(clip)
    if have + 0.05 < need:
        skipped.append((tag, f'clip {have:.2f}s shorter than segment {need:.2f}s'))
        continue
    seg['src'] = f'file:{clip}'
    seg['still_was'] = s['still']          # so this is reversible
    swapped.append(tag)

json.dump(edl, open('ep5_edl.json', 'w'), ensure_ascii=False, indent=1)
print(f'swapped {len(swapped)} shots to lip-synced clips')
for t in swapped:
    print('  ', t)
if skipped:
    print(f'\nleft as stills ({len(skipped)}):')
    for t, why in skipped:
        print(f'   {t}: {why}')
print('\nnow: bash assemble_ep5.sh && python3 verify_picture.py')
PY
