#!/bin/bash
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep5prod
STYLE=0c47270d-70f7-4dd0-887f-c06c88ef5fd9
CS=../charsheets
BR="--image stills/e5_bridge_broken.png"
FULLN="Full-bleed scene, the camera is INSIDE the world. NEGATIVE: no theater curtains, no stage, no proscenium, no frame-within-frame, no decorative border, no readable text, no letters, no watermark, no photorealism, nothing scary, nobody in danger."
SP="STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY. CHARACTER REFERENCE: the character image is a locked design; match it EXACTLY. 3D papercraft, layered cut-paper illustration, soft matte textures, warm storybook palette, non-photorealistic. LANDSCAPE 16:9 SHOT."
one(){ local n="$1" refs="$2" d="$3" t
  [ -s "stills/$n.png" ] && { echo "SKIP $n"; return; }
  for t in 1 2 3; do
    out=$(higgsfield generate create nano_banana_pro --prompt "$SP $d $FULLN" --image "$STYLE" $refs --aspect_ratio 16:9 --resolution 2k --wait --json 2>/dev/null)
    url=$(echo "$out" | python3 -c "import sys,json
try:
  d=json.load(sys.stdin); d=d[0] if isinstance(d,list) else d
  print(d.get('result_url') or '')
except Exception: print('')")
    [ -n "$url" ] && curl -s -o "stills/$n.png" "$url" && { echo "OK $n"; sleep 5; return; }
    echo "retry $t $n"; sleep 16
  done
  echo "FAIL $n"; }

# --- close-ups: NO bridge in frame at all, so they work in any scene ---
one e5_cu_kuku "--image $CS/kuku.png" "CLOSE-UP of Kuku the small green baby dragon from the chest up, filling most of the frame, worried and determined. Behind him only soft blurred green grass, bushes and sky. THERE IS NO BRIDGE ANYWHERE IN THIS PICTURE."
one e5_cu_fyuria "--image $CS/furia.png" "CLOSE-UP of Fyuria the pink-red dragon girl from the chest up, filling most of the frame, guilt on her face, eyes lowered then lifting, evening light. Behind her only soft blurred grass and sky. THERE IS NO BRIDGE ANYWHERE IN THIS PICTURE."
one e5_cu_dadi "--image $CS/dadi.png" "CLOSE-UP of Dadi Maya the grey spectacled grandmother dragon from the chest up, filling most of the frame, calling out warmly, teacherly. Behind her only soft blurred trees and sky. THERE IS NO BRIDGE ANYWHERE IN THIS PICTURE."
one e5_cu_papa "--image $CS/papa.png" "CLOSE-UP of Papa the big dark-green dragon from the chest up, filling most of the frame, ashamed but steady, quietly telling the truth, dusk. Behind him only soft blurred trees and darkening sky. THERE IS NO BRIDGE ANYWHERE IN THIS PICTURE."
one e5_cu_mitasur "--image $CS/mitasur.png" "CLOSE-UP of Mitasur the grey-purple goblin from the chest up, filling most of the frame, both wet pink sponge-hands raised, delighted and astonished, dusk. Behind him only soft blurred water and grass. THERE IS NO BRIDGE ANYWHERE IN THIS PICTURE."

# --- wides: the bridge must be BROKEN, with a gap where the middle planks were ---
one e5_kuku_forge "--image $CS/kuku.png --image $CS/furia.png $BR" "Kuku the small green baby dragon stands at the near water's edge with his feet planted and belly puffed, Fyuria braced beside him, evening. Behind them the rope bridge from the place reference is BROKEN — its middle planks gone, a clear empty gap in the middle, cut ropes hanging loose."
one e5_kuku_sad "--image $CS/kuku.png $BR" "Kuku the small green baby dragon sits small on a stone at the water's edge, shoulders down, close to tears, evening. Behind him the rope bridge is BROKEN — middle planks missing, a clear gap, cut ropes dangling."
one e5_mitasur_search "--image $CS/mitasur.png $BR" "Mitasur the grey-purple goblin kneels in the shallow water with both fat pink sponge-hands under the surface, searching the riverbed, dusk. Behind him the rope bridge is BROKEN — middle planks gone, clear gap, ropes hanging."
one e5_fyuria_confess "--image $CS/furia.png --image $CS/kuku.png $BR" "Fyuria the pink-red dragon girl stands straight at the water's edge facing Kuku the green baby dragon, chin up but eyes wet, telling the truth, evening. Behind them the rope bridge is BROKEN — a clear empty gap where its middle planks were."
one e5_papa_kneel "--image $CS/papa.png --image $CS/furia.png $BR" "Papa the big dark-green dragon kneels down to Fyuria the pink-red dragon girl at the water's edge, one paw on her shoulder, gentle and steady, dusk. Behind them the rope bridge is BROKEN — middle planks missing, cut ropes hanging."
one e5_papa_tells "--image $CS/papa.png --image $CS/mitasur.png $BR" "Papa the big dark-green dragon stands in the shallows pointing at a spot in the water while Mitasur the goblin looks where he points, dusk, lantern-warm light. Behind them the rope bridge is BROKEN — a clear gap in its middle."
echo "STATE FIX: done"
