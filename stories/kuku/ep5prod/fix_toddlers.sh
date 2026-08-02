#!/bin/bash
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep5prod
STYLE=0c47270d-70f7-4dd0-887f-c06c88ef5fd9
CS=../charsheets
A="--image stills/e5_bridge_wide.png"
N="Full-bleed scene, camera INSIDE the world. NEGATIVE: no theater curtains, no stage, no proscenium, no frame-within-frame, no readable text, no letters, no watermark, no photorealism, nothing scary, no duplicate characters, no twins, no repeated identical dragon."
CAST="THE GROUP IS EXACTLY FOUR: Dadi Maya the tall grey grandmother dragon with spectacles and a knitted shawl, Reechh the big honey-brown bear, Castor the TINY YELLOW toddler dragon, and Leda the even smaller LAVENDER-PINK baby girl dragon. Each appears ONCE. There is one yellow toddler and one pink-purple baby — they are different colours and must not be duplicated."
for t in 1 2 3; do
  [ -s stills/e5_dadi_group_cross.png ] && break
  out=$(higgsfield generate create nano_banana_pro --prompt "STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY. CHARACTER REFERENCES: each character image is a locked design; match each EXACTLY. LOCATION REFERENCE: match the place image's rope-and-plank bridge, banks and tree. 3D papercraft, layered cut-paper, warm storybook palette, non-photorealistic. LANDSCAPE 16:9. $CAST They are walking together onto the rope-and-plank bridge in the afternoon, cheerful, Dadi leading with her walking stick. $N" --image "$STYLE" --image $CS/dadi.png --image $CS/reechh.png --image $CS/castor.png --image $CS/leda.png $A --aspect_ratio 16:9 --resolution 2k --wait --json 2>/dev/null)
  url=$(echo "$out" | python3 -c "import sys,json
try:
  d=json.load(sys.stdin); d=d[0] if isinstance(d,list) else d
  print(d.get('result_url') or '')
except Exception: print('')")
  [ -n "$url" ] && curl -s -o stills/e5_dadi_group_cross.png "$url" && echo "OK still" || { echo "retry still $t"; sleep 16; }
done
sleep 6
for t in 1 2 3; do
  [ -s clips/c54_group_cross.mp4 ] && break
  id=$(higgsfield generate create gemini_omni --prompt "STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY. CHARACTER REFERENCES: each character image is a locked design; match each EXACTLY. LOCATION REFERENCE: match the place image's rope-and-plank bridge. 3D papercraft, layered cut-paper, warm storybook palette, non-photorealistic, not a photo. SCENE: $CAST They cross the old rope-and-plank bridge together in the afternoon; the bridge sways gently under the bear's weight; the two little ones hop along behind. MOTION: the slow careful crossing, the bridge swaying, the toddlers hopping. AUDIO: none needed. $N" --image "$STYLE" --image $CS/dadi.png --image $CS/reechh.png --image $CS/castor.png --image $CS/leda.png $A --duration 10 --aspect_ratio 16:9 --resolution 720p --json 2>/dev/null | python3 -c "import sys,json
try:
  d=json.load(sys.stdin); v=d[0] if isinstance(d,list) and isinstance(d[0],str) else (d[0].get('id') if isinstance(d,list) else d.get('id'))
  print(v or '')
except Exception: print('')")
  if [ -n "$id" ]; then
    url=$(higgsfield generate wait "$id" --json 2>/dev/null | python3 -c "import sys,json
d=json.load(sys.stdin); d=d[0] if isinstance(d,list) else d
print(d.get('result_url') or '')")
    [ -n "$url" ] && curl -s -o clips/c54_group_cross.mp4 "$url" && { echo "OK clip"; break; }
  fi
  echo "retry clip $t"; sleep 20
done
