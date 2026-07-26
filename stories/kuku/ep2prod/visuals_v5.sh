#!/bin/bash
# v5 shot-list NEED renders (non-Leda): 2 stills + the sack-burst clip. Sequential CLI.
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep2prod
STYLE=0c47270d-70f7-4dd0-887f-c06c88ef5fd9
CS=../charsheets
SP="STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY. CHARACTER REFERENCES: every other attached image is a locked character design; match each EXACTLY. 3D papercraft, layered cut-paper illustration, soft matte construction-paper textures, warm storybook palette, soft lighting, non-photorealistic, illustrated. LANDSCAPE 16:9 SHOT for a children's cartoon."
EN="Full-bleed scene, the camera is INSIDE the world. NEGATIVE: no theater curtains, no stage, no proscenium, no frame-within-frame, no decorative border, no readable text, no letters, no captions, no watermark, no logos, no photorealism, no live action, no human figures, nothing scary."

still() { local n="$1" refs="$2" desc="$3"
  [ -s "stills/$n.png" ] && { echo "SKIP $n"; return; }
  local out url
  out=$(higgsfield generate create nano_banana_pro --prompt "$SP $desc Mouth gently closed, calm clear expression. $EN" --image "$STYLE" $refs --aspect_ratio 16:9 --resolution 2k --wait --json 2>/dev/null)
  url=$(echo "$out" | python3 -c "import sys,json
try:
  d=json.load(sys.stdin); d=d[0] if isinstance(d,list) else d
  print(d.get('result_url') or '')
except Exception: print('')")
  [ -n "$url" ] && curl -s -o "stills/$n.png" "$url" && echo "OK $n" || echo "FAIL $n"
  sleep 1
}

still s_kuku_taste "--image $CS/kuku.png" "Kuku the small green baby dragon standing at a GREY faded drained-of-color paper sweets stall, holding a half-bitten paper sweet in one paw, puzzled disappointed little face, the fair behind him all grey and sagging."
still s_dadi_grey "--image $CS/dadi.png" "Dadi Maya the grey spectacled grandmother dragon in front of her faded grey sweets stall, gravely gathering the children close with one open wing, kind but serious, the drained grey fair behind."

clip() { local n="$1" refs="$2" desc="$3"
  [ -s "clips/$n.mp4" ] && { echo "SKIP $n"; return; }
  local id url
  id=$(higgsfield generate create gemini_omni --prompt "STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY. CHARACTER REFERENCES: every other attached image is a locked character design; match each EXACTLY. 3D papercraft, layered cut-paper illustration, soft matte construction-paper textures, warm storybook palette, soft lighting, non-photorealistic, illustrated, not a photo. $desc $EN" --image "$STYLE" $refs --duration 10 --aspect_ratio 16:9 --resolution 720p --json 2>/dev/null | python3 -c "import sys,json
try:
  d=json.load(sys.stdin); v=d[0] if isinstance(d,list) and isinstance(d[0],str) else (d[0].get('id') if isinstance(d,list) else d.get('id'))
  print(v or '')
except Exception: print('')")
  [ -z "$id" ] && { echo "SUBMIT-FAIL $n"; return; }
  url=$(higgsfield generate wait "$id" --json 2>/dev/null | python3 -c "import sys,json
d=json.load(sys.stdin); d=d[0] if isinstance(d,list) else d
print(d.get('result_url') or '')")
  [ -n "$url" ] && curl -s -o "clips/$n.mp4" "$url" && echo "OK $n" || echo "FAIL $n"
}

clip c14_burst "--image $CS/mitasur.png" "SCENE: golden hour by the paper stream: the burlap sack in the arms of Mitasur the grey-purple goblin BURSTS open; dozens of warm glowing golden letter-shapes fountain upward out of it and stream away in bright arcs over the paper hills toward the distant fair, like comets flying home; Mitasur tumbles backward into the mud, the empty deflated sack fluttering down over his head. MOTION: the sudden burst, the fountain of streaming golden lights arcing away, the comic backward tumble. AUDIO: none needed."
echo "V5 RENDERS DONE: $(ls stills/s_kuku_taste.png stills/s_dadi_grey.png clips/c14_burst.mp4 2>/dev/null | wc -l | tr -d ' ')/3"
