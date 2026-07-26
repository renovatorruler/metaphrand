#!/bin/bash
# Ep2 animatic visuals: stills (talking/holding shots, 16:9) then motion clips.
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep2prod
STYLE=0c47270d-70f7-4dd0-887f-c06c88ef5fd9
CS=../charsheets
mkdir -p stills clips
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

K="--image $CS/kuku.png"; F="--image $CS/furia.png"; V="--image $CS/vesper.png"
D="--image $CS/dadi.png"; P="--image $CS/papa.png"; M="--image $CS/mitasur.png"; L="--image $CS/kalu.png"

still s_kuku_fair "$K" "Kuku the small green baby dragon at a bright paper fairground, holding up a paper postcard, delighted, bunting behind."
still s_fyuria_fair "$F" "Fyuria the pink-red dragon girl at the bright fairground, arms flung wide with joy, stalls and bunting behind."
still s_vesper_fair "$V" "Vesper the soft blue dragon boy at the fairground, half asleep on his feet, sweet sleepy smile, festive blur behind."
still s_dadi_fair "$D" "Dadi Maya the grey spectacled grandmother dragon behind her colorful sweets stall at the fair, warm amused look to camera."
still s_mitasur_hill "$M" "Mitasur the grey-purple goblin standing in open wild grass on a dusk hilltop overlooking the tiny glowing fair far below, medium close-up, sulky-sad, plain closed burlap sack on shoulder. Full-bleed outdoor scene. ABSOLUTELY NO theater curtains, NO stage, NO proscenium, NO frame-within-frame, NO letters or glyphs spilling from the sack."
still s_dadi_rock "$D" "Dadi Maya at her flat teaching rock, gesturing warmly beside a soft golden glow, children's-show host energy."
still s_vesper_rock "$V" "Vesper the soft blue dragon boy gazing up dreamily at a golden glow above him, wonder in his half-lidded eyes."
still s_fyuria_rock "$F" "Fyuria the pink-red dragon girl at the teaching rock, leaning forward keen and bright, ready to answer."
still s_team_hunt "$K $F $V $L" "The three dragon kids and Kalu the black puppy in a determined line at the faded grey fair, ready for a mission, heroic kid energy."
still s_mitasur_cornered "$M" "Mitasur the grey-purple goblin cornered by the stream, hugging his glowing burlap sack to his chest with both sponge-hands, tearful defiant eyes."
still s_fyuria_alarm "$F" "Fyuria the pink-red dragon girl at the stream's edge pointing across the water, genuinely alarmed, urgent."
still s_kuku_brave "$K" "Kuku the small green baby dragon planting his feet at the stream bank, scared but steady, little fists clenched, golden hour."
still s_kuku_kneel "$K $M" "Kuku the small green dragon kneeling in the mud face to face with Mitasur the deflated grey-purple goblin, gentle and kind, offering."
still s_mitasur_wonder "$M" "Mitasur the grey-purple goblin cupping his sponge-hands together before his chest, staring down at a soft golden glow between them, eyes enormous with wonder, tears of joy."
still s_papa_dadi "$P $D $K" "Papa the big dark-green dragon leaning down to kiss the top of Dadi Maya's grey head while small Kuku looks up wide-eyed; warm evening fair lights."
still s_dadi_night "$D" "Dadi Maya at her rock under paper stars, warm to camera, counting on her claws, cozy night."
still s_fyuria_kitab "$F" "Fyuria the pink-red dragon girl writing carefully in a small paper notebook with a fat crayon, tongue out in concentration, starlit."
still s_group_night "$K $F $D $L" "Kuku, Fyuria, Kalu and Dadi Maya settled cozy around the teaching rock under stars, sleepy warm smiles, night lamp glow."
echo "STILLS: $(ls stills/*.png 2>/dev/null | wc -l | tr -d ' ')/18"

CP="STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY. CHARACTER REFERENCES: every other attached image is a locked character design; match each EXACTLY. 3D papercraft, layered cut-paper illustration, soft matte construction-paper textures, warm storybook palette, soft lighting, non-photorealistic, illustrated, not a photo."

