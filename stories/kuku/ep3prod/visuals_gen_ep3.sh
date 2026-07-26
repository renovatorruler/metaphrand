#!/bin/bash
# Ep3 shot-list renders: 17 stills + 10 clips. Sequential CLI (the law). Reuse pool
# from Ep2: s_dadi_rock, s_vesper_rock, s_fyuria_rock, s_dadi_night, s_fyuria_kitab,
# cast sheets, cue1/3/6/7, typst cards. रीछ + रथ sheets attached wherever they appear.
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep3prod
STYLE=0c47270d-70f7-4dd0-887f-c06c88ef5fd9
CS=../charsheets
mkdir -p stills clips
SP="STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY. CHARACTER REFERENCES: every other attached image is a locked design; match each EXACTLY. 3D papercraft, layered cut-paper illustration, soft matte construction-paper textures, warm storybook palette, soft lighting, non-photorealistic, illustrated. LANDSCAPE 16:9 SHOT for a children's cartoon."
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
D="--image $CS/dadi.png"; M="--image $CS/mitasur.png"; L="--image $CS/kalu.png"
B="--image $CS/reechh.png"; R="--image $CS/rath.png"; C="--image $CS/castor.png"; LE="--image $CS/leda.png"

still e3_mitasur_paint "$M" "Mitasur the grey-purple goblin at dusk in front of his cozy new paper house, proudly holding a paint brush up to his freshly painted front door, warm lantern light, flower pots."
still e3_mitasur_stuck "$M" "Mitasur the grey-purple goblin close-up at his front door at dusk, brush frozen mid-air, worried puzzled face, looking at the unfinished door."
still e3_kuku_evening "$K" "Kuku the small green baby dragon at dusk arriving at a cozy paper house yard, delighted and curious, lantern glow."
still e3_fyuria_evening "$F" "Fyuria the BRIGHT PINK-RED little dragon girl, a small child dragon exactly as in her reference sheet, at dusk in the paper house yard, hands on hips, bright encouraging smile, warm lantern light."
still e3_vesper_evening "$V" "Vesper the soft blue dragon boy standing a little apart at dusk, sleepy knowing half-smile, evening stars beginning."
still e3_toddlers "$C $LE" "Castor the tiny yellow toddler dragon and Leda the tinier lavender-pink baby girl dragon side by side at DUSK — purple-orange evening sky, warm lantern glow, first stars — both clapping, adorable."
still e3_kuku_rock "$K" "Kuku the small green baby dragon at the flat teaching rock, tongue out trying to roll a sound, morning light."
still e3_mitasur_rock "$M" "Mitasur the grey-purple goblin at the teaching rock, drooping sad, tongue stuck out clumsily, endearing."
still e3_kalu_cu "$L" "Kalu the small black puppy close-up at the teaching rock, chest puffed proud, bright happy eyes."
still e3_kids_night "$K $F $V" "Kuku, Fyuria and Vesper the three dragon kids at their doorway at night in moonlight, just woken, listening alarmed toward the dark hills."
still e3_mitasur_night "$M" "Mitasur the grey-purple goblin at night, panicked, paws on his cheeks, moonlit."
still e3_slope_vesper "$V" "Vesper the soft blue dragon boy at night on a moonlit slope, calmly pointing across a meadow toward a distant river bend, certain and serene."
still e3_rope_team "$F $M" "Fyuria the pink-red dragon girl and Mitasur the grey-purple goblin at night gripping a taut rope stretched across a moonlit path, braced hard, determined."
still e3_reechh_grass "$B" "The big honey-brown paper bear sitting slumped on moonlit grass, sad hungry droopy eyes, paws on his round tummy, utterly unthreatening."
still e3_feast_dadi "$D $R" "Dadi Maya the grey spectacled grandmother dragon at a festive morning yard beside the garlanded wooden sweets cart, arms open in welcome, bunting and marigolds."
still e3_mitasur_name "$M" "Mitasur the grey-purple goblin close-up at his front door in morning light, holding the brush with trembling care, eyes shining with emotion."
still e3_fyuria_roti "$F $M" "Fyuria the pink-red dragon girl warmly offering a golden paper roti to surprised Mitasur the grey-purple goblin, festive morning yard."
echo "STILLS: $(ls stills/*.png 2>/dev/null | wc -l | tr -d ' ')/17"

