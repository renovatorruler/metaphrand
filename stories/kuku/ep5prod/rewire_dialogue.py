#!/usr/bin/env python3
"""Point every generic talking-head still at its per-scene variant.

The old cut reused one close-up per character for the whole episode, so a shot
from scene 1 (bright afternoon) could sit next to scene 7 (lantern night). The
per-scene set fixes that. Story-specific stills (the bridge, the forge, Vesper
asleep) are NOT generic and stay exactly where they are.
"""
import json, os, sys, collections

D = os.path.dirname(os.path.abspath(__file__))
os.chdir(D)

# generic close-up -> character slug in the per-scene set
GENERIC = {
    'e5_cu_kuku': 'kuku', 'e5_cu_kuku_happy': 'kuku',
    'e5_cu_fyuria': 'fyuria', 'e5_cu_fyuria_bright': 'fyuria',
    'e5_cu_vesper': 'vesper',
    'e5_cu_dadi': 'dadi',
    'e5_cu_mitasur': 'mitasur',
    'e5_cu_papa': 'papa',
    'e5_toddlers_far': 'toddlers',
    'e5_dadi_group_cross': 'toddlers',   # s1: this one carries Castor+Leda
}

edl = json.load(open('ep5_edl.json'))
changed, kept, missing = [], collections.Counter(), []

for sc in edl['scenes']:
    name = sc['name']
    if not (len(name) > 1 and name[0] == 's' and name[1].isdigit()):
        continue
    n = int(name[1])
    if n == 0:
        continue
    for seg in sc['segments']:
        src = seg.get('src', '')
        if not src.startswith('still:'):
            continue
        old = src[6:]
        slug = GENERIC.get(old)
        if slug is None:
            kept[old] += 1
            continue
        new = f'e5_d{n}_{slug}'
        if not os.path.exists(f'stills/{new}.png'):
            missing.append((name, old, new))
            continue
        seg['src'] = 'still:' + new
        changed.append((name, old, new))

if missing:
    print('MISSING per-scene stills — refusing to write:', file=sys.stderr)
    for m in missing:
        print('  ', m, file=sys.stderr)
    sys.exit(1)

json.dump(edl, open('ep5_edl.json', 'w'), ensure_ascii=False, indent=1)

print(f'rewired {len(changed)} segments')
for s, o, nw in changed:
    print(f'  {s:4} {o:24} -> {nw}')
print('\nkept as story-specific stills:')
for k, v in sorted(kept.items()):
    print(f'  {k:24} x{v}')
