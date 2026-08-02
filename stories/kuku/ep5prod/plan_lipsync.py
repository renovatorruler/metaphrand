#!/usr/bin/env python3
"""Weighted lip-sync plan: spend the budget on the shots that carry the episode.

A straight every-third rotation is cheap to compute but blind — it can spend on
"...हाँ।" and skip Fyuria admitting she broke the bridge. This forces in the story
beats first, then spreads whatever budget is left evenly over the remaining shots
so no character sits frozen for long stretches.

Unit of work = one segment (a shot) showing ONE speaker over a character still.
Castor, Leda and every chorus line are excluded by the user's instruction.
"""
import json, os

D = os.path.dirname(os.path.abspath(__file__))
os.chdir(D)

RATE = 0.14          # USD per second, fal.ai OmniHuman
BUDGET = 25.45       # match the mechanical plan's price
EXCLUDE = {'CASTOR', 'LEDA', 'CHORUS_ALL'}

# OmniHuman drives ONE face. A wide shot (the broken bridge, the crossing) has no
# single face to drive, and a shot of the wrong character would animate a listener's
# mouth to the speaker's words. So a shot only qualifies when the still is provably
# that speaker's own per-scene close-up.
SLUG = {'KUKU': 'kuku', 'FYURIA': 'fyuria', 'VESPER': 'vesper',
        'DADI': 'dadi', 'MITASUR': 'mitasur', 'PAPA': 'papa'}

# The beats the episode actually turns on. Each is a take index; any segment
# carrying one of these is synced regardless of where the rotation lands.
BEATS = {
    102: "Fyuria: I broke the bridge",
    103: "Fyuria: your letter is not weak",
    104: "Fyuria: Mitasur, forgive me",
    114: "Papa: I built this bridge",
    116: "Papa: I set the middle pier on sand",
    118: "Papa: I put it off because telling was hard",
    119: "Papa: truth joins only by speaking",
    71:  "Kuku: maybe I am small, so my letter...",
    99:  "Kuku: my letter itself is weak",
    72:  "Dadi: the letter is not weak, the place is wrong",
    142: "Dadi: the mistake was small, hiding made it big",
    54:  "Dadi: the three parts of P (the lesson)",
}

edl = json.load(open('ep5_edl.json'))
man = json.load(open('ep5_manifest.json'))
who = {e['idx']: e['who'] for e in man['events'] if 'idx' in e}
text = {e['idx']: e['text'] for e in man['events'] if 'idx' in e}
durs = json.load(open('ep5_durs.json'))['takes']


def tdur(i):
    return float(durs.get(str(i)) or durs.get(i) or 0.0)


shots = []
for sc in edl['scenes']:
    for gi, seg in enumerate(sc['segments']):
        src = seg.get('src', '')
        if not src.startswith('still:'):
            continue                      # cards, clips and sequences can't be synced
        idxs = [t['i'] for t in seg.get('takes', []) if 'i' in t]
        spk = {who.get(i) for i in idxs}
        if not idxs or len(spk) != 1:
            continue                      # need exactly one face doing all the talking
        w = spk.pop()
        if w in EXCLUDE or w is None or w.endswith('_SFX'):
            continue
        slug = SLUG.get(w)
        if slug is None or src[6:] != f"e5_d{sc['name'][1:]}_{slug}":
            continue                      # not this speaker's own close-up
        secs = sum(tdur(i) for i in idxs)
        if secs < 0.8:
            continue                      # too short to read as speech
        shots.append({
            'scene': sc['name'], 'seg': gi, 'who': w, 'still': src[6:],
            'takes': idxs, 'secs': round(secs, 2),
            'beat': next((BEATS[i] for i in idxs if i in BEATS), None),
        })

beats = [s for s in shots if s['beat']]
rest = [s for s in shots if not s['beat']]

spent = sum(s['secs'] for s in beats) * RATE
left = BUDGET - spent

# spread the remainder evenly across the non-beat shots rather than taking a
# prefix, so the sync never clumps into one stretch of the episode
chosen = list(beats)
if left > 0 and rest:
    avg = sum(s['secs'] for s in rest) / len(rest)
    n = max(0, int(left / (avg * RATE)))
    if n:
        step = len(rest) / n
        picked, acc = [], 0.0
        for k in range(n):
            j = int(k * step)
            if j < len(rest):
                cand = rest[j]
                if acc + cand['secs'] * RATE > left:
                    continue
                acc += cand['secs'] * RATE
                picked.append(cand)
        chosen += picked

chosen.sort(key=lambda s: (int(s['scene'][1:] or 0), s['seg']))
total = sum(s['secs'] for s in chosen)

plan = {
    'rate_usd_per_sec': RATE,
    'eligible_shots': len(shots),
    'eligible_secs': round(sum(s['secs'] for s in shots), 1),
    'chosen_shots': len(chosen),
    'chosen_secs': round(total, 1),
    'cost_usd': round(total * RATE, 2),
    'beats_forced': len(beats),
    'shots': chosen,
}
json.dump(plan, open('lip_plan.json', 'w'), ensure_ascii=False, indent=1)

print(f"eligible: {len(shots)} shots / {plan['eligible_secs']}s  (full sync = ${plan['eligible_secs']*RATE:.2f})")
print(f"chosen:   {len(chosen)} shots / {plan['chosen_secs']}s  = ${plan['cost_usd']}")
print(f"  of which {len(beats)} forced story beats ({sum(s['secs'] for s in beats):.1f}s)\n")

per = {}
for s in chosen:
    per.setdefault(s['who'], [0, 0.0])
    per[s['who']][0] += 1
    per[s['who']][1] += s['secs']
for w, (c, sec) in sorted(per.items(), key=lambda x: -x[1][1]):
    print(f"  {w:8} {c:2} shots {sec:6.1f}s  ${sec*RATE:5.2f}")

print("\nforced beats:")
for s in beats:
    print(f"  {s['scene']:3} seg{s['seg']:<3} {s['who']:8} {s['secs']:5.1f}s  {s['beat']}")

cov = {}
for s in shots:
    cov.setdefault(s['scene'], [0, 0])
    cov[s['scene']][0] += 1
for s in chosen:
    cov[s['scene']][1] += 1
print("\nspread across the episode (synced / eligible per scene):")
for k in sorted(cov, key=lambda x: int(x[1:] or 0)):
    print(f"  {k:4} {cov[k][1]}/{cov[k][0]}")