CP="STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY. CHARACTER REFERENCES: every other attached image is a locked design; match each EXACTLY. 3D papercraft, layered cut-paper illustration, soft matte construction-paper textures, warm storybook palette, soft lighting, non-photorealistic, illustrated, not a photo."
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

clip c31_paint "$M" "SCENE: dusk at a cozy paper house: Mitasur the grey-purple goblin happily paints smooth colorful strokes on his front door with a fat brush, humming, lantern glowing, fireflies drifting. MOTION: gentle rhythmic brush strokes, proud little sways, firefly drift. AUDIO: none needed."
clip c32_break "$B $R" "SCENE: night on a paper hilltop: the garlanded wooden sweets cart stands tied by a thick rope to a wooden stake; the big honey-brown paper bear climbs into the cart bed sniffing eagerly at the piled breads; the cart tilts under his weight, the rope stretches, strains — and SNAPS; the cart lurches and starts to roll. MOTION: the heavy climb, the tilting, the rope straining then snapping, the first lurch of the wheels. AUDIO: none needed."
clip c33_rolling "$B $R" "SCENE: night: the wooden sweets cart careens down a long moonlit paper slope, wheels blurring, the big honey-brown paper bear clinging to the cart bed wide-eyed and scared, breads bouncing; moonlit trees whip past. MOTION: fast downhill rolling, bouncing, clinging, wind in paper leaves. AUDIO: none needed."
clip c34_chasefail "$F $R" "SCENE: night: Fyuria the pink-red dragon girl sprints at full stretch down the moonlit path behind the runaway wooden cart, giving everything, but the cart pulls further and further away downhill. MOTION: desperate sprint, the widening gap, her slowing to a defeated stop. AUDIO: none needed."
clip c35_meadow "$K $F $V $M" "SCENE: night: Kuku, Fyuria, Vesper and Mitasur the goblin dash together in a determined line STRAIGHT across a moonlit paper meadow of tall silver grass, cutting the corner while the empty road curves far around behind them. MOTION: the flat-out shortcut run through parting grass, fireflies scattering. AUDIO: none needed."
clip c36_forge "$K $F $V" "SCENE: night at a moonlit river-bend in the road: Kuku the small green baby dragon plants his feet, draws an enormous breath with puffed belly, and breathes out a stream of golden light that slams down into the earth beside the road as a glowing solid stake, sparks raining gently; Fyuria and Vesper brace beside him. MOTION: the huge inhale, the golden stream, the heavy THUD of light setting into the ground, rising sparkle. AUDIO: none needed."
clip c37_stop "$B $R" "SCENE: night: the runaway wooden cart barrels toward a taut rope stretched across the road near a moonlit river; it hits the rope, the rope stretches long like a bowstring, the cart groans, slows, and stops with its front wheel at the very edge of the water; the big honey-brown paper bear tumbles gently off into thick soft grass. MOTION: the catch, the long elastic strain, the screeching slow, the soft tumble. AUDIO: none needed."
clip c38_feast "$D $B $R $M" "SCENE: festive morning outside a cozy paper house: marigold garlands and bunting, the wooden sweets cart parked proudly, villager dragons gathering, Dadi Maya the grandmother dragon welcoming, the big honey-brown paper bear seated shyly like a guest of honour, Mitasur the goblin beaming host. MOTION: festive bustle, garlands swaying, shy bear waving a paw. AUDIO: none needed."
clip c39_eat "$B" "SCENE: festive morning close-up: the big honey-brown paper bear takes an enormous happy bite of a golden paper roti, chews with eyes closed in bliss, then pats his round tummy with both paws, utterly content. MOTION: the big bite, blissful chewing, the happy tummy pats. AUDIO: none needed."
clip c40_end "$V $B $R $L" "SCENE: night, slow pan across a lamp-lit yard: Vesper the soft blue dragon boy fast asleep INSIDE the empty wooden cart bed on a blanket, Kalu the small black puppy at his feet, and the big honey-brown paper bear leaning against the cart wheel snoring peacefully, paper stars and a warm lantern above. MOTION: the slow tender pan, gentle breathing, lamp flicker. AUDIO: none needed."
echo "CLIPS: $(ls clips/*.mp4 2>/dev/null | wc -l | tr -d ' ')/10"
