#!/bin/bash
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep5prod
STYLE=0c47270d-70f7-4dd0-887f-c06c88ef5fd9
CS=../charsheets
# the ONE canonical description, used verbatim everywhere the deck appears
DECK="They are standing ON a broad flat plain golden-brown wooden deck. Only the flat deck surface and its plank boards are visible under their feet — the bridge's railings, pillars and overall shape are OUT OF FRAME."
N="Full-bleed scene, camera INSIDE the world. NEGATIVE: no arched bridge, no ornate railings, no lattice, no visible bridge structure, no theater curtains, no stage, no frame-within-frame, no readable text, no letters, no watermark, no photorealism, nothing scary."
S="STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY. CHARACTER REFERENCES: character images are locked designs; match each EXACTLY. 3D papercraft, layered cut-paper, warm storybook palette, non-photorealistic. LANDSCAPE 16:9 SHOT."
one(){ local n="$1" refs="$2" d="$3" t
  [ -s "stills/$n.png" ] && { echo "SKIP $n"; return; }
  for t in 1 2 3; do
    out=$(higgsfield generate create nano_banana_pro --prompt "$S $d $DECK $N" --image "$STYLE" $refs --aspect_ratio 16:9 --resolution 2k --wait --json 2>/dev/null)
    url=$(echo "$out" | python3 -c "import sys,json
try:
  d=json.load(sys.stdin); d=d[0] if isinstance(d,list) else d
  print(d.get('result_url') or '')
except Exception: print('')")
    [ -n "$url" ] && curl -s -o "stills/$n.png" "$url" && { echo "OK $n"; sleep 5; return; }
    echo "retry $t $n"; sleep 16
  done
  echo "FAIL $n"; }
one e5_papa_crosses "--image $CS/papa.png" "MEDIUM CLOSE SHOT of Papa the big dark-green dragon from the knees up, taking a heavy testing step forward, looking down at his own feet, relieved and proud, dusk light."
one e5_all_cross "--image $CS/dadi.png --image $CS/reechh.png --image $CS/castor.png --image $CS/leda.png" "MEDIUM SHOT from the knees up of Dadi Maya the grey grandmother dragon, Reechh the honey-brown bear, Castor the tiny yellow toddler and Leda the smaller lavender-pink baby girl dragon walking towards camera together, relieved and happy, dusk. Each character appears exactly once."
one e5_vesper_asleep "--image $CS/vesper.png" "CLOSE SHOT of Vesper the soft blue dragon boy fast asleep curled on his side, cheek against the wood, a small blanket over him, paper stars and a warm lantern glow above, night."
echo done
