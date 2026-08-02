#!/bin/bash
# Ep5 MOTION — the action spine the first cut was missing entirely.
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep5prod
STYLE=0c47270d-70f7-4dd0-887f-c06c88ef5fd9
CS=../charsheets
A="--image stills/e5_bridge_wide.png"
mkdir -p clips
CP="STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY. CHARACTER REFERENCES: character images are locked designs; match each EXACTLY. LOCATION REFERENCE: the place image is the set — match its rope-and-plank bridge, banks, water and far-bank tree. 3D papercraft, layered cut-paper illustration, soft matte construction-paper textures, warm storybook palette, non-photorealistic, illustrated, not a photo."
EN="Full-bleed scene, camera INSIDE the world. NEGATIVE: no theater curtains, no stage, no proscenium, no readable text, no letters, no numbers, no watermark, no photorealism, nothing scary, nobody in danger, no child falling."
clip() { local n="$1" refs="$2" desc="$3" t
  [ -s "clips/$n.mp4" ] && { echo "SKIP $n"; return; }
  for t in 1 2 3; do
    local id url
    id=$(higgsfield generate create gemini_omni --prompt "$CP $desc $EN" --image "$STYLE" $refs --duration 10 --aspect_ratio 16:9 --resolution 720p --json 2>/dev/null | python3 -c "import sys,json
try:
  d=json.load(sys.stdin); v=d[0] if isinstance(d,list) and isinstance(d[0],str) else (d[0].get('id') if isinstance(d,list) else d.get('id'))
  print(v or '')
except Exception: print('')")
    if [ -n "$id" ]; then
      url=$(higgsfield generate wait "$id" --json 2>/dev/null | python3 -c "import sys,json
d=json.load(sys.stdin); d=d[0] if isinstance(d,list) else d
print(d.get('result_url') or '')")
      [ -n "$url" ] && curl -s -o "clips/$n.mp4" "$url" && { echo "OK $n"; sleep 6; return; }
    fi
    echo "retry $t $n"; sleep 20
  done
  echo "FAIL $n"
}
K="--image $CS/kuku.png"; F="--image $CS/furia.png"; V="--image $CS/vesper.png"
D="--image $CS/dadi.png"; P="--image $CS/papa.png"; M="--image $CS/mitasur.png"
B="--image $CS/reechh.png"; C="--image $CS/castor.png"

clip c51_kite_fly "$V $F $K" "SCENE: a windy sunny morning on a green paper hillside by a stream: Vesper the blue dragon boy holds a kite string while Fyuria the pink-red dragon girl and Kuku the green baby dragon run and cheer, a bright paper kite climbing high and swooping on the wind above them. MOTION: the kite rising and dancing, string tugging, children running and pointing up, grass and paper clouds moving. AUDIO: none needed."
clip c52_kite_snap "$V" "SCENE: a bright paper kite high on the wind suddenly breaks free — the string whips loose and the kite tumbles sideways across a stream and snags in the branches of a big leafy tree on the far bank, where it hangs fluttering. MOTION: the snap, the tumbling flight across the water, the snag, the kite flapping in the branches. AUDIO: none needed."
clip c53_fyuria_cross "$F $A" "SCENE: Fyuria the pink-red dragon girl runs confidently across THE SAME old rope-and-plank footbridge from the place reference, then lands hard on both feet on the middle plank; the plank flexes and dips sharply under her and the rope handrails shudder. MOTION: the confident run, the two-footed landing, the plank bending, ropes shaking, then stillness. AUDIO: none needed."
clip c54_group_cross "$D $B $C $A" "SCENE: Dadi Maya the grey grandmother dragon with a walking stick leads Reechh the big honey-brown bear and Castor the tiny yellow toddler across THE SAME rope-and-plank bridge in the afternoon; the bridge sways gently under the bear's weight. MOTION: the slow careful crossing, the bridge swaying, the toddler hopping. AUDIO: none needed."
clip c55_collapse "$A" "SCENE: THE SAME empty rope-and-plank bridge from the place reference in the late afternoon — nobody on it — the middle planks groan, sag, break loose and drop into the fast water below, leaving a wide gap with two cut ropes swinging. MOTION: the sag, the break, the planks tumbling into the stream, splash, ropes swinging to a stop. AUDIO: none needed."
clip c56_bear_slip "$B $A" "SCENE: Reechh the big honey-brown paper bear wades into the shallow fast stream, his paws slide on round mossy stones, he wobbles comically and sits down in the water with a huge splash, then climbs back out shaking his paws. MOTION: the wading, the comic slip and splash, the shake-off. AUDIO: none needed."
clip c57_forge_fail "$K $F $V $A" "SCENE: evening at the stream: Kuku the small green baby dragon plants his feet and breathes out a swirling stream of golden sparkling light that gathers over the water into a heavy glowing golden beam; the beam settles into the water, tilts, sinks at both ends and drifts to the bank. Fyuria and Vesper watch, then slump. MOTION: the huge breath, the golden light gathering, the beam settling then tilting and sinking, the children's shoulders dropping. ABSOLUTELY NO FIRE, NO FLAME. AUDIO: none needed."
clip c58_search "$M $K $A" "SCENE: dusk in the shallows: Mitasur the grey-purple goblin kneels in the water sweeping both fat pink sponge-hands across the riverbed, lifting handfuls of sand that pour away, while Kuku the green baby dragon holds a lantern beside him; the light is fading. MOTION: the sweeping hands, sand pouring, ripples, the lantern glow flickering. AUDIO: none needed."
clip c59_forge_hold "$K $M $A" "SCENE: night falling at the stream: Kuku the small green baby dragon breathes a broad ribbon of golden light that settles into a solid glowing beam spanning the water; its left foot clamps down onto a flat stone with a jolt, its right leg plants on a second stone, and the whole span pulls taut and stops moving. Mitasur the goblin steadies the stones with his sponge-hands. MOTION: the golden ribbon flowing out, the clamp, the settle, the span going rigid and still. ABSOLUTELY NO FIRE. AUDIO: none needed."
clip c60_cross_home "$P $D $B $C" "SCENE: dusk: Papa the big dark-green dragon steps heavily onto a broad flat golden bridge deck over a stream and walks across testing it, then Dadi Maya, Reechh the bear and the toddlers hurry across behind him, everyone relieved and happy, a paper kite carried high in someone's paws. MOTION: the heavy testing steps, the happy crossing, the kite bobbing above them. AUDIO: none needed."
echo "CLIPS: $(ls clips/*.mp4 2>/dev/null | wc -l | tr -d ' ')/10"
