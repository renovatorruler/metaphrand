#!/bin/bash
# Lip-sync the shots in lip_plan.json via fal.ai OmniHuman.
#
# Resumable: every finished shot is recorded in lipclips/_manifest.json and skipped
# on re-run, so a crash mid-run costs nothing. DRY=1 does everything except spend —
# it builds and measures the audio, checks the stills, and prints the bill.
#
# The audio handed to OmniHuman is built with the SAME lead/gap placement the
# assembler uses, so the returned video aligns with the episode timeline frame for
# frame. Building it from 0.0 instead would put every mouth 0.3s ahead of its voice.
set -e
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep5prod
python3 - <<'PY'
import json, os, subprocess, sys, time, urllib.request, urllib.error

DRY   = os.environ.get('DRY') == '1'
LIMIT = int(os.environ.get('LIMIT', '0'))
MODEL = os.environ.get('MODEL', 'fal-ai/bytedance/omnihuman')
LEAD, GAP, TAIL = 0.3, 0.28, 0.38          # must match assemble_ep5.sh
PAD = 0.8                                   # freeze-frame tail so no SHOT OVERFLOW

OUT = 'lipclips'; os.makedirs(OUT, exist_ok=True)
MANP = f'{OUT}/_manifest.json'
man = json.load(open(MANP)) if os.path.exists(MANP) else {}

plan  = json.load(open('lip_plan.json'))
durs  = json.load(open('ep5_durs.json'))['takes']
edl   = {sc['name']: sc for sc in json.load(open('ep5_edl.json'))['scenes']}

def key():
    for line in open('/Users/dusty/Dev/metaphrand/.env'):
        if line.startswith('FAL_AI='):
            return line.split('=', 1)[1].strip().strip('"').strip("'")
    raise SystemExit('no FAL_AI in .env')

K = key()
H = {'Authorization': f'Key {K}', 'Content-Type': 'application/json'}

def api(url, data=None, headers=None, method=None, raw=None, timeout=120):
    req = urllib.request.Request(url, data=raw if raw is not None else (
        json.dumps(data).encode() if data is not None else None),
        headers=headers or H, method=method)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        body = r.read()
    return json.loads(body) if body[:1] in (b'{', b'[') else body

def balance():
    req = urllib.request.Request('https://rest.alpha.fal.ai/billing/user_balance',
                                 headers={'Authorization': f'Key {K}'})
    return float(urllib.request.urlopen(req, timeout=20).read().decode().strip())

def tdur(i):
    return float(durs.get(str(i)) or durs.get(i) or 0.0)

def build_audio(shot):
    """Speech-only bus for one segment, placed exactly as the assembler places it."""
    dst = f"{OUT}/{shot['scene']}_{shot['seg']:02d}.wav"
    if os.path.exists(dst):
        return dst
    t, placed = 0.0, []
    for n, i in enumerate(shot['takes']):
        at = LEAD if n == 0 else t + GAP
        placed.append((f'takes/{i:02d}.mp3', at))
        t = at + tdur(i)
    total = t + TAIL
    args = ['ffmpeg', '-y', '-v', 'error']
    for p, _ in placed:
        args += ['-i', p]
    chains = [f"[{k}:a]aresample=44100,adelay={int(at*1000)}:all=1[d{k}]"
              for k, (_, at) in enumerate(placed)]
    mix = ''.join(f'[d{k}]' for k in range(len(placed)))
    fc = ';'.join(chains) + (
        f";{mix}amix=inputs={len(placed)}:duration=longest:normalize=0"
        f",atrim=0:{total:.3f},apad=whole_dur={total:.3f}[o]")
    subprocess.run(args + ['-filter_complex', fc, '-map', '[o]',
                           '-ac', '1', '-ar', '44100', dst], check=True,
                   capture_output=True)
    return dst

def upload(path, ctype):
    init = api('https://rest.alpha.fal.ai/storage/upload/initiate?storage_type=fal-cdn-v3',
               data={'content_type': ctype, 'file_name': os.path.basename(path)})
    api(init['upload_url'], raw=open(path, 'rb').read(), method='PUT',
        headers={'Content-Type': ctype}, timeout=300)
    return init['file_url']

