#!/bin/bash
# Ep4 shot renders: 17 stills + 10 clips. New set: फ्यूरिया-वैस्पर house + the नल.
# LAW: the tap/letter is NEVER model-drawn — blank plates render here, न composites later.
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep4prod
STYLE=0c47270d-70f7-4dd0-887f-c06c88ef5fd9
CS=../charsheets
mkdir -p stills clips
SP="STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY. CHARACTER REFERENCES: every other attached image is a locked design; match each EXACTLY. 3D papercraft, layered cut-paper illustration, soft matte construction-paper textures, warm storybook palette, soft lighting, non-photorealistic, illustrated. LANDSCAPE 16:9 SHOT for a children's cartoon."
EN="Full-bleed scene, the camera is INSIDE the world. NEGATIVE: no theater curtains, no stage, no proscenium, no frame-within-frame, no decorative border, no readable text, no letters, no captions, no watermark, no logos, no photorealism, no live action, no human figures, nothing scary."
still() { local n="$1" refs="$2" desc="$3"
  [ -s "stills/$n.png" ] && { echo "SKIP $n"; return; }
  local out url
  out=$(higgsfield generate create nano_banana_pro --prompt "$SP $desc Mouths gently closed, clear expressions. $EN" --image "$STYLE" $refs --aspect_ratio 16:9 --resolution 2k --wait --json 2>/dev/null)
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
B="--image $CS/reechh.png"; C="--image $CS/castor.png"; LE="--image $CS/leda.png"

still e4_play_kids "$K $F $L" "Kuku the green baby dragon and Fyuria the pink-red dragon girl playing with a paper ball by the riverside on a sunny afternoon, Kalu the black puppy leaping, joyful."
still e4_toddlers_play "$C $LE" "Castor the tiny yellow toddler dragon and Leda the tinier lavender-pink baby girl dragon clapping and toddling on sunny grass, afternoon light."
still e4_vesper_dreamy "$V" "Vesper the soft blue dragon boy wandering dreamily out of a cozy paper house doorway, eyes up at the clouds, completely lost in a daydream, afternoon."
still e4_fyuria_notice "$F" "Fyuria the pink-red dragon girl outside the house squinting after someone with a hand shading her eyes, half amused half puzzled, afternoon."
still e4_house_ext "" "A cozy two-window paper cottage with a small porch at the edge of the paper village, warm afternoon light, flower boxes, a path to the river."
still e4_nal_old "" "Inside a simple paper bathroom corner: a small round wash basin under a plain old wooden-handled tap on the wall, a single water drop falling, everything slightly worn, soft window light."
still e4_vesper_sick "$V" "Vesper the soft blue dragon boy tucked in a small bed looking miserable: droopy eyes, a red sniffly nose, blanket to his chin, morning light through a window."
still e4_fyuria_worried "$F" "Fyuria the pink-red dragon girl at a bedside looking genuinely worried, paws clasped, cozy paper bedroom, bright MORNING light through the window."
still e4_kuku_worried "$K" "Kuku the small green baby dragon standing in a cozy paper bedroom looking worried and helpful, morning."
still e4_dadi_bedside "$D" "Dadi Maya the grey spectacled grandmother dragon sitting at a small bed's edge with a caring look, offering a paper cup of water, cozy bedroom."
still e4_dadi_teach "$D" "Dadi Maya the grey grandmother dragon standing beside the wash basin corner gesturing warmly like a teacher, children's-show host energy, indoor light."
still e4_wash_line "$K $F $C $LE" "Kuku, Fyuria and the two toddlers Castor and Leda lined up at the wash basin with sleeves rolled, hands out ready, excited, indoor light."
still e4_reechh_wash "$B" "The big honey-brown paper bear holding out his big front paws over the wash basin, delighted, water droplets, indoor light."
still e4_vesper_vow "$V" "Vesper the soft blue dragon boy standing proud and healthy on green paper hills at golden evening, clear bright eyes, one paw on his chest like a promise, the flat teaching rock and soft green valley behind him."
still e4_sleep_bear "$V $B $L" "Night: Vesper the soft blue dragon boy fast asleep rising and falling on the big honey-brown paper bear's round belly, the bear asleep too, Kalu the puppy curled at their feet, paper stars."
still e4_nal_wall "" "Inside the simple paper bathroom corner: the small round wash basin and the bare wall above it with NOTHING mounted on it, clean empty wall space above the basin, soft warm light."
still e4_mitasur_proud "$M" "Mitasur the grey-purple goblin beaming with pride, sponge-hands raised triumphantly covered in white foam bubbles, indoor light."
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
clip c41_play "$K $F $L" "SCENE: sunny riverside afternoon: Kuku and Fyuria the dragon kids race and bounce a paper ball, Kalu the black puppy chasing it, grass and flowers, sparkling paper river. MOTION: running, bouncing ball, leaping puppy, carefree play. AUDIO: none needed."
clip c42_dreamwalk "$V" "SCENE: Vesper the soft blue dragon boy drifts dreamily out of a cozy paper house door and wanders down the path with his eyes fixed on the clouds, completely in his own world, while behind him inside the doorway a single water drop falls from an old tap. MOTION: slow dreamy drifting walk, head in the clouds, the tiny drip behind. AUDIO: none needed."
clip c43_sneeze "" "SCENE: exterior of a cozy two-window paper cottage in the morning: suddenly the whole cottage SHAKES with a comic blast from inside — windows rattle, the roofline ripples, a flock of paper birds scatters from the roof, leaves burst off a nearby tree. MOTION: one big comic shockwave rocking the cottage, birds scattering, everything settling. AUDIO: none needed."
clip c44_dadi_arrive "$D $K $F" "SCENE: Dadi Maya the grey grandmother dragon walks slowly and warmly up the path to the cottage porch where Kuku and Fyuria wait anxiously at the door and usher her inside. MOTION: her gentle unhurried walk, the kids' relieved welcome, door opening. AUDIO: none needed."
clip c45_forge_n "$K $F $D" "SCENE: inside by the wash basin corner: Kuku the small green baby dragon plants his feet, draws an enormous breath with his round belly puffing, and breathes out a bright stream of golden light toward the bare wall above the basin; Fyuria and Dadi Maya watch delighted; golden sparkles fill the room. MOTION: the huge inhale, the golden stream flowing to the wall, sparkles raining. AUDIO: none needed."
clip c46_water_burst "" "SCENE: the simple paper bathroom corner: from a point on the wall above the round basin, a joyful arc of clean blue paper water suddenly bursts forth and pours steadily into the basin, splashing tiny droplets, light dancing on the water; the wall point itself is hidden in a soft golden glow. MOTION: the sudden joyful burst, the steady sparkling pour, dancing droplets. AUDIO: none needed."
clip c47_wash_game "$K $F $C $LE" "SCENE: at the wash basin: Kuku, Fyuria, Castor and Leda all lather their paws together in white soap foam, bubbles floating up, splashing playfully, everyone laughing; foam beards and bubble crowns. MOTION: scrubbing little paws, floating bubbles, playful splashes. AUDIO: none needed."
clip c48_foam "$M $K" "SCENE: Mitasur the grey-purple goblin lathers his big pink sponge-hands into an ENORMOUS mountain of white foam that grows taller than everyone, bubbles drifting everywhere, Kuku amazed and laughing beside him. MOTION: the foam mountain rising comically, drifting bubble clouds, proud goblin flourish. AUDIO: none needed."
clip c49_hush "$K $F $D" "SCENE: evening inside the cozy cottage: Dadi Maya, Kuku and Fyuria tip-toe in exaggerated slow motion past a small bed where Vesper the blue dragon boy sleeps peacefully, everyone with a finger to their lips, warm lamp light, long soft shadows. MOTION: comic tip-toeing, the sleeping boy's gentle breathing, lamp flicker. AUDIO: none needed."
clip c50_end "$V $B $L" "SCENE: night outside under paper stars: Vesper the soft blue dragon boy fast asleep rising and falling gently on the round belly of the sleeping honey-brown paper bear, Kalu the puppy curled at their feet, a warm lantern, fireflies. MOTION: the slow gentle rise and fall of the bear's breathing carrying the sleeping boy, lamp flicker, drifting fireflies. AUDIO: none needed."
echo "CLIPS: $(ls clips/*.mp4 2>/dev/null | wc -l | tr -d ' ')/10"
