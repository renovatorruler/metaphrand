#!/bin/bash
# Per-scene dialogue images: one per (character, scene), no bridge in frame.
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep5prod
STYLE=0c47270d-70f7-4dd0-887f-c06c88ef5fd9
python3 - <<'PY' > /tmp/dlg_cmds.sh
import json
rows=json.load(open('dialogue_set.json'))
S=("STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY. "
   "CHARACTER REFERENCES: every other image is a locked character design; match each EXACTLY. "
   "3D papercraft, layered cut-paper illustration, soft matte construction-paper textures, "
   "warm storybook palette, non-photorealistic, illustrated. LANDSCAPE 16:9 SHOT.")
N=("Full-bleed scene, the camera is INSIDE the world. Mouth gently closed, clear readable expression. "
   "NEGATIVE: no bridge, no rope bridge, no plank walkway, no theater curtains, no stage, no proscenium, "
   "no frame-within-frame, no decorative border, no readable text, no letters, no watermark, "
   "no photorealism, no duplicate characters, nothing scary.")
for r in rows:
    refs=' '.join(f'--image ../charsheets/{x}.png' for x in r['refs'])
    p=(S+' '+r['prompt']+' '+N).replace('"','\\"')
    print(f'one {r["name"]} "{refs}" "{p}"')
PY
one(){ local n="$1" refs="$2" p="$3" t
  [ -s "stills/$n.png" ] && { echo "SKIP $n"; return; }
  for t in 1 2 3; do
    out=$(higgsfield generate create nano_banana_pro --prompt "$p" --image "$STYLE" $refs --aspect_ratio 16:9 --resolution 2k --wait --json 2>/dev/null)
    url=$(echo "$out" | python3 -c "import sys,json
try:
  d=json.load(sys.stdin); d=d[0] if isinstance(d,list) else d
  print(d.get('result_url') or '')
except Exception: print('')")
    [ -n "$url" ] && curl -s -o "stills/$n.png" "$url" && { echo "OK $n"; sleep 4; return; }
    echo "retry $t $n"; sleep 14
  done
  echo "FAIL $n"; }
source /tmp/dlg_cmds.sh
echo "DIALOGUE SET: $(ls stills/e5_d*.png 2>/dev/null | wc -l | tr -d ' ')/43"