clip() { local n="$1" refs="$2" desc="$3"
  [ -s "clips/$n.mp4" ] && { echo "SKIP $n"; return; }
  local id url
  id=$(higgsfield generate create gemini_omni --prompt "$CP $desc $EN" --image "$STYLE" $refs --duration 10 --aspect_ratio 16:9 --resolution 720p --json 2>/dev/null | python3 -c "import sys,json
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

clip c1_bustle "$K $F $V $L" "SCENE: ground-level bright morning paper fairground in full swing: bunting, stalls, dragon villagers strolling, a peacock family parading with fuzzy chicks trailing their mother, a sparkling fish pond; Kuku, Fyuria, sleepy Vesper and Kalu the puppy tumble happily into frame. MOTION: festive bustle, happy tumbling arrival, chicks waddling in a line. AUDIO: none needed."
clip c2_popper "$V" "SCENE: tiny yellow toddler dragon Cheeku squeezes a paper party-popper right behind Vesper the soft blue dragon boy; confetti bursts; Vesper's eyes SNAP open huge and his mouth opens enormous in a colossal cartoon scream, giant papercraft sound-rings blasting outward across the fair, everyone claps paws over ears, hills rippling. MOTION: pop, confetti, the huge scream shockwave rings, everyone flinching. AUDIO: none needed."
clip c4_chase "$F $L $M" "SCENE: comic chase through a faded grey paper fair: Mitasur the grey-purple goblin scampers ahead flinging slippery paper peels behind him; Fyuria the pink-red dragon girl and Kalu the black puppy tear after him dodging the peels; a drooping flat-tailed peacock and dull grey sweets stall flash past. MOTION: fast scamper, flung peels, skids and leaps. AUDIO: none needed."
clip c5_matka "" "SCENE: quiet by the paper stream: a fat round clay paper pot sits among reeds, a thin thread of warm golden light leaking from under its lid, pulsing gently like something alive inside; dragonfly drifts past. MOTION: the gentle pulsing leak of golden light, reeds swaying. AUDIO: none needed."
clip c6_freeze "$F $K $M" "SCENE: the whole faded paper fair frozen mid-step: Fyuria mid-run, Kuku mid-hop, Mitasur mid-scamper, every villager stopped with paws clapped over ears, giant papercraft sound-rings rolling across the scene from off-frame right. MOTION: near-total freeze, only the huge sound-rings sweeping through, dust settling. AUDIO: none needed."
clip c7_forge "$K $F $V" "SCENE: golden hour at the stream: Kuku the small green baby dragon plants his feet, draws an enormous breath with puffed round belly, and breathes out a swirling ball of golden light that gathers and brightens above the water while Fyuria and Vesper lock in beside him paw to paw; sparks rain gently. MOTION: the huge inhale, the gathering blazing ball, rising sparkle, hair and paper edges fluttering. AUDIO: none needed."
clip c8_boat "" "SCENE: a small curved boat of warm golden light, shaped like two open cradling arms, glides across a golden-hour paper stream carrying a tiny fuzzy peachick; on the far bank a peahen mother rushes to the water's edge wings open; the chick sails gently to her. MOTION: the smooth gliding crossing, wings opening, the tender arrival. AUDIO: none needed."
clip c9_heal "" "SCENE: a wave of warm golden light rolls across the paper fairground restoring everything: grey sweets bloom back to bright colors, a drooping peacock lifts its head and FANS its tail wide in a hundred colors, frozen paper fish flash back to life and dart in the pond, bunting re-brightens. MOTION: the rolling wave of color, the glorious tail fan, darting fish. AUDIO: none needed."
clip c10_firstm "$M $K" "SCENE: Mitasur the grey-purple goblin, kneeling in soft mud, trembles his fat sponge-hands, squeezes his eyes shut and breathes out; a tiny wobbly glow flickers to life in the air before him, small and crooked and precious; Kuku the small green dragon beams beside him; the glow reflects in Mitasur's enormous amazed eyes. MOTION: the trembling breath, the tiny flickering wobbly glow, welling joy. AUDIO: none needed."
clip c11_night "$V $M $L" "SCENE: slow pan at night across Dadi's warm lamp-lit yard: Vesper the soft blue dragon boy fast asleep curled inside a big empty sweets basket, Kalu the black puppy snuggled against him, and Mitasur the grey-purple goblin snoring softly nearby with a sweet in one sponge-hand, something tiny and warm glowing cradled in the other arm; paper stars above. MOTION: the slow tender pan, breathing rises and falls, lamp flicker. AUDIO: none needed."
echo "CLIPS: $(ls clips/*.mp4 2>/dev/null | wc -l | tr -d ' ')/10"

clip c12_sniff "$L $F $K $V" "SCENE: at the faded grey paper fair, Kalu the black puppy drops his nose to the ground and sniffs along a visible trail of chalky white eraser-smudges dotted down the path; his tail stiffens, he yips and BOLTS along the trail; Fyuria, Kuku and Vesper the dragon kids leap and dash after him. MOTION: nose-down tracking along the smudge trail, the sudden bolt, kids scrambling to follow. AUDIO: none needed."
clip c13_unheard "$V $F $L" "SCENE: Vesper the soft blue dragon boy stands very still at the faded grey fair, gently raising one paw to point toward the stream; behind him the loud chase blurs past — Fyuria the pink-red dragon girl and Kalu the black puppy tear by without a glance at him; Vesper tries pointing again, shoulders drooping a little, completely unheard. MOTION: the still pointing figure against rushing motion-blur chaos behind, the small second try. AUDIO: none needed."
echo "CLIPS: $(ls clips/*.mp4 2>/dev/null | wc -l | tr -d ' ')/12"
