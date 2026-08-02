#!/bin/bash
# Ep5 «प से पुल» renders. NEW SET: the old rope-plank bridge over the stream (both banks).
# Laws: location anchors on every shot in a set; letterless plates (प composites later);
# true scale language; full negative block always.
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep5prod
STYLE=0c47270d-70f7-4dd0-887f-c06c88ef5fd9
CS=../charsheets
mkdir -p stills clips
SP="STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY. CHARACTER REFERENCES: character images are locked designs; match each EXACTLY. LOCATION REFERENCE: when a place image is attached, match its banks, water, trees and structure EXACTLY — same place, different angle. 3D papercraft, layered cut-paper illustration, soft matte construction-paper textures, warm storybook palette, non-photorealistic, illustrated. LANDSCAPE 16:9 SHOT for a children's cartoon."
EN="Full-bleed scene, the camera is INSIDE the world. NEGATIVE: no theater curtains, no stage, no proscenium, no frame-within-frame, no decorative border, no readable text, no letters, no numbers, no captions, no watermark, no logos, no photorealism, no live action, no human figures, nothing scary, nobody in danger."
still() { local n="$1" refs="$2" desc="$3" t
  [ -s "stills/$n.png" ] && { echo "SKIP $n"; return; }
  for t in 1 2 3; do
    local out url
    out=$(higgsfield generate create nano_banana_pro --prompt "$SP $desc Mouths gently closed, clear expressions. $EN" --image "$STYLE" $refs --aspect_ratio 16:9 --resolution 2k --wait --json 2>/dev/null)
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
K="--image $CS/kuku.png"; F="--image $CS/furia.png"; V="--image $CS/vesper.png"
D="--image $CS/dadi.png"; P="--image $CS/papa.png"; M="--image $CS/mitasur.png"
L="--image $CS/kalu.png"; B="--image $CS/reechh.png"; C="--image $CS/castor.png"; LE="--image $CS/leda.png"

# 1. the SET anchor first — everything else references it
still e5_bridge_wide "" "A wide view of a small old rope-and-plank footbridge crossing a fast shallow paper stream in a green valley; weathered wooden planks, rope handrails, round mossy stones at the edges of the water, a big leafy paper tree on the far bank, soft morning light. No characters."
A="--image stills/e5_bridge_wide.png"

still e5_kite_sky "$V $F" "Vesper the soft blue dragon boy and Fyuria the pink-red dragon girl on a grassy bank flying a bright paper kite high on a windy morning, heads tilted up, string taut, joyful."
still e5_kite_tree "" "A bright paper kite snagged high in the branches of a big leafy paper tree on the far bank of a stream, wind moving the leaves, morning."
still e5_fyuria_claim "$F $A" "Fyuria the pink-red dragon girl at the near end of THE SAME rope-and-plank bridge from the place reference, one foot forward, chin up, claiming the errand, bright morning."
still e5_vesper_hears "$V $A" "Vesper the soft blue dragon boy standing very still near THE SAME bridge, head tilted, listening hard to something only he noticed, dreamy and puzzled."
still e5_dadi_group_cross "$D $B $C $LE $A" "Dadi Maya the grey grandmother dragon with her walking stick leading Reechh the honey-brown bear and the two toddlers Castor and Leda onto THE SAME bridge from the place reference, afternoon light, cheerful departure."
still e5_bridge_broken "$A" "THE SAME bridge from the place reference with its MIDDLE PLANKS GONE — a clean gap in the walkway, cut rope ends hanging, the stream running fast below, nobody on it, late afternoon."
still e5_kuku_shout "$K $A" "Kuku the small green baby dragon at the near bank of THE SAME broken bridge, front paws cupped around his mouth, shouting across the water, worried."
still e5_dadi_far "$D $A" "Dadi Maya the grey spectacled grandmother dragon standing on the FAR bank of THE SAME stream, calling back across the water with one wing raised, calm and reassuring, late afternoon."
still e5_kuku_forge "$K $F $V $A" "Kuku the small green baby dragon standing at the water's edge of THE SAME stream, feet planted, round belly puffed with a huge breath, Fyuria and Vesper braced beside him, golden sparkles beginning, evening light."
still e5_letter_sunk "$A" "THE SAME stream: a large heavy golden-brown wooden beam lying tilted and half sunk against the near bank, water pulling at it, evening light. No letters, no text."
still e5_kuku_sad "$K $A" "Kuku the small green baby dragon sitting small on a stone at the water's edge, shoulders down, close to tears, evening light."
still e5_mitasur_search "$M $A" "Mitasur the grey-purple goblin kneeling in the shallow water of THE SAME stream, both fat pink sponge-hands pushed under the surface, searching the riverbed, evening light."
still e5_fyuria_confess "$F $K $A" "Fyuria the pink-red dragon girl standing straight at the water's edge facing Kuku the green baby dragon, chin up but eyes wet, telling the truth, evening light."
still e5_papa_kneel "$P $F $A" "Papa the big dark-green dragon kneeling down to his daughter Fyuria the pink-red dragon girl at the water's edge, one paw on her shoulder, gentle and steady, dusk."
still e5_papa_tells "$P $K $M $A" "Papa the big dark-green dragon standing in the shallows of THE SAME stream pointing at a spot in the water, Kuku and Mitasur looking where he points, dusk, lantern-warm light."
still e5_bridge_new "$A" "THE SAME stream at dusk with a NEW bridge across it: a broad flat golden-brown deck resting on two thick pillars that stand on flat stones in the water, warm and solid. No letters, no text, no writing."
still e5_papa_crosses "$P" "Papa the big dark-green dragon taking a heavy first step onto a broad flat golden bridge deck over a stream, testing it with his weight, dusk, everyone watching from the bank."
still e5_all_cross "$D $B $C $LE" "Dadi Maya, Reechh the honey-brown bear and the toddlers Castor and Leda walking home across a broad flat golden bridge deck at dusk, relieved and happy."
still e5_vesper_asleep "$V" "Vesper the soft blue dragon boy fast asleep curled on a broad flat golden bridge deck over a quiet stream at night, paper stars above, a lantern glow."
echo "STILLS: $(ls stills/*.png 2>/dev/null | wc -l | tr -d ' ')/20"
