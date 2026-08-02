#!/bin/bash
# EP1 «Я САМ» — Scene 1 motion. Same reference stack as the stills.
# Two routes, pick per shot:
#   clip()   = gemini_omni text-to-video WITH style/character/location refs (Kuku's method)
#   anim()   = kling3_0 image-to-video from an APPROVED still (holds the frame harder)
cd "$(dirname "$0")"
CS=../charsheets
mkdir -p clips

STYLE=""
STYLE_REF=""; [ -n "$STYLE" ] && STYLE_REF="--image $STYLE"

CP="CHARACTER REFERENCES: the attached character images are LOCKED designs; match each EXACTLY. LOCATION REFERENCE: the place image is the set — match its beams, floorboards, cobwebs and light. Hand-painted 2D children's storybook illustration, warm saturated gouache, visible brush texture, oversized round heads, thin spindly arms and legs, barefoot. Non-photorealistic, illustrated, not a photo."
EN="Full-bleed scene, camera INSIDE the world. NEGATIVE: no theater curtains, no stage, no proscenium, no readable text, no letters, no numbers, no watermark, no photorealism, nothing scary, nobody in danger, no shoes."

clip() { local n="$1" refs="$2" desc="$3" t
  [ -s "clips/$n.mp4" ] && { echo "SKIP $n"; return; }
  for t in 1 2 3; do
    local id url
    id=$(higgsfield generate create gemini_omni --prompt "$CP $desc $EN" $STYLE_REF $refs --duration 10 --aspect_ratio 16:9 --resolution 720p --json 2>/dev/null | python3 -c "import sys,json
try:
  raw=sys.stdin.read(); i=raw.find('[')
  d=json.loads(raw[i:]) if i>=0 else json.loads(raw)
  d=d[0] if isinstance(d,list) else d
  print(d.get('id') or '')
except Exception: print('')")
    if [ -n "$id" ]; then
      url=$(higgsfield generate wait "$id" --json 2>/dev/null | python3 -c "import sys,json
raw=sys.stdin.read(); i=raw.find('[')
d=json.loads(raw[i:]) if i>=0 else json.loads(raw)
d=d[0] if isinstance(d,list) else d
print(d.get('result_url') or '')")
      [ -n "$url" ] && curl -s -o "clips/$n.mp4" "$url" && { echo "OK $n"; sleep 6; return; }
    fi
    echo "retry $t $n"; sleep 20
  done
  echo "FAIL $n"
}

# image-to-video from an approved still — strongest character hold
anim() { local n="$1" still="$2" desc="$3" t
  [ -s "clips/$n.mp4" ] && { echo "SKIP $n"; return; }
  local kf="clips/_kf_$n.jpg"
  python3 -c "
from PIL import Image
im=Image.open('$still').convert('RGB'); im.thumbnail((1920,1920)); im.save('$kf', quality=93)" 2>/dev/null || { echo "NO STILL $still"; return; }
  for t in 1 2 3; do
    local out url
    out=$(higgsfield generate create kling3_0 --prompt "$desc" --start-image "$kf" --duration 5 --mode pro --sound off --aspect_ratio 16:9 --wait --wait-timeout 10m --json 2>/dev/null)
    url=$(echo "$out" | python3 -c "import sys,json
try:
  raw=sys.stdin.read(); i=raw.find('[')
  d=json.loads(raw[i:]) if i>=0 else json.loads(raw)
  d=d[0] if isinstance(d,list) else d
  print(d.get('result_url') or '')
except Exception: print('')")
    [ -n "$url" ] && curl -s -o "clips/$n.mp4" "$url" && { echo "OK $n"; sleep 5; return; }
    echo "retry $t $n"; sleep 18
  done
  echo "FAIL $n"
}

V="--image $CS/vasya.png"; F="--image $CS/frosya.png"; A="--image stills/s1_underfloor_wide.png"

anim c1_haul stills/s1_haul_wide.png "The two characters walk to the LEFT together, straining, dragging the huge striped sock along the ground behind them; the sock slides after them. Dust drifts slowly through the warm shaft of light. Cobwebs stir. Slow camera pan left following them. Everything stays hand-painted storybook illustration; the characters keep their exact painted appearance."
anim c2_freeze stills/s1_freeze.png "Both characters hold absolutely still, only their eyes moving upward; fine dust sifts down through the shaft of light around them. Almost no motion. Very slow, gentle camera push-in."
anim c3_shadow stills/s1_giant_shadow.png "The huge dark shadow of a giant foot slides across the floorboards overhead and passes; dust pours down through the cracks in the warm light. No characters."

echo "CLIPS: $(ls clips/*.mp4 2>/dev/null | wc -l | tr -d ' ')"
