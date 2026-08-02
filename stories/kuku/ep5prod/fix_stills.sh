#!/bin/bash
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep5prod
STYLE=0c47270d-70f7-4dd0-887f-c06c88ef5fd9
CS=../charsheets
A="--image stills/e5_bridge_wide.png"
SP="STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY. CHARACTER REFERENCES: character images are locked designs; match each EXACTLY. LOCATION REFERENCE: the place image is THE set — match its rope-and-plank bridge, its banks, its stones and its far-bank tree EXACTLY. 3D papercraft, layered cut-paper, soft matte textures, warm storybook palette, non-photorealistic. LANDSCAPE 16:9."
EN="Full-bleed scene, camera INSIDE the world. NEGATIVE: no theater curtains, no stage, no proscenium, no frame-within-frame, no readable text, no letters, no numbers, no watermark, no photorealism, nothing scary, nobody in danger."
one() { local n="$1" refs="$2" desc="$3" t
  [ -s "stills/$n.png" ] && { echo "SKIP $n"; return; }
  for t in 1 2 3; do
    local out url
    out=$(higgsfield generate create nano_banana_pro --prompt "$SP $desc $EN" --image "$STYLE" $refs --aspect_ratio 16:9 --resolution 2k --wait --json 2>/dev/null)
    url=$(echo "$out" | python3 -c "import sys,json
try:
  d=json.load(sys.stdin); d=d[0] if isinstance(d,list) else d
  print(d.get('result_url') or '')
except Exception: print('')")
    [ -n "$url" ] && curl -s -o "stills/$n.png" "$url" && { echo "OK $n"; sleep 5; return; }
    echo "retry $t $n"; sleep 14
  done
  echo "FAIL $n"
}
# --- the three failed shots ---
one e5_bridge_broken "$A" "THE SAME rope-and-plank bridge from the place reference, now BROKEN: the four middle planks are COMPLETELY GONE leaving a wide empty gap right in the centre, the two cut rope ends hang loose over the water, only the planks nearest each bank remain. Nobody on it. Late afternoon."
one e5_dadi_group_cross "--image $CS/dadi.png --image $CS/reechh.png --image $CS/castor.png $A" "Dadi Maya the grey grandmother dragon with her walking stick leading Reechh the honey-brown bear and the tiny yellow toddler Castor onto THE SAME rope-and-plank bridge from the place reference, mid-crossing, afternoon, cheerful."
one e5_bridge_new "$A" "THE SAME stream and banks from the place reference at dusk, but the old rope bridge is replaced by a NEW structure: one broad flat plain wooden deck resting on two thick square pillars that stand on flat stones in the water. Plain and solid. NO writing, NO symbols, NO letters anywhere."
# --- close-ups: this episode is ten minutes of talking ---
one e5_cu_kuku "--image $CS/kuku.png $A" "CLOSE-UP of Kuku the small green baby dragon by the stream, filling most of the frame from the chest up, worried and determined, the blurred bridge and far-bank tree behind him, afternoon."
one e5_cu_fyuria "--image $CS/furia.png $A" "CLOSE-UP of Fyuria the pink-red dragon girl by the stream, from the chest up, filling most of the frame, guilt on her face, eyes down then lifting, the blurred stream behind her, evening."
one e5_cu_vesper "--image $CS/vesper.png $A" "CLOSE-UP of Vesper the soft blue dragon boy by the stream, from the chest up, filling most of the frame, head tilted listening, dreamy and certain, blurred trees behind, afternoon."
one e5_cu_dadi "--image $CS/dadi.png $A" "CLOSE-UP of Dadi Maya the grey spectacled grandmother dragon on the FAR bank, from the chest up, filling most of the frame, calling across the water with her mouth closed and eyes warm and teacherly, blurred far-bank tree behind, evening."
one e5_cu_papa "--image $CS/papa.png $A" "CLOSE-UP of Papa the big dark-green dragon by the stream at dusk, from the chest up, filling most of the frame, ashamed but steady, quietly telling the truth, blurred water behind him."
one e5_cu_mitasur "--image $CS/mitasur.png $A" "CLOSE-UP of Mitasur the grey-purple goblin kneeling in the shallows, from the chest up, filling most of the frame, both wet pink sponge-hands raised, delighted and astonished, blurred stream behind, dusk."
echo "FIX BATCH: $(ls stills/*.png | wc -l | tr -d ' ')/26"
