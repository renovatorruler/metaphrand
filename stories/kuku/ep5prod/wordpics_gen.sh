#!/bin/bash
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep5prod
STYLE=0c47270d-70f7-4dd0-887f-c06c88ef5fd9
CS=../charsheets
P="FLASHCARD ILLUSTRATION for a children's letter-learning show: ONE single subject, large and centred, filling most of the frame, clearly readable at a glance, plain simple background with nothing else competing. STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY. 3D papercraft, layered cut-paper, soft matte textures, warm storybook palette, non-photorealistic."
N="NEGATIVE: no wide landscape, no distant scenery, no busy background, no other objects, no readable text, no letters, no watermark, no photorealism."
one(){ local n="$1" refs="$2" d="$3" t
  [ -s "wordpics/$n.png" ] && { echo "SKIP $n"; return; }
  for t in 1 2 3; do
    out=$(higgsfield generate create nano_banana_pro --prompt "$P $d $N" --image "$STYLE" $refs --aspect_ratio 1:1 --resolution 2k --wait --json 2>/dev/null)
    url=$(echo "$out" | python3 -c "import sys,json
try:
  d=json.load(sys.stdin); d=d[0] if isinstance(d,list) else d
  print(d.get('result_url') or '')
except Exception: print('')")
    [ -n "$url" ] && curl -s -o "wordpics/$n.png" "$url" && { echo "OK $n"; sleep 5; return; }
    echo "retry $t $n"; sleep 15
  done
  echo "FAIL $n"; }
one pul_new "" "A single small wooden footbridge with a flat plank deck on two sturdy pillars, seen close and side-on, spanning a narrow ribbon of blue paper water. The bridge fills the frame."
one patthar_new "" "Three smooth flat grey river stones stacked and resting together, close up and large, a little green moss on one edge, a few blue paper water ripples at their base."
one pair_new "--image $CS/kuku.png" "EXTREME CLOSE-UP of the two green feet and clawed toes of Kuku the small green baby dragon, standing on green paper grass. Just the feet and lower legs, filling the frame."
one patang_new "" "A single bright diamond-shaped paper kite with a long ribboned tail, large and centred, tilted as if flying, against a plain pale blue sky."
one ped_new "" "One big leafy paper tree with a thick brown trunk and a full round crown of layered green leaves, whole and centred, standing alone on a small patch of grass."
echo "WORDPICS: $(ls wordpics/*_new.png 2>/dev/null | wc -l | tr -d ' ')/5"