def submit(img_url, aud_url):
    r = api(f'https://queue.fal.run/{MODEL}',
            data={'image_url': img_url, 'audio_url': aud_url})
    rid, base = r['request_id'], r.get('response_url')
    status = r.get('status_url') or f'https://queue.fal.run/{MODEL}/requests/{rid}/status'
    for _ in range(240):                      # up to ~20 min per shot
        time.sleep(5)
        st = api(status, headers={'Authorization': f'Key {K}'})
        if st.get('status') == 'COMPLETED':
            res = api(base or f'https://queue.fal.run/{MODEL}/requests/{rid}',
                      headers={'Authorization': f'Key {K}'})
            return res['video']['url']
        if st.get('status') in ('FAILED', 'ERROR'):
            raise RuntimeError(f'fal job {rid} failed: {json.dumps(st)[:300]}')
    raise RuntimeError(f'fal job {rid} timed out')

def pad_clip(src, dst, need):
    """Freeze the last frame so the clip covers the segment; else SHOT OVERFLOW."""
    subprocess.run(['ffmpeg', '-y', '-v', 'error', '-i', src,
                    '-vf', f'tpad=stop_mode=clone:stop_duration={PAD}',
                    '-an', '-c:v', 'libx264', '-crf', '18', dst],
                   check=True, capture_output=True)

shots = plan['shots']
if LIMIT:
    shots = shots[:LIMIT]

total_sec = sum(s['secs'] for s in shots)
print(f"plan: {len(shots)} shots / {total_sec:.1f}s "
      f"= ${total_sec*plan['rate_usd_per_sec']:.2f}")

# every shot must be the speaker's own close-up and the still must exist
for s in shots:
    png = f"stills/{s['still']}.png"
    if not os.path.exists(png):
        raise SystemExit(f"missing still {png} for {s['scene']}#{s['seg']}")
    seg = edl[s['scene']]['segments'][s['seg']]
    if seg.get('src') != f"still:{s['still']}":
        raise SystemExit(f"EDL drifted: {s['scene']}#{s['seg']} is {seg.get('src')}, "
                         f"plan expects still:{s['still']} — re-run plan_lipsync.py")

bal = balance()
print(f'fal balance: ${bal:.2f}')
if not DRY and bal < total_sec * plan['rate_usd_per_sec']:
    raise SystemExit(f'INSUFFICIENT BALANCE: need about '
                     f'${total_sec*plan["rate_usd_per_sec"]:.2f}, have ${bal:.2f}. '
                     f'Top up at fal.ai/dashboard/billing, then re-run.')

done = 0
for s in shots:
    tag = f"{s['scene']}_{s['seg']:02d}"
    final = f'{OUT}/{tag}.mp4'
    if man.get(tag) and os.path.exists(final):
        print(f'SKIP {tag} (done)')
        done += 1
        continue
    wav = build_audio(s)
    alen = float(subprocess.run(
        ['ffprobe', '-v', 'error', '-show_entries', 'format=duration',
         '-of', 'csv=p=0', wav], capture_output=True, text=True).stdout.strip())
    print(f"{tag}  {s['who']:8} {alen:5.2f}s  {s['still']}"
          f"{'  [' + s['beat'] + ']' if s.get('beat') else ''}")
    if DRY:
        continue
    try:
        iu = upload(f"stills/{s['still']}.png", 'image/png')
        au = upload(wav, 'audio/wav')
        url = submit(iu, au)
        raw = f'{OUT}/{tag}_raw.mp4'
        with open(raw, 'wb') as f:
            f.write(urllib.request.urlopen(url, timeout=600).read())
        pad_clip(raw, final, alen)
        man[tag] = {'still': s['still'], 'secs': round(alen, 2), 'who': s['who']}
        json.dump(man, open(MANP, 'w'), ensure_ascii=False, indent=1)
        done += 1
        print(f'   OK -> {final}')
    except Exception as e:
        print(f'   FAIL {tag}: {type(e).__name__} {str(e)[:200]}')

print(f'\n{done}/{len(shots)} shots ready in {OUT}/')
if DRY:
    print('DRY run — nothing submitted, nothing spent.')
PY
