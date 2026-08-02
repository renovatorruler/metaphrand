#!/bin/bash
# EP1 «Я САМ» — Scene 1 stills (under-floor road, the striped sock).
# Laws: location anchor on every shot in the set; letterless plates (Cyrillic composited
# later); true scale language; full negative block always; idempotent + retry.
cd "$(dirname "$0")"
CS=../charsheets
mkdir -p stills clips

# Style key: leave empty to use the locked hand-painted look via character refs alone,
# or set to a resolved Higgsfield preset media_id (re-resolve — these expire):
#   higgsfield preset resolve video-explainer <preset_uuid> --json
STYLE=""
STYLE_REF=""; [ -n "$STYLE" ] && STYLE_REF="--image $STYLE"

SP="CHARACTER REFERENCES: the attached character images are LOCKED designs; match each one EXACTLY — same face, same hair, same patchwork clothing, same proportions. LOCATION REFERENCE: when a place image is attached, match its beams, floorboards, cobwebs and light EXACTLY — same place, different angle. Hand-painted 2D children's storybook illustration, warm saturated gouache, visible brush texture, bold caricature proportions: oversized round heads, thin spindly arms and legs, small slender bodies, barefoot. Non-photorealistic, illustrated. LANDSCAPE 16:9 SHOT for a children's cartoon."

EN="Full-bleed scene, the camera is INSIDE the world. TRUE SCALE: the characters are matchbox-sized, so household objects around them are enormous. NEGATIVE: no theater curtains, no stage, no proscenium, no frame-within-frame, no decorative border, no readable text, no letters, no numbers, no captions, no watermark, no logos, no photorealism, no live action, no realistic human beings, nothing scary, nobody in danger, no shoes."

still() { local n="$1" refs="$2" desc="$3" t
  [ -s "stills/$n.png" ] && { echo "SKIP $n"; return; }
  for t in 1 2 3; do
    local out url
    out=$(higgsfield generate create nano_banana_pro --prompt "$SP $desc $EN" $STYLE_REF $refs --aspect_ratio 16:9 --resolution 2k --wait --json 2>/dev/null)
    url=$(echo "$out" | python3 -c "import sys,json
try:
  raw=sys.stdin.read(); i=raw.find('[')
  d=json.loads(raw[i:]) if i>=0 else json.loads(raw)
  d=d[0] if isinstance(d,list) else d
  print(d.get('result_url') or '')
except Exception: print('')")
    [ -n "$url" ] && curl -s -o "stills/$n.png" "$url" && { echo "OK $n"; sleep 5; return; }
    echo "retry $t $n"; sleep 14
  done
  echo "FAIL $n"
}

V="--image $CS/vasya.png"; F="--image $CS/frosya.png"

# ---- 1. THE SET ANCHOR FIRST — every other shot references it ----
still s1_underfloor_wide "" "A wide view of a narrow dusty passage in the gap UNDER a wooden floor: enormous worn floorboards overhead, towering wooden joists and posts, drifting cobwebs, soft dust on the ground, and one warm shaft of light stabbing down through a gap between the boards into deep cool blue-violet shadow, glowing dust motes in the beam. No characters."
A="--image stills/s1_underfloor_wide.png"

# ---- 2. shots in that set ----
still s1_haul_wide "$F $V $A" "In THE SAME under-floor passage from the place reference: the two tiny house-spirit characters travel together toward the LEFT, side by side, the girl slightly ahead and the boy just behind her, both gripping the cuff of a HUGE striped sock that trails away behind them to the RIGHT along the dusty ground. They lean into the pull, straining with the weight, bare feet braced. They are on the SAME side of the sock, moving it together in one direction — not facing each other, not pulling apart. Open space at the left of frame ahead of them."
still s1_haul_close "$F $V $A" "In THE SAME under-floor passage: a closer three-quarter view of the two characters mid-haul, faces effortful — the girl determined and commanding, the boy gritting his teeth — the huge striped sock's cuff gripped in their hands, the warm shaft of light raking across them."
still s1_freeze "$F $V $A" "In THE SAME under-floor passage: both characters FROZEN stock-still mid-step beside the striped sock, rigid, holding their breath, eyes wide and looking upward; pale dust sifting down through the shaft of light around them. Absolute stillness, tension."
still s1_giant_shadow "$A" "In THE SAME under-floor passage, seen from below: the huge dark shadow of a giant human foot passing across the floorboards overhead, dust sifting down through the cracks in the warm light. No characters visible."
still s1_sock_alone "$A" "In THE SAME under-floor passage: the HUGE striped sock lying alone on the dusty ground, half in the warm shaft of light, nobody near it."

echo "STILLS: $(ls stills/*.png 2>/dev/null | wc -l | tr -d ' ')"
