#!/bin/bash
# Ep4 v2 fix renders — set-locking per the audit.
# SICKROOM anchor  = stills/e4_vesper_sick.png (established first, reads best)
# WASHROOM anchor  = stills/e4_nal_old.png (basin + old wall tap, paw-scale)
# Sequential CLI + retry (the API fails in bursts).
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep4prod
STYLE=0c47270d-70f7-4dd0-887f-c06c88ef5fd9
CS=../charsheets
SP="STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY. CHARACTER REFERENCES: character images are locked designs; match each EXACTLY. LOCATION REFERENCE: the room image is the SET — match its wall colour, window position, furniture and fixtures EXACTLY; a different camera angle of the SAME room. Keep every fixture at TRUE scale (a wall tap is paw-sized). 3D papercraft, layered cut-paper illustration, soft matte construction-paper textures, warm storybook palette, non-photorealistic. LANDSCAPE 16:9 SHOT for a children's cartoon."
EN="Full-bleed scene, the camera is INSIDE the world. NEGATIVE: no theater curtains, no stage, no proscenium, no frame-within-frame, no decorative border, no clocks, no wall charts, no readable text, no letters, no numbers, no captions, no watermark, no logos, no photorealism, no live action, no human figures, nothing scary."

still() { local n="$1" refs="$2" desc="$3" try
  [ -s "stills/$n.png" ] && { echo "SKIP $n"; return; }
  for try in 1 2 3; do
    local out url
    out=$(higgsfield generate create nano_banana_pro --prompt "$SP $desc $EN" --image "$STYLE" $refs --aspect_ratio 16:9 --resolution 2k --wait --json 2>/dev/null)
    url=$(echo "$out" | python3 -c "import sys,json
try:
  d=json.load(sys.stdin); d=d[0] if isinstance(d,list) else d
  print(d.get('result_url') or '')
except Exception: print('')")
    if [ -n "$url" ]; then curl -s -o "stills/$n.png" "$url" && { echo "OK $n"; sleep 6; return; }; fi
    echo "retry $try $n"; sleep 15
  done
  echo "FAIL $n"
}

CP="STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY. CHARACTER REFERENCES: character images are locked designs; match each EXACTLY. LOCATION REFERENCE: the room image is the SET — match its wall colour, window position and fixtures EXACTLY. 3D papercraft, layered cut-paper illustration, soft matte textures, warm storybook palette, non-photorealistic, not a photo."
clip() { local n="$1" refs="$2" desc="$3" try
  [ -s "clips/$n.png.done" ] && { echo "SKIP $n"; return; }
  for try in 1 2 3; do
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
      if [ -n "$url" ]; then curl -s -o "clips/$n.mp4" "$url" && { touch "clips/$n.png.done"; echo "OK $n"; sleep 6; return; }; fi
    fi
    echo "retry $try $n"; sleep 20
  done
  echo "FAIL $n"
}

K="--image $CS/kuku.png"; F="--image $CS/furia.png"; V="--image $CS/vesper.png"
D="--image $CS/dadi.png"; M="--image $CS/mitasur.png"; B="--image $CS/reechh.png"
C="--image $CS/castor.png"; LE="--image $CS/leda.png"
BED="--image stills/e4_vesper_sick.png"; BATH="--image stills/e4_nal_old.png"

# ---- SICKROOM (one room, four angles) ----
still e4_fyuria_worried "$F $V $BED" "Fyuria the pink-red dragon girl standing worried at the bedside of THE SAME bedroom from the room reference, with Vesper the soft blue dragon boy lying sick in that same bed — droopy eyes, red sniffly nose, blanket to his chin. Morning light. Both clearly visible."
still e4_dadi_bedside "$D $V $BED" "Dadi Maya the grey spectacled grandmother dragon sitting on the edge of THE SAME bed in the room reference, offering a paper cup of water to Vesper the soft blue dragon boy who lies sick under the blanket, weak little smile. Morning light. Both clearly visible."
still e4_kuku_worried "$K $V $BED" "Kuku the small green baby dragon standing in THE SAME bedroom from the room reference, looking worried toward the bed where Vesper the soft blue dragon boy lies sick under the blanket. Morning light. Both clearly visible."
still e4_toddlers_bedside "$C $LE $BED" "Castor the tiny yellow toddler dragon and Leda the tinier lavender-pink baby girl dragon sitting together on the floor of THE SAME bedroom from the room reference, looking up curiously, the corner of the sick-bed visible behind them. Morning light."
still e4_dadi_night_bedside "$D $V $BED" "Evening in THE SAME bedroom from the room reference, lit only by a warm little lamp: Dadi Maya the grey grandmother dragon leaning over the bed with a finger to her lips, and Vesper the soft blue dragon boy FAST ASLEEP under the blanket, eyes closed, peaceful. Deep blue evening sky in the window."

# ---- WASHROOM (one room, four angles; old tap visible, paw-sized) ----
still e4_wash_line "$K $F $C $LE $BATH" "Kuku the green baby dragon, Fyuria the pink-red dragon girl, the tiny yellow toddler Castor and the tinier lavender-pink baby Leda lined up at THE SAME small round wash basin from the room reference, the little old wall tap above it, paws out ready and excited, indoor light."
still e4_dadi_teach "$D $BATH" "Dadi Maya the grey grandmother dragon standing beside THE SAME small wash basin and little old wall tap from the room reference, gesturing warmly like a teacher, children's-show host energy, indoor light."
still e4_reechh_wash "$B $BATH" "The big honey-brown paper bear holding out his big front paws over THE SAME small round wash basin from the room reference, delighted, water droplets, indoor light."
still e4_mitasur_proud "$M $BATH" "Mitasur the roly-poly dusty grey-purple goblin with big googly eyes and two fat pink sponge-hands, standing in THE SAME washroom from the room reference, beaming with pride, both sponge-hands raised high and covered in white foam bubbles."

# ---- CLIPS (interiors matching the washroom; no fire; no clocks) ----
clip c45_forge_n "$K $F $D $BATH" "SCENE: inside THE SAME washroom from the room reference: Kuku the small green baby dragon plants his feet, draws an enormous breath with his round belly puffing, and breathes out a swirling stream of GOLDEN SPARKLING LIGHT toward the bare wall above the round basin; Fyuria and Dadi Maya watch delighted; golden sparkles fill the room. The breath is soft golden glitter-light, NOT fire. MOTION: the huge inhale, the ribbon of golden light flowing to the wall, sparkles raining. ABSOLUTELY NO FIRE, NO FLAME, NO ORANGE FIRE, NO SMOKE. AUDIO: none needed."
clip c47_wash_game "$K $F $C $LE $BATH" "SCENE: inside THE SAME washroom from the room reference, at the small round basin: Kuku, Fyuria, Castor and Leda all lather their paws together in white soap foam, bubbles floating up, splashing playfully, everyone laughing, foam beards and bubble crowns. MOTION: scrubbing little paws, floating bubbles, playful splashes. AUDIO: none needed."
clip c48_foam "$M $K $BATH" "SCENE: inside THE SAME washroom from the room reference: Mitasur the grey-purple goblin lathers his big pink sponge-hands into an ENORMOUS mountain of white foam that grows taller than everyone, bubbles drifting everywhere, Kuku the green baby dragon amazed and laughing beside him. MOTION: the foam mountain rising comically, drifting bubble clouds, proud goblin flourish. AUDIO: none needed."
clip c49_hush "$D $K $F $V" "SCENE: EVENING inside a cozy paper bedroom lit by one warm little lamp, deep blue night sky in the window: Dadi Maya the grandmother dragon, Kuku and Fyuria tip-toe in exaggerated slow motion past a small bed where Vesper the blue dragon boy sleeps peacefully under a blanket, everyone with a finger to their lips, long soft shadows. MOTION: comic tip-toeing, the sleeping boy's gentle breathing, lamp flicker. NO CLOCKS ON THE WALL. AUDIO: none needed."
echo "FIX RENDERS DONE"
